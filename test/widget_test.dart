// DoorBell unit tests. Widget tests that pump the full app require a Firebase
// test harness; here we cover pure business logic that needs no plugins.
import 'package:flutter_test/flutter_test.dart';
import 'package:doorbell/core/utils/geo_utils.dart';
import 'package:doorbell/data/models/coupon_model.dart';

void main() {
  test('Haversine distance between two close points is small', () {
    final d = GeoUtils.distanceKm(12.9716, 77.5946, 12.9352, 77.6245);
    expect(d, greaterThan(0));
    expect(d, lessThan(10));
  });

  test('Percentage coupon respects max discount cap', () {
    const coupon = CouponModel(
      code: 'SAVE20',
      description: '20% off up to ₹50',
      isPercent: true,
      value: 20,
      maxDiscount: 50,
      minOrderValue: 100,
    );
    final (discount, error) = coupon.discountFor(1000);
    expect(error, isNull);
    expect(discount, 50); // 20% of 1000 = 200, capped at 50
  });

  test('Coupon rejects orders below minimum value', () {
    const coupon = CouponModel(
      code: 'MIN200',
      description: 'Flat ₹30 off above ₹200',
      isPercent: false,
      value: 30,
      minOrderValue: 200,
    );
    final (discount, error) = coupon.discountFor(150);
    expect(discount, 0);
    expect(error, isNotNull);
  });
}
