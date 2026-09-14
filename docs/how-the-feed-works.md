# How the feed works

Two things decide what you see, and they are separate on purpose.

**Which posts are considered** comes from an indexer we run. It is off chain,
it is dumb by design, and it is decided by the tab you are on — not by a
setting. There is no secret weighting in it and no personalisation.

**What order they appear in** comes from a contract. Ranking is an `eth_call`,
so switching is instant, costs nothing, and needs no wallet — a signed-out
visitor gets a ranked feed. Which contract is your choice, and it can be one we
never wrote: see [writing your own](writing-an-algorithm.md).

## Feed and Explore

| | Feed | Explore |
|---|---|---|
| Posts considered | accounts you follow | everyone |
| Ordered by | Hot, New, Best or Controversial | Discovery |

They are two slots, each holding an algorithm. Explore is not a hardcoded
feature — it is the second slot, and the contract filling it is named in the
panel and readable from there.

Follow a few people and the two stop overlapping. Measured on the seeded
network for an account with follows: **zero of the top ten appear in both.**

Until you follow anyone the home feed has nothing of its own, so it shows the
newest posts and says so. Deliberately not what is spreading — that is
Explore's source, and borrowing it would make both tabs show the same list.

## The four sorts

These are Reddit's, implemented from its published `_sorts.pyx` rather than
reinvented.

**Hot** — the default. `sign · log10(max(|score|, 1)) + seconds / 45000`.
Votes count logarithmically, so the tenth upvote matters far less than the
first, and every 12.5 hours a post needs ten times as many votes to hold its
place. This is the ranking that made Reddit's front page behave the way it
does.

**New** — newest first. No ranking, no filtering, no opinion. The baseline you
compare the others against.

**Best** — the Wilson score lower bound at 95% confidence. Ranks by how sure
the votes make us rather than by the average, so nine hundred votes at 80%
beats four votes at 100%. One friendly vote does not outrank a crowd. Our
implementation is checked against Reddit's own output to within 0.5%.

**Controversial** — `magnitude ^ balance`, where balance is how evenly the
upvotes and downvotes are split. Surfaces what people disagreed about rather
than what they agreed on — the one thing an engagement-maximising feed will
never show you, because disagreement does not retain.

**Discovery**, on Explore, drops the authors you already follow and ranks the
rest by how fast their posts are spreading.

## Votes are weighted by the graph

A like is not worth the same from everyone. Trust here is **distance from an
immutable seed set**, not follower count: the seeds are at depth 0, accounts
they follow at depth 1, and so on outward. Weight falls with depth and reaches
zero past depth 6.

An account nobody reachable follows never gets a depth at all. It sits at 255,
weighs nothing, and can vote as much as it likes.

This is why buying followers does not work here. On the seeded network there
are a hundred wallets that follow each other — 9,900 follow edges between them
— and they gave five posts ninety-nine likes each. Those posts carry
`likeCount 99` and `weightedLikes 0`, and none of them reaches Explore's top
twenty.

Your own weight is on your profile page, read from the contract rather than
from our indexer — a trust score that arrived through an indexer is a trust
score you have to trust the indexer for.

## What is on chain

Posts, follows, likes, dislikes, the trust graph and every ranking contract.
The indexer holds no truth: wipe it and it rebuilds from the chain. It exists
because reading every post from a node to render a page would be slow, not
because it knows anything the chain does not.

Contract addresses are in [DEPLOYED.md](../DEPLOYED.md). No contract
has an admin function — including us.
