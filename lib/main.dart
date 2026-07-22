import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/theme.dart';
import 'features/navigation/views/navigation_shell.dart';
import 'core/services/gdrive_service.dart';

/// Provider untuk menjembatani backup otomatis secara silent
final autoBackupProvider = Provider<VoidCallback>((ref) {
  return () => GDriveService.uploadBackupSilently();
});

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: ".env");
  } catch (_) {}

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
    // Jalankan auto backup pertama kali dibuka
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
      title: 'dodolanku Barcode Scanner',
      theme: AppTheme.lightTheme,
      home: const NavigationShell(),
      debugShowCheckedModeBanner: false,
    );
  }
}
