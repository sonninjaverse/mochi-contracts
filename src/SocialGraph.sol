// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/// @notice Follow graph and trust weighting for Mochi Network.
/// @dev Deliberately has no admin functions. The seed set is fixed at
///      construction and can never be changed; see Task 3.
contract SocialGraph {
    error CannotFollowSelf();

    /// @notice Nonzero means "following", and the value is when it started.
    /// @dev A uint64 timestamp costs the same slot as a bool but carries more
    ///      information for ranking algorithms.
    mapping(address => mapping(address => uint64)) public followedAt;
    mapping(address => uint32) public followerCount;
    mapping(address => uint32) public followingCount;

    event Followed(address indexed follower, address indexed followee, uint64 at);
    event Unfollowed(address indexed follower, address indexed followee);

    constructor(address[] memory seeds) {
        // Seed handling lands in Task 3. Accepting the argument now keeps the
        // constructor signature stable for the frontend and indexer.
        seeds;
    }

    function follow(address followee) external {
        if (followee == msg.sender) revert CannotFollowSelf();
        if (followedAt[msg.sender][followee] != 0) return;

        followedAt[msg.sender][followee] = uint64(block.timestamp);
        followingCount[msg.sender] += 1;
        followerCount[followee] += 1;

        emit Followed(msg.sender, followee, uint64(block.timestamp));
    }

    function unfollow(address followee) external {
        if (followedAt[msg.sender][followee] == 0) return;

        followedAt[msg.sender][followee] = 0;
        followingCount[msg.sender] -= 1;
        followerCount[followee] -= 1;

        emit Unfollowed(msg.sender, followee);
    }
}
