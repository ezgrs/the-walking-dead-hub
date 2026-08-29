import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:responsive_framework/responsive_framework.dart' as rf;

import 'common/authenticator.dart';
import 'common/vault.dart';
import 'features/entities/bloc.dart';
import 'features/entities/bloc_event.dart';
import 'features/entities/repository.dart';
import 'features/entities/screen.dart';
import 'features/home/screen.dart';
import 'l10n/app_localizations.dart';

Future<void> main() async {
  runApp(
    MainApp(authenticator: PublicAuthenticator(), vault: HardcodedVault()),
  );
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

class AppColors {
  static const Color background = Color(0xFFF6F4EF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFECE8DD);
  static const Color ink = Color(0xFF1B1D18);
  static const Color muted = Color(0xFF686B60);
  static const Color accent = Color(0xFF5D6B46);
  static const Color accentSoft = Color(0xFFE2E8D4);
  static const Color border = Color(0xFFD8D2C4);

  const AppColors._();
}

class LocaleController extends ValueNotifier<Locale> {
  LocaleController(super.value);
}

class MainApp extends StatelessWidget {
  final Authenticator authenticator;
  final Vault vault;

  const MainApp({super.key, required this.authenticator, required this.vault});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<GoRouter>(
          create: (_) => GoRouter(
            routes: [
              GoRoute(
                path: '/',
                pageBuilder: (context, state) =>
                    NoTransitionPage(key: state.pageKey, child: HomeScreen()),
              ),
              GoRoute(
                path: '/entities',
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: EntitiesScreen(
                    bloc: EntitiesBloc(
                      repository: EntitiesRepository(
                        vault: vault,
                        authenticator: authenticator,
                      ),
                    )..add(const IndicesLoadRequested()),
                  ),
                ),
              ),
              GoRoute(
                path: '/seasons',
                pageBuilder: (context, state) =>
                    NoTransitionPage(key: state.pageKey, child: Placeholder()),
              ),
              GoRoute(
                path: '/episodes',
                pageBuilder: (context, state) =>
                    NoTransitionPage(key: state.pageKey, child: Placeholder()),
              ),
            ],
          ),
        ),
        ChangeNotifierProvider<LocaleController>(
          create: (_) => LocaleController(AppLocalizations.supportedLocales[0]),
        ),
      ],
      builder: (context, _) {
        return MaterialApp.router(
          title: 'The Walking Dead Hub',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            scaffoldBackgroundColor: AppColors.background,
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.accent,
              brightness: Brightness.light,
              surface: AppColors.surface,
            ),
            cardTheme: CardThemeData(
              color: AppColors.surface,
              elevation: 0,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: AppColors.border),
              ),
            ),
            textTheme: const TextTheme(
              displayLarge: TextStyle(
                fontSize: 48,
                height: 1.02,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
              displayMedium: TextStyle(
                fontSize: 36,
                height: 1.08,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
              displaySmall: TextStyle(
                fontSize: 24,
                height: 1.16,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
              headlineLarge: TextStyle(
                fontSize: 22,
                height: 1.2,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
              headlineMedium: TextStyle(
                fontSize: 18,
                height: 1.35,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
              headlineSmall: TextStyle(
                fontSize: 16,
                height: 1.35,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
              titleLarge: TextStyle(
                fontSize: 16,
                height: 1.45,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
              titleMedium: TextStyle(
                fontSize: 14,
                height: 1.45,
                fontWeight: FontWeight.w500,
                color: AppColors.muted,
              ),
              bodyLarge: TextStyle(
                fontSize: 16,
                height: 1.55,
                fontWeight: FontWeight.w400,
                color: AppColors.ink,
              ),
              bodyMedium: TextStyle(
                fontSize: 14,
                height: 1.5,
                fontWeight: FontWeight.w400,
                color: AppColors.muted,
              ),
              labelLarge: TextStyle(
                fontSize: 14,
                height: 1.2,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            dividerTheme: const DividerThemeData(
              color: AppColors.border,
              thickness: 1,
              space: AppSpacing.xl,
            ),
            inputDecorationTheme: const InputDecorationTheme(
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
                borderSide: BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
                borderSide: BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
                borderSide: BorderSide(color: AppColors.accent, width: 1.5),
              ),
            ),
            scrollbarTheme: ScrollbarThemeData(
              thickness: WidgetStateProperty.all(6),
              radius: const Radius.circular(999),
              thumbColor: WidgetStateProperty.all(AppColors.border),
              thumbVisibility: WidgetStateProperty.all(false),
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
          supportedLocales: AppLocalizations.supportedLocales,
          locale: context.watch<LocaleController>().value,
          routerConfig: context.read<GoRouter>(),
        );
      },
    );
  }
}
