# Deployed contracts — Monad testnet

## Status: interface frozen, testnet deploy pending

`IFeedAlgorithm` is frozen and will not change. The ABI in `abi/IFeedAlgorithm.json`
is final, so the frontend and indexer can be written against it now — only the
address below is still missing.

| Contract | Address |
|---|---|
| StubFeed | _pending — needs an RPC URL and a funded testnet key_ |

## What has been verified

The deploy script and the full call path were exercised against a local anvil
node before any testnet key existed:

```
name()                        -> "Stub"
description()                 -> "Hardcoded stub for day-3 integration"
rank(address, [7,8,9])        -> ids [7,8,9], scores [3e18, 2e18, 1e18]
rank(address, [])             -> [], []        (empty input must not revert)
```

The empty-input case matters: a reverting `rank()` renders as a blank feed, and
every algorithm shipped later has to keep that property.

## Deploying to testnet

```bash
cd contracts
export MONAD_TESTNET_RPC="<https RPC url>"
export PRIVATE_KEY="<funded testnet key>"
forge script script/DeployStubs.s.sol:DeployStubs \
  --rpc-url "$MONAD_TESTNET_RPC" --private-key "$PRIVATE_KEY" --broadcast
```

Then record the printed address in the table above and tell P2 and P3.

If deployment fails on an unknown opcode, drop `evm_version` in `foundry.toml`
from `shanghai` to `paris` and retry. That check is the reason this stub is
deployed before any real contract.

## Toolchain

- Foundry 1.7.1, solc 0.8.24, `evm_version = "shanghai"`
- `forge-std` pinned at v1.16.2 as a git submodule

A fresh clone needs the submodule:

```bash
git submodule update --init --recursive
```
