// node comp_peak.mjs edit.json outDir [from] [to] — the "PEAK ROBLOX HORROR GAME TO PLAY WITH FRIENDS"
// format (reel 23, the owner's reference): slow first-person footage; the hook word by word in the
// upper middle with soft shadows (PEAK yellow, ROBLOX red, HORROR GAME white, TO PLAY WITH / FRIENDS
// green, "(Part 1)"); then a small three-line card pinned at the top (NAME / GAMEPLAY / GENRE, coloured
// labels) and one spaced-out line low in the frame; the jumpscare pixelated and grey; a blue glitch-text
// flash; a noise-block glitch into the black end card. Film grain, vignette, rain on the outdoor shot.
// edit.json: { frames: [{ src, section, i, rain, thought, scare, glitchText, cardLines }], text: {...} }
import { chromium } from 'playwright';
import fs from 'fs';
const [,, editPath, outDir, fromArg, toArg] = process.argv;
const edit = JSON.parse(fs.readFileSync(editPath, 'utf8'));
fs.mkdirSync(outDir, { recursive: true });
const NF = edit.frames.length;
const FD = '/mnt/skills/examples/canvas-design/canvas-fonts/';
const font = (f) => 'data:font/ttf;base64,' + fs.readFileSync(FD + f).toString('base64');
const T = Object.assign({ name: 'someone lives in our attic.', score: '10.5/10', genre: 'Survival Horror', low: 'OUT NOW',
  part: '(Part 1)', endTop: 'Out Now', endSub: 'someone lives in our attic.', glitch: 'he lives in the attic', hookTimes: [0.0, 0.5, 1.0, 1.55, 2.5, 3.4] }, edit.text || {});

const html = `<!doctype html><html><head><style>
@font-face { font-family: O; src: url(${font('Outfit-Bold.ttf')}); }
@font-face { font-family: OR; src: url(${font('Outfit-Regular.ttf')}); }
html,body { margin:0; width:1080px; height:1920px; overflow:hidden; background:#000; }
#base, #pix { position:absolute; inset:0; width:1080px; height:1920px; }
#base { object-fit:cover; }
#pix { image-rendering: pixelated; opacity:0; }
.l { position:absolute; inset:0; }
#vig { background: radial-gradient(ellipse 80% 66% at 50% 48%, rgba(0,0,0,0) 55%, rgba(0,0,0,.35) 88%, rgba(0,0,0,.6) 100%); }
#grain { mix-blend-mode: overlay; opacity:.22; }
#rain { opacity:0; }
#noise { opacity:0; }
#black { background:#000; opacity:0; }
.o { position:absolute; opacity:0; }
.sh { text-shadow: 0 4px 10px rgba(0,0,0,.85), 0 0 3px rgba(0,0,0,.9); }
/* the hook */
.hk { left:0; right:0; text-align:center; font-family:O; white-space:nowrap; color:#fff; letter-spacing:1px; }
#h1 { top:705px; font-size:128px; letter-spacing:0; }
#h2 { top:828px; font-size:128px; letter-spacing:0; }
#h3 { top:950px; font-size:76px; letter-spacing:2px; }
.y { color:#f6c430; } .r { color:#e8251c; } .g { color:#52d36a; }
#part { left:0; right:0; top:1372px; text-align:center; font-family:O; font-size:68px; color:#fff; }
/* the card */
#card { left:0; right:0; top:205px; text-align:center; font-family:O; font-size:56px; line-height:64px; color:#fff; }
#low { left:0; right:0; top:1318px; text-align:center; font-family:O; font-size:46px; letter-spacing:7px; color:#e9e9e9; }
/* the game's own thinking-out-loud line (as in the game, low in the frame) */
#thought { left:90px; right:90px; top:1495px; text-align:center; font-family:OR; font-size:40px; color:#f2efe8; }
/* the glitch text */
#glt { left:-20px; right:-20px; top:900px; text-align:center; font-family:O; font-size:150px; letter-spacing:-6px; color:#2a3cff; white-space:nowrap; }
/* the end card */
#endTop { left:0; right:0; top:680px; text-align:center; font-family:O; font-size:84px; color:#fff; }
#endSub { left:0; right:0; top:860px; text-align:center; font-family:O; font-size:68px; color:#fff; }
</style></head><body>
<img id="base"/>
<canvas id="pix" width="54" height="96"></canvas>
<div class="l" id="vig"></div>
<canvas class="l" id="rain" width="540" height="960" style="width:1080px;height:1920px"></canvas>
<canvas class="l" id="grain" width="360" height="640" style="width:1080px;height:1920px"></canvas>
<div class="o hk sh" id="h1"><span class="y" id="w1">PEAK</span> <span class="r" id="w2">ROBLOX</span></div>
<div class="o hk sh" id="h2">HORROR GAME</div>
<div class="o hk sh" id="h3"><span id="w4">TO PLAY WITH</span> <span class="g" id="w5">FRIENDS</span></div>
<div class="o sh" id="part">${T.part}</div>
<div class="o sh" id="card"><div id="c1"><span class="g">NAME</span> : ${T.name}</div><div id="c2"><span class="y">GAMEPLAY</span> : ${T.score}</div><div id="c3"><span class="r">GENRE</span> : ${T.genre}</div></div>
<div class="o sh" id="low">${T.low}</div>
<div class="o sh" id="thought"></div>
<div class="o" id="glt">${T.glitch}</div>
<div class="l" id="black"></div>
<canvas class="l" id="noise" width="270" height="480" style="width:1080px;height:1920px; image-rendering: pixelated"></canvas>
<div class="o sh" id="endTop">${T.endTop}</div>
<div class="o sh" id="endSub">${T.endSub}</div>
<script>
const $ = (id) => document.getElementById(id);
const HT = ${JSON.stringify(T.hookTimes)};
const gctx = $('grain').getContext('2d'); const gimg = gctx.createImageData(360, 640);
const rctx = $('rain').getContext('2d');
const nctx = $('noise').getContext('2d');
const pctx = $('pix').getContext('2d'); pctx.imageSmoothingEnabled = true;
function rnd(n) { const x = Math.sin(n * 127.1 + 311.7) * 43758.5453; return x - Math.floor(x); }
window.setFrame = (f, fr) => {
  const t = f / 30;
  for (const id of ['h1','h2','h3','part','card','low','thought','glt','endTop','endSub']) $(id).style.opacity = 0;
  // footage: dark, a little crushed, a touch of chromatic edge
  let filt = 'contrast(1.1) saturate(.85) brightness(' + (fr.bright || 1.35) + ')';
  $('base').style.filter = filt;
  $('base').style.transform = 'none';
  $('pix').style.opacity = 0;
  // the scare: pixelated, grey, blown out, shaking
  if (fr.scare) {
    const b = $('base');
    pctx.drawImage(b, 0, 0, 54, 96);
    const p = $('pix'); p.style.opacity = 1;
    p.style.filter = 'grayscale(1) contrast(1.9) brightness(1.6)';
    const s = 1.08 + 0.06 * Math.sin(f * 2.1);
    p.style.transform = 'translate(' + (rnd(f) - .5) * 40 + 'px,' + (rnd(f + 3) - .5) * 40 + 'px) scale(' + s + ')';
  } else $('pix').style.transform = 'none';
  // the hook, word by word
  if (fr.section === 'hook') {
    const lt = fr.i / 30;
    $('h1').style.opacity = 1;
    $('w1').style.opacity = lt >= HT[0] ? 1 : 0;
    $('w2').style.opacity = lt >= HT[1] ? 1 : 0;
    $('h2').style.opacity = lt >= HT[2] ? 1 : 0;
    $('h3').style.opacity = lt >= HT[3] ? 1 : 0;
    $('w5').style.opacity = lt >= HT[4] ? 1 : 0;
    $('part').style.opacity = lt >= HT[5] ? 1 : 0;
  }
  // the card and the low line, for the rest (not on the end card)
  // (fr.cardLines: the lines pop in one by one with the track; without it, all at once)
  if (fr.section === 'clip') {
    const n = fr.cardLines === undefined ? 4 : fr.cardLines;
    $('card').style.opacity = n > 0 ? 1 : 0;
    ['c1', 'c2', 'c3'].forEach((id, k) => { $(id).style.visibility = n > k ? 'visible' : 'hidden'; });
    $('low').style.opacity = n >= 4 ? 1 : 0;
  }
  if (fr.thought) { const th = $('thought'); th.textContent = fr.thought; th.style.opacity = Math.min(1, fr.ti / 6); }
  // the glitch text: blue, sliced and shifted
  if (fr.glitchText) {
    const g = $('glt'); g.style.opacity = 1;
    const dx = (rnd(f) - .5) * 60, sk = (rnd(f + 7) - .5) * 30;
    g.style.transform = 'translateX(' + dx + 'px) skewX(' + sk + 'deg) scaleY(' + (3.2 + 0.9 * rnd(f + 2)) + ')';
    g.style.textShadow = (6 + rnd(f) * 10) + 'px 0 #0a1060, ' + (-8 - rnd(f + 1) * 12) + 'px 0 rgba(120,140,255,.7)';
    $('base').style.filter = 'contrast(1.2) saturate(.6) brightness(1.1)';
    $('base').style.transform = 'translateX(' + (rnd(f + 4) - .5) * 50 + 'px)';
  }
  // the end card: black, a burst of noise blocks on the way in
  $('black').style.opacity = fr.section === 'end' ? 1 : 0;
  $('noise').style.opacity = 0;
  if (fr.section === 'end') {
    const lt = fr.i / 30;
    if (lt < 0.35 || (lt > 0.9 && lt < 1.0)) {
      nctx.clearRect(0, 0, 270, 480); $('noise').style.opacity = 1;
      for (let k = 0; k < 140; k++) {
        const x = Math.floor(rnd(f * 31 + k) * 270), y = Math.floor(rnd(f * 17 + k * 3) * 480), w = 2 + Math.floor(rnd(k + f) * 14), h = 1 + Math.floor(rnd(k * 5 + f) * 4);
        const c = [[255,255,255],[255,40,60],[40,255,120],[60,120,255],[200,200,200]][k % 5];
        nctx.fillStyle = 'rgba(' + c.join(',') + ',' + (0.4 + rnd(k) * 0.6) + ')'; nctx.fillRect(x, y, w, h);
      }
    }
    if (lt >= 0.2) { $('endTop').style.opacity = 1; $('endSub').style.opacity = 1; }
  }
  // rain on the outdoor shot
  rctx.clearRect(0, 0, 540, 960);
  if (fr.rain) {
    $('rain').style.opacity = 0.55;
    rctx.strokeStyle = 'rgba(200,210,230,0.35)'; rctx.lineWidth = 1;
    for (let k = 0; k < 260; k++) {
      const x = (rnd(k * 13.1) * 600 + f * 3 + k) % 600 - 30, y = (rnd(k * 7.7) * 960 + f * 38 * (0.7 + rnd(k))) % 1000 - 40;
      rctx.beginPath(); rctx.moveTo(x, y); rctx.lineTo(x - 3, y + 26); rctx.stroke();
    }
  } else $('rain').style.opacity = 0;
  // the black at the very start, the grain everywhere
  if (t < 0.12) $('black').style.opacity = Math.max(+$('black').style.opacity, 1 - t / 0.12);
  const d = gimg.data;
  for (let k = 0; k < d.length; k += 4) { const v = (128 + (Math.random() - 0.5) * 170) | 0; d[k] = d[k + 1] = d[k + 2] = v; d[k + 3] = 255; }
  gctx.putImageData(gimg, 0, 0);
};
</script></body></html>`;

const browser = await chromium.launch({ executablePath: '/opt/pw-browsers/chromium-1194/chrome-linux/chrome' });
const page = await browser.newPage({ viewport: { width: 1080, height: 1920 } });
await page.setContent(html);
await page.evaluate(() => document.fonts.ready);
const from = +(fromArg ?? 0), to = Math.min(+(toArg ?? NF - 1), NF - 1);
for (let f = from; f <= to; f++) {
  const fr = edit.frames[f];
  const img = fr.src && fs.existsSync(fr.src) ? 'data:image/png;base64,' + fs.readFileSync(fr.src).toString('base64') : '';
  await page.evaluate(async ([img, f, fr]) => {
    const b = document.getElementById('base');
    if (img) { b.src = img; await b.decode(); }
    window.setFrame(f, fr);
  }, [img, f, fr]);
  fs.writeFileSync(`${outDir}/${String(f).padStart(4, '0')}.png`, await page.screenshot({ type: 'png' }));
  if (f % 60 === 0) console.log('comp', f);
}
await browser.close();
