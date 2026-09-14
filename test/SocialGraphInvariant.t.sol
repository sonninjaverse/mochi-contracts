// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {SocialGraph} from "../src/SocialGraph.sol";

/// @dev Fuzz driver: random accounts follow random accounts.
contract GraphHandler is Test {
    SocialGraph public graph;
    address[] public actors;

    constructor(SocialGraph g, address[] memory seeds) {
        graph = g;
        for (uint256 i; i < seeds.length; ++i) actors.push(seeds[i]);
        for (uint256 i; i < 20; ++i) actors.push(address(uint160(0xACC0000 + i)));
    }

    function follow(uint256 a, uint256 b) external {
        address from = actors[a % actors.length];
        address to = actors[b % actors.length];
        if (from == to) return;
        vm.prank(from);
        graph.follow(to);
    }

    function actorCount() external view returns (uint256) {
        return actors.length;
    }

    function actorAt(uint256 i) external view returns (address) {
        return actors[i];
    }
}

contract SocialGraphInvariantTest is Test {
    SocialGraph graph;
    GraphHandler handler;

    /// @dev uint16, not uint8: current can be UNREACHED (255) and this stores
    ///      current + 1, which would overflow a uint8.
    mapping(address => uint16) private seen;

    function setUp() public {
        address[] memory seeds = new address[](1);
        seeds[0] = address(0x5EED);
        graph = new SocialGraph(seeds);
        handler = new GraphHandler(graph, seeds);
        targetContract(address(handler));
    }

    /// @notice Depth must only ever decrease. If it could increase, the
    ///         assignment rule would admit cycles and never terminate.
    function invariant_DepthNeverIncreases() public {
        uint256 n = handler.actorCount();
        for (uint256 i; i < n; ++i) {
            address a = handler.actorAt(i);
            uint8 current = graph.depthOf(a);
            uint16 previous = seen[a];
            if (previous != 0) {
                assertLe(current, previous - 1);
            }
            seen[a] = uint16(current) + 1; // stored off by one so 0 means unseen
        }
    }
}
