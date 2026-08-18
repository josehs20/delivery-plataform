import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../features/delivery/domain/delivery.dart';
import '../../../../features/delivery/domain/new_delivery.dart';
import '../business_delivery_cubit.dart';
import '../business_delivery_state.dart';

/// Formulário de criação de nova entrega (`POST /deliveries`).
///
/// Coleta origem/destino (com coordenadas), destinatário, itens, precificação
/// e prazo de coleta — conforme o `CreateDeliveryRequest` do Laravel. O
/// backend continua sendo a autoridade de validação/preço.
class CreateDeliveryScreen extends StatefulWidget {
  const CreateDeliveryScreen({super.key});

  @override
  State<CreateDeliveryScreen> createState() => _CreateDeliveryScreenState();
}

class _CreateDeliveryScreenState extends State<CreateDeliveryScreen> {
  final _formKey = GlobalKey<FormState>();

  // Origem.
  final _originAddress = TextEditingController();
  final _originLatitude = TextEditingController();
  final _originLongitude = TextEditingController();
  final _originReference = TextEditingController();

  // Destino.
  final _destinationAddress = TextEditingController();
  final _destinationLatitude = TextEditingController();
  final _destinationLongitude = TextEditingController();
  final _destinationReference = TextEditingController();

  // Destinatário.
  final _recipientName = TextEditingController();
  final _recipientPhone = TextEditingController();

  // Itens (dinâmicos).
  final List<_ItemForm> _items = [_ItemForm()];

  // Precificação.
  DeliveryPricingMode _pricingMode = DeliveryPricingMode.calculated;
  final _manualValue = TextEditingController();

  DateTime? _pickupDeadline;

  @override
  void dispose() {
    _originAddress.dispose();
    _originLatitude.dispose();
    _originLongitude.dispose();
    _originReference.dispose();
    _destinationAddress.dispose();
    _destinationLatitude.dispose();
    _destinationLongitude.dispose();
    _destinationReference.dispose();
    _recipientName.dispose();
    _recipientPhone.dispose();
    _manualValue.dispose();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  void _addItem() => setState(() => _items.add(_ItemForm()));

  void _removeItem(int index) {
    if (_items.length <= 1) return;
    setState(() => _items.removeAt(index).dispose());
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final delivery = NewDelivery(
      origin: DeliveryAddress(
        address: _originAddress.text.trim(),
        latitude: double.tryParse(_originLatitude.text.trim()),
        longitude: double.tryParse(_originLongitude.text.trim()),
        reference: _emptyToNull(_originReference.text),
      ),
      destination: DeliveryAddress(
        address: _destinationAddress.text.trim(),
        latitude: double.tryParse(_destinationLatitude.text.trim()),
        longitude: double.tryParse(_destinationLongitude.text.trim()),
        reference: _emptyToNull(_destinationReference.text),
      ),
      recipient: Recipient(
        name: _recipientName.text.trim(),
        phone: _recipientPhone.text.trim(),
      ),
      items: _items
          .map(
            (item) => DeliveryItem(
              name: item.name.text.trim(),
              category: item.category,
              quantity: int.tryParse(item.quantity.text.trim()) ?? 1,
              approximateWeight: double.tryParse(item.weight.text.trim()),
              notes: _emptyToNull(item.notes.text),
            ),
          )
          .toList(growable: false),
      pricingMode: _pricingMode,
      manualValue: _pricingMode == DeliveryPricingMode.manual
          ? _manualValue.text.trim()
          : null,
      pickupDeadline: _pickupDeadline,
    );

    context.read<CreateDeliveryCubit>().submit(delivery);
  }

  static String? _emptyToNull(String value) {
    final v = value.trim();
    return v.isEmpty ? null : v;
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nova entrega')),
      body: BlocListener<CreateDeliveryCubit, CreateDeliveryState>(
        listener: (context, state) {
          if (state is CreateDeliverySuccess) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                const SnackBar(content: Text('Entrega criada como rascunho.')),
              );
            Navigator.of(context).pushReplacementNamed(
              AppRoutes.businessDeliveryDetailFor(state.delivery.id),
            );
          } else if (state is CreateDeliveryFailure) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        child: BlocBuilder<CreateDeliveryCubit, CreateDeliveryState>(
          buildWhen: (previous, current) =>
              current is CreateDeliverySubmitting ||
              previous is CreateDeliverySubmitting,
          builder: (context, state) {
            final submitting = state is CreateDeliverySubmitting;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Section(
                      title: 'Origem',
                      children: [
                        _textField(
                          _originAddress,
                          'Endereço de coleta',
                          validator: _required('Informe o endereço de coleta.'),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: _textField(
                                _originLatitude,
                                'Latitude',
                                keyboardType: TextInputType.number,
                                validator: _latValidator,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _textField(
                                _originLongitude,
                                'Longitude',
                                keyboardType: TextInputType.number,
                                validator: _lonValidator,
                              ),
                            ),
                          ],
                        ),
                        _textField(_originReference, 'Referência (opcional)'),
                      ],
                    ),
                    _Section(
                      title: 'Destino',
                      children: [
                        _textField(
                          _destinationAddress,
                          'Endereço de entrega',
                          validator:
                              _required('Informe o endereço de entrega.'),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: _textField(
                                _destinationLatitude,
                                'Latitude',
                                keyboardType: TextInputType.number,
                                validator: _latValidator,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _textField(
                                _destinationLongitude,
                                'Longitude',
                                keyboardType: TextInputType.number,
                                validator: _lonValidator,
                              ),
                            ),
                          ],
                        ),
                        _textField(
                          _destinationReference,
                          'Referência (opcional)',
                        ),
                      ],
                    ),
                    _Section(
                      title: 'Destinatário',
                      children: [
                        _textField(
                          _recipientName,
                          'Nome',
                          validator: _required('Informe o nome do destinatário.'),
                        ),
                        _textField(
                          _recipientPhone,
                          'Telefone',
                          keyboardType: TextInputType.phone,
                          validator: _required('Informe o telefone.'),
                        ),
                      ],
                    ),
                    _Section(
                      title: 'Itens',
                      children: [
                        for (var i = 0; i < _items.length; i++)
                          _buildItemField(i),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: _addItem,
                            icon: const Icon(Icons.add),
                            label: const Text('Adicionar item'),
                          ),
                        ),
                      ],
                    ),
                    _Section(
                      title: 'Precificação',
                      children: [
                        SegmentedButton<DeliveryPricingMode>(
                          segments: const [
                            ButtonSegment(
                              value: DeliveryPricingMode.calculated,
                              label: Text('Calculado'),
                              icon: Icon(Icons.auto_awesome),
                            ),
                            ButtonSegment(
                              value: DeliveryPricingMode.manual,
                              label: Text('Manual'),
                              icon: Icon(Icons.edit),
                            ),
                          ],
                          selected: {_pricingMode},
                          onSelectionChanged: (selection) => setState(
                            () => _pricingMode = selection.first,
                          ),
                        ),
                        if (_pricingMode == DeliveryPricingMode.manual) ...[
                          const SizedBox(height: 12),
                          _textField(
                            _manualValue,
                            'Valor (R\$)',
                            keyboardType:
                                const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: (value) {
                              final v = value?.trim() ?? '';
                              if (v.isEmpty) return 'Informe o valor.';
                              if (double.tryParse(v) == null) {
                                return 'Valor inválido.';
                              }
                              return null;
                            },
                          ),
                        ],
                      ],
                    ),
                    _Section(
                      title: 'Prazo de coleta',
                      children: [
                        OutlinedButton.icon(
                          onPressed: _pickDeadline,
                          icon: const Icon(Icons.schedule),
                          label: Text(
                            _pickupDeadline == null
                                ? 'Selecionar prazo (obrigatório)'
                                : 'Prazo: ${DateFormat("dd/MM/yyyy HH:mm").format(_pickupDeadline!.toLocal())}',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: submitting ? null : _submit,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: submitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.5),
                            )
                          : const Text('Criar entrega'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildItemField(int index) {
    final item = _items[index];
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Item ${index + 1}',
                      style: Theme.of(context).textTheme.titleSmall),
                ),
                IconButton(
                  tooltip: 'Remover item',
                  onPressed: _items.length > 1 ? () => _removeItem(index) : null,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            _textField(
              item.name,
              'Nome do item',
              validator: _required('Informe o nome do item.'),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: item.category,
              decoration: const InputDecoration(
                labelText: 'Categoria',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'GENERAL', child: Text('Geral')),
                DropdownMenuItem(value: 'FRAGILE', child: Text('Frágil')),
                DropdownMenuItem(value: 'FROZEN', child: Text('Congelado')),
                DropdownMenuItem(value: 'HAZMAT', child: Text('Perigoso')),
              ],
              onChanged: (value) =>
                  setState(() => item.category = value ?? 'GENERAL'),
              validator: _required('Selecione a categoria.'),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _textField(
                    item.quantity,
                    'Quantidade',
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      final v = int.tryParse(value?.trim() ?? '');
                      if (v == null || v < 1) return 'Mínimo 1.';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _textField(
                    item.weight,
                    'Peso aprox. (kg)',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (value) {
                      final v = double.tryParse(value?.trim() ?? '');
                      if (v == null || v < 0.1) return 'Mínimo 0.1 kg.';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _textField(item.notes, 'Observações (opcional)'),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now.add(const Duration(hours: 1))),
    );
    if (time == null || !mounted) return;

    final local = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    if (!local.isAfter(now)) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('O prazo deve ser no futuro.')),
        );
      return;
    }

    setState(() => _pickupDeadline = local.toUtc());
  }

  Widget _textField(
    TextEditingController controller,
    String label, {
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: validator,
      ),
    );
  }

  String? Function(String?)? _required(String message) =>
      (value) => (value?.trim() ?? '').isEmpty ? message : null;

  String? _latValidator(String? value) {
    final v = double.tryParse(value?.trim() ?? '');
    if (v == null || v < -90 || v > 90) return 'Latitude inválida.';
    return null;
  }

  String? _lonValidator(String? value) {
    final v = double.tryParse(value?.trim() ?? '');
    if (v == null || v < -180 || v > 180) return 'Longitude inválida.';
    return null;
  }
}

/// Estado do formulário de um item (controladores + categoria).
class _ItemForm {
  final name = TextEditingController();
  final quantity = TextEditingController(text: '1');
  final weight = TextEditingController();
  final notes = TextEditingController();
  String category = 'GENERAL';

  void dispose() {
    name.dispose();
    quantity.dispose();
    weight.dispose();
    notes.dispose();
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}

