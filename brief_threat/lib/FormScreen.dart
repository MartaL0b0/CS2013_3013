import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:datetime_picker_formfield/datetime_picker_formfield.dart';
import 'SnackBarController.dart';
import 'TextVerification.dart';

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
  InputType inputType = InputType.both;
  DateTime _date;

  //payment types :
  List<DropdownMenuItem<String>> _dropDownMenuItems;
  String _currentPaymentMethod; 

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
  
  @override
  void initState() {
    _dropDownMenuItems = [
      new DropdownMenuItem(
        value: "Cash",
        child: new Text("Cash")
      ),
      new DropdownMenuItem(
        value: "Cheque",
        child: new Text("Cheque")
      )
    ];
    _currentPaymentMethod = _dropDownMenuItems[0].value;
    super.initState();
  }
  static final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('Customer Details'),
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
                  new DropdownButton(
                    value: _currentPaymentMethod,
                    items: _dropDownMenuItems,
                    onChanged: changedDropDownItem,
                    hint: Text("Payment Method"),
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
                          _user =_userNameController.text;
                          _repName =_repNameController.text;
                          _course =_courseController.text;
                          _amount =_amountController.text;
                          _receipt =_receiptController.text;
                          double _amountValue;

                          // input data checks, woho
                          if (_user.isEmpty || _repName.isEmpty || _course.isEmpty || _amount.isEmpty || _receipt.isEmpty || _date == null) {
                            showSnackBarErrorMessage(_scaffoldKey, "Please fill in all fields");
                            return;
                          } else if (checkForSpecialChars(_user) == null) {
                            showSnackBarErrorMessage(_scaffoldKey, "Invalid username.");
                            return;
                          } else if (checkForSpecialChars(_repName) == null) {
                            showSnackBarErrorMessage(_scaffoldKey, "Invalid representative name.");
                            return;
                          } else if (checkForSpecialChars(_course) == null) {
                            showSnackBarErrorMessage(_scaffoldKey, "Invalid course name.");
                            return;
                          } else if((_amountValue = checkForMoneyAmountInput(_amount)) == null) {
                            showSnackBarErrorMessage(_scaffoldKey, "Invalid amount.");
                            return;
                          } else if(checkForNumbersOnly(_receipt) == null) {
                            showSnackBarErrorMessage(_scaffoldKey, "Invalid receipt Number.");
                            return;
                          }

                          print("date : $_date, username : $_user, rep name : $_repName, course : $_course, method : $_currentPaymentMethod, amount : $_amount, receipt no : $_receipt");
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
  void changedDropDownItem(String paymentMethod) {
    setState(() {
      _currentPaymentMethod = paymentMethod;
    });
  }
}