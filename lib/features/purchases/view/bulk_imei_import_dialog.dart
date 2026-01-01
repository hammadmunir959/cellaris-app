import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/models/app_models.dart';
import '../../../core/models/unit_imei.dart';
import '../../../core/repositories/unit_repository.dart';

/// Dialog for bulk IMEI import during purchase
class BulkImeiImportDialog extends ConsumerStatefulWidget {
  final Product product;
  final int expectedQuantity;

  const BulkImeiImportDialog({
    super.key,
    required this.product,
    required this.expectedQuantity,
  });

  @override
  ConsumerState<BulkImeiImportDialog> createState() => _BulkImeiImportDialogState();
}

class _BulkImeiImportDialogState extends ConsumerState<BulkImeiImportDialog> {
  final _textController = TextEditingController();
  List<String> _parsedImeis = [];
  List<String> _validatedImeis = [];
  List<String> _duplicateImeis = [];
  List<String> _invalidImeis = [];
  bool _isValidating = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 700,
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
                    child: Icon(
                      LucideIcons.download,
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
                          'Bulk IMEI Import',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${widget.product.name} • Expected: ${widget.expectedQuantity} units',
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

            // Input area
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Paste IMEIs (one per line or comma-separated):',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _textController,
                    maxLines: 8,
                    decoration: InputDecoration(
                      hintText: '352512085678901\n352512085678902\n352512085678903\n...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surface,
                    ),
                    onChanged: (_) => _parseImeis(),
                  ),
                ],
              ),
            ),

            // Parse & Validate button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _isValidating ? null : _validateImeis,
                    icon: _isValidating
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(LucideIcons.checkCircle, size: 18),
                    label: Text(_isValidating ? 'Validating...' : 'Validate IMEIs'),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Parsed: ${_parsedImeis.length}',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),

            // Validation results
            if (_validatedImeis.isNotEmpty || _duplicateImeis.isNotEmpty || _invalidImeis.isNotEmpty)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ValidationSection(
                        title: 'Valid IMEIs',
                        count: _validatedImeis.length,
                        color: Colors.green,
                        icon: LucideIcons.checkCircle,
                        imeis: _validatedImeis,
                      ),
                      if (_duplicateImeis.isNotEmpty)
                        _ValidationSection(
                          title: 'Duplicates in System',
                          count: _duplicateImeis.length,
                          color: Colors.orange,
                          icon: LucideIcons.alertTriangle,
                          imeis: _duplicateImeis,
                        ),
                      if (_invalidImeis.isNotEmpty)
                        _ValidationSection(
                          title: 'Invalid Format',
                          count: _invalidImeis.length,
                          color: Colors.red,
                          icon: LucideIcons.xCircle,
                          imeis: _invalidImeis,
                        ),
                    ],
                  ),
                ),
              ),

            // Quantity check
            if (_validatedImeis.isNotEmpty)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _validatedImeis.length == widget.expectedQuantity
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      _validatedImeis.length == widget.expectedQuantity
                          ? LucideIcons.checkCircle
                          : LucideIcons.alertCircle,
                      color: _validatedImeis.length == widget.expectedQuantity
                          ? Colors.green
                          : Colors.orange,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _validatedImeis.length == widget.expectedQuantity
                          ? 'Count matches expected quantity'
                          : 'Count (${_validatedImeis.length}) differs from expected (${widget.expectedQuantity})',
                      style: TextStyle(
                        color: _validatedImeis.length == widget.expectedQuantity
                            ? Colors.green
                            : Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

            // Actions
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: _validatedImeis.isNotEmpty
                        ? () => Navigator.pop(context, _validatedImeis)
                        : null,
                    icon: const Icon(LucideIcons.download, size: 18),
                    label: Text('Import ${_validatedImeis.length} IMEIs'),
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

  void _parseImeis() {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      setState(() => _parsedImeis = []);
      return;
    }

    // Split by newlines or commas
    final lines = text.split(RegExp(r'[\n,]+'));
    final imeis = lines
        .map((line) => line.trim().replaceAll(RegExp(r'\D'), '')) // Remove non-digits
        .where((imei) => imei.isNotEmpty)
        .toList();

    setState(() => _parsedImeis = imeis);
  }

  Future<void> _validateImeis() async {
    if (_parsedImeis.isEmpty) return;

    setState(() => _isValidating = true);

    final unitRepo = ref.read(unitRepositoryProvider);
    final validated = <String>[];
    final duplicates = <String>[];
    final invalid = <String>[];

    for (final imei in _parsedImeis) {
      // Check format (15-16 digits)
      if (imei.length < 15 || imei.length > 16) {
        invalid.add(imei);
        continue;
      }

      // Check if already exists in system
      final exists = await unitRepo.exists(imei);
      if (exists) {
        duplicates.add(imei);
      } else {
        validated.add(imei);
      }
    }

    setState(() {
      _validatedImeis = validated;
      _duplicateImeis = duplicates;
      _invalidImeis = invalid;
      _isValidating = false;
    });
  }
}

class _ValidationSection extends StatelessWidget {
  final String title;
  final int count;
  final Color color;
  final IconData icon;
  final List<String> imeis;

  const _ValidationSection({
    required this.title,
    required this.count,
    required this.color,
    required this.icon,
    required this.imeis,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: Icon(icon, color: color, size: 18),
        title: Text(
          '$title ($count)',
          style: TextStyle(color: color, fontWeight: FontWeight.w600),
        ),
        children: [
          Container(
            constraints: const BoxConstraints(maxHeight: 100),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: imeis.length,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                child: Text(
                  imeis[index],
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Show bulk IMEI import dialog and return validated IMEIs
Future<List<String>?> showBulkImeiImportDialog(
  BuildContext context,
  Product product,
  int expectedQuantity,
) async {
  return showDialog<List<String>>(
    context: context,
    builder: (context) => BulkImeiImportDialog(
      product: product,
      expectedQuantity: expectedQuantity,
    ),
  );
}
