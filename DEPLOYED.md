# Deployed contracts — Monad testnet

**Chain id 10143 · deployed 2026-09-14 · explorer https://testnet.monadscan.com**

> **Provisional deployment.** The seed set holds only the deployer wallet. Replace
> `seeds.json` with three team wallets plus the real Monad ecosystem addresses and
> redeploy before the demo — the seed set is immutable once deployed.

| Contract | Address |
|---|---|
| SocialGraph | `0x8e63326fa167d22fdc0cc2e4172ecdd4fd138de0` |
| IdentityRegistry | `0x655068668d57c85cace3ab7d1fd8eeb3ce6b1c2c` |
| PostRegistry | `0x556beb11957955ff4fb4c5263d1e4a4b68bea197` |
| AlgorithmRegistry | `0x56ca4d9bb90ff6983b46506a78cc3acccc3bff73` |
| ChronoFeed | `0xe6e7ed4a1091d5b29d0fabf22fc44348d0d6d69d` |
| FollowFeed | `0x51b414ccc6330db98a6b52110b1441f5c5084ea5` |
| AffinityFeed | `0x9088997666c9a9e66df0ee2b833a88b2fb1665ef` |
| SerendipityFeed | `0x476a8fb0270bed8de0e0d37ec21b801cd19502ba` |
| DiscoveryFeed | `0x2d1cef498eea5054f85041c52cccdf76b600570a` |
| ParametricFeed | `0x38feae33d194fc751b4903d125c627f97dd95a21` |

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

**About 4.5x the plan's estimate.** Check the faucet limit before committing to
this volume; halving posts and likes brings it to roughly 55 MON.

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
