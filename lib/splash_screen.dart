import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const CulinaHomePage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // A premium fade-in transition
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Accessing theme colors from main.dart
    final theme = Theme.of(context);

    return Scaffold(
      
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.0,
            colors: [
              theme.colorScheme.surface.withOpacity(0.5), 
              theme.scaffoldBackgroundColor,
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            /// LOTTIE ANIMATION
            Lottie.asset(
              'assets/animations/culina_intro2.json',
              height: 280,
              controller: _controller,
              onLoaded: (composition) {
                _controller
                  ..duration = composition.duration
                  ..forward().then((_) => _navigateToHome());
              },
            ),

            const SizedBox(height: 32),

            
            Text(
              "CULINA AI",
              style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 6.0, 
                    color: Colors.white,
                  ),
            ),

            const SizedBox(height: 12),

            /// TAGLINE
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white10),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "COOK SMART • EAT BETTER",
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary.withOpacity(0.8),
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}