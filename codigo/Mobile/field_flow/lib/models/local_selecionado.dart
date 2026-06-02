/// Local escolhido no mapa: coordenadas + um rotulo legivel (texto digitado
/// pelo usuario, ex.: "Talhao Norte" ou um endereco).
class LocalSelecionado {
  LocalSelecionado({
    required this.lat,
    required this.lng,
    required this.rotulo,
  });

  final double lat;
  final double lng;
  final String rotulo;
}
