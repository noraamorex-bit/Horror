// node comp_peak.mjs edit.json outDir [from] [to] — the "PEAK ROBLOX HORROR GAME TO PLAY WITH FRIENDS"
// format (reel 23, the owner's reference): slow first-person footage; the hook word by word in the
// upper middle with soft shadows (PEAK yellow, ROBLOX red, HORROR GAME white, TO PLAY WITH / FRIENDS
// green, "(Part 1)"); then a small three-line card pinned at the top (NAME / GAMEPLAY / GENRE, coloured
// labels) and one spaced-out line low in the frame; the jumpscare pixelated and grey; a blue glitch-text
// flash; a noise-block glitch into the black end card. Film grain, vignette, rain on the outdoor shot.
// edit.json: { frames: [{ src, section, i, rain, thought, scare, scareI, glitchText, cardLines, hud }], text: {...} }
// brand (v100 rule: every reel says plainly it's a new Roblox game, with the name): a red NEW ROBLOX
// HORROR GAME tag on every clip (the name under it on the hook; the card carries it after), and the end
// card with the name big, a search bar typing it in, free, with friends. text.brand: false = the old look.
// hud (reel 36, "simulate gameplay"): the game's own HUD drawn over the footage, as on a phone:
//   { obj: 'objective text', sel: hotbar slot (1-based), stam: 0..1 (the sprint bar), hb: seconds into
//     the heartbeat minigame, hbHint, notice: 'text', chat: [[name, colour, message], ...] }
// scareI (frames since the scare began): the first 3 pixelated and blown out, then the real frame,
// shaking, punched in, with a red flash.
import { chromium } from 'playwright';
import fs from 'fs';
const [,, editPath, outDir, fromArg, toArg] = process.argv;
const edit = JSON.parse(fs.readFileSync(editPath, 'utf8'));
fs.mkdirSync(outDir, { recursive: true });
const NF = edit.frames.length;
const FD = new URL('../../fonts/', import.meta.url).pathname;
const font = (f) => 'data:font/ttf;base64,' + fs.readFileSync(FD + f).toString('base64');
const T = Object.assign({ name: 'someone lives in our attic.', score: '10.5/10', genre: 'Survival Horror', low: 'OUT NOW',
  part: '(Part 1)', endTop: 'Out Now', endSub: 'someone lives in our attic.', glitch: 'he lives in the attic', hookTimes: [0.0, 0.5, 1.0, 1.55, 2.5, 3.4],
  brand: true, tag: 'NEW ROBLOX HORROR GAME', items: [['flashlight', ''], ['taser', '3']] }, edit.text || {});
const ICON = {
  flashlight: '<svg viewBox="0 0 64 64"><g transform="rotate(-40 32 32)"><rect x="24" y="22" width="16" height="34" rx="3" fill="#3a3a42" stroke="#111" stroke-width="2"/><path d="M20 8h24l-4 15H24z" fill="#55555f" stroke="#111" stroke-width="2"/><rect x="22" y="5" width="20" height="5" rx="2" fill="#fff3c4"/><rect x="29" y="30" width="6" height="8" rx="1" fill="#c9c9cf"/></g></svg>',
  taser: '<svg viewBox="0 0 64 64"><g transform="rotate(-20 32 32)"><path d="M8 20h40l6 5v8H8z" fill="#f2c82a" stroke="#111" stroke-width="2"/><path d="M14 33h14l-4 22H12z" fill="#222" stroke="#111" stroke-width="2"/><rect x="8" y="24" width="40" height="4" fill="#222"/><path d="M54 22l6-4M54 30l6 4" stroke="#8fd3ff" stroke-width="3"/></g></svg>',
};

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
/* the brand: the tag on every clip, the name under it on the hook (the card has it after) */
#brand { left:0; right:0; top:178px; text-align:center; }
#tag { display:inline-block; background:#e3262b; color:#fff; font-family:O; font-size:40px; letter-spacing:3px; padding:10px 26px 8px; border-radius:10px; box-shadow:0 4px 18px rgba(0,0,0,.6); }
#bname { left:0; right:0; top:268px; text-align:center; font-family:O; font-size:60px; color:#fff; }
#bname .r, #e2name .r { color:#e3262b; }
body.brand #card { top:282px; }
/* the branded end card */
#e2 { left:60px; right:60px; top:560px; text-align:center; }
#e2tag { display:inline-block; background:#e3262b; color:#fff; font-family:O; font-size:46px; letter-spacing:4px; padding:14px 30px 12px; border-radius:12px; }
#e2name { margin-top:44px; font-family:O; font-size:124px; line-height:132px; color:#fff; }
#e2on { margin-top:70px; font-family:O; font-size:40px; letter-spacing:3px; color:#bdbdc4; }
#e2bar { margin:22px auto 0; width:900px; height:112px; border-radius:56px; background:#f4f4f6; display:flex; align-items:center; box-shadow:0 6px 30px rgba(0,0,0,.6); }
#e2glass { width:44px; height:44px; margin:0 26px 0 40px; border:7px solid #505058; border-radius:50%; position:relative; box-sizing:border-box; flex:none; }
#e2glass::after { content:''; position:absolute; width:7px; height:22px; background:#505058; right:-9px; bottom:-17px; transform:rotate(-45deg); border-radius:3px; }
#e2q { font-family:OR; font-size:46px; color:#18181c; white-space:nowrap; text-shadow:none; }
#e2cur { display:inline-block; width:4px; height:50px; background:#18181c; vertical-align:-8px; margin-left:3px; }
#e2foot { margin-top:60px; font-family:O; font-size:38px; letter-spacing:2px; color:#fff; white-space:nowrap; }
/* the game's HUD (monochrome, dark boxes, as in the game on a phone) */
#hud { left:0; top:0; width:1080px; height:1920px; }
#obj { position:absolute; right:36px; top:520px; width:330px; background:rgba(8,8,10,.62); border-radius:12px; padding:14px 18px 16px; box-sizing:border-box; }
#objL { font-family:O; font-size:22px; letter-spacing:3px; color:#a9a9b0; }
#objT { margin-top:6px; font-family:O; font-size:33px; line-height:39px; color:#fff; }
#objT b { color:#ffd84a; }
#chat { position:absolute; left:36px; top:520px; width:470px; background:rgba(8,8,10,.42); border-radius:12px; padding:10px 16px 12px; box-sizing:border-box; font-family:OR; font-size:30px; line-height:40px; color:#f2f2f2; }
#chat .n { font-family:O; }
#hot { position:absolute; left:0; right:0; top:1428px; display:flex; justify-content:center; gap:14px; }
.slot { position:relative; width:104px; height:104px; border-radius:10px; background:rgba(28,28,32,.66); box-sizing:border-box; border:3px solid rgba(255,255,255,0); }
.slot.on { border-color:#fff; background:rgba(60,60,66,.7); }
.slot svg { position:absolute; left:14px; top:14px; width:76px; height:76px; }
.slot .k { position:absolute; left:8px; top:3px; font-family:O; font-size:22px; color:#ddd; }
.slot .c { position:absolute; right:8px; bottom:3px; font-family:O; font-size:24px; color:#fff; }
#stam { position:absolute; left:390px; top:1404px; width:300px; height:9px; border-radius:5px; background:rgba(255,255,255,.18); overflow:hidden; }
#stamF { height:100%; background:#f2f2f2; border-radius:5px; }
#hb { position:absolute; left:190px; top:1010px; width:700px; height:260px; }
#hbLane { position:absolute; left:40px; top:106px; width:620px; height:6px; border-radius:3px; background:rgba(255,255,255,.18); }
#hbHeart { position:absolute; left:285px; top:44px; width:130px; height:130px; text-align:center; font-family:O; font-size:128px; line-height:130px; color:#e6283c; text-shadow:0 0 6px rgba(0,0,0,.8); }
.half { position:absolute; top:61px; width:48px; height:96px; overflow:hidden; font-family:O; font-size:96px; line-height:96px; }
.half span { position:absolute; top:0; width:96px; text-align:center; }
#hbMiss { position:absolute; left:0; right:0; top:182px; text-align:center; font-family:O; font-size:30px; letter-spacing:6px; color:#ff7878; }
#hbHint { position:absolute; left:-60px; right:-60px; top:222px; text-align:center; font-family:OR; font-size:27px; color:#eee; }
#note { position:absolute; left:0; right:0; top:1236px; text-align:center; }
#noteB { display:inline-block; background:rgba(8,8,10,.75); color:#fff; font-family:O; font-size:34px; padding:14px 30px; border-radius:12px; }
#redf { background:#c0101a; mix-blend-mode:multiply; opacity:0; }
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
<div class="o" id="hud"><div id="chat"></div><div id="obj"><div id="objL">OBJECTIVE</div><div id="objT"></div></div>
<div id="stam"><div id="stamF"></div></div>
<div id="hot">${T.items.map(([k, c], j) => `<div class="slot" id="slot${j + 1}"><div class="k">${j + 1}</div>${ICON[k] || ''}<div class="c">${c}</div></div>`).join('')}</div>
<div id="hb"><div id="hbLane"></div><div id="hbHalves"></div><div id="hbHeart">♥</div><div id="hbMiss">· · ·</div><div id="hbHint"></div></div>
<div id="note"><span id="noteB"></span></div></div>
<div class="l" id="redf"></div>
<div class="o" id="brand"><div id="tag">${T.tag}</div></div>
<div class="o sh" id="bname">${T.name.replace('attic.', '<span class="r">attic.</span>')}</div>
<div class="l" id="black"></div>
<canvas class="l" id="noise" width="270" height="480" style="width:1080px;height:1920px; image-rendering: pixelated"></canvas>
<div class="o sh" id="endTop">${T.endTop}</div>
<div class="o sh" id="endSub">${T.endSub}</div>
<div class="o sh" id="e2"><div id="e2tag">${T.tag}</div><div id="e2name">someone lives<br>in our <span class="r">attic.</span></div>
<div id="e2on">SEARCH IT ON ROBLOX</div><div id="e2bar"><div id="e2glass"></div><span id="e2q"></span><span id="e2cur"></span></div>
<div id="e2foot">FREE &nbsp;·&nbsp; 1-4 PLAYERS &nbsp;·&nbsp; WITH FRIENDS</div></div>
<script>
const $ = (id) => document.getElementById(id);
const HT = ${JSON.stringify(T.hookTimes)};
const BRAND = ${!!T.brand};
if (BRAND) document.body.classList.add('brand');
// the heartbeat minigame: a beat every 0.75 s, the halves flying 0.9 s along the lane to the heart
const BEATS = []; for (let k = 0; k < 40; k++) BEATS.push({ T: 0.9 + k * 0.75, side: 'LRRLRLLR'[k % 8] });
function hud(fr, f) {
  const h = fr.hud;
  $('hud').style.opacity = h ? 1 : 0;
  if (!h) return;
  $('obj').style.display = h.obj ? 'block' : 'none';
  if (h.obj) $('objT').innerHTML = h.obj;
  for (let j = 1; j <= ${T.items.length}; j++) $('slot' + j).classList.toggle('on', h.sel === j);
  $('stam').style.display = h.stam === undefined ? 'none' : 'block';
  if (h.stam !== undefined) $('stamF').style.width = (100 * h.stam) + '%';
  $('chat').style.display = h.chat && h.chat.length ? 'block' : 'none';
  if (h.chat) $('chat').innerHTML = h.chat.map(([n, c, m]) => '<div><span class="n" style="color:' + c + '">' + n + ':</span> ' + m + '</div>').join('');
  $('note').style.display = h.notice ? 'block' : 'none';
  if (h.notice) $('noteB').textContent = h.notice;
  $('hb').style.display = h.hb === undefined ? 'none' : 'block';
  if (h.hb !== undefined) {
    const t = h.hb;
    $('hb').style.opacity = Math.min(1, t / 0.25);
    let html = '', pulse = 0;
    for (const b of BEATS) {
      const d = b.T - t;
      if (d < 0 && d > -0.16) pulse = 1 - (-d / 0.16);
      if (d < 0 || d > 0.9) continue;
      const x = (d / 0.9) * 300;
      const L = b.side === 'L';
      const col = L ? '#50beff' : '#ff5faa';
      // (the left half of a heart flies in from the left, the right half from the right)
      html += '<div class="half" style="left:' + (L ? 302 - x : 350 + x) + 'px"><span style="color:' + col + ';left:' + (L ? 0 : -48) + 'px">♥</span></div>';
    }
    $('hbHalves').innerHTML = html;
    $('hbHeart').style.transform = 'scale(' + (1 + 0.16 * pulse) + ')';
    $('hbHeart').style.color = pulse > 0 ? '#ff3a50' : '#e6283c';
    $('hbHint').textContent = h.hbHint || '';
  }
}
const gctx = $('grain').getContext('2d'); const gimg = gctx.createImageData(360, 640);
const rctx = $('rain').getContext('2d');
const nctx = $('noise').getContext('2d');
const pctx = $('pix').getContext('2d'); pctx.imageSmoothingEnabled = true;
function rnd(n) { const x = Math.sin(n * 127.1 + 311.7) * 43758.5453; return x - Math.floor(x); }
window.setFrame = (f, fr) => {
  const t = f / 30;
  for (const id of ['h1','h2','h3','part','card','low','thought','glt','endTop','endSub','brand','bname','e2']) $(id).style.opacity = 0;
  hud(fr, f);
  $('redf').style.opacity = 0;
  if (BRAND && fr.section !== 'end') $('brand').style.opacity = 1;
  if (BRAND && fr.section === 'hook') $('bname').style.opacity = 1;
  // footage: dark, a little crushed, a touch of chromatic edge
  let filt = 'contrast(1.1) saturate(.85) brightness(' + (fr.bright || 1.35) + ')';
  $('base').style.filter = filt;
  $('base').style.transform = 'none';
  $('pix').style.opacity = 0;
  // the scare: pixelated, grey, blown out, shaking
  if (fr.scare && fr.scareI !== undefined && fr.scareI >= 3) {
    // the real frame: punched in, shaking hard, a red flash fading
    const j = fr.scareI - 3;
    const s = 1.22 - 0.012 * j + 0.04 * Math.sin(f * 2.3);
    $('base').style.transform = 'translate(' + (rnd(f) - .5) * 70 + 'px,' + (rnd(f + 3) - .5) * 70 + 'px) scale(' + s + ') rotate(' + (rnd(f + 9) - .5) * 4 + 'deg)';
    $('base').style.filter = 'contrast(1.55) saturate(.5) brightness(' + (1.9 - 0.06 * j) + ')';
    $('redf').style.opacity = Math.max(0, 0.5 - 0.05 * j);
    $('hud').style.opacity = 0;
  } else if (fr.scare) {
    const b = $('base');
    $('hud').style.opacity = 0;
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
    if (fr.scare) { $('card').style.opacity = 0; $('low').style.opacity = 0; }
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
    if (BRAND) {
      // the name, then the search bar typing it in, then free / with friends
      $('e2').style.opacity = Math.min(1, Math.max(0, (lt - 0.25) / 0.3));
      const typed = Math.max(0, Math.floor((lt - 1.3) * 22));
      $('e2q').textContent = ${JSON.stringify(T.name)}.slice(0, typed);
      $('e2cur').style.opacity = (Math.floor(lt * 2.5) % 2) ? 0 : 1;
      $('e2on').style.opacity = Math.min(1, Math.max(0, (lt - 0.9) / 0.3));
      $('e2bar').style.opacity = $('e2on').style.opacity;
      $('e2foot').style.opacity = Math.min(1, Math.max(0, (lt - 2.9) / 0.4));
    } else if (lt >= 0.2) { $('endTop').style.opacity = 1; $('endSub').style.opacity = 1; }
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
