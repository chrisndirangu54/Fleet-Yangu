import 'package:flutter/material.dart';
import '../features/shell/fleet_shell.dart';

class FleetYanguApp extends StatelessWidget {
  const FleetYanguApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fleet Yangu',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF146C43), brightness: Brightness.light),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF42B883), brightness: Brightness.dark), useMaterial3: true),
      home: const FleetShell(),
    );
  }
}
