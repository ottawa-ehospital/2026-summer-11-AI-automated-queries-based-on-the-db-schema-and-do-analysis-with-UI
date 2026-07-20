import 'package:flutter/material.dart';
import '../../ui/ui.dart';

class AppFormPanel extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry padding;

  const AppFormPanel({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.all(AppSpacing.xxl),
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadii.radius(AppRadii.xl),
        boxShadow: AppShadows.soft,
      ),
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }
}
