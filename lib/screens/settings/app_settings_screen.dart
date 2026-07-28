import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:manage_center/services/storage_service.dart';
import 'package:manage_center/theme/app_theme.dart';
import 'package:manage_center/theme/theme_cubit.dart';

class AppSettingsScreen extends StatelessWidget {
  const AppSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки приложения'),
      ),
      body: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 120),
        children: const [
          AppearanceSettings(),
          AlarmNotificationSettings(),
        ],
      ),
    );
  }
}

/// Заголовок группы настроек.
class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 8, bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: context.colors.onSurface,
        ),
      ),
    );
  }
}

/// Выбор светлой / тёмной / системной темы.
class AppearanceSettings extends StatelessWidget {
  const AppearanceSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('Оформление'),
          BlocBuilder<ThemeCubit, ThemeMode>(
            builder: (context, mode) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(_iconFor(mode), color: colors.primary),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Тема приложения',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _descriptionFor(context, mode),
                        style: TextStyle(
                          fontSize: 13,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: SegmentedButton<ThemeMode>(
                          segments: const [
                            ButtonSegment(
                              value: ThemeMode.system,
                              icon: Icon(Icons.brightness_auto_outlined),
                              label: Text('Система'),
                            ),
                            ButtonSegment(
                              value: ThemeMode.light,
                              icon: Icon(Icons.light_mode_outlined),
                              label: Text('Светлая'),
                            ),
                            ButtonSegment(
                              value: ThemeMode.dark,
                              icon: Icon(Icons.dark_mode_outlined),
                              label: Text('Тёмная'),
                            ),
                          ],
                          selected: {mode},
                          showSelectedIcon: false,
                          onSelectionChanged: (selection) {
                            context.read<ThemeCubit>().setMode(selection.first);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  IconData _iconFor(ThemeMode mode) => switch (mode) {
        ThemeMode.system => Icons.brightness_auto_outlined,
        ThemeMode.light => Icons.light_mode_outlined,
        ThemeMode.dark => Icons.dark_mode_outlined,
      };

  String _descriptionFor(BuildContext context, ThemeMode mode) {
    return switch (mode) {
      ThemeMode.system =>
        'Следует настройке устройства — сейчас ${context.isDark ? 'тёмная' : 'светлая'}',
      ThemeMode.light => 'Всегда светлое оформление',
      ThemeMode.dark => 'Всегда тёмное оформление',
    };
  }
}

class AlarmNotificationSettings extends StatefulWidget {
  const AlarmNotificationSettings({super.key});

  @override
  State<AlarmNotificationSettings> createState() =>
      _AlarmNotificationSettingsState();
}

class _AlarmNotificationSettingsState extends State<AlarmNotificationSettings> {
  static const List<_SoundOption> _sounds = [
    _SoundOption(asset: 'sounds/alarm.wav', label: 'Стандартный'),
    _SoundOption(asset: 'sounds/beep1.mp3', label: 'Короткий сигнал'),
    _SoundOption(asset: 'sounds/beep2.mp3', label: 'Длинный сигнал'),
    _SoundOption(asset: 'sounds/beep3.mp3', label: 'Гудок'),
    _SoundOption(asset: 'sounds/beep4.mp3', label: 'Клик'),
  ];

  final AudioPlayer _previewPlayer = AudioPlayer();
  late final StorageService _storage;

  bool _enabled = StorageService.defaultAlarmSoundEnabled;
  double _volume = StorageService.defaultAlarmVolume;
  String _selectedSound = StorageService.defaultAlarmSound;
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _storage = context.read<StorageService>();
      _load();
    }
  }

  @override
  void dispose() {
    _previewPlayer.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final enabled = await _storage.isAlarmSoundEnabled();
    final volume = await _storage.getAlarmVolume();
    final sound = await _storage.getAlarmSound();
    if (!mounted) return;
    setState(() {
      _enabled = enabled;
      _volume = volume;
      _selectedSound = sound;
      _loaded = true;
    });
  }

  Future<void> _preview(String asset) async {
    await _previewPlayer.stop();
    await _previewPlayer.setVolume(_volume);
    await _previewPlayer.play(AssetSource(asset));
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final colors = context.colors;
    final appColors = context.appColors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('Аварийные уведомления'),

          Card(
            child: SwitchListTile(
              title: const Text('Звук уведомлений',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                _enabled ? 'Включён' : 'Выключен',
                style: TextStyle(
                  color: _enabled ? appColors.success : colors.onSurfaceVariant,
                ),
              ),
              secondary: Icon(
                _enabled ? Icons.notifications_active : Icons.notifications_off,
                color: _enabled ? colors.primary : colors.onSurfaceVariant,
              ),
              value: _enabled,
              onChanged: (val) {
                setState(() => _enabled = val);
                _storage.setAlarmSoundEnabled(val);
              },
            ),
          ),

          const SizedBox(height: 12),

          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: _enabled ? 1.0 : 0.5,
            child: IgnorePointer(
              ignoring: !_enabled,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.volume_up, color: colors.primary),
                              const SizedBox(width: 8),
                              const Text('Громкость',
                                  style: TextStyle(fontWeight: FontWeight.bold)),
                              const Spacer(),
                              Text(
                                '${(_volume * 100).round()}%',
                                style: TextStyle(
                                  color: colors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          Slider(
                            min: 0.0,
                            max: 1.0,
                            divisions: 20,
                            value: _volume,
                            onChanged: (v) => setState(() => _volume = v),
                            onChangeEnd: (v) => _storage.setAlarmVolume(v),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: () => _preview(_selectedSound),
                              icon: const Icon(Icons.play_arrow),
                              label: const Text('Прослушать'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  const _SectionTitle('Звук аварии'),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      child: Row(
                        children: [
                          Icon(Icons.music_note, color: colors.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedSound,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Мелодия',
                                labelStyle:
                                    TextStyle(fontWeight: FontWeight.bold),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                              ),
                              items: _sounds
                                  .map((s) => DropdownMenuItem<String>(
                                        value: s.asset,
                                        child: Text(s.label),
                                      ))
                                  .toList(),
                              onChanged: (val) {
                                if (val == null) return;
                                setState(() => _selectedSound = val);
                                _storage.setAlarmSound(val);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _SoundOption {
  final String asset;
  final String label;
  const _SoundOption({required this.asset, required this.label});
}
