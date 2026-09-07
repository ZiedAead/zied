import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/dialog_helper.dart';
import '../../models/person_model.dart';
import '../../providers/debt_provider.dart';

class AddEditPersonDialog extends StatefulWidget {
  final Person? personToEdit;

  const AddEditPersonDialog({super.key, this.personToEdit});

  static Future<void> show(BuildContext context, {Person? personToEdit}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddEditPersonDialog(personToEdit: personToEdit),
    );
  }

  @override
  State<AddEditPersonDialog> createState() => _AddEditPersonDialogState();
}

class _AddEditPersonDialogState extends State<AddEditPersonDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _notesController;
  bool _isLoading = false;

  bool get isEditing => widget.personToEdit != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.personToEdit?.name ?? '');
    _phoneController = TextEditingController(text: widget.personToEdit?.phone ?? '');
    _notesController = TextEditingController(text: widget.personToEdit?.notes ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final provider = context.read<DebtProvider>();
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final notes = _notesController.text.trim();

    try {
      if (isEditing) {
        final updated = widget.personToEdit!.copyWith(
          name: name,
          phone: phone.isEmpty ? null : phone,
          notes: notes.isEmpty ? null : notes,
        );
        await provider.updatePerson(updated);
        if (mounted) {
          Navigator.of(context).pop();
          DialogHelper.showSnackBar(context, message: "تم تعديل بيانات الشخص بنجاح", isSuccess: true);
        }
      } else {
        await provider.addPerson(name, phone: phone, notes: notes);
        if (mounted) {
          Navigator.of(context).pop();
          DialogHelper.showSnackBar(context, message: "تمت إضافة الشخص بنجاح", isSuccess: true);
        }
      }
    } catch (e) {
      if (mounted) {
        DialogHelper.showSnackBar(context, message: "حدث خطأ أثناء الحفظ", isError: true);
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

                // العنوان
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        isEditing ? Icons.edit_note_rounded : Icons.person_add_alt_1_rounded,
                        color: AppColors.primary,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      isEditing ? AppStrings.editPerson : AppStrings.addPerson,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),

                // حقل اسم الشخص
                TextFormField(
                  controller: _nameController,
                  autofocus: !isEditing,
                  decoration: const InputDecoration(
                    labelText: AppStrings.personName,
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return AppStrings.nameRequired;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // حقل رقم الهاتف
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: AppStrings.phoneNumber,
                    prefixIcon: Icon(Icons.phone_outlined),
                    hintText: "مثال: 07701234567",
                  ),
                ),
                const SizedBox(height: 16),

                // حقل الملاحظات
                TextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: AppStrings.notes,
                    prefixIcon: Icon(Icons.sticky_note_2_outlined),
                    hintText: "أي تفاصيل إضافية عن الشخص...",
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
                          backgroundColor: AppColors.primary,
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
                                isEditing ? AppStrings.save : AppStrings.save,
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
