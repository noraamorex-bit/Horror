// node comp7.mjs edit.json outDir [from] [to] — reel 6, "CAN YOU SPOT HIM?" (3 rounds, a scare, a comment-bait end card)
import { chromium } from 'playwright';
import fs from 'fs';
const [,, editPath, outDir, fromArg, toArg] = process.argv;
const edit = JSON.parse(fs.readFileSync(editPath, 'utf8'));
fs.mkdirSync(outDir, { recursive: true });
const NF = edit.frames.length;
const FD = '/mnt/skills/examples/canvas-design/canvas-fonts/';
const font = (f) => 'data:font/ttf;base64,' + fs.readFileSync(FD + f).toString('base64');

const html = `<!doctype html><html><head><style>
@font-face { font-family: D; src: url(${font('Boldonse-Regular.ttf')}); }
@font-face { font-family: W; src: url(${font('WorkSans-Bold.ttf')}); }
@font-face { font-family: SC; src: url(${font('NothingYouCouldDo-Regular.ttf')}); }
:root { --y:#ffd60a; --red:#ff2b2b; --easy:#3ddc84; --hard:#ff9f1c; }
html,body { margin:0; width:1080px; height:1920px; overflow:hidden; background:#000; }
#base { position:absolute; inset:0; width:1080px; height:1920px; object-fit:cover; }
.l { position:absolute; inset:0; }
#vig { background: radial-gradient(ellipse 85% 70% at 50% 50%, rgba(0,0,0,0) 55%, rgba(0,0,0,.45) 85%, rgba(0,0,0,.8) 100%); }
#grain { mix-blend-mode: soft-light; opacity:.12; }
#flash { background:#fff; opacity:0; }
#black { background:#000; opacity:0; }
.o { position:absolute; opacity:0; }
.st { -webkit-text-stroke: 14px #000; paint-order: stroke fill; }
.c { left:0; right:0; text-align:center; white-space:nowrap; }
#hook { top:80px; font-family:D; color:#fff; line-height:1.25; transform-origin:50% 0; }
#hook .a { font-size:92px; } #hook .b { font-size:112px; color:var(--y); }
#tag { top:1290px; font-family:W; font-size:50px; }
#tag .p { display:inline-block; background:var(--y); color:#000; padding:10px 26px; border-radius:14px; border:5px solid #000; margin-right:14px; }
#tag .lv { display:inline-block; color:#000; padding:10px 26px; border-radius:14px; border:5px solid #000; }
#timer { left:50%; top:1440px; width:220px; height:220px; margin-left:-110px; }
#timer svg { position:absolute; inset:0; }
#tnum { position:absolute; inset:0; text-align:center; line-height:220px; font-family:D; font-size:96px; color:#fff; }
#hint { top:1700px; font-family:SC; font-size:66px; color:#fff; -webkit-text-stroke: 9px #000; paint-order: stroke fill; }
#ring { left:0; top:0; width:1080px; height:1920px; }
#say { top:1450px; font-family:W; font-size:78px; color:#fff; white-space:normal; padding:0 50px; line-height:1.15; }
#score { top:560px; font-family:D; font-size:64px; color:var(--easy); }
#q1 { top:330px; font-family:D; font-size:78px; color:#fff; line-height:1.3; }
#q1 .y { color:var(--y); }
#chips { top:600px; font-family:D; font-size:56px; }
#chips span { display:inline-block; margin:0 10px; padding:18px 22px; border-radius:18px; border:6px solid #000; background:#fff; color:#000; }
#cmt { top:780px; font-family:W; font-size:58px; color:#fff; }
#game { top:1010px; font-family:W; font-size:46px; color:#fff; }
#gname { top:1080px; font-family:D; font-size:62px; color:#fff; }
#pill { left:50%; top:1230px; transform:translateX(-50%); font-family:W; font-size:62px; background:var(--y); color:#000; border:6px solid #000; border-radius:18px; padding:20px 46px; white-space:nowrap; }
#send { top:1420px; font-family:SC; font-size:66px; white-space:normal; padding:0 60px; line-height:1.2; color:#fff; -webkit-text-stroke: 9px #000; paint-order: stroke fill; }
</style></head><body>
<img id="base"/>
<div class="l" id="vig"></div>
<canvas class="l" id="grain" width="540" height="960" style="width:1080px;height:1920px"></canvas>
<svg class="o" id="ring" viewBox="0 0 1080 1920"><circle id="rc" cx="0" cy="0" r="120" fill="none" stroke="#ff2b2b" stroke-width="14" stroke-linecap="round"/>
  <path id="arrow" d="" fill="none" stroke="#ff2b2b" stroke-width="14" stroke-linecap="round" stroke-linejoin="round"/></svg>
<div class="o c st" id="hook"><div class="a">CAN YOU</div><div class="b">SPOT HIM?</div></div>
<div class="o c" id="tag"><span class="p">ROUND 1</span><span class="lv">EASY</span></div>
<div class="o" id="timer"><svg viewBox="0 0 220 220"><circle cx="110" cy="110" r="96" fill="rgba(0,0,0,.55)" stroke="rgba(255,255,255,.25)" stroke-width="14"/>
  <circle id="tarc" cx="110" cy="110" r="96" fill="none" stroke="#ffd60a" stroke-width="14" stroke-linecap="round" transform="rotate(-90 110 110)" stroke-dasharray="603" stroke-dashoffset="0"/></svg>
  <div id="tnum" class="st">3</div></div>
<div class="o c" id="hint"></div>
<div class="o c st" id="score">1/3</div>
<div class="o c st" id="say"></div>
<div class="o c st" id="q1">HOW MANY<br><span class="y">DID YOU FIND?</span></div>
<div class="o c" id="chips"><span>0/3</span><span>1/3</span><span>2/3</span><span>3/3</span></div>
<div class="o c st" id="cmt">comment yours &#8595;</div>
<div class="o c st" id="game">the game:</div>
<div class="o c st" id="gname">someone lives in our attic.</div>
<div class="o" id="pill">SEARCH IT ON ROBLOX</div>
<div class="o c" id="send">send this to the friend who'd scream first</div>
<div class="l" id="flash"></div>
<div class="l" id="black"></div>
<script>
const $ = (id) => document.getElementById(id);
const clamp = (x, a, b) => Math.max(a, Math.min(b, x));
const seg = (t, a, b) => clamp((t - a) / (b - a), 0, 1);
const back = (x) => { x = clamp(x, 0, 1); const c = 1.7; return 1 + (c + 1) * Math.pow(x - 1, 3) + c * Math.pow(x - 1, 2); };
const ease = (x) => x * x * (3 - 2 * x);
function rnd(n) { const x = Math.sin(n * 127.1 + 311.7) * 43758.5453; return x - Math.floor(x); }
const g = $('grain').getContext('2d'); const gi = g.createImageData(540, 960);
function pop(el, t, at, dur = 0.2, extra = '') {
  const k = seg(t, at, at + dur);
  el.style.opacity = k > 0 ? 1 : 0;
  el.style.transform = extra + ' scale(' + (0.5 + 0.5 * back(k)) + ')';
}
const ALL = ['hook','tag','timer','hint','ring','say','score','q1','chips','cmt','game','gname','pill','send'];
const LV = { EASY: 'var(--easy)', HARD: 'var(--hard)', IMPOSSIBLE: 'var(--red)' };
window.setFrame = (f, fr, cuts) => {
  const t = f / 30, sec = fr.section, lt = fr.i / 30, dur = fr.n / 30;
  for (const id of ALL) $(id).style.opacity = 0;
  const b = $('base');
  let filt = 'contrast(1.12) saturate(1.1) brightness(1.15)', tf = 'none', org = '50% 50%';
  if (fr.src.includes('/reel/raw/')) filt = 'contrast(1.15) saturate(1.0) brightness(1.5)';
  // ---------- rounds
  if (sec === 'round') {
    const r = fr.round;
    const hk = $('hook'); hk.style.opacity = 1;
    const k = seg(lt, 0, 0.25); hk.style.transform = 'scale(' + ((r === 1 ? 1.25 : 1.0) - (r === 1 ? 0.45 : 0.2) * back(k)) + ')';
    const tg = $('tag'); tg.firstChild.textContent = 'ROUND ' + r;
    const lv = tg.lastChild; lv.textContent = fr.level; lv.style.background = LV[fr.level];
    pop(tg, lt, r === 1 ? 0.3 : 0.05); 
    // the countdown
    const T0 = 0.35, TL = dur - T0 - 0.15;
    const left = clamp(1 - (lt - T0) / TL, 0, 1);
    const tm = $('timer'); tm.style.opacity = lt >= T0 - 0.15 ? 1 : 0;
    $('tarc').setAttribute('stroke-dashoffset', String(603 * (1 - left)));
    $('tarc').setAttribute('stroke', left > 0.34 ? '#ffd60a' : '#ff2b2b');
    const num = Math.max(1, Math.ceil(left * 3));
    $('tnum').textContent = String(num);
    const ph = ((lt - T0) / TL * 3) % 1; tm.style.transform = 'scale(' + (1 + 0.12 * Math.max(0, 1 - ph * 4)) + ')';
    const h = $('hint');
    if (r === 2) { h.textContent = "(pause it. we'll wait.)"; h.style.opacity = seg(lt, 0.8, 1.1); h.style.transform = 'rotate(-3deg)'; }
    if (r === 3) { h.textContent = 'only 2% find this one'; h.style.opacity = seg(lt, 0.6, 0.9); h.style.transform = 'rotate(-3deg)'; }
  }
  // ---------- reveals: punch in on him, draw the circle
  if (sec === 'reveal') {
    const [sx, sy] = fr.spot;
    const kz = ease(seg(lt, 0, 0.35));
    org = sx + 'px ' + sy + 'px'; tf = 'scale(' + (1 + 0.55 * kz) + ')';
    // with the origin on him he stays put on screen while everything grows around him
    const kc = seg(lt, 0.2, 0.55);
    const rc = $('rc'); rc.setAttribute('cx', sx); rc.setAttribute('cy', sy); rc.setAttribute('r', 125);
    const C = 2 * Math.PI * 125; rc.setAttribute('stroke-dasharray', C); rc.setAttribute('stroke-dashoffset', C * (1 - kc));
    const ax = sx + 330, ay = sy + 300;
    $('arrow').setAttribute('d', 'M' + ax + ' ' + ay + ' L' + (sx + 110) + ' ' + (sy + 105) + ' M' + (sx + 110) + ' ' + (sy + 105) + ' l60 0 M' + (sx + 110) + ' ' + (sy + 105) + ' l0 60');
    $('arrow').style.opacity = seg(lt, 0.45, 0.55);
    $('ring').style.opacity = 1;
    const s = $('say'); s.textContent = fr.say; pop(s, lt, 0.4, 0.2);
    filt = 'contrast(1.15) saturate(1.1) brightness(1.2)';
  }
  if (sec === 'scare') { filt = 'contrast(1.2) brightness(1.5)'; const sh = 30 * (1 - seg(lt, 0, 0.5)); tf = 'translate(' + (rnd(f) - .5) * sh + 'px,' + (rnd(f + 3) - .5) * sh + 'px) scale(1.05)'; }
  // ---------- end card
  if (sec === 'end') {
    filt = 'contrast(1.1) saturate(.8) brightness(.4) blur(5px)'; tf = 'scale(1.08)';
    pop($('q1'), lt, 0.2, 0.22);
    pop($('chips'), lt, 0.8, 0.22);
    $('cmt').style.opacity = seg(lt, 1.5, 1.8); $('cmt').style.transform = 'translateY(' + (8 * Math.sin(lt * 6)) + 'px)';
    $('game').style.opacity = seg(lt, 2.2, 2.4); pop($('gname'), lt, 2.3, 0.22);
    const kp = seg(lt, 2.7, 2.95); const p = $('pill'); p.style.opacity = kp > 0 ? 1 : 0;
    p.style.transform = 'translateX(-50%) scale(' + ((0.5 + 0.5 * back(kp)) * (1 + 0.03 * Math.sin(lt * 7))) + ')';
    $('send').style.opacity = seg(lt, 3.5, 3.9); $('send').style.transform = 'rotate(-3deg)';
  }
  b.style.filter = filt; b.style.transformOrigin = org; b.style.transform = tf;
  // ---------- flashes and blackout
  let fl = 0;
  const sc = cuts[5];
  if (t >= sc) fl = Math.max(fl, 0.95 * (1 - seg(t, sc, sc + 0.2)));
  for (const c of [cuts[1], cuts[2], cuts[3], cuts[4], cuts[6]]) if (t >= c) fl = Math.max(fl, 0.35 * (1 - seg(t, c, c + 0.1)));
  $('flash').style.opacity = fl;
  let bk = 0;
  if (t >= sc - 0.4 && t < sc) bk = 1;                 // a beat of black before he hits
  if (t > 19.6) bk = seg(t, 19.6, 20.0);
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
    const b = document.getElementById('base');
    if (img) { b.src = img; await b.decode(); }
    window.setFrame(f, fr, cuts);
  }, [img, f, fr, edit.cuts]);
  fs.writeFileSync(`${outDir}/${String(f).padStart(4, '0')}.png`, await page.screenshot({ type: 'png' }));
  if (f % 60 === 0) console.log('comp', f);
}
await browser.close();
