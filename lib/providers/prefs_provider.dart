import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

class PrefsNotifier extends StateNotifier<PrefsState> {
  PrefsNotifier() : super(PrefsState.initial());

  late Box _box;

  Future<void> init() async {
    _box = await Hive.openBox('prefs');

    state = PrefsState(
      themeMode: ThemeMode.values[_box.get('themeMode', defaultValue: 0)],
      currency: _box.get('currency', defaultValue: 'USD'),
      snackDurationSec: _box.get('snackDurationSec', defaultValue: 3),
      swipeToDelete: _box.get('swipeToDelete', defaultValue: true),
      confirmBeforeDelete: _box.get('confirmBeforeDelete', defaultValue: true),
    );
  }

  void setThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
    _box.put('themeMode', mode.index);
  }

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
}

class PrefsState {
  final ThemeMode themeMode;
  final String currency;
  final int snackDurationSec;
  final bool swipeToDelete;
  final bool confirmBeforeDelete;

  PrefsState({
    required this.themeMode,
    required this.currency,
    required this.snackDurationSec,
    required this.swipeToDelete,
    required this.confirmBeforeDelete,
  });

  factory PrefsState.initial() => PrefsState(
        themeMode: ThemeMode.system,
        currency: 'USD',
        snackDurationSec: 3,
        swipeToDelete: true,
        confirmBeforeDelete: true,
      );

  PrefsState copyWith({
    ThemeMode? themeMode,
    String? currency,
    int? snackDurationSec,
    bool? swipeToDelete,
    bool? confirmBeforeDelete,
  }) {
    return PrefsState(
      themeMode: themeMode ?? this.themeMode,
      currency: currency ?? this.currency,
      snackDurationSec: snackDurationSec ?? this.snackDurationSec,
      swipeToDelete: swipeToDelete ?? this.swipeToDelete,
      confirmBeforeDelete: confirmBeforeDelete ?? this.confirmBeforeDelete,
    );
  }
}

final prefsProvider =
    StateNotifierProvider<PrefsNotifier, PrefsState>((ref) {
  return PrefsNotifier();
});
