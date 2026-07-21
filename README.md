# Dodolanku (YourCashier)

Aplikasi Kasir POS (Point of Sale) Sederhana utk Retail Kecil berbasis Flutter.

## Build APK (Release & Size Optimized)

**Option 1: Split Per ABI (Rekomendasi - Ukuran Terkecil ~12-15 MB)**
```bash
flutter build apk --split-per-abi --release --obfuscate --split-debug-info=build/app/outputs/symbols
```

**Option 2: Universal APK (Satu File APK Terkompresi ~20 MB)**
```bash
flutter build apk --release --obfuscate --split-debug-info=build/app/outputs/symbols
```

