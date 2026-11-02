import {onCall,HttpsError} from 'firebase-functions/v2/https';
import {defineSecret} from 'firebase-functions/params';
import {getFirestore,FieldValue} from 'firebase-admin/firestore';
import {validFleetInsuranceRequest,parseBimaQuote,policyRecord,renewalStatus}
  from './bima_guardian_domain';

const db=()=>getFirestore();
const secret=defineSecret('BIMA_API_KEY');
const id=(v:unknown)=> {
  if(typeof v!=='string'||!/^[A-Za-z0-9_-]{1,100}$/.test(v))
    throw new HttpsError('invalid-argument','Invalid identifier');
  return v;
};
function endpoint() {
  let url:URL;
  try {url=new URL(process.env.BIMA_API_BASE_URL||'');}
  catch {throw new HttpsError('failed-precondition','Bima Guardian production gateway not configured');}
  if(url.protocol!=='https:'||url.username||url.password||url.hash||url.search||
     url.hostname==='localhost'||!url.hostname.includes('.')||
     /^\d+\.\d+\.\d+\.\d+$/.test(url.hostname))
    throw new HttpsError('failed-precondition','Bima Guardian requires a platform-configured HTTPS gateway');
  return url.toString().replace(/\/$/,'');
}
async function context(req:any) {
  if(!req.auth?.uid)throw new HttpsError('unauthenticated','Sign in first');
  const organisationId=id(req.data?.organisationId);
  const org=db().collection('organisations').doc(organisationId);
  const member=(await org.collection('members').doc(req.auth.uid).get()).data();
  if(!member||!['owner','super_admin','admin'].includes(member.role))
    throw new HttpsError('permission-denied','Fleet Yangu insurance administrator required');
  return {org,user:req.auth.uid};
}
function wrap(fn:(request:any)=>Promise<any>,useSecret=false){
  return onCall({secrets:useSecret?[secret]:[]},async req=>{
    try{return await fn(req);}
    catch(e) {
      if(e instanceof HttpsError)throw e;
      throw new HttpsError('failed-precondition',
        e instanceof Error?e.message:'Insurance operation could not be completed');
    }
  });
}
async function activeConsent(org:any) {
  const doc=(await org.collection('insurancePermissions').doc('bimaGuardian').get()).data();
  if(doc?.enabled!==true||typeof doc.expiresAtMs!=='number'||
     doc.expiresAtMs<=Date.now()||doc.scope!=='vehicle_valuation_only')
    throw new HttpsError('permission-denied','Renew explicit insurance-data-sharing consent');
}
export const fleetYanguAuthorizeBimaGuardian=wrap(async req=>{
  const {org,user}=await context(req);
  const enabled=req.data?.enabled===true;
  if(req.data?.enabled!==true&&req.data?.enabled!==false)
    throw new HttpsError('invalid-argument','Explicit authorization decision required');
  if(enabled&&req.data?.acknowledgedLimitedDisclosure!==true)
    throw new HttpsError('invalid-argument','Confirm purpose-limited data sharing');
  const expiresAtMs=enabled?Date.now()+30*86400000:Date.now();
  await org.collection('insurancePermissions').doc('bimaGuardian').set({
    enabled,scope:'vehicle_valuation_only',expiresAtMs,
    decisionBy:user,changedAt:FieldValue.serverTimestamp()
  });
  return {enabled,scope:'vehicle_valuation_only',expiresAtMs};
});
export const fleetYanguInsuranceOverview=wrap(async req=>{
  const {org}=await context(req);
  const [consent,policies,quotes,claims]=await Promise.all([
    org.collection('insurancePermissions').doc('bimaGuardian').get(),
    org.collection('insurancePolicies').limit(80).get(),
    org.collection('insuranceQuotes').limit(60).get(),
    org.collection('insuranceClaims').limit(60).get(),
  ]);
  const permission=consent.data()||{};
  return {provider:'bima_guardian',connected:false,liveInsurerVerification:false,
    consentActive:permission.enabled===true&&permission.expiresAtMs>Date.now(),
    policies:policies.docs.map(d=>({id:d.id,...d.data(),
      renewal:renewalStatus(d.data())})),
    quotes:quotes.docs.map(d=>({id:d.id,...d.data()})),
    claims:claims.docs.map(d=>({id:d.id,...d.data()})),
    warning:'Manual policies remain unverified. Quotes do not bind insurers; claims are only local drafts.'};
});
export const fleetYanguRequestBimaQuote=wrap(async req=>{
  const {org,user}=await context(req);
  await activeConsent(org);
  const data=validFleetInsuranceRequest(req.data);
  const vehicle=await org.collection('vehicles').doc(data.vehicleId).get();
  if(!vehicle.exists)throw new HttpsError('not-found','Vehicle not registered');
  if(!secret.value())throw new HttpsError('failed-precondition','Bima Guardian key not configured');
  let response:Response,body:any;
  try {
    response=await fetch(endpoint()+'/v1/quotes',{
      method:'POST',headers:{'x-api-key':secret.value(),'content-type':'application/json'},
      body:JSON.stringify({product:'motor',subtype:data.subtype,
        sumInsured:data.sumInsured,audience:data.audience}),
      redirect:'error',signal:AbortSignal.timeout(15000)
    });
    if(!response.ok)throw new Error('Provider request failed');
    const raw=await response.text();
    if(raw.length>100000)throw new Error('Quote response too large');
    body=JSON.parse(raw);
  }catch {throw new HttpsError('unavailable','Bima Guardian quotation service unavailable');}
  const normalized=parseBimaQuote(body);
  const doc=org.collection('insuranceQuotes').doc();
  await doc.create({vehicleId:data.vehicleId,product:'motor',subtype:data.subtype,
    sumInsuredKes:data.sumInsured,provider:'bima_guardian',
    ...normalized,createdBy:user,createdAt:FieldValue.serverTimestamp()});
  return {quoteId:doc.id,vehicleId:data.vehicleId,...normalized};
},true);
export const fleetYanguRecordInsurancePolicy=wrap(async req=>{
  const {org,user}=await context(req);
  const data=policyRecord(req.data);
  if(!(await org.collection('vehicles').doc(data.vehicleId).get()).exists)
    throw new HttpsError('not-found','Vehicle not registered');
  const ref=org.collection('insurancePolicies').doc();
  await ref.create({...data,createdBy:user,
    createdAt:FieldValue.serverTimestamp()});
  return {id:ref.id,verificationStatus:'unverified',
    warning:'Recorded from operator input only. Insurer confirmation is required before treating this as coverage.'};
});
export const fleetYanguDraftInsuranceClaim=wrap(async req=>{
  const {org,user}=await context(req);
  const policyId=id(req.data?.policyId);
  const policy=(await org.collection('insurancePolicies').doc(policyId).get()).data();
  if(!policy)throw new HttpsError('not-found','Insurance policy record not found');
  const description=String(req.data?.description||'').trim();
  if(description.length<10||description.length>500)
    throw new HttpsError('invalid-argument','Describe incident in 10–500 characters');
  const incidentId=req.data?.incidentId? id(req.data.incidentId):null;
  if(incidentId&&!(await org.collection('incidents').doc(incidentId).get()).exists)
    throw new HttpsError('not-found','Referenced incident not found');
  const claim=org.collection('insuranceClaims').doc();
  await claim.create({policyId,vehicleId:policy.vehicleId,description,incidentId,
    status:'draft_unsubmitted',provider:'bima_guardian',
    hasInsurerReference:false,createdBy:user,createdAt:FieldValue.serverTimestamp()});
  return {id:claim.id,status:'draft_unsubmitted',
    warning:'Local draft only; not sent to Bima Guardian or an insurer. Verify cover and obtain authorization before filing.'};
});
