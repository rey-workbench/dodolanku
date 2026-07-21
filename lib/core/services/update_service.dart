import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
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

      // Ponytail mode: simple string check. If not identical, it's an update.
      if (latestVersion.isNotEmpty && latestVersion != currentVersion) {
        if (!context.mounted) return;

        // Find APK url
        String? apkUrl;
        final assets = data['assets'] as List?;
        if (assets != null) {
          for (final asset in assets) {
            final name = asset['name'].toString().toLowerCase();
            if (name.endsWith('.apk') && name.contains('arm64')) {
              apkUrl = asset['browser_download_url'];
              break; // Prefer arm64 if multiple, or just take the first apk
            }
          }
          // Fallback to any apk
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
            final url = Uri.parse(apkUrl!);
            if (await canLaunchUrl(url)) {
              await launchUrl(url, mode: LaunchMode.externalApplication);
            }
          },
        );
      }
    } catch (e) {
      // Silently ignore update check errors
    }
  }
}
