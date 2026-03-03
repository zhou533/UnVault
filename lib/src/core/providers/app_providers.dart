import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:unvault/src/core/database/app_database.dart';

part 'app_providers.g.dart';

@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
}
