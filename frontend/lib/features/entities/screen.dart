import 'package:dartx/dartx.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:responsive_framework/responsive_framework.dart' as rf;
import 'package:timelines_plus/timelines_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'bloc_event.dart';
import 'bloc_state.dart';
import '../../l10n/app_localizations.dart';
import '../../models.dart';
import '../../main.dart';
import '../../widgets/button.dart';
import '../../widgets/header.dart';
import '../../widgets/maybe.dart';
import 'bloc.dart';

class _EntityCard extends StatelessWidget {
  final EntitiesBloc bloc;
  final Entity entity;

  const _EntityCard({required this.entity, required this.bloc});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => bloc.add(EpisodesLoadRequested(entityId: entity.id)),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                entity.name,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                entity.wikiHref,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EntitiesScreen extends StatelessWidget {
  final EntitiesBloc bloc;

  const EntitiesScreen({super.key, required this.bloc});

  Widget _buildIndicesLoadSuccessState(
    BuildContext context,
    IndicesLoadSuccessBase state, {
    required bool scrollable,
  }) {
    final List<Widget> children = state.indices
        .map(
          (obj) => AppButton(
            label: obj.index,
            onTap: () => bloc.add(IndexLoadRequested(index: obj.index)),
            alignment: scrollable ? null : Alignment.center,
            padding: EdgeInsets.symmetric(
              vertical: AppSpacing.md,
              horizontal: scrollable ? AppSpacing.md : AppSpacing.sm,
            ),
          ),
        )
        .toList();
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: scrollable ? AppSpacing.md : AppSpacing.huge,
          ),
          child: scrollable
              ? Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: children,
                )
              : Row(
                  children: children
                      .map((child) => Expanded(child: child))
                      .expand(
                        (child) => [
                          const SizedBox(width: AppSpacing.md),
                          child,
                        ],
                      )
                      .toList(),
                ),
        ),
        const SizedBox(height: AppSpacing.lg),
        MaybeWidget(
          enabled: !scrollable,
          builder: (child) => Expanded(child: child),
          child: switch (state) {
            IndicesInitial() => Text("Selecione um índice para pesquisar."),
            EntitiesLoadInProgress() => Text("loading!"),
            EntitiesLoadSuccessBase() => _buildEntitiesLoadSuccessState(
              context,
              state,
              scrollable: scrollable,
            ),
          },
        ),
      ],
    );
  }

  Widget _buildEntitiesLoadSuccessState(
    BuildContext context,
    EntitiesLoadSuccessBase state, {
    required bool scrollable,
  }) {
    const EdgeInsets bodyPadding = EdgeInsets.symmetric(
      horizontal: AppSpacing.lg,
    );
    final Widget body;
    if (scrollable) {
      body = Padding(
        padding: bodyPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: state.entities
              .map((entity) => _EntityCard(bloc: bloc, entity: entity))
              .expand((child) => [const SizedBox(height: AppSpacing.sm), child])
              .skip(1)
              .toList(),
        ),
      );
    } else {
      final List<List<Entity>> groups = state.entities.chunked(2).toList();
      body = ListView.builder(
        padding: bodyPadding,
        itemCount: groups.length,
        itemBuilder: (context, i) {
          final List<Entity> entities = groups[i];
          return Row(
            children: entities
                .map(
                  (entity) => Expanded(
                    child: _EntityCard(bloc: bloc, entity: entity),
                  ),
                )
                .expand(
                  (child) => [const SizedBox(width: AppSpacing.sm), child],
                )
                .skip(1)
                .toList(),
          );
        },
      );
    }

    return rf.ResponsiveRowColumn(
      layout: scrollable
          ? rf.ResponsiveRowColumnType.COLUMN
          : rf.ResponsiveRowColumnType.ROW,
      children: [
        rf.ResponsiveRowColumnItem(rowFit: FlexFit.tight, child: body),
        if (!scrollable)
          rf.ResponsiveRowColumnItem(
            rowFit: FlexFit.tight,
            child: switch (state) {
              EntitiesInitial() => Center(
                child: Text(
                  "Select a character or location to view its data.",
                  style: Theme.of(context).textTheme.displaySmall,
                ),
              ),
              EntitySelectedInitial() => Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              state.stats.entity.name,
                              style: Theme.of(context).textTheme.displayMedium,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              state.stats.entity.wikiHref,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(color: Colors.grey),
                            ),
                          ],
                        ),
                        const SizedBox(width: AppSpacing.huge),
                        InkWell(
                          onTap: () async {
                            await launchUrl(
                              Uri(
                                scheme: "https",
                                host: "walkingdead.fandom.com",
                                path: state.stats.entity.wikiHref,
                              ),
                            );
                          },
                          child: SvgPicture.network(
                            "https://upload.wikimedia.org/wikipedia/commons/e/ee/Fandom_heart-logo.svg",
                            height: 36,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Expanded(
                      child: rf.ResponsiveRowColumn(
                        layout: scrollable
                            ? rf.ResponsiveRowColumnType.COLUMN
                            : rf.ResponsiveRowColumnType.ROW,
                        children: [
                          rf.ResponsiveRowColumnItem(
                            rowFit: FlexFit.tight,
                            child: Column(
                              children: [
                                Text(
                                  "Timeline",
                                  style: Theme.of(
                                    context,
                                  ).textTheme.displaySmall,
                                ),
                                Expanded(
                                  child: Timeline.tileBuilder(
                                    theme: TimelineThemeData(
                                      nodePosition: 0,
                                      connectorTheme: const ConnectorThemeData(
                                        thickness: 2.5,
                                        color: Colors.grey,
                                      ),
                                      indicatorTheme: const IndicatorThemeData(
                                        size: 16,
                                      ),
                                    ),
                                    builder: TimelineTileBuilder.connected(
                                      itemCount: state.stats.episodes.length,
                                      connectionDirection:
                                          ConnectionDirection.before,
                                      contentsBuilder: (context, index) {
                                        final EpisodeOut appearance =
                                            state.stats.episodes[index];
                                        final Episode episode =
                                            appearance.episode;
                                        final isNewSeason =
                                            index == 0 ||
                                            episode.seasonNumber !=
                                                state
                                                    .stats
                                                    .episodes[index - 1]
                                                    .episode
                                                    .seasonNumber;

                                        return Padding(
                                          padding: const EdgeInsets.all(12.0),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              if (isNewSeason)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        bottom: 6,
                                                      ),
                                                  child: Text(
                                                    'Season ${episode.seasonNumber}',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .headlineLarge
                                                        ?.copyWith(
                                                          color:
                                                              Colors.blueAccent,
                                                        ),
                                                  ),
                                                ),
                                              Text(
                                                'E${episode.episodeNumber}: ${episode.name} (${appearance.appearanceTypeLabel}, ${appearance.appearanceFormTypeLabel})',
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.headlineMedium,
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                      indicatorBuilder: (context, index) {
                                        final Episode episode =
                                            state.stats.episodes[index].episode;
                                        final isSeasonStart =
                                            index == 0 ||
                                            episode.seasonNumber !=
                                                state
                                                    .stats
                                                    .episodes[index - 1]
                                                    .episode
                                                    .seasonNumber;

                                        return DotIndicator(
                                          color: isSeasonStart
                                              ? Colors.blue
                                              : Colors.grey,
                                        );
                                      },
                                      connectorBuilder: (_, index, type) =>
                                          const SolidLineConnector(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!scrollable)
                            rf.ResponsiveRowColumnItem(
                              child: VerticalDivider(),
                            ),
                          rf.ResponsiveRowColumnItem(
                            rowFit: FlexFit.tight,
                            child: const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            },
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool scrollable = rf.ResponsiveBreakpoints.of(
      context,
    ).smallerThan(kDeviceDesktop);
    final List<Widget> children = [
      HeaderWidget(),
      Center(
        child: Text(
          AppLocalizations.of(context)!.homepageEntitiesButtonLabel,
          style: Theme.of(context).textTheme.displayLarge,
        ),
      ),
      const SizedBox(height: AppSpacing.lg),
      MaybeWidget(
        enabled: !scrollable,
        builder: (child) => Expanded(child: child),
        child: BlocBuilder<EntitiesBloc, EntitiesState>(
          bloc: bloc,
          builder: (context, state) {
            switch (state) {
              case IndicesLoadInProgress():
                return Text("loading indices!");
              case IndicesLoadSuccessBase():
                return _buildIndicesLoadSuccessState(
                  context,
                  state,
                  scrollable: scrollable,
                );
            }
          },
        ),
      ),
      const SizedBox(height: AppSpacing.lg),
    ];
    return Scaffold(
      body: Ink(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 1.2,
            colors: [Color(0xFF999999), Color(0xFFFFFFFF)],
            stops: [0.0, 1.0],
          ),
        ),
        child: scrollable
            ? ListView(children: children)
            : Column(children: children),
      ),
    );
  }
}
