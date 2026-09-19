import 'dart:convert';
import 'dart:io';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';

/// Cross-platform API client for the Task Manager backend.
///
/// - Defaults to Android emulator loopback (10.0.2.2); override with
///   `--dart-define=API_BASE_URL=https://your.cloud.run/api`.
class ApiClient {
  ApiClient({String? baseUrl, http.Client? httpClient})
      : baseUrl = baseUrl ??
            const String.fromEnvironment(
              'API_BASE_URL',
              defaultValue: 'http://10.0.2.2:8080/api',
            ),
        _http = httpClient ?? http.Client();

  final String baseUrl;
  final http.Client _http;

  static const _authKey = 'auth.data';
  AuthData? _auth;

  bool get isAuthenticated => _auth != null && _auth!.token.isNotEmpty;

  Future<AuthData?> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_authKey);
    _auth = raw == null ? null : AuthData.fromStorage(raw);
    return _auth;
  }

  Future<AuthData> login(String email, String password) =>
      _send('/auth/login', 'POST', {'email': email, 'password': password})
          .then((m) => _persistAuth(m));
  Future<AuthData> register(String email, String fullName, String password) => _send(
      '/auth/register',
      'POST',
      {'email': email, 'fullName': fullName, 'password': password}).then((m) => _persistAuth(m));

  Future<AuthData> _persistAuth(Map<String, dynamic> json) async {
    final data = AuthData.fromStorage(jsonEncode(json));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_authKey, jsonEncode(json));
    _auth = data;
    return data;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_authKey);
    _auth = null;
  }

  Future<List<Task>> listTasks({String? status, String? search}) async {
    final q = <String, String>{};
    if (status != null && status.isNotEmpty) q['status'] = status;
    if (search != null && search.isNotEmpty) q['search'] = search;
    final list = await _send('/tasks', 'GET', null, query: q) as List;
    return list.map((e) => Task.fromJson(e)).toList();
  }

  Future<Task> createTask(TaskDraft draft) => _send('/tasks', 'POST', draft.toJson())
      .then((m) => Task.fromJson(m));
  Future<Task> updateTask(int id, TaskDraft draft) =>
      _send('/tasks/$id', 'PUT', draft.toJson()).then((m) => Task.fromJson(m));
  Future<void> deleteTask(int id) => _send('/tasks/$id', 'DELETE', null).then((_) {});

  // ---- low level ----
  Future<dynamic> _send(String path, String method, Map<String, dynamic>? body,
      {Map<String, String>? query}) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);

    final headers = <String, String>{
      'Accept': 'application/json',
      if (body != null) 'Content-Type': 'application/json',
      if (_auth != null && _auth!.token.isNotEmpty) 'Authorization': 'Bearer ${_auth!.token}',
    };

    final http.Response res = switch (method) {
      'POST' => await _http.post(uri, headers: headers, body: body == null ? null : jsonEncode(body)),
      'PUT' => await _http.put(uri, headers: headers, body: body == null ? null : jsonEncode(body)),
      'DELETE' => await _http.delete(uri, headers: headers),
      _ => await _http.get(uri, headers: headers),
    };

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException.fromResponse(res);
    }
    if (res.body.isEmpty) return null;
    return jsonDecode(res.body);
  }
}

class ApiException implements Exception {
  ApiException(this.message, this.statusCode);

  factory ApiException.fromResponse(http.Response res) {
    String message = 'Request failed (${res.statusCode}).';
    String? fieldError;
    try {
      final body = jsonDecode(res.body);
      if (body is Map<String, dynamic>) {
        if (body['message'] is String) message = body['message'] as String;
        final fe = body['fieldErrors'];
        if (fe is Map && fe.isNotEmpty) fieldError = fe.values.first.toString();
      }
    } catch (_) {}
    if (res.statusCode == 401 || res.statusCode == 403) {
      message = 'Your session has expired. Please sign in again.';
    }
    return ApiException(fieldError ?? message, res.statusCode);
  }

  final String message;
  final int statusCode;

  @override
  String toString() => message;
}
