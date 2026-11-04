import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:interviewtask/core/di/injection_container.dart';
import 'package:interviewtask/features/categories/domain/usecases/add_category.dart'
    as add_use_case;
import 'package:interviewtask/features/categories/presentation/bloc/category_bloc.dart';
import 'package:interviewtask/features/categories/presentation/bloc/category_state.dart';
import 'package:interviewtask/features/categories/presentation/pages/category_management_screen.dart';
import 'package:interviewtask/core/session/user_session.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      UserSession.authenticatedUserIdKey: 1,
    });
    await configureDependencies(databasePath: ':memory:');
  });

  tearDown(() async {
    await getIt.reset();
  });

  late CategoryBloc categoryBloc;

  Future<void> pumpUntilIdle(WidgetTester tester) async {
    bool isLoading(CategoryState state) =>
        state is CategoryLoading || state is CategorySearchLoading;
    bool isFinished(CategoryState state) =>
        state is CategoryLoaded ||
        state is CategoryError ||
        state is CategorySearchSuccess ||
        state is CategorySearchEmpty ||
        state is CategorySearchError;

    var sawLoading = isLoading(categoryBloc.state);
    for (var attempt = 0; attempt < 60; attempt++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump(const Duration(milliseconds: 100));
      if (isLoading(categoryBloc.state)) {
        sawLoading = true;
      } else if (sawLoading && isFinished(categoryBloc.state)) {
        await tester.pump(const Duration(milliseconds: 300));
        return;
      }
    }
    fail(
        'Category operation did not finish: ${categoryBloc.state.runtimeType}');
  }

  Future<void> pumpCategoryScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      BlocProvider(
        create: (_) {
          categoryBloc = getIt<CategoryBloc>();
          return categoryBloc;
        },
        child: const MaterialApp(home: CategoryManagementScreen()),
      ),
    );
    await pumpUntilIdle(tester);
  }

  testWidgets('creates and displays a root category and subcategory',
      (tester) async {
    await pumpCategoryScreen(tester);

    expect(find.text('No categories yet'), findsOneWidget);
    await tester.tap(find.text('Create first category'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('category-name-field')),
      'Work',
    );
    await tester.tap(find.text('Add category').last);
    await pumpUntilIdle(tester);

    expect(find.text('Work'), findsOneWidget);
    await tester.tap(find.byTooltip('Add subcategory to Work'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('category-name-field')),
      'Projects',
    );
    await tester.tap(find.text('Add category').last);
    await pumpUntilIdle(tester);

    expect(find.text('Work'), findsOneWidget);
    expect(find.text('Projects'), findsOneWidget);
  });

  testWidgets('shows duplicate name validation in the form', (tester) async {
    await pumpCategoryScreen(tester);

    await tester.tap(find.text('Create first category'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('category-name-field')),
      'Personal',
    );
    await tester.tap(find.text('Add category').last);
    await pumpUntilIdle(tester);

    await tester.tap(find.text('Add category').first);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('category-name-field')),
      'Personal',
    );
    await tester.tap(find.text('Add category').last);
    await pumpUntilIdle(tester);

    expect(
      find.text('A category with this name already exists under this parent.'),
      findsOneWidget,
    );
    expect(find.byType(AlertDialog), findsOneWidget);
  });

  testWidgets('search preserves matching categories in their tree context',
      (tester) async {
    await tester.runAsync(() async {
      final root = await getIt<add_use_case.AddCategory>()('Home');
      await getIt<add_use_case.AddCategory>()('Reading', parentId: root.id);
      await getIt<add_use_case.AddCategory>()('Office');
    });

    await pumpCategoryScreen(tester);
    await tester.enterText(find.byType(TextField), 'reading');
    await pumpUntilIdle(tester);

    expect(FocusManager.instance.primaryFocus?.hasFocus, isTrue);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Reading'), findsOneWidget);
    expect(find.text('Office'), findsNothing);
  });

  testWidgets('multiple search results use unique hierarchy keys',
      (tester) async {
    late int firstMatchId;
    late int secondMatchId;
    await tester.runAsync(() async {
      final firstRoot = await getIt<add_use_case.AddCategory>()('Group A');
      final secondRoot = await getIt<add_use_case.AddCategory>()('Group B');
      firstMatchId = (await getIt<add_use_case.AddCategory>()(
        'Common',
        parentId: firstRoot.id,
      ))
          .id!;
      secondMatchId = (await getIt<add_use_case.AddCategory>()(
        'Common',
        parentId: secondRoot.id,
      ))
          .id!;
    });

    await pumpCategoryScreen(tester);
    await tester.enterText(
        find.byKey(const ValueKey('category-search-field')), 'common');
    await pumpUntilIdle(tester);

    expect(find.text('Matched: Common'), findsNWidgets(2));
    expect(find.text('Group A'), findsOneWidget);
    expect(find.text('Group B'), findsOneWidget);
    expect(
      find.byKey(ValueKey('search-result-$firstMatchId')),
      findsOneWidget,
    );
    expect(
      find.byKey(ValueKey('search-result-$secondMatchId')),
      findsOneWidget,
    );
  });

  testWidgets(
      'renders and expands a deep category tree at mobile, tablet, '
      'and desktop sizes', (tester) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 480);

    await tester.runAsync(() async {
      final root = await getIt<add_use_case.AddCategory>()('Electronics');
      final mobile = await getIt<add_use_case.AddCategory>()(
        'Mobile',
        parentId: root.id,
      );
      final android = await getIt<add_use_case.AddCategory>()(
        'Android',
        parentId: mobile.id,
      );
      await getIt<add_use_case.AddCategory>()(
        'Samsung',
        parentId: android.id,
      );
    });

    await pumpCategoryScreen(tester);
    await tester.ensureVisible(find.text('Mobile'));
    await tester.tap(find.text('Mobile'));
    await tester.pump();
    await tester.ensureVisible(find.text('Android'));
    await tester.tap(find.text('Android'));
    await tester.pump();

    expect(find.text('Electronics'), findsOneWidget);
    expect(find.text('Mobile'), findsOneWidget);
    expect(find.text('Android'), findsOneWidget);
    expect(find.text('Samsung'), findsOneWidget);

    for (final size in [
      const Size(768, 1024),
      const Size(1440, 900),
    ]) {
      tester.view.physicalSize = size;
      await tester.pump();
      expect(find.text('Electronics'), findsOneWidget);
      expect(find.text('Samsung'), findsOneWidget);
    }
  });

  testWidgets('empty state remains scrollable on a short mobile viewport',
      (tester) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 360);

    await pumpCategoryScreen(tester);

    expect(find.text('No categories yet'), findsOneWidget);
    await tester.ensureVisible(find.text('Create first category'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('edits a category and confirms deleting its subtree',
      (tester) async {
    await tester.runAsync(() async {
      final root = await getIt<add_use_case.AddCategory>()('Archive');
      await getIt<add_use_case.AddCategory>()('Old files', parentId: root.id);
    });

    await pumpCategoryScreen(tester);
    await tester.tap(find.byTooltip('Edit Archive'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('category-name-field')),
      'Documents',
    );
    await tester.tap(find.text('Save changes'));
    await pumpUntilIdle(tester);
    expect(find.text('Documents'), findsOneWidget);

    await tester.tap(find.byTooltip('Delete Documents'));
    await tester.pumpAndSettle();
    expect(
        find.textContaining('all of its nested subcategories'), findsOneWidget);
    await tester.tap(find.text('Delete').last);
    await pumpUntilIdle(tester);

    expect(find.text('No categories yet'), findsOneWidget);
  });
}
