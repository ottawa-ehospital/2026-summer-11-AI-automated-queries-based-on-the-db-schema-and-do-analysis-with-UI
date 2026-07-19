import 'package:flutter/material.dart';

import '../../../ui/ui.dart';
import '../presentation/device_styles.dart';

class DeviceInfoBanner extends StatelessWidget {
  final String title;
  final String body;

  const DeviceInfoBanner({
    super.key,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: DeviceStyles.bannerMargin,
      padding: DeviceStyles.bannerPadding,
      decoration: DeviceStyles.bannerDecoration,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: AppColors.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: DeviceStyles.bannerTitle),
                const SizedBox(height: AppSpacing.xs),
                Text(body, style: DeviceStyles.bannerBody),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
