// node comp_story.mjs edit.json outDir [from] [to] — the "story" format (reel 33): a short first-person
// story told in typed lines over found footage. Lowercase serif captions in the lower middle, typed
// in letter by letter, one word in red; a camcorder overlay (REC, the date and time, a faint scanline
// and colour bleed); the jumpscare as a negative flash into a shaking, red, blown-out frame; "RUN." huge
// and red; a black end card. Film grain and a vignette throughout.
// edit.json: { frames: [{ src, section, i, cap: [lines], capT, scare, scareI, run, runI }], text: {...} }
//   cap: the caption's lines; each line is [[text, red?], ...] chunks; capT: seconds since it started
//   typing (or a list of reveal times per chunk in the hook: chunkTimes)
import { chromium } from 'playwright';
import fs from 'fs';
const [,, editPath, outDir, fromArg, toArg] = process.argv;
const edit = JSON.parse(fs.readFileSync(editPath, 'utf8'));
fs.mkdirSync(outDir, { recursive: true });
const NF = edit.frames.length;
const FD = '/mnt/skills/examples/canvas-design/canvas-fonts/';
const font = (f) => 'data:font/ttf;base64,' + fs.readFileSync(FD + f).toString('base64');
const T = Object.assign({ endTitle: 'someone lives in our attic.', endSub: 'search it on roblox.', date: 'OCT 31 2026', time0: [3, 12, 7] }, edit.text || {});

const html = `<!doctype html><html><head><style>
@font-face { font-family: S; src: url(${font('LibreBaskerville-Regular.ttf')}); }
@font-face { font-family: SI; src: url(${font('Lora-Italic.ttf')}); }
@font-face { font-family: SB; src: url(${font('Lora-Bold.ttf')}); }
@font-face { font-family: M; src: url(${font('DMMono-Regular.ttf')}); }
html,body { margin:0; width:1080px; height:1920px; overflow:hidden; background:#000; }
#base, #inv { position:absolute; inset:0; width:1080px; height:1920px; object-fit:cover; }
#red, #blue { position:absolute; inset:0; width:1080px; height:1920px; object-fit:cover; mix-blend-mode:screen; opacity:0; }
.l { position:absolute; inset:0; }
#vig { background: radial-gradient(ellipse 78% 64% at 50% 48%, rgba(0,0,0,0) 52%, rgba(0,0,0,.4) 86%, rgba(0,0,0,.72) 100%); }
#scan { background: repeating-linear-gradient(0deg, rgba(0,0,0,.16) 0px, rgba(0,0,0,.16) 2px, rgba(0,0,0,0) 2px, rgba(0,0,0,0) 5px); opacity:.5; }
#grain { mix-blend-mode: overlay; opacity:.24; }
#flash { background:#fff; opacity:0; }
#tint { background:#b00010; mix-blend-mode:multiply; opacity:0; }
#black { background:#000; opacity:0; }
.o { position:absolute; opacity:0; }
.sh { text-shadow: 0 3px 12px rgba(0,0,0,.95), 0 0 4px rgba(0,0,0,.95); }
/* the camcorder */
#rec { left:70px; top:120px; font-family:M; font-size:40px; color:#f2f2f2; letter-spacing:3px; }
#dot { display:inline-block; width:26px; height:26px; border-radius:50%; background:#e32020; margin-right:14px; vertical-align:-2px; }
#stamp { right:70px; top:120px; text-align:right; font-family:M; font-size:36px; color:#f2f2f2; line-height:46px; letter-spacing:2px; }
#play { left:70px; bottom:150px; font-family:M; font-size:34px; color:#f2f2f2; letter-spacing:3px; }
/* the story */
#capbg { left:0; right:0; top:1060px; height:420px; background: radial-gradient(ellipse 60% 50% at 50% 50%, rgba(0,0,0,.55), rgba(0,0,0,0) 100%); }
#cap { left:70px; right:70px; top:1170px; text-align:center; font-family:S; font-size:72px; line-height:96px; color:#f4f1ea; }
#cap .r { color:#e3262b; }
#cap .ln { white-space:nowrap; }
#run { left:0; right:0; top:760px; text-align:center; font-family:SB; font-size:300px; letter-spacing:-6px; color:#e3262b; }
/* the end card */
#endTitle { left:60px; right:60px; top:820px; text-align:center; font-family:S; font-size:70px; color:#f4f1ea; }
#endSub { left:0; right:0; top:960px; text-align:center; font-family:SI; font-size:52px; color:#e3262b; }
</style></head><body>
<img id="base"/><img id="red"/><img id="blue"/>
<div class="l" id="tint"></div>
<div class="l" id="scan"></div>
<div class="l" id="vig"></div>
<canvas class="l" id="grain" width="360" height="640" style="width:1080px;height:1920px"></canvas>
<div class="o sh" id="rec"><span id="dot"></span>REC</div>
<div class="o sh" id="stamp"><div>${T.date}</div><div id="clock"></div></div>
<div class="o sh" id="play">PLAY &#9654;</div>
<div class="o" id="capbg"></div>
<div class="o sh" id="cap"></div>
<div class="o sh" id="run">RUN.</div>
<div class="l" id="flash"></div>
<div class="l" id="black"></div>
<canvas class="l" id="noise" width="270" height="480" style="width:1080px;height:1920px; image-rendering: pixelated; opacity:0"></canvas>
<div class="o sh" id="endTitle">${T.endTitle}</div>
<div class="o sh" id="endSub">${T.endSub}</div>
<script>
const $ = (id) => document.getElementById(id);
const gctx = $('grain').getContext('2d'); const gimg = gctx.createImageData(360, 640);
const nctx = $('noise').getContext('2d');
const T0 = ${JSON.stringify(T.time0)};
function rnd(n) { const x = Math.sin(n * 127.1 + 311.7) * 43758.5453; return x - Math.floor(x); }
function esc(s) { return s.replace(/&/g, '&amp;').replace(/</g, '&lt;'); }
// a caption, typed: fr.cap = [[ [text, red], ... ], ...]; shown up to n characters
function caption(lines, n) {
  let left = n, out = [];
  for (const line of lines) {
    let html = '';
    for (const [txt, red] of line) {
      const take = Math.max(0, Math.min(txt.length, left)); left -= txt.length;
      const shown = esc(txt.slice(0, take)), hidden = esc(txt.slice(take));
      html += (red ? '<span class="r">' : '<span>') + shown + '</span><span style="visibility:hidden">' + hidden + '</span>';
    }
    out.push('<div class="ln">' + html + '</div>');
  }
  return out.join('');
}
window.setFrame = (f, fr) => {
  const t = f / 30;
  for (const id of ['rec','stamp','play','cap','capbg','run','endTitle','endSub']) $(id).style.opacity = 0;
  const b = $('base');
  b.style.filter = 'contrast(1.12) saturate(.78) brightness(' + (fr.bright || 1.3) + ')';
  b.style.transform = 'none';
  // colour bleed: a red copy nudged left, a blue copy nudged right
  for (const [id, dx, col] of [['red', -4, 'sepia(1) saturate(6) hue-rotate(-50deg)'], ['blue', 4, 'sepia(1) saturate(6) hue-rotate(180deg)']]) {
    const e = $(id); e.style.opacity = 0.16; e.style.filter = col + ' brightness(.7)'; e.style.transform = 'translateX(' + dx + 'px)';
  }
  $('flash').style.opacity = 0; $('tint').style.opacity = 0;
  // the camcorder, everywhere but the end card
  if (fr.section !== 'end') {
    $('rec').style.opacity = 1; $('dot').style.opacity = (Math.floor(t * 1.6) % 2) ? 0.15 : 1;
    $('stamp').style.opacity = 1;
    const s = T0[2] + Math.floor(t), m = T0[1] + Math.floor(s / 60), h = T0[0];
    $('clock').textContent = h + ':' + String(m % 60).padStart(2, '0') + ':' + String(s % 60).padStart(2, '0') + ' AM';
    if (t < 1.2) $('play').style.opacity = 1;
  }
  // the story line, typed in
  if (fr.cap) {
    const c = $('cap');
    let n;
    if (fr.chunkTimes) {
      // (the hook: whole chunks appear on the music box's notes)
      n = 0; let k = 0;
      for (const line of fr.cap) for (const [txt] of line) { if (fr.capT >= fr.chunkTimes[k]) n += txt.length; k++; }
    } else n = Math.floor(fr.capT * (fr.capSpeed || 34));
    c.innerHTML = caption(fr.cap, n);
    c.style.opacity = fr.capFade === undefined ? 1 : fr.capFade;
    $('capbg').style.opacity = c.style.opacity;
  }
  // the scare: a negative flash, then his face blown out red, shaking, the frame torn
  if (fr.scare) {
    const k = fr.scareI;
    if (k < 2) { b.style.filter = 'invert(1) contrast(1.6) brightness(1.4)'; $('flash').style.opacity = 0.25; }
    else {
      b.style.filter = 'grayscale(.4) contrast(1.9) brightness(' + (1.8 - 0.06 * k) + ')';
      $('tint').style.opacity = 0.55;
      const sc = 1.12 + 0.05 * Math.sin(k * 2.3);
      b.style.transform = 'translate(' + (rnd(f) - .5) * 70 + 'px,' + (rnd(f + 3) - .5) * 70 + 'px) scale(' + sc + ') rotate(' + (rnd(f + 9) - .5) * 4 + 'deg)';
      $('red').style.opacity = 0.45; $('red').style.transform = 'translateX(' + (-18 - rnd(f) * 20) + 'px) scale(' + sc + ')';
      $('blue').style.opacity = 0.4; $('blue').style.transform = 'translateX(' + (18 + rnd(f + 1) * 20) + 'px) scale(' + sc + ')';
    }
  }
  // RUN.
  if (fr.run) {
    const r = $('run'); r.style.opacity = 1;
    r.style.transform = 'translate(' + (rnd(f) - .5) * 26 + 'px,' + (rnd(f + 5) - .5) * 20 + 'px) scale(' + (1 + 0.04 * rnd(f + 2)) + ')';
    b.style.transform = 'translateX(' + (rnd(f + 4) - .5) * 30 + 'px)';
  }
  // the end card: black, a burst of tape noise on the way in
  $('black').style.opacity = fr.section === 'end' ? 1 : 0;
  $('noise').style.opacity = 0;
  if (fr.section === 'end') {
    const lt = fr.i / 30;
    if (lt < 0.4 || (lt > 1.6 && lt < 1.7)) {
      nctx.clearRect(0, 0, 270, 480); $('noise').style.opacity = 1;
      for (let k = 0; k < 220; k++) {
        const x = Math.floor(rnd(f * 31 + k) * 270), y = Math.floor(rnd(f * 17 + k * 3) * 480), w = 4 + Math.floor(rnd(k + f) * 40), h = 1 + Math.floor(rnd(k * 5 + f) * 2);
        const v = 120 + Math.floor(rnd(k * 3 + f) * 135);
        nctx.fillStyle = 'rgba(' + v + ',' + v + ',' + v + ',' + (0.5 + rnd(k) * 0.5) + ')'; nctx.fillRect(x, y, w, h);
      }
    }
    if (lt >= 0.3) { $('endTitle').style.opacity = Math.min(1, (lt - 0.3) / 0.4); }
    if (lt >= 1.2) { $('endSub').style.opacity = Math.min(1, (lt - 1.2) / 0.4); }
  }
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
    for (const id of ['base', 'red', 'blue']) {
      const e = document.getElementById(id);
      if (img) { e.src = img; await e.decode(); } else e.removeAttribute('src');
    }
    window.setFrame(f, fr);
  }, [img, f, fr]);
  fs.writeFileSync(`${outDir}/${String(f).padStart(4, '0')}.png`, await page.screenshot({ type: 'png' }));
  if (f % 60 === 0) console.log('comp', f);
}
await browser.close();
