import 'dart:async';

import 'package:ardrive/blocs/blocs.dart';
import 'package:ardrive/models/models.dart';
import 'package:ardrive/services/services.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:pedantic/pedantic.dart';

part 'fs_entry_move_state.dart';

class FsEntryMoveCubit extends Cubit<FsEntryMoveState> {
  final String driveId;
  final String folderId;
  final String fileId;

  final ArweaveService _arweave;
  final DriveDao _driveDao;
  final ProfileBloc _profileBloc;

  StreamSubscription _folderSubscription;

  bool get _isMovingFolder => folderId != null;

  FsEntryMoveCubit({
    @required this.driveId,
    this.folderId,
    this.fileId,
    @required ArweaveService arweave,
    @required DriveDao driveDao,
    @required ProfileBloc profileBloc,
  })  : _arweave = arweave,
        _driveDao = driveDao,
        _profileBloc = profileBloc,
        assert(folderId != null || fileId != null),
        super(
            FsEntryMoveFolderLoadInProgress(isMovingFolder: folderId != null)) {
    _driveDao.getDriveById(driveId).then((d) => loadFolder(d.rootFolderId));
  }

  Future<void> loadParentFolder() {
    final state = this.state as FsEntryMoveFolderLoadSuccess;
    return loadFolder(state.viewingFolder.folder.parentFolderId);
  }

  Future<void> loadFolder(String folderId) async {
    unawaited(_folderSubscription?.cancel());

    _folderSubscription =
        _driveDao.watchFolderContentsById(driveId, folderId).listen((f) => emit(
              FsEntryMoveFolderLoadSuccess(
                viewingRootFolder: f.folder.parentFolderId == null,
                viewingFolder: f,
                isMovingFolder: _isMovingFolder,
              ),
            ));
  }

  Future<void> submit() async {
    final state = this.state as FsEntryMoveFolderLoadSuccess;
    final profile = _profileBloc.state as ProfileLoaded;

    final parentFolder = state.viewingFolder.folder;
    final driveKey = await _driveDao.getDriveKey(driveId, profile.cipherKey);

    if (_isMovingFolder) {
      emit(FolderEntryMoveInProgress());

      await _driveDao.transaction(() async {
        var folder = await _driveDao.getFolderById(driveId, folderId);
        folder = folder.copyWith(
            parentFolderId: parentFolder.id,
            path: '${parentFolder.path}/${folder.name}',
            lastUpdated: DateTime.now());

        final folderTx = await _arweave.prepareEntityTx(
            folder.asArFsEntity(), profile.wallet, driveKey);

        await _arweave.postTx(folderTx);
        await _driveDao.writeToFolder(folder);
      });

      emit(FolderEntryMoveSuccess());
    } else {
      emit(FileEntryMoveInProgress());

      await _driveDao.transaction(() async {
        var file = await _driveDao.getFileById(driveId, fileId);
        file = file.copyWith(
            parentFolderId: parentFolder.id,
            path: '${parentFolder.path}/${file.name}',
            lastUpdated: DateTime.now());

        final fileTx = await _arweave.prepareEntityTx(
            file.asArFsEntity(), profile.wallet, driveKey);

        await _arweave.postTx(fileTx);
        await _driveDao.writeToFile(file);
      });

      emit(FileEntryMoveSuccess());
    }
  }

  @override
  Future<void> close() {
    _folderSubscription?.cancel();
    return super.close();
  }
}
