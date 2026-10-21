// A real Roblox avatar in three.js, dressed in real catalog items (reel 38 on; the owner: "use actual
// Roblox characters instead of your blocky thing"): the R15 block body with the classic shirt and
// pants templates mapped onto it exactly as Roblox lays them out (585x559: torso, then each limb's
// four sides, top and bottom), the classic head with a real face decal, and real accessory meshes
// (hair, hats) placed by their attachments. Same joints as avatar.js, so window.poseAvatar poses it.
//   window.buildRobloxAvatar({ rbx: { skin, shirt, pants, faces: [dataUrl...], hats: [{ mesh, texture,
//     scale, offset, attachCF, attachment }] }, scale }) -> THREE.Group (faces -Z, origin = LowerTorso centre)
// The data (images as data URLs, meshes decoded) comes from film2.mjs (spec.avatars[i].rbx).
(function () {
  const T = THREE;
  const TW = 585, TH = 559;   // the clothing template
  // template rects [x, y, w, h]
  const TORSO = { F: [231, 74, 128, 128], B: [427, 74, 128, 128], R: [165, 74, 64, 128], L: [361, 74, 64, 128], U: [231, 8, 128, 64], D: [231, 204, 128, 64] };
  // (the right limb: right arm on a shirt, right leg on pants; L/R here are the limb's own sides)
  const RLIMB = { L: [19, 355, 64, 128], B: [85, 355, 64, 128], R: [151, 355, 64, 128], F: [217, 355, 64, 128], U: [217, 289, 64, 64], D: [217, 485, 64, 64] };
  const LLIMB = { F: [308, 355, 64, 128], L: [374, 355, 64, 128], B: [440, 355, 64, 128], R: [506, 355, 64, 128], U: [308, 289, 64, 64], D: [308, 485, 64, 64] };

  function loadImage(url) {
    return new Promise((res) => {
      if (!url) return res(null);
      const im = new Image(); im.onload = () => res(im); im.onerror = () => res(null); im.src = url;
    });
  }
  // skin, then pants, then the shirt over them (Roblox's order), at 2x the template's size
  function composite(skin, layers) {
    const c = document.createElement('canvas'); c.width = TW * 2; c.height = TH * 2;
    const g = c.getContext('2d');
    g.fillStyle = skin; g.fillRect(0, 0, c.width, c.height);
    for (const im of layers) if (im) g.drawImage(im, 0, 0, c.width, c.height);
    const t = new T.CanvasTexture(c); t.colorSpace = T.SRGBColorSpace; t.anisotropy = 8;
    t.magFilter = T.LinearFilter; t.minFilter = T.LinearMipmapLinearFilter;
    return t;
  }
  // a box whose six faces show the given template rects (yFrom..yTo: the slice of the side rects,
  // 0 = top, 1 = bottom, for the R15 pieces of one classic limb); the faces in BoxGeometry order:
  // +X, -X, +Y, -Y, +Z (back), -Z (front)
  function texBox(w, h, d, rects, yFrom, yTo, capTop, capBottom) {
    const g = new T.BoxGeometry(w, h, d);
    const uv = g.attributes.uv;
    const sides = [rects.px, rects.nx, null, null, rects.B, rects.F];
    for (let face = 0; face < 6; face++) {
      for (let k = 0; k < 4; k++) {
        const i = face * 4 + k;
        let u = uv.getX(i), v = uv.getY(i);
        let r, uu, vv;
        if (face === 2 || face === 3) {
          // top / bottom: their own rects (turned to meet the front edge), or a thin slice of the
          // sides where an R15 piece meets the next
          r = face === 2 ? capTop : capBottom;
          uu = 1 - u; vv = 1 - v;
        } else {
          r = sides[face];
          uu = u;
          vv = yFrom + (1 - v) * (yTo - yFrom);   // (0 at the top of the slice)
          vv = 1 - vv;
        }
        const px = r[0] + uu * r[2], py = r[1] + (1 - vv) * r[3];
        uv.setXY(i, px / TW, 1 - py / TH);
      }
    }
    uv.needsUpdate = true;
    return g;
  }
  // the classic head: a cylinder with rounded top and bottom (1.2 studs every way)
  function headProfile() {
    const pts = [];
    const R = 0.6, H = 0.6, rc = 0.3;
    pts.push(new T.Vector2(0.0001, -H));
    for (let i = 0; i <= 8; i++) { const a = -Math.PI / 2 + (i / 8) * Math.PI / 2; pts.push(new T.Vector2(R - rc + rc * Math.cos(a), -H + rc + rc * Math.sin(a))); }
    for (let i = 0; i <= 8; i++) { const a = (i / 8) * Math.PI / 2; pts.push(new T.Vector2(R - rc + rc * Math.cos(a), H - rc + rc * Math.sin(a))); }
    pts.push(new T.Vector2(0.0001, H));
    return pts;
  }
  function plastic(opts) {
    return new T.MeshStandardMaterial(Object.assign({ roughness: 0.55, metalness: 0.0 }, opts));
  }

  window.buildRobloxAvatar = async function (o) {
    const X = o.rbx;
    const s = o.scale || 1.3;
    const [shirt, pants, ...faces] = await Promise.all([loadImage(X.shirt), loadImage(X.pants), ...(X.faces || []).map(loadImage)]);
    const skin = X.skin || '#f2c9a6';
    const torsoTex = composite(skin, [pants, shirt]);
    const armTex = composite(skin, [shirt]);
    const legTex = composite(skin, [pants]);
    const mTorso = plastic({ map: torsoTex }), mArm = plastic({ map: armTex }), mLeg = plastic({ map: legTex }), mSkin = plastic({ color: skin });

    const root = new T.Group();
    const body = new T.Group(); body.scale.setScalar(s); root.add(body);
    const add = (parent, geo, m, x, y, z) => { const mesh = new T.Mesh(geo, m); mesh.position.set(x, y, z); parent.add(mesh); return mesh; };
    const joint = (parent, x, y, z) => { const g = new T.Group(); g.position.set(x, y, z); parent.add(g); return g; };
    const J = {};
    // torso: the template's torso rects, LowerTorso the bottom fifth of them, UpperTorso the rest
    const tR = { px: TORSO.R, nx: TORSO.L, F: TORSO.F, B: TORSO.B };
    add(body, texBox(2, 0.4, 1, tR, 0.8, 1.0, [231, 196, 128, 4], TORSO.D), mTorso, 0, 0, 0);
    const waist = joint(body, 0, 0.2, 0); J.waist = waist;
    add(waist, texBox(2, 1.6, 1, tR, 0.0, 0.8, TORSO.U, [231, 196, 128, 4]), mTorso, 0, 0.8, 0);
    // head: the classic head, a real face decal on its front half
    const neck = joint(waist, 0, 1.6, 0); J.neck = neck;
    const headC = joint(neck, 0, 0.6, 0);
    const prof = headProfile();
    add(headC, new T.LatheGeometry(prof, 40), mSkin, 0, 0, 0);
    const faceGeo = new T.LatheGeometry(prof, 32, Math.PI / 2, Math.PI);
    {
      // the decal: projected straight on from the front (u across the head, viewer's left = the
      // character's right; v up), over the front half only
      const p = faceGeo.attributes.position, uv = faceGeo.attributes.uv;
      for (let i = 0; i < p.count; i++) uv.setXY(i, 0.5 - p.getX(i) / 1.2, 0.5 + p.getY(i) / 1.2);
      uv.needsUpdate = true;
    }
    const faceTex = faces.map((im) => { if (!im) return null; const t = new T.Texture(im); t.colorSpace = T.SRGBColorSpace; t.anisotropy = 8; t.needsUpdate = true; return t; });
    const mFace = plastic({ map: faceTex[0] || null, transparent: true, polygonOffset: true, polygonOffsetFactor: -2, depthWrite: false });
    const faceMesh = add(headC, faceGeo, mFace, 0, 0, 0); faceMesh.scale.setScalar(1.004);
    faceMesh.visible = !!faceTex[0];
    // accessories (hair, hats): handle = head * head attachment * handle attachment^-1
    const HEAD_ATT = { HairAttachment: [0, 0.6, 0], HatAttachment: [0, 0.6, 0], FaceFrontAttachment: [0, 0, -0.6], FaceCenterAttachment: [0, 0, 0] };
    for (const h of X.hats || []) {
      const m = h.mesh;
      const geo = new T.BufferGeometry();
      geo.setAttribute('position', new T.Float32BufferAttribute(m.pos, 3));
      if (m.nrm) geo.setAttribute('normal', new T.Float32BufferAttribute(m.nrm, 3));
      if (m.uv) geo.setAttribute('uv', new T.Float32BufferAttribute(m.uv, 2));
      geo.setIndex(Array.from(m.idx));
      if (!m.nrm) geo.computeVertexNormals();
      const tim = await loadImage(h.texture);
      let tex = null;
      if (tim) { tex = new T.Texture(tim); tex.colorSpace = T.SRGBColorSpace; tex.anisotropy = 8; tex.needsUpdate = true; }
      const mh = plastic({ map: tex, color: tex ? 0xffffff : (h.color || '#3a2618'), roughness: 0.7, side: T.DoubleSide });
      const mesh = new T.Mesh(geo, mh);
      const sc = h.scale || [1, 1, 1];
      mesh.scale.set(sc[0], sc[1], sc[2]);
      const off = h.offset || [0, 0, 0];
      const handle = new T.Group();
      const ha = HEAD_ATT[h.attachment] || [0, 0.6, 0];
      const c = h.attachCF || [0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1];
      // handle attachment CFrame (position + rotation) inverted
      const A = new T.Matrix4().set(c[3], c[4], c[5], c[0], c[6], c[7], c[8], c[1], c[9], c[10], c[11], c[2], 0, 0, 0, 1);
      const M = new T.Matrix4().makeTranslation(ha[0], ha[1], ha[2]).multiply(A.clone().invert());
      handle.matrixAutoUpdate = false; handle.matrix.copy(M);
      mesh.position.set(off[0], off[1], off[2]);
      handle.add(mesh); headC.add(handle);
    }
    // arms: the shirt's limb rects, upper arm the top half, lower arm the next 3/8, the hand the rest
    const arms = {};
    for (const [side, sx] of [['l', -1], ['r', 1]]) {
      const L = side === 'r' ? RLIMB : LLIMB;
      // (the right limb's outer side is its R rect, on +X; the left limb's outer side is L, on -X)
      const lr = { px: L.R, nx: L.L, F: L.F, B: L.B };
      const cut = (y) => [L.F[0], L.F[1] + y * 128, 64, 2];
      const sh = joint(waist, sx * 1.5, 1.1, 0); J[side + 'Shoulder'] = sh;
      add(sh, texBox(1, 1.0, 1, lr, 0.0, 0.5, L.U, cut(0.5)), mArm, 0, 0.0, 0);
      const el = joint(sh, 0, -0.5, 0); J[side + 'Elbow'] = el;
      add(el, texBox(1, 0.75, 1, lr, 0.5, 0.875, cut(0.5), cut(0.875)), mArm, 0, -0.375, 0);
      const hand = add(el, texBox(1, 0.25, 1, lr, 0.875, 1.0, cut(0.875), L.D), mArm, 0, -0.875, 0);
      arms[side] = hand;
    }
    // legs: the pants' limb rects the same way
    for (const [side, sx] of [['l', -1], ['r', 1]]) {
      const L = side === 'r' ? RLIMB : LLIMB;
      const lr = { px: L.R, nx: L.L, F: L.F, B: L.B };
      const cut = (y) => [L.F[0], L.F[1] + y * 128, 64, 2];
      const hip = joint(body, sx * 0.5, -0.2, 0); J[side + 'Hip'] = hip;
      add(hip, texBox(1, 1.0, 1, lr, 0.0, 0.5, L.U, cut(0.5)), mLeg, 0, -0.5, 0);
      const kn = joint(hip, 0, -1.0, 0); J[side + 'Knee'] = kn;
      add(kn, texBox(1, 0.75, 1, lr, 0.5, 0.875, cut(0.5), cut(0.875)), mLeg, 0, -0.375, 0);
      add(kn, texBox(1, 0.25, 1, lr, 0.875, 1.0, cut(0.875), L.D), mLeg, 0, -0.875, 0);
    }
    for (const m of [mTorso, mArm, mLeg, mSkin]) m.needsUpdate = true;
    root.userData.hands = arms;
    root.userData.joints = J;
    root.userData.headNode = neck;
    root.userData.setFace = (k) => {
      const t = faceTex[k] || faceTex[0];
      if (t && mFace.map !== t) { mFace.map = t; mFace.needsUpdate = true; }
    };
    if (o.pose && window.poseAvatar) window.poseAvatar(root, o.pose);
    return root;
  };
})();
