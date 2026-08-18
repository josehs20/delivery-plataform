import 'package:delivery_app/features/delivery/presentation/delivery_labels.dart';
import 'package:delivery_app/features/delivery/domain/delivery.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatCurrency', () {
    /// O intl pt_BR usa espaço não separável (U+00A0) entre símbolo e valor.
    String normalize(String value) =>
        value.replaceAll('\u00A0', ' ').replaceAll('\u202F', ' ');

    test('formats BRL with pt_BR locale', () {
      expect(normalize(formatCurrency('25.00', 'BRL')), 'R\$ 25,00');
    });

    test('formats large values with thousand separators', () {
      expect(normalize(formatCurrency('1234.5', 'BRL')), 'R\$ 1.234,50');
    });

    test('returns a dash when amount is null/invalid', () {
      expect(formatCurrency(null, 'BRL'), '—');
      expect(formatCurrency('abc', 'BRL'), '—');
    });

    test('uses the currency code as symbol when not BRL', () {
      final formatted = formatCurrency('10.00', 'USD');
      expect(formatted.replaceAll('\u00A0', ' ').replaceAll('\u202F', ' '),
          'USD 10,00');
    });
  });

  group('deliveryStatusLabel', () {
    test('maps key statuses to product terminology', () {
      expect(deliveryStatusLabel(DeliveryStatus.open), 'Disponível');
      expect(deliveryStatusLabel(DeliveryStatus.atPickup), 'Na coleta');
      expect(deliveryStatusLabel(DeliveryStatus.pickedUp), 'Coletada');
      expect(deliveryStatusLabel(DeliveryStatus.delivered), 'Entregue');
      expect(deliveryStatusLabel(DeliveryStatus.cancelled), 'Cancelada');
      expect(deliveryStatusLabel(DeliveryStatus.unknown), 'Desconhecido');
    });
  });
}
