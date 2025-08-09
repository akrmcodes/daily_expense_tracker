import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData light() {
    final scheme = FlexThemeData.light(
      useMaterial3: true,
      scheme: FlexScheme.indigoM3, // نقطة بداية لطيفة
      fontFamily: GoogleFonts.cairo().fontFamily,
    );
    return scheme.copyWith(
      textTheme: GoogleFonts.cairoTextTheme(scheme.textTheme),
    );
  }

  static ThemeData dark() {
    final scheme = FlexThemeData.dark(
      useMaterial3: true,
      scheme: FlexScheme.indigoM3,
      fontFamily: GoogleFonts.cairo().fontFamily,
    );
    return scheme.copyWith(
      textTheme: GoogleFonts.cairoTextTheme(scheme.textTheme),
    );
  }
}
