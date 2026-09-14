// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {SocialGraph} from "../src/SocialGraph.sol";
import {IdentityRegistry} from "../src/IdentityRegistry.sol";
import {PostRegistry} from "../src/PostRegistry.sol";
import {AlgorithmRegistry} from "../src/AlgorithmRegistry.sol";
import {BestFeed} from "../src/algorithms/BestFeed.sol";
import {ChronoFeed} from "../src/algorithms/ChronoFeed.sol";
import {ControversialFeed} from "../src/algorithms/ControversialFeed.sol";
import {HotFeed} from "../src/algorithms/HotFeed.sol";
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

        // Reddit's three, taken from _sorts.pyx rather than reinvented. Hot
        // anchors its time term to deployment for the same reason reddit
        // anchored theirs to launch day: it keeps the linear term at a size
        // where the logarithmic vote term still registers.
        HotFeed hot = new HotFeed(posts, block.timestamp);
        BestFeed bestSort = new BestFeed(posts);
        ControversialFeed controversial = new ControversialFeed(posts);
        FollowFeed follow = new FollowFeed(graph, posts);
        AffinityFeed affinity = new AffinityFeed(graph, posts);
        SerendipityFeed serendipity = new SerendipityFeed(graph, posts);
        DiscoveryFeed discovery = new DiscoveryFeed(graph, posts);
        ParametricFeed parametric = new ParametricFeed(graph, posts);

        // Hot is the default.
        //
        // It is the only ranking here that does not depend on the viewer, so a
        // brand new account sees a full feed rather than an empty one —
        // Affinity has nothing to work with and Best ignores time entirely,
        // which leaves a stale page. It is also the one people already
        // recognise, which makes the claim land without explanation.
        AlgorithmRegistry registry = new AlgorithmRegistry(hot, discovery);
        registry.register(bestSort);
        registry.register(controversial);
        registry.register(serendipity);
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
        console.log("HotFeed          ", address(hot));
        console.log("BestFeed         ", address(bestSort));
        console.log("ControversialFeed", address(controversial));
        console.log("ChronoFeed       ", address(chrono));
        console.log("FollowFeed       ", address(follow));
        console.log("AffinityFeed     ", address(affinity));
        console.log("SerendipityFeed  ", address(serendipity));
        console.log("DiscoveryFeed    ", address(discovery));
        console.log("ParametricFeed   ", address(parametric));
    }
}
