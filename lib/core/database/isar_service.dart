import 'dart:io';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'isar_schemas.dart';
import 'local_control_state.dart';

class IsarService {
  late Isar isar;

  Future<void> init() async {
    String dbPath;
    
    try {
      final dir = await getApplicationDocumentsDirectory();
      dbPath = dir.path;
    } catch (e) {
      // Fallback for Linux when /proc/self/exe cannot be resolved
      if (Platform.isLinux) {
        final fallbackDir = Directory('${Platform.environment['HOME']}/.mbm_app');
        if (!await fallbackDir.exists()) {
          await fallbackDir.create(recursive: true);
        }
        dbPath = fallbackDir.path;
      } else {
        rethrow;
      }
    }
    
    isar = await Isar.open(
      [
        // Core entities
        ProductPersistenceSchema,
        CustomerPersistenceSchema,
        SaleDraftPersistenceSchema,
        SupplierPersistenceSchema,
        PurchaseOrderPersistenceSchema,
        RepairTicketPersistenceSchema,
        // Accounting
        AccountGroupPersistenceSchema,
        AccountPersistenceSchema,
        VoucherPersistenceSchema,
        LedgerEntryPersistenceSchema,
        // Stock Ledger (Unified serialized + non-serialized)
        StockEntryPersistenceSchema,
        // IMEI tracking (deprecated - kept for migration)
        UnitPersistenceSchema,
        // Invoices
        InvoicePersistenceSchema,
        InvoiceLineItemPersistenceSchema,
        // Multi-company support
        CompanyPersistenceSchema,
        LocationPersistenceSchema,
        SalesmanPersistenceSchema,
        // Control plane (offline tracking)
        LocalControlStatePersistenceSchema,
      ],
      directory: dbPath,
    );
  }
}

final isarServiceProvider = Provider<IsarService>((ref) {
  throw UnimplementedError('Initialize this in main.dart');
});
