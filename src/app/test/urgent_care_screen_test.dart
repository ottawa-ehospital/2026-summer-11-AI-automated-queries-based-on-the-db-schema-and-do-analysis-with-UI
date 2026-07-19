import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_health_app/core/network/api_client.dart';
import 'package:smart_health_app/features/urgent_care/urgent_care.dart';

void main() {
  testWidgets('check-in validation prevents empty symptom submit', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'patient_id': 42});
    final repository = FakeUrgentCareRepository();

    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(1), '40');
    await tester.ensureVisible(find.text('Check in'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Check in'));
    await tester.pumpAndSettle();

    expect(repository.checkInCalls, 0);
    expect(find.text('Enter full name.'), findsOneWidget);
    expect(find.text('Describe the main symptoms.'), findsOneWidget);
  });

  testWidgets('patient can check in, view status, and send feedback', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'patient_id': 42,
      'patient_username': 'Jane Doe',
    });
    final repository = FakeUrgentCareRepository();

    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(1), '40');
    await tester.enterText(find.byType(TextFormField).at(2), 'Mild cough');
    await tester.ensureVisible(find.text('Check in'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Check in'));
    await tester.pumpAndSettle();

    expect(repository.checkInCalls, 1);
    expect(find.text('Current status'), findsOneWidget);
    expect(find.text('10-25 minutes'), findsOneWidget);

    await tester.ensureVisible(find.text('Feedback'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Feedback'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Optional condition details'),
      'Symptoms are getting worse',
    );
    await tester.tap(find.text('Send update'));
    await tester.pumpAndSettle();

    expect(repository.feedbackCalls, 1);
    expect(find.text('Staff review has been flagged.'), findsOneWidget);
  });
}

Widget _app(FakeUrgentCareRepository repository) {
  return MaterialApp(home: UrgentCareScreen(repository: repository));
}

class FakeUrgentCareRepository extends UrgentCareRepository {
  FakeUrgentCareRepository()
    : super(
        client: ApiClient(
          baseUrl: 'https://example.test',
          client: MockClient((_) async => throw UnimplementedError()),
        ),
      );

  int checkInCalls = 0;
  int feedbackCalls = 0;

  @override
  Future<UrgentCareCheckInResult> checkIn({
    required int? patientId,
    required String name,
    required int age,
    required String gender,
    required String symptoms,
    required String medicalHistory,
  }) async {
    checkInCalls += 1;
    return UrgentCareCheckInResult(
      message: 'Check-in complete.',
      patient: _status(),
      analysis: const {'ctas_level': 4},
    );
  }

  @override
  Future<UrgentCarePatientStatus> status(int visitId) async => _status();

  @override
  Future<UrgentCareFeedbackResult> submitFeedback({
    required int visitId,
    required String rating,
    required String message,
    required String conditionUpdate,
  }) async {
    feedbackCalls += 1;
    return const UrgentCareFeedbackResult(
      message: 'Staff review has been flagged.',
      alertRequired: true,
    );
  }
}

UrgentCarePatientStatus _status() {
  return const UrgentCarePatientStatus(
    localPatientId: 1001,
    patientId: 42,
    queueNumber: 2,
    status: 'Waiting',
    patientsAhead: 1,
    estimatedWaitRange: '10-25 minutes',
    checkedInAt: '2026-07-17T10:00:00',
    serverTime: '2026-07-17T10:01:00',
    submittedInformation: {
      'symptoms': 'Mild cough',
      'ctas_urgency_level': 4,
      'risk_score': 3,
      'queue_name': 'Non-Urgent Queue',
      'clinical_summary': 'Decision support only.',
      'recommended_action': 'Staff review.',
    },
  );
}
