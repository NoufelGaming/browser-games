# Rescan browser-game sources -> polished shareable site (v3)
# Run: powershell -ExecutionPolicy Bypass -File rescan-browser-games.ps1
$ErrorActionPreference = "Continue"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $ScriptDir) { $ScriptDir = "C:\Users\Zayne\Desktop\Dev" }
$OutHtml = Join-Path $ScriptDir "index.html"
$OutAuto = Join-Path $ScriptDir "browser-games.auto.html"
$OutJson = Join-Path $ScriptDir "browser-games-sources.json"
$Today = (Get-Date).ToString("yyyy-MM-dd")
$Stamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-dd HH:mm UTC")

$Sources = @(
  "https://recompiledgames.com/",
  "https://decompgames.com/",
  "https://foundplay.io/collections/classic-games-in-your-browser"
)

$ManualGames = @(
  @{name="BO1 Zombies (all maps)"; url="https://vel.gg/bo1z"},
  @{name="Moon (Zombies)"; url="https://moon-zombies.pages.dev/"},
  @{name="Kino der Toten"; url="https://kino-der-toten.pages.dev/"},
  @{name="BO3 Cheese Cube"; url="https://cheese-cube.pages.dev/"},
  @{name="Black Ops 2 (AI rebuild)"; url="https://vibeslops.luckeysystems.com/"},
  @{name="Modern Warfare 2"; url="https://ovz-game-production.up.railway.app/"},
  @{name="Skate 3"; url="https://skate.aaddpp.lol/"},
  @{name="Skate Rust / Global Terror"; url="https://global-terror.net/"},
  @{name="CS Surf"; url="https://surfd.net/"},
  @{name="Halo CE"; url="https://mitchellhynes.com/halo"},
  @{name="Halo CE Mobile"; url="https://hcemobile.com/"},
  @{name="PES 6"; url="https://pes6.optijuegos.net/"},
  @{name="GTA 5 (archive)"; url="https://web.archive.org/web/20261006055917/https://playgta5.com/"},
  @{name="GTA Vice City (reVC)"; url="https://joncodeofficial.github.io/gta-vice-city-wasm"},
  @{name="Simpsons Hit & Run"; url="https://shar-wasm.cjoseph.workers.dev/?skipmovie"},
  @{name="Quake 1"; url="https://q1.pieter.com/"},
  @{name="Quake 2"; url="https://q2.pieter.com/"},
  @{name="Quake 3"; url="https://q3.pieter.com/"},
  @{name="Return to Castle Wolfenstein"; url="https://rtcw.pieter.com/"},
  @{name="Urban Terror (listed as UT)"; url="https://ut.pieter.com/"},
  @{name="Half-Life (pixelsuft)"; url="https://pixelsuft.github.io/hl/"},
  @{name="Half-Life / CS 1.6 WebXash"; url="https://x8bitrain.github.io/webXash/"},
  @{name="Diablo (DevilutionX)"; url="https://johnimril.github.io/diablo_web/"},
  @{name="Hedgewars"; url="https://webwars.link/"},
  @{name="WaW Zombies"; url="https://zombies.bitcoinsapi.com/"},
  @{name="OpenHaloCE"; url="https://openhaloce.com/"},
  @{name="Bunnyhop"; url="https://bunnyhop.lol/"}
)

function Decode($s) { return [System.Net.WebUtility]::HtmlDecode($s).Trim() }
function NormKey($u) { return ($u.Trim().ToLower().TrimEnd("/") -replace '^http://','https://') }
function DomainOf($u) { try { return ([uri]$u).Host -replace '^www\.','' } catch { return ($u -replace '^https?://','').Split('/')[0] } }

function Get-Category($name, $url) {
  $n = $name.ToLower()
  if ($n -match "halo|doom|quake|wolfenstein|counter-strike|call of duty|black ops|warfare|zombies|kino|moon|nuketown|half-life|half life|turok|goldeneye|perfect dark|urban terror|bunnyhop|surf|myth|cheese|cube") { return "Shooters" }
  if ($n -match "grand theft|\bgta\b|vice city|san andreas|hit and run|hit & run|open world|mafia|just cause|sleeping dogs|saints row") { return "Action and Open World" }
  if ($n -match "skate|racing|kart|f-zero|wave race|diddy kong|pes |fifa|madden|nba|soccar|snowboard|tony hawk|rugby|carmageddon|driver|gran turismo|need for speed") { return "Racing and Sports" }
  if ($n -match "mario 64|mario kart|banjo|donkey kong|conker|yoshi|crash |spyro|sonic|kirby|bugdom|elasto|chip|commander keen|prince of persia|tomb raider|pitfall") { return "Platformers" }
  if ($n -match "zelda|pok.mon|diablo|golden sun|final fantasy|star fox|banjo|metroid|castlevania|resident evil|witcher|skyrim|fallout|chrono|earthbound|fire emblem") { return "RPG and Adventure" }
  if ($n -match "smash|melee|fighter|virtua fighter|mortal kombat|street fighter|tekken|kill la kill") { return "Fighting" }
  if ($n -match "command|conquer|red alert|warzone|warcraft|starcraft|age of|openttd|simcity|micropolis|civilization|tycoon|lemmings|kerbal|openra|generals|hedgewars|worms") { return "Strategy and Sim" }
  if ($n -match "party|dr\. mario|tetris|pinball|puzzle|kart|chess|solitaire|minesweeper|space cadet|paperroute|zork|hend") { return "Puzzle and Party" }
  return "Classics and Other"
}
function CatIcon($c) {
  if ($c -eq "Shooters") { return "&#x1F52B;" }
  if ($c -eq "Racing and Sports") { return "&#x1F3C1;" }
  if ($c -eq "Platformers") { return "&#x1F344;" }
  if ($c -eq "RPG and Adventure") { return "&#x1F5FA;" }
  if ($c -eq "Fighting") { return "&#x1F94A;" }
  if ($c -eq "Action and Open World") { return "&#x1F3D9;" }
  if ($c -eq "Strategy and Sim") { return "&#x1F3D7;" }
  if ($c -eq "Puzzle and Party") { return "&#x1F9E9;" }
  return "&#x2728;"
}

function Get-RecompiledGames {
  $url = "https://recompiledgames.com/"
  Write-Host "Scanning $url ..."
  $r = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 30 -Headers @{"User-Agent"="Mozilla/5.0"}
  $anchors = [regex]::Matches($r.Content, '<a[^>]+href="([^"]+)"[^>]*>(.*?)</a>', 'Singleline')
  $out = @(); $lastTitle = $null
  foreach ($m in $anchors) {
    $h = $m.Groups[1].Value.Trim()
    $t = Decode([regex]::Replace($m.Groups[2].Value, '<[^>]+>', '') -replace '\s+', ' ')
    if ($t.Length -gt 120) { $t = $t.Substring(0,120) }
    if ($h -match "^/[^/]" -and $h -match "recompiled" -and $t.Length -ge 3 -and $t -notmatch "^(Read the deep dive|PLAY|Play|Suggest.*)$") { $lastTitle = $t }
    if ($h -match "^https?://" -and $h -notmatch "(x\.com|twitter\.com|discord\.gg|github\.com/|clarity\.ms|googlesyndication|fonts\.google)") {
      if ($t -match "^(PLAY|Play)$" -and $lastTitle) { $out += @{name=$lastTitle; url=$h; source="recompiledgames.com"} }
    }
  }
  Write-Host " -> $($out.Count)"; return $out
}
function Get-DecompGames {
  $url = "https://decompgames.com/"
  Write-Host "Scanning $url ..."
  $r = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 30 -Headers @{"User-Agent"="Mozilla/5.0"}
  $pairs = [regex]::Matches($r.Content, 'data-title="([^"]+)"[^>]*>.*?<a[^>]+href="(/games/[^"]+)"', 'Singleline')
  $out = @()
  foreach ($m in $pairs) { $out += @{name=(Decode $m.Groups[1].Value); url=("https://decompgames.com" + $m.Groups[2].Value); source="decompgames.com"} }
  Write-Host " -> $($out.Count)"; return $out
}
function Get-FoundplayGames {
  $url = "https://foundplay.io/collections/classic-games-in-your-browser"
  Write-Host "Scanning $url ..."
  $r = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 30 -Headers @{"User-Agent"="Mozilla/5.0"}
  $out = @()
  $ld = [regex]::Match($r.Content, '<script type="application/ld\+json">(.*?)</script>', 'Singleline')
  if ($ld.Success) {
    $data = $ld.Groups[1].Value | ConvertFrom-Json
    foreach ($item in $data.itemListElement) {
      if (-not $item.url -or -not $item.name) { continue }
      $slug = ($item.url -replace '^https://foundplay\.io/games/', '') -replace '/$', ''
      $out += @{name=[string]$item.name; url=("https://foundplay.io/go/" + $slug); detail=[string]$item.url; source="foundplay.io"}
    }
  }
  Write-Host " -> $($out.Count)"; return $out
}

# Load history for firstSeen / change detection
$prev = @{}
$prevList = @()
if (Test-Path $OutJson) {
  try {
    $pj = Get-Content $OutJson -Raw | ConvertFrom-Json
    foreach ($g in $pj.games) { $prev[(NormKey $g.url)] = $g; $prevList += $g }
  } catch { Write-Warning "Could not read prev JSON, starting fresh" }
}
$baseline = "2026-09-20"

$scanned = @()
$scanned += Get-RecompiledGames
$scanned += Get-DecompGames
$scanned += Get-FoundplayGames

# Merge scanned + manual, dedup (manual wins name)
$byKey = @{}
foreach ($g in $scanned) {
  $k = NormKey $g.url
  if (-not $byKey.ContainsKey($k)) { $byKey[$k] = @{name=$g.name; url=$g.url; source=$g.source; detail=$g.detail} }
}
foreach ($mg in $ManualGames) {
  $k = NormKey $mg.url
  $byKey[$k] = @{name=$mg.name; url=$mg.url; source="tweet"}
}

$merged = @(); $added = @()
foreach ($k in $byKey.Keys) {
  $e = $byKey[$k]
  $old = $prev[$k]
  if ($old -and $old.firstSeen) { $first = $old.firstSeen }
  elseif ($old) { $first = $baseline }
  else { $first = $Today; $added += $e }
  $cat = Get-Category $e.name $e.url
  $merged += @{
    name=$e.name; url=$e.url; source=$e.source; detail=$e.detail
    category=$cat; icon=(CatIcon $cat); domain=(DomainOf $e.url)
    firstSeen=$first; lastSeen=$Today; offline=$false
  }
}
# Keep disappeared as offline (not deleted) for 30 days
foreach ($pk in $prev.Keys) {
  if (-not $byKey.ContainsKey($pk)) {
    $o = $prev[$pk]
    $lastSeen = $o.lastSeen
    try { $age = ((Get-Date) - (Get-Date $lastSeen)).Days } catch { $age = 99 }
    if ($age -le 30) {
      $o.offline = $true
      $merged += $o
    }
  }
}

$merged = $merged | Sort-Object { if ($_.source -eq "tweet") { "0_" + $_.name } else { "1_" + $_.name } }
$newCount = ($merged | Where-Object {
  try { (((Get-Date) - (Get-Date $_.firstSeen)).Days) -le 14 } catch { $false }
}).Count

$json = @{updated=$Stamp; sources=$Sources; count=$merged.Count; newCount=$newCount; addedThisScan=($added | Select-Object name,url,source); games=$merged} | ConvertTo-Json -Depth 5
$json | Out-File -FilePath $OutJson -Encoding UTF8
Write-Host "Total $($merged.Count), new this scan $($added.Count), new<=14d $newCount"

# Build data JSON for embedding (compact)
$dataJson = ($merged | ForEach-Object {
  @{n=$_.name; u=$_.url; d=$_.domain; c=$_.category; i=$_.icon; s=$_.source; f=$_.firstSeen; o=$_.offline}
} | ConvertTo-Json -Depth 3 -Compress)

$template = @'
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Browser Games - Play Decompiled Games in Your Browser</title>
<meta name="description" content="Play decompiled games in your browser. No download. Auto-updated list.">
<link rel="icon" href="data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'%3E%3Crect width='100' height='100' rx='20' fill='%23151b26'/%3E%3Ctext x='50' y='68' font-size='55' text-anchor='middle'%3EG%3C/text%3E%3C/svg%3E">
<meta property="og:title" content="Browser Games - Play Decompiled Games in Your Browser">
<meta property="og:description" content="Play decompiled games in your browser. No download. Auto-updated list.">
<meta property="og:type" content="website">
<style>
:root{--bg:#0b0e14;--card:#151b26;--line:#232c3f;--txt:#e9edf5;--mut:#9aa6bd;--acc:#7dd3fc;--acc2:#a78bfa;--new:#34d399}
*{box-sizing:border-box}body{margin:0;font-family:ui-sans-serif,system-ui,-apple-system,Segoe UI,Roboto,Arial;background:radial-gradient(1200px 600px at 20% -10%,#1b2540 0%,var(--bg) 55%) fixed,var(--bg);color:var(--txt)}
.wrap{max-width:1080px;margin:0 auto;padding:28px 18px 60px}
.hero{background:linear-gradient(135deg,#182238,#101828);border:1px solid var(--line);border-radius:20px;padding:26px 22px;display:flex;gap:18px;flex-wrap:wrap;align-items:center;justify-content:space-between}
.hero h1{margin:0;font-size:clamp(22px,3.4vw,34px);letter-spacing:-.02em}
.hero p{margin:8px 0 0;color:var(--mut);max-width:640px}
.stats{display:flex;gap:10px;flex-wrap:wrap;margin-top:12px}
.pill{background:#0f1626;border:1px solid var(--line);border-radius:999px;padding:6px 12px;font-size:13px;color:var(--mut)}
.pill b{color:var(--txt)}
.pill.new{border-color:#134e4a;color:#a7f3d0}.pill.new b{color:#ecfdf5}
.actions{display:flex;gap:10px;flex-wrap:wrap}
.btn{appearance:none;border:1px solid var(--line);background:#1c2537;color:var(--txt);border-radius:12px;padding:10px 14px;font-size:14px;cursor:pointer}
.btn.primary{background:linear-gradient(135deg,var(--acc),var(--acc2));color:#081018;border:0;font-weight:700}
.btn:hover{filter:brightness(1.08)}
.bar{position:sticky;top:0;z-index:5;background:rgba(11,14,20,.86);backdrop-filter:blur(10px);border:1px solid var(--line);border-radius:16px;padding:12px;margin:16px 0;display:grid;gap:10px}
.search{display:flex;gap:10px}.search input{flex:1;background:#0f1626;border:1px solid var(--line);color:var(--txt);border-radius:12px;padding:12px 14px;font-size:15px}
.row{display:flex;gap:8px;flex-wrap:wrap;align-items:center}
.chip{border:1px solid var(--line);background:#101728;color:var(--mut);border-radius:999px;padding:7px 12px;font-size:13px;cursor:pointer}
.chip.on{background:var(--txt);color:#0b0e14;border-color:var(--txt);font-weight:700}
select{background:#0f1626;color:var(--txt);border:1px solid var(--line);border-radius:10px;padding:8px 10px}
.grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(240px,1fr));gap:12px;margin-top:14px}
.card{background:var(--card);border:1px solid var(--line);border-radius:16px;padding:14px;display:flex;flex-direction:column;gap:8px;min-height:150px}
.card:hover{border-color:#33415e;transform:translateY(-1px)}
.top{display:flex;gap:10px;align-items:flex-start}.ico{font-size:26px;line-height:1;background:#0e1422;border:1px solid var(--line);border-radius:12px;width:44px;height:44px;display:grid;place-items:center;flex-shrink:0}
.ttl{font-weight:700;line-height:1.25}.dom{color:var(--mut);font-size:12.5px;word-break:break-all}
.tags{display:flex;gap:6px;flex-wrap:wrap;margin-top:auto}.tag{font-size:11.5px;border:1px solid var(--line);border-radius:999px;padding:3px 9px;color:var(--mut)}
.tag.cat{color:#dbeafe}.tag.new{background:#064e3b;color:#a7f3d0;border-color:#065f46;font-weight:800}.tag.off{background:#451a1a;color:#fecaca;border-color:#7f1d1d}
.play{margin-top:6px;display:flex;gap:8px}.play a{flex:1;text-align:center;text-decoration:none;background:linear-gradient(135deg,var(--acc),var(--acc2));color:#081018;font-weight:800;border-radius:11px;padding:10px}
.play a:hover{filter:brightness(1.07)}
.meta{display:flex;justify-content:space-between;align-items:center;color:var(--mut);font-size:13px;margin:14px 2px}
.news{background:#0d1f1a;border:1px solid #134e4a;border-radius:16px;padding:14px;margin-top:14px}
.news h3{margin:0 0 8px}.news ul{margin:0;padding-left:18px;color:#d1fae5}
footer{color:var(--mut);font-size:13px;margin-top:22px;line-height:1.6}
footer a{color:var(--acc)}
.empty{display:none;text-align:center;color:var(--mut);padding:30px;border:1px dashed var(--line);border-radius:16px;margin-top:14px}
.sr{position:absolute;width:1px;height:1px;overflow:hidden;clip:rect(0 0 0 0);white-space:nowrap}
.copy{background:#0f1626;border:1px solid var(--line);color:var(--mut);border-radius:11px;padding:10px 12px;cursor:pointer}
.copy:hover{color:var(--txt);border-color:#33415e}
@media(max-width:560px){.wrap{padding:16px 12px 50px}.hero{padding:18px}}
</style>
</head>
<body><div class="wrap">
<div class="hero"><div>
<h1>&#x1F3AE; Browser Games</h1>
<p>Play decompiled games in your browser - no download. Auto-rescans sources, finds new ones, organizes by genre. Share this page with friends.</p>
<div class="stats">
<span class="pill"><b>__TOTAL__</b> games</span>
<span class="pill new"><b>__NEWCOUNT__</b> new &lt;=14d</span>
<span class="pill">Updated <b>__STAMP__</b></span>
</div></div>
<div class="actions">
<button class="btn primary" id="surprise">Surprise me</button>
<button class="btn" id="share">Copy share link</button>
</div></div>

<div class="bar">
<div class="search"><label class="sr" for="q">Search games</label><input id="q" placeholder="Search games... try halo, zelda, skate, quake" autocomplete="off"></div>
<div class="row" id="cats"></div>
<div class="row">
<select id="src"><option value="">All sources</option><option value="tweet">Tweet picks</option><option value="recompiledgames.com">recompiledgames</option><option value="decompgames.com">decompgames</option><option value="foundplay.io">foundplay</option></select>
<select id="sort"><option value="feat">Sort: Featured</option><option value="az">Sort: A-Z</option><option value="new">Sort: Newest</option><option value="cat">Sort: Category</option></select>
<button class="chip" id="newOnly">New only</button>
<button class="chip" id="reset">Reset</button>
<span class="pill" id="count" aria-live="polite"></span>
</div></div>

<div class="news" id="news" style="display:none"><h3>New since last scan</h3><ul id="newsList"></ul></div>
<div class="meta"><span id="showing"></span><span>Tip: press / to search</span></div>
<div class="grid" id="grid"></div>
<div class="empty" id="empty">No games match. Try clearing search or filters.</div>

<footer>Sources: <a href="https://recompiledgames.com/">recompiledgames.com</a> - <a href="https://decompgames.com/">decompgames.com</a> - <a href="https://foundplay.io/collections/classic-games-in-your-browser">foundplay.io</a> - tweet mirror <a href="https://twitterviewer.net/RadiantOpti/status/2108068632991256995">RadiantOpti</a> - <a href="https://github.com/NoufelGaming/browser-games/issues">report a broken link</a><br>Fan ports. Some need your own game files. If a page asks to download a launcher, skip it - real browser ports run in the tab.</footer>
</div>
<script id="data" type="application/json">__DATA__</script>
<script>
const games=JSON.parse(document.getElementById('data').textContent);
const DISP={'Racing and Sports':'Racing & Sports','RPG and Adventure':'RPG & Adventure','Strategy and Sim':'Strategy & Sim','Puzzle and Party':'Puzzle & Party','Action and Open World':'Action & Open World'};
const disp=c=>DISP[c]||c;
const cats=[...new Set(games.map(g=>g.c))].sort();
const catBox=document.getElementById('cats');let fCat='',fQ='',fSrc='',fNew=false,fSort='feat';
try{const p=new URLSearchParams(location.search);fCat=p.get('cat')||'';fQ=(p.get('q')||'').toLowerCase();fSrc=p.get('src')||'';fSort=p.get('sort')||'feat';fNew=p.get('new')==='1';if(fQ)document.getElementById('q').value=p.get('q');if(fSrc)document.getElementById('src').value=fSrc;document.getElementById('sort').value=fSort;if(fNew)document.getElementById('newOnly').classList.add('on')}catch(e){}
function chip(t,on,fn){const b=document.createElement('button');b.className='chip'+(on?' on':'');b.textContent=t;b.onclick=()=>fn(b);return b}
function drawCats(){catBox.innerHTML='';catBox.appendChild(chip('All',!fCat,()=>{fCat='';drawCats();draw()}));cats.forEach(c=>catBox.appendChild(chip(disp(c),fCat===c,()=>{fCat=fCat===c?'':c;drawCats();draw()})))}
const grid=document.getElementById('grid'),empty=document.getElementById('empty'),count=document.getElementById('count'),showing=document.getElementById('showing');
function isNew(g){const t=new Date(g.f).getTime();return !isNaN(t)&&(Date.now()-t)<14*864e5}
async function copyText(t,btn){try{await navigator.clipboard.writeText(t);const o=btn.textContent;btn.textContent='Copied!';setTimeout(()=>btn.textContent=o,1200)}catch(e){prompt('Copy this link:',t)}}
function render(list){grid.innerHTML='';list.forEach(g=>{const d=document.createElement('div');d.className='card';const nw=isNew(g)?'<span class="tag new">NEW</span>':'',off=g.o?'<span class="tag off">CHECK LINK</span>':'';d.innerHTML='<div class="top"><div class="ico">'+g.i+'</div><div><div class="ttl"></div><div class="dom">'+g.d+'</div></div></div><div class="tags"><span class="tag cat">'+disp(g.c)+'</span><span class="tag">'+g.s+'</span>'+nw+off+'</div><div class="play"><a target="_blank" rel="noopener" href="'+g.u+'">Play</a><button class="copy">Copy</button></div>';d.querySelector('.ttl').textContent=g.n;const cp=d.querySelector('.copy');cp.onclick=()=>copyText(g.u,cp);grid.appendChild(d)});empty.style.display=list.length?'none':'';count.textContent=list.length+' / '+games.length;showing.textContent=list.length+' shown'}
function syncURL(){try{const p=new URLSearchParams();if(fQ)p.set('q',fQ);if(fCat)p.set('cat',fCat);if(fSrc)p.set('src',fSrc);if(fSort!=='feat')p.set('sort',fSort);if(fNew)p.set('new','1');history.replaceState(null,'',location.pathname+(p.toString()?'?'+p.toString():''))}catch(e){}}
function draw(){let l=games.filter(g=>(!fCat||g.c===fCat)&&(!fSrc||g.s===fSrc)&&(!fNew||isNew(g))&&(!fQ||(g.n+' '+g.d+' '+g.c).toLowerCase().includes(fQ)));if(fSort==='az')l=[...l].sort((a,b)=>a.n.localeCompare(b.n));else if(fSort==='new')l=[...l].sort((a,b)=>new Date(b.f)-new Date(a.f));else if(fSort==='cat')l=[...l].sort((a,b)=>(a.c+b.n).localeCompare(b.c+b.n));render(l);syncURL()}
document.getElementById('q').oninput=e=>{fQ=e.target.value.toLowerCase().trim();draw()};
document.getElementById('src').onchange=e=>{fSrc=e.target.value;draw()};
document.getElementById('sort').onchange=e=>{fSort=e.target.value;draw()};
document.getElementById('newOnly').onclick=e=>{fNew=!fNew;e.target.classList.toggle('on',fNew);draw()};
document.getElementById('reset').onclick=()=>{fCat=fQ=fSrc='';fNew=false;fSort='feat';document.getElementById('q').value='';document.getElementById('src').value='';document.getElementById('sort').value='feat';document.getElementById('newOnly').classList.remove('on');drawCats();draw()};
document.addEventListener('keydown',e=>{if(e.key==='/'){e.preventDefault();document.getElementById('q').focus()}});
document.getElementById('surprise').onclick=()=>{const l=games.filter(g=>!g.o);if(!l.length)return;const g=l[Math.floor(Math.random()*l.length)];window.open(g.u,'_blank')};
document.getElementById('share').onclick=async()=>{try{await navigator.clipboard.writeText(location.href);alert('Link copied - send it to friends!')}catch{prompt('Copy this link:',location.href)}};
try{const added=__ADDED__;if(added&&added.length){document.getElementById('news').style.display='';document.getElementById('newsList').innerHTML=added.slice(0,8).map(a=>'<li></li>').join('');[...document.querySelectorAll('#newsList li')].forEach((li,i)=>li.textContent=added[i].name+' - '+added[i].url)}}catch(e){}
drawCats();draw();
</script></body></html>
'@

$addedJson = ($added | Select-Object name,url,source | ConvertTo-Json -Depth 3 -Compress)
if (-not $addedJson) { $addedJson = "[]" }
$htmlOut = $template.Replace("__DATA__", $dataJson).Replace("__STAMP__", $Stamp).Replace("__TOTAL__", "$($merged.Count)").Replace("__NEWCOUNT__", "$newCount").Replace("__ADDED__", $addedJson)
$htmlOut | Out-File -FilePath $OutHtml -Encoding UTF8
Copy-Item $OutHtml $OutAuto -Force
Write-Host "Wrote $OutHtml (+ auto copy) and $OutJson"
