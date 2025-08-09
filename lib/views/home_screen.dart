import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../providers/app_state_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/transitions.dart';
import '../widgets/balance_card.dart';

// إضافات الواجهة الجديدة:
import '../widgets/app/panel_card.dart';
import '../widgets/app/section_title.dart';
import '../widgets/app/glass_panel_card.dart';
import 'create_folder_screen.dart';
import 'folder_details_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appStateProvider);

    // مجلدات المستوى الأعلى فقط
    final folders = appState.folders
        .where((f) => f.parentFolderId == null)
        .toList();
    final transactions = appState.transactions;

    final totalIncome = transactions
        .where((t) => t.isIncome)
        .fold(0.0, (sum, t) => sum + t.amount);
    final totalExpense = transactions
        .where((t) => !t.isIncome)
        .fold(0.0, (sum, t) => sum + t.amount);
    final netBalance = totalIncome - totalExpense;

    // 🎨 تلوين ديناميكي للزجاج حسب الرصيد
    // نستخدم ألوان من ColorScheme لتناسق أعلى مع الثيم:
    final cs = Theme.of(context).colorScheme;
    final Color dynamicTint = netBalance >= 0
        ? cs
              .tertiary // نغمة إيجابية (عادة تميل للأخضر/سماوي حسب الثيم)
        : cs.error; // نغمة سلبية (أحمر أنيق من الثيم)

    return Scaffold(
      appBar: AppBar(
        title: const Text('الرئيسية'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'تبديل الثيم',
            icon: const Icon(Icons.brightness_6),
            onPressed: () {
              final notifier = ref.read(themeModeProvider.notifier);
              notifier.state = notifier.state == ThemeMode.dark
                  ? ThemeMode.light
                  : ThemeMode.dark;
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ✅ GlassPanelCard + BalanceCard مع Elevation & Tint ديناميكي
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child:
                Container(
                      // ظل خارجي لطيف يعطي إحساس Elevation
                      decoration: const BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 24,
                            offset: Offset(0, 12),
                            color: Colors.black26,
                          ),
                        ],
                      ),
                      child: GlassPanelCard(
                        tintColor: dynamicTint, // ← تلوين حسب الرصيد
                        opacity: 0.16, // وضوح بسيط للون داخل الزجاج
                        blurSigma: 14, // Blur متوازن للأداء/الجمال
                        borderOpacity: 0.12, // حدود خفيفة
                        highlightOpacity: 0.07, // هايلايت داخلي ناعم
                        // showNoise: true,        // فعّلها إذا أضفت asset للـ noise
                        child: BalanceCard(
                          income: totalIncome,
                          expense: totalExpense,
                        ),
                      ),
                    )
                    // لمسة دخول لطيفة للبطاقة
                    .animate()
                    .fadeIn(duration: 260.ms, curve: Curves.easeOut)
                    .slideY(
                      begin: .06,
                      end: 0,
                      duration: 260.ms,
                      curve: Curves.easeOut,
                    ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.0),
            child: SectionTitle('المجلدات'),
          ),

          // ✅ قائمة المجلدات مع micro-animations
          Expanded(
            child: ListView.builder(
              itemCount: folders.length,
              itemBuilder: (context, index) {
                final folder = folders[index];
                return ListTile(
                      leading: const Icon(Icons.folder),
                      title: Text(folder.name),
                      onTap: () {
                        Navigator.push(
                          context,
                          slideFadeRoute(
                            context: context,
                            page: FolderDetailsScreen(
                              folderId: folder.key as int,
                            ),
                          ),
                        );
                      },
                    )
                    .animate()
                    .fadeIn(
                      duration: 220.ms,
                      curve: Curves.easeOut,
                      delay: (index * 30).ms,
                    )
                    .slideY(
                      begin: .06,
                      end: 0,
                      duration: 220.ms,
                      curve: Curves.easeOut,
                    );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const CreateFolderScreen(),
          );
        },
        child: const Icon(Icons.create_new_folder),
      ),
    );
  }
}
