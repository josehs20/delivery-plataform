import 'dart:io';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../sync/hive_sync_queue.dart';
import '../sync/sync_queue.dart';
import 'delivery_cache_repository.dart';

/// Banco local (Hive) — dono das boxes de cache de entregas, da fila de sync
/// e dos metadados do app.
///
/// Requisitos (docs/flutter/docs/06-local-database.md): schema versionado,
/// gravações atômicas, persistência entre restarts. O dado local NÃO é fonte
/// de verdade para estado crítico — o servidor reconcilia.
final class LocalDatabase {
  LocalDatabase._(this._deliveries, this._syncQueue, this._meta);

  /// Nomes das boxes (esquema local).
  static const deliveriesBoxName = 'deliveries_cache';
  static const syncQueueBoxName = 'sync_queue';
  static const metaBoxName = 'app_meta';

  final Box<Map<dynamic, dynamic>> _deliveries;
  final Box<Map<dynamic, dynamic>> _syncQueue;
  final Box<dynamic> _meta;

  /// Abre (ou recupera) o banco local. Em testes, forneça um [directory].
  static Future<LocalDatabase> open({Directory? directory}) async {
    if (directory != null) {
      Hive.init(directory.path);
    } else {
      await Hive.initFlutter();
    }

    final deliveries = await Hive.openBox<Map<dynamic, dynamic>>(
      deliveriesBoxName,
    );
    final syncQueue = await Hive.openBox<Map<dynamic, dynamic>>(
      syncQueueBoxName,
    );
    final meta = await Hive.openBox<dynamic>(metaBoxName);

    return LocalDatabase._(deliveries, syncQueue, meta);
  }

  /// Repositório de cache de entregas sincronizadas.
  DeliveryCacheRepository deliveryCache() =>
      HiveDeliveryCacheRepository(_deliveries);

  /// Fila durável de operações offline.
  SyncQueue syncQueue() => HiveSyncQueue(_syncQueue);

  /// Identificador estável do dispositivo (gerado uma vez e persistido).
  ///
  /// Usado no `device_id` do contrato `POST /sync/batch` para reconciliação.
  Future<String> deviceId() async {
    const key = 'device_id';
    final existing = _meta.get(key);
    if (existing is String && existing.isNotEmpty) return existing;

    final id = const Uuid().v4();
    await _meta.put(key, id);
    return id;
  }

  Future<void> close() async {
    await Future.wait([
      _deliveries.close(),
      _syncQueue.close(),
      _meta.close(),
    ]);
  }
}
