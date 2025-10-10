class Person {
  const Person({
    required this.id,
    required this.name,
    this.photoPath,
    this.emoji,
    this.iconAsset,
  });

  final String id;
  final String name;
  final String? photoPath;
  final String? emoji;
  final String? iconAsset;

  Person copyWith({
    String? name,
    Object? photoPath = _noValue,
    Object? emoji = _noValue,
    Object? iconAsset = _noValue,
  }) {
    return Person(
      id: id,
      name: name ?? this.name,
      photoPath: identical(photoPath, _noValue)
          ? this.photoPath
          : photoPath as String?,
      emoji: identical(emoji, _noValue) ? this.emoji : emoji as String?,
      iconAsset: identical(iconAsset, _noValue)
          ? this.iconAsset
          : iconAsset as String?,
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
        other.emoji == emoji &&
        other.iconAsset == iconAsset;
  }

  @override
  int get hashCode => Object.hash(id, name, photoPath, emoji, iconAsset);
}
