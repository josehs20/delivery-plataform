import 'package:hive/hive.dart';

import '../models/delivery_dto.dart';

/// Cache local de entregas sincronizadas (estado do servidor).
///
/// IMPORTANTE: é um CACHE operacional — NUNCA é fonte de verdade para estado
/// crítico ou financeiro. O servidor reconcilia durante a sincronização.
abstract interface class DeliveryCacheRepository {
  Future<void> upsert(DeliveryDto delivery);
  Future<void> upsertAll(Iterable<DeliveryDto> deliveries);
  Future<DeliveryDto?> byId(String id);
  Future<List<DeliveryDto>> all();
  Future<List<DeliveryDto>> byStatus(Set<String> statuses);
  Future<void> remove(String id);
  Future<void> clear();
}

/// Implementação com Hive (box `deliveries_cache`, chave = id da entrega).
final class HiveDeliveryCacheRepository implements DeliveryCacheRepository {
  HiveDeliveryCacheRepository(this._box);

  final Box<Map<dynamic, dynamic>> _box;

  @override
  Future<void> upsert(DeliveryDto delivery) async {
    await _box.put(delivery.id, delivery.toJson());
  }

  @override
  Future<void> upsertAll(Iterable<DeliveryDto> deliveries) async {
    await _box.putAll({
      for (final delivery in deliveries) delivery.id: delivery.toJson(),
    });
  }

  @override
  Future<DeliveryDto?> byId(String id) async {
    final raw = _box.get(id);
    if (raw is! Map) return null;
    return DeliveryDto.fromJson(_asStringMap(raw));
  }

  @override
  Future<List<DeliveryDto>> all() async {
    return _box.values
        .whereType<Map>()
        .map((raw) => DeliveryDto.fromJson(_asStringMap(raw)))
        .toList(growable: false);
  }

  @override
  Future<List<DeliveryDto>> byStatus(Set<String> statuses) async {
    final deliveries = await all();
    return deliveries
        .where((delivery) => statuses.contains(delivery.status))
        .toList(growable: false);
  }

  @override
  Future<void> remove(String id) async {
    await _box.delete(id);
  }

  @override
  Future<void> clear() async {
    await _box.clear();
  }

  static Map<String, dynamic> _asStringMap(Map<dynamic, dynamic> raw) {
    return raw.map((key, value) => MapEntry(key.toString(), value));
  }
}
