import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/dialog_helper.dart';
import '../../../models/transaction_model.dart';
import '../../../providers/debt_provider.dart';
import '../../../widgets/custom_3d_card.dart';
import '../../transaction/add_edit_transaction_dialog.dart';

class TransactionTile extends StatelessWidget {
  final DebtTransaction transaction;
  final String personName;

  const TransactionTile({
    super.key,
    required this.transaction,
    required this.personName,
  });

  Future<void> _handleDelete(BuildContext context) async {
    final confirmed = await DialogHelper.showConfirmationDialog(
      context,
      title: AppStrings.deleteTransaction,
      message: AppStrings.deleteTransactionConfirm,
      confirmText: AppStrings.delete,
      isDestructive: true,
      icon: Icons.delete_outline_rounded,
    );

    if (confirmed && context.mounted) {
      final provider = context.read<DebtProvider>();
      await provider.deleteTransaction(transaction.id!, transaction.personId);
      if (context.mounted) {
        DialogHelper.showSnackBar(
          context,
          message: AppStrings.transactionDeletedSuccess,
          isSuccess: true,
        );
      }
    }
  }

  void _handleEdit(BuildContext context) {
    AddEditTransactionDialog.show(
      context,
      personId: transaction.personId,
      personName: personName,
      transactionToEdit: transaction,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isForMe = transaction.isForMe;
    final color = isForMe ? AppColors.debtForMe : AppColors.debtOnMe;
    final bgColor = isForMe ? AppColors.debtForMeLight : AppColors.debtOnMeLight;

    return Custom3dCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      borderRadius: 18,
      child: Row(
        children: [
          // أيقونة نوع الحركة (استلام / تسليم)
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isDark ? color.withOpacity(0.18) : bgColor.withOpacity(0.8),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withOpacity(0.3), width: 1),
            ),
            child: Icon(
              isForMe ? Icons.call_received_rounded : Icons.call_made_rounded,
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),

          // التفاصيل والملاحظة والتاريخ
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      isForMe ? "دين لي (مستحق)" : "دين علي (مطلوب)",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: transaction.isIqd
                            ? AppColors.currencyIQD.withOpacity(0.12)
                            : AppColors.currencyUSD.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        transaction.currency,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: transaction.isIqd
                              ? AppColors.currencyIQD
                              : AppColors.currencyUSD,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (transaction.notes != null && transaction.notes!.isNotEmpty) ...[
                  Text(
                    transaction.notes!,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                ],
                Text(
                  DateFormatter.formatRelativeDate(transaction.date),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.textMuted : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // المبلغ والقائمة
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "${isForMe ? '+' : '-'}${CurrencyFormatter.formatWithSymbol(transaction.amount, transaction.currency)}",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.more_horiz_rounded, color: AppColors.textMuted, size: 20),
                onSelected: (val) {
                  if (val == 'edit') {
                    _handleEdit(context);
                  } else if (val == 'delete') {
                    _handleDelete(context);
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
                        SizedBox(width: 8),
                        Text(AppStrings.edit),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.debtOnMe),
                        SizedBox(width: 8),
                        Text(AppStrings.delete, style: TextStyle(color: AppColors.debtOnMe)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
