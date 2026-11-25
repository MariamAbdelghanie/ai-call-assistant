import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'glass.dart';

/// Tek bir ozet metrik: halka + rakam + etiket.
class KpiRing {
  const KpiRing({
    required this.value,
    required this.total,
    required this.label,
    required this.color,
    this.onTap,
  });

  /// Gosterilen rakam.
  final int value;

  /// Halkanin doluluk oranini belirleyen taban. 0 ise halka bos kalir.
  final int total;

  final String label;
  final Color color;
  final VoidCallback? onTap;
}

/// Dort metrigi tek beyaz kartta yan yana gosteren satir.
///
/// Rakamlari duz yazi yerine halka icinde vermek iki is yapiyor: oran
/// gorunur oluyor (3 acil cagri 4 cagri icindeyse bu ciddi, 400 icindeyse
/// degil) ve satir, altindaki duz liste kartlarindan gorsel olarak ayriliyor.
class KpiRingRow extends StatelessWidget {
  const KpiRingRow({super.key, required this.items});

  final List<KpiRing> items;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      radius: 20,
      child: Row(
        children: [
          for (final item in items)
            Expanded(child: _RingCell(item: item)),
        ],
      ),
    );
  }
}

class _RingCell extends StatelessWidget {
  const _RingCell({required this.item});

  final KpiRing item;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final fraction = item.total <= 0
        ? 0.0
        : (item.value / item.total).clamp(0.0, 1.0).toDouble();

    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Column(
          children: [
            SizedBox(
              width: 54,
              height: 54,
              child: CustomPaint(
                painter: _RingPainter(
                  fraction: fraction,
                  color: item.color,
                  track: tokens.glassBorder,
                ),
                child: Center(
                  child: Text(
                    '${item.value}',
                    style: context.text.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: context.text.labelSmall?.copyWith(color: tokens.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.fraction,
    required this.color,
    required this.track,
  });

  final double fraction;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 5.0;
    final rect = Rect.fromLTWH(0, 0, size.width, size.height)
        .deflate(stroke / 2 + 1);

    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = track;
    canvas.drawArc(rect, 0, math.pi * 2, false, base);

    if (fraction <= 0) return;

    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * fraction,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.fraction != fraction || old.color != color || old.track != track;
}

/// Basligin altindaki hizli eylem seridi.
class QuickActionPills extends StatelessWidget {
  const QuickActionPills({super.key, required this.actions});

  final List<({IconData icon, String label, VoidCallback onTap})> actions;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final action in actions)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: _ActionPill(
                icon: action.icon,
                label: action.label,
                onTap: action.onTap,
              ),
            ),
        ],
      ),
    );
  }
}

class _ActionPill extends StatelessWidget {
  const _ActionPill({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Material(
      color: tokens.isDark ? tokens.glass : AppPalette.surface,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: tokens.glassBorder),
          ),
          child: Row(
            children: [
              Icon(icon, size: 17, color: AppPalette.orange),
              const SizedBox(width: 7),
              Text(
                label,
                style: context.text.titleSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
