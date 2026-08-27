import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/theme.dart';
import 'core/database_service.dart';
import 'background_tasks.dart';
import 'features/navigation/views/navigation_shell.dart';
import 'core/services/gdrive_service.dart';

final autoBackupProvider = Provider<VoidCallback>((ref) {
  return () async {
    try {
      final db = ref.read(databaseServiceProvider);
      await db.initDb();
      await db.forceCheckpoint();
    } catch (_) {}
    await GDriveService.uploadBackupSilently();
  };
});

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: ".env");
  } catch (_) {}

  BackgroundTasks.init();

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    _triggerBackup();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _triggerBackup();
    }
  }

  void _triggerBackup() {
    ref.read(autoBackupProvider)();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'dodolanku',
      theme: AppTheme.lightTheme,
      home: const NavigationShell(),
      debugShowCheckedModeBanner: false,
    );
  }
}
