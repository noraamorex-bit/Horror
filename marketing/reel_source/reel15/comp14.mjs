// node comp14.mjs edit.json outDir [from] [to] — reel 15: "WOULD YOU SURVIVE THIS ROBLOX HORROR GAME?", a quiz.
// Game-show look in electric blue: a ROUND n/4 badge, the situation, A/B choice buttons with a countdown bar,
// then the reveal (right turns green with a tick, wrong turns red with a cross and shakes) and a kinetic
// explanation. Punch-ins on cuts, beat pulse, RGB split and glitch slices on the scare, blue light leaks, grain.
import { chromium } from 'playwright';
import fs from 'fs';
const [,, editPath, outDir, fromArg, toArg] = process.argv;
const edit = JSON.parse(fs.readFileSync(editPath, 'utf8'));
fs.mkdirSync(outDir, { recursive: true });
const NF = edit.frames.length;
const FD = '/mnt/skills/examples/canvas-design/canvas-fonts/';
const font = (f) => 'data:font/ttf;base64,' + fs.readFileSync(FD + f).toString('base64');
const maskImg = 'data:image/png;base64,' + fs.readFileSync(new URL('../reel11/mask_card.png', import.meta.url)).toString('base64');

const html = `<!doctype html><html><head><style>
@font-face { font-family: H; src: url(${font('BigShoulders-Bold.ttf')}); }
@font-face { font-family: O; src: url(${font('Outfit-Bold.ttf')}); }
@font-face { font-family: W; src: url(${font('WorkSans-Bold.ttf')}); }
@font-face { font-family: SC; src: url(${font('NothingYouCouldDo-Regular.ttf')}); }
:root { --blue:#2f6bff; --sky:#7fb0ff; --ok:#2bff88; --bad:#ff3355; }
* { box-sizing:border-box; }
html,body { margin:0; width:1080px; height:1920px; overflow:hidden; background:#000; }
#stage { position:absolute; inset:0; overflow:hidden; }
#cam { position:absolute; inset:0; transform-origin:50% 48%; }
#cam img { position:absolute; inset:0; width:1080px; height:1920px; object-fit:cover; }
#imR, #imB { mix-blend-mode:screen; display:none; }
.strip { position:absolute; left:0; width:1080px; background-size:1080px 1920px; display:none; }
.l { position:absolute; inset:0; pointer-events:none; }
#vig { background: radial-gradient(ellipse 80% 66% at 50% 48%, rgba(0,0,0,0) 46%, rgba(0,0,0,.55) 80%, rgba(0,0,0,.92) 100%); }
#tint { background: linear-gradient(180deg, rgba(20,50,160,.35), rgba(0,0,0,0) 30%, rgba(0,0,0,0) 62%, rgba(10,30,120,.55)); }
#leak { mix-blend-mode:screen; opacity:0; }
#grain { mix-blend-mode: soft-light; opacity:.16; }
#flash { background:#fff; opacity:0; } #black { background:#000; opacity:0; } #redwash { background:#ff1030; mix-blend-mode:multiply; opacity:0; }
.o { position:absolute; opacity:0; }
.st { -webkit-text-stroke:14px #000; paint-order:stroke fill; }
.b { color:var(--blue); } .g { color:var(--ok); } .r { color:var(--bad); }
/* hook */
.hk { left:0; right:0; text-align:center; font-family:H; white-space:nowrap; line-height:1; text-transform:uppercase; }
#hk1 { top:190px; font-size:118px; color:#fff; letter-spacing:2px; }
#hk2 { top:330px; font-size:88px; color:var(--sky); letter-spacing:1px; text-shadow:0 0 40px rgba(47,107,255,.8); }
#hk3 { top:500px; left:50%; font-family:H; font-size:84px; color:#fff; background:var(--blue); border:9px solid #000; border-radius:22px; padding:10px 40px 16px; white-space:nowrap; letter-spacing:3px; box-shadow:0 0 60px rgba(47,107,255,.7); }
#hk4 { top:1700px; left:0; right:0; text-align:center; font-family:SC; font-size:74px; color:#fff; -webkit-text-stroke:9px #000; paint-order:stroke fill; white-space:nowrap; }
/* quiz */
#round { left:50%; top:150px; font-family:W; font-size:44px; letter-spacing:6px; color:#fff; background:#000; border:6px solid var(--blue); border-radius:999px; padding:10px 34px; white-space:nowrap; box-shadow:0 0 34px rgba(47,107,255,.8); }
#q { left:50px; right:50px; top:250px; text-align:center; font-family:O; font-size:84px; line-height:1.1; color:#fff; }
#q span { display:inline-block; margin:0 10px; -webkit-text-stroke:14px #000; paint-order:stroke fill; }
.opt { left:70px; right:70px; height:150px; border:9px solid #000; border-radius:28px; background:rgba(10,20,60,.82); display:flex; align-items:center; gap:30px; padding:0 34px; box-shadow:0 12px 0 rgba(0,0,0,.55); }
.opt .k { width:96px; height:96px; border-radius:20px; background:var(--blue); border:6px solid #000; font-family:H; font-size:80px; line-height:84px; text-align:center; color:#fff; flex:none; }
.opt .t { font-family:H; font-size:86px; color:#fff; white-space:nowrap; letter-spacing:2px; -webkit-text-stroke:10px #000; paint-order:stroke fill; flex:1; }
.opt .m { font-family:H; font-size:110px; line-height:1; width:110px; text-align:center; flex:none; }
#oa { top:1180px; } #ob { top:1370px; }
.opt.ok { background:var(--ok); box-shadow:0 0 60px rgba(43,255,136,.8), 0 12px 0 rgba(0,0,0,.55); } .opt.ok .k { background:#000; color:var(--ok); } .opt.ok .m { color:#000; }
.opt.bad { background:var(--bad); box-shadow:0 0 50px rgba(255,51,85,.7), 0 12px 0 rgba(0,0,0,.55); } .opt.bad .k { background:#000; color:var(--bad); } .opt.bad .m { color:#000; }
#timer { left:120px; right:120px; top:1570px; height:26px; border:6px solid #000; border-radius:999px; background:rgba(0,0,0,.6); overflow:hidden; }
#timer i { position:absolute; left:0; top:0; bottom:0; background:linear-gradient(90deg,var(--blue),var(--sky)); }
#num { left:0; right:0; top:1610px; text-align:center; font-family:H; font-size:110px; color:#fff; -webkit-text-stroke:12px #000; paint-order:stroke fill; }
#why { left:50px; right:50px; top:1590px; text-align:center; font-family:O; font-size:72px; line-height:1.12; color:#fff; }
#why span { display:inline-block; margin:0 10px; -webkit-text-stroke:13px #000; paint-order:stroke fill; filter: drop-shadow(0 8px 0 rgba(0,0,0,.6)); }
/* end */
#pol { left:375px; top:120px; width:330px; border:18px solid #f4f1ea; border-bottom-width:64px; box-shadow:0 22px 40px rgba(0,0,0,.65); background:#f4f1ea; }
#pol img { display:block; width:100%; background:#141414; filter:grayscale(1) contrast(1.15); }
#tape { left:455px; top:96px; width:170px; height:52px; background:rgba(200,215,255,.8); }
#e0 { left:0; right:0; top:610px; text-align:center; font-family:W; font-size:46px; letter-spacing:5px; color:var(--sky); -webkit-text-stroke:8px #000; paint-order:stroke fill; }
#e1 { left:0; right:0; top:690px; text-align:center; font-family:H; font-size:98px; color:#fff; white-space:nowrap; }
#e2 { left:0; right:0; top:840px; text-align:center; font-family:W; font-size:48px; letter-spacing:4px; color:#fff; -webkit-text-stroke:9px #000; paint-order:stroke fill; }
#e3 { left:50%; top:990px; padding:28px 60px 32px; border-radius:22px; background:var(--blue); border:8px solid #000; font-family:H; font-size:92px; color:#fff; white-space:nowrap; letter-spacing:2px; box-shadow:0 0 70px rgba(47,107,255,.75); }
#e4 { left:0; right:0; top:1240px; text-align:center; font-family:SC; font-size:74px; color:#fff; -webkit-text-stroke:9px #000; paint-order:stroke fill; white-space:nowrap; }
</style></head><body>
<svg width="0" height="0" style="position:absolute"><filter id="onlyR"><feColorMatrix type="matrix" values="1 0 0 0 0  0 0 0 0 0  0 0 0 0 0  0 0 0 1 0"/></filter>
<filter id="onlyGB"><feColorMatrix type="matrix" values="0 0 0 0 0  0 1 0 0 0  0 0 1 0 0  0 0 0 1 0"/></filter></svg>
<div id="stage"><div id="cam"><img id="im"/><img id="imR"/><img id="imB"/></div>
  <div class="strip" id="s0"></div><div class="strip" id="s1"></div><div class="strip" id="s2"></div><div class="strip" id="s3"></div><div class="strip" id="s4"></div><div class="strip" id="s5"></div></div>
<div class="l" id="vig"></div><div class="l" id="tint"></div><div class="l" id="redwash"></div><div class="l" id="leak"></div>
<canvas class="l" id="grain" width="540" height="960" style="width:1080px;height:1920px"></canvas>
<div class="o hk st" id="hk1">WOULD YOU SURVIVE</div>
<div class="o hk st" id="hk2">THIS ROBLOX HORROR GAME?</div>
<div class="o" id="hk3">4 QUESTIONS</div>
<div class="o" id="hk4">(be honest in the comments)</div>
<div class="o" id="round"></div>
<div class="o" id="q"></div>
<div class="o opt" id="oa"><div class="k">A</div><div class="t"></div><div class="m"></div></div>
<div class="o opt" id="ob"><div class="k">B</div><div class="t"></div><div class="m"></div></div>
<div class="o" id="timer"><i></i></div>
<div class="o" id="num"></div>
<div class="o" id="why"></div>
<div class="o" id="tape"></div><div class="o" id="pol"><img src="${maskImg}"/></div>
<div class="o" id="e0">THE GAME IS CALLED</div>
<div class="o st" id="e1">someone lives in our attic.</div>
<div class="o" id="e2">FREE ON ROBLOX · 1-4 PLAYERS</div>
<div class="o" id="e3">SEARCH IT ON ROBLOX</div>
<div class="o" id="e4">how many did you get? 👇</div>
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
const REVEAL = 3.0;                       // seconds into a round: the answer
function words(s) {                       // "*blue* _green_ ^red^" markup -> [{w, cls}]
  const out = []; let cls = '', cur = '';
  const push = () => { if (cur) { out.push({ w: cur, cls }); cur = ''; } };
  for (const ch of s) {
    if (ch === '*' || ch === '_' || ch === '^') { push(); const c = { '*': 'b', '_': 'g', '^': 'r' }[ch]; cls = cls === c ? '' : c; }
    else if (ch === ' ') push(); else cur += ch;
  }
  push(); return out;
}
function slam(el, t, at, dur, base) {
  const k = seg(t, at, at + dur);
  el.style.opacity = k > 0 ? 1 : 0;
  el.style.transform = (base || '') + ' scale(' + (2.0 - 1.0 * back(k)) + ')';
  return k;
}
function kinetic(el, text, key, lt, start, f) {
  if (el.dataset.key !== key) { el.innerHTML = words(text).map(w => '<span class="' + w.cls + '">' + w.w + '</span>').join(' '); el.dataset.key = key; }
  el.style.opacity = 1;
  [...el.children].forEach((sp, j) => {
    const at = start + j * 0.075; const k = seg(lt, at, at + 0.13);
    sp.style.opacity = k > 0 ? 1 : 0;
    let tf = 'scale(' + (1.7 - 0.7 * back(k)) + ') rotate(' + ((1 - k) * (j % 2 ? 6 : -6)) + 'deg)';
    if (sp.className === 'r' && k >= 1) tf += ' translate(' + (rnd(f + j) - .5) * 6 + 'px,' + (rnd(f + j + 3) - .5) * 6 + 'px)';
    sp.style.transform = tf;
  });
}
window.setFrame = (f, fr, E, img) => {
  const cuts = E.cuts, t = f / 30, sec = fr.section, lt = fr.i / 30, d = fr.d || {};
  for (const id of ['hk1', 'hk2', 'hk3', 'hk4', 'round', 'q', 'oa', 'ob', 'timer', 'num', 'why', 'pol', 'tape', 'e0', 'e1', 'e2', 'e3', 'e4']) $(id).style.opacity = 0;
  // ---------- grading
  const dark = /\\/reel[23]?\\/raw\\//.test(fr.src);
  let filt = dark ? 'contrast(1.18) saturate(1.05) brightness(1.55)' : 'contrast(1.14) saturate(1.1) brightness(1.15)';
  if (sec === 'quiz') filt += ' hue-rotate(-8deg)';
  if (sec === 'end') filt = 'contrast(1.1) saturate(.7) brightness(.36) blur(5px)';
  $('tint').style.opacity = sec === 'end' ? 0.5 : 1;
  // ---------- camera: punch-in on every cut, slow push, a pulse on the beat
  const segStart = cuts.filter(c => c <= t + 1e-6).pop() || 0;
  const sinceCut = t - segStart;
  let zoom = 1.02 + 0.05 * fr.k + 0.12 * (1 - ease(seg(sinceCut, 0, 0.32)));
  const silent = t > E.silentFrom && t < E.scare;
  if (t > cuts[1] && !silent && sec !== 'end') { const bp = ((t - cuts[1]) / BEAT) % 1; zoom += 0.012 * Math.max(0, 1 - bp * 5); }
  if (sec === 'quiz' && lt >= REVEAL && lt < REVEAL + 0.25) zoom += 0.06 * (1 - (lt - REVEAL) / 0.25);
  if (sec === 'end') zoom = 1.1;
  let sh = 0;
  for (const c of cuts) if (t >= c && t < c + 0.14) sh = Math.max(sh, 20 * (1 - (t - c) / 0.14));
  if (sec === 'quiz' && lt >= REVEAL && lt < REVEAL + 0.2) sh = Math.max(sh, 22 * (1 - (lt - REVEAL) / 0.2));
  // ---------- the scare + hook glitches
  let split = 0, glitch = 0, red = 0, fl = 0;
  const hit = (at, dd, amt) => { if (t >= at && t < at + dd) { const k = 1 - (t - at) / dd; split = Math.max(split, amt * k); glitch = Math.max(glitch, k); fl = Math.max(fl, 0.85 * Math.max(0, 1 - (t - at) / 0.12)); sh = Math.max(sh, 34 * k); } };
  hit(E.scare, 0.6, 40);
  if (t >= E.scare && t < E.end) red = 0.4 * (1 - seg(t, E.scare, E.end));
  if (sec === 'hook') { for (const a of [0.15, 0.55, 1.0]) if (t >= a && t < a + 0.12) { split = Math.max(split, 14); sh = Math.max(sh, 16); } }
  const shx = (rnd(f) - .5) * sh, shy = (rnd(f + 9) - .5) * sh;
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
  // ---------- light leak on cuts: a blue-white burn sweeping across
  let lk = 0, lx = 0;
  for (const c of cuts.slice(1)) if (t >= c - 0.05 && t < c + 0.45) { lk = Math.max(lk, Math.sin(Math.PI * seg(t, c - 0.05, c + 0.45))); lx = seg(t, c - 0.05, c + 0.45); }
  const leak = $('leak'); leak.style.opacity = 0.7 * lk;
  leak.style.background = 'radial-gradient(ellipse 60% 45% at ' + (-20 + 140 * lx) + '% 40%, rgba(70,130,255,.9), rgba(160,200,255,.35) 45%, rgba(0,0,0,0) 75%)';
  // ---------- hook
  if (sec === 'hook') {
    slam($('hk1'), lt, 0.15, 0.16); slam($('hk2'), lt, 0.55, 0.16);
    const k3 = slam($('hk3'), lt, 1.0, 0.18, 'translateX(-50%) rotate(-4deg)');
    if (k3 >= 1) $('hk3').style.transform = 'translateX(-50%) rotate(-4deg) scale(' + (1 + 0.03 * Math.sin(lt * 8)) + ')';
    const k4 = seg(lt, 1.9, 2.25); $('hk4').style.opacity = k4; $('hk4').style.transform = 'rotate(-3deg) translateY(' + (20 * (1 - k4)) + 'px)';
  }
  // ---------- quiz rounds
  if (sec === 'quiz') {
    const kr = seg(lt, 0, 0.2); $('round').style.opacity = kr; $('round').style.transform = 'translateX(-50%) translateY(' + (-40 * (1 - ease(kr))) + 'px)';
    $('round').textContent = 'ROUND ' + d.n + ' / 4';
    kinetic($('q'), d.q, 'q' + d.n, lt, 0.12, f);
    const opts = [['oa', 'a', 0.55], ['ob', 'b', 0.72]];
    for (const [id, key, at] of opts) {
      const el = $(id); el.querySelector('.t').textContent = d[key];
      const k = seg(lt, at, at + 0.22); el.style.opacity = k > 0 ? 1 : 0;
      let tf = 'translateX(' + ((key === 'a' ? -1 : 1) * 1100 * (1 - back(k))) + 'px)';
      el.classList.remove('ok', 'bad'); el.querySelector('.m').textContent = '';
      if (lt >= REVEAL) {
        const right = d.ok === key;
        el.classList.add(right ? 'ok' : 'bad');
        el.querySelector('.m').textContent = right ? '✓' : '✗';
        const kk = seg(lt, REVEAL, REVEAL + 0.3);
        if (right) tf += ' scale(' + (1 + 0.12 * Math.sin(Math.PI * kk)) + ')';
        else tf += ' translateX(' + (Math.sin(lt * 60) * 18 * (1 - kk)) + 'px) rotate(' + ((key === 'a' ? -1 : 1) * 2 * kk) + 'deg)';
        if (!right && d.ok) el.style.opacity = 1 - 0.35 * kk;
      }
      el.style.transform = tf;
    }
    if (lt < REVEAL) {
      const kt = seg(lt, 0.9, REVEAL);
      $('timer').style.opacity = lt > 0.85 ? 1 : 0;
      $('timer').querySelector('i').style.width = (100 * (1 - kt)) + '%';
      const n = Math.ceil(3 * (1 - kt));
      if (lt > 0.9 && n > 0) { const kn = ((lt - 0.9) / ((REVEAL - 0.9) / 3)) % 1; $('num').style.opacity = 1; $('num').textContent = n; $('num').style.transform = 'scale(' + (1.5 - 0.5 * ease(kn * 3)) + ')'; }
    } else {
      kinetic($('why'), d.why, 'w' + d.n, lt, REVEAL + 0.15, f);
    }
  }
  // ---------- end card
  if (sec === 'end') {
    const kp = seg(lt, 0, 0.3);
    $('pol').style.opacity = kp; $('pol').style.transform = 'rotate(-5deg) scale(' + (0.8 + 0.2 * back(kp)) + ')';
    $('tape').style.opacity = kp; $('tape').style.transform = 'rotate(8deg)';
    $('e0').style.opacity = seg(lt, 0.2, 0.4);
    slam($('e1'), lt, 0.3, 0.16); const k2 = seg(lt, 0.8, 1.0); $('e2').style.opacity = k2;
    const k3 = slam($('e3'), lt, 1.3, 0.18, 'translateX(-50%)'); if (k3 >= 1) $('e3').style.transform = 'translateX(-50%) scale(' + (1 + 0.035 * Math.sin(lt * 7)) + ')';
    const k4 = seg(lt, 2.0, 2.4); $('e4').style.opacity = k4; $('e4').style.transform = 'rotate(-3deg)';
  }
  // ---------- flashes and black
  for (const c of cuts.slice(1, 5)) if (t >= c && t < c + 0.08) fl = Math.max(fl, 0.3 * (1 - (t - c) / 0.08));
  if (sec === 'quiz' && lt >= REVEAL && lt < REVEAL + 0.08) fl = Math.max(fl, 0.35 * (1 - (lt - REVEAL) / 0.08));
  $('flash').style.opacity = fl;
  let bk = 0;
  if (t < 0.12) bk = 1 - seg(t, 0, 0.12);
  if (silent) bk = 0.35 * seg(t, E.silentFrom, E.scare - 0.05);
  if (t > E.dur - 0.4) bk = seg(t, E.dur - 0.4, E.dur);
  $('black').style.opacity = bk;
  const dd = gi.data;
  for (let i2 = 0; i2 < dd.length; i2 += 4) { const v = (128 + (Math.random() - 0.5) * 150) | 0; dd[i2] = dd[i2 + 1] = dd[i2 + 2] = v; dd[i2 + 3] = 255; }
  g.putImageData(gi, 0, 0);
};
</script></body></html>`;

const browser = await chromium.launch({ executablePath: '/opt/pw-browsers/chromium-1194/chrome-linux/chrome' });
const page = await browser.newPage({ viewport: { width: 1080, height: 1920 } });
await page.setContent(html);
await page.evaluate(() => document.fonts.ready);
const from = +(fromArg ?? 0), to = +(toArg ?? NF - 1);
const E = { cuts: edit.cuts, scare: edit.scare, silentFrom: edit.silentFrom, end: edit.end, dur: edit.dur };
for (let f = from; f <= to; f++) {
  const fr = edit.frames[f];
  const img = fs.existsSync(fr.src) ? 'data:image/png;base64,' + fs.readFileSync(fr.src).toString('base64') : '';
  await page.evaluate(async ([img, f, fr, E]) => {
    for (const id of ['im', 'imR', 'imB']) { const b = document.getElementById(id); if (img) { b.src = img; } }
    if (img) await Promise.all(['im', 'imR', 'imB'].map(id => document.getElementById(id).decode().catch(() => {})));
    window.setFrame(f, fr, E, img);
  }, [img, f, fr, E]);
  fs.writeFileSync(`${outDir}/${String(f).padStart(4, '0')}.png`, await page.screenshot({ type: 'png' }));
  if (f % 60 === 0) console.log('comp', f);
}
await browser.close();
