import '../l10n/strings.dart';

/// intl paketine ihtiyac duymadan tarih/saat bicimleme.
class Formatters {
  static String _two(int value) => value.toString().padLeft(2, '0');

  static String time(DateTime value) =>
      '${_two(value.hour)}:${_two(value.minute)}';

  static String date(DateTime value) =>
      '${_two(value.day)}.${_two(value.month)}.${value.year}';

  /// "Bugün 14:32", "Dün 09:05" veya "12.11.2026 09:05".
  static String friendly(DateTime? value, AppStrings strings) {
    if (value == null) return '—';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(value.year, value.month, value.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return '${strings.t('today')} ${time(value)}';
    if (diff == 1) return '${strings.t('yesterday')} ${time(value)}';
    return '${date(value)} ${time(value)}';
  }

  static bool isToday(DateTime? value) {
    if (value == null) return false;
    final now = DateTime.now();
    return value.year == now.year &&
        value.month == now.month &&
        value.day == now.day;
  }

  /// Ad ve soyadin bas harfleri; yoksa tek harf.
  static String initials(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}
