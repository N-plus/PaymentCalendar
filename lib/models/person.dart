class Person {
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
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is Person &&
        other.id == id &&
        other.name == name &&
        other.photoPath == photoPath &&
        other.emoji == emoji;
  }

  @override
  int get hashCode => Object.hash(id, name, photoPath, emoji);
}
