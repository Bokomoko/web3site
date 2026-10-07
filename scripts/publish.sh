#!/usr/bin/env bash
#
# publish.sh — pin the built bundle to the torrent cloud (BTFS) + IPFS mirror.
#
# Usage:
#   ./scripts/publish.sh [dist_dir]
#
# Requires at least one of:
#   - btfs CLI  (BitTorrent File System — the "torrent cloud")
#   - ipfs CLI  (IPFS mirror / fallback)
#
# Output: prints the resulting CID. Point your ENS contenthash / DNSLink
# TXT record at that CID to update the friendly URL.
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST="${1:-${ROOT}/dist}"

if [ ! -d "${DIST}" ]; then
  echo "[publish] ERROR: bundle dir not found: ${DIST}"
  echo "[publish] run ./scripts/build.sh first"
  exit 1
fi

BTFS_CID=""
IPFS_CID=""

# --- Torrent cloud: BTFS -----------------------------------------------------
if command -v btfs >/dev/null 2>&1; then
  echo "[publish] adding to BTFS (torrent cloud): ${DIST}"
  BTFS_CID="$(btfs add -r -Q "${DIST}")"
  echo "[publish] BTFS CID: ${BTFS_CID}"
else
  echo "[publish] WARN: btfs CLI not found — skipping torrent cloud pin"
fi

# --- IPFS mirror -------------------------------------------------------------
if command -v ipfs >/dev/null 2>&1; then
  echo "[publish] adding to IPFS (mirror): ${DIST}"
  IPFS_CID="$(ipfs add -r -Q "${DIST}")"
  echo "[publish] IPFS CID: ${IPFS_CID}"
else
  echo "[publish] WARN: ipfs CLI not found — skipping IPFS mirror"
fi

if [ -z "${BTFS_CID}" ] && [ -z "${IPFS_CID}" ]; then
  echo "[publish] ERROR: neither btfs nor ipfs is installed. Nothing published."
  exit 1
fi

# BTFS and IPFS share the same content-addressing, so the CIDs should match
# for identical content. Prefer the BTFS CID when present.
CID="${BTFS_CID:-${IPFS_CID}}"

echo ""
echo "=============================================================="
echo " Published. CID: ${CID}"
echo "--------------------------------------------------------------"
echo " Next steps to update the friendly URL (bokomoko.eth):"
echo "   1. Set ENS contenthash -> ipfs://${CID}"
echo "      (ENS app: https://app.ens.domains)"
echo "   2. (optional) DNSLink TXT on _dnslink.bokomoko.<tld>:"
echo "        dnslink=/ipfs/${CID}"
echo "   3. Verify: https://<gateway>/ipfs/${CID}/"
echo "=============================================================="
