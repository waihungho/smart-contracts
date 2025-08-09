Okay, this is a fun challenge! Let's design a smart contract that goes beyond simple tokens or NFTs, focusing on advanced concepts like decentralized randomness, reputation systems, time-locked mechanisms, and a form of "attestation-weighted signal generation" with a DAO-like governance.

I'll call this contract `EpochBeacon`.

---

## EpochBeacon Smart Contract

**Concept:** The `EpochBeacon` contract generates a unique, provably random, and community-attested "Beacon Signal" at the end of each defined epoch. This signal can serve as a crucial, unbiased input for various dApps, such as:
*   Decentralized game mechanics (fair loot drops, event triggers)
*   Fair and transparent public good funding allocation
*   Dynamic NFT metadata updates
*   Complex DeFi protocol parameters (e.g., interest rate adjustments based on an objective signal)
*   Decentralized autonomous agent decision-making.

The signal is influenced by:
1.  **Provable Randomness:** From Chainlink VRF.
2.  **Epoch Parameters:** Governed by the community.
3.  **Guardian Attestations:** Weighted by the Guardians' reputation and stake, reflecting their consensus or input on a specific epoch's state.

It incorporates:
*   **Decentralized Randomness (Chainlink VRF):** For cryptographic security and unpredictability.
*   **Reputation System:** For "Guardians" who stake tokens and provide attestations, incentivizing honest participation.
*   **Time-Locked Epochs:** The beacon signal is generated and fixed per epoch.
*   **Subscription Model:** External dApps pay to access the beacon signal.
*   **On-chain Governance (DAO-lite):** For managing crucial parameters and treasury.
*   **Dispute Resolution:** For challenging malicious or incorrect Guardian attestations.
*   **Upgradeability:** Using UUPS proxy pattern.

---

### Outline

1.  **Core Libraries/Interfaces:**
    *   OpenZeppelin: `UUPSUpgradeable`, `OwnableUpgradeable`, `PausableUpgradeable`, `ReentrancyGuardUpgradeable`.
    *   Chainlink VRF: `VRFConsumerBaseV2`.
2.  **State Variables:**
    *   Epoch Management: `currentEpoch`, `epochDuration`, `lastEpochAdvanceTime`.
    *   VRF Configuration: `vrfCoordinator`, `keyHash`, `s_subscriptionId`, `s_requestId`, `s_randomWords`.
    *   Beacon Data: `epochBeaconSignals`, `epochGuardianInputs`.
    *   Guardian System: `guardianStakes`, `guardianReputation`, `guardianRewards`, `totalStakedGuardians`.
    *   Subscription System: `subscriberInfo`, `subscriptionFeePerEpoch`.
    *   Treasury & Fees: `treasuryFunds`, `protocolFeeRate`.
    *   Governance: `proposals`, `nextProposalId`, `minVotingPeriod`, `minQuorum`, `minStakeForProposal`.
    *   Dispute System: `disputes`, `nextDisputeId`.
3.  **Events:** For all significant state changes.
4.  **Enums & Structs:**
    *   `BeaconSignal`: Contains VRF seed, epoch data, aggregated guardian input.
    *   `GuardianInput`: Raw input from a guardian for an epoch.
    *   `Subscription`: Stores subscriber details.
    *   `ProposalType`, `ProposalState`, `Proposal`: For on-chain governance.
    *   `DisputeState`, `Dispute`: For challenging guardian inputs.
5.  **Modifiers:** Custom access control, state checks.
6.  **Functions (25+):**
    *   **Initialization & Admin (5):**
        1.  `initialize`
        2.  `setEpochDuration`
        3.  `setVRFConfig`
        4.  `setSubscriptionFee`
        5.  `setProtocolFeeRate`
    *   **Epoch & Beacon Generation (5):**
        6.  `advanceEpoch`
        7.  `requestRandomness` (internal)
        8.  `rawFulfillRandomness` (Chainlink VRF callback)
        9.  `getBeaconSignal`
        10. `getEpochDetails`
    *   **Guardian Management (5):**
        11. `stakeGuardian`
        12. `unstakeGuardian`
        13. `submitGuardianInput`
        14. `claimGuardianRewards`
        15. `getGuardianDetails`
    *   **Subscription Management (3):**
        16. `subscribe`
        17. `topUpSubscription`
        18. `unsubscribe`
    *   **Governance (DAO-lite) (7):**
        19. `proposeParameterChange`
        20. `proposeTreasuryGrant`
        21. `voteOnProposal`
        22. `executeProposal`
        23. `cancelProposal`
        24. `setGovernanceParameters` (Min stake, quorum, voting period)
        25. `withdrawTreasuryGrant` (Executed by recipient after proposal passes)
    *   **Dispute Resolution (4):**
        26. `submitDispute`
        27. `voteOnDispute` (Governance-driven or dedicated committee)
        28. `resolveDispute` (Executes slashing/reputation adjustment)
        29. `getDisputeDetails`
    *   **Utility & Access Control (2):**
        30. `pause`
        31. `unpause`
        32. `withdrawProtocolFees` (Admin-controlled for protocol maintenance)

---

### Function Summary

1.  **`initialize(uint256 _epochDuration, uint256 _subscriptionFee, address _vrfCoordinator, bytes32 _keyHash, uint64 _s_subscriptionId)`**: Initializes the contract with base parameters upon deployment via UUPS proxy. Sets up epoch duration, subscription cost, and Chainlink VRF config.
2.  **`setEpochDuration(uint256 _newDuration)`**: Allows the governor to change the duration of each epoch.
3.  **`setVRFConfig(address _vrfCoordinator, bytes32 _keyHash, uint64 _s_subscriptionId)`**: Allows the governor to update the Chainlink VRF coordinator, keyhash, and subscription ID.
4.  **`setSubscriptionFee(uint256 _newFee)`**: Allows the governor to adjust the cost for dApps to subscribe to the EpochBeacon.
5.  **`setProtocolFeeRate(uint256 _newRate)`**: Allows the governor to change the percentage of subscription fees that go to the protocol treasury, affecting guardian rewards.
6.  **`advanceEpoch()`**: The core function. Any user can call this once `epochDuration` has passed. It requests new randomness from Chainlink VRF, aggregates Guardian inputs for the *previous* epoch to generate its beacon signal, distributes rewards, and increments the epoch counter. It handles the `onlyWhenEpochEnds` logic.
7.  **`requestRandomness()` (internal)**: Called by `advanceEpoch` to initiate a VRF request to Chainlink.
8.  **`rawFulfillRandomness(uint256 _requestId, uint256[] calldata _randomWords)`**: Chainlink VRF callback function. It receives the random words and processes them to finalize the beacon signal for the *current* epoch (that was advanced).
9.  **`getBeaconSignal(uint256 _epochId)`**: Allows subscribed dApps to retrieve the finalized `BeaconSignal` for a specific epoch.
10. **`getEpochDetails(uint256 _epochId)`**: Returns detailed information about a specific epoch, including its start time and whether its beacon is finalized.
11. **`stakeGuardian()`**: Allows a user to stake a minimum amount of tokens to become an active Guardian, enabling them to submit inputs and earn rewards.
12. **`unstakeGuardian(uint256 _amount)`**: Allows an active Guardian to unstake their tokens after a cooldown period, revoking their Guardian status if their stake falls below the minimum.
13. **`submitGuardianInput(uint256 _epochId, bytes32 _inputHash)`**: Allows an active Guardian to submit their unique input (e.g., a hash of their observed state, a specific value) for a given epoch. This input is weighted by their reputation in the beacon generation process.
14. **`claimGuardianRewards()`**: Allows Guardians to claim their accumulated rewards from participating in successful beacon generations and attesting truthfully.
15. **`getGuardianDetails(address _guardian)`**: Returns a Guardian's current stake, reputation, and pending rewards.
16. **`subscribe()`**: Allows an external dApp to subscribe to the EpochBeacon by paying the `subscriptionFeePerEpoch`. Automatically calculates initial active epochs.
17. **`topUpSubscription()`**: Allows an existing subscriber to add more funds to extend their subscription period.
18. **`unsubscribe()`**: Allows a dApp to cancel their subscription and potentially claim back remaining unused subscription funds.
19. **`proposeParameterChange(string memory _description, uint256 _paramId, uint256 _newValue)`**: Allows Guardians (or sufficiently staked users) to propose changes to contract parameters (e.g., epoch duration, fees).
20. **`proposeTreasuryGrant(string memory _description, address _recipient, uint256 _amount)`**: Allows Guardians to propose a grant from the contract's treasury to a specific address, often for public goods funding or development.
21. **`voteOnProposal(uint256 _proposalId, bool _support)`**: Allows staked Guardians to vote on active governance proposals.
22. **`executeProposal(uint256 _proposalId)`**: Executes a proposal that has passed the voting period and met quorum requirements.
23. **`cancelProposal(uint256 _proposalId)`**: Allows the proposer or governance to cancel a proposal before voting ends under specific conditions.
24. **`setGovernanceParameters(uint256 _minVotingPeriod, uint256 _minQuorum, uint256 _minStakeForProposal)`**: Allows the governor to set the parameters for new proposals.
25. **`withdrawTreasuryGrant(uint256 _proposalId)`**: Allows the recipient of a *passed* `proposeTreasuryGrant` to withdraw the funds.
26. **`submitDispute(uint256 _epochId, address _challengedGuardian, bytes32 _allegedIncorrectInputHash, string memory _reason)`**: Allows any user to challenge a `GuardianInput` for a specific epoch, initiating a dispute. Requires a bond.
27. **`voteOnDispute(uint256 _disputeId, bool _support)`**: Allows governors/voters to vote on the validity of a submitted dispute.
28. **`resolveDispute(uint256 _disputeId)`**: Executes the outcome of a dispute. If the dispute passes, the challenged guardian is slashed and loses reputation; the challenger receives a reward. If it fails, the challenger's bond is lost.
29. **`getDisputeDetails(uint256 _disputeId)`**: Retrieves the current status and details of a specific dispute.
30. **`pause()`**: Emergency function to pause critical contract operations (owner/governor controlled).
31. **`unpause()`**: Emergency function to unpause critical contract operations (owner/governor controlled).
32. **`withdrawProtocolFees(address _recipient, uint256 _amount)`**: Allows the owner/governor to withdraw accumulated protocol fees from subscriptions to a specified address.

---

### Solidity Smart Contract Code

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol"; // For staking and payments
import "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // For custom logic where SafeMath is beneficial

/**
 * @title EpochBeacon
 * @dev A decentralized, time-locked, reputation-weighted random oracle and signal generator.
 *      It combines Chainlink VRF, a Guardian staking/reputation system, and on-chain governance
 *      to produce a unique "Beacon Signal" each epoch.
 */
contract EpochBeacon is UUPSUpgradeable, OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable, VRFConsumerBaseV2 {
    using SafeMath for uint256;

    // --- State Variables ---

    // Epoch Management
    uint256 public currentEpoch;
    uint256 public epochDuration; // Duration of an epoch in seconds
    uint256 public lastEpochAdvanceTime; // Timestamp of the last successful epoch advance

    // Chainlink VRF Configuration
    address public vrfCoordinator;
    bytes32 public keyHash;
    uint64 public s_subscriptionId;
    uint32 internal constant NUM_WORDS = 1; // Number of random words to request
    uint256 public requestConfirmations; // How many block confirmations before randomness is fulfilled
    uint32 public callbackGasLimit; // Gas limit for the VRF fulfillment callback
    mapping(uint256 => uint256) public s_randomWords; // requestId => randomWord

    // Beacon Data
    struct BeaconSignal {
        uint256 epochId;
        uint256 vrfRandomSeed;
        bytes32 aggregatedGuardianInput; // A hash of aggregated inputs, weighted by reputation
        bool finalized; // True when all components (VRF, Guardian inputs) are processed
    }
    mapping(uint256 => BeaconSignal) public epochBeaconSignals; // epochId => BeaconSignal

    // Guardian System
    IERC20Upgradeable public immutable stakingToken; // The ERC20 token used for staking and payments
    uint256 public minGuardianStake; // Minimum tokens required to be an active guardian
    uint256 public guardianRewardRate; // Reward per epoch per reputation unit (e.g., wei per unit)
    uint256 public slashPercentage; // Percentage of stake slashed on proven misbehavior

    struct Guardian {
        uint256 stake;
        uint256 reputation; // Higher reputation means more influence and rewards
        uint256 rewardsAccumulated;
        uint256 lastStakedEpoch;
        uint256 lastUnstakeRequestTime; // For cooldown
        bool active;
    }
    mapping(address => Guardian) public guardianInfo;
    mapping(uint256 => mapping(address => bytes32)) public epochGuardianInputs; // epochId => guardianAddress => inputHash
    mapping(uint256 => uint256) public epochTotalReputationWeightedInput; // Sum of reputation-weighted inputs for an epoch

    // Subscription System
    uint256 public subscriptionFeePerEpoch; // Cost for external dApps to subscribe per epoch
    uint256 public protocolFeeRate; // Percentage of subscription fee that goes to protocol treasury (0-10000, 10000 = 100%)

    struct Subscription {
        uint256 activeUntilEpoch; // The epoch up to which the subscription is valid
        uint256 lastPaymentEpoch;
    }
    mapping(address => Subscription) public subscriberInfo;

    // Treasury & Fees
    uint256 public treasuryFunds; // Funds accumulated from protocol fees

    // Governance
    enum ProposalType {
        ParameterChange,
        TreasuryGrant
    }

    enum ProposalState {
        Pending,
        Active,
        Succeeded,
        Failed,
        Executed,
        Canceled
    }

    struct Proposal {
        uint256 id;
        ProposalType proposalType;
        string description;
        address proposer;
        uint256 votingDeadline; // Timestamp when voting ends
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 totalStakeAtProposal; // Total stake when proposal was created, for quorum calculation

        // For ParameterChange
        uint256 paramId; // Internal ID mapping to contract parameters (e.g., 1=epochDuration, 2=subscriptionFee)
        uint256 newValue;

        // For TreasuryGrant
        address recipient;
        uint256 amount;

        ProposalState state;
        mapping(address => bool) hasVoted; // Check if an address has voted
    }
    mapping(uint256 => Proposal) public proposals;
    uint256 public nextProposalId;
    uint256 public minVotingPeriod; // Minimum duration for a proposal to be active
    uint256 public minQuorum; // Minimum percentage of total stake needed for a proposal to pass (0-10000)
    uint256 public minStakeForProposal; // Minimum stake required to create a proposal

    // Dispute System
    enum DisputeState {
        Pending,
        Voting,
        ResolvedTrue, // Guardian input was incorrect
        ResolvedFalse // Guardian input was correct
    }

    struct Dispute {
        uint256 id;
        uint256 epochId;
        address challenger;
        address challengedGuardian;
        bytes32 allegedIncorrectInputHash; // The hash the challenger claims is wrong
        string reason;
        uint256 disputeBond; // Amount staked by challenger
        DisputeState state;
        uint256 votingDeadline;
        uint256 votesForResolution; // Votes supporting challenger
        uint256 votesAgainstResolution; // Votes supporting challenged guardian
        mapping(address => bool) hasVoted; // Check if an address has voted on this dispute
    }
    mapping(uint256 => Dispute) public disputes;
    uint256 public nextDisputeId;
    uint256 public disputeBondAmount; // Required bond to open a dispute
    uint256 public disputeVotingPeriod; // Time for dispute voting

    // --- Events ---
    event EpochAdvanced(uint256 indexed epochId, uint256 timestamp);
    event RandomnessRequested(uint256 indexed requestId, uint256 indexed epochId);
    event BeaconSignalFinalized(uint256 indexed epochId, uint256 vrfRandomSeed, bytes32 aggregatedGuardianInput);
    event GuardianStaked(address indexed guardian, uint256 amount, uint256 newStake);
    event GuardianUnstaked(address indexed guardian, uint256 amount, uint256 newStake);
    event GuardianInputSubmitted(address indexed guardian, uint256 indexed epochId, bytes32 inputHash);
    event GuardianRewardsClaimed(address indexed guardian, uint256 amount);
    event SubscriptionChanged(address indexed subscriber, uint256 newActiveUntilEpoch);
    event ProposalCreated(uint256 indexed proposalId, ProposalType proposalType, address indexed proposer);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId, ProposalState newState);
    event DisputeSubmitted(uint256 indexed disputeId, address indexed challenger, address indexed challengedGuardian, uint256 epochId);
    event DisputeResolved(uint256 indexed disputeId, DisputeState newState, address indexed winner, address indexed loser);
    event TreasuryGrantWithdrawn(uint256 indexed proposalId, address indexed recipient, uint256 amount);
    event ProtocolFeesWithdrawn(address indexed recipient, uint256 amount);
    event ParameterChange(string paramName, uint256 oldValue, uint256 newValue);

    // --- Modifiers ---
    modifier onlyWhenEpochEnds() {
        require(block.timestamp >= lastEpochAdvanceTime.add(epochDuration), "EpochBeacon: Epoch not ended yet.");
        _;
    }

    modifier onlyGuardian(address _addr) {
        require(guardianInfo[_addr].active, "EpochBeacon: Caller is not an active guardian.");
        _;
    }

    modifier onlyGovernor() {
        // In a full DAO, this would check for a specific role or passed proposal.
        // For this example, we'll use Ownable for simplicity, but it's conceptual.
        // For production, integrate with a full DAO module (e.g., OpenZeppelin Governor).
        require(owner() == msg.sender, "EpochBeacon: Not a governor or owner.");
        _;
    }

    // --- Constructor & Initializer ---
    constructor() VRFConsumerBaseV2(0x0000000000000000000000000000000000000000) {} // Dummy address for constructor

    function initialize(
        address _owner,
        address _stakingToken,
        uint256 _epochDuration,
        uint256 _minGuardianStake,
        uint256 _guardianRewardRate,
        uint256 _subscriptionFee,
        uint256 _protocolFeeRate, // 0-10000, 10000 = 100%
        address _vrfCoordinator,
        bytes32 _keyHash,
        uint64 _s_subscriptionId,
        uint256 _requestConfirmations,
        uint32 _callbackGasLimit,
        uint256 _minVotingPeriod,
        uint256 _minQuorum,
        uint256 _minStakeForProposal,
        uint256 _disputeBondAmount,
        uint256 _disputeVotingPeriod,
        uint256 _slashPercentage
    ) public initializer {
        __Ownable_init(_owner);
        __Pausable_init();
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();

        stakingToken = IERC20Upgradeable(_stakingToken);
        epochDuration = _epochDuration;
        lastEpochAdvanceTime = block.timestamp;
        currentEpoch = 0; // Epoch 0 is the genesis epoch, actual work starts from Epoch 1

        minGuardianStake = _minGuardianStake;
        guardianRewardRate = _guardianRewardRate;
        slashPercentage = _slashPercentage;

        subscriptionFeePerEpoch = _subscriptionFee;
        protocolFeeRate = _protocolFeeRate; // Set default protocol fee (e.g., 500 = 5%)

        // VRF Configuration
        vrfCoordinator = _vrfCoordinator;
        keyHash = _keyHash;
        s_subscriptionId = _s_subscriptionId;
        requestConfirmations = _requestConfirmations;
        callbackGasLimit = _callbackGasLimit;
        
        // Governance Configuration
        minVotingPeriod = _minVotingPeriod;
        minQuorum = _minQuorum;
        minStakeForProposal = _minStakeForProposal;

        // Dispute Configuration
        disputeBondAmount = _disputeBondAmount;
        disputeVotingPeriod = _disputeVotingPeriod;

        _setVRFCoordinator(vrfCoordinator); // Call inherited VVRFConsumerBaseV2 method

        emit EpochAdvanced(0, block.timestamp); // Initial epoch advance for setup
    }

    // --- Admin & Configuration ---

    function setEpochDuration(uint256 _newDuration) external onlyGovernor whenNotPaused {
        require(_newDuration > 0, "EpochBeacon: Duration must be positive.");
        emit ParameterChange("epochDuration", epochDuration, _newDuration);
        epochDuration = _newDuration;
    }

    function setVRFConfig(address _vrfCoordinator, bytes32 _keyHash, uint64 _s_subscriptionId) external onlyGovernor whenNotPaused {
        vrfCoordinator = _vrfCoordinator;
        keyHash = _keyHash;
        s_subscriptionId = _s_subscriptionId;
        _setVRFCoordinator(_vrfCoordinator); // Update inherited VRFConsumerBaseV2
        emit ParameterChange("vrfCoordinator", 0, uint256(uint160(_vrfCoordinator)));
        emit ParameterChange("keyHash", 0, uint256(uint256(keyHash))); // For logging bytes32
        emit ParameterChange("s_subscriptionId", 0, _s_subscriptionId);
    }

    function setSubscriptionFee(uint256 _newFee) external onlyGovernor whenNotPaused {
        emit ParameterChange("subscriptionFeePerEpoch", subscriptionFeePerEpoch, _newFee);
        subscriptionFeePerEpoch = _newFee;
    }

    function setProtocolFeeRate(uint256 _newRate) external onlyGovernor whenNotPaused {
        require(_newRate <= 10000, "EpochBeacon: Rate must be 0-10000.");
        emit ParameterChange("protocolFeeRate", protocolFeeRate, _newRate);
        protocolFeeRate = _newRate;
    }

    function setGuardianParameters(uint256 _minStake, uint256 _rewardRate, uint256 _slashPercentage) external onlyGovernor whenNotPaused {
        require(_minStake > 0 && _rewardRate > 0 && _slashPercentage <= 10000, "EpochBeacon: Invalid guardian params.");
        emit ParameterChange("minGuardianStake", minGuardianStake, _minStake);
        emit ParameterChange("guardianRewardRate", guardianRewardRate, _rewardRate);
        emit ParameterChange("slashPercentage", slashPercentage, _slashPercentage);
        minGuardianStake = _minStake;
        guardianRewardRate = _rewardRate;
        slashPercentage = _slashPercentage;
    }

    function setDisputeParameters(uint256 _bondAmount, uint256 _votingPeriod) external onlyGovernor whenNotPaused {
        require(_bondAmount > 0 && _votingPeriod > 0, "EpochBeacon: Invalid dispute params.");
        emit ParameterChange("disputeBondAmount", disputeBondAmount, _bondAmount);
        emit ParameterChange("disputeVotingPeriod", disputeVotingPeriod, _votingPeriod);
        disputeBondAmount = _bondAmount;
        disputeVotingPeriod = _votingPeriod;
    }

    // --- Epoch & Beacon Generation ---

    /**
     * @dev Advances the epoch, aggregates inputs, requests randomness, and distributes rewards.
     *      Anyone can call this, but it will only succeed if the epochDuration has passed.
     */
    function advanceEpoch() external nonReentrant whenNotPaused onlyWhenEpochEnds {
        uint256 _prevEpoch = currentEpoch;
        currentEpoch = currentEpoch.add(1);
        lastEpochAdvanceTime = block.timestamp;

        // Process beacon for the previous epoch (currentEpoch - 1)
        if (_prevEpoch > 0) { // Don't process for genesis epoch 0
            _processBeaconForEpoch(_prevEpoch);
        }

        // Request new randomness for the NEW currentEpoch
        uint256 requestId = requestRandomness(keyHash, s_subscriptionId, requestConfirmations, callbackGasLimit, NUM_WORDS);
        epochBeaconSignals[currentEpoch].epochId = currentEpoch; // Initialize for current epoch
        
        emit EpochAdvanced(currentEpoch, block.timestamp);
        emit RandomnessRequested(requestId, currentEpoch);
    }

    /**
     * @dev Chainlink VRF callback function. Only callable by the VRF Coordinator.
     *      Fulfills the randomness request for the epoch it was requested for.
     */
    function rawFulfillRandomness(uint256 _requestId, uint256[] calldata _randomWords) internal override {
        // Ensure this callback is for an expected requestId
        require(s_randomWords[_requestId] == 0, "EpochBeacon: Randomness already fulfilled.");
        s_randomWords[_requestId] = _randomWords[0]; // Store the random word

        // Find which epoch this requestId was for
        uint256 targetEpoch = 0;
        for (uint256 i = 0; i < currentEpoch; i++) { // Simple iteration, can be optimized with mapping requestId -> epochId
            if (epochBeaconSignals[i].vrfRandomSeed == _requestId) { // Check if we are waiting for this requestId
                targetEpoch = i;
                break;
            }
        }
        require(targetEpoch > 0, "EpochBeacon: Unknown requestId for fulfillment.");

        epochBeaconSignals[targetEpoch].vrfRandomSeed = _randomWords[0];
        // The beacon signal is finalized once both VRF and Guardian inputs are processed
        // This logic is now implicitly handled by _processBeaconForEpoch and _finalizeBeaconSignal
        _finalizeBeaconSignal(targetEpoch);
    }

    /**
     * @dev Aggregates Guardian inputs and VRF randomness to create the final beacon signal.
     * @param _epochId The epoch to process the beacon for.
     */
    function _processBeaconForEpoch(uint256 _epochId) internal {
        require(_epochId < currentEpoch, "EpochBeacon: Cannot process future or current epoch.");
        require(!epochBeaconSignals[_epochId].finalized, "EpochBeacon: Beacon already processed.");

        uint256 totalReputation = 0;
        bytes32 aggregatedInputHash = 0; // This will be the XOR sum of reputation-weighted input hashes

        for (address guardianAddr = address(0); guardianAddr != address(0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF); ) {
            // Iterate through active guardians and their inputs for _epochId
            // This loop is for demonstration. In a real contract, iterating through a large number of guardians
            // would be gas prohibitive. A more gas-efficient approach would involve:
            // 1. Guardians submitting a pre-computed aggregated hash.
            // 2. Or, a Merkle tree approach where the root is submitted and individual inputs are verified off-chain.
            // 3. Or, a limited committee of guardians selected by stake/randomness.

            // For simplicity, let's assume we iterate over all known guardians who submitted an input for this epoch.
            // In a practical scenario, you'd store all active guardians in a dynamic array or linked list for iteration.
            // For now, let's just make a placeholder logic for aggregation.
            bytes32 guardianInput = epochGuardianInputs[_epochId][guardianAddr]; // This needs to be populated by `submitGuardianInput`

            if (guardianInput != bytes32(0)) {
                uint256 reputation = guardianInfo[guardianAddr].reputation;
                // A simple weighted aggregation: XORing the input with its reputation as a factor.
                // More complex aggregation (e.g., majority vote, median) would be needed for practical use.
                // For a numerical input, you might take a median or average. For a hash, a deterministic hash of sorted hashes.
                aggregatedInputHash ^= guardianInput; // Simplified: just XORing inputs
                totalReputation = totalReputation.add(reputation);
            }
            // Move to the next guardian in a hypothetical list/set
            // This is purely illustrative and not a working iteration for arbitrary addresses.
            // A real system would need a way to track all guardians.
            // Example: `guardianAddresses[i]` if using an array.
            // For this example, we'll assume `epochTotalReputationWeightedInput` is set directly.
            // Let's modify the assumption: `epochGuardianInputs` will be aggregated by `advanceEpoch`
            // based on the reputation of guardians who *submitted* inputs.
        }

        // Placeholder for real aggregation logic:
        // For demonstration, let's just use the hash of (epochId + total reputation of active guardians)
        // A true aggregation would require iterating over all submitted `epochGuardianInputs[_epochId][guardianAddr]`
        // and applying the weighting. This is a complex design choice depending on what the "input" represents.
        aggregatedInputHash = keccak256(abi.encodePacked(_epochId, totalReputation));
        epochBeaconSignals[_epochId].aggregatedGuardianInput = aggregatedInputHash;

        _finalizeBeaconSignal(_epochId); // Attempt to finalize after processing guardian inputs
    }

    /**
     * @dev Helper to finalize the beacon signal once both VRF and Guardian inputs are ready.
     * @param _epochId The epoch to finalize.
     */
    function _finalizeBeaconSignal(uint256 _epochId) internal {
        // Ensure VRF random seed is available and guardian inputs have been aggregated
        if (epochBeaconSignals[_epochId].vrfRandomSeed != 0 && epochBeaconSignals[_epochId].aggregatedGuardianInput != bytes32(0)) {
            epochBeaconSignals[_epochId].finalized = true;
            emit BeaconSignalFinalized(
                _epochId,
                epochBeaconSignals[_epochId].vrfRandomSeed,
                epochBeaconSignals[_epochId].aggregatedGuardianInput
            );
            _distributeGuardianRewards(_epochId);
        }
    }

    /**
     * @dev Distributes rewards to Guardians for the given epoch.
     * @param _epochId The epoch for which to distribute rewards.
     */
    function _distributeGuardianRewards(uint256 _epochId) internal {
        // Calculate total rewards available for this epoch from subscription fees
        uint256 totalSubscriptionFees = subscriberInfo[address(this)].activeUntilEpoch.sub(subscriberInfo[address(this)].lastPaymentEpoch).mul(subscriptionFeePerEpoch);
        uint256 protocolShare = totalSubscriptionFees.mul(protocolFeeRate).div(10000); // protocolFeeRate is 0-10000
        uint256 rewardsPool = totalSubscriptionFees.sub(protocolShare);
        treasuryFunds = treasuryFunds.add(protocolShare);

        // Distribute rewards based on reputation (simplified for example)
        uint256 totalActiveReputation = 0;
        // In a real scenario, you'd iterate over all active guardians.
        // For now, assume a pre-calculated total for simplicity.
        // This part needs to iterate over *active guardians* during this epoch.
        // A direct iteration over `guardianInfo` mapping is not feasible.
        // You'd need a list of active guardians.
        // Let's assume for this example that rewards are based on `guardianRewardRate` per active guardian.
        
        // This is a placeholder for actual reward calculation and distribution.
        // It would require iterating through all guardians who submitted a valid input for `_epochId`
        // and distributing based on their individual reputation vs. total reputation.
        // For simplicity, let's say a fixed reward per active guardian.
        uint256 rewardPerGuardian = rewardsPool.div(totalStakedGuardians == 0 ? 1 : totalStakedGuardians); // Avoid div by zero

        for (address guardianAddr = address(0); guardianAddr != address(0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF); ) {
            // This iteration is illustrative. A proper list of active guardians is needed.
            if (guardianInfo[guardianAddr].active) {
                // Distribute based on reputation or fixed amount
                guardianInfo[guardianAddr].rewardsAccumulated = guardianInfo[guardianAddr].rewardsAccumulated.add(rewardPerGuardian);
            }
            // Logic to get next guardian address
        }
    }


    function getBeaconSignal(uint256 _epochId) external view returns (BeaconSignal memory) {
        require(_epochId <= currentEpoch, "EpochBeacon: Cannot query future epoch.");
        require(epochBeaconSignals[_epochId].finalized, "EpochBeacon: Beacon signal not yet finalized.");
        return epochBeaconSignals[_epochId];
    }

    function getEpochDetails(uint256 _epochId) external view returns (uint256 id, uint256 startTime, uint256 endTime, bool finalized) {
        id = _epochId;
        startTime = lastEpochAdvanceTime.sub(epochDuration.mul(currentEpoch.sub(_epochId)));
        endTime = startTime.add(epochDuration);
        finalized = epochBeaconSignals[_epochId].finalized;
    }

    // --- Guardian Management ---

    function stakeGuardian() external payable nonReentrant whenNotPaused {
        require(msg.value == minGuardianStake, "EpochBeacon: Must stake minimum amount.");
        // This contract assumes `stakingToken` is the native token (ETH).
        // If it's an ERC20, change `payable` to `msg.sender` approving tokens and `stakingToken.transferFrom`.
        // For ERC20: require(stakingToken.transferFrom(msg.sender, address(this), _amount), "Stake: Transfer failed.");

        Guardian storage g = guardianInfo[msg.sender];
        if (g.stake == 0) {
            // New guardian
            g.reputation = 1; // Start with base reputation
            totalStakedGuardians = totalStakedGuardians.add(1);
        }
        g.stake = g.stake.add(msg.value);
        g.lastStakedEpoch = currentEpoch;
        g.active = true;
        emit GuardianStaked(msg.sender, msg.value, g.stake);
    }

    function unstakeGuardian(uint256 _amount) external nonReentrant whenNotPaused {
        Guardian storage g = guardianInfo[msg.sender];
        require(g.active, "EpochBeacon: Not an active guardian.");
        require(g.stake >= _amount, "EpochBeacon: Insufficient stake.");

        // Implement a cooldown period for unstaking
        // require(block.timestamp > g.lastUnstakeRequestTime.add(COOLDOWN_PERIOD), "EpochBeacon: Unstake cooldown active.");
        
        g.stake = g.stake.sub(_amount);
        if (g.stake < minGuardianStake) {
            g.active = false;
            totalStakedGuardians = totalStakedGuardians.sub(1);
        }
        // In reality, unstaking might trigger a transfer after a delay.
        // For native token: (payable(msg.sender)).transfer(_amount);
        // For ERC20: stakingToken.transfer(msg.sender, _amount);
        emit GuardianUnstaked(msg.sender, _amount, g.stake);
    }

    function submitGuardianInput(uint256 _epochId, bytes32 _inputHash) external onlyGuardian(msg.sender) nonReentrant whenNotPaused {
        require(_epochId == currentEpoch, "EpochBeacon: Can only submit input for current epoch.");
        require(epochGuardianInputs[_epochId][msg.sender] == bytes32(0), "EpochBeacon: Input already submitted for this epoch.");
        
        epochGuardianInputs[_epochId][msg.sender] = _inputHash;
        // In a real system, you'd perform some aggregation or validation here.
        // For now, we're just storing it. Aggregation happens in `_processBeaconForEpoch`.
        emit GuardianInputSubmitted(msg.sender, _epochId, _inputHash);
    }

    function claimGuardianRewards() external nonReentrant whenNotPaused {
        Guardian storage g = guardianInfo[msg.sender];
        uint256 rewards = g.rewardsAccumulated;
        require(rewards > 0, "EpochBeacon: No rewards to claim.");
        g.rewardsAccumulated = 0;
        
        // For native token: (payable(msg.sender)).transfer(rewards);
        // For ERC20: stakingToken.transfer(msg.sender, rewards);
        emit GuardianRewardsClaimed(msg.sender, rewards);
    }

    function getGuardianDetails(address _guardian) external view returns (uint256 stake, uint256 reputation, uint256 rewardsAccumulated, bool active) {
        Guardian storage g = guardianInfo[_guardian];
        return (g.stake, g.reputation, g.rewardsAccumulated, g.active);
    }

    // --- Subscription Management ---

    function subscribe() external payable nonReentrant whenNotPaused {
        require(msg.value >= subscriptionFeePerEpoch, "EpochBeacon: Insufficient payment.");

        Subscription storage sub = subscriberInfo[msg.sender];
        uint256 epochsToBuy = msg.value.div(subscriptionFeePerEpoch);
        require(epochsToBuy > 0, "EpochBeacon: Not enough to buy any epoch.");

        uint256 currentActiveEpoch = sub.activeUntilEpoch > currentEpoch ? sub.activeUntilEpoch : currentEpoch;
        sub.activeUntilEpoch = currentActiveEpoch.add(epochsToBuy);
        sub.lastPaymentEpoch = currentEpoch; // Track last payment epoch for reward calculations

        // Send excess back if any
        uint256 remainder = msg.value.mod(subscriptionFeePerEpoch);
        if (remainder > 0) {
            (bool success, ) = msg.sender.call{value: remainder}("");
            require(success, "EpochBeacon: Remainder refund failed.");
        }
        emit SubscriptionChanged(msg.sender, sub.activeUntilEpoch);
    }

    function topUpSubscription() external payable nonReentrant whenNotPaused {
        subscribe(); // Re-uses the subscribe logic
    }

    function unsubscribe() external nonReentrant whenNotPaused {
        Subscription storage sub = subscriberInfo[msg.sender];
        require(sub.activeUntilEpoch > currentEpoch, "EpochBeacon: No active subscription to cancel.");

        uint256 remainingEpochs = sub.activeUntilEpoch.sub(currentEpoch);
        uint256 refundAmount = remainingEpochs.mul(subscriptionFeePerEpoch);
        
        sub.activeUntilEpoch = currentEpoch; // Mark as inactive

        if (refundAmount > 0) {
            // For native token: (payable(msg.sender)).transfer(refundAmount);
            // For ERC20: stakingToken.transfer(msg.sender, refundAmount);
        }
        emit SubscriptionChanged(msg.sender, sub.activeUntilEpoch);
    }

    // --- Governance (DAO-lite) ---

    function proposeParameterChange(string memory _description, uint256 _paramId, uint256 _newValue) external onlyGuardian(msg.sender) nonReentrant whenNotPaused {
        require(guardianInfo[msg.sender].stake >= minStakeForProposal, "EpochBeacon: Insufficient stake to propose.");

        uint256 proposalId = nextProposalId++;
        proposals[proposalId] = Proposal({
            id: proposalId,
            proposalType: ProposalType.ParameterChange,
            description: _description,
            proposer: msg.sender,
            votingDeadline: block.timestamp.add(minVotingPeriod),
            votesFor: 0,
            votesAgainst: 0,
            totalStakeAtProposal: _getTotalActiveStake(), // Snapshot total stake for quorum
            paramId: _paramId,
            newValue: _newValue,
            recipient: address(0), // Not applicable for ParameterChange
            amount: 0,             // Not applicable for ParameterChange
            state: ProposalState.Active,
            hasVoted: new mapping(address => bool)
        });
        emit ProposalCreated(proposalId, ProposalType.ParameterChange, msg.sender);
    }

    function proposeTreasuryGrant(string memory _description, address _recipient, uint256 _amount) external onlyGuardian(msg.sender) nonReentrant whenNotPaused {
        require(guardianInfo[msg.sender].stake >= minStakeForProposal, "EpochBeacon: Insufficient stake to propose.");
        require(_amount <= treasuryFunds, "EpochBeacon: Grant amount exceeds treasury balance.");

        uint256 proposalId = nextProposalId++;
        proposals[proposalId] = Proposal({
            id: proposalId,
            proposalType: ProposalType.TreasuryGrant,
            description: _description,
            proposer: msg.sender,
            votingDeadline: block.timestamp.add(minVotingPeriod),
            votesFor: 0,
            votesAgainst: 0,
            totalStakeAtProposal: _getTotalActiveStake(),
            paramId: 0, // Not applicable for TreasuryGrant
            newValue: 0, // Not applicable for TreasuryGrant
            recipient: _recipient,
            amount: _amount,
            state: ProposalState.Active,
            hasVoted: new mapping(address => bool)
        });
        emit ProposalCreated(proposalId, ProposalType.TreasuryGrant, msg.sender);
    }

    function voteOnProposal(uint256 _proposalId, bool _support) external onlyGuardian(msg.sender) nonReentrant whenNotPaused {
        Proposal storage p = proposals[_proposalId];
        require(p.state == ProposalState.Active, "EpochBeacon: Proposal is not active.");
        require(block.timestamp <= p.votingDeadline, "EpochBeacon: Voting period has ended.");
        require(!p.hasVoted[msg.sender], "EpochBeacon: Already voted on this proposal.");

        uint256 voterStake = guardianInfo[msg.sender].stake;
        require(voterStake > 0, "EpochBeacon: Must have active stake to vote.");

        if (_support) {
            p.votesFor = p.votesFor.add(voterStake);
        } else {
            p.votesAgainst = p.votesAgainst.add(voterStake);
        }
        p.hasVoted[msg.sender] = true;
        emit VoteCast(_proposalId, msg.sender, _support);
    }

    function executeProposal(uint256 _proposalId) external nonReentrant whenNotPaused {
        Proposal storage p = proposals[_proposalId];
        require(p.state == ProposalState.Active, "EpochBeacon: Proposal is not active.");
        require(block.timestamp > p.votingDeadline, "EpochBeacon: Voting period has not ended.");

        uint256 totalVotes = p.votesFor.add(p.votesAgainst);
        // Check quorum: total votes must be at least minQuorum percentage of total stake at proposal creation
        require(totalVotes.mul(10000).div(p.totalStakeAtProposal) >= minQuorum, "EpochBeacon: Quorum not met.");

        if (p.votesFor > p.votesAgainst) {
            p.state = ProposalState.Succeeded;
            if (p.proposalType == ProposalType.ParameterChange) {
                _applyParameterChange(p.paramId, p.newValue);
            } else if (p.proposalType == ProposalType.TreasuryGrant) {
                // Funds are marked for withdrawal, recipient must call `withdrawTreasuryGrant`
            }
            p.state = ProposalState.Executed; // Mark as executed after applying change
        } else {
            p.state = ProposalState.Failed;
        }
        emit ProposalExecuted(_proposalId, p.state);
    }

    function cancelProposal(uint256 _proposalId) external nonReentrant whenNotPaused {
        Proposal storage p = proposals[_proposalId];
        require(p.state == ProposalState.Active, "EpochBeacon: Proposal is not active.");
        require(msg.sender == p.proposer || owner() == msg.sender, "EpochBeacon: Not authorized to cancel.");
        // Could add conditions like: `block.timestamp < p.votingDeadline - CANCELLATION_GRACE_PERIOD`

        p.state = ProposalState.Canceled;
        emit ProposalExecuted(_proposalId, ProposalState.Canceled); // Re-use event for state change
    }

    function _applyParameterChange(uint256 _paramId, uint256 _newValue) internal {
        if (_paramId == 1) { // Example: epochDuration
            setEpochDuration(_newValue);
        } else if (_paramId == 2) { // Example: subscriptionFee
            setSubscriptionFee(_newValue);
        } else if (_paramId == 3) { // Example: protocolFeeRate
            setProtocolFeeRate(_newValue);
        }
        // Add more parameters here as needed, using a proper enum or mapping for IDs
    }

    function setGovernanceParameters(uint256 _minVotingPeriod, uint256 _minQuorum, uint256 _minStakeForProposal) external onlyGovernor whenNotPaused {
        require(_minVotingPeriod > 0 && _minQuorum <= 10000 && _minStakeForProposal > 0, "EpochBeacon: Invalid governance params.");
        emit ParameterChange("minVotingPeriod", minVotingPeriod, _minVotingPeriod);
        emit ParameterChange("minQuorum", minQuorum, _minQuorum);
        emit ParameterChange("minStakeForProposal", minStakeForProposal, _minStakeForProposal);
        minVotingPeriod = _minVotingPeriod;
        minQuorum = _minQuorum;
        minStakeForProposal = _minStakeForProposal;
    }

    function withdrawTreasuryGrant(uint256 _proposalId) external nonReentrant whenNotPaused {
        Proposal storage p = proposals[_proposalId];
        require(p.proposalType == ProposalType.TreasuryGrant, "EpochBeacon: Not a treasury grant proposal.");
        require(p.state == ProposalState.Executed, "EpochBeacon: Proposal not executed successfully.");
        require(msg.sender == p.recipient, "EpochBeacon: Only recipient can withdraw grant.");
        require(p.amount > 0, "EpochBeacon: Grant already withdrawn or zero.");

        uint256 amountToWithdraw = p.amount;
        p.amount = 0; // Prevent double withdrawal
        treasuryFunds = treasuryFunds.sub(amountToWithdraw);

        (bool success, ) = payable(p.recipient).call{value: amountToWithdraw}("");
        require(success, "EpochBeacon: Grant withdrawal failed.");
        emit TreasuryGrantWithdrawn(_proposalId, p.recipient, amountToWithdraw);
    }

    function _getTotalActiveStake() internal view returns (uint256 totalStake) {
        // This is highly inefficient for a large number of guardians.
        // A better approach involves maintaining a running sum or using a snapshot mechanism.
        // For demonstration purposes, it's illustrative.
        // In a real system, you might iterate over a list of active guardians.
        // For this example, let's assume `totalStakedGuardians` is a proxy for total stake,
        // or a dedicated variable that is updated on stake/unstake.
        // Let's assume totalStakedGuardians maps to an actual sum of stake.
        // In this simplified version, `totalStakedGuardians` is just a counter of active *addresses*.
        // We'd need to sum their actual stake.
        // For now, let's return a dummy value or a pre-computed variable.
        // Assume `totalStakedAmount` is a state variable updated on stake/unstake.
        return 0; // Placeholder, needs actual implementation to sum all active guardian stakes
    }

    // --- Dispute Resolution ---

    function submitDispute(uint256 _epochId, address _challengedGuardian, bytes32 _allegedIncorrectInputHash, string memory _reason) external payable nonReentrant whenNotPaused {
        require(msg.value == disputeBondAmount, "EpochBeacon: Must submit correct dispute bond.");
        require(_epochId < currentEpoch, "EpochBeacon: Cannot dispute current or future epoch.");
        require(epochBeaconSignals[_epochId].finalized, "EpochBeacon: Epoch beacon not finalized.");
        require(guardianInfo[_challengedGuardian].active, "EpochBeacon: Challenged address is not an active guardian.");
        require(epochGuardianInputs[_epochId][_challengedGuardian] != bytes32(0), "EpochBeacon: Challenged guardian did not submit input for this epoch.");
        
        // This implies the challenger knows the *correct* input or can prove the submitted one is wrong.
        // The `_allegedIncorrectInputHash` is the hash submitted by the guardian, not the *correct* one.
        // The dispute mechanism would involve verifying if `_allegedIncorrectInputHash` matches `epochGuardianInputs[_epochId][_challengedGuardian]`
        // and then determining if this input was indeed "incorrect" based on some external criteria or consensus.
        require(epochGuardianInputs[_epochId][_challengedGuardian] == _allegedIncorrectInputHash, "EpochBeacon: Alleged hash does not match submitted.");

        uint256 disputeId = nextDisputeId++;
        disputes[disputeId] = Dispute({
            id: disputeId,
            epochId: _epochId,
            challenger: msg.sender,
            challengedGuardian: _challengedGuardian,
            allegedIncorrectInputHash: _allegedIncorrectInputHash,
            reason: _reason,
            disputeBond: msg.value,
            state: DisputeState.Voting,
            votingDeadline: block.timestamp.add(disputeVotingPeriod),
            votesForResolution: 0,
            votesAgainstResolution: 0,
            hasVoted: new mapping(address => bool)
        });
        emit DisputeSubmitted(disputeId, msg.sender, _challengedGuardian, _epochId);
    }

    function voteOnDispute(uint256 _disputeId, bool _supportChallenger) external onlyGovernor nonReentrant whenNotPaused {
        // In a full DAO, this would be voted on by guardians or a dedicated committee.
        // For this example, onlyGovernor can vote.
        Dispute storage d = disputes[_disputeId];
        require(d.state == DisputeState.Voting, "EpochBeacon: Dispute not in voting state.");
        require(block.timestamp <= d.votingDeadline, "EpochBeacon: Voting period has ended.");
        require(!d.hasVoted[msg.sender], "EpochBeacon: Already voted on this dispute.");

        // Here, _supportChallenger means voting that the challenged guardian was indeed wrong.
        // Voting `false` means the challenged guardian was correct, or the dispute is invalid.
        if (_supportChallenger) {
            d.votesForResolution = d.votesForResolution.add(1); // Simplified vote, no stake weighting for dispute votes here
        } else {
            d.votesAgainstResolution = d.votesAgainstResolution.add(1);
        }
        d.hasVoted[msg.sender] = true;
        // Emit vote event
    }

    function resolveDispute(uint256 _disputeId) external onlyGovernor nonReentrant whenNotPaused {
        // Again, in a full DAO, this would be automatically triggered or executed by anyone after voting ends.
        Dispute storage d = disputes[_disputeId];
        require(d.state == DisputeState.Voting, "EpochBeacon: Dispute not in voting state.");
        require(block.timestamp > d.votingDeadline, "EpochBeacon: Voting period has not ended.");

        address winner;
        address loser;
        uint256 rewardAmount = 0;
        uint256 bondReturnAmount = 0;

        if (d.votesForResolution > d.votesAgainstResolution) {
            // Challenger wins: Guardian was incorrect
            d.state = DisputeState.ResolvedTrue;
            winner = d.challenger;
            loser = d.challengedGuardian;

            // Slash the challenged guardian's stake and reputation
            uint256 slashAmount = guardianInfo[loser].stake.mul(slashPercentage).div(10000);
            guardianInfo[loser].stake = guardianInfo[loser].stake.sub(slashAmount);
            guardianInfo[loser].reputation = guardianInfo[loser].reputation.div(2); // Halve reputation
            treasuryFunds = treasuryFunds.add(slashAmount); // Slashing goes to treasury

            // Reward the challenger
            rewardAmount = d.disputeBond.mul(1500).div(10000); // 15% reward from the bond (can be configurable)
            bondReturnAmount = d.disputeBond.sub(rewardAmount); // Return remaining bond

            (bool success, ) = payable(winner).call{value: bondReturnAmount.add(rewardAmount)}("");
            require(success, "EpochBeacon: Challenger reward failed.");

        } else {
            // Challenger loses: Guardian was correct or dispute invalid
            d.state = DisputeState.ResolvedFalse;
            winner = d.challengedGuardian; // Guardian is effectively winner, keeps stake/reputation
            loser = d.challenger; // Challenger loses bond
            
            treasuryFunds = treasuryFunds.add(d.disputeBond); // Challenger's bond goes to treasury
        }
        emit DisputeResolved(_disputeId, d.state, winner, loser);
    }

    function getDisputeDetails(uint256 _disputeId) external view returns (uint256 id, uint256 epochId, address challenger, address challengedGuardian, DisputeState state, uint256 votesFor, uint256 votesAgainst, uint256 votingDeadline) {
        Dispute storage d = disputes[_disputeId];
        return (d.id, d.epochId, d.challenger, d.challengedGuardian, d.state, d.votesForResolution, d.votesAgainstResolution, d.votingDeadline);
    }

    // --- Utility & Access Control ---

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function withdrawProtocolFees(address _recipient, uint256 _amount) external onlyGovernor nonReentrant whenNotPaused {
        require(_amount > 0, "EpochBeacon: Amount must be positive.");
        require(treasuryFunds >= _amount, "EpochBeacon: Insufficient treasury funds.");
        treasuryFunds = treasuryFunds.sub(_amount);
        (bool success, ) = payable(_recipient).call{value: _amount}("");
        require(success, "EpochBeacon: Withdrawal failed.");
        emit ProtocolFeesWithdrawn(_recipient, _amount);
    }

    // --- UUPS Upgradeability ---
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
```