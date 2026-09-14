// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {IFeedAlgorithm} from "../interfaces/IFeedAlgorithm.sol";
import {PostRegistry} from "../PostRegistry.sol";
import {SocialGraph} from "../SocialGraph.sol";
import {FeedSort} from "../lib/FeedSort.sol";

/// @notice Deliberately down-ranks accounts the viewer already knows.
/// @dev The default algorithm for new accounts. No advertising platform ships
///      this, because breaking the filter bubble lowers engagement.
///
///      It also solves cold start without a special case: a viewer who follows
///      nobody has zero familiarity with everyone, so novelty is uniform and
///      the score reduces to recency times reach, i.e. a trending feed.
contract SerendipityFeed is IFeedAlgorithm {
    SocialGraph public immutable graph;
    PostRegistry public immutable posts;

    uint256 private constant HALF_LIFE = 6 hours;
    uint256 private constant FOLLOW_PENALTY = 5;

    constructor(SocialGraph graph_, PostRegistry posts_) {
        graph = graph_;
        posts = posts_;
    }

    function rank(address viewer, uint256[] calldata candidateIds)
        external
        view
        returns (uint256[] memory, uint256[] memory)
    {
        PostRegistry.Post[] memory ps = posts.postsOf(candidateIds);

        uint256[] memory ids = new uint256[](candidateIds.length);
        uint256[] memory scores = new uint256[](candidateIds.length);

        for (uint256 i; i < candidateIds.length; ++i) {
            ids[i] = candidateIds[i];

            address author = ps[i].author;
            if (author == address(0) || author == viewer) continue;

            uint256 age = block.timestamp > ps[i].createdAt ? block.timestamp - ps[i].createdAt : 0;
            uint256 recency = (HALF_LIFE * 1e18) / (HALF_LIFE + age);

            // weightedLikes, not likeCount: a sybil ring moves the raw counter
            // but carries no weight, so it cannot buy its way into this feed.
            uint256 reach = (uint256(ps[i].weightedLikes) + 1) * 1e18;

            uint256 familiarity = posts.interactionCount(viewer, author);
            if (graph.followedAt(viewer, author) != 0) familiarity += FOLLOW_PENALTY;
            uint256 novelty = 1e18 / (1 + familiarity);

            scores[i] = recency * reach / 1e18 * novelty / 1e18;
        }

        return FeedSort.byScoreDesc(ids, scores);
    }

    function name() external pure returns (string memory) {
        return "Serendipity";
    }

    function description() external pure returns (string memory) {
        return "Down-ranks people you already know. Built to break your bubble, not reinforce it.";
    }
}
