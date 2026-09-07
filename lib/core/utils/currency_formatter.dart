import 'package:intl/intl.dart';
import '../constants/app_strings.dart';

class CurrencyFormatter {
  static final NumberFormat _iqdFormat = NumberFormat("#,##0", "en_US");
  static final NumberFormat _usdCleanFormat = NumberFormat("#,##0.##", "en_US");

  /// تنسيق المبلغ مع رمز العملة
  static String formatWithSymbol(double amount, String currencyCode) {
    if (currencyCode.toUpperCase() == 'IQD') {
      return "${_iqdFormat.format(amount.abs())} ${AppStrings.iqd}";
    } else {
      return "${AppStrings.usd}${_usdCleanFormat.format(amount.abs())}";
    }
  }

  /// تنسيق الرقم المجرد بدون رمز
  static String formatAmount(double amount, String currencyCode) {
    if (currencyCode.toUpperCase() == 'IQD') {
      return _iqdFormat.format(amount);
    } else {
      return _usdCleanFormat.format(amount);
    }
  }

  /// تحويل مبلغ من الدولار إلى الدينار العراقي بحسب سعر الصرف اليدوي
  static double convertUsdToIqd(double amountInUsd, double exchangeRate) {
    return amountInUsd * exchangeRate;
  }

  /// تحويل مبلغ من الدينار إلى الدولار بحسب سعر الصرف اليدوي
  static double convertIqdToUsd(double amountInIqd, double exchangeRate) {
    if (exchangeRate <= 0) return 0.0;
    return amountInIqd / exchangeRate;
  }

  /// حساب الإجمالي المكافئ بالدينار
  static double calculateEquivalentInIqd({
    required double iqdAmount,
    required double usdAmount,
    required double exchangeRate,
  }) {
    return iqdAmount + (usdAmount * exchangeRate);
  }
}
