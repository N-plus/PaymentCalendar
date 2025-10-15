import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'expense_category.dart';

enum ExpenseStatus { unpaid, planned, paid }

class Expense {
  const Expense({
    required this.id,
    required this.payerId,
    required this.payeeId,
    required this.date,
    required this.amount,
    required this.memo,
    required this.status,
    required this.category,
    this.photoPaths = const <String>[],
    this.paidAt,
    required this.createdAt,
  });

  factory Expense.newRecord({
    required String id,
    required String payerId,
    required String payeeId,
    required DateTime date,
    required int amount,
    String memo = '',
    String? category,
    List<String> photoPaths = const <String>[],
  }) {
    final now = DateUtils.dateOnly(DateTime.now());
    final status = _statusFor(date, false, now: now);
    return Expense(
      id: id,
      payerId: payerId,
      payeeId: payeeId,
      date: date,
      amount: amount,
      memo: memo,
      status: status,
      category: (category == null || category.isEmpty)
          ? ExpenseCategory.fallback
          : category,
      photoPaths: List<String>.unmodifiable(photoPaths),
      createdAt: DateTime.now(),
    );
  }

  final String id;
  final String payerId;
  final String payeeId;
  final DateTime date;
  final int amount;
  final String memo;
  final ExpenseStatus status;
  final String category;
  final List<String> photoPaths;
  final DateTime? paidAt;
  final DateTime createdAt;

  bool get isPaid => status == ExpenseStatus.paid;
  bool get isPlanned => status == ExpenseStatus.planned;
  bool get isUnpaid => status == ExpenseStatus.unpaid;

  Expense copyWith({
    String? id,
    String? payerId,
    String? payeeId,
    DateTime? date,
    int? amount,
    String? memo,
    ExpenseStatus? status,
    String? category,
    List<String>? photoPaths,
    DateTime? paidAt,
    DateTime? createdAt,
  }) {
    return Expense(
      id: id ?? this.id,
      payerId: payerId ?? this.payerId,
      payeeId: payeeId ?? this.payeeId,
      date: date ?? this.date,
      amount: amount ?? this.amount,
      memo: memo ?? this.memo,
      status: status ?? this.status,
      category: category ?? this.category,
      photoPaths: photoPaths != null
          ? List<String>.unmodifiable(photoPaths)
          : this.photoPaths,
      paidAt: paidAt ?? this.paidAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Expense adjustStatus({DateTime? date, bool? paid}) {
    final resolvedDate = date ?? this.date;
    final resolvedPaid = paid ?? isPaid;
    final now = DateUtils.dateOnly(DateTime.now());
    final newStatus = _statusFor(resolvedDate, resolvedPaid, now: now);
    return copyWith(
      date: resolvedDate,
      status: newStatus,
      paidAt: resolvedPaid ? (paidAt ?? DateTime.now()) : null,
    );
  }

  static ExpenseStatus _statusFor(DateTime date, bool isPaid, {DateTime? now}) {
    if (isPaid) {
      return ExpenseStatus.paid;
    }
    final today = now ?? DateUtils.dateOnly(DateTime.now());
    final target = DateUtils.dateOnly(date);
    if (target.isAfter(today)) {
      return ExpenseStatus.planned;
    }
    return ExpenseStatus.unpaid;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is Expense &&
        other.id == id &&
        other.payerId == payerId &&
        other.payeeId == payeeId &&
        other.date == date &&
        other.amount == amount &&
        other.memo == memo &&
        other.status == status &&
        other.category == category &&
        listEquals(other.photoPaths, photoPaths) &&
        other.paidAt == paidAt &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode => Object.hash(
        id,
        payerId,
        payeeId,
        date,
        amount,
        memo,
        status,
        category,
        Object.hashAll(photoPaths),
        paidAt,
        createdAt,
      );
}
