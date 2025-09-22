import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/expense_provider.dart';
import '../widgets/person_avatar.dart';
import 'expense_input_screen.dart';
import 'settings_screen.dart';
import 'unpaid_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _includePlanned = false;
  final _currencyFormat = NumberFormat.currency(locale: 'ja_JP', symbol: '¥');

  @override
  Widget build(BuildContext context) {
    return Consumer<ExpenseProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        final summaries = provider.summaries(includePlanned: _includePlanned);
        final total = summaries.fold<int>(0, (prev, element) => prev + element.unpaidTotal);
        return Scaffold(
          appBar: AppBar(
            title: const Text('Payment Calendar'),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () => Navigator.of(context).pushNamed(SettingsScreen.routeName),
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile.adaptive(
                  value: _includePlanned,
                  onChanged: (value) {
                    setState(() => _includePlanned = value);
                  },
                  title: const Text('予定を含める'),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 12),
                Text(
                  '未払い合計: ${_currencyFormat.format(total)}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                if (summaries.isEmpty)
                  Expanded(
                    child: Center(
                      child: Text(
                        provider.persons.isEmpty
                            ? 'まずは人を追加してください。設定 > 人の管理で登録できます。'
                            : '未払いはありません。',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                else
                  SizedBox(
                    height: 180,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: summaries.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final summary = summaries[index];
                        return _PersonCard(
                          summary: summary,
                          currencyFormat: _currencyFormat,
                          includePlanned: _includePlanned,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => UnpaidListScreen(
                                  initialPersonId: summary.person.id,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 16),
                const Expanded(
                  child: _UpcomingList(),
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => showExpenseEditor(context),
            icon: const Icon(Icons.add),
            label: const Text('記録追加'),
          ),
        );
      },
    );
  }
}

class _PersonCard extends StatelessWidget {
  const _PersonCard({
    required this.summary,
    required this.currencyFormat,
    required this.includePlanned,
    required this.onTap,
  });

  final PersonSummary summary;
  final NumberFormat currencyFormat;
  final bool includePlanned;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                PersonAvatar(person: summary.person, size: 48),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    summary.person.name,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              currencyFormat.format(summary.unpaidTotal),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (summary.plannedCount > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('予定 ${summary.plannedCount}件'),
                  ),
                ),
              ),
            if (!includePlanned && summary.plannedCount > 0)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  '予定は集計外です',
                  style: TextStyle(fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _UpcomingList extends StatelessWidget {
  const _UpcomingList();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final plannedExpenses = provider.expenses
        .where((expense) => !expense.isPaid && expense.isPlanned)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    if (plannedExpenses.isEmpty) {
      return const Center(
        child: Text('予定されている支払いはありません。'),
      );
    }

    final formatter = DateFormat('M/d (E)', 'ja_JP');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '今後の予定',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.separated(
            itemCount: plannedExpenses.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final expense = plannedExpenses[index];
              final person = provider.getPerson(expense.personId);
              return ListTile(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => UnpaidListScreen(
                      initialPersonId: person.id,
                      initialStatus: ExpenseStatusFilter.planned,
                    ),
                  ),
                ),
                leading: PersonAvatar(person: person, size: 40),
                title: Text(expense.memo?.isNotEmpty == true ? expense.memo! : '未分類の支払い'),
                subtitle: Text('${person.name} ・ ${formatter.format(expense.date)}'),
                trailing: Text(NumberFormat.currency(locale: 'ja_JP', symbol: '¥').format(expense.amount)),
              );
            },
          ),
        ),
      ],
    );
  }
}
