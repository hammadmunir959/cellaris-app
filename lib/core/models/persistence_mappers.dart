import 'dart:convert';
import 'package:mbm_app/core/models/app_models.dart';
import 'package:mbm_app/core/database/isar_schemas.dart';

extension ProductMapper on Product {
  ProductPersistence toPersistence({bool synced = false}) {
    return ProductPersistence()
      ..id = id
      ..name = name
      ..sku = sku
      ..imei = imei
      ..category = category
      ..purchasePrice = purchasePrice
      ..sellingPrice = sellingPrice
      ..stock = stock
      ..condition = condition.name
      ..brand = brand
      ..variant = variant
      ..lowStockThreshold = lowStockThreshold
      ..supplierId = supplierId
      ..isActive = isActive
      ..isSerialized = isSerialized
      ..isAccessory = isAccessory
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now()
      ..isSynced = synced;
  }
}

extension ProductPersistenceMapper on ProductPersistence {
  Product toDomain() {
    return Product(
      id: id,
      name: name,
      sku: sku,
      imei: imei,
      category: category,
      purchasePrice: purchasePrice,
      sellingPrice: sellingPrice,
      stock: stock,
      condition: ProductCondition.values.byName(condition),
      brand: brand,
      variant: variant,
      lowStockThreshold: lowStockThreshold,
      supplierId: supplierId,
      isActive: isActive,
      isSerialized: isSerialized,
      isAccessory: isAccessory,
    );
  }
}

extension CustomerMapper on Customer {
  CustomerPersistence toPersistence({bool synced = false}) {
    return CustomerPersistence()
      ..id = id
      ..name = name
      ..contact = contact
      ..email = email
      ..address = address
      ..city = city
      ..taxId = taxId
      ..cnic = cnic
      ..isWholesale = isWholesale
      ..notes = notes
      ..balance = balance
      ..debitLimit = debitLimit
      ..agingLimit = agingLimit
      ..creditDays = creditDays
      ..accountNo = accountNo
      ..companyId = companyId
      ..isPublic = isPublic
      ..category = category
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now()
      ..isSynced = synced;
  }
}

extension CustomerPersistenceMapper on CustomerPersistence {
  Customer toDomain() {
    return Customer(
      id: id,
      name: name,
      contact: contact,
      email: email,
      address: address,
      city: city,
      taxId: taxId,
      isWholesale: isWholesale,
      notes: notes,
      balance: balance,
      category: category,
    );
  }
}

extension SupplierMapper on Supplier {
  SupplierPersistence toPersistence({bool synced = false}) {
    return SupplierPersistence()
      ..id = id
      ..name = name
      ..contact = contact
      ..company = company
      ..email = email
      ..address = address
      ..taxId = taxId
      ..paymentTerms = paymentTerms
      ..notes = notes
      ..isActive = isActive
      ..balance = balance
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now()
      ..isSynced = synced;
  }
}

extension SupplierPersistenceMapper on SupplierPersistence {
  Supplier toDomain() {
    return Supplier(
      id: id,
      name: name,
      contact: contact,
      company: company,
      email: email,
      address: address,
      taxId: taxId,
      paymentTerms: paymentTerms,
      notes: notes,
      isActive: isActive,
      balance: balance,
    );
  }
}

extension POMapper on PurchaseOrder {
  PurchaseOrderPersistence toPersistence({bool synced = false}) {
    final itemsJson = jsonEncode(items.map((i) => {
      'productId': i.productId,
      'productName': i.productName,
      'quantity': i.quantity,
      'costPrice': i.costPrice,
      'imeis': i.imeis,
    }).toList());

    return PurchaseOrderPersistence()
      ..id = id
      ..supplierId = supplierId
      ..supplierName = supplierName
      ..itemsJson = itemsJson
      ..totalCost = totalCost
      ..status = status.name
      ..notes = notes
      ..createdAt = createdAt
      ..receivedAt = receivedAt
      ..updatedAt = DateTime.now()
      ..isSynced = synced;
  }
}

extension POPersistenceMapper on PurchaseOrderPersistence {
  PurchaseOrder toDomain() {
    final List<dynamic> itemsList = jsonDecode(itemsJson);
    final items = itemsList.map((i) => PurchaseOrderItem(
      productId: i['productId'] ?? '',
      productName: i['productName'] ?? '',
      quantity: i['quantity'] ?? 0,
      costPrice: (i['costPrice'] as num?)?.toDouble() ?? 0.0,
      imeis: (i['imeis'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
    )).toList();

    return PurchaseOrder(
      id: id,
      supplierId: supplierId,
      supplierName: supplierName,
      items: items,
      totalCost: totalCost,
      status: PurchaseOrderStatus.values.byName(status),
      notes: notes,
      createdAt: createdAt,
      receivedAt: receivedAt,
    );
  }
}

extension RepairTicketMapper on RepairTicket {
  RepairTicketPersistence toPersistence({bool synced = false}) {
    return RepairTicketPersistence()
      ..id = id
      ..customerName = customerName
      ..customerContact = customerContact
      ..deviceModel = deviceModel
      ..issueDescription = issueDescription
      ..status = status.name
      ..estimatedCost = estimatedCost
      ..createdAt = createdAt
      ..expectedReturnDate = expectedReturnDate
      ..notesJson = jsonEncode(notes)
      ..updatedAt = DateTime.now()
      ..isSynced = synced;
  }
}

extension RepairTicketPersistenceMapper on RepairTicketPersistence {
  RepairTicket toDomain() {
    final List<dynamic> notesList = jsonDecode(notesJson);
    final notes = notesList.map((e) => e.toString()).toList();

    return RepairTicket(
      id: id,
      customerName: customerName,
      customerContact: customerContact,
      deviceModel: deviceModel,
      issueDescription: issueDescription,
      status: RepairStatus.values.byName(status),
      estimatedCost: estimatedCost,
      createdAt: createdAt,
      expectedReturnDate: expectedReturnDate,
      notes: notes,
    );
  }
}

