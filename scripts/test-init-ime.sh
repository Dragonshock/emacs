#!/bin/sh
# Test: the Rime input-method stack must be ported into init-emacs-ime.
#
# Failure it pins (2026-11-21): the new config dropped the whole old
# init-ime.el module.  init-emacs-core sets `(setq-default
# default-input-method nil)', s-SPC is bound to `toggle-input-method' with
# no registered method behind it, and sis/liberime/liberime-regexp/rimel
# are absent from the package list.
#
# Run: cd /Users/dragon/.config/emacs && sh scripts/test-init-ime.sh
# Exit: 0 = all assertions pass, 1 = at least one failed.

set -u

repo_dir=$(cd "$(dirname "$0")/.." && pwd)
out=$(mktemp "${TMPDIR:-/tmp}/init-ime.XXXXXX")
trap 'rm -f "$out"' EXIT INT TERM

cd "$repo_dir" || exit 1

# Dynamic assertions: load the real config in batch, then probe the IM state.
# The ime module loads its packages via `:require-incrementally' (once's
# idle-timer mechanism), which by design never fires under `--batch' —
# so the probe requires them explicitly first: the batch equivalent of
# what the idle timer does in an interactive session.  A failed require
# aborts with exit != 0 and shows up in the emacs-exits-0 check.
# IM=    t when `default-input-method' is non-nil (ime module sets "rimel")
# REG=   the `(assoc "rimel" input-method-alist)' entry, or nil
# PKGS=  t when liberime, rimel and sis features are all loaded
emacs -Q --batch -l early-init.el -l init.el \
      --eval "(require 'liberime)" \
      --eval "(require 'rimel)" \
      --eval "(require 'sis)" \
      --eval "(require 'liberime-regexp)" \
      --eval '(princ (format "IM=%S\n" (if default-input-method t)))' \
      --eval '(princ (format "REG=%S\n" (assoc "rimel" input-method-alist)))' \
      --eval "(princ (format \"PKGS=%S\\n\"
                           (if (and (featurep 'liberime)
                                    (featurep 'rimel)
                                    (featurep 'sis))
                               t)))" >"$out" 2>&1
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

if grep -q '^IM=t$' "$out"; then
    check PASS "IM=t, default-input-method is non-nil"
else
    check FAIL "IM=t, default-input-method is non-nil (got: $(grep -o '^IM=.*' "$out" || echo 'no IM line'))"
fi

if grep -q '^REG=("rimel" "Chinese" rimel-activate' "$out"; then
    check PASS "REG hits (rimel), register-input-method ran"
else
    check FAIL "REG hits (rimel), register-input-method ran (got: $(grep -o '^REG=.*' "$out" || echo 'no REG line'))"
fi

if grep -q '^PKGS=t$' "$out"; then
    check PASS "PKGS=t, liberime+rimel+sis all loaded"
else
    check FAIL "PKGS=t, liberime+rimel+sis all loaded (got: $(grep -o '^PKGS=.*' "$out" || echo 'no PKGS line'))"
fi

# Static assertions on emacs-config.org.
org="$repo_dir/emacs-config.org"

if grep -q '^ \{0,2\}\*\* The =init-emacs-ime.el= module$' "$org"; then
    check PASS "org has 'The =init-emacs-ime.el= module' heading"
else
    check FAIL "org has 'The =init-emacs-ime.el= module' heading"
fi

if grep -qF "(require 'init-emacs-ime)" "$org"; then
    check PASS "init.el tangle block contains (require 'init-emacs-ime)"
else
    check FAIL "init.el tangle block contains (require 'init-emacs-ime)"
fi

# Load order: ime right after core, before edit (line numbers within the org).
ime_line=$(grep -nF "(require 'init-emacs-ime)" "$org" | head -n1 | cut -d: -f1)
core_line=$(grep -nF "(require 'init-emacs-core)" "$org" | head -n1 | cut -d: -f1)
edit_line=$(grep -nF "(require 'init-emacs-edit)" "$org" | head -n1 | cut -d: -f1)
if [ -n "$ime_line" ] && [ -n "$core_line" ] && [ -n "$edit_line" ] \
   && [ "$core_line" -lt "$ime_line" ] && [ "$ime_line" -lt "$edit_line" ]; then
    check PASS "load order: ime after core ($core_line), before edit ($edit_line), at $ime_line"
else
    check FAIL "load order: ime after core, before edit (core=$core_line ime=${ime_line:-none} edit=$edit_line)"
fi

# Ownership handoff: the core global-defaults nil assignment must be gone.
# The ime section is where `default-input-method' gets set to "rimel".
nil_count=$(grep -cF '(setq-default default-input-method nil)' "$org")
if [ "$nil_count" -eq 0 ]; then
    check PASS "org no longer sets (setq-default default-input-method nil)"
else
    check FAIL "org no longer sets (setq-default default-input-method nil) ($nil_count occurrence(s) left)"
fi

if [ "$fail" -ne 0 ]; then
    printf '\n--- emacs output (%s) ---\n' "$out"
    cat "$out"
    printf '\nRESULT: FAIL\n'
    exit 1
fi

printf '\nRESULT: PASS\n'
exit 0
