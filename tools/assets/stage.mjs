// node stage.mjs <stage.json> <cacheDir> <views.json> <outDir>
// The house with its Creator Store props in place, exactly as World/Props fit() puts them (turned by
// the entry's Yaw, scaled to the placeholder's box, standing on its base), rendered from the given
// views. stage.json comes from tools/harness/stage_dump.luau. Missing models are downloaded and
// inspected on the way (fetch.py, inspect.luau).
import { chromium } from 'playwright';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { loadProps } from './propload.mjs';

const here = path.dirname(fileURLToPath(import.meta.url));
const [,, stagePath, cache, viewsPath, outDir] = process.argv;
const stage = JSON.parse(fs.readFileSync(stagePath, 'utf8'));
const views = JSON.parse(fs.readFileSync(viewsPath, 'utf8'));
fs.mkdirSync(outDir, { recursive: true });
fs.mkdirSync(cache, { recursive: true });

const { models, meshes, textures, tris } = await loadProps(stage, cache);
const W = 1280, H = 720;
const browser = await chromium.launch({ executablePath: '/opt/pw-browsers/chromium-1194/chrome-linux/chrome', args: ['--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist'] });
const page = await browser.newPage({ viewport: { width: W, height: H } });
page.on('console', m => { if (m.type() === 'error' || m.type() === 'log') console.log('PAGE', m.text()); });
await page.setContent(`<html><body style="margin:0;background:#000"><canvas id="c" width="${W}" height="${H}"></canvas></body></html>`);
await page.addScriptTag({ path: path.join(here, 'node_modules/three/build/three.min.js') });
await page.addScriptTag({ path: path.join(here, 'propscene.js') });
await page.evaluate(async ([stage, models, meshes, textures, W, H]) => {
  const T = THREE;
  const renderer = new T.WebGLRenderer({ canvas: document.getElementById('c'), antialias: true, preserveDrawingBuffer: true });
  renderer.setSize(W, H, false); renderer.outputColorSpace = T.SRGBColorSpace; renderer.toneMapping = T.ACESFilmicToneMapping;
  window.R = renderer;
  const scene = new T.Scene(); window.S = scene;
  const box = new T.BoxGeometry(1, 1, 1), ball = new T.SphereGeometry(0.5, 20, 14), cyl = new T.CylinderGeometry(0.5, 0.5, 1, 24); cyl.rotateZ(-Math.PI / 2);
  const cfm = (c) => new T.Matrix4().set(c[3], c[4], c[5], c[0], c[6], c[7], c[8], c[1], c[9], c[10], c[11], c[2], 0, 0, 0, 1);
  const mats = {};
  const mat = (col, matName, tr) => {
    const k = col.join(',') + matName + tr; if (mats[k]) return mats[k];
    const color = new T.Color(`rgb(${col[0]},${col[1]},${col[2]})`);
    const o = { color, roughness: 0.8 };
    if (/Neon/.test(matName)) { o.emissive = color; o.emissiveIntensity = 1.2; }
    if (/Glass/.test(matName)) { o.transparent = true; o.opacity = 0.4; }
    else if (tr > 0.02) { o.transparent = true; o.opacity = 1 - tr; }
    return (mats[k] = new T.MeshStandardMaterial(o));
  };
  // which placeholders get a model
  const swapped = new Set(stage.holders.filter(h => models[String(h.entry.Id)]).map(h => h.key));
  for (const p of stage.parts) {
    if (p.ph && swapped.has(p.ph)) continue;
    let g = box, sx = p.s[0], sy = p.s[1], sz = p.s[2];
    if (p.m && /Sphere/.test(p.m.t)) g = ball; else if (p.sh === 'Ball') { g = ball; const d = Math.min(sx, sy, sz); sx = sy = sz = d; }
    else if (p.sh === 'Cylinder') { g = cyl; const d = Math.min(sy, sz); sy = sz = d; }
    const mesh = new T.Mesh(g, mat(p.col, p.mat, p.tr));
    const m = cfm(p.c).multiply(new T.Matrix4().makeScale(sx, sy, sz));
    mesh.matrixAutoUpdate = false; mesh.matrix.copy(m); mesh.userData.pos = new T.Vector3(p.c[0], p.c[1], p.c[2]);
    scene.add(mesh);
  }
  await window.addProps(scene, stage, models, meshes, textures);
  scene.updateMatrixWorld(true);
}, [stage, models, meshes, textures, W, H]);
for (const v of views) {
  await page.evaluate((v) => {
    const T = THREE, scene = window.S;
    for (const l of (window.EXTRA || [])) scene.remove(l);
    window.EXTRA = []; const add = (l) => { scene.add(l); window.EXTRA.push(l); };
    scene.background = new T.Color(0x101010);
    add(new T.HemisphereLight(0xfff4e6, 0x3a3228, 1.1));
    const sun = new T.DirectionalLight(0xffffff, 0.6); sun.position.set(40, 80, -60); add(sun);
    const cam = new T.PerspectiveCamera(v.fov || 70, 1280 / 720, 0.1, 2000);
    cam.position.set(...v.pos); cam.lookAt(new T.Vector3(...v.look));
    const head = new T.PointLight(0xfff0dd, 1.6, 0, 0); head.position.set(...v.pos); add(head);
    const r = v.radius || 1e9, cpos = new T.Vector3(...v.pos);
    scene.traverse(o => { if (o.isMesh && o.userData.pos) o.visible = o.userData.pos.distanceTo(cpos) < r; });
    window.R.render(scene, cam);
  }, v);
  fs.writeFileSync(path.join(outDir, v.name + '.png'), await page.screenshot({ type: 'png' }));
  console.log('rendered', v.name);
}
await browser.close();
