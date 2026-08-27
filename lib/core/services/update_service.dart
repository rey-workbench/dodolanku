import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dodolanku/core/database_service.dart';
import 'package:dodolanku/core/services/gdrive_service.dart';
import 'package:dodolanku/core/widgets/app_modal.dart';

class UpdateService {
  static const String _repo = 'rey-workbench/dodolanku';

  static Future<void> checkForUpdates(BuildContext context) async {
    try {
      final response = await http.get(
        Uri.parse('https://api.github.com/repos/$_repo/releases/latest'),
      );

      if (response.statusCode != 200) return;

      final data = jsonDecode(response.body);
      final String latestTag = data['tag_name']?.toString() ?? '';
      final String latestVersion = latestTag.replaceAll('v', '');
      
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      
      if (latestVersion.isNotEmpty && _isNewer(latestVersion, currentVersion)) {
        if (!context.mounted) return;

        
        String? apkUrl;
        final assets = data['assets'] as List?;
        if (assets != null) {
          for (final asset in assets) {
            final name = asset['name'].toString().toLowerCase();
            if (name.endsWith('.apk') && name.contains('arm64')) {
              apkUrl = asset['browser_download_url'];
              break; 
            }
          }
          
          if (apkUrl == null) {
            for (final asset in assets) {
              if (asset['name'].toString().toLowerCase().endsWith('.apk')) {
                apkUrl = asset['browser_download_url'];
                break;
              }
            }
          }
        }

        if (apkUrl == null) return;

        showAppConfirmModal(
          context: context,
          title: 'Update Tersedia (v$latestVersion)',
          message: 'Versi baru aplikasi telah dirilis!\n\nCatatan Rilis:\n${data['name']}\n\nApakah Anda ingin mengunduhnya sekarang?',
          confirmLabel: 'Update Sekarang',
          onConfirm: () async {
            await _backupBeforeUpdate(context);
            try {
              final url = Uri.parse(apkUrl!);
              await launchUrl(url, mode: LaunchMode.externalApplication);
            } catch (_) {
              try {
                final url = Uri.parse(apkUrl!);
                await launchUrl(url, mode: LaunchMode.platformDefault);
              } catch (_) {}
            }
          },
        );
      }
    } catch (e) {
      debugPrint('[UpdateService] Check update error: $e');
    }
  }

  static Future<void> _backupBeforeUpdate(BuildContext context) async {
    try {
      final container = ProviderScope.containerOf(context);
      final dbService = container.read(databaseServiceProvider);
      await dbService.initDb();
      await dbService.forceCheckpoint();
    } catch (_) {}
    await GDriveService.uploadBackupSilently();
  }

  
  static bool _isNewer(String a, String b) {
    final av = a.split('.').map((s) => int.tryParse(s) ?? 0).toList();
    final bv = b.split('.').map((s) => int.tryParse(s) ?? 0).toList();
    final len = av.length > bv.length ? av.length : bv.length;
    for (var i = 0; i < len; i++) {
      final x = i < av.length ? av[i] : 0;
      final y = i < bv.length ? bv[i] : 0;
      if (x != y) return x > y;
    }
    return false;
  }
}
