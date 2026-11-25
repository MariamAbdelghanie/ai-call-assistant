import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../models/call_summary.dart';
import '../theme/app_theme.dart';
import 'glass.dart';
import 'soft_icon.dart';

/// Cagri verisinden turetilen kucuk gostergeler.
///
/// Sayfanin tamami ayni bicimde beyaz kutulardan olusunca tekduze gorunuyordu.
/// Bu kartlar farkli bir gorsel dil (cubuk grafik, oranlar, buyuk rakam)
/// getirerek hem ritmi kirar hem de asistanin ne is yaptigini somut gosterir.

/// Son yedi gunun cagri dagilimi.
class WeeklyActivityCard extends StatelessWidget {
  const WeeklyActivityCard({super.key, required this.calls});

  final List<CallSummary> calls;

  /// Bugunden geriye yedi gun, en eski solda.
  List<({DateTime day, int count})> _buckets() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return List.generate(7, (i) {
      final day = today.subtract(Duration(days: 6 - i));
      final count = calls.where((c) {
        final t = c.timestamp;
        if (t == null) return false;
        return t.year == day.year && t.month == day.month && t.day == day.day;
      }).length;
      return (day: day, count: count);
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final tokens = context.tokens;
    final data = _buckets();
    final maxCount = data.fold<int>(1, (m, e) => math.max(m, e.count));
    final total = data.fold<int>(0, (s, e) => s + e.count);

    // Son uc gun ile onceki uc gunu karsilastirarak basit bir egilim.
    final recent = data.skip(4).fold<int>(0, (s, e) => s + e.count);
    final earlier = data.take(3).fold<int>(0, (s, e) => s + e.count);
    final rising = recent >= earlier;

    final labels = strings.weekdayInitials();

    return GlassCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      radius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                strings.t('weeklyTitle'),
                style: context.text.labelLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: (rising ? tokens.success : tokens.muted)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Transform.rotate(
                      angle: rising ? -1.5708 : 1.5708,
                      child: SoftIcon(
                        AppIcon.chevron,
                        size: 11,
                        color: rising ? tokens.success : tokens.muted,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$total',
                      style: context.text.labelSmall?.copyWith(
                        color: rising ? tokens.success : tokens.muted,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          // Cubuk yerine alan grafigi: yedi gunun cizgisi egilimi tek
          // bakista gosteriyor, cubuklar ise birbirinden kopuk yedi
          // rakam gibi duruyordu.
          SizedBox(
            height: 96,
            child: CustomPaint(
              size: Size.infinite,
              painter: _TrendPainter(
                values: [for (final b in data) b.count.toDouble()],
                maxValue: maxCount.toDouble(),
                line: AppPalette.orange,
                grid: tokens.glassBorder,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final (i, bucket) in data.indexed)
                Expanded(
                  child: Text(
                    labels[bucket.day.weekday - 1],
                    textAlign: TextAlign.center,
                    style: context.text.labelSmall?.copyWith(
                      color: i == data.length - 1
                          ? AppPalette.orange
                          : tokens.muted,
                      fontWeight: i == data.length - 1
                          ? FontWeight.w800
                          : FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Arayanlarin dil dagilimi: tek bir yatay seritte oranlar.
class LanguageMixCard extends StatelessWidget {
  const LanguageMixCard({super.key, required this.calls});

  final List<CallSummary> calls;

  static const _order = ['tr', 'ar', 'en'];
  static const _colors = {
    'tr': AppPalette.orange,
    'ar': Color(0xFF34D399),
    'en': Color(0xFF7AA2FF),
  };

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    final counts = <String, int>{for (final k in _order) k: 0};
    for (final c in calls) {
      final key = _order.contains(c.lang) ? c.lang : 'tr';
      counts[key] = counts[key]! + 1;
    }
    final total = counts.values.fold<int>(0, (a, b) => a + b);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        // Lacivert kart: sayfadaki beyaz kart dizisini kirar ve dil
        // dagilimini tek bakista ayirt edilir bir blok yapar.
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppPalette.indigo, AppPalette.indigoDeep],
        ),
        boxShadow: [
          BoxShadow(
            color: AppPalette.indigoDeep.withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.t('langMixTitle'),
            style: context.text.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 14),
          // Halka: cubuk serit yerine, yuzdeler arasindaki farki daha
          // iyi gosteriyor ve ortasinda toplam cagri sayisi duruyor.
          Center(
            child: SizedBox(
              width: 104,
              height: 104,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size.square(104),
                    painter: _DonutPainter(
                      values: [for (final k in _order) counts[k]!.toDouble()],
                      colors: [for (final k in _order) _colors[k]!],
                      track: Colors.white.withValues(alpha: 0.14),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$total',
                        style: context.text.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      Text(
                        strings.t('statTotal'),
                        style: context.text.labelSmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.65),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          for (final key in _order)
            Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                children: [
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: _colors[key],
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      strings.t('lang_$key'),
                      style: context.text.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.86),
                      ),
                    ),
                  ),
                  Text(
                    total == 0
                        ? '0%'
                        : '${((counts[key]! / total) * 100).round()}%',
                    style: context.text.labelSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class PeakHourCard extends StatelessWidget {
  const PeakHourCard({super.key, required this.calls});

  final List<CallSummary> calls;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final tokens = context.tokens;

    final perHour = <int, int>{};
    for (final c in calls) {
      final t = c.timestamp;
      if (t == null) continue;
      perHour[t.hour] = (perHour[t.hour] ?? 0) + 1;
    }
    int? peak;
    var best = 0;
    perHour.forEach((hour, count) {
      if (count > best) {
        best = count;
        peak = hour;
      }
    });

    final label = peak == null ? '—' : '${peak.toString().padLeft(2, '0')}:00';

    return GlassCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      radius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SoftIcon(AppIcon.clock, size: 16, color: tokens.muted),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  strings.t('peakHourTitle'),
                  maxLines: 2,
                  style: context.text.labelLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Saat kadrani: rakam tek basina soyuttu; ibre gunun hangi
          // dilimi oldugunu (sabah mi, aksam mi) anlatiyor.
          Center(
            child: SizedBox(
              width: 104,
              height: 104,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size.square(104),
                    painter: _ClockPainter(
                      hour: peak,
                      ring: tokens.glassBorder,
                      hand: AppPalette.orange,
                      tick: tokens.muted,
                    ),
                  ),
                  Text(
                    label,
                    style: context.text.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppPalette.indigo,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              peak == null
                  ? strings.t('peakHourEmpty')
                  : '$best ${strings.t('peakHourUnit')}',
              textAlign: TextAlign.center,
              style: context.text.bodySmall?.copyWith(color: tokens.muted),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dil dagilimi halkasi.
class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.values,
    required this.colors,
    required this.track,
  });

  final List<double> values;
  final List<Color> colors;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 13.0;
    final rect = (Offset.zero & size).deflate(stroke / 2 + 2);
    final total = values.fold<double>(0, (a, b) => a + b);

    canvas.drawArc(
      rect,
      0,
      math.pi * 2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = track,
    );
    if (total <= 0) return;

    var start = -math.pi / 2;
    for (var i = 0; i < values.length; i++) {
      if (values[i] <= 0) continue;
      // Dilimler arasinda kucuk bir bosluk birakiyoruz; bitisik
      // yaylar tek renk gibi okunuyordu.
      final sweep = math.pi * 2 * (values[i] / total);
      canvas.drawArc(
        rect,
        start + 0.03,
        math.max(sweep - 0.06, 0.02),
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round
          ..color = colors[i],
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter oldDelegate) =>
      oldDelegate.values.toString() != values.toString();
}

/// En yogun saati gosteren kadran.
class _ClockPainter extends CustomPainter {
  _ClockPainter({
    required this.hour,
    required this.ring,
    required this.hand,
    required this.tick,
  });

  final int? hour;
  final Color ring;
  final Color hand;
  final Color tick;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 3;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = ring,
    );

    // 12 cizik: kadranin saat oldugunu anlatan sey bu.
    for (var i = 0; i < 12; i++) {
      final angle = -math.pi / 2 + i * math.pi / 6;
      final outer = center + Offset(math.cos(angle), math.sin(angle)) * radius;
      final inner = center +
          Offset(math.cos(angle), math.sin(angle)) *
              (radius - (i % 3 == 0 ? 8 : 5));
      canvas.drawLine(
        inner,
        outer,
        Paint()
          ..strokeWidth = i % 3 == 0 ? 2 : 1
          ..strokeCap = StrokeCap.round
          ..color = tick.withValues(alpha: i % 3 == 0 ? 0.55 : 0.3),
      );
    }

    if (hour == null) return;

    // Ibre 24 saatlik degeri 12'lik kadrana oturtur.
    final angle = -math.pi / 2 + (hour! % 12) * math.pi / 6;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      (hour! % 12) * math.pi / 6,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..color = hand.withValues(alpha: 0.35),
    );
    canvas.drawLine(
      center,
      center + Offset(math.cos(angle), math.sin(angle)) * (radius - 14),
      Paint()
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..color = hand,
    );
    canvas.drawCircle(center, 3.5, Paint()..color = hand);
  }

  @override
  bool shouldRepaint(_ClockPainter oldDelegate) => oldDelegate.hour != hour;
}

/// Haftalik egilim grafigi: yumusak bir cizgi, altinda sonen bir dolgu
/// ve her gun icin bir nokta. Son gun turuncu halkayla isaretlenir.
class _TrendPainter extends CustomPainter {
  _TrendPainter({
    required this.values,
    required this.maxValue,
    required this.line,
    required this.grid,
  });

  final List<double> values;
  final double maxValue;
  final Color line;
  final Color grid;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    const topPad = 14.0;
    final usable = size.height - topPad - 6;
    final step = size.width / (values.length - 1);

    Offset pointAt(int i) {
      final ratio = maxValue <= 0 ? 0.0 : values[i] / maxValue;
      return Offset(i * step, topPad + usable * (1 - ratio));
    }

    // Arkadaki yatay cizgiler: yukseklikleri okunabilir kilar.
    for (var i = 0; i <= 2; i++) {
      final y = topPad + usable * i / 2;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        Paint()
          ..strokeWidth = 1
          ..color = grid,
      );
    }

    // Yumusatilmis cizgi: iki nokta arasinda kubik egri.
    final path = Path()..moveTo(pointAt(0).dx, pointAt(0).dy);
    for (var i = 0; i < values.length - 1; i++) {
      final p1 = pointAt(i);
      final p2 = pointAt(i + 1);
      final midX = (p1.dx + p2.dx) / 2;
      path.cubicTo(midX, p1.dy, midX, p2.dy, p2.dx, p2.dy);
    }

    // Dolgu: cizginin altini kapatip tabana dogru soner.
    final fill = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            line.withValues(alpha: 0.26),
            line.withValues(alpha: 0.0),
          ],
        ).createShader(Offset.zero & size),
    );

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = line,
    );

    // Noktalar; sonuncusu daha buyuk ve halkali.
    for (var i = 0; i < values.length; i++) {
      final p = pointAt(i);
      final last = i == values.length - 1;
      canvas.drawCircle(p, last ? 6.5 : 3.5, Paint()..color = Colors.white);
      canvas.drawCircle(
        p,
        last ? 6.5 : 3.5,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = last ? 3 : 2
          ..color = line,
      );
    }
  }

  @override
  bool shouldRepaint(_TrendPainter oldDelegate) =>
      oldDelegate.values.toString() != values.toString() ||
      oldDelegate.maxValue != maxValue ||
      oldDelegate.line != line ||
      oldDelegate.grid != grid;
}
