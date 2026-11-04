import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/user.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (state is AuthFailure) {
          return Scaffold(
            appBar: AppBar(title: const Text('Profile')),
            body: Center(child: Text(state.message)),
          );
        }
        if (state is! AuthAuthenticated) {
          return const Scaffold(body: SizedBox.shrink());
        }

        return _ProfileContent(user: state.user);
      },
    );
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            tooltip: 'Manage categories',
            onPressed: () => context.go('/categories'),
            icon: const Icon(Icons.account_tree_outlined),
          ),
          IconButton(
            tooltip: 'Log out',
            onPressed: () {
              context.read<AuthBloc>().add(const LogoutRequested());
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 36,
                            child: Text(
                              user.name.isEmpty
                                  ? '?'
                                  : user.name.characters.first.toUpperCase(),
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            user.name,
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _ProfileDetail(
                      icon: Icons.alternate_email,
                      label: 'Username',
                      value: user.username,
                    ),
                    _ProfileDetail(
                      icon: Icons.email_outlined,
                      label: 'Email',
                      value: user.email,
                    ),
                    _ProfileDetail(
                      icon: Icons.phone_outlined,
                      label: 'Phone',
                      value: user.phone,
                    ),
                    _ProfileDetail(
                      icon: Icons.language,
                      label: 'Website',
                      value: user.website,
                    ),
                    _ProfileDetail(
                      icon: Icons.business_outlined,
                      label: 'Company',
                      value: user.company,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileDetail extends StatelessWidget {
  const _ProfileDetail({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(label),
      subtitle: Text(value),
    );
  }
}
