import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'models/transaction_model.dart';
import 'models/folder_model.dart';
import 'views/home_screen.dart';
import 'theme/app_theme.dart';
import 'providers/theme_provider.dart'; // ✅ جديد
import 'app_globals.dart'; // ← أضِف هذا الاستيراد


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تهيئة Hive
  await Hive.initFlutter();
  Hive.registerAdapter(TransactionModelAdapter());
  await Hive.openBox<TransactionModel>('transactions');
  Hive.registerAdapter(FolderModelAdapter());
  await Hive.openBox<FolderModel>('folders');

  // تهيئة بيانات اللغة العربية
  await initializeDateFormatting('ar');

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget { // ✅ تغيّرت من Stateless إلى ConsumerWidget
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider); // ✅ قراءة حالة الثيم

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
      themeMode: themeMode, // ✅ تطبيق وضع الثيم من المزود
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
      scaffoldMessengerKey: AppGlobals.scaffoldMessengerKey, // ← سطر مهم جداً

    );
  }
}
