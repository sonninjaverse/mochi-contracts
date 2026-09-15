# Deployed contracts — Monad testnet

**Chain id 10143 · redeployed 2026-09-15 · explorer https://testnet.monadscan.com**

Every contract below is verified on Sourcify with an `exact_match` on both
creation and runtime bytecode, so the source can be read without cloning:
`https://repo.sourcify.dev/10143/<address>/`

> **Seed set: 31 anchors** — the deployer plus thirty team-controlled wallets
> with invented handles. Immutable once deployed.

| Contract | Address |
|---|---|
| SocialGraph | `0x7d11e04ccf5de28a3bdbe116714dc92e08d37cd6` |
| IdentityRegistry | `0xa788bcbd7b09d5caaa93b4b69516dc2ac89d277b` |
| PostRegistry | `0xed65a47a6622a65ba5fb0fc184798195036047df` |
| ChronoFeed | `0x79e74b0065f2461eb2ba874ba389a3e05fa4ac88` |
| HotFeed | `0xc05f6443567dd8bad273160880ba5a5707803708` |
| BestFeed | `0x595f2a29e5859f4870bb0eb2c6a3f15788b7eac3` |
| ControversialFeed | `0x277d58051cd879e14136651e1aa59197c13d3dbf` |
| FollowFeed | `0x37fb3fcbf5e65f768d0ff319d0dbc17d68f8dbf9` |
| AffinityFeed | `0x65e4e505b6e5ac839802e6e8b0bfb17fb5a88323` |
| SerendipityFeed | `0x129c6498d932b18aa7d0b5af024439785161a34e` |
| DiscoveryFeed | `0x8bf646f66af7b96a2d1da54662dff9e0150cbbda` |
| ParametricFeed | `0xa656c8571b54d6f46416225acdf624f505d92444` |
| AlgorithmRegistry | `0x3f5cee8729bae8a0aa011332a3108c68cbb5b7e1` |

Default feed slot: HotFeed. Default explore slot: DiscoveryFeed.
Nine algorithms registered. No contract has an admin function.

`NetVotesFeed` at `0x8ffDad83C6c3e6bbf50088D46DaC87C9B8547601` is the worked
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
