import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:datetime_picker_formfield/datetime_picker_formfield.dart';
import 'SnackBarController.dart';
import 'Verification.dart';
import 'Tokens/TokenProcessor.dart';
import 'Requests.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import 'colors.dart' as colors;

class FormScreen extends StatefulWidget {
  final SharedPreferences prefs;
  FormScreen({Key key, @required this.prefs}) : super(key: key);
  @override
  State createState() => _FormScreen(prefs);
}

class _FormScreen extends State<FormScreen> {
 
  final SharedPreferences prefs;
  _FormScreen(this. prefs);  //constructor

  String _user = "";
  String _repName = "";
  String _course = "";
  String _amount = "";
  String _receipt = "";

  String accessToken = "";
  String refreshToken = "";

  //define type of date input needed, all of them are here now because I am unsure wether we need the time or not yet :)
  final formats = {
    InputType.both: DateFormat("EEEE, MMMM d, yyyy 'at' h:mma"),
    InputType.date: DateFormat('yyyy-MM-dd'),
    InputType.time: DateFormat("HH:mm"),
  };

  // let the user pick a date
  InputType inputType = InputType.date;
  DateTime _date;

  bool _radioValue = false;
  //default value for the radio button
  String _currentPaymentMethod = "cash"; 
  
  // controllers and variables for the inputs 
  final TextEditingController _userNameController = new TextEditingController();
  final TextEditingController _courseController = new TextEditingController();
  final TextEditingController _amountController = new TextEditingController();
  final TextEditingController _receiptController = new TextEditingController();
  final TextEditingController _dateController = new TextEditingController();
  final TextEditingController _repNameController = new TextEditingController();
  
  static final GlobalKey<ScaffoldState> _formKey = new GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadTokensAndRepName();
  }

  void _biometricAuth () async {
    var localAuth = LocalAuthentication();
    bool didAuthenticate = await localAuth.authenticateWithBiometrics(
        localizedReason: 'Please authenticate to Login', useErrorDialogs: false);
    if (!didAuthenticate) {
      _logout();
    }
  }

  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed){
      _biometricAuth();
    }
  }

  @override
  Widget build(BuildContext context) {
    return new WillPopScope(
      onWillPop: () => Future.value(false),
      child: Scaffold(
        key: _formKey,
        appBar: AppBar(
          title: Text('Transaction Details'),
          automaticallyImplyLeading: false,
          actions: <Widget>[
            PopupMenuButton<BarButtonOptions>(
              onSelected: _select,
              itemBuilder: (BuildContext context) {
                return options.map((BarButtonOptions options) {
                  return PopupMenuItem<BarButtonOptions>(
                    value: options,
                    child: Text(options.title),
                  );
                }).toList();
              },
            ),
          ],
        ),
        body: SafeArea(
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              children: <Widget>[
                SizedBox(height: 1.0),
                Column(
                  children: <Widget>[
                    SizedBox(height: 30.0),
                    TextField(
                      cursorColor: Colors.white,
                      decoration: InputDecoration(
                        labelText: "Rep Name",
                        filled: true,
                      ),
                      controller: _repNameController,
                    ),
                    SizedBox(height: 12.0),
                    TextField(
                      cursorColor: Colors.white,
                      decoration: InputDecoration(
                        labelText: "Customer Username",
                        filled: true,
                      ),
                      controller: _userNameController,
                    ),
                    SizedBox(height: 12.0),       
                    TextField(
                      cursorColor: Colors.white,
                      decoration: InputDecoration(
                        labelText: "Course",
                        filled: true,
                      ),
                      controller: _courseController,
                    ),
                    SizedBox(height: 12.0),
                    DateTimePickerFormField(
                      inputType: inputType,
                      format: formats[inputType],
                      editable: false,
                      controller: _dateController,
                      decoration: InputDecoration(
                        labelText: 'Date/Time', hasFloatingPlaceholder: false),
                        onChanged: (dt) => setState(() => _date = dt),
                    ),
                    SizedBox(height: 12.0),
                    Text("Payment Method: "),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        new Radio(
                          activeColor: colors.buttonColor,
                          value: false,
                          groupValue: _radioValue,
                          onChanged: _handleRadioChange,
                        ),
                        new Text(
                          'Cash',
                          style: new TextStyle(fontSize: 16.0),
                        ),
                        new Radio(
                          activeColor: colors.buttonColor,
                          value: true,
                          groupValue: _radioValue,
                          onChanged: _handleRadioChange,
                        ),
                        new Text(
                          'Cheque',
                          style: new TextStyle(
                            fontSize: 16.0,
                          ),
                        ),
                      ]
                    ),
                    SizedBox(height: 12.0),
                    TextField(
                      keyboardType: TextInputType.number,
                      cursorColor: Colors.white,
                      decoration: InputDecoration(
                        labelText: "Amount",
                        filled: true,
                        prefixText: '€',
                      ),
                      controller: _amountController,
                    ),
                    SizedBox(height: 12.0),
                    TextField(
                      keyboardType: TextInputType.number,
                      cursorColor: Colors.white,
                      decoration: InputDecoration(
                        labelText: "Receipt No",
                        filled: true,
                      ),
                      controller: _receiptController,
                    ),
                    ButtonBar(
                      children: <Widget>[
                        RaisedButton(
                          color: colors.buttonColor,
                          child: Text('SUBMIT', style: TextStyle(color: Colors.white)),
                          onPressed: () async {
                            _user =_userNameController.text.trim();
                            _repName =_repNameController.text.trim();
                            _course =_courseController.text.trim();
                            _amount =_amountController.text.trim();
                            _receipt =_receiptController.text.trim();
                            double _amountValue = Verification.checkForMoneyAmountInput(_amount);
                            String printErrorMessage = Verification.validateFormSubmission(_user, _repName, _course, _amount, _amountValue, _receipt, _date);
                            if (printErrorMessage != null) {
                              SnackBarController.showSnackBarErrorMessage(_formKey, printErrorMessage);
                              return;
                            }
                            handleSubmitForm(_user, _repName, _course, _amountValue, _receipt, _date, _currentPaymentMethod);
                          },
                        )
                      ],
                    )
                  ],
                ),
              ],
            )
        )
      )
    );
  }
  void _handleRadioChange(bool value) {
    setState(() {
      _radioValue = value;
      _currentPaymentMethod = (_radioValue ? "cheque" : "cash");
    });
  }

  void handleSubmitForm(String user, String repName, String course, double amount, String receipt, DateTime date, String paymentMethod) async {
    if ((accessToken = await TokenParser.checkTokens(accessToken, refreshToken, this.prefs)) == null) {
      // an error occured with the tokens, means the user no longer has valid tokens 
      // redirect to login page
      Navigator.pop(context);
      return;
    }

    int requestId = await Requests.postForm(accessToken, user, repName, course, amount, receipt, date, paymentMethod);
    if (requestId == 0) {
      SnackBarController.showSnackBarErrorMessage(_formKey, "An error occured. Please try again later.");
      return;
    } 
    
    // success, clear the fields & show message 
    _showDialog(requestId);
    _userNameController.clear();
    _repNameController.clear();
    _courseController.clear();
    _amountController.clear();
    _receiptController.clear();
    _dateController.clear();
    setState(() => _date = null);
  }

  void _select(BarButtonOptions options) {
    switch (options.title) {
      case "Log Out":
        _showLogOutDialog();
        break;
      case "Toggle Biometrics" :
        _toggleBiometrics();
        break;
      default:
        // shouldn't come here
    }
  }

  void _loadTokensAndRepName() async {
    _repName = await (this.prefs.get('username') ?? '');
    refreshToken = await (this.prefs.get('refresh') ?? '');
    accessToken = await (this.prefs.get('access' ?? ''));
    setState(() {
      _repNameController.text =_repName;
    });
  }

  void _logout() async {
    // delete tokens if they are valid
    if (TokenParser.validateToken(accessToken) && ! (await Requests.deleteToken(accessToken))) {
      // if we go here, the access token is valid but the call to delete it failed (probably a backend error)
      print("access token deletion failed");
    }

    if (TokenParser.validateToken(refreshToken) && !(await Requests.deleteToken(refreshToken))) {
      // if we go here, the refresh token is valid but the call to delete it failed (probably a backend error)
      print("refresh token deletion failed");
    }

    // remove them from local storage
    await this.prefs.remove('access');
    await this.prefs.remove('refresh');

    // pop form screen
    Navigator.of(context).pop();
  }

  void _showDialog(int id) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          title: new Text("Success"),
          content: new Text("The form has been sent successfully! id: $id"),
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

   void _showLogOutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          title: new Text("Do you want to log out ?"),
          actions: <Widget>[
            new FlatButton(
              child: new Text("Confirm"),
              onPressed: () {
                Navigator.of(context).pop();
                _logout();
              },
            ),
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

  void _toggleBiometrics() {
    String question = "";
    bool isOptionEnabled = prefs.getBool("isBiometricsEnabled");
    if ( ( isOptionEnabled == null) || (isOptionEnabled == false)) {
      question = "Turn on Biometrics?";
    } else if (isOptionEnabled == true) {
      question = "Turn off Biometrics?";
    }
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          title: new Text(question),
          actions: <Widget>[
            new FlatButton(
              child: new Text("Confirm"),
              onPressed: () {
                if (( isOptionEnabled == null) || (isOptionEnabled == false)) {
                  prefs.setBool("isBiometricsEnabled", true);
                } else if (isOptionEnabled == true) {
                  prefs.setBool("isBiometricsEnabled", false);
                }
                Navigator.of(context).pop();
              },
            ),
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

// class used to represent buttons
class BarButtonOptions {
  const BarButtonOptions({this.title, this.icon});

  final String title;
  final IconData icon;
}

// list of choices on the side menu, add a line here to add another option
 const List<BarButtonOptions> options = const <BarButtonOptions>[
   // we don't use the icons as of now
  const BarButtonOptions(title: 'Log Out', icon: null),
  const BarButtonOptions(title: 'Toggle Biometrics', icon: null),
];