// node compose.mjs spec.json  — lays title text, glow, vignette, grain and rain over renders
import { chromium } from 'playwright';
import fs from 'fs';
const spec = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
const font = (f) => 'data:font/ttf;base64,' + fs.readFileSync(f).toString('base64');
const browser = await chromium.launch({ executablePath: '/opt/pw-browsers/chromium-1194/chrome-linux/chrome' });
for (const s of spec.items) {
  const page = await browser.newPage({ viewport: { width: s.w, height: s.h } });
  const img = 'data:image/png;base64,' + fs.readFileSync(s.src).toString('base64');
  const k = s.w / 1920;
  const html = `<!doctype html><html><head><style>
  @font-face { font-family: T; src: url(${font(spec.fonts.title)}); }
  @font-face { font-family: L; src: url(${font(spec.fonts.light)}); }
  @font-face { font-family: B; src: url(${font(spec.fonts.body)}); }
  html,body { margin:0; width:${s.w}px; height:${s.h}px; overflow:hidden; background:#000; }
  .l { position:absolute; inset:0; }
  .bg { background:url(${img}) center/cover; filter: contrast(1.12) saturate(${s.sat ?? 0.8}) brightness(${s.bright ?? 1}); }
  .glow { background:url(${img}) center/cover; filter: blur(${22 * k}px) brightness(1.6); mix-blend-mode: screen; opacity:${s.glow ?? 0.45}; }
  .rain { background: repeating-linear-gradient(104deg, rgba(255,255,255,0) 0 ${9 * k}px, rgba(200,215,235,0.07) ${9 * k}px ${10 * k}px); opacity:${s.rain ? 1 : 0}; }
  .vig { opacity:${s.vig ?? 1}; background: radial-gradient(ellipse at ${s.focus || '50% 45%'}, rgba(0,0,0,0) 30%, rgba(0,0,0,0.55) 65%, rgba(0,0,0,0.92) 100%); }
  .shade { background: linear-gradient(${s.shadeDir || '0deg'}, rgba(0,0,0,0.85) 0%, rgba(0,0,0,0) ${s.shadeTo || 45}%); }
  .grain { opacity:.10; background-image:url("data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' width='220' height='220'><filter id='n'><feTurbulence type='fractalNoise' baseFrequency='.9' numOctaves='2' stitchTiles='stitch'/></filter><rect width='100%' height='100%' filter='url(%23n)'/></svg>"); mix-blend-mode: overlay; }
  .txt { position:absolute; color:#f2efe9; text-shadow: 0 ${4 * k}px ${30 * k}px rgba(0,0,0,.8); ${s.textPos || `left:${90 * k}px; bottom:${80 * k}px;`} text-align:${s.align || 'left'}; }
  .title { font-family:T; font-size:${(s.titleSize || 150) * k}px; letter-spacing:${(s.track ?? 6) * k}px; line-height:.95; text-transform:uppercase; }
  .sub { font-family:L; font-size:${(s.subSize || 44) * k}px; letter-spacing:${(s.subTrack ?? 10) * k}px; text-transform:uppercase; opacity:.86; margin-top:${18 * k}px; }
  .small { font-family:B; font-size:${(s.smallSize || 30) * k}px; letter-spacing:${2 * k}px; opacity:.7; margin-top:${22 * k}px; }
  .rule { width:${120 * k}px; height:${3 * k}px; background:#f2efe9; opacity:.8; margin:${26 * k}px ${s.align === 'center' ? 'auto' : '0'} 0; }
  </style></head><body>
  <div class="l bg"></div><div class="l glow"></div><div class="l rain"></div><div class="l shade"></div><div class="l vig"></div><div class="l grain"></div>
  <div class="txt">${s.kicker ? `<div class="sub" style="margin:0 0 ${14 * k}px">${s.kicker}</div>` : ''}<div class="title">${s.title || ''}</div>${s.rule ? '<div class="rule"></div>' : ''}${s.sub ? `<div class="sub">${s.sub}</div>` : ''}${s.small ? `<div class="small">${s.small}</div>` : ''}</div>
  </body></html>`;
  await page.setContent(html);
  await page.evaluate(() => document.fonts.ready);
  await page.waitForTimeout(150);
  fs.writeFileSync(s.out, await page.screenshot({ type: 'png' }));
  console.log('composed', s.out);
  await page.close();
}
await browser.close();
