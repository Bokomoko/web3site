# Bokomoko Portal — Web3 CMS on the Torrent Cloud

A decentralized portal / lightweight CMS for **Bokomoko**, built with **plain JavaScript (no frameworks)** and served from decentralized storage. Content is addressed by hash, pinned to the "torrent cloud" (BTFS), mirrored on IPFS, and reached through a human-friendly URL via an **Unstoppable Domains** name (`bokomoko.x`).

The landing page is **version 4 of the PEC 3/2021 infographic** (an interactive D3.js page).

---

## North Star

Publish a censorship-resistant, serverless portal for Bokomoko that:

- Runs as static assets (HTML/CSS/vanilla JS) with zero backend.
- Is content-addressed and immutable per release (a CID per version).
- Lives on the torrent cloud so there is no single point of failure.
- Is reachable at a readable URL, not a raw hash.

---

## What "Torrent Cloud" means here

The torrent cloud is decentralized storage built on the BitTorrent protocol. The content isn't on one server — it's chunked, hashed, and served peer-to-peer by many nodes, exactly like a torrent, but presented as a cloud storage/hosting layer.

The concrete target is **BTFS (BitTorrent File System)** — the BitTorrent + TRON decentralized storage network. It is a torrent-native, IPFS-compatible protocol: files get a content hash (CID), are stored across the DHT by storage nodes, and are retrievable through BTFS gateways. See the research notes below.

We pair BTFS with **IPFS** because the two speak the same content-addressing model (CIDs, DAG, DHT). This gives us redundancy: the same build pins to both networks, and either can serve it.

---

## Architecture

```
  Source (this repo)                 Build output              Decentralized storage           Friendly URL
┌─────────────────────┐          ┌──────────────────┐       ┌───────────────────────┐      ┌──────────────────┐
│ index.html          │          │ /dist            │       │  BTFS (torrent cloud) │      │ bokomoko.x        │
│ pages/*.html        │  build   │   index.html     │  pin  │   + IPFS mirror       │  UD  │   ↓ record        │
│ assets/ css js      │ ───────► │   assets/...      │ ────► │   → CID (immutable)   │ ───► │  dweb.ipfs.hash   │
│ content/*.json      │          │   content/...     │       │                       │      │  = CID            │
└─────────────────────┘          └──────────────────┘       └───────────────────────┘      └──────────────────┘
```

- **No frameworks.** Rendering is done with vanilla JS DOM APIs. The infographic uses D3.js (loaded via CDN inside the page) for charts only.
- **Content as data.** Portal/CMS pages are driven by JSON content files plus small vanilla-JS renderers, so adding a page is adding a content file, not writing a backend.
- **Immutable releases.** Each publish produces a new CID. The friendly URL is repointed to the latest CID; old CIDs remain valid forever.

---

## Project structure

```
web3site/
├── README.md
├── index.html              # Landing page: PEC 3/2021 infographic (v4)
├── pages/                  # Additional portal pages (vanilla JS rendered)
├── assets/
│   ├── css/
│   └── js/                 # Vanilla JS: router, content loader, renderers
├── content/                # JSON content for the CMS (one file per entry)
├── scripts/
│   ├── build.sh            # Assemble /dist
│   └── publish.sh          # Pin to BTFS + IPFS, print CID, update DNSLink
└── dist/                   # Build output (generated, git-ignored)
```

> The landing page content is seeded from `infografico_pec3_2021_v4.html` (currently in `~/Downloads`). Copy it in as `index.html` — see Getting Started.

---

## URL strategy (user-friendly)

Raw CIDs are not readable. We make the portal reachable through an
**Unstoppable Domains** name we already own, `bokomoko.x`:

1. **Set the IPFS record** — on `bokomoko.x`, set the record `dweb.ipfs.hash` to the current build CID. UD stores records as an on-chain key-value map; this key is the dweb/IPFS website pointer (the older `ipfs.html.value` is deprecated).
2. **(optional) protocol hint** — set `browser.preferred_protocols` to `["ipfs","http"]` so resolvers prioritize IPFS.
3. **Access** — users reach the site via:
   - `bokomoko.x` in a UD-aware browser (Brave, Opera) or the `ud.me` gateway, or
   - a BTFS/IPFS gateway path `.../ipfs/<CID>/` directly.

On each release, only the `dweb.ipfs.hash` record changes — the name stays constant. UD records live on Polygon, so updates cost little to no gas. UD does not host content; it only stores the pointer to our IPFS-hosted site.

---

## Getting started

> Python tooling in this repo is invoked through `uv run`. The publish/build helpers are shell scripts that shell out to the IPFS/BTFS CLIs.

```bash
# 1. Seed the landing page from the PEC 3/2021 v4 infographic
cp ~/Downloads/infografico_pec3_2021_v4.html index.html

# 2. Serve locally while developing (static, no backend)
uv run python -m http.server 8080
# open http://localhost:8080

# 3. Build the publishable bundle
./scripts/build.sh            # → ./dist

# 4. Publish to the torrent cloud (BTFS) + IPFS mirror
./scripts/publish.sh ./dist   # prints the CID to set on bokomoko.x
```

---

## Publishing to the torrent cloud (BTFS)

High-level flow (research-backed, see Sources):

1. **Run or reach a BTFS node.** Either run your own BTFS node or use a BTFS gateway/pinning service. BTFS is IPFS-compatible, so the `btfs add` flow mirrors `ipfs add`.
2. **Add the build.** `btfs add -r ./dist` returns a **CID** for the directory. On BTFS you can also take out a **storage contract** so storage nodes keep your content pinned (incentivized with BTT on TRON).
3. **Mirror to IPFS** for redundancy: `ipfs add -r ./dist` (same content-addressing model) or pin via a service (Pinata, Filebase, web3.storage-style providers).
4. **Point the name at the CID.** Set the `dweb.ipfs.hash` record on `bokomoko.x` to the new CID. The friendly URL now serves the new release.
5. **Verify.** Fetch `https://<gateway>/ipfs/<CID>/` and confirm the landing page renders.

Because content is addressed by hash, publishing a change = publishing a new CID. There are no in-place edits; every version is reproducible and verifiable.

---

## Decisions & constraints

- Plain JavaScript, **no frameworks** (React/Vue/Svelte are out). D3.js is allowed as a charting lib inside the infographic page only.
- Static assets only — no server-side runtime in production (it's hosted peer-to-peer).
- The torrent cloud target is **BTFS**, with **IPFS** as the mirror. Both are content-addressed and interoperable.
- The public URL is the Unstoppable Domains name **`bokomoko.x`** (already owned, no recurring fee).
- First page = **PEC 3/2021 infographic, version 4**.

---

## Open questions

- Updating `bokomoko.x` after each deploy: manual (UD dashboard) or automated (`setMany` on Polygon from CI)? See `todolist.md`.
- BTFS hosting approach: self-hosted node vs. managed BTFS/IPFS pinning provider. (Currently: self-hosted IPFS node on `bokomint`.)
- Public reachability/durability of the CID beyond the single `bokomint` node.

---

## Sources (research)

Content below was rephrased for compliance with licensing restrictions.

- Hosting sites on IPFS and making CIDs user-friendly — [IPFS: Custom domains and DNSLink](https://docs.ipfs.tech/how-to/websites-on-ipfs/custom-domains/), [IPFS: host a single-page site](https://github.com/ipfs/ipfs-docs/blob/main/docs/how-to/host-single-page-site.md)
- Mapping a readable domain to a CID — [IPFS: Link a domain](https://docs.ipfs.eth.limo/how-to/websites-on-ipfs/link-a-domain/), [Cloudflare Web3: DNSLink gateways](https://developers.cloudflare.com/web3/ipfs-gateway/concepts/dnslink/)
- Unstoppable Domains → IPFS website records — [UD: records reference (`dweb.ipfs.hash`)](https://docs.unstoppabledomains.com/resolution/records-reference/), [UD: manage records via contract (`setMany`)](https://docs.unstoppabledomains.com/smart-contracts/quick-start/manage-domain-records/), [UD: browser resolution](https://docs.unstoppabledomains.com/resolution/guides/browser-resolution/overview/), [UD: no hosting, point to external IPFS](https://support.unstoppabledomains.com/support/solutions/articles/48001277457-does-unstoppable-domains-offer-hosting-)
- Naming-layer background (ENS, for comparison) — [ENS: Practical guide to decentralized websites](https://ens.domains/blog/post/decentralized-websites)
- Torrent cloud / BTFS decentralized storage — [BitTorrent File System (BTFS)](http://staging.bittorrent.com/token/bittorrent-file-system/), [BTFS web3 storage overview](https://www.okx.com/nb/learn/btfs-web3-storage-data-privacy-scalability), [Hosting storage on BTFS](https://www.quora.com/How-do-I-start-storage-hosting-in-BTFS)
- Hosting websites via torrents, background — [SitePoint: using torrents to host websites](https://www.sitepoint.com/bittorrents-maelstrom-using-torrents-host-websites/)
```