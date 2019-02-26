import 'package:flutter/material.dart';
import 'FormScreen.dart';
import 'SnackBarController.dart';
import 'Tokens/models/RefreshToken.dart';
import 'Verification.dart';
import 'Requests.dart';
import 'dart:async';
import 'RequestAccess.dart';
import 'globals.dart' as globals;

void main() {
  runApp(MaterialApp(
      title: 'Form app',
      home: LoginPage(),
      routes: <String, WidgetBuilder> {
        '/Login': (BuildContext context) => new LoginPage(),
        '/Form' : (BuildContext context) => new FormScreen(),
        '/RequestAccess' : (BuildContext context) => new RequestAccess(),
      },
    ));
}

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // text input controllers & variables
  final TextEditingController _userNameController = new TextEditingController();
  final TextEditingController _passwordController = new TextEditingController();
  String _user = "";
  String _password = "";
  var hidePassword = true;

  @override
  Widget build(BuildContext context) {
    final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
    return Scaffold(
      key: _scaffoldKey,
        body: SafeArea(
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              children: <Widget>[
                SizedBox(height: 80.0),
                Column(
                  children: <Widget>[
                    SizedBox(height: 40.0),
                    Text('Welcome !',
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
                TextField(
                  decoration: InputDecoration(
                    labelText: "Password",
                    filled: true,
                  ),
                  controller: _passwordController,
                  obscureText: hidePassword,
                ),
                ButtonBar(
                children: <Widget>[
                    FlatButton(
                      child: Text('Show'),
                      onPressed: () {
                        //handle show/hide password
                        _toggleShowPassword();
                      },
                    )
                  ],
                ),
                ButtonBar(
                  children: <Widget>[
                    FlatButton(
                      child: Text('Login'),
                      onPressed: () async {
                        // trim user name but not password
                        _user = _userNameController.text.trim();
                        _password = _passwordController.text;

                        String error = Verification.validateLoginSubmission(_user, _password);
                        if (error != null) {
                          SnackBarController.showSnackBarErrorMessage(_scaffoldKey, error);
                          return;
                        }

                        // show loading snack bar, close any previous snackbar before showing new one
                         _scaffoldKey.currentState.hideCurrentSnackBar();
                        _scaffoldKey.currentState.showSnackBar(
                            new SnackBar(
                              content: new Row(
                              children: <Widget>[
                                new CircularProgressIndicator(),
                                new Text("  Signing-In...")
                              ],
                            ),
                          )
                        );
                        bool status = await _loginPressed(_user, _password, _scaffoldKey);
                        
                        // don't redirect if login failed
                        if(!status) {
                          return;
                        }

                        _userNameController.clear();
                        _passwordController.clear();

                        // redirect to new page
                        Navigator.pop(context);
                      },
                    )
                  ],
                ),
                SizedBox(height: 90.0), //spacer
                ButtonBar(
                  children: <Widget>[
                    FlatButton(
                      child: Text('Request Access'),
                      onPressed: () async {
                        // redirect to new page
                        Navigator.pushNamed(context, '/RequestAccess');
                      },
                    )
                  ],
                )
              ],
            )
        )
    );
  }

  // Toggles the password show status
  void _toggleShowPassword() {
    setState(() {
      hidePassword = !hidePassword;
    });
  }

  // handle login, currently just prints what was entered in the text fields
  Future<bool> _loginPressed (String user, String password, GlobalKey<ScaffoldState> key) async {
    print('The user wants to login with $_user and $_password');
    RefreshToken token = await Requests.login(_user, _password);
    if (token == null) {
      // show error message
      SnackBarController.showSnackBarErrorMessage(key, "Incorrect username or password. Please try again");
      return false;
    } 
    globals.access_token = token.accessToken.accessToken;
    globals.refresh_token = token.refreshToken;
    globals.username = user;
    // successful login 
    print(globals.username);
    key.currentState.hideCurrentSnackBar();
    return true;
  }
}