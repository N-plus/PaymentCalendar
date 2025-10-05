import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'providers/settings_provider.dart';
import 'screens/home/home_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/unpaid/unpaid_screen.dart';
import 'services/reminder_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final reminderService = ReminderService(FlutterLocalNotificationsPlugin());
  await reminderService.initialize();
  final preferences = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [
        reminderServiceProvider.overrideWithValue(reminderService),
        sharedPreferencesProvider.overrideWithValue(preferences),
      ],
      child: const PaymentCalendarApp(),
    ),
  );
}

class PaymentCalendarApp extends ConsumerWidget {
  const PaymentCalendarApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(reminderCoordinatorProvider);
    final settings = ref.watch(settingsProvider);
    final themeColor = settings.themeColor;
    final colorScheme = ColorScheme.fromSeed(seedColor: themeColor).copyWith(
      background: const Color(0xFFFFFAF0),
      surface: const Color(0xFFFFFAF0),
      primary: themeColor,
    );
    return MaterialApp(
      title: 'Payment Calendar',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: colorScheme,
        scaffoldBackgroundColor: const Color(0xFFFFFAF0),
        appBarTheme: AppBarTheme(
          backgroundColor: colorScheme.primary,
          foregroundColor: Colors.white,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: colorScheme.primary,
          foregroundColor: Colors.white,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFCCCCCC)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFCCCCCC)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF333333)),
          ),
        ),
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: Color(0xFF333333),
        ),
        useMaterial3: true,
        fontFamily: 'N'
            'o'
            't'
            'o'
            'S'
            'a'
            'n'
            's'
            'J'
            'P',
      ),
      home: const RootPage(),
    );
  }
}

class RootPage extends ConsumerStatefulWidget {
  const RootPage({super.key});

  @override
  ConsumerState<RootPage> createState() => _RootPageState();
}

class _RootPageState extends ConsumerState<RootPage> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      const HomeScreen(),
      const UnpaidScreen(),
      const SettingsScreen(),
    ];
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        onTap: (value) => setState(() => _index = value),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'ホーム',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: '未払い',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: '設定',
          ),
        ],
      ),
    );
  }
}
