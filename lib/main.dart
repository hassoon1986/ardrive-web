import 'package:ardrive/theme/theme.dart';
import 'package:arweave/arweave.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'app_shell.dart';
import 'blocs/blocs.dart';
import 'models/models.dart';
import 'services/services.dart';
import 'views/views.dart';

ArweaveService arweave;
Database db;

void main() async {
  arweave =
      ArweaveService(Arweave(gatewayUrl: Uri.parse('https://arweave.dev')));

  db = Database();

  runApp(App());
}

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<ProfileDao>(create: (_) => db.profileDao),
        RepositoryProvider<ArweaveService>(create: (_) => arweave),
        RepositoryProvider<DrivesDao>(create: (_) => db.drivesDao),
        RepositoryProvider<DriveDao>(create: (_) => db.driveDao),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => ProfileBloc(
              profileDao: context.repository<ProfileDao>(),
            ),
          ),
          BlocProvider(
            create: (context) => UploadBloc(
              profileBloc: context.bloc<ProfileBloc>(),
              arweave: context.repository<ArweaveService>(),
              driveDao: context.repository<DriveDao>(),
            ),
          ),
          BlocProvider(
            create: (context) => SyncBloc(
              profileBloc: context.bloc<ProfileBloc>(),
              arweave: context.repository<ArweaveService>(),
              drivesDao: context.repository<DrivesDao>(),
              driveDao: context.repository<DriveDao>(),
            ),
          ),
          BlocProvider(
            create: (context) => DrivesCubit(
              profileBloc: context.bloc<ProfileBloc>(),
              drivesDao: context.repository<DrivesDao>(),
            ),
          ),
        ],
        child: MaterialApp(
          title: 'ArDrive',
          theme: appTheme(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: BlocBuilder<ProfileBloc, ProfileState>(
            builder: (context, state) {
              if (state is ProfileUnavailable) {
                return ProfileAuthView();
              } else if (state is ProfileLoading) {
                return Container();
              } else if (state is ProfileLoaded) {
                return BlocBuilder<DrivesCubit, DrivesState>(
                  builder: (context, state) {
                    if (state is DrivesLoadSuccess) {
                      return BlocProvider(
                        key: ValueKey(state.selectedDriveId),
                        create: (context) => DriveDetailCubit(
                          driveId: state.selectedDriveId,
                          profileBloc: context.bloc<ProfileBloc>(),
                          uploadBloc: context.bloc<UploadBloc>(),
                          driveDao: context.repository<DriveDao>(),
                        ),
                        child: AppShell(
                          page: state.selectedDriveId != null
                              ? DriveDetailView()
                              : Container(),
                        ),
                      );
                    } else {
                      return Container();
                    }
                  },
                );
              } else {
                return Container();
              }
            },
          ),
        ),
      ),
    );
  }
}
