import 'dart:io';

import 'package:flutter/material.dart';

import '../models/person.dart';

class PersonAvatar extends StatelessWidget {
  const PersonAvatar({
    super.key,
    required this.person,
    this.size = 48,
  });

  final Person person;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (person.avatarType == AvatarType.photo && person.photoUri != null) {
      final file = File(person.photoUri!);
      if (file.existsSync()) {
        return CircleAvatar(
          radius: size / 2,
          backgroundImage: FileImage(file),
        );
      }
    }
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      child: Text(
        person.iconKey ?? '👤',
        style: TextStyle(fontSize: size / 2),
      ),
    );
  }
}
