/**
 * DoorBell Cloud Functions.
 *
 * Responsibilities:
 *  - Push notifications via FCM on order lifecycle events.
 *  - Broadcast new pickup-ready orders to riders (topic: "riders").
 *  - Keep aggregates consistent (shop rating from reviews).
 *  - Create a wallet document for every new user.
 *  - Razorpay order creation + signature verification (callable functions).
 *
 * Secrets (set via): firebase functions:secrets:set RAZORPAY_KEY_ID
 *                    firebase functions:secrets:set RAZORPAY_KEY_SECRET
 */
import { onDocumentCreated, onDocumentUpdated } from "firebase-functions/v2/firestore";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import { initializeApp } from "firebase-admin/app";
import { getFirestore, FieldValue as FirestoreFieldValue } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";
import * as crypto from "crypto";
import Razorpay = require("razorpay");

initializeApp();
const db = getFirestore();

const RAZORPAY_KEY_ID = defineSecret("RAZORPAY_KEY_ID");
const RAZORPAY_KEY_SECRET = defineSecret("RAZORPAY_KEY_SECRET");

/** Sends a push to a single user (by their stored fcmToken) and logs it. */
async function notifyUser(
  userId: string,
  title: string,
  body: string,
  data: Record<string, string> = {},
): Promise<void> {
  // Persist the in-app notification.
  await db.collection("notifications").add({
    userId,
    title,
    body,
    type: data.type || "general",
    data,
    isRead: false,
    createdAt: FirestoreFieldValue.serverTimestamp(),
  });

  const userSnap = await db.collection("users").doc(userId).get();
  const token = userSnap.get("fcmToken");
  if (!token) return;
  try {
    await getMessaging().send({
      token,
      notification: { title, body },
      data,
    });
  } catch (err) {
    console.error(`FCM send failed for ${userId}`, err);
  }
}

/** New order -> notify the shop owner. */
export const onOrderCreated = onDocumentCreated("orders/{orderId}", async (event) => {
  const order = event.data?.data();
  if (!order) return;
  const shopSnap = await db.collection("shops").doc(order.shopId).get();
  const ownerId = shopSnap.get("ownerId");
  if (ownerId) {
    await notifyUser(
      ownerId,
      "New order received 🛒",
      `You have a new order worth ₹${order.totalAmount}.`,
      { type: "new_order", orderId: event.params.orderId },
    );
  }
});

/** Order status transitions -> notify the relevant parties. */
export const onOrderUpdated = onDocumentUpdated("orders/{orderId}", async (event) => {
  const before = event.data?.before.data();
  const after = event.data?.after.data();
  if (!before || !after) return;
  const orderId = event.params.orderId;

  // Status changed.
  if (before.orderStatus !== after.orderStatus) {
    const customerMessages: Record<string, string> = {
      accepted: "Your order has been accepted and is being prepared.",
      preparing: "The store is preparing your order.",
      riderAssigned: "A rider has been assigned to your order.",
      outForDelivery: "Your order is out for delivery! 🛵",
      delivered: "Your order has been delivered. Enjoy! 🎉",
      rejected: "Sorry, your order was rejected by the store.",
      cancelled: "Your order has been cancelled.",
    };
    const msg = customerMessages[after.orderStatus];
    if (msg) {
      await notifyUser(after.customerId, "Order update", msg, {
        type: "order_update",
        orderId,
        status: after.orderStatus,
      });
    }

    // When the order becomes ready for pickup, broadcast to riders.
    if (after.orderStatus === "readyForPickup" && !after.riderId) {
      await getMessaging().send({
        topic: "riders",
        notification: {
          title: "New delivery available 🛵",
          body: `Pickup ready • Payout ₹${after.deliveryFee}`,
        },
        data: { type: "delivery_request", orderId },
      });
    }

    // On delivery: settle rider earnings and mark COD as paid.
    if (after.orderStatus === "delivered") {
      const updates: Record<string, unknown> = {};
      if (after.paymentMethod === "cod" && after.paymentStatus !== "paid") {
        updates.paymentStatus = "paid";
      }
      if (Object.keys(updates).length) {
        await event.data?.after.ref.update(updates);
      }
      if (after.riderId) {
        await db.collection("riders").doc(after.riderId).update({
          earnings: FirestoreFieldValue.increment(after.deliveryFee || 0),
          totalDeliveries: FirestoreFieldValue.increment(1),
          status: "online",
        });
      }
    }
  }

  // Rider just got assigned -> notify that rider.
  if (!before.riderId && after.riderId) {
    await notifyUser(
      after.riderId,
      "Delivery assigned",
      "You've accepted a delivery. Head to the store for pickup.",
      { type: "delivery_assigned", orderId },
    );
    await db.collection("riders").doc(after.riderId).update({ status: "onDelivery" });
  }
});

/** Recompute a product's average rating whenever a review is added. */
export const onReviewCreated = onDocumentCreated("reviews/{reviewId}", async (event) => {
  const review = event.data?.data();
  if (!review?.productId) return;
  const reviews = await db
    .collection("reviews")
    .where("productId", "==", review.productId)
    .get();
  if (reviews.empty) return;
  const avg =
    reviews.docs.reduce((sum: number, d) => sum + (d.get("rating") || 0), 0) /
    reviews.size;
  await db
    .collection("products")
    .doc(review.productId)
    .update({ rating: Math.round(avg * 10) / 10 });
});

/** Create an empty wallet for every new user. */
export const onUserCreated = onDocumentCreated("users/{uid}", async (event) => {
  const uid = event.params.uid;
  await db.collection("wallets").doc(uid).set({ balance: 0 }, { merge: true });
});

/**
 * Creates a Razorpay order server-side so the client receives a verifiable
 * order_id. Call from Flutter before opening checkout.
 */
export const createRazorpayOrder = onCall(
  { secrets: [RAZORPAY_KEY_ID, RAZORPAY_KEY_SECRET] },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Sign in required.");
    }
    const amount = Number(request.data.amount);
    if (!amount || amount <= 0) {
      throw new HttpsError("invalid-argument", "Invalid amount.");
    }
    const 
    razorpay = new Razorpay({
      key_id: RAZORPAY_KEY_ID.value(),
      key_secret: RAZORPAY_KEY_SECRET.value(),
    });
    const order = await razorpay.orders.create({
      amount: Math.round(amount * 100), // paise
      currency: "INR",
      receipt: `rcpt_${Date.now()}`,
    });
    return { orderId: order.id, amount: order.amount, keyId: RAZORPAY_KEY_ID.value() };
  },
);

/**
 * Verifies a Razorpay payment signature. Returns {valid: true} when the
 * payment is authentic. Call after a successful client-side payment.
 */
export const verifyRazorpayPayment = onCall(
  { secrets: [RAZORPAY_KEY_SECRET] },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Sign in required.");
    }
    const { orderId, paymentId, signature } = request.data;
    if (!orderId || !paymentId || !signature) {
      throw new HttpsError("invalid-argument", "Missing payment fields.");
    }
    const expected = crypto
      .createHmac("sha256", RAZORPAY_KEY_SECRET.value())
      .update(`${orderId}|${paymentId}`)
      .digest("hex");
    return { valid: expected === signature };
  },
);
