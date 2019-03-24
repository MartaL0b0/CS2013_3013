class AccessToken {
  final String accessToken;

  AccessToken({this.accessToken});

  factory AccessToken.fromJson(Map<String, dynamic> json) {
    return AccessToken(
      accessToken: json['access_token'],
    );
  }
}

