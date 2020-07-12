import 'package:drive/blocs/blocs.dart';
import 'package:drive/views/partials/create_new_drive_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DrivesBloc, DrivesState>(
      builder: (context, state) => Drawer(
        elevation: 1,
        child: Column(
          children: [
            if (state is DrivesReady)
              ...state.drives.map(
                (d) => ListTile(
                  leading: Icon(Icons.folder_shared),
                  title: Text(d.name),
                  selected: state.selectedDriveId == d.id,
                  onTap: () =>
                      context.bloc<DrivesBloc>().add(SelectDrive(d.id)),
                ),
              ),
            ListTile(
              leading: Icon(Icons.add),
              title: Text('Add drive'),
              onTap: () => promptToCreateNewDrive(context),
            ),
            Expanded(child: Container()),
            Divider(height: 0),
            ListTile(
              title: Text('John Applebee'),
              subtitle: Text('john@arweave.org'),
              trailing: Icon(Icons.arrow_drop_down),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}