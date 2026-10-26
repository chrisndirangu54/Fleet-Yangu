import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore db;
  FirestoreService({FirebaseFirestore? db}) : db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _org(String orgId, String name) =>
      db.collection('organisations').doc(orgId).collection(name);

  Stream<QuerySnapshot<Map<String, dynamic>>> vehicles(String orgId) => _org(orgId, 'vehicles').snapshots();
  Stream<QuerySnapshot<Map<String, dynamic>>> alerts(String orgId) => _org(orgId, 'alerts').orderBy('createdAt', descending: true).snapshots();
  Stream<QuerySnapshot<Map<String, dynamic>>> incidents(String orgId) => _org(orgId, 'incidents').orderBy('createdAt', descending: true).snapshots();
  Stream<QuerySnapshot<Map<String, dynamic>>> workOrders(String orgId) => _org(orgId, 'workOrders').orderBy('createdAt', descending: true).snapshots();
  Stream<QuerySnapshot<Map<String, dynamic>>> drivers(String orgId) => _org(orgId, 'drivers').snapshots();
  Stream<QuerySnapshot<Map<String, dynamic>>> trips(String orgId) => _org(orgId, 'trips').orderBy('startedAt', descending: true).snapshots();

  Future<void> ingestTelemetry({
    required String orgId,
    required String vehicleId,
    required Map<String, dynamic> payload,
  }) => _vehicleEvents(orgId, vehicleId, 'telemetry').add(_event(payload));

  Future<void> ingestDiagnostic({
    required String orgId,
    required String vehicleId,
    required Map<String, dynamic> payload,
  }) => _vehicleEvents(orgId, vehicleId, 'diagnostics').add(_event(payload));

  Future<void> ingestDriverSafetyEvent({
    required String orgId,
    required String vehicleId,
    required Map<String, dynamic> payload,
  }) => _vehicleEvents(orgId, vehicleId, 'driverSafetyEvents').add(_event(payload));

  Future<void> ingestCameraEvent({
    required String orgId,
    required String vehicleId,
    required Map<String, dynamic> payload,
  }) => _vehicleEvents(orgId, vehicleId, 'cameraEvents').add(_event(payload));

  Future<void> ingestCargoEvent({
    required String orgId,
    required String vehicleId,
    required Map<String, dynamic> payload,
  }) => _vehicleEvents(orgId, vehicleId, 'cargoEvents').add(_event(payload));

  Future<void> submitInspection({
    required String orgId,
    required String vehicleId,
    required Map<String, dynamic> inspection,
  }) => _vehicleEvents(orgId, vehicleId, 'inspections').add(_event(inspection));

  Future<DocumentReference<Map<String, dynamic>>> createWorkOrder({
    required String orgId,
    required String vehicleId,
    required String title,
    required String priority,
    Map<String, dynamic> metadata = const {},
  }) => _org(orgId, 'workOrders').add({
        'vehicleId': vehicleId,
        'title': title,
        'priority': priority,
        'status': 'open',
        ...metadata,
        'createdAt': FieldValue.serverTimestamp(),
      });

  Future<void> requestVehicleCommand({
    required String orgId,
    required String vehicleId,
    required String commandType,
    required String requestedBy,
    Map<String, dynamic> parameters = const {},
  }) async {
    // This creates a request only. A privileged server/gateway must validate
    // authorization, approvals, vehicle state and hardware support before execution.
    await _org(orgId, 'commandRequests').add({
      'vehicleId': vehicleId,
      'commandType': commandType,
      'parameters': parameters,
      'requestedBy': requestedBy,
      'status': 'pending_approval',
      'requiredApprovals': 2,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  CollectionReference<Map<String, dynamic>> _vehicleEvents(String orgId, String vehicleId, String name) =>
      _org(orgId, 'vehicles').doc(vehicleId).collection(name);

  Map<String, dynamic> _event(Map<String, dynamic> payload) => {
        ...payload,
        'serverReceivedAt': FieldValue.serverTimestamp(),
      };
}
