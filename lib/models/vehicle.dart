class Vehicle {
  final String id;
  final String registration;
  final String make;
  final String model;
  final int year;
  final double healthScore;
  final String status;

  const Vehicle({
    required this.id,
    required this.registration,
    required this.make,
    required this.model,
    required this.year,
    required this.healthScore,
    required this.status,
  });

  factory Vehicle.fromMap(String id, Map<String, dynamic> map) => Vehicle(
        id: id,
        registration: map['registration'] ?? '',
        make: map['make'] ?? '',
        model: map['model'] ?? '',
        year: map['year'] ?? 0,
        healthScore: (map['healthScore'] ?? 0).toDouble(),
        status: map['status'] ?? 'unknown',
      );
}
