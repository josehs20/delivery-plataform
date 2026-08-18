import '../../../core/models/delivery_dto.dart';
import '../../../core/models/offer_dto.dart';
import '../domain/delivery.dart';

/// Converte o DTO de transporte [DeliveryDto] na entidade de domínio
/// [Delivery]. A conversão fica restrita ao data layer.
final class DeliveryMapper {
  const DeliveryMapper._();

  static Delivery fromDto(DeliveryDto dto) {
    return Delivery(
      id: dto.id,
      status: DeliveryStatus.fromWire(dto.status),
      pricingMode: dto.pricingMode,
      currency: dto.currency,
      suggestedAmount: dto.suggestedAmount,
      merchantOfferedAmount: dto.merchantOfferedAmount,
      acceptedAmount: dto.acceptedAmount,
      pickupDeadline: dto.pickupDeadline,
      origin: _address(dto.origin),
      destination: _address(dto.destination),
      recipient: dto.recipient == null
          ? null
          : Recipient(
              name: dto.recipient!.name,
              phone: dto.recipient!.phone,
              reference: dto.recipient!.reference,
            ),
      items: dto.items.map(_item).toList(growable: false),
      offers: dto.offers.map(_offer).toList(growable: false),
      createdAt: dto.createdAt,
      updatedAt: dto.updatedAt,
    );
  }

  static DeliveryAddress? _address(DeliveryAddressDto? dto) {
    if (dto == null) return null;
    return DeliveryAddress(
      address: dto.address,
      latitude: dto.latitude,
      longitude: dto.longitude,
      reference: dto.reference,
    );
  }

  static DeliveryItem _item(DeliveryItemDto dto) {
    return DeliveryItem(
      id: dto.id,
      name: dto.name,
      description: dto.description,
      category: dto.category,
      quantity: dto.quantity,
      approximateWeight: dto.approximateWeight,
      notes: dto.notes,
    );
  }

  static Offer _offer(OfferDto dto) {
    return Offer(
      id: dto.id,
      deliveryId: dto.deliveryId,
      driverId: dto.driverId,
      status: dto.status,
      offeredAmount: dto.offeredAmount,
    );
  }
}
