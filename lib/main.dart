import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart';
import 'register_page.dart';
import 'home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Supabase.initialize(
      url: 'https://kotncfxpwaeivymcbihi.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtvdG5jZnhwd2FlaXZ5bWNiaWhpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MjY1MzM0MDAsImV4cCI6MjA0MjEwOTQwMH0.NWkKyakE7SINjvrdgOWS54_MWWkz55LZtt_QwVeQpiw',
    );
    print('Supabase initialized successfully');
  } catch (e) {
    print('Error initializing Supabase: $e');
    // You might want to show an error dialog here
  }

  runApp(const ProviderScope(child: MyApp()));
}

final supabase = Supabase.instance.client;

final authStateProvider = StateNotifierProvider<AuthNotifier, User?>((ref) {
  return AuthNotifier();
});

class AuthNotifier extends StateNotifier<User?> {
  AuthNotifier() : super(null) {
    _init();
  }

  void _init() {
    state = supabase.auth.currentUser;
    supabase.auth.onAuthStateChange.listen((data) {
      state = data.session?.user;
    });
  }

  Future<void> signIn(String email, String password) async {
    await supabase.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signUp(String email, String password, String phone, String username) async {
    try {
      // Sign up the user
      final AuthResponse res = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {'phone': phone, 'username': username},
      );

      if (res.user != null) {
        // Insert data into the profiles table
        await supabase.from('profiles').insert({
          'user_uid': res.user!.id,
          'email_personal': email,
          'phone_mobile': phone,
          'name': username,
        });
      }
    } catch (e) {
      print('Error during sign up: $e');
      // You might want to rethrow the error or handle it appropriately
    }
  }

  Future<void> signOut() async {
    await supabase.auth.signOut();
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: authState != null ? const HomePage() : const LoginPage(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/home': (context) => const HomePage(),
      },
      builder: (context, child) {
        return Navigator(
          onGenerateRoute: (settings) {
            return MaterialPageRoute(
              builder: (context) => Scaffold(
                body: Center(
                  child: child,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// Remove the MyHomePage and _MyHomePageState classes as they're no longer needed
