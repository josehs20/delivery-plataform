import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/delivery/presentation/delivery_list_cubit.dart';
import '../../features/delivery/presentation/screens/delivery_feed_screen.dart';

/// Dashboard de Entregas (MVP) — tela-âncora após autenticação.
///
/// Responsabilidade do app-layer: disparar a carga do feed ao entrar na tela
/// (a feature permanece puramente reativa ao cubit).
class DeliveryDashboardScreen extends StatefulWidget {
  const DeliveryDashboardScreen({super.key});

  @override
  State<DeliveryDashboardScreen> createState() =>
      _DeliveryDashboardScreenState();
}

class _DeliveryDashboardScreenState extends State<DeliveryDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<DeliveryListCubit>().load();
    });
  }

  @override
  Widget build(BuildContext context) => const DeliveryFeedScreen();
}