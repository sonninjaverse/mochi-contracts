// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {StubFeed} from "../script/DeployStubs.s.sol";

contract StubFeedTest is Test {
    StubFeed feed;

    function setUp() public {
        feed = new StubFeed();
    }

    function test_PreservesOrderAndLength() public view {
        uint256[] memory ids = new uint256[](3);
        ids[0] = 7;
        ids[1] = 8;
        ids[2] = 9;

        (uint256[] memory out, uint256[] memory scores) = feed.rank(address(1), ids);

        assertEq(out.length, 3);
        assertEq(scores.length, 3);
        assertEq(out[0], 7);
        assertGt(scores[0], scores[1]);
    }

    function test_EmptyInputDoesNotRevert() public view {
        uint256[] memory ids = new uint256[](0);
        (uint256[] memory out,) = feed.rank(address(1), ids);
        assertEq(out.length, 0);
    }
}
