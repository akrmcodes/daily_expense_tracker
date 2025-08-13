import 'package:flutter/material.dart';
import '../app_globals.dart';

class AppSnack {
  // نمسك آخر سناك بار معروضة لنتحكم فيها
  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? _active;

  static void show(
    String message, {
    SnackBarAction? action,
    Duration duration = const Duration(seconds: 3),
    SnackBarBehavior behavior = SnackBarBehavior.floating,
  }) {
    final messenger = AppGlobals.scaffoldMessengerKey.currentState;
    if (messenger == null) return;

    // اغلق أي سناك بار نشطة فورًا (منع التراكم)
    try {
      _active?.close();
    } catch (_) {}

    messenger.hideCurrentSnackBar();
    messenger.clearSnackBars();

    _active = messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        behavior: behavior,
        dismissDirection: DismissDirection.horizontal,
        action: action,
      ),
    );

    // ضمان إضافي: بعد انقضاء المدة + هامش، نخفي السناك بار قسرًا
    Future.delayed(duration + const Duration(milliseconds: 150), () {
      final m = AppGlobals.scaffoldMessengerKey.currentState;
      if (m == null) return;
      // لو لسه نفس السناك بار المعروضة، أخفِها
      if (_active != null) {
        m.hideCurrentSnackBar();
        _active = null;
      }
    });

    // لما تُغلق، صفّر المرجع
    _active?.closed.whenComplete(() {
      _active = null;
    });
  }

  static void undoable(String message, VoidCallback onUndo) {
    show(
      message,
      action: SnackBarAction(label: 'تراجع', onPressed: onUndo),
    );
  }
}
