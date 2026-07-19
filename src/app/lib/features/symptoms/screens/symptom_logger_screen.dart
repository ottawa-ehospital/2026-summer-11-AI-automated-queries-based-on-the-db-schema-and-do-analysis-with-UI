import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/l10n.dart';
import '../../../ui/ui.dart';
import '../presentation/symptom_styles.dart';
import '../widgets/add_symptom_sheet.dart';
import '../widgets/symptom_card.dart';

class SymptomLoggerScreen extends StatefulWidget {
  const SymptomLoggerScreen({super.key});

  @override
  State<SymptomLoggerScreen> createState() => _SymptomLoggerScreenState();
}

class _SymptomLoggerScreenState extends State<SymptomLoggerScreen> {
  List<Map<String, dynamic>> _symptoms = [];
  int? _patientId;

  final _nameCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  double _severity = 3;

  @override
  void initState() {
    super.initState();
    _loadSymptoms();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSymptoms() async {
    final prefs = await SharedPreferences.getInstance();
    final rawId = prefs.get("patient_id");
    _patientId = int.tryParse(rawId?.toString() ?? '');
    if (_patientId == null) return;

    final raw = prefs.getString("symptoms_$_patientId") ?? "[]";
    final list = (jsonDecode(raw) as List).map((e) => Map<String, dynamic>.from(e)).toList();
    list.sort((a, b) => (b["timestamp"] as String).compareTo(a["timestamp"] as String));
    if (mounted) setState(() => _symptoms = list);
  }

  Future<void> _saveSymptoms() async {
    if (_patientId == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("symptoms_$_patientId", jsonEncode(_symptoms));
  }

  Future<void> _addSymptom() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    final entry = {
      "id": DateTime.now().millisecondsSinceEpoch.toString(),
      "name": name,
      "severity": _severity.round(),
      "notes": _notesCtrl.text.trim(),
      "timestamp": DateTime.now().toIso8601String(),
    };
    setState(() => _symptoms.insert(0, entry));
    await _saveSymptoms();
    _nameCtrl.clear();
    _notesCtrl.clear();
    setState(() => _severity = 3);
  }

  Future<void> _deleteSymptom(int index) async {
    setState(() => _symptoms.removeAt(index));
    await _saveSymptoms();
  }

  Color _severityColor(int severity) {
    if (severity <= 1) return Colors.green;
    if (severity == 2) return Colors.lightGreen;
    if (severity == 3) return Colors.orange;
    if (severity == 4) return Colors.deepOrange;
    return Colors.red;
  }

  String _severityLabel(int severity) {
    final l10n = context.l10n;
    switch (severity) {
      case 1:
        return l10n.severityVeryMild;
      case 2:
        return l10n.severityMild;
      case 3:
        return l10n.severityModerate;
      case 4:
        return l10n.severitySevere;
      default:
        return l10n.severityVerySevere;
    }
  }

  String _formatTime(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
      final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final ampm = dt.hour >= 12 ? "PM" : "AM";
      final min = dt.minute.toString().padLeft(2, "0");
      return "${months[dt.month - 1]} ${dt.day}, ${dt.year} at $h:$min $ampm";
    } catch (_) {
      return iso;
    }
  }

  void _showAddSheet() {
    setState(() {
      _severity = 3;
      _nameCtrl.clear();
      _notesCtrl.clear();
    });
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AddSymptomSheet(
          nameController: _nameCtrl,
          notesController: _notesCtrl,
          severity: _severity,
          onSeverityChanged: (value) => setModalState(() => _severity = value),
          severityColor: _severityColor,
          severityLabel: _severityLabel,
          onAdd: () {
            Navigator.pop(ctx);
            _addSymptom();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          AppSliverHeader(title: l10n.symptomLogTitle, icon: Icons.sick_outlined),
          _symptoms.isEmpty
              ? SliverFillRemaining(
                  child: EmptyStateView(
                    icon: Icons.sick_outlined,
                    title: l10n.noSymptomsLogged,
                    subtitle: l10n.tapLogSymptom,
                  ),
                )
              : SliverPadding(
                  padding: SymptomStyles.listPadding,
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => SymptomCard(
                        symptom: _symptoms[i],
                        severityColor: _severityColor,
                        severityLabel: _severityLabel,
                        formatTime: _formatTime,
                        onDelete: () => _deleteSymptom(i),
                      ),
                      childCount: _symptoms.length,
                    ),
                  ),
                ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddSheet,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
