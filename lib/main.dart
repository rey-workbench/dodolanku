import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/theme.dart';
import 'features/navigation/views/navigation_shell.dart';
import 'core/services/gdrive_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: ".env");
  } catch (_) {
    // If .env file fails to load, fallback gracefully
  }

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Jalankan auto backup saat aplikasi pertama kali dibuka
    _runAutoBackup();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // Jalankan auto backup saat aplikasi diminimize (di-background-kan)
      _runAutoBackup();
    }
  }

  void _runAutoBackup() {
    // Berjalan secara silent tanpa mengganggu UI
    GDriveService.uploadBackupSilently();
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
