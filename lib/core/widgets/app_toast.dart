import 'package:flutter/material.dart';

class AppToast {
  static void show(
    BuildContext context, {
    required String message,
    bool isError = false,
    IconData? icon,
    double? bottomMargin,
  }) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final theme = Theme.of(context);

    // Hapus SnackBar aktif agar tidak menumpuk
    scaffoldMessenger.clearSnackBars();

    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              icon ?? (isError ? Icons.error_outline : Icons.check_circle_outline),
              color: isError ? Colors.red[800] : theme.colorScheme.primary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        // Gaya Floating premium di bagian bawah layar
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.white,
        elevation: 6,
        margin: EdgeInsets.only(
          bottom: bottomMargin ?? 16,
          left: 16,
          right: 16,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isError ? Colors.red.shade200 : theme.colorScheme.primary.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
