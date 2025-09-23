import 'package:equatable/equatable.dart';

import 'person.dart';

class PersonSummary extends Equatable {
  const PersonSummary({
    required this.person,
    required this.unpaidAmount,
    required this.unpaidCount,
    required this.plannedAmount,
    required this.plannedCount,
  });

  final Person person;
  final int unpaidAmount;
  final int unpaidCount;
  final int plannedAmount;
  final int plannedCount;

  int totalAmount({required bool includePlanned}) =>
      includePlanned ? unpaidAmount + plannedAmount : unpaidAmount;

  int totalCount({required bool includePlanned}) =>
      includePlanned ? unpaidCount + plannedCount : unpaidCount;

  @override
  List<Object?> get props => [
        person,
        unpaidAmount,
        unpaidCount,
        plannedAmount,
        plannedCount,
      ];
}
