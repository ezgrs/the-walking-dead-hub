import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:responsive_framework/responsive_framework.dart' as rf;

import '../main.dart';
import 'button.dart';
import 'header.dart';
import 'maybe.dart';

typedef AppRecordIndexBuilder<T> = String Function(T record);
typedef AppRecordKeyBuilder<T> = Object Function(T record);
typedef AppRecordLabelBuilder<T> = String Function(T record);
typedef AppRecordSelected<T> = void Function(T record);
typedef AppIndexedDetailBuilder = Widget Function(
  BuildContext context,
  bool compact,
);

class AppIndexedMasterDetailIndex {
  final String value;
  final int count;

  const AppIndexedMasterDetailIndex({
    required this.value,
    required this.count,
  });

  static List<AppIndexedMasterDetailIndex> fromRecords<T>(
    Iterable<T> records,
    AppRecordIndexBuilder<T> indexBuilder,
  ) {
    final Map<String, int> counts = {};
    for (final T record in records) {
      final String index = indexBuilder(record);
      counts[index] = (counts[index] ?? 0) + 1;
    }

    return counts.entries
        .map(
          (entry) => AppIndexedMasterDetailIndex(
            value: entry.key,
            count: entry.value,
          ),
        )
        .toList()
      ..sort((a, b) => a.value.compareTo(b.value));
  }
}

class AppIndexedMasterDetailPage<T> extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color? iconBackgroundColor;
  final String title;
  final bool indicesLoading;
  final bool recordsLoading;
  final List<AppIndexedMasterDetailIndex>? indices;
  final String? selectedIndex;
  final ValueChanged<String> onIndexSelected;
  final List<T> records;
  final bool recordsArePreFiltered;
  final Object? selectedRecordKey;
  final AppRecordIndexBuilder<T> recordIndexBuilder;
  final AppRecordKeyBuilder<T> recordKeyBuilder;
  final AppRecordLabelBuilder<T> recordLabelBuilder;
  final AppRecordSelected<T> onRecordSelected;
  final AppIndexedDetailBuilder detailBuilder;
  final String searchHint;
  final String chooseIndexTitle;
  final String chooseIndexMessage;
  final String emptyRecordsTitle;
  final String emptyRecordsMessage;
  final String emptySearchTitle;
  final String emptySearchMessage;

  const AppIndexedMasterDetailPage({
    super.key,
    required this.icon,
    required this.color,
    this.iconBackgroundColor,
    required this.title,
    required this.indicesLoading,
    required this.recordsLoading,
    this.indices,
    required this.selectedIndex,
    required this.onIndexSelected,
    required this.records,
    this.recordsArePreFiltered = false,
    required this.selectedRecordKey,
    required this.recordIndexBuilder,
    required this.recordKeyBuilder,
    required this.recordLabelBuilder,
    required this.onRecordSelected,
    required this.detailBuilder,
    required this.searchHint,
    required this.chooseIndexTitle,
    required this.chooseIndexMessage,
    required this.emptyRecordsTitle,
    required this.emptyRecordsMessage,
    required this.emptySearchTitle,
    required this.emptySearchMessage,
  });

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
                  AppIndexedPageTitle(
                    icon: icon,
                    color: color,
                    iconBackgroundColor: iconBackgroundColor,
                    title: title,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  MaybeWidget(
                    enabled: !compact,
                    builder: (child) => Expanded(child: child),
                    child: _IndexedMasterDetailBody<T>(
                      compact: compact,
                      indicesLoading: indicesLoading,
                      recordsLoading: recordsLoading,
                      indices: _effectiveIndices,
                      selectedIndex: selectedIndex,
                      onIndexSelected: onIndexSelected,
                      records: _effectiveRecords,
                      selectedRecordKey: selectedRecordKey,
                      recordKeyBuilder: recordKeyBuilder,
                      recordLabelBuilder: recordLabelBuilder,
                      onRecordSelected: onRecordSelected,
                      detailBuilder: detailBuilder,
                      searchHint: searchHint,
                      chooseIndexTitle: chooseIndexTitle,
                      chooseIndexMessage: chooseIndexMessage,
                      emptyRecordsTitle: emptyRecordsTitle,
                      emptyRecordsMessage: emptyRecordsMessage,
                      emptySearchTitle: emptySearchTitle,
                      emptySearchMessage: emptySearchMessage,
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

  List<AppIndexedMasterDetailIndex> get _effectiveIndices {
    return indices ?? AppIndexedMasterDetailIndex.fromRecords(
      records,
      recordIndexBuilder,
    );
  }

  List<T> get _effectiveRecords {
    if (selectedIndex == null || recordsArePreFiltered) {
      return records;
    }

    return records
        .where((record) => recordIndexBuilder(record) == selectedIndex)
        .toList();
  }
}

class AppIndexedPageTitle extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color? iconBackgroundColor;
  final String title;

  const AppIndexedPageTitle({
    super.key,
    required this.icon,
    required this.color,
    this.iconBackgroundColor,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () {
            final NavigatorState navigator = Navigator.of(context);
            if (navigator.canPop()) {
              navigator.pop();
              return;
            }

            GoRouter.of(context).go('/');
          },
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        const SizedBox(width: AppSpacing.sm),
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: iconBackgroundColor ??
                Color.alphaBlend(color.withAlpha(28), AppColors.surface),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.displayMedium),
        ),
      ],
    );
  }
}

class AppIndexedDetailSkeleton extends StatelessWidget {
  final bool compact;
  final Widget? tabs;

  const AppIndexedDetailSkeleton({
    super.key,
    required this.compact,
    this.tabs,
  });

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: _IndexedDetailSkeletonPane(compact: compact, tabs: tabs),
    );
  }
}

class _IndexedMasterDetailBody<T> extends StatelessWidget {
  final bool compact;
  final bool indicesLoading;
  final bool recordsLoading;
  final List<AppIndexedMasterDetailIndex> indices;
  final String? selectedIndex;
  final ValueChanged<String> onIndexSelected;
  final List<T> records;
  final Object? selectedRecordKey;
  final AppRecordKeyBuilder<T> recordKeyBuilder;
  final AppRecordLabelBuilder<T> recordLabelBuilder;
  final AppRecordSelected<T> onRecordSelected;
  final AppIndexedDetailBuilder detailBuilder;
  final String searchHint;
  final String chooseIndexTitle;
  final String chooseIndexMessage;
  final String emptyRecordsTitle;
  final String emptyRecordsMessage;
  final String emptySearchTitle;
  final String emptySearchMessage;

  const _IndexedMasterDetailBody({
    required this.compact,
    required this.indicesLoading,
    required this.recordsLoading,
    required this.indices,
    required this.selectedIndex,
    required this.onIndexSelected,
    required this.records,
    required this.selectedRecordKey,
    required this.recordKeyBuilder,
    required this.recordLabelBuilder,
    required this.onRecordSelected,
    required this.detailBuilder,
    required this.searchHint,
    required this.chooseIndexTitle,
    required this.chooseIndexMessage,
    required this.emptyRecordsTitle,
    required this.emptyRecordsMessage,
    required this.emptySearchTitle,
    required this.emptySearchMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (indicesLoading) {
      return AppShimmer(child: _IndexedInitialSkeleton(compact: compact));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: indices
              .map(
                (index) => AppButton(
                  label: '${index.value} (${index.count})',
                  onTap: () => onIndexSelected(index.value),
                  selected: selectedIndex == index.value,
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.sm,
                    horizontal: AppSpacing.md,
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: AppSpacing.lg),
        MaybeWidget(
          enabled: !compact,
          builder: (child) => Expanded(child: child),
          child: _bodyContent(context),
        ),
      ],
    );
  }

  Widget _bodyContent(BuildContext context) {
    if (selectedIndex == null) {
      return AppIndexedEmptyState(
        icon: Icons.touch_app_rounded,
        title: chooseIndexTitle,
        message: chooseIndexMessage,
      );
    }

    if (recordsLoading) {
      return AppShimmer(child: _IndexedContentSkeleton(compact: compact));
    }

    if (records.isEmpty) {
      return AppIndexedEmptyState(
        icon: Icons.search_off_rounded,
        title: emptyRecordsTitle,
        message: emptyRecordsMessage,
      );
    }

    final Widget list = _IndexedRecordList<T>(
      compact: compact,
      records: records,
      selectedRecordKey: selectedRecordKey,
      recordKeyBuilder: recordKeyBuilder,
      recordLabelBuilder: recordLabelBuilder,
      onRecordSelected: onRecordSelected,
      searchHint: searchHint,
      emptyTitle: emptySearchTitle,
      emptyMessage: emptySearchMessage,
    );
    final Widget detail = detailBuilder(context, compact);

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
}

class _IndexedRecordList<T> extends StatefulWidget {
  final bool compact;
  final List<T> records;
  final Object? selectedRecordKey;
  final AppRecordKeyBuilder<T> recordKeyBuilder;
  final AppRecordLabelBuilder<T> recordLabelBuilder;
  final AppRecordSelected<T> onRecordSelected;
  final String searchHint;
  final String emptyTitle;
  final String emptyMessage;

  const _IndexedRecordList({
    required this.compact,
    required this.records,
    required this.selectedRecordKey,
    required this.recordKeyBuilder,
    required this.recordLabelBuilder,
    required this.onRecordSelected,
    required this.searchHint,
    required this.emptyTitle,
    required this.emptyMessage,
  });

  @override
  State<_IndexedRecordList<T>> createState() => _IndexedRecordListState<T>();
}

class _IndexedRecordListState<T> extends State<_IndexedRecordList<T>> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final String normalizedQuery = _normalizeSearchText(_query);
    final List<T> visibleRecords = widget.records
        .where((record) {
          final String recordName = widget.recordLabelBuilder(record);
          return normalizedQuery.isEmpty ||
              _normalizeSearchText(recordName).contains(normalizedQuery);
        })
        .toList();

    final Widget results = visibleRecords.isEmpty
        ? AppIndexedEmptyState(
            icon: Icons.search_off_rounded,
            title: widget.emptyTitle,
            message: widget.emptyMessage,
          )
        : _IndexedRecordCards<T>(
            compact: widget.compact,
            records: visibleRecords,
            selectedRecordKey: widget.selectedRecordKey,
            recordKeyBuilder: widget.recordKeyBuilder,
            recordLabelBuilder: widget.recordLabelBuilder,
            onRecordSelected: widget.onRecordSelected,
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          onChanged: (value) => setState(() => _query = value),
          decoration: InputDecoration(
            hintText: widget.searchHint,
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

class _IndexedRecordCards<T> extends StatelessWidget {
  final bool compact;
  final List<T> records;
  final Object? selectedRecordKey;
  final AppRecordKeyBuilder<T> recordKeyBuilder;
  final AppRecordLabelBuilder<T> recordLabelBuilder;
  final AppRecordSelected<T> onRecordSelected;

  const _IndexedRecordCards({
    required this.compact,
    required this.records,
    required this.selectedRecordKey,
    required this.recordKeyBuilder,
    required this.recordLabelBuilder,
    required this.onRecordSelected,
  });

  @override
  Widget build(BuildContext context) {
    final Iterable<Widget> cards = records.map(
      (record) => _IndexedRecordCard(
        label: recordLabelBuilder(record),
        selected: selectedRecordKey == recordKeyBuilder(record),
        onTap: () => onRecordSelected(record),
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
      itemCount: records.length,
      itemBuilder: (context, index) {
        final T record = records[index];
        return _IndexedRecordCard(
          label: recordLabelBuilder(record),
          selected: selectedRecordKey == recordKeyBuilder(record),
          onTap: () => onRecordSelected(record),
        );
      },
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppSpacing.sm),
    );
  }
}

class _IndexedRecordCard extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _IndexedRecordCard({
    required this.label,
    required this.selected,
    required this.onTap,
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
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineSmall,
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

class AppIndexedEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const AppIndexedEmptyState({
    super.key,
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 36, color: AppColors.accent),
              const SizedBox(height: AppSpacing.md),
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.sm),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IndexedInitialSkeleton extends StatelessWidget {
  final bool compact;

  const _IndexedInitialSkeleton({required this.compact});

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _IndexButtonsSkeleton(),
          const SizedBox(height: AppSpacing.lg),
          _IndexedContentSkeleton(compact: compact),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _IndexButtonsSkeleton(),
        const SizedBox(height: AppSpacing.lg),
        Expanded(child: _IndexedContentSkeleton(compact: compact)),
      ],
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
        AppSkeletonBlock(width: 58, height: 38, radius: 8),
        AppSkeletonBlock(width: 64, height: 38, radius: 8),
        AppSkeletonBlock(width: 56, height: 38, radius: 8),
        AppSkeletonBlock(width: 68, height: 38, radius: 8),
        AppSkeletonBlock(width: 60, height: 38, radius: 8),
        AppSkeletonBlock(width: 62, height: 38, radius: 8),
        AppSkeletonBlock(width: 54, height: 38, radius: 8),
        AppSkeletonBlock(width: 66, height: 38, radius: 8),
        AppSkeletonBlock(width: 58, height: 38, radius: 8),
        AppSkeletonBlock(width: 64, height: 38, radius: 8),
      ],
    );
  }
}

class _IndexedContentSkeleton extends StatelessWidget {
  final bool compact;

  const _IndexedContentSkeleton({required this.compact});

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _IndexedListSkeletonPane(compact: true),
          SizedBox(height: AppSpacing.lg),
          _IndexedDetailSkeletonPane(compact: true),
        ],
      );
    }

    return const Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(flex: 4, child: _IndexedListSkeletonPane(compact: false)),
        SizedBox(width: AppSpacing.lg),
        Expanded(flex: 6, child: _IndexedDetailSkeletonPane(compact: false)),
      ],
    );
  }
}

class _IndexedListSkeletonPane extends StatelessWidget {
  final bool compact;

  const _IndexedListSkeletonPane({required this.compact});

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
              itemBuilder: (context, index) => const _IndexedSkeletonCard(),
              separatorBuilder: (context, index) =>
                  const SizedBox(height: AppSpacing.sm),
            ),
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AppSkeletonBlock(height: 48, radius: 8),
        const SizedBox(height: AppSpacing.md),
        cards,
      ],
    );
  }

  static List<Widget> _skeletonCards(int count) {
    return List<Widget>.generate(count, (index) {
      return Padding(
        padding: EdgeInsets.only(top: index == 0 ? 0 : AppSpacing.sm),
        child: const _IndexedSkeletonCard(),
      );
    });
  }
}

class _IndexedDetailSkeletonPane extends StatelessWidget {
  final bool compact;
  final Widget? tabs;

  const _IndexedDetailSkeletonPane({required this.compact, this.tabs});

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
                    AppSkeletonBlock(width: 220, height: 28, radius: 7),
                    SizedBox(height: AppSpacing.sm),
                    AppSkeletonBlock(width: 300, height: 16, radius: 6),
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
          tabs ?? const _DetailTabsSkeleton(),
          const SizedBox(height: AppSpacing.md),
          if (compact) ...[
            const _IndexedDetailMapSkeleton(),
          ] else ...[
            Expanded(child: const _IndexedDetailMapSkeleton()),
          ],
        ],
      ),
    );
  }
}

class _DetailTabsSkeleton extends StatelessWidget {
  const _DetailTabsSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        AppSkeletonBlock(width: 120, height: 36, radius: 8),
        SizedBox(width: AppSpacing.sm),
        AppSkeletonBlock(width: 84, height: 36, radius: 8),
        SizedBox(width: AppSpacing.sm),
        AppSkeletonBlock(width: 88, height: 36, radius: 8),
      ],
    );
  }
}

class _IndexedDetailMapSkeleton extends StatelessWidget {
  const _IndexedDetailMapSkeleton();

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
              AppSkeletonBlock(width: 40, height: 40, radius: 8),
              SizedBox(width: AppSpacing.sm),
              AppSkeletonBlock(width: 168, height: 40, radius: 8),
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
        AppSkeletonBlock(width: 34, height: 34, radius: 8),
        SizedBox(width: AppSpacing.md),
        Expanded(
          child: Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              AppSkeletonBlock(width: 34, height: 34, radius: 8),
              AppSkeletonBlock(width: 34, height: 34, radius: 8),
              AppSkeletonBlock(width: 34, height: 34, radius: 8),
              AppSkeletonBlock(width: 34, height: 34, radius: 8),
              AppSkeletonBlock(width: 34, height: 34, radius: 8),
              AppSkeletonBlock(width: 34, height: 34, radius: 8),
              AppSkeletonBlock(width: 34, height: 34, radius: 8),
              AppSkeletonBlock(width: 34, height: 34, radius: 8),
              AppSkeletonBlock(width: 34, height: 34, radius: 8),
              AppSkeletonBlock(width: 34, height: 34, radius: 8),
              AppSkeletonBlock(width: 34, height: 34, radius: 8),
              AppSkeletonBlock(width: 34, height: 34, radius: 8),
            ],
          ),
        ),
      ],
    );
  }
}

class _IndexedSkeletonCard extends StatelessWidget {
  const _IndexedSkeletonCard();

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
              child: AppSkeletonBlock(width: 180, height: 18, radius: 6),
            ),
          ),
          SizedBox(width: AppSpacing.md),
          AppSkeletonBlock(width: 22, height: 22, radius: 8),
        ],
      ),
    );
  }
}

class AppShimmer extends StatefulWidget {
  final Widget child;

  const AppShimmer({super.key, required this.child});

  @override
  State<AppShimmer> createState() => _AppShimmerState();
}

class _AppShimmerState extends State<AppShimmer>
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

class AppSkeletonBlock extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;

  const AppSkeletonBlock({
    super.key,
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
