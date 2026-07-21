import 'package:flutter/services.dart';

String formatRupiah(num amount) {
  final isNegative = amount < 0;
  final val = amount.abs().toStringAsFixed(0);
  final result = StringBuffer();
  for (int i = 0; i < val.length; i++) {
    if (i > 0 && (val.length - i) % 3 == 0) result.write('.');
    result.write(val[i]);
  }
  return (isNegative ? '-' : '') + result.toString();
}

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final intValue = int.tryParse(newValue.text.replaceAll(RegExp(r'[^0-9]'), ''));
    if (intValue == null) return oldValue;

    final newText = formatRupiah(intValue);
    
    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}
