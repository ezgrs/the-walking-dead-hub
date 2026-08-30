import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:responsive_framework/responsive_framework.dart' as rf;

import '../main.dart';

class HeaderWidget extends StatelessWidget {
  const HeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final bool compact = rf.ResponsiveBreakpoints.of(
      context,
    ).smallerThan(kDeviceDesktop);
    final Widget logoWidget = SvgPicture.network(
      'https://upload.wikimedia.org/wikipedia/commons/e/ef/The_Walking_Dead_2010_logo.svg',
      height: compact ? 54 : 64,
    );
    final Widget homeLink = InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => GoRouter.of(context).go('/'),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: logoWidget,
      ),
    );
    final Widget localizationWidget = Consumer<LocaleController>(
      builder: (context, localeController, _) {
        final Locale locale = LocaleController.resolve(
          localeController.value ?? Localizations.localeOf(context),
        );
        final Locale nextLocale = LocaleController.nextAfter(locale);

        return OutlinedButton.icon(
          onPressed: () => localeController.value = nextLocale,
          icon: const Icon(Icons.language_rounded, size: 18),
          label: Text(nextLocale.languageCode.toUpperCase()),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.ink,
            side: const BorderSide(color: AppColors.border),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: compact ? AppSpacing.md : AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            textStyle: Theme.of(context).textTheme.labelLarge,
          ),
        );
      },
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        compact ? AppSpacing.md : AppSpacing.xl,
        AppSpacing.md,
        compact ? AppSpacing.md : AppSpacing.xl,
        AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Align(alignment: Alignment.centerLeft, child: homeLink),
          ),
          localizationWidget,
        ],
      ),
    );
  }
}
