/// Invoice and InvoiceLineItem models for sales, purchases, and returns
/// Supports IMEI tracking, split payments, and salesman attribution

enum InvoiceType {
  sale,
  purchase,
  saleReturn,
  purchaseReturn,
}

enum InvoiceStatus {
  draft,
  pending,
  confirmed,
  completed,
  cancelled,
}

enum InvoicePaymentMode {
  cash,
  bank,
  card,
  split,
  credit,
}

/// Summary of invoice financial values
class InvoiceSummary {
  final double grossValue;
  final double discount;
  final double discountPercent;
  final double tax;
  final double netValue;
  final double paidAmount;
  final double balance;

  const InvoiceSummary({
    this.grossValue = 0.0,
    this.discount = 0.0,
    this.discountPercent = 0.0,
    this.tax = 0.0,
    this.netValue = 0.0,
    this.paidAmount = 0.0,
    this.balance = 0.0,
  });

  InvoiceSummary copyWith({
    double? grossValue,
    double? discount,
    double? discountPercent,
    double? tax,
    double? netValue,
    double? paidAmount,
    double? balance,
  }) {
    return InvoiceSummary(
      grossValue: grossValue ?? this.grossValue,
      discount: discount ?? this.discount,
      discountPercent: discountPercent ?? this.discountPercent,
      tax: tax ?? this.tax,
      netValue: netValue ?? this.netValue,
      paidAmount: paidAmount ?? this.paidAmount,
      balance: balance ?? this.balance,
    );
  }
}

/// Split payment details
class SplitPayment {
  final double cashAmount;
  final double cardAmount;
  final String? cardBankAccountNo;
  final String? cardBankName;

  const SplitPayment({
    this.cashAmount = 0.0,
    this.cardAmount = 0.0,
    this.cardBankAccountNo,
    this.cardBankName,
  });

  double get total => cashAmount + cardAmount;
}

/// Main Invoice document
class Invoice {
  final String billNo;
  final InvoiceType type;
  final String partyId;
  final String partyName;
  final DateTime date;
  final InvoiceSummary summary;
  final InvoicePaymentMode paymentMode;
  final SplitPayment? splitPayment;
  final String? salesmanId;
  final String? salesmanName;
  final InvoiceStatus status;
  final String? companyId;
  final String? referenceNo;
  final String? notes;
  final DateTime createdAt;
  final String createdBy;
  final List<InvoiceLineItem> items;

  // Customer-specific fields
  final String? customerMobile;
  final String? customerCnic;
  final String? orderNo;

  // Return-specific fields
  final String? originalBillNo;
  final double? furtherDeductionPercent;

  const Invoice({
    required this.billNo,
    required this.type,
    required this.partyId,
    required this.partyName,
    required this.date,
    required this.summary,
    required this.paymentMode,
    this.splitPayment,
    this.salesmanId,
    this.salesmanName,
    this.status = InvoiceStatus.pending,
    this.companyId,
    this.referenceNo,
    this.notes,
    required this.createdAt,
    required this.createdBy,
    this.items = const [],
    this.customerMobile,
    this.customerCnic,
    this.orderNo,
    this.originalBillNo,
    this.furtherDeductionPercent,
  });

  /// Check if this is a sale-type invoice
  bool get isSale => type == InvoiceType.sale;

  /// Check if this is a purchase-type invoice
  bool get isPurchase => type == InvoiceType.purchase;

  /// Check if this is a return invoice
  bool get isReturn => 
      type == InvoiceType.saleReturn || type == InvoiceType.purchaseReturn;

  /// Total quantity of items
  int get totalQuantity => items.fold(0, (sum, item) => sum + item.quantity);

  /// Calculate profit for sale invoices
  double get profit {
    if (!isSale) return 0.0;
    return items.fold(0.0, (sum, item) => sum + item.profit);
  }

  Invoice copyWith({
    String? billNo,
    InvoiceType? type,
    String? partyId,
    String? partyName,
    DateTime? date,
    InvoiceSummary? summary,
    InvoicePaymentMode? paymentMode,
    SplitPayment? splitPayment,
    String? salesmanId,
    String? salesmanName,
    InvoiceStatus? status,
    String? companyId,
    String? referenceNo,
    String? notes,
    DateTime? createdAt,
    String? createdBy,
    List<InvoiceLineItem>? items,
    String? customerMobile,
    String? customerCnic,
    String? orderNo,
    String? originalBillNo,
    double? furtherDeductionPercent,
  }) {
    return Invoice(
      billNo: billNo ?? this.billNo,
      type: type ?? this.type,
      partyId: partyId ?? this.partyId,
      partyName: partyName ?? this.partyName,
      date: date ?? this.date,
      summary: summary ?? this.summary,
      paymentMode: paymentMode ?? this.paymentMode,
      splitPayment: splitPayment ?? this.splitPayment,
      salesmanId: salesmanId ?? this.salesmanId,
      salesmanName: salesmanName ?? this.salesmanName,
      status: status ?? this.status,
      companyId: companyId ?? this.companyId,
      referenceNo: referenceNo ?? this.referenceNo,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      items: items ?? this.items,
      customerMobile: customerMobile ?? this.customerMobile,
      customerCnic: customerCnic ?? this.customerCnic,
      orderNo: orderNo ?? this.orderNo,
      originalBillNo: originalBillNo ?? this.originalBillNo,
      furtherDeductionPercent: furtherDeductionPercent ?? this.furtherDeductionPercent,
    );
  }
}

/// Line item within an invoice
class InvoiceLineItem {
  final String id;
  final String invoiceId;
  final String productId;
  final String productName;
  final String? imei; // For IMEI-tracked items
  final double unitPrice;
  final double costPrice; // For profit calculation
  final int quantity;
  final double lineDiscount;
  final double lineTotal;
  final String? warranty;
  final String? color;
  final double? backupValue;
  final double? activationFee;

  const InvoiceLineItem({
    required this.id,
    required this.invoiceId,
    required this.productId,
    required this.productName,
    this.imei,
    required this.unitPrice,
    this.costPrice = 0.0,
    this.quantity = 1,
    this.lineDiscount = 0.0,
    required this.lineTotal,
    this.warranty,
    this.color,
    this.backupValue,
    this.activationFee,
  });

  /// Profit for this line item
  double get profit => (unitPrice - costPrice) * quantity - lineDiscount;

  /// Net price after discount
  double get netPrice => lineTotal;

  InvoiceLineItem copyWith({
    String? id,
    String? invoiceId,
    String? productId,
    String? productName,
    String? imei,
    double? unitPrice,
    double? costPrice,
    int? quantity,
    double? lineDiscount,
    double? lineTotal,
    String? warranty,
    String? color,
    double? backupValue,
    double? activationFee,
  }) {
    return InvoiceLineItem(
      id: id ?? this.id,
      invoiceId: invoiceId ?? this.invoiceId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      imei: imei ?? this.imei,
      unitPrice: unitPrice ?? this.unitPrice,
      costPrice: costPrice ?? this.costPrice,
      quantity: quantity ?? this.quantity,
      lineDiscount: lineDiscount ?? this.lineDiscount,
      lineTotal: lineTotal ?? this.lineTotal,
      warranty: warranty ?? this.warranty,
      color: color ?? this.color,
      backupValue: backupValue ?? this.backupValue,
      activationFee: activationFee ?? this.activationFee,
    );
  }
}

/// Sales Order (pre-invoice commitment)
class SalesOrder {
  final String orderNo;
  final String customerId;
  final String customerName;
  final DateTime date;
  final InvoiceSummary summary;
  final InvoiceStatus status;
  final String? salesmanId;
  final String? companyId;
  final String? notes;
  final DateTime createdAt;
  final List<InvoiceLineItem> items;

  const SalesOrder({
    required this.orderNo,
    required this.customerId,
    required this.customerName,
    required this.date,
    required this.summary,
    this.status = InvoiceStatus.pending,
    this.salesmanId,
    this.companyId,
    this.notes,
    required this.createdAt,
    this.items = const [],
  });

  bool get isConfirmed => status == InvoiceStatus.confirmed;

  SalesOrder copyWith({
    String? orderNo,
    String? customerId,
    String? customerName,
    DateTime? date,
    InvoiceSummary? summary,
    InvoiceStatus? status,
    String? salesmanId,
    String? companyId,
    String? notes,
    DateTime? createdAt,
    List<InvoiceLineItem>? items,
  }) {
    return SalesOrder(
      orderNo: orderNo ?? this.orderNo,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      date: date ?? this.date,
      summary: summary ?? this.summary,
      status: status ?? this.status,
      salesmanId: salesmanId ?? this.salesmanId,
      companyId: companyId ?? this.companyId,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      items: items ?? this.items,
    );
  }

  /// Convert this sales order to an invoice
  Invoice toInvoice({
    required String billNo,
    required InvoicePaymentMode paymentMode,
    required String createdBy,
  }) {
    return Invoice(
      billNo: billNo,
      type: InvoiceType.sale,
      partyId: customerId,
      partyName: customerName,
      date: DateTime.now(),
      summary: summary,
      paymentMode: paymentMode,
      salesmanId: salesmanId,
      status: InvoiceStatus.pending,
      companyId: companyId,
      notes: notes,
      createdAt: DateTime.now(),
      createdBy: createdBy,
      items: items.map((item) => item.copyWith(invoiceId: billNo)).toList(),
      orderNo: orderNo,
    );
  }
}
