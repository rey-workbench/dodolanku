import 'dart:developer' as dev;
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image/image.dart' as img;
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:dodolanku/features/scanner/models/cart_item_model.dart';
import 'package:dodolanku/core/database_service.dart';
import 'package:dodolanku/core/utils/currency_formatter.dart';

import 'package:dodolanku/core/services/permission_service.dart';

class PrintService {
  static final PrintService instance = PrintService._internal();
  PrintService._internal();

  final DatabaseService _db = DatabaseService();

  static const _autoPrintKey = 'auto_print';
  static const _paperSizeKey = 'paper_size';

  bool _isAutoPrintEnabled = true;
  bool get isAutoPrintEnabled => _isAutoPrintEnabled;

  String _paperSize = '58';
  String get paperSize => _paperSize;

  
  
  Future<void> loadSettings() async {
    try {
      await _db.initDb();
      final auto = await _db.getSetting(_autoPrintKey);
      if (auto != null) _isAutoPrintEnabled = auto == '1';
      final size = await _db.getSetting(_paperSizeKey);
      if (size != null && (size == '58' || size == '80')) _paperSize = size;
    } catch (_) {
      
    }
  }

  void setAutoPrint(bool value) {
    _isAutoPrintEnabled = value;
    _db.setSetting(_autoPrintKey, value ? '1' : '0');
  }

  void setPaperSize(String value) {
    _paperSize = value;
    _db.setSetting(_paperSizeKey, value);
  }

  
  Future<List<BluetoothInfo>> getPairedDevices() async {
    try {
      
      final bool hasPermission = await PermissionService.instance.requestBluetoothPermissions();
      if (!hasPermission) {
        dev.log('Bluetooth permissions are not granted');
        return [];
      }

      final bool isBluetoothEnabled = await PrintBluetoothThermal.bluetoothEnabled;
      if (!isBluetoothEnabled) {
        dev.log('Bluetooth is disabled');
        return [];
      }
      final List<BluetoothInfo> devices = await PrintBluetoothThermal.pairedBluetooths;
      return devices;
    } catch (e) {
      dev.log('Error getting bluetooth devices: $e');
      return [];
    }
  }

  
  Future<bool> connect(String macAddress) async {
    try {
      final bool result = await PrintBluetoothThermal.connect(
        macPrinterAddress: macAddress,
      );
      dev.log('Connection result to $macAddress: $result');
      return result;
    } catch (e) {
      dev.log('Error connecting to device: $e');
      return false;
    }
  }

  
  Future<bool> disconnect() async {
    try {
      final bool result = await PrintBluetoothThermal.disconnect;
      dev.log('Disconnection result: $result');
      return result;
    } catch (e) {
      dev.log('Error disconnecting: $e');
      return false;
    }
  }

  
  Future<bool> isConnected() async {
    try {
      return await PrintBluetoothThermal.connectionStatus;
    } catch (e) {
      return false;
    }
  }

  
  Future<bool> printTest() async {
    if (!await isConnected()) return false;

    
    await _db.initDb();
    final config = await _db.getReceiptConfig();
    final storeName = config['store_name'] ?? 'dodolanku';
    final storeAddress = config['store_address'] ?? '';

    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);
    List<int> bytes = [];

    bytes += generator.reset();
    if (storeName.isNotEmpty) {
      bytes += generator.text(
        storeName,
        styles: const PosStyles(
          align: PosAlign.center,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
          bold: true,
        ),
      );
    }
    if (storeAddress.isNotEmpty) {
      bytes += generator.text(storeAddress, styles: const PosStyles(align: PosAlign.center));
    }
    bytes += generator.hr();
    bytes += generator.text('PRINTER CONNECTED!', styles: const PosStyles(align: PosAlign.center, bold: true));
    bytes += generator.text('Ready to print receipt.', styles: const PosStyles(align: PosAlign.center));
    bytes += generator.feed(1);
    
    
    bytes += generator.hr();
    bytes += generator.text('powered by :', styles: const PosStyles(align: PosAlign.center));
    bytes += generator.text('reynaldsilva.my.id', styles: const PosStyles(align: PosAlign.center, bold: true));
    bytes += generator.feed(3);

    final bool result = await PrintBluetoothThermal.writeBytes(bytes);
    return result;
  }

  Future<img.Image?> _getLogo(int printWidth) async {
    try {
      final svgString = await rootBundle.loadString('assets/logo.svg');
      final pictureInfo = await vg.loadPicture(SvgStringLoader(svgString), null);
      
      
      final int rawWidth = (printWidth * 0.2).clamp(64.0, 96.0).toInt();
      final int targetWidth = (rawWidth ~/ 8) * 8;
      final double ratio = pictureInfo.size.height / pictureInfo.size.width;
      final int targetHeight = (targetWidth * ratio).toInt();
      
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      
      canvas.drawRect(
        ui.Rect.fromLTWH(0, 0, targetWidth.toDouble(), targetHeight.toDouble()),
        ui.Paint()..color = const ui.Color(0xFFFFFFFF),
      );
      
      canvas.scale(targetWidth.toDouble() / pictureInfo.size.width);
      canvas.drawPicture(pictureInfo.picture);
      
      final ui.Image image = await recorder.endRecording().toImage(targetWidth.toInt(), targetHeight);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;
      return img.decodeImage(byteData.buffer.asUint8List());
    } catch (e) {
      dev.log('Error loading logo: $e');
      return null;
    }
  }

  
  Future<bool> printReceipt({
    required double total,
    required double paid,
    required double change,
    required String paymentMethod,
    required List<CartItem> items,
  }) async {
    if (!await isConnected()) return false;

    
    await _db.initDb();
    final config = await _db.getReceiptConfig();
    final storeName = config['store_name'] ?? 'dodolanku';
    final storeAddress = config['store_address'] ?? '';
    final storePhone = config['store_phone'] ?? '';
    final headerMsg = config['header_msg'] ?? '';
    final footerMsg = config['footer_msg'] ?? 'Terima Kasih';

    final is80 = _paperSize == '80';
    final maxChars = is80 ? 48 : 32; 
    final printWidth = is80 ? 576 : 384;

    final profile = await CapabilityProfile.load();
    final generator = Generator(is80 ? PaperSize.mm80 : PaperSize.mm58, profile);
    List<int> bytes = [];

    bytes += generator.reset();
    
    
    final logoImage = await _getLogo(printWidth);
    if (logoImage != null) {
      bytes += generator.image(logoImage);
    }
    
    
    if (storeName.isNotEmpty) {
      bytes += generator.text(
        storeName,
        styles: const PosStyles(
          align: PosAlign.center,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
          bold: true,
        ),
      );
    }
    
    if (storeAddress.isNotEmpty) {
      bytes += generator.text(storeAddress, styles: const PosStyles(align: PosAlign.center));
    }
    if (storePhone.isNotEmpty) {
      bytes += generator.text('Phone: $storePhone', styles: const PosStyles(align: PosAlign.center));
    }
    if (headerMsg.isNotEmpty) {
      bytes += generator.text(headerMsg, styles: const PosStyles(align: PosAlign.center, bold: true));
    }
    
    final now = DateTime.now();
    final dateStr = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    
    final spaceCountDT = maxChars - dateStr.length - timeStr.length;
    final spacesDT = spaceCountDT > 0 ? ' ' * spaceCountDT : ' ';
    bytes += generator.text('$dateStr$spacesDT$timeStr');
    
    bytes += generator.hr();

    
    for (final item in items) {
      bytes += generator.text(item.name);
      final qtyPrice = '${item.qty} x ${formatRupiah(item.price)}';
      final subtotal = formatRupiah(item.subtotal);
      
      final spaceCount = maxChars - qtyPrice.length - subtotal.length;
      final spaces = spaceCount > 0 ? ' ' * spaceCount : ' ';
      bytes += generator.text('$qtyPrice$spaces$subtotal');
    }
    bytes += generator.hr();

    
    final totalStr = formatRupiah(total);
    final paidStr = formatRupiah(paid);
    final changeStr = formatRupiah(change);

    final totalLabel = 'TOTAL';
    final totalSpace = maxChars - totalLabel.length - totalStr.length;
    bytes += generator.text(
      '$totalLabel${' ' * (totalSpace > 0 ? totalSpace : 1)}$totalStr',
      styles: const PosStyles(bold: true),
    );

    final payLabel = 'BAYAR (${paymentMethod.toUpperCase()})';
    final paySpace = maxChars - payLabel.length - paidStr.length;
    bytes += generator.text('$payLabel${' ' * (paySpace > 0 ? paySpace : 1)}$paidStr');

    final changeLabel = 'KEMBALIAN';
    final changeSpace = maxChars - changeLabel.length - changeStr.length;
    bytes += generator.text('$changeLabel${' ' * (changeSpace > 0 ? changeSpace : 1)}$changeStr');
    
    bytes += generator.hr();
    if (footerMsg.isNotEmpty) {
      bytes += generator.text(footerMsg, styles: const PosStyles(align: PosAlign.center, bold: true));
    }
    
    bytes += generator.feed(1);

    final bool result = await PrintBluetoothThermal.writeBytes(bytes);
    return result;
  }
}
