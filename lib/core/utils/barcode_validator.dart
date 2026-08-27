/// Utility untuk validasi dan sanitasi barcode serta nama produk
/// standar ritel internasional (GS1 GTIN: EAN-8, UPC-A, EAN-13, ITF-14).
class BarcodeValidator {
  BarcodeValidator._();

  static final RegExp _digitsOnlyRegex = RegExp(r'^\d+$');
  static final RegExp _dummyNamesRegex = RegExp(
    r'^(test|tes|asdf|null|undefined|sample|dummy|\.|\-)$',
    caseSensitive: false,
  );
  static final RegExp _whitespaceRegex = RegExp(r'\s+');
  static final RegExp _controlCharsRegex = RegExp(r'[\x00-\x1f\x7f-\x9f]');

  /// Menghitung dan memvalidasi GS1 Modulo 10 Checksum.
  /// Mendukung panjang 8 (EAN-8), 12 (UPC-A), 13 (EAN-13), dan 14 (ITF-14).
  static bool isValidChecksum(String barcode) {
    if (!_digitsOnlyRegex.hasMatch(barcode)) return false;
    final len = barcode.length;
    if (len != 8 && len != 12 && len != 13 && len != 14) return false;

    final digits = barcode.split('').map((c) => int.parse(c)).toList();
    final checkDigit = digits.last;
    final payload = digits.sublist(0, len - 1);

    int total = 0;
    // Iterasi dari kanan ke kiri dari payload (bobot selang-seling 3 dan 1)
    for (int i = 0; i < payload.length; i++) {
      final digit = payload[payload.length - 1 - i];
      final weight = (i % 2 == 0) ? 3 : 1;
      total += digit * weight;
    }

    final expectedCheckDigit = (10 - (total % 10)) % 10;
    return checkDigit == expectedCheckDigit;
  }

  /// Memeriksa apakah barcode adalah barcode ritel standar yang valid (bukan dummy/smell).
  static bool isValidStandardBarcode(String? rawBarcode) {
    if (rawBarcode == null) return false;
    final bc = rawBarcode.trim();
    if (bc.isEmpty) return false;

    // 1. Harus seluruhnya angka
    if (!_digitsOnlyRegex.hasMatch(bc)) return false;

    // 2. Panjang standar GTIN
    if (bc.length != 8 && bc.length != 12 && bc.length != 13 && bc.length != 14) {
      return false;
    }

    // 3. Bukan angka berulang semua (misal 00000000, 88888888)
    final firstChar = bc[0];
    if (bc.split('').every((c) => c == firstChar)) return false;

    // 4. Bukan padding nol berlebih (misal 0000012)
    if (bc.startsWith('00000')) return false;

    // 5. Validasi Checksum GS1
    return isValidChecksum(bc);
  }

  /// Membersihkan nama produk (unescape HTML entities, hapus karakter kontrol, normalisasi spasi).
  static String cleanProductName(String? rawName) {
    if (rawName == null) return '';
    String name = rawName.replaceAll(_controlCharsRegex, '');

    // Unescape HTML entities umum
    name = name
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&nbsp;', ' ');

    return name.replaceAll(_whitespaceRegex, ' ').trim();
  }

  /// Memvalidasi kelayakan nama produk.
  static bool isValidProductName(String? rawName) {
    final cleaned = cleanProductName(rawName);
    if (cleaned.length < 2) return false;
    if (_dummyNamesRegex.hasMatch(cleaned)) return false;
    return true;
  }

  /// Validasi menyeluruh pasangan barcode & nama produk untuk sync master katalog.
  static bool isValidMasterProduct(String? barcode, String? name) {
    return isValidStandardBarcode(barcode) && isValidProductName(name);
  }
}
