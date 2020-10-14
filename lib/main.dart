import 'package:ardrive/theme/theme.dart';
import 'package:arweave/arweave.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'blocs/blocs.dart';
import 'models/models.dart';
import 'services/services.dart';

ArweaveService arweave;
Database db;

void main() async {
  arweave =
      ArweaveService(Arweave(gatewayUrl: Uri.parse('https://arweave.dev')));

  db = Database();

  runApp(App());
}

class App extends StatelessWidget {
  final _routerDelegate = AppRouterDelegate();
  final _routeInformationParser = AppRouteInformationParser();

  @override
  Widget build(BuildContext context) => MultiRepositoryProvider(
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
          child: MaterialApp.router(
            title: 'ArDrive',
            theme: appTheme(),
            routerDelegate: _routerDelegate,
            routeInformationParser: _routeInformationParser,
          ),
        ),
      );
}
