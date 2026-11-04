import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/entities/user.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_event.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';

class AuthenticatedAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const AuthenticatedAppBar({required this.title, super.key});

  final String title;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  Future<void> _confirmLogout(BuildContext context) async {
    FocusManager.instance.primaryFocus?.unfocus();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        insetPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        icon: const Icon(Icons.logout),
        title: const Text('Log out?'),
        content: const Text('Your saved session will be cleared.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<AuthBloc>().add(const LogoutRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final user = state is AuthAuthenticated ? state.user : null;
        return AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Category Manager',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall,
              ),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          actions: [
            if (user != null)
              _ProfileAction(
                user: user,
                onPressed: () {
                  FocusManager.instance.primaryFocus?.unfocus();
                  if (GoRouterState.of(context).matchedLocation != '/profile') {
                    context.go('/profile');
                  }
                },
              ),
            IconButton(
              tooltip: 'Log out',
              onPressed:
                  state is AuthLoading ? null : () => _confirmLogout(context),
              icon: const Icon(Icons.logout),
            ),
          ],
        );
      },
    );
  }
}

class _ProfileAction extends StatelessWidget {
  const _ProfileAction({required this.user, required this.onPressed});

  final User user;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final initial =
        user.name.isEmpty ? '?' : user.name.characters.first.toUpperCase();
    return IconButton(
      tooltip: 'Open profile',
      onPressed: onPressed,
      icon: CircleAvatar(
        radius: 16,
        child: Text(
          initial,
          style: Theme.of(context).textTheme.labelMedium,
        ),
      ),
    );
  }
}
