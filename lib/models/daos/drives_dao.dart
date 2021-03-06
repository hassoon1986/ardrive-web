import 'package:ardrive/services/services.dart';
import 'package:arweave/arweave.dart';
import 'package:cryptography/cryptography.dart';
import 'package:moor/moor.dart';
import 'package:uuid/uuid.dart';

import '../../entities/entities.dart';
import '../database/database.dart';
import '../models.dart';

part 'drives_dao.g.dart';

@UseDao(tables: [Drives, FolderEntries, FileEntries])
class DrivesDao extends DatabaseAccessor<Database> with _$DrivesDaoMixin {
  final uuid = Uuid();

  DrivesDao(Database db) : super(db);

  Future<List<Drive>> getAllDrives() => select(drives).get();
  Stream<List<Drive>> watchAllDrives() =>
      (select(drives)..orderBy([(d) => OrderingTerm(expression: d.name)]))
          .watch();

  /// Creates a drive with its accompanying root folder.
  Future<CreateDriveResult> createDrive({
    @required String name,
    @required String ownerAddress,
    @required String privacy,
    Wallet wallet,
    String password,
    SecretKey profileKey,
  }) async {
    final driveId = uuid.v4();
    final rootFolderId = uuid.v4();

    var insertDriveOp = DrivesCompanion.insert(
      id: driveId,
      name: name,
      ownerAddress: ownerAddress,
      rootFolderId: rootFolderId,
      privacy: privacy,
    );

    SecretKey driveKey;
    if (privacy == DrivePrivacy.private) {
      driveKey = await deriveDriveKey(wallet, driveId, password);
      insertDriveOp = await _addDriveKeyToDriveCompanion(
          insertDriveOp, profileKey, driveKey);
    }

    await batch((batch) {
      batch.insert(drives, insertDriveOp);

      batch.insert(
        folderEntries,
        FolderEntriesCompanion.insert(
          id: rootFolderId,
          driveId: driveId,
          name: name,
          path: '',
        ),
      );
    });

    return CreateDriveResult(
      driveId,
      rootFolderId,
      driveKey,
    );
  }

  /// Adds or updates the user's drives with the provided drive entities.
  Future<void> updateUserDrives(
          Map<DriveEntity, SecretKey> driveEntities, SecretKey profileKey) =>
      db.batch((b) async {
        for (final entry in driveEntities.entries) {
          final entity = entry.key;

          var driveCompanion = DrivesCompanion.insert(
            id: entity.id,
            name: entity.name,
            ownerAddress: entity.ownerAddress,
            rootFolderId: entity.rootFolderId,
            privacy: entity.privacy,
            dateCreated: Value(entity.commitTime),
            lastUpdated: Value(entity.commitTime),
          );

          if (entity.privacy == DrivePrivacy.private) {
            driveCompanion = await _addDriveKeyToDriveCompanion(
                driveCompanion, profileKey, entry.value);
          }

          b.insert(
            drives,
            driveCompanion,
            onConflict:
                DoUpdate((_) => driveCompanion.copyWith(dateCreated: null)),
          );
        }
      });

  /// Inserts the provided [DriveEntity] with the provided name.
  ///
  /// Only works for public drives.
  Future<void> insertDriveEntity({
    String name,
    DriveEntity entity,
  }) {
    assert(entity.privacy == DrivePrivacy.public);

    return into(drives).insert(
      DrivesCompanion.insert(
        id: entity.id,
        name: name,
        ownerAddress: entity.ownerAddress,
        rootFolderId: entity.rootFolderId,
        privacy: entity.privacy,
        // TODO: Provide proper date created for attached drives.
        // It should be the timestamp for the first entry of this drive.
        dateCreated: Value(entity.commitTime),
        lastUpdated: Value(entity.commitTime),
      ),
    );
  }

  Future<DrivesCompanion> _addDriveKeyToDriveCompanion(
    DrivesCompanion drive,
    SecretKey profileKey,
    SecretKey driveKey,
  ) async {
    final iv = Nonce.randomBytes(96 ~/ 8);
    final encryptedWallet = await aesGcm.encrypt(
      await driveKey.extract(),
      secretKey: profileKey,
      nonce: iv,
    );

    return drive.copyWith(
      encryptedKey: Value(encryptedWallet),
      keyIv: Value(iv.bytes),
    );
  }
}

class CreateDriveResult {
  final String driveId;
  final String rootFolderId;
  final SecretKey driveKey;

  CreateDriveResult(this.driveId, this.rootFolderId, this.driveKey);
}
