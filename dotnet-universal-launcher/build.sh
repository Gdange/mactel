#!/bin/bash
# Build a universal (x86_64 + arm64) macOS launcher for a .NET app.
#
# A .NET console app is dll + a native "apphost" launcher. The apphost is arch-specific, so a
# build made for one architecture starts with "Bad CPU type in executable" on the other. This
# script builds the same project for both RIDs and joins the two apphosts with lipo.
#
# Usage: build.sh <project dir or .csproj> [output path]
#   output defaults to <project dir>/bin/universal/<app name>
# Needs: dotnet SDK 8+, Xcode command line tools (lipo).
set -euo pipefail

die() { echo "FAIL: $*" >&2; exit 1; }
[ $# -ge 1 ] || die "usage: $0 <project dir or .csproj> [output path]"

PROJ=$1
[ -d "$PROJ" ] && PROJ=$(cd "$PROJ" && ls -1 *.csproj 2>/dev/null | head -1 | sed "s|^|$PWD/|")
[ -f "$PROJ" ] || die "no .csproj at $1 (pass the directory or the file)"
NAME=$(basename "$PROJ" .csproj)
DIR=$(dirname "$PROJ")
OUT=${2:-"$DIR/bin/universal/$NAME"}

command -v dotnet >/dev/null || die "dotnet not found"
command -v lipo >/dev/null || die "lipo not found (install Xcode command line tools)"

TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
for rid in osx-x64 osx-arm64; do
  dotnet build "$PROJ" -c Release -r "$rid" -o "$TMP/$rid" >"$TMP/$rid.log" 2>&1 \
    || { tail -5 "$TMP/$rid.log" >&2; die "dotnet build -r $rid failed"; }
done

# The apphost is the Mach-O executable the build wrote beside the dll (dylibs are not executables).
x=$(file "$TMP/osx-x64/$NAME" 2>/dev/null | grep -c 'Mach-O.*executable' || true)
a=$(file "$TMP/osx-arm64/$NAME" 2>/dev/null | grep -c 'Mach-O.*executable' || true)
[ "$x" = 1 ] && [ "$a" = 1 ] || die "no apphost named $NAME in the build output (self-contained publish instead?)"

mkdir -p "$(dirname "$OUT")"
lipo -create "$TMP/osx-x64/$NAME" "$TMP/osx-arm64/$NAME" -output "$OUT"
chmod +x "$OUT"
echo "ok: $OUT ($(lipo -archs "$OUT"))"
echo "note: the apphost looks for $NAME.dll next to itself, so keep it beside the dll (or publish self-contained)."
