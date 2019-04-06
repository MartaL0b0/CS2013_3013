/*
  This file handles all of the requests made to the backend
 */

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:brief_threat/Models/RefreshToken.dart';
import 'package:brief_threat/Models/AccessToken.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:brief_threat/Processors/TokenProcessor.dart';
import 'package:brief_threat/Models/request.dart';

class Requests {

  // logs in a user, returns both tokens on success, null on error
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

    // get forms as a list of 'Request' classes, returns null on error
  static Future<List<Request>> getForms(SharedPreferences prefs) async {
    //make sure access token is valid, generate a new one otherwise
    String accessToken = prefs.getString('access');
    accessToken = await TokenProcessor.checkTokens(accessToken, prefs.getString('refresh'), prefs);
    if (accessToken == null) return null;

    final response = await http.get(
      'https://briefthreat.nul.ie/api/v1/form', 
      headers: {"Authorization": "Bearer $accessToken"});

    if (response.statusCode == 200) {
      // decode response into list of requests
      var forms = (jsonDecode(response.body) as List).map((form) => new Request.fromJson(form)).toList();
      // reverse list in order to make the latest submissions appear first
      return forms.reversed.toList();
    } 
    // request failed
    return null;
  }

  // get all data from user, return json response
  static Future<Map<String, dynamic>> getUser(SharedPreferences prefs) async {
    //make sure access token is valid, generate a new one otherwise
    String accessToken = await updateAccessToken(prefs);
    if (accessToken == null) return null;

    final response = await http.get(
      'https://briefthreat.nul.ie/api/v1/auth/login', 
      headers: {"Authorization": "Bearer $accessToken"});

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } 
    // request failed
    return null;
  }

  // returns true if user is an admin
  static Future<bool> isUserAdmin(String accessToken) async {
    final response = await http.get(
      'https://briefthreat.nul.ie/api/v1/auth/login', 
      headers: {"Authorization": "Bearer $accessToken"});

    Map<String, dynamic> json = jsonDecode(response.body);
    if (json == null) {
      return false;
    }
    return json['is_admin'];
  }

  // gets a refresh token and returns an access token
  static Future<AccessToken> generateAccessToken(String refreshToken) async {
    final response = await http.post(
      'https://briefthreat.nul.ie/api/v1/auth/token', 
      headers: {"Authorization": "Bearer $refreshToken"});

    if (response.statusCode == 200) {
      // success, return access token from JSON
      return AccessToken.fromJson(jsonDecode(response.body));
    } 

    // request failed
    return null;
  }  

  // post a form, return id on success and -1 on error
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
      'https://briefthreat.nul.ie/api/v1/form', 
      headers: {"Authorization": "Bearer $accessToken", "Content-Type": "application/json"},
      body: dataAsJson);

    if (response.statusCode == 200) {
      // success, return id
      return jsonDecode(response.body)['id'];
    } 

    // request failed
    return -1;
  }

  // delete a token (log user out)
  static Future<bool> deleteToken(String token) async {
    final response = await http.delete(
      'https://briefthreat.nul.ie/api/v1/auth/token', 
      headers: {"Authorization": "Bearer $token"});

    if(response.statusCode == 204) {
      return true;
    }

    return false;
  }

  // updates an access token & store the new token in shared preferences
  static Future<String> updateAccessToken (SharedPreferences prefs) async {
    String accessToken = prefs.getString('access');
    accessToken = await TokenProcessor.checkTokens(accessToken, prefs.getString('refresh'), prefs);
    return accessToken;
  }

  // only used by admins, can send a request to approve a request
  static Future<bool> approveRequest(int id, SharedPreferences prefs) async {
    // make sure access token is valid
    String accessToken = await updateAccessToken(prefs);
    if (accessToken == null) return null;

    String data = jsonEncode({"id" : id});
    final response = await http.put(
      'https://briefthreat.nul.ie//api/v1/form/resolve', 
      headers: {"Authorization": "Bearer $accessToken", "Content-Type": "application/json"},
      body: data);

    if (response.statusCode == 200) {
      return true;
    } 
    // request failed
    return false;
  }

  // register new user, returns boolean string reflecting success / failure
  static Future<String> register(String username, String email, bool isAdmin, String firstName, String lastName, String accessToken) async {
    String dataAsJson =jsonEncode({"username": username, "email": email, "is_admin":isAdmin, "first_name":firstName, "last_name":lastName});

    final response = await http.post(
      'https://briefthreat.nul.ie/api/v1/auth/register', 
      headers: {"Authorization": "Bearer $accessToken", "Content-Type": "application/json"},
      body: dataAsJson);

    // return null on succes, return the error message on failure
    return response.statusCode == 204 ? null : jsonDecode(response.body)['message'];
  }  

  // send request to the backend to reset a user's password
  static Future<String> resetPassword (String username) async {
    String data = jsonEncode({"username": username});

    final response = await http.patch(
      'https://briefthreat.nul.ie//api/v1/auth/login', 
      headers: {"Content-Type": "application/json"},
      body: data);

    // return null on success and error message on error
    return response.statusCode == 204 ? null : jsonDecode(response.body)['message'];
  }
}