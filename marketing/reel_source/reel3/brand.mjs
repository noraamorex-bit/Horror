// node brand.mjs artDir outDir — icon + thumbnails for "someone lives in our attic."
import { chromium } from 'playwright';
import fs from 'fs';
const [,, art, out] = process.argv;
fs.mkdirSync(out, { recursive: true });
const FD = '/mnt/skills/examples/canvas-design/canvas-fonts/';
const font = (f) => 'data:font/ttf;base64,' + fs.readFileSync(FD + f).toString('base64');
const img = (p) => 'data:image/png;base64,' + fs.readFileSync(p).toString('base64');
const css = `
@font-face { font-family: HSerif; src: url(${font('InstrumentSerif-Italic.ttf')}); }
@font-face { font-family: HTitle; src: url(${font('BigShoulders-Bold.ttf')}); }
@font-face { font-family: HSans; src: url(${font('WorkSans-Bold.ttf')}); }
html,body{margin:0;overflow:hidden;background:#000}
.bg{position:absolute;inset:0;background-size:cover;background-position:center}
.vig{position:absolute;inset:0}
.grain{position:absolute;inset:0;mix-blend-mode:soft-light;opacity:.28}
.t{position:absolute;color:#f2eee6;text-shadow:0 6px 40px rgba(0,0,0,.95),0 0 4px rgba(0,0,0,.9)}
.serif{font-family:HSerif}
.tag{font-family:HTitle;letter-spacing:10px;color:#f2eee6;opacity:.9}
`;
const grain = `<canvas class="grain" id="g"></canvas><script>
const c=document.getElementById('g');c.width=innerWidth/2;c.height=innerHeight/2;c.style.width=innerWidth+'px';c.style.height=innerHeight+'px';
const x=c.getContext('2d'),d=x.createImageData(c.width,c.height);for(let i=0;i<d.data.length;i+=4){const v=128+(Math.random()-.5)*160;d.data[i]=d.data[i+1]=d.data[i+2]=v;d.data[i+3]=255}x.putImageData(d,0,0)</script>`;
const page = (w, h, body) => `<!doctype html><html><head><style>${css} html,body{width:${w}px;height:${h}px}</style></head><body>${body}${grain}</body></html>`;
const jobs = {
  // the icon: his face upside down in the open hatch, nothing else
  icon: [1024, 1024, `<div class="bg" style="background-image:url(${img(art + '/0000.png')});filter:contrast(1.3) brightness(1.05) saturate(.6)"></div>
    <div class="vig" style="background:radial-gradient(circle at 44% 55%, rgba(0,0,0,0) 22%, rgba(0,0,0,.55) 52%, rgba(0,0,0,.96) 80%)"></div>`],
  // 1: the hatch
  thumb1_hatch: [1920, 1080, `<div class="bg" style="background-image:url(${img(art + '/0001.png')});filter:contrast(1.28) brightness(1.06) saturate(.55)"></div>
    <div class="vig" style="background:radial-gradient(ellipse 60% 70% at 60% 38%, rgba(0,0,0,0) 30%, rgba(0,0,0,.7) 70%, rgba(0,0,0,.97) 100%)"></div>
    <div class="t serif" style="left:110px;top:640px;font-size:128px;line-height:1.0">someone lives<br>in our attic.</div>
    <div class="t tag" style="left:116px;top:920px;font-size:54px">[HORROR]</div>`],
  // 2: the nest
  thumb2_nest: [1920, 1080, `<div class="bg" style="background-image:url(${img(art + '/0002.png')});filter:contrast(1.04) brightness(1.55) saturate(.85)"></div>
    <div class="vig" style="background:radial-gradient(ellipse 70% 85% at 45% 45%, rgba(0,0,0,0) 45%, rgba(0,0,0,.35) 78%, rgba(0,0,0,.85) 100%)"></div>
    <div class="t serif" style="right:110px;top:150px;font-size:100px;line-height:1.02;text-align:right">he's been up there<br>for 19 days.</div>
    <div class="t serif" style="right:112px;top:390px;font-size:52px;opacity:.9;text-align:right">someone lives in our attic. <span class="tag" style="font-size:36px;font-style:normal">[HORROR]</span></div>`],
  // 3: the photos
  thumb3_photos: [1920, 1080, `<div class="bg" style="background-image:url(${img(art + '/0003_photos.png')});filter:contrast(1.2) brightness(1.15) saturate(.7)"></div>
    <div class="vig" style="background:radial-gradient(ellipse 62% 70% at 60% 40%, rgba(0,0,0,0) 35%, rgba(0,0,0,.6) 72%, rgba(0,0,0,.95) 100%)"></div>
    <div class="t serif" style="left:110px;top:760px;font-size:120px;line-height:1.0">he has photos of us.</div>
    <div class="t serif" style="left:114px;top:905px;font-size:52px;opacity:.9">someone lives in our attic. <span class="tag" style="font-size:36px;font-style:normal">[HORROR]</span></div>`],
};
const browser = await chromium.launch({ executablePath: '/opt/pw-browsers/chromium-1194/chrome-linux/chrome' });
for (const [name, [w, h, body]] of Object.entries(jobs)) {
  const p = await browser.newPage({ viewport: { width: w, height: h } });
  await p.setContent(page(w, h, body)); await p.evaluate(() => document.fonts.ready);
  fs.writeFileSync(`${out}/${name}.png`, await p.screenshot({ type: 'png' }));
  await p.close();
}
await browser.close();
console.log('brand done');
