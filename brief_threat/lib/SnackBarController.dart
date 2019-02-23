import 'package:flutter/material.dart';
class SnackBarController {
  static void showSnackBarErrorMessage (GlobalKey<ScaffoldState> _scaffoldKey, String message) {
    _scaffoldKey.currentState.hideCurrentSnackBar();
    _scaffoldKey.currentState.showSnackBar(
        new SnackBar(
          duration: Duration(seconds: 3),
          content: new Row(
            children: <Widget>[
              new Text(message)
            ],
          ),
        ));
  }
}
