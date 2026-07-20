import 'package:flutter/material.dart';
import '../widgets/sleep_analysis_view.dart';

/// Standalone wrapper kept for the /sleep route. The sleep feature now
/// lives inside the Wearable Vitals screen's Sleep tab via SleepAnalysisView.
class SleepScreen extends StatelessWidget {
  const SleepScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sleep Analysis')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: SleepAnalysisView(),
      ),
    );
  }
}
