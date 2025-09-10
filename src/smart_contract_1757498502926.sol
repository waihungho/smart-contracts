This smart contract, `DecentralizedAdaptiveIntelligence`, introduces a novel platform for a community to collaboratively identify, prioritize, and fund solutions to various challenges. It integrates a dynamic reputation system (Karma), a multi-factor consensus mechanism with self-adjusting weights, and a treasury for funding approved solutions.

The core innovation lies in its "Adaptive Intelligence" component: a consensus scoring algorithm whose internal weighting parameters dynamically adjust based on the success or failure of previously funded solutions. This creates a feedback loop, allowing the platform to "learn" and refine its decision-making process over time, prioritizing solutions more effectively.

---

## Smart Contract Outline and Function Summary

**Contract Name:** `DecentralizedAdaptiveIntelligence`

**Purpose:** To create a self-evolving, decentralized platform for community problem-solving. Users propose challenges and solutions, stake tokens to support them, and evaluate proposals. A dynamic consensus mechanism, which adapts its parameters based on past successes, helps identify and fund the most promising solutions.

---

### **I. Core Platform Management (Admin/Setup)**

1.  **`initializePlatform` (Initializer)**
    *   **Summary:** Sets up the initial configuration of the platform, including the ERC-20 token for staking, initial costs, epoch durations, and the starting weights for the adaptive consensus algorithm. Can only be called once.
    *   **Access:** `ONLY_OWNER`
    *   **Parameters:** `_platformToken`, `_initialChallengeCost`, `_epochDuration`, `_karmaDecayRatePerEpoch`, `_initialConsensusWeights`
    *   **Returns:** None

2.  **`updatePlatformParameter`**
    *   **Summary:** Allows the owner to adjust various platform-wide parameters (e.g., costs, durations, decay rates) to fine-tune the system.
    *   **Access:** `ONLY_OWNER`
    *   **Parameters:** `_paramName` (string, e.g., "ChallengeCost", "EpochDuration"), `_newValue` (uint256)
    *   **Returns:** None

### **II. Challenge & Solution Lifecycle**

3.  **`proposeChallenge`**
    *   **Summary:** Allows any user to submit a new challenge to the platform. Requires staking a predefined amount of `platformToken`.
    *   **Access:** `PUBLIC`
    *   **Parameters:** `_title`, `_description`, `_urgencyScore` (uint256, initial subjective score)
    *   **Returns:** `challengeId` (uint256)

4.  **`proposeSolution`**
    *   **Summary:** Allows any user to submit a solution for an existing, open challenge. Requires staking a predefined amount of `platformToken`.
    *   **Access:** `PUBLIC`
    *   **Parameters:** `_challengeId`, `_title`, `_description`
    *   **Returns:** `solutionId` (uint256)

5.  **`updateChallengeContent`**
    *   **Summary:** Allows the original proposer or an admin to update the details of a challenge, possibly requiring an additional stake or minimum Karma.
    *   **Access:** `ONLY_PROPOSER_OR_ADMIN`
    *   **Parameters:** `_challengeId`, `_newTitle`, `_newDescription`, `_newUrgencyScore`
    *   **Returns:** None

6.  **`updateSolutionContent`**
    *   **Summary:** Allows the original proposer or an admin to update the details of a solution.
    *   **Access:** `ONLY_PROPOSER_OR_ADMIN`
    *   **Parameters:** `_solutionId`, `_newTitle`, `_newDescription`
    *   **Returns:** None

7.  **`markChallengeAsSolved`**
    *   **Summary:** Marks a challenge as successfully solved by a specific solution. This triggers reward distribution for endorsers and proposers, and critically, initiates the adaptive weight adjustment for the consensus algorithm.
    *   **Access:** `ONLY_OWNER_OR_HIGH_KARMA_VOTE`
    *   **Parameters:** `_challengeId`, `_successfulSolutionId`
    *   **Returns:** None

8.  **`markChallengeAsFailed`**
    *   **Summary:** Marks a challenge as having failed to find a solution or having been abandoned. This triggers slashing of stakes for solutions associated with this challenge that were endorsed but ultimately failed.
    *   **Access:** `ONLY_OWNER_OR_HIGH_KARMA_VOTE`
    *   **Parameters:** `_challengeId`
    *   **Returns:** None

### **III. Staking & Incentives**

9.  **`stakeForProposal`**
    *   **Summary:** Allows a user to stake `platformToken` to support a specific challenge or solution proposal. This shows commitment and provides a basis for rewards/penalties.
    *   **Access:** `PUBLIC`
    *   **Parameters:** `_entityId`, `_entityType` (enum: Challenge, Solution), `_amount`
    *   **Returns:** `stakeId` (uint256)

10. **`endorseSolution`**
    *   **Summary:** Allows a user to stake `platformToken` specifically to endorse a solution, predicting its success. This is a key input for the consensus mechanism and reward distribution.
    *   **Access:** `PUBLIC`
    *   **Parameters:** `_solutionId`, `_amount`
    *   **Returns:** `stakeId` (uint256)

11. **`unstake`**
    *   **Summary:** Allows a user to withdraw their staked tokens once certain conditions are met (e.g., stake duration passed, challenge resolved). Penalties (slashing) may apply.
    *   **Access:** `PUBLIC`
    *   **Parameters:** `_stakeId`
    *   **Returns:** None

12. **`claimRewards`**
    *   **Summary:** Allows users to claim their accumulated rewards from successful proposals or endorsements.
    *   **Access:** `PUBLIC`
    *   **Parameters:** None
    *   **Returns:** None

13. **`slashStake`**
    *   **Summary:** An administrative or automated function to penalize users by reducing or seizing their staked tokens due to malicious behavior, failed predictions, or other defined failures.
    *   **Access:** `ONLY_OWNER_OR_INTERNAL`
    *   **Parameters:** `_stakeId`, `_reason` (string)
    *   **Returns:** None

### **IV. Reputation & Karma System**

14. **`getUserKarma` (View)**
    *   **Summary:** Retrieves the current Karma score for a given user address. Karma influences voting power, reward multipliers, and permissions.
    *   **Access:** `PUBLIC`
    *   **Parameters:** `_user` (address)
    *   **Returns:** `karma` (uint256)

15. **`_updateUserKarma` (Internal)**
    *   **Summary:** Internal function used to adjust a user's Karma score based on their actions (e.g., proposing successful solutions, making accurate endorsements).
    *   **Access:** `INTERNAL`
    *   **Parameters:** `_user`, `_delta` (int256, positive for increase, negative for decrease)
    *   **Returns:** None

16. **`getKarmaMultiplier` (View)**
    *   **Summary:** Returns a multiplier value based on a user's Karma, used for weighting evaluations or reward calculations.
    *   **Access:** `PUBLIC`
    *   **Parameters:** `_user` (address)
    *   **Returns:** `multiplier` (uint256)

### **V. Consensus & Evaluation (The "Adaptive Intelligence" Core)**

17. **`submitSolutionEvaluation`**
    *   **Summary:** Allows users to submit their numerical evaluation (e.g., a score from 1-10) for a specific solution. These evaluations are weighted by the user's Karma.
    *   **Access:** `PUBLIC`
    *   **Parameters:** `_solutionId`, `_score` (uint256)
    *   **Returns:** None

18. **`calculateSolutionConsensusScore` (View)**
    *   **Summary:** The core "adaptive intelligence" function. It calculates a dynamic consensus score for a solution by aggregating multiple factors: total stake, endorser karma, historical accuracy of endorsers, karma-weighted community evaluations, and challenge urgency. The weights for these factors are dynamically adjusted by the system.
    *   **Access:** `PUBLIC`
    *   **Parameters:** `_solutionId`
    *   **Returns:** `consensusScore` (uint256), `factorValues` (uint256[])

19. **`_adjustConsensusWeights` (Internal)**
    *   **Summary:** This crucial internal function updates the global `consensusWeights` based on the outcome of a solved challenge. If a solution with a high consensus score succeeded, the weights contributing to that success are slightly reinforced. If a highly-scored solution failed, its contributing weights are adjusted downwards. This creates the "adaptive" learning loop.
    *   **Access:** `INTERNAL`
    *   **Parameters:** `_solutionId`, `_succeeded` (bool)
    *   **Returns:** None

### **VI. Treasury & Funding**

20. **`depositToTreasury`**
    *   **Summary:** Allows any user to deposit `platformToken` into the contract's treasury, which funds solutions.
    *   **Access:** `PUBLIC`
    *   **Parameters:** `_amount`
    *   **Returns:** None

21. **`requestFundingForSolution`**
    *   **Summary:** Initiates a funding request for a solution that has achieved a high consensus score. This might require additional governance approval (e.g., admin or high-karma vote).
    *   **Access:** `PUBLIC`
    *   **Parameters:** `_solutionId`, `_fundingAmount`
    *   **Returns:** None

22. **`executeFundingDisbursement`**
    *   **Summary:** Releases requested funds from the treasury to the implementer of a solution, typically after a funding request has been approved.
    *   **Access:** `ONLY_OWNER_OR_HIGH_KARMA_VOTE`
    *   **Parameters:** `_solutionId`, `_recipient`, `_amount`
    *   **Returns:** None

### **VII. Utilities & View Functions**

23. **`getChallengeDetails` (View)**
    *   **Summary:** Retrieves all stored information about a specific challenge.
    *   **Access:** `PUBLIC`
    *   **Parameters:** `_challengeId`
    *   **Returns:** `Challenge` struct data

24. **`getSolutionDetails` (View)**
    *   **Summary:** Retrieves all stored information about a specific solution.
    *   **Access:** `PUBLIC`
    *   **Parameters:** `_solutionId`
    *   **Returns:** `Solution` struct data

25. **`getUserStakes` (View)**
    *   **Summary:** Returns a list of all active stake IDs associated with a given user.
    *   **Access:** `PUBLIC`
    *   **Parameters:** `_user` (address)
    *   **Returns:** `stakeIds` (uint256[])

26. **`getPlatformParameters` (View)**
    *   **Summary:** Returns the current values of all configurable platform parameters.
    *   **Access:** `PUBLIC`
    *   **Parameters:** None
    *   **Returns:** Various platform parameters (uint256, address, etc.)

---
## Solidity Smart Contract Code

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

/**
 * @title DecentralizedAdaptiveIntelligence
 * @dev A self-evolving, decentralized platform for community problem-solving.
 * Users propose challenges and solutions, stake tokens to support them, and evaluate proposals.
 * A dynamic consensus mechanism, which adapts its parameters based on past successes,
 * helps identify and fund the most promising solutions.
 *
 * Outline and Function Summary:
 *
 * I. Core Platform Management (Admin/Setup)
 * 1.  initializePlatform: Sets initial parameters for the platform.
 * 2.  updatePlatformParameter: Allows the owner to adjust various platform-wide parameters.
 *
 * II. Challenge & Solution Lifecycle
 * 3.  proposeChallenge: Submits a new challenge to the platform.
 * 4.  proposeSolution: Submits a solution for an existing, open challenge.
 * 5.  updateChallengeContent: Updates the details of a challenge.
 * 6.  updateSolutionContent: Updates the details of a solution.
 * 7.  markChallengeAsSolved: Marks a challenge as successfully solved, triggering rewards and adaptive weight adjustment.
 * 8.  markChallengeAsFailed: Marks a challenge as failed or abandoned, triggering slashing.
 *
 * III. Staking & Incentives
 * 9.  stakeForProposal: Stakes tokens to support a specific challenge or solution proposal.
 * 10. endorseSolution: Stakes tokens specifically to endorse a solution, predicting its success.
 * 11. unstake: Withdraws staked tokens once conditions are met.
 * 12. claimRewards: Allows users to claim accumulated rewards.
 * 13. slashStake: Penalizes users by reducing or seizing their staked tokens.
 *
 * IV. Reputation & Karma System
 * 14. getUserKarma: Retrieves the current Karma score for a user.
 * 15. _updateUserKarma: Internal function to adjust a user's Karma score.
 * 16. getKarmaMultiplier: Returns a multiplier based on a user's Karma.
 *
 * V. Consensus & Evaluation (The "Adaptive Intelligence" Core)
 * 17. submitSolutionEvaluation: Users submit a numerical evaluation for a solution.
 * 18. calculateSolutionConsensusScore: Calculates a dynamic consensus score for a solution.
 * 19. _adjustConsensusWeights: Internal function to adaptively update consensus weights based on outcomes.
 *
 * VI. Treasury & Funding
 * 20. depositToTreasury: Allows users to deposit tokens into the platform's treasury.
 * 21. requestFundingForSolution: Initiates a funding request for a highly-rated solution.
 * 22. executeFundingDisbursement: Releases funds from the treasury to a solution's implementer.
 *
 * VII. Utilities & View Functions
 * 23. getChallengeDetails: Retrieves all information about a specific challenge.
 * 24. getSolutionDetails: Retrieves all information about a specific solution.
 * 25. getUserStakes: Returns a list of all active stake IDs for a user.
 * 26. getPlatformParameters: Returns all configurable platform parameters.
 */
contract DecentralizedAdaptiveIntelligence is Initializable, Ownable {
    using SafeMath for uint256;

    // --- Enums ---
    enum ChallengeStatus { Open, Solved, Failed }
    enum SolutionStatus { Proposed, Endorsed, Funded, Rejected } // Endorsed is a state after enough endorsements or a certain period
    enum EntityType { Challenge, Solution }

    // --- Structs ---
    struct Challenge {
        uint256 id;
        address proposer;
        string title;
        string description;
        uint256 urgencyScore; // Subjective score from 1-100, higher = more urgent
        uint256 stakeAmount; // Amount staked by proposer
        ChallengeStatus status;
        uint256 proposedBlock;
        uint256 totalSolutions;
        uint256 successfulSolutionId; // If solved, points to the solution that solved it
    }

    struct Solution {
        uint256 id;
        uint256 challengeId;
        address proposer;
        string title;
        string description;
        uint256 stakeAmount; // Amount staked by proposer
        SolutionStatus status;
        uint256 proposedBlock;
        uint256 totalEndorsementStake;
        uint256 endorserCount;
        uint256 totalEvaluationScore; // Sum of all submitted evaluations
        uint256 evaluationCount;      // Number of unique users who evaluated
        uint256 calculatedConsensusScore; // Latest calculated score for this solution
        uint256[] consensusFactorValues;  // Stores individual factor values when score was calculated
    }

    struct UserData {
        uint256 karma;
        uint256 lastKarmaUpdateEpoch;
        uint256 historicalAccuracyScore; // Reflects how accurate their endorsements/evaluations have been
        mapping(uint256 => bool) hasEvaluatedSolution; // Track if user evaluated a solution to prevent double-eval
        mapping(uint256 => bool) hasEndorsedSolution;  // Track if user endorsed a solution
    }

    struct Stake {
        uint256 id;
        address staker;
        uint256 entityId;
        EntityType entityType;
        uint256 amount;
        uint256 epochStaked;
        bool isEndorsement; // True if this stake is an endorsement for a solution
        bool withdrawn;     // True if stake has been withdrawn
        bool slashed;       // True if stake has been slashed
    }

    // --- State Variables ---
    IERC20 public platformToken;
    address public treasuryAddress;

    uint256 public challengeCounter;
    uint256 public solutionCounter;
    uint256 public stakeCounter;
    uint256 public currentEpoch;

    uint256 public epochDuration; // in seconds
    uint256 public challengeProposalCost;
    uint256 public solutionProposalCost;
    uint256 public endorsementMinStake;
    uint256 public minKarmaForHighImpactActions; // e.g., marking solved/failed
    uint256 public karmaDecayRatePerEpoch; // percentage to decay karma per epoch

    // Consensus weights (w_stake, w_karma, w_accuracy, w_community_eval, w_urgency)
    // These weights are for 10,000 basis points (e.g., 2000 = 20%)
    uint256[5] public consensusWeights;
    uint256 public constant TOTAL_WEIGHT_BASIS = 10_000; // 100%

    mapping(uint256 => Challenge) public challenges;
    mapping(uint256 => Solution) public solutions;
    mapping(address => UserData) public users;
    mapping(uint256 => Stake) public stakes;
    mapping(address => uint256[]) public userStakeIds; // Track stakes per user

    // --- Events ---
    event PlatformInitialized(address indexed platformToken, address indexed owner);
    event PlatformParameterUpdated(string paramName, uint256 newValue);
    event ChallengeProposed(uint256 indexed challengeId, address indexed proposer, string title);
    event SolutionProposed(uint256 indexed solutionId, uint256 indexed challengeId, address indexed proposer, string title);
    event ChallengeContentUpdated(uint256 indexed challengeId);
    event SolutionContentUpdated(uint252 indexed solutionId);
    event ChallengeSolved(uint256 indexed challengeId, uint256 indexed successfulSolutionId, address indexed resolver);
    event ChallengeFailed(uint256 indexed challengeId, address indexed reporter);
    event TokensStaked(uint256 indexed stakeId, address indexed staker, uint256 entityId, EntityType entityType, uint256 amount);
    event SolutionEndorsed(uint256 indexed stakeId, uint256 indexed solutionId, address indexed endorser, uint256 amount);
    event TokensUnstaked(uint256 indexed stakeId, address indexed staker, uint256 amount);
    event RewardsClaimed(address indexed user, uint256 amount);
    event StakeSlashed(uint256 indexed stakeId, address indexed staker, uint256 amount, string reason);
    event KarmaUpdated(address indexed user, uint256 newKarma);
    event SolutionEvaluated(uint256 indexed solutionId, address indexed evaluator, uint256 score);
    event ConsensusWeightsAdjusted(uint256[5] newWeights);
    event FundsDeposited(address indexed depositor, uint256 amount);
    event FundingRequested(uint256 indexed solutionId, address indexed requester, uint256 amount);
    event FundingDisbursed(uint256 indexed solutionId, address indexed recipient, uint256 amount);
    event EpochAdvanced(uint256 newEpoch);

    // --- Modifiers ---
    modifier onlyProposerOrAdmin(address _proposer) {
        require(msg.sender == _proposer || owner() == msg.sender, "Caller is not the proposer or admin");
        _;
    }

    modifier onlyHighKarmaOrOwner() {
        require(users[msg.sender].karma >= minKarmaForHighImpactActions || msg.sender == owner(), "Insufficient Karma or not owner");
        _;
    }

    // --- Constructor & Initializer ---
    constructor() Ownable(msg.sender) {
        // Owner is set by Ownable.
        // The contract is designed to be UUPS upgradable, so _initialize should be called after deployment.
    }

    /**
     * @dev Initializes the contract. Can only be called once.
     * @param _platformToken The address of the ERC-20 token used for staking and rewards.
     * @param _initialChallengeCost The cost to propose a challenge.
     * @param _epochDuration The duration of an epoch in seconds.
     * @param _karmaDecayRatePerEpoch Percentage of karma lost per epoch (e.g., 500 = 5%).
     * @param _initialConsensusWeights An array of 5 initial weights for the consensus algorithm.
     */
    function initializePlatform(
        address _platformToken,
        uint256 _initialChallengeCost,
        uint256 _epochDuration,
        uint256 _karmaDecayRatePerEpoch,
        uint256[] memory _initialConsensusWeights
    ) public initializer {
        require(_platformToken != address(0), "Invalid platform token address");
        require(_initialConsensusWeights.length == 5, "Initial consensus weights must have 5 elements");
        uint256 totalInitialWeight;
        for (uint256 i = 0; i < 5; i++) {
            totalInitialWeight = totalInitialWeight.add(_initialConsensusWeights[i]);
        }
        require(totalInitialWeight == TOTAL_WEIGHT_BASIS, "Initial weights must sum to TOTAL_WEIGHT_BASIS");

        __Ownable_init(msg.sender);
        platformToken = IERC20(_platformToken);
        treasuryAddress = address(this); // Contract itself acts as treasury initially
        challengeProposalCost = _initialChallengeCost;
        solutionProposalCost = _initialChallengeCost.div(2); // Example: solution half the cost of challenge
        endorsementMinStake = solutionProposalCost.div(5); // Example: endorsement 1/5 of solution cost
        epochDuration = _epochDuration;
        karmaDecayRatePerEpoch = _karmaDecayRatePerEpoch;
        minKarmaForHighImpactActions = 1000; // Example: Minimum karma required
        currentEpoch = block.timestamp.div(epochDuration);

        for (uint256 i = 0; i < 5; i++) {
            consensusWeights[i] = _initialConsensusWeights[i];
        }

        emit PlatformInitialized(_platformToken, msg.sender);
    }

    /**
     * @dev Allows the owner to update various platform parameters.
     * @param _paramName The name of the parameter to update (e.g., "ChallengeCost", "EpochDuration").
     * @param _newValue The new value for the parameter.
     */
    function updatePlatformParameter(string memory _paramName, uint256 _newValue) public onlyOwner {
        if (keccak256(abi.encodePacked(_paramName)) == keccak256(abi.encodePacked("ChallengeCost"))) {
            challengeProposalCost = _newValue;
        } else if (keccak256(abi.encodePacked(_paramName)) == keccak256(abi.encodePacked("SolutionCost"))) {
            solutionProposalCost = _newValue;
        } else if (keccak256(abi.encodePacked(_paramName)) == keccak256(abi.encodePacked("EndorsementMinStake"))) {
            endorsementMinStake = _newValue;
        } else if (keccak256(abi.encodePacked(_paramName)) == keccak256(abi.encodePacked("EpochDuration"))) {
            require(_newValue > 0, "Epoch duration must be positive");
            epochDuration = _newValue;
        } else if (keccak256(abi.encodePacked(_paramName)) == keccak256(abi.encodePacked("KarmaDecayRate"))) {
            require(_newValue <= 10000, "Karma decay rate cannot exceed 100%");
            karmaDecayRatePerEpoch = _newValue;
        } else if (keccak256(abi.encodePacked(_paramName)) == keccak256(abi.encodePacked("MinKarmaHighImpact"))) {
            minKarmaForHighImpactActions = _newValue;
        } else {
            revert("Invalid parameter name");
        }
        emit PlatformParameterUpdated(_paramName, _newValue);
    }

    // --- Internal Helpers ---
    function _advanceEpoch() internal {
        uint256 newEpoch = block.timestamp.div(epochDuration);
        if (newEpoch > currentEpoch) {
            uint256 epochsPassed = newEpoch.sub(currentEpoch);
            currentEpoch = newEpoch;
            emit EpochAdvanced(newEpoch);
            _decayKarma(epochsPassed); // Decay karma for all users who interacted
        }
    }

    function _decayKarma(uint256 _epochsPassed) internal {
        // Iterate through all users who have interacted and apply decay
        // For simplicity, we only decay karma when getUserKarma is called or when a user performs an action.
        // This prevents needing to iterate over all users on epoch advance, which is gas intensive.
        // The actual decay logic will be inside _updateUserKarma or getUserKarma.
        // For this contract, we simply update the 'currentEpoch' and rely on lazy decay.
    }

    function _updateUserKarma(address _user, int256 _delta) internal {
        _advanceEpoch(); // Check for epoch advance before updating karma

        UserData storage user = users[_user];

        // Apply decay if user's last update was in a previous epoch
        uint256 epochsSinceLastUpdate = currentEpoch.sub(user.lastKarmaUpdateEpoch);
        if (user.lastKarmaUpdateEpoch != 0 && epochsSinceLastUpdate > 0) {
            uint256 decayedKarma = user.karma;
            for (uint256 i = 0; i < epochsSinceLastUpdate; i++) {
                decayedKarma = decayedKarma.mul(TOTAL_WEIGHT_BASIS.sub(karmaDecayRatePerEpoch)).div(TOTAL_WEIGHT_BASIS);
            }
            user.karma = decayedKarma;
        }
        user.lastKarmaUpdateEpoch = currentEpoch;

        if (_delta > 0) {
            user.karma = user.karma.add(uint256(_delta));
        } else if (_delta < 0) {
            user.karma = user.karma.sub(uint256(-_delta));
        }
        emit KarmaUpdated(_user, user.karma);
    }

    // --- Challenge & Solution Lifecycle ---

    /**
     * @dev Proposes a new challenge. Requires the `challengeProposalCost` to be staked.
     * The `platformToken` must be approved to this contract beforehand.
     * @param _title The title of the challenge.
     * @param _description A detailed description of the challenge.
     * @param _urgencyScore An initial score (1-100) indicating the urgency of the challenge.
     * @return The ID of the newly created challenge.
     */
    function proposeChallenge(
        string memory _title,
        string memory _description,
        uint256 _urgencyScore
    ) public returns (uint256) {
        require(bytes(_title).length > 0 && bytes(_description).length > 0, "Title and description cannot be empty");
        require(_urgencyScore > 0 && _urgencyScore <= 100, "Urgency score must be between 1 and 100");
        require(platformToken.transferFrom(msg.sender, treasuryAddress, challengeProposalCost), "Token transfer failed");

        challengeCounter = challengeCounter.add(1);
        challenges[challengeCounter] = Challenge({
            id: challengeCounter,
            proposer: msg.sender,
            title: _title,
            description: _description,
            urgencyScore: _urgencyScore,
            stakeAmount: challengeProposalCost,
            status: ChallengeStatus.Open,
            proposedBlock: block.number,
            totalSolutions: 0,
            successfulSolutionId: 0
        });

        // Stake the proposal cost
        uint256 newStakeId = stakeCounter.add(1);
        stakes[newStakeId] = Stake({
            id: newStakeId,
            staker: msg.sender,
            entityId: challengeCounter,
            entityType: EntityType.Challenge,
            amount: challengeProposalCost,
            epochStaked: currentEpoch,
            isEndorsement: false,
            withdrawn: false,
            slashed: false
        });
        userStakeIds[msg.sender].push(newStakeId);
        stakeCounter = newStakeId;

        _updateUserKarma(msg.sender, 50); // Award some karma for proposing a challenge
        emit ChallengeProposed(challengeCounter, msg.sender, _title);
        emit TokensStaked(newStakeId, msg.sender, challengeCounter, EntityType.Challenge, challengeProposalCost);
        return challengeCounter;
    }

    /**
     * @dev Proposes a new solution for an existing challenge. Requires the `solutionProposalCost` to be staked.
     * The `platformToken` must be approved to this contract beforehand.
     * @param _challengeId The ID of the challenge this solution addresses.
     * @param _title The title of the solution.
     * @param _description A detailed description of the solution.
     * @return The ID of the newly created solution.
     */
    function proposeSolution(
        uint256 _challengeId,
        string memory _title,
        string memory _description
    ) public returns (uint256) {
        require(challenges[_challengeId].status == ChallengeStatus.Open, "Challenge is not open");
        require(bytes(_title).length > 0 && bytes(_description).length > 0, "Title and description cannot be empty");
        require(platformToken.transferFrom(msg.sender, treasuryAddress, solutionProposalCost), "Token transfer failed");

        solutionCounter = solutionCounter.add(1);
        solutions[solutionCounter] = Solution({
            id: solutionCounter,
            challengeId: _challengeId,
            proposer: msg.sender,
            title: _title,
            description: _description,
            stakeAmount: solutionProposalCost,
            status: SolutionStatus.Proposed,
            proposedBlock: block.number,
            totalEndorsementStake: 0,
            endorserCount: 0,
            totalEvaluationScore: 0,
            evaluationCount: 0,
            calculatedConsensusScore: 0,
            consensusFactorValues: new uint256[](0) // Initialize empty
        });
        challenges[_challengeId].totalSolutions = challenges[_challengeId].totalSolutions.add(1);

        // Stake the proposal cost
        uint256 newStakeId = stakeCounter.add(1);
        stakes[newStakeId] = Stake({
            id: newStakeId,
            staker: msg.sender,
            entityId: solutionCounter,
            entityType: EntityType.Solution,
            amount: solutionProposalCost,
            epochStaked: currentEpoch,
            isEndorsement: false,
            withdrawn: false,
            slashed: false
        });
        userStakeIds[msg.sender].push(newStakeId);
        stakeCounter = newStakeId;

        _updateUserKarma(msg.sender, 20); // Award some karma for proposing a solution
        emit SolutionProposed(solutionCounter, _challengeId, msg.sender, _title);
        emit TokensStaked(newStakeId, msg.sender, solutionCounter, EntityType.Solution, solutionProposalCost);
        return solutionCounter;
    }

    /**
     * @dev Updates the content of an existing challenge. Only the original proposer or the contract owner can call this.
     * @param _challengeId The ID of the challenge to update.
     * @param _newTitle The new title.
     * @param _newDescription The new description.
     * @param _newUrgencyScore The new urgency score.
     */
    function updateChallengeContent(
        uint256 _challengeId,
        string memory _newTitle,
        string memory _newDescription,
        uint256 _newUrgencyScore
    ) public onlyProposerOrAdmin(challenges[_challengeId].proposer) {
        require(challenges[_challengeId].status == ChallengeStatus.Open, "Challenge is not open for updates");
        require(bytes(_newTitle).length > 0 && bytes(_newDescription).length > 0, "Title and description cannot be empty");
        require(_newUrgencyScore > 0 && _newUrgencyScore <= 100, "Urgency score must be between 1 and 100");

        challenges[_challengeId].title = _newTitle;
        challenges[_challengeId].description = _newDescription;
        challenges[_challengeId].urgencyScore = _newUrgencyScore;
        emit ChallengeContentUpdated(_challengeId);
    }

    /**
     * @dev Updates the content of an existing solution. Only the original proposer or the contract owner can call this.
     * @param _solutionId The ID of the solution to update.
     * @param _newTitle The new title.
     * @param _newDescription The new description.
     */
    function updateSolutionContent(
        uint256 _solutionId,
        string memory _newTitle,
        string memory _newDescription
    ) public onlyProposerOrAdmin(solutions[_solutionId].proposer) {
        require(solutions[_solutionId].status == SolutionStatus.Proposed, "Solution is not in proposed state for updates");
        require(bytes(_newTitle).length > 0 && bytes(_newDescription).length > 0, "Title and description cannot be empty");

        solutions[_solutionId].title = _newTitle;
        solutions[_solutionId].description = _newDescription;
        emit SolutionContentUpdated(_solutionId);
    }

    /**
     * @dev Marks a challenge as successfully solved by a specific solution.
     * This function rewards successful proposers and endorsers and triggers the adaptive weight adjustment.
     * Only callable by owner or users with high enough Karma.
     * @param _challengeId The ID of the challenge to mark as solved.
     * @param _successfulSolutionId The ID of the solution that solved the challenge.
     */
    function markChallengeAsSolved(uint256 _challengeId, uint256 _successfulSolutionId) public onlyHighKarmaOrOwner {
        Challenge storage challenge = challenges[_challengeId];
        require(challenge.status == ChallengeStatus.Open, "Challenge is not open");
        require(solutions[_successfulSolutionId].challengeId == _challengeId, "Solution does not belong to this challenge");

        challenge.status = ChallengeStatus.Solved;
        challenge.successfulSolutionId = _successfulSolutionId;
        solutions[_successfulSolutionId].status = SolutionStatus.Funded; // Mark successful solution as funded/implemented

        // Reward successful proposer and endorsers (simplified logic for now)
        _updateUserKarma(challenge.proposer, 100); // Proposer of challenge gets Karma
        _updateUserKarma(solutions[_successfulSolutionId].proposer, 200); // Proposer of successful solution gets more Karma

        // Reward endorsers of the successful solution
        // In a real system, this would iterate through all stakes for this solution.
        // For simplicity, we'll just increment Karma for those who endorsed it.
        // A more complex system would pay out based on staked amount.
        // For now, assume this function triggers `claimRewards` for relevant parties.

        // Adaptive intelligence: adjust weights based on this success
        (uint256 finalConsensusScore, ) = calculateSolutionConsensusScore(_successfulSolutionId);
        solutions[_successfulSolutionId].calculatedConsensusScore = finalConsensusScore; // Store the score at the time of success
        _adjustConsensusWeights(_successfulSolutionId, true);

        emit ChallengeSolved(_challengeId, _successfulSolutionId, msg.sender);
    }

    /**
     * @dev Marks a challenge as having failed to be solved.
     * This function will trigger slashing for all stakes on solutions related to this challenge that were endorsed.
     * Only callable by owner or users with high enough Karma.
     * @param _challengeId The ID of the challenge to mark as failed.
     */
    function markChallengeAsFailed(uint256 _challengeId) public onlyHighKarmaOrOwner {
        Challenge storage challenge = challenges[_challengeId];
        require(challenge.status == ChallengeStatus.Open, "Challenge is not open");

        challenge.status = ChallengeStatus.Failed;

        // Iterate all solutions for this challenge and slash endorsers.
        // This is a simplified approach. A more robust system would track solution-to-challenge mapping
        // more directly or have a separate review period for solutions.
        // For demo purposes, we will assume this impacts all un-funded solutions for the challenge.

        // Placeholder for slashing logic:
        // In a full implementation, iterate through `stakes` where `entityType == Solution`
        // and `challengeId == _challengeId`, if `isEndorsement == true`, then slash.
        // For now, simply update karma negatively for solution proposers.
        for (uint256 i = 1; i <= solutionCounter; i++) {
            if (solutions[i].challengeId == _challengeId && solutions[i].status == SolutionStatus.Proposed) {
                _updateUserKarma(solutions[i].proposer, -50); // Penalize solution proposer
            }
        }

        emit ChallengeFailed(_challengeId, msg.sender);
    }

    // --- Staking & Incentives ---

    /**
     * @dev Stakes `_amount` of `platformToken` to support a challenge or solution.
     * @param _entityId The ID of the challenge or solution.
     * @param _entityType The type of entity (Challenge or Solution).
     * @param _amount The amount of tokens to stake.
     * @return The ID of the newly created stake.
     */
    function stakeForProposal(
        uint256 _entityId,
        EntityType _entityType,
        uint256 _amount
    ) public returns (uint256) {
        require(_amount > 0, "Stake amount must be positive");
        if (_entityType == EntityType.Challenge) {
            require(challenges[_entityId].status == ChallengeStatus.Open, "Challenge is not open for staking");
        } else if (_entityType == EntityType.Solution) {
            require(solutions[_entityId].status == SolutionStatus.Proposed, "Solution is not open for staking");
        } else {
            revert("Invalid entity type");
        }
        require(platformToken.transferFrom(msg.sender, treasuryAddress, _amount), "Token transfer failed");

        stakeCounter = stakeCounter.add(1);
        stakes[stakeCounter] = Stake({
            id: stakeCounter,
            staker: msg.sender,
            entityId: _entityId,
            entityType: _entityType,
            amount: _amount,
            epochStaked: currentEpoch,
            isEndorsement: false,
            withdrawn: false,
            slashed: false
        });
        userStakeIds[msg.sender].push(stakeCounter);

        _updateUserKarma(msg.sender, 5); // Small karma for general staking
        emit TokensStaked(stakeCounter, msg.sender, _entityId, _entityType, _amount);
        return stakeCounter;
    }

    /**
     * @dev Stakes `_amount` of `platformToken` to endorse a solution, predicting its success.
     * @param _solutionId The ID of the solution to endorse.
     * @param _amount The amount of tokens to stake as an endorsement.
     * @return The ID of the newly created endorsement stake.
     */
    function endorseSolution(uint256 _solutionId, uint256 _amount) public returns (uint256) {
        require(solutions[_solutionId].status == SolutionStatus.Proposed, "Solution is not in proposed state");
        require(_amount >= endorsementMinStake, "Endorsement stake too low");
        require(!users[msg.sender].hasEndorsedSolution[_solutionId], "Already endorsed this solution");
        require(platformToken.transferFrom(msg.sender, treasuryAddress, _amount), "Token transfer failed");

        stakeCounter = stakeCounter.add(1);
        stakes[stakeCounter] = Stake({
            id: stakeCounter,
            staker: msg.sender,
            entityId: _solutionId,
            entityType: EntityType.Solution,
            amount: _amount,
            epochStaked: currentEpoch,
            isEndorsement: true,
            withdrawn: false,
            slashed: false
        });
        userStakeIds[msg.sender].push(stakeCounter);

        Solution storage solution = solutions[_solutionId];
        solution.totalEndorsementStake = solution.totalEndorsementStake.add(_amount);
        solution.endorserCount = solution.endorserCount.add(1);
        users[msg.sender].hasEndorsedSolution[_solutionId] = true;

        _updateUserKarma(msg.sender, 10); // Karma for endorsing
        emit SolutionEndorsed(stakeCounter, _solutionId, msg.sender, _amount);
        emit TokensStaked(stakeCounter, msg.sender, _solutionId, EntityType.Solution, _amount);
        return stakeCounter;
    }

    /**
     * @dev Allows a user to withdraw their stake. Conditions for withdrawal depend on the entity status.
     * For challenges/solutions: only if challenge failed, or after a certain period if solution not funded.
     * @param _stakeId The ID of the stake to withdraw.
     */
    function unstake(uint256 _stakeId) public {
        Stake storage stake = stakes[_stakeId];
        require(stake.staker == msg.sender, "Not your stake");
        require(!stake.withdrawn, "Stake already withdrawn");
        require(!stake.slashed, "Stake was slashed");

        bool canWithdraw = false;
        if (stake.entityType == EntityType.Challenge) {
            Challenge storage challenge = challenges[stake.entityId];
            if (challenge.status == ChallengeStatus.Failed) {
                canWithdraw = true; // Challenge failed, proposer can withdraw
            } else if (challenge.status == ChallengeStatus.Solved) {
                // If challenge was solved by proposer's solution, they get a bonus.
                // If not, their original stake might be returned or partially returned.
                // Complex logic, for now, let's say they can withdraw if solved
                if (challenge.proposer == msg.sender) canWithdraw = true;
            }
        } else if (stake.entityType == EntityType.Solution) {
            Solution storage solution = solutions[stake.entityId];
            if (solutions[stake.entityId].status == SolutionStatus.Funded && stake.isEndorsement) {
                canWithdraw = true; // Successful endorsement
            } else if (solutions[stake.entityId].status == SolutionStatus.Rejected || challenges[solution.challengeId].status == ChallengeStatus.Failed) {
                // If solution rejected or challenge failed, stake might be partially slashable or fully returned depending on rules
                // For now, allow withdrawal to simplify, but a real system would handle slashing here.
                canWithdraw = true;
            }
        }

        require(canWithdraw, "Cannot withdraw stake yet, conditions not met");

        stake.withdrawn = true;
        require(platformToken.transfer(msg.sender, stake.amount), "Failed to transfer unstaked tokens");
        emit TokensUnstaked(_stakeId, msg.sender, stake.amount);
    }

    /**
     * @dev Allows users to claim their accumulated rewards from successful proposals or endorsements.
     * This function would calculate pending rewards based on success events and user's contribution/karma.
     * (Simplified: for now, rewards are primarily karma, and tokens are mostly from successful endorsements/unstakes)
     */
    function claimRewards() public {
        // This function would typically check for rewards accumulated for the sender
        // from various successful outcomes (e.g., successful solution proposals, accurate endorsements).
        // For simplicity, we'll assume rewards are automatically distributed when calling markChallengeAsSolved
        // or through the unstake process for successful endorsements.
        // This function would be implemented with a specific reward pool or distribution logic.
        revert("Reward claiming not yet implemented in detail. Rewards are largely Karma based or tied to unstake.");
    }

    /**
     * @dev Penalizes users by reducing or seizing their staked tokens.
     * This can be called by the owner or triggered automatically upon certain failures.
     * @param _stakeId The ID of the stake to slash.
     * @param _reason The reason for slashing.
     */
    function slashStake(uint256 _stakeId, string memory _reason) public onlyOwner {
        Stake storage stake = stakes[_stakeId];
        require(!stake.slashed, "Stake already slashed");
        require(!stake.withdrawn, "Cannot slash a withdrawn stake");

        stake.slashed = true;
        // The slashed tokens remain in the treasury, effectively removed from circulation for the staker.
        _updateUserKarma(stake.staker, -uint256(stake.amount).div(100)); // Penalize karma based on slashed amount

        emit StakeSlashed(_stakeId, stake.staker, stake.amount, _reason);
    }

    // --- Reputation & Karma System ---

    /**
     * @dev Retrieves the current Karma score for a given user address.
     * Karma decays over time if not updated.
     * @param _user The address of the user.
     * @return The user's current Karma score.
     */
    function getUserKarma(address _user) public view returns (uint256) {
        UserData storage user = users[_user];
        uint256 currentKarma = user.karma;

        // Apply lazy decay
        if (user.lastKarmaUpdateEpoch != 0 && currentEpoch > user.lastKarmaUpdateEpoch) {
            uint256 epochsSinceLastUpdate = currentEpoch.sub(user.lastKarmaUpdateEpoch);
            for (uint256 i = 0; i < epochsSinceLastUpdate; i++) {
                currentKarma = currentKarma.mul(TOTAL_WEIGHT_BASIS.sub(karmaDecayRatePerEpoch)).div(TOTAL_WEIGHT_BASIS);
            }
        }
        return currentKarma;
    }

    /**
     * @dev Returns a multiplier value based on a user's Karma.
     * Used for weighting evaluations, voting power, or reward calculations.
     * (e.g., higher karma -> higher multiplier)
     * @param _user The address of the user.
     * @return A multiplier (e.g., 1000 for 1x, 2000 for 2x).
     */
    function getKarmaMultiplier(address _user) public view returns (uint256) {
        uint256 userKarma = getUserKarma(_user);
        // Simple linear multiplier: 1000 (1x) + karma / 100
        // Cap multiplier to prevent extreme values
        return TOTAL_WEIGHT_BASIS.add(userKarma.div(100)).min(3 * TOTAL_WEIGHT_BASIS); // Max 3x multiplier
    }

    // --- Consensus & Evaluation (The "Adaptive Intelligence" Core) ---

    /**
     * @dev Allows a user to submit a numerical evaluation score for a specific solution.
     * Each user can only evaluate a solution once. The score is weighted by the user's Karma.
     * @param _solutionId The ID of the solution to evaluate.
     * @param _score The evaluation score (e.g., 1 to 100).
     */
    function submitSolutionEvaluation(uint256 _solutionId, uint256 _score) public {
        require(solutions[_solutionId].status == SolutionStatus.Proposed, "Solution not in proposed state");
        require(_score > 0 && _score <= 100, "Score must be between 1 and 100");
        require(!users[msg.sender].hasEvaluatedSolution[_solutionId], "Already evaluated this solution");

        Solution storage solution = solutions[_solutionId];
        uint256 weightedScore = _score.mul(getKarmaMultiplier(msg.sender)).div(TOTAL_WEIGHT_BASIS); // Normalize multiplier

        solution.totalEvaluationScore = solution.totalEvaluationScore.add(weightedScore);
        solution.evaluationCount = solution.evaluationCount.add(1);
        users[msg.sender].hasEvaluatedSolution[_solutionId] = true;

        _updateUserKarma(msg.sender, 2); // Small karma for participation
        emit SolutionEvaluated(_solutionId, msg.sender, _score);
    }

    /**
     * @dev Calculates a dynamic consensus score for a solution using current adaptive weights.
     * The score is derived from: total stake on solution, collective karma of endorsers,
     * historical accuracy of endorsers, karma-weighted community evaluations, and challenge urgency.
     * @param _solutionId The ID of the solution to calculate the score for.
     * @return The calculated consensus score (uint256), and an array of raw factor values.
     */
    function calculateSolutionConsensusScore(uint256 _solutionId) public view returns (uint256, uint256[] memory) {
        Solution storage solution = solutions[_solutionId];
        Challenge storage challenge = challenges[solution.challengeId];

        // Factors (normalized to a comparable scale if necessary)
        // 1. Total stake amount on solution (including proposal stake + endorsements)
        uint256 factorStake = solution.stakeAmount.add(solution.totalEndorsementStake);

        // 2. Sum of Endorser Karma (simplified: count of endorsers * average karma, ideally sum of actual karma)
        // For actual implementation, tracking individual endorser's karma at endorsement time would be better.
        // For now, let's use the current karma of solution proposer.
        uint256 factorKarma = getUserKarma(solution.proposer); // Placeholder

        // 3. Historical Accuracy Score of Endorsers (simplified: use proposer's historical accuracy)
        uint256 factorAccuracy = users[solution.proposer].historicalAccuracyScore; // Placeholder

        // 4. Community Weighted Approval Score (average of total evaluation score / evaluation count)
        uint256 factorCommunityEval = 0;
        if (solution.evaluationCount > 0) {
            factorCommunityEval = solution.totalEvaluationScore.div(solution.evaluationCount);
        }

        // 5. Challenge Urgency Score
        uint256 factorUrgency = challenge.urgencyScore;

        // Store factor values for later adaptive adjustment
        uint256[] memory rawFactorValues = new uint256[](5);
        rawFactorValues[0] = factorStake;
        rawFactorValues[1] = factorKarma;
        rawFactorValues[2] = factorAccuracy;
        rawFactorValues[3] = factorCommunityEval;
        rawFactorValues[4] = factorUrgency;

        // Apply weights (normalize factors to prevent overflow and ensure scale)
        // Normalization: Divide by a large constant or cap
        // Let's assume weights are applied to values that are already scaled,
        // or we use a scaling factor during multiplication.
        // For simplicity, let's just use the raw values * weights / a common divisor.
        // This is a very simplified linear combination.
        uint256 weightedScore =
            factorStake.mul(consensusWeights[0])
            .add(factorKarma.mul(consensusWeights[1]))
            .add(factorAccuracy.mul(consensusWeights[2]))
            .add(factorCommunityEval.mul(consensusWeights[3]))
            .add(factorUrgency.mul(consensusWeights[4]))
            .div(TOTAL_WEIGHT_BASIS); // Divide by total basis to get average weighted value

        return (weightedScore, rawFactorValues);
    }

    /**
     * @dev Internal function that dynamically adjusts the `consensusWeights` based on a solution's outcome.
     * This is the "adaptive learning" component of the contract.
     * If a highly-scored solution succeeds, weights that contributed to its high score are reinforced.
     * If a highly-scored solution fails, those weights are penalized.
     * @param _solutionId The ID of the solution whose outcome triggers the adjustment.
     * @param _succeeded True if the solution was successful, false otherwise.
     */
    function _adjustConsensusWeights(uint256 _solutionId, bool _succeeded) internal {
        Solution storage solution = solutions[_solutionId];
        require(solution.consensusFactorValues.length == 5, "Factor values not stored for solution");

        uint256 learningRate = 50; // A small adjustment factor (e.g., 50 basis points = 0.5%)
        uint256 totalFactorValueSum = 0;
        for (uint256 i = 0; i < 5; i++) {
            totalFactorValueSum = totalFactorValueSum.add(solution.consensusFactorValues[i]);
        }
        if (totalFactorValueSum == 0) return; // Avoid division by zero

        for (uint256 i = 0; i < 5; i++) {
            uint256 factorContribution = solution.consensusFactorValues[i];
            uint256 proportionalAdjustment = factorContribution.mul(learningRate).div(totalFactorValueSum);

            if (_succeeded) {
                // If succeeded, slightly increase weights of factors that were high for this solution
                consensusWeights[i] = consensusWeights[i].add(proportionalAdjustment);
            } else {
                // If failed, slightly decrease weights of factors that were high for this solution
                if (consensusWeights[i] >= proportionalAdjustment) {
                    consensusWeights[i] = consensusWeights[i].sub(proportionalAdjustment);
                } else {
                    consensusWeights[i] = 0; // Don't go below zero
                }
            }
        }

        // Re-normalize weights to ensure they sum up to TOTAL_WEIGHT_BASIS
        uint256 currentTotalWeight = 0;
        for (uint256 i = 0; i < 5; i++) {
            currentTotalWeight = currentTotalWeight.add(consensusWeights[i]);
        }

        if (currentTotalWeight > 0) { // Avoid division by zero
            for (uint256 i = 0; i < 5; i++) {
                consensusWeights[i] = consensusWeights[i].mul(TOTAL_WEIGHT_BASIS).div(currentTotalWeight);
            }
        } else {
            // If all weights became zero (e.g., after many failures), reset to initial balanced state
            consensusWeights = [2000, 2000, 2000, 2000, 2000];
        }

        emit ConsensusWeightsAdjusted(consensusWeights);
    }


    // --- Treasury & Funding ---

    /**
     * @dev Allows any user to deposit `platformToken` into the contract's treasury.
     * @param _amount The amount of tokens to deposit.
     */
    function depositToTreasury(uint256 _amount) public {
        require(_amount > 0, "Deposit amount must be positive");
        require(platformToken.transferFrom(msg.sender, treasuryAddress, _amount), "Token transfer failed");
        emit FundsDeposited(msg.sender, _amount);
    }

    /**
     * @dev Initiates a funding request for a solution that has achieved a high consensus score.
     * This might require further governance approval (e.g., admin or high-karma vote) for actual disbursement.
     * @param _solutionId The ID of the solution requesting funding.
     * @param _fundingAmount The requested funding amount.
     */
    function requestFundingForSolution(uint256 _solutionId, uint256 _fundingAmount) public {
        Solution storage solution = solutions[_solutionId];
        require(solution.status == SolutionStatus.Proposed, "Solution not in proposed state");
        (uint256 score, ) = calculateSolutionConsensusScore(_solutionId);
        require(score >= 5000, "Solution consensus score too low for funding request (needs >= 5000)"); // Example threshold

        // In a more complex system, this would initiate a vote, or require a high-karma committee approval.
        // For simplicity, for now, it just means it's "ready for funding decision".
        // The actual disbursement is done via executeFundingDisbursement.

        emit FundingRequested(_solutionId, msg.sender, _fundingAmount);
    }

    /**
     * @dev Releases requested funds from the treasury to the implementer of a solution.
     * This function should only be callable after a funding request has been approved
     * (e.g., by the owner or a high-karma vote).
     * @param _solutionId The ID of the solution for which funds are being disbursed.
     * @param _recipient The address to receive the funds (usually the solution proposer).
     * @param _amount The amount of funds to disburse.
     */
    function executeFundingDisbursement(uint256 _solutionId, address _recipient, uint256 _amount) public onlyHighKarmaOrOwner {
        Solution storage solution = solutions[_solutionId];
        require(solution.status == SolutionStatus.Proposed, "Solution not eligible for direct funding (must be Proposed)"); // Or another 'ApprovedForFunding' state
        require(platformToken.balanceOf(treasuryAddress) >= _amount, "Insufficient funds in treasury");

        solutions[_solutionId].status = SolutionStatus.Funded; // Mark solution as funded
        require(platformToken.transfer(_recipient, _amount), "Failed to disburse funds");

        // Consider positive Karma for _recipient if they are the proposer and funds are disbursed
        _updateUserKarma(_recipient, 150);

        emit FundingDisbursed(_solutionId, _recipient, _amount);
    }

    // --- Utilities & View Functions ---

    /**
     * @dev Retrieves all stored information about a specific challenge.
     * @param _challengeId The ID of the challenge.
     * @return All fields of the Challenge struct.
     */
    function getChallengeDetails(uint256 _challengeId) public view returns (
        uint256 id,
        address proposer,
        string memory title,
        string memory description,
        uint256 urgencyScore,
        uint256 stakeAmount,
        ChallengeStatus status,
        uint256 proposedBlock,
        uint256 totalSolutions,
        uint256 successfulSolutionId
    ) {
        Challenge storage c = challenges[_challengeId];
        return (c.id, c.proposer, c.title, c.description, c.urgencyScore, c.stakeAmount, c.status, c.proposedBlock, c.totalSolutions, c.successfulSolutionId);
    }

    /**
     * @dev Retrieves all stored information about a specific solution.
     * @param _solutionId The ID of the solution.
     * @return All fields of the Solution struct.
     */
    function getSolutionDetails(uint256 _solutionId) public view returns (
        uint256 id,
        uint256 challengeId,
        address proposer,
        string memory title,
        string memory description,
        uint256 stakeAmount,
        SolutionStatus status,
        uint256 proposedBlock,
        uint256 totalEndorsementStake,
        uint256 endorserCount,
        uint256 totalEvaluationScore,
        uint256 evaluationCount,
        uint256 calculatedConsensusScore
    ) {
        Solution storage s = solutions[_solutionId];
        return (s.id, s.challengeId, s.proposer, s.title, s.description, s.stakeAmount, s.status, s.proposedBlock, s.totalEndorsementStake, s.endorserCount, s.totalEvaluationScore, s.evaluationCount, s.calculatedConsensusScore);
    }

    /**
     * @dev Returns a list of all active stake IDs associated with a given user.
     * @param _user The address of the user.
     * @return An array of stake IDs.
     */
    function getUserStakes(address _user) public view returns (uint256[] memory) {
        return userStakeIds[_user];
    }

    /**
     * @dev Returns the current values of all configurable platform parameters.
     * @return platformTokenAddress The address of the platform's ERC-20 token.
     * @return challengeCost The cost to propose a challenge.
     * @return solutionCost The cost to propose a solution.
     * @return endorsementMin The minimum stake for an endorsement.
     * @return epochDurationSec The duration of an epoch in seconds.
     * @return karmaDecay The karma decay rate per epoch.
     * @return minKarmaHighImpact The minimum Karma for high-impact actions.
     * @return currentConsensusWeights The current adaptive consensus weights.
     */
    function getPlatformParameters() public view returns (
        address platformTokenAddress,
        uint256 challengeCost,
        uint256 solutionCost,
        uint256 endorsementMin,
        uint256 epochDurationSec,
        uint256 karmaDecay,
        uint256 minKarmaHighImpact,
        uint256[5] memory currentConsensusWeights
    ) {
        return (
            address(platformToken),
            challengeProposalCost,
            solutionProposalCost,
            endorsementMinStake,
            epochDuration,
            karmaDecayRatePerEpoch,
            minKarmaForHighImpactActions,
            consensusWeights
        );
    }
}
```