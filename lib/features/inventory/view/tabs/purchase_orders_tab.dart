import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:animate_do/animate_do.dart';
import 'package:mbm_app/core/theme/app_theme.dart';
import 'package:mbm_app/core/widgets/glass_card.dart';
import 'package:mbm_app/core/widgets/primary_button.dart';
import 'package:mbm_app/core/models/app_models.dart';
import 'package:mbm_app/features/inventory/controller/purchase_order_controller.dart';
import 'package:mbm_app/features/inventory/controller/inventory_controller.dart';
import 'package:mbm_app/features/inventory/controller/buyback_controller.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../purchase_order_dialog.dart';

class PurchaseOrdersTab extends ConsumerStatefulWidget {
  const PurchaseOrdersTab({super.key});

  @override
  ConsumerState<PurchaseOrdersTab> createState() => _PurchaseOrdersTabState();
}

class _PurchaseOrdersTabState extends ConsumerState<PurchaseOrdersTab> with SingleTickerProviderStateMixin {
  late TabController _subTabController;

  @override
  void initState() {
    super.initState();
    _subTabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _subTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Sub-tabs
        Container(
          alignment: Alignment.centerLeft,
          child: TabBar(
            controller: _subTabController,
            isScrollable: true,
            indicatorColor: AppTheme.primaryColor,
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(text: 'Inventory POs'),
              Tab(text: 'Used Phone Buyback'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: TabBarView(
            controller: _subTabController,
            children: const [
              _InventoryPOSubTab(),
              _UsedPhoneBuybackSubTab(),
            ],
          ),
        ),
      ],
    );
  }
}

// --- Sub-Tab 1: Inventory Purchase Orders ---
class _InventoryPOSubTab extends ConsumerWidget {
  const _InventoryPOSubTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pos = ref.watch(purchaseOrderProvider);
    final draftCount = pos.where((p) => p.status == PurchaseOrderStatus.draft).length;
    final sentCount = pos.where((p) => p.status == PurchaseOrderStatus.sent).length;
    final receivedCount = pos.where((p) => p.status == PurchaseOrderStatus.received).length;
    final totalValue = pos.fold(0.0, (sum, p) => sum + p.totalCost);

    return FadeInUp(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // KPIs
          Row(
            children: [
              Expanded(child: _StatCard(label: 'Total POs', value: pos.length.toString(), icon: LucideIcons.fileText, color: Colors.blue)),
              const SizedBox(width: 16),
              Expanded(child: _StatCard(label: 'Drafts', value: draftCount.toString(), icon: LucideIcons.fileEdit, color: Colors.orange)),
              const SizedBox(width: 16),
              Expanded(child: _StatCard(label: 'Sent', value: sentCount.toString(), icon: LucideIcons.send, color: Colors.purple)),
              const SizedBox(width: 16),
              Expanded(child: _StatCard(label: 'Received', value: receivedCount.toString(), icon: LucideIcons.checkCircle, color: Colors.green)),
              const SizedBox(width: 16),
              Expanded(child: _StatCard(label: 'Total Value', value: 'Rs. ${totalValue.toStringAsFixed(0)}', icon: LucideIcons.coins, color: AppTheme.primaryColor)),
            ],
          ),
          const SizedBox(height: 24),

          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              PrimaryButton(
                label: 'New Purchase Order',
                onPressed: () => showDialog(context: context, builder: (context) => const PurchaseOrderDialog()),
                icon: LucideIcons.plus,
                width: 200,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // List
          Expanded(
            child: pos.isEmpty
                ? const Center(child: Text('No purchase orders yet.', style: TextStyle(color: Colors.grey)))
                : GlassCard(
                    padding: EdgeInsets.zero,
                    child: ListView.separated(
                      itemCount: pos.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.white10),
                      itemBuilder: (context, index) {
                        final p = pos[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: _getStatusColor(p.status).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                            child: Icon(LucideIcons.fileText, color: _getStatusColor(p.status)),
                          ),
                          title: Text('PO #${p.id.length > 8 ? p.id.substring(0, 8) : p.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${p.supplierName} • ${p.items.length} items • ${DateFormat('MMM dd').format(p.createdAt)}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _StatusBadge(status: p.status),
                              const SizedBox(width: 16),
                              Text('Rs. ${p.totalCost.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(width: 8),
                              const Icon(LucideIcons.chevronRight, size: 16),
                            ],
                          ),
                          onTap: () => showDialog(context: context, builder: (context) => PurchaseOrderDialog(purchaseOrder: p)),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(PurchaseOrderStatus status) {
    switch (status) {
      case PurchaseOrderStatus.draft: return Colors.orange;
      case PurchaseOrderStatus.sent: return Colors.blue;
      case PurchaseOrderStatus.confirmed: return Colors.purple;
      case PurchaseOrderStatus.received: return Colors.green;
      case PurchaseOrderStatus.cancelled: return Colors.red;
    }
  }
}

// --- Sub-Tab 2: Used Phone Buyback ---
class _UsedPhoneBuybackSubTab extends ConsumerWidget {
  const _UsedPhoneBuybackSubTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final buybackRecords = ref.watch(buybackProvider);
    final totalSpent = buybackRecords.fold(0.0, (sum, r) => sum + r.purchasePrice);

    return FadeInUp(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // KPIs
          Row(
            children: [
              Expanded(child: _StatCard(label: 'Total Purchases', value: buybackRecords.length.toString(), icon: LucideIcons.smartphone, color: Colors.teal)),
              const SizedBox(width: 16),
              Expanded(child: _StatCard(label: 'Total Spent', value: 'Rs. ${totalSpent.toStringAsFixed(0)}', icon: LucideIcons.wallet, color: AppTheme.primaryColor)),
              const SizedBox(width: 16),
              Expanded(child: _StatCard(label: 'This Week', value: buybackRecords.where((r) => r.createdAt.isAfter(DateTime.now().subtract(const Duration(days: 7)))).length.toString(), icon: LucideIcons.calendar, color: Colors.blue)),
              const SizedBox(width: 16),
              const Expanded(child: SizedBox()),
            ],
          ),
          const SizedBox(height: 24),

          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              PrimaryButton(
                label: 'New Buyback',
                onPressed: () => _showBuybackModal(context),
                icon: LucideIcons.plus,
                width: 160,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // List
          Expanded(
            child: buybackRecords.isEmpty
                ? const Center(child: Text('No buyback records yet. Click "New Buyback" to add one.', style: TextStyle(color: Colors.grey)))
                : GlassCard(
                    padding: EdgeInsets.zero,
                    child: ListView.separated(
                      itemCount: buybackRecords.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.white10),
                      itemBuilder: (context, index) {
                        final record = buybackRecords[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: Colors.teal.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                            child: const Icon(LucideIcons.smartphone, color: Colors.teal),
                          ),
                          title: Text(record.fullPhoneName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('IMEI: ${record.displayImei} • Seller: ${record.sellerName}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Rs. ${record.purchasePrice.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                              const SizedBox(width: 16),
                              Text(record.condition.toUpperCase(), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                              const SizedBox(width: 8),
                              const Icon(LucideIcons.chevronRight, size: 16, color: Colors.grey),
                            ],
                          ),
                          onTap: () => _showBuybackDetails(context, record),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _showBuybackModal(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _BuybackFormModal(),
    );
  }

  void _showBuybackDetails(BuildContext context, BuybackRecord record) {
    showDialog(
      context: context,
      builder: (context) => _BuybackDetailsDialog(record: record),
    );
  }
}

// --- Buyback Details Dialog ---
class _BuybackDetailsDialog extends ConsumerWidget {
  final BuybackRecord record;
  const _BuybackDetailsDialog({required this.record});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: GlassCard(
        width: 900,
        height: 700,
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.teal.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(LucideIcons.smartphone, color: Colors.teal, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(record.fullPhoneName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        Text('Purchased on ${DateFormat('MMMM dd, yyyy').format(record.createdAt)}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _generateInvoice(context, record),
                      icon: const Icon(LucideIcons.fileText, size: 16),
                      label: const Text('Invoice'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () => _printDetails(context, record),
                      icon: const Icon(LucideIcons.printer, size: 16),
                      label: const Text('Print'),
                    ),
                    const SizedBox(width: 8),
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(LucideIcons.x)),
                  ],
                ),
              ],
            ),
            const Divider(height: 32),
            
            // Content
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left: Seller Info
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(LucideIcons.user, size: 16, color: AppTheme.primaryColor),
                              SizedBox(width: 8),
                              Text('Seller Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildInfoRow('Full Name', record.sellerName),
                          _buildInfoRow('Phone', record.sellerPhone),
                          _buildInfoRow('CNIC', record.sellerCnic),
                          const SizedBox(height: 20),
                          const Text('CNIC Images', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(child: _buildImagePreview('Front', record.cnicFrontPath)),
                              const SizedBox(width: 12),
                              Expanded(child: _buildImagePreview('Back', record.cnicBackPath)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const VerticalDivider(width: 48),
                  // Right: Phone Info
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(LucideIcons.smartphone, size: 16, color: AppTheme.primaryColor),
                              SizedBox(width: 8),
                              Text('Phone Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildInfoRow('Brand', record.brand),
                          _buildInfoRow('Model', record.model),
                          _buildInfoRow('IMEI 1', record.imei),
                          if (record.imei2 != null) _buildInfoRow('IMEI 2', record.imei2!),
                          _buildInfoRow('Variant', record.variant ?? 'N/A'),
                          _buildInfoRow('Condition', record.condition.toUpperCase()),
                          const Divider(height: 24),
                          _buildInfoRow('Purchase Price', 'Rs. ${record.purchasePrice.toStringAsFixed(0)}', valueColor: AppTheme.primaryColor),
                          if (record.notes != null && record.notes!.isNotEmpty)
                            _buildInfoRow('Notes', record.notes!),
                          const SizedBox(height: 20),
                          const Text('Phone Images', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(child: _buildImagePreview('Image 1', record.phoneImage1Path)),
                              const SizedBox(width: 12),
                              Expanded(child: _buildImagePreview('Image 2', record.phoneImage2Path)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ),
          Expanded(
            child: Text(value, style: TextStyle(fontWeight: FontWeight.w500, color: valueColor)),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview(String label, String? path) {
    final hasImage = path != null;
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: hasImage ? Colors.green.withOpacity(0.05) : Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: hasImage ? Colors.green.withOpacity(0.2) : Colors.white.withOpacity(0.1)),
      ),
      child: hasImage
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(File(path), fit: BoxFit.cover, errorBuilder: (_, __, ___) => _buildPlaceholder(label, true)),
            )
          : _buildPlaceholder(label, false),
    );
  }

  Widget _buildPlaceholder(String label, bool hasError) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(hasError ? LucideIcons.imageOff : LucideIcons.image, size: 20, color: Colors.grey.withOpacity(0.5)),
          const SizedBox(height: 4),
          Text(hasError ? 'Not found' : 'No $label', style: TextStyle(fontSize: 9, color: Colors.grey.withOpacity(0.5))),
        ],
      ),
    );
  }

  void _generateInvoice(BuildContext context, BuybackRecord record) async {
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('PHONE PURCHASE INVOICE', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 4),
                      pw.Text('Invoice #: BUY-${record.id.substring(0, 8).toUpperCase()}', style: const pw.TextStyle(color: PdfColors.grey700)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('MBM Store', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                      pw.Text('Date: ${DateFormat('dd/MM/yyyy').format(record.createdAt)}'),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 24),
              pw.Divider(),
              pw.SizedBox(height: 16),
              
              // Seller Info
              pw.Text('SELLER INFORMATION', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
              pw.SizedBox(height: 8),
              pw.Text('Name: ${record.sellerName}'),
              pw.Text('Phone: ${record.sellerPhone}'),
              pw.Text('CNIC: ${record.sellerCnic}'),
              pw.SizedBox(height: 20),
              
              // Phone Info
              pw.Text('PHONE DETAILS', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
              pw.SizedBox(height: 8),
              pw.Text('Device: ${record.fullPhoneName}'),
              pw.Text('IMEI: ${record.displayImei}'),
              pw.Text('Variant: ${record.variant ?? 'N/A'}'),
              pw.Text('Condition: ${record.condition.toUpperCase()}'),
              pw.SizedBox(height: 24),
              
              // Amount
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('PURCHASE AMOUNT', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                    pw.Text('Rs. ${record.purchasePrice.toStringAsFixed(0)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18)),
                  ],
                ),
              ),
              pw.SizedBox(height: 40),
              
              // Signatures
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    children: [
                      pw.Container(width: 150, height: 1, color: PdfColors.black),
                      pw.SizedBox(height: 4),
                      pw.Text('Seller Signature'),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Container(width: 150, height: 1, color: PdfColors.black),
                      pw.SizedBox(height: 4),
                      pw.Text('Store Representative'),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
    
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  void _printDetails(BuildContext context, BuybackRecord record) {
    _generateInvoice(context, record);
  }
}

// --- Buyback Form Modal ---
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
  final priceController = TextEditingController();
  final specsController = TextEditingController();
  ProductCondition selectedCondition = ProductCondition.used;

  // Multiple IMEIs
  List<TextEditingController> imeiControllers = [TextEditingController()];

  // CNIC Images
  String? cnicFrontPath;
  String? cnicBackPath;

  // Phone Images (optional)
  String? phoneImage1Path;
  String? phoneImage2Path;

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    cnicController.dispose();
    brandController.dispose();
    modelController.dispose();
    priceController.dispose();
    specsController.dispose();
    for (final c in imeiControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage(bool isFront) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        if (isFront) {
          cnicFrontPath = result.files.single.path;
        } else {
          cnicBackPath = result.files.single.path;
        }
      });
    }
  }

  Future<void> _pickPhoneImage(bool isFirst) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        if (isFirst) {
          phoneImage1Path = result.files.single.path;
        } else {
          phoneImage2Path = result.files.single.path;
        }
      });
    }
  }

  void _addImeiField() {
    setState(() {
      imeiControllers.add(TextEditingController());
    });
  }

  void _removeImeiField(int index) {
    if (imeiControllers.length > 1) {
      setState(() {
        imeiControllers[index].dispose();
        imeiControllers.removeAt(index);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      child: GlassCard(
        width: 1000,
        height: 750,
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
              const Divider(height: 32),
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
                            const SizedBox(height: 20),
                            _ModalField(label: 'Full Name *', controller: nameController, hint: 'e.g. Hammad Munir'),
                            _ModalField(label: 'Contact Number *', controller: phoneController, hint: 'e.g. 0300-1234567'),
                            _ModalField(label: 'CNIC / ID Number *', controller: cnicController, hint: 'e.g. 42101-XXXXXXX-X'),
                            const SizedBox(height: 12),
                            const Text('CNIC Verification (Mandatory)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(child: _buildImageUpload('Front Side', cnicFrontPath, () => _pickImage(true))),
                                const SizedBox(width: 12),
                                Expanded(child: _buildImageUpload('Back Side', cnicBackPath, () => _pickImage(false))),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const VerticalDivider(width: 48),
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
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(child: _ModalField(label: 'Brand *', controller: brandController, hint: 'e.g. Apple')),
                                const SizedBox(width: 16),
                                Expanded(child: _ModalField(label: 'Model *', controller: modelController, hint: 'e.g. iPhone 15')),
                              ],
                            ),
                            // Multiple IMEIs
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('IMEI Numbers *', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                TextButton.icon(
                                  onPressed: _addImeiField,
                                  icon: const Icon(LucideIcons.plus, size: 14),
                                  label: const Text('Add IMEI', style: TextStyle(fontSize: 12)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ...imeiControllers.asMap().entries.map((entry) {
                              final index = entry.key;
                              final controller = entry.value;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: controller,
                                        decoration: InputDecoration(
                                          hintText: 'IMEI ${index + 1} (15 digits)',
                                          filled: true,
                                          fillColor: Colors.white.withOpacity(0.05),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                        ),
                                      ),
                                    ),
                                    if (imeiControllers.length > 1)
                                      IconButton(
                                        icon: const Icon(LucideIcons.trash2, size: 18, color: Colors.red),
                                        onPressed: () => _removeImeiField(index),
                                      ),
                                  ],
                                ),
                              );
                            }),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(child: _ModalField(label: 'Specs / Variant', controller: specsController, hint: '256GB, Blue')),
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
                            const SizedBox(height: 8),
                            const Text('Phone Images (Optional)', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(child: _buildImageUpload('Image 1', phoneImage1Path, () => _pickPhoneImage(true))),
                                const SizedBox(width: 12),
                                Expanded(child: _buildImageUpload('Image 2', phoneImage2Path, () => _pickPhoneImage(false))),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Image status
                  Row(
                    children: [
                      Icon(cnicFrontPath != null ? LucideIcons.checkCircle : LucideIcons.circle, size: 16, color: cnicFrontPath != null ? Colors.green : Colors.grey),
                      const SizedBox(width: 4),
                      Text('CNIC Front', style: TextStyle(fontSize: 10, color: cnicFrontPath != null ? Colors.green : Colors.grey)),
                      const SizedBox(width: 8),
                      Icon(cnicBackPath != null ? LucideIcons.checkCircle : LucideIcons.circle, size: 16, color: cnicBackPath != null ? Colors.green : Colors.grey),
                      const SizedBox(width: 4),
                      Text('CNIC Back', style: TextStyle(fontSize: 10, color: cnicBackPath != null ? Colors.green : Colors.grey)),
                      if (phoneImage1Path != null || phoneImage2Path != null) ...[
                        const SizedBox(width: 12),
                        Icon(LucideIcons.camera, size: 14, color: Colors.blue.withOpacity(0.7)),
                        const SizedBox(width: 4),
                        Text('${[phoneImage1Path, phoneImage2Path].where((p) => p != null).length} photo(s)', style: TextStyle(fontSize: 10, color: Colors.blue.withOpacity(0.7))),
                      ],
                    ],
                  ),
                  Row(
                    children: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                      const SizedBox(width: 16),
                      PrimaryButton(
                        label: 'Complete Purchase',
                        onPressed: _handleSubmit,
                        width: 200,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageUpload(String label, String? path, VoidCallback onTap) {
    final hasImage = path != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: hasImage ? Colors.green.withOpacity(0.1) : Colors.white.withOpacity(0.02),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: hasImage ? Colors.green.withOpacity(0.3) : Colors.white.withOpacity(0.1)),
        ),
        child: hasImage
            ? Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.checkCircle, color: Colors.green, size: 24),
                        const SizedBox(height: 4),
                        Text(label, style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold)),
                        Text(path!.split('/').last, style: const TextStyle(fontSize: 9, color: Colors.grey), overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Icon(LucideIcons.edit2, size: 14, color: Colors.grey.withOpacity(0.5)),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(LucideIcons.upload, color: Colors.grey, size: 20),
                  const SizedBox(height: 4),
                  Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  const Text('Click to upload', style: TextStyle(fontSize: 9, color: Colors.grey)),
                ],
              ),
      ),
    );
  }

  void _handleSubmit() {
    // Validation
    final validImeis = imeiControllers.where((c) => c.text.trim().isNotEmpty).toList();
    if (brandController.text.isEmpty || modelController.text.isEmpty || validImeis.isEmpty || priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill Brand, Model, at least one IMEI, and Price'), backgroundColor: Colors.red));
      return;
    }
    if (cnicFrontPath == null || cnicBackPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please upload both CNIC front and back images'), backgroundColor: Colors.orange));
      return;
    }
    if (nameController.text.isEmpty || phoneController.text.isEmpty || cnicController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill Seller Name, Phone, and CNIC'), backgroundColor: Colors.red));
      return;
    }

    final purchasePrice = double.tryParse(priceController.text) ?? 0;
    int addedCount = 0;

    // Create buyback record for each IMEI
    for (int i = 0; i < validImeis.length; i++) {
      final imei = validImeis[i].text.trim();
      final productId = const Uuid().v4();
      
      // Create Product for inventory
      final p = Product(
        id: productId,
        name: '${brandController.text} ${modelController.text}',
        sku: 'BUY-${imei.length >= 4 ? imei.substring(imei.length - 4) : imei}',
        imei: imei,
        category: 'Used Phones',
        brand: brandController.text,
        variant: specsController.text,
        purchasePrice: purchasePrice,
        sellingPrice: purchasePrice + 5000,
        stock: 1,
        condition: selectedCondition,
      );
      ref.read(productProvider.notifier).addProduct(p);
      
      // Create BuybackRecord with full metadata
      final buybackRecord = BuybackRecord(
        id: const Uuid().v4(),
        productId: productId,
        sellerName: nameController.text,
        sellerPhone: phoneController.text,
        sellerCnic: cnicController.text,
        cnicFrontPath: cnicFrontPath,
        cnicBackPath: cnicBackPath,
        brand: brandController.text,
        model: modelController.text,
        imei: imei,
        imei2: validImeis.length > 1 && i == 0 && validImeis.length > 1 ? validImeis[1].text.trim() : null,
        variant: specsController.text.isNotEmpty ? specsController.text : null,
        condition: selectedCondition.name,
        purchasePrice: purchasePrice,
        phoneImage1Path: phoneImage1Path,
        phoneImage2Path: phoneImage2Path,
      );
      ref.read(buybackProvider.notifier).addRecord(buybackRecord);
      addedCount++;
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$addedCount phone(s) added to inventory'), backgroundColor: Colors.green),
    );
  }
}

// --- Shared Widgets ---
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

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
              Icon(icon, size: 16, color: color),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
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
    final color = _getColor();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(status.name.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Color _getColor() {
    switch (status) {
      case PurchaseOrderStatus.draft: return Colors.orange;
      case PurchaseOrderStatus.sent: return Colors.blue;
      case PurchaseOrderStatus.confirmed: return Colors.purple;
      case PurchaseOrderStatus.received: return Colors.green;
      case PurchaseOrderStatus.cancelled: return Colors.red;
    }
  }
}
