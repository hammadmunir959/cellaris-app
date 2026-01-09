import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';

import '../database/isar_service.dart';
import '../database/isar_schemas.dart';
import '../models/voucher.dart';

/// Repository for Voucher and LedgerEntry operations
class VoucherRepository {
  final IsarService _isarService;

  VoucherRepository(this._isarService);

  Isar get _isar => _isarService.isar;

  // ============================================================
  // VOUCHER OPERATIONS
  // ============================================================

  /// Get all vouchers
  Future<List<Voucher>> getAll({
    String? companyId,
    DateTime? fromDate,
    DateTime? toDate,
    VoucherType? type,
  }) async {
    // Get all vouchers first, then filter in Dart
    final allPersistence = await _isar.voucherPersistences.where().findAll();
    
    var persistence = allPersistence.where((p) {
      if (companyId != null && p.companyId != companyId) return false;
      if (type != null && p.type != type.name) return false;
      if (fromDate != null && p.date.isBefore(fromDate)) return false;
      if (toDate != null && p.date.isAfter(toDate)) return false;
      return true;
    }).toList();
    
    // Load entries for each voucher
    final vouchers = <Voucher>[];
    for (final p in persistence) {
      final entries = await _getEntriesForVoucher(p.voucherNo);
      vouchers.add(_mapFromPersistence(p, entries));
    }
    return vouchers;
  }

  /// Get voucher by number
  Future<Voucher?> getByVoucherNo(String voucherNo) async {
    final persistence = await _isar.voucherPersistences
        .filter()
        .voucherNoEqualTo(voucherNo)
        .findFirst();
    
    if (persistence == null) return null;
    
    final entries = await _getEntriesForVoucher(voucherNo);
    return _mapFromPersistence(persistence, entries);
  }

  /// Get vouchers by type
  Future<List<Voucher>> getByType(VoucherType type) async {
    final persistence = await _isar.voucherPersistences
        .filter()
        .typeEqualTo(type.name)
        .findAll();
    
    final vouchers = <Voucher>[];
    for (final p in persistence) {
      final entries = await _getEntriesForVoucher(p.voucherNo);
      vouchers.add(_mapFromPersistence(p, entries));
    }
    return vouchers;
  }

  /// Get vouchers by party
  Future<List<Voucher>> getByParty(String partyId) async {
    final persistence = await _isar.voucherPersistences
        .filter()
        .partyIdEqualTo(partyId)
        .findAll();
    
    final vouchers = <Voucher>[];
    for (final p in persistence) {
      final entries = await _getEntriesForVoucher(p.voucherNo);
      vouchers.add(_mapFromPersistence(p, entries));
    }
    return vouchers;
  }

  /// Generate next voucher number
  Future<String> generateVoucherNo(VoucherType type) async {
    final prefix = _getVoucherPrefix(type);
    final count = await _isar.voucherPersistences
        .filter()
        .typeEqualTo(type.name)
        .count();
    final number = (count + 1).toString().padLeft(6, '0');
    return '$prefix$number';
  }

  /// Save voucher with entries
  Future<void> save(Voucher voucher) async {
    if (!voucher.isBalanced && voucher.type == VoucherType.journalVoucher) {
      throw Exception('Journal Voucher must be balanced (Total Debit = Total Credit)');
    }

    await _isar.writeTxn(() async {
      // Save voucher
      final voucherPersistence = _mapToPersistence(voucher);
      await _isar.voucherPersistences.put(voucherPersistence);

      // Save ledger entries
      for (final entry in voucher.entries) {
        final entryPersistence = _mapEntryToPersistence(entry);
        await _isar.ledgerEntryPersistences.put(entryPersistence);
      }
    });
  }

  /// Post voucher (mark as finalized)
  Future<void> post(String voucherNo) async {
    await _isar.writeTxn(() async {
      final persistence = await _isar.voucherPersistences
          .filter()
          .voucherNoEqualTo(voucherNo)
          .findFirst();
      if (persistence != null) {
        persistence.isPosted = true;
        persistence.updatedAt = DateTime.now();
        await _isar.voucherPersistences.put(persistence);
      }
    });
  }

  /// Delete voucher and its entries
  Future<void> delete(String voucherNo) async {
    await _isar.writeTxn(() async {
      // Delete entries first
      await _isar.ledgerEntryPersistences
          .filter()
          .sourceIdEqualTo(voucherNo)
          .deleteAll();
      
      // Delete voucher
      await _isar.voucherPersistences
          .filter()
          .voucherNoEqualTo(voucherNo)
          .deleteFirst();
    });
  }

  // ============================================================
  // LEDGER ENTRY OPERATIONS
  // ============================================================

  /// Get all ledger entries for an account
  Future<List<LedgerEntry>> getEntriesForAccount(
    String accountNo, {
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    var query = _isar.ledgerEntryPersistences
        .filter()
        .accountNoEqualTo(accountNo);
    
    if (fromDate != null) {
      query = query.dateGreaterThan(fromDate.subtract(const Duration(days: 1)));
    }
    if (toDate != null) {
      query = query.dateLessThan(toDate.add(const Duration(days: 1)));
    }

    final persistence = await query.sortByDate().findAll();
    return persistence.map(_mapEntryFromPersistence).toList();
  }

  /// Get entries for a specific voucher by voucher number
  Future<List<LedgerEntry>> _getEntriesForVoucher(String voucherNo) async {
    final persistence = await _isar.ledgerEntryPersistences
        .filter()
        .sourceIdEqualTo(voucherNo)
        .findAll();
    return persistence.map(_mapEntryFromPersistence).toList();
  }

  // ============================================================
  // HELPERS
  // ============================================================

  String _getVoucherPrefix(VoucherType type) {
    switch (type) {
      case VoucherType.cashPayment:
        return 'CP-';
      case VoucherType.cashReceipt:
        return 'CR-';
      case VoucherType.bankPayment:
        return 'BP-';
      case VoucherType.bankReceipt:
        return 'BR-';
      case VoucherType.partyPayment:
        return 'PP-';
      case VoucherType.partyReceipt:
        return 'PR-';
      case VoucherType.journalVoucher:
        return 'JV-';
    }
  }

  // ============================================================
  // MAPPERS
  // ============================================================

  Voucher _mapFromPersistence(VoucherPersistence p, List<LedgerEntry> entries) {
    return Voucher(
      voucherNo: p.voucherNo,
      type: _parseVoucherType(p.type),
      date: p.date,
      totalAmount: p.totalAmount,
      narration: p.narration,
      bankAccountNo: p.bankAccountNo,
      bankName: p.bankName,
      partyId: p.partyId,
      partyName: p.partyName,
      companyId: p.companyId,
      createdBy: p.createdBy,
      createdAt: p.createdAt,
      isPosted: p.isPosted,
      entries: entries,
    );
  }

  VoucherPersistence _mapToPersistence(Voucher v) {
    return VoucherPersistence()
      ..voucherNo = v.voucherNo
      ..type = v.type.name
      ..date = v.date
      ..totalAmount = v.totalAmount
      ..narration = v.narration
      ..bankAccountNo = v.bankAccountNo
      ..bankName = v.bankName
      ..partyId = v.partyId
      ..partyName = v.partyName
      ..companyId = v.companyId
      ..createdBy = v.createdBy
      ..createdAt = v.createdAt
      ..isPosted = v.isPosted
      ..updatedAt = DateTime.now()
      ..isSynced = false;
  }

  LedgerEntry _mapEntryFromPersistence(LedgerEntryPersistence p) {
    return LedgerEntry(
      id: p.id,
      accountNo: p.accountNo,
      accountName: p.accountName,
      date: p.date,
      debit: p.debit,
      credit: p.credit,
      particular: p.particular,
      reference: p.reference,
      sourceId: p.sourceId,
      sourceType: p.sourceType,
      companyId: p.companyId,
      taxAccountNo: p.taxAccountNo,
      taxAmount: p.taxAmount,
    );
  }

  LedgerEntryPersistence _mapEntryToPersistence(LedgerEntry e) {
    return LedgerEntryPersistence()
      ..id = e.id
      ..accountNo = e.accountNo
      ..accountName = e.accountName
      ..date = e.date
      ..debit = e.debit
      ..credit = e.credit
      ..particular = e.particular
      ..reference = e.reference
      ..sourceId = e.sourceId
      ..sourceType = e.sourceType
      ..companyId = e.companyId
      ..taxAccountNo = e.taxAccountNo
      ..taxAmount = e.taxAmount
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now()
      ..isSynced = false;
  }

  VoucherType _parseVoucherType(String type) {
    switch (type) {
      case 'cashPayment':
        return VoucherType.cashPayment;
      case 'cashReceipt':
        return VoucherType.cashReceipt;
      case 'bankPayment':
        return VoucherType.bankPayment;
      case 'bankReceipt':
        return VoucherType.bankReceipt;
      case 'partyPayment':
        return VoucherType.partyPayment;
      case 'partyReceipt':
        return VoucherType.partyReceipt;
      case 'journalVoucher':
        return VoucherType.journalVoucher;
      default:
        return VoucherType.journalVoucher;
    }
  }
}

/// Provider for VoucherRepository
final voucherRepositoryProvider = Provider<VoucherRepository>((ref) {
  final isarService = ref.watch(isarServiceProvider);
  return VoucherRepository(isarService);
});
