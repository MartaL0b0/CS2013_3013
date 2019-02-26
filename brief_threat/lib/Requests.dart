import 'package:http/http.dart' as http;
import 'dart:convert';
import 'Tokens/models/RefreshToken.dart';
import 'Tokens/models/AccessToken.dart';

class Requests {
  static Future<RefreshToken> login(String _username, String _password) async {
    String credentialsAsJson =jsonEncode({"username": _username, "password": _password});

    final response = await http.post(
      'https://briefthreat.nul.ie//api/v1/auth/login', 
      headers: {"Content-Type": "application/json"},
      body: credentialsAsJson);
    if (response.statusCode == 200) {
      //parse the JSON to get the refresh key
      return RefreshToken.fromJson(jsonDecode(response.body));
    } 

    // authentification failed
    return null;
  }

  static Future<AccessToken> generateAccessToken(String refreshToken) async {
    final response = await http.post(
      'https://briefthreat.nul.ie//api/v1/auth/token', 
      headers: {"Authorization": "Bearer $refreshToken"});

    if (response.statusCode == 200) {
      // success, return access token from JSON
      return AccessToken.fromJson(jsonDecode(response.body));
    } 

    // request failed
    return null;
  }  

  static Future<int> postForm(String accessToken, String user, String repName, String course, double amount, String receipt, DateTime date, String paymentMethod) async {
    String dataAsJson =jsonEncode({
      "customer_name" : user,   
      "course" : course,
      "payment_method" : paymentMethod.toLowerCase(),
      "receipt" : receipt,
      "time" : (date.millisecondsSinceEpoch / 1000).round(),
      "amount" : amount
      });

    final response = await http.post(
      'https://briefthreat.nul.ie//api/v1/form', 
      headers: {"Authorization": "Bearer $accessToken", "Content-Type": "application/json"},
      body: dataAsJson);

    if (response.statusCode == 200) {
      // success, return id
      return jsonDecode(response.body)['id'];
    } 

    // request failed
    return 0;
  }  
}