import 'package:mobile_scanner/mobile_scanner.dart';

class ScannerConfig {
  static const List<BarcodeFormat> scannerFormats = [
    BarcodeFormat.ean8,
    BarcodeFormat.ean13,
    BarcodeFormat.code128,
    BarcodeFormat.code39,
    BarcodeFormat.upcA,
    BarcodeFormat.upcE,
  ];
}
