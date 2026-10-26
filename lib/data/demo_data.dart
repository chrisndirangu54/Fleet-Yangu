import '../models/fleet_models.dart';

const demoVehicles = <VehicleSnapshot>[
  VehicleSnapshot(
    id: 'hilux-001', registration: 'KDA 123A', name: 'Toyota Hilux', type: 'Pickup',
    healthScore: 91, latitude: -1.2864, longitude: 36.8172, speedKph: 42,
    fuelPercent: 61, batteryPercent: 72, coolantTempC: 92, tyrePressurePsi: 31,
    brakeLifePercent: 48, payloadKg: 530, payloadCapacityKg: 1000,
    driverFatigueScore: 24, routeRiskScore: 31, maintenanceRiskScore: 36,
    engineOn: true, connected: true,
  ),
  VehicleSnapshot(
    id: 'isuzu-014', registration: 'KDB 482K', name: 'Isuzu N-Series', type: 'Truck',
    healthScore: 78, latitude: -1.3192, longitude: 36.9278, speedKph: 67,
    fuelPercent: 38, batteryPercent: 81, coolantTempC: 101, tyrePressurePsi: 25,
    brakeLifePercent: 12, payloadKg: 4680, payloadCapacityKg: 4500,
    driverFatigueScore: 72, routeRiskScore: 67, maintenanceRiskScore: 71,
    engineOn: true, connected: true,
  ),
  VehicleSnapshot(
    id: 'ev-003', registration: 'KDH 903E', name: 'Electric Delivery Van', type: 'EV Van',
    healthScore: 95, latitude: -1.2490, longitude: 36.7800, speedKph: 0,
    fuelPercent: 0, batteryPercent: 43, coolantTempC: 36, tyrePressurePsi: 33,
    brakeLifePercent: 82, payloadKg: 420, payloadCapacityKg: 900,
    driverFatigueScore: 10, routeRiskScore: 28, maintenanceRiskScore: 18,
    engineOn: false, connected: true, ev: true,
  ),
];

final demoAlerts = <FleetAlert>[
  FleetAlert(id: 'a1', vehicleId: 'isuzu-014', title: 'Brake service critical', detail: 'Estimated brake life is 12%.', severity: RiskLevel.critical, occurredAt: DateTime.now().subtract(const Duration(minutes: 11)), category: 'brakes'),
  FleetAlert(id: 'a2', vehicleId: 'isuzu-014', title: 'Driver fatigue elevated', detail: 'Drowsiness model crossed fleet intervention threshold.', severity: RiskLevel.high, occurredAt: DateTime.now().subtract(const Duration(minutes: 7)), category: 'driver_safety'),
  FleetAlert(id: 'a3', vehicleId: 'isuzu-014', title: 'Tyre pressure anomaly', detail: 'Front-right pressure is below configured safe range.', severity: RiskLevel.high, occurredAt: DateTime.now().subtract(const Duration(minutes: 4)), category: 'tyres'),
];

const fleetModules = <FleetModule>[
  FleetModule(id:'tracking', title:'Live Tracking & Geofencing', subtitle:'GPS, trips, route playback and zone policy', metric:'24 online', status:FeatureStatus.healthy, capabilities:['Live GPS position','Trip history/playback','Depot/customer geofences','Restricted-zone rules','Odometer vs GPS reconciliation','Unauthorized movement/tow detection','ETA and route deviation']),
  FleetModule(id:'ecu', title:'ECU Diagnostics', subtitle:'OBD-II, CAN, J1939 & UDS', metric:'3 active DTCs', status:FeatureStatus.attention, capabilities:['Live PIDs and SPNs','DTC + freeze-frame decoder','Manufacturer profiles','Read-only gateway policy','Diagnostic trend analysis']),
  FleetModule(id:'maintenance', title:'Predictive Maintenance', subtitle:'Remaining useful life & work orders', metric:'2 due soon', status:FeatureStatus.warning, capabilities:['Component life prediction','Automatic work orders','Workshop booking','Parts matching','Service history','Downtime forecasting']),
  FleetModule(id:'fuel', title:'Fuel & Energy', subtitle:'Fuel theft, efficiency & EV charging', metric:'8.7 km/L', status:FeatureStatus.healthy, capabilities:['Tank + ECU reconciliation','Siphoning detection','Fuel-card matching','Idle fuel analysis','EV SOC/SOH','Charging optimization','Parasitic drain detection']),
  FleetModule(id:'tyres', title:'Tyres & Brakes', subtitle:'TPMS, wear, ABS & stopping risk', metric:'1 anomaly', status:FeatureStatus.warning, capabilities:['Pressure/temperature','Puncture prediction','Uneven wear','Brake-pad life','ABS fault analytics','Stopping-distance risk']),
  FleetModule(id:'driver', title:'Driver Safety & Health', subtitle:'Identity, fatigue, distraction & wellbeing', metric:'1 intervention', status:FeatureStatus.warning, capabilities:['Face/NFC/fingerprint authorization','Drowsiness','Phone distraction','Seatbelt detection','Driver health wearables','Shift/rest compliance','Behaviour score','Panic/SOS','Two-way mission messaging']),
  FleetModule(id:'adas', title:'ADAS & Cameras', subtitle:'360° video and machine-vision events', metric:'4 cameras online', status:FeatureStatus.healthy, capabilities:['Dashcam + cabin camera','Lane departure','Collision warning','Tailgating','Blind spot','Pedestrian/cyclist events','Event-triggered evidence clips']),
  FleetModule(id:'locks', title:'Smart Locks & Security', subtitle:'Hood, trunk, tank & battery protection', metric:'All secured', status:FeatureStatus.healthy, capabilities:['Hood lock','Trunk/cargo lock','Fuel-cap lock','Battery lock','Tamper sensors','Unauthorized towing/theft detection','Stationary-only immobilization workflow','Signed command approvals']),
  FleetModule(id:'cargo', title:'Cargo & Load Intelligence', subtitle:'Payload, cold chain and tamper monitoring', metric:'93% load', status:FeatureStatus.attention, capabilities:['Door state','Load cells','Axle balance','Temperature/humidity','Shock/vibration','Cold-chain compliance','Cargo theft anomaly detection']),
  FleetModule(id:'roads', title:'Road & Route Risk', subtitle:'Road surface, weather & operational risk', metric:'67/100 risk', status:FeatureStatus.warning, capabilities:['Pothole/rough-road sensing','Flood/weather context','Gradient/terrain','Congestion','Unsafe-zone geofences','Vehicle-route compatibility','Dynamic dispatch']),
  FleetModule(id:'inspection', title:'Smart Inspections & Damage AI', subtitle:'Pre/post-trip checks and visual damage history', metric:'96% complete', status:FeatureStatus.healthy, capabilities:['Guided pre-trip inspection','Post-trip inspection','Photo/video evidence','Damage change detection','Tyre/body/light checks','Driver sign-off','Defect-to-work-order automation']),
  FleetModule(id:'incidents', title:'Crash & Incident Intelligence', subtitle:'Emergency response and evidence', metric:'0 open crashes', status:FeatureStatus.healthy, capabilities:['Impact detection','Severity estimate','Impact direction','SOS/panic','Evidence package','Accident reconstruction dataset','Claims handoff']),
  FleetModule(id:'digital_twin', title:'Vehicle Digital Twin', subtitle:'Lifetime mechanical and operational record', metric:'27 twins', status:FeatureStatus.healthy, capabilities:['Parts genealogy','Service history','Fault history','Driver exposure','Accident record','Tyre/component lineage','Residual value estimate']),
  FleetModule(id:'cost', title:'Cost & Utilization', subtitle:'True cost per kilometre and asset ROI', metric:'KSh 34.8/km', status:FeatureStatus.healthy, capabilities:['Fuel + maintenance + tyres','Depreciation','Driver cost','Customer/route profitability','Under-utilization','Replacement timing','Carbon accounting']),
  FleetModule(id:'compliance', title:'Compliance & Insurance', subtitle:'Documents, risk and claims', metric:'2 expiries soon', status:FeatureStatus.attention, capabilities:['Insurance expiry','Inspection/licence alerts','Driver certification','Usage-based risk score','Claims initiation','Compliance evidence','Emissions monitoring']),
  FleetModule(id:'workshops', title:'Workshop & Parts Network', subtitle:'Repairs, inventory and quality scoring', metric:'8 partners', status:FeatureStatus.healthy, capabilities:['Nearby workshop matching','Parts compatibility','Inventory/pricing','Repair recurrence','Turnaround analytics','Warranty tracking','Supplier quality scoring']),
  FleetModule(id:'dispatch', title:'Smart Dispatch', subtitle:'Assign the safest, lowest-cost vehicle', metric:'14 trips today', status:FeatureStatus.healthy, capabilities:['Health-aware assignment','Load compatibility','Driver availability','Fuel/SOC constraints','Maintenance windows','Route constraints','Automatic reassignment']),
  FleetModule(id:'automation', title:'Vehicle Environment Automation', subtitle:'Depots, gates, charging and yards', metric:'5 integrations', status:FeatureStatus.healthy, capabilities:['Smart gates + ANPR','Charging stations','Weighbridges','Warehouse handoff','Parking automation','Workshop check-in','Mission dispatch']),
  FleetModule(id:'copilot', title:'Fleet AI Copilot', subtitle:'Natural-language operations intelligence', metric:'Ready', status:FeatureStatus.healthy, capabilities:['Ask fleet questions','Explain anomalies','Generate incident reports','Maintenance summaries','Cost analysis','Dispatch recommendations','Natural-language driver reports']),
  FleetModule(id:'offline', title:'Offline & Remote Operations', subtitle:'Store-and-forward + satellite fallback', metric:'Gateway buffered', status:FeatureStatus.healthy, capabilities:['Offline inspections','Telemetry buffering','Delayed sync','Satellite fallback adapter','Signed local events','Connectivity health','Conflict-safe synchronization']),
];
