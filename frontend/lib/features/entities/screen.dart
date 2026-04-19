import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:responsive_framework/responsive_framework.dart' as rf;
import 'package:twd_hub/features/entities/bloc_event.dart';
import 'package:twd_hub/features/entities/bloc_state.dart';
import 'package:twd_hub/models.dart';
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
        MaybeWidget(
          enabled: !scrollable,
          builder: (child) => Expanded(child: child),
          child: switch (state) {
            IndicesInitial() => Text("Selecione um índice para pesquisar."),
            EntitiesLoadInProgress() => Text("loading!"),
            EntitiesLoadSuccessBase() => ListView.builder(
              itemCount: state.entities.length,
              itemBuilder: (context, i) {
                final Entity entity = state.entities[i];
                return Text(entity.name);
              },
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
