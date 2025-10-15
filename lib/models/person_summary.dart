import 'person.dart';

class PersonSummary {
  const PersonSummary({
    required this.payer,
    required this.payee,
    required this.unpaidAmount,
    required this.unpaidCount,
    required this.plannedAmount,
    required this.plannedCount,
  });

  final Person payer;
  final Person payee;
  final int unpaidAmount;
  final int unpaidCount;
  final int plannedAmount;
  final int plannedCount;

  int totalAmount({required bool includePlanned}) =>
      includePlanned ? unpaidAmount + plannedAmount : unpaidAmount;

  int totalCount({required bool includePlanned}) =>
      includePlanned ? unpaidCount + plannedCount : unpaidCount;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is PersonSummary &&
        other.payer == payer &&
        other.payee == payee &&
        other.unpaidAmount == unpaidAmount &&
        other.unpaidCount == unpaidCount &&
        other.plannedAmount == plannedAmount &&
        other.plannedCount == plannedCount;
  }

  @override
  int get hashCode => Object.hash(
        payer,
        payee,
        unpaidAmount,
        unpaidCount,
        plannedAmount,
        plannedCount,
      );
}
