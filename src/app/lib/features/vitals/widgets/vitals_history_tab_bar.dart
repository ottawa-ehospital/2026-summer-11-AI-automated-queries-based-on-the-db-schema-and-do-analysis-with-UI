import 'package:flutter/material.dart';

import '../../../ui/ui.dart';
import '../presentation/vitals_history_styles.dart';

class VitalsHistoryTabItem {
  final IconData icon;
  final String label;
  final Color color;

  const VitalsHistoryTabItem({
    required this.icon,
    required this.label,
    required this.color,
  });
}

class VitalsHistoryTabBar extends StatelessWidget {
  final List<VitalsHistoryTabItem> tabs;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const VitalsHistoryTabBar({
    super.key,
    required this.tabs,
    required this.selectedIndex,
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
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 10),
              decoration: VitalsHistoryStyles.tabDecoration(selected: selected, color: tab.color),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(tab.icon, size: 15, color: selected ? Colors.white : tab.color),
                  const SizedBox(width: 6),
                  Text(
                    tab.label,
                    style: TextStyle(color: selected ? Colors.white : tab.color, fontWeight: FontWeight.w600, fontSize: 13),
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
