# Deployed contracts — Monad testnet

**Chain id 10143 · redeployed 2026-09-14 · explorer https://testnet.monadscan.com**

> **Seed set: 31 anchors** — the deployer plus thirty team-controlled wallets
> with invented handles. Immutable once deployed.

| Contract | Address |
|---|---|
| SocialGraph | `0x9ff3c817bd6c65ef2ed148de815a4d87c7c79b92` |
| IdentityRegistry | `0x1129f4115abd5bd3ee80de8de166fbbfe6f6cb24` |
| PostRegistry | `0xa9428c768f9e4eca0e23dfd7c7e30eb807ccaad0` |
| ChronoFeed | `0xf855f22f43644dc277cba0b4cec293ef302341b9` |
| HotFeed | `0xfb6b96e9b195e567a1b18177e69d42476fb821f4` |
| BestFeed | `0x6c5b4e6a43775e61119a2fd5ae047351af1fe142` |
| ControversialFeed | `0x6ef0bcfd4fc24ed2562b38ae6f7f778d348446f9` |
| FollowFeed | `0x1cfc28e483ba14ce4b0d20523ab8d9da2f501aed` |
| AffinityFeed | `0x1b7f955ea04d505342b832943a31777c64c4341c` |
| SerendipityFeed | `0x77c4eb442a65cb3e5088ea1d006a324188dfeec6` |
| DiscoveryFeed | `0x0cdf94ce85fa2896ef833d433e7e6013a07a472b` |
| ParametricFeed | `0x5bb35dd0c83d34042145572b9fd5e76c96034b8f` |
| AlgorithmRegistry | `0x80de7271bc24493bf8e9ccba00313059302564ac` |

Default feed slot: HotFeed. Default explore slot: DiscoveryFeed.
Six algorithms registered. No contract has an admin function.

## Verified on chain

```
depthOf(seed wallet)              -> 0        seeds start reachable
weightOf(seed wallet)             -> 100      full discovery weight
depthOf(0x...dEaD)                -> 255      an unknown wallet is UNREACHED
algorithmCount()                  -> 6
algorithmOf(anyone, SLOT_FEED)    -> SerendipityFeed
rank(viewer, [1])                 -> scored, no revert
```

`evm_version = "shanghai"` is accepted by Monad. No opcode fallback to `paris` needed.

## Real cost on Monad testnet

Gas price at deployment: **102 gwei**.

| Action | Gas | Cost |
|---|---|---|
| Deploy all ten contracts | ~8.7M | **0.935 MON** |
| `post` | 67,146 | 0.00695 MON |
| `like` | 99,492 | ~0.0102 MON |
| `follow` | 117,870 | ~0.0120 MON |

### This changes the seed data budget

The indexer plan assumed roughly 24 MON. At 102 gwei the real figure is:

```
3,000 posts    x 0.00695  =  20.9 MON
5,000 likes    x 0.0102   =  50.7 MON
2,000 follows  x 0.0120   =  24.0 MON
300 wallets    x 0.05     =  15.0 MON   (funding)
                              --------
                              ~110 MON
```

**About 4.5x the plan's estimate**, but the deployer wallet holds 209 MON as of
2026-09-14, so the full volume is affordable with room to regenerate the data
several times. No need to cut the seed data down.

Note also that "sub-cent fees" in the spec is a claim about mainnet economics
and has not been verified. On testnet the gas price is 102 gwei, which is not
negligible in MON terms whatever a MON is worth.

## Redeploying

```bash
cd contracts
set -a && . ./.env && set +a
forge script script/Deploy.s.sol:Deploy \
  --rpc-url "$MONAD_TESTNET_RPC" --private-key "$PRIVATE_KEY" --broadcast
```

## Toolchain

- Foundry 1.7.1, solc 0.8.24, `evm_version = "shanghai"`
- `forge-std` pinned at v1.16.2 as a git submodule
- 82 tests, all passing

A fresh clone needs the submodule:

```bash
git submodule update --init --recursive
```
