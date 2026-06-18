# 🛒 LocalKart

A production-grade, scalable **hyperlocal delivery platform** (think Blinkit / Zepto / Instamart / BigBasket) built with **Flutter + Firebase**. Customers order from nearby local stores; shop owners manage inventory and orders; riders deliver with live GPS tracking; admins approve and oversee the marketplace.

> **Status:** This repository is a fully-architected, compiling foundation. `flutter analyze` reports **0 issues** and the unit tests pass. The full customer + auth + cart + checkout + tracking flows and all four role areas (Customer / Shop Owner / Rider / Admin) are implemented. Plug in your own Firebase project (`flutterfire configure`) and API keys to run end-to-end.

---

## ✨ Tech Stack

| Layer | Technology |
|------|------------|
| UI | Flutter 3.x, Material 3, Glassmorphism, `flutter_animate`, `shimmer`, `cached_network_image`, `lottie` |
| State | Riverpod 3 (`Notifier` / `AsyncNotifier` / `StreamProvider`) |
| Navigation | GoRouter (role-based redirects) |
| Backend | Firebase Auth, Cloud Firestore, Storage, Cloud Messaging, Cloud Functions, Analytics, Crashlytics, Hosting |
| Maps | `google_maps_flutter`, `geolocator`, `geocoding`, polyline points |
| Payments | Razorpay, UPI, Wallet, Cash on Delivery |

## 🏛 Architecture

Clean Architecture + Repository pattern + feature-based folders. Dependency injection is a single composition root in `lib/core/providers/firebase_providers.dart` — every service and repository is provided there, so swapping an implementation (e.g. for tests) is a one-line `ProviderScope` override.

```
lib/
├── main.dart                  # Firebase + Crashlytics bootstrap
├── app.dart                   # MaterialApp.router + theme
├── firebase_options.dart      # PLACEHOLDER — replace via flutterfire configure
├── core/
│   ├── constants/             # app + firebase collection names, business rules
│   ├── error/                 # Failure types + Result<T> sealed class
│   ├── providers/             # DI composition root (firebase_providers.dart)
│   ├── router/                # GoRouter + role-based redirect
│   ├── theme/                 # Material 3 theme (white + light green)
│   ├── utils/                 # validators, formatters, geo (Haversine)
│   └── widgets/               # reusable UI (GlassCard, ProductCard, ShopCard…)
├── data/
│   ├── models/                # 13 domain models + enums (toMap/fromDoc)
│   ├── services/              # Auth, Storage, Location, Notification, Razorpay, Analytics
│   └── repositories/          # 12 repositories (one per domain)
└── features/                  # feature-first: each has screens/ + providers
    ├── splash/  onboarding/  auth/
    ├── home/  search/  shop/  product/  cart/  checkout/  orders/  tracking/
    ├── location/  profile/  wallet/  notifications/
    └── seller/  rider/  admin/
```

## 👥 Roles & Flows

- **Customer** — browse nearby shops, search/filter products, cart (single-shop, coupon support), checkout (address + COD/UPI/Razorpay/Wallet), live order tracking, wallet, addresses, notifications.
- **Shop Owner** — register store (pending admin approval), dashboard (revenue/orders/analytics), inventory CRUD with image upload, accept/reject/progress orders.
- **Rider** — KYC registration (Aadhaar/License/RC/Selfie), go online (streams live GPS to Firestore), accept deliveries, update delivery status, navigate via Google Maps.
- **Admin** — dashboard (users/shops/riders/revenue), approve/reject shops & riders.

**Order lifecycle:** `placed → accepted → preparing → readyForPickup → riderAssigned → pickedUp → outForDelivery → delivered` (with `rejected` / `cancelled`). State transitions trigger FCM pushes via Cloud Functions.

## 🔥 Firebase Collections

`users`, `shops`, `products`, `categories`, `orders`, `riders`, `reviews`, `wallets` (+ `transactions` subcollection), `notifications`, `supportTickets`, `coupons`, and `users/{uid}/addresses`. See each model in `lib/data/models/`.

---

## 🚀 Getting Started

### 1. Prerequisites
- Flutter 3.41+ / Dart 3.11+
- A Firebase project
- Node 20 (for Cloud Functions)
- `npm i -g firebase-tools` and `dart pub global activate flutterfire_cli`

### 2. Configure Firebase
```bash
flutterfire configure        # regenerates lib/firebase_options.dart for your project
```
Enable in the Firebase console: **Authentication** (Email/Password, Phone, Google), **Firestore**, **Storage**, **Cloud Messaging**, **Crashlytics**, **Analytics**.

### 3. Platform setup
- **Android:** drop `google-services.json` into `android/app/`, then uncomment the `com.google.gms.google-services` plugin in `android/app/build.gradle.kts`. Set your Maps key in `android/app/src/main/AndroidManifest.xml`.
- **iOS:** add `GoogleService-Info.plist` to `ios/Runner/`, and your Maps key in `ios/Runner/AppDelegate.swift`.

### 4. Provide API keys (compile-time)
```bash
flutter run \
  --dart-define=GOOGLE_MAPS_API_KEY=your_maps_key \
  --dart-define=RAZORPAY_KEY=rzp_test_xxxx
```

### 5. Deploy backend
```bash
firebase deploy --only firestore:rules,firestore:indexes,storage   # security rules + indexes
cd functions && npm install && npm run build && cd ..
firebase functions:secrets:set RAZORPAY_KEY_ID
firebase functions:secrets:set RAZORPAY_KEY_SECRET
firebase deploy --only functions
```

### 6. Run / Build
```bash
flutter pub get
flutter run                                            # debug
flutter build apk --release                            # Android
flutter build web && firebase deploy --only hosting    # Web (Firebase Hosting)
```

### 7. Test & analyze
```bash
flutter analyze     # → No issues found!
flutter test        # → All tests passed!
```

---

## ☁️ Cloud Functions (`functions/src/index.ts`)
- `onOrderCreated` → push to shop owner.
- `onOrderUpdated` → status-change pushes to customer/rider, broadcast pickup-ready orders to the `riders` FCM topic, settle rider earnings + mark COD paid on delivery.
- `onReviewCreated` → recompute product rating.
- `onUserCreated` → create the user's wallet.
- `createRazorpayOrder` / `verifyRazorpayPayment` → callable functions for secure server-side Razorpay order creation and signature verification.

## 🔐 Security
- `firestore.rules` — role-based access derived from `users/{uid}.role`; users can't self-assign `admin`, shop owners can't self-approve, riders can't self-approve, catalogue is public-read, orders visible only to involved parties.
- `storage.rules` — public image reads, owner-scoped writes, image type/size validation, **private rider KYC documents**.

## 📈 Scaling Notes (built-in upgrade paths)
- **Geo queries:** nearby-shop discovery currently fetches approved shops and filters by Haversine distance client-side (fine up to a few hundred shops/city). For millions of users, switch to **geohash** queries (`geoflutterfire_plus`).
- **Product search:** currently a Firestore fetch + in-memory filter. For large catalogues, integrate **Algolia / Typesense**.
- **Wallet integrity:** the demo allows owner wallet writes; move balance mutations entirely into a Cloud Function for production (see comment in `firestore.rules`).
- Firestore composite indexes for all compound queries are declared in `firestore.indexes.json`.

## ⚠️ What you must supply
`firebase_options.dart` (via flutterfire), `google-services.json` / `GoogleService-Info.plist`, Google Maps API keys, and Razorpay keys. Until then the app **compiles** but Firebase calls will fail at runtime.

## 📄 License
Provided as a starter/scaffold for your own product. Add your preferred license.
