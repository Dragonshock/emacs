# Emacs configuration

Single source of truth: [`emacs-config.org`](emacs-config.org). `early-init.el`,
`init.el` and everything under `core/` are tangled from it — do not edit the
generated files.

## Requirements

- Emacs 31.1 or newer (native compilation expected)
- git, plus network access on the first start (straight clones the packages)

## Install

1. Place the repository at `~/.config/emacs` (or anywhere and start Emacs with
   `--init-directory`).
2. Tangle once:

   ```sh
   cd ~/.config/emacs
   emacs -Q --batch --eval '(progn (require (quote ob-tangle)) \
     (setq org-confirm-babel-evaluate nil) \
     (org-babel-tangle-file "emacs-config.org"))'
   ```

3. Start Emacs. straight installs and compiles the packages on first launch.
4. Optional: create `private.el` with your identity settings (mail addresses).
   The modules that use it degrade gracefully when it is missing.

## Verify

```sh
sh scripts/test-init-load.sh
```

Loads the whole configuration in batch mode and asserts the theme and a few
key settings.

## Layout

```
emacs-config.org   source of truth (prose + code)
early-init.el      generated: startup tuning
init.el            generated: module loader
core/              generated: 23 configuration modules
scripts/           regression tests
etc/               local static snippets (gitignored)
var/               runtime data (gitignored)
straight/          packages (gitignored, rebuildable)
```

## Editing

Edit `emacs-config.org`, then `C-c C-v C-t` (`org-babel-tangle`), then restart
Emacs. A prose-only change must leave `git diff core/` empty.
