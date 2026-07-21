import 'package:flutter/material.dart';

/// Card flat putih dengan border abu tipis — pengganti standar Card di seluruh app.
///
/// Contoh:
/// ```dart
/// AppCard(child: Text('Konten'))
/// AppCard(padding: EdgeInsets.all(20), onTap: () {}, child: Column(...))
/// ```
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.borderRadius = 16,
    this.margin,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final double borderRadius;
  final EdgeInsets? margin;

  @override
  Widget build(BuildContext context) {
    final box = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Padding(padding: padding, child: child),
    );

    return onTap != null ? GestureDetector(onTap: onTap, child: box) : box;
  }
}

/// Card peringatan dengan icon kiri, judul + subtitle tengah, action kanan.
///
/// Contoh:
/// ```dart
/// AppAlertCard(
///   icon: Icons.warning_amber_rounded,
///   title: 'Beras Setra Ramos 5kg',
///   subtitle: 'Stok kosong',
///   color: Colors.red,
///   actionLabel: 'Pesan Lagi',
///   onAction: () {},
/// )
/// ```
class AppAlertCard extends StatelessWidget {
  const AppAlertCard({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.color = const Color(0xFFD97706), // Gunakan Amber/Oranye hangat sebagai warna warning default
    this.actionLabel,
    this.onAction,
    this.margin,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Color color;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EdgeInsets? margin;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: margin,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ],
            ),
          ),
          if (actionLabel != null && onAction != null)
            ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                actionLabel!,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }
}
