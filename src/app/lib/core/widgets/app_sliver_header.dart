import 'package:flutter/material.dart';
import '../../ui/ui.dart';

class AppSliverHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Gradient gradient;
  final Color? backgroundColor;

  const AppSliverHeader({
    super.key,
    required this.title,
    required this.icon,
    this.gradient = AppGradients.primary,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 130,
      pinned: true,
      backgroundColor: backgroundColor,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        background: Container(
          decoration: BoxDecoration(gradient: gradient),
          child: Center(child: Icon(icon, size: 48, color: Colors.white54)),
        ),
      ),
    );
  }
}
