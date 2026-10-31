// node film.mjs world.json creature_frames.json spec.json outdir [from] [to]
// spec: { W, H, shots: { name: { center:[x,y,z], lampRadius, maxLamps, lights:[{p,col,b,r}] } },
//         frames: [{ f, shot, cam:{pos,look,fov,roll}, lamps, ambient, moon, lightning, fog, bg, exposure,
//                    flash:{i, pos, target, angle}, burst:{pos, col, i, r}, creature: true|false, radius, hide:[names | {near:[x,z], r, names?}] }] }
import { chromium } from 'playwright';
import fs from 'fs';
import { loadProps } from '../../../tools/assets/propload.mjs';
import { decodeMesh } from '../../../tools/assets/mesh.mjs';
const [,, worldPath, crPath, specPath, outDir, fromArg, toArg] = process.argv;
const world = JSON.parse(fs.readFileSync(worldPath, 'utf8'));
const cr = JSON.parse(fs.readFileSync(crPath, 'utf8'));
const spec = JSON.parse(fs.readFileSync(specPath, 'utf8'));
fs.mkdirSync(outDir, { recursive: true });
const W = spec.W, H = spec.H;
// Creator Store furniture (spec.props = { cache }): the world file is then a stage.json from
// tools/harness/stage_dump.luau, and its placeholders get their props exactly as the game places them
let props = null;
if (spec.props && world.holders) {
  props = await loadProps(world, spec.props.cache);
  world.swapped = world.holders.filter(h => props.models[String(h.entry.Id)]).map(h => h.key);
}
// (v112) the skinned creature: a creature file from tools/creature/skin_frames.luau ("skin") draws the
// game's real mesh, posed by SkinPose, instead of the old part-built figure. Its mesh and maps are
// fetched into spec.skinCache (default ./cache_skin)
let skinData = null;
if (cr.skin) {
  const { execFileSync } = await import('child_process');
  const cache = spec.skinCache || 'cache_skin';
  fs.mkdirSync(cache, { recursive: true });
  const ids = { mesh: '17737123792', color: '17737123793', normal: '17737124050', rough: '17737123673' };
  for (const id of Object.values(ids)) if (!fs.existsSync(`${cache}/${id}.bin`)) execFileSync('python3', ['../../../tools/assets/fetch.py', cache, id], { stdio: 'pipe' });
  const m = await decodeMesh(new Uint8Array(fs.readFileSync(`${cache}/${ids.mesh}.bin`)));
  const img = (id) => 'data:image/png;base64,' + fs.readFileSync(`${cache}/${id}.bin`).toString('base64');
  skinData = { mesh: { pos: Array.from(m.pos), nrm: Array.from(m.nrm), uv: Array.from(m.uv), idx: Array.from(m.idx), skin: { bones: m.skin.bones, skinIndex: Array.from(m.skin.skinIndex), skinWeight: Array.from(m.skin.skinWeight) } },
    tex: { color: img(ids.color), normal: img(ids.normal), rough: img(ids.rough) }, info: cr.skin };
}
const photos = (spec.photos || []).map(p => 'data:image/png;base64,' + fs.readFileSync(p).toString('base64'));
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
    const f = [[0,1,2],[3,5,4],[0,1,4],[0,4,3],[1,2,5],[1,5,4],[0,3,5],[0,5,2]];
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
  const swapped = new Set(world.swapped || []);
  for (const p of world.parts) {
    if (p.ph && swapped.has(p.ph)) continue;
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
  // the photos on his wall: real pictures of the family's rooms
  window.PHOTOS = [];
}, [world, { parts: cr.parts || [] }, W, H]);
if (skinData) {
  await page.evaluate(async (sd) => {
    const T = THREE;
    const loader = new T.TextureLoader();
    const load = async (u, srgb) => { const t = await loader.loadAsync(u); if (srgb) t.colorSpace = T.SRGBColorSpace; t.flipY = false; return t; };
    const [cmap, nmap, rmap] = await Promise.all([load(sd.tex.color, true), load(sd.tex.normal), load(sd.tex.rough)]);
    const mesh = sd.mesh;
    const uv = new Float32Array(mesh.uv); for (let i = 1; i < uv.length; i += 2) uv[i] = 1 - uv[i];
    const g = new T.BufferGeometry();
    g.setAttribute('position', new T.Float32BufferAttribute(mesh.pos, 3));
    g.setAttribute('normal', new T.Float32BufferAttribute(mesh.nrm, 3));
    g.setAttribute('uv', new T.Float32BufferAttribute(uv, 2));
    g.setAttribute('skinIndex', new T.Uint16BufferAttribute(mesh.skin.skinIndex, 4));
    g.setAttribute('skinWeight', new T.Float32BufferAttribute(mesh.skin.skinWeight, 4));
    g.setIndex(mesh.idx);
    const mat = new T.MeshStandardMaterial({ map: cmap, normalMap: nmap, roughnessMap: rmap, roughness: 1, metalness: 0 });
    // (v114: the body without its colour map, tools/creature/plain_skin.luau: the part's colour + the normal map)
    if (sd.info.color) { mat.map = null; mat.roughnessMap = null; mat.roughness = 0.62; mat.color = new T.Color(`rgb(${sd.info.color[0]},${sd.info.color[1]},${sd.info.color[2]})`); }
    const cf = (a) => new T.Matrix4().set(a[3], a[4], a[5], a[0], a[6], a[7], a[8], a[1], a[9], a[10], a[11], a[2], 0, 0, 0, 1);
    const outer = new T.Group(); window.S.add(outer);
    const inner = new T.Group(); inner.position.set(0, sd.info.half, 0); outer.add(inner);
    const tb = {};
    for (const b of sd.info.bones) { const o = new T.Bone(); o.name = b.name; o.matrixAutoUpdate = false; o.userData.rest = cf(b.rest); o.matrix.copy(o.userData.rest); tb[b.name] = o; }
    for (const b of sd.info.bones) (b.parent ? tb[b.parent] : inner).add(tb[b.name]);
    const ordered = mesh.skin.bones.map(b => tb[b.name] || new T.Bone());
    const inverses = mesh.skin.bones.map(b => { const r = b.rot; return new T.Matrix4().set(r[0], r[1], r[2], b.pos[0], r[3], r[4], r[5], b.pos[1], r[6], r[7], r[8], b.pos[2], 0, 0, 0, 1).invert(); });
    const sk = new T.SkinnedMesh(g, mat);
    sk.frustumCulled = false; sk.castShadow = true;
    inner.add(sk);
    outer.updateMatrixWorld(true);
    sk.bind(new T.Skeleton(ordered, inverses), new T.Matrix4()); // (vertices are in the mesh's own space)
    outer.visible = false;
    window.SKIN = { outer, inner, sk, tb, cf, scale: sd.info.scale };
  }, skinData);
}
if (props) {
  await page.addScriptTag({ path: '../../../tools/assets/propscene.js' });
  await page.evaluate(async ([stage, models, meshes, textures]) => {
    await window.addProps(window.S, stage, models, meshes, textures);
    window.S.updateMatrixWorld(true);
  }, [{ holders: world.holders }, props.models, props.meshes, props.textures]);
}
// staged Roblox avatars (spec.avatars), with a phone in their hands if asked. An avatar with "rbx" is
// dressed in real catalog items (avatar_rbx.js): its files are read here and passed in as data
// (rbx: { skin, shirt, pants, faces: [png], hats: [item json from avatar_items.luau] }, all from rbx.cache)
if (spec.avatars && spec.avatars.length) {
  await page.addScriptTag({ path: 'avatar.js' });
  await page.addScriptTag({ path: 'avatar_rbx.js' });
  const dataUrl = (f) => f && fs.existsSync(f) ? 'data:image/png;base64,' + fs.readFileSync(f).toString('base64') : null;
  for (const a of spec.avatars) {
    if (!a.rbx) continue;
    const C = a.rbx.cache, X = a.rbx;
    const hats = [];
    for (const id of X.hats || []) {
      const it = JSON.parse(fs.readFileSync(`${C}/${id}.json`, 'utf8'));
      const m = await decodeMesh(new Uint8Array(fs.readFileSync(`${C}/${it.mesh}.bin`)));
      hats.push({ mesh: { pos: Array.from(m.pos), nrm: Array.from(m.nrm), uv: Array.from(m.uv), idx: Array.from(m.idx) },
                  texture: it.texture ? dataUrl(`${C}/${it.texture}.bin`) : null, scale: it.scale, offset: it.offset, attachCF: it.attachCF, attachment: it.attachment });
    }
    a.rbx = { skin: X.skin, shirt: dataUrl(X.shirt && `${C}/${X.shirt}.bin`), pants: dataUrl(X.pants && `${C}/${X.pants}.bin`),
              faces: (X.faces || []).map(f => dataUrl(`${C}/${f}.bin`)), hats };
  }
  await page.evaluate(async (avatars) => {
    const T = THREE;
    for (const a of avatars) {
      const g = a.rbx ? await window.buildRobloxAvatar(a) : window.buildAvatar(a);
      g.position.set(...a.pos); g.rotation.order = "YXZ"; g.rotation.set(a.pitch || 0, a.yaw || 0, 0);
      window.S.add(g); g.updateMatrixWorld(true);
      (window.AV = window.AV || []).push(g);
      if (a.flashlight) {
        // a flashlight in the right hand, pointing where the avatar faces (or at a.flashlight.target)
        const r = new T.Vector3(); g.userData.hands.r.getWorldPosition(r);
        const fl = new T.Group(); fl.position.copy(r); window.S.add(fl);
        const tgt = a.flashlight.target ? new T.Vector3(...a.flashlight.target) : r.clone().add(new T.Vector3(-Math.sin(g.rotation.y), 0, -Math.cos(g.rotation.y)).multiplyScalar(10));
        fl.lookAt(tgt);
        const body = new T.Mesh(new T.CylinderGeometry(0.16, 0.13, 1.0, 16), new T.MeshStandardMaterial({ color: 0x1c1c22, roughness: 0.4, metalness: 0.5 }));
        body.rotation.x = Math.PI / 2; body.position.z = 0.3; fl.add(body);
        const lens = new T.Mesh(new T.CircleGeometry(0.15, 20), new T.MeshStandardMaterial({ color: 0xfff6dc, emissive: 0xfff6dc, emissiveIntensity: 3 }));
        lens.position.z = 0.81; fl.add(lens);
        const sp = new T.SpotLight(0xfff2dc, a.flashlight.intensity ?? 16, 60, 0.42, 0.5, 1.1);
        sp.position.set(0, 0, 0.85); fl.add(sp); const st = new T.Object3D(); st.position.set(0, 0, 10); fl.add(st); sp.target = st;
      }
      if (a.phone) {
        const l = new T.Vector3(), r = new T.Vector3(), head = new T.Vector3();
        g.userData.hands.l.getWorldPosition(l); g.userData.hands.r.getWorldPosition(r); g.userData.headNode.getWorldPosition(head);
        head.y += 0.86;
        const at = (a.phone.hand === 'r' ? r.clone() : a.phone.hand === 'l' ? l.clone() : l.clone().add(r).multiplyScalar(0.5)).add(new T.Vector3(...(a.phone.offset || [0, 0, 0])));
        const ph = new T.Group(); ph.position.copy(at); window.S.add(ph); ph.lookAt(head);
        const body = new T.Mesh(new T.BoxGeometry(0.62, 1.12, 0.09), new T.MeshStandardMaterial({ color: 0x141418, roughness: 0.35, metalness: 0.3 }));
        ph.add(body);
        const scr = new T.Mesh(new T.PlaneGeometry(0.55, 1.02), new T.MeshStandardMaterial({ color: 0xd8e8ff, emissive: 0xd8e8ff, emissiveIntensity: 2.4 }));
        scr.position.z = 0.05; ph.add(scr);
        const lens = new T.Mesh(new T.CylinderGeometry(0.07, 0.07, 0.04, 16), new T.MeshStandardMaterial({ color: 0x2a2a30 }));
        lens.rotation.x = Math.PI / 2; lens.position.set(-0.17, 0.4, -0.06); ph.add(lens);
        const glow = new T.PointLight(0xb8d2ff, a.phone.light ?? 3.0, 6, 1.8); glow.position.set(0, 0, 0.5); ph.add(glow);
      }
    }
  }, spec.avatars);
}
// extra props for staged shots (spec.extras: boxes/balls with optional glow)
if (spec.extras && spec.extras.length) {
  await page.evaluate((extras) => {
    const T = THREE;
    for (const e of extras) {
      const geo = e.shape === 'ball' ? new T.SphereGeometry(0.5, 32, 20) : (e.shape === 'cyl' ? new T.CylinderGeometry(0.5, 0.5, 1, 32) : new T.BoxGeometry(1, 1, 1));
      const o = { color: new T.Color(`rgb(${e.col[0]},${e.col[1]},${e.col[2]})`), roughness: e.rough ?? 0.75, metalness: 0 };
      if (e.emissive) { o.emissive = new T.Color(`rgb(${e.emissive[0]},${e.emissive[1]},${e.emissive[2]})`); o.emissiveIntensity = e.ei ?? 1.5; }
      let mat = new T.MeshStandardMaterial(o);
      if (e.face !== undefined) {
        // a Roblox face drawn on one side of the head (0..5 = +x,-x,+y,-y,+z,-z)
        const c = document.createElement('canvas'); c.width = c.height = 256;
        const g = c.getContext('2d');
        g.fillStyle = `rgb(${e.col[0]},${e.col[1]},${e.col[2]})`; g.fillRect(0, 0, 256, 256);
        g.fillStyle = '#111';
        for (const x of [88, 168]) { g.beginPath(); g.ellipse(x, 104, 13, 26, 0, 0, Math.PI * 2); g.fill(); }
        g.lineWidth = 13; g.lineCap = 'round'; g.strokeStyle = '#111';
        g.beginPath(); g.arc(128, 128, 62, 0.22 * Math.PI, 0.78 * Math.PI); g.stroke();
        const tex = new T.CanvasTexture(c); tex.colorSpace = T.SRGBColorSpace;
        const mats = [0, 1, 2, 3, 4, 5].map(i => i === e.face ? new T.MeshStandardMaterial(Object.assign({}, o, { map: tex, color: new T.Color(1, 1, 1) })) : mat);
        mat = mats;
      }
      const m = new T.Mesh(geo, mat);
      m.position.set(...e.pos); m.rotation.set(...(e.rot || [0, 0, 0]), 'YXZ'); m.scale.set(...e.s);
      window.S.add(m);
      (window.EXTRAS = window.EXTRAS || []).push(m);
    }
  }, spec.extras);
}
if (photos.length) {
  await page.evaluate(async (photos) => {
    const T = THREE; const loader = new T.TextureLoader();
    const tex = await Promise.all(photos.map(u => new Promise(r => loader.load(u, t => { t.colorSpace = T.SRGBColorSpace; r(t); }))));
    let i = 0;
    window.S.traverse(o => {
      if (o.isMesh && o.userData.name === 'PhotoImage' && o.userData.pos.x < -27 && i < tex.length) {
        o.material = new T.MeshStandardMaterial({ map: tex[i++], roughness: 0.7 });
      }
    });
  }, photos);
}

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
      window.FRESH = true; // (a new light rig: the first render after it came out dark, so it renders twice)
      for (const l of (window.RIG || [])) scene.remove(l);
      const rig = window.RIG = [];
      const add = (o) => { scene.add(o); rig.push(o); return o; };
      window.HEMI = add(new T.HemisphereLight(0x8fa4c8, 0x1a1612, 0.1));
      window.MOON = add(new T.DirectionalLight(0x9fb4d8, 0.05)); window.MOON.position.set(-60, 90, -80);
      window.BOLT = add(new T.DirectionalLight(0xc8d8ff, 0)); window.BOLT.position.set(30, 120, -160);
      window.FLASH = add(new T.SpotLight(0xfff2dc, 0, 110, 0.42, 0.55, 1.1)); add(window.FLASH.target);
      // (reel 39) a burst of light for a frame or two: an explosion (fr.burst: { pos, col, i, r })
      window.BURST = add(new T.PointLight(0xff9a3c, 0, 40, 1.4));
      const c = shotCfg.center;
      const ls = window.LIGHTS.map(l => ({ l, d: Math.hypot(l.p[0] - c[0], l.p[1] - c[1], l.p[2] - c[2]) }))
        .filter(x => x.d < (shotCfg.lampRadius || 50)).sort((a, b) => a.d - b.d).slice(0, shotCfg.maxLamps ?? 14);
      window.LAMPS = ls.map(({ l }) => { const pl = add(new T.PointLight(new T.Color(l.col[0], l.col[1], l.col[2]), 0, l.r * 1.6, 1.4)); pl.position.set(...l.p); pl.userData.b = l.b; return pl; });
      window.XL = (shotCfg.lights || []).map(e => { const pl = add(new T.PointLight(new T.Color(e.col), 0, e.r, e.decay ?? 1.4)); pl.position.set(...e.p); pl.userData.b = e.b; return pl; });
      const cpos = new T.Vector3(...c), r = shotCfg.radius || 1e9;
      scene.traverse(o => { if (o.isMesh && o.userData.pos) o.visible = o.userData.pos.distanceTo(cpos) < r && !(shotCfg.hide || []).some(h => typeof h === 'string' ? o.userData.name === h : ((!h.names || h.names.includes(o.userData.name)) && Math.hypot(o.userData.pos.x - h.near[0], o.userData.pos.z - h.near[1]) < h.r)); });
      // see-through parts for this shot (a shower curtain he's a shape behind): { names, near, r, opacity }
      scene.traverse(o => {
        if (!o.isMesh || !o.userData.pos) return;
        const tl = shotCfg.translucent;
        const hit = tl && (tl.names || []).includes(o.userData.name) && o.userData.pos.distanceTo(new T.Vector3(...tl.near)) < tl.r;
        if (hit) {
          if (!o.userData.mat0) { o.userData.mat0 = o.material; o.material = o.material.clone(); }
          o.material.transparent = true; o.material.opacity = tl.opacity; o.material.depthWrite = false;
        } else if (o.userData.mat0) { o.material = o.userData.mat0; o.userData.mat0 = null; }
      });
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
    if (fr.burst && fr.burst.i > 0) {
      window.BURST.intensity = fr.burst.i; window.BURST.distance = fr.burst.r || 40;
      window.BURST.color.set(fr.burst.col || '#ff9a3c'); window.BURST.position.set(...fr.burst.pos);
    } else window.BURST.intensity = 0;
    if (window.DOOR && window.DOOR.length) {
      const h = shotCfg.door.hinge, a = fr.door || 0;
      const R = shotCfg.door.axis === 'x' ? new T.Matrix4().makeRotationX(a) : shotCfg.door.axis === 'z' ? new T.Matrix4().makeRotationZ(a) : new T.Matrix4().makeRotationY(a);
      const M = new T.Matrix4().makeTranslation(h[0], h[1] || 0, h[2]).multiply(R).multiply(new T.Matrix4().makeTranslation(-h[0], -(h[1] || 0), -h[2]));
      for (const o of window.DOOR) o.matrix.copy(M.clone().multiply(o.userData.m0));
    }
    // extras taken away on this frame (fr.hideExtras: points; anything of an extra within 1 stud)
    for (const m of (window.EXTRAS || [])) m.visible = !(fr.hideExtras || []).some(p => Math.hypot(m.position.x - p[0], m.position.y - p[1] - 0.22, m.position.z - p[2]) < 1.0);
    // (reel 42) or by their index in spec.extras (fr.hideIdx), for props that sit close together
    if (fr.hideIdx) for (const j of fr.hideIdx) if (window.EXTRAS && window.EXTRAS[j]) window.EXTRAS[j].visible = false;
    // avatars moved and posed per frame (fr.av: [{ i, pos, yaw, pose }]); with fr.av, the ones not listed hide
    if (fr.av && window.AV) {
      for (const g of window.AV) g.visible = false;
      for (const a of fr.av) {
        const g = window.AV[a.i]; if (!g) continue;
        g.visible = true; g.position.set(...a.pos); g.rotation.set(a.pitch || 0, a.yaw || 0, 0);
        if (a.pose) window.poseAvatar(g, a.pose);
        if (a.face !== undefined && g.userData.setFace) g.userData.setFace(a.face);
      }
    } else if (window.AV) for (const g of window.AV) g.visible = true;
    // creature
    const SK = window.SKIN;
    if (SK) {
      // (the skinned creature: where he stands, then every bone's rest times its Transform)
      SK.outer.visible = !!crFrame && !crFrame.noSkin; // (noSkin: only the mask, skin_frames' "head")
      // (v114: the porcelain mask and hair on his head: the part meshes, placed per frame)
      window.CRG.visible = !!(crFrame && crFrame.parts);
      if (crFrame && crFrame.parts) crFrame.parts.forEach((c, i) => window.CR[i] && window.place(window.CR[i].mesh, c, window.CR[i].gi));
      if (crFrame) {
        const r = crFrame.root;
        SK.outer.position.set(r[0], r[1], r[2]); SK.outer.rotation.set(0, r[3], 0); SK.outer.scale.setScalar(SK.scale);
        for (const name in SK.tb) {
          const b = SK.tb[name], t = crFrame.tr[name];
          b.matrix.copy(b.userData.rest); if (t) b.matrix.multiply(SK.cf(t));
        }
        SK.outer.updateMatrixWorld(true);
        window.GLOW.position.set(...crFrame.glow); window.GLOW.intensity = fr.glow ?? 6;
      } else window.GLOW.intensity = 0;
    } else {
      window.CRG.visible = !!crFrame;
      if (crFrame) crFrame.forEach((c, i) => window.place(window.CR[i].mesh, c, window.CR[i].gi));
      if (crFrame && window.GLOW_I >= 0) { const g = crFrame[window.GLOW_I]; window.GLOW.position.set(g[0], g[1], g[2]); window.GLOW.intensity = fr.glow ?? 6; }
      else window.GLOW.intensity = 0;
    }
    const cam = new T.PerspectiveCamera(fr.cam.fov || 60, window.W / window.H, 0.05, 3000);
    cam.position.set(...fr.cam.pos); cam.lookAt(new T.Vector3(...fr.cam.look));
    if (fr.cam.roll) cam.rotateZ(fr.cam.roll);
    window.R.render(scene, cam);
    if (window.FRESH) { window.FRESH = false; window.R.render(scene, cam); }
  }, [fr, spec.shots[fr.shot], crFrame]);
  const buf = await page.screenshot({ type: 'png', timeout: 0 }); // (no limit: a full-size frame can take over 30 s when several renders share the CPU)
  fs.writeFileSync(`${outDir}/${String(fr.f).padStart(4, '0')}.png`, buf);
  if (fr.f % 10 === 0) { console.log('frame', fr.f, ((Date.now() - t0) / 1000).toFixed(1) + 's'); }
}
await browser.close();
