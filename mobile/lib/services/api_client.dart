import 'dart:async';
import 'dart:convert';

import '../models/call_summary.dart';
import 'http_adapter.dart';

/// `web_dialer.py` uzerindeki uc noktalarla konusur.
/// Harici HTTP paketi kullanmaz; platforma gore HttpAdapter secilir.
///
///   GET  /logs              -> cagri kayitlari
///   POST /logs/returned     -> {call_id, called_back}
///   POST /logs/delete       -> {call_id}
///   GET  /api/config        -> asistan ayarlari
///   POST /api/config        -> ayar guncelleme
class ApiClient {
  ApiClient({Duration timeout = const Duration(seconds: 8)})
      : _http = HttpAdapter(timeout: timeout);

  final HttpAdapter _http;

  /// Sunucudaki API_TOKEN ile ayni olmalidir. Bos birakilirsa baslik
  /// gonderilmez; sunucu da korumasizsa istekler yine calisir.
  String token = '';

  Uri _uri(String baseUrl, String path) {
    final normalized = baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    final withScheme =
        normalized.startsWith('http') ? normalized : 'http://$normalized';
    return Uri.parse('$withScheme$path');
  }

  Future<String> _send(
    Uri uri, {
    String method = 'GET',
    Map<String, dynamic>? body,
  }) =>
      _http.send(
        uri,
        method: method,
        body: body,
        headers: token.isEmpty ? null : {'X-API-Token': token},
      );

  Future<List<CallSummary>> fetchCalls(String baseUrl) async {
    final text = await _send(_uri(baseUrl, '/logs'));
    final decoded = jsonDecode(text);
    if (decoded is! List) return const <CallSummary>[];
    final items = decoded
        .whereType<Map<String, dynamic>>()
        .map(CallSummary.fromJson)
        .toList();
    items.sort((a, b) {
      final left = a.timestamp;
      final right = b.timestamp;
      if (left == null && right == null) return 0;
      if (left == null) return 1;
      if (right == null) return -1;
      return right.compareTo(left);
    });
    return items;
  }

  Future<void> markCalledBack(
    String baseUrl,
    String callId, {
    required bool calledBack,
  }) async {
    await _send(
      _uri(baseUrl, '/logs/returned'),
      method: 'POST',
      body: {'call_id': callId, 'called_back': calledBack},
    );
  }

  Future<void> deleteCall(String baseUrl, String callId) async {
    await _send(
      _uri(baseUrl, '/logs/delete'),
      method: 'POST',
      body: {'call_id': callId},
    );
  }

  Future<AssistantConfig> fetchConfig(String baseUrl) async {
    final text = await _send(_uri(baseUrl, '/api/config'));
    final decoded = jsonDecode(text);
    if (decoded is! Map<String, dynamic>) return AssistantConfig.fallback;
    return AssistantConfig.fromJson(decoded);
  }

  Future<void> saveConfig(String baseUrl, AssistantConfig config) async {
    await _send(
      _uri(baseUrl, '/api/config'),
      method: 'POST',
      body: config.toJson(),
    );
  }

  void dispose() => _http.close();
}

/// Sunucu yokken arayuzun bos gorunmemesi icin ornek kayitlar.
class DemoData {
  static List<CallSummary> calls() {
    final now = DateTime.now();
    return [
      CallSummary(
        callId: 'demo-1',
        timestamp: now.subtract(const Duration(minutes: 24)),
        callerName: 'Ayşe Demir',
        callerNumber: '+90 5xx xxx 42 18',
        callerPurpose: 'Yarınki toplantının saati',
        summary:
            'Ayşe Demir aradı. Yarınki toplantının saatini öğrenmek istiyor '
            've uygunsa bir saat öne alınmasını rica ediyor. Geri dönüş istiyor.',
        appointmentInfo: '',
        isUrgent: false,
        callbackRequested: true,
        calledBack: false,
        lang: 'tr',
      ),
      CallSummary(
        callId: 'demo-2',
        timestamp: now.subtract(const Duration(hours: 2, minutes: 10)),
        callerName: 'خالد منصور',
        callerNumber: '+20 1xx xxx 7733',
        callerPurpose: 'حجز موعد',
        summary:
            'اتصل خالد منصور وطلب حجز موعد يوم الثلاثاء الساعة الثالثة عصراً. '
            'تم تأكيد الموعد معه ولا يحتاج معاودة اتصال.',
        appointmentInfo: '2026-11-17 15:00',
        isUrgent: false,
        callbackRequested: false,
        calledBack: false,
        lang: 'ar',
      ),
      CallSummary(
        callId: 'demo-3',
        timestamp: now.subtract(const Duration(hours: 5)),
        callerName: 'Mehmet Kaya',
        callerNumber: '+90 5xx xxx 09 51',
        callerPurpose: 'Acil durum',
        summary:
            'Mehmet Kaya acil olarak aranmak istediğini belirtti. Deponun '
            'elektriği kesilmiş, bugün içinde dönülmesi gerekiyor.',
        appointmentInfo: '',
        isUrgent: true,
        callbackRequested: true,
        calledBack: false,
        lang: 'tr',
      ),
      CallSummary(
        callId: 'demo-4',
        timestamp: now.subtract(const Duration(days: 1, hours: 3)),
        callerName: 'Sarah Whitfield',
        callerNumber: '+44 7xxx xxx 219',
        callerPurpose: 'Follow-up on the proposal',
        summary:
            'Sarah Whitfield called about the proposal sent last week. She '
            'asked for a short answer by email and did not need a callback.',
        appointmentInfo: '',
        isUrgent: false,
        callbackRequested: false,
        calledBack: true,
        lang: 'en',
      ),
      CallSummary(
        callId: 'demo-5',
        timestamp: now.subtract(const Duration(days: 2, hours: 1)),
        callerName: 'Elif Yılmaz',
        callerNumber: '+90 5xx xxx 88 04',
        callerPurpose: 'Randevu iptali',
        summary:
            'Elif Yılmaz, perşembe sabah onda olan randevusunu iptal etti. '
            'Yeni bir tarih için sonra arayacağını söyledi.',
        appointmentInfo: 'İPTAL EDİLDİ (2026-11-13 10:00)',
        isUrgent: false,
        callbackRequested: false,
        calledBack: true,
        lang: 'tr',
      ),
    ];
  }
}
