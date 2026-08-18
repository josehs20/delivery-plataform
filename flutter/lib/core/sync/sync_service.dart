import 'sync_worker.dart';

/// Facade de sincronização para o app.
///
/// Garante uma execução por vez (`syncOnce` retorna `null` se já estiver
/// rodando) e devolve um [SyncResult] para a camada de estado/UI.
final class SyncService {
  SyncService(this._worker);

  final SyncWorker _worker;
  bool _running = false;

  /// Executa um ciclo de sincronização da fila local.
  ///
  /// Retorna `null` quando já há um ciclo em andamento (evita corrida).
  Future<SyncResult?> syncOnce() async {
    if (_running) return null;
    _running = true;
    try {
      return await _worker.sync();
    } finally {
      _running = false;
    }
  }
}
