import 'package:flutter/material.dart';
import '../../../../core/design_system/app_tokens.dart';

class CategoryCard extends StatelessWidget {
  const CategoryCard({
    required this.title,
    required this.backgroundColor,
    required this.onTap,
    this.image,
    this.height = 220,
    super.key,
  });
  final String title;
  final Color backgroundColor;
  final ImageProvider? image;
  final double height;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    child: Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            if (image != null)
              Positioned(
                left: AppSpacing.sm,
                right: AppSpacing.sm,
                bottom: 0,
                height: height * .7,
                child: Image(
                  image: image!,
                  fit: BoxFit.contain,
                  alignment: Alignment.bottomCenter,
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.md,
                0,
              ),
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
