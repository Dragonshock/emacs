# Emacs configuration

Single source of truth: [`emacs-config.org`](emacs-config.org). `early-init.el`,
`init.el` and everything under `core/` are tangled from it — do not edit the
generated files.

## System dependencies

The configuration starts without any optional tool: modules that need a missing
program skip themselves instead of failing. Install what you actually use.

### Required

| Tool | Why |
|---|---|
| Emacs 31.1+ | the config uses 31-only APIs; a native-compilation build is expected |
| git | straight.el clones all packages |
| `make` + a C compiler (`cc`) | native compilation, emureader's `:pre-build` |
| `libgccjit` | native compilation (bundled by Nix/Homebrew builds) |
| network access on first start | straight installs ~150 packages |

### Recommended

| Tool | Used by |
|---|---|
| `ripgrep` (`rg`) | consult-ripgrep, agent-recall |
| `fd` | consult-fd |
| `gh` | ghub/forge GitHub tokens |
| `sqlite3` + `xxd` + `iconv` | reading Magpie's model picker |
| `coreutils` (`gls` on macOS) | dired's long listing on macOS |
| `zstd` | archive handling |
| `aspell` | ispell/flyspell |
| `fish` | exec-path-from-shell (falls back to `$SHELL`, then `shell-file-name`) |

### Optional, by feature

- Mail: `mu`, `msmtp`, `mbsync` (mu4e)
- Passwords: `pass`, `gpg` (password-store)
- Writing: `typst`, a TeX distribution (`latex`), `mermaid-cli` (`mmdc`)
- Languages: `rust-analyzer`, `jdtls`, `clangd`, `pyright` (eglot); `ctags` (citre); `python3` + `jupyter`
- Terminal: `ghostty` (ghostel), plus `zig`/`make` if the module must be built
- Telegram: `cmake` + TDLib (telega)
- Git extras: `difftastic` (magit-difftastic)
- Fonts: LXGW WenKai (CJK), MonoLisa (ligatures)

Missing helper scripts (`scripts/hn-elfeed.py`, `scripts/install-telega-tdlib`,
`scripts/update-elfeed-feeds`) only disable the related commands; they are not
required for startup.

### Quick install

macOS (Homebrew). Homebrew's `emacs` may lag behind 31.1; prefer
[emacs-plus](https://github.com/d12frosted/homebrew-emacs-plus) or Nix:

```sh
brew install git ripgrep fd gh sqlite3 coreutils zstd aspell vim \
             mu isync msmtp pass gnupg typst python3
```

Nix:

```sh
nix profile install nixpkgs#emacs nixpkgs#git nixpkgs#ripgrep nixpkgs#fd \
  nixpkgs#gh nixpkgs#sqlite nixpkgs#coreutils nixpkgs#zstd nixpkgs#aspell \
  nixpkgs#mu nixpkgs#isync nixpkgs#msmtp nixpkgs#pass nixpkgs#gnupg \
  nixpkgs#typst nixpkgs#python3
```

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
