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
