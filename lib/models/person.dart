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
    Object? photoPath = _noValue,
    Object? emoji = _noValue,
  }) {
    return Person(
      id: id,
      name: name ?? this.name,
      photoPath: identical(photoPath, _noValue)
          ? this.photoPath
          : photoPath as String?,
      emoji: identical(emoji, _noValue) ? this.emoji : emoji as String?,
    );
  }

  static const Object _noValue = Object();

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
