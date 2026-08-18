import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/bootstrap/app_bootstrap.dart';

/// Ponto de entrada do app.
///
/// Inicializa os serviços essenciais (banco local Hive, secure storage e
/// cliente HTTP) antes de montar a árvore de widgets. A primeira tela é o
/// Splash, que restaura a sessão e direciona para o Login ou para o Dashboard
/// de Entregas.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final dependencies = await AppBootstrap.create();
  runApp(App(dependencies: dependencies));
}
