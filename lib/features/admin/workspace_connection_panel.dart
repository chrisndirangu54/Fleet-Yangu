import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Real connector setup; unlike the demonstration dashboard, never shows demo keys.
class FleetYanguWorkspaceConnectionPanel extends StatefulWidget {
  const FleetYanguWorkspaceConnectionPanel({super.key});

  @override
  State<FleetYanguWorkspaceConnectionPanel> createState() => _FleetYanguWorkspaceConnectionPanelState();
}

class _FleetYanguWorkspaceConnectionPanelState extends State<FleetYanguWorkspaceConnectionPanel> {
  final fleetOrg = TextEditingController();
  final workspaceOrg = TextEditingController();
  bool busy = false;
  bool allowDispatch = false;
  String? message;

  @override
  void dispose() {
    fleetOrg.dispose();
    workspaceOrg.dispose();
    super.dispose();
  }

  Future<void> _run(String functionName, {bool issue = false}) async {
    if (FirebaseAuth.instance.currentUser == null) {
      setState(() => message = 'Sign in to a Fleet Yangu owner account first.');
      return;
    }
    setState(() { busy = true; message = null; });
    try {
      final response = await FirebaseFunctions.instance.httpsCallable(functionName).call({
        'organisationId': fleetOrg.text.trim(),
        'workspaceOrgId': workspaceOrg.text.trim(),
        if (issue) 'allowDispatch': allowDispatch,
      });
      if (!mounted) return;
      final data = Map<String, dynamic>.from(response.data as Map);
      if (issue) {
        final token = data['token']?.toString() ?? '';
        await showDialog<void>(context: context, builder: (ctx) => AlertDialog(
          title: const Text('One-time Workspace integration key'),
          content: SizedBox(width: 520, child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min, children: [
              const Text('Copy this key into TeknTandao Workspace under Fleet Yangu. '
                'It is shown only once and expires in 90 days. '
                'Store it securely and never post it publicly.'),
              const SizedBox(height: 12),
              SelectableText(token),
            ],
          )),
          actions: [
            TextButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: token));
                if (ctx.mounted) Navigator.pop(ctx);
              },
              icon: const Icon(Icons.copy), label: const Text('Copy and close')),
            TextButton(onPressed: () => Navigator.pop(ctx),
              child: const Text('Close')),
          ],
        ));
      }
      if (mounted) setState(() => message = issue
        ? 'Workspace integration key issued for ${workspaceOrg.text.trim()}.'
        : 'Workspace access revoked. Disconnect it inside Workspace as well.');
    } catch (error) {
      if (mounted) setState(() => message = 'Integration request failed: $error');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(padding: const EdgeInsets.all(18), child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('TeknTandao Workspace connection',
          style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        const Text('Authorize one Workspace organization to read limited Fleet Yangu '
          'vehicle health, diagnostic summaries and maintenance alerts. '
          'Dispatch handoff is optional and requires separate permission. '
          'No hardware controls or driver health data are shared.'),
        const SizedBox(height: 14),
        TextField(controller: fleetOrg,
          decoration: const InputDecoration(labelText: 'Fleet Yangu organisation ID')),
        const SizedBox(height: 10),
        TextField(controller: workspaceOrg,
          decoration: const InputDecoration(labelText: 'TeknTandao Workspace organisation ID')),
        const SizedBox(height: 10),
        SwitchListTile(
          value: allowDispatch,
          onChanged: busy ? null : (v) => setState(() => allowDispatch = v),
          title: const Text('Permit dispatch requests'),
          subtitle: const Text('Fleet Yangu still requires a dispatcher to review each request.')),
        const SizedBox(height: 12),
        Wrap(spacing: 12, runSpacing: 8, children: [
          FilledButton.icon(onPressed: busy ? null
            : () => _run('fleetYanguIssueWorkspaceKey', issue: true),
            icon: const Icon(Icons.vpn_key_outlined),
            label: const Text('Issue or rotate integration key')),
          OutlinedButton.icon(onPressed: busy ? null
            : () => _run('fleetYanguRevokeWorkspaceKey'),
            icon: const Icon(Icons.link_off),
            label: const Text('Revoke Workspace access')),
        ]),
        if (busy) const LinearProgressIndicator(),
        if (message != null) Padding(
          padding: const EdgeInsets.only(top: 12),child: Text(message!)),
      ],
    )),
  );
}
