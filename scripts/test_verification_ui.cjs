const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const source = fs.readFileSync('force-app/main/default/lwc/readinessVerification/readinessVerification.js','utf8').replace(/^import .*;$/gm,'').replace('export default class','class').replace(/@api /g,'');
let erasureCalls=0, inspected=0, allowControl=true;
const Component=vm.runInNewContext(source+'\nReadinessVerification',{
    LightningElement:class {},canErase:true,canManage:true,
    controlStatus:async()=>'{"disabled":false}',
    setDisabled:async ({disabled})=>JSON.stringify(allowControl?{disabled}:{error:'denied'}),
    inspect:async()=>{inspected++;return JSON.stringify({checks:[{id:'probe',status:'pass'}],gaps:[{id:'agent',status:'unknown',required_binding:'actual identity'}],monitoring:{recorded:true}});},
    targetHost:async()=>'test.scratch.my.salesforce.com',
    runErasure:async args=>{erasureCalls++;assert.equal(args.confirmed,true);return JSON.stringify({status:'observed',sourceActiveAbsent:'pass',aggregateExclusion:'pass',recycleBinErased:'fail',external:[{category:'backups',status:'unknown'}]});}
});
(async()=>{
 const screen=new Component();await screen.connectedCallback();
 await screen.runChecks();assert.equal(inspected,1);assert.equal(screen.gaps.length,1);assert.equal(screen.checks[0].outcome,'Passed');
 await screen.handleErasure();assert.equal(erasureCalls,0,'Active exercise requires separate confirmation');
 screen.confirmed=true;await screen.handleErasure();assert.equal(erasureCalls,1);assert.equal(screen.erasureChecks[2].status,'fail');assert.equal(screen.external[0].status,'unknown');
 await screen.toggleControl();assert.equal(screen.disabled,true);
 allowControl=false;await screen.toggleControl();assert.equal(screen.disabled,true,'Denied recovery must not pretend enabled');assert.match(screen.error,/failed/);
 screen.canErase=false;await screen.handleErasure();assert.equal(erasureCalls,1);
 console.log('Executed verification UI boundaries passed');
})().catch(error=>{console.error(error);process.exitCode=1;});
