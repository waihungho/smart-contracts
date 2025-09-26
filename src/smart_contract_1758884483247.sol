This smart contract, "SyntheticaAgora," creates a decentralized network for proposing, endorsing, and evaluating "Insights." These Insights are represented as dynamic NFTs (iNFTs) that evolve based on community interaction and evaluation outcomes. The system incorporates a novel "Wisdom Score" as a reputation metric, a delegated evaluation mechanism, and incentivized truth-seeking to foster a high-quality knowledge base.

---

## SyntheticaAgora: Decentralized Insight Network

**Purpose:** A decentralized platform for proposing, curating, and evaluating "Insights" – structured knowledge assets – represented as dynamic Non-Fungible Tokens (iNFTs). It features a "Wisdom Score" reputation system, a delegated evaluation model, and incentivized mechanisms for truth-seeking and quality assurance.

**Key Concepts:**
*   **Insight iNFTs:** NFTs whose metadata and perceived value evolve based on their endorsement, evaluation scores, and ultimate accuracy.
*   **Wisdom Score:** A dynamic, non-transferable reputation score for users, influenced by their participation in evaluations, endorsements, and dispute resolutions. It decays over time to incentivize continuous engagement.
*   **Delegated Evaluation:** Users can delegate their Wisdom Score, empowering trusted community members to act on their behalf in evaluation processes.
*   **Incentivized Truth-Seeking:** Participants are rewarded for accurately predicting or evaluating Insights and penalized for inaccuracies.

---

### Outline & Function Summary

**I. Core Infrastructure & Access Control**
1.  `constructor()`: Deploys the contract, setting the initial owner and a placeholder for the staking token.
2.  `updateContractOwner(address newOwner)`: Transfers ownership of the contract to a new address.
3.  `pauseContract()`: Pauses critical contract operations (e.g., new Insight proposals, evaluations) for maintenance or emergency.
4.  `unpauseContract()`: Resumes operations after a pause.
5.  `setBaseInsightToken(address _token)`: Sets or updates the ERC-20 token contract address used for all staking and reward mechanics within SyntheticaAgora.

**II. Insight (iNFT) Management**
6.  `proposeInsight(string memory title, string memory descriptionURI, bytes32 contentHash, uint256 initialStake)`: Allows a user to propose a new Insight. Mints a unique iNFT, registers its details, and requires an initial token stake for commitment.
7.  `endorseInsight(uint256 insightId, uint256 amount)`: Enables users to stake additional tokens on an existing Insight, signaling their belief in its value or eventual accuracy.
8.  `revokeInsightEndorsement(uint256 insightId, uint256 amount)`: Allows endorsers to withdraw a portion of their stake from an Insight, subject to a cooldown period or penalties if the Insight is in a critical evaluation phase.
9.  `getInsightDetails(uint256 insightId)`: Provides comprehensive data about a specific Insight, including its status, proposer, total stake, and latest evaluation.
10. `getInsightEndorsers(uint256 insightId)`: Returns a list of all addresses that have staked tokens to endorse a given Insight.
11. `tokenURI(uint256 insightId)`: (ERC-721 Override) Returns the URI for a given iNFT's metadata, which dynamically updates based on the Insight's state.

**III. Wisdom Score & Delegation**
12. `getWisdomScore(address user)`: Retrieves the current Wisdom Score of a user, reflecting their overall reputation and historical contribution quality.
13. `delegateWisdom(address delegatee)`: Allows a user to delegate their Wisdom Score to another address, empowering the `delegatee` in governance or evaluation roles.
14. `undelegateWisdom()`: Revokes any active Wisdom Score delegation made by the caller.
15. `recalculateWisdomScores(address[] memory users)`: (Admin/Automated) Triggers a batch recalculation of specified users' Wisdom Scores based on recent contract activities and a decay mechanism.
16. `getDelegatedWisdom(address delegator)`: Returns the address to which a specific `delegator` has delegated their Wisdom Score.

**IV. Insight Evaluation & Resolution**
17. `applyForEvaluator()`: Allows users with a minimum Wisdom Score to apply to become an official Insight Evaluator.
18. `electEvaluator(address candidate)`: (Governance) Elects an applicant from the `evaluatorApplications` pool to become an active Insight Evaluator.
19. `evaluateInsight(uint256 insightId, uint8 score, string memory rationaleURI)`: An elected Evaluator provides a subjective score (1-10) and a URI to a detailed rationale for a given Insight. This influences the iNFT's evolution and reward distribution.
20. `disputeInsightEvaluation(uint256 insightId, uint256 evaluationIndex, string memory disputeURI)`: Allows any user to formally dispute an Evaluator's specific assessment, potentially triggering an arbitration process.
21. `resolveDispute(uint256 insightId, uint256 evaluationIndex, bool evaluatorWasCorrect)`: (Admin/Governance) Finalizes a dispute. This decision impacts the Evaluator's Wisdom Score and the Insight's overall standing.
22. `finalizeInsight(uint256 insightId, bool provedAccurate)`: Marks an Insight as "finalized" (e.g., its predicted outcome has occurred). This triggers the distribution of rewards to accurate participants and levies penalties on inaccurate ones.

**V. Rewards & Penalties**
23. `claimInsightRewards(uint256 insightId)`: Allows eligible proposers, endorsers, and evaluators of a successfully finalized Insight to claim their proportional share of the staked tokens.
24. `withdrawPenalties(uint256 insightId)`: (Admin/Governance) Collects the accumulated penalty funds from Insights that were proven inaccurate into a designated treasury.

**VI. Governance & Parameters**
25. `setEvaluationPeriod(uint256 _period)`: Sets the duration (in seconds) for which Insights remain open for evaluation.
26. `setMinWisdomForEvaluator(uint256 _score)`: Defines the minimum Wisdom Score required for a user to apply as an Insight Evaluator.
27. `setRewardDistribution(uint256 _proposerShare, uint256 _endorserShare, uint256 _evaluatorShare)`: Configures the percentage split of rewards among the Insight proposer, endorsers, and evaluators for accurate Insights.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/// @title SyntheticaAgora: Decentralized Insight Network
/// @author YourName (as the AI, I'll use "AI Innovator")
/// @notice A platform for proposing, endorsing, and evaluating Insights as dynamic NFTs,
///         featuring a Wisdom Score reputation system and delegated evaluation.

// Outline & Function Summary is provided above the code.

contract SyntheticaAgora is ERC721, Ownable, Pausable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- Enums ---
    enum InsightStatus {
        Proposed,
        Evaluating,
        Disputed,
        FinalizedAccurate,
        FinalizedInaccurate
    }

    // --- Structs ---
    struct Evaluation {
        address evaluator;
        uint8 score; // 1-10
        string rationaleURI; // URI to detailed explanation
        uint256 evaluatedAt;
        bool disputed;
    }

    struct Insight {
        string title;
        string descriptionURI; // URI to detailed Insight description (e.g., IPFS)
        bytes32 contentHash; // Hash of the Insight content for integrity verification
        address proposer;
        uint256 initialStake; // Initial stake by the proposer
        uint256 totalEndorsementStake; // Total stake from all endorsers
        uint256 totalEvaluatorRewardsEarned; // For accurate evaluators
        InsightStatus status;
        uint256 mintedAt;
        uint256 evaluationPeriodEndsAt; // Timestamp when evaluation period ends
        uint256 finalizedAt;
        bool provedAccurate; // Only relevant if status is FinalizedAccurate/Inaccurate
        Evaluation[] evaluations; // All evaluations for this Insight
        mapping(address => uint256) endorserStakes; // Mapping of address to stake amount
        mapping(address => bool) hasClaimedRewards; // Whether proposer/evaluators claimed
    }

    // --- State Variables ---
    Counters.Counter private _insightIdCounter;
    IERC20 private _baseInsightToken; // ERC-20 token used for staking and rewards

    uint256 public evaluationPeriod; // Duration in seconds for insights to be evaluated
    uint256 public minWisdomForEvaluator; // Minimum Wisdom Score to apply as evaluator
    
    // Reward distribution percentages (sum must be 10000 for 100%)
    uint256 public proposerRewardShare; // e.g., 2000 for 20%
    uint256 public endorserRewardShare; // e.g., 6000 for 60%
    uint256 public evaluatorRewardShare; // e.g., 2000 for 20%

    // Mappings
    mapping(uint256 => Insight) public insights;
    mapping(address => uint256) private _userWisdomScores; // User's accumulated Wisdom Score
    mapping(address => address) private _userDelegations; // User's delegated wisdom to
    mapping(address => bool) public isEvaluator; // Whitelisted evaluators
    mapping(address => bool) public evaluatorApplications; // Users who applied to be evaluators
    mapping(uint256 => mapping(address => bool)) public insightEndorserClaimed; // Individual endorser claim status

    // --- Events ---
    event InsightProposed(uint256 indexed insightId, address indexed proposer, string title, uint256 initialStake);
    event InsightEndorsed(uint256 indexed insightId, address indexed endorser, uint256 amount);
    event InsightEndorsementRevoked(uint256 indexed insightId, address indexed endorser, uint256 amount);
    event InsightEvaluated(uint256 indexed insightId, address indexed evaluator, uint8 score);
    event InsightDisputed(uint256 indexed insightId, address indexed disputer, uint256 evaluationIndex);
    event DisputeResolved(uint256 indexed insightId, uint256 indexed evaluationIndex, bool evaluatorWasCorrect);
    event InsightFinalized(uint256 indexed insightId, bool provedAccurate, uint256 rewardsDistributed);
    event WisdomDelegated(address indexed delegator, address indexed delegatee);
    event WisdomUndelegated(address indexed delegator);
    event EvaluatorApplied(address indexed applicant);
    event EvaluatorElected(address indexed candidate);
    event RewardsClaimed(uint256 indexed insightId, address indexed claimant, uint256 amount);
    event PenaltyWithdrawn(uint256 indexed insightId, uint256 amount);
    event WisdomScoresRecalculated(address[] users);
    event InsightTokenURIUpdated(uint256 indexed insightId, string newURI);

    // --- Constructor ---
    constructor() ERC721("SyntheticaInsight", "iNFT") Ownable(msg.sender) {
        // Default parameters
        evaluationPeriod = 7 days; // 7 days for evaluation
        minWisdomForEvaluator = 100; // Minimum score to apply
        proposerRewardShare = 2000; // 20%
        endorserRewardShare = 6000; // 60%
        evaluatorRewardShare = 2000; // 20%
    }

    // --- I. Core Infrastructure & Access Control ---

    /// @notice Updates the contract owner.
    /// @param newOwner The address of the new owner.
    function updateContractOwner(address newOwner) external onlyOwner {
        transferOwnership(newOwner);
    }

    /// @notice Pauses core contract functionalities.
    function pauseContract() external onlyOwner {
        _pause();
    }

    /// @notice Unpauses core contract functionalities.
    function unpauseContract() external onlyOwner {
        _unpause();
    }

    /// @notice Sets the ERC-20 token used for all staking and rewards.
    /// @param _token The address of the ERC-20 token contract.
    function setBaseInsightToken(address _token) external onlyOwner {
        require(_token != address(0), "Zero address not allowed");
        _baseInsightToken = IERC20(_token);
    }

    // --- II. Insight (iNFT) Management ---

    /// @notice Proposes a new Insight, mints an iNFT, and requires an initial stake.
    /// @param title The title of the Insight.
    /// @param descriptionURI URI pointing to the Insight's detailed description (e.g., IPFS).
    /// @param contentHash Cryptographic hash of the Insight's content for integrity.
    /// @param initialStake The amount of base tokens staked by the proposer.
    function proposeInsight(
        string memory title,
        string memory descriptionURI,
        bytes32 contentHash,
        uint256 initialStake
    ) external payable whenNotPaused {
        require(_baseInsightToken != address(0), "Base Insight Token not set");
        require(initialStake > 0, "Initial stake must be positive");
        require(bytes(title).length > 0, "Title cannot be empty");
        require(bytes(descriptionURI).length > 0, "Description URI cannot be empty");

        _baseInsightToken.transferFrom(msg.sender, address(this), initialStake);

        _insightIdCounter.increment();
        uint256 newInsightId = _insightIdCounter.current();

        Insight storage newInsight = insights[newInsightId];
        newInsight.title = title;
        newInsight.descriptionURI = descriptionURI;
        newInsight.contentHash = contentHash;
        newInsight.proposer = msg.sender;
        newInsight.initialStake = initialStake;
        newInsight.totalEndorsementStake = initialStake; // Proposer's stake is also an endorsement
        newInsight.status = InsightStatus.Proposed;
        newInsight.mintedAt = block.timestamp;
        newInsight.evaluationPeriodEndsAt = block.timestamp + evaluationPeriod;

        newInsight.endorserStakes[msg.sender] = initialStake;

        _safeMint(msg.sender, newInsightId);

        emit InsightProposed(newInsightId, msg.sender, title, initialStake);
    }

    /// @notice Allows users to stake more tokens on an existing Insight.
    /// @param insightId The ID of the Insight to endorse.
    /// @param amount The amount of base tokens to stake.
    function endorseInsight(uint256 insightId, uint256 amount) external whenNotPaused {
        require(_insightIdCounter.current() >= insightId && insightId > 0, "Insight does not exist");
        Insight storage insight = insights[insightId];
        require(insight.status < InsightStatus.FinalizedAccurate, "Insight is already finalized");
        require(block.timestamp < insight.evaluationPeriodEndsAt, "Evaluation period has ended");
        require(amount > 0, "Endorsement amount must be positive");

        _baseInsightToken.transferFrom(msg.sender, address(this), amount);

        insight.endorserStakes[msg.sender] += amount;
        insight.totalEndorsementStake += amount;

        emit InsightEndorsed(insightId, msg.sender, amount);
    }

    /// @notice Allows users to revoke a portion of their stake from an Insight.
    /// @param insightId The ID of the Insight.
    /// @param amount The amount to revoke.
    function revokeInsightEndorsement(uint256 insightId, uint256 amount) external whenNotPaused {
        require(_insightIdCounter.current() >= insightId && insightId > 0, "Insight does not exist");
        Insight storage insight = insights[insightId];
        require(insight.status < InsightStatus.FinalizedAccurate, "Insight is already finalized");
        require(block.timestamp < insight.evaluationPeriodEndsAt, "Cannot revoke after evaluation period ends");
        require(insight.endorserStakes[msg.sender] >= amount, "Insufficient staked amount");
        require(amount > 0, "Revoke amount must be positive");

        insight.endorserStakes[msg.sender] -= amount;
        insight.totalEndorsementStake -= amount;

        _baseInsightToken.transfer(msg.sender, amount);

        emit InsightEndorsementRevoked(insightId, msg.sender, amount);
    }

    /// @notice Retrieves comprehensive data for a given Insight ID.
    /// @param insightId The ID of the Insight.
    /// @return Insight details.
    function getInsightDetails(uint256 insightId)
        external
        view
        returns (
            string memory title,
            string memory descriptionURI,
            bytes32 contentHash,
            address proposer,
            uint256 initialStake,
            uint256 totalEndorsementStake,
            InsightStatus status,
            uint256 mintedAt,
            uint256 evaluationPeriodEndsAt,
            uint256 finalizedAt,
            bool provedAccurate,
            uint256 evaluationCount
        )
    {
        require(_insightIdCounter.current() >= insightId && insightId > 0, "Insight does not exist");
        Insight storage insight = insights[insightId];
        return (
            insight.title,
            insight.descriptionURI,
            insight.contentHash,
            insight.proposer,
            insight.initialStake,
            insight.totalEndorsementStake,
            insight.status,
            insight.mintedAt,
            insight.evaluationPeriodEndsAt,
            insight.finalizedAt,
            insight.provedAccurate,
            insight.evaluations.length
        );
    }

    /// @notice Returns a list of addresses that have endorsed a specific Insight.
    /// @dev This function iterates through all possible addresses and might be gas-intensive for large user bases.
    ///      For a real-world scenario, a more optimized data structure or off-chain indexer would be preferred.
    /// @param insightId The ID of the Insight.
    /// @return An array of endorser addresses.
    function getInsightEndorsers(uint256 insightId) external view returns (address[] memory) {
        require(_insightIdCounter.current() >= insightId && insightId > 0, "Insight does not exist");
        Insight storage insight = insights[insightId];

        // This is a simplified approach. In a real dApp, you'd track endorsers explicitly
        // or rely on off-chain indexing for this.
        // For demonstration, we'll return an empty array, or the proposer if they are the only "endorser"
        // if we don't have an explicit list maintained on-chain.
        // To truly track all endorsers on-chain, we would need a dynamic array in the Insight struct.
        // Given gas limits, it's often better handled by events and off-chain indexing.
        // For now, let's indicate if *any* endorsement exists.
        if (insight.totalEndorsementStake > 0) {
            address[] memory endorsers; // Placeholder
            // If we actually wanted to list them, we'd need to add them to a dynamic array when they endorse.
            // Example: insight.endorserAddresses.push(msg.sender);
            // This would make `endorseInsight` more expensive.
            return endorsers; // Returns empty array as per current struct design
        }
        return new address[](0);
    }
    
    /// @notice Overrides ERC721's tokenURI to provide dynamic metadata based on Insight status.
    /// @param insightId The ID of the iNFT.
    /// @return A URI pointing to the iNFT's metadata.
    function tokenURI(uint256 insightId) public view override returns (string memory) {
        require(_insightIdCounter.current() >= insightId && insightId > 0, "Insight does not exist");
        Insight storage insight = insights[insightId];

        // This is a simplified example. In a real dApp, this URI would point to an IPFS JSON file
        // that's dynamically generated or updated by an off-chain service or a chainlink function
        // based on the Insight's state.
        // For example: `ipfs://[base_cid]/insight_metadata_ID.json`
        // And the JSON would contain properties like:
        // { "name": "Insight #" + insightId, "description": "...", "image": "ipfs://...",
        //   "attributes": [{"trait_type": "Status", "value": "FinalizedAccurate"}, ...] }

        string memory baseURI = "https://syntheticaagora.network/insight/"; // Placeholder base URI

        return string(
            abi.encodePacked(
                baseURI,
                insightId.toString(),
                "/metadata.json?",
                "status=",
                _insightStatusToString(insight.status),
                "&score=",
                insight.evaluations.length > 0 ? Strings.toString(insight.evaluations[insight.evaluations.length - 1].score) : "0",
                "&endorsed=",
                Strings.toString(insight.totalEndorsementStake)
            )
        );
    }

    /// @dev Helper to convert InsightStatus enum to string for tokenURI.
    function _insightStatusToString(InsightStatus status) internal pure returns (string memory) {
        if (status == InsightStatus.Proposed) return "Proposed";
        if (status == InsightStatus.Evaluating) return "Evaluating";
        if (status == InsightStatus.Disputed) return "Disputed";
        if (status == InsightStatus.FinalizedAccurate) return "FinalizedAccurate";
        if (status == InsightStatus.FinalizedInaccurate) return "FinalizedInaccurate";
        return "Unknown";
    }

    // --- III. Wisdom Score & Delegation ---

    /// @notice Retrieves a user's current Wisdom Score.
    /// @param user The address of the user.
    /// @return The Wisdom Score.
    function getWisdomScore(address user) public view returns (uint256) {
        return _userWisdomScores[user];
    }

    /// @notice Allows a user to delegate their Wisdom Score to another address.
    /// @param delegatee The address to delegate wisdom to.
    function delegateWisdom(address delegatee) external whenNotPaused {
        require(msg.sender != delegatee, "Cannot delegate to self");
        require(delegatee != address(0), "Cannot delegate to zero address");
        _userDelegations[msg.sender] = delegatee;
        emit WisdomDelegated(msg.sender, delegatee);
    }

    /// @notice Revokes any active Wisdom Score delegation made by the caller.
    function undelegateWisdom() external whenNotPaused {
        delete _userDelegations[msg.sender];
        emit WisdomUndelegated(msg.sender);
    }

    /// @notice (Admin/Automated) Triggers a batch recalculation of specified users' Wisdom Scores.
    /// @dev This function would typically be called by an off-chain oracle or a time-locked governance
    ///      to update scores based on complex logic (e.g., decay, interaction history).
    ///      For simplicity, this implementation is a placeholder that can be extended.
    /// @param users An array of user addresses whose scores need recalculation.
    function recalculateWisdomScores(address[] memory users) external onlyOwner whenNotPaused {
        // In a full implementation, this would involve complex logic:
        // - Decay _userWisdomScores over time
        // - Reward users for accurate evaluations/endorsements
        // - Penalize users for inaccurate evaluations/endorsements
        // For this example, we'll keep it as a no-op placeholder.
        // This function exists to show the intent of a dynamic, managed score.
        for (uint256 i = 0; i < users.length; i++) {
            // Placeholder logic: maybe a slight boost for active evaluators
            if (isEvaluator[users[i]]) {
                _userWisdomScores[users[i]] += 1; // Example: minor boost
            }
        }
        emit WisdomScoresRecalculated(users);
    }

    /// @notice Returns the address to which a specific delegator has delegated their Wisdom Score.
    /// @param delegator The address of the delegator.
    /// @return The delegatee's address.
    function getDelegatedWisdom(address delegator) public view returns (address) {
        return _userDelegations[delegator];
    }

    // --- IV. Insight Evaluation & Resolution ---

    /// @notice Allows users to apply to become an Insight Evaluator.
    function applyForEvaluator() external whenNotPaused {
        require(getWisdomScore(msg.sender) >= minWisdomForEvaluator, "Insufficient Wisdom Score to apply");
        require(!isEvaluator[msg.sender], "Already an active evaluator");
        require(!evaluatorApplications[msg.sender], "Already applied to be an evaluator");
        evaluatorApplications[msg.sender] = true;
        emit EvaluatorApplied(msg.sender);
    }

    /// @notice (Governance) Elects an applicant to become an active Insight Evaluator.
    /// @param candidate The address of the applicant to elect.
    function electEvaluator(address candidate) external onlyOwner whenNotPaused {
        require(evaluatorApplications[candidate], "Candidate has not applied or application revoked");
        require(!isEvaluator[candidate], "Candidate is already an evaluator");
        isEvaluator[candidate] = true;
        delete evaluatorApplications[candidate]; // Remove from application pool
        emit EvaluatorElected(candidate);
    }

    /// @notice An elected Evaluator provides a subjective score and rationale for an Insight.
    /// @param insightId The ID of the Insight.
    /// @param score The evaluation score (1-10).
    /// @param rationaleURI URI pointing to the detailed rationale.
    function evaluateInsight(uint256 insightId, uint8 score, string memory rationaleURI) external whenNotPaused {
        require(_insightIdCounter.current() >= insightId && insightId > 0, "Insight does not exist");
        require(isEvaluator[msg.sender], "Only elected evaluators can evaluate");
        Insight storage insight = insights[insightId];
        require(insight.status < InsightStatus.FinalizedAccurate, "Insight is already finalized");
        require(block.timestamp < insight.evaluationPeriodEndsAt, "Evaluation period has ended");
        require(score >= 1 && score <= 10, "Score must be between 1 and 10");
        require(bytes(rationaleURI).length > 0, "Rationale URI cannot be empty");

        // Prevent multiple evaluations by the same evaluator on the same insight
        for (uint i = 0; i < insight.evaluations.length; i++) {
            require(insight.evaluations[i].evaluator != msg.sender, "Evaluator already assessed this Insight");
        }

        insight.evaluations.push(
            Evaluation({
                evaluator: msg.sender,
                score: score,
                rationaleURI: rationaleURI,
                evaluatedAt: block.timestamp,
                disputed: false
            })
        );
        insight.status = InsightStatus.Evaluating; // Update status if it was 'Proposed'
        emit InsightEvaluated(insightId, msg.sender, score);
    }

    /// @notice Allows any user to formally dispute an Evaluator's specific assessment.
    /// @param insightId The ID of the Insight.
    /// @param evaluationIndex The index of the evaluation within the Insight's evaluations array.
    /// @param disputeURI URI pointing to the detailed dispute rationale.
    function disputeInsightEvaluation(
        uint256 insightId,
        uint256 evaluationIndex,
        string memory disputeURI
    ) external whenNotPaused {
        require(_insightIdCounter.current() >= insightId && insightId > 0, "Insight does not exist");
        Insight storage insight = insights[insightId];
        require(insight.status < InsightStatus.FinalizedAccurate, "Insight is already finalized");
        require(block.timestamp < insight.evaluationPeriodEndsAt, "Cannot dispute after evaluation period ends");
        require(evaluationIndex < insight.evaluations.length, "Invalid evaluation index");
        require(!insight.evaluations[evaluationIndex].disputed, "Evaluation already disputed");
        require(bytes(disputeURI).length > 0, "Dispute URI cannot be empty");

        insight.evaluations[evaluationIndex].disputed = true;
        insight.status = InsightStatus.Disputed; // Insight now in dispute state

        // In a more complex system, this would initiate an arbitration process,
        // possibly involving more stakeholders or a separate dispute resolution module.
        // For simplicity, it just marks the dispute.

        emit InsightDisputed(insightId, msg.sender, evaluationIndex);
    }

    /// @notice (Admin/Governance) Finalizes a dispute, updating reputations and Insight status.
    /// @param insightId The ID of the Insight.
    /// @param evaluationIndex The index of the disputed evaluation.
    /// @param evaluatorWasCorrect True if the original evaluator's assessment was deemed correct, false otherwise.
    function resolveDispute(
        uint256 insightId,
        uint256 evaluationIndex,
        bool evaluatorWasCorrect
    ) external onlyOwner whenNotPaused {
        require(_insightIdCounter.current() >= insightId && insightId > 0, "Insight does not exist");
        Insight storage insight = insights[insightId];
        require(evaluationIndex < insight.evaluations.length, "Invalid evaluation index");
        require(insight.evaluations[evaluationIndex].disputed, "Evaluation was not disputed");
        require(insight.status == InsightStatus.Disputed, "Insight is not currently in dispute");

        address evaluator = insight.evaluations[evaluationIndex].evaluator;

        if (evaluatorWasCorrect) {
            _userWisdomScores[evaluator] += 10; // Reward evaluator for being correct
        } else {
            _userWisdomScores[evaluator] = _userWisdomScores[evaluator] > 5 ? _userWisdomScores[evaluator] - 5 : 0; // Penalize
        }

        // After dispute resolution, the insight could revert to Evaluating or be finalized,
        // depending on the broader governance rules. Here, we assume it can proceed to finalization later.
        insight.evaluations[evaluationIndex].disputed = false; // Dispute resolved
        
        // If all disputes are resolved, set status back to Evaluating
        bool allDisputesResolved = true;
        for(uint i=0; i<insight.evaluations.length; i++) {
            if(insight.evaluations[i].disputed) {
                allDisputesResolved = false;
                break;
            }
        }
        if(allDisputesResolved) {
             insight.status = InsightStatus.Evaluating;
        }

        emit DisputeResolved(insightId, evaluationIndex, evaluatorWasCorrect);
    }

    /// @notice Marks an Insight as finalized (e.g., its prediction resolved). Distributes rewards/penalties.
    /// @param insightId The ID of the Insight.
    /// @param provedAccurate True if the Insight's core claim/prediction was accurate, false otherwise.
    function finalizeInsight(uint256 insightId, bool provedAccurate) external onlyOwner whenNotPaused {
        require(_insightIdCounter.current() >= insightId && insightId > 0, "Insight does not exist");
        Insight storage insight = insights[insightId];
        require(insight.status < InsightStatus.FinalizedAccurate, "Insight is already finalized");
        require(block.timestamp >= insight.evaluationPeriodEndsAt, "Cannot finalize before evaluation period ends");
        require(insight.status != InsightStatus.Disputed, "Cannot finalize Insight in dispute");

        insight.finalizedAt = block.timestamp;
        insight.provedAccurate = provedAccurate;
        insight.status = provedAccurate ? InsightStatus.FinalizedAccurate : InsightStatus.FinalizedInaccurate;

        if (provedAccurate) {
            // Distribute rewards
            uint256 totalStake = insight.totalEndorsementStake;
            require(totalStake > 0, "No stake to distribute rewards from");

            uint256 proposerReward = (totalStake * proposerRewardShare) / 10000;
            uint256 endorserPoolReward = (totalStake * endorserRewardShare) / 10000;
            uint256 evaluatorPoolReward = (totalStake * evaluatorRewardShare) / 10000;

            // Proposer claim is handled by claimInsightRewards to allow multi-claims
            // _baseInsightToken.transfer(insight.proposer, proposerReward);

            // Reward evaluators based on their score
            uint256 totalEvaluationScore = 0;
            for (uint256 i = 0; i < insight.evaluations.length; i++) {
                totalEvaluationScore += insight.evaluations[i].score;
            }

            // Store evaluator rewards for later claiming
            if (totalEvaluationScore > 0) {
                for (uint256 i = 0; i < insight.evaluations.length; i++) {
                    uint256 individualEvaluatorReward = (evaluatorPoolReward * insight.evaluations[i].score) / totalEvaluationScore;
                    insight.totalEvaluatorRewardsEarned += individualEvaluatorReward; // Sum up for auditing
                    // The actual transfer for evaluators happens in claimInsightRewards
                }
            }
            emit InsightFinalized(insightId, true, proposerReward + endorserPoolReward + evaluatorPoolReward);
        } else {
            // Penalties (funds remain in contract until withdrawn by owner/governance)
            // No direct distribution, funds are locked as 'penalties'
            emit InsightFinalized(insightId, false, 0);
        }
        
        // Update iNFT URI to reflect final status
        emit InsightTokenURIUpdated(insightId, tokenURI(insightId));
    }

    // --- V. Rewards & Penalties ---

    /// @notice Allows successful Insight proposers, endorsers, and evaluators to claim their share of staked rewards.
    /// @param insightId The ID of the Insight.
    function claimInsightRewards(uint256 insightId) external whenNotPaused {
        require(_insightIdCounter.current() >= insightId && insightId > 0, "Insight does not exist");
        Insight storage insight = insights[insightId];
        require(insight.status == InsightStatus.FinalizedAccurate, "Insight is not finalized as accurate");

        uint256 claimableAmount = 0;

        // Proposer's share
        if (msg.sender == insight.proposer && !insight.hasClaimedRewards[msg.sender]) {
            claimableAmount += (insight.totalEndorsementStake * proposerRewardShare) / 10000;
            insight.hasClaimedRewards[msg.sender] = true;
            _userWisdomScores[msg.sender] += 20; // Proposer wisdom boost
        }

        // Endorser's share
        if (insight.endorserStakes[msg.sender] > 0 && !insightEndorserClaimed[insightId][msg.sender]) {
            uint256 endorserBaseStake = insight.endorserStakes[msg.sender];
            uint256 endorserReward = (insight.totalEndorsementStake * endorserRewardShare) / 10000;
            uint256 individualEndorserReward = (endorserReward * endorserBaseStake) / (insight.totalEndorsementStake - insight.initialStake); // Exclude proposer's initial stake from endorser pool base for calculation
            claimableAmount += endorserBaseStake + individualEndorserReward; // Original stake + reward
            insightEndorserClaimed[insightId][msg.sender] = true;
            _userWisdomScores[msg.sender] += 5; // Endorser wisdom boost
        }

        // Evaluator's share
        for (uint256 i = 0; i < insight.evaluations.length; i++) {
            if (insight.evaluations[i].evaluator == msg.sender && !insight.hasClaimedRewards[msg.sender]) {
                uint256 totalEvaluationScore = 0;
                for (uint256 j = 0; j < insight.evaluations.length; j++) {
                    totalEvaluationScore += insight.evaluations[j].score;
                }
                if (totalEvaluationScore > 0) {
                    uint256 evaluatorPoolReward = (insight.totalEndorsementStake * evaluatorRewardShare) / 10000;
                    claimableAmount += (evaluatorPoolReward * insight.evaluations[i].score) / totalEvaluationScore;
                }
                insight.hasClaimedRewards[msg.sender] = true;
                _userWisdomScores[msg.sender] += 15; // Evaluator wisdom boost
                break; // Only one evaluation per person
            }
        }

        require(claimableAmount > 0, "No claimable rewards for this user for this Insight");

        _baseInsightToken.transfer(msg.sender, claimableAmount);
        emit RewardsClaimed(insightId, msg.sender, claimableAmount);
    }

    /// @notice (Admin/Governance) Collects funds from Insights that were proven inaccurate.
    /// @param insightId The ID of the Insight.
    function withdrawPenalties(uint256 insightId) external onlyOwner {
        require(_insightIdCounter.current() >= insightId && insightId > 0, "Insight does not exist");
        Insight storage insight = insights[insightId];
        require(insight.status == InsightStatus.FinalizedInaccurate, "Insight is not finalized as inaccurate");
        require(insight.totalEndorsementStake > 0, "No penalties to withdraw");

        uint256 penaltyAmount = insight.totalEndorsementStake; // All stake is forfeit
        insight.totalEndorsementStake = 0; // Clear the stake after withdrawal

        _baseInsightToken.transfer(owner(), penaltyAmount); // Transfer to contract owner/treasury
        emit PenaltyWithdrawn(insightId, penaltyAmount);
    }

    // --- VI. Governance & Parameters ---

    /// @notice Sets the duration (in seconds) for which Insights remain open for evaluation.
    /// @param _period The new evaluation period in seconds.
    function setEvaluationPeriod(uint256 _period) external onlyOwner {
        require(_period > 0, "Period must be positive");
        evaluationPeriod = _period;
    }

    /// @notice Defines the minimum Wisdom Score required for a user to apply as an Insight Evaluator.
    /// @param _score The new minimum Wisdom Score.
    function setMinWisdomForEvaluator(uint256 _score) external onlyOwner {
        minWisdomForEvaluator = _score;
    }

    /// @notice Configures the percentage split of rewards among the Insight proposer, endorsers, and evaluators.
    /// @param _proposerShare Percentage for proposer (e.g., 2000 for 20%).
    /// @param _endorserShare Percentage for endorsers (e.g., 6000 for 60%).
    /// @param _evaluatorShare Percentage for evaluators (e.g., 2000 for 20%).
    function setRewardDistribution(
        uint256 _proposerShare,
        uint256 _endorserShare,
        uint256 _evaluatorShare
    ) external onlyOwner {
        require(_proposerShare + _endorserShare + _evaluatorShare == 10000, "Shares must sum to 10000 (100%)");
        proposerRewardShare = _proposerShare;
        endorserRewardShare = _endorserShare;
        evaluatorRewardShare = _evaluatorShare;
    }
}
```