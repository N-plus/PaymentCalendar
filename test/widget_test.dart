import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pay_check/main.dart';
import 'package:pay_check/providers/settings_provider.dart';
import 'package:pay_check/services/reminder_service.dart';

class _FakeReminderService implements ReminderService {
  @override
  Future<void> cancelAll() async {}

  @override
  Future<void> cancelPlannedReminder() async {}

  @override
  Future<void> cancelUnpaidReminder() async {}

  @override
  Future<void> initialize() async {}

  @override
  Future<void> scheduleDailyUnpaidReminder() async {}

  @override
  Future<void> schedulePlannedReminder() async {}
}

void main() {
  testWidgets('PayCheckApp can be pumped', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          reminderServiceProvider.overrideWithValue(_FakeReminderService()),
        ],
        child: const PayCheckApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('ホーム'), findsOneWidget);
  });
}
