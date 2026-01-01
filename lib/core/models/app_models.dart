import 'package:flutter/material.dart';

enum ProductCondition { new_, used, refurbished }

class Product {
  final String id;
  final String name;
  final String sku;
  final String? imei; // @deprecated - Use StockEntry.identifier instead
  final String category;
  final double purchasePrice;
  final double sellingPrice;
  final double? retailPrice; // Recommended retail price
  final int stock; // @deprecated - Calculate from StockLedger instead
  final ProductCondition condition;
  final String? brand;
  final String? variant;
  final int lowStockThreshold;
  final int minStockLevel; // Threshold for Demand List
  final String? supplierId;
  final bool isActive;
  final bool isSerialized; // TRUE for Mobiles (requires IMEI), FALSE for Accessories
  @Deprecated('Use isSerialized instead. isAccessory is the inverse of isSerialized.')
  final bool isAccessory; // @deprecated - Kept for backward compatibility
  final bool isBlocked; // If true, prevent new transactions
  final double? activationFee; // For mobile devices
  final String? companyId;
  final String? accountNo; // Linked GL account

  Product({
    required this.id,
    required this.name,
    required this.sku,
    this.imei,
    required this.category,
    required this.purchasePrice,
    required this.sellingPrice,
    this.retailPrice,
    this.stock = 0, // @deprecated
    this.condition = ProductCondition.new_,
    this.brand,
    this.variant,
    this.lowStockThreshold = 10,
    this.minStockLevel = 5,
    this.supplierId,
    this.isActive = true,
    this.isSerialized = true, // Default: requires IMEI tracking
    this.isAccessory = false, // @deprecated
    this.isBlocked = false,
    this.activationFee,
    this.companyId,
    this.accountNo,
  });

  /// Check if this product requires IMEI/Serial tracking
  bool get requiresImei => isSerialized;

  /// Check if stock is below minimum level
  /// @deprecated - Use StockLedgerRepository.getAvailableQuantity() instead
  bool get needsReorder => stock <= minStockLevel;

  Product copyWith({
    String? name,
    int? stock,
    double? sellingPrice,
    double? purchasePrice,
    double? retailPrice,
    int? lowStockThreshold,
    int? minStockLevel,
    String? supplierId,
    bool? isActive,
    bool? isSerialized,
    bool? isAccessory,
    bool? isBlocked,
    double? activationFee,
    String? companyId,
    String? accountNo,
  }) {
    return Product(
      id: id,
      name: name ?? this.name,
      sku: sku,
      imei: imei,
      category: category,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      retailPrice: retailPrice ?? this.retailPrice,
      stock: stock ?? this.stock,
      condition: condition,
      brand: brand,
      variant: variant,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      minStockLevel: minStockLevel ?? this.minStockLevel,
      supplierId: supplierId ?? this.supplierId,
      isActive: isActive ?? this.isActive,
      isSerialized: isSerialized ?? this.isSerialized,
      isAccessory: isAccessory ?? this.isAccessory,
      isBlocked: isBlocked ?? this.isBlocked,
      activationFee: activationFee ?? this.activationFee,
      companyId: companyId ?? this.companyId,
      accountNo: accountNo ?? this.accountNo,
    );
  }
}

class CartItem {
  final Product product;
  int quantity;
  final List<String> selectedImeis;

  CartItem({
    required this.product, 
    this.quantity = 1,
    this.selectedImeis = const [],
  });

  double get total => product.sellingPrice * quantity;
}

enum SaleStatus { completed, pending, cancelled }
enum PaymentMethod { cash, card, split, other }

class Sale {
  final String id;
  final List<CartItem> items;
  final double subtotal;
  final double discount;
  final double total;
  final DateTime timestamp;
  final SaleStatus status;
  final PaymentMethod paymentMethod;
  final String? customerId;
  final String? customerName;

  Sale({
    required this.id,
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.total,
    required this.timestamp,
    this.status = SaleStatus.completed,
    required this.paymentMethod,
    this.customerId,
    this.customerName,
  });
}

enum RepairStatus { received, inRepair, ready, delivered }

class RepairTicket {
  final String id;
  final String customerName;
  final String customerContact;
  final String deviceModel;
  final String issueDescription;
  final RepairStatus status;
  final double estimatedCost;
  final DateTime createdAt;
  final List<String> notes;

  final DateTime? expectedReturnDate;

  RepairTicket({
    required this.id,
    required this.customerName,
    required this.customerContact,
    required this.deviceModel,
    required this.issueDescription,
    required this.status,
    required this.estimatedCost,
    required this.createdAt,
    this.expectedReturnDate,
    this.notes = const [],
  });

  RepairTicket copyWith({
    RepairStatus? status, 
    List<String>? notes,
    DateTime? expectedReturnDate,
  }) {
    return RepairTicket(
      id: id,
      customerName: customerName,
      customerContact: customerContact,
      deviceModel: deviceModel,
      issueDescription: issueDescription,
      status: status ?? this.status,
      estimatedCost: estimatedCost,
      createdAt: createdAt,
      expectedReturnDate: expectedReturnDate ?? this.expectedReturnDate,
      notes: notes ?? this.notes,
    );
  }
}

class Customer {
  final String id;
  final String name;
  final String contact;
  final String? category; // e.g. "Repairing", "Standard", "Wholesale"
  final String? email;
  final String? address;
  final String? city;
  final String? taxId;
  final String? cnic; // National ID (CNIC No.)
  final bool isWholesale;
  final String? notes;
  final double balance;
  // Credit control fields
  final double debitLimit; // Maximum allowable debit balance
  final int agingLimit; // Maximum days for outstanding payments (0 = no limit)
  final int creditDays; // Standard payment terms
  final String? accountNo; // Linked GL account for sub-ledger
  final String? companyId;
  final bool isPublic; // Shared across all company branches

  Customer({
    required this.id,
    required this.name,
    required this.contact,
    this.category,
    this.email,
    this.address,
    this.city,
    this.taxId,
    this.cnic,
    this.isWholesale = false,
    this.notes,
    this.balance = 0,
    this.debitLimit = 0,
    this.agingLimit = 0,
    this.creditDays = 0,
    this.accountNo,
    this.companyId,
    this.isPublic = false,
  });

  /// Check if customer can take more credit
  bool get canTakeCredit => debitLimit == 0 || balance < debitLimit;

  /// Check if customer has exceeded debit limit
  bool get hasExceededDebitLimit => debitLimit > 0 && balance >= debitLimit;

  Customer copyWith({
    String? id,
    String? name,
    String? contact,
    String? category,
    String? email,
    String? address,
    String? city,
    String? taxId,
    String? cnic,
    bool? isWholesale,
    String? notes,
    double? balance,
    double? debitLimit,
    int? agingLimit,
    int? creditDays,
    String? accountNo,
    String? companyId,
    bool? isPublic,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      contact: contact ?? this.contact,
      category: category ?? this.category,
      email: email ?? this.email,
      address: address ?? this.address,
      city: city ?? this.city,
      taxId: taxId ?? this.taxId,
      cnic: cnic ?? this.cnic,
      isWholesale: isWholesale ?? this.isWholesale,
      notes: notes ?? this.notes,
      balance: balance ?? this.balance,
      debitLimit: debitLimit ?? this.debitLimit,
      agingLimit: agingLimit ?? this.agingLimit,
      creditDays: creditDays ?? this.creditDays,
      accountNo: accountNo ?? this.accountNo,
      companyId: companyId ?? this.companyId,
      isPublic: isPublic ?? this.isPublic,
    );
  }
}

enum ActivationChargeMode { onPurchase, onSale }

class Supplier {
  final String id;
  final String name;
  final String contact;
  final String company;
  final String? email;
  final String? address;
  final String? taxId;
  final String? paymentTerms;
  final String? notes;
  final bool isActive;
  final double balance;
  // Credit control fields
  final double debitLimit; // Maximum outstanding balance
  final int agingLimit; // Maximum days (0 = no limit)
  final int creditDays; // Standard payment terms
  final String? accountNo; // Linked GL account for sub-ledger
  final String? backupAccountNo; // Backup account for accounting
  final String? activationAccountNo; // Activation receivable account
  final ActivationChargeMode activationChargeMode; // When to charge activation
  final double cashIncentivePercent; // Automated rebate percentage
  final String? companyId;
  final bool isPublic; // Shared across all company branches

  Supplier({
    required this.id,
    required this.name,
    required this.contact,
    required this.company,
    this.email,
    this.address,
    this.taxId,
    this.paymentTerms,
    this.notes,
    this.isActive = true,
    this.balance = 0,
    this.debitLimit = 0,
    this.agingLimit = 0,
    this.creditDays = 0,
    this.accountNo,
    this.backupAccountNo,
    this.activationAccountNo,
    this.activationChargeMode = ActivationChargeMode.onPurchase,
    this.cashIncentivePercent = 0,
    this.companyId,
    this.isPublic = false,
  });

  Supplier copyWith({
    String? id,
    String? name,
    String? contact,
    String? company,
    String? email,
    String? address,
    String? taxId,
    String? paymentTerms,
    String? notes,
    bool? isActive,
    double? balance,
    double? debitLimit,
    int? agingLimit,
    int? creditDays,
    String? accountNo,
    String? backupAccountNo,
    String? activationAccountNo,
    ActivationChargeMode? activationChargeMode,
    double? cashIncentivePercent,
    String? companyId,
    bool? isPublic,
  }) {
    return Supplier(
      id: id ?? this.id,
      name: name ?? this.name,
      contact: contact ?? this.contact,
      company: company ?? this.company,
      email: email ?? this.email,
      address: address ?? this.address,
      taxId: taxId ?? this.taxId,
      paymentTerms: paymentTerms ?? this.paymentTerms,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      balance: balance ?? this.balance,
      debitLimit: debitLimit ?? this.debitLimit,
      agingLimit: agingLimit ?? this.agingLimit,
      creditDays: creditDays ?? this.creditDays,
      accountNo: accountNo ?? this.accountNo,
      backupAccountNo: backupAccountNo ?? this.backupAccountNo,
      activationAccountNo: activationAccountNo ?? this.activationAccountNo,
      activationChargeMode: activationChargeMode ?? this.activationChargeMode,
      cashIncentivePercent: cashIncentivePercent ?? this.cashIncentivePercent,
      companyId: companyId ?? this.companyId,
      isPublic: isPublic ?? this.isPublic,
    );
  }
}

class TaxRate {
  final String id;
  final String name;
  final double rate;
  final bool isDefault;

  TaxRate({required this.id, required this.name, required this.rate, this.isDefault = false});

  TaxRate copyWith({
    String? id,
    String? name,
    double? rate,
    bool? isDefault,
  }) {
    return TaxRate(
      id: id ?? this.id,
      name: name ?? this.name,
      rate: rate ?? this.rate,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}

class TransactionPaymentMethod {
  final String id;
  final String name;
  final String type; // cash, card, wallet, other
  final bool isEnabled;

  TransactionPaymentMethod({required this.id, required this.name, required this.type, this.isEnabled = true});

  TransactionPaymentMethod copyWith({
    String? id,
    String? name,
    String? type,
    bool? isEnabled,
  }) {
    return TransactionPaymentMethod(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }
}

class BusinessSettings {
  final String companyName;
  final String taxId;
  final String address;
  final String phone;
  final String email;
  final String currency;
  final String receiptHeader;
  final String receiptFooter;
  final List<TaxRate> taxRates;
  final List<TransactionPaymentMethod> paymentMethods;

  BusinessSettings({
    required this.companyName,
    this.taxId = '',
    this.address = '',
    this.phone = '',
    this.email = '',
    this.currency = 'PKR',
    this.receiptHeader = 'Thank you for shopping!',
    this.receiptFooter = 'No returns without receipt.',
    this.taxRates = const [],
    this.paymentMethods = const [],
  });

  BusinessSettings copyWith({
    String? companyName,
    String? taxId,
    String? address,
    String? phone,
    String? email,
    String? currency,
    String? receiptHeader,
    String? receiptFooter,
    List<TaxRate>? taxRates,
    List<TransactionPaymentMethod>? paymentMethods,
  }) {
    return BusinessSettings(
      companyName: companyName ?? this.companyName,
      taxId: taxId ?? this.taxId,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      currency: currency ?? this.currency,
      receiptHeader: receiptHeader ?? this.receiptHeader,
      receiptFooter: receiptFooter ?? this.receiptFooter,
      taxRates: taxRates ?? this.taxRates,
      paymentMethods: paymentMethods ?? this.paymentMethods,
    );
  }
}

enum ReturnStatus { pending, approved, rejected, completed }

class ReturnRequest {
  final String id;
  final String saleId;
  final String productId;
  final String productName;
  final String? customerName;
  final int quantity;
  final String reason;
  final String? reasonDetails;
  final String refundMethod;
  final double refundAmount;
  final ReturnStatus status;
  final DateTime createdAt;
  final DateTime? processedAt;

  ReturnRequest({
    required this.id,
    required this.saleId,
    required this.productId,
    required this.productName,
    this.customerName,
    required this.quantity,
    required this.reason,
    this.reasonDetails,
    required this.refundMethod,
    required this.refundAmount,
    this.status = ReturnStatus.pending,
    required this.createdAt,
    this.processedAt,
  });

  ReturnRequest copyWith({ReturnStatus? status, DateTime? processedAt}) {
    return ReturnRequest(
      id: id,
      saleId: saleId,
      productId: productId,
      productName: productName,
      customerName: customerName,
      quantity: quantity,
      reason: reason,
      reasonDetails: reasonDetails,
      refundMethod: refundMethod,
      refundAmount: refundAmount,
      status: status ?? this.status,
      createdAt: createdAt,
      processedAt: processedAt ?? this.processedAt,
    );
  }
}

class AppNotification {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final IconData? icon;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.icon,
  });

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      title: title,
      message: message,
      timestamp: timestamp,
      isRead: isRead ?? this.isRead,
      icon: icon,
    );
  }
}

enum PurchaseOrderStatus { draft, sent, confirmed, received, cancelled }

class PurchaseOrderItem {
  final String productId;
  final String productName;
  final int quantity;
  final double costPrice;
  final List<String>? imeis;

  PurchaseOrderItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.costPrice,
    this.imeis,
  });

  PurchaseOrderItem copyWith({
    String? productId,
    String? productName,
    int? quantity,
    double? costPrice,
    List<String>? imeis,
  }) {
    return PurchaseOrderItem(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      costPrice: costPrice ?? this.costPrice,
      imeis: imeis ?? this.imeis,
    );
  }
}

class PurchaseOrder {
  final String id;
  final String supplierId;
  final String supplierName;
  final List<PurchaseOrderItem> items;
  final double totalCost;
  final PurchaseOrderStatus status;
  final String? notes;
  final DateTime createdAt;
  final DateTime? receivedAt;

  PurchaseOrder({
    required this.id,
    required this.supplierId,
    required this.supplierName,
    required this.items,
    required this.totalCost,
    required this.status,
    this.notes,
    required this.createdAt,
    this.receivedAt,
  });

  PurchaseOrder copyWith({
    PurchaseOrderStatus? status,
    DateTime? receivedAt,
    List<PurchaseOrderItem>? items,
    double? totalCost,
  }) {
    return PurchaseOrder(
      id: id,
      supplierId: supplierId,
      supplierName: supplierName,
      items: items ?? this.items,
      totalCost: totalCost ?? this.totalCost,
      status: status ?? this.status,
      notes: notes,
      createdAt: createdAt,
      receivedAt: receivedAt ?? this.receivedAt,
    );
  }
}
