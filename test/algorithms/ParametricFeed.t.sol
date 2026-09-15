// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {ParametricFeed} from "../../src/algorithms/ParametricFeed.sol";
import {PostRegistry} from "../../src/PostRegistry.sol";
import {SocialGraph} from "../../src/SocialGraph.sol";

contract ParametricFeedTest is Test {
    ParametricFeed feed;
    PostRegistry posts;
    SocialGraph graph;
    address viewer = address(0xBEEF);
    address known = address(0xCAFE);
    address unknown = address(0x0DD);

    function setUp() public {
        address[] memory seeds = new address[](1);
        seeds[0] = viewer;
        graph = new SocialGraph(seeds);
        posts = new PostRegistry(graph);
        feed = new ParametricFeed(graph, posts);
    }

    function test_UnsetWeightsFallBackToDefaults() public view {
        ParametricFeed.Weights memory w = feed.weightsOf(viewer);
        assertEq(w.recency, 70);
        assertEq(w.familiarity, 30);
        assertEq(w.novelty, 80);
        assertEq(w.reach, 40);
    }

    function test_SetWeightsPersistsPerUser() public {
        vm.prank(viewer);
        feed.setWeights(10, 20, 30, 40);

        ParametricFeed.Weights memory w = feed.weightsOf(viewer);
        assertEq(w.recency, 10);
        assertEq(w.novelty, 30);

        ParametricFeed.Weights memory other = feed.weightsOf(unknown);
        assertEq(other.recency, 70); // untouched
    }

    function test_WeightAbove100Reverts() public {
        vm.prank(viewer);
        vm.expectRevert(ParametricFeed.WeightOutOfRange.selector);
        feed.setWeights(101, 0, 0, 0);
    }

    /// @dev Turning novelty all the way up and familiarity to zero must flip
    ///      the ordering relative to the opposite setting. This is the moment
    ///      the slider demo has to land.
    function test_WeightsChangeTheOrdering() public {
        vm.prank(viewer);
        graph.follow(known);

        vm.prank(known);
        uint256 familiarPost = posts.post("from someone you follow", "");
        vm.prank(unknown);
        uint256 strangePost = posts.post("from a stranger", "");

        uint256[] memory ids = new uint256[](2);
        ids[0] = familiarPost;
        ids[1] = strangePost;

        vm.prank(viewer);
        feed.setWeights(0, 100, 0, 0); // familiarity only
        (uint256[] memory familiarFirst,) = feed.rank(viewer, ids);
        assertEq(familiarFirst[0], familiarPost);

        vm.prank(viewer);
        feed.setWeights(0, 0, 100, 0); // novelty only
        (uint256[] memory strangeFirst,) = feed.rank(viewer, ids);
        assertEq(strangeFirst[0], strangePost);
    }

    /// @dev All-zero is indistinguishable from unset, so it falls back to the
    ///      defaults rather than producing an empty feed.
    function test_AllZeroWeightsFallsBackToDefaults() public {
        vm.prank(viewer);
        feed.setWeights(0, 0, 0, 0);

        ParametricFeed.Weights memory w = feed.weightsOf(viewer);
        assertEq(w.recency, 70);

        vm.prank(unknown);
        uint256 id = posts.post("a", "");
        uint256[] memory ids = new uint256[](1);
        ids[0] = id;

        (, uint256[] memory scores) = feed.rank(viewer, ids);
        assertGt(scores[0], 0);
    }

    function test_EmptyCandidatesDoesNotRevert() public view {
        uint256[] memory ids = new uint256[](0);
        (uint256[] memory out,) = feed.rank(viewer, ids);
        assertEq(out.length, 0);
    }
}
