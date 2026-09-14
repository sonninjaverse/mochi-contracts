// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {SocialGraph} from "../src/SocialGraph.sol";
import {IdentityRegistry} from "../src/IdentityRegistry.sol";
import {PostRegistry} from "../src/PostRegistry.sol";
import {AlgorithmRegistry} from "../src/AlgorithmRegistry.sol";
import {ChronoFeed} from "../src/algorithms/ChronoFeed.sol";
import {FollowFeed} from "../src/algorithms/FollowFeed.sol";
import {AffinityFeed} from "../src/algorithms/AffinityFeed.sol";
import {SerendipityFeed} from "../src/algorithms/SerendipityFeed.sol";
import {DiscoveryFeed} from "../src/algorithms/DiscoveryFeed.sol";
import {ParametricFeed} from "../src/algorithms/ParametricFeed.sol";

contract Deploy is Script {
    function run() external {
        string memory json = vm.readFile("seeds.json");
        address[] memory seeds = vm.parseJsonAddressArray(json, ".seeds");
        require(seeds.length > 0, "seeds.json is empty");

        vm.startBroadcast();

        SocialGraph graph = new SocialGraph(seeds);
        IdentityRegistry identity = new IdentityRegistry();
        PostRegistry posts = new PostRegistry(graph);

        ChronoFeed chrono = new ChronoFeed(posts);
        FollowFeed follow = new FollowFeed(graph, posts);
        AffinityFeed affinity = new AffinityFeed(graph, posts);
        SerendipityFeed serendipity = new SerendipityFeed(graph, posts);
        DiscoveryFeed discovery = new DiscoveryFeed(graph, posts);
        ParametricFeed parametric = new ParametricFeed(graph, posts);

        // Serendipity is the default feed: it degrades to a trending feed for
        // an account with no follows, so new users need no special path.
        AlgorithmRegistry registry = new AlgorithmRegistry(serendipity, discovery);
        registry.register(chrono);
        registry.register(follow);
        registry.register(affinity);
        registry.register(parametric);

        vm.stopBroadcast();

        console.log("SEEDS_COUNT      ", seeds.length);
        console.log("SocialGraph      ", address(graph));
        console.log("IdentityRegistry ", address(identity));
        console.log("PostRegistry     ", address(posts));
        console.log("AlgorithmRegistry", address(registry));
        console.log("ChronoFeed       ", address(chrono));
        console.log("FollowFeed       ", address(follow));
        console.log("AffinityFeed     ", address(affinity));
        console.log("SerendipityFeed  ", address(serendipity));
        console.log("DiscoveryFeed    ", address(discovery));
        console.log("ParametricFeed   ", address(parametric));
    }
}
