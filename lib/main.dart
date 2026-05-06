import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'services/bankak_store.dart';
import 'services/native_integration_service.dart';
import 'ui/screens/setup_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final prefs = await SharedPreferences.getInstance();
  const secureStorage = FlutterSecureStorage();
  
  final store = BankakStore(prefs, secureStorage);
  final nativeService = NativeIntegrationService(store);
  
  // Initialize native listener for incoming SMS
  nativeService.initialize();

  runApp(
    ChangeNotifierProvider(
      create: (context) => store,
      child: const BankakApp(),
    ),
  );
}

class BankakApp extends StatelessWidget {
  const BankakApp({super.key});

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<BankakStore>(context);
    
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Vault',
      locale: Locale(store.isArabic ? 'ar' : 'en'),
      supportedLocales: const [Locale('en'), Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.blueAccent,
        textTheme: store.isArabic 
          ? GoogleFonts.alexandriaTextTheme(ThemeData.dark().textTheme)
          : GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
      ),
      // Start with SetupScreen to check for permissions
      home: const SetupScreen(),
    );
  }
}
