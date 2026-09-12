import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';

class AppSectionCard extends StatelessWidget {
  const AppSectionCard({
    required this.child,
    this.title,
    this.trailing,
    super.key,
  });

  final Widget child;
  final String? title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final hasBoundedHeight = constraints.maxHeight.isFinite;
            final content = hasBoundedHeight
                ? Expanded(
                    child: SingleChildScrollView(
                      child: child,
                    ),
                  )
                : child;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: hasBoundedHeight ? MainAxisSize.max : MainAxisSize.min,
              children: [
                if (title != null) ...[
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title!,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                      if (trailing != null) trailing!,
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                content,
              ],
            );
          },
        ),
      ),
    );
  }
}
