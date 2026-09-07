import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/dialog_helper.dart';
import '../../providers/debt_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/backup_service.dart';
import '../../widgets/custom_3d_card.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isExporting = false;
  bool _isImporting = false;

  Future<void> _editExchangeRate(BuildContext context) async {
    final settings = context.read<SettingsProvider>();
    final controller = TextEditingController(text: settings.exchangeRate.toInt().toString());

    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.currency_exchange_rounded, color: AppColors.primary),
              SizedBox(width: 10),
              Text("تعديل سعر الصرف"),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "أدخل قيمة 1 دولار أمريكي بالدينار العراقي:",
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: "سعر الصرف (IQD)",
                  suffixText: "د.ع",
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text(AppStrings.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                final rate = double.tryParse(controller.text.trim());
                if (rate != null && rate > 0) {
                  Navigator.of(ctx).pop(rate);
                }
              },
              child: const Text(AppStrings.save),
            ),
          ],
        ),
      ),
    );

    if (result != null && mounted) {
      await settings.setExchangeRate(result);
      if (mounted) {
        DialogHelper.showSnackBar(context, message: "تم تحديث سعر الصرف بنجاح", isSuccess: true);
      }
    }
  }

  Future<void> _exportBackup(BuildContext context) async {
    setState(() => _isExporting = true);
    final rate = context.read<SettingsProvider>().exchangeRate;

    try {
      final success = await BackupService.exportAndShareBackup(rate);
      if (mounted && success) {
        DialogHelper.showSnackBar(context, message: AppStrings.backupExportedSuccess, isSuccess: true);
      }
    } catch (_) {
      if (mounted) {
        DialogHelper.showSnackBar(context, message: AppStrings.backupError, isError: true);
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _importBackup(BuildContext context) async {
    try {
      final backupData = await BackupService.pickBackupFile();
      if (backupData == null) return; // المستخدم ألغى الاختيار

      if (!mounted) return;

      // نافذة التأكيد قبل الاسترجاع
      final confirmed = await DialogHelper.showConfirmationDialog(
        context,
        title: AppStrings.importBackupConfirmTitle,
        message: "${AppStrings.importBackupConfirmMsg}\n\nيحتوي الملف على (${backupData.persons.length}) أشخاص و (${backupData.transactions.length}) حركة مالية.",
        confirmText: "استرجاع واستبدال البيانات",
        isDestructive: true,
        icon: Icons.restore_page_rounded,
      );

      if (confirmed && mounted) {
        setState(() => _isImporting = true);
        final debtProvider = context.read<DebtProvider>();
        final settingsProvider = context.read<SettingsProvider>();

        await debtProvider.restoreFromBackup(backupData);
        if (backupData.exchangeRate > 0) {
          await settingsProvider.setExchangeRate(backupData.exchangeRate);
        }

        if (mounted) {
          DialogHelper.showSnackBar(context, message: AppStrings.backupImportedSuccess, isSuccess: true);
        }
      }
    } catch (_) {
      if (mounted) {
        DialogHelper.showSnackBar(context, message: AppStrings.backupError, isError: true);
      }
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  Future<void> _clearAllData(BuildContext context) async {
    final confirmed = await DialogHelper.showConfirmationDialog(
      context,
      title: "مسح جميع البيانات",
      message: "هل أنت متأكد من مسح وتصفير كافة سجلات الديون والحركات؟ لا يمكن التراجع عن هذا الإجراء إلا بوجود نسخة احتياطية.",
      confirmText: "مسح الكل نهائياً",
      isDestructive: true,
      icon: Icons.delete_forever_rounded,
    );

    if (confirmed && mounted) {
      await context.read<DebtProvider>().clearAll();
      if (mounted) {
        DialogHelper.showSnackBar(context, message: "تم مسح جميع البيانات بنجاح", isSuccess: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(AppStrings.settings),
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // قسم سعر الصرف
            _buildSectionHeader("سعر الصرف والحسابات"),
            const SizedBox(height: 10),
            Custom3dCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.currencyUSD.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.currency_exchange_rounded, color: AppColors.currencyUSD, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "سعر صرف الدولار",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "1 دولار = ${settings.exchangeRate.toInt()} دينار عراقي",
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          AppStrings.exchangeRateDescription,
                          style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_note_rounded, color: AppColors.primary, size: 26),
                    onPressed: () => _editExchangeRate(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // قسم النسخ الاحتياطي والاسترجاع
            _buildSectionHeader(AppStrings.backupAndRestore),
            const SizedBox(height: 10),
            Custom3dCard(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.cloud_upload_rounded, color: AppColors.primary),
                    ),
                    title: const Text(
                      AppStrings.exportBackup,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    subtitle: const Text(
                      AppStrings.exportBackupDesc,
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    trailing: _isExporting
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.share_rounded, color: AppColors.primary, size: 20),
                    onTap: _isExporting ? null : () => _exportBackup(context),
                  ),
                  const Divider(height: 1, color: AppColors.borderSubtle),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.currencyIQD.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.cloud_download_rounded, color: AppColors.currencyIQD),
                    ),
                    title: const Text(
                      AppStrings.importBackup,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    subtitle: const Text(
                      AppStrings.importBackupDesc,
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    trailing: _isImporting
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.file_open_rounded, color: AppColors.currencyIQD, size: 20),
                    onTap: _isImporting ? null : () => _importBackup(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // المظهر والخيارات العامة
            _buildSectionHeader("المظهر والنظام"),
            const SizedBox(height: 10),
            Custom3dCard(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        settings.isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                        color: Colors.amber.shade700,
                      ),
                    ),
                    title: const Text(
                      "الوضع الداكن (Dark Mode)",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    trailing: Switch(
                      value: settings.isDarkMode,
                      activeColor: AppColors.primaryLight,
                      onChanged: (_) => settings.toggleTheme(),
                    ),
                  ),
                  const Divider(height: 1, color: AppColors.borderSubtle),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.debtOnMe.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.delete_sweep_rounded, color: AppColors.debtOnMe),
                    ),
                    title: const Text(
                      "مسح وتصفير كافة البيانات",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.debtOnMe),
                    ),
                    subtitle: const Text(
                      "إعادة التطبيق لحالته الأولى كأنه جديد",
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    onTap: () => _clearAllData(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // معلومات التطبيق
            Center(
              child: Column(
                children: [
                  Text(
                    AppStrings.appName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primary),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "الإصدار 1.0.0 • يعمل محلياً بالكامل 100% بدون إنترنت",
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
