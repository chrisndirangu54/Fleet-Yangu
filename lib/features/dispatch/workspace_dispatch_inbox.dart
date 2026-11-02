import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Tenant-authorized incoming Workspace requests, not demonstration records.
class WorkspaceDispatchInbox extends StatefulWidget {
  const WorkspaceDispatchInbox({super.key});

  @override
  State<WorkspaceDispatchInbox> createState() => _WorkspaceDispatchInboxState();
}

class _WorkspaceDispatchInboxState extends State<WorkspaceDispatchInbox> {
  final orgInput = TextEditingController();
  String? orgId;
  String? error;
  bool submitting = false;

  @override
  void dispose() {
    orgInput.dispose();
    super.dispose();
  }

  Future<void> _review(String tripId, String decision) async {
    if (orgId == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("${decision == 'accepted' ? 'Accept' : 'Decline'} dispatch request?"),
        content: const Text('This records a dispatcher decision in Fleet Yangu. '
            'It does not actuate any vehicle or automatically start a trip.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true),
              child: Text(decision == 'accepted' ? 'Accept' : 'Decline')),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => submitting = true);
    try {
      await FirebaseFunctions.instance
          .httpsCallable('fleetYanguReviewWorkspaceDispatch')
          .call({'organisationId': orgId, 'tripId': tripId,
            'decision': decision});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Dispatch request ${decision == 'accepted' ? 'accepted' : 'declined'}"),
        ));
      }
    } catch (e) {
      if (mounted) {
        setState(() => error = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      Text('TeknTandao Workspace dispatch inbox',
          style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 8),
      const Text('Authorized dispatchers may accept or decline incoming '
          'Workspace shipment requests. No vehicle is commanded automatically.'),
      const SizedBox(height: 12),
      if (FirebaseAuth.instance.currentUser == null)
        const Card(child: ListTile(
          leading: Icon(Icons.lock_outline),
          title: Text('Sign in as a Fleet Yangu dispatcher or owner '
              'in Admin & Security first.'),
        )),
      TextField(controller: orgInput,
          decoration: const InputDecoration(
              labelText: 'Fleet Yangu organisation ID')),
      const SizedBox(height: 8),
      Align(
        alignment: Alignment.centerLeft,
        child: FilledButton.icon(
          onPressed: () {
            if (RegExp(r'^[a-zA-Z0-9_-]{1,100}$')
                .hasMatch(orgInput.text.trim())) {
              setState(() {
                orgId = orgInput.text.trim();
                error = null;
              });
            } else {
              setState(() => error = 'Valid organization ID required');
            }
          },
          icon: const Icon(Icons.refresh),
          label: const Text('Load live requests'),
        ),
      ),
      if (error != null)
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Text(error!, style: const TextStyle(color: Colors.red)),
        ),
      if (orgId != null && FirebaseAuth.instance.currentUser != null)
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('organisations')
              .doc(orgId).collection('trips')
              .where('source', isEqualTo: 'tekntandao_workspace')
              .limit(50).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Text('Unable to load requests: ${snapshot.error}');
            }
            if (!snapshot.hasData) return const LinearProgressIndicator();
            final items = snapshot.data!.docs;
            if (items.isEmpty) {
              return const Card(child: ListTile(
                  title: Text('No incoming Workspace dispatch requests')));
            }
            return Column(children: items.map((item) {
              final data = item.data();
              final status = data['status']?.toString() ?? 'unknown';
              return Card(child: ListTile(
                leading: const Icon(Icons.local_shipping_outlined),
                title: Text("${data['reference'] ?? 'Shipment'} · ${data['destination'] ?? '-'}"),
                subtitle: Text("Vehicle: ${data['vehicleId'] ?? '-'} · Weight ${data['weightKg'] ?? '-'} kg · Status: $status"),
                trailing: status == 'awaiting_fleet_dispatcher_review'
                    ? Wrap(spacing: 6, children: [
                        TextButton(
                          onPressed: submitting ? null
                              : () => _review(item.id, 'declined'),
                          child: const Text('Decline')),
                        FilledButton(
                          onPressed: submitting ? null
                              : () => _review(item.id, 'accepted'),
                          child: const Text('Accept')),
                      ])
                    : const Icon(Icons.check_circle_outline),
              ));
            }).toList());
          },
        ),
    ],
  );
}
