// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'models/transaction_model.dart';
import 'models/folder_model.dart';
import 'views/home_screen.dart';
import 'theme/app_theme.dart';
import 'app_globals.dart';

import 'providers/prefs_provider.dart';           // ✅ جديد: نقرأ الثيم من هنا
import './security/lock_service.dart';              // ✅ جديد: لاستخدام القفل

final navigatorKey = GlobalKey<NavigatorState>(); // ✅ لو لم يكن موجوداً

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(TransactionModelAdapter());
  await Hive.openBox<TransactionModel>('transactions');
  Hive.registerAdapter(FolderModelAdapter());
  await Hive.openBox<FolderModel>('folders');

  await initializeDateFormatting('ar');

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  DateTime? _lastPaused;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // تأكد تهيئة تفضيلات المستخدم
    Future.microtask(() async {
      await ref.read(prefsProvider.notifier).init();
      if (mounted) setState(() {});
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state);

    final prefs = ref.read(prefsProvider);
    if (!prefs.appLockEnabled) return;

    if (state == AppLifecycleState.paused) {
      _lastPaused = DateTime.now();
    }

    if (state == AppLifecycleState.resumed && _lastPaused != null) {
      final diff = DateTime.now().difference(_lastPaused!);
      final needLock = diff.inSeconds >= prefs.lockAfterSec;
      if (needLock) {
        final ctx = navigatorKey.currentContext;
        if (ctx != null) {
          final ok = await ref.read(lockServiceProvider).requireUnlock(ctx);
          // لو فشل، شاشة القفل ستظل معروضة حتى النجاح؛ لا حاجة لعمل إضافي هنا
        }
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(prefsProvider); // ✅ نقرأ الثيم من prefs
    return MaterialApp(
      navigatorKey: navigatorKey,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: prefs.themeMode, // ✅ بدل themeModeProvider
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
      scaffoldMessengerKey: AppGlobals.scaffoldMessengerKey,
    );
  }
}
