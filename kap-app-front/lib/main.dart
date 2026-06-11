// lib/main.dart

import 'package:flutter/material.dart' as m;
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart' as loc;
import 'package:provider/provider.dart';

import 'core/localization/app_localizations.dart';
import 'features/product/providers/product_provider.dart';
import 'features/auth/presentation/screens/login_screen.dart';

void main() {
  runApp(const KappApp());
}

class KappApp extends m.StatelessWidget {
  const KappApp({super.key});

  @override
  m.Widget build(m.BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProductProvider()),
      ],
      // MaterialApp YERİNE ShadcnApp KULLANIYORUZ
      child: ShadcnApp(
        title: 'Kap-App',
        debugShowCheckedModeBanner: false,
        
        // Shadcn Özel Teması
        theme: ThemeData(
          colorScheme: ColorSchemes.darkZinc, 
        ),

        // ── Lokalizasyon ─────────────────────────────────────────────────────
        locale: const m.Locale('tr'),
        supportedLocales: const [m.Locale('tr'), m.Locale('en')],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          loc.GlobalMaterialLocalizations.delegate,
          loc.GlobalWidgetsLocalizations.delegate,
          loc.GlobalCupertinoLocalizations.delegate,
        ],

        // ── Ana Ekran ─────────────────────────────────────────────────────────
        home: const LoginScreen(),
      ),
    );
  }
}

