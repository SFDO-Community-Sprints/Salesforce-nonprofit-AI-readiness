const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const source = fs.readFileSync('force-app/main/default/lwc/readinessOrgHealth/readinessOrgHealth.js','utf8').replace(/^import .*;$/gm,'').replace('export default class','class').replace(/@api /g,'');
let response={score:50,coverage:75,passed:2,failed:2,unknown:1,rating:'Needs attention',findings:[
 {id:'pass',status:'pass',url:'/lightning/setup/Users/home'},
 {id:'fail',status:'fail',url:'javascript:alert(1)'},
 {id:'unknown',status:'unknown',url:'https://example.com'}
],inventory:[{id:'unavailable',count:null}],categories:[{id:'privacy',score:null,coverage:0,passed:0,failed:0,unknown:3}],banner:'Critical failures block a pilot'};
const Component=vm.runInNewContext(source+'\nReadinessOrgHealth',{LightningElement:class{dispatchEvent(event){this.lastEvent=event;}},CustomEvent:class{constructor(type,options){this.type=type;this.detail=options.detail;}},scan:async()=>JSON.stringify(response),loadHistory:async()=>JSON.stringify({recordedBy:'Recorded reviewer'}),Set,Number});
(async()=>{
 const screen=new Component(); assert.equal(screen.score,'Not checked');
 await screen.runScan(); assert.equal(screen.score,'50%');assert.equal(screen.categories[0].scoreLabel,'Not checked');assert.equal(screen.categories[0].coverageLabel,'0%');assert.match(screen.banner,/Critical/);assert.equal(screen.coverage,'75%');
 assert.equal(screen.findings[0].id,'fail');assert.equal(screen.findings[0].safeUrl,undefined);assert.equal(screen.findings[1].safeUrl,undefined);assert.equal(screen.findings[2].safeUrl,'/lightning/setup/Users/home');
 assert.equal(screen.inventory[0].countLabel,'Not checked');
 response.findings.push({id:'critical',status:'fail',severity:'Critical',url:'/lightning/o/Contact/list'});
 await screen.runScan();assert.equal(screen.findings[0].id,'critical');assert.equal(screen.findings[0].safeUrl,'/lightning/o/Contact/list');
 const originalScore = screen.score;
 screen.handleFilter({target:{dataset:{filter:'statusFilter'},value:'fail'}});
 assert.equal(screen.filteredFindings.length,2); assert.equal(screen.score,originalScore); assert.equal(screen.coverage,'75%');
 screen.handleFilter({target:{dataset:{filter:'severityFilter'},value:'Critical'}});
 assert.equal(screen.filteredFindings.length,1);assert.equal(screen.findingGroups[0].rows[0].id,'critical');
 screen.handleFilter({target:{dataset:{filter:'categoryFilter'},value:'Missing category'}});
 assert.equal(screen.noMatches,true);assert.match(screen.filterSummary,/0 of 4/);
 screen.clearFilters();assert.equal(screen.filteredFindings.length,4);
 screen.displayReport({score:0,coverage:0,scope:'Implementation: Donor helper',source:'Saved assessment',findings:[
  {id:'manual',status:'unknown',group:'Company',questionId:'privacy_owner',checklistScope:'company',useCaseId:'case1',action:'Record the accountable owner'},
  {id:'runtime',status:'unknown',group:'Safeguards',action:'Run the actual assistant test'},
  {id:'passed',status:'pass',group:'Company',questionId:'privacy_owner',checklistScope:'company'}
 ]});
 assert.equal(screen.sourceLabel,'Saved assessment');assert.equal(screen.scope,'Implementation: Donor helper');
 assert.equal(screen.findingGroups.length,2);assert.equal(screen.findings.find(row=>row.id==='manual').hasChecklist,true);
 assert.equal(screen.findings.find(row=>row.id==='runtime').hasChecklist,false);assert.equal(screen.findings.find(row=>row.id==='passed').hasChecklist,false);
 screen.openChecklist({currentTarget:{dataset:{id:'manual'}}});
 assert.equal(screen.lastEvent.type,'openchecklist');assert.equal(screen.lastEvent.detail.questionId,'privacy_owner');assert.equal(screen.lastEvent.detail.scope,'company');assert.equal(screen.lastEvent.detail.useCaseId,'case1');
 screen.openChecklist({currentTarget:{dataset:{id:'runtime'}}});assert.equal(screen.lastEvent.detail.questionId,'privacy_owner');
 assert.match(screen.findings[0].why,/not enough evidence/);assert.equal(screen.findings[0].how,'Record the accountable owner');
 screen.handleFilter({target:{dataset:{filter:'categoryFilter'},value:'Company'}});assert.equal(screen.filteredFindings.length,2);
 const html=fs.readFileSync('force-app/main/default/lwc/readinessOrgHealth/readinessOrgHealth.html','utf8');
 const css=fs.readFileSync('force-app/main/default/lwc/readinessOrgHealth/readinessOrgHealth.css','utf8');
 assert.match(html,/aria-label="Filter AI readiness findings"/);assert.match(html,/<details[^>]*class="advice"/);assert.match(html,/Answer in checklist/);
 assert.match(css,/th:nth-child\(4\),th:nth-child\(5\)\{width:20%\}/);
 screen.displayReport({findings:[],coverage:0,recordedBy:'Original reviewer',observedAt:new Date(Date.now()-2*86400000).toISOString()});assert.match(screen.scanActor,/Original reviewer/);assert.equal(screen.scanAge,'Observed 2 days ago');screen.result.observedAt='invalid';assert.equal(screen.scanAge,'Observation age unavailable');screen.result.observedAt=new Date(Date.now()+86400000).toISOString();assert.equal(screen.scanAge,'Observation age unavailable');
 response={error:'denied'};await screen.runScan();assert.equal(screen.result,undefined);assert.equal(screen.score,'Not checked');assert.match(screen.error,/No checks are marked as passed/);assert.equal(screen.loading,false);
 console.log('Org health UI coverage, safe links, scoped reports, filters, groups and checklist navigation passed');
})().catch(error=>{console.error(error);process.exitCode=1;});
