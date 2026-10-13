// node stage.mjs <stage.json> <cacheDir> <views.json> <outDir>
// The house with its Creator Store props in place, exactly as World/Props fit() puts them (turned by
// the entry's Yaw, scaled to the placeholder's box, standing on its base), rendered from the given
// views. stage.json comes from tools/harness/stage_dump.luau. Missing models are downloaded and
// inspected on the way (fetch.py, inspect.luau).
import { chromium } from 'playwright';
import fs from 'fs';
import path from 'path';
import { execFileSync } from 'child_process';
import { fileURLToPath } from 'url';
import { decodeMesh } from './mesh.mjs';

const here = path.dirname(fileURLToPath(import.meta.url));
const repo = path.resolve(here, '../..');
const [,, stagePath, cache, viewsPath, outDir] = process.argv;
const stage = JSON.parse(fs.readFileSync(stagePath, 'utf8'));
const views = JSON.parse(fs.readFileSync(viewsPath, 'utf8'));
fs.mkdirSync(outDir, { recursive: true });
fs.mkdirSync(cache, { recursive: true });

// the models
const models = {};
for (const h of stage.holders) {
  const id = String(h.entry.Id);
  if (models[id] !== undefined) continue;
  const js = path.join(cache, id + '.json');
  try {
    if (!fs.existsSync(js)) {
      execFileSync('python3', [path.join(here, 'fetch.py'), cache, id], { stdio: 'pipe' });
      execFileSync('/root/bin/lune', ['run', path.join(here, 'inspect.luau'), path.join(cache, id + '.bin'), js], { stdio: 'pipe', cwd: repo });
    }
    models[id] = JSON.parse(fs.readFileSync(js, 'utf8'));
  } catch (e) { console.log('model', id, 'failed:', String(e.message).slice(0, 200)); models[id] = null; }
}
const meshIds = new Set(), texIds = new Set();
for (const m of Object.values(models)) {
  if (!m) continue;
  for (const p of m.Parts) {
    if (p.MeshId) meshIds.add(p.MeshId);
    if (p.Special && p.Special.MeshId) meshIds.add(p.Special.MeshId);
    const t = p.TextureID || (p.Special && p.Special.TextureId) || (p.Surface && p.Surface.Color);
    if (t) texIds.add(t);
  }
}
const ids = [...meshIds, ...texIds].filter(x => /^\d+$/.test(x) && !fs.existsSync(path.join(cache, x + '.bin')));
for (let i = 0; i < ids.length; i += 40) {
  try { execFileSync('python3', [path.join(here, 'fetch.py'), cache, ...ids.slice(i, i + 40)], { stdio: 'pipe' }); } catch (e) { console.log('fetch', String(e.stdout || e).slice(0, 300)); }
}
const meshes = {}, textures = {};
for (const id of meshIds) {
  const f = path.join(cache, id + '.bin');
  if (!fs.existsSync(f)) continue;
  try { const m = await decodeMesh(new Uint8Array(fs.readFileSync(f))); meshes[id] = { pos: Array.from(m.pos), nrm: Array.from(m.nrm), uv: Array.from(m.uv), idx: Array.from(m.idx), min: m.min, max: m.max }; }
  catch (e) { console.log('mesh', id, e.message); }
}
for (const id of texIds) {
  const f = path.join(cache, id + '.bin');
  if (!fs.existsSync(f)) continue;
  const b = fs.readFileSync(f);
  const mime = b[0] === 0x89 ? 'image/png' : (b[0] === 0xff ? 'image/jpeg' : null);
  if (mime) textures[id] = `data:${mime};base64,` + b.toString('base64');
}
let tris = {};
for (const [id, m] of Object.entries(models)) {
  if (!m) continue;
  let t = 0; for (const p of m.Parts) { const mid = p.MeshId || (p.Special && p.Special.MeshId); t += mid && meshes[mid] ? meshes[mid].idx.length / 3 : 12; }
  tris[id] = t;
}
console.log('models', Object.keys(models).length, 'meshes', Object.keys(meshes).length, 'textures', Object.keys(textures).length);
for (const [id, t] of Object.entries(tris)) console.log('  ', id, models[id] && models[id].RootName, Math.round(t), 'triangles');

const W = 1280, H = 720;
const browser = await chromium.launch({ executablePath: '/opt/pw-browsers/chromium-1194/chrome-linux/chrome', args: ['--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist'] });
const page = await browser.newPage({ viewport: { width: W, height: H } });
page.on('console', m => { if (m.type() === 'error' || m.type() === 'log') console.log('PAGE', m.text()); });
await page.setContent(`<html><body style="margin:0;background:#000"><canvas id="c" width="${W}" height="${H}"></canvas></body></html>`);
await page.addScriptTag({ path: path.join(here, 'node_modules/three/build/three.min.js') });
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
  // the props
  const loader = new T.TextureLoader(); const texCache = {};
  for (const id in textures) { try { const t = await loader.loadAsync(textures[id]); t.colorSpace = T.SRGBColorSpace; texCache[id] = t; } catch (e) {} }
  const geos = {};
  const meshGeo = (id) => { if (geos[id]) return geos[id]; const m = meshes[id]; if (!m) return null; const g = new T.BufferGeometry();
    g.setAttribute('position', new T.Float32BufferAttribute(m.pos, 3)); g.setAttribute('normal', new T.Float32BufferAttribute(m.nrm, 3)); g.setAttribute('uv', new T.Float32BufferAttribute(m.uv, 2)); g.setIndex(m.idx);
    return (geos[id] = { g, min: m.min, max: m.max }); };
  function authored(model) { // the model as built, in its own world coordinates; and its part box
    const grp = new T.Group(); let mn = [Infinity, Infinity, Infinity], mx = [-Infinity, -Infinity, -Infinity];
    for (const p of model.Parts) {
      if (p.Transparency >= 0.99) continue;
      const pm = cfm(p.CFrame);
      for (const sx of [-1, 1]) for (const sy of [-1, 1]) for (const sz of [-1, 1]) {
        const v = new T.Vector3(sx * p.Size[0] / 2, sy * p.Size[1] / 2, sz * p.Size[2] / 2).applyMatrix4(pm);
        mn = [Math.min(mn[0], v.x), Math.min(mn[1], v.y), Math.min(mn[2], v.z)]; mx = [Math.max(mx[0], v.x), Math.max(mx[1], v.y), Math.max(mx[2], v.z)];
      }
      const col = new T.Color(`rgb(${p.Color[0]},${p.Color[1]},${p.Color[2]})`);
      const texId = p.TextureID || (p.Special && p.Special.TextureId) || (p.Surface && p.Surface.Color);
      const map = texId ? texCache[texId] || null : null;
      const m = new T.MeshStandardMaterial({ color: map ? 0xffffff : col, map, roughness: 0.75, transparent: p.Transparency > 0.02, opacity: 1 - p.Transparency, side: T.DoubleSide });
      let mesh, sx = p.Size[0], sy = p.Size[1], sz = p.Size[2], off = [0, 0, 0];
      const mid = p.MeshId || (p.Special && p.Special.MeshId); const mg = mid ? meshGeo(mid) : null;
      if (mg) {
        mesh = new T.Mesh(mg.g, m);
        const ext = [0, 1, 2].map(k => (mg.max[k] - mg.min[k]) || 1), ctr = [0, 1, 2].map(k => (mg.max[k] + mg.min[k]) / 2);
        if (p.MeshId) { sx /= ext[0]; sy /= ext[1]; sz /= ext[2]; off = [-ctr[0] * sx, -ctr[1] * sy, -ctr[2] * sz]; }
        else { const s = p.Special.Scale || [1, 1, 1]; sx = s[0]; sy = s[1]; sz = s[2]; off = p.Special.Offset || [0, 0, 0]; }
      } else if (/Ball/.test(p.Shape || '')) mesh = new T.Mesh(ball, m); else if (/Cylinder/.test(p.Shape || '')) mesh = new T.Mesh(cyl, m); else mesh = new T.Mesh(box, m);
      const holder = new T.Group(); holder.matrixAutoUpdate = false; holder.matrix.copy(pm);
      mesh.scale.set(sx, sy, sz); mesh.position.set(off[0], off[1], off[2]); holder.add(mesh); grp.add(holder);
    }
    return { grp, mn, mx };
  }
  for (const h of stage.holders) {
    const model = models[String(h.entry.Id)]; if (!model) continue;
    const { grp, mn, mx } = authored(model);
    // 1. turn about its centre by Yaw
    const c0 = new T.Vector3((mn[0] + mx[0]) / 2, (mn[1] + mx[1]) / 2, (mn[2] + mx[2]) / 2);
    const yaw = (h.entry.Yaw || 0) * Math.PI / 180;
    const rot = new T.Matrix4().makeTranslation(c0.x, c0.y, c0.z).multiply(new T.Matrix4().makeRotationY(yaw)).multiply(new T.Matrix4().makeTranslation(-c0.x, -c0.y, -c0.z));
    let bmn = [Infinity, Infinity, Infinity], bmx = [-Infinity, -Infinity, -Infinity];
    for (const sx of [mn[0], mx[0]]) for (const sy of [mn[1], mx[1]]) for (const sz of [mn[2], mx[2]]) {
      const v = new T.Vector3(sx, sy, sz).applyMatrix4(rot);
      bmn = [Math.min(bmn[0], v.x), Math.min(bmn[1], v.y), Math.min(bmn[2], v.z)]; bmx = [Math.max(bmx[0], v.x), Math.max(bmx[1], v.y), Math.max(bmx[2], v.z)];
    }
    const c1 = new T.Vector3((bmn[0] + bmx[0]) / 2, (bmn[1] + bmx[1]) / 2, (bmn[2] + bmx[2]) / 2);
    const bs = [bmx[0] - bmn[0], bmx[1] - bmn[1], bmx[2] - bmn[2]];
    const ps = [h.max[0] - h.min[0], h.max[1] - h.min[1], h.max[2] - h.min[2]];
    const r = [0, 1, 2].map(k => ps[k] / Math.max(bs[k], 0.01));
    let s = h.entry.Fit === 'width' ? Math.min(r[0], r[1] * 1.25) : Math.min(r[0], r[1], r[2]);
    if (h.name === 'Plate' || h.name === 'BrokenPlate') s = Math.max(r[0], r[2]);
    const hgt = bs[1] * s;
    const frame = cfm(h.frame);
    const cz = h.entry.Back ? h.max[2] - bs[2] * s / 2 : (h.min[2] + h.max[2]) / 2;
    const at = new T.Vector3((h.min[0] + h.max[0]) / 2, h.min[1] + hgt / 2, cz).applyMatrix4(frame);
    const frot = new T.Matrix4().extractRotation(frame);
    const M = new T.Matrix4().makeTranslation(at.x, at.y, at.z).multiply(frot).multiply(new T.Matrix4().makeScale(s, s, s)).multiply(new T.Matrix4().makeTranslation(-c1.x, -c1.y, -c1.z)).multiply(rot);
    const outer = new T.Group(); outer.matrixAutoUpdate = false; outer.matrix.copy(M); outer.add(grp);
    outer.traverse(o => { if (o.isMesh) o.userData.pos = at.clone(); });
    scene.add(outer);
  }
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
