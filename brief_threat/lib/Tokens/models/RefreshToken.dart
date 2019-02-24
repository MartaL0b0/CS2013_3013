import 'AccessToken.dart';

class RefreshToken {
  // backend also generates access token when generating refresh token
  final String refreshToken;
  final AccessToken accessToken;

  RefreshToken({this.refreshToken, this.accessToken});

  factory RefreshToken.fromJson(Map<String, dynamic> json) {
    AccessToken access =AccessToken.fromJson(json);
    return RefreshToken(
      refreshToken: json['refresh_token'],
      accessToken: access
    );
  }
}
