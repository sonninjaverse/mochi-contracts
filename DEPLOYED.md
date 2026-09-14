# Deployed contracts — Monad testnet

**Chain id 10143 · redeployed 2026-09-14 · explorer https://testnet.monadscan.com**

> **Seed set: 31 anchors** — the deployer plus thirty team-controlled wallets
> with invented handles. Immutable once deployed.

| Contract | Address |
|---|---|
| SocialGraph | `0x96c1bd8316597d2e2823d4c2748400ce4c511a87` |
| IdentityRegistry | `0x186e8c857ae91458534da3b277ab31275bf7b781` |
| PostRegistry | `0xb96f26c1d2c798366308d4631ae9ab312adc5b45` |
| AlgorithmRegistry | `0x26f7fde6bf9a0acbe42e5457118b38856dacef81` |
| ChronoFeed | `0x66907c3795aeb693ef432af30bea3ad23e6b7d4b` |
| FollowFeed | `0x6ef65e41ec5f00a0e9e4b6794ca85df29592f7ab` |
| AffinityFeed | `0xacf04de12806e411cc7f74def98984532bc443d4` |
| SerendipityFeed | `0xff2ee2c1a49b7b80a6158cd3c9a47d78bfa304be` |
| DiscoveryFeed | `0x2437ffe6d7eec1d794c6eb3519a46c2cebf2f6e3` |
| ParametricFeed | `0x66eaa67ea0985f46917c4a5f9c93282622f8644a` |

Default feed slot: SerendipityFeed. Default explore slot: DiscoveryFeed.
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
