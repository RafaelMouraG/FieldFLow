import 'package:flutter/foundation.dart';

import '../../core/api_exception.dart';
import '../../domain/entities/enums.dart';
import '../../state/auth_controller.dart';

/// ViewModel do formulario de criacao de demanda.
///
/// Guarda o estado nao-textual (unidade de pagamento, data limite, coordenadas
/// do local, envio) e faz o POST. Espelha a regra do backend: `valor_recompensa`
/// so e exigido quando a unidade NAO for "A combinar".
class DemandaFormViewModel extends ChangeNotifier {
  DemandaFormViewModel(this._auth);
  final AuthController _auth;

  UnidadePagamento _unidade = UnidadePagamento.fixo;
  UnidadePagamento get unidade => _unidade;

  DateTime? _dataLimite;
  DateTime? get dataLimite => _dataLimite;

  bool _enviando = false;
  bool get enviando => _enviando;

  bool get exigeValor => _unidade != UnidadePagamento.aCombinar;

  // Coordenadas do local da tarefa, escolhidas no mapa.
  double? _origemLat;
  double? _origemLng;
  double? _destinoLat;
  double? _destinoLng;

  double? get origemLat => _origemLat;
  double? get origemLng => _origemLng;
  double? get destinoLat => _destinoLat;
  double? get destinoLng => _destinoLng;

  bool get origemMarcada => _origemLat != null && _origemLng != null;
  bool get destinoMarcado => _destinoLat != null && _destinoLng != null;

  String? _coordResumo(double? lat, double? lng) => (lat != null && lng != null)
      ? '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}'
      : null;
  String? get origemResumo => _coordResumo(_origemLat, _origemLng);
  String? get destinoResumo => _coordResumo(_destinoLat, _destinoLng);

  // Endereco da fazenda (cliente CNPJ), usado para pre-centrar o mapa.
  double? get fazendaLat => _auth.usuario?.enderecoLat;
  double? get fazendaLng => _auth.usuario?.enderecoLng;
  String? get fazendaEndereco => _auth.usuario?.endereco;

  void setOrigemCoord(double lat, double lng) {
    _origemLat = lat;
    _origemLng = lng;
    notifyListeners();
  }

  void setDestinoCoord(double lat, double lng) {
    _destinoLat = lat;
    _destinoLng = lng;
    notifyListeners();
  }

  void setUnidade(UnidadePagamento u) {
    _unidade = u;
    notifyListeners();
  }

  void setDataLimite(DateTime? d) {
    _dataLimite = d;
    notifyListeners();
  }

  /// Cria a demanda. Retorna `null` em sucesso ou a msg de erro.
  Future<String?> salvar({
    required String titulo,
    required String descricao,
    required String origem,
    required String destino,
    required double areaHectares,
    required String tipoServico,
    required double? valorRecompensa,
  }) async {
    _setEnviando(true);
    try {
      await _auth.criarDemanda(
        titulo: titulo.trim(),
        descricao: descricao.trim(),
        origem: origem.trim(),
        destino: destino.trim(),
        areaHectares: areaHectares,
        unidadePagamento: _unidade,
        tipoServico: tipoServico.trim(),
        origemLat: _origemLat,
        origemLng: _origemLng,
        destinoLat: _destinoLat,
        destinoLng: _destinoLng,
        valorRecompensa: exigeValor ? valorRecompensa : null,
        dataLimite: _dataLimite,
      );
      return null;
    } on ApiException catch (e) {
      return e.message;
    } finally {
      _setEnviando(false);
    }
  }

  void _setEnviando(bool v) {
    _enviando = v;
    notifyListeners();
  }
}
