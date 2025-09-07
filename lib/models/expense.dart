class Expense {
  Expense({
    required this.date,
    required this.amount,
    required this.category,
    required this.person,
    this.isPaid = false,
  });

  DateTime date;
  int amount;
  String category;
  String person;
  bool isPaid;
}

class Member {
  Member({required this.name, required this.icon});

  String name;
  String icon;
}
