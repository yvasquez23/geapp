import 'package:flutter/material.dart';
import '../models/cotizacion.dart';
import '../models/cotizacion_det.dart';
import '../models/articulo.dart';
import '../services/cotizacion_service.dart';

class CotizacionProvider extends ChangeNotifier {
  List<Cotizacion> _cotizaciones  = [];
  List<CotizacionDet> _detalles  = [];
  List<Articulo> _articulos       = [];
  bool _isLoading                 = false;
  String? _error;

  List<Cotizacion> get cotizaciones => _cotizaciones;
  List<CotizacionDet> get detalles  => _detalles;
  List<Articulo> get articulos      => _articulos;
  bool get isLoading                => _isLoading;
  String? get error                 => _error;

  // ── Cotizaciones ──────────────────────────────────────────────────────────────
  Future<void> fetchCotizaciones() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _cotizaciones = await CotizacionService.getAll();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createCotizacion(
    Cotizacion cotizacion,
    List<Map<String, dynamic>> items, {
    String? clienteNombre,
    String? comentario,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final balance = items.fold<double>(
          0, (s, i) => s + ((i['qty'] as double) * (i['precio'] as double)));

      await CotizacionService.createCompleta(
        fecha:          cotizacion.cotizacionFecha ?? DateTime.now(),
        clienteId:      cotizacion.clienteId,
        clienteNombre:  clienteNombre,
        balance:        balance,
        comentario:     comentario,
        detalles:       items,
      );

      await fetchCotizaciones();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateCotizacion(
    int id,
    Cotizacion cotizacion,
    List<Map<String, dynamic>> items, {
    String? clienteNombre,
    String? comentario,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final balance = items.fold<double>(
          0, (s, i) => s + ((i['qty'] as double) * (i['precio'] as double)));

      await CotizacionService.updateCompleta(
        id:            id,
        fecha:         cotizacion.cotizacionFecha ?? DateTime.now(),
        clienteId:     cotizacion.clienteId,
        clienteNombre: clienteNombre,
        balance:       balance,
        comentario:    comentario,
        detalles:      items,
      );

      await fetchCotizaciones();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> deleteCotizacion(int id) async {
    try {
      await CotizacionService.delete(id);
      _cotizaciones.removeWhere((c) => c.cotizacionId == id);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // ── Detalles ──────────────────────────────────────────────────────────────────
  Future<void> fetchDetalles(int cotizacionId) async {
    _isLoading = true;
    _error    = null;
    _detalles = [];          // limpiar detalles anteriores al comenzar
    notifyListeners();
    try {
      _detalles = await CotizacionService.getDetalles(cotizacionId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Artículos ─────────────────────────────────────────────────────────────────
  Future<void> fetchArticulos() async {
    if (_articulos.isNotEmpty) return;
    try {
      _articulos = await CotizacionService.getArticulos();
      notifyListeners();
    } catch (_) {}
  }

  void clearDetalles() {
    _detalles = [];
    _error = null;   // limpiar el error para que no contamine otras pantallas
    notifyListeners();
  }
}
