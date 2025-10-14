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
import '../../widgets/person_avatar.dart';

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
      backgroundColor: const Color(0xFFFFFAF0),
      appBar: AppBar(
        title: const Text('ホーム'),
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
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
                  activeColor: Colors.white,
                  activeTrackColor: colorScheme.primary,
                  inactiveTrackColor: const Color(0xFFEEEEEE),
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
        backgroundColor: colorScheme.primary,
        onPressed: () async {
          await showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            builder: (_) => const ExpenseFormSheet(),
          );
        },
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _EmptySummaryView extends StatelessWidget {
  const _EmptySummaryView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '未払いの記録がありません',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
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
    const unpaidColor = Color(0xFFF44336);

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
                              ? unpaidColor
                              : textTheme.headlineSmall?.color,
                        ),
                      ),
                    ],
                  ),
                ),
                if (summary.unpaidCount > 0 || hasPlanned)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (summary.unpaidCount > 0)
                        _CountBadge(
                          text: '未払い${summary.unpaidCount}件',
                          color: unpaidColor,
                        ),
                      if (hasPlanned) ...[
                        const SizedBox(height: 4),
                        _CountBadge(
                          text: '予定${summary.plannedCount}件',
                          color: const Color(0xFFEEEEEE),
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
                      foregroundColor: Colors.black,
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
                      foregroundColor: Colors.black,
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

    final messenger = ScaffoldMessenger.of(context);
    if (targets.isEmpty) {
      messenger.showSnackBar(
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

    if (!messenger.mounted) {
      return;
    }

    final originals = ref
        .read(expensesProvider.notifier)
        .markPaidForPerson(
          summary.person.id,
          includePlanned: includePlannedForPayment,
        );

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
    return PersonAvatar(
      person: summary.person,
      size: size,
      showShadow: true,
      backgroundColor: kPersonAvatarBackgroundColor,
      textStyle: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.onSurface,
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
    final theme = Theme.of(context);
    final badgeColor = color ?? theme.colorScheme.primary;
    final isCustomColor = color != null;
    final useSolidStyle = isCustomColor &&
        ThemeData.estimateBrightnessForColor(badgeColor) == Brightness.light;
    final backgroundColor = useSolidStyle
        ? badgeColor
        : badgeColor.withOpacityValue(0.12);
    final borderColor = useSolidStyle
        ? Colors.transparent
        : badgeColor.withOpacityValue(0.3);
    final textColor = useSolidStyle ? theme.colorScheme.onSurface : badgeColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
