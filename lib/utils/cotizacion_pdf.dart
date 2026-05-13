import 'dart:io';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/cotizacion.dart';
import '../models/cotizacion_det.dart';

class CotizacionPdf {
  static final _currFmt = NumberFormat.currency(locale: 'es_MX', symbol: '\$');
  static final _dateFmt = DateFormat('dd/MM/yyyy');

  static const _azul    = PdfColor.fromInt(0xFF1A237E);
  static const _azulBg  = PdfColor.fromInt(0xFFE8EAF6);
  static const _gris    = PdfColor.fromInt(0xFF757575);
  // PdfColors.white70 no existe — usamos blanco con opacidad manual
  static const _blanco70 = PdfColor(1, 1, 1, 0.75);

  /// Genera el PDF y lo devuelve como Uint8List (requerido por printing)
  static Future<Uint8List> generar({
    required Cotizacion cot,
    required List<CotizacionDet> detalles,
    String? clienteNombre,
  }) async {
    final pdf   = pw.Document();
    final total = detalles.fold<double>(0, (s, d) => s + d.subtotal);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin:     const pw.EdgeInsets.all(32),
        header: (_) => _header(cot),
        footer: (ctx) => _footer(ctx),
        build: (ctx) => [
          pw.SizedBox(height: 20),
          _infoCard(cot, clienteNombre),
          pw.SizedBox(height: 20),
          _tablaDetalles(detalles),
          pw.SizedBox(height: 12),
          _totalRow(total),
          pw.SizedBox(height: 24),
          _nota(),
        ],
      ),
    );

    return pdf.save();
  }

  // ── Header ──────────────────────────────────────────────────────────────────
  static pw.Widget _header(Cotizacion cot) {
    return pw.Container(
      decoration: const pw.BoxDecoration(
        color: _azul,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'GEAPP',
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                  letterSpacing: 3,
                ),
              ),
              pw.Text(
                'Sistema de Cotizaciones',
                style: pw.TextStyle(color: _blanco70, fontSize: 10),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'COTIZACIÓN',
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                '#${cot.cotizacionId}',
                style: pw.TextStyle(color: _blanco70, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Info card ───────────────────────────────────────────────────────────────
  static pw.Widget _infoCard(Cotizacion cot, String? clienteNombre) {
    return pw.Container(
      decoration: const pw.BoxDecoration(
        color: _azulBg,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      padding: const pw.EdgeInsets.all(16),
      child: pw.Row(
        children: [
          pw.Expanded(child: _infoItem('Número', '#${cot.cotizacionId}')),
          pw.Expanded(
            child: _infoItem(
              'Fecha',
              cot.cotizacionFecha != null
                  ? _dateFmt.format(cot.cotizacionFecha!)
                  : '—',
            ),
          ),
          pw.Expanded(child: _infoItem('Cliente', clienteNombre ?? '—')),
        ],
      ),
    );
  }

  static pw.Widget _infoItem(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label,
            style: pw.TextStyle(color: _gris, fontSize: 9)),
        pw.SizedBox(height: 3),
        pw.Text(value,
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
      ],
    );
  }

  // ── Tabla ───────────────────────────────────────────────────────────────────
  static pw.Widget _tablaDetalles(List<CotizacionDet> detalles) {
    final headerStyle = pw.TextStyle(
      color: PdfColors.white,
      fontSize: 10,
      fontWeight: pw.FontWeight.bold,
    );

    return pw.Table(
      columnWidths: const {
        0: pw.FlexColumnWidth(3),
        1: pw.FlexColumnWidth(4),
        2: pw.FlexColumnWidth(2),
        3: pw.FlexColumnWidth(2),
        4: pw.FlexColumnWidth(2),
      },
      children: [
        // Encabezado
        pw.TableRow(
          decoration: const pw.BoxDecoration(
            color: _azul,
            borderRadius: pw.BorderRadius.only(
              topLeft:  pw.Radius.circular(6),
              topRight: pw.Radius.circular(6),
            ),
          ),
          children: [
            _th('Código',      headerStyle),
            _th('Descripción', headerStyle),
            _th('Cant.',       headerStyle, align: pw.TextAlign.center),
            _th('Precio',      headerStyle, align: pw.TextAlign.right),
            _th('Subtotal',    headerStyle, align: pw.TextAlign.right),
          ],
        ),
        // Filas de datos
        ...detalles.asMap().entries.map((e) {
          final i   = e.key;
          final det = e.value;
          final bg  = i.isEven
              ? PdfColors.white
              : const PdfColor.fromInt(0xFFF5F5F5);
          return pw.TableRow(
            decoration: pw.BoxDecoration(color: bg),
            children: [
              _td(det.articuloCd ?? '—'),
              _td(det.articuloDesc ?? '—',
                  style: pw.TextStyle(fontSize: 9, color: _gris)),
              _td(det.cotizacionQty?.toStringAsFixed(2) ?? '0',
                  align: pw.TextAlign.center),
              _td(_currFmt.format(det.cotizacionPrecio ?? 0),
                  align: pw.TextAlign.right),
              _td(_currFmt.format(det.subtotal),
                  align: pw.TextAlign.right,
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 10)),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _th(String text, pw.TextStyle style,
      {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: pw.Text(text, style: style, textAlign: align),
    );
  }

  static pw.Widget _td(String text,
      {pw.TextAlign align = pw.TextAlign.left, pw.TextStyle? style}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      child: pw.Text(text,
          style: style ?? const pw.TextStyle(fontSize: 10),
          textAlign: align),
    );
  }

  // ── Total ───────────────────────────────────────────────────────────────────
  static pw.Widget _totalRow(double total) {
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Container(
        width: 220,
        decoration: const pw.BoxDecoration(
          color: _azulBg,
          borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
        ),
        padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('TOTAL',
                style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 13,
                    color: _azul)),
            pw.Text(_currFmt.format(total),
                style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 14,
                    color: _azul)),
          ],
        ),
      ),
    );
  }

  // ── Nota ────────────────────────────────────────────────────────────────────
  static pw.Widget _nota() {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _azulBg, width: 1),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      padding: const pw.EdgeInsets.all(10),
      child: pw.Text(
        'Esta cotización tiene una validez de 30 días a partir de la fecha de emisión.',
        style: pw.TextStyle(color: _gris, fontSize: 9),
      ),
    );
  }

  // ── Footer ──────────────────────────────────────────────────────────────────
  static pw.Widget _footer(pw.Context ctx) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text('GEAPP — Sistema de Cotizaciones',
            style: pw.TextStyle(color: _gris, fontSize: 8)),
        pw.Text('Página ${ctx.pageNumber} de ${ctx.pagesCount}',
            style: pw.TextStyle(color: _gris, fontSize: 8)),
      ],
    );
  }

  // ── Guardar en archivo temporal ─────────────────────────────────────────────
  static Future<File> guardarTemporal({
    required Cotizacion cot,
    required List<CotizacionDet> detalles,
    String? clienteNombre,
  }) async {
    final bytes = await generar(
      cot:           cot,
      detalles:      detalles,
      clienteNombre: clienteNombre,
    );
    final dir  = await getTemporaryDirectory();
    final file = File('${dir.path}/cotizacion_${cot.cotizacionId}.pdf');
    await file.writeAsBytes(bytes);
    return file;
  }
}
