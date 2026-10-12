// node comp_gameplay.mjs edit.json outDir [from] [to] — the "AMAZING NEW ROBLOX HORROR GAME" format
// (reel 22 on): gameplay footage cut to an upbeat track, the game's name always pinned at the top, a
// big hook over the first two bars, short bold captions popping in on each cut, a zoom punch on every
// cut and a pulse on every beat, and an end card (search it on Roblox).
// edit.json: { frames: [{ src, section: hook|clip|end, cap, i, k }], cuts: [s...], bpm, drop, text: {...} }
import { chromium } from 'playwright';
import fs from 'fs';
const [,, editPath, outDir, fromArg, toArg] = process.argv;
const edit = JSON.parse(fs.readFileSync(editPath, 'utf8'));
fs.mkdirSync(outDir, { recursive: true });
const NF = edit.frames.length;
const FD = '/mnt/skills/examples/canvas-design/canvas-fonts/';
const font = (f) => 'data:font/ttf;base64,' + fs.readFileSync(FD + f).toString('base64');
const T = Object.assign({ name: 'someone lives in our attic.', tag: 'ROBLOX  ·  HORROR', hook: ['AMAZING NEW', 'ROBLOX HORROR GAME', 'TO PLAY WITH', 'YOUR FRIENDS'],
  hookAccent: [1], endTop: 'PLAY IT WITH YOUR FRIENDS', endSearch: 'SEARCH IT ON ROBLOX', endSub: 'FREE  ·  1-4 PLAYERS', accent: '#ffd60a' }, edit.text || {});

const html = `<!doctype html><html><head><style>
@font-face { font-family: O; src: url(${font('Outfit-Bold.ttf')}); }
:root { --acc:${T.accent}; }
html,body { margin:0; width:1080px; height:1920px; overflow:hidden; background:#000; }
#base { position:absolute; inset:0; width:1080px; height:1920px; object-fit:cover; transform-origin:50% 50%; }
.l { position:absolute; inset:0; }
#vig { background: radial-gradient(ellipse 85% 70% at 50% 50%, rgba(0,0,0,0) 55%, rgba(0,0,0,.45) 100%); }
#topfade { background: linear-gradient(rgba(0,0,0,.65), rgba(0,0,0,0) 22%); }
#flash { background:#fff; opacity:0; }
#black { background:#000; opacity:0; }
.o { position:absolute; opacity:0; }
.st { -webkit-text-stroke: 14px #000; paint-order: stroke fill; }
/* the game's name, always on top */
#banner { left:50%; top:150px; transform:translateX(-50%); padding:18px 38px 20px; border-radius:26px; background:rgba(8,8,10,.86);
          border:4px solid rgba(255,255,255,.9); font-family:O; font-size:66px; color:#fff; white-space:nowrap; letter-spacing:-1px; opacity:1; }
#tag { left:0; right:0; top:286px; text-align:center; font-family:O; font-size:30px; letter-spacing:6px; color:var(--acc); opacity:1;
       -webkit-text-stroke: 7px #000; paint-order: stroke fill; }
#hook { left:40px; right:40px; top:720px; text-align:center; font-family:O; line-height:1.0; color:#fff; }
#hook div { font-size:84px; letter-spacing:-2px; margin:6px 0; white-space:nowrap; }
#hook .acc { color:var(--acc); }
#cap { left:40px; right:40px; top:1380px; text-align:center; font-family:O; font-size:92px; line-height:1.05; color:#fff; letter-spacing:-1px; }
#cap .acc { color:var(--acc); }
#endName { left:40px; right:40px; top:700px; text-align:center; font-family:O; font-size:112px; line-height:1.0; color:#fff; letter-spacing:-2px; }
#endTop { left:0; right:0; top:960px; text-align:center; font-family:O; font-size:58px; color:var(--acc); }
#endSearch { left:50%; top:1090px; transform:translateX(-50%); padding:26px 54px; border-radius:22px; background:var(--acc); border:6px solid #000;
             font-family:O; font-size:72px; color:#000; white-space:nowrap; }
#endSub { left:0; right:0; top:1270px; text-align:center; font-family:O; font-size:44px; letter-spacing:4px; color:#fff; }
</style></head><body>
<img id="base"/>
<div class="l" id="vig"></div>
<div class="l" id="topfade"></div>
<div class="o st" id="hook"></div>
<div class="o st" id="cap"></div>
<div class="o st" id="endName">${T.name}</div>
<div class="o st" id="endTop">${T.endTop}</div>
<div class="o" id="endSearch">${T.endSearch}</div>
<div class="o st" id="endSub">${T.endSub}</div>
<div class="o" id="banner">${T.name}</div>
<div class="o" id="tag">${T.tag}</div>
<div class="l" id="flash"></div>
<div class="l" id="black"></div>
<script>
const $ = (id) => document.getElementById(id);
const clamp = (x, a, b) => Math.max(a, Math.min(b, x));
const seg = (t, a, b) => clamp((t - a) / (b - a), 0, 1);
const back = (x) => { x = clamp(x, 0, 1); const c = 1.9; return 1 + (c + 1) * Math.pow(x - 1, 3) + c * Math.pow(x - 1, 2); };
const HOOK = ${JSON.stringify(T.hook)}, HOOKACC = ${JSON.stringify(T.hookAccent)};
$('hook').innerHTML = HOOK.map((w, i) => '<div class="' + (HOOKACC.includes(i) ? 'acc' : '') + '">' + w + '</div>').join('');
window.setFrame = (f, fr, cuts, bpm, drop) => {
  const t = f / 30, beat = 60 / bpm;
  for (const id of ['hook', 'cap', 'endName', 'endTop', 'endSearch', 'endSub']) $(id).style.opacity = 0;
  // footage: a zoom punch on every cut, a little pulse on every beat (once the beat drops)
  let since = 1e9; for (const c of cuts) if (t >= c) since = Math.min(since, t - c);
  let zoom = 1 + 0.09 * Math.exp(-since * 9);
  if (t >= drop) zoom += 0.018 * Math.exp(-(((t - drop) % beat)) * 10);
  let filt = 'contrast(1.12) saturate(1.15) brightness(1.18)';
  if (fr.section === 'end') { filt = 'contrast(1.05) saturate(.9) brightness(.42) blur(6px)'; zoom = 1.1; }
  $('base').style.filter = filt;
  $('base').style.transform = 'scale(' + zoom + ')';
  // the name, always on top (a small bounce on the drop)
  const kb = t >= drop ? Math.exp(-(t - drop) * 6) : 0;
  $('banner').style.opacity = 1; $('tag').style.opacity = 1;
  $('banner').style.transform = 'translateX(-50%) scale(' + (1 + 0.08 * kb) + ')';
  // the hook: line by line on the beat
  if (fr.section === 'hook') {
    const h = $('hook'); h.style.opacity = 1;
    [...h.children].forEach((d, i) => { const k = seg(t, 0.15 + i * beat, 0.15 + i * beat + 0.16); d.style.opacity = k > 0 ? 1 : 0; d.style.transform = 'scale(' + (1.5 - 0.5 * back(k)) + ')'; });
  }
  // captions: pop in on the cut
  if (fr.section === 'clip' && fr.cap) {
    const c = $('cap'); const k = seg(since, 0.0, 0.14);
    c.innerHTML = fr.cap.replace(/\\*(.+?)\\*/g, '<span class="acc">$1</span>');
    c.style.opacity = k > 0 ? 1 : 0; c.style.transform = 'scale(' + (1.45 - 0.45 * back(k)) + ') rotate(' + (-2 + 4 * ((cuts.findIndex(x => Math.abs(x - (t - since)) < 1e-3)) % 2)) + 'deg)';
  }
  // the end card
  if (fr.section === 'end') {
    const lt = fr.i / 30;
    const kn = seg(lt, 0, 0.2); $('endName').style.opacity = kn > 0 ? 1 : 0; $('endName').style.transform = 'scale(' + (1.4 - 0.4 * back(kn)) + ')';
    const kt = seg(lt, beat, beat + 0.15); $('endTop').style.opacity = kt;
    const ks = seg(lt, 2 * beat, 2 * beat + 0.2); $('endSearch').style.opacity = ks > 0 ? 1 : 0;
    $('endSearch').style.transform = 'translateX(-50%) scale(' + ((0.6 + 0.4 * back(ks)) * (1 + 0.035 * Math.exp(-((lt % beat)) * 8))) + ')';
    $('endSub').style.opacity = seg(lt, 3 * beat, 3 * beat + 0.2);
  }
  // flashes: the drop, and a softer one on each cut after it
  let fl = 0;
  if (t >= drop) fl = Math.max(fl, 0.85 * (1 - seg(t, drop, drop + 0.2)));
  for (const c of cuts) if (c > drop && t >= c) fl = Math.max(fl, 0.22 * (1 - seg(t, c, c + 0.08)));
  $('flash').style.opacity = fl;
  $('black').style.opacity = t < 0.1 ? 1 - seg(t, 0, 0.1) : 0;
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
  await page.evaluate(async ([img, f, fr, cuts, bpm, drop]) => {
    const b = document.getElementById('base');
    if (img) { b.src = img; await b.decode(); }
    window.setFrame(f, fr, cuts, bpm, drop);
  }, [img, f, fr, edit.cuts, edit.bpm, edit.drop]);
  fs.writeFileSync(`${outDir}/${String(f).padStart(4, '0')}.png`, await page.screenshot({ type: 'png' }));
  if (f % 60 === 0) console.log('comp', f);
}
await browser.close();
