import 'dart:io';

import 'package:characters/characters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/expense.dart';
import '../../models/person_summary.dart';
import '../../providers/expenses_provider.dart';
import '../../providers/home_summary_provider.dart';
import '../../providers/settings_provider.dart';
import '../../screens/person/person_detail_screen.dart';
import '../../screens/unpaid/unpaid_screen.dart';
import '../../utils/format.dart';
import '../expense/expense_form_sheet.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final includePlanned = ref.watch(includePlannedInSummaryProvider);
    final summaries = ref.watch(homeSummariesProvider);
    final quickPayIncludesPlanned = ref.watch(settingsProvider
        .select((settings) => settings.quickPayIncludesPlanned));

    return Scaffold(
      appBar: AppBar(
        title: const Text('ホーム'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('予定を含める'),
                Switch(
                  value: includePlanned,
                  onChanged: (value) => ref
                      .read(includePlannedInSummaryProvider.notifier)
                      .state = value,
                ),
              ],
            ),
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: summaries.length,
        itemBuilder: (context, index) {
          final summary = summaries[index];
          return _PersonSummaryTile(
            summary: summary,
            includePlanned: includePlanned,
            quickPayIncludesPlanned: quickPayIncludesPlanned,
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            builder: (_) => const ExpenseFormSheet(),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _PersonSummaryTile extends ConsumerWidget {
  const _PersonSummaryTile({
    required this.summary,
    required this.includePlanned,
    required this.quickPayIncludesPlanned,
  });

  final PersonSummary summary;
  final bool includePlanned;
  final bool quickPayIncludesPlanned;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalAmount = summary.totalAmount(includePlanned: includePlanned);
    final totalCount = summary.totalCount(includePlanned: includePlanned);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Avatar(summary: summary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        summary.person.name,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatCurrency(totalAmount),
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          _CountBadge(
                            label: '未払い',
                            count: summary.unpaidCount,
                          ),
                          if (summary.plannedCount > 0)
                            _CountBadge(
                              label: '予定',
                              count: summary.plannedCount,
                              color: Colors.deepPurple,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => PersonDetailScreen(
                              person: summary.person,
                            ),
                          ),
                        );
                      },
                      child: const Text('個人詳細'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () => _onPayAllPressed(context, ref),
                      child: const Text('全件支払い'),
                    ),
                    IconButton(
                      tooltip: '未払い一覧を開く',
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => UnpaidScreen(
                              initialPersonId: summary.person.id,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              includePlanned
                  ? '予定を含めた合計 $totalCount 件'
                  : '未払い合計 $totalCount 件',
            ),
          ],
        ),
      ),
    );
  }

  void _onPayAllPressed(BuildContext context, WidgetRef ref) async {
    final includePlannedForPayment =
        includePlanned && quickPayIncludesPlanned;
    final expenses = ref.read(expensesProvider);
    final targets = expenses.where((expense) {
      if (expense.personId != summary.person.id) {
        return false;
      }
      if (expense.status == ExpenseStatus.unpaid) {
        return true;
      }
      if (includePlannedForPayment && expense.status == ExpenseStatus.planned) {
        return true;
      }
      return false;
    }).toList();

    if (targets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('支払い対象の明細はありません')), 
      );
      return;
    }

    final totalAmount =
        targets.fold<int>(0, (value, item) => value + item.amount);
    final label = includePlannedForPayment ? '未払い・予定' : '未払い';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('全件支払い'),
          content: Text(
            '${summary.person.name}の$label${targets.length}件（合計${formatCurrency(totalAmount)}）を支払い済みにしますか？',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('支払い済みにする'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    final originals = ref
        .read(expensesProvider.notifier)
        .markPaidForPerson(
          summary.person.id,
          includePlanned: includePlannedForPayment,
        );

    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
            '${targets.length}件（${formatCurrency(totalAmount)}）を支払い済みにしました'),
        action: SnackBarAction(
          label: '元に戻す',
          onPressed: () {
            ref.read(expensesProvider.notifier).restoreMany(originals);
          },
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.summary});

  final PersonSummary summary;

  @override
  Widget build(BuildContext context) {
    final emoji = summary.person.emoji;
    final photoPath = summary.person.photoPath;
    if (photoPath != null && File(photoPath).existsSync()) {
      return CircleAvatar(
        radius: 28,
        backgroundImage: FileImage(File(photoPath)),
      );
    }
    final text = emoji ??
        (summary.person.name.characters.isNotEmpty
            ? summary.person.name.characters.first
            : '?');
    return CircleAvatar(
      radius: 28,
      child: Text(
        text,
        style: const TextStyle(fontSize: 24),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({
    required this.label,
    required this.count,
    this.color,
  });

  final String label;
  final int count;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final badgeColor = color ?? Theme.of(context).colorScheme.primary;
    final foreground =
        ThemeData.estimateBrightnessForColor(badgeColor) == Brightness.dark
            ? Colors.white
            : Colors.black87;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: badgeColor.withOpacity(0.4)),
      ),
      child: Text('$label: $count', style: TextStyle(color: foreground)),
    );
  }
}
