import 'package:intl/intl.dart';

class DateUtil {
  static String dateWithDayFormat(DateTime dateTime) {
    // final weekName = _weekNames()[dateTime.weekday];
    final date = DateFormat('dd MMMM yyyy').format(dateTime);
    return date;
  }

  static bool isSameDate(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  static List<String> _weekNames() {
    return <String>[
      '',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
  }
}
