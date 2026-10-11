import 'package:flutter/material.dart';

import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/welcome_screen.dart';
import 'dart:async';
import 'screens/home/home_screen.dart';
import 'services/pennypal_service.dart';

class PennyPalTheme {
  static const navy = Color(0xFF0B1F3A);
  static const navy2 = Color(0xFF15365F);
  static const mint = Color(0xFF22C7A8);
  static const sky = Color(0xFF4F8CFF);
  static const ink = Color(0xFF102033);
  static const muted = Color(0xFF66758A);
  static const canvas = Color(0xFFF6F8FC);
  static const line = Color(0xFFE3E9F2);
  static const danger = Color(0xFFE85D75);
  static const amber = Color(0xFF2563EB);
  static const gold = Color(0xFF2563EB);

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: navy,
      brightness: Brightness.light,
    ).copyWith(
      primary: navy,
      secondary: mint,
      surface: Colors.white,
      error: danger,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: canvas,
      fontFamily: 'sans-serif',
      appBarTheme: const AppBarTheme(
        backgroundColor: canvas,
        foregroundColor: ink,
        elevation: 0,
        toolbarHeight: 68,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 1,
        shadowColor: const Color(0x140B1F3A),
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: line),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        labelStyle: const TextStyle(color: muted),
        hintStyle: const TextStyle(color: Color(0xFF9AA6B5)),
        prefixIconColor: muted,
        suffixIconColor: muted,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: navy, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: danger),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: navy,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: navy,
          minimumSize: const Size(0, 50),
          side: const BorderSide(color: line),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        elevation: 0,
        height: 76,
        indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        indicatorColor: const Color(0xFFE5EEFF),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
            color: selected ? navy : muted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: selected ? 24 : 22,
            color: selected ? navy : muted,
          );
        }),
      ),
      dividerTheme: const DividerThemeData(color: line, thickness: 1),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: navy,
        contentTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        insetPadding: const EdgeInsets.all(16),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        showDragHandle: true,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }

  static ThemeData dark() => ThemeData.dark(useMaterial3: true).copyWith(
        colorScheme: ColorScheme.fromSeed(seedColor: mint, brightness: Brightness.dark),
      );
}

PageRoute<T> pennyPalRoute<T>(Widget page, {RouteSettings? settings}) => PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (_, __, ___) => page,
      transitionDuration: const Duration(milliseconds: 360),
      reverseTransitionDuration: const Duration(milliseconds: 260),
      transitionsBuilder: (_, animation, __, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        final slide = Tween<Offset>(
          begin: const Offset(-0.14, 0),
          end: Offset.zero,
        ).animate(curved);
        final fade = Tween<double>(begin: 0, end: 1).animate(curved);
        final scale = Tween<double>(begin: .985, end: 1).animate(curved);
        return FadeTransition(
          opacity: fade,
          child: SlideTransition(
            position: slide,
            child: ScaleTransition(scale: scale, child: child),
          ),
        );
      },
    );

class PennyPalApp extends StatefulWidget {
  const PennyPalApp({super.key});

  @override
  State<PennyPalApp> createState() => _PennyPalAppState();
}

class _PennyPalAppState extends State<PennyPalApp> {
  bool dark = false;
  bool showSplash = true;
  Timer? _splashTimer;

  @override
  void initState() {
    super.initState();
    _splashTimer = Timer(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => showSplash = false);
    });
  }

  @override
  void dispose() {
    _splashTimer?.cancel();
    super.dispose();
  }

  void toggle() => setState(() => dark = !dark);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PennyPal',
      theme: PennyPalTheme.light(),
      darkTheme: PennyPalTheme.dark(),
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      home: showSplash
          ? const SplashScreen()
          : StreamBuilder(
              stream: PennyPalService.auth.authStateChanges(),
              initialData: PennyPalService.auth.currentUser,
              builder: (context, snapshot) {
                // Never show a second indefinite splash while Firebase restores
                // the session. currentUser gives us an immediate answer.
                return snapshot.data == null ? const WelcomeScreen() : const HomeScreen();
              },
            ),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/welcome':
            return pennyPalRoute(const WelcomeScreen(), settings: settings);
          case '/login':
            return pennyPalRoute(const LoginScreen(), settings: settings);
          case '/register':
            return pennyPalRoute(const RegisterScreen(), settings: settings);
          default:
            return pennyPalRoute(const WelcomeScreen(), settings: settings);
        }
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..forward();
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scale = Tween<double>(begin: .96, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PennyPalTheme.navy,
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const PennyPalLogo(showWordmark: false, size: 82),
                const SizedBox(height: 22),
                const Text(
                  'PennyPal',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.7,
                  ),
                ),
                const SizedBox(height: 7),
                const Text(
                  'Your money, clearer.',
                  style: TextStyle(color: Color(0xFFBFD0E8), fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PennyPalLogo extends StatelessWidget {
  final bool showWordmark;
  final double size;
  final Color? wordmarkColor;

  const PennyPalLogo({super.key, this.showWordmark = true, this.size = 46, this.wordmarkColor});

  @override
  Widget build(BuildContext context) {
    final mark = ClipRRect(
      borderRadius: BorderRadius.circular(size * .22),
      child: Image.asset(
        'assets/branding/pennypal_logo.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.high,
        semanticLabel: 'PennyPal logo',
      ),
    );

    if (!showWordmark) return mark;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        const SizedBox(width: 11),
        RichText(
          text: TextSpan(
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.7,
                  height: 1,
                ),
            children: [
              TextSpan(
                text: 'Penny',
                style: TextStyle(color: wordmarkColor ?? PennyPalTheme.ink),
              ),
              const TextSpan(
                text: 'Pal',
                style: TextStyle(color: PennyPalTheme.sky),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
