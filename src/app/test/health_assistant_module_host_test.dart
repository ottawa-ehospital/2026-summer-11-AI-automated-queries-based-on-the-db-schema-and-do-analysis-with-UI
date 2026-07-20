import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_health_app/features/health_assistant/health_assistant.dart';
import 'package:smart_health_app/l10n/generated/app_localizations.dart';
import 'package:smart_health_app/ui/app_theme.dart';

void main() {
  testWidgets('assistant host opens separate chat and report pages', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: HealthAssistantScreen(
          reportInterpreterBuilder: (_) =>
              const Center(child: Text('Report module body')),
          nutritionMonitorBuilder: (_) =>
              const Center(child: Text('Nutrition module body')),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Chat'), findsOneWidget);
    expect(find.text('Report Analyze'), findsOneWidget);
    expect(find.text('Choose an AI tool'), findsOneWidget);
    expect(find.text('Ask about your wellness data'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('ai-module-health-chat')));
    await tester.pumpAndSettle();
    expect(find.text('Ask about your wellness data'), findsOneWidget);
    expect(
      find.widgetWithText(TextField, 'Ask about your health...'),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Choose an AI tool'), findsOneWidget);

    await tester.tap(find.text('Report Analyze'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('ai-module-report-analyze')));
    await tester.pumpAndSettle();
    expect(find.text('Report module body'), findsOneWidget);
    expect(find.text('Choose an AI tool'), findsNothing);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Choose an AI tool'), findsOneWidget);

    await tester.drag(
      find.byKey(const ValueKey('ai-module-picker-pages')),
      const Offset(0, -260),
    );
    await tester.pumpAndSettle();
    expect(find.text('Nutrition Monitor'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('ai-module-nutrition-monitor')));
    await tester.pumpAndSettle();
    expect(find.text('Nutrition module body'), findsOneWidget);
    expect(find.text('Choose an AI tool'), findsNothing);
  });

  testWidgets('assistant module picker supports more than two modules', (
    tester,
  ) async {
    var selectedIndex = 0;
    String? launchedId;
    final modules = [
      AiAssistantModuleDefinition(
        id: 'chat',
        label: 'Chat',
        description: 'Ask health questions.',
        icon: Icons.chat_bubble_outline,
        builder: (_) => const SizedBox.shrink(),
      ),
      AiAssistantModuleDefinition(
        id: 'report',
        label: 'Report Analyze',
        description: 'Understand reports.',
        icon: Icons.description_outlined,
        builder: (_) => const SizedBox.shrink(),
      ),
      AiAssistantModuleDefinition(
        id: 'planner',
        label: 'Care Planner',
        description: 'Plan follow-up actions.',
        icon: Icons.event_note_outlined,
        builder: (_) => const SizedBox.shrink(),
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: StatefulBuilder(
          builder: (context, setState) {
            return Scaffold(
              body: AiAssistantModulePicker(
                modules: modules,
                selectedIndex: selectedIndex,
                onSelected: (index) {
                  setState(() => selectedIndex = index);
                },
                onLaunch: (module) {
                  launchedId = module.id;
                },
              ),
            );
          },
        ),
      ),
    );

    expect(find.text('Chat'), findsOneWidget);
    expect(find.text('Report Analyze'), findsOneWidget);

    await tester.drag(
      find.byKey(const ValueKey('ai-module-picker-pages')),
      const Offset(0, -260),
    );
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const ValueKey('ai-module-picker-pages')),
      const Offset(0, -260),
    );
    await tester.pumpAndSettle();

    expect(find.text('Care Planner'), findsOneWidget);
    await tester.tap(find.text('Care Planner'));
    await tester.pumpAndSettle();
    expect(launchedId, 'planner');
  });

  testWidgets('chat empty state does not overflow when keyboard is open', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 330);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.view.viewInsets = FakeViewPadding.zero;
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: HealthChatModule()),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Ask about your wellness data'), findsOneWidget);
  });
}
