import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:livekit_client/livekit_client.dart' as lk;
import 'package:permission_handler/permission_handler.dart';

import 'http_adapter.dart';

enum CallPhase { idle, connecting, connected, ending, failed }

/// Uygulamadan asistani arama akisi.
///
/// 1. `web_dialer.py` icindeki `GET /token` cagrilir; token, ws_url ve oda adi alinir.
/// 2. LiveKit odasina baglanilir, mikrofon acilir.
/// 3. Asistanin sesi otomatik olarak calinir (abone olunan ses parcasi).
class LiveCallService extends ChangeNotifier {
  LiveCallService({HttpAdapter? http})
      : _http = http ?? HttpAdapter(timeout: const Duration(seconds: 10));

  final HttpAdapter _http;

  lk.Room? _room;
  lk.EventsListener<lk.RoomEvent>? _listener;
  Timer? _ticker;
  DateTime? _startedAt;

  CallPhase phase = CallPhase.idle;
  String? errorMessage;
  String roomName = '';
  bool micEnabled = true;
  bool assistantSpeaking = false;
  Duration elapsed = Duration.zero;

  bool get isBusy =>
      phase == CallPhase.connecting || phase == CallPhase.ending;
  bool get isActive => phase == CallPhase.connected;

  Uri _uri(String baseUrl, String path) {
    final normalized = baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    final withScheme =
        normalized.startsWith('http') ? normalized : 'http://$normalized';
    return Uri.parse('$withScheme$path');
  }

  Future<bool> _ensureMicPermission() async {
    if (kIsWeb) return true;
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<void> start(String baseUrl) async {
    if (baseUrl.trim().isEmpty) {
      phase = CallPhase.failed;
      errorMessage = 'server_missing';
      notifyListeners();
      return;
    }
    if (isBusy || isActive) return;

    phase = CallPhase.connecting;
    errorMessage = null;
    elapsed = Duration.zero;
    notifyListeners();

    try {
      if (!await _ensureMicPermission()) {
        phase = CallPhase.failed;
        errorMessage = 'mic_denied';
        notifyListeners();
        return;
      }

      final raw = await _http.send(_uri(baseUrl, '/token'));
      final data = jsonDecode(raw);
      if (data is! Map<String, dynamic>) {
        throw Exception('token yaniti beklenen bicimde degil');
      }
      final token = (data['token'] ?? '').toString();
      var wsUrl = (data['ws_url'] ?? '').toString();
      roomName = (data['room'] ?? '').toString();
      if (token.isEmpty || wsUrl.isEmpty) {
        throw Exception('token veya ws_url bos');
      }

      // Sunucu kendi adresini bilmiyorsa, bagli oldugumuz adresi kullan.
      if (wsUrl.contains('127.0.0.1') || wsUrl.contains('localhost')) {
        final host = _uri(baseUrl, '/').host;
        wsUrl = 'ws://$host:7880';
      }

      final room = lk.Room(
        roomOptions: const lk.RoomOptions(adaptiveStream: true, dynacast: true),
      );
      _room = room;
      _listener = room.createListener();
      _bindEvents();

      await room.connect(wsUrl, token);
      await room.localParticipant?.setMicrophoneEnabled(true);
      micEnabled = true;

      _startedAt = DateTime.now();
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        final started = _startedAt;
        if (started == null) return;
        elapsed = DateTime.now().difference(started);
        notifyListeners();
      });

      phase = CallPhase.connected;
      notifyListeners();
    } catch (error) {
      await _teardown();
      phase = CallPhase.failed;
      errorMessage = error.toString();
      notifyListeners();
    }
  }

  void _bindEvents() {
    _listener
      ?..on<lk.RoomDisconnectedEvent>((_) async {
        await _teardown();
        phase = CallPhase.idle;
        notifyListeners();
      })
      ..on<lk.ActiveSpeakersChangedEvent>((event) {
        final localSid = _room?.localParticipant?.sid;
        assistantSpeaking =
            event.speakers.any((speaker) => speaker.sid != localSid);
        notifyListeners();
      });
  }

  Future<void> toggleMic() async {
    final participant = _room?.localParticipant;
    if (participant == null) return;
    micEnabled = !micEnabled;
    await participant.setMicrophoneEnabled(micEnabled);
    notifyListeners();
  }

  Future<void> hangUp() async {
    if (phase == CallPhase.idle) return;
    phase = CallPhase.ending;
    notifyListeners();
    await _teardown();
    phase = CallPhase.idle;
    notifyListeners();
  }

  Future<void> _teardown() async {
    _ticker?.cancel();
    _ticker = null;
    _startedAt = null;
    assistantSpeaking = false;
    await _listener?.dispose();
    _listener = null;
    try {
      await _room?.disconnect();
    } catch (_) {
      // Baglanti zaten kopmus olabilir.
    }
    await _room?.dispose();
    _room = null;
  }

  @override
  void dispose() {
    _teardown();
    _http.close();
    super.dispose();
  }
}
