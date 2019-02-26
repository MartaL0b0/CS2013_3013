import 'package:corsac_jwt/corsac_jwt.dart';
import 'package:brief_threat/globals.dart' as globals;
import 'package:brief_threat/Requests.dart';
import 'models/AccessToken.dart';

class TokenParser {
  // for now just checks for the time
  static bool validateToken (String token) {
    if (token.isEmpty) return false;
    var decodedToken = new JWT.parse(token);
    
    // need to multiply as dart will only generate time in ms as opposed to seconds
    int val = decodedToken.expiresAt * 1000;
    int now = DateTime.now().toUtc().millisecondsSinceEpoch;
    return val > now;
  }

  static Future<bool> checkTokens() async {
    if (!validateToken(globals.access_token) && !validateToken(globals.refresh_token)) {
      // go to login
      return false;
    }
    else if(!validateToken(globals.access_token)) {
      // generate new one
      AccessToken token = await Requests.generateAccessToken(globals.access_token);
      if (token == null) {
        // an error occured, do something
        return false;
      }
      globals.access_token = token.accessToken;
    }
    return true;
  }
}