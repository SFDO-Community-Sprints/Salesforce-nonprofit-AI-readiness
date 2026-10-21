const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const source = fs.readFileSync('force-app/main/default/lwc/readinessWorkspace/readinessWorkspace.js','utf8');
const saved=[];
const data={useCases:[{id:'one',name:'Donor service',owner:'Admin',purpose:'Service',groundingFields:['Contact.FirstName']},{id:'two',name:'Grant service'}],answers:[],questions:[{id:'privacy',scope:'company',stage:'People',label:'Privacy owner?'},{id:'access',scope:'implementation',stage:'Access',label:'Access?'}],history:[],canEdit:true};
const events=[],navigation=[];let loadFailure=false;let scanFailure=false;let savedReport=false;
const Navigate=Symbol('Navigate');const NavigationMixin=base=>class extends base{[Navigate](route){navigation.push(route);}};NavigationMixin.Navigate=Navigate;
const Component = vm.runInNewContext(source.replace(/^import .*;\n/gm,'').replace('export default class','class').replaceAll('@api ', '').replace(/@wire\([^)]*\)\s*/g,'')+'\nReadinessWorkspace', {
 NavigationMixin, LightningElement: class {dispatchEvent(e){events.push(e);}},CustomEvent:class{constructor(type,options){this.type=type;this.detail=options?.detail;}},
 loadWorkspace:async()=>{if(loadFailure)throw new Error('SECRET raw org error');return JSON.stringify(data);},saveUseCase:async({input})=>JSON.stringify({...JSON.parse(input),id:'one'}),saveAnswer:async({input})=>{saved.push(JSON.parse(input));return '{}';},
 scanUseCase:async()=>{if(scanFailure)throw new Error('SECRET raw org error');return JSON.stringify({findings:[],coverage:0,scope:'one',version:'v1',historySaved:savedReport,assessmentId:savedReport?'savedScan':undefined,historyMessage:'Recorder required'});},loadHistory:async({assessmentId})=>JSON.stringify({scope:assessmentId,version:'v1',coverage:0,findings:[]}), console
});
const event=(value,dataset={})=>({detail:{value},target:{value,dataset}});
(async()=>{
 const shortcut=new Component();shortcut.navigateChecklist({detail:{questionId:'access',scope:'implementation',useCaseId:'two'}});assert.equal(navigation[0].attributes.apiName,'AI_Checklists');assert.equal(navigation[0].state.c__questionId,'access');assert.equal(navigation[0].state.c__scope,'implementation');assert.equal(navigation[0].state.c__useCaseId,'two');navigation.length=0;
 const routed=new Component();routed.mode='checklists';routed.receivePage({state:{c__useCaseId:'two',c__questionId:'access',c__scope:'implementation'}});await routed.load();
 assert.equal(routed.selectedId,'two');assert.equal(routed.scope,'implementation');assert(routed.showChecklists);assert(!routed.showCases);assert(!routed.showHistory);
 for (const [mode,visible] of [['cases','showCases'],['history','showHistory']]) {const page=new Component();page.mode=mode;assert(page[visible]);assert(!page.showChecklists);}
 const c=new Component();await c.load();assert.equal(c.data.useCases.length,2);
 c.selectCase(event('one'));c.changeCase(event('Unsaved purpose',{field:'purpose'}));
 c.selectCase(event('two'));c.selectCase(event('one'));assert.equal(c.draft.purpose,'Unsaved purpose');assert(c.scanDisabled);
 await c.saveCase();assert(!c.dirty);assert(events.some(e=>e.type==='workspacechange'));
 const q=c.questions[0];assert.equal(q.answer,'unknown');
 c.changeAnswer(event('partial',{key:q.key,field:'answer'}));c.changeScope(event('implementation'));assert(c.questions[0].id==='access');
 c.changeScope(event('company'));assert.equal(c.questions[0].answer,'partial');
 await c.saveQuestion({target:{dataset:{key:q.key}}});assert.equal(saved[0].answer,'partial');assert.equal(saved[0].useCaseId,null);
 c.data.canEdit=false;await c.saveQuestion({target:{dataset:{key:q.key}}});assert.equal(saved.length,1,'Reader must not save');
 await c.runScan();assert.equal(c.historyMessage,'Recorder required');assert(!c.message.includes('saved'));assert(events.some(e=>e.type==='scopedresult' && e.detail.report.findings.length===0));
 await c.chooseHistory(event('one'));await c.chooseHistory(event('two',{comparison:'true'}));assert(c.comparisonWarning.includes('not directly comparable'));
 const history=new Component();await history.load();history.mode='history';
 history.data.history=[{id:'scan1',name:'AIR-001',useCaseId:'one',observedAt:'2026-10-21T10:00:00Z',score:0,coverage:0},{id:'scan2',name:'AIR-002',useCaseId:null,score:null,coverage:40}];
 assert(!history.showImplementationSelector);assert.equal(history.historyRows[0].implementation,'Donor service');assert.equal(history.historyRows[0].scoreLabel,'0%');assert.equal(history.historyRows[1].implementation,'Organization');assert.equal(history.historyRows[1].scoreLabel,'Unknown');
 await history.reviewHistory({detail:{action:{name:'review'},row:{id:'scan1'}}});assert.equal(history.historyId,'scan1');assert.equal(history.snapshotRows[0].name,'AIR-001');
 await history.reviewHistory({detail:{action:{name:'compare'},row:{id:'scan1'}}});assert.equal(history.comparisonId,'');assert(!history.comparisonReport);assert(history.message.includes('different saved assessment'));
 await history.reviewHistory({detail:{action:{name:'compare'},row:{id:'scan2'}}});assert.equal(history.comparisonId,'scan2');
 await history.reviewHistory({detail:{action:{name:'review'},row:{id:'scan2'}}});assert.equal(history.historyId,'scan2');assert.equal(history.comparisonId,'');
 history.selectedId='one';assert.equal(history.historyRows.length,1);history.selectedId='missing';assert(history.noHistory);
 const template=fs.readFileSync('force-app/main/default/lwc/readinessWorkspace/readinessWorkspace.html','utf8');assert(template.includes('<lightning-datatable'));assert(template.includes('<lightning-card key={snapshot.key}'));assert(template.includes('<lightning-accordion-section key={finding.key}'));assert(!template.includes('label="Saved assessment"'));
 c.mode='cases';await c.runScan();assert(c.localReport);assert.equal(navigation.length,0,'Unsaved report stays visible locally');
 savedReport=true;await c.runScan();assert.equal(navigation[0].attributes.apiName,'AI_Readiness');assert.equal(navigation[0].state.c__assessmentId,'savedScan');c.mode='all';savedReport=false;
 c.historyReport.observedAt=new Date(Date.now()-3*86400000).toISOString();assert(c.snapshotRows[0].age.includes('3 days'));assert.equal(c.snapshotRows[0].assessmentId,'one');assert.equal(c.snapshotRows[0].scopeDetails[0].value,'Not recorded');
 c.historyReport.scopeDefinition={groundingFields:['Contact.FirstName'],minimumCompleteness:80,policyApproved:true};assert.equal(c.snapshotRows[0].scopeDetails[0].value,'Contact.FirstName');
 c.openChecklist({questionId:'access',scope:'implementation',useCaseId:'two'});assert.equal(c.scope,'implementation');assert.equal(c.selectedId,'two');
 c.scope='implementation';c.selectedId='';assert(c.needsImplementation);assert.equal(c.questions.length,0);
 c.data.canEdit=true; c.draft.integrationUserId='old';c.changeCase(event('',{field:'integrationUsername'}));assert.equal(c.draft.integrationUserId,null);
 c.scope='company';c.accountability='unassigned';assert(c.questions.length===1);
 const sharedKey=c.questions[0].key;c.changeAnswer(event('privacy team',{key:sharedKey,field:'responsible'}));c.selectCase(event('one'));assert.equal(c.questions.length,0,'Company ownership draft remains shared across implementation selection');c.accountability='all';assert.equal(c.questions[0].responsible,'privacy team');c.accountability='unassigned';c.changeAnswer(event('',{key:sharedKey,field:'responsible'}));
 c.answerDrafts[c.questions[0].key]={answer:'yes'};assert(c.questions.length===0);
 c.dirty=false;c.selectedId='one';scanFailure=true;const count=events.length;await c.runScan();assert.equal(events.length,count);assert(c.error.includes('No checks'));assert(!c.error.includes('SECRET'));
 loadFailure=true;await c.load();assert(c.error.includes('could not be loaded'));assert.equal(c.data.canEdit,false);assert(c.scanDisabled);assert(!c.error.includes('SECRET'));
 console.log('Workspace scope, drafts, partial/unknown answers, role gating, history and scan checks passed.');
})().catch(error=>{console.error(error);process.exitCode=1;});
