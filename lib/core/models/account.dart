/// Account and AccountGroup models for Chart of Accounts
/// Supports hierarchical 6-digit COA structure (e.g., 404001)

enum AccountType { asset, liability, equity, income, expense }

/// Defines the classification of accounts for P&L and Trial Balance reporting
class AccountGroup {
  final int id;
  final String name;
  final AccountType type;
  final int? parentGroupId;

  const AccountGroup({
    required this.id,
    required this.name,
    required this.type,
    this.parentGroupId,
  });

  AccountGroup copyWith({
    int? id,
    String? name,
    AccountType? type,
    int? parentGroupId,
  }) {
    return AccountGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      parentGroupId: parentGroupId ?? this.parentGroupId,
    );
  }
}

/// Represents a double-entry ledger account in the Chart of Accounts
class Account {
  final String accountNo; // 6-digit hierarchical code (e.g., "301001")
  final String title;
  final int groupId;
  final double currentBalance;
  final double incentivePercent;
  final bool isPublic; // Shared across all company branches
  final bool isActive;
  final String? companyId;

  const Account({
    required this.accountNo,
    required this.title,
    required this.groupId,
    this.currentBalance = 0.0,
    this.incentivePercent = 0.0,
    this.isPublic = false,
    this.isActive = true,
    this.companyId,
  });

  /// Get the account level (1st, 2nd, or 3rd) based on the 6-digit structure
  int get level {
    if (accountNo.length < 2) return 1;
    final suffix = accountNo.substring(1);
    if (suffix.endsWith('0000')) return 1;
    if (suffix.endsWith('00')) return 2;
    return 3;
  }

  /// Alias for accountNo to satisfy generic interfaces
  String get id => accountNo;

  Account copyWith({
    String? accountNo,
    String? title,
    int? groupId,
    double? currentBalance,
    double? incentivePercent,
    bool? isPublic,
    bool? isActive,
    String? companyId,
  }) {
    return Account(
      accountNo: accountNo ?? this.accountNo,
      title: title ?? this.title,
      groupId: groupId ?? this.groupId,
      currentBalance: currentBalance ?? this.currentBalance,
      incentivePercent: incentivePercent ?? this.incentivePercent,
      isPublic: isPublic ?? this.isPublic,
      isActive: isActive ?? this.isActive,
      companyId: companyId ?? this.companyId,
    );
  }
}

/// Standard account groups for P&L statement mapping
class StandardAccountGroups {
  static const sales = AccountGroup(
    id: 1,
    name: 'Sales',
    type: AccountType.income,
  );
  static const costOfSales = AccountGroup(
    id: 3,
    name: 'Cost of Sales',
    type: AccountType.expense,
  );
  static const expenses = AccountGroup(
    id: 5,
    name: 'Expenses',
    type: AccountType.expense,
  );
  static const assets = AccountGroup(
    id: 10,
    name: 'Assets',
    type: AccountType.asset,
  );
  static const liabilities = AccountGroup(
    id: 20,
    name: 'Liabilities',
    type: AccountType.liability,
  );
  static const equity = AccountGroup(
    id: 30,
    name: 'Equity',
    type: AccountType.equity,
  );
}
