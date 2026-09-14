// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {IFeedAlgorithm} from "../interfaces/IFeedAlgorithm.sol";
import {PostRegistry} from "../PostRegistry.sol";
import {SocialGraph} from "../SocialGraph.sol";
import {FeedSort} from "../lib/FeedSort.sol";

/// @notice Posts from accounts the viewer follows, newest weighted highest.
/// @dev What most people assume they are already getting.
contract FollowFeed is IFeedAlgorithm {
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
            if (graph.followedAt(viewer, author) == 0) continue;

            // Guarded subtraction: a future timestamp must not underflow, or
            // the whole feed would revert and render blank.
            uint256 age = block.timestamp > ps[i].createdAt ? block.timestamp - ps[i].createdAt : 0;

            scores[i] = (HALF_LIFE * 1e18) / (HALF_LIFE + age);
        }

        return FeedSort.byScoreDesc(ids, scores);
    }

    function name() external pure returns (string memory) {
        return "Follow";
    }

    function description() external pure returns (string memory) {
        return "Only accounts you follow, most recent first.";
    }
}
