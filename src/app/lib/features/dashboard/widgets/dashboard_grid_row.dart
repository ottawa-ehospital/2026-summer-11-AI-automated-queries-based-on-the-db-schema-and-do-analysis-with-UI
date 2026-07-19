import 'package:flutter/material.dart';

class DashboardGridRow extends StatelessWidget {
  final Widget left;
  final Widget right;

  const DashboardGridRow({
    super.key,
    required this.left,
    required this.right,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: left),
        const SizedBox(width: 14),
        Expanded(child: right),
      ],
    );
  }
}
