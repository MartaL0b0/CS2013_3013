import 'package:corsac_jwt/corsac_jwt.dart';

class TokenParser {
  static void validateToken (String token) {
    var decodedToken = new JWT.parse(token);
    int val = decodedToken.expiresAt * 1000;
    int now = DateTime.now().toUtc().millisecondsSinceEpoch;
    print("hehehehe");
  }
}