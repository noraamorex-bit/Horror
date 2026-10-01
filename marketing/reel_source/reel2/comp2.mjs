// node comp2.mjs rawDir outDir [from] [to] — reel 2 ("under the bed"): overlays, grading, titles
import { chromium } from 'playwright';
import fs from 'fs';
const [,, rawDir, outDir, fromArg, toArg] = process.argv;
fs.mkdirSync(outDir, { recursive: true });
const FPS = 30, NF = 780;
const FD = '/mnt/skills/examples/canvas-design/canvas-fonts/';
const font = (f) => 'data:font/ttf;base64,' + fs.readFileSync(FD + f).toString('base64');
const faceStill = fs.existsSync(`${rawDir}/0648.png`) ? 'data:image/png;base64,' + fs.readFileSync(`${rawDir}/0648.png`).toString('base64') : '';

const html = `<!doctype html><html><head><style>
@font-face { font-family: HTitle; src: url(${font('BigShoulders-Bold.ttf')}); }
@font-face { font-family: HSerif; src: url(${font('InstrumentSerif-Italic.ttf')}); }
@font-face { font-family: HSans; src: url(${font('WorkSans-Bold.ttf')}); }
@font-face { font-family: HSansR; src: url(${font('WorkSans-Regular.ttf')}); }
html,body { margin:0; width:1080px; height:1920px; overflow:hidden; background:#000; }
.l { position:absolute; inset:0; }
#stage { position:absolute; inset:0; }
#base, #rgb { position:absolute; inset:0; width:1080px; height:1920px; }
#rgb { mix-blend-mode:screen; opacity:0; }
#vig { background: radial-gradient(ellipse 80% 55% at 50% 40%, rgba(0,0,0,0) 40%, rgba(0,0,0,.55) 75%, rgba(0,0,0,.94) 100%); }
#grain { mix-blend-mode: soft-light; opacity:.24; }
#skirt { position:absolute; left:-20px; right:-20px; height:120px; background: linear-gradient(180deg, #000 0%, rgba(0,0,0,.92) 45%, rgba(0,0,0,0) 100%); filter: blur(2px); }
#dust { position:absolute; inset:0; }
#flash { background:#fff; opacity:0; }
#black { background:#000; opacity:0; }
.txt { position:absolute; left:70px; right:70px; text-align:center; color:#f3efe7; text-shadow: 0 6px 40px rgba(0,0,0,.95), 0 0 3px rgba(0,0,0,.9); opacity:0; }
.serif { font-family: HSerif; }
.title { font-family: HTitle; text-transform: uppercase; letter-spacing: 18px; line-height: .9; }
.sans { font-family: HSans; text-transform: uppercase; }
#pov { top: 180px; font-family: HSans; font-size: 44px; letter-spacing: 10px; }
#hook { top: 250px; font-size: 96px; line-height: 1.02; }
#rule { top: 1330px; font-size: 60px; }
#count { top: 1250px; font-family: HTitle; font-size: 190px; letter-spacing: 14px; }
#countSub { top: 1460px; font-size: 52px; }
#breatheT { top: 260px; font-size: 104px; }
#gone { top: 260px; font-size: 96px; }
#right { top: 1300px; font-size: 84px; }
/* the game's breath meter, as it looks in Home Alone: a plain dark box, white text, a bar */
#meter { position:absolute; left:50%; top:1640px; width:560px; margin-left:-280px; padding:22px 28px 26px; border-radius:14px; background:rgba(12,12,14,.72); border:1px solid rgba(255,255,255,.16); opacity:0; }
#meter .lab { font-family: HSans; font-size:30px; letter-spacing:6px; color:#f2f0ea; text-align:center; text-transform:uppercase; }
#meter .bar { margin-top:16px; height:16px; border-radius:8px; background:rgba(255,255,255,.14); overflow:hidden; }
#meter .fill { height:100%; width:100%; background:#f2f0ea; border-radius:8px; }
#end { position:absolute; inset:0; opacity:0; background:#000; }
#endFace { position:absolute; left:-120px; top:-200px; width:1320px; height:2347px; background-size:cover; background-position:center; filter: blur(7px) grayscale(.35) brightness(.5); opacity:0; }
#endTitle { top: 560px; font-size: 270px; }
#endLine { top: 1080px; font-size: 72px; }
#endRule { position:absolute; left:470px; width:140px; height:4px; top: 1250px; background:#f3efe7; opacity:0; }
#endCta { top: 1300px; font-size: 56px; letter-spacing: 8px; }
#endSmall { top: 1395px; font-family: HSansR; font-size: 36px; letter-spacing: 3px; }
</style></head><body>
<svg width="0" height="0" style="position:absolute"><defs>
  <filter id="red" color-interpolation-filters="sRGB"><feColorMatrix type="matrix" values="1 0 0 0 0  0 0 0 0 0  0 0 0 0 0  0 0 0 1 0"/></filter>
  <filter id="cyan" color-interpolation-filters="sRGB"><feColorMatrix type="matrix" values="0 0 0 0 0  0 1 0 0 0  0 0 1 0 0  0 0 0 1 0"/></filter>
</defs></svg>
<div id="stage">
  <img id="base"/><img id="rgb"/>
  <canvas id="dust" width="540" height="960" style="width:1080px;height:1920px"></canvas>
  <div id="skirt"></div>
  <div class="l" id="vig"></div>
  <canvas class="l" id="grain" width="540" height="960" style="width:1080px;height:1920px"></canvas>
  <div id="end"><div id="endFace" style="background-image:url(${faceStill})"></div>
    <div class="l" style="background: radial-gradient(ellipse 70% 55% at 50% 45%, rgba(0,0,0,.25), rgba(0,0,0,.95) 80%)"></div></div>
  <div class="txt" id="pov">POV</div>
  <div class="txt serif" id="hook"></div>
  <div class="txt serif" id="rule">he checks <b style="font-family:HSans;font-style:normal;font-size:56px;letter-spacing:2px">2</b> hiding spots.</div>
  <div class="txt serif" id="breatheT">don't. breathe.</div>
  <div class="txt" id="count"></div>
  <div class="txt serif" id="countSub"></div>
  <div class="txt serif" id="gone">he's gone.</div>
  <div class="txt serif" id="right">...right?</div>
  <div id="meter"><div class="lab">Holding breath</div><div class="bar"><div class="fill" id="fill"></div></div></div>
  <div class="txt title" id="endTitle">Home Alone</div>
  <div class="txt serif" id="endLine">you can hide. he will look.</div>
  <div id="endRule"></div>
  <div class="txt sans" id="endCta">Play free on Roblox</div>
  <div class="txt" id="endSmall">search “Home Alone Horror”  ·  1–4 players</div>
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
const HOOK = 'you hid\\nunder the bed.';
const g = $('grain').getContext('2d'); const gi = g.createImageData(540, 960);
const dc = $('dust').getContext('2d');
const motes = Array.from({ length: 70 }, (_, i) => ({ x: rnd(i) * 540, y: 230 + rnd(i + 50) * 330, s: 0.6 + rnd(i + 99) * 1.6, v: 0.05 + rnd(i + 7) * 0.2, p: rnd(i + 3) * 6.28 }));
window.setFrame = (t, f) => {
  const scene = t < 22.2;
  // ---------- grade: cold, crushed blacks; warmer once the flashlight is on
  let filter = 'contrast(1.18) saturate(.75) brightness(1.04)';
  if (t >= 20.55 && t < 21.1) filter = 'contrast(1.12) saturate(.9) brightness(1.06) sepia(.06)';
  if (t >= 21.1) filter = 'contrast(1.25) saturate(.6) brightness(1.08)';
  $('base').style.filter = filter;
  // ---------- the bed skirt over the top of the gap (where the bed's underside meets the light)
  $('skirt').style.top = (t < 19.9 ? 380 : 380 - 300 * ease(seg(t, 19.9, 21.1))) + 'px';
  $('skirt').style.opacity = scene ? 1 : 0;
  // ---------- dust drifting in the gap
  dc.clearRect(0, 0, 540, 960);
  if (scene) {
    for (const m of motes) {
      const x = (m.x + Math.sin(t * 0.4 + m.p) * 14 + t * m.v * 30) % 540, y = m.y + Math.sin(t * 0.7 + m.p) * 10;
      dc.fillStyle = 'rgba(210,220,240,' + (0.12 + 0.18 * Math.sin(t * 1.3 + m.p) ** 2) + ')';
      dc.beginPath(); dc.arc(x, y, m.s, 0, 6.29); dc.fill();
    }
  }
  // ---------- shake on hits
  let sh = 0;
  for (const [h, a] of [[8.9, 8], [11.75, 30], [21.1, 54], [22.8, 14]]) sh += a * Math.max(0, 1 - (t - h) / 0.4) * (t >= h ? 1 : 0);
  // his footsteps right by the bed
  for (const h of [14.33, 14.77, 15.2]) sh += 6 * Math.max(0, 1 - (t - h) / 0.2) * (t >= h ? 1 : 0);
  $('stage').style.transform = sh ? \`translate(\${(rnd(f) - .5) * sh}px, \${(rnd(f + 99) - .5) * sh}px)\` : '';
  // ---------- chromatic split
  let split = 0;
  if (t >= 21.1 && t < 22.2) split = 30 * (1 - seg(t, 21.1, 21.8)) + 8;
  else if (t >= 11.75 && t < 11.95) split = 14;
  else if (t >= 8.9 && t < 9.0) split = 9;
  $('rgb').style.opacity = split ? 1 : 0;
  if (split) { $('base').style.filter += ' url(#cyan)'; $('rgb').style.filter = 'url(#red)'; $('rgb').style.transform = \`translate(\${split}px, \${-split * 0.3}px) scale(1.01)\`; }
  // ---------- text
  $('pov').style.opacity = 0.75 * win(t, 0.2, 3.1, 0.3, 0.3);
  const hookN = Math.floor(clamp((t - 0.35) / 1.0, 0, 1) * HOOK.length);
  $('hook').innerHTML = HOOK.slice(0, hookN).replace('\\n', '<br>') + (t < 1.4 && f % 16 < 8 ? '<span style="opacity:.7">|</span>' : '');
  $('hook').style.opacity = win(t, 0.3, 3.1, 0.1, 0.3);
  $('rule').style.opacity = win(t, 1.55, 4.6, 0.4, 0.4);
  let br = win(t, 6.45, 8.6, 0.35, 0.4);
  $('breatheT').style.opacity = br;
  // the count: 1 / 2 at the wardrobe, 2 / 2 at the bed
  let cnt = '', sub = '', ca = 0;
  if (t >= 11.75 && t < 13.6) { cnt = '1 / 2'; sub = 'the wardrobe.'; ca = win(t, 11.75, 13.6, 0.05, 0.4); }
  if (t >= 15.3 && t < 17.3) { cnt = '2 / 2'; sub = ''; ca = win(t, 15.3, 17.3, 0.05, 0.4) * (rnd(f * 5) < 0.12 ? 0.35 : 1); }
  $('count').textContent = cnt; $('count').style.opacity = ca;
  $('count').style.transform = \`scale(\${1 + 0.2 * (1 - ease(seg(t, cnt === '1 / 2' ? 11.75 : 15.3, (cnt === '1 / 2' ? 11.75 : 15.3) + 0.25)))})\`;
  $('countSub').textContent = sub; $('countSub').style.opacity = sub ? win(t, 12.0, 13.6, 0.3, 0.4) : 0;
  $('gone').style.opacity = win(t, 19.85, 21.08, 0.4, 0.02);
  $('right').style.opacity = win(t, 20.4, 21.08, 0.25, 0.02);
  // ---------- the breath meter (the game's)
  const mOn = t >= 6.4 && t < 19.8;
  $('meter').style.opacity = mOn ? win(t, 6.4, 19.8, 0.3, 0.3) : 0;
  const left = clamp(1 - (t - 6.5) / 11.6, 0.04, 1);
  $('fill').style.width = (left * 100) + '%';
  $('fill').style.background = left < 0.25 && f % 6 < 3 ? '#ffffff' : '#d9d6cf';
  $('meter').style.transform = left < 0.25 && mOn ? \`translateX(\${(rnd(f * 3) - .5) * 8}px)\` : '';
  // ---------- flashes and blacks
  let fl = 0;
  if (t >= 21.1) fl = Math.max(fl, 0.95 * (1 - seg(t, 21.1, 21.24)));
  if (t >= 11.75) fl = Math.max(fl, 0.22 * (1 - seg(t, 11.75, 11.85)));
  if (t >= 20.55) fl = Math.max(fl, 0.08 * (1 - seg(t, 20.55, 20.6)));
  $('flash').style.opacity = fl;
  let bk = 0;
  if (t < 0.3) bk = 1 - seg(t, 0, 0.3);
  if (t >= 22.2 && t < 22.8) bk = 1;
  $('black').style.opacity = bk;
  // ---------- end card
  const endOn = t >= 22.8;
  $('end').style.opacity = endOn ? 1 : 0;
  $('endFace').style.opacity = endOn ? 0.32 * seg(t, 22.9, 24.6) : 0;
  $('endFace').style.transform = \`scale(\${1 + 0.05 * seg(t, 22.8, 26)})\`;
  let et = win(t, 22.8, 26.5, 0.08, 0.1);
  if (t >= 24.8 && rnd(f * 7) < 0.06) et *= 0.2;
  $('endTitle').style.opacity = et;
  $('endTitle').style.transform = \`scale(\${1 + 0.16 * (1 - ease(seg(t, 22.8, 23.1)))})\`;
  $('endTitle').style.filter = \`blur(\${8 * (1 - seg(t, 22.8, 23.0))}px)\`;
  $('endLine').style.opacity = win(t, 23.4, 26.5, 0.5, 0.1);
  $('endRule').style.opacity = 0.8 * win(t, 24.0, 26.5, 0.4, 0.1);
  $('endCta').style.opacity = win(t, 24.0, 26.5, 0.35, 0.1);
  $('endSmall').style.opacity = 0.75 * win(t, 24.3, 26.5, 0.5, 0.1);
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
