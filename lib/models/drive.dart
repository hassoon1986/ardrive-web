import 'package:ardrive/services/services.dart';
import 'package:moor/moor.dart';

import './database/database.dart';

class Drives extends Table {
  TextColumn get id => text()();
  TextColumn get rootFolderId =>
      text().customConstraint('REFERENCES folderEntries(id)')();

  TextColumn get ownerAddress => text()();

  TextColumn get name => text().withLength(min: 1)();

  /// The latest block we've pulled state from.
  IntColumn get latestSyncedBlock => integer().withDefault(const Constant(0))();

  TextColumn get privacy => text()();

  BlobColumn get encryptedKey => blob().nullable()();
  BlobColumn get keyIv => blob().nullable()();

  DateTimeColumn get dateCreated =>
      dateTime().clientDefault(() => DateTime.now())();
  DateTimeColumn get lastUpdated =>
      dateTime().clientDefault(() => DateTime.now())();

  @override
  Set<Column> get primaryKey => {id};
}

extension DriveExtensions on Drive {
  bool get isPublic => privacy == DrivePrivacy.public;
  bool get isPrivate => privacy == DrivePrivacy.private;

  DriveEntity asArFsEntity() => DriveEntity(
        id: id,
        name: name,
        rootFolderId: rootFolderId,
        privacy: privacy,
        authMode:
            privacy == DrivePrivacy.private ? DriveAuthMode.password : null,
      );
}
