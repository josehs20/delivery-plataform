import '../../../core/models/json_utils.dart';
import '../domain/admin_models.dart';

/// Conversão dos envelopes administrativos (JSON → models de domínio).
///
/// Regra: DTOs espelham o backend e campos desconhecidos são ignorados com
/// segurança. Nenhuma regra de negócio é decidida aqui.
final class AdminMappers {
  const AdminMappers._();

  /// Converte uma listagem paginada: `{"<key>": [...], "pagination": {...}}`.
  static AdminPage<T> pageOf<T>(
    Map<String, dynamic> data,
    String key,
    T Function(Map<String, dynamic>) parse,
  ) {
    final raw = data[key];
    final items = raw is List
        ? raw
            .whereType<Map>()
            .map((e) => parse(e.map((k, v) => MapEntry(k.toString(), v))))
            .toList(growable: false)
        : List<T>.empty(growable: false);

    return AdminPage(
      items: items,
      pagination: AdminPagination.fromJson(
        JsonUtils.mapOrEmpty(data['pagination']),
      ),
    );
  }
}
