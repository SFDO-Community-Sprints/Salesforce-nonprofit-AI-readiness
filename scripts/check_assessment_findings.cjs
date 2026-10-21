const assert=require('node:assert/strict');
const fs=require('node:fs');
const vm=require('node:vm');
const source=fs.readFileSync('force-app/main/default/lwc/readinessAssessmentFindings/readinessAssessmentFindings.js','utf8');
let fail=false, pending;
const Component=vm.runInNewContext(source.replace(/^import .*;\n/gm,'').replace('export default class','class').replaceAll('@api ','')+'\nReadinessAssessmentFindings',{
 LightningElement:class{},loadHistory:async({assessmentId})=>{
  if(pending)return pending;
  if(fail)throw new Error('SECRET server detail');
  return JSON.stringify({findings:[{id:assessmentId,label:'Access',status:'unknown',actual:'Not measured',expected:'Restricted access'}]});
 }
});
(async()=>{
 const c=new Component();c.recordId='scan1';await c.connectedCallback();await new Promise(r=>setTimeout(r,0));
 assert.equal(c.findings[0].id,'scan1');assert.equal(c.findings[0].outcome,'Not checked');
 fail=true;await c.load();assert(c.error.includes('could not be loaded'));assert(!c.error.includes('SECRET'));assert.equal(c.findings.length,0);
 fail=false;let resolve;pending=new Promise(r=>{resolve=r;});c.recordId='old';c.recordId=undefined;
 resolve(JSON.stringify({findings:[{id:'stale',status:'pass'}]}));await new Promise(r=>setTimeout(r,0));assert.equal(c.findings.length,0);assert(!c.loading);
 assert.equal(c.columns.filter(col=>col.fieldName==='actual')[0].initialWidth,c.columns.filter(col=>col.fieldName==='expected')[0].initialWidth);
 const page=fs.readFileSync('force-app/main/default/flexipages/Readiness_Assessment_Record_Page.flexipage-meta.xml','utf8');
 assert(page.includes('flexipage:fieldSection'));assert(!page.includes('force:recordDetailPanel'));
 for(const field of ['Name','Use_Case__c','Observed_At__c','Source__c','Rubric__c','Score__c','Coverage__c','Passed__c','Failed__c','Unknown__c','Scope__c','CreatedById']) assert(page.includes('<fieldItem>Record.'+field+'</fieldItem>'));
 assert.equal((page.match(/<value>readonly<\/value>/g)||[]).length,12);
 console.log('Native assessment findings record binding, safe denial, stale-response and equal-width checks passed.');
})().catch(error=>{console.error(error);process.exitCode=1;});
