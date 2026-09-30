// node captions.mjs spec.json — transparent 1080x1920 caption cards
import { chromium } from 'playwright';
import fs from 'fs';
const spec = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
const font = (f) => 'data:font/ttf;base64,' + fs.readFileSync(f).toString('base64');
const browser = await chromium.launch({ executablePath: '/opt/pw-browsers/chromium-1194/chrome-linux/chrome' });
const page = await browser.newPage({ viewport: { width: 1080, height: 1920 } });
for (const c of spec.items) {
  await page.setContent(`<!doctype html><html><head><style>
  @font-face { font-family: T; src: url(${font(spec.fonts.title)}); }
  @font-face { font-family: L; src: url(${font(spec.fonts.light)}); }
  @font-face { font-family: B; src: url(${font(spec.fonts.body)}); }
  html,body { margin:0; width:1080px; height:1920px; background:transparent; }
  .box { position:absolute; left:80px; right:80px; top:${c.top ?? 330}px; text-align:center; color:#f4f1ea;
         text-shadow: 0 4px 24px rgba(0,0,0,.95), 0 0 2px rgba(0,0,0,.9); }
  .cap { font-family:B; font-size:${c.size ?? 62}px; line-height:1.22; }
  .title { font-family:T; font-size:${c.titleSize ?? 170}px; letter-spacing:10px; text-transform:uppercase; line-height:1; }
  .sub { font-family:L; font-size:48px; letter-spacing:8px; text-transform:uppercase; opacity:.85; margin-top:30px; }
  .small { font-family:B; font-size:40px; opacity:.75; margin-top:44px; }
  .rule { width:140px; height:4px; background:#f4f1ea; margin:36px auto 0; opacity:.8; }
  </style></head><body><div class="box">${c.html}</div></body></html>`);
  await page.evaluate(() => document.fonts.ready);
  fs.writeFileSync(c.out, await page.screenshot({ type: 'png', omitBackground: true }));
  console.log('caption', c.out);
}
await browser.close();
