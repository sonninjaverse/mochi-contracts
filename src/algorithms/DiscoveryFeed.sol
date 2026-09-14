// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {IFeedAlgorithm} from "../interfaces/IFeedAlgorithm.sol";
import {PostRegistry} from "../PostRegistry.sol";
import {SocialGraph} from "../SocialGraph.sol";
import {FeedSort} from "../lib/FeedSort.sol";

/// @notice Default algorithm for the Explore tab: accounts the viewer does not
///         follow yet, ranked by how fast their posts are spreading.
/// @dev Explore is not a hardcoded product feature. It is a second algorithm
///      slot, and a viewer may point it at any contract they like.
contract DiscoveryFeed is IFeedAlgorithm {
    SocialGraph public immutable graph;
    PostRegistry public immutable posts;

    uint256 private constant WINDOW = 24 hours;
    uint256 private constant FLOOR = 10 minutes;

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
            if (graph.followedAt(viewer, author) != 0) continue;

            uint256 age = block.timestamp > ps[i].createdAt ? block.timestamp - ps[i].createdAt : 0;
            if (age > WINDOW) continue;

            // Spread rate rather than total likes, so a good post from ten
            // minutes ago can beat an old one that merely accumulated more.
            // FLOOR in the denominator prevents division by zero and stops a
            // three-second-old post with one like from topping the feed.
            scores[i] = (uint256(ps[i].weightedLikes) * 1e18) / (age + FLOOR);
        }

        return FeedSort.byScoreDesc(ids, scores);
    }

    function name() external pure returns (string memory) {
        return "Discovery";
    }

    function description() external pure returns (string memory) {
        return "People you do not follow yet, ranked by how fast their posts are spreading.";
    }
}
