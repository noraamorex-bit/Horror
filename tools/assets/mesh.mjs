// Roblox mesh files → { pos, nrm, uv, idx, min, max } (the highest level of detail only).
// Handles every version Roblox serves: 1.00/1.01 (text), 2.00, 3.00/3.01, 4.00/4.01, 5.00 and the
// chunked 6.00/7.00 (COREMESH v1 raw, v2 Draco-compressed; LODS picks the first level).
//   import { decodeMesh } from './mesh.mjs'; const m = await decodeMesh(buffer)
import draco3d from 'draco3d';

let dracoPromise = null;
function draco() {
  if (!dracoPromise) dracoPromise = draco3d.createDecoderModule({});
  return dracoPromise;
}

function bounds(pos) {
  const min = [Infinity, Infinity, Infinity], max = [-Infinity, -Infinity, -Infinity];
  for (let i = 0; i < pos.length; i += 3) {
    for (let k = 0; k < 3; k++) { min[k] = Math.min(min[k], pos[i + k]); max[k] = Math.max(max[k], pos[i + k]); }
  }
  return { min, max };
}

function finish(pos, nrm, uv, idx) {
  const b = bounds(pos);
  return { pos, nrm, uv, idx, min: b.min, max: b.max };
}

function readVerts(dv, off, n, stride) {
  const pos = new Float32Array(n * 3), nrm = new Float32Array(n * 3), uv = new Float32Array(n * 2);
  for (let i = 0; i < n; i++) {
    const o = off + i * stride;
    pos[i * 3] = dv.getFloat32(o, true); pos[i * 3 + 1] = dv.getFloat32(o + 4, true); pos[i * 3 + 2] = dv.getFloat32(o + 8, true);
    nrm[i * 3] = dv.getFloat32(o + 12, true); nrm[i * 3 + 1] = dv.getFloat32(o + 16, true); nrm[i * 3 + 2] = dv.getFloat32(o + 20, true);
    uv[i * 2] = dv.getFloat32(o + 24, true); uv[i * 2 + 1] = 1 - dv.getFloat32(o + 28, true);
  }
  return { pos, nrm, uv };
}

function readFaces(dv, off, n, stride = 12) {
  const idx = new Uint32Array(n * 3);
  for (let i = 0; i < n; i++) {
    const o = off + i * stride;
    idx[i * 3] = dv.getUint32(o, true); idx[i * 3 + 1] = dv.getUint32(o + 4, true); idx[i * 3 + 2] = dv.getUint32(o + 8, true);
  }
  return idx;
}

// faces of the first LOD only
function lod0(idx, lods) {
  if (!lods || lods.length < 2) return idx;
  const a = lods[0], b = lods[1];
  if (b <= a || b * 3 > idx.length) return idx;
  return idx.slice(a * 3, b * 3);
}

function v1(text) {
  const lines = text.split(/\r?\n/);
  const old = lines[0].trim() === 'version 1.00';
  const nums = [...lines.slice(2).join('').matchAll(/\[([^\]]*)\]/g)].map(m => m[1].split(',').map(Number));
  const nv = Math.floor(nums.length / 3);
  const pos = new Float32Array(nv * 3), nrm = new Float32Array(nv * 3), uv = new Float32Array(nv * 2), idx = new Uint32Array(nv);
  for (let i = 0; i < nv; i++) {
    const [p, n, t] = [nums[i * 3], nums[i * 3 + 1], nums[i * 3 + 2]];
    const s = old ? 0.5 : 1;
    pos.set([p[0] * s, p[1] * s, p[2] * s], i * 3); nrm.set(n, i * 3); uv.set([t[0], 1 - t[1]], i * 2); idx[i] = i;
  }
  return finish(pos, nrm, uv, idx);
}

async function chunked(buf, start) {
  const dv = new DataView(buf.buffer, buf.byteOffset, buf.byteLength);
  let o = start, mesh = null, lods = null;
  while (o + 16 <= buf.length) {
    const type = new TextDecoder().decode(buf.subarray(o, o + 8)).replace(/\0+$/, '');
    const ver = dv.getUint32(o + 8, true), size = dv.getUint32(o + 12, true);
    const d = o + 16;
    if (type === 'COREMESH') {
      if (ver === 1) {
        const nv = dv.getUint32(d, true);
        const v = readVerts(dv, d + 4, nv, 40);
        const nf = dv.getUint32(d + 4 + nv * 40, true);
        const idx = readFaces(dv, d + 8 + nv * 40, nf);
        mesh = { ...v, idx };
      } else {
        const M = await draco();
        const decoder = new M.Decoder();
        const dbuf = new M.DecoderBuffer();
        dbuf.Init(new Int8Array(buf.buffer, buf.byteOffset + d, size), size);
        const dm = new M.Mesh();
        const st = decoder.DecodeBufferToMesh(dbuf, dm);
        if (!st.ok()) throw new Error('draco: ' + st.error_msg());
        const nv = dm.num_points(), nf = dm.num_faces();
        const get = (attrType, comps) => {
          const id = decoder.GetAttributeId(dm, attrType);
          if (id < 0) return null;
          const attr = decoder.GetAttribute(dm, id);
          const arr = new M.DracoFloat32Array();
          decoder.GetAttributeFloatForAllPoints(dm, attr, arr);
          const out = new Float32Array(nv * comps);
          for (let i = 0; i < nv * comps; i++) out[i] = arr.GetValue(i);
          M.destroy(arr);
          return out;
        };
        const pos = get(M.POSITION, 3), nrm = get(M.NORMAL, 3) || new Float32Array(nv * 3), uvRaw = get(M.TEX_COORD, 2);
        const uv = new Float32Array(nv * 2);
        if (uvRaw) for (let i = 0; i < nv; i++) { uv[i * 2] = uvRaw[i * 2]; uv[i * 2 + 1] = 1 - uvRaw[i * 2 + 1]; }
        const idx = new Uint32Array(nf * 3);
        const fa = new M.DracoInt32Array();
        for (let i = 0; i < nf; i++) {
          decoder.GetFaceFromMesh(dm, i, fa);
          idx[i * 3] = fa.GetValue(0); idx[i * 3 + 1] = fa.GetValue(1); idx[i * 3 + 2] = fa.GetValue(2);
        }
        M.destroy(fa); M.destroy(dm); M.destroy(dbuf); M.destroy(decoder);
        mesh = { pos, nrm, uv, idx };
      }
    } else if (type === 'LODS') {
      const n = dv.getUint32(d + 3, true);
      lods = [];
      for (let i = 0; i < n; i++) lods.push(dv.getUint32(d + 7 + i * 4, true));
    }
    o = d + size;
  }
  if (!mesh) throw new Error('no COREMESH chunk');
  return finish(mesh.pos, mesh.nrm, mesh.uv, lod0(mesh.idx, lods));
}

export async function decodeMesh(buf) {
  const nl = buf.indexOf(10);
  const head = new TextDecoder().decode(buf.subarray(0, nl)).trim();
  const ver = head.replace('version ', '');
  if (ver.startsWith('1.')) return v1(new TextDecoder().decode(buf));
  if (ver.startsWith('6.') || ver.startsWith('7.')) return chunked(buf, nl + 1);
  const dv = new DataView(buf.buffer, buf.byteOffset, buf.byteLength);
  let o = nl + 1;
  if (ver.startsWith('2.')) {
    const hs = dv.getUint16(o, true), vs = dv.getUint8(o + 2), fs = dv.getUint8(o + 3);
    const nv = dv.getUint32(o + 4, true), nf = dv.getUint32(o + 8, true);
    o += hs;
    const v = readVerts(dv, o, nv, vs);
    return finish(v.pos, v.nrm, v.uv, readFaces(dv, o + nv * vs, nf, fs));
  }
  if (ver.startsWith('3.')) {
    const hs = dv.getUint16(o, true), vs = dv.getUint8(o + 2), fs = dv.getUint8(o + 3);
    const ls = dv.getUint16(o + 4, true), nl2 = dv.getUint16(o + 6, true);
    const nv = dv.getUint32(o + 8, true), nf = dv.getUint32(o + 12, true);
    o += hs;
    const v = readVerts(dv, o, nv, vs);
    const idx = readFaces(dv, o + nv * vs, nf, fs);
    const lo = o + nv * vs + nf * fs;
    const lods = []; for (let i = 0; i < nl2; i++) lods.push(dv.getUint32(lo + i * ls, true));
    return finish(v.pos, v.nrm, v.uv, lod0(idx, lods));
  }
  if (ver.startsWith('4.') || ver.startsWith('5.')) {
    const hs = dv.getUint16(o, true);
    const nv = dv.getUint32(o + 4, true), nf = dv.getUint32(o + 8, true);
    const nLods = dv.getUint16(o + 12, true), nBones = dv.getUint16(o + 14, true);
    o += hs;
    const v = readVerts(dv, o, nv, 40);
    o += nv * 40;
    if (nBones > 0) o += nv * 8;
    const idx = readFaces(dv, o, nf);
    o += nf * 12;
    const lods = []; for (let i = 0; i < nLods; i++) lods.push(dv.getUint32(o + i * 4, true));
    return finish(v.pos, v.nrm, v.uv, lod0(idx, lods));
  }
  throw new Error('unknown mesh ' + head);
}
