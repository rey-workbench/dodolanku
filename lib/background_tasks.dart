import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:workmanager/workmanager.dart';
import 'core/config/database_config.dart';
import 'core/services/gdrive_service.dart';

@pragma('vm:entry-point')
void backgroundCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      final dbPath = await getDatabasesPath();
      final db = await openDatabase(
        p.join(dbPath, DatabaseConfig.localDbName),
      );
      try {
        await db.rawQuery('PRAGMA wal_checkpoint(TRUNCATE);');
      } catch (_) {}
      await db.close();
    } catch (_) {}
    await GDriveService.uploadBackupSilently();
    return true;
  });
}

class BackgroundTasks {
  static const _taskName = 'dodolanku.gdrive_backup';

  static void init() {
    Workmanager().initialize(backgroundCallbackDispatcher);
    Workmanager().registerPeriodicTask(
      _taskName,
      _taskName,
      frequency: const Duration(hours: 6),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    );
  }
}
