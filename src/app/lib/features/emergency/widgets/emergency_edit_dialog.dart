import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../ui/ui.dart';

class EmergencyEditDialog extends StatefulWidget {
  final AppLocalizations l10n;
  final String title;
  final String currentValue;
  final IconData icon;

  const EmergencyEditDialog({
    super.key,
    required this.l10n,
    required this.title,
    required this.currentValue,
    required this.icon,
  });

  @override
  State<EmergencyEditDialog> createState() => _EmergencyEditDialogState();
}

class _EmergencyEditDialogState extends State<EmergencyEditDialog> {
  late final TextEditingController _controller = TextEditingController(text: widget.currentValue);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: AppRadii.radius(AppRadii.dialog)),
      title: Text(widget.l10n.editFieldTitle(widget.title)),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(
          labelText: widget.title,
          prefixIcon: Icon(widget.icon, color: Colors.red.shade700),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(widget.l10n.cancelButton)),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
          onPressed: () => Navigator.pop(context, _controller.text.trim()),
          child: Text(widget.l10n.saveButton),
        ),
      ],
    );
  }
}
