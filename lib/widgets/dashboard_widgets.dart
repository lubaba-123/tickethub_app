import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 19, color: color),
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class StatGrid extends StatelessWidget {
  final List<StatCard> cards;

  const StatGrid({super.key, required this.cards});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 640 ? 4 : 2;
        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: columns == 4 ? 1.45 : 1.35,
          children: cards,
        );
      },
    );
  }
}

class ChartBar {
  final String label;
  final double value;
  final String display;

  const ChartBar(this.label, this.value, this.display);
}

class HorizontalBarChart extends StatelessWidget {
  final List<ChartBar> bars;
  final Color color;

  const HorizontalBarChart({super.key, required this.bars, this.color = AppColors.primary});

  @override
  Widget build(BuildContext context) {
    if (bars.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text('No data yet.', style: TextStyle(color: AppColors.textSecondary)),
      );
    }
    var maxValue = bars.map((b) => b.value).reduce((a, b) => a > b ? a : b);
    if (maxValue <= 0) maxValue = 1;

    return Column(
      children: [
        for (final bar in bars)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 112,
                  child: Text(
                    bar.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Stack(
                      children: [
                        Container(height: 14, color: AppColors.border),
                        FractionallySizedBox(
                          widthFactor: (bar.value / maxValue).clamp(0.02, 1.0),
                          child: Container(height: 14, color: color),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 70,
                  child: Text(
                    bar.display,
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class ColumnBarChart extends StatelessWidget {
  final List<ChartBar> bars;
  final Color color;

  const ColumnBarChart({super.key, required this.bars, this.color = AppColors.accent});

  @override
  Widget build(BuildContext context) {
    var maxValue = bars.isEmpty ? 1.0 : bars.map((b) => b.value).reduce((a, b) => a > b ? a : b);
    if (maxValue <= 0) maxValue = 1;

    return SizedBox(
      height: 168,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final bar in bars)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(bar.display, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Container(
                      height: (bar.value / maxValue * 100).clamp(3.0, 100.0),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      bar.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
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

class SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const SectionCard({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
