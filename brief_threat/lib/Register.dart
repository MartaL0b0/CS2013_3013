import 'package:flutter/material.dart';
import 'SnackBarController.dart';
import 'Verification.dart';

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
                  decoration: InputDecoration(
                  labelText: "First Name",
                  filled: true,
                  ),
                  controller: _firstNameController,
                ),
                SizedBox(height: 15.0),
                TextField(
                  decoration: InputDecoration(
                  labelText: "Last Name",
                  filled: true,
                  ),
                  controller: _lastNameController,
                ),
                SizedBox(height: 15.0),
                TextField(
                  decoration: InputDecoration(
                  labelText: "Username",
                  filled: true,
                  ),
                  controller: _userNameController,
                ),
                SizedBox(height: 15.0),
                TextField(
                  decoration: InputDecoration(
                  labelText: "email",
                  filled: true,
                  ),
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                ),
                SizedBox(height: 15.0),
                TextField(
                  decoration: InputDecoration(
                  labelText: "Confirm email address",
                  filled: true,
                  ),
                  controller: _emailConfirmationController,
                  keyboardType: TextInputType.emailAddress,
                ),
              SizedBox(height: 12.0), //spacer
              ButtonBar(
                children: <Widget>[
                  FlatButton(
                    child: Text('Create user'),
                    onPressed: () async {
                      _user =_userNameController.text.trim();
                      _firstName =_firstNameController.text.trim();
                      _lastName =_lastNameController.text.trim();
                      _email =_emailController.text.trim();
                      _emailConfirmed =_emailConfirmationController.text.trim();

                      String printErrorMessage = Verification.validateNewUserFields(_user, _firstName, _lastName, _email, _emailConfirmed);
                      if (printErrorMessage != null) {
                        SnackBarController.showSnackBarErrorMessage(_registerScaffold, printErrorMessage);
                        return;
                      }

                      print("creating user with details : $_user, $_firstName, $_lastName, $_email, $_emailConfirmed");
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