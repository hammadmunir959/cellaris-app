import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/models/app_models.dart';
import '../../../core/models/invoice.dart';
import '../../../core/repositories/invoice_repository.dart';
import '../../../core/repositories/unit_repository.dart';
import '../../inventory/controller/inventory_controller.dart';

// ============================================================
// SALES MODE
// ============================================================

/// Mode toggle for unified sales screen
enum SalesMode {
  directSale,  // Immediate payment, creates Invoice
  createOrder, // No payment, creates Order (Pending/Confirmed)
}

extension SalesModeExtension on SalesMode {
  String get label => this == SalesMode.directSale ? 'Direct Sale' : 'Create Order';
  String get icon => this == SalesMode.directSale ? '⚡' : '📋';
  String get description => this == SalesMode.directSale 
    ? 'Instant checkout with payment' 
    : 'Save as order for later fulfillment';
}

// ============================================================
// ORDER STATUS (for Create Order mode)
// ============================================================

enum SaleOrderStatus {
  pending,
  confirmed,
  invoiced,
  cancelled,
}

extension SaleOrderStatusExtension on SaleOrderStatus {
  String get label {
    switch (this) {
      case SaleOrderStatus.pending: return 'Pending';
      case SaleOrderStatus.confirmed: return 'Confirmed';
      case SaleOrderStatus.invoiced: return 'Invoiced';
      case SaleOrderStatus.cancelled: return 'Cancelled';
    }
  }
}

// ============================================================
// CART ITEM (shared between modes)
// ============================================================

class SalesCartItem {
  final Product product;
  final int quantity;
  final List<String> imeis;
  final double lineDiscount;

  const SalesCartItem({
    required this.product,
    this.quantity = 1,
    this.imeis = const [],
    this.lineDiscount = 0.0,
  });

  double get unitPrice => product.sellingPrice;
  double get costPrice => product.purchasePrice;
  double get lineTotal => (unitPrice * quantity) - lineDiscount;
  double get profit => (unitPrice - costPrice) * quantity - lineDiscount;

  SalesCartItem copyWith({
    Product? product,
    int? quantity,
    List<String>? imeis,
    double? lineDiscount,
  }) {
    return SalesCartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      imeis: imeis ?? this.imeis,
      lineDiscount: lineDiscount ?? this.lineDiscount,
    );
  }
}

// ============================================================
// SPLIT PAYMENT
// ============================================================

class SplitPaymentInfo {
  final double cashAmount;
  final double cardAmount;
  final String? bankAccountNo;
  final String? bankName;

  const SplitPaymentInfo({
    this.cashAmount = 0.0,
    this.cardAmount = 0.0,
    this.bankAccountNo,
    this.bankName,
  });

  double get total => cashAmount + cardAmount;

  SplitPaymentInfo copyWith({
    double? cashAmount,
    double? cardAmount,
    String? bankAccountNo,
    String? bankName,
  }) {
    return SplitPaymentInfo(
      cashAmount: cashAmount ?? this.cashAmount,
      cardAmount: cardAmount ?? this.cardAmount,
      bankAccountNo: bankAccountNo ?? this.bankAccountNo,
      bankName: bankName ?? this.bankName,
    );
  }
}

// ============================================================
// HELD ORDER (for parking transactions)
// ============================================================

class HeldOrder {
  final String id;
  final String? customerName;
  final List<SalesCartItem> items;
  final DateTime heldAt;
  final String? note;

  const HeldOrder({
    required this.id,
    this.customerName,
    required this.items,
    required this.heldAt,
    this.note,
  });

  double get total => items.fold(0.0, (sum, item) => sum + item.lineTotal);
  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);
}

// ============================================================
// UNIFIED SALES STATE
// ============================================================

class UnifiedSalesState {
  // Mode
  final SalesMode mode;
  
  // Cart items (shared)
  final List<SalesCartItem> items;
  
  // Customer info
  final Customer? selectedCustomer;
  final String? walkInName;      // For walk-in customers
  final String? walkInPhone;     // For walk-in customers
  final bool isWholesale;        // Default false (retail)
  
  // Salesman
  final String? salesmanId;
  final String? salesmanName;
  
  // Discount
  final double discount;
  final bool isPercentageDiscount;
  
  // Notes
  final String? note;
  
  // Payment (Direct Sale mode only)
  final PaymentMethod paymentMethod;
  final SplitPaymentInfo? splitPayment;
  
  // Order status (Create Order mode only)
  final SaleOrderStatus orderStatus;
  
  // Held orders
  final Map<String, HeldOrder> heldOrders;
  
  // UI state
  final bool isProcessing;
  final String? lastBillNo;
  final String? lastOrderNo;

  const UnifiedSalesState({
    this.mode = SalesMode.directSale,
    this.items = const [],
    this.selectedCustomer,
    this.walkInName,
    this.walkInPhone,
    this.isWholesale = false,
    this.salesmanId,
    this.salesmanName,
    this.discount = 0.0,
    this.isPercentageDiscount = false,
    this.note,
    this.paymentMethod = PaymentMethod.cash,
    this.splitPayment,
    this.orderStatus = SaleOrderStatus.pending,
    this.heldOrders = const {},
    this.isProcessing = false,
    this.lastBillNo,
    this.lastOrderNo,
  });

  // Calculations
  double get subtotal => items.fold(0.0, (sum, item) => sum + item.lineTotal);
  double get totalProfit => items.fold(0.0, (sum, item) => sum + item.profit);
  
  double get discountAmount {
    if (isPercentageDiscount) {
      return subtotal * (discount / 100);
    }
    return discount;
  }

  double get total => subtotal - discountAmount;
  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);
  bool get isSplitPayment => paymentMethod == PaymentMethod.split;
  bool get isDirectSale => mode == SalesMode.directSale;
  bool get isCreateOrder => mode == SalesMode.createOrder;
  bool get hasItems => items.isNotEmpty;

  UnifiedSalesState copyWith({
    SalesMode? mode,
    List<SalesCartItem>? items,
    Customer? selectedCustomer,
    String? walkInName,
    String? walkInPhone,
    bool? isWholesale,
    String? salesmanId,
    String? salesmanName,
    double? discount,
    bool? isPercentageDiscount,
    String? note,
    PaymentMethod? paymentMethod,
    SplitPaymentInfo? splitPayment,
    SaleOrderStatus? orderStatus,
    Map<String, HeldOrder>? heldOrders,
    bool? isProcessing,
    String? lastBillNo,
    String? lastOrderNo,
    bool clearCustomer = false,
    bool clearSalesman = false,
  }) {
    return UnifiedSalesState(
      mode: mode ?? this.mode,
      items: items ?? this.items,
      selectedCustomer: clearCustomer ? null : (selectedCustomer ?? this.selectedCustomer),
      walkInName: clearCustomer ? null : (walkInName ?? this.walkInName),
      walkInPhone: clearCustomer ? null : (walkInPhone ?? this.walkInPhone),
      isWholesale: isWholesale ?? this.isWholesale,
      salesmanId: clearSalesman ? null : (salesmanId ?? this.salesmanId),
      salesmanName: clearSalesman ? null : (salesmanName ?? this.salesmanName),
      discount: discount ?? this.discount,
      isPercentageDiscount: isPercentageDiscount ?? this.isPercentageDiscount,
      note: note ?? this.note,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      splitPayment: splitPayment ?? this.splitPayment,
      orderStatus: orderStatus ?? this.orderStatus,
      heldOrders: heldOrders ?? this.heldOrders,
      isProcessing: isProcessing ?? this.isProcessing,
      lastBillNo: lastBillNo ?? this.lastBillNo,
      lastOrderNo: lastOrderNo ?? this.lastOrderNo,
    );
  }

  UnifiedSalesState reset() {
    return UnifiedSalesState(
      mode: mode,
      heldOrders: heldOrders,
    );
  }
}

// ============================================================
// UNIFIED SALES NOTIFIER
// ============================================================

class UnifiedSalesNotifier extends StateNotifier<UnifiedSalesState> {
  final Ref ref;

  UnifiedSalesNotifier(this.ref) : super(const UnifiedSalesState());

  // === MODE ===
  void setMode(SalesMode mode) {
    state = state.copyWith(mode: mode);
  }

  void toggleMode() {
    state = state.copyWith(
      mode: state.mode == SalesMode.directSale 
        ? SalesMode.createOrder 
        : SalesMode.directSale,
    );
  }

  // === CART OPERATIONS ===
  void addToCart(Product product, {List<String>? imeis}) {
    if (product.stock <= 0) return;

    final items = [...state.items];
    final existingIndex = items.indexWhere((item) => item.product.id == product.id);
    
    if (existingIndex != -1) {
      if (items[existingIndex].quantity < product.stock) {
        items[existingIndex] = items[existingIndex].copyWith(
          quantity: items[existingIndex].quantity + 1,
          imeis: [...items[existingIndex].imeis, ...(imeis ?? [])],
        );
      }
    } else {
      items.add(SalesCartItem(
        product: product,
        imeis: imeis ?? [],
      ));
    }
    
    state = state.copyWith(items: items);
  }

  void addToCartWithImeis(Product product, List<String> imeis) {
    final items = [...state.items];
    final existingIndex = items.indexWhere((item) => item.product.id == product.id);
    
    if (existingIndex != -1) {
      items[existingIndex] = items[existingIndex].copyWith(
        quantity: items[existingIndex].quantity + imeis.length,
        imeis: [...items[existingIndex].imeis, ...imeis],
      );
    } else {
      items.add(SalesCartItem(
        product: product,
        quantity: imeis.length,
        imeis: imeis,
      ));
    }
    
    state = state.copyWith(items: items);
  }

  void removeFromCart(String productId) {
    state = state.copyWith(
      items: state.items.where((item) => item.product.id != productId).toList()
    );
  }

  void updateQuantity(String productId, int delta) {
    state = state.copyWith(
      items: [
        for (final item in state.items)
          if (item.product.id == productId)
            item.copyWith(
              quantity: (item.quantity + delta).clamp(1, item.product.stock)
            )
          else item
      ]
    );
  }

  void setItemImeis(String productId, List<String> imeis) {
    state = state.copyWith(
      items: [
        for (final item in state.items)
          if (item.product.id == productId)
            item.copyWith(imeis: imeis, quantity: imeis.isNotEmpty ? imeis.length : item.quantity)
          else item
      ]
    );
  }

  void setItemDiscount(String productId, double discount) {
    state = state.copyWith(
      items: [
        for (final item in state.items)
          if (item.product.id == productId)
            item.copyWith(lineDiscount: discount)
          else item
      ]
    );
  }

  // === CUSTOMER ===
  void setCustomer(Customer? customer) {
    if (customer == null) {
      state = state.copyWith(clearCustomer: true);
    } else {
      state = state.copyWith(
        selectedCustomer: customer,
        walkInPhone: customer.contact,
        isWholesale: customer.isWholesale,
      );
    }
  }

  void setWalkInName(String name) => state = state.copyWith(walkInName: name);
  void setWalkInPhone(String phone) => state = state.copyWith(walkInPhone: phone);

  // === SALESMAN ===
  void setSalesman(String id, String name) {
    state = state.copyWith(salesmanId: id, salesmanName: name);
  }

  void clearSalesman() => state = state.copyWith(clearSalesman: true);

  // === DISCOUNT ===
  void setDiscount(double value, bool isPercentage) {
    state = state.copyWith(discount: value, isPercentageDiscount: isPercentage);
  }

  // === PAYMENT ===
  void setPaymentMethod(PaymentMethod method) {
    state = state.copyWith(paymentMethod: method);
  }

  void setSplitPayment(double cashAmount, double cardAmount, {String? bankAccountNo, String? bankName}) {
    state = state.copyWith(
      paymentMethod: PaymentMethod.split,
      splitPayment: SplitPaymentInfo(
        cashAmount: cashAmount,
        cardAmount: cardAmount,
        bankAccountNo: bankAccountNo,
        bankName: bankName,
      ),
    );
  }

  // === NOTES ===
  void setNote(String note) => state = state.copyWith(note: note);

  // === ORDER STATUS ===
  void setOrderStatus(SaleOrderStatus status) => state = state.copyWith(orderStatus: status);

  // === HELD ORDERS ===
  void holdCurrentOrder({String? note}) {
    if (state.items.isEmpty) return;
    
    final id = 'HOLD-${DateTime.now().millisecondsSinceEpoch}';
    final heldOrder = HeldOrder(
      id: id,
      customerName: state.selectedCustomer?.name,
      items: state.items,
      heldAt: DateTime.now(),
      note: note,
    );
    
    state = state.copyWith(
      heldOrders: {...state.heldOrders, id: heldOrder},
    );
    clearCart();
  }

  void resumeHeldOrder(String id) {
    final heldOrder = state.heldOrders[id];
    if (heldOrder == null) return;
    
    final newHeldOrders = Map<String, HeldOrder>.from(state.heldOrders)..remove(id);
    state = state.copyWith(
      items: heldOrder.items,
      heldOrders: newHeldOrders,
    );
  }

  void deleteHeldOrder(String id) {
    final newHeldOrders = Map<String, HeldOrder>.from(state.heldOrders)..remove(id);
    state = state.copyWith(heldOrders: newHeldOrders);
  }

  // === CLEAR ===
  void clearCart() {
    state = state.reset();
  }

  // === CHECKOUT (DIRECT SALE) ===
  Future<String?> processDirectSale() async {
    if (state.items.isEmpty || !state.isDirectSale) return null;
    
    state = state.copyWith(isProcessing: true);
    
    try {
      final invoiceRepo = ref.read(invoiceRepositoryProvider);
      final unitRepo = ref.read(unitRepositoryProvider);
      
      final billNo = await invoiceRepo.generateBillNo(InvoiceType.sale);
      
      // Build line items
      final lineItems = <InvoiceLineItem>[];
      for (final item in state.items) {
        if (item.imeis.isNotEmpty) {
          for (final imei in item.imeis) {
            lineItems.add(InvoiceLineItem(
              id: '',
              invoiceId: billNo,
              productId: item.product.id,
              productName: item.product.name,
              imei: imei,
              unitPrice: item.unitPrice,
              costPrice: item.costPrice,
              quantity: 1,
              lineDiscount: item.lineDiscount / item.quantity,
              lineTotal: item.unitPrice - (item.lineDiscount / item.quantity),
            ));
            
            await unitRepo.markAsSold(
              imei: imei,
              saleBillNo: billNo,
              soldPrice: item.unitPrice,
              saleDate: DateTime.now(),
            );
          }
        } else {
          lineItems.add(InvoiceLineItem(
            id: '',
            invoiceId: billNo,
            productId: item.product.id,
            productName: item.product.name,
            unitPrice: item.unitPrice,
            costPrice: item.costPrice,
            quantity: item.quantity,
            lineDiscount: item.lineDiscount,
            lineTotal: item.lineTotal,
          ));
        }
      }
      
      // Determine payment mode
      InvoicePaymentMode paymentMode;
      SplitPayment? splitPayment;
      switch (state.paymentMethod) {
        case PaymentMethod.cash:
          paymentMode = InvoicePaymentMode.cash;
          break;
        case PaymentMethod.card:
          paymentMode = InvoicePaymentMode.card;
          break;
        case PaymentMethod.split:
          paymentMode = InvoicePaymentMode.split;
          if (state.splitPayment != null) {
            splitPayment = SplitPayment(
              cashAmount: state.splitPayment!.cashAmount,
              cardAmount: state.splitPayment!.cardAmount,
              cardBankAccountNo: state.splitPayment!.bankAccountNo,
              cardBankName: state.splitPayment!.bankName,
            );
          }
          break;
        case PaymentMethod.other:
          paymentMode = InvoicePaymentMode.credit;
          break;
      }
      
      // Create invoice
      final invoice = Invoice(
        billNo: billNo,
        type: InvoiceType.sale,
        partyId: state.selectedCustomer?.id ?? 'walk-in',
        partyName: state.selectedCustomer?.name ?? state.walkInName ?? 'Walk-in Customer',
        date: DateTime.now(),
        summary: InvoiceSummary(
          grossValue: state.subtotal,
          discount: state.discountAmount,
          discountPercent: state.isPercentageDiscount ? state.discount : 0,
          tax: 0,
          netValue: state.total,
          paidAmount: state.paymentMethod == PaymentMethod.other ? 0 : state.total,
          balance: state.paymentMethod == PaymentMethod.other ? state.total : 0,
        ),
        paymentMode: paymentMode,
        splitPayment: splitPayment,
        salesmanId: state.salesmanId,
        salesmanName: state.salesmanName,
        status: InvoiceStatus.completed,
        notes: state.note,
        createdAt: DateTime.now(),
        createdBy: 'POS',
        items: lineItems,
        customerMobile: state.walkInPhone,
        customerCnic: null,
      );
      
      await invoiceRepo.save(invoice);
      
      // Update stock
      for (final item in state.items) {
        ref.read(productProvider.notifier).updateStock(item.product.id, -item.quantity);
      }
      
      state = state.copyWith(
        isProcessing: false,
        lastBillNo: billNo,
      );
      
      clearCart();
      return billNo;
    } catch (e) {
      state = state.copyWith(isProcessing: false);
      return null;
    }
  }

  // === SAVE ORDER (CREATE ORDER) ===
  Future<String?> saveOrder() async {
    if (state.items.isEmpty || !state.isCreateOrder) return null;
    
    state = state.copyWith(isProcessing: true);
    
    try {
      // Generate order number
      final orderNo = 'ORD-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
      
      // TODO: Implement order persistence when order repository is set up
      // For now, just simulate success
      await Future.delayed(const Duration(milliseconds: 500));
      
      state = state.copyWith(
        isProcessing: false,
        lastOrderNo: orderNo,
      );
      
      clearCart();
      return orderNo;
    } catch (e) {
      state = state.copyWith(isProcessing: false);
      return null;
    }
  }
}

// ============================================================
// PROVIDERS
// ============================================================

final unifiedSalesProvider = StateNotifierProvider<UnifiedSalesNotifier, UnifiedSalesState>((ref) {
  return UnifiedSalesNotifier(ref);
});

final salesSearchQueryProvider = StateProvider<String>((ref) => '');

final salesCategoryFilterProvider = StateProvider<String>((ref) => 'All');

final salesFilteredProductsProvider = Provider<List<Product>>((ref) {
  final allProducts = ref.watch(productProvider);
  final query = ref.watch(salesSearchQueryProvider).toLowerCase();
  final category = ref.watch(salesCategoryFilterProvider);

  return allProducts.where((p) {
    final matchesQuery = p.name.toLowerCase().contains(query) || 
                         p.sku.toLowerCase().contains(query) ||
                         (p.imei?.toLowerCase().contains(query) ?? false);
    final matchesCategory = category == 'All' || p.category == category;
    return matchesQuery && matchesCategory && p.isActive;
  }).toList();
});

/// Available salesmen for selection
final salesmenProvider = Provider<List<({String id, String name})>>((ref) {
  // TODO: Replace with actual salesman repository fetch
  return [
    (id: 'SM001', name: 'Ahmed Khan'),
    (id: 'SM002', name: 'Muhammad Ali'),
    (id: 'SM003', name: 'Hassan Raza'),
    (id: 'SM004', name: 'Usman Malik'),
  ];
});

final heldOrdersCountProvider = Provider<int>((ref) {
  return ref.watch(unifiedSalesProvider).heldOrders.length;
});
