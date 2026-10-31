import 'package:intl/intl.dart';

class Formatters {
  static String formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
  
  static String formatCurrency(double amount, {String symbol = '₹'}) {
    final formatter = NumberFormat.currency(symbol: symbol, decimalDigits: 0);
    return formatter.format(amount);
  }
  
  static String formatDecimal(double value, {int decimals = 2}) {
    return value.toStringAsFixed(decimals);
  }
  
  static String formatDate(DateTime date, {String pattern = 'MMM dd, yyyy'}) {
    return DateFormat(pattern).format(date);
  }
  
  static String formatDateTime(DateTime date, {String pattern = 'MMM dd, yyyy HH:mm'}) {
    return DateFormat(pattern).format(date);
  }
  
  static String formatTime(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }
  
  static String formatRelativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return formatDate(date);
  }
  
  static String formatPercentage(double value) {
    return '${value.toStringAsFixed(1)}%';
  }
  
  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }
}