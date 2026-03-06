import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Required for SystemChrome
import 'package:google_fonts/google_fonts.dart';
import 'splash_screen.dart';

void main() {
  
  WidgetsFlutterBinding.ensureInitialized();
  
  
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(const CulinaApp());
}

class CulinaApp extends StatelessWidget {
  const CulinaApp({super.key});

  @override
  Widget build(BuildContext context) {
    
    const bg = Color(0xFF0B0F14);      
    const accent = Color(0xFF10A37F);  
    const surface = Color(0xFF161B22); 

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Culina AI',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bg,
        
        // Refined ColorScheme for better button/input styling automatically
        colorScheme: ColorScheme.fromSeed(
          seedColor: accent,
          brightness: Brightness.dark,
          surface: surface,
          primary: accent,
        ),

        // Typography: Inter is great, but let's make it more legible
        textTheme: GoogleFonts.interTextTheme(
          Theme.of(context).textTheme,
        ).apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),

        // Modernized Card & Button Themes
        cardTheme: CardThemeData(
          color: surface,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      
      // Global System UI Overlay (Removes grey bars on Android/iOS)
      builder: (context, child) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.light.copyWith(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: bg,
          ),
          child: child!,
        );
      },
      
      home: const SplashScreen(),
    );
  }
}