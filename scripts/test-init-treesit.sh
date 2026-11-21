#!/bin/sh
# Regression test: treesit mode remapping must actually be installed.
#
# Failure it pins (2026-11-21): the treesit section used `setq' on
# `treesit-enabled-modes', bypassing the defcustom's :set function, so
# `major-mode-remap-alist' stayed empty and no mode was remapped to its
# -ts-mode version (0765-7080 in emacs-config.org).
#
# Run: cd /Users/dragon/.config/emacs && sh scripts/test-init-treesit.sh
# Exit: 0 = all assertions pass, 1 = at least one failed.

set -u

repo_dir=$(cd "$(dirname "$0")/.." && pwd)
out=$(mktemp "${TMPDIR:-/tmp}/treesit.XXXXXX")
trap 'rm -f "$out"' EXIT INT TERM

cd "$repo_dir" || exit 1

emacs -Q --batch -l early-init.el -l init.el \
      --eval '(progn
                (princ (format "AVAIL=%S\n" (treesit-available-p)))
                (princ (format "ENABLED=%S\n" treesit-enabled-modes))
                (princ (format "REMAP=%d\n" (length major-mode-remap-alist))))' \
      >"$out" 2>&1
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
    check PASS "exit code is 0 (got $status)"
else
    check FAIL "exit code is 0 (got $status)"
fi

if grep -qF 'AVAIL=t' "$out"; then
    check PASS "treesit is available"
else
    check FAIL "treesit is available (got $(grep -o 'AVAIL=.*' "$out" || echo none))"
fi

if grep -qF 'ENABLED=t' "$out"; then
    check PASS "treesit-enabled-modes is t"
else
    check FAIL "treesit-enabled-modes is t (got $(grep -o 'ENABLED=.*' "$out" || echo none))"
fi

remap=$(grep -o 'REMAP=[0-9]*' "$out" | cut -d= -f2)
remap=${remap:-0}
if [ "$remap" -ge 26 ]; then
    check PASS "major-mode-remap-alist has >= 26 entries (got $remap)"
else
    check FAIL "major-mode-remap-alist has >= 26 entries (got $remap)"
fi

# The setq variant installed nothing; a live config must not regress to it.
if grep -qF '(setq treesit-enabled-modes' \
        "$repo_dir/core/init-emacs-langs.el"; then
    check FAIL "core/init-emacs-langs.el uses setopt, not setq (found setq)"
else
    check PASS "core/init-emacs-langs.el uses setopt, not setq"
fi

if [ "$fail" -ne 0 ]; then
    printf '\n--- emacs output (%s) ---\n' "$out"
    cat "$out"
    printf '\nRESULT: FAIL\n'
    exit 1
fi

printf '\nRESULT: PASS\n'
exit 0
