import fs from 'fs';
import { decodeMesh } from '/home/user/Horror/tools/assets/mesh.mjs';
const m = await decodeMesh(new Uint8Array(fs.readFileSync(process.argv[2])));
const p = m.pos; const n = p.length / 3;
let mn = [1e9,1e9,1e9], mx = [-1e9,-1e9,-1e9];
for (let i = 0; i < n; i++) for (let k = 0; k < 3; k++) { mn[k] = Math.min(mn[k], p[i*3+k]); mx[k] = Math.max(mx[k], p[i*3+k]); }
console.log('verts', n, 'tris', m.idx.length / 3, 'min', mn.map(v=>v.toFixed(3)), 'max', mx.map(v=>v.toFixed(3)));
// extreme points per axis
for (let k = 0; k < 3; k++) for (const s of [-1, 1]) {
  let best = -1, bv = -1e9;
  for (let i = 0; i < n; i++) { const v = s * p[i*3+k]; if (v > bv) { bv = v; best = i; } }
  console.log('axis', k, s > 0 ? '+' : '-', [p[best*3], p[best*3+1], p[best*3+2]].map(v=>v.toFixed(3)));
}
fs.writeFileSync(process.argv[3], JSON.stringify({ pos: Array.from(p), idx: Array.from(m.idx), nrm: Array.from(m.nrm) }));
