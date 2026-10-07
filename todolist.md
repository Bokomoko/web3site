# TODO — Unstoppable Domains wiring for bokomoko.x

Goal: make the friendly URL **`bokomoko.x`** resolve to the latest deploy CID,
and keep it updated as the site changes. Today the deploy pins the site to the
`bokomint` IPFS node and prints a CID; pointing `bokomoko.x` at that CID is the
remaining manual step.

The domain `bokomoko.x` is **already owned** (Unstoppable Domains), so there is
no registration or recurring fee. UD does not host content — it stores an
on-chain pointer (a record) to our IPFS-hosted site. UD records live on
**Polygon**, so updates cost little to no gas.

North Star alignment: this serves the project North Star — a censorship-resistant
portal reachable at a human-readable URL. `bokomoko.x` is the "human-readable
URL" half.

Status legend: [ ] todo · [~] in progress · [x] done · [!] blocked

---

## [!] BLOCKER — wallet access for bokomoko.x

`bokomoko.x` is self-custodied by the Ethereum address
`0xd7d1874eb9073261108affe80d2e9034a89ee885` (shown by UD's "Confirm with your
wallet" dialog). Setting the IPFS link requires signing a Polygon tx with that
wallet.

Investigation on this machine (read-only, metadata only):
- No desktop wallet apps (/Applications, Application Support) — none found.
- No wallet browser extensions (MetaMask/Phantom/Coinbase/Trust/etc.) in Chrome,
  Brave, or Edge profiles.
- Brave's built-in wallet keyring files exist in both profiles, but the Brave
  Wallet UI shows "Get Started" in BOTH — i.e. no account is loaded.
- No mobile wallet (user confirmed).

Conclusion: the wallet controlling `0xd7d1...e885` is NOT active on this machine.
The only way to regain control is the **recovery phrase** (12/24 BIP-39 words).

Next action (user, OUTSIDE Kiro, offline-safe):
- Search for the phrase in a password manager (1Password/Bitwarden/Apple
  Passwords), macOS Keychain/Notes, or a physical/paper backup.
- Filename-only disk search (prints paths, never contents) is acceptable; never
  grep for the words themselves or echo them anywhere.
- If found: restore via Brave "Get Started → Import", then do M1.

If the phrase is unrecoverable: `bokomoko.x` is permanently locked. Pivot to a
fresh wallet + a new name (new UD name, or ENS `kurukuru.eth`). The website is
unaffected either way (already live/pinned on bokomint).

IMPORTANT: the recovery phrase / private key must NEVER be pasted into a terminal
command, a repo file, or any chat. GitHub secret only, and only if/when CI
automation (M2 Option B) is chosen.

---

## Milestone 1 — Point bokomoko.x at the current build (UD dashboard)

Owner: Bokomoko. Done in the UD dashboard "Website" section; no code, no secrets.
This is the fastest path to a working public URL and is the recommended first
step. The domain is managed through the UD account, so UD performs the on-chain
record write (likely gas-sponsored) when you save.

- [ ] **1.1 Open the Website section**
  - UD dashboard → the domain `bokomoko.x` → **Website**.
  - Two options are shown: "Upload website files to IPFS" (uploads into UD's
    IPFS — NOT what we want) and "Custom website linking" (link an existing
    IPFS hash — THIS is what we want, since the site lives on our `bokomint`
    node).
  - Acceptance: the "Custom website linking" card with a **Link Website** button
    is visible.

- [ ] **1.2 Link the deploy CID**
  - Click **Link Website** under "Custom website linking".
  - Paste the latest deploy CID (CIDv1 `bafybei...`, printed by the deploy;
    currently `bafybeifv6ffwfav3hz2y3udsajdae7wxco2m3vqcs7enpr5onsntjia6pa`).
  - Confirm/save. UD writes the IPFS website record (`dweb.ipfs.hash`) for the
    domain.
  - Acceptance: the dashboard shows `bokomoko.x` linked to that CID.

- [ ] **1.3 Verify resolution**
  - Open `bokomoko.x` in a UD-aware browser (Brave, Opera) OR via the `ud.me`
    gateway, OR read the record with UD's Resolution Service API (see M2.1).
  - Confirm the PEC 3/2021 landing page renders.
  - Acceptance: `bokomoko.x` serves the current build; the resolved IPFS record
    equals the deploy CID.

> Per-deploy step: each deploy prints a new CID. Until/unless automation (M2) is
> in place, re-open "Custom website linking" and paste the new CID after each
> deploy to `main`.

---

## Milestone 2 — Automation (optional, gated by custody)

Owner: Kiro (implementation) + Bokomoko (secrets/custody). Depends on M1. Only
pursue if the manual dashboard step becomes a chore.

### UD APIs — what's usable here

- **Resolution Service API (read-only)** — reads a domain's records, including
  the IPFS website hash, via a REST call + API key. We CAN use this for
  verification (no wallet needed). Docs:
  https://docs.unstoppabledomains.com/resolution/quickstart/resolution/
- **Partner API v3 (write/manage, REST)** — can register/manage records WITHOUT
  touching the chain directly, BUT it operates on *Partner-custodied* domains
  (UD manages dedicated custodial wallets for Partner-owned names). It is NOT a
  "manage any user's self-held domain with an API key" endpoint. Docs:
  https://docs.unstoppabledomains.com/web3/apis/partner/openapi/
- **UNS registry contract `set`/`setMany` (write, on-chain)** — the universal
  write path for a *self-custodied* domain, signed by the owning wallet on
  Polygon. Docs:
  https://docs.unstoppabledomains.com/smart-contracts/quick-start/manage-domain-records/

### Custody reality for bokomoko.x

The domain is managed through the UD **dashboard** ("Website" → "Custom website
linking"), i.e. UD performs the on-chain write. That means:

- There is almost certainly **no self-custody private key** available to sign a
  `setMany` from CI today.
- So full CI write-automation is **blocked** unless the domain is first exported
  to a self-custody wallet whose key we can hold as a secret.

- [ ] **2.1 Decide the automation path**
  - **Option A — stay manual (recommended default):** keep using "Custom website
    linking" in the dashboard after each deploy. Zero secrets. Add M2.5 read
    verification via the Resolution API so we at least *detect* drift.
  - **Option B — full CI automation:** export `bokomoko.x` to a self-custody
    wallet, then sign `setMany` on Polygon from the runner. Requires a key as a
    secret (see 2.2). Only if updates become frequent.
  - Acceptance: option recorded here.

- [ ] **2.2 (Option B only) Add secrets** (Settings → Secrets → Actions)
  - `UD_UPDATER_PRIVATE_KEY` — key of the self-custody wallet that owns
    `bokomoko.x` on Polygon (after export).
  - `POLYGON_RPC_URL` — a Polygon mainnet RPC endpoint.
  - `UD_DOMAIN` — `bokomoko.x`.
  - SECURITY: the key controls the domain. GitHub secret only, never in the
    repo; scope the wallet to just this domain; keep a minimal MATIC balance;
    rotate if exposed.
  - Acceptance: all present; never printed in logs.

- [ ] **2.3 (Option B only) Add a UD update step to the deploy workflow**
  - After "Verify pin", only on `main`. Takes `steps.ipfs.outputs.cid` and calls
    `setMany` on the UNS registry (domain namehash, key `dweb.ipfs.hash`, value
    = CID) via a committed `scripts/ud-update.mjs` (viem + UNS ABI, pinned
    versions). Runs on the `bokomint` runner (needs egress to `POLYGON_RPC_URL`).
  - Acceptance: dry run encodes correct `setMany` calldata for a known CID +
    namehash.

- [ ] **2.4 (Option B only) Gas + failure handling**
  - Gas cap + timeout; decide whether a failed UD tx fails the deploy or warns
    (pin already succeeded). Add a `workflow_dispatch` re-point path.
  - Acceptance: documented behavior for "pin ok, UD tx failed".

- [ ] **2.5 (Either option) Read-side verification via Resolution API**
  - After a deploy, call the Resolution Service API for `bokomoko.x` and assert
    the IPFS record equals the just-deployed CID. Needs only a UD API key
    (`UD_API_KEY` secret), no wallet.
  - Acceptance: CI logs the resolved CID and flags a mismatch.

---

## Milestone 3 — Verification and durability

Owner: Kiro. Depends on M1 (and M2 if automated).

- [ ] **3.1 End-to-end verify after a real deploy**
  - Merge a trivial change to `main`; let CI deploy (and, if M2 is done, update
    the record).
  - Confirm `bokomoko.x` serves the new build (hard refresh; gateways cache).
  - Acceptance: new content visible via `bokomoko.x` within a few minutes.

- [ ] **3.2 Public reachability / durability of the CID**
  - The name is only useful if the CID is retrievable. `bokomint` is a single
    home node behind NAT. Add a second pin (another node or a pinning service)
    or a public gateway so the content survives bokomint downtime.
  - Acceptance: CID resolves from a public gateway with bokomint offline.

---

## Open questions / decisions needed

- Automation path: Option A (manual dashboard, recommended) or Option B (export
  to self-custody + `setMany` in CI)? (M2.1)
- Is exporting `bokomoko.x` out of UD-managed custody acceptable? That is the
  precondition for any CI write-automation. (M2.1/2.2)
- Do we want the read-side Resolution API verification regardless of path? (M2.5)
- Is a second pin location in scope now, or later? (M3.2)

## Notes

- Record key is `dweb.ipfs.hash` (current). `ipfs.html.value` is deprecated.
- The deploy already emits CIDv1 (`bafybei...`), which UD records accept.
- Keep any updater private key out of the repo at all costs — GitHub secret only.
- UD = pointer only, not hosting; the site lives on the `bokomint` IPFS node.
