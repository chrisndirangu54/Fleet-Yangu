class DiagnosticEvent {
  final String vehicleId;
  final String code;
  final String description;
  final String severity;
  final DateTime occurredAt;
  final Map<String, dynamic> freezeFrame;

  const DiagnosticEvent({
    required this.vehicleId,
    required this.code,
    required this.description,
    required this.severity,
    required this.occurredAt,
    this.freezeFrame = const {},
  });
}
