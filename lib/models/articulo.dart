class Articulo {
  final int articuloId;
  final String? articuloCd;
  final String? articuloDesc;

  Articulo({
    required this.articuloId,
    this.articuloCd,
    this.articuloDesc,
  });

  factory Articulo.fromJson(Map<String, dynamic> json) => Articulo(
        articuloId:   json['articulo_ID'] ?? 0,
        articuloCd:   json['articulo_CD'],
        articuloDesc: json['articulo_Desc'],
      );

  @override
  String toString() => '${articuloCd ?? ''} - ${articuloDesc ?? ''}';
}
