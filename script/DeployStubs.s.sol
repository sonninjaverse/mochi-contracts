// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {IFeedAlgorithm} from "../src/interfaces/IFeedAlgorithm.sol";

/// @notice Hardcoded stand-in so the frontend and indexer can integrate on day 3,
///         before the real contracts exist. Deleted once Task 16 ships.
contract StubFeed is IFeedAlgorithm {
    function rank(address, uint256[] calldata candidateIds)
        external
        pure
        returns (uint256[] memory orderedIds, uint256[] memory scores)
    {
        orderedIds = new uint256[](candidateIds.length);
        scores = new uint256[](candidateIds.length);
        for (uint256 i; i < candidateIds.length; ++i) {
            orderedIds[i] = candidateIds[i];
            scores[i] = (candidateIds.length - i) * 1e18;
        }
    }

    function name() external pure returns (string memory) {
        return "Stub";
    }

    function description() external pure returns (string memory) {
        return "Hardcoded stub for day-3 integration";
    }
}

contract DeployStubs is Script {
    function run() external {
        vm.startBroadcast();
        StubFeed stub = new StubFeed();
        vm.stopBroadcast();
        console.log("StubFeed:", address(stub));
    }
}
