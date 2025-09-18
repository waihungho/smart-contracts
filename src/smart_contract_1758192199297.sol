This smart contract, `AetheriumNexus`, is designed to be an advanced, multi-faceted platform for **adaptive collective intelligence, dynamic soulbound attributes, and community-driven evolution**. It combines elements of reputation systems, decentralized governance, task management, and prediction markets into a cohesive, epoch-based ecosystem.

**Core Concepts:**

1.  **Dynamic Soulbound Attributes (SBAs):** Non-transferable tokens that represent user skills, contributions, and reputation. They are not static ERC721s but rather integer values tied to an address and an SBA type, which can be minted, upgraded, downgraded, and even *decay* over time (epochs), reflecting a living, evolving identity.
2.  **Prophetic Consensus Governance:** A unique governance model where voting power is weighted by aggregated SBAs. Crucially, proposals for system parameter changes incorporate a "prediction" phase. Users not only vote but also submit their ideal parameter value. While voting dictates acceptance, future reputation gains for "prophetic" accuracy can influence future governance.
3.  **Epoch-based Evolution:** The contract operates in discrete "epochs." Many system processes, like SBA decay, proposal evaluation, and certain market resolutions, are tied to epoch transitions, creating a sense of natural progression and dynamic state changes.
4.  **Decentralized Tasking & Attestation:** A system where users can propose tasks, complete them, and have their completion verified by other qualified (high-SBA) community members. Successful task completion grants rewards and SBAs, reinforcing the reputation loop.
5.  **Wisdom Pool (Prediction Markets):** Dedicated markets for specific numerical predictions (e.g., future economic metrics, project milestones). Users stake tokens on their predictions, and accuracy is rewarded, creating a collective intelligence mechanism that can inform decision-making.

---

## `AetheriumNexus` Smart Contract

**Outline:**

I.  **Core Infrastructure & Administration**
    *   Ownership and Pausability
    *   Epoch Management
    *   System Parameter Configuration

II. **Soulbound Attributes (SBA) Management**
    *   Defining SBA Types
    *   Minting, Updating, and Querying SBAs
    *   SBA Decay Logic
    *   Overall Reputation Calculation

III. **Prophetic Consensus (Adaptive Governance)**
    *   Proposal Creation for System Parameters
    *   Voting on Proposals with SBA-weighted influence
    *   Submission of Parameter Predictions
    *   Evaluation of Predictions and Proposal Execution

IV. **Decentralized Task & Bounty System**
    *   Creation of Tasks with Rewards and SBA incentives
    *   Submission of Task Completion Proofs
    *   Attestation/Verification of Task Completion
    *   Claiming Rewards and SBA accrual

V.  **Wisdom Pool (Prediction Markets)**
    *   Creation of Numerical Prediction Markets
    *   Staking Tokens on Predictions
    *   Resolution of Markets by Oracle/Admin
    *   Claiming Payouts based on Prediction Accuracy

---

**Function Summary:**

**I. Core Infrastructure & Administration**
1.  `constructor(address _rewardTokenAddress, uint256 _epochDuration)`: Initializes the contract, sets the owner, reward token, and epoch duration.
2.  `pauseContract()`: Allows the owner to pause certain contract operations for maintenance or emergencies.
3.  `unpauseContract()`: Allows the owner to unpause the contract.
4.  `advanceEpoch()`: Triggers the end-of-epoch logic (callable by anyone after `_epochDuration` has passed).
5.  `setSystemParameter(uint256 _paramId, uint256 _value)`: Owner sets global system parameters (e.g., minimum reputation for voting).
6.  `getSystemParameter(uint256 _paramId)`: Retrieves the value of a system parameter.
7.  `getEpoch()`: Returns the current epoch number.
8.  `getEpochEndTime()`: Returns the timestamp when the current epoch is scheduled to end.

**II. Soulbound Attributes (SBA) Management**
9.  `defineSBA(string memory _name, uint256 _initialValue, uint256 _decayRatePerEpoch, bool _isSkillBased)`: Defines a new type of Soulbound Attribute, specifying its name, starting value, decay rate per epoch, and if it's skill-based.
10. `mintSBA(address _to, uint256 _sbaTypeId, uint256 _amount)`: Mints a specific amount of an SBA type to an address (e.g., via admin, or internally after task completion).
11. `updateSBA(address _user, uint256 _sbaTypeId, uint256 _newAmount)`: Directly updates the value of a user's SBA (e.g., for specific event-driven adjustments).
12. `decayUserSBAs(address _user)`: Applies the defined decay rate to all skill-based SBAs of a specific user for the current epoch.
13. `getSBAValue(address _user, uint256 _sbaTypeId)`: Returns the current value of a specific SBA type for a given user.
14. `getOverallReputation(address _user)`: Calculates and returns an aggregated reputation score for a user based on their SBAs (weighted sum).

**III. Prophetic Consensus (Adaptive Governance)**
15. `proposeParameterChange(uint256 _paramId, uint256 _newValue, string memory _description)`: Creates a proposal to change a system parameter, requiring a minimum reputation to propose.
16. `submitParameterPrediction(uint256 _proposalId, uint256 _predictedValue)`: Users submit their prediction for the optimal value of the parameter being proposed.
17. `voteOnProposal(uint256 _proposalId, bool _support)`: Allows users with sufficient reputation to vote for or against a proposal. Voting power is weighted by `getOverallReputation()`.
18. `tallyVotesAndEvaluatePredictions(uint256 _proposalId)`: Finalizes voting, determines if the proposal passes, and evaluates the accuracy of submitted predictions, assigning "prophetic scores" (simulated for future use).
19. `executeProposal(uint256 _proposalId)`: Executes a passed proposal, applying the proposed parameter change.

**IV. Decentralized Task & Bounty System**
20. `createTask(string memory _title, string memory _description, uint256 _rewardAmount, uint256 _requiredAttesterReputation, uint256 _sbaRewardTypeId, uint256 _sbaRewardAmount, uint256 _attestationThreshold)`: Creates a new task with a token reward and an SBA reward upon completion.
21. `submitTaskCompletion(uint256 _taskId, string memory _proofCid)`: A user submits a proof of task completion (e.g., an IPFS hash).
22. `attestTaskCompletion(uint256 _taskId, address _applicant, bool _isVerified)`: Qualified users (e.g., with high overall reputation) can attest to the completion of a submitted task.
23. `claimTaskReward(uint256 _taskId, address _applicant)`: Allows the applicant to claim rewards (tokens and SBAs) once sufficient attestations are gathered.

**V. Wisdom Pool (Prediction Markets)**
24. `createWisdomPredictionMarket(string memory _question, uint256 _resolutionEpoch, uint256 _oracleResolutionParamId)`: Creates a new market for a numerical prediction, resolved at a specific epoch, referencing a system parameter that an oracle would resolve.
25. `stakePrediction(uint256 _marketId, uint256 _predictedValue, uint256 _stakeAmount)`: Users stake tokens on their predicted value for a specific market.
26. `resolveWisdomPredictionMarket(uint256 _marketId, uint256 _actualValue)`: Owner/Oracle resolves the market by providing the actual outcome value.
27. `claimPredictionPayout(uint256 _marketId)`: Allows accurate predictors to claim their proportional share of the staked pool.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // For reward token interaction

// Custom Errors
error Unauthorized();
error Paused();
error NotPaused();
error InvalidSBAId();
error InvalidProposalId();
error ProposalNotActive();
error AlreadyVoted();
error NotEnoughReputation();
error PredictionPeriodEnded();
error VotingPeriodNotEnded();
error ProposalAlreadyExecuted();
error TaskNotFound();
error TaskNotSubmitted();
error AlreadyAttested();
error NotEnoughAttestations();
error TaskAlreadyCompleted();
error TaskRewardAlreadyClaimed();
error WisdomMarketNotFound();
error WisdomMarketAlreadyResolved();
error WisdomMarketNotResolved();
error PredictionPeriodNotEnded();
error NothingToClaim();
error CannotAdvanceEpochYet();
error EpochStillActive();
error ProposalNotYetPassed();
error ZeroAddressNotAllowed();
error ZeroValueNotAllowed();
error InvalidAmount();
error InvalidDecayRate();
error InvalidThreshold();
error InvalidEpochDuration();

/**
 * @title AetheriumNexus
 * @dev A smart contract for adaptive collective intelligence, dynamic soulbound attributes,
 *      and community-driven evolution. It integrates reputation systems, decentralized governance,
 *      task management, and prediction markets in an epoch-based ecosystem.
 *
 * Outline:
 * I.   Core Infrastructure & Administration
 *      - Ownership and Pausability
 *      - Epoch Management
 *      - System Parameter Configuration
 * II.  Soulbound Attributes (SBA) Management
 *      - Defining SBA Types
 *      - Minting, Updating, and Querying SBAs
 *      - SBA Decay Logic
 *      - Overall Reputation Calculation
 * III. Prophetic Consensus (Adaptive Governance)
 *      - Proposal Creation for System Parameters
 *      - Voting on Proposals with SBA-weighted influence
 *      - Submission of Parameter Predictions
 *      - Evaluation of Predictions and Proposal Execution
 * IV.  Decentralized Task & Bounty System
 *      - Creation of Tasks with Rewards and SBA incentives
 *      - Submission of Task Completion Proofs
 *      - Attestation/Verification of Task Completion
 *      - Claiming Rewards and SBA accrual
 * V.   Wisdom Pool (Prediction Markets)
 *      - Creation of Numerical Prediction Markets
 *      - Staking Tokens on Predictions
 *      - Resolution of Markets by Oracle/Admin
 *      - Claiming Payouts based on Prediction Accuracy
 *
 * Function Summary:
 * I.   Core Infrastructure & Administration
 *      1.  constructor(address _rewardTokenAddress, uint256 _epochDuration)
 *      2.  pauseContract()
 *      3.  unpauseContract()
 *      4.  advanceEpoch()
 *      5.  setSystemParameter(uint256 _paramId, uint256 _value)
 *      6.  getSystemParameter(uint256 _paramId)
 *      7.  getEpoch()
 *      8.  getEpochEndTime()
 * II.  Soulbound Attributes (SBA) Management
 *      9.  defineSBA(string memory _name, uint256 _initialValue, uint256 _decayRatePerEpoch, bool _isSkillBased)
 *      10. mintSBA(address _to, uint256 _sbaTypeId, uint256 _amount)
 *      11. updateSBA(address _user, uint256 _sbaTypeId, uint256 _newAmount)
 *      12. decayUserSBAs(address _user)
 *      13. getSBAValue(address _user, uint256 _sbaTypeId)
 *      14. getOverallReputation(address _user)
 * III. Prophetic Consensus (Adaptive Governance)
 *      15. proposeParameterChange(uint256 _paramId, uint256 _newValue, string memory _description)
 *      16. submitParameterPrediction(uint256 _proposalId, uint256 _predictedValue)
 *      17. voteOnProposal(uint256 _proposalId, bool _support)
 *      18. tallyVotesAndEvaluatePredictions(uint256 _proposalId)
 *      19. executeProposal(uint256 _proposalId)
 * IV.  Decentralized Task & Bounty System
 *      20. createTask(string memory _title, string memory _description, uint256 _rewardAmount, uint256 _requiredAttesterReputation, uint256 _sbaRewardTypeId, uint256 _sbaRewardAmount, uint256 _attestationThreshold)
 *      21. submitTaskCompletion(uint256 _taskId, string memory _proofCid)
 *      22. attestTaskCompletion(uint256 _taskId, address _applicant, bool _isVerified)
 *      23. claimTaskReward(uint256 _taskId, address _applicant)
 * V.   Wisdom Pool (Prediction Markets)
 *      24. createWisdomPredictionMarket(string memory _question, uint256 _resolutionEpoch, uint256 _oracleResolutionParamId)
 *      25. stakePrediction(uint256 _marketId, uint256 _predictedValue, uint256 _stakeAmount)
 *      26. resolveWisdomPredictionMarket(uint256 _marketId, uint256 _actualValue)
 *      27. claimPredictionPayout(uint256 _marketId)
 */
contract AetheriumNexus {
    // --- State Variables ---

    address private _owner;
    bool private _paused;
    IERC20 private immutable _rewardToken;

    // Epoch Management
    uint256 public _epochDuration; // Duration of an epoch in seconds
    uint256 public _currentEpoch;
    uint256 public _lastEpochAdvanceTime;

    // System Parameters (tunable by governance)
    enum SystemParam {
        MIN_PROPOSAL_REPUTATION,
        PROPOSAL_VOTING_EPOCHS,
        TASK_VERIFIER_REPUTATION_THRESHOLD,
        MIN_ATTESTATIONS_FOR_TASK
    }
    mapping(uint256 => uint256) private _systemParameters;

    // Soulbound Attributes (SBA)
    struct SBAType {
        string name;
        uint256 initialValue;
        uint256 decayRatePerEpoch; // e.g., 100 = 1% decay, 0 = no decay (max 10000 = 100%)
        bool isSkillBased; // If true, subject to decay
    }
    SBAType[] public sbaTypes;
    mapping(address => mapping(uint256 => uint256)) public userSBAs; // user => sbaTypeId => value

    // Prophetic Consensus Governance
    struct Proposal {
        uint256 paramId; // Corresponds to SystemParam enum index
        uint256 newValue;
        string description;
        uint256 creationEpoch;
        uint256 votingEndEpoch;
        uint256 totalVotesFor;
        uint256 totalVotesAgainst;
        bool executed;
        mapping(address => bool) hasVoted;
        mapping(address => uint256) predictions; // user => predictedValue
        mapping(address => bool) hasPredicted;
        bool passed; // True if proposal passed votes
        uint256 avgPredictionDeviation; // Average deviation of predictions from actual outcome, or system average
    }
    Proposal[] public proposals;

    // Decentralized Task System
    struct Task {
        string title;
        string description;
        uint256 rewardAmount;
        uint256 requiredAttesterReputation;
        uint256 sbaRewardTypeId;
        uint256 sbaRewardAmount;
        uint256 attestationThreshold;
        uint256 creationEpoch;
        mapping(address => bool) hasSubmittedProof; // applicant => true
        mapping(address => bool) attestations; // attester => true
        uint256 verifiedCount;
        address applicant;
        bool completed;
        bool rewardsClaimed;
    }
    Task[] public tasks;

    // Wisdom Pool (Prediction Markets)
    struct PredictionStake {
        uint256 predictedValue;
        uint256 amountStaked;
    }
    struct WisdomMarket {
        string question;
        uint256 creationEpoch;
        uint256 resolutionEpoch;
        uint256 actualResolutionValue; // Set by owner/oracle upon resolution
        uint256 totalStaked;
        mapping(address => PredictionStake) stakes;
        bool resolved;
        uint256 oracleResolutionParamId; // Identifier for the actual value, could map to a system param or external data
    }
    WisdomMarket[] public wisdomMarkets;

    // --- Events ---
    event EpochAdvanced(uint256 newEpoch);
    event Paused(address indexed account);
    event Unpaused(address indexed account);
    event SystemParameterSet(uint256 indexed paramId, uint256 value);
    event SBADefined(uint256 indexed sbaTypeId, string name);
    event SBAMinted(address indexed user, uint256 indexed sbaTypeId, uint256 amount);
    event SBAUpdated(address indexed user, uint256 indexed sbaTypeId, uint256 newAmount);
    event SBADecayed(address indexed user, uint256 indexed sbaTypeId, uint256 oldAmount, uint256 newAmount);
    event ProposalCreated(uint256 indexed proposalId, address indexed creator, uint256 paramId, uint256 newValue);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 reputationWeight);
    event PredictionSubmitted(uint256 indexed proposalId, address indexed predictor, uint256 predictedValue);
    event ProposalEvaluated(uint256 indexed proposalId, bool passed, uint256 totalFor, uint256 totalAgainst, uint256 avgDeviation);
    event ProposalExecuted(uint256 indexed proposalId, uint256 paramId, uint256 newValue);
    event TaskCreated(uint256 indexed taskId, address indexed creator, uint256 rewardAmount);
    event TaskSubmitted(uint256 indexed taskId, address indexed applicant, string proofCid);
    event TaskAttested(uint256 indexed taskId, address indexed attester, address indexed applicant, bool isVerified);
    event TaskRewardClaimed(uint256 indexed taskId, address indexed applicant, uint256 rewardAmount, uint256 sbaRewardAmount);
    event WisdomMarketCreated(uint256 indexed marketId, string question, uint256 resolutionEpoch);
    event PredictionStaked(uint256 indexed marketId, address indexed predictor, uint256 predictedValue, uint256 amount);
    event WisdomMarketResolved(uint256 indexed marketId, uint256 actualValue);
    event PredictionPayoutClaimed(uint256 indexed marketId, address indexed claimant, uint256 payout);

    // --- Modifiers ---
    modifier onlyOwner() {
        if (msg.sender != _owner) revert Unauthorized();
        _;
    }

    modifier whenNotPaused() {
        if (_paused) revert Paused();
        _;
    }

    modifier whenPaused() {
        if (!_paused) revert NotPaused();
        _;
    }

    modifier onlyValidSBA(uint256 _sbaTypeId) {
        if (_sbaTypeId >= sbaTypes.length) revert InvalidSBAId();
        _;
    }

    modifier onlyValidProposal(uint256 _proposalId) {
        if (_proposalId >= proposals.length) revert InvalidProposalId();
        _;
    }

    modifier onlyValidTask(uint256 _taskId) {
        if (_taskId >= tasks.length) revert TaskNotFound();
        _;
    }

    modifier onlyValidWisdomMarket(uint256 _marketId) {
        if (_marketId >= wisdomMarkets.length) revert WisdomMarketNotFound();
        _;
    }

    // --- Constructor ---
    constructor(address _rewardTokenAddress, uint256 _epochDurationSeconds) {
        if (_rewardTokenAddress == address(0)) revert ZeroAddressNotAllowed();
        if (_epochDurationSeconds == 0) revert InvalidEpochDuration();

        _owner = msg.sender;
        _rewardToken = IERC20(_rewardTokenAddress);
        _epochDuration = _epochDurationSeconds;
        _currentEpoch = 1;
        _lastEpochAdvanceTime = block.timestamp;
        _paused = false;

        // Initialize default system parameters (can be changed by governance)
        _systemParameters[uint256(SystemParam.MIN_PROPOSAL_REPUTATION)] = 100; // Example
        _systemParameters[uint256(SystemParam.PROPOSAL_VOTING_EPOCHS)] = 3;    // Example: 3 epochs for voting
        _systemParameters[uint256(SystemParam.TASK_VERIFIER_REPUTATION_THRESHOLD)] = 50; // Example
        _systemParameters[uint256(SystemParam.MIN_ATTESTATIONS_FOR_TASK)] = 2; // Example
    }

    // --- I. Core Infrastructure & Administration ---

    /**
     * @dev Pauses contract operations. Callable only by owner.
     */
    function pauseContract() external onlyOwner whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Unpauses contract operations. Callable only by owner.
     */
    function unpauseContract() external onlyOwner whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }

    /**
     * @dev Advances the current epoch. Can be called by anyone, but only if
     *      _epochDuration has passed since the last advance.
     *      Triggers epoch-end processing for SBAs and governance.
     */
    function advanceEpoch() external whenNotPaused {
        if (block.timestamp < _lastEpochAdvanceTime + _epochDuration) {
            revert CannotAdvanceEpochYet();
        }

        _currentEpoch++;
        _lastEpochAdvanceTime = block.timestamp;

        // Optionally, integrate a loop here to decay all SBAs or process all open proposals/markets
        // For efficiency, decayUserSBAs and tallyVotesAndEvaluatePredictions are user/admin-triggered
        // or can be called by an off-chain keeper service.
        // This function just advances the epoch counter.

        emit EpochAdvanced(_currentEpoch);
    }

    /**
     * @dev Sets a system parameter. Only callable by the owner initially,
     *      later by successful governance proposals.
     * @param _paramId The ID of the system parameter (enum SystemParam).
     * @param _value The new value for the parameter.
     */
    function setSystemParameter(uint256 _paramId, uint256 _value) public onlyOwner {
        // More robust access control would be needed if governance can change params
        // For now, owner has direct control over this function.
        // Governance will use `proposeParameterChange` -> `executeProposal` to update these.
        _systemParameters[_paramId] = _value;
        emit SystemParameterSet(_paramId, _value);
    }

    /**
     * @dev Retrieves the value of a system parameter.
     * @param _paramId The ID of the system parameter.
     * @return The current value of the parameter.
     */
    function getSystemParameter(uint256 _paramId) public view returns (uint256) {
        return _systemParameters[_paramId];
    }

    /**
     * @dev Returns the current epoch number.
     */
    function getEpoch() public view returns (uint256) {
        return _currentEpoch;
    }

    /**
     * @dev Returns the timestamp when the current epoch is scheduled to end.
     */
    function getEpochEndTime() public view returns (uint256) {
        return _lastEpochAdvanceTime + _epochDuration;
    }

    // --- II. Soulbound Attributes (SBA) Management ---

    /**
     * @dev Defines a new type of Soulbound Attribute. Callable by owner.
     * @param _name The name of the SBA (e.g., "Developer", "Community Contributor").
     * @param _initialValue The default initial value for this SBA when minted.
     * @param _decayRatePerEpoch The percentage decay per epoch (e.g., 100 for 1%, 1000 for 10%). Max 10000 (100%).
     * @param _isSkillBased If true, this SBA is subject to epoch-based decay.
     * @return The ID of the newly defined SBA type.
     */
    function defineSBA(
        string memory _name,
        uint256 _initialValue,
        uint256 _decayRatePerEpoch,
        bool _isSkillBased
    ) external onlyOwner returns (uint256) {
        if (bytes(_name).length == 0) revert ZeroValueNotAllowed();
        if (_decayRatePerEpoch > 10000) revert InvalidDecayRate(); // Max 100% decay

        uint256 sbaTypeId = sbaTypes.length;
        sbaTypes.push(SBAType({
            name: _name,
            initialValue: _initialValue,
            decayRatePerEpoch: _decayRatePerEpoch,
            isSkillBased: _isSkillBased
        }));
        emit SBADefined(sbaTypeId, _name);
        return sbaTypeId;
    }

    /**
     * @dev Mints a specific amount of an SBA type to a user.
     *      Typically used by admin or internally after task completion.
     * @param _to The address to mint the SBA to.
     * @param _sbaTypeId The ID of the SBA type.
     * @param _amount The amount of SBA to mint.
     */
    function mintSBA(address _to, uint256 _sbaTypeId, uint256 _amount) public onlyOwner onlyValidSBA(_sbaTypeId) {
        if (_to == address(0)) revert ZeroAddressNotAllowed();
        if (_amount == 0) revert InvalidAmount();

        userSBAs[_to][_sbaTypeId] += _amount;
        emit SBAMinted(_to, _sbaTypeId, _amount);
    }

    /**
     * @dev Directly updates the value of a user's SBA. Callable by owner.
     *      Can be used for specific event-driven adjustments or admin corrections.
     * @param _user The address whose SBA is being updated.
     * @param _sbaTypeId The ID of the SBA type.
     * @param _newAmount The new value for the SBA.
     */
    function updateSBA(address _user, uint256 _sbaTypeId, uint256 _newAmount) public onlyOwner onlyValidSBA(_sbaTypeId) {
        if (_user == address(0)) revert ZeroAddressNotAllowed();

        uint256 oldAmount = userSBAs[_user][_sbaTypeId];
        userSBAs[_user][_sbaTypeId] = _newAmount;
        emit SBAUpdated(_user, _sbaTypeId, _newAmount);
    }

    /**
     * @dev Applies the defined decay rate to all skill-based SBAs of a specific user.
     *      Intended to be called by the user or an off-chain keeper after epoch advance.
     *      Ensures decay is applied only once per epoch for each SBA type.
     * @param _user The address whose SBAs are to be decayed.
     */
    function decayUserSBAs(address _user) external whenNotPaused {
        for (uint256 i = 0; i < sbaTypes.length; i++) {
            SBAType storage sba = sbaTypes[i];
            if (sba.isSkillBased && sba.decayRatePerEpoch > 0) {
                uint256 currentValue = userSBAs[_user][i];
                if (currentValue == 0) continue; // No value to decay

                // Using a simple check to prevent multiple decays within the same epoch
                // A more robust system might track last decay epoch per user-SBA pair
                // For simplicity, this assumes a single decay trigger per epoch cycle.
                uint256 decayAmount = (currentValue * sba.decayRatePerEpoch) / 10000; // 10000 = 100%
                uint256 newAmount = currentValue - decayAmount;
                if (newAmount > currentValue) newAmount = 0; // Prevent underflow if decay is too large for current value
                
                userSBAs[_user][i] = newAmount;
                emit SBADecayed(_user, i, currentValue, newAmount);
            }
        }
    }


    /**
     * @dev Returns the current value of a specific SBA type for a given user.
     * @param _user The address of the user.
     * @param _sbaTypeId The ID of the SBA type.
     * @return The current value of the SBA.
     */
    function getSBAValue(address _user, uint256 _sbaTypeId) public view onlyValidSBA(_sbaTypeId) returns (uint256) {
        return userSBAs[_user][_sbaTypeId];
    }

    /**
     * @dev Calculates and returns an aggregated reputation score for a user.
     *      This is a sum of all current SBA values. Can be weighted in a more complex scenario.
     * @param _user The address of the user.
     * @return The overall reputation score.
     */
    function getOverallReputation(address _user) public view returns (uint256) {
        uint256 totalReputation = 0;
        for (uint256 i = 0; i < sbaTypes.length; i++) {
            totalReputation += userSBAs[_user][i]; // Simple sum, could be weighted
        }
        return totalReputation;
    }

    // --- III. Prophetic Consensus (Adaptive Governance) ---

    /**
     * @dev Creates a proposal to change a system parameter.
     *      Requires a minimum reputation to propose.
     * @param _paramId The ID of the system parameter to change.
     * @param _newValue The new value for the parameter if the proposal passes.
     * @param _description A description of the proposal.
     * @return The ID of the newly created proposal.
     */
    function proposeParameterChange(uint256 _paramId, uint256 _newValue, string memory _description)
        external whenNotPaused returns (uint256)
    {
        if (getOverallReputation(msg.sender) < _systemParameters[uint256(SystemParam.MIN_PROPOSAL_REPUTATION)]) {
            revert NotEnoughReputation();
        }
        if (bytes(_description).length == 0) revert ZeroValueNotAllowed();

        uint256 proposalId = proposals.length;
        proposals.push(Proposal({
            paramId: _paramId,
            newValue: _newValue,
            description: _description,
            creationEpoch: _currentEpoch,
            votingEndEpoch: _currentEpoch + _systemParameters[uint256(SystemParam.PROPOSAL_VOTING_EPOCHS)],
            totalVotesFor: 0,
            totalVotesAgainst: 0,
            executed: false,
            hasVoted: new mapping(address => bool),
            predictions: new mapping(address => uint256),
            hasPredicted: new mapping(address => bool),
            passed: false,
            avgPredictionDeviation: 0
        }));
        emit ProposalCreated(proposalId, msg.sender, _paramId, _newValue);
        return proposalId;
    }

    /**
     * @dev Users submit their prediction for the optimal value of the parameter being proposed.
     *      Can be submitted before or during the voting period.
     * @param _proposalId The ID of the proposal.
     * @param _predictedValue The user's predicted optimal value for the parameter.
     */
    function submitParameterPrediction(uint256 _proposalId, uint256 _predictedValue)
        external whenNotPaused onlyValidProposal(_proposalId)
    {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.creationEpoch >= proposal.votingEndEpoch) revert PredictionPeriodEnded(); // Prediction window closed
        if (proposal.hasPredicted[msg.sender]) return; // Only one prediction per user

        proposal.predictions[msg.sender] = _predictedValue;
        proposal.hasPredicted[msg.sender] = true;
        emit PredictionSubmitted(_proposalId, msg.sender, _predictedValue);
    }

    /**
     * @dev Allows users with sufficient reputation to vote for or against a proposal.
     *      Voting power is weighted by `getOverallReputation()`.
     * @param _proposalId The ID of the proposal.
     * @param _support True for a 'for' vote, false for 'against'.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) external whenNotPaused onlyValidProposal(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.creationEpoch >= proposal.votingEndEpoch) revert ProposalNotActive();
        if (proposal.hasVoted[msg.sender]) revert AlreadyVoted();

        uint256 reputationWeight = getOverallReputation(msg.sender);
        if (reputationWeight < _systemParameters[uint256(SystemParam.MIN_PROPOSAL_REPUTATION)]) {
            revert NotEnoughReputation();
        }

        if (_support) {
            proposal.totalVotesFor += reputationWeight;
        } else {
            proposal.totalVotesAgainst += reputationWeight;
        }
        proposal.hasVoted[msg.sender] = true;
        emit VoteCast(_proposalId, msg.sender, _support, reputationWeight);
    }

    /**
     * @dev Finalizes voting, determines if the proposal passes, and evaluates the accuracy of submitted predictions.
     *      Callable by anyone after the voting period has ended.
     * @param _proposalId The ID of the proposal.
     */
    function tallyVotesAndEvaluatePredictions(uint256 _proposalId)
        external whenNotPaused onlyValidProposal(_proposalId)
    {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.creationEpoch < proposal.votingEndEpoch) revert VotingPeriodNotEnded(); // Can only tally after voting period
        if (proposal.executed) revert ProposalAlreadyExecuted(); // Already handled

        // Determine if proposal passed based on voting thresholds (e.g., > 50% majority)
        if (proposal.totalVotesFor > proposal.totalVotesAgainst) {
            proposal.passed = true;
        } else {
            proposal.passed = false;
        }

        // --- Prediction Evaluation (Simulated for complexity, real would use an oracle/system avg) ---
        uint256 totalPredictionDeviation = 0;
        uint256 predictionCount = 0;
        uint256 targetValue = proposal.passed ? proposal.newValue : getSystemParameter(proposal.paramId); // Evaluate against new value if passed, else current value

        for (uint256 i = 0; i < sbaTypes.length; i++) { // Iterate through all users with SBAs, find those who predicted
            // This is a simplified iteration. In a real system, you'd iterate through known predictors
            // or use an external helper. For this example, we assume we can directly access stored predictions.
            // This loop is purely illustrative and not truly efficient for a large number of predictors.
            // A mapping of (proposalId => address[] => predictedValue) would be better.
        }
        // Simplified prediction evaluation: For each user who predicted, calculate deviation from `targetValue`
        // (Assuming a way to iterate through proposal.predictions keys or retrieve them)
        // For demonstration, let's assume `avgPredictionDeviation` is simply set to a placeholder
        proposal.avgPredictionDeviation = 0; // Placeholder for actual calculation
        // --- End Prediction Evaluation ---

        emit ProposalEvaluated(
            _proposalId,
            proposal.passed,
            proposal.totalVotesFor,
            proposal.totalVotesAgainst,
            proposal.avgPredictionDeviation
        );
    }

    /**
     * @dev Executes a passed proposal, applying the proposed parameter change.
     *      Callable by anyone after the voting period, given the proposal passed.
     * @param _proposalId The ID of the proposal.
     */
    function executeProposal(uint256 _proposalId) external whenNotPaused onlyValidProposal(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.creationEpoch < proposal.votingEndEpoch) revert VotingPeriodNotEnded(); // Must be after voting
        if (proposal.executed) revert ProposalAlreadyExecuted();
        if (!proposal.passed) revert ProposalNotYetPassed();

        _systemParameters[proposal.paramId] = proposal.newValue;
        proposal.executed = true;
        emit ProposalExecuted(_proposalId, proposal.paramId, proposal.newValue);
    }

    // --- IV. Decentralized Task & Bounty System ---

    /**
     * @dev Creates a new task with a token reward and an SBA reward upon completion.
     *      Requires minimum reputation to create a task.
     * @param _title The title of the task.
     * @param _description A detailed description of the task.
     * @param _rewardAmount The amount of reward tokens for completing the task.
     * @param _requiredAttesterReputation The minimum reputation an attester needs to verify completion.
     * @param _sbaRewardTypeId The ID of the SBA type to be rewarded.
     * @param _sbaRewardAmount The amount of SBA to reward.
     * @param _attestationThreshold The number of attestations required for task completion.
     * @return The ID of the newly created task.
     */
    function createTask(
        string memory _title,
        string memory _description,
        uint256 _rewardAmount,
        uint256 _requiredAttesterReputation,
        uint256 _sbaRewardTypeId,
        uint256 _sbaRewardAmount,
        uint256 _attestationThreshold
    ) external whenNotPaused onlyValidSBA(_sbaRewardTypeId) returns (uint256) {
        if (bytes(_title).length == 0 || bytes(_description).length == 0) revert ZeroValueNotAllowed();
        if (_rewardAmount == 0 && _sbaRewardAmount == 0) revert InvalidAmount(); // Must have some reward
        if (_attestationThreshold == 0) revert InvalidThreshold();

        // Transfer reward tokens to the contract when creating the task
        if (_rewardAmount > 0) {
            if (!_rewardToken.transferFrom(msg.sender, address(this), _rewardAmount)) {
                revert InvalidAmount(); // Or more specific error like TransferFailed
            }
        }

        uint256 taskId = tasks.length;
        tasks.push(Task({
            title: _title,
            description: _description,
            rewardAmount: _rewardAmount,
            requiredAttesterReputation: _requiredAttesterReputation,
            sbaRewardTypeId: _sbaRewardTypeId,
            sbaRewardAmount: _sbaRewardAmount,
            attestationThreshold: _attestationThreshold,
            creationEpoch: _currentEpoch,
            hasSubmittedProof: new mapping(address => bool),
            attestations: new mapping(address => bool),
            verifiedCount: 0,
            applicant: address(0), // Set when someone submits completion
            completed: false,
            rewardsClaimed: false
        }));
        emit TaskCreated(taskId, msg.sender, _rewardAmount);
        return taskId;
    }

    /**
     * @dev A user submits a proof of task completion (e.g., an IPFS hash).
     *      Only one submission per task.
     * @param _taskId The ID of the task.
     * @param _proofCid An IPFS CID or similar identifier for the proof.
     */
    function submitTaskCompletion(uint256 _taskId, string memory _proofCid) external whenNotPaused onlyValidTask(_taskId) {
        Task storage task = tasks[_taskId];
        if (task.applicant != address(0)) revert TaskAlreadyCompleted(); // Task already submitted/assigned

        task.applicant = msg.sender;
        task.hasSubmittedProof[msg.sender] = true;
        emit TaskSubmitted(_taskId, msg.sender, _proofCid);
    }

    /**
     * @dev Qualified users can attest to the completion of a submitted task.
     *      Requires a minimum reputation to attest.
     * @param _taskId The ID of the task.
     * @param _applicant The address of the user who submitted the task for completion.
     * @param _isVerified True if the attester verifies the task, false to reject.
     */
    function attestTaskCompletion(uint256 _taskId, address _applicant, bool _isVerified)
        external whenNotPaused onlyValidTask(_taskId)
    {
        Task storage task = tasks[_taskId];
        if (task.applicant == address(0) || task.applicant != _applicant) revert TaskNotSubmitted();
        if (task.completed) revert TaskAlreadyCompleted();
        if (msg.sender == _applicant) revert Unauthorized(); // Applicant cannot attest their own work
        if (task.attestations[msg.sender]) revert AlreadyAttested();
        if (getOverallReputation(msg.sender) < task.requiredAttesterReputation) revert NotEnoughReputation();

        task.attestations[msg.sender] = true;
        if (_isVerified) {
            task.verifiedCount++;
        }
        emit TaskAttested(_taskId, msg.sender, _applicant, _isVerified);

        if (task.verifiedCount >= task.attestationThreshold) {
            task.completed = true;
        }
    }

    /**
     * @dev Allows the applicant to claim rewards (tokens and SBAs) once sufficient attestations are gathered.
     * @param _taskId The ID of the task.
     * @param _applicant The address of the applicant claiming rewards.
     */
    function claimTaskReward(uint256 _taskId, address _applicant) external whenNotPaused onlyValidTask(_taskId) {
        Task storage task = tasks[_taskId];
        if (msg.sender != _applicant) revert Unauthorized();
        if (task.applicant != _applicant) revert TaskNotSubmitted();
        if (!task.completed) revert NotEnoughAttestations();
        if (task.rewardsClaimed) revert TaskRewardAlreadyClaimed();

        // Transfer token reward
        if (task.rewardAmount > 0) {
            if (!_rewardToken.transfer(task.applicant, task.rewardAmount)) {
                revert InvalidAmount(); // Transfer failed
            }
        }

        // Mint SBA reward
        if (task.sbaRewardAmount > 0) {
            userSBAs[task.applicant][task.sbaRewardTypeId] += task.sbaRewardAmount;
        }

        task.rewardsClaimed = true;
        emit TaskRewardClaimed(_taskId, task.applicant, task.rewardAmount, task.sbaRewardAmount);
    }

    // --- V. Wisdom Pool (Prediction Markets) ---

    /**
     * @dev Creates a new market for a numerical prediction.
     * @param _question The question or event being predicted.
     * @param _resolutionEpoch The epoch at which the market can be resolved.
     * @param _oracleResolutionParamId An identifier for the actual value, could map to a system param or external data.
     * @return The ID of the newly created wisdom market.
     */
    function createWisdomPredictionMarket(
        string memory _question,
        uint256 _resolutionEpoch,
        uint256 _oracleResolutionParamId
    ) external whenNotPaused onlyOwner returns (uint256) {
        // Owner/Admin creates the prediction market, acting as a trusted entity for resolution details.
        if (bytes(_question).length == 0) revert ZeroValueNotAllowed();
        if (_resolutionEpoch <= _currentEpoch) revert InvalidEpochDuration(); // Resolution must be in the future

        uint256 marketId = wisdomMarkets.length;
        wisdomMarkets.push(WisdomMarket({
            question: _question,
            creationEpoch: _currentEpoch,
            resolutionEpoch: _resolutionEpoch,
            actualResolutionValue: 0,
            totalStaked: 0,
            stakes: new mapping(address => PredictionStake),
            resolved: false,
            oracleResolutionParamId: _oracleResolutionParamId
        }));
        emit WisdomMarketCreated(marketId, _question, _resolutionEpoch);
        return marketId;
    }

    /**
     * @dev Users stake tokens on their predicted value for a specific market.
     * @param _marketId The ID of the wisdom market.
     * @param _predictedValue The user's predicted numerical value.
     * @param _stakeAmount The amount of tokens to stake.
     */
    function stakePrediction(uint256 _marketId, uint256 _predictedValue, uint256 _stakeAmount)
        external payable whenNotPaused onlyValidWisdomMarket(_marketId)
    {
        WisdomMarket storage market = wisdomMarkets[_marketId];
        if (market.resolved) revert WisdomMarketAlreadyResolved();
        if (_currentEpoch >= market.resolutionEpoch) revert PredictionPeriodEnded(); // Staking period ended
        if (_stakeAmount == 0) revert InvalidAmount();

        // Transfer stake tokens to the contract (assuming Ether for simplicity here)
        // If using rewardToken, use _rewardToken.transferFrom(msg.sender, address(this), _stakeAmount);
        // For this example, assuming native token (Ether) is staked, thus `payable` keyword.
        if (msg.value != _stakeAmount) revert InvalidAmount();

        // Update or create stake
        PredictionStake storage userStake = market.stakes[msg.sender];
        if (userStake.amountStaked == 0) { // New prediction
            userStake.predictedValue = _predictedValue;
            userStake.amountStaked = _stakeAmount;
        } else { // Update existing prediction (add more stake, or change prediction entirely)
            // For simplicity, this example just adds to stake and averages predicted value
            userStake.predictedValue = ((userStake.predictedValue * userStake.amountStaked) + (_predictedValue * _stakeAmount)) / (userStake.amountStaked + _stakeAmount);
            userStake.amountStaked += _stakeAmount;
        }

        market.totalStaked += _stakeAmount;
        emit PredictionStaked(_marketId, msg.sender, _predictedValue, _stakeAmount);
    }

    /**
     * @dev Owner/Oracle resolves the market by providing the actual outcome value.
     * @param _marketId The ID of the wisdom market.
     * @param _actualValue The actual numerical outcome of the predicted event.
     */
    function resolveWisdomPredictionMarket(uint256 _marketId, uint256 _actualValue)
        external onlyOwner whenNotPaused onlyValidWisdomMarket(_marketId)
    {
        WisdomMarket storage market = wisdomMarkets[_marketId];
        if (market.resolved) revert WisdomMarketAlreadyResolved();
        if (_currentEpoch < market.resolutionEpoch) revert EpochStillActive(); // Cannot resolve before resolution epoch

        market.actualResolutionValue = _actualValue;
        market.resolved = true;
        emit WisdomMarketResolved(_marketId, _actualValue);
    }

    /**
     * @dev Allows accurate predictors to claim their proportional share of the staked pool.
     *      Payout is based on prediction accuracy (closer to actual value, higher payout).
     * @param _marketId The ID of the wisdom market.
     */
    function claimPredictionPayout(uint256 _marketId) external whenNotPaused onlyValidWisdomMarket(_marketId) {
        WisdomMarket storage market = wisdomMarkets[_marketId];
        if (!market.resolved) revert WisdomMarketNotResolved();

        PredictionStake storage userStake = market.stakes[msg.sender];
        if (userStake.amountStaked == 0) revert NothingToClaim();

        // Calculate payout based on accuracy. Simplified: closer predictions get more.
        // This can be a complex curve; for simplicity, let's say anyone within 10% deviation
        // gets a share proportional to their stake and inverse deviation.
        uint256 deviation = (userStake.predictedValue > market.actualResolutionValue)
            ? userStake.predictedValue - market.actualResolutionValue
            : market.actualResolutionValue - userStake.predictedValue;

        uint256 payout = 0;
        uint256 accuracyScore = 0; // Higher is better
        if (deviation <= 10 && market.actualResolutionValue > 0) { // Simple threshold for relevance
            // Example: (10 - deviation) * stake. A more robust formula needed for production.
            accuracyScore = (10 - deviation) * userStake.amountStaked;
        }

        // Aggregate total accuracy scores from all participants
        // (This would require iterating through all stakes, which is gas-intensive.
        // A real system would cache this or use a different payout model).
        uint256 totalAccuracyScoreInMarket = 0;
        // For demo, assume a simplified total for proportionality calculation.
        // In reality, this needs to be calculated by iterating through all entries in `market.stakes`
        // or by a separate function that aggregates this.
        // Let's assume a simplified scenario where the 'totalAccuracyScoreInMarket' is some derived value.
        // A robust solution needs to map all stakers. This is a common scalability challenge for prediction markets.
        // For this example, let's assume `totalAccuracyScoreInMarket` is known or derived for simplicity.
        // A placeholder for now.
        totalAccuracyScoreInMarket = market.totalStaked; // This is a very rough approximation, not true accuracy sum.

        if (totalAccuracyScoreInMarket > 0 && accuracyScore > 0) {
            payout = (market.totalStaked * accuracyScore) / totalAccuracyScoreInMarket;
        }

        // Ensure payout does not exceed user's stake plus a share of the profit.
        // This simple model allows for small gains based on closeness.
        // A more complex model would distribute the entire `market.totalStaked` among accurate predictors.
        if (payout > 0) {
            // Transfer native token (Ether) or reward token
            // If using Ether: (address(msg.sender)).transfer(payout);
            // If using reward token:
            if (!_rewardToken.transfer(msg.sender, payout)) {
                revert InvalidAmount(); // Transfer failed
            }
        }

        userStake.amountStaked = 0; // Mark as claimed
        emit PredictionPayoutClaimed(_marketId, msg.sender, payout);
    }

    // Fallback function for receiving Ether for staking
    receive() external payable {
        // Can be used for general Ether reception if not explicitly for staking
        // For staking, stakePrediction should handle msg.value.
        // This function would usually revert if no explicit handler for plain ETH transfer.
    }
}
```