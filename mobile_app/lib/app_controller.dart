import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'models/call_record.dart';
import 'services/call_api.dart';

class AppController extends ChangeNotifier {
  String ownerName = '';
  String serverUrl = 'http://10.0.2.2:8080';
  String adminToken = '';
  bool assistantEnabled = true;
  String greeting = 'Merhaba, şu anda uygun değilim. Size nasıl yardımcı olabilirim?';
  String workStart = '09:00';
  String workEnd = '18:00';
  bool useDemoData = true;
  bool loading = false;
  String? error;
  List<CallRecord> calls = _demoCalls;

  bool get isSignedIn => ownerName.trim().isNotEmpty;
  int get urgentCount => calls.where((call) => call.urgent && !call.calledBack).length;
  int get pendingCallbackCount => calls.where((call) => call.callbackRequested && !call.calledBack).length;
  List<CallRecord> get appointments => calls.where((call) => call.appointmentAt != null).toList();

  Future<void> signIn(String name) async {
    ownerName = name.trim();
    notifyListeners();
  }

  void signOut() {
    ownerName = '';
    notifyListeners();
  }

  CallApi get _api => CallApi(baseUrl: serverUrl, adminToken: adminToken);
  Uri _uri(String path) => Uri.parse('${serverUrl.replaceAll(RegExp(r'/$'), '')}$path');
  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (adminToken.trim().isNotEmpty) 'X-Admin-Token': adminToken.trim(),
      };

  Future<void> connectAndLoad() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final settings = await http.get(_uri('/api/config'), headers: _headers);
      if (settings.statusCode != 200) throw Exception('Ayarlar alınamadı (${settings.statusCode}).');
      final config = jsonDecode(settings.body) as Map<String, dynamic>;
      assistantEnabled = config['assistant_enabled'] != false;
      greeting = (config['greeting_text'] ?? greeting).toString();
      workStart = (config['work_start'] ?? workStart).toString();
      workEnd = (config['work_end'] ?? workEnd).toString();
      calls = await _api.fetchCalls();
      useDemoData = false;
    } catch (exception) {
      error = exception.toString().replaceFirst('Exception: ', '');
      useDemoData = true;
      calls = _demoCalls;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> saveAssistantSettings({
    required bool enabled,
    required String greetingText,
    required String start,
    required String end,
  }) async {
    error = null;
    notifyListeners();
    try {
      if (!useDemoData) {
        final response = await http.post(
          _uri('/api/config'),
          headers: _headers,
          body: jsonEncode({
            'assistant_enabled': enabled,
            'greeting_text': greetingText.trim(),
            'work_start': start.trim(),
            'work_end': end.trim(),
          }),
        );
        if (response.statusCode != 200) throw Exception('Ayarlar kaydedilemedi (${response.statusCode}).');
      }
      assistantEnabled = enabled;
      greeting = greetingText.trim();
      workStart = start.trim();
      workEnd = end.trim();
      notifyListeners();
      return true;
    } catch (exception) {
      error = exception.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> setCalledBack(CallRecord call, bool value) async {
    error = null;
    try {
      if (!useDemoData) await _api.markCalledBack(call.id, value);
      calls = calls.map((item) => item.id == call.id ? item.copyWith(calledBack: value) : item).toList();
      notifyListeners();
      return true;
    } catch (exception) {
      error = exception.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteAllData() async {
    try {
      if (!useDemoData) {
        final response = await http.post(
          _uri('/api/calls/delete-all'),
          headers: _headers,
          body: jsonEncode({'confirmed': true}),
        );
        if (response.statusCode < 200 || response.statusCode >= 300) {
          throw Exception('Veriler silinemedi (${response.statusCode}).');
        }
      }
      calls = const [];
      notifyListeners();
      return true;
    } catch (exception) {
      error = exception.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  static final List<CallRecord> _demoCalls = [
    CallRecord(
      id: 'demo-1',
      callerName: 'Ayşe Yılmaz',
      phone: '0555 111 22 33',
      summary: 'Yarınki görüşme için geri dönüş talep ediyor.',
      createdAt: DateTime.now().subtract(const Duration(minutes: 24)),
      urgent: false,
      callbackRequested: true,
      calledBack: false,
    ),
    CallRecord(
      id: 'demo-2',
      callerName: 'Mehmet Kaya',
      phone: '0532 444 55 66',
      summary: 'Acil yardım ihtiyacı olduğunu belirtti; 112 yönlendirmesi yapıldı.',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      urgent: true,
      callbackRequested: true,
      calledBack: false,
    ),
    CallRecord(
      id: 'demo-3',
      callerName: 'Elif Demir',
      phone: '0541 333 44 55',
      summary: 'Randevusunu teyit etmek istiyor.',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      urgent: false,
      callbackRequested: false,
      calledBack: true,
      appointmentAt: DateTime.now().add(const Duration(days: 2, hours: 3)),
    ),
  ];
}
