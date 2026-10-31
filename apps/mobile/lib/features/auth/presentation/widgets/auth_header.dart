import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../core/design_system/app_tokens.dart';

class AuthHeader extends StatelessWidget {
  const AuthHeader({
    required this.step,
    required this.onBack,
    required this.onSkip,
    super.key,
  });
  final int step;
  final VoidCallback onBack;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Row(
        children: [
          DecoratedBox(
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Color(0x10000000), blurRadius: 14)],
            ),
            child: IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.chevron_left, size: 30),
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: onSkip,
            child: Text(
              'auth.skip'.tr(),
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 18),
      SizedBox(
        width: 154,
        child: Row(
          children: List.generate(7, (index) {
            if (index.isOdd) {
              final active = index ~/ 2 < step;
              return Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  height: 3,
                  color: active ? AppColors.primary : const Color(0xFFF0E8ED),
                ),
              );
            }
            final dotIndex = index ~/ 2;
            final active = dotIndex <= step;
            final current = dotIndex == step;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: current ? 16 : 10,
              height: current ? 16 : 10,
              decoration: BoxDecoration(
                color: active ? AppColors.primary : const Color(0xFFF0E8ED),
                shape: BoxShape.circle,
              ),
            );
          }),
        ),
      ),
    ],
  );
}
