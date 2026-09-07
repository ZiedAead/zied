import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/person_model.dart';
import '../../../widgets/custom_3d_card.dart';

class PersonCard extends StatelessWidget {
  final Person person;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const PersonCard({
    super.key,
    required this.person,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Custom3dCard(
      onTap: onTap,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              // صورة رمزية ثلاثية الأبعاد
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryLight.withOpacity(0.85),
                      AppColors.primaryDark,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.25),
                      offset: const Offset(0, 4),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    person.name.isNotEmpty ? person.name.substring(0, 1) : "؟",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // الاسم ورقم الهاتف
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      person.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    if (person.phone != null && person.phone!.isNotEmpty)
                      Row(
                        children: [
                          Icon(
                            Icons.phone_iphone_rounded,
                            size: 14,
                            color: isDark ? AppColors.textMuted : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            person.phone!,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? AppColors.textMuted : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        "${person.transactionCount} حركات مسجلة",
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.textMuted : AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),

              // سهم الانتقال
              const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16,
                color: AppColors.textMuted,
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.borderSubtle),
          const SizedBox(height: 12),

          // شارات الأرصدة (دينار ودولار)
          if (person.isSettled)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: (isDark ? Colors.white10 : AppColors.surfaceVariant),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_rounded, color: AppColors.primaryLight, size: 16),
                  SizedBox(width: 6),
                  Text(
                    AppStrings.balanced,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryLight,
                    ),
                  ),
                ],
              ),
            )
          else
            Row(
              children: [
                // رصيد الدينار
                if (person.hasIqdDebt)
                  Expanded(
                    child: _buildCurrencyBadge(
                      context,
                      currency: 'IQD',
                      amount: person.netBalanceIqd,
                      isForMe: person.isIqdForMe,
                    ),
                  ),

                if (person.hasIqdDebt && person.hasUsdDebt) const SizedBox(width: 8),

                // رصيد الدولار
                if (person.hasUsdDebt)
                  Expanded(
                    child: _buildCurrencyBadge(
                      context,
                      currency: 'USD',
                      amount: person.netBalanceUsd,
                      isForMe: person.isUsdForMe,
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildCurrencyBadge(
    BuildContext context, {
    required String currency,
    required double amount,
    required bool isForMe,
  }) {
    final color = isForMe ? AppColors.debtForMe : AppColors.debtOnMe;
    final bgColor = isForMe ? AppColors.debtForMeLight : AppColors.debtOnMeLight;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final formatted = CurrencyFormatter.formatWithSymbol(amount.abs(), currency);
    final prefix = isForMe ? "لي: +" : "علي: -";

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? color.withOpacity(0.15) : bgColor.withOpacity(0.7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isForMe ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              "$prefix$formatted",
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
