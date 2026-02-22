import 'dart:io';
import 'package:dio/dio.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class AppUpdateService {
  static final AppUpdateService _instance = AppUpdateService._internal();
  factory AppUpdateService() => _instance;
  AppUpdateService._internal();

  static const String _baseUrl = 'https://boiler-v2.nwwork.site';
  final Dio _dio = Dio();

  String get _platform {
    if (Platform.isAndroid) return 'android';
    if (Platform.isWindows) return 'windows';
    return 'unknown';
  }

  Future<UpdateInfo?> checkForUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      print('🔍 [UPDATE] Проверка. Текущая: $currentVersion, Платформа: $_platform');

      final response = await _dio.get(
        '$_baseUrl/api/update/check/$_platform',
        queryParameters: {'currentVersion': currentVersion},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        print('📦 [UPDATE] Ответ: $data');

        if (data['updateAvailable'] == true) {
          return UpdateInfo(
            currentVersion: currentVersion,
            latestVersion: data['latestVersion'],
            downloadUrl: data['downloadUrl'],
            force: data['force'] ?? false,
          );
        }
      }

      print('✅ [UPDATE] Обновлений нет');
      return null;
    } catch (e) {
      print('❌ [UPDATE] Ошибка проверки: $e');
      return null;
    }
  }

  Future<void> downloadAndInstall(
    UpdateInfo info, {
    CancelToken? cancelToken,
    Function(int received, int total)? onProgress,
  }) async {
    try {
      if (Platform.isAndroid) {
        await _downloadAndInstallAndroid(info,
            cancelToken: cancelToken, onProgress: onProgress);
      } else if (Platform.isWindows) {
        await _downloadAndInstallWindows(info,
            cancelToken: cancelToken, onProgress: onProgress);
      }
    } catch (e) {
      print('❌ [UPDATE] Ошибка: $e');
      rethrow;
    }
  }

  Future<void> _downloadAndInstallAndroid(
    UpdateInfo info, {
    CancelToken? cancelToken,
    Function(int received, int total)? onProgress,
  }) async {
    if (await Permission.requestInstallPackages.isDenied) {
      await Permission.requestInstallPackages.request();
    }

    final dir = await getExternalStorageDirectory();
    if (dir == null) throw Exception('Не удалось получить папку');

    final filePath = '${dir.path}/update.apk';

    print('📥 [UPDATE] Скачиваем: ${info.downloadUrl}');

    await _dio.download(
      info.downloadUrl,
      filePath,
      cancelToken: cancelToken,
      onReceiveProgress: (received, total) {
        onProgress?.call(received, total);
      },
    );

    print('✅ [UPDATE] APK скачан: $filePath');

    final result = await OpenFilex.open(filePath);
    print('📱 [UPDATE] Открытие: ${result.message}');
  }

  Future<void> _downloadAndInstallWindows(
    UpdateInfo info, {
    CancelToken? cancelToken,
    Function(int received, int total)? onProgress,
  }) async {
    final dir = await getTemporaryDirectory();
    final filePath = '${dir.path}\\update.exe';

    print('📥 [UPDATE] Скачиваем: ${info.downloadUrl}');

    await _dio.download(
      info.downloadUrl,
      filePath,
      cancelToken: cancelToken,
      onReceiveProgress: (received, total) {
        onProgress?.call(received, total);
      },
    );

    print('✅ [UPDATE] EXE скачан: $filePath');

    await Process.start(filePath, [], mode: ProcessStartMode.detached);
    exit(0);
  }
}

class UpdateInfo {
  final String currentVersion;
  final String latestVersion;
  final String downloadUrl;
  final bool force;

  UpdateInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.downloadUrl,
    required this.force,
  });
}