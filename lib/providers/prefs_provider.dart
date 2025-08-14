// lib/providers/prefs_provider.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:crypto/crypto.dart';

class PrefsNotifier extends StateNotifier<PrefsState> {
  PrefsNotifier() : super(PrefsState.initial());

  late Box _box;

  Future<void> init() async {
    _box = await Hive.openBox('prefs');

    state = PrefsState(
      themeMode: ThemeMode.values[_box.get('themeMode', defaultValue: 0)],
      // (اختياري/ترِك للاستخدام لاحقًا)
      currency: _box.get('currency', defaultValue: 'USD'),
      snackDurationSec: _box.get('snackDurationSec', defaultValue: 3),
      swipeToDelete: _box.get('swipeToDelete', defaultValue: true),
      confirmBeforeDelete: _box.get('confirmBeforeDelete', defaultValue: true),

      // القفل
      appLockEnabled: _box.get('appLockEnabled', defaultValue: false),
      lockMethod: _box.get('lockMethod', defaultValue: 'biometric'), // 'biometric' | 'pin'
      lockAfterSec: _box.get('lockAfterSec', defaultValue: 0), // 0 = فوري
      pinHash: _box.get('pinHash'), // null لو لم يُضبط PIN
      lastUnlockMs: _box.get('lastUnlockMs') as int?, // آخر وقت فتح
    );
  }

  // ===== Theme =====
  void setThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
    _box.put('themeMode', mode.index);
  }

  // ===== Legacy/Optional =====
  void setCurrency(String currency) {
    state = state.copyWith(currency: currency);
    _box.put('currency', currency);
  }

  void setSnackDuration(int seconds) {
    state = state.copyWith(snackDurationSec: seconds);
    _box.put('snackDurationSec', seconds);
  }

  void setSwipeToDelete(bool value) {
    state = state.copyWith(swipeToDelete: value);
    _box.put('swipeToDelete', value);
  }

  void setConfirmBeforeDelete(bool value) {
    state = state.copyWith(confirmBeforeDelete: value);
    _box.put('confirmBeforeDelete', value);
  }

  // ===== App Lock =====
  void setAppLockEnabled(bool enabled) {
    state = state.copyWith(appLockEnabled: enabled);
    _box.put('appLockEnabled', enabled);
  }

  void setLockMethod(String method) {
    // method: 'biometric' | 'pin'
    state = state.copyWith(lockMethod: method);
    _box.put('lockMethod', method);
  }

  void setLockAfter(int seconds) {
    state = state.copyWith(lockAfterSec: seconds);
    _box.put('lockAfterSec', seconds);
  }

  Future<void> setPin(String pin) async {
    final hash = _hashPin(pin);
    state = state.copyWith(pinHash: hash);
    await _box.put('pinHash', hash);
  }

  bool verifyPin(String pin) {
    final stored = state.pinHash;
    if (stored == null) return false;
    return stored == _hashPin(pin);
  }

  Future<void> markUnlockedNow() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    state = state.copyWith(lastUnlockMs: now);
    await _box.put('lastUnlockMs', now);
  }

  String _hashPin(String pin) {
    // تبسيط: SHA256 فقط (لاحقًا نقدر نضيف salt)
    final bytes = utf8.encode(pin);
    return sha256.convert(bytes).toString();
  }
}

class PrefsState {
  final ThemeMode themeMode;
  final String currency;
  final int snackDurationSec;
  final bool swipeToDelete;
  final bool confirmBeforeDelete;

  // القفل:
  final bool appLockEnabled;
  final String lockMethod; // 'biometric' | 'pin'
  final int lockAfterSec;  // 0 = فوري
  final String? pinHash;
  final int? lastUnlockMs;

  PrefsState({
    required this.themeMode,
    required this.currency,
    required this.snackDurationSec,
    required this.swipeToDelete,
    required this.confirmBeforeDelete,
    required this.appLockEnabled,
    required this.lockMethod,
    required this.lockAfterSec,
    required this.pinHash,
    required this.lastUnlockMs,
  });

  factory PrefsState.initial() => PrefsState(
        themeMode: ThemeMode.system,
        currency: 'USD',
        snackDurationSec: 3,
        swipeToDelete: true,
        confirmBeforeDelete: true,
        appLockEnabled: false,
        lockMethod: 'biometric',
        lockAfterSec: 0,
        pinHash: null,
        lastUnlockMs: null,
      );

  PrefsState copyWith({
    ThemeMode? themeMode,
    String? currency,
    int? snackDurationSec,
    bool? swipeToDelete,
    bool? confirmBeforeDelete,
    bool? appLockEnabled,
    String? lockMethod,
    int? lockAfterSec,
    String? pinHash,
    int? lastUnlockMs,
  }) {
    return PrefsState(
      themeMode: themeMode ?? this.themeMode,
      currency: currency ?? this.currency,
      snackDurationSec: snackDurationSec ?? this.snackDurationSec,
      swipeToDelete: swipeToDelete ?? this.swipeToDelete,
      confirmBeforeDelete: confirmBeforeDelete ?? this.confirmBeforeDelete,
      appLockEnabled: appLockEnabled ?? this.appLockEnabled,
      lockMethod: lockMethod ?? this.lockMethod,
      lockAfterSec: lockAfterSec ?? this.lockAfterSec,
      pinHash: pinHash ?? this.pinHash,
      lastUnlockMs: lastUnlockMs ?? this.lastUnlockMs,
    );
  }
}

final prefsProvider = StateNotifierProvider<PrefsNotifier, PrefsState>((ref) {
  return PrefsNotifier();
});
