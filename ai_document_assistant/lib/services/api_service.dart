import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

import '../models/ask_response.dart';
import '../models/document_entry.dart';
import '../models/document_info.dart';

class ApiException implements Exception {
  ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ApiService {
  ApiService({required this.baseUrl, http.Client? client})
    : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  Uri get _root => Uri.parse(baseUrl);

  Future<Map<String, dynamic>> healthCheck() async {
    final response = await _client.get(_root);
    return _decodeJson(response);
  }

  Future<DocumentInfo> uploadPdf(PlatformFile file) async {
    debugPrint('[ApiService] uploadPdf started: ${file.name}');
    final bytes = await file.readAsBytes();

    final request = http.MultipartRequest('POST', _root.resolve('/upload'))
      ..files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: file.name),
      );

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    final data = _decodeJson(response);
    debugPrint('[ApiService] uploadPdf completed: ${file.name}');
    return DocumentInfo.fromJson(data);
  }

  Future<AskResponse> askQuestion(String question) async {
    final response = await _client.post(
      _root.resolve('/ask'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'question': question}),
    );
    final data = _decodeJson(response);
    return AskResponse.fromJson(data);
  }

  Future<Map<String, dynamic>> clearSession() async {
    debugPrint('[ApiService] clearSession request started');
    final response = await _client.post(_root.resolve('/clear'));
    debugPrint('[ApiService] clearSession request completed');
    return _decodeJson(response);
  }

  Future<List<DocumentEntry>> fetchDocuments() async {
    debugPrint('[ApiService] fetchDocuments request started');
    final response = await _client.get(_root.resolve('/documents'));
    final data = _decodeJson(response);
    final documentsJson = data['documents'];
    if (documentsJson is! List) return [];
    final documents = documentsJson
        .whereType<Map<String, dynamic>>()
        .map(DocumentEntry.fromJson)
        .toList();
    debugPrint('[ApiService] fetchDocuments request completed (${documents.length})');
    return documents;
  }

  Map<String, dynamic> _decodeJson(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final detail = _extractErrorDetail(response.body);
      throw ApiException(detail);
    }
    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) return decoded;
    throw ApiException('Unexpected response format from server.');
  }

  String _extractErrorDetail(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic> && decoded['detail'] != null) {
        return decoded['detail'].toString();
      }
    } catch (_) {}
    return body.isEmpty ? 'Request failed.' : body;
  }
}
