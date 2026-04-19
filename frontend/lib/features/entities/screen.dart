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

class EntitiesScreen extends StatelessWidget {
  final EntitiesBloc bloc;

  const EntitiesScreen({super.key, required this.bloc});

  Widget _buildIndicesLoadSuccessState(
    BuildContext context,
    IndicesLoadSuccessBase state, {
    required bool scrollable,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.huge),
          child: Row(
            children: state.indices
                .map(
                  (obj) => Expanded(
                    child: AppButton(
                      label: obj.index,
                      onTap: () =>
                          bloc.add(IndexLoadRequested(index: obj.index)),
                      padding: EdgeInsets.symmetric(
                        vertical: AppSpacing.md,
                        horizontal: AppSpacing.sm,
                      ),
                    ),
                  ),
                )
                .expand(
                  (child) => [const SizedBox(width: AppSpacing.lg), child],
                )
                .skip(1)
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
    final List<List<Entity>> groups = state.entities.chunked(2).toList();
    return rf.ResponsiveRowColumn(
      layout: scrollable
          ? rf.ResponsiveRowColumnType.COLUMN
          : rf.ResponsiveRowColumnType.ROW,
      children: [
        rf.ResponsiveRowColumnItem(
          rowFit: FlexFit.tight,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            itemCount: groups.length,
            itemBuilder: (context, i) {
              final List<Entity> entities = groups[i];
              return Row(
                children: entities
                    .map(
                      (entity) => Expanded(
                        child: Card(
                          child: InkWell(
                            onTap: () => bloc.add(
                              EpisodesLoadRequested(entityId: entity.id),
                            ),
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
                                    style: Theme.of(
                                      context,
                                    ).textTheme.headlineSmall,
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    entity.wikiHref,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                    .expand(
                      (child) => [const SizedBox(width: AppSpacing.sm), child],
                    )
                    .skip(1)
                    .toList(),
              );
            },
          ),
        ),
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
      Text(
        AppLocalizations.of(context)!.homepageEntitiesButtonLabel,
        style: Theme.of(context).textTheme.displayLarge,
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
