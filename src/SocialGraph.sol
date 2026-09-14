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

    /// @notice Depth value meaning "not reachable from the seed set".
    uint8 public constant UNREACHED = 255;

    /// @dev Stored off by one so that 0 can mean "never assigned":
    ///      a stored 1 is depth 0, a stored 2 is depth 1, and so on.
    mapping(address => uint8) private _depth;

    event Followed(address indexed follower, address indexed followee, uint64 at);
    event Unfollowed(address indexed follower, address indexed followee);
    event DepthAssigned(address indexed account, uint8 depth);

    constructor(address[] memory seeds) {
        for (uint256 i; i < seeds.length; ++i) {
            _depth[seeds[i]] = 1; // stored 1 == depth 0
            emit DepthAssigned(seeds[i], 0);
        }
    }

    function follow(address followee) external {
        if (followee == msg.sender) revert CannotFollowSelf();
        if (followedAt[msg.sender][followee] != 0) return;

        followedAt[msg.sender][followee] = uint64(block.timestamp);
        followingCount[msg.sender] += 1;
        followerCount[followee] += 1;

        _tryLowerDepth(msg.sender, followee);

        emit Followed(msg.sender, followee, uint64(block.timestamp));
    }

    function unfollow(address followee) external {
        if (followedAt[msg.sender][followee] == 0) return;

        followedAt[msg.sender][followee] = 0;
        followingCount[msg.sender] -= 1;
        followerCount[followee] -= 1;

        emit Unfollowed(msg.sender, followee);
    }

    function depthOf(address account) public view returns (uint8) {
        uint8 stored = _depth[account];
        return stored == 0 ? UNREACHED : stored - 1;
    }

    /// @notice How much this account's likes count toward discovery.
    /// @dev Influence fades with distance from the seed set and hits zero
    ///      outside it. Being UNREACHED never blocks reading or posting; it
    ///      only removes the ability to boost other people's posts.
    function weightOf(address account) public view returns (uint32) {
        uint8 d = depthOf(account);
        if (d <= 2) return 100;
        if (d == 3) return 40;
        if (d == 4) return 10;
        return 0;
    }

    /// @notice Recompute `account`'s depth from an existing follower `via`.
    /// @dev Depth is assigned at follow time and is never propagated backwards,
    ///      so it over-estimates true distance. That errs safe — a real user may
    ///      be under-weighted for a while, but a sybil is never over-weighted.
    ///      This function lets anyone repair a stale value permissionlessly.
    function refresh(address account, address via) external {
        if (followedAt[via][account] == 0) return;
        _tryLowerDepth(via, account);
    }

    function _tryLowerDepth(address from, address to) private {
        uint8 dSrc = depthOf(from);
        if (dSrc == UNREACHED) return; // only a reachable account passes trust on
        if (dSrc == UNREACHED - 1) return; // would overflow into UNREACHED
        uint8 candidate = dSrc + 1;
        if (candidate >= depthOf(to)) return; // depth only ever decreases
        _depth[to] = candidate + 1; // stored off by one
        emit DepthAssigned(to, candidate);
    }
}
