import 'dart:io';

import 'package:flutter/material.dart';
import 'package:characters/characters.dart';

import '../models/person.dart';
import '../utils/color_utils.dart';

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
            color: Colors.black.withOpacityValue(0.1),
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
