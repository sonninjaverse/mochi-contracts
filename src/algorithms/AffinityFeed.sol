// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {IFeedAlgorithm} from "../interfaces/IFeedAlgorithm.sol";
import {PostRegistry} from "../PostRegistry.sol";
import {SocialGraph} from "../SocialGraph.sol";
import {FeedSort} from "../lib/FeedSort.sol";

/// @notice Ranks by who the viewer actually engages with, not who they followed
///         once. This is roughly what commercial feeds do, except readable.
contract AffinityFeed is IFeedAlgorithm {
    SocialGraph public immutable graph;
    PostRegistry public immutable posts;

    uint256 private constant HALF_LIFE = 6 hours;

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

            uint256 affinity = posts.interactionCount(viewer, author);
            if (graph.followedAt(viewer, author) != 0) affinity += 1;
            if (affinity == 0) continue;

            uint256 age = block.timestamp > ps[i].createdAt ? block.timestamp - ps[i].createdAt : 0;
            uint256 recency = (HALF_LIFE * 1e18) / (HALF_LIFE + age);

            scores[i] = recency * affinity;
        }

        return FeedSort.byScoreDesc(ids, scores);
    }

    function name() external pure returns (string memory) {
        return "Affinity";
    }

    function description() external pure returns (string memory) {
        return "Weighted by who you actually interact with, not who you followed once.";
    }
}
