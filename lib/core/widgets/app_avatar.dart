import 'package:flutter/material.dart';

/// CircleAvatar menampilkan inisial huruf pertama dari [name].
class AppInitialAvatar extends StatelessWidget {
  const AppInitialAvatar({
    super.key,
    required this.name,
    this.radius = 20,
  });

  final String name;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return CircleAvatar(
      radius: radius,
      backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
      child: Text(
        initial,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// CircleAvatar menampilkan icon — histori scan, profil pengaturan, dll.
class AppIconAvatar extends StatelessWidget {
  const AppIconAvatar({
    super.key,
    required this.icon,
    this.radius = 20,
    this.backgroundColor,
    this.iconColor,
  });

  final IconData icon;
  final double radius;
  final Color? backgroundColor;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor:
          backgroundColor ?? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
      child: Icon(
        icon,
        color: iconColor ?? Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
