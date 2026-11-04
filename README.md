# Flutter Category Manager

A Flutter application for managing unlimited-depth hierarchical categories with user authentication, local database persistence, recursive search, and a responsive Material 3 interface.

Built using **Flutter, Dart, BLoC, Clean Architecture, Dio, and SQLite**.

## Features

### 1. Authentication

- Login using JSONPlaceholder User ID.
- Fetch user information from REST API.
- Validate user ID.
- Persist login session using SharedPreferences.
- Revalidate saved user session when the application starts.
- Logout and clear saved session.

**API Endpoint:**

`https://jsonplaceholder.typicode.com/users/{id}`

Valid demo user IDs: `1–10`.

### 2. User Profile

Display authenticated user information retrieved from the API:

- Name
- Username
- Email
- Phone
- Website
- Company

### 3. Category Management

- Create unlimited root categories.
- Create unlimited nested subcategories.
- Edit category names and parent relationships.
- Delete categories with descendant confirmation.
- Expand and collapse category trees.
- Prevent duplicate category names under the same parent.
- Allow identical category names under different parents.
- Validate category names.
- Isolate category data by authenticated user.

Example:

```text
Electronics
├── Mobile
│   ├── Android
│   │   ├── Samsung
│   │   └── OnePlus
│   └── iPhone
└── Laptop
    └── Gaming

Clothing
└── Mobile
```

The hierarchy supports unlimited nesting without hardcoded levels.

### 4. Recursive Search

- Search categories by name.
- Case-insensitive search.
- Partial name matching.
- Find categories at any hierarchy depth.
- Retrieve parent and child relationships.
- Display complete category hierarchy paths.

Example:

Searching for `Samsung`:

```text
Electronics
└── Mobile
    └── Android
        └── Samsung
```

### 5. Local Database

SQLite is used for persistent category storage.

Database schema:

| Column     | Type    | Description           |
| ---------- | ------- | --------------------- |
| id         | INTEGER | Primary key           |
| user_id    | INTEGER | Authenticated user ID |
| name       | TEXT    | Category name         |
| parent_id  | INTEGER | Parent category ID    |
| created_at | TEXT    | Creation timestamp    |

Features:

- Database versioning.
- Database migrations.
- Parent-child relationships.
- User-specific category isolation.
- Duplicate validation.
- Persistent local storage.

### 6. Responsive Navigation

The application includes two main navigation sections:

- Profile
- Categories

After successful login, the user is redirected to the Profile screen.

The bottom navigation allows switching between Profile and Categories.

## Technology Stack

| Technology         | Purpose              |
| ------------------ | -------------------- |
| Flutter            | UI framework         |
| Dart               | Programming language |
| BLoC               | State management     |
| Clean Architecture | Project architecture |
| Dio                | REST API integration |
| SQLite / sqflite   | Local database       |
| SharedPreferences  | Session persistence  |
| GetIt              | Dependency injection |
| GoRouter           | Navigation           |
| Equatable          | State comparison     |

## Project Architecture

The application follows Clean Architecture with three main layers.

```text
lib/
│
├── core/
│   ├── database/
│   ├── di/
│   ├── errors/
│   ├── network/
│   └── utils/
│
├── features/
│   │
│   ├── auth/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   ├── profile/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   └── categories/
│       ├── data/
│       ├── domain/
│       └── presentation/
│
└── main.dart
```

### Presentation Layer

Contains screens, reusable widgets, BLoC events and states.

### Domain Layer

Contains business entities, repository contracts and use cases.

### Data Layer

Contains API services, database operations, models and repository implementations.

## Database Platform Support

The database implementation uses platform-specific SQLite backends.

| Platform | Database implementation |
| -------- | ----------------------- |
| Android  | Native sqflite          |
| iOS      | Native sqflite          |
| macOS    | Native sqflite          |
| Windows  | sqflite_common_ffi      |
| Linux    | sqflite_common_ffi      |
| Web      | sqflite_common_ffi_web  |

### Flutter Web Database

The Web implementation uses SQLite WebAssembly (WASM) with IndexedDB persistence.

Required assets:

```text
web/
├── sqflite_sw.js
└── sqlite3.wasm
```

To regenerate Web assets after upgrading the database package:

```bash
dart run sqflite_common_ffi_web:setup
```

### Database Migration

The database uses versioned migrations.

When upgrading from the previous category schema without user ownership, existing records are preserved in `legacy_categories`.

These records are not assigned to any user because their original ownership cannot be determined.

## Installation and Setup

### Prerequisites

- Flutter SDK
- Dart SDK
- Android Studio or VS Code
- Google Chrome (for Web testing)

### 1. Clone the Repository

```bash
git clone <your-repository-url>
```

### 2. Navigate to the Project

```bash
cd category_manager
```

### 3. Install Dependencies

```bash
flutter pub get
```

### 4. Run on Web

```bash
flutter run -d chrome --web-port=7357
```

### 5. Run on Android

Connect an Android device with USB debugging enabled.

```bash
flutter devices
flutter run
```

### 6. Build APK

```bash
flutter build apk --release
```

The generated APK is available at:

```text
build/app/outputs/flutter-apk/app-release.apk
```

## How to Use

### Login

1. Launch the application.
2. Enter a valid JSONPlaceholder User ID.
3. Select Login.
4. The application retrieves the user information from the API.
5. After successful login, the Profile screen opens.

Example:

```text
User ID: 1
```

### Profile

View the authenticated user's profile information.

Use the logout action in the authenticated app bar to clear the saved session.

### Categories

1. Open the Categories tab.
2. Select Add Category to create a root category.
3. Expand a category to view its children.
4. Use the row actions to add a subcategory, edit or delete.
5. Use the search field to find categories and their hierarchy paths.

### Persistence

To verify Web persistence:

1. Log in using User ID `1`.
2. Create some categories and subcategories.
3. Stop the application.
4. Restart it using the same Web port.
5. Verify that the saved session and categories remain available.

**Important:** Browser storage is scoped to the origin, including its port. Use the same origin when testing persistence.

On Android and iOS, application data remains available across normal restarts. Uninstalling the application removes its local storage.

## Testing and Validation

Run static analysis:

```bash
flutter analyze
```

Run automated tests:

```bash
flutter test
```

Build Web:

```bash
flutter build web
```

Build Android:

```bash
flutter build apk --debug
```

### Test Scenarios

- Database initialization.
- Category insertion and retrieval.
- Nested parent-child relationships.
- Duplicate category validation.
- Empty category validation.
- Category updates.
- Circular reparenting prevention.
- Descendant deletion.
- JSON model conversion.
- Database persistence after reopening.
- Authentication and session restoration.
- User-specific category isolation.
- Recursive search and hierarchy retrieval.

## Machine Test Compliance Checklist

Before submission, verify the following requirements against the actual implementation:

- [x] API authentication.
- [x] Profile information from API.
- [x] Local database persistence.
- [x] Unlimited-depth hierarchy.
- [x] Category CRUD operations.
- [x] Duplicate category prevention.
- [x] Recursive search.
- [x] Complete hierarchy retrieval.
- [x] Optional result limit.
- [x] Pagination with current page, page size and total count.
- [x] Loading, empty and error states.
- [x] Unit and widget tests.
- [x] README documentation.

## Author

Flutter Developer

**Project:** Local Hierarchical Category Manager

**Framework:** Flutter

**Architecture:** Clean Architecture

**State Management:** BLoC

---

*Developed as part of a Flutter Developer Machine Test.*
