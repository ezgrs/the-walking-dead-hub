import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:responsive_framework/responsive_framework.dart' as rf;
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';
import '../../main.dart';
import '../../widgets/button.dart';
import '../../widgets/header.dart';
import '../../widgets/maybe.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool compact = rf.ResponsiveBreakpoints.of(
      context,
    ).smallerThan(kDeviceDesktop);
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final List<Widget> children = [
      const HeaderWidget(),
      MaybeWidget(
        enabled: !compact,
        builder: (child) => Expanded(child: child),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                compact ? AppSpacing.md : AppSpacing.xl,
                compact ? AppSpacing.lg : AppSpacing.xxl,
                compact ? AppSpacing.md : AppSpacing.xl,
                AppSpacing.lg,
              ),
              child: rf.ResponsiveRowColumn(
                layout: compact
                    ? rf.ResponsiveRowColumnType.COLUMN
                    : rf.ResponsiveRowColumnType.ROW,
                rowCrossAxisAlignment: CrossAxisAlignment.center,
                columnCrossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  rf.ResponsiveRowColumnItem(
                    rowFlex: 6,
                    rowFit: FlexFit.tight,
                    child: _IntroSection(l10n: l10n, compact: compact),
                  ),
                  rf.ResponsiveRowColumnItem(
                    child: compact
                        ? const SizedBox(height: AppSpacing.xl)
                        : const SizedBox(width: AppSpacing.xxl),
                  ),
                  rf.ResponsiveRowColumnItem(
                    rowFlex: 4,
                    rowFit: FlexFit.tight,
                    child: _MenuSection(l10n: l10n),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      _Footer(label: l10n.homepageCreatedByLabel),
    ];

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(color: AppColors.background),
        child: compact
            ? ListView(children: children)
            : Column(children: children),
      ),
    );
  }
}

class _IntroSection extends StatelessWidget {
  final AppLocalizations l10n;
  final bool compact;

  const _IntroSection({required this.l10n, required this.compact});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: AspectRatio(
            aspectRatio: compact ? 16 / 9 : 16 / 7,
            child: Image.network(
              'https://static.independent.co.uk/s3fs-public/thumbnails/image/2017/03/06/13/the-walking-dead-cast-1.jpg',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          l10n.homepageIntroductionTitleText,
          style: compact
              ? Theme.of(context).textTheme.displayMedium
              : Theme.of(context).textTheme.displayLarge,
        ),
        const SizedBox(height: AppSpacing.md),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Text(
            l10n.homepageIntroductionBodyText,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ],
    );
  }
}

class _MenuSection extends StatelessWidget {
  final AppLocalizations l10n;

  const _MenuSection({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.homepageMenu,
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: AppSpacing.md),
            _NavigationButton(
              icon: Icons.groups_rounded,
              label: l10n.homepageEntitiesButtonLabel,
              location: '/entities',
            ),
            const SizedBox(height: AppSpacing.sm),
            _NavigationButton(
              icon: Icons.calendar_month_rounded,
              label: l10n.homepageSeasonsButtonLabel,
              location: '/seasons',
            ),
            const SizedBox(height: AppSpacing.sm),
            _NavigationButton(
              icon: Icons.movie_filter_rounded,
              label: l10n.homepageEpisodesButtonLabel,
              location: '/episodes',
            ),
          ],
        ),
      ),
    );
  }
}

class _NavigationButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String location;

  const _NavigationButton({
    required this.icon,
    required this.label,
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    return AppButton(
      icon: icon,
      label: label,
      expanded: true,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      onTap: () => GoRouter.of(context).go(location),
    );
  }
}

class _Footer extends StatelessWidget {
  final String label;

  const _Footer({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Center(
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpacing.xs,
          children: [
            Text('$label:', style: Theme.of(context).textTheme.bodyMedium),
            TextButton(
              onPressed: () async {
                await launchUrl(
                  Uri(
                    scheme: 'https',
                    host: 'github.com',
                    pathSegments: ['ezgrs'],
                  ),
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: AppColors.accent,
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 36),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: Theme.of(context).textTheme.labelLarge,
              ),
              child: const Text('github.com/ezgrs'),
            ),
          ],
        ),
      ),
    );
  }
}
