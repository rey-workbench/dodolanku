import 'package:flutter/material.dart';
import 'package:dodolanku/core/widgets/app_widgets.dart';
import 'package:dodolanku/core/services/print_service.dart';
import 'package:dodolanku/features/scanner/providers/scanner_provider.dart';

void showPrintDialog(BuildContext context, CheckoutResult result) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final primary = Theme.of(ctx).colorScheme.primary;
      return Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(
          20, 12, 20,
          24 + MediaQuery.of(ctx).padding.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            // Icon
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.receipt_long_rounded, color: primary, size: 28),
            ),
            const SizedBox(height: 14),
            const Text(
              'Cetak Struk?',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87),
            ),
            const SizedBox(height: 6),
            Text(
              'Apakah Anda ingin mencetak struk untuk transaksi ini?',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Lewati', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.print_rounded, size: 18),
                    label: const Text('Cetak', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      final connected = await PrintService.instance.isConnected();
                      if (!context.mounted) return;
                      if (!connected) {
                        AppToast.show(
                          context,
                          message: 'Printer tidak terhubung. Sambungkan printer di Pengaturan.',
                          isError: true,
                          bottomMargin: 24,
                        );
                        return;
                      }
                      final ok = await PrintService.instance.printReceipt(
                        total: result.total,
                        paid: result.amountPaid,
                        change: result.change,
                        paymentMethod: result.paymentMethod,
                        items: result.items,
                      );
                      if (context.mounted) {
                        AppToast.show(
                          context,
                          message: ok ? 'Struk berhasil dicetak!' : 'Gagal mencetak struk.',
                          isError: !ok,
                          bottomMargin: 24,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}
