// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {SocialGraph} from "./SocialGraph.sol";

/// @notice Posts and engagement for Mochi Network.
/// @dev Post text never enters storage; it lives in PostCreated event data and
///      is reconstructed by the indexer. Only fields a ranking contract reads
///      are stored, which is what keeps a post down to two slots.
contract PostRegistry {
    error EmptyText();

    struct Post {
        // --- slot 1 ---
        address author; // 160 bits
        uint48 createdAt; // 48 bits
        uint48 parentId; // 48 bits, reserved for replies in a later version
        // --- slot 2 ---
        uint32 likeCount; // raw likes
        uint32 weightedLikes; // likes filtered by SocialGraph.weightOf
        uint32 repostCount; // reserved
        uint32 replyCount; // reserved
    }

    SocialGraph public immutable graph;

    /// @dev Ids start at 1 so that parentId == 0 can mean "no parent".
    uint256 public nextPostId = 1;

    mapping(uint256 => Post) private _posts;

    event PostCreated(uint256 indexed id, address indexed author, uint48 createdAt, string text);

    constructor(SocialGraph graph_) {
        graph = graph_;
    }

    function postOf(uint256 id) external view returns (Post memory) {
        return _posts[id];
    }

    function post(string calldata text) external returns (uint256 id) {
        if (bytes(text).length == 0) revert EmptyText();

        id = nextPostId++;
        _posts[id] = Post({
            author: msg.sender,
            createdAt: uint48(block.timestamp),
            parentId: 0,
            likeCount: 0,
            weightedLikes: 0,
            repostCount: 0,
            replyCount: 0
        });

        emit PostCreated(id, msg.sender, uint48(block.timestamp), text);
    }
}
