import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'main_flow.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'firebase_options.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AppBootstrap());
}

class AppBootstrap extends StatefulWidget {
  const AppBootstrap({super.key});

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  late final Future<void> _initFuture;

  @override
  void initState() {
    super.initState();
    _initFuture = _initialize();
  }

  Future<void> _initialize() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 20));
    await Supabase.initialize(
      url: 'https://dfrqfcuwfvvmvbagsdmo.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRmcnFmY3V3ZnZ2bXZiYWdzZG1vIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM0NDQwMzYsImV4cCI6MjA4OTAyMDAzNn0.RyLt6pdVV9nkFOi3MYyb0r5uZAjOtVy47M_EBCXSq9o',
    ).timeout(const Duration(seconds: 20));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              backgroundColor: Color(0xFFEFF2F7),
              body: Center(
                child: CircularProgressIndicator(color: Color(0xFF1D5AFF)),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              backgroundColor: const Color(0xFFEFF2F7),
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Color(0xFFEF4444),
                        size: 40,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'App-ka ma furmin. Fadlan refresh samee.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF111827),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }
        return const MyApp();
      },
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Caruurkaab AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Inter', // Or any default font you prefer
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1D5AFF)),
        useMaterial3: true,
      ),
      builder: (context, child) {
        if (!kIsWeb || child == null) return child ?? const SizedBox.shrink();
        return ColoredBox(
          color: const Color(0xFFEFF2F7),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: child,
            ),
          ),
        );
      },
      home: const MainFlow(),
    );
  }
}
