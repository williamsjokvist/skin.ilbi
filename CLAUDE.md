# Ilbi

A Kodi skin, forked from Estuary. Scope is deliberately narrow: **movies and TV shows only**.
Music, PVR/live TV, games, pictures and weather have been removed from the skin.

## Style

Comments are a code smell. Code should be readable and self-explanatory. Name controls,
includes and variables so their purpose is obvious and let the structure of the XML carry the
rest; if a piece of code seems to need explaining, rename or restructure it instead of
annotating it.

Saying *why* something is built the way it is, is worth it - a constraint in Kodi that forced
the shape, a non-obvious reason a value is what it is. Saying *what* the code does is not.

Put it in a `<description>`, which is part of the control spec, and keep it to a line or two.
Where there is no control to hang one on - expressions, variables, animation includes - a
short `<!-- -->` is the only place one belongs.

Comments already in the tree predate this; leave them alone unless you are changing the code
they sit on.

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
