import 'dart:convert';
import 'dart:io';

import 'package:file_chooser/file_chooser.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../blocs/blocs.dart';

class UnauthedPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RaisedButton(
                    onPressed: () => _promptToLogin(context),
                    child: Text('Login'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _promptToLogin(BuildContext context) async {
    final chooseResult = await showOpenPanel();
    if (!chooseResult.canceled) {
      final jwk = json.decode(
        await new File(chooseResult.paths[0]).readAsString(),
      );

      context.bloc<UserBloc>().add(AttemptLogin(jwk));
    }
  }
}