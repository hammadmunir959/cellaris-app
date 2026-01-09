import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';

import '../database/isar_service.dart';
import '../database/isar_schemas.dart';
import '../models/voucher.dart';

/// Repository for Ledger Entry operations and account balance calculations
class LedgerRepository {
  final IsarService _isarService;

  LedgerRepository(this._isarService);

  Isar get _isar => _isarService.isar;

  // ============================================================
  // QUERY OPERATIONS
  // ============================================================

  /// Get all ledger entries for an account
  Future<List<LedgerEntry>> getByAccount(
    String accountNo, {
    DateTime? fromDate,
    DateTime? toDate,
    String? companyId,
  }) async {
    var query = _isar.ledgerEntryPersistences
        .filter()
        .accountNoEqualTo(accountNo);
    
    if (companyId != null) {
      query = query.companyIdEqualTo(companyId);
    }
    if (fromDate != null) {
      query = query.dateGreaterThan(fromDate.subtract(const Duration(days: 1)));
    }
    if (toDate != null) {
      query = query.dateLessThan(toDate.add(const Duration(days: 1)));
    }

    final persistence = await query.sortByDate().findAll();
    return persistence.map(_mapFromPersistence).toList();
  }

  /// Get all entries for a date range
  Future<List<LedgerEntry>> getByDateRange({
    required DateTime fromDate,
    required DateTime toDate,
    String? companyId,
  }) async {
    var query = _isar.ledgerEntryPersistences
        .filter()
        .dateGreaterThan(fromDate.subtract(const Duration(days: 1)))
        .dateLessThan(toDate.add(const Duration(days: 1)));
    
    if (companyId != null) {
      query = query.companyIdEqualTo(companyId);
    }

    final persistence = await query.sortByDate().findAll();
    return persistence.map(_mapFromPersistence).toList();
  }

  /// Get entries by source (voucher or invoice)
  Future<List<LedgerEntry>> getBySource(String sourceId) async {
    final persistence = await _isar.ledgerEntryPersistences
        .filter()
        .sourceIdEqualTo(sourceId)
        .findAll();
    return persistence.map(_mapFromPersistence).toList();
  }

  // ============================================================
  // BALANCE CALCULATIONS
  // ============================================================

  /// Get account balance as of a specific date
  Future<double> getAccountBalance(
    String accountNo, {
    DateTime? asOfDate,
    String? companyId,
  }) async {
    var query = _isar.ledgerEntryPersistences
        .filter()
        .accountNoEqualTo(accountNo);
    
    if (companyId != null) {
      query = query.companyIdEqualTo(companyId);
    }
    if (asOfDate != null) {
      query = query.dateLessThan(asOfDate.add(const Duration(days: 1)));
    }

    final entries = await query.findAll();
    
    double balance = 0;
    for (final entry in entries) {
      balance += entry.debit - entry.credit;
    }
    return balance;
  }

  /// Get total debits for an account
  Future<double> getTotalDebits(
    String accountNo, {
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final allEntries = await _isar.ledgerEntryPersistences
        .filter()
        .accountNoEqualTo(accountNo)
        .findAll();
    
    double total = 0.0;
    for (final e in allEntries) {
      if (fromDate != null && e.date.isBefore(fromDate)) continue;
      if (toDate != null && e.date.isAfter(toDate)) continue;
      total += e.debit;
    }
    return total;
  }

  /// Get total credits for an account
  Future<double> getTotalCredits(
    String accountNo, {
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final allEntries = await _isar.ledgerEntryPersistences
        .filter()
        .accountNoEqualTo(accountNo)
        .findAll();
    
    double total = 0.0;
    for (final e in allEntries) {
      if (fromDate != null && e.date.isBefore(fromDate)) continue;
      if (toDate != null && e.date.isAfter(toDate)) continue;
      total += e.credit;
    }
    return total;
  }

  // ============================================================
  // REPORTING
  // ============================================================

  /// Get trial balance (all accounts with their balances)
  Future<Map<String, double>> getTrialBalance({
    DateTime? asOfDate,
    String? companyId,
  }) async {
    final allEntries = await _isar.ledgerEntryPersistences.where().findAll();
    
    var entries = allEntries.where((e) {
      if (companyId != null && e.companyId != companyId) return false;
      if (asOfDate != null && e.date.isAfter(asOfDate)) return false;
      return true;
    }).toList();
    
    final balances = <String, double>{};
    for (final entry in entries) {
      final current = balances[entry.accountNo] ?? 0;
      balances[entry.accountNo] = current + entry.debit - entry.credit;
    }
    
    return balances;
  }

  /// Get day book (all entries for a specific day)
  Future<List<LedgerEntry>> getDayBook(DateTime date, {String? companyId}) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    return getByDateRange(
      fromDate: startOfDay,
      toDate: endOfDay,
      companyId: companyId,
    );
  }

  /// Get account summary (opening, debits, credits, closing)
  Future<AccountSummary> getAccountSummary(
    String accountNo, {
    required DateTime fromDate,
    required DateTime toDate,
    String? companyId,
  }) async {
    // Opening balance (before fromDate)
    final opening = await getAccountBalance(
      accountNo,
      asOfDate: fromDate.subtract(const Duration(days: 1)),
      companyId: companyId,
    );
    
    // Period debits and credits
    final debits = await getTotalDebits(accountNo, fromDate: fromDate, toDate: toDate);
    final credits = await getTotalCredits(accountNo, fromDate: fromDate, toDate: toDate);
    
    // Closing balance
    final closing = opening + debits - credits;
    
    return AccountSummary(
      accountNo: accountNo,
      openingBalance: opening,
      totalDebits: debits,
      totalCredits: credits,
      closingBalance: closing,
    );
  }

  // ============================================================
  // MAPPERS
  // ============================================================

  LedgerEntry _mapFromPersistence(LedgerEntryPersistence p) {
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
}

/// Account summary for reporting
class AccountSummary {
  final String accountNo;
  final double openingBalance;
  final double totalDebits;
  final double totalCredits;
  final double closingBalance;

  AccountSummary({
    required this.accountNo,
    required this.openingBalance,
    required this.totalDebits,
    required this.totalCredits,
    required this.closingBalance,
  });
}

/// Provider for LedgerRepository
final ledgerRepositoryProvider = Provider<LedgerRepository>((ref) {
  final isarService = ref.watch(isarServiceProvider);
  return LedgerRepository(isarService);
});
