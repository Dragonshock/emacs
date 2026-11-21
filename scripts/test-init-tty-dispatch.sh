#!/bin/sh
# Test: tty-only extras (kkp, kitty-graphics) must be enabled by ONE
# TERM-dispatching function, +tty-setup-features, instead of being hung
# unconditionally on tty-setup.
#
# Failure it pins (2026-11-21): research
# dev-docs/notes/ghostty-tty-performance-research-2026-11-21.md (sections
# 三/六/七) found that `global-kkp-mode' and `kitty-graphics-setup' run in
# EVERY terminal frame.  On xterm-ghostty, kitty-graphics probes a Kitty
# graphics protocol SUBSET that diverges from upstream kitty and, with
# `kitty-graphics-enable-video t', streams per-frame redraws -> escape
# storms / tearing (H1, first suspect).  Emacs 31.1 has no Synchronized
# Output (H4), so tearing can only be mitigated by not streaming graphics
# in the first place.  Decision (section 七.A2): a single dispatcher
# whitelists TERM values --
#   xterm-kitty   -> kkp on, kitty-graphics-setup on   (current behavior)
#   xterm-ghostty -> kkp on, kitty-graphics OFF entirely
#   other          -> per package self-detection study
# -- while xterm-mouse-mode and the tty coding/warp-glyph setup stay
# unconditional.
#
# Runtime note: `tty-setup' never runs under `--batch' (no terminal frame
# is initialized), so the mode states cannot be observed; instead this
# test asserts (a) batch init still completes with TERM=xterm-ghostty in
# the environment (regression guard), and (b) the dispatcher is defined
# and IS the only new tenant on `tty-setup-hook', with the two old
# unconditional tenants gone and the keepers intact.
#
# Run: cd /Users/dragon/.config/emacs && sh scripts/test-init-tty-dispatch.sh
# Exit: 0 = all assertions pass, 1 = at least one failed.

set -u

repo_dir=$(cd "$(dirname "$0")/.." && pwd)
out=$(mktemp "${TMPDIR:-/tmp}/tty-dispatch.XXXXXX")
block=$(mktemp "${TMPDIR:-/tmp}/tty-dispatch-block.XXXXXX")
ghostty=$(mktemp "${TMPDIR:-/tmp}/tty-dispatch-ghostty.XXXXXX")
trap 'rm -f "$out" "$block" "$ghostty"' EXIT INT TERM

cd "$repo_dir" || exit 1

org="$repo_dir/emacs-config.org"

fail=0
check() { # check <PASS|FAIL> <description>
    if [ "$1" = PASS ]; then
        printf 'PASS  %s\n' "$2"
    else
        printf 'FAIL  %s\n' "$2"
        fail=1
    fi
}

# --- static: the dispatcher exists in the org source ---------------------

for needle in '(defun +tty-setup-features' '(tty-setup . +tty-setup-features)'; do
    if grep -qF -- "$needle" "$org"; then
        check PASS "org wires tty-setup to the dispatcher ($needle)"
    else
        check FAIL "org wires tty-setup to the dispatcher ($needle)"
    fi
done

# --- static: the dispatch body knows both TERMs -------------------------
# Extract the dispatcher's source block: from the defun line to the next
# "#+end_src".  Empty when the dispatcher is absent (so the baseline fails).
awk '
    /\(defun \+tty-setup-features/ { flag = 1 }
    flag && /^#\+end_src/           { print; exit }
    flag                            { print }
' "$org" >"$block"

for term in xterm-kitty xterm-ghostty; do
    if grep -qF "$term" "$block"; then
        check PASS "dispatcher dispatches on TERM=$term"
    else
        check FAIL "dispatcher dispatches on TERM=$term"
    fi
done

# --- static: the ghostty branch must not enable kitty-graphics ----------
# Scope A2: on xterm-ghostty kitty-graphics is OFF entirely (the protocol
# subset diverges and video streaming causes redraw storms; research H1),
# not merely video.  Extract the ghostty case: from the line mentioning
# xterm-ghostty up to (not including) the pcase wildcard line (a "(" or
# whitespace followed by "_").
awk '
    /xterm-ghostty/ { flag = 1 }
    flag && /(^|[[:space:](])_/ { exit }
    flag { print }
' "$block" >"$ghostty"

if [ -s "$ghostty" ]; then
    if grep -qE 'kitty-graphics' "$ghostty"; then
        check FAIL "ghostty branch does NOT enable kitty-graphics (H1)"
    else
        check PASS "ghostty branch does NOT enable kitty-graphics (H1)"
    fi
else
    check FAIL "ghostty branch is present in the dispatcher"
fi

# --- static: the old unconditional :hook wiring is GONE -------------------
# The use-package forms stay (recipes + :init variables); only the way the
# modes get enabled changes.  Check both the org source and the tangled
# core files, since regenerating is part of the fix.
for target in "$org" "$repo_dir/core/init-emacs-core.el" "$repo_dir/core/init-emacs-ui.el"; do
    if grep -qF -- ':hook (tty-setup . global-kkp-mode)' "$target"; then
        check FAIL "unconditional tty-setup kkp wiring gone ($target)"
    else
        check PASS "unconditional tty-setup kkp wiring gone ($target)"
    fi
    if grep -qF -- ':hook (tty-setup . kitty-graphics-setup)' "$target"; then
        check FAIL "unconditional tty-setup kitty-graphics wiring gone ($target)"
    else
        check PASS "unconditional tty-setup kitty-graphics wiring gone ($target)"
    fi
done

# --- static: the unconditional tty setups stay unconditional ------------
if grep -qF -- ':hook (tty-setup . xterm-mouse-mode)' "$org"; then
    check PASS "xterm-mouse-mode stays on tty-setup unconditionally"
else
    check FAIL "xterm-mouse-mode stays on tty-setup unconditionally"
fi
if grep -qF -- '(defun +setup-tty-coding-system' "$org"; then
    check PASS "tty coding-system setup stays unconditional"
else
    check FAIL "tty coding-system setup stays unconditional"
fi
if grep -qF -- "(make-glyph-code ?↩ 'shadow)" "$org"; then
    check PASS "tty wrap/truncation glyphs stay out of the dispatcher"
else
    check FAIL "tty wrap/truncation glyphs stay out of the dispatcher"
fi

# --- runtime: batch init survives TERM=xterm-ghostty ---------------------
# tty-setup never fires under --batch; assert that loading the whole config
# still completes (regression guard) and that the hook carries the
# dispatcher instead of the old tenants:
#   EXIT0        1 when emacs exited 0
#   DISPATCHER   1 when (fboundp '+tty-setup-features)
#   ONHOOK       1 when (memq '+tty-setup-features tty-setup-hook)
#   KKPONHOOK    1 when global-kkp-mode is still a direct hook tenant (bad)
#   KGONHOOK     1 when kitty-graphics-setup is still a direct tenant (bad)
#   MOUSEONHOOK  1 when xterm-mouse-mode is still hooked (good)
#   CODINGONHOOK 1 when +setup-tty-coding-system is still hooked (good)
TERM=xterm-ghostty emacs -Q --batch -l early-init.el -l init.el \
      --eval '(princ (format "DISPATCHER=%S\n" (if (fboundp (quote +tty-setup-features)) 1 0)))' \
      --eval '(princ (format "ONHOOK=%S\n" (if (memq (quote +tty-setup-features) tty-setup-hook) 1 0)))' \
      --eval '(princ (format "KKPONHOOK=%S\n" (if (memq (quote global-kkp-mode) tty-setup-hook) 1 0)))' \
      --eval '(princ (format "KGONHOOK=%S\n" (if (memq (quote kitty-graphics-setup) tty-setup-hook) 1 0)))' \
      --eval '(princ (format "MOUSEONHOOK=%S\n" (if (memq (quote xterm-mouse-mode) tty-setup-hook) 1 0)))' \
      --eval '(princ (format "CODINGONHOOK=%S\n" (if (memq (quote +setup-tty-coding-system) tty-setup-hook) 1 0)))' \
      --eval '(princ "HOOKLINE\n")' \
      --eval '(princ (format "HOOK=%S\n" tty-setup-hook))' \
      >"$out" 2>&1
status=$?

if [ "$status" -eq 0 ]; then
    check PASS "batch init completes with TERM=xterm-ghostty (exit $status)"
else
    check FAIL "batch init completes with TERM=xterm-ghostty (exit $status)"
fi

if grep -q '^DISPATCHER=1' "$out"; then
    check PASS "dispatcher is defined at runtime (+tty-setup-features)"
else
    check FAIL "dispatcher is defined at runtime (+tty-setup-features)"
fi

if grep -q '^ONHOOK=1' "$out"; then
    check PASS "+tty-setup-features sits on tty-setup-hook"
else
    check FAIL "+tty-setup-features sits on tty-setup-hook"
fi

if grep -q '^KKPONHOOK=1' "$out"; then
    check FAIL "global-kkp-mode is no longer a direct tty-setup tenant"
else
    check PASS "global-kkp-mode is no longer a direct tty-setup tenant"
fi

if grep -q '^KGONHOOK=1' "$out"; then
    check FAIL "kitty-graphics-setup is no longer a direct tty-setup tenant"
else
    check PASS "kitty-graphics-setup is no longer a direct tty-setup tenant"
fi

if grep -q '^MOUSEONHOOK=1' "$out"; then
    check PASS "xterm-mouse-mode still on tty-setup (unconditional, as scoped)"
else
    check FAIL "xterm-mouse-mode still on tty-setup (unconditional, as scoped)"
fi

if grep -q '^CODINGONHOOK=1' "$out"; then
    check PASS "+setup-tty-coding-system still on tty-setup (unconditional)"
else
    check FAIL "+setup-tty-coding-system still on tty-setup (unconditional)"
fi

if [ "$fail" -ne 0 ]; then
    printf '\n--- emacs output (%s) ---\n' "$out"
    cat "$out"
    printf '\n--- dispatcher block extracted from org (%s) ---\n' "$block"
    cat "$block" 2>/dev/null
    printf '\nRESULT: FAIL\n'
    exit 1
fi

printf '\nRESULT: PASS\n'
exit 0
