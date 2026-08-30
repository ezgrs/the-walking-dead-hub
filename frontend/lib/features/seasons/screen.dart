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
    final int firstAppearances = stats.appearances
        .where((appearance) => _isAppearanceType(appearance, 'first'))
        .length;
    final int lastAppearances = stats.appearances
        .where((appearance) => _isAppearanceType(appearance, 'last'))
        .length;

    return Row(
      children: [
        Expanded(
          child: _SeasonEpisodeMetric(
            icon: Icons.add_rounded,
            color: const Color(0xFF2F8F4E),
            label: l10n.seasonsFirstAppearancesMetricLabel,
            value: firstAppearances.toString(),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _SeasonEpisodeMetric(
            icon: Icons.remove_rounded,
            color: const Color(0xFFC2413A),
            label: l10n.seasonsLastAppearancesMetricLabel,
            value: lastAppearances.toString(),
          ),
        ),
      ],
    );
  }
}

class _SeasonEpisodeMetric extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _SeasonEpisodeMetric({
    required this.icon,
    this.color = AppColors.accent,
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
          Icon(icon, color: color),
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
    final _AppearanceMarkerData? typeMarker = _AppearanceMarkerData.type(
      appearance.appearanceTypeLabel,
      l10n,
    );
    final _AppearanceMarkerData? formMarker = _AppearanceMarkerData.form(
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              appearance.entity.name,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          if (formMarker != null) ...[
            const SizedBox(width: AppSpacing.sm),
            _AppearanceMarker(data: formMarker),
          ],
          if (typeMarker != null) ...[
            const SizedBox(width: AppSpacing.xs),
            _AppearanceMarker(data: typeMarker),
          ],
        ],
      ),
    );
  }
}

class _AppearanceMarkerData {
  final IconData icon;
  final Color color;
  final Color backgroundColor;
  final String tooltip;

  const _AppearanceMarkerData({
    required this.icon,
    required this.color,
    required this.backgroundColor,
    required this.tooltip,
  });

  static _AppearanceMarkerData? type(
    String value,
    AppLocalizations l10n,
  ) {
    return switch (value.trim().toLowerCase()) {
      'first' => _AppearanceMarkerData(
        icon: Icons.add_rounded,
        color: const Color(0xFF2F8F4E),
        backgroundColor: const Color(0xFFE3F4E8),
        tooltip: l10n.entitiesFirstAppearanceLabel,
      ),
      'last' => _AppearanceMarkerData(
        icon: Icons.remove_rounded,
        color: const Color(0xFFC2413A),
        backgroundColor: const Color(0xFFFBE4E2),
        tooltip: l10n.entitiesLastAppearanceLabel,
      ),
      'only' => _AppearanceMarkerData(
        icon: Icons.looks_one_rounded,
        color: const Color(0xFF2563EB),
        backgroundColor: const Color(0xFFE4EDFF),
        tooltip: l10n.entitiesOnlyAppearanceLabel,
      ),
      _ => null,
    };
  }

  static _AppearanceMarkerData? form(
    String? value,
    AppLocalizations l10n,
  ) {
    final String? label = _appearanceFormLabel(value, l10n);
    final String? normalizedValue = value?.trim().toLowerCase();
    if (label == null || normalizedValue == null || normalizedValue.isEmpty) {
      return null;
    }

    return switch (normalizedValue) {
      'alive' => _AppearanceMarkerData(
        icon: Icons.favorite_rounded,
        color: const Color(0xFF2F8F4E),
        backgroundColor: const Color(0xFFE3F4E8),
        tooltip: label,
      ),
      'corpse' => _AppearanceMarkerData(
        icon: Icons.person_off_rounded,
        color: const Color(0xFF6B7280),
        backgroundColor: const Color(0xFFECEFF3),
        tooltip: label,
      ),
      'zombified' => _AppearanceMarkerData(
        icon: Icons.warning_rounded,
        color: const Color(0xFF3F6F44),
        backgroundColor: const Color(0xFFDDEEDC),
        tooltip: label,
      ),
      'voiceonly' => _AppearanceMarkerData(
        icon: Icons.volume_up_rounded,
        color: const Color(0xFF7C3AED),
        backgroundColor: const Color(0xFFEFE7FF),
        tooltip: label,
      ),
      'physically' => _AppearanceMarkerData(
        icon: Icons.accessibility_new_rounded,
        color: const Color(0xFF2563EB),
        backgroundColor: const Color(0xFFE4EDFF),
        tooltip: label,
      ),
      'videotape' => _AppearanceMarkerData(
        icon: Icons.videocam_rounded,
        color: const Color(0xFFB45309),
        backgroundColor: const Color(0xFFFFF3D8),
        tooltip: label,
      ),
      'flashback' => _AppearanceMarkerData(
        icon: Icons.history_rounded,
        color: const Color(0xFF0F766E),
        backgroundColor: const Color(0xFFDCF5F1),
        tooltip: label,
      ),
      'photograph' => _AppearanceMarkerData(
        icon: Icons.photo_camera_rounded,
        color: const Color(0xFF4F46E5),
        backgroundColor: const Color(0xFFE8E7FF),
        tooltip: label,
      ),
      'hallucination' => _AppearanceMarkerData(
        icon: Icons.visibility_rounded,
        color: const Color(0xFFBE185D),
        backgroundColor: const Color(0xFFFCE7F3),
        tooltip: label,
      ),
      'dream' => _AppearanceMarkerData(
        icon: Icons.bedtime_rounded,
        color: const Color(0xFF6D28D9),
        backgroundColor: const Color(0xFFEFE7FF),
        tooltip: label,
      ),
      'ultrasound' => _AppearanceMarkerData(
        icon: Icons.graphic_eq_rounded,
        color: const Color(0xFF0891B2),
        backgroundColor: const Color(0xFFDDF7FC),
        tooltip: label,
      ),
      _ => _AppearanceMarkerData(
        icon: Icons.category_rounded,
        color: AppColors.accent,
        backgroundColor: AppColors.accentSoft,
        tooltip: label,
      ),
    };
  }
}

class _AppearanceMarker extends StatelessWidget {
  final _AppearanceMarkerData data;

  const _AppearanceMarker({required this.data});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: data.tooltip,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: data.backgroundColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(data.icon, color: data.color, size: 17),
      ),
    );
  }
}

String _episodeReference(Episode episode, AppLocalizations l10n) {
  return '${l10n.entitiesSeasonShortLabel}${episode.seasonNumber} '
      '${l10n.entitiesEpisodeShortLabel}${episode.episodeNumber}';
}

bool _isAppearanceType(SeasonEpisodeAppearanceDto appearance, String type) {
  return appearance.appearanceTypeLabel.trim().toLowerCase() == type;
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
