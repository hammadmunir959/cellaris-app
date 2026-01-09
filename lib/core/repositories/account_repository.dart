import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';

import '../database/isar_service.dart';
import '../database/isar_schemas.dart';
import '../models/account.dart';

/// Repository for Chart of Accounts management
class AccountRepository {
  final IsarService _isarService;

  AccountRepository(this._isarService);

  Isar get _isar => _isarService.isar;

  // ============================================================
  // ACCOUNT GROUP OPERATIONS
  // ============================================================

  /// Get all account groups
  Future<List<AccountGroup>> getAllGroups() async {
    final persistence = await _isar.accountGroupPersistences.where().findAll();
    return persistence.map(_mapGroupFromPersistence).toList();
  }

  /// Get account group by ID
  Future<AccountGroup?> getGroupById(int id) async {
    final persistence = await _isar.accountGroupPersistences
        .filter()
        .idEqualTo(id)
        .findFirst();
    return persistence != null ? _mapGroupFromPersistence(persistence) : null;
  }

  /// Save account group
  Future<void> saveGroup(AccountGroup group) async {
    final persistence = _mapGroupToPersistence(group);
    await _isar.writeTxn(() async {
      await _isar.accountGroupPersistences.put(persistence);
    });
  }

  /// Delete account group
  Future<void> deleteGroup(int id) async {
    await _isar.writeTxn(() async {
      await _isar.accountGroupPersistences.filter().idEqualTo(id).deleteFirst();
    });
  }

  // ============================================================
  // ACCOUNT OPERATIONS
  // ============================================================

  /// Get all accounts
  Future<List<Account>> getAll({String? companyId}) async {
    var query = _isar.accountPersistences.where();
    if (companyId != null) {
      final persistence = await _isar.accountPersistences
          .filter()
          .companyIdEqualTo(companyId)
          .or()
          .isPublicEqualTo(true)
          .findAll();
      return persistence.map(_mapFromPersistence).toList();
    }
    final persistence = await query.findAll();
    return persistence.map(_mapFromPersistence).toList();
  }

  /// Get account by account number
  Future<Account?> getByAccountNo(String accountNo) async {
    final persistence = await _isar.accountPersistences
        .filter()
        .accountNoEqualTo(accountNo)
        .findFirst();
    return persistence != null ? _mapFromPersistence(persistence) : null;
  }

  /// Get accounts by group
  Future<List<Account>> getByGroup(int groupId) async {
    final persistence = await _isar.accountPersistences
        .filter()
        .groupIdEqualTo(groupId)
        .findAll();
    return persistence.map(_mapFromPersistence).toList();
  }

  /// Get accounts by level (1st, 2nd, or 3rd)
  Future<List<Account>> getByLevel(int level) async {
    final all = await getAll();
    return all.where((a) => a.level == level).toList();
  }

  /// Search accounts by title
  Future<List<Account>> search(String query) async {
    final persistence = await _isar.accountPersistences
        .filter()
        .titleContains(query, caseSensitive: false)
        .findAll();
    return persistence.map(_mapFromPersistence).toList();
  }

  /// Save account
  Future<void> save(Account account) async {
    final persistence = _mapToPersistence(account);
    await _isar.writeTxn(() async {
      await _isar.accountPersistences.put(persistence);
    });
  }

  /// Update account balance
  Future<void> updateBalance(String accountNo, double newBalance) async {
    await _isar.writeTxn(() async {
      final persistence = await _isar.accountPersistences
          .filter()
          .accountNoEqualTo(accountNo)
          .findFirst();
      if (persistence != null) {
        persistence.currentBalance = newBalance;
        persistence.updatedAt = DateTime.now();
        await _isar.accountPersistences.put(persistence);
      }
    });
  }

  /// Delete account
  Future<void> delete(String accountNo) async {
    await _isar.writeTxn(() async {
      await _isar.accountPersistences
          .filter()
          .accountNoEqualTo(accountNo)
          .deleteFirst();
    });
  }

  /// Get current cash balance (sum of all cash accounts)
  Future<double> getCashBalance({String? companyId}) async {
    // Assuming cash accounts start with "1" (Assets) and have specific group
    final accounts = await getAll(companyId: companyId);
    // Filter for cash-type accounts based on your COA structure
    double total = 0.0;
    for (final a in accounts) {
      if (a.accountNo.startsWith('10') || a.title.toLowerCase().contains('cash')) {
        total += a.currentBalance;
      }
    }
    return total;
  }

  // ============================================================
  // MAPPERS
  // ============================================================

  AccountGroup _mapGroupFromPersistence(AccountGroupPersistence p) {
    return AccountGroup(
      id: p.id,
      name: p.name,
      type: _parseAccountType(p.type),
      parentGroupId: p.parentGroupId,
    );
  }

  AccountGroupPersistence _mapGroupToPersistence(AccountGroup g) {
    return AccountGroupPersistence()
      ..id = g.id
      ..name = g.name
      ..type = g.type.name
      ..parentGroupId = g.parentGroupId
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now()
      ..isSynced = false;
  }

  Account _mapFromPersistence(AccountPersistence p) {
    return Account(
      accountNo: p.accountNo,
      title: p.title,
      groupId: p.groupId,
      currentBalance: p.currentBalance,
      incentivePercent: p.incentivePercent,
      isPublic: p.isPublic,
      isActive: p.isActive,
      companyId: p.companyId,
    );
  }

  AccountPersistence _mapToPersistence(Account a) {
    return AccountPersistence()
      ..accountNo = a.accountNo
      ..title = a.title
      ..groupId = a.groupId
      ..currentBalance = a.currentBalance
      ..incentivePercent = a.incentivePercent
      ..isPublic = a.isPublic
      ..isActive = a.isActive
      ..companyId = a.companyId
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now()
      ..isSynced = false;
  }

  AccountType _parseAccountType(String type) {
    switch (type) {
      case 'asset':
        return AccountType.asset;
      case 'liability':
        return AccountType.liability;
      case 'equity':
        return AccountType.equity;
      case 'income':
        return AccountType.income;
      case 'expense':
        return AccountType.expense;
      default:
        return AccountType.asset;
    }
  }
}

/// Provider for AccountRepository
final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  final isarService = ref.watch(isarServiceProvider);
  return AccountRepository(isarService);
});
