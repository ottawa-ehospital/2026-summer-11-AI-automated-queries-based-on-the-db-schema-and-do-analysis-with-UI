import 'package:flutter/material.dart';

class AppActionRow extends StatelessWidget {
  final List<Widget> children;
  final MainAxisAlignment alignment;

  const AppActionRow({
    super.key,
    required this.children,
    this.alignment = MainAxisAlignment.end,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: alignment,
      children: children,
    );
  }
}
