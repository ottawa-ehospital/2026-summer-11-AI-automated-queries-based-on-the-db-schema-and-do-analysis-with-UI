import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../ui/ui.dart';

class EditGoalDialog extends StatefulWidget {
  final AppLocalizations l10n;
  final String title;
  final String unit;
  final double currentValue;
  final double min;
  final double max;
  final bool isInt;

  const EditGoalDialog({
    super.key,
    required this.l10n,
    required this.title,
    required this.unit,
    required this.currentValue,
    required this.min,
    required this.max,
    required this.isInt,
  });

  @override
  State<EditGoalDialog> createState() => _EditGoalDialogState();
}

class _EditGoalDialogState extends State<EditGoalDialog> {
  late double _value = widget.currentValue;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: AppRadii.radius(AppRadii.dialog)),
      title: Text(widget.l10n.editGoalTitle(widget.title)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.isInt
                ? widget.l10n.metricValueInt(_value.round(), widget.unit)
                : widget.l10n.metricValueDecimal(_value, widget.unit),
            style: AppTypography.screenTitle.copyWith(color: AppColors.primary),
          ),
          Slider(
            value: _value,
            min: widget.min,
            max: widget.max,
            divisions: widget.isInt ? (widget.max - widget.min).round() : ((widget.max - widget.min) * 2).round(),
            activeColor: AppColors.primary,
            onChanged: (value) => setState(() => _value = value),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(widget.l10n.cancelButton)),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _value),
          child: Text(widget.l10n.saveButton),
        ),
      ],
    );
  }
}
