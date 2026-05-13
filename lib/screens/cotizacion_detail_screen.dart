import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../models/cotizacion.dart';
import '../providers/auth_provider.dart';
import '../providers/cotizacion_provider.dart';
import '../utils/cotizacion_pdf.dart';

class CotizacionDetailScreen extends StatefulWidget {
  const CotizacionDetailScreen({super.key});

  @override
  State<CotizacionDetailScreen> createState() => _CotizacionDetailScreenState();
}

class _CotizacionDetailScreenState extends State<CotizacionDetailScreen> {
  final _currFmt = NumberFormat.currency(locale: 'es_MX', symbol: '\$');
  final _dateFmt = DateFormat('dd/MM/yyyy');
  bool _loaded   = false;
  // Guardamos referencia antes de que el widget se desactive
  CotizacionProvider? _prov;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _prov = context.read<CotizacionProvider>();
    if (!_loaded) {
      _loaded = true;
      final cot = ModalRoute.of(context)!.settings.arguments as Cotizacion;
      _prov!.fetchDetalles(cot.cotizacionId);
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _imprimir(Cotizacion cot, List detalles, String? nombre) async {
    await Printing.layoutPdf(
      onLayout: (_) async => await CotizacionPdf.generar(
        cot:           cot,
        detalles:      detalles.cast(),
        clienteNombre: nombre,
      ),
      name: 'Cotizacion_${cot.cotizacionId}.pdf',
    );
  }

  Future<void> _compartir(
      BuildContext ctx, Cotizacion cot, List detalles, String? nombre) async {
    // Generar y guardar en archivo temporal
    File file;
    try {
      file = await CotizacionPdf.guardarTemporal(
        cot:           cot,
        detalles:      detalles.cast(),
        clienteNombre: nombre,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(content: Text('Error al generar PDF: $e'),
              backgroundColor: Colors.red),
        );
      }
      return;
    }

    // Compartir — el usuario elige la app (WhatsApp, email, etc.)
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/pdf')],
      text:    'Cotización #${cot.cotizacionId} - GEAPP',
      subject: 'Cotización #${cot.cotizacionId}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final cot    = ModalRoute.of(context)!.settings.arguments as Cotizacion;
    final prov   = context.watch<CotizacionProvider>();
    final nombre = context.read<AuthProvider>().usuario;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        title: Text('Cotización #${cot.cotizacionId}'),
        actions: [
          // Imprimir / vista previa PDF
          IconButton(
            tooltip: 'Imprimir',
            icon: const Icon(Icons.print_outlined),
            onPressed: prov.detalles.isEmpty
                ? null
                : () => _imprimir(cot, prov.detalles, nombre),
          ),
          // Compartir (WhatsApp, email, etc.)
          IconButton(
            tooltip: 'Compartir',
            icon: const Icon(Icons.share_outlined),
            onPressed: prov.detalles.isEmpty
                ? null
                : () => _compartir(context, cot, prov.detalles, nombre),
          ),
          // Editar
          IconButton(
            tooltip: 'Editar cotización',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.pushNamed(
              context,
              '/cotizacion/editar',
              arguments: cot,
            ).then((edited) {
              if (edited == true && mounted) {
                _prov?.fetchDetalles(cot.cotizacionId);
              }
            }),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Header info ───────────────────────────────────────────────────────
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _InfoRow(
                    icon: Icons.tag,
                    label: 'Número',
                    value: '#${cot.cotizacionId}',
                  ),
                  const Divider(),
                  _InfoRow(
                    icon: Icons.calendar_today,
                    label: 'Fecha',
                    value: cot.cotizacionFecha != null
                        ? _dateFmt.format(cot.cotizacionFecha!)
                        : '—',
                  ),
                  const Divider(),
                  _InfoRow(
                    icon: Icons.person_outline,
                    label: 'Cliente ID',
                    value: cot.clienteId?.toString() ?? '—',
                  ),
                  const Divider(),
                  _InfoRow(
                    icon: Icons.attach_money,
                    label: 'Balance Total',
                    value: _currFmt.format(cot.cotizacionBalance ?? 0),
                    valueStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A237E)),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ── Detalles ──────────────────────────────────────────────────────────
          const Text(
            'Detalle de artículos',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A237E)),
          ),
          const SizedBox(height: 8),

          if (prov.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (prov.error != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Text(prov.error!,
                  style: TextStyle(color: Colors.red.shade700, fontSize: 12)),
            )
          else if (prov.detalles.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text('Sin artículos registrados',
                    style: TextStyle(color: Colors.grey)),
              ),
            )
          else ...[
            // Tabla de detalles
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  // Encabezado tabla
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: const BoxDecoration(
                      color: Color(0xFF1A237E),
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(12)),
                    ),
                    child: const Row(
                      children: [
                        Expanded(
                            flex: 3,
                            child: Text('Artículo',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold))),
                        Expanded(
                            flex: 2,
                            child: Text('Cant.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold))),
                        Expanded(
                            flex: 2,
                            child: Text('Subtotal',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold))),
                      ],
                    ),
                  ),
                  // Filas
                  ...prov.detalles.asMap().entries.map((entry) {
                    final i   = entry.key;
                    final det = entry.value;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: i.isEven ? Colors.white : Colors.grey.shade50,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Columna Artículo
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  det.articuloCd ?? '—',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: Color(0xFF1A237E)),
                                ),
                                if (det.articuloDesc != null)
                                  Text(
                                    det.articuloDesc!,
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade600),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                Text(
                                  'Precio: ${_currFmt.format(det.cotizacionPrecio ?? 0)}',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade500),
                                ),
                              ],
                            ),
                          ),
                          // Cantidad
                          Expanded(
                            flex: 2,
                            child: Text(
                              det.cotizacionQty?.toStringAsFixed(2) ?? '0',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          // Subtotal
                          Expanded(
                            flex: 2,
                            child: Text(
                              _currFmt.format(det.subtotal),
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  // Total
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A237E).withValues(alpha: 0.05),
                      borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(12)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                          _currFmt.format(prov.detalles
                              .fold<double>(0, (s, d) => s + d.subtotal)),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A237E),
                              fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final TextStyle? valueStyle;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueStyle,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Colors.grey),
            const SizedBox(width: 10),
            Text('$label: ',
                style: const TextStyle(color: Colors.grey, fontSize: 14)),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: valueStyle ??
                    const TextStyle(
                        fontWeight: FontWeight.w500, fontSize: 14),
              ),
            ),
          ],
        ),
      );
}
