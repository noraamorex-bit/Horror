// node film.mjs world.json creature_frames.json spec.json outdir [from] [to]
// spec: { W, H, shots: { name: { center:[x,y,z], lampRadius, maxLamps, lights:[{p,col,b,r}] } },
//         frames: [{ f, shot, cam:{pos,look,fov,roll}, lamps, ambient, moon, lightning, fog, bg, exposure,
//                    flash:{i, pos, target, angle}, creature: true|false, radius, hide:[names] }] }
import { chromium } from 'playwright';
import fs from 'fs';
const [,, worldPath, crPath, specPath, outDir, fromArg, toArg] = process.argv;
const world = JSON.parse(fs.readFileSync(worldPath, 'utf8'));
const cr = JSON.parse(fs.readFileSync(crPath, 'utf8'));
const spec = JSON.parse(fs.readFileSync(specPath, 'utf8'));
fs.mkdirSync(outDir, { recursive: true });
const W = spec.W, H = spec.H;
const browser = await chromium.launch({ executablePath: '/opt/pw-browsers/chromium-1194/chrome-linux/chrome', args: ['--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist'] });
const page = await browser.newPage({ viewport: { width: W, height: H } });
page.on('console', m => { if (m.type() === 'error') console.log('PAGE', m.text()); });
await page.setContent(`<html><body style="margin:0;background:#000"><canvas id="c" width="${W}" height="${H}"></canvas></body></html>`);
await page.addScriptTag({ path: 'node_modules/three/build/three.min.js' });
await page.evaluate(([world, cr, W, H]) => {
  const T = THREE;
  const renderer = new T.WebGLRenderer({ canvas: document.getElementById('c'), antialias: true, preserveDrawingBuffer: true });
  renderer.setSize(W, H, false);
  renderer.outputColorSpace = T.SRGBColorSpace;
  renderer.toneMapping = T.ACESFilmicToneMapping;
  window.R = renderer; window.W = W; window.H = H;
  const unitBox = new T.BoxGeometry(1, 1, 1);
  const unitSphere = new T.SphereGeometry(0.5, 24, 16);
  const unitCyl = new T.CylinderGeometry(0.5, 0.5, 1, 24); unitCyl.rotateZ(-Math.PI / 2);
  const wedge = (() => { const g = new T.BufferGeometry();
    const v = [[-.5,-.5,-.5],[-.5,-.5,.5],[-.5,.5,.5],[.5,-.5,-.5],[.5,-.5,.5],[.5,.5,.5]];
    const f = [[0,2,1],[3,4,5],[0,1,4],[0,4,3],[1,2,5],[1,5,4],[0,3,5],[0,5,2]];
    const pos = []; for (const t of f) for (const i of t) pos.push(...v[i]);
    g.setAttribute('position', new T.Float32BufferAttribute(pos, 3)); g.computeVertexNormals(); return g; })();
  const mats = {};
  function mat(p) {
    const key = p.col.join(',') + p.mat + p.tr;
    if (mats[key]) return mats[key];
    const color = new T.Color(`rgb(${p.col[0]},${p.col[1]},${p.col[2]})`);
    const o = { color, roughness: 0.8, metalness: 0 };
    if (p.mat === 'Neon') { o.emissive = color; o.emissiveIntensity = 1.6; }
    if (p.mat === 'Metal' || p.mat === 'DiamondPlate' || p.mat === 'CorrodedMetal') { o.metalness = 0.5; o.roughness = 0.45; }
    if (p.mat === 'Glass') { o.transparent = true; o.opacity = Math.min(0.5, 1 - p.tr); o.roughness = 0.1; }
    else if (p.tr > 0.02) { o.transparent = true; o.opacity = 1 - p.tr; }
    if (p.mat === 'SmoothPlastic' || p.mat === 'Marble') o.roughness = 0.45;
    if (p.mat === 'Fabric') o.roughness = 0.95;
    return (mats[key] = new T.MeshStandardMaterial(o));
  }
  function geo(p) {
    let g, sx = p.s[0], sy = p.s[1], sz = p.s[2], off = null;
    if (p.m && (p.m.t === 'Sphere' || p.m.t === 'Brick' || p.m.t === 'Wedge' || p.m.t === 'Cylinder')) {
      g = p.m.t === 'Sphere' ? unitSphere : p.m.t === 'Wedge' ? wedge : p.m.t === 'Cylinder' ? unitCyl : unitBox;
      sx *= p.m.s[0]; sy *= p.m.s[1]; sz *= p.m.s[2]; off = p.m.o;
    } else if (p.sh === 'Ball') { g = unitSphere; const d = Math.min(sx, sy, sz); sx = sy = sz = d; }
    else if (p.sh === 'Cylinder') { g = unitCyl; const d = Math.min(sy, sz); sy = sz = d; }
    else if (p.sh === 'Wedge') g = wedge;
    else g = unitBox;
    return { g, sx, sy, sz, off };
  }
  function place(mesh, c, gi) {
    const m = new T.Matrix4().set(c[3], c[4], c[5], c[0], c[6], c[7], c[8], c[1], c[9], c[10], c[11], c[2], 0, 0, 0, 1);
    if (gi.off) m.multiply(new T.Matrix4().makeTranslation(gi.off[0], gi.off[1], gi.off[2]));
    m.multiply(new T.Matrix4().makeScale(gi.sx, gi.sy, gi.sz));
    mesh.matrix.copy(m);
  }
  const scene = new T.Scene(); window.S = scene;
  for (const p of world.parts) {
    const gi = geo(p);
    const mesh = new T.Mesh(gi.g, mat(p));
    mesh.matrixAutoUpdate = false; place(mesh, p.c, gi);
    mesh.userData.pos = new T.Vector3(p.c[0], p.c[1], p.c[2]); mesh.userData.name = p.n;
    scene.add(mesh);
  }
  // the creature
  const crGroup = new T.Group(); scene.add(crGroup);
  window.CR = cr.parts.map(p => {
    const gi = geo(p);
    const mesh = new T.Mesh(gi.g, mat(p));
    mesh.matrixAutoUpdate = false; mesh.visible = p.tr < 0.98; mesh.userData.cr = true;
    crGroup.add(mesh);
    return { mesh, gi };
  });
  window.CRG = crGroup; window.place = place;
  // the faint cold glow in front of his mask (a PointLight in the game)
  window.GLOW_I = cr.parts.findIndex(p => p.n === 'FaceGlow');
  window.GLOW = new T.PointLight(0xc4cee8, 0, 6, 1.2); scene.add(window.GLOW);
  window.LIGHTS = world.lights;
  window.SHOT = null;
}, [world, { parts: cr.parts }, W, H]);

const from = +(fromArg ?? 0), to = +(toArg ?? Math.max(...spec.frames.map(x => x.f)));
let t0 = Date.now();
for (const fr of spec.frames) {
  if (fr.f < from || fr.f > to) continue;
  const crFrame = fr.creature ? cr.frames[String(fr.creatureF ?? fr.f)] : null;
  await page.evaluate(([fr, shotCfg, crFrame]) => {
    const T = THREE, scene = window.S;
    // per-shot light rig (built once per shot so shaders don't recompile every frame)
    if (window.SHOT !== fr.shot) {
      window.SHOT = fr.shot;
      for (const l of (window.RIG || [])) scene.remove(l);
      const rig = window.RIG = [];
      const add = (o) => { scene.add(o); rig.push(o); return o; };
      window.HEMI = add(new T.HemisphereLight(0x8fa4c8, 0x1a1612, 0.1));
      window.MOON = add(new T.DirectionalLight(0x9fb4d8, 0.05)); window.MOON.position.set(-60, 90, -80);
      window.BOLT = add(new T.DirectionalLight(0xc8d8ff, 0)); window.BOLT.position.set(30, 120, -160);
      window.FLASH = add(new T.SpotLight(0xfff2dc, 0, 110, 0.42, 0.55, 1.1)); add(window.FLASH.target);
      const c = shotCfg.center;
      const ls = window.LIGHTS.map(l => ({ l, d: Math.hypot(l.p[0] - c[0], l.p[1] - c[1], l.p[2] - c[2]) }))
        .filter(x => x.d < (shotCfg.lampRadius || 50)).sort((a, b) => a.d - b.d).slice(0, shotCfg.maxLamps ?? 14);
      window.LAMPS = ls.map(({ l }) => { const pl = add(new T.PointLight(new T.Color(l.col[0], l.col[1], l.col[2]), 0, l.r * 1.6, 1.4)); pl.position.set(...l.p); pl.userData.b = l.b; return pl; });
      window.XL = (shotCfg.lights || []).map(e => { const pl = add(new T.PointLight(new T.Color(e.col), 0, e.r, e.decay ?? 1.4)); pl.position.set(...e.p); pl.userData.b = e.b; return pl; });
      const cpos = new T.Vector3(...c), r = shotCfg.radius || 1e9;
      scene.traverse(o => { if (o.isMesh && o.userData.pos) o.visible = o.userData.pos.distanceTo(cpos) < r && !(shotCfg.hide || []).some(h => o.userData.name === h); });
      window.DOOR = [];
      if (shotCfg.door) {
        const dc = new T.Vector3(...shotCfg.door.near);
        scene.traverse(o => { if (o.isMesh && o.userData.pos && (shotCfg.door.names || []).includes(o.userData.name) && o.userData.pos.distanceTo(dc) < shotCfg.door.r) { o.userData.m0 = o.userData.m0 || o.matrix.clone(); window.DOOR.push(o); } });
      }
    }
    const bg = new T.Color(fr.bg ?? 0x050505);
    scene.background = bg;
    scene.fog = fr.fog ? new T.Fog(bg, fr.fog[0], fr.fog[1]) : null;
    window.R.toneMappingExposure = fr.exposure ?? 1.0;
    window.HEMI.intensity = fr.ambient ?? 0.1;
    window.MOON.intensity = fr.moon ?? 0.05;
    window.BOLT.intensity = (fr.lightning || 0) * 6;
    window.HEMI.color.setHex(fr.lightning ? 0xb8c8ff : 0x8fa4c8);
    window.HEMI.intensity += (fr.lightning || 0) * 2.2;
    for (const l of window.LAMPS) l.intensity = (fr.lamps ?? 0) * l.userData.b * 22;
    for (const l of window.XL) l.intensity = (fr.xl ?? 1) * l.userData.b;
    const fl = fr.flash;
    if (fl && fl.i > 0) {
      window.FLASH.intensity = fl.i; window.FLASH.angle = fl.angle || 0.42;
      window.FLASH.position.set(...fl.pos); window.FLASH.target.position.set(...fl.target); window.FLASH.target.updateMatrixWorld();
    } else window.FLASH.intensity = 0;
    if (window.DOOR && window.DOOR.length) {
      const h = shotCfg.door.hinge, a = fr.door || 0;
      const M = new T.Matrix4().makeTranslation(h[0], 0, h[2]).multiply(new T.Matrix4().makeRotationY(a)).multiply(new T.Matrix4().makeTranslation(-h[0], 0, -h[2]));
      for (const o of window.DOOR) o.matrix.copy(M.clone().multiply(o.userData.m0));
    }
    // creature
    window.CRG.visible = !!crFrame;
    if (crFrame) crFrame.forEach((c, i) => window.place(window.CR[i].mesh, c, window.CR[i].gi));
    if (crFrame && window.GLOW_I >= 0) { const g = crFrame[window.GLOW_I]; window.GLOW.position.set(g[0], g[1], g[2]); window.GLOW.intensity = fr.glow ?? 6; }
    else window.GLOW.intensity = 0;
    const cam = new T.PerspectiveCamera(fr.cam.fov || 60, window.W / window.H, 0.05, 3000);
    cam.position.set(...fr.cam.pos); cam.lookAt(new T.Vector3(...fr.cam.look));
    if (fr.cam.roll) cam.rotateZ(fr.cam.roll);
    window.R.render(scene, cam);
  }, [fr, spec.shots[fr.shot], crFrame]);
  const buf = await page.screenshot({ type: 'png' });
  fs.writeFileSync(`${outDir}/${String(fr.f).padStart(4, '0')}.png`, buf);
  if (fr.f % 10 === 0) { console.log('frame', fr.f, ((Date.now() - t0) / 1000).toFixed(1) + 's'); }
}
await browser.close();
