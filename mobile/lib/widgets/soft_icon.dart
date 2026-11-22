import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Uygulamanin kendi ikon seti.
///
/// Material ikonlari yerine elle cizilmis, yumusak ve yuvarlak uclu sekiller
/// kullanilir; boylece arayuz hazir bir sablona degil kendi kimligine benzer.
/// Tum sekiller 24x24 bir tuvale gore tanimlanir ve istenen boyuta olceklenir.
enum AppIcon {
  home,
  inbox,
  urgent,
  calendar,
  settings,
  phone,
  phoneBack,
  phoneEnd,
  mic,
  micOff,
  check,
  trash,
  globe,
  close,
  chevron,
  clock,
  cloud,
  cloudOff,
  copy,
  undo,
  bell,
  link,
  sun,
  moon,
  auto,
  wave,
  layers,
  spark,
  search,
  bulb,
  calendarOk,
  calendarOff,
}

/// Tek bir ikon. Cizgi kalinligi boyutla birlikte orantili buyur.
class SoftIcon extends StatelessWidget {
  const SoftIcon(this.icon, {super.key, this.size = 22, this.color, this.solid = false});

  final AppIcon icon;
  final double size;
  final Color? color;

  /// Dolu bicem: sekil ici doldurulur, ayrintilar beyaz bosluk olarak kalir.
  /// Alt menu ve cagri ekrani gibi ikonun tek basina durdugu yerlerde kullanilir.
  final bool solid;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _SoftIconPainter(
          icon: icon,
          color: color ?? context.text.bodyMedium?.color ?? Colors.black87,
          solid: solid,
        ),
      ),
    );
  }
}

/// Ikonu dairesel, ince degradeli bir halkanin icine yerlestirir.
///
/// Kare kutucuklar kart koselerinin tekrari gibi duruyordu; daire hem
/// kureyle ayni dili konusur hem de listede ikonu daha net ayirir.
class SoftIconTile extends StatelessWidget {
  const SoftIconTile({
    super.key,
    required this.icon,
    required this.color,
    this.size = 44,
    this.solid = true,
  });

  final AppIcon icon;
  final Color color;
  final double size;
  final bool solid;

  @override
  Widget build(BuildContext context) {
    final dark = context.tokens.isDark;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.3, -0.4),
          colors: [
            color.withValues(alpha: dark ? 0.26 : 0.18),
            color.withValues(alpha: dark ? 0.08 : 0.07),
          ],
        ),
        border: Border.all(
          color: color.withValues(alpha: dark ? 0.42 : 0.26),
          width: 1.1,
        ),
        boxShadow: dark
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.22),
                  blurRadius: size * 0.42,
                ),
              ]
            : null,
      ),
      child: Center(
        child: SoftIcon(
          icon,
          size: size * 0.46,
          color: dark ? Color.lerp(color, Colors.white, 0.28)! : color,
          solid: solid,
        ),
      ),
    );
  }
}

class _SoftIconPainter extends CustomPainter {
  _SoftIconPainter({required this.icon, required this.color, this.solid = false});

  final AppIcon icon;
  final Color color;
  final bool solid;

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 24.0;
    canvas.save();
    canvas.scale(k, k);

    if (solid && _paintSolid(canvas)) {
      canvas.restore();
      return;
    }

    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()..color = color;

    void line(double x1, double y1, double x2, double y2) =>
        canvas.drawLine(Offset(x1, y1), Offset(x2, y2), stroke);
    void dot(double x, double y, [double r = 1.3]) =>
        canvas.drawCircle(Offset(x, y), r, fill);
    void rrect(double l, double t, double r, double b, double radius) =>
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTRB(l, t, r, b),
            Radius.circular(radius),
          ),
          stroke,
        );
    void path(Path p) => canvas.drawPath(p, stroke);

    switch (icon) {
      case AppIcon.home:
        path(Path()
          ..moveTo(4, 10.5)
          ..lineTo(12, 4)
          ..lineTo(20, 10.5)
          ..lineTo(20, 18)
          ..quadraticBezierTo(20, 20, 18, 20)
          ..lineTo(6, 20)
          ..quadraticBezierTo(4, 20, 4, 18)
          ..close());
        path(Path()
          ..moveTo(9.5, 20)
          ..lineTo(9.5, 14.5)
          ..quadraticBezierTo(9.5, 13.5, 10.5, 13.5)
          ..lineTo(13.5, 13.5)
          ..quadraticBezierTo(14.5, 13.5, 14.5, 14.5)
          ..lineTo(14.5, 20));
      case AppIcon.inbox:
        rrect(3.5, 5, 20.5, 19, 4);
        path(Path()
          ..moveTo(3.5, 13)
          ..lineTo(8.5, 13)
          ..lineTo(10, 15.5)
          ..lineTo(14, 15.5)
          ..lineTo(15.5, 13)
          ..lineTo(20.5, 13));
        line(8, 9, 16, 9);
      case AppIcon.urgent:
        // Yumusak bir alev/simsek karisimi: dikkat ceker ama sert degil.
        path(Path()
          ..moveTo(13.5, 3)
          ..quadraticBezierTo(14, 7, 11, 10.5)
          ..lineTo(14.5, 10.5)
          ..quadraticBezierTo(14, 16, 10, 21)
          ..quadraticBezierTo(10.5, 15.5, 13, 13)
          ..lineTo(9.5, 13)
          ..quadraticBezierTo(10.5, 7.5, 13.5, 3)
          ..close());
      case AppIcon.calendar:
        rrect(3.5, 5.5, 20.5, 20, 4.5);
        line(3.5, 10.5, 20.5, 10.5);
        line(8, 3.5, 8, 7);
        line(16, 3.5, 16, 7);
        dot(8.5, 14.5);
        dot(12, 14.5);
        dot(15.5, 14.5);
      case AppIcon.calendarOk:
        rrect(3.5, 5.5, 20.5, 20, 4.5);
        line(3.5, 10.5, 20.5, 10.5);
        line(8, 3.5, 8, 7);
        line(16, 3.5, 16, 7);
        path(Path()
          ..moveTo(8.5, 15.3)
          ..lineTo(11, 17.6)
          ..lineTo(15.8, 13));
      case AppIcon.calendarOff:
        rrect(3.5, 5.5, 20.5, 20, 4.5);
        line(3.5, 10.5, 20.5, 10.5);
        line(8, 3.5, 8, 7);
        line(16, 3.5, 16, 7);
        line(9.5, 13.5, 14.5, 17.5);
        line(14.5, 13.5, 9.5, 17.5);
      case AppIcon.settings:
        // Dis disli yerine uc kademeli bir ayar paneli: daha sakin durur.
        line(4, 7.5, 20, 7.5);
        line(4, 12, 20, 12);
        line(4, 16.5, 20, 16.5);
        canvas.drawCircle(const Offset(9, 7.5), 2.6, Paint()..color = color.withValues(alpha: 0.14));
        canvas.drawCircle(const Offset(9, 7.5), 2.6, stroke);
        canvas.drawCircle(const Offset(15, 12), 2.6, Paint()..color = color.withValues(alpha: 0.14));
        canvas.drawCircle(const Offset(15, 12), 2.6, stroke);
        canvas.drawCircle(const Offset(10.5, 16.5), 2.6, Paint()..color = color.withValues(alpha: 0.14));
        canvas.drawCircle(const Offset(10.5, 16.5), 2.6, stroke);
      case AppIcon.phone:
        path(Path()
          ..moveTo(7.5, 4.5)
          ..quadraticBezierTo(9.5, 4.5, 10, 7)
          ..lineTo(10.4, 9)
          ..quadraticBezierTo(10.6, 10.2, 9.5, 11)
          ..quadraticBezierTo(11, 14.2, 13.8, 15.5)
          ..quadraticBezierTo(14.6, 14.2, 15.8, 14.5)
          ..lineTo(17.6, 15)
          ..quadraticBezierTo(19.6, 15.6, 19.5, 17.5)
          ..quadraticBezierTo(19.3, 20, 16.5, 20)
          ..quadraticBezierTo(4, 19, 4, 7.5)
          ..quadraticBezierTo(4.2, 4.6, 7.5, 4.5)
          ..close());
      case AppIcon.phoneBack:
        path(Path()
          ..moveTo(7.5, 7.5)
          ..quadraticBezierTo(9, 7.5, 9.6, 9.6)
          ..quadraticBezierTo(10, 11, 9, 11.8)
          ..quadraticBezierTo(10.4, 14.4, 12.8, 15.5)
          ..quadraticBezierTo(13.6, 14.4, 15, 14.8)
          ..quadraticBezierTo(17.2, 15.4, 17.2, 17.2)
          ..quadraticBezierTo(17, 19.4, 14.6, 19.4)
          ..quadraticBezierTo(4.6, 18.6, 4.6, 10)
          ..quadraticBezierTo(4.8, 7.6, 7.5, 7.5)
          ..close());
        path(Path()
          ..moveTo(20, 8.5)
          ..lineTo(14.5, 8.5));
        path(Path()
          ..moveTo(17, 5.5)
          ..lineTo(14.2, 8.5)
          ..lineTo(17, 11.5));
      case AppIcon.phoneEnd:
        path(Path()
          ..moveTo(3.5, 14.5)
          ..quadraticBezierTo(12, 8.5, 20.5, 14.5));
        path(Path()
          ..moveTo(6.2, 12.9)
          ..lineTo(5.2, 16.4));
        path(Path()
          ..moveTo(17.8, 12.9)
          ..lineTo(18.8, 16.4));
      case AppIcon.mic:
        rrect(9, 3, 15, 14, 3);
        path(Path()
          ..moveTo(5.5, 11.5)
          ..quadraticBezierTo(5.5, 18, 12, 18)
          ..quadraticBezierTo(18.5, 18, 18.5, 11.5));
        line(12, 18, 12, 21);
      case AppIcon.micOff:
        rrect(9, 3, 15, 14, 3);
        path(Path()
          ..moveTo(5.5, 11.5)
          ..quadraticBezierTo(5.5, 18, 12, 18)
          ..quadraticBezierTo(18.5, 18, 18.5, 11.5));
        line(12, 18, 12, 21);
        line(4, 3.5, 20, 20.5);
      case AppIcon.check:
        path(Path()
          ..moveTo(5, 12.8)
          ..lineTo(9.8, 17.5)
          ..lineTo(19, 7));
      case AppIcon.trash:
        path(Path()
          ..moveTo(5.5, 7.5)
          ..lineTo(18.5, 7.5));
        path(Path()
          ..moveTo(7.5, 7.5)
          ..lineTo(8.3, 19)
          ..quadraticBezierTo(8.4, 20.5, 10, 20.5)
          ..lineTo(14, 20.5)
          ..quadraticBezierTo(15.6, 20.5, 15.7, 19)
          ..lineTo(16.5, 7.5));
        path(Path()
          ..moveTo(9.5, 7.5)
          ..quadraticBezierTo(9.5, 4, 12, 4)
          ..quadraticBezierTo(14.5, 4, 14.5, 7.5));
      case AppIcon.globe:
        canvas.drawCircle(const Offset(12, 12), 8.2, stroke);
        path(Path()
          ..moveTo(12, 3.8)
          ..quadraticBezierTo(7.8, 12, 12, 20.2)
          ..quadraticBezierTo(16.2, 12, 12, 3.8));
        line(4.2, 12, 19.8, 12);
      case AppIcon.close:
        line(6.5, 6.5, 17.5, 17.5);
        line(17.5, 6.5, 6.5, 17.5);
      case AppIcon.chevron:
        path(Path()
          ..moveTo(9.5, 5.5)
          ..lineTo(16, 12)
          ..lineTo(9.5, 18.5));
      case AppIcon.clock:
        canvas.drawCircle(const Offset(12, 12), 8.2, stroke);
        path(Path()
          ..moveTo(12, 7.2)
          ..lineTo(12, 12.4)
          ..lineTo(15.6, 14.4));
      case AppIcon.cloud:
        path(Path()
          ..moveTo(7.5, 18)
          ..quadraticBezierTo(3.5, 18, 3.5, 14.2)
          ..quadraticBezierTo(3.5, 10.8, 7, 10.4)
          ..quadraticBezierTo(8, 6, 12.5, 6)
          ..quadraticBezierTo(16.8, 6, 17.3, 10.6)
          ..quadraticBezierTo(20.5, 11, 20.5, 14.3)
          ..quadraticBezierTo(20.5, 18, 16.8, 18)
          ..close());
      case AppIcon.cloudOff:
        path(Path()
          ..moveTo(7.5, 18)
          ..quadraticBezierTo(3.5, 18, 3.5, 14.2)
          ..quadraticBezierTo(3.5, 10.8, 7, 10.4)
          ..quadraticBezierTo(8, 6, 12.5, 6)
          ..quadraticBezierTo(16.8, 6, 17.3, 10.6)
          ..quadraticBezierTo(20.5, 11, 20.5, 14.3)
          ..quadraticBezierTo(20.5, 18, 16.8, 18)
          ..close());
        line(4.5, 4, 19.5, 20);
      case AppIcon.copy:
        rrect(8.5, 3.5, 20.5, 15.5, 3.5);
        path(Path()
          ..moveTo(15.5, 19)
          ..quadraticBezierTo(15.5, 20.5, 14, 20.5)
          ..lineTo(5, 20.5)
          ..quadraticBezierTo(3.5, 20.5, 3.5, 19)
          ..lineTo(3.5, 10)
          ..quadraticBezierTo(3.5, 8.5, 5, 8.5));
      case AppIcon.undo:
        path(Path()
          ..moveTo(4, 9.5)
          ..lineTo(9.5, 9.5)
          ..lineTo(9.5, 4));
        path(Path()
          ..moveTo(4.6, 9.8)
          ..quadraticBezierTo(9, 4.5, 14.5, 7)
          ..quadraticBezierTo(21, 10, 18.5, 17)
          ..quadraticBezierTo(16.5, 21, 11, 20));
      case AppIcon.bell:
        path(Path()
          ..moveTo(6, 17)
          ..quadraticBezierTo(7.5, 15.5, 7.5, 11.5)
          ..quadraticBezierTo(7.5, 5, 12, 5)
          ..quadraticBezierTo(16.5, 5, 16.5, 11.5)
          ..quadraticBezierTo(16.5, 15.5, 18, 17)
          ..close());
        path(Path()
          ..moveTo(10, 19)
          ..quadraticBezierTo(12, 21.2, 14, 19));
      case AppIcon.link:
        path(Path()
          ..moveTo(10.5, 13.5)
          ..quadraticBezierTo(13, 16, 15.5, 13.5)
          ..lineTo(18.5, 10.5)
          ..quadraticBezierTo(21, 8, 18.5, 5.5)
          ..quadraticBezierTo(16, 3, 13.5, 5.5)
          ..lineTo(12, 7));
        path(Path()
          ..moveTo(13.5, 10.5)
          ..quadraticBezierTo(11, 8, 8.5, 10.5)
          ..lineTo(5.5, 13.5)
          ..quadraticBezierTo(3, 16, 5.5, 18.5)
          ..quadraticBezierTo(8, 21, 10.5, 18.5)
          ..lineTo(12, 17));
      case AppIcon.sun:
        canvas.drawCircle(const Offset(12, 12), 4.4, stroke);
        for (var i = 0; i < 8; i++) {
          final a = i * math.pi / 4;
          line(12 + math.cos(a) * 7, 12 + math.sin(a) * 7,
              12 + math.cos(a) * 9.2, 12 + math.sin(a) * 9.2);
        }
      case AppIcon.moon:
        path(Path()
          ..moveTo(19, 14.5)
          ..quadraticBezierTo(11, 18, 8, 11)
          ..quadraticBezierTo(6.2, 6.5, 11, 3.8)
          ..quadraticBezierTo(4, 6, 5, 13.5)
          ..quadraticBezierTo(6.4, 21.5, 14.5, 20.5)
          ..quadraticBezierTo(18, 20, 19, 14.5)
          ..close());
      case AppIcon.auto:
        canvas.drawCircle(const Offset(12, 12), 8.2, stroke);
        path(Path()
          ..moveTo(12, 3.8)
          ..quadraticBezierTo(20.2, 3.8, 20.2, 12)
          ..quadraticBezierTo(20.2, 20.2, 12, 20.2)
          ..close());
      case AppIcon.wave:
        // Ses dalgasi: ortadan kenarlara dogru alcalan cubuklar.
        const heights = [4.0, 8.0, 12.5, 16.0, 12.5, 8.0, 4.0];
        for (var i = 0; i < heights.length; i++) {
          final x = 4.0 + i * 2.7;
          final h = heights[i];
          line(x, 12 - h / 2, x, 12 + h / 2);
        }
      case AppIcon.layers:
        path(Path()
          ..moveTo(12, 3.5)
          ..lineTo(20.5, 8)
          ..lineTo(12, 12.5)
          ..lineTo(3.5, 8)
          ..close());
        path(Path()
          ..moveTo(3.5, 12.5)
          ..lineTo(12, 17)
          ..lineTo(20.5, 12.5));
        path(Path()
          ..moveTo(3.5, 16.5)
          ..lineTo(12, 21)
          ..lineTo(20.5, 16.5));
      case AppIcon.bulb:
        // Ampul: fikir ve "asistan hazir" hissi icin acilis ekraninda durur.
        path(Path()
          ..moveTo(8.6, 14.6)
          ..quadraticBezierTo(5.2, 12.2, 6.2, 8.4)
          ..quadraticBezierTo(7.3, 4.2, 12, 4.2)
          ..quadraticBezierTo(16.7, 4.2, 17.8, 8.4)
          ..quadraticBezierTo(18.8, 12.2, 15.4, 14.6)
          ..lineTo(15.4, 16.2)
          ..quadraticBezierTo(15.4, 17.2, 14.4, 17.2)
          ..lineTo(9.6, 17.2)
          ..quadraticBezierTo(8.6, 17.2, 8.6, 16.2)
          ..close());
        line(9.8, 19.6, 14.2, 19.6);
        line(10.6, 21.6, 13.4, 21.6);
        line(12, 9, 12, 14.4);
        line(12, 11.2, 10.2, 9.4);
        line(12, 11.2, 13.8, 9.4);
      case AppIcon.search:
        canvas.drawCircle(const Offset(10.8, 10.8), 6.3, stroke);
        line(15.4, 15.4, 20, 20);
      case AppIcon.spark:
        path(Path()
          ..moveTo(12, 3.5)
          ..quadraticBezierTo(13, 10, 19.5, 11.5)
          ..quadraticBezierTo(13, 13, 12, 19.5)
          ..quadraticBezierTo(11, 13, 4.5, 11.5)
          ..quadraticBezierTo(11, 10, 12, 3.5)
          ..close());
    }

    canvas.restore();
  }

  /// Dolu bicem. Destekledigi ikonlarda true doner; aksi halde ince cizgili
  /// bicem devreye girer, boylece set eksik kalmaz.
  bool _paintSolid(Canvas canvas) {
    final body = Paint()..color = color;
    final cut = Paint()..blendMode = BlendMode.clear;

    void shape(Path p) => canvas.drawPath(p, body);
    void knockRRect(double l, double tp, double r, double b, double rad) =>
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTRB(l, tp, r, b),
            Radius.circular(rad),
          ),
          cut,
        );

    // Beyaz bosluklar icin ayri bir katman: BlendMode.clear ancak katman
    // icinde dogru calisir.
    canvas.saveLayer(const Rect.fromLTWH(0, 0, 24, 24), Paint());

    switch (icon) {
      case AppIcon.home:
        shape(Path()
          ..moveTo(12, 3.2)
          ..lineTo(21, 10.4)
          ..quadraticBezierTo(21.4, 10.8, 21, 11.3)
          ..quadraticBezierTo(20.5, 11.8, 20, 11.4)
          ..lineTo(20, 18.2)
          ..quadraticBezierTo(20, 20.8, 17.4, 20.8)
          ..lineTo(6.6, 20.8)
          ..quadraticBezierTo(4, 20.8, 4, 18.2)
          ..lineTo(4, 11.4)
          ..quadraticBezierTo(3.5, 11.8, 3, 11.3)
          ..quadraticBezierTo(2.6, 10.8, 3, 10.4)
          ..close());
        knockRRect(9.4, 13.4, 14.6, 21.4, 2.2);
      case AppIcon.urgent:
        shape(Path()
          ..moveTo(14.2, 2.4)
          ..quadraticBezierTo(14.8, 7.4, 11.2, 10.4)
          ..lineTo(15.2, 10.4)
          ..quadraticBezierTo(15.4, 11.4, 14.6, 12.4)
          ..lineTo(9, 21.6)
          ..quadraticBezierTo(9.4, 15.4, 12.4, 13.2)
          ..lineTo(8.6, 13.2)
          ..quadraticBezierTo(8.4, 12.2, 9, 11.2)
          ..close());
      case AppIcon.calendar:
        shape(Path()
          ..addRRect(RRect.fromRectAndRadius(
              const Rect.fromLTRB(3, 5, 21, 21), const Radius.circular(5))));
        knockRRect(3, 8.6, 21, 10.4, 0);
        knockRRect(7.2, 2.6, 9, 7, 0.9);
        knockRRect(15, 2.6, 16.8, 7, 0.9);
        for (final x in [7.6, 11.4, 15.2]) {
          canvas.drawCircle(Offset(x + 0.5, 14.2), 1.25, cut);
          canvas.drawCircle(Offset(x + 0.5, 17.8), 1.25, cut);
        }
      case AppIcon.settings:
        for (final y in [6.6, 12.0, 17.4]) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTRB(3, y - 0.95, 21, y + 0.95),
              const Radius.circular(1),
            ),
            body,
          );
        }
        canvas.drawCircle(const Offset(8.4, 6.6), 3.1, body);
        canvas.drawCircle(const Offset(8.4, 6.6), 1.5, cut);
        canvas.drawCircle(const Offset(15.6, 12.0), 3.1, body);
        canvas.drawCircle(const Offset(15.6, 12.0), 1.5, cut);
        canvas.drawCircle(const Offset(10.2, 17.4), 3.1, body);
        canvas.drawCircle(const Offset(10.2, 17.4), 1.5, cut);
      case AppIcon.phone:
        shape(Path()
          ..moveTo(7.2, 3.4)
          ..quadraticBezierTo(9.8, 3.4, 10.5, 6.8)
          ..lineTo(11, 9.2)
          ..quadraticBezierTo(11.3, 10.8, 9.6, 11.8)
          ..quadraticBezierTo(11.4, 14.6, 13.6, 15.7)
          ..quadraticBezierTo(14.8, 14.2, 16.3, 14.6)
          ..lineTo(18.6, 15.2)
          ..quadraticBezierTo(21.2, 16, 21, 18.4)
          ..quadraticBezierTo(20.7, 21.4, 17, 21.3)
          ..quadraticBezierTo(2.8, 20, 2.9, 7)
          ..quadraticBezierTo(3.2, 3.5, 7.2, 3.4)
          ..close());
      case AppIcon.mic:
        shape(Path()
          ..addRRect(RRect.fromRectAndRadius(
              const Rect.fromLTRB(8.8, 2.4, 15.2, 14.2),
              const Radius.circular(3.2))));
        shape(Path()
          ..moveTo(5, 11)
          ..quadraticBezierTo(5, 18.4, 11, 18.9)
          ..lineTo(11, 21.6)
          ..lineTo(13, 21.6)
          ..lineTo(13, 18.9)
          ..quadraticBezierTo(19, 18.4, 19, 11)
          ..lineTo(17, 11)
          ..quadraticBezierTo(17, 17, 12, 17)
          ..quadraticBezierTo(7, 17, 7, 11)
          ..close());
      case AppIcon.inbox:
        shape(Path()
          ..addRRect(RRect.fromRectAndRadius(
              const Rect.fromLTRB(3, 4.6, 21, 19.6),
              const Radius.circular(4.4))));
        shape(Path()
          ..moveTo(3, 12.6)
          ..lineTo(8.6, 12.6)
          ..lineTo(10.1, 15.2)
          ..lineTo(13.9, 15.2)
          ..lineTo(15.4, 12.6)
          ..lineTo(21, 12.6)
          ..close());
        knockRRect(3, 12.6, 8.2, 13.6, 0);
        knockRRect(15.8, 12.6, 21, 13.6, 0);
        knockRRect(8.2, 13.2, 15.8, 14.2, 0);
      default:
        canvas.restore();
        return false;
    }

    canvas.restore();
    return true;
  }

  @override
  bool shouldRepaint(_SoftIconPainter old) =>
      old.icon != icon || old.color != color || old.solid != solid;
}
