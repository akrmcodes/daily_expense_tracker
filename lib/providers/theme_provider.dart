import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// يحتفظ بحالة الثيم الحالي (فاتح/داكن)
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.dark);
