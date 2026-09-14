// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {SerendipityFeed} from "../../src/algorithms/SerendipityFeed.sol";
import {PostRegistry} from "../../src/PostRegistry.sol";
import {SocialGraph} from "../../src/SocialGraph.sol";

contract SerendipityFeedTest is Test {
    SerendipityFeed feed;
    PostRegistry posts;
    SocialGraph graph;
    address viewer = address(0xBEEF);
    address familiar = address(0xFA111);
    address unknown = address(0x0DD);

    function setUp() public {
        address[] memory seeds = new address[](1);
        seeds[0] = viewer;
        graph = new SocialGraph(seeds);
        posts = new PostRegistry(graph);
        feed = new SerendipityFeed(graph, posts);
    }

    /// @dev The inversion: being familiar is a penalty, not a bonus.
    function test_UnfamiliarAuthorOutranksFamiliarAtEqualReach() public {
        vm.prank(viewer);
        graph.follow(familiar);

        vm.prank(familiar);
        uint256 known = posts.post("from someone you know");
        vm.prank(unknown);
        uint256 fresh = posts.post("from someone new");

        uint256[] memory ids = new uint256[](2);
        ids[0] = known;
        ids[1] = fresh;

        (uint256[] memory out,) = feed.rank(viewer, ids);
        assertEq(out[0], fresh);
    }

    /// @dev Cold start falls out of the formula rather than a special case:
    ///      with no follows, familiarity is zero everywhere and the score
    ///      collapses to recency times reach, which is a trending feed.
    function test_ViewerWithNoFollowsGetsTrendingOrder() public {
        address liker = address(0x11CE);
        vm.prank(viewer);
        graph.follow(liker); // give liker weight so weightedLikes moves

        vm.prank(unknown);
        uint256 quiet = posts.post("quiet");
        vm.prank(familiar);
        uint256 popular = posts.post("popular");

        vm.prank(liker);
        posts.like(popular);

        address fresh = address(0xF2E5);
        uint256[] memory ids = new uint256[](2);
        ids[0] = quiet;
        ids[1] = popular;

        (uint256[] memory out,) = feed.rank(fresh, ids);
        assertEq(out[0], popular);
    }

    function test_ViewerOwnPostsAreExcluded() public {
        vm.prank(viewer);
        uint256 mine = posts.post("mine");

        uint256[] memory ids = new uint256[](1);
        ids[0] = mine;

        (, uint256[] memory scores) = feed.rank(viewer, ids);
        assertEq(scores[0], 0);
    }

    function test_EmptyCandidatesDoesNotRevert() public view {
        uint256[] memory ids = new uint256[](0);
        (uint256[] memory out,) = feed.rank(viewer, ids);
        assertEq(out.length, 0);
    }

    function test_MetadataStrings() public view {
        assertEq(feed.name(), "Serendipity");
        assertGt(bytes(feed.description()).length, 0);
    }
}
