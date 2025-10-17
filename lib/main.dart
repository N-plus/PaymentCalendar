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
      child: const PayCheckApp(),
    ),
  );
}

class PayCheckApp extends ConsumerWidget {
  const PayCheckApp({super.key});

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
      title: 'Pay Check',
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

final _rootInitializationProvider = FutureProvider<bool>((ref) async {
  // Ensure that SharedPreferences has been provided before evaluating.
  ref.watch(sharedPreferencesProvider);

  final peopleNotifier = ref.watch(peopleProvider.notifier);
  await peopleNotifier.ensureInitialized();

  final onboardingNotifier = ref.read(peopleOnboardingProvider.notifier);
  final onboardingCompleted = ref.read(peopleOnboardingProvider);

  bool shouldShowOnboarding = false;
  if (peopleNotifier.count == 0 && !onboardingCompleted) {
    shouldShowOnboarding = true;
  } else if (!onboardingCompleted) {
    await onboardingNotifier.complete();
  }

  ref.read(expensesProvider.notifier).removePlaceholderUnpaidExpenses();
  return shouldShowOnboarding;
});

class RootGate extends ConsumerStatefulWidget {
  const RootGate({super.key});

  @override
  ConsumerState<RootGate> createState() => _RootGateState();
}

class _RootGateState extends ConsumerState<RootGate> {
  bool _hasPresentedOnboarding = false;
  late final ProviderSubscription<AsyncValue<bool>>
      _rootInitializationSubscription;

  @override
  void initState() {
    super.initState();
    _rootInitializationSubscription = ref.listenManual<AsyncValue<bool>>(
      _rootInitializationProvider,
      (previous, next) {
        next.whenData((shouldShowOnboarding) {
          _handleOnboardingVisibility(shouldShowOnboarding);
        });
      },
    );
  }

  @override
  void dispose() {
    _rootInitializationSubscription.close();
    super.dispose();
  }

  void _handleOnboardingVisibility(bool shouldShowOnboarding) {
    if (!shouldShowOnboarding) {
      _hasPresentedOnboarding = false;
      return;
    }
    if (_hasPresentedOnboarding || !mounted) {
      return;
    }
    _hasPresentedOnboarding = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final onboardingNotifier = ref.read(peopleOnboardingProvider.notifier);
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PeopleOnboardingScreen(
            onCompleted: () => onboardingNotifier.complete(),
            onLater: () => onboardingNotifier.complete(),
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final initialization = ref.watch(_rootInitializationProvider);
    return initialization.when(
      data: (_) => const RootPage(),
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
            label: '詳細',
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
