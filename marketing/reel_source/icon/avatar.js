// A standard modern Roblox R15 avatar, built in three.js: rounded body parts, hoodie, jeans,
// sneakers, messy hair, the classic face. window.buildAvatar(opts) -> THREE.Group (posed).
// Local space: the avatar faces -Z, origin at the centre of the LowerTorso (studs).
(function () {
  const T = THREE;
  // a box with rounded edges: spherify the corners of a subdivided box
  function rbox(w, h, d, r, n) {
    n = n || 6;
    const g = new T.BoxGeometry(1, 1, 1, n, n, n);
    const p = g.attributes.position;
    const hw = w / 2, hh = h / 2, hd = d / 2;
    r = Math.min(r, hw, hh, hd);
    const v = new T.Vector3(), inner = new T.Vector3();
    for (let i = 0; i < p.count; i++) {
      v.set(p.getX(i) * w, p.getY(i) * h, p.getZ(i) * d);
      inner.set(Math.max(-hw + r, Math.min(hw - r, v.x)), Math.max(-hh + r, Math.min(hh - r, v.y)), Math.max(-hd + r, Math.min(hd - r, v.z)));
      const dir = v.clone().sub(inner);
      if (dir.lengthSq() > 1e-9) v.copy(inner).add(dir.normalize().multiplyScalar(r));
      p.setXYZ(i, v.x, v.y, v.z);
    }
    g.computeVertexNormals();
    return g;
  }
  function mat(col, extra) {
    return new T.MeshStandardMaterial(Object.assign({ color: new T.Color(col), roughness: 0.62, metalness: 0 }, extra || {}));
  }
  function faceTexture(skin) {
    const c = document.createElement('canvas'); c.width = c.height = 512;
    const g = c.getContext('2d');
    g.fillStyle = skin; g.fillRect(0, 0, 512, 512);
    // eyes: tall ovals with a highlight
    for (const x of [196, 316]) {
      g.fillStyle = '#16120f'; g.beginPath(); g.ellipse(x, 236, 22, 38, 0, 0, Math.PI * 2); g.fill();
      g.fillStyle = 'rgba(255,255,255,.9)'; g.beginPath(); g.ellipse(x - 7, 222, 7, 10, 0, 0, Math.PI * 2); g.fill();
    }
    // brows
    g.strokeStyle = '#2a1d14'; g.lineWidth = 10; g.lineCap = 'round';
    for (const [x, s] of [[196, 1], [316, -1]]) { g.beginPath(); g.moveTo(x - 26, 176 + s * 3); g.lineTo(x + 26, 176 - s * 3); g.stroke(); }
    // a small smile
    g.strokeStyle = '#16120f'; g.lineWidth = 12;
    g.beginPath(); g.arc(256, 292, 46, 0.2 * Math.PI, 0.8 * Math.PI); g.stroke();
    // a little blush
    g.fillStyle = 'rgba(230,120,110,.25)';
    for (const x of [150, 362]) { g.beginPath(); g.ellipse(x, 300, 30, 16, 0, 0, Math.PI * 2); g.fill(); }
    const t = new T.CanvasTexture(c); t.colorSpace = T.SRGBColorSpace; t.anisotropy = 8;
    return t;
  }
  window.buildAvatar = function (o) {
    const C = Object.assign({ skin: '#f2c9a6', hoodie: '#d23b3b', hoodieDark: '#a52a2e', pants: '#2b3b5c', shoe: '#efefef', sole: '#2a2a2e', hair: '#3a2618', string: '#f2f2f2' }, o.colors || {});
    const P = Object.assign({ waist: 0, neckX: 0, neckY: 0, neckZ: 0, lShoulder: [0, 0, 0], rShoulder: [0, 0, 0], lElbow: 0, rElbow: 0, lHip: 0, rHip: 0, lKnee: 0, rKnee: 0 }, o.pose || {});
    const root = new T.Group();
    const add = (parent, geo, m, x, y, z) => { const mesh = new T.Mesh(geo, m); mesh.position.set(x, y, z); parent.add(mesh); return mesh; };
    const joint = (parent, x, y, z) => { const g = new T.Group(); g.position.set(x, y, z); parent.add(g); return g; };
    const mSkin = mat(C.skin), mHood = mat(C.hoodie, { roughness: 0.85 }), mHoodD = mat(C.hoodieDark, { roughness: 0.9 }), mPants = mat(C.pants, { roughness: 0.9 });
    // lower torso (jeans) and upper torso (hoodie)
    add(root, rbox(2.0, 0.42, 1.0, 0.14), mPants, 0, 0, 0);
    const waist = joint(root, 0, 0.21, 0); waist.rotation.x = P.waist;
    add(waist, rbox(2.0, 1.62, 1.0, 0.2), mHood, 0, 0.81, 0);
    add(waist, rbox(1.4, 0.5, 0.12, 0.05), mHoodD, 0, 0.5, -0.52);                           // the front pocket
    const hood = add(waist, rbox(1.5, 0.62, 0.62, 0.28), mHoodD, 0, 1.62, 0.32);              // the hood, down behind the neck
    for (const x of [-0.24, 0.24]) {                                                          // drawstrings
      const s = add(waist, new T.CylinderGeometry(0.035, 0.035, 0.62, 10), mat(C.string), x, 1.25, -0.53);
      add(waist, new T.SphereGeometry(0.06, 12, 8), mat(C.string), x, 0.93, -0.53);
    }
    // head: the rounded Roblox head, face on the -Z side
    const neck = joint(waist, 0, 1.62, 0); neck.rotation.set(P.neckX, P.neckY, P.neckZ);
    add(neck, new T.CylinderGeometry(0.32, 0.32, 0.3, 20), mSkin, 0, 0.1, 0);
    const headGeo = rbox(1.22, 1.22, 1.22, 0.42, 8);
    const faceMat = new T.MeshStandardMaterial({ map: faceTexture(C.skin), roughness: 0.6 });
    add(neck, headGeo, [mSkin, mSkin, mSkin, mSkin, mSkin, faceMat], 0, 0.86, 0);
    // messy hair: a cap with tufts
    const mHair = mat(C.hair, { roughness: 0.95 });
    const hair = joint(neck, 0, 0.86, 0);
    add(hair, rbox(1.36, 0.62, 1.38, 0.3), mHair, 0, 0.42, 0.04);
    add(hair, rbox(1.36, 0.95, 0.42, 0.2), mHair, 0, 0.06, 0.5);
    for (const [x, y, z, rx, rz, s] of [[-0.42, 0.62, -0.42, -0.5, 0.35, 0.42], [0.0, 0.66, -0.5, -0.65, 0, 0.46], [0.42, 0.6, -0.4, -0.5, -0.35, 0.4],
                                         [-0.6, 0.3, -0.25, 0, 0.5, 0.36], [0.6, 0.3, -0.25, 0, -0.5, 0.36], [-0.2, 0.78, 0.2, 0.3, 0.3, 0.4], [0.3, 0.8, 0.1, 0.2, -0.4, 0.38]]) {
      const t = add(hair, rbox(s, s * 1.3, s * 0.9, s * 0.4), mHair, x, y, z); t.rotation.set(rx, 0, rz);
    }
    add(hair, rbox(0.3, 0.55, 0.9, 0.12), mHair, -0.66, 0.1, 0.1);
    add(hair, rbox(0.3, 0.55, 0.9, 0.12), mHair, 0.66, 0.1, 0.1);
    // arms
    const arms = {};
    for (const [side, sx] of [['l', -1], ['r', 1]]) {
      const sh = joint(waist, sx * 1.5, 1.52, 0); sh.rotation.set(...P[side + 'Shoulder']);
      add(sh, rbox(0.96, 1.22, 0.96, 0.24), mHood, 0, -0.55, 0);
      const el = joint(sh, 0, -1.15, 0); el.rotation.x = P[side + 'Elbow'];
      add(el, rbox(0.94, 1.1, 0.94, 0.24), mHood, 0, -0.5, 0);
      add(el, rbox(0.98, 0.22, 0.98, 0.08), mHoodD, 0, -0.98, 0);                              // the cuff
      const hand = add(el, rbox(0.7, 0.36, 0.7, 0.16), mSkin, 0, -1.2, 0);
      arms[side] = hand;
    }
    // legs
    for (const [side, sx] of [['l', -1], ['r', 1]]) {
      const hip = joint(root, sx * 0.5, -0.21, 0); hip.rotation.x = P[side + 'Hip'];
      add(hip, rbox(0.98, 1.2, 0.98, 0.2), mPants, 0, -0.6, 0);
      const kn = joint(hip, 0, -1.2, 0); kn.rotation.x = P[side + 'Knee'];
      add(kn, rbox(0.96, 1.15, 0.96, 0.2), mPants, 0, -0.58, 0);
      add(kn, rbox(1.0, 0.36, 1.25, 0.16), mat(C.shoe), 0, -1.3, -0.12);
      add(kn, rbox(1.02, 0.1, 1.27, 0.04), mat(C.sole), 0, -1.45, -0.12);
    }
    root.userData.hands = arms;
    root.userData.headNode = neck;
    return root;
  };
})();
