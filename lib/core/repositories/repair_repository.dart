import 'package:isar/isar.dart';
import 'package:mbm_app/core/database/isar_schemas.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mbm_app/core/database/isar_service.dart';

class RepairRepository {
  final Isar _isar;
  RepairRepository(this._isar);

  Future<List<RepairTicketPersistence>> getRepairTickets() async {
    return _isar.repairTicketPersistences.where().findAll();
  }

  Future<List<RepairTicketPersistence>> getRepairTicketsByCustomer(String customerName) async {
    return _isar.repairTicketPersistences.filter().customerNameEqualTo(customerName).findAll();
  }

  Future<void> saveRepairTicket(RepairTicketPersistence ticket) async {
    await _isar.writeTxn(() async {
      ticket.updatedAt = DateTime.now();
      await _isar.repairTicketPersistences.put(ticket);
    });
  }

  Future<void> deleteRepairTicket(String id) async {
    await _isar.writeTxn(() async {
      await _isar.repairTicketPersistences.filter().idEqualTo(id).deleteFirst();
    });
  }
}

final repairRepositoryProvider = Provider<RepairRepository>((ref) {
  final isar = ref.watch(isarServiceProvider).isar;
  return RepairRepository(isar);
});
