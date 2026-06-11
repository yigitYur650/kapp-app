// lib/main.dart
//
// Kap-App giriş noktası.
// Provider DI, lokalizasyon ve tema burada wiring edilir.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/localization/app_localizations.dart';
import 'core/theme/app_theme.dart';
import 'features/product/providers/product_provider.dart';
import 'features/home/presentation/screens/main_layout.dart';

void main() {
  runApp(const KappApp());
}

class KappApp extends StatelessWidget {
  const KappApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProductProvider()),
      ],
      child: MaterialApp(
        title: 'Kap-App',
        debugShowCheckedModeBanner: false,

        // ── Tema ────────────────────────────────────────────────────────────
        theme: AppTheme.lightTheme(),
        darkTheme: AppTheme.darkTheme(),
        themeMode: ThemeMode.dark, // varsayılan koyu tema

        // ── Lokalizasyon ─────────────────────────────────────────────────────
        locale: const Locale('tr'),
        supportedLocales: const [Locale('tr'), Locale('en')],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],

        // ── Ana Ekran ─────────────────────────────────────────────────────────
        home: const MainLayout(),
      ),
    );
  }
}
