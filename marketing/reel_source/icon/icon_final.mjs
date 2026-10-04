import { chromium } from 'playwright';
import fs from 'fs';
const [,, src, out] = process.argv;
const img = 'data:image/png;base64,' + fs.readFileSync(src).toString('base64');
const html = `<!doctype html><html><head><style>html,body{margin:0;width:1024px;height:1024px;overflow:hidden;background:#000}
.bg{position:absolute;inset:0;background:url(${img}) center/cover;filter:contrast(1.14) saturate(1.12) brightness(1.04)}
.vig{position:absolute;inset:0;background:radial-gradient(ellipse 72% 72% at 50% 46%, rgba(0,0,0,0) 48%, rgba(0,0,0,.45) 78%, rgba(0,0,0,.9) 100%)}
.grain{position:absolute;inset:0;mix-blend-mode:soft-light;opacity:.18}</style></head><body>
<div class="bg"></div><div class="vig"></div><canvas class="grain" id="g" width="512" height="512" style="width:1024px;height:1024px"></canvas>
<script>const x=document.getElementById('g').getContext('2d'),d=x.createImageData(512,512);for(let i=0;i<d.data.length;i+=4){const v=128+(Math.random()-.5)*140;d.data[i]=d.data[i+1]=d.data[i+2]=v;d.data[i+3]=255}x.putImageData(d,0,0)</script></body></html>`;
const b = await chromium.launch({ executablePath: '/opt/pw-browsers/chromium-1194/chrome-linux/chrome' });
const p = await b.newPage({ viewport: { width: 1024, height: 1024 } });
await p.setContent(html); fs.writeFileSync(out, await p.screenshot({ type: 'png' })); await b.close();
