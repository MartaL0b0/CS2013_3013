import 'package:flutter/material.dart';

class FormScreen extends StatefulWidget {
  @override
  State createState() => _FormScreen();
}

class _FormScreen extends State<FormScreen> {
  // TODO implement this screen 
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
                    Text('WELCOME :)',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 40),
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
                    TextField(
                      cursorColor: Colors.white,
                      decoration: InputDecoration(
                        labelText: "Date",
                        filled: true,
                      ),
                      //controller: _userNameController,
                    ),
                    SizedBox(height: 12.0),
                    TextField(
                      cursorColor: Colors.white,
                      decoration: InputDecoration(
                        labelText: "Payment",
                        filled: true,
                      ),
                      //controller: _userNameController,
                    ),
                    SizedBox(height: 12.0),
                    TextField(
                      cursorColor: Colors.white,
                      decoration: InputDecoration(
                        labelText: "Amount",
                        filled: true,
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
                            print("submit pressed");
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
}