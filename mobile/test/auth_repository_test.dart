import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:medisathi/data/auth_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AuthRepository Tests', () {
    test('Initial state loads default seed user', () async {
      final auth = AuthRepository();
      await auth.init();

      expect(auth.currentUser, isNotNull);
      expect(auth.currentUser!.name, contains('Sunanda'));
      expect(auth.isLoggedIn, isTrue);
    });

    test('loginWithPin succeeds with correct PIN 1234', () async {
      final auth = AuthRepository();
      await auth.init();

      final success = await auth.loginWithPin('1234');
      expect(success, isTrue);
      expect(auth.isLoggedIn, isTrue);
    });

    test('loginWithPin fails with wrong PIN', () async {
      final auth = AuthRepository();
      await auth.init();

      final success = await auth.loginWithPin('9999');
      expect(success, isFalse);
    });

    test('loginWithPhoneAndOtp succeeds with 4-digit code', () async {
      final auth = AuthRepository();
      await auth.init();

      final success = await auth.loginWithPhoneAndOtp('+91 98200 98765', '9876');
      expect(success, isTrue);
      expect(auth.currentUser!.phone, contains('9820098765'));
      expect(auth.isLoggedIn, isTrue);
    });

    test('registerUser creates new patient profile', () async {
      final auth = AuthRepository();
      await auth.init();

      await auth.registerUser(
        name: 'Ramesh Patil',
        phone: '+91 98989 89898',
        pin: '4321',
        role: 'Caregiver',
      );

      expect(auth.currentUser!.name, equals('Ramesh Patil'));
      expect(auth.currentUser!.role, equals('Caregiver'));
      expect(auth.currentUser!.pin, equals('4321'));
      expect(auth.isLoggedIn, isTrue);
    });

    test('loginAsGuest creates guest user', () async {
      final auth = AuthRepository();
      await auth.init();

      await auth.loginAsGuest();
      expect(auth.currentUser!.isGuest, isTrue);
      expect(auth.currentUser!.role, equals('Guest'));
      expect(auth.isLoggedIn, isTrue);
    });

    test('logout clears logged in status', () async {
      final auth = AuthRepository();
      await auth.init();

      await auth.logout();
      expect(auth.isLoggedIn, isFalse);
    });
  });
}
