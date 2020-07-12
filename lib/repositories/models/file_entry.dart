import 'package:moor/moor.dart';

@DataClassName('FileEntry')
class FileEntries extends Table {
  TextColumn get id => text()();
  TextColumn get driveId => text().customConstraint('REFERENCES drives(id)')();
  TextColumn get parentFolderId =>
      text().customConstraint('REFERENCES folderEntries(id)')();

  TextColumn get name => text().withLength(min: 1)();
  TextColumn get path => text().withLength(min: 1)();

  IntColumn get size => integer()();

  BoolColumn get uploaded => boolean()();

  DateTimeColumn get dateCreated => dateTime().nullable()();
  DateTimeColumn get dateUpdated => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}