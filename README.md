<!-- markdownlint-disable no-inline-html -->

# Dotfiles

After cloning this repo, run `install` to automatically set up the development
environment. Note that the install script is idempotent: it can safely be run
multiple times.

For the color scheme to look right, you will also need terminal-specific
support. The configuration for that, along with a whole bunch of other
machine-specific configuration, is located in [dotfiles-local][dotfiles-local].

Dotfiles uses [Dotbot][dotbot] for installation.

## Installation

- Try recursive clone every submodule with following commands.

> git clone --recursive --remote-submodules <URL>

- To remove submodules, run followings:

```zsh
git submodule deinit -f <path_to_submodule>
git rm --cached <path_to_submodule>
rm -rf .git/modules/<path_to_submodule> # if exists.
```

## Making Local Customizations

You can make local customizations for some programs by editing these files:

- `vim` : `~/.vimrc_local`
- `emacs` : `~/.emacs_local`
- `zsh` / `bash` : `~/.shell_local_before` run first
- `zsh` : `~/.zshrc_local_before` run before `.zshrc`
- `zsh` : `~/.zshrc_local_after` run after `.zshrc`
- `zsh` / `bash` : `~/.shell_local_after` run last
- `git` : `~/.gitconfig_local`
- `hg` : `~/.hgrc_local`
- `tmux` : `~/.tmux_local.conf`

## License

Copyright (c) 2013-2021 Anish Athalye. Released under the MIT License. See
[LICENSE.md][license] for details.

[dotfiles-local]: https://github.com/kalinlau/dotfiles-local
[dotbot]: https://github.com/anishathalye/dotbot
[license]: LICENSE.md
