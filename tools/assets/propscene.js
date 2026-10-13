// Browser side of placing Creator Store props in a three.js render, exactly as World/Props fit() does:
// turned by the entry's Yaw about its centre, scaled into the placeholder's box (Fit), against the
// back (Back), standing on its base. Needs THREE. Every mesh gets userData.pos (its prop's position).
//   await window.addProps(scene, stage, models, meshes, textures)
window.addProps = async function (scene, stage, models, meshes, textures) {
  const T = THREE;
  const box = new T.BoxGeometry(1, 1, 1), ball = new T.SphereGeometry(0.5, 20, 14), cyl = new T.CylinderGeometry(0.5, 0.5, 1, 24); cyl.rotateZ(-Math.PI / 2);
  const cfm = (c) => new T.Matrix4().set(c[3], c[4], c[5], c[0], c[6], c[7], c[8], c[1], c[9], c[10], c[11], c[2], 0, 0, 0, 1);
  const loader = new T.TextureLoader(); const texCache = {};
  for (const id in textures) { try { const t = await loader.loadAsync(textures[id]); t.colorSpace = T.SRGBColorSpace; texCache[id] = t; } catch (e) {} }
  const geos = {};
  const meshGeo = (id) => { if (geos[id]) return geos[id]; const m = meshes[id]; if (!m) return null; const g = new T.BufferGeometry();
    g.setAttribute('position', new T.Float32BufferAttribute(m.pos, 3)); g.setAttribute('normal', new T.Float32BufferAttribute(m.nrm, 3)); g.setAttribute('uv', new T.Float32BufferAttribute(m.uv, 2)); g.setIndex(m.idx);
    return (geos[id] = { g, min: m.min, max: m.max }); };
  function authored(model) { // the model as built, in its own world coordinates; and its part box
    const grp = new T.Group(); let mn = [Infinity, Infinity, Infinity], mx = [-Infinity, -Infinity, -Infinity];
    for (const p of model.Parts) {
      if (p.Transparency >= 0.99) continue;
      const pm = cfm(p.CFrame);
      for (const sx of [-1, 1]) for (const sy of [-1, 1]) for (const sz of [-1, 1]) {
        const v = new T.Vector3(sx * p.Size[0] / 2, sy * p.Size[1] / 2, sz * p.Size[2] / 2).applyMatrix4(pm);
        mn = [Math.min(mn[0], v.x), Math.min(mn[1], v.y), Math.min(mn[2], v.z)]; mx = [Math.max(mx[0], v.x), Math.max(mx[1], v.y), Math.max(mx[2], v.z)];
      }
      const col = new T.Color(`rgb(${p.Color[0]},${p.Color[1]},${p.Color[2]})`);
      const texId = p.TextureID || (p.Special && p.Special.TextureId) || (p.Surface && p.Surface.Color);
      const map = texId ? texCache[texId] || null : null;
      const m = new T.MeshStandardMaterial({ color: map ? 0xffffff : col, map, roughness: 0.75, transparent: p.Transparency > 0.02, opacity: 1 - p.Transparency, side: T.DoubleSide });
      let mesh, sx = p.Size[0], sy = p.Size[1], sz = p.Size[2], off = [0, 0, 0];
      const mid = p.MeshId || (p.Special && p.Special.MeshId); const mg = mid ? meshGeo(mid) : null;
      if (mg) {
        mesh = new T.Mesh(mg.g, m);
        const ext = [0, 1, 2].map(k => (mg.max[k] - mg.min[k]) || 1), ctr = [0, 1, 2].map(k => (mg.max[k] + mg.min[k]) / 2);
        if (p.MeshId) { sx /= ext[0]; sy /= ext[1]; sz /= ext[2]; off = [-ctr[0] * sx, -ctr[1] * sy, -ctr[2] * sz]; }
        else { const s = p.Special.Scale || [1, 1, 1]; sx = s[0]; sy = s[1]; sz = s[2]; off = p.Special.Offset || [0, 0, 0]; }
      } else if (/Ball/.test(p.Shape || '')) mesh = new T.Mesh(ball, m); else if (/Cylinder/.test(p.Shape || '')) mesh = new T.Mesh(cyl, m); else mesh = new T.Mesh(box, m);
      const holder = new T.Group(); holder.matrixAutoUpdate = false; holder.matrix.copy(pm);
      mesh.scale.set(sx, sy, sz); mesh.position.set(off[0], off[1], off[2]); holder.add(mesh); grp.add(holder);
    }
    return { grp, mn, mx };
  }
  for (const h of stage.holders) {
    const model = models[String(h.entry.Id)]; if (!model) continue;
    const { grp, mn, mx } = authored(model);
    // 1. turn about its centre by Yaw
    const c0 = new T.Vector3((mn[0] + mx[0]) / 2, (mn[1] + mx[1]) / 2, (mn[2] + mx[2]) / 2);
    const yaw = (h.entry.Yaw || 0) * Math.PI / 180;
    const rot = new T.Matrix4().makeTranslation(c0.x, c0.y, c0.z).multiply(new T.Matrix4().makeRotationY(yaw)).multiply(new T.Matrix4().makeTranslation(-c0.x, -c0.y, -c0.z));
    let bmn = [Infinity, Infinity, Infinity], bmx = [-Infinity, -Infinity, -Infinity];
    for (const sx of [mn[0], mx[0]]) for (const sy of [mn[1], mx[1]]) for (const sz of [mn[2], mx[2]]) {
      const v = new T.Vector3(sx, sy, sz).applyMatrix4(rot);
      bmn = [Math.min(bmn[0], v.x), Math.min(bmn[1], v.y), Math.min(bmn[2], v.z)]; bmx = [Math.max(bmx[0], v.x), Math.max(bmx[1], v.y), Math.max(bmx[2], v.z)];
    }
    const c1 = new T.Vector3((bmn[0] + bmx[0]) / 2, (bmn[1] + bmx[1]) / 2, (bmn[2] + bmx[2]) / 2);
    const bs = [bmx[0] - bmn[0], bmx[1] - bmn[1], bmx[2] - bmn[2]];
    const ps = [h.max[0] - h.min[0], h.max[1] - h.min[1], h.max[2] - h.min[2]];
    const r = [0, 1, 2].map(k => ps[k] / Math.max(bs[k], 0.01));
    let s = h.entry.Fit === 'width' ? Math.min(r[0], r[1] * 1.25) : Math.min(r[0], r[1], r[2]);
    if (h.name === 'Plate' || h.name === 'BrokenPlate') s = Math.max(r[0], r[2]);
    const hgt = bs[1] * s;
    const frame = cfm(h.frame);
    const cz = h.entry.Back ? h.max[2] - bs[2] * s / 2 : (h.min[2] + h.max[2]) / 2;
    const at = new T.Vector3((h.min[0] + h.max[0]) / 2, h.min[1] + hgt / 2, cz).applyMatrix4(frame);
    const frot = new T.Matrix4().extractRotation(frame);
    const M = new T.Matrix4().makeTranslation(at.x, at.y, at.z).multiply(frot).multiply(new T.Matrix4().makeScale(s, s, s)).multiply(new T.Matrix4().makeTranslation(-c1.x, -c1.y, -c1.z)).multiply(rot);
    const outer = new T.Group(); outer.matrixAutoUpdate = false; outer.matrix.copy(M); outer.add(grp);
    outer.traverse(o => { if (o.isMesh) o.userData.pos = at.clone(); });
    scene.add(outer);
  }
};
