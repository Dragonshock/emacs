#!/bin/sh
# Test: ibuffer + ibuffer-project must be ported INTO init-emacs-window
# (buffer list management lives in the window module, prot precedent;
# NO standalone init-emacs-ibuffer module is created).
#
# Failure it pins (2026-11-21): the config rewired the window module but
# the old active backup core/init-ibuffer.el (94 lines) was dropped
# entirely.  C-x C-b falls back to the built-in list-buffers: a flat
# buffer list with no filter groups, so group-at-a-time delete (put point
# on the [Elfeed] group name, press d, then x) is gone.
#
# Run: cd ~/.config/emacs && sh scripts/test-init-ibuffer.sh
# Exit: 0 = all assertions pass, 1 = at least one failed.

set -u

repo_dir=$(cd "$(dirname "$0")/.." && pwd)
out=$(mktemp "${TMPDIR:-/tmp}/init-ibuffer.XXXXXX")
trap 'rm -f "$out"' EXIT INT TERM

cd "$repo_dir" || exit 1

# Runtime assertions: load the real config in batch, then probe the
# C-x C-b binding and the ibuffer-project feature.  `use-package
# ibuffer-project :straight t' is hook-deferred (it only loads when an
# Ibuffer buffer opens, which never happens under `--batch'), so the
# probe requires it explicitly: the batch equivalent of what the
# `ibuffer-mode-hook' does interactively.
# KEY=   what C-x C-b runs (ibuffer after the port, list-buffers now)
# FEAT=  t when ibuffer-project is loaded
# Note: (key-binding "C-x C-b") does not resolve key notation; the probe
# needs (kbd "C-x C-b").
emacs -Q --batch -l early-init.el -l init.el \
      --eval "(require 'ibuffer-project nil t)" \
      --eval '(princ (format "KEY=%S\n" (key-binding (kbd "C-x C-b"))))' \
      --eval '(princ (format "FEAT=%S\n" (if (featurep (quote ibuffer-project)) t)))' >"$out" 2>&1
status=$?

fail=0
check() { # check <PASS|FAIL> <description>
    if [ "$1" = PASS ]; then
        printf 'PASS  %s\n' "$2"
    else
        printf 'FAIL  %s\n' "$2"
        fail=1
    fi
}

if [ "$status" -eq 0 ]; then
    check PASS "emacs exits 0 (got $status)"
else
    check FAIL "emacs exits 0 (got $status)"
fi

if grep -aq '^KEY=ibuffer$' "$out"; then
    check PASS "KEY=ibuffer, C-x C-b is bound to ibuffer"
else
    check FAIL "KEY=ibuffer, C-x C-b is bound to ibuffer (got: $(grep -ao '^KEY=.*' "$out" || echo 'no KEY line'))"
fi

if grep -aq '^FEAT=t$' "$out"; then
    check PASS "FEAT=t, ibuffer-project feature loads"
else
    check FAIL "FEAT=t, ibuffer-project feature loads (got: $(grep -ao '^FEAT=.*' "$out" || echo 'no FEAT line'))"
fi

# Static assertions on emacs-config.org: the two new subsections live in
# the init-emacs-window module, between the last existing window package
# section (~zoom~) and the provide section.  They must NOT become a new
# module, so the org must contain no init-emacs-ibuffer reference at all
# and init.el must not gain a new require.
org="$repo_dir/emacs-config.org"

win_start=$(grep -n '^\*\* The =init-emacs-window\.el= module$' "$org" | head -n1 | cut -d: -f1)
if [ -n "$win_start" ]; then
    check PASS "org has the init-emacs-window module heading (line $win_start)"
else
    check FAIL "org has the init-emacs-window module heading"
fi # win_start empty also fails the placement checks below

# End of the window module = the next top-level (**) heading, exclusive.
win_end=$(awk -v s="$win_start" 'NR > s && /^\*\* /{print NR; exit}' "$org")
[ -n "$win_end" ] || win_end=999999999

find_in_window() { # find_in_window <literal line>
    awk -v s="$win_start" -v e="$win_end" -v line="$1" \
        'NR > s && NR < e && $0 == line {print NR}' "$org" | head -n1
}

zoom_line=$(find_in_window '*** The =init-emacs-window.el= section for ~zoom~')
ibuf_line=$(find_in_window '*** The =init-emacs-window.el= section for ~ibuffer~')
proj_line=$(find_in_window '*** The =init-emacs-window.el= section for ~ibuffer-project~')
prov_line=$(find_in_window '*** The =init-emacs-window.el= section to provide the feature')

if [ -n "$ibuf_line" ]; then
    check PASS "window module has 'section for ~ibuffer~' heading (line $ibuf_line)"
else
    check FAIL "window module has 'section for ~ibuffer~' heading"
fi

if [ -n "$proj_line" ]; then
    check PASS "window module has 'section for ~ibuffer-project~' heading (line $proj_line)"
else
    check FAIL "window module has 'section for ~ibuffer-project~' heading"
fi

# Placement: ibuffer subsections go at the END of the window module,
# after the existing sections, right before the provide section.
if [ -n "$ibuf_line" ] && [ -n "$proj_line" ] && [ -n "$prov_line" ] \
   && [ "$zoom_line" -lt "$ibuf_line" ] \
   && [ "$ibuf_line" -lt "$proj_line" ] \
   && [ "$proj_line" -lt "$prov_line" ]; then
    check PASS "placement: zoom($zoom_line) < ibuffer($ibuf_line) < ibuffer-project($proj_line) < provide($prov_line)"
else
    check FAIL "placement: after zoom, before provide (zoom=$zoom_line ibuffer=${ibuf_line:-none} ibuffer-project=${proj_line:-none} provide=$prov_line)"
fi

# No new module: the org must nowhere mention init-emacs-ibuffer, and the
# init.el tangle block gains no new require (it still requires exactly
# the 24 init-emacs-* modules it has before this change).
ibuf_refs=$(grep -c 'init-emacs-ibuffer' "$org")
if [ "$ibuf_refs" -eq 0 ]; then
    check PASS "org never mentions init-emacs-ibuffer (no new module)"
else
    check FAIL "org never mentions init-emacs-ibuffer ($ibuf_refs occurrence(s))"
fi

require_count=$(grep -c "(require 'init-emacs-" "$org")
if [ "$require_count" -eq 24 ]; then
    check PASS "init.el tangle block has no new require (${require_count} init-emacs-* requires)"
else
    check FAIL "init.el tangle block has no new require (expected 24 requires, got $require_count)"
fi

if [ "$fail" -ne 0 ]; then
    printf '\n--- emacs output (%s) ---\n' "$out"
    cat "$out"
    printf '\nRESULT: FAIL\n'
    exit 1
fi

printf '\nRESULT: PASS\n'
exit 0
