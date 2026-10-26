class EvidenceRef {
  final String id;
  final String type;
  final String uri;
  final DateTime observedAt;

  const EvidenceRef({
    required this.id,
    required this.type,
    required this.uri,
    required this.observedAt,
  });
}

class CopilotRecommendation {
  final String summary;
  final List<String> reasoning;
  final List<EvidenceRef> evidence;
  final double confidence;
  final bool requiresHumanApproval;
  final String? proposedAction;

  const CopilotRecommendation({
    required this.summary,
    required this.reasoning,
    required this.evidence,
    required this.confidence,
    required this.requiresHumanApproval,
    this.proposedAction,
  });

  bool get canAutoExecute =>
      !requiresHumanApproval &&
      proposedAction != null &&
      {
        'create_work_order',
        'notify_dispatcher',
        'draft_incident_summary',
      }.contains(proposedAction);
}
