import 'package:flutter/material.dart';
import 'FormScreen.dart';
import 'SnackBarController.dart';
import 'Tokens/models/RefreshToken.dart';
import 'Verification.dart';
import 'Requests.dart';
import 'dart:async';
import 'RequestAccess.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Tokens/TokenProcessor.dart';
import 'Register.dart';

void main() {
  runApp(MaterialApp(
      title: 'Form app',
      home: LoginPage(),
      routes: <String, WidgetBuilder> {
        '/Login': (BuildContext context) => new LoginPage(),
        '/RequestAccess' : (BuildContext context) => new RequestAccess(),
        '/register' : (BuildContext context) => new Register(),
      },
    ));
}

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // text input controllers & variables
  final TextEditingController _userNameController = new TextEditingController(text: "root");
  final TextEditingController _passwordController = new TextEditingController(text: "tinder4cats2k19");
  String _user = "";
  String _password = "";
  var hidePassword = true;
  SharedPreferences prefs;


  @override
  void initState() {
    super.initState();
    _getPreferences();
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  @override
  Widget build(BuildContext context) {
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

                        _passwordController.clear();

                        // redirect to new page
                        Navigator.push(context, new MaterialPageRoute(builder: (context) => new FormScreen(prefs:prefs)));
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

  void _getPreferences() async {
    prefs = await SharedPreferences.getInstance();
    if ((_user = await prefs.get('username') ?? '') != '') {
      setState(() {
        _userNameController.text =_user;
      });
    }
    if (TokenParser.validateToken((await prefs.getString('refresh') ??  ''))){
      // already logged in
      Navigator.push(context, new MaterialPageRoute(builder: (context) => new FormScreen(prefs:prefs)));
      return;
    }
  }
  // Toggles the password show status
  void _toggleShowPassword() async {
    setState(() {
      hidePassword = !hidePassword;
    });
  }

  // handle login, currently just prints what was entered in the text fields
  Future<bool> _loginPressed (String user, String password, GlobalKey<ScaffoldState> key) async {
    RefreshToken token = await Requests.login(_user, _password);
    if (token == null) {
      // show error message
      SnackBarController.showSnackBarErrorMessage(key, "Incorrect username or password. Please try again");
      return false;
    } 

    await prefs.setString('username', user);
    await prefs.setString('refresh', token.refreshToken);
    await prefs.setString('access', token.accessToken.accessToken);

    // successful login 
    key.currentState.hideCurrentSnackBar();
    return true;
  }
}