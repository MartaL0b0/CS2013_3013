// model class for an access token
class AccessToken {
  final String accessToken;

  AccessToken({this.accessToken});

  // get an access token class instance from json
  factory AccessToken.fromJson(Map<String, dynamic> json) {
    return AccessToken(
      accessToken: json['access_token'],
    );
  }
}

