import 'package:http/http.dart' as http;
import 'dart:convert';
import 'Tokens/models/RefreshToken.dart';
import 'Tokens/models/AccessToken.dart';

class Requests {
  static Future<RefreshToken> login(String _username, String _password) async {
    final response = await http.post(
      'https://briefthreat.nul.ie//api/v1/auth/login', 
      headers: {"Content-Type": "application/json"},
      body: {'username' : '$_username', 'password' : '$_password'});

    if (response.statusCode == 200) {
      //parse the JSON to get the refresh key
      return RefreshToken.fromJson(jsonDecode(response.body));
    } 
    else {
      // authentification failed
      return null;
    }
  }

  static Future<AccessToken> generateAccessToken(String refreshToken) async {
    final response = await http.post(
      'https://briefthreat.nul.ie//api/v1/auth/token', 
      headers: {"Authorization": "Bearer $refreshToken"});

    if (response.statusCode == 200) {
      // success, return access token from JSON
      return AccessToken.fromJson(jsonDecode(response.body));
    } 
    else {
      return null;
    }
  }  
}