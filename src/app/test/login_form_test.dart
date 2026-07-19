import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_health_app/features/auth/widgets/login_form.dart';
import 'package:smart_health_app/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('login form shows password field and eHospital identities', (
    tester,
  ) async {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    var selectedIdentity = 'Patient';

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: StatefulBuilder(
          builder: (context, setState) {
            return Scaffold(
              body: Column(
                children: [
                  LoginForm(
                    emailController: emailController,
                    passwordController: passwordController,
                    selectedIdentity: selectedIdentity,
                    identityOptions: const [
                      'Admin',
                      'Patient',
                      'Doctor',
                      'Clinic',
                      'PharmaAdmin',
                      'Pharma',
                      'ClinicalReasoning',
                    ],
                    onIdentityChanged: (value) =>
                        setState(() => selectedIdentity = value),
                    error: null,
                    loading: false,
                    onSubmit: () {},
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );

    expect(find.byKey(const Key('login_email_field')), findsOneWidget);
    expect(find.byKey(const Key('login_password_field')), findsOneWidget);
    expect(find.text('Patient'), findsOneWidget);

    await tester.tap(find.byKey(const Key('login_identity_dropdown')));
    await tester.pumpAndSettle();

    for (final identity in const [
      'Admin',
      'Patient',
      'Doctor',
      'Clinic',
      'PharmaAdmin',
      'Pharma',
      'ClinicalReasoning',
    ]) {
      expect(find.text(identity), findsWidgets);
    }

    await tester.tap(find.text('Doctor').last);
    await tester.pumpAndSettle();

    expect(selectedIdentity, 'Doctor');
  });
}
