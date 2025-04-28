Okay, let's design a smart contract that represents a dynamic, interactable NFT system powered by a fungible token. We'll call it "AuraBound Orbs". These Orbs are NFTs that have attributes which change based on the amount of a linked "Essence" token deposited into them, time, and interactions with other Orbs. It blends concepts from dynamic NFTs, token utility, crafting/synthesis, and basic state-based mechanics.

It will use standard ERC721 for the Orbs and interact with an external ERC20 contract for the Essence token. It won't duplicate standard OpenZeppelin ERC20/721 implementations entirely, but will inherit from them for correctness and gas efficiency where appropriate (like `ERC721`, `Ownable`, `Pausable`), focusing the custom logic on the unique Orb mechanics.

Here's the contract design:

**Contract Name:** `AuraBoundOrbs`

**Outline:**

1.  **Pragma & Imports:** Specify Solidity version and import necessary OpenZeppelin contracts.
2.  **Errors:** Define custom errors for better revert reasons.
3.  **Events:** Define events for key actions (Mint, Burn, EssenceDeposit, StateChange, Synthesis, etc.).
4.  **Structs:** Define the structure for `OrbAttributes`.
5.  **State Variables:**
    *   ERC721 standard state (`_tokens`, `_owners`, `_balances`, `_tokenApprovals`, `_operatorApprovals`).
    *   Custom Orb state (`_orbAttributes`, `_tokenIdCounter`).
    *   Linked token address (`_essenceTokenAddress`).
    *   Configuration parameters (`_tierThresholds`, `_baseTokenURI`, `_synthesisCostEssence`).
    *   Access control (`_owner`, `_paused`).
6.  **Modifiers:** `onlyOwner`, `whenNotPaused`, `whenPaused`.
7.  **Constructor:** Initialize contract owner, Essence token address, initial thresholds, and base URI.
8.  **ERC721 Standard Functions:** Implement or override standard ERC721 functions (`balanceOf`, `ownerOf`, `transferFrom`, `safeTransferFrom`, `approve`, `setApprovalForAll`, `getApproved`, `isApprovedForAll`, `tokenURI`, `supportsInterface`).
9.  **Core Orb Management:**
    *   `mintOrb`: Create a new Orb NFT.
    *   `burnOrb`: Destroy an Orb NFT.
    *   `getOrbAttributes`: Retrieve the full attributes of an Orb.
10. **Essence Interaction & Dynamic State:**
    *   `depositEssence`: Add Essence to an Orb, increasing its `essenceLevel` and potentially its `powerTier`.
    *   `withdrawEssence`: Remove Essence from an Orb (may decrease tier).
    *   `infuseAffinity`: Add Essence to a different metric, `affinityScore`, which is persistent.
    *   `calibrateOrb`: Re-evaluate dynamic traits based on current state and time.
11. **Orb Rituals & Interaction:**
    *   `resonateOrbs`: Interact two Orbs, potentially yielding temporary buffs or state changes. (Requires caller owns both).
    *   `synthesizeOrb`: Consume two Orbs and Essence to create a new Orb with derived attributes. (Requires caller owns both parents).
    *   `bindOrbToAddress`: Make an Orb non-transferable (bound).
    *   `unbindOrbFromAddress`: Make a bound Orb transferable again (requires cost).
12. **Query Functions:**
    *   `getOrbEssenceLevel`: Get only the essence level.
    *   `getOrbPowerTier`: Get only the power tier.
    *   `getOrbDynamicTraits`: Get only the dynamic traits.
    *   `getOrbAffinityScore`: Get only the affinity score.
    *   `isOrbBound`: Check if an Orb is bound.
    *   `getTimeSinceLastCharged`: Check time since last essence deposit/calibration.
    *   `getTierThresholds`: Get the current tier thresholds.
    *   `getSynthesisCostEssence`: Get the cost to synthesize.
    *   `getEssenceTokenAddress`: Get the address of the linked Essence token.
13. **Admin Functions:**
    *   `setBaseURI`: Update the metadata base URI.
    *   `setEssenceTokenAddress`: Update the linked Essence token address (careful!).
    *   `updateTierThresholds`: Update the thresholds for power tiers.
    *   `setSynthesisCostEssence`: Update the cost for synthesis.
    *   `pauseContract`: Pause transfers and key interactions.
    *   `unpauseContract`: Unpause the contract.
    *   `transferOwnership`: Transfer contract ownership.
    *   `renounceOwnership`: Renounce contract ownership.
14. **Internal/Helper Functions:**
    *   `_updateOrbAttributes`: Internal logic to recalculate tier and dynamic traits.
    *   `_calculatePowerTier`: Determine tier based on essence level.
    *   `_calculateDynamicTraits`: Determine dynamic traits based on various factors.
    *   `_beforeTokenTransfer`: ERC721 hook for binding logic.

**Function Summary (>= 20 functions):**

*   `constructor(address essenceAddress_, string memory baseURI_, uint256[] calldata initialTierThresholds)`: Initializes the contract, sets the Essence token, base URI, and tier thresholds.
*   `mintOrb()`: (external) Mints a new Orb NFT to the caller. Assigns initial attributes. Emits `Transfer` and `OrbMinted` events.
*   `burnOrb(uint256 orbId)`: (external) Burns an Orb NFT owned by the caller. Clears attributes. Emits `Transfer` and `OrbBurned` events.
*   `depositEssence(uint256 orbId, uint256 amount)`: (external) Allows owner of `orbId` to deposit `amount` of Essence token. Transfers tokens from caller to contract. Increases `essenceLevel`, potentially updates `powerTier` and `dynamicTraits`. Emits `EssenceDeposited` and `OrbStateChanged` events.
*   `withdrawEssence(uint256 orbId, uint256 amount)`: (external) Allows owner of `orbId` to withdraw `amount` of Essence token *if* available in the Orb. Decreases `essenceLevel`, potentially updates `powerTier` and `dynamicTraits`. Transfers tokens from contract to caller. Emits `EssenceWithdrawn` and `OrbStateChanged` events.
*   `infuseAffinity(uint256 orbId, uint256 amount)`: (external) Allows owner of `orbId` to deposit `amount` of Essence token specifically for `affinityScore`. Transfers tokens from caller to contract. Increases `affinityScore` *without* affecting `essenceLevel` or `powerTier`. Emits `AffinityInfused` event.
*   `calibrateOrb(uint256 orbId)`: (external) Allows owner of `orbId` to trigger a recalculation of `dynamicTraits` and update `lastChargedTime`. Useful for time-decaying mechanics or trait refreshing. Emits `OrbCalibrated` event.
*   `resonateOrbs(uint256 orbId1, uint256 orbId2)`: (external) Allows an owner to interact with two of their Orbs. Implements custom logic (e.g., temporary attribute boost, state merge, requires Essence cost). Updates relevant Orb attributes. Emits `OrbsResonated` event.
*   `synthesizeOrb(uint256 orbId1, uint256 orbId2)`: (external) Allows an owner to synthesize two Orbs they own. Requires a specific Essence token cost. Burns `orbId1` and `orbId2`. Mints a new Orb with derived attributes based on parents. Emits `OrbsSynthesized`, `Transfer` (for the new Orb), and `Transfer` (for the burned Orbs) events.
*   `bindOrbToAddress(uint256 orbId)`: (external) Makes the specified `orbId` non-transferable. Can only be called by the owner. Sets the `bound` flag. Emits `OrbBound` event.
*   `unbindOrbFromAddress(uint256 orbId)`: (external) Makes a bound `orbId` transferable again. Requires the owner to pay a specific Essence token cost. Transfers tokens from caller to contract. Clears the `bound` flag. Emits `OrbUnbound` event.
*   `getOrbAttributes(uint256 orbId)`: (public view) Returns the full `OrbAttributes` struct for a given Orb ID.
*   `getOrbEssenceLevel(uint256 orbId)`: (public view) Returns the `essenceLevel` of an Orb.
*   `getOrbPowerTier(uint256 orbId)`: (public view) Returns the `powerTier` of an Orb.
*   `getOrbDynamicTraits(uint256 orbId)`: (public view) Returns the `dynamicTrait1` and `dynamicTrait2` of an Orb.
*   `getOrbAffinityScore(uint256 orbId)`: (public view) Returns the `affinityScore` of an Orb.
*   `isOrbBound(uint256 orbId)`: (public view) Returns `true` if the Orb is bound, `false` otherwise.
*   `getTimeSinceLastCharged(uint256 orbId)`: (public view) Returns the time elapsed in seconds since the Orb was last charged or calibrated.
*   `getTierThresholds()`: (public view) Returns the array of Essence thresholds defining the power tiers.
*   `getSynthesisCostEssence()`: (public view) Returns the amount of Essence required for synthesis.
*   `getEssenceTokenAddress()`: (public view) Returns the address of the linked Essence token contract.
*   `setBaseURI(string memory baseURI_)`: (external onlyOwner) Sets the base URI for token metadata.
*   `setEssenceTokenAddress(address essenceAddress_)`: (external onlyOwner) Sets the address of the Essence token contract. Allows updating if the token contract changes (use with extreme caution!).
*   `updateTierThresholds(uint256[] calldata newThresholds)`: (external onlyOwner) Updates the Essence thresholds for power tiers.
*   `setSynthesisCostEssence(uint256 cost)`: (external onlyOwner) Sets the Essence cost for the `synthesizeOrb` function.
*   `pauseContract()`: (external onlyOwner whenNotPaused) Pauses key contract functionality.
*   `unpauseContract()`: (external onlyOwner whenPaused) Unpauses the contract.
*   `transferOwnership(address newOwner)`: (external onlyOwner) Transfers ownership of the contract. (Inherited from Ownable)
*   `renounceOwnership()`: (external onlyOwner) Renounces ownership of the contract. (Inherited from Ownable)
*   `tokenURI(uint256 tokenId)`: (public view override) Returns the URI for token metadata, incorporating the base URI.
*   `supportsInterface(bytes4 interfaceId)`: (public view override) ERC165 interface detection. (Inherited/Overridden for ERC721)

This provides 31 public/external functions, well exceeding the minimum of 20, covering core ERC721, custom dynamic state, resource interaction, complex rituals (synthesis, resonance), bonding, querying, and administration.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

// Outline:
// 1. Pragma & Imports
// 2. Errors
// 3. Events
// 4. Structs (OrbAttributes)
// 5. State Variables
// 6. Modifiers (inherited)
// 7. Constructor
// 8. ERC721 Standard Functions (overrides/implementations)
// 9. Core Orb Management (mint, burn, get)
// 10. Essence Interaction & Dynamic State (deposit, withdraw, infuse, calibrate)
// 11. Orb Rituals & Interaction (resonate, synthesize, bind, unbind)
// 12. Query Functions (specific getters)
// 13. Admin Functions (set configs, pause, ownership)
// 14. Internal/Helper Functions (_updateAttributes, calculations, _beforeTokenTransfer)

// Function Summary:
// - constructor: Initializes contract with Essence token, base URI, tier thresholds.
// - mintOrb: Mints a new Orb NFT to the caller.
// - burnOrb: Burns an Orb NFT owned by the caller.
// - depositEssence: Adds Essence to an Orb, affects essenceLevel and powerTier.
// - withdrawEssence: Removes Essence from an Orb, affects essenceLevel and powerTier.
// - infuseAffinity: Adds Essence to a persistent affinityScore.
// - calibrateOrb: Re-evaluates dynamic traits based on current state and time.
// - resonateOrbs: Interacts two owner's Orbs (custom logic).
// - synthesizeOrb: Burns two owner's Orbs and Essence to mint a new one with derived attributes.
// - bindOrbToAddress: Makes an Orb non-transferable.
// - unbindOrbFromAddress: Makes a bound Orb transferable (requires Essence cost).
// - getOrbAttributes: Returns all attributes of an Orb.
// - getOrbEssenceLevel: Returns an Orb's essenceLevel.
// - getOrbPowerTier: Returns an Orb's powerTier.
// - getOrbDynamicTraits: Returns an Orb's dynamic traits.
// - getOrbAffinityScore: Returns an Orb's affinityScore.
// - isOrbBound: Checks if an Orb is bound.
// - getTimeSinceLastCharged: Time elapsed since last charge/calibration.
// - getTierThresholds: Returns the power tier thresholds.
// - getSynthesisCostEssence: Returns the Essence cost for synthesis.
// - getEssenceTokenAddress: Returns the Essence token contract address.
// - setBaseURI: Sets the base URI for metadata (Admin).
// - setEssenceTokenAddress: Sets the Essence token address (Admin, careful).
// - updateTierThresholds: Updates power tier thresholds (Admin).
// - setSynthesisCostEssence: Sets the synthesis cost (Admin).
// - pauseContract: Pauses contract functions (Admin).
// - unpauseContract: Unpauses contract functions (Admin).
// - transferOwnership: Transfers ownership (Admin).
// - renounceOwnership: Renounces ownership (Admin).
// - tokenURI: Returns the dynamic token URI.
// - supportsInterface: ERC165 interface check.
// - balanceOf: ERC721 standard.
// - ownerOf: ERC721 standard.
// - transferFrom: ERC721 standard (modified for binding).
// - safeTransferFrom: ERC721 standard (modified for binding).
// - approve: ERC721 standard.
// - setApprovalForAll: ERC721 standard.
// - getApproved: ERC721 standard.
// - isApprovedForAll: ERC721 standard.

contract AuraBoundOrbs is ERC721, Ownable, Pausable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // Custom Errors
    error InvalidOrbId(uint256 orbId);
    error Unauthorized(address caller);
    error NotOrbOwner(uint256 orbId, address caller);
    error OrbAlreadyBound(uint256 orbId);
    error OrbNotBound(uint256 orbId);
    error InsufficientEssenceInOrb(uint256 orbId, uint256 requestedAmount, uint256 currentAmount);
    error InsufficientEssenceForCost(address caller, uint256 requiredAmount, uint256 currentAmount);
    error InvalidTierThresholds(string reason);
    error SynthesisRequiresDifferentOrbs();
    error SynthesisRequiresNonBoundOrbs(uint256 orbId);
    error SynthesisEssenceTransferFailed(address token, uint256 amount);

    // Struct for Orb Attributes
    struct OrbAttributes {
        uint256 essenceLevel;      // Amount of Essence token currently deposited
        uint8 powerTier;           // Tier derived from essenceLevel
        uint64 creationTime;      // Timestamp of Orb creation
        uint64 lastChargedTime;   // Timestamp of last deposit/calibration
        uint256 affinityScore;     // Separate score from Infusion, persistent
        bool bound;                // If true, cannot be transferred
        uint8 dynamicTrait1;       // Example dynamic trait (e.g., 0-255)
        uint8 dynamicTrait2;       // Another example dynamic trait
        // Add more attributes as needed
    }

    // State Variables
    mapping(uint256 => OrbAttributes) private _orbAttributes;
    address private _essenceTokenAddress;
    uint256[] private _tierThresholds; // Essence levels required for each tier (0-indexed)
    string private _baseTokenURI;
    uint256 private _synthesisCostEssence;

    // Events
    event OrbMinted(uint256 indexed tokenId, address indexed owner);
    event OrbBurned(uint256 indexed tokenId, address indexed owner);
    event EssenceDeposited(uint256 indexed tokenId, address indexed depositor, uint256 amount, uint256 newEssenceLevel);
    event EssenceWithdrawn(uint256 indexed tokenId, address indexed withdrawer, uint256 amount, uint256 newEssenceLevel);
    event AffinityInfused(uint256 indexed tokenId, address indexed infuser, uint256 amount, uint256 newAffinityScore);
    event OrbStateChanged(uint256 indexed tokenId, uint8 newPowerTier, uint8 newDynamicTrait1, uint8 newDynamicTrait2);
    event OrbCalibrated(uint256 indexed tokenId, uint64 calibrationTime);
    event OrbsResonated(uint256 indexed orbId1, uint256 indexed orbId2, address indexed caller);
    event OrbsSynthesized(uint256 indexed parentOrbId1, uint256 indexed parentOrbId2, uint256 indexed newOrbId, address indexed synthInitiator);
    event OrbBound(uint256 indexed orbId, address indexed owner);
    event OrbUnbound(uint256 indexed orbId, address indexed owner);
    event TierThresholdsUpdated(uint256[] newThresholds);
    event SynthesisCostUpdated(uint256 newCost);
    event EssenceTokenAddressUpdated(address oldAddress, address newAddress);

    constructor(address essenceAddress_, string memory baseURI_, uint256[] calldata initialTierThresholds)
        ERC721("AuraBoundOrb", "ABO")
        Ownable(msg.sender)
    {
        if (essenceAddress_ == address(0)) revert InvalidEssenceTokenAddress();
        if (initialTierThresholds.length == 0) revert InvalidTierThresholds("must not be empty");
        // Ensure thresholds are strictly increasing
        for (uint i = 0; i < initialTierThresholds.length; i++) {
            if (i > 0 && initialTierThresholds[i] <= initialTierThresholds[i-1]) {
                 revert InvalidTierThresholds("must be strictly increasing");
            }
        }

        _essenceTokenAddress = essenceAddress_;
        _baseTokenURI = baseURI_;
        _tierThresholds = initialTierThresholds; // e.g., [100, 500, 2000] for tiers 1, 2, 3+
        _synthesisCostEssence = 1000; // Default synthesis cost
    }

    // --- ERC721 Standard Overrides ---

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId); // Ensure token exists and is owned
        return string(abi.encodePacked(_baseTokenURI, Strings.toString(tokenId)));
        // Note: For truly dynamic metadata based on OrbAttributes,
        // the metadata server/API at baseURI must read the on-chain state
        // via calls like getOrbAttributes(tokenId).
    }

    // Override transfer functions to check for `bound` status
    function transferFrom(address from, address to, uint256 tokenId)
        public payable override whenNotPaused
    {
        if (_orbAttributes[tokenId].bound) revert OrbAlreadyBound(tokenId);
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId)
        public payable override whenNotPaused
    {
        if (_orbAttributes[tokenId].bound) revert OrbAlreadyBound(tokenId);
        super.safeTransferFrom(from, to, tokenId);
    }

     function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public payable override whenNotPaused
    {
        if (_orbAttributes[tokenId].bound) revert OrbAlreadyBound(tokenId);
        super.safeTransferFrom(from, to, tokenId, data);
    }

    // Implement ERC165 supportsInterface
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        // Add other interfaces if implementing them (e.g., ERC2981 for royalties)
        return interfaceId == type(IERC721).interfaceId ||
               interfaceId == type(IERC721Metadata).interfaceId ||
               interfaceId == type(IERC165).interfaceId; // Inherited from ERC721
    }


    // --- Core Orb Management ---

    function mintOrb() external whenNotPaused returns (uint256) {
        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();

        _safeMint(msg.sender, newItemId);

        // Initialize basic attributes - dynamic traits will be updated later
        _orbAttributes[newItemId] = OrbAttributes({
            essenceLevel: 0,
            powerTier: 0,
            creationTime: uint64(block.timestamp),
            lastChargedTime: uint64(block.timestamp),
            affinityScore: 0,
            bound: false,
            dynamicTrait1: 0, // Initial value, updated on calibration/deposit
            dynamicTrait2: 0  // Initial value
        });

        // Call internal update to calculate initial dynamic traits based on creation time etc.
        _updateOrbAttributes(newItemId);

        emit OrbMinted(newItemId, msg.sender);
        return newItemId;
    }

    function burnOrb(uint256 orbId) external whenNotPaused {
        address owner = ownerOf(orbId);
        if (owner != msg.sender) revert NotOrbOwner(orbId, msg.sender);
        if (_orbAttributes[orbId].bound) revert OrbAlreadyBound(orbId);

        // Transfer any remaining Essence back to owner? Or burn it? Let's burn it for simplicity.
        // If transferring back, need to transfer from *this* contract's balance of Essence.

        delete _orbAttributes[orbId]; // Clear attributes
        _burn(orbId); // Burn the token itself

        emit OrbBurned(orbId, msg.sender);
    }

    function getOrbAttributes(uint256 orbId) public view returns (OrbAttributes memory) {
         // Check if token exists (ERC721's _exists handles this)
        if (!_exists(orbId)) revert InvalidOrbId(orbId);
        return _orbAttributes[orbId];
    }


    // --- Essence Interaction & Dynamic State ---

    function depositEssence(uint256 orbId, uint256 amount) external whenNotPaused {
        address owner = ownerOf(orbId);
        if (owner != msg.sender) revert NotOrbOwner(orbId, msg.sender);
        if (amount == 0) return; // No-op

        // Transfer Essence from caller to this contract
        IERC20 essenceToken = IERC20(_essenceTokenAddress);
        // Assumes caller has already called approve on the Essence token contract
        bool success = essenceToken.transferFrom(msg.sender, address(this), amount);
        if (!success) revert EssenceTransferFailed(_essenceTokenAddress, amount);

        // Update Orb state
        _orbAttributes[orbId].essenceLevel += amount;
        _orbAttributes[orbId].lastChargedTime = uint64(block.timestamp);

        // Update power tier and dynamic traits based on new essence level
        _updateOrbAttributes(orbId);

        emit EssenceDeposited(orbId, msg.sender, amount, _orbAttributes[orbId].essenceLevel);
    }

    function withdrawEssence(uint256 orbId, uint256 amount) external whenNotPaused {
        address owner = ownerOf(orbId);
        if (owner != msg.sender) revert NotOrbOwner(orbId, msg.sender);
        if (amount == 0) return; // No-op
        if (_orbAttributes[orbId].essenceLevel < amount) {
            revert InsufficientEssenceInOrb(orbId, amount, _orbAttributes[orbId].essenceLevel);
        }

        // Update Orb state
        _orbAttributes[orbId].essenceLevel -= amount;
        // Optionally update lastChargedTime here or only on deposit/calibrate
        // Let's only update on deposit/calibrate to encourage 'freshness'

        // Update power tier and dynamic traits based on new essence level
        _updateOrbAttributes(orbId);

        // Transfer Essence from this contract back to caller
        IERC20 essenceToken = IERC20(_essenceTokenAddress);
        bool success = essenceToken.transfer(msg.sender, amount);
        if (!success) revert EssenceTransferFailed(_essenceTokenAddress, amount); // Should not fail if contract has balance

        emit EssenceWithdrawn(orbId, msg.sender, amount, _orbAttributes[orbId].essenceLevel);
    }

    function infuseAffinity(uint256 orbId, uint256 amount) external whenNotPaused {
        address owner = ownerOf(orbId);
        if (owner != msg.sender) revert NotOrbOwner(orbId, msg.sender);
        if (amount == 0) return;

        // Transfer Essence from caller to this contract
        IERC20 essenceToken = IERC20(_essenceTokenAddress);
        bool success = essenceToken.transferFrom(msg.sender, address(this), amount);
         if (!success) revert EssenceTransferFailed(_essenceTokenAddress, amount);

        // Update affinity score (does not affect essenceLevel or tier)
        _orbAttributes[orbId].affinityScore += amount;

        emit AffinityInfused(orbId, msg.sender, amount, _orbAttributes[orbId].affinityScore);
    }

     function calibrateOrb(uint256 orbId) external whenNotPaused {
        address owner = ownerOf(orbId);
        if (owner != msg.sender) revert NotOrbOwner(orbId, msg.sender);

        // Update power tier and dynamic traits based on current state
        _updateOrbAttributes(orbId);
        _orbAttributes[orbId].lastChargedTime = uint64(block.timestamp); // Mark as calibrated

        emit OrbCalibrated(orbId, uint64(block.timestamp));
    }


    // --- Orb Rituals & Interaction ---

    function resonateOrbs(uint256 orbId1, uint256 orbId2) external whenNotPaused {
        address owner1 = ownerOf(orbId1);
        address owner2 = ownerOf(orbId2);

        if (owner1 != msg.sender || owner2 != msg.sender) revert NotOrbOwner(orbId1, msg.sender); // Requires owning both
        if (orbId1 == orbId2) revert InvalidOrbId(orbId1); // Cannot resonate with self
        if (_orbAttributes[orbId1].bound || _orbAttributes[orbId2].bound) revert SynthesisRequiresNonBoundOrbs( _orbAttributes[orbId1].bound ? orbId1 : orbId2 );


        // --- Resonance Logic Placeholder ---
        // Example: Average affinity, add small temporary buff.
        // This could be complex: require Essence cost, temporary state change, etc.
        // For this example, let's average affinity and mildly boost dynamic traits based on total essence.

        uint256 totalEssence = _orbAttributes[orbId1].essenceLevel + _orbAttributes[orbId2].essenceLevel;
        uint256 avgAffinity = (_orbAttributes[orbId1].affinityScore + _orbAttributes[orbId2].affinityScore) / 2;

        // Simple boosting logic (example): boost traits by a small percentage of total essence / constant
        uint8 boostAmount1 = uint8(totalEssence / 1000); // Example scaling
        uint8 boostAmount2 = uint8(avgAffinity / 500);   // Example scaling

        // Apply boost (cap at max uint8)
        _orbAttributes[orbId1].dynamicTrait1 = uint8(min(255, _orbAttributes[orbId1].dynamicTrait1 + boostAmount1));
        _orbAttributes[orbId2].dynamicTrait1 = uint8(min(255, _orbAttributes[orbId2].dynamicTrait1 + boostAmount1));
        _orbAttributes[orbId1].dynamicTrait2 = uint8(min(255, _orbAttributes[orbId1].dynamicTrait2 + boostAmount2));
        _orbAttributes[orbId2].dynamicTrait2 = uint8(min(255, _orbAttributes[orbId2].dynamicTrait2 + boostAmount2));

        // Update last charged time or add a specific resonance time
        _orbAttributes[orbId1].lastChargedTime = uint64(block.timestamp);
        _orbAttributes[orbId2].lastChargedTime = uint64(block.timestamp);

        // Recalculate tiers/traits just in case the boost affects them (depending on _calculateDynamicTraits logic)
        _updateOrbAttributes(orbId1);
        _updateOrbAttributes(orbId2);
        // --- End Resonance Logic Placeholder ---


        emit OrbsResonated(orbId1, orbId2, msg.sender);
    }

    function synthesizeOrb(uint256 orbId1, uint256 orbId2) external whenNotPaused {
        address owner1 = ownerOf(orbId1);
        address owner2 = ownerOf(orbId2);

        if (owner1 != msg.sender || owner2 != msg.sender) revert NotOrbOwner(orbId1, msg.sender);
        if (orbId1 == orbId2) revert SynthesisRequiresDifferentOrbs();
         if (_orbAttributes[orbId1].bound) revert SynthesisRequiresNonBoundOrbs(orbId1);
        if (_orbAttributes[orbId2].bound) revert SynthesisRequiresNonBoundOrbs(orbId2);


        // Require Essence cost
        IERC20 essenceToken = IERC20(_essenceTokenAddress);
         if (essenceToken.balanceOf(msg.sender) < _synthesisCostEssence) {
             revert InsufficientEssenceForCost(msg.sender, _synthesisCostEssence, essenceToken.balanceOf(msg.sender));
         }

        // Transfer Essence cost from caller
        bool success = essenceToken.transferFrom(msg.sender, address(this), _synthesisCostEssence);
         if (!success) revert SynthesisEssenceTransferFailed(_essenceTokenAddress, _synthesisCostEssence);


        // --- Synthesis Logic Placeholder ---
        // Example: Combine attributes, potentially add randomness.
        // Read parent attributes
        OrbAttributes memory parent1 = _orbAttributes[orbId1];
        OrbAttributes memory parent2 = _orbAttributes[orbId2];

        // Burn parent Orbs (this also clears their state)
        _burn(orbId1);
        delete _orbAttributes[orbId1]; // Ensure state is cleared
        _burn(orbId2);
        delete _orbAttributes[orbId2]; // Ensure state is cleared

        // Mint new Orb
        _tokenIdCounter.increment();
        uint256 newOrbId = _tokenIdCounter.current();
        _safeMint(msg.sender, newOrbId);

        // Derive child attributes (example logic)
        // For simplicity, let's average some stats and sum others
        uint256 childEssenceLevel = (parent1.essenceLevel + parent2.essenceLevel) / 2;
        uint256 childAffinityScore = parent1.affinityScore + parent2.affinityScore; // Affinity sums up
        uint8 childDynamicTrait1 = uint8((uint256(parent1.dynamicTrait1) + uint256(parent2.dynamicTrait1)) / 2);
        uint8 childDynamicTrait2 = uint8((uint256(parent1.dynamicTrait2) + uint256(parent2.dynamicTrait2)) / 2);

        // Add some randomness? Requires a secure random source like Chainlink VRF.
        // For demonstration, we'll skip secure randomness. A simple block.timestamp based
        // "randomness" is NOT secure or unpredictable.

        _orbAttributes[newOrbId] = OrbAttributes({
            essenceLevel: childEssenceLevel,
            powerTier: 0, // Will be set by _updateOrbAttributes
            creationTime: uint64(block.timestamp),
            lastChargedTime: uint64(block.timestamp),
            affinityScore: childAffinityScore,
            bound: false,
            dynamicTrait1: childDynamicTrait1,
            dynamicTrait2: childDynamicTrait2
        });

        // Update power tier for the new Orb
        _updateOrbAttributes(newOrbId);

        // --- End Synthesis Logic Placeholder ---

        emit OrbsSynthesized(orbId1, orbId2, newOrbId, msg.sender);
    }

    function bindOrbToAddress(uint256 orbId) external whenNotPaused {
        address owner = ownerOf(orbId);
        if (owner != msg.sender) revert NotOrbOwner(orbId, msg.sender);
        if (_orbAttributes[orbId].bound) revert OrbAlreadyBound(orbId);

        _orbAttributes[orbId].bound = true;
        emit OrbBound(orbId, msg.sender);
    }

    function unbindOrbFromAddress(uint256 orbId) external whenNotPaused {
        address owner = ownerOf(orbId);
        if (owner != msg.sender) revert NotOrbOwner(orbId, msg.sender);
        if (!_orbAttributes[orbId].bound) revert OrbNotBound(orbId);

        // Require Essence cost for unbinding (example cost, can be configured)
        uint256 unbindCost = _synthesisCostEssence / 2; // Example: half the synthesis cost
         IERC20 essenceToken = IERC20(_essenceTokenAddress);
         if (essenceToken.balanceOf(msg.sender) < unbindCost) {
             revert InsufficientEssenceForCost(msg.sender, unbindCost, essenceToken.balanceOf(msg.sender));
         }

        // Transfer Essence cost from caller
        bool success = essenceToken.transferFrom(msg.sender, address(this), unbindCost);
        if (!success) revert EssenceTransferFailed(_essenceTokenAddress, unbindCost);


        _orbAttributes[orbId].bound = false;
        emit OrbUnbound(orbId, msg.sender);
    }


    // --- Query Functions ---

    function getOrbEssenceLevel(uint256 orbId) public view returns (uint256) {
        if (!_exists(orbId)) revert InvalidOrbId(orbId);
        return _orbAttributes[orbId].essenceLevel;
    }

    function getOrbPowerTier(uint256 orbId) public view returns (uint8) {
        if (!_exists(orbId)) revert InvalidOrbId(orbId);
        return _orbAttributes[orbId].powerTier;
    }

    function getOrbDynamicTraits(uint256 orbId) public view returns (uint8 trait1, uint8 trait2) {
        if (!_exists(orbId)) revert InvalidOrbId(orbId);
        return (_orbAttributes[orbId].dynamicTrait1, _orbAttributes[orbId].dynamicTrait2);
    }

    function getOrbAffinityScore(uint256 orbId) public view returns (uint256) {
         if (!_exists(orbId)) revert InvalidOrbId(orbId);
         return _orbAttributes[orbId].affinityScore;
     }

     function isOrbBound(uint256 orbId) public view returns (bool) {
          if (!_exists(orbId)) revert InvalidOrbId(orbId);
         return _orbAttributes[orbId].bound;
     }

     function getTimeSinceLastCharged(uint256 orbId) public view returns (uint256) {
         if (!_exists(orbId)) revert InvalidOrbId(orbId);
         return block.timestamp - _orbAttributes[orbId].lastChargedTime;
     }

     function getTierThresholds() public view returns (uint256[] memory) {
         return _tierThresholds;
     }

     function getSynthesisCostEssence() public view returns (uint256) {
         return _synthesisCostEssence;
     }

     function getEssenceTokenAddress() public view returns (address) {
         return _essenceTokenAddress;
     }


    // --- Admin Functions ---

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseTokenURI = baseURI_;
    }

    function setEssenceTokenAddress(address essenceAddress_) external onlyOwner {
        if (essenceAddress_ == address(0)) revert InvalidEssenceTokenAddress();
        address oldAddress = _essenceTokenAddress;
        _essenceTokenAddress = essenceAddress_;
        emit EssenceTokenAddressUpdated(oldAddress, _essenceTokenAddress);
    }

    function updateTierThresholds(uint256[] calldata newThresholds) external onlyOwner {
        if (newThresholds.length == 0) revert InvalidTierThresholds("must not be empty");
         // Ensure thresholds are strictly increasing
        for (uint i = 0; i < newThresholds.length; i++) {
            if (i > 0 && newThresholds[i] <= newThresholds[i-1]) {
                 revert InvalidTierThresholds("must be strictly increasing");
            }
        }
        _tierThresholds = newThresholds;
        emit TierThresholdsUpdated(newThresholds);

        // Consider adding a re-calibration logic for all existing Orbs here
        // or require users to calibrate manually after thresholds update.
        // Manual calibration is cheaper gas-wise.
    }

     function setSynthesisCostEssence(uint256 cost) external onlyOwner {
        _synthesisCostEssence = cost;
        emit SynthesisCostUpdated(cost);
    }

    function pauseContract() external onlyOwner whenNotPaused {
        _pause();
    }

    function unpauseContract() external onlyOwner whenPaused {
        _unpause();
    }


    // --- Internal/Helper Functions ---

    // Internal function to update power tier and dynamic traits based on current state
    function _updateOrbAttributes(uint256 orbId) internal {
        OrbAttributes storage orb = _orbAttributes[orbId]; // Use storage reference

        uint8 oldPowerTier = orb.powerTier;
        uint8 oldTrait1 = orb.dynamicTrait1;
        uint8 oldTrait2 = orb.dynamicTrait2;

        // Calculate Power Tier
        orb.powerTier = _calculatePowerTier(orb.essenceLevel);

        // Calculate Dynamic Traits (Placeholder Logic)
        // Example: Dynamic traits depend on tier, essence level, time since charged, and affinity.
        uint256 timeSinceCharged = block.timestamp - orb.lastChargedTime;

        // Example Trait 1: Modulated by tier and freshness
        orb.dynamicTrait1 = uint8(min(255, (uint256(orb.powerTier) * 20 + orb.essenceLevel / 50 + (1000 / (timeSinceCharged + 1))) / 10));

        // Example Trait 2: Modulated by affinity and essence level
        orb.dynamicTrait2 = uint8(min(255, (orb.affinityScore / 100 + orb.essenceLevel / 100) / 5));


        // Emit state change event if relevant attributes changed
        if (orb.powerTier != oldPowerTier || orb.dynamicTrait1 != oldTrait1 || orb.dynamicTrait2 != oldTrait2) {
            emit OrbStateChanged(orbId, orb.powerTier, orb.dynamicTrait1, orb.dynamicTrait2);
        }
    }

    // Internal function to calculate power tier based on essence level and thresholds
    function _calculatePowerTier(uint256 essenceLevel) internal view returns (uint8) {
        uint8 tier = 0;
        for (uint i = 0; i < _tierThresholds.length; i++) {
            if (essenceLevel >= _tierThresholds[i]) {
                tier = uint8(i + 1); // Tier 1 corresponds to threshold 0, Tier 2 to threshold 1, etc.
            } else {
                break; // Thresholds are increasing, so we found the tier
            }
        }
        return tier;
    }

    // Helper to get minimum of two unsigned integers
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    // Override _beforeTokenTransfer hook to prevent transfers for bound tokens
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal override whenNotPaused
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        // Check binding for single token transfers (ERC721 specific)
        if (batchSize == 1 && from != address(0) && to != address(0)) { // Avoid check during mint/burn
            if (_orbAttributes[tokenId].bound) revert OrbAlreadyBound(tokenId);
        }
        // Note: Batch transfers are not part of ERC721, but if implementing ERC1155 style transfers,
        // this hook would need adaptation. For ERC721, batchSize is always 1.
    }

     // Custom Error for invalid essence token address
    error InvalidEssenceTokenAddress();
     // Custom Error for Essence Transfer failure
    error EssenceTransferFailed(address token, uint256 amount);
}
```

**Explanation of Advanced/Creative Concepts:**

1.  **Dynamic NFTs:** The core concept is that an Orb's attributes (`powerTier`, `dynamicTrait1`, `dynamicTrait2`) are not fixed upon minting. They change based on the `essenceLevel`, `affinityScore`, and `lastChargedTime`. This requires storing mutable state (`_orbAttributes`) associated with each NFT and updating it via specific functions (`depositEssence`, `withdrawEssence`, `calibrateOrb`, `resonateOrbs`).
2.  **Token Utility / Resource Sink:** The `Essence` ERC20 token isn't just traded; it has a direct functional purpose within the NFT ecosystem. Depositing/withdrawing it powers the Orb's dynamic state. `infuseAffinity` provides an alternative sink for Essence, focusing on a different, potentially more persistent, metric. `synthesizeOrb` and `unbindOrbFromAddress` provide further burning/spending mechanisms for Essence.
3.  **Tiered System:** `powerTier` creates discrete levels based on `essenceLevel`, adding a clear progression mechanism linked to token investment.
4.  **Timed Mechanics:** `lastChargedTime` introduces a temporal element. The example `_calculateDynamicTraits` uses `timeSinceCharged`, allowing for mechanics where traits decay over time or require periodic interaction (`calibrateOrb`) to maintain peak performance.
5.  **NFT Bonding:** The `bound` flag and the override of `transferFrom`/`safeTransferFrom` enable making an NFT non-transferable. This could be used for staking, equipping items in a game, preventing market listing while in use, etc. `unbindOrbFromAddress` provides a way to revert this, but at a cost, creating a strategic choice.
6.  **NFT Synthesis/Crafting:** `synthesizeOrb` is a complex ritual where two NFTs and a fungible resource are consumed to create a new, potentially more powerful, NFT with derived attributes. This is a common pattern in blockchain gaming and adds depth to the ecosystem.
7.  **NFT Interaction / Resonance:** `resonateOrbs` provides a mechanism for NFTs to interact directly with each other on-chain, beyond simple transfers. The logic implemented here (averaging affinity, temporary trait boost) is just an example; this function could implement many complex state transitions between Orbs.
8.  **On-Chain State Transitions:** Functions like `depositEssence`, `withdrawEssence`, `calibrateOrb`, `resonateOrbs`, and `synthesizeOrb` involve reading existing Orb state, performing calculations (including tiering and dynamic trait logic), writing new state, and interacting with an external token contract. This represents complex, multi-step on-chain logic.
9.  **Role-Based Access Control & Pausability:** Standard but important for managing a complex system. `Ownable` restricts administrative functions, and `Pausable` allows stopping critical operations in case of emergency or upgrades (though upgradeability itself isn't built-in here).
10. **Custom Errors:** Using `error` definitions instead of `require` strings is a more gas-efficient and informative pattern introduced in recent Solidity versions.

This contract serves as a foundation for a game or ecosystem where NFTs are living, evolving entities influenced by player action and resource management, going beyond static digital collectibles.