import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/widgets/widgets.dart';
import '../../../data/repositories/ehospital_repository.dart';
import '../../../l10n/l10n.dart';
import '../../../services/wearable_sync_service.dart';
import '../data/training_records_repository.dart';
import '../models/training_record.dart';
import '../widgets/edit_goal_dialog.dart';
import '../widgets/goals_tab_content.dart';
import '../widgets/training_records_tab.dart';

class HealthGoalsScreen extends StatefulWidget {
  const HealthGoalsScreen({
    super.key,
    this.ehospitalRepository,
    this.trainingRecordsRepository,
    this.wearableSyncService,
  });

  final EHospitalRepository? ehospitalRepository;
  final TrainingRecordsRepository? trainingRecordsRepository;
  final WearableSyncService? wearableSyncService;

  @override
  State<HealthGoalsScreen> createState() => _HealthGoalsScreenState();
}

enum _HealthGoalsTab { goals, trainingRecords }

class _HealthGoalsScreenState extends State<HealthGoalsScreen> {
  late final EHospitalRepository _ehospitalRepository =
      widget.ehospitalRepository ?? EHospitalRepository();
  late final TrainingRecordsRepository _trainingRecordsRepository =
      widget.trainingRecordsRepository ?? TrainingRecordsRepository();
  late final WearableSyncService _wearableSyncService =
      widget.wearableSyncService ?? WearableSyncService();

  bool _loading = true;
  bool _trainingRecordsLoading = false;
  bool _syncingWorkouts = false;
  int? _patientId;
  _HealthGoalsTab _selectedTab = _HealthGoalsTab.goals;
  List<TrainingRecord> _trainingRecords = const [];
  String? _trainingRecordsError;
  String? _trainingRecordsStatus;

  int _goalSteps = 8000;
  double _goalSleep = 8.0;
  int _goalCalories = 500;

  int _actualSteps = 0;
  double _actualSleep = 0;
  int _actualCalories = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final rawId = prefs.get('patient_id');
    _patientId = int.tryParse(rawId?.toString() ?? '');

    _goalSteps = prefs.getInt('goal_steps_$_patientId') ?? 8000;
    _goalSleep = prefs.getDouble('goal_sleep_$_patientId') ?? 8.0;
    _goalCalories = prefs.getInt('goal_calories_$_patientId') ?? 500;

    if (_patientId != null) {
      await _fetchActuals(_patientId!);
      await _loadTrainingRecords(showLoading: false);
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _fetchActuals(int patientId) async {
    try {
      final data = await _ehospitalRepository.fetchTable(
        'wearable_vitals',
        patientId: patientId.toString(),
      );

      if (data.isNotEmpty) {
        final sorted = List<dynamic>.from(data)
          ..sort((a, b) => _timestampOf(a).compareTo(_timestampOf(b)));
        final latest = sorted.last;
        _actualSteps = _parseInt(latest['steps']);
        _actualSleep = _parseDouble(latest['sleep']);
        _actualCalories = _parseInt(latest['calories']);
      }
    } catch (_) {}
  }

  Future<void> _loadTrainingRecords({
    bool showLoading = true,
    bool clearStatus = true,
  }) async {
    final patientId = _patientId;
    if (patientId == null) return;
    if (showLoading && mounted) {
      setState(() {
        _trainingRecordsLoading = true;
        _trainingRecordsError = null;
        if (clearStatus) _trainingRecordsStatus = null;
      });
    }
    try {
      final records = await _trainingRecordsRepository.fetchTrainingRecords(
        patientId: patientId.toString(),
      );
      if (!mounted) return;
      setState(() {
        _trainingRecords = records;
        _trainingRecordsError = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _trainingRecordsError =
            '${context.l10n.trainingRecordsError} ${error.toString()}';
      });
    } finally {
      if (showLoading && mounted) {
        setState(() => _trainingRecordsLoading = false);
      }
    }
  }

  Future<void> _syncPlatformWorkouts() async {
    final patientId = _patientId;
    if (patientId == null || _syncingWorkouts) return;
    setState(() {
      _syncingWorkouts = true;
      _trainingRecordsError = null;
      _trainingRecordsStatus = null;
    });
    try {
      final result = await _wearableSyncService.syncPlatformWorkouts(
        patientId: patientId.toString(),
      );
      if (!mounted) return;
      if (result.success) {
        await _loadTrainingRecords(clearStatus: false);
        if (!mounted) return;
        setState(() {
          _trainingRecordsStatus =
              '${context.l10n.trainingRecordsSyncSuccess} ${result.message}';
        });
      } else {
        setState(() => _trainingRecordsStatus = result.message);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _trainingRecordsError =
            '${context.l10n.trainingRecordsError} ${error.toString()}';
      });
    } finally {
      if (mounted) setState(() => _syncingWorkouts = false);
    }
  }

  String _timestampOf(dynamic item) {
    if (item is! Map) return "";
    return (item['timestamp'] ?? item['recorded_on'] ?? "").toString();
  }

  int _parseInt(dynamic value) => int.tryParse(value?.toString() ?? '') ?? 0;

  double _parseDouble(dynamic value) =>
      double.tryParse(value?.toString() ?? '') ?? 0.0;

  Future<void> _saveGoals() async {
    if (_patientId == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('goal_steps_$_patientId', _goalSteps);
    await prefs.setDouble('goal_sleep_$_patientId', _goalSleep);
    await prefs.setInt('goal_calories_$_patientId', _goalCalories);
  }

  Future<void> _editGoal({
    required String title,
    required String unit,
    required double currentValue,
    required double min,
    required double max,
    required bool isInt,
    required ValueChanged<double> onSave,
  }) async {
    final value = await showDialog<double>(
      context: context,
      builder: (context) => EditGoalDialog(
        l10n: context.l10n,
        title: title,
        unit: unit,
        currentValue: currentValue,
        min: min,
        max: max,
        isInt: isInt,
      ),
    );

    if (value == null) return;
    onSave(value);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          AppSliverHeader(
            title: l10n.healthGoalsTitle,
            icon: Icons.flag_outlined,
          ),
          if (_loading)
            SliverStateView.loading()
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<_HealthGoalsTab>(
                      segments: [
                        ButtonSegment(
                          value: _HealthGoalsTab.goals,
                          label: Text(l10n.healthGoalsGoalsTab),
                          icon: const Icon(Icons.flag_outlined),
                        ),
                        ButtonSegment(
                          value: _HealthGoalsTab.trainingRecords,
                          label: Text(l10n.healthGoalsTrainingRecordsTab),
                          icon: const Icon(Icons.fitness_center_outlined),
                        ),
                      ],
                      selected: {_selectedTab},
                      onSelectionChanged: (selection) {
                        setState(() => _selectedTab = selection.single);
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_selectedTab == _HealthGoalsTab.goals)
                    GoalsTabContent(
                      actualSteps: _actualSteps,
                      actualSleep: _actualSleep,
                      actualCalories: _actualCalories,
                      goalSteps: _goalSteps,
                      goalSleep: _goalSleep,
                      goalCalories: _goalCalories,
                      onEditGoal: _editGoal,
                      onSaveSteps: (value) {
                        setState(() => _goalSteps = value.round());
                        _saveGoals();
                      },
                      onSaveSleep: (value) {
                        setState(
                          () => _goalSleep = double.parse(
                            value.toStringAsFixed(1),
                          ),
                        );
                        _saveGoals();
                      },
                      onSaveCalories: (value) {
                        setState(() => _goalCalories = value.round());
                        _saveGoals();
                      },
                    )
                  else
                    TrainingRecordsTab(
                      records: _trainingRecords,
                      loading: _trainingRecordsLoading,
                      syncing: _syncingWorkouts,
                      errorMessage: _trainingRecordsError,
                      statusMessage: _trainingRecordsStatus,
                      onRefresh: () => _loadTrainingRecords(),
                      onSync: _syncPlatformWorkouts,
                    ),
                ]),
              ),
            ),
        ],
      ),
    );
  }
}
