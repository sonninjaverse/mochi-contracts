# Mochi Network contracts

A social network on Monad whose **feed ranking is a public contract you can
read, fork and swap**. This repository is that part of it — the registries, the
trust graph, and every shipped ranking algorithm.

Live at [mochi.meme](https://mochi.meme) on Monad testnet. All contracts are
verified: source is readable straight from
[Sourcify](https://repo.sourcify.dev/10143/0x6eb6e878b58a27F115FB9979A882834360F06362/)
without cloning anything.

## The whole idea, in one interface

```solidity
function rank(address viewer, uint256[] calldata candidateIds)
    external view
    returns (uint256[] memory orderedIds, uint256[] memory scores);
```

A client sends the candidate posts and a viewer; the contract sends back the
order. It is an `eth_call`, so switching algorithms costs nothing, needs no
wallet, and works signed out.

Nothing about deploying your own needs our permission. **[Write your own feed
algorithm](docs/writing-an-algorithm.md)** is the guide, with a worked example
that is deployed and rankable today.

## Deployed

| Contract | Address |
|---|---|
| SocialGraph | `0x7d11e04ccf5de28a3bdbe116714dc92e08d37cd6` |
| PostRegistry | `0xed65a47a6622a65ba5fb0fc184798195036047df` |
| AlgorithmRegistry | `0x3f5cee8729bae8a0aa011332a3108c68cbb5b7e1` |

Nine algorithms and the rest of the addresses are in [DEPLOYED.md](DEPLOYED.md).
Chain id 10143.

## Setup

```bash
git submodule update --init --recursive
forge test
```

116 tests, including a Wilson-score parity check against Reddit's own output
and an invariant that a ranking contract never reverts.

## Rules that are not style preferences

- **Post text never enters storage.** It lives in calldata and event data. Only
  what a ranking contract reads belongs in storage.
- **No admin functions anywhere.** No owner, no upgrade path, no `addSeed`. The
  trust anchors are fixed in the constructor at deployment, including against
  us.
- **`rank()` must never revert.** A reverting algorithm renders as a blank feed
  with nothing to explain it, and algorithms are deployed by strangers.
- **Votes are weighted by graph distance, not follower count.** A ring of
  wallets that follow each other never reaches the anchors, so it weighs
  nothing however loudly it votes — [why that works](docs/how-the-feed-works.md#votes-are-weighted-by-the-graph).

## Layout

| Path | Purpose |
|---|---|
| `src/interfaces/IFeedAlgorithm.sol` | The contract every algorithm implements |
| `src/` | Registries and the social graph |
| `src/algorithms/` | Shipped ranking algorithms, four of them Reddit's |
| `src/examples/` | A standalone example to copy |
| `docs/` | How the feed works, and how to write your own algorithm |
| `DEPLOYED.md` | Addresses and what was verified on chain |

## License

MIT.
