// lib/views/lock_pin_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/prefs_provider.dart';

class LockPinScreen extends ConsumerStatefulWidget {
  const LockPinScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LockPinScreen> createState() => _LockPinScreenState();
}

class _LockPinScreenState extends ConsumerState<LockPinScreen> {
  final _controller = TextEditingController();
  String? _error;

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(prefsProvider);
    final notifier = ref.read(prefsProvider.notifier);

    final hasPin = prefs.pinHash != null;
    final title = hasPin ? 'أدخل الرقم السري' : 'أنشئ رقمًا سريًا';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
              decoration: InputDecoration(
                labelText: hasPin ? 'PIN' : 'PIN جديد',
                errorText: _error,
              ),
              onSubmitted: (_) => _submit(hasPin, notifier),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => _submit(hasPin, notifier),
              child: Text(hasPin ? 'دخول' : 'حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit(bool hasPin, PrefsNotifier notifier) async {
    final pin = _controller.text.trim();
    if (pin.length < 4) {
      setState(() => _error = 'الرقم السري يجب أن لا يقل عن 4 أرقام');
      return;
    }

    if (!hasPin) {
      // إنشاء PIN لأول مرة
      await notifier.setPin(pin);
      if (mounted) Navigator.of(context).pop(true);
      return;
    }

    // تحقق من PIN
    final ok = notifier.verifyPin(pin);
    if (ok) {
      if (mounted) Navigator.of(context).pop(true);
    } else {
      setState(() => _error = 'PIN غير صحيح');
    }
  }
}
