const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const source = fs.readFileSync('force-app/main/default/lwc/readinessVerification/readinessVerification.js','utf8').replace(/^import .*;$/gm,'').replace('export default class','class').replace(/@api /g,'');
let erasureCalls=0, inspected=0, allowControl=true, statusAvailable=true, events=0;
const Component=vm.runInNewContext(source+'\nReadinessVerification',{
    LightningElement:class {dispatchEvent(){events++;}},CustomEvent:class{},canErase:true,canManage:true,
    controlStatus:async()=>JSON.stringify(statusAvailable?{disabled:false}:{error:'denied'}),
    setDisabled:async ({disabled})=>JSON.stringify(allowControl?{disabled}:{error:'denied'}),
    inspect:async()=>{inspected++;return JSON.stringify({checks:[{id:'contact_read',status:'pass'},{id:'native_assessment',status:'pass'},{id:'raw_email_read_boundary',status:'unknown'},{id:'unapproved_task_action',status:'fail'},{id:'mcp_boundary',status:'pass'}],gaps:[{id:'assistant_identity',status:'unknown'}],monitoring:{recorded:true}});},
    targetHost:async()=>'test.scratch.my.salesforce.com',
    runErasure:async args=>{erasureCalls++;assert.equal(args.confirmed,true);return JSON.stringify({status:'observed',sourceActiveAbsent:'pass',aggregateExclusion:'pass',recycleBinErased:'fail',external:[{category:'backups',status:'unknown'}]});}
});
(async()=>{
 const screen=new Component();assert.equal(screen.controlState,'Not checked');assert.equal(screen.controlDisabled,true);assert.equal(screen.gaps.length,5);
 await screen.connectedCallback();assert.equal(screen.controlState,'Running');
 await screen.runChecks();assert.equal(inspected,1);assert.equal(screen.gaps.length,1);assert.equal(screen.checks.length,4);assert.equal(screen.checks[0].outcome,'Passed');
 assert.equal(screen.passedCount,2);assert.equal(screen.failedCount,1);assert.equal(screen.unknownCount,1);assert.match(screen.resultMessage,/need attention/);assert.match(screen.checks[1].explanation,/Your account can read/);assert.match(screen.gaps[0].instruction,/actual AI account/);
 await screen.handleErasure();assert.equal(erasureCalls,0,'Active exercise requires separate confirmation');
 screen.confirmed=true;await screen.handleErasure();assert.equal(erasureCalls,1);assert.equal(events,1,'New deletion evidence refreshes overview');assert.equal(screen.erasureChecks[2].status,'fail');assert.equal(screen.erasureChecks[2].outcome,'Needs attention');assert.equal(screen.external[0].status,'unknown');
 await screen.toggleControl();assert.equal(screen.disabled,true);assert.equal(screen.controlState,'Paused');
 allowControl=false;await screen.toggleControl();assert.equal(screen.disabled,true,'Denied recovery must not pretend enabled');assert.match(screen.error,/could not be paused or resumed/);
 screen.canErase=false;await screen.handleErasure();assert.equal(erasureCalls,1);
 statusAvailable=false;await screen.refreshControl();assert.equal(screen.controlState,'Not checked');assert.equal(screen.controlDisabled,true);
 await screen.runChecks();assert.equal(screen.passedCount,2,'Missing control status does not erase valid test results');assert.equal(screen.controlState,'Not checked');
 console.log('Safeguard page explains results and preserves action/permission boundaries');
})().catch(error=>{console.error(error);process.exitCode=1;});
