// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {AffinityFeed} from "../../src/algorithms/AffinityFeed.sol";
import {PostRegistry} from "../../src/PostRegistry.sol";
import {SocialGraph} from "../../src/SocialGraph.sol";

contract AffinityFeedTest is Test {
    AffinityFeed feed;
    PostRegistry posts;
    SocialGraph graph;
    address viewer = address(0xBEEF);
    address engaged = address(0xE49);
    address ignored = address(0x1911);

    function setUp() public {
        address[] memory seeds = new address[](1);
        seeds[0] = viewer;
        graph = new SocialGraph(seeds);
        posts = new PostRegistry(graph);
        feed = new AffinityFeed(graph, posts);

        // Viewer follows both, but only ever engages with one of them.
        vm.startPrank(viewer);
        graph.follow(engaged);
        graph.follow(ignored);
        vm.stopPrank();
    }

    /// @dev The distinction that matters: following is a one-time act, engaging
    ///      is a repeated one. This ranks by the second.
    function test_EngagedAuthorOutranksMerelyFollowedAuthor() public {
        vm.prank(engaged);
        uint256 warm = posts.post("from someone you talk to", "");
        vm.prank(viewer);
        posts.like(warm);

        vm.prank(ignored);
        uint256 cold = posts.post("from someone you only followed", "");

        uint256[] memory ids = new uint256[](2);
        ids[0] = cold;
        ids[1] = warm;

        (uint256[] memory out,) = feed.rank(viewer, ids);
        assertEq(out[0], warm);
    }

    function test_FollowedButNeverEngagedStillScores() public {
        vm.prank(ignored);
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
