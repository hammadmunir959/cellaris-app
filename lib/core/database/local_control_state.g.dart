// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_control_state.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetLocalControlStatePersistenceCollection on Isar {
  IsarCollection<LocalControlStatePersistence>
      get localControlStatePersistences => this.collection();
}

const LocalControlStatePersistenceSchema = CollectionSchema(
  name: r'LocalControlStatePersistence',
  id: 2606078931607480437,
  properties: {
    r'createdAt': PropertySchema(
      id: 0,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'daysUntilExpiry': PropertySchema(
      id: 1,
      name: r'daysUntilExpiry',
      type: IsarType.long,
    ),
    r'id': PropertySchema(
      id: 2,
      name: r'id',
      type: IsarType.string,
    ),
    r'isOfflineLimitExceeded': PropertySchema(
      id: 3,
      name: r'isOfflineLimitExceeded',
      type: IsarType.bool,
    ),
    r'isSubscriptionExpired': PropertySchema(
      id: 4,
      name: r'isSubscriptionExpired',
      type: IsarType.bool,
    ),
    r'lastOnlineDate': PropertySchema(
      id: 5,
      name: r'lastOnlineDate',
      type: IsarType.dateTime,
    ),
    r'lastServerTime': PropertySchema(
      id: 6,
      name: r'lastServerTime',
      type: IsarType.dateTime,
    ),
    r'lastSyncedAt': PropertySchema(
      id: 7,
      name: r'lastSyncedAt',
      type: IsarType.dateTime,
    ),
    r'maxOfflineDays': PropertySchema(
      id: 8,
      name: r'maxOfflineDays',
      type: IsarType.long,
    ),
    r'offlineDaysUsed': PropertySchema(
      id: 9,
      name: r'offlineDaysUsed',
      type: IsarType.long,
    ),
    r'status': PropertySchema(
      id: 10,
      name: r'status',
      type: IsarType.string,
    ),
    r'subscriptionEndDate': PropertySchema(
      id: 11,
      name: r'subscriptionEndDate',
      type: IsarType.dateTime,
    ),
    r'updatedAt': PropertySchema(
      id: 12,
      name: r'updatedAt',
      type: IsarType.dateTime,
    ),
    r'userId': PropertySchema(
      id: 13,
      name: r'userId',
      type: IsarType.string,
    )
  },
  estimateSize: _localControlStatePersistenceEstimateSize,
  serialize: _localControlStatePersistenceSerialize,
  deserialize: _localControlStatePersistenceDeserialize,
  deserializeProp: _localControlStatePersistenceDeserializeProp,
  idName: r'isarId',
  indexes: {
    r'id': IndexSchema(
      id: -3268401673993471357,
      name: r'id',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'id',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _localControlStatePersistenceGetId,
  getLinks: _localControlStatePersistenceGetLinks,
  attach: _localControlStatePersistenceAttach,
  version: '3.2.1',
);

int _localControlStatePersistenceEstimateSize(
  LocalControlStatePersistence object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.id.length * 3;
  bytesCount += 3 + object.status.length * 3;
  bytesCount += 3 + object.userId.length * 3;
  return bytesCount;
}

void _localControlStatePersistenceSerialize(
  LocalControlStatePersistence object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.createdAt);
  writer.writeLong(offsets[1], object.daysUntilExpiry);
  writer.writeString(offsets[2], object.id);
  writer.writeBool(offsets[3], object.isOfflineLimitExceeded);
  writer.writeBool(offsets[4], object.isSubscriptionExpired);
  writer.writeDateTime(offsets[5], object.lastOnlineDate);
  writer.writeDateTime(offsets[6], object.lastServerTime);
  writer.writeDateTime(offsets[7], object.lastSyncedAt);
  writer.writeLong(offsets[8], object.maxOfflineDays);
  writer.writeLong(offsets[9], object.offlineDaysUsed);
  writer.writeString(offsets[10], object.status);
  writer.writeDateTime(offsets[11], object.subscriptionEndDate);
  writer.writeDateTime(offsets[12], object.updatedAt);
  writer.writeString(offsets[13], object.userId);
}

LocalControlStatePersistence _localControlStatePersistenceDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = LocalControlStatePersistence();
  object.createdAt = reader.readDateTime(offsets[0]);
  object.id = reader.readString(offsets[2]);
  object.isarId = id;
  object.lastOnlineDate = reader.readDateTime(offsets[5]);
  object.lastServerTime = reader.readDateTime(offsets[6]);
  object.lastSyncedAt = reader.readDateTime(offsets[7]);
  object.maxOfflineDays = reader.readLong(offsets[8]);
  object.offlineDaysUsed = reader.readLong(offsets[9]);
  object.status = reader.readString(offsets[10]);
  object.subscriptionEndDate = reader.readDateTime(offsets[11]);
  object.updatedAt = reader.readDateTime(offsets[12]);
  object.userId = reader.readString(offsets[13]);
  return object;
}

P _localControlStatePersistenceDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readBool(offset)) as P;
    case 4:
      return (reader.readBool(offset)) as P;
    case 5:
      return (reader.readDateTime(offset)) as P;
    case 6:
      return (reader.readDateTime(offset)) as P;
    case 7:
      return (reader.readDateTime(offset)) as P;
    case 8:
      return (reader.readLong(offset)) as P;
    case 9:
      return (reader.readLong(offset)) as P;
    case 10:
      return (reader.readString(offset)) as P;
    case 11:
      return (reader.readDateTime(offset)) as P;
    case 12:
      return (reader.readDateTime(offset)) as P;
    case 13:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _localControlStatePersistenceGetId(LocalControlStatePersistence object) {
  return object.isarId;
}

List<IsarLinkBase<dynamic>> _localControlStatePersistenceGetLinks(
    LocalControlStatePersistence object) {
  return [];
}

void _localControlStatePersistenceAttach(
    IsarCollection<dynamic> col, Id id, LocalControlStatePersistence object) {
  object.isarId = id;
}

extension LocalControlStatePersistenceByIndex
    on IsarCollection<LocalControlStatePersistence> {
  Future<LocalControlStatePersistence?> getById(String id) {
    return getByIndex(r'id', [id]);
  }

  LocalControlStatePersistence? getByIdSync(String id) {
    return getByIndexSync(r'id', [id]);
  }

  Future<bool> deleteById(String id) {
    return deleteByIndex(r'id', [id]);
  }

  bool deleteByIdSync(String id) {
    return deleteByIndexSync(r'id', [id]);
  }

  Future<List<LocalControlStatePersistence?>> getAllById(
      List<String> idValues) {
    final values = idValues.map((e) => [e]).toList();
    return getAllByIndex(r'id', values);
  }

  List<LocalControlStatePersistence?> getAllByIdSync(List<String> idValues) {
    final values = idValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'id', values);
  }

  Future<int> deleteAllById(List<String> idValues) {
    final values = idValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'id', values);
  }

  int deleteAllByIdSync(List<String> idValues) {
    final values = idValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'id', values);
  }

  Future<Id> putById(LocalControlStatePersistence object) {
    return putByIndex(r'id', object);
  }

  Id putByIdSync(LocalControlStatePersistence object, {bool saveLinks = true}) {
    return putByIndexSync(r'id', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllById(List<LocalControlStatePersistence> objects) {
    return putAllByIndex(r'id', objects);
  }

  List<Id> putAllByIdSync(List<LocalControlStatePersistence> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'id', objects, saveLinks: saveLinks);
  }
}

extension LocalControlStatePersistenceQueryWhereSort on QueryBuilder<
    LocalControlStatePersistence, LocalControlStatePersistence, QWhere> {
  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterWhere> anyIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension LocalControlStatePersistenceQueryWhere on QueryBuilder<
    LocalControlStatePersistence, LocalControlStatePersistence, QWhereClause> {
  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterWhereClause> isarIdEqualTo(Id isarId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: isarId,
        upper: isarId,
      ));
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterWhereClause> isarIdNotEqualTo(Id isarId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: isarId, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: isarId, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: isarId, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: isarId, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterWhereClause> isarIdGreaterThan(Id isarId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: isarId, includeLower: include),
      );
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterWhereClause> isarIdLessThan(Id isarId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: isarId, includeUpper: include),
      );
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterWhereClause> isarIdBetween(
    Id lowerIsarId,
    Id upperIsarId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerIsarId,
        includeLower: includeLower,
        upper: upperIsarId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterWhereClause> idEqualTo(String id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'id',
        value: [id],
      ));
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterWhereClause> idNotEqualTo(String id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'id',
              lower: [],
              upper: [id],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'id',
              lower: [id],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'id',
              lower: [id],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'id',
              lower: [],
              upper: [id],
              includeUpper: false,
            ));
      }
    });
  }
}

extension LocalControlStatePersistenceQueryFilter on QueryBuilder<
    LocalControlStatePersistence,
    LocalControlStatePersistence,
    QFilterCondition> {
  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterFilterCondition> createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterFilterCondition> createdAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterFilterCondition> createdAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterFilterCondition> createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'createdAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterFilterCondition> daysUntilExpiryEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'daysUntilExpiry',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterFilterCondition> daysUntilExpiryGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'daysUntilExpiry',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterFilterCondition> daysUntilExpiryLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'daysUntilExpiry',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterFilterCondition> daysUntilExpiryBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'daysUntilExpiry',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterFilterCondition> idEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterFilterCondition> idGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterFilterCondition> idLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterFilterCondition> idBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterFilterCondition> idStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterFilterCondition> idEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
          QAfterFilterCondition>
      idContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
          QAfterFilterCondition>
      idMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'id',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterFilterCondition> idIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterFilterCondition> idIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'id',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterFilterCondition> isOfflineLimitExceededEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isOfflineLimitExceeded',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterFilterCondition> isSubscriptionExpiredEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isSubscriptionExpired',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterFilterCondition> isarIdEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterFilterCondition> isarIdGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterFilterCondition> isarIdLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterFilterCondition> isarIdBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'isarId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterFilterCondition> lastOnlineDateEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastOnlineDate',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterFilterCondition> lastOnlineDateGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastOnlineDate',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterFilterCondition> lastOnlineDateLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastOnlineDate',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterFilterCondition> lastOnlineDateBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastOnlineDate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterFilterCondition> lastServerTimeEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastServerTime',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterFilterCondition> lastServerTimeGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastServerTime',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterFilterCondition> lastServerTimeLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastServerTime',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterFilterCondition> lastServerTimeBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastServerTime',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterFilterCondition> lastSyncedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastSyncedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterFilterCondition> lastSyncedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastSyncedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterFilterCondition> lastSyncedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastSyncedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterFilterCondition> lastSyncedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastSyncedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterFilterCondition> maxOfflineDaysEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'maxOfflineDays',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterFilterCondition> maxOfflineDaysGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'maxOfflineDays',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterFilterCondition> maxOfflineDaysLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'maxOfflineDays',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterFilterCondition> maxOfflineDaysBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'maxOfflineDays',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterFilterCondition> offlineDaysUsedEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'offlineDaysUsed',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterFilterCondition> offlineDaysUsedGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'offlineDaysUsed',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterFilterCondition> offlineDaysUsedLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'offlineDaysUsed',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterFilterCondition> offlineDaysUsedBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'offlineDaysUsed',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterFilterCondition> statusEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterFilterCondition> statusGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterFilterCondition> statusLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterFilterCondition> statusBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'status',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterFilterCondition> statusStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterFilterCondition> statusEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
          QAfterFilterCondition>
      statusContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
          QAfterFilterCondition>
      statusMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'status',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterFilterCondition> statusIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'status',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterFilterCondition> statusIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'status',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterFilterCondition> subscriptionEndDateEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'subscriptionEndDate',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterFilterCondition> subscriptionEndDateGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'subscriptionEndDate',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterFilterCondition> subscriptionEndDateLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'subscriptionEndDate',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterFilterCondition> subscriptionEndDateBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'subscriptionEndDate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterFilterCondition> updatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterFilterCondition> updatedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterFilterCondition> updatedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterFilterCondition> updatedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'updatedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterFilterCondition> userIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterFilterCondition> userIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterFilterCondition> userIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterFilterCondition> userIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'userId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterFilterCondition> userIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterFilterCondition> userIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
          QAfterFilterCondition>
      userIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
          QAfterFilterCondition>
      userIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'userId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterFilterCondition> userIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'userId',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterFilterCondition> userIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'userId',
        value: '',
      ));
    });
  }
}

extension LocalControlStatePersistenceQueryObject on QueryBuilder<
    LocalControlStatePersistence,
    LocalControlStatePersistence,
    QFilterCondition> {}

extension LocalControlStatePersistenceQueryLinks on QueryBuilder<
    LocalControlStatePersistence,
    LocalControlStatePersistence,
    QFilterCondition> {}

extension LocalControlStatePersistenceQuerySortBy on QueryBuilder<
    LocalControlStatePersistence, LocalControlStatePersistence, QSortBy> {
  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterSortBy> sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterSortBy> sortByDaysUntilExpiry() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'daysUntilExpiry', Sort.asc);
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterSortBy> sortByDaysUntilExpiryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'daysUntilExpiry', Sort.desc);
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterSortBy> sortById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterSortBy> sortByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterSortBy> sortByIsOfflineLimitExceeded() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isOfflineLimitExceeded', Sort.asc);
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterSortBy> sortByIsOfflineLimitExceededDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isOfflineLimitExceeded', Sort.desc);
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterSortBy> sortByIsSubscriptionExpired() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSubscriptionExpired', Sort.asc);
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterSortBy> sortByIsSubscriptionExpiredDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSubscriptionExpired', Sort.desc);
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterSortBy> sortByLastOnlineDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastOnlineDate', Sort.asc);
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterSortBy> sortByLastOnlineDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastOnlineDate', Sort.desc);
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterSortBy> sortByLastServerTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastServerTime', Sort.asc);
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterSortBy> sortByLastServerTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastServerTime', Sort.desc);
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterSortBy> sortByLastSyncedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncedAt', Sort.asc);
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterSortBy> sortByLastSyncedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncedAt', Sort.desc);
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterSortBy> sortByMaxOfflineDays() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxOfflineDays', Sort.asc);
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterSortBy> sortByMaxOfflineDaysDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxOfflineDays', Sort.desc);
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterSortBy> sortByOfflineDaysUsed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'offlineDaysUsed', Sort.asc);
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterSortBy> sortByOfflineDaysUsedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'offlineDaysUsed', Sort.desc);
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterSortBy> sortByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterSortBy> sortByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterSortBy> sortBySubscriptionEndDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subscriptionEndDate', Sort.asc);
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterSortBy> sortBySubscriptionEndDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subscriptionEndDate', Sort.desc);
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterSortBy> sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterSortBy> sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterSortBy> sortByUserId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.asc);
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterSortBy> sortByUserIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.desc);
    });
  }
}

extension LocalControlStatePersistenceQuerySortThenBy on QueryBuilder<
    LocalControlStatePersistence, LocalControlStatePersistence, QSortThenBy> {
  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterSortBy> thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterSortBy> thenByDaysUntilExpiry() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'daysUntilExpiry', Sort.asc);
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterSortBy> thenByDaysUntilExpiryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'daysUntilExpiry', Sort.desc);
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterSortBy> thenByIsOfflineLimitExceeded() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isOfflineLimitExceeded', Sort.asc);
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterSortBy> thenByIsOfflineLimitExceededDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isOfflineLimitExceeded', Sort.desc);
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterSortBy> thenByIsSubscriptionExpired() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSubscriptionExpired', Sort.asc);
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterSortBy> thenByIsSubscriptionExpiredDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSubscriptionExpired', Sort.desc);
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterSortBy> thenByIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.asc);
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterSortBy> thenByIsarIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.desc);
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterSortBy> thenByLastOnlineDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastOnlineDate', Sort.asc);
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterSortBy> thenByLastOnlineDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastOnlineDate', Sort.desc);
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterSortBy> thenByLastServerTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastServerTime', Sort.asc);
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterSortBy> thenByLastServerTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastServerTime', Sort.desc);
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterSortBy> thenByLastSyncedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncedAt', Sort.asc);
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterSortBy> thenByLastSyncedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncedAt', Sort.desc);
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterSortBy> thenByMaxOfflineDays() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxOfflineDays', Sort.asc);
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterSortBy> thenByMaxOfflineDaysDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxOfflineDays', Sort.desc);
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterSortBy> thenByOfflineDaysUsed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'offlineDaysUsed', Sort.asc);
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterSortBy> thenByOfflineDaysUsedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'offlineDaysUsed', Sort.desc);
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterSortBy> thenByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterSortBy> thenByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterSortBy> thenBySubscriptionEndDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subscriptionEndDate', Sort.asc);
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterSortBy> thenBySubscriptionEndDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subscriptionEndDate', Sort.desc);
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterSortBy> thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterSortBy> thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterSortBy> thenByUserId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.asc);
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QAfterSortBy> thenByUserIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.desc);
    });
  }
}

extension LocalControlStatePersistenceQueryWhereDistinct on QueryBuilder<
    LocalControlStatePersistence, LocalControlStatePersistence, QDistinct> {
  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QDistinct> distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QDistinct> distinctByDaysUntilExpiry() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'daysUntilExpiry');
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QDistinct> distinctById({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'id', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QDistinct> distinctByIsOfflineLimitExceeded() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isOfflineLimitExceeded');
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QDistinct> distinctByIsSubscriptionExpired() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isSubscriptionExpired');
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QDistinct> distinctByLastOnlineDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastOnlineDate');
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QDistinct> distinctByLastServerTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastServerTime');
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QDistinct> distinctByLastSyncedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastSyncedAt');
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QDistinct> distinctByMaxOfflineDays() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'maxOfflineDays');
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QDistinct> distinctByOfflineDaysUsed() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'offlineDaysUsed');
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QDistinct> distinctByStatus({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'status', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QDistinct> distinctBySubscriptionEndDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'subscriptionEndDate');
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QDistinct> distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }

  QueryBuilder<LocalControlStatePersistence, LocalControlStatePersistence,
      QDistinct> distinctByUserId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'userId', caseSensitive: caseSensitive);
    });
  }
}

extension LocalControlStatePersistenceQueryProperty on QueryBuilder<
    LocalControlStatePersistence,
    LocalControlStatePersistence,
    QQueryProperty> {
  QueryBuilder<LocalControlStatePersistence, int, QQueryOperations>
      isarIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isarId');
    });
  }

  QueryBuilder<LocalControlStatePersistence, DateTime, QQueryOperations>
      createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<LocalControlStatePersistence, int, QQueryOperations>
      daysUntilExpiryProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'daysUntilExpiry');
    });
  }

  QueryBuilder<LocalControlStatePersistence, String, QQueryOperations>
      idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<LocalControlStatePersistence, bool, QQueryOperations>
      isOfflineLimitExceededProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isOfflineLimitExceeded');
    });
  }

  QueryBuilder<LocalControlStatePersistence, bool, QQueryOperations>
      isSubscriptionExpiredProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isSubscriptionExpired');
    });
  }

  QueryBuilder<LocalControlStatePersistence, DateTime, QQueryOperations>
      lastOnlineDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastOnlineDate');
    });
  }

  QueryBuilder<LocalControlStatePersistence, DateTime, QQueryOperations>
      lastServerTimeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastServerTime');
    });
  }

  QueryBuilder<LocalControlStatePersistence, DateTime, QQueryOperations>
      lastSyncedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastSyncedAt');
    });
  }

  QueryBuilder<LocalControlStatePersistence, int, QQueryOperations>
      maxOfflineDaysProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'maxOfflineDays');
    });
  }

  QueryBuilder<LocalControlStatePersistence, int, QQueryOperations>
      offlineDaysUsedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'offlineDaysUsed');
    });
  }

  QueryBuilder<LocalControlStatePersistence, String, QQueryOperations>
      statusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'status');
    });
  }

  QueryBuilder<LocalControlStatePersistence, DateTime, QQueryOperations>
      subscriptionEndDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'subscriptionEndDate');
    });
  }

  QueryBuilder<LocalControlStatePersistence, DateTime, QQueryOperations>
      updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }

  QueryBuilder<LocalControlStatePersistence, String, QQueryOperations>
      userIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'userId');
    });
  }
}
