import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

void main() {
  group('app integration tests', (){
    final loginButtonFinder = find.byValueKey('login');
    final loginFieldFinder = find.byValueKey('login field');
    final passwordFieldFinder = find.byValueKey('password field');

    final screenTitleFinder = find.byValueKey('title');
    FlutterDriver driver;

    // Connect to the Flutter driver before running any tests
    setUpAll(() async {
      driver = await FlutterDriver.connect();
    });

    // Close the connection to the driver after the tests have completed
    tearDownAll(() async {
      if (driver != null) {
        driver.close();
      }
    });

    test('login with username and password', () async {
      await driver.tap(loginFieldFinder);
      await driver.enterText("root");
      await driver.tap(passwordFieldFinder);
      await driver.enterText("ENTER PASSWORD HERE"); //TODO: make sure this password is correct when testing
      await driver.tap(loginButtonFinder);
      expect(await driver.getText(screenTitleFinder), "Transaction Details");
    });
  });
}
