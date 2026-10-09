# Browser Games - play decompiled games in your browser

No downloads. Open the site, search, filter, hit Play.

- Live site: `https://NoufelGaming.github.io/browser-games/`
- Data: `browser-games-sources.json` (auto-updated with first-seen dates)
- Scanner: `rescan-browser-games.ps1`

## Zero-effort automation (already wired)
- `.github/workflows/update-games.yml` rescans the 3 indexes every Sunday + on demand (Actions > Run workflow).
- New games get a NEW badge automatically and appear in "New since last scan".
- Dead links keep a CHECK LINK badge for 30 days instead of vanishing.
- GitHub Pages redeploys on every push. You do nothing after setup.

## Add your own game
Edit `$ManualGames` at the top of `rescan-browser-games.ps1`, then run:
`powershell -ExecutionPolicy Bypass -File rescan-browser-games.ps1`
