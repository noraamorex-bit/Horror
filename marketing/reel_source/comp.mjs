// node comp.mjs rawDir outDir [from] [to] — overlays, grading and titles on top of the renders
import { chromium } from 'playwright';
import fs from 'fs';
const [,, rawDir, outDir, fromArg, toArg] = process.argv;
fs.mkdirSync(outDir, { recursive: true });
const FPS = 30, NF = 810;
const FD = '/mnt/skills/examples/canvas-design/canvas-fonts/';
const font = (f) => 'data:font/ttf;base64,' + fs.readFileSync(FD + f).toString('base64');
const faceStill = fs.existsSync(`${rawDir}/0603.png`) ? 'data:image/png;base64,' + fs.readFileSync(`${rawDir}/0603.png`).toString('base64') : '';

const html = `<!doctype html><html><head><style>
@font-face { font-family: HTitle; src: url(${font('BigShoulders-Bold.ttf')}); }
@font-face { font-family: HSerif; src: url(${font('InstrumentSerif-Italic.ttf')}); }
@font-face { font-family: HSans; src: url(${font('WorkSans-Bold.ttf')}); }
@font-face { font-family: HSansR; src: url(${font('WorkSans-Regular.ttf')}); }
html,body { margin:0; width:1080px; height:1920px; overflow:hidden; background:#000; }
.l { position:absolute; inset:0; }
#stage { position:absolute; inset:0; }
#base { position:absolute; inset:0; width:1080px; height:1920px; }
#rgb { position:absolute; inset:0; width:1080px; height:1920px; mix-blend-mode:screen; opacity:0; }
#vig { background: radial-gradient(ellipse 75% 60% at 50% 46%, rgba(0,0,0,0) 45%, rgba(0,0,0,.55) 78%, rgba(0,0,0,.92) 100%); }
#grain { mix-blend-mode: soft-light; opacity:.22; }
#rain { opacity:0; background: repeating-linear-gradient(101deg, rgba(255,255,255,0) 0 13px, rgba(200,215,235,.10) 13px 14px, rgba(255,255,255,0) 14px 31px); }
#flash { background:#fff; opacity:0; }
#black { background:#000; opacity:0; }
.door { position:absolute; top:0; bottom:0; width:560px; background: linear-gradient(90deg, #070605, #120d0a 30%, #0b0806 70%, #050404); box-shadow: 0 0 60px 30px rgba(0,0,0,.9); }
.door::after { content:''; position:absolute; inset:0; background: repeating-linear-gradient(0deg, rgba(255,255,255,.012) 0 3px, rgba(0,0,0,0) 3px 9px); }
#doorL { left:0; } #doorR { right:0; }
.txt { position:absolute; left:70px; right:70px; text-align:center; color:#f3efe7; text-shadow: 0 6px 40px rgba(0,0,0,.95), 0 0 3px rgba(0,0,0,.9); opacity:0; }
.serif { font-family: HSerif; }
.title { font-family: HTitle; text-transform: uppercase; letter-spacing: 18px; line-height: .9; }
.sans { font-family: HSans; text-transform: uppercase; }
#hook { top: 300px; font-size: 92px; line-height: 1.05; }
#title { top: 1180px; font-size: 250px; }
#titleSub { top: 1650px; font-family: HSansR; font-size: 38px; letter-spacing: 16px; text-transform: uppercase; }
#power { top: 820px; font-size: 84px; }
#knows { top: 330px; font-size: 80px; }
#run { top: 760px; font-size: 330px; letter-spacing: 30px; }
#hide { top: 1420px; font-size: 120px; }
#breathe { top: 1420px; font-size: 104px; }
#end { position:absolute; inset:0; opacity:0; }
#endFace { position:absolute; left:-120px; top:-200px; width:1320px; height:2347px; background-size:cover; background-position:center; filter: blur(6px) grayscale(.3) brightness(.55); opacity:.0; }
#endTitle { top: 520px; font-size: 270px; }
#endLine { top: 1060px; font-size: 70px; }
#endRule { position:absolute; left:470px; width:140px; height:4px; top: 1235px; background:#f3efe7; opacity:0; }
#endCta { top: 1285px; font-size: 54px; letter-spacing: 8px; }
#endSmall { top: 1375px; font-family: HSansR; font-size: 36px; letter-spacing: 3px; opacity:0; }
.note { position:absolute; left:60px; right:60px; height:auto; padding: 28px 34px; border-radius: 42px; background: rgba(28,28,30,.78); backdrop-filter: blur(20px); border: 1px solid rgba(255,255,255,.12); color:#f2f2f2; font-family: HSansR; opacity:0; box-shadow: 0 20px 60px rgba(0,0,0,.5); }
.note .app { font-family: HSans; font-size: 28px; letter-spacing: 1px; opacity:.6; text-transform: uppercase; display:flex; justify-content:space-between; }
.note .who { font-family: HSans; font-size: 42px; margin-top: 10px; }
.note .msg { font-size: 40px; line-height: 1.25; margin-top: 6px; }
</style></head><body>
<svg width="0" height="0" style="position:absolute"><defs>
  <filter id="red" color-interpolation-filters="sRGB"><feColorMatrix type="matrix" values="1 0 0 0 0  0 0 0 0 0  0 0 0 0 0  0 0 0 1 0"/></filter>
  <filter id="cyan" color-interpolation-filters="sRGB"><feColorMatrix type="matrix" values="0 0 0 0 0  0 1 0 0 0  0 0 1 0 0  0 0 0 1 0"/></filter>
</defs></svg>
<div id="stage">
  <img id="base"/>
  <img id="rgb"/>
  <div class="l" id="rain"></div>
  <div class="door" id="doorL"></div><div class="door" id="doorR"></div>
  <div class="l" id="vig"></div>
  <canvas class="l" id="grain" width="540" height="960" style="width:1080px;height:1920px"></canvas>
  <div id="end"><div id="endFace" style="background-image:url(${faceStill})"></div>
    <div class="l" style="background: radial-gradient(ellipse 70% 55% at 50% 45%, rgba(0,0,0,.2), rgba(0,0,0,.95) 80%)"></div></div>
  <div class="txt serif" id="hook"></div>
  <div class="txt title" id="title">Home Alone</div>
  <div class="txt" id="titleSub">a Roblox horror game</div>
  <div class="note" id="note1" style="top:150px"><div class="app"><span>Messages</span><span>now</span></div><div class="who">Mom</div><div class="msg">Turn on channel 7. RIGHT NOW.</div></div>
  <div class="note" id="note2" style="top:420px"><div class="app"><span>Messages</span><span>now</span></div><div class="who">Mom</div><div class="msg">A man has been living inside houses here. While the families were home.</div></div>
  <div class="txt serif" id="power">then the power goes out.</div>
  <div class="txt serif" id="knows">he always knows<br>where you are.</div>
  <div class="txt title" id="run">Run</div>
  <div class="txt serif" id="hide">hide.</div>
  <div class="txt serif" id="breathe">don't breathe.</div>
  <div class="txt title" id="endTitle">Home Alone</div>
  <div class="txt serif" id="endLine">can you survive the night?</div>
  <div id="endRule"></div>
  <div class="txt sans" id="endCta">Play free on Roblox</div>
  <div class="txt" id="endSmall">1–4 players  ·  search “Home Alone”</div>
  <div class="l" id="flash"></div>
  <div class="l" id="black"></div>
</div>
<script>
const $ = (id) => document.getElementById(id);
const clamp = (x, a, b) => Math.max(a, Math.min(b, x));
const seg = (t, a, b) => clamp((t - a) / (b - a), 0, 1);
const ease = (x) => x * x * (3 - 2 * x);
const win = (t, a, b, fi = 0.25, fo = 0.3) => Math.min(seg(t, a, a + fi), 1 - seg(t, b - fo, b));
function rnd(n) { const x = Math.sin(n * 127.1 + 311.7) * 43758.5453; return x - Math.floor(x); }
const HOOK = 'something has been\\nliving in your house.';
const g = $('grain').getContext('2d'); const gi = g.createImageData(540, 960);
window.setFrame = (t, f) => {
  // ---------- base grade
  let filter = 'contrast(1.12) saturate(.82) brightness(1.02)';
  if (t >= 5.4 && t < 8.7) filter = 'contrast(1.06) saturate(1.0) brightness(1.04) sepia(.08)';
  if (t >= 2.6 && t < 5.4) filter = 'contrast(1.15) saturate(.7) brightness(1.05) hue-rotate(-6deg)';
  $('base').style.filter = filter;
  // ---------- shake on hits
  let sh = 0;
  for (const [h, a] of [[1.3, 14], [2.98, 18], [8.7, 10], [11.2, 12], [13.5, 26], [19.0, 30], [19.9, 46], [21.0, 16]]) sh += a * Math.max(0, 1 - (t - h) / 0.35) * (t >= h ? 1 : 0);
  $('stage').style.transform = sh ? \`translate(\${(rnd(f) - .5) * sh}px, \${(rnd(f + 99) - .5) * sh}px)\` : '';
  // ---------- chromatic split on the scares
  let split = 0;
  if (t >= 19.9 && t < 20.6) split = 26 * (1 - seg(t, 19.9, 20.6)) + 10;
  else if (t >= 13.3 && t < 13.56) split = 14;
  else if (t >= 1.3 && t < 1.45) split = 10;
  $('rgb').style.opacity = split ? 1 : 0;
  if (split) { $('base').style.filter += ' url(#cyan)'; $('rgb').style.filter = 'url(#red)'; $('rgb').style.transform = \`translate(\${split}px, \${-split * 0.3}px) scale(1.01)\`; }
  // ---------- rain outside
  $('rain').style.opacity = (t >= 2.6 && t < 5.4) ? 0.9 : 0;
  $('rain').style.backgroundPosition = \`\${(f * 37) % 300}px \${(f * 181) % 1900}px\`;
  // ---------- closet doors: a crack of the room between them, then ripped open
  let gap = 1200;
  if (t >= 14.4 && t < 19.0) gap = 230 + 18 * Math.sin(t * 0.9);
  else if (t >= 19.0 && t < 19.2) gap = 230 + (1200 - 230) * ease(seg(t, 19.0, 19.2));
  const dw = Math.max(0, (1080 - gap) / 2);
  $('doorL').style.width = dw + 'px'; $('doorR').style.width = dw + 'px';
  $('doorL').style.display = $('doorR').style.display = (t >= 14.4 && t < 19.25) ? 'block' : 'none';
  // ---------- text
  const hookN = Math.floor(clamp((t - 0.15) / 1.05, 0, 1) * HOOK.length);
  $('hook').innerHTML = HOOK.slice(0, hookN).replace('\\n', '<br>') + (t < 1.3 && f % 16 < 8 ? '<span style="opacity:.7">|</span>' : '');
  let hookA = win(t, 0.12, 2.6, 0.1, 0.12);
  if (t > 2.0 && rnd(f * 3) < 0.35) hookA *= 0.15;   // flickers with the flashlight
  $('hook').style.opacity = hookA;
  const titleA = win(t, 2.98, 5.35, 0.08, 0.25);
  const slam = 1 + 0.18 * (1 - ease(seg(t, 2.98, 3.25)));
  $('title').style.opacity = titleA;
  $('title').style.transform = \`scale(\${slam})\`;
  $('title').style.filter = \`blur(\${10 * (1 - seg(t, 2.98, 3.2))}px)\`;
  if (t >= 2.98 && t < 3.4 && rnd(f) < 0.3) $('title').style.transform += \` translateX(\${(rnd(f + 5) - .5) * 30}px)\`;
  $('titleSub').style.opacity = win(t, 3.55, 5.35, 0.4, 0.25) * 0.85;
  const n1 = win(t, 5.8, 8.55, 0.3, 0.15), n2 = win(t, 6.75, 8.55, 0.3, 0.15);
  $('note1').style.opacity = n1; $('note1').style.transform = \`translateY(\${-60 * (1 - ease(seg(t, 5.8, 6.1)))}px)\`;
  $('note2').style.opacity = n2; $('note2').style.transform = \`translateY(\${-60 * (1 - ease(seg(t, 6.75, 7.05)))}px)\`;
  if (t >= 8.48 && t < 8.7 && f % 3 === 0) { $('note1').style.opacity = 0; $('note2').style.opacity = 0; }
  $('power').style.opacity = win(t, 8.85, 9.9, 0.35, 0.3);
  $('knows').style.opacity = win(t, 10.25, 11.15, 0.35, 0.06);
  const runA = win(t, 11.2, 12.3, 0.04, 0.25);
  $('run').style.opacity = runA;
  $('run').style.transform = \`scale(\${1 + 0.25 * (1 - ease(seg(t, 11.2, 11.45)))})\`;
  $('hide').style.opacity = win(t, 14.75, 16.3, 0.5, 0.35);
  $('breathe').style.opacity = win(t, 16.5, 18.9, 0.6, 0.4) * (t > 18.2 && rnd(f) < 0.3 ? 0.3 : 1);
  // ---------- flashes and blacks
  let fl = 0;
  if (t >= 19.9) fl = Math.max(fl, 1 - seg(t, 19.9, 20.08));
  if (t >= 1.3) fl = Math.max(fl, 0.25 * (1 - seg(t, 1.3, 1.4)));
  if (t >= 2.98) fl = Math.max(fl, 0.18 * (1 - seg(t, 2.98, 3.06)));
  if (t >= 11.2) fl = Math.max(fl, 0.18 * (1 - seg(t, 11.2, 11.3)));
  $('flash').style.opacity = fl;
  let bk = 0;
  if (t < 0.12) bk = 1 - seg(t, 0, 0.12);
  if (t >= 2.52 && t < 2.62) bk = 1;
  if (t >= 13.56 && t < 14.4) bk = 1;
  if (t >= 14.4 && t < 14.9) bk = 1 - seg(t, 14.4, 14.9);
  if (t >= 20.6) bk = 1;
  $('black').style.opacity = bk;
  // ---------- end card
  const endOn = t >= 21.0;
  $('end').style.opacity = endOn ? 1 : 0;
  $('endFace').style.opacity = endOn ? 0.28 * seg(t, 21.2, 23.5) : 0;
  $('endFace').style.transform = \`scale(\${1 + 0.05 * seg(t, 21, 27)})\`;
  if (endOn) $('black').style.opacity = 0;
  if (endOn) $('stage').style.background = '#000';
  let et = win(t, 21.0, 27.5, 0.08, 0.1);
  if (t >= 24.6 && rnd(f * 7) < 0.06) et *= 0.2;
  $('endTitle').style.opacity = et;
  $('endTitle').style.transform = \`scale(\${1 + 0.16 * (1 - ease(seg(t, 21.0, 21.3)))})\`;
  $('endTitle').style.filter = \`blur(\${8 * (1 - seg(t, 21.0, 21.2))}px)\`;
  $('endLine').style.opacity = win(t, 21.9, 27.5, 0.6, 0.1);
  $('endRule').style.opacity = 0.8 * win(t, 23.0, 27.5, 0.4, 0.1);
  $('endCta').style.opacity = win(t, 23.0, 27.5, 0.35, 0.1);
  $('endSmall').style.opacity = 0.7 * win(t, 23.4, 27.5, 0.5, 0.1);
  $('base').style.opacity = endOn ? 0 : 1;
  $('rgb').style.display = endOn ? 'none' : 'block';
  $('vig').style.opacity = endOn ? 0.6 : 1;
  // ---------- film grain
  const d = gi.data;
  for (let i = 0; i < d.length; i += 4) { const v = (128 + (Math.random() - 0.5) * 150) | 0; d[i] = d[i + 1] = d[i + 2] = v; d[i + 3] = 255; }
  g.putImageData(gi, 0, 0);
};
</script></body></html>`;

const browser = await chromium.launch({ executablePath: '/opt/pw-browsers/chromium-1194/chrome-linux/chrome' });
const page = await browser.newPage({ viewport: { width: 1080, height: 1920 } });
await page.setContent(html);
await page.evaluate(() => document.fonts.ready);
const from = +(fromArg ?? 0), to = +(toArg ?? NF - 1);
for (let f = from; f <= to; f++) {
  const t = f / FPS;
  const p = `${rawDir}/${String(f).padStart(4, '0')}.png`;
  const img = fs.existsSync(p) ? 'data:image/png;base64,' + fs.readFileSync(p).toString('base64') : '';
  await page.evaluate(async ([img, t, f]) => {
    const b = document.getElementById('base'), r = document.getElementById('rgb');
    if (img) { b.src = img; r.src = img; await b.decode(); await r.decode(); }
    window.setFrame(t, f);
  }, [img, t, f]);
  fs.writeFileSync(`${outDir}/${String(f).padStart(4, '0')}.png`, await page.screenshot({ type: 'png' }));
  if (f % 30 === 0) console.log('comp', f);
}
await browser.close();
