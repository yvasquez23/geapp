class Cotizacion {
  final int cotizacionId;
  final DateTime? cotizacionFecha;
  final int? clienteId;
  final double? cotizacionBalance;

  Cotizacion({
    required this.cotizacionId,
    this.cotizacionFecha,
    this.clienteId,
    this.cotizacionBalance,
  });

  factory Cotizacion.fromJson(Map<String, dynamic> json) => Cotizacion(
        cotizacionId:      json['cotizacion_id'] ?? 0,
        cotizacionFecha:   json['cotizacion_Fecha'] != null
            ? DateTime.tryParse(json['cotizacion_Fecha'])
            : null,
        clienteId:         json['cliente_id'],
        cotizacionBalance: (json['cotizacion_Balance'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'cotizacion_id':      cotizacionId,
        'cotizacion_Fecha':   cotizacionFecha?.toIso8601String(),
        'cliente_id':         clienteId,
        'cotizacion_Balance': cotizacionBalance,
      };
}
