/// 日期工具类
class DateUtils {
  /// 格式化为"多久之前"的形式
  static String formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}年前';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}个月前';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}天前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}小时前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分钟前';
    } else {
      return '刚刚';
    }
  }

  /// 格式化为标准日期时间格式
  static String formatDateTime(DateTime date) {
    return '${date.year}-${_twoDigits(date.month)}-${_twoDigits(date.day)} '
        '${_twoDigits(date.hour)}:${_twoDigits(date.minute)}';
  }

  /// 格式化为日期格式
  static String formatDate(DateTime date) {
    return '${date.year}-${_twoDigits(date.month)}-${_twoDigits(date.day)}';
  }

  /// 格式化为时间格式
  static String formatTime(DateTime date) {
    return '${_twoDigits(date.hour)}:${_twoDigits(date.minute)}';
  }

  /// 将数字格式化为两位数字符串
  static String _twoDigits(int n) {
    if (n >= 10) return '$n';
    return '0$n';
  }

  /// 获取今天的开始时间
  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// 获取今天的结束时间
  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
  }

  /// 获取本周的开始时间（周一）
  static DateTime startOfWeek(DateTime date) {
    final diff = date.weekday - 1;
    return startOfDay(date.subtract(Duration(days: diff)));
  }

  /// 获取本周的结束时间（周日）
  static DateTime endOfWeek(DateTime date) {
    final diff = 7 - date.weekday;
    return endOfDay(date.add(Duration(days: diff)));
  }

  /// 获取本月的开始时间
  static DateTime startOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  /// 获取本月的结束时间
  static DateTime endOfMonth(DateTime date) {
    return endOfDay(DateTime(date.year, date.month + 1, 0));
  }

  /// 检查是否是同一天
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  /// 检查是否是今天
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return isSameDay(date, now);
  }

  /// 检查是否是昨天
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return isSameDay(date, yesterday);
  }

  /// 检查是否是本周
  static bool isThisWeek(DateTime date) {
    final now = DateTime.now();
    return date.isAfter(startOfWeek(now)) && date.isBefore(endOfWeek(now));
  }

  /// 检查是否是本月
  static bool isThisMonth(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month;
  }
} 