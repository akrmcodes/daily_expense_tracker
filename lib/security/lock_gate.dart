// lib/services/lock_gate.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/prefs_provider.dart';
import 'lock_service.dart';

/// غلاف يفرض القفل عند الإقلاع وأيضًا عند الرجوع من الخلفية
class LockGate extends ConsumerStatefulWidget {
  final Widget child;
  const LockGate({Key? key, required this.child}) : super(key: key);

  @override
  ConsumerState<LockGate> createState() => _LockGateState();
}

class _LockGateState extends ConsumerState<LockGate> with WidgetsBindingObserver {
  bool _initializing = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // نفّذ فحص القفل بعد أول frame حتى يكون الـ context صالح للملاحة
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _maybeLock(initial: true);
      if (mounted) setState(() => _initializing = false);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _maybeLock({bool initial = false}) async {
    final prefs = ref.read(prefsProvider);
    if (!prefs.appLockEnabled) return;

    await ref.read(lockServiceProvider).requireUnlock(context);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _maybeLock();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_initializing) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return widget.child;
  }
}
