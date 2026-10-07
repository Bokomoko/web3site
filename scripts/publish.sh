#!/usr/bin/env bash
#
# publish.sh — pin the built bundle to the torrent cloud (IPFS / BTFS).
#
# Usage:
#   ./scripts/publish.sh [dist_dir]
#
# Pinning method, in order of preference:
#   1. IPFS HTTP API  — set IPFS_API (e.g. http://127.0.0.1:5001).
#                       Used by CI on the bokomint self-hosted runner, which
#                       talks to the local Kubo (Podman) node over loopback.
#   2. ipfs CLI       — if an `ipfs` binary is on PATH.
#   3. btfs CLI       — BitTorrent File System (torrent cloud), if present.
#
# Output: prints a line "CID=<cid>" that automation can parse, plus the
# follow-up steps to point the friendly URL (ENS/DNSLink) at that CID.
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST="${1:-${ROOT}/dist}"
IPFS_API="${IPFS_API:-}"

if [ ! -d "${DIST}" ]; then
  echo "[publish] ERROR: bundle dir not found: ${DIST}"
  echo "[publish] run ./scripts/build.sh first"
  exit 1
fi

CID=""
METHOD=""

# --- 1. IPFS HTTP API (preferred: local node on the runner) ------------------
if [ -n "${IPFS_API}" ]; then
  echo "[publish] adding ${DIST} via IPFS HTTP API at ${IPFS_API}"
  # Recursive add of the directory, pinned, wrap in a dir so the site keeps
  # its paths. -Q-equivalent: take the last (root) hash from the add output.
  RESP="$(curl -sf -m 120 -X POST \
    "${IPFS_API}/api/v0/add?recursive=true&wrap-with-directory=true&pin=true&cid-version=1&quieter=true" \
    $(find "${DIST}" -type f -printf "-F file=@%p;filename=%P ") )"
  # The API streams one JSON object per added entry; the wrapping dir is last.
  CID="$(printf '%s\n' "${RESP}" | tail -1 | sed -n 's/.*"Hash":"\([^"]*\)".*/\1/p')"
  METHOD="ipfs-api"
fi

# --- 2. ipfs CLI -------------------------------------------------------------
if [ -z "${CID}" ] && command -v ipfs >/dev/null 2>&1; then
  echo "[publish] adding ${DIST} via ipfs CLI"
  CID="$(ipfs add -r -Q --cid-version=1 "${DIST}")"
  METHOD="ipfs-cli"
fi

# --- 3. btfs CLI (torrent cloud) ---------------------------------------------
if [ -z "${CID}" ] && command -v btfs >/dev/null 2>&1; then
  echo "[publish] adding ${DIST} via btfs CLI (torrent cloud)"
  CID="$(btfs add -r -Q "${DIST}")"
  METHOD="btfs-cli"
fi

if [ -z "${CID}" ]; then
  echo "[publish] ERROR: no pin method available."
  echo "[publish]   set IPFS_API, or install the ipfs or btfs CLI."
  exit 1
fi

# Parseable line for automation (the deploy workflow greps for this).
echo "CID=${CID}"

echo ""
echo "=============================================================="
echo " Published via ${METHOD}. CID: ${CID}"
echo "--------------------------------------------------------------"
echo " Next steps to update the friendly URL (kurukuru.eth):"
echo "   1. Set ENS contenthash -> ipfs://${CID}"
echo "      (ENS app: https://app.ens.domains)"
echo "   2. (optional) DNSLink TXT on _dnslink.bokomoko.<tld>:"
echo "        dnslink=/ipfs/${CID}"
echo "   3. Verify: https://<gateway>/ipfs/${CID}/"
echo "=============================================================="
