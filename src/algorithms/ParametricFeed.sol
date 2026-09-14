// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {IFeedAlgorithm} from "../interfaces/IFeedAlgorithm.sol";
import {PostRegistry} from "../PostRegistry.sol";
import {SocialGraph} from "../SocialGraph.sol";
import {FeedSort} from "../lib/FeedSort.sol";

/// @notice One algorithm whose behaviour each user tunes themselves, stored on
///         chain. Drives the slider UI.
/// @dev Chosen over shipping a Solidity compiler in the browser: a fraction of
///      the work, and a stronger demo, because the feed visibly reorders as the
///      sliders move instead of making the audience watch someone type code.
contract ParametricFeed is IFeedAlgorithm {
    error WeightOutOfRange();

    struct Weights {
        uint16 recency;
        uint16 familiarity;
        uint16 novelty;
        uint16 reach;
    }

    SocialGraph public immutable graph;
    PostRegistry public immutable posts;

    uint256 private constant HALF_LIFE = 6 hours;
    uint256 private constant REACH_SCALE = 100;
    uint256 private constant FAMILIARITY_SCALE = 5;
    uint16 private constant MAX_WEIGHT = 100;

    /// @dev A record of all zeros means "never set", so defaults apply. There is
    ///      deliberately no way to select all-zero weights: that state produces
    ///      an empty feed and is never what someone moving sliders intended.
    mapping(address => Weights) private _weights;

    event WeightsSet(
        address indexed user, uint16 recency, uint16 familiarity, uint16 novelty, uint16 reach
    );

    constructor(SocialGraph graph_, PostRegistry posts_) {
        graph = graph_;
        posts = posts_;
    }

    function weightsOf(address user) public view returns (Weights memory) {
        Weights memory w = _weights[user];
        if (w.recency == 0 && w.familiarity == 0 && w.novelty == 0 && w.reach == 0) {
            return Weights({recency: 70, familiarity: 30, novelty: 80, reach: 40});
        }
        return w;
    }

    function setWeights(uint16 recency, uint16 familiarity, uint16 novelty, uint16 reach)
        external
    {
        if (
            recency > MAX_WEIGHT || familiarity > MAX_WEIGHT || novelty > MAX_WEIGHT
                || reach > MAX_WEIGHT
        ) revert WeightOutOfRange();

        _weights[msg.sender] =
            Weights({recency: recency, familiarity: familiarity, novelty: novelty, reach: reach});

        emit WeightsSet(msg.sender, recency, familiarity, novelty, reach);
    }

    function rank(address viewer, uint256[] calldata candidateIds)
        external
        view
        returns (uint256[] memory, uint256[] memory)
    {
        Weights memory w = weightsOf(viewer);
        PostRegistry.Post[] memory ps = posts.postsOf(candidateIds);

        uint256[] memory ids = new uint256[](candidateIds.length);
        uint256[] memory scores = new uint256[](candidateIds.length);

        for (uint256 i; i < candidateIds.length; ++i) {
            ids[i] = candidateIds[i];
            scores[i] = _score(w, ps[i], viewer);
        }

        return FeedSort.byScoreDesc(ids, scores);
    }

    /// @dev Scoring lives in its own frame because holding every component as a
    ///      local inside the loop overflows the stack. Splitting it is also how
    ///      the formula stays readable, which matters for a contract whose whole
    ///      pitch is that you can open it and see what it does.
    function _score(Weights memory w, PostRegistry.Post memory p, address viewer)
        private
        view
        returns (uint256)
    {
        if (p.author == address(0) || p.author == viewer) return 0;

        uint256 fam = posts.interactionCount(viewer, p.author);
        if (graph.followedAt(viewer, p.author) != 0) fam += FAMILIARITY_SCALE;

        uint256 age = block.timestamp > p.createdAt ? block.timestamp - p.createdAt : 0;

        // Every component saturates into [0, 1e18] and every denominator
        // carries a positive constant, so nothing divides by zero.
        uint256 total = uint256(w.recency) * ((HALF_LIFE * 1e18) / (HALF_LIFE + age));
        total += uint256(w.reach)
            * ((uint256(p.weightedLikes) * 1e18) / (uint256(p.weightedLikes) + REACH_SCALE));
        total += uint256(w.familiarity) * ((fam * 1e18) / (fam + FAMILIARITY_SCALE));
        total += uint256(w.novelty) * ((FAMILIARITY_SCALE * 1e18) / (fam + FAMILIARITY_SCALE));

        // Max value is 4 * 100 * 1e18 / 100 == 4e18, far from overflow.
        return total / 100;
    }

    function name() external pure returns (string memory) {
        return "Parametric";
    }

    function description() external pure returns (string memory) {
        return "Your own weighting of recency, familiarity, novelty and reach, stored on chain.";
    }
}
