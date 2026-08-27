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

  @override
  
  void close() {
    _client.close();
    super.close();
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

  
  static Future<void> uploadBackupSilently() async {
    try {
      
      final account = await _googleSignIn.signInSilently();
      if (account == null) return; 

      final authHeaders = await account.authHeaders;
      final client = GoogleAuthClient(authHeaders);
      try {
        final driveApi = drive.DriveApi(client);

        final dbPath = await getDatabasesPath();
        final file = File(join(dbPath, DatabaseConfig.localDbName));
        if (!await file.exists()) return;

        
        final fileList = await driveApi.files.list(
          spaces: 'appDataFolder',
          q: "name = 'dodolanku.db'",
        );

        final media = drive.Media(file.openRead(), file.lengthSync());

        if (fileList.files != null && fileList.files!.isNotEmpty) {
          final fileId = fileList.files!.first.id!;
          await driveApi.files.update(
            drive.File(),
            fileId,
            uploadMedia: media,
          );
        } else {
          final driveFile = drive.File()
            ..name = 'dodolanku.db'
            ..parents = ['appDataFolder'];
          await driveApi.files.create(
            driveFile,
            uploadMedia: media,
          );
        }
      } finally {
        client.close();
      }
    } catch (e) {
      debugPrint('GDrive Auto Backup Error: $e');
    }
  }

  
  static Future<String?> uploadBackup() async {
    try {
      var account = await currentUser();
      account ??= await signIn();
      if (account == null) return 'Gagal login ke akun Google.';

      final authHeaders = await account.authHeaders;
      
      final client = GoogleAuthClient(authHeaders);
      try {
        final driveApi = drive.DriveApi(client);

        final dbPath = await getDatabasesPath();
        final file = File(join(dbPath, DatabaseConfig.localDbName));
        if (!await file.exists()) return 'File database lokal (${DatabaseConfig.localDbName}) tidak ditemukan.';

        
        final fileList = await driveApi.files.list(
          spaces: 'appDataFolder',
          q: "name = 'dodolanku.db'",
        );

        final media = drive.Media(file.openRead(), file.lengthSync());

        if (fileList.files != null && fileList.files!.isNotEmpty) {
          
          final fileId = fileList.files!.first.id!;
          await driveApi.files.update(
            drive.File(),
            fileId,
            uploadMedia: media,
          );
        } else {
          
          final driveFile = drive.File()
            ..name = 'dodolanku.db'
            ..parents = ['appDataFolder'];
          await driveApi.files.create(
            driveFile,
            uploadMedia: media,
          );
        }
        return null; 
      } finally {
        client.close();
      }
    } catch (e) {
      debugPrint('GDrive Upload Error: $e');
      return e.toString();
    }
  }

  
  
  static Future<bool> restoreBackup({Future<void> Function()? onBeforeOverwrite}) async {
    try {
      var account = await currentUser();
      account ??= await signIn();
      if (account == null) return false;

      final authHeaders = await account.authHeaders;
      
      final client = GoogleAuthClient(authHeaders);
      try {
        final driveApi = drive.DriveApi(client);

        final fileList = await driveApi.files.list(
          spaces: 'appDataFolder',
          q: "name = 'dodolanku.db'",
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
        
        final tmpFile = File('${localFile.path}.tmp');
        await tmpFile.writeAsBytes(dataBytes, flush: true);
        
        
        if (onBeforeOverwrite != null) {
          await onBeforeOverwrite();
        }
        
        
        if (await localFile.exists()) await localFile.delete();
        final walFile = File('${localFile.path}-wal');
        if (await walFile.exists()) await walFile.delete();
        final shmFile = File('${localFile.path}-shm');
        if (await shmFile.exists()) await shmFile.delete();
        
        await tmpFile.rename(localFile.path);
        return true;
      } finally {
        client.close();
      }
    } catch (e) {
      debugPrint('GDrive Restore Error: $e');
      return false;
    }
  }
}
