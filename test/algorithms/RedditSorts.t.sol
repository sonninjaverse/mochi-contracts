// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {BestFeed} from "../../src/algorithms/BestFeed.sol";
import {ControversialFeed} from "../../src/algorithms/ControversialFeed.sol";
import {PostRegistry} from "../../src/PostRegistry.sol";
import {SocialGraph} from "../../src/SocialGraph.sol";

contract RedditSortsTest is Test {
    BestFeed best;
    ControversialFeed controversial;
    PostRegistry posts;
    SocialGraph graph;

    address seed = address(0x5EED);
    address author = address(0xA07);
    uint256 nextVoter = 0xC0FFEE0;

    function setUp() public {
        address[] memory seeds = new address[](1);
        seeds[0] = seed;
        graph = new SocialGraph(seeds);
        posts = new PostRegistry(graph);
        best = new BestFeed(posts);
        controversial = new ControversialFeed(posts);
    }

    /// A fresh reachable voter, so every vote carries full weight.
    function voter() internal returns (address a) {
        a = address(uint160(nextVoter++));
        vm.prank(seed);
        graph.follow(a);
    }

    function vote(uint256 id, uint256 ups, uint256 downs) internal {
        for (uint256 i; i < ups; ++i) {
            vm.prank(voter());
            posts.like(id);
        }
        for (uint256 i; i < downs; ++i) {
            vm.prank(voter());
            posts.dislike(id);
        }
    }

    /**
     * @dev The reason Reddit uses a confidence bound at all: a perfect record
     *      over two votes is weaker evidence than a good record over hundreds,
     *      and a plain average says the opposite.
     */
    function test_BestPrefersEvidenceOverAverage() public {
        vm.startPrank(author);
        uint256 thin = posts.post("two likes, no dislikes");
        uint256 thick = posts.post("ninety likes, ten dislikes");
        vm.stopPrank();

        vote(thin, 2, 0);
        vote(thick, 90, 10);

        uint256[] memory ids = new uint256[](2);
        ids[0] = thin;
        ids[1] = thick;

        (uint256[] memory out,) = best.rank(address(1), ids);
        assertEq(out[0], thick, "the better-evidenced post should win");
    }

    function test_BestScoresNothingWithNoVotes() public {
        vm.prank(author);
        uint256 id = posts.post("silent");

        uint256[] memory ids = new uint256[](1);
        ids[0] = id;

        (, uint256[] memory scores) = best.rank(address(1), ids);
        assertEq(scores[0], 0);
    }

    function test_BestRisesWithMoreAgreement() public {
        vm.startPrank(author);
        uint256 few = posts.post("few");
        uint256 many = posts.post("many");
        vm.stopPrank();

        vote(few, 5, 1);
        vote(many, 50, 10); // same ratio, ten times the evidence

        uint256[] memory ids = new uint256[](2);
        ids[0] = few;
        ids[1] = many;

        (uint256[] memory out,) = best.rank(address(1), ids);
        assertEq(out[0], many);
    }

    /// Agreement is not controversy, however loud.
    function test_ControversialIgnoresUnanimousPosts() public {
        vm.startPrank(author);
        uint256 loved = posts.post("everyone agrees");
        uint256 split = posts.post("nobody agrees");
        vm.stopPrank();

        vote(loved, 40, 0);
        vote(split, 10, 9);

        uint256[] memory ids = new uint256[](2);
        ids[0] = loved;
        ids[1] = split;

        (uint256[] memory out, uint256[] memory scores) = controversial.rank(address(1), ids);
        assertEq(out[0], split);
        assertEq(scores[1], 0, "a unanimous post is not controversial at any volume");
    }

    function test_ControversialPrefersTheEvenerSplit() public {
        vm.startPrank(author);
        uint256 lopsided = posts.post("mostly agreed");
        uint256 even = posts.post("evenly split");
        vm.stopPrank();

        vote(lopsided, 18, 2);
        vote(even, 10, 10);

        uint256[] memory ids = new uint256[](2);
        ids[0] = lopsided;
        ids[1] = even;

        (uint256[] memory out,) = controversial.rank(address(1), ids);
        assertEq(out[0], even);
    }

    /// The property that made dislikes safe to add at all.
    function test_SybilDislikesCannotBury() public {
        vm.startPrank(author);
        uint256 target = posts.post("targeted");
        uint256 other = posts.post("other");
        vm.stopPrank();

        vote(target, 10, 0);
        vote(other, 10, 0);

        // A ring of unreachable wallets piles on.
        for (uint256 i; i < 40; ++i) {
            vm.prank(address(uint160(0x5117000 + i)));
            posts.dislike(target);
        }

        uint256[] memory ids = new uint256[](2);
        ids[0] = target;
        ids[1] = other;

        (, uint256[] memory scores) = best.rank(address(1), ids);
        assertEq(posts.postOf(target).dislikeCount, 40);
        assertEq(posts.postOf(target).weightedDislikes, 0);
        assertEq(scores[0], scores[1], "a ring must not move the score at all");
    }

    function test_NeitherRevertsOnEmptyInput() public view {
        uint256[] memory ids = new uint256[](0);
        best.rank(address(1), ids);
        controversial.rank(address(1), ids);
    }
}
