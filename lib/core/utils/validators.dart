/// Input validation helpers used across auth and registration forms.
class Validators {
  const Validators._();

  static final _emailRegex =
      RegExp(r'^[\w.\-]+@([\w\-]+\.)+[\w\-]{2,4}$');
  static final _phoneRegex = RegExp(r'^[6-9]\d{9}$');

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    if (!_emailRegex.hasMatch(value.trim())) return 'Enter a valid email';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'Minimum 6 characters';
    return null;
  }

  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) return 'Name is required';
    if (value.trim().length < 2) return 'Enter a valid name';
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Phone is required';
    if (!_phoneRegex.hasMatch(value.trim())) {
      return 'Enter a valid 10-digit mobile number';
    }
    return null;
  }

  static String? required(String? value, [String field = 'This field']) {
    if (value == null || value.trim().isEmpty) return '$field is required';
    return null;
  }

  static String? price(String? value) {
    if (value == null || value.trim().isEmpty) return 'Price is required';
    final n = double.tryParse(value);
    if (n == null || n < 0) return 'Enter a valid price';
    return null;
  }
}
