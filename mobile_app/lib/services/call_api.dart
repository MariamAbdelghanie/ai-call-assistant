import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/call_record.dart';

class CallApi {
  CallApi({required this.baseUrl, this.adminToken = ''});

  final String baseUrl;
  final String adminToken;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (adminToken.trim().isNotEmpty) 'X-Admin-Token': adminToken.trim(),
      };

  Uri _uri(String path) => Uri.parse('${baseUrl.replaceAll(RegExp(r'/$'), '')}$path');

  Future<List<CallRecord>> fetchCalls() async {
    final response = await http.get(_uri('/api/calls'), headers: _headers);
    if (response.statusCode != 200) throw Exception('Çağrı geçmişi alınamadı (${response.statusCode}).');
    final decoded = jsonDecode(response.body);
    final rows = decoded is List ? decoded : (decoded['calls'] as List? ?? const []);
    return rows.whereType<Map>().map((row) => CallRecord.fromJson(Map<String, dynamic>.from(row))).toList();
  }

  Future<void> markCalledBack(String callId, bool calledBack) async {
    final response = await http.post(
      _uri('/api/calls/$callId/returned'),
      headers: _headers,
      body: jsonEncode({'called_back': calledBack}),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Geri arama bilgisi kaydedilemedi (${response.statusCode}).');
    }
  }
}
