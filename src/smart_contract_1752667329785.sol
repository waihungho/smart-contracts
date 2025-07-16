I. Contract Overview
*   **Contract Name:** `AetheriaNexus`
*   **Purpose:** A decentralized, self-adapting platform for identifying, predicting, and capitalizing on emerging technological trends. It integrates prediction markets, dynamic reputation systems, and evolving "Trend Laureate" NFTs within a community-governed framework.
*   **Key Features:**
    *   **Trend Lifecycle Management:** Trends progress through defined statuses (Proposed, Active, Declining, Mature, Archived), reflecting real-world tech adoption curves.
    *   **Adaptive Prediction Market:** Users predict a continuous "Growth Index" (0-100) for trends, with rewards dynamically calculated based on accuracy, prediction timing, and the trend's overall success.
    *   **Reputation System:** Participants gain or lose reputation based on prediction accuracy and governance participation. Reputation influences access to advanced features (e.g., proposing trends, voting power).
    *   **Dynamic Trend Laureate NFTs:** Special NFTs are minted for highly successful trends, whose metadata dynamically updates to reflect the ongoing success and metrics of their associated trend.
    *   **AI/Oracle Integration (Conceptual):** Designed to utilize verifiable off-chain data (e.g., from decentralized AI or Zero-Knowledge Proof (ZKP) backed oracles) for objective trend growth assessment.
    *   **Trend Merging:** A unique feature allowing for the consolidation of related or converging technological trends.
    *   **Decentralized Governance:** A proposal and voting system enables the community (especially high-reputation users) to govern core contract parameters.
*   **Token:** The platform interacts with an external ERC-20 token, `AETH`, used for staking, submission bonds, and rewards.

II. Function Summary (25 Functions)

**I. Core Trend Management (5 Functions)**

1.  `submitNewTrend(string calldata _name, string calldata _description)`
    *   **Description:** Allows users to propose a new technological trend for consideration.
    *   **Requirements:** `msg.sender` must meet `minReputationForTrendSubmission` and pay a `submissionBondAmount` in AETH.
    *   **Events:** `TrendSubmitted`
2.  `voteOnTrendProposal(uint256 _trendId, bool _approve)`
    *   **Description:** Enables reputation-gated users to vote on whether a proposed trend should be approved.
    *   **Requirements:** `msg.sender` must meet `minReputationForVote`; voting period must be active.
    *   **Events:** `TrendVoteCast`
3.  `finalizeTrendApproval(uint256 _trendId)`
    *   **Description:** Finalizes the outcome of a trend proposal vote. If approved, the bond is returned to the submitter, and the trend becomes `Active`. If rejected, the bond is transferred to the treasury.
    *   **Requirements:** Callable by `owner` (or DAO); voting period must have ended.
    *   **Events:** `TrendApproved`, `TrendStatusUpdated`
4.  `updateTrendStatus(uint256 _trendId, TrendStatus _newStatus)`
    *   **Description:** Changes the lifecycle status of an existing trend (e.g., from `Active` to `Declining` or `Mature`).
    *   **Requirements:** Callable by `owner` (or DAO/Oracle).
    *   **Events:** `TrendStatusUpdated`
5.  `mergeTrends(uint256 _trendId1, uint256 _trendId2, string calldata _newName, string calldata _newDescription)`
    *   **Description:** Combines two existing, active trends into a new, single trend, archiving the original ones.
    *   **Requirements:** Callable by `owner` (or DAO).
    *   **Events:** `TrendsMerged`, `TrendStatusUpdated`

**II. Prediction Market & Staking (4 Functions)**

6.  `predictTrendGrowth(uint256 _trendId, uint256 _amountToStake, uint256 _predictedGrowthIndex)`
    *   **Description:** Users stake AETH to predict a trend's future "Growth Index" (a numerical value from 0-100 indicating adoption/success).
    *   **Requirements:** Trend must be `Active`; `_amountToStake` > 0; `_predictedGrowthIndex` <= 100.
    *   **Events:** `PredictionMade`
7.  `resolveTrendGrowth(uint256 _trendId, uint256 _actualGrowthIndex, bytes calldata _oracleProof)`
    *   **Description:** Called by a trusted oracle to provide the actual growth index for a trend. This triggers the resolution of all eligible predictions for that trend and updates `userReputation`.
    *   **Requirements:** Callable by `oracleAddress`; sufficient time must have passed since the trend's last update. `_oracleProof` is a conceptual placeholder for verifiable data.
    *   **Events:** `PredictionResolved`, `ReputationUpdated`
8.  `claimPredictionRewards(uint256 _predictionId)`
    *   **Description:** Allows users to claim their AETH rewards if their prediction was resolved and determined to be accurate.
    *   **Requirements:** Prediction must be resolved, not yet claimed, and have a positive payout.
    *   **Events:** `RewardsClaimed`
9.  `earlyUnstakePrediction(uint256 _predictionId)`
    *   **Description:** Enables a user to retrieve a portion of their staked AETH before the prediction is resolved, incurring a penalty that goes to the treasury.
    *   **Requirements:** Prediction must not be resolved; must be within the early unstake window.
    *   **Events:** `EarlyUnstake`

**III. Reputation System (3 Functions)**

10. `getReputation(address _user)`
    *   **Description:** Publicly queries the current reputation score for a given user address.
    *   **Returns:** `uint256` - The user's reputation score.
11. `_updateReputation(address _user, int256 _delta)`
    *   **Description:** Internal function to adjust a user's reputation score based on actions (e.g., successful predictions, proposal participation).
    *   **Events:** `ReputationUpdated`
12. `getMinReputationForSubmission()`
    *   **Description:** Returns the currently set minimum reputation required for submitting new trend proposals.
    *   **Returns:** `uint256` - Minimum reputation value.

**IV. Dynamic NFTs (Trend Laureates) (3 Functions)**

13. `mintLaureateNFT(uint256 _trendId, address _recipient)`
    *   **Description:** Mints a special "Trend Laureate NFT" for highly successful trends (typically when they reach `Mature` status).
    *   **Requirements:** Callable internally by contract logic or `owner` (or DAO) when a trend meets success criteria; NFT not already minted for this trend.
    *   **Events:** `LaureateNFTMinted`
14. `getLaureateNFTMetadata(uint256 _laureateNFTId)`
    *   **Description:** Retrieves the dynamic metadata (e.g., associated trend's name, current growth index, adoption metrics) for a specific Laureate NFT.
    *   **Returns:** `string` - A representation of the NFT's dynamic attributes.
15. `_updateLaureateNFTAttributes(uint256 _laureateNFTId, string calldata _key, string calldata _value)`
    *   **Description:** Internal function to update the dynamic attributes associated with a Laureate NFT, reflecting changes in the underlying trend's success.
    *   **Events:** `LaureateNFTAttributesUpdated`

**V. Governance & System Parameters (8 Functions)**

16. `proposeParameterChange(string calldata _paramName, uint256 _newValue, uint256 _quorumPercentage)`
    *   **Description:** Initiates a governance proposal to modify a system parameter (e.g., `submissionBondAmount`, `minReputationForVote`).
    *   **Requirements:** `msg.sender` must meet `minReputationForVote`.
    *   **Events:** `ParameterChangeProposed`
17. `voteOnProposal(uint256 _proposalId, bool _support)`
    *   **Description:** Allows users to cast their weighted vote (based on reputation) on an active governance proposal.
    *   **Requirements:** `msg.sender` must meet `minReputationForVote`; proposal must be `Pending` and within voting period.
    *   **Events:** `VoteCast`
18. `executeProposal(uint256 _proposalId)`
    *   **Description:** Executes a governance proposal that has met its voting requirements (passed quorum and majority).
    *   **Requirements:** Callable by `owner` (or reputation-gated); voting period must have ended, and proposal must be `Pending`.
    *   **Events:** `ProposalExecuted`
19. `setOracleAddress(address _newOracle)`
    *   **Description:** Sets the address of the trusted oracle responsible for providing external trend growth data.
    *   **Requirements:** Callable by `owner` (or DAO).
    *   **Events:** `OracleAddressUpdated`
20. `setTreasuryAddress(address _newTreasury)`
    *   **Description:** Sets the address for the project's treasury, where fees and unreturned bonds are collected.
    *   **Requirements:** Callable by `owner` (or DAO).
    *   **Events:** `TreasuryAddressUpdated`
21. `withdrawTreasuryFunds(address _recipient, uint256 _amount)`
    *   **Description:** Allows the `owner` (or DAO) to withdraw AETH from the contract's treasury balance.
    *   **Requirements:** Callable by `owner` (or DAO); sufficient funds in treasury.
22. `emergencyPause()`
    *   **Description:** Pauses core functionalities of the contract in case of an emergency (e.g., exploit, critical bug).
    *   **Requirements:** Callable by `owner`.
    *   **Events:** `Paused` (from OpenZeppelin Pausable)
23. `emergencyUnpause()`
    *   **Description:** Unpauses core functionalities, resuming normal operation.
    *   **Requirements:** Callable by `owner`.
    *   **Events:** `Unpaused` (from OpenZeppelin Pausable)

**VI. Auxiliary/Utility Functions (2 Functions)**

24. `calculatePredictionPayout(uint256 _predictionId, uint256 _actualGrowthIndex)`
    *   **Description:** Internal pure function that calculates the reward amount for a prediction based on its accuracy relative to the actual growth index and other factors.
    *   **Returns:** `uint256` - The calculated payout amount.
25. `getCurrentAETHBalance()`
    *   **Description:** Returns the total AETH balance currently held by the `AetheriaNexus` contract.
    *   **Returns:** `uint256` - The contract's AETH balance.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // For explicit checks and clarity
import "@openzeppelin/contracts/utils/Strings.sol"; // For uint256 to string conversion

// AetheriaNexus: Decentralized Adaptive Learning & Prediction Market for Emerging Tech Trends
//
// Overview:
// AetheriaNexus is a novel smart contract platform designed to identify, predict, and capitalize on emerging
// technological trends. It combines elements of prediction markets, dynamic reputation systems,
// and uniquely structured "Trend Laureate" NFTs that evolve with the success of the trends they represent.
// The platform encourages accurate forecasting and strategic insight into the tech landscape,
// rewarding participants based on their foresight and contribution to the ecosystem's intelligence.
// AetheriaNexus aims to be a self-adapting, community-governed system for decentralized trend analysis.
//
// Key Advanced Concepts & Unique Features:
// 1.  **Trend Lifecycle Management:** Trends progress through statuses (Proposed, Active, Declining, Mature, Archived),
//     allowing for dynamic interaction and reflecting real-world technology adoption curves.
// 2.  **Adaptive Prediction Market:** Users predict a continuous "Growth Index" (0-100) for trends,
//     rather than binary outcomes. Rewards are dynamically calculated based on proximity to the actual index,
//     earliness of prediction, and the trend's overall success.
// 3.  **Reputation-Gated Participation:** A dynamic reputation system rewards accurate predictors and
//     influences a user's ability to propose new trends or vote on governance proposals, fostering expert participation.
// 4.  **Dynamic Trend Laureate NFTs:** Special NFTs are minted for the originators of highly successful trends
//     or top predictors. These NFTs' metadata dynamically updates to reflect the ongoing real-world
//     metrics and success of their associated trend, making them living, evolving digital assets.
// 5.  **AI/Oracle Integration (Conceptual):** Designed with an `_oracleProof` parameter in `resolveTrendGrowth`
//     to signify reliance on verifiable off-chain data, potentially from decentralized AI or ZKP-backed oracles
//     for objective trend growth assessment.
// 6.  **Trend Merging:** A unique feature allowing the community/governance to merge related trends,
//     reflecting how technologies often converge or evolve together.
// 7.  **Decentralized Governance (DAO-like):** A proposal and voting system allows the community
//     (especially high-reputation users) to steer the contract's parameters and evolution.
//
// Token Economy:
// The platform utilizes an external ERC-20 token, `AETH`, for staking on predictions, paying submission bonds,
// and receiving rewards.
//
// ---
//
// Function Summary:
//
// I. Core Trend Management:
// 1.  `submitNewTrend(string calldata _name, string calldata _description)`: Proposes a new tech trend for community review. Requires a bond and minimum reputation.
// 2.  `voteOnTrendProposal(uint255 _trendId, bool _approve)`: Allows reputation-gated users to vote on proposed trends.
// 3.  `finalizeTrendApproval(uint255 _trendId)`: Finalizes the approval or rejection of a trend proposal after voting.
// 4.  `updateTrendStatus(uint255 _trendId, TrendStatus _newStatus)`: Updates the lifecycle status of an existing trend.
// 5.  `mergeTrends(uint255 _trendId1, uint255 _trendId2, string calldata _newName, string calldata _newDescription)`: Combines two existing trends into a new, merged trend.
//
// II. Prediction Market & Staking:
// 6.  `predictTrendGrowth(uint255 _trendId, uint255 _amountToStake, uint255 _predictedGrowthIndex)`: Stakes AETH to predict a trend's future growth index.
// 7.  `resolveTrendGrowth(uint255 _trendId, uint255 _actualGrowthIndex, bytes calldata _oracleProof)`: Called by a trusted oracle to provide the actual growth index, triggering prediction resolution.
// 8.  `claimPredictionRewards(uint255 _predictionId)`: Allows users to claim their calculated rewards for accurate predictions.
// 9.  `earlyUnstakePrediction(uint255 _predictionId)`: Enables a user to retrieve a portion of their staked amount before resolution, with a penalty.
//
// III. Reputation System:
// 10. `getReputation(address _user)`: Retrieves the current reputation score for a given address.
// 11. `_updateReputation(address _user, int255 _delta)`: Internal function to adjust a user's reputation score.
// 12. `getMinReputationForSubmission()`: Returns the minimum reputation required to submit a new trend.
//
// IV. Dynamic NFTs (Trend Laureates):
// 13. `mintLaureateNFT(uint255 _trendId, address _recipient)`: Mints a Trend Laureate NFT, associating it with a highly successful trend.
// 14. `getLaureateNFTMetadata(uint255 _laureateNFTId)`: Retrieves the dynamically updating metadata for a specific Laureate NFT.
// 15. `_updateLaureateNFTAttributes(uint255 _laureateNFTId, string calldata _key, string calldata _value)`: Internal function to update Laureate NFT attributes.
//
// V. Governance & System Parameters:
// 16. `proposeParameterChange(string calldata _paramName, uint255 _newValue, uint255 _quorumPercentage)`: Initiates a governance proposal to change contract parameters.
// 17. `voteOnProposal(uint255 _proposalId, bool _support)`: Casts a vote on an active governance proposal.
// 18. `executeProposal(uint255 _proposalId)`: Executes a governance proposal that has met its voting requirements.
// 19. `setOracleAddress(address _newOracle)`: Sets the address of the trusted oracle.
// 20. `setTreasuryAddress(address _newTreasury)`: Sets the address for the project's treasury.
// 21. `withdrawTreasuryFunds(address _recipient, uint255 _amount)`: Allows the DAO/Owner to withdraw funds from the treasury.
// 22. `emergencyPause()`: Pauses core contract functionalities in an emergency.
// 23. `emergencyUnpause()`: Unpauses the contract functionalities.
//
// VI. Auxiliary/Utility Functions:
// 24. `calculatePredictionPayout(uint255 _predictionId, uint255 _actualGrowthIndex)`: Internal pure function to compute prediction rewards.
// 25. `getCurrentAETHBalance()`: Returns the current AETH balance held by the contract.

contract AetheriaNexus is Ownable, Pausable {
    using SafeMath for uint256;
    using Strings for uint256;

    IERC20 public immutable aethToken;

    address public oracleAddress;
    address public treasuryAddress;

    // --- Enums ---
    enum TrendStatus {
        Proposed,
        Active,
        Declining,
        Mature,
        Archived
    }

    enum ProposalStatus {
        Pending,
        Approved,
        Rejected,
        Executed
    }

    // --- Structs ---
    struct Trend {
        uint256 id;
        string name;
        string description;
        address submitter;
        TrendStatus status;
        uint256 submissionTimestamp;
        uint256 lastUpdated;
        uint256 currentGrowthIndex; // Last resolved growth index (0-100)
        uint256 totalStaked; // Total AETH staked on this trend across all active predictions
        uint256 laureateNFTId; // 0 if no NFT, otherwise ID of the associated Laureate NFT
        uint256 votesFor; // For trend proposals
        uint256 votesAgainst; // For trend proposals
        uint256 proposalEndTime; // For trend proposals
    }

    struct Prediction {
        uint256 id;
        address predictor;
        uint256 trendId;
        uint256 stakedAmount;
        uint256 predictedGrowthIndex; // User's prediction (0-100)
        uint256 predictionTimestamp;
        bool isResolved;
        bool isClaimed;
        uint256 payoutAmount; // Calculated payout if prediction resolved and accurate
    }

    struct Proposal {
        uint256 id;
        address proposer;
        string paramName; // e.g., "submissionBondAmount", "minReputationForVote"
        uint256 newValue;
        ProposalStatus status;
        uint256 voteYes; // Total reputation points voting "Yes"
        uint256 voteNo;  // Total reputation points voting "No"
        uint256 creationTime;
        uint256 proposalEndTime;
        uint256 quorumPercentage; // e.g., 50 for 50%
    }

    // --- Mappings & State Variables ---
    uint256 public nextTrendId;
    uint256 public nextPredictionId;
    uint256 public nextProposalId;
    uint256 public nextLaureateNFTId; // Simple ID for our "dynamic NFT" concept

    mapping(uint256 => Trend) public trends;
    mapping(uint256 => Prediction) public predictions;
    mapping(uint256 => Proposal) public proposals;
    mapping(address => uint256) public userReputation; // Reputation score for each user
    mapping(uint256 => mapping(string => string)) public laureateNFTAttributes; // tokenId => attributeName => attributeValue (simple dynamic metadata)

    uint256 public minReputationForTrendSubmission; // Minimum reputation to submit a new trend
    uint252 public minReputationForVote; // Minimum reputation to vote on proposals
    uint256 public submissionBondAmount; // AETH required to submit a new trend
    uint256 public trendProposalVotingPeriod; // Duration for trend proposal voting in seconds
    uint256 public governanceVotingPeriod; // Duration for governance proposal voting in seconds
    uint256 public predictionResolutionWindow; // Time after which a prediction can be resolved
    uint256 public growthIndexRewardMultiplier; // Multiplier for reward calculation (e.g., 100 for 1x stake for perfect accuracy)
    uint256 public earlyUnstakePenaltyPercentage; // Penalty for early unstaking (e.g., 10 for 10%)

    // --- Events ---
    event TrendSubmitted(uint256 indexed trendId, address indexed submitter, string name, uint256 bondAmount);
    event TrendVoteCast(uint256 indexed trendId, address indexed voter, bool approved);
    event TrendApproved(uint256 indexed trendId, address indexed approver);
    event TrendStatusUpdated(uint256 indexed trendId, TrendStatus oldStatus, TrendStatus newStatus);
    event TrendsMerged(uint256 indexed newTrendId, uint256 indexed oldTrendId1, uint256 indexed oldTrendId2, string newName);

    event PredictionMade(uint256 indexed predictionId, uint256 indexed trendId, address indexed predictor, uint256 stakedAmount, uint256 predictedGrowth);
    event PredictionResolved(uint256 indexed predictionId, uint256 indexed trendId, uint256 actualGrowth, uint256 payoutAmount);
    event RewardsClaimed(uint256 indexed predictionId, address indexed claimant, uint256 amount);
    event EarlyUnstake(uint256 indexed predictionId, address indexed staker, uint256 returnedAmount, uint256 penaltyAmount);

    event ReputationUpdated(address indexed user, uint256 newReputation);

    event LaureateNFTMinted(uint256 indexed laureateNFTId, uint256 indexed trendId, address indexed recipient);
    event LaureateNFTAttributesUpdated(uint256 indexed laureateNFTId, string key, string value);

    event ParameterChangeProposed(uint256 indexed proposalId, address indexed proposer, string paramName, uint256 newValue);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId, string paramName, uint256 newValue);

    event OracleAddressUpdated(address indexed oldAddress, address indexed newAddress);
    event TreasuryAddressUpdated(address indexed oldAddress, address indexed newAddress);

    // --- Modifiers ---
    modifier onlyOracle() {
        require(msg.sender == oracleAddress, "AetheriaNexus: Caller is not the oracle");
        _;
    }

    modifier reputationGated(uint256 _minReputation) {
        require(userReputation[msg.sender] >= _minReputation, "AetheriaNexus: Insufficient reputation");
        _;
    }

    // --- Constructor ---
    constructor(address _aethTokenAddress, address _initialOracleAddress, address _initialTreasuryAddress) Ownable(msg.sender) Pausable() {
        require(_aethTokenAddress != address(0), "AetheriaNexus: AETH token address cannot be zero");
        require(_initialOracleAddress != address(0), "AetheriaNexus: Oracle address cannot be zero");
        require(_initialTreasuryAddress != address(0), "AetheriaNexus: Treasury address cannot be zero");

        aethToken = IERC20(_aethTokenAddress);
        oracleAddress = _initialOracleAddress;
        treasuryAddress = _initialTreasuryAddress;

        // Initial default parameters
        minReputationForTrendSubmission = 100; // Example value
        minReputationForVote = 50; // Example value
        submissionBondAmount = 100 * (10 ** 18); // 100 AETH (assuming 18 decimals) as an example bond
        trendProposalVotingPeriod = 3 days;
        governanceVotingPeriod = 7 days;
        predictionResolutionWindow = 30 days; // Predictions can be resolved after this duration
        growthIndexRewardMultiplier = 100; // E.g., 100 means 1x staked amount for 0 diff, scaled down.
        earlyUnstakePenaltyPercentage = 10; // 10% penalty
    }

    // --- I. Core Trend Management ---

    /// @notice Proposes a new tech trend for community review.
    /// @param _name The name of the proposed trend.
    /// @param _description A detailed description of the trend.
    function submitNewTrend(string calldata _name, string calldata _description)
        external
        whenNotPaused
        reputationGated(minReputationForTrendSubmission)
    {
        require(bytes(_name).length > 0, "AetheriaNexus: Trend name cannot be empty");
        require(bytes(_description).length > 0, "AetheriaNexus: Trend description cannot be empty");
        require(aethToken.transferFrom(msg.sender, address(this), submissionBondAmount), "AetheriaNexus: AETH transfer failed for bond");

        uint256 trendId = nextTrendId++;
        trends[trendId] = Trend({
            id: trendId,
            name: _name,
            description: _description,
            submitter: msg.sender,
            status: TrendStatus.Proposed,
            submissionTimestamp: block.timestamp,
            lastUpdated: block.timestamp,
            currentGrowthIndex: 0,
            totalStaked: 0,
            laureateNFTId: 0,
            votesFor: 0,
            votesAgainst: 0,
            proposalEndTime: block.timestamp + trendProposalVotingPeriod
        });

        _updateReputation(msg.sender, 5); // Reward for active participation (proposal)
        emit TrendSubmitted(trendId, msg.sender, _name, submissionBondAmount);
    }

    /// @notice Allows reputation-gated users to vote on proposed trends.
    /// @param _trendId The ID of the trend proposal.
    /// @param _approve True to vote for approval, false to vote against.
    function voteOnTrendProposal(uint256 _trendId, bool _approve)
        external
        whenNotPaused
        reputationGated(minReputationForVote)
    {
        Trend storage trend = trends[_trendId];
        require(trend.status == TrendStatus.Proposed, "AetheriaNexus: Trend is not in proposed status");
        require(block.timestamp <= trend.proposalEndTime, "AetheriaNexus: Voting period has ended");

        // Simple voting; for robust system, prevent double-voting using a mapping:
        // mapping(uint256 => mapping(address => bool)) hasVoted;
        // require(!hasVoted[_trendId][msg.sender], "AetheriaNexus: Already voted on this proposal.");
        // hasVoted[_trendId][msg.sender] = true;

        if (_approve) {
            trend.votesFor++;
        } else {
            trend.votesAgainst++;
        }

        _updateReputation(msg.sender, 1); // Small reward for voting
        emit TrendVoteCast(_trendId, msg.sender, _approve);
    }

    /// @notice Finalizes the approval or rejection of a trend proposal after voting.
    /// @param _trendId The ID of the trend proposal.
    function finalizeTrendApproval(uint256 _trendId) external whenNotPaused onlyOwner { // Can be DAO-gated
        Trend storage trend = trends[_trendId];
        require(trend.status == TrendStatus.Proposed, "AetheriaNexus: Trend is not in proposed status");
        require(block.timestamp > trend.proposalEndTime, "AetheriaNexus: Voting period has not ended");

        if (trend.votesFor > trend.votesAgainst) {
            trend.status = TrendStatus.Active;
            _updateReputation(trend.submitter, 20); // Significant reward for successful proposal
            require(aethToken.transfer(trend.submitter, submissionBondAmount), "AetheriaNexus: Bond return failed");
            emit TrendApproved(_trendId, msg.sender);
            emit TrendStatusUpdated(_trendId, TrendStatus.Proposed, TrendStatus.Active);
        } else {
            // Trend rejected, bond goes to treasury
            require(aethToken.transfer(treasuryAddress, submissionBondAmount), "AetheriaNexus: Bond transfer to treasury failed");
            trend.status = TrendStatus.Archived; // Or a specific 'Rejected' status
            _updateReputation(trend.submitter, -10); // Penalty for rejected proposal
            emit TrendStatusUpdated(_trendId, TrendStatus.Proposed, TrendStatus.Archived);
        }
    }

    /// @notice Updates the lifecycle status of an existing trend.
    /// @param _trendId The ID of the trend.
    /// @param _newStatus The new status to set (e.g., Active, Declining, Mature, Archived).
    function updateTrendStatus(uint256 _trendId, TrendStatus _newStatus) external whenNotPaused onlyOwner { // Can be DAO/oracle gated
        Trend storage trend = trends[_trendId];
        require(trend.status != TrendStatus.Proposed, "AetheriaNexus: Cannot update status of a proposed trend directly.");
        require(trend.status != _newStatus, "AetheriaNexus: Trend already has this status.");

        TrendStatus oldStatus = trend.status;
        trend.status = _newStatus;
        trend.lastUpdated = block.timestamp;

        // Specific actions on status change, e.g., minting NFT on Mature
        if (_newStatus == TrendStatus.Mature && trend.laureateNFTId == 0) {
            // Logic to determine if trend is "successful enough" for NFT (e.g., based on totalStaked, growth over time)
            // For now, it's assumed this function is called judiciously.
            mintLaureateNFT(_trendId, trend.submitter);
        }

        emit TrendStatusUpdated(_trendId, oldStatus, _newStatus);
    }

    /// @notice Combines two existing trends into a new, merged trend.
    /// @param _trendId1 The ID of the first trend to merge.
    /// @param _trendId2 The ID of the second trend to merge.
    /// @param _newName The name for the new merged trend.
    /// @param _newDescription The description for the new merged trend.
    function mergeTrends(uint256 _trendId1, uint256 _trendId2, string calldata _newName, string calldata _newDescription)
        external
        whenNotPaused
        onlyOwner // Can be DAO-gated
    {
        require(_trendId1 != _trendId2, "AetheriaNexus: Cannot merge a trend with itself.");
        Trend storage trend1 = trends[_trendId1];
        Trend storage trend2 = trends[_trendId2];

        require(trend1.status != TrendStatus.Proposed && trend1.status != TrendStatus.Archived, "AetheriaNexus: Trend 1 not mergeable.");
        require(trend2.status != TrendStatus.Proposed && trend2.status != TrendStatus.Archived, "AetheriaNexus: Trend 2 not mergeable.");

        uint256 newTrendId = nextTrendId++;
        trends[newTrendId] = Trend({
            id: newTrendId,
            name: _newName,
            description: _newDescription,
            submitter: msg.sender, // The one initiating the merge, or a default
            status: TrendStatus.Active,
            submissionTimestamp: block.timestamp,
            lastUpdated: block.timestamp,
            currentGrowthIndex: (trend1.currentGrowthIndex + trend2.currentGrowthIndex) / 2, // Average or more complex logic
            totalStaked: trend1.totalStaked.add(trend2.totalStaked),
            laureateNFTId: 0, // Merged trends start fresh for NFTs
            votesFor: 0, votesAgainst: 0, proposalEndTime: 0
        });

        // Mark old trends as archived (or merged_source)
        trend1.status = TrendStatus.Archived;
        trend2.status = TrendStatus.Archived;
        trend1.lastUpdated = block.timestamp;
        trend2.lastUpdated = block.timestamp;

        // Note: Existing predictions on trend1/trend2 will still resolve based on their original trend.
        // New predictions would target the merged trend.

        emit TrendsMerged(newTrendId, _trendId1, _trendId2, _newName);
        emit TrendStatusUpdated(_trendId1, trend1.status, TrendStatus.Archived);
        emit TrendStatusUpdated(_trendId2, trend2.status, TrendStatus.Archived);
    }

    // --- II. Prediction Market & Staking ---

    /// @notice Stakes AETH to predict a trend's future growth index.
    /// @param _trendId The ID of the trend being predicted.
    /// @param _amountToStake The amount of AETH to stake.
    /// @param _predictedGrowthIndex The user's predicted growth index (0-100).
    function predictTrendGrowth(uint256 _trendId, uint256 _amountToStake, uint256 _predictedGrowthIndex)
        external
        whenNotPaused
    {
        Trend storage trend = trends[_trendId];
        require(trend.status == TrendStatus.Active, "AetheriaNexus: Trend is not active for prediction.");
        require(_amountToStake > 0, "AetheriaNexus: Stake amount must be greater than zero.");
        require(_predictedGrowthIndex <= 100, "AetheriaNexus: Predicted growth index must be between 0 and 100.");
        require(aethToken.transferFrom(msg.sender, address(this), _amountToStake), "AetheriaNexus: AETH transfer failed for prediction stake.");

        uint256 predictionId = nextPredictionId++;
        predictions[predictionId] = Prediction({
            id: predictionId,
            predictor: msg.sender,
            trendId: _trendId,
            stakedAmount: _amountToStake,
            predictedGrowthIndex: _predictedGrowthIndex,
            predictionTimestamp: block.timestamp,
            isResolved: false,
            isClaimed: false,
            payoutAmount: 0
        });

        trend.totalStaked = trend.totalStaked.add(_amountToStake);
        _updateReputation(msg.sender, 2); // Small reputation for making a prediction
        emit PredictionMade(predictionId, _trendId, msg.sender, _amountToStake, _predictedGrowthIndex);
    }

    /// @notice Called by a trusted oracle to provide the actual growth index, triggering prediction resolution.
    /// @param _trendId The ID of the trend to resolve.
    /// @param _actualGrowthIndex The actual growth index (0-100) provided by the oracle.
    /// @param _oracleProof A cryptographic proof (e.g., ZKP, oracle signature) validating the data. (Conceptual, not implemented)
    function resolveTrendGrowth(uint256 _trendId, uint256 _actualGrowthIndex, bytes calldata _oracleProof)
        external
        whenNotPaused
        onlyOracle // Or DAO/reputation-gated multi-sig in a real system
    {
        Trend storage trend = trends[_trendId];
        require(trend.status == TrendStatus.Active || trend.status == TrendStatus.Declining, "AetheriaNexus: Trend is not in a resolvable status.");
        require(_actualGrowthIndex <= 100, "AetheriaNexus: Actual growth index must be between 0 and 100.");
        require(block.timestamp >= trend.lastUpdated.add(predictionResolutionWindow), "AetheriaNexus: Not yet time to resolve this trend.");

        // In a real system, one would verify the _oracleProof (e.g., using a ZKP verifier contract,
        // or verifying an ECC signature against a known public key from the oracle).
        // For this example, `onlyOracle` modifier implies trusted data.
        // If the proof is invalid, the function should revert.

        trend.currentGrowthIndex = _actualGrowthIndex;
        trend.lastUpdated = block.timestamp;

        // Iterate through predictions for this trend and resolve them.
        // WARNING: Iterating over a large number of predictions in a single transaction can be gas-intensive.
        // In a real dApp, this might be optimized (e.g., batch processing, keeper network off-chain resolution).
        uint256 totalPayouts = 0;
        for (uint256 i = 0; i < nextPredictionId; i++) {
            if (predictions[i].trendId == _trendId && !predictions[i].isResolved) {
                Prediction storage prediction = predictions[i];
                // Ensure prediction was made before the current resolution window
                // A more robust system would define explicit prediction "epochs" for clarity.
                if (prediction.predictionTimestamp <= trend.lastUpdated) {
                    prediction.isResolved = true;
                    prediction.payoutAmount = calculatePredictionPayout(prediction.id, _actualGrowthIndex);
                    totalPayouts = totalPayouts.add(prediction.payoutAmount);

                    int256 reputationDelta = 0;
                    if (prediction.payoutAmount > prediction.stakedAmount) {
                        reputationDelta = 5; // Reward good prediction
                    } else if (prediction.payoutAmount == 0) {
                        reputationDelta = -5; // Penalize bad prediction
                    } else {
                        reputationDelta = 1; // Small reward for partial accuracy
                    }
                    _updateReputation(prediction.predictor, reputationDelta);
                    emit PredictionResolved(prediction.id, _trendId, _actualGrowthIndex, prediction.payoutAmount);
                }
            }
        }
        // Deduct resolved payout from total staked on the trend
        trend.totalStaked = trend.totalStaked.sub(totalPayouts);
    }

    /// @notice Allows users to claim their calculated rewards for accurate predictions.
    /// @param _predictionId The ID of the prediction to claim rewards for.
    function claimPredictionRewards(uint252 _predictionId) external whenNotPaused {
        Prediction storage prediction = predictions[_predictionId];
        require(prediction.predictor == msg.sender, "AetheriaNexus: Not your prediction.");
        require(prediction.isResolved, "AetheriaNexus: Prediction not yet resolved.");
        require(!prediction.isClaimed, "AetheriaNexus: Rewards already claimed.");
        require(prediction.payoutAmount > 0, "AetheriaNexus: No payout for this prediction.");

        prediction.isClaimed = true;
        require(aethToken.transfer(msg.sender, prediction.payoutAmount), "AetheriaNexus: AETH transfer failed for rewards.");

        emit RewardsClaimed(_predictionId, msg.sender, prediction.payoutAmount);
    }

    /// @notice Enables a user to retrieve a portion of their staked amount before resolution, with a penalty.
    /// @param _predictionId The ID of the prediction to unstake from.
    function earlyUnstakePrediction(uint252 _predictionId) external whenNotPaused {
        Prediction storage prediction = predictions[_predictionId];
        require(prediction.predictor == msg.sender, "AetheriaNexus: Not your prediction.");
        require(!prediction.isResolved, "AetheriaNexus: Prediction already resolved, cannot early unstake.");
        require(block.timestamp < prediction.predictionTimestamp.add(predictionResolutionWindow), "AetheriaNexus: Too late for early unstake.");

        uint256 penalty = prediction.stakedAmount.mul(earlyUnstakePenaltyPercentage).div(100);
        uint256 amountToReturn = prediction.stakedAmount.sub(penalty);

        // Send penalty to treasury
        require(aethToken.transfer(treasuryAddress, penalty), "AetheriaNexus: Penalty transfer to treasury failed.");
        require(aethToken.transfer(msg.sender, amountToReturn), "AetheriaNexus: Early unstake return failed.");

        Trend storage trend = trends[prediction.trendId];
        trend.totalStaked = trend.totalStaked.sub(prediction.stakedAmount); // Remove full staked amount
        
        prediction.isResolved = true; // Mark as resolved to prevent future claims/resolutions
        prediction.payoutAmount = 0; // No payout for early unstake

        _updateReputation(msg.sender, -3); // Small reputation penalty for early exit
        emit EarlyUnstake(_predictionId, msg.sender, amountToReturn, penalty);
    }

    // --- III. Reputation System ---

    /// @notice Retrieves the current reputation score for a given address.
    /// @param _user The address to query reputation for.
    /// @return The reputation score.
    function getReputation(address _user) external view returns (uint256) {
        return userReputation[_user];
    }

    /// @notice Internal function to adjust a user's reputation score.
    /// @param _user The address whose reputation to adjust.
    /// @param _delta The amount to add (positive) or subtract (negative).
    function _updateReputation(address _user, int256 _delta) internal {
        if (_delta > 0) {
            userReputation[_user] = userReputation[_user].add(uint256(_delta));
        } else {
            uint256 currentRep = userReputation[_user];
            uint256 absDelta = uint256(-_delta);
            userReputation[_user] = currentRep > absDelta ? currentRep.sub(absDelta) : 0;
        }
        emit ReputationUpdated(_user, userReputation[_user]);
    }

    /// @notice Returns the minimum reputation required to submit a new trend.
    /// @return The minimum reputation value.
    function getMinReputationForSubmission() external view returns (uint256) {
        return minReputationForTrendSubmission;
    }

    // --- IV. Dynamic NFTs (Trend Laureates) ---

    /// @notice Mints a Trend Laureate NFT, associating it with a highly successful trend.
    /// @param _trendId The ID of the trend the NFT represents.
    /// @param _recipient The address to mint the NFT to.
    function mintLaureateNFT(uint256 _trendId, address _recipient) internal { // Should be called by internal logic or DAO
        Trend storage trend = trends[_trendId];
        require(trend.status == TrendStatus.Mature, "AetheriaNexus: Trend not mature enough for NFT minting.");
        require(trend.laureateNFTId == 0, "AetheriaNexus: NFT already minted for this trend.");

        uint256 laureateNFTId = nextLaureateNFTId++;
        trend.laureateNFTId = laureateNFTId;

        // Initialize some basic dynamic attributes
        _updateLaureateNFTAttributes(laureateNFTId, "trendName", trend.name);
        _updateLaureateNFTAttributes(laureateNFTId, "trendId", _trendId.toString());
        _updateLaureateNFTAttributes(laureateNFTId, "initialGrowthIndex", trend.currentGrowthIndex.toString());
        _updateLaureateNFTAttributes(laureateNFTId, "mintTimestamp", block.timestamp.toString());
        // More attributes can be added based on trend success metrics
        // e.g., "totalAETHStaked", "adoptionScore", "numberofAccuratePredictions" etc.

        emit LaureateNFTMinted(laureateNFTId, _trendId, _recipient);
    }

    /// @notice Retrieves the dynamically updating metadata for a specific Laureate NFT.
    /// @param _laureateNFTId The ID of the Laureate NFT.
    /// @return A string representing the JSON metadata (or just attributes as a mapping).
    function getLaureateNFTMetadata(uint256 _laureateNFTId) external view returns (string memory) {
        require(_laureateNFTId < nextLaureateNFTId && _laureateNFTId > 0, "AetheriaNexus: Invalid Laureate NFT ID.");

        // For simplicity, returning a concatenated string. In a real application, this would
        // either serve a JSON URI or provide a structured data response.
        string memory metadata = "Metadata for Laureate NFT ";
        metadata = string.concat(metadata, _laureateNFTId.toString(), ":\n");
        
        // This iteration is inefficient for many attributes. A proper ERC721 metadata solution
        // would likely involve a separate contract or a more sophisticated storage pattern.
        // For demonstration, iterating over a few fixed known keys.
        string memory trendName = laureateNFTAttributes[_laureateNFTId]["trendName"];
        string memory currentGrowth = laureateNFTAttributes[_laureateNFTId]["currentGrowthIndex"];
        
        metadata = string.concat(metadata, "Trend Name: ", trendName, "\n");
        metadata = string.concat(metadata, "Current Growth Index: ", currentGrowth, "\n");
        // Add more attributes as needed

        return metadata;
    }

    /// @notice Internal function to update Laureate NFT attributes.
    /// @param _laureateNFTId The ID of the Laureate NFT.
    /// @param _key The attribute key (e.g., "currentGrowthIndex").
    /// @param _value The new value for the attribute.
    function _updateLaureateNFTAttributes(uint256 _laureateNFTId, string calldata _key, string calldata _value) internal {
        laureateNFTAttributes[_laureateNFTId][_key] = _value;
        emit LaureateNFTAttributesUpdated(_laureateNFTId, _key, _value);
    }

    // --- V. Governance & System Parameters ---

    /// @notice Initiates a governance proposal to change contract parameters.
    /// @param _paramName The name of the parameter to change (e.g., "submissionBondAmount").
    /// @param _newValue The new value for the parameter.
    /// @param _quorumPercentage The percentage of total voting power required for proposal to pass (e.g., 50 for 50%).
    function proposeParameterChange(string calldata _paramName, uint256 _newValue, uint256 _quorumPercentage)
        external
        whenNotPaused
        reputationGated(minReputationForVote)
    {
        require(_quorumPercentage > 0 && _quorumPercentage <= 100, "AetheriaNexus: Quorum percentage must be between 1 and 100.");
        bytes memory pNameBytes = bytes(_paramName);
        require(pNameBytes.length > 0, "AetheriaNexus: Parameter name cannot be empty.");

        // Basic validation for paramName. A real system would have a whitelist/enum of allowed parameters.
        if (!compareStrings(_paramName, "minReputationForTrendSubmission") &&
            !compareStrings(_paramName, "minReputationForVote") &&
            !compareStrings(_paramName, "submissionBondAmount") &&
            !compareStrings(_paramName, "trendProposalVotingPeriod") &&
            !compareStrings(_paramName, "governanceVotingPeriod") &&
            !compareStrings(_paramName, "predictionResolutionWindow") &&
            !compareStrings(_paramName, "growthIndexRewardMultiplier") &&
            !compareStrings(_paramName, "earlyUnstakePenaltyPercentage")) {
            revert("AetheriaNexus: Unknown parameter name.");
        }

        uint256 proposalId = nextProposalId++;
        proposals[proposalId] = Proposal({
            id: proposalId,
            proposer: msg.sender,
            paramName: _paramName,
            newValue: _newValue,
            status: ProposalStatus.Pending,
            voteYes: 0,
            voteNo: 0,
            creationTime: block.timestamp,
            proposalEndTime: block.timestamp + governanceVotingPeriod,
            quorumPercentage: _quorumPercentage
        });

        _updateReputation(msg.sender, 5); // Reward for proposing
        emit ParameterChangeProposed(proposalId, msg.sender, _paramName, _newValue);
    }

    /// @notice Casts a vote on an active governance proposal.
    /// @param _proposalId The ID of the proposal to vote on.
    /// @param _support True to vote yes, false to vote no.
    function voteOnProposal(uint252 _proposalId, bool _support)
        external
        whenNotPaused
        reputationGated(minReputationForVote)
    {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.status == ProposalStatus.Pending, "AetheriaNexus: Proposal not in pending status.");
        require(block.timestamp <= proposal.proposalEndTime, "AetheriaNexus: Voting period has ended.");

        // More robust systems would prevent double voting using a mapping:
        // mapping(uint256 => mapping(address => bool)) public hasVotedOnProposal;
        // require(!hasVotedOnProposal[_proposalId][msg.sender], "AetheriaNexus: Already voted on this proposal.");
        // hasVotedOnProposal[_proposalId][msg.sender] = true;

        if (_support) {
            proposal.voteYes = proposal.voteYes.add(userReputation[msg.sender]); // Voting power based on reputation
        } else {
            proposal.voteNo = proposal.voteNo.add(userReputation[msg.sender]);
        }
        _updateReputation(msg.sender, 1); // Small reward for voting
        emit VoteCast(_proposalId, msg.sender, _support);
    }

    /// @notice Executes a governance proposal that has met its voting requirements.
    /// @param _proposalId The ID of the proposal to execute.
    function executeProposal(uint252 _proposalId) external whenNotPaused onlyOwner { // Can be reputation-gated for execution
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.status == ProposalStatus.Pending, "AetheriaNexus: Proposal not in pending status.");
        require(block.timestamp > proposal.proposalEndTime, "AetheriaNexus: Voting period has not ended.");

        uint256 totalVotes = proposal.voteYes.add(proposal.voteNo);
        uint256 requiredQuorum = totalVotes.mul(proposal.quorumPercentage).div(100);

        if (proposal.voteYes > proposal.voteNo && proposal.voteYes >= requiredQuorum) {
            // Proposal passes, execute the change
            if (compareStrings(proposal.paramName, "minReputationForTrendSubmission")) {
                minReputationForTrendSubmission = proposal.newValue;
            } else if (compareStrings(proposal.paramName, "minReputationForVote")) {
                minReputationForVote = proposal.newValue;
            } else if (compareStrings(proposal.paramName, "submissionBondAmount")) {
                submissionBondAmount = proposal.newValue;
            } else if (compareStrings(proposal.paramName, "trendProposalVotingPeriod")) {
                trendProposalVotingPeriod = proposal.newValue;
            } else if (compareStrings(proposal.paramName, "governanceVotingPeriod")) {
                governanceVotingPeriod = proposal.newValue;
            } else if (compareStrings(proposal.paramName, "predictionResolutionWindow")) {
                predictionResolutionWindow = proposal.newValue;
            } else if (compareStrings(proposal.paramName, "growthIndexRewardMultiplier")) {
                growthIndexRewardMultiplier = proposal.newValue;
            } else if (compareStrings(proposal.paramName, "earlyUnstakePenaltyPercentage")) {
                earlyUnstakePenaltyPercentage = proposal.newValue;
            } else {
                revert("AetheriaNexus: Unknown parameter name for execution.");
            }
            proposal.status = ProposalStatus.Executed;
            proposal.executionTime = block.timestamp;
            _updateReputation(proposal.proposer, 10); // Reward proposer for successful execution
            emit ProposalExecuted(_proposalId, proposal.paramName, proposal.newValue);
        } else {
            proposal.status = ProposalStatus.Rejected;
            _updateReputation(proposal.proposer, -5); // Penalty for rejected proposal
        }
    }

    /// @notice Sets the address of the trusted oracle.
    /// @param _newOracle The new address for the oracle.
    function setOracleAddress(address _newOracle) public onlyOwner {
        require(_newOracle != address(0), "AetheriaNexus: New oracle address cannot be zero.");
        emit OracleAddressUpdated(oracleAddress, _newOracle);
        oracleAddress = _newOracle;
    }

    /// @notice Sets the address for the project's treasury.
    /// @param _newTreasury The new address for the treasury.
    function setTreasuryAddress(address _newTreasury) public onlyOwner {
        require(_newTreasury != address(0), "AetheriaNexus: New treasury address cannot be zero.");
        emit TreasuryAddressUpdated(treasuryAddress, _newTreasury);
        treasuryAddress = _newTreasury;
    }

    /// @notice Allows the DAO/Owner to withdraw funds from the treasury.
    /// @param _recipient The address to send funds to.
    /// @param _amount The amount of AETH to withdraw.
    function withdrawTreasuryFunds(address _recipient, uint256 _amount) public onlyOwner {
        require(_recipient != address(0), "AetheriaNexus: Recipient address cannot be zero.");
        require(_amount > 0, "AetheriaNexus: Amount must be greater than zero.");
        require(aethToken.balanceOf(address(this)) >= _amount, "AetheriaNexus: Insufficient treasury balance.");
        require(aethToken.transfer(_recipient, _amount), "AetheriaNexus: Treasury withdrawal failed.");
    }

    /// @notice Pauses core contract functionalities in an emergency.
    function emergencyPause() public onlyOwner {
        _pause();
    }

    /// @notice Unpauses the contract functionalities.
    function emergencyUnpause() public onlyOwner {
        _unpause();
    }

    // --- VI. Auxiliary/Utility Functions ---

    /// @notice Internal pure function to compute prediction rewards.
    /// @param _predictionId The ID of the prediction.
    /// @param _actualGrowthIndex The actual growth index for the trend.
    /// @return The calculated payout amount for the prediction.
    function calculatePredictionPayout(uint256 _predictionId, uint256 _actualGrowthIndex) internal view returns (uint256) {
        Prediction storage prediction = predictions[_predictionId];
        uint256 diff = 0;
        if (prediction.predictedGrowthIndex > _actualGrowthIndex) {
            diff = prediction.predictedGrowthIndex.sub(_actualGrowthIndex);
        } else {
            diff = _actualGrowthIndex.sub(prediction.predictedGrowthIndex);
        }

        // Payout inversely proportional to the difference (accuracy)
        // Max accuracy (diff 0) gets max payout. Lower accuracy gets less.
        uint256 maxDiff = 100; // Max possible difference in growth index

        if (diff >= maxDiff) { // Very inaccurate prediction
            return 0;
        }

        // Base payout formula: stakedAmount * (1 - diff/maxDiff)
        // Example: stakedAmount * ((100 - diff) / 100)
        uint256 basePayout = prediction.stakedAmount.mul(maxDiff.sub(diff)).div(maxDiff);
        
        // Add a bonus for highly accurate predictions
        if (diff <= 5) { // Within 5 points of accuracy
            basePayout = basePayout.add(prediction.stakedAmount.div(2)); // 50% bonus
        } else if (diff <= 10) { // Within 10 points
            basePayout = basePayout.add(prediction.stakedAmount.div(4)); // 25% bonus
        }
        
        // Apply global reward multiplier
        basePayout = basePayout.mul(growthIndexRewardMultiplier).div(100);

        // Ensure total payout doesn't exceed a reasonable cap (e.g., 2x staked amount)
        uint256 maxPossiblePayout = prediction.stakedAmount.mul(2);
        return basePayout > maxPossiblePayout ? maxPossiblePayout : basePayout;
    }

    /// @notice Returns the current AETH balance held by the contract.
    /// @return The balance of AETH.
    function getCurrentAETHBalance() public view returns (uint256) {
        return aethToken.balanceOf(address(this));
    }

    // --- Internal Helpers ---
    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }
}
```