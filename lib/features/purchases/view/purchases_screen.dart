import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:animate_do/animate_do.dart';
import 'package:mbm_app/core/theme/app_theme.dart';
import 'package:mbm_app/core/widgets/glass_card.dart';
import 'package:mbm_app/core/widgets/primary_button.dart';
import 'package:mbm_app/features/inventory/controller/inventory_controller.dart';
import 'package:mbm_app/shared/controller/shared_controller.dart';
import 'package:mbm_app/features/purchases/controller/purchases_controller.dart';
import 'package:mbm_app/core/models/app_models.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'bulk_imei_import_dialog.dart';
import '../../inventory/view/purchase_order_dialog.dart';



class PurchasesScreen extends ConsumerStatefulWidget {
  const PurchasesScreen({super.key});

  @override
  ConsumerState<PurchasesScreen> createState() => _PurchasesScreenState();
}

class _PurchasesScreenState extends ConsumerState<PurchasesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Purchases & Procurement',
                  style: theme.textTheme.displayMedium?.copyWith(fontSize: 28),
                ),
                const SizedBox(height: 4),
                const Text('Manage device buy-backs and supplier inventory orders.', style: TextStyle(color: Colors.grey)),
              ],
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorColor: AppTheme.primaryColor,
                labelColor: AppTheme.primaryColor,
                unselectedLabelColor: Colors.grey,
                indicatorSize: TabBarIndicatorSize.label,
                tabs: const [
                  Tab(text: 'Used Phone Buy-back'),
                  Tab(text: 'Inventory Purchase Orders'),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              const _UsedPhoneBuybackTab(),
              const _InventoryPOTab(),
            ],
          ),
        ),
      ],
    );
  }
}

// --- TAB 1: USED PHONE BUYBACK ---

class _UsedPhoneBuybackTab extends ConsumerStatefulWidget {
  const _UsedPhoneBuybackTab();

  @override
  ConsumerState<_UsedPhoneBuybackTab> createState() => _UsedPhoneBuybackTabState();
}

class _UsedPhoneBuybackTabState extends ConsumerState<_UsedPhoneBuybackTab> {
  String searchTerm = '';
  
  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productProvider).where((p) => p.category == 'Used Phones' || (p.sku.startsWith('BUY-'))).toList();
    
    final stats = {
      'total': products.length,
      'today': products.where((p) => p.isActive).length, // Mock "today" logic
      'spent': products.fold(0.0, (sum, p) => sum + p.purchasePrice),
    };

    return Column(
      children: [
        Row(
          children: [
            _StatCard(title: 'Total Purchases', value: stats['total'].toString(), icon: LucideIcons.smartphone, color: Colors.blue),
            const SizedBox(width: 16),
            _StatCard(title: 'Purchased Today', value: stats['today'].toString(), icon: LucideIcons.plus, color: Colors.green),
            const SizedBox(width: 16),
            _StatCard(title: 'Total Spent', value: 'Rs. ${(stats['spent']! / 1000).toStringAsFixed(1)}k', icon: LucideIcons.rotateCcw, color: AppTheme.primaryColor),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(
              width: 300,
              child: TextField(
                onChanged: (v) => setState(() => searchTerm = v),
                decoration: InputDecoration(
                  hintText: 'Search seller, model, IMEI...',
                  prefixIcon: const Icon(LucideIcons.search, size: 18),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
            ),
            PrimaryButton(
              label: 'Record New Buy-back',
              icon: LucideIcons.plus,
              onPressed: () => _showBuybackModal(context),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: GlassCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _buildTableHeader(['Date', 'Seller', 'Device', 'IMEI', 'Purchase Price', 'Actions']),
                Expanded(
                  child: products.isEmpty 
                    ? const Center(child: Text('No buy-back records found.'))
                    : ListView.builder(
                        itemCount: products.length,
                        itemBuilder: (context, index) {
                          final p = products[index];
                          return _buildTableRow([
                            Text(DateFormat('MMM dd, yyyy').format(DateTime.now()), style: const TextStyle(fontSize: 12)), // Mock date
                            const Text('Unknown Seller', style: TextStyle(fontWeight: FontWeight.bold)), // Mock seller
                            Text(p.name),
                            Text(p.imei ?? 'N/A', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            Text('Rs. ${p.purchasePrice}'),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  icon: const Icon(LucideIcons.eye, size: 18), 
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: Text(p.name),
                                        content: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('IMEI: ${p.imei ?? "N/A"}'),
                                            Text('Variant: ${p.variant}'),
                                            Text('Condition: ${p.condition.name.toUpperCase()}'),
                                            Text('Purchase Price: Rs. ${p.purchasePrice}'),
                                            Text('Selling Price: Rs. ${p.sellingPrice}'),
                                            const SizedBox(height: 10),
                                            const Text('Seller Info:', style: TextStyle(fontWeight: FontWeight.bold)),
                                            const Text('Name: Unknown (Mock)'),
                                            const Text('Contact: Unknown (Mock)'),
                                          ],
                                        ),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(LucideIcons.trash2, size: 18, color: Colors.red), 
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Confirm Delete'),
                                        content: Text('Are you sure you want to delete ${p.name}?'),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                                          TextButton(
                                            onPressed: () {
                                              ref.read(productProvider.notifier).deleteProduct(p.id);
                                              Navigator.pop(context);
                                            },
                                            child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                          ),
                                        ],
                                      ),
                                    );
                                  }
                                ),
                              ],
                            ),
                          ]);
                        },
                      ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showBuybackModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _BuybackFormModal(),
    );
  }
}

class _BuybackFormModal extends ConsumerStatefulWidget {
  const _BuybackFormModal();

  @override
  ConsumerState<_BuybackFormModal> createState() => _BuybackFormModalState();
}

class _BuybackFormModalState extends ConsumerState<_BuybackFormModal> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final cnicController = TextEditingController();
  final brandController = TextEditingController();
  final modelController = TextEditingController();
  final imeiController = TextEditingController();
  final priceController = TextEditingController();
  final specsController = TextEditingController();
  ProductCondition selectedCondition = ProductCondition.used;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      child: GlassCard(
        width: 900,
        height: 700,
        padding: const EdgeInsets.all(32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Record New Phone Purchase', style: theme.textTheme.titleLarge?.copyWith(fontSize: 24)),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(LucideIcons.x)),
                ],
              ),
              const Divider(height: 48),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Column: Seller Info
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(LucideIcons.user, size: 18, color: AppTheme.primaryColor),
                                SizedBox(width: 8),
                                Text('Seller Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              ],
                            ),
                            const SizedBox(height: 24),
                            _ModalField(label: 'Full Name *', controller: nameController, hint: 'e.g. Hammad Munir'),
                            _ModalField(label: 'Contact Number *', controller: phoneController, hint: 'e.g. 0300-1234567'),
                            _ModalField(label: 'CNIC / ID Number *', controller: cnicController, hint: 'e.g. 42101-XXXXXXX-X'),
                            const SizedBox(height: 16),
                            const Text('CNIC Verification (Mandatory)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey)),
                            const SizedBox(height: 8),
                            Container(
                              height: 100,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.02),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white.withOpacity(0.1), style: BorderStyle.solid),
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(LucideIcons.upload, color: Colors.grey, size: 24),
                                  SizedBox(height: 8),
                                  Text('Upload ID Photo', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const VerticalDivider(width: 64),
                    // Right Column: Phone Info
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(LucideIcons.smartphone, size: 18, color: AppTheme.primaryColor),
                                SizedBox(width: 8),
                                Text('Phone Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(child: _ModalField(label: 'Brand *', controller: brandController, hint: 'e.g. Apple')),
                                const SizedBox(width: 16),
                                Expanded(child: _ModalField(label: 'Model *', controller: modelController, hint: 'e.g. iPhone 15')),
                              ],
                            ),
                            _ModalField(label: 'IMEI Number (15 digits) *', controller: imeiController, hint: 'IMEI 1'),
                            Row(
                              children: [
                                Expanded(child: _ModalField(label: 'Specs', controller: specsController, hint: '256GB, Blue')),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Condition', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                      const SizedBox(height: 8),
                                      DropdownButtonFormField<ProductCondition>(
                                        value: selectedCondition,
                                        onChanged: (v) => setState(() => selectedCondition = v!),
                                        items: ProductCondition.values.map((v) => DropdownMenuItem(value: v, child: Text(v.name.toUpperCase()))).toList(),
                                        decoration: InputDecoration(
                                          filled: true,
                                          fillColor: Colors.white.withOpacity(0.05),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            _ModalField(label: 'Purchase Price (Rs.) *', controller: priceController, hint: '0.00'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 48),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                  const SizedBox(width: 16),
                  PrimaryButton(
                    label: 'Complete Purchase',
                    onPressed: () {
                      final p = Product(
                        id: const Uuid().v4(),
                        name: '${brandController.text} ${modelController.text}',
                        sku: 'BUY-${imeiController.text.substring(imeiController.text.length - 4)}',
                        imei: imeiController.text,
                        category: 'Used Phones',
                        brand: brandController.text,
                        variant: specsController.text,
                        purchasePrice: double.tryParse(priceController.text) ?? 0,
                        sellingPrice: (double.tryParse(priceController.text) ?? 0) + 5000,
                        stock: 1,
                        condition: selectedCondition,
                      );
                      ref.read(productProvider.notifier).addProduct(p);
                      Navigator.pop(context);
                    },
                    width: 200,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- TAB 2: INVENTORY PURCHASE ORDERS ---

class _InventoryPOTab extends ConsumerStatefulWidget {
  const _InventoryPOTab();

  @override
  ConsumerState<_InventoryPOTab> createState() => _InventoryPOTabState();
}

class _InventoryPOTabState extends ConsumerState<_InventoryPOTab> {
  String filterStatus = 'all';

  @override
  Widget build(BuildContext context) {
    final pos = ref.watch(purchasesProvider);
    final filteredPos = filterStatus == 'all' ? pos : pos.where((p) => p.status.name == filterStatus).toList();

    return Column(
      children: [
        Row(
          children: [
            _StatCard(title: 'Drafts', value: pos.where((p) => p.status == PurchaseOrderStatus.draft).length.toString(), icon: LucideIcons.fileEdit, color: Colors.grey),
            const SizedBox(width: 16),
            _StatCard(title: 'Sent', value: pos.where((p) => p.status == PurchaseOrderStatus.sent).length.toString(), icon: LucideIcons.truck, color: Colors.orange),
            const SizedBox(width: 16),
            _StatCard(title: 'Received', value: pos.where((p) => p.status == PurchaseOrderStatus.received).length.toString(), icon: LucideIcons.checkCircle, color: Colors.green),
            const SizedBox(width: 16),
            _StatCard(title: 'Total Value', value: 'Rs. ${(pos.fold(0.0, (sum, p) => sum + p.totalCost) / 1000).toStringAsFixed(0)}k', icon: LucideIcons.banknote, color: AppTheme.primaryColor),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            DropdownButton<String>(
              value: filterStatus,
              onChanged: (v) => setState(() => filterStatus = v!),
              items: ['all', 'draft', 'sent', 'received', 'cancelled']
                  .map((s) => DropdownMenuItem(value: s, child: Text(s.toUpperCase()))).toList(),
            ),
            PrimaryButton(
              label: 'New Purchase Order',
              icon: LucideIcons.plus,
              onPressed: () => _showNewPOModal(context),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: GlassCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _buildTableHeader(['PO ID', 'Supplier', 'Items', 'Total Cost', 'Status', 'Date', 'Actions']),
                Expanded(
                  child: filteredPos.isEmpty 
                    ? const Center(child: Text('No purchase orders found.'))
                    : ListView.builder(
                        itemCount: filteredPos.length,
                        itemBuilder: (context, index) {
                          final p = filteredPos[index];
                          return _buildTableRow([
                            Text(p.id, style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text(p.supplierName),
                            Text('${p.items.length} item(s)'),
                            Text('Rs. ${p.totalCost}'),
                            _StatusBadge(status: p.status),
                            Text(DateFormat('MMM dd, yyyy').format(p.createdAt)),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  icon: const Icon(LucideIcons.eye, size: 18), 
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => PurchaseOrderDialog(purchaseOrder: p),
                                    );
                                  }

                                ),
                                if (p.status == PurchaseOrderStatus.sent || p.status == PurchaseOrderStatus.confirmed)
                                  IconButton(
                                    icon: const Icon(LucideIcons.packageCheck, size: 18, color: Colors.green), 
                                    onPressed: () => ref.read(purchasesProvider.notifier).updatePOStatus(p.id, PurchaseOrderStatus.received)
                                  ),
                                IconButton(
                                  icon: const Icon(LucideIcons.trash2, size: 18, color: Colors.red),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Confirm Delete PO'),
                                        content: Text('Are you sure you want to delete PO ${p.id}?'),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                                          TextButton(
                                            onPressed: () {
                                              ref.read(purchasesProvider.notifier).deletePO(p.id);
                                              Navigator.pop(context);
                                            },
                                            child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ]);
                        },
                      ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showNewPOModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const PurchaseOrderDialog(),
    );
  }

}


// --- REMOVED DEPRECATED _POFormModal ---


// --- SHARED UI COMPONENTS ---

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GlassCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class _ModalField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController? controller;
  const _ModalField({required this.label, required this.hint, this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final PurchaseOrderStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color = Colors.grey;
    if (status == PurchaseOrderStatus.sent || status == PurchaseOrderStatus.confirmed) color = Colors.orange;
    if (status == PurchaseOrderStatus.received) color = Colors.green;
    if (status == PurchaseOrderStatus.cancelled) color = Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(status.name.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}

Widget _buildTableHeader(List<String> headers) {
  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05)))),
    child: Row(
      children: headers.map((h) => Expanded(child: Text(h, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)))).toList(),
    ),
  );
}

Widget _buildTableRow(List<Widget> children) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.02)))),
    child: Row(
      children: children.map((c) => Expanded(child: c)).toList(),
    ),
  );
}
