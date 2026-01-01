/// Voucher and LedgerEntry models for double-entry accounting
/// Supports Cash/Bank/Party vouchers and Journal Vouchers

enum VoucherType {
  cashPayment,
  cashReceipt,
  bankPayment,
  bankReceipt,
  partyPayment,
  partyReceipt,
  journalVoucher,
}

/// Represents an accounting voucher document
class Voucher {
  final String voucherNo;
  final VoucherType type;
  final DateTime date;
  final double totalAmount;
  final String? narration;
  final String? bankAccountNo; // For bank-based vouchers
  final String? bankName;
  final String? partyId; // For party-based vouchers
  final String? partyName;
  final String? companyId;
  final String createdBy;
  final DateTime createdAt;
  final bool isPosted;
  final List<LedgerEntry> entries;

  const Voucher({
    required this.voucherNo,
    required this.type,
    required this.date,
    required this.totalAmount,
    this.narration,
    this.bankAccountNo,
    this.bankName,
    this.partyId,
    this.partyName,
    this.companyId,
    required this.createdBy,
    required this.createdAt,
    this.isPosted = false,
    this.entries = const [],
  });

  /// User-friendly voucher type name
  String get typeName {
    switch (type) {
      case VoucherType.cashPayment:
        return 'Cash Payment Voucher';
      case VoucherType.cashReceipt:
        return 'Cash Received Voucher';
      case VoucherType.bankPayment:
        return 'Bank Payment Voucher';
      case VoucherType.bankReceipt:
        return 'Bank Received Voucher';
      case VoucherType.partyPayment:
        return 'Party Payment Voucher';
      case VoucherType.partyReceipt:
        return 'Party Receipt Voucher';
      case VoucherType.journalVoucher:
        return 'Journal Voucher';
    }
  }

  /// Check if voucher is balanced (Total Debit = Total Credit)
  bool get isBalanced {
    final totalDebit = entries.fold(0.0, (sum, e) => sum + e.debit);
    final totalCredit = entries.fold(0.0, (sum, e) => sum + e.credit);
    return (totalDebit - totalCredit).abs() < 0.01; // Allow small floating point diff
  }

  double get totalDebit => entries.fold(0.0, (sum, e) => sum + e.debit);
  double get totalCredit => entries.fold(0.0, (sum, e) => sum + e.credit);

  Voucher copyWith({
    String? voucherNo,
    VoucherType? type,
    DateTime? date,
    double? totalAmount,
    String? narration,
    String? bankAccountNo,
    String? bankName,
    String? partyId,
    String? partyName,
    String? companyId,
    String? createdBy,
    DateTime? createdAt,
    bool? isPosted,
    List<LedgerEntry>? entries,
  }) {
    return Voucher(
      voucherNo: voucherNo ?? this.voucherNo,
      type: type ?? this.type,
      date: date ?? this.date,
      totalAmount: totalAmount ?? this.totalAmount,
      narration: narration ?? this.narration,
      bankAccountNo: bankAccountNo ?? this.bankAccountNo,
      bankName: bankName ?? this.bankName,
      partyId: partyId ?? this.partyId,
      partyName: partyName ?? this.partyName,
      companyId: companyId ?? this.companyId,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      isPosted: isPosted ?? this.isPosted,
      entries: entries ?? this.entries,
    );
  }
}

/// The atomic unit of a double-entry transaction
class LedgerEntry {
  final String id;
  final String accountNo;
  final String accountName;
  final DateTime date;
  final double debit;
  final double credit;
  final String? particular; // Row-level description/narration
  final String? reference;
  final String sourceId; // Link to Voucher or Invoice
  final String sourceType; // 'voucher' or 'invoice'
  final String? companyId;
  final String? taxAccountNo; // For bank vouchers with tax withholding
  final double? taxAmount;

  const LedgerEntry({
    required this.id,
    required this.accountNo,
    required this.accountName,
    required this.date,
    this.debit = 0.0,
    this.credit = 0.0,
    this.particular,
    this.reference,
    required this.sourceId,
    required this.sourceType,
    this.companyId,
    this.taxAccountNo,
    this.taxAmount,
  });

  /// Net amount (positive for debit, negative for credit)
  double get netAmount => debit - credit;

  LedgerEntry copyWith({
    String? id,
    String? accountNo,
    String? accountName,
    DateTime? date,
    double? debit,
    double? credit,
    String? particular,
    String? reference,
    String? sourceId,
    String? sourceType,
    String? companyId,
    String? taxAccountNo,
    double? taxAmount,
  }) {
    return LedgerEntry(
      id: id ?? this.id,
      accountNo: accountNo ?? this.accountNo,
      accountName: accountName ?? this.accountName,
      date: date ?? this.date,
      debit: debit ?? this.debit,
      credit: credit ?? this.credit,
      particular: particular ?? this.particular,
      reference: reference ?? this.reference,
      sourceId: sourceId ?? this.sourceId,
      sourceType: sourceType ?? this.sourceType,
      companyId: companyId ?? this.companyId,
      taxAccountNo: taxAccountNo ?? this.taxAccountNo,
      taxAmount: taxAmount ?? this.taxAmount,
    );
  }
}

/// Helper for creating voucher entries
class VoucherBuilder {
  final VoucherType type;
  final DateTime date;
  final String createdBy;
  final List<LedgerEntry> _entries = [];
  String? narration;
  String? bankAccountNo;
  String? bankName;
  String? partyId;
  String? partyName;
  String? companyId;

  VoucherBuilder({
    required this.type,
    required this.date,
    required this.createdBy,
  });

  void addEntry({
    required String accountNo,
    required String accountName,
    double debit = 0.0,
    double credit = 0.0,
    String? particular,
    String? reference,
  }) {
    _entries.add(LedgerEntry(
      id: 'TEMP_${_entries.length}', // Will be replaced on save
      accountNo: accountNo,
      accountName: accountName,
      date: date,
      debit: debit,
      credit: credit,
      particular: particular,
      reference: reference,
      sourceId: '', // Will be set when voucher is saved
      sourceType: 'voucher',
      companyId: companyId,
    ));
  }

  bool get isBalanced {
    final totalDebit = _entries.fold(0.0, (sum, e) => sum + e.debit);
    final totalCredit = _entries.fold(0.0, (sum, e) => sum + e.credit);
    return (totalDebit - totalCredit).abs() < 0.01;
  }

  double get totalAmount {
    return _entries.fold(0.0, (sum, e) => sum + e.debit);
  }

  Voucher build(String voucherNo) {
    return Voucher(
      voucherNo: voucherNo,
      type: type,
      date: date,
      totalAmount: totalAmount,
      narration: narration,
      bankAccountNo: bankAccountNo,
      bankName: bankName,
      partyId: partyId,
      partyName: partyName,
      companyId: companyId,
      createdBy: createdBy,
      createdAt: DateTime.now(),
      entries: _entries.map((e) => e.copyWith(sourceId: voucherNo)).toList(),
    );
  }
}
