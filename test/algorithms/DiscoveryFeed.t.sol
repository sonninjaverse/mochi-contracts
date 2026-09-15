// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {DiscoveryFeed} from "../../src/algorithms/DiscoveryFeed.sol";
import {PostRegistry} from "../../src/PostRegistry.sol";
import {SocialGraph} from "../../src/SocialGraph.sol";

contract DiscoveryFeedTest is Test {
    DiscoveryFeed feed;
    PostRegistry posts;
    SocialGraph graph;
    address viewer = address(0xBEEF);
    address followed = address(0xF0110);
    address stranger = address(0x57A1);
    address liker = address(0x11CE);

    function setUp() public {
        address[] memory seeds = new address[](1);
        seeds[0] = viewer;
        graph = new SocialGraph(seeds);
        posts = new PostRegistry(graph);
        feed = new DiscoveryFeed(graph, posts);

        vm.startPrank(viewer);
        graph.follow(followed);
        graph.follow(liker); // give liker weight
        vm.stopPrank();
    }

    /// @dev Explore is for finding people you do not already follow.
    function test_AlreadyFollowedAuthorsAreExcluded() public {
        vm.prank(followed);
        uint256 id = posts.post("a", "");
        vm.prank(liker);
        posts.like(id);

        uint256[] memory ids = new uint256[](1);
        ids[0] = id;

        (, uint256[] memory scores) = feed.rank(viewer, ids);
        assertEq(scores[0], 0);
    }

    /// @dev Velocity, not total likes: a good post from ten minutes ago should
    ///      beat an older post that merely accumulated more.
    function test_FasterSpreadOutranksOlderWithMoreLikes() public {
        vm.prank(stranger);
        uint256 old = posts.post("old but liked", "");
        vm.prank(liker);
        posts.like(old);

        vm.warp(block.timestamp + 12 hours);

        address stranger2 = address(0x57A2);
        address liker2 = address(0x11C2);
        vm.prank(viewer);
        graph.follow(liker2);

        vm.prank(stranger2);
        uint256 fresh = posts.post("new and liked", "");
        vm.prank(liker2);
        posts.like(fresh);

        uint256[] memory ids = new uint256[](2);
        ids[0] = old;
        ids[1] = fresh;

        (uint256[] memory out,) = feed.rank(viewer, ids);
        assertEq(out[0], fresh);
    }

    function test_PostsOlderThanWindowScoreZero() public {
        vm.prank(stranger);
        uint256 id = posts.post("ancient", "");
        vm.prank(liker);
        posts.like(id);

        vm.warp(block.timestamp + 25 hours);

        uint256[] memory ids = new uint256[](1);
        ids[0] = id;

        (, uint256[] memory scores) = feed.rank(viewer, ids);
        assertEq(scores[0], 0);
    }

    /// @dev A ring of unreachable wallets can like each other all day and
    ///      still contributes nothing, because weightedLikes stays zero.
    function test_SybilLikesDoNotSurfacePost() public {
        vm.prank(stranger);
        uint256 id = posts.post("sybil boosted", "");

        for (uint256 i; i < 50; ++i) {
            vm.prank(address(uint160(0x5117000 + i)));
            posts.like(id);
        }

        uint256[] memory ids = new uint256[](1);
        ids[0] = id;

        (, uint256[] memory scores) = feed.rank(viewer, ids);
        assertEq(posts.postOf(id).likeCount, 50);
        assertEq(posts.postOf(id).weightedLikes, 0);
        assertEq(scores[0], 0);
    }

    function test_EmptyCandidatesDoesNotRevert() public view {
        uint256[] memory ids = new uint256[](0);
        (uint256[] memory out,) = feed.rank(viewer, ids);
        assertEq(out.length, 0);
    }
}
