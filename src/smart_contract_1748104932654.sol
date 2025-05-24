Okay, let's create a concept for a smart contract that is more than just a static NFT. We'll design a "Quantum Leaper" NFT, which represents an entity that can evolve, interact, and attempt a probabilistic "leap" to a higher state, influenced by time, other NFTs, and randomness.

This contract will combine:
1.  **Dynamic Attributes:** NFT properties (Energy, Stability, Potential) that change over time and based on actions.
2.  **NFT Interaction:** A unique "Entanglement" mechanism where two owned NFTs can be linked, affecting their stats.
3.  **Probabilistic State Change:** A "Quantum Leap" function using Chainlink VRF for a chance to reach a permanent higher state.
4.  **Time-Based Mechanics:** Decay and growth of attributes based on time elapsed.
5.  **Bonding/Staking:** An option to "bond" an NFT for passive benefits.

It will use standard interfaces (ERC721, ERC2981) and integrate with Chainlink VRF.

---

## QuantumLeapNFT Smart Contract

**Concept:** A dynamic NFT representing a "Quantum Leaper" entity. Leapers possess attributes (Energy, Stability, Potential) that evolve based on time, user interactions, and entanglement with other Leapers. They can attempt a probabilistic "Quantum Leap" to achieve a permanent, high-rarity state.

**Key Features:**

*   ERC721 standard for ownership.
*   ERC2981 standard for royalties.
*   Dynamic attributes (Energy, Stability, Potential) stored and calculated.
*   Time-based decay (Energy) and growth (Potential).
*   User actions (Recharge Energy, Entangle, Disentangle, Bond, Unbond).
*   Leaper Entanglement: Linking two owned Leapers for mutual benefit (e.g., Stability bonus).
*   Quantum Leap: A function attempting to transition to a permanent "Quantum State" using Chainlink VRF for a probabilistic outcome based on attributes.
*   Pausable functionality.
*   Owner-configurable parameters and fee withdrawal.

**Data Structures:**

*   `struct LeaperAttributes`: Stores the core state of each Leaper NFT.

**Outline:**

1.  Imports (ERC721, Ownable, ERC2981, Pausable, VRFConsumerBaseV2).
2.  Error Definitions.
3.  Struct Definition (`LeaperAttributes`).
4.  State Variables (Mappings, Counters, Config, VRF).
5.  Events.
6.  Modifiers.
7.  Constructor (Initializes contracts, sets VRF config).
8.  ERC721 Core Functions (`balanceOf`, `ownerOf`, `approve`, `getApproved`, `setApprovalForAll`, `isApprovedForAll`, `transferFrom`, `safeTransferFrom`). *Inherited/handled by OpenZeppelin.*
9.  ERC721/ERC2981/VRF Functions (`tokenURI`, `supportsInterface`, `royaltyInfo`, `fulfillRandomWords`).
10. Leaper State Calculation (Internal Helper).
11. User Interaction Functions (`mint`, `getLeaperAttributes`, `rechargeEnergy`, `entangleLeapers`, `disentangleLeapers`, `bondLeaper`, `unbondLeaper`, `requestQuantumLeap`).
12. Owner Configuration & Utility Functions (`setVRFConfig`, `setLeapCost`, `setMaxAttributes`, `setDecayGrowthRates`, `setLeapProbabilityFactors`, `setRoyaltyInfo`, `pause`, `unpause`, `withdrawFees`, `rescueETH`).

**Function Summary:**

1.  `constructor()`: Initializes the contract, setting up base contracts (ERC721, Ownable, Pausable, ERC2981) and Chainlink VRF parameters.
2.  `supportsInterface(bytes4 interfaceId) public view override`: Returns true if the contract supports the given interface (ERC721, ERC2981, VRF).
3.  `tokenURI(uint256 tokenId) public view override`: Returns the metadata URI for a given token ID. Can be dynamic based on Leaper state.
4.  `royaltyInfo(uint256 _tokenId, uint256 _salePrice) public view override returns (address receiver, uint256 royaltyAmount)`: Implements ERC2981 royalty standard.
5.  `fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override`: VRF callback function. Processes the randomness to determine the outcome of a Quantum Leap attempt.
6.  `mint() external payable whenNotPaused`: Mints a new Quantum Leaper NFT for the caller. Requires a mint fee. Initializes attributes and timestamp.
7.  `getLeaperAttributes(uint256 tokenId) public view returns (...)`: Returns the *calculated* current attributes of a Leaper, accounting for time decay/growth and entanglement bonuses.
8.  `getRawLeaperAttributes(uint256 tokenId) public view returns (...)`: Returns the raw stored attributes of a Leaper.
9.  `rechargeEnergy(uint256 tokenId) external payable whenNotPaused`: Allows the owner to pay a fee to recharge the Leaper's energy.
10. `entangleLeapers(uint256 tokenId1, uint256 tokenId2) external whenNotPaused`: Allows the owner to entangle two of their Leapers. They must be unentangled. Provides a temporary stability bonus.
11. `disentangleLeapers(uint256 tokenId) external whenNotPaused`: Allows the owner to disentangle a Leaper.
12. `bondLeaper(uint256 tokenId) external whenNotPaused`: Allows the owner to bond a Leaper, locking it for a duration. Provides a passive potential growth bonus during bonding.
13. `unbondLeaper(uint256 tokenId) external whenNotPaused`: Allows the owner to unbond a Leaper after the bonding duration has passed.
14. `requestQuantumLeap(uint256 tokenId) external payable whenNotPaused`: Initiates a Quantum Leap attempt for the Leaper. Requires energy, potentially entanglement, and pays a VRF request fee. Requests randomness from Chainlink.
15. `setVRFConfig(address _vrfCoordinator, bytes32 _keyHash, uint64 _subscriptionId, uint32 _callbackGasLimit, uint16 _requestConfirmations) external onlyOwner`: Allows the owner to update Chainlink VRF configuration.
16. `setMintCost(uint256 _mintCost) external onlyOwner`: Allows the owner to set the cost of minting a new Leaper.
17. `setLeapCost(uint256 _leapCost) external onlyOwner`: Allows the owner to set the cost of attempting a Quantum Leap.
18. `setMaxAttributes(uint16 _maxEnergy, uint16 _maxStability, uint16 _maxPotential) external onlyOwner`: Allows the owner to set the maximum possible values for attributes.
19. `setDecayGrowthRates(uint16 _energyDecayRatePerSecond, uint16 _potentialGrowthRatePerSecond, uint16 _bondedPotentialGrowthRatePerSecond) external onlyOwner`: Allows the owner to set the per-second rates for time-based attribute changes.
20. `setLeapProbabilityFactors(uint16 _stabilityFactor, uint16 _potentialFactor, uint16 _baseSuccessChance) external onlyOwner`: Allows the owner to tune the parameters that influence the success probability of a Quantum Leap.
21. `setEntanglementBonus(uint16 _stabilityBonus) external onlyOwner`: Allows the owner to set the stability bonus granted by entanglement.
22. `setRoyaltyInfo(address receiver, uint96 feeNumerator) external onlyOwner`: Allows the owner to update the royalty recipient and percentage.
23. `pause() external onlyOwner`: Pauses certain core functions (mint, recharge, entangle, bond, leap request).
24. `unpause() external onlyOwner`: Unpauses the contract.
25. `withdrawFees() external onlyOwner`: Allows the owner to withdraw collected ETH fees.
26. `rescueETH() external onlyOwner`: Allows the owner to withdraw accidentally sent ETH (excluding protocol fees). *Note: This is a basic rescue, careful implementation needed.*

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol"; // For royalty standard
import "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol"; // For Chainlink VRF

// Outline:
// 1. Imports
// 2. Error Definitions
// 3. Struct Definition (LeaperAttributes)
// 4. State Variables (Mappings, Counters, Config, VRF)
// 5. Events
// 6. Modifiers
// 7. Constructor
// 8. Standard ERC721/ERC2981/VRF Functions
// 9. Leaper State Calculation (Internal Helper)
// 10. User Interaction Functions
// 11. Owner Configuration & Utility Functions

// Function Summary:
// 1. constructor(): Initializes the contract, setting up base contracts and Chainlink VRF parameters.
// 2. supportsInterface(bytes4 interfaceId): Returns true if the contract supports ERC721, ERC2981, VRF.
// 3. tokenURI(uint256 tokenId): Returns the metadata URI for a token. Can be dynamic.
// 4. royaltyInfo(uint256 _tokenId, uint256 _salePrice): Implements ERC2981 royalty.
// 5. fulfillRandomWords(uint256 requestId, uint256[] memory randomWords): VRF callback for Leap outcome.
// 6. mint() payable: Mints a new Leaper.
// 7. getLeaperAttributes(uint256 tokenId) view: Gets calculated current attributes (dynamic).
// 8. getRawLeaperAttributes(uint256 tokenId) view: Gets raw stored attributes.
// 9. rechargeEnergy(uint256 tokenId) payable: Pays to recharge Leaper energy.
// 10. entangleLeapers(uint256 tokenId1, uint256 tokenId2): Entangles two owner's Leapers.
// 11. disentangleLeapers(uint256 tokenId): Disentangles a Leaper.
// 12. bondLeaper(uint256 tokenId): Bonds a Leaper for a duration (potential growth boost).
// 13. unbondLeaper(uint256 tokenId): Unbonds a Leaper after duration.
// 14. requestQuantumLeap(uint256 tokenId) payable: Initiates a Quantum Leap attempt (requests VRF).
// 15. setVRFConfig(...): Owner sets VRF parameters.
// 16. setMintCost(uint256 _mintCost): Owner sets mint fee.
// 17. setLeapCost(uint256 _leapCost): Owner sets Leap attempt fee.
// 18. setMaxAttributes(...): Owner sets max attribute caps.
// 19. setDecayGrowthRates(...): Owner sets time-based decay/growth rates.
// 20. setLeapProbabilityFactors(...): Owner sets factors for Leap success chance.
// 21. setEntanglementBonus(uint16 _stabilityBonus): Owner sets entanglement bonus.
// 22. setRoyaltyInfo(address receiver, uint96 feeNumerator): Owner sets royalty info.
// 23. pause(): Owner pauses core functions.
// 24. unpause(): Owner unpauses.
// 25. withdrawFees(): Owner withdraws collected fees.
// 26. rescueETH(): Owner rescues accidentally sent ETH.


/// @title QuantumLeapNFT
/// @dev A dynamic NFT contract where entities (Leapers) evolve based on time, interaction, and randomness.
contract QuantumLeapNFT is ERC721, Ownable, Pausable, ERC721Burnable, IERC2981, VRFConsumerBaseV2 {

    // 2. Error Definitions
    error QuantumLeapNFT__InvalidTokenId();
    error QuantumLeapNFT__NotLeaperOwner();
    error QuantumLeapNFT__AlreadyEntangled();
    error QuantumLeapNFT__NotEntangled();
    error QuantumLeapNFT__CannotEntangleSelf();
    error QuantumLeapNFT__NotBonded();
    error QuantumLeapNFT__AlreadyBonded();
    error QuantumLeapNFT__BondDurationNotPassed(uint64 releaseTime);
    error QuantumLeapNFT__InsufficientEnergy(uint16 required, uint16 available);
    error QuantumLeapNFT__InvalidBondDuration();
    error QuantumLeapNFT__InsufficientPayment(uint256 required, uint256 sent);
    error QuantumLeapNFT__PaymentOverflow();
    error QuantumLeapNFT__NoFeesToWithdraw();
    error QuantumLeapNFT__VRFConfigNotSet();
    error QuantumLeapNFT__VRFRequestFailed();
    error QuantumLeapNFT__VRFCallbackMismatch();
    error QuantumLeapNFT__LeapInProgress();
    error QuantumLeapNFT__AlreadyInQuantumState();

    // 3. Struct Definition
    /// @dev Stores the mutable attributes and state for each Leaper NFT.
    struct LeaperAttributes {
        uint64 lastUpdateTime; // Timestamp of the last state-changing action (mint, recharge, entangle, bond, leap)
        uint16 energy;         // Represents vitality, decays over time
        uint16 stability;      // Represents resilience, affects Leap success
        uint16 potential;      // Represents growth potential, increases over time, boosted by bonding/entanglement
        uint8 rarityScore;     // Base rarity, can be increased significantly by achieving Quantum State
        bool isInQuantumState; // Permanent state achieved via a successful Leap
        uint256 entangledWithId; // Token ID of the Leaper this one is entangled with (0 if not entangled)
        uint64 bondReleaseTime; // Timestamp when bonding ends (0 if not bonded)
        uint16 leapAttempts;   // Count of Quantum Leap attempts
        uint256 pendingLeapRequestId; // Chainlink VRF Request ID for pending Leap outcome (0 if none)
    }

    // 4. State Variables
    uint256 private _nextTokenId; // Counter for token IDs

    // Mapping from token ID to its Leaper attributes
    mapping(uint256 => LeaperAttributes) private _leapers;

    // VRF Configuration
    address private s_vrfCoordinator;
    bytes32 private s_keyHash;
    uint64 private s_subscriptionId;
    uint32 private s_callbackGasLimit;
    uint16 private s_requestConfirmations;

    // Mapping from VRF Request ID to Token ID for tracking pending leaps
    mapping(uint256 => uint256) private s_requestIdToTokenId;

    // Configurable Costs
    uint256 public mintCost = 0.01 ether;
    uint256 public leapAttemptCost = 0.005 ether;

    // Configurable Attribute Caps
    uint16 public maxEnergy = 1000;
    uint16 public maxStability = 1000;
    uint16 public maxPotential = 1000;
    uint8 public maxRarity = 100; // Max base rarity before Quantum State
    uint8 public quantumStateRarityBonus = 155; // Bonus added for Quantum State (e.g., max 100 + 155 = 255 max)

    // Configurable Decay/Growth Rates (per second, scaled by 1000)
    // e.g., 10 means 0.01 energy lost per second
    uint16 public energyDecayRatePerSecond = 10;
    uint16 public potentialGrowthRatePerSecond = 5;
    uint16 public bondedPotentialGrowthRatePerSecond = 15; // Faster growth when bonded

    // Configurable Leap Probability Factors
    // Higher factors mean attributes have a stronger influence on success chance
    uint16 public stabilityFactor = 2; // How much Stability affects chance
    uint16 public potentialFactor = 3; // How much Potential affects chance
    uint16 public baseLeapSuccessChance = 10; // Base success chance (out of 1000)

    // Configurable Interaction Bonuses
    uint16 public entanglementStabilityBonus = 100;

    // Configurable Bonding Duration (in seconds)
    uint64 public defaultBondDuration = 30 days; // Example: 30 days in seconds (30 * 24 * 60 * 60)

    // Royalty Information
    address public royaltyReceiver;
    uint96 public royaltyFeeNumerator; // e.g., 100 for 10% (10000 basis points)

    // Collected Protocol Fees
    uint256 private _protocolFees;

    // 5. Events
    event LeaperMinted(uint256 indexed tokenId, address indexed owner, uint64 initialTimestamp);
    event EnergyRecharged(uint256 indexed tokenId, address indexed owner, uint16 newEnergy);
    event LeaperEntangled(uint256 indexed tokenId1, uint256 indexed tokenId2, address indexed owner);
    event LeaperDisentangled(uint256 indexed tokenId1, uint256 indexed tokenId2, address indexed owner);
    event LeaperBonded(uint256 indexed tokenId, address indexed owner, uint64 releaseTime);
    event LeaperUnbonded(uint256 indexed tokenId, address indexed owner);
    event QuantumLeapAttempted(uint256 indexed tokenId, address indexed owner, uint256 requestId);
    event QuantumLeapSucceeded(uint256 indexed tokenId, uint16 finalRarity, uint16 finalPotential, uint16 finalStability);
    event QuantumLeapFailed(uint256 indexed tokenId, uint16 finalRarity, uint16 finalPotential, uint16 finalStability);
    event LeaperStateUpdated(uint256 indexed tokenId, uint64 lastUpdateTime, uint16 energy, uint16 stability, uint16 potential, uint8 rarityScore, bool isInQuantumState, uint256 entangledWithId, uint64 bondReleaseTime);
    event ConfigUpdated(string paramName, uint256 newValue);
    event RoyaltyUpdated(address indexed receiver, uint96 feeNumerator);
    event FeesWithdrawn(address indexed receiver, uint256 amount);
    event ETHRescued(address indexed receiver, uint256 amount);

    // 6. Modifiers
    modifier isLeaperExists(uint256 tokenId) {
        if (!_exists(tokenId)) {
            revert QuantumLeapNFT__InvalidTokenId();
        }
        _;
    }

    modifier isLeaperOwner(uint256 tokenId) {
        if (ownerOf(tokenId) != msg.sender) {
            revert QuantumLeapNFT__NotLeaperOwner();
        }
        _;
    }

    // 7. Constructor
    /// @param name_ NFT Collection Name
    /// @param symbol_ NFT Collection Symbol
    /// @param vrfCoordinator_ Address of the VRF Coordinator contract
    /// @param keyHash_ The key hash for the VRF service
    /// @param subscriptionId_ The VRF subscription ID
    /// @param callbackGasLimit_ The gas limit for the VRF callback function
    /// @param requestConfirmations_ The number of block confirmations required for VRF
    /// @param initialRoyaltyReceiver The initial address to receive royalties
    /// @param initialRoyaltyFeeNumerator The initial royalty percentage (e.g., 100 for 10%)
    constructor(
        string memory name_,
        string memory symbol_,
        address vrfCoordinator_,
        bytes32 keyHash_,
        uint64 subscriptionId_,
        uint32 callbackGasLimit_,
        uint16 requestConfirmations_,
        address initialRoyaltyReceiver,
        uint96 initialRoyaltyFeeNumerator
    ) ERC721(name_, symbol_) Ownable(msg.sender) Pausable() VRFConsumerBaseV2(vrfCoordinator_) {
        s_vrfCoordinator = vrfCoordinator_;
        s_keyHash = keyHash_;
        s_subscriptionId = subscriptionId_;
        s_callbackGasLimit = callbackGasLimit_;
        s_requestConfirmations = requestConfirmations_;

        royaltyReceiver = initialRoyaltyReceiver;
        royaltyFeeNumerator = initialRoyaltyFeeNumerator;
    }

    // 8. Standard ERC721/ERC2981/VRF Functions

    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, VRFConsumerBaseV2, IERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    /// @dev See {ERC721-tokenURI}.
    /// This can be extended to return dynamic metadata based on Leaper state.
    function tokenURI(uint256 tokenId) public view override isLeaperExists(tokenId) returns (string memory) {
        // Example: simple placeholder. Replace with actual metadata logic.
        // Could generate metadata URL based on attributes or link to an off-chain service.
        return string(abi.encodePacked("ipfs://BASE_METADATA_URI/", Strings.toString(tokenId)));
    }

    /// @dev See {IERC2981-royaltyInfo}.
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) public view override returns (address receiver, uint256 royaltyAmount) {
        // We don't use tokenId specific royalty, just contract-level config
        if (royaltyReceiver == address(0) || royaltyFeeNumerator == 0) {
             return (address(0), 0);
        }
        uint256 totalRoyalty = (_salePrice * royaltyFeeNumerator) / 10000; // Fee numerator is basis points
        return (royaltyReceiver, totalRoyalty);
    }

    /// @dev Callback function used by VRF Coordinator. Processes the randomness for the Quantum Leap.
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        uint256 tokenId = s_requestIdToTokenId[requestId];
        delete s_requestIdToTokenId[requestId]; // Clean up mapping

        if (tokenId == 0 || !_exists(tokenId)) {
            // Token might have been burned or mapping was somehow corrupted
            // Log an error or handle appropriately, cannot proceed
             emit VRFCallbackMismatch(); // Custom event for logging
            return;
        }

        LeaperAttributes storage leaper = _leapers[tokenId];

        if (leaper.pendingLeapRequestId != requestId) {
             // Mismatch between pending request and received request.
             // This indicates an unexpected state. Log or handle.
             emit VRFCallbackMismatch(); // Custom event for logging
            leaper.pendingLeapRequestId = 0; // Reset pending status
             return;
        }

        // Get the randomness result
        uint256 randomNumber = randomWords[0];

        // Calculate success probability based on *current* attributes
        // Note: Attributes here should be the ones *at the time the request was made*
        // OR we recalculate. Recalculating based on current time is simpler but means decay/growth
        // while waiting for VRF affects outcome. Let's use current calculated attributes.
        LeaperAttributes memory currentCalculatedAttributes = _getCalculatedAttributes(tokenId, block.timestamp);

        uint256 successThreshold = _calculateLeapSuccessChance(
            currentCalculatedAttributes.stability,
            currentCalculatedAttributes.potential
        );

        bool success = (randomNumber % 1000) < successThreshold; // Roll against a value out of 1000

        // Update Leaper state based on outcome
        if (success) {
            leaper.isInQuantumState = true;
            leaper.rarityScore = maxRarity + quantumStateRarityBonus; // Permanently increased rarity
             // Could also slightly boost other stats on success
             leaper.potential = Math.min(leaper.potential + 100, maxPotential); // Example bonus
             leaper.stability = Math.min(leaper.stability + 50, maxStability); // Example bonus

            emit QuantumLeapSucceeded(tokenId, leaper.rarityScore, leaper.potential, leaper.stability);
        } else {
            // Failure penalty - example: slight reduction in potential
            leaper.potential = (leaper.potential >= 50) ? (leaper.potential - 50) : 0;
             // Could also reduce stability or energy
            emit QuantumLeapFailed(tokenId, leaper.rarityScore, leaper.potential, leaper.stability);
        }

        leaper.lastUpdateTime = uint64(block.timestamp);
        leaper.pendingLeapRequestId = 0; // Reset pending flag
         // Disentangle automatically on Leap attempt outcome (success or fail)
         _disentangleLeaper(tokenId); // Use internal helper

        emit LeaperStateUpdated(
            tokenId,
            leaper.lastUpdateTime,
            leaper.energy,
            leaper.stability,
            leaper.potential,
            leaper.rarityScore,
            leaper.isInQuantumState,
            leaper.entangledWithId,
            leaper.bondReleaseTime
        );
    }

    // 9. Leaper State Calculation (Internal Helper)

    /// @dev Calculates the current, dynamic attributes of a Leaper based on time and state.
    /// Does NOT update the stored state. Use this for view functions.
    function _getCalculatedAttributes(uint256 tokenId, uint64 currentTime) internal view returns (LeaperAttributes memory) {
        LeaperAttributes storage rawLeaper = _leapers[tokenId];
        LeaperAttributes memory calculatedLeaper = rawLeaper; // Start with raw values

        // No decay/growth if already in Quantum State or if bond duration is active (potential boost instead)
        if (!rawLeaper.isInQuantumState) {
             uint66 timeElapsed = currentTime - rawLeaper.lastUpdateTime; // Use uint66 for safer duration calc

             // Apply Energy Decay
             // Energy can only decay down to a minimum (e.g., 0)
             uint256 energyDecay = (uint256(timeElapsed) * energyDecayRatePerSecond) / 1000;
             calculatedLeaper.energy = uint16(Math.max(int256(calculatedLeaper.energy) - int256(energyDecay), 0)); // Prevent underflow

             // Apply Potential Growth (different rate if bonded)
             if (rawLeaper.bondReleaseTime == 0 || currentTime < rawLeaper.bondReleaseTime) { // Not bonded or bonded and duration not passed
                  // Apply normal or bonded growth
                 uint256 potentialGrowth = (uint256(timeElapsed) * (rawLeaper.bondReleaseTime > 0 ? bondedPotentialGrowthRatePerSecond : potentialGrowthRatePerSecond)) / 1000;
                 calculatedLeaper.potential = uint16(Math.min(uint256(calculatedLeaper.potential) + potentialGrowth, maxPotential));
             } else {
                  // If bonded duration *has* passed, potential growth stops until unbonded
             }
        }

        // Apply Entanglement Bonus
        if (rawLeaper.entangledWithId != 0) {
             calculatedLeaper.stability = uint16(Math.min(uint256(calculatedLeaper.stability) + entanglementStabilityBonus, maxStability));
        }

        return calculatedLeaper;
    }

    /// @dev Internal helper to update a Leaper's stored state and emit event.
    function _updateLeaperState(uint256 tokenId, LeaperAttributes memory newAttributes) internal {
        LeaperAttributes storage leaper = _leapers[tokenId];
        leaper.lastUpdateTime = newAttributes.lastUpdateTime;
        leaper.energy = newAttributes.energy;
        leaper.stability = newAttributes.stability;
        leaper.potential = newAttributes.potential;
        leaper.rarityScore = newAttributes.rarityScore;
        leaper.isInQuantumState = newAttributes.isInQuantumState;
        leaper.entangledWithId = newAttributes.entangledWithId;
        leaper.bondReleaseTime = newAttributes.bondReleaseTime;
        leaper.leapAttempts = newAttributes.leapAttempts;
        leaper.pendingLeapRequestId = newAttributes.pendingLeapRequestId;

        emit LeaperStateUpdated(
            tokenId,
            leaper.lastUpdateTime,
            leaper.energy,
            leaper.stability,
            leaper.potential,
            leaper.rarityScore,
            leaper.isInQuantumState,
            leaper.entangledWithId,
            leaper.bondReleaseTime
        );
    }

    /// @dev Calculates the probability of a successful Quantum Leap based on attributes (out of 1000).
    function _calculateLeapSuccessChance(uint16 stability, uint16 potential) internal view returns (uint256) {
        // Example calculation: Base chance + (Stability * factor) + (Potential * factor)
        uint256 chance = baseLeapSuccessChance;
        chance += (uint256(stability) * stabilityFactor) / 1000; // Scale factors to attribute range
        chance += (uint256(potential) * potentialFactor) / 1000;

        // Clamp chance to a reasonable maximum (e.g., 95%) to prevent guaranteed success
        return Math.min(chance, 950); // Max 950 out of 1000 (95%)
    }

    /// @dev Internal helper to disentangle a single leaper without checks (used by public disentangle and leap outcome).
    function _disentangleLeaper(uint256 tokenId) internal {
        LeaperAttributes storage leaper = _leapers[tokenId];
        if (leaper.entangledWithId != 0) {
             uint256 entangledTokenId = leaper.entangledWithId;
            leaper.entangledWithId = 0;
            // Find the other half if it still exists and is entangled with this one
            if (_exists(entangledTokenId)) {
                LeaperAttributes storage otherLeaper = _leapers[entangledTokenId];
                if (otherLeaper.entangledWithId == tokenId) {
                     otherLeaper.entangledWithId = 0;
                     _updateLeaperState(entangledTokenId, otherLeaper); // Update other leaper's state
                }
            }
            _updateLeaperState(tokenId, leaper); // Update this leaper's state
            emit LeaperDisentangled(tokenId, entangledTokenId, ownerOf(tokenId));
        }
    }


    // 10. User Interaction Functions

    /// @dev Mints a new Leaper NFT.
    function mint() external payable whenNotPaused returns (uint256) {
        if (msg.value < mintCost) {
            revert QuantumLeapNFT__InsufficientPayment(mintCost, msg.value);
        }

        uint256 newTokenId = _nextTokenId++;
        _mint(msg.sender, newTokenId); // ERC721 standard mint

        // Initialize Leaper attributes
        _leapers[newTokenId] = LeaperAttributes({
            lastUpdateTime: uint64(block.timestamp),
            energy: maxEnergy, // Starts with full energy
            stability: 100, // Base stability
            potential: 100, // Base potential
            rarityScore: 1, // Base rarity
            isInQuantumState: false,
            entangledWithId: 0,
            bondReleaseTime: 0,
            leapAttempts: 0,
            pendingLeapRequestId: 0
        });

        // Store excess payment as protocol fees (if any)
        if (msg.value > mintCost) {
             _protocolFees += (msg.value - mintCost);
        }

        emit LeaperMinted(newTokenId, msg.sender, uint64(block.timestamp));
        emit LeaperStateUpdated(
            newTokenId,
            uint64(block.timestamp),
            maxEnergy,
            100, // Initial stability
            100, // Initial potential
            1,   // Initial rarity
            false,
            0,
            0
        );

        return newTokenId;
    }

    /// @dev Returns the currently calculated attributes of a Leaper.
    function getLeaperAttributes(uint256 tokenId) public view isLeaperExists(tokenId) returns (
        uint64 lastUpdateTime,
        uint16 energy,
        uint16 stability,
        uint16 potential,
        uint8 rarityScore,
        bool isInQuantumState,
        uint256 entangledWithId,
        uint64 bondReleaseTime,
        uint16 leapAttempts,
        uint256 pendingLeapRequestId // Include pending request ID
    ) {
        LeaperAttributes memory currentLeaper = _getCalculatedAttributes(tokenId, uint64(block.timestamp));
        // Copy raw values that are not calculated dynamically (rarity, state, entanglement, bond, attempts, pending VRF)
        currentLeaper.rarityScore = _leapers[tokenId].rarityScore;
        currentLeaper.isInQuantumState = _leapers[tokenId].isInQuantumState;
        currentLeaper.entangledWithId = _leapers[tokenId].entangledWithId;
        currentLeaper.bondReleaseTime = _leapers[tokenId].bondReleaseTime;
        currentLeaper.leapAttempts = _leapers[tokenId].leapAttempts;
        currentLeaper.pendingLeapRequestId = _leapers[tokenId].pendingLeapRequestId;


        return (
            currentLeaper.lastUpdateTime,
            currentLeaper.energy,
            currentLeaper.stability,
            currentLeaper.potential,
            currentLeaper.rarityScore,
            currentLeaper.isInQuantumState,
            currentLeaper.entangledWithId,
            currentLeaper.bondReleaseTime,
            currentLeaper.leapAttempts,
            currentLeaper.pendingLeapRequestId
        );
    }

    /// @dev Returns the raw stored attributes of a Leaper without dynamic calculation.
    function getRawLeaperAttributes(uint256 tokenId) public view isLeaperExists(tokenId) returns (LeaperAttributes memory) {
        return _leapers[tokenId];
    }

    /// @dev Recharges a Leaper's energy to max.
    function rechargeEnergy(uint256 tokenId) external payable whenNotPaused isLeaperOwner(tokenId) isLeaperExists(tokenId) {
        // Example fee: fixed cost or scales with energy recharged? Let's use fixed cost for simplicity.
        uint256 rechargeCost = 0.001 ether; // Example fee

        if (msg.value < rechargeCost) {
             revert QuantumLeapNFT__InsufficientPayment(rechargeCost, msg.value);
        }

        LeaperAttributes storage leaper = _leapers[tokenId];
        LeaperAttributes memory currentLeaper = _getCalculatedAttributes(tokenId, uint64(block.timestamp));

        // Update stored state based on calculated state BEFORE applying recharge
        // This captures decay/growth up to this point
        _updateLeaperState(tokenId, currentLeaper);

        // Apply recharge
        leaper.energy = maxEnergy;
        leaper.lastUpdateTime = uint64(block.timestamp); // Update timestamp after action

        // Store excess payment as protocol fees
        if (msg.value > rechargeCost) {
             _protocolFees += (msg.value - rechargeCost);
        }

        emit EnergyRecharged(tokenId, msg.sender, leaper.energy);
         emit LeaperStateUpdated(
            tokenId,
            leaper.lastUpdateTime,
            leaper.energy,
            leaper.stability,
            leaper.potential,
            leaper.rarityScore,
            leaper.isInQuantumState,
            leaper.entangledWithId,
            leaper.bondReleaseTime
        );
    }

    /// @dev Entangles two Leapers owned by the caller.
    function entangleLeapers(uint256 tokenId1, uint256 tokenId2) external whenNotPaused isLeaperOwner(tokenId1) isLeaperOwner(tokenId2) isLeaperExists(tokenId1) isLeaperExists(tokenId2) {
        if (tokenId1 == tokenId2) {
             revert QuantumLeapNFT__CannotEntangleSelf();
        }

        LeaperAttributes storage leaper1 = _leapers[tokenId1];
        LeaperAttributes storage leaper2 = _leapers[tokenId2];

        if (leaper1.entangledWithId != 0 || leaper2.entangledWithId != 0) {
             revert QuantumLeapNFT__AlreadyEntangled();
        }
        if (leaper1.bondReleaseTime > block.timestamp || leaper2.bondReleaseTime > block.timestamp) {
            // Cannot entangle if either is bonded
             revert QuantumLeapNFT__AlreadyBonded(); // Re-using error, maybe needs new one like CannotEntangleBonded
        }


        // Update state for both Leapers
        LeaperAttributes memory currentLeaper1 = _getCalculatedAttributes(tokenId1, uint64(block.timestamp));
        LeaperAttributes memory currentLeaper2 = _getCalculatedAttributes(tokenId2, uint64(block.timestamp));

         // Update stored state based on calculated state BEFORE entanglement
         _updateLeaperState(tokenId1, currentLeaper1);
         _updateLeaperState(tokenId2, currentLeaper2);

        leaper1.entangledWithId = tokenId2;
        leaper2.entangledWithId = tokenId1;

        leaper1.lastUpdateTime = uint64(block.timestamp); // Update timestamp for stat calculation
        leaper2.lastUpdateTime = uint64(block.timestamp); // Update timestamp for stat calculation

        // Apply bonus dynamically in _getCalculatedAttributes, no need to store here

        emit LeaperEntangled(tokenId1, tokenId2, msg.sender);
         emit LeaperStateUpdated(
            tokenId1,
            leaper1.lastUpdateTime,
            leaper1.energy,
            leaper1.stability,
            leaper1.potential,
            leaper1.rarityScore,
            leaper1.isInQuantumState,
            leaper1.entangledWithId,
            leaper1.bondReleaseTime
        );
          emit LeaperStateUpdated(
            tokenId2,
            leaper2.lastUpdateTime,
            leaper2.energy,
            leaper2.stability,
            leaper2.potential,
            leaper2.rarityScore,
            leaper2.isInQuantumState,
            leaper2.entangledWithId,
            leaper2.bondReleaseTime
        );
    }

    /// @dev Disentangles a Leaper. Automatically disentangles the partner.
    function disentangleLeapers(uint256 tokenId) external whenNotPaused isLeaperOwner(tokenId) isLeaperExists(tokenId) {
        LeaperAttributes storage leaper = _leapers[tokenId];
        if (leaper.entangledWithId == 0) {
             revert QuantumLeapNFT__NotEntangled();
        }

        // Ensure calculated attributes up to this point are captured before disentangling
         LeaperAttributes memory currentLeaper = _getCalculatedAttributes(tokenId, uint64(block.timestamp));
         _updateLeaperState(tokenId, currentLeaper);

        _disentangleLeaper(tokenId); // Use internal helper
    }

    /// @dev Bonds a Leaper for a set duration, boosting passive potential growth.
    /// Cannot be bonded if entangled.
    function bondLeaper(uint256 tokenId) external whenNotPaused isLeaperOwner(tokenId) isLeaperExists(tokenId) {
        LeaperAttributes storage leaper = _leapers[tokenId];

        if (leaper.bondReleaseTime > block.timestamp) {
             revert QuantumLeapNFT__AlreadyBonded();
        }
        if (leaper.entangledWithId != 0) {
             revert QuantumLeapNFT__AlreadyEntangled(); // Re-using error, cannot bond if entangled
        }
        if (leaper.isInQuantumState) {
            // Cannot bond Leapers that have reached final state
             revert QuantumLeapNFT__AlreadyInQuantumState();
        }

        // Ensure calculated attributes up to this point are captured before bonding
         LeaperAttributes memory currentLeaper = _getCalculatedAttributes(tokenId, uint64(block.timestamp));
         _updateLeaperState(tokenId, currentLeaper);

        leaper.bondReleaseTime = uint64(block.timestamp + defaultBondDuration);
        leaper.lastUpdateTime = uint64(block.timestamp); // Update timestamp for potential growth calculation

        emit LeaperBonded(tokenId, msg.sender, leaper.bondReleaseTime);
         emit LeaperStateUpdated(
            tokenId,
            leaper.lastUpdateTime,
            leaper.energy,
            leaper.stability,
            leaper.potential,
            leaper.rarityScore,
            leaper.isInQuantumState,
            leaper.entangledWithId,
            leaper.bondReleaseTime
        );
    }

    /// @dev Unbonds a Leaper after the duration has passed.
    function unbondLeaper(uint256 tokenId) external whenNotPaused isLeaperOwner(tokenId) isLeaperExists(tokenId) {
        LeaperAttributes storage leaper = _leapers[tokenId];

        if (leaper.bondReleaseTime == 0) {
             revert QuantumLeapNFT__NotBonded();
        }
        if (block.timestamp < leaper.bondReleaseTime) {
             revert QuantumLeapNFT__BondDurationNotPassed(leaper.bondReleaseTime);
        }

         // Ensure calculated attributes up to this point are captured before unbonding
         LeaperAttributes memory currentLeaper = _getCalculatedAttributes(tokenId, uint64(block.timestamp));
         _updateLeaperState(tokenId, currentLeaper);

        leaper.bondReleaseTime = 0; // Reset bond state
        leaper.lastUpdateTime = uint64(block.timestamp); // Update timestamp to stop bonded growth calculation

        emit LeaperUnbonded(tokenId, msg.sender);
          emit LeaperStateUpdated(
            tokenId,
            leaper.lastUpdateTime,
            leaper.energy,
            leaper.stability,
            leaper.potential,
            leaper.rarityScore,
            leaper.isInQuantumState,
            leaper.entangledWithId,
            leaper.bondReleaseTime
        );
    }

    /// @dev Initiates a Quantum Leap attempt for the Leaper using Chainlink VRF.
    /// Requires energy and a fee.
    function requestQuantumLeap(uint256 tokenId) external payable whenNotPaused isLeaperOwner(tokenId) isLeaperExists(tokenId) {
        if (s_vrfCoordinator == address(0)) {
             revert QuantumLeapNFT__VRFConfigNotSet();
        }
         if (msg.value < leapAttemptCost) {
             revert QuantumLeapNFT__InsufficientPayment(leapAttemptCost, msg.value);
        }

        LeaperAttributes storage leaper = _leapers[tokenId];

        if (leaper.pendingLeapRequestId != 0) {
             revert QuantumLeapNFT__LeapInProgress();
        }
        if (leaper.isInQuantumState) {
             revert QuantumLeapNFT__AlreadyInQuantumState();
        }
         if (leaper.bondReleaseTime > block.timestamp) {
            // Cannot attempt leap if bonded
             revert QuantumLeapNFT__AlreadyBonded(); // Re-using error, cannot leap if bonded
        }

        // Get current calculated attributes to check energy and use for probability calculation in callback
        LeaperAttributes memory currentLeaper = _getCalculatedAttributes(tokenId, uint64(block.timestamp));

        // Require minimum energy (e.g., 100 energy units per attempt)
        uint16 energyRequired = 100; // Example cost
        if (currentLeaper.energy < energyRequired) {
             revert QuantumLeapNFT__InsufficientEnergy(energyRequired, currentLeaper.energy);
        }

         // Update stored state based on calculated state BEFORE deducting energy
         _updateLeaperState(tokenId, currentLeaper);

        // Deduct energy for the attempt
        leaper.energy -= energyRequired;
        leaper.leapAttempts++; // Increment attempt counter
        leaper.lastUpdateTime = uint64(block.timestamp); // Update timestamp

        // Request randomness from Chainlink VRF
        uint256 requestId = requestRandomWords(s_keyHash, s_subscriptionId, s_requestConfirmations, s_callbackGasLimit, 1); // Request 1 random word

        s_requestIdToTokenId[requestId] = tokenId; // Map request ID to token ID
        leaper.pendingLeapRequestId = requestId; // Store the pending request ID

         // Store excess payment as protocol fees
        if (msg.value > leapAttemptCost) {
             _protocolFees += (msg.value - leapAttemptCost);
        }

        emit QuantumLeapAttempted(tokenId, msg.sender, requestId);
         emit LeaperStateUpdated(
            tokenId,
            leaper.lastUpdateTime,
            leaper.energy,
            leaper.stability,
            leaper.potential,
            leaper.rarityScore,
            leaper.isInQuantumState,
            leaper.entangledWithId,
            leaper.bondReleaseTime
        );
    }

    // 11. Owner Configuration & Utility Functions

    /// @dev Allows the owner to update Chainlink VRF configuration.
    function setVRFConfig(
        address _vrfCoordinator,
        bytes32 _keyHash,
        uint64 _subscriptionId,
        uint32 _callbackGasLimit,
        uint16 _requestConfirmations
    ) external onlyOwner {
        s_vrfCoordinator = _vrfCoordinator;
        s_keyHash = _keyHash;
        s_subscriptionId = _subscriptionId;
        s_callbackGasLimit = _callbackGasLimit;
        s_requestConfirmations = _requestConfirmations;
        emit ConfigUpdated("VRFConfig", 0); // Generic event for config changes
    }

     /// @dev Allows the owner to set the cost of minting a new Leaper.
    function setMintCost(uint256 _mintCost) external onlyOwner {
        mintCost = _mintCost;
        emit ConfigUpdated("mintCost", _mintCost);
    }

     /// @dev Allows the owner to set the cost of attempting a Quantum Leap.
    function setLeapCost(uint256 _leapCost) external onlyOwner {
        leapAttemptCost = _leapCost;
        emit ConfigUpdated("leapAttemptCost", _leapCost);
    }

     /// @dev Allows the owner to set the maximum possible values for Leaper attributes.
    function setMaxAttributes(uint16 _maxEnergy, uint16 _maxStability, uint16 _maxPotential) external onlyOwner {
        maxEnergy = _maxEnergy;
        maxStability = _maxStability;
        maxPotential = _maxPotential;
         // Can add checks here if needed, e.g., > 0
        emit ConfigUpdated("maxEnergy", _maxEnergy); // Example, can add more specific events
    }

    /// @dev Allows the owner to set the per-second rates for time-based attribute changes.
    function setDecayGrowthRates(uint16 _energyDecayRatePerSecond, uint16 _potentialGrowthRatePerSecond, uint16 _bondedPotentialGrowthRatePerSecond) external onlyOwner {
        energyDecayRatePerSecond = _energyDecayRatePerSecond;
        potentialGrowthRatePerSecond = _potentialGrowthRatePerSecond;
        bondedPotentialGrowthRatePerSecond = _bondedPotentialGrowthRatePerSecond;
         // Can add checks, e.g., energyDecayRate > 0
         emit ConfigUpdated("energyDecayRatePerSecond", _energyDecayRatePerSecond);
    }

    /// @dev Allows the owner to tune the parameters that influence the success probability of a Quantum Leap.
    function setLeapProbabilityFactors(uint16 _stabilityFactor, uint16 _potentialFactor, uint16 _baseSuccessChance) external onlyOwner {
        stabilityFactor = _stabilityFactor;
        potentialFactor = _potentialFactor;
        baseLeapSuccessChance = _baseSuccessChance; // Ensure base chance is reasonable (e.g., <= 1000)
         emit ConfigUpdated("stabilityFactor", _stabilityFactor);
    }

    /// @dev Allows the owner to set the stability bonus granted by entanglement.
    function setEntanglementBonus(uint16 _stabilityBonus) external onlyOwner {
        entanglementStabilityBonus = _stabilityBonus;
        emit ConfigUpdated("entanglementStabilityBonus", _stabilityBonus);
    }

     /// @dev Allows the owner to update the royalty recipient and percentage.
     function setRoyaltyInfo(address receiver, uint96 feeNumerator) external onlyOwner {
         require(feeNumerator <= 10000, "Royalty fee numerator must be <= 10000"); // Max 100%
         royaltyReceiver = receiver;
         royaltyFeeNumerator = feeNumerator;
         emit RoyaltyUpdated(receiver, feeNumerator);
     }

    /// @dev See {Pausable-pause}.
    function pause() public onlyOwner override {
        _pause();
    }

    /// @dev See {Pausable-unpause}.
    function unpause() public onlyOwner override {
        _unpause();
    }

    /// @dev Allows the owner to withdraw accumulated protocol fees.
    function withdrawFees() external onlyOwner {
        if (_protocolFees == 0) {
            revert QuantumLeapNFT__NoFeesToWithdraw();
        }
        uint256 amount = _protocolFees;
        _protocolFees = 0;
        (bool success, ) = payable(owner()).call{value: amount}("");
        require(success, "Fee withdrawal failed");
        emit FeesWithdrawn(owner(), amount);
    }

    /// @dev Allows the owner to rescue accidentally sent ETH to the contract address (excluding fees).
    /// Use with caution.
    function rescueETH() external onlyOwner {
        uint256 contractBalance = address(this).balance;
        uint256 amountToRescue = contractBalance - _protocolFees; // Leave protocol fees in contract

        if (amountToRescue == 0) {
            // No accidental ETH to rescue
             return;
        }

        (bool success, ) = payable(owner()).call{value: amountToRescue}("");
        require(success, "ETH rescue failed");
        emit ETHRescued(owner(), amountToRescue);
    }

    // Helper functions for attribute calculations (can be made internal or view)
    // (These are already effectively used within _getCalculatedAttributes and _calculateLeapSuccessChance)

    // Helper for safe math if needed (using Solidy's built-in safety or OpenZeppelin Math)
    using Math for uint256;

    // Receive function to allow receiving ETH for fees
    receive() external payable {
        // ETH sent without calling a specific function is added to protocol fees
        // Could add requirements here, e.g., only if msg.sender is approved minter or similar
        _protocolFees += msg.value;
    }

    // Fallback function (optional, depending on desired contract behavior)
    // fallback() external payable {
    //     // Can handle arbitrary calls, potentially adding to fees or rejecting
    //     _protocolFees += msg.value;
    // }

}
```

**Explanation of Concepts and Novelty:**

1.  **Dynamic Attributes (`LeaperAttributes` struct, `_getCalculatedAttributes`):** Instead of static JSON metadata, the core stats (Energy, Stability, Potential) are state variables within the contract. `_getCalculatedAttributes` is a crucial helper function that calculates the *current* value by considering the time elapsed since the last state update and applying decay or growth rates. This makes the NFT's state *live* on-chain.
2.  **Time-Based Mechanics:** `lastUpdateTime` is stored. Energy decays linearly over time, while Potential grows. Bonding accelerates Potential growth. This creates a state where inaction (decay) and certain actions (growth, bonding) have tangible effects on the NFT's value and potential.
3.  **NFT Interaction (`entangleLeapers`, `disentangleLeapers`):** A specific mechanic where two Leapers owned by the *same* user can be linked. This isn't just cosmetic; it provides a quantifiable bonus (Stability) affecting the crucial Quantum Leap function. This is different from typical "breeding" or fusion, focusing on temporary cooperative buffs.
4.  **Probabilistic State Change (`requestQuantumLeap`, `fulfillRandomWords`):** The "Quantum Leap" is the ultimate goal. It's not guaranteed. It costs resources (Energy, ETH fee for VRF), requires specific states (not bonded, not already in Quantum State), and its outcome depends probabilistically on the Leaper's attributes (Stability, Potential) combined with Chainlink VRF randomness. This adds a layer of risk and excitement, transforming the NFT into a participant in an on-chain "game of chance" with permanent consequences.
5.  **Bonding (`bondLeaper`, `unbondLeaper`):** A simple staking-like mechanic where locking the NFT for a period provides a different benefit (faster potential growth) than active use (entanglement, leaping). This adds strategic choice for the owner.
6.  **State Updates (`_updateLeaperState`):** State changes (mint, recharge, entangle, bond, leap outcome) don't just modify the struct; they also update the `lastUpdateTime` and emit a `LeaperStateUpdated` event. This event makes tracking the history of the Leaper's evolution off-chain easier and ensures that time-based calculations are correctly anchored.
7.  **Configuration & Pausability:** Common but essential features allowing the owner to fine-tune game parameters and pause interactions in emergencies.
8.  **Royalty (ERC2981):** Standardized way for marketplaces to fetch royalty information.

This contract goes beyond basic NFT functions by embedding complex, interactive, and time-sensitive logic directly into the NFT's state management, creating entities that live and evolve on the blockchain in a way that feels distinct from most existing open-source examples.