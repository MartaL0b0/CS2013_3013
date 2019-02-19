import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:datetime_picker_formfield/datetime_picker_formfield.dart';

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
  DateTime date;

  //payment types :
  List<DropdownMenuItem<String>> _dropDownMenuItems;
  String _currentPaymentMethod; 

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
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SafeArea(
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              children: <Widget>[
                SizedBox(height: 80.0),
                Column(
                  children: <Widget>[
                    Text('Customer Details:',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
                    ),
                    SizedBox(height: 30.0),
                    TextField(
                      cursorColor: Colors.white,
                      decoration: InputDecoration(
                        labelText: "Username",
                        filled: true,
                      ),
                      //controller: _userNameController,
                    ),
                    SizedBox(height: 12.0),
                    TextField(
                      cursorColor: Colors.white,
                      decoration: InputDecoration(
                        labelText: "Rep Name",
                        filled: true,
                      ),
                      //controller: _userNameController,
                    ),
                    SizedBox(height: 12.0),       
                    TextField(
                      cursorColor: Colors.white,
                      decoration: InputDecoration(
                        labelText: "Course",
                        filled: true,
                      ),
                      //controller: _userNameController,
                    ),
                    SizedBox(height: 12.0),
                    DateTimePickerFormField(
                      inputType: inputType,
                      format: formats[inputType],
                      editable: false,
                      decoration: InputDecoration(
                        labelText: 'Date/Time', hasFloatingPlaceholder: false),
                        onChanged: (dt) => setState(() => date = dt),
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
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      cursorColor: Colors.white,
                      inputFormatters: [
                        
                      ],
                      decoration: InputDecoration(
                        labelText: "Amount",
                        filled: true,
                        prefixText: '€',
                      ),
                      //controller: _userNameController,
                    ),
                    SizedBox(height: 12.0),
                    TextField(
                      cursorColor: Colors.white,
                      decoration: InputDecoration(
                        labelText: "Receipt No",
                        filled: true,
                      ),
                      //controller: _userNameController,
                    ),
                    ButtonBar(
                      children: <Widget>[
                        FlatButton(
                          child: Text('SUBMIT'),
                          onPressed: () {
                            print("submit pressed date input is : $date");
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