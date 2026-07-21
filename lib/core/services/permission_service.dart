import 'dart:developer' as dev;
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static final PermissionService instance = PermissionService._internal();
  PermissionService._internal();

  /// Meminta izin kamera secara dinamis
  Future<bool> requestCameraPermission() async {
    try {
      final status = await Permission.camera.request();
      dev.log('Camera permission status: $status');
      return status.isGranted;
    } catch (e) {
      dev.log('Error requesting camera permission: $e');
      return false;
    }
  }

  /// Meminta izin Bluetooth secara dinamis (Connect & Scan untuk Android 12+)
  Future<bool> requestBluetoothPermissions() async {
    try {
      // Request Bluetooth Connect
      final connectStatus = await Permission.bluetoothConnect.request();
      dev.log('Bluetooth Connect permission status: $connectStatus');
      
      // Request Bluetooth Scan
      final scanStatus = await Permission.bluetoothScan.request();
      dev.log('Bluetooth Scan permission status: $scanStatus');

      // Request Location (diperlukan beberapa HP/Android lama untuk BLE)
      final locationStatus = await Permission.location.request();
      dev.log('Location permission status: $locationStatus');

      return connectStatus.isGranted;
    } catch (e) {
      dev.log('Error requesting bluetooth permissions: $e');
      return false;
    }
  }

  /// Cek apakah izin kamera sudah diberikan
  Future<bool> hasCameraPermission() async {
    return await Permission.camera.isGranted;
  }

  /// Cek apakah izin Bluetooth Connect sudah diberikan
  Future<bool> hasBluetoothPermission() async {
    return await Permission.bluetoothConnect.isGranted;
  }
}
