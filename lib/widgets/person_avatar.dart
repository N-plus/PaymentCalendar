import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';

import '../models/person.dart';

class PersonAvatar extends StatelessWidget {
  const PersonAvatar({
    super.key,
    required this.person,
    this.size = 32,
    this.backgroundColor,
    this.textStyle,
    this.showShadow = false,
  });

  final Person person;
  final double size;
  final Color? backgroundColor;
  final TextStyle? textStyle;
  final bool showShadow;

  @override
  Widget build(BuildContext context) {
    final Widget content = _buildContent(context);

    if (!showShadow) {
      return content;
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: content,
    );
  }

  Widget _buildContent(BuildContext context) {
    final photoPath = person.photoPath;
    if (photoPath != null && photoPath.isNotEmpty) {
      final file = File(photoPath);
      if (file.existsSync()) {
        return SizedBox(
          width: size,
          height: size,
          child: ClipOval(
            child: Image.file(
              file,
              width: size,
              height: size,
              fit: BoxFit.cover,
            ),
          ),
        );
      }
    }

    final builtIn = _BuiltInIllustration.fromPerson(person);
    if (builtIn != null) {
      return builtIn.build(size);
    }

    final placeholder = person.emoji?.isNotEmpty == true
        ? person.emoji!
        : (person.name.characters.isNotEmpty
            ? person.name.characters.first
            : '?');

    final Color resolvedBackground = backgroundColor ??
        Theme.of(context).colorScheme.primaryContainer;
    final TextStyle resolvedStyle = textStyle ??
        TextStyle(
          fontSize: size * 0.42,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        );

    return SizedBox(
      width: size,
      height: size,
      child: ClipOval(
        child: Container(
          color: resolvedBackground,
          alignment: Alignment.center,
          child: Text(placeholder, style: resolvedStyle),
        ),
      ),
    );
  }
}

enum _IllustrationType { mother, father, child }

class _BuiltInIllustration {
  _BuiltInIllustration(this.type);

  final _IllustrationType type;

  static _BuiltInIllustration? fromPerson(Person person) {
    switch (person.id) {
      case 'mother':
        return _BuiltInIllustration(_IllustrationType.mother);
      case 'father':
        return _BuiltInIllustration(_IllustrationType.father);
      case 'child':
        return _BuiltInIllustration(_IllustrationType.child);
    }
    return null;
  }

  Widget build(double size) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _PersonIllustrationPainter(type),
      ),
    );
  }
}

class _PersonIllustrationPainter extends CustomPainter {
  _PersonIllustrationPainter(this.type);

  final _IllustrationType type;

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width / 2;
    final Offset center = Offset(radius, radius);

    final palette = _paletteFor(type);

    final Paint backgroundPaint = Paint()..color = palette.background;
    canvas.drawCircle(center, radius, backgroundPaint);

    final Rect bodyRect = Rect.fromCenter(
      center: Offset(center.dx, size.height * 0.88),
      width: size.width * 0.92,
      height: size.height * 0.7,
    );
    final Paint bodyPaint = Paint()..color = palette.body;
    canvas.drawOval(bodyRect, bodyPaint);

    final Rect faceRect = Rect.fromCircle(
      center: Offset(center.dx, size.height * 0.47),
      radius: size.width * 0.28,
    );
    final Paint facePaint = Paint()..color = const Color(0xFFFFE2C6);
    canvas.drawOval(faceRect, facePaint);

    final Path hairPath = Path();
    final double hairTop = size.height * 0.18;
    hairPath.moveTo(size.width * 0.18, size.height * 0.42);
    hairPath.quadraticBezierTo(
      size.width * 0.24,
      hairTop,
      center.dx,
      hairTop * 0.8,
    );
    hairPath.quadraticBezierTo(
      size.width * 0.76,
      hairTop,
      size.width * 0.82,
      size.height * 0.42,
    );
    hairPath.arcTo(
      Rect.fromCircle(
        center: Offset(center.dx, size.height * 0.46),
        radius: size.width * 0.32,
      ),
      -pi,
      pi,
      false,
    );
    hairPath.close();
    final Paint hairPaint = Paint()..color = palette.hair;
    canvas.drawPath(hairPath, hairPaint);

    if (type == _IllustrationType.father) {
      final Paint fringePaint = Paint()..color = palette.hairDark;
      final Path fringePath = Path()
        ..moveTo(center.dx - size.width * 0.18, size.height * 0.34)
        ..quadraticBezierTo(
          center.dx,
          size.height * 0.26,
          center.dx + size.width * 0.18,
          size.height * 0.34,
        )
        ..lineTo(center.dx + size.width * 0.12, size.height * 0.26)
        ..quadraticBezierTo(
          center.dx,
          size.height * 0.24,
          center.dx - size.width * 0.12,
          size.height * 0.26,
        )
        ..close();
      canvas.drawPath(fringePath, fringePaint);
    }

    if (type == _IllustrationType.mother) {
      final Paint bunPaint = Paint()..color = palette.hairDark;
      canvas.drawCircle(
        Offset(center.dx - size.width * 0.28, size.height * 0.22),
        size.width * 0.12,
        bunPaint,
      );
      canvas.drawCircle(
        Offset(center.dx + size.width * 0.28, size.height * 0.22),
        size.width * 0.12,
        bunPaint,
      );
    }

    if (type == _IllustrationType.child) {
      final Paint capPaint = Paint()..color = palette.hairDark;
      final Rect capRect = Rect.fromCenter(
        center: Offset(center.dx, size.height * 0.32),
        width: size.width * 0.74,
        height: size.height * 0.38,
      );
      canvas.drawArc(capRect, pi, pi, false, capPaint);
      final Paint brimPaint = Paint()
        ..color = palette.hairDark.withOpacity(0.9)
        ..strokeWidth = size.width * 0.08
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(center.dx, size.height * 0.37),
          width: size.width * 0.8,
          height: size.height * 0.44,
        ),
        pi,
        pi,
        false,
        brimPaint,
      );
    }

    final Paint eyePaint = Paint()
      ..color = palette.eye
      ..style = PaintingStyle.fill;
    final double eyeRadius = size.width * 0.04;
    canvas.drawCircle(
      Offset(center.dx - size.width * 0.1, size.height * 0.46),
      eyeRadius,
      eyePaint,
    );
    canvas.drawCircle(
      Offset(center.dx + size.width * 0.1, size.height * 0.46),
      eyeRadius,
      eyePaint,
    );

    final Paint smilePaint = Paint()
      ..color = palette.smile
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = size.width * 0.05;
    final Rect smileRect = Rect.fromCircle(
      center: Offset(center.dx, size.height * 0.56),
      radius: size.width * 0.18,
    );
    canvas.drawArc(smileRect, pi / 6, 2 * pi / 3, false, smilePaint);

    final Paint cheekPaint = Paint()..color = palette.cheek;
    final double cheekRadius = size.width * 0.05;
    canvas.drawCircle(
      Offset(center.dx - size.width * 0.2, size.height * 0.53),
      cheekRadius,
      cheekPaint,
    );
    canvas.drawCircle(
      Offset(center.dx + size.width * 0.2, size.height * 0.53),
      cheekRadius,
      cheekPaint,
    );
  }

  _AvatarPalette _paletteFor(_IllustrationType type) {
    switch (type) {
      case _IllustrationType.mother:
        return const _AvatarPalette(
          background: Color(0xFFFFF4E5),
          body: Color(0xFFFFB1C1),
          hair: Color(0xFF6B3F2B),
          hairDark: Color(0xFF4C2A1B),
          eye: Color(0xFF3C2716),
          cheek: Color(0xFFFFC7D1),
          smile: Color(0xFFE87A90),
        );
      case _IllustrationType.father:
        return const _AvatarPalette(
          background: Color(0xFFE9F2FF),
          body: Color(0xFF7FB4FF),
          hair: Color(0xFF2F3A4C),
          hairDark: Color(0xFF1F2835),
          eye: Color(0xFF222933),
          cheek: Color(0xFFB5D4FF),
          smile: Color(0xFF3B77CC),
        );
      case _IllustrationType.child:
        return const _AvatarPalette(
          background: Color(0xFFFFF9E7),
          body: Color(0xFFFFD66B),
          hair: Color(0xFF5A3B20),
          hairDark: Color(0xFF8B4F1F),
          eye: Color(0xFF3A2210),
          cheek: Color(0xFFFFE0A8),
          smile: Color(0xFFE28A40),
        );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AvatarPalette {
  const _AvatarPalette({
    required this.background,
    required this.body,
    required this.hair,
    required this.hairDark,
    required this.eye,
    required this.cheek,
    required this.smile,
  });

  final Color background;
  final Color body;
  final Color hair;
  final Color hairDark;
  final Color eye;
  final Color cheek;
  final Color smile;
}
