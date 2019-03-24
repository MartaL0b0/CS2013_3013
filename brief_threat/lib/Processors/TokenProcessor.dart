import 'package:corsac_jwt/corsac_jwt.dart';
import 'package:brief_threat/Processors/HttpRequestsProcessor.dart';
import 'package:brief_threat/Models/AccessToken.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TokenProcessor {
  // returns true if token is valid
  static bool validateToken (String token) {
    if (token.isEmpty) return false;
    var decodedToken = new JWT.parse(token);
    
    // need to multiply as dart will only generate time in ms as opposed to seconds (which is what our backend returns)
    int val = decodedToken.expiresAt * 1000;
    int now = DateTime.now().toUtc().millisecondsSinceEpoch;
    return val > now;
  }

  // returns a valid access token (null when refresh token expired)
  static Future<String> checkTokens(String access, String refresh, SharedPreferences prefs) async {
    AccessToken token;
    if (!validateToken(access) && !validateToken(refresh)) {
      // both token not valid
      return null;
    }
    else if(!validateToken(access)) {
      // generate new one
      token = await Requests.generateAccessToken(refresh);
      await prefs.setString('access', token.accessToken);

      if (token == null) {
        // an error occured when making a call to regenerate an access token, how should we handle this ?
        // currently the user is sent back to login
        return null;
      }
    }
    return token == null ? access : token.accessToken;
  }
}