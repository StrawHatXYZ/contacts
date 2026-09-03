import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:contacts/main.dart';
import 'package:contacts/login_page.dart';
import 'package:contacts/register_page.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  });

  testWidgets('MyApp renders login page when unauthenticated', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.text('Login'), findsWidgets);
    expect(find.byType(TextField), findsNWidgets(2));
  });

  testWidgets('LoginPage contains email and password input fields and actions', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: LoginPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Login'), findsWidgets);
    expect(find.byType(ElevatedButton), findsOneWidget);
    expect(find.text("Don't have an account? Sign Up"), findsOneWidget);
  });

  testWidgets('RegisterPage contains full registration fields', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: RegisterPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Register'), findsWidgets);
    expect(find.text('Username'), findsOneWidget);
    expect(find.text('Phone Number'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Confirm Password'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsOneWidget);
  });
}
