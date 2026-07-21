String formatRupiah(num amount) {
  final val = amount.abs().toStringAsFixed(0);
  final result = StringBuffer();
  for (int i = 0; i < val.length; i++) {
    if (i > 0 && (val.length - i) % 3 == 0) result.write('.');
    result.write(val[i]);
  }
  return result.toString();
}
