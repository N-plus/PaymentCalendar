class Expense {
  Expense({
    required this.date,
    required this.amount,
    required this.category,
    required this.person,
    required this.personIcon,
    this.isPaid = false,
  });

  DateTime date;
  int amount;
  String category;
  String person;
  String personIcon;
  bool isPaid;
}

class Member {
  Member({required this.name, required this.icon});

  String name;
  String icon;
}
