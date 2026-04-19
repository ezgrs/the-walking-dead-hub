import 'package:flutter/material.dart';

class AppButton extends StatelessWidget {
  final String label;
  final void Function()? onTap;
  final EdgeInsets padding;
  final Alignment? alignment;

  const AppButton({
    super.key,
    required this.label,
    required this.onTap,
    this.padding = const EdgeInsets.all(20),
    this.alignment = Alignment.center,
  });

  @override
  Widget build(BuildContext context) {
    Widget child = Text(
      label,
      style: Theme.of(context).textTheme.displaySmall?.copyWith(
        color: onTap == null ? Colors.grey : Colors.white,
      ),
    );
    final Alignment? alignment = this.alignment;
    if (alignment != null) {
      child = Align(alignment: alignment, child: child);
    }
    return Ink(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
