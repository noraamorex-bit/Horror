// node comp9.mjs edit.json outDir [from] [to] — reel 10, the gameplay trailer: first-person gameplay with the game's own HUD
// (clock/act/room, inventory, OBJECTIVE, hunt banner, thoughts, sound captions, prompts, mobile buttons) + dev-voice captions.
import { chromium } from 'playwright';
import fs from 'fs';
const [,, editPath, outDir, fromArg, toArg] = process.argv;
const edit = JSON.parse(fs.readFileSync(editPath, 'utf8'));
fs.mkdirSync(outDir, { recursive: true });
const NF = edit.frames.length;
const FD = '/mnt/skills/examples/canvas-design/canvas-fonts/';
const font = (f) => 'data:font/ttf;base64,' + fs.readFileSync(FD + f).toString('base64');
const icon = 'data:image/png;base64,' + fs.readFileSync(edit.icon).toString('base64');

const html = `<!doctype html><html><head><style>
@font-face { font-family: CAP; src: url(${font('InstrumentSans-Bold.ttf')}); }
@font-face { font-family: T; src: url(${font('Outfit-Bold.ttf')}); }
* { box-sizing:border-box; }
html,body { margin:0; width:1080px; height:1920px; overflow:hidden; background:#000; }
#base { position:absolute; inset:0; width:1080px; height:1920px; object-fit:cover; }
.l { position:absolute; inset:0; pointer-events:none; }
#vig { background: radial-gradient(ellipse 90% 75% at 50% 50%, rgba(0,0,0,0) 60%, rgba(0,0,0,.45) 100%); }
#red { background: radial-gradient(ellipse 70% 60% at 50% 50%, rgba(160,0,0,0) 30%, rgba(170,0,0,.75) 100%); opacity:0; }
#flash { background:#fff; opacity:0; } #black { background:#000; opacity:0; }
#grain { mix-blend-mode: soft-light; opacity:.1; }
/* ---- the game's HUD (Helvetica-ish bold, dark glass, thin outline) */
.hud { font-family: Helvetica, Arial, sans-serif; color:#e8e4da; }
.gb { background:rgba(14,14,16,.72); border:2px solid rgba(255,255,255,.12); border-radius:14px; padding:10px 18px; }
#tl { position:absolute; left:34px; top:96px; display:flex; flex-direction:column; gap:10px; align-items:flex-start; }
#clk { font-weight:900; font-size:38px; } #act { font-weight:700; font-size:25px; color:#c8c4ba; } #room { font-weight:700; font-size:25px; color:#f5f5f5; }
#inv { font-weight:700; font-size:25px; line-height:1.2; }
#obj { position:absolute; right:34px; top:96px; width:560px; }
#obj .k { font-weight:900; font-size:22px; color:#96928a; letter-spacing:1px; } #obj .ti { font-weight:900; font-size:34px; margin-top:2px; } #obj .st { font-weight:700; font-size:27px; color:#d7d2c8; margin-top:4px; }
#obj .bar { position:absolute; left:0; top:0; bottom:0; width:6px; border-radius:14px 0 0 14px; background:#f2c94c; }
#mid { position:absolute; left:0; right:0; top:300px; display:flex; flex-direction:column; align-items:center; gap:10px; }
#pol { font-weight:900; font-size:30px; color:#f0f0f0; padding:6px 22px; }
#ban { width:760px; display:flex; gap:16px; padding:14px 18px; } #ban i { display:block; width:6px; background:#fff; flex:none; } #ban div { font-weight:900; font-size:32px; }
#toast { font-weight:900; font-size:32px; padding:10px 26px; border-color:rgba(242,201,76,.6); color:#f2e2a8; }
#bot { position:absolute; left:0; right:0; top:1300px; display:flex; flex-direction:column; align-items:center; gap:12px; }
#snd { font-weight:900; font-size:30px; color:#cdcdc3; padding:6px 18px; }
#tht { font-weight:700; font-size:40px; color:#f5f0e4; padding:14px 26px; max-width:960px; text-align:center; }
.btn { position:absolute; border-radius:50%; border:3px solid rgba(255,255,255,.35); background:rgba(0,0,0,.25); color:#ddd; font:700 22px Helvetica, Arial; display:flex; align-items:center; justify-content:center; }
.btn.on { background:rgba(255,255,255,.28); border-color:rgba(255,255,255,.8); color:#fff; }
#jump { right:60px; bottom:120px; width:150px; height:150px; }
#b1 { right:250px; bottom:150px; width:120px; height:120px; } #b2 { right:215px; bottom:300px; width:120px; height:120px; } #b3 { right:90px; bottom:310px; width:120px; height:120px; }
#breath { right:70px; bottom:150px; width:230px; height:230px; font-size:34px; } #leave { right:330px; bottom:140px; width:130px; height:130px; }
#bbar { position:absolute; right:70px; bottom:400px; width:230px; height:16px; border-radius:8px; background:rgba(255,255,255,.2); overflow:hidden; } #bbar b { display:block; height:100%; background:#e8e4da; }
#stick { position:absolute; left:90px; bottom:160px; width:230px; height:230px; border-radius:50%; border:3px solid rgba(255,255,255,.25); }
#stick i { position:absolute; left:65px; top:65px; width:100px; height:100px; border-radius:50%; background:rgba(255,255,255,.3); }
#pp { position:absolute; left:50%; top:960px; transform:translateX(-50%); display:flex; align-items:center; gap:18px; background:rgba(20,20,22,.78); border-radius:18px; padding:16px 28px 16px 18px; }
#pp .key { width:76px; height:76px; border-radius:50%; border:4px solid #fff; display:flex; align-items:center; justify-content:center; font:900 34px Helvetica; color:#fff; }
#pp .ot { font:700 26px Helvetica; color:#bbb; } #pp .at { font:900 36px Helvetica; color:#fff; }
#pp .ring { position:absolute; left:14px; top:12px; width:84px; height:84px; border-radius:50%; }
/* ---- dev captions */
#cap { position:absolute; left:50px; right:50px; top:560px; text-align:center; font-family:CAP; font-size:76px; line-height:1.12; color:#fff; -webkit-text-stroke:14px #000; paint-order:stroke fill; }
#cap o { color:#ff8a2a; }
/* ---- endings */
#endg { position:absolute; left:60px; right:60px; top:820px; display:grid; grid-template-columns:1fr 1fr; gap:22px; }
.ec { background:rgba(14,14,16,.82); border:2px solid rgba(255,255,255,.14); border-radius:18px; padding:20px 24px; opacity:0; }
.ec .n { font-family:T; font-size:44px; color:#fff; letter-spacing:1px; } .ec .s { font-family:CAP; font-size:26px; color:#9a968e; margin-top:2px; }
.ec.bad .n { color:#ff5a4a; } .ec.sec { border-color:rgba(255,138,42,.7); } .ec.sec .n { color:#ff8a2a; }
/* ---- call to action */
#cta { position:absolute; inset:0; display:none; }
#ico { position:absolute; left:50%; top:360px; width:380px; height:380px; margin-left:-190px; border-radius:76px; box-shadow:0 20px 60px rgba(0,0,0,.7); }
#ct1 { position:absolute; left:0; right:0; top:800px; text-align:center; font-family:T; font-size:82px; color:#fff; }
#ct2 { position:absolute; left:0; right:0; top:920px; text-align:center; font-family:CAP; font-size:40px; color:#d8d4cc; letter-spacing:3px; }
#ct3 { position:absolute; left:50%; top:1060px; transform:translateX(-50%); padding:30px 60px; border-radius:22px; background:#ff8a2a; color:#000; font-family:T; font-size:68px; white-space:nowrap; }
#ct4 { position:absolute; left:0; right:0; top:1290px; text-align:center; font-family:CAP; font-size:52px; color:#fff; -webkit-text-stroke:10px #000; paint-order:stroke fill; }
.o { opacity:0; }
</style></head><body>
<img id="base"/>
<div class="l" id="vig"></div><div class="l" id="red"></div>
<canvas class="l" id="grain" width="540" height="960" style="width:1080px;height:1920px"></canvas>
<div id="hud" class="hud">
  <div id="tl"><div class="gb" id="tlb"><div id="clk"></div><div id="act"></div><div id="room"></div></div><div class="gb" id="inv"></div></div>
  <div class="gb" id="obj" style="position:absolute"><div class="bar"></div><div class="k">OBJECTIVE</div><div class="ti" id="oti"></div><div class="st" id="ost"></div></div>
  <div id="mid"><div class="gb" id="pol"></div><div class="gb" id="ban"><i></i><div>He's hunting you. Hide before he sees you.</div></div><div class="gb" id="toast"></div></div>
  <div id="pp"><div class="key">E</div><div><div class="ot" id="ppo"></div><div class="at" id="ppa"></div></div></div>
  <div id="bot"><div class="gb" id="snd"></div><div class="gb" id="tht"></div></div>
  <div id="stick"><i></i></div>
  <div class="btn" id="jump"></div><div class="btn" id="b1">CROUCH</div><div class="btn" id="b2">SPRINT</div><div class="btn" id="b3">LIGHT</div>
  <div class="btn" id="breath">BREATH</div><div class="btn" id="leave">LEAVE</div><div id="bbar"><b></b></div>
</div>
<div id="cap"></div>
<div id="endg">
  <div class="ec"><div class="n">SIRENS</div><div class="s">the police make it in time</div></div>
  <div class="ec"><div class="n">LOCKED IN</div><div class="s">trap him in the basement</div></div>
  <div class="ec"><div class="n">TAILLIGHTS</div><div class="s">drive out for help</div></div>
  <div class="ec"><div class="n">NEXT DOOR</div><div class="s">reach Mrs. Okafor</div></div>
  <div class="ec"><div class="n">DAWN</div><div class="s">survive the whole night</div></div>
  <div class="ec bad"><div class="n">GONE QUIET</div><div class="s">he takes everyone</div></div>
  <div class="ec bad"><div class="n">HE GOT AWAY</div><div class="s">help comes too late</div></div>
  <div class="ec sec"><div class="n">???</div><div class="s">secret ending</div></div>
</div>
<div id="cta"><img id="ico" src="${icon}"/><div id="ct1">someone lives in our attic.</div><div id="ct2">FREE · 1-4 PLAYERS · PHONE &amp; PC</div><div id="ct3">SEARCH IT ON ROBLOX</div><div id="ct4">play it with your friends tonight 👀</div></div>
<div class="l" id="flash"></div><div class="l" id="black"></div>
<script>
const $ = (id) => document.getElementById(id);
const clamp = (x, a, b) => Math.max(a, Math.min(b, x));
const seg = (t, a, b) => clamp((t - a) / (b - a), 0, 1);
const back = (x) => { x = clamp(x, 0, 1); const c = 1.6; return 1 + (c + 1) * Math.pow(x - 1, 3) + c * Math.pow(x - 1, 2); };
function rnd(n) { const x = Math.sin(n * 127.1 + 311.7) * 43758.5453; return x - Math.floor(x); }
const g = $('grain').getContext('2d'); const gi = g.createImageData(540, 960);
const vis = (id, on) => { $(id).style.display = on ? '' : 'none'; };
const CAP = {
  hook: "I made a Roblox horror game where a stranger has been <o>living in your attic</o>",
  sleep: "you and up to <o>3 friends</o> have a sleepover",
  clues: "find clues. he's been up there for <o>19 days</o>",
  power: "then he <o>cuts the power</o>",
  hunt: "now he's <o>hunting</o> you",
  hide: "hide. <o>hold your breath.</o>",
  caught: "if he catches you...",
  friends: "your <o>friends</o> have to come save you",
  endings: "<o>7 endings</o>. most people never escape.",
};
function hud(o) {
  vis('hud', !!o); if (!o) return;
  vis('tl', !!o.clk); if (o.clk) { $('clk').textContent = o.clk; $('act').textContent = o.act; $('room').textContent = o.room; }
  vis('inv', !!o.inv); if (o.inv) $('inv').innerHTML = o.inv.join('<br>');
  vis('obj', !!o.oti); if (o.oti) { $('oti').textContent = o.oti; $('ost').textContent = o.ost || ''; }
  vis('pol', !!o.pol); if (o.pol) $('pol').textContent = o.pol;
  vis('ban', !!o.ban); vis('toast', !!o.toast); if (o.toast) { $('toast').textContent = o.toast; $('toast').style.transform = 'scale(' + (0.7 + 0.3 * back(o.toastK ?? 1)) + ')'; }
  vis('snd', !!o.snd); if (o.snd) $('snd').textContent = o.snd;
  vis('tht', !!o.tht); if (o.tht) $('tht').textContent = o.tht;
  vis('pp', !!o.pp); if (o.pp) { $('ppo').textContent = o.pp[0]; $('ppa').textContent = o.pp[1]; }
  const hiding = !!o.hiding;
  vis('stick', !hiding); vis('jump', !hiding);
  for (const b of ['b1', 'b2', 'b3']) vis(b, !hiding);
  vis('b3', !hiding && !!o.light); $('b3').className = 'btn' + (o.lightOn ? ' on' : '');
  $('b2').className = 'btn' + (o.sprint ? ' on' : '');
  vis('breath', hiding); vis('leave', hiding); vis('bbar', hiding);
  if (hiding) { $('breath').className = 'btn' + (o.holding ? ' on' : ''); $('breath').style.transform = o.holding ? 'scale(.94)' : 'none'; $('bbar').firstChild.style.width = (100 * (o.breath ?? 1)) + '%'; }
  if (o.stick) $('stick').firstChild.style.transform = 'translate(' + o.stick[0] + 'px,' + o.stick[1] + 'px)'; else $('stick').firstChild.style.transform = 'none';
}
window.setFrame = (f, fr, cuts) => {
  const t = f / 30, s = fr.seg, lt = fr.i / 30, dur = fr.n / 30;
  const b = $('base');
  let filt = 'contrast(1.08) saturate(1.05) brightness(1.1)', tf = 'none';
  if (/\\/reel[23]?\\/raw\\//.test(fr.src)) filt = 'contrast(1.12) saturate(1.0) brightness(1.4)';
  let H = null, fl = 0, bk = 0, red = 0;
  if (s === 'hook') {
    H = { clk: '11:42 PM', act: 'IV. The Guest', room: 'Hallway', inv: ['Flashlight  61%  (on)', 'House keys'], oti: 'Survive until the police arrive', ost: 'Hide when you hear him coming',
          pol: 'Police: 1:48', ban: true, light: true, lightOn: true, sprint: lt > 1.6, stick: lt > 1.6 ? [0, 50] : [0, -40] };
    if (lt > 2.2) { const sh = 18; tf = 'translate(' + (rnd(f) - .5) * sh + 'px,' + (rnd(f + 3) - .5) * sh + 'px) scale(1.04)'; }
  }
  if (s === 'sleep') {
    H = { clk: '8:52 PM', act: 'I. Friday Night', room: 'Living Room', oti: 'Order pizza', ost: 'Find the pizza menu on the fridge', stick: [-20 * Math.sin(lt), -30] };
    if (lt > 1.0) H.tht = 'Riley: ok whoever loses the next round orders the pizza';
  }
  if (s === 'clues') {
    H = { clk: '10:41 PM', act: 'III. Someone Else', room: 'Attic', inv: ['Flashlight  72%  (on)'], oti: "Find out what's in the attic", ost: 'Look around up here', light: true, lightOn: true,
          pp: ['Polaroids, pinned to a rafter', 'Read'] };
    if (lt > 1.0) { H.toast = 'Evidence 4 / 10'; H.toastK = seg(lt, 1.0, 1.25); H.pp = null; H.tht = "They're all of us. He's been watching us for weeks."; }
  }
  if (s === 'power') {
    const off = lt >= 1.53, fon = lt >= 1.93;
    H = { clk: '10:14 PM', act: 'III. Someone Else', room: 'Upstairs Hall', oti: off ? 'Get the power back on' : 'Check upstairs', ost: off ? 'Find a flashlight (search the drawers and shelves)' : 'Find out what made that noise upstairs' };
    if (off && !fon) H.tht = "The power's out. All of it. That wasn't the storm.";
    if (fon) { H.inv = ['Flashlight  100%  (on)']; H.light = true; H.lightOn = true; H.ost = 'Flip the MAIN breaker back on'; }
    if (fon) fl = 0.5 * (1 - seg(lt, 1.93, 2.1));
    if (lt > 2.3) H.snd = '[Slow, heavy breathing]';
  }
  if (s === 'hunt') {
    H = { clk: '11:58 PM', act: 'IV. The Guest', room: 'Upstairs Hall', inv: ['Flashlight  58%  (on)', 'Pepper spray (2)'], oti: 'Survive until the police arrive', ost: 'Hide when you hear him coming', pol: 'Police: 1:12', ban: true,
          light: true, lightOn: true, snd: '[Heavy footsteps, running]' };
    if (lt > 0.9) H.tht = 'Footsteps. Running. He knows where we are.';
  }
  if (s === 'hide') {
    const holding = lt > 1.0;
    H = { hiding: true, holding, breath: holding ? 1 - seg(lt, 1.0, 3.0) * 0.8 : 1, tht: holding ? null : 'I have to stay quiet in here.', snd: lt > 0.6 ? '[Footsteps, right outside]' : null,
          oti: 'Survive until the police arrive', ost: 'Hide when you hear him coming', pol: 'Police: 0:57' };
    filt = 'contrast(1.15) brightness(1.5)';
    tf = 'scale(' + (1.02 + 0.01 * Math.sin(lt * 3)) + ')';
  }
  if (s === 'caught') {
    filt = 'contrast(1.25) brightness(1.5)';
    const sh = 40 * (1 - seg(lt, 0, 0.7)); tf = 'translate(' + (rnd(f) - .5) * sh + 'px,' + (rnd(f + 3) - .5) * sh + 'px) scale(' + (1.06 + 0.08 * seg(lt, 0, 1)) + ')';
    fl = 0.9 * (1 - seg(lt, 0, 0.15)); red = 0.6 + 0.4 * seg(lt, 0, 0.6);
  }
  if (s === 'friends') {
    H = { clk: '12:06 AM', act: 'IV. The Guest', room: 'Upstairs Hall', oti: 'Free anyone he takes (boiler room, basement)', ost: 'Hold to cut the zip ties', light: true, lightOn: true };
    if (lt > 0.6) H.tht = "Riley: we're coming. stay quiet.";
  }
  if (s === 'endings' || s === 'cta') { filt = 'contrast(1.1) saturate(.7) brightness(.32) blur(6px)'; tf = 'scale(1.08)'; }
  b.style.filter = filt; b.style.transform = tf;
  hud(H);
  // dev captions
  const c = $('cap');
  if (CAP[s]) { c.style.display = ''; c.innerHTML = CAP[s]; const k = seg(lt, 0, 0.16); c.style.opacity = k > 0 ? 1 : 0; c.style.transform = 'scale(' + (0.8 + 0.2 * back(k)) + ')';
    c.style.top = ({ hook: 1060, hunt: 1080, caught: 820, sleep: 330 }[s] ?? 560) + 'px'; }
  else c.style.display = 'none';
  // endings
  const eg = $('endg'); eg.style.display = s === 'endings' ? 'grid' : 'none';
  if (s === 'endings') [...eg.children].forEach((e, j) => { const k = seg(lt, 0.35 + j * 0.18, 0.55 + j * 0.18); e.style.opacity = k; e.style.transform = 'scale(' + (0.7 + 0.3 * back(k)) + ')'; });
  // call to action
  $('cta').style.display = s === 'cta' ? 'block' : 'none';
  if (s === 'cta') {
    const pop = (id, at, x) => { const k = seg(lt, at, at + 0.25); $(id).style.opacity = k > 0 ? 1 : 0; $(id).style.transform = (x || '') + ' scale(' + (0.6 + 0.4 * back(k)) + ')'; };
    pop('ico', 0.05); pop('ct1', 0.4); pop('ct2', 0.8); pop('ct3', 1.2, 'translateX(-50%)');
    const kk = seg(lt, 1.2, 1.45); if (kk >= 1) $('ct3').style.transform = 'translateX(-50%) scale(' + (1 + 0.035 * Math.sin(lt * 7)) + ')';
    $('ct4').style.opacity = seg(lt, 2.0, 2.3);
    if (t > 28.3) bk = seg(t, 28.3, 28.7);
  }
  // cut flashes
  for (const ct of cuts.slice(1)) if (t >= ct && t < ct + 0.12 && s !== 'caught') fl = Math.max(fl, 0.4 * (1 - (t - ct) / 0.12));
  if (t < 0.1) bk = 1 - seg(t, 0, 0.1);
  $('flash').style.opacity = fl; $('black').style.opacity = bk; $('red').style.opacity = red;
  const d = gi.data;
  for (let i2 = 0; i2 < d.length; i2 += 4) { const v = (128 + (Math.random() - 0.5) * 150) | 0; d[i2] = d[i2 + 1] = d[i2 + 2] = v; d[i2 + 3] = 255; }
  g.putImageData(gi, 0, 0);
};
</script></body></html>`;

const browser = await chromium.launch({ executablePath: '/opt/pw-browsers/chromium-1194/chrome-linux/chrome' });
const page = await browser.newPage({ viewport: { width: 1080, height: 1920 } });
await page.setContent(html);
await page.evaluate(() => document.fonts.ready);
const from = +(fromArg ?? 0), to = +(toArg ?? NF - 1);
for (let f = from; f <= to; f++) {
  const fr = edit.frames[f];
  const img = fs.existsSync(fr.src) ? 'data:image/png;base64,' + fs.readFileSync(fr.src).toString('base64') : '';
  await page.evaluate(async ([img, f, fr, cuts]) => {
    const b = document.getElementById('base');
    if (img) { b.src = img; await b.decode(); }
    window.setFrame(f, fr, cuts);
  }, [img, f, fr, edit.cuts]);
  fs.writeFileSync(`${outDir}/${String(f).padStart(4, '0')}.png`, await page.screenshot({ type: 'png' }));
  if (f % 60 === 0) console.log('comp', f);
}
await browser.close();
