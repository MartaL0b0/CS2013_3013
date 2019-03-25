import 'package:flutter/material.dart';
import 'package:brief_threat/Controllers/SnackBarController.dart';
import 'package:brief_threat/Processors/InputProcessor.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:brief_threat/Processors/HttpRequestsProcessor.dart';
import 'package:brief_threat/Processors/TokenProcessor.dart';

class Register extends StatefulWidget {
  final SharedPreferences prefs;
  Register({Key key, @required this.prefs}) : super(key: key);

  @override
  State createState() => _Register(this.prefs);
}

class _Register extends State <Register> {
  final SharedPreferences prefs;
  _Register(this.prefs);  //constructor
  String accessToken;
  String refreshToken;

  @override
  void initState() {
    super.initState();
    accessToken = prefs.getString('access');
    refreshToken = prefs.getString('refresh');
  }

  // text input controllers & variables
  final TextEditingController _userNameController = new TextEditingController();
  final TextEditingController _firstNameController = new TextEditingController();
  final TextEditingController _lastNameController = new TextEditingController();
  final TextEditingController _emailController = new TextEditingController();
  final TextEditingController _emailConfirmationController = new TextEditingController();
  bool isAdmin = false;
  String _user = "";
  String _firstName = "";
  String _lastName = "";
  String _email = "";
  String _emailConfirmed = "";

  static final GlobalKey<ScaffoldState> _registerScaffold = new GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop:() async {
        setVariablesFromControllers();
        if (!Verification.isAnyFilled([_user, _firstName, _lastName, _email, _emailConfirmed])){
          return true;
        } else {
          return showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text("Cancel registration?"),
                actions: <Widget>[
                  FlatButton(
                    child: Text("Yes"),
                    onPressed: () async {
                      Navigator.pop(context, true);
                    },
                  ),
                  FlatButton(
                    child: Text("Cancel"),
                    onPressed: () => Navigator.pop(context, false),
                  )
                ],
              )
          );
        }
      },
      child: Scaffold(
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
                  SizedBox(height: 20.0), //spacer
                  Text("Is user an admin:"),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        new Radio(
                          value: false,
                          groupValue: isAdmin,
                          onChanged: _handleAdminChange,
                        ),
                        new Text(
                          'No',
                          style: new TextStyle(fontSize: 16.0),
                        ),
                        new Radio(
                          value: true,
                          groupValue: isAdmin,
                          onChanged: _handleAdminChange,
                        ),
                        new Text(
                          'Yes',
                          style: new TextStyle(
                            fontSize: 16.0,
                          ),
                        ),
                      ]
                    ),
                SizedBox(height: 12.0), //spacer
                ButtonBar(
                  children: <Widget>[
                    FlatButton(
                      child: Text('Create user'),
                      onPressed: () async {
                        setVariablesFromControllers();
                        String printErrorMessage = Verification.validateNewUserFields(_user, _firstName, _lastName, _email, _emailConfirmed);
                        if (printErrorMessage != null) {
                          SnackBarController.showSnackBarErrorMessage(_registerScaffold, printErrorMessage);
                          return;
                        }
                        _createNewUser();
                      },
                    )
                  ],
                )
              ],
            )
          ]),
        ),
      )
    );
  }

  void _createNewUser () async {
    accessToken = await TokenProcessor.checkTokens(accessToken, refreshToken, prefs);
    if (accessToken == null) {
      // no longer logged in, pop both screens back to login screen & remove prefs
      await this.prefs.remove('access');
      await this.prefs.remove('refresh');
      await this.prefs.remove('is_admin');
      SnackBarController.showSnackBarErrorMessage(_registerScaffold, "You are no longer logged in.");
      Navigator.pop(context);
      Navigator.pop(context);
      return;
    }
    String status = await Requests.register(_user, _email, isAdmin, _firstName, _lastName, accessToken);
    _showMessageDialog(status == null ? "Registration for user $_user was successful!" : "An error occured.", status == null ? '' : status);

    if (status == null) {
      // if registration was a success, clear fields
      setState(() {
       _firstNameController.clear();
       _lastNameController.clear();
       _emailController.clear();
       _emailConfirmationController.clear();
       _userNameController.clear();
       isAdmin = false; 
      });
    }
  }

  void _showMessageDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          title: new Text(title),
          content: Text(message),
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
  void _handleAdminChange(bool value) {
    setState(() {
      isAdmin = value;
    });
  }

  void setVariablesFromControllers () {
    _user =_userNameController.text.trim();
    _firstName =_firstNameController.text.trim();
    _lastName =_lastNameController.text.trim();
    _email =_emailController.text.trim();
    _emailConfirmed =_emailConfirmationController.text.trim();
  }
}