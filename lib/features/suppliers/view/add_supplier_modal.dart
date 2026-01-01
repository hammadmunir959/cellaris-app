import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:animate_do/animate_do.dart';
import 'package:mbm_app/core/theme/app_theme.dart';
import 'package:mbm_app/core/widgets/primary_button.dart';
import 'package:mbm_app/shared/controller/shared_controller.dart';
import 'package:mbm_app/core/models/app_models.dart';
import 'package:uuid/uuid.dart';

class AddSupplierModal extends ConsumerStatefulWidget {
  final Supplier? supplier;
  const AddSupplierModal({super.key, this.supplier});

  @override
  ConsumerState<AddSupplierModal> createState() => _AddSupplierModalState();
}

class _AddSupplierModalState extends ConsumerState<AddSupplierModal> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final nameController = TextEditingController();
  final companyController = TextEditingController();
  final contactController = TextEditingController();
  final emailController = TextEditingController();
  final addressController = TextEditingController();
  final taxIdController = TextEditingController();
  final termsController = TextEditingController();
  final notesController = TextEditingController();
  
  // State
  bool isActive = true;
  bool isLoading = false;
  bool isEditing = false;

  @override
  void initState() {
    super.initState();
    if (widget.supplier != null) {
      isEditing = true;
      final s = widget.supplier!;
      nameController.text = s.name;
      companyController.text = s.company;
      contactController.text = s.contact;
      emailController.text = s.email ?? '';
      addressController.text = s.address ?? '';
      taxIdController.text = s.taxId ?? '';
      termsController.text = s.paymentTerms ?? '';
      notesController.text = s.notes ?? '';
      isActive = s.isActive;
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    companyController.dispose();
    contactController.dispose();
    emailController.dispose();
    addressController.dispose();
    taxIdController.dispose();
    termsController.dispose();
    notesController.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);
    // await Future.delayed(const Duration(seconds: 1)); // Removed artificial delay

    final newSupplier = Supplier(
      id: isEditing ? widget.supplier!.id : const Uuid().v4(),
      name: nameController.text,
      company: companyController.text,
      contact: contactController.text,
      email: emailController.text.isNotEmpty ? emailController.text : null,
      address: addressController.text.isNotEmpty ? addressController.text : null,
      taxId: taxIdController.text.isNotEmpty ? taxIdController.text : null,
      paymentTerms: termsController.text.isNotEmpty ? termsController.text : null,
      notes: notesController.text.isNotEmpty ? notesController.text : null,
      isActive: isActive,
      // Create new supplier preserves previous balance and credit details if not exposed in form
      balance: isEditing ? widget.supplier!.balance : 0, 
      debitLimit: isEditing ? widget.supplier!.debitLimit : 0,
      agingLimit: isEditing ? widget.supplier!.agingLimit : 0,
    );

    if (isEditing) {
      await ref.read(supplierProvider.notifier).updateSupplier(newSupplier);
    } else {
      await ref.read(supplierProvider.notifier).addSupplier(newSupplier);
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Supplier ${newSupplier.company} ${isEditing ? 'updated' : 'added'}.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: FadeInDown(
        duration: const Duration(milliseconds: 300),
        child: Container(
          width: 850,
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
          decoration: BoxDecoration(
            color: theme.brightness == Brightness.dark ? const Color(0xFF1A1A2E) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(isEditing ? 'Edit Supplier' : 'Register New Supplier', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        const Text('Manage corporate partners and logistics suppliers.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.x),
                      onPressed: () => Navigator.pop(context),
                      splashRadius: 20,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Form
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionHeader(title: 'Company Information', icon: LucideIcons.building),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(child: _FormField(label: 'Company Name', controller: companyController, hint: 'e.g. Apple Distribution Inc.', required: true)),
                            const SizedBox(width: 24),
                            Expanded(child: _FormField(label: 'Contact Person', controller: nameController, hint: 'e.g. Mr. Kashif', required: true)),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(child: _FormField(label: 'Contact Number', controller: contactController, hint: 'e.g. 03xx-xxxxxxx', required: true)),
                            const SizedBox(width: 24),
                            Expanded(child: _FormField(label: 'Business Email', controller: emailController, hint: 'e.g. sales@company.com')),
                          ],
                        ),

                        const SizedBox(height: 48),

                        _SectionHeader(title: 'Legal & Address', icon: LucideIcons.fileText),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(flex: 1, child: _FormField(label: 'Tax Reference / NTN', controller: taxIdController, hint: 'e.g. 1234567-8')),
                            const SizedBox(width: 24),
                            Expanded(flex: 2, child: _FormField(label: 'Full Business Address', controller: addressController, hint: 'Full office/warehouse address', maxLines: 2)),
                          ],
                        ),

                        const SizedBox(height: 48),

                        _SectionHeader(title: 'Terms & Logistics', icon: LucideIcons.truck),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(child: _FormField(label: 'Payment Terms', controller: termsController, hint: 'e.g. Net 30, COD, 50% Advance')),
                            const SizedBox(width: 24),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Partner Status', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)),
                                  const SizedBox(height: 12),
                                  SwitchListTile(
                                    title: Text(isActive ? 'Active Supplier' : 'Inactive / Blocked', style: const TextStyle(fontSize: 14)),
                                    value: isActive,
                                    onChanged: (val) => setState(() => isActive = val),
                                    activeColor: Colors.green,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _FormField(label: 'Internal Notes', controller: notesController, hint: 'Private notes about reliability, quality, etc.', maxLines: 3),
                      ],
                    ),
                  ),
                ),
              ),

              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
                    const SizedBox(width: 24),
                    PrimaryButton(
                      label: isEditing ? 'Update Supplier' : 'Save Supplier',
                      onPressed: _handleSubmit,
                      isLoading: isLoading,
                      width: 200,
                      icon: LucideIcons.save,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.primaryColor),
        const SizedBox(width: 12),
        Text(title.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.2, color: Colors.grey)),
      ],
    );
  }
}

class _FormField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final bool required;
  final int maxLines;

  const _FormField({required this.label, required this.hint, required this.controller, this.required = false, this.maxLines = 1});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)),
            if (required) const Text(' *', style: TextStyle(color: Colors.red)),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 15),
          validator: (val) {
            if (required && (val == null || val.isEmpty)) return 'This field is required';
            return null;
          },
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.withOpacity(0.5), fontSize: 14),
            filled: true,
            fillColor: Colors.white.withOpacity(0.03),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1)),
          ),
        ),
      ],
    );
  }
}
