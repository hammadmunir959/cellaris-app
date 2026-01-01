import '../../../core/models/voucher.dart';

// ============================================================
// FILTER MODELS
// ============================================================

/// Filter for voucher queries
class VoucherFilter {
  final String? companyId;
  final VoucherType? type;
  final DateTime? fromDate;
  final DateTime? toDate;

  const VoucherFilter({
    this.companyId,
    this.type,
    this.fromDate,
    this.toDate,
  });

  VoucherFilter copyWith({
    String? companyId,
    VoucherType? type,
    DateTime? fromDate,
    DateTime? toDate,
  }) {
    return VoucherFilter(
      companyId: companyId ?? this.companyId,
      type: type ?? this.type,
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
    );
  }
}

/// Filter for ledger queries
class LedgerFilter {
  final String accountNo;
  final DateTime? fromDate;
  final DateTime? toDate;
  final String? companyId;

  const LedgerFilter({
    required this.accountNo,
    this.fromDate,
    this.toDate,
    this.companyId,
  });
}

/// Filter for trial balance
class TrialBalanceFilter {
  final DateTime? asOfDate;
  final String? companyId;
  final int? level; // 1, 2, or 3

  const TrialBalanceFilter({
    this.asOfDate,
    this.companyId,
    this.level,
  });
}

/// Filter for account summary
class AccountSummaryFilter {
  final String accountNo;
  final DateTime fromDate;
  final DateTime toDate;
  final String? companyId;

  const AccountSummaryFilter({
    required this.accountNo,
    required this.fromDate,
    required this.toDate,
    this.companyId,
  });
}

// ============================================================
// VOUCHER FORM STATE
// ============================================================

/// Single line entry in a voucher form
class VoucherEntryLine {
  final String accountNo;
  final String accountName;
  final double debit;
  final double credit;
  final String? particular;

  const VoucherEntryLine({
    required this.accountNo,
    required this.accountName,
    this.debit = 0.0,
    this.credit = 0.0,
    this.particular,
  });

  VoucherEntryLine copyWith({
    String? accountNo,
    String? accountName,
    double? debit,
    double? credit,
    String? particular,
  }) {
    return VoucherEntryLine(
      accountNo: accountNo ?? this.accountNo,
      accountName: accountName ?? this.accountName,
      debit: debit ?? this.debit,
      credit: credit ?? this.credit,
      particular: particular ?? this.particular,
    );
  }
}

/// State for voucher entry form
class VoucherFormState {
  final VoucherType type;
  final DateTime date;
  final String? narration;
  final String? bankAccountNo;
  final String? bankName;
  final String? partyId;
  final String? partyName;
  final List<VoucherEntryLine> entries;
  final bool isSaving;
  final String? error;
  final String? savedVoucherNo;

  const VoucherFormState({
    required this.type,
    required this.date,
    this.narration,
    this.bankAccountNo,
    this.bankName,
    this.partyId,
    this.partyName,
    this.entries = const [],
    this.isSaving = false,
    this.error,
    this.savedVoucherNo,
  });

  factory VoucherFormState.initial() {
    return VoucherFormState(
      type: VoucherType.cashPayment,
      date: DateTime.now(),
      entries: [],
    );
  }

  double get totalDebit => entries.fold(0.0, (sum, e) => sum + e.debit);
  double get totalCredit => entries.fold(0.0, (sum, e) => sum + e.credit);
  bool get isBalanced => (totalDebit - totalCredit).abs() < 0.01;
  double get totalAmount => totalDebit;

  VoucherFormState copyWith({
    VoucherType? type,
    DateTime? date,
    String? narration,
    String? bankAccountNo,
    String? bankName,
    String? partyId,
    String? partyName,
    List<VoucherEntryLine>? entries,
    bool? isSaving,
    String? error,
    String? savedVoucherNo,
  }) {
    return VoucherFormState(
      type: type ?? this.type,
      date: date ?? this.date,
      narration: narration ?? this.narration,
      bankAccountNo: bankAccountNo ?? this.bankAccountNo,
      bankName: bankName ?? this.bankName,
      partyId: partyId ?? this.partyId,
      partyName: partyName ?? this.partyName,
      entries: entries ?? this.entries,
      isSaving: isSaving ?? this.isSaving,
      error: error,
      savedVoucherNo: savedVoucherNo,
    );
  }
}

// ============================================================
// ACCOUNTS MODULE VIEW STATE
// ============================================================

enum AccountsViewMode {
  chartOfAccounts,
  vouchers,
  reports,
}

enum ReportType {
  accountLedger,
  trialBalance,
  profitLoss,
  agingReceivables,
  agingPayables,
}

class AccountsViewState {
  final AccountsViewMode mode;
  final ReportType? selectedReport;
  final DateTime fromDate;
  final DateTime toDate;
  final String? selectedCompanyId;

  const AccountsViewState({
    this.mode = AccountsViewMode.chartOfAccounts,
    this.selectedReport,
    required this.fromDate,
    required this.toDate,
    this.selectedCompanyId,
  });

  factory AccountsViewState.initial() {
    final now = DateTime.now();
    return AccountsViewState(
      fromDate: DateTime(now.year, now.month, 1),
      toDate: now,
    );
  }

  AccountsViewState copyWith({
    AccountsViewMode? mode,
    ReportType? selectedReport,
    DateTime? fromDate,
    DateTime? toDate,
    String? selectedCompanyId,
  }) {
    return AccountsViewState(
      mode: mode ?? this.mode,
      selectedReport: selectedReport ?? this.selectedReport,
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
      selectedCompanyId: selectedCompanyId ?? this.selectedCompanyId,
    );
  }
}
