import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:3000';

  static String? token;

  static Map<String, String> get _jsonHeaders {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token!.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  static Map<String, String> get _multipartHeaders {
    return {
      'Accept': 'application/json',
      if (token != null && token!.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  static bool _isSuccess(int statusCode) {
    return statusCode >= 200 && statusCode < 300;
  }

  static Uri _uri(String path) {
    return Uri.parse('$baseUrl$path');
  }

  static dynamic _decode(http.Response response) {
    if (response.body.trim().isEmpty) {
      return null;
    }

    try {
      return jsonDecode(response.body);
    } on FormatException {
      return null;
    }
  }

  static List<dynamic> _decodeList(http.Response response) {
    final data = _decode(response);

    if (data is List) {
      return data;
    }

    if (data is Map) {
      final possibleList = data['data'] ?? data['items'] ?? data['results'];

      if (possibleList is List) {
        return possibleList;
      }
    }

    return [];
  }

  static Map<String, dynamic> _decodeMap(http.Response response) {
    final data = _decode(response);

    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    return {};
  }

  static String _errorMessage(http.Response response, String fallback) {
    try {
      final data = _decode(response);

      if (data is Map) {
        return (data['message'] ?? data['error'] ?? data['detail'] ?? fallback)
            .toString();
      }
    } catch (_) {
      // ใช้ข้อความ fallback เมื่อ response ไม่ใช่ JSON
    }

    return '$fallback (${response.statusCode})';
  }

  static Future<http.Response> _get(
    String path, {
    Duration timeout = const Duration(seconds: 15),
  }) {
    return http.get(_uri(path), headers: _jsonHeaders).timeout(timeout);
  }

  static Future<http.Response> _post(
    String path, {
    Object? body,
    Duration timeout = const Duration(seconds: 15),
  }) {
    return http
        .post(
          _uri(path),
          headers: _jsonHeaders,
          body: body == null ? null : jsonEncode(body),
        )
        .timeout(timeout);
  }

  static Future<http.Response> _put(
    String path, {
    Object? body,
    Duration timeout = const Duration(seconds: 15),
  }) {
    return http
        .put(
          _uri(path),
          headers: _jsonHeaders,
          body: body == null ? null : jsonEncode(body),
        )
        .timeout(timeout);
  }

  static Future<http.Response> _delete(
    String path, {
    Duration timeout = const Duration(seconds: 15),
  }) {
    return http.delete(_uri(path), headers: _jsonHeaders).timeout(timeout);
  }

  // Authentication

  static Future<bool> login(String username, String password) async {
    final response = await _post(
      '/auth/login',
      body: {'username': username, 'password': password},
    );

    debugPrint('LOGIN STATUS: ${response.statusCode}');
    debugPrint('LOGIN BODY: ${response.body}');

    if (!_isSuccess(response.statusCode)) {
      return false;
    }

    final data = _decodeMap(response);

    final tokenValue =
        data['token'] ??
        data['accessToken'] ??
        data['access_token'] ??
        data['data']?['token'] ??
        data['data']?['accessToken'] ??
        data['data']?['access_token'];

    token = tokenValue?.toString();

    return token != null && token!.isNotEmpty;
  }

  static void logout() {
    token = null;
  }

  // Presentations

  static Future<List<dynamic>> getPresentations() async {
    final response = await _get('/presentations');

    if (_isSuccess(response.statusCode)) {
      return _decodeList(response);
    }

    throw Exception(_errorMessage(response, 'Failed to load presentations'));
  }

  static Future<Map<String, dynamic>> createPresentation({
    required String title,
    required String description,
    required int totalTargetTime,
    String filePath = '',
  }) async {
    final response = await _post(
      '/presentations',
      body: {
        'title': title,
        'description': description,
        'totalTargetTime': totalTargetTime,
        'filePath': filePath,
      },
    );

    if (_isSuccess(response.statusCode)) {
      return _decodeMap(response);
    }

    throw Exception(_errorMessage(response, 'Failed to create presentation'));
  }

  static Future<bool> updatePresentation({
    required String id,
    required String title,
    required String description,
    required int totalTargetTime,
    String filePath = '',
  }) async {
    final response = await _put(
      '/presentations/$id',
      body: {
        'title': title,
        'description': description,
        'totalTargetTime': totalTargetTime,
        'filePath': filePath,
      },
    );

    return _isSuccess(response.statusCode);
  }

  static Future<bool> deletePresentation(String id) async {
    final response = await _delete('/presentations/$id');

    return _isSuccess(response.statusCode);
  }

  // Slides

  static Future<List<dynamic>> getSlides(String presentationId) async {
    final response = await _get('/presentations/$presentationId/slides');

    if (_isSuccess(response.statusCode)) {
      return _decodeList(response);
    }

    throw Exception(_errorMessage(response, 'Failed to load slides'));
  }

  static Future<bool> updateSlide({
    required String slideId,
    required String extractedTextClean,
  }) async {
    final response = await _put(
      '/slides/$slideId',
      body: {'extractedTextClean': extractedTextClean},
    );

    return _isSuccess(response.statusCode);
  }

  static Future<bool> deleteSlide(String slideId) async {
    final response = await _delete('/slides/$slideId');

    return _isSuccess(response.statusCode);
  }

  // Scripts

  static Future<List<dynamic>> getScripts(String slideId) async {
    final response = await _get('/slides/$slideId/scripts');

    if (_isSuccess(response.statusCode)) {
      return _decodeList(response);
    }

    throw Exception(_errorMessage(response, 'Failed to load scripts'));
  }

  static Future<Map<String, dynamic>> createScript({
    required String slideId,
    required String content,
    required String level,
    required bool isAiGenerated,
  }) async {
    final response = await _post(
      '/scripts',
      body: {
        'slideId': slideId,
        'content': content,
        'level': level,
        'isAiGenerated': isAiGenerated,
      },
    );

    if (_isSuccess(response.statusCode)) {
      return _decodeMap(response);
    }

    throw Exception(_errorMessage(response, 'Failed to create script'));
  }

  static Future<bool> updateScript({
    required String scriptId,
    required String content,
    required String level,
    required bool isAiGenerated,
  }) async {
    final response = await _put(
      '/scripts/$scriptId',
      body: {
        'content': content,
        'level': level,
        'isAiGenerated': isAiGenerated,
      },
    );

    return _isSuccess(response.statusCode);
  }

  static Future<bool> deleteScript(String scriptId) async {
    final response = await _delete('/scripts/$scriptId');

    return _isSuccess(response.statusCode);
  }

  // File uploads

  static Future<bool> uploadPdfAndCreateSlides({
    required String presentationId,
    required String pdfPath,
    required int targetTime,
    int startSlideNo = 1,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      _uri('/presentations/$presentationId/slides/from-pdf'),
    );

    request.headers.addAll(_multipartHeaders);

    request.fields['targetTime'] = targetTime.toString();
    request.fields['startSlideNo'] = startSlideNo.toString();

    try {
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          pdfPath,
          filename: _fileName(pdfPath),
          contentType: MediaType('application', 'pdf'),
        ),
      );

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 120),
      );

      final response = await http.Response.fromStream(streamedResponse);

      return _isSuccess(response.statusCode);
    } catch (_) {
      return false;
    }
  }

  static Future<bool> uploadImages({
    required String presentationId,
    required List<String> imagePaths,
    required int targetTime,
  }) async {
    if (imagePaths.isEmpty) {
      return false;
    }

    final request = http.MultipartRequest(
      'POST',
      _uri('/presentations/$presentationId/slides/upload-images'),
    );

    request.headers.addAll(_multipartHeaders);
    request.fields['targetTime'] = targetTime.toString();

    try {
      for (final path in imagePaths) {
        final extension = _fileExtension(path);
        final mimeSubtype = _imageMimeSubtype(extension);

        request.files.add(
          await http.MultipartFile.fromPath(
            'files',
            path,
            filename: _fileName(path),
            contentType: MediaType('image', mimeSubtype),
          ),
        );
      }

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 120),
      );

      final response = await http.Response.fromStream(streamedResponse);

      return _isSuccess(response.statusCode);
    } catch (_) {
      return false;
    }
  }

  // OCR and AI script

  static Future<Map<String, dynamic>> runOcr(String slideId) async {
    final response = await _post(
      '/slides/$slideId/ocr',
      timeout: const Duration(seconds: 60),
    );

    if (_isSuccess(response.statusCode)) {
      return _decodeMap(response);
    }

    throw Exception(_errorMessage(response, 'OCR failed'));
  }

  static Future<Map<String, dynamic>> generateScript({
    required String slideId,
    required String level,
  }) async {
    final response = await _post(
      '/slides/$slideId/generate-script',
      body: {'level': level},
      timeout: const Duration(seconds: 100),
    );

    if (_isSuccess(response.statusCode)) {
      return _decodeMap(response);
    }

    throw Exception(_errorMessage(response, 'Failed to generate script'));
  }

  // File helpers

  static String _fileName(String path) {
    return path.split(RegExp(r'[\\/]+')).last;
  }

  static String _fileExtension(String path) {
    final fileName = _fileName(path);
    final dotIndex = fileName.lastIndexOf('.');

    if (dotIndex == -1 || dotIndex == fileName.length - 1) {
      return 'jpeg';
    }

    return fileName.substring(dotIndex + 1).toLowerCase();
  }

  static String _imageMimeSubtype(String extension) {
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'jpeg';

      case 'png':
        return 'png';

      case 'gif':
        return 'gif';

      case 'webp':
        return 'webp';

      case 'bmp':
        return 'bmp';

      default:
        return 'jpeg';
    }
  }
}
