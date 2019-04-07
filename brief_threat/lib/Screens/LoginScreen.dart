import 'package:flutter/material.dart';
import 'package:brief_threat/Screens/FormScreen.dart';
import 'package:brief_threat/Controllers/SnackBarController.dart';
import 'package:brief_threat/Models/RefreshToken.dart';
import 'package:brief_threat/Processors/InputProcessor.dart';
import 'package:brief_threat/Processors/HttpRequestsProcessor.dart';
import 'dart:async';
import 'package:brief_threat/Screens/ForgotPasswordScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:brief_threat/Processors/TokenProcessor.dart';
import 'package:local_auth/local_auth.dart';
import 'package:brief_threat/Theme/colors.dart' as colors;

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreen createState() => _LoginScreen();
}

class _LoginScreen extends State<LoginScreen> {
  // text input controllers & variables
  final TextEditingController _userNameController = new TextEditingController();
  final TextEditingController _passwordController = new TextEditingController();
  String _user = "";
  String _password = "";
  var hidePassword = true;
  IconData showOrHideIcon = Icons.visibility_off;
  SharedPreferences prefs;
  bool isAdmin;

  // initialise : check if user already has a valid token & prefill the username field
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
                  key: Key('login field'),
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
                      TextField(
                        key: Key('password field'),
                        decoration: InputDecoration(
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
                      child: Text('Forgot your password?'),
                      onPressed: () async {
                        _user =_userNameController.text;
                        // redirect to new page
                        Navigator.push(context, new MaterialPageRoute(builder: (context) => new ForgotPassword(originalUsername:_user)));
                      },
                    ),
                    RaisedButton(
                      key: Key('login'),
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
                        Navigator.push(context, new MaterialPageRoute(builder: (context) => new FormScreen(prefs:prefs, isAdmin: isAdmin,)));
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

  // autofill username if it is present in local storage
  void _getPreferences() async {
    prefs = await SharedPreferences.getInstance();
    if ((_user = prefs.getString('username') ?? '') != '') {
      setState(() {
        _userNameController.text =_user;
      });
    }
    isAdmin = prefs.getBool('is_admin') ?? false;

    // if refresh token is valid, the user is already logged in
    if (TokenProcessor.validateToken((prefs.getString('refresh') ??  ''))){
      // already logged in
      if (!(prefs.getBool("isBiometricsEnabled") ?? false) || ((prefs.getBool("isBiometricsEnabled") ?? false) && await _biometricAuth()) ) {
        Navigator.push(context, new MaterialPageRoute(
            builder: (context) => new FormScreen(prefs: prefs, isAdmin: isAdmin)));
        return;
      }
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

  // handle login
  Future<bool> _loginPressed (String user, String password, GlobalKey<ScaffoldState> key) async {
    RefreshToken token = await Requests.login(_user, _password);
    if (token == null) {
      // show error message
      SnackBarController.showSnackBarErrorMessage(key, "Incorrect username or password. Please try again");
      return false;
    }
    // keep tokens and username in local storage
    await prefs.setString('username', user);
    await prefs.setString('refresh', token.refreshToken);
    await prefs.setString('access', token.accessToken.accessToken);

    // get admin status from backend, the access token was just generated so it will be valid (no need to update)
    isAdmin = await Requests.isUserAdmin(token.accessToken.accessToken);
    await prefs.setBool('is_admin', isAdmin);

    // successful login 
    key.currentState.hideCurrentSnackBar();
    return true;
  }
}