import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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
  final DotEnv data = DotEnv();
  await data.load();
  runApp(
    MainApp(
      authenticator: PublicAuthenticator(),
      vault: DecodedVault(data: data.env),
    ),
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
          supportedLocales: AppLocalizations.supportedLocales,
          locale: context.watch<LocaleController>().value,
          routerConfig: context.read<GoRouter>(),
        );
      },
    );
  }
}
