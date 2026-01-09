import 'package:isar_community/isar.dart';

export 'local_control_state.dart';

part 'isar_schemas.g.dart';

@collection
class ProductPersistence {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String id;

  @Index(type: IndexType.value)
  late String name;

  @Index(unique: true)
  late String sku;

  @Index(type: IndexType.value)
  String? imei; // @deprecated - Use StockEntryPersistence.identifier

  @Index()
  late String category;

  late double purchasePrice;
  late double sellingPrice;
  double? retailPrice;
  late int stock; // @deprecated - Calculate from StockEntryPersistence
  late String condition;
  String? brand;
  String? variant;
  int lowStockThreshold = 0;
  int minStockLevel = 0;
  String? supplierId;
  late bool isActive;
  bool isSerialized = true; // TRUE for mobiles (requires IMEI), FALSE for accessories
  bool isAccessory = false; // @deprecated - Kept for backward compatibility
  bool isBlocked = false;
  double? activationFee;
  String? companyId;
  String? accountNo;

  late DateTime createdAt;
  late DateTime updatedAt;

  @Index()
  late bool isSynced;
}

/// Unified Stock Ledger - tracks both serialized and non-serialized inventory
/// For Mobiles: Each row = one device with unique IMEI (quantity = 1)
/// For Accessories: Each row = a batch of items (quantity = N)
@collection
class StockEntryPersistence {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String stockId; // Unique ID for this stock entry

  @Index()
  late String productId; // FK to ProductPersistence

  @Index(type: IndexType.value)
  String? identifier; // IMEI for serialized, BatchID for non-serialized

  late double quantity; // Always 1 for serialized, N for non-serialized
  late double purchasePrice; // Landed cost per unit (essential for P&L)
  String? locationId; // Warehouse, Shop Floor, or Bin

  @Index()
  late String status; // available, sold, reserved, returned

  String? purchaseBillNo; // Origin purchase invoice
  String? saleBillNo; // Destination sale invoice (null if not sold)
  DateTime? purchaseDate;
  DateTime? saleDate;
  double? soldPrice; // Actual sale price per unit
  String? color;
  String? warranty;
  String? activationStatus;
  String? companyId;
  String? notes;

  late DateTime createdAt;
  late DateTime updatedAt;
  @Index()
  late bool isSynced;
}

@collection
class CustomerPersistence {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String id;

  @Index(type: IndexType.value)
  late String name;

  @Index()
  late String contact;

  @Index()
  String? category;

  String? email;
  String? address;
  String? city;
  String? taxId;
  String? cnic;
  late bool isWholesale;
  String? notes;
  late double balance;
  late double debitLimit;
  late int agingLimit;
  late int creditDays;
  String? accountNo;
  String? companyId;
  late bool isPublic;

  late DateTime createdAt;
  late DateTime updatedAt;

  @Index()
  late bool isSynced;
}

@collection
class SaleDraftPersistence {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String id;

  late String itemsJson; 
  late double subtotal;
  late double discount;
  late double total;
  late DateTime timestamp;
  late String status;
  late String paymentMethod;
  String? customerId;
  String? customerName;

  late DateTime createdAt;
  late DateTime updatedAt;
  @Index()
  late bool isSynced;
}

@collection
class SupplierPersistence {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String id;

  @Index(type: IndexType.value)
  late String name;

  late String contact;

  @Index(type: IndexType.value)
  late String company;

  String? email;
  String? address;
  String? taxId;
  String? paymentTerms;
  String? notes;
  late bool isActive;
  late double balance;
  late double debitLimit;
  late int agingLimit;
  late int creditDays;
  String? accountNo;
  String? backupAccountNo;
  String? activationAccountNo;
  late String activationChargeMode;
  late double cashIncentivePercent;
  String? companyId;
  late bool isPublic;

  late DateTime createdAt;
  late DateTime updatedAt;

  @Index()
  late bool isSynced;
}

@collection
class PurchaseOrderPersistence {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String id;

  @Index()
  late String supplierId;

  late String supplierName;
  late String itemsJson;
  late double totalCost;

  @Index()
  late String status;

  String? notes;

  @Index()
  late DateTime createdAt;

  DateTime? receivedAt;

  late DateTime updatedAt;

  @Index()
  late bool isSynced;
}

// ============================================================
// NEW SCHEMAS FOR PHASE 1.2
// ============================================================

@collection
class AccountGroupPersistence {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late int id;

  late String name;
  late String type; // asset, liability, equity, income, expense
  int? parentGroupId;

  late DateTime createdAt;
  late DateTime updatedAt;
  @Index()
  late bool isSynced;
}

@collection
class AccountPersistence {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String accountNo; // 6-digit hierarchical code

  @Index(type: IndexType.value)
  late String title;

  @Index()
  late int groupId;

  late double currentBalance;
  late double incentivePercent;
  late bool isPublic;
  late bool isActive;
  String? companyId;

  late DateTime createdAt;
  late DateTime updatedAt;
  @Index()
  late bool isSynced;
}

@collection
class UnitPersistence {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String imei; // Primary key - unique serial number

  @Index()
  late String productId;

  late String color;
  String? locationId;

  @Index()
  late String status; // inStock, issued, sold, returned

  String? purchaseBillNo;
  String? saleBillNo;
  double? purchasePrice;
  double? soldPrice;
  DateTime? purchaseDate;
  DateTime? saleDate;
  String? warranty;
  String? activationStatus;
  String? companyId;
  String? notes;

  late DateTime createdAt;
  late DateTime updatedAt;
  @Index()
  late bool isSynced;
}

@collection
class VoucherPersistence {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String voucherNo;

  @Index()
  late String type; // cashPayment, cashReceipt, bankPayment, etc.

  @Index()
  late DateTime date;

  late double totalAmount;
  String? narration;
  String? bankAccountNo;
  String? bankName;
  String? partyId;
  String? partyName;
  String? companyId;
  late String createdBy;
  late DateTime createdAt;
  late bool isPosted;

  late DateTime updatedAt;
  @Index()
  late bool isSynced;
}

@collection
class LedgerEntryPersistence {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String id;

  @Index()
  late String accountNo;

  late String accountName;

  @Index()
  late DateTime date;

  late double debit;
  late double credit;
  String? particular;
  String? reference;

  @Index()
  late String sourceId; // Voucher or Invoice ID

  late String sourceType; // 'voucher' or 'invoice'
  String? companyId;
  String? taxAccountNo;
  double? taxAmount;

  late DateTime createdAt;
  late DateTime updatedAt;
  @Index()
  late bool isSynced;
}

@collection
class InvoicePersistence {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String billNo;

  @Index()
  late String type; // sale, purchase, saleReturn, purchaseReturn

  @Index()
  late String partyId;

  late String partyName;

  @Index()
  late DateTime date;

  // Summary fields stored as separate fields
  late double grossValue;
  late double discount;
  late double discountPercent;
  late double tax;
  late double netValue;
  late double paidAmount;
  late double balance;

  late String paymentMode; // cash, bank, card, split, credit
  String? splitPaymentJson; // JSON for split payment details

  String? salesmanId;
  String? salesmanName;

  @Index()
  late String status; // draft, pending, confirmed, completed, cancelled

  String? companyId;
  String? referenceNo;
  String? notes;
  late DateTime createdAt;
  late String createdBy;

  // Customer-specific fields
  String? customerMobile;
  String? customerCnic;
  String? orderNo;

  // Return-specific fields
  String? originalBillNo;
  double? furtherDeductionPercent;

  late DateTime updatedAt;
  @Index()
  late bool isSynced;
}

@collection
class InvoiceLineItemPersistence {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String id;

  @Index()
  late String invoiceId;

  @Index()
  late String productId;

  late String productName;

  @Index(type: IndexType.value)
  String? imei;

  late double unitPrice;
  late double costPrice;
  late int quantity;
  late double lineDiscount;
  late double lineTotal;
  String? warranty;
  String? color;
  double? backupValue;
  double? activationFee;

  late DateTime createdAt;
  late DateTime updatedAt;
  @Index()
  late bool isSynced;
}

@collection
class CompanyPersistence {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String id;

  @Index(type: IndexType.value)
  late String name;

  String? code;
  String? address;
  String? phone;
  String? email;
  String? taxId;
  late bool isHeadOffice;
  late bool isActive;
  String? parentCompanyId;

  late DateTime createdAt;
  late DateTime updatedAt;
  @Index()
  late bool isSynced;
}

@collection
class LocationPersistence {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String id;

  @Index(type: IndexType.value)
  late String name;

  String? code;
  late String type; // warehouse, shopFloor, bin, shelf, other
  String? companyId;
  String? parentLocationId;
  String? address;
  late bool isActive;

  late DateTime createdAt;
  late DateTime updatedAt;
  @Index()
  late bool isSynced;
}

@collection
class SalesmanPersistence {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String id;

  @Index(type: IndexType.value)
  late String name;

  String? contact;
  String? email;
  late double commissionPercent;
  String? companyId;
  late bool isActive;

  late DateTime createdAt;
  late DateTime updatedAt;
  @Index()
  late bool isSynced;
}

@collection
class RepairTicketPersistence {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String id;

  @Index(type: IndexType.value)
  late String customerName;

  @Index()
  late String customerContact;

  late String deviceModel;
  late String issueDescription;

  @Index()
  late String status; // received, inRepair, ready, delivered

  late double estimatedCost;
  
  @Index()
  late DateTime createdAt;

  DateTime? expectedReturnDate;

  late String notesJson; // List<String> encoded as JSON

  late DateTime updatedAt;

  @Index()
  late bool isSynced;
}

