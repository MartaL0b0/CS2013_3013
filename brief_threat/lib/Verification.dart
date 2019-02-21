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

  static String checkForNumbersOnly (String s) {
    return RegExp('[^0-9]').hasMatch(s) ? null : s;
  }
  static bool hasSpecialChar(String s) {
    return RegExp(r'[.,<>§£$°^!@#<>?":_`~;[\]\\|=+)(*&^%-]').hasMatch(s);
  }

  static bool areAllEmpty(List s) {
    return s.every((elem) => elem.isEmpty);
  }

  static String validateFormSubmission (String user, String repName, String course, String amount, double amountVal, String receipt, DateTime date){
    // input data checks, woho
    if(areAllEmpty([user, repName, course, amount, receipt]) || date == null){
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

  static String validateLoginSubmission(String _user, String _password) {
    if(areAllEmpty([_user, _password])){
      return "Please fill in all fields";
    } 
    else if(hasSpecialChar(_user)) {
      return "Invalid username";
    }

    return null;
  }
}