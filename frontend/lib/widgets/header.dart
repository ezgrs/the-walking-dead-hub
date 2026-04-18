import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:responsive_framework/responsive_framework.dart' as rf;

import '../l10n/app_localizations.dart';
import '../main.dart';

class HeaderWidget extends StatelessWidget {
  const HeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final Widget logoWidget = SvgPicture.network(
      "https://upload.wikimedia.org/wikipedia/commons/e/ef/The_Walking_Dead_2010_logo.svg",
      height: 100,
    );
    final Widget localizationWidget = ValueListenableBuilder(
      valueListenable: localeController.locale,
      builder: (context, locale, _) {
        final int index = AppLocalizations.supportedLocales.indexOf(locale);
        final Locale nextLocale =
            AppLocalizations.supportedLocales[(index + 1) %
                AppLocalizations.supportedLocales.length];
        final String emojiText = switch (nextLocale.languageCode) {
          "en" => "🇺🇸",
          "pt" => "🇧🇷",
          _ => "",
        };
        return TextButton.icon(
          onPressed: () => localeController.setLocale(nextLocale),
          label: Text("$emojiText  ${nextLocale.languageCode.toUpperCase()}"),
          style: TextButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            textStyle: Theme.of(context).textTheme.displaySmall,
          ),
        );
      },
    );
    final Widget child;
    if (rf.ResponsiveBreakpoints.of(context).smallerThan(kDeviceDesktop)) {
      child = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(child: logoWidget),
          const SizedBox(height: AppSpacing.md),
          Align(alignment: Alignment.centerRight, child: localizationWidget),
        ],
      );
    } else {
      child = Stack(
        children: [
          Center(child: logoWidget),
          Align(alignment: Alignment.centerRight, child: localizationWidget),
        ],
      );
    }
    return Padding(padding: const EdgeInsets.all(AppSpacing.lg), child: child);
  }
}
