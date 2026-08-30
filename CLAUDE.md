# Ilbi

A Kodi skin, forked from Estuary. Scope is deliberately narrow: **movies and TV shows only**.
Music, PVR/live TV, games, pictures and weather have been removed from the skin.

## Resources

- https://kodi.wiki/view/Skinning_Manual
- https://kodi.wiki/view/Skin_development_introduction
- https://kodi.wiki/view/Skinning_Engine
- https://kodi.wiki/view/TexturePacker
- https://kodi.wiki/view/TextureTool

## TODO

### Clean up leftover links into removed sections

The section prune removed the music/PVR/games/pictures/weather window files, but a
few kept files still contain `ActivateWindow` targets pointing at them. Those
windows now have no skin file, so reaching one logs an error and fails to open.
All of them sit behind paths that are unreachable in normal use, hence deferred:

- `xml/VideoOSD.xml:169` — `ActivateWindow(pvrchannelguide)`; only reachable during live TV playback.
- `xml/Custom_1100_AddonLauncher.xml` — category rows linking to `music`, `games`, `programs`, `pictures`.
- `xml/Variables.xml:202-207` — album-onclick variable with `ActivateWindow(music,…)` targets; dead now that music views are gone.

Not a mechanical delete: the OSD and add-on launcher entries are children of
`grouplist` controls, so removing them shifts sibling layout and navigation.
Worth doing deliberately, checking each window afterwards.

`xml/Includes_PVR.xml` is **intentionally kept** despite PVR being gone — it defines
`PVRProgress` and `PVRChannelNumberInput`, which `xml/DialogSeekBar.xml` and
`xml/Custom_1109_TopBarOverlay.xml` use. Those are the video playback seek bar and
top bar, which movies and TV shows rely on. The PVR usages inside them are gated on
PVR-only conditions and never evaluate true.

### Trailer preview as the spotlight background

Play an item's trailer behind the spotlight card instead of the static fanart, using
`plugin.video.themoviedb.helper` (installed, 6.16.6) as the metadata source.

What TMDb Helper already gives us:

- Its service watches the container named in `Skin.String(TMDbHelper.MonitorContainer)`
  and writes `Window(Home).Property(ListItem.*)` for the focused item. This is the only
  way to react to focus changes — skin XML has no on-focus hook for containers. Gated on
  `Skin.HasSetting(TMDbHelper.Service)`.
- A `trailer` infolabel for **tvshow** items, which Kodi's own library lacks: the `tvshow`
  table has no trailer column, so `ListItem.Trailer` is always empty for series. Movies
  have it in the DB already.
- A trailer list route, trailers first:
  `plugin://plugin.video.themoviedb.helper/?info=videos&tmdb_type=<movie|tv>&tmdb_id=<id>`

Two blockers before any of it runs:

- **No resolver installed.** Every trailer URL in the library points at
  `plugin.video.youtube` or `plugin.video.tubed`; neither add-on is present. Also expect
  1-3s to resolve a YouTube URL, which may rule out autoplay-on-dwell entirely.
- **TMDb Helper only sets properties, it never starts playback.** Something still has to
  call `PlayMedia`. The spotlight is a single item with real buttons (`HomeSpotlight`,
  `xml/Includes_Home.xml`), not a list, so `<onfocus>` is usable — but XML cannot delay an
  action, so dwell-then-play needs a service add-on of our own.

The hard part is teardown, not playback: starting a trailer sets `Player.HasVideo`, which
flips `DefaultBackground` (`xml/Includes.xml`) to a fullscreen videowindow skin-wide, can
raise the video OSD, and makes back/stop ambiguous. Every window keys off that flag.

Suggested order: prove the pipeline with a manual "Preview" button on the spotlight (one
`PlayMedia` call, no timing logic) before building autoplay. Ship behind a skin setting,
default off. If YouTube latency makes it unusable, the fallback is local trailer files or
`theme.mp4` beside the media — instant and add-on free, but they have to be sourced.

### Favourites carry one image, and it cannot be looked up

A favourite stores a single `thumb` in `userdata/favourites.xml` and nothing else, so the
same image has to serve both the poster slot and the focused wide card in the favourites
row (`16500`, My Kodi). `HomeWideLayout` falls back to that thumb when `Art(fanart)` is
empty, which is always for a favourite. Whichever art was on screen when the item was
favourited is what got saved — expect a mix of posters and fanart in one row.

The art cannot be recovered from the library in skin XML. From `CFavouritesService::GetAll`:

- `SetArt("thumb", …)` is the only art key ever set; there is no fanart key.
- No database lookup happens. `GetAll` and `LoadFromFile` return the items unenriched.
- The item's path is a `favourite://` URL with the exec string encoded inside, not the
  target. `ListItem.FolderPath` gives that URL, so the one lookup a skin has — point a
  hidden container at a path and read `Container.Art(fanart)` off it, as
  `MediaFanartVar` in `xml/Variables.xml` does for `tvshow.fanart` — has nothing browsable
  to aim at. The only other properties are `favourite.action`, `favourite.provider` and
  `favourite.index`.

Fixing it properly needs **the same service add-on the trailer preview above wants**: read
`favourites.xml`, resolve each target against the library the way `script.globalsearch`
does (`VideoLibrary.GetMovies` with a filter), and write `Window(Home).Property(...)` per
favourite for the skin to read. Worth building once, for both features.

### Keyboard input on the search home

Search itself works: the **Search** entry at the top of the side list (`15100`) raises Kodi's
keyboard with `Skin.SetString(search_query)` — no value means prompt — and the grid (`15200`)
fills with library hits in place. What is missing is the design's on-screen key grid, which
belongs above the side list; the entries start at the top of that column and shift down once
the keys exist.

- **The keys.** A grid of buttons plus space and backspace. Kodi's `DialogKeyboard.xml` is a
  modal and cannot be embedded, and XML cannot append a character to a string, so each key
  needs its own `Skin.SetString(search_query,$INFO[...])` concatenation, or a small service
  add-on. The results half needs no work when they land: the keys write the same skin string
  the prompt does.
- **How the results are queried.** `$VAR[SearchGridContentVar]` (`xml/Variables.xml`) points
  the grid at `videodb://movies/titles/?xsp={…}` — an xsp filter as a URL option, the same
  filter object `script.globalsearch` hands to `VideoLibrary.GetMovies`, which Kodi converts
  into exactly this URL. A container holds one media type, so movies and series are separate
  paths: probes `15570`/`15571` count each, the side list offers only the types that matched,
  and `Window(Home).Property(search_type)` picks between them. A query and a genre are held at
  the same time — `Window(Home).Property(search_mode)` decides which of the two the grid shows,
  so browsing a genre mid-search and stepping back onto a result type loses neither. Two caveats in the query text —
  it is interpolated raw into JSON inside a URL, so a `"` breaks the filter and an `&` truncates
  it at the URL option boundary. Skin XML has no way to escape either.
