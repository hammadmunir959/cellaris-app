import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mbm_app/core/models/app_models.dart';
import 'package:mbm_app/core/models/unit_imei.dart';
import 'package:mbm_app/core/repositories/unit_repository.dart';
import 'package:mbm_app/core/widgets/glass_card.dart';
import 'package:mbm_app/core/widgets/primary_button.dart';
import 'package:mbm_app/core/theme/app_theme.dart';

class ImeiSelectionDialog extends ConsumerStatefulWidget {
  final Product product;
  final int maxSelection;

  const ImeiSelectionDialog({
    super.key,
    required this.product,
    this.maxSelection = 999,
  });

  @override
  ConsumerState<ImeiSelectionDialog> createState() => _ImeiSelectionDialogState();
}

class _ImeiSelectionDialogState extends ConsumerState<ImeiSelectionDialog> {
  final _searchController = TextEditingController();
  List<Unit> _availableUnits = [];
  List<Unit> _filteredUnits = [];
  final Set<String> _selectedImeis = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUnits();
  }

  Future<void> _loadUnits() async {
    final repo = ref.read(unitRepositoryProvider);
    final allUnits = await repo.getByProduct(widget.product.id);
    
    // Filter only available units (In Stock)
    final available = allUnits.where((u) => u.isAvailableForSale).toList();

    setState(() {
      _availableUnits = available;
      _filteredUnits = available;
      _isLoading = false;
    });
  }

  void _filterUnits(String query) {
    if (query.isEmpty) {
      setState(() => _filteredUnits = _availableUnits);
      return;
    }
    final lower = query.toLowerCase();
    setState(() {
      _filteredUnits = _availableUnits.where((u) => 
        u.imei.toLowerCase().contains(lower) || 
        (u.color?.toLowerCase().contains(lower) ?? false)
      ).toList();
    });
  }

  void _toggleSelection(String imei) {
    setState(() {
      if (_selectedImeis.contains(imei)) {
        _selectedImeis.remove(imei);
      } else {
        if (_selectedImeis.length < widget.maxSelection) {
          _selectedImeis.add(imei);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: GlassCard(
        width: 500,
        height: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Select IMEIs', style: theme.textTheme.titleLarge),
                    Text(widget.product.name, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                  ],
                ),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(LucideIcons.x)),
              ],
            ),
            const Divider(height: 32),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search IMEI or Color...',
                prefixIcon: const Icon(LucideIcons.search, size: 18),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              onChanged: _filterUnits,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : _filteredUnits.isEmpty
                  ? const Center(child: Text('No available units found.'))
                  : ListView.builder(
                      itemCount: _filteredUnits.length,
                      itemBuilder: (context, index) {
                        final unit = _filteredUnits[index];
                        final isSelected = _selectedImeis.contains(unit.imei);
                        return ListTile(
                          onTap: () => _toggleSelection(unit.imei),
                          leading: Icon(
                            isSelected ? LucideIcons.checkSquare : LucideIcons.square,
                            color: isSelected ? AppTheme.primaryColor : Colors.grey,
                          ),
                          title: Text(unit.imei, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: unit.color != null ? Text('Color: ${unit.color}') : null,
                          trailing: isSelected ? const Icon(LucideIcons.check, color: AppTheme.primaryColor, size: 16) : null,
                        );
                      },
                    ),
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${_selectedImeis.length} selected'),
                PrimaryButton(
                  label: 'Add to Cart', 
                  onPressed: _selectedImeis.isEmpty ? null : () => Navigator.pop(context, _selectedImeis.toList()),
                  icon: LucideIcons.shoppingBag,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Future<List<String>?> showImeiSelectionDialog(BuildContext context, Product product) async {
  return showDialog<List<String>>(
    context: context,
    builder: (context) => ImeiSelectionDialog(product: product),
  );
}
