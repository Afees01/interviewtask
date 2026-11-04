# Category Manager

A Flutter app with a Clean Architecture authentication feature managed by
BLoC. Users sign in with a JSONPlaceholder user ID; profile details are fetched
from `https://jsonplaceholder.typicode.com/users/{id}`. The user ID is stored
with SharedPreferences and is revalidated against the API when the app starts.

Category management includes a responsive Material 3 tree screen backed by the
existing CategoryBloc and Clean Architecture SQLite layer. It supports
recursive nested categories, expand/collapse, hierarchy-aware search, adding
root categories and subcategories, editing names/parents, and confirmed
descendant deletion. Each category is scoped to the signed-in user; duplicate
names are unique within that user's parent hierarchy.

The app uses native `sqflite` on Android/iOS/macOS,
`sqflite_common_ffi` on Linux/Windows, and `sqflite_common_ffi_web` on Flutter
Web. The web backend runs SQLite in WebAssembly and persists the database in
browser IndexedDB. Its worker and WASM assets are `web/sqflite_sw.js` and
`web/sqlite3.wasm`.

The database schema is versioned. On upgrade from the unowned category schema,
old rows are preserved in `legacy_categories` and are not assigned to or
visible to any account because their original owner cannot be determined.

## Run

```shell
flutter pub get
flutter run -d chrome --web-port=7357
```

Enter a user ID from `1` to `10` to log in. The profile screen displays the
user's name, username, email, phone, website, and company from the API. Use the
logout button in the app bar to clear the saved session.

Open category management from the profile screen using the category-tree
button. Expand a category to see its descendants, use the row actions to add a
subcategory, edit, or delete, and use the search box to filter the hierarchy.

To verify web persistence, create categories, stop the app, and run it again
with the same web port. The browser origin (including port) must be unchanged
because IndexedDB storage is scoped to the origin. On native mobile/macOS, the
database is stored in the platform's application database directory. Linux and
Windows use the FFI SQLite factory with the database path provided by
sqflite_common_ffi.

If the WebAssembly or worker assets need to be regenerated after upgrading
`sqflite_common_ffi_web`, run:

```shell
dart run sqflite_common_ffi_web:setup
```

## Validate

```shell
flutter analyze
flutter test
```

The tests cover database initialization, category relationships, duplicate and
empty-name validation, updates, circular reparenting, descendant deletion,
JSON conversion, and persistence after reopening the database.
