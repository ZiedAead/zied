import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/debt_provider.dart';
import '../../../providers/settings_provider.dart';

class BalanceSummaryCard extends StatelessWidget {
  const BalanceSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final debtProv = context.watch<DebtProvider>();
    final setProv = context.watch<SettingsProvider>();

    final rate = setProv.exchangeRate;

    // صافي العملتين
    final netIqd = debtProv.netIqd;
    final netUsd = debtProv.netUsd;

    // المجموع التقديري الموحد بالدينار
    final totalEquivalentIqd = CurrencyFormatter.calculateEquivalentInIqd(
      iqdAmount: netIqd,
      usdAmount: netUsd,
      exchangeRate: rate,
    );

    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.heroCardGradient,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: Colors.white.withOpacity(0.12),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.35),
            offset: const Offset(0, 14),
            blurRadius: 28,
            spreadRadius: -4,
          ),
          BoxShadow(
            color: AppColors.primary.withOpacity(0.2),
            offset: const Offset(0, 4),
            blurRadius: 12,
            spreadRadius: 0,
          ),
        ],
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // شريط علوي مع سعر الصرف
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.25),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: AppColors.primaryLight,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "ملخص الذمم والديون",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.12)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.currency_exchange_rounded, color: AppColors.currencyUSD, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      "\$1 = ${rate.toInt()} د.ع",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // الصافي الموحد بالدينار
          Center(
            child: Column(
              children: [
                Text(
                  AppStrings.equivalentTotal,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.65),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  CurrencyFormatter.formatWithSymbol(totalEquivalentIqd, 'IQD'),
                  style: TextStyle(
                    color: totalEquivalentIqd >= 0 ? AppColors.debtForMeLight : AppColors.debtOnMeLight,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // تفصيل العملتين (IQD و USD)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Row(
              children: [
                // عمود الدينار العراقي
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.currencyIQD,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            AppStrings.iqdFullName,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      _buildBalanceRow("لي:", debtProv.totalForMeIqd, 'IQD', AppColors.debtForMe),
                      const SizedBox(height: 2),
                      _buildBalanceRow("علي:", debtProv.totalOnMeIqd, 'IQD', AppColors.debtOnMe),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 50,
                  color: Colors.white.withOpacity(0.12),
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                ),
                // عمود الدولار الأمريكي
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.currencyUSD,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            AppStrings.usdFullName,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      _buildBalanceRow("لي:", debtProv.totalForMeUsd, 'USD', AppColors.debtForMe),
                      const SizedBox(height: 2),
                      _buildBalanceRow("علي:", debtProv.totalOnMeUsd, 'USD', AppColors.debtOnMe),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceRow(String label, double amount, String currency, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white60, fontSize: 12),
        ),
        Text(
          CurrencyFormatter.formatWithSymbol(amount, currency),
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
