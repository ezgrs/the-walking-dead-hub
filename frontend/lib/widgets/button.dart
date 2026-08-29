import 'package:flutter/material.dart';

import '../main.dart';

class AppButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final void Function()? onTap;
  final EdgeInsets padding;
  final Alignment? alignment;
  final bool selected;
  final bool expanded;

  const AppButton({
    super.key,
    required this.label,
    this.icon,
    required this.onTap,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: AppSpacing.sm,
    ),
    this.alignment = Alignment.center,
    this.selected = false,
    this.expanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color background = selected ? AppColors.ink : AppColors.surface;
    final Color foreground = selected
        ? AppColors.surface
        : onTap == null
        ? AppColors.muted
        : AppColors.ink;
    final BorderSide border = selected
        ? BorderSide.none
        : const BorderSide(color: AppColors.border);

    Widget child = Row(
      mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: foreground),
          const SizedBox(width: AppSpacing.sm),
        ],
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: foreground,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
            ),
          ),
        ),
      ],
    );
    child = Padding(padding: padding, child: child);

    final Alignment? alignment = this.alignment;
    if (alignment != null) {
      child = Align(
        alignment: alignment,
        widthFactor: expanded ? null : 1,
        heightFactor: 1,
        child: child,
      );
    }

    return Material(
      color: background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: border,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: child,
      ),
    );
  }
}
