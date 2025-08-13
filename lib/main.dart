// main.dart
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
import 'providers/prefs_provider.dart'; // 👈 مهم

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(TransactionModelAdapter());
  await Hive.openBox<TransactionModel>('transactions');
  Hive.registerAdapter(FolderModelAdapter());
  await Hive.openBox<FolderModel>('folders');

  await initializeDateFormatting('ar');

  // 👇 أنشئ الـ PrefsNotifier و نفّذ init ثم مرّره كـ override
  final prefsNotifier = PrefsNotifier();
  await prefsNotifier.init();

  runApp(
    ProviderScope(
      overrides: [
        // Riverpod v2: نستخدم overrideWith
        prefsProvider.overrideWith((ref) => prefsNotifier),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(prefsProvider); // 👈 اقرأ الثيم من prefs

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
      themeMode: prefs.themeMode, // 👈 هذا يحل مشكلة عدم تغيّر الوضع
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
      scaffoldMessengerKey: AppGlobals.scaffoldMessengerKey,
    );
  }
}
