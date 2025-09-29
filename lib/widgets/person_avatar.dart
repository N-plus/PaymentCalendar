import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:characters/characters.dart';

import '../models/person.dart';
import '../utils/color_utils.dart';

const Color kPersonAvatarBackgroundColor = Color(0xFFEEEEEE);

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

    return _PresetPersonAvatar(type: type, size: size);
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
  });

  final _PresetAvatarType type;
  final double size;

  static const Color _faceColor = Color(0xFFFFEB3B);
  static const Color _backgroundColor = Color(0xFFFFFDE7);

  Color get _hairColor {
    switch (type) {
      case _PresetAvatarType.child:
        return const Color(0xFF8D6E63);
      case _PresetAvatarType.mother:
        return const Color(0xFF6D4C41);
      case _PresetAvatarType.father:
        return const Color(0xFF4E342E);
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> hairBehind = _buildHairBehind();
    final List<Widget> hairFront = _buildHairFront();

    final double faceSize = size * 0.78;
    final List<Widget> features = [
      Align(
        alignment: const Alignment(-0.35, -0.05),
        child: _buildEye(),
      ),
      Align(
        alignment: const Alignment(0.35, -0.05),
        child: _buildEye(),
      ),
      Align(
        alignment: const Alignment(0, 0.38),
        child: SizedBox(
          width: size * 0.32,
          height: size * 0.2,
          child: CustomPaint(
            painter: _SmilePainter(
              color: Colors.black,
              strokeWidth: size * 0.07,
            ),
          ),
        ),
      ),
    ];

    final List<Widget> accessories = _buildAccessories();

    return SizedBox(
      width: size,
      height: size,
      child: ClipOval(
        child: Container(
          color: _backgroundColor,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              ...hairBehind,
              Align(
                alignment: Alignment.center,
                child: Container(
                  width: faceSize,
                  height: faceSize,
                  decoration: const BoxDecoration(
                    color: _faceColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              ...hairFront,
              ...accessories,
              ...features,
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildHairBehind() {
    if (type != _PresetAvatarType.mother) {
      return const [];
    }

    return [
      Align(
        alignment: Alignment.center,
        child: Container(
          width: size * 0.95,
          height: size * 0.95,
          decoration: BoxDecoration(
            color: _hairColor,
            borderRadius: BorderRadius.circular(size * 0.6),
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildHairFront() {
    switch (type) {
      case _PresetAvatarType.child:
        return [
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              margin: EdgeInsets.only(top: size * 0.12),
              width: size * 0.6,
              height: size * 0.3,
              decoration: BoxDecoration(
                color: _hairColor,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(size * 0.32),
                  bottomRight: Radius.circular(size * 0.32),
                  topLeft: Radius.circular(size * 0.5),
                  topRight: Radius.circular(size * 0.5),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: Transform.translate(
              offset: Offset(0, -size * 0.18),
              child: Container(
                width: size * 0.22,
                height: size * 0.28,
                decoration: BoxDecoration(
                  color: _hairColor,
                  borderRadius: BorderRadius.circular(size * 0.2),
                ),
              ),
            ),
          ),
        ];
      case _PresetAvatarType.mother:
        return [
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              margin: EdgeInsets.only(top: size * 0.02),
              width: size * 0.84,
              height: size * 0.5,
              decoration: BoxDecoration(
                color: _hairColor,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(size * 0.4),
                  bottomRight: Radius.circular(size * 0.4),
                  topLeft: Radius.circular(size * 0.45),
                  topRight: Radius.circular(size * 0.45),
                ),
              ),
            ),
          ),
        ];
      case _PresetAvatarType.father:
        return [
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              margin: EdgeInsets.only(top: size * 0.08),
              width: size * 0.78,
              height: size * 0.34,
              decoration: BoxDecoration(
                color: _hairColor,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(size * 0.35),
                  bottomRight: Radius.circular(size * 0.35),
                  topLeft: Radius.circular(size * 0.45),
                  topRight: Radius.circular(size * 0.45),
                ),
              ),
            ),
          ),
          Align(
            alignment: const Alignment(-0.7, -0.2),
            child: Container(
              width: size * 0.22,
              height: size * 0.16,
              decoration: BoxDecoration(
                color: _hairColor,
                borderRadius: BorderRadius.circular(size * 0.12),
              ),
            ),
          ),
          Align(
            alignment: const Alignment(0.7, -0.2),
            child: Container(
              width: size * 0.22,
              height: size * 0.16,
              decoration: BoxDecoration(
                color: _hairColor,
                borderRadius: BorderRadius.circular(size * 0.12),
              ),
            ),
          ),
        ];
    }
  }

  List<Widget> _buildAccessories() {
    if (type != _PresetAvatarType.father) {
      return const [];
    }

    final double lensSize = size * 0.32;
    final double bridgeHeight = size * 0.02;

    return [
      Align(
        alignment: const Alignment(-0.35, -0.02),
        child: Container(
          width: lensSize,
          height: lensSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.black,
              width: size * 0.05,
            ),
          ),
        ),
      ),
      Align(
        alignment: const Alignment(0.35, -0.02),
        child: Container(
          width: lensSize,
          height: lensSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.black,
              width: size * 0.05,
            ),
          ),
        ),
      ),
      Align(
        alignment: Alignment.center,
        child: Container(
          width: size * 0.14,
          height: bridgeHeight,
          color: Colors.black,
        ),
      ),
      Align(
        alignment: const Alignment(-0.85, -0.02),
        child: Container(
          width: size * 0.18,
          height: bridgeHeight,
          color: Colors.black,
        ),
      ),
      Align(
        alignment: const Alignment(0.85, -0.02),
        child: Container(
          width: size * 0.18,
          height: bridgeHeight,
          color: Colors.black,
        ),
      ),
    ];
  }

  Widget _buildEye() {
    return Container(
      width: size * 0.14,
      height: size * 0.14,
      decoration: const BoxDecoration(
        color: Colors.black,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _SmilePainter extends CustomPainter {
  const _SmilePainter({
    required this.color,
    required this.strokeWidth,
  });

  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final Rect rect = Rect.fromLTWH(
      0,
      strokeWidth,
      size.width,
      size.height,
    );

    canvas.drawArc(
      rect,
      math.pi * 0.15,
      math.pi - (math.pi * 0.3),
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _SmilePainter oldDelegate) {
    return color != oldDelegate.color || strokeWidth != oldDelegate.strokeWidth;
  }
}
