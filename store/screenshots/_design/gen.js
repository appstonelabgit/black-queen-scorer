// Generates branded "designed" Play screenshots: emerald gradient bg +
// gold caption + device-framed raw screenshot. One HTML per slot, rendered
// to 1080x2160 by Chrome headless (see gen.sh).
const fs = require('fs');
const path = require('path');

const PHONE = path.resolve(__dirname, '..', 'android', 'phone');

// Brand palette (from app: deep emerald + gold #E8B931, cream surface).
const slots = [
  { img: '01_scoreboard.jpg',     caption: 'Live leaderboard.\nZero spreadsheet.' },
  { img: '03_round_entry.jpg',    caption: 'Caller, team, target —\nunder 10 seconds.' },
  { img: '04_summary.jpg',        caption: 'Finish with a\nshareable podium.' },
  { img: '05_home.jpg',           caption: 'One tap,\nback in the game.' },
  { img: '06_lifetime_stats.jpg', caption: 'See who really\nowns the table.' },
];

function html(imgB64, captionHtml) {
  return `<!doctype html><html><head><meta charset="utf-8"><style>
  * { margin:0; padding:0; box-sizing:border-box; }
  html,body { width:1080px; height:2160px; overflow:hidden; }
  body {
    font-family:-apple-system,'Helvetica Neue',Arial,sans-serif;
    background:
      radial-gradient(120% 80% at 50% -10%, rgba(232,185,49,0.16), transparent 60%),
      linear-gradient(165deg, #0c3b2b 0%, #0f4733 45%, #093023 100%);
    position:relative;
  }
  /* faint spade watermark */
  .mark {
    position:absolute; right:-120px; top:380px; font-size:900px; line-height:1;
    color:rgba(232,185,49,0.05); transform:rotate(8deg); user-select:none;
  }
  .cap {
    position:absolute; top:118px; left:0; right:0; text-align:center;
    color:#E8B931; font-weight:800; font-size:74px; line-height:1.12;
    letter-spacing:-1px; padding:0 70px;
    text-shadow:0 2px 18px rgba(0,0,0,0.25);
  }
  .stage {
    position:absolute; top:470px; left:0; right:0;
    display:flex; justify-content:center;
  }
  .device {
    width:734px; height:1468px; border-radius:62px;
    background:#05201700; padding:14px;
    background-color:#04140e;
    box-shadow:0 40px 90px rgba(0,0,0,0.45), 0 0 0 2px rgba(232,185,49,0.18);
  }
  .device img { width:100%; height:100%; object-fit:cover; border-radius:48px; display:block; }
  .foot {
    position:absolute; bottom:116px; left:0; right:0; text-align:center;
    color:rgba(245,240,230,0.72); font-size:34px; font-weight:600;
    letter-spacing:0.5px;
  }
  .foot b { color:#E8B931; font-weight:800; }
  </style></head><body>
    <div class="mark">&#9824;</div>
    <div class="cap">${captionHtml}</div>
    <div class="stage"><div class="device"><img src="${imgB64}"></div></div>
    <div class="foot"><b>Black Queen</b> Scorer</div>
  </body></html>`;
}

for (const s of slots) {
  const buf = fs.readFileSync(path.join(PHONE, s.img));
  const b64 = 'data:image/jpeg;base64,' + buf.toString('base64');
  const cap = s.caption.split('\n').join('<br>');
  const out = path.join(__dirname, s.img.replace('.jpg', '.html'));
  fs.writeFileSync(out, html(b64, cap));
  console.log('wrote', path.basename(out));
}
