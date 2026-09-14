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

    function test_SeedsStartAtDepthZero() public {
        address[] memory seeds = new address[](1);
        seeds[0] = alice;
        SocialGraph g = new SocialGraph(seeds);

        assertEq(g.depthOf(alice), 0);
        assertEq(g.weightOf(alice), 100);
    }

    function test_DepthFlowsOutwardFromSeed() public {
        address[] memory seeds = new address[](1);
        seeds[0] = alice;
        SocialGraph g = new SocialGraph(seeds);

        address c = address(0xC);
        address d = address(0xD);

        vm.prank(alice);
        g.follow(bob); // bob reachable at depth 1
        vm.prank(bob);
        g.follow(c); // c at depth 2
        vm.prank(c);
        g.follow(d); // d at depth 3

        assertEq(g.depthOf(bob), 1);
        assertEq(g.depthOf(c), 2);
        assertEq(g.depthOf(d), 3);
        assertEq(g.weightOf(bob), 100);
        assertEq(g.weightOf(d), 40);
    }

    function test_UnreachedAccountHasZeroWeight() public view {
        assertEq(graph.depthOf(bob), graph.UNREACHED());
        assertEq(graph.weightOf(bob), 0);
    }

    /// @dev The headline property: a cross-following ring that no reachable
    ///      account ever follows stays sealed off no matter how dense it is.
    function test_SybilRing_NeverGainsDepth() public {
        address[] memory seeds = new address[](1);
        seeds[0] = alice;
        SocialGraph g = new SocialGraph(seeds);

        address[] memory ring = new address[](100);
        for (uint256 i; i < 100; ++i) {
            ring[i] = address(uint160(0x5117000 + i));
        }
        // every member follows every other member: 9,900 edges
        for (uint256 i; i < 100; ++i) {
            vm.startPrank(ring[i]);
            for (uint256 j; j < 100; ++j) {
                if (i != j) g.follow(ring[j]);
            }
            vm.stopPrank();
        }

        for (uint256 i; i < 100; ++i) {
            assertEq(g.depthOf(ring[i]), g.UNREACHED());
            assertEq(g.weightOf(ring[i]), 0);
        }
    }

    function test_RingMemberGainsDepthOnlyViaReachableFollower() public {
        address[] memory seeds = new address[](1);
        seeds[0] = alice;
        SocialGraph g = new SocialGraph(seeds);

        address sybil = address(0x5117001);
        vm.prank(alice);
        g.follow(sybil);

        assertEq(g.depthOf(sybil), 1);
    }

    function test_DepthNeverIncreases() public {
        address[] memory seeds = new address[](1);
        seeds[0] = alice;
        SocialGraph g = new SocialGraph(seeds);

        address c = address(0xC);
        vm.prank(alice);
        g.follow(bob); // bob -> 1
        vm.prank(bob);
        g.follow(c); // c -> 2

        uint8 before = g.depthOf(c);
        vm.prank(c);
        g.follow(bob); // cycle back; must not worsen bob
        assertEq(g.depthOf(bob), 1);
        assertEq(g.depthOf(c), before);
    }

    function test_RefreshLowersDepthAfterShorterPathAppears() public {
        address[] memory seeds = new address[](1);
        seeds[0] = alice;
        SocialGraph g = new SocialGraph(seeds);

        address c = address(0xC);
        vm.prank(bob);
        g.follow(c); // bob unreached, so c gains nothing
        assertEq(g.depthOf(c), g.UNREACHED());

        vm.prank(alice);
        g.follow(bob); // bob now depth 1, but c was not updated retroactively
        assertEq(g.depthOf(c), g.UNREACHED());

        g.refresh(c, bob); // anyone may call
        assertEq(g.depthOf(c), 2);
    }

    function test_RefreshDoesNothingWhenEdgeAbsent() public {
        address[] memory seeds = new address[](1);
        seeds[0] = alice;
        SocialGraph g = new SocialGraph(seeds);

        address c = address(0xC);
        g.refresh(c, alice); // alice never followed c
        assertEq(g.depthOf(c), g.UNREACHED());
    }
}
