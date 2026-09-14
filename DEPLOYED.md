# Deployed contracts — Monad testnet

**Chain id 10143 · redeployed 2026-09-14 · explorer https://testnet.monadscan.com**

> **Seed set: 31 anchors** — the deployer plus thirty team-controlled wallets
> with invented handles. Immutable once deployed.

| Contract | Address |
|---|---|
| SocialGraph | `0x7a3f704ae7e12c0f1baa79905ac045199a366ef8` |
| IdentityRegistry | `0x6b9a453075f00bc17b515061aaff7d710dd42953` |
| PostRegistry | `0x7fab7facb68992c84efa942e2052ea33e9073cf4` |
| ChronoFeed | `0x92a0b888b0a026a340c44926d1dcbc8951b06c2c` |
| HotFeed | `0x6eb6e878b58a27f115fb9979a882834360f06362` |
| BestFeed | `0x0f8badfe3de0d479580ea56ac3fdb571141e53df` |
| ControversialFeed | `0xe2f9cff336d73af0d15db6b26dad21a76e44c83e` |
| FollowFeed | `0x95738e88cd1a46c2cf7b1f2e6adca789aa2efabc` |
| AffinityFeed | `0xd95d34e3eac7faf4bd5fe05bdb98ae5cbe12cc51` |
| SerendipityFeed | `0x699d108cfda5d9fe9d79e864001fa29f598bf9d3` |
| DiscoveryFeed | `0x866133cd8f6f0cd8c948453b697d385cebbdc67c` |
| ParametricFeed | `0xbc4078fe1e9fe6926d77f19f013c63268f18a43b` |
| AlgorithmRegistry | `0x02b2268761ccb1ab5b26751f517448b3b866b6af` |

Default feed slot: HotFeed. Default explore slot: DiscoveryFeed.
Nine algorithms registered. No contract has an admin function.

`NetVotesFeed` at `0x2B99faEEa7369c998e81635486FD6A28C952CA30` is the worked
example from [docs/writing-an-algorithm.md](../docs/writing-an-algorithm.md).
Deployed, deliberately **not** registered: it is there to be pasted into the
feed control the way a stranger's algorithm would be.

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
