# DoorBell — Claude Project Context

## Project Overview
**DoorBell** is a hyperlocal delivery app for Jodhpur, Rajasthan (first launch: Chopasni area).
Built with Flutter + Firebase. Rebranded from LocalKart.

## Architecture
- **State management:** Riverpod (flutter_riverpod)
- **Navigation:** go_router
- **Backend:** Firebase (Firestore, Auth, Storage, Messaging, Analytics)
- **Payments:** Razorpay (active) · PhonePe stub · Paytm stub
- **Maps:** Google Maps Flutter
- **Package name:** `com.doorbell.doorbell`

## Folder Structure
```
lib/
├── core/
│   ├── constants/       # AppConstants, FirestoreCollections, StoragePaths
│   ├── error/           # Result<T>, Failure, ServerFailure
│   ├── providers/       # firebase_providers.dart — single DI root
│   ├── router/          # app_router.dart, app_routes.dart
│   ├── theme/           # app_colors.dart, app_theme.dart
│   ├── utils/           # formatters, validators, geo_utils
│   └── widgets/         # shared UI: PrimaryButton, AppTextField, EmptyState…
├── data/
│   ├── models/          # UserModel, ShopModel, OrderModel, RiderModel…
│   ├── repositories/    # one repo per domain (Firestore CRUD)
│   └── services/        # AuthService, PaymentService, StorageService…
└── features/
    ├── admin/           # AdminDashboardScreen — shop + rider approval
    ├── auth/            # login, signup, phone login, forgot password
    ├── cart/            # CartProvider (Riverpod StateNotifier)
    ├── checkout/        # CheckoutScreen — delivery slot + payment
    ├── emitra/          # EMitraScreen — document upload & print orders
    ├── home/            # CustomerShell (5-tab nav), HomeScreen
    ├── notifications/   # FCM notifications list
    ├── orders/          # Customer order history + OrderStatusChip
    ├── product/         # ProductDetailScreen
    ├── profile/         # ProfileScreen, AddressesScreen
    ├── rider/           # RiderDashboardScreen, RiderRegisterScreen
    ├── search/          # SearchScreen, CategoryProductsScreen
    ├── seller/          # SellerDashboardScreen (Overview/Orders/Inventory)
    ├── shop/            # ShopDetailScreen
    ├── tracking/        # TrackingScreen (live order map)
    └── wallet/          # WalletScreen (DoorBell Wallet + top-up)
```

## Key Domain Rules
- **Hyperlocal radius:** 3 km for Chopasni launch (`AppConstants.hyperlocalRadiusKm`)
- **Low-stock threshold:** 5 units (`AppConstants.lowStockThreshold`) — configurable per shop
- **Delivery slots:** 30-min windows 10 AM–9 PM (`DeliverySlot` enum in enums.dart)
- **Order flow:** placed → accepted/rejected → preparing → readyForPickup → riderAssigned → pickedUp → outForDelivery → delivered
- **Admin approves** shops and riders before they go live (`approvalStatus` field)
- **Google Sign-In** is Android-only (guarded by `Platform.isAndroid` in LoginScreen)

## Payment Gateways
| Gateway   | Status        | File                          |
|-----------|--------------|-------------------------------|
| Razorpay  | ✅ Active     | `RazorpayGateway` in payment_service.dart |
| PhonePe   | 🔜 Stub      | `PhonePeGateway` — add SDK + flip `isEnabled` |
| Paytm     | 🔜 Stub      | `PaytmGateway` — add SDK + flip `isEnabled` |

To enable PhonePe/Paytm:
1. Add SDK to `pubspec.yaml`
2. Implement `pay()` in the stub class
3. Set `isEnabled = true` in `enums.dart` `PaymentMethod`

## E-Mitra Services
Documents uploaded to Firebase Storage at `emitra/{uid}/{timestamp}_{filename}`.
Orders stored in `emitra_orders` Firestore collection.
Pricing: ₹5/page B&W · ₹10/page colour.

## Firebase Collections
| Collection       | Description                        |
|------------------|------------------------------------|
| `users`          | UserModel (all roles)              |
| `shops`          | ShopModel                          |
| `products`       | ProductModel                       |
| `categories`     | CategoryModel                      |
| `orders`         | OrderModel                         |
| `riders`         | RiderModel                         |
| `wallets`        | WalletModel + subcollection `transactions` |
| `coupons`        | CouponModel (doc ID = coupon code) |
| `notifications`  | NotificationModel                  |
| `reviews`        | ReviewModel                        |
| `emitra_orders`  | EMitraOrderModel                   |

## Firestore Indexes Needed
- `orders`: `customerId ASC, createdAt DESC`
- `orders`: `shopId ASC, createdAt DESC`
- `orders`: `riderId ASC, createdAt DESC`
- `orders`: `orderStatus ASC, riderId ASC` (availableForRiders)
- `shops`: `approvalStatus ASC, createdAt ASC`
- `riders`: `approvalStatus ASC, createdAt ASC`
- `products`: `shopId ASC, stock ASC` (low-stock alert)
- `emitra_orders`: `customerId ASC, createdAt DESC`

## Dev Notes
- Run `flutterfire configure` to regenerate `firebase_options.dart` for a new Firebase project.
- Set `GOOGLE_MAPS_API_KEY` and `RAZORPAY_KEY` via `--dart-define` in launch config, never hardcode.
- First 10-20 shops are manually onboarded via admin panel before opening public registration.
- `AppConstants.chopasniLat/Lng` = 26.3016, 73.0179 — update for other areas.

---

## New Features (latest update)

### Google Drive Image Storage
All images go to **Google Drive** (`lakshitsolanki1234@gmail.com`) instead of Firebase Storage (avoids Spark plan costs).

- **Service:** `lib/data/services/google_drive_service.dart`
- `StorageService` auto-routes images → Drive, non-images → Firebase Storage
- Images served via `https://drive.google.com/thumbnail?id=FILE_ID&sz=w800`
- Sub-folders created automatically: `doorbell_products`, `doorbell_shops`, `doorbell_riders`, `doorbell_users`, `doorbell_emitra`

**One-time setup:**
1. Enable **Google Drive API** at https://console.cloud.google.com
2. Add scope `https://www.googleapis.com/auth/drive.file` to your OAuth client
3. Create a root folder in Drive → Share → "Anyone with link can view"
4. Copy the folder ID from the URL and pass it as `--dart-define=GDRIVE_FOLDER_ID=YOUR_ID`

### Price Comparison on Product Detail
When a customer opens a product, they see a **"Compare prices nearby"** section showing the same product from all nearby shops, sorted cheapest-first. Tapping another shop's row opens that product directly.

- Provider: `priceComparisonProvider` in `product_detail_screen.dart`
- Matches by exact product name (case-insensitive) across all approved nearby shops

### Rider Status (5 states)
| Status | Receives orders? | GPS tracked? |
|--------|-----------------|-------------|
| Online ✅ | Yes | Yes |
| On Break 😴 | No | No |
| Busy 🔴 | No | No |
| Delivering 🔵 | No | Yes |
| Offline ⚫ | No | No |

- `RiderStatus.canReceiveOrders` — only `online` returns true
- `availableDeliveriesProvider` returns empty stream when rider is not online (saves Firestore reads)
- Status pill selector shown on rider dashboard

### First-Accept Order System
`OrderRepository.assignRider()` now uses a **Firestore transaction**:
- Checks `orderStatus == readyForPickup` AND `riderId == null` inside the transaction
- First rider to tap "Accept" wins; subsequent taps return `false` with "Another rider accepted this" snackbar
- Rider status auto-updates: `pickedUp` → `delivering`, `delivered` → `online`
