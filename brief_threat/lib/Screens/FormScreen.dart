import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:datetime_picker_formfield/datetime_picker_formfield.dart';
import 'package:brief_threat/Controllers/SnackBarController.dart';
import 'package:brief_threat/Processors/InputProcessor.dart';
import 'package:brief_threat/Processors/TokenProcessor.dart';
import 'package:brief_threat/Processors/HttpRequestsProcessor.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:brief_threat/Screens/RegisterScreen.dart';
import 'package:brief_threat/Models/request.dart';
import 'package:page_indicator/page_indicator.dart';
import 'dart:async';
import 'package:brief_threat/Theme/colors.dart' as colors;
import 'package:local_auth/local_auth.dart';

class FormScreen extends StatefulWidget {
  final SharedPreferences prefs;
  final bool isAdmin;

  FormScreen({Key key, @required this.prefs, this.isAdmin}) : super(key: key);
  @override
  State createState() => _FormScreen(prefs, isAdmin);
}

class _FormScreen extends State<FormScreen> with WidgetsBindingObserver {
 // list of choices on the side menu, add a line here to add another option
 final List<barButtonOptions> options = <barButtonOptions>[
   // we don't use the icons as of now
  const barButtonOptions(title: 'Log Out', icon: null),
  const barButtonOptions(title: 'Toggle Biometrics', icon: null),

  ];
  final SharedPreferences prefs;
  final bool isAdmin;
  _FormScreen(this.prefs, this.isAdmin);  //constructor
  Widget submittedForms;
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

  PageController pageControll = new PageController(
    initialPage: 0,
    keepPage: true,
  );
  
  static final GlobalKey<ScaffoldState> _formKey = new GlobalKey<ScaffoldState>();
  static final GlobalKey<ScaffoldState> _formsListKey = new GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadTokensAndRepName();
    if (this.isAdmin) {
      options.add(const barButtonOptions(title: 'Add new user', icon: null));
    }
    submittedForms = _buildFormScreen();
    WidgetsBinding.instance.addObserver(this);
  }

   @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && prefs.getBool("isBiometricsEnabled")) {
      _biometricAuth();
    }
  }

  Widget _buildFormScreen() {
    return new FutureBuilder(
      future: Requests.getForms(prefs),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if(snapshot.data == null) {
            // no data to display 
            return new Scaffold(
              body: Center(
                child: Text('There is nothing to display right now.'),
              ),
              floatingActionButton: FloatingActionButton(
                child: Icon(Icons.cached),
                onPressed: setFormScreen,
              ),
              floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
            );
          }
            return new RefreshIndicator(
              child: ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemBuilder: (context, index) => _buildFormItem(snapshot.data[index], index),
                itemCount: snapshot.data.length,
              ),
              onRefresh: _handleRefresh,
            );
        } else {
          return Center(
            child: CircularProgressIndicator()
          );
        }
      }
    );
  }
  Widget _buildFormItem(Request request, int index) {
    var formatter = new DateFormat('dd-MM-yy');
    String dateSubmitted =formatter.format(request.submittedTime);
    String status =request.resolvedAt == null ? "Waiting for approval" : "Resolved on ${formatter.format(request.resolvedAt)}";
    return new ListTile(
      contentPadding: EdgeInsets.all(8.0),
      leading: request.resolvedAt == null ? Icon(Icons.radio_button_unchecked) : Icon(Icons.radio_button_checked),
      title: Text('Customer: ${request.customerName} - Submitted by ${request.submitter}'),
      subtitle: new Text('Submitted on: $dateSubmitted\nPaid in ${request.paymentMethod}\nReceipt No: ${request.receipt}\nCourse: ${request.course}\n$status',
        style: TextStyle(fontSize: 12.0),
      ),
      trailing: 
        new Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            new Text('${request.amount}€'),
          ],
        ),
      enabled: (prefs.getBool('is_admin') ?? false) && request.resolvedAt == null,
      onTap: () => showValidateDialog(request.id),
    );
  }

  void updateAccessToken () async {
    accessToken = await TokenProcessor.checkTokens(accessToken, refreshToken, this.prefs);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () => Future.value(false),
      child: PageIndicatorContainer(
        pageView: PageView(
        controller: pageControll,
        children: <Widget>[
          form(context),
          submissions(context)
          ],
        ),
        align: IndicatorAlign.bottom,
        length: 2,
        padding: EdgeInsets.only(bottom: 10, left: 15),
        indicatorSpace: 10.0, // space between circles
        indicatorColor: Colors.grey,
        indicatorSelectorColor: Colors.blue[200],
        size: 15.0, // indicator size.
      )
    );
  }

  
  Widget form(BuildContext context) {
    return Scaffold(
      key: _formKey,
      appBar: AppBar(
        title: Text('Transaction Details'),
        automaticallyImplyLeading: false,
        actions: <Widget>[
          PopupMenuButton<barButtonOptions>(
            onSelected: _select,
            itemBuilder: (BuildContext context) {
              return options.map((barButtonOptions options) {
                return PopupMenuItem<barButtonOptions>(
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
                    decoration: InputDecoration(
                      labelText: "Rep Name",
                      filled: true,
                    ),
                    controller: _repNameController,
                  ),
                  SizedBox(height: 12.0),
                  TextField(
                    decoration: InputDecoration(
                      labelText: "Customer Username",
                      filled: true,
                    ),
                    controller: _userNameController,
                  ),
                  SizedBox(height: 12.0),       
                  TextField(
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
                        value: false,
                        groupValue: _radioValue,
                        onChanged: _handleRadioChange,
                        activeColor: colors.buttonColor,
                      ),
                      new Text(
                        'Cash',
                        style: new TextStyle(fontSize: 16.0),
                      ),
                      new Radio(
                        value: true,
                        groupValue: _radioValue,
                        onChanged: _handleRadioChange,
                        activeColor: colors.buttonColor,
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
    );
  }

  Widget submissions(BuildContext context) {
    return Scaffold(
      key: _formsListKey,
      appBar: AppBar(
        title: Text('Past Submissions'),
        automaticallyImplyLeading: false,
        actions: <Widget>[
          PopupMenuButton<barButtonOptions>(
            onSelected: _select,
            itemBuilder: (BuildContext context) {
              return options.map((barButtonOptions options) {
                return PopupMenuItem<barButtonOptions>(
                  value: options,
                  child: Text(options.title),
                );
              }).toList();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: submittedForms,
      ),
    );
  }



  void _handleRadioChange(bool value) {
    setState(() {
      _radioValue = value;
      _currentPaymentMethod = (_radioValue ? "cheque" : "cash");
    });
  }

  void handleSubmitForm(String user, String repName, String course, double amount, String receipt, DateTime date, String paymentMethod) async {
    if ((accessToken = await TokenProcessor.checkTokens(accessToken, refreshToken, this.prefs)) == null) {
      // an error occured with the tokens, means the user no longer has valid tokens 
      // redirect to login page
      Navigator.pop(context);
      return;
    }

    int requestId = await Requests.postForm(accessToken, user, repName, course, amount, receipt, date, paymentMethod);
    if (requestId == -1) {
      SnackBarController.showSnackBarErrorMessage(_formKey, "An error occured. Please try again later.");
      return;
    } 
    
    // success, clear the fields & show message 
    _showDialog(requestId);
    _userNameController.clear();
    _courseController.clear();
    _amountController.clear();
    _receiptController.clear();
    _dateController.clear();
    setState(() => _date = null);
  }

  void _select(barButtonOptions options) {
    switch (options.title) {
      case "Log Out":
        _showLogOutDialog();
        break;
      case "Add new user":
        Navigator.push(context, new MaterialPageRoute(builder: (context) => new Register(prefs:prefs)));
        break;
      case "Refresh forms":
        setFormScreen();
        break;
      case "Toggle Biometrics" :
        _toggleBiometrics();
        break;
      default:
        // shoudln't come here
    }
  }

  void setFormScreen() {
    setState(() {
      submittedForms = _buildFormScreen();
    });
  }

   Future<void> _handleRefresh() async {
    List<Request> forms = await Requests.getForms(prefs);
    if (forms == null || forms.isEmpty) {
      setState(() {
        submittedForms = Scaffold(
          body: Center(
            child: FlatButton(
              child: Text('There is nothing to display right now. Click to refresh'),
              onPressed: _handleRefresh,
            ),
          )
        );
      });
    } else {
      setState(() {
        submittedForms = new RefreshIndicator(
          child: ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemBuilder: (context, index) => _buildFormItem(forms[index], index),
          itemCount: forms.length,
            ),
            onRefresh: _handleRefresh,
        );
      });
    }

    return null;
  }

  void _loadTokensAndRepName() async {
    _repName = (this.prefs.getString('username') ?? '');
    refreshToken = (this.prefs.getString('refresh') ?? '');
    accessToken = (this.prefs.getString('access' ?? ''));
    setState(() {
      _repNameController.text =_repName;
    });
  }

  void _logout() async {
    // delete tokens if they are valid
    if (TokenProcessor.validateToken(accessToken) && ! (await Requests.deleteToken(accessToken))) {
      // if we go here, the access token is valid but the call to delete it failed (probably a backend error)
      print("access token deletion failed");
    }

    if (TokenProcessor.validateToken(refreshToken) && !(await Requests.deleteToken(refreshToken))) {
      // if we go here, the refresh token is valid but the call to delete it failed (probably a backend error)
      print("refresh token deletion failed");
    }

    // remove them from local storage
    await this.prefs.remove('access');
    await this.prefs.remove('refresh');
    await this.prefs.remove('is_admin');

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

    void showValidateDialog(int id) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          title: new Text("Do you want to validate this request?"),
          actions: <Widget>[
            new FlatButton(
              child: new Text("Validate"),
              onPressed: () { 
                Navigator.of(context).pop();
                handleApproveRequest(id);
              },
            ),
            new FlatButton(
              child: new Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void handleApproveRequest (int id) async {
    bool status = await Requests.approveRequest(id, prefs);
    SnackBarController.showSnackBarErrorMessage(_formsListKey, status ? "Successfully approved request #$id" : "An error occurred.");
    setFormScreen();
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

    void _biometricAuth () async {
    var localAuth = LocalAuthentication();
    bool didAuthenticate = await localAuth.authenticateWithBiometrics(
        localizedReason: 'Please authenticate to Login', useErrorDialogs: false);
    if (!didAuthenticate) {
      _logout();
    }
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
class barButtonOptions {
  const barButtonOptions({this.title, this.icon});

  final String title;
  final IconData icon;
}