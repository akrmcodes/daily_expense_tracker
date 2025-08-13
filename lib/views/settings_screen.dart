// lib/views/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../providers/prefs_provider.dart';
import '../security/lock_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  static const _idleOptions = <int, String>{
    0: 'فوريًا',
    5: 'بعد 5 ثوانٍ',
    15: 'بعد 15 ثانية',
    30: 'بعد 30 ثانية',
    60: 'بعد دقيقة',
    300: 'بعد 5 دقائق',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(prefsProvider);
    final notifier = ref.read(prefsProvider.notifier);
    final lock = ref.read(lockServiceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ===== المظهر =====
          const Text('المظهر', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(value: ThemeMode.system, label: Text('النظام')),
              ButtonSegment(value: ThemeMode.light, label: Text('فاتح')),
              ButtonSegment(value: ThemeMode.dark, label: Text('داكن')),
            ],
            selected: {prefs.themeMode},
            onSelectionChanged: (value) => notifier.setThemeMode(value.first),
          ),
          const Divider(height: 32),

          // ===== قفل التطبيق =====
          const Text('قفل التطبيق', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          SwitchListTile(
            title: const Text('تفعيل القفل'),
            value: prefs.appLockEnabled,
            onChanged: (v) => notifier.setAppLockEnabled(v),
          ),

          ListTile(
            title: const Text('طريقة القفل'),
            subtitle: Text(prefs.lockMethod == 'biometric' ? 'بصمة/وجه' : 'PIN'),
            trailing: const Icon(Icons.chevron_left),
            onTap: () async {
              final method = await showModalBottomSheet<String>(
                context: context,
                builder: (_) => SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        title: const Text('بصمة / وجه'),
                        onTap: () => Navigator.pop(context, 'biometric'),
                      ),
                      ListTile(
                        title: const Text('PIN'),
                        onTap: () => Navigator.pop(context, 'pin'),
                      ),
                    ],
                  ),
                ),
              );
              if (method != null) {
                notifier.setLockMethod(method);
                if (method == 'pin' && prefs.pinHash == null && context.mounted) {
                  // أول مرة يختار PIN ولا يوجد PIN مخزن → اطلب تعيين PIN (بإجبار unlock الذي يهيئ PIN)
                  final ok = await lock.requireUnlock(context);
                  if (!ok && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('فشل ضبط PIN')),
                    );
                  }
                }
              }
            },
          ),

          ListTile(
            title: const Text('القفل بعد الخمول'),
            subtitle: Text(_idleOptions[prefs.lockAfterSec] ?? '${prefs.lockAfterSec} ثانية'),
            trailing: const Icon(Icons.chevron_left),
            onTap: () async {
              final sec = await showModalBottomSheet<int>(
                context: context,
                builder: (_) => SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: _idleOptions.entries.map((e) {
                      return ListTile(
                        title: Text(e.value),
                        onTap: () => Navigator.pop(context, e.key),
                      );
                    }).toList(),
                  ),
                ),
              );
              if (sec != null) {
                notifier.setLockAfter(sec);
              }
            },
          ),

          ListTile(
            title: const Text('تغيير PIN'),
            subtitle: const Text('تعيين رمز مرور جديد'),
            trailing: const Icon(Icons.chevron_left),
            onTap: () async {
              // ✅ تحقق فوري من PIN الحالي قبل الانتقال للجديد
              final currentOk = await _verifyCurrentPinBlocking(context, notifier);
              if (!currentOk) return;

              final newPin = await _promptNewPin(context);
              if (newPin == null) return;

              await notifier.setPin(newPin);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم تغيير PIN بنجاح')),
                );
              }
            },
          ),

          const SizedBox(height: 8),
          FilledButton.icon(
            icon: const Icon(Icons.lock),
            label: const Text('اقفل الآن للاختبار'),
            onPressed: () async {
              final ok = await lock.requireUnlock(context);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(ok ? 'تم الفتح' : 'فشل الفتح')),
                );
              }
            },
          ),

          const SizedBox(height: 16),
          // ===== اختبار البصمة/الوجه + تشخيص =====
          ListTile(
            title: const Text('اختبار البصمة/الوجه'),
            subtitle: const Text('تحقق من الدعم والتسجيل وحاول المصادقة'),
            trailing: const Icon(Icons.fingerprint),
            onTap: () async {
              final auth = LocalAuthentication();
              try {
                final supported = await auth.isDeviceSupported();
                final canCheck = await auth.canCheckBiometrics;
                final biotypes = await auth.getAvailableBiometrics();

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      duration: const Duration(seconds: 4),
                      content: Text(
                        'مدعوم: $supported | يمكن الفحص: $canCheck | الأنواع: $biotypes',
                      ),
                    ),
                  );
                }

                if (!(supported && canCheck)) return;

                final ok = await auth.authenticate(
                  localizedReason: 'اختبار المصادقة الحيوية',
                  options: const AuthenticationOptions(
                    biometricOnly: true,
                    stickyAuth: true,
                    useErrorDialogs: true,
                  ),
                );

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(ok ? 'نجحت المصادقة' : 'فشلت المصادقة')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('خطأ: $e')),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  // ===== Helpers =====

  /// يطلب PIN الحالي ويتحقق منه *داخل الحوار* — لا يغلق إلا لو صحيح.
  Future<bool> _verifyCurrentPinBlocking(
    BuildContext context,
    PrefsNotifier notifier,
  ) async {
    final controller = TextEditingController();
    String? error;

    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('أدخل PIN الحالي'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 8,
                decoration: const InputDecoration(
                  hintText: 'من 4 إلى 8 أرقام',
                ),
              ),
              if (error != null) ...[
                const SizedBox(height: 8),
                Text(
                  error!,
                  style: TextStyle(
                    color: Theme.of(ctx).colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () {
                final pin = controller.text.trim();
                if (pin.length < 4) {
                  setState(() => error = 'PIN قصير جدًا');
                  return;
                }
                final valid = notifier.verifyPin(pin);
                if (!valid) {
                  setState(() => error = 'PIN غير صحيح');
                  return; // لا نغلق
                }
                Navigator.pop(ctx, true);
              },
              child: const Text('تأكيد'),
            ),
          ],
        ),
      ),
    );

    return ok == true;
  }

  /// تعيين PIN جديد (مع تأكيد) — يرجع النص أو null لو إلغاء.
  Future<String?> _promptNewPin(BuildContext context) async {
    final c1 = TextEditingController();
    final c2 = TextEditingController();
    String? error;

    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('تعيين PIN جديد'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: c1,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 8,
                decoration: const InputDecoration(hintText: 'PIN (4–8)'),
              ),
              TextField(
                controller: c2,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 8,
                decoration: const InputDecoration(hintText: 'تأكيد PIN'),
              ),
              if (error != null) ...[
                const SizedBox(height: 8),
                Text(error!, style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
            FilledButton(
              onPressed: () {
                final p1 = c1.text.trim();
                final p2 = c2.text.trim();
                if (p1.length < 4) {
                  setState(() => error = 'PIN قصير جدًا');
                  return;
                }
                if (p1 != p2) {
                  setState(() => error = 'الرمزان غير متطابقين');
                  return;
                }
                Navigator.pop(ctx, true);
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );

    if (ok == true) return c1.text.trim();
    return null;
  }
}
