class TelemetryEnvelope {
  final String eventId;
  final String organisationId;
  final String vehicleId;
  final String deviceId;
  final String schemaVersion;
  final int sequence;
  final DateTime capturedAt;
  final DateTime receivedAt;
  final Map<String, dynamic> payload;
  final Map<String, dynamic> provenance;

  const TelemetryEnvelope({
    required this.eventId,
    required this.organisationId,
    required this.vehicleId,
    required this.deviceId,
    required this.schemaVersion,
    required this.sequence,
    required this.capturedAt,
    required this.receivedAt,
    required this.payload,
    this.provenance = const {},
  });

  Duration get transportLatency => receivedAt.difference(capturedAt);

  bool get isClockSkewSuspicious =>
      capturedAt.isAfter(receivedAt.add(const Duration(minutes: 2))) ||
      receivedAt.difference(capturedAt) > const Duration(hours: 12);

  Map<String, dynamic> toMap() => {
        'eventId': eventId,
        'organisationId': organisationId,
        'vehicleId': vehicleId,
        'deviceId': deviceId,
        'schemaVersion': schemaVersion,
        'sequence': sequence,
        'capturedAt': capturedAt.toUtc().toIso8601String(),
        'receivedAt': receivedAt.toUtc().toIso8601String(),
        'payload': payload,
        'provenance': provenance,
      };
}
