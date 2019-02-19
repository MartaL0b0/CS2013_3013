String checkForSpecialChars (String s) {
  return RegExp(r'[.,<>§£$°^!@#<>?":_`~;[\]\\|=+)(*&^%-]').hasMatch(s) ? null : s;
}

double checkForMoneyAmountInput (String s) {
  // not ideal but does the job
  s = s.replaceAll(',', '.');
  try {
    return double.parse(s);
  } catch (e) {
    return null;
  }
}

String checkForNumbersOnly (String s) {
  return RegExp('[^0-9]').hasMatch(s) ? null : s;
}