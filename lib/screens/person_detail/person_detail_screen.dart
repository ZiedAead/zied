import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/dialog_helper.dart';
import '../../models/person_model.dart';
import '../../providers/debt_provider.dart';
import '../../widgets/custom_3d_card.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/gradient_button.dart';
import '../person/add_edit_person_dialog.dart';
import '../transaction/add_edit_transaction_dialog.dart';
import 'widgets/transaction_tile.dart';

class PersonDetailScreen extends StatefulWidget {
  final int personId;

  const PersonDetailScreen({super.key, required this.personId});

  @override
  State<PersonDetailScreen> createState() => _PersonDetailScreenState();
}

class _PersonDetailScreenState extends State<PersonDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DebtProvider>().loadTransactionsForPerson(widget.personId);
    });
  }

  Future<void> _deletePerson(BuildContext context, Person person) async {
    final confirmed = await DialogHelper.showConfirmationDialog(
      context,
      title: AppStrings.deletePerson,
      message: AppStrings.deletePersonConfirm,
      confirmText: AppStrings.delete,
      isDestructive: true,
      icon: Icons.person_remove_rounded,
    );

    if (confirmed && context.mounted) {
      await context.read<DebtProvider>().deletePerson(person.id!);
      if (context.mounted) {
        Navigator.of(context).pop();
        DialogHelper.showSnackBar(context, message: "تم حذف الشخص بنجاح", isSuccess: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final debtProv = context.watch<DebtProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // العثور على الشخص الحالي من القائمة المحدثة
    Person? person;
    try {
      person = debtProv.persons.firstWhere((p) => p.id == widget.personId);
    } catch (_) {
      person = null;
    }

    if (person == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("تفاصيل الشخص")),
        body: const Center(child: Text("تم حذف هذا الحساب")),
      );
    }

    final transactions = debtProv.currentPersonTransactions;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(person.name),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: AppStrings.editPerson,
              onPressed: () => AddEditPersonDialog.show(context, personToEdit: person),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.debtOnMe),
              tooltip: AppStrings.deletePerson,
              onPressed: () => _deletePerson(context, person!),
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            await debtProv.loadTransactionsForPerson(widget.personId);
            await debtProv.loadPersons();
          },
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // بطاقة الرصيد الصافي للشخص
              _buildPersonHeaderCard(person, isDark),
              const SizedBox(height: 16),

              // معلومات الاتصال والملاحظات إن وجدت
              if (person.phone != null || person.notes != null)
                _buildInfoCard(person, isDark),

              const SizedBox(height: 22),

              // شريط عنوان سجل الحركات
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.receipt_long_rounded, color: AppColors.primary, size: 22),
                      const SizedBox(width: 8),
                      const Text(
                        "سجل الحركات المالية",
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          "${transactions.length}",
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: () => AddEditTransactionDialog.show(
                      context,
                      personId: person!.id!,
                      personName: person.name,
                    ),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text("حركة جديدة"),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // قائمة الحركات
              if (transactions.isEmpty)
                EmptyStateWidget(
                  icon: Icons.receipt_outlined,
                  title: "لا توجد حركات مالية مسجلة",
                  subtitle: "اضغط على زر إضافة حركة لتسجيل دين جديد له أو عليه.",
                  actionText: AppStrings.addTransaction,
                  onAction: () => AddEditTransactionDialog.show(
                    context,
                    personId: person!.id!,
                    personName: person.name,
                  ),
                )
              else
                ...transactions.map(
                  (t) => TransactionTile(
                    transaction: t,
                    personName: person!.name,
                  ),
                ),
            ],
          ),
        ),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.surface,
            boxShadow: AppColors.softShadow3D(),
          ),
          child: Row(
            children: [
              Expanded(
                child: GradientButton(
                  text: "سجل دين لي (مستحق)",
                  icon: Icons.call_received_rounded,
                  solidColor: AppColors.debtForMeDark,
                  onPressed: () => AddEditTransactionDialog.show(
                    context,
                    personId: person!.id!,
                    personName: person.name,
                    initialType: 'for_me',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GradientButton(
                  text: "سجل دين علي (مطلوب)",
                  icon: Icons.call_made_rounded,
                  solidColor: AppColors.debtOnMeDark,
                  onPressed: () => AddEditTransactionDialog.show(
                    context,
                    personId: person!.id!,
                    personName: person.name,
                    initialType: 'on_me',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPersonHeaderCard(Person person, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.heroCardGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppColors.softShadow3D(),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Text(
            "الرصيد الصافي الحالي",
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 14),

          // عرض رصيد العملتين جنباً إلى جنب
          Row(
            children: [
              // رصيد الدينار
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        "الدينار العراقي (IQD)",
                        style: TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        CurrencyFormatter.formatWithSymbol(person.netBalanceIqd, 'IQD'),
                        style: TextStyle(
                          color: person.netBalanceIqd > 0
                              ? AppColors.debtForMeLight
                              : person.netBalanceIqd < 0
                                  ? AppColors.debtOnMeLight
                                  : Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        person.netBalanceIqd > 0
                            ? "مستحق لي"
                            : person.netBalanceIqd < 0
                                ? "مطلوب مني"
                                : "خالص الذمة",
                        style: TextStyle(
                          color: person.netBalanceIqd > 0
                              ? AppColors.debtForMe
                              : person.netBalanceIqd < 0
                                  ? AppColors.debtOnMe
                                  : Colors.white54,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // رصيد الدولار
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        "الدولار الأمريكي (USD)",
                        style: TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        CurrencyFormatter.formatWithSymbol(person.netBalanceUsd, 'USD'),
                        style: TextStyle(
                          color: person.netBalanceUsd > 0
                              ? AppColors.debtForMeLight
                              : person.netBalanceUsd < 0
                                  ? AppColors.debtOnMeLight
                                  : Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        person.netBalanceUsd > 0
                            ? "مستحق لي"
                            : person.netBalanceUsd < 0
                                ? "مطلوب مني"
                                : "خالص الذمة",
                        style: TextStyle(
                          color: person.netBalanceUsd > 0
                              ? AppColors.debtForMe
                              : person.netBalanceUsd < 0
                                  ? AppColors.debtOnMe
                                  : Colors.white54,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(Person person, bool isDark) {
    return Custom3dCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderRadius: 18,
      child: Column(
        children: [
          if (person.phone != null && person.phone!.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.phone_rounded, color: AppColors.primary, size: 20),
                const SizedBox(width: 10),
                Text(
                  person.phone!,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ],
            ),
          ],
          if (person.phone != null && person.notes != null)
            const Divider(height: 16, color: AppColors.borderSubtle),
          if (person.notes != null && person.notes!.isNotEmpty) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.notes_rounded, color: AppColors.textMuted, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    person.notes!,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppColors.textMuted : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
