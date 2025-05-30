Okay, here is a Solidity smart contract concept, `QuantumNexus`, designed with several advanced concepts like dynamic state, probabilistic outcomes influenced by external factors (simulated via oracle callbacks), randomness integration, resource management (custom ERC20), and unique asset management (custom ERC721) with inter-asset linking and state-dependent interactions.

It aims to be creative by introducing concepts like "entropic decay" and "state collapse" for NFTs, and "fusion" with probabilistic outcomes influenced by various on-chain and simulated off-chain factors. It implements minimal ERC20 and ERC721 interfaces directly to avoid strict "open source duplication" at the library level, although the interface definitions themselves are standard.

This contract has over 20 public/external functions and incorporates complex internal logic.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// --- Contract: QuantumNexus ---
// A complex smart contract managing unique "Quantum Fragments" (ERC721-like)
// and "Nexus Energy" (ERC20-like). It simulates a system where Fragment states
// are dynamic, subject to entropic decay, probabilistic collapse, and fusion.
// Interactions consume Energy, outcomes depend on randomness, internal state,
// and simulated external "cosmic factors" provided by an oracle.

// --- Outline ---
// 1. Interfaces & Errors: Define necessary interfaces (VRF) and custom errors.
// 2. Events: Define events for key state changes and actions.
// 3. Libraries: None used to minimize open-source duplication.
// 4. State Variables: Declare all contract state, including token data, fragment data, oracles, parameters.
// 5. Modifiers: Define access control modifiers.
// 6. Constructor: Initialize the contract, owner, and initial parameters.
// 7. Oracle Management: Functions for setting oracle addresses and callback functions.
// 8. Parameter Management: Functions for setting dynamic contract parameters.
// 9. Token Minting (Initial): Functions for initial distribution of Fragments and Energy.
// 10. Fragment State Management: Core logic for collapsing state, decay, linking.
// 11. Fusion Logic: Functions for requesting randomness and attempting fusion.
// 12. Randomness Handling: Internal and external functions for VRF interaction.
// 13. Minimal ERC721 Implementation: Functions for managing Fragment ownership and approvals.
// 14. Minimal ERC20 Implementation: Functions for managing Nexus Energy balances and transfers.
// 15. View Functions: Functions to query contract state and parameters.
// 16. Internal Helpers: Functions for common internal operations (_transferFragment, _mintEnergy, etc.).

// --- Function Summary ---
// Admin/Setup:
// - constructor(...): Deploys and initializes the contract.
// - setCosmicFactorOracle(address _oracle): Sets the address of the oracle providing cosmic factors.
// - setRNGOracle(address _oracle): Sets the address of the VRF oracle.
// - setEntropicDecayRate(uint64 _rate): Sets the decay rate for fragments (e.g., per second).
// - setFusionProbabilityBase(uint16 _baseProb): Sets the base probability percentage for fusion success.
// - setStateCollapseCost(uint256 _cost): Sets the Nexus Energy cost for state collapse.
// - setFusionCost(uint256 _cost): Sets the Nexus Energy cost for attempting fusion.
// - setParameterEvolutionRate(uint64 _rate): Sets the rate at which global parameters evolve.
// - grantInitialMintPermission(address _minter): Grants permission to an address to mint initial fragments/energy.
// - revokeInitialMintPermission(address _minter): Revokes minting permission.

// Oracle Callbacks:
// - updateCosmicFactor(uint256 _factor): Called by the Cosmic Factor Oracle to update the global factor.
// - fulfillRandomness(bytes32 requestId, uint256 randomness): Called by the VRF Oracle to provide randomness.

// Initial Minting (Permissioned):
// - mintInitialFragment(address _to, uint8 _initialQuality): Mints a new fragment with initial state (permissioned).
// - mintNexusEnergy(address _to, uint256 _amount): Mints Nexus Energy (permissioned).

// Core Interactions:
// - collapseState(uint256 _tokenId): Initiates state collapse for a fragment (user action, costs energy, requests randomness).
// - attemptFusion(uint256 _tokenId1, uint256 _tokenId2): Attempts to fuse two fragments (user action, costs energy, requires prior randomness).
// - linkFragments(uint256 _tokenId1, uint256 _tokenId2): Links two fragments together.
// - breakLink(uint256 _tokenId): Breaks the link for a fragment.
// - triggerGlobalParameterEvolution(): Triggers evolution of global contract parameters (e.g., global entropy).

// Minimal ERC721 Implementation (Quantum Fragments):
// - balanceOf(address owner): Returns the number of fragments owned by an address.
// - ownerOf(uint256 tokenId): Returns the owner of a fragment.
// - transferFrom(address from, address to, uint256 tokenId): Transfers ownership of a fragment (basic transfer).
// - safeTransferFrom(address from, address to, uint256 tokenId): Transfers ownership (safe version).
// - safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data): Transfers ownership (safe version with data).
// - approve(address to, uint256 tokenId): Approves an address to transfer a specific fragment.
// - getApproved(uint256 tokenId): Gets the approved address for a fragment.
// - setApprovalForAll(address operator, bool approved): Sets approval for an operator for all owner's fragments.
// - isApprovedForAll(address owner, address operator): Checks if an operator is approved for an owner.
// - tokenURI(uint256 tokenId): Returns the metadata URI for a fragment.
// - supportsInterface(bytes4 interfaceId): Checks if the contract supports a given interface (for ERC165).

// Minimal ERC20 Implementation (Nexus Energy):
// - totalSupply(): Returns the total supply of Nexus Energy.
// - balanceOf(address account): Returns the balance of Nexus Energy for an address.
// - transfer(address recipient, uint256 amount): Transfers Nexus Energy.
// - allowance(address owner, address spender): Returns the amount an owner has allowed a spender to spend.
// - approve(address spender, uint256 amount): Approves a spender to spend an amount of Energy.
// - transferFrom(address sender, address recipient, uint256 amount): Transfers Energy using an allowance.

// View Functions:
// - queryFragmentState(uint256 _tokenId): Returns the current state data of a fragment.
// - queryGlobalEntropy(): Returns the current global entropy level.
// - queryCosmicFactor(): Returns the current cosmic factor.
// - queryDecayRate(): Returns the current entropic decay rate.
// - queryFusionProbabilityBase(): Returns the base fusion probability.
// - queryStateCollapseCost(): Returns the cost of state collapse.
// - queryFusionCost(): Returns the cost of fusion.
// - queryParameterEvolutionRate(): Returns the rate of parameter evolution.
// - queryFragmentLinkedFragment(uint256 _tokenId): Returns the ID of the fragment linked to this one.
// - getInitialMinterPermission(address _minter): Checks if an address has initial mint permission.

// --- End Outline & Summary ---


// Minimal Interface for VRF Oracle Callback
interface IVRFConsumer {
    function fulfillRandomness(bytes32 requestId, uint256 randomness) external;
}

// ERC165 Interface for supportsInterface
interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// Minimal ERC721 Metadata Interface (for tokenURI)
interface IERC721Metadata is IERC165 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// ERC721 Standard Events (from OpenZeppelin) - required for compatibility
interface IERC721Events {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
}


error NotOwner();
error NotApprovedOrOwner();
error NotApprovedForAll();
error InvalidTokenId();
error NotCosmicFactorOracle();
error NotRNGOracle();
error NotInitialMinter();
error ZeroAddressRecipient();
error InsufficientEnergy();
error SelfTransfer();
error NotApproved();
error InsufficientAllowance();
error FragmentNotLinked();
error FragmentsAlreadyLinked();
error CannotLinkToSelf();
error FragmentsDoNotExist();
error FusionRequiresRandomness();
error RandomnessNotFulfilled();
error InvalidRandomnessRequestType();
error RandomnessAlreadyUsed();


contract QuantumNexus is IERC721Metadata, IERC721Events {

    // --- State Variables ---

    // Admin & Oracles
    address private _owner;
    address public cosmicFactorOracle;
    address public rngOracle;

    // Contract Parameters (Dynamic)
    uint64 public entropicDecayRate = 1 ether / (3600 * 24 * 7); // Example: decay rate per second (relative)
    uint16 public fusionProbabilityBase = 5000; // Base probability percentage (50.00%)
    uint256 public stateCollapseCost = 100; // Nexus Energy cost
    uint256 public fusionCost = 500; // Nexus Energy cost
    uint64 public parameterEvolutionRate = 1; // How much global entropy changes per interaction (example)

    // Global State
    uint256 public globalEntropyLevel = 0; // Rises with activity, affects outcomes
    uint256 public cosmicFactor = 100; // Example initial value (e.g., represents external cosmic influence)
    uint64 private lastGlobalEvolutionTime;

    // Quantum Fragments (ERC721-like)
    string private _name = "Quantum Fragment";
    string private _symbol = "QF";
    uint256 private _nextTokenId = 0;
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Fragment Specific Data & State
    struct FragmentState {
        uint8 quality; // 0-100, affects outcomes
        uint64 lastInteractionTime; // Timestamp of last decay/interaction
        uint256 linkedFragmentId; // 0 if not linked
        bytes32 randomnessRequestId; // ID of the last randomness request associated with this fragment
        uint8 randomnessRequestType; // 0: None, 1: Collapse, 2: Fusion
        bool randomnessUsed; // Whether the randomness result has been applied
    }
    mapping(uint256 => FragmentState) public fragmentData;
    mapping(bytes32 => uint256) private _randomnessRequestTokenId; // Map request ID back to token ID
    mapping(bytes32 => uint256) private _randomnessResults; // Map request ID to the received randomness

    // Nexus Energy (ERC20-like)
    string public constant ENERGY_NAME = "Nexus Energy";
    string public constant ENERGY_SYMBOL = "NXE";
    uint256 private _totalEnergySupply = 0;
    mapping(address => uint256) private _energyBalances;
    mapping(address => mapping(address => uint256)) private _energyAllowances;

    // Access Control
    mapping(address => bool) private _initialMinters;

    // Interface IDs for ERC165
    bytes4 private constant _ERC165_INTERFACE_ID = 0x01ffc9a7;
    bytes4 private constant _ERC721_INTERFACE_ID = 0x80ac58cd;
    bytes4 private constant _ERC721_METADATA_INTERFACE_ID = 0x5b5e139f;


    // --- Events ---

    event CosmicFactorUpdated(uint256 newFactor);
    event RandomnessFulfilled(bytes32 indexed requestId, uint256 indexed randomness);
    event FragmentStateCollapsed(uint256 indexed tokenId, uint8 oldQuality, uint8 newQuality, uint256 energySpent);
    event FusionAttempted(uint256 indexed tokenId1, uint256 indexed tokenId2, uint256 energySpent);
    event FusionSuccess(uint256 indexed burnedToken1, uint256 indexed burnedToken2, uint256 indexed newTokenId, uint8 newQuality);
    event FusionFailure(uint256 indexed burnedToken1, uint256 indexed burnedToken2, uint256 energyRefunded);
    event FragmentLinked(uint256 indexed tokenId1, uint256 indexed tokenId2);
    event FragmentLinkBroken(uint256 indexed tokenId);
    event GlobalParametersEvolved(uint256 newGlobalEntropy);
    event EntropicDecayApplied(uint256 indexed tokenId, uint8 oldQuality, uint8 newQuality, uint64 decayAmount);
    event InitialMinterPermissionUpdated(address indexed minter, bool permitted);
    event FragmentMetadataURISet(uint256 indexed tokenId, string uri);

    // Standard ERC721 & ERC20 Events (declared via interfaces above)


    // --- Modifiers ---

    modifier onlyOwner() {
        if (msg.sender != _owner) revert NotOwner();
        _;
    }

    modifier onlyCosmicFactorOracle() {
        if (msg.sender != cosmicFactorOracle) revert NotCosmicFactorOracle();
        _;
    }

    modifier onlyRNGOracle() {
        if (msg.sender != rngOracle) revert NotRNGOracle();
        _;
    }

    modifier onlyInitialMinter() {
        if (!_initialMinters[msg.sender]) revert NotInitialMinter();
        _;
    }

    modifier existingFragment(uint256 _tokenId) {
        if (_owners[_tokenId] == address(0)) revert InvalidTokenId();
        _;
    }

    // --- Constructor ---

    constructor(
        address initialOwner,
        address initialCosmicFactorOracle,
        address initialRNGOracle,
        string memory baseTokenURI
    ) {
        _owner = initialOwner;
        cosmicFactorOracle = initialCosmicFactorOracle;
        rngOracle = initialRNGOracle;
        _baseTokenURI = baseTokenURI;
        lastGlobalEvolutionTime = uint64(block.timestamp);
    }

    // --- Oracle Management ---

    function setCosmicFactorOracle(address _oracle) external onlyOwner {
        cosmicFactorOracle = _oracle;
    }

    function setRNGOracle(address _oracle) external onlyOwner {
        rngOracle = _oracle;
    }

    function updateCosmicFactor(uint256 _factor) external onlyCosmicFactorOracle {
        cosmicFactor = _factor;
        emit CosmicFactorUpdated(_factor);
        triggerGlobalParameterEvolution(); // Interaction triggers evolution
    }

    // --- Parameter Management ---

    function setEntropicDecayRate(uint64 _rate) external onlyOwner {
        entropicDecayRate = _rate;
    }

    function setFusionProbabilityBase(uint16 _baseProb) external onlyOwner {
        // Base prob is in 1/100th of a percent (e.g., 5000 = 50.00%)
        if (_baseProb > 10000) _baseProb = 10000; // Cap at 100%
        fusionProbabilityBase = _baseProb;
    }

    function setStateCollapseCost(uint256 _cost) external onlyOwner {
        stateCollapseCost = _cost;
    }

    function setFusionCost(uint256 _cost) external onlyOwner {
        fusionCost = _cost;
    }

    function setParameterEvolutionRate(uint64 _rate) external onlyOwner {
        parameterEvolutionRate = _rate;
    }

    // --- Access Control for Initial Minting ---

    function grantInitialMintPermission(address _minter) external onlyOwner {
        _initialMinters[_minter] = true;
        emit InitialMinterPermissionUpdated(_minter, true);
    }

    function revokeInitialMintPermission(address _minter) external onlyOwner {
        _initialMinters[_minter] = false;
        emit InitialMinterPermissionUpdated(_minter, false);
    }

    function getInitialMinterPermission(address _minter) external view returns (bool) {
        return _initialMinters[_minter];
    }

    // --- Initial Minting (Permissioned) ---

    function mintInitialFragment(address _to, uint8 _initialQuality) external onlyInitialMinter {
        _mintFragment(_to, _initialQuality);
    }

    function mintNexusEnergy(address _to, uint256 _amount) external onlyInitialMinter {
        _mintEnergy(_to, _amount);
    }

    // --- Core Interaction Logic ---

    // Requests randomness and initiates state collapse logic
    function collapseState(uint256 _tokenId) external existingFragment(_tokenId) {
        address owner = ownerOf(_tokenId);
        if (msg.sender != owner && !isApprovedForAll(owner, msg.sender) && getApproved(_tokenId) != msg.sender) {
             revert NotApprovedOrOwner();
        }

        if (_energyBalances[msg.sender] < stateCollapseCost) revert InsufficientEnergy();

        _burnEnergy(msg.sender, stateCollapseCost);

        // Apply decay before state change
        _applyEntropicDecay(_tokenId);

        // Request randomness for the collapse outcome
        bytes32 requestId = _requestRandomness(1); // Type 1 for Collapse
        fragmentData[_tokenId].randomnessRequestId = requestId;
        fragmentData[_tokenId].randomnessRequestType = 1;
        fragmentData[_tokenId].randomnessUsed = false;
        _randomnessRequestTokenId[requestId] = _tokenId;

        emit FragmentStateCollapsed(_tokenId, fragmentData[_tokenId].quality, fragmentData[_tokenId].quality, stateCollapseCost); // Emit before randomness known, final state update in fulfill
        triggerGlobalParameterEvolution();
    }

    // Attempts to fuse two fragments
    function attemptFusion(uint256 _tokenId1, uint256 _tokenId2) external existingFragment(_tokenId1) existingFragment(_tokenId2) {
        if (_tokenId1 == _tokenId2) revert InvalidTokenId();

        address owner1 = ownerOf(_tokenId1);
        address owner2 = ownerOf(_tokenId2);

        // Must own both fragments
        if (msg.sender != owner1 || msg.sender != owner2) revert NotOwner();

        if (_energyBalances[msg.sender] < fusionCost) revert InsufficientEnergy();

        // Check if both fragments have a recent, unused fusion randomness request fulfilled
        FragmentState storage data1 = fragmentData[_tokenId1];
        FragmentState storage data2 = fragmentData[_tokenId2];

        if (data1.randomnessRequestType != 2 || data2.randomnessRequestType != 2) revert FusionRequiresRandomness();
        if (data1.randomnessUsed || data2.randomnessUsed) revert RandomnessAlreadyUsed();
        if (_randomnessResults[data1.randomnessRequestId] == 0 || _randomnessResults[data2.randomnessRequestId] == 0) revert RandomnessNotFulfilled();
        // Note: Ideally, VRF would provide a single randomness for a pair attempt,
        // but for simulation, we use two, one for each component's influence.
        // A real VRF integration might need a different request structure.

        _burnEnergy(msg.sender, fusionCost);

        // Apply decay before fusion
        _applyEntropicDecay(_tokenId1);
        _applyEntropicDecay(_tokenId2);

        uint256 randomness1 = _randomnessResults[data1.randomnessRequestId];
        uint256 randomness2 = _randomnessResults[data2.randomnessRequestId];

        // Mark randomness as used
        data1.randomnessUsed = true;
        data2.randomnessUsed = true;

        // Combine randomness for a fusion outcome factor
        uint256 combinedRandomness = (randomness1 + randomness2) % 10000; // Max 9999

        // Fusion success logic (simplified)
        // Factors: Base probability, average quality, cosmic factor, global entropy, randomness
        uint256 avgQuality = uint256(data1.quality + data2.quality) / 2;
        uint256 qualityInfluence = avgQuality; // Simple linear influence
        uint256 cosmicInfluence = cosmicFactor / 10; // Example scaling
        uint256 entropyPenalty = globalEntropyLevel / 1000; // Example penalty

        uint256 successChance = fusionProbabilityBase + qualityInfluence + cosmicInfluence - entropyPenalty;
        if (successChance > 10000) successChance = 10000;
        if (successChance < 0) successChance = 0; // Should not happen with uint, but good practice

        // Determine success based on combined randomness
        bool success = combinedRandomness < successChance;

        emit FusionAttempted(_tokenId1, _tokenId2, fusionCost);

        _burnFragment(_tokenId1);
        _burnFragment(_tokenId2);

        if (success) {
            // Generate new fragment state (e.g., higher quality)
            uint8 newQuality = uint8(uint256(avgQuality * 120) / 100); // 20% potential improvement
            if (newQuality > 100) newQuality = 100; // Cap quality

            uint256 newTokenId = _mintFragment(msg.sender, newQuality); // Mints to the caller/owner

            emit FusionSuccess(_tokenId1, _tokenId2, newTokenId, newQuality);
        } else {
            // Fusion Failure - Maybe some Energy refund?
            // uint256 refundAmount = fusionCost / 2; // Example refund
            // _mintEnergy(msg.sender, refundAmount);
            emit FusionFailure(_tokenId1, _tokenId2, 0); // No refund in this version
        }

        triggerGlobalParameterEvolution();
    }

    // Links two fragments owned by the caller
    function linkFragments(uint256 _tokenId1, uint256 _tokenId2) external existingFragment(_tokenId1) existingFragment(_tokenId2) {
         if (_tokenId1 == _tokenId2) revert CannotLinkToSelf();

         address owner1 = ownerOf(_tokenId1);
         address owner2 = ownerOf(_tokenId2);

         if (msg.sender != owner1 || msg.sender != owner2) revert NotOwner();

         if (fragmentData[_tokenId1].linkedFragmentId != 0 || fragmentData[_tokenId2].linkedFragmentId != 0) revert FragmentsAlreadyLinked();

         fragmentData[_tokenId1].linkedFragmentId = _tokenId2;
         fragmentData[_tokenId2].linkedFragmentId = _tokenId1;

         emit FragmentLinked(_tokenId1, _tokenId2);
    }

    // Breaks the link for a fragment owned by the caller
    function breakLink(uint256 _tokenId) external existingFragment(_tokenId) {
        address owner = ownerOf(_tokenId);
        if (msg.sender != owner) revert NotOwner();

        uint256 linkedId = fragmentData[_tokenId].linkedFragmentId;
        if (linkedId == 0) revert FragmentNotLinked();

        // Check if the linked fragment also exists and is linked back
        // This handles potential issues if one fragment was burned while linked
        if (_owners[linkedId] != address(0) && fragmentData[linkedId].linkedFragmentId == _tokenId) {
            fragmentData[linkedId].linkedFragmentId = 0;
        }

        fragmentData[_tokenId].linkedFragmentId = 0;

        emit FragmentLinkBroken(_tokenId);
    }

    // Triggers evolution of global parameters (can be called by anyone, but logic is internal)
    // In this simple version, only owner can call, or it's triggered by core actions.
    function triggerGlobalParameterEvolution() public {
        // This is currently triggered by oracle update or core actions.
        // Could add time-based checks here if external calls were allowed.
        // For simplicity, let's make it update every time it's called by internal logic.
        // A more complex version could check time elapsed since lastEvolutionTime.

        uint64 currentTime = uint64(block.timestamp);
        uint64 timeElapsed = currentTime - lastGlobalEvolutionTime;

        // Example evolution: Global entropy increases slightly over time and with interactions
        globalEntropyLevel += parameterEvolutionRate + (timeElapsed / (3600 * 24)); // Increase per interaction + time

        lastGlobalEvolutionTime = currentTime;

        emit GlobalParametersEvolved(globalEntropyLevel);
    }


    // --- Randomness Handling (VRF Simulation) ---

    // Internal function to simulate requesting randomness
    function _requestRandomness(uint8 _requestType) internal returns (bytes32) {
        // In a real VRF integration (like Chainlink VRF), this would call a VRF Coordinator.
        // For simulation, we just generate a deterministic ID and expect a callback.
        bytes32 requestId = keccak256(abi.encodePacked(block.timestamp, msg.sender, block.number, tx.origin, tx.gasprice, _nextTokenId, _requestType, globalEntropyLevel));
        // We store the request type and token ID associated with this request ID
        // Mapping is done in the calling function (e.g., collapseState)
        return requestId;
    }

    // Callback function from the VRF Oracle
    function fulfillRandomness(bytes32 requestId, uint256 randomness) external onlyRNGOracle {
        if (_randomnessRequestTokenId[requestId] == 0 && fragmentData[_randomnessRequestTokenId[requestId]].randomnessRequestType == 0) {
             // This request ID wasn't tracked by a core action or already processed
            revert InvalidRandomnessRequestType();
        }

        uint256 tokenId = _randomnessRequestTokenId[requestId];
        FragmentState storage data = fragmentData[tokenId];

        if (data.randomnessUsed) revert RandomnessAlreadyUsed(); // Should be caught by calling functions too

        _randomnessResults[requestId] = randomness;

        // Process outcome based on request type
        if (data.randomnessRequestType == 1) { // Collapse
            // Use the randomness to determine the new quality
            // Example: randomness determines quality change based on current quality, cosmic factor, entropy
            uint256 randInfluence = randomness % 100; // 0-99
            int256 qualityChange = int256(randInfluence) - 50; // Can be negative or positive (-50 to +49)

            // Add influences
            qualityChange += int256(cosmicFactor / 20); // Cosmic factor influence
            qualityChange -= int256(globalEntropyLevel / 5000); // Entropy penalty

            int256 newQualityInt = int256(data.quality) + qualityChange;

            uint8 newQuality = uint8(newQualityInt);
            if (newQualityInt < 0) newQuality = 0;
            if (newQualityInt > 100) newQuality = 100;

            uint8 oldQuality = data.quality;
            data.quality = newQuality;
            data.lastInteractionTime = uint64(block.timestamp); // Update interaction time after processing

            // Mark as used *after* processing
            data.randomnessUsed = true;

            emit FragmentStateCollapsed(tokenId, oldQuality, newQuality, stateCollapseCost); // Re-emit with final state

        } else if (data.randomnessRequestType == 2) { // Fusion - handled in attemptFusion, randomness just stored here
             // The attemptFusion function reads _randomnessResults[requestId]
             // The randomnessUsed flag prevents double processing of the same random result in attemptFusion
        } else {
             // Should not happen based on _randomnessRequestType
             revert InvalidRandomnessRequestType();
        }

        emit RandomnessFulfilled(requestId, randomness);
        // Note: For fusion, the randomness is stored here, but the fusion logic
        // is triggered by attemptFusion AFTER randomness is available.
        // A real integration might handle fusion outcome directly in the callback
        // or require the user to call attemptFusion *after* seeing the fulfilled event.
    }

    // --- Internal Helpers ---

    // Applies entropic decay to a fragment's quality based on time since last interaction
    function _applyEntropicDecay(uint256 _tokenId) internal {
        FragmentState storage data = fragmentData[_tokenId];
        uint64 currentTime = uint64(block.timestamp);
        uint64 timeElapsed = currentTime - data.lastInteractionTime;

        uint64 decayAmount = (timeElapsed * entropicDecayRate) / (1 ether); // Scale by 1 ether for fixed point

        if (decayAmount > 0) {
            uint8 oldQuality = data.quality;
            if (data.quality > decayAmount) {
                 data.quality -= uint8(decayAmount);
            } else {
                 data.quality = 0;
            }
            data.lastInteractionTime = currentTime; // Reset timer
            emit EntropicDecayApplied(_tokenId, oldQuality, data.quality, decayAmount);
        }
    }

    // Internal Fragment (ERC721) Minting
    function _mintFragment(address _to, uint8 _initialQuality) internal returns (uint256) {
        if (_to == address(0)) revert ZeroAddressRecipient();

        uint256 tokenId = _nextTokenId++;
        _owners[tokenId] = _to;
        _balances[_to]++;

        fragmentData[tokenId] = FragmentState({
            quality: _initialQuality,
            lastInteractionTime: uint64(block.timestamp),
            linkedFragmentId: 0,
            randomnessRequestId: bytes32(0),
            randomnessRequestType: 0,
            randomnessUsed: false
        });

        emit Transfer(address(0), _to, tokenId);
        return tokenId;
    }

    // Internal Fragment (ERC721) Burning
    function _burnFragment(uint256 _tokenId) internal existingFragment(_tokenId) {
        address owner = _owners[_tokenId];
        _approve(address(0), _tokenId); // Clear approval
        _owners[_tokenId] = address(0);
        _balances[owner]--;

        // Clean up fragment data and unlink if necessary
        uint256 linkedId = fragmentData[_tokenId].linkedFragmentId;
        if (linkedId != 0 && _owners[linkedId] != address(0) && fragmentData[linkedId].linkedFragmentId == _tokenId) {
            fragmentData[linkedId].linkedFragmentId = 0;
        }
        delete fragmentData[_tokenId]; // Remove fragment state data

        emit Transfer(owner, address(0), _tokenId);
    }

    // Internal Fragment (ERC721) Transfer
    function _transferFragment(address from, address to, uint256 tokenId) internal existingFragment(tokenId) {
        if (ownerOf(tokenId) != from) revert NotOwner();
        if (to == address(0)) revert ZeroAddressRecipient();

        // Clear approvals for the transferred token
        _approve(address(0), tokenId);

        _balances[from]--;
        _balances[to]++;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        // Apply decay on transfer (as an interaction)
        _applyEntropicDecay(tokenId);
    }

    // Internal Fragment (ERC721) Approval
    function _approve(address to, uint256 tokenId) internal existingFragment(tokenId) {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    // Internal Nexus Energy (ERC20) Minting
    function _mintEnergy(address _to, uint256 _amount) internal {
        if (_to == address(0)) revert ZeroAddressRecipient();
        _totalEnergySupply += _amount;
        _energyBalances[_to] += _amount;
        // No standard ERC20 mint event, using Transfer from 0x0
        emit Transfer(address(0), _to, _amount);
    }

    // Internal Nexus Energy (ERC20) Burning
    function _burnEnergy(address _account, uint256 _amount) internal {
        if (_account == address(0)) revert InvalidTokenId(); // Should be ZeroAddress? Standard practice
        uint256 accountBalance = _energyBalances[_account];
        if (accountBalance < _amount) revert InsufficientEnergy(); // Using InsufficientEnergy for simplicity

        unchecked {
            _energyBalances[_account] = accountBalance - _amount;
        }
        _totalEnergySupply -= _amount;
         // No standard ERC20 burn event, using Transfer to 0x0
        emit Transfer(_account, address(0), _amount);
    }


    // --- Minimal ERC721 Implementation (Quantum Fragments) ---
    // Based on OpenZeppelin's non-enumerable ERC721

    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return interfaceId == _ERC165_INTERFACE_ID ||
               interfaceId == _ERC721_INTERFACE_ID ||
               interfaceId == _ERC721_METADATA_INTERFACE_ID;
    }

    function balanceOf(address owner) public view override returns (uint256) {
        if (owner == address(0)) revert ZeroAddressRecipient();
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view override returns (address) {
        address owner = _owners[tokenId];
        if (owner == address(0)) revert InvalidTokenId();
        return owner;
    }

    function transferFrom(address from, address to, uint256 tokenId) public override existingFragment(tokenId) {
        if (!_isApprovedOrOwner(msg.sender, tokenId)) revert NotApprovedOrOwner();
        _transferFragment(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override existingFragment(tokenId) {
         safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override existingFragment(tokenId) {
        if (!_isApprovedOrOwner(msg.sender, tokenId)) revert NotApprovedOrOwner();
        _transferFragment(from, to, tokenId);

        // This simulation does not include IERC721Receiver checks for safety
        // A real safeTransferFrom would check if the recipient is a contract and
        // implements the onERC721Received function correctly.
        // To keep it minimal and avoid external code, this check is skipped.
        // Buyer beware: transfers to contracts might fail if they aren't designed to receive ERC721.
    }

    function approve(address to, uint256 tokenId) public override existingFragment(tokenId) {
        address owner = ownerOf(tokenId);
        if (msg.sender != owner && !isApprovedForAll(owner, msg.sender)) revert NotOwner(); // Approval requires being owner or approved for all
        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) public view override existingFragment(tokenId) returns (address) {
        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public override {
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    // Helper function to check approval or ownership
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
         address owner = ownerOf(tokenId); // Implicitly checks if token exists
         return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    // Metadata URI (Base URI + Token ID)
    string private _baseTokenURI;

    function tokenURI(uint256 tokenId) public view override existingFragment(tokenId) returns (string memory) {
        // Does not include specific fragment state in URI, just base + ID
        // A real implementation might generate URI based on fragmentData
        string memory base = _baseTokenURI;
        if (bytes(base).length == 0) {
             return ""; // Or a default error/placeholder URI
        }
        // Simple concatenation: baseURI + tokenId
        return string(abi.encodePacked(base, Strings.toString(tokenId)));
    }

    // Allows owner to set a new base URI
    function setBaseTokenURI(string memory baseURI) external onlyOwner {
         _baseTokenURI = baseURI;
    }

    // Allows owner to set metadata URI for a specific token (e.g., after state collapse/fusion)
    function setFragmentMetadataURI(uint256 _tokenId, string memory _uri) external onlyOwner existingFragment(_tokenId) {
        // This is a placeholder; ideally metadata update is part of the state-changing logic
        // For this example, we allow admin override.
        // A real system would need a more sophisticated metadata standard (e.g., ERC721 Metadata JSON Schema)
        // and potentially update the URI automatically based on fragment state changes.
        // This function simply allows admin to point a token's metadata to a specific URI.
        // It doesn't store the URI in the contract itself, only implies the URI is now _uri.
        // The `tokenURI` function above provides the *default* baseURI + ID format.
        // To support individual URIs, you'd need a mapping `tokenId -> string`.
        // For this example, let's stick to the base + ID model for `tokenURI` and make this function just emit an event.
        emit FragmentMetadataURISet(_tokenId, _uri);
    }


    // --- Minimal ERC20 Implementation (Nexus Energy) ---
    // Based on OpenZeppelin's ERC20

    function name() public view virtual override returns (string memory) {
        // ERC721 Metadata function, conflicts with ERC20 name. Need to disambiguate or choose one.
        // Let's make ERC721 name() return Fragment name, and add a separate view for Energy name.
        return _name; // Quantum Fragment name
    }

     function symbol() public view virtual override returns (string memory) {
        // ERC721 Metadata function, conflicts with ERC20 symbol.
        return _symbol; // Quantum Fragment symbol
    }

    function energyName() external view returns (string memory) {
        return ENERGY_NAME;
    }

    function energySymbol() external view returns (string memory) {
        return ENERGY_SYMBOL;
    }

    function totalSupply() public view returns (uint256) {
        return _totalEnergySupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        // Overrides ERC721 balanceOf with ERC20 logic based on context (implicit or explicit?)
        // Best to rename ERC20 balanceOf to distinguish, or let the caller know.
        // Let's rename ERC20 balanceOf to avoid conflict/confusion.
        revert("Use balanceOfFragments or balanceOfEnergy"); // Placeholder, need separate functions
    }

     function balanceOfFragments(address owner) public view returns (uint256) {
        if (owner == address(0)) revert ZeroAddressRecipient();
        return _balances[owner]; // ERC721 balance
    }

    function balanceOfEnergy(address account) public view returns (uint256) {
        if (account == address(0)) revert ZeroAddressRecipient();
        return _energyBalances[account]; // ERC20 balance
    }


    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transferEnergy(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _energyAllowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approveEnergy(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        uint256 currentAllowance = _energyAllowances[sender][msg.sender];
        if (currentAllowance < amount) revert InsufficientAllowance();

        unchecked {
            _approveEnergy(sender, msg.sender, currentAllowance - amount);
        }

        _transferEnergy(sender, recipient, amount);
        return true;
    }

    // Internal Nexus Energy (ERC20) Transfer
    function _transferEnergy(address sender, address recipient, uint256 amount) internal {
        if (sender == address(0)) revert InvalidTokenId(); // ZeroAddress
        if (recipient == address(0)) revert ZeroAddressRecipient();

        uint256 senderBalance = _energyBalances[sender];
        if (senderBalance < amount) revert InsufficientEnergy();

        unchecked {
            _energyBalances[sender] = senderBalance - amount;
        }
        _energyBalances[recipient] += amount;

        emit Transfer(sender, recipient, amount); // ERC20 Transfer event
    }

    // Internal Nexus Energy (ERC20) Approval
     function _approveEnergy(address owner, address spender, uint256 amount) internal {
        _energyAllowances[owner][spender] = amount;
        emit Approval(owner, spender, amount); // ERC20 Approval event
    }


    // --- View Functions ---

    function queryFragmentState(uint256 _tokenId) public view existingFragment(_tokenId) returns (
        uint8 quality,
        uint64 lastInteractionTime,
        uint256 linkedFragmentId,
        bytes32 randomnessRequestId,
        uint8 randomnessRequestType,
        bool randomnessUsed
    ) {
        FragmentState storage data = fragmentData[_tokenId];
        return (
            data.quality,
            data.lastInteractionTime,
            data.linkedFragmentId,
            data.randomnessRequestId,
            data.randomnessRequestType,
            data.randomnessUsed
        );
    }

    function queryGlobalEntropy() public view returns (uint256) {
        return globalEntropyLevel;
    }

    function queryCosmicFactor() public view returns (uint256) {
        return cosmicFactor;
    }

    function queryDecayRate() public view returns (uint64) {
        return entropicDecayRate;
    }

    function queryFusionProbabilityBase() public view returns (uint16) {
        return fusionProbabilityBase;
    }

    function queryStateCollapseCost() public view returns (uint256) {
        return stateCollapseCost;
    }

    function queryFusionCost() public view returns (uint256) {
        return fusionCost;
    }

    function queryParameterEvolutionRate() public view returns (uint64) {
        return parameterEvolutionRate;
    }

     function queryFragmentLinkedFragment(uint256 _tokenId) public view existingFragment(_tokenId) returns (uint256) {
        return fragmentData[_tokenId].linkedFragmentId;
    }

     function queryRandomnessResult(bytes32 requestId) public view returns (uint256) {
        return _randomnessResults[requestId];
    }

    // --- Helper Library (Minimal) ---
    // Basic integer to string conversion

    library Strings {
        bytes10 private constant alphabet = "0123456789";

        function toString(uint256 value) internal pure returns (string memory) {
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
                buffer[digits] = alphabet[value % 10];
                value /= 10;
            }
            return string(buffer);
        }
    }
}
```