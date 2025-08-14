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

import 'providers/prefs_provider.dart';
import './security/lock_gate.dart'; // ✅ غلاف القفل

Future<void> main() async {
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

class _MyAppState extends ConsumerState<MyApp> {
  bool _prefsReady = false;

  @override
  void initState() {
    super.initState();
    // تهيئة تفضيلات المستخدم قبل البناء (مرة واحدة)
    Future.microtask(() async {
      await ref.read(prefsProvider.notifier).init();
      if (mounted) setState(() => _prefsReady = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(prefsProvider);

    // لو حاب تعرض دائرة تحميل أثناء التهيئة الأولى
    if (!_prefsReady) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return MaterialApp(
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: prefs.themeMode,
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: AppGlobals.scaffoldMessengerKey,
      // ✅ اجعل LockGate هو الغلاف الوحيد المسؤول عن القفل
      home: const LockGate(child: HomeScreen()),
    );
  }
}
