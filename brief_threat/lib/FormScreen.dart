import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:datetime_picker_formfield/datetime_picker_formfield.dart';
import 'SnackBarController.dart';
import 'Verification.dart';

class FormScreen extends StatefulWidget {
  @override
  State createState() => _FormScreen();
}

class _FormScreen extends State<FormScreen> {
  //define type of date input needed, all of them are here now because I am unsure wether we need the time or not yet :)
  final formats = {
    InputType.both: DateFormat("EEEE, MMMM d, yyyy 'at' h:mma"),
    InputType.date: DateFormat('yyyy-MM-dd'),
    InputType.time: DateFormat("HH:mm"),
  };

  // let the user pick a date and time (for now)
  InputType inputType = InputType.date;
  DateTime _date;

  int _radioValue = 0;
  //default value for the radio button
  String _currentPaymentMethod = "CASH"; 

  // controllers and variables for the inputs 
  final TextEditingController _userNameController = new TextEditingController();
  final TextEditingController _repNameController = new TextEditingController();
  final TextEditingController _courseController = new TextEditingController();
  final TextEditingController _amountController = new TextEditingController();
  final TextEditingController _receiptController = new TextEditingController();

  String _user = "";
  String _repName = "";
  String _course = "";
  String _amount = "";
  String _receipt = "";

  static final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('Transaction Details'),
          automaticallyImplyLeading: false
      ),
      body: SafeArea(
          child: ListView(
            padding: EdgeInsets.symmetric(horizontal: 24.0),
            children: <Widget>[
              SizedBox(height: 12.0),
              Column(
                children: <Widget>[
                  SizedBox(height: 30.0),
                  TextField(
                    cursorColor: Colors.white,
                    decoration: InputDecoration(
                      labelText: "Username",
                      filled: true,
                    ),
                    controller: _userNameController,
                  ),
                  SizedBox(height: 12.0),
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
                        value: 0,
                        groupValue: _radioValue,
                        onChanged: _handleRadioChange,
                      ),
                      new Text(
                        'Cash',
                        style: new TextStyle(fontSize: 16.0),
                      ),
                      new Radio(
                        value: 1,
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
                      FlatButton(
                        child: Text('SUBMIT'),
                        onPressed: () async {
                          _user =_userNameController.text.trim();
                          _repName =_repNameController.text.trim();
                          _course =_courseController.text.trim();
                          _amount =_amountController.text.trim();
                          _receipt =_receiptController.text.trim();
                          double _amountValue = Verification.checkForMoneyAmountInput(_amount);

                          String printErrorMessage = Verification.validateFormSubmission(_user, _repName, _course, _amount, _amountValue, _receipt, _date);
                          if (printErrorMessage != null) {
                            SnackBarController.showSnackBarErrorMessage(_scaffoldKey, printErrorMessage);
                            return;
                          }
                          if (_receipt.isEmpty) {
                            print("receipt is empty");
                          }
                          print("date : $_date, username : $_user, rep name : $_repName, course : $_course, method : $_currentPaymentMethod, amount : $_amountValue, receipt no : $_receipt");
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

  void _handleRadioChange(int value) {
    setState(() {
      _radioValue = value;
  
      switch (_radioValue) {
        case 0:
          _currentPaymentMethod = "CASH";
          break;
        case 1:
          _currentPaymentMethod = "CHEQUE";
          break;
      }
    });
  }
}