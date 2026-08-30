import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:responsive_framework/responsive_framework.dart' as rf;
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';
import '../../main.dart';
import '../../models.dart';
import '../../widgets/button.dart';
import '../../widgets/header.dart';
import '../../widgets/maybe.dart';
import 'bloc.dart';
import 'bloc_event.dart';
import 'bloc_state.dart';

const Map<int, int> _episodeCountsBySeason = {
  1: 6,
  2: 13,
  3: 16,
  4: 16,
  5: 16,
  6: 16,
  7: 16,
  8: 16,
  9: 16,
  10: 22,
  11: 24,
};

class EntitiesScreen extends StatelessWidget {
  final EntitiesBloc bloc;

  const EntitiesScreen({super.key, required this.bloc});

  Widget _buildIndicesLoadSuccessState(
    BuildContext context,
    IndicesLoadSuccessBase state, {
    required bool compact,
  }) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final String? selectedIndex = switch (state) {
      IndexSelectedInitialBase(:final index) => index,
      _ => null,
    };
    final List<Widget> indexButtons = state.indices
        .map(
          (obj) => AppButton(
            label: '${obj.index} (${obj.count})',
            onTap: () => bloc.add(IndexLoadRequested(index: obj.index)),
            selected: selectedIndex == obj.index,
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.sm,
              horizontal: AppSpacing.md,
            ),
          ),
        )
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: indexButtons,
        ),
        const SizedBox(height: AppSpacing.lg),
        MaybeWidget(
          enabled: !compact,
          builder: (child) => Expanded(child: child),
          child: switch (state) {
            IndicesInitial() => _EmptyState(
              icon: Icons.touch_app_rounded,
              title: l10n.entitiesChooseIndexTitle,
              message: l10n.entitiesChooseIndexMessage,
            ),
            EntitiesLoadInProgress() => _LoadingState(
              label: l10n.entitiesRecordsLoadingLabel,
            ),
            EntitiesLoadSuccessBase() => _buildEntitiesLoadSuccessState(
              context,
              state,
              compact: compact,
            ),
          },
        ),
      ],
    );
  }

  Widget _buildEntitiesLoadSuccessState(
    BuildContext context,
    EntitiesLoadSuccessBase state, {
    required bool compact,
  }) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final int? selectedEntityId = switch (state) {
      EntitySelectedInitial(:final stats) => stats.entity.id,
      _ => null,
    };
    final Widget list = _EntityList(
      bloc: bloc,
      entities: state.entities,
      selectedEntityId: selectedEntityId,
      compact: compact,
    );
    final Widget detail = switch (state) {
      EntitiesInitial() => _EmptyState(
        icon: Icons.badge_rounded,
        title: l10n.entitiesSelectRecordTitle,
        message: l10n.entitiesSelectRecordMessage,
      ),
      EntitySelectedInitial(:final stats) => _EntityDetails(
        stats: stats,
        compact: compact,
      ),
    };

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          list,
          const SizedBox(height: AppSpacing.lg),
          detail,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(flex: 4, child: list),
        const SizedBox(width: AppSpacing.lg),
        Expanded(flex: 6, child: detail),
      ],
    );
  }

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
                AppSpacing.lg,
                compact ? AppSpacing.md : AppSpacing.xl,
                AppSpacing.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _PageTitle(
                    title: AppLocalizations.of(
                      context,
                    )!.homepageEntitiesButtonLabel,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  MaybeWidget(
                    enabled: !compact,
                    builder: (child) => Expanded(child: child),
                    child: BlocBuilder<EntitiesBloc, EntitiesState>(
                      bloc: bloc,
                      builder: (context, state) {
                        return switch (state) {
                          IndicesLoadInProgress() => _LoadingState(
                            label: l10n.entitiesIndicesLoadingLabel,
                          ),
                          IndicesLoadSuccessBase() =>
                            _buildIndicesLoadSuccessState(
                              context,
                              state,
                              compact: compact,
                            ),
                        };
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
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

class _PageTitle extends StatelessWidget {
  final String title;

  const _PageTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.accentSoft,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.groups_rounded, color: AppColors.accent),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.displayMedium),
        ),
      ],
    );
  }
}

class _EntityList extends StatefulWidget {
  final EntitiesBloc bloc;
  final List<Entity> entities;
  final int? selectedEntityId;
  final bool compact;

  const _EntityList({
    required this.bloc,
    required this.entities,
    required this.selectedEntityId,
    required this.compact,
  });

  @override
  State<_EntityList> createState() => _EntityListState();
}

class _EntityListState extends State<_EntityList> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    if (widget.entities.isEmpty) {
      return _EmptyState(
        icon: Icons.search_off_rounded,
        title: l10n.entitiesNoResultsTitle,
        message: l10n.entitiesNoResultsMessage,
      );
    }

    final String normalizedQuery = _normalizeSearchText(_query);
    final List<Entity> visibleEntities = widget.entities
        .where(
          (entity) =>
              normalizedQuery.isEmpty ||
              _normalizeSearchText(entity.name).contains(normalizedQuery),
        )
        .toList();

    final Widget results = visibleEntities.isEmpty
        ? _EmptyState(
            icon: Icons.search_off_rounded,
            title: l10n.entitiesNoResultsTitle,
            message: l10n.entitiesNoSearchResultsMessage,
          )
        : _EntityCards(
            bloc: widget.bloc,
            entities: visibleEntities,
            selectedEntityId: widget.selectedEntityId,
            compact: widget.compact,
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          onChanged: (value) => setState(() => _query = value),
          decoration: InputDecoration(
            hintText: l10n.entitiesSearchHint,
            prefixIcon: const Icon(Icons.search_rounded),
            isDense: true,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        widget.compact ? results : Expanded(child: results),
      ],
    );
  }
}

class _EntityCards extends StatelessWidget {
  final EntitiesBloc bloc;
  final List<Entity> entities;
  final int? selectedEntityId;
  final bool compact;

  const _EntityCards({
    required this.bloc,
    required this.entities,
    required this.selectedEntityId,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    if (entities.isEmpty) {
      final AppLocalizations l10n = AppLocalizations.of(context)!;
      return _EmptyState(
        icon: Icons.search_off_rounded,
        title: l10n.entitiesNoResultsTitle,
        message: l10n.entitiesNoResultsMessage,
      );
    }

    final Iterable<Widget> cards = entities.map(
      (entity) => _EntityCard(
        bloc: bloc,
        entity: entity,
        selected: selectedEntityId == entity.id,
      ),
    );

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children:
            cards
                .expand(
                  (child) => [child, const SizedBox(height: AppSpacing.sm)],
                )
                .toList()
              ..removeLast(),
      );
    }

    return ListView.separated(
      itemCount: entities.length,
      itemBuilder: (context, index) {
        final Entity entity = entities[index];
        return _EntityCard(
          bloc: bloc,
          entity: entity,
          selected: selectedEntityId == entity.id,
        );
      },
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppSpacing.sm),
    );
  }
}

class _EntityCard extends StatelessWidget {
  final EntitiesBloc bloc;
  final Entity entity;
  final bool selected;

  const _EntityCard({
    required this.entity,
    required this.bloc,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    final Color background = selected
        ? AppColors.accentSoft
        : AppColors.surface;
    final BorderSide border = selected
        ? const BorderSide(color: AppColors.accent, width: 1.5)
        : const BorderSide(color: AppColors.border);

    return Material(
      color: background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: border,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => bloc.add(EpisodesLoadRequested(entityId: entity.id)),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      entity.name,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Icon(
                Icons.chevron_right_rounded,
                color: selected ? AppColors.accent : AppColors.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EntityDetails extends StatefulWidget {
  final EntityOut stats;
  final bool compact;

  const _EntityDetails({required this.stats, required this.compact});

  @override
  State<_EntityDetails> createState() => _EntityDetailsState();
}

class _EntityDetailsState extends State<_EntityDetails> {
  bool _showAllEpisodes = false;

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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.stats.entity.name,
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        widget.stats.entity.wikiHref,
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
                          path: widget.stats.entity.wikiHref,
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
            ),
            const SizedBox(height: AppSpacing.lg),
            widget.compact
                ? SizedBox(
                    height: 560,
                    child: _EntityDetailsBody(
                      episodes: widget.stats.episodes,
                      showAllEpisodes: _showAllEpisodes,
                      onShowAllEpisodesChanged: _setShowAllEpisodes,
                    ),
                  )
                : Expanded(
                    child: _EntityDetailsBody(
                      episodes: widget.stats.episodes,
                      showAllEpisodes: _showAllEpisodes,
                      onShowAllEpisodesChanged: _setShowAllEpisodes,
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  void _setShowAllEpisodes(bool? value) {
    setState(() => _showAllEpisodes = value ?? false);
  }
}

class _EntityDetailsBody extends StatelessWidget {
  final List<EpisodeOut> episodes;
  final bool showAllEpisodes;
  final ValueChanged<bool?> onShowAllEpisodesChanged;

  const _EntityDetailsBody({
    required this.episodes,
    required this.showAllEpisodes,
    required this.onShowAllEpisodesChanged,
  });

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final _EpisodeSlotRange appearanceRange = _appearanceRangeFor(episodes);

    return DefaultTabController(
      length: 1,
      child: Scrollbar(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelColor: AppColors.ink,
                indicatorColor: AppColors.accent,
                dividerColor: AppColors.border,
                labelStyle: Theme.of(context).textTheme.labelLarge,
                tabs: [Tab(text: l10n.entitiesAppearanceMapTitle)],
              ),
              const SizedBox(height: AppSpacing.md),
              Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _AppearanceLegendButton(
                      showAppearanceRange: appearanceRange.isValid,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _ShowAllEpisodesToggle(
                      value: showAllEpisodes,
                      onChanged: onShowAllEpisodesChanged,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _AppearanceMap(
                episodes: episodes,
                showAllEpisodes: showAllEpisodes,
                appearanceRange: appearanceRange,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppearanceLegendButton extends StatelessWidget {
  final bool showAppearanceRange;

  const _AppearanceLegendButton({required this.showAppearanceRange});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return Tooltip(
      message: l10n.entitiesAppearanceLegendTooltip,
      child: IconButton(
        onPressed: () {
          showDialog<void>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(l10n.entitiesAppearanceLegendTitle),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: _AppearanceLegend(
                  showAppearanceRange: showAppearanceRange,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.entitiesCloseDialogLabel),
                ),
              ],
            ),
          );
        },
        icon: const Icon(Icons.info_outline_rounded),
      ),
    );
  }
}

class _ShowAllEpisodesToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?> onChanged;

  const _ShowAllEpisodesToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return Tooltip(
      message: l10n.entitiesShowAllEpisodesDescription,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => onChanged(!value),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IgnorePointer(
                child: Checkbox(
                  value: value,
                  onChanged: onChanged,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                l10n.entitiesShowAllEpisodesLabel,
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppearanceLegend extends StatelessWidget {
  final bool showAppearanceRange;

  const _AppearanceLegend({required this.showAppearanceRange});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        _LegendItem(
          color: const Color(0xFF2E7D32),
          icon: Icons.play_arrow_rounded,
          label: l10n.entitiesFirstAppearanceLabel,
        ),
        _LegendItem(
          color: const Color(0xFFC2413A),
          icon: Icons.flag_rounded,
          label: l10n.entitiesLastAppearanceLabel,
        ),
        _LegendItem(
          color: const Color(0xFF2563EB),
          icon: Icons.looks_one_rounded,
          label: l10n.entitiesOnlyAppearanceLabel,
        ),
        if (showAppearanceRange)
          _LegendItem(
            color: const Color(0xFFB7791F),
            icon: Icons.horizontal_rule_rounded,
            label: l10n.entitiesAppearanceRangeLabel,
          ),
        _LegendItem(
          color: AppColors.muted,
          icon: Icons.circle_rounded,
          label: l10n.entitiesOtherAppearanceLabel,
        ),
        _LegendItem(
          color: AppColors.border,
          icon: Icons.circle_outlined,
          label: l10n.entitiesNoAppearanceLabel,
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;

  const _LegendItem({
    required this.color,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: AppSpacing.xs),
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

class _AppearanceMap extends StatelessWidget {
  final List<EpisodeOut> episodes;
  final bool showAllEpisodes;
  final _EpisodeSlotRange appearanceRange;

  const _AppearanceMap({
    required this.episodes,
    required this.showAllEpisodes,
    required this.appearanceRange,
  });

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final List<int> seasons = _seasonsToShow();
    final Map<String, EpisodeOut> appearancesBySlot = _appearancesBySlot;

    if (seasons.isEmpty) {
      return _EmptyState(
        icon: Icons.grid_view_rounded,
        title: l10n.entitiesNoAppearancesTitle,
        message: l10n.entitiesNoAppearancesMessage,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children:
          seasons
              .map(
                (season) => _SeasonAppearanceRow(
                  season: season,
                  episodeNumbers: _episodeNumbersForSeason(season),
                  appearancesBySlot: appearancesBySlot,
                  appearanceRange: appearanceRange,
                ),
              )
              .expand((child) => [child, const SizedBox(height: AppSpacing.md)])
              .toList()
            ..removeLast(),
    );
  }

  Map<String, EpisodeOut> get _appearancesBySlot {
    return {
      for (final EpisodeOut appearance in episodes)
        _episodeKey(
          appearance.episode.seasonNumber,
          appearance.episode.episodeNumber,
        ): appearance,
    };
  }

  List<int> _seasonsToShow() {
    if (showAllEpisodes) {
      final Set<int> seasons = {..._episodeCountsBySeason.keys};
      for (final EpisodeOut appearance in episodes) {
        seasons.add(appearance.episode.seasonNumber);
      }
      return seasons.toList()..sort();
    }

    final Set<int> seasons = {};
    for (final EpisodeOut appearance in episodes) {
      seasons.add(appearance.episode.seasonNumber);
    }
    if (appearanceRange.isValid) {
      for (final int season in _availableSeasons) {
        if (appearanceRange.intersectsSeason(season)) {
          seasons.add(season);
        }
      }
    }
    return seasons.toList()..sort();
  }

  List<int> _episodeNumbersForSeason(int season) {
    final int count = _episodeCountForSeason(season);
    return List<int>.generate(count, (index) => index + 1);
  }

  int _episodeCountForSeason(int season) {
    int count = _episodeCountsBySeason[season] ?? 0;
    for (final EpisodeOut appearance in episodes) {
      final Episode episode = appearance.episode;
      if (episode.seasonNumber == season && episode.episodeNumber > count) {
        count = episode.episodeNumber;
      }
    }
    return count;
  }
}

class _SeasonAppearanceRow extends StatelessWidget {
  final int season;
  final List<int> episodeNumbers;
  final Map<String, EpisodeOut> appearancesBySlot;
  final _EpisodeSlotRange appearanceRange;

  const _SeasonAppearanceRow({
    required this.season,
    required this.episodeNumbers,
    required this.appearancesBySlot,
    required this.appearanceRange,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 48,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.ink,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                season.toString(),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.surface,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: episodeNumbers
                .map(
                  (episodeNumber) => _EpisodeAppearanceCell(
                    season: season,
                    episodeNumber: episodeNumber,
                    appearance:
                        appearancesBySlot[_episodeKey(season, episodeNumber)],
                    inAppearanceRange: appearanceRange.contains(
                      season,
                      episodeNumber,
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _EpisodeAppearanceCell extends StatelessWidget {
  final int season;
  final int episodeNumber;
  final EpisodeOut? appearance;
  final bool inAppearanceRange;

  const _EpisodeAppearanceCell({
    required this.season,
    required this.episodeNumber,
    required this.appearance,
    required this.inAppearanceRange,
  });

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final EpisodeOut? appearance = this.appearance;
    final _AppearanceTone tone = _AppearanceTone.from(
      appearance?.appearanceTypeLabel,
      inAppearanceRange: inAppearanceRange,
      hasAppearance: appearance != null,
    );
    final _AppearanceMilestone? milestone = appearance == null
        ? null
        : _AppearanceMilestone.from(appearance.appearanceTypeLabel, l10n);

    final Widget cell = Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: tone.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tone.border),
      ),
      child: Stack(
        children: [
          Center(
            child: Text(
              episodeNumber.toString(),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: tone.foreground,
                fontSize: 12,
              ),
            ),
          ),
          if (tone.icon != null)
            Positioned(
              top: 3,
              right: 3,
              child: Icon(tone.icon, size: 10, color: tone.foreground),
            ),
        ],
      ),
    );

    if (appearance == null) {
      return cell;
    }

    return Tooltip(
      message: _tooltipMessage(l10n, appearance, milestone),
      child: cell,
    );
  }

  String _tooltipMessage(
    AppLocalizations l10n,
    EpisodeOut appearance,
    _AppearanceMilestone? milestone,
  ) {
    final String typeLabel =
        milestone?.label ??
        (inAppearanceRange
            ? l10n.entitiesAppearanceRangeLabel
            : l10n.entitiesOtherAppearanceLabel);
    final String? translatedFormLabel = _appearanceFormLabel(
      appearance.appearanceFormTypeLabel,
      l10n,
    );
    final String formLabel = translatedFormLabel == null
        ? ''
        : ' - $translatedFormLabel';

    return '${appearance.episode.name} - $typeLabel$formLabel';
  }
}

class _AppearanceTone {
  final Color background;
  final Color border;
  final Color foreground;
  final IconData? icon;

  const _AppearanceTone({
    required this.background,
    required this.border,
    required this.foreground,
    this.icon,
  });

  factory _AppearanceTone.from(
    String? value, {
    required bool inAppearanceRange,
    required bool hasAppearance,
  }) {
    return switch (value?.trim().toLowerCase()) {
      'first' => const _AppearanceTone(
        background: Color(0xFFE3F4E8),
        border: Color(0xFF2E7D32),
        foreground: Color(0xFF2E7D32),
        icon: Icons.play_arrow_rounded,
      ),
      'last' => const _AppearanceTone(
        background: Color(0xFFFBE4E2),
        border: Color(0xFFC2413A),
        foreground: Color(0xFFC2413A),
        icon: Icons.flag_rounded,
      ),
      'only' => const _AppearanceTone(
        background: Color(0xFFE4EDFF),
        border: Color(0xFF2563EB),
        foreground: Color(0xFF2563EB),
        icon: Icons.looks_one_rounded,
      ),
      _ when inAppearanceRange => _AppearanceTone.lifeRange(
        hasAppearance: hasAppearance,
      ),
      _ when hasAppearance => const _AppearanceTone(
        background: AppColors.surfaceMuted,
        border: AppColors.border,
        foreground: AppColors.ink,
        icon: Icons.circle_rounded,
      ),
      _ => const _AppearanceTone(
        background: AppColors.surface,
        border: AppColors.border,
        foreground: AppColors.muted,
      ),
    };
  }

  factory _AppearanceTone.lifeRange({required bool hasAppearance}) {
    return _AppearanceTone(
      background: const Color(0xFFFFF4D6),
      border: const Color(0xFFE3B341),
      foreground: const Color(0xFF8A5A00),
      icon: hasAppearance ? Icons.circle_rounded : null,
    );
  }
}

class _AppearanceMilestone {
  final String label;

  const _AppearanceMilestone({required this.label});

  static _AppearanceMilestone? from(String value, AppLocalizations l10n) {
    return switch (value.trim().toLowerCase()) {
      'first' => _AppearanceMilestone(label: l10n.entitiesFirstAppearanceLabel),
      'last' => _AppearanceMilestone(label: l10n.entitiesLastAppearanceLabel),
      'only' => _AppearanceMilestone(label: l10n.entitiesOnlyAppearanceLabel),
      _ => null,
    };
  }
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

class _EpisodeSlotRange {
  final int? start;
  final int? end;

  const _EpisodeSlotRange({required this.start, required this.end});

  factory _EpisodeSlotRange.empty() {
    return const _EpisodeSlotRange(start: null, end: null);
  }

  bool get isValid => start != null && end != null;

  bool contains(int season, int episode) {
    final int? start = this.start;
    final int? end = this.end;
    if (start == null || end == null) {
      return false;
    }

    final int index = _episodeAbsoluteIndex(season, episode);
    return index > start && index < end;
  }

  bool intersectsSeason(int season) {
    final int? start = this.start;
    final int? end = this.end;
    final int episodeCount = _episodeCountsBySeason[season] ?? 0;
    if (start == null || end == null || episodeCount == 0) {
      return false;
    }

    final int seasonStart = _episodeAbsoluteIndex(season, 1);
    final int seasonEnd = _episodeAbsoluteIndex(season, episodeCount);
    return seasonStart < end && seasonEnd > start;
  }
}

_EpisodeSlotRange _appearanceRangeFor(List<EpisodeOut> episodes) {
  final List<EpisodeOut> sorted = episodes.toList()
    ..sort((a, b) {
      final int aIndex = _episodeAbsoluteIndex(
        a.episode.seasonNumber,
        a.episode.episodeNumber,
      );
      final int bIndex = _episodeAbsoluteIndex(
        b.episode.seasonNumber,
        b.episode.episodeNumber,
      );
      return aIndex.compareTo(bIndex);
    });

  Episode? first;
  for (final EpisodeOut appearance in sorted) {
    final bool isFirst =
        appearance.appearanceTypeLabel.trim().toLowerCase() == 'first';
    if (isFirst && appearance.appearanceFormTypeLabel == null) {
      first = appearance.episode;
      break;
    }
  }

  if (first == null) {
    return _EpisodeSlotRange.empty();
  }

  final int firstIndex = _episodeAbsoluteIndex(
    first.seasonNumber,
    first.episodeNumber,
  );
  Episode? last;
  for (final EpisodeOut appearance in sorted) {
    final int index = _episodeAbsoluteIndex(
      appearance.episode.seasonNumber,
      appearance.episode.episodeNumber,
    );
    final bool isLast =
        appearance.appearanceTypeLabel.trim().toLowerCase() == 'last';
    if (index > firstIndex && isLast) {
      last = appearance.episode;
      break;
    }
  }

  if (last == null) {
    return _EpisodeSlotRange.empty();
  }

  return _EpisodeSlotRange(
    start: firstIndex,
    end: _episodeAbsoluteIndex(last.seasonNumber, last.episodeNumber),
  );
}

String _normalizeSearchText(String value) {
  return value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp('[áàâãä]'), 'a')
      .replaceAll(RegExp('[éèêë]'), 'e')
      .replaceAll(RegExp('[íìîï]'), 'i')
      .replaceAll(RegExp('[óòôõö]'), 'o')
      .replaceAll(RegExp('[úùûü]'), 'u')
      .replaceAll('ç', 'c');
}

int _episodeAbsoluteIndex(int season, int episode) {
  int index = episode;
  for (final MapEntry<int, int> entry in _episodeCountsBySeason.entries) {
    if (entry.key >= season) {
      break;
    }
    index += entry.value;
  }
  return index;
}

List<int> get _availableSeasons {
  return _episodeCountsBySeason.keys.toList()..sort();
}

String _episodeKey(int season, int episode) => '$season:$episode';

class _LoadingState extends StatelessWidget {
  final String label;

  const _LoadingState({required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 32, color: AppColors.accent),
                const SizedBox(height: AppSpacing.md),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
