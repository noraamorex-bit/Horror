// node icon_avatar.mjs bg.png avatar.png out.png — the attic scene with a real Roblox avatar in front
import { chromium } from 'playwright';
import fs from 'fs';
const [,, bgPath, avPath, out] = process.argv;
const u = (p) => 'data:image/png;base64,' + fs.readFileSync(p).toString('base64');
const bg = u(bgPath), av = u(avPath);
const AV = 'left:318px;bottom:-70px;width:720px;height:720px';
const html = `<!doctype html><html><head><style>html,body{margin:0;width:1024px;height:1024px;overflow:hidden;background:#000}
.bg{position:absolute;inset:0;background:url(${bg}) center/cover;filter:contrast(1.14) saturate(1.1) brightness(1.02)}
.av{position:absolute;${AV}}
.av img{position:absolute;inset:0;width:100%;height:100%;filter:brightness(.5) contrast(1.18) saturate(.9) drop-shadow(0 0 3px rgba(150,185,255,.55))}
.m{position:absolute;${AV};-webkit-mask:url(${av}) center/contain no-repeat;mask:url(${av}) center/contain no-repeat}
.glow{background:radial-gradient(ellipse 55% 45% at 50% 92%, rgba(150,190,255,.75), rgba(150,190,255,0) 70%);mix-blend-mode:screen}
.shade{background:linear-gradient(to bottom, rgba(4,6,14,.55), rgba(4,6,14,0) 45%);mix-blend-mode:multiply}
.rim{background:linear-gradient(100deg, rgba(120,150,230,.0) 60%, rgba(120,150,230,.35) 100%);mix-blend-mode:screen}
.vig{position:absolute;inset:0;background:radial-gradient(ellipse 75% 75% at 50% 44%, rgba(0,0,0,0) 50%, rgba(0,0,0,.45) 80%, rgba(0,0,0,.9) 100%)}
.grain{position:absolute;inset:0;mix-blend-mode:soft-light;opacity:.18}</style></head><body>
<div class="bg"></div>
<div class="av"><img src="${av}"></div>
<div class="m glow"></div><div class="m shade"></div><div class="m rim"></div>
<div class="vig"></div><canvas class="grain" id="g" width="512" height="512" style="width:1024px;height:1024px"></canvas>
<script>const x=document.getElementById('g').getContext('2d'),d=x.createImageData(512,512);for(let i=0;i<d.data.length;i+=4){const v=128+(Math.random()-.5)*140;d.data[i]=d.data[i+1]=d.data[i+2]=v;d.data[i+3]=255}x.putImageData(d,0,0)</script></body></html>`;
const b = await chromium.launch({ executablePath: '/opt/pw-browsers/chromium-1194/chrome-linux/chrome' });
const p = await b.newPage({ viewport: { width: 1024, height: 1024 } });
await p.setContent(html); await p.waitForTimeout(200);
fs.writeFileSync(out, await p.screenshot({ type: 'png' })); await b.close();
