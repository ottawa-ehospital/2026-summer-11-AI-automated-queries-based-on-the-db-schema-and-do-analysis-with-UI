import 'package:flutter/material.dart';

import '../presentation/device_styles.dart';

class DeviceSectionLabel extends StatelessWidget {
  final String text;

  const DeviceSectionLabel({
    super.key,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Text(text, style: DeviceStyles.sectionLabel);
  }
}
