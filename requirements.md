# Requirements for Inkscape-Figure-Manager Neovim Plugin

- [ ] keybinding for **editing figure on current line**
  - pass markdown figure text (ie `![...`) to python figure manager.
    - [ ] modify python inkfigman edit to accept markdown include graphic text
  - If error occurs, print message: DNE and/or python inkfigman exit status.
- [ ] keybinding for **creating figure**
  - Open a neovim UI window for entering the alternate text for the figure.
    Pressing `Enter` confirms creation (launching python inkfigman create).
    Pressing `Esc` cancels creation (does nothing).
- [ ] on markdown file open, start **watching figures**:
  - Watch directory of markdown file, and all figures included within it

## Future Features

- [ ] keybinding for **editing figure within buffer's git repo**
- [ ] keybinding for **editing figure from those in buffer**
- [ ] Modify python inkfigman so that this plugin can provide the picker (eg Telescope)
