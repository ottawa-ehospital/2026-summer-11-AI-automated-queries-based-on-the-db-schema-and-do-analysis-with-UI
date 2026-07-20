import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/widgets/widgets.dart';
import '../../../ui/ui.dart';
import '../data/urgent_care_repository.dart';
import '../models/urgent_care_models.dart';

enum _UrgentCareTab { checkIn, status, feedback }

class UrgentCareScreen extends StatefulWidget {
  const UrgentCareScreen({super.key, UrgentCareRepository? repository})
    : _repository = repository;

  final UrgentCareRepository? _repository;

  @override
  State<UrgentCareScreen> createState() => _UrgentCareScreenState();
}

class _UrgentCareScreenState extends State<UrgentCareScreen> {
  static const _visitIdKey = 'urgent_care.active_visit_id';
  static const _lastStatusKey = 'urgent_care.last_status';

  late final UrgentCareRepository _repository =
      widget._repository ?? UrgentCareRepository();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _symptomsController = TextEditingController();
  final _historyController = TextEditingController();
  final _conditionController = TextEditingController();
  final _feedbackController = TextEditingController();

  _UrgentCareTab _tab = _UrgentCareTab.checkIn;
  UrgentCarePatientStatus? _status;
  int? _patientId;
  String _gender = 'Other';
  String _conditionChoice = 'No change';
  bool _loading = true;
  bool _submitting = false;
  bool _refreshing = false;
  bool _sendingFeedback = false;
  String? _message;
  bool _urgentMessage = false;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _nameController.dispose();
    _ageController.dispose();
    _symptomsController.dispose();
    _historyController.dispose();
    _conditionController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final rawId = prefs.get('patient_id');
    final username = prefs.getString('patient_username') ?? '';
    final visitId = prefs.getInt(_visitIdKey);
    final cached = prefs.getString(_lastStatusKey);
    _patientId = int.tryParse(rawId?.toString() ?? '');
    _nameController.text = username;

    if (cached != null) {
      _status = UrgentCarePatientStatus.fromJson(
        Map<String, dynamic>.from(jsonDecode(cached) as Map),
      );
      _tab = _UrgentCareTab.status;
    }
    setState(() => _loading = false);
    if (visitId != null) {
      await _refreshStatus(visitId: visitId, silent: true);
    }
  }

  Future<void> _saveStatus(UrgentCarePatientStatus status) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_visitIdKey, status.localPatientId);
    await prefs.setString(_lastStatusKey, jsonEncode(status.toJson()));
  }

  void _startPolling() {
    _pollTimer?.cancel();
    final status = _status;
    if (status == null || status.isFinished || _tab != _UrgentCareTab.status) {
      return;
    }
    _pollTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _refreshStatus(silent: true),
    );
  }

  Future<void> _submitCheckIn() async {
    if (_submitting || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _submitting = true;
      _message = 'Submitting check-in...';
      _urgentMessage = false;
    });
    try {
      final result = await _repository.checkIn(
        patientId: _patientId,
        name: _nameController.text.trim(),
        age: int.parse(_ageController.text.trim()),
        gender: _gender,
        symptoms: _symptomsController.text.trim(),
        medicalHistory: _historyController.text.trim(),
      );
      await _saveStatus(result.patient);
      setState(() {
        _status = result.patient;
        _tab = _UrgentCareTab.status;
        _message = result.message;
      });
      _startPolling();
    } catch (error) {
      setState(() => _message = 'Check-in failed: $error');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _refreshStatus({int? visitId, bool silent = false}) async {
    final id = visitId ?? _status?.localPatientId;
    if (id == null || _refreshing) return;
    if (!silent) {
      setState(() {
        _refreshing = true;
        _message = 'Refreshing status...';
        _urgentMessage = false;
      });
    }
    try {
      final next = await _repository.status(id);
      await _saveStatus(next);
      setState(() {
        _status = next;
        _urgentMessage = next.isCalled;
        _message = next.isCalled
            ? 'You have been called. Please go to the care desk.'
            : silent
            ? _message
            : 'Status refreshed.';
      });
      if (next.isFinished) {
        _pollTimer?.cancel();
      } else {
        _startPolling();
      }
    } catch (error) {
      setState(
        () => _message = 'Could not refresh. Last status is still shown.',
      );
    } finally {
      if (mounted && !silent) setState(() => _refreshing = false);
    }
  }

  Future<void> _submitFeedback() async {
    final status = _status;
    if (status == null || _sendingFeedback) return;
    setState(() {
      _sendingFeedback = true;
      _message = 'Sending update...';
      _urgentMessage = false;
    });
    try {
      final details = _conditionController.text.trim();
      final condition = details.isEmpty
          ? _conditionChoice
          : '$_conditionChoice. $details';
      final result = await _repository.submitFeedback(
        visitId: status.localPatientId,
        rating: _feedbackController.text.trim().isEmpty
            ? 'Unsure'
            : 'Reasonable',
        message: _feedbackController.text.trim(),
        conditionUpdate: condition,
      );
      _conditionController.clear();
      _feedbackController.clear();
      setState(() {
        _message = result.message;
        _urgentMessage = result.alertRequired;
      });
    } catch (error) {
      setState(() => _message = 'Update failed: $error');
    } finally {
      if (mounted) setState(() => _sendingFeedback = false);
    }
  }

  void _selectTab(_UrgentCareTab tab) {
    setState(() => _tab = tab);
    if (tab == _UrgentCareTab.status) {
      _refreshStatus(silent: true);
      _startPolling();
    } else {
      _pollTimer?.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const AppSliverHeader(
            title: 'Urgent Care',
            icon: Icons.local_hospital_outlined,
            gradient: LinearGradient(
              colors: [Color(0xFF0F766E), Color(0xFF2563EB)],
            ),
            backgroundColor: Color(0xFF0F766E),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: AppSpacing.page,
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_message != null)
                          _MessageBanner(
                            message: _message!,
                            urgent: _urgentMessage,
                          ),
                        const SizedBox(height: AppSpacing.md),
                        SegmentedButton<_UrgentCareTab>(
                          segments: const [
                            ButtonSegment(
                              value: _UrgentCareTab.checkIn,
                              icon: Icon(Icons.edit_note_outlined),
                              label: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'Check-in',
                                  maxLines: 1,
                                  softWrap: false,
                                ),
                              ),
                            ),
                            ButtonSegment(
                              value: _UrgentCareTab.status,
                              icon: Icon(Icons.confirmation_number_outlined),
                              label: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'Status',
                                  maxLines: 1,
                                  softWrap: false,
                                ),
                              ),
                            ),
                            ButtonSegment(
                              value: _UrgentCareTab.feedback,
                              icon: Icon(Icons.rate_review_outlined),
                              label: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'Feedback',
                                  maxLines: 1,
                                  softWrap: false,
                                ),
                              ),
                            ),
                          ],
                          style: const ButtonStyle(
                            padding: WidgetStatePropertyAll(
                              EdgeInsets.symmetric(horizontal: 8),
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                          selected: {_tab},
                          onSelectionChanged: (value) =>
                              _selectTab(value.first),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        switch (_tab) {
                          _UrgentCareTab.checkIn => _buildCheckIn(),
                          _UrgentCareTab.status => _buildStatus(),
                          _UrgentCareTab.feedback => _buildFeedback(),
                        },
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckIn() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader(
            title: 'Patient check-in',
            subtitle: 'Clinical staff review all care decisions.',
          ),
          const SizedBox(height: AppSpacing.md),
          AppCard(
            child: Column(
              children: [
                if (_patientId != null)
                  _InfoRow(label: 'Patient ID', value: _patientId.toString()),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Full name'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter full name.'
                      : null,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _ageController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Age'),
                  validator: (value) {
                    final age = int.tryParse(value?.trim() ?? '');
                    if (age == null || age < 0 || age > 125) {
                      return 'Enter a valid age.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  initialValue: _gender,
                  decoration: const InputDecoration(labelText: 'Gender'),
                  items: const [
                    DropdownMenuItem(value: 'Male', child: Text('Male')),
                    DropdownMenuItem(value: 'Female', child: Text('Female')),
                    DropdownMenuItem(value: 'Other', child: Text('Other')),
                  ],
                  onChanged: (value) =>
                      setState(() => _gender = value ?? 'Other'),
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _symptomsController,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(labelText: 'Main symptoms'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Describe the main symptoms.'
                      : null,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _historyController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Medical history, medications, allergies',
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                ElevatedButton.icon(
                  onPressed: _submitting ? null : _submitCheckIn,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                  ),
                  icon: _submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.fact_check_outlined),
                  label: Text(
                    _submitting ? 'Submitting...' : 'Check in',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatus() {
    final status = _status;
    if (status == null) {
      return const AppCard(child: Text('No active urgent-care visit yet.'));
    }
    final info = status.submittedInformation;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StatusHero(status: status),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            _Metric(
              label: 'Reference',
              value: status.queueNumber?.toString() ?? 'Pending',
            ),
            _Metric(
              label: 'Patients ahead',
              value: status.patientsAhead.toString(),
            ),
            _Metric(label: 'Estimated wait', value: status.estimatedWaitRange),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InfoRow(
                label: 'Queue',
                value: info['queue_name']?.toString() ?? 'Pending',
              ),
              _InfoRow(
                label: 'CTAS',
                value: info['ctas_urgency_level']?.toString() ?? 'Pending',
              ),
              _InfoRow(
                label: 'Risk score',
                value: info['risk_score']?.toString() ?? 'Pending',
              ),
              _InfoRow(
                label: 'Symptoms',
                value: info['symptoms']?.toString() ?? 'Not provided',
              ),
              _InfoRow(
                label: 'Clinical summary',
                value: info['clinical_summary']?.toString() ?? 'Pending review',
              ),
              _InfoRow(
                label: 'Recommended staff action',
                value:
                    info['recommended_action']?.toString() ?? 'Pending review',
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ElevatedButton.icon(
          onPressed: _refreshing ? null : () => _refreshStatus(),
          icon: _refreshing
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh),
          label: Text(_refreshing ? 'Refreshing...' : 'Refresh status'),
        ),
      ],
    );
  }

  Widget _buildFeedback() {
    if (_status == null) {
      return const AppCard(child: Text('Check in before sending updates.'));
    }
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader(
            title: 'Condition update',
            subtitle:
                'Staff review is flagged when your update needs attention.',
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<String>(
            initialValue: _conditionChoice,
            decoration: const InputDecoration(labelText: 'Current condition'),
            items: const [
              DropdownMenuItem(value: 'No change', child: Text('No change')),
              DropdownMenuItem(
                value: 'Feeling better',
                child: Text('Feeling better'),
              ),
              DropdownMenuItem(
                value: 'Getting worse',
                child: Text('Getting worse'),
              ),
              DropdownMenuItem(
                value: 'Need assistance',
                child: Text('Need assistance'),
              ),
            ],
            onChanged: (value) =>
                setState(() => _conditionChoice = value ?? 'No change'),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _conditionController,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Optional condition details',
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _feedbackController,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Optional queue or app feedback',
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton.icon(
            onPressed: _sendingFeedback ? null : _submitFeedback,
            icon: const Icon(Icons.send_outlined),
            label: Text(_sendingFeedback ? 'Sending...' : 'Send update'),
          ),
        ],
      ),
    );
  }
}

class _MessageBanner extends StatelessWidget {
  const _MessageBanner({required this.message, required this.urgent});

  final String message;
  final bool urgent;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Icon(
            urgent ? Icons.priority_high_outlined : Icons.info_outline,
            color: urgent ? Colors.red.shade700 : AppColors.primary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}

class _StatusHero extends StatelessWidget {
  const _StatusHero({required this.status});

  final UrgentCarePatientStatus status;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Icon(
            status.isCalled ? Icons.campaign_outlined : Icons.hourglass_top,
            size: 40,
            color: status.isCalled ? Colors.red.shade700 : AppColors.primary,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status.isCalled ? 'You have been called' : 'Current status',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  status.status,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: AppColors.textMuted)),
            const SizedBox(height: AppSpacing.xs),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textMuted)),
          const SizedBox(height: 3),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
