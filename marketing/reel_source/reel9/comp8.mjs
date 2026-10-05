// node comp8.mjs timeline.json outDir [from] [to] — reel 9: the whole reel is a phone at 3:12 AM.
// Lock screen -> group chat (typing, a baby-monitor clip, a photo, a zoom) -> incoming video call -> the call -> him -> "maya left the chat" -> end card.
import { chromium } from 'playwright';
import fs from 'fs';
const [,, tlPath, outDir, fromArg, toArg] = process.argv;
const tl = JSON.parse(fs.readFileSync(tlPath, 'utf8'));
fs.mkdirSync(outDir, { recursive: true });
const NF = Math.round(tl.phases.dur * tl.fps);
const FD = '/mnt/skills/examples/canvas-design/canvas-fonts/';
const font = (f) => 'data:font/ttf;base64,' + fs.readFileSync(FD + f).toString('base64');
const img = (p) => 'data:image/png;base64,' + fs.readFileSync(p).toString('base64');
const DIR = new URL('../reel9/', import.meta.url).pathname;
const IM = { maya: img(DIR + 'pfp_maya.png'), jake: img(DIR + 'pfp_jake.png'), leo: img(DIR + 'pfp_leo.png'),
             photo: img(tl.photo), wall: img(tl.wall), cctvLast: img(tl.cctv[tl.cctv.length - 1]) };

const html = `<!doctype html><html><head><style>
@font-face { font-family: IS; src: url(${font('InstrumentSans-Regular.ttf')}); }
@font-face { font-family: ISB; src: url(${font('InstrumentSans-Bold.ttf')}); }
@font-face { font-family: OR; src: url(${font('Outfit-Regular.ttf')}); }
@font-face { font-family: OB; src: url(${font('Outfit-Bold.ttf')}); }
* { box-sizing: border-box; }
html,body { margin:0; width:1080px; height:1920px; overflow:hidden; background:#000; font-family: IS, 'Noto Color Emoji'; color:#fff; }
.scr { position:absolute; inset:0; overflow:hidden; display:none; }
/* ---------- status bar (shared) */
.sb { position:absolute; left:0; right:0; top:0; height:110px; display:flex; align-items:center; justify-content:space-between; padding:30px 70px 0; font-family:ISB; font-size:40px; z-index:5; }
.sb .r { display:flex; gap:18px; align-items:center; }
.bars { display:flex; gap:5px; align-items:flex-end; } .bars i { display:block; width:9px; background:#fff; border-radius:2px; }
.bat { width:70px; height:34px; border:3px solid rgba(255,255,255,.6); border-radius:9px; position:relative; padding:3px; }
.bat b { display:block; width:14%; height:100%; background:#ff3b30; border-radius:4px; }
.bat span { position:absolute; right:-80px; top:-6px; font-size:34px; color:#ff3b30; }
/* ---------- lock screen */
#lock { background:#000; }
#lwall { position:absolute; inset:-40px; width:1160px; height:2000px; object-fit:cover; filter: blur(14px) brightness(.42) saturate(.8); }
#ltime { position:absolute; left:0; right:0; top:250px; text-align:center; font-family:OR; font-size:250px; letter-spacing:-6px; }
#ldate { position:absolute; left:0; right:0; top:225px; text-align:center; font-family:ISB; font-size:46px; opacity:.85; }
.note { position:absolute; left:40px; right:40px; border-radius:48px; background:rgba(38,38,44,.78); padding:34px 40px; display:flex; gap:30px; align-items:center;
        box-shadow: 0 12px 40px rgba(0,0,0,.35); backdrop-filter: blur(20px); }
.note .ic { width:104px; height:104px; border-radius:26px; background:linear-gradient(160deg,#ff9a3c,#ff6a00); flex:none; position:relative; }
.note .ic::after { content:''; position:absolute; left:22px; top:26px; width:60px; height:46px; background:#fff; border-radius:22px; }
.note .ic::before { content:''; position:absolute; left:30px; top:62px; width:0; height:0; border-left:10px solid transparent; border-right:14px solid transparent; border-top:20px solid #fff; transform:rotate(25deg); }
.note .tx { flex:1; min-width:0; }
.note .h { display:flex; justify-content:space-between; font-family:ISB; font-size:48px; }
.note .h span { font-family:IS; opacity:.6; font-size:34px; }
.note .b { font-size:52px; margin-top:6px; white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
#swipe { position:absolute; left:50%; bottom:40px; width:300px; height:12px; margin-left:-150px; border-radius:6px; background:rgba(255,255,255,.8); }
/* ---------- chat */
#chat { background:#0c0c10; }
#hdr { position:absolute; left:0; right:0; top:110px; height:200px; display:flex; align-items:center; gap:26px; padding:0 40px; background:rgba(20,20,26,.96);
       border-bottom:2px solid rgba(255,255,255,.07); z-index:4; }
#hdr .back { font-family:IS; font-size:110px; color:#ff8a2a; line-height:1; margin-top:-14px; }
.gav { position:relative; width:150px; height:120px; flex:none; }
.gav img { position:absolute; width:84px; height:84px; border-radius:50%; border:4px solid #14141a; object-fit:cover; }
#hdr .nm { font-family:ISB; font-size:56px; } #hdr .sub { font-size:38px; opacity:.55; margin-top:4px; }
#hdr .vc { margin-left:auto; width:90px; height:62px; border:5px solid #ff8a2a; border-radius:16px; position:relative; }
#hdr .vc::after { content:''; position:absolute; right:-30px; top:10px; border-top:16px solid transparent; border-bottom:16px solid transparent; border-right:24px solid #ff8a2a; }
#list { position:absolute; left:0; right:0; top:310px; bottom:190px; display:flex; flex-direction:column; justify-content:flex-end; overflow:hidden; padding:0 26px 24px; }
.w { overflow:visible; flex:none; }
.row { display:flex; align-items:flex-end; gap:22px; margin-top:14px; }
.row.me { justify-content:flex-end; }
.pf { width:104px; height:104px; border-radius:50%; object-fit:cover; flex:none; }
.pf.no { visibility:hidden; }
.col { display:flex; flex-direction:column; max-width:860px; }
.who { font-family:ISB; font-size:40px; margin:20px 0 8px 28px; }
.bub { font-size:62px; line-height:1.22; padding:28px 42px; border-radius:58px; background:#25252c; }
.me .bub { background:linear-gradient(170deg,#ff9a3c,#ff6a00); color:#fff; }
.sys { text-align:center; font-size:42px; color:rgba(255,255,255,.5); margin:26px 0 10px; font-family:ISB; }
.vid { width:820px; height:462px; border-radius:36px; overflow:hidden; position:relative; background:#000; }
.vid img { width:100%; height:100%; object-fit:cover; filter: grayscale(1) sepia(1) hue-rotate(58deg) saturate(2.6) brightness(1.5) contrast(1.35); }
.vid .ov { position:absolute; inset:0; background: repeating-linear-gradient(0deg, rgba(0,0,0,.22) 0 2px, rgba(0,0,0,0) 2px 5px); }
.vid .rec { position:absolute; left:30px; top:24px; font-family:ISB; font-size:36px; color:#fff; text-shadow:0 2px 4px #000; }
.vid .rec i { display:inline-block; width:20px; height:20px; border-radius:50%; background:#ff3030; margin-right:10px; }
.vid .ts { position:absolute; right:30px; bottom:22px; font-family:ISB; font-size:34px; color:#e8ffe8; text-shadow:0 2px 4px #000; }
.vid .cam { position:absolute; left:30px; bottom:22px; font-family:ISB; font-size:34px; color:#e8ffe8; text-shadow:0 2px 4px #000; }
.ph { width:500px; height:889px; border-radius:36px; overflow:hidden; }
.ph img { width:100%; height:100%; object-fit:cover; filter: brightness(.72) contrast(1.1) saturate(.85); }
.dots { display:flex; gap:12px; padding:30px 36px; }
.dots i { display:block; width:24px; height:24px; border-radius:50%; background:rgba(255,255,255,.55); }
#inp { position:absolute; left:0; right:0; bottom:0; height:190px; background:#121218; display:flex; align-items:center; gap:24px; padding:0 34px 40px; border-top:2px solid rgba(255,255,255,.06); }
#inp .plus { width:84px; height:84px; border-radius:50%; background:#2a2a32; font-size:64px; line-height:80px; text-align:center; color:#aaa; flex:none; }
#field { flex:1; height:100px; border-radius:50px; border:3px solid #33333c; font-size:54px; padding-top:16px; padding:18px 34px; color:#fff; white-space:nowrap; overflow:hidden; }
#field.ph { color:#66666e; }
#send { width:92px; height:92px; border-radius:50%; background:#ff6a00; flex:none; opacity:.25; }
#send.on { opacity:1; }
/* ---------- the zoom */
#zoom { background:#000; }
#zimg { position:absolute; inset:0; width:1080px; height:1920px; object-fit:cover; filter: brightness(.72) contrast(1.15) saturate(.85); }
/* ---------- incoming call */
#ring { background:#000; }
#rbg { position:absolute; inset:-60px; width:1200px; height:2040px; object-fit:cover; filter: blur(40px) brightness(.5); }
#rpf { position:absolute; left:50%; top:430px; width:300px; height:300px; margin-left:-150px; border-radius:50%; object-fit:cover; }
#rnm { position:absolute; left:0; right:0; top:780px; text-align:center; font-family:OB; font-size:96px; }
#rsub { position:absolute; left:0; right:0; top:910px; text-align:center; font-size:44px; opacity:.7; }
.cb { position:absolute; top:1480px; width:190px; height:190px; border-radius:50%; }
#dec { left:180px; background:#ff3b30; } #acc { right:180px; background:#30d158; }
.cbl { position:absolute; top:1690px; width:300px; text-align:center; font-size:38px; opacity:.8; }
/* ---------- the call */
#call { background:#000; }
#cimg { position:absolute; inset:0; width:1080px; height:1920px; object-fit:cover; }
#ctop { position:absolute; left:0; right:0; top:120px; text-align:center; }
#ctop .n { font-family:OB; font-size:60px; text-shadow:0 3px 12px rgba(0,0,0,.6); } #ctop .t { font-size:40px; opacity:.85; text-shadow:0 3px 10px rgba(0,0,0,.6); }
#pip { position:absolute; right:44px; top:300px; width:250px; height:420px; border-radius:30px; overflow:hidden; border:3px solid rgba(255,255,255,.3); }
#pip img { width:100%; height:100%; object-fit:cover; filter: brightness(.45) blur(1px); }
#cbar { position:absolute; left:120px; right:120px; bottom:110px; height:200px; border-radius:100px; background:rgba(30,30,36,.6); display:flex; justify-content:space-around; align-items:center; }
#cbar i { display:block; width:130px; height:130px; border-radius:50%; background:rgba(255,255,255,.18); }
#cbar i.end { background:#ff3b30; }
#weak { position:absolute; left:50%; top:260px; transform:translateX(-50%); font-family:ISB; font-size:34px; padding:12px 26px; border-radius:30px; background:rgba(0,0,0,.55); color:#ffd60a; opacity:0; }
/* ---------- scare */
#scare { background:#000; }
#simg { position:absolute; inset:0; width:1080px; height:1920px; object-fit:cover; }
/* ---------- end */
#endc { background:#000; }
#ebg { position:absolute; inset:-40px; width:1160px; height:2000px; object-fit:cover; filter: blur(10px) brightness(.32) saturate(.7); }
#e1 { position:absolute; left:0; right:0; top:700px; text-align:center; font-family:OB; font-size:88px; }
#e2 { position:absolute; left:0; right:0; top:830px; text-align:center; font-family:ISB; font-size:50px; color:#ff8a2a; }
#e3 { position:absolute; left:50%; top:1010px; transform:translateX(-50%); padding:28px 56px; border-radius:20px; background:#ff8a2a; color:#000; font-family:OB; font-size:64px; white-space:nowrap; }
#e4 { position:absolute; left:0; right:0; top:1250px; text-align:center; font-size:46px; opacity:.9; }
#e0 { position:absolute; left:50%; top:470px; width:150px; height:120px; margin-left:-75px; }
.l { position:absolute; inset:0; pointer-events:none; }
#grain { mix-blend-mode: soft-light; opacity:.08; }
#flash { background:#fff; opacity:0; } #black { background:#000; opacity:0; }
</style></head><body>
<div class="scr" id="lock"><img id="lwall" src="${IM.wall}"/>
  <div id="ldate">Friday the 13th</div><div id="ltime">3:12</div>
  <div class="note" id="n1" style="top:620px"><div class="ic"></div><div class="tx"><div class="h">the attic crew 🏚️<span>now</span></div><div class="b">maya: guys</div></div></div>
  <div class="note" id="n2" style="top:840px"><div class="ic"></div><div class="tx"><div class="h">the attic crew 🏚️<span>now</span></div><div class="b">maya: someone is in my attic</div></div></div>
  <div id="swipe"></div></div>
<div class="scr" id="chat">
  <div id="hdr"><div class="back">‹</div>
    <div class="gav"><img src="${IM.jake}" style="left:56px;top:0"/><img src="${IM.leo}" style="left:0;top:34px"/><img src="${IM.maya}" style="left:60px;top:38px"/></div>
    <div><div class="nm">the attic crew 🏚️</div><div class="sub" id="members">maya, jake, you</div></div><div class="vc"></div></div>
  <div id="list"></div>
  <div id="inp"><div class="plus">+</div><div id="field" class="ph">Message</div><div id="send"></div></div></div>
<div class="scr" id="zoom"><img id="zimg" src="${IM.photo}"/></div>
<div class="scr" id="ring"><img id="rbg" src="${IM.maya}"/><img id="rpf" src="${IM.maya}"/><div id="rnm">maya</div><div id="rsub">incoming video call...</div>
  <div class="cb" id="dec"></div><div class="cb" id="acc"></div><div class="cbl" style="left:125px">Decline</div><div class="cbl" style="right:125px">Accept</div></div>
<div class="scr" id="call"><img id="cimg"/><div id="ctop"><div class="n">maya</div><div class="t" id="ctime">00:00</div></div><div id="weak">poor connection</div>
  <div id="pip"><img src="${IM.leo}"/></div><div id="cbar"><i></i><i></i><i class="end"></i></div></div>
<div class="scr" id="scare"><img id="simg"/></div>
<div class="scr" id="endc"><img id="ebg" src="${IM.wall}"/>
  <div id="e0" class="gav"><img src="${IM.jake}" style="left:56px;top:0"/><img src="${IM.leo}" style="left:0;top:34px"/><img src="${IM.maya}" style="left:60px;top:38px;filter:grayscale(1) brightness(.6)"/></div>
  <div id="e1">someone lives in our attic.</div><div id="e2">play it with your group chat.</div><div id="e3">SEARCH IT ON ROBLOX</div><div id="e4">send this to your group chat 👀</div></div>
<div class="sb" id="sb"><span id="clock">3:12</span><div class="r"><div class="bars"><i style="height:12px"></i><i style="height:18px"></i><i style="height:24px;opacity:.35"></i><i style="height:30px;opacity:.35"></i></div><div class="bat"><b></b><span>9%</span></div></div></div>
<canvas class="l" id="grain" width="540" height="960" style="width:1080px;height:1920px"></canvas>
<div class="l" id="flash"></div><div class="l" id="black"></div>
<script>
const TL = ${JSON.stringify({ phases: tl.phases, msgs: tl.msgs, typing: tl.typing })};
const PF = { maya: '${IM.maya}', jake: '${IM.jake}' };
const CCTV_LAST = '${IM.cctvLast}';
const $ = (id) => document.getElementById(id);
const clamp = (x, a, b) => Math.max(a, Math.min(b, x));
const seg = (t, a, b) => clamp((t - a) / (b - a), 0, 1);
const ease = (x) => x * x * (3 - 2 * x);
const back = (x) => { x = clamp(x, 0, 1); const c = 1.6; return 1 + (c + 1) * Math.pow(x - 1, 3) + c * Math.pow(x - 1, 2); };
function rnd(n) { const x = Math.sin(n * 127.1 + 311.7) * 43758.5453; return x - Math.floor(x); }
const NAMECOL = { maya: '#6cb4ff', jake: '#ff7070' };
const P = TL.phases;
const g = $('grain').getContext('2d'); const gi = g.createImageData(540, 960);
function show(id) { for (const s of ['lock','chat','zoom','ring','call','scare','endc']) $(s).style.display = s === id ? 'block' : 'none'; }
function buildChat(t, dyn) {
  const L = $('list'); L.innerHTML = '';
  const vis = TL.msgs.filter(m => m.t <= t);
  let last = null;
  vis.forEach((m, i) => {
    const w = document.createElement('div'); w.className = 'w';
    if (m.who === 'sys') { w.innerHTML = '<div class="sys">' + m.text + '</div>'; }
    else {
      const nxt = vis[i + 1]; const isLastRun = !nxt || nxt.who !== m.who;
      const prev = vis[i - 1]; const isFirstRun = !prev || prev.who !== m.who;
      let body;
      if (m.kind === 'video') {
        const k = Math.floor((t - m.t) * 30);
        const src = dyn && k < 102 ? dyn : CCTV_LAST;
        const secs = 41 + Math.min(3, Math.floor((t - m.t)));
        body = '<div class="vid"><img src="' + src + '"/><div class="ov"></div><div class="rec"><i></i>REC</div><div class="cam">HALL CAM 02</div><div class="ts">03:11:' + secs + ' AM</div></div>';
      } else if (m.kind === 'photo') body = '<div class="ph"><img src="${IM.photo}"/></div>';
      else body = '<div class="bub">' + m.text + '</div>';
      if (m.who === 'me') w.innerHTML = '<div class="row me">' + body + '</div>';
      else w.innerHTML = '<div class="row">' + '<img class="pf' + (isLastRun ? '' : ' no') + '" src="' + PF[m.who] + '"/>' +
        '<div class="col">' + (isFirstRun ? '<div class="who" style="color:' + NAMECOL[m.who] + '">' + m.who + '</div>' : '') + body + '</div></div>';
    }
    L.appendChild(w); last = { w, m };
  });
  // typing dots
  const ty = TL.typing.find(y => t >= y.t0 && t < y.t1);
  if (ty) {
    const w = document.createElement('div'); w.className = 'w';
    const ph = (t * 3) % 1;
    const dots = [0, 1, 2].map(j => '<i style="transform:translateY(' + (-10 * Math.max(0, Math.sin((ph - j * 0.18) * Math.PI * 2))) + 'px)"></i>').join('');
    const lm = vis[vis.length - 1];
    w.innerHTML = '<div class="row"><img class="pf" src="' + PF[ty.who] + '"/><div class="col">' + (lm && lm.who === ty.who ? '' : '<div class="who" style="color:' + NAMECOL[ty.who] + '">' + ty.who + '</div>') + '<div class="bub dots">' + dots + '</div></div></div>';
    L.appendChild(w);
    const k = ease(seg(t, ty.t0, ty.t0 + 0.18)); const h = w.offsetHeight; w.style.height = (h * k) + 'px'; w.style.opacity = k;
    if (lm && lm.who === ty.who) { const prevRow = last && last.w.querySelector('.pf'); if (prevRow) prevRow.classList.add('no'); }
  }
  // the newest message slides in and pushes the list up
  if (last) {
    const k = seg(t, last.m.t, last.m.t + 0.22);
    if (k < 1) { const h = last.w.offsetHeight; last.w.style.height = (h * ease(k)) + 'px'; last.w.style.opacity = k;
      last.w.firstChild.style.transform = 'scale(' + (0.9 + 0.1 * back(k)) + ')'; last.w.firstChild.style.transformOrigin = last.m.who === 'me' ? '100% 100%' : '0% 100%'; }
  }
  // my messages get typed out first
  const fld = $('field'); const nextMe = TL.msgs.find(m => m.who === 'me' && m.t > t && m.t - t < 0.9);
  if (nextMe) { const n = Math.ceil(nextMe.text.length * seg(t, nextMe.t - 0.9, nextMe.t - 0.15)); fld.textContent = nextMe.text.slice(0, n) + (Math.floor(t * 4) % 2 ? '|' : ''); fld.className = ''; $('send').className = n > 0 ? 'on' : ''; }
  else { fld.textContent = 'Message'; fld.className = 'ph'; $('send').className = ''; }
}
window.setFrame = (f, dyn) => {
  const t = f / 30;
  let fl = 0, bk = 0;
  $('sb').style.display = 'flex';
  $('clock').textContent = t > P.after ? '3:13' : '3:12';
  if (t < P.chat) {
    show('lock');
    const k1 = seg(t, 0.25, 0.5), k2 = seg(t, 0.85, 1.1);
    $('n1').style.opacity = k1; $('n1').style.transform = 'translateY(' + (-40 * (1 - back(k1))) + 'px) scale(' + (0.9 + 0.1 * back(k1)) + ')';
    $('n2').style.opacity = k2; $('n2').style.transform = 'translateY(' + (-40 * (1 - back(k2))) + 'px) scale(' + (0.9 + 0.1 * back(k2)) + ')';
    // swipe up into the chat
    const ks = ease(seg(t, 1.35, 1.7));
    $('lock').style.transform = 'translateY(' + (-1920 * ks) + 'px)';
    if (ks > 0) { $('chat').style.display = 'block'; buildChat(t, null); $('chat').style.zIndex = 0; $('lock').style.zIndex = 1; }
    if (t < 0.12) bk = 1 - seg(t, 0, 0.12);
  } else if (t < P.ring || (t >= P.after && t < P.end)) {
    show('chat'); $('lock').style.transform = 'none';
    buildChat(t, dyn);
    if (t >= P.zoom0 && t < P.zoom1) {
      // tap the photo: it opens full screen and pushes in on the hatch
      show('zoom'); $('sb').style.display = 'none';
      const k = ease(seg(t, P.zoom0 + 0.25, P.zoom1 - 0.3));
      const ko = seg(t, P.zoom0, P.zoom0 + 0.2);
      $('zimg').style.transformOrigin = '50% 23%'; $('zimg').style.transform = 'scale(' + ((0.45 + 0.55 * ease(ko)) * (1 + 1.9 * k)) + ')';
      if (t > P.zoom1 - 0.15) bk = seg(t, P.zoom1 - 0.15, P.zoom1);
    }
    if (t >= P.after && t < P.after + 0.35) bk = 1 - seg(t, P.after, P.after + 0.35);
  } else if (t < P.call) {
    show('ring');
    const k = seg(t, P.ring, P.ring + 0.2); $('ring').style.opacity = k;
    const pulse = 1 + 0.06 * Math.max(0, Math.sin(t * 9));
    $('acc').style.transform = 'scale(' + (t > P.call - 0.3 ? 0.85 : pulse) + ')';
    $('rpf').style.transform = 'scale(' + (1 + 0.03 * Math.sin(t * 5)) + ')';
  } else if (t < P.scare) {
    show('call'); $('ring').style.opacity = 1;
    $('cimg').src = dyn;
    const lt = t - P.call;
    $('ctime').textContent = '00:0' + Math.floor(lt);
    // the connection starts to break up as he comes down
    const gl = seg(t, P.scare - 0.9, P.scare);
    const j = gl > 0 && rnd(f) < 0.25 + 0.5 * gl;
    $('cimg').style.filter = j ? 'hue-rotate(' + (rnd(f + 2) * 90 - 45) + 'deg) contrast(1.4) saturate(1.4)' : 'contrast(1.05)';
    $('cimg').style.transform = j ? 'translateX(' + (rnd(f + 5) - .5) * 40 + 'px) scale(1.02)' : 'none';
    $('weak').style.opacity = seg(t, P.scare - 1.3, P.scare - 1.1);
  } else if (t < P.after) {
    show('scare'); $('sb').style.display = 'none';
    $('simg').src = dyn;
    const lt = t - P.scare; const sh = 40 * (1 - seg(lt, 0, 0.6));
    $('simg').style.transform = 'translate(' + (rnd(f) - .5) * sh + 'px,' + (rnd(f + 3) - .5) * sh + 'px) scale(' + (1.08 + 0.1 * seg(lt, 0, 1)) + ')';
    $('simg').style.filter = 'contrast(1.25) brightness(1.5)';
    fl = 0.95 * (1 - seg(lt, 0, 0.18));
    if (lt > 0.85) bk = seg(lt, 0.85, 1.0);
  } else {
    show('endc'); $('sb').style.display = 'none';
    const lt = t - P.end;
    if (lt < 0.25) bk = 1 - seg(lt, 0, 0.25);
    const pop = (id, at, x) => { const k = seg(lt, at, at + 0.22); $(id).style.opacity = k > 0 ? 1 : 0; $(id).style.transform = (x || '') + ' scale(' + (0.6 + 0.4 * back(k)) + ')'; };
    pop('e0', 0.1); pop('e1', 0.3); pop('e2', 0.9); pop('e3', 1.5, 'translateX(-50%)'); $('e4').style.opacity = seg(lt, 2.2, 2.5);
    if (t > P.dur - 0.4) bk = seg(t, P.dur - 0.4, P.dur);
  }
  $('flash').style.opacity = fl; $('black').style.opacity = bk;
  const d = gi.data;
  for (let i2 = 0; i2 < d.length; i2 += 4) { const v = (128 + (Math.random() - 0.5) * 150) | 0; d[i2] = d[i2 + 1] = d[i2 + 2] = v; d[i2 + 3] = 255; }
  g.putImageData(gi, 0, 0);
};
</script></body></html>`;

const browser = await chromium.launch({ executablePath: '/opt/pw-browsers/chromium-1194/chrome-linux/chrome' });
const page = await browser.newPage({ viewport: { width: 1080, height: 1920 } });
await page.setContent(html);
await page.evaluate(() => document.fonts.ready);
const P = tl.phases;
const vid = tl.msgs.find(m => m.kind === 'video');
function dynFor(t) {
  if (t >= P.call && t < P.scare) return tl.call[Math.min(tl.call.length - 1, Math.floor((t - P.call) * 30))];
  if (t >= P.scare && t < P.after) return tl.scare[Math.min(tl.scare.length - 1, Math.floor((t - P.scare) * 30))];
  if (vid && t >= vid.t && t < vid.t + tl.cctv.length / 30) return tl.cctv[Math.floor((t - vid.t) * 30)];
  return null;
}
const from = +(fromArg ?? 0), to = +(toArg ?? NF - 1);
for (let f = from; f <= to; f++) {
  const p = dynFor(f / 30);
  const d = p ? img(p) : null;
  await page.evaluate(async ([f, d]) => {
    window.setFrame(f, d);
    await Promise.all([...document.images].filter(i => !i.complete).map(i => i.decode().catch(() => {})));
  }, [f, d]);
  fs.writeFileSync(`${outDir}/${String(f).padStart(4, '0')}.png`, await page.screenshot({ type: 'png' }));
  if (f % 60 === 0) console.log('comp', f);
}
await browser.close();
