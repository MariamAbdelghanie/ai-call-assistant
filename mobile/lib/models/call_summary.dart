/// `call_logs.json` ve Firestore `call_summaries` kaydiyla birebir ayni alanlar.
class CallSummary {
  const CallSummary({
    required this.callId,
    required this.timestamp,
    required this.callerName,
    required this.callerNumber,
    required this.callerPurpose,
    required this.summary,
    required this.appointmentInfo,
    required this.isUrgent,
    required this.callbackRequested,
    required this.calledBack,
    required this.lang,
  });

  final String callId;
  final DateTime? timestamp;
  final String callerName;
  final String callerNumber;
  final String callerPurpose;
  final String summary;
  final String appointmentInfo;
  final bool isUrgent;
  final bool callbackRequested;
  final bool calledBack;
  final String lang;

  bool get hasAppointment => appointmentInfo.trim().isNotEmpty;

  /// Geri donus bekleyen: arayan istedi ama henuz aranmadi.
  bool get awaitingCallback => callbackRequested && !calledBack;

  static bool _asBool(Object? value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) return value.toLowerCase() == 'true';
    return false;
  }

  static String _asString(Object? value) =>
      value == null ? '' : value.toString();

  factory CallSummary.fromJson(Map<String, dynamic> json) {
    return CallSummary(
      callId: _asString(json['call_id']),
      timestamp: DateTime.tryParse(_asString(json['timestamp']))?.toLocal(),
      callerName: _asString(json['caller_name']).trim(),
      callerNumber: _asString(json['caller_number']).trim(),
      callerPurpose: _asString(json['caller_purpose']).trim(),
      // `summary_tr` eski alan adidir; icerik sahibin dilindeki ozettir.
      summary: _asString(json['summary_tr']).trim(),
      appointmentInfo: _asString(json['appointment_info']).trim(),
      isUrgent: _asBool(json['is_urgent']),
      callbackRequested: _asBool(json['callback_requested']),
      calledBack: _asBool(json['called_back']),
      lang: _asString(json['lang']).isEmpty ? 'tr' : _asString(json['lang']),
    );
  }

  /// Cevrimdisi onbellek icin: sunucudan gelen bicimle birebir ayni.
  Map<String, dynamic> toJson() => {
        'call_id': callId,
        'timestamp': timestamp?.toIso8601String() ?? '',
        'caller_name': callerName,
        'caller_number': callerNumber,
        'caller_purpose': callerPurpose,
        'summary_tr': summary,
        'appointment_info': appointmentInfo,
        'is_urgent': isUrgent,
        'callback_requested': callbackRequested,
        'called_back': calledBack,
        'lang': lang,
      };

  CallSummary copyWith({bool? calledBack}) => CallSummary(
        callId: callId,
        timestamp: timestamp,
        callerName: callerName,
        callerNumber: callerNumber,
        callerPurpose: callerPurpose,
        summary: summary,
        appointmentInfo: appointmentInfo,
        isUrgent: isUrgent,
        callbackRequested: callbackRequested,
        calledBack: calledBack ?? this.calledBack,
        lang: lang,
      );
}

/// `agent_config.json` icindeki, uygulamadan degistirilebilen alanlar.
class AssistantConfig {
  const AssistantConfig({
    required this.enabled,
    required this.workStart,
    required this.workEnd,
    required this.architecture,
    required this.ttsVoice,
    required this.realtimeVoice,
    required this.ownerLanguage,
  });

  final bool enabled;
  final String workStart;
  final String workEnd;
  final String architecture;
  final String ttsVoice;
  final String realtimeVoice;
  final String ownerLanguage;

  static const AssistantConfig fallback = AssistantConfig(
    enabled: true,
    workStart: '08:00',
    workEnd: '20:00',
    architecture: 'realtime',
    ttsVoice: 'elevenlabs-ar-ahmet',
    realtimeVoice: 'Kore',
    ownerLanguage: 'tr',
  );

  String get activeVoice =>
      architecture == 'realtime' ? realtimeVoice : ttsVoice;

  factory AssistantConfig.fromJson(Map<String, dynamic> json) {
    String str(String key, String fallbackValue) {
      final value = json[key];
      if (value == null) return fallbackValue;
      final text = value.toString().trim();
      return text.isEmpty ? fallbackValue : text;
    }

    return AssistantConfig(
      enabled: json['assistant_enabled'] is bool
          ? json['assistant_enabled'] as bool
          : true,
      workStart: str('work_start', '08:00'),
      workEnd: str('work_end', '20:00'),
      architecture: str('architecture', 'realtime'),
      ttsVoice: str('tts_voice', 'edge-ahmet'),
      realtimeVoice: str('realtime_voice', 'Kore'),
      ownerLanguage: str('owner_language', 'tr'),
    );
  }

  Map<String, dynamic> toJson() => {
        'assistant_enabled': enabled,
        'work_start': workStart,
        'work_end': workEnd,
        'architecture': architecture,
        'tts_voice': ttsVoice,
        'realtime_voice': realtimeVoice,
        'owner_language': ownerLanguage,
      };

  AssistantConfig copyWith({
    bool? enabled,
    String? workStart,
    String? workEnd,
    String? architecture,
    String? ttsVoice,
    String? realtimeVoice,
    String? ownerLanguage,
  }) =>
      AssistantConfig(
        enabled: enabled ?? this.enabled,
        workStart: workStart ?? this.workStart,
        workEnd: workEnd ?? this.workEnd,
        architecture: architecture ?? this.architecture,
        ttsVoice: ttsVoice ?? this.ttsVoice,
        realtimeVoice: realtimeVoice ?? this.realtimeVoice,
        ownerLanguage: ownerLanguage ?? this.ownerLanguage,
      );
}
