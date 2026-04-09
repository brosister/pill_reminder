import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'pages/pill_reminder_home_page.dart';
import 'services/reminder_service.dart';

Future<void> _warmUpServices() async {
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: Color(0xFFF3F6FB),
    systemNavigationBarIconBrightness: Brightness.dark,
  ));
  await ReminderService.instance.initialize();
  if (!kIsWeb) {
    await MobileAds.instance.initialize();
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  unawaited(_warmUpServices());
  runApp(const PillReminderApp());
}

class PillReminderApp extends StatelessWidget {
  const PillReminderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) {
        final code =
            Localizations.localeOf(context).languageCode.toLowerCase();
        return code == 'ko' ? '약 알리미' : 'Pill Reminder';
      },
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ko'), Locale('en')],
      theme: ThemeData(
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF3F6FB),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.dark,
          ),
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF3F6FB),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7A5AF8),
          brightness: Brightness.light,
        ),
      ),
      home: const PillReminderHomePage(),
    );
  }
}
