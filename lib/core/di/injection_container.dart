import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../../features/categories/data/datasources/category_local_data_source.dart';
import '../../features/categories/data/repositories/category_repository_impl.dart';
import '../../features/categories/domain/repositories/category_repository.dart';
import '../../features/categories/domain/usecases/add_category.dart';
import '../../features/categories/domain/usecases/delete_category.dart';
import '../../features/categories/domain/usecases/get_categories.dart';
import '../../features/categories/domain/usecases/get_children.dart';
import '../../features/categories/domain/usecases/search_categories.dart'
    as search_use_case;
import '../../features/categories/domain/usecases/update_category.dart';
import '../../features/categories/presentation/bloc/category_bloc.dart';
import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/login_with_user_id.dart';
import '../../features/auth/domain/usecases/logout.dart';
import '../../features/auth/domain/usecases/restore_session.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../database/app_database.dart';
import '../router/app_router.dart';
import '../session/user_session.dart';

final GetIt getIt = GetIt.instance;

Future<void> configureDependencies({String? databasePath}) async {
  final sharedPreferences = await SharedPreferences.getInstance();
  final database = await const AppDatabase().open(databasePath: databasePath);

  getIt.registerLazySingleton<SharedPreferences>(() => sharedPreferences);
  getIt.registerLazySingleton<UserSession>(
    () => UserSession(getIt<SharedPreferences>()),
  );
  getIt.registerSingleton<Database>(
    database,
    dispose: (database) => database.close(),
  );
  getIt.registerLazySingleton<Dio>(
    () => Dio(
      BaseOptions(
        baseUrl: 'https://jsonplaceholder.typicode.com',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        sendTimeout: const Duration(seconds: 10),
        contentType: Headers.jsonContentType,
        responseType: ResponseType.json,
        validateStatus: (status) =>
            status != null && status >= 200 && status < 300,
      ),
    ),
  );
  getIt.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(getIt<Dio>()),
  );
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: getIt<AuthRemoteDataSource>(),
      userSession: getIt<UserSession>(),
    ),
  );
  getIt.registerLazySingleton(
    () => LoginWithUserId(getIt<AuthRepository>()),
  );
  getIt.registerLazySingleton(
    () => RestoreSession(getIt<AuthRepository>()),
  );
  getIt.registerLazySingleton(() => Logout(getIt<AuthRepository>()));
  getIt.registerFactory(
    () => AuthBloc(
      loginWithUserId: getIt<LoginWithUserId>(),
      restoreSession: getIt<RestoreSession>(),
      logout: getIt<Logout>(),
    ),
  );
  getIt.registerLazySingleton<CategoryLocalDataSource>(
    () => CategoryLocalDataSourceImpl(
      getIt<Database>(),
      getIt<UserSession>(),
    ),
  );
  getIt.registerLazySingleton<CategoryRepository>(
    () => CategoryRepositoryImpl(getIt<CategoryLocalDataSource>()),
  );
  getIt.registerLazySingleton(() => AddCategory(getIt<CategoryRepository>()));
  getIt.registerLazySingleton(
    () => UpdateCategory(getIt<CategoryRepository>()),
  );
  getIt.registerLazySingleton(
    () => DeleteCategory(getIt<CategoryRepository>()),
  );
  getIt.registerLazySingleton(
    () => GetCategories(getIt<CategoryRepository>()),
  );
  getIt.registerLazySingleton(() => GetChildren(getIt<CategoryRepository>()));
  getIt.registerLazySingleton(
    () => search_use_case.SearchCategories(getIt<CategoryRepository>()),
  );
  getIt.registerFactory(
    () => CategoryBloc(
      addCategory: getIt<AddCategory>(),
      updateCategory: getIt<UpdateCategory>(),
      deleteCategory: getIt<DeleteCategory>(),
      getCategories: getIt<GetCategories>(),
      getChildren: getIt<GetChildren>(),
      searchCategories: getIt<search_use_case.SearchCategories>(),
    ),
  );
  getIt.registerFactoryParam<AppRouter, AuthBloc, void>(
    (authBloc, _) => AppRouter(authBloc),
  );
}
