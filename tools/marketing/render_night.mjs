// node render.mjs world.json views.json outdir
import { chromium } from 'playwright';
import fs from 'fs';
const [,, worldPath, viewsPath, outDir] = process.argv;
const world = JSON.parse(fs.readFileSync(worldPath, 'utf8'));
const views = JSON.parse(fs.readFileSync(viewsPath, 'utf8'));
fs.mkdirSync(outDir, { recursive: true });
const browser = await chromium.launch({ executablePath: '/opt/pw-browsers/chromium-1194/chrome-linux/chrome', args: ['--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist'] });
const W = +(process.env.W || 1920), H = +(process.env.H || 1080);
const page = await browser.newPage({ viewport: { width: W, height: H } });
page.on('console', m => { if (m.type() === 'error') console.log('PAGE', m.text()); });
await page.setContent('<html><body style="margin:0;background:#000"><canvas id="c"></canvas></body></html>');
await page.addScriptTag({ path: '/tmp/claude-0/-home-user-Horror/84f4b59f-d9bd-5c4a-9b16-ad5ba90d0af8/scratchpad/render/node_modules/three/build/three.min.js' });
await page.evaluate(([world, W, H]) => {
  const T = THREE;
  const renderer = new T.WebGLRenderer({ canvas: document.getElementById('c'), antialias: true, preserveDrawingBuffer: true });
  renderer.setSize(W, H, false);
  window.W = W; window.H = H;
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
    if (p.mat === 'Neon') { o.emissive = color; o.emissiveIntensity = 2.2; }
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
    const mesh = new T.Mesh(g, mat(p));
    const c = p.c;
    const m = new T.Matrix4().set(c[3], c[4], c[5], c[0], c[6], c[7], c[8], c[1], c[9], c[10], c[11], c[2], 0, 0, 0, 1);
    if (off) m.multiply(new T.Matrix4().makeTranslation(off[0], off[1], off[2]));
    m.multiply(new T.Matrix4().makeScale(sx, sy, sz));
    mesh.matrixAutoUpdate = false; mesh.matrix.copy(m);
    mesh.userData.pos = new T.Vector3(c[0], c[1], c[2]); mesh.userData.name = p.n;
    scene.add(mesh);
  }
  window.LIGHTS = world.lights;
}, [world, W, H]);
for (const v of views) {
  await page.evaluate((v) => {
    const T = THREE;
    const scene = window.S;
    for (const l of (window.EXTRA || [])) scene.remove(l);
    window.EXTRA = [];
    const add = (o) => { scene.add(o); window.EXTRA.push(o); };
    const outside = v.mode === 'outside';
    const bg = new T.Color(v.bg || (outside ? 0x0d1218 : 0x050505));
    scene.background = bg;
    scene.fog = v.fog ? new T.Fog(bg, v.fog[0], v.fog[1]) : null;
    window.R.toneMappingExposure = v.exposure || 1.0;
    add(new T.HemisphereLight(0x8fa4c8, 0x1a1612, v.ambient ?? (outside ? 0.35 : 0.12)));
    const moon = new T.DirectionalLight(0x9fb4d8, v.moon ?? (outside ? 0.5 : 0.05)); moon.position.set(-60, 90, -80); add(moon);
    const cam = new T.PerspectiveCamera(v.fov || 60, window.W / window.H, 0.1, 3000);
    cam.position.set(...v.pos); cam.lookAt(new T.Vector3(...v.look));
    const cpos = new T.Vector3(...v.pos);
    if (v.flashlight) {
      const sp = new T.SpotLight(0xfff2dc, v.flashlight, 90, 0.42, 0.55, 1.2);
      sp.position.set(v.pos[0] + 0.6, v.pos[1] - 0.5, v.pos[2]);
      sp.target.position.set(...(v.beam || v.look)); add(sp); add(sp.target);
    }
    const ls = window.LIGHTS.map(l => ({ l, d: Math.hypot(l.p[0] - v.pos[0], l.p[1] - v.pos[1], l.p[2] - v.pos[2]) }))
      .filter(x => x.d < (v.lightRadius || 60)).sort((a, b) => a.d - b.d).slice(0, v.maxLights ?? 20);
    for (const { l } of ls) {
      const pl = new T.PointLight(new T.Color(l.col[0], l.col[1], l.col[2]), l.b * (v.lampGain || 22), l.r * 1.6, 1.4);
      pl.position.set(...l.p); add(pl);
    }
    for (const e of (v.lights || [])) {
      const pl = new T.PointLight(new T.Color(e.col), e.b, e.r, e.decay ?? 1.4);
      pl.position.set(...e.p); add(pl);
    }
    for (const g of (v.glow || [])) {
      const m = new T.Mesh(new T.PlaneGeometry(g.w, g.h), new T.MeshBasicMaterial({ color: new T.Color(g.col || 0xffb060), fog: true, side: T.DoubleSide }));
      m.position.set(...g.p); add(m);
    }
    for (const f of (v.figures || [])) {
      const grp = new T.Group();
      const dark = new T.MeshStandardMaterial({ color: new T.Color(f.col || 0x0b0b0c), roughness: 1 });
      const sack = new T.MeshStandardMaterial({ color: new T.Color(0x6e5a3e), roughness: 1 });
      const hole = new T.MeshBasicMaterial({ color: 0x000000 });
      const box = (w, h, d, x, y, z, rx = 0, m = dark) => { const b = new T.Mesh(new T.BoxGeometry(w, h, d), m); b.position.set(x, y, z); b.rotation.x = rx; grp.add(b); return b; };
      box(0.75, 3.3, 0.8, -0.45, 1.65, 0); box(0.75, 3.3, 0.8, 0.45, 1.65, 0);
      box(1.9, 2.6, 0.95, 0, 4.55, 0.25, 0.28);
      box(0.55, 2.9, 0.6, -1.25, 4.2, 0.35, 0.12); box(0.55, 2.9, 0.6, 1.25, 4.2, 0.35, 0.12);
      const head = new T.Mesh(new T.SphereGeometry(0.62, 20, 16), f.sack ? sack : dark); head.scale.set(1, 1.18, 1); head.position.set(0, 6.25, 0.75); grp.add(head);
      if (f.sack) {
        for (const x of [-0.24, 0.24]) { const e = new T.Mesh(new T.SphereGeometry(0.13, 12, 10), hole); e.scale.set(1, 1.2, 0.4); e.position.set(x, 6.35, 1.33); grp.add(e); }
        const knot = new T.Mesh(new T.CylinderGeometry(0.5, 0.62, 0.25, 16), sack); knot.position.set(0, 5.62, 0.6); grp.add(knot);
      }
      grp.scale.setScalar(f.scale || 1);
      grp.position.set(...f.pos);
      grp.lookAt(f.face[0], f.pos[1], f.face[1]);
      add(grp);
    }
    const r = v.radius || 1e9;
    scene.traverse(o => { if (o.isMesh && o.userData.pos) o.visible = o.userData.pos.distanceTo(cpos) < r && !(v.hide || []).includes(o.userData.name); });
    window.R.render(scene, cam);
  }, v);
  const buf = await page.screenshot({ type: 'png' });
  fs.writeFileSync(`${outDir}/${v.name}.png`, buf);
  console.log('rendered', v.name);
}
await browser.close();
