class AppStrings {
  // App Title
  static const String appName = "زيد اياد للديون";
  static const String appSubtitle = "إدارة الديون والمستحقات بدقة وسهولة";

  // Common Labels
  static const String home = "الرئيسية";
  static const String settings = "الإعدادات";
  static const String reports = "التقارير";
  static const String save = "حفظ";
  static const String cancel = "إلغاء";
  static const String delete = "حذف";
  static const String edit = "تعديل";
  static const String confirm = "تأكيد";
  static const String close = "إغلاق";
  static const String searchHint = "بحث عن شخص...";
  static const String noDataFound = "لا توجد بيانات حالياً";
  static const String notes = "ملاحظات";
  static const String date = "التاريخ";
  static const String amount = "المبلغ";
  static const String currency = "العملة";

  // Currencies
  static const String iqd = "د.ع";
  static const String iqdFullName = "دينار عراقي";
  static const String usd = "\$";
  static const String usdFullName = "دولار أمريكي";

  // Debt Types
  static const String debtForMe = "دين لي (مستحق)";
  static const String debtOnMe = "دين علي (مطلوب)";
  static const String totalForMe = "إجمالي لي";
  static const String totalOnMe = "إجمالي علي";
  static const String netBalance = "صافي الرصيد";
  static const String balanced = "خالص الذمة (متوازن)";

  // Person Details
  static const String personName = "اسم الشخص";
  static const String phoneNumber = "رقم الهاتف (اختياري)";
  static const String addPerson = "إضافة شخص جديد";
  static const String editPerson = "تعديل بيانات الشخص";
  static const String deletePerson = "حذف الشخص";
  static const String deletePersonConfirm = "هل أنت متأكد من حذف هذا الشخص؟ سيتم حذف جميع الحركات المالية المرتبطة به بشكل نهائي.";
  static const String callPerson = "اتصال";
  static const String whatsappPerson = "واتساب";

  // Transactions
  static const String addTransaction = "إضافة حركة مالية";
  static const String editTransaction = "تعديل الحركة";
  static const String deleteTransaction = "حذف الحركة";
  static const String deleteTransactionConfirm = "هل أنت متأكد من حذف هذه الحركة المالية؟";
  static const String transactionType = "نوع الحركة";
  static const String transactionNoteHint = "سبب الدين أو تفاصيل الحركة...";
  static const String transactionAddedSuccess = "تمت إضافة الحركة المالية بنجاح";
  static const String transactionUpdatedSuccess = "تم تعديل الحركة المالية بنجاح";
  static const String transactionDeletedSuccess = "تم حذف الحركة المالية";

  // Exchange Rate & Summary
  static const String exchangeRate = "سعر الصرف (الدولار مقابل الدينار)";
  static const String exchangeRateHint = "مثال: 1530";
  static const String exchangeRateDescription = "يستخدم لحساب الإجمالي التقديري الموحد بدون اتصال إنترنت";
  static const String equivalentTotal = "الإجمالي التقديري بالدينار";
  static const String summaryBothCurrencies = "إجماليات العملتين";

  // Backup & Restore
  static const String backupAndRestore = "النسخ الاحتياطي والاسترجاع";
  static const String exportBackup = "تصدير نسخة احتياطية (JSON)";
  static const String exportBackupDesc = "حفظ أو مشاركة ملف النسخة الاحتياطية للأمان أو نقله لجهاز آخر";
  static const String importBackup = "استرجاع نسخة احتياطية";
  static const String importBackupDesc = "استعادة البيانات من ملف نسخة احتياطية تم تصديره مسبقاً";
  static const String importBackupConfirmTitle = "تنبيه هام: استرجاع البيانات";
  static const String importBackupConfirmMsg = "استرجاع النسخة الاحتياطية سيقوم باستبدال جميع البيانات الحالية بالبيانات الموجودة في الملف.\n\nهل أنت متأكد من المتابعة؟";
  static const String backupExportedSuccess = "تم تصدير النسخة الاحتياطية بنجاح";
  static const String backupImportedSuccess = "تم استرجاع البيانات بنجاح";
  static const String backupError = "حدث خطأ أثناء معالجة النسخة الاحتياطية";

  // Validation
  static const String nameRequired = "يرجى إدخال اسم الشخص";
  static const String amountRequired = "يرجى إدخال المبلغ";
  static const String validAmountRequired = "يرجى إدخال مبلغ صحيح أكبر من الصفر";
}
