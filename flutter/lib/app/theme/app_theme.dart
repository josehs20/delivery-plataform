import 'package:flutter/material.dart';

/// Tema visual do app (Material 3).
abstract final class AppTheme {
  /// Cor-semente da identidade visual (entrega/logística).
  static const Color seedColor = Color(0xFF00695C);

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(seedColor: seedColor);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
    );
  }
}