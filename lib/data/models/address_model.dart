/// A saved delivery address belonging to a customer.
class AddressModel {
  const AddressModel({
    required this.id,
    required this.label,
    required this.line1,
    this.line2,
    required this.city,
    required this.pincode,
    required this.latitude,
    required this.longitude,
    this.isDefault = false,
  });

  final String id;
  final String label; // Home / Work / Other
  final String line1;
  final String? line2;
  final String city;
  final String pincode;
  final double latitude;
  final double longitude;
  final bool isDefault;

  String get formatted =>
      [line1, if (line2 != null && line2!.isNotEmpty) line2, city, pincode]
          .join(', ');

  factory AddressModel.fromMap(Map<String, dynamic> map) => AddressModel(
        id: map['id'] as String? ?? '',
        label: map['label'] as String? ?? 'Home',
        line1: map['line1'] as String? ?? '',
        line2: map['line2'] as String?,
        city: map['city'] as String? ?? '',
        pincode: map['pincode'] as String? ?? '',
        latitude: (map['latitude'] as num?)?.toDouble() ?? 0,
        longitude: (map['longitude'] as num?)?.toDouble() ?? 0,
        isDefault: map['isDefault'] as bool? ?? false,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'label': label,
        'line1': line1,
        'line2': line2,
        'city': city,
        'pincode': pincode,
        'latitude': latitude,
        'longitude': longitude,
        'isDefault': isDefault,
      };

  AddressModel copyWith({bool? isDefault}) => AddressModel(
        id: id,
        label: label,
        line1: line1,
        line2: line2,
        city: city,
        pincode: pincode,
        latitude: latitude,
        longitude: longitude,
        isDefault: isDefault ?? this.isDefault,
      );
}
