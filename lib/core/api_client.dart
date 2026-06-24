// lib/core/api_client.dart

import 'package:http/http.dart' as http;

class ApiClient {
  // Singleton setup
  ApiClient._internal();
  static final ApiClient instance = ApiClient._internal();
  factory ApiClient() => instance;

  // Base URL
  // static const String baseUrl = 'http://localhost/api';
  static const String baseUrl = 'http://172.16.100.27/api';

  // Default headers for JSON requests
  static Map<String, String> get jsonHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Build a Uri from a path with optional query parameters
  // Usage: ApiClient.buildUri('/employees')
  // Usage: ApiClient.buildUri('/employees', {'departmentId': '1'})
  static Uri buildUri(String path, [Map<String, String>? queryParams]) {
    final uri = Uri.parse('$baseUrl$path');
    if (queryParams != null && queryParams.isNotEmpty) {
      return uri.replace(queryParameters: queryParams);
    }
    return uri;
  }

  // Convenience GET
  Future<http.Response> get(
    String path, [
    Map<String, String>? queryParams,
  ]) async {
    return http.get(buildUri(path, queryParams), headers: jsonHeaders);
  }

  // Convenience POST
  Future<http.Response> post(
    String path,
    String body, [
    Map<String, String>? queryParams,
  ]) async {
    return http.post(
      buildUri(path, queryParams),
      headers: jsonHeaders,
      body: body,
    );
  }

  // Convenience PUT
  Future<http.Response> put(
    String path,
    String body, [
    Map<String, String>? queryParams,
  ]) async {
    return http.put(
      buildUri(path, queryParams),
      headers: jsonHeaders,
      body: body,
    );
  }

  // Convenience DELETE
  Future<http.Response> delete(
    String path, [
    Map<String, String>? queryParams,
  ]) async {
    return http.delete(buildUri(path, queryParams), headers: jsonHeaders);
  }
}
