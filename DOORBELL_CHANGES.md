# DoorBell — Changes from LocalKart

## Summary of all changes made

### 1. Rebrand: LocalKart → DoorBell
- `pubspec.yaml` name changed to `doorbell`
- `AppConstants.appName` = `'DoorBell'`
- App class renamed `DoorBellApp`
- Android package: `com.localkart.localkart` → `com.doorbell.doorbell`
- `MainActivity.kt` moved to new package path
- `AndroidManifest.xml` label and package updated
- `ios/Runner/Info.plist` usage descriptions updated
- App icon updated to `Icons.doorbell_rounded` on login/signup screens
- All UI strings referencing "LocalKart" replaced with "DoorBell"

### 2. Payment Gateway Abstraction (Razorpay-only → Multi-gateway)
- **New file:** `lib/data/services/payment_service.dart`
  - `PaymentGateway` abstract class
  - `RazorpayGateway` — active implementation
  - `PhonePeGateway` — stub with TODO comments (enable when SDK added)
  - `PaytmGateway` — stub with TODO comments (enable when SDK added)
  - `PaymentService.gatewayFor(method)` factory
- `PaymentMethod` enum extended with `phonePe`, `paytm`
- Each method has `isEnabled` getter — PhonePe/Paytm show "Coming soon" chip in checkout
- Old `razorpay_service.dart` replaced; wallet screen updated

**To enable PhonePe:**
1. Add `phonepe_payment_sdk` to `pubspec.yaml`
2. Implement `PhonePeGateway.pay()` in `payment_service.dart`
3. Set `PaymentMethod.phonePe.isEnabled = true` in `enums.dart`

**To enable Paytm:** same pattern with `paytm_allinonesdk`

### 3. Scheduled Delivery Slots
- `DeliverySlot` enum added to `enums.dart` (ASAP + 30-min windows 10 AM – 9 PM)
- `OrderModel` has new `scheduledSlot` field (nullable — null = ASAP)
- Checkout screen shows a dropdown slot picker
- Seller dashboard Orders tab displays the scheduled slot on each order card

### 4. Shop Order Accept / Reject Workflow ✅ (already existed, now visible)
- Seller dashboard `_OrdersTab._orderActions()` shows **Accept / Reject** buttons for `placed` orders
- `OrderStatus.rejected` is a terminal status

### 5. Rider Online / Offline Status ✅ (already existed, now hardened)
- `RiderStatus` enum: `offline`, `online`, `onDelivery`
- `RiderDashboardScreen` switch toggles `RiderRepository.setStatus()`
- GPS stream starts on online, stops on offline

### 6. Hyperlocal Radius Filtering — Chopasni First
- `AppConstants.chopasniLat/Lng` = Chopasni, Jodhpur coordinates
- `AppConstants.hyperlocalRadiusKm` = 3.0 km (tight first-launch radius)
- `ShopRepository.nearbyShops()` accepts `useHyperlocal` flag
- Set `useHyperlocal: true` in `HomeProviders` to restrict to Chopasni radius

### 7. E-Mitra Document Upload + Print Orders
- **New model:** `lib/data/models/emitra_order_model.dart`
- **New repository:** `lib/data/repositories/emitra_repository.dart`
  - `uploadDocument()` — Firebase Storage upload
  - `placeOrder()` / `customerOrders()` / `pendingOrders()` / `updateStatus()`
- **New screen:** `lib/features/emitra/screens/emitra_screen.dart`
  - Service type picker (Aadhaar, PAN, income cert, caste cert, …)
  - Multi-file upload via `image_picker`
  - Copies + colour toggle, estimated price
  - Firestore order creation
- **E-Mitra tab** added to `CustomerShell` bottom navigation (5 tabs)
- `EMitraServiceType` enum in `enums.dart`
- Route `/emitra` added to `AppRouter`

### 8. Inventory Sync + Low-Stock Alerts
- `ProductRepository.lowStockProducts(shopId, threshold)` — Firestore query
- `ProductRepository.updateStock(productId, newStock)` — atomic stock update
- `lowStockProductsProvider` in `seller_providers.dart`
- Seller **Overview tab** shows amber warning banner when any product is low
- Seller **Inventory tab** shows ⚠️ icon next to low-stock items
- `ShopModel.lowStockThreshold` field (per-shop customizable, default = 5)
- `AppConstants.lowStockThreshold` = 5

### 9. Admin Approval for Shops and Riders ✅ (already existed, hardened)
- `ShopModel.approvalStatus` field ('pending' / 'approved' / 'rejected')
- `ShopRepository.setApproval(shopId, approved: bool)` updates both `isApproved` and `approvalStatus`
- `ShopRepository.pendingShops()` queries `approvalStatus == 'pending'`
- Seller dashboard shows "Rejected" chip (not just "Pending") when rejected
- Rider KYC approval unchanged (was already complete)

### 10. Google Sign-In → Android Only Notice
- `LoginScreen._google()` checks `Platform.isAndroid` before proceeding
- On non-Android: shows `AlertDialog` explaining this is Android-only with a shortcut to Phone login
- On Android: proceeds normally
- Non-Android devices see a small hint text under the Google button

---

## Files Added
- `lib/data/services/payment_service.dart`
- `lib/data/models/emitra_order_model.dart`
- `lib/data/repositories/emitra_repository.dart`
- `lib/features/emitra/screens/emitra_screen.dart`
- `DOORBELL_CHANGES.md` (this file)

## Files Modified
- `pubspec.yaml`
- `lib/main.dart`
- `lib/app.dart`
- `lib/core/constants/app_constants.dart`
- `lib/data/models/enums.dart`
- `lib/data/models/order_model.dart`
- `lib/data/models/shop_model.dart`
- `lib/data/models/product_model.dart`
- `lib/data/repositories/shop_repository.dart`
- `lib/data/repositories/product_repository.dart`
- `lib/features/auth/screens/login_screen.dart`
- `lib/features/checkout/screens/checkout_screen.dart`
- `lib/features/home/screens/customer_shell.dart`
- `lib/features/seller/seller_providers.dart`
- `lib/features/seller/screens/seller_dashboard_screen.dart`
- `lib/features/admin/screens/admin_dashboard_screen.dart`
- `lib/features/wallet/wallet_screen.dart`
- `android/app/src/main/AndroidManifest.xml`
- `android/app/src/main/kotlin/com/doorbell/doorbell/MainActivity.kt`
- `ios/Runner/Info.plist`

## Files Removed
- `lib/data/services/razorpay_service.dart` (replaced by `payment_service.dart`)
