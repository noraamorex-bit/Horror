// node comp16.mjs edit.json outDir [from] [to] — reel 17, the cinematic trailer.
// A film-trailer look (nothing like the meme-caption reels): a teal-and-amber grade, halation on the
// highlights, gate weave, film grain and dust, thin cinema bars; serif title cards on black whose
// letters slowly spread; white flash frames in the montage; the title in Gloock with a red full stop;
// an end card with the game icon.
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
@font-face { font-family: IS; src: url(${font('InstrumentSerif-Regular.ttf')}); }
@font-face { font-family: ISI; src: url(${font('InstrumentSerif-Italic.ttf')}); }
@font-face { font-family: G; src: url(${font('Gloock-Regular.ttf')}); }
@font-face { font-family: SC; src: url(${font('ArsenalSC-Regular.ttf')}); }
* { box-sizing:border-box; }
html,body { margin:0; width:1080px; height:1920px; overflow:hidden; background:#000; }
.l { position:absolute; inset:0; pointer-events:none; }
#shot { position:absolute; inset:0; overflow:hidden; }
#cam { position:absolute; inset:-20px; transform-origin:50% 50%; }
#cam img { position:absolute; inset:20px; width:1080px; height:1920px; object-fit:cover; }
#glow { mix-blend-mode:screen; opacity:.26; }
#toneS { background:#0b2f3d; mix-blend-mode:lighten; opacity:.3; }
#toneH { background:#ff9a45; mix-blend-mode:soft-light; opacity:.14; }
#vig { background: radial-gradient(ellipse 78% 62% at 50% 50%, rgba(0,0,0,0) 40%, rgba(0,0,0,.5) 78%, rgba(0,0,0,.9) 100%); }
.bar { position:absolute; left:0; right:0; height:150px; background:#000; }
#barT { top:0; } #barB { bottom:0; }
#grain { mix-blend-mode:overlay; opacity:.22; }
#dust { opacity:.8; }
#flash { background:#fff; opacity:0; } #black { background:#000; opacity:0; }
/* cards */
#card { position:absolute; left:60px; right:60px; top:0; bottom:0; display:flex; flex-direction:column; align-items:center; justify-content:center; text-align:center; opacity:0; }
#card div { font-family:IS; font-size:82px; line-height:1.18; color:#eee8dc; text-transform:uppercase; white-space:nowrap; }
#card.small div { font-family:SC; font-size:44px; color:#cfc6b4; }
#card.italic div { font-family:ISI; font-size:92px; text-transform:none; }
/* title */
#title { position:absolute; left:0; right:0; top:820px; text-align:center; opacity:0; }
#title .t { font-family:G; font-size:84px; color:#f2ede4; letter-spacing:-1px; white-space:nowrap; }
#title .t b { color:#d1252b; font-weight:normal; }
#title .s { font-family:SC; font-size:38px; letter-spacing:14px; color:#a99f8f; margin-top:34px; }
/* end */
#end { position:absolute; left:0; right:0; top:0; bottom:0; opacity:0; text-align:center; }
#end img { position:absolute; left:50%; top:560px; width:240px; height:240px; margin-left:-120px; border-radius:46px; box-shadow:0 0 80px rgba(209,37,43,.25); }
#end .t { position:absolute; left:0; right:0; top:860px; font-family:G; font-size:72px; color:#f2ede4; white-space:nowrap; }
#end .t b { color:#d1252b; font-weight:normal; }
#end .s { position:absolute; left:0; right:0; top:985px; font-family:SC; font-size:36px; letter-spacing:10px; color:#bfb5a3; }
#end .p { position:absolute; left:50%; top:1080px; transform:translateX(-50%); border:2px solid #8f8576; border-radius:999px; padding:20px 44px 22px; font-family:SC; font-size:34px; letter-spacing:4px; color:#efe8dc; white-space:nowrap; }
#end .i { position:absolute; left:0; right:0; top:1220px; font-family:ISI; font-size:64px; color:#d8cfbf; }
</style></head><body>
<div id="shot"><div id="cam"><img id="im"/><img id="glow"/></div>
  <div class="l" id="toneS"></div><div class="l" id="toneH"></div><div class="l" id="vig"></div>
  <div class="bar" id="barT"></div><div class="bar" id="barB"></div></div>
<div id="card"></div>
<div id="title"><div class="t">someone lives in our attic<b>.</b></div><div class="s">NOW ON ROBLOX</div></div>
<div id="end"><img src="${icon}"/><div class="t">someone lives in our attic<b>.</b></div>
  <div class="s">FREE ON ROBLOX · 1–4 PLAYERS</div><div class="p">SEARCH: SOMEONE LIVES IN OUR ATTIC</div><div class="i">bring your friends.</div></div>
<canvas class="l" id="dust" width="1080" height="1920"></canvas>
<canvas class="l" id="grain" width="540" height="960" style="width:1080px;height:1920px"></canvas>
<div class="l" id="flash"></div><div class="l" id="black"></div>
<script>
const $ = (id) => document.getElementById(id);
const clamp = (x, a, b) => Math.max(a, Math.min(b, x));
const seg = (t, a, b) => clamp((t - a) / (b - a), 0, 1);
const ease = (x) => { x = clamp(x, 0, 1); return x * x * (3 - 2 * x); };
function rnd(n) { const x = Math.sin(n * 127.1 + 311.7) * 43758.5453; return x - Math.floor(x); }
const g = $('grain').getContext('2d'); const gi = g.createImageData(540, 960);
const dctx = $('dust').getContext('2d');
let lastCard = '';
window.setFrame = (f, fr, img) => {
  const kind = fr.kind, lt = fr.i / 30, len = fr.n / 30;
  $('shot').style.opacity = 0; $('card').style.opacity = 0; $('title').style.opacity = 0; $('end').style.opacity = 0;
  let flash = 0, black = 0, dust = 0;
  // gate weave: a slow drift and a tiny jitter, like film in a projector
  const wx = Math.sin(f * 0.37) * 1.2 + (rnd(f) - .5) * 1.1, wy = Math.sin(f * 0.23) * 1.6 + (rnd(f + 3) - .5) * 1.1;
  if (kind === 'shot') {
    $('shot').style.opacity = 1;
    const k = fr.i / Math.max(1, fr.n - 1);
    const zoom = 1.02 + 0.035 * k;
    $('cam').style.transform = 'translate(' + wx + 'px,' + wy + 'px) scale(' + zoom + ')';
    const filt = 'contrast(1.14) saturate(.8) brightness(' + fr.g + ')';
    $('im').style.filter = filt;
    $('glow').style.filter = filt + ' blur(16px) brightness(1.25)';
    // short shots (the montage) cut in with a flash of overexposure
    if (fr.n <= 8 && fr.i === 0) flash = 0.35;
    if (fr.name === 'chase') { $('cam').style.transform += ' rotate(' + (Math.sin(f * 0.9) * 0.6) + 'deg)'; if (fr.i >= fr.n - 4) flash = (fr.i - (fr.n - 4)) / 4 * 0.6; }
    // fade up from black at the start of the slow shots, and down at the end of some
    if (fr.n > 30) { black = Math.max(black, 1 - seg(lt, 0, 0.35)); }
    if (fr.name === 'hero') black = Math.max(black, 1 - seg(lt, 0, 0.9));
    dust = 0.5;
  } else if (kind === 'card') {
    const c = $('card');
    const key = fr.lines.join('|') + fr.style;
    if (key !== lastCard) { c.innerHTML = fr.lines.map(s => '<div>' + s + '</div>').join(''); c.className = fr.style || ''; lastCard = key; }
    const a = seg(lt, 0.05, 0.45) * (1 - seg(lt, len - 0.32, len - 0.04));
    c.style.opacity = a * (0.94 + 0.06 * rnd(f * 3));               // (a faint projector flicker)
    const sp = (fr.style === 'italic' ? 0.02 : 0.14) + 0.07 * (lt / len);
    for (const d of c.children) { d.style.letterSpacing = sp + 'em'; d.style.filter = 'blur(' + (6 * (1 - seg(lt, 0.05, 0.5))) + 'px)'; }
    c.style.transform = 'translate(' + wx * 0.5 + 'px,' + wy * 0.5 + 'px) scale(' + (1 + 0.025 * lt / len) + ')';
    dust = 1;
  } else if (kind === 'flash') {
    flash = 1;
  } else if (kind === 'black') {
    black = 1;
  } else if (kind === 'title') {
    const t = $('title');
    const a = seg(lt, 0.15, 0.9);
    // a hard flicker as it lands
    const flick = lt > 0.15 && lt < 0.55 ? (rnd(f * 5) < 0.4 ? 0.15 : 1) : 1;
    t.style.opacity = a * flick;
    t.querySelector('.t').style.filter = 'blur(' + (8 * (1 - seg(lt, 0.15, 0.8))) + 'px)';
    t.querySelector('.t').style.letterSpacing = (-1 + 1.5 * (lt / len)) + 'px';
    t.querySelector('.s').style.opacity = seg(lt, 1.4, 2.0);
    t.style.transform = 'translate(' + wx * 0.4 + 'px,' + wy * 0.4 + 'px)';
    black = seg(lt, len - 0.3, len);
    dust = 1;
  } else if (kind === 'end') {
    const e = $('end');
    e.style.opacity = seg(lt, 0.1, 0.6) * (1 - seg(lt, len - 0.5, len));
    e.querySelector('img').style.transform = 'scale(' + (0.94 + 0.06 * ease(seg(lt, 0.1, 1.2))) + ')';
    e.querySelector('.s').style.opacity = seg(lt, 0.7, 1.2);
    e.querySelector('.p').style.opacity = seg(lt, 1.1, 1.6);
    e.querySelector('.i').style.opacity = seg(lt, 1.6, 2.2);
    dust = 0.7;
  }
  $('flash').style.opacity = flash;
  $('black').style.opacity = black;
  // dust and scratches
  dctx.clearRect(0, 0, 1080, 1920);
  if (dust > 0) {
    for (let j = 0; j < 7; j++) {
      if (rnd(f * 11 + j) < 0.45) continue;
      const x = rnd(f * 13 + j) * 1080, y = rnd(f * 17 + j) * 1920, r = 1 + rnd(f * 19 + j) * 2.6;
      dctx.fillStyle = 'rgba(235,225,205,' + (0.35 * dust) + ')';
      dctx.beginPath(); dctx.ellipse(x, y, r, r * (0.6 + rnd(f + j)), rnd(j + f) * 3, 0, Math.PI * 2); dctx.fill();
    }
    if (rnd(f * 23) < 0.12) {
      const x = rnd(f * 29) * 1080;
      dctx.fillStyle = 'rgba(235,225,205,' + (0.18 * dust) + ')'; dctx.fillRect(x, 0, 1.4, 1920);
    }
  }
  const d = gi.data;
  for (let i2 = 0; i2 < d.length; i2 += 4) { const v = (128 + (Math.random() - 0.5) * 170) | 0; d[i2] = d[i2 + 1] = d[i2 + 2] = v; d[i2 + 3] = 255; }
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
  const img = fr.src && fs.existsSync(fr.src) ? 'data:image/png;base64,' + fs.readFileSync(fr.src).toString('base64') : '';
  await page.evaluate(async ([img, f, fr]) => {
    if (img) {
      for (const id of ['im', 'glow']) document.getElementById(id).src = img;
      await Promise.all(['im', 'glow'].map(id => document.getElementById(id).decode().catch(() => {})));
    }
    window.setFrame(f, fr, img);
  }, [img, f, fr]);
  fs.writeFileSync(`${outDir}/${String(f).padStart(4, '0')}.png`, await page.screenshot({ type: 'png' }));
  if (f % 60 === 0) console.log('comp', f);
}
await browser.close();
