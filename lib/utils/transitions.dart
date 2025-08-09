import 'package:flutter/material.dart';

/// Transition: Slide + Fade, تتكيّف تلقائيًا مع RTL/LTR
Route<T> slideFadeRoute<T>({
  required BuildContext context,
  required Widget page,
  Duration duration = const Duration(milliseconds: 280),
  Curve curve = Curves.easeOutCubic,
}) {
  final dir = Directionality.of(context);
  // في RTL نبدأ من اليسار، في LTR من اليمين
  final beginOffset = dir == TextDirection.rtl ? const Offset(-1, 0) : const Offset(1, 0);

  return PageRouteBuilder<T>(
    transitionDuration: duration,
    reverseTransitionDuration: duration,
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final slide = Tween<Offset>(begin: beginOffset, end: Offset.zero)
          .chain(CurveTween(curve: curve))
          .animate(animation);

      final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);

      return SlideTransition(
        position: slide,
        child: FadeTransition(opacity: fade, child: child),
      );
    },
  );
}
