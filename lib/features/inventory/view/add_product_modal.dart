import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:animate_do/animate_do.dart';
import 'package:mbm_app/core/theme/app_theme.dart';
import 'package:mbm_app/core/widgets/glass_card.dart';
import 'package:mbm_app/core/widgets/primary_button.dart';
import 'package:mbm_app/features/inventory/controller/inventory_controller.dart';
import 'package:mbm_app/shared/controller/shared_controller.dart';
import 'package:mbm_app/core/models/app_models.dart';
import 'package:uuid/uuid.dart';

class AddProductModal extends ConsumerStatefulWidget {
  final Product? product;
  const AddProductModal({super.key, this.product});

  @override
  ConsumerState<AddProductModal> createState() => _AddProductModalState();
}

class _AddProductModalState extends ConsumerState<AddProductModal> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final nameController = TextEditingController();
  final brandController = TextEditingController();
  final categoryController = TextEditingController();
  final variantController = TextEditingController();
  final costPriceController = TextEditingController();
  final salePriceController = TextEditingController();
  final quantityController = TextEditingController();
  final skuController = TextEditingController();
  
  // State
  String? selectedSupplier;
  ProductCondition condition = ProductCondition.new_;
  bool isActive = true;
  bool isSerialized = true; // TRUE for mobiles (requires IMEI), FALSE for accessories
  bool isEditing = false;
  bool isLoading = false;
  String? generatedBarcode;

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      isEditing = true;
      final p = widget.product!;
      nameController.text = p.name;
      brandController.text = p.brand ?? '';
      categoryController.text = p.category;
      variantController.text = p.variant ?? '';
      costPriceController.text = p.purchasePrice.toString();
      salePriceController.text = p.sellingPrice.toString();
      quantityController.text = p.stock.toString();
      skuController.text = p.sku;
      selectedSupplier = p.supplierId;
      condition = p.condition;
      isActive = p.isActive;
      isSerialized = p.isSerialized;
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    brandController.dispose();
    categoryController.dispose();
    variantController.dispose();
    costPriceController.dispose();
    salePriceController.dispose();
    quantityController.dispose();
    skuController.dispose();
    super.dispose();
  }

  void _generateSKU() {
    setState(() {
      generatedBarcode = 'SKU-${const Uuid().v4().substring(0, 8).toUpperCase()}';
      skuController.text = generatedBarcode!;
    });
  }

  void _scanBarcode() async {
    // Mocking barcode scan behavior
    setState(() => isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() {
        isLoading = false;
        skuController.text = 'SCN-${const Uuid().v4().substring(0, 8).toUpperCase()}';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Barcode scanned successfully!')),
      );
    }
  }

  void _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);
    
    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    final newProduct = Product(
      id: isEditing ? widget.product!.id : const Uuid().v4(),
      name: nameController.text,
      sku: skuController.text,
      brand: brandController.text.isNotEmpty ? brandController.text : null,
      category: categoryController.text,
      variant: variantController.text.isNotEmpty ? variantController.text : null,
      purchasePrice: double.tryParse(costPriceController.text) ?? 0,
      sellingPrice: double.tryParse(salePriceController.text) ?? 0,
      stock: int.tryParse(quantityController.text) ?? 0,
      condition: condition,
      isActive: isActive,
      isSerialized: isSerialized,
      supplierId: selectedSupplier,
      // Preserve these if editing
      lowStockThreshold: isEditing ? widget.product!.lowStockThreshold : 10,
      minStockLevel: isEditing ? widget.product!.minStockLevel : 5,
    );

    if (isEditing) {
      await ref.read(productProvider.notifier).updateProduct(newProduct);
    } else {
      await ref.read(productProvider.notifier).addProduct(newProduct);
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${newProduct.name} ${isEditing ? 'updated' : 'added to inventory'}.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final suppliers = ref.watch(supplierProvider);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: FadeInDown(
        duration: const Duration(milliseconds: 300),
        child: Container(
          width: 900,
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
                        Text(isEditing ? 'Edit Product' : 'Add New Product', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        Text(isEditing ? 'Update the product details below.' : 'Fill in the details to expand your catalog.', style: const TextStyle(color: Colors.grey, fontSize: 13)),
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

              // Form Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Row 1: Basic Info
                        _SectionHeader(title: 'Basic Information', icon: LucideIcons.info),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(child: _FormField(label: 'Product Name', controller: nameController, hint: 'e.g. iPhone 15 Pro', required: true)),
                            const SizedBox(width: 24),
                            Expanded(child: _FormField(label: 'Brand', controller: brandController, hint: 'e.g. Apple')),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(child: _FormField(label: 'Category', controller: categoryController, hint: 'e.g. Smartphones')),
                            const SizedBox(width: 24),
                            Expanded(child: _FormField(label: 'Variant', controller: variantController, hint: 'e.g. 256GB, Blue Titanium')),
                          ],
                        ),

                        const SizedBox(height: 48),

                        // Row 2: Pricing & Inventory
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _SectionHeader(title: 'Pricing', icon: LucideIcons.dollarSign),
                                  const SizedBox(height: 20),
                                  _FormField(label: 'Cost Price', controller: costPriceController, hint: '0.00', prefix: 'Rs.', keyboardType: TextInputType.number),
                                  const SizedBox(height: 16),
                                  _FormField(label: 'Sale Price', controller: salePriceController, hint: '0.00', prefix: 'Rs.', keyboardType: TextInputType.number, required: true),
                                ],
                              ),
                            ),
                            const SizedBox(width: 48),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _SectionHeader(title: 'Inventory', icon: LucideIcons.box),
                                  const SizedBox(height: 20),
                                  _FormField(label: 'Initial Quantity', controller: quantityController, hint: '0', keyboardType: TextInputType.number),
                                  const SizedBox(height: 16),
                                  const Text('Supplier', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<String>(
                                    value: selectedSupplier,
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: Colors.white.withOpacity(0.03),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                                    ),
                                    items: suppliers.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                                    onChanged: (val) => setState(() => selectedSupplier = val),
                                    hint: const Text('Select Supplier', style: TextStyle(fontSize: 14)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 48),

                        // Row 3: Identification (Barcodes)
                        _SectionHeader(title: 'Identification', icon: LucideIcons.scan),
                        const SizedBox(height: 20),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(child: _FormField(label: 'SKU / IMEI / Barcode', controller: skuController, hint: 'Enter or Scan')),
                            const SizedBox(width: 16),
                            PrimaryButton(
                              label: 'Scan', 
                              onPressed: _scanBarcode, 
                              icon: LucideIcons.camera, 
                              width: 120, 
                              height: 48,
                              color: AppTheme.primaryColor.withOpacity(0.1),
                            ),
                            const SizedBox(width: 12),
                            PrimaryButton(
                              label: 'Generate', 
                              onPressed: _generateSKU, 
                              icon: LucideIcons.refreshCcw, 
                              width: 140, 
                              height: 48,
                              color: Colors.blue.withOpacity(0.1),
                            ),
                          ],
                        ),
                        if (skuController.text.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.03),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withOpacity(0.05)),
                            ),
                            child: Row(
                              children: [
                                Icon(LucideIcons.scan, size: 40, color: Colors.grey),
                                const SizedBox(width: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Barcode Preview', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                    Text(skuController.text, style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2)),
                                  ],
                                ),
                                const Spacer(),
                                IconButton(icon: const Icon(LucideIcons.printer, size: 18), onPressed: () {}),
                                IconButton(icon: const Icon(LucideIcons.download, size: 18), onPressed: () {}),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 48),

                        // Row 4: Inventory Type & Attributes
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _SectionHeader(title: 'Inventory Type', icon: LucideIcons.layers),
                                  const SizedBox(height: 20),
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.03),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: _ChoiceBtn(
                                                label: '📱 Serialized (IMEI)', 
                                                isSelected: isSerialized, 
                                                onTap: () => setState(() => isSerialized = true),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: _ChoiceBtn(
                                                label: '📦 Non-Serialized', 
                                                isSelected: !isSerialized, 
                                                onTap: () => setState(() => isSerialized = false),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          isSerialized 
                                            ? 'Each unit requires a unique IMEI/Serial number (e.g., Mobile Phones)'
                                            : 'Units tracked by quantity only, no serial numbers required (e.g., Chargers, Cables)',
                                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        // Row 5: Condition & Status
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Product Condition', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      _ChoiceBtn(
                                        label: 'Brand New', 
                                        isSelected: condition == ProductCondition.new_, 
                                        onTap: () => setState(() => condition = ProductCondition.new_)
                                      ),
                                      const SizedBox(width: 12),
                                      _ChoiceBtn(
                                        label: 'Used / Pre-owned', 
                                        isSelected: condition == ProductCondition.used, 
                                        onTap: () => setState(() => condition = ProductCondition.used)
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 48),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('System Status', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)),
                                  const SizedBox(height: 12),
                                  SwitchListTile(
                                    title: Text(isActive ? 'Product is Active' : 'Product is Inactive', style: const TextStyle(fontSize: 14)),
                                    subtitle: const Text('Inactive products are hidden in POS', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                    value: isActive,
                                    onChanged: (val) => setState(() => isActive = val),
                                    contentPadding: EdgeInsets.zero,
                                    activeColor: Colors.green,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Footer Actions
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Discard Changes', style: TextStyle(color: Colors.grey)),
                    ),
                    const SizedBox(width: 24),
                    PrimaryButton(
                      label: isEditing ? 'Update Product' : 'Save Product',
                      onPressed: _handleSubmit,
                      isLoading: isLoading,
                      width: 200,
                      icon: isEditing ? LucideIcons.check : LucideIcons.save,
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
  final TextInputType keyboardType;
  final String? prefix;

  const _FormField({
    required this.label, 
    required this.hint, 
    required this.controller, 
    this.required = false,
    this.keyboardType = TextInputType.text,
    this.prefix,
  });

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
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 15),
          validator: (val) {
            if (required && (val == null || val.isEmpty)) {
              return 'This field is required';
            }
            return null;
          },
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.withOpacity(0.5), fontSize: 14),
            prefixText: prefix != null ? '$prefix ' : null,
            prefixStyle: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
            filled: true,
            fillColor: Colors.white.withOpacity(0.03),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1)),
            errorStyle: const TextStyle(fontSize: 10),
          ),
        ),
      ],
    );
  }
}

class _ChoiceBtn extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ChoiceBtn({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? AppTheme.primaryColor : Colors.white.withOpacity(0.05)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
