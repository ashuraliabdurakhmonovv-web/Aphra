import 'package:flutter/material.dart';

import '../design_system/app_tokens.dart';

class AppErrorState extends StatelessWidget {
  const AppErrorState({
    required this.title,
    required this.retryLabel,
    required this.onRetry,
    super.key,
  });
  final String title;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 40),
          const SizedBox(height: AppSpacing.md),
          Text(title, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.md),
          FilledButton(onPressed: onRetry, child: Text(retryLabel)),
        ],
      ),
    ),
  );
}
