// Node side of placing Creator Store props in a render: the models a stage.json's placeholders use,
// downloaded and inspected if missing (fetch.py, inspect.luau), their meshes decoded (mesh.mjs) and
// their textures read. Used by stage.mjs and the reel renderer (marketing/reel_source/tools/film2.mjs).
//   const { models, meshes, textures, tris } = await loadProps(stage, cacheDir)
import fs from 'fs';
import path from 'path';
import { execFileSync } from 'child_process';
import { fileURLToPath } from 'url';
import { decodeMesh } from './mesh.mjs';

const here = path.dirname(fileURLToPath(import.meta.url));
const repo = path.resolve(here, '../..');

export async function loadProps(stage, cache) {
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
  const tris = {};
  for (const [id, m] of Object.entries(models)) {
    if (!m) continue;
    let t = 0; for (const p of m.Parts) { const mid = p.MeshId || (p.Special && p.Special.MeshId); t += mid && meshes[mid] ? meshes[mid].idx.length / 3 : 12; }
    tris[id] = t;
  }
  console.log('models', Object.keys(models).length, 'meshes', Object.keys(meshes).length, 'textures', Object.keys(textures).length);
  for (const [id, t] of Object.entries(tris)) console.log('  ', id, models[id] && models[id].RootName, Math.round(t), 'triangles');

  return { models, meshes, textures, tris };
}
