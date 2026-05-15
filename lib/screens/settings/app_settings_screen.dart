import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:manage_center/services/storage_service.dart';
import 'package:provider/provider.dart';

class AppSettingsScreen extends StatelessWidget {
  const AppSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Настройки приложения'),
        foregroundColor: Colors.white,
        backgroundColor: Colors.blue,
      ),
      body: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 120),
        children: const [
          AlarmNotificationSettings(),
        ],
      ),
    );
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
        child: Center(
          child: CircularProgressIndicator(color: Colors.blueAccent),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, top: 8, bottom: 8),
            child: Text(
              'Аварийные уведомления',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3748),
              ),
            ),
          ),

          Card(
            elevation: 2.0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
            color: Colors.white,
            child: SwitchListTile(
              title: const Text('Звук уведомлений',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                _enabled ? 'Включён' : 'Выключен',
                style: TextStyle(color: _enabled ? Colors.green : Colors.grey),
              ),
              secondary: Icon(
                _enabled ? Icons.notifications_active : Icons.notifications_off,
                color: _enabled ? Colors.blue : Colors.grey,
              ),
              value: _enabled,
              activeColor: Colors.blue,
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
                    elevation: 2.0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0)),
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.volume_up, color: Colors.blue),
                              const SizedBox(width: 8),
                              const Text('Громкость',
                                  style: TextStyle(fontWeight: FontWeight.bold)),
                              const Spacer(),
                              Text(
                                '${(_volume * 100).round()}%',
                                style: const TextStyle(
                                  color: Colors.blueAccent,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: Colors.blueAccent,
                              inactiveTrackColor: Colors.blue.withOpacity(0.2),
                              thumbColor: Colors.blueAccent,
                              overlayColor: Colors.blueAccent.withOpacity(0.15),
                            ),
                            child: Slider(
                              min: 0.0,
                              max: 1.0,
                              divisions: 20,
                              value: _volume,
                              onChanged: (v) => setState(() => _volume = v),
                              onChangeEnd: (v) => _storage.setAlarmVolume(v),
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: () => _preview(_selectedSound),
                              icon: const Icon(Icons.play_arrow, color: Colors.blue),
                              label: const Text('Прослушать',
                                  style: TextStyle(color: Colors.blue)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

const Padding(
  padding: EdgeInsets.only(left: 4, top: 4, bottom: 8),
  child: Text(
    'Звук аварии',
    style: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: Color(0xFF2D3748),
    ),
  ),
),

                  Card(
  elevation: 2.0,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
  color: Colors.white,
  child: Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
    child: Row(
      children: [
        const Icon(Icons.music_note, color: Colors.blue),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButtonFormField<String>(
            value: _selectedSound,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Мелодия',
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
        // IconButton(
        //   icon: const Icon(Icons.play_circle_outline, color: Colors.blue),
        //   tooltip: 'Прослушать',
        //   onPressed: () => _preview(_selectedSound),
        // ),
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