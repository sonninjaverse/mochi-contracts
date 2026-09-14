// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {SocialGraph} from "../src/SocialGraph.sol";

contract SocialGraphTest is Test {
    SocialGraph graph;
    address alice = address(0xA11CE);
    address bob = address(0xB0B);

    function setUp() public {
        address[] memory seeds = new address[](0);
        graph = new SocialGraph(seeds);
    }

    function test_FollowRecordsTimestampAndCounts() public {
        vm.prank(alice);
        graph.follow(bob);

        assertEq(graph.followedAt(alice, bob), uint64(block.timestamp));
        assertEq(graph.followingCount(alice), 1);
        assertEq(graph.followerCount(bob), 1);
    }

    function test_UnfollowClearsTimestampAndCounts() public {
        vm.startPrank(alice);
        graph.follow(bob);
        graph.unfollow(bob);
        vm.stopPrank();

        assertEq(graph.followedAt(alice, bob), 0);
        assertEq(graph.followingCount(alice), 0);
        assertEq(graph.followerCount(bob), 0);
    }

    function test_DoubleFollowDoesNotDoubleCount() public {
        vm.startPrank(alice);
        graph.follow(bob);
        graph.follow(bob);
        vm.stopPrank();

        assertEq(graph.followingCount(alice), 1);
        assertEq(graph.followerCount(bob), 1);
    }

    function test_CannotFollowSelf() public {
        vm.prank(alice);
        vm.expectRevert(SocialGraph.CannotFollowSelf.selector);
        graph.follow(alice);
    }

    function test_UnfollowWhenNotFollowingIsNoop() public {
        vm.prank(alice);
        graph.unfollow(bob);
        assertEq(graph.followerCount(bob), 0);
    }
}
