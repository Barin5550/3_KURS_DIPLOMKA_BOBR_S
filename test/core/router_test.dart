import 'package:flutter_test/flutter_test.dart';
import 'package:marshrut/core/router/app_router.dart';
import 'package:marshrut/presentation/providers/auth_controller.dart';

/// Правило доступа к экранам (redirect в go_router).
void main() {
  const closed = ['/home', '/plan', '/profile', '/onboarding', '/session/1'];

  test('пока сессия проверяется, виден только Splash', () {
    expect(authRedirect(AuthStatus.unknown, '/splash'), isNull);
    for (final location in [...closed, '/login']) {
      expect(authRedirect(AuthStatus.unknown, location), '/splash');
    }
  });

  test('без входа закрытые экраны ведут на вход', () {
    for (final location in [...closed, '/splash']) {
      expect(
        authRedirect(AuthStatus.unauthenticated, location),
        '/login',
        reason: location,
      );
    }
    expect(authRedirect(AuthStatus.unauthenticated, '/login'), isNull);
    expect(authRedirect(AuthStatus.unauthenticated, '/register'), isNull);
  });

  test('после входа экраны входа и Splash ведут на главную', () {
    for (final location in ['/login', '/register', '/splash']) {
      expect(authRedirect(AuthStatus.authenticated, location), '/home');
    }
    for (final location in closed) {
      expect(authRedirect(AuthStatus.authenticated, location), isNull);
    }
  });
}
