import 'package:ardrive/services/services.dart';
import 'package:moor/moor.dart';

import './database/database.dart';

@DataClassName('FileEntry')
class FileEntries extends Table {
  TextColumn get id => text()();
  TextColumn get driveId => text().customConstraint('REFERENCES drives(id)')();
  TextColumn get parentFolderId =>
      text().customConstraint('REFERENCES folderEntries(id)')();

  TextColumn get name => text().withLength(min: 1)();
  TextColumn get path => text()();

  TextColumn get dataTxId => text()();

  IntColumn get size => integer()();

  DateTimeColumn get dateCreated =>
      dateTime().clientDefault(() => DateTime.now())();
  DateTimeColumn get lastUpdated =>
      dateTime().clientDefault(() => DateTime.now())();
  DateTimeColumn get lastModifiedDate => dateTime()();

  @override
  Set<Column> get primaryKey => {id, driveId};
}

extension FileEntryExtensions on FileEntry {
  FileEntity asArFsEntity() => FileEntity(
        id: id,
        driveId: driveId,
        parentFolderId: parentFolderId,
        name: name,
        dataTxId: dataTxId,
        size: size,
        lastModifiedDate: lastModifiedDate,
      );
}
