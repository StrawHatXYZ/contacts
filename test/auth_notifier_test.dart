import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:contacts/main.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  });

  test('AuthStateProvider initializes with current Supabase user or null', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final initialUser = container.read(authStateProvider);
    expect(initialUser, isNull);
  });
}
