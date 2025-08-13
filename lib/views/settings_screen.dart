import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/prefs_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(prefsProvider);
    final notifier = ref.read(prefsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'المظهر',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(value: ThemeMode.system, label: Text('النظام')),
              ButtonSegment(value: ThemeMode.light, label: Text('فاتح')),
              ButtonSegment(value: ThemeMode.dark, label: Text('داكن')),
            ],
            selected: {prefs.themeMode},
            onSelectionChanged: (value) {
              notifier.setThemeMode(value.first);
            },
          ),
          const Divider(height: 32),

          const Text(
            'العملة الافتراضية',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          DropdownButton<String>(
            value: prefs.currency,
            items: const [
              DropdownMenuItem(value: 'USD', child: Text('دولار أمريكي')),
              DropdownMenuItem(value: 'SAR', child: Text('ريال سعودي')),
              DropdownMenuItem(value: 'YER', child: Text('ريال يمني')),
              DropdownMenuItem(value: 'EUR', child: Text('يورو')),
            ],
            onChanged: (value) {
              if (value != null) notifier.setCurrency(value);
            },
          ),
          const Divider(height: 32),

          const Text(
            'مدة ظهور الرسائل (ثواني)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Slider(
            value: prefs.snackDurationSec.toDouble(),
            min: 2,
            max: 10,
            divisions: 8,
            label: '${prefs.snackDurationSec} ثانية',
            onChanged: (value) {
              notifier.setSnackDuration(value.toInt());
            },
          ),
          const Divider(height: 32),

          SwitchListTile(
            title: const Text('السحب للحذف'),
            value: prefs.swipeToDelete,
            onChanged: notifier.setSwipeToDelete,
          ),
          SwitchListTile(
            title: const Text('التأكيد قبل الحذف'),
            value: prefs.confirmBeforeDelete,
            onChanged: notifier.setConfirmBeforeDelete,
          ),
        ],
      ),
    );
  }
}
