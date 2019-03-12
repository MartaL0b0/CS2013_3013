import 'package:flutter/material.dart';

class Register extends StatefulWidget {
  @override
  State createState() => _Register();
}

class _Register extends State <Register> {
// text input controllers & variables
  final TextEditingController _userNameController = new TextEditingController();
  final TextEditingController _firstNameController = new TextEditingController();
  final TextEditingController _lastNameController = new TextEditingController();
  final TextEditingController _emailController = new TextEditingController();
  final TextEditingController _emailConfirmationController = new TextEditingController();

  String _user = "";
  String _firstName = "";
  String _lastName = "";
  String _email = "";
  String _emailConfirmed = "";

  static final GlobalKey<ScaffoldState> _registerScaffold = new GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _registerScaffold,
      appBar: AppBar(
          title: Text('Create a new user'),
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.symmetric(horizontal: 24.0),
          children: <Widget>[
            Column(
              children: <Widget>[
                SizedBox(height: 25.0),
                TextField(
                  cursorColor: Colors.white,
                  decoration: InputDecoration(
                  labelText: "First Name",
                  filled: true,
                  ),
                  controller: _firstNameController,
                ),
                SizedBox(height: 15.0),
                TextField(
                  cursorColor: Colors.white,
                  decoration: InputDecoration(
                  labelText: "Last Name",
                  filled: true,
                  ),
                  controller: _lastNameController,
                ),
                SizedBox(height: 15.0),
                TextField(
                  cursorColor: Colors.white,
                  decoration: InputDecoration(
                  labelText: "Username",
                  filled: true,
                  ),
                  controller: _userNameController,
                ),
                SizedBox(height: 15.0),
                TextField(
                  cursorColor: Colors.white,
                  decoration: InputDecoration(
                  labelText: "email",
                  filled: true,
                  ),
                  controller: _emailController,
                ),
                SizedBox(height: 15.0),
                TextField(
                  cursorColor: Colors.white,
                  decoration: InputDecoration(
                  labelText: "Confirm email address",
                  filled: true,
                  ),
                  controller: _emailConfirmationController,
                ),
              SizedBox(height: 12.0), //spacer
              ButtonBar(
                children: <Widget>[
                  FlatButton(
                    child: Text('Create user'),
                    onPressed: () async {
                    _user =_userNameController.text;
                    print("sent request to access : $_user");
                    },
                  )
                ],
              )
            ],
          )
        ]),
      ),
    );
  }
}