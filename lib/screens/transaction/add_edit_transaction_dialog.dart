import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/dialog_helper.dart';
import '../../models/transaction_model.dart';
import '../../providers/debt_provider.dart';

class AddEditTransactionDialog extends StatefulWidget {
  final int personId;
  final String personName;
  final DebtTransaction? transactionToEdit;
  final String? initialType; // 'for_me' or 'on_me'

  const AddEditTransactionDialog({
    super.key,
    required this.personId,
    required this.personName,
    this.transactionToEdit,
    this.initialType,
  });

  static Future<void> show(
    BuildContext context, {
    required int personId,
    required String personName,
    DebtTransaction? transactionToEdit,
    String? initialType,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddEditTransactionDialog(
        personId: personId,
        personName: personName,
        transactionToEdit: transactionToEdit,
        initialType: initialType,
      ),
    );
  }

  @override
  State<AddEditTransactionDialog> createState() => _AddEditTransactionDialogState();
}

class _AddEditTransactionDialogState extends State<AddEditTransactionDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  late TextEditingController _notesController;

  late String _type; // 'for_me' or 'on_me'
  late String _currency; // 'IQD' or 'USD'
  late DateTime _selectedDate;
  bool _isLoading = false;

  bool get isEditing => widget.transactionToEdit != null;

  @override
  void initState() {
    super.initState();
    final tr = widget.transactionToEdit;
    _type = tr?.type ?? widget.initialType ?? 'for_me';
    _currency = tr?.currency ?? 'IQD';
    _selectedDate = tr?.date ?? DateTime.now();

    _amountController = TextEditingController(
      text: tr != null
          ? (_currency == 'IQD'
              ? tr.amount.toInt().toString()
              : tr.amount.toString())
          : '',
    );
    _notesController = TextEditingController(text: tr?.notes ?? '');
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (ctx, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final rawAmount = double.tryParse(_amountController.text.replaceAll(',', ''));
    if (rawAmount == null || rawAmount <= 0) {
      DialogHelper.showSnackBar(context, message: AppStrings.validAmountRequired, isError: true);
      return;
    }

    setState(() => _isLoading = true);

    final provider = context.read<DebtProvider>();
    final notes = _notesController.text.trim();

    try {
      if (isEditing) {
        final updated = widget.transactionToEdit!.copyWith(
          type: _type,
          amount: rawAmount,
          currency: _currency,
          date: _selectedDate,
          notes: notes.isEmpty ? null : notes,
        );
        await provider.updateTransaction(updated);
        if (mounted) {
          Navigator.of(context).pop();
          DialogHelper.showSnackBar(context, message: AppStrings.transactionUpdatedSuccess, isSuccess: true);
        }
      } else {
        await provider.addTransaction(
          personId: widget.personId,
          type: _type,
          amount: rawAmount,
          currency: _currency,
          date: _selectedDate,
          notes: notes.isEmpty ? null : notes,
        );
        if (mounted) {
          Navigator.of(context).pop();
          DialogHelper.showSnackBar(context, message: AppStrings.transactionAddedSuccess, isSuccess: true);
        }
      }
    } catch (e) {
      if (mounted) {
        DialogHelper.showSnackBar(context, message: "حدث خطأ أثناء حفظ الحركة", isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: AppColors.softShadow3D(),
        ),
        padding: EdgeInsets.fromLTRB(24, 20, 24, 20 + bottomInset),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // مقبض سحب علوي
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.textMuted.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // العنوان مع اسم الشخص
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (_type == 'for_me' ? AppColors.debtForMe : AppColors.debtOnMe)
                            .withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        _type == 'for_me' ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                        color: _type == 'for_me' ? AppColors.debtForMe : AppColors.debtOnMe,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEditing ? AppStrings.editTransaction : AppStrings.addTransaction,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "الحساب: ${widget.personName}",
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // محدد نوع الدين (دين لي / دين علي)
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _type = 'for_me'),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _type == 'for_me'
                                ? AppColors.debtForMe.withOpacity(0.14)
                                : isDark
                                    ? AppColors.darkSurfaceCard
                                    : AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _type == 'for_me'
                                  ? AppColors.debtForMe
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.call_received_rounded,
                                color: _type == 'for_me'
                                    ? AppColors.debtForMe
                                    : AppColors.textSecondary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "دين لي",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _type == 'for_me'
                                      ? AppColors.debtForMe
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _type = 'on_me'),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _type == 'on_me'
                                ? AppColors.debtOnMe.withOpacity(0.14)
                                : isDark
                                    ? AppColors.darkSurfaceCard
                                    : AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _type == 'on_me'
                                  ? AppColors.debtOnMe
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.call_made_rounded,
                                color: _type == 'on_me'
                                    ? AppColors.debtOnMe
                                    : AppColors.textSecondary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "دين علي",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _type == 'on_me'
                                      ? AppColors.debtOnMe
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // محدد العملة (IQD أو USD)
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _currency = 'IQD'),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _currency == 'IQD'
                                ? AppColors.currencyIQD.withOpacity(0.14)
                                : isDark
                                    ? AppColors.darkSurfaceCard
                                    : AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _currency == 'IQD'
                                  ? AppColors.currencyIQD
                                  : Colors.transparent,
                              width: 1.8,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              "دينار عراقي (IQD)",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _currency == 'IQD'
                                    ? AppColors.currencyIQD
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _currency = 'USD'),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _currency == 'USD'
                                ? AppColors.currencyUSD.withOpacity(0.14)
                                : isDark
                                    ? AppColors.darkSurfaceCard
                                    : AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _currency == 'USD'
                                  ? AppColors.currencyUSD
                                  : Colors.transparent,
                              width: 1.8,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              "دولار أمريكي (USD)",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _currency == 'USD'
                                    ? AppColors.currencyUSD
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // حقل المبلغ
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    labelText: AppStrings.amount,
                    prefixIcon: const Icon(Icons.monetization_on_outlined),
                    suffixText: _currency == 'IQD' ? AppStrings.iqd : AppStrings.usd,
                    suffixStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return AppStrings.amountRequired;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // اختيار التاريخ
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurfaceCard : AppColors.surfaceVariant.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.border,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 22, color: AppColors.primary),
                        const SizedBox(width: 12),
                        Text(
                          "التاريخ: ${DateFormatter.formatDate(_selectedDate)}",
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                        const Spacer(),
                        const Icon(Icons.keyboard_arrow_left_rounded, color: AppColors.textMuted),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // حقل الملاحظة / تفاصيل الحركة
                TextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: AppStrings.notes,
                    hintText: AppStrings.transactionNoteHint,
                    prefixIcon: Icon(Icons.edit_note_rounded),
                  ),
                ),
                const SizedBox(height: 24),

                // أزرار الحفظ والإلغاء
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          AppStrings.cancel,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _type == 'for_me' ? AppColors.debtForMeDark : AppColors.debtOnMeDark,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                isEditing ? AppStrings.save : "حفظ الحركة المالية",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
