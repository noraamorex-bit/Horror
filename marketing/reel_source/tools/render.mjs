// node render.mjs world.json views.json outdir
import { chromium } from 'playwright';
import fs from 'fs';
const [,, worldPath, viewsPath, outDir] = process.argv;
const world = JSON.parse(fs.readFileSync(worldPath, 'utf8'));
const ARTIMG = {}; for (const p of world.parts) if (p.art && fs.existsSync(`../art/${p.art}.png`)) ARTIMG[p.art] = 'data:image/png;base64,' + fs.readFileSync(`../art/${p.art}.png`).toString('base64');
const views = JSON.parse(fs.readFileSync(viewsPath, 'utf8'));
fs.mkdirSync(outDir, { recursive: true });
const browser = await chromium.launch({ executablePath: '/opt/pw-browsers/chromium-1194/chrome-linux/chrome', args: ['--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist'] });
const page = await browser.newPage({ viewport: { width: 1280, height: 720 } });
page.on('console', m => { if (m.type() === 'error') console.log('PAGE', m.text()); });
await page.setContent('<html><body style="margin:0;background:#000"><canvas id="c" width="1280" height="720"></canvas></body></html>');
await page.addScriptTag({ path: 'node_modules/three/build/three.min.js' });
await page.evaluate(([world, ARTIMG]) => {
  const T = THREE;
  const renderer = new T.WebGLRenderer({ canvas: document.getElementById('c'), antialias: true, preserveDrawingBuffer: true });
  renderer.setSize(1280, 720, false);
  renderer.outputColorSpace = T.SRGBColorSpace;
  renderer.toneMapping = T.ACESFilmicToneMapping;
  window.R = renderer;
  const geoCache = {};
  const unitBox = new T.BoxGeometry(1, 1, 1);
  const unitSphere = new T.SphereGeometry(0.5, 20, 14);
  const unitCyl = new T.CylinderGeometry(0.5, 0.5, 1, 24); unitCyl.rotateZ(-Math.PI / 2);
  const wedge = (() => { // Roblox wedge: slope rises toward +Z... high edge at back (+Z), low at front (-Z)
    const g = new T.BufferGeometry();
    const v = [ // triangular prism: cross-section in YZ: (-.5,-.5) (-.5,+.5) (+.5,+.5) as (y,z)
      [-.5,-.5,-.5],[-.5,-.5,.5],[-.5,.5,.5], [.5,-.5,-.5],[.5,-.5,.5],[.5,.5,.5] ];
    const f = [[0,2,1],[3,4,5],[0,1,4],[0,4,3],[1,2,5],[1,5,4],[0,3,5],[0,5,2]];
    const pos = []; for (const t of f) for (const i of t) pos.push(...v[i]);
    g.setAttribute('position', new T.Float32BufferAttribute(pos, 3)); g.computeVertexNormals(); return g; })();
  const mats = {};
  function mat(p) {
    const key = p.col.join(',') + p.mat + p.tr;
    if (mats[key]) return mats[key];
    const color = new T.Color(`rgb(${p.col[0]},${p.col[1]},${p.col[2]})`);
    const o = { color, roughness: 0.8, metalness: 0 };
    if (p.mat === 'Neon') { o.emissive = color; o.emissiveIntensity = 1.2; }
    if (p.mat === 'Metal' || p.mat === 'DiamondPlate' || p.mat === 'CorrodedMetal') { o.metalness = 0.5; o.roughness = 0.45; }
    if (p.mat === 'Glass') { o.transparent = true; o.opacity = Math.min(0.55, 1 - p.tr); o.roughness = 0.1; }
    else if (p.tr > 0.02) { o.transparent = true; o.opacity = 1 - p.tr; }
    if (p.mat === 'SmoothPlastic' || p.mat === 'Marble') o.roughness = 0.45;
    return (mats[key] = new T.MeshStandardMaterial(o));
  }
  const scene = new T.Scene();
  window.S = scene;
  for (const p of world.parts) {
    let g, sx = p.s[0], sy = p.s[1], sz = p.s[2];
    let off = null;
    if (p.m && (p.m.t === 'Sphere' || p.m.t === 'Brick' || p.m.t === 'Wedge' || p.m.t === 'Cylinder')) {
      g = p.m.t === 'Sphere' ? unitSphere : p.m.t === 'Wedge' ? wedge : p.m.t === 'Cylinder' ? unitCyl : unitBox;
      sx *= p.m.s[0]; sy *= p.m.s[1]; sz *= p.m.s[2]; off = p.m.o;
    } else if (p.sh === 'Ball') { g = unitSphere; const d = Math.min(sx, sy, sz); sx = sy = sz = d; }
    else if (p.sh === 'Cylinder') { g = unitCyl; const d = Math.min(sy, sz); sy = sz = d; }
    else if (p.sh === 'Wedge') g = wedge;
    else g = unitBox;
    let mesh = new T.Mesh(g, mat(p));
    if (p.art && ARTIMG[p.art]) { const tx = new T.TextureLoader().load(ARTIMG[p.art]); tx.colorSpace = T.SRGBColorSpace; mesh = new T.Mesh(g, new T.MeshStandardMaterial({ map: tx, roughness: 0.7 })); }
    const c = p.c;
    const m = new T.Matrix4().set(c[3], c[4], c[5], c[0], c[6], c[7], c[8], c[1], c[9], c[10], c[11], c[2], 0, 0, 0, 1);
    if (off) m.multiply(new T.Matrix4().makeTranslation(off[0], off[1], off[2]));
    m.multiply(new T.Matrix4().makeScale(sx, sy, sz));
    mesh.matrixAutoUpdate = false; mesh.matrix.copy(m);
    mesh.userData.pos = new T.Vector3(c[0], c[1], c[2]);
    scene.add(mesh);
  }
  window.LIGHTS = world.lights;
}, [world, ARTIMG]);
await page.waitForTimeout(1500);
for (const v of views) {
  await page.evaluate((v) => {
    const T = THREE;
    const scene = window.S;
    for (const l of (window.EXTRA || [])) scene.remove(l);
    window.EXTRA = [];
    const add = (l) => { scene.add(l); window.EXTRA.push(l); };
    const outside = v.mode === 'outside';
    scene.background = new T.Color(outside ? 0x3a4450 : 0x101010);
    scene.fog = v.fog ? new T.Fog(scene.background, v.fog[0], v.fog[1]) : null;
    add(new T.HemisphereLight(0xdde6ff, 0x3a3228, outside ? 1.2 : 0.8));
    const sun = new T.DirectionalLight(0xffffff, outside ? 1.6 : 0.6); sun.position.set(40, 80, -60); add(sun);
    const cam = new T.PerspectiveCamera(v.fov || 70, 1280 / 720, 0.1, 2000);
    cam.position.set(...v.pos); cam.lookAt(new T.Vector3(...v.look));
    if (!outside) { const head = new T.PointLight(0xfff0dd, 1.5, 0, 0); head.position.set(...v.pos); add(head); }
    const r = v.radius || 1e9;
    const cpos = new T.Vector3(...v.pos);
    scene.traverse(o => { if (o.isMesh) o.visible = o.userData.pos.distanceTo(cpos) < r; });
    window.R.render(scene, cam);
  }, v);
  const buf = await page.screenshot({ type: 'png' });
  fs.writeFileSync(`${outDir}/${v.name}.png`, buf);
  console.log('rendered', v.name);
}
await browser.close();
