import 'dart:io';
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

enum _PresetAvatarType {
  mother,
  father;
  static _PresetAvatarType? fromPerson(Person person) {
    switch (person.id) {
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
    final Color resolvedBackgroundColor =
        backgroundColor ?? kPersonAvatarBackgroundColor;

    final String assetName;
    switch (type) {
      case _PresetAvatarType.mother:
        assetName = 'assets/images/mother.png';
        break;
      case _PresetAvatarType.father:
        assetName = 'assets/images/father.png';
        break;
    }

    return SizedBox(
      width: size,
      height: size,
      child: ClipOval(
        child: Container(
          color: resolvedBackgroundColor,
          child: Image.asset(
            assetName,
            width: size,
            height: size,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
