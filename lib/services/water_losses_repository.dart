// lib/services/water_losses_repository.dart
//
// Доступ к данным раздела «Баланс воды / Потери».
// ──────────────────────────────────────────────────────────────────────────────
// Источник цифр — asset-датасет, собранный из квартальной выгрузки биллинга
// (tool/generate_water_losses.py). API здесь не участвует: названия ВЗУ из
// выгрузки с объектами в системе автоматически не сходятся, а часть ВЗУ в
// системе вообще отсутствует.
//
// Поверх датасета лежат ручные правки оператора, привязанные к паре
// «объект × месяц» — иначе при переключении месяца в поле оставалось бы число
// от предыдущего.
// ──────────────────────────────────────────────────────────────────────────────

import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:manage_center/models/water_losses_dataset.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WaterLossesRepository {
  /// Текущая выгрузка. Новый квартал — новый файл и новая строка здесь.
  static const assetPath = 'assets/water_losses/2026_q1.json';

  static const _kTariff = 'wl_tariff';

  /// Префикс ключей ручного ввода. `v2` — потому что в первой версии раздела
  /// значение хранилось одно на объект, без привязки к месяцу.
  static const _kOverridePrefix = 'wl_v2_';

  final SharedPreferences _prefs;

  WaterLossesRepository(this._prefs);

  static Future<WaterLossesRepository> create() async =>
      WaterLossesRepository(await SharedPreferences.getInstance());

  // ── Датасет ───────────────────────────────────────────────────────────────
  Future<WaterLossesDataset> loadDataset() async {
    final raw = await rootBundle.loadString(assetPath);
    return WaterLossesDataset.fromJson(
        jsonDecode(raw) as Map<String, dynamic>);
  }

  // ── Тариф ─────────────────────────────────────────────────────────────────
  double get tariff => _prefs.getDouble(_kTariff) ?? 0;

  Future<void> saveTariff(double value) async {
    if (value > 0) {
      await _prefs.setDouble(_kTariff, value);
    } else {
      await _prefs.remove(_kTariff);
    }
  }

  // ── Ручные правки ─────────────────────────────────────────────────────────
  String _overrideKey(String nodeKey, String period) =>
      '$_kOverridePrefix${nodeKey}_$period';

  WaterOverride? readOverride(String nodeKey, String period) {
    final raw = _prefs.getString(_overrideKey(nodeKey, period));
    if (raw == null) return null;
    try {
      final o = WaterOverride.fromJson(
          jsonDecode(raw) as Map<String, dynamic>);
      return o.isEmpty ? null : o;
    } catch (_) {
      // Битая запись — считаем, что правки нет, чтобы раздел не падал.
      return null;
    }
  }

  Future<void> writeOverride(
    String nodeKey,
    String period,
    WaterOverride? value,
  ) async {
    final key = _overrideKey(nodeKey, period);
    if (value == null || value.isEmpty) {
      await _prefs.remove(key);
    } else {
      await _prefs.setString(key, jsonEncode(value.toJson()));
    }
  }
}
