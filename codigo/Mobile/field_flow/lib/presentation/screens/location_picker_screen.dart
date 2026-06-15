import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../domain/entities/local_selecionado.dart';

/// Seletor de local no mapa (OpenStreetMap, sem API key).
///
/// UX: um pino fixo no centro da tela; o usuario arrasta o mapa para posicionar
/// o ponto sob o pino. Botao "usar minha localizacao" (GPS) reposiciona o mapa.
/// Retorna um [LocalSelecionado] (coordenadas + rotulo) via `Navigator.pop`.
class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({
    super.key,
    this.inicial,
    this.rotuloInicial,
    this.titulo = 'Selecionar local',
  });

  /// Centro inicial do mapa (ex.: ponto ja salvo, ou endereco da fazenda).
  final LatLng? inicial;
  final String? rotuloInicial;
  final String titulo;

  /// Centro padrao quando nao ha ponto inicial nem GPS (regiao agricola —
  /// Sorriso/MT). Evita o mapa abrir no oceano (0,0) no simulador sem GPS.
  static const LatLng _padrao = LatLng(-12.545, -55.711);

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final _map = MapController();
  late final TextEditingController _rotulo;
  late LatLng _centro;
  bool _localizando = false;

  @override
  void initState() {
    super.initState();
    _rotulo = TextEditingController(text: widget.rotuloInicial ?? '');
    _centro = widget.inicial ?? LocationPickerScreen._padrao;
  }

  @override
  void dispose() {
    _rotulo.dispose();
    super.dispose();
  }

  Future<void> _usarMinhaLocalizacao() async {
    setState(() => _localizando = true);
    try {
      final pos = await _posicaoAtual();
      if (pos != null) {
        _map.move(pos, 15);
        setState(() => _centro = pos);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Nao foi possivel obter o GPS. Arraste o mapa para marcar o local.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _localizando = false);
    }
  }

  /// Posicao atual via GPS; `null` se sem permissao/servico (cai no fallback).
  Future<LatLng?> _posicaoAtual() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return null;
      }
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          timeLimit: Duration(seconds: 8),
        ),
      );
      return LatLng(p.latitude, p.longitude);
    } catch (_) {
      return null;
    }
  }

  void _confirmar() {
    // Usa _centro (sincronizado em onPositionChanged) em vez de _map.camera,
    // que lancaria StateError se confirmado antes do primeiro layout do mapa.
    Navigator.of(context).pop(
      LocalSelecionado(
        lat: _centro.latitude,
        lng: _centro.longitude,
        rotulo: _rotulo.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.titulo)),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _map,
            options: MapOptions(
              initialCenter: _centro,
              initialZoom: 13,
              onPositionChanged: (camera, _) =>
                  setState(() => _centro = camera.center),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.fieldflow.app',
              ),
            ],
          ),
          // Pino fixo no centro (a ponta aponta o centro exato do mapa).
          const IgnorePointer(
            child: Center(
              child: Padding(
                padding: EdgeInsets.only(bottom: 36),
                child: Icon(Icons.location_on, size: 44, color: Colors.red),
              ),
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.my_location,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${_centro.latitude.toStringAsFixed(5)}, '
                            '${_centro.longitude.toStringAsFixed(5)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _localizando
                              ? null
                              : _usarMinhaLocalizacao,
                          icon: _localizando
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.gps_fixed, size: 18),
                          label: const Text('Minha localizacao'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _rotulo,
                      decoration: const InputDecoration(
                        labelText: 'Rotulo do local (ex.: Talhao Norte)',
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _confirmar,
                        icon: const Icon(Icons.check),
                        label: const Text('Confirmar local'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
