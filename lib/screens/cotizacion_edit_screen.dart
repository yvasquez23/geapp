import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/cotizacion.dart';
import '../models/cotizacion_det.dart';
import '../models/articulo.dart';
import '../providers/auth_provider.dart';
import '../providers/cotizacion_provider.dart';

// Línea de detalle con datos precargables
class _LineItem {
  Articulo? articulo;
  final TextEditingController qtyCtrl;
  final TextEditingController precioCtrl;

  _LineItem({Articulo? articulo, String qty = '', String precio = ''})
      : articulo   = articulo,
        qtyCtrl    = TextEditingController(text: qty),
        precioCtrl = TextEditingController(text: precio);

  double get subtotal =>
      (double.tryParse(qtyCtrl.text) ?? 0) *
      (double.tryParse(precioCtrl.text) ?? 0);

  void dispose() {
    qtyCtrl.dispose();
    precioCtrl.dispose();
  }
}

class CotizacionEditScreen extends StatefulWidget {
  const CotizacionEditScreen({super.key});

  @override
  State<CotizacionEditScreen> createState() => _CotizacionEditScreenState();
}

class _CotizacionEditScreenState extends State<CotizacionEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dateFmt = DateFormat('dd/MM/yyyy');
  final _currFmt = NumberFormat.currency(locale: 'es_MX', symbol: '\$');

  late Cotizacion _cot;
  DateTime _fecha = DateTime.now();
  final List<_LineItem> _items = [];
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _cot  = ModalRoute.of(context)!.settings.arguments as Cotizacion;
      _fecha = _cot.cotizacionFecha ?? DateTime.now();
      // Cargar artículos y detalles existentes
      final prov = context.read<CotizacionProvider>();
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await prov.fetchArticulos();
        await prov.fetchDetalles(_cot.cotizacionId);
        if (mounted) _precargarDetalles(prov.detalles, prov.articulos);
      });
    }
  }

  void _precargarDetalles(
      List<CotizacionDet> detalles, List<Articulo> articulos) {
    setState(() {
      _items.clear();
      for (final det in detalles) {
        // Buscar el artículo completo en la lista; si no está, construir uno mínimo
        final art = articulos.firstWhere(
          (a) => a.articuloId == det.articuloId,
          orElse: () => Articulo(
            articuloId:   det.articuloId ?? 0,
            articuloCd:   det.articuloCd,
            articuloDesc: det.articuloDesc,
          ),
        );
        _items.add(_LineItem(
          articulo: det.articuloId != null ? art : null,
          qty:      det.cotizacionQty?.toStringAsFixed(2) ?? '',
          precio:   det.cotizacionPrecio?.toStringAsFixed(2) ?? '',
        ));
      }
    });
  }

  @override
  void dispose() {
    for (final item in _items) item.dispose();
    super.dispose();
  }

  void _addItem() => setState(() => _items.add(_LineItem()));

  void _removeItem(int index) {
    setState(() {
      _items[index].dispose();
      _items.removeAt(index);
    });
  }

  double get _total => _items.fold(0.0, (sum, i) => sum + i.subtotal);

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _fecha = picked);
  }

  Future<Articulo?> _selectArticulo(List<Articulo> articulos) async {
    final search   = TextEditingController();
    List<Articulo> filtered = articulos;

    return showDialog<Articulo>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: const Text('Seleccionar artículo'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: Column(
              children: [
                TextField(
                  controller: search,
                  decoration: const InputDecoration(
                    hintText: 'Buscar por código o descripción...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (v) => setStateDialog(() {
                    filtered = articulos
                        .where((a) =>
                            (a.articuloCd ?? '')
                                .toLowerCase()
                                .contains(v.toLowerCase()) ||
                            (a.articuloDesc ?? '')
                                .toLowerCase()
                                .contains(v.toLowerCase()))
                        .toList();
                  }),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: filtered.isEmpty
                      ? const Center(child: Text('Sin resultados'))
                      : ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final art = filtered[i];
                            return ListTile(
                              dense: true,
                              leading: CircleAvatar(
                                radius: 16,
                                backgroundColor: const Color(0xFF1A237E)
                                    .withValues(alpha: 0.1),
                                child: Text(
                                  '${art.articuloId}',
                                  style: const TextStyle(
                                      fontSize: 10,
                                      color: Color(0xFF1A237E)),
                                ),
                              ),
                              title: Text(art.articuloCd ?? '',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13)),
                              subtitle: Text(art.articuloDesc ?? '',
                                  style: const TextStyle(fontSize: 12)),
                              onTap: () => Navigator.pop(ctx, art),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    if (_items.isEmpty) {
      _showSnack('Agrega al menos un artículo', Colors.orange);
      return;
    }
    if (_items.any((i) => i.articulo == null)) {
      _showSnack('Selecciona el artículo en cada línea', Colors.orange);
      return;
    }

    final auth = context.read<AuthProvider>();
    final prov = context.read<CotizacionProvider>();

    final cotizacion = Cotizacion(
      cotizacionId:      _cot.cotizacionId,
      cotizacionFecha:   _fecha,
      clienteId:         _cot.clienteId,
      cotizacionBalance: _total,
    );

    final items = _items
        .map((i) => <String, dynamic>{
              'articulo_ID': i.articulo?.articuloId,
              'qty':         double.tryParse(i.qtyCtrl.text) ?? 0.0,
              'precio':      double.tryParse(i.precioCtrl.text) ?? 0.0,
              'comentario':  null,
            })
        .toList();

    final success = await prov.updateCotizacion(
      _cot.cotizacionId,
      cotizacion,
      items,
      clienteNombre: auth.usuario,
    );

    if (mounted) {
      if (success) {
        _showSnack('Cotización actualizada', Colors.green);
        Navigator.pop(context, true); // true = hubo cambios
      } else {
        _showSnack(prov.error ?? 'Error al actualizar', Colors.red);
      }
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final prov = context.watch<CotizacionProvider>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        title: Text('Editar Cotización #${_cot.cotizacionId}'),
      ),
      body: prov.isLoading && _items.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ── Información general ─────────────────────────────────────
                  _SectionTitle('Información general'),
                  const SizedBox(height: 12),

                  // Fecha
                  InkWell(
                    onTap: _pickDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Fecha de cotización',
                        prefixIcon: Icon(Icons.calendar_today),
                        border: OutlineInputBorder(),
                      ),
                      child: Text(_dateFmt.format(_fecha)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Cliente (solo lectura)
                  InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Cliente',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Color(0xFFF5F5F5),
                    ),
                    child: Text(
                      auth.usuario ?? 'Usuario',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Artículos ───────────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _SectionTitle('Artículos (${_items.length})'),
                      TextButton.icon(
                        onPressed: _addItem,
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text('Agregar'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (_items.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: const Center(
                        child: Text('Sin artículos. Toca "Agregar" para añadir.',
                            style: TextStyle(color: Colors.grey)),
                      ),
                    ),

                  // Lista de artículos
                  ...List.generate(_items.length, (i) {
                    final lineItem = _items[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Línea ${i + 1}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1A237E))),
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline,
                                      color: Colors.red, size: 20),
                                  onPressed: () => _removeItem(i),
                                ),
                              ],
                            ),

                            // Selector de artículo
                            GestureDetector(
                              onTap: prov.articulos.isEmpty
                                  ? null
                                  : () async {
                                      final selected = await _selectArticulo(
                                          prov.articulos);
                                      if (selected != null) {
                                        setState(
                                            () => lineItem.articulo = selected);
                                      }
                                    },
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 14),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                      color: lineItem.articulo == null
                                          ? Colors.grey.shade400
                                          : const Color(0xFF1A237E)),
                                  borderRadius: BorderRadius.circular(6),
                                  color: lineItem.articulo == null
                                      ? Colors.white
                                      : const Color(0xFF1A237E)
                                          .withValues(alpha: 0.04),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.inventory_2_outlined,
                                        size: 18,
                                        color: lineItem.articulo == null
                                            ? Colors.grey
                                            : const Color(0xFF1A237E)),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: lineItem.articulo == null
                                          ? Text(
                                              'Toca para seleccionar artículo',
                                              style: TextStyle(
                                                  color: Colors.grey.shade500))
                                          : Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  lineItem.articulo!
                                                          .articuloCd ??
                                                      '',
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 13,
                                                      color:
                                                          Color(0xFF1A237E)),
                                                ),
                                                Text(
                                                  lineItem.articulo!
                                                          .articuloDesc ??
                                                      '',
                                                  style: const TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.black54),
                                                ),
                                              ],
                                            ),
                                    ),
                                    const Icon(Icons.arrow_drop_down,
                                        color: Colors.grey),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Cantidad y Precio
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: lineItem.qtyCtrl,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: true),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                          RegExp(r'^\d+\.?\d{0,2}'))
                                    ],
                                    decoration: const InputDecoration(
                                      labelText: 'Cantidad',
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                    ),
                                    onChanged: (_) => setState(() {}),
                                    validator: (v) => v == null || v.isEmpty
                                        ? 'Requerido'
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextFormField(
                                    controller: lineItem.precioCtrl,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: true),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                          RegExp(r'^\d+\.?\d{0,2}'))
                                    ],
                                    decoration: const InputDecoration(
                                      labelText: 'Precio unitario',
                                      prefixText: '\$ ',
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                    ),
                                    onChanged: (_) => setState(() {}),
                                    validator: (v) => v == null || v.isEmpty
                                        ? 'Requerido'
                                        : null,
                                  ),
                                ),
                              ],
                            ),

                            if (lineItem.subtotal > 0)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    'Subtotal: ${_currFmt.format(lineItem.subtotal)}',
                                    style: const TextStyle(
                                        color: Color(0xFF1A237E),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }),

                  // ── Total ───────────────────────────────────────────────────
                  if (_items.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A237E).withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color:
                                const Color(0xFF1A237E).withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total cotización:',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                          Text(
                            _currFmt.format(_total),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                color: Color(0xFF1A237E)),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // ── Botón guardar ───────────────────────────────────────────
                  SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A237E),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: prov.isLoading ? null : _guardar,
                      icon: prov.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.save_outlined),
                      label: Text(prov.isLoading
                          ? 'Guardando...'
                          : 'Guardar cambios'),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A237E)),
      );
}
