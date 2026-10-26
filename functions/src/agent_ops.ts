export type AgentAction =
  | 'create_work_order'
  | 'recommend_driver_rest'
  | 'recommend_vehicle_swap'
  | 'request_inspection'
  | 'notify_dispatcher'
  | 'draft_incident_summary'
  | 'request_command_approval';

export type AgentProposal = {
  id: string;
  action: AgentAction;
  vehicleId: string;
  rationale: string[];
  confidence: number;
  evidenceRefs: string[];
  requiresHumanApproval: boolean;
  commandType?: string;
};

export type AgentContext = {
  vehicleId: string;
  fleetRiskScore: number;
  healthScore: number;
  driverFatigueScore: number;
  maintenanceRiskScore: number;
  brakeLifePercent: number;
  tyrePressurePsi: number;
  coolantTempC: number;
  connected: boolean;
  openAlertIds: string[];
};

export function proposeFleetActions(ctx: AgentContext): AgentProposal[] {
  const proposals: AgentProposal[] = [];
  const base = `${ctx.vehicleId}-${Date.now()}`;

  if (ctx.brakeLifePercent < 15 || ctx.coolantTempC >= 105 || ctx.maintenanceRiskScore >= 75) {
    proposals.push({
      id: `${base}-maintenance`,
      action: 'create_work_order',
      vehicleId: ctx.vehicleId,
      rationale: [
        `maintenanceRisk=${ctx.maintenanceRiskScore}`,
        `brakeLife=${ctx.brakeLifePercent}%`,
        `coolant=${ctx.coolantTempC}C`,
      ],
      confidence: 0.96,
      evidenceRefs: ctx.openAlertIds,
      requiresHumanApproval: false,
    });
  }

  if (ctx.driverFatigueScore >= 70) {
    proposals.push({
      id: `${base}-rest`,
      action: 'recommend_driver_rest',
      vehicleId: ctx.vehicleId,
      rationale: [`driverFatigueScore=${ctx.driverFatigueScore}`],
      confidence: 0.94,
      evidenceRefs: ctx.openAlertIds,
      requiresHumanApproval: true,
    });
  }

  if (ctx.fleetRiskScore >= 75) {
    proposals.push({
      id: `${base}-swap`,
      action: 'recommend_vehicle_swap',
      vehicleId: ctx.vehicleId,
      rationale: [`fleetRiskScore=${ctx.fleetRiskScore}`, `healthScore=${ctx.healthScore}`],
      confidence: 0.91,
      evidenceRefs: ctx.openAlertIds,
      requiresHumanApproval: true,
    });
  }

  if (!ctx.connected) {
    proposals.push({
      id: `${base}-inspection`,
      action: 'request_inspection',
      vehicleId: ctx.vehicleId,
      rationale: ['telematics_gateway_offline'],
      confidence: 0.88,
      evidenceRefs: ctx.openAlertIds,
      requiresHumanApproval: true,
    });
  }

  return proposals;
}

export function actionIsActuation(proposal: AgentProposal): boolean {
  return proposal.action === 'request_command_approval';
}
