import 'database_factory_initializer_stub.dart'
    if (dart.library.io) 'database_factory_initializer_io.dart'
    if (dart.library.html) 'database_factory_initializer_web.dart' as platform;

void initializeDatabaseFactory() {
  platform.initializePlatformDatabaseFactory();
}
