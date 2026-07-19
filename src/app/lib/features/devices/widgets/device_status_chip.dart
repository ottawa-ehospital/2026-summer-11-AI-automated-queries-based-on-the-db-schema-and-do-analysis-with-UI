import 'package:flutter/material.dart';

import '../presentation/device_styles.dart';

class DeviceStatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const DeviceStatusChip({
    super.key,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: DeviceStyles.statusChipDecoration(color),
      child: Text(
        label,
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}
