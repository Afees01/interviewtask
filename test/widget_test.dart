import 'package:flutter_test/flutter_test.dart';
import 'package:interviewtask/core/di/injection_container.dart';
import 'package:interviewtask/main.dart';
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

  testWidgets('shows login and validates a missing user ID', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('User ID'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a positive numeric user ID.'), findsOneWidget);
  });
}
