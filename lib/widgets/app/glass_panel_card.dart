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

  const GlassPanelCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppTokens.sp16),
    this.margin = const EdgeInsets.all(AppTokens.sp12),
    this.isEnabled = true,
    this.blurSigma = 12,
    this.opacity = 0.14, // شفافية خفيفة
  });

  @override
  Widget build(BuildContext context) {
    final base = ClipRRect(
      borderRadius: AppTokens.br16,
      child: Container(
        margin: margin,
        decoration: BoxDecoration(
          borderRadius: AppTokens.br16,
          border: Border.all(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.08),
          ),
          color: Theme.of(context).colorScheme.surface.withOpacity(opacity),
        ),
        child: Padding(padding: padding, child: child),
      ),
    );

    if (!isEnabled) return base;

    return ClipRRect(
      borderRadius: AppTokens.br16,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: base,
      ),
    );
  }
}
