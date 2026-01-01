import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/app_models.dart';
import '../../../core/models/invoice.dart';
import '../../../core/repositories/invoice_repository.dart';
import '../../inventory/controller/inventory_controller.dart';

/// State for return processing
class ReturnState {
  final bool isProcessing;
  final String? error;
  final String? returnInvoiceNo;

  const ReturnState({
    this.isProcessing = false,
    this.error,
    this.returnInvoiceNo,
  });

  ReturnState copyWith({
    bool? isProcessing,
    String? error,
    String? returnInvoiceNo,
  }) {
    return ReturnState(
      isProcessing: isProcessing ?? this.isProcessing,
      error: error,
      returnInvoiceNo: returnInvoiceNo,
    );
  }
}

class ReturnsNotifier extends StateNotifier<ReturnState> {
  final Ref ref;
  final List<ReturnRequest> _processedReturns = [];

  ReturnsNotifier(this.ref) : super(const ReturnState());

  List<ReturnRequest> get processedReturns => _processedReturns;

  /// Process a return against an original invoice
  Future<void> processReturn({
    required Invoice originalInvoice,
    required Map<String, int> returnQuantities,
    required double deductionPercent,
    required String reason,
  }) async {
    state = state.copyWith(isProcessing: true, error: null);

    try {
      final invoiceRepo = ref.read(invoiceRepositoryProvider);

      // Generate return invoice number
      final returnBillNo = await invoiceRepo.generateBillNo(InvoiceType.saleReturn);

      // Build return line items
      final returnItems = <InvoiceLineItem>[];
      double totalReturnValue = 0;

      for (final item in originalInvoice.items) {
        final returnQty = returnQuantities[item.id] ?? 0;
        if (returnQty > 0) {
          final unitValue = item.lineTotal / item.quantity;
          final returnValue = unitValue * returnQty;
          totalReturnValue += returnValue;

          returnItems.add(InvoiceLineItem(
            id: '',
            invoiceId: returnBillNo,
            productId: item.productId,
            productName: item.productName,
            imei: item.imei,
            unitPrice: item.unitPrice,
            costPrice: item.costPrice,
            quantity: returnQty,
            lineDiscount: 0,
            lineTotal: returnValue,
            warranty: item.warranty,
            color: item.color,
          ));

          // Restore inventory stock
          ref.read(productProvider.notifier).updateStock(item.productId, returnQty);
        }
      }

      // Apply deduction
      final deductionAmount = totalReturnValue * (deductionPercent / 100);
      final refundAmount = totalReturnValue - deductionAmount;

      // Create return invoice
      final returnInvoice = Invoice(
        billNo: returnBillNo,
        type: InvoiceType.saleReturn,
        partyId: originalInvoice.partyId,
        partyName: originalInvoice.partyName,
        date: DateTime.now(),
        summary: InvoiceSummary(
          grossValue: totalReturnValue,
          discount: deductionAmount,
          discountPercent: deductionPercent,
          tax: 0,
          netValue: refundAmount,
          paidAmount: refundAmount,
          balance: 0,
        ),
        paymentMode: InvoicePaymentMode.cash,
        salesmanId: originalInvoice.salesmanId,
        salesmanName: originalInvoice.salesmanName,
        status: InvoiceStatus.completed,
        companyId: originalInvoice.companyId,
        notes: reason,
        createdAt: DateTime.now(),
        createdBy: 'System',
        items: returnItems,
        originalBillNo: originalInvoice.billNo,
      );

      // Save return invoice
      await invoiceRepo.save(returnInvoice);

      // Record processed return
      final returnQtyTotal = returnQuantities.values.fold(0, (a, b) => a + b);
      final firstProductId = returnItems.isNotEmpty ? returnItems.first.productId : '';
      final firstProductName = returnItems.isNotEmpty ? returnItems.first.productName : '';
      _processedReturns.add(ReturnRequest(
        id: returnBillNo,
        saleId: originalInvoice.billNo,
        productId: firstProductId,
        productName: firstProductName,
        customerName: originalInvoice.partyName,
        quantity: returnQtyTotal,
        reason: reason,
        refundMethod: 'cash',
        refundAmount: refundAmount,
        status: ReturnStatus.completed,
        createdAt: DateTime.now(),
        processedAt: DateTime.now(),
      ));

      state = state.copyWith(isProcessing: false, returnInvoiceNo: returnBillNo);
    } catch (e) {
      state = state.copyWith(isProcessing: false, error: e.toString());
      rethrow;
    }
  }
}

final returnsProvider = StateNotifierProvider<ReturnsNotifier, ReturnState>((ref) {
  return ReturnsNotifier(ref);
});
