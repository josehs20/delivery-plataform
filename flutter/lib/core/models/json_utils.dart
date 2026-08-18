/// Helpers de conversão JSON tolerante compartilhados pelos DTOs.
///
/// Centraliza o parsing defensivo de campos ausentes/nulos/desconhecidos
/// (regra: DTOs refletem o OpenAPI e campos desconhecidos devem ser ignorados
/// com segurança). Nenhuma regra de negócio é executada aqui.
///
/// Convenções:
/// - Datas são normalizadas para UTC.
/// - Valores monetários permanecem como String (ex.: `"25.00"`); nunca como
///   double autoritativo (regra: monetário sempre string + currency).
final class JsonUtils {
  const JsonUtils._();

  /// Parseia uma data ISO-8601 (ex.: `2026-08-16T12:10:00Z`) para UTC.
  /// Retorna `null` quando ausente/indefinido.
  static DateTime? dateTime(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value)?.toUtc();
  }

  /// Converte qualquer valor para String ou `null` quando ausente.
  /// Números são aceitos defensivamente (ex.: `25` → `"25"`).
  static String? stringOrNull(Object? value) {
    if (value == null) return null;
    return value.toString();
  }

  /// Como [stringOrNull], mas com fallback para campos não nulos.
  static String stringOrDefault(Object? value, {String fallback = ''}) {
    return stringOrNull(value) ?? fallback;
  }

  static int? intOrNull(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static double? doubleOrNull(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static bool? boolOrNull(Object? value) => value is bool ? value : null;

  static List<String> stringList(Object? value) {
    if (value is! List) return const [];
    return value
        .map((e) => e?.toString() ?? '')
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
  }

  static Map<String, dynamic> mapOrEmpty(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val));
    }
    return const {};
  }
}
