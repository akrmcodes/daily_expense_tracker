import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/tokens.dart';

class GlassPanelCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final bool isEnabled;
  final double blurSigma;
  final double opacity;
  final Color? tintColor;        // ← لون خفيف شفاف
  final bool showNoise;          // ← اختياري لإضافة Noise واقعي
  final double borderOpacity;    // ← شدة الحدود
  final double highlightOpacity; // ← شدة الـ highlight الداخلي

  const GlassPanelCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppTokens.sp16),
    this.margin = const EdgeInsets.all(AppTokens.sp12),
    this.isEnabled = true,
    this.blurSigma = 14,
    this.opacity = 0.14,
    this.tintColor,
    this.showNoise = false,
    this.borderOpacity = 0.10,
    this.highlightOpacity = 0.06,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // لون خفيف متكيّف مع الثيم:
    final Color baseTint = tintColor ??
        (cs.brightness == Brightness.dark
            ? cs.primary.withOpacity(0.18)
            : cs.primary.withOpacity(0.12));

    final container = Container(
      decoration: BoxDecoration(
        borderRadius: AppTokens.br16,
        // حدود مضيئة خفيفة
        border: Border.all(
          color: cs.onSurface.withOpacity(borderOpacity),
          width: 1,
        ),
        // تدرّج يعطي عمق + Tint خفيف
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            baseTint.withOpacity(opacity + 0.06),
            baseTint.withOpacity(opacity),
          ],
        ),
      ),
      child: Stack(
        children: [
          // (اختياري) Noise texture بسيط — أضفه لاحقًا كأصل إن رغبت
          if (showNoise)
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: const AssetImage('assets/noise.png'),
                      fit: BoxFit.cover,
                      opacity: 0.04,
                    ),
                  ),
                ),
              ),
            ),
          // highlight داخلي لطيف من الأعلى
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: AppTokens.br16,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.center,
                    colors: [
                      Colors.white.withOpacity(highlightOpacity),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(padding: padding, child: child),
        ],
      ),
    );

    final glass = ClipRRect(
      borderRadius: AppTokens.br16,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: container,
      ),
    );

    return Container(
      margin: margin,
      child: isEnabled ? glass : Container(
        decoration: BoxDecoration(
          borderRadius: AppTokens.br16,
          color: baseTint.withOpacity(opacity),
          border: Border.all(color: cs.onSurface.withOpacity(borderOpacity)),
        ),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
