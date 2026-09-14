# Deployed contracts — Monad testnet

## Status: all contracts built and tested, testnet deploy pending

Everything below is verified against a local anvil node. Only the addresses are
missing, and they need an RPC url and a funded testnet key.

| Contract | Address |
|---|---|
| SocialGraph | _pending_ |
| IdentityRegistry | _pending_ |
| PostRegistry | _pending_ |
| AlgorithmRegistry | _pending_ |
| ChronoFeed | _pending_ |
| FollowFeed | _pending_ |
| AffinityFeed | _pending_ |
| SerendipityFeed | _pending_ |
| DiscoveryFeed | _pending_ |
| ParametricFeed | _pending_ |

Default feed slot: SerendipityFeed. Default explore slot: DiscoveryFeed.

Seed set: fixed in the SocialGraph constructor from `seeds.json`. There is no
function to add or remove one, and no admin role exists on any contract.

## Measured gas

Taken from transaction receipts on a local node, not estimated:

| Action | Gas | Spec estimate | Note |
|---|---|---|---|
| `post` | 55,755 | ~60,000 | close |
| `like` | 99,492 | ~45,000 | **2.2x the estimate** |
| `follow` | 117,870 | ~50,000 | **2.4x the estimate** |
| `unlike` | 33,932 | — | warm slots, so much cheaper |
| `register` (handle) | 69,442 | — | once per account |

The two write-heavy operations cost roughly twice what the spec guessed, and
the reason is by design rather than an accident:

- `follow` writes four cold slots — `followedAt`, `followingCount`,
  `followerCount`, and `_depth` when the followee becomes reachable.
- `like` writes three — `hasLiked`, the packed `likeCount`/`weightedLikes`
  slot, and `interactionCount`.

Both extra writes buy O(1) reads at ranking time, which is the trade the spec
argues for. The numbers confirm the trade is real, not that it was wrong: the
write costs about twice as much, and every feed load afterwards avoids a scan.

Use these figures in the write-up rather than the spec's estimates.

## Seed data budget

At measured cost, seeding the demo network is roughly:

```
3,000 posts   x  55,755  =  167M gas
5,000 likes   x  99,492  =  497M gas
2,000 follows x 117,870  =  236M gas
                            --------
                            ~900M gas
```

That is around 1.8x the 500M the indexer plan assumed. Claim faucet funds with
that in mind.

## Deploying to testnet

```bash
cd contracts
export MONAD_TESTNET_RPC="<https RPC url>"
export PRIVATE_KEY="<funded testnet key>"

# seeds.json still holds placeholders. Replace them first.
forge script script/Deploy.s.sol:Deploy \
  --rpc-url "$MONAD_TESTNET_RPC" --private-key "$PRIVATE_KEY" --broadcast
```

Record the printed addresses above, then tell P2 and P3.

If deployment fails on an unknown opcode, drop `evm_version` in `foundry.toml`
from `shanghai` to `paris` and retry.

## Toolchain

- Foundry 1.7.1, solc 0.8.24, `evm_version = "shanghai"`
- `forge-std` pinned at v1.16.2 as a git submodule
- 84 tests, all passing

A fresh clone needs the submodule:

```bash
git submodule update --init --recursive
```
