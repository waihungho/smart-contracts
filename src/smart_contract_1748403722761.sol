Okay, let's design a smart contract that incorporates several advanced/creative concepts like dynamic token states, on-chain interaction leading to state changes, 'entanglement' between tokens, resource consumption for crafting/upgrading, and a form of 'decoherence' that locks states.

We'll call it the "QuantumForge". It will manage tokens called "Quanta" which represent complex, dynamic entities.

**Concept Outline:**

1.  **Dynamic Quanta:** ERC-721 tokens representing unique entities.
2.  **Superposition & Decoherence:** Quanta exist in a 'superposition' of potential states. Interactions can trigger 'decoherence', locking the Quanta into a single, permanent state.
3.  **Traits & State:** Each Quanta has numerical 'state' attributes and descriptive 'traits' derived from the state. Both can change while in superposition.
4.  **Resonance:** Interacting with a Quanta increases its 'Resonance Level', potentially influencing state changes and unlocking new interactions.
5.  **Entanglement:** Two Quanta can be 'entangled', linking their states or interactions in some way (e.g., inducing state shifts on one might affect the other).
6.  **The Forge (Crafting/Upgrading):** Users can consume 'Essence' (an ERC-20 token) to either:
    *   Forge new Quanta.
    *   Upgrade existing Quanta (modifying state/traits).
7.  **Forging Rules:** On-chain parameters govern the cost, probability, and outcome of forging, upgrading, and state shifts. These can potentially be updated by the contract owner or via a simple governance mechanism.
8.  **Residue Collection:** Interactions or failed state shifts might leave behind 'residue' (Essence or other tokens) that can be collected by the contract owner.

**Function Summary:**

1.  **ERC-721 Standard Functions (8):** Basic NFT functionality (transfer, ownership, approvals, URI).
2.  **Core Quanta Lifecycle (6):** Create, upgrade, lock state, induce change, link, unlink.
3.  **State & Data Retrieval (7):** Get current/potential states, traits, decoherence status, entanglement, resonance, rules.
4.  **Interaction & Utility (10):** Check forging costs/possibility, collect residue, manage parameters.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// --- Outline ---
// 1. Interfaces: Define external token interfaces (IERC20)
// 2. Errors: Custom error definitions
// 3. Events: Log significant actions (Mint, Upgrade, Decoherence, Entanglement, StateShift, ParameterUpdate)
// 4. Structs: Define data structures for Quanta state, traits, potential, forging rules, and entanglement info.
// 5. State Variables: Storage for tokens, counts, rules, external addresses, etc.
// 6. Modifiers: Access control modifier (onlyOwner is from Ownable)
// 7. Constructor: Initialize contract owner and dependencies.
// 8. ERC721 Standard Functions (Overridden/Used):
//    - transferFrom, safeTransferFrom, approve, setApprovalForAll, getApproved, isApprovedForAll, ownerOf, balanceOf, tokenURI
//    - _beforeTokenTransfer (to check entanglement)
// 9. Core Quanta Lifecycle Functions:
//    - forgeNewQuanta: Create a new Quanta token consuming Essence.
//    - upgradeQuanta: Upgrade an existing Quanta consuming Essence.
//    - decohereQuanta: Lock a Quanta's state permanently.
//    - induceStateShift: Attempt to change a Quanta's state while in superposition.
//    - entangleQuanta: Create a link between two Quanta.
//    - disentangleQuanta: Break the link between two Quanta.
// 10. State & Data Retrieval Functions (View/Pure):
//    - getQuantaState: Get the current numerical state values of a Quanta.
//    - getQuantaTraits: Get the descriptive traits derived from a Quanta's state.
//    - getQuantaPotential: Get potential future states if not decohered.
//    - isDecohered: Check if a Quanta's state is locked.
//    - isEntangled: Check if a Quanta is entangled.
//    - getActiveEntanglements: Get the token ID a Quanta is entangled with.
//    - getResonanceLevel: Get the resonance level of a Quanta.
//    - getForgingRules: Get the current parameters governing forging.
// 11. Interaction & Utility Functions:
//    - getForgingCost: Calculate Essence cost for forging.
//    - getUpgradeCost: Calculate Essence cost for upgrading.
//    - setForgingRules: Set parameters for forging (Owner only).
//    - setEssenceAddress: Set the address of the Essence token (Owner only).
//    - getEssenceAddress: Get the address of the Essence token.
//    - canForgeNew: Check if an address has enough Essence to forge.
//    - canUpgrade: Check if a token is eligible and user has enough Essence to upgrade.
//    - collectResidue: Withdraw collected Essence (Owner only).
//    - setTokenURIPrefix: Set the base URI for token metadata (Owner only).
//    - getTraitRules: Get rules for state-to-trait mapping.

// --- Function Summary ---

// ERC-721 Standard Functions:
// ownerOf(uint256 tokenId) external view returns (address owner): Returns the owner of the tokenId.
// balanceOf(address owner) external view returns (uint256 balance): Returns the number of tokens owned by an owner.
// approve(address to, uint256 tokenId) external: Gives permission to to to transfer tokenId.
// getApproved(uint256 tokenId) external view returns (address operator): Returns the account approved for tokenId.
// setApprovalForAll(address operator, bool approved) external: Enables or disables operator to manage all of msg.sender's tokens.
// isApprovedForAll(address owner, address operator) external view returns (bool): Checks if operator is approved for owner.
// transferFrom(address from, address to, uint256 tokenId) external: Transfers tokenId from from to to.
// safeTransferFrom(address from, address to, uint256 tokenId) external: Transfers tokenId from from to to, with safety checks.
// tokenURI(uint256 tokenId) external view returns (string memory): Returns the metadata URI for tokenId.

// Core Quanta Lifecycle Functions:
// forgeNewQuanta() public payable: Creates a new Quanta token for the caller. Requires Essence token payment.
// upgradeQuanta(uint256 tokenId) public payable: Attempts to upgrade the specified Quanta token. Requires ownership and Essence payment. Changes state/traits based on rules.
// decohereQuanta(uint256 tokenId) public: Locks the state of the specified Quanta token permanently. Requires ownership.
// induceStateShift(uint256 tokenId, uint256 shiftParameter) public: Attempts to shift the state of a Quanta token while in superposition. Requires ownership. Outcome depends on rules and shiftParameter.
// entangleQuanta(uint256 token1Id, uint256 token2Id) public: Creates a reciprocal entanglement link between two Quanta tokens. Requires ownership of both and they must not be entangled or decohered.
// disentangleQuanta(uint256 tokenId) public: Breaks the entanglement link of a Quanta token. Requires ownership.

// State & Data Retrieval Functions (View/Pure):
// getQuantaState(uint256 tokenId) public view returns (uint256[] memory): Returns the current numerical state values of a Quanta.
// getQuantaTraits(uint256 tokenId) public view returns (string memory): Returns a string representation of the descriptive traits of a Quanta.
// getQuantaPotential(uint256 tokenId) public view returns (uint256[][] memory): Returns potential future numerical states of a Quanta if not decohered.
// isDecohered(uint256 tokenId) public view returns (bool): Returns true if the Quanta's state is locked.
// isEntangled(uint256 tokenId) public view returns (bool): Returns true if the Quanta is entangled with another.
// getActiveEntanglements(uint256 tokenId) public view returns (uint256 entangledWithTokenId): Returns the token ID the Quanta is entangled with, or 0 if not entangled.
// getResonanceLevel(uint256 tokenId) public view returns (uint256): Returns the resonance level of the Quanta.
// getForgingRules() public view returns (ForgingRules memory): Returns the current parameters used by the forge.

// Interaction & Utility Functions:
// getForgingCost() public view returns (uint256): Returns the current Essence cost to forge a new Quanta.
// getUpgradeCost(uint256 tokenId) public view returns (uint256): Returns the current Essence cost to upgrade a specific Quanta. (Could be dynamic based on level/state).
// setForgingRules(ForgingRules memory newRules) public onlyOwner: Sets the parameters for forging and state changes.
// setEssenceAddress(address newEssenceAddress) public onlyOwner: Sets the address of the ERC20 Essence token.
// getEssenceAddress() public view returns (address): Returns the address of the Essence token.
// canForgeNew(address addr) public view returns (bool): Checks if the address has enough Essence allowance/balance.
// canUpgrade(uint256 tokenId, address addr) public view returns (bool): Checks if the token is eligible and address has enough Essence allowance/balance.
// collectResidue() public onlyOwner: Transfers any collected Essence residue to the contract owner.
// setTokenURIPrefix(string memory baseURI) public onlyOwner: Sets the base URI for metadata.
// getTraitRules() public view returns (string[] memory traitCategories, string[][] memory categoryRules): Returns the rules used to map state to traits.

contract QuantumForge is ERC721, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256; // Although SafeMath is often not needed in 0.8+ due to default overflow checks, useful for clarity in cost calculations.

    Counters.Counter private _tokenIdCounter;

    // --- Errors ---
    error NotEnoughEssenceAllowance();
    error NotEnoughEssenceBalance();
    error QuantaDoesNotExist();
    error NotQuantaOwner();
    error QuantaAlreadyDecohered();
    error QuantaAlreadyEntangled();
    error CannotEntangleSelf();
    error QuantaNotEntangled();
    error QuantaDecoheredCannotEntangle();
    error InvalidEntanglementPair(); // e.g., attempting to entangle decohered or non-existent
    error CannotUpgradeDecoheredQuanta();

    // --- Events ---
    event QuantaForged(uint256 indexed tokenId, address indexed owner, uint256 initialResonance);
    event QuantaUpgraded(uint256 indexed tokenId, uint256 newResonance);
    event QuantaDecohered(uint256 indexed tokenId);
    event QuantaStateShifted(uint256 indexed tokenId, uint256[] newState);
    event QuantaEntangled(uint256 indexed token1Id, uint256 indexed token2Id);
    event QuantaDisentangled(uint256 indexed token1Id, uint256 indexed token2Id);
    event ResidueCollected(address indexed owner, uint256 amount);
    event ForgingRulesUpdated(ForgingRules newRules);

    // --- Structs ---

    // Represents the numerical state of a Quanta (e.g., energy levels, material composition).
    struct QuantaState {
        uint256[] values; // Dynamic array for state values
    }

    // Represents potential future states (simplification: just one potential state for now)
    struct QuantaPotential {
        uint256[] potentialValues;
        uint256 probabilityBasis; // Basis for calculating probability of state shift
    }

    // Represents the descriptive traits derived from state (simplification: string representation)
    // More advanced: Map state values to enums or specific trait strings
    struct QuantaTraits {
        string description;
    }

    // Represents the entanglement link
    struct Entanglement {
        uint256 entangledWithTokenId; // 0 if not entangled
    }

    // Core Quanta data
    struct Quanta {
        bool exists;
        bool isDecohered;
        uint256 resonanceLevel;
        QuantaState state;
        QuantaPotential potential;
        // Note: Traits and Entanglement are stored in separate mappings for easier access/modification
    }

    // Rules governing the forging and state changes
    struct ForgingRules {
        uint256 baseForgingCost; // Cost in Essence for new Quanta
        uint256 baseUpgradeCost; // Base cost in Essence for upgrading
        uint256 upgradeCostMultiplier; // Multiplier for upgrade cost based on resonance/level
        uint256 stateShiftResonanceCost; // Resonance required/consumed for a state shift attempt
        uint256 stateShiftProbabilityBasis; // Max value for randomness check in state shift
        uint256 decoherenceEssenceCost; // Cost to decohere
        uint256 residueRate; // Percentage of cost that becomes residue (e.g., 100 = 1%)
        uint256 maxStateValue; // Max value for any state element
        uint256 minStateValue; // Min value for any state element
        uint256 initialResonance; // Starting resonance for new Quanta
    }

    // Rules for mapping state values to traits (Simplified: just example categories)
    struct TraitRules {
        string[] traitCategories; // e.g., ["Energy Signature", "Form Factor"]
        string[][] categoryRules; // e.g., [ ["Low", "Medium", "High"], ["Fluid", "Solid", "Gaseous"] ] - Mapping based on state value ranges
    }

    // --- State Variables ---

    address public essenceTokenAddress;
    IERC20 private essenceToken;

    mapping(uint256 => Quanta) private _quantaData; // Stores core Quanta data
    mapping(uint256 => QuantaTraits) private _quantaTraits; // Stores descriptive traits
    mapping(uint256 => Entanglement) private _quantaEntanglements; // Stores entanglement links

    ForgingRules public forgingRules;
    TraitRules private traitRules; // Rules for state -> trait mapping

    uint256 public collectedResidue; // Essence collected as residue

    string private _baseTokenURIPrefix;

    // --- Modifiers ---
    modifier onlyQuantaOwner(uint256 tokenId) {
        if (ownerOf(tokenId) != msg.sender) {
            revert NotQuantaOwner();
        }
        _;
    }

    modifier existingQuanta(uint256 tokenId) {
        if (!_quantaData[tokenId].exists) {
            revert QuantaDoesNotExist();
        }
        _;
    }

    // --- Constructor ---
    constructor(address initialEssenceToken, ForgingRules memory initialRules)
        ERC721("QuantumForgeQuanta", "QFQ")
        Ownable(msg.sender)
    {
        essenceTokenAddress = initialEssenceToken;
        essenceToken = IERC20(initialEssenceToken);
        forgingRules = initialRules;

        // Initialize example trait rules (simplified)
        traitRules.traitCategories = ["Energy Signature", "Form Factor", "Stability"];
        // Rules: 0-30: Low/Fluid/Unstable, 31-70: Medium/Solid/Stable, 71-100: High/Gaseous/Ancient (example mapping based on state value index/range)
        traitRules.categoryRules = new string[][](3);
        traitRules.categoryRules[0] = ["Faint", "Pulse", "Radiant"]; // Energy Signature based on state value[0]
        traitRules.categoryRules[1] = ["Nebulous", "Crystalline", "Entropic"]; // Form Factor based on state value[1]
        traitRules.categoryRules[2] = ["Transient", "Enduring", "Cosmic"]; // Stability based on resonance level relative to max/decoherence potential
    }

    // --- ERC721 Standard Functions (Overridden/Used) ---
    // All standard ERC721 functions (ownerOf, balanceOf, approve, setApprovalForAll, isApprovedForAll, transferFrom, safeTransferFrom, getApproved)
    // are inherited and available. We only override _beforeTokenTransfer to add custom logic.

    function tokenURI(uint256 tokenId) public view override existingQuanta(tokenId) returns (string memory) {
        // This is a simplified metadata URI. In a real dapp, this would point to
        // a JSON file describing the Quanta's current state and traits.
        // The JSON file could be hosted off-chain (IPFS, Arweave) or generated dynamically
        // by an API backend that reads the on-chain state via RPC.
        // We include token ID and maybe decoherence status in the path for uniqueness.
        return string(abi.encodePacked(_baseTokenURIPrefix, Strings.toString(tokenId), "-", _quantaData[tokenId].isDecohered ? "decohered" : "superposed"));
    }

    // Override to prevent transferring entangled tokens
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
         // batchSize > 1 is for ERC1155, but overriding ERC721 allows checking
        require(batchSize == 1, "ERC721: batch size must be 1"); // Basic check for ERC721 context

        if (_quantaEntanglements[tokenId].entangledWithTokenId != 0) {
            revert QuantaAlreadyEntangled(); // Preventing transfer while entangled
        }

        // Call the parent ERC721 hook
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }


    // --- Core Quanta Lifecycle Functions ---

    /**
     * @notice Forges a new Quanta token, consuming Essence.
     * @dev Requires the caller to have approved this contract to spend the required Essence amount.
     * @dev Initial state, potential, and traits are generated based on forging rules.
     */
    function forgeNewQuanta() public {
        uint256 cost = forgingRules.baseForgingCost;
        require(essenceToken.allowance(msg.sender, address(this)) >= cost, NotEnoughEssenceAllowance());
        require(essenceToken.balanceOf(msg.sender) >= cost, NotEnoughEssenceBalance());

        // Transfer Essence cost
        bool success = essenceToken.transferFrom(msg.sender, address(this), cost);
        require(success, "Essence transfer failed");

        // Collect residue
        collectedResidue = collectedResidue.add(cost.mul(forgingRules.residueRate).div(10000)); // residueRate is x100, so divide by 10000 for percentage

        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        // Mint the ERC721 token
        _safeMint(msg.sender, newTokenId);

        // Initialize Quanta data
        Quanta storage newQuanta = _quantaData[newTokenId];
        newQuanta.exists = true;
        newQuanta.isDecohered = false;
        newQuanta.resonanceLevel = forgingRules.initialResonance; // Initial resonance

        // Generate initial state (example: 3 random-ish values between min/max)
        // Use block.timestamp and token ID for minimal pseudo-randomness
        newQuanta.state.values = new uint256[](3);
        newQuanta.state.values[0] = (block.timestamp + newTokenId) % (forgingRules.maxStateValue - forgingRules.minStateValue + 1) + forgingRules.minStateValue;
        newQuanta.state.values[1] = (block.difficulty + newTokenId) % (forgingRules.maxStateValue - forgingRules.minStateValue + 1) + forgingRules.minStateValue;
        newQuanta.state.values[2] = (block.number + newTokenId) % (forgingRules.maxStateValue - forgingRules.minStateValue + 1) + forgingRules.minStateValue;

        // Generate initial potential state (example: slightly shifted values)
        newQuanta.potential.potentialValues = new uint256[](3);
        newQuanta.potential.potentialValues[0] = (newQuanta.state.values[0] + 10) % (forgingRules.maxStateValue - forgingRules.minStateValue + 1) + forgingRules.minStateValue; // Example shift logic
        newQuanta.potential.potentialValues[1] = (newQuanta.state.values[1] > 10) ? newQuanta.state.values[1] - 10 : forgingRules.minStateValue; // Example shift logic
        newQuanta.potential.potentialValues[2] = newQuanta.state.values[2]; // Example: maybe some values are more stable

        newQuanta.potential.probabilityBasis = 1000; // Example basis for state shifts

        // Generate initial traits based on initial state
        _quantaTraits[newTokenId].description = _generateTraitsString(newQuanta.state.values, newQuanta.resonanceLevel);

        emit QuantaForged(newTokenId, msg.sender, newQuanta.initialResonance);
    }

    /**
     * @notice Attempts to upgrade an existing Quanta, consuming Essence.
     * @param tokenId The ID of the Quanta to upgrade.
     * @dev Requires ownership and Essence token payment.
     * @dev Modifies state, potential, and resonance based on rules.
     */
    function upgradeQuanta(uint256 tokenId) public payable existingQuanta(tokenId) onlyQuantaOwner(tokenId) {
        if (_quantaData[tokenId].isDecohered) {
            revert CannotUpgradeDecoheredQuanta();
        }

        uint256 cost = getUpgradeCost(tokenId); // Dynamic cost calculation
        require(essenceToken.allowance(msg.sender, address(this)) >= cost, NotEnoughEssenceAllowance());
        require(essenceToken.balanceOf(msg.sender) >= cost, NotEnoughEssenceBalance());

        bool success = essenceToken.transferFrom(msg.sender, address(this), cost);
        require(success, "Essence transfer failed");

         // Collect residue
        collectedResidue = collectedResidue.add(cost.mul(forgingRules.residueRate).div(10000));

        Quanta storage quanta = _quantaData[tokenId];

        // Apply upgrade logic (example: slightly increase state values, boost resonance)
        for (uint i = 0; i < quanta.state.values.length; i++) {
            quanta.state.values[i] = quanta.state.values[i].add(5); // Example fixed increase
            if (quanta.state.values[i] > forgingRules.maxStateValue) {
                 quanta.state.values[i] = forgingRules.maxStateValue; // Cap
            }
        }
        quanta.resonanceLevel = quanta.resonanceLevel.add(10); // Boost resonance

        // Regenerate potential based on new state (example)
         quanta.potential.potentialValues = new uint256[](quanta.state.values.length);
        for (uint i = 0; i < quanta.state.values.length; i++) {
            quanta.potential.potentialValues[i] = (quanta.state.values[i] + ((tokenId % 7) + 1) * 2) % (forgingRules.maxStateValue - forgingRules.minStateValue + 1) + forgingRules.minStateValue; // More complex example shift
        }


        // Update traits
        _quantaTraits[tokenId].description = _generateTraitsString(quanta.state.values, quanta.resonanceLevel);


        emit QuantaUpgraded(tokenId, quanta.resonanceLevel);
    }

    /**
     * @notice Locks the state of a Quanta permanently, ending superposition.
     * @param tokenId The ID of the Quanta to decohere.
     * @dev Requires ownership and the decoherence cost (if any) to be paid.
     * @dev Clears potential states.
     */
    function decohereQuanta(uint256 tokenId) public existingQuanta(tokenId) onlyQuantaOwner(tokenId) {
        if (_quantaData[tokenId].isDecohered) {
            revert QuantaAlreadyDecohered();
        }

        uint256 cost = forgingRules.decoherenceEssenceCost;
        if (cost > 0) {
             require(essenceToken.allowance(msg.sender, address(this)) >= cost, NotEnoughEssenceAllowance());
             require(essenceToken.balanceOf(msg.sender) >= cost, NotEnoughEssenceBalance());
             bool success = essenceToken.transferFrom(msg.sender, address(this), cost);
             require(success, "Essence transfer failed");
             collectedResidue = collectedResidue.add(cost.mul(forgingRules.residueRate).div(10000));
        }

        Quanta storage quanta = _quantaData[tokenId];
        quanta.isDecohered = true;
        // Clear potential states as they are no longer relevant
        delete quanta.potential;

        emit QuantaDecohered(tokenId);
    }

     /**
     * @notice Attempts to induce a state shift on a Quanta while it's in superposition.
     * @param tokenId The ID of the Quanta.
     * @param shiftParameter An input parameter that can influence the shift outcome (example: user input bias).
     * @dev Requires ownership and Quanta must not be decohered.
     * @dev Outcome depends on rules, current state, resonance, and shiftParameter. May consume resonance or add residue.
     */
    function induceStateShift(uint256 tokenId, uint256 shiftParameter) public existingQuanta(tokenId) onlyQuantaOwner(tokenId) {
        if (_quantaData[tokenId].isDecohered) {
            revert QuantaAlreadyDecohered();
        }

        Quanta storage quanta = _quantaData[tokenId];

        // Cost in resonance
        if (quanta.resonanceLevel < forgingRules.stateShiftResonanceCost) {
             // Instead of reverting, maybe just fail silently or add more residue?
             // Let's make it add residue and fail state change for demonstration
             collectedResidue = collectedResidue.add(forgingRules.stateShiftResonanceCost.mul(100).div(10000)); // 100 resonance ~ 1 unit of Essence? Example conversion
             quanta.resonanceLevel = quanta.resonanceLevel.add(1); // Minor resonance gain on failed attempt
             emit QuantaStateShifted(tokenId, quanta.state.values); // State didn't change
             return; // State shift fails
        }
        quanta.resonanceLevel = quanta.resonanceLevel.sub(forgingRules.stateShiftResonanceCost); // Consume resonance

        // Use a combination of block data, token ID, resonance, and shiftParameter for pseudo-randomness
        uint256 randomFactor = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, block.number, tokenId, msg.sender, shiftParameter, quanta.resonanceLevel))) % forgingRules.stateShiftProbabilityBasis;

        // Simplified State Shift Logic:
        // If randomFactor is below a threshold influenced by resonance and parameter, shift to potential state.
        uint256 successThreshold = (quanta.resonanceLevel / 10).add(shiftParameter / 100); // Example: Higher resonance/parameter increases chance
        if (randomFactor < successThreshold && quanta.potential.potentialValues.length > 0) {
            // Shift successful: Apply potential state
            quanta.state.values = quanta.potential.potentialValues;

            // Generate *new* potential state based on the *new* current state
             quanta.potential.potentialValues = new uint256[](quanta.state.values.length);
             for (uint i = 0; i < quanta.state.values.length; i++) {
                quanta.potential.potentialValues[i] = (quanta.state.values[i] + ((tokenId % 5) + 1) * 3) % (forgingRules.maxStateValue - forgingRules.minStateValue + 1) + forgingRules.minStateValue;
            }

            // Update traits
            _quantaTraits[tokenId].description = _generateTraitsString(quanta.state.values, quanta.resonanceLevel);

            emit QuantaStateShifted(tokenId, quanta.state.values);

        } else {
            // State shift failed: Add some residue and perhaps minor resonance gain
            collectedResidue = collectedResidue.add(forgingRules.stateShiftResonanceCost.mul(200).div(10000)); // More residue on failure
            quanta.resonanceLevel = quanta.resonanceLevel.add(5); // Minor resonance gain
             emit QuantaStateShifted(tokenId, quanta.state.values); // State did not change
        }

         // Resonance always increases a little from interaction
         quanta.resonanceLevel = quanta.resonanceLevel.add(1);
    }

    /**
     * @notice Creates a reciprocal entanglement link between two Quanta tokens.
     * @param token1Id The ID of the first Quanta.
     * @param token2Id The ID of the second Quanta.
     * @dev Requires ownership of both tokens. Neither token can be entangled or decohered. Cannot entangle a token with itself.
     */
    function entangleQuanta(uint256 token1Id, uint256 token2Id) public existingQuanta(token1Id) existingQuanta(token2Id) {
        if (token1Id == token2Id) revert CannotEntangleSelf();
        if (ownerOf(token1Id) != msg.sender || ownerOf(token2Id) != msg.sender) revert NotQuantaOwner(); // Must own both

        if (_quantaEntanglements[token1Id].entangledWithTokenId != 0 || _quantaEntanglements[token2Id].entangledWithTokenId != 0) {
             revert QuantaAlreadyEntangled();
        }
         if (_quantaData[token1Id].isDecohered || _quantaData[token2Id].isDecohered) {
             revert QuantaDecoheredCannotEntangle();
         }


        _quantaEntanglements[token1Id].entangledWithTokenId = token2Id;
        _quantaEntanglements[token2Id].entangledWithTokenId = token1Id;

        // Example: Entangling boosts resonance
        _quantaData[token1Id].resonanceLevel = _quantaData[token1Id].resonanceLevel.add(50);
        _quantaData[token2Id].resonanceLevel = _quantaData[token2Id].resonanceLevel.add(50);


        emit QuantaEntangled(token1Id, token2Id);
    }

     /**
     * @notice Breaks the entanglement link for a Quanta token.
     * @param tokenId The ID of the Quanta.
     * @dev Requires ownership and the Quanta must be entangled.
     */
    function disentangleQuanta(uint256 tokenId) public existingQuanta(tokenId) onlyQuantaOwner(tokenId) {
        uint256 entangledWithId = _quantaEntanglements[tokenId].entangledWithTokenId;
        if (entangledWithId == 0) revert QuantaNotEntangled();

        // Clear both sides of the entanglement
        delete _quantaEntanglements[tokenId];
        delete _quantaEntanglements[entangledWithId];

        // Example: Disentangling reduces resonance (cost)
         _quantaData[tokenId].resonanceLevel = (_quantaData[tokenId].resonanceLevel > 20) ? _quantaData[tokenId].resonanceLevel.sub(20) : 0;
        if (_quantaData[entangledWithId].exists) { // Check if the other token still exists
             _quantaData[entangledWithId].resonanceLevel = (_quantaData[entangledWithId].resonanceLevel > 20) ? _quantaData[entangledWithId].resonanceLevel.sub(20) : 0;
        }


        emit QuantaDisentangled(tokenId, entangledWithId);
    }


    // --- State & Data Retrieval Functions (View/Pure) ---

    /**
     * @notice Gets the current numerical state values of a Quanta.
     * @param tokenId The ID of the Quanta.
     * @return values The array of state values.
     */
    function getQuantaState(uint256 tokenId) public view existingQuanta(tokenId) returns (uint256[] memory) {
        return _quantaData[tokenId].state.values;
    }

    /**
     * @notice Gets the descriptive traits of a Quanta.
     * @param tokenId The ID of the Quanta.
     * @return description The string representation of traits.
     */
    function getQuantaTraits(uint256 tokenId) public view existingQuanta(tokenId) returns (string memory) {
        return _quantaTraits[tokenId].description;
    }

    /**
     * @notice Gets the potential future numerical states of a Quanta if not decohered.
     * @param tokenId The ID of the Quanta.
     * @return potentialValues The array of potential state values, or empty if decohered.
     */
    function getQuantaPotential(uint256 tokenId) public view existingQuanta(tokenId) returns (uint256[][] memory) {
        if (_quantaData[tokenId].isDecohered) {
            return new uint256[][](0); // Return empty array if decohered
        }
        // Simplified: We only store ONE potential state currently.
        // A more complex implementation could store multiple potential states.
        uint256[][] memory potentialStates = new uint256[][](1);
        potentialStates[0] = _quantaData[tokenId].potential.potentialValues;
        return potentialStates;
    }

    /**
     * @notice Checks if a Quanta's state is locked (decohered).
     * @param tokenId The ID of the Quanta.
     * @return isLocked True if decohered, false otherwise.
     */
    function isDecohered(uint256 tokenId) public view existingQuanta(tokenId) returns (bool) {
        return _quantaData[tokenId].isDecohered;
    }

     /**
     * @notice Checks if a Quanta is entangled with another.
     * @param tokenId The ID of the Quanta.
     * @return entangled True if entangled, false otherwise.
     */
    function isEntangled(uint256 tokenId) public view existingQuanta(tokenId) returns (bool) {
        return _quantaEntanglements[tokenId].entangledWithTokenId != 0;
    }

     /**
     * @notice Gets the token ID a Quanta is entangled with.
     * @param tokenId The ID of the Quanta.
     * @return entangledWithTokenId The ID of the entangled token, or 0 if not entangled.
     */
    function getActiveEntanglements(uint256 tokenId) public view existingQuanta(tokenId) returns (uint256 entangledWithTokenId) {
         return _quantaEntanglements[tokenId].entangledWithTokenId;
    }

     /**
     * @notice Gets the resonance level of a Quanta.
     * @param tokenId The ID of the Quanta.
     * @return resonanceLevel The current resonance level.
     */
    function getResonanceLevel(uint256 tokenId) public view existingQuanta(tokenId) returns (uint256) {
         return _quantaData[tokenId].resonanceLevel;
    }

    /**
     * @notice Gets the current parameters used by the forge for costs and state changes.
     * @return rules The current ForgingRules struct.
     */
    function getForgingRules() public view returns (ForgingRules memory) {
        return forgingRules;
    }

    // --- Interaction & Utility Functions ---

    /**
     * @notice Gets the current Essence cost to forge a new Quanta.
     * @return cost The cost in Essence.
     */
    function getForgingCost() public view returns (uint256) {
        return forgingRules.baseForgingCost;
    }

    /**
     * @notice Gets the current Essence cost to upgrade a specific Quanta.
     * @param tokenId The ID of the Quanta.
     * @return cost The cost in Essence.
     * @dev Cost might be dynamic based on the Quanta's resonance or other factors.
     */
    function getUpgradeCost(uint256 tokenId) public view existingQuanta(tokenId) returns (uint256) {
        // Example dynamic cost: Base cost + multiplier based on resonance
        uint256 currentResonance = _quantaData[tokenId].resonanceLevel;
        return forgingRules.baseUpgradeCost.add(currentResonance.mul(forgingRules.upgradeCostMultiplier).div(100)); // multiplier is x100
    }

    /**
     * @notice Sets the parameters for forging and state changes.
     * @param newRules The new ForgingRules struct.
     * @dev Only callable by the contract owner.
     */
    function setForgingRules(ForgingRules memory newRules) public onlyOwner {
        forgingRules = newRules;
        emit ForgingRulesUpdated(newRules);
    }

     /**
     * @notice Sets the address of the ERC20 Essence token.
     * @param newEssenceAddress The address of the Essence contract.
     * @dev Only callable by the contract owner.
     */
    function setEssenceAddress(address newEssenceAddress) public onlyOwner {
        essenceTokenAddress = newEssenceAddress;
        essenceToken = IERC20(newEssenceAddress);
    }

    /**
     * @notice Gets the address of the ERC20 Essence token used by the forge.
     * @return essenceAddr The address of the Essence contract.
     */
    function getEssenceAddress() public view returns (address essenceAddr) {
        return essenceTokenAddress;
    }

    /**
     * @notice Checks if an address has enough Essence allowance and balance to forge a new Quanta.
     * @param addr The address to check.
     * @return canForge True if the address can afford to forge, false otherwise.
     */
    function canForgeNew(address addr) public view returns (bool) {
        uint256 cost = getForgingCost();
        return essenceToken.allowance(addr, address(this)) >= cost && essenceToken.balanceOf(addr) >= cost;
    }

    /**
     * @notice Checks if a token is eligible for upgrade and if the user has enough Essence allowance/balance.
     * @param tokenId The ID of the Quanta.
     * @param addr The address of the potential upgrader (should be owner).
     * @return canUpgrade True if the token is eligible and the address can afford, false otherwise.
     */
    function canUpgrade(uint256 tokenId, address addr) public view existingQuanta(tokenId) returns (bool) {
         if (ownerOf(tokenId) != addr || _quantaData[tokenId].isDecohered) {
             return false; // Not owner or already decohered
         }
        uint256 cost = getUpgradeCost(tokenId);
        return essenceToken.allowance(addr, address(this)) >= cost && essenceToken.balanceOf(addr) >= cost;
    }

     /**
     * @notice Transfers the accumulated Essence residue to the contract owner.
     * @dev Only callable by the contract owner.
     */
    function collectResidue() public onlyOwner {
        uint256 amount = collectedResidue;
        if (amount == 0) return;

        collectedResidue = 0; // Reset residue before transfer to prevent reentrancy issues

        bool success = essenceToken.transfer(owner(), amount);
        require(success, "Residue transfer failed");

        emit ResidueCollected(owner(), amount);
    }

     /**
     * @notice Sets the base URI for token metadata.
     * @param baseURI The base URI string.
     * @dev Only callable by the contract owner. The final URI will be baseURI + tokenId + suffix.
     */
    function setTokenURIPrefix(string memory baseURI) public onlyOwner {
        _baseTokenURIPrefix = baseURI;
    }

    /**
     * @notice Gets the rules used to map Quanta state to descriptive traits.
     * @return traitCategories An array of trait category names.
     * @return categoryRules A 2D array mapping state ranges to trait names within each category.
     */
    function getTraitRules() public view returns (string[] memory traitCategories, string[][] memory categoryRules) {
        return (traitRules.traitCategories, traitRules.categoryRules);
    }


    // --- Internal Helper Functions ---

    /**
     * @dev Internal helper to generate a traits string based on state values and resonance.
     * @param stateValues The numerical state values.
     * @param resonance The resonance level.
     * @return A concatenated string representing the Quanta's traits.
     * @dev This is a simplified mapping. Real logic might be more complex.
     */
    function _generateTraitsString(uint256[] memory stateValues, uint256 resonance) internal view returns (string memory) {
         if (stateValues.length < 3) return "Minimal Quanta"; // Handle unexpected state size

        bytes memory traitsBytes = "";

        // Example mapping logic: map state value ranges to trait names
        // Category 1 (Energy Signature) based on stateValues[0]
        traitsBytes = abi.encodePacked(traitsBytes, traitRules.traitCategories[0], ": ");
        uint256 val0 = stateValues[0];
        if (val0 <= 30) traitsBytes = abi.encodePacked(traitsBytes, traitRules.categoryRules[0][0]);
        else if (val0 <= 70) traitsBytes = abi.encodePacked(traitsBytes, traitRules.categoryRules[0][1]);
        else traitsBytes = abi.encodePacked(traitsBytes, traitRules.categoryRules[0][2]);

        // Category 2 (Form Factor) based on stateValues[1]
        traitsBytes = abi.encodePacked(traitsBytes, ", ", traitRules.traitCategories[1], ": ");
        uint256 val1 = stateValues[1];
         if (val1 <= 30) traitsBytes = abi.encodePacked(traitsBytes, traitRules.categoryRules[1][0]);
        else if (val1 <= 70) traitsBytes = abi.encodePacked(traitsBytes, traitRules.categoryRules[1][1]);
        else traitsBytes = abi.encodePacked(traitsBytes, traitRules.categoryRules[1][2]);

        // Category 3 (Stability) based on resonance level (simplified)
        traitsBytes = abi.encodePacked(traitsBytes, ", ", traitRules.traitCategories[2], ": ");
         if (resonance <= 50) traitsBytes = abi.encodePacked(traitsBytes, traitRules.categoryRules[2][0]);
        else if (resonance <= 200) traitsBytes = abi.encodePacked(traitsBytes, traitRules.categoryRules[2][1]);
        else traitsBytes = abi.encodePacked(traitsBytes, traitRules.categoryRules[2][2]);


        return string(traitsBytes);
    }

     // Fallback/Receive functions - not strictly necessary for this contract's logic
     // unless you want to allow ETH payments (which isn't part of the current design,
     // which uses an external Essence token). Including them is common practice
     // but we will omit for simplicity as the design uses ERC20 transfers.
}
```