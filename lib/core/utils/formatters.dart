import 'package:intl/intl.dart';

/// Display formatting helpers (currency, dates, distance).
class Formatters {
  const Formatters._();

  static final _currency =
      NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  static String currency(num value) => _currency.format(value);

  static String date(DateTime date) => DateFormat('dd MMM yyyy').format(date);

  static String dateTime(DateTime date) =>
      DateFormat('dd MMM, hh:mm a').format(date);

  static String time(DateTime date) => DateFormat('hh:mm a').format(date);

  /// Human-friendly distance: "850 m" or "2.4 km".
  static String distance(double km) {
    if (km < 1) return '${(km * 1000).round()} m';
    return '${km.toStringAsFixed(1)} km';
  }

  static String relativeTime(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return Formatters.date(date);
  }
}
