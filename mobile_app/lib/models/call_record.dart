class CallRecord {
  const CallRecord({
    required this.id,
    required this.callerName,
    required this.phone,
    required this.summary,
    required this.createdAt,
    required this.urgent,
    required this.callbackRequested,
    required this.calledBack,
    this.appointmentAt,
  });

  final String id;
  final String callerName;
  final String phone;
  final String summary;
  final DateTime createdAt;
  final bool urgent;
  final bool callbackRequested;
  final bool calledBack;
  final DateTime? appointmentAt;

  factory CallRecord.fromJson(Map<String, dynamic> json) {
    final rawStatus = (json['status'] ?? '').toString().toLowerCase();
    return CallRecord(
      id: (json['call_id'] ?? json['id'] ?? '').toString(),
      callerName: (json['caller_name'] ?? json['name'] ?? 'Bilinmeyen').toString(),
      phone: (json['callback_number'] ?? json['caller_number'] ?? json['phone'] ?? '').toString(),
      summary: (json['summary_tr'] ?? json['summary'] ?? json['message'] ?? json['caller_purpose'] ?? '').toString(),
      createdAt: DateTime.tryParse((json['created_at'] ?? json['timestamp'] ?? '').toString()) ?? DateTime.now(),
      urgent: json['is_urgent'] == true || json['urgent'] == true || rawStatus == 'urgent',
      callbackRequested: json['callback_requested'] == true || json['needs_callback'] == true,
      calledBack: json['called_back'] == true || rawStatus == 'called_back',
      appointmentAt: DateTime.tryParse((json['appointment_at'] ?? '').toString()),
    );
  }

  CallRecord copyWith({bool? calledBack, DateTime? appointmentAt}) => CallRecord(
        id: id,
        callerName: callerName,
        phone: phone,
        summary: summary,
        createdAt: createdAt,
        urgent: urgent,
        callbackRequested: callbackRequested,
        calledBack: calledBack ?? this.calledBack,
        appointmentAt: appointmentAt ?? this.appointmentAt,
      );
}
