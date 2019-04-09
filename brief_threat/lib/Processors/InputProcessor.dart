class Verification {
  // returns null if the string contains a special char, otherwise the original string is returned
  static String checkForSpecialChars (String s) {
    return RegExp(r'[.,<>§£$°^!@#<>?":`~;[\]\\|=+)(*&^%]').hasMatch(s) ? null : s;
  }

  // checks if the amount entered is a valid double
  static double checkForMoneyAmountInput (String s) {
    // not ideal but does the job
    s = s.replaceAll(',', '.');
    var string = s.split(".");

    // string has more than 1 dot or has more than 2 digits after the dot
    if (string.length > 2 || (string.length == 2 && string[1].length > 2)) {
      return null;
    }
    // if can't parse the value to a double, then it's not a valid amount
    try {
      return double.parse(s);
    } catch (e) {
      return null;
    }
  }

  // returns true if string is an email
  static bool isStringAnEmail (String email) {
    return RegExp(r"^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(email);
  }

  // checks if a string is only composed of numbers
  static String checkForNumbersOnly (String s) {
    return RegExp('[^0-9]').hasMatch(s) ? null : s;
  }

  // returns true if the strings has a special character
  static bool hasSpecialChar(String s) {
    return RegExp(r'[.,<>§£$°^!@#<>?":_`~;[\]\\|=+)(*&^%-]').hasMatch(s);
  }

  // checks that a list of elements (strings) contains empty strings
  static bool isAnyNotFilled(List<String> s) {
    for(int i = 0; i < s.length; i++){
      if(s[i].isEmpty) {
        return true;
      }
    }
    return false;
  }

  // returns true if any string in a list of string is not empty
  static bool isAnyFilled(List<String> s) {
    for(int i = 0; i < s.length; i++){
      if(s[i].isNotEmpty) {
        return true;
      }
    }
    return false;
  }

  //check the inputs of a form submission, return the error message to display or null if all is well
  static String validateFormSubmission (String user, String repName, String course, String amount, double amountVal, String receipt, DateTime date){
    // input data checks, woho
    if(isAnyNotFilled([user, repName, course, amount, receipt]) || date == null){
      return "Please fill in all fields";
    } else if (checkForSpecialChars(user) == null) {
      return "Invalid username.";
    } else if (checkForSpecialChars(repName) == null) {
      return "Invalid representative name.";
    } else if (checkForSpecialChars(course) == null) {
      return "Invalid course name.";
    } else if(amountVal == null) {
      return "Invalid amount.";
    } else if(checkForNumbersOnly(receipt) == null) {
      return "Invalid receipt Number.";
    }
    return null;
  }

    // check the inputs of the login page, return the error message to display or null if all is well
  static String validateLoginSubmission(String _user, String _password) {
    if(isAnyNotFilled([_user, _password])){
      return "Please fill in all fields";
    } 
    else if(hasSpecialChar(_user)) {
      return "Invalid username";
    }

    return null;
  }

  // check the input fields of a new user form submission, return the error message to display or null if all is well
  static String validateNewUserFields (String username, String firstName, String lastName, String email, String confirmEmail) {
    print(isStringAnEmail(email));
    print("printed");
    if (isAnyNotFilled([username, firstName, lastName, email, confirmEmail])) {
      return "Please fill in all fields";
    } else if (checkForSpecialChars(username) == null) {
      return "Invalid username.";
    } else if (checkForSpecialChars(firstName) == null) {
      return "Invalid first name.";
    } else if (checkForSpecialChars(lastName) == null) {
      return "Invalid last name.";
    } else if (!isStringAnEmail(email)) {
      return "Invalid email address.";
    } else if (email !=confirmEmail) {
      return "Email addresses do not match.";
    }

    return null;
  }
}