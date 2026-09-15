// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {FollowFeed} from "../../src/algorithms/FollowFeed.sol";
import {PostRegistry} from "../../src/PostRegistry.sol";
import {SocialGraph} from "../../src/SocialGraph.sol";

contract FollowFeedTest is Test {
    FollowFeed feed;
    PostRegistry posts;
    SocialGraph graph;
    address viewer = address(0xBEEF);
    address followed = address(0xF0110);
    address stranger = address(0x57A1);

    function setUp() public {
        address[] memory seeds = new address[](1);
        seeds[0] = viewer;
        graph = new SocialGraph(seeds);
        posts = new PostRegistry(graph);
        feed = new FollowFeed(graph, posts);

        vm.prank(viewer);
        graph.follow(followed);
    }

    function test_OnlyFollowedAuthorsScore() public {
        vm.prank(stranger);
        uint256 s = posts.post("from a stranger", "");
        vm.prank(followed);
        uint256 f = posts.post("from someone followed", "");

        uint256[] memory ids = new uint256[](2);
        ids[0] = s;
        ids[1] = f;

        (uint256[] memory out, uint256[] memory scores) = feed.rank(viewer, ids);
        assertEq(out[0], f);
        assertGt(scores[0], 0);
        assertEq(scores[1], 0);
    }

    function test_NewerFollowedPostOutranksOlder() public {
        vm.prank(followed);
        uint256 older = posts.post("old", "");
        vm.warp(block.timestamp + 1 days);
        vm.prank(followed);
        uint256 newer = posts.post("new", "");

        uint256[] memory ids = new uint256[](2);
        ids[0] = older;
        ids[1] = newer;

        (uint256[] memory out,) = feed.rank(viewer, ids);
        assertEq(out[0], newer);
    }

    /// @dev A viewer who follows nobody gets an empty feed, and that is correct:
    ///      it is precisely what this algorithm means. The UI must say so.
    function test_ViewerFollowingNobodyScoresEverythingZero() public {
        vm.prank(followed);
        uint256 id = posts.post("a", "");

        uint256[] memory ids = new uint256[](1);
        ids[0] = id;

        (, uint256[] memory scores) = feed.rank(stranger, ids);
        assertEq(scores[0], 0);
    }

    function test_EmptyCandidatesDoesNotRevert() public view {
        uint256[] memory ids = new uint256[](0);
        (uint256[] memory out,) = feed.rank(viewer, ids);
        assertEq(out.length, 0);
    }
}
