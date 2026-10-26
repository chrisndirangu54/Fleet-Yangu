import 'package:flutter/material.dart';
import '../../data/demo_data.dart';
import '../../models/fleet_models.dart';
import '../../services/risk_engine.dart';

class FleetShell extends StatefulWidget {
  const FleetShell({super.key});

  @override
  State<FleetShell> createState() => _FleetShellState();
}

class _FleetShellState extends State<FleetShell> {
  String selected = 'dashboard';

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 960;
    final body = _body();
    return Scaffold(
      appBar: AppBar(
        title: const Row(children: [
          Icon(Icons.local_shipping_outlined),
          SizedBox(width: 10),
          Text('Fleet Yangu'),
        ]),
        actions: const [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Chip(avatar: Icon(Icons.cloud_done_outlined, size: 18), label: Text('Firebase connected')),
          ),
        ],
      ),
      drawer: wide ? null : Drawer(child: _Navigation(selected: selected, onSelect: _select)),
      body: Row(
        children: [
          if (wide) SizedBox(width: 280, child: Material(elevation: 1, child: _Navigation(selected: selected, onSelect: _select))),
          Expanded(child: body),
        ],
      ),
    );
  }

  void _select(String id) => setState(() => selected = id);

  Widget _body() {
    if (selected == 'dashboard') return const _Dashboard();
    if (selected == 'vehicles') return const _VehiclesPage();
    if (selected == 'risk') return const _RiskPage();
    if (selected == 'alerts') return const _AlertsPage();
    if (selected == 'admin') return const _AdminPage();
    FleetModule? module;
    for (final item in fleetModules) {
      if (item.id == selected) { module = item; break; }
    }
    return module == null ? const _Dashboard() : _ModulePage(module: module);
  }
}

class _Navigation extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;
  const _Navigation({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final core = [
      ('dashboard', 'Command Center', Icons.dashboard_outlined),
      ('vehicles', 'Vehicles & Digital Twins', Icons.directions_car_outlined),
      ('risk', 'Fleet Risk Engine', Icons.health_and_safety_outlined),
      ('alerts', 'Alerts & Incidents', Icons.notification_important_outlined),
    ];
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 8, 16, 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('FLEET YANGU', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.2)),
              SizedBox(height: 3),
              Text('Vehicle intelligence platform', style: TextStyle(fontSize: 12)),
            ]),
          ),
          ...core.map((e) => _nav(e.$1, e.$2, e.$3)),
          const Divider(),
          const Padding(padding: EdgeInsets.fromLTRB(20, 8, 16, 4), child: Text('SYSTEMS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
          ...fleetModules.map((m) => _nav(m.id, m.title, _iconFor(m.id))),
          const Divider(),
          _nav('admin', 'Admin & Security', Icons.admin_panel_settings_outlined),
        ],
      ),
    );
  }

  Widget _nav(String id, String title, IconData icon) => ListTile(
        dense: true,
        selected: selected == id,
        leading: Icon(icon),
        title: Text(title),
        onTap: () => onSelect(id),
      );
}

IconData _iconFor(String id) => switch (id) {
      'tracking' => Icons.gps_fixed_outlined,
      'ecu' => Icons.memory_outlined,
      'maintenance' => Icons.build_circle_outlined,
      'fuel' => Icons.local_gas_station_outlined,
      'tyres' => Icons.tire_repair_outlined,
      'driver' => Icons.badge_outlined,
      'adas' => Icons.videocam_outlined,
      'locks' => Icons.lock_outline,
      'cargo' => Icons.inventory_2_outlined,
      'roads' => Icons.route_outlined,
      'inspection' => Icons.fact_check_outlined,
      'incidents' => Icons.car_crash_outlined,
      'digital_twin' => Icons.hub_outlined,
      'cost' => Icons.analytics_outlined,
      'compliance' => Icons.verified_user_outlined,
      'workshops' => Icons.car_repair_outlined,
      'dispatch' => Icons.alt_route_outlined,
      'automation' => Icons.precision_manufacturing_outlined,
      'copilot' => Icons.auto_awesome_outlined,
      'offline' => Icons.satellite_alt_outlined,
      _ => Icons.grid_view_outlined,
    };

class _Dashboard extends StatelessWidget {
  const _Dashboard();

  @override
  Widget build(BuildContext context) {
    final engine = FleetRiskEngine();
    final avgHealth = demoVehicles.map((e) => e.healthScore).reduce((a,b)=>a+b) / demoVehicles.length;
    final highRisk = demoVehicles.where((v) => engine.assess(v).level.index >= RiskLevel.high.index).length;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Fleet Command Center', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        const Text('One operational view across diagnostics, safety, security, maintenance, cost, cargo and dispatch.'),
        const SizedBox(height: 20),
        Wrap(spacing: 12, runSpacing: 12, children: [
          _MetricCard(label: 'Fleet health', value: '${avgHealth.toStringAsFixed(0)}/100', icon: Icons.health_and_safety_outlined),
          _MetricCard(label: 'Vehicles online', value: '${demoVehicles.where((e)=>e.connected).length}/${demoVehicles.length}', icon: Icons.cloud_done_outlined),
          _MetricCard(label: 'High-risk vehicles', value: '$highRisk', icon: Icons.warning_amber_rounded),
          _MetricCard(label: 'Open alerts', value: '${demoAlerts.length}', icon: Icons.notifications_active_outlined),
          const _MetricCard(label: 'True fleet cost', value: 'KSh 34.8/km', icon: Icons.payments_outlined),
          const _MetricCard(label: 'CO₂ this month', value: '4.2 t', icon: Icons.eco_outlined),
        ]),
        const SizedBox(height: 24),
        Text('Vehicles needing attention', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        ...demoVehicles.map((v) => _VehicleCard(vehicle: v, assessment: engine.assess(v))),
        const SizedBox(height: 24),
        Text('Operational systems', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Wrap(spacing: 12, runSpacing: 12, children: fleetModules.map((m) => SizedBox(width: 330, child: _ModuleSummary(module: m))).toList()),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _MetricCard({required this.label, required this.value, required this.icon});
  @override
  Widget build(BuildContext context) => SizedBox(width: 215, child: Card(child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [Icon(icon, size: 30), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)), Text(label, style: Theme.of(context).textTheme.bodySmall)]))]))));
}

class _VehicleCard extends StatelessWidget {
  final VehicleSnapshot vehicle;
  final RiskAssessment assessment;
  const _VehicleCard({required this.vehicle, required this.assessment});
  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.center, spacing: 16, runSpacing: 10, children: [
            SizedBox(width: 320, child: Row(children: [const CircleAvatar(child: Icon(Icons.local_shipping_outlined)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${vehicle.registration} • ${vehicle.name}', style: const TextStyle(fontWeight: FontWeight.bold)), Text('${vehicle.type} • ${vehicle.speedKph.toStringAsFixed(0)} km/h • Health ${vehicle.healthScore.toStringAsFixed(0)}/100')]))])),
            _MiniMetric('Fuel/SOC', '${(vehicle.ev ? vehicle.batteryPercent : vehicle.fuelPercent).toStringAsFixed(0)}%'),
            _MiniMetric('Tyre', '${vehicle.tyrePressurePsi.toStringAsFixed(0)} psi'),
            _MiniMetric('Brakes', '${vehicle.brakeLifePercent.toStringAsFixed(0)}%'),
            _MiniMetric('Load', '${(vehicle.loadRatio * 100).toStringAsFixed(0)}%'),
            Chip(label: Text('${assessment.level.name.toUpperCase()} • ${assessment.score.toStringAsFixed(0)}/100')),
          ]),
        ),
      );
}

class _MiniMetric extends StatelessWidget {
  final String label; final String value;
  const _MiniMetric(this.label, this.value);
  @override Widget build(BuildContext context) => SizedBox(width: 88, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(value, style: const TextStyle(fontWeight: FontWeight.bold)), Text(label, style: Theme.of(context).textTheme.bodySmall)]));
}

class _ModuleSummary extends StatelessWidget {
  final FleetModule module;
  const _ModuleSummary({required this.module});
  @override Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Icon(_iconFor(module.id)), const SizedBox(width: 10), Expanded(child: Text(module.title, style: const TextStyle(fontWeight: FontWeight.bold))), Chip(label: Text(module.metric))]), const SizedBox(height: 6), Text(module.subtitle), const SizedBox(height: 10), Text(module.capabilities.take(3).join(' • '), style: Theme.of(context).textTheme.bodySmall)])));
}

class _ModulePage extends StatelessWidget {
  final FleetModule module;
  const _ModulePage({required this.module});
  @override Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(24), children: [
    Row(children: [CircleAvatar(radius: 28, child: Icon(_iconFor(module.id), size: 30)), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(module.title, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)), Text(module.subtitle)])), Chip(label: Text(module.metric))]),
    const SizedBox(height: 24),
    const _SafetyBanner(),
    const SizedBox(height: 16),
    Text('Capabilities', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
    const SizedBox(height: 10),
    Wrap(
      spacing: 12,
      runSpacing: 12,
      children: module.capabilities
          .map((c) => SizedBox(
                width: 320,
                child: Card(
                  child: ListTile(
                    leading: const Icon(Icons.check_circle_outline),
                    title: Text(c),
                    subtitle: const Text('Firebase-backed workflow / telemetry domain'),
                  ),
                ),
              ))
          .toList(),
    ),
    const SizedBox(height: 24),
    Text('Live integration model', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
    const SizedBox(height: 8),
    const Card(child: Padding(padding: EdgeInsets.all(18), child: Text('Vehicle sensors / ECU / camera / wearable → trusted gateway → authenticated ingestion → Firestore time-series events → Cloud Functions risk/anomaly processing → alerts, work orders, evidence and Flutter dashboards.'))),
  ]);
}

class _SafetyBanner extends StatelessWidget {
  const _SafetyBanner();
  @override Widget build(BuildContext context) => Card(child: ListTile(leading: const Icon(Icons.shield_outlined), title: const Text('Safety-first control plane'), subtitle: const Text('ECU and safety-critical actuator commands remain read-only or disabled by default. Any future vehicle control requires signed commands, role approval, vehicle-state validation and an auditable trusted gateway.')));
}

class _VehiclesPage extends StatelessWidget {
  const _VehiclesPage();
  @override Widget build(BuildContext context) { final engine = FleetRiskEngine(); return ListView(padding: const EdgeInsets.all(24), children: [Text('Vehicles & Digital Twins', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)), const SizedBox(height: 8), const Text('A persistent lifecycle record for mechanical condition, parts, service, drivers, incidents, fuel, tyres, cargo and operating cost.'), const SizedBox(height: 16), ...demoVehicles.map((v)=>_VehicleCard(vehicle:v, assessment:engine.assess(v)))]); }
}

class _RiskPage extends StatelessWidget {
  const _RiskPage();

  @override
  Widget build(BuildContext context) {
    final engine = FleetRiskEngine();
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Fleet Risk Engine',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text('Combines vehicle health, driver fatigue, tyres/brakes, load, route exposure, maintenance risk and connectivity.'),
        const SizedBox(height: 16),
        ...demoVehicles.map((v) {
          final r = engine.assess(v);
          final factors = r.factors.isEmpty ? 'No material risk factors' : r.factors.join(' • ');
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${v.registration} • ${v.name}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Chip(label: Text('${r.level.name.toUpperCase()} ${r.score.toStringAsFixed(0)}/100')),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: r.score / 100),
                  const SizedBox(height: 12),
                  Text('Factors: $factors'),
                  const SizedBox(height: 8),
                  Text(
                    'Recommended actions: ${r.actions.join(' • ')}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _AlertsPage extends StatelessWidget {
  const _AlertsPage();

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Alerts & Incidents',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...demoAlerts.map(
            (a) => Card(
              child: ListTile(
                leading: const Icon(Icons.warning_amber_rounded),
                title: Text(a.title),
                subtitle: Text('${a.detail}\nCategory: ${a.category} • Vehicle: ${a.vehicleId}'),
                isThreeLine: true,
                trailing: Chip(label: Text(a.severity.name.toUpperCase())),
              ),
            ),
          ),
        ],
      );
}

class _AdminPage extends StatelessWidget {
  const _AdminPage();

  @override
  Widget build(BuildContext context) {
    const adminCards = [
      ('Users & roles', 'Owner, super admin, admin, dispatcher, mechanic, safety officer, driver and read-only roles.', Icons.manage_accounts_outlined),
      ('Device registry', 'Gateway identity, secure boot status, firmware, certificates and last attestation.', Icons.router_outlined),
      ('API & connector vault', 'Keep provider credentials server-side; never place privileged secrets in Flutter.', Icons.key_outlined),
      ('AI model settings', 'Select approved anomaly, predictive-maintenance, vision and copilot models.', Icons.model_training_outlined),
      ('Command approvals', 'Two-person approval for configured high-risk controls; stationary-state checks required.', Icons.approval_outlined),
      ('Audit trail', 'Immutable record of access, exports, command attempts, policy changes and incident evidence.', Icons.history_outlined),
    ];
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Admin & Security Center',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text('Organisation controls, device trust, model settings, API integrations, roles and high-security approvals.'),
        const SizedBox(height: 16),
        ...adminCards.map(
          (e) => Card(
            child: ListTile(
              leading: Icon(e.$3),
              title: Text(e.$1),
              subtitle: Text(e.$2),
            ),
          ),
        ),
      ],
    );
  }
}
