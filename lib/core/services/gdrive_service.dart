import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:dodolanku/core/config/database_config.dart';

class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }
}

class GDriveService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [drive.DriveApi.driveAppdataScope],
  );

  static Future<GoogleSignInAccount?> currentUser() async {
    return _googleSignIn.currentUser ?? await _googleSignIn.signInSilently();
  }

  static Future<GoogleSignInAccount?> signIn() async {
    try {
      return await _googleSignIn.signIn();
    } catch (e) {
      debugPrint('GDrive Sign-In Error: $e');
      return null;
    }
  }

  static Future<void> signOut() async {
    await _googleSignIn.signOut();
  }

  /// Upload database SQLite lokal ke folder tersembunyi Google Drive (appDataFolder)
  static Future<String?> uploadBackup() async {
    try {
      var account = await currentUser();
      account ??= await signIn();
      if (account == null) return 'Gagal login ke akun Google.';

      final authHeaders = await account.authHeaders;
      final authClient = GoogleAuthClient(authHeaders);
      final driveApi = drive.DriveApi(authClient);

      final dbPath = await getDatabasesPath();
      final file = File(join(dbPath, DatabaseConfig.localDbName));
      if (!await file.exists()) return 'File database lokal (${DatabaseConfig.localDbName}) tidak ditemukan.';

      // Cari file backup lama
      final fileList = await driveApi.files.list(
        spaces: 'appDataFolder',
        q: "name = 'yourcashier_backup.db'",
      );

      final media = drive.Media(file.openRead(), file.lengthSync());

      if (fileList.files != null && fileList.files!.isNotEmpty) {
        // Update file lama yang sudah ada
        final fileId = fileList.files!.first.id!;
        await driveApi.files.update(
          drive.File(),
          fileId,
          uploadMedia: media,
        );
      } else {
        // Buat file baru di appDataFolder
        final driveFile = drive.File()
          ..name = 'yourcashier_backup.db'
          ..parents = ['appDataFolder'];
        await driveApi.files.create(
          driveFile,
          uploadMedia: media,
        );
      }
      return null; // Null means success
    } catch (e) {
      debugPrint('GDrive Upload Error: $e');
      return e.toString();
    }
  }

  /// Download & pulihkan database SQLite dari Google Drive ke HP
  static Future<bool> restoreBackup() async {
    try {
      var account = await currentUser();
      account ??= await signIn();
      if (account == null) return false;

      final authHeaders = await account.authHeaders;
      final authClient = GoogleAuthClient(authHeaders);
      final driveApi = drive.DriveApi(authClient);

      final fileList = await driveApi.files.list(
        spaces: 'appDataFolder',
        q: "name = 'yourcashier_backup.db'",
      );

      if (fileList.files == null || fileList.files!.isEmpty) return false;

      final fileId = fileList.files!.first.id!;
      final drive.Media fileMedia = await driveApi.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final dbPath = await getDatabasesPath();
      final localFile = File(join(dbPath, DatabaseConfig.localDbName));

      final List<int> dataBytes = [];
      await for (final data in fileMedia.stream) {
        dataBytes.addAll(data);
      }
      await localFile.writeAsBytes(dataBytes);
      return true;
    } catch (e) {
      debugPrint('GDrive Restore Error: $e');
      return false;
    }
  }
}
