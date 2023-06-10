# Inkscape Figure Manager | A Neovim Plugin

Manage images/figures within a markdown document from neovim. As neovim chads,
we should have fast workflows that are as featureful as the plebian WYSISWG
editors. This plugin pairs Inkscape, a FOSS svg editor, with neovim.

## Features

- [ ] watch figures
- [x] create figure
- [x] edit figure
- [ ] rename figure

## FAQ

- What does it mean to  "watch" figures?
  - A daemon "watcher" is spawned which has a list of directories to watch.
    Whenever a svg file within one of the watched directories is written to,
    the svg file is exported with Inkscape as a png.
- How do I speed up Inkscape startup time?
  - See this
    [reddit](https://www.reddit.com/r/lua/comments/2vwkq5/structuring_my_lua_code/)
    solution.
