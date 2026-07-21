import 'package:flutter/material.dart';
import 'package:dodolanku/features/dashboard/views/dashboard_page.dart';
import 'package:dodolanku/features/orders/views/orders_page.dart';
import 'package:dodolanku/features/debt/views/debt_page.dart';
import 'package:dodolanku/features/settings/views/settings_page.dart';
import 'package:dodolanku/features/scanner/views/scanner_page.dart';

class NavigationShell extends StatefulWidget {
  const NavigationShell({super.key});

  @override
  State<NavigationShell> createState() => _NavigationShellState();
}

class _NavigationShellState extends State<NavigationShell> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    DashboardPage(),
    OrdersPage(),
    SizedBox.shrink(), // Placeholder for Scanner FAB
    DebtPage(),
    SettingsPage(),
  ];

  void _onTabSelected(int index) {
    if (index == 2) {
      Navigator.push(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 400),
          reverseTransitionDuration: const Duration(milliseconds: 350),
          pageBuilder: (context, animation, secondaryAnimation) => const ScannerPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        ),
      );
    } else {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Keep body behind the bottom nav bar notch
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      floatingActionButton: Hero(
        tag: 'scan_fab',
        child: FloatingActionButton(
          onPressed: () => _onTabSelected(2),
          heroTag: null, // Disable internal Hero
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          shape: const CircleBorder(),
          elevation: 0,
          child: const Icon(Icons.qr_code_scanner_rounded, size: 28),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
        ),
        child: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 8.0,
          color: Colors.white,
          elevation: 0,
          padding: EdgeInsets.zero,
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
            Expanded(child: _buildTabItem(icon: Icons.home_filled, label: 'Beranda', index: 0)),
            Expanded(child: _buildTabItem(icon: Icons.receipt_long_outlined, label: 'Riwayat', index: 1)),
            const SizedBox(width: 60), // Spacer for central FAB
            Expanded(child: _buildTabItem(icon: Icons.assignment_outlined, label: 'Hutang', index: 3)),
            Expanded(child: _buildTabItem(icon: Icons.more_horiz_outlined, label: 'Lainnya', index: 4)),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildTabItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? Theme.of(context).colorScheme.primary : Colors.grey[400];
    return InkWell(
      onTap: () => _onTabSelected(index),
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
