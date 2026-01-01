import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mbm_app/core/models/app_models.dart';

class SettingsNotifier extends StateNotifier<BusinessSettings> {
  SettingsNotifier() : super(BusinessSettings(
    companyName: 'MBM Mobile Solutions',
    address: 'Main Boulevard, Gulberg III, Lahore',
    phone: '+92 42 1234567',
    email: 'info@mbm.com',
    taxId: 'NTN-1234567-8',
    taxRates: [
      TaxRate(id: '1', name: 'Standard GST', rate: 17, isDefault: true),
    ],
    paymentMethods: [
      TransactionPaymentMethod(id: '1', name: 'Cash', type: 'cash'),
      TransactionPaymentMethod(id: '2', name: 'Credit Card', type: 'card'),
      TransactionPaymentMethod(id: '3', name: 'EasyPaisa', type: 'wallet'),
    ],
  ));

  void updateSettings(BusinessSettings newSettings) {
    state = newSettings;
  }

  void addTaxRate(TaxRate taxRate) {
    state = state.copyWith(taxRates: [...state.taxRates, taxRate]);
  }

  void updateTaxRate(TaxRate taxRate) {
    state = state.copyWith(
      taxRates: state.taxRates.map((t) => t.id == taxRate.id ? taxRate : t).toList(),
    );
  }

  void deleteTaxRate(String id) {
    state = state.copyWith(
      taxRates: state.taxRates.where((t) => t.id != id).toList(),
    );
  }

  void addPaymentMethod(TransactionPaymentMethod method) {
    state = state.copyWith(paymentMethods: [...state.paymentMethods, method]);
  }

  void updatePaymentMethod(TransactionPaymentMethod method) {
    state = state.copyWith(
      paymentMethods: state.paymentMethods.map((m) => m.id == method.id ? method : m).toList(),
    );
  }

  void deletePaymentMethod(String id) {
    state = state.copyWith(
      paymentMethods: state.paymentMethods.where((m) => m.id != id).toList(),
    );
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, BusinessSettings>((ref) {
  return SettingsNotifier();
});
