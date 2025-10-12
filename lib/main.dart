import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'providers/expenses_provider.dart';
import 'providers/onboarding_provider.dart';
import 'providers/people_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/home/home_screen.dart';
import 'screens/onboarding/people_onboarding_screen.dart';
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
      home: const RootGate(),
    );
  }
}

final _rootInitializationProvider = FutureProvider<void>((ref) async {
  // Ensure that SharedPreferences has been provided before evaluating.
  ref.watch(sharedPreferencesProvider);

  final peopleNotifier = ref.watch(peopleProvider.notifier);
  await peopleNotifier.ensureInitialized();
  if (peopleNotifier.count > 0 && !ref.read(peopleOnboardingProvider)) {
    await ref.read(peopleOnboardingProvider.notifier).complete();
  }
  ref.read(expensesProvider.notifier).removePlaceholderUnpaidExpenses();
});

final _shouldShowPeopleOnboardingProvider = Provider<bool>((ref) {
  final onboardingCompleted = ref.watch(peopleOnboardingProvider);
  return !onboardingCompleted;
});

class RootGate extends ConsumerWidget {
  const RootGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initialization = ref.watch(_rootInitializationProvider);
    return initialization.when(
      data: (_) {
        return const RootPage();
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) {
        return Scaffold(
          body: Center(
            child: Text('読み込みに失敗しました\n$error'),
          ),
        );
      },
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
  bool _isShowingOnboarding = false;
  ProviderSubscription<bool>? _onboardingSubscription;

  @override
  void initState() {
    super.initState();
    _listenOnboarding();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      if (ref.read(_shouldShowPeopleOnboardingProvider)) {
        _showOnboardingScreen();
      }
    });
  }

  void _listenOnboarding() {
    if (_onboardingSubscription != null) {
      return;
    }
    _onboardingSubscription = ref.listenManual<bool>(
      _shouldShowPeopleOnboardingProvider,
      (previous, next) {
        if (next) {
          _showOnboardingScreen();
        }
      },
    );
  }

  Future<void> _showOnboardingScreen() async {
    if (_isShowingOnboarding || !mounted) {
      return;
    }
    _isShowingOnboarding = true;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const PeopleOnboardingScreen(),
        fullscreenDialog: true,
      ),
    );
    if (!mounted) {
      return;
    }
    _isShowingOnboarding = false;

    if (ref.read(_shouldShowPeopleOnboardingProvider)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showOnboardingScreen();
      });
    }
  }

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

  @override
  void dispose() {
    _onboardingSubscription?.close();
    super.dispose();
  }
}
