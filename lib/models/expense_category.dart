class ExpenseCategory {
  static const fallback = 'その他';

  static const defaults = <String>[
    '食費',
    '交通費',
    '日用品',
    '衣服',
    '趣味',
    '医療費',
    fallback,
  ];
}
