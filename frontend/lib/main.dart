import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:responsive_framework/responsive_framework.dart' as rf;

import 'screens/homepage.dart';

void main() {
  runApp(const MainApp());
}

const String kDeviceDesktop = 'DESKTOP';
const String kDeviceLaptop = 'LAPTOP';
const String kDeviceTablet = 'TABLET';
const String kDeviceMobile = 'MOBILE';

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
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
      localizationsDelegates: const [...GlobalMaterialLocalizations.delegates],
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
      supportedLocales: const [Locale('en', 'US')],
      locale: const Locale('en', 'US'),
      routerConfig: GoRouter(
        routes: [GoRoute(path: '/', builder: (context, state) => HomeScreen())],
      ),
    );
  }
}
