import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/api_exception.dart';
import '../../delivery/domain/new_delivery.dart';
import '../../delivery/domain/use_cases.dart';
import 'business_delivery_state.dart';

/// Orquestra a criação de uma nova entrega (`POST /deliveries`).
class CreateDeliveryCubit extends Cubit<CreateDeliveryState> {
  CreateDeliveryCubit(this._createDelivery)
      : super(const CreateDeliveryIdle());

  final CreateDelivery _createDelivery;

  Future<void> submit(NewDelivery delivery) async {
    emit(const CreateDeliverySubmitting());
    try {
      final result = await _createDelivery.call(delivery: delivery);
      emit(CreateDeliverySuccess(delivery: result.delivery));
    } on ApiException catch (error) {
      emit(CreateDeliveryFailure(error.message));
    } catch (_) {
      emit(const CreateDeliveryFailure(
        'Não foi possível criar a entrega. Tente novamente.',
      ));
    }
  }
}
