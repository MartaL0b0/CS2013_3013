import 'package:flutter/material.dart';
import 'FormScreen.dart';
import 'SnackBarController.dart';
import 'Tokens/models/RefreshToken.dart';
import 'Verification.dart';
import 'Requests.dart';
import 'dart:async';
import 'ForgotPassword.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import 'Tokens/TokenProcessor.dart';
import 'colors.dart' as colors;

void main() {
  runApp(MaterialApp(
      title: 'Form app',
      home: LoginPage(),
      routes: <String, WidgetBuilder> {
        '/login': (BuildContext context) => new LoginPage(),
      },
      theme : buildTheme()
    ));
}

ThemeData buildTheme() {
  final ThemeData base = ThemeData.light();
  return base.copyWith(
    primaryColor: colors.primaryColor,
    accentColor: colors.accentColor,
    buttonColor: colors.primaryColor,
    backgroundColor: colors.primaryColor
  );
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
  IconData showOrHideIcon = Icons.visibility_off;
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
                Column(
                  children: <Widget>[
                    Image.asset(
                      'assets/flat_logo.png',
                    ),
                  ],
                ),
                TextField(
                  decoration: InputDecoration(
                    labelText: "Username",
                    filled: true,
                  ),
                  controller: _userNameController,
                ),
                SizedBox(height: 12.0), //spacer
                Stack(
                    alignment: const Alignment(1.0, 1.0),
                    children: <Widget>[
                      TextField(decoration: InputDecoration(
                        labelText: "Password",
                        filled: true,
                      ),
                        controller: _passwordController,
                        obscureText: hidePassword,),
                      Positioned(
                        right: 10,
                        top: 5,
                        child: IconButton(
                          onPressed: () {
                            _toggleShowPassword();
                          },
                          icon: new Icon(showOrHideIcon)
                        )
                      )
                    ]
                ),
                SizedBox(height: 12.0), //spacer
                ButtonBar(
                  children: <Widget>[
                    FlatButton(
                      child: Text('Request Access'),
                      onPressed: () async {
                        // redirect to new page
                        Navigator.pushNamed(context, '/RequestAccess');
                      },
                    ),
                    RaisedButton(
                      color: colors.buttonColor,
                      child: Text('Login', style: TextStyle(color: Colors.white),),
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
              ],
            )
        )
    );
  }

  Future<bool>_biometricAuth() async {
    var localAuth = LocalAuthentication();
    return await localAuth.authenticateWithBiometrics(
        localizedReason: 'Please authenticate to Login', useErrorDialogs: false);
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
      if (!prefs.getBool("isBiometricsEnabled") || (prefs.getBool("isBiometricsEnabled") && await _biometricAuth()) ) {
        Navigator.push(context, new MaterialPageRoute(
            builder: (context) => new FormScreen(prefs: prefs)));
      }
      return;
    }
  }
  // Toggles the password show status
  void _toggleShowPassword() async {
    setState(() {
      hidePassword = !hidePassword;
      if (hidePassword) {
        showOrHideIcon = Icons.visibility_off;
      } else {
        showOrHideIcon = Icons.visibility;
      }
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