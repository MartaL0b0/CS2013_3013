import 'package:flutter/material.dart';
import 'FormScreen.dart';
import 'SnackBarController.dart';
import 'Verification.dart';

void main() {
  runApp(MaterialApp(
    title: 'Form app',  // someone please suggest something :)
    home: LoginPage(),
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
                              ));
                        _loginPressed();

                        // TODO implement this when we have the login system setup
                        /*
                        if incorrect login
                        SnackBarController.showSnackBarErrorMessage(_scaffoldKey, "Incorrect username or password. Please try again");
                        return;
                        else : 
                        */

                        // wait before loading new page
                        // TODO remove when login is implemented with backend
                        await new Future.delayed(const Duration(seconds: 3));

                        // redirect to new page
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => FormScreen()),
                        );
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
  void _loginPressed () {
    print('The user wants to login with $_user and $_password');
  }
}
