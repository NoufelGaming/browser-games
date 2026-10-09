# Host your Browser Games page for free

Your shareable file is `index.html` (single file, no server needed).

## Option A - Fastest: Netlify Drop (2 minutes, great for friends)
1. Go to https://app.netlify.com/drop
2. Drag ONLY `index.html` into the page (rename a copy to `index.html` if needed - yours already is).
3. You get a link like `https://sunny-fox-1234.netlify.app` - send it to friends.
4. To update later: drag the new `index.html` into your Netlify site (Site > Deploys > Drag and drop).

## Option B - Permanent + auto-updates: GitHub Pages (recommended)
1. Create free account at https://github.com, create a new public repo named `browser-games`.
2. Upload these files into the repo: `index.html`, `browser-games-sources.json`, `rescan-browser-games.ps1`, and `.github/workflows/update-games.yml` (already in this folder).
3. In repo: Settings > Pages > Source: Deploy from branch > Branch: main > /(root) > Save.
4. Your link: `https://YOURNAME.github.io/browser-games/` - share it.
5. Auto-scan is now in the cloud: the workflow runs every Sunday and whenever you click Run workflow. It rescans, commits new games, and Pages redeploys automatically.

## Option C - Alternative: Cloudflare Pages
1. https://pages.cloudflare.com > Create project > Upload assets.
2. Upload `index.html` (as `index.html`).
3. Get `https://browser-games.pages.dev` style link.

## Auto-rescan on your PC (weekly)
1. Open Task Scheduler > Create Basic Task > Weekly > Sunday 10am.
2. Action: Start a program. Program: `powershell.exe`
3. Arguments: `-NoProfile -ExecutionPolicy Bypass -File "C:\Users\Zayne\Desktop\Dev\rescan-browser-games.ps1"`
4. If you use GitHub (Option B), after each scan run:
   `git add index.html browser-games-sources.json; git commit -m "update games"; git push`
   Pages redeploys in ~1 min.

## How organizing works
- Categories auto-assigned from game names: Shooters, Racing and Sports, Platformers, RPG and Adventure, Fighting, Strategy and Sim, Puzzle and Party, Classics and Other.
- `firstSeen` date tracked in `browser-games-sources.json`. Games found in the last 14 days get a NEW badge + appear in "New since last scan".
- Dead links are kept 30 days with a CHECK LINK badge instead of vanishing.
- To add your own: edit `$ManualGames` at the top of `rescan-browser-games.ps1`, run it again.
