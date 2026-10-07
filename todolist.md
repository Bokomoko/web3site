# TODO — ENS wiring for kurukuru.eth

Goal: make the friendly URL **`kurukuru.eth`** resolve to the latest deploy CID,
automatically updated on every deploy to `main`. Today the deploy pins the site
to the `bokomint` IPFS node and prints a CID, but pointing ENS at that CID is
manual.

North Star alignment: this serves the project North Star — a censorship-resistant
portal reachable at a human-readable URL. ENS is the "human-readable URL" half.

Status legend: [ ] todo · [~] in progress · [x] done · [!] blocked

---

## Milestone 1 — Register and configure ENS (one-time, manual, on-chain)

Owner: Bokomoko (requires a wallet + ETH for gas). These steps touch mainnet and
cost money; they are deliberately NOT automated.

- [ ] **1.1 Confirm/register the ENS name**
  - Check `kurukuru.eth` availability at https://app.ens.domains.
  - If unregistered, register it (annual fee + gas). If owned, confirm the
    controller is the wallet we will use for updates.
  - Acceptance: `kurukuru.eth` shows the intended controller address.

- [ ] **1.2 Set the resolver**
  - Ensure the name uses the current ENS Public Resolver (supports `contenthash`).
  - Acceptance: resolver address set; `contenthash` field is editable.

- [ ] **1.3 Set the initial contenthash manually**
  - Set `contenthash` → `ipfs://<latest deploy CID>` (CIDv1, e.g. the current
    `bafybei...`).
  - Acceptance: resolving `kurukuru.eth` returns the CID via
    `https://kurukuru.eth.limo` and an ENS resolver query.

- [ ] **1.4 Decide the updater identity**
  - Create or designate a wallet that owns/controls the name and will sign
    `setContenthash` transactions from CI.
  - Fund it with a small ETH balance for gas.
  - Acceptance: wallet address recorded; private key stored ONLY as a GitHub
    Actions secret (never in the repo). See 2.1.

---

## Milestone 2 — Automate contenthash updates in CI

Owner: Kiro (implementation) + Bokomoko (adds secrets). Depends on M1.

- [ ] **2.1 Add secrets to the repo** (Settings → Secrets → Actions)
  - `ENS_UPDATER_PRIVATE_KEY` — wallet key that controls `kurukuru.eth`.
  - `ETH_RPC_URL` — mainnet RPC endpoint (e.g. Infura/Alchemy/own node).
  - `ENS_NAME` — `kurukuru.eth` (or make it a workflow env var).
  - Acceptance: all three secrets present; values never printed in logs.
  - SECURITY: the private key gives control of the ENS name and spends ETH.
    Treat it as a production credential. Scope the wallet to only own this name;
    keep a minimal gas balance. Rotate if ever exposed.

- [ ] **2.2 Add an ENS update step to `.github/workflows/deploy.yml`**
  - Runs AFTER the existing "Verify pin" step, only on `main`.
  - Takes `steps.ipfs.outputs.cid`, encodes it as an ENS contenthash
    (`ipfs://<cid>`), and calls `setContenthash` on the resolver.
  - Tooling options (pick one in 2.3):
    - a small Node script using `viem` or `ethers` + `@ensdomains/ensjs`;
    - or the `ens-contenthash` / equivalent CLI.
  - Must mask the key; fail the job if the tx reverts.
  - Acceptance: a dry-run (testnet or `--dry-run`) encodes the right contenthash
    for a known CID.

- [ ] **2.3 Choose the updater implementation + pin versions**
  - Prefer a tiny committed script `scripts/ens-update.mjs` (viem) over an
    unpinned third-party action, so the signing path is auditable.
  - Pin exact dependency versions (iron rule: no open ranges).
  - Run it on the `bokomint` self-hosted runner (same job) — it needs network
    egress to `ETH_RPC_URL`, not the LAN.
  - Acceptance: script committed, deps pinned, `uv`/npm invocation documented.

- [ ] **2.4 Gas + failure handling**
  - Set a sane gas cap and a timeout; on failure, surface a clear error and
    keep the deploy green/red decision explicit (pin succeeded even if ENS tx
    failed — decide whether that fails the whole deploy).
  - Add a `workflow_dispatch` manual re-run path to re-point ENS to a given CID.
  - Acceptance: documented behavior for "pin ok, ENS tx failed".

---

## Milestone 3 — Verification and durability

Owner: Kiro. Depends on M2.

- [ ] **3.1 End-to-end verify after a real deploy**
  - Merge a trivial change to `main`, let CI deploy + update ENS.
  - Confirm `https://kurukuru.eth.limo` serves the new build (hard refresh;
    gateways cache).
  - Confirm an ENS resolver query returns the new `contenthash`.
  - Acceptance: new content visible via the ENS gateway within a few minutes.

- [ ] **3.2 (Related, tracked separately) public reachability of the CID**
  - The ENS name is only useful if the CID is retrievable. `bokomint` is a
    single home node behind NAT. Add a second pin (another node or a pinning
    service) or a public gateway so the content survives bokomint downtime.
  - NOTE: this is the "public reachability" item from the deploy discussion;
    not strictly ENS but a hard dependency for a working public URL.
  - Acceptance: CID resolves from a public gateway with bokomint offline.

---

## Open questions / decisions needed

- Which wallet/key owns `kurukuru.eth` and signs CI updates? (M1.4)
- Which mainnet RPC provider for `ETH_RPC_URL`? (M2.1)
- Should an ENS-update failure fail the whole deploy, or just warn? (M2.4)
- Is a second pin location in scope now, or later? (M3.2)

## Notes

- Keep the ENS private key out of the repo at all costs — GitHub secret only.
- ENS updates cost gas on every change; batching / only-on-release may be worth
  considering if deploys become frequent.
- `contenthash` is CIDv1-friendly; the deploy already emits CIDv1 (`bafybei...`).
