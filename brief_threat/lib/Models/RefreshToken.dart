// model class for a refresh token
import 'package:brief_threat/Models/AccessToken.dart';

class RefreshToken {
  // we only get a refresh token when logging in, the backend also generates access token when generating refresh token
  final String refreshToken;
  final AccessToken accessToken;

  RefreshToken({this.refreshToken, this.accessToken});

  // get a refresh token instance from json
  factory RefreshToken.fromJson(Map<String, dynamic> json) {
    AccessToken access =AccessToken.fromJson(json);
    return RefreshToken(
      refreshToken: json['refresh_token'],
      accessToken: access
    );
  }
}
