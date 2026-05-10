import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:doc_scanner/core/constants.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class OcrService {
  final _storage = const FlutterSecureStorage();

  Future<String?> _getToken() async {
    return await _storage.read(key: 'token');
  }

  /// Calls `POST /ocr/extract/{documentId}` (see backend `endpoints/ocr.py`).
  Future<Map<String, dynamic>> extractText(
    int documentId, {
    String lang = 'eng',
    String engine = 'tesseract',
  }) async {
    final token = await _getToken();
    final uri = Uri.parse(
      '${AppConstants.baseUrl}/ocr/extract/$documentId',
    ).replace(
      queryParameters: {
        'lang': lang,
        'engine': engine,
      },
    );

    final response = await http.post(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );

    final raw = response.body.trim();
    Map<String, dynamic> body = {};
    if (raw.isNotEmpty) {
      try {
        final decoded = json.decode(raw);
        if (decoded is Map<String, dynamic>) {
          body = decoded;
        }
      } catch (_) {
        if (response.statusCode < 200 || response.statusCode >= 300) {
          throw Exception('Invalid response from server');
        }
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    final detail = body['detail'];
    if (detail is String) {
      throw Exception(detail);
    }
    if (detail is List && detail.isNotEmpty) {
      final first = detail.first;
      if (first is Map && first['msg'] != null) {
        throw Exception(first['msg'].toString());
      }
    }
    throw Exception(detail?.toString() ?? 'OCR extraction failed');
  }
}
