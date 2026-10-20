// node tools/assets/ui_preview.mjs <ui.json> <out.png> [pc|phone|tablet] [backdrop.png]
// Draws a GUI dump from tools/harness/ui_dump.luau the way Roblox lays it out (UDim2 position and
// size, anchor points, UIListLayout, UIPadding, AutomaticSize, UICorner, UIStroke, UIScale, ZIndex,
// rich text), at a PC (1920x1080), phone (844x390) or tablet (1180x820) screen, over a backdrop.
// An approximation: fonts are close, images are placeholders, the Roblox top bar and hotbar are
// sketched in for context. Good enough to see what shows, where, how big, and what overlaps.
import { chromium } from 'playwright';
import fs from 'fs';
const here = new URL('.', import.meta.url).pathname;
// (npm install in tools/assets first: it uses the playwright there)

const [,, inPath, outPath, devArg, backdrop] = process.argv;
const dump = JSON.parse(fs.readFileSync(inPath, 'utf8'));
const DEV = { pc: [1920, 1080], phone: [844, 390], tablet: [1180, 820] }[devArg || (dump.touch ? 'phone' : 'pc')];
const [W, H] = DEV;
const INSET = 36; // (Roblox's top bar)
const bg = backdrop && fs.existsSync(backdrop) ? 'data:image/png;base64,' + fs.readFileSync(backdrop).toString('base64') : '';
const font = (f) => fs.existsSync(f) ? 'data:font/ttf;base64,' + fs.readFileSync(f).toString('base64') : '';
const FD = here + '../../marketing/fonts/';

const html = `<!doctype html><html><head><style>
@font-face { font-family: G; src: url(${font(FD + 'WorkSans-Bold.ttf')}); font-weight: 700; }
@font-face { font-family: GR; src: url(${font(FD + 'Outfit-Regular.ttf')}); }
html, body { margin: 0; width: ${W}px; height: ${H}px; overflow: hidden; background: #0b0c10; font-family: GR, sans-serif; }
#bg { position: absolute; inset: 0; background: url(${bg}) center/cover; filter: brightness(.8); }
.g { position: absolute; box-sizing: border-box; }
.t { display: flex; white-space: pre; overflow: visible; line-height: 1.12; }
.img { outline: 1px dashed rgba(255,255,255,.35); }
#top { position: absolute; left: 0; top: 0; right: 0; height: ${INSET}px; }
.rb { position: absolute; top: 4px; width: 44px; height: 28px; border-radius: 9px; background: rgba(18,18,21,.75); }
#hot { position: absolute; left: 50%; bottom: 8px; transform: translateX(-50%); display: flex; gap: 6px; }
.hs { width: ${W > 1000 ? 60 : 46}px; height: ${W > 1000 ? 60 : 46}px; border-radius: 8px; background: rgba(28,28,32,.55); border: 2px dashed rgba(255,255,255,.25); box-sizing: border-box; }
</style></head><body><div id="bg"></div>
<div id="top"><div class="rb" style="left:12px"></div><div class="rb" style="left:62px"></div></div>
<div id="hot">${dump.hotbar === false ? '' : '<div class="hs"></div><div class="hs"></div>'}</div>
<div id="root"></div>
<script>
const W = ${W}, H = ${H}, INSET = ${INSET}, TOUCH = ${devArg ? devArg !== 'pc' : !!dump.touch};
const dump = ${JSON.stringify(dump)};
const css = (c, a = 1) => 'rgba(' + c[0] + ',' + c[1] + ',' + c[2] + ',' + a + ')';
const FONTS = { GothamBlack: 900, GothamBold: 700, GothamMedium: 500, Gotham: 400, SourceSansBold: 700, SourceSans: 400, BuilderSansBold: 700, BuilderSansExtraBold: 800, BuilderSans: 400, Arcade: 700 };
function rich(t) {
  return t.replace(/&/g, '&amp;').replace(/<(?!\\/?(b|i|u|font|br|stroke)\\b)/g, '&lt;')
    .replace(/<font([^>]*)>/g, (m, a) => {
      let st = '';
      const c = a.match(/color="(#[0-9a-fA-F]{6})"/) || a.match(/color="rgb\\((\\d+),\\s*(\\d+),\\s*(\\d+)\\)"/);
      if (c) st += 'color:' + (c[1].startsWith('#') ? c[1] : 'rgb(' + c[1] + ',' + c[2] + ',' + c[3] + ')') + ';';
      const s = a.match(/size="(\\d+)"/); if (s) st += 'font-size:' + s[1] + 'px;';
      return '<span style="' + st + '">';
    }).replace(/<\\/font>/g, '</span>').replace(/<\\/?stroke[^>]*>/g, '');
}
// (an empty Luau table comes out of serde as {}, not [])
const arr = (x) => Array.isArray(x) ? x : [];
function kids(n, cls) { return arr(n.ch).filter(c => c.c === cls); }
// lay out one GuiObject inside a parent box of (pw, ph); returns the element
function draw(n, pw, ph, parentEl, inList) {
  if (n.vis === false) return null;
  const el = document.createElement('div');
  el.className = 'g';
  const [sxs, sxo, sys, syo] = n.size;
  let w = sxs * pw + sxo, h = sys * ph + syo;
  const auto = n.auto || 'None';
  const pad = kids(n, 'UIPadding')[0];
  const p = pad ? pad.p : [0, 0, 0, 0];
  const corner = kids(n, 'UICorner')[0];
  const stroke = kids(n, 'UIStroke')[0];
  const scale = kids(n, 'UIScale')[0];
  const list = kids(n, 'UIListLayout')[0];
  const cons = kids(n, 'UISizeConstraint')[0];
  if (cons) { w = Math.min(Math.max(w, cons.min[0]), cons.max[0]); h = Math.min(Math.max(h, cons.min[1]), cons.max[1]); }
  if (auto === 'X' || auto === 'XY') { el.style.minWidth = w + 'px'; el.style.width = 'max-content'; } else el.style.width = w + 'px';
  if (auto === 'Y' || auto === 'XY') { el.style.minHeight = h + 'px'; el.style.height = 'auto'; } else el.style.height = h + 'px';
  el.style.padding = p[0] + 'px ' + p[1] + 'px ' + p[2] + 'px ' + p[3] + 'px';
  if (!inList) {
    const [pxs, pxo, pys, pyo] = n.pos;
    el.style.left = (pxs * pw + pxo) + 'px';
    el.style.top = (pys * ph + pyo) + 'px';
    el.style.transform = 'translate(' + (-n.anchor[0] * 100) + '%,' + (-n.anchor[1] * 100) + '%)' + (scale ? ' scale(' + scale.scale + ')' : '') + (n.rot ? ' rotate(' + n.rot + 'deg)' : '');
  } else {
    el.style.position = 'relative';
    if (scale) el.style.transform = 'scale(' + scale.scale + ')';
  }
  el.style.zIndex = n.z || 1;
  const grad = kids(n, 'UIGradient')[0];
  if (n.bgT < 1) {
    if (grad) {
      // (Roblox: rotation 0 runs left to right, 90 top to bottom; colour x (1 - transparency))
      const stops = grad.gt.map(([t, v]) => {
        const c = grad.gc.length > 1 ? grad.gc.reduce((a, b) => Math.abs(b[0] - t) < Math.abs(a[0] - t) ? b : a)[1] : (grad.gc[0] ? grad.gc[0][1] : [255, 255, 255]);
        const mix = [0, 1, 2].map(k => Math.round(n.bg[k] * c[k] / 255));
        return css(mix, (1 - n.bgT) * (1 - v)) + ' ' + (t * 100) + '%';
      });
      el.style.background = 'linear-gradient(' + (90 + (grad.grot || 0)) + 'deg,' + stops.join(',') + ')';
    } else el.style.background = css(n.bg, 1 - n.bgT);
  }
  if (corner) el.style.borderRadius = (corner.r[0] * Math.min(w, h) + corner.r[1]) + 'px';
  if (n.clip) el.style.overflow = 'hidden';
  if (n.text !== undefined && n.text !== '') {
    el.classList.add('t');
    const span = document.createElement('span');
    let ts = n.ts || 14;
    if (n.scaled) ts = Math.max(8, Math.min(h * 0.82, (w / Math.max(1, n.text.length)) * 1.9));
    span.style.fontSize = ts + 'px';
    span.style.color = css(n.tc, 1 - (n.tt || 0));
    span.style.fontWeight = FONTS[n.font] || (String(n.font || '').match(/Bold|Black|Heavy/) ? 700 : 400);
    span.style.fontFamily = span.style.fontWeight >= 600 ? 'G' : 'GR';
    if (n.wrap || n.scaled) { el.style.whiteSpace = 'normal'; span.style.whiteSpace = 'pre-wrap'; }
    el.style.justifyContent = { Left: 'flex-start', Right: 'flex-end' }[n.xa] || 'center';
    el.style.alignItems = { Top: 'flex-start', Bottom: 'flex-end' }[n.ya] || 'center';
    span.style.textAlign = { Left: 'left', Right: 'right' }[n.xa] || 'center';
    if (n.stroke !== undefined && n.stroke < 1) span.style.textShadow = '0 0 2px rgba(0,0,0,' + (1 - n.stroke) + ')';
    if (stroke) span.style.textShadow = '0 0 ' + stroke.th + 'px ' + css(stroke.sc, 1 - stroke.st);
    span.innerHTML = n.rich ? rich(n.text) : n.text.replace(/&/g, '&amp;').replace(/</g, '&lt;');
    el.appendChild(span);
  } else if (stroke) {
    el.style.boxShadow = 'inset 0 0 0 ' + stroke.th + 'px ' + css(stroke.sc, 1 - stroke.st);
  }
  if (n.img !== undefined && n.img !== '') {
    el.classList.add('img');
    if (n.it < 1 && !n.text) el.style.background = (el.style.background || '') ;
  }
  parentEl.appendChild(el);
  // children
  const cw = Math.max(0, w - p[1] - p[3]), chh = Math.max(0, h - p[0] - p[2]);
  const guiKids = arr(n.ch).filter(c => c.size);
  if (list) {
    const box = document.createElement('div');
    box.style.display = 'flex';
    box.style.flexDirection = list.dir === 'Horizontal' ? 'row' : 'column';
    box.style.gap = (list.pad[0] * (list.dir === 'Horizontal' ? cw : chh) + list.pad[1]) + 'px';
    const along = list.dir === 'Horizontal';
    const ha = { Left: 'flex-start', Right: 'flex-end', Center: 'center' }[list.ha] || 'flex-start';
    const va = { Top: 'flex-start', Bottom: 'flex-end', Center: 'center' }[list.va] || 'flex-start';
    box.style.justifyContent = along ? ha : va;
    box.style.alignItems = along ? va : ha;
    box.style.position = auto === 'None' ? 'absolute' : 'relative';
    if (auto === 'None') { box.style.left = p[3] + 'px'; box.style.top = p[0] + 'px'; box.style.width = cw + 'px'; box.style.height = chh + 'px'; }
    const sorted = guiKids.slice().sort((a, b) => list.sort === 'LayoutOrder' ? (a.order || 0) - (b.order || 0) : 0);
    for (const c of sorted) draw(c, cw, chh, box, true);
    el.appendChild(box);
  } else {
    // (an auto-sized box with absolutely placed children: give it their extent)
    const inner = document.createElement('div');
    inner.style.position = 'absolute'; inner.style.left = p[3] + 'px'; inner.style.top = p[0] + 'px';
    inner.style.width = cw + 'px'; inner.style.height = chh + 'px';
    el.appendChild(inner);
    for (const c of guiKids) draw(c, cw, chh, inner, false);
  }
  return el;
}
const root = document.getElementById('root');
const screens = dump.guis.filter(g => g.en !== false).sort((a, b) => (a.order || 0) - (b.order || 0));
for (const s of screens) {
  const sc = document.createElement('div');
  sc.className = 'g';
  const top = s.inset ? 0 : INSET;
  sc.style.left = '0px'; sc.style.top = top + 'px'; sc.style.width = W + 'px'; sc.style.height = (H - top) + 'px';
  sc.style.zIndex = 10 + (s.order || 0);
  root.appendChild(sc);
  const us = arr(s.ch).find(c => c.c === 'UIScale');
  // (client UI.rescale: the HUD scales with the screen)
  const k = !us ? 1 : TOUCH ? Math.min(1.3, Math.max(0.62, Math.min(W / 1100, H / 620))) : Math.min(1.05, Math.max(0.72, Math.min(W / 1320, H / 742)));
  if (k !== 1) { sc.style.width = (W / k) + 'px'; sc.style.height = ((H - top) / k) + 'px'; sc.style.transform = 'scale(' + k + ')'; sc.style.transformOrigin = '0 0'; }
  for (const c of arr(s.ch).filter(c => c.size)) draw(c, W / k, (H - top) / k, sc, false);
}
</script></body></html>`;

const browser = await chromium.launch({ executablePath: '/opt/pw-browsers/chromium-1194/chrome-linux/chrome' });
const page = await browser.newPage({ viewport: { width: W, height: H } });
page.on('pageerror', (e) => console.log('PAGE ERROR', e.message));
page.on('console', (m) => { if (m.type() === 'error') console.log('PAGE', m.text()); });
await page.setContent(html);
await page.evaluate(() => document.fonts.ready);
await page.screenshot({ path: outPath });
await browser.close();
console.log('wrote', outPath, W + 'x' + H);
