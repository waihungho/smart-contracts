Okay, let's design a smart contract that isn't a standard token, NFT, or simple DAO. We'll create a system focused on on-chain reputation, prediction-like "Covenants," and collaborative "Challenges," with dynamic parameters adjusted through governance influenced by reputation.

This contract, let's call it "AetheriumWeave," tracks user "Resonance" (reputation). Users can propose and validate "Covenants" (predictions about future on-chain states or events) by staking Resonance or another token. Successful Covenants increase Resonance, failures decrease it. Users with sufficient Resonance can create or join "Challenges" (complex, multi-step collaborative tasks). The contract's core parameters can be adjusted via a governance mechanism weighted by Resonance. Resonance decays over time to incentivize participation.

**Concept:** A dynamic, self-adjusting protocol powered by decentralized prediction and collaboration, where on-chain reputation (Resonance) is key to participation and governance.

**Outline:**

1.  **Contract Definition:** SPDX License, Pragma, Imports (Ownable, ERC20 Interface).
2.  **Enums & Structs:** Define states for Covenants, Challenges, Parameter Proposals, Covenant types, and data structures for these concepts.
3.  **State Variables:** Storage for Resonance, Oracles, Weave Parameters, Covenants, Challenges, Proposals, etc.
4.  **Events:** Define events for key actions and state changes.
5.  **Modifiers:** Access control (`onlyOwner`, `onlyOracle`, etc.) and state checks.
6.  **Internal Functions:** Helpers for Resonance calculation (including decay) and state transitions.
7.  **Constructor:** Initialize owner, initial parameters, and stake token.
8.  **Admin/Configuration Functions:** Set oracles, adjust initial parameters (restricted), transfer ownership, set stake token.
9.  **Resonance Management Functions:** Get Resonance (applies decay), burn Resonance.
10. **Covenant Functions:** Propose, validate (by oracle), redeem stake, view details.
11. **Challenge Functions:** Create, join, leave, start, resolve, claim rewards, view details.
12. **Governance Functions:** Propose parameter changes, vote, execute changes, view proposals/parameters.
13. **Utility Functions:** Get total Resonance, get contract state summary.

**Function Summary:**

*   `constructor()`: Initializes the contract with the owner, initial weave parameters, and the ERC20 address used for staking (can be address(0) for ETH).
*   `setOwner(address newOwner)`: Transfers contract ownership. (From Ownable)
*   `setOracle(address oracle, bool approved)`: Adds or removes an address from the list of approved oracles.
*   `removeOracle(address oracle)`: Alias for `setOracle(oracle, false)`.
*   `setWeaveParameter(bytes32 key, uint256 value)`: Sets a specific weave parameter. Initially restricted to owner, potentially later via governance.
*   `setStakeToken(address tokenAddress)`: Sets the ERC20 token address used for staking Covenants. If `address(0)`, ETH is used.
*   `getResonance(address user)`: Returns the user's current Resonance score after applying time-based decay.
*   `getTotalResonanceSupply()`: Returns the sum of all users' Resonance (before decay calculation for individual access).
*   `burnResonance(uint256 amount)`: Allows a user to voluntarily burn some of their Resonance.
*   `proposeCovenant(uint8 covenantType, bytes data, uint256 stakeAmount, uint48 validationTimestamp, address oracleAddress)`: Allows a user to propose a Covenant, staking Resonance or the designated stake token.
*   `validateCovenant(uint256 covenantId, bool outcomeSuccess, bytes validationProof)`: Called by an approved oracle to validate the outcome of a Covenant.
*   `redeemCovenantStake(uint256 covenantId)`: Allows the Covenant creator to redeem their stake and claim rewards (Resonance or token) after validation.
*   `getCovenantDetails(uint256 covenantId)`: View function to get details of a specific Covenant.
*   `getUserCovenants(address user)`: View function to list Covenant IDs created by a user (might be limited for gas).
*   `createChallenge(string memory name, uint256 requiredResonance, uint256 maxParticipants, uint48 endTime, uint256 entranceStake, uint8 rewardType, uint256 rewardAmount)`: Allows a user with sufficient Resonance to propose a collaborative Challenge, defining its rules and rewards.
*   `joinChallenge(uint256 challengeId)`: Allows a user with sufficient Resonance to join a pending Challenge, paying the entrance stake.
*   `leaveChallenge(uint256 challengeId)`: Allows a participant to leave a pending Challenge, refunding stake.
*   `startChallenge(uint256 challengeId)`: Owner or automated process can start a challenge once participant requirements are met and time allows.
*   `resolveChallenge(uint256 challengeId, bool outcomeSuccess, bytes resolutionData)`: Owner or oracle resolves the outcome of an active Challenge.
*   `claimChallengeReward(uint256 challengeId)`: Allows participants of a successful Challenge to claim their rewards.
*   `getChallengeDetails(uint256 challengeId)`: View function to get details of a specific Challenge.
*   `getChallengeParticipants(uint256 challengeId)`: View function to get the list of participants for a Challenge (might be limited).
*   `proposeParameterChange(bytes32 parameterKey, uint256 newValue)`: Allows a user with high Resonance to propose changing a Weave parameter, initiating a voting period.
*   `voteOnParameterChange(bytes32 parameterKey, bool voteYes)`: Allows users with sufficient Resonance to vote on an active parameter change proposal.
*   `executeParameterChange(bytes32 parameterKey)`: Allows the owner or automated process to execute a parameter change if the proposal passed the vote.
*   `getParameterProposalDetails(bytes32 parameterKey)`: View function to get details of a parameter change proposal.
*   `getWeaveParameter(bytes32 key)`: View function to get the current value of a specific Weave parameter.
*   `getCurrentWeaveState()`: View function providing a summary of contract state (e.g., total Resonance, active challenges/covenants counts, key parameters).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/// @title AetheriumWeave - Protocol of Prophecy & Resonance
/// @author YourNameHere (Placeholder)
/// @notice A dynamic, reputation-based protocol where users earn Resonance by participating in Covenants (predictions) and Challenges (collaborative tasks). Core parameters evolve through Resonance-weighted governance. Resonance decays over time.
/// @dev This contract is a complex, conceptual example demonstrating multiple advanced features. It is NOT production-ready and requires significant auditing, gas optimization, and potentially off-chain components for oracle data and complex challenge resolution.

// --- Outline ---
// 1. Contract Definition & Imports
// 2. Enums & Structs
// 3. State Variables
// 4. Events
// 5. Modifiers
// 6. Internal Helper Functions
// 7. Constructor
// 8. Admin & Configuration Functions
// 9. Resonance Management Functions
// 10. Covenant Functions (Prediction Market elements)
// 11. Challenge Functions (Collaborative tasks)
// 12. Governance Functions (Parameter evolution)
// 13. Utility/View Functions

// --- Function Summary ---
// constructor(address initialStakeToken, uint256 initialResonanceDecayRate, uint256 initialResonanceDecayPeriod, uint256 initialCovenantResonanceStake)
// Admin/Configuration:
// - setOracle(address oracle, bool approved)
// - removeOracle(address oracle)
// - setWeaveParameter(bytes32 key, uint256 value)
// - setStakeToken(address tokenAddress)
// - renounceOwnership() (From Ownable)
// - transferOwnership(address newOwner) (From Ownable)
// Resonance Management:
// - getResonance(address user)
// - getTotalResonanceSupply()
// - burnResonance(uint256 amount)
// Covenant Functions:
// - proposeCovenant(uint8 covenantType, bytes data, uint256 stakeAmount, uint48 validationTimestamp, address oracleAddress)
// - validateCovenant(uint256 covenantId, bool outcomeSuccess, bytes validationProof) (Only Oracle)
// - redeemCovenantStake(uint256 covenantId)
// - getCovenantDetails(uint256 covenantId)
// - getUserCovenants(address user) (Limited view)
// Challenge Functions:
// - createChallenge(string memory name, uint256 requiredResonance, uint256 maxParticipants, uint48 endTime, uint256 entranceStake, uint8 rewardType, uint256 rewardAmount)
// - joinChallenge(uint256 challengeId)
// - leaveChallenge(uint256 challengeId)
// - startChallenge(uint256 challengeId) (Admin/Trigger)
// - resolveChallenge(uint256 challengeId, bool outcomeSuccess, bytes resolutionData) (Admin/Oracle/Trigger)
// - claimChallengeReward(uint256 challengeId)
// - getChallengeDetails(uint256 challengeId)
// - getChallengeParticipants(uint256 challengeId) (Limited view)
// Governance Functions:
// - proposeParameterChange(bytes32 parameterKey, uint256 newValue)
// - voteOnParameterChange(bytes32 parameterKey, bool voteYes)
// - executeParameterChange(bytes32 parameterKey) (Admin/Trigger)
// - getParameterProposalDetails(bytes32 parameterKey)
// - getWeaveParameter(bytes32 key)
// Utility/View:
// - getCurrentWeaveState()

contract AetheriumWeave is Ownable {
    using SafeMath for uint256;

    // --- 2. Enums & Structs ---

    enum CovenantState { Pending, Successful, Failed, Redeemed }
    enum ChallengeState { Proposed, Active, Successful, Failed, Claimed }
    enum ParameterProposalState { Voting, Approved, Rejected, Executed }

    // Defines the type of prediction a Covenant represents
    enum CovenantType {
        BoolOutcome, // Oracle validates a simple true/false outcome
        Uint256Outcome // Oracle validates a uint256 value outcome (e.g., token balance, block property)
        // Future types could involve more complex oracle data feeds or on-chain checks
    }

    struct Covenant {
        uint256 id;
        address creator;
        CovenantType covenantType;
        bytes predictionData; // Data specific to the prediction type (e.g., abi.encode(targetAddress, expectedValue))
        uint256 stakeAmount;
        address stakeAsset; // 0x0 for ETH, otherwise ERC20 address
        uint48 validationTimestamp; // Timestamp by which the outcome must be validated
        address oracleAddress; // The oracle responsible for validating this covenant
        CovenantState state;
        bool outcome; // True if validated as successful, false otherwise
        bytes validationProof; // Optional data provided by the oracle
    }

    struct Challenge {
        uint256 id;
        string name;
        address creator;
        uint256 requiredResonance; // Minimum Resonance required to join
        uint256 maxParticipants;
        address[] participants;
        mapping(address => bool) isParticipant; // Helper for quick lookup
        uint48 startTime; // When the challenge becomes Active
        uint48 endTime; // Deadline for resolution
        uint256 entranceStake; // Stake required to join (Resonance or StakeAsset)
        address stakeAsset; // 0x0 for Resonance, otherwise ERC20 address
        uint8 rewardType; // 0 for Resonance, 1 for StakeAsset
        uint256 rewardAmount; // Total reward pool
        ChallengeState state;
        bytes resolutionData; // Data provided upon resolution
    }

    struct ParameterProposal {
        bytes32 parameterKey;
        uint256 newValue;
        address proposer;
        uint48 votingEndTime;
        uint256 yesVotes; // Weighted by voter Resonance
        uint256 noVotes; // Weighted by voter Resonance
        mapping(address => bool) hasVoted;
        ParameterProposalState state;
    }

    // --- 3. State Variables ---

    mapping(address => uint256) private _resonance; // User's raw Resonance score
    mapping(address => uint48) private _lastResonanceUpdate; // Timestamp of last Resonance update
    uint256 private _totalResonance; // Track total raw resonance supply

    mapping(bytes32 => uint256) public weaveParameters; // Configurable parameters of the protocol
    // Parameter Keys (bytes32):
    // - keccak256("RESONANCE_DECAY_RATE"): Percentage (e.g., 1000 for 10%) of Resonance lost per decay period (scaled by 1e4)
    // - keccak256("RESONANCE_DECAY_PERIOD"): Time duration in seconds for the decay rate (e.g., 1 day, 1 week)
    // - keccak256("COVENANT_RESONANCE_STAKE_BASE"): Base Resonance required to propose a Covenant
    // - keccak256("COVENANT_SUCCESS_RESONANCE_BOOST"): Resonance gained on successful Covenant (percentage of stake, scaled by 1e4)
    // - keccak256("COVENANT_FAILURE_RESONANCE_PENALTY"): Resonance lost on failed Covenant (percentage of stake, scaled by 1e4)
    // - keccak256("CHALLENGE_CREATION_RESONANCE_MIN"): Minimum Resonance to create a Challenge
    // - keccak256("GOVERNANCE_PROPOSAL_RESONANCE_MIN"): Minimum Resonance to propose a parameter change
    // - keccak256("GOVERNANCE_VOTE_RESONANCE_MIN"): Minimum Resonance to vote on a proposal
    // - keccak256("GOVERNANCE_VOTING_PERIOD"): Duration of parameter proposal voting in seconds
    // - keccak256("GOVERNANCE_APPROVAL_THRESHOLD"): Percentage of total voting Resonance required for approval (scaled by 1e4)

    mapping(address => bool) public approvedOracles; // Addresses authorized to validate Covenants/Challenges

    mapping(uint256 => Covenant) public covenants;
    uint256 public nextCovenantId = 1;

    mapping(uint256 => Challenge) public challenges;
    uint256 public nextChallengeId = 1;

    mapping(bytes32 => ParameterProposal) public parameterProposals;
    // Note: Using parameterKey as the key for proposals. Only one proposal per key active at a time.

    address public stakeTokenAddress; // Address of the ERC20 token used for staking. address(0) means ETH.

    // --- 4. Events ---

    event ResonanceUpdated(address indexed user, uint256 oldResonance, uint256 newResonance, string reason);
    event TotalResonanceSupplyUpdated(uint256 newTotalSupply);
    event OracleStatusUpdated(address indexed oracle, bool approved);
    event WeaveParameterSet(bytes32 indexed key, uint256 value);
    event StakeTokenSet(address indexed tokenAddress);

    event CovenantProposed(uint256 indexed covenantId, address indexed creator, CovenantType covenantType, uint256 stakeAmount, address stakeAsset, uint48 validationTimestamp, address oracleAddress);
    event CovenantValidated(uint256 indexed covenantId, bool outcomeSuccess, bytes validationProof);
    event CovenantRedeemed(uint256 indexed covenantId, address indexed redeemer, uint256 resonanceGain, uint256 tokenReturned);

    event ChallengeProposed(uint256 indexed challengeId, address indexed creator, string name, uint256 requiredResonance, uint256 maxParticipants, uint48 endTime, uint256 entranceStake, address stakeAsset, uint8 rewardType, uint256 rewardAmount);
    event ChallengeJoined(uint256 indexed challengeId, address indexed participant);
    event ChallengeLeft(uint256 indexed challengeId, address indexed participant);
    event ChallengeStarted(uint256 indexed challengeId);
    event ChallengeResolved(uint256 indexed challengeId, bool outcomeSuccess, bytes resolutionData);
    event ChallengeRewardClaimed(uint256 indexed challengeId, address indexed participant, uint256 rewardAmount, uint8 rewardType);

    event ParameterChangeProposed(bytes32 indexed parameterKey, uint256 newValue, address indexed proposer, uint48 votingEndTime);
    event VoteCast(bytes32 indexed parameterKey, address indexed voter, bool voteYes, uint256 voteWeight);
    event ParameterChangeExecuted(bytes32 indexed parameterKey, uint256 newValue, bool executed);

    // --- 5. Modifiers ---

    modifier onlyOracle() {
        require(approvedOracles[msg.sender], "AetheriumWeave: Not an approved oracle");
        _;
    }

    modifier whenCovenantState(uint256 covenantId, CovenantState expectedState) {
        require(covenants[covenantId].state == expectedState, "AetheriumWeave: Covenant is not in the expected state");
        _;
    }

     modifier whenChallengeState(uint256 challengeId, ChallengeState expectedState) {
        require(challenges[challengeId].state == expectedState, "AetheriumWeave: Challenge is not in the expected state");
        _;
    }

    modifier whenParameterProposalState(bytes32 proposalKey, ParameterProposalState expectedState) {
        require(parameterProposals[proposalKey].state == expectedState, "AetheriumWeave: Proposal is not in the expected state");
        _;
    }

    // --- 6. Internal Helper Functions ---

    /// @dev Applies decay to a user's resonance based on elapsed time and global parameters.
    /// Updates the user's stored resonance and last update timestamp.
    /// @param user The address whose resonance to update.
    function _applyResonanceDecay(address user) internal {
        uint256 currentRawResonance = _resonance[user];
        if (currentRawResonance == 0) {
            _lastResonanceUpdate[user] = uint48(block.timestamp); // Reset timestamp if resonance is zero
            return;
        }

        uint48 lastUpdate = _lastResonanceUpdate[user];
        uint256 decayPeriod = weaveParameters[keccak256("RESONANCE_DECAY_PERIOD")];
        uint256 decayRate = weaveParameters[keccak256("RESONANCE_DECAY_RATE")]; // Scaled by 1e4

        if (decayPeriod == 0 || decayRate == 0) {
             _lastResonanceUpdate[user] = uint48(block.timestamp); // No decay, just update timestamp
            return;
        }

        uint256 timeElapsed = block.timestamp - lastUpdate;
        if (timeElapsed == 0) {
             return; // No time elapsed, no decay
        }

        // Calculate number of decay periods elapsed
        uint256 periodsElapsed = timeElapsed / decayPeriod;

        // Simple linear decay approximation for demonstration.
        // A more accurate decay would use exponents, but that's more complex/gas intensive.
        // Decay amount = raw_resonance * decay_rate * periods_elapsed / 1e4
        uint256 decayAmount = (currentRawResonance.mul(decayRate).mul(periodsElapsed)).div(10000); // decayRate is /1e4

        uint256 newRawResonance = currentRawResonance > decayAmount ? currentRawResonance - decayAmount : 0;

        if (newRawResonance != currentRawResonance) {
            emit ResonanceUpdated(user, currentRawResonance, newRawResonance, "decay");
            _totalResonance = _totalResonance - (currentRawResonance - newRawResonance); // Adjust total supply
            emit TotalResonanceSupplyUpdated(_totalResonance);
            _resonance[user] = newRawResonance;
        }
        _lastResonanceUpdate[user] = uint48(block.timestamp); // Update timestamp after decay
    }

    /// @dev Internal function to add or subtract raw Resonance, applying decay first.
    /// @param user The address whose resonance to update.
    /// @param amount The amount of resonance to add or subtract.
    /// @param add True to add, false to subtract.
    /// @param reason Descriptive string for the event log.
    function _updateResonance(address user, uint256 amount, bool add, string memory reason) internal {
        _applyResonanceDecay(user); // Apply decay before updating

        uint256 currentRawResonance = _resonance[user];
        uint256 newRawResonance;
        uint256 totalResonanceDiff = 0;

        if (add) {
            newRawResonance = currentRawResonance.add(amount);
             totalResonanceDiff = amount;
        } else {
             newRawResonance = currentRawResonance > amount ? currentRawResonance - amount : 0;
             totalResonanceDiff = currentRawResonance - newRawResonance; // Only subtract what was actually removed
        }

        if (newRawResonance != currentRawResonance) {
             emit ResonanceUpdated(user, currentRawResonance, newRawResonance, reason);
            if (add) {
                 _totalResonance = _totalResonance.add(totalResonanceDiff);
            } else {
                 _totalResonance = _totalResonance.sub(totalResonanceDiff);
            }
             emit TotalResonanceSupplyUpdated(_totalResonance);
             _resonance[user] = newRawResonance;
        }
        _lastResonanceUpdate[user] = uint48(block.timestamp); // Update timestamp after modification
    }

    // --- 7. Constructor ---

    constructor(address initialStakeToken, uint256 initialResonanceDecayRate, uint256 initialResonanceDecayPeriod, uint256 initialCovenantResonanceStake) Ownable(msg.sender) {
        stakeTokenAddress = initialStakeToken; // address(0) means ETH
        weaveParameters[keccak256("RESONANCE_DECAY_RATE")] = initialResonanceDecayRate; // e.g., 1000 for 10%
        weaveParameters[keccak256("RESONANCE_DECAY_PERIOD")] = initialResonanceDecayPeriod; // e.g., 1 days in seconds
        weaveParameters[keccak256("COVENANT_RESONANCE_STAKE_BASE")] = initialCovenantResonanceStake;
        weaveParameters[keccak256("COVENANT_SUCCESS_RESONANCE_BOOST")] = 2000; // 20% of stake added as Resonance
        weaveParameters[keccak256("COVENANT_FAILURE_RESONANCE_PENALTY")] = 3000; // 30% of stake subtracted as Resonance
        weaveParameters[keccak256("CHALLENGE_CREATION_RESONANCE_MIN")] = 1000; // Example minimum
        weaveParameters[keccak256("GOVERNANCE_PROPOSAL_RESONANCE_MIN")] = 5000; // Example minimum
        weaveParameters[keccak256("GOVERNANCE_VOTE_RESONANCE_MIN")] = 100; // Example minimum
        weaveParameters[keccak256("GOVERNANCE_VOTING_PERIOD")] = 7 days;
        weaveParameters[keccak256("GOVERNANCE_APPROVAL_THRESHOLD")] = 5000; // 50% approval (scaled by 1e4)

        // Initial Resonance for the owner for testing/setup
        _updateResonance(msg.sender, 10000, true, "initial_owner_provision");
    }

    // --- 8. Admin & Configuration Functions ---

    function setOracle(address oracle, bool approved) external onlyOwner {
        require(oracle != address(0), "AetheriumWeave: Invalid oracle address");
        approvedOracles[oracle] = approved;
        emit OracleStatusUpdated(oracle, approved);
    }

    function removeOracle(address oracle) external onlyOwner {
        setOracle(oracle, false);
    }

    /// @dev Allows setting weave parameters. Initially only owner, later could be governance-controlled.
    /// @param key The bytes32 key identifier for the parameter.
    /// @param value The new uint256 value for the parameter.
    function setWeaveParameter(bytes32 key, uint256 value) external onlyOwner {
         // Add checks here if certain parameters should only be changed via governance later
        weaveParameters[key] = value;
        emit WeaveParameterSet(key, value);
    }

    /// @dev Sets the address of the ERC20 token used for staking. Address(0) means ETH.
    /// @param tokenAddress The address of the ERC20 token.
    function setStakeToken(address tokenAddress) external onlyOwner {
        stakeTokenAddress = tokenAddress;
        emit StakeTokenSet(tokenAddress);
    }

    // renounceOwnership and transferOwnership are inherited from Ownable

    // --- 9. Resonance Management Functions ---

    /// @dev Returns the user's current Resonance score, applying decay if necessary.
    /// Note: This function modifies state (`_applyResonanceDecay`). It's okay for a read-heavy function if decay is part of the state update logic.
    /// If pure view is needed, decay calculation must be done without updating state.
    function getResonance(address user) public returns (uint256) {
        _applyResonanceDecay(user);
        return _resonance[user];
    }

     /// @dev Returns the total sum of raw Resonance scores across all users.
     /// Note: This requires careful maintenance in _updateResonance and potentially manual correction mechanisms in a real system.
     function getTotalResonanceSupply() external view returns (uint256) {
         return _totalResonance;
     }

    /// @dev Allows a user to voluntarily burn their Resonance.
    /// @param amount The amount of Resonance to burn.
    function burnResonance(uint256 amount) external {
        require(amount > 0, "AetheriumWeave: Cannot burn zero resonance");
        _applyResonanceDecay(msg.sender); // Apply decay before burning
        uint256 currentResonance = _resonance[msg.sender];
        require(currentResonance >= amount, "AetheriumWeave: Insufficient resonance");

        _updateResonance(msg.sender, amount, false, "burned");
    }


    // --- 10. Covenant Functions (Prediction Market elements) ---

    /// @dev Allows a user to propose a Covenant, staking Resonance or the stake token.
    /// @param covenantType The type of the Covenant prediction.
    /// @param data Data specific to the prediction type (e.g., abi.encode(targetAddress, expectedValue)).
    /// @param stakeAmount The amount of Resonance or stake token to stake.
    /// @param validationTimestamp The timestamp by which an oracle must validate the outcome.
    /// @param oracleAddress The address of the oracle responsible for validating this Covenant.
    function proposeCovenant(
        uint8 covenantType,
        bytes memory data,
        uint256 stakeAmount,
        uint48 validationTimestamp,
        address oracleAddress
    ) external payable {
        // Basic validation
        require(validationTimestamp > block.timestamp, "AetheriumWeave: Validation timestamp must be in the future");
        require(approvedOracles[oracleAddress], "AetheriumWeave: Oracle is not approved");
        require(stakeAmount > 0, "AetheriumWeave: Stake amount must be greater than zero");
        require(covenantType <= uint8(CovenantType.Uint256Outcome), "AetheriumWeave: Invalid covenant type");

        uint256 requiredResonanceStake = weaveParameters[keccak256("COVENANT_RESONANCE_STAKE_BASE")];
         _applyResonanceDecay(msg.sender); // Apply decay before checking/taking stake
         require(_resonance[msg.sender] >= requiredResonanceStake, "AetheriumWeave: Insufficient resonance to propose covenant");

        address assetToStake = stakeTokenAddress == address(0) ? address(this) : stakeTokenAddress; // Contract holds ETH or ERC20
        if (assetToStake == address(this)) { // ETH staking
            require(msg.value == stakeAmount, "AetheriumWeave: ETH stake amount must match msg.value");
        } else { // ERC20 staking
            require(msg.value == 0, "AetheriumWeave: Do not send ETH for ERC20 staking");
            IERC20 token = IERC20(assetToStake);
            // User must approve contract to transfer tokens beforehand
            require(token.transferFrom(msg.sender, address(this), stakeAmount), "AetheriumWeave: ERC20 transferFrom failed. Did you approve?");
        }

        uint256 cId = nextCovenantId++;
        covenants[cId] = Covenant({
            id: cId,
            creator: msg.sender,
            covenantType: CovenantType(covenantType),
            predictionData: data,
            stakeAmount: stakeAmount,
            stakeAsset: assetToStake,
            validationTimestamp: validationTimestamp,
            oracleAddress: oracleAddress,
            state: CovenantState.Pending,
            outcome: false, // Default, will be set by oracle
            validationProof: "" // Default
        });

        emit CovenantProposed(cId, msg.sender, CovenantType(covenantType), stakeAmount, assetToStake, validationTimestamp, oracleAddress);
    }

    /// @dev Called by the assigned oracle to validate the outcome of a Covenant.
    /// @param covenantId The ID of the Covenant to validate.
    /// @param outcomeSuccess The oracle's determination (true for successful prediction, false for failed).
    /// @param validationProof Optional data provided by the oracle to support validation.
    function validateCovenant(uint256 covenantId, bool outcomeSuccess, bytes memory validationProof) external onlyOracle whenCovenantState(covenantId, CovenantState.Pending) {
        Covenant storage covenant = covenants[covenantId];
        require(msg.sender == covenant.oracleAddress, "AetheriumWeave: Not the assigned oracle for this covenant");
        require(block.timestamp <= covenant.validationTimestamp, "AetheriumWeave: Validation timestamp has passed");

        covenant.state = outcomeSuccess ? CovenantState.Successful : CovenantState.Failed;
        covenant.outcome = outcomeSuccess;
        covenant.validationProof = validationProof;

        emit CovenantValidated(covenantId, outcomeSuccess, validationProof);
    }

    /// @dev Allows the Covenant creator to redeem their stake and claim rewards/penalties after validation.
    /// @param covenantId The ID of the Covenant to redeem.
    function redeemCovenantStake(uint256 covenantId) external whenCovenantState(covenantId, CovenantState.Successful) {
        Covenant storage covenant = covenants[covenantId];
        require(msg.sender == covenant.creator, "AetheriumWeave: Only the creator can redeem");
        require(block.timestamp > covenant.validationTimestamp || covenant.state != CovenantState.Pending, "AetheriumWeave: Covenant must be validated or expired");

        // Ensure it's not already redeemed (should be covered by state check, but belt-and-suspenders)
        require(covenant.state != CovenantState.Redeemed, "AetheriumWeave: Covenant already redeemed");

        uint256 resonanceChange = 0;
        uint256 tokenReturn = 0;

        if (covenant.state == CovenantState.Successful) {
            // Return stake + add resonance
            tokenReturn = covenant.stakeAmount;
            uint256 resonanceBoostPercentage = weaveParameters[keccak256("COVENANT_SUCCESS_RESONANCE_BOOST")]; // Scaled by 1e4
            resonanceChange = covenant.stakeAmount.mul(resonanceBoostPercentage).div(10000);
             _updateResonance(msg.sender, resonanceChange, true, "covenant_success");

        } else if (covenant.state == CovenantState.Failed) {
            // Lose stake + lose resonance
            tokenReturn = 0; // Stake is lost
            uint256 resonancePenaltyPercentage = weaveParameters[keccak256("COVENANT_FAILURE_RESONANCE_PENALTY")]; // Scaled by 1e4
            resonanceChange = covenant.stakeAmount.mul(resonancePenaltyPercentage).div(10000);
             _updateResonance(msg.sender, resonanceChange, false, "covenant_failure");

        } else if (covenant.state == CovenantState.Pending && block.timestamp > covenant.validationTimestamp) {
             // Oracle failed to validate in time - creator gets stake back, no resonance change
             tokenReturn = covenant.stakeAmount;
             resonanceChange = 0; // No change if oracle failed to validate in time
             // Note: A more complex system might penalize the oracle or allow others to validate after expiry
        } else {
            // This state should not be reachable if modifier and preceding checks are correct
            revert("AetheriumWeave: Covenant not in redeemable state");
        }

        // Transfer staked asset back to the creator
        if (tokenReturn > 0) {
            if (covenant.stakeAsset == address(this)) { // ETH
                 (bool success, ) = payable(covenant.creator).call{value: tokenReturn}("");
                 require(success, "AetheriumWeave: ETH transfer failed");
            } else { // ERC20
                 IERC20 token = IERC20(covenant.stakeAsset);
                 require(token.transfer(covenant.creator, tokenReturn), "AetheriumWeave: ERC20 transfer failed");
            }
        }

        covenant.state = CovenantState.Redeemed;
        emit CovenantRedeemed(covenantId, msg.sender, resonanceChange, tokenReturn);
    }

    /// @dev View function to get details of a specific Covenant.
    /// @param covenantId The ID of the Covenant.
    function getCovenantDetails(uint256 covenantId) external view returns (Covenant memory) {
        return covenants[covenantId];
    }

     /// @dev View function to get Covenant IDs created by a user. LIMITED for gas efficiency.
     /// Does not return full details, just the IDs. Iterating full structs could be too expensive.
     /// A real application would likely use off-chain indexing or a more complex linked list pattern on-chain.
     /// @param user The address of the user.
     /// @param startId The starting Covenant ID to check from.
     /// @param count The maximum number of Covenant IDs to return.
     /// @return An array of Covenant IDs created by the user within the range.
    function getUserCovenants(address user, uint256 startId, uint256 count) external view returns (uint256[] memory) {
         require(count <= 100, "AetheriumWeave: Count limit exceeded"); // Gas limit protection

         uint256[] memory userCovenantIds = new uint256[](count);
         uint256 foundCount = 0;
         uint256 currentId = startId > 0 ? startId : 1;

         while (foundCount < count && currentId < nextCovenantId) {
             // Check if covenant exists and belongs to user (might be sparse if covenants are deleted/removed)
             // This implementation is inefficient for sparse data. An indexed list would be better.
             // For this conceptual example, we iterate up to count or nextCovenantId.
             if (covenants[currentId].creator == user && covenants[currentId].id == currentId) { // Check id == currentId to see if struct is initialized
                 userCovenantIds[foundCount] = currentId;
                 foundCount++;
             }
             currentId++;
         }

         // Resize array to actual found count
         uint256[] memory result = new uint256[](foundCount);
         for (uint256 i = 0; i < foundCount; i++) {
             result[i] = userCovenantIds[i];
         }
         return result;
     }


    // --- 11. Challenge Functions (Collaborative tasks) ---

    /// @dev Allows a user with sufficient Resonance to propose a collaborative Challenge.
    /// @param name The name of the Challenge.
    /// @param requiredResonance Minimum Resonance required for participants.
    /// @param maxParticipants Maximum number of participants.
    /// @param endTime The deadline for the Challenge resolution.
    /// @param entranceStake Stake required to join (0 for no stake).
    /// @param rewardType 0 for Resonance, 1 for StakeAsset (must match global stakeTokenAddress).
    /// @param rewardAmount Total reward pool to be distributed among successful participants.
    function createChallenge(
        string memory name,
        uint256 requiredResonance,
        uint256 maxParticipants,
        uint48 endTime,
        uint256 entranceStake,
        uint8 rewardType, // 0: Resonance, 1: StakeAsset
        uint256 rewardAmount
    ) external payable {
        _applyResonanceDecay(msg.sender); // Apply decay before check
        require(_resonance[msg.sender] >= weaveParameters[keccak256("CHALLENGE_CREATION_RESONANCE_MIN")], "AetheriumWeave: Insufficient resonance to create challenge");
        require(endTime > block.timestamp, "AetheriumWeave: End time must be in the future");
        require(maxParticipants > 0, "AetheriumWeave: Must allow at least one participant");
        require(rewardType <= 1, "AetheriumWeave: Invalid reward type");
        require(rewardAmount > 0, "AetheriumWeave: Reward amount must be greater than zero");

        address assetToStake = address(0); // Default for Resonance stake
        if (entranceStake > 0) {
            assetToStake = stakeTokenAddress == address(0) ? address(this) : stakeTokenAddress;
            if (assetToStake == address(this)) { // ETH staking
                 require(msg.value == entranceStake, "AetheriumWeave: ETH stake amount must match msg.value");
            } else { // ERC20 staking
                 require(msg.value == 0, "AetheriumWeave: Do not send ETH for ERC20 staking");
                 IERC20 token = IERC20(assetToStake);
                 require(token.transferFrom(msg.sender, address(this), entranceStake), "AetheriumWeave: ERC20 transferFrom failed. Did you approve?");
            }
        } else {
             require(msg.value == 0, "AetheriumWeave: Do not send ETH if entranceStake is 0");
        }

        uint256 chId = nextChallengeId++;
        Challenge storage challenge = challenges[chId]; // Get storage reference

        challenge.id = chId;
        challenge.name = name;
        challenge.creator = msg.sender;
        challenge.requiredResonance = requiredResonance;
        challenge.maxParticipants = maxParticipants;
        // participants array starts empty
        // isParticipant mapping starts empty
        challenge.startTime = 0; // Set when started
        challenge.endTime = endTime;
        challenge.entranceStake = entranceStake;
        challenge.stakeAsset = assetToStake;
        challenge.rewardType = rewardType;
        challenge.rewardAmount = rewardAmount;
        challenge.state = ChallengeState.Proposed;
        // resolutionData starts empty

        emit ChallengeProposed(chId, msg.sender, name, requiredResonance, maxParticipants, endTime, entranceStake, assetToStake, rewardType, rewardAmount);
    }

    /// @dev Allows a user with sufficient Resonance to join a proposed Challenge.
    /// @param challengeId The ID of the Challenge to join.
    function joinChallenge(uint256 challengeId) external payable whenChallengeState(challengeId, ChallengeState.Proposed) {
        Challenge storage challenge = challenges[challengeId];
        _applyResonanceDecay(msg.sender); // Apply decay before check
        require(_resonance[msg.sender] >= challenge.requiredResonance, "AetheriumWeave: Insufficient resonance to join challenge");
        require(!challenge.isParticipant[msg.sender], "AetheriumWeave: Already a participant");
        require(challenge.participants.length < challenge.maxParticipants, "AetheriumWeave: Challenge is full");

        // Handle stake
        if (challenge.entranceStake > 0) {
             if (challenge.stakeAsset == address(this)) { // ETH staking
                 require(msg.value == challenge.entranceStake, "AetheriumWeave: ETH stake amount must match msg.value");
             } else { // ERC20 staking
                 require(msg.value == 0, "AetheriumWeave: Do not send ETH for ERC20 staking");
                 IERC20 token = IERC20(challenge.stakeAsset);
                 require(token.transferFrom(msg.sender, address(this), challenge.entranceStake), "AetheriumWeave: ERC20 transferFrom failed. Did you approve?");
             }
        } else {
            require(msg.value == 0, "AetheriumWeave: Do not send ETH if entranceStake is 0");
        }


        challenge.participants.push(msg.sender);
        challenge.isParticipant[msg.sender] = true;

        emit ChallengeJoined(challengeId, msg.sender);
    }

    /// @dev Allows a participant to leave a Proposed Challenge.
    /// @param challengeId The ID of the Challenge to leave.
    function leaveChallenge(uint256 challengeId) external whenChallengeState(challengeId, ChallengeState.Proposed) {
        Challenge storage challenge = challenges[challengeId];
        require(challenge.isParticipant[msg.sender], "AetheriumWeave: Not a participant");
        require(msg.sender != challenge.creator, "AetheriumWeave: Creator cannot leave a proposed challenge"); // Creator is responsible for initiating

        // Remove from participants array (simple approach, inefficient for large arrays)
        // In production, consider using a more complex data structure or marking as inactive.
        bool found = false;
        for (uint256 i = 0; i < challenge.participants.length; i++) {
            if (challenge.participants[i] == msg.sender) {
                // Swap with last element and pop
                challenge.participants[i] = challenge.participants[challenge.participants.length - 1];
                challenge.participants.pop();
                found = true;
                break;
            }
        }
        require(found, "AetheriumWeave: Participant not found in list (internal error)");

        challenge.isParticipant[msg.sender] = false;

        // Refund stake
        if (challenge.entranceStake > 0) {
             if (challenge.stakeAsset == address(this)) { // ETH
                 (bool success, ) = payable(msg.sender).call{value: challenge.entranceStake}("");
                 require(success, "AetheriumWeave: ETH refund failed");
             } else { // ERC20
                 IERC20 token = IERC20(challenge.stakeAsset);
                 require(token.transfer(msg.sender, challenge.entranceStake), "AetheriumWeave: ERC20 refund failed");
             }
        }

        emit ChallengeLeft(challengeId, msg.sender);
    }


    /// @dev Starts a Proposed Challenge. Can be called by owner or potentially automated.
    /// Add checks for minimum participants if needed.
    /// @param challengeId The ID of the Challenge to start.
    function startChallenge(uint256 challengeId) external onlyOwner whenChallengeState(challengeId, ChallengeState.Proposed) {
        Challenge storage challenge = challenges[challengeId];
        // Add requirement checks here, e.g., minimum participants reached
        // require(challenge.participants.length >= challenge.minParticipants, "AetheriumWeave: Not enough participants");

        challenge.state = ChallengeState.Active;
        challenge.startTime = uint48(block.timestamp);

        emit ChallengeStarted(challengeId);
    }

    /// @dev Resolves an Active Challenge as successful or failed.
    /// Can be called by owner, a designated oracle, or based on complex on-chain logic (simulated here).
    /// @param challengeId The ID of the Challenge to resolve.
    /// @param outcomeSuccess The resolution outcome (true for successful).
    /// @param resolutionData Optional data describing the resolution.
    function resolveChallenge(uint256 challengeId, bool outcomeSuccess, bytes memory resolutionData) external whenChallengeState(challengeId, ChallengeState.Active) {
        Challenge storage challenge = challenges[challengeId];
        // Require owner, oracle, or potentially complex condition evaluation
        require(msg.sender == owner() || approvedOracles[msg.sender] /* || checkComplexCondition(challenge) */, "AetheriumWeave: Unauthorized resolver");
        require(block.timestamp <= challenge.endTime, "AetheriumWeave: Resolution time has passed");

        challenge.state = outcomeSuccess ? ChallengeState.Successful : ChallengeState.Failed;
        challenge.resolutionData = resolutionData;

        // Stakes are kept by the contract for now, distributed/returned on claim
        emit ChallengeResolved(challengeId, outcomeSuccess, resolutionData);
    }

    /// @dev Allows participants of a Successful Challenge to claim their reward and get their stake back.
    /// Participants of a Failed Challenge lose their stake.
    /// @param challengeId The ID of the Challenge.
    function claimChallengeReward(uint256 challengeId) external whenChallengeState(challengeId, ChallengeState.Successful) {
        Challenge storage challenge = challenges[challengeId];
        require(challenge.isParticipant[msg.sender], "AetheriumWeave: Not a participant of this challenge");
        // Ensure participant hasn't already claimed - need a mapping for this
        // mapping(uint256 => mapping(address => bool)) private hasClaimedReward;
        // require(!hasClaimedReward[challengeId][msg.sender], "AetheriumWeave: Reward already claimed");

        // Simplified: Assume all participants get reward on success, lose stake on failure.
        // A real challenge might have specific success criteria per participant.

        uint256 rewardAmount = 0;
        uint256 stakeReturnAmount = 0;
        bool isSuccessful = (challenge.state == ChallengeState.Successful); // Check state again, although modifier helps

        if (isSuccessful) {
            // Calculate individual reward (simple: total reward / number of participants)
            // More complex: weighted by contribution, resonance, etc.
            uint256 totalParticipants = challenge.participants.length;
            if (totalParticipants > 0) {
                 rewardAmount = challenge.rewardAmount.div(totalParticipants);
            }
            stakeReturnAmount = challenge.entranceStake; // Stake is returned on success

            // Distribute Resonance reward if applicable
            if (challenge.rewardType == 0 && rewardAmount > 0) {
                 _updateResonance(msg.sender, rewardAmount, true, "challenge_success_reward");
            }

        } else { // State is Failed (participant loses stake)
            rewardAmount = 0;
            stakeReturnAmount = 0; // Stake is not returned
        }

        // Transfer token stake back if applicable
        if (stakeReturnAmount > 0 && challenge.entranceStake > 0) {
            if (challenge.stakeAsset == address(this)) { // ETH
                 (bool success, ) = payable(msg.sender).call{value: stakeReturnAmount}("");
                 require(success, "AetheriumWeave: ETH stake return failed");
            } else { // ERC20
                 IERC20 token = IERC20(challenge.stakeAsset);
                 require(token.transfer(msg.sender, stakeReturnAmount), "AetheriumWeave: ERC20 stake return failed");
            }
        }

        // Transfer token reward if applicable
        if (isSuccessful && challenge.rewardType == 1 && rewardAmount > 0) {
             if (challenge.stakeAsset == address(this)) { // ETH
                 (bool success, ) = payable(msg.sender).call{value: rewardAmount}("");
                 require(success, "AetheriumWeave: ETH reward failed");
             } else { // ERC20
                 IERC20 token = IERC20(challenge.stakeAsset);
                 require(token.transfer(msg.sender, rewardAmount), "AetheriumWeave: ERC20 reward failed");
             }
        }

        // Mark user as claimed (requires added state)
        // hasClaimedReward[challengeId][msg.sender] = true;

        // If all participants have claimed, potentially change challenge state to Claimed
        // This requires tracking claimed participants count or iterating (expensive)

        emit ChallengeRewardClaimed(challengeId, msg.sender, rewardAmount, challenge.rewardType);
    }


    /// @dev View function to get details of a specific Challenge.
    /// @param challengeId The ID of the Challenge.
    function getChallengeDetails(uint256 challengeId) external view returns (Challenge memory) {
        // Note: This returns a copy. Modifications require storage reference.
        // Also, participants list in memory copy might be large.
        return challenges[challengeId];
    }

     /// @dev View function to get participants of a Challenge. LIMITED for gas.
     /// @param challengeId The ID of the Challenge.
     /// @return An array of participant addresses.
    function getChallengeParticipants(uint256 challengeId) external view returns (address[] memory) {
         // Return participants array. Be mindful of gas for very large arrays.
         return challenges[challengeId].participants;
     }


    // --- 12. Governance Functions (Parameter evolution) ---

    /// @dev Allows a user with high Resonance to propose changing a Weave parameter.
    /// Only one proposal per parameter key can be active (Voting) at a time.
    /// @param parameterKey The key of the parameter to change.
    /// @param newValue The new value for the parameter.
    function proposeParameterChange(bytes32 parameterKey, uint256 newValue) external {
        _applyResonanceDecay(msg.sender); // Apply decay before check
        require(_resonance[msg.sender] >= weaveParameters[keccak256("GOVERNANCE_PROPOSAL_RESONANCE_MIN")], "AetheriumWeave: Insufficient resonance to propose parameter change");
        require(parameterProposals[parameterKey].state != ParameterProposalState.Voting, "AetheriumWeave: A proposal for this parameter is already under voting");

        ParameterProposal storage proposal = parameterProposals[parameterKey];

        proposal.parameterKey = parameterKey;
        proposal.newValue = newValue;
        proposal.proposer = msg.sender;
        proposal.votingEndTime = uint48(block.timestamp + weaveParameters[keccak256("GOVERNANCE_VOTING_PERIOD")]);
        proposal.yesVotes = 0;
        proposal.noVotes = 0;
        // hasVoted mapping is reset per proposal key
        proposal.state = ParameterProposalState.Voting;

        emit ParameterChangeProposed(parameterKey, newValue, msg.sender, proposal.votingEndTime);
    }

    /// @dev Allows users with sufficient Resonance to vote on an active parameter change proposal.
    /// Vote weight is the user's current Resonance (after decay).
    /// @param parameterKey The key of the parameter proposal to vote on.
    /// @param voteYes True for Yes, False for No.
    function voteOnParameterChange(bytes32 parameterKey, bool voteYes) external whenParameterProposalState(parameterKey, ParameterProposalState.Voting) {
        ParameterProposal storage proposal = parameterProposals[parameterKey];
        require(block.timestamp <= proposal.votingEndTime, "AetheriumWeave: Voting period has ended");

        _applyResonanceDecay(msg.sender); // Apply decay before using resonance as vote weight
        uint256 voterResonance = _resonance[msg.sender];
        require(voterResonance >= weaveParameters[keccak256("GOVERNANCE_VOTE_RESONANCE_MIN")], "AetheriumWeave: Insufficient resonance to vote");
        require(!proposal.hasVoted[msg.sender], "AetheriumWeave: Already voted on this proposal");

        proposal.hasVoted[msg.sender] = true;
        if (voteYes) {
            proposal.yesVotes = proposal.yesVotes.add(voterResonance);
        } else {
            proposal.noVotes = proposal.noVotes.add(voterResonance);
        }

        emit VoteCast(parameterKey, msg.sender, voteYes, voterResonance);
    }

    /// @dev Executes a parameter change if the voting period has ended and the proposal passed.
    /// Can be called by owner or automated.
    /// @param parameterKey The key of the parameter proposal to execute.
    function executeParameterChange(bytes32 parameterKey) external whenParameterProposalState(parameterKey, ParameterProposalState.Voting) {
        ParameterProposal storage proposal = parameterProposals[parameterKey];
        require(block.timestamp > proposal.votingEndTime, "AetheriumWeave: Voting period is not over");

        uint256 totalVotes = proposal.yesVotes.add(proposal.noVotes);
        // Avoid division by zero if no one voted
        bool passed = false;
        if (totalVotes > 0) {
            uint256 approvalThreshold = weaveParameters[keccak256("GOVERNANCE_APPROVAL_THRESHOLD")]; // Scaled by 1e4
            passed = proposal.yesVotes.mul(10000).div(totalVotes) >= approvalThreshold;
        }

        if (passed) {
            weaveParameters[parameterKey] = proposal.newValue;
            proposal.state = ParameterProposalState.Executed;
            emit ParameterChangeExecuted(parameterKey, proposal.newValue, true);
        } else {
            proposal.state = ParameterProposalState.Rejected;
             // The proposal is rejected, parameter remains unchanged
             emit ParameterChangeExecuted(parameterKey, proposal.newValue, false);
        }
    }

    /// @dev View function to get details of a parameter change proposal.
    /// @param parameterKey The key of the proposal.
    function getParameterProposalDetails(bytes32 parameterKey) external view returns (ParameterProposal memory) {
        return parameterProposals[parameterKey];
    }

    /// @dev View function to get the current value of a Weave parameter.
    /// @param key The bytes32 key identifier for the parameter.
    function getWeaveParameter(bytes32 key) external view returns (uint256) {
        return weaveParameters[key];
    }

    // --- 13. Utility/View Functions ---

     /// @dev View function to get the address of the stake token (address(0) for ETH).
     function getStakeTokenAsset() external view returns (address) {
         return stakeTokenAddress;
     }

     /// @dev View function providing a summary of key contract state.
     function getCurrentWeaveState() external view returns (
         uint256 totalResonanceSupply,
         uint256 pendingCovenants,
         uint256 activeChallenges,
         uint256 votingProposalsCount,
         uint256 resonanceDecayRate,
         uint256 resonanceDecayPeriod,
         address currentStakeToken
     ) {
         uint256 _pendingCovenants = 0;
         uint256 _activeChallenges = 0;
         uint256 _votingProposalsCount = 0;

         // Iterating mappings is expensive; in a real app, counts would be maintained state variables.
         // This is a simplified example iteration.
         // for (uint256 i = 1; i < nextCovenantId; i++) { if (covenants[i].state == CovenantState.Pending) _pendingCovenants++; }
         // for (uint256 i = 1; i < nextChallengeId; i++) { if (challenges[i].state == ChallengeState.Active) _activeChallenges++; }
         // Iterating through all possible parameter keys is not feasible. Assuming a known set.
         // bytes32[] memory knownParamsWithProposals; // Need a way to track this or iterate keys

         // For this example, we'll return the count vars as placeholders or simplify.
         // Let's return key state variables directly for simplicity, skipping iteration.
         return (
             _totalResonance, // Note: This is raw total, not sum of decayed
             nextCovenantId - 1, // Approximation: total covenants created
             nextChallengeId - 1, // Approximation: total challenges created
             0, // Placeholder: Cannot iterate proposals mapping cheaply
             weaveParameters[keccak256("RESONANCE_DECAY_RATE")],
             weaveParameters[keccak256("RESONANCE_DECAY_PERIOD")],
             stakeTokenAddress
         );
     }

    // Fallback function to receive ETH when stakeTokenAddress is address(0)
    receive() external payable {}

    // Allow owner to withdraw any accidentally sent ETH not intended for staking
    // Or withdrawn stakes/failed challenge stakes
    function withdrawETH(uint256 amount) external onlyOwner {
        require(address(this).balance >= amount, "AetheriumWeave: Insufficient balance");
        (bool success, ) = payable(owner()).call{value: amount}("");
        require(success, "AetheriumWeave: ETH withdrawal failed");
    }

    // Allow owner to withdraw any accidentally sent ERC20s not intended for staking
    // Or withdrawn stakes/failed challenge stakes
    function withdrawERC20(address tokenAddress, uint256 amount) external onlyOwner {
        require(tokenAddress != address(0), "AetheriumWeave: Cannot withdraw ETH with this function");
        IERC20 token = IERC20(tokenAddress);
        require(token.balanceOf(address(this)) >= amount, "AetheriumWeave: Insufficient token balance");
        require(token.transfer(owner(), amount), "AetheriumWeave: ERC20 withdrawal failed");
    }
}
```