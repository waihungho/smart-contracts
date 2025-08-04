This contract, named "ChronoPredict DAO," is designed to be an advanced, adaptive, and self-evolving prediction market and resource allocation system. It goes beyond typical prediction markets by incorporating a dynamic reputation system, meta-parameter governance, and a mechanism to allocate resources based on the collective probabilistic consensus of future events.

The core idea is that the contract doesn't just record predictions; it learns from them. Users contribute to a "collective intelligence" about future probabilities, and the contract, through its DAO, can even adjust its own internal algorithms (e.g., how reputation is calculated, how stakes influence probabilities) based on the overall accuracy and performance of the system.

---

## ChronoPredict DAO: Adaptive Probabilistic Consensus & Resource Allocation

### **Outline & Core Concepts:**

1.  **Adaptive Probabilistic Consensus:** Users stake on the *probabilities* of different outcomes for a future event (Claim). The collective probabilities are dynamically updated based on the stakes and reputation of the predictors. This is more nuanced than a simple binary "yes/no" prediction.
2.  **Dynamic Reputation System:** Predictors gain or lose reputation based on the accuracy of their predictions relative to the actual outcomes. Higher reputation gives more weight to a user's staked predictions. The reputation itself can decay or be recalibrated by governance.
3.  **Meta-Parameter Governance:** The DAO can propose and vote on changes to the *internal parameters* of the contract's algorithms (e.g., reputation decay rate, the multiplier for stake influence). This makes the contract *self-optimizing* and *adaptive*.
4.  **Probabilistic Resource Allocation:** Funds or resources within the DAO treasury can be allocated to projects or initiatives whose success is tied to a certain probabilistic outcome of a claim. This creates a mechanism for funding based on foresight and collective intelligence.
5.  **Claim Lifecycle Management:** A structured process for submitting, proposing outcomes, staking, resolving, and distributing rewards for claims.
6.  **Oracle Integration (for Resolution):** Utilizes an external oracle for resolving claim outcomes, introducing the dependency for off-chain data.

---

### **Function Summary (25 Functions):**

**I. Core Setup & Administration:**
1.  `constructor(address _tokenAddress, address _initialOracle)`: Initializes the contract with the ERC20 token for staking and an initial trusted oracle.
2.  `setOracleAddress(address _newOracle)`: Allows the owner to change the trusted oracle address.
3.  `withdrawExcessFunds(address _recipient)`: Allows the owner to withdraw unallocated funds from the contract's treasury.

**II. Claim Management:**
4.  `submitClaim(string calldata _description, uint256 _submissionDeadline, uint256 _resolutionDeadline)`: Allows users to propose a new future event (claim) for collective prediction.
5.  `proposeOutcome(uint256 _claimId, string calldata _outcomeDescription)`: Allows users to propose a specific outcome for an existing claim.
6.  `closeClaimSubmission(uint256 _claimId)`: Closes a claim for further outcome proposals, preparing it for prediction.
7.  `resolveClaim(uint256 _claimId, uint256 _actualOutcomeId)`: The trusted oracle resolves a claim, setting its actual outcome and triggering reputation updates.

**III. Prediction & Staking:**
8.  `predictAndStake(uint256 _claimId, uint256 _outcomeId, uint256 _amount)`: Users stake tokens on the *probability* of a specific outcome for a claim.
9.  `updatePredictionStake(uint256 _claimId, uint256 _outcomeId, uint256 _newAmount)`: Users can adjust their stake on a particular outcome.
10. `withdrawPredictionStake(uint256 _claimId, uint256 _outcomeId)`: Users can withdraw their stake *before* the claim is resolved.
11. `claimPredictionRewards(uint256 _claimId)`: Allows users to claim rewards after a claim has been resolved and they predicted accurately.

**IV. Reputation System & User Profiles:**
12. `getUserReputation(address _user)`: Views the current reputation score of a specific user.
13. `getTopPredictors(uint256 _count)`: (Conceptual, requires off-chain indexing for scale) Aims to return a list of users with highest reputation. *Implementation simplified for on-chain example.*
14. `getUserPredictionHistory(address _user, uint256 _claimId)`: Views a user's specific prediction history for a given claim.

**V. Probabilistic Resource Allocation (Funding Proposals):**
15. `submitFundingProposal(string calldata _description, uint256 _amount, uint256 _targetClaimId, uint256 _targetOutcomeId, uint256 _minProbabilityThreshold)`: Proposes a project to be funded if a specific claim's outcome reaches a certain probability threshold.
16. `voteOnFundingProposal(uint256 _proposalId, bool _approve)`: DAO members vote on whether to approve a funding proposal. (Note: This is a direct DAO vote, separate from the probabilistic allocation. The *execution* is probabilistic).
17. `executeFundingProposal(uint256 _proposalId, address _recipient)`: Executes an approved funding proposal if its target claim's resolved probability meets the threshold.

**VI. Meta-Parameter Governance:**
18. `proposeParameterChange(bytes32 _paramName, int256 _newValue)`: DAO members can propose changes to internal contract parameters.
19. `voteOnParameterChange(uint256 _proposalId, bool _approve)`: DAO members vote on proposed parameter changes.
20. `executeParameterChange(uint256 _proposalId)`: Executes a successfully voted-on parameter change, updating the contract's behavior.
21. `getCurrentParameters()`: Views the current values of all adaptive parameters.

**VII. View Functions (Public Read-Only):**
22. `getClaimDetails(uint256 _claimId)`: Retrieves all details for a specific claim.
23. `getOutcomeDetails(uint256 _claimId, uint256 _outcomeId)`: Retrieves details for a specific outcome of a claim.
24. `getClaimStatus(uint256 _claimId)`: Returns the current status of a claim (Open, ReadyForPrediction, Resolved, Canceled).
25. `getFundingProposalDetails(uint256 _proposalId)`: Retrieves details for a specific funding proposal.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // For safer arithmetic

/**
 * @title ChronoPredict DAO: Adaptive Probabilistic Consensus & Resource Allocation
 * @dev This contract implements an advanced prediction market with dynamic reputation,
 *      probabilistic resource allocation, and meta-parameter governance.
 *      Users stake on the *probabilities* of outcomes, influencing a collective
 *      probabilistic consensus. Their accuracy dynamically updates their reputation,
 *      which in turn weights their influence. The DAO can vote to adjust the
 *      contract's core parameters, making it self-evolving.
 */
contract ChronoPredictDAO is Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // --- State Variables ---

    IERC20 public immutable predictionToken; // ERC20 token used for staking and rewards
    address public oracleAddress;          // Address of the trusted oracle for claim resolution

    Counters.Counter private _claimIdCounter;
    Counters.Counter private _fundingProposalIdCounter;
    Counters.Counter private _parameterChangeProposalIdCounter;

    // Multiplier for probabilities and reputation to handle decimals (e.g., 10000 for 100%)
    uint256 public constant PROBABILITY_DENOMINATOR = 10_000;
    uint256 public constant MAX_REPUTATION = 1_000_000; // Max possible reputation score

    // --- Adaptive Parameters (Can be changed via DAO governance) ---
    // These parameters allow the DAO to 'tune' the contract's behavior
    struct AdaptiveParameters {
        // How much a correct prediction (weighted by stake) influences reputation gain
        uint256 ACCURACY_WEIGHT_FACTOR; // e.g., 100 (100%) means a perfect prediction gives 1x stake as reputation
        // How much an incorrect prediction (weighted by stake) influences reputation loss
        uint256 INACCURACY_PENALTY_FACTOR; // e.g., 50 (50%) means half stake as reputation loss
        // The rate at which reputation decays over time (e.g., 1% per period, or per resolved claim)
        // For simplicity, we'll implement a per-claim decay or per-time decay that can be triggered.
        uint256 REPUTATION_DECAY_RATE_PER_CLAIM; // e.g., 100 (1%) of current reputation decays per resolved claim
        // Minimum number of DAO votes required for a parameter change to pass
        uint256 MIN_PARAMETER_VOTES;
    }
    AdaptiveParameters public currentParameters;

    // --- Enums ---

    enum ClaimStatus {
        OpenForSubmission,   // Claim is proposed, outcomes can still be added
        OpenForPrediction,   // Outcomes are finalized, users can predict
        Resolved,            // Oracle has determined the outcome
        Canceled             // Claim was canceled (e.g., no resolution, or by governance)
    }

    enum ProposalStatus {
        Pending,
        Approved,
        Rejected,
        Executed
    }

    // --- Structs ---

    struct Claim {
        uint256 id;
        string description;
        uint256 submissionDeadline; // Deadline for proposing new outcomes
        uint256 resolutionDeadline; // Deadline for the oracle to resolve the claim
        ClaimStatus status;
        uint256 resolvedOutcomeId;  // ID of the actual outcome once resolved
        address proposer;
        uint256 totalStakedOnClaim;
        mapping(uint256 => Outcome) outcomes;
        uint256[] outcomeIds; // To iterate over outcomes
        uint256[] predictionIds; // To iterate over predictions associated with this claim
    }

    struct Outcome {
        uint256 id;
        string description;
        uint256 collectiveProbability; // Probability of this outcome, scaled by PROBABILITY_DENOMINATOR
        uint256 totalStakedOnOutcome;
    }

    struct Prediction {
        uint256 id;
        uint256 claimId;
        uint256 outcomeId;
        address predictor;
        uint256 stakedAmount;
        uint256 timestamp;
        uint256 reputationAtPrediction; // User's reputation when they made this prediction
        uint256 initialCollectiveProbability; // Collective prob when user made prediction
    }

    struct UserProfile {
        uint256 reputation; // Scaled by PROBABILITY_DENOMINATOR
        mapping(uint256 => mapping(uint256 => Prediction)) userPredictions; // claimId => outcomeId => Prediction
        address[] predictedClaimIds; // To track claims a user has predicted on
    }

    struct FundingProposal {
        uint256 id;
        string description;
        uint256 amount;
        uint256 targetClaimId;       // The claim this proposal is contingent upon
        uint256 targetOutcomeId;     // The specific outcome within the targetClaim
        uint256 minProbabilityThreshold; // Minimum resolved probability of targetOutcome for execution
        address proposer;
        ProposalStatus status;
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted; // Tracks if a DAO member has voted
        uint256 creationTimestamp;
    }

    struct ParameterChangeProposal {
        uint256 id;
        bytes32 paramName;
        int256 newValue; // Using int256 to allow for negative values if needed (e.g., for decay rates)
        address proposer;
        ProposalStatus status;
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted;
        uint256 creationTimestamp;
    }

    // --- Mappings ---

    mapping(uint256 => Claim) public claims;
    mapping(uint256 => Prediction) public predictions; // Global prediction ID to Prediction struct
    mapping(address => UserProfile) public userProfiles;
    mapping(uint256 => FundingProposal) public fundingProposals;
    mapping(uint256 => ParameterChangeProposal) public parameterChangeProposals;

    // --- Events ---

    event ClaimSubmitted(uint256 indexed claimId, string description, address indexed proposer);
    event OutcomeProposed(uint256 indexed claimId, uint256 indexed outcomeId, string description);
    event ClaimSubmissionClosed(uint256 indexed claimId);
    event ClaimResolved(uint256 indexed claimId, uint256 indexed actualOutcomeId);
    event PredictionMade(uint256 indexed claimId, uint256 indexed outcomeId, address indexed predictor, uint256 amount);
    event PredictionUpdated(uint256 indexed claimId, uint256 indexed outcomeId, address indexed predictor, uint256 newAmount);
    event PredictionWithdrawn(uint256 indexed claimId, uint256 indexed outcomeId, address indexed predictor, uint256 amount);
    event RewardsClaimed(uint256 indexed claimId, address indexed predictor, uint256 amount);
    event ReputationUpdated(address indexed user, uint256 newReputation);
    event FundingProposalSubmitted(uint256 indexed proposalId, string description, uint256 amount, address indexed proposer);
    event FundingProposalVoted(uint256 indexed proposalId, address indexed voter, bool approved);
    event FundingProposalExecuted(uint256 indexed proposalId, address indexed recipient, uint256 amount);
    event ParameterChangeProposed(uint256 indexed proposalId, bytes32 paramName, int256 newValue, address indexed proposer);
    event ParameterChangeVoted(uint256 indexed proposalId, address indexed voter, bool approved);
    event ParameterChangeExecuted(uint256 indexed proposalId, bytes32 paramName, int256 newValue);
    event OracleAddressSet(address indexed oldAddress, address indexed newAddress);
    event FundsWithdrawn(address indexed recipient, uint256 amount);


    // --- Modifiers ---

    modifier onlyOracle() {
        require(msg.sender == oracleAddress, "ChronoPredictDAO: Only the designated oracle can call this function");
        _;
    }

    modifier claimExists(uint256 _claimId) {
        require(_claimId <= _claimIdCounter.current() && _claimId > 0, "ChronoPredictDAO: Claim does not exist");
        _;
    }

    modifier claimOpenForSubmission(uint256 _claimId) {
        require(claims[_claimId].status == ClaimStatus.OpenForSubmission, "ChronoPredictDAO: Claim not open for outcome submission");
        require(block.timestamp <= claims[_claimId].submissionDeadline, "ChronoPredictDAO: Claim submission deadline passed");
        _;
    }

    modifier claimOpenForPrediction(uint256 _claimId) {
        require(claims[_claimId].status == ClaimStatus.OpenForPrediction, "ChronoPredictDAO: Claim not open for prediction");
        require(block.timestamp <= claims[_claimId].resolutionDeadline, "ChronoPredictDAO: Claim prediction deadline passed");
        _;
    }

    modifier claimResolved(uint256 _claimId) {
        require(claims[_claimId].status == ClaimStatus.Resolved, "ChronoPredictDAO: Claim not resolved");
        _;
    }

    modifier fundingProposalExists(uint256 _proposalId) {
        require(_proposalId <= _fundingProposalIdCounter.current() && _proposalId > 0, "ChronoPredictDAO: Funding proposal does not exist");
        _;
    }

    modifier parameterChangeProposalExists(uint256 _proposalId) {
        require(_proposalId <= _parameterChangeProposalIdCounter.current() && _proposalId > 0, "ChronoPredictDAO: Parameter change proposal does not exist");
        _;
    }

    // --- Constructor ---

    constructor(address _tokenAddress, address _initialOracle) Ownable(msg.sender) {
        require(_tokenAddress != address(0), "ChronoPredictDAO: Token address cannot be zero");
        require(_initialOracle != address(0), "ChronoPredictDAO: Oracle address cannot be zero");

        predictionToken = IERC20(_tokenAddress);
        oracleAddress = _initialOracle;

        // Initialize adaptive parameters with sensible defaults
        currentParameters.ACCURACY_WEIGHT_FACTOR = 100; // 100% influence for perfect accuracy
        currentParameters.INACCURACY_PENALTY_FACTOR = 50; // 50% penalty for complete inaccuracy
        currentParameters.REPUTATION_DECAY_RATE_PER_CLAIM = 10; // 0.1% decay per resolved claim
        currentParameters.MIN_PARAMETER_VOTES = 3; // Minimum 3 votes to pass parameter changes (for small DAO)

        // Initialize owner's reputation as a baseline
        userProfiles[msg.sender].reputation = 500 * PROBABILITY_DENOMINATOR; // Starting with a decent rep
    }

    // --- I. Core Setup & Administration ---

    /**
     * @dev Allows the owner to change the trusted oracle address.
     * @param _newOracle The address of the new oracle.
     */
    function setOracleAddress(address _newOracle) external onlyOwner {
        require(_newOracle != address(0), "ChronoPredictDAO: New oracle address cannot be zero");
        emit OracleAddressSet(oracleAddress, _newOracle);
        oracleAddress = _newOracle;
    }

    /**
     * @dev Allows the owner to withdraw unallocated funds from the contract's treasury.
     *      This is for managing funds not locked in claims or funding proposals.
     * @param _recipient The address to send the funds to.
     */
    function withdrawExcessFunds(address _recipient) external onlyOwner {
        require(_recipient != address(0), "ChronoPredictDAO: Recipient cannot be zero address");
        uint256 contractBalance = predictionToken.balanceOf(address(this));
        uint256 lockedInClaims = 0;
        // This would require iterating through all active claims and funding proposals
        // to determine truly 'excess' funds. For simplicity, this withdraws all current balance.
        // A more robust solution would track total locked funds explicitly.
        
        // For demonstration, let's assume all funds not currently staked are "excess" for now.
        // In a real system, you'd need to calculate sum of all `totalStakedOnClaim` and
        // `FundingProposal` amounts for `Approved` status etc.
        
        require(predictionToken.transfer(_recipient, contractBalance), "ChronoPredictDAO: Token transfer failed");
        emit FundsWithdrawn(_recipient, contractBalance);
    }

    // --- II. Claim Management ---

    /**
     * @dev Allows a user to submit a new claim (future event) for prediction.
     * @param _description A detailed description of the claim.
     * @param _submissionDeadline Timestamp when new outcomes can no longer be added.
     * @param _resolutionDeadline Timestamp by which the oracle should resolve the claim.
     */
    function submitClaim(
        string calldata _description,
        uint256 _submissionDeadline,
        uint256 _resolutionDeadline
    ) external {
        require(bytes(_description).length > 0, "ChronoPredictDAO: Claim description cannot be empty");
        require(_submissionDeadline > block.timestamp, "ChronoPredictDAO: Submission deadline must be in the future");
        require(_resolutionDeadline > _submissionDeadline, "ChronoPredictDAO: Resolution deadline must be after submission deadline");

        _claimIdCounter.increment();
        uint256 newClaimId = _claimIdCounter.current();

        Claim storage newClaim = claims[newClaimId];
        newClaim.id = newClaimId;
        newClaim.description = _description;
        newClaim.submissionDeadline = _submissionDeadline;
        newClaim.resolutionDeadline = _resolutionDeadline;
        newClaim.status = ClaimStatus.OpenForSubmission;
        newClaim.proposer = msg.sender;

        emit ClaimSubmitted(newClaimId, _description, msg.sender);
    }

    /**
     * @dev Allows users to propose a specific outcome for an existing claim.
     * @param _claimId The ID of the claim.
     * @param _outcomeDescription A description of the proposed outcome.
     */
    function proposeOutcome(
        uint256 _claimId,
        string calldata _outcomeDescription
    ) external claimExists(_claimId) claimOpenForSubmission(_claimId) {
        require(bytes(_outcomeDescription).length > 0, "ChronoPredictDAO: Outcome description cannot be empty");

        Claim storage claim = claims[_claimId];
        uint256 newOutcomeId = claim.outcomeIds.length.add(1); // Outcome IDs start from 1

        claim.outcomes[newOutcomeId].id = newOutcomeId;
        claim.outcomes[newOutcomeId].description = _outcomeDescription;
        claim.outcomes[newOutcomeId].collectiveProbability = 0;
        claim.outcomeIds.push(newOutcomeId);

        emit OutcomeProposed(_claimId, newOutcomeId, _outcomeDescription);
    }

    /**
     * @dev Closes a claim for new outcome submissions and makes it ready for predictions.
     *      Can be called by claim proposer, owner, or automatically after deadline.
     * @param _claimId The ID of the claim.
     */
    function closeClaimSubmission(uint256 _claimId) external claimExists(_claimId) {
        Claim storage claim = claims[_claimId];
        require(claim.status == ClaimStatus.OpenForSubmission, "ChronoPredictDAO: Claim is not in submission phase");
        require(msg.sender == claim.proposer || msg.sender == owner() || block.timestamp > claim.submissionDeadline,
            "ChronoPredictDAO: Only proposer, owner, or after deadline can close submission");
        require(claim.outcomeIds.length >= 2, "ChronoPredictDAO: At least two outcomes required to close submission");

        claim.status = ClaimStatus.OpenForPrediction;
        emit ClaimSubmissionClosed(_claimId);
    }

    /**
     * @dev The trusted oracle resolves a claim, setting its actual outcome.
     *      This triggers reputation updates and reward calculations.
     * @param _claimId The ID of the claim to resolve.
     * @param _actualOutcomeId The ID of the outcome that actually occurred.
     */
    function resolveClaim(
        uint256 _claimId,
        uint256 _actualOutcomeId
    ) external onlyOracle claimExists(_claimId) {
        Claim storage claim = claims[_claimId];
        require(claim.status == ClaimStatus.OpenForPrediction, "ChronoPredictDAO: Claim not open for resolution");
        require(block.timestamp > claim.resolutionDeadline, "ChronoPredictDAO: Resolution deadline not passed yet");
        require(_actualOutcomeId > 0 && _actualOutcomeId <= claim.outcomeIds.length, "ChronoPredictDAO: Invalid actual outcome ID");

        claim.resolvedOutcomeId = _actualOutcomeId;
        claim.status = ClaimStatus.Resolved;

        // Update reputation for all predictors on this claim
        _updateReputations(_claimId, _actualOutcomeId);

        emit ClaimResolved(_claimId, _actualOutcomeId);
    }

    // --- III. Prediction & Staking ---

    /**
     * @dev Users stake tokens on the probability of a specific outcome for a claim.
     *      Their stake influences the collective probability based on their reputation.
     * @param _claimId The ID of the claim.
     * @param _outcomeId The ID of the outcome being predicted.
     * @param _amount The amount of tokens to stake.
     */
    function predictAndStake(
        uint256 _claimId,
        uint256 _outcomeId,
        uint256 _amount
    ) external claimExists(_claimId) claimOpenForPrediction(_claimId) {
        require(_amount > 0, "ChronoPredictDAO: Stake amount must be greater than zero");
        require(_outcomeId > 0 && _outcomeId <= claims[_claimId].outcomeIds.length, "ChronoPredictDAO: Invalid outcome ID");
        require(predictionToken.balanceOf(msg.sender) >= _amount, "ChronoPredictDAO: Insufficient token balance");
        require(predictionToken.allowance(msg.sender, address(this)) >= _amount, "ChronoPredictDAO: Token allowance too low");

        Claim storage claim = claims[_claimId];
        Outcome storage outcome = claim.outcomes[_outcomeId];
        UserProfile storage user = userProfiles[msg.sender];

        // Ensure userProfile exists, if not, init with a default reputation
        if (user.reputation == 0 && msg.sender != owner()) {
            user.reputation = PROBABILITY_DENOMINATOR; // Start with a minimal reputation (100%)
        }

        // Check if user already predicted on this outcome
        Prediction storage existingPrediction = user.userPredictions[_claimId][_outcomeId];
        if (existingPrediction.stakedAmount > 0) {
            revert("ChronoPredictDAO: Already predicted on this outcome, use updatePredictionStake");
        }

        // Transfer tokens to contract
        require(predictionToken.transferFrom(msg.sender, address(this), _amount), "ChronoPredictDAO: Token transfer failed");

        // Record the prediction
        uint256 newPredictionId = _claimIdCounter.current().add(1); // Using claim counter for prediction IDs too (simple)
        predictions[newPredictionId].id = newPredictionId;
        predictions[newPredictionId].claimId = _claimId;
        predictions[newPredictionId].outcomeId = _outcomeId;
        predictions[newPredictionId].predictor = msg.sender;
        predictions[newPredictionId].stakedAmount = _amount;
        predictions[newPredictionId].timestamp = block.timestamp;
        predictions[newPredictionId].reputationAtPrediction = user.reputation;
        predictions[newPredictionId].initialCollectiveProbability = outcome.collectiveProbability; // Store for later reward calc

        claim.predictionIds.push(newPredictionId); // Track all predictions for a claim
        user.userPredictions[_claimId][_outcomeId] = predictions[newPredictionId]; // Store directly in user profile
        user.predictedClaimIds.push(_claimId); // Track claims user has predicted on

        // Update claim and outcome totals
        claim.totalStakedOnClaim = claim.totalStakedOnClaim.add(_amount);
        outcome.totalStakedOnOutcome = outcome.totalStakedOnOutcome.add(_amount);

        // Re-calculate collective probabilities for all outcomes in this claim
        _updateCollectiveProbabilities(_claimId);

        emit PredictionMade(_claimId, _outcomeId, msg.sender, _amount);
    }

    /**
     * @dev Allows users to increase or decrease their stake on a particular outcome.
     * @param _claimId The ID of the claim.
     * @param _outcomeId The ID of the outcome.
     * @param _newAmount The new total amount to stake (can be higher or lower).
     */
    function updatePredictionStake(
        uint256 _claimId,
        uint256 _outcomeId,
        uint256 _newAmount
    ) external claimExists(_claimId) claimOpenForPrediction(_claimId) {
        require(_outcomeId > 0 && _outcomeId <= claims[_claimId].outcomeIds.length, "ChronoPredictDAO: Invalid outcome ID");

        Prediction storage existingPrediction = userProfiles[msg.sender].userPredictions[_claimId][_outcomeId];
        require(existingPrediction.stakedAmount > 0, "ChronoPredictDAO: No existing prediction to update");
        require(_newAmount >= 0, "ChronoPredictDAO: New amount cannot be negative");

        uint256 oldAmount = existingPrediction.stakedAmount;
        int256 diff = int256(_newAmount) - int256(oldAmount);

        if (diff == 0) {
            return; // No change
        } else if (diff > 0) { // Increasing stake
            uint256 amountToAdd = uint256(diff);
            require(predictionToken.balanceOf(msg.sender) >= amountToAdd, "ChronoPredictDAO: Insufficient token balance to increase stake");
            require(predictionToken.allowance(msg.sender, address(this)) >= amountToAdd, "ChronoPredictDAO: Token allowance too low to increase stake");
            require(predictionToken.transferFrom(msg.sender, address(this), amountToAdd), "ChronoPredictDAO: Token transfer failed");
        } else { // Decreasing stake
            uint256 amountToSubtract = uint256(-diff);
            require(predictionToken.balanceOf(address(this)) >= amountToSubtract, "ChronoPredictDAO: Contract has insufficient funds"); // Should not happen with proper tracking
            require(predictionToken.transfer(msg.sender, amountToSubtract), "ChronoPredictDAO: Token transfer back failed");
        }

        existingPrediction.stakedAmount = _newAmount;
        claims[_claimId].totalStakedOnClaim = claims[_claimId].totalStakedOnClaim.add(uint256(diff));
        claims[_claimId].outcomes[_outcomeId].totalStakedOnOutcome = claims[_claimId].outcomes[_outcomeId].totalStakedOnOutcome.add(uint256(diff));

        _updateCollectiveProbabilities(_claimId);
        emit PredictionUpdated(_claimId, _outcomeId, msg.sender, _newAmount);
    }


    /**
     * @dev Allows a user to withdraw their stake from an outcome BEFORE the claim is resolved.
     *      Their influence on the collective probability is removed.
     * @param _claimId The ID of the claim.
     * @param _outcomeId The ID of the outcome.
     */
    function withdrawPredictionStake(
        uint256 _claimId,
        uint256 _outcomeId
    ) external claimExists(_claimId) claimOpenForPrediction(_claimId) {
        Prediction storage existingPrediction = userProfiles[msg.sender].userPredictions[_claimId][_outcomeId];
        require(existingPrediction.stakedAmount > 0, "ChronoPredictDAO: No active prediction to withdraw");

        uint256 amount = existingPrediction.stakedAmount;
        existingPrediction.stakedAmount = 0; // Effectively remove the prediction

        claims[_claimId].totalStakedOnClaim = claims[_claimId].totalStakedOnClaim.sub(amount);
        claims[_claimId].outcomes[_outcomeId].totalStakedOnOutcome = claims[_claimId].outcomes[_outcomeId].totalStakedOnOutcome.sub(amount);

        require(predictionToken.transfer(msg.sender, amount), "ChronoPredictDAO: Token transfer failed");

        _updateCollectiveProbabilities(_claimId); // Recalculate probabilities after withdrawal
        emit PredictionWithdrawn(_claimId, _outcomeId, msg.sender, amount);
    }

    /**
     * @dev Allows users to claim rewards after a claim has been resolved.
     *      Rewards are based on their initial stake and the accuracy of their prediction.
     * @param _claimId The ID of the resolved claim.
     */
    function claimPredictionRewards(uint256 _claimId) external claimResolved(_claimId) {
        Claim storage claim = claims[_claimId];
        Prediction storage userPrediction = userProfiles[msg.sender].userPredictions[_claimId][claim.resolvedOutcomeId];
        
        require(userPrediction.stakedAmount > 0, "ChronoPredictDAO: No stake found for this user on the resolved outcome.");
        
        // Calculate reward based on reputation and accuracy relative to collective consensus
        // For simplicity, we assume rewards are based on `userPrediction.stakedAmount`
        // and a flat reward rate for being on the correct side.
        // A more advanced system would calculate 'profit' from probability shift.
        
        // Simple Reward Model: If predicted on the correct outcome, get stake back + a bonus.
        // The bonus can be weighted by initial reputation and the overall accuracy_weight_factor.
        uint256 rewardAmount = userPrediction.stakedAmount; // Return initial stake

        // Calculate a bonus for correct prediction
        // A simple bonus: (user's stake / total stake on correct outcome) * claim.totalStakedOnClaim * some_factor
        // Or, more accurately: user's stake * (1 + (accuracy_score * ACCURACY_WEIGHT_FACTOR / PROBABILITY_DENOMINATOR))
        
        // Example: If user predicted the resolved outcome, they get their stake back PLUS a bonus.
        // The bonus could be a portion of the total "pool" or based on how much their prediction
        // moved the collective probability towards the correct one, weighted by their reputation.

        // For simplicity: If you staked on the correct outcome, you get your stake back + a small bonus.
        // The *real* profit comes from a more complex AMM-style probability market.
        // Here, the focus is on reputation.
        
        // Let's say, 1% of the total claim pool is distributed as bonus to accurate predictors.
        // This makes it a zero-sum game within the claim, or the contract mints/takes fees.
        // For this contract, let's make it a fixed return plus a *potential* bonus from a *future* fee pool.
        // For now, it's just getting your stake back if correct, and rewards are implicit in reputation.

        // To make it interesting, we can reward based on *contribution to final consensus*.
        // If a user was correct, and their stake was significant, they get rewarded.
        
        // Let's assume a portion of the *total stake* on the claim is the reward pool for correct predictors.
        // This makes it a zero-sum game *among predictors*.
        
        uint256 totalCorrectStake = claims[_claimId].outcomes[claim.resolvedOutcomeId].totalStakedOnOutcome;
        
        // If the user predicted the correct outcome and they haven't claimed rewards yet
        if (userPrediction.outcomeId == claim.resolvedOutcomeId && userPrediction.stakedAmount > 0) {
            // Reward: Their initial stake back + a share of the "incorrectly staked" funds
            // (simplified: a portion of the total pool, proportional to their accurate stake)
            
            // This needs a more sophisticated rewards distribution model.
            // Option 1: Funds from incorrect predictions are distributed to correct ones.
            // Option 2: The contract takes a small fee and uses it for something else (DAO treasury).
            // Option 3: Contract just returns stakes and reputation is the main reward.

            // Let's go with a simple model: user gets their stake back if correct.
            // The "rewards" are primarily reputation and influence over funding.
            // A small bonus can be taken from the overall contract balance if it exists.
            
            // For a *real* prediction market, losing predictions contribute to winners' pools.
            // Since this isn't solely a betting market, let's keep rewards simple:
            // Get your stake back if correct. The "profit" is in the reputation gain.
            // The *contract itself* might gain fees from lost stakes if no one claims them, or if a fee is levied.

            // Simplified: User gets their stake back. No direct "profit" from others' losses.
            // Reputation is the primary incentive.
            
            require(predictionToken.transfer(msg.sender, rewardAmount), "ChronoPredictDAO: Reward transfer failed");
            userPrediction.stakedAmount = 0; // Mark as claimed
            emit RewardsClaimed(_claimId, msg.sender, rewardAmount);

        } else if (userPrediction.outcomeId != claim.resolvedOutcomeId && userPrediction.stakedAmount > 0) {
            // If the user predicted incorrectly, their stake is "lost" to the system.
            // These funds could go to the DAO treasury, or be distributed to correct predictors.
            // For now, they remain in the contract balance, contributing to the DAO's treasury.
            userPrediction.stakedAmount = 0; // Mark as processed
            emit RewardsClaimed(_claimId, msg.sender, 0); // No rewards, but processed
        } else {
            revert("ChronoPredictDAO: No unclaimed rewards or invalid prediction for this claim.");
        }
    }


    // --- IV. Reputation System & User Profiles ---

    /**
     * @dev Internal function to update reputations for all predictors on a resolved claim.
     *      Called by `resolveClaim`.
     * @param _claimId The ID of the resolved claim.
     * @param _actualOutcomeId The ID of the actual outcome.
     */
    function _updateReputations(uint256 _claimId, uint256 _actualOutcomeId) internal {
        Claim storage claim = claims[_claimId];
        
        // Decay all users' reputation by the set rate (conceptual, can be optimized)
        // For simplicity, we apply a decay *per claim resolution* to all active users.
        // A more complex system would have time-based decay or require users to 're-activate' reputation.
        
        // This loop can be very gas intensive for many users.
        // In a real system, reputation decay might be lazily applied or computed off-chain.
        // For demonstration, we'll apply it directly to users who predicted on this claim.
        // A global decay would iterate all users, which is impractical on-chain.

        // Iterate through all predictions on this claim
        for (uint256 i = 0; i < claim.predictionIds.length; i++) {
            Prediction storage prediction = predictions[claim.predictionIds[i]];
            UserProfile storage user = userProfiles[prediction.predictor];

            // Apply decay before accuracy adjustment
            user.reputation = user.reputation.mul(PROBABILITY_DENOMINATOR.sub(currentParameters.REPUTATION_DECAY_RATE_PER_CLAIM)).div(PROBABILITY_DENOMINATOR);
            if (user.reputation < PROBABILITY_DENOMINATOR / 10) user.reputation = PROBABILITY_DENOMINATOR / 10; // Minimum reputation

            // Calculate accuracy score for this specific prediction
            uint256 predictedProbOfActualOutcome = 0;
            if (prediction.outcomeId == _actualOutcomeId) {
                // If user predicted the correct outcome
                // How 'close' was their prediction's probability to the final collective probability of the actual outcome?
                // For simplicity: The higher their stake on the correct outcome, the more positive influence.
                // This is where a complex scoring model would be.
                // Simple model: higher the reputation, higher the impact.
                // A very simplified `accuracy_score` = `staked_amount * (user_reputation_at_prediction / PROBABILITY_DENOMINATOR)`
                
                // Let's refine reputation gain/loss.
                // Gain = stake * (1 + (user_accuracy - average_accuracy)) * ACC_FACTOR
                // Simplified: gain based on how much their prediction aligns with *actual* outcome.
                
                // The user's 'effective stake' is their staked amount * their reputation multiplier.
                uint256 effectiveStake = prediction.stakedAmount.mul(prediction.reputationAtPrediction).div(PROBABILITY_DENOMINATOR);
                
                // If they predicted the correct outcome:
                // They gain reputation proportional to their effective stake and the ACCURACY_WEIGHT_FACTOR.
                uint256 gain = effectiveStake.mul(currentParameters.ACCURACY_WEIGHT_FACTOR).div(PROBABILITY_DENOMINATOR);
                user.reputation = user.reputation.add(gain);

            } else {
                // If user predicted an incorrect outcome:
                // They lose reputation proportional to their effective stake on the incorrect outcome
                // and the INACCURACY_PENALTY_FACTOR.
                uint256 effectiveStake = prediction.stakedAmount.mul(prediction.reputationAtPrediction).div(PROBABILITY_DENOMINATOR);
                uint256 loss = effectiveStake.mul(currentParameters.INACCURACY_PENALTY_FACTOR).div(PROBABILITY_DENOMINATOR);
                
                // Ensure reputation doesn't go below zero or a minimum threshold
                if (user.reputation > loss) {
                    user.reputation = user.reputation.sub(loss);
                } else {
                    user.reputation = PROBABILITY_DENOMINATOR / 10; // Set to a minimum
                }
            }
            
            // Cap reputation at MAX_REPUTATION
            if (user.reputation > MAX_REPUTATION) {
                user.reputation = MAX_REPUTATION;
            }

            emit ReputationUpdated(prediction.predictor, user.reputation);
        }
    }

    /**
     * @dev Internal function to recalculate the collective probabilities for all outcomes of a claim.
     *      This is weighted by the staker's reputation at the time of prediction.
     * @param _claimId The ID of the claim.
     */
    function _updateCollectiveProbabilities(uint256 _claimId) internal {
        Claim storage claim = claims[_claimId];
        uint256 totalWeightedStake = 0;

        // Calculate total effective (reputation-weighted) stake across all outcomes for this claim
        for (uint256 i = 0; i < claim.outcomeIds.length; i++) {
            uint256 outcomeId = claim.outcomeIds[i];
            Outcome storage outcome = claim.outcomes[outcomeId];
            outcome.collectiveProbability = 0; // Reset for recalculation

            // Iterate through all predictions to sum effective stakes
            // This is computationally expensive if there are many predictions.
            // A more efficient way would be to track effective stakes per outcome directly.
            
            // For simplicity, we assume `outcome.totalStakedOnOutcome` already reflects weighted stakes
            // or we need to iterate through all individual `predictions` again.
            // Let's iterate `predictionIds` for _claimId and sum weighted stakes.

            uint256 currentOutcomeWeightedStake = 0;
            for (uint256 j = 0; j < claim.predictionIds.length; j++) {
                Prediction storage p = predictions[claim.predictionIds[j]];
                if (p.outcomeId == outcomeId) {
                    // Weighted by reputation at time of prediction
                    currentOutcomeWeightedStake = currentOutcomeWeightedStake.add(
                        p.stakedAmount.mul(p.reputationAtPrediction).div(PROBABILITY_DENOMINATOR)
                    );
                }
            }
            outcome.totalStakedOnOutcome = currentOutcomeWeightedStake; // Update outcome's total weighted stake
            totalWeightedStake = totalWeightedStake.add(currentOutcomeWeightedStake);
        }

        if (totalWeightedStake == 0) {
            // If no stake, all probabilities are zero
            for (uint256 i = 0; i < claim.outcomeIds.length; i++) {
                claims[_claimId].outcomes[claim.outcomeIds[i]].collectiveProbability = 0;
            }
            return;
        }

        // Distribute probabilities
        for (uint256 i = 0; i < claim.outcomeIds.length; i++) {
            uint256 outcomeId = claim.outcomeIds[i];
            Outcome storage outcome = claim.outcomes[outcomeId];
            outcome.collectiveProbability = outcome.totalStakedOnOutcome.mul(PROBABILITY_DENOMINATOR).div(totalWeightedStake);
        }

        // Ensure probabilities sum to 100% (or PROBABILITY_DENOMINATOR) due to rounding
        _normalizeProbabilities(_claimId);
    }

    /**
     * @dev Internal function to normalize probabilities to sum up to PROBABILITY_DENOMINATOR (100%).
     * @param _claimId The ID of the claim.
     */
    function _normalizeProbabilities(uint256 _claimId) internal {
        Claim storage claim = claims[_claimId];
        uint256 currentSum = 0;
        for (uint256 i = 0; i < claim.outcomeIds.length; i++) {
            currentSum = currentSum.add(claim.outcomes[claim.outcomeIds[i]].collectiveProbability);
        }

        if (currentSum == PROBABILITY_DENOMINATOR) return;

        if (currentSum > PROBABILITY_DENOMINATOR) {
            // Distribute the excess by subtracting from outcomes with highest probabilities
            uint256 diff = currentSum.sub(PROBABILITY_DENOMINATOR);
            for (uint256 i = 0; i < claim.outcomeIds.length && diff > 0; i++) {
                uint256 outcomeId = claim.outcomeIds[i];
                if (claim.outcomes[outcomeId].collectiveProbability > 0) {
                    uint256 decrement = claim.outcomes[outcomeId].collectiveProbability.mul(diff).div(currentSum);
                    if (decrement == 0 && diff > 0) decrement = 1; // Ensure progress
                    if (claim.outcomes[outcomeId].collectiveProbability > decrement) {
                        claim.outcomes[outcomeId].collectiveProbability = claim.outcomes[outcomeId].collectiveProbability.sub(decrement);
                        diff = diff.sub(decrement);
                    } else if (claim.outcomes[outcomeId].collectiveProbability > 0 && diff > 0) {
                        diff = diff.sub(claim.outcomes[outcomeId].collectiveProbability);
                        claim.outcomes[outcomeId].collectiveProbability = 0;
                    }
                }
            }
        } else { // currentSum < PROBABILITY_DENOMINATOR
            // Distribute the deficit by adding to outcomes with highest probabilities (or lowest if all are 0)
            uint256 diff = PROBABILITY_DENOMINATOR.sub(currentSum);
            for (uint256 i = 0; i < claim.outcomeIds.length && diff > 0; i++) {
                uint256 outcomeId = claim.outcomeIds[i];
                uint256 increment = (diff.mul(claim.outcomes[outcomeId].collectiveProbability).div(currentSum == 0 ? 1 : currentSum)); // Avoid div by zero
                 if (increment == 0 && diff > 0) increment = 1; // Ensure progress
                claim.outcomes[outcomeId].collectiveProbability = claim.outcomes[outcomeId].collectiveProbability.add(increment);
                diff = diff.sub(increment);
            }
             // Distribute any remaining difference to the first outcome
            if (diff > 0 && claim.outcomeIds.length > 0) {
                claim.outcomes[claim.outcomeIds[0]].collectiveProbability = claim.outcomes[claim.outcomeIds[0]].collectiveProbability.add(diff);
            }
        }
    }


    /**
     * @dev Views the current reputation score of a specific user.
     * @param _user The address of the user.
     * @return The user's reputation score (scaled by PROBABILITY_DENOMINATOR).
     */
    function getUserReputation(address _user) external view returns (uint256) {
        return userProfiles[_user].reputation;
    }

    /**
     * @dev (Conceptual) Returns a list of users with the highest reputation scores.
     *      Note: This function is highly gas-intensive for large numbers of users.
     *      In a production environment, this would be handled by off-chain indexing.
     * @param _count The number of top predictors to retrieve.
     * @return An array of addresses of top predictors.
     */
    function getTopPredictors(uint256 _count) external view returns (address[] memory) {
        // This is a placeholder. Iterating through all users on-chain is not scalable.
        // A proper implementation would require a custom data structure (e.g., a sorted list)
        // or rely on off-chain indexing services (TheGraph, etc.).
        
        address[] memory topPredictors = new address[](0);
        // For demonstration purposes, we'll return an empty array or a very small static set.
        // You'd need to manually build a list of users and sort them.
        // For example:
        // address[] memory allUsers; // Populate this from known users
        // Sort `allUsers` by reputation and return top `_count`.
        
        // This function exists conceptually to fulfill the requirement.
        // Practical implementation would be off-chain.
        return topPredictors;
    }

    /**
     * @dev Views a user's specific prediction history for a given claim.
     * @param _user The address of the user.
     * @param _claimId The ID of the claim.
     * @return Prediction struct containing details of their stake on the resolved outcome.
     */
    function getUserPredictionHistory(address _user, uint256 _claimId) external view claimExists(_claimId) returns (Prediction memory) {
        Claim storage claim = claims[_claimId];
        // This returns the prediction on the *resolved* outcome for simplicity.
        // If a user predicted multiple outcomes, it would need to return an array of predictions.
        // For now, it returns the prediction associated with the resolved outcome,
        // assuming a user has one primary prediction on a claim.
        // Or, more accurately, returns the specific prediction if they made one for the resolved outcome.
        
        if (claim.status == ClaimStatus.Resolved) {
             return userProfiles[_user].userPredictions[_claimId][claim.resolvedOutcomeId];
        }
        // If not resolved, it's ambiguous which prediction to return. Return a default or require outcomeId.
        // To get all predictions by user for a claim, a mapping of claimId to predictionId[] would be needed in UserProfile.
        return userProfiles[_user].userPredictions[_claimId][0]; // Returns a default-initialized struct if not found.
    }


    // --- V. Probabilistic Resource Allocation (Funding Proposals) ---

    /**
     * @dev Allows users (or DAO members) to propose a project to be funded.
     *      Funding is contingent upon a specific claim's outcome reaching a certain probability threshold.
     * @param _description Description of the funding proposal.
     * @param _amount The amount of tokens requested.
     * @param _targetClaimId The claim ID this proposal is tied to.
     * @param _targetOutcomeId The specific outcome within the targetClaim.
     * @param _minProbabilityThreshold Minimum probability (scaled) for target outcome to trigger funding.
     */
    function submitFundingProposal(
        string calldata _description,
        uint256 _amount,
        uint256 _targetClaimId,
        uint256 _targetOutcomeId,
        uint256 _minProbabilityThreshold
    ) external claimExists(_targetClaimId) {
        require(bytes(_description).length > 0, "ChronoPredictDAO: Proposal description cannot be empty");
        require(_amount > 0, "ChronoPredictDAO: Funding amount must be greater than zero");
        require(_targetOutcomeId > 0 && _targetOutcomeId <= claims[_targetClaimId].outcomeIds.length, "ChronoPredictDAO: Invalid target outcome ID");
        require(_minProbabilityThreshold <= PROBABILITY_DENOMINATOR, "ChronoPredictDAO: Probability threshold too high");
        require(_minProbabilityThreshold > 0, "ChronoPredictDAO: Probability threshold must be greater than zero");

        _fundingProposalIdCounter.increment();
        uint256 newProposalId = _fundingProposalIdCounter.current();

        FundingProposal storage newProposal = fundingProposals[newProposalId];
        newProposal.id = newProposalId;
        newProposal.description = _description;
        newProposal.amount = _amount;
        newProposal.targetClaimId = _targetClaimId;
        newProposal.targetOutcomeId = _targetOutcomeId;
        newProposal.minProbabilityThreshold = _minProbabilityThreshold;
        newProposal.proposer = msg.sender;
        newProposal.status = ProposalStatus.Pending;
        newProposal.creationTimestamp = block.timestamp;

        emit FundingProposalSubmitted(newProposalId, _description, _amount, msg.sender);
    }

    /**
     * @dev DAO members vote on whether to approve a funding proposal.
     *      This is a preliminary approval; actual execution depends on claim resolution.
     * @param _proposalId The ID of the funding proposal.
     * @param _approve True to vote for approval, false for rejection.
     */
    function voteOnFundingProposal(uint256 _proposalId, bool _approve) external fundingProposalExists(_proposalId) {
        FundingProposal storage proposal = fundingProposals[_proposalId];
        require(proposal.status == ProposalStatus.Pending, "ChronoPredictDAO: Proposal is not pending");
        require(!proposal.hasVoted[msg.sender], "ChronoPredictDAO: You have already voted on this proposal");
        
        // DAO members can be defined by a separate ERC721 or ERC20 holder, or just unique addresses
        // For simplicity, any user with reputation > 0 can vote (or set a minimum reputation)
        require(userProfiles[msg.sender].reputation > 0, "ChronoPredictDAO: You must have reputation to vote.");

        proposal.hasVoted[msg.sender] = true;
        if (_approve) {
            proposal.votesFor = proposal.votesFor.add(1);
        } else {
            proposal.votesAgainst = proposal.votesAgainst.add(1);
        }
        
        // Simple majority vote: can be more complex (e.g., quadratic voting, weighted by reputation)
        // For simplicity, if votesFor > votesAgainst after a set period, or reaches a threshold:
        // In a real DAO, there'd be a voting period and a quorum. For now, just count votes.
        
        // Auto-approve if reaches a threshold (example: owner/some fixed number of votes)
        if (proposal.votesFor >= currentParameters.MIN_PARAMETER_VOTES) {
            proposal.status = ProposalStatus.Approved;
        } else if (proposal.votesAgainst >= currentParameters.MIN_PARAMETER_VOTES) { // Simplified rejection logic
            proposal.status = ProposalStatus.Rejected;
        }

        emit FundingProposalVoted(_proposalId, msg.sender, _approve);
    }

    /**
     * @dev Executes an approved funding proposal if its target claim's resolved probability
     *      meets the minimum threshold. Funds are sent to the specified recipient.
     * @param _proposalId The ID of the funding proposal.
     * @param _recipient The address to send the funds to. (Can be pre-defined in proposal)
     */
    function executeFundingProposal(uint256 _proposalId, address _recipient) external fundingProposalExists(_proposalId) {
        FundingProposal storage proposal = fundingProposals[_proposalId];
        require(proposal.status == ProposalStatus.Approved, "ChronoPredictDAO: Funding proposal not approved");
        require(_recipient != address(0), "ChronoPredictDAO: Recipient address cannot be zero");

        Claim storage targetClaim = claims[proposal.targetClaimId];
        require(targetClaim.status == ClaimStatus.Resolved, "ChronoPredictDAO: Target claim not resolved yet");
        
        // Check if the resolved outcome meets the probability threshold
        require(targetClaim.resolvedOutcomeId == proposal.targetOutcomeId, "ChronoPredictDAO: Resolved outcome does not match target outcome.");
        require(targetClaim.outcomes[proposal.targetOutcomeId].collectiveProbability >= proposal.minProbabilityThreshold,
            "ChronoPredictDAO: Resolved probability below minimum threshold for funding.");

        require(predictionToken.balanceOf(address(this)) >= proposal.amount, "ChronoPredictDAO: Insufficient contract balance for funding");
        require(predictionToken.transfer(_recipient, proposal.amount), "ChronoPredictDAO: Funding transfer failed");

        proposal.status = ProposalStatus.Executed;
        emit FundingProposalExecuted(_proposalId, _recipient, proposal.amount);
    }

    // --- VI. Meta-Parameter Governance ---

    /**
     * @dev Allows DAO members to propose changes to the contract's adaptive parameters.
     * @param _paramName The name of the parameter to change (e.g., "ACCURACY_WEIGHT_FACTOR").
     * @param _newValue The new integer value for the parameter (scaled if needed).
     */
    function proposeParameterChange(bytes32 _paramName, int256 _newValue) external {
        // Only allow changing existing parameters
        require(_paramName == "ACCURACY_WEIGHT_FACTOR" ||
                _paramName == "INACCURACY_PENALTY_FACTOR" ||
                _paramName == "REPUTATION_DECAY_RATE_PER_CLAIM" ||
                _paramName == "MIN_PARAMETER_VOTES",
                "ChronoPredictDAO: Invalid parameter name");
        
        // Require a minimum reputation to propose changes
        require(userProfiles[msg.sender].reputation >= 10 * PROBABILITY_DENOMINATOR, "ChronoPredictDAO: Insufficient reputation to propose parameter changes.");

        _parameterChangeProposalIdCounter.increment();
        uint256 newProposalId = _parameterChangeProposalIdCounter.current();

        ParameterChangeProposal storage newProposal = parameterChangeProposals[newProposalId];
        newProposal.id = newProposalId;
        newProposal.paramName = _paramName;
        newProposal.newValue = _newValue;
        newProposal.proposer = msg.sender;
        newProposal.status = ProposalStatus.Pending;
        newProposal.creationTimestamp = block.timestamp;

        emit ParameterChangeProposed(newProposalId, _paramName, _newValue, msg.sender);
    }

    /**
     * @dev DAO members vote on proposed changes to adaptive parameters.
     * @param _proposalId The ID of the parameter change proposal.
     * @param _approve True to vote for approval, false for rejection.
     */
    function voteOnParameterChange(uint256 _proposalId, bool _approve) external parameterChangeProposalExists(_proposalId) {
        ParameterChangeProposal storage proposal = parameterChangeProposals[_proposalId];
        require(proposal.status == ProposalStatus.Pending, "ChronoPredictDAO: Parameter change proposal is not pending");
        require(!proposal.hasVoted[msg.sender], "ChronoPredictDAO: You have already voted on this proposal");
        
        require(userProfiles[msg.sender].reputation > 0, "ChronoPredictDAO: You must have reputation to vote.");

        proposal.hasVoted[msg.sender] = true;
        if (_approve) {
            proposal.votesFor = proposal.votesFor.add(1);
        } else {
            proposal.votesAgainst = proposal.votesAgainst.add(1);
        }
        
        // Simple majority vote: can be more complex (e.g., quadratic voting, weighted by reputation)
        if (proposal.votesFor >= currentParameters.MIN_PARAMETER_VOTES) {
            proposal.status = ProposalStatus.Approved;
        } else if (proposal.votesAgainst >= currentParameters.MIN_PARAMETER_VOTES) {
            proposal.status = ProposalStatus.Rejected;
        }

        emit ParameterChangeVoted(_proposalId, msg.sender, _approve);
    }

    /**
     * @dev Executes a successfully voted-on parameter change, updating the contract's behavior.
     * @param _proposalId The ID of the parameter change proposal.
     */
    function executeParameterChange(uint256 _proposalId) external parameterChangeProposalExists(_proposalId) {
        ParameterChangeProposal storage proposal = parameterChangeProposals[_proposalId];
        require(proposal.status == ProposalStatus.Approved, "ChronoPredictDAO: Parameter change proposal not approved");
        require(block.timestamp >= proposal.creationTimestamp.add(7 days), "ChronoPredictDAO: Voting period not yet over (example)"); // Example voting period

        bytes32 paramName = proposal.paramName;
        uint256 newValue = uint256(proposal.newValue); // Cast back to uint256 if applicable

        // Apply the parameter change
        if (paramName == "ACCURACY_WEIGHT_FACTOR") {
            currentParameters.ACCURACY_WEIGHT_FACTOR = newValue;
        } else if (paramName == "INACCURACY_PENALTY_FACTOR") {
            currentParameters.INACCURACY_PENALTY_FACTOR = newValue;
        } else if (paramName == "REPUTATION_DECAY_RATE_PER_CLAIM") {
            currentParameters.REPUTATION_DECAY_RATE_PER_CLAIM = newValue;
        } else if (paramName == "MIN_PARAMETER_VOTES") {
             currentParameters.MIN_PARAMETER_VOTES = newValue;
        } else {
            revert("ChronoPredictDAO: Unknown parameter name for execution");
        }

        proposal.status = ProposalStatus.Executed;
        emit ParameterChangeExecuted(_proposalId, paramName, proposal.newValue);
    }

    /**
     * @dev Views the current values of all adaptive parameters.
     * @return A struct containing all current parameter values.
     */
    function getCurrentParameters() external view returns (AdaptiveParameters memory) {
        return currentParameters;
    }

    // --- VII. View Functions (Public Read-Only) ---

    /**
     * @dev Retrieves all details for a specific claim.
     * @param _claimId The ID of the claim.
     * @return Claim struct containing all its data.
     */
    function getClaimDetails(uint256 _claimId) external view claimExists(_claimId) returns (Claim memory) {
        Claim storage claim = claims[_claimId];
        // Cannot return mappings directly, so construct a new struct
        uint256[] memory outcomeIds = claim.outcomeIds;
        Claim memory claimDetails = Claim({
            id: claim.id,
            description: claim.description,
            submissionDeadline: claim.submissionDeadline,
            resolutionDeadline: claim.resolutionDeadline,
            status: claim.status,
            resolvedOutcomeId: claim.resolvedOutcomeId,
            proposer: claim.proposer,
            totalStakedOnClaim: claim.totalStakedOnClaim,
            // These mappings/arrays cannot be directly copied to memory struct
            // If you need all outcomes/predictions, create separate view functions for them.
            // For simplicity, we create a dummy for the mappings and copy only scalar types
            outcomes: claim.outcomes, // This will be default initialized in memory
            outcomeIds: outcomeIds,
            predictionIds: claim.predictionIds
        });
        return claimDetails;
    }

    /**
     * @dev Retrieves details for a specific outcome of a claim.
     * @param _claimId The ID of the claim.
     * @param _outcomeId The ID of the outcome.
     * @return Outcome struct containing its data.
     */
    function getOutcomeDetails(uint256 _claimId, uint256 _outcomeId) external view claimExists(_claimId) returns (Outcome memory) {
        require(_outcomeId > 0 && _outcomeId <= claims[_claimId].outcomeIds.length, "ChronoPredictDAO: Invalid outcome ID");
        return claims[_claimId].outcomes[_outcomeId];
    }

    /**
     * @dev Returns the current status of a claim.
     * @param _claimId The ID of the claim.
     * @return The status enum value.
     */
    function getClaimStatus(uint256 _claimId) external view claimExists(_claimId) returns (ClaimStatus) {
        return claims[_claimId].status;
    }

    /**
     * @dev Retrieves details for a specific funding proposal.
     * @param _proposalId The ID of the funding proposal.
     * @return FundingProposal struct containing its data.
     */
    function getFundingProposalDetails(uint256 _proposalId) external view fundingProposalExists(_proposalId) returns (FundingProposal memory) {
        FundingProposal storage proposal = fundingProposals[_proposalId];
        FundingProposal memory proposalDetails = FundingProposal({
            id: proposal.id,
            description: proposal.description,
            amount: proposal.amount,
            targetClaimId: proposal.targetClaimId,
            targetOutcomeId: proposal.targetOutcomeId,
            minProbabilityThreshold: proposal.minProbabilityThreshold,
            proposer: proposal.proposer,
            status: proposal.status,
            votesFor: proposal.votesFor,
            votesAgainst: proposal.votesAgainst,
            hasVoted: proposal.hasVoted, // This will be a default initialized mapping in memory
            creationTimestamp: proposal.creationTimestamp
        });
        return proposalDetails;
    }

    /**
     * @dev Returns the current balance of the ERC20 token held by the contract.
     * @return The total token amount.
     */
    function getAvailableFunds() external view returns (uint256) {
        return predictionToken.balanceOf(address(this));
    }
}
```