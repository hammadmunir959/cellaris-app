import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';

import '../../../core/models/unit_imei.dart';
import '../../../core/repositories/unit_repository.dart';
import '../../inventory/controller/inventory_controller.dart';
import '../../../core/models/app_models.dart';

// ============================================================
// UNIT TRACKING VIEW
// ============================================================

class UnitTrackingView extends ConsumerStatefulWidget {
  const UnitTrackingView({super.key});

  @override
  ConsumerState<UnitTrackingView> createState() => _UnitTrackingViewState();
}

class _UnitTrackingViewState extends ConsumerState<UnitTrackingView> {
  String _searchQuery = '';
  UnitStatus? _statusFilter;
  String? _productFilter;
  List<Unit> _units = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUnits();
  }

  Future<void> _loadUnits() async {
    final unitRepo = ref.read(unitRepositoryProvider);
    final units = await unitRepo.getAll();
    setState(() {
      _units = units;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final products = ref.watch(productProvider);
    final f = NumberFormat('#,###');

    // Apply filters
    var filteredUnits = _units.where((u) {
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!u.imei.toLowerCase().contains(query) &&
            !u.productId.toLowerCase().contains(query)) {
          return false;
        }
      }
      if (_statusFilter != null && u.status != _statusFilter) {
        return false;
      }
      if (_productFilter != null && u.productId != _productFilter) {
        return false;
      }
      return true;
    }).toList();

    // Stats
    final stats = {
      'total': _units.length,
      'inStock': _units.where((u) => u.status == UnitStatus.inStock).length,
      'issued': _units.where((u) => u.status == UnitStatus.issued).length,
      'sold': _units.where((u) => u.status == UnitStatus.sold).length,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Icon(
                LucideIcons.qrCode,
                color: theme.colorScheme.primary,
                size: 28,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'IMEI Unit Tracking',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Track individual units by IMEI',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(LucideIcons.refreshCw),
                onPressed: () {
                  setState(() => _isLoading = true);
                  _loadUnits();
                },
              ),
            ],
          ),
        ),

        // Stats row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              _StatChip(
                label: 'Total',
                value: stats['total'].toString(),
                color: Colors.blue,
                isSelected: _statusFilter == null,
                onTap: () => setState(() => _statusFilter = null),
              ),
              const SizedBox(width: 12),
              _StatChip(
                label: 'In Stock',
                value: stats['inStock'].toString(),
                color: Colors.green,
                isSelected: _statusFilter == UnitStatus.inStock,
                onTap: () => setState(() => _statusFilter = UnitStatus.inStock),
              ),
              const SizedBox(width: 12),
              _StatChip(
                label: 'Issued',
                value: stats['issued'].toString(),
                color: Colors.orange,
                isSelected: _statusFilter == UnitStatus.issued,
                onTap: () => setState(() => _statusFilter = UnitStatus.issued),
              ),
              const SizedBox(width: 12),
              _StatChip(
                label: 'Sold',
                value: stats['sold'].toString(),
                color: Colors.purple,
                isSelected: _statusFilter == UnitStatus.sold,
                onTap: () => setState(() => _statusFilter = UnitStatus.sold),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Filters row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              // Search
              Expanded(
                flex: 2,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search IMEI...',
                    prefixIcon: const Icon(LucideIcons.search, size: 18),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surface,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
              ),
              const SizedBox(width: 16),

              // Product filter
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    hintText: 'All Products',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surface,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  value: _productFilter,
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('All Products'),
                    ),
                    ...products.map((p) => DropdownMenuItem(
                      value: p.id,
                      child: Text(p.name, overflow: TextOverflow.ellipsis),
                    )),
                  ],
                  onChanged: (value) => setState(() => _productFilter = value),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Units table
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : filteredUnits.isEmpty
                  ? _buildEmptyState(theme)
                  : _buildUnitsTable(context, filteredUnits, products, f),
        ),
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.qrCode,
            size: 64,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No units found',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnitsTable(
    BuildContext context,
    List<Unit> units,
    List<Product> products,
    NumberFormat f,
  ) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: theme.dividerColor.withValues(alpha: 0.1),
                ),
              ),
            ),
            child: Row(
              children: const [
                Expanded(flex: 2, child: Text('IMEI', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text('Product', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(child: Text('Location', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(child: Text('Purchase', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(child: Text('Sale', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
            ),
          ),

          // Body
          Expanded(
            child: ListView.builder(
              itemCount: units.length,
              itemBuilder: (context, index) {
                final unit = units[index];
                final product = products.where((p) => p.id == unit.productId).firstOrNull;

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: theme.dividerColor.withValues(alpha: 0.05),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          unit.imei,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          product?.name ?? unit.productId,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Expanded(
                        child: _StatusBadge(status: unit.status),
                      ),
                      Expanded(
                        child: Text(
                          unit.locationId ?? '-',
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (unit.purchaseBillNo != null)
                              Text(
                                unit.purchaseBillNo!,
                                style: const TextStyle(fontSize: 11),
                              ),
                            Text(
                              'Rs. ${f.format(unit.purchasePrice)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (unit.saleBillNo != null)
                              Text(
                                unit.saleBillNo!,
                                style: const TextStyle(fontSize: 11),
                              ),
                            if (unit.soldPrice != null)
                              Text(
                                'Rs. ${f.format(unit.soldPrice!)}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.green,
                                ),
                              ),
                            if (unit.saleBillNo == null)
                              Text(
                                '-',
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(color: color, width: 2)
              : null,
        ),
        child: Row(
          children: [
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: color,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final UnitStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    switch (status) {
      case UnitStatus.inStock:
        color = Colors.green;
        label = 'In Stock';
        break;
      case UnitStatus.issued:
        color = Colors.orange;
        label = 'Issued';
        break;
      case UnitStatus.sold:
        color = Colors.purple;
        label = 'Sold';
        break;
      case UnitStatus.returned:
        color = Colors.blue;
        label = 'Returned';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
