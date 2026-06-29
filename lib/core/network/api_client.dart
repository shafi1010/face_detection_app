import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'api_exceptions.dart';

class ApiClient {
  final String baseUrl;
  final http.Client _httpClient;
  Future<String?> Function()? getToken;
  void Function()? onUnauthorized;

  ApiClient({
    required this.baseUrl,
    http.Client? client,
    this.getToken,
    this.onUnauthorized,
  }) : _httpClient = client ?? http.Client();

  Map<String, String> _headers({String? token}) {
    final headers = <String, String>{
      HttpHeaders.contentTypeHeader: 'application/json',
      HttpHeaders.acceptHeader: 'application/json',
    };
    if (token != null) {
      headers[HttpHeaders.authorizationHeader] = 'Bearer $token';
    }
    return headers;
  }

  Future<T> _request<T>({
    required String method,
    required String path,
    Map<String, dynamic>? queryParams,
    Object? body,
    T Function(dynamic json)? fromJson,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$path').replace(queryParameters: queryParams?.map((k, v) => MapEntry(k, v.toString())));
      final token = getToken != null ? await getToken!() : null;
      final headers = _headers(token: token);

      late http.Response response;
      switch (method) {
        case 'GET':
          response = await _httpClient.get(uri, headers: headers).timeout(const Duration(seconds: 15));
          break;
        case 'POST':
          response = await _httpClient.post(uri, headers: headers, body: body != null ? jsonEncode(body) : null).timeout(const Duration(seconds: 30));
          break;
        case 'PUT':
          response = await _httpClient.put(uri, headers: headers, body: body != null ? jsonEncode(body) : null).timeout(const Duration(seconds: 30));
          break;
        case 'PATCH':
          response = await _httpClient.patch(uri, headers: headers, body: body != null ? jsonEncode(body) : null).timeout(const Duration(seconds: 30));
          break;
        case 'DELETE':
          response = await _httpClient.delete(uri, headers: headers).timeout(const Duration(seconds: 15));
          break;
        default:
          throw ApiException('Unsupported method: $method');
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (fromJson != null && response.body.isNotEmpty) {
          final decoded = jsonDecode(response.body);
          return fromJson(decoded);
        }
        return null as T;
      }

      if (response.statusCode == 401) {
        onUnauthorized?.call();
      }

      throw ApiException.fromStatusCode(
        response.statusCode,
        body: response.body,
      );
    } on SocketException {
      throw const NetworkException();
    } on http.ClientException {
      throw const NetworkException();
    } on TimeoutException {
      throw const TimeoutException();
    }
  }

  Future<T> get<T>(String path, {
    Map<String, dynamic>? queryParams,
    T Function(dynamic)? fromJson,
  }) => _request(method: 'GET', path: path, queryParams: queryParams, fromJson: fromJson);

  Future<T> post<T>(String path, {
    Object? body,
    T Function(dynamic)? fromJson,
  }) => _request(method: 'POST', path: path, body: body, fromJson: fromJson);

  Future<T> put<T>(String path, {
    Object? body,
    T Function(dynamic)? fromJson,
  }) => _request(method: 'PUT', path: path, body: body, fromJson: fromJson);

  Future<T> patch<T>(String path, {
    Object? body,
    T Function(dynamic)? fromJson,
  }) => _request(method: 'PATCH', path: path, body: body, fromJson: fromJson);

  Future<T> delete<T>(String path, {
    T Function(dynamic)? fromJson,
  }) => _request(method: 'DELETE', path: path, fromJson: fromJson);

  void dispose() {
    _httpClient.close();
  }
}
