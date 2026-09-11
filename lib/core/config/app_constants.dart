class AppConstants {
  const AppConstants._();

  static const String appName = 'Pitbox Control';
  static const String currencySymbol = 'Bs.';
  static const String appTagline = 'Gestión base para taller mecánico';
  static const String upcomingLabel = 'Próximamente';

  static String formatCurrency(num amount) {
    final isNegative = amount < 0;
    final digits = amount.abs().round().toString();
    final reversed = digits.split('').reversed.toList();
    final parts = <String>[];

    for (int i = 0; i < reversed.length; i += 3) {
      final end = (i + 3 < reversed.length) ? i + 3 : reversed.length;
      parts.add(reversed.sublist(i, end).reversed.join());
    }

    final formatted = parts.reversed.join(',');
    final prefix = isNegative ? '-' : '';
    return '$prefix$currencySymbol $formatted';
  }
}
