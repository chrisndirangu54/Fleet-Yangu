import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Secure Bima Guardian motor-fleet workflows. The backend owns all credentials.
class BimaGuardianFleetScreen extends StatefulWidget {
  const BimaGuardianFleetScreen({super.key});
  @override
  State<BimaGuardianFleetScreen> createState() => _BimaGuardianFleetScreenState();
}
class _BimaGuardianFleetScreenState extends State<BimaGuardianFleetScreen> {
  final organisation = TextEditingController();
  final sumInsured = TextEditingController(text: '2000000');
  final insurer = TextEditingController();
  final policyNumber = TextEditingController();
  final starts = TextEditingController();
  final ends = TextEditingController();
  final description = TextEditingController();
  String? activeOrg;
  String? vehicleId;
  String? policyId;
  String subtype = 'fleet';
  bool sharedConsent = false;
  bool busy = false;
  String? message;
  Map<String, dynamic> overview = const {};

  @override
  void dispose() {
    for (final field in [organisation,sumInsured,insurer,policyNumber,
      starts,ends,description]) { field.dispose(); }
    super.dispose();
  }

  Future<Map<String, dynamic>> _call(String name, Map<String,dynamic> data) async {
    if(activeOrg==null || FirebaseAuth.instance.currentUser==null) {
      throw StateError('Sign in and load your Fleet Yangu organization first');
    }
    final result=await FirebaseFunctions.instance.httpsCallable(name).call({
      'organisationId':activeOrg,...data});
    return Map<String,dynamic>.from(result.data as Map);
  }

  Future<void> _action(String name,Map<String,dynamic> params,
      {bool refresh=true}) async {
    setState(() {busy=true;message=null;});
    try {
      final result=await _call(name,params);
      if(!mounted)return;
      setState(() => message=result['warning']?.toString() ??
        result['note']?.toString() ?? 'Insurance operation recorded successfully');
      if(refresh)await _refresh();
    }catch(e) {
      if(mounted)setState(() => message='Insurance action unavailable: $e');
    }finally {
      if(mounted)setState(() => busy=false);
    }
  }

  Future<void> _refresh() async {
    if(activeOrg==null)return;
    setState(() => busy=true);
    try{
      final result=await _call('fleetYanguInsuranceOverview',{});
      if(!mounted)return;
      final rows=(result['vehicles'] as List? ?? const []).whereType<Map>().toList();
      final policies=(result['policies'] as List? ?? const []).whereType<Map>().toList();
      setState((){
        overview=result;
        vehicleId=rows.any((x)=>x['id']==vehicleId)?vehicleId:
          rows.isEmpty?null:rows.first['id'].toString();
        policyId=policies.any((x)=>x['id']==policyId)?policyId:
          policies.isEmpty?null:policies.first['id'].toString();
      });
    }catch(e) {
      if(mounted)setState(() => message='Cannot load insurance register: $e');
    }finally{if(mounted)setState(()=>busy=false);}
  }

  List<Map<String,dynamic>> _rows(String key) =>
      (overview[key] as List? ?? const []).whereType<Map>()
      .map((x)=>Map<String,dynamic>.from(x)).toList();

  Widget _heading(String title)=>Padding(
      padding:const EdgeInsets.only(top:24,bottom:10),
      child:Text(title,style:Theme.of(context).textTheme.titleLarge));
  @override
  Widget build(BuildContext context) {
    final vehicles=_rows('vehicles'),policies=_rows('policies');
    final authenticated=FirebaseAuth.instance.currentUser!=null;
    return ListView(padding:const EdgeInsets.all(20),children:[
      Text('Bima Guardian · Fleet insurance',
        style:Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height:8),
      const Text('Request indicative fleet/commercial motor quotes, record existing '
        'policy details and organize insurer claim documents. '
        'No quote binds an insurer, and all recorded policies are unverified.'),
      const SizedBox(height:16),
      if(!authenticated)const Text(
        'Sign in as a Fleet Yangu organization owner or administrator first '
        'through Admin & Security.'),
      TextField(controller:organisation,
        decoration:const InputDecoration(labelText:'Fleet Yangu organisation ID')),
      const SizedBox(height:10),
      Align(alignment:Alignment.centerLeft,child:OutlinedButton.icon(
        onPressed:!authenticated||busy?null:(){
          final input=organisation.text.trim();
          if(!RegExp(r'^[A-Za-z0-9_-]{1,100}$').hasMatch(input)){
            setState(()=>message='Valid Fleet Yangu organisation ID required');
            return;
          }
          setState(()=>activeOrg=input);
          _refresh();
        },icon:const Icon(Icons.refresh),
        label:const Text('Load insurance records'))),
      if(message!=null)Padding(padding:const EdgeInsets.only(top:10),
        child:Text(message!,style:const TextStyle(color:Color(0xFF9A3412)))),
      if(busy)const LinearProgressIndicator(),
      if(activeOrg!=null)...[
        _heading('Consent and data protection'),
        CheckboxListTile(
          title:const Text('Authorize a limited Bima Guardian quotation request'),
          subtitle:const Text('Only cover type, sum insured and fleet category '
            'will be transmitted. No GPS trails, medical history or raw ECU data. '
            'Authorization expires after 30 days and can be revoked.'),
          value:sharedConsent,onChanged:busy?null:
            (v)=>setState(()=>sharedConsent=v??false)),
        Wrap(spacing:10,runSpacing:8,children:[
          FilledButton(onPressed:busy||!sharedConsent?null:()=>_action(
            'fleetYanguAuthorizeBimaGuardian',{
              'enabled':true,'acknowledgedLimitedDisclosure':true
            }),child:const Text('Authorize 30 days')),
          OutlinedButton(onPressed:busy?null:()=>_action(
            'fleetYanguAuthorizeBimaGuardian',{'enabled':false}),
            child:const Text('Revoke consent'))
        ]),
        Text(overview['consentActive']==true?'Consent active':'No current consent'),
        _heading('Request motor fleet quotation'),
        if(vehicles.isEmpty)const Text('Register a vehicle before requesting cover.'),
        if(vehicles.isNotEmpty)DropdownButtonFormField<String>(
          initialValue:vehicleId,
          decoration:const InputDecoration(labelText:'Vehicle'),
          items:vehicles.map((v)=>DropdownMenuItem<String>(
            value:v['id'].toString(),child:Text(
              (v['registration']??v['id']).toString()))).toList(),
          onChanged:(v)=>setState(()=>vehicleId=v)),
        const SizedBox(height:8),
        DropdownButtonFormField<String>(
          initialValue:subtype,
          decoration:const InputDecoration(labelText:'Cover type'),
          items:const [
            DropdownMenuItem(value:'fleet',child:Text('Motor fleet')),
            DropdownMenuItem(value:'commercial',child:Text('Commercial motor')),
          ],
          onChanged:(v){if(v!=null)setState(()=>subtype=v);}),
        TextField(controller:sumInsured,keyboardType:TextInputType.number,
          decoration:const InputDecoration(labelText:'Sum insured (KES)')),
        const SizedBox(height:8),
        FilledButton.icon(onPressed:busy||vehicleId==null?null:(){
          final sum=int.tryParse(sumInsured.text.trim());
          if(sum==null||sum<10000){
            setState(()=>message='Enter a valid sum insured in whole KES');return;
          }
          _action('fleetYanguRequestBimaQuote',{
            'vehicleId':vehicleId,'subtype':subtype,'sumInsured':sum});
        },icon:const Icon(Icons.request_quote_outlined),
          label:const Text('Request indicative quotation')),
        _heading('Quote history'),
        if(_rows('quotes').isEmpty)const Text('No quote requests yet.'),
        ..._rows('quotes').take(12).map((q)=>ExpansionTile(
          leading:const Icon(Icons.price_check_outlined),
          title:Text("Vehicle ${q['vehicleId']} · ${q['subtype']}"),
          subtitle:Text("Source: ${q['source']} · ${q['status']} "
            "· NOT insurer-confirmed"),
          children:[
            if(q['source']=='demo')const ListTile(
              title:Text('Demonstration premium estimates only'),
              subtitle:Text('No approved insurer rate card or binding cover is established.')),
            ...((q['options'] as List? ?? const []).whereType<Map>().map((o)=>
              ListTile(
                title:Text(o['insurerName']?.toString()??'Unverified insurer'),
                subtitle:Text('Indicative premium, not a binding offer'),
                trailing:Text("KES ${o['estimatedPremiumKes'] ?? '-'}"),
              ))),
          ],
        )),
        _heading('Record an existing insurance policy'),
        const Text('Manually entered policies are NOT automatically verified '
          'against Bima Guardian or an insurer.'),
        TextField(controller:insurer,
          decoration:const InputDecoration(labelText:'Insurer name')),
        TextField(controller:policyNumber,
          decoration:const InputDecoration(labelText:'Policy number')),
        TextField(controller:starts,
          decoration:const InputDecoration(labelText:'Effective from (YYYY-MM-DD)')),
        TextField(controller:ends,
          decoration:const InputDecoration(labelText:'Expires on (YYYY-MM-DD)')),
        const SizedBox(height:8),
        OutlinedButton.icon(onPressed:busy||vehicleId==null?null:()=>_action(
          'fleetYanguRecordInsurancePolicy',{
            'vehicleId':vehicleId,'subtype':subtype,
            'insurer':insurer.text.trim(),'policyNumber':policyNumber.text.trim(),
            'effectiveFrom':starts.text.trim(),'expiresOn':ends.text.trim()
          }),icon:const Icon(Icons.description_outlined),
          label:const Text('Save unverified policy record')),
        _heading('Policies and renewal watch'),
        if(policies.isEmpty)const Text('No policies recorded.'),
        ...policies.take(30).map((p)=>ListTile(
          leading:const Icon(Icons.verified_user_outlined),
          title:Text("${p['insurer']} · ${p['policyNumber']}"),
          subtitle:Text("Vehicle ${p['vehicleId']} · Expires ${p['expiresOn']} "
            "· ${p['verificationStatus']} · ${(p['renewal'] as Map?)?['label']}"),
        )),
        _heading('Prepare a claim'),
        const Text('Claim entries remain local drafts, not insurer submissions.'),
        if(policies.isNotEmpty)DropdownButtonFormField<String>(
          initialValue:policyId,
          decoration:const InputDecoration(labelText:'Recorded policy'),
          items:policies.map((p)=>DropdownMenuItem<String>(
            value:p['id'].toString(),
            child:Text(p['policyNumber']?.toString()??'Policy'))).toList(),
          onChanged:(v)=>setState(()=>policyId=v)),
        TextField(controller:description,maxLines:3,
          decoration:const InputDecoration(labelText:'Incident description (10–500 characters)')),
        const SizedBox(height:8),
        OutlinedButton.icon(onPressed:busy||policyId==null?null:()=>_action(
          'fleetYanguDraftInsuranceClaim',{
            'policyId':policyId,'description':description.text.trim()
          }),icon:const Icon(Icons.note_add_outlined),
          label:const Text('Create local claim draft')),
        Text("Claims in register: ${_rows('claims').length}"),
      ]
    ]);
  }
}
