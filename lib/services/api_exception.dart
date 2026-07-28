/// Ошибка обращения к API в виде, пригодном для показа пользователю.
///
/// `toString()` возвращает только текст сообщения — блоки кладут его прямо
/// в state и выводят на экран, поэтому префикс «Exception: » здесь не нужен.
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

/// Сервер ответил 401 на запрос, требующий авторизации: токен истёк или отозван.
///
/// Бросается только там, где 401 действительно означает проблему с сессией.
/// На эндпоинтах, где 401 — часть бизнес-логики (неверный пароль при входе
/// или при смене пароля), используется обычный [ApiException].
class UnauthorizedException extends ApiException {
  const UnauthorizedException([String message = 'Сессия истекла. Войдите снова'])
      : super(message, statusCode: 401);
}

/// Проблемы с сетью: нет соединения, таймаут, обрыв.
class NetworkException extends ApiException {
  const NetworkException([super.message = 'Нет связи с сервером']);
}
