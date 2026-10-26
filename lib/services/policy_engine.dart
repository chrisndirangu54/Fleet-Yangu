enum Decision { allow, requireApproval, deny }

class PolicyContext {
  final String command;
  final double speedKph;
  final bool gatewayTrusted;
  final bool driverPresent;
  final bool emergencyActive;
  final int approvals;
  final Set<String> roles;

  const PolicyContext({
    required this.command,
    required this.speedKph,
    required this.gatewayTrusted,
    required this.driverPresent,
    required this.emergencyActive,
    required this.approvals,
    required this.roles,
  });
}

class PolicyDecision {
  final Decision decision;
  final List<String> reasons;

  const PolicyDecision(this.decision, this.reasons);
}

/// UX mirror of server policy. Enforcement remains server/gateway-side.
class VehicleCommandPolicyEngine {
  const VehicleCommandPolicyEngine();

  PolicyDecision evaluate(PolicyContext c) {
    if (!c.gatewayTrusted) {
      return const PolicyDecision(Decision.deny, ['Gateway is not trusted']);
    }

    const stationaryOnly = {
      'unlock_hood',
      'unlock_fuel_cap',
      'unlock_battery_compartment',
      'immobilize_when_stationary',
    };

    if (stationaryOnly.contains(c.command) && c.speedKph > 1) {
      return const PolicyDecision(
        Decision.deny,
        ['Vehicle must be stationary'],
      );
    }

    if (c.emergencyActive && c.command != 'unlock_trunk') {
      return const PolicyDecision(
        Decision.deny,
        ['Emergency mode active'],
      );
    }

    if (!c.roles.any({'owner', 'super_admin', 'fleet_security'}.contains)) {
      return const PolicyDecision(
        Decision.deny,
        ['Insufficient privileged role'],
      );
    }

    if (c.approvals < 2) {
      return const PolicyDecision(
        Decision.requireApproval,
        ['Two-person approval required'],
      );
    }

    return const PolicyDecision(
      Decision.allow,
      ['Policy conditions satisfied'],
    );
  }
}
