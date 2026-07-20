import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/health_alert_models.dart';
import 'health_alert_service.dart';

typedef HealthAlertEventProcessor =
    Future<AlertDecisionRecord> Function(HealthAlertEvent event);

class HealthAlertCoordinator extends StatefulWidget {
  final Widget child;
  final HealthAlertBridge? bridge;
  final HealthAlertEventProcessor? processEvent;
  final Duration patientPollInterval;

  const HealthAlertCoordinator({
    super.key,
    required this.child,
    this.bridge,
    this.processEvent,
    this.patientPollInterval = const Duration(seconds: 2),
  });

  @override
  State<HealthAlertCoordinator> createState() => _HealthAlertCoordinatorState();
}

class _HealthAlertCoordinatorState extends State<HealthAlertCoordinator>
    with WidgetsBindingObserver {
  late final HealthAlertBridge _bridge;
  late final HealthAlertEventProcessor _processEvent;
  Timer? _patientPoller;
  String? _activePatientId;
  bool _starting = false;
  bool _bridgeStarted = false;
  final Set<String> _processingEventIds = <String>{};

  @override
  void initState() {
    super.initState();
    _bridge = widget.bridge ?? HealthKitAlertBridge();
    _processEvent = widget.processEvent ?? HealthAlertService().processEvent;
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshPatient());
    _patientPoller = Timer.periodic(
      widget.patientPollInterval,
      (_) => _refreshPatient(),
    );
  }

  @override
  void dispose() {
    _patientPoller?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        _activePatientId != null &&
        _bridgeStarted) {
      _reconcile();
    }
  }

  Future<void> _refreshPatient() async {
    final prefs = await SharedPreferences.getInstance();
    final rawPatientId = prefs.get('patient_id')?.toString();
    final patientId = rawPatientId == null || rawPatientId.trim().isEmpty
        ? null
        : rawPatientId.trim();
    if (!mounted || patientId == _activePatientId) return;
    _activePatientId = patientId;
    if (patientId == null) return;
    _startForPatient(patientId);
  }

  Future<void> _startForPatient(String patientId) async {
    if (_starting) return;
    _starting = true;
    _showDebugBubble('Syncing Apple Health alerts for patient $patientId...');
    _bridge.listen(patientId: patientId, onEvent: _handleEvent);
    try {
      await _bridge.start();
      _bridgeStarted = true;
      _showDebugBubble('Apple Health alert sync is listening.');
    } catch (error) {
      _bridgeStarted = false;
      _showDebugBubble('Apple Health alert sync could not start: $error');
    } finally {
      _starting = false;
    }
  }

  Future<void> _reconcile() async {
    if (!_bridgeStarted) return;
    _showDebugBubble('Syncing Apple Health updates...');
    try {
      await _bridge.reconcile();
    } catch (error) {
      _showDebugBubble('Apple Health reconcile failed: $error');
    }
  }

  Future<void> _handleEvent(HealthAlertEvent event) async {
    if (_activePatientId == null || event.patientId != _activePatientId) return;
    final eventKey = '${event.eventType}:${event.eventSourceId}';
    if (!_processingEventIds.add(eventKey)) return;
    _showDebugBubble('Apple Health ${event.eventType} update received.');
    try {
      final record = await _processEvent(event);
      final decision = record.decision;
      if (decision.notify) {
        _showDebugBubble(
          'Health alert notification sent: ${decision.title ?? decision.reason}',
        );
      } else {
        _showDebugBubble('Health alert analyzed: ${decision.reason}');
      }
    } catch (error) {
      _showDebugBubble('Health alert analysis failed: $error');
    } finally {
      _processingEventIds.remove(eventKey);
    }
  }

  void _showDebugBubble(String message) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
