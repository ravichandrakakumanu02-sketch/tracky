/// Utility class for formatting dates cleanly without external dependencies.
class DateFormatter {
  static const List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  static const List<String> _shortMonths = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  static const List<String> _weekdays = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];

  static const List<String> _shortWeekdays = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
  ];

  /// Returns e.g. "Tuesday, 17 Nov 2026"
  static String formatFull(DateTime date) {
    final weekday = _weekdays[date.weekday - 1];
    final month = _shortMonths[date.month - 1];
    return '$weekday, ${date.day} $month ${date.year}';
  }

  /// Returns e.g. "Today", "Yesterday", or "Mon, 16 Nov"
  static String formatRelativeOrDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);

    final difference = today.difference(target).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else {
      final weekday = _shortWeekdays[date.weekday - 1];
      final month = _shortMonths[date.month - 1];
      return '$weekday, ${date.day} $month';
    }
  }

  /// Returns e.g. "17 November 2026"
  static String formatDisplay(DateTime date) {
    final month = _months[date.month - 1];
    return '${date.day} $month ${date.year}';
  }

  /// Returns e.g. "17 Nov"
  static String formatShort(DateTime date) {
    final month = _shortMonths[date.month - 1];
    return '${date.day} $month';
  }
}
