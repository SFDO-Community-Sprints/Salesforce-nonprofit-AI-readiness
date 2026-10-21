const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const source = fs.readFileSync('force-app/main/default/lwc/readinessOrgHealth/readinessOrgHealth.js','utf8').replace(/^import .*;$/gm,'').replace('export default class','class').replace(/@api /g,'');
let response={score:50,coverage:75,passed:2,failed:2,unknown:1,rating:'Needs attention',findings:[
 {id:'pass',status:'pass',url:'/lightning/setup/Users/home'},
 {id:'fail',status:'fail',url:'javascript:alert(1)'},
 {id:'unknown',status:'unknown',url:'https://example.com'}
],inventory:[{id:'unavailable',count:null}],categories:[{id:'privacy',score:null,coverage:0,passed:0,failed:0,unknown:3}],banner:'Critical failures block a pilot'};
const Component=vm.runInNewContext(source+'\nReadinessOrgHealth',{LightningElement:class{},scan:async()=>JSON.stringify(response),Set,Number});
(async()=>{
 const screen=new Component(); assert.equal(screen.score,'Not checked');
 await screen.runScan(); assert.equal(screen.score,'50%');assert.equal(screen.categories[0].scoreLabel,'Not checked');assert.equal(screen.categories[0].coverageLabel,'0%');assert.match(screen.banner,/Critical/);assert.equal(screen.coverage,'75%');
 assert.equal(screen.findings[0].id,'fail');assert.equal(screen.findings[0].safeUrl,undefined);assert.equal(screen.findings[1].safeUrl,undefined);assert.equal(screen.findings[2].safeUrl,'/lightning/setup/Users/home');
 assert.equal(screen.inventory[0].countLabel,'Not checked');
 response.findings.push({id:'critical',status:'fail',severity:'Critical',url:'/lightning/o/Contact/list'});
 await screen.runScan();assert.equal(screen.findings[0].id,'critical');assert.equal(screen.findings[0].safeUrl,'/lightning/o/Contact/list');
 response={error:'denied'};await screen.runScan();assert.equal(screen.result,undefined);assert.equal(screen.score,'Not checked');assert.match(screen.error,/No checks are marked as passed/);assert.equal(screen.loading,false);
 console.log('Org health UI coverage, category unknown states and safe links passed');
})().catch(error=>{console.error(error);process.exitCode=1;});
