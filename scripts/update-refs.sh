#!/usr/bin/env bash
# Sync the reference Emacs configurations under dev-docs/refs/code/.
#
# Each repo is a shallow (--depth 1) clone named <owner>--<repo>.
# Existing clones are fetched and hard-reset to the remote head, so a
# force-push upstream does not leave a broken tree behind.
#
# Usage: scripts/update-refs.sh [--dry-run]
# Writes dev-docs/refs/code/MANIFEST.tsv with the commit each clone sits on.

set -uo pipefail

DRY_RUN=0
[ "${1:-}" = "--dry-run" ] && DRY_RUN=1

ROOT=$(cd "$(dirname "$0")/.." && pwd)
DEST="$ROOT/dev-docs/refs/code"
MANIFEST="$DEST/MANIFEST.tsv"

REPOS=(
  roife/.emacs.d
  d12frosted/environment
  LuciusChen/.emacs.d
  a13/emacs.d
  DogLooksGood/dogEmacs
  rememberYou/.emacs.d
  casouri/lunarymacs
  kaushalmodi/.emacs.d
  seagle0128/.emacs.d
  jcs-emacs/jcs-emacs
  ztlevi/doom-config
  iynaix/dotfiles
  jmccarrell/literate-emacs.d
  protesilaos/dotfiles
  dezzw/.emacs.d
  reynard93/emacs-life
  dingtele/lightly-cus-emacs
  SqrtMinusOne/dotfiles
)

mkdir -p "$DEST"
printf 'repo\tdir\tcommit\tcommit_date\tsynced_at\tstatus\n' > "$MANIFEST.tmp"

for spec in "${REPOS[@]}"; do
  owner=${spec%%/*}
  repo=${spec#*/}
  name="$owner--${repo#.}"
  dir="$DEST/$name"

  if [ "$DRY_RUN" -eq 1 ]; then
    printf 'would-sync\t%s\n' "$spec"
    continue
  fi

  if [ -d "$dir/.git" ]; then
    before=$(git -C "$dir" rev-parse HEAD 2>/dev/null || echo '-')
    if ! git -C "$dir" fetch --depth 1 --quiet origin 2>/dev/null; then
      status="FETCH-FAILED"
    elif ! git -C "$dir" reset --hard --quiet FETCH_HEAD 2>/dev/null; then
      status="RESET-FAILED"
    else
      after=$(git -C "$dir" rev-parse HEAD 2>/dev/null || echo '-')
      [ "$before" = "$after" ] && status=unchanged || status=updated
    fi
  else
    if git clone --depth 1 --single-branch --quiet \
         --recurse-submodules --shallow-submodules \
         "https://github.com/$spec.git" "$dir" 2>/dev/null; then
      status=cloned
    elif git clone --depth 1 --single-branch --quiet \
           "https://github.com/$spec.git" "$dir" 2>/dev/null; then
      status="cloned(no-submodules)"
    else
      status=CLONE-FAILED
    fi
  fi

  commit=$(git -C "$dir" rev-parse --short=12 HEAD 2>/dev/null || echo '-')
  cdate=$(git -C "$dir" log -1 --format='%cs' 2>/dev/null || echo '-')
  printf '%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$spec" "refs/code/$name" "$commit" "$cdate" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$status" \
    >> "$MANIFEST.tmp"
  printf '%-22s %s (%s)\n' "$status" "$spec" "$cdate"
done

if [ "$DRY_RUN" -eq 0 ]; then
  mv "$MANIFEST.tmp" "$MANIFEST"
  echo
  echo "manifest: $MANIFEST"
else
  rm -f "$MANIFEST.tmp"
fi
