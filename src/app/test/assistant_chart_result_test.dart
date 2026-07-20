import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_health_app/data/models/assistant_models.dart';
import 'package:smart_health_app/features/health_assistant/models/chat_message.dart';
import 'package:smart_health_app/features/health_assistant/widgets/assistant_result_view.dart';

void main() {
  test('assistant chat reply parses chart results', () {
    final reply = AssistantChatReply.fromJson({
      'reply': 'Here is your recent heart rate trend.',
      'results': [
        {'type': 'text', 'content': 'Here is your recent heart rate trend.'},
        {
          'type': 'chart',
          'displayType': 'line',
          'title': 'Recent heart rate',
          'xAxis': {'label': 'Time', 'type': 'time'},
          'yAxis': {'label': 'Heart rate', 'unit': 'bpm'},
          'series': [
            {
              'name': 'Heart rate',
              'points': [
                {'x': '2026-06-01T09:00:00Z', 'y': 72},
              ],
            },
          ],
        },
      ],
    });

    expect(reply.results.length, 2);
    expect(reply.results.last, isA<AssistantChartResult>());
    expect((reply.results.last as AssistantChartResult).displayType, 'line');
  });

  test('assistant chat reply parses report results', () {
    final reply = AssistantChatReply.fromJson({
      'reply': 'I generated a report.',
      'results': [
        {'type': 'text', 'content': 'I generated a report.'},
        {
          'type': 'report',
          'format': 'markdown',
          'title': 'Sleep report',
          'content': '## Summary\n- Sleep was short.',
          'generatedAt': '2026-06-20T12:00:00Z',
          'expiresAt': '2026-06-21T12:00:00Z',
          'freshnessReason': 'Sleep can change after the next sleep cycle.',
        },
      ],
    });

    expect(reply.results.length, 2);
    expect(reply.results.last, isA<AssistantReportResult>());
    expect((reply.results.last as AssistantReportResult).format, 'markdown');
  });

  test('chat message serializes assistant result items', () {
    final message = ChatMessage(
      role: 'assistant',
      content: 'Here is your chart.',
      results: [
        const AssistantTextResult(content: 'Here is your chart.'),
        AssistantChartResult.fromJson({
          'type': 'chart',
          'displayType': 'bar',
          'title': 'Sleep',
          'xAxis': {'label': 'Time'},
          'yAxis': {'label': 'Sleep', 'unit': 'hours'},
          'series': [
            {
              'name': 'Sleep',
              'points': [
                {'x': 'Mon', 'y': 7},
              ],
            },
          ],
        }),
      ],
    );

    final decoded = ChatMessage.fromJson(message.toJson());

    expect(decoded.results.length, 2);
    expect(decoded.results.last, isA<AssistantChartResult>());
  });

  testWidgets('assistant line chart result renders title', (tester) async {
    final result = AssistantChartResult.fromJson({
      'type': 'chart',
      'displayType': 'line',
      'title': 'Recent heart rate',
      'xAxis': {'label': 'Time'},
      'yAxis': {'label': 'Heart rate', 'unit': 'bpm'},
      'series': [
        {
          'name': 'Heart rate',
          'points': [
            {'x': '2026-06-01T09:00:00Z', 'y': 72},
            {'x': '2026-06-02T09:00:00Z', 'y': 78},
          ],
        },
      ],
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: AssistantResultView(result: result)),
      ),
    );

    expect(find.text('Recent heart rate'), findsOneWidget);
  });

  testWidgets('unsupported chart result warns without rendering', (
    tester,
  ) async {
    final result = AssistantResult.fromJson({
      'type': 'chart',
      'displayType': 'pie',
      'title': 'Unsupported chart',
      'xAxis': {'label': 'Time'},
      'yAxis': {'label': 'Value'},
      'series': [
        {
          'name': 'Value',
          'points': [
            {'x': 'A', 'y': 1},
          ],
        },
      ],
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: AssistantResultView(result: result)),
      ),
    );

    expect(find.text('Unsupported chart'), findsNothing);
  });

  testWidgets('assistant markdown report renders content', (tester) async {
    final result = AssistantReportResult.fromJson({
      'type': 'report',
      'format': 'markdown',
      'title': 'Sleep report',
      'content': '## Summary\n- **Sleep** was short.',
      'generatedAt': '2026-06-20T12:00:00Z',
      'expiresAt': '2999-06-21T12:00:00Z',
      'freshnessReason': 'Sleep can change after the next sleep cycle.',
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: AssistantResultView(result: result)),
      ),
    );

    expect(find.text('Sleep report'), findsOneWidget);
    expect(find.text('Summary'), findsOneWidget);
    expect(find.text('Sleep was short.'), findsOneWidget);
    expect(find.textContaining('stale'), findsNothing);
  });

  testWidgets('expired assistant report displays stale notice', (tester) async {
    final result = AssistantReportResult.fromJson({
      'type': 'report',
      'format': 'markdown',
      'title': 'Old report',
      'content': '## Summary\nThis report is old.',
      'generatedAt': '2020-06-20T12:00:00Z',
      'expiresAt': '2020-06-21T12:00:00Z',
      'freshnessReason': 'Short-term signals can change.',
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: AssistantResultView(result: result)),
      ),
    );

    expect(find.text('Old report'), findsOneWidget);
    expect(find.textContaining('stale'), findsOneWidget);
    expect(find.text('This report is old.'), findsOneWidget);
  });
}
