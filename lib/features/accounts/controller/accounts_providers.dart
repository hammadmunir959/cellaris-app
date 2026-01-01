import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/account.dart';
import '../../../core/models/voucher.dart';
import '../../../core/repositories/account_repository.dart';
import '../../../core/repositories/voucher_repository.dart';
import '../../../core/repositories/ledger_repository.dart';
import '../model/accounts_state.dart';

// ============================================================
// ACCOUNT PROVIDERS
// ============================================================

/// Provider for all account groups
final accountGroupsProvider = FutureProvider<List<AccountGroup>>((ref) async {
  final repository = ref.watch(accountRepositoryProvider);
  return repository.getAllGroups();
});

/// Provider for all accounts (with optional company filter)
final accountsProvider = FutureProvider.family<List<Account>, String?>((ref, companyId) async {
  final repository = ref.watch(accountRepositoryProvider);
  return repository.getAll(companyId: companyId);
});

/// Provider for accounts by level (1st, 2nd, 3rd level)
final accountsByLevelProvider = FutureProvider.family<List<Account>, int>((ref, level) async {
  final repository = ref.watch(accountRepositoryProvider);
  return repository.getByLevel(level);
});

/// Provider for accounts by group
final accountsByGroupProvider = FutureProvider.family<List<Account>, int>((ref, groupId) async {
  final repository = ref.watch(accountRepositoryProvider);
  return repository.getByGroup(groupId);
});

/// Provider for account search
final accountSearchProvider = FutureProvider.family<List<Account>, String>((ref, query) async {
  final repository = ref.watch(accountRepositoryProvider);
  return repository.search(query);
});

/// Provider for current cash balance
final cashBalanceProvider = FutureProvider.family<double, String?>((ref, companyId) async {
  final repository = ref.watch(accountRepositoryProvider);
  return repository.getCashBalance(companyId: companyId);
});

// ============================================================
// VOUCHER PROVIDERS
// ============================================================

/// Provider for vouchers list with filters
final vouchersProvider = FutureProvider.family<List<Voucher>, VoucherFilter>((ref, filter) async {
  final repository = ref.watch(voucherRepositoryProvider);
  return repository.getAll(
    companyId: filter.companyId,
    type: filter.type,
    fromDate: filter.fromDate,
    toDate: filter.toDate,
  );
});

/// Provider for a single voucher
final voucherProvider = FutureProvider.family<Voucher?, String>((ref, voucherNo) async {
  final repository = ref.watch(voucherRepositoryProvider);
  return repository.getByVoucherNo(voucherNo);
});

/// Provider for generating next voucher number
final nextVoucherNoProvider = FutureProvider.family<String, VoucherType>((ref, type) async {
  final repository = ref.watch(voucherRepositoryProvider);
  return repository.generateVoucherNo(type);
});

// ============================================================
// LEDGER & REPORT PROVIDERS
// ============================================================

/// Provider for account ledger entries
final accountLedgerProvider = FutureProvider.family<List<LedgerEntry>, LedgerFilter>((ref, filter) async {
  final repository = ref.watch(voucherRepositoryProvider);
  return repository.getEntriesForAccount(
    filter.accountNo,
    fromDate: filter.fromDate,
    toDate: filter.toDate,
  );
});

/// Provider for trial balance
final trialBalanceProvider = FutureProvider.family<Map<String, double>, TrialBalanceFilter>((ref, filter) async {
  final repository = ref.watch(ledgerRepositoryProvider);
  return repository.getTrialBalance(
    asOfDate: filter.asOfDate,
    companyId: filter.companyId,
  );
});

/// Provider for account summary (opening, debits, credits, closing)
final accountSummaryProvider = FutureProvider.family<AccountSummary, AccountSummaryFilter>((ref, filter) async {
  final repository = ref.watch(ledgerRepositoryProvider);
  return repository.getAccountSummary(
    filter.accountNo,
    fromDate: filter.fromDate,
    toDate: filter.toDate,
    companyId: filter.companyId,
  );
});

// ============================================================
// STATE NOTIFIER FOR VOUCHER FORM
// ============================================================

/// State notifier for managing voucher entry form
class VoucherFormNotifier extends StateNotifier<VoucherFormState> {
  final VoucherRepository _repository;

  VoucherFormNotifier(this._repository) : super(VoucherFormState.initial());

  void setType(VoucherType type) {
    state = state.copyWith(type: type);
  }

  void setDate(DateTime date) {
    state = state.copyWith(date: date);
  }

  void setNarration(String narration) {
    state = state.copyWith(narration: narration);
  }

  void setBankDetails({String? bankAccountNo, String? bankName}) {
    state = state.copyWith(bankAccountNo: bankAccountNo, bankName: bankName);
  }

  void setPartyDetails({String? partyId, String? partyName}) {
    state = state.copyWith(partyId: partyId, partyName: partyName);
  }

  void addEntry({
    required String accountNo,
    required String accountName,
    double debit = 0.0,
    double credit = 0.0,
    String? particular,
  }) {
    final newEntry = VoucherEntryLine(
      accountNo: accountNo,
      accountName: accountName,
      debit: debit,
      credit: credit,
      particular: particular,
    );
    state = state.copyWith(entries: [...state.entries, newEntry]);
  }

  void updateEntry(int index, VoucherEntryLine entry) {
    final entries = [...state.entries];
    entries[index] = entry;
    state = state.copyWith(entries: entries);
  }

  void removeEntry(int index) {
    final entries = [...state.entries];
    entries.removeAt(index);
    state = state.copyWith(entries: entries);
  }

  void clear() {
    state = VoucherFormState.initial();
  }

  Future<void> save(String createdBy, String? companyId) async {
    if (!state.isBalanced && state.type == VoucherType.journalVoucher) {
      throw Exception('Journal Voucher must be balanced');
    }

    state = state.copyWith(isSaving: true);

    try {
      final voucherNo = await _repository.generateVoucherNo(state.type);
      
      final builder = VoucherBuilder(
        type: state.type,
        date: state.date,
        createdBy: createdBy,
      )
        ..narration = state.narration
        ..bankAccountNo = state.bankAccountNo
        ..bankName = state.bankName
        ..partyId = state.partyId
        ..partyName = state.partyName
        ..companyId = companyId;

      for (final entry in state.entries) {
        builder.addEntry(
          accountNo: entry.accountNo,
          accountName: entry.accountName,
          debit: entry.debit,
          credit: entry.credit,
          particular: entry.particular,
        );
      }

      final voucher = builder.build(voucherNo);
      await _repository.save(voucher);

      state = state.copyWith(isSaving: false, savedVoucherNo: voucherNo);
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
      rethrow;
    }
  }
}

final voucherFormProvider = StateNotifierProvider.autoDispose<VoucherFormNotifier, VoucherFormState>((ref) {
  final repository = ref.watch(voucherRepositoryProvider);
  return VoucherFormNotifier(repository);
});

// ============================================================
// SELECTED ACCOUNT PROVIDER (for navigation)
// ============================================================

final selectedAccountProvider = StateProvider<Account?>((ref) => null);
final selectedVoucherTypeProvider = StateProvider<VoucherType?>((ref) => null);
