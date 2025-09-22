import 'dart:convert';

class Expense {
  Expense({
    required this.id,
    required this.date,
    required this.personId,
    required this.amount,
    this.memo,
    this.isPaid = false,
    this.paidAt,
    List<String>? photoUris,
    bool? isPlanned,
  }) : photoUris = photoUris ?? <String>[] {
    this.isPlanned = isPlanned ?? date.isAfter(_today());
  }

  final String id;
  DateTime date;
  String personId;
  int amount;
  String? memo;
  bool isPaid;
  DateTime? paidAt;
  late bool isPlanned;
  List<String> photoUris;

  Expense copyWith({
    DateTime? date,
    String? personId,
    int? amount,
    String? memo,
    bool? isPaid,
    DateTime? paidAt,
    List<String>? photoUris,
    bool? isPlanned,
  }) {
    final updated = Expense(
      id: id,
      date: date ?? this.date,
      personId: personId ?? this.personId,
      amount: amount ?? this.amount,
      memo: memo ?? this.memo,
      isPaid: isPaid ?? this.isPaid,
      paidAt: paidAt ?? this.paidAt,
      photoUris: photoUris ?? List<String>.from(this.photoUris),
      isPlanned: isPlanned ?? this.isPlanned,
    );
    return updated;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'personId': personId,
      'amount': amount,
      'memo': memo,
      'isPaid': isPaid,
      'paidAt': paidAt?.toIso8601String(),
      'photoUris': photoUris,
      'isPlanned': isPlanned,
    };
  }

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      personId: json['personId'] as String,
      amount: json['amount'] as int,
      memo: json['memo'] as String?,
      isPaid: json['isPaid'] as bool? ?? false,
      paidAt: json['paidAt'] == null
          ? null
          : DateTime.tryParse(json['paidAt'] as String),
      photoUris: (json['photoUris'] as List<dynamic>? ?? const [])
          .map((dynamic e) => e as String)
          .toList(),
      isPlanned: json['isPlanned'] as bool?,
    );
  }

  static List<Expense> listFromJson(String? jsonString) {
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }
    final List<dynamic> data = jsonDecode(jsonString) as List<dynamic>;
    return data.map((dynamic e) => Expense.fromJson(e as Map<String, dynamic>)).toList();
  }

  static String listToJson(List<Expense> expenses) {
    final data = expenses.map((e) => e.toJson()).toList();
    return jsonEncode(data);
  }

  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }
}
