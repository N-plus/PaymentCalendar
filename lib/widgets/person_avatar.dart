import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:characters/characters.dart';

import '../models/person.dart';

const Color kPersonAvatarBackgroundColor = Color(0xFFF7F7FA);

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

    final presetAvatar = _buildPresetAvatar();
    if (presetAvatar != null) {
      return presetAvatar;
    }

    final placeholder = person.emoji?.isNotEmpty == true
        ? person.emoji!
        : (person.name.characters.isNotEmpty
            ? person.name.characters.first
            : '?');

    final theme = Theme.of(context);
    final Color resolvedBackground =
        backgroundColor ?? kPersonAvatarBackgroundColor;
    final TextStyle resolvedStyle = textStyle ??
        TextStyle(
          fontSize: size * 0.42,
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onSurface,
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

  Widget? _buildPresetAvatar() {
    final _PresetAvatarType? type = _PresetAvatarType.fromPerson(person);
    if (type == null) {
      return null;
    }

    return _PresetPersonAvatar(
      type: type,
      size: size,
      backgroundColor: backgroundColor,
    );
  }
}

enum _PresetAvatarType { child, mother, father;
  static _PresetAvatarType? fromPerson(Person person) {
    switch (person.id) {
      case 'child':
        return _PresetAvatarType.child;
      case 'mother':
        return _PresetAvatarType.mother;
      case 'father':
        return _PresetAvatarType.father;
    }
    return null;
  }
}

class _PresetPersonAvatar extends StatelessWidget {
  const _PresetPersonAvatar({
    required this.type,
    required this.size,
    this.backgroundColor,
  });

  final _PresetAvatarType type;
  final double size;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case _PresetAvatarType.child:
      case _PresetAvatarType.mother:
      case _PresetAvatarType.father:
        break;
    }

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _AvatarPainter(
          backgroundColor:
              backgroundColor ?? _AvatarPainter.kDefaultBackgroundColor,
        ),
      ),
    );
  }
}

class _AvatarPainter extends CustomPainter {
  const _AvatarPainter({required this.backgroundColor});

  final Color backgroundColor;

  static const Color kDefaultBackgroundColor = Color(0xFFF7F7FA);
  static const Color _faceColor = Color(0xFFFFE082);
  static const Color _outlineColor = Color(0xFF333333);
  static const Color _eyeColor = Color(0xFF000000);
  static const Color _mouthColor = Color(0xFF000000);

  static const double _faceDiameterFactor = 0.7;
  static const double _faceStrokeFactor = 2 / 32;
  static const double _eyeDiameterFactor = 0.12;
  static const double _eyeOffsetXFactor = 0.16;
  static const double _eyeOffsetYFactor = 0.08;
  static const double _mouthWidthFactor = 0.36;
  static const double _mouthHeightFactor = 0.22;
  static const double _mouthOffsetYFactor = 0.16;
  static const double _mouthStrokeFactor = 1.8 / 32;

  @override
  void paint(Canvas canvas, Size size) {
    final double dimension = math.min(size.width, size.height);
    final Offset center = Offset(size.width / 2, size.height / 2);

    final Paint backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    canvas.drawCircle(center, dimension / 2, backgroundPaint);

    final double faceDiameter = dimension * _faceDiameterFactor;
    final double faceRadius = faceDiameter / 2;

    final Paint facePaint = Paint()
      ..color = _faceColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    canvas.drawCircle(center, faceRadius, facePaint);

    final Paint outlinePaint = Paint()
      ..color = _outlineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = dimension * _faceStrokeFactor
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;
    canvas.drawCircle(center, faceRadius, outlinePaint);

    final Paint featurePaint = Paint()
      ..color = _eyeColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    final double eyeRadius = (dimension * _eyeDiameterFactor) / 2;
    final double eyeOffsetX = dimension * _eyeOffsetXFactor;
    final double eyeOffsetY = dimension * _eyeOffsetYFactor;

    canvas.drawCircle(
      center.translate(-eyeOffsetX, -eyeOffsetY),
      eyeRadius,
      featurePaint,
    );
    canvas.drawCircle(
      center.translate(eyeOffsetX, -eyeOffsetY),
      eyeRadius,
      featurePaint,
    );

    final Rect mouthRect = Rect.fromCenter(
      center: center.translate(0, dimension * _mouthOffsetYFactor),
      width: dimension * _mouthWidthFactor,
      height: dimension * _mouthHeightFactor,
    );
    final Paint mouthPaint = Paint()
      ..color = _mouthColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = dimension * _mouthStrokeFactor
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    canvas.drawArc(
      mouthRect,
      math.pi * 0.15,
      math.pi - (math.pi * 0.3),
      false,
      mouthPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _AvatarPainter oldDelegate) {
    return backgroundColor != oldDelegate.backgroundColor;
  }
}
