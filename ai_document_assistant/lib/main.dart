import 'package:flutter/material.dart';

import 'screens/document_assistant_screen.dart';

void main() {
  runApp(const AiDocumentAssistantApp());
}

class AiDocumentAssistantApp extends StatelessWidget {
  const AiDocumentAssistantApp({super.key});

  @override
  Widget build(BuildContext context) {
    const surface = Color(0xFF0B0B0B);
    const surfaceAlt = Color(0xFF171717);
    const accent = Color(0xFFFFFFFF);
    const accentSoft = Color(0xFFE8E8E8);

    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: accent,
          brightness: Brightness.dark,
          surface: surface,
        ).copyWith(
          primary: accent,
          secondary: accentSoft,
          surface: surface,
          onSurface: Colors.white,
        );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AI Document Assistant',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: surface,
        appBarTheme: const AppBarTheme(
          backgroundColor: surface,
          foregroundColor: Colors.white,
          centerTitle: false,
        ),
        cardColor: surfaceAlt,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surfaceAlt,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
        ),
        textTheme: Typography.whiteMountainView,
      ),
      home: const DocumentAssistantScreen(),
    );
  }
}
