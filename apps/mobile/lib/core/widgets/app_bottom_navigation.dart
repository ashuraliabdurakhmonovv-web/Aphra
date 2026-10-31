import 'package:flutter/material.dart';

import '../design_system/app_tokens.dart';

class AppNavigationItem {
  const AppNavigationItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.badgeCount = 0,
  });
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final int badgeCount;
}

class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({
    required this.currentIndex,
    required this.onSelected,
    required this.items,
    super.key,
  });
  final int currentIndex;
  final ValueChanged<int> onSelected;
  final List<AppNavigationItem> items;

  static const _selectedColor = Color(0xFFCC1F8D);

  @override
  Widget build(BuildContext context) => SafeArea(
    minimum: const EdgeInsets.fromLTRB(
      AppSpacing.md,
      0,
      AppSpacing.md,
      AppSpacing.sm,
    ),
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border.all(color: const Color(0xFFF0EEF3)),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        boxShadow: const [
          BoxShadow(
            color: Color(0x142B1430),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: 6,
        ),
        child: Row(
          children: List.generate(items.length, (index) {
            final item = items[index];
            final selected = index == currentIndex;
            return Expanded(
              child: Semantics(
                selected: selected,
                label: item.label,
                button: true,
                child: InkWell(
                  onTap: () => onSelected(index),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    height: 52,
                    // Soft glow around the selected tab.
                    decoration: BoxDecoration(
                      gradient: selected
                          ? const RadialGradient(
                              radius: 0.75,
                              colors: [Color(0xFFFCE3F1), Color(0x00FCE3F1)],
                            )
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          clipBehavior: Clip.none,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: selected
                                    ? _selectedColor
                                    : Colors.transparent,
                              ),
                              child: Icon(
                                selected ? item.selectedIcon : item.icon,
                                size: selected ? 18 : 23,
                                color: selected
                                    ? Colors.white
                                    : AppColors.textPrimary,
                              ),
                            ),
                            if (item.badgeCount > 0)
                              Positioned(
                                right: -6,
                                top: -4,
                                child: Container(
                                  constraints: const BoxConstraints(
                                    minWidth: 16,
                                    minHeight: 16,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  decoration: const BoxDecoration(
                                    color: AppColors.cashback,
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '${item.badgeCount}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: selected
                                ? _selectedColor
                                : const Color(0xFF6E6E78),
                            fontSize: 9.5,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    ),
  );
}
