import 'dart:developer' as dev;
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static final PermissionService instance = PermissionService._internal();
  PermissionService._internal();

  
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

  
  Future<bool> requestBluetoothPermissions() async {
    try {
      
      final connectStatus = await Permission.bluetoothConnect.request();
      dev.log('Bluetooth Connect permission status: $connectStatus');
      
      
      final scanStatus = await Permission.bluetoothScan.request();
      dev.log('Bluetooth Scan permission status: $scanStatus');

      
      final locationStatus = await Permission.location.request();
      dev.log('Location permission status: $locationStatus');

      return connectStatus.isGranted;
    } catch (e) {
      dev.log('Error requesting bluetooth permissions: $e');
      return false;
    }
  }

  
  Future<bool> hasCameraPermission() async {
    return await Permission.camera.isGranted;
  }

  
  Future<bool> hasBluetoothPermission() async {
    return await Permission.bluetoothConnect.isGranted;
  }
}
