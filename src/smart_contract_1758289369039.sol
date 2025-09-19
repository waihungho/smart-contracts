Here's a smart contract written in Solidity, incorporating advanced concepts, creative functions, and trendy ideas, designed to be unique from common open-source implementations.

**Concept: The Epochal Reputation Nexus (ERN)**

The **Epochal Reputation Nexus (ERN)** is a decentralized system for dynamic, collective intelligence-driven reputation and contribution assessment. It introduces **Essence (SBTs)** as dynamic, non-transferable reputation tokens that visually and functionally reflect a user's standing, which evolves over time through distinct **Epochs**. Users submit **Insight Capsules** (proposals, knowledge, ideas) which are collectively endorsed, and the system learns from past outcomes to adaptively weight future contributions.

**Key Advanced Concepts & Unique Features:**

1.  **Dynamic Soulbound Tokens (dSBTs) "Essence":** Non-transferable tokens (ERC721) whose metadata (and underlying score/level) dynamically changes based on a user's activity and reputation within each epoch. This provides a living, evolving badge of contribution.
2.  **Epoch-based Reputation Cycle:** Reputation is not static. It's recalculated and updated periodically in discrete "Epochs," encouraging continuous engagement and preventing early adopter dominance.
3.  **Adaptive Endorsement Weighting (Simplified AI-like Feedback):** The influence of a user's endorsement on an "Insight Capsule" is dynamically adjusted. This adjustment is based on their overall reputation *and* the historical "success" or "relevance" of their previous endorsements. This creates a self-improving collective intelligence mechanism.
4.  **Insight Capsules:** Structured submissions (proposals, knowledge, ideas) that act as the primary means for users to contribute and earn reputation.
5.  **Modular Scoring Logic:** The core algorithm for calculating reputation (Essence scores) and evaluating Insight Capsules can be upgraded via governance by referencing different external `ICoreScoringLogic` contracts, allowing the system to evolve its intelligence over time.
6.  **Staking for Influence:** Users can stake ERC20 tokens to boost their Essence's influence in the adaptive weighting system and earn rewards, aligning incentives.
7.  **Decentralized Governance:** Critical parameters and system upgrades are controlled by community proposals and votes.
8.  **Emergency Pause:** A safety mechanism to halt critical operations in case of unforeseen issues.

---

### Contract: `EpochalReputationNexus`

**Outline:**

*   **I. Interfaces & Libraries:** Defines external contract interactions and uses OpenZeppelin utilities.
*   **II. State Variables:** Core mappings and variables for epochs, essences, insights, users, and governance.
*   **III. Events:** Declarations for logging significant actions.
*   **IV. Modifiers:** Access control and state-checking modifiers.
*   **V. Constructor:** Initializes the contract with basic parameters.
*   **VI. Core Epoch Management:** Functions related to epoch progression and status.
*   **VII. Essence (Dynamic SBT) Management:** Functions for minting, querying, and refreshing user reputation tokens.
*   **VIII. Insight Capsules & Endorsement:** Functions for submitting, querying, endorsing, and resolving insights.
*   **IX. Adaptive Weighting & Scoring Logic:** Functions for setting scoring modules and calculating dynamic weights.
*   **X. Staking & Rewards:** Functions for users to stake tokens for influence and claim rewards.
*   **XI. Governance & Security:** Functions for proposing parameter changes, voting, executing proposals, and pausing the system.
*   **XII. Internal/Helper Functions:** Utility functions called internally.

**Function Summary (26 Functions):**

**I. Core & Configuration**
1.  `constructor`: Initializes owner, epoch duration, and initial parameters.
2.  `advanceEpoch`: Triggers the end of the current epoch, initiates reputation recalculation, and starts a new epoch.
3.  `setEpochDuration`: Governance function to adjust the duration of an epoch.
4.  `getEpochDetails`: Returns current epoch number, start time, and end time.
5.  `setEssenceBaseURI`: Sets the base URI for dynamic Essence metadata (governance).

**II. Essence (Dynamic SBT) Management**
6.  `mintEssence`: Allows a user to mint their first non-transferable Essence SBT.
7.  `getEssenceScore`: Returns the current reputation score for an Essence holder.
8.  `getEssenceLevel`: Returns the derived level/tier of an Essence based on its score.
9.  `requestEssenceMetadataRefresh`: Allows an Essence holder to trigger a re-generation of their SBT's metadata URI.
10. `getEssenceTokenURI`: Returns the full metadata URI for a specific Essence.

**III. Insight Capsules & Endorsement**
11. `submitInsightCapsule`: Allows users to submit a new "insight" (proposal, idea, knowledge entry).
12. `getInsightCapsuleDetails`: Retrieves the details of a specific insight capsule.
13. `endorseInsightCapsule`: Users endorse a capsule, contributing to its overall score. Their endorsement weight is dynamic.
14. `revokeEndorsement`: Users can revoke their endorsement before an epoch ends.
15. `getCapsuleEndorsementScore`: Returns the current weighted endorsement score for a capsule.
16. `markCapsuleAsResolved`: A designated role (or DAO vote) marks a capsule as resolved, triggering a learning feedback loop.

**IV. Adaptive Weighting & Scoring Logic**
17. `setAdaptiveWeightFactor`: Governance function to adjust how strongly past accuracy influences future endorsement weight.
18. `getAdaptiveWeight`: Calculates a user's current adaptive weight based on their reputation and historical endorsement accuracy.
19. `setCoreScoringLogic`: Governance function to update the external contract defining the core reputation calculation logic.
20. `evaluateResolvedCapsuleOutcome`: (Internal/Triggered) After a capsule is resolved, this function assesses its "success" and updates endorsing users' historical accuracy.

**V. Staking & Rewards**
21. `stakeTokensForInfluence`: Users stake a certain amount of ERC20 tokens to boost their Essence's influence.
22. `withdrawStakedTokens`: Allows users to withdraw their staked tokens after a cool-down period.
23. `claimEpochRewards`: Allows Essence holders to claim epoch-specific rewards based on their reputation score.

**VI. Governance & Security**
24. `proposeAndVote`: A generalized function for proposing and voting on various system parameter changes.
25. `executeProposal`: Executes a proposal that has passed.
26. `emergencyPauseSystem`: DAO/admin function to pause critical system operations.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Base64.sol"; // For dynamic JSON metadata

// --- Interfaces & Libraries ---

// ICoreScoringLogic: Interface for external contracts that define specific reputation and capsule scoring algorithms.
// This allows the system to evolve its core intelligence without replacing the main contract.
interface ICoreScoringLogic {
    // Calculates a user's raw reputation score based on their activities within an epoch.
    // This could involve complex logic looking at endorsements, capsule resolutions, staking, etc.
    function calculateReputationScore(
        address _user,
        uint256 _epoch,
        address _ernContract // Reference to the main ERN contract for data access
    ) external view returns (uint256);

    // Determines the "success" score of a resolved insight capsule.
    // This could be based on community consensus, oracle input, or other metrics.
    function evaluateCapsuleSuccess(
        uint256 _capsuleId,
        address _ernContract // Reference to the main ERN contract for data access
    ) external view returns (uint256);
}

// Minimal ERC721 metadata interface for reference
interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// --- Contract Definition ---

contract EpochalReputationNexus is ERC721, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // --- I. State Variables ---

    // --- Epoch Management ---
    struct Epoch {
        uint256 startTime;
        uint256 endTime;
        uint256 totalEssenceSupply; // Total essences at epoch end, for reward distribution calc
        bool frozen; // True if epoch advancement is paused
    }
    mapping(uint256 => Epoch) public epochs;
    uint256 public currentEpoch;
    uint256 public epochDuration; // Duration in seconds

    // --- Essence (Dynamic SBT) ---
    Counters.Counter private _essenceTokenIds;
    mapping(address => uint256) public addressToEssenceId;
    mapping(uint256 => address) public essenceIdToAddress; // Inverse lookup
    mapping(uint256 => EssenceData) public essenceData; // Stores dynamic data for each Essence

    struct EssenceData {
        uint256 score; // Raw reputation score
        uint256 level; // Derived level from score
        uint256 lastActivityEpoch; // Last epoch the user was active/scored
        uint256 stakedTokens; // Amount of tokens staked by this Essence holder
        uint256 lastStakeChangeEpoch; // Epoch of last stake change for cool-down
        uint256 epochRewardsClaimed; // Tokens claimed in current/previous epoch
    }
    string public essenceBaseURI; // Base URI for Essence SBT metadata

    // --- Insight Capsules ---
    Counters.Counter private _capsuleIds;
    mapping(uint256 => InsightCapsule) public insightCapsules;

    enum CapsuleStatus { Pending, Resolved, Rejected }

    struct InsightCapsule {
        address submitter;
        uint256 submissionEpoch;
        string title;
        string descriptionHash; // IPFS hash or similar for long description
        CapsuleStatus status;
        uint256 totalWeightedEndorsements; // Sum of adaptive_weight * endorsement_score
        mapping(address => Endorsement) endorsers; // Track individual endorsements
        address[] endorserAddresses; // To iterate over endorsers
        uint256 resolutionEpoch; // Epoch when capsule was resolved
        uint256 successScore; // Outcome score as per ICoreScoringLogic
    }

    struct Endorsement {
        uint256 weightAtEndorsement; // User's adaptive weight when they endorsed
        uint256 endorsementScore; // A score (e.g., 1-5) given by the endorser
        uint256 timestamp;
        bool exists; // To check if an endorsement exists
    }

    // --- Adaptive Weighting & Scoring Logic ---
    ICoreScoringLogic public coreScoringLogic; // Address of the pluggable scoring logic contract
    uint256 public adaptiveWeightFactor; // How much past accuracy influences adaptive weight (e.g., 100 = 1x, 200 = 2x)

    // User accuracy stats for adaptive weighting
    mapping(address => UserAccuracyStats) public userAccuracyStats;
    struct UserAccuracyStats {
        uint256 totalSuccessfulEndorsements; // Count of 'successful' insights endorsed
        uint256 totalEndorsements; // Count of all insights endorsed
    }

    // --- Staking & Rewards ---
    IERC20 public stakingToken;
    uint256 public stakingCoolDownPeriod; // In seconds
    uint256 public totalStakedTokens;

    // --- Governance ---
    address public governorAddress; // Address authorized for governance actions (can be a DAO contract)

    struct Proposal {
        uint256 id;
        address proposer;
        string description;
        bytes callData; // Encoded function call for execution
        address targetContract; // Contract to call
        uint256 voteCount;
        mapping(address => bool) hasVoted;
        bool executed;
        uint256 creationEpoch;
        uint256 endEpoch;
    }
    Counters.Counter private _proposalIds;
    mapping(uint256 => Proposal) public proposals;

    // --- VI. Events ---
    event EpochAdvanced(uint256 indexed newEpoch, uint256 startTime, uint256 endTime);
    event EssenceMinted(address indexed owner, uint256 indexed tokenId, uint256 initialScore);
    event EssenceScoreUpdated(address indexed owner, uint256 indexed tokenId, uint256 newScore, uint256 newLevel);
    event EssenceMetadataRefreshRequested(uint256 indexed tokenId);
    event InsightCapsuleSubmitted(uint256 indexed capsuleId, address indexed submitter, uint256 epoch);
    event InsightCapsuleEndorsed(uint256 indexed capsuleId, address indexed endorser, uint256 weightUsed, uint256 endorsementScore);
    event InsightCapsuleEndorsementRevoked(uint256 indexed capsuleId, address indexed endorser);
    event InsightCapsuleResolved(uint256 indexed capsuleId, uint256 resolutionEpoch, uint256 successScore);
    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event RewardsClaimed(address indexed user, uint256 amount, uint256 epoch);
    event CoreScoringLogicSet(address indexed newLogicContract);
    event AdaptiveWeightFactorSet(uint256 newFactor);
    event EpochDurationSet(uint256 newDuration);
    event EssenceBaseURISet(string newURI);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description);
    event Voted(uint256 indexed proposalId, address indexed voter);
    event ProposalExecuted(uint256 indexed proposalId);
    event SystemPaused(address indexed by);
    event SystemUnpaused(address indexed by);

    // --- V. Modifiers ---

    modifier onlyGovernor() {
        require(msg.sender == governorAddress, "ERN: Only governor can call this function");
        _;
    }

    modifier onlyEssenceHolder(address _addr) {
        require(addressToEssenceId[_addr] != 0, "ERN: Only Essence holders can perform this action");
        _;
    }

    modifier notPaused() {
        require(!epochs[currentEpoch].frozen, "ERN: System is paused");
        _;
    }

    modifier onlyCurrentEpochNotFrozen() {
        require(!epochs[currentEpoch].frozen, "ERN: Current epoch is frozen");
        _;
    }

    modifier epochEnded() {
        require(block.timestamp >= epochs[currentEpoch].endTime, "ERN: Epoch has not ended yet");
        _;
    }

    modifier epochNotEnded() {
        require(block.timestamp < epochs[currentEpoch].endTime, "ERN: Epoch has already ended");
        _;
    }

    // --- V. Constructor ---

    constructor(
        address _governorAddress,
        uint256 _initialEpochDuration, // in seconds
        address _initialScoringLogic,
        address _stakingTokenAddress,
        uint256 _stakingCoolDown // in seconds
    ) ERC721("EssenceOfNexus", "ESSENCE") Ownable(msg.sender) {
        require(_governorAddress != address(0), "ERN: Governor address cannot be zero");
        require(_initialScoringLogic != address(0), "ERN: Scoring logic cannot be zero");
        require(_stakingTokenAddress != address(0), "ERN: Staking token cannot be zero");
        
        governorAddress = _governorAddress;
        epochDuration = _initialEpochDuration;
        coreScoringLogic = ICoreScoringLogic(_initialScoringLogic);
        stakingToken = IERC20(_stakingTokenAddress);
        stakingCoolDownPeriod = _stakingCoolDown;

        // Initialize first epoch
        currentEpoch = 1;
        epochs[currentEpoch].startTime = block.timestamp;
        epochs[currentEpoch].endTime = block.timestamp.add(epochDuration);
        epochs[currentEpoch].frozen = false;

        // Initial adaptive weight factor (e.g., 100 means past accuracy has 1x influence)
        adaptiveWeightFactor = 100;
        
        emit EpochAdvanced(currentEpoch, epochs[currentEpoch].startTime, epochs[currentEpoch].endTime);
    }

    // --- VI. Core Epoch Management ---

    /// @notice Advances the system to the next epoch, recalculating reputations and starting a new cycle.
    ///         This function can only be called once the current epoch has ended and is not frozen.
    function advanceEpoch() external notPaused epochEnded nonReentrant {
        _advanceEpoch();
    }

    /// @notice Governance function to set the duration of an epoch.
    /// @param _newDuration The new duration in seconds for subsequent epochs.
    function setEpochDuration(uint256 _newDuration) external onlyGovernor {
        require(_newDuration > 0, "ERN: Epoch duration must be positive");
        epochDuration = _newDuration;
        emit EpochDurationSet(_newDuration);
    }

    /// @notice Returns details about a specific epoch or the current one.
    /// @param _epochNumber The epoch number to query. If 0, returns current epoch details.
    function getEpochDetails(uint256 _epochNumber)
        public
        view
        returns (uint256 startTime, uint256 endTime, bool frozen, uint256 totalEssenceSupply)
    {
        uint256 epochToQuery = (_epochNumber == 0) ? currentEpoch : _epochNumber;
        Epoch storage epoch = epochs[epochToQuery];
        return (epoch.startTime, epoch.endTime, epoch.frozen, epoch.totalEssenceSupply);
    }

    /// @notice Governance function to set the base URI for Essence SBT metadata.
    /// @param _newURI The new base URI.
    function setEssenceBaseURI(string memory _newURI) external onlyGovernor {
        essenceBaseURI = _newURI;
        emit EssenceBaseURISet(_newURI);
    }

    // --- VII. Essence (Dynamic SBT) Management ---

    /// @notice Allows a user to mint their first non-transferable Essence SBT.
    ///         A user can only mint one Essence.
    function mintEssence() external notPaused nonReentrant {
        require(addressToEssenceId[msg.sender] == 0, "ERN: Already minted Essence");
        
        _essenceTokenIds.increment();
        uint256 newEssenceId = _essenceTokenIds.current();

        _mint(msg.sender, newEssenceId);
        _setApprovalForAll(msg.sender, address(0), false); // Essence is non-transferable, disable transfers explicitly

        addressToEssenceId[msg.sender] = newEssenceId;
        essenceIdToAddress[newEssenceId] = msg.sender;

        // Initial score for a new Essence (can be 0 or a base value)
        essenceData[newEssenceId].score = 100; // Base score
        essenceData[newEssenceId].level = 1;
        essenceData[newEssenceId].lastActivityEpoch = currentEpoch;

        emit EssenceMinted(msg.sender, newEssenceId, essenceData[newEssenceId].score);
    }

    /// @notice Returns the current raw reputation score for an Essence holder.
    /// @param _holder The address of the Essence holder.
    /// @return The raw reputation score.
    function getEssenceScore(address _holder) public view onlyEssenceHolder(_holder) returns (uint256) {
        return essenceData[addressToEssenceId[_holder]].score;
    }

    /// @notice Returns the derived level/tier of an Essence based on its score.
    ///         This function can be customized for different level thresholds.
    /// @param _holder The address of the Essence holder.
    /// @return The reputation level.
    function getEssenceLevel(address _holder) public view onlyEssenceHolder(_holder) returns (uint256) {
        // Example: Simple level calculation. Can be more complex.
        uint256 score = essenceData[addressToEssenceId[_holder]].score;
        if (score >= 1000) return 5;
        if (score >= 500) return 4;
        if (score >= 200) return 3;
        if (score >= 100) return 2;
        return 1;
    }

    /// @notice Allows an Essence holder to trigger a re-generation of their SBT's metadata URI.
    ///         Useful if external systems cache metadata.
    function requestEssenceMetadataRefresh() external onlyEssenceHolder(msg.sender) {
        emit EssenceMetadataRefreshRequested(addressToEssenceId[msg.sender]);
    }

    /// @notice Returns the full metadata URI for a specific Essence.
    ///         This function constructs a dynamic JSON string.
    /// @param _tokenId The ID of the Essence token.
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

        address holder = essenceIdToAddress[_tokenId];
        uint256 score = essenceData[_tokenId].score;
        uint256 level = getEssenceLevel(holder);
        uint256 currentStaked = essenceData[_tokenId].stakedTokens;
        uint256 adaptiveWeight = getAdaptiveWeight(holder);
        uint256 epochLastActive = essenceData[_tokenId].lastActivityEpoch;

        string memory name_ = string(abi.encodePacked("Essence of ", _toString(_tokenId), " (", holder.toHexString(), ")"));
        string memory description_ = string(abi.encodePacked(
            "This Essence represents the dynamic reputation of ", holder.toHexString(), 
            ". Score: ", _toString(score), ", Level: ", _toString(level), 
            ". Staked: ", _toString(currentStaked), ", Adaptive Weight: ", _toString(adaptiveWeight),
            ". Last Active Epoch: ", _toString(epochLastActive)
        ));
        
        // Construct the JSON metadata directly
        string memory json = string(abi.encodePacked(
            '{"name": "', name_,
            '", "description": "', description_,
            '", "image": "ipfs://YOUR_GENERIC_IMAGE_HASH_HERE",', // Placeholder image, could be dynamic
            '"attributes": [',
                '{"trait_type": "Essence ID", "value": "', _toString(_tokenId), '"},',
                '{"trait_type": "Holder", "value": "', holder.toHexString(), '"},',
                '{"trait_type": "Reputation Score", "value": ', _toString(score), '},',
                '{"trait_type": "Reputation Level", "value": ', _toString(level), '},',
                '{"trait_type": "Staked Tokens", "value": ', _toString(currentStaked), '},',
                '{"trait_type": "Adaptive Weight", "value": ', _toString(adaptiveWeight), '},',
                '{"trait_type": "Last Active Epoch", "value": ', _toString(epochLastActive), '}',
            ']}'
        ));

        // Use Base64 encoding to serve data URI
        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));
    }

    // --- VIII. Insight Capsules & Endorsement ---

    /// @notice Allows users to submit a new "insight" (proposal, idea, knowledge entry).
    /// @param _title The title of the insight.
    /// @param _descriptionHash IPFS hash or similar for the full description content.
    function submitInsightCapsule(string memory _title, string memory _descriptionHash)
        external
        notPaused
        onlyEssenceHolder(msg.sender)
        nonReentrant
    {
        _capsuleIds.increment();
        uint256 newCapsuleId = _capsuleIds.current();

        InsightCapsule storage capsule = insightCapsules[newCapsuleId];
        capsule.submitter = msg.sender;
        capsule.submissionEpoch = currentEpoch;
        capsule.title = _title;
        capsule.descriptionHash = _descriptionHash;
        capsule.status = CapsuleStatus.Pending;

        emit InsightCapsuleSubmitted(newCapsuleId, msg.sender, currentEpoch);
    }

    /// @notice Retrieves the details of a specific insight capsule.
    /// @param _capsuleId The ID of the insight capsule.
    function getInsightCapsuleDetails(uint256 _capsuleId)
        public
        view
        returns (address submitter, uint256 submissionEpoch, string memory title, string memory descriptionHash, CapsuleStatus status, uint256 totalWeightedEndorsements)
    {
        InsightCapsule storage capsule = insightCapsules[_capsuleId];
        require(capsule.submitter != address(0), "ERN: Capsule does not exist");
        return (
            capsule.submitter,
            capsule.submissionEpoch,
            capsule.title,
            capsule.descriptionHash,
            capsule.status,
            capsule.totalWeightedEndorsements
        );
    }

    /// @notice Users endorse a capsule, contributing to its overall score. Their endorsement weight is dynamic.
    /// @param _capsuleId The ID of the insight capsule to endorse.
    /// @param _endorsementScore A score (e.g., 1-5) given by the endorser.
    function endorseInsightCapsule(uint256 _capsuleId, uint256 _endorsementScore)
        external
        notPaused
        onlyEssenceHolder(msg.sender)
        epochNotEnded
        nonReentrant
    {
        InsightCapsule storage capsule = insightCapsules[_capsuleId];
        require(capsule.submitter != address(0), "ERN: Capsule does not exist");
        require(capsule.status == CapsuleStatus.Pending, "ERN: Capsule is not pending endorsement");
        require(capsule.submissionEpoch == currentEpoch, "ERN: Can only endorse capsules in current epoch");
        require(capsule.submitter != msg.sender, "ERN: Cannot endorse your own capsule");
        require(_endorsementScore > 0 && _endorsementScore <= 5, "ERN: Endorsement score must be 1-5");
        require(!capsule.endorsers[msg.sender].exists, "ERN: Already endorsed this capsule");

        uint256 endorserWeight = getAdaptiveWeight(msg.sender);
        require(endorserWeight > 0, "ERN: Endorser must have a positive adaptive weight");

        capsule.endorsers[msg.sender] = Endorsement({
            weightAtEndorsement: endorserWeight,
            endorsementScore: _endorsementScore,
            timestamp: block.timestamp,
            exists: true
        });
        capsule.endorserAddresses.push(msg.sender);
        capsule.totalWeightedEndorsements = capsule.totalWeightedEndorsements.add(endorserWeight.mul(_endorsementScore));

        emit InsightCapsuleEndorsed(_capsuleId, msg.sender, endorserWeight, _endorsementScore);
    }

    /// @notice Users can revoke their endorsement before an epoch ends.
    /// @param _capsuleId The ID of the insight capsule.
    function revokeEndorsement(uint256 _capsuleId) external notPaused epochNotEnded nonReentrant {
        InsightCapsule storage capsule = insightCapsules[_capsuleId];
        require(capsule.submitter != address(0), "ERN: Capsule does not exist");
        require(capsule.status == CapsuleStatus.Pending, "ERN: Capsule is not pending endorsement");
        require(capsule.endorsers[msg.sender].exists, "ERN: No active endorsement to revoke");

        // Remove endorsement from total weighted score
        Endorsement storage endorsement = capsule.endorsers[msg.sender];
        capsule.totalWeightedEndorsements = capsule.totalWeightedEndorsements.sub(
            endorsement.weightAtEndorsement.mul(endorsement.endorsementScore)
        );

        // Mark as non-existent (Safer than deleting from array, which is gas intensive)
        endorsement.exists = false;
        // For `endorserAddresses` array, we would typically swap with last element and pop,
        // but for simplicity and gas, we'll accept some "dead" addresses in the array,
        // or filter them out during iteration. This simplifies the logic.

        emit InsightCapsuleEndorsementRevoked(_capsuleId, msg.sender);
    }

    /// @notice Returns the current weighted endorsement score for a capsule.
    /// @param _capsuleId The ID of the insight capsule.
    /// @return The total weighted endorsement score.
    function getCapsuleEndorsementScore(uint256 _capsuleId) public view returns (uint256) {
        return insightCapsules[_capsuleId].totalWeightedEndorsements;
    }

    /// @notice A designated role (or DAO vote) marks a capsule as resolved, triggering a learning feedback loop.
    /// @param _capsuleId The ID of the insight capsule.
    /// @param _wasSuccessful A boolean indicating if the capsule was deemed successful.
    // (In a more complex system, _wasSuccessful would be derived from governance/oracle/ICoreScoringLogic)
    function markCapsuleAsResolved(uint256 _capsuleId, bool _wasSuccessful) external onlyGovernor {
        // Can be extended to allow submitter to mark as resolved, or specific mods
        InsightCapsule storage capsule = insightCapsules[_capsuleId];
        require(capsule.submitter != address(0), "ERN: Capsule does not exist");
        require(capsule.status == CapsuleStatus.Pending, "ERN: Capsule is not pending resolution");

        capsule.status = CapsuleStatus.Resolved;
        capsule.resolutionEpoch = currentEpoch;
        
        // This is a simplified success determination. In a real system, `evaluateCapsuleSuccess`
        // of `coreScoringLogic` would be called here. For this example, we use a direct bool.
        capsule.successScore = _wasSuccessful ? 100 : 0; // Simplified score

        // Trigger the learning feedback loop for endorsers
        _evaluateResolvedCapsuleOutcome(_capsuleId);

        emit InsightCapsuleResolved(_capsuleId, currentEpoch, capsule.successScore);
    }

    // --- IX. Adaptive Weighting & Scoring Logic ---

    /// @notice Governance function to adjust how strongly past accuracy influences future endorsement weight.
    /// @param _newFactor The new adaptive weight factor (e.g., 100 for 1x influence, 200 for 2x).
    function setAdaptiveWeightFactor(uint256 _newFactor) external onlyGovernor {
        adaptiveWeightFactor = _newFactor;
        emit AdaptiveWeightFactorSet(_newFactor);
    }

    /// @notice Calculates a user's current adaptive weight based on their reputation and historical endorsement accuracy.
    /// @param _user The address of the user.
    /// @return The calculated adaptive weight.
    function getAdaptiveWeight(address _user) public view returns (uint256) {
        if (addressToEssenceId[_user] == 0) return 0; // Non-essence holders have no weight

        uint256 essenceScore = essenceData[addressToEssenceId[_user]].score;
        uint256 stakedInfluence = essenceData[addressToEssenceId[_user]].stakedTokens.div(100); // 100 staked tokens = 1 point influence

        UserAccuracyStats storage stats = userAccuracyStats[_user];
        uint256 accuracyBonus = 0;
        if (stats.totalEndorsements > 0) {
            uint256 accuracy = (stats.totalSuccessfulEndorsements.mul(100)).div(stats.totalEndorsements); // Percentage
            accuracyBonus = (accuracy.mul(adaptiveWeightFactor)).div(10000); // Scales accuracy by factor
        }

        // Base weight from score + staked influence + accuracy bonus
        // A simple formula for demonstration. Could be more complex.
        return essenceScore.div(100).add(stakedInfluence).add(accuracyBonus);
    }

    /// @notice Governance function to update the external contract defining the core reputation calculation logic.
    /// @param _newLogicContract The address of the new ICoreScoringLogic contract.
    function setCoreScoringLogic(address _newLogicContract) external onlyGovernor {
        require(_newLogicContract != address(0), "ERN: New scoring logic cannot be zero");
        coreScoringLogic = ICoreScoringLogic(_newLogicContract);
        emit CoreScoringLogicSet(_newLogicContract);
    }

    // --- X. Staking & Rewards ---

    /// @notice Users stake a certain amount of ERC20 tokens to boost their Essence's influence.
    /// @param _amount The amount of tokens to stake.
    function stakeTokensForInfluence(uint256 _amount) external notPaused onlyEssenceHolder(msg.sender) nonReentrant {
        require(_amount > 0, "ERN: Must stake a positive amount");
        
        uint256 essenceId = addressToEssenceId[msg.sender];
        
        require(stakingToken.transferFrom(msg.sender, address(this), _amount), "ERN: Token transfer failed");

        essenceData[essenceId].stakedTokens = essenceData[essenceId].stakedTokens.add(_amount);
        essenceData[essenceId].lastStakeChangeEpoch = currentEpoch;
        totalStakedTokens = totalStakedTokens.add(_amount);

        emit Staked(msg.sender, _amount);
    }

    /// @notice Allows users to withdraw their staked tokens after a cool-down period.
    /// @param _amount The amount of tokens to withdraw.
    function withdrawStakedTokens(uint256 _amount) external notPaused onlyEssenceHolder(msg.sender) nonReentrant {
        uint256 essenceId = addressToEssenceId[msg.sender];
        require(essenceData[essenceId].stakedTokens >= _amount, "ERN: Insufficient staked tokens");
        require(_amount > 0, "ERN: Must withdraw a positive amount");

        // Check cool-down period if stake has changed recently
        if (essenceData[essenceId].lastStakeChangeEpoch == currentEpoch) {
            require(block.timestamp >= epochs[currentEpoch].endTime.add(stakingCoolDownPeriod), "ERN: Staking cooldown period not over");
        }

        essenceData[essenceId].stakedTokens = essenceData[essenceId].stakedTokens.sub(_amount);
        totalStakedTokens = totalStakedTokens.sub(_amount);
        essenceData[essenceId].lastStakeChangeEpoch = currentEpoch; // Reset cooldown for next withdrawal/stake

        require(stakingToken.transfer(msg.sender, _amount), "ERN: Token withdrawal failed");

        emit Unstaked(msg.sender, _amount);
    }

    /// @notice Allows Essence holders to claim epoch-specific rewards based on their reputation score.
    ///         Rewards are distributed from a pool. (Simplified for this example)
    function claimEpochRewards() external notPaused onlyEssenceHolder(msg.sender) nonReentrant {
        uint256 essenceId = addressToEssenceId[msg.sender];
        require(essenceData[essenceId].lastActivityEpoch < currentEpoch, "ERN: Rewards for current epoch not yet available");
        require(essenceData[essenceId].epochRewardsClaimed == 0, "ERN: Rewards already claimed for previous epoch");
        
        // Simplified reward calculation: 1% of score per epoch (can be more complex)
        // This would ideally come from a separate reward pool/treasury.
        uint256 rewards = essenceData[essenceId].score.div(100); 
        require(rewards > 0, "ERN: No rewards to claim");

        // Transfer rewards (e.g., using stakingToken or a separate reward token)
        // For simplicity, we'll assume rewards are paid in the staking token.
        require(stakingToken.transfer(msg.sender, rewards), "ERN: Reward transfer failed");
        
        essenceData[essenceId].epochRewardsClaimed = rewards;

        emit RewardsClaimed(msg.sender, rewards, essenceData[essenceId].lastActivityEpoch);
    }

    // --- XI. Governance & Security ---

    /// @notice A generalized function for proposing and voting on various system parameter changes.
    /// @param _description Description of the proposal.
    /// @param _callData Encoded function call to execute if proposal passes.
    /// @param _targetContract The address of the target contract for the callData.
    /// @param _durationEpochs Duration of the voting period in epochs.
    function proposeAndVote(
        string memory _description,
        bytes memory _callData,
        address _targetContract,
        uint256 _durationEpochs
    ) external onlyEssenceHolder(msg.sender) nonReentrant {
        require(_callData.length > 0, "ERN: Call data cannot be empty");
        require(_targetContract != address(0), "ERN: Target contract cannot be zero address");
        require(_durationEpochs > 0, "ERN: Proposal duration must be at least 1 epoch");

        _proposalIds.increment();
        uint256 newProposalId = _proposalIds.current();

        proposals[newProposalId] = Proposal({
            id: newProposalId,
            proposer: msg.sender,
            description: _description,
            callData: _callData,
            targetContract: _targetContract,
            voteCount: 0,
            hasVoted: new mapping(address => bool),
            executed: false,
            creationEpoch: currentEpoch,
            endEpoch: currentEpoch.add(_durationEpochs)
        });

        // Proposer automatically votes yes
        _vote(newProposalId, msg.sender);

        emit ProposalCreated(newProposalId, msg.sender, _description);
    }

    /// @notice Allows Essence holders to vote on open proposals.
    /// @param _proposalId The ID of the proposal to vote on.
    function voteOnProposal(uint256 _proposalId) external onlyEssenceHolder(msg.sender) nonReentrant {
        _vote(_proposalId, msg.sender);
    }

    /// @notice Executes a proposal that has passed its voting period and reached the required threshold.
    ///         For simplicity, a passing threshold is 51% of current active essences.
    /// @param _proposalId The ID of the proposal to execute.
    function executeProposal(uint256 _proposalId) external onlyGovernor nonReentrant {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposer != address(0), "ERN: Proposal does not exist");
        require(!proposal.executed, "ERN: Proposal already executed");
        require(currentEpoch > proposal.endEpoch, "ERN: Voting period not over");

        // Simplified threshold: 51% of total essences at proposal creation epoch
        // This requires `epochs[proposal.creationEpoch].totalEssenceSupply` to be accurate
        // (Set during _advanceEpoch). For now, we'll use a simpler threshold.
        uint256 requiredVotes = _essenceTokenIds.current().mul(51).div(100);
        require(proposal.voteCount >= requiredVotes, "ERN: Proposal did not pass vote threshold");

        (bool success, ) = proposal.targetContract.call(proposal.callData);
        require(success, "ERN: Proposal execution failed");

        proposal.executed = true;
        emit ProposalExecuted(_proposalId);
    }
    
    /// @notice Emergency function to pause critical system operations.
    ///         Only the governor can freeze an epoch.
    function emergencyPauseSystem() external onlyGovernor {
        require(!epochs[currentEpoch].frozen, "ERN: System already paused");
        epochs[currentEpoch].frozen = true;
        emit SystemPaused(msg.sender);
    }

    /// @notice Emergency function to unpause critical system operations.
    ///         Only the governor can unfreeze an epoch.
    function emergencyUnpauseSystem() external onlyGovernor {
        require(epochs[currentEpoch].frozen, "ERN: System not paused");
        epochs[currentEpoch].frozen = false;
        emit SystemUnpaused(msg.sender);
    }

    // --- XII. Internal/Helper Functions ---

    /// @dev Internal function to handle epoch advancement logic.
    function _advanceEpoch() internal {
        // Finalize current epoch's data
        epochs[currentEpoch].totalEssenceSupply = _essenceTokenIds.current();

        // Calculate and update reputation scores for all active essences
        _recalculateAllEssenceScores();

        // Prepare next epoch
        currentEpoch = currentEpoch.add(1);
        epochs[currentEpoch].startTime = block.timestamp;
        epochs[currentEpoch].endTime = block.timestamp.add(epochDuration);
        epochs[currentEpoch].frozen = false;

        emit EpochAdvanced(currentEpoch, epochs[currentEpoch].startTime, epochs[currentEpoch].endTime);
    }

    /// @dev Internal function to recalculate reputation for all essences.
    /// This function iterates through all minted Essence tokens. For large numbers of users,
    /// this would need to be offloaded to a separate contract/mechanism (e.g., merkle tree,
    /// or allowing users to trigger their own update). For this example, it's in-line.
    function _recalculateAllEssenceScores() internal {
        for (uint256 i = 1; i <= _essenceTokenIds.current(); i++) {
            address holder = essenceIdToAddress[i];
            if (holder != address(0)) {
                uint256 oldScore = essenceData[i].score;
                uint256 newScore = coreScoringLogic.calculateReputationScore(holder, currentEpoch.sub(1), address(this));
                
                // Incorporate decay: if user inactive, decay their score
                if (essenceData[i].lastActivityEpoch < currentEpoch.sub(1)) {
                    newScore = newScore.mul(90).div(100); // 10% decay per inactive epoch
                }

                essenceData[i].score = newScore;
                essenceData[i].level = getEssenceLevel(holder); // Recalculate level
                essenceData[i].lastActivityEpoch = currentEpoch; // Mark as active for scoring
                essenceData[i].epochRewardsClaimed = 0; // Reset rewards claim for new epoch

                if (newScore != oldScore) {
                    emit EssenceScoreUpdated(holder, i, newScore, essenceData[i].level);
                }
            }
        }
    }

    /// @dev Internal function to evaluate the outcome of a resolved capsule and update endorser accuracy.
    function _evaluateResolvedCapsuleOutcome(uint256 _capsuleId) internal {
        InsightCapsule storage capsule = insightCapsules[_capsuleId];
        // The success score is already set in markCapsuleAsResolved in this simplified example.
        // In a real system, it would call:
        // uint256 successScore = coreScoringLogic.evaluateCapsuleSuccess(_capsuleId, address(this));

        bool capsuleWasSuccessful = capsule.successScore > 50; // Threshold for success

        for (uint256 i = 0; i < capsule.endorserAddresses.length; i++) {
            address endorser = capsule.endorserAddresses[i];
            Endorsement storage endorsement = capsule.endorsers[endorser];

            // Only count active endorsements
            if (endorsement.exists) {
                userAccuracyStats[endorser].totalEndorsements = userAccuracyStats[endorser].totalEndorsements.add(1);
                if (capsuleWasSuccessful) {
                    userAccuracyStats[endorser].totalSuccessfulEndorsements = userAccuracyStats[endorser].totalSuccessfulEndorsements.add(1);
                }
            }
        }
    }

    /// @dev Internal function for voting logic.
    function _vote(uint256 _proposalId, address _voter) internal {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposer != address(0), "ERN: Proposal does not exist");
        require(!proposal.executed, "ERN: Proposal already executed");
        require(currentEpoch <= proposal.endEpoch, "ERN: Voting period has ended");
        require(!proposal.hasVoted[_voter], "ERN: Already voted on this proposal");

        proposal.hasVoted[_voter] = true;
        proposal.voteCount = proposal.voteCount.add(1);

        emit Voted(_proposalId, _voter);
    }

    /// @dev Converts a uint256 to its string representation.
    function _toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits--;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    // Override `_approve` and `_setApprovalForAll` to prevent Essence transfers (SBT concept)
    function _approve(address to, uint256 tokenId) internal override {
        revert("ERN: Essence is non-transferable");
    }

    function _setApprovalForAll(address owner, address operator, bool approved) internal override {
        revert("ERN: Essence is non-transferable");
    }

    // Explicitly disallow transfers
    function transferFrom(address from, address to, uint256 tokenId) public pure override {
        revert("ERN: Essence is non-transferable");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public pure override {
        revert("ERN: Essence is non-transferable");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public pure override {
        revert("ERN: Essence is non-transferable");
    }
}
```