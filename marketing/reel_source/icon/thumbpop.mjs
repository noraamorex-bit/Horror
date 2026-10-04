// node thumbpop.mjs job.json — bright, bold store thumbnails: grade + outlined text + arrows
import { chromium } from 'playwright';
import fs from 'fs';
const jobs = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
const FD = '/mnt/skills/examples/canvas-design/canvas-fonts/';
const font = (f) => 'data:font/ttf;base64,' + fs.readFileSync(FD + f).toString('base64');
const img = (p) => 'data:image/png;base64,' + fs.readFileSync(p).toString('base64');
const css = `@font-face{font-family:Pop;src:url(${font('Boldonse-Regular.ttf')})}
@font-face{font-family:Pop2;src:url(${font('EricaOne-Regular.ttf')})}
html,body{margin:0;width:1920px;height:1080px;overflow:hidden;background:#000}
.bg{position:absolute;inset:0;background-size:cover;background-position:center}
.vig{position:absolute;inset:0;background:radial-gradient(ellipse 80% 80% at 45% 50%, rgba(0,0,0,0) 55%, rgba(0,0,0,.5) 100%)}
.t{position:absolute;font-family:Pop;color:#fff;line-height:1.08;letter-spacing:1px;
  -webkit-text-stroke:14px #000;paint-order:stroke fill;filter:drop-shadow(0 10px 0 rgba(0,0,0,.55))}
.red{color:#ff2b2b}
.arrow{position:absolute;filter:drop-shadow(0 8px 0 rgba(0,0,0,.5))}`;
const browser = await chromium.launch({ executablePath: '/opt/pw-browsers/chromium-1194/chrome-linux/chrome' });
for (const j of jobs) {
  const p = await browser.newPage({ viewport: { width: 1920, height: 1080 } });
  await p.setContent(`<!doctype html><html><head><style>${css}</style></head><body>
    <div class="bg" style="background-image:url(${img(j.src)});filter:${j.filter || 'brightness(1.25) contrast(1.12) saturate(1.35)'}"></div>
    <div class="vig"></div>${j.html}</body></html>`);
  await p.evaluate(() => document.fonts.ready);
  fs.writeFileSync(j.out, await p.screenshot({ type: 'png' }));
  await p.close();
}
await browser.close();
console.log('done', jobs.length);
