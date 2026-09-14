// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {SocialGraph} from "./SocialGraph.sol";

/// @notice Posts and engagement for Mochi Network.
/// @dev Post text never enters storage; it lives in PostCreated event data and
///      is reconstructed by the indexer. Only fields a ranking contract reads
///      are stored, which is what keeps a post down to two slots.
contract PostRegistry {
    error EmptyText();
    error NoSuchPost();

    struct Post {
        // --- slot 1 ---
        address author; // 160 bits
        uint48 createdAt; // 48 bits
        uint48 parentId; // 48 bits, reserved for replies in a later version
        // --- slot 2 ---
        uint32 likeCount; // raw likes
        uint32 weightedLikes; // likes filtered by SocialGraph.weightOf
        // --- slot 3 ---
        uint32 dislikeCount; // raw dislikes
        uint32 weightedDislikes; // dislikes filtered the same way
        uint32 repostCount; // reserved
        uint32 replyCount; // reserved
    }

    SocialGraph public immutable graph;

    /// @dev Ids start at 1 so that parentId == 0 can mean "no parent".
    uint256 public nextPostId = 1;

    mapping(uint256 => Post) private _posts;

    mapping(uint256 => mapping(address => bool)) public hasLiked;
    mapping(uint256 => mapping(address => bool)) public hasDisliked;

    /// @notice How many times `from` has engaged with content by `to`.
    /// @dev Written at like time so ranking can read affinity in O(1) instead
    ///      of scanning history. One extra SSTORE per like buys a cheap read on
    ///      every feed load, and reads vastly outnumber writes.
    mapping(address => mapping(address => uint32)) public interactionCount;

    event PostCreated(uint256 indexed id, address indexed author, uint48 createdAt, string text);
    event Liked(uint256 indexed id, address indexed account, uint32 weight);
    event Unliked(uint256 indexed id, address indexed account);
    event Disliked(uint256 indexed id, address indexed account, uint32 weight);
    event Undisliked(uint256 indexed id, address indexed account);

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
            dislikeCount: 0,
            weightedDislikes: 0,
            repostCount: 0,
            replyCount: 0
        });

        emit PostCreated(id, msg.sender, uint48(block.timestamp), text);
    }

    /// @dev Ranking reads up to 500 candidates per call. One batched read beats
    ///      500 external calls and keeps rank latency flat as the window grows.
    function postsOf(uint256[] calldata ids) external view returns (Post[] memory out) {
        out = new Post[](ids.length);
        for (uint256 i; i < ids.length; ++i) {
            out[i] = _posts[ids[i]];
        }
    }

    function like(uint256 id) external {
        Post storage p = _posts[id];
        if (p.author == address(0)) revert NoSuchPost();
        if (hasLiked[id][msg.sender]) return;

        // A vote is one direction at a time, the way Reddit works. Liking
        // something you had disliked withdraws the dislike rather than leaving
        // the post counted in both columns.
        if (hasDisliked[id][msg.sender]) _clearDislike(p, id);

        hasLiked[id][msg.sender] = true;
        uint32 weight = graph.weightOf(msg.sender);

        p.likeCount += 1;
        p.weightedLikes += weight;
        interactionCount[msg.sender][p.author] += 1;

        emit Liked(id, msg.sender, weight);
    }

    function unlike(uint256 id) external {
        Post storage p = _posts[id];
        if (p.author == address(0)) revert NoSuchPost();
        if (!hasLiked[id][msg.sender]) return;

        // Recompute rather than remember: weightOf can only have risen since
        // the like, and subtracting a larger value than was added would
        // underflow.
        //
        // interactionCount is deliberately not decremented: affinity records
        // that the interaction happened, not that it still stands.
        _clearLike(p, id);
    }

    /**
     * @notice Vote a post down.
     *
     * @dev Weighted exactly as likes are, which is the part that matters: an
     *      unreachable account cannot bury anyone any more than it can promote
     *      anyone. Without that, adding dislikes would have handed a ring a
     *      weapon it did not previously have.
     *
     *      Reddit's Best and Controversial sorts are meaningless without this
     *      signal — one is a confidence interval over agreement, the other is
     *      a measure of disagreement.
     */
    function dislike(uint256 id) external {
        Post storage p = _posts[id];
        if (p.author == address(0)) revert NoSuchPost();
        if (hasDisliked[id][msg.sender]) return;

        if (hasLiked[id][msg.sender]) _clearLike(p, id);

        hasDisliked[id][msg.sender] = true;
        uint32 weight = graph.weightOf(msg.sender);

        p.dislikeCount += 1;
        p.weightedDislikes += weight;
        interactionCount[msg.sender][p.author] += 1;

        emit Disliked(id, msg.sender, weight);
    }

    function undislike(uint256 id) external {
        Post storage p = _posts[id];
        if (p.author == address(0)) revert NoSuchPost();
        if (!hasDisliked[id][msg.sender]) return;
        _clearDislike(p, id);
    }

    function _clearLike(Post storage p, uint256 id) private {
        hasLiked[id][msg.sender] = false;
        uint32 weight = graph.weightOf(msg.sender);
        p.likeCount -= 1;
        p.weightedLikes = weight > p.weightedLikes ? 0 : p.weightedLikes - weight;
        emit Unliked(id, msg.sender);
    }

    function _clearDislike(Post storage p, uint256 id) private {
        hasDisliked[id][msg.sender] = false;
        uint32 weight = graph.weightOf(msg.sender);
        p.dislikeCount -= 1;
        p.weightedDislikes = weight > p.weightedDislikes ? 0 : p.weightedDislikes - weight;
        emit Undisliked(id, msg.sender);
    }
}
