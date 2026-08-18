import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/api_exception.dart';
import '../domain/delivery.dart';
import '../domain/use_cases.dart';
import 'delivery_list_state.dart';

/// Orquestra o feed de entregas disponíveis.
class DeliveryListCubit extends Cubit<DeliveryListState> {
  DeliveryListCubit(this._listAvailable, this._acceptOffer)
      : super(const DeliveryListLoading());

  final ListAvailableDeliveries _listAvailable;
  final AcceptOffer _acceptOffer;

  List<Delivery> get _currentDeliveries => switch (state) {
        DeliveryListLocal(:final deliveries) => deliveries,
        DeliveryListSyncing(:final deliveries) => deliveries,
        DeliveryListSynced(:final deliveries) => deliveries,
        DeliveryListFailure(:final deliveries?) => deliveries,
        _ => const [],
      };

  /// Carga inicial (ou após falha).
  Future<void> load() async {
    emit(const DeliveryListLoading());
    try {
      final result = await _listAvailable.call();
      _emitFromResult(result.deliveries, result.fromCache);
    } on ApiException catch (error) {
      emit(DeliveryListFailure(error.message));
    } catch (_) {
      emit(const DeliveryListFailure('Não foi possível carregar as entregas.'));
    }
  }

  /// Recarrega mantendo o conteúdo atual visível (pull-to-refresh).
  Future<void> refresh() async {
    final current = _currentDeliveries;
    emit(DeliveryListSyncing(deliveries: current));
    try {
      final result = await _listAvailable.call();
      _emitFromResult(result.deliveries, result.fromCache);
    } on ApiException catch (error) {
      emit(DeliveryListFailure(error.message, deliveries: current));
    } catch (_) {
      emit(DeliveryListFailure(
        'Não foi possível atualizar as entregas.',
        deliveries: current,
      ));
    }
  }

  /// Aceita a oferta pendente da entrega (exige oferta e conectividade).
  Future<void> accept(Delivery delivery) async {
    final pendingOffer = delivery.pendingOffer;
    if (pendingOffer == null) {
      emit(DeliveryListFailure(
        'Esta entrega não possui uma oferta pendente.',
        deliveries: _currentDeliveries,
      ));
      return;
    }

    final current = _currentDeliveries;
    emit(DeliveryListSyncing(deliveries: current));
    try {
      await _acceptOffer.call(deliveryId: delivery.id, offerId: pendingOffer.id);
      // Após o aceite a entrega sai do feed de disponíveis: recarrega.
      await refresh();
    } on ApiException catch (error) {
      emit(DeliveryListFailure(error.message, deliveries: current));
    } catch (_) {
      emit(DeliveryListFailure(
        'Não foi possível aceitar a oferta.',
        deliveries: current,
      ));
    }
  }

  void _emitFromResult(List<Delivery> deliveries, bool fromCache) {
    if (fromCache) {
      emit(DeliveryListLocal(deliveries: deliveries));
    } else {
      emit(DeliveryListSynced(deliveries: deliveries));
    }
  }
}
