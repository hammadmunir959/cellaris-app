import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/models/app_models.dart';
import '../../../core/models/location.dart';
import '../../../core/models/unit_imei.dart';
import '../../../core/repositories/unit_repository.dart';
import '../../inventory/controller/inventory_controller.dart';

// ============================================================
// STOCK ISSUANCE STATE
// ============================================================

class StockIssuanceState {
  final String? sourceLocationId;
  final String? targetLocationId;
  final List<String> selectedImeis;
  final bool isProcessing;
  final String? error;

  const StockIssuanceState({
    this.sourceLocationId,
    this.targetLocationId,
    this.selectedImeis = const [],
    this.isProcessing = false,
    this.error,
  });

  StockIssuanceState copyWith({
    String? sourceLocationId,
    String? targetLocationId,
    List<String>? selectedImeis,
    bool? isProcessing,
    String? error,
  }) {
    return StockIssuanceState(
      sourceLocationId: sourceLocationId ?? this.sourceLocationId,
      targetLocationId: targetLocationId ?? this.targetLocationId,
      selectedImeis: selectedImeis ?? this.selectedImeis,
      isProcessing: isProcessing ?? this.isProcessing,
      error: error,
    );
  }
}

// ============================================================
// STOCK ISSUANCE SCREEN
// ============================================================

class StockIssuanceScreen extends ConsumerStatefulWidget {
  const StockIssuanceScreen({super.key});

  @override
  ConsumerState<StockIssuanceScreen> createState() => _StockIssuanceScreenState();
}

class _StockIssuanceScreenState extends ConsumerState<StockIssuanceScreen> {
  String? _selectedProduct;
  String? _targetLocation;
  final Set<String> _selectedImeis = {};
  List<Unit> _availableUnits = [];
  bool _isLoading = false;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final products = ref.watch(productProvider);

    // Filter products that have IMEI tracking
    final imeiProducts = products.where((p) => !p.isAccessory).toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: theme.dividerColor.withValues(alpha: 0.1),
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  LucideIcons.arrowRightLeft,
                  color: theme.colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Stock Issuance',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Issue stock to locations/branches',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // Process button
                ElevatedButton.icon(
                  onPressed: _selectedImeis.isNotEmpty && _targetLocation != null
                      ? _processIssuance
                      : null,
                  icon: const Icon(LucideIcons.send, size: 18),
                  label: Text('Issue ${_selectedImeis.length} Units'),
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

          // Filters row
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Product filter
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Product',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(LucideIcons.smartphone, size: 18),
                    ),
                    value: _selectedProduct,
                    items: imeiProducts.map((p) => DropdownMenuItem(
                      value: p.id,
                      child: Text(p.name),
                    )).toList(),
                    onChanged: (value) {
                      setState(() => _selectedProduct = value);
                      if (value != null) _loadUnits(value);
                    },
                  ),
                ),
                const SizedBox(width: 16),

                // Target location
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Target Location',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(LucideIcons.mapPin, size: 18),
                    ),
                    value: _targetLocation,
                    items: _getLocationOptions(),
                    onChanged: (value) => setState(() => _targetLocation = value),
                  ),
                ),
                const SizedBox(width: 16),

                // Search
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Search IMEI',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(LucideIcons.search, size: 18),
                    ),
                    onChanged: (value) => setState(() => _searchQuery = value),
                  ),
                ),
              ],
            ),
          ),

          // Selected count
          if (_selectedImeis.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.checkCircle, color: Colors.blue, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    '${_selectedImeis.length} unit(s) selected for issuance',
                    style: const TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => setState(() => _selectedImeis.clear()),
                    child: const Text('Clear Selection'),
                  ),
                ],
              ),
            ),

          // Units list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _selectedProduct == null
                    ? _buildEmptyState(theme, 'Select a product to view units')
                    : _availableUnits.isEmpty
                        ? _buildEmptyState(theme, 'No units in stock')
                        : _buildUnitsList(theme),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.package,
            size: 64,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnitsList(ThemeData theme) {
    // Filter by search
    final filteredUnits = _availableUnits.where((u) {
      if (_searchQuery.isEmpty) return true;
      return u.imei.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredUnits.length,
      itemBuilder: (context, index) {
        final unit = filteredUnits[index];
        final isSelected = _selectedImeis.contains(unit.imei);

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
            onTap: () {
              setState(() {
                if (isSelected) {
                  _selectedImeis.remove(unit.imei);
                } else {
                  _selectedImeis.add(unit.imei);
                }
              });
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Checkbox(
                    value: isSelected,
                    onChanged: (_) {
                      setState(() {
                        if (isSelected) {
                          _selectedImeis.remove(unit.imei);
                        } else {
                          _selectedImeis.add(unit.imei);
                        }
                      });
                    },
                    activeColor: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
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
                        if (unit.color != null)
                          Text(
                            'Color: ${unit.color}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
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
                  const SizedBox(width: 12),
                  // Current location
                  if (unit.locationId != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: theme.dividerColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.mapPin, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            unit.locationId!,
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<DropdownMenuItem<String>> _getLocationOptions() {
    // TODO: Replace with actual location repository data
    return const [
      DropdownMenuItem(value: 'LOC-001', child: Text('Main Warehouse')),
      DropdownMenuItem(value: 'LOC-002', child: Text('Shop Floor A')),
      DropdownMenuItem(value: 'LOC-003', child: Text('Shop Floor B')),
      DropdownMenuItem(value: 'LOC-004', child: Text('Branch Office')),
    ];
  }

  Future<void> _loadUnits(String productId) async {
    setState(() => _isLoading = true);

    final unitRepo = ref.read(unitRepositoryProvider);
    final units = await unitRepo.getByProduct(productId);

    setState(() {
      _availableUnits = units.where((u) =>
        u.status == UnitStatus.inStock || u.status == UnitStatus.issued
      ).toList();
      _isLoading = false;
      _selectedImeis.clear();
    });
  }

  Future<void> _processIssuance() async {
    if (_targetLocation == null || _selectedImeis.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final unitRepo = ref.read(unitRepositoryProvider);

      for (final imei in _selectedImeis) {
        await unitRepo.issueToLocation(imei, _targetLocation!);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_selectedImeis.length} units issued to $_targetLocation'),
            backgroundColor: Colors.green,
          ),
        );

        // Reload units
        if (_selectedProduct != null) {
          await _loadUnits(_selectedProduct!);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
