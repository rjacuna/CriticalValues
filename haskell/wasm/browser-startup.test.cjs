// Browser regression checks; run with Playwright installed and the web bundle served.
const assert = require('node:assert/strict');
const {chromium} = require('playwright');
(async () => {
 const b = await chromium.launch(process.env.CHROME_PATH ? {executablePath: process.env.CHROME_PATH} : {});
 try {
  const context=await b.newContext(); const p=await context.newPage(); const requests=[],errors=[];
  p.on('request',r=>requests.push({url:r.url(),at:Date.now(),method:r.method()}));p.on('pageerror',e=>errors.push(String(e)));
  await p.route('**/*.wasm*',r=>r.abort());
  const start=Date.now(); await p.goto((process.env.CRITICALVALUES_URL || 'http://localhost:8000/') + '?backend=wasm');await p.locator('#results').waitFor({state:'visible'});
  console.log('CriticalValues cold examples ready',Date.now()-start,'ms');
  for(const button of await p.locator('.ex').all()) {await button.click();await p.locator('#results').waitFor({state:'visible'});assert.equal(await p.locator('#alert').isVisible(),false);}
  assert.equal(requests.filter(r=>r.url.includes('.wasm')).length,0);assert.equal(requests.filter(r=>r.url.includes('vendor/math.js')).length,0);
  await p.unroute('**/*.wasm*');
  await p.route('**/*.wasm*',async r=>{await new Promise(resolve=>setTimeout(resolve,700));await r.continue()});
  await p.locator('#finput').fill('(x+1)*(x^2+1)');await p.locator('#go').click();await p.locator('#results').waitFor({state:'visible',timeout:30000});
  const binaryRequests=requests.filter(r=>r.url.includes('.wasm')&&r.method==='GET');
  assert.equal(binaryRequests.length,2);assert.ok(Math.abs(binaryRequests[0].at-binaryRequests[1].at)<500,'WASM downloads must overlap');
  const verified=await p.evaluate(async()=>{const {pickBackend,solveWithFlint}=await import('./js/backend.js?v=fast-start-1');return solveWithFlint(await pickBackend(),'1,1,1,1')});
  assert.equal(verified.setups.length,2);assert.ok(verified.setups.every(s=>s.HIrred&&s.checks.every(c=>c.ok)));
  await p.waitForFunction(async()=>{const c=await caches.open('criticalvalues-assets-v1');return (await c.keys()).filter(r=>r.url.includes('.wasm')).length===2});
  await p.unroute('**/*.wasm*');await p.route('**/*.wasm*',r=>r.abort());requests.length=0;
  await p.reload();await p.locator('#results').waitFor({state:'visible'});await p.locator('#finput').fill('(x+1)*(x^2+1)');await p.locator('#go').click();await p.locator('#results').waitFor({state:'visible'});
  assert.equal(requests.filter(r=>r.url.includes('.wasm')).length,0);assert.equal(await p.locator('#alert').isVisible(),false);
  assert.deepEqual(errors,[]);console.log('CriticalValues: examples without WASM/parser, concurrent arbitrary solve, factor checks, persistent cache PASS');await context.close();

 } finally { await b.close(); }
})().catch(e => { console.error(e); process.exitCode = 1; });
