import 'package:flutter/material.dart';
import 'tokens.dart';

class AppTheme {
  static ThemeData lightTheme() {
    const scheme = ColorScheme.light(
      primary: Cores.action,
      onPrimary: Colors.white,
      secondary: Cores.brand,
      onSecondary: Colors.white,
      surface: Cores.card,
      onSurface: Cores.text,
      error: Cores.dangerSoftText,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: Cores.bg,
      fontFamily: Fontes.texto,
      textTheme: TextTheme(
        displayLarge: Texto.counter,
        headlineLarge: Texto.display,
        headlineMedium: Texto.h2,
        titleLarge: Texto.h3,
        titleMedium: Texto.bodyL,
        bodyLarge: Texto.body,
        bodyMedium: Texto.body,
        labelLarge: Texto.button,
        labelMedium: Texto.label,
        bodySmall: Texto.caption,
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: Cores.action,
        selectionHandleColor: Cores.action,
      ),
      splashFactory: InkSparkle.splashFactory,
      pageTransitionsTheme: const PageTransitionsTheme(),
    );
  }
}
