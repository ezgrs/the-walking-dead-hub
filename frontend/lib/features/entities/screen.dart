import 'package:dartx/dartx.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:responsive_framework/responsive_framework.dart' as rf;

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
        rf.ResponsiveRowColumnItem(
          rowFit: FlexFit.tight,
          child: const SizedBox.shrink(),
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
