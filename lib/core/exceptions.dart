/// Excecao lancada quando o usuario nao esta autenticado em uma das contas.
class NotAuthenticatedException implements Exception {
  final String message;
  const NotAuthenticatedException(this.message);

  @override
  String toString() => message;
}

/// Excecao lancada quando a cota diaria da API do YouTube e atingida.
class QuotaExceededException implements Exception {
  final String message;
  const QuotaExceededException(this.message);

  @override
  String toString() => message;
}

/// Erro generico de comunicacao com uma API externa.
class ApiRequestException implements Exception {
  final String message;
  const ApiRequestException(this.message);

  @override
  String toString() => message;
}
