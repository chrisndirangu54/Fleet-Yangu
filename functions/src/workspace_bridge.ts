// Tenant-owned service connection for TeknTandao Workspace. This only exports
// an allowlisted vehicle snapshot and accepts a *proposed* dispatch job.
// Vehicle immobilization, CAN commands and driver health are never exposed.
import {onCall, onRequest, HttpsError} from 'firebase-functions/v2/https';
import {createHash,randomBytes,timingSafeEqual} from 'node:crypto';
import {getFirestore,FieldValue} from 'firebase-admin/firestore';

const db=getFirestore();
const id=(value:unknown)=> {
  if(typeof value!=='string'||!/^[a-zA-Z0-9_-]{1,100}$/.test(value))
    throw new Error('Invalid identifier');
  return value;
};
const hash=(value:string)=>createHash('sha256').update(value).digest('hex');
const iso=(value:any)=>value?.toDate?.()?.toISOString?.()||null;
async function owner(request:any) {
  if(!request.auth?.uid)throw new HttpsError('unauthenticated','Sign in');
  const orgId=id(request.data?.organisationId);
  const org=db.collection('organisations').doc(orgId);
  const member=(await org.collection('members').doc(request.auth.uid).get()).data();
  if(!member||!['owner','super_admin'].includes(member.role))
    throw new HttpsError('permission-denied','Fleet Yangu organization owner required');
  return {org,orgId,user:request.auth.uid};
}
export const fleetYanguIssueWorkspaceKey=onCall(async request=>{
  const {org,user}=await owner(request);
  const workspaceOrgId=id(request.data?.workspaceOrgId);
  const dispatchAllowed=request.data?.allowDispatch===true;
  const token='fyw_'+randomBytes(32).toString('base64url');
  const expiresAt=Date.now()+90*24*3600*1000;
  await org.collection('workspaceConnections').doc(workspaceOrgId).set({
    tokenHash:hash(token),expiresAt,enabled:true,allowDispatch:dispatchAllowed,
    createdBy:user,createdAt:FieldValue.serverTimestamp()
  });
  return {token,workspaceOrgId,expiresAt,allowDispatch:dispatchAllowed,
    warning:'Shown only once. Supply this key only to the matching Workspace owner. Rotate by issuing a new key.'};
});
export const fleetYanguRevokeWorkspaceKey=onCall(async request=>{
  const {org}=await owner(request);
  const workspaceOrgId=id(request.data?.workspaceOrgId);
  await org.collection('workspaceConnections').doc(workspaceOrgId).delete();
  return {revoked:true};
});

export function safeVehicleSummary(vehicleId:string,data:any) {
  const live=data?.live||{};
  const n=(key:string,min:number,max:number)=>{
    const value=live[key];
    return typeof value==='number'&&Number.isFinite(value)&&value>=min&&value<=max
      ?value:null;
  };
  const score=(key:string)=>{
    const x=data?.[key];return typeof x==='number'&&Number.isFinite(x)&&x>=0&&x<=100?x:null;
  };
  return {id:vehicleId,
    registration:String(data?.registration||'').slice(0,30),
    status:String(data?.status||'unknown').slice(0,40),
    healthScore:score('healthScore'),fleetRiskScore:score('fleetRiskScore'),
    lastTelemetryAt:iso(data?.lastTelemetryAt),
    telemetry:{coolantTempC:n('coolantTempC',-60,180),
      batteryVoltage:n('batteryVoltage',0,200),
      tyrePressurePsi:n('tyrePressurePsi',0,200),
      fuelPercent:n('fuelPercent',0,100),
      speedKph:n('speedKph',0,350),evBatterySoc:n('evBatterySoc',0,100)}};
}

function permission(res:any,code:number) {
  res.status(code).json({error:'Unauthorized or invalid Fleet Yangu Workspace request'});
}
export const fleetYanguWorkspaceBridge=onRequest({cors:false},async(req,res)=>{
  try{
    if(!['GET','POST'].includes(req.method)){res.status(405).json({error:'Method not allowed'});return;}
    if((req.rawBody?.length||0)>8192){res.status(413).json({error:'Payload too large'});return;}
    const fleetOrgId=id(req.get('x-fleet-organisation-id'));
    const workspaceOrgId=id(req.get('x-workspace-id'));
    const authorization=req.get('authorization')||'';
    if(!/^Bearer fyw_[A-Za-z0-9_-]{43}$/.test(authorization)){
      permission(res,401);return;
    }
    const secret=authorization.slice(7);
    const org=db.collection('organisations').doc(fleetOrgId);
    const connection=(await org.collection('workspaceConnections').doc(workspaceOrgId).get()).data();
    if(!connection?.enabled||!Number.isFinite(connection.expiresAt)||
       connection.expiresAt<=Date.now()||typeof connection.tokenHash!=='string'){
      permission(res,401);return;
    }
    const expected=Buffer.from(connection.tokenHash,'hex');
    const supplied=Buffer.from(hash(secret),'hex');
    if(expected.length!==supplied.length||!timingSafeEqual(expected,supplied)){
      permission(res,401);return;
    }
    if(req.method==='GET'){
      if(req.path!=='/v1/vehicles'){res.status(404).json({error:'Not found'});return;}
      const [vehicles,alerts,orders]=await Promise.all([
        org.collection('vehicles').limit(100).get(),
        org.collection('alerts').limit(100).get(),
        org.collection('workOrders').limit(100).get()
      ]);
      res.status(200).json({source:'fleet_yangu',organisationId:fleetOrgId,
        workspaceOrgId,readOnly:true,
        vehicles:vehicles.docs.map(doc=>safeVehicleSummary(doc.id,doc.data())),
        alerts:alerts.docs.map(doc=>({id:doc.id,
          vehicleId:String(doc.data().vehicleId||'').slice(0,100),
          type:String(doc.data().type||'').slice(0,80),
          severity:String(doc.data().severity||'').slice(0,20),
          status:String(doc.data().status||'').slice(0,30),
          createdAt:iso(doc.data().createdAt)})),
        workOrders:orders.docs.map(doc=>({id:doc.id,
          vehicleId:String(doc.data().vehicleId||'').slice(0,100),
          title:String(doc.data().title||'').slice(0,160),
          priority:String(doc.data().priority||'').slice(0,30),
          status:String(doc.data().status||'').slice(0,30)})),
        dispatchAllowed:connection.allowDispatch===true,
        sampled:true,limitedTo:100});
      return;
    }
    if(req.path!=='/v1/dispatch'){res.status(404).json({error:'Not found'});return;}
    if(connection.allowDispatch!==true){permission(res,403);return;}
    const body=req.body||{};
    const dispatchId=id(body.dispatchId);
    const vehicleId=id(body.vehicleId);
    const shipmentId=id(body.shipmentId);
    const reference=String(body.reference||'').trim();
    const destination=String(body.destination||'').trim();
    const weightKg=body.weightKg;
    if(!reference||reference.length>80||!destination||destination.length>160||
      typeof weightKg!=='number'||!Number.isFinite(weightKg)||weightKg<0||weightKg>100000){
      res.status(400).json({error:'Invalid dispatch manifest'});return;
    }
    const vehicle=await org.collection('vehicles').doc(vehicleId).get();
    if(!vehicle.exists){res.status(404).json({error:'Fleet vehicle not registered'});return;}
    const tripId=hash(workspaceOrgId+':'+dispatchId).slice(0,40);
    const trip=org.collection('trips').doc(tripId);
    let duplicate=false;
    await db.runTransaction(async tx=>{
      const existing=await tx.get(trip);
      if(existing.exists) {
        if(existing.data()?.sourceDispatchId!==dispatchId||
           existing.data()?.vehicleId!==vehicleId||
           existing.data()?.sourceShipmentId!==shipmentId)
          throw new Error('Dispatch identity conflict');
        duplicate=true;return;
      }
      tx.create(trip,{source:'tekntandao_workspace',workspaceOrgId,sourceDispatchId:dispatchId,
        sourceShipmentId:shipmentId,reference,destination,weightKg,vehicleId,
        status:'awaiting_fleet_dispatcher_review',createdAt:FieldValue.serverTimestamp()});
    });
    res.status(200).json({accepted:true,duplicate,tripId,
      status:'awaiting_fleet_dispatcher_review',
      notice:'Dispatch request recorded, not physically dispatched and no vehicle controls executed'});
  }catch(error){
    // Never reveal tenant identifiers, device identities or credential internals.
    res.status(400).json({error:'Invalid Fleet Yangu bridge request'});
  }
});
