/// Company model for multi-branch/multi-company support
/// Allows consolidated reporting and branch-level filtering

class Company {
  final String id;
  final String name;
  final String? code;
  final String? address;
  final String? phone;
  final String? email;
  final String? taxId;
  final bool isHeadOffice;
  final bool isActive;
  final String? parentCompanyId; // For subsidiary relationships
  final DateTime createdAt;

  const Company({
    required this.id,
    required this.name,
    this.code,
    this.address,
    this.phone,
    this.email,
    this.taxId,
    this.isHeadOffice = false,
    this.isActive = true,
    this.parentCompanyId,
    required this.createdAt,
  });

  Company copyWith({
    String? id,
    String? name,
    String? code,
    String? address,
    String? phone,
    String? email,
    String? taxId,
    bool? isHeadOffice,
    bool? isActive,
    String? parentCompanyId,
    DateTime? createdAt,
  }) {
    return Company(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      taxId: taxId ?? this.taxId,
      isHeadOffice: isHeadOffice ?? this.isHeadOffice,
      isActive: isActive ?? this.isActive,
      parentCompanyId: parentCompanyId ?? this.parentCompanyId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Salesman model for commission tracking and invoice attribution
class Salesman {
  final String id;
  final String name;
  final String? contact;
  final String? email;
  final double commissionPercent;
  final String? companyId;
  final bool isActive;
  final DateTime createdAt;

  const Salesman({
    required this.id,
    required this.name,
    this.contact,
    this.email,
    this.commissionPercent = 0.0,
    this.companyId,
    this.isActive = true,
    required this.createdAt,
  });

  Salesman copyWith({
    String? id,
    String? name,
    String? contact,
    String? email,
    double? commissionPercent,
    String? companyId,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return Salesman(
      id: id ?? this.id,
      name: name ?? this.name,
      contact: contact ?? this.contact,
      email: email ?? this.email,
      commissionPercent: commissionPercent ?? this.commissionPercent,
      companyId: companyId ?? this.companyId,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
