import 'package:flutter/material.dart';

class AppLoading extends StatelessWidget {
  const AppLoading({super.key, this.label, this.child});

  final String? label;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    if (child != null) return child!;
    return const AppSkeletonList();
  }
}

class AppSkeleton {
  const AppSkeleton._();

  static Widget home() => ListView(
    children: const [
      SkeletonBox(height: 420, borderRadius: 0),
      Padding(
        padding: EdgeInsets.fromLTRB(18, 28, 18, 8),
        child: AppSkeletonGrid(),
      ),
      Padding(
        padding: EdgeInsets.fromLTRB(18, 20, 18, 8),
        child: AppSkeletonGrid(),
      ),
    ],
  );

  static Widget contentList({int itemCount = 4}) =>
      AppSkeletonList(itemCount: itemCount);

  static Widget contentDetail() => ListView(
    children: const [
      SkeletonBox(height: 360, borderRadius: 0),
      Padding(
        padding: EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBox(height: 32, width: 260),
            SizedBox(height: 14),
            SkeletonBox(height: 20, width: double.infinity),
            SizedBox(height: 8),
            SkeletonBox(height: 20, width: 280),
            SizedBox(height: 22),
            SkeletonParagraph(lines: 8),
          ],
        ),
      ),
    ],
  );

  static Widget notifications({int itemCount = 8}) =>
      AppSkeletonTileList(itemCount: itemCount);

  static Widget settings() => ListView(
    padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
    children: const [
      SkeletonCard(height: 152),
      SizedBox(height: 14),
      SkeletonCard(height: 102),
      SizedBox(height: 14),
      SkeletonCard(height: 76, lines: 2),
      SizedBox(height: 14),
      SkeletonCard(height: 76, lines: 2),
      SizedBox(height: 14),
      SkeletonCard(height: 220),
    ],
  );
}

class AppSkeletonList extends StatelessWidget {
  const AppSkeletonList({super.key, this.itemCount = 4});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(18),
      itemCount: itemCount + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: SkeletonBox(height: 32, width: 180),
          );
        }
        return const Padding(
          padding: EdgeInsets.only(bottom: 14),
          child: SkeletonContentCard(height: 230),
        );
      },
    );
  }
}

class AppSkeletonGrid extends StatelessWidget {
  const AppSkeletonGrid({super.key, this.itemCount = 3});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 900
            ? 3
            : constraints.maxWidth > 620
            ? 2
            : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            childAspectRatio: 0.86,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
          ),
          itemCount: itemCount,
          itemBuilder: (_, __) => const SkeletonContentCard(),
        );
      },
    );
  }
}

class AppSkeletonTileList extends StatelessWidget {
  const AppSkeletonTileList({super.key, this.itemCount = 8});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemBuilder: (_, __) => const SkeletonTile(),
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemCount: itemCount,
    );
  }
}

class SkeletonTile extends StatelessWidget {
  const SkeletonTile({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: Row(
        children: [
          SkeletonBox(width: 42, height: 42, borderRadius: 21),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(height: 18, width: 180),
                SizedBox(height: 8),
                SkeletonBox(height: 14, width: double.infinity),
                SizedBox(height: 6),
                SkeletonBox(height: 14, width: 220),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SkeletonContentCard extends StatelessWidget {
  const SkeletonContentCard({super.key, this.height});

  final double? height;

  @override
  Widget build(BuildContext context) {
    final card = Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Expanded(child: SkeletonBox(borderRadius: 0)),
          Padding(
            padding: EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(height: 18, width: 210),
                SizedBox(height: 8),
                SkeletonBox(height: 14, width: double.infinity),
                SizedBox(height: 6),
                SkeletonBox(height: 14, width: 170),
              ],
            ),
          ),
        ],
      ),
    );
    return height == null ? card : SizedBox(height: height, child: card);
  }
}

class SkeletonCard extends StatelessWidget {
  const SkeletonCard({
    super.key,
    this.width,
    required this.height,
    this.lines = 3,
  });

  final double? width;
  final double height;
  final int lines;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SkeletonParagraph(lines: lines),
        ),
      ),
    );
  }
}

class SkeletonParagraph extends StatelessWidget {
  const SkeletonParagraph({super.key, this.lines = 4});

  final int lines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < lines; index++) ...[
          SkeletonBox(
            height: 14,
            width: index == lines - 1 ? 180 : double.infinity,
          ),
          if (index != lines - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class SkeletonBox extends StatefulWidget {
  const SkeletonBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 8,
  });

  final double? width;
  final double? height;
  final double borderRadius;

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1150),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final base = colors.surfaceContainerHighest;
    final highlight = Color.alphaBlend(
      colors.surface.withValues(alpha: 0.68),
      base,
    );
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [base, highlight, base],
              stops: const [0.18, 0.5, 0.82],
              transform: _SlidingGradientTransform(_controller.value),
            ),
          ),
        );
      },
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform(this.value);

  final double value;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * (value * 2 - 1), 0, 0);
  }
}
