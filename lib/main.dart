import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import 'core/di/injection_container.dart';
import 'core/router/app_router.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_state.dart';
import 'features/categories/presentation/bloc/category_bloc.dart';
import 'features/categories/presentation/bloc/category_event.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AuthBloc _authBloc;
  late final AppRouter _appRouter;

  @override
  void initState() {
    super.initState();
    _authBloc = GetIt.instance<AuthBloc>();
    _appRouter = GetIt.instance<AppRouter>(param1: _authBloc);
  }

  @override
  void dispose() {
    _appRouter.dispose();
    _authBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: _authBloc),
        BlocProvider<CategoryBloc>(
          lazy: false,
          create: (_) => GetIt.instance<CategoryBloc>(),
        ),
      ],
      child: BlocListener<AuthBloc, AuthState>(
        listenWhen: (previous, current) {
          if (previous is AuthAuthenticated && current is! AuthAuthenticated) {
            return true;
          }
          return previous is AuthAuthenticated &&
              current is AuthAuthenticated &&
              previous.user.id != current.user.id;
        },
        listener: (context, state) {
          context.read<CategoryBloc>().add(const ClearCategories());
        },
        child: MaterialApp.router(
          title: 'Category Manager',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF315C50),
              brightness: Brightness.light,
            ),
            useMaterial3: true,
            inputDecorationTheme: const InputDecorationTheme(
              border: OutlineInputBorder(),
            ),
          ),
          routerConfig: _appRouter.router,
        ),
      ),
    );
  }
}
