import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/repositories/sleep_repository.dart';
import '../models/night_sleep.dart';
import '../presentation/sleep_styles.dart';
import '../services/health_sleep_service.dart';
import 'sleep_stage_bar_chart.dart';
import 'sleep_stage_legend.dart';

class _ChatMsg {
  final String role; // 'user' | 'assistant'
  final String content;
  const _ChatMsg(this.role, this.content);
}

/// Embeddable sleep analysis panel (no Scaffold), shown inside the
/// Wearable Vitals screen's Sleep tab. Reads real Apple Watch sleep data
/// from HealthKit, auto-syncs to eHospital once daily, generates AI feedback
/// on the real values, and lets the patient chat with the assistant about it.
class SleepAnalysisView extends StatefulWidget {
  const SleepAnalysisView({super.key});

  @override
  State<SleepAnalysisView> createState() => _SleepAnalysisViewState();
}

class _SleepAnalysisViewState extends State<SleepAnalysisView>
    with AutomaticKeepAliveClientMixin {
  final SleepRepository _repository = SleepRepository();
  final HealthSleepService _health = HealthSleepService();
  final TextEditingController _chatController = TextEditingController();

  String? _patientId;
  List<NightSleep> _nights = [];
  bool _loading = true;
  String? _error;

  bool _feedbackLoading = false;
  bool _feedbackStarted = false;
  bool _chatSending = false;
  final List<_ChatMsg> _messages = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      _patientId = prefs.get('patient_id')?.toString();

      // HealthKit is iOS-only. On web (UI preview) load demo data instead so
      // the chart, summary, and assistant are all viewable.
      if (kIsWeb) {
        setState(() {
          _nights = _demoNights();
          _loading = false;
        });
        return;
      }

      final granted = await _health.requestPermissions();
      if (!granted) {
        setState(() {
          _loading = false;
          _error =
              'Apple Health access was not granted. Enable Sleep, Blood Oxygen, '
              'and Heart Rate for this app in the Health app under '
              'Sharing \u203a Apps.';
        });
        return;
      }

      final nights = await _health.fetchNightlySleep(nights: 7);
      if (!mounted) return;
      setState(() {
        _nights = nights;
        _loading = false;
      });
      _autoSync();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not read Apple Health data: $e';
      });
    }
  }

  List<NightSleep> _demoNights() {
    final now = DateTime.now();
    return List.generate(7, (i) {
      final date = now.subtract(Duration(days: 6 - i));
      final deep = 55.0 + (i % 4) * 6;
      final rem = 80.0 + (i % 4) * 8;
      final core = 190.0 + (i % 3) * 10;
      final awake = 15.0 + (i % 3) * 5;
      return NightSleep(
        night:
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
        deepMinutes: deep,
        remMinutes: rem,
        coreMinutes: core,
        lightMinutes: 0,
        awakeMinutes: awake,
        asleepMinutes: deep + rem + core,
        inBedMinutes: deep + rem + core + awake,
        spo2Avg: 96.0 + (i % 3) * 0.5,
        spo2Min: 91.0 + (i % 3),
        hrAvg: 55.0 + (i % 4),
        hrMin: 48.0 + (i % 3),
        source: 'sample_data',
      );
    });
  }

  Future<void> _autoSync() async {
    if (_nights.isEmpty) return;
    try {
      final saved = await _repository.autoSyncOncePerDay(
        patientId: _patientId ?? '20',
        nights: _nights,
      );
      if (saved != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Synced $saved night(s) to eHospital')),
        );
      }
    } catch (_) {}
  }

  Future<void> _getFeedback() async {
    if (_feedbackLoading) return;
    setState(() {
      _feedbackLoading = true;
      _feedbackStarted = true;
      _messages.clear();
    });
    try {
      final text = await _repository.requestFeedback(
        patientId: _patientId ?? '20',
      );
      if (!mounted) return;
      setState(() => _messages.add(_ChatMsg('assistant', text)));
    } catch (e) {
      if (!mounted) return;
      setState(
        () => _messages.add(
          _ChatMsg('assistant', 'Could not generate feedback: $e'),
        ),
      );
    } finally {
      if (mounted) setState(() => _feedbackLoading = false);
    }
  }

  Future<void> _sendChat() async {
    final text = _chatController.text.trim();
    if (text.isEmpty || _chatSending) return;
    _chatController.clear();
    setState(() {
      _messages.add(_ChatMsg('user', text));
      _chatSending = true;
    });
    try {
      // Send prior turns (excluding the one we just added) as history.
      final history = _messages
          .sublist(0, _messages.length - 1)
          .map((m) => {'role': m.role, 'content': m.content})
          .toList();
      final reply = await _repository.chatAboutSleep(
        patientId: _patientId ?? '20',
        message: text,
        history: history,
      );
      if (!mounted) return;
      setState(() => _messages.add(_ChatMsg('assistant', reply)));
    } catch (e) {
      if (!mounted) return;
      setState(
        () => _messages.add(
          _ChatMsg('assistant', 'Sorry, I could not reply: $e'),
        ),
      );
    } finally {
      if (mounted) setState(() => _chatSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) return _errorState();
    if (_nights.isEmpty) return _emptyState();
    return _content();
  }

  Widget _errorState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 8),
      child: Column(
        children: [
          const Icon(
            Icons.health_and_safety_outlined,
            size: 48,
            color: Colors.grey,
          ),
          const SizedBox(height: 12),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _init,
            icon: const Icon(Icons.refresh),
            label: const Text('Try again'),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: Column(
        children: [
          const Icon(Icons.bedtime_outlined, size: 56, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'No sleep data found',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            'Wear your Apple Watch to bed and your nightly sleep stages will '
            'appear here automatically from Apple Health.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: _init,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _content() {
    final latest = _nights.last;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: SleepStyles.cardDecoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Time in each stage per night',
                    style: SleepStyles.cardTitle,
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.watch_outlined,
                    size: 15,
                    color: Color(0xFF6A1B9A),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Apple Health',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF6A1B9A),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SleepStageBarChart(nights: _nights),
              const SizedBox(height: 14),
              const SleepStageLegend(),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _summaryCard(latest),
        const SizedBox(height: 16),
        _assistantCard(),
        const SizedBox(height: 8),
        const Center(
          child: Text(
            'Synced to eHospital automatically once daily',
            style: TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ),
      ],
    );
  }

  Widget _summaryCard(NightSleep night) {
    String hrs(double minutes) => '${(minutes / 60).toStringAsFixed(1)}h';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: SleepStyles.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Last night (${night.nightIso})', style: SleepStyles.cardTitle),
          const SizedBox(height: 16),
          Wrap(
            spacing: 24,
            runSpacing: 16,
            children: [
              _metric('Asleep', hrs(night.asleepMinutes)),
              _metric('Deep', hrs(night.deepMinutes)),
              _metric('REM', hrs(night.remMinutes)),
              _metric('Core', hrs(night.coreMinutes)),
              if (night.spo2Avg != null)
                _metric('SpO2 avg', '${night.spo2Avg!.toStringAsFixed(1)}%'),
              if (night.spo2Min != null)
                _metric('SpO2 low', '${night.spo2Min!.toStringAsFixed(0)}%'),
              if (night.hrAvg != null)
                _metric('HR avg', '${night.hrAvg!.toStringAsFixed(0)} bpm'),
              if (night.hrMin != null)
                _metric('HR low', '${night.hrMin!.toStringAsFixed(0)} bpm'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metric(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: SleepStyles.metric),
        Text(label, style: SleepStyles.metricLabel),
      ],
    );
  }

  // AI feedback + follow-up chat
  Widget _assistantCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: SleepStyles.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(
                Icons.smart_toy_outlined,
                size: 18,
                color: Color(0xFF6A1B9A),
              ),
              SizedBox(width: 6),
              Text('Sleep Assistant', style: SleepStyles.cardTitle),
            ],
          ),
          const SizedBox(height: 12),
          if (!_feedbackStarted)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _feedbackLoading ? null : _getFeedback,
                icon: const Icon(Icons.auto_awesome_outlined),
                label: const Text('Get AI Feedback'),
              ),
            )
          else ...[
            ..._messages.map(_bubble),
            if (_feedbackLoading || _chatSending)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Thinking...',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            _chatInput(),
          ],
        ],
      ),
    );
  }

  Widget _bubble(_ChatMsg m) {
    final isUser = m.role == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF6A1B9A) : const Color(0xFFEDE7F6),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(isUser ? 14 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 14),
          ),
        ),
        child: Text(
          m.content,
          style: TextStyle(
            color: isUser ? Colors.white : const Color(0xFF2A2A3C),
            height: 1.35,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _chatInput() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _chatController,
            minLines: 1,
            maxLines: 4,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _sendChat(),
            decoration: InputDecoration(
              hintText: 'Ask about your sleep...',
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Material(
          color: const Color(0xFF6A1B9A),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: _chatSending ? null : _sendChat,
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ),
        ),
      ],
    );
  }
}
