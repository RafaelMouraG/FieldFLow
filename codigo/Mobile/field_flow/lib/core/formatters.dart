import 'package:intl/intl.dart';

import '../domain/entities/enums.dart';

/// Helpers de formatacao pt-BR (moeda, area, datas).
class Fmt {
  Fmt._();

  static final _moeda = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  static final _data = DateFormat('dd/MM/yyyy');
  static final _dataHora = DateFormat('dd/MM/yyyy HH:mm');

  static String dinheiro(double? v) => v == null ? '-' : _moeda.format(v);

  static String area(double ha) =>
      '${NumberFormat.decimalPattern('pt_BR').format(ha)} ha';

  static String data(DateTime? d) => d == null ? '-' : _data.format(d);

  static String dataHora(DateTime d) => _dataHora.format(d.toLocal());

  /// Valor + unidade, ex.: "R$ 3.500,00 (valor fixo)" ou "A combinar".
  static String pagamento(double? valor, UnidadePagamento unidade) {
    if (unidade == UnidadePagamento.aCombinar) return 'A combinar';
    return '${dinheiro(valor)} (${unidade.label.toLowerCase()})';
  }
}
