import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:interviewtask/core/di/injection_container.dart';
import 'package:interviewtask/main.dart';
import 'package:interviewtask/core/session/user_session.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await configureDependencies(databasePath: ':memory:');
  });

  tearDown(() async {
    await getIt.reset();
  });

  void stubUserApi() {
    getIt<Dio>().interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.resolve(
            Response<Object?>(
              requestOptions: options,
              data: {
                'id': 1,
                'name': 'Leanne Graham',
                'username': 'Bret',
                'email': 'Sincere@april.biz',
                'phone': '1-770-736-8031 x56442',
                'website': 'hildegard.org',
                'company': {'name': 'Romaguera-Crona'},
              },
            ),
          );
        },
      ),
    );
  }

  testWidgets('shows login and validates a missing user ID', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('User ID'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a positive numeric user ID.'), findsOneWidget);
  });

  testWidgets('login opens Profile and bottom navigation preserves both tabs',
      (tester) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 480);
    stubUserApi();
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), '1');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Profile'), findsNWidgets(2));
    expect(find.text('Leanne Graham'), findsNWidgets(2));
    expect(find.text('Bret'), findsOneWidget);
    expect(find.text('Sincere@april.biz'), findsOneWidget);
    expect(find.text('1-770-736-8031 x56442'), findsOneWidget);
    expect(find.text('hildegard.org'), findsOneWidget);
    expect(find.text('Romaguera-Crona'), findsOneWidget);

    for (final size in [
      const Size(768, 1024),
      const Size(1440, 900),
    ]) {
      tester.view.physicalSize = size;
      await tester.pump();
      expect(find.text('Leanne Graham'), findsNWidgets(2));
    }

    tester.view.physicalSize = const Size(800, 600);
    await tester.pump();
    await tester.tap(find.text('Categories').last);
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Your categories'), findsOneWidget);
    expect(find.text('No categories yet'), findsOneWidget);

    await tester.tap(find.text('Profile').last);
    await tester.pumpAndSettle();
    expect(find.text('Leanne Graham'), findsNWidgets(2));
  });

  testWidgets('restored session opens Profile and logout returns to Login',
      (tester) async {
    final preferences = getIt<SharedPreferences>();
    await preferences.setInt(UserSession.authenticatedUserIdKey, 1);
    stubUserApi();

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('Leanne Graham'), findsNWidgets(2));
    await tester.tap(find.byTooltip('Log out'));
    await tester.pumpAndSettle();
    expect(find.text('Your saved session will be cleared.'), findsOneWidget);
    await tester.tap(find.text('Log out').last);
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(preferences.getInt(UserSession.authenticatedUserIdKey), isNull);
  });

  testWidgets('saved session restores after the application is restarted',
      (tester) async {
    stubUserApi();
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), '1');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Leanne Graham'), findsNWidgets(2));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('Leanne Graham'), findsNWidgets(2));
    expect(find.text('Welcome back'), findsNothing);
  });

  testWidgets('logout is available from the Categories tab', (tester) async {
    final preferences = getIt<SharedPreferences>();
    await preferences.setInt(UserSession.authenticatedUserIdKey, 1);
    stubUserApi();

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Categories').last);
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Your categories'), findsOneWidget);
    await tester.tap(find.byTooltip('Log out'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log out').last);
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(preferences.getInt(UserSession.authenticatedUserIdKey), isNull);
  });
}
