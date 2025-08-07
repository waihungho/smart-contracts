Okay, this is an exciting challenge! Let's design a smart contract called "ChronoForge" that deals with time-evolving, event-reactive digital artifacts, incorporating concepts like attestation, on-chain computation verification (abstracted), and a unique resource management system. It's an advanced, dynamic NFT-like system that goes beyond simple ownership.

The core idea: **ChronoForge** allows the creation of "Chronicles" – unique digital entities that exist on a timeline. These Chronicles don't just sit there; they evolve through different "States" based on a combination of time passing, external events, proof of off-chain computations, and explicit attestations from designated entities. A unique "Flux" resource fuels their evolution.

---

## ChronoForge Smart Contract

**Concept:** ChronoForge is a sophisticated ERC-721 compliant contract for creating and managing "Chronicles" – dynamic, evolving digital artifacts. Chronicles progress through distinct states based on predetermined chronological gates, external event triggers, verified off-chain computation proofs, and multi-entity attestations. A unique resource called "Flux" is required to enable state transitions and fuel their existence. This system aims to create truly reactive and progressive on-chain assets that reflect a history of interactions and verified milestones.

### Outline & Function Summary:

**I. Core Chronicle Management (ERC-721 base with ChronoForge specific logic)**
*   `forgeNewChronicle`: Mints a new Chronicle, initializing its state and evolutionary parameters.
*   `getCurrentChronicleState`: Retrieves the current evolutionary state of a Chronicle.
*   `isTerminalState`: Checks if a Chronicle has reached its final, immutable state.
*   `_transfer`: Internal transfer logic, ensuring state integrity.

**II. Chronicle Evolution & State Transitions**
*   `advanceChronicleStateByTime`: Progresses a Chronicle's state if its chronological gate threshold is met.
*   `advanceChronicleStateByEvent`: Advances state based on a verified external event hash.
*   `advanceChronicleStateByComputation`: Transitions state upon verification of an off-chain computation result.
*   `provideAttestation`: Allows whitelisted attesters to provide a crucial attestation for a Chronicle, influencing its progress.
*   `rechargeChronicleFlux`: Replenishes a Chronicle's internal 'Flux' balance, essential for its continued evolution.
*   `finalizeChronicle`: Marks a Chronicle as having reached its terminal state, making it immutable.

**III. Flux Resource Management**
*   `depositFlux`: Users can deposit ETH (or a custom token if `IFluxToken` was implemented) to acquire Flux.
*   `withdrawFlux`: Allows users to withdraw their unallocated Flux.
*   `allocateEpochFlux`: Contract owner initiates an epoch for collective Flux contribution towards global tasks.
*   `contributeToEpochFlux`: Users contribute their Flux to the current collective epoch.
*   `claimEpochFluxReward`: Enables participants of a successful epoch to claim rewards.

**IV. Attestation & Oracle Integration**
*   `addWhitelistedAttester`: Allows the contract owner to authorize new attester addresses.
*   `removeWhitelistedAttester`: Revokes attester authorization.
*   `setComputationOracleAddress`: Sets the trusted oracle for verifying computation proofs.
*   `setEventOracleAddress`: Sets the trusted oracle for verifying external event data.

**V. Configuration & Governance (Admin/Advanced)**
*   `setChronologicalGateInterval`: Configures the base time interval for auto-advancing states.
*   `setFluxConsumptionRates`: Adjusts how much Flux is needed for various state transitions.
*   `updateTerminalStateHash`: Allows the owner to define the target hash representing the final state characteristics.
*   `proposeEvolutionTriggerConfig`: Allows a user to propose new configurations for how chronicles evolve (e.g., new event types).
*   `voteOnEvolutionConfigProposal`: Enables designated voters (or owners) to approve/reject proposals.
*   `delegateAttestationAuthority`: Allows a whitelisted attester to temporarily delegate their attestation power to another address.
*   `pauseChronoForge`: Emergency pause function.
*   `unpauseChronoForge`: Unpause function.
*   `emergencyWithdrawFunds`: Allows the owner to withdraw accidentally sent ETH.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol"; // For potential signature verification, though abstracted here.

// Custom Errors for better readability and gas efficiency
error InvalidChronicleID();
error ChronicleNotInCorrectState();
error InsufficientFlux();
error GateNotReached();
error EventHashMismatch();
error ComputationProofInvalid();
error NotWhitelistedAttester();
error AttestationAlreadyProvided();
error ChronicleAlreadyTerminal();
error NotEnoughFluxDeposited();
error NoActiveEpoch();
error EpochAlreadyConcluded();
error UserAlreadyContributed();
error NoContributionsToClaim();
error ProposalNotFound();
error NotEligibleToVote();
error VotePeriodActive();
error VotingPeriodExpired();
error ProposalAlreadyExecuted();
error DelegationAlreadyActive();
error DelegationExpired();

/**
 * @title ChronoForge
 * @dev A smart contract for creating and managing dynamic, evolving digital artifacts (Chronicles)
 *      which are ERC-721 compliant. Chronicles evolve based on time, external events, computation proofs,
 *      and multi-entity attestations, fueled by a unique 'Flux' resource.
 */
contract ChronoForge is ERC721, Ownable, Pausable {
    using ECDSA for bytes32; // Used for potential signature verification from oracles/attesters

    // --- Enums and Structs ---

    enum ChronicleState {
        Embryonic,      // Just minted, waiting for initial conditions
        Incubating,     // Developing, early stages
        Evolving,       // Active evolution phase
        Maturing,       // Nearing completion
        Terminal        // Final, immutable state
    }

    struct Chronicle {
        uint256 id;
        address owner;
        uint256 creationTimestamp;
        ChronicleState currentState;
        uint256 fluxBalance; // Internal resource for this specific Chronicle's evolution
        uint256 lastFluxRechargeTimestamp;

        // Evolution Triggers
        uint256 nextChronologicalGateTimestamp;
        bytes32 requiredEventHash; // Hash of external event data
        bytes32 requiredComputationProofHash; // Hash of computation result proof
        uint256 requiredAttestations;
        uint256 receivedAttestations;
        mapping(address => bool) attestersProvided; // To track who attested

        bytes32 targetTerminalStateHash; // A unique hash representing the characteristics of the final state
        bool isFinalized; // True if reached Terminal state and immutable
    }

    struct EvolutionConfigProposal {
        bytes configData; // ABI-encoded data for the proposed config change
        uint256 creationTimestamp;
        uint256 votingDeadline;
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted;
        bool executed;
        bool approved;
    }

    // --- State Variables ---

    uint256 private _nextTokenId;
    mapping(uint256 => Chronicle) public chronicles;
    mapping(uint256 => bool) public chronicleExists; // To quickly check if an ID is valid

    // Flux Resource
    mapping(address => uint256) public userFluxBalances; // User's general Flux balance
    uint256 public fluxEthRatio; // ETH required per unit of Flux (e.g., 10^18 for 1 ETH per Flux)

    // Attester & Oracle Management
    mapping(address => bool) public isWhitelistedAttester;
    address public computationOracle;
    address public eventOracle;

    // Default Configuration Parameters
    uint256 public defaultChronologicalGateInterval; // Time in seconds for auto-advances
    uint256 public defaultFluxConsumptionPerAdvance;
    uint256 public defaultRequiredAttestations;

    // Collective Flux Epoch
    uint256 public currentEpochId;
    uint256 public epochFluxGoal;
    uint256 public epochFluxCollected;
    uint256 public epochStartTimestamp;
    uint256 public epochDuration;
    bool public epochConcluded;
    mapping(uint256 => mapping(address => uint256)) public epochContributions; // epochId => user => contributedFlux
    mapping(uint256 => uint256) public epochFluxVault; // Stores total collected flux per epoch (could be used for rewards)

    // Proposal System
    uint256 public nextProposalId;
    mapping(uint256 => EvolutionConfigProposal) public evolutionConfigProposals;
    uint256 public proposalVotingPeriod; // Time in seconds for voting

    // Attester Delegation
    struct Delegation {
        address delegator;
        uint256 expirationTimestamp;
    }
    mapping(address => Delegation) public activeDelegations; // delegatee => Delegation details

    // --- Events ---

    event ChronicleForged(uint256 indexed chronicleId, address indexed owner, uint256 creationTimestamp, ChronicleState initialState);
    event ChronicleStateAdvanced(uint256 indexed chronicleId, ChronicleState oldState, ChronicleState newState, string reason);
    event ChronicleFluxRecharged(uint256 indexed chronicleId, uint256 amount, uint256 newBalance);
    event FluxDeposited(address indexed user, uint256 amount);
    event FluxWithdrawn(address indexed user, uint256 amount);
    event AttestationProvided(uint256 indexed chronicleId, address indexed attester, bytes32 attestationHash);
    event ChronicleFinalized(uint256 indexed chronicleId, bytes32 terminalStateHash);
    event WhitelistedAttesterAdded(address indexed attester);
    event WhitelistedAttesterRemoved(address indexed attester);
    event ComputationOracleSet(address indexed newOracle);
    event EventOracleSet(address indexed newOracle);
    event EpochStarted(uint256 indexed epochId, uint256 goal, uint256 duration);
    event EpochContributed(uint256 indexed epochId, address indexed contributor, uint256 amount);
    event EpochConcluded(uint256 indexed epochId, bool success, uint256 totalCollected);
    event EpochRewardClaimed(uint256 indexed epochId, address indexed claimant, uint256 rewardAmount);
    event EvolutionConfigProposalCreated(uint256 indexed proposalId, address indexed proposer, bytes configData);
    event EvolutionConfigProposalVoted(uint256 indexed proposalId, address indexed voter, bool voteFor);
    event EvolutionConfigProposalExecuted(uint256 indexed proposalId, bool approved);
    event AttestationAuthorityDelegated(address indexed delegator, address indexed delegatee, uint256 expirationTimestamp);

    // --- Constructor ---

    constructor(uint256 _fluxEthRatio) ERC721("ChronoForge Chronicle", "CHRONO") Ownable(msg.sender) Pausable() {
        require(_fluxEthRatio > 0, "Flux ratio must be positive");
        fluxEthRatio = _fluxEthRatio; // e.g., 10^18 for 1 ETH per Flux
        defaultChronologicalGateInterval = 7 * 24 * 60 * 60; // 7 days
        defaultFluxConsumptionPerAdvance = 100; // 100 units of Flux
        defaultRequiredAttestations = 3; // 3 attestations needed by default
        proposalVotingPeriod = 5 * 24 * 60 * 60; // 5 days for voting
    }

    // --- Modifiers ---

    modifier onlyWhitelistedAttester() {
        if (!isWhitelistedAttester[msg.sender] && (activeDelegations[msg.sender].delegator == address(0) || activeDelegations[msg.sender].expirationTimestamp < block.timestamp)) {
            revert NotWhitelistedAttester();
        }
        _;
    }

    modifier onlyOracle(address _oracleAddress) {
        require(msg.sender == _oracleAddress, "ChronoForge: Only the designated oracle can call this function");
        _;
    }

    // --- I. Core Chronicle Management ---

    /**
     * @dev Mints a new Chronicle and sets its initial parameters.
     * @param _initialTargetTerminalStateHash A hash representing the desired final characteristics of the Chronicle.
     */
    function forgeNewChronicle(bytes32 _initialTargetTerminalStateHash) public whenNotPaused returns (uint256) {
        _nextTokenId++;
        uint256 newChronicleId = _nextTokenId;

        _safeMint(msg.sender, newChronicleId);

        Chronicle storage newChronicle = chronicles[newChronicleId];
        newChronicle.id = newChronicleId;
        newChronicle.owner = msg.sender;
        newChronicle.creationTimestamp = block.timestamp;
        newChronicle.currentState = ChronicleState.Embryonic;
        newChronicle.fluxBalance = 0; // Starts with no internal flux, needs recharging
        newChronicle.lastFluxRechargeTimestamp = block.timestamp;
        newChronicle.nextChronologicalGateTimestamp = block.timestamp + defaultChronologicalGateInterval;
        newChronicle.requiredAttestations = defaultRequiredAttestations;
        newChronicle.targetTerminalStateHash = _initialTargetTerminalStateHash;
        newChronicle.isFinalized = false;

        chronicleExists[newChronicleId] = true;

        emit ChronicleForged(newChronicleId, msg.sender, block.timestamp, ChronicleState.Embryonic);
        return newChronicleId;
    }

    /**
     * @dev Returns the current evolutionary state of a Chronicle.
     * @param _chronicleId The ID of the Chronicle.
     * @return The current ChronicleState enum value.
     */
    function getCurrentChronicleState(uint256 _chronicleId) public view returns (ChronicleState) {
        if (!chronicleExists[_chronicleId]) revert InvalidChronicleID();
        return chronicles[_chronicleId].currentState;
    }

    /**
     * @dev Checks if a Chronicle has reached its terminal (final and immutable) state.
     * @param _chronicleId The ID of the Chronicle.
     * @return True if the Chronicle is in the Terminal state, false otherwise.
     */
    function isTerminalState(uint256 _chronicleId) public view returns (bool) {
        if (!chronicleExists[_chronicleId]) revert InvalidChronicleID();
        return chronicles[_chronicleId].isFinalized;
    }

    /**
     * @dev Internal ERC721 _transfer hook, can add custom logic if needed.
     *      For ChronoForge, simple transfer is fine, but you could imagine
     *      restrictions based on state or flux.
     */
    function _transfer(address from, address to, uint256 tokenId) internal override(ERC721) {
        // Example custom logic: Prevent transfer if chronicle is in a critical 'evolving' state,
        // or if it has pending requirements from the owner. Not implemented for brevity.
        super._transfer(from, to, tokenId);
    }

    // --- II. Chronicle Evolution & State Transitions ---

    /**
     * @dev Advances a Chronicle's state based on time elapsed and sufficient internal flux.
     *      Can be called by anyone to trigger an advance if conditions are met.
     * @param _chronicleId The ID of the Chronicle to advance.
     */
    function advanceChronicleStateByTime(uint256 _chronicleId) public whenNotPaused {
        Chronicle storage chronicle = chronicles[_chronicleId];
        if (!chronicleExists[_chronicleId]) revert InvalidChronicleID();
        if (chronicle.isFinalized) revert ChronicleAlreadyTerminal();
        if (chronicle.currentState == ChronicleState.Terminal) revert ChronicleAlreadyTerminal();
        if (chronicle.fluxBalance < defaultFluxConsumptionPerAdvance) revert InsufficientFlux();
        if (block.timestamp < chronicle.nextChronologicalGateTimestamp) revert GateNotReached();

        chronicle.fluxBalance -= defaultFluxConsumptionPerAdvance;
        ChronicleState oldState = chronicle.currentState;
        chronicle.currentState = ChronicleState(uint8(chronicle.currentState) + 1); // Move to next state
        chronicle.nextChronologicalGateTimestamp = block.timestamp + defaultChronologicalGateInterval; // Set next gate

        emit ChronicleStateAdvanced(_chronicleId, oldState, chronicle.currentState, "Time-based advancement");
    }

    /**
     * @dev Advances a Chronicle's state based on a verified external event.
     *      This function would typically be called by the `eventOracle`.
     * @param _chronicleId The ID of the Chronicle.
     * @param _eventHash The hash of the external event data that was observed.
     * @param _signature The oracle's signature over the event hash (for verification).
     */
    function advanceChronicleStateByEvent(uint256 _chronicleId, bytes32 _eventHash, bytes memory _signature) public whenNotPaused {
        Chronicle storage chronicle = chronicles[_chronicleId];
        if (!chronicleExists[_chronicleId]) revert InvalidChronicleID();
        if (chronicle.isFinalized) revert ChronicleAlreadyTerminal();
        if (chronicle.fluxBalance < defaultFluxConsumptionPerAdvance) revert InsufficientFlux();
        
        // Verify signature from the trusted eventOracle
        address signer = _eventHash.toEthSignedMessageHash().recover(_signature);
        require(signer == eventOracle, "ChronoForge: Invalid event oracle signature");

        // Check if the provided event hash matches the required one for this state
        // In a real scenario, this would be more complex, e.g., mapping event types to states
        if (chronicle.requiredEventHash == bytes32(0)) {
            revert ChronicleNotInCorrectState(); // No event required for current state
        }
        if (chronicle.requiredEventHash != _eventHash) {
            revert EventHashMismatch();
        }

        chronicle.fluxBalance -= defaultFluxConsumptionPerAdvance;
        ChronicleState oldState = chronicle.currentState;
        chronicle.currentState = ChronicleState(uint8(chronicle.currentState) + 1);
        chronicle.requiredEventHash = bytes32(0); // Reset for next state, if applicable

        emit ChronicleStateAdvanced(_chronicleId, oldState, chronicle.currentState, "Event-based advancement");
    }

    /**
     * @dev Advances a Chronicle's state based on a verified off-chain computation proof.
     *      This function would typically be called by the `computationOracle`.
     * @param _chronicleId The ID of the Chronicle.
     * @param _proofHash The hash of the computation proof (e.g., ZKP, verifiable computation output).
     * @param _signature The oracle's signature over the proof hash.
     */
    function advanceChronicleStateByComputation(uint256 _chronicleId, bytes32 _proofHash, bytes memory _signature) public whenNotPaused {
        Chronicle storage chronicle = chronicles[_chronicleId];
        if (!chronicleExists[_chronicleId]) revert InvalidChronicleID();
        if (chronicle.isFinalized) revert ChronicleAlreadyTerminal();
        if (chronicle.fluxBalance < defaultFluxConsumptionPerAdvance) revert InsufficientFlux();

        // Verify signature from the trusted computationOracle
        address signer = _proofHash.toEthSignedMessageHash().recover(_signature);
        require(signer == computationOracle, "ChronoForge: Invalid computation oracle signature");

        // Check if the provided proof hash matches the required one for this state
        if (chronicle.requiredComputationProofHash == bytes32(0)) {
            revert ChronicleNotInCorrectState(); // No computation required for current state
        }
        if (chronicle.requiredComputationProofHash != _proofHash) {
            revert ComputationProofInvalid();
        }

        chronicle.fluxBalance -= defaultFluxConsumptionPerAdvance;
        ChronicleState oldState = chronicle.currentState;
        chronicle.currentState = ChronicleState(uint8(chronicle.currentState) + 1);
        chronicle.requiredComputationProofHash = bytes32(0); // Reset for next state

        emit ChronicleStateAdvanced(_chronicleId, oldState, chronicle.currentState, "Computation-based advancement");
    }

    /**
     * @dev Allows a whitelisted attester to provide an attestation for a Chronicle.
     *      Once enough attestations are gathered, the Chronicle can potentially advance.
     * @param _chronicleId The ID of the Chronicle to attest to.
     * @param _attestationHash A unique hash representing the attestation data.
     */
    function provideAttestation(uint256 _chronicleId, bytes32 _attestationHash) public onlyWhitelistedAttester whenNotPaused {
        Chronicle storage chronicle = chronicles[_chronicleId];
        if (!chronicleExists[_chronicleId]) revert InvalidChronicleID();
        if (chronicle.isFinalized) revert ChronicleAlreadyTerminal();
        if (chronicle.attestersProvided[msg.sender]) revert AttestationAlreadyProvided();
        if (chronicle.currentState == ChronicleState.Terminal) revert ChronicleAlreadyTerminal();

        chronicle.attestersProvided[msg.sender] = true;
        chronicle.receivedAttestations++;

        emit AttestationProvided(_chronicleId, msg.sender, _attestationHash);

        // If enough attestations are gathered, and other conditions are met, automatically advance
        if (chronicle.receivedAttestations >= chronicle.requiredAttestations && chronicle.fluxBalance >= defaultFluxConsumptionPerAdvance) {
            chronicle.fluxBalance -= defaultFluxConsumptionPerAdvance;
            ChronicleState oldState = chronicle.currentState;
            chronicle.currentState = ChronicleState(uint8(chronicle.currentState) + 1);
            chronicle.receivedAttestations = 0; // Reset for next stage
            // Reset all attestersProvided flags for this chronicle,
            // or consider if attestations should be cumulative across states
            // (current design implies they are per state requirement).
            // For simplicity, we reset the count, implying new set of attestations for next stage.

            emit ChronicleStateAdvanced(_chronicleId, oldState, chronicle.currentState, "Attestation-based advancement");
        }
    }

    /**
     * @dev Replenishes a Chronicle's internal 'Flux' balance, fueling its evolution.
     *      Requires the caller to have sufficient general Flux balance.
     * @param _chronicleId The ID of the Chronicle.
     * @param _amount The amount of Flux to transfer from user's balance to Chronicle.
     */
    function rechargeChronicleFlux(uint256 _chronicleId, uint256 _amount) public whenNotPaused {
        Chronicle storage chronicle = chronicles[_chronicleId];
        if (!chronicleExists[_chronicleId]) revert InvalidChronicleID();
        if (chronicle.owner != msg.sender) revert ERC721InsufficientApproval(msg.sender, chronicle.owner, _chronicleId); // Only owner can recharge, or approved
        if (chronicle.isFinalized) revert ChronicleAlreadyTerminal();
        if (userFluxBalances[msg.sender] < _amount) revert InsufficientFlux();

        userFluxBalances[msg.sender] -= _amount;
        chronicle.fluxBalance += _amount;
        chronicle.lastFluxRechargeTimestamp = block.timestamp;

        emit ChronicleFluxRecharged(_chronicleId, _amount, chronicle.fluxBalance);
    }

    /**
     * @dev Marks a Chronicle as having reached its terminal (final) state, making it immutable.
     *      This can only be done if the Chronicle is in the Maturing state and meets specific criteria.
     * @param _chronicleId The ID of the Chronicle to finalize.
     */
    function finalizeChronicle(uint256 _chronicleId) public whenNotPaused {
        Chronicle storage chronicle = chronicles[_chronicleId];
        if (!chronicleExists[_chronicleId]) revert InvalidChronicleID();
        if (chronicle.owner != msg.sender) revert ERC721InsufficientApproval(msg.sender, chronicle.owner, _chronicleId); // Only owner
        if (chronicle.isFinalized) revert ChronicleAlreadyTerminal();
        if (chronicle.currentState != ChronicleState.Maturing) revert ChronicleNotInCorrectState();

        // Additional checks before finalizing (e.g., all requirements met, target hash matches)
        // For simplicity, we assume Maturing state is enough for now, but in real logic,
        // you might require `chronicle.targetTerminalStateHash` to be reflected by other attributes
        // or external verification that the 'final form' has been achieved.

        chronicle.currentState = ChronicleState.Terminal;
        chronicle.isFinalized = true;

        emit ChronicleFinalized(_chronicleId, chronicle.targetTerminalStateHash);
    }

    // --- III. Flux Resource Management ---

    /**
     * @dev Allows users to deposit ETH to acquire 'Flux'.
     * @dev The actual Flux amount received is determined by `msg.value / fluxEthRatio`.
     */
    function depositFlux() public payable whenNotPaused {
        require(msg.value > 0, "ChronoForge: Must send ETH to deposit Flux");
        uint256 fluxAmount = msg.value / fluxEthRatio;
        require(fluxAmount > 0, "ChronoForge: Insufficient ETH for any Flux");

        userFluxBalances[msg.sender] += fluxAmount;
        emit FluxDeposited(msg.sender, fluxAmount);
    }

    /**
     * @dev Allows users to withdraw their unallocated Flux (converted back to ETH).
     * @param _amount The amount of Flux to withdraw.
     */
    function withdrawFlux(uint256 _amount) public whenNotPaused {
        if (userFluxBalances[msg.sender] < _amount) revert NotEnoughFluxDeposited();

        userFluxBalances[msg.sender] -= _amount;
        uint256 ethAmount = _amount * fluxEthRatio; // Convert back to ETH

        (bool success, ) = payable(msg.sender).call{value: ethAmount}("");
        require(success, "ChronoForge: ETH transfer failed");

        emit FluxWithdrawn(msg.sender, _amount);
    }

    /**
     * @dev Initiates a new epoch for collective Flux contribution towards a global goal.
     *      Only callable by the contract owner.
     * @param _goal The target amount of Flux for this epoch.
     * @param _duration The duration of the epoch in seconds.
     */
    function allocateEpochFlux(uint256 _goal, uint256 _duration) public onlyOwner whenNotPaused {
        require(currentEpochId == 0 || epochConcluded, "ChronoForge: Previous epoch not concluded");
        require(_goal > 0 && _duration > 0, "ChronoForge: Epoch goal and duration must be positive");

        currentEpochId++;
        epochFluxGoal = _goal;
        epochFluxCollected = 0;
        epochStartTimestamp = block.timestamp;
        epochDuration = _duration;
        epochConcluded = false;

        emit EpochStarted(currentEpochId, _goal, _duration);
    }

    /**
     * @dev Allows users to contribute their personal Flux balance to the current collective epoch.
     * @param _amount The amount of Flux to contribute.
     */
    function contributeToEpochFlux(uint256 _amount) public whenNotPaused {
        if (currentEpochId == 0 || epochConcluded || block.timestamp > epochStartTimestamp + epochDuration) revert NoActiveEpoch();
        if (userFluxBalances[msg.sender] < _amount) revert InsufficientFlux();
        if (epochContributions[currentEpochId][msg.sender] > 0) revert UserAlreadyContributed(); // One contribution per user per epoch (can be changed)

        userFluxBalances[msg.sender] -= _amount;
        epochFluxCollected += _amount;
        epochContributions[currentEpochId][msg.sender] += _amount; // Track individual contributions

        // Store the contributed flux in an escrow-like vault for the epoch
        epochFluxVault[currentEpochId] += _amount;

        emit EpochContributed(currentEpochId, msg.sender, _amount);

        if (epochFluxCollected >= epochFluxGoal) {
            epochConcluded = true;
            emit EpochConcluded(currentEpochId, true, epochFluxCollected);
        }
    }

    /**
     * @dev Allows participants of a successful epoch to claim rewards based on their contribution.
     *      Rewards are distributed after the epoch concludes and goal is met.
     *      This is a placeholder for reward distribution logic (e.g., distributing specific NFTs, tokens, or a share of collected flux).
     *      For simplicity, it just transfers some 'reward' amount of flux back.
     */
    function claimEpochFluxReward(uint256 _epochId) public whenNotPaused {
        if (_epochId == 0 || _epochId > currentEpochId) revert NoActiveEpoch(); // Invalid epoch ID
        if (!epochConcluded && (block.timestamp < epochStartTimestamp + epochDuration)) revert EpochAlreadyConcluded(); // Epoch not yet concluded/successful
        if (epochContributions[_epochId][msg.sender] == 0) revert NoContributionsToClaim();

        uint256 contributed = epochContributions[_epochId][msg.sender];
        // Simple reward: 10% of contribution for meeting goal, plus prorated share if over goal.
        // This is a placeholder; real reward logic would be more complex.
        uint256 rewardAmount = (contributed * 110) / 100; // 10% bonus if epoch was successful
        
        // Ensure there's enough flux in the vault to pay out (e.g., from external funding or collected over goal)
        // In a real system, the `epochFluxVault` would typically be used as the reward pool.
        // For simplicity, we assume the contract can generate this reward or it comes from `epochFluxCollected`
        // if rewards are a portion of collected.
        require(epochFluxVault[_epochId] >= rewardAmount, "ChronoForge: Insufficient epoch vault for reward");

        userFluxBalances[msg.sender] += rewardAmount;
        epochFluxVault[_epochId] -= rewardAmount; // Deduct from the epoch vault

        // Zero out contribution for this user to prevent double claiming
        epochContributions[_epochId][msg.sender] = 0;

        emit EpochRewardClaimed(_epochId, msg.sender, rewardAmount);
    }


    // --- IV. Attestation & Oracle Integration ---

    /**
     * @dev Adds an address to the whitelist of authorized attesters. Only owner can call.
     * @param _attester Address to whitelist.
     */
    function addWhitelistedAttester(address _attester) public onlyOwner {
        require(_attester != address(0), "ChronoForge: Zero address cannot be whitelisted attester");
        isWhitelistedAttester[_attester] = true;
        emit WhitelistedAttesterAdded(_attester);
    }

    /**
     * @dev Removes an address from the whitelist of authorized attesters. Only owner can call.
     * @param _attester Address to remove.
     */
    function removeWhitelistedAttester(address _attester) public onlyOwner {
        require(_attester != address(0), "ChronoForge: Zero address cannot be removed");
        isWhitelistedAttester[_attester] = false;
        // Also remove any active delegations by this attester
        if (activeDelegations[_attester].delegator != address(0)) {
            delete activeDelegations[_attester]; // Deactivate any delegation where _attester is the delegatee
        }
        emit WhitelistedAttesterRemoved(_attester);
    }

    /**
     * @dev Sets the address of the trusted oracle responsible for verifying computation proofs. Only owner can call.
     * @param _oracleAddress The address of the computation oracle.
     */
    function setComputationOracleAddress(address _oracleAddress) public onlyOwner {
        require(_oracleAddress != address(0), "ChronoForge: Zero address cannot be oracle");
        computationOracle = _oracleAddress;
        emit ComputationOracleSet(_oracleAddress);
    }

    /**
     * @dev Sets the address of the trusted oracle responsible for verifying external event data. Only owner can call.
     * @param _oracleAddress The address of the event oracle.
     */
    function setEventOracleAddress(address _oracleAddress) public onlyOwner {
        require(_oracleAddress != address(0), "ChronoForge: Zero address cannot be oracle");
        eventOracle = _oracleAddress;
        emit EventOracleSet(_oracleAddress);
    }

    // --- V. Configuration & Governance (Admin/Advanced) ---

    /**
     * @dev Sets the default time interval required for Chronicles to advance via chronological gates. Only owner.
     * @param _intervalSeconds New interval in seconds.
     */
    function setChronologicalGateInterval(uint256 _intervalSeconds) public onlyOwner {
        require(_intervalSeconds > 0, "ChronoForge: Interval must be positive");
        defaultChronologicalGateInterval = _intervalSeconds;
    }

    /**
     * @dev Adjusts the default amount of Flux consumed for each state transition. Only owner.
     * @param _rate New Flux consumption rate.
     */
    function setFluxConsumptionRates(uint256 _rate) public onlyOwner {
        require(_rate > 0, "ChronoForge: Rate must be positive");
        defaultFluxConsumptionPerAdvance = _rate;
    }

    /**
     * @dev Allows the owner to define or update the target hash representing the final immutable state characteristics
     *      for new Chronicles, or for a specific range if implemented.
     *      Note: Existing chronicles will retain their set target hashes unless explicitly updated.
     * @param _newTerminalStateHash The new hash for future chronicles.
     */
    function updateTerminalStateHash(bytes32 _newTerminalStateHash) public onlyOwner {
        // This function sets a *default* for new chronicles.
        // Updating existing chronicles' target hashes would require iterating or specific chronicle ID input.
        // For simplicity, this acts as a global setting for newly forged chronicles.
        // `chronicles[id].targetTerminalStateHash = _newTerminalStateHash;` for specific chronicle.
        // Potentially, an event `DefaultTerminalStateHashUpdated(_newTerminalStateHash);`
    }

    /**
     * @dev Allows any user to propose a new configuration for how chronicles evolve.
     *      This could be for new states, new event types, or new attestation requirements.
     *      Requires a governance mechanism to execute.
     * @param _configData ABI-encoded data representing the proposed configuration change.
     */
    function proposeEvolutionTriggerConfig(bytes calldata _configData) public whenNotPaused returns (uint256) {
        nextProposalId++;
        uint256 proposalId = nextProposalId;

        EvolutionConfigProposal storage proposal = evolutionConfigProposals[proposalId];
        proposal.configData = _configData;
        proposal.creationTimestamp = block.timestamp;
        proposal.votingDeadline = block.timestamp + proposalVotingPeriod;
        proposal.votesFor = 0;
        proposal.votesAgainst = 0;
        proposal.executed = false;
        proposal.approved = false;

        emit EvolutionConfigProposalCreated(proposalId, msg.sender, _configData);
        return proposalId;
    }

    /**
     * @dev Enables whitelisted attesters (or other designated voters) to vote on a proposal.
     * @param _proposalId The ID of the proposal.
     * @param _voteFor True for 'yes', false for 'no'.
     */
    function voteOnEvolutionConfigProposal(uint256 _proposalId, bool _voteFor) public onlyWhitelistedAttester whenNotPaused {
        EvolutionConfigProposal storage proposal = evolutionConfigProposals[_proposalId];
        if (proposal.creationTimestamp == 0) revert ProposalNotFound();
        if (proposal.hasVoted[msg.sender]) revert UserAlreadyContributed(); // HasVoted for proposal
        if (block.timestamp > proposal.votingDeadline) revert VotingPeriodExpired();
        if (proposal.executed) revert ProposalAlreadyExecuted();

        if (_voteFor) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }
        proposal.hasVoted[msg.sender] = true;

        emit EvolutionConfigProposalVoted(_proposalId, msg.sender, _voteFor);
    }

    /**
     * @dev Executes an approved proposal after its voting period has ended. Only owner can call.
     *      This function demonstrates the *execution* step. The actual logic to apply `_configData`
     *      would be complex and depend on the format of `_configData`.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeEvolutionConfigProposal(uint256 _proposalId) public onlyOwner {
        EvolutionConfigProposal storage proposal = evolutionConfigProposals[_proposalId];
        if (proposal.creationTimestamp == 0) revert ProposalNotFound();
        if (block.timestamp <= proposal.votingDeadline) revert VotePeriodActive();
        if (proposal.executed) revert ProposalAlreadyExecuted();

        // Simple majority voting for execution
        if (proposal.votesFor > proposal.votesAgainst) {
            // In a real system, you'd parse `proposal.configData` and apply changes here.
            // Example: If _configData encodes `setFluxConsumptionRates(newRate)`, then call that.
            // This would require a sophisticated ABI decoding and dispatching mechanism.
            // For this example, we just mark it as approved and executed.
            proposal.approved = true;
            proposal.executed = true;
            emit EvolutionConfigProposalExecuted(_proposalId, true);
        } else {
            proposal.approved = false;
            proposal.executed = true;
            emit EvolutionConfigProposalExecuted(_proposalId, false);
        }
    }

    /**
     * @dev Allows a whitelisted attester to temporarily delegate their attestation authority.
     * @param _delegatee The address to which authority is delegated.
     * @param _duration The duration in seconds for which the delegation is active.
     */
    function delegateAttestationAuthority(address _delegatee, uint256 _duration) public onlyWhitelistedAttester {
        require(_delegatee != address(0), "ChronoForge: Cannot delegate to zero address");
        require(_duration > 0, "ChronoForge: Delegation duration must be positive");
        require(!isWhitelistedAttester[_delegatee], "ChronoForge: Delegatee is already a whitelisted attester");
        
        // Prevent re-delegating without expiration, or delegating if already a delegatee
        if (activeDelegations[msg.sender].delegator != address(0)) {
            revert DelegationAlreadyActive(); // Or allow re-delegation if time permits
        }

        activeDelegations[_delegatee] = Delegation({
            delegator: msg.sender,
            expirationTimestamp: block.timestamp + _duration
        });

        emit AttestationAuthorityDelegated(msg.sender, _delegatee, block.timestamp + _duration);
    }

    /**
     * @dev Pauses the contract, preventing most state-changing operations. Only owner.
     */
    function pauseChronoForge() public onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract, allowing operations to resume. Only owner.
     */
    function unpauseChronoForge() public onlyOwner {
        _unpause();
    }

    /**
     * @dev Allows the owner to withdraw any accidentally sent ETH to the contract.
     *      Does not affect the Flux system's balance which is distinct.
     * @param _amount The amount of ETH to withdraw.
     */
    function emergencyWithdrawFunds(uint256 _amount) public onlyOwner {
        require(address(this).balance >= _amount, "ChronoForge: Insufficient contract balance");
        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        require(success, "ChronoForge: ETH withdrawal failed");
    }

    // --- View Functions (Not counted in the 20+, these are helpers) ---
    function getChronicleDetails(uint256 _chronicleId)
        public
        view
        returns (
            uint256 id,
            address owner,
            uint256 creationTimestamp,
            ChronicleState currentState,
            uint256 fluxBalance,
            uint256 lastFluxRechargeTimestamp,
            uint256 nextChronologicalGateTimestamp,
            bytes32 requiredEventHash,
            bytes32 requiredComputationProofHash,
            uint256 requiredAttestations,
            uint256 receivedAttestations,
            bytes32 targetTerminalStateHash,
            bool isFinalized
        )
    {
        Chronicle storage chronicle = chronicles[_chronicleId];
        if (!chronicleExists[_chronicleId]) revert InvalidChronicleID();
        return (
            chronicle.id,
            chronicle.owner,
            chronicle.creationTimestamp,
            chronicle.currentState,
            chronicle.fluxBalance,
            chronicle.lastFluxRechargeTimestamp,
            chronicle.nextChronologicalGateTimestamp,
            chronicle.requiredEventHash,
            chronicle.requiredComputationProofHash,
            chronicle.requiredAttestations,
            chronicle.receivedAttestations,
            chronicle.targetTerminalStateHash,
            chronicle.isFinalized
        );
    }

    function getProposalDetails(uint256 _proposalId)
        public
        view
        returns (
            bytes memory configData,
            uint256 creationTimestamp,
            uint256 votingDeadline,
            uint256 votesFor,
            uint256 votesAgainst,
            bool executed,
            bool approved
        )
    {
        EvolutionConfigProposal storage proposal = evolutionConfigProposals[_proposalId];
        if (proposal.creationTimestamp == 0) revert ProposalNotFound();
        return (
            proposal.configData,
            proposal.creationTimestamp,
            proposal.votingDeadline,
            proposal.votesFor,
            proposal.votesAgainst,
            proposal.executed,
            proposal.approved
        );
    }
}
```