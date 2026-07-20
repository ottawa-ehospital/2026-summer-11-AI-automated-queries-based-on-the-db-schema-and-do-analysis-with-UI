import 'package:flutter/material.dart';

import '../../ui/ui.dart';

class LoadingStateView extends StatelessWidget {
  final String? label;

  const LoadingStateView({super.key, this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          if (label != null) ...[const SizedBox(height: 12), Text(label!)],
        ],
      ),
    );
  }
}

class EmptyStateView extends StatelessWidget {
  final String? message;
  final IconData? icon;
  final String? title;
  final String? subtitle;

  const EmptyStateView({
    super.key,
    this.message,
    this.icon,
    this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    if (icon == null && title == null && subtitle == null) {
      return Center(child: Text(message ?? ""));
    }
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) Icon(icon, size: 64, color: Colors.grey),
          if (title != null) ...[
            const SizedBox(height: 12),
            Text(
              title!,
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }
}

class ErrorStateView extends StatelessWidget {
  final String message;

  const ErrorStateView({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        style: const TextStyle(color: AppColors.danger),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class SliverStateView extends StatelessWidget {
  final Widget child;
  final bool hasScrollBody;

  const SliverStateView({
    super.key,
    required this.child,
    this.hasScrollBody = false,
  });

  SliverStateView.loading({super.key, String? label})
    : child = LoadingStateView(label: label),
      hasScrollBody = false;

  SliverStateView.error({super.key, required String message})
    : child = ErrorStateView(message: message),
      hasScrollBody = false;

  SliverStateView.empty({
    super.key,
    IconData? icon,
    String? title,
    String? subtitle,
    String? message,
  }) : child = EmptyStateView(
         icon: icon,
         title: title,
         subtitle: subtitle,
         message: message,
       ),
       hasScrollBody = false;

  @override
  Widget build(BuildContext context) {
    return SliverFillRemaining(hasScrollBody: hasScrollBody, child: child);
  }
}
