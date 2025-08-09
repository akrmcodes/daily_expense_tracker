import 'package:flutter/material.dart';
import '../../theme/tokens.dart';

class PanelCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;

  const PanelCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppTokens.sp16),
    this.margin = const EdgeInsets.all(AppTokens.sp12),
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: margin,
      shape: RoundedRectangleBorder(borderRadius: AppTokens.br16),
      child: Padding(padding: padding, child: child),
    );
  }
}
