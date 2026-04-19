import 'package:flutter/widgets.dart';

class MaybeWidget extends StatelessWidget {
  final Widget child;
  final bool enabled;
  final Widget Function(Widget child) builder;

  const MaybeWidget({
    super.key,
    required this.enabled,
    required this.builder,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => enabled ? builder(child) : child;
}
