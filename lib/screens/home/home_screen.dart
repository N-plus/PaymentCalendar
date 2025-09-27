import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payment_calendar/utils/color_utils.dart';

import '../../models/expense.dart';
import '../../models/person_summary.dart';
import '../../providers/expenses_provider.dart';
import '../../providers/home_summary_provider.dart';
import '../../providers/settings_provider.dart';
import '../../screens/person/person_detail_screen.dart';
import '../../screens/unpaid/unpaid_screen.dart';
import '../../utils/date_util.dart';
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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface.withOpacityValue(0.3),
      appBar: AppBar(
        title: const Text('ホーム'),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
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
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: colorScheme.surface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.event, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  '予定を含める',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Switch(
                  value: includePlanned,
                  onChanged: (value) => ref
                      .read(includePlannedInSummaryProvider.notifier)
                      .state = value,
                ),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: Theme.of(context).dividerColor),
          Expanded(
            child: summaries.isEmpty
                ? const _EmptySummaryView()
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemBuilder: (context, index) {
                      final summary = summaries[index];
                      return _PersonSummaryTile(
                        summary: summary,
                        includePlanned: includePlanned,
                        quickPayIncludesPlanned: quickPayIncludesPlanned,
                      );
                    },
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemCount: summaries.length,
                  ),
          ),
        ],
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

class _EmptySummaryView extends StatelessWidget {
  const _EmptySummaryView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_alt_outlined,
            size: 64,
              color: colorScheme.onSurface.withOpacityValue(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            '人が登録されていません',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
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
    final includePlannedForPayment =
        includePlanned && quickPayIncludesPlanned;
    final hasUnpaid = summary.unpaidCount > 0;
    final hasPlanned = summary.plannedCount > 0;
    final hasPayTargets = summary.unpaidCount > 0 ||
        (includePlannedForPayment && summary.plannedCount > 0);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 4,
      shadowColor: const Color.fromRGBO(0, 0, 0, 0.05),
      color: const Color(0xFFFFFFFF),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                        style: textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatCurrency(totalAmount),
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: hasUnpaid
                              ? colorScheme.error
                              : textTheme.headlineSmall?.color,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
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
                    if (summary.unpaidCount > 0)
                      _CountBadge(
                        text: '未払い${summary.unpaidCount}件',
                        color: colorScheme.error,
                      ),
                    if (hasPlanned) ...[
                      const SizedBox(height: 4),
                      _CountBadge(
                        text: '予定${summary.plannedCount}件',
                        color: colorScheme.secondary,
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              includePlanned
                  ? '予定を含めた合計 $totalCount 件'
                  : '未払い合計 $totalCount 件',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PersonDetailScreen(
                            person: summary.person,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.person, size: 18),
                    label: const Text('個人詳細'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: hasPayTargets
                        ? () => _onPayAllPressed(context, ref)
                        : null,
                    icon: const Icon(Icons.payment, size: 18),
                    label: const Text('全件支払い'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
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

    if (!context.mounted) {
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
    const double size = 56;
    final colorScheme = Theme.of(context).colorScheme;
    final photoPath = summary.person.photoPath;
    if (photoPath != null && File(photoPath).existsSync()) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacityValue(0.1),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.file(
          File(photoPath),
          fit: BoxFit.cover,
        ),
      );
    }
    final emoji = summary.person.emoji;
    final text = emoji ??
        (summary.person.name.characters.isNotEmpty
            ? summary.person.name.characters.first
            : '?');
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({
    required this.text,
    this.color,
  });

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final badgeColor = color ?? Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: badgeColor.withOpacityValue(0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: badgeColor.withOpacityValue(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: badgeColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
