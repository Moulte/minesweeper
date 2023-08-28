import 'package:flutter/material.dart';
import 'package:minesweeper/model.dart';

Future<bool?> displayDialog(BuildContext context, DialogNotif dialog) async {
  final callback = dialog.callback;
  return showDialog<bool>(
    context: context,
    barrierDismissible: false, // user must tap button!
    builder: (BuildContext context) {
      return AlertDialog(
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              Text(dialog.message),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: Text(dialog.validateAction),
            onPressed: () {
              if (callback != null) {
                callback(true);
              }
              Navigator.of(context).pop(true);
            },
          ),
          TextButton(
            child: Text(dialog.annulationAction),
            onPressed: () {
              if (callback != null) {
                callback(false);
              }
              Navigator.of(context).pop(false);
            },
          ),
        ],
      );
    },
  );
}
