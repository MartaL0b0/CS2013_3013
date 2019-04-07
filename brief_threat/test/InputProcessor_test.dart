import 'package:flutter_test/flutter_test.dart';
import 'package:brief_threat/Processors/InputProcessor.dart';

void main(){
  group('checkForSpecialChars', (){
    test('expect null, "The weak ones die, Big deal."', (){
      expect(Verification.checkForSpecialChars("The weak ones die, Big deal."), null);
    });
    test('expect String, "Your drill is the drill that will pierce the Heavens"', (){
      expect(Verification.checkForSpecialChars("Your drill is the drill that will pierce the Heavens"),
        "Your drill is the drill that will pierce the Heavens" );
    });
  });

  group('checkForMoneyAmountInput', (){
    test('expect double, 9001,00', (){
      expect(Verification.checkForMoneyAmountInput("9001,00"), 9001);
    });
    test('expect double, 9001.00', (){
      expect(Verification.checkForMoneyAmountInput("9001.00"), 9001);
    });
    test('expect null, 9001.000', (){
      expect(Verification.checkForMoneyAmountInput("9001.000"), null);
    });
    test('expect null, "nico nico n11"', (){
      expect(Verification.checkForMoneyAmountInput("nico nico n11"), null);
    });
  });

  group('isStringAnEmail', (){
    test('expect true, test@iru.ie', (){
      expect(Verification.isStringAnEmail("test@iru.ie"), true);
    });
    test('expect false, ei.uri@tset', (){
      expect(Verification.isStringAnEmail("ei.uri@tset"), false);
    });
    test('expect false, "A knight must never run away, no matter how mighty the enemy"', (){
      expect(Verification.isStringAnEmail(
          "A knight must never run away, no matter how mighty the enemy."), false);
    });
  });

  group('checkForNumbersOnly', (){
    test('expect String, 1337', (){
      expect(Verification.checkForNumbersOnly("1337"), "1337");
    });
    test('expect null, Chunchunmaru', (){
      expect(Verification.checkForNumbersOnly("Chunchunmaru"), null);
    });
  });

  group('hasSpecialChar', (){
    test('expect true, "Im not a criminal. Woah, that makes me sound more like a criminal, doesnt it."', (){
      expect(Verification.hasSpecialChar(
          "Im not a criminal. Woah, that makes me sound more like a criminal, doesnt it."), true);
    });
    test('expect false, "If you know the way to live you know the way to die"', (){
      expect(Verification.hasSpecialChar(
          "If you know the way to live you know the way to die"), false);
    });
  });

  group('isAnyNotFilled', (){
    test('expect false, (list of non-empty strings)', (){
      String s1 = "F:Hey there, having a little trouble?\nS:Huh?";
      String s2 = "F:I can bail you out for 80%.\nS:You're insane!";
      String s3 = "F:Okay! Bye-bye now!\nS:All right 40% that's my last offer!\nF:Okay, I get the 60!";
      expect(Verification.isAnyNotFilled([s1, s2, s3]), false);
    });
    test('expect true, (list of 1 full string, 1 empty)', (){
      String s1 = "Whatever happens, happens.";
      String s2 = "";
      expect(Verification.isAnyNotFilled([s1, s2]), true);
    });
  });

  group('isAnyFilled', (){
    test('expect false, (list of empty strings)', (){
      String s1 = "";
      String s2 = "";
      expect(Verification.isAnyFilled([s1, s2]), false);
    });
    test('expect true, (list of 1 full string, 1 empty)', (){
      String s1 = "Whatever happens, happens.";
      String s2 = "";
      expect(Verification.isAnyFilled([s1, s2]), true);
    });
  });
}