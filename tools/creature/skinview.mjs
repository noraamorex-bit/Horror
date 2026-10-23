// node tools/creature/skinview.mjs <poses.json> <cacheDir> <outDir> [views.json]
// Renders the v112 creature (assets/Creature.rbxm: a skinned MeshPart) posed by the game's own
// SkinPose (poses.json from pose_dump.luau), the way Roblox skins it: each bone's world frame is its
// parent's times its rest CFrame times its Transform; vertices follow their four bones through the
// inverse of the mesh file's bind frames. One PNG per frame (all views side by side) in outDir.
// views.json: [{ "pos": [x, y, z], "look": [x, y, z], "fov": 40 }, ...] in the model's space (feet at
// y = -6.83, facing -Z); default: front 3/4, side, and a face close-up.
import { chromium } from '../assets/node_modules/playwright/index.mjs';
import fs from 'fs';
import path from 'path';
import { execFileSync } from 'child_process';
import { fileURLToPath } from 'url';
import { decodeMesh } from '../assets/mesh.mjs';

const here = path.dirname(fileURLToPath(import.meta.url));
const [,, posesPath, cache, outDir, viewsPath] = process.argv;
const poses = JSON.parse(fs.readFileSync(posesPath, 'utf8'));
fs.mkdirSync(outDir, { recursive: true });
const MESH = '17737123792', COLOR = '17737123793', NORMAL = '17737124050', ROUGH = '17737123673';
for (const id of [MESH, COLOR, NORMAL, ROUGH]) {
  if (!fs.existsSync(path.join(cache, id + '.bin'))) execFileSync('python3', [path.join(here, '../assets/fetch.py'), cache, id], { stdio: 'pipe' });
}
const m = await decodeMesh(new Uint8Array(fs.readFileSync(path.join(cache, MESH + '.bin'))));
const img = (id) => 'data:image/png;base64,' + fs.readFileSync(path.join(cache, id + '.bin')).toString('base64');
const views = viewsPath ? JSON.parse(fs.readFileSync(viewsPath, 'utf8')) : [
  { pos: [7, 1.5, -13], look: [0, -0.5, 0], fov: 45 },
  { pos: [15, 0, 0], look: [0, -0.5, 0], fov: 45 },
  { pos: [1.2, 4.6, -5.2], look: [0, 4.2, 0], fov: 38 },
];
const W = 540, H = 960;
const browser = await chromium.launch({ executablePath: '/opt/pw-browsers/chromium-1194/chrome-linux/chrome', args: ['--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist'] });
const page = await browser.newPage({ viewport: { width: W * views.length, height: H } });
page.on('console', msg => { if (msg.type() === 'error') console.log('PAGE', msg.text()); });
await page.setContent(`<html><body style="margin:0;background:#000"><canvas id="c" width="${W * views.length}" height="${H}"></canvas></body></html>`);
await page.addScriptTag({ path: path.join(here, '../assets/node_modules/three/build/three.min.js') });
await page.evaluate(async ([mesh, poses, tex, views, W, H]) => {
  const T = THREE;
  const r = new T.WebGLRenderer({ canvas: document.getElementById('c'), antialias: true, preserveDrawingBuffer: true });
  r.setSize(W * views.length, H, false); r.outputColorSpace = T.SRGBColorSpace; r.setScissorTest(true);
  r.toneMapping = T.ACESFilmicToneMapping; r.toneMappingExposure = 1.1;
  const scene = new T.Scene();
  scene.add(new T.HemisphereLight(0x8a96b8, 0x141210, 0.55));
  const key = new T.DirectionalLight(0xfff0e0, 2.4); key.position.set(-6, 10, -12); scene.add(key);
  const rim = new T.DirectionalLight(0x8fa8ff, 1.8); rim.position.set(10, 6, 12); scene.add(rim);
  const floor = new T.Mesh(new T.PlaneGeometry(60, 60), new T.MeshStandardMaterial({ color: 0x24201c, roughness: 0.9 }));
  floor.rotation.x = -Math.PI / 2; floor.position.y = -6.83; scene.add(floor);
  const grid = new T.GridHelper(40, 40, 0x3a3530, 0x2c2824); grid.position.y = -6.82; scene.add(grid);
  const loader = new T.TextureLoader();
  const load = async (u, srgb) => { const t = await loader.loadAsync(u); if (srgb) t.colorSpace = T.SRGBColorSpace; t.flipY = false; return t; };
  const [cmap, nmap, rmap] = await Promise.all([load(tex.color, true), load(tex.normal), load(tex.rough)]);
  // (the decoder flips v for its own previews: undo it, the textures are loaded unflipped)
  const uv = new Float32Array(mesh.uv); for (let i = 1; i < uv.length; i += 2) uv[i] = 1 - uv[i];
  const g = new T.BufferGeometry();
  g.setAttribute('position', new T.Float32BufferAttribute(mesh.pos, 3));
  g.setAttribute('normal', new T.Float32BufferAttribute(mesh.nrm, 3));
  g.setAttribute('uv', new T.Float32BufferAttribute(uv, 2));
  g.setAttribute('skinIndex', new T.Uint16BufferAttribute(mesh.skin.skinIndex, 4));
  g.setAttribute('skinWeight', new T.Float32BufferAttribute(mesh.skin.skinWeight, 4));
  g.setIndex(mesh.idx);
  const mat = new T.MeshStandardMaterial({ map: cmap, normalMap: nmap, roughnessMap: rmap, roughness: 1, metalness: 0 });
  const cf = (a) => new T.Matrix4().set(a[3], a[4], a[5], a[0], a[6], a[7], a[8], a[1], a[9], a[10], a[11], a[2], 0, 0, 0, 1);
  // bones from the instances (their rest CFrames, hierarchy), in the mesh file's bone order
  const inst = {}; for (const b of poses.bones) inst[b.name] = b;
  const tb = {};
  for (const b of poses.bones) { const o = new T.Bone(); o.name = b.name; o.matrixAutoUpdate = false; tb[b.name] = o; }
  const rootGroup = new T.Group(); scene.add(rootGroup);
  for (const b of poses.bones) (b.parent ? tb[b.parent] : rootGroup).add(tb[b.name]);
  const ordered = mesh.skin.bones.map(b => tb[b.name] || new T.Bone());
  const inverses = mesh.skin.bones.map(b => {
    const r = b.rot;
    return new T.Matrix4().set(r[0], r[1], r[2], b.pos[0], r[3], r[4], r[5], b.pos[1], r[6], r[7], r[8], b.pos[2], 0, 0, 0, 1).invert();
  });
  const sk = new T.SkinnedMesh(g, mat);
  sk.frustumCulled = false;
  sk.bind(new T.Skeleton(ordered, inverses), new T.Matrix4());
  rootGroup.add(sk);
  const cam = new T.PerspectiveCamera(45, W / H, 0.05, 500);
  window.renderFrame = (f) => {
    const fr = poses.frames[f];
    for (const b of poses.bones) {
      const tr = fr.transforms[b.name];
      const local = cf(b.rest);
      if (tr) local.multiply(cf(tr));
      tb[b.name].matrix.copy(local);
    }
    rootGroup.updateMatrixWorld(true);
    r.setClearColor(0x0c0c0e);
    views.forEach((v, i) => {
      r.setViewport(i * W, 0, W, H); r.setScissor(i * W, 0, W, H);
      cam.fov = v.fov || 45; cam.updateProjectionMatrix();
      cam.position.set(...v.pos); cam.lookAt(new T.Vector3(...v.look));
      r.render(scene, cam);
    });
    return r.domElement.toDataURL('image/png');
  };
}, [{ pos: Array.from(m.pos), nrm: Array.from(m.nrm), uv: Array.from(m.uv), idx: Array.from(m.idx), skin: { bones: m.skin.bones, skinIndex: Array.from(m.skin.skinIndex), skinWeight: Array.from(m.skin.skinWeight) } },
    poses, { color: img(COLOR), normal: img(NORMAL), rough: img(ROUGH) }, views, W, H]);
for (let f = 0; f < poses.frames.length; f++) {
  const url = await page.evaluate((f) => window.renderFrame(f), f);
  fs.writeFileSync(path.join(outDir, String(f).padStart(4, '0') + '.png'), Buffer.from(url.split(',')[1], 'base64'));
}
await browser.close();
console.log('skinview:', poses.frames.length, 'frames ->', outDir);
