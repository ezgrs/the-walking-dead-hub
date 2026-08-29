import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:responsive_framework/responsive_framework.dart' as rf;
import 'package:timelines_plus/timelines_plus.dart';
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

class EntitiesScreen extends StatelessWidget {
  final EntitiesBloc bloc;

  const EntitiesScreen({super.key, required this.bloc});

  Widget _buildIndicesLoadSuccessState(
    BuildContext context,
    IndicesLoadSuccessBase state, {
    required bool compact,
  }) {
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
            IndicesInitial() => const _EmptyState(
              icon: Icons.touch_app_rounded,
              title: 'Escolha um indice',
              message: 'Selecione uma letra acima para listar os registros.',
            ),
            EntitiesLoadInProgress() => const _LoadingState(
              label: 'Carregando registros...',
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
      EntitiesInitial() => const _EmptyState(
        icon: Icons.badge_rounded,
        title: 'Selecione um registro',
        message: 'Toque em um personagem ou local para ver aparicoes e links.',
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
                          IndicesLoadInProgress() => const _LoadingState(
                            label: 'Carregando indices...',
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

class _EntityList extends StatelessWidget {
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
  Widget build(BuildContext context) {
    if (entities.isEmpty) {
      return const _EmptyState(
        icon: Icons.search_off_rounded,
        title: 'Nenhum resultado',
        message: 'Tente selecionar outro indice.',
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
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      entity.wikiHref,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
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

class _EntityDetails extends StatelessWidget {
  final EntityOut stats;
  final bool compact;

  const _EntityDetails({required this.stats, required this.compact});

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
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stats.entity.name,
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        stats.entity.wikiHref,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Tooltip(
                  message: 'Abrir no Fandom',
                  child: IconButton.outlined(
                    onPressed: () async {
                      await launchUrl(
                        Uri(
                          scheme: 'https',
                          host: 'walkingdead.fandom.com',
                          path: stats.entity.wikiHref,
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
            Text('Timeline', style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: AppSpacing.sm),
            compact
                ? SizedBox(
                    height: 520,
                    child: _EpisodeTimeline(episodes: stats.episodes),
                  )
                : Expanded(child: _EpisodeTimeline(episodes: stats.episodes)),
          ],
        ),
      ),
    );
  }
}

class _EpisodeTimeline extends StatelessWidget {
  final List<EpisodeOut> episodes;

  const _EpisodeTimeline({required this.episodes});

  @override
  Widget build(BuildContext context) {
    if (episodes.isEmpty) {
      return const _EmptyState(
        icon: Icons.timeline_rounded,
        title: 'Sem aparicoes',
        message: 'Ainda nao ha episodios cadastrados para este registro.',
      );
    }

    return Timeline.tileBuilder(
      theme: TimelineThemeData(
        nodePosition: 0,
        connectorTheme: const ConnectorThemeData(
          thickness: 2,
          color: AppColors.border,
        ),
        indicatorTheme: const IndicatorThemeData(size: 14),
      ),
      builder: TimelineTileBuilder.connected(
        itemCount: episodes.length,
        connectionDirection: ConnectionDirection.before,
        contentsBuilder: (context, index) {
          final EpisodeOut appearance = episodes[index];
          final Episode episode = appearance.episode;
          final bool isNewSeason =
              index == 0 ||
              episode.seasonNumber != episodes[index - 1].episode.seasonNumber;
          final String meta = [
            appearance.appearanceTypeLabel,
            if (appearance.appearanceFormTypeLabel != null)
              appearance.appearanceFormTypeLabel!,
          ].join(' - ');

          return Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.xs,
              0,
              AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isNewSeason) ...[
                  Text(
                    'Season ${episode.seasonNumber}',
                    style: Theme.of(
                      context,
                    ).textTheme.labelLarge?.copyWith(color: AppColors.accent),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                ],
                Text(
                  'E${episode.episodeNumber}: ${episode.name}',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(meta, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          );
        },
        indicatorBuilder: (context, index) {
          final Episode episode = episodes[index].episode;
          final bool isSeasonStart =
              index == 0 ||
              episode.seasonNumber != episodes[index - 1].episode.seasonNumber;

          return DotIndicator(
            color: isSeasonStart ? AppColors.accent : AppColors.border,
          );
        },
        connectorBuilder: (_, index, type) => const SolidLineConnector(),
      ),
    );
  }
}

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
