import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../config/api_config.dart';
import 'storage_service.dart';

class ApiClient {
  final StorageService _storageService;
  final http.Client _client;

  ApiClient(this._storageService, [http.Client? client]) : _client = client ?? http.Client();

  Map<String, String> _getHeaders({bool isJson = true}) {
    final headers = <String, String>{};
    if (isJson) {
      headers['Content-Type'] = 'application/json';
      headers['Accept'] = 'application/json';
    }
    
    final token = _storageService.accessToken;
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<http.Response> get(String path) async {
    final url = Uri.parse('${ApiConfig.baseUrl}$path');
    final response = await _client.get(url, headers: _getHeaders());
    return _handleResponse(response, () => get(path));
  }

  Future<http.Response> post(String path, {Object? body}) async {
    final url = Uri.parse('${ApiConfig.baseUrl}$path');
    final response = await _client.post(
      url,
      headers: _getHeaders(),
      body: body != null ? json.encode(body) : null,
    );
    return _handleResponse(response, () => post(path, body: body));
  }

  Future<http.Response> put(String path, {Object? body}) async {
    final url = Uri.parse('${ApiConfig.baseUrl}$path');
    final response = await _client.put(
      url,
      headers: _getHeaders(),
      body: body != null ? json.encode(body) : null,
    );
    return _handleResponse(response, () => put(path, body: body));
  }

  Future<http.Response> patch(String path, {Object? body}) async {
    final url = Uri.parse('${ApiConfig.baseUrl}$path');
    final response = await _client.patch(
      url,
      headers: _getHeaders(),
      body: body != null ? json.encode(body) : null,
    );
    return _handleResponse(response, () => patch(path, body: body));
  }

  Future<http.Response> delete(String path) async {
    final url = Uri.parse('${ApiConfig.baseUrl}$path');
    final response = await _client.delete(url, headers: _getHeaders());
    return _handleResponse(response, () => delete(path));
  }

  /// Specialized file upload method for multipart form-data.
  /// Works across Mobile (filepath) and Web (bytes/filename).
  Future<http.Response> uploadMultipartFile(
    String path, {
    required List<int> fileBytes,
    required String filename,
    String fieldName = 'file',
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}$path');
    final request = http.MultipartRequest('POST', url);
    
    // Set headers
    final headers = _getHeaders(isJson: false);
    request.headers.addAll(headers);

    // Determine content type based on extension
    MediaType mediaType;
    final ext = filename.split('.').last.toLowerCase();
    if (ext == 'pdf') {
      mediaType = MediaType('application', 'pdf');
    } else if (ext == 'jpg' || ext == 'jpeg') {
      mediaType = MediaType('image', 'jpeg');
    } else if (ext == 'png') {
      mediaType = MediaType('image', 'png');
    } else {
      mediaType = MediaType('application', 'octet-stream');
    }

    // Add multipart file from bytes (compatible with both mobile and web)
    request.files.add(
      http.MultipartFile.fromBytes(
        fieldName,
        fileBytes,
        filename: filename,
        contentType: mediaType,
      ),
    );

    try {
      final streamedResponse = await _client.send(request);
      final response = await http.Response.fromStream(streamedResponse);
      return _handleResponse(
        response,
        () => uploadMultipartFile(path, fileBytes: fileBytes, filename: filename, fieldName: fieldName),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Evaluates response status codes.
  /// Intercepts 401 Unauthorized, runs refresh token logic, and retries the request if refresh succeeds.
  Future<http.Response> _handleResponse(http.Response response, Future<http.Response> Function() retryCallback) async {
    if (response.statusCode == 401) {
      final refreshSuccess = await _attemptTokenRefresh();
      if (refreshSuccess) {
        // Retry original request with new headers
        return await retryCallback();
      }
    }
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response;
    } else {
      // Decode error details if available from Spring Boot backend
      String message = 'Ocurrió un error en el servidor (${response.statusCode})';
      try {
        final decoded = json.decode(utf8.decode(response.bodyBytes));
        if (decoded is Map && decoded.containsKey('message')) {
          message = decoded['message'];
        } else if (decoded is Map && decoded.containsKey('error')) {
          message = decoded['error'];
        }
      } catch (_) {}
      throw ApiException(message, response.statusCode);
    }
  }

  /// Makes a separate un-intercepted request to refresh the token.
  Future<bool> _attemptTokenRefresh() async {
    final refreshToken = _storageService.refreshToken;
    final username = _storageService.username;
    if (refreshToken == null || username == null) {
      await _storageService.clearSession();
      return false;
    }

    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/auth/refresh');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'refreshToken': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        
        await _storageService.saveSession(
          accessToken: data['accessToken'],
          refreshToken: data['refreshToken'],
          expiresInSeconds: data['expiresIn'] ?? 3600,
          username: username,
        );
        return true;
      }
    } catch (e) {
      if (kDebugMode) print('Token refresh failed: $e');
    }

    // Refresh failed or timed out, clear session to force re-login
    await _storageService.clearSession();
    return false;
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException(this.message, this.statusCode);

  @override
  String toString() => message;
}
