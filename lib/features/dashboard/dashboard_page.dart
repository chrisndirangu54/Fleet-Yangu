import 'package:flutter/material.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cards = <(String, String, IconData)>[
      ('Fleet Health', '92%', Icons.health_and_safety_outlined),
      ('Vehicles Online', '24 / 27', Icons.local_shipping_outlined),
      ('Critical Alerts', '3', Icons.warning_amber_rounded),
      ('Fuel Efficiency', '8.7 km/L', Icons.local_gas_station_outlined),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Fleet Yangu')),
      drawer: const _FleetDrawer(),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Operations Overview', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: cards
                .map((e) => SizedBox(
                      width: 260,
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Icon(e.$3, size: 30),
                            const SizedBox(height: 12),
                            Text(e.$2, style: Theme.of(context).textTheme.headlineSmall),
                            Text(e.$1),
                          ]),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 20),
          const Card(
            child: ListTile(
              leading: Icon(Icons.directions_car_filled_outlined),
              title: Text('KDA 123A • Toyota Hilux'),
              subtitle: Text('Health 91/100 • Battery degradation detected • Service due in 680 km'),
              trailing: Chip(label: Text('Attention')),
            ),
          ),
          const Card(
            child: ListTile(
              leading: Icon(Icons.local_shipping_outlined),
              title: Text('KDB 482K • Isuzu N-Series'),
              subtitle: Text('Health 78/100 • Tyre temperature anomaly • Route risk elevated'),
              trailing: Chip(label: Text('High risk')),
            ),
          ),
        ],
      ),
    );
  }
}

class _FleetDrawer extends StatelessWidget {
  const _FleetDrawer();
  @override
  Widget build(BuildContext context) {
    const entries = [
      ('Dashboard', Icons.dashboard_outlined),
      ('Vehicles', Icons.directions_car_outlined),
      ('Live Map', Icons.map_outlined),
      ('ECU Diagnostics', Icons.memory_outlined),
      ('Maintenance', Icons.build_outlined),
      ('Drivers', Icons.badge_outlined),
      ('Safety & ADAS', Icons.shield_outlined),
      ('Fuel & Energy', Icons.local_gas_station_outlined),
      ('Cameras', Icons.videocam_outlined),
      ('Cargo & Locks', Icons.inventory_2_outlined),
      ('Incidents', Icons.car_crash_outlined),
      ('Analytics', Icons.analytics_outlined),
      ('Admin', Icons.admin_panel_settings_outlined),
    ];
    return Drawer(
      child: SafeArea(
        child: ListView(
          children: [
            const ListTile(title: Text('Fleet Yangu', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
            ...entries.map((e) => ListTile(leading: Icon(e.$2), title: Text(e.$1))),
          ],
        ),
      ),
    );
  }
}
