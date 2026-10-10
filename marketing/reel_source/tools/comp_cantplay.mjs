// node comp_cantplay.mjs edit.json outDir [from] [to] — comp6 ("ROBLOX HORROR GAMES YOU CAN'T PLAY ALONE #N") with the words
// from edit.json: hook4, stamp, rows {squad, goal}, next (and its size)
import { chromium } from 'playwright';
import fs from 'fs';
const [,, editPath, outDir, fromArg, toArg] = process.argv;
const edit = JSON.parse(fs.readFileSync(editPath, 'utf8'));
fs.mkdirSync(outDir, { recursive: true });
const FPS = 30, NF = edit.frames.length;
const FD = '/mnt/skills/examples/canvas-design/canvas-fonts/';
const font = (f) => 'data:font/ttf;base64,' + fs.readFileSync(FD + f).toString('base64');
const maskImg = 'data:image/png;base64,' + fs.readFileSync(new URL('../reel4/mask_card.png', import.meta.url)).toString('base64');

const NUM = edit.num ?? 2, NEXT = edit.next ?? '';
const T = Object.assign({ hook4: '(bring a friend. or two.)', stamp: 'found this upstairs', squad: '1 - 4 players', goal: 'survive the night', nextSize: 72 }, edit.text || {});
const html = `<!doctype html><html><head><style>
@font-face { font-family: H; src: url(${font('BigShoulders-Bold.ttf')}); }
@font-face { font-family: MO; src: url(${font('WorkSans-Bold.ttf')}); }
@font-face { font-family: CP; src: url(${font('WorkSans-Bold.ttf')}); }
@font-face { font-family: SC; src: url(${font('NothingYouCouldDo-Regular.ttf')}); }
:root { --acc:#ff8a2a; --bone:#ffffff; }
html,body { margin:0; width:1080px; height:1920px; overflow:hidden; background:#000; }
#stage { position:absolute; inset:0; }
#base { position:absolute; inset:0; width:1080px; height:1920px; object-fit:cover; transform-origin:50% 45%; }
.l { position:absolute; inset:0; }
#vig { background: radial-gradient(ellipse 80% 65% at 50% 48%, rgba(0,0,0,0) 50%, rgba(0,0,0,.5) 85%, rgba(0,0,0,.85) 100%); }
#grain { mix-blend-mode: soft-light; opacity:.14; }
#flash { background:#fff; opacity:0; }
#black { background:#000; opacity:0; }
.o { opacity:0; position:absolute; }
/* plain outlined text, the way people caption in the app */
.sh { -webkit-text-stroke: 12px #000; paint-order: stroke fill; }
.acc { color:var(--acc); }
.hk { left:0; right:0; text-align:center; font-family:H; color:#fff; white-space:nowrap; text-transform:uppercase; line-height:1; }
#hook1 { top:580px; font-size:116px; letter-spacing:2px; }
#hook2 { top:720px; font-size:116px; letter-spacing:1px; }
#hook3 { top:860px; left:0; right:0; text-align:center; font-family:H; font-size:260px; line-height:1; color:var(--acc); }
#hook4 { top:1170px; left:0; right:0; text-align:center; font-family:SC; font-size:80px; color:#fff; -webkit-text-stroke: 8px #000; paint-order: stroke fill; }
/* a polaroid taped to the page */
#mask { left:50%; top:90px; width:320px; margin-left:-180px; filter: grayscale(1) contrast(1.1); border:20px solid #f4f1ea; border-bottom-width:70px;
        box-shadow: 0 18px 30px rgba(0,0,0,.6); }
#tape { left:470px; top:70px; width:150px; height:46px; background:rgba(235,225,200,.75); }
#stamp { left:740px; top:330px; font-family:SC; font-size:62px; color:#fff; -webkit-text-stroke: 8px #000; paint-order: stroke fill; }
#head { display:none; }
.row { left:80px; right:40px; }
.row .k { font-family:MO; font-size:40px; letter-spacing:4px; color:var(--acc); -webkit-text-stroke: 8px #000; paint-order: stroke fill; }
.row .v { font-family:H; font-size:96px; line-height:1; color:#fff; white-space:nowrap; text-transform:uppercase; -webkit-text-stroke: 12px #000; paint-order: stroke fill; }
.bar { display:inline-block; width:50px; height:60px; margin-right:10px; background:rgba(255,255,255,.25); border:5px solid #000; vertical-align:middle; }
.bar.on { background:var(--acc); }
#cap { left:40px; right:40px; top:1400px; text-align:center; font-family:CP; font-size:76px; line-height:1.15; color:#fff; white-space:normal; }
#cap span { -webkit-text-stroke: 12px #000; paint-order: stroke fill; }
#capBig { left:0; right:0; top:1180px; text-align:center; font-family:H; font-size:300px; color:var(--acc); }
#capBig2 { display:none; }
#endTitle { left:0; right:0; top:700px; text-align:center; font-family:H; font-size:100px; color:#fff; white-space:nowrap; }
#endSub { left:0; right:0; top:840px; text-align:center; font-family:MO; font-size:44px; letter-spacing:3px; color:#fff; -webkit-text-stroke: 8px #000; paint-order: stroke fill; }
#endSearch { left:50%; top:1010px; transform:translateX(-50%); padding:24px 50px; border-radius:14px; background:var(--acc); border:6px solid #000;
             font-family:H; font-size:80px; color:#000; white-space:nowrap; letter-spacing:2px; }
#endNext { left:0; right:0; top:1250px; text-align:center; font-family:SC; font-size:${T.nextSize}px; color:#fff; -webkit-text-stroke: 8px #000; paint-order: stroke fill; }
</style></head><body>
<div id="stage">
  <img id="base"/>
    <div class="l" id="vig"></div>
    <canvas class="l" id="grain" width="540" height="960" style="width:1080px;height:1920px"></canvas>
  <div class="o hk sh" id="hook1">ROBLOX HORROR GAMES</div>
  <div class="o hk sh" id="hook2">YOU CAN'T PLAY ALONE</div>
  <div class="o sh" id="hook3">#${NUM}</div>
  <div class="o sh" id="hook4">${T.hook4}</div>
  <img class="o" id="mask" src="${maskImg}"/>
  <div class="o" id="tape"></div><div class="o" id="stamp">${T.stamp}</div>
  <div class="o" id="head">// CASE FILE 01</div>
  <div class="o row sh" id="c1" style="top:710px"><div class="k">TITLE</div><div class="v" style="font-size:80px">someone lives in our attic.</div></div>
  <div class="o row sh" id="c2" style="top:870px"><div class="k">FEAR LEVEL</div><div class="v" id="bars"></div></div>
  <div class="o row sh" id="c3" style="top:1030px"><div class="k">SQUAD</div><div class="v">${T.squad}</div></div>
  <div class="o row sh" id="c4" style="top:1190px"><div class="k">GOAL</div><div class="v acc">${T.goal}</div></div>
  <div class="o" id="cap"><span></span></div>
  <div class="o sh" id="capBig2">RUN.</div>
  <div class="o sh" id="capBig">RUN.</div>
  <div class="o sh" id="endTitle">someone lives in our attic.</div>
  <div class="o" id="endSub">FREE ON ROBLOX · 1-4 PLAYERS</div>
  <div class="o" id="endSearch">SEARCH IT ON ROBLOX</div>
  <div class="o" id="endNext">${NEXT}</div>
  <div class="l" id="flash"></div>
  <div class="l" id="black"></div>
</div>
<script>
const $ = (id) => document.getElementById(id);
const clamp = (x, a, b) => Math.max(a, Math.min(b, x));
const seg = (t, a, b) => clamp((t - a) / (b - a), 0, 1);
const back = (x) => { x = clamp(x, 0, 1); const c = 1.7; return 1 + (c + 1) * Math.pow(x - 1, 3) + c * Math.pow(x - 1, 2); };
function rnd(n) { const x = Math.sin(n * 127.1 + 311.7) * 43758.5453; return x - Math.floor(x); }
const g = $('grain').getContext('2d'); const gi = g.createImageData(540, 960);
// slide in from the left and settle (the case file rows)
function slide(el, t, at, dur = 0.25) {
  const k = seg(t, at, at + dur);
  el.style.opacity = k > 0 ? 1 : 0;
  el.style.transform = 'translateX(' + (-120 * (1 - back(k))) + 'px)';
}
// drop from slightly above (hook lines)
function drop(el, t, at, dur = 0.22, base = '') {
  const k = seg(t, at, at + dur);
  el.style.opacity = k > 0 ? 1 : 0;
  el.style.transform = base + ' translateY(' + (-60 * (1 - back(k))) + 'px) scale(' + (1.25 - 0.25 * back(k)) + ')';
}
const ALL = ['tape','hook1','hook2','hook3','hook4','mask','stamp','head','c1','c2','c3','c4','cap','capBig','capBig2','endTitle','endSub','endSearch','endNext'];
window.setFrame = (f, fr, cuts) => {
  const t = f / 30, sec = fr.section, lt = fr.i / 30;
  for (const id of ALL) $(id).style.opacity = 0;
  // ---------- the footage
  let filt = 'contrast(1.15) saturate(.95) brightness(1.45)';
  let zoom = 1 + 0.06 * fr.k;
  if (sec === 'hook') filt = 'contrast(1.15) saturate(.7) brightness(.85)';
  if (sec === 'card') { filt = 'contrast(1.1) saturate(.55) brightness(.5)'; zoom = 1.02 + 0.04 * fr.k; }
  if (sec === 'end') { filt = 'contrast(1.1) saturate(.6) brightness(.4) blur(4px)'; zoom = 1.08; }
  $('base').style.filter = filt;
  let sh = 0;
  if (fr.cap === 'RUN.') sh = 14 + 10 * Math.sin(f);
  for (const c of cuts) if (t >= c && t < c + 0.15) sh = Math.max(sh, 22 * (1 - (t - c) / 0.15));
  const sx = (rnd(f) - .5) * sh, sy = (rnd(f + 9) - .5) * sh;
  $('base').style.transform = 'translate(' + sx + 'px,' + sy + 'px) scale(' + zoom + ')';
  // ---------- hook
  if (sec === 'hook') {
    drop($('hook1'), t, 0.15); drop($('hook2'), t, 0.55); drop($('hook3'), t, 1.0, 0.25);
    const k4 = seg(t, 1.6, 1.9); $('hook4').style.opacity = k4; $('hook4').style.transform = 'rotate(-3deg) translateY(' + (20 * (1 - k4)) + 'px)';
  }
  // ---------- the case file
  if (sec === 'card') {
    const m = $('mask'); const k = seg(lt, 0.0, 0.3);
    m.style.opacity = k;
    m.style.transform = 'scale(' + (0.9 + 0.1 * back(k)) + ') rotate(-4deg)'; $('tape').style.opacity = k; $('tape').style.transform = 'rotate(6deg)';
    const ks = seg(lt, 2.9, 3.05);
    $('stamp').style.opacity = ks; $('stamp').style.transform = 'rotate(-6deg)';
    const kh = seg(lt, 0.2, 0.35); $('head').style.opacity = kh;
    slide($('c1'), lt, 0.35); slide($('c2'), lt, 1.0); slide($('c3'), lt, 1.75); slide($('c4'), lt, 2.35);
    const lit = Math.round(10 * seg(lt, 1.15, 1.7));     // the fear bar fills up to 10/10
    let h = ''; for (let b = 0; b < 10; b++) h += '<span class="bar' + (b < lit ? ' on' : '') + '"></span>';
    $('bars').innerHTML = h + '<span class="acc" style="font-size:76px">' + (lit === 10 ? ' 10/10' : '') + '</span>';
  }
  // ---------- montage captions
  if (sec === 'clip' && fr.cap) {
    if (fr.cap === 'RUN.') {
      const k = seg(lt, 0.03, 0.15);
      for (const [id, dx] of [['capBig', 0], ['capBig2', 10 * Math.sin(f * 2.3)]]) {
        const e = $(id); e.style.opacity = k > 0 ? 1 : 0;
        e.style.transform = 'translateX(' + dx + 'px) scale(' + (1.4 - 0.4 * back(k)) + ')';
      }
    } else {
      const c = $('cap'); c.firstChild.textContent = fr.cap; drop(c, lt, 0.05, 0.18);
    }
  }
  // ---------- end card
  if (sec === 'end') {
    const m = $('mask'); const k = seg(lt, 0.0, 0.35); m.style.opacity = 0.9 * k; m.style.transform = 'scale(' + (0.9 + 0.1 * back(k)) + ') rotate(-4deg)'; $('tape').style.opacity = k; $('tape').style.transform = 'rotate(6deg)';
    m.style.top = '80px';
    drop($('endTitle'), lt, 0.25); $('endSub').style.opacity = seg(lt, 0.7, 0.95);
    const ke = seg(lt, 1.3, 1.55);
    $('endSearch').style.opacity = ke > 0 ? 1 : 0; $('endSearch').style.transform = 'translateX(-50%) scale(' + ((0.6 + 0.4 * back(ke)) * (1 + 0.03 * Math.sin(lt * 6))) + ')';
    const kn = seg(lt, 2.3, 2.7); $('endNext').style.opacity = kn; $('endNext').style.transform = 'rotate(-3deg)';
  }
  // ---------- flashes
  let fl = 0;
  const scare1 = cuts[8] + 2.15, scare2 = cuts[9];
  if (t >= scare1) fl = Math.max(fl, 0.9 * (1 - seg(t, scare1, scare1 + 0.15)));
  if (t >= scare2) fl = Math.max(fl, 0.9 * (1 - seg(t, scare2, scare2 + 0.15)));
  for (const c of cuts.slice(1, 8)) if (t >= c) fl = Math.max(fl, 0.25 * (1 - seg(t, c, c + 0.08)));
  $('flash').style.opacity = fl;
  let bk = 0;
  if (t < 0.15) bk = 1 - seg(t, 0, 0.15);
  if (t > 29.2) bk = seg(t, 29.2, 29.5);
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
