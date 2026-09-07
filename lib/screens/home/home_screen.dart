import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../models/person_model.dart';
import '../../providers/debt_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/empty_state_widget.dart';
import '../person/add_edit_person_dialog.dart';
import '../person_detail/person_detail_screen.dart';
import '../reports/reports_screen.dart';
import '../settings/settings_screen.dart';
import 'widgets/balance_summary_card.dart';
import 'widgets/person_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _activeFilter = 'ALL'; // 'ALL', 'FOR_ME', 'ON_ME', 'SETTLED'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Person> _filterPersons(List<Person> persons) {
    if (_activeFilter == 'FOR_ME') {
      return persons.where((p) => p.isIqdForMe || p.isUsdForMe).toList();
    } else if (_activeFilter == 'ON_ME') {
      return persons.where((p) => p.isIqdOnMe || p.isUsdOnMe).toList();
    } else if (_activeFilter == 'SETTLED') {
      return persons.where((p) => p.isSettled).toList();
    }
    return persons;
  }

  @override
  Widget build(BuildContext context) {
    final debtProv = context.watch<DebtProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filteredPersons = _filterPersons(debtProv.persons);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.account_balance_rounded, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 10),
              const Text(
                AppStrings.appName,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.analytics_outlined),
              tooltip: AppStrings.reports,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ReportsScreen()),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: AppStrings.settings,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () => debtProv.refreshAll(),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            children: [
              // بطاقة الإجمالي الكلي للديون ثلاثية الأبعاد
              const BalanceSummaryCard()
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: -0.1, end: 0, curve: Curves.easeOutQuad),
              const SizedBox(height: 20),

              // شريط البحث المباشر
              TextField(
                controller: _searchController,
                onChanged: (val) => debtProv.setSearchQuery(val),
                decoration: InputDecoration(
                  hintText: AppStrings.searchHint,
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            debtProv.setSearchQuery('');
                          },
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 16),

              // أزرار الفلترة السريعة (الكل، لي، علي، خالص)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('ALL', 'الكل (${debtProv.persons.length})'),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      'FOR_ME',
                      'مطلوب منهم (لي)',
                      color: AppColors.debtForMe,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      'ON_ME',
                      'مطلوب مني (علي)',
                      color: AppColors.debtOnMe,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      'SETTLED',
                      'خالص الذمة',
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // رأس القائمة مع عدد الحسابات
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "قائمة الحسابات والأشخاص",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    "${filteredPersons.length} شخص",
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // قائمة الأشخاص أو الحالة الفارغة
              if (debtProv.isLoading)
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (filteredPersons.isEmpty)
                EmptyStateWidget(
                  icon: Icons.person_search_rounded,
                  title: _searchController.text.isNotEmpty
                      ? "لا يوجد نتائج مطابقة للبحث"
                      : "لا يوجد أشخاص مسجلين حتى الآن",
                  subtitle: _searchController.text.isNotEmpty
                      ? "تأكد من كتابة الاسم أو رقم الهاتف بشكل صحيح."
                      : "اضغط على زر الإضافة بالأسفل لتسجيل أول حساب أو دين.",
                  actionText: _searchController.text.isEmpty ? AppStrings.addPerson : null,
                  onAction: _searchController.text.isEmpty
                      ? () => AddEditPersonDialog.show(context)
                      : null,
                )
              else
                ...filteredPersons.asMap().entries.map((entry) {
                  final index = entry.key;
                  final person = entry.value;
                  return PersonCard(
                    person: person,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PersonDetailScreen(personId: person.id!),
                        ),
                      );
                    },
                  )
                      .animate(delay: (40 * index).ms)
                      .fadeIn(duration: 300.ms)
                      .slideY(begin: 0.08, end: 0, curve: Curves.easeOutQuad);
                }),
              const SizedBox(height: 80), // مساحة للزر العائم
            ],
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => AddEditPersonDialog.show(context),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 4,
          icon: const Icon(Icons.person_add_alt_1_rounded),
          label: const Text(
            AppStrings.addPerson,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String key, String label, {Color? color}) {
    final isSelected = _activeFilter == key;
    final effectiveColor = color ?? AppColors.primary;

    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : AppColors.textSecondary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 13,
        ),
      ),
      selected: isSelected,
      selectedColor: effectiveColor,
      backgroundColor: Colors.transparent,
      side: BorderSide(
        color: isSelected ? effectiveColor : AppColors.border,
        width: 1,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onSelected: (_) => setState(() => _activeFilter = key),
    );
  }
}
