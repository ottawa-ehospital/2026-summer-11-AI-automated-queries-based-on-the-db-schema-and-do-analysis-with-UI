import 'package:flutter/material.dart';
import '../../../l10n/l10n.dart';
import '../../../ui/ui.dart';
import '../presentation/login_styles.dart';

class LoginForm extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final String selectedIdentity;
  final ValueChanged<String> onIdentityChanged;
  final List<String> identityOptions;
  final String? error;
  final bool loading;
  final VoidCallback onSubmit;

  const LoginForm({
    super.key,
    required this.emailController,
    required this.passwordController,
    required this.selectedIdentity,
    required this.onIdentityChanged,
    required this.identityOptions,
    required this.error,
    required this.loading,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Expanded(
      child: SingleChildScrollView(
        padding: LoginStyles.formPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.signInTitle, style: AppTypography.screenTitle),
            const SizedBox(height: 6),
            Text(l10n.signInSubtitle, style: AppTypography.bodyMuted),
            const SizedBox(height: 28),
            Container(
              decoration: LoginStyles.emailFieldDecoration,
              child: TextField(
                key: const Key('login_email_field'),
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  hintText: l10n.emailAddressHint,
                  prefixIcon: const Icon(
                    Icons.email_outlined,
                    color: AppColors.primary,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: AppRadii.radius(AppRadii.lg),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: AppColors.card,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              decoration: LoginStyles.emailFieldDecoration,
              child: TextField(
                key: const Key('login_password_field'),
                controller: passwordController,
                obscureText: true,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => onSubmit(),
                decoration: InputDecoration(
                  hintText: l10n.passwordHint,
                  prefixIcon: const Icon(
                    Icons.lock_outline,
                    color: AppColors.primary,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: AppRadii.radius(AppRadii.lg),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: AppColors.card,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              decoration: LoginStyles.emailFieldDecoration,
              child: DropdownButtonFormField<String>(
                key: const Key('login_identity_dropdown'),
                initialValue: selectedIdentity,
                items: [
                  for (final identity in identityOptions)
                    DropdownMenuItem(value: identity, child: Text(identity)),
                ],
                onChanged: loading
                    ? null
                    : (value) {
                        if (value != null) onIdentityChanged(value);
                      },
                decoration: InputDecoration(
                  hintText: l10n.roleLabel,
                  prefixIcon: const Icon(
                    Icons.badge_outlined,
                    color: AppColors.primary,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: AppRadii.radius(AppRadii.lg),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: AppColors.card,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
            ),
            if (error != null) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: LoginStyles.errorDecoration,
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppColors.danger,
                      size: 16,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        error!,
                        style: const TextStyle(
                          color: AppColors.danger,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: loading ? null : onSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadii.radius(AppRadii.lg),
                  ),
                  elevation: 0,
                ),
                child: loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(l10n.signInButton, style: AppTypography.button),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
