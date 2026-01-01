import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/app_models.dart';
import '../../../core/models/invoice.dart';
import '../../../core/repositories/invoice_repository.dart';
import '../../../core/repositories/unit_repository.dart';
import '../../inventory/controller/inventory_controller.dart';

// ============================================================
// ENHANCED CART ITEM WITH IMEI
// ============================================================

class EnhancedCartItem {
  final Product product;
  final int quantity;
  final List<String> imeis; // IMEIs for IMEI-tracked products
  final double lineDiscount;

  const EnhancedCartItem({
    required this.product,
    this.quantity = 1,
    this.imeis = const [],
    this.lineDiscount = 0.0,
  });

  double get unitPrice => product.sellingPrice;
  double get costPrice => product.purchasePrice;
  double get lineTotal => (unitPrice * quantity) - lineDiscount;
  double get profit => (unitPrice - costPrice) * quantity - lineDiscount;

  EnhancedCartItem copyWith({
    Product? product,
    int? quantity,
    List<String>? imeis,
    double? lineDiscount,
  }) {
    return EnhancedCartItem(
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

class POSSplitPayment {
  final double cashAmount;
  final double cardAmount;
  final String? bankAccountNo;
  final String? bankName;

  const POSSplitPayment({
    this.cashAmount = 0.0,
    this.cardAmount = 0.0,
    this.bankAccountNo,
    this.bankName,
  });

  double get total => cashAmount + cardAmount;

  POSSplitPayment copyWith({
    double? cashAmount,
    double? cardAmount,
    String? bankAccountNo,
    String? bankName,
  }) {
    return POSSplitPayment(
      cashAmount: cashAmount ?? this.cashAmount,
      cardAmount: cardAmount ?? this.cardAmount,
      bankAccountNo: bankAccountNo ?? this.bankAccountNo,
      bankName: bankName ?? this.bankName,
    );
  }
}

// ============================================================
// ENHANCED CART STATE
// ============================================================

class CartState {
  final List<EnhancedCartItem> items;
  final Customer? selectedCustomer;
  final String? customerCnic;
  final String? customerMobile;
  final String? salesmanId;
  final String? salesmanName;
  final double discount;
  final bool isPercentageDiscount;
  final String? note;
  final PaymentMethod paymentMethod;
  final POSSplitPayment? splitPayment;

  const CartState({
    this.items = const [],
    this.selectedCustomer,
    this.customerCnic,
    this.customerMobile,
    this.salesmanId,
    this.salesmanName,
    this.discount = 0.0,
    this.isPercentageDiscount = false,
    this.note,
    this.paymentMethod = PaymentMethod.cash,
    this.splitPayment,
  });

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

  CartState copyWith({
    List<EnhancedCartItem>? items,
    Customer? selectedCustomer,
    String? customerCnic,
    String? customerMobile,
    String? salesmanId,
    String? salesmanName,
    double? discount,
    bool? isPercentageDiscount,
    String? note,
    PaymentMethod? paymentMethod,
    POSSplitPayment? splitPayment,
    bool clearCustomer = false,
    bool clearSalesman = false,
  }) {
    return CartState(
      items: items ?? this.items,
      selectedCustomer: clearCustomer ? null : (selectedCustomer ?? this.selectedCustomer),
      customerCnic: clearCustomer ? null : (customerCnic ?? this.customerCnic),
      customerMobile: clearCustomer ? null : (customerMobile ?? this.customerMobile),
      salesmanId: clearSalesman ? null : (salesmanId ?? this.salesmanId),
      salesmanName: clearSalesman ? null : (salesmanName ?? this.salesmanName),
      discount: discount ?? this.discount,
      isPercentageDiscount: isPercentageDiscount ?? this.isPercentageDiscount,
      note: note ?? this.note,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      splitPayment: splitPayment ?? this.splitPayment,
    );
  }
}

// ============================================================
// CART NOTIFIER
// ============================================================

class CartNotifier extends StateNotifier<CartState> {
  final Ref ref;
  final Map<String, CartState> _heldOrders = {};

  CartNotifier(this.ref) : super(const CartState());

  Map<String, CartState> get heldOrders => _heldOrders;

  void holdCurrentOrder() {
    if (state.items.isEmpty) return;
    final id = 'HOLD-${DateTime.now().millisecondsSinceEpoch}';
    _heldOrders[id] = state;
    clearCart();
  }

  void resumeHeldOrder(String id) {
    if (_heldOrders.containsKey(id)) {
      state = _heldOrders[id]!;
      _heldOrders.remove(id);
    }
  }

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
      items.add(EnhancedCartItem(
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
      items.add(EnhancedCartItem(
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

  void setCustomer(Customer? customer) {
    if (customer == null) {
      state = state.copyWith(clearCustomer: true);
    } else {
      state = state.copyWith(
        selectedCustomer: customer,
        customerMobile: customer.contact,
        customerCnic: customer.cnic,
      );
    }
  }

  void setCustomerCnic(String cnic) {
    state = state.copyWith(customerCnic: cnic);
  }

  void setCustomerMobile(String mobile) {
    state = state.copyWith(customerMobile: mobile);
  }

  void setSalesman(String id, String name) {
    state = state.copyWith(salesmanId: id, salesmanName: name);
  }

  void clearSalesman() {
    state = state.copyWith(clearSalesman: true);
  }

  void setDiscount(double value, bool isPercentage) {
    state = state.copyWith(discount: value, isPercentageDiscount: isPercentage);
  }

  void setPaymentMethod(PaymentMethod method) {
    state = state.copyWith(paymentMethod: method);
  }

  void setSplitPayment(double cashAmount, double cardAmount, {String? bankAccountNo, String? bankName}) {
    state = state.copyWith(
      paymentMethod: PaymentMethod.split,
      splitPayment: POSSplitPayment(
        cashAmount: cashAmount,
        cardAmount: cardAmount,
        bankAccountNo: bankAccountNo,
        bankName: bankName,
      ),
    );
  }

  void setNote(String note) {
    state = state.copyWith(note: note);
  }

  void clearCart() {
    state = const CartState();
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier(ref);
});

final posCategoryFilterProvider = StateProvider<String>((ref) => 'All');

final posFilteredProductsProvider = Provider<List<Product>>((ref) {
  final allProducts = ref.watch(productProvider);
  final query = ref.watch(searchQueryProvider).toLowerCase();
  final category = ref.watch(posCategoryFilterProvider);

  return allProducts.where((p) {
    final matchesQuery = p.name.toLowerCase().contains(query) || 
                         p.sku.toLowerCase().contains(query);
    final matchesCategory = category == 'All' || p.category == category;
    return matchesQuery && matchesCategory;
  }).toList();
});

// ============================================================
// SALES NOTIFIER WITH INVOICE CREATION
// ============================================================

class SalesNotifier extends StateNotifier<List<Sale>> {
  final Ref ref;
  SalesNotifier(this.ref) : super([]);

  Future<String?> processCheckout({
    required CartState cart,
  }) async {
    try {
      final invoiceRepo = ref.read(invoiceRepositoryProvider);
      final unitRepo = ref.read(unitRepositoryProvider);

      // Generate bill number
      final billNo = await invoiceRepo.generateBillNo(InvoiceType.sale);

      // Build line items
      final lineItems = <InvoiceLineItem>[];
      for (final item in cart.items) {
        if (item.imeis.isNotEmpty) {
          // Create separate line items for each IMEI
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

            // Mark IMEI as sold
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
      switch (cart.paymentMethod) {
        case PaymentMethod.cash:
          paymentMode = InvoicePaymentMode.cash;
          break;
        case PaymentMethod.card:
          paymentMode = InvoicePaymentMode.card;
          break;
        case PaymentMethod.split:
          paymentMode = InvoicePaymentMode.split;
          if (cart.splitPayment != null) {
            splitPayment = SplitPayment(
              cashAmount: cart.splitPayment!.cashAmount,
              cardAmount: cart.splitPayment!.cardAmount,
              cardBankAccountNo: cart.splitPayment!.bankAccountNo,
              cardBankName: cart.splitPayment!.bankName,
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
        partyId: cart.selectedCustomer?.id ?? 'walk-in',
        partyName: cart.selectedCustomer?.name ?? 'Walk-in Customer',
        date: DateTime.now(),
        summary: InvoiceSummary(
          grossValue: cart.subtotal,
          discount: cart.discountAmount,
          discountPercent: cart.isPercentageDiscount ? cart.discount : 0,
          tax: 0,
          netValue: cart.total,
          paidAmount: cart.paymentMethod == PaymentMethod.other ? 0 : cart.total,
          balance: cart.paymentMethod == PaymentMethod.other ? cart.total : 0,
        ),
        paymentMode: paymentMode,
        splitPayment: splitPayment,
        salesmanId: cart.salesmanId,
        salesmanName: cart.salesmanName,
        status: InvoiceStatus.completed,
        notes: cart.note,
        createdAt: DateTime.now(),
        createdBy: 'POS',
        items: lineItems,
        customerMobile: cart.customerMobile,
        customerCnic: cart.customerCnic,
      );

      // Save invoice
      await invoiceRepo.save(invoice);

      // Record legacy sale for backwards compatibility
      final legacyItems = cart.items.map((item) => CartItem(
        product: item.product,
        quantity: item.quantity,
      )).toList();

      final sale = Sale(
        id: billNo,
        items: legacyItems,
        subtotal: cart.subtotal,
        discount: cart.discountAmount,
        total: cart.total,
        timestamp: DateTime.now(),
        paymentMethod: cart.paymentMethod,
        customerName: cart.selectedCustomer?.name,
      );

      state = [sale, ...state];

      // Update stock levels
      for (final item in cart.items) {
        ref.read(productProvider.notifier).updateStock(item.product.id, -item.quantity);
      }

      // Clear cart after checkout
      ref.read(cartProvider.notifier).clearCart();

      return billNo;
    } catch (e) {
      return null;
    }
  }

  // Legacy method for backwards compatibility
  void processCheckoutLegacy({
    required CartState cart,
    required PaymentMethod paymentMethod,
  }) {
    processCheckout(cart: cart);
  }
}

final salesProvider = StateNotifierProvider<SalesNotifier, List<Sale>>((ref) {
  return SalesNotifier(ref);
});

// ============================================================
// SALESMAN PROVIDERS
// ============================================================

/// Available salesmen for selection
final availableSalesmenProvider = Provider<List<({String id, String name})>>((ref) {
  // TODO: Replace with actual salesman repository fetch
  return [
    (id: 'SM001', name: 'Ahmed Khan'),
    (id: 'SM002', name: 'Muhammad Ali'),
    (id: 'SM003', name: 'Hassan Raza'),
    (id: 'SM004', name: 'Usman Malik'),
  ];
});
