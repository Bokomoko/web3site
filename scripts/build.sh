#!/usr/bin/env bash
#
# build.sh — assemble the publishable static bundle into ./dist
#
# No framework, no bundler: this is a static site, so "building" means
# copying the source assets into a clean dist/ directory ready to pin.
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST="${ROOT}/dist"

echo "[build] root: ${ROOT}"
echo "[build] cleaning ${DIST}"
rm -rf "${DIST}"
mkdir -p "${DIST}"

echo "[build] copying static assets"
cp "${ROOT}/index.html" "${DIST}/index.html"
cp -r "${ROOT}/pages" "${DIST}/pages"
cp -r "${ROOT}/assets" "${DIST}/assets"
cp -r "${ROOT}/content" "${DIST}/content"

echo "[build] verifying output"
test -f "${DIST}/index.html" || { echo "[build] ERROR: index.html missing in dist"; exit 1; }

echo "[build] done. Bundle ready at: ${DIST}"
find "${DIST}" -type f | sed "s#${DIST}/#  #"
