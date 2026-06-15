import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

/// Mini-mapa (somente leitura) com um pino no local da tarefa + botao para
/// abrir o app de navegacao nativo ("Abrir no Maps"). Usado no detalhe.
class MapPreview extends StatelessWidget {
  const MapPreview({
    super.key,
    required this.lat,
    required this.lng,
    this.rotulo,
    this.altura = 160,
  });

  final double lat;
  final double lng;
  final String? rotulo;
  final double altura;

  Future<void> _abrirNoMaps() async {
    // URL universal de mapas: abre o app nativo (ou navegador) com o pino.
    final uri = Uri.parse('https://maps.google.com/?q=$lat,$lng');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final ponto = LatLng(lat, lng);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: altura,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: ponto,
                initialZoom: 14,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.none,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.fieldflow.app',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: ponto,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_on,
                        size: 36,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: _abrirNoMaps,
            icon: const Icon(Icons.directions, size: 18),
            label: const Text('Abrir no Maps'),
          ),
        ),
      ],
    );
  }
}
