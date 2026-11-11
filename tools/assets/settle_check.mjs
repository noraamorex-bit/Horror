// node settle_check.mjs <stage.json> <cacheDir>
// Every Creator Store prop as World/Props fit() places it: does its real geometry stand on its placeholder's base
// (the surface the placeholder was built on)? Prints, per prop, how far the geometry's bottom is from that base
// ("gap": + floats, - sinks; FAIL past 0.06). Also replays the old settle() (v85-v144: 5 rays up through the middle of
// the footprint for the prop's lowest point, one ray down that only met CanQuery parts for the surface) as "old",
// which sank the dining chairs 1.3 studs into the floor and floated the teddies.
import { chromium } from 'playwright';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { loadProps } from './propload.mjs';

const here = path.dirname(fileURLToPath(import.meta.url));
const [,, stagePath, cache] = process.argv;
const stage = JSON.parse(fs.readFileSync(stagePath, 'utf8'));
const { models, meshes, textures } = await loadProps(stage, cache);
const browser = await chromium.launch({ executablePath: process.env.PW_CHROME || '/opt/pw-browsers/chromium', args: ['--use-angle=swiftshader', '--enable-unsafe-swiftshader'] });
const page = await browser.newPage();
await page.setContent('<html><body></body></html>');
await page.addScriptTag({ path: path.join(here, 'node_modules/three/build/three.min.js') });
await page.addScriptTag({ path: path.join(here, 'propscene.js') });
const out = await page.evaluate(async ([stage, models, meshes]) => {
  const T = THREE;
  const scene = new T.Scene();
  await window.addProps(scene, stage, models, meshes, {});
  scene.updateMatrixWorld(true);
  const cfm = (c) => new T.Matrix4().set(c[3], c[4], c[5], c[0], c[6], c[7], c[8], c[1], c[9], c[10], c[11], c[2], 0, 0, 0, 1);
  // the queryable world: visible CanQuery parts + invisible colliders, as boxes (with their holder id)
  const box = new T.BoxGeometry(1, 1, 1);
  const qm = new T.MeshBasicMaterial({ side: T.DoubleSide });
  const qs = [];
  for (const p of stage.parts.concat(stage.qparts)) {
    if (!(p.q || p.n !== undefined && stage.qparts.includes(p))) continue;
    const m = new T.Mesh(box, qm);
    m.matrixAutoUpdate = false; m.matrix.copy(cfm(p.c).multiply(new T.Matrix4().makeScale(p.s[0], p.s[1], p.s[2])));
    m.updateMatrixWorld(true); m.userData.hid = p.hid; m.userData.n = p.n;
    qs.push(m);
  }
  const rc = new T.Raycaster();
  const res = [];
  for (const outer of window.PROPS || []) {
    const h = outer.userData.holder, at = outer.userData.at;
    // (v146: the base fit() uses: a base a little under its floor is the floor)
    // the placeholder's world box (settle's `size`)
    const frame = cfm(h.frame);
    let wmn = [Infinity, Infinity, Infinity], wmx = [-Infinity, -Infinity, -Infinity];
    for (const x of [h.min[0], h.max[0]]) for (const y of [h.min[1], h.max[1]]) for (const z of [h.min[2], h.max[2]]) {
      const v = new T.Vector3(x, y, z).applyMatrix4(frame);
      wmn = [Math.min(wmn[0], v.x), Math.min(wmn[1], v.y), Math.min(wmn[2], v.z)]; wmx = [Math.max(wmx[0], v.x), Math.max(wmx[1], v.y), Math.max(wmx[2], v.z)];
    }
    const size = [wmx[0] - wmn[0], wmx[1] - wmn[1], wmx[2] - wmn[2]];
    const meshesOf = []; outer.traverse(o => { if (o.isMesh) meshesOf.push(o); });
    let low = Infinity;
    const rx = size[0] * 0.25, rz = size[2] * 0.25;
    for (const o of [[0, 0], [rx, 0], [-rx, 0], [0, rz], [0, -rz]]) {
      rc.set(new T.Vector3(at.x + o[0], at.y - size[1] - 2, at.z + o[1]), new T.Vector3(0, 1, 0)); rc.far = size[1] * 3 + 4;
      const hit = rc.intersectObjects(meshesOf, false)[0];
      if (hit) low = Math.min(low, hit.point.y);
    }
    // the true bottom of the prop's geometry
    const bb = new T.Box3().setFromObject(outer);
    rc.set(new T.Vector3(at.x, at.y + size[1], at.z), new T.Vector3(0, -1, 0)); rc.far = size[1] * 2 + 3;
    const fl = rc.intersectObjects(qs.filter(q => q.userData.hid !== h.hid), false)[0];
    let dy = null;
    if (low < Infinity && fl) { dy = fl.point.y + 0.01 - low; if (Math.abs(dy) >= 1.5) dy = 0; }
    res.push({ key: h.key, hid: h.hid, at: [at.x, at.y, at.z], dy, gap: bb.min.y - wmn[1], bottom: bb.min.y, base: wmn[1], topGap: h.entry.Stretch ? bb.max.y - wmx[1] : 0 });
  }
  return res;
}, [stage, models, meshes]);
await browser.close();
out.sort((a, b) => Math.abs(b.gap) - Math.abs(a.gap));
let fails = 0;
for (const r of out) {
  const bad = Math.abs(r.gap) > 0.06 || Math.abs(r.topGap) > 0.08;
  if (bad) fails++;
  console.log(`${bad ? 'FAIL' : '  ok'} gap ${r.gap.toFixed(2).padStart(6)}  ${r.key.padEnd(16)} #${r.hid} at (${r.at.map(v => v.toFixed(1)).join(', ')})  bottom ${r.bottom.toFixed(2)} base ${r.base.toFixed(2)}${r.topGap ? '  top gap ' + r.topGap.toFixed(2) : ''}  old settle ${r.dy == null ? '-' : r.dy.toFixed(2)}`);
}
console.log(fails ? `SETTLE FAIL: ${fails} props off their base` : 'SETTLE OK');
