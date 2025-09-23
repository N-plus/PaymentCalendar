import 'package:equatable/equatable.dart';

class Person extends Equatable {
  const Person({
    required this.id,
    required this.name,
    this.photoPath,
    this.emoji,
  });

  final String id;
  final String name;
  final String? photoPath;
  final String? emoji;

  Person copyWith({
    String? name,
    String? photoPath,
    String? emoji,
  }) {
    return Person(
      id: id,
      name: name ?? this.name,
      photoPath: photoPath ?? this.photoPath,
      emoji: emoji ?? this.emoji,
    );
  }

  @override
  List<Object?> get props => [id, name, photoPath, emoji];
}
