import 'package:intl/intl.dart';

class DateFormatter {
  static final DateFormat _arabicDate = DateFormat('yyyy/MM/dd', 'en');
  static final DateFormat _dateTimeFormat = DateFormat('yyyy/MM/dd - hh:mm a', 'en');

  /// تنسيق التاريخ بصيغة سنة/شهر/يوم
  static String formatDate(DateTime date) {
    return _arabicDate.format(date);
  }

  /// تنسيق نسبي (اليوم، أمس، أو التاريخ)
  static String formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final aDate = DateTime(date.year, date.month, date.day);

    final difference = today.difference(aDate).inDays;

    if (difference == 0) {
      return "اليوم";
    } else if (difference == 1) {
      return "أمس";
    } else if (difference == -1) {
      return "غداً";
    } else {
      return _arabicDate.format(date);
    }
  }

  /// تنسيق التاريخ والوقت
  static String formatDateTime(DateTime date) {
    return _dateTimeFormat.format(date);
  }
}
