import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/design_system/app_tokens.dart';

class ExploreHeader extends StatelessWidget {
  const ExploreHeader({super.key});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'explore.title'.tr(),
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w700,
          height: 1.15,
          letterSpacing: -0.5,
        ),
      ),
      const SizedBox(height: AppSpacing.xs),
      Text(
        'explore.subtitle'.tr(),
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: AppColors.textSecondary,
          height: 1.4,
        ),
      ),
      const SizedBox(height: AppSpacing.xl),
      const _ExploreSearchField(),
      const SizedBox(height: AppSpacing.lg),
      const _ExploreCategories(),
      const SizedBox(height: AppSpacing.xl),
      Text(
        'explore.popular'.tr(),
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
      ),
    ],
  );
}

class _ExploreSearchField extends StatelessWidget {
  const _ExploreSearchField();

  @override
  Widget build(BuildContext context) => Semantics(
    textField: true,
    label: 'explore.search_hint'.tr(),
    child: TextField(
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'explore.search_hint'.tr(),
        hintStyle: Theme.of(
          context,
        ).textTheme.bodyLarge?.copyWith(color: const Color(0xFF80747A)),
        prefixIcon: const Padding(
          padding: EdgeInsets.only(left: 6, right: 2),
          child: Icon(Icons.search_rounded, size: 26),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 48),
        filled: true,
        fillColor: AppColors.softPink,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: 18,
        ),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFF2DEE8)),
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.pill)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.pill)),
        ),
      ),
    ),
  );
}

class _ExploreCategories extends StatelessWidget {
  const _ExploreCategories();

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 42,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.xs),
      itemBuilder: (context, index) {
        final labels = [
          'categories.nearby',
          'categories.cosmetology',
          'categories.massage',
          'categories.facial',
        ];
        return _CategoryPill(label: labels[index].tr(), selected: index == 0);
      },
    ),
  );
}

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({required this.label, required this.selected});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: selected ? AppColors.primary : AppColors.background,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      border: Border.all(
        color: selected ? AppColors.primary : const Color(0xFFE8D3DD),
      ),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (selected) ...[
          const Icon(Icons.near_me_rounded, size: 16, color: Colors.white),
          const SizedBox(width: 6),
        ],
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: selected ? Colors.white : const Color(0xFF685B62),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}
