// node comp_find.mjs edit.json outDir [from] [to] — reel 54's "FIND HIM" challenge format (not the orange #N captions): a
// level badge (LEVEL n/4 + EASY / MEDIUM / HARD / IMPOSSIBLE in its colour), a timer bar running out, then a red ring that
// snaps onto him while the shot punches in on his face; the brand tag every frame (NEW ROBLOX HORROR GAME + the name); the
// hook ("FIND HIM" / "only 1% find him on level 4") over level 1; the scare (fr.scare: shake, flash, red); the end card (the
// name, SEARCH IT ON ROBLOX with the search bar, COMMENT YOUR LEVEL).
// edit.json: { frames: [{ src, sec: 'lvl'|'end', lvl, i, n, search, target: [x, y] | null, scare }], levels: [{ name, col }] }
import { chromium } from 'playwright';
import fs from 'fs';
const [,, editPath, outDir, fromArg, toArg] = process.argv;
const edit = JSON.parse(fs.readFileSync(editPath, 'utf8'));
fs.mkdirSync(outDir, { recursive: true });
const NF = edit.frames.length;
const FD = new URL('../../fonts/', import.meta.url);
const font = (f) => 'data:font/ttf;base64,' + fs.readFileSync(new URL(f, FD)).toString('base64');
const LV = edit.levels;
const NAME = 'someone lives in our attic.';

const html = `<!doctype html><html><head><style>
@font-face { font-family: O; src: url(${font('Outfit-Bold.ttf')}); }
@font-face { font-family: OR; src: url(${font('Outfit-Regular.ttf')}); }
@font-face { font-family: L; src: url(${font('Lora-Bold.ttf')}); }
html,body { margin:0; width:1080px; height:1920px; overflow:hidden; background:#000; }
#stage { position:absolute; inset:0; overflow:hidden; }
#base { position:absolute; inset:0; width:1080px; height:1920px; }
.l { position:absolute; inset:0; }
#vig { background: radial-gradient(ellipse 85% 70% at 50% 45%, rgba(0,0,0,0) 55%, rgba(0,0,0,.45) 85%, rgba(0,0,0,.8) 100%); }
#grain { mix-blend-mode: soft-light; opacity:.12; }
#red { background: radial-gradient(ellipse 70% 60% at 50% 45%, rgba(255,0,0,0) 30%, rgba(200,0,0,.75) 100%); opacity:0; }
#flash { background:#fff; opacity:0; }
#black { background:#000; opacity:0; }
.o { position:absolute; opacity:0; }
.st { -webkit-text-stroke: 12px #000; paint-order: stroke fill; }
/* the brand, every frame */
#tag { left:50%; top:120px; transform:translateX(-50%); background:#e01919; color:#fff; font-family:O; font-size:34px; letter-spacing:3px;
       padding:10px 22px 8px; border-radius:8px; white-space:nowrap; opacity:1; }
#tagname { left:0; right:0; top:186px; text-align:center; font-family:L; font-size:44px; color:#fff; opacity:1;
           -webkit-text-stroke: 8px #000; paint-order: stroke fill; }
/* the level badge */
#lv { left:0; right:0; top:290px; text-align:center; }
#lvn { font-family:O; font-size:64px; color:#fff; letter-spacing:4px; -webkit-text-stroke: 12px #000; paint-order: stroke fill; }
#lvd { display:inline-block; margin-top:10px; font-family:O; font-size:58px; letter-spacing:6px; color:#000; padding:8px 34px 4px; border-radius:12px;
       border:6px solid #000; }
/* the timer: a bar running out + the seconds */
#tm { left:150px; right:150px; top:1430px; height:34px; border:6px solid #000; border-radius:22px; background:rgba(255,255,255,.18); overflow:hidden; }
#tmf { position:absolute; left:0; top:0; bottom:0; border-radius:16px; }
#tms { left:0; right:0; top:1300px; text-align:center; font-family:O; font-size:110px; color:#fff; -webkit-text-stroke: 14px #000; paint-order: stroke fill; }
/* the hook */
#h1 { left:0; right:0; top:1020px; text-align:center; font-family:O; font-size:184px; line-height:1; color:#fff; letter-spacing:4px;
      -webkit-text-stroke: 18px #000; paint-order: stroke fill; white-space:nowrap; }
#h2 { left:40px; right:40px; top:1250px; text-align:center; font-family:O; font-size:66px; line-height:1.15; color:#fff;
      -webkit-text-stroke: 12px #000; paint-order: stroke fill; }
#h2 b { color:#ff2a2a; }
/* the reveal ring */
#ring { width:200px; height:200px; margin:-100px 0 0 -100px; border-radius:50%; border:12px solid #ff1f1f;
        box-shadow: 0 0 0 5px #000, inset 0 0 0 5px #000, 0 0 40px rgba(255,0,0,.6); }
#found { font-family:O; font-size:70px; color:#ff2a2a; -webkit-text-stroke: 12px #000; paint-order: stroke fill; white-space:nowrap; }
/* the end card */
#eName { left:0; right:0; top:560px; text-align:center; font-family:L; font-size:96px; line-height:1.1; color:#fff; }
#eSub { left:0; right:0; top:820px; text-align:center; font-family:O; font-size:46px; letter-spacing:6px; color:#e01919; }
#eBar { left:110px; right:110px; top:930px; height:120px; border-radius:60px; background:#fff; border:6px solid #000; }
#eIcon { position:absolute; left:40px; top:28px; width:40px; height:40px; border:8px solid #555; border-radius:50%; }
#eIcon:after { content:''; position:absolute; left:40px; top:44px; width:26px; height:9px; background:#555; transform:rotate(45deg); }
#eTyped { position:absolute; left:130px; top:26px; font-family:OR; font-size:54px; color:#111; white-space:nowrap; }
#eFree { left:0; right:0; top:1110px; text-align:center; font-family:O; font-size:40px; letter-spacing:4px; color:#ddd; }
#eAsk { left:0; right:0; top:1300px; text-align:center; font-family:O; font-size:76px; line-height:1.15; color:#fff;
        -webkit-text-stroke: 12px #000; paint-order: stroke fill; }
#eAsk b { color:#ff2a2a; }
</style></head><body>
<svg width="0" height="0" style="position:absolute">${[['lift', 0.62], ['liftLow', 0.8]].map(([id, e]) => `<filter id="${id}" color-interpolation-filters="sRGB"><feComponentTransfer>
  <feFuncR type="gamma" amplitude="1" exponent="${e}"/><feFuncG type="gamma" amplitude="1" exponent="${e}"/><feFuncB type="gamma" amplitude="1" exponent="${e}"/>
</feComponentTransfer></filter>`).join('')}</svg>
<div id="stage">
  <img id="base"/>
  <div class="l" id="vig"></div>
  <canvas class="l" id="grain" width="540" height="960" style="width:1080px;height:1920px"></canvas>
  <div class="l" id="red"></div>
  <div class="o" id="ring"></div>
  <div class="o" id="found">THERE.</div>
  <div class="o" id="lv"><div id="lvn"></div><div id="lvd"></div></div>
  <div class="o" id="tm"><div id="tmf"></div></div>
  <div class="o" id="tms"></div>
  <div class="o" id="h1">FIND HIM</div>
  <div class="o" id="h2">only <b>1%</b> find him on level 4</div>
  <div class="o" id="eName">someone lives<br/>in our attic.</div>
  <div class="o" id="eSub">NEW ROBLOX HORROR GAME</div>
  <div class="o" id="eBar"><div id="eIcon"></div><div id="eTyped"></div></div>
  <div class="o" id="eFree">SEARCH IT ON ROBLOX · FREE · 1-4 PLAYERS</div>
  <div class="o" id="eAsk">what level did<br/>you find him on? <b>↓</b></div>
  <div class="o" id="tag">NEW ROBLOX HORROR GAME</div>
  <div class="o" id="tagname">${NAME}</div>
  <div class="l" id="flash"></div>
  <div class="l" id="black"></div>
</div>
<script>
const $ = (id) => document.getElementById(id);
const clamp = (x, a, b) => Math.max(a, Math.min(b, x));
const seg = (t, a, b) => clamp((t - a) / (b - a), 0, 1);
const back = (x) => { x = clamp(x, 0, 1); const c = 1.9; return 1 + (c + 1) * Math.pow(x - 1, 3) + c * Math.pow(x - 1, 2); };
const ease = (x) => { x = clamp(x, 0, 1); return x * x * (3 - 2 * x); };
function rnd(n) { const x = Math.sin(n * 127.1 + 311.7) * 43758.5453; return x - Math.floor(x); }
const g = $('grain').getContext('2d'); const gi = g.createImageData(540, 960);
const LV = ${JSON.stringify(LV)};
const ALL = ['ring','found','lv','tm','tms','h1','h2','eName','eSub','eBar','eFree','eAsk'];
window.setFrame = (f, fr) => {
  for (const id of ALL) $(id).style.opacity = 0;
  const i = fr.i, S = fr.search;
  // (a gamma lift first: the rooms are near black, and a plain brightness would blow his mask out before they read)
  let filt = 'url(#' + (fr.lift || 'lift') + ') contrast(1.12) saturate(.85) brightness(' + (fr.bright || 1.35) + ')';
  let zoom = 1, ox = 540, oy = 860, mx = 0, my = 0, sh = 0, fl = 0, red = 0, bk = 0;
  $('tag').style.opacity = 1; $('tagname').style.opacity = 1;
  if (fr.sec === 'lvl') {
    const L = LV[fr.lvl];
    // ---- the level badge: slams in at the cut
    const kb = seg(i, 0, 6);
    $('lv').style.opacity = 1;
    $('lv').style.transform = 'scale(' + (1.5 - 0.5 * back(kb)) + ')';
    $('lvn').textContent = 'LEVEL ' + (fr.lvl + 1) + '/4';
    $('lvd').textContent = L.name; $('lvd').style.background = L.col;
    if (fr.lvl > 0) fl = Math.max(fl, 0.5 * (1 - seg(i, 0, 4)));
    // ---- the timer runs out
    if (i < S) {
      const left = 1 - i / S;
      $('tm').style.opacity = 1; $('tms').style.opacity = 1;
      const tf = $('tmf'); tf.style.width = (100 * left) + '%';
      tf.style.background = left < 0.34 ? '#ff2a2a' : L.col;
      const secs = Math.ceil((S - i) / 30);
      $('tms').textContent = secs;
      const since = (30 - (S - i) % 30) % 30;         // each new second pops
      $('tms').style.transform = 'scale(' + (1 + 0.22 * (1 - seg(since, 0, 5))) + ')';
      $('tms').style.color = secs <= 1 ? '#ff2a2a' : '#fff';
    }
    // ---- the hook over level 1
    if (fr.lvl === 0 && i < 96) {
      // (on screen from the very first frame: it's the thumbnail and the scroll-stopper)
      const k1 = seg(i, 0, 6), k2 = seg(i, 12, 18), out = 1 - seg(i, 86, 95);
      $('h1').style.opacity = out; $('h1').style.transform = 'scale(' + (1.1 - 0.1 * back(k1)) + ')';
      $('h2').style.opacity = (k2 > 0 ? 1 : 0) * out; $('h2').style.transform = 'translateY(' + (30 * (1 - back(k2))) + 'px)';
      $('tm').style.opacity = 0; $('tms').style.opacity = 0;
    }
    // ---- the reveal: the ring snaps onto him, the shot punches in on his face
    if (i >= S && fr.target && !fr.scare) {
      const [tx, ty] = fr.target;
      const kz = ease(seg(i, S + 3, S + 15));
      // (the punch-in also pulls him to the middle of the screen, clear of the badge)
      zoom = 1 + (fr.zoom - 1) * kz; ox = tx; oy = ty; mx = (540 - tx) * kz; my = (900 - ty) * kz;
      const rx = tx + mx, ry = ty + my;
      const kr = seg(i, S, S + 5);
      const r = $('ring'); r.style.opacity = 1;
      r.style.left = rx + 'px'; r.style.top = ry + 'px';
      const rs = (2.6 - 1.6 * back(kr)) * zoom * (fr.ring || 1);
      r.style.transform = 'scale(' + rs + ')';
      const kf = seg(i, S + 6, S + 10), fd = $('found');
      fd.style.opacity = kf > 0 ? 1 : 0;
      fd.style.left = clamp(rx - 130, 40, 760) + 'px';
      fd.style.top = (ry + 110 * zoom * (fr.ring || 1)) + 'px';
      fd.style.transform = 'scale(' + (1.4 - 0.4 * back(kf)) + ') rotate(-4deg)';
      if (i < S + 3) fl = Math.max(fl, 0.35 * (1 - seg(i, S, S + 3)));
      $('lv').style.opacity = 1;
    }
    // ---- the scare: the mask drops at you
    if (fr.scare) {
      const k = fr.scare;                             // frames since the drop
      sh = k < 22 ? 34 * (1 - k / 26) : 0;
      fl = Math.max(fl, 0.95 * (1 - seg(k, 0, 5)));
      red = k < 4 ? 0 : 0.85 * (1 - seg(k, 4, 30)) + 0.25 * Math.max(0, Math.sin(k * 1.3));
      filt = 'contrast(1.3) saturate(1.2) brightness(1.15)';
      $('lv').style.opacity = 0; $('tag').style.opacity = 0; $('tagname').style.opacity = 0;
    }
  }
  if (fr.sec === 'end') {
    filt = 'contrast(1.1) saturate(.5) brightness(.32) blur(6px)'; zoom = 1.1;
    const t = i / 30;
    $('tag').style.opacity = 0; $('tagname').style.opacity = 0;
    const kn = seg(t, 0.05, 0.3); $('eName').style.opacity = kn; $('eName').style.transform = 'scale(' + (1.2 - 0.2 * back(kn)) + ')';
    $('eSub').style.opacity = seg(t, 0.25, 0.45);
    const kb = seg(t, 0.4, 0.6); $('eBar').style.opacity = kb; $('eBar').style.transform = 'scale(' + (0.8 + 0.2 * back(kb)) + ')';
    const typed = 'someone lives in our attic';
    const nch = Math.floor(clamp((t - 0.6) / 0.9, 0, 1) * typed.length);
    $('eTyped').textContent = typed.slice(0, nch) + ((Math.floor(t * 4) % 2) ? '|' : '');
    $('eFree').style.opacity = seg(t, 1.0, 1.2);
    const ka = seg(t, 1.2, 1.4); $('eAsk').style.opacity = ka; $('eAsk').style.transform = 'translateY(' + (30 * (1 - back(ka))) + 'px)';
    if (t < 0.12) fl = 0.6 * (1 - seg(t, 0, 0.12));
  }
  $('base').style.filter = filt;
  const sx = (rnd(f) - .5) * sh, sy = (rnd(f + 9) - .5) * sh;
  $('base').style.transformOrigin = ox + 'px ' + oy + 'px';
  $('base').style.transform = 'translate(' + (sx + mx) + 'px,' + (sy + my) + 'px) scale(' + zoom + ')';
  $('red').style.opacity = red;
  $('flash').style.opacity = fl;
  if (fr.fadeOut) bk = fr.fadeOut;
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
  await page.evaluate(async ([img, f, fr]) => {
    const b = document.getElementById('base');
    if (img) { b.src = img; await b.decode(); }
    window.setFrame(f, fr);
  }, [img, f, fr]);
  fs.writeFileSync(`${outDir}/${String(f).padStart(4, '0')}.png`, await page.screenshot({ type: 'png' }));
  if (f % 60 === 0) console.log('comp', f);
}
await browser.close();
