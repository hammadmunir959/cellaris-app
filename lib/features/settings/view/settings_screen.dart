import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:animate_do/animate_do.dart';
import 'package:mbm_app/core/theme/app_theme.dart';
import 'package:mbm_app/core/widgets/glass_card.dart';
import 'package:mbm_app/core/widgets/primary_button.dart';
import 'package:mbm_app/features/settings/controller/settings_controller.dart';
import 'package:mbm_app/core/models/app_models.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Controllers for Business info
  final companyController = TextEditingController();
  final taxIdController = TextEditingController();
  final addressController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  
  // Controllers for Receipt
  final headerController = TextEditingController();
  final footerController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    // Initialize with current settings
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final s = ref.read(settingsProvider);
      companyController.text = s.companyName;
      taxIdController.text = s.taxId;
      addressController.text = s.address;
      phoneController.text = s.phone;
      emailController.text = s.email;
      headerController.text = s.receiptHeader;
      footerController.text = s.receiptFooter;
    });
  }

  void _saveAll() {
    final current = ref.read(settingsProvider);
    final updated = current.copyWith(
      companyName: companyController.text,
      taxId: taxIdController.text,
      address: addressController.text,
      phone: phoneController.text,
      email: emailController.text,
      receiptHeader: headerController.text,
      receiptFooter: footerController.text,
    );
    ref.read(settingsProvider.notifier).updateSettings(updated);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings saved successfully!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('System Settings', style: theme.textTheme.displayMedium?.copyWith(fontSize: 28)),
                const Text('Configure your business preferences and system defaults.', style: TextStyle(color: Colors.grey)),
              ],
            ),
            PrimaryButton(
              label: 'Save Changes',
              onPressed: _saveAll,
              icon: LucideIcons.save,
            ),
          ],
        ),
        const SizedBox(height: 32),
        
        TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(LucideIcons.building, size: 18), text: 'Business'),
            Tab(icon: Icon(LucideIcons.percent, size: 18), text: 'Tax & Currency'),
            Tab(icon: Icon(LucideIcons.receipt, size: 18), text: 'Receipt'),
            Tab(icon: Icon(LucideIcons.creditCard, size: 18), text: 'Payment'),
          ],
        ),
        const SizedBox(height: 24),
        
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _BusinessTab(
                company: companyController,
                taxId: taxIdController,
                address: addressController,
                phone: phoneController,
                email: emailController,
              ),
              _TaxTab(settings: settings),
              _ReceiptTab(header: headerController, footer: footerController),
              _PaymentTab(settings: settings),
            ],
          ),
        ),
      ],
    );
  }
}

class _BusinessTab extends StatelessWidget {
  final TextEditingController company;
  final TextEditingController taxId;
  final TextEditingController address;
  final TextEditingController phone;
  final TextEditingController email;

  const _BusinessTab({
    required this.company,
    required this.taxId,
    required this.address,
    required this.phone,
    required this.email,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: FadeInUp(
        child: GlassCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Business Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: _SettingField(label: 'Company Name', controller: company)),
                  const SizedBox(width: 24),
                  Expanded(child: _SettingField(label: 'Tax / Registration ID', controller: taxId)),
                ],
              ),
              const SizedBox(height: 16),
              _SettingField(label: 'Business Address', controller: address, maxLines: 3),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _SettingField(label: 'Contact Phone', controller: phone)),
                  const SizedBox(width: 24),
                  Expanded(child: _SettingField(label: 'Support Email', controller: email)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaxTab extends ConsumerWidget {
  final BusinessSettings settings;
  const _TaxTab({required this.settings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      child: Column(
        children: [
          FadeInUp(
            child: GlassCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Currency Settings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: settings.currency,
                    decoration: const InputDecoration(labelText: 'Default Currency'),
                    items: ['PKR', 'USD', 'EUR', 'GBP', 'AED'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        ref.read(settingsProvider.notifier).updateSettings(settings.copyWith(currency: val));
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          FadeInUp(
            delay: const Duration(milliseconds: 100),
            child: GlassCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tax Rates', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      TextButton.icon(
                        onPressed: () => _showAddTaxDialog(context, ref), 
                        icon: const Icon(LucideIcons.plus, size: 16), 
                        label: const Text('Add Tax')
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DataTable(
                    columns: const [
                      DataColumn(label: Text('Name')),
                      DataColumn(label: Text('Rate (%)')),
                      DataColumn(label: Text('Default')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: settings.taxRates.map((t) => DataRow(cells: [
                      DataCell(Text(t.name)),
                      DataCell(Text('${t.rate}%')),
                      DataCell(Icon(t.isDefault ? LucideIcons.checkCircle : null, size: 16, color: Colors.green)),
                      DataCell(Row(
                        children: [
                          IconButton(
                            icon: const Icon(LucideIcons.edit, size: 16), 
                            onPressed: () => _showEditTaxDialog(context, ref, t)
                          ),
                          IconButton(
                            icon: const Icon(LucideIcons.trash2, size: 16, color: Colors.red), 
                            onPressed: () => ref.read(settingsProvider.notifier).deleteTaxRate(t.id)
                          ),
                        ],
                      )),
                    ])).toList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddTaxDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final rateController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Tax Rate'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Tax Name')),
            TextField(controller: rateController, decoration: const InputDecoration(labelText: 'Rate (%)'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              ref.read(settingsProvider.notifier).addTaxRate(TaxRate(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                name: nameController.text,
                rate: double.tryParse(rateController.text) ?? 0,
              ));
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditTaxDialog(BuildContext context, WidgetRef ref, TaxRate tax) {
    final nameController = TextEditingController(text: tax.name);
    final rateController = TextEditingController(text: tax.rate.toString());
    bool isDefault = tax.isDefault;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Tax Rate'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Tax Name')),
              TextField(controller: rateController, decoration: const InputDecoration(labelText: 'Rate (%)'), keyboardType: TextInputType.number),
              SwitchListTile(
                title: const Text('Set as Default'),
                value: isDefault, 
                onChanged: (val) => setState(() => isDefault = val),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            PrimaryButton(
              label: 'Update', 
              onPressed: () {
                ref.read(settingsProvider.notifier).updateTaxRate(tax.copyWith(
                  name: nameController.text,
                  rate: double.tryParse(rateController.text) ?? 0,
                  isDefault: isDefault,
                ));
                Navigator.pop(context);
              },
              width: 100,
            ),
          ],
        ),
      ),
    );
  }
}

class _ReceiptTab extends StatelessWidget {
  final TextEditingController header;
  final TextEditingController footer;

  const _ReceiptTab({required this.header, required this.footer});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: FadeInUp(
        child: GlassCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Receipt Customization', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              _SettingField(label: 'Receipt Header Message', controller: header, maxLines: 2),
              const SizedBox(height: 16),
              _SettingField(label: 'Receipt Footer / Terms', controller: footer, maxLines: 3),
              const SizedBox(height: 32),
              const Text('Live Preview', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 12),
              Container(
                width: 300,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                ),
                child: Column(
                  children: [
                    const Text('BUSINESS NAME', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                    const Text('Address Line 1', style: TextStyle(fontSize: 10, color: Colors.black54)),
                    const Divider(color: Colors.black12),
                    ValueListenableBuilder(
                      valueListenable: header,
                      builder: (context, value, _) => Text(value.text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.black)),
                    ),
                    const SizedBox(height: 16),
                    const Text('[ ITEMS LIST ]', style: TextStyle(fontSize: 10, color: Colors.black26)),
                    const Divider(color: Colors.black12),
                    ValueListenableBuilder(
                      valueListenable: footer,
                      builder: (context, value, _) => Text(value.text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: Colors.black54)),
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

class _PaymentTab extends ConsumerWidget {
  final BusinessSettings settings;
  const _PaymentTab({required this.settings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      child: FadeInUp(
        child: GlassCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Payment Methods', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  PrimaryButton(
                    label: 'Add Method', 
                    onPressed: () => _showAddPaymentMethodDialog(context, ref), 
                    width: 150
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: settings.paymentMethods.length,
                itemBuilder: (context, index) {
                  final m = settings.paymentMethods[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(m.type == 'cash' ? LucideIcons.banknote : LucideIcons.creditCard, color: AppTheme.primaryColor),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(m.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text(m.type.toUpperCase(), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                        ),
                        Switch(
                          value: m.isEnabled,
                          onChanged: (val) {
                            ref.read(settingsProvider.notifier).updatePaymentMethod(TransactionPaymentMethod(
                              id: m.id,
                              name: m.name,
                              type: m.type,
                              isEnabled: val,
                            ));
                          },
                        ),
                        IconButton(
                          icon: const Icon(LucideIcons.edit, size: 18),
                          onPressed: () => _showEditPaymentMethodDialog(context, ref, m),
                        ),
                        IconButton(
                          icon: const Icon(LucideIcons.trash2, size: 18, color: Colors.red),
                          onPressed: () => ref.read(settingsProvider.notifier).deletePaymentMethod(m.id),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddPaymentMethodDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    String selectedType = 'cash';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Payment Method'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Method Name')),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedType,
                decoration: const InputDecoration(labelText: 'Type'),
                items: ['cash', 'card', 'wallet', 'other'].map((t) => DropdownMenuItem(value: t, child: Text(t.toUpperCase()))).toList(),
                onChanged: (val) => setState(() => selectedType = val!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                ref.read(settingsProvider.notifier).addPaymentMethod(TransactionPaymentMethod(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameController.text,
                  type: selectedType,
                ));
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditPaymentMethodDialog(BuildContext context, WidgetRef ref, TransactionPaymentMethod method) {
    final nameController = TextEditingController(text: method.name);
    String selectedType = method.type;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Payment Method'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Method Name')),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedType,
                decoration: const InputDecoration(labelText: 'Type'),
                items: ['cash', 'card', 'wallet', 'other'].map((t) => DropdownMenuItem(value: t, child: Text(t.toUpperCase()))).toList(),
                onChanged: (val) => setState(() => selectedType = val!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            PrimaryButton(
              label: 'Update', 
              onPressed: () {
                ref.read(settingsProvider.notifier).updatePaymentMethod(TransactionPaymentMethod(
                  id: method.id,
                  name: nameController.text,
                  type: selectedType,
                  isEnabled: method.isEnabled,
                ));
                Navigator.pop(context);
              },
              width: 100,
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final int maxLines;

  const _SettingField({required this.label, required this.controller, this.maxLines = 1});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }
}
