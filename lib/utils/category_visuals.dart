import 'package:flutter/material.dart';

class CategoryVisual {
  const CategoryVisual({required this.icon, required this.color});

  final IconData icon;
  final Color color;
}

CategoryVisual categoryVisualFor(String category) {
  switch (category) {
    case '食費':
      return const CategoryVisual(
        icon: Icons.restaurant,
        color: Colors.orange,
      );
    case '交通費':
      return const CategoryVisual(
        icon: Icons.train,
        color: Colors.indigo,
      );
    case '日用品':
      return const CategoryVisual(
        icon: Icons.shopping_bag,
        color: Colors.teal,
      );
    case '衣服':
      return const CategoryVisual(
        icon: Icons.checkroom,
        color: Colors.purple,
      );
    case '趣味':
      return const CategoryVisual(
        icon: Icons.book,
        color: Colors.blue,
      );
    case '医療費':
      return const CategoryVisual(
        icon: Icons.local_hospital,
        color: Colors.red,
      );
    default:
      return const CategoryVisual(
        icon: Icons.category,
        color: Colors.grey,
      );
  }
}
