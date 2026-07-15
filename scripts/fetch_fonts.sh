#!/usr/bin/env bash
set -euo pipefail

FONTS_DIR="App/Resources/Fonts"
mkdir -p "$FONTS_DIR"

# Pinned google/fonts commit (immutable): bump deliberately after verifying filenames
# still exist at the new SHA. Verified 2026-07-15: archivo, bitter, rye
# dirs all contain the exact files below at this commit.
PIN="26c5c976d82d50c24a8f0a7ac455e0a7c639c226"
RAW_BASE="https://raw.githubusercontent.com/google/fonts/$PIN"
MIRROR_BASE="https://cdn.jsdelivr.net/gh/google/fonts@$PIN"

FONT_NAMES=(
  "Archivo.ttf"
  "Bitter.ttf"
  "Bitter-Italic.ttf"
  "Rye-Regular.ttf"
)
FONT_URLS=(
  "$RAW_BASE/ofl/archivo/Archivo%5Bwdth,wght%5D.ttf"
  "$RAW_BASE/ofl/bitter/Bitter%5Bwght%5D.ttf"
  "$RAW_BASE/ofl/bitter/Bitter-Italic%5Bwght%5D.ttf"
  "$RAW_BASE/ofl/rye/Rye-Regular.ttf"
)

LICENSE_NAMES=(
  "Archivo-OFL.txt"
  "Bitter-OFL.txt"
  "Rye-OFL.txt"
)
LICENSE_URLS=(
  "$RAW_BASE/ofl/archivo/OFL.txt"
  "$RAW_BASE/ofl/bitter/OFL.txt"
  "$RAW_BASE/ofl/rye/OFL.txt"
)

MIN_FONT_BYTES=40960

download() {
  local dest="$1"
  local url="$2"
  local mirror="${MIRROR_BASE}${url#$RAW_BASE}"
  local attempt
  echo "Downloading $dest"
  for attempt in 1 2 3; do
    if curl -fsSL --connect-timeout 15 --max-time 120 --retry 4 --retry-delay 3 "$url" -o "$FONTS_DIR/$dest"; then
      return 0
    fi
    echo "Primary fetch failed for $dest (attempt $attempt), trying mirror"
    if curl -fsSL --connect-timeout 15 --max-time 120 --retry 4 --retry-delay 3 "$mirror" -o "$FONTS_DIR/$dest"; then
      return 0
    fi
    sleep $((attempt * 10))
  done
  echo "All fetch attempts failed for $dest" >&2
  return 1
}

for i in "${!FONT_NAMES[@]}"; do
  download "${FONT_NAMES[$i]}" "${FONT_URLS[$i]}"
done

for i in "${!LICENSE_NAMES[@]}"; do
  download "${LICENSE_NAMES[$i]}" "${LICENSE_URLS[$i]}"
done

echo "Verifying downloaded fonts"
for i in "${!FONT_NAMES[@]}"; do
  name="${FONT_NAMES[$i]}"
  path="$FONTS_DIR/$name"

  if [ ! -f "$path" ]; then
    echo "Missing font file: $path" >&2
    exit 1
  fi

  size=$(wc -c < "$path" | tr -d '[:space:]')
  if [ "$size" -le "$MIN_FONT_BYTES" ]; then
    echo "Font file too small (possible download failure): $path ($size bytes)" >&2
    exit 1
  fi

  file_output=$(file -b "$path")
  case "$file_output" in
    *TrueType*|*OpenType*)
      ;;
    *)
      echo "Font file failed type check: $path ($file_output)" >&2
      exit 1
      ;;
  esac

  echo "OK: $path ($size bytes, $file_output)"
done

echo "Verifying license files"
for i in "${!LICENSE_NAMES[@]}"; do
  name="${LICENSE_NAMES[$i]}"
  path="$FONTS_DIR/$name"

  if [ ! -f "$path" ]; then
    echo "Missing license file: $path" >&2
    exit 1
  fi

  size=$(wc -c < "$path" | tr -d '[:space:]')
  if [ "$size" -le 0 ]; then
    echo "License file is empty: $path" >&2
    exit 1
  fi

  echo "OK: $path ($size bytes)"
done

echo "All fonts and licenses fetched and verified"
