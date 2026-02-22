import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:manage_center/services/app_update_service.dart';

class UpdateDialog extends StatefulWidget {
  final UpdateInfo updateInfo;

  const UpdateDialog({super.key, required this.updateInfo});

  static Future<void> show(BuildContext context, UpdateInfo info) {
    return showDialog(
      context: context,
      barrierDismissible: !info.force,
      builder: (context) => UpdateDialog(updateInfo: info),
    );
  }

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> with WidgetsBindingObserver {
  bool _isDownloading = false;
  double _progress = 0;
  String? _error;
  CancelToken? _cancelToken;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cancelToken?.cancel('Диалог закрыт');
    super.dispose();
  }

  void _safeSetState(VoidCallback fn) {
    if (mounted) {
      setState(fn);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !widget.updateInfo.force || !_isDownloading,
      child: AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.system_update, color: Colors.blue, size: 24),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Доступно обновление',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Текущая: ${widget.updateInfo.currentVersion}',
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              'Новая: ${widget.updateInfo.latestVersion}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            if (_isDownloading) ...[
              const SizedBox(height: 20),
              LinearProgressIndicator(value: _progress),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Загрузка ${(_progress * 100).toStringAsFixed(0)}%',
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(color: Colors.red, fontSize: 13),
              ),
            ],
          ],
        ),
        actions: _buildActions(),
      ),
    );
  }

  List<Widget> _buildActions() {
    // Идёт загрузка — показываем только кнопку отмены
    if (_isDownloading) {
      return [
        TextButton(
          onPressed: _cancelDownload,
          child: const Text('Отмена'),
        ),
      ];
    }

    // Есть ошибка — показываем "Повторить" и "Позже"
    if (_error != null) {
      return [
        if (!widget.updateInfo.force)
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Позже'),
          ),
        ElevatedButton.icon(
          onPressed: _startDownload,
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('Повторить'),
        ),
      ];
    }

    // Начальное состояние — "Позже" и "Обновить"
    return [
      if (!widget.updateInfo.force)
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Позже'),
        ),
      ElevatedButton.icon(
        onPressed: _startDownload,
        icon: const Icon(Icons.download, size: 18),
        label: const Text('Обновить'),
      ),
    ];
  }

  void _cancelDownload() {
    _cancelToken?.cancel('Отменено пользователем');
    _safeSetState(() {
      _isDownloading = false;
      _progress = 0;
      _error = null;
    });
  }

  Future<void> _startDownload() async {
    _cancelToken = CancelToken();

    _safeSetState(() {
      _isDownloading = true;
      _progress = 0;
      _error = null;
    });

    try {
      await AppUpdateService().downloadAndInstall(
        widget.updateInfo,
        cancelToken: _cancelToken,
        onProgress: (received, total) {
          if (total > 0) {
            _safeSetState(() {
              _progress = received / total;
            });
          }
        },
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        _safeSetState(() {
          _isDownloading = false;
          _error = null;
        });
      } else {
        _safeSetState(() {
          _isDownloading = false;
          _error = 'Ошибка соединения. Проверьте интернет.';
        });
      }
    } catch (e) {
      _safeSetState(() {
        _isDownloading = false;
        _error = 'Ошибка загрузки. Попробуйте позже.';
      });
    }
  }
}