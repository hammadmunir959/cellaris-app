import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mbm_app/core/models/app_models.dart';
import 'package:mbm_app/core/repositories/repair_repository.dart';
import 'package:mbm_app/shared/controller/shared_controller.dart';
import 'package:mbm_app/core/models/persistence_mappers.dart';
import 'package:mbm_app/core/services/pdf_service.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

class RepairNotifier extends StateNotifier<List<RepairTicket>> {
  final RepairRepository _repository;
  final Ref ref;

  RepairNotifier(this._repository, this.ref) : super([]) {
    _init();
  }

  Future<void> _init() async {
    final persisted = await _repository.getRepairTickets();
    state = persisted.map((t) => t.toDomain()).toList();
  }

  Future<void> printTicket(RepairTicket ticket) async {
    await PdfService.generateAndPrintRepairTicket(ticket);
  }

  Future<RepairTicket> createTicket({
    required String name,
    required String contact,
    required String device,
    required String issue,
    required double cost,
    DateTime? expectedReturnDate,
    bool printAfter = false,
  }) async {
    // 1. Auto-Customer Integration
    final customers = ref.read(customerProvider);
    final existingCustomer = customers.where((c) => c.contact == contact).firstOrNull;

    if (existingCustomer == null) {
      final newCustomer = Customer(
        id: const Uuid().v4(),
        name: name,
        contact: contact,
        category: 'Repairing',
        notes: 'Automatically added from Repair Service',
      );
      await ref.read(customerProvider.notifier).addCustomer(newCustomer);
    } else if (existingCustomer.category != 'Repairing') {
      await ref.read(customerProvider.notifier).updateCustomer(
        existingCustomer.copyWith(category: 'Repairing'),
      );
    }

    // 2. Create Ticket
    final timestamp = DateFormat('yyyy-MM-dd hh:mm a').format(DateTime.now());
    final ticket = RepairTicket(
      id: 'REP-${const Uuid().v4().substring(0, 4).toUpperCase()}',
      customerName: name,
      customerContact: contact,
      deviceModel: device,
      issueDescription: issue,
      status: RepairStatus.received,
      estimatedCost: cost,
      createdAt: DateTime.now(),
      expectedReturnDate: expectedReturnDate,
      notes: ['[$timestamp] Ticket created.'],
    );

    state = [ticket, ...state];
    await _repository.saveRepairTicket(ticket.toPersistence());

    // 3. Optional Printing
    if (printAfter) {
      await printTicket(ticket);
    }
    
    return ticket;
  }

  Future<void> updateStatus(String id, RepairStatus newStatus, {String? note}) async {
    final ticketIndex = state.indexWhere((t) => t.id == id);
    if (ticketIndex == -1) return;

    final ticket = state[ticketIndex];
    final timestamp = DateFormat('yyyy-MM-dd hh:mm a').format(DateTime.now());
    final defaultNote = 'Status changed to ${newStatus.name.toUpperCase()}';
    final actualNote = (note == null || note.trim().isEmpty) ? defaultNote : note;

    final updatedTicket = ticket.copyWith(
      status: newStatus,
      notes: [...ticket.notes, '[$timestamp] $actualNote'],
    );

    state = [
      for (final t in state)
        if (t.id == id) updatedTicket else t
    ];
    
    await _repository.saveRepairTicket(updatedTicket.toPersistence());
  }

  Future<void> deleteTicket(String id) async {
    state = state.where((t) => t.id != id).toList();
    await _repository.deleteRepairTicket(id);
  }

  // Statistics & Filtering
  List<RepairTicket> searchTickets(String query) {
    if (query.isEmpty) return state;
    final q = query.toLowerCase();
    return state.where((t) => 
      t.id.toLowerCase().contains(q) || 
      t.customerName.toLowerCase().contains(q) || 
      t.customerContact.toLowerCase().contains(q) || 
      t.deviceModel.toLowerCase().contains(q)
    ).toList();
  }

  double calculateTotalRevenue() {
    return state
      .where((t) => t.status == RepairStatus.delivered)
      .fold(0.0, (sum, t) => sum + t.estimatedCost);
  }

  int getActiveRepairsCount() {
    return state.where((t) => t.status != RepairStatus.delivered).length;
  }

  int getDueTodayCount() {
    final now = DateTime.now();
    return state.where((t) => 
      t.expectedReturnDate != null && 
      t.expectedReturnDate!.year == now.year &&
      t.expectedReturnDate!.month == now.month &&
      t.expectedReturnDate!.day == now.day &&
      t.status != RepairStatus.delivered
    ).length;
  }
}


final repairProvider = StateNotifierProvider<RepairNotifier, List<RepairTicket>>((ref) {
  final repo = ref.watch(repairRepositoryProvider);
  return RepairNotifier(repo, ref);
});
