import 'package:corsac_jwt/corsac_jwt.dart';

class TokenParser {
  static bool validateToken (String token) {
    if (token.isEmpty) return false;
    var decodedToken = new JWT.parse(token);
    int val = decodedToken.expiresAt * 1000;
    int now = DateTime.now().toUtc().millisecondsSinceEpoch;
    return val > now;
  }
}