Okay, let's design an interesting, advanced smart contract concept.

**Concept:** **OmniChainPulse**

This contract simulates a dynamic, interconnected system ("The Pulse") represented by non-fungible tokens ("Pulse Fragments") on this specific chain. The Pulse has global properties influenced by actions *on this chain* and potentially *other chains* (simulated via cross-chain messaging interaction points), as well as complex external data (like AI simulations or ZK proof results relayed by oracles). Each Pulse Fragment NFT has properties that change based on user interaction and the global Pulse state.

**Advanced Concepts Used:**

1.  **Dynamic NFTs:** NFT properties (`energy`, `resonance`, `integrity`) are not static metadata but change based on contract logic, global state, and external inputs.
2.  **Simulated Cross-Chain Interaction:** The contract includes entry points (`receiveCrossChainMessage`) and exit points (`sendCrossChainPulseSignal`) that *simulate* integration with a cross-chain messaging protocol (like LayerZero, Chainlink CCIP, etc.). It reacts to messages from other chains and can trigger messages.
3.  **Oracle/External Data Integration:** Specific functions are designed to receive data from trusted oracles representing complex off-chain computation (e.g., AI simulation results affecting global state, verification of a ZK proof affecting a fragment).
4.  **Epoch-Based State Transitions:** The Pulse operates in epochs, and key parameters or rules might change during epoch transitions.
5.  **Complex Interdependencies:** Local Fragment actions affect global Pulse state, global Pulse state affects local Fragments, and external inputs (including cross-chain) affect both.
6.  **Modular Interaction Points:** Clearly defined functions for different types of external inputs (Oracle, AI, ZK, Cross-Chain).

**Outline & Function Summary:**

```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Contract Name: OmniChainPulse

// --- Outline ---
// 1. Imports (ERC721, Ownable, Pausable, ReentrancyGuard)
// 2. Errors
// 3. Events
// 4. Structs (GlobalPulseState, FragmentState)
// 5. State Variables (Ownership, Pausing, Oracles, Cross-Chain Config, Pulse State, Fragment Data, Epoch Info, NFT Counter)
// 6. Modifiers (onlyOracle, onlyAIOracle, onlyZKVerifier, onlyCrossChainMessenger)
// 7. Constructor
// 8. Core Interaction Functions (User Actions)
//    - mintFragment: Mints a new Pulse Fragment NFT.
//    - attuneFragment: User action to increase fragment resonance (may cost tokens).
//    - stabilizeFragment: User action to increase fragment integrity (may require condition).
//    - amplifyPulse: User action contributing to global pulse intensity.
//    - resonateGlobally: User action potentially triggering a cross-chain signal.
// 9. Oracle/External Data Input Functions (Called by authorized external systems)
//    - updateGlobalPulseFromOracle: Update global parameters based on general oracle feed.
//    - processAIResults: Apply results from an off-chain AI simulation.
//    - submitZKProofResult: Validate and apply a state change based on a ZK proof verification result.
// 10. Cross-Chain Interaction Functions (Simulated)
//    - receiveCrossChainMessage: Endpoint for receiving messages from other chains.
//    - sendCrossChainPulseSignal: Internal/Admin function to trigger sending a signal cross-chain.
// 11. State Query Functions (View/Pure)
//    - getFragmentState: Get the current properties of a specific fragment.
//    - getGlobalPulseState: Get the current global pulse parameters.
//    - calculateDynamicFragmentProperty: Calculate a derived property based on current states.
//    - tokenURI: ERC721 standard, returns dynamic metadata URI.
// 12. Epoch Management Functions
//    - triggerEpochTransition: Admin function to advance to the next epoch.
//    - claimEpochReward: Users claim rewards based on fragment state at epoch end.
// 13. Admin & Configuration Functions
//    - togglePause: Pause/Unpause contract interactions.
//    - setOracleAddress: Set address for general oracle.
//    - setAIOracleAddress: Set address for AI oracle.
//    - setZKVerifierAddress: Set address for ZK verifier relay.
//    - setCrossChainMessenger: Set address for cross-chain messaging contract.
//    - registerCrossChainEndpoint: Register a valid destination chain ID for signals.
//    - withdrawERC20: Withdraw accidental ERC20 tokens.
//    - withdrawETH: Withdraw accidental ETH.
// 14. ERC721 Standard Functions (Inherited/Overridden)
//    - balanceOf
//    - ownerOf
//    - approve
//    - getApproved
//    - setApprovalForAll
//    - isApprovedForAll
//    - transferFrom
//    - safeTransferFrom

// --- Function Summary ---

// mintFragment(address to): Mints a new Pulse Fragment for 'to' with initial state.
// attuneFragment(uint256 tokenId, uint256 tuneAmount): Increases tokenId's resonance by tuneAmount, potentially costing sender tokens.
// stabilizeFragment(uint256 tokenId): Increases tokenId's integrity, requires certain conditions to be met by sender.
// amplifyPulse(uint256 amount): Contributes 'amount' to the global pulse intensity.
// resonateGlobally(uint256 tokenId): Triggers a potential cross-chain signal related to this fragment.
// updateGlobalPulseFromOracle(uint64 newFrequency, uint64 newIntensity, uint64 newStability): Updates global pulse state; callable only by oracleAddress.
// processAIResults(uint256[] tokenIds, int256[] energyChanges, int256[] resonanceChanges): Applies AI-simulated changes to specified fragments; callable only by aiOracleAddress.
// submitZKProofResult(address prover, bytes32 proofHash, uint256 relatedTokenId, uint256 stateDelta): Applies a state change to a fragment if proofHash is valid for prover/relatedTokenId; callable only by zkVerifierAddress.
// receiveCrossChainMessage(uint16 sourceChainId, bytes memory message): Processes a message received from another chain; callable only by crossChainMessenger.
// sendCrossChainPulseSignal(uint16 destChainId, uint256 tokenId, bytes memory data): Internal/Admin function to trigger sending a message via messenger.
// getFragmentState(uint256 tokenId): View function to get the current state of a fragment.
// getGlobalPulseState(): View function to get the current global pulse state.
// calculateDynamicFragmentProperty(uint256 tokenId, uint8 propertyType): Pure/View function calculating a derived property (e.g., "sync score") based on global and local states. propertyType can be an enum {SyncScore, StabilityIndex, etc.}
// tokenURI(uint256 tokenId): Returns the URI pointing to the dynamic metadata for tokenId.
// triggerEpochTransition(uint256 newEpochNumber): Advances the system to a new epoch; callable by owner. Resets/updates epoch-specific states.
// claimEpochReward(uint256 tokenId): Allows fragment owner to claim rewards based on tokenId's state in the *previous* epoch.
// togglePause(): Toggles the Paused state of the contract; callable by owner.
// setOracleAddress(address _oracleAddress): Sets the authorized oracle address.
// setAIOracleAddress(address _aiOracleAddress): Sets the authorized AI oracle address.
// setZKVerifierAddress(address _zkVerifierAddress): Sets the authorized ZK verifier relay address.
// setCrossChainMessenger(address _crossChainMessenger): Sets the authorized cross-chain messenger address.
// registerCrossChainEndpoint(uint16 chainId, bool enabled): Registers/deregisters a chain ID as a valid target for cross-chain signals.
// withdrawERC20(address tokenAddress, uint256 amount): Allows owner to withdraw accidental ERC20 tokens.
// withdrawETH(uint256 amount): Allows owner to withdraw accidental ETH.
// balanceOf(address owner): ERC721 standard.
// ownerOf(uint256 tokenId): ERC721 standard.
// approve(address to, uint256 tokenId): ERC721 standard.
// getApproved(uint256 tokenId): ERC721 standard.
// setApprovalForAll(address operator, bool approved): ERC721 standard.
// isApprovedForAll(address owner, address operator): ERC721 standard.
// transferFrom(address from, address to, uint256 tokenId): ERC721 standard.
// safeTransferFrom(address from, address to, uint256 tokenId): ERC721 standard (both versions).

```

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// --- Outline ---
// 1. Imports (ERC721, Ownable, Pausable, ReentrancyGuard)
// 2. Errors
// 3. Events
// 4. Structs (GlobalPulseState, FragmentState)
// 5. State Variables (Ownership, Pausing, Oracles, Cross-Chain Config, Pulse State, Fragment Data, Epoch Info, NFT Counter)
// 6. Modifiers (onlyOracle, onlyAIOracle, onlyZKVerifier, onlyCrossChainMessenger)
// 7. Constructor
// 8. Core Interaction Functions (User Actions)
//    - mintFragment
//    - attuneFragment
//    - stabilizeFragment
//    - amplifyPulse
//    - resonateGlobally
// 9. Oracle/External Data Input Functions (Called by authorized external systems)
//    - updateGlobalPulseFromOracle
//    - processAIResults
//    - submitZKProofResult
// 10. Cross-Chain Interaction Functions (Simulated)
//    - receiveCrossChainMessage
//    - sendCrossChainPulseSignal (Internal/Admin)
// 11. State Query Functions (View/Pure)
//    - getFragmentState
//    - getGlobalPulseState
//    - calculateDynamicFragmentProperty
//    - tokenURI
// 12. Epoch Management Functions
//    - triggerEpochTransition
//    - claimEpochReward
// 13. Admin & Configuration Functions
//    - togglePause
//    - setOracleAddress
//    - setAIOracleAddress
//    - setZKVerifierAddress
//    - setCrossChainMessenger
//    - registerCrossChainEndpoint
//    - withdrawERC20
//    - withdrawETH
// 14. ERC721 Standard Functions (Inherited/Overridden)
//    - balanceOf
//    - ownerOf
//    - approve
//    - getApproved
//    - setApprovalForAll
//    - isApprovedForAll
//    - transferFrom
//    - safeTransferFrom

// --- Function Summary ---

// mintFragment(address to): Mints a new Pulse Fragment for 'to' with initial state.
// attuneFragment(uint256 tokenId, uint256 tuneAmount): Increases tokenId's resonance by tuneAmount, potentially costing sender tokens.
// stabilizeFragment(uint256 tokenId): Increases tokenId's integrity, requires certain conditions to be met by sender.
// amplifyPulse(uint256 amount): Contributes 'amount' to the global pulse intensity.
// resonateGlobally(uint256 tokenId): Triggers a potential cross-chain signal related to this fragment.
// updateGlobalPulseFromOracle(uint64 newFrequency, uint64 newIntensity, uint64 newStability): Updates global pulse state; callable only by oracleAddress.
// processAIResults(uint256[] tokenIds, int256[] energyChanges, int256[] resonanceChanges): Applies AI-simulated changes to specified fragments; callable only by aiOracleAddress.
// submitZKProofResult(address prover, bytes32 proofHash, uint256 relatedTokenId, uint256 stateDelta): Applies a state change to a fragment if proofHash is valid for prover/relatedTokenId; callable only by zkVerifierAddress.
// receiveCrossChainMessage(uint16 sourceChainId, bytes memory message): Processes a message received from another chain; callable only by crossChainMessenger.
// sendCrossChainPulseSignal(uint16 destChainId, uint256 tokenId, bytes memory data): Internal/Admin function to trigger sending a message via messenger.
// getFragmentState(uint256 tokenId): View function to get the current state of a fragment.
// getGlobalPulseState(): View function to get the current global pulse state.
// calculateDynamicFragmentProperty(uint256 tokenId, uint8 propertyType): Pure/View function calculating a derived property (e.g., "sync score") based on global and local states. propertyType can be an enum {SyncScore, StabilityIndex, etc.}
// tokenURI(uint256 tokenId): Returns the URI pointing to the dynamic metadata for tokenId.
// triggerEpochTransition(uint256 newEpochNumber): Advances the system to a new epoch; callable by owner. Resets/updates epoch-specific states.
// claimEpochReward(uint256 tokenId): Allows fragment owner to claim rewards based on tokenId's state in the *previous* epoch.
// togglePause(): Toggles the Paused state of the contract; callable by owner.
// setOracleAddress(address _oracleAddress): Sets the authorized general oracle address.
// setAIOracleAddress(address _aiOracleAddress): Sets the authorized AI oracle address.
// setZKVerifierAddress(address _zkVerifierAddress): Sets the authorized ZK verifier relay address.
// setCrossChainMessenger(address _crossChainMessenger): Sets the authorized cross-chain messaging contract address.
// registerCrossChainEndpoint(uint16 chainId, bool enabled): Registers/deregisters a chain ID as a valid target for cross-chain signals.
// withdrawERC20(address tokenAddress, uint256 amount): Allows owner to withdraw accidental ERC20 tokens.
// withdrawETH(uint256 amount): Allows owner to withdraw accidental ETH.
// balanceOf(address owner): ERC721 standard.
// ownerOf(uint256 tokenId): ERC721 standard.
// approve(address to, uint256 tokenId): ERC721 standard.
// getApproved(uint256 tokenId): ERC721 standard.
// setApprovalForAll(address operator, bool approved): ERC721 standard.
// isApprovedForAll(address owner, address operator): ERC721 standard.
// transferFrom(address from, address to, uint256 tokenId): ERC721 standard.
// safeTransferFrom(address from, address to, uint256 tokenId): ERC721 standard (both versions).


contract OmniChainPulse is ERC721, Ownable, Pausable, ReentrancyGuard {

    // --- Errors ---
    error UnauthorizedOracle();
    error UnauthorizedAIOracle();
    error UnauthorizedZKVerifier();
    error UnauthorizedCrossChainMessenger();
    error FragmentDoesNotExist();
    error InvalidTuneAmount();
    error InsufficientBalanceForTune(); // Example error if tune costs tokens
    error StabilizationConditionNotMet(); // Example condition
    error InvalidArrayLength(); // For batch updates
    error InvalidCrossChainMessage(); // For malformed incoming messages
    error CrossChainEndpointNotRegistered(); // For unregistered outgoing targets
    error NothingToClaim(); // For epoch rewards
    error EpochNotEnded(); // For epoch rewards
    error InvalidPropertyType(); // For calculateDynamicFragmentProperty

    // --- Events ---
    event FragmentMinted(uint256 indexed tokenId, address indexed owner);
    event FragmentStateUpdated(uint256 indexed tokenId, uint64 energy, uint64 resonance, uint64 integrity);
    event GlobalPulseUpdated(uint64 frequency, uint64 intensity, uint64 stability);
    event PulseAmplified(address indexed sender, uint256 amount);
    event GlobalResonanceTriggered(uint256 indexed tokenId, uint16 indexed destChainId);
    event OracleDataProcessed(bytes32 indexed dataHash); // Generic event for oracle updates
    event AIResultsProcessed(bytes32 indexed resultsHash); // Specific for AI
    event ZKProofResultProcessed(bytes32 indexed proofHash, uint256 indexed relatedTokenId); // Specific for ZK
    event CrossChainMessageReceived(uint16 indexed sourceChainId, bytes32 indexed messageHash);
    event CrossChainSignalSent(uint16 indexed destChainId, uint256 indexed tokenId, bytes32 indexed dataHash);
    event EpochTransitioned(uint256 indexed newEpoch, uint256 timestamp);
    event EpochRewardClaimed(uint256 indexed tokenId, uint256 epoch, uint256 rewardAmount);
    event CrossChainEndpointRegistered(uint16 indexed chainId, bool enabled);

    // --- Structs ---
    struct GlobalPulseState {
        uint64 frequency; // How often it 'pulses' - could affect decay/growth rates
        uint64 intensity; // Overall power/magnitude
        uint64 stability; // Resistance to negative fluctuations
        uint256 lastUpdateTime;
        uint256 lastAmplificationTime;
        // Add other global parameters as needed
    }

    struct FragmentState {
        uint64 energy;      // Fuel/lifeforce of the fragment
        uint64 resonance;   // Ability to sync with the global pulse / other fragments
        uint64 integrity;   // Resilience against decay or external shocks
        uint256 lastInteractionTime; // Timestamp of last user interaction
        uint256 mintedEpoch; // Epoch when the fragment was minted
        // Add other fragment-specific dynamic parameters
    }

    struct EpochInfo {
        uint256 currentEpoch;
        uint256 epochStartTime;
        uint256 epochEndTime; // 0 if epoch is ongoing
        // Add epoch-specific rules or states here
        mapping(uint256 => uint256) rewardsClaimedInEpoch; // tokenId => epoch rewards claimed
    }

    // --- State Variables ---
    address private oracleAddress;
    address private aiOracleAddress;
    address private zkVerifierAddress; // Address authorized to relay ZK proof results
    address private crossChainMessenger; // Address of the cross-chain messaging contract (e.g., LayerZero, CCIP)

    GlobalPulseState public globalPulse;
    mapping(uint256 => FragmentState) private fragmentStates;
    uint256 private _nextTokenId; // Counter for unique NFTs

    EpochInfo public epochInfo;

    mapping(uint16 => bool) public registeredCrossChainEndpoints; // chainId => is_registered

    // Example: Token required for tuning
    IERC20 private tuningToken;
    uint256 private tuningCostPerResonanceUnit = 1e18; // Example cost (1 token per unit)

    // --- Modifiers ---
    modifier onlyOracle() {
        if (msg.sender != oracleAddress) revert UnauthorizedOracle();
        _;
    }

    modifier onlyAIOracle() {
        if (msg.sender != aiOracleAddress) revert UnauthorizedAIOracle();
        _;
    }

    modifier onlyZKVerifier() {
        if (msg.sender != zkVerifierAddress) revert UnauthorizedZKVerifier();
        _;
    }

    modifier onlyCrossChainMessenger() {
        if (msg.sender != crossChainMessenger) revert UnauthorizedCrossChainMessenger();
        _;
    }

    // --- Constructor ---
    constructor(address _oracle, address _aiOracle, address _zkVerifier, address _crossChainMessenger, address _tuningToken)
        ERC721("OmniChainPulseFragment", "OCPF")
        Ownable(msg.sender)
        Pausable()
    {
        oracleAddress = _oracle;
        aiOracleAddress = _aiOracle;
        zkVerifierAddress = _zkVerifier;
        crossChainMessenger = _crossChainMessenger;
        tuningToken = IERC20(_tuningToken);

        // Initial Global Pulse State
        globalPulse = GlobalPulseState({
            frequency: 100,
            intensity: 500,
            stability: 75,
            lastUpdateTime: block.timestamp,
            lastAmplificationTime: block.timestamp
        });

        // Initial Epoch Info
        epochInfo.currentEpoch = 1;
        epochInfo.epochStartTime = block.timestamp;
        epochInfo.epochEndTime = 0; // Ongoing

        _nextTokenId = 1; // Start token IDs from 1
    }

    // --- Core Interaction Functions (User Actions) ---

    /// @notice Mints a new Pulse Fragment NFT for the specified address.
    /// @param to The address to mint the fragment to.
    /// @return The ID of the newly minted fragment.
    function mintFragment(address to) public whenNotPaused returns (uint256) {
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);

        // Initial Fragment State
        fragmentStates[tokenId] = FragmentState({
            energy: 1000,
            resonance: 100,
            integrity: 500,
            lastInteractionTime: block.timestamp,
            mintedEpoch: epochInfo.currentEpoch
        });

        emit FragmentMinted(tokenId, to);
        emit FragmentStateUpdated(tokenId, 1000, 100, 500); // Initial state event
        return tokenId;
    }

    /// @notice User action to increase a fragment's resonance. May cost tuning tokens.
    /// @param tokenId The ID of the fragment to attune.
    /// @param tuneAmount The amount to increase resonance by.
    function attuneFragment(uint256 tokenId, uint256 tuneAmount) public payable whenNotPaused nonReentrant {
        if (ownerOf(tokenId) != msg.sender) revert ERC721InsufficientApproval(msg.sender, tokenId); // Or custom error
        if (tuneAmount == 0) revert InvalidTuneAmount();
        if (!fragmentStates[tokenId].integrity > 0) revert FragmentDoesNotExist(); // Basic check

        // Example: Cost based on tuneAmount and tuning token
        uint256 cost = tuneAmount * tuningCostPerResonanceUnit;
        if (tuningToken.balanceOf(msg.sender) < cost) revert InsufficientBalanceForTune();
        // Transfer tokens (requires allowance or direct ETH payment if using ETH)
        // Assuming ERC20:
        if (!tuningToken.transferFrom(msg.sender, address(this), cost)) {
             // Handle transfer failure, maybe revert or log
             revert InsufficientBalanceForTune(); // Or a more specific error
        }

        fragmentStates[tokenId].resonance += uint64(tuneAmount); // Add logic to handle overflow if necessary
        fragmentStates[tokenId].lastInteractionTime = block.timestamp;

        // Resonance increase *could* slightly affect global intensity (example)
        globalPulse.intensity += uint64(tuneAmount / 10); // Simplified impact

        emit FragmentStateUpdated(tokenId, fragmentStates[tokenId].energy, fragmentStates[tokenId].resonance, fragmentStates[tokenId].integrity);
        emit GlobalPulseUpdated(globalPulse.frequency, globalPulse.intensity, globalPulse.stability);
    }

    /// @notice User action to increase a fragment's integrity. Requires specific conditions.
    /// @param tokenId The ID of the fragment to stabilize.
    function stabilizeFragment(uint256 tokenId) public whenNotPaused nonReentrant {
        if (ownerOf(tokenId) != msg.sender) revert ERC721InsufficientApproval(msg.sender, tokenId);
        if (!fragmentStates[tokenId].integrity > 0) revert FragmentDoesNotExist(); // Basic check

        // --- Example Condition: Must hold a specific other NFT or meet a time lock ---
        // This is a placeholder. Replace with actual condition checks.
        bool conditionMet = (block.timestamp - fragmentStates[tokenId].lastInteractionTime) > 1 days; // Example: cannot stabilize too frequently
        // conditionMet = conditionMet && checkUserHoldsSpecificItem(msg.sender); // Example: Requires holding another token

        if (!conditionMet) revert StabilizationConditionNotMet();
        // --- End Example Condition ---

        // Increase integrity (add logic to handle limits or costs)
        fragmentStates[tokenId].integrity += 50; // Example fixed increase
        if (fragmentStates[tokenId].integrity > 1000) fragmentStates[tokenId].integrity = 1000; // Example cap
        fragmentStates[tokenId].lastInteractionTime = block.timestamp;

        // Integrity increase *could* slightly affect global stability (example)
        globalPulse.stability += 1; // Simplified impact
        if (globalPulse.stability > 100) globalPulse.stability = 100; // Example cap

        emit FragmentStateUpdated(tokenId, fragmentStates[tokenId].energy, fragmentStates[tokenId].resonance, fragmentStates[tokenId].integrity);
        emit GlobalPulseUpdated(globalPulse.frequency, globalPulse.intensity, globalPulse.stability);
    }

    /// @notice User action to contribute to the global pulse intensity.
    /// @param amount The amount to contribute (could be in native ETH or an ERC20).
    function amplifyPulse(uint256 amount) public payable whenNotPaused nonReentrant {
         if (amount == 0) revert InvalidTuneAmount(); // Reusing error, or define new one

         // Example: Contribution requires sending ETH or a specific ERC20
         // Assuming ETH for simplicity in this example:
         if (msg.value < amount) revert InsufficientBalanceForTune(); // Reusing error

         // Add logic to process the contribution (e.g., lock ETH, assign to a fund)
         // For now, just update global state and emit event
         globalPulse.intensity += uint64(amount / 100); // Simplified impact
         globalPulse.lastAmplificationTime = block.timestamp;

         emit PulseAmplified(msg.sender, amount);
         emit GlobalPulseUpdated(globalPulse.frequency, globalPulse.intensity, globalPulse.stability);
    }

    /// @notice User action that *may* trigger a cross-chain signal related to their fragment.
    /// @param tokenId The ID of the fragment initiating the resonance.
    function resonateGlobally(uint256 tokenId) public whenNotPaused nonReentrant {
        if (ownerOf(tokenId) != msg.sender) revert ERC721InsufficientApproval(msg.sender, tokenId);
         if (!fragmentStates[tokenId].integrity > 0) revert FragmentDoesNotExist(); // Basic check

        // --- Example Logic: Condition for triggering a global resonance ---
        // Maybe requires high resonance or a specific global state
        bool triggerConditionMet = fragmentStates[tokenId].resonance > 500 && globalPulse.intensity > 600;
        // --- End Example Logic ---

        if (triggerConditionMet) {
            // Example: Select a random registered cross-chain endpoint (requires more complex logic)
            // For simplicity, let's hardcode sending to a registered chain 101
            uint16 destChainId = 101; // Example target chain ID

            if (!registeredCrossChainEndpoints[destChainId]) {
                // Even if trigger condition met, cannot send if endpoint isn't registered
                // Consider different logic: maybe store the intent or revert
                // For this example, we allow triggering but internal send might fail/queue
                 // This isn't ideal, better to check upfront if a target chain is possible
                 // Let's check registration first
                 revert CrossChainEndpointNotRegistered(); // User shouldn't trigger if no valid endpoint exists
            }

            // Package fragment state and global pulse state into data for cross-chain message
            bytes memory messageData = abi.encode(tokenId, fragmentStates[tokenId], globalPulse);

            // Simulate sending the cross-chain signal via the messenger contract
            // In a real implementation, this would call a function on the messenger contract
            // e.g., crossChainMessenger.sendMessage(destChainId, address(this), messageData, gasLimit);
            _triggerCrossChainSend(destChainId, tokenId, messageData); // Use internal helper

            fragmentStates[tokenId].lastInteractionTime = block.timestamp; // Update interaction time

            emit GlobalResonanceTriggered(tokenId, destChainId);

        } else {
             // If condition not met, maybe a smaller effect or simply no action
             // fragmentStates[tokenId].energy -= 10; // Example: small energy cost even if not successful
             // emit FragmentStateUpdated(...);
        }
    }

    // --- Oracle/External Data Input Functions ---

    /// @notice Updates global pulse parameters based on a general oracle feed.
    /// @param newFrequency New frequency value.
    /// @param newIntensity New intensity value.
    /// @param newStability New stability value.
    function updateGlobalPulseFromOracle(uint64 newFrequency, uint64 newIntensity, uint64 newStability) external onlyOracle whenNotPaused {
        globalPulse.frequency = newFrequency;
        globalPulse.intensity = newIntensity;
        globalPulse.stability = newStability;
        globalPulse.lastUpdateTime = block.timestamp;
        // Can add logic here to calculate impact on fragments based on changes

        emit GlobalPulseUpdated(globalPulse.frequency, globalPulse.intensity, globalPulse.stability);
        emit OracleDataProcessed(keccak256(abi.encode(newFrequency, newIntensity, newStability)));
    }

    /// @notice Applies state changes to fragments based on the results of an off-chain AI simulation.
    /// @param tokenIds Array of token IDs to update.
    /// @param energyChanges Array of signed integers representing energy changes.
    /// @param resonanceChanges Array of signed integers representing resonance changes.
    /// @dev Array lengths must match. Changes are applied element-wise.
    function processAIResults(uint256[] calldata tokenIds, int256[] calldata energyChanges, int256[] calldata resonanceChanges) external onlyAIOracle whenNotPaused {
        if (tokenIds.length != energyChanges.length || tokenIds.length != resonanceChanges.length) {
            revert InvalidArrayLength();
        }

        bytes32 resultsHash = keccak256(abi.encode(tokenIds, energyChanges, resonanceChanges));

        for (uint i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            if (!fragmentStates[tokenId].integrity > 0) continue; // Skip if fragment doesn't exist

            // Apply changes, ensuring values stay within bounds (e.g., >0)
            if (energyChanges[i] > 0) {
                fragmentStates[tokenId].energy = fragmentStates[tokenId].energy + uint64(energyChanges[i]);
            } else if (energyChanges[i] < 0) {
                uint64 energyDecrease = uint64(-energyChanges[i]);
                if (fragmentStates[tokenId].energy > energyDecrease) {
                    fragmentStates[tokenId].energy -= energyDecrease;
                } else {
                    fragmentStates[tokenId].energy = 0;
                }
            }

             if (resonanceChanges[i] > 0) {
                fragmentStates[tokenId].resonance = fragmentStates[tokenId].resonance + uint64(resonanceChanges[i]);
            } else if (resonanceChanges[i] < 0) {
                uint64 resonanceDecrease = uint64(-resonanceChanges[i]);
                if (fragmentStates[tokenId].resonance > resonanceDecrease) {
                    fragmentStates[tokenId].resonance -= resonanceDecrease;
                } else {
                    fragmentStates[tokenId].resonance = 0;
                }
            }

            // Integrity could also be affected by AI results
            // fragmentStates[tokenId].integrity = calculateNewIntegrity(...);

            emit FragmentStateUpdated(tokenId, fragmentStates[tokenId].energy, fragmentStates[tokenId].resonance, fragmentStates[tokenId].integrity);
        }

        emit AIResultsProcessed(resultsHash);
    }

    /// @notice Receives and applies a state change validated by an off-chain ZK proof verifier.
    /// @param prover Address of the entity that generated the proof.
    /// @param proofHash Hash representing the validated ZK proof.
    /// @param relatedTokenId The fragment ID the proof relates to.
    /// @param stateDelta The state change value determined by the ZK proof logic.
    /// @dev This function is called by the ZK verifier relay contract after successful verification.
    function submitZKProofResult(address prover, bytes32 proofHash, uint256 relatedTokenId, uint256 stateDelta) external onlyZKVerifier whenNotPaused {
         // In a real ZK integration, the ZK verifier contract would verify the proof on-chain
         // and then call this function, passing the results/deltas.
         // The `proofHash` would likely correspond to the *statement* being proven.
         // The `prover` could be relevant for reputation or specific proof types.
         // The `stateDelta` is the outcome calculated off-chain and proven valid.

         if (!fragmentStates[relatedTokenId].integrity > 0) revert FragmentDoesNotExist(); // Basic check

         // Example: The ZK proof proves that the prover performed a specific action off-chain
         // related to this token ID, resulting in a stateDelta increase in energy.
         fragmentStates[relatedTokenId].energy += uint64(stateDelta); // Example application

         // Apply any other logic dictated by the ZK proof result
         // e.g., globalPulse.stability += 1;

        emit FragmentStateUpdated(relatedTokenId, fragmentStates[relatedTokenId].energy, fragmentStates[relatedTokenId].resonance, fragmentStates[relatedTokenId].integrity);
        emit ZKProofResultProcessed(proofHash, relatedTokenId);
    }


    // --- Cross-Chain Interaction Functions (Simulated) ---

    /// @notice Endpoint for receiving cross-chain messages from the messenger contract.
    /// @param sourceChainId The chain ID the message originated from.
    /// @param message The raw message data.
    /// @dev This function is called by the authorized crossChainMessenger contract.
    function receiveCrossChainMessage(uint16 sourceChainId, bytes memory message) external onlyCrossChainMessenger whenNotPaused {
        // In a real system, parse the message based on a predefined format.
        // Example message format: (messageType, tokenId, data...)
        // Based on messageType, call internal logic function.

        // --- Example: Simulate processing a 'CrossChainResonanceBoost' message ---
        // Assume message format is abi.encode(uint256 boostedTokenId, uint256 boostAmount)
        // This is a simplification. Real cross-chain requires more robust message parsing.

        // Check minimum message length to avoid decoding errors
        if (message.length < 64) { // size of uint256 + uint256
            revert InvalidCrossChainMessage();
        }

        (uint256 boostedTokenId, uint256 boostAmount) = abi.decode(message, (uint256, uint256));

        // Apply the effect of the cross-chain message to a local fragment
        if (fragmentStates[boostedTokenId].integrity > 0) { // Check if local fragment exists
            fragmentStates[boostedTokenId].resonance += uint64(boostAmount); // Example effect
            // Can add logic: cross-chain resonance is more powerful, etc.
             emit FragmentStateUpdated(boostedTokenId, fragmentStates[boostedTokenId].energy, fragmentStates[boostedTokenId].resonance, fragmentStates[boostedTokenId].integrity);
        }
        // --- End Example Processing ---

        // Add logic to handle different message types
        // Example: if (messageType == SomeEnum.GlobalPulseShift) { _processGlobalPulseShift(data); }

        emit CrossChainMessageReceived(sourceChainId, keccak256(message));
    }

    /// @notice Internal helper function to simulate sending a cross-chain signal.
    /// @param destChainId The destination chain ID.
    /// @param tokenId The ID of the fragment related to the signal.
    /// @param data The message payload to send.
    /// @dev This would typically call the cross-chain messenger contract.
    function _triggerCrossChainSend(uint16 destChainId, uint256 tokenId, bytes memory data) internal {
         // In a real integration (e.g., LayerZero, Chainlink CCIP), you would call
         // the messenger contract here to send the message. This costs gas on this chain
         // and fees on the destination chain (often paid in native gas or LINK/token).
         // Example: crossChainMessenger.send(destChainId, address(this), data);

         // For this simulation, we just emit an event.
         emit CrossChainSignalSent(destChainId, tokenId, keccak256(data));
    }


    // --- State Query Functions (View/Pure) ---

    /// @notice Gets the current state of a specific Pulse Fragment.
    /// @param tokenId The ID of the fragment.
    /// @return The FragmentState struct.
    function getFragmentState(uint256 tokenId) public view returns (FragmentState memory) {
        if (ownerOf(tokenId) == address(0)) revert FragmentDoesNotExist(); // Check existence via ownerOf
        return fragmentStates[tokenId];
    }

    /// @notice Gets the current state of the Global Pulse.
    /// @return The GlobalPulseState struct.
    function getGlobalPulseState() public view returns (GlobalPulseState memory) {
        return globalPulse;
    }

    /// @notice Calculates a derived, dynamic property for a fragment.
    /// @param tokenId The ID of the fragment.
    /// @param propertyType Type of derived property (e.g., 0 for SyncScore, 1 for StabilityIndex).
    /// @return The calculated value.
    function calculateDynamicFragmentProperty(uint256 tokenId, uint8 propertyType) public view returns (uint256) {
         if (ownerOf(tokenId) == address(0)) revert FragmentDoesNotExist(); // Check existence

         FragmentState memory fragment = fragmentStates[tokenId];
         GlobalPulseState memory global = globalPulse;

         // Example calculation logic:
         if (propertyType == 0) { // SyncScore
             // SyncScore = (Fragment Resonance / Global Frequency) * Fragment Energy * some_factor
             // Use checked arithmetic or ensure types/scales prevent overflow/underflow
             // Example simplified calculation (avoiding floats)
             uint256 syncScore = (uint256(fragment.resonance) * uint256(fragment.energy)) / (uint256(global.frequency) + 1); // Add 1 to avoid division by zero
             syncScore = syncScore / 100; // Scale down
             return syncScore;

         } else if (propertyType == 1) { // StabilityIndex
             // StabilityIndex = Fragment Integrity * Global Stability / some_other_factor
              uint256 stabilityIndex = (uint256(fragment.integrity) * uint256(global.stability)) / 10; // Scale down
              return stabilityIndex;

         } else {
             revert InvalidPropertyType();
         }
    }

    /// @notice Returns the URI for the dynamic metadata of a fragment.
    /// @param tokenId The ID of the fragment.
    /// @return The metadata URI.
    /// @dev Metadata should be generated off-chain by a service that reads fragment/global state.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert ERC721DoesNotExist(tokenId);
        // Base URI should point to a service that serves JSON metadata based on token ID
        // e.g., "https://api.omnichainpulse.xyz/metadata/"
        // The service will call getFragmentState and getGlobalPulseState to build the JSON.
        string memory baseURI = "ipfs://YOUR_METADATA_BASE_URI/"; // Replace with your actual URI service
        return string(abi.encodePacked(baseURI, Strings.toString(tokenId)));
    }


    // --- Epoch Management Functions ---

    /// @notice Advances the system to the next epoch. Resets/updates epoch-specific states.
    /// @param newEpochNumber The number of the new epoch (must be currentEpoch + 1).
    function triggerEpochTransition(uint256 newEpochNumber) public onlyOwner whenNotPaused {
        if (newEpochNumber != epochInfo.currentEpoch + 1) revert InvalidEpochNumber(); // Or similar error

        epochInfo.epochEndTime = block.timestamp; // End the current epoch

        // --- Epoch Transition Logic ---
        // This is where epoch-specific logic happens:
        // - Calculate final state for rewards for *previous* epoch
        // - Potentially reset fragment states (e.g., energy decay)
        // - Potentially adjust global pulse baseline parameters
        // - Clear previous epoch's reward claims mapping
        // --- End Epoch Transition Logic ---

        epochInfo.currentEpoch = newEpochNumber;
        epochInfo.epochStartTime = block.timestamp;
        epochInfo.epochEndTime = 0; // Reset for ongoing epoch

        // Clear the reward claim mapping for the *new* epoch. The previous epoch's claims are implicitly archived
        // or must be queried from past events if needed. For this example, we just reset the mapping for the *next* claims.
        // Note: Solidity mappings cannot be iterated or fully cleared efficiently.
        // If you need to track *all* claims per epoch, store them differently or manage the mapping differently.
        // The current mapping is `tokenId => claims in *current* epoch`. If triggered for new epoch, it means claims for the *old* epoch are finished via this mapping.
        // A better pattern for claiming past epochs is `(tokenId, epoch) => claimedBool`.
        // Let's refactor the claim logic slightly for clarity below.

        emit EpochTransitioned(epochInfo.currentEpoch, block.timestamp);
    }

    /// @notice Allows a fragment owner to claim rewards based on its state in the previous epoch.
    /// @param tokenId The ID of the fragment.
    function claimEpochReward(uint256 tokenId) public whenNotPaused nonReentrant {
         if (ownerOf(tokenId) != msg.sender) revert ERC721InsufficientApproval(msg.sender, tokenId);
         if (epochInfo.epochEndTime == 0) revert EpochNotEnded(); // Can only claim after epoch ends

         uint256 epochToClaim = epochInfo.currentEpoch - 1;
         // Use a mapping to track claims per token per epoch
         bytes32 claimKey = keccak256(abi.encode(tokenId, epochToClaim));

         // Assume a separate mapping or state history is needed to determine rewards *at the time epoch ended*
         // This is a complex aspect often requiring snapshots or off-chain calculation/proof.
         // For this example, we'll use a simplified reward logic based on the *current* fragment state,
         // and assume a history mapping `claimedForEpoch[tokenId][epoch]` exists conceptually.
         // A proper system would need to store state snapshots or calculate rewards off-chain and verify claims.

         // Simplistic Example: Reward based on final integrity * current reward rate (requires historical state or snapshot)
         // Placeholder: Calculate a reward amount based on the fragment's state at the end of the *previous* epoch.
         // In a real system, you'd query a snapshot state or use an oracle/ZK proof for the reward amount.
         uint256 rewardAmount = calculateEpochRewardAmount(tokenId, epochToClaim); // Requires snapshot logic

         if (rewardAmount == 0) revert NothingToClaim(); // Or if already claimed

         // --- Example: Transfer reward token ---
         // Assumes a reward token exists (e.g., ERC20) and the contract holds it.
         // IERC20 rewardToken = IERC20(address(REWARD_TOKEN_ADDRESS)); // Constant or state variable
         // if (!rewardToken.transfer(msg.sender, rewardAmount)) {
         //     // Handle transfer failure
         //     revert RewardTransferFailed();
         // }
         // For this example, just emit an event.
         // --- End Example Transfer ---

         // Mark as claimed for this epoch
         // claimedForEpoch[tokenId][epochToClaim] = true; // Requires a separate state variable for historical claims

         emit EpochRewardClaimed(tokenId, epochToClaim, rewardAmount);
    }

    /// @notice Internal helper to calculate epoch reward amount (Placeholder - requires snapshot/history logic).
    /// @param tokenId The ID of the fragment.
    /// @param epoch The epoch to calculate rewards for.
    /// @return The calculated reward amount.
    function calculateEpochRewardAmount(uint256 tokenId, uint256 epoch) internal view returns (uint256) {
        // This is a complex function that should ideally read from historical state snapshots
        // or rely on verified off-chain computations (e.g., provided via ZK proof or trusted oracle).
        // Reading current state for past epoch rewards is not reliable.

        // For demonstration, a placeholder: reward is based on *current* integrity / 10, if called for previous epoch
        // This is INCORRECT for a real system, but illustrates where the logic would go.
         if (epoch >= epochInfo.currentEpoch) return 0; // Cannot claim future or current epoch rewards this way
         if (!_exists(tokenId)) return 0; // Cannot claim for non-existent token

         // Check if already claimed for this epoch using a conceptual mapping
         // if (claimedForEpoch[tokenId][epoch]) return 0; // Conceptual check

         FragmentState storage fragment = fragmentStates[tokenId];
         uint256 conceptualReward = uint256(fragment.integrity) * 1e18 / 100; // Example calculation

         return conceptualReward; // Needs actual logic based on historical state
    }

    // --- Admin & Configuration Functions ---

    /// @notice Toggles the Paused state of the contract.
    function togglePause() public onlyOwner {
        if (paused()) {
            _unpause();
        } else {
            _pause();
        }
    }

    /// @notice Sets the address authorized to call oracle functions.
    /// @param _oracleAddress The new oracle address.
    function setOracleAddress(address _oracleAddress) public onlyOwner {
        oracleAddress = _oracleAddress;
    }

    /// @notice Sets the address authorized to call AI oracle functions.
    /// @param _aiOracleAddress The new AI oracle address.
    function setAIOracleAddress(address _aiOracleAddress) public onlyOwner {
        aiOracleAddress = _aiOracleAddress;
    }

    /// @notice Sets the address authorized to call ZK verifier relay functions.
    /// @param _zkVerifierAddress The new ZK verifier relay address.
    function setZKVerifierAddress(address _zkVerifierAddress) public onlyOwner {
        zkVerifierAddress = _zkVerifierAddress;
    }

    /// @notice Sets the address of the cross-chain messenger contract.
    /// @param _crossChainMessenger The new messenger address.
    function setCrossChainMessenger(address _crossChainMessenger) public onlyOwner {
        crossChainMessenger = _crossChainMessenger;
    }

    /// @notice Registers or unregisters a chain ID as a valid target for cross-chain signals.
    /// @param chainId The chain ID to register/unregister.
    /// @param enabled True to register, False to unregister.
    function registerCrossChainEndpoint(uint16 chainId, bool enabled) public onlyOwner {
        registeredCrossChainEndpoints[chainId] = enabled;
        emit CrossChainEndpointRegistered(chainId, enabled);
    }

    /// @notice Allows owner to withdraw accidental ERC20 tokens sent to the contract.
    /// @param tokenAddress The address of the ERC20 token.
    /// @param amount The amount to withdraw.
    function withdrawERC20(address tokenAddress, uint256 amount) public onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        token.transfer(owner(), amount);
    }

    /// @notice Allows owner to withdraw accidental ETH sent to the contract.
    /// @param amount The amount to withdraw.
    function withdrawETH(uint256 amount) public onlyOwner {
        (bool success, ) = owner().call{value: amount}("");
        require(success, "ETH withdrawal failed");
    }


    // --- ERC721 Standard Functions ---
    // All standard ERC721 functions are inherited and work with the internal _safeMint, _transfer, _burn logic.
    // The `tokenURI` function is overridden above to provide dynamic metadata.

    // @dev The following ERC721 functions are implicitly available or overridden:
    // function balanceOf(address owner) public view virtual override returns (uint256);
    // function ownerOf(uint256 tokenId) public view virtual override returns (address);
    // function approve(address to, uint256 tokenId) public virtual override;
    // function getApproved(uint256 tokenId) public view virtual override returns (address);
    // function setApprovalForAll(address operator, bool approved) public virtual override;
    // function isApprovedForAll(address owner, address operator) public view virtual override returns (bool);
    // function transferFrom(address from, address to, uint256 tokenId) public virtual override;
    // function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual override;
    // function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override;

    // Helper internal function used by ERC721 _safeMint
    // Not included in the 20+ public/external function count, but required for implementation.
    // function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, IERC165) returns (bool);

    // We need to implement _beforeTokenTransfer to hook into transfers if state needs adjustment
    // (e.g., pausing interaction timers) - but it's an internal override, not a new public function.
    // function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal virtual override {
    //     super._beforeTokenTransfer(from, to, tokenId, batchSize);
    //     // Example: Reset interaction timer on transfer
    //     // if (from != address(0)) { // Not a mint
    //     //     fragmentStates[tokenId].lastInteractionTime = block.timestamp;
    //     // }
    // }
}

// Helper contract or library might be needed for complex off-chain validation/parsing/etc.
// For this example, we keep it contained.

```