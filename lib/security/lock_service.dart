// lib/services/lock_service.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import '../providers/prefs_provider.dart';

final lockServiceProvider = Provider<LockService>((ref) => LockService(ref));

class LockService {
  LockService(this._ref);
  final Ref _ref;
  final LocalAuthentication _auth = LocalAuthentication();

  bool _authInProgress = false; // ✅ يمنع تداخل طلبات المصادقة

  /// يُعيد true لو تم فتح القفل بنجاح.
  Future<bool> requireUnlock(BuildContext context) async {
    final prefs = _ref.read(prefsProvider);
    if (!prefs.appLockEnabled) return true;

    final should = await shouldLockNow();
    if (!should) return true;

    if (_authInProgress) return false; // حوار قيد التنفيذ بالفعل
    _authInProgress = true;

    try {
      if (prefs.lockMethod == 'biometric') {
        final okBio = await _tryBiometrics();
        if (okBio) {
          await _ref.read(prefsProvider.notifier).markUnlockedNow();
          return true;
        }
        // فشل/غير متاح → PIN
        final okPin = await _askForPin(context);
        if (okPin) {
          await _ref.read(prefsProvider.notifier).markUnlockedNow();
          return true;
        }
        return false;
      } else {
        // طريقة القفل = PIN
        final okPin = await _askForPin(context);
        if (okPin) {
          await _ref.read(prefsProvider.notifier).markUnlockedNow();
        }
        return okPin;
      }
    } catch (_) {
      // أمانًا: لا نعلّق التطبيق
      return true;
    } finally {
      _authInProgress = false;
    }
  }

  /// يقرر إن كان يجب القفل الآن بناءً على آخر وقت فتح والمهلة.
  Future<bool> shouldLockNow() async {
    final prefs = _ref.read(prefsProvider);
    if (!prefs.appLockEnabled) return false;

    final last = prefs.lastUnlockMs;
    final idleSec = prefs.lockAfterSec; // 0 = فوري
    final now = DateTime.now();

    // أول مرة بعد التفعيل ولم يُسجَّل فتح سابق
    if (last == null) return true;

    final elapsed = now.difference(DateTime.fromMillisecondsSinceEpoch(last));

    // ⚠️ الحالة الخاصة: "فوري"
    // حتى لو فوري، بعد نجاح فتح القفل مباشرة لا نُعيد الطلب فورًا في نفس اللحظة.
    // لذلك نستخدم عتبة صغيرة (~1.2 ثانية) لمنع الحلقة.
    if (idleSec == 0) {
      return elapsed.inMilliseconds > 1200;
    }

    // مهلة عادية بالثواني
    return elapsed.inSeconds >= idleSec;
  }

  // ================== Biometrics ==================
  Future<bool> _tryBiometrics() async {
    try {
      final supported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;
      if (!(supported && canCheck)) return false;

      final ok = await _auth.authenticate(
        localizedReason: 'الرجاء المصادقة بالبصمة/الوجه',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: false,     // ⬅️ مهم: تقليل سلوك إعادة الفتح التلقائي
          useErrorDialogs: true,
        ),
      );
      return ok;
    } catch (_) {
      return false;
    }
  }

  // ================== PIN ==================
  Future<bool> _askForPin(BuildContext context) async {
    final prefs = _ref.read(prefsProvider);
    final notifier = _ref.read(prefsProvider.notifier);

    // لا يوجد PIN → اطلب إنشاءه
    if (prefs.pinHash == null) {
      final newPin = await _promptNewPin(context);
      if (newPin == null) return false;
      await notifier.setPin(newPin);
      return true;
    }

    final controller = TextEditingController();
    String? error;

    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              title: const Text('أدخل رمز PIN'),
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
                      hintText: 'أدخل رقمًا من 4–8 أرقام',
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
                      setState(() => error = 'رمز غير صحيح');
                      return;
                    }
                    Navigator.pop(ctx, true);
                  },
                  child: const Text('تأكيد'),
                ),
              ],
            );
          },
        );
      },
    );
    return ok == true;
  }

  Future<String?> _promptNewPin(BuildContext context) async {
    final c1 = TextEditingController();
    final c2 = TextEditingController();
    String? error;

    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              title: const Text('تعيين PIN'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: c1,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    maxLength: 8,
                    decoration: const InputDecoration(hintText: 'PIN جديد (4–8)'),
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
                    final p1 = c1.text.trim();
                    final p2 = c2.text.trim();
                    if (p1.length < 4) {
                      setState(() => error = 'PIN قصير جدًا (الحد الأدنى 4)');
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
            );
          },
        );
      },
    );
    if (ok == true) return c1.text.trim();
    return null;
  }

  /// تغيير PIN من الإعدادات (لو أردت استخدامه لاحقًا).
  Future<bool> changePin({
    required BuildContext context,
    required String currentPin,
    required String newPin,
  }) async {
    final notifier = _ref.read(prefsProvider.notifier);
    if (!notifier.verifyPin(currentPin)) return false;
    await notifier.setPin(newPin);
    return true;
  }
}
