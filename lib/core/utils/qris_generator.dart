class QrisGenerator {
  static String makeDynamic({
    required String staticQris,
    required double amount,
  }) {
    if (staticQris.isEmpty) return '';

    try {
      String payload = staticQris;

      // 1. Remove the existing CRC (last 8 characters)
      final crcIndex = payload.lastIndexOf('6304');
      if (crcIndex != -1) {
        payload = payload.substring(0, crcIndex);
      }

      // 2. Change Point of Initiation Method to Dynamic (010211 -> 010212)
      if (payload.startsWith('000201010211')) {
        payload = payload.replaceFirst('000201010211', '000201010212');
      }

      // 3. Inject Tag 54 (Transaction Amount)
      final amountStr = amount.toInt().toString();
      final lengthStr = amountStr.length.toString().padLeft(2, '0');
      final tag54 = '54$lengthStr$amountStr';

      // It must be inserted before Tag 58 (Country Code '5802ID')
      final tag58Index = payload.indexOf('5802ID');
      if (tag58Index != -1) {
        payload = payload.substring(0, tag58Index) + tag54 + payload.substring(tag58Index);
      } else {
        // Fallback: insert before Tag 59 or 60 or just append
        final tag59Index = payload.indexOf('59'); // Merchant Name
        if (tag59Index != -1 && tag59Index > 20) {
           payload = payload.substring(0, tag59Index) + tag54 + payload.substring(tag59Index);
        } else {
           payload = payload + tag54;
        }
      }

      // 4. Append CRC tag prefix: '6304'
      final dataToCrc = '${payload}6304';

      // 5. Calculate accurate CRC-16 (CCITT-FALSE)
      final crcHex = _calculateCRC16(dataToCrc);

      return '$dataToCrc$crcHex';
    } catch (e) {
      // Jika static QRIS tidak valid, kembalikan static QRIS as-is
      return staticQris;
    }
  }

  static String extractMerchantName(String qris) {
    final idx = qris.indexOf('59');
    if (idx != -1 && idx + 4 <= qris.length) {
      try {
        final len = int.parse(qris.substring(idx + 2, idx + 4));
        if (idx + 4 + len <= qris.length) {
          return qris.substring(idx + 4, idx + 4 + len);
        }
      } catch (_) {}
    }
    return 'QRIS Terdaftar';
  }

  static String _calculateCRC16(String input) {
    int crc = 0xFFFF;
    for (int i = 0; i < input.length; i++) {
      crc ^= (input.codeUnitAt(i) << 8);
      for (int j = 0; j < 8; j++) {
        if ((crc & 0x8000) != 0) {
          crc = (crc << 1) ^ 0x1021;
        } else {
          crc <<= 1;
        }
      }
    }
    return (crc & 0xFFFF).toRadixString(16).toUpperCase().padLeft(4, '0');
  }
}
