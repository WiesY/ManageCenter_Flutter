import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// Лог только для отладочных сборок. В release не пишет ничего, чтобы
/// содержимое запросов и токены не попадали в системный лог устройства.
void logDebug(String message, {String name = 'app'}) {
  if (kDebugMode) {
    developer.log(message, name: name);
  }
}

/// Ошибка — пишем всегда, но без тел запросов и заголовков.
void logError(String message, {Object? error, String name = 'app'}) {
  developer.log(message, name: name, error: error);
}
