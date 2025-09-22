import 'dart:convert';

enum AvatarType { photo, icon }

class Person {
  Person({
    required this.id,
    required this.name,
    required this.avatarType,
    this.photoUri,
    this.iconKey,
  });

  final String id;
  String name;
  AvatarType avatarType;
  String? photoUri;
  String? iconKey;

  Person copyWith({
    String? name,
    AvatarType? avatarType,
    String? photoUri,
    String? iconKey,
  }) {
    return Person(
      id: id,
      name: name ?? this.name,
      avatarType: avatarType ?? this.avatarType,
      photoUri: photoUri ?? this.photoUri,
      iconKey: iconKey ?? this.iconKey,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatarType': avatarType.name,
      'photoUri': photoUri,
      'iconKey': iconKey,
    };
  }

  factory Person.fromJson(Map<String, dynamic> json) {
    return Person(
      id: json['id'] as String,
      name: json['name'] as String,
      avatarType: AvatarType.values.firstWhere(
        (type) => type.name == json['avatarType'],
        orElse: () => AvatarType.icon,
      ),
      photoUri: json['photoUri'] as String?,
      iconKey: json['iconKey'] as String?,
    );
  }

  static List<Person> listFromJson(String? jsonString) {
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }
    final List<dynamic> data = jsonDecode(jsonString) as List<dynamic>;
    return data.map((dynamic item) => Person.fromJson(item as Map<String, dynamic>)).toList();
  }

  static String listToJson(List<Person> persons) {
    final data = persons.map((p) => p.toJson()).toList();
    return jsonEncode(data);
  }
}
