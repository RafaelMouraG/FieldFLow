import 'package:flutter/foundation.dart';

import '../core/api_exception.dart';
import '../models/enums.dart';
import '../state/auth_controller.dart';

/// ViewModel do formulario de criacao de demanda.
///
/// Guarda o estado nao-textual (unidade de pagamento, data limite, envio) e
/// faz o POST. Espelha a regra do backend: `valor_recompensa` so e exigido
/// quando a unidade NAO for "A combinar".
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
      await _auth.demandas.criar(
        titulo: titulo.trim(),
        descricao: descricao.trim(),
        origem: origem.trim(),
        destino: destino.trim(),
        areaHectares: areaHectares,
        unidadePagamento: _unidade,
        tipoServico: tipoServico.trim(),
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
