// node preview_close.mjs <inspect.json> <cacheDir> <out.png> [label]: close-ups (face front, 3/4, full body 3/4 in low light)
// A model from the Creator Store, seen before it goes in the game: four views (its -Z front, its
// +X side, its back, from above) on a 1-stud grid with a 5.5-stud person for scale and an arrow
// on the floor pointing along -Z (Roblox's "forward"). Meshes and textures are downloaded with
// fetch.py into cacheDir and decoded with mesh.mjs.
import { chromium } from 'playwright';
import fs from 'fs';
import path from 'path';
import { execFileSync } from 'child_process';
import { fileURLToPath } from 'url';
import { decodeMesh } from './mesh.mjs';

const here = path.dirname(fileURLToPath(import.meta.url));
const [,, jsonPath, cache, outPath, label] = process.argv;
const model = JSON.parse(fs.readFileSync(jsonPath, 'utf8'));
fs.mkdirSync(cache, { recursive: true });

const meshIds = new Set(), texIds = new Set();
for (const p of model.Parts) {
  if (p.MeshId) meshIds.add(p.MeshId);
  if (p.Special && p.Special.MeshId) meshIds.add(p.Special.MeshId);
  if (p.TextureID) texIds.add(p.TextureID);
  if (p.Special && p.Special.TextureId) texIds.add(p.Special.TextureId);
  if (p.Surface && p.Surface.Color) texIds.add(p.Surface.Color);
  for (const d of p.Decals || []) if (d.Texture) texIds.add(d.Texture);
}
const ids = [...meshIds, ...texIds].filter(x => /^\d+$/.test(x));
if (ids.length) {
  try { execFileSync('python3', [path.join(here, 'fetch.py'), cache, ...ids], { stdio: 'pipe' }); } catch (e) { console.log('fetch:', String(e.stdout || e)); }
}
const meshes = {};
for (const id of meshIds) {
  const f = path.join(cache, id + '.bin');
  if (!fs.existsSync(f)) continue;
  try {
    const m = await decodeMesh(new Uint8Array(fs.readFileSync(f)));
    meshes[id] = { pos: Array.from(m.pos), nrm: Array.from(m.nrm), uv: Array.from(m.uv), idx: Array.from(m.idx), min: m.min, max: m.max };
  } catch (e) { console.log('mesh', id, e.message); }
}
const textures = {};
for (const id of texIds) {
  const f = path.join(cache, id + '.bin');
  if (!fs.existsSync(f)) continue;
  const b = fs.readFileSync(f);
  const mime = b[0] === 0x89 ? 'image/png' : (b[0] === 0xff ? 'image/jpeg' : null);
  // (an image asset can come wrapped in a model file pointing at the real image: skip those)
  if (mime) textures[id] = `data:${mime};base64,` + b.toString('base64');
}

const W = 1024, H = 1024;
const browser = await chromium.launch({ executablePath: '/opt/pw-browsers/chromium-1194/chrome-linux/chrome', args: ['--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist'] });
const page = await browser.newPage({ viewport: { width: W, height: H } });
page.on('console', m => { if (m.type() === 'error') console.log('PAGE', m.text()); });
await page.setContent(`<html><body style="margin:0;background:#777"><canvas id="c" width="${W}" height="${H}"></canvas></body></html>`);
await page.addScriptTag({ path: path.join(here, 'node_modules/three/build/three.min.js') });
const shot = await page.evaluate(async ([model, meshes, textures, W, H, label]) => {
  const T = THREE;
  const renderer = new T.WebGLRenderer({ canvas: document.getElementById('c'), antialias: true, preserveDrawingBuffer: true });
  renderer.setSize(W, H, false);
  renderer.outputColorSpace = T.SRGBColorSpace;
  renderer.setScissorTest(true);
  const scene = new T.Scene();
  scene.add(new T.HemisphereLight(0x9fb0d0, 0x202020, 0.8));
  const sun = new T.DirectionalLight(0xfff0dd, 2.2); sun.position.set(20, 40, -50); scene.add(sun);
  const rim = new T.DirectionalLight(0x7f97cf, 1.2); rim.position.set(-30, 20, 40); scene.add(rim);
  const loader = new T.TextureLoader();
  const texCache = {};
  for (const id in textures) {
    try { const t = await loader.loadAsync(textures[id]); t.colorSpace = T.SRGBColorSpace; texCache[id] = t; } catch (e) { /* not an image */ }
  }
  const tex = (id) => texCache[id] || null;
  const geos = {};
  const meshGeo = (id) => {
    if (geos[id]) return geos[id];
    const m = meshes[id]; if (!m) return null;
    const g = new T.BufferGeometry();
    g.setAttribute('position', new T.Float32BufferAttribute(m.pos, 3));
    g.setAttribute('normal', new T.Float32BufferAttribute(m.nrm, 3));
    g.setAttribute('uv', new T.Float32BufferAttribute(m.uv, 2));
    g.setIndex(m.idx);
    return (geos[id] = { g, min: m.min, max: m.max });
  };
  const box = new T.BoxGeometry(1, 1, 1), ball = new T.SphereGeometry(0.5, 24, 16), cyl = new T.CylinderGeometry(0.5, 0.5, 1, 24); cyl.rotateZ(-Math.PI / 2);
  const all = new T.Group(); scene.add(all);
  for (const p of model.Parts) {
    if (p.Transparency >= 0.99) continue;
    const col = new T.Color(`rgb(${p.Color[0]},${p.Color[1]},${p.Color[2]})`);
    const texId = p.TextureID || (p.Special && p.Special.TextureId) || (p.Surface && p.Surface.Color);
    const map = texId ? tex(texId) : null;
    const mat = new T.MeshStandardMaterial({ color: map ? 0xffffff : col, map, roughness: 0.75, transparent: p.Transparency > 0.02, opacity: 1 - p.Transparency, side: T.DoubleSide });
    if (/Neon/.test(p.Material)) { mat.emissive = col; mat.emissiveIntensity = 1; }
    let mesh, sx = p.Size[0], sy = p.Size[1], sz = p.Size[2], off = [0, 0, 0];
    const mid = p.MeshId || (p.Special && p.Special.MeshId);
    const mg = mid ? meshGeo(mid) : null;
    if (mg) {
      mesh = new T.Mesh(mg.g, mat);
      const ext = [mg.max[0] - mg.min[0], mg.max[1] - mg.min[1], mg.max[2] - mg.min[2]].map(v => v || 1);
      const ctr = [(mg.max[0] + mg.min[0]) / 2, (mg.max[1] + mg.min[1]) / 2, (mg.max[2] + mg.min[2]) / 2];
      if (p.MeshId) { // MeshPart: the mesh's box is fitted to the part's size, centred on it
        sx /= ext[0]; sy /= ext[1]; sz /= ext[2];
        off = [-ctr[0] * sx, -ctr[1] * sy, -ctr[2] * sz];
      } else { // SpecialMesh: mesh units times Scale, plus Offset
        const s = p.Special.Scale || [1, 1, 1]; sx = s[0]; sy = s[1]; sz = s[2]; off = p.Special.Offset || [0, 0, 0];
      }
    } else if (/Ball/.test(p.Shape || '') || (p.Special && /Sphere/.test(p.Special.Type))) { mesh = new T.Mesh(ball, mat); }
    else if (/Cylinder/.test(p.Shape || '')) { mesh = new T.Mesh(cyl, mat); }
    else mesh = new T.Mesh(box, mat);
    const c = p.CFrame;
    const m4 = new T.Matrix4().set(c[3], c[4], c[5], c[0], c[6], c[7], c[8], c[1], c[9], c[10], c[11], c[2], 0, 0, 0, 1);
    const holder = new T.Group(); holder.matrixAutoUpdate = false; holder.matrix.copy(m4);
    mesh.scale.set(sx, sy, sz); mesh.position.set(off[0], off[1], off[2]);
    holder.add(mesh); all.add(holder);
  }
  all.updateMatrixWorld(true);
  const bb = new T.Box3().setFromObject(all);
  const size = bb.getSize(new T.Vector3()), center = bb.getCenter(new T.Vector3());
  // floor grid at the model's base, an arrow along -Z, a 5.5-stud person beside it
  const floorY = bb.min.y;
  const span = Math.max(size.x, size.z, 6) + 6;
  const grid = new T.GridHelper(Math.ceil(span), Math.ceil(span), 0x333333, 0x555555); grid.position.set(center.x, floorY, center.z); scene.add(grid);
  const arrow = new T.ArrowHelper(new T.Vector3(0, 0, -1), new T.Vector3(center.x, floorY + 0.02, bb.min.z - 0.3), 2.5, 0xff3030, 0.8, 0.5); scene.add(arrow);
  const person = new T.Mesh(new T.BoxGeometry(1.4, 5.5, 0.8), new T.MeshStandardMaterial({ color: 0x3a6ea5 }));
  person.position.set(bb.max.x + 1.8, floorY + 2.75, center.z); scene.add(person);
  const views = [
    ['FACE', new T.Vector3(0.05, 0.05, -1), 0.22, 0.88], ['FACE 3/4', new T.Vector3(0.7, 0.1, -0.8), 0.25, 0.86],
    ['BODY 3/4', new T.Vector3(0.6, 0.15, -1), 1.0, 0.5], ['TORSO', new T.Vector3(-0.3, 0.05, -1), 0.45, 0.62],
  ];
  const cam = new T.PerspectiveCamera(35, 1, 0.05, 2000);
  const r = Math.max(size.length() * 0.5, 3.5);
  const dist = r / Math.sin((35 / 2) * Math.PI / 180) * 1.05;
  renderer.setClearColor(0x8a8a8a);
  grid.visible = false; arrow.visible = false; person.visible = false;
  renderer.setClearColor(0x101012);
  views.forEach(([, dir, zoom, hfrac], i) => {
    const x = (i % 2) * (W / 2), y = (1 - Math.floor(i / 2)) * (H / 2);
    renderer.setViewport(x, y, W / 2, H / 2); renderer.setScissor(x, y, W / 2, H / 2);
    const tgt = new T.Vector3(center.x, bb.min.y + size.y * hfrac, center.z);
    cam.position.copy(tgt.clone().add(dir.clone().normalize().multiplyScalar(dist * zoom)));
    cam.lookAt(tgt);
    renderer.render(scene, cam);
  });
  // labels
  const out = document.createElement('canvas'); out.width = W; out.height = H;
  const g = out.getContext('2d'); g.drawImage(renderer.domElement, 0, 0);
  g.font = 'bold 22px sans-serif'; g.fillStyle = '#fff'; g.strokeStyle = '#000'; g.lineWidth = 4;
  views.forEach(([name], i) => { const x = (i % 2) * (W / 2) + 12, y = Math.floor(i / 2) * (H / 2) + 30; g.strokeText(name, x, y); g.fillText(name, x, y); });
  const info = `${label || ''}  ${size.x.toFixed(1)} x ${size.y.toFixed(1)} x ${size.z.toFixed(1)} studs, ${model.Parts.length} parts`;
  g.strokeText(info, 12, H - 14); g.fillText(info, 12, H - 14);
  g.strokeStyle = '#000'; g.lineWidth = 2; g.beginPath(); g.moveTo(W / 2, 0); g.lineTo(W / 2, H); g.moveTo(0, H / 2); g.lineTo(W, H / 2); g.stroke();
  await new Promise(r => setTimeout(r, 50));
  return out.toDataURL('image/png');
}, [model, meshes, textures, W, H, label]);
fs.writeFileSync(outPath, Buffer.from(shot.split(',')[1], 'base64'));
await browser.close();
console.log('wrote', outPath);
