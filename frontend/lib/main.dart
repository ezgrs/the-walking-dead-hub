import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:responsive_framework/responsive_framework.dart' as rf;

import 'features/home/screen.dart';
import 'l10n/app_localizations.dart';

void main() {
  runApp(const MainApp());
}

const String kDeviceDesktop = 'DESKTOP';
const String kDeviceLaptop = 'LAPTOP';
const String kDeviceTablet = 'TABLET';
const String kDeviceMobile = 'MOBILE';

class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 40;
  static const double xxxl = 48;
  static const double huge = 64;

  const AppSpacing._();
}

class LocaleController {
  final ValueNotifier<Locale> locale = ValueNotifier(const Locale('en', 'US'));

  void setLocale(Locale newLocale) {
    locale.value = newLocale;
  }
}

final LocaleController localeController = LocaleController();

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: localeController.locale,
      builder: (context, locale, _) {
        return MaterialApp.router(
          title: 'The Walking Dead Hub',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            inputDecorationTheme: const InputDecorationTheme(
              border: OutlineInputBorder(),
            ),
            fontFamily: "JollyLodger",
            scrollbarTheme: ScrollbarThemeData(
              thickness: WidgetStateProperty.all(10),
              radius: Radius.zero,
              thumbColor: WidgetStateProperty.all(Colors.grey),
              thumbVisibility: WidgetStateProperty.all(true),
            ),
          ),
          localizationsDelegates: [
            AppLocalizations.delegate,
            ...GlobalMaterialLocalizations.delegates,
          ],
          builder: (context, child) {
            child = rf.ResponsiveBreakpoints.builder(
              child: child!,
              breakpoints: const [
                rf.Breakpoint(start: 0, end: 319),
                rf.Breakpoint(start: 320, end: 719, name: kDeviceMobile),
                rf.Breakpoint(start: 720, end: 1279, name: kDeviceTablet),
                rf.Breakpoint(start: 1280, end: 1600, name: kDeviceLaptop),
                rf.Breakpoint(
                  start: 1601,
                  end: double.infinity,
                  name: kDeviceDesktop,
                ),
              ],
            );
            final MediaQueryData media = MediaQuery.of(context);
            child = MediaQuery(
              data: media.copyWith(textScaler: media.textScaler),
              child: child,
            );
            return child;
          },
          supportedLocales: const [Locale('en', 'US'), Locale('pt', 'BR')],
          locale: locale,
          routerConfig: GoRouter(
            routes: [
              GoRoute(path: '/', builder: (context, _) => HomeScreen()),
              GoRoute(
                path: '/characters',
                builder: (context, _) => Placeholder(),
              ),
              GoRoute(path: '/seasons', builder: (context, _) => Placeholder()),
              GoRoute(
                path: '/episodes',
                builder: (context, _) => Placeholder(),
              ),
            ],
          ),
        );
      },
    );
  }
}
