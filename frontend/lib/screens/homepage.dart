import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:responsive_framework/responsive_framework.dart' as rf;
import 'package:twd_hub/main.dart';

class MaybeWidget extends StatelessWidget {
  final Widget child;
  final bool enabled;
  final Widget Function(Widget child) builder;

  const MaybeWidget({
    super.key,
    required this.enabled,
    required this.builder,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => enabled ? builder(child) : child;
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool scrollable = rf.ResponsiveBreakpoints.of(
      context,
    ).smallerThan(kDeviceDesktop);
    final List<Widget> children = [
      Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: SvgPicture.network(
          "https://upload.wikimedia.org/wikipedia/commons/e/ef/The_Walking_Dead_2010_logo.svg",
          height: 100,
        ),
      ),
      MaybeWidget(
        enabled: !scrollable,
        builder: (child) => Expanded(child: child),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.huge),
          child: rf.ResponsiveRowColumn(
            layout: scrollable
                ? rf.ResponsiveRowColumnType.COLUMN
                : rf.ResponsiveRowColumnType.ROW,
            children: [
              rf.ResponsiveRowColumnItem(
                rowFlex: 7,
                rowFit: FlexFit.tight,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    MaybeWidget(
                      enabled: !scrollable,
                      builder: (child) => Expanded(child: child),
                      child: Image.network(
                        "https://static.independent.co.uk/s3fs-public/thumbnails/image/2017/03/06/13/the-walking-dead-cast-1.jpg",
                        fit: BoxFit.cover,
                        alignment: Alignment.topCenter,
                      ),
                    ),
                    SizedBox(height: AppSpacing.xxxl),
                    Center(
                      child: Text(
                        "Bem-vindo ao seu guia definitivo de personagens de The "
                        "Walking Dead!\nAqui você encontra um panorama completo "
                        "sobre cada sobrevivente que marcou a série — desde sua "
                        "primeira aparição até seu destino final. Consulte "
                        "rapidamente quando e como cada personagem morreu, "
                        "incluindo as circunstâncias principais. Veja se houve "
                        "aparições em flashbacks e em quais episódios ocorreram. "
                        "Acompanhe também a primeira aparição, estatísticas ao "
                        "longo das temporadas e redescubra personagens que podem "
                        "ter passado despercebidos.",
                        style: TextStyle(fontSize: 28),
                        textAlign: TextAlign.justify,
                      ),
                    ),
                  ],
                ),
              ),
              rf.ResponsiveRowColumnItem(
                child: scrollable
                    ? const SizedBox(height: AppSpacing.xl)
                    : const SizedBox(width: AppSpacing.huge),
              ),
              rf.ResponsiveRowColumnItem(
                rowFlex: 4,
                rowFit: FlexFit.tight,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Text("Menu", style: TextStyle(fontSize: 64)),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Column(
                        children: [
                          _Button(label: "Personagens"),
                          SizedBox(height: AppSpacing.md),
                          _Button(label: "Temporadas"),
                          SizedBox(height: AppSpacing.md),
                          _Button(label: "Episódios"),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Center(
          child: Text(
            "Criado por: github.com/ezgrs",
            style: TextStyle(fontSize: 36),
          ),
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

class _Button extends StatelessWidget {
  final String label;
  const _Button({required this.label});

  @override
  Widget build(BuildContext context) {
    return Ink(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: Text(
              label,
              style: TextStyle(fontSize: 36, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}
