import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../database/isar_service.dart';
import '../database/isar_schemas.dart';
import '../models/invoice.dart';

/// Repository for Invoice and InvoiceLineItem operations
class InvoiceRepository {
  final IsarService _isarService;

  InvoiceRepository(this._isarService);

  Isar get _isar => _isarService.isar;

  // ============================================================
  // QUERY OPERATIONS
  // ============================================================

  /// Get all invoices
  Future<List<Invoice>> getAll({
    String? companyId,
    InvoiceType? type,
    InvoiceStatus? status,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    // Get all invoices first, then filter in Dart
    final allPersistence = await _isar.invoicePersistences.where().findAll();
    
    var persistence = allPersistence.where((p) {
      if (companyId != null && p.companyId != companyId) return false;
      if (type != null && p.type != type.name) return false;
      if (status != null && p.status != status.name) return false;
      if (fromDate != null && p.date.isBefore(fromDate)) return false;
      if (toDate != null && p.date.isAfter(toDate)) return false;
      return true;
    }).toList();

    // Sort by date descending
    persistence.sort((a, b) => b.date.compareTo(a.date));
    
    final invoices = <Invoice>[];
    for (final p in persistence) {
      final items = await _getItemsForInvoice(p.billNo);
      invoices.add(_mapFromPersistence(p, items));
    }
    return invoices;
  }

  /// Get invoice by bill number
  Future<Invoice?> getByBillNo(String billNo) async {
    final persistence = await _isar.invoicePersistences
        .filter()
        .billNoEqualTo(billNo)
        .findFirst();
    
    if (persistence == null) return null;
    
    final items = await _getItemsForInvoice(billNo);
    return _mapFromPersistence(persistence, items);
  }

  /// Get invoices by party
  Future<List<Invoice>> getByParty(String partyId, {InvoiceType? type}) async {
    var query = _isar.invoicePersistences.filter().partyIdEqualTo(partyId);
    
    if (type != null) {
      query = query.typeEqualTo(type.name);
    }

    final persistence = await query.sortByDateDesc().findAll();
    
    final invoices = <Invoice>[];
    for (final p in persistence) {
      final items = await _getItemsForInvoice(p.billNo);
      invoices.add(_mapFromPersistence(p, items));
    }
    return invoices;
  }

  /// Get invoices by salesman
  Future<List<Invoice>> getBySalesman(String salesmanId) async {
    final persistence = await _isar.invoicePersistences
        .filter()
        .salesmanIdEqualTo(salesmanId)
        .sortByDateDesc()
        .findAll();
    
    final invoices = <Invoice>[];
    for (final p in persistence) {
      final items = await _getItemsForInvoice(p.billNo);
      invoices.add(_mapFromPersistence(p, items));
    }
    return invoices;
  }

  Future<List<Invoice>> getTodaySales({String? companyId}) async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    return getAll(
      companyId: companyId,
      type: InvoiceType.sale,
      fromDate: startOfDay,
      toDate: endOfDay,
    );
  }

  /// Get recent sales (for dashboard)
  Future<List<Invoice>> getRecentSales({int limit = 5, String? companyId}) async {
    var query = _isar.invoicePersistences
        .filter()
        .typeEqualTo(InvoiceType.sale.name);
        
    if (companyId != null) {
      query = query.companyIdEqualTo(companyId);
    }

    final persistence = await query
        .sortByDateDesc()
        .limit(limit)
        .findAll();

    final invoices = <Invoice>[];
    for (final p in persistence) {
      final items = await _getItemsForInvoice(p.billNo);
      invoices.add(_mapFromPersistence(p, items));
    }
    return invoices;
  }

  /// Generate next bill number
  Future<String> generateBillNo(InvoiceType type) async {
    final prefix = _getBillPrefix(type);
    final count = await _isar.invoicePersistences
        .filter()
        .typeEqualTo(type.name)
        .count();
    final number = (count + 1).toString().padLeft(6, '0');
    return '$prefix$number';
  }

  // ============================================================
  // WRITE OPERATIONS
  // ============================================================

  /// Save invoice with line items
  Future<void> save(Invoice invoice) async {
    await _isar.writeTxn(() async {
      // Save invoice
      final invoicePersistence = _mapToPersistence(invoice);
      await _isar.invoicePersistences.put(invoicePersistence);

      // Save line items
      for (final item in invoice.items) {
        final itemPersistence = _mapItemToPersistence(item);
        await _isar.invoiceLineItemPersistences.put(itemPersistence);
      }
    });
  }

  /// Update invoice status
  Future<void> updateStatus(String billNo, InvoiceStatus status) async {
    await _isar.writeTxn(() async {
      final persistence = await _isar.invoicePersistences
          .filter()
          .billNoEqualTo(billNo)
          .findFirst();
      if (persistence != null) {
        persistence.status = status.name;
        persistence.updatedAt = DateTime.now();
        await _isar.invoicePersistences.put(persistence);
      }
    });
  }

  /// Delete invoice and its items
  Future<void> delete(String billNo) async {
    await _isar.writeTxn(() async {
      // Delete items first
      await _isar.invoiceLineItemPersistences
          .filter()
          .invoiceIdEqualTo(billNo)
          .deleteAll();
      
      // Delete invoice
      await _isar.invoicePersistences
          .filter()
          .billNoEqualTo(billNo)
          .deleteFirst();
    });
  }

  // ============================================================
  // STATISTICS
  // ============================================================

  /// Get today's total sales
  Future<double> getTodaysSalesTotal({String? companyId}) async {
    final sales = await getTodaySales(companyId: companyId);
    double total = 0.0;
    for (final inv in sales) {
      total += inv.summary.netValue;
    }
    return total;
  }

  /// Get total sales for date range
  Future<double> getSalesTotal({
    required DateTime fromDate,
    required DateTime toDate,
    String? companyId,
  }) async {
    final sales = await getAll(
      companyId: companyId,
      type: InvoiceType.sale,
      fromDate: fromDate,
      toDate: toDate,
    );
    double total = 0.0;
    for (final inv in sales) {
      total += inv.summary.netValue;
    }
    return total;
  }

  /// Get total profit for date range (sales only)
  Future<double> getProfit({
    required DateTime fromDate,
    required DateTime toDate,
    String? companyId,
  }) async {
    final sales = await getAll(
      companyId: companyId,
      type: InvoiceType.sale,
      fromDate: fromDate,
      toDate: toDate,
    );
    double total = 0.0;
    for (final inv in sales) {
      total += inv.profit;
    }
    return total;
  }

  // ============================================================
  // HELPERS
  // ============================================================

  Future<List<InvoiceLineItem>> _getItemsForInvoice(String billNo) async {
    final persistence = await _isar.invoiceLineItemPersistences
        .filter()
        .invoiceIdEqualTo(billNo)
        .findAll();
    return persistence.map(_mapItemFromPersistence).toList();
  }

  String _getBillPrefix(InvoiceType type) {
    switch (type) {
      case InvoiceType.sale:
        return 'SI-';
      case InvoiceType.purchase:
        return 'PI-';
      case InvoiceType.saleReturn:
        return 'SR-';
      case InvoiceType.purchaseReturn:
        return 'PR-';
    }
  }

  // ============================================================
  // MAPPERS
  // ============================================================

  Invoice _mapFromPersistence(InvoicePersistence p, List<InvoiceLineItem> items) {
    SplitPayment? splitPayment;
    if (p.splitPaymentJson != null) {
      final map = jsonDecode(p.splitPaymentJson!) as Map<String, dynamic>;
      splitPayment = SplitPayment(
        cashAmount: map['cashAmount'] as double? ?? 0,
        cardAmount: map['cardAmount'] as double? ?? 0,
        cardBankAccountNo: map['cardBankAccountNo'] as String?,
        cardBankName: map['cardBankName'] as String?,
      );
    }

    return Invoice(
      billNo: p.billNo,
      type: _parseInvoiceType(p.type),
      partyId: p.partyId,
      partyName: p.partyName,
      date: p.date,
      summary: InvoiceSummary(
        grossValue: p.grossValue,
        discount: p.discount,
        discountPercent: p.discountPercent,
        tax: p.tax,
        netValue: p.netValue,
        paidAmount: p.paidAmount,
        balance: p.balance,
      ),
      paymentMode: _parsePaymentMode(p.paymentMode),
      splitPayment: splitPayment,
      salesmanId: p.salesmanId,
      salesmanName: p.salesmanName,
      status: _parseInvoiceStatus(p.status),
      companyId: p.companyId,
      referenceNo: p.referenceNo,
      notes: p.notes,
      createdAt: p.createdAt,
      createdBy: p.createdBy,
      items: items,
      customerMobile: p.customerMobile,
      customerCnic: p.customerCnic,
      orderNo: p.orderNo,
      originalBillNo: p.originalBillNo,
      furtherDeductionPercent: p.furtherDeductionPercent,
    );
  }

  InvoicePersistence _mapToPersistence(Invoice i) {
    String? splitPaymentJson;
    if (i.splitPayment != null) {
      splitPaymentJson = jsonEncode({
        'cashAmount': i.splitPayment!.cashAmount,
        'cardAmount': i.splitPayment!.cardAmount,
        'cardBankAccountNo': i.splitPayment!.cardBankAccountNo,
        'cardBankName': i.splitPayment!.cardBankName,
      });
    }

    return InvoicePersistence()
      ..billNo = i.billNo
      ..type = i.type.name
      ..partyId = i.partyId
      ..partyName = i.partyName
      ..date = i.date
      ..grossValue = i.summary.grossValue
      ..discount = i.summary.discount
      ..discountPercent = i.summary.discountPercent
      ..tax = i.summary.tax
      ..netValue = i.summary.netValue
      ..paidAmount = i.summary.paidAmount
      ..balance = i.summary.balance
      ..paymentMode = i.paymentMode.name
      ..splitPaymentJson = splitPaymentJson
      ..salesmanId = i.salesmanId
      ..salesmanName = i.salesmanName
      ..status = i.status.name
      ..companyId = i.companyId
      ..referenceNo = i.referenceNo
      ..notes = i.notes
      ..createdAt = i.createdAt
      ..createdBy = i.createdBy
      ..customerMobile = i.customerMobile
      ..customerCnic = i.customerCnic
      ..orderNo = i.orderNo
      ..originalBillNo = i.originalBillNo
      ..furtherDeductionPercent = i.furtherDeductionPercent
      ..updatedAt = DateTime.now()
      ..isSynced = false;
  }

  InvoiceLineItem _mapItemFromPersistence(InvoiceLineItemPersistence p) {
    return InvoiceLineItem(
      id: p.id,
      invoiceId: p.invoiceId,
      productId: p.productId,
      productName: p.productName,
      imei: p.imei,
      unitPrice: p.unitPrice,
      costPrice: p.costPrice,
      quantity: p.quantity,
      lineDiscount: p.lineDiscount,
      lineTotal: p.lineTotal,
      warranty: p.warranty,
      color: p.color,
      backupValue: p.backupValue,
      activationFee: p.activationFee,
    );
  }

  InvoiceLineItemPersistence _mapItemToPersistence(InvoiceLineItem i) {
    return InvoiceLineItemPersistence()
      ..id = i.id
      ..invoiceId = i.invoiceId
      ..productId = i.productId
      ..productName = i.productName
      ..imei = i.imei
      ..unitPrice = i.unitPrice
      ..costPrice = i.costPrice
      ..quantity = i.quantity
      ..lineDiscount = i.lineDiscount
      ..lineTotal = i.lineTotal
      ..warranty = i.warranty
      ..color = i.color
      ..backupValue = i.backupValue
      ..activationFee = i.activationFee
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now()
      ..isSynced = false;
  }

  InvoiceType _parseInvoiceType(String type) {
    switch (type) {
      case 'sale':
        return InvoiceType.sale;
      case 'purchase':
        return InvoiceType.purchase;
      case 'saleReturn':
        return InvoiceType.saleReturn;
      case 'purchaseReturn':
        return InvoiceType.purchaseReturn;
      default:
        return InvoiceType.sale;
    }
  }

  InvoiceStatus _parseInvoiceStatus(String status) {
    switch (status) {
      case 'draft':
        return InvoiceStatus.draft;
      case 'pending':
        return InvoiceStatus.pending;
      case 'confirmed':
        return InvoiceStatus.confirmed;
      case 'completed':
        return InvoiceStatus.completed;
      case 'cancelled':
        return InvoiceStatus.cancelled;
      default:
        return InvoiceStatus.pending;
    }
  }

  InvoicePaymentMode _parsePaymentMode(String mode) {
    switch (mode) {
      case 'cash':
        return InvoicePaymentMode.cash;
      case 'bank':
        return InvoicePaymentMode.bank;
      case 'card':
        return InvoicePaymentMode.card;
      case 'split':
        return InvoicePaymentMode.split;
      case 'credit':
        return InvoicePaymentMode.credit;
      default:
        return InvoicePaymentMode.cash;
    }
  }
}

/// Provider for InvoiceRepository
final invoiceRepositoryProvider = Provider<InvoiceRepository>((ref) {
  final isarService = ref.watch(isarServiceProvider);
  return InvoiceRepository(isarService);
});
