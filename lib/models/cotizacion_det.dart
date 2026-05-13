class CotizacionDet {
  final int cotizacionId;
  final int cotizacionDetId;
  final double? cotizacionQty;
  final double? cotizacionPrecio;
  final int?    articuloId;
  final String? articuloCd;
  final String? articuloDesc;

  CotizacionDet({
    required this.cotizacionId,
    required this.cotizacionDetId,
    this.cotizacionQty,
    this.cotizacionPrecio,
    this.articuloId,
    this.articuloCd,
    this.articuloDesc,
  });

  double get subtotal => (cotizacionQty ?? 0) * (cotizacionPrecio ?? 0);

  /// Parsea tanto la respuesta del endpoint original como la del nuevo
  /// endpoint /api/Cotizacion/{id}/detalles
  factory CotizacionDet.fromJson(Map<String, dynamic> json) => CotizacionDet(
        cotizacionId:     json['cotizacion_ID'] ?? 0,
        cotizacionDetId:  json['cotizacion_DetID'] ?? json['detId'] ?? 0,
        cotizacionQty:    _toDouble(json['cotizacion_Qty'] ?? json['qty']),
        cotizacionPrecio: _toDouble(json['cotizacion_Precio'] ?? json['precio']),
        articuloId:   json['articuloId'],
        articuloCd:   json['articuloCd'],
        articuloDesc: json['articuloDesc'],
      );

  /// Convierte string, int o double a double — maneja columnas varchar en GEAPP
  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  Map<String, dynamic> toJson() => {
        'cotizacion_ID':     cotizacionId,
        'cotizacion_DetID':  cotizacionDetId,
        'cotizacion_Qty':    cotizacionQty,
        'cotizacion_Precio': cotizacionPrecio,
      };
}
