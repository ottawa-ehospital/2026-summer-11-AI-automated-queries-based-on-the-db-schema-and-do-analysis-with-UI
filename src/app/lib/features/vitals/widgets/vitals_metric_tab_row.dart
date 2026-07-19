import 'package:flutter/material.dart';

import '../presentation/vitals_styles.dart';

class VitalsMetricTabData {
  final IconData icon;
  final String label;
  final Color color;

  const VitalsMetricTabData({
    required this.icon,
    required this.label,
    required this.color,
  });
}

class VitalsMetricTabRow extends StatelessWidget {
  final int selectedIndex;
  final List<VitalsMetricTabData> tabs;
  final ValueChanged<int> onSelected;

  const VitalsMetricTabRow({
    super.key,
    required this.selectedIndex,
    required this.tabs,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(tabs.length, (index) {
          final tab = tabs[index];
          final selected = selectedIndex == index;
          return GestureDetector(
            onTap: () => onSelected(index),
            child: AnimatedContainer(
              duration: VitalsStyles.mediumAnimation,
              margin: const EdgeInsets.only(right: 10),
              padding: VitalsStyles.metricTabPadding,
              decoration: VitalsStyles.metricTabDecoration(selected: selected, color: tab.color),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(tab.icon, size: 16, color: selected ? Colors.white : tab.color),
                  const SizedBox(width: 6),
                  Text(
                    tab.label,
                    style: TextStyle(
                      color: selected ? Colors.white : tab.color,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
