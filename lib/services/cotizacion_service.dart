import 'dart:convert';
import '../config/api_config.dart';
import '../models/cotizacion.dart';
import '../models/cotizacion_det.dart';
import '../models/articulo.dart';
import 'api_service.dart';

class CotizacionService {
  // ── COTIZACIONES ──────────────────────────────────────────────────────────────
  static Future<List<Cotizacion>> getAll({int page = 1, int pageSize = 50}) async {
    final response = await ApiService.get(
      ApiConfig.cotizaciones,
      queryParams: {'page': '$page', 'pageSize': '$pageSize'},
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => Cotizacion.fromJson(e)).toList();
    }
    throw Exception('Error al obtener cotizaciones (${response.statusCode})');
  }

  static Future<Cotizacion> getById(int id) async {
    final response = await ApiService.get('${ApiConfig.cotizaciones}/$id');
    if (response.statusCode == 200) {
      return Cotizacion.fromJson(jsonDecode(response.body));
    }
    throw Exception('Cotización no encontrada');
  }

  static Future<Cotizacion> create(Cotizacion cotizacion) async {
    final response = await ApiService.post(
        ApiConfig.cotizaciones, cotizacion.toJson());
    if (response.statusCode == 201 || response.statusCode == 200) {
      return Cotizacion.fromJson(jsonDecode(response.body));
    }
    throw Exception('Error al crear cotización (${response.statusCode})');
  }

  /// Crea cotización completa (header + detalles) en GEAPP y ServempSys
  static Future<Map<String, dynamic>> createCompleta({
    required DateTime fecha,
    required int? clienteId,
    required String? clienteNombre,
    required double balance,
    required String? comentario,
    required List<Map<String, dynamic>> detalles,
  }) async {
    final body = {
      'cotizacion_Fecha':   fecha.toIso8601String(),
      'cliente_ID':         clienteId,
      'cotizacion_Cliente': clienteNombre,
      'cotizacion_Balance': balance,
      'comentario':         comentario,
      'detalles': detalles.map((d) => {
        'articulo_ID':       d['articulo_ID'],
        'cotizacion_Qty':    d['qty'],
        'cotizacion_Precio': d['precio'],
        'comentario':        d['comentario'],
      }).toList(),
    };

    final response = await ApiService.post(ApiConfig.cotizacionCompleta, body);
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Error al guardar cotización (${response.statusCode})');
  }

  /// Actualiza cotización completa (header + reemplaza detalles) en GEAPP y ServempSys
  static Future<Map<String, dynamic>> updateCompleta({
    required int id,
    required DateTime fecha,
    required int? clienteId,
    required String? clienteNombre,
    required double balance,
    required String? comentario,
    required List<Map<String, dynamic>> detalles,
  }) async {
    final body = {
      'cotizacion_Fecha':   fecha.toIso8601String(),
      'cliente_ID':         clienteId,
      'cotizacion_Cliente': clienteNombre,
      'cotizacion_Balance': balance,
      'comentario':         comentario,
      'detalles': detalles.map((d) => {
        'articulo_ID':       d['articulo_ID'],
        'cotizacion_Qty':    d['qty'],
        'cotizacion_Precio': d['precio'],
        'comentario':        d['comentario'],
      }).toList(),
    };
    final response = await ApiService.put(
        ApiConfig.cotizacionCompletaUpdate(id), body);
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Error al actualizar cotización (${response.statusCode})');
  }

  static Future<void> delete(int id) async {
    final response = await ApiService.delete('${ApiConfig.cotizaciones}/$id');
    if (response.statusCode != 204) {
      throw Exception('Error al eliminar cotización');
    }
  }

  // ── DETALLES ──────────────────────────────────────────────────────────────────
  static Future<List<CotizacionDet>> getDetalles(int cotizacionId) async {
    final url = ApiConfig.cotizacionDetalles(cotizacionId);
    final response = await ApiService.get(url);
    // ignore: avoid_print
    print('── getDetalles URL: $url');
    // ignore: avoid_print
    print('── status: ${response.statusCode}  body: ${response.body}');
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => CotizacionDet.fromJson(e)).toList();
    }
    throw Exception('Error al obtener detalles (${response.statusCode}): ${response.body}');
  }

  static Future<CotizacionDet> createDetalle(CotizacionDet det) async {
    final response =
        await ApiService.post(ApiConfig.cotizacionDet, det.toJson());
    if (response.statusCode == 200 || response.statusCode == 201) {
      return CotizacionDet.fromJson(jsonDecode(response.body));
    }
    throw Exception('Error al agregar detalle (${response.statusCode})');
  }

  static Future<void> deleteDetalle(int cotizacionId, int detId) async {
    final response = await ApiService.delete(
        '${ApiConfig.cotizacionDet}/$cotizacionId/$detId');
    if (response.statusCode != 204) {
      throw Exception('Error al eliminar detalle');
    }
  }

  // ── ARTÍCULOS ─────────────────────────────────────────────────────────────────
  static Future<List<Articulo>> getArticulos() async {
    final response = await ApiService.get(ApiConfig.articulos,
        queryParams: {'pageSize': '100'});
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => Articulo.fromJson(e)).toList();
    }
    throw Exception('Error al obtener artículos');
  }
}
