import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:animate_do/animate_do.dart';
import 'package:mbm_app/core/theme/app_theme.dart';
import 'package:mbm_app/core/widgets/primary_button.dart';
import 'package:mbm_app/shared/controller/shared_controller.dart';
import 'package:mbm_app/core/models/app_models.dart';
import 'package:uuid/uuid.dart';

class AddCustomerModal extends ConsumerStatefulWidget {
  final Customer? customer;
  const AddCustomerModal({super.key, this.customer});

  @override
  ConsumerState<AddCustomerModal> createState() => _AddCustomerModalState();
}

class _AddCustomerModalState extends ConsumerState<AddCustomerModal> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final nameController = TextEditingController();
  final contactController = TextEditingController();
  final emailController = TextEditingController();
  final addressController = TextEditingController();
  final cityController = TextEditingController();
  final taxIdController = TextEditingController();
  final notesController = TextEditingController();
  
  // State
  bool isWholesale = false;
  bool isLoading = false;
  bool isEditing = false;

  @override
  void initState() {
    super.initState();
    if (widget.customer != null) {
      isEditing = true;
      final c = widget.customer!;
      nameController.text = c.name;
      contactController.text = c.contact;
      emailController.text = c.email ?? '';
      addressController.text = c.address ?? '';
      cityController.text = c.city ?? '';
      taxIdController.text = c.taxId ?? '';
      notesController.text = c.notes ?? '';
      isWholesale = c.isWholesale;
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    contactController.dispose();
    emailController.dispose();
    addressController.dispose();
    cityController.dispose();
    taxIdController.dispose();
    notesController.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);
    // await Future.delayed(const Duration(seconds: 1));

    final newCustomer = Customer(
      id: isEditing ? widget.customer!.id : const Uuid().v4(),
      name: nameController.text,
      contact: contactController.text,
      email: emailController.text.isNotEmpty ? emailController.text : null,
      address: addressController.text.isNotEmpty ? addressController.text : null,
      city: cityController.text.isNotEmpty ? cityController.text : null,
      taxId: taxIdController.text.isNotEmpty ? taxIdController.text : null,
      isWholesale: isWholesale,
      notes: notesController.text.isNotEmpty ? notesController.text : null,
      // Create new customer preserves previous balance and credit details if not exposed in form
      balance: isEditing ? widget.customer!.balance : 0, 
      debitLimit: isEditing ? widget.customer!.debitLimit : 0,
    );

    if (isEditing) {
      await ref.read(customerProvider.notifier).updateCustomer(newCustomer);
    } else {
      await ref.read(customerProvider.notifier).addCustomer(newCustomer);
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Customer ${newCustomer.name} ${isEditing ? 'updated' : 'added'}.'),
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
          width: 800,
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
                        Text(isEditing ? 'Edit Customer' : 'Add New Customer', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        const Text('Create a profile for better relationship management.', style: TextStyle(color: Colors.grey, fontSize: 13)),
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
                        _SectionHeader(title: 'Basic Information', icon: LucideIcons.user),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(child: _FormField(label: 'Full Name', controller: nameController, hint: 'e.g. John Doe', required: true)),
                            const SizedBox(width: 24),
                            Expanded(child: _FormField(label: 'Contact Number', controller: contactController, hint: 'e.g. 03xx-xxxxxxx', required: true)),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _FormField(label: 'Email Address', controller: emailController, hint: 'e.g. john@example.com'),

                        const SizedBox(height: 48),

                        _SectionHeader(title: 'Address & Identification', icon: LucideIcons.mapPin),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(child: _FormField(label: 'City', controller: cityController, hint: 'e.g. Lahore')),
                            const SizedBox(width: 24),
                            Expanded(child: _FormField(label: 'Tax ID / CNIC', controller: taxIdController, hint: 'e.g. 35201-xxxxxxx-x')),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _FormField(label: 'Street Address', controller: addressController, hint: 'e.g. House #, Street Name, Area', maxLines: 2),

                        const SizedBox(height: 48),

                        _SectionHeader(title: 'Business Details & Notes', icon: LucideIcons.briefcase),
                        const SizedBox(height: 20),
                        SwitchListTile(
                          title: const Text('Wholesale Customer', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                          subtitle: const Text('Check this if the customer is a re-seller or wholesaler.', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          value: isWholesale,
                          onChanged: (val) => setState(() => isWholesale = val),
                          activeColor: AppTheme.primaryColor,
                          contentPadding: EdgeInsets.zero,
                        ),
                        const SizedBox(height: 24),
                        _FormField(label: 'Additional Notes', controller: notesController, hint: 'Any specific preferences or credit terms...', maxLines: 3),
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
                      label: isEditing ? 'Update Customer' : 'Create Customer',
                      onPressed: _handleSubmit,
                      isLoading: isLoading,
                      width: 200,
                      icon: LucideIcons.userPlus,
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
