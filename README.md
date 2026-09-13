# Mochi Network contracts

The feed ranking algorithm is a public smart contract that anyone can read,
fork and swap. `IFeedAlgorithm` is the whole idea in one interface.

## Setup

```bash
git submodule update --init --recursive
forge test
```

## Layout

| Path | Purpose |
|---|---|
| `src/interfaces/IFeedAlgorithm.sol` | The contract every algorithm implements. Frozen. |
| `src/` | Registries and the social graph |
| `src/algorithms/` | Shipped ranking algorithms |
| `script/DeployStubs.s.sol` | Day-3 stand-in, deleted once the real contracts deploy |
| `abi/` | ABIs the frontend and indexer build against |
| `DEPLOYED.md` | Addresses and measured gas |

## Rules that are not style preferences

- **Post text never enters storage.** It lives in calldata and event data.
  Only what a ranking contract reads belongs in storage.
- **No admin functions anywhere.** No owner, no upgrade path, no `addSeed`.
  The seed set is fixed in the constructor at deployment.
- **`rank()` must never revert.** A reverting algorithm renders as a blank
  feed, and algorithms are deployed by strangers.

Design rationale: `docs/superpowers/specs/2026-09-13-mochi-network-design.md`
Task list: `docs/superpowers/plans/2026-09-13-contracts.md`
