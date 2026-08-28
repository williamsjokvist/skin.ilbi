# Ilbi

A minimalist, streaming-service-style skin for [Kodi](https://kodi.tv), forked from Estuary.

Scope is deliberately narrow: **movies and TV shows only**.

## Screenshots

Home screen with the centred nav bar and hero spotlight:

![Home screen](resources/menu.jpg)

Poster rows, with the focused item spotlighted above the row:

![Spotlight](resources/spotlight.jpg)

## Development

Tasks are run with [mise](https://mise.jdx.dev):

```sh
mise install-fonts    # fetch fonts from Google Fonts
mise mockgen          # generate a mock Kodi library to browse
mise symlink          # symlink the skin into Kodi's addons directory
```

## License

Creative Commons Attribution Non-Commercial Share-Alike 4.0 — see [LICENSE.txt](LICENSE.txt).
