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

## Milestone 1 — Point bokomoko.x at the current build (manual, simplest)

Owner: Bokomoko. Done in the UD dashboard; no code, no secrets. This is the
fastest path to a working public URL and is the recommended first step.

- [ ] **1.1 Confirm ownership + management access**
  - Sign in at https://unstoppabledomains.com and confirm `bokomoko.x` is in the
    account and manageable.
  - Note which chain it's on (UNS on Polygon for most recent names).
  - Acceptance: `bokomoko.x` shows under "My Domains" with an editable records
    panel.

- [ ] **1.2 Set the IPFS website record**
  - Set record `dweb.ipfs.hash` = `<latest deploy CID>` (the CIDv1 `bafybei...`
    printed by the deploy; currently
    `bafybeifv6ffwfav3hz2y3udsajdae7wxco2m3vqcs7enpr5onsntjia6pa`).
  - Note: `ipfs.html.value` is the deprecated equivalent — do NOT use it; use
    `dweb.ipfs.hash`.
  - Save/submit (one Polygon tx; UD may sponsor gas).
  - Acceptance: the record shows the CID in the dashboard.

- [ ] **1.3 (optional) Protocol hint**
  - Set `browser.preferred_protocols` = `["ipfs","http"]`.
  - Acceptance: record saved.

- [ ] **1.4 Verify resolution**
  - Open `https://bokomoko.x` in a UD-aware browser (Brave, Opera) OR via the
    `ud.me` gateway, OR resolve the record through UD's resolution API/CLI.
  - Confirm the PEC 3/2021 landing page renders.
  - Acceptance: `bokomoko.x` serves the current build; the resolved
    `dweb.ipfs.hash` equals the deploy CID.

---

## Milestone 2 — Automate the record update in CI (optional)

Owner: Kiro (implementation) + Bokomoko (adds secrets). Depends on M1 and on the
decision in the Open Questions below. Only pursue if manual updates become a
chore. UD updates are `setMany`/`set` calls on the UNS registry on Polygon.

- [ ] **2.1 Decide: automate or stay manual**
  - Manual (M1) is zero-secret and fine for infrequent deploys.
  - Automation adds a signing key on the runner — a real credential. Choose
    deliberately.
  - Acceptance: decision recorded here.

- [ ] **2.2 Add secrets to the repo** (Settings → Secrets → Actions)
  - `UD_UPDATER_PRIVATE_KEY` — wallet key that owns/controls `bokomoko.x` on
    Polygon.
  - `POLYGON_RPC_URL` — a Polygon mainnet RPC endpoint.
  - `UD_DOMAIN` — `bokomoko.x` (or a workflow env var).
  - Acceptance: all three present; values never printed in logs.
  - SECURITY: the key controls the domain and can set any record. Treat it as a
    production credential; scope the wallet to just this domain, keep a minimal
    MATIC balance for gas, rotate if exposed. GitHub secret only — never in the
    repo.

- [ ] **2.3 Add a UD update step to `.github/workflows/deploy.yml`**
  - Runs AFTER the existing "Verify pin" step, only on `main`.
  - Takes `steps.ipfs.outputs.cid` and sets `dweb.ipfs.hash` on `bokomoko.x` via
    the UNS registry `setMany` (namehash of the domain, key `dweb.ipfs.hash`,
    value = CID).
  - Implementation: a small committed script `scripts/ud-update.mjs` using
    `viem` (Polygon) + the UNS registry ABI, or the Unstoppable resolution/
    registry libraries. Prefer a committed, auditable script over an unpinned
    third-party action.
  - Pin exact dependency versions (iron rule: no open ranges).
  - Runs on the `bokomint` self-hosted runner (needs egress to `POLYGON_RPC_URL`,
    not the LAN).
  - Must mask the key; fail the step if the tx reverts.
  - Acceptance: a dry run encodes the correct `setMany` calldata for a known CID
    and domain namehash.

- [ ] **2.4 Gas + failure handling**
  - Set a gas cap and timeout. Decide whether a failed UD tx fails the whole
    deploy or just warns (the pin already succeeded).
  - Add a `workflow_dispatch` path to re-point `bokomoko.x` to a given CID
    manually.
  - Acceptance: documented behavior for "pin ok, UD tx failed".

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

- Update strategy: manual UD dashboard (M1) or automated `setMany` in CI (M2)?
- If automated: which wallet/key controls `bokomoko.x`, and which Polygon RPC
  provider? (M2.2)
- Should a UD-update failure fail the whole deploy, or just warn? (M2.4)
- Is a second pin location in scope now, or later? (M3.2)

## Notes

- Record key is `dweb.ipfs.hash` (current). `ipfs.html.value` is deprecated.
- The deploy already emits CIDv1 (`bafybei...`), which UD records accept.
- Keep any updater private key out of the repo at all costs — GitHub secret only.
- UD = pointer only, not hosting; the site lives on the `bokomint` IPFS node.
