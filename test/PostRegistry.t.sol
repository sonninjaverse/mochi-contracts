// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test, Vm} from "forge-std/Test.sol";
import {PostRegistry} from "../src/PostRegistry.sol";
import {SocialGraph} from "../src/SocialGraph.sol";

contract PostRegistryTest is Test {
    PostRegistry posts;
    SocialGraph graph;
    address alice = address(0xA11CE);

    function setUp() public {
        address[] memory seeds = new address[](1);
        seeds[0] = alice;
        graph = new SocialGraph(seeds);
        posts = new PostRegistry(graph);
    }

    function test_PostStoresMetadata() public {
        vm.prank(alice);
        uint256 id = posts.post("hello monad");

        PostRegistry.Post memory p = posts.postOf(id);
        assertEq(p.author, alice);
        assertEq(p.createdAt, uint48(block.timestamp));
        assertEq(p.likeCount, 0);
        assertEq(p.weightedLikes, 0);
    }

    function test_PostIdsIncrementFromOne() public {
        vm.startPrank(alice);
        assertEq(posts.post("a"), 1);
        assertEq(posts.post("b"), 2);
        vm.stopPrank();
    }

    /// @dev Zero is reserved as "no parent", so ids must start at 1.
    function test_ZeroIdIsEmptyPost() public view {
        PostRegistry.Post memory p = posts.postOf(0);
        assertEq(p.author, address(0));
    }

    /// @dev Text must never reach storage. It exists only in the event.
    function test_TextIsEmittedNotStored() public {
        vm.recordLogs();
        vm.prank(alice);
        posts.post("hello monad");

        Vm.Log[] memory logs = vm.getRecordedLogs();
        assertEq(logs.length, 1);
        (, string memory text) = abi.decode(logs[0].data, (uint48, string));
        assertEq(text, "hello monad");
    }

    function test_EmptyTextReverts() public {
        vm.prank(alice);
        vm.expectRevert(PostRegistry.EmptyText.selector);
        posts.post("");
    }

    /// @dev v1 ships likes only; these counters exist for a later version.
    function test_RepostAndReplyCountersStayZero() public {
        vm.prank(alice);
        uint256 id = posts.post("a");

        PostRegistry.Post memory p = posts.postOf(id);
        assertEq(p.repostCount, 0);
        assertEq(p.replyCount, 0);
        assertEq(p.parentId, 0);
    }
}
