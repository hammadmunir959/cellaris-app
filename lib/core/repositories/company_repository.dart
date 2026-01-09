import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';

import '../database/isar_service.dart';
import '../database/isar_schemas.dart';
import '../models/company.dart';
import '../models/location.dart';

/// Repository for Company management (multi-branch support)
class CompanyRepository {
  final IsarService _isarService;

  CompanyRepository(this._isarService);

  Isar get _isar => _isarService.isar;

  /// Get all companies
  Future<List<Company>> getAll() async {
    final persistence = await _isar.companyPersistences.where().findAll();
    return persistence.map(_mapFromPersistence).toList();
  }

  /// Get active companies
  Future<List<Company>> getActive() async {
    final persistence = await _isar.companyPersistences
        .filter()
        .isActiveEqualTo(true)
        .findAll();
    return persistence.map(_mapFromPersistence).toList();
  }

  /// Get company by ID
  Future<Company?> getById(String id) async {
    final persistence = await _isar.companyPersistences
        .filter()
        .idEqualTo(id)
        .findFirst();
    return persistence != null ? _mapFromPersistence(persistence) : null;
  }

  /// Get head office
  Future<Company?> getHeadOffice() async {
    final persistence = await _isar.companyPersistences
        .filter()
        .isHeadOfficeEqualTo(true)
        .findFirst();
    return persistence != null ? _mapFromPersistence(persistence) : null;
  }

  /// Save company
  Future<void> save(Company company) async {
    final persistence = _mapToPersistence(company);
    await _isar.writeTxn(() async {
      await _isar.companyPersistences.put(persistence);
    });
  }

  /// Delete company
  Future<void> delete(String id) async {
    await _isar.writeTxn(() async {
      await _isar.companyPersistences.filter().idEqualTo(id).deleteFirst();
    });
  }

  Company _mapFromPersistence(CompanyPersistence p) {
    return Company(
      id: p.id,
      name: p.name,
      code: p.code,
      address: p.address,
      phone: p.phone,
      email: p.email,
      taxId: p.taxId,
      isHeadOffice: p.isHeadOffice,
      isActive: p.isActive,
      parentCompanyId: p.parentCompanyId,
      createdAt: p.createdAt,
    );
  }

  CompanyPersistence _mapToPersistence(Company c) {
    return CompanyPersistence()
      ..id = c.id
      ..name = c.name
      ..code = c.code
      ..address = c.address
      ..phone = c.phone
      ..email = c.email
      ..taxId = c.taxId
      ..isHeadOffice = c.isHeadOffice
      ..isActive = c.isActive
      ..parentCompanyId = c.parentCompanyId
      ..createdAt = c.createdAt
      ..updatedAt = DateTime.now()
      ..isSynced = false;
  }
}

/// Repository for Location management (warehouse, shop floor, bins)
class LocationRepository {
  final IsarService _isarService;

  LocationRepository(this._isarService);

  Isar get _isar => _isarService.isar;

  /// Get all locations
  Future<List<Location>> getAll({String? companyId}) async {
    if (companyId != null) {
      final persistence = await _isar.locationPersistences
          .filter()
          .companyIdEqualTo(companyId)
          .findAll();
      return persistence.map(_mapFromPersistence).toList();
    }
    final persistence = await _isar.locationPersistences.where().findAll();
    return persistence.map(_mapFromPersistence).toList();
  }

  /// Get active locations
  Future<List<Location>> getActive({String? companyId}) async {
    var query = _isar.locationPersistences.filter().isActiveEqualTo(true);
    if (companyId != null) {
      query = query.companyIdEqualTo(companyId);
    }
    final persistence = await query.findAll();
    return persistence.map(_mapFromPersistence).toList();
  }

  /// Get locations by type
  Future<List<Location>> getByType(LocationType type, {String? companyId}) async {
    var query = _isar.locationPersistences.filter().typeEqualTo(type.name);
    if (companyId != null) {
      query = query.companyIdEqualTo(companyId);
    }
    final persistence = await query.findAll();
    return persistence.map(_mapFromPersistence).toList();
  }

  /// Get location by ID
  Future<Location?> getById(String id) async {
    final persistence = await _isar.locationPersistences
        .filter()
        .idEqualTo(id)
        .findFirst();
    return persistence != null ? _mapFromPersistence(persistence) : null;
  }

  /// Get child locations
  Future<List<Location>> getChildren(String parentId) async {
    final persistence = await _isar.locationPersistences
        .filter()
        .parentLocationIdEqualTo(parentId)
        .findAll();
    return persistence.map(_mapFromPersistence).toList();
  }

  /// Save location
  Future<void> save(Location location) async {
    final persistence = _mapToPersistence(location);
    await _isar.writeTxn(() async {
      await _isar.locationPersistences.put(persistence);
    });
  }

  /// Delete location
  Future<void> delete(String id) async {
    await _isar.writeTxn(() async {
      await _isar.locationPersistences.filter().idEqualTo(id).deleteFirst();
    });
  }

  Location _mapFromPersistence(LocationPersistence p) {
    return Location(
      id: p.id,
      name: p.name,
      code: p.code,
      type: _parseLocationType(p.type),
      companyId: p.companyId,
      parentLocationId: p.parentLocationId,
      address: p.address,
      isActive: p.isActive,
      createdAt: p.createdAt,
    );
  }

  LocationPersistence _mapToPersistence(Location l) {
    return LocationPersistence()
      ..id = l.id
      ..name = l.name
      ..code = l.code
      ..type = l.type.name
      ..companyId = l.companyId
      ..parentLocationId = l.parentLocationId
      ..address = l.address
      ..isActive = l.isActive
      ..createdAt = l.createdAt
      ..updatedAt = DateTime.now()
      ..isSynced = false;
  }

  LocationType _parseLocationType(String type) {
    switch (type) {
      case 'warehouse':
        return LocationType.warehouse;
      case 'shopFloor':
        return LocationType.shopFloor;
      case 'bin':
        return LocationType.bin;
      case 'shelf':
        return LocationType.shelf;
      default:
        return LocationType.other;
    }
  }
}

/// Providers
final companyRepositoryProvider = Provider<CompanyRepository>((ref) {
  final isarService = ref.watch(isarServiceProvider);
  return CompanyRepository(isarService);
});

final locationRepositoryProvider = Provider<LocationRepository>((ref) {
  final isarService = ref.watch(isarServiceProvider);
  return LocationRepository(isarService);
});
