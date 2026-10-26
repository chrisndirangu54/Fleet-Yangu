typedef ProjectionReducer<T> = T Function(
  T state,
  Map<String, dynamic> event,
);

class ReplayResult<T> {
  final T state;
  final int applied;
  final List<String> rejectedEventIds;

  const ReplayResult({
    required this.state,
    required this.applied,
    required this.rejectedEventIds,
  });
}

class EventReplayEngine<T> {
  final ProjectionReducer<T> reducer;

  const EventReplayEngine(this.reducer);

  ReplayResult<T> rebuild({
    required T initialState,
    required List<Map<String, dynamic>> events,
  }) {
    final ordered = [...events]
      ..sort((a, b) {
        final aTime = DateTime.tryParse('${a['capturedAt']}') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = DateTime.tryParse('${b['capturedAt']}') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final timeCompare = aTime.compareTo(bTime);
        if (timeCompare != 0) return timeCompare;
        return (a['sequence'] ?? 0).compareTo(b['sequence'] ?? 0);
      });

    final seen = <String>{};
    final rejected = <String>[];
    var state = initialState;
    var applied = 0;

    for (final event in ordered) {
      final id = '${event['eventId'] ?? ''}';
      if (id.isEmpty || !seen.add(id)) {
        rejected.add(id);
        continue;
      }
      state = reducer(state, event);
      applied++;
    }

    return ReplayResult(
      state: state,
      applied: applied,
      rejectedEventIds: rejected,
    );
  }
}
