// Bima Guardian fleet cover is quote-first and NEVER an insurer binding API.
// No raw GPS tracks, driver health, ECU data, national IDs or claims evidence is sent.
export type FleetCover = 'fleet' | 'commercial';
const allowed = (v:unknown,max:number) =>
  typeof v === 'string' && v.trim().length>0 && v.trim().length<=max;
export function validFleetInsuranceRequest(input:any) {
  if(!['fleet','commercial'].includes(input?.subtype))
    throw new Error('Unsupported motor cover');
  if(!Number.isSafeInteger(input?.sumInsured)||
      input.sumInsured<10000||input.sumInsured>1000000000)
    throw new Error('Sum insured must be integer KES within allowable bounds');
  if(!allowed(input?.vehicleId,100)||!/^[A-Za-z0-9_-]{1,100}$/.test(input.vehicleId))
    throw new Error('Registered vehicle ID required');
  return {vehicleId:input.vehicleId,product:'motor',
    subtype:input.subtype as FleetCover,sumInsured:input.sumInsured,
    audience:'fleet_logistics'};
}
export function parseBimaQuote(raw:any) {
  if(!raw || typeof raw!=='object'||!Array.isArray(raw.options))
    throw new Error('Invalid Bima Guardian quotation response');
  const source=raw.source==='uploaded'?'uploaded_rate_card':'demo';
  return {source,status:'indicative_not_bound',verifiedInsurer:false,
    quoteReference:allowed(raw.id,100)?raw.id:null,
    currency:raw.currency==='KES'?'KES':'KES',
    options:raw.options.slice(0,12).filter((p:any)=>
      p && allowed(p.insurerName,100)&&
      typeof p.premium==='number'&&Number.isFinite(p.premium)&&p.premium>=0)
      .map((p:any)=>({insurerName:p.insurerName,
        insurerId:allowed(p.insurerId,100)?p.insurerId:null,
        estimatedPremiumKes:p.premium})),
    disclaimer:'Indicative Bima Guardian calculation only; requires licensed insurer verification, approved terms and payment before cover exists.'};
}
export function dateOnly(input:unknown) {
  if(typeof input!=='string'||!/^\d{4}-\d{2}-\d{2}$/.test(input))
    throw new Error('Date must be YYYY-MM-DD');
  const parsed=new Date(input+'T00:00:00Z');
  if(!Number.isFinite(parsed.getTime())||parsed.toISOString().slice(0,10)!==input)
    throw new Error('Invalid calendar date');
  return input;
}
export function policyRecord(input:any) {
  if(!allowed(input?.vehicleId,100)||!/^[A-Za-z0-9_-]{1,100}$/.test(input.vehicleId))
    throw new Error('Invalid registered vehicle');
  for(const key of ['insurer','policyNumber'])
    if(!allowed(input?.[key],120))throw new Error('Missing insurer or policy number');
  const effectiveFrom=dateOnly(input.effectiveFrom);
  const expiresOn=dateOnly(input.expiresOn);
  if(expiresOn<=effectiveFrom)throw new Error('Policy expiry must follow start');
  if(!['fleet','commercial'].includes(input.subtype))
    throw new Error('Invalid motor cover');
  return {vehicleId:input.vehicleId,insurer:input.insurer.trim(),
    policyNumber:input.policyNumber.trim(),subtype:input.subtype,
    effectiveFrom,expiresOn,source:'operator_recorded',
    verificationStatus:'unverified',insuranceStatus:'record_only'};
}
export function renewalStatus(policy:any, today=new Date()) {
  const verified=policy?.verificationStatus==='insurer_confirmed';
  const expiry=Date.parse(String(policy?.expiresOn||'')+'T00:00:00Z');
  if(!Number.isFinite(expiry))return {label:'invalid_expiry',daysToExpiry:null,activeCoverage:false};
  const midnight=Date.UTC(today.getUTCFullYear(),today.getUTCMonth(),today.getUTCDate());
  const days=Math.round((expiry-midnight)/86400000);
  return {label:(days<0?'expired':days<=30?'renewal_due':'recorded')+
      (verified?'':'_unverified'),
    daysToExpiry:days,activeCoverage:false}; // provider verification is not connected
}
