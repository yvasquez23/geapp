class ApiConfig {
  // ── URL local (misma red Wi-Fi) ───────────────────────────────────────────────
  static const String baseUrl = 'http://192.168.1.197:9404';


  // Endpoints
  static const String login               = '$baseUrl/api/Usuario/login';
  static const String registro            = '$baseUrl/api/Usuario/registro';
  static const String cotizaciones        = '$baseUrl/api/Cotizacion';
  static const String cotizacionCompleta  = '$baseUrl/api/Cotizacion/completa';
  static const String cotizacionDet       = '$baseUrl/api/CotizacionDet';
  static const String articulos           = '$baseUrl/api/Articulos';

  /// Detalles con info de artículo: GET /api/Cotizacion/{id}/detalles
  static String cotizacionDetalles(int id) => '$cotizaciones/$id/detalles';

  /// Actualizar cotización completa: PUT /api/Cotizacion/{id}/completa
  static String cotizacionCompletaUpdate(int id) => '$cotizaciones/$id/completa';
}
