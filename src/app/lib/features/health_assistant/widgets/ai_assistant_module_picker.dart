import 'package:flutter/material.dart';

import '../presentation/assistant_styles.dart';

class AiAssistantModuleDefinition {
  const AiAssistantModuleDefinition({
    required this.id,
    required this.label,
    required this.description,
    required this.icon,
    required this.builder,
  });

  final String id;
  final String label;
  final String description;
  final IconData icon;
  final WidgetBuilder builder;
}

class AiAssistantModulePicker extends StatefulWidget {
  const AiAssistantModulePicker({
    super.key,
    required this.modules,
    required this.selectedIndex,
    required this.onSelected,
    required this.onLaunch,
  });

  final List<AiAssistantModuleDefinition> modules;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final ValueChanged<AiAssistantModuleDefinition> onLaunch;

  @override
  State<AiAssistantModulePicker> createState() =>
      _AiAssistantModulePickerState();
}

class _AiAssistantModulePickerState extends State<AiAssistantModulePicker> {
  late final PageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PageController(
      initialPage: widget.selectedIndex,
      viewportFraction: 0.48,
    );
  }

  @override
  void didUpdateWidget(covariant AiAssistantModulePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedIndex != oldWidget.selectedIndex &&
        _controller.hasClients &&
        _controller.page?.round() != widget.selectedIndex) {
      _controller.animateToPage(
        widget.selectedIndex,
        duration: AssistantStyles.pickerAnimationDuration,
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap(int index) {
    if (index == widget.selectedIndex) {
      widget.onLaunch(widget.modules[index]);
      return;
    }
    widget.onSelected(index);
    _controller.animateToPage(
      index,
      duration: AssistantStyles.pickerAnimationDuration,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.modules.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight.isFinite
            ? constraints.maxHeight.clamp(280.0, double.infinity)
            : 420.0;

        return SizedBox(
          height: height,
          child: PageView.builder(
            key: const ValueKey('ai-module-picker-pages'),
            controller: _controller,
            scrollDirection: Axis.vertical,
            itemCount: widget.modules.length,
            onPageChanged: widget.onSelected,
            itemBuilder: (context, index) {
              final module = widget.modules[index];
              final selected = index == widget.selectedIndex;
              return _AiAssistantModulePickerItem(
                module: module,
                selected: selected,
                onTap: () => _handleTap(index),
              );
            },
          ),
        );
      },
    );
  }
}

class _AiAssistantModulePickerItem extends StatelessWidget {
  const _AiAssistantModulePickerItem({
    required this.module,
    required this.selected,
    required this.onTap,
  });

  final AiAssistantModuleDefinition module;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleStyle = selected
        ? AssistantStyles.pickerSelectedTitle
        : AssistantStyles.pickerTitle;
    final descriptionStyle = selected
        ? AssistantStyles.pickerSelectedDescription
        : AssistantStyles.pickerDescription;

    return Semantics(
      button: true,
      selected: selected,
      label: '${module.label}. ${module.description}',
      child: AnimatedScale(
        scale: selected ? 1 : 0.9,
        duration: AssistantStyles.pickerAnimationDuration,
        curve: Curves.easeOutCubic,
        child: AnimatedOpacity(
          opacity: selected ? 1 : 0.52,
          duration: AssistantStyles.pickerAnimationDuration,
          child: Padding(
            padding: AssistantStyles.pickerItemOuterPadding,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                key: ValueKey('ai-module-${module.id}'),
                borderRadius: AssistantStyles.pickerItemRadius,
                onTap: onTap,
                child: AnimatedContainer(
                  duration: AssistantStyles.pickerAnimationDuration,
                  curve: Curves.easeOutCubic,
                  padding: AssistantStyles.pickerItemPadding,
                  decoration: AssistantStyles.pickerItemDecoration(
                    selected: selected,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: AssistantStyles.pickerIconDecoration(
                          selected: selected,
                        ),
                        child: Icon(
                          module.icon,
                          color: selected
                              ? Colors.white
                              : theme.colorScheme.primary,
                          size: selected ? 28 : 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              module.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: titleStyle,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              module.description,
                              maxLines: selected ? 2 : 1,
                              overflow: TextOverflow.ellipsis,
                              style: descriptionStyle,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      AnimatedContainer(
                        duration: AssistantStyles.pickerAnimationDuration,
                        width: selected ? 44 : 34,
                        height: selected ? 44 : 34,
                        decoration: AssistantStyles.pickerLaunchDecoration(
                          selected: selected,
                        ),
                        child: Icon(
                          Icons.arrow_forward,
                          color: selected
                              ? Colors.white
                              : theme.colorScheme.primary,
                          size: selected ? 22 : 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
