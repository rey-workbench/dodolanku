import 'package:flutter/material.dart';

/// Chip kecil berlatar abu untuk menampilkan info ringkas (Harga, Stok, dll).
///
/// Contoh:
/// ```dart
/// AppInfoBadge(label: 'Harga: Rp 15.000')
/// AppInfoBadge(label: 'Stok: 50 pcs', color: Colors.green)
/// ```
class AppInfoBadge extends StatelessWidget {
  const AppInfoBadge({
    super.key,
    required this.label,
    this.color,
  });

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: color),
      ),
    );
  }
}

/// Badge status berwarna dengan background transparan.
///
/// Contoh:
/// ```dart
/// AppStatusBadge(label: 'Siap', color: Colors.green)
/// AppStatusBadge(label: 'Diproses', color: Colors.orange)
/// ```
class AppStatusBadge extends StatelessWidget {
  const AppStatusBadge({
    super.key,
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}
