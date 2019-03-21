class Verification {
  static String checkForSpecialChars (String s) {
    return RegExp(r'[.,<>§£$°^!@#<>?":_`~;[\]\\|=+)(*&^%-]').hasMatch(s) ? null : s;
  }

  static double checkForMoneyAmountInput (String s) {
    // not ideal but does the job
    s = s.replaceAll(',', '.');
    try {
      return double.parse(s);
    } catch (e) {
      return null;
    }
  }

  static bool isStringAnEmail (String email) {
    return RegExp(r"^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(email);
  }

  static String checkForNumbersOnly (String s) {
    return RegExp('[^0-9]').hasMatch(s) ? null : s;
  }
  
  static bool hasSpecialChar(String s) {
    return RegExp(r'[.,<>§£$°^!@#<>?":_`~;[\]\\|=+)(*&^%-]').hasMatch(s);
  }

  // checks that a list of elements (strings) contain no empty strings
  static bool areAllFilled(List<String> s) {
    for(int i = 0; i < s.length; i++){
      if(s[i].isEmpty) {
        return true;
      }
    }
    return false;
  }

    // return the error message to display or null if all is well 
  static String validateFormSubmission (String user, String repName, String course, String amount, double amountVal, String receipt, DateTime date){
    // input data checks, woho
    if(areAllFilled([user, repName, course, amount, receipt]) || date == null){
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

    // return the error message to display or null if all is well 
  static String validateLoginSubmission(String _user, String _password) {
    if(areAllFilled([_user, _password])){
      return "Please fill in all fields";
    } 
    else if(hasSpecialChar(_user)) {
      return "Invalid username";
    }

    return null;
  }

  // return the error message to display or null if all is well 
  static String validateNewUserFields (String username, String firstName, String lastName, String email, String confirmEmail) {
    print(isStringAnEmail(email));
    print("printed");
    if (areAllFilled([username, firstName, lastName, email, confirmEmail])) {
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