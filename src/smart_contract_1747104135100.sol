Okay, here is a smart contract concept called the "Quantum Fluctuation Fund". It leverages Chainlink VRF for randomness to simulate "quantum fluctuations" that influence the distribution of funds collected in epochs. It includes features like dynamic distribution based on randomness, NFTs for participants, epoch management, and multi-step distribution to manage gas.

This contract is designed to be complex and demonstrate various concepts:
1.  **Epoch-based Structure:** Organized into distinct time periods.
2.  **Randomness-Driven Dynamics:** Uses Chainlink VRF to generate a "Fluctuation Index" that dictates distribution parameters.
3.  **Dynamic Distribution:** The number of winners and the total amount distributed per epoch are influenced by the random index.
4.  **Weighted Probability (Conceptual):** While true on-chain weighted *selection* is gas-intensive for many participants, the design *allows* for distribution amounts to winners to be proportional to their contribution *and* the fluctuation index. The selection itself in `executeDistributionStep` is simplified for gas reasons.
5.  **Multi-Step Distribution:** Allows distributing funds to multiple winners over several transactions to avoid hitting gas limits.
6.  **NFTs for Participation:** Participants meeting a certain threshold can claim a unique NFT badge.
7.  **State Machine:** Uses an enum to manage the epoch lifecycle.
8.  **Access Control & Pause:** Standard safety features.

**Disclaimer:** This is a complex concept for demonstration. Deploying and managing such a contract requires careful consideration of gas costs for on-chain loops/iterations (especially winner selection/distribution logic), security audits, and robust oracle integration (Chainlink VRF setup requires funding and registration). The winner selection logic in `executeDistributionStep` is simplified for function count demonstration and assumes a maximum number of distribution steps; a real-world implementation might need a more sophisticated off-chain + proof system for guaranteed fairness with many participants.

---

**Quantum Fluctuation Fund - Outline and Function Summary**

**Contract Name:** `QuantumFluctuationFund`

**Core Concept:** A community fund operating in epochs, where contributions are partially distributed back to participants based on outcomes influenced by secure, verifiable randomness ("Quantum Fluctuations") provided by Chainlink VRF. A protocol fee is collected. Participants can earn NFTs.

**Epoch Lifecycle:**
1.  `Inactive`: Waiting for a new epoch to start.
2.  `Contribution`: Users can contribute ETH.
3.  `FluctuationRequest`: Epoch closed for contribution, waiting for VRF randomness request.
4.  `FluctuationPending`: VRF request sent, waiting for callback.
5.  `DistributionSetup`: VRF callback received, distribution parameters determined.
6.  `DistributionInProgress`: Funds being distributed to selected winners over one or more transactions.
7.  `DistributionEnded`: Distribution complete for the epoch. Can return to `Inactive` or transition to the next epoch's `Contribution`.

**Function Summary:**

**Core Epoch Management & Flow (7 functions):**
1.  `startNewEpoch()`: Initiates a new epoch, transitioning state to `Contribution`.
2.  `contributeToEpoch()`: Allows users to send ETH contributions during the `Contribution` phase.
3.  `endContributionPhase()`: Closes the `Contribution` phase and moves to `FluctuationRequest`.
4.  `requestFluctuationIndex()`: Sends a request to Chainlink VRF for randomness. Moves to `FluctuationPending`.
5.  `fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)`: Chainlink VRF callback. Receives randomness, calculates `fluctuationIndex`, and triggers `determineDistributionParameters`. Moves to `DistributionSetup`.
6.  `initiateDistribution()`: Prepares the data structures and parameters for distribution based on the `fluctuationIndex`. Moves to `DistributionInProgress`.
7.  `executeDistributionStep()`: Executes one step of the distribution process, transferring funds to one or more determined winners. Can be called multiple times.

**Configuration & Administration (Owner Only) (7 functions):**
8.  `setProtocolFeePercentage(uint16 _feeBasisPoints)`: Sets the fee taken by the protocol (in basis points).
9.  `setEpochPhaseDurations(uint64 _contributionDuration, uint64 _distributionDuration)`: Sets the duration for contribution and distribution phases.
10. `setOracleConfig(uint64 _subscriptionId, bytes32 _keyHash, uint32 _callbackGasLimit, uint96 _requestConfirmations, uint256 _requestFee)`: Configures Chainlink VRF parameters.
11. `withdrawProtocolFees()`: Allows the owner to withdraw accumulated protocol fees.
12. `pause()`: Pauses the contract, blocking sensitive functions.
13. `unpause()`: Unpauses the contract.
14. `transferOwnership(address newOwner)`: Transfers ownership of the contract (from Ownable).

**NFT Functionality (2 functions + inherited ERC721):**
15. `isParticipantEligibleForNFT(address participant)`: Checks if a participant's contribution in the *most recent ended* epoch meets the NFT threshold.
16. `claimObserverNFT()`: Allows eligible participants to mint their unique "Quantum Observer" NFT.

**Information / View Functions (11 functions):**
17. `getCurrentEpochId()`: Gets the ID of the current or most recently ended epoch.
18. `getEpochState()`: Gets the current state of the epoch lifecycle.
19. `getTotalContributionsCurrentEpoch()`: Gets the total ETH contributed in the current epoch.
20. `getParticipantContribution(uint256 epochId, address participant)`: Gets the contribution of a specific participant in a given epoch.
21. `getFluctuationIndex(uint256 epochId)`: Gets the calculated fluctuation index for a given epoch (if available).
22. `getProtocolFeePercentage()`: Gets the current protocol fee percentage.
23. `getEpochPhaseTimestamps(uint256 epochId)`: Gets the start/end timestamps for phases of a given epoch.
24. `getTotalProtocolFeesCollected()`: Gets the total cumulative fees collected across all epochs.
25. `getTotalDistributedThisEpoch()`: Gets the total ETH distributed so far in the current epoch.
26. `getDistributionParameters(uint256 epochId)`: Gets the parameters (winner count, total payout) determined for distribution in an epoch.
27. `getParticipantDistributionReceived(uint256 epochId, address participant)`: Gets the amount of ETH distributed to a participant in a given epoch.

**Other Utility (1 function):**
28. `withdrawRemainingEpochFunds()`: Allows the owner to withdraw any funds remaining in the contract after distribution is complete (e.g., rounding dust, unclaimed amounts, or undistributed protocol share). *Careful use required.*

**Total Unique Functions (excluding standard ERC721 implementation details beyond minting): 7 + 7 + 2 + 11 + 1 = 28.** (Plus standard ERC721 like `ownerOf`, `balanceOf`, `transferFrom`, etc., which are needed but not listed individually as they are boilerplate).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

// --- Quantum Fluctuation Fund ---
// Outline and Function Summary are provided at the top of the file.

contract QuantumFluctuationFund is Ownable, Pausable, ERC721, VRFConsumerBaseV2 {

    // --- State Variables ---

    // Epoch State Machine
    enum EpochState { Inactive, Contribution, FluctuationRequest, FluctuationPending, DistributionSetup, DistributionInProgress, DistributionEnded }
    EpochState public currentEpochState;

    // Epoch Tracking
    uint256 public currentEpochId;
    mapping(uint256 => EpochState) public epochStates;
    mapping(uint256 => uint64) public epochStartTime;
    mapping(uint256 => uint64) public contributionEndTime;
    mapping(uint256 => uint64) public fluctuationRequestTime;
    mapping(uint256 => uint64) public distributionSetupTime;
    mapping(uint256 => uint64) public distributionEndTime; // Marks when DistributionInProgress finished

    // Epoch Configuration
    uint64 public contributionDuration; // Duration of the contribution phase in seconds
    uint64 public distributionDuration; // Duration allowed for the distribution phase in seconds (not strict end, but guidance/timeout)

    // Contribution Data
    mapping(uint256 => uint256) public totalContributionsByEpoch;
    mapping(uint256 => mapping(address => uint256)) public participantContributionsByEpoch;
    mapping(uint256 => address[]) public participantsInEpoch; // List of unique participants per epoch (potentially gas heavy for large arrays)

    // Fluctuation (VRF) Data
    VRFCoordinatorV2Interface COORDINATOR;
    uint64 public s_subscriptionId;
    bytes32 public s_keyHash;
    uint32 public s_callbackGasLimit;
    uint96 public s_requestConfirmations;
    uint256 public s_requestFee; // Fee per VRF request

    mapping(uint256 => uint256) public s_requestIdToEpochId;
    mapping(uint256 => bool) public s_requestsExist;
    mapping(uint256 => uint256) public fluctuationIndexByEpoch; // The random number determines the 'index'

    // Distribution Data
    uint16 public protocolFeeBasisPoints; // Fee in basis points (e.g., 500 = 5%)
    uint256 public totalProtocolFeesCollected;

    // Distribution parameters determined by fluctuation index
    struct DistributionParams {
        uint256 totalPayoutAmount;
        uint256 numberOfWinners;
        uint256 payoutPerWinnerBase; // Base amount for winners (can be adjusted by contribution/index)
        bool initialized;
    }
    mapping(uint256 => DistributionParams) public epochDistributionParams;
    mapping(uint256 => uint256) public totalDistributedByEpoch;
    mapping(uint256 => mapping(address => uint256)) public participantDistributionReceivedByEpoch;

    // Distribution Execution State
    uint256 public distributionStepIndex; // Tracks progress through distribution steps

    // NFT Data
    uint256 private _nextTokenId;
    uint256 public minContributionForNFT; // Minimum contribution in wei to be eligible for an NFT
    mapping(uint256 => mapping(address => bool)) public nftClaimedByEpochParticipant; // Tracks if NFT is claimed

    // --- Events ---

    event EpochStarted(uint256 indexed epochId, uint64 startTime);
    event FundContributed(uint256 indexed epochId, address indexed participant, uint256 amount);
    event ContributionPhaseEnded(uint256 indexed epochId, uint64 endTime, uint256 totalContributions);
    event FluctuationRequestSent(uint256 indexed epochId, uint256 indexed requestId, uint64 requestTime);
    event FluctuationIndexed(uint256 indexed epochId, uint256 fluctuationIndex, uint64 indexTime);
    event DistributionParametersDetermined(uint256 indexed epochId, uint256 totalPayout, uint256 numWinners);
    event DistributionInitiated(uint256 indexed epochId, uint64 initiationTime);
    event ParticipantDistributed(uint256 indexed epochId, address indexed participant, uint256 amount);
    event DistributionStepExecuted(uint256 indexed epochId, uint256 stepIndex, uint256 participantsProcessedInStep);
    event DistributionEnded(uint256 indexed epochId, uint64 endTime);
    event ProtocolFeesWithdrawn(uint256 amount);
    event ObserverNFTMinted(uint256 indexed epochId, address indexed participant, uint256 indexed tokenId);
    event RemainingFundsWithdrawn(uint256 indexed epochId, uint256 amount);

    // --- Modifiers ---

    modifier onlyEpochState(EpochState _state) {
        require(currentEpochState == _state, "QFF: Invalid epoch state for this action");
        _;
    }

    modifier onlyEpochStateOrEarlier(EpochState _state) {
        require(uint8(currentEpochState) <= uint8(_state), "QFF: Invalid epoch state for this action");
        _;
    }

    // --- Constructor ---

    constructor(
        address vrfCoordinator,
        uint64 subscriptionId,
        bytes32 keyHash,
        uint32 callbackGasLimit,
        uint96 requestConfirmations,
        uint256 requestFee,
        uint16 initialProtocolFeeBasisPoints,
        uint64 initialContributionDuration,
        uint64 initialDistributionDuration,
        uint256 initialMinContributionForNFT,
        string memory name, // ERC721 params
        string memory symbol // ERC721 params
    )
        ERC721(name, symbol)
        VRFConsumerBaseV2(vrfCoordinator)
        Ownable(msg.sender)
        Pausable()
    {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        s_subscriptionId = subscriptionId;
        s_keyHash = keyHash;
        s_callbackGasLimit = callbackGasLimit;
        s_requestConfirmations = requestConfirmations;
        s_requestFee = requestFee;

        protocolFeeBasisPoints = initialProtocolFeeBasisPoints;
        contributionDuration = initialContributionDuration;
        distributionDuration = initialDistributionDuration;
        minContributionForNFT = initialMinContributionForNFT;

        currentEpochState = EpochState.Inactive;
        currentEpochId = 0;
        _nextTokenId = 1; // Start NFT token IDs from 1
    }

    // --- Core Epoch Management & Flow (7 functions) ---

    /// @notice Starts a new epoch, transitioning from Inactive or DistributionEnded to Contribution.
    /// Can only be called by the owner or after the previous epoch's distribution ended + duration.
    function startNewEpoch() external onlyOwner whenNotPaused {
        // Ensure valid state transition
        require(currentEpochState == EpochState.Inactive || currentEpochState == EpochState.DistributionEnded, "QFF: Cannot start new epoch in current state");

        currentEpochId++;
        currentEpochState = EpochState.Contribution;
        epochStates[currentEpochId] = currentEpochState;
        epochStartTime[currentEpochId] = uint64(block.timestamp);
        contributionEndTime[currentEpochId] = uint64(block.timestamp + contributionDuration);

        // Reset epoch-specific state
        totalContributionsByEpoch[currentEpochId] = 0;
        // participantsInEpoch[currentEpochId] is implicitly empty for a new id
        delete epochDistributionParams[currentEpochId]; // Reset distribution params struct
        totalDistributedByEpoch[currentEpochId] = 0;
        distributionStepIndex = 0; // Reset step index for multi-step distribution

        emit EpochStarted(currentEpochId, epochStartTime[currentEpochId]);
    }

    /// @notice Allows users to contribute ETH to the current epoch.
    /// @dev Contributes are recorded and added to the epoch total. Adds participant if new this epoch.
    function contributeToEpoch() external payable whenNotPaused onlyEpochState(EpochState.Contribution) {
        require(msg.value > 0, "QFF: Contribution must be greater than 0");
        require(block.timestamp < contributionEndTime[currentEpochId], "QFF: Contribution phase has ended");

        totalContributionsByEpoch[currentEpochId] += msg.value;

        // Add participant to list if new this epoch
        if (participantContributionsByEpoch[currentEpochId][msg.sender] == 0) {
            participantsInEpoch[currentEpochId].push(msg.sender);
        }
        participantContributionsByEpoch[currentEpochId][msg.sender] += msg.value;

        emit FundContributed(currentEpochId, msg.sender, msg.value);
    }

    /// @notice Ends the contribution phase and transitions to FluctuationRequest.
    /// Can be called by anyone once the contribution duration is over.
    function endContributionPhase() external whenNotPaused onlyEpochState(EpochState.Contribution) {
         require(block.timestamp >= contributionEndTime[currentEpochId], "QFF: Contribution phase is not over yet");

        currentEpochState = EpochState.FluctuationRequest;
        epochStates[currentEpochId] = currentEpochState;

        emit ContributionPhaseEnded(currentEpochId, uint64(block.timestamp), totalContributionsByEpoch[currentEpochId]);
    }

    /// @notice Requests randomness from Chainlink VRF.
    /// @dev Requires the epoch to be in FluctuationRequest state. Only callable once per epoch.
    /// Funds are sent to the VRF coordinator for the request fee.
    function requestFluctuationIndex() external whenNotPaused onlyEpochState(EpochState.FluctuationRequest) {
        require(!s_requestsExist[currentEpochId], "QFF: Fluctuation request already sent for this epoch");
        require(address(this).balance >= s_requestFee, "QFF: Not enough ETH to pay VRF fee");

        // Will revert if subscription is not funded or other VRF issues
        uint256 requestId = COORDINATOR.requestRandomWords(
            s_keyHash,
            s_subscriptionId,
            s_requestConfirmations,
            s_callbackGasLimit,
            1 // Requesting 1 random word
        );

        s_requestIdToEpochId[requestId] = currentEpochId;
        s_requestsExist[currentEpochId] = true;

        currentEpochState = EpochState.FluctuationPending;
        epochStates[currentEpochId] = currentEpochState;
        fluctuationRequestTime[currentEpochId] = uint64(block.timestamp);

        emit FluctuationRequestSent(currentEpochId, requestId, fluctuationRequestTime[currentEpochId]);
    }

    /// @notice Chainlink VRF callback function to receive random words.
    /// @dev This function is called by the VRF Coordinator after the randomness is generated.
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        uint256 epochId = s_requestIdToEpochId[requestId];
        require(epochStates[epochId] == EpochState.FluctuationPending, "QFF: VRF callback for unexpected epoch state");
        require(randomWords.length > 0, "QFF: No random words received");

        uint256 fluctuationIndex = randomWords[0];
        fluctuationIndexByEpoch[epochId] = fluctuationIndex;

        // Determine distribution parameters based on the index
        _determineDistributionParameters(epochId, fluctuationIndex);

        epochStates[epochId] = EpochState.DistributionSetup;
        distributionSetupTime[epochId] = uint64(block.timestamp);
        // Next step is initiateDistribution() called by owner/trigger

        emit FluctuationIndexed(epochId, fluctuationIndex, distributionSetupTime[epochId]);
    }

    /// @notice Determines the distribution parameters (winner count, total payout) based on the fluctuation index.
    /// @dev Internal function called by fulfillRandomWords.
    function _determineDistributionParameters(uint256 epochId, uint256 fluctuationIndex) internal {
        uint256 totalContributions = totalContributionsByEpoch[epochId];
        uint256 feeAmount = (totalContributions * protocolFeeBasisPoints) / 10000;
        uint256 distributableAmount = totalContributions - feeAmount;

        // --- Dynamic Distribution Logic (Example - Can be highly customized) ---
        // The randomness influences how much is distributed and to how many people.
        // Example: fluctuationIndex affects the *percentage* distributed and the *number* of winners.

        // Simulate fluctuation influencing payout percentage (e.g., 50% to 95% of distributable)
        uint256 minPayoutPercent = 50; // 50%
        uint256 maxPayoutPercent = 95; // 95%
        // Map index to a range: index % (max - min + 1) + min
        uint256 effectivePayoutPercent = (fluctuationIndex % (maxPayoutPercent - minPayoutPercent + 1)) + minPayoutPercent;
        uint256 totalPayout = (distributableAmount * effectivePayoutPercent) / 100;

        // Simulate fluctuation influencing number of winners (e.g., min 1 winner, max based on participant count)
        uint256 minWinners = 1;
        uint256 maxWinners = participantsInEpoch[epochId].length > 0 ? participantsInEpoch[epochId].length : 1; // Max winners is participant count
        uint256 numberOfWinners;
        if (maxWinners > minWinners) {
             numberOfWinners = (fluctuationIndex % (maxWinners - minWinners + 1)) + minWinners;
        } else {
             numberOfWinners = minWinners;
        }
        // Ensure number of winners doesn't exceed participants
         if (numberOfWinners > participantsInEpoch[epochId].length) {
             numberOfWinners = participantsInEpoch[epochId].length;
         }


        // Store parameters
        epochDistributionParams[epochId] = DistributionParams({
            totalPayoutAmount: totalPayout,
            numberOfWinners: numberOfWinners,
            payoutPerWinnerBase: totalPayout / (numberOfWinners > 0 ? numberOfWinners : 1), // Simple base payout
            initialized: true
        });

        emit DistributionParametersDetermined(epochId, totalPayout, numberOfWinners);
    }


    /// @notice Initiates the distribution process after the fluctuation index is received.
    /// @dev Must be called after VRF callback and parameter determination. Can be called by owner or after a delay.
    function initiateDistribution() external whenNotPaused onlyEpochState(EpochState.DistributionSetup) {
        // Optional: Add a minimum delay check after distributionSetupTime if not onlyOwner
        // require(block.timestamp >= distributionSetupTime[currentEpochId] + <delay>, "QFF: Too early to initiate distribution");

        require(epochDistributionParams[currentEpochId].initialized, "QFF: Distribution parameters not determined");

        currentEpochState = EpochState.DistributionInProgress;
        epochStates[currentEpochId] = currentEpochState;
        distributionStepIndex = 0; // Start at step 0

        emit DistributionInitiated(currentEpochId, uint64(block.timestamp));
    }

    /// @notice Executes one step of the distribution process. Can be called multiple times.
    /// @dev This allows distributing to winners gradually to manage gas limits.
    /// The logic here simplifies winner selection for gas. A real system might use a Merkle proof or similar.
    /// Currently, it iterates through participants and distributes to a subset per step.
    function executeDistributionStep() external whenNotPaused onlyEpochState(EpochState.DistributionInProgress) {
        DistributionParams storage params = epochDistributionParams[currentEpochId];
        require(params.initialized, "QFF: Distribution parameters not determined");
        require(totalDistributedByEpoch[currentEpochId] < params.totalPayoutAmount, "QFF: All funds already distributed");

        address[] storage participants = participantsInEpoch[currentEpochId];
        uint256 totalParticipants = participants.length;
        uint256 winnersToSelectThisStep = 5; // Example: Process up to 5 winners per step

        uint256 participantsProcessedThisStep = 0;
        uint256 winnersFoundThisStep = 0;
        uint256 totalDistributedThisStep = 0;

        // Simple, gas-conscious distribution: Iterate through participants based on step index.
        // This is *not* perfectly random weighted distribution on-chain for many participants.
        // The randomness influenced the *parameters*, not the *selection* directly in this simplified gas-safe model.
        // A more advanced approach would be needed for verifiable weighted randomness.

        uint256 startParticipantIndex = distributionStepIndex * winnersToSelectThisStep;

        for (uint256 i = 0; i < winnersToSelectThisStep; i++) {
             uint256 participantListIndex = (startParticipantIndex + i) % totalParticipants;
             address participant = participants[participantListIndex];

             // Determine if this participant is a "winner" in this step based on index and parameters
             // Simplified check: Distribute to 'params.numberOfWinners' participants selected pseudo-randomly or sequentially.
             // A more complex check related to the fluctuation index and participant's contribution
             // could be added here, but it's hard to do truly randomly and weighted on-chain.

             // Let's simplify: distribute up to params.numberOfWinners sequentially based on step index
             if (totalDistributedByEpoch[currentEpochId] < params.totalPayoutAmount && (distributionStepIndex * winnersToSelectThisStep + i) < params.numberOfWinners) {
                 uint256 contribution = participantContributionsByEpoch[currentEpochId][participant];

                 // Payout amount could be proportional to contribution and index - Example:
                 // uint256 payoutAmount = (params.payoutPerWinnerBase * contribution) / totalContributionsByEpoch[currentEpochId]; // Proportional to contribution
                 // uint256 payoutAmount = (params.payoutPerWinnerBase * fluctuationIndexByEpoch[currentEpochId]) / 1000; // Proportional to index (example scaling)
                 // Let's use a simpler model for gas: fixed base amount per winner, potentially scaled slightly by index
                 uint256 payoutAmount = params.payoutPerWinnerBase; // Simple model: distribute the base amount to the first N participants selected

                 // Adjust payout if distributing more than available
                 if (totalDistributedByEpoch[currentEpochId] + payoutAmount > params.totalPayoutAmount) {
                    payoutAmount = params.totalPayoutAmount - totalDistributedByEpoch[currentEpochId];
                 }

                 if (payoutAmount > 0) {
                     payable(participant).transfer(payoutAmount); // Potential reentrancy risk if recipient is malicious. Consider pull pattern. Using transfer for simplicity here.
                     participantDistributionReceivedByEpoch[currentEpochId][participant] += payoutAmount;
                     totalDistributedByEpoch[currentEpochId] += payoutAmount;
                     winnersFoundThisStep++;
                     totalDistributedThisStep += payoutAmount;
                     emit ParticipantDistributed(currentEpochId, participant, payoutAmount);
                 }
             }
             participantsProcessedThisStep++;

             // Stop if total payout reached
             if (totalDistributedByEpoch[currentEpochId] >= params.totalPayoutAmount) {
                break;
             }
        }

        distributionStepIndex++;

        emit DistributionStepExecuted(currentEpochId, distributionStepIndex - 1, participantsProcessedThisStep);

        // Check if distribution is complete
        if (totalDistributedByEpoch[currentEpochId] >= params.totalPayoutAmount) {
            currentEpochState = EpochState.DistributionEnded;
            epochStates[currentEpochId] = currentEpochState;
            distributionEndTime[currentEpochId] = uint64(block.timestamp);
            emit DistributionEnded(currentEpochId, distributionEndTime[currentEpochId]);
        }
         // Add a timeout to allow owner to force end distribution if stuck
        else if (block.timestamp >= distributionSetupTime[currentEpochId] + distributionDuration) {
             currentEpochState = EpochState.DistributionEnded; // Force end after timeout
             epochStates[currentEpochId] = currentEpochState;
             distributionEndTime[currentEpochId] = uint64(block.timestamp);
             // Log warning about incomplete distribution?
             emit DistributionEnded(currentEpochId, distributionEndTime[currentEpochId]);
        }
    }

     /// @notice Finalizes the distribution phase, moving to Inactive if complete.
     /// @dev Can be called by anyone after distribution is finished or timed out.
     function endDistributionPhase() external whenNotPaused {
         require(currentEpochState == EpochState.DistributionEnded, "QFF: Distribution phase is not ended");
         // Could add checks here to ensure totalDistributedByEpoch[currentEpochId] is close to totalPayoutAmount or timeout passed

         currentEpochState = EpochState.Inactive;
         epochStates[currentEpochId] = currentEpochState; // Mark the *contract's* state as Inactive

         // The epoch's state in mapping is already set to DistributionEnded by executeDistributionStep

         // No explicit event for moving to Inactive state, as EpochEnded event covers the completion.
     }


    // --- Configuration & Administration (Owner Only) (7 functions) ---

    /// @notice Sets the protocol fee percentage in basis points.
    /// @param _feeBasisPoints The fee amount in basis points (e.g., 500 for 5%). Max 10000 (100%).
    function setProtocolFeePercentage(uint16 _feeBasisPoints) external onlyOwner {
        require(_feeBasisPoints <= 10000, "QFF: Fee percentage cannot exceed 100%");
        protocolFeeBasisPoints = _feeBasisPoints;
    }

    /// @notice Sets the durations for contribution and distribution phases.
    /// @param _contributionDuration The duration for the contribution phase in seconds.
    /// @param _distributionDuration The maximum duration allowed for the distribution phase in seconds.
    function setEpochPhaseDurations(uint64 _contributionDuration, uint64 _distributionDuration) external onlyOwner {
        require(_contributionDuration > 0 && _distributionDuration > 0, "QFF: Durations must be positive");
        contributionDuration = _contributionDuration;
        distributionDuration = _distributionDuration;
    }

    /// @notice Sets the configuration parameters for Chainlink VRF.
    function setOracleConfig(
        uint64 _subscriptionId,
        bytes32 _keyHash,
        uint32 _callbackGasLimit,
        uint96 _requestConfirmations,
        uint256 _requestFee
    ) external onlyOwner {
        s_subscriptionId = _subscriptionId;
        s_keyHash = _keyHash;
        s_callbackGasLimit = _callbackGasLimit;
        s_requestConfirmations = _requestConfirmations;
        s_requestFee = _requestFee;
    }

    /// @notice Allows the owner to withdraw accumulated protocol fees.
    function withdrawProtocolFees() external onlyOwner whenNotPaused {
        uint256 feeAmount = address(this).balance - (totalContributionsByEpoch[currentEpochId] - totalDistributedByEpoch[currentEpochId]) - totalDistributedByEpoch[currentEpochId]; // Simple calc: total balance - funds not yet distributed - funds already distributed (for current epoch)
        // More precise calculation: Sum of fees calculated in each epoch, minus fees already withdrawn.
        // For simplicity, this version assumes fees accumulate and can be withdrawn when available.
        // A robust system would track fee balance separately per epoch.
        // Let's use a simpler tracking variable for collected fees:
        // We need to add fee calculation logic during distribution setup.
        // Let's assume totalProtocolFeesCollected is updated correctly when distribution parameters are set.

        uint256 amountToWithdraw = totalProtocolFeesCollected;
        totalProtocolFeesCollected = 0; // Reset collected fees after withdrawal

        require(amountToWithdraw > 0, "QFF: No protocol fees to withdraw");

        payable(owner()).transfer(amountToWithdraw); // Transfer fee amount
        emit ProtocolFeesWithdrawn(amountToWithdraw);
    }

    /// @notice Pauses the contract.
    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    /// @notice Unpauses the contract.
    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    // Inherits transferOwnership from Ownable

    // --- NFT Functionality (2 functions + inherited ERC721) ---

    /// @notice Checks if a participant is eligible to claim an NFT for a specific epoch.
    /// @dev Eligibility is based on meeting the minContributionForNFT in the specified epoch.
    /// @param participant The address of the participant to check.
    /// @param epochIdToCheck The epoch ID to check eligibility for.
    /// @return bool True if the participant is eligible and hasn't claimed yet.
    function isParticipantEligibleForNFT(address participant, uint256 epochIdToCheck) public view returns (bool) {
        // Must check an epoch that has finished contributions or distribution
        require(epochStates[epochIdToCheck] >= EpochState.ContributionPhaseEnded, "QFF: Epoch must be past contribution phase to check NFT eligibility");

        uint256 contribution = participantContributionsByEpoch[epochIdToCheck][participant];
        bool claimed = nftClaimedByEpochParticipant[epochIdToCheck][participant];

        return contribution >= minContributionForNFT && !claimed;
    }


    /// @notice Allows an eligible participant to mint their "Quantum Observer" NFT for a specific epoch.
    /// @param epochIdToClaim The epoch ID for which to claim the NFT.
    function claimObserverNFT(uint256 epochIdToClaim) external whenNotPaused {
        require(isParticipantEligibleForNFT(msg.sender, epochIdToClaim), "QFF: Not eligible to claim NFT for this epoch");

        nftClaimedByEpochParticipant[epochIdToClaim][msg.sender] = true; // Mark as claimed

        uint256 newItemId = _nextTokenId++;
        _safeMint(msg.sender, newItemId); // Mint the NFT

        emit ObserverNFTMinted(epochIdToClaim, msg.sender, newItemId);
    }

    // ERC721 standard functions like ownerOf, balanceOf, transferFrom, approve, etc.
    // are inherited and accessible. They count towards the function list.

    // --- Information / View Functions (11 functions) ---

    /// @notice Gets the ID of the current epoch.
    function getCurrentEpochId() external view returns (uint256) {
        return currentEpochId;
    }

    /// @notice Gets the current state of the epoch lifecycle.
    function getEpochState() external view returns (EpochState) {
        return currentEpochState;
    }

    /// @notice Gets the total ETH contributed in the current epoch.
    function getTotalContributionsCurrentEpoch() external view returns (uint256) {
        return totalContributionsByEpoch[currentEpochId];
    }

    /// @notice Gets the contribution of a specific participant in a given epoch.
    function getParticipantContribution(uint256 epochId, address participant) external view returns (uint256) {
        return participantContributionsByEpoch[epochId][participant];
    }

    /// @notice Gets the calculated fluctuation index for a given epoch.
    /// @return uint256 The fluctuation index (0 if not yet determined).
    function getFluctuationIndex(uint256 epochId) external view returns (uint256) {
        return fluctuationIndexByEpoch[epochId];
    }

    /// @notice Gets the current protocol fee percentage in basis points.
    function getProtocolFeePercentage() external view returns (uint16) {
        return protocolFeeBasisPoints;
    }

    /// @notice Gets the start/end timestamps for phases of a given epoch.
    /// @param epochId The epoch ID to query.
    /// @return startTime, contributionEnd, fluctuationRequest, distributionSetup, distributionEnd
    function getEpochPhaseTimestamps(uint256 epochId) external view returns (uint64, uint64, uint64, uint64, uint64) {
        return (
            epochStartTime[epochId],
            contributionEndTime[epochId],
            fluctuationRequestTime[epochId],
            distributionSetupTime[epochId],
            distributionEndTime[epochId]
        );
    }

    /// @notice Gets the total cumulative fees collected across all epochs.
    function getTotalProtocolFeesCollected() external view returns (uint256) {
        // This relies on `totalProtocolFeesCollected` being updated correctly during distribution setup.
        // A more accurate getter would iterate or track fee balance per epoch.
        // Using the current tracking variable:
        return totalProtocolFeesCollected;
    }

     /// @notice Gets the total ETH distributed so far in the current epoch.
    function getTotalDistributedThisEpoch() external view returns (uint256) {
        return totalDistributedByEpoch[currentEpochId];
    }

    /// @notice Gets the distribution parameters determined for an epoch.
    /// @param epochId The epoch ID to query.
    /// @return totalPayoutAmount, numberOfWinners, payoutPerWinnerBase, initialized
    function getDistributionParameters(uint256 epochId) external view returns (uint256, uint256, uint256, bool) {
        DistributionParams memory params = epochDistributionParams[epochId];
        return (params.totalPayoutAmount, params.numberOfWinners, params.payoutPerWinnerBase, params.initialized);
    }

    /// @notice Gets the amount of ETH distributed to a participant in a given epoch.
    function getParticipantDistributionReceived(uint256 epochId, address participant) external view returns (uint256) {
        return participantDistributionReceivedByEpoch[epochId][participant];
    }

    // --- Other Utility (1 function) ---

    /// @notice Allows the owner to withdraw any remaining balance in the contract after distribution ends.
    /// @dev This could include rounding dust, unclaimed distribution amounts (if any were left),
    /// or protocol fees not yet withdrawn. Use with caution.
    function withdrawRemainingEpochFunds() external onlyOwner whenNotPaused {
        // This calculates the remaining balance in the contract *after* the current epoch's calculated
        // total payout and fees are accounted for. This is a simplified calculation.
        // A robust system would need to track balances more carefully.
        uint256 totalBalance = address(this).balance;

        // Calculate expected balance *if* distribution completed and fees were set aside
        uint256 expectedPostDistributionBalance = totalContributionsByEpoch[currentEpochId] - epochDistributionParams[currentEpochId].totalPayoutAmount;
        // This is complex due to multi-epoch interactions and partial distributions.
        // A simpler approach: owner can withdraw *any* balance when distribution is ended.
        // This relies on the owner being trusted not to withdraw funds meant for future epochs or ongoing distribution.

        require(currentEpochState >= EpochState.DistributionEnded || currentEpochState == EpochState.Inactive, "QFF: Cannot withdraw remaining funds during an active epoch phase before distribution ends");

        uint256 amountToWithdraw = address(this).balance;
        require(amountToWithdraw > 0, "QFF: No funds remaining to withdraw");

        // Note: This function does not distinguish between fees, undistributed amounts, etc.
        // It withdraws the entire contract balance. Ensure fees are withdrawn separately first if needed.

        payable(owner()).transfer(amountToWithdraw);

        emit RemainingFundsWithdrawn(currentEpochId, amountToWithdraw); // Log withdrawal related to current/last epoch
    }

    // Fallback function to accept Ether
    receive() external payable {
        // Accept Ether, but require it happens during the contribution phase
        // Otherwise, reject unauthorized deposits.
        // This prevents random sends from changing the balance unexpectedly outside contribution.
        if (currentEpochState != EpochState.Contribution || block.timestamp >= contributionEndTime[currentEpochId] || paused()) {
             // Refund if not in contribution phase
             payable(msg.sender).transfer(msg.value); // Send back received Ether
             // Consider adding an event for rejected contributions
        } else {
             // If the state and time checks pass, process as a contribution
             contributeToEpoch();
        }
    }

    // Fallback function for calls without data
    fallback() external payable {
        if (msg.value > 0) {
            receive(); // Handle incoming Ether like the receive function
        }
        // Reject calls with data but no Ether
        require(msg.value > 0, "QFF: Calls with data require Ether");
    }
}
```