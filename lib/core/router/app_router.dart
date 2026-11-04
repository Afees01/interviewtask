import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/categories/presentation/pages/category_management_screen.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/auth/presentation/pages/login_screen.dart';
import '../../features/auth/presentation/pages/profile_screen.dart';
import 'main_screen.dart';

class AppRouter {
  AppRouter(AuthBloc authBloc)
      : _authBloc = authBloc,
        _refreshListenable = _AuthRouterRefresh(authBloc) {
    router = GoRouter(
      initialLocation: '/profile',
      refreshListenable: _refreshListenable,
      redirect: (context, state) {
        final authState = _authBloc.state;
        if (authState is AuthLoading) {
          return null;
        }

        final isAuthenticated = authState is AuthAuthenticated;
        final isLoginRoute = state.matchedLocation == '/login';
        if (!isAuthenticated && !isLoginRoute) {
          return '/login';
        }
        if (isAuthenticated && (isLoginRoute || state.matchedLocation == '/')) {
          return '/profile';
        }
        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) => MainScreen(
            navigationShell: navigationShell,
          ),
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/profile',
                  builder: (context, state) => const ProfileScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/categories',
                  builder: (context, state) => const CategoryManagementScreen(),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  final AuthBloc _authBloc;
  final _AuthRouterRefresh _refreshListenable;
  late final GoRouter router;

  void dispose() {
    router.dispose();
    _refreshListenable.dispose();
  }
}

class _AuthRouterRefresh extends ChangeNotifier {
  _AuthRouterRefresh(AuthBloc authBloc) {
    _subscription = authBloc.stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<AuthState> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
