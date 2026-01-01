import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/models/app_models.dart';
import '../../../core/models/unit_imei.dart';
import '../../../core/repositories/unit_repository.dart';

/// Dialog for importing/selecting IMEIs from stock
class ImeiImportDialog extends ConsumerStatefulWidget {
  final Product product;

  const ImeiImportDialog({
    super.key,
    required this.product,
  });

  @override
  ConsumerState<ImeiImportDialog> createState() => _ImeiImportDialogState();
}

class _ImeiImportDialogState extends ConsumerState<ImeiImportDialog> {
  final _searchController = TextEditingController();
  final _manualImeiController = TextEditingController();
  final Set<String> _selectedImeis = {};
  String _searchQuery = '';
  bool _isLoading = true;
  List<Unit> _availableUnits = [];

  @override
  void initState() {
    super.initState();
    _loadAvailableUnits();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _manualImeiController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableUnits() async {
    final unitRepo = ref.read(unitRepositoryProvider);
    final units = await unitRepo.getByProduct(widget.product.id);
    
    setState(() {
      // Only show units that are in stock
      _availableUnits = units.where((u) => 
        u.status == UnitStatus.inStock || u.status == UnitStatus.issued
      ).toList();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Filter units by search query
    final filteredUnits = _availableUnits.where((unit) {
      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      return unit.imei.toLowerCase().contains(query);
    }).toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      LucideIcons.smartphone,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Import IMEIs',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.product.name,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.x),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Search bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search IMEI...',
                  prefixIcon: const Icon(LucideIcons.search, size: 18),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
            ),

            // Selected count
            if (_selectedImeis.isNotEmpty)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.check, color: Colors.green, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      '${_selectedImeis.length} IMEI(s) selected',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => setState(() => _selectedImeis.clear()),
                      child: const Text('Clear All'),
                    ),
                  ],
                ),
              ),

            // Units list
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredUnits.isEmpty
                      ? _buildEmptyState(theme)
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredUnits.length,
                          itemBuilder: (context, index) {
                            final unit = filteredUnits[index];
                            final isSelected = _selectedImeis.contains(unit.imei);
                            return _ImeiListItem(
                              unit: unit,
                              isSelected: isSelected,
                              onToggle: () {
                                setState(() {
                                  if (isSelected) {
                                    _selectedImeis.remove(unit.imei);
                                  } else {
                                    _selectedImeis.add(unit.imei);
                                  }
                                });
                              },
                            );
                          },
                        ),
            ),

            const Divider(height: 1),

            // Manual entry section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _manualImeiController,
                      decoration: InputDecoration(
                        hintText: 'Enter IMEI manually',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _addManualImei,
                    child: const Text('Add'),
                  ),
                ],
              ),
            ),

            // Action buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: _selectedImeis.isNotEmpty
                        ? () => Navigator.pop(context, _selectedImeis.toList())
                        : null,
                    icon: const Icon(LucideIcons.check, size: 18),
                    label: Text('Add ${_selectedImeis.length} to Cart'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
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

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.packageX,
            size: 48,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 12),
          Text(
            _searchQuery.isEmpty
                ? 'No IMEIs in stock for this product'
                : 'No matching IMEIs found',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          if (_searchQuery.isEmpty)
            Text(
              'Add stock to see available IMEIs',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
        ],
      ),
    );
  }

  void _addManualImei() {
    final imei = _manualImeiController.text.trim();
    if (imei.isEmpty) return;

    // Validate IMEI format (15 digits)
    if (imei.length < 15 || imei.length > 16) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('IMEI should be 15-16 digits'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check if already selected
    if (_selectedImeis.contains(imei)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('IMEI already selected'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _selectedImeis.add(imei);
      _manualImeiController.clear();
    });
  }
}

class _ImeiListItem extends StatelessWidget {
  final Unit unit;
  final bool isSelected;
  final VoidCallback onToggle;

  const _ImeiListItem({
    required this.unit,
    required this.isSelected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isSelected
          ? theme.colorScheme.primary.withValues(alpha: 0.05)
          : theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.5)
              : theme.dividerColor.withValues(alpha: 0.2),
        ),
      ),
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Checkbox
              Checkbox(
                value: isSelected,
                onChanged: (_) => onToggle(),
                activeColor: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),

              // IMEI details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      unit.imei,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),

              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(unit.status).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _getStatusLabel(unit.status),
                  style: TextStyle(
                    color: _getStatusColor(unit.status),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(UnitStatus status) {
    switch (status) {
      case UnitStatus.inStock:
        return Colors.green;
      case UnitStatus.issued:
        return Colors.orange;
      case UnitStatus.sold:
        return Colors.blue;
      case UnitStatus.returned:
        return Colors.purple;
    }
  }

  String _getStatusLabel(UnitStatus status) {
    switch (status) {
      case UnitStatus.inStock:
        return 'In Stock';
      case UnitStatus.issued:
        return 'Issued';
      case UnitStatus.sold:
        return 'Sold';
      case UnitStatus.returned:
        return 'Returned';
    }
  }
}

/// Show IMEI import dialog and return selected IMEIs
Future<List<String>?> showImeiImportDialog(
  BuildContext context,
  Product product,
) async {
  return showDialog<List<String>>(
    context: context,
    builder: (context) => ImeiImportDialog(product: product),
  );
}
