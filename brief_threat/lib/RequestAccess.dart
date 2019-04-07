import 'package:flutter/material.dart';
import 'Theme/colors.dart' as colors;

class RequestAccess extends StatefulWidget {
  @override
  State createState() => _RequestAccess();
}

class _RequestAccess extends State <RequestAccess> {
// text input controllers & variables
  final TextEditingController _userNameController = new TextEditingController();
  String _user = "";
  static final GlobalKey<ScaffoldState> _second = new GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _second,
        body: SafeArea(
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              children: <Widget>[
                SizedBox(height: 80.0),
                Column(
                  children: <Widget>[
                    SizedBox(height: 40.0),
                    Text('Request Access:',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 40),
                    ),
                  ],
                ),
                SizedBox(height: 120.0),
                TextField(
                  cursorColor: Colors.white,
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
                      color: colors.buttonColor,
                      child: Text('Submit', style : TextStyle(color: Colors.white)),
                      onPressed: () async {
                        _user =_userNameController.text;
                        print("sent request to access : $_user");
                      },
                    )
                  ],
                )
              ],
            )
        )
    );
  }
}