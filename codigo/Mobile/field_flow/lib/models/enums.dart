// Espelha os enums do backend (strings identicas as do FastAPI).

enum TipoUsuario {
  cliente('CLIENTE'),
  prestador('PRESTADOR');

  const TipoUsuario(this.wire);
  final String wire;

  static TipoUsuario fromWire(String v) =>
      values.firstWhere((e) => e.wire == v, orElse: () => TipoUsuario.cliente);
}

enum TipoDocumento {
  cpf('CPF'),
  cnpj('CNPJ');

  const TipoDocumento(this.wire);
  final String wire;

  static TipoDocumento fromWire(String v) =>
      values.firstWhere((e) => e.wire == v, orElse: () => TipoDocumento.cpf);
}

enum DemandaStatus {
  pendente('PENDENTE', 'Pendente'),
  aceito('ACEITO', 'Aceito'),
  emExecucao('EM_EXECUCAO', 'Em execucao'),
  concluido('CONCLUIDO', 'Concluido');

  const DemandaStatus(this.wire, this.label);
  final String wire;
  final String label;

  static DemandaStatus fromWire(String v) => values
      .firstWhere((e) => e.wire == v, orElse: () => DemandaStatus.pendente);
}

enum UnidadePagamento {
  fixo('FIXO', 'Valor fixo'),
  porDia('POR_DIA', 'Por dia'),
  porHora('POR_HORA', 'Por hora'),
  porHectare('POR_HECTARE', 'Por hectare'),
  aCombinar('A_COMBINAR', 'A combinar');

  const UnidadePagamento(this.wire, this.label);
  final String wire;
  final String label;

  static UnidadePagamento fromWire(String v) => values
      .firstWhere((e) => e.wire == v, orElse: () => UnidadePagamento.fixo);
}

enum StatusCandidatura {
  pendente('PENDENTE', 'Pendente'),
  aceita('ACEITA', 'Aceita'),
  rejeitada('REJEITADA', 'Rejeitada'),
  cancelada('CANCELADA', 'Cancelada');

  const StatusCandidatura(this.wire, this.label);
  final String wire;
  final String label;

  static StatusCandidatura fromWire(String v) => values.firstWhere(
      (e) => e.wire == v,
      orElse: () => StatusCandidatura.pendente);
}
