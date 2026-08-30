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

const List<String> _knownAppearanceForms = [
  'alive',
  'corpse',
  'zombified',
  'voiceonly',
  'physically',
  'videotape',
  'flashback',
  'photograph',
  'hallucination',
  'dream',
  'ultrasound',
];

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
            EntitiesLoadInProgress() => _EntityListSkeleton(compact: compact),
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
      EpisodesLoadInProgress(:final selectedEntityId) => selectedEntityId,
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
      EpisodesLoadInProgress() => _EntityDetailSkeleton(compact: compact),
      EntitySelectedInitial(:final stats) => _EntityDetails(
        stats: stats,
        entities: state.entities,
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
                          IndicesLoadInProgress() => _EntitiesInitialSkeleton(
                            compact: compact,
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

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        body: DecoratedBox(
          decoration: const BoxDecoration(color: AppColors.background),
          child: compact
              ? ListView(children: children)
              : Column(children: children),
        ),
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

class _EntityListSkeleton extends StatelessWidget {
  final bool compact;

  const _EntityListSkeleton({required this.compact});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return Semantics(
      label: l10n.entitiesRecordsLoadingLabel,
      child: _Shimmer(child: _EntityContentSkeleton(compact: compact)),
    );
  }
}

class _EntitiesInitialSkeleton extends StatelessWidget {
  final bool compact;

  const _EntitiesInitialSkeleton({required this.compact});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final Widget content = compact
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _IndexButtonsSkeleton(),
              const SizedBox(height: AppSpacing.lg),
              _EntityContentSkeleton(compact: compact),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _IndexButtonsSkeleton(),
              const SizedBox(height: AppSpacing.lg),
              Expanded(child: _EntityContentSkeleton(compact: compact)),
            ],
          );

    return Semantics(
      label: l10n.entitiesIndicesLoadingLabel,
      child: _Shimmer(child: content),
    );
  }
}

class _IndexButtonsSkeleton extends StatelessWidget {
  const _IndexButtonsSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        _SkeletonBlock(width: 58, height: 38, radius: 8),
        _SkeletonBlock(width: 64, height: 38, radius: 8),
        _SkeletonBlock(width: 56, height: 38, radius: 8),
        _SkeletonBlock(width: 68, height: 38, radius: 8),
        _SkeletonBlock(width: 60, height: 38, radius: 8),
        _SkeletonBlock(width: 62, height: 38, radius: 8),
        _SkeletonBlock(width: 54, height: 38, radius: 8),
        _SkeletonBlock(width: 66, height: 38, radius: 8),
        _SkeletonBlock(width: 58, height: 38, radius: 8),
        _SkeletonBlock(width: 64, height: 38, radius: 8),
      ],
    );
  }
}

class _EntityContentSkeleton extends StatelessWidget {
  final bool compact;

  const _EntityContentSkeleton({required this.compact});

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _EntityListSkeletonPane(compact: true),
          SizedBox(height: AppSpacing.lg),
          _EntityDetailSkeletonPane(compact: true),
        ],
      );
    }

    return const Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(flex: 4, child: _EntityListSkeletonPane(compact: false)),
        SizedBox(width: AppSpacing.lg),
        Expanded(flex: 6, child: _EntityDetailSkeletonPane(compact: false)),
      ],
    );
  }
}

class _EntityListSkeletonPane extends StatelessWidget {
  final bool compact;

  const _EntityListSkeletonPane({required this.compact});

  @override
  Widget build(BuildContext context) {
    final Widget cards = compact
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: _skeletonCards(6),
          )
        : Expanded(
            child: ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 8,
              itemBuilder: (context, index) => const _EntitySkeletonCard(),
              separatorBuilder: (context, index) =>
                  const SizedBox(height: AppSpacing.sm),
            ),
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SkeletonBlock(height: 48, radius: 8),
        const SizedBox(height: AppSpacing.md),
        cards,
      ],
    );
  }

  static List<Widget> _skeletonCards(int count) {
    return List<Widget>.generate(count, (index) {
      return Padding(
        padding: EdgeInsets.only(top: index == 0 ? 0 : AppSpacing.sm),
        child: const _EntitySkeletonCard(),
      );
    });
  }
}

class _EntityDetailSkeletonPane extends StatelessWidget {
  final bool compact;

  const _EntityDetailSkeletonPane({required this.compact});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SkeletonBlock(width: 220, height: 28, radius: 7),
                    SizedBox(height: AppSpacing.sm),
                    _SkeletonBlock(width: 300, height: 16, radius: 6),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const _EntityDetailsTabs(),
          const SizedBox(height: AppSpacing.md),
          if (compact) ...[
            const _EntityDetailMapSkeleton(),
          ] else ...[
            Expanded(child: const _EntityDetailMapSkeleton()),
          ],
        ],
      ),
    );
  }
}

class _EntityDetailSkeleton extends StatelessWidget {
  final bool compact;

  const _EntityDetailSkeleton({required this.compact});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return Semantics(
      label: l10n.entitiesRecordsLoadingLabel,
      child: _Shimmer(
        child: _EntityDetailSkeletonPane(compact: compact),
      ),
    );
  }
}

class _EntityDetailMapSkeleton extends StatelessWidget {
  const _EntityDetailMapSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Align(
          alignment: Alignment.centerRight,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SkeletonBlock(width: 40, height: 40, radius: 8),
              SizedBox(width: AppSpacing.sm),
              _SkeletonBlock(width: 168, height: 40, radius: 8),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ...List<Widget>.generate(6, (index) {
          return Padding(
            padding: EdgeInsets.only(top: index == 0 ? 0 : AppSpacing.md),
            child: const _SkeletonEpisodeRow(),
          );
        }),
      ],
    );
  }
}

class _SkeletonEpisodeRow extends StatelessWidget {
  const _SkeletonEpisodeRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SkeletonBlock(width: 34, height: 34, radius: 8),
        SizedBox(width: AppSpacing.md),
        Expanded(
          child: Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              _SkeletonBlock(width: 34, height: 34, radius: 8),
              _SkeletonBlock(width: 34, height: 34, radius: 8),
              _SkeletonBlock(width: 34, height: 34, radius: 8),
              _SkeletonBlock(width: 34, height: 34, radius: 8),
              _SkeletonBlock(width: 34, height: 34, radius: 8),
              _SkeletonBlock(width: 34, height: 34, radius: 8),
              _SkeletonBlock(width: 34, height: 34, radius: 8),
              _SkeletonBlock(width: 34, height: 34, radius: 8),
              _SkeletonBlock(width: 34, height: 34, radius: 8),
              _SkeletonBlock(width: 34, height: 34, radius: 8),
              _SkeletonBlock(width: 34, height: 34, radius: 8),
              _SkeletonBlock(width: 34, height: 34, radius: 8),
            ],
          ),
        ),
      ],
    );
  }
}

class _EntitySkeletonCard extends StatelessWidget {
  const _EntitySkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: const Row(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: _SkeletonBlock(width: 180, height: 18, radius: 6),
            ),
          ),
          SizedBox(width: AppSpacing.md),
          _SkeletonBlock(width: 22, height: 22, radius: 8),
        ],
      ),
    );
  }
}

class _Shimmer extends StatefulWidget {
  final Widget child;

  const _Shimmer({required this.child});

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            final double width = bounds.width;
            final double offset = (width * 2 * _controller.value) - width;

            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: const [
                AppColors.surfaceMuted,
                AppColors.surface,
                AppColors.surfaceMuted,
              ],
              stops: const [0.2, 0.5, 0.8],
            ).createShader(
              Rect.fromLTWH(offset, 0, width, bounds.height),
            );
          },
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}

class _SkeletonBlock extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;

  const _SkeletonBlock({
    this.width,
    required this.height,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class _EntityDetails extends StatefulWidget {
  final EntityOut stats;
  final List<Entity> entities;
  final bool compact;

  const _EntityDetails({
    required this.stats,
    required this.entities,
    required this.compact,
  });

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
                      entity: widget.stats.entity,
                      entities: widget.entities,
                      episodes: widget.stats.episodes,
                      showAllEpisodes: _showAllEpisodes,
                      onShowAllEpisodesChanged: _setShowAllEpisodes,
                    ),
                  )
                : Expanded(
                    child: _EntityDetailsBody(
                      entity: widget.stats.entity,
                      entities: widget.entities,
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
  final Entity entity;
  final List<Entity> entities;
  final List<EpisodeOut> episodes;
  final bool showAllEpisodes;
  final ValueChanged<bool?> onShowAllEpisodesChanged;

  const _EntityDetailsBody({
    required this.entity,
    required this.entities,
    required this.episodes,
    required this.showAllEpisodes,
    required this.onShowAllEpisodesChanged,
  });

  @override
  Widget build(BuildContext context) {
    final _PrimaryOccurrenceSlots primaryOccurrenceSlots =
        _primaryOccurrenceSlotsFor(episodes);
    final _EpisodeSlotRange appearanceRange =
        primaryOccurrenceSlots.appearanceRange;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _EntityDetailsTabs(),
        const SizedBox(height: AppSpacing.md),
        Expanded(
          child: TabBarView(
            children: [
              _AppearanceMapTab(
                episodes: episodes,
                showAllEpisodes: showAllEpisodes,
                onShowAllEpisodesChanged: onShowAllEpisodesChanged,
                appearanceRange: appearanceRange,
                primaryOccurrenceSlots: primaryOccurrenceSlots,
              ),
              _TrophiesTab(
                entity: entity,
                entities: entities,
                episodes: episodes,
                primaryOccurrenceSlots: primaryOccurrenceSlots,
              ),
              _AnalysisTab(
                episodes: episodes,
                primaryOccurrenceSlots: primaryOccurrenceSlots,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EntityDetailsTabs extends StatelessWidget {
  const _EntityDetailsTabs();

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return TabBar(
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      labelColor: AppColors.ink,
      indicatorColor: AppColors.accent,
      dividerColor: AppColors.border,
      labelStyle: Theme.of(context).textTheme.labelLarge,
      tabs: [
        Tab(text: l10n.entitiesAppearanceMapTitle),
        Tab(text: l10n.entitiesTrophiesTabTitle),
        Tab(text: l10n.entitiesAnalysisTabTitle),
      ],
    );
  }
}

class _AppearanceMapTab extends StatelessWidget {
  final List<EpisodeOut> episodes;
  final bool showAllEpisodes;
  final ValueChanged<bool?> onShowAllEpisodesChanged;
  final _EpisodeSlotRange appearanceRange;
  final _PrimaryOccurrenceSlots primaryOccurrenceSlots;

  const _AppearanceMapTab({
    required this.episodes,
    required this.showAllEpisodes,
    required this.onShowAllEpisodesChanged,
    required this.appearanceRange,
    required this.primaryOccurrenceSlots,
  });

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
              primaryOccurrenceSlots: primaryOccurrenceSlots,
            ),
          ],
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
                constraints: const BoxConstraints(
                  maxWidth: 360,
                  maxHeight: 420,
                ),
                child: SingleChildScrollView(
                  child: _AppearanceLegend(
                    showAppearanceRange: showAppearanceRange,
                  ),
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
        _formLegendItem(
          _AppearanceTone.secondaryForm('alive'),
          l10n.entitiesAppearanceFormAliveLabel,
        ),
        _formLegendItem(
          _AppearanceTone.secondaryForm('corpse'),
          l10n.entitiesAppearanceFormCorpseLabel,
        ),
        _formLegendItem(
          _AppearanceTone.secondaryForm('zombified'),
          l10n.entitiesAppearanceFormZombifiedLabel,
        ),
        _formLegendItem(
          _AppearanceTone.secondaryForm('voiceOnly'),
          l10n.entitiesAppearanceFormVoiceOnlyLabel,
        ),
        _formLegendItem(
          _AppearanceTone.secondaryForm('physically'),
          l10n.entitiesAppearanceFormPhysicallyLabel,
        ),
        _formLegendItem(
          _AppearanceTone.secondaryForm('videoTape'),
          l10n.entitiesAppearanceFormVideoTapeLabel,
        ),
        _formLegendItem(
          _AppearanceTone.secondaryForm('flashback'),
          l10n.entitiesAppearanceFormFlashbackLabel,
        ),
        _formLegendItem(
          _AppearanceTone.secondaryForm('photograph'),
          l10n.entitiesAppearanceFormPhotographLabel,
        ),
        _formLegendItem(
          _AppearanceTone.secondaryForm('hallucination'),
          l10n.entitiesAppearanceFormHallucinationLabel,
        ),
        _formLegendItem(
          _AppearanceTone.secondaryForm('dream'),
          l10n.entitiesAppearanceFormDreamLabel,
        ),
        _formLegendItem(
          _AppearanceTone.secondaryForm('ultrasound'),
          l10n.entitiesAppearanceFormUltrasoundLabel,
        ),
        _LegendItem(
          color: AppColors.border,
          icon: Icons.circle_outlined,
          label: l10n.entitiesNoAppearanceLabel,
        ),
      ],
    );
  }

  Widget _formLegendItem(_AppearanceTone tone, String label) {
    return _LegendItem(
      color: tone.foreground,
      icon: tone.icon ?? Icons.circle_rounded,
      label: label,
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

class _TrophiesTab extends StatelessWidget {
  final Entity entity;
  final List<Entity> entities;
  final List<EpisodeOut> episodes;
  final _PrimaryOccurrenceSlots primaryOccurrenceSlots;

  const _TrophiesTab({
    required this.entity,
    required this.entities,
    required this.episodes,
    required this.primaryOccurrenceSlots,
  });

  @override
  Widget build(BuildContext context) {
    final _TrophyContext trophyContext = _TrophyContext(
      entity: entity,
      entities: entities,
      episodes: episodes,
      primaryOccurrenceSlots: primaryOccurrenceSlots,
    );
    final List<_TrophyDefinition> unlockedTrophies = _TrophyDefinition.all
        .where((definition) => definition.isUnlocked(trophyContext))
        .toList()
      ..sort((a, b) => b.tier.rank.compareTo(a.tier.rank));

    return Scrollbar(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final double width = constraints.maxWidth < 680
                    ? constraints.maxWidth
                    : (constraints.maxWidth - AppSpacing.md) / 2;

                return Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.md,
                  children: unlockedTrophies
                      .map(
                        (trophy) => SizedBox(
                          width: width,
                          child: _TrophyCard(definition: trophy),
                        ),
                      )
                      .toList(),
                );
              },
            ),
            if (unlockedTrophies.isNotEmpty)
              const SizedBox(height: AppSpacing.lg),
            _TrophySummary(
              unlocked: unlockedTrophies.length,
              total: _TrophyDefinition.all.length,
            ),
          ],
        ),
      ),
    );
  }
}

class _TrophySummary extends StatelessWidget {
  final int unlocked;
  final int total;

  const _TrophySummary({required this.unlocked, required this.total});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.accentSoft,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.emoji_events_rounded, color: AppColors.accent),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              '$unlocked/$total ${l10n.entitiesTrophiesUnlockedLabel}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrophyCard extends StatelessWidget {
  final _TrophyDefinition definition;

  const _TrophyCard({required this.definition});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final _TrophyTierStyle tierStyle = _TrophyTierStyle.from(definition.tier);

    return Container(
      constraints: const BoxConstraints(minHeight: 128),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: tierStyle.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tierStyle.color),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(definition.icon, size: 20, color: tierStyle.color),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        definition.title(l10n),
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _TrophyBadge(
                      label: definition.tier.label(l10n),
                      color: tierStyle.color,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  definition.description(l10n),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrophyBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _TrophyBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }
}

class _AnalysisTab extends StatelessWidget {
  final List<EpisodeOut> episodes;
  final _PrimaryOccurrenceSlots primaryOccurrenceSlots;

  const _AnalysisTab({
    required this.episodes,
    required this.primaryOccurrenceSlots,
  });

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final _AnalysisMetrics metrics = _AnalysisMetrics(
      episodes: episodes,
      primaryOccurrenceSlots: primaryOccurrenceSlots,
    );
    final List<String> notices = metrics.notices(l10n);

    return Scrollbar(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _AnalysisCoverageCard(metrics: metrics),
            const SizedBox(height: AppSpacing.md),
            _AnalysisStatsGrid(metrics: metrics),
            const SizedBox(height: AppSpacing.md),
            _AnalysisFormsPanel(metrics: metrics),
            if (notices.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              _AnalysisNoticesPanel(notices: notices),
            ],
          ],
        ),
      ),
    );
  }
}

class _AnalysisCoverageCard extends StatelessWidget {
  final _AnalysisMetrics metrics;

  const _AnalysisCoverageCard({required this.metrics});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final int percentage = (metrics.persistedEpisodeRatio * 100).round();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.accentSoft,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.insights_rounded,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  l10n.entitiesAnalysisCoverageTitle,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              Text(
                '$percentage%',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _AnalysisProgressBar(value: metrics.persistedEpisodeRatio),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${metrics.persistedEpisodeCount}/${metrics.totalEpisodeCount} '
            '${l10n.entitiesAnalysisCoverageValueLabel}',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _AnalysisProgressBar extends StatelessWidget {
  final double value;

  const _AnalysisProgressBar({required this.value});

  @override
  Widget build(BuildContext context) {
    final double normalizedValue = value < 0
        ? 0
        : value > 1
        ? 1
        : value;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          height: 8,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: constraints.maxWidth * normalizedValue,
              child: Container(color: AppColors.accent),
            ),
          ),
        );
      },
    );
  }
}

class _AnalysisStatsGrid extends StatelessWidget {
  final _AnalysisMetrics metrics;

  const _AnalysisStatsGrid({required this.metrics});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final List<_AnalysisMetric> metricItems = [
      _AnalysisMetric(
        icon: Icons.first_page_rounded,
        label: l10n.entitiesAnalysisFirstEverLabel,
        value: _episodeReference(metrics.firstEverEpisode, l10n),
      ),
      _AnalysisMetric(
        icon: Icons.last_page_rounded,
        label: l10n.entitiesAnalysisLastEverLabel,
        value: _episodeReference(metrics.lastEverEpisode, l10n),
      ),
      _AnalysisMetric(
        icon: Icons.play_arrow_rounded,
        label: l10n.entitiesAnalysisFirstPrimaryLabel,
        value: _episodeReference(metrics.firstPrimaryEpisode, l10n),
      ),
      _AnalysisMetric(
        icon: Icons.flag_rounded,
        label: l10n.entitiesAnalysisLastPrimaryLabel,
        value: _episodeReference(metrics.lastPrimaryEpisode, l10n),
      ),
      _AnalysisMetric(
        icon: Icons.route_rounded,
        label: l10n.entitiesAnalysisPrimarySpanLabel,
        value: metrics.primarySpanEpisodeCount == null
            ? l10n.entitiesAnalysisUnavailableValue
            : '${metrics.primarySpanEpisodeCount} '
                  '${l10n.entitiesAnalysisEpisodesValueLabel}',
      ),
      _AnalysisMetric(
        icon: Icons.calendar_view_month_rounded,
        label: l10n.entitiesAnalysisSeasonsLabel,
        value: metrics.continuitySeasonCount.toString(),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final int columns = constraints.maxWidth >= 900
            ? 3
            : constraints.maxWidth >= 560
            ? 2
            : 1;
        final double width =
            (constraints.maxWidth - (AppSpacing.md * (columns - 1))) /
            columns;

        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: metricItems
              .map(
                (metric) => SizedBox(
                  width: width,
                  child: _AnalysisMetricCard(metric: metric),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _AnalysisMetric {
  final IconData icon;
  final String label;
  final String value;

  const _AnalysisMetric({
    required this.icon,
    required this.label,
    required this.value,
  });
}

class _AnalysisMetricCard extends StatelessWidget {
  final _AnalysisMetric metric;

  const _AnalysisMetricCard({required this.metric});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 92),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(metric.icon, size: 18, color: AppColors.accent),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  metric.label,
                  style: Theme.of(
                    context,
                  ).textTheme.labelMedium?.copyWith(color: AppColors.muted),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  metric.value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalysisFormsPanel extends StatelessWidget {
  final _AnalysisMetrics metrics;

  const _AnalysisFormsPanel({required this.metrics});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return Container(
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
            l10n.entitiesAnalysisFormsTitle,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: _knownAppearanceForms.map((form) {
              return _AnalysisFormChip(
                active: metrics.hasAppearanceForm(form),
                label: _appearanceFormLabel(form, l10n) ?? form,
                tone: _AppearanceTone.secondaryForm(form),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _AnalysisFormChip extends StatelessWidget {
  final bool active;
  final String label;
  final _AppearanceTone tone;

  const _AnalysisFormChip({
    required this.active,
    required this.label,
    required this.tone,
  });

  @override
  Widget build(BuildContext context) {
    final Color foreground = active ? tone.foreground : AppColors.muted;
    final Color border = active ? tone.border : AppColors.border;
    final Color background = active ? tone.background : AppColors.surfaceMuted;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            active ? tone.icon ?? Icons.check_circle_rounded : Icons.circle_outlined,
            size: 16,
            color: foreground,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: foreground),
          ),
        ],
      ),
    );
  }
}

class _AnalysisNoticesPanel extends StatelessWidget {
  final List<String> notices;

  const _AnalysisNoticesPanel({required this.notices});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE3B341)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFF8A5A00),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                l10n.entitiesAnalysisNoticesTitle,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: const Color(0xFF8A5A00),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ...notices.map(
            (notice) => Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.circle_rounded,
                    size: 7,
                    color: Color(0xFF8A5A00),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      notice,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AppearanceMap extends StatelessWidget {
  final List<EpisodeOut> episodes;
  final bool showAllEpisodes;
  final _EpisodeSlotRange appearanceRange;
  final _PrimaryOccurrenceSlots primaryOccurrenceSlots;

  const _AppearanceMap({
    required this.episodes,
    required this.showAllEpisodes,
    required this.appearanceRange,
    required this.primaryOccurrenceSlots,
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
                  primaryOccurrenceSlots: primaryOccurrenceSlots,
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
  final _PrimaryOccurrenceSlots primaryOccurrenceSlots;

  const _SeasonAppearanceRow({
    required this.season,
    required this.episodeNumbers,
    required this.appearancesBySlot,
    required this.appearanceRange,
    required this.primaryOccurrenceSlots,
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
                    primaryOccurrenceSlots: primaryOccurrenceSlots,
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
  final _PrimaryOccurrenceSlots primaryOccurrenceSlots;

  const _EpisodeAppearanceCell({
    required this.season,
    required this.episodeNumber,
    required this.appearance,
    required this.inAppearanceRange,
    required this.primaryOccurrenceSlots,
  });

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final EpisodeOut? appearance = this.appearance;
    final _AppearanceTone tone = _AppearanceTone.from(
      appearance,
      inAppearanceRange: inAppearanceRange,
      primaryOccurrenceSlots: primaryOccurrenceSlots,
    );
    final _AppearanceMilestone? milestone = appearance == null
        ? null
        : _AppearanceMilestone.from(
            appearance,
            l10n,
            primaryOccurrenceSlots: primaryOccurrenceSlots,
          );

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
        milestone?.label ?? l10n.entitiesOtherAppearanceLabel;
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
    EpisodeOut? appearance, {
    required bool inAppearanceRange,
    required _PrimaryOccurrenceSlots primaryOccurrenceSlots,
  }) {
    if (appearance == null) {
      return inAppearanceRange
          ? _AppearanceTone.lifeRange()
          : const _AppearanceTone(
              background: AppColors.surface,
              border: AppColors.border,
              foreground: AppColors.muted,
            );
    }

    final String typeLabel = appearance.appearanceTypeLabel.trim().toLowerCase();

    if (primaryOccurrenceSlots.isInitial(appearance)) {
      return const _AppearanceTone(
        background: Color(0xFFE3F4E8),
        border: Color(0xFF2E7D32),
        foreground: Color(0xFF2E7D32),
        icon: Icons.play_arrow_rounded,
      );
    }

    if (primaryOccurrenceSlots.isFinal(appearance)) {
      return const _AppearanceTone(
        background: Color(0xFFFBE4E2),
        border: Color(0xFFC2413A),
        foreground: Color(0xFFC2413A),
        icon: Icons.flag_rounded,
      );
    }

    if (typeLabel == 'only') {
      return const _AppearanceTone(
        background: Color(0xFFE4EDFF),
        border: Color(0xFF2563EB),
        foreground: Color(0xFF2563EB),
        icon: Icons.looks_one_rounded,
      );
    }

    return _AppearanceTone.secondaryForm(appearance.appearanceFormTypeLabel);
  }

  factory _AppearanceTone.secondaryForm(String? value) {
    return switch (value?.trim().toLowerCase()) {
      'alive' => const _AppearanceTone(
        background: Color(0xFFE7F5E8),
        border: Color(0xFF2F7D3C),
        foreground: Color(0xFF1F6B2D),
        icon: Icons.favorite_rounded,
      ),
      'corpse' => const _AppearanceTone(
        background: Color(0xFFE7E5E4),
        border: Color(0xFF57534E),
        foreground: Color(0xFF44403C),
        icon: Icons.block_rounded,
      ),
      'zombified' => const _AppearanceTone(
        background: Color(0xFFDDEDE4),
        border: Color(0xFF17633A),
        foreground: Color(0xFF0F4C2F),
        icon: Icons.sync_rounded,
      ),
      'voiceonly' => const _AppearanceTone(
        background: Color(0xFFF1E8FF),
        border: Color(0xFF7C3AED),
        foreground: Color(0xFF6D28D9),
        icon: Icons.record_voice_over_rounded,
      ),
      'physically' => const _AppearanceTone(
        background: Color(0xFFE8EEF6),
        border: Color(0xFF475569),
        foreground: Color(0xFF334155),
        icon: Icons.person_rounded,
      ),
      'videotape' => const _AppearanceTone(
        background: Color(0xFFFFF0CC),
        border: Color(0xFFD97706),
        foreground: Color(0xFFB45309),
        icon: Icons.videocam_rounded,
      ),
      'flashback' => const _AppearanceTone(
        background: Color(0xFFDFF7F3),
        border: Color(0xFF0F766E),
        foreground: Color(0xFF0F766E),
        icon: Icons.history_rounded,
      ),
      'photograph' => const _AppearanceTone(
        background: Color(0xFFE0F2FE),
        border: Color(0xFF0284C7),
        foreground: Color(0xFF0369A1),
        icon: Icons.photo_camera_rounded,
      ),
      'hallucination' => const _AppearanceTone(
        background: Color(0xFFFCE7F3),
        border: Color(0xFFDB2777),
        foreground: Color(0xFFBE185D),
        icon: Icons.blur_on_rounded,
      ),
      'dream' => const _AppearanceTone(
        background: Color(0xFFEDE9FE),
        border: Color(0xFF6D28D9),
        foreground: Color(0xFF5B21B6),
        icon: Icons.nights_stay_rounded,
      ),
      'ultrasound' => const _AppearanceTone(
        background: Color(0xFFFFE4E6),
        border: Color(0xFFE11D48),
        foreground: Color(0xFFBE123C),
        icon: Icons.graphic_eq_rounded,
      ),
      'only' => const _AppearanceTone(
        background: Color(0xFFE4EDFF),
        border: Color(0xFF2563EB),
        foreground: Color(0xFF2563EB),
        icon: Icons.looks_one_rounded,
      ),
      _ => const _AppearanceTone(
        background: AppColors.surfaceMuted,
        border: AppColors.border,
        foreground: AppColors.ink,
        icon: Icons.circle_rounded,
      ),
    };
  }

  factory _AppearanceTone.lifeRange() {
    return const _AppearanceTone(
      background: Color(0xFFFFF4D6),
      border: Color(0xFFE3B341),
      foreground: Color(0xFF8A5A00),
    );
  }
}

class _AppearanceMilestone {
  final String label;

  const _AppearanceMilestone({required this.label});

  static _AppearanceMilestone? from(
    EpisodeOut appearance,
    AppLocalizations l10n, {
    required _PrimaryOccurrenceSlots primaryOccurrenceSlots,
  }) {
    if (primaryOccurrenceSlots.isInitial(appearance)) {
      return _AppearanceMilestone(label: l10n.entitiesFirstAppearanceLabel);
    }
    if (primaryOccurrenceSlots.isFinal(appearance)) {
      return _AppearanceMilestone(label: l10n.entitiesLastAppearanceLabel);
    }

    if (appearance.appearanceTypeLabel.trim().toLowerCase() == 'only') {
      return _AppearanceMilestone(label: l10n.entitiesOnlyAppearanceLabel);
    }

    return null;
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

enum _TrophyTier {
  bronze,
  silver,
  gold,
  legendary;

  int get rank {
    return switch (this) {
      _TrophyTier.bronze => 1,
      _TrophyTier.silver => 2,
      _TrophyTier.gold => 3,
      _TrophyTier.legendary => 4,
    };
  }

  String label(AppLocalizations l10n) {
    return switch (this) {
      _TrophyTier.bronze => l10n.entitiesTrophyTierBronzeLabel,
      _TrophyTier.silver => l10n.entitiesTrophyTierSilverLabel,
      _TrophyTier.gold => l10n.entitiesTrophyTierGoldLabel,
      _TrophyTier.legendary => l10n.entitiesTrophyTierLegendaryLabel,
    };
  }
}

enum _TrophyId {
  singleEpisode,
  sharedExactName,
  onlyZombified,
  onlyCorpse,
  onlyPhotograph,
  onlyFlashback,
  voiceIntroBeforePrimary,
  hasUltrasound,
  persistedOneSeason,
  hasDream,
  hasHallucination,
  introducedAtSeasonPremiere,
  endedAtSeasonFinale,
  consecutivePrimaryJourney,
  postJourneyFlashback,
  postJourneyZombified,
  persistedAllSeasons,
  persistedEveryEpisode,
  appearedInPilot,
  appearedInFinale,
  allAppearanceForms,
}

class _TrophyDefinition {
  final _TrophyId id;
  final _TrophyTier tier;
  final IconData icon;

  const _TrophyDefinition({
    required this.id,
    required this.tier,
    required this.icon,
  });

  static const List<_TrophyDefinition> all = [
    _TrophyDefinition(
      id: _TrophyId.singleEpisode,
      tier: _TrophyTier.bronze,
      icon: Icons.looks_one_rounded,
    ),
    _TrophyDefinition(
      id: _TrophyId.sharedExactName,
      tier: _TrophyTier.bronze,
      icon: Icons.badge_rounded,
    ),
    _TrophyDefinition(
      id: _TrophyId.onlyFlashback,
      tier: _TrophyTier.bronze,
      icon: Icons.history_rounded,
    ),
    _TrophyDefinition(
      id: _TrophyId.onlyPhotograph,
      tier: _TrophyTier.bronze,
      icon: Icons.photo_camera_rounded,
    ),
    _TrophyDefinition(
      id: _TrophyId.onlyCorpse,
      tier: _TrophyTier.silver,
      icon: Icons.block_rounded,
    ),
    _TrophyDefinition(
      id: _TrophyId.hasDream,
      tier: _TrophyTier.silver,
      icon: Icons.nights_stay_rounded,
    ),
    _TrophyDefinition(
      id: _TrophyId.hasHallucination,
      tier: _TrophyTier.silver,
      icon: Icons.blur_on_rounded,
    ),
    _TrophyDefinition(
      id: _TrophyId.hasUltrasound,
      tier: _TrophyTier.silver,
      icon: Icons.graphic_eq_rounded,
    ),
    _TrophyDefinition(
      id: _TrophyId.onlyZombified,
      tier: _TrophyTier.silver,
      icon: Icons.sync_rounded,
    ),
    _TrophyDefinition(
      id: _TrophyId.appearedInPilot,
      tier: _TrophyTier.silver,
      icon: Icons.flag_circle_rounded,
    ),
    _TrophyDefinition(
      id: _TrophyId.voiceIntroBeforePrimary,
      tier: _TrophyTier.silver,
      icon: Icons.record_voice_over_rounded,
    ),
    _TrophyDefinition(
      id: _TrophyId.introducedAtSeasonPremiere,
      tier: _TrophyTier.silver,
      icon: Icons.first_page_rounded,
    ),
    _TrophyDefinition(
      id: _TrophyId.persistedOneSeason,
      tier: _TrophyTier.gold,
      icon: Icons.calendar_view_month_rounded,
    ),
    _TrophyDefinition(
      id: _TrophyId.appearedInFinale,
      tier: _TrophyTier.gold,
      icon: Icons.outlined_flag_rounded,
    ),
    _TrophyDefinition(
      id: _TrophyId.endedAtSeasonFinale,
      tier: _TrophyTier.gold,
      icon: Icons.sports_score_rounded,
    ),
    _TrophyDefinition(
      id: _TrophyId.consecutivePrimaryJourney,
      tier: _TrophyTier.gold,
      icon: Icons.skip_next_rounded,
    ),
    _TrophyDefinition(
      id: _TrophyId.postJourneyFlashback,
      tier: _TrophyTier.gold,
      icon: Icons.replay_rounded,
    ),
    _TrophyDefinition(
      id: _TrophyId.postJourneyZombified,
      tier: _TrophyTier.gold,
      icon: Icons.sync_rounded,
    ),
    _TrophyDefinition(
      id: _TrophyId.persistedAllSeasons,
      tier: _TrophyTier.gold,
      icon: Icons.view_timeline_rounded,
    ),
    _TrophyDefinition(
      id: _TrophyId.persistedEveryEpisode,
      tier: _TrophyTier.legendary,
      icon: Icons.all_inclusive_rounded,
    ),
    _TrophyDefinition(
      id: _TrophyId.allAppearanceForms,
      tier: _TrophyTier.legendary,
      icon: Icons.auto_awesome_rounded,
    ),
  ];

  bool isUnlocked(_TrophyContext context) {
    return switch (id) {
      _TrophyId.singleEpisode => context.uniqueAppearanceEpisodeCount == 1,
      _TrophyId.sharedExactName => context.hasSharedExactName,
      _TrophyId.onlyZombified => context.onlyAppearedAs('zombified'),
      _TrophyId.onlyCorpse => context.onlyAppearedAs('corpse'),
      _TrophyId.onlyPhotograph => context.onlyAppearedAs('photograph'),
      _TrophyId.onlyFlashback => context.onlyAppearedAs('flashback'),
      _TrophyId.voiceIntroBeforePrimary =>
        context.introducedByVoiceBeforePrimary,
      _TrophyId.hasUltrasound => context.hasAppearanceForm('ultrasound'),
      _TrophyId.persistedOneSeason => context.persistedFullSeason,
      _TrophyId.hasDream => context.hasAppearanceForm('dream'),
      _TrophyId.hasHallucination => context.hasAppearanceForm('hallucination'),
      _TrophyId.introducedAtSeasonPremiere =>
        context.primaryStartedAtSeasonPremiere,
      _TrophyId.endedAtSeasonFinale => context.primaryEndedAtSeasonFinale,
      _TrophyId.consecutivePrimaryJourney =>
        context.consecutivePrimaryJourney,
      _TrophyId.postJourneyFlashback =>
        context.hasPostPrimaryAppearanceForm('flashback'),
      _TrophyId.postJourneyZombified =>
        context.hasPostPrimaryAppearanceForm('zombified'),
      _TrophyId.persistedAllSeasons => context.persistedAllSeasons,
      _TrophyId.persistedEveryEpisode => context.persistedEveryEpisode,
      _TrophyId.appearedInPilot => context.hasAppearanceAt(1, 1),
      _TrophyId.appearedInFinale => context.hasAppearanceAt(
        _availableSeasons.last,
        _episodeCountsBySeason[_availableSeasons.last]!,
      ),
      _TrophyId.allAppearanceForms => context.hasAllKnownAppearanceForms,
    };
  }

  String title(AppLocalizations l10n) {
    return switch (id) {
      _TrophyId.singleEpisode => l10n.entitiesTrophySingleEpisodeTitle,
      _TrophyId.sharedExactName => l10n.entitiesTrophySharedExactNameTitle,
      _TrophyId.onlyZombified => l10n.entitiesTrophyOnlyZombifiedTitle,
      _TrophyId.onlyCorpse => l10n.entitiesTrophyOnlyCorpseTitle,
      _TrophyId.onlyPhotograph => l10n.entitiesTrophyOnlyPhotographTitle,
      _TrophyId.onlyFlashback => l10n.entitiesTrophyOnlyFlashbackTitle,
      _TrophyId.voiceIntroBeforePrimary =>
        l10n.entitiesTrophyVoiceIntroBeforePrimaryTitle,
      _TrophyId.hasUltrasound => l10n.entitiesTrophyHasUltrasoundTitle,
      _TrophyId.persistedOneSeason =>
        l10n.entitiesTrophyPersistedOneSeasonTitle,
      _TrophyId.hasDream => l10n.entitiesTrophyHasDreamTitle,
      _TrophyId.hasHallucination =>
        l10n.entitiesTrophyHasHallucinationTitle,
      _TrophyId.introducedAtSeasonPremiere =>
        l10n.entitiesTrophyIntroducedAtSeasonPremiereTitle,
      _TrophyId.endedAtSeasonFinale =>
        l10n.entitiesTrophyEndedAtSeasonFinaleTitle,
      _TrophyId.consecutivePrimaryJourney =>
        l10n.entitiesTrophyConsecutivePrimaryJourneyTitle,
      _TrophyId.postJourneyFlashback =>
        l10n.entitiesTrophyPostJourneyFlashbackTitle,
      _TrophyId.postJourneyZombified =>
        l10n.entitiesTrophyPostJourneyZombifiedTitle,
      _TrophyId.persistedAllSeasons =>
        l10n.entitiesTrophyPersistedAllSeasonsTitle,
      _TrophyId.persistedEveryEpisode =>
        l10n.entitiesTrophyPersistedEveryEpisodeTitle,
      _TrophyId.appearedInPilot => l10n.entitiesTrophyAppearedInPilotTitle,
      _TrophyId.appearedInFinale => l10n.entitiesTrophyAppearedInFinaleTitle,
      _TrophyId.allAppearanceForms =>
        l10n.entitiesTrophyAllAppearanceFormsTitle,
    };
  }

  String description(AppLocalizations l10n) {
    return switch (id) {
      _TrophyId.singleEpisode => l10n.entitiesTrophySingleEpisodeDescription,
      _TrophyId.sharedExactName =>
        l10n.entitiesTrophySharedExactNameDescription,
      _TrophyId.onlyZombified =>
        l10n.entitiesTrophyOnlyZombifiedDescription,
      _TrophyId.onlyCorpse => l10n.entitiesTrophyOnlyCorpseDescription,
      _TrophyId.onlyPhotograph =>
        l10n.entitiesTrophyOnlyPhotographDescription,
      _TrophyId.onlyFlashback =>
        l10n.entitiesTrophyOnlyFlashbackDescription,
      _TrophyId.voiceIntroBeforePrimary =>
        l10n.entitiesTrophyVoiceIntroBeforePrimaryDescription,
      _TrophyId.hasUltrasound =>
        l10n.entitiesTrophyHasUltrasoundDescription,
      _TrophyId.persistedOneSeason =>
        l10n.entitiesTrophyPersistedOneSeasonDescription,
      _TrophyId.hasDream => l10n.entitiesTrophyHasDreamDescription,
      _TrophyId.hasHallucination =>
        l10n.entitiesTrophyHasHallucinationDescription,
      _TrophyId.introducedAtSeasonPremiere =>
        l10n.entitiesTrophyIntroducedAtSeasonPremiereDescription,
      _TrophyId.endedAtSeasonFinale =>
        l10n.entitiesTrophyEndedAtSeasonFinaleDescription,
      _TrophyId.consecutivePrimaryJourney =>
        l10n.entitiesTrophyConsecutivePrimaryJourneyDescription,
      _TrophyId.postJourneyFlashback =>
        l10n.entitiesTrophyPostJourneyFlashbackDescription,
      _TrophyId.postJourneyZombified =>
        l10n.entitiesTrophyPostJourneyZombifiedDescription,
      _TrophyId.persistedAllSeasons =>
        l10n.entitiesTrophyPersistedAllSeasonsDescription,
      _TrophyId.persistedEveryEpisode =>
        l10n.entitiesTrophyPersistedEveryEpisodeDescription,
      _TrophyId.appearedInPilot =>
        l10n.entitiesTrophyAppearedInPilotDescription,
      _TrophyId.appearedInFinale =>
        l10n.entitiesTrophyAppearedInFinaleDescription,
      _TrophyId.allAppearanceForms =>
        l10n.entitiesTrophyAllAppearanceFormsDescription,
    };
  }
}

class _TrophyTierStyle {
  final Color color;
  final Color background;

  const _TrophyTierStyle({required this.color, required this.background});

  factory _TrophyTierStyle.from(_TrophyTier tier) {
    return switch (tier) {
      _TrophyTier.bronze => const _TrophyTierStyle(
        color: Color(0xFF9A5A22),
        background: Color(0xFFFFF1E4),
      ),
      _TrophyTier.silver => const _TrophyTierStyle(
        color: Color(0xFF64748B),
        background: Color(0xFFF1F5F9),
      ),
      _TrophyTier.gold => const _TrophyTierStyle(
        color: Color(0xFFB7791F),
        background: Color(0xFFFFF4D6),
      ),
      _TrophyTier.legendary => const _TrophyTierStyle(
        color: Color(0xFF7C3AED),
        background: Color(0xFFF1E8FF),
      ),
    };
  }
}

class _AnalysisMetrics {
  final List<EpisodeOut> episodes;
  final _PrimaryOccurrenceSlots primaryOccurrenceSlots;

  _AnalysisMetrics({
    required this.episodes,
    required this.primaryOccurrenceSlots,
  });

  late final List<EpisodeOut> sortedEpisodes = episodes.toList()
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

  late final Set<String> appearanceEpisodeKeys = {
    for (final EpisodeOut appearance in episodes)
      _episodeKeyForAppearance(appearance),
  };

  late final Set<String> continuityEpisodeKeys = _continuityEpisodeKeysFor(
    episodes,
    primaryOccurrenceSlots,
  );

  late final Set<String> appearanceForms = {
    for (final EpisodeOut appearance in episodes)
      if (_normalizedAppearanceForm(appearance) != null)
        _normalizedAppearanceForm(appearance)!,
  };

  int get totalEpisodeCount {
    return {..._allKnownEpisodeKeys, ...appearanceEpisodeKeys}.length;
  }

  int get persistedEpisodeCount => continuityEpisodeKeys.length;

  double get persistedEpisodeRatio {
    if (totalEpisodeCount == 0) {
      return 0;
    }

    final double ratio = persistedEpisodeCount / totalEpisodeCount;
    return ratio > 1 ? 1 : ratio;
  }

  Episode? get firstEverEpisode {
    return sortedEpisodes.isEmpty ? null : sortedEpisodes.first.episode;
  }

  Episode? get lastEverEpisode {
    return sortedEpisodes.isEmpty ? null : sortedEpisodes.last.episode;
  }

  Episode? get firstPrimaryEpisode => _primaryInitialOccurrence?.episode;

  Episode? get lastPrimaryEpisode => _primaryFinalOccurrence?.episode;

  int? get primarySpanEpisodeCount {
    final int? initialIndex = primaryOccurrenceSlots.initialIndex;
    final int? finalIndex = primaryOccurrenceSlots.finalIndex;
    if (initialIndex == null || finalIndex == null || finalIndex < initialIndex) {
      return null;
    }

    return finalIndex - initialIndex + 1;
  }

  int get continuitySeasonCount {
    final Set<int> seasons = {
      for (final EpisodeOut appearance in episodes) appearance.episode.seasonNumber,
    };

    for (final int season in _availableSeasons) {
      final int episodeCount = _episodeCountsBySeason[season] ?? 0;
      for (int episode = 1; episode <= episodeCount; episode++) {
        if (continuityEpisodeKeys.contains(_episodeKey(season, episode))) {
          seasons.add(season);
          break;
        }
      }
    }

    return seasons.length;
  }

  bool hasAppearanceForm(String formType) {
    return appearanceForms.contains(formType);
  }

  List<String> notices(AppLocalizations l10n) {
    final List<String> result = [];
    if (episodes.isEmpty) {
      result.add(l10n.entitiesAnalysisNoticeNoAppearances);
    }

    if (primaryOccurrenceSlots.initialKey != null &&
        primaryOccurrenceSlots.finalKey == null) {
      result.add(l10n.entitiesAnalysisNoticeInitialWithoutFinal);
    }

    if (primaryOccurrenceSlots.initialKey == null && _lastMarkerCount > 0) {
      result.add(l10n.entitiesAnalysisNoticeFinalWithoutInitial);
    }

    if (_firstMarkerCount > 1) {
      result.add(l10n.entitiesAnalysisNoticeMultipleFirst);
    }

    if (_lastMarkerCount > 1) {
      result.add(l10n.entitiesAnalysisNoticeMultipleLast);
    }

    return result;
  }

  int get _firstMarkerCount {
    return episodes.where((appearance) {
      return appearance.appearanceTypeLabel.trim().toLowerCase() == 'first';
    }).length;
  }

  int get _lastMarkerCount {
    return episodes.where(_isFinalPrimaryOccurrence).length;
  }

  EpisodeOut? get _primaryInitialOccurrence {
    for (final EpisodeOut appearance in episodes) {
      if (primaryOccurrenceSlots.isInitial(appearance)) {
        return appearance;
      }
    }

    return null;
  }

  EpisodeOut? get _primaryFinalOccurrence {
    for (final EpisodeOut appearance in episodes) {
      if (primaryOccurrenceSlots.isFinal(appearance)) {
        return appearance;
      }
    }

    return null;
  }
}

class _TrophyContext {
  final Entity entity;
  final List<Entity> entities;
  final List<EpisodeOut> episodes;
  final _PrimaryOccurrenceSlots primaryOccurrenceSlots;

  _TrophyContext({
    required this.entity,
    required this.entities,
    required this.episodes,
    required this.primaryOccurrenceSlots,
  });

  late final Set<String> appearanceEpisodeKeys = {
    for (final EpisodeOut appearance in episodes)
      _episodeKeyForAppearance(appearance),
  };

  late final Set<String> continuityEpisodeKeys = _continuityEpisodeKeysFor(
    episodes,
    primaryOccurrenceSlots,
  );

  late final List<EpisodeOut> sortedEpisodes = episodes.toList()
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

  int get uniqueAppearanceEpisodeCount => appearanceEpisodeKeys.length;

  bool get hasSharedExactName {
    return entities.any(
      (other) => other.id != entity.id && other.name == entity.name,
    );
  }

  bool get introducedByVoiceBeforePrimary {
    final int? initialIndex = primaryOccurrenceSlots.initialIndex;
    if (initialIndex == null || sortedEpisodes.isEmpty) {
      return false;
    }

    final EpisodeOut firstAppearance = sortedEpisodes.first;
    final int firstIndex = _episodeAbsoluteIndex(
      firstAppearance.episode.seasonNumber,
      firstAppearance.episode.episodeNumber,
    );

    return firstIndex < initialIndex &&
        _normalizedAppearanceForm(firstAppearance) == 'voiceonly';
  }

  bool get primaryStartedAtSeasonPremiere {
    return _primaryInitialOccurrence?.episode.episodeNumber == 1;
  }

  bool get primaryEndedAtSeasonFinale {
    final EpisodeOut? finalOccurrence = _primaryFinalOccurrence;
    if (finalOccurrence == null) {
      return false;
    }

    final Episode episode = finalOccurrence.episode;
    return episode.episodeNumber == _episodeCountsBySeason[episode.seasonNumber];
  }

  bool get consecutivePrimaryJourney {
    final int? initialIndex = primaryOccurrenceSlots.initialIndex;
    final int? finalIndex = primaryOccurrenceSlots.finalIndex;
    return initialIndex != null &&
        finalIndex != null &&
        finalIndex == initialIndex + 1;
  }

  bool get hasAllKnownAppearanceForms {
    final Set<String> forms = {};
    for (final EpisodeOut appearance in episodes) {
      final String? form = _normalizedAppearanceForm(appearance);
      if (form != null) {
        forms.add(form);
      }
    }

    return _knownAppearanceForms.every(forms.contains);
  }

  bool get persistedFullSeason {
    return _availableSeasons.any((season) {
      final int episodeCount = _episodeCountsBySeason[season] ?? 0;
      if (episodeCount == 0) {
        return false;
      }

      return List<int>.generate(
        episodeCount,
        (index) => index + 1,
      ).every((episode) {
        return continuityEpisodeKeys.contains(_episodeKey(season, episode));
      });
    });
  }

  bool get persistedAllSeasons {
    return _availableSeasons.every((season) {
      final int episodeCount = _episodeCountsBySeason[season] ?? 0;
      return List<int>.generate(
        episodeCount,
        (index) => index + 1,
      ).any((episode) {
        return continuityEpisodeKeys.contains(_episodeKey(season, episode));
      });
    });
  }

  bool get persistedEveryEpisode {
    return _allKnownEpisodeKeys.every(continuityEpisodeKeys.contains);
  }

  bool hasAppearanceAt(int season, int episode) {
    return appearanceEpisodeKeys.contains(_episodeKey(season, episode));
  }

  bool hasAppearanceForm(String formType) {
    return episodes.any((appearance) {
      return _normalizedAppearanceForm(appearance) == formType;
    });
  }

  bool onlyAppearedAs(String formType) {
    return episodes.isNotEmpty && episodes.every((appearance) {
      return _normalizedAppearanceForm(appearance) == formType;
    });
  }

  bool hasPostPrimaryAppearanceForm(String formType) {
    final int? finalIndex = primaryOccurrenceSlots.finalIndex;
    if (finalIndex == null) {
      return false;
    }

    return episodes.any((appearance) {
      final int index = _episodeAbsoluteIndex(
        appearance.episode.seasonNumber,
        appearance.episode.episodeNumber,
      );
      return index > finalIndex &&
          _normalizedAppearanceForm(appearance) == formType;
    });
  }

  EpisodeOut? get _primaryInitialOccurrence {
    for (final EpisodeOut appearance in episodes) {
      if (primaryOccurrenceSlots.isInitial(appearance)) {
        return appearance;
      }
    }

    return null;
  }

  EpisodeOut? get _primaryFinalOccurrence {
    for (final EpisodeOut appearance in episodes) {
      if (primaryOccurrenceSlots.isFinal(appearance)) {
        return appearance;
      }
    }

    return null;
  }

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

class _PrimaryOccurrenceSlots {
  final String? initialKey;
  final String? finalKey;
  final int? initialIndex;
  final int? finalIndex;
  final _EpisodeSlotRange appearanceRange;

  const _PrimaryOccurrenceSlots({
    required this.initialKey,
    required this.finalKey,
    required this.initialIndex,
    required this.finalIndex,
    required this.appearanceRange,
  });

  bool get hasInitial => initialKey != null;

  bool isInitial(EpisodeOut appearance) {
    return initialKey == _episodeKeyForAppearance(appearance);
  }

  bool isFinal(EpisodeOut appearance) {
    return finalKey == _episodeKeyForAppearance(appearance);
  }
}

_PrimaryOccurrenceSlots _primaryOccurrenceSlotsFor(List<EpisodeOut> episodes) {
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

  EpisodeOut? initialOccurrence;
  for (final EpisodeOut appearance in sorted) {
    if (_isInitialPrimaryOccurrence(appearance)) {
      initialOccurrence = appearance;
      break;
    }
  }

  if (initialOccurrence == null) {
    return _PrimaryOccurrenceSlots(
      initialKey: null,
      finalKey: null,
      initialIndex: null,
      finalIndex: null,
      appearanceRange: _EpisodeSlotRange.empty(),
    );
  }

  final int initialIndex = _episodeAbsoluteIndex(
    initialOccurrence.episode.seasonNumber,
    initialOccurrence.episode.episodeNumber,
  );

  EpisodeOut? finalOccurrence;
  for (final EpisodeOut appearance in sorted) {
    final int index = _episodeAbsoluteIndex(
      appearance.episode.seasonNumber,
      appearance.episode.episodeNumber,
    );
    if (index > initialIndex && _isFinalPrimaryOccurrence(appearance)) {
      finalOccurrence = appearance;
      break;
    }
  }

  final int? finalIndex = finalOccurrence == null
      ? null
      : _episodeAbsoluteIndex(
          finalOccurrence.episode.seasonNumber,
          finalOccurrence.episode.episodeNumber,
        );

  final _EpisodeSlotRange appearanceRange =
      finalIndex != null && finalIndex > initialIndex
      ? _EpisodeSlotRange(start: initialIndex, end: finalIndex)
      : _EpisodeSlotRange.empty();

  return _PrimaryOccurrenceSlots(
    initialKey: _episodeKeyForAppearance(initialOccurrence),
    finalKey: finalOccurrence == null
        ? null
        : _episodeKeyForAppearance(finalOccurrence),
    initialIndex: initialIndex,
    finalIndex: finalIndex,
    appearanceRange: appearanceRange,
  );
}

bool _isInitialPrimaryOccurrence(EpisodeOut appearance) {
  final bool isFirst =
      appearance.appearanceTypeLabel.trim().toLowerCase() == 'first';
  final String? formType = appearance.appearanceFormTypeLabel
      ?.trim()
      .toLowerCase();

  return isFirst && (formType == null || formType == 'physically');
}

bool _isFinalPrimaryOccurrence(EpisodeOut appearance) {
  return appearance.appearanceTypeLabel.trim().toLowerCase() == 'last';
}

String? _normalizedAppearanceForm(EpisodeOut appearance) {
  return appearance.appearanceFormTypeLabel?.trim().toLowerCase();
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

List<String> get _allKnownEpisodeKeys {
  return [
    for (final int season in _availableSeasons)
      for (int episode = 1;
          episode <= (_episodeCountsBySeason[season] ?? 0);
          episode++)
        _episodeKey(season, episode),
  ];
}

Set<String> _continuityEpisodeKeysFor(
  List<EpisodeOut> episodes,
  _PrimaryOccurrenceSlots primaryOccurrenceSlots,
) {
  final Set<String> keys = {
    for (final EpisodeOut appearance in episodes)
      _episodeKeyForAppearance(appearance),
  };
  final _EpisodeSlotRange range = primaryOccurrenceSlots.appearanceRange;
  if (!range.isValid) {
    return keys;
  }

  for (final int season in _availableSeasons) {
    final int episodeCount = _episodeCountsBySeason[season] ?? 0;
    for (int episode = 1; episode <= episodeCount; episode++) {
      if (range.contains(season, episode)) {
        keys.add(_episodeKey(season, episode));
      }
    }
  }

  return keys;
}

String _episodeReference(Episode? episode, AppLocalizations l10n) {
  if (episode == null) {
    return l10n.entitiesAnalysisUnavailableValue;
  }

  return '${l10n.entitiesSeasonShortLabel}${episode.seasonNumber} '
      '${l10n.entitiesEpisodeShortLabel}${episode.episodeNumber}';
}

String _episodeKey(int season, int episode) => '$season:$episode';

String _episodeKeyForAppearance(EpisodeOut appearance) {
  return _episodeKey(
    appearance.episode.seasonNumber,
    appearance.episode.episodeNumber,
  );
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
