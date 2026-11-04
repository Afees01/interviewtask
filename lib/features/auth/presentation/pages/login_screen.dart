import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userIdController = TextEditingController();

  @override
  void dispose() {
    _userIdController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(LoginRequested(_userIdController.text));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  final isLoading = state is AuthLoading;
                  final errorMessage =
                      state is AuthFailure ? state.message : null;

                  return Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.5, end: 1),
                          duration: const Duration(milliseconds: 700),
                          curve: Curves.elasticOut,
                          builder: (context, scale, child) =>
                              Transform.scale(scale: scale, child: child),
                          child: Center(
                            child: CircleAvatar(
                              radius: 38,
                              backgroundColor: colors.primaryContainer,
                              child: Icon(
                                Icons.category_outlined,
                                color: colors.onPrimaryContainer,
                                size: 36,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _FadeSlideIn(
                          index: 1,
                          child: Text(
                            'Welcome back',
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _FadeSlideIn(
                          index: 2,
                          child: Text(
                            'Sign in with your user ID to continue.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(color: colors.onSurfaceVariant),
                          ),
                        ),
                        const SizedBox(height: 32),
                        _FadeSlideIn(
                          index: 3,
                          child: TextFormField(
                            controller: _userIdController,
                            enabled: !isLoading,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _submit(),
                            decoration: InputDecoration(
                              labelText: 'User ID',
                              hintText: 'Enter your user ID',
                              prefixIcon: const Icon(Icons.person_outline),
                              filled: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            validator: (value) {
                              final userId = int.tryParse(value?.trim() ?? '');
                              if (userId == null || userId <= 0) {
                                return 'Enter a positive numeric user ID.';
                              }
                              return null;
                            },
                          ),
                        ),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOutCubic,
                          alignment: Alignment.topCenter,
                          child: errorMessage == null
                              ? const SizedBox(width: double.infinity)
                              : _FadeSlideIn(
                                  key: ValueKey(errorMessage),
                                  offset: -8,
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 16),
                                    child: Text(
                                      errorMessage,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: colors.error),
                                    ),
                                  ),
                                ),
                        ),
                        const SizedBox(height: 24),
                        _FadeSlideIn(
                          index: 4,
                          child: FilledButton(
                            onPressed: isLoading ? null : _submit,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                transitionBuilder: (child, animation) =>
                                    FadeTransition(
                                  opacity: animation,
                                  child: ScaleTransition(
                                    scale: animation,
                                    child: child,
                                  ),
                                ),
                                child: isLoading
                                    ? const SizedBox.square(
                                        key: ValueKey('loading'),
                                        dimension: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text(
                                        'Continue',
                                        key: ValueKey('label'),
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Fade + slide-up entrance. Plays once when first mounted.
class _FadeSlideIn extends StatelessWidget {
  const _FadeSlideIn({
    super.key,
    required this.child,
    this.index = 0,
    this.offset = 20,
  });

  final Widget child;
  final int index;
  final double offset;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 350 + index * 90),
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
