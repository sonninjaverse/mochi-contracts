// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {SocialGraph} from "../src/SocialGraph.sol";
import {PostRegistry} from "../src/PostRegistry.sol";
import {IFeedAlgorithm} from "../src/interfaces/IFeedAlgorithm.sol";
import {ChronoFeed} from "../src/algorithms/ChronoFeed.sol";
import {FollowFeed} from "../src/algorithms/FollowFeed.sol";
import {AffinityFeed} from "../src/algorithms/AffinityFeed.sol";
import {SerendipityFeed} from "../src/algorithms/SerendipityFeed.sol";
import {DiscoveryFeed} from "../src/algorithms/DiscoveryFeed.sol";
import {ParametricFeed} from "../src/algorithms/ParametricFeed.sol";

/// @notice A reverting rank() renders as a blank feed, so every shipped
///         algorithm must tolerate any input the client can produce.
contract RankNeverRevertsTest is Test {
    SocialGraph graph;
    PostRegistry posts;
    IFeedAlgorithm[] algos;

    address seed = address(0x5EED);
    address author = address(0xA07);

    function setUp() public {
        address[] memory seeds = new address[](1);
        seeds[0] = seed;
        graph = new SocialGraph(seeds);
        posts = new PostRegistry(graph);

        algos.push(new ChronoFeed(posts));
        algos.push(new FollowFeed(graph, posts));
        algos.push(new AffinityFeed(graph, posts));
        algos.push(new SerendipityFeed(graph, posts));
        algos.push(new DiscoveryFeed(graph, posts));
        algos.push(new ParametricFeed(graph, posts));

        vm.prank(seed);
        graph.follow(author);
        for (uint256 i; i < 5; ++i) {
            vm.prank(author);
            posts.post("a post");
        }
    }

    /// @dev Covers unknown ids, id zero, duplicates and arbitrary viewers.
    function testFuzz_NoAlgorithmRevertsOnArbitraryInput(uint256[16] memory rawIds, address viewer)
        public
        view
    {
        uint256[] memory ids = new uint256[](16);
        for (uint256 i; i < 16; ++i) {
            ids[i] = rawIds[i];
        }

        for (uint256 a; a < algos.length; ++a) {
            (uint256[] memory out, uint256[] memory scores) = algos[a].rank(viewer, ids);
            assertEq(out.length, 16);
            assertEq(scores.length, 16);
        }
    }

    function test_NoAlgorithmRevertsOnEmptyInput() public view {
        uint256[] memory ids = new uint256[](0);
        for (uint256 a; a < algos.length; ++a) {
            (uint256[] memory out,) = algos[a].rank(address(0), ids);
            assertEq(out.length, 0);
        }
    }

    /// @dev A post timestamped in the future must not underflow the age maths.
    function test_NoAlgorithmRevertsOnFutureTimestamp() public {
        vm.prank(author);
        uint256 id = posts.post("from the future");

        uint256[] memory ids = new uint256[](1);
        ids[0] = id;

        vm.warp(1); // now earlier than createdAt
        for (uint256 a; a < algos.length; ++a) {
            algos[a].rank(seed, ids);
        }
    }
}
