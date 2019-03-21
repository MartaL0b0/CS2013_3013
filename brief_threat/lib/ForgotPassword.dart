import 'package:flutter/material.dart';
import 'Requests.dart';

class ForgotPassword extends StatefulWidget {
  @override
  State createState() => _ForgotPassword();
}

class _ForgotPassword extends State <ForgotPassword> {
// text input controllers & variables
  final TextEditingController _userNameController = new TextEditingController();
  String _user = "";
  static final GlobalKey<ScaffoldState> _second = new GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Reset your password"),
      ),
      key: _second,
        body: SafeArea(
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              children: <Widget>[
                SizedBox(height: 120.0),
                TextField(
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: "Username",
                    filled: true,
                  ),
                  controller: _userNameController,
                ),
                SizedBox(height: 12.0), //spacer
                ButtonBar(
                  children: <Widget>[
                    FlatButton(
                      child: Text('Reset'),
                      onPressed: () async {
                        _user =_userNameController.text;
                        _resetPassword();
                      },
                    )
                  ],
                )
              ],
            )
        )
    );
  }

  void _resetPassword () async {
    String status = await Requests.resetPassword(_user);
    if (status == null) {
      // return to login screen on success
      Navigator.pop(context);
    }
    status == null ? _showDialog("Success", "An email will be sent to you shortly.") : _showDialog("An error occured.", status);
  }

    void _showDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          title: new Text(title),
          content: new Text(message),
          actions: <Widget>[
            new FlatButton(
              child: new Text("Close"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}