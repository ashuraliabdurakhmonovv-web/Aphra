import 'package:flutter/material.dart';

import '../../../../core/design_system/app_tokens.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({
    required this.title,
    required this.currentPrice,
    required this.isFavorite,
    required this.quantity,
    required this.onFavorite,
    required this.onAdd,
    required this.onIncrement,
    required this.onDecrement,
    this.image,
    this.originalPrice,
    this.discountLabel,
    this.cashbackLabel,
    super.key,
  });

  final String title;
  final String currentPrice;
  final String? originalPrice;
  final String? discountLabel;
  final String? cashbackLabel;
  final ImageProvider? image;
  final bool isFavorite;
  final int quantity;
  final VoidCallback onFavorite;
  final VoidCallback onAdd;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: AppColors.background,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(AppRadius.lg),
    ),
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: .92,
            child: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: image == null
                        ? const Icon(
                            Icons.image_outlined,
                            color: AppColors.textSecondary,
                          )
                        : Padding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Image(image: image!, fit: BoxFit.contain),
                          ),
                  ),
                ),
                Positioned(
                  right: AppSpacing.xs,
                  top: AppSpacing.xs,
                  child: IconButton.filledTonal(
                    onPressed: onFavorite,
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
                Positioned(
                  left: AppSpacing.xs,
                  bottom: AppSpacing.xs,
                  child: Wrap(
                    spacing: AppSpacing.xxs,
                    children: [
                      if (cashbackLabel != null)
                        _Label(text: cashbackLabel!, filled: true),
                      if (discountLabel != null)
                        _Label(text: discountLabel!, filled: false),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const Spacer(),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentPrice,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (originalPrice != null)
                      Text(
                        originalPrice!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                  ],
                ),
              ),
              quantity == 0
                  ? IconButton.filled(
                      onPressed: onAdd,
                      icon: const Icon(Icons.add),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        color: AppColors.softPink,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: onDecrement,
                            icon: const Icon(Icons.remove),
                            visualDensity: VisualDensity.compact,
                          ),
                          Text(
                            '$quantity',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          IconButton(
                            onPressed: onIncrement,
                            icon: const Icon(Icons.add),
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                    ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _Label extends StatelessWidget {
  const _Label({required this.text, required this.filled});
  final String text;
  final bool filled;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
    decoration: BoxDecoration(
      color: filled ? AppColors.cashback : AppColors.background,
      border: Border.all(color: AppColors.cashback),
      borderRadius: BorderRadius.circular(AppRadius.pill),
    ),
    child: Text(
      text,
      style: TextStyle(
        color: filled ? Colors.white : AppColors.cashback,
        fontSize: 10,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}
