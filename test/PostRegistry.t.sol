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
        uint256 id = posts.post("hello monad", "");

        PostRegistry.Post memory p = posts.postOf(id);
        assertEq(p.author, alice);
        assertEq(p.createdAt, uint48(block.timestamp));
        assertEq(p.likeCount, 0);
        assertEq(p.weightedLikes, 0);
    }

    function test_PostIdsIncrementFromOne() public {
        vm.startPrank(alice);
        assertEq(posts.post("a", ""), 1);
        assertEq(posts.post("b", ""), 2);
        vm.stopPrank();
    }

    /// @dev Zero is reserved as "no parent", so ids must start at 1.
    function test_ZeroIdIsEmptyPost() public view {
        PostRegistry.Post memory p = posts.postOf(0);
        assertEq(p.author, address(0));
    }

    /// @dev Text and media are the two things storage never sees: no ranking reads
    /// either, and a post costs the same whatever it says.
    function test_TextAndMediaAreEmittedNotStored() public {
        vm.recordLogs();
        vm.prank(alice);
        posts.post("hello monad", "ipfs://bafyabc");

        Vm.Log[] memory logs = vm.getRecordedLogs();
        assertEq(logs.length, 1);
        (,, string memory text, string memory media) =
            abi.decode(logs[0].data, (uint48, uint48, string, string));
        assertEq(text, "hello monad");
        assertEq(media, "ipfs://bafyabc");
    }

    function test_EmptyTextReverts() public {
        vm.prank(alice);
        vm.expectRevert(PostRegistry.EmptyText.selector);
        posts.post("", "");
    }

    /// @dev A top-level post has no parent and no replies until it gets one.
    ///      repostCount is still unused.
    function test_RepostAndReplyCountersStayZero() public {
        vm.prank(alice);
        uint256 id = posts.post("a", "");

        PostRegistry.Post memory p = posts.postOf(id);
        assertEq(p.repostCount, 0);
        assertEq(p.replyCount, 0);
        assertEq(p.parentId, 0);
    }

    function test_LikeIncrementsBothCounters() public {
        vm.prank(alice);
        uint256 id = posts.post("a", "");

        address bob = address(0xB0B);
        vm.prank(alice);
        graph.follow(bob); // bob reaches depth 1, weight 100

        vm.prank(bob);
        posts.like(id);

        PostRegistry.Post memory p = posts.postOf(id);
        assertEq(p.likeCount, 1);
        assertEq(p.weightedLikes, 100);
        assertTrue(posts.hasLiked(id, bob));
    }

    /// @dev The whole point of weightedLikes: an unreachable account can like,
    ///      and the raw count moves, but it contributes no discovery weight.
    function test_UnreachedLikerAddsNoWeight() public {
        vm.prank(alice);
        uint256 id = posts.post("a", "");

        address sybil = address(0x5117);
        vm.prank(sybil);
        posts.like(id);

        PostRegistry.Post memory p = posts.postOf(id);
        assertEq(p.likeCount, 1);
        assertEq(p.weightedLikes, 0);
    }

    function test_DoubleLikeIsNoop() public {
        vm.prank(alice);
        uint256 id = posts.post("a", "");

        vm.startPrank(alice);
        posts.like(id);
        posts.like(id);
        vm.stopPrank();

        assertEq(posts.postOf(id).likeCount, 1);
    }

    function test_UnlikeReversesBothCounters() public {
        vm.prank(alice);
        uint256 id = posts.post("a", "");

        vm.startPrank(alice);
        posts.like(id);
        posts.unlike(id);
        vm.stopPrank();

        PostRegistry.Post memory p = posts.postOf(id);
        assertEq(p.likeCount, 0);
        assertEq(p.weightedLikes, 0);
        assertFalse(posts.hasLiked(id, alice));
    }

    function test_LikeRecordsInteractionTowardAuthor() public {
        vm.prank(alice);
        uint256 id = posts.post("a", "");

        address bob = address(0xB0B);
        vm.prank(bob);
        posts.like(id);

        assertEq(posts.interactionCount(bob, alice), 1);
    }

    /// @dev Unliking must not rewrite history: affinity reflects that the
    ///      interaction happened, not whether the like currently stands.
    function test_UnlikeDoesNotDecrementInteraction() public {
        vm.prank(alice);
        uint256 id = posts.post("a", "");

        address bob = address(0xB0B);
        vm.startPrank(bob);
        posts.like(id);
        posts.unlike(id);
        vm.stopPrank();

        assertEq(posts.interactionCount(bob, alice), 1);
    }

    function test_LikingNonexistentPostReverts() public {
        vm.prank(alice);
        vm.expectRevert(PostRegistry.NoSuchPost.selector);
        posts.like(999);
    }

    function test_PostsOfReturnsAllInOrder() public {
        vm.startPrank(alice);
        uint256 a = posts.post("a", "");
        uint256 b = posts.post("b", "");
        vm.stopPrank();

        uint256[] memory ids = new uint256[](2);
        ids[0] = b;
        ids[1] = a;

        PostRegistry.Post[] memory got = posts.postsOf(ids);
        assertEq(got.length, 2);
        assertEq(got[0].author, alice);
        assertEq(got[1].createdAt, posts.postOf(a).createdAt);
    }

    function test_PostsOfWithUnknownIdReturnsEmptyStruct() public view {
        uint256[] memory ids = new uint256[](1);
        ids[0] = 12345;
        PostRegistry.Post[] memory got = posts.postsOf(ids);
        assertEq(got[0].author, address(0));
    }

    function test_DislikeIncrementsBothCounters() public {
        vm.prank(alice);
        uint256 id = posts.post("a", "");

        address bob = address(0xB0B);
        vm.prank(alice);
        graph.follow(bob); // depth 1, weight 100

        vm.prank(bob);
        posts.dislike(id);

        PostRegistry.Post memory p = posts.postOf(id);
        assertEq(p.dislikeCount, 1);
        assertEq(p.weightedDislikes, 100);
        assertTrue(posts.hasDisliked(id, bob));
    }

    /// The property that makes dislikes safe to add: a ring can no more bury
    /// someone than it can promote them.
    function test_UnreachedDislikerAddsNoWeight() public {
        vm.prank(alice);
        uint256 id = posts.post("a", "");

        vm.prank(address(0x5117));
        posts.dislike(id);

        PostRegistry.Post memory p = posts.postOf(id);
        assertEq(p.dislikeCount, 1);
        assertEq(p.weightedDislikes, 0);
    }

    /// A vote is one direction at a time, as on Reddit.
    function test_LikingAfterDislikingWithdrawsTheDislike() public {
        vm.prank(alice);
        uint256 id = posts.post("a", "");

        address bob = address(0xB0B);
        vm.prank(alice);
        graph.follow(bob);

        vm.startPrank(bob);
        posts.dislike(id);
        posts.like(id);
        vm.stopPrank();

        PostRegistry.Post memory p = posts.postOf(id);
        assertEq(p.likeCount, 1);
        assertEq(p.dislikeCount, 0);
        assertEq(p.weightedLikes, 100);
        assertEq(p.weightedDislikes, 0);
        assertFalse(posts.hasDisliked(id, bob));
    }

    function test_DislikingAfterLikingWithdrawsTheLike() public {
        vm.prank(alice);
        uint256 id = posts.post("a", "");

        address bob = address(0xB0B);
        vm.prank(alice);
        graph.follow(bob);

        vm.startPrank(bob);
        posts.like(id);
        posts.dislike(id);
        vm.stopPrank();

        PostRegistry.Post memory p = posts.postOf(id);
        assertEq(p.likeCount, 0);
        assertEq(p.dislikeCount, 1);
    }

    function test_UndislikeReverses() public {
        vm.prank(alice);
        uint256 id = posts.post("a", "");

        vm.startPrank(alice);
        posts.dislike(id);
        posts.undislike(id);
        vm.stopPrank();

        PostRegistry.Post memory p = posts.postOf(id);
        assertEq(p.dislikeCount, 0);
        assertEq(p.weightedDislikes, 0);
        assertFalse(posts.hasDisliked(id, alice));
    }

    function test_DoubleDislikeIsNoop() public {
        vm.prank(alice);
        uint256 id = posts.post("a", "");

        vm.startPrank(alice);
        posts.dislike(id);
        posts.dislike(id);
        vm.stopPrank();

        assertEq(posts.postOf(id).dislikeCount, 1);
    }

    function test_DislikingNonexistentPostReverts() public {
        vm.prank(alice);
        vm.expectRevert(PostRegistry.NoSuchPost.selector);
        posts.dislike(999);
    }
}
