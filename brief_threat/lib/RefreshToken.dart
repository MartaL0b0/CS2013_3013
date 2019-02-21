class RefreshToken {
  final String refreshToken;

  RefreshToken({this.refreshToken});

  factory RefreshToken.fromJson(Map<String, dynamic> json) {
    return RefreshToken(
      refreshToken: json['refresh_token'],
    );
  }
}
