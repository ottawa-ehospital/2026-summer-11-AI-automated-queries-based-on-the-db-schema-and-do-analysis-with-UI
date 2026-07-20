import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/l10n.dart';
import '../../../ui/ui.dart';
import '../presentation/medication_styles.dart';
import '../widgets/add_medication_sheet.dart';
import '../widgets/medication_card.dart';

class MedicationTrackerScreen extends StatefulWidget {
  const MedicationTrackerScreen({super.key});

  @override
  State<MedicationTrackerScreen> createState() => _MedicationTrackerScreenState();
}

class _MedicationTrackerScreenState extends State<MedicationTrackerScreen> {
  List<Map<String, dynamic>> _meds = [];
  int? _patientId;

  final _nameCtrl = TextEditingController();
  final _dosageCtrl = TextEditingController();
  final _freqCtrl = TextEditingController();
  final _timeCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMeds();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _dosageCtrl.dispose();
    _freqCtrl.dispose();
    _timeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMeds() async {
    final prefs = await SharedPreferences.getInstance();
    final rawId = prefs.get("patient_id");
    _patientId = int.tryParse(rawId?.toString() ?? '');
    if (_patientId == null) return;

    final today = DateTime.now().toIso8601String().substring(0, 10);
    final lastReset = prefs.getString("lastResetDate_$_patientId") ?? "";
    final raw = prefs.getString("medications_$_patientId") ?? "[]";
    final meds = (jsonDecode(raw) as List).map((e) => Map<String, dynamic>.from(e)).toList();

    if (lastReset != today) {
      for (final m in meds) {
        m["takenToday"] = false;
      }
      await prefs.setString("medications_$_patientId", jsonEncode(meds));
      await prefs.setString("lastResetDate_$_patientId", today);
    }

    if (mounted) setState(() => _meds = meds);
  }

  Future<void> _saveMeds() async {
    if (_patientId == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("medications_$_patientId", jsonEncode(_meds));
  }

  Future<void> _addMed() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    final med = {
      "id": DateTime.now().millisecondsSinceEpoch.toString(),
      "name": name,
      "dosage": _dosageCtrl.text.trim(),
      "frequency": _freqCtrl.text.trim(),
      "time": _timeCtrl.text.trim(),
      "takenToday": false,
    };
    setState(() => _meds.add(med));
    await _saveMeds();
    _nameCtrl.clear();
    _dosageCtrl.clear();
    _freqCtrl.clear();
    _timeCtrl.clear();
  }

  Future<void> _toggleTaken(int index) async {
    setState(() => _meds[index]["takenToday"] = !(_meds[index]["takenToday"] as bool));
    await _saveMeds();
  }

  Future<void> _deleteMed(int index) async {
    setState(() => _meds.removeAt(index));
    await _saveMeds();
  }

  void _showAddSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => AddMedicationSheet(
        nameController: _nameCtrl,
        dosageController: _dosageCtrl,
        frequencyController: _freqCtrl,
        timeController: _timeCtrl,
        onAdd: () {
          Navigator.pop(ctx);
          _addMed();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          AppSliverHeader(title: l10n.medicationsTitle, icon: Icons.medication_outlined),
          _meds.isEmpty
              ? SliverFillRemaining(
                  child: EmptyStateView(
                    icon: Icons.medication_outlined,
                    title: l10n.noMedicationsYet,
                    subtitle: l10n.tapAddMedication,
                  ),
                )
              : SliverPadding(
                  padding: MedicationStyles.listPadding,
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => MedicationCard(
                        medication: _meds[i],
                        onToggleTaken: () => _toggleTaken(i),
                        onDelete: () => _deleteMed(i),
                      ),
                      childCount: _meds.length,
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
