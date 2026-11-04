import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/user.dart';
import '../bloc/auth_bloc.dart';
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
            body: SafeArea(
              child: Center(
                child: _FadeSlideIn(child: Text(state.message)),
              ),
            ),
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
    final colors = Theme.of(context).colorScheme;
    final details = [
      (Icons.person_outline, 'Name', user.name),
      (Icons.alternate_email, 'Username', user.username),
      (Icons.email_outlined, 'Email', user.email),
      (Icons.phone_outlined, 'Phone', user.phone),
      (Icons.language, 'Website', user.website),
      (Icons.business_outlined, 'Company', user.company),
    ];

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: _FadeSlideIn(
              offset: 28,
              duration: 500,
              child: Card(
                elevation: 0,
                color: colors.surfaceContainerLow,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: BorderSide(color: colors.outlineVariant),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Column(
                          children: [
                            TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.4, end: 1),
                              duration: const Duration(milliseconds: 750),
                              curve: Curves.elasticOut,
                              builder: (context, scale, child) =>
                                  Transform.scale(scale: scale, child: child),
                              child: CircleAvatar(
                                radius: 40,
                                child: Text(
                                  user.name.isEmpty
                                      ? '?'
                                      : user.name.characters.first
                                          .toUpperCase(),
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            _FadeSlideIn(
                              index: 1,
                              child: Text(
                                user.name,
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      for (var i = 0; i < details.length; i++)
                        _FadeSlideIn(
                          index: i + 2,
                          offset: 12,
                          child: _ProfileDetail(
                            icon: details[i].$1,
                            label: details[i].$2,
                            value: details[i].$3,
                          ),
                        ),
                    ],
                  ),
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
    final colors = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: colors.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 20, color: colors.onPrimaryContainer),
      ),
      title: Text(label),
      subtitle: Text(
        value,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

/// Fade + slide-up entrance. Plays once when first mounted.
class _FadeSlideIn extends StatelessWidget {
  const _FadeSlideIn({
    required this.child,
    this.index = 0,
    this.offset = 16,
    this.duration = 350,
  });

  final Widget child;
  final int index;
  final double offset;
  final int duration;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: duration + index * 80),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, (1 - value) * offset),
          child: child,
        ),
      ),
      child: child,
    );
  }
}
