import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/person_model.dart';
import '../../providers/debt_provider.dart';
import '../../widgets/custom_3d_card.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final debtProv = context.watch<DebtProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final forMeIqd = debtProv.totalForMeIqd;
    final onMeIqd = debtProv.totalOnMeIqd;
    final totalIqd = forMeIqd + onMeIqd;

    final forMeUsd = debtProv.totalForMeUsd;
    final onMeUsd = debtProv.totalOnMeUsd;
    final totalUsd = forMeUsd + onMeUsd;

    final persons = debtProv.persons;
    final settledCount = persons.where((p) => p.isSettled).length;
    final activeCount = persons.length - settledCount;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(AppStrings.reports),
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // بطاقات الإحصائيات السريعة
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: "إجمالي الأشخاص",
                    value: "${persons.length}",
                    icon: Icons.people_alt_rounded,
                    color: AppColors.primary,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    title: "حسابات نشطة",
                    value: "$activeCount",
                    icon: Icons.hourglass_top_rounded,
                    color: AppColors.currencyUSD,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    title: "خالص الذمة",
                    value: "$settledCount",
                    icon: Icons.verified_rounded,
                    color: AppColors.debtForMe,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // رسم بياني للدينار العراقي (IQD)
            _buildChartSection(
              title: "توزيع الديون بالدينار العراقي (IQD)",
              total: totalIqd,
              forMe: forMeIqd,
              onMe: onMeIqd,
              currency: 'IQD',
              isDark: isDark,
            ),
            const SizedBox(height: 20),

            // رسم بياني للدولار الأمريكي (USD)
            _buildChartSection(
              title: "توزيع الديون بالدولار الأمريكي (USD)",
              total: totalUsd,
              forMe: forMeUsd,
              onMe: onMeUsd,
              currency: 'USD',
              isDark: isDark,
            ),
            const SizedBox(height: 20),

            // قائمة أكبر المستحقين / المطلوبين
            _buildTopPersonsSection(persons, isDark),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Custom3dCard(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? AppColors.textMuted : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildChartSection({
    required String title,
    required double total,
    required double forMe,
    required double onMe,
    required String currency,
    required bool isDark,
  }) {
    final hasData = total > 0;
    final forMePercent = hasData ? ((forMe / total) * 100).toInt() : 0;
    final onMePercent = hasData ? ((onMe / total) * 100).toInt() : 0;

    return Custom3dCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 16),
          if (!hasData)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: Text(
                  "لا توجد حركات مسجلة بهذه العملة حتى الآن",
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
              ),
            )
          else ...[
            SizedBox(
              height: 160,
              child: Stack(
                children: [
                  PieChart(
                    PieChartData(
                      sectionsSpace: 3,
                      centerSpaceRadius: 46,
                      sections: [
                        if (forMe > 0)
                          PieChartSectionData(
                            value: forMe,
                            color: AppColors.debtForMe,
                            title: "$forMePercent%",
                            radius: 36,
                            titleStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        if (onMe > 0)
                          PieChartSectionData(
                            value: onMe,
                            color: AppColors.debtOnMe,
                            title: "$onMePercent%",
                            radius: 36,
                            titleStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text("الإجمالي", style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                        Text(
                          CurrencyFormatter.formatWithSymbol(total, currency),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildLegendItem(
                  label: "دين لي: ${CurrencyFormatter.formatWithSymbol(forMe, currency)}",
                  color: AppColors.debtForMe,
                ),
                _buildLegendItem(
                  label: "دين علي: ${CurrencyFormatter.formatWithSymbol(onMe, currency)}",
                  color: AppColors.debtOnMe,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLegendItem({required String label, required Color color}) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildTopPersonsSection(List<Person> dynamicPersons, bool isDark) {
    if (dynamicPersons.isEmpty) return const SizedBox();

    return Custom3dCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.leaderboard_rounded, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text(
                "قائمة الأرصدة حسب الأشخاص",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...dynamicPersons.take(5).map((p) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    p.name,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  Row(
                    children: [
                      if (p.hasIqdDebt)
                        Text(
                          CurrencyFormatter.formatWithSymbol(p.netBalanceIqd.abs(), 'IQD'),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: p.isIqdForMe ? AppColors.debtForMe : AppColors.debtOnMe,
                          ),
                        ),
                      if (p.hasIqdDebt && p.hasUsdDebt) const SizedBox(width: 8),
                      if (p.hasUsdDebt)
                        Text(
                          CurrencyFormatter.formatWithSymbol(p.netBalanceUsd.abs(), 'USD'),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: p.isUsdForMe ? AppColors.debtForMe : AppColors.debtOnMe,
                          ),
                        ),
                      if (p.isSettled)
                        const Text(
                          "خالص",
                          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
