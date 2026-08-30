import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';
import '../../main.dart';
import '../../models.dart';
import '../../widgets/indexed_master_detail.dart';
import 'bloc.dart';
import 'bloc_event.dart';
import 'bloc_state.dart';

class SeasonsScreen extends StatelessWidget {
  final SeasonsBloc bloc;

  const SeasonsScreen({super.key, required this.bloc});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return BlocBuilder<SeasonsBloc, SeasonsState>(
      bloc: bloc,
      builder: (context, state) {
        return AppIndexedMasterDetailPage<Episode>(
          icon: Icons.calendar_view_month_rounded,
          color: AppColors.accent,
          iconBackgroundColor: AppColors.accentSoft,
          title: l10n.homepageSeasonsButtonLabel,
          indicesLoading: state is SeasonsIndicesLoadInProgress,
          recordsLoading: state is SeasonEpisodesLoadInProgress,
          indices: _indicesFor(l10n, state),
          selectedIndex: _selectedIndexFor(state),
          onIndexSelected: (index) {
            bloc.add(
              SeasonEpisodesLoadRequested(seasonNumber: int.parse(index)),
            );
          },
          records: _episodesFor(state),
          recordsArePreFiltered: true,
          selectedRecordKey: _selectedEpisodeKeyFor(state),
          recordIndexBuilder: (episode) => "${episode.seasonNumber}",
          recordKeyBuilder: _episodeKey,
          recordLabelBuilder: (episode) => _episodeListLabel(episode, l10n),
          onRecordSelected: (episode) {
            bloc.add(
              SeasonEpisodeLoadRequested(
                seasonNumber: episode.seasonNumber,
                episodeNumber: episode.episodeNumber,
              ),
            );
          },
          detailBuilder: (context, _, compact) =>
              _buildDetail(context, state, compact),
          searchHint: l10n.seasonsSearchHint,
          chooseIndexTitle: l10n.seasonsChooseIndexTitle,
          chooseIndexMessage: l10n.seasonsChooseIndexMessage,
          emptyRecordsTitle: l10n.seasonsNoResultsTitle,
          emptyRecordsMessage: l10n.seasonsNoResultsMessage,
          emptySearchTitle: l10n.seasonsNoResultsTitle,
          emptySearchMessage: l10n.seasonsNoSearchResultsMessage,
        );
      },
    );
  }

  List<AppIndexedMasterDetailIndex> _indicesFor(
    AppLocalizations l10n,
    SeasonsState state,
  ) {
    return switch (state) {
      SeasonsIndicesLoadSuccessBase(:final indices) =>
        indices
            .map(
              (index) => AppIndexedMasterDetailIndex(
                value: "${index.index}",
                count: index.count,
              ),
            )
            .toList(),
      _ => const [],
    };
  }

  String? _selectedIndexFor(SeasonsState state) {
    return switch (state) {
      SeasonSelectedInitialBase(:final seasonNumber) => seasonNumber.toString(),
      _ => null,
    };
  }

  List<Episode> _episodesFor(SeasonsState state) {
    return switch (state) {
      SeasonEpisodesLoadSuccessBase(:final episodes) => episodes,
      _ => const [],
    };
  }

  Object? _selectedEpisodeKeyFor(SeasonsState state) {
    return switch (state) {
      SeasonEpisodeLoadInProgress(:final seasonNumber, :final episodeNumber) =>
        '$seasonNumber:$episodeNumber',
      SeasonEpisodeSelectedInitial(:final stats) => _episodeKey(stats.episode),
      _ => null,
    };
  }

  Widget _buildDetail(BuildContext context, SeasonsState state, bool compact) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return switch (state) {
      SeasonEpisodeLoadInProgress() => AppIndexedDetailSkeleton(
        compact: compact,
      ),
      SeasonEpisodeSelectedInitial(:final stats) => _SeasonEpisodeDetails(
        stats: stats,
        compact: compact,
      ),
      _ => AppIndexedEmptyState(
        icon: Icons.movie_filter_rounded,
        title: l10n.seasonsSelectEpisodeTitle,
        message: l10n.seasonsSelectEpisodeMessage,
      ),
    };
  }

  String _episodeListLabel(Episode episode, AppLocalizations l10n) {
    return '${l10n.seasonsEpisodeShortLabel}${episode.episodeNumber} - '
        '${episode.name}';
  }

  Object _episodeKey(Episode episode) {
    return '${episode.seasonNumber}:${episode.episodeNumber}';
  }
}

class _SeasonEpisodeDetails extends StatelessWidget {
  final SeasonEpisodeDto stats;
  final bool compact;

  const _SeasonEpisodeDetails({required this.stats, required this.compact});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

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
          children: [
            _SeasonEpisodeHeader(episode: stats.episode),
            const SizedBox(height: AppSpacing.lg),
            _SeasonEpisodeStats(stats: stats),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.seasonsAppearancesTitle,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.md),
            compact
                ? _SeasonEpisodeAppearances(appearances: stats.appearances)
                : Expanded(
                    child: _SeasonEpisodeAppearances(
                      appearances: stats.appearances,
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class _SeasonEpisodeHeader extends StatelessWidget {
  final Episode episode;

  const _SeasonEpisodeHeader({required this.episode});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                episode.name,
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                _episodeReference(episode, l10n),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Tooltip(
          message: l10n.entitiesOpenFandomTooltip,
          child: IconButton.outlined(
            onPressed: () async {
              await launchUrl(
                Uri(
                  scheme: 'https',
                  host: 'walkingdead.fandom.com',
                  path: episode.wikiHref,
                ),
              );
            },
            icon: SvgPicture.network(
              'https://upload.wikimedia.org/wikipedia/commons/e/ee/Fandom_heart-logo.svg',
              height: 22,
            ),
          ),
        ),
      ],
    );
  }
}

class _SeasonEpisodeStats extends StatelessWidget {
  final SeasonEpisodeDto stats;

  const _SeasonEpisodeStats({required this.stats});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final Set<String> forms = {};
    for (final SeasonEpisodeAppearanceDto appearance in stats.appearances) {
      final String? form = appearance.appearanceFormTypeLabel?.trim();
      if (form != null && form.isNotEmpty) {
        forms.add(form.toLowerCase());
      }
    }

    return Row(
      children: [
        Expanded(
          child: _SeasonEpisodeMetric(
            icon: Icons.groups_rounded,
            label: l10n.seasonsAppearancesMetricLabel,
            value: stats.appearances.length.toString(),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _SeasonEpisodeMetric(
            icon: Icons.category_rounded,
            label: l10n.seasonsAppearanceFormsMetricLabel,
            value: forms.length.toString(),
          ),
        ),
      ],
    );
  }
}

class _SeasonEpisodeMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SeasonEpisodeMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.accent),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(
                    context,
                  ).textTheme.labelMedium?.copyWith(color: AppColors.muted),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(value, style: Theme.of(context).textTheme.headlineSmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SeasonEpisodeAppearances extends StatelessWidget {
  final List<SeasonEpisodeAppearanceDto> appearances;

  const _SeasonEpisodeAppearances({required this.appearances});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    if (appearances.isEmpty) {
      return AppIndexedEmptyState(
        icon: Icons.person_off_rounded,
        title: l10n.seasonsNoAppearancesTitle,
        message: l10n.seasonsNoAppearancesMessage,
      );
    }

    return Scrollbar(
      child: SingleChildScrollView(
        child: Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: appearances
              .map((appearance) => _AppearanceCard(appearance: appearance))
              .toList(),
        ),
      ),
    );
  }
}

class _AppearanceCard extends StatelessWidget {
  final SeasonEpisodeAppearanceDto appearance;

  const _AppearanceCard({required this.appearance});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final String? formLabel = _appearanceFormLabel(
      appearance.appearanceFormTypeLabel,
      l10n,
    );

    return Container(
      width: 260,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            appearance.entity.name,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              _AppearanceChip(
                label: _appearanceTypeLabel(
                  appearance.appearanceTypeLabel,
                  l10n,
                ),
              ),
              if (formLabel != null) _AppearanceChip(label: formLabel),
            ],
          ),
        ],
      ),
    );
  }
}

class _AppearanceChip extends StatelessWidget {
  final String label;

  const _AppearanceChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.accentSoft,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelSmall),
    );
  }
}

String _episodeReference(Episode episode, AppLocalizations l10n) {
  return '${l10n.entitiesSeasonShortLabel}${episode.seasonNumber} '
      '${l10n.entitiesEpisodeShortLabel}${episode.episodeNumber}';
}

String _appearanceTypeLabel(String value, AppLocalizations l10n) {
  return switch (value.trim().toLowerCase()) {
    'first' => l10n.entitiesFirstAppearanceLabel,
    'last' => l10n.entitiesLastAppearanceLabel,
    'only' => l10n.entitiesOnlyAppearanceLabel,
    _ => l10n.entitiesOtherAppearanceLabel,
  };
}

String? _appearanceFormLabel(String? value, AppLocalizations l10n) {
  final String? normalizedValue = value?.trim();
  if (normalizedValue == null || normalizedValue.isEmpty) {
    return null;
  }

  return switch (normalizedValue.toLowerCase()) {
    'alive' => l10n.entitiesAppearanceFormAliveLabel,
    'corpse' => l10n.entitiesAppearanceFormCorpseLabel,
    'zombified' => l10n.entitiesAppearanceFormZombifiedLabel,
    'voiceonly' => l10n.entitiesAppearanceFormVoiceOnlyLabel,
    'physically' => l10n.entitiesAppearanceFormPhysicallyLabel,
    'videotape' => l10n.entitiesAppearanceFormVideoTapeLabel,
    'flashback' => l10n.entitiesAppearanceFormFlashbackLabel,
    'photograph' => l10n.entitiesAppearanceFormPhotographLabel,
    'hallucination' => l10n.entitiesAppearanceFormHallucinationLabel,
    'dream' => l10n.entitiesAppearanceFormDreamLabel,
    'ultrasound' => l10n.entitiesAppearanceFormUltrasoundLabel,
    _ => normalizedValue,
  };
}
