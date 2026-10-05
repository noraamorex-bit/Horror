// node comp10.mjs edit.json outDir [from] [to] — reel 11 (#5): the #2 format, rebuilt with more punch.
// Kinetic word-by-word captions (*red* _green_ ^yellow^), punch-in zooms on cuts, beat pulses, RGB split, glitch slices,
// red light leaks, a colour-coded case file, and a red/green/yellow end card.
import { chromium } from 'playwright';
import fs from 'fs';
const [,, editPath, outDir, fromArg, toArg] = process.argv;
const edit = JSON.parse(fs.readFileSync(editPath, 'utf8'));
fs.mkdirSync(outDir, { recursive: true });
const NF = edit.frames.length;
const FD = '/mnt/skills/examples/canvas-design/canvas-fonts/';
const font = (f) => 'data:font/ttf;base64,' + fs.readFileSync(FD + f).toString('base64');
const maskImg = 'data:image/png;base64,' + fs.readFileSync(new URL('../reel11/mask_card.png', import.meta.url)).toString('base64');
const NUM = edit.num, NEXT = edit.next;

const html = `<!doctype html><html><head><style>
@font-face { font-family: H; src: url(${font('BigShoulders-Bold.ttf')}); }
@font-face { font-family: O; src: url(${font('Outfit-Bold.ttf')}); }
@font-face { font-family: W; src: url(${font('WorkSans-Bold.ttf')}); }
@font-face { font-family: SC; src: url(${font('NothingYouCouldDo-Regular.ttf')}); }
:root { --red:#ff2d3d; --green:#35e07a; --yellow:#ffd23f; }
* { box-sizing:border-box; }
html,body { margin:0; width:1080px; height:1920px; overflow:hidden; background:#000; }
#stage { position:absolute; inset:0; overflow:hidden; }
#cam { position:absolute; inset:0; transform-origin:50% 48%; }
#cam img { position:absolute; inset:0; width:1080px; height:1920px; object-fit:cover; }
#imR, #imB { mix-blend-mode:screen; display:none; }
.strip { position:absolute; left:0; width:1080px; background-size:1080px 1920px; display:none; }
.l { position:absolute; inset:0; pointer-events:none; }
#vig { background: radial-gradient(ellipse 80% 66% at 50% 48%, rgba(0,0,0,0) 46%, rgba(0,0,0,.55) 80%, rgba(0,0,0,.92) 100%); }
#leak { mix-blend-mode:screen; opacity:0; }
#grain { mix-blend-mode: soft-light; opacity:.16; }
#flash { background:#fff; opacity:0; } #black { background:#000; opacity:0; } #redwash { background:#ff1a2a; mix-blend-mode:multiply; opacity:0; }
.o { position:absolute; opacity:0; }
.st { -webkit-text-stroke:14px #000; paint-order:stroke fill; }
.red { color:var(--red); } .green { color:var(--green); } .yellow { color:var(--yellow); }
/* hook */
.hk { left:0; right:0; text-align:center; font-family:H; white-space:nowrap; line-height:1; text-transform:uppercase; }
#hk1 { top:190px; font-size:106px; color:#fff; letter-spacing:2px; }
#hk2 { top:320px; font-size:106px; color:var(--red); letter-spacing:1px; text-shadow:0 0 40px rgba(255,45,61,.55); }
#hk3 { top:470px; left:50%; width:300px; margin-left:-150px; text-align:center; font-family:H; font-size:230px; line-height:1; color:#000; background:var(--yellow); border:10px solid #000; border-radius:26px; padding:6px 0 14px; }
#hk4 { top:1640px; left:0; right:0; text-align:center; font-family:SC; font-size:78px; color:#fff; -webkit-text-stroke:9px #000; paint-order:stroke fill; }
/* captions */
#cap { left:50px; right:50px; top:1330px; text-align:center; font-family:O; font-size:88px; line-height:1.12; color:#fff; }
#cap span { display:inline-block; margin:0 12px; -webkit-text-stroke:15px #000; paint-order:stroke fill; filter: drop-shadow(0 8px 0 rgba(0,0,0,.6)); }
#cap span.red { text-shadow:0 0 34px rgba(255,45,61,.6); }
/* case file */
#pol { left:120px; top:120px; width:330px; border:18px solid #f4f1ea; border-bottom-width:64px; box-shadow:0 22px 40px rgba(0,0,0,.65); background:#f4f1ea; }
#pol img { display:block; width:100%; background:#141414; filter:grayscale(1) contrast(1.15); }
#tape { left:200px; top:96px; width:170px; height:52px; background:rgba(255,45,61,.85); }
#stamp { left:540px; top:300px; font-family:H; font-size:84px; color:var(--red); border:9px solid var(--red); padding:4px 24px 10px; border-radius:12px; letter-spacing:4px; line-height:1; }
#rows { left:70px; right:60px; top:740px; }
.row { opacity:0; margin-bottom:34px; }
.chip { display:inline-block; font-family:W; font-size:38px; letter-spacing:3px; color:#000; padding:6px 18px; border-radius:10px; border:4px solid #000; }
.val { font-family:H; font-size:104px; line-height:1; color:#fff; margin-top:10px; white-space:nowrap; text-transform:uppercase; -webkit-text-stroke:12px #000; paint-order:stroke fill; }
.bar { display:inline-block; width:58px; height:74px; margin-right:12px; border:5px solid #000; border-radius:8px; background:rgba(255,255,255,.18); vertical-align:middle; }
.bar.on { background:var(--red); box-shadow:0 0 26px rgba(255,45,61,.8); }
/* end */
#e1 { left:0; right:0; top:700px; text-align:center; font-family:H; font-size:98px; color:#fff; white-space:nowrap; }
#e2 { left:0; right:0; top:850px; text-align:center; font-family:W; font-size:48px; letter-spacing:4px; color:var(--green); -webkit-text-stroke:9px #000; paint-order:stroke fill; }
#e3 { left:50%; top:1000px; padding:28px 60px 32px; border-radius:22px; background:var(--red); border:8px solid #000; font-family:H; font-size:92px; color:#fff; white-space:nowrap; letter-spacing:2px; box-shadow:0 0 60px rgba(255,45,61,.5); }
#e4 { left:0; right:0; top:1250px; text-align:center; font-family:SC; font-size:84px; color:var(--yellow); -webkit-text-stroke:9px #000; paint-order:stroke fill; }
</style></head><body>
<svg width="0" height="0" style="position:absolute"><filter id="onlyR"><feColorMatrix type="matrix" values="1 0 0 0 0  0 0 0 0 0  0 0 0 0 0  0 0 0 1 0"/></filter>
<filter id="onlyGB"><feColorMatrix type="matrix" values="0 0 0 0 0  0 1 0 0 0  0 0 1 0 0  0 0 0 1 0"/></filter></svg>
<div id="stage"><div id="cam"><img id="im"/><img id="imR"/><img id="imB"/></div>
  <div class="strip" id="s0"></div><div class="strip" id="s1"></div><div class="strip" id="s2"></div><div class="strip" id="s3"></div><div class="strip" id="s4"></div><div class="strip" id="s5"></div></div>
<div class="l" id="vig"></div><div class="l" id="redwash"></div><div class="l" id="leak"></div>
<canvas class="l" id="grain" width="540" height="960" style="width:1080px;height:1920px"></canvas>
<div class="o hk st" id="hk1">ROBLOX HORROR GAMES</div>
<div class="o hk st" id="hk2">YOU CAN'T PLAY ALONE</div>
<div class="o" id="hk3">#${NUM}</div>
<div class="o" id="hk4">(bring a friend. or three.)</div>
<div class="o" id="tape"></div><div class="o" id="pol"><img src="${maskImg}"/></div>
<div class="o" id="stamp">FOUND UPSTAIRS</div>
<div class="o" id="rows" style="opacity:1">
  <div class="row" id="r1"><span class="chip" style="background:var(--green)">TITLE</span><div class="val" style="font-size:84px">someone lives in our attic.</div></div>
  <div class="row" id="r2"><span class="chip" style="background:var(--red);color:#fff">FEAR LEVEL</span><div class="val" id="bars"></div></div>
  <div class="row" id="r3"><span class="chip" style="background:var(--yellow)">PLAYERS</span><div class="val">1 - 4 <span class="yellow">friends</span></div></div>
  <div class="row" id="r4"><span class="chip" style="background:var(--green)">ENDINGS</span><div class="val">7 <span class="green">+ 1 secret</span></div></div>
</div>
<div class="o" id="cap"></div>
<div class="o st" id="e1">someone lives in our attic.</div>
<div class="o" id="e2">FREE ON ROBLOX · 1-4 PLAYERS</div>
<div class="o" id="e3">SEARCH IT ON ROBLOX</div>
<div class="o" id="e4">${NEXT}</div>
<div class="l" id="flash"></div><div class="l" id="black"></div>
<script>
const $ = (id) => document.getElementById(id);
const clamp = (x, a, b) => Math.max(a, Math.min(b, x));
const seg = (t, a, b) => clamp((t - a) / (b - a), 0, 1);
const ease = (x) => 1 - Math.pow(1 - clamp(x, 0, 1), 3);
const back = (x) => { x = clamp(x, 0, 1); const c = 1.7; return 1 + (c + 1) * Math.pow(x - 1, 3) + c * Math.pow(x - 1, 2); };
function rnd(n) { const x = Math.sin(n * 127.1 + 311.7) * 43758.5453; return x - Math.floor(x); }
const g = $('grain').getContext('2d'); const gi = g.createImageData(540, 960);
const BPM = 140, BEAT = 60 / BPM;
function words(s) {                       // "*red* _green_ ^yellow^" markup -> [{w, cls}]
  const out = []; let cls = '', cur = '';
  const push = () => { if (cur) { out.push({ w: cur, cls }); cur = ''; } };
  for (const ch of s) {
    if (ch === '*' || ch === '_' || ch === '^') { push(); const c = { '*': 'red', '_': 'green', '^': 'yellow' }[ch]; cls = cls === c ? '' : c; }
    else if (ch === ' ') push(); else cur += ch;
  }
  push(); return out;
}
let lastCap = null;
function slam(el, t, at, dur, base) {
  const k = seg(t, at, at + dur);
  el.style.opacity = k > 0 ? 1 : 0;
  el.style.transform = (base || '') + ' scale(' + (2.0 - 1.0 * back(k)) + ')';
  return k;
}
window.setFrame = (f, fr, cuts, img) => {
  const t = f / 30, sec = fr.section, lt = fr.i / 30;
  for (const id of ['hk1', 'hk2', 'hk3', 'hk4', 'pol', 'tape', 'stamp', 'cap', 'e1', 'e2', 'e3', 'e4']) $(id).style.opacity = 0;
  for (const r of ['r1', 'r2', 'r3', 'r4']) $(r).style.opacity = 0;
  // ---------- grading
  const dark = /\\/reel[23]?\\/raw\\//.test(fr.src);
  let filt = dark ? 'contrast(1.18) saturate(1.05) brightness(1.5)' : 'contrast(1.14) saturate(1.12) brightness(1.15)';
  if (sec === 'card') filt = 'contrast(1.1) saturate(.8) brightness(.5)';
  if (sec === 'end') filt = 'contrast(1.1) saturate(.7) brightness(.36) blur(5px)';
  // ---------- camera: punch-in on every cut, slow push, a pulse on the beat
  const segStart = cuts.filter(c => c <= t + 1e-6).pop() || 0;
  const sinceCut = t - segStart;
  let zoom = 1.02 + 0.05 * fr.k + 0.12 * (1 - ease(seg(sinceCut, 0, 0.32)));
  const silent = t > cuts[8] + 1.85 && t < cuts[10];
  if (t > cuts[1] && !silent) { const bp = ((t - cuts[1]) / BEAT) % 1; zoom += 0.014 * Math.max(0, 1 - bp * 5); }
  if (sec === 'end') zoom = 1.1;
  let shx = 0, shy = 0, sh = 0;
  for (const c of cuts) if (t >= c && t < c + 0.14) sh = Math.max(sh, 20 * (1 - (t - c) / 0.14));
  // ---------- scares, hook reveal: RGB split + glitch slices + red wash
  const s1 = cuts[8] + 2.15, s2 = cuts[9], rev = 1.93;
  let split = 0, glitch = 0, red = 0, fl = 0;
  const hit = (at, d, amt) => { if (t >= at && t < at + d) { const k = 1 - (t - at) / d; split = Math.max(split, amt * k); glitch = Math.max(glitch, k); fl = Math.max(fl, 0.85 * Math.max(0, 1 - (t - at) / 0.12)); sh = Math.max(sh, 34 * k); } };
  hit(rev, 0.35, 26); hit(s1, 0.4, 34); hit(s2, 0.5, 40);
  if (t >= s2 && t < cuts[10]) red = 0.35 * (1 - seg(t, s2, cuts[10]));
  if (sec === 'hook') { for (const a of [0.15, 0.55, 1.0]) if (t >= a && t < a + 0.12) { split = Math.max(split, 14); sh = Math.max(sh, 16); } }
  shx = (rnd(f) - .5) * sh; shy = (rnd(f + 9) - .5) * sh;
  $('cam').style.transform = 'translate(' + shx + 'px,' + shy + 'px) scale(' + zoom + ')';
  for (const id of ['im', 'imR', 'imB']) $(id).style.filter = filt;
  if (split > 0.5) {
    $('im').style.display = 'none'; $('imR').style.display = 'block'; $('imB').style.display = 'block';
    $('imR').style.filter = filt + ' url(#onlyR)'; $('imB').style.filter = filt + ' url(#onlyGB)';
    $('imR').style.transform = 'translateX(' + (-split) + 'px)'; $('imB').style.transform = 'translateX(' + split + 'px)';
  } else { $('im').style.display = 'block'; $('imR').style.display = 'none'; $('imB').style.display = 'none'; }
  for (let j = 0; j < 6; j++) {
    const s = $('s' + j);
    if (glitch > 0.15 && img && rnd(f * 7 + j) < 0.75) {
      const y = Math.floor(rnd(f * 3 + j * 11) * 1800), h = 30 + Math.floor(rnd(f * 5 + j) * 140), dx = (rnd(f * 13 + j) - .5) * 160 * glitch;
      s.style.display = 'block'; s.style.top = y + 'px'; s.style.height = h + 'px'; s.style.backgroundImage = 'url(' + img + ')';
      s.style.backgroundPosition = dx + 'px ' + (-y) + 'px'; s.style.filter = filt + (j % 2 ? ' hue-rotate(90deg)' : '');
    } else s.style.display = 'none';
  }
  $('redwash').style.opacity = red;
  // ---------- light leak on cuts: a red-orange burn sweeping across
  let lk = 0, lx = 0;
  for (const c of cuts.slice(1)) if (t >= c - 0.05 && t < c + 0.45) { lk = Math.max(lk, Math.sin(Math.PI * seg(t, c - 0.05, c + 0.45))); lx = seg(t, c - 0.05, c + 0.45); }
  const leak = $('leak'); leak.style.opacity = 0.75 * lk;
  leak.style.background = 'radial-gradient(ellipse 60% 45% at ' + (-20 + 140 * lx) + '% 40%, rgba(255,60,30,.9), rgba(255,140,40,.35) 45%, rgba(0,0,0,0) 75%)';
  // ---------- hook
  if (sec === 'hook') {
    slam($('hk1'), lt, 0.15, 0.16); slam($('hk2'), lt, 0.55, 0.16);
    slam($('hk3'), lt, 1.0, 0.18, 'rotate(-6deg)');
    const k4 = seg(lt, 2.4, 2.75); $('hk4').style.opacity = k4; $('hk4').style.transform = 'rotate(-3deg) translateY(' + (20 * (1 - k4)) + 'px)';
  }
  // ---------- case file
  if (sec === 'card') {
    const kp = seg(lt, 0, 0.3);
    $('pol').style.opacity = kp; $('pol').style.transform = 'rotate(-5deg) scale(' + (0.8 + 0.2 * back(kp)) + ')';
    $('tape').style.opacity = kp; $('tape').style.transform = 'rotate(8deg)';
    const ks = seg(lt, 3.05, 3.2); $('stamp').style.opacity = ks > 0 ? 0.95 : 0; $('stamp').style.transform = 'rotate(-10deg) scale(' + (2.4 - 1.4 * ease(ks)) + ')';
    [['r1', 0.35], ['r2', 1.0], ['r3', 1.85], ['r4', 2.45]].forEach(([id, at]) => {
      const k = seg(lt, at, at + 0.22); $(id).style.opacity = k > 0 ? 1 : 0; $(id).style.transform = 'translateX(' + (-160 * (1 - back(k))) + 'px)';
    });
    const lit = Math.round(10 * seg(lt, 1.15, 1.7));
    let h = ''; for (let b = 0; b < 10; b++) h += '<span class="bar' + (b < lit ? ' on' : '') + '"></span>';
    $('bars').innerHTML = h + '<span class="red" style="font-size:82px">' + (lit === 10 ? ' 10/10' : '') + '</span>';
  }
  // ---------- kinetic captions
  if (sec === 'clip' && fr.cap) {
    const c = $('cap');
    if (lastCap !== fr.cap) { c.innerHTML = words(fr.cap).map(w => '<span class="' + w.cls + '">' + w.w + '</span>').join(' '); lastCap = fr.cap; }
    c.style.opacity = 1;
    [...c.children].forEach((sp, j) => {
      const at = 0.06 + j * 0.085; const k = seg(lt, at, at + 0.14);
      sp.style.opacity = k > 0 ? 1 : 0;
      let tf = 'scale(' + (1.7 - 0.7 * back(k)) + ') rotate(' + ((1 - k) * (j % 2 ? 6 : -6)) + 'deg)';
      if (sp.className === 'red' && k >= 1) tf += ' translate(' + (rnd(f + j) - .5) * 5 + 'px,' + (rnd(f + j + 3) - .5) * 5 + 'px)';
      sp.style.transform = tf;
    });
  }
  // ---------- end card
  if (sec === 'end') {
    const kp = seg(lt, 0, 0.3);
    $('pol').style.opacity = kp; $('pol').style.transform = 'rotate(-5deg) scale(' + (0.8 + 0.2 * back(kp)) + ')'; $('pol').style.left = '375px'; $('pol').style.top = '120px';
    $('tape').style.opacity = kp; $('tape').style.left = '455px'; $('tape').style.top = '96px';
    slam($('e1'), lt, 0.3, 0.16); const k2 = seg(lt, 0.8, 1.0); $('e2').style.opacity = k2;
    const k3 = slam($('e3'), lt, 1.3, 0.18, 'translateX(-50%)'); if (k3 >= 1) $('e3').style.transform = 'translateX(-50%) scale(' + (1 + 0.035 * Math.sin(lt * 7)) + ')';
    const k4 = seg(lt, 2.2, 2.6); $('e4').style.opacity = k4; $('e4').style.transform = 'rotate(-3deg)';
  } else { $('pol').style.left = '120px'; $('pol').style.top = '120px'; $('tape').style.left = '200px'; $('tape').style.top = '96px'; }
  // ---------- flashes and black
  for (const c of cuts.slice(1, 9)) if (t >= c && t < c + 0.08) fl = Math.max(fl, 0.3 * (1 - (t - c) / 0.08));
  $('flash').style.opacity = fl;
  let bk = 0;
  if (t < 0.12) bk = 1 - seg(t, 0, 0.12);
  if (silent && t < s1) bk = 0.25 * seg(t, cuts[8] + 1.85, s1 - 0.05);
  if (t > 29.1) bk = seg(t, 29.1, 29.5);
  $('black').style.opacity = bk;
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
    for (const id of ['im', 'imR', 'imB']) { const b = document.getElementById(id); if (img) { b.src = img; } }
    if (img) await Promise.all(['im', 'imR', 'imB'].map(id => document.getElementById(id).decode().catch(() => {})));
    window.setFrame(f, fr, cuts, img);
  }, [img, f, fr, edit.cuts]);
  fs.writeFileSync(`${outDir}/${String(f).padStart(4, '0')}.png`, await page.screenshot({ type: 'png' }));
  if (f % 60 === 0) console.log('comp', f);
}
await browser.close();
