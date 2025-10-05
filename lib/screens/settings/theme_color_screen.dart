import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/settings_provider.dart';

class ThemeColorOption {
  const ThemeColorOption({
    required this.name,
    required this.color,
  });

  final String name;
  final Color color;
}

const themeColorOptions = <ThemeColorOption>[
  ThemeColorOption(name: 'ブルーデニム', color: Color(0xFF3366FF)),
  ThemeColorOption(name: 'ナチュラルウッド', color: Color(0xFFE8CFA9)),
  ThemeColorOption(name: 'ディープブルー', color: Color(0xFF1A2947)),
  ThemeColorOption(name: 'オレンジ', color: Color(0xFFFF9800)),
  ThemeColorOption(name: '水色', color: Color(0xFF00BCD4)),
  ThemeColorOption(name: '赤', color: Color(0xFFFF0033)),
  ThemeColorOption(name: 'ワインレッド', color: Color(0xFFB71C1C)),
  ThemeColorOption(name: 'ピンク', color: Color(0xFFFF80AB)),
  ThemeColorOption(name: '緑', color: Color(0xFF4CAF50)),
];

class ThemeColorScreen extends ConsumerWidget {
  const ThemeColorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final selectedColorValue = settings.themeColor.value;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFAF0),
      appBar: AppBar(
        title: const Text('テーマカラー'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 0,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 16),
        itemBuilder: (context, index) {
          final option = themeColorOptions[index];
          final isSelected = option.color.value == selectedColorValue;
          final borderRadius = BorderRadius.vertical(
            top: index == 0 ? const Radius.circular(12) : Radius.zero,
            bottom: index == themeColorOptions.length - 1
                ? const Radius.circular(12)
                : Radius.zero,
          );

          return ClipRRect(
            borderRadius: borderRadius,
            child: Material(
              color: Colors.white,
              child: ListTile(
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: option.color,
                    shape: BoxShape.circle,
                  ),
                ),
                title: Text(
                  option.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                trailing: isSelected
                    ? Icon(
                        Icons.check,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : null,
                onTap: () async {
                  await ref
                      .read(settingsProvider.notifier)
                      .setThemeColor(option.color);
                },
              ),
            ),
          );
        },
        separatorBuilder: (context, _) => const Divider(
          height: 1,
          thickness: 0.5,
          color: Color(0xFFE0E0E0),
        ),
        itemCount: themeColorOptions.length,
      ),
    );
  }
}
