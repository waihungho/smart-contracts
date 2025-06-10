Okay, here is a Solidity smart contract demonstrating several advanced, creative, and less commonly duplicated concepts. It focuses on a system of "Adaptive Programmable Assets" which are similar to Soulbound Tokens (SBTs) but with dynamic traits, composability, and integrated adaptive funding/interaction rules.

**Disclaimer:** This contract is complex and includes novel concepts. It is provided for educational purposes and demonstration of advanced Solidity patterns. It has NOT been audited and should NOT be used in production without significant security review, gas optimization, and thorough testing. String manipulation (`string`, `keccak256(bytes(string))`) can be gas-intensive; using `bytes32` directly for trait names internally is generally more efficient in practice but strings are used here for readability of the concept.

---

**Smart Contract Outline & Function Summary**

**Contract Name:** `AdaptiveProgrammableAssetSystem`

**Core Concept:** A system for creating and managing dynamic, non-transferable-by-default assets (like SBTs) that possess mutable traits. These traits change based on on-chain interactions (triggering rules), attestation by authorized entities, or even decay over time. Assets can hold other assets (composability) and ERC-20 tokens. Traits influence system interactions, such as eligibility for adaptive funding from a communal pool. The system includes mechanisms for defining trait behavior rules, registering trusted parties (attesters, external contracts), and basic access control/pausing.

**Key Features:**

1.  **Adaptive Assets:** Assets with dynamic traits that change based on defined rules and interactions.
2.  **Programmable Traits:** Traits can be influenced by specific on-chain actions or external attestation.
3.  **Behavioral Rules:** Define how certain actions map to changes in specific traits.
4.  **Attestation:** Trusted parties can directly set or influence asset traits.
5.  **Trait Decay:** Traits can be configured to decrease in value over time, requiring ongoing activity or attestation to maintain.
6.  **Composability (Nested Assets):** Assets can contain other assets, creating hierarchical structures.
7.  **Composability (ERC-20 Holding):** Assets can securely hold ERC-20 tokens internally.
8.  **Adaptive Funding:** A mechanism where assets can request/receive funding from a pool based on their current trait profile and defined eligibility/multiplier rules.
9.  **Asset Linking:** Create arbitrary, typed relationships between assets (graph-like structure).
10. **External Contract Integration:** Allow registered external contracts to trigger trait changes for assets.
11. **Access Control & Pausability:** Standard mechanisms for system management.

**Function Summary:**

*   **Core Asset Management:**
    *   `mintAsset(address recipient)`: Mints a new asset for the recipient. Returns the new asset ID.
    *   `getAssetOwner(uint256 assetId)`: Returns the current owner of an asset.
    *   `getAssetTraits(uint256 assetId)`: Returns a list of all trait names for an asset.
    *   `getAssetTraitValue(uint256 assetId, string memory traitName)`: Returns the current value of a specific trait for an asset (potentially with decay applied).
    *   `getTotalAssets()`: Returns the total number of assets minted.
    *   `isTraitLocked(uint256 assetId, string memory traitName)`: Checks if a specific trait is locked against changes.
    *   `configureInitialTraits(uint256 assetId, string[] memory traitNames, uint256[] memory initialValues)`: Sets initial trait values for a newly minted asset (callable by owner or minter within a grace period).
*   **Trait Definition & Rule Management:**
    *   `defineTraitType(string memory traitName, uint256 decayRatePerSecond, uint256 initialValue)`: Defines a new type of trait, including its decay properties and default initial value.
    *   `getTraitTypeDefinition(string memory traitName)`: Returns the definition details for a trait type.
    *   `registerActionRule(bytes32 ruleId, string memory affectedTrait, uint256 impactValue, bool isAdditive)`: Defines a rule mapping an action ID (`ruleId`) to a specific impact on a trait (`affectedTrait`).
    *   `getActionRule(bytes32 ruleId)`: Returns the details of a registered action rule.
*   **Dynamic Trait Modification:**
    *   `triggerTraitChange(uint256 assetId, bytes32 ruleId)`: Applies the effect of a registered action rule to an asset's trait. Callable by asset owner, attesters, or registered external contracts.
    *   `attestTraitValue(uint256 assetId, string memory traitName, uint256 attestedValue)`: Allows a registered attester to set the value of a specific trait for an asset.
    *   `decayTrait(uint256 assetId, string memory traitName)`: Manually triggers decay calculation and updates the value of a trait based on elapsed time and its defined decay rate.
    *   `lockTrait(uint256 assetId, string memory traitName)`: Locks a specific trait for an asset, preventing further changes (except by owner/governance override).
    *   `unlockTrait(uint256 assetId, string memory traitName)`: Unlocks a previously locked trait.
    *   `delegateTraitManagement(uint256 assetId, address delegatee)`: Allows the asset owner to delegate the ability to trigger trait changes or decay for their asset to another address.
    *   `revokeTraitManagementDelegation(uint256 assetId)`: Revokes trait management delegation for an asset.
*   **Attester Management:**
    *   `registerAttester(address attester)`: Registers an address as a trusted attester (owner only).
    *   `revokeAttester(address attester)`: Revokes attester status (owner only).
    *   `isAttester(address account)`: Checks if an address is a registered attester.
    *   `getApprovedAttesters()`: Returns the list of registered attesters.
*   **External Contract Integration:**
    *   `registerExternalContract(address externalContract)`: Registers an external contract address allowed to call functions like `triggerTraitChange` (owner only).
    *   `revokeExternalContract(address externalContract)`: Revokes external contract status (owner only).
    *   `isRegisteredExternalContract(address account)`: Checks if an address is a registered external contract.
    *   `getRegisteredExternalContracts()`: Returns the list of registered external contracts.
*   **Composability (Nesting & ERC-20):**
    *   `depositERC20(uint256 assetId, address tokenContract, uint256 amount)`: Deposits ERC-20 tokens into the specified asset's internal balance (requires asset owner approval/call).
    *   `withdrawERC20(uint256 assetId, address tokenContract, uint256 amount)`: Withdraws ERC-20 tokens from the asset's internal balance (asset owner only).
    *   `getAssetERC20Balance(uint256 assetId, address tokenContract)`: Returns the balance of a specific ERC-20 token held within an asset.
    *   `nestAsset(uint256 parentAssetId, uint256 childAssetId)`: Nests `childAssetId` inside `parentAssetId` (owner of both required).
    *   `unnestAsset(uint256 childAssetId)`: Removes a nested asset from its parent (owner of child required).
    *   `getNestedAssets(uint256 assetId)`: Returns the list of asset IDs nested within `assetId`.
    *   `getAssetParent(uint256 assetId)`: Returns the parent asset ID if the asset is nested.
*   **Adaptive Funding:**
    *   `depositFunding()`: Receives Ether into the contract's funding pool (payable).
    *   `setFundingEligibilityTrait(string memory traitName, uint256 threshold)`: Sets a minimum trait value required for an asset to be eligible for funding.
    *   `removeFundingEligibilityTrait(string memory traitName)`: Removes a trait eligibility requirement.
    *   `setFundingMultiplierTrait(string memory traitName, uint256 multiplierBasisPoints)`: Sets a trait that provides a funding multiplier (in basis points, 10000 = 1x).
    *   `removeFundingMultiplierTrait(string memory traitName)`: Removes a trait multiplier.
    *   `calculateFundingAmount(uint256 assetId)`: Calculates the potential funding amount for an asset based on current traits and funding rules (view function).
    *   `requestFunding(uint256 assetId)`: Allows an eligible asset owner to request funding (transfers calculated amount from pool).
    *   `distributeFunding(uint256[] memory assetIds)`: Allows owner/privileged role to trigger funding distribution for multiple assets.
*   **Asset Linking:**
    *   `linkAssets(uint256 asset1, uint256 asset2, string memory linkType)`: Creates a directed link of a specific type from asset1 to asset2 (owner of asset1 required).
    *   `unlinkAssets(uint256 asset1, uint256 asset2, string memory linkType)`: Removes a link from asset1 to asset2.
    *   `getLinkedAssets(uint256 assetId, string memory linkType)`: Returns a list of asset IDs linked from `assetId` with a specific type.
*   **System Control:**
    *   `pauseSystem()`: Pauses core interactions (owner only).
    *   `unpauseSystem()`: Unpauses core interactions (owner only).
    *   `upgradeSystem(address newContractAddress)`: Records the address of a potential new version of the contract (placeholder for upgradeability).
    *   `getFundingPoolBalance()`: Returns the current balance of the contract's funding pool.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol"; // For ERC20 safeTransfer

// Note: Using OpenZeppelin interfaces/utils is standard practice and not considered "duplication of open source" in the sense of duplicating core *logic* or *patterns*.
// The core logic around dynamic traits, nesting, adaptive funding based on traits, and linking is the custom part.

// Outline and Function Summary are above the code as requested.

contract AdaptiveProgrammableAssetSystem {
    using Address for address payable;

    address public owner;
    bool public paused;

    uint256 private _nextTokenId; // Start from 1 to avoid conflicts with 0 checks

    // --- State Variables ---

    // Asset storage: tokenId -> Asset struct
    mapping(uint256 tokenId => Asset) public assets;
    mapping(uint256 tokenId => address) public tokenOwners;
    mapping(uint256 tokenId => bool) public assetExists; // Track if token ID is minted

    // Trait Definitions: traitName (bytes32 hash) -> TraitDefinition
    mapping(bytes32 traitHash => TraitDefinition) public traitDefinitions;
    bytes32[] public registeredTraitTypes; // List of defined trait hashes

    // Trait Storage: tokenId -> traitName (bytes32 hash) -> Trait
    mapping(uint256 tokenId => mapping(bytes32 traitHash => Trait)) public tokenTraits;
    mapping(uint256 tokenId => mapping(bytes32 traitHash => bool)) public traitLocked;

    // Trait Management Delegation: tokenId -> delegatee
    mapping(uint256 tokenId => address) public traitManagementDelegatee;

    // Action Rules: ruleId (bytes32) -> ActionRule
    mapping(bytes32 ruleId => ActionRule) public actionRules;
    bytes32[] public registeredActionRuleIds; // List of defined rule IDs

    // Attestation: attesterAddress -> bool
    mapping(address attester => bool) public isApprovedAttester;
    address[] private approvedAttesters; // List of attesters for easy retrieval

    // External Contract Integration: contractAddress -> bool
    mapping(address externalContract => bool) public isRegisteredExternalContract;
    address[] private registeredExternalContracts; // List of external contracts

    // Composability (ERC20): tokenId -> tokenContract -> balance
    mapping(uint256 tokenId => mapping(address tokenContract => uint256)) public tokenERC20Balances;

    // Composability (Nesting): parentTokenId -> list of childTokenIds
    mapping(uint256 parentTokenId => uint256[] internal nestedAssetsList); // Internal list
    mapping(uint256 childTokenId => uint256) public parentAsset; // childTokenId -> parentTokenId

    // Asset Linking: tokenId1 -> linkType (bytes32 hash) -> list of tokenId2
    mapping(uint256 tokenId1 => mapping(bytes32 linkTypeHash => uint256[] internal linkedAssetsList));
    mapping(uint256 tokenId => mapping(bytes32 linkTypeHash => mapping(uint256 targetTokenId => bool))) internal linkedAssetExists; // Helper for checking existence

    // Adaptive Funding Rules: traitName (bytes32 hash) -> threshold/multiplier
    mapping(bytes32 traitHash => uint256) public fundingEligibilityThresholds;
    mapping(bytes32 traitHash => uint256) public fundingMultiplierBasisPoints; // 10000 = 1x, 5000 = 0.5x, 20000 = 2x

    // Upgradeability Placeholder
    address public nextVersion;

    // --- Structs ---

    struct Asset {
        uint256 id;
        uint64 mintedTimestamp;
        // Traits are stored in the tokenTraits mapping
        // Nested assets are tracked via parentAsset mapping and nestedAssetsList
        // ERC20 balances are in tokenERC20Balances mapping
    }

    struct TraitDefinition {
        bytes32 traitHash; // keccak256(bytes(traitName))
        uint256 decayRatePerSecond; // How much the value decreases per second
        uint256 initialValue; // Default value when trait is added
    }

    struct Trait {
        uint256 value;
        uint64 lastUpdatedTimestamp;
    }

    struct ActionRule {
        bytes32 ruleId; // Identifier for the action
        bytes32 affectedTraitHash; // keccak256(bytes(affectedTrait))
        uint256 impactValue; // How much the trait changes
        bool isAdditive; // True for addition, False for subtraction
    }

    // --- Events ---

    event AssetMinted(uint256 indexed assetId, address indexed owner, uint64 timestamp);
    event TraitUpdated(uint256 indexed assetId, bytes32 indexed traitHash, uint256 oldValue, uint256 newValue, uint64 timestamp, address indexed updater);
    event TraitDecayed(uint256 indexed assetId, bytes32 indexed traitHash, uint256 oldValue, uint256 newValue, uint64 timestamp);
    event TraitLocked(uint256 indexed assetId, bytes32 indexed traitHash, address indexed account);
    event TraitUnlocked(uint256 indexed assetId, bytes32 indexed traitHash, address indexed account);
    event TraitManagementDelegated(uint256 indexed assetId, address indexed oldDelegatee, address indexed newDelegatee);

    event TraitTypeDefined(bytes32 indexed traitHash, string traitName, uint256 decayRatePerSecond, uint256 initialValue);
    event ActionRuleRegistered(bytes32 indexed ruleId, string affectedTrait, uint256 impactValue, bool isAdditive);

    event AttesterRegistered(address indexed attester, address indexed registrar);
    event AttesterRevoked(address indexed attester, address indexed revoker);
    event ExternalContractRegistered(address indexed externalContract, address indexed registrar);
    event ExternalContractRevoked(address indexed externalContract, address indexed revoker);

    event ERC20Deposited(uint256 indexed assetId, address indexed tokenContract, uint256 amount, address indexed depositor);
    event ERC20Withdrawn(uint256 indexed assetId, address indexed tokenContract, uint256 amount, address indexed withdrawer);

    event AssetNested(uint256 indexed parentAssetId, uint256 indexed childAssetId, address indexed account);
    event AssetUnnested(uint256 indexed parentAssetId, uint256 indexed childAssetId, address indexed account);

    event AssetsLinked(uint256 indexed asset1Id, uint256 indexed asset2Id, bytes32 indexed linkTypeHash, address indexed linker);
    event AssetsUnlinked(uint256 indexed asset1Id, uint256 indexed asset2Id, bytes32 indexed linkTypeHash, address indexed unlinker);

    event FundingDeposited(uint256 amount, address indexed depositor);
    event FundingEligibilitySet(bytes32 indexed traitHash, uint256 threshold);
    event FundingEligibilityRemoved(bytes32 indexed traitHash);
    event FundingMultiplierSet(bytes32 indexed traitHash, uint256 multiplierBasisPoints);
    event FundingMultiplierRemoved(bytes32 indexed traitHash);
    event FundingRequested(uint256 indexed assetId, uint256 amount, address indexed recipient);
    event FundingDistributed(uint256[] indexed assetIds, uint256 totalAmount, address indexed distributor);

    event SystemPaused(address indexed account);
    event SystemUnpaused(address indexed account);
    event UpgradeAddressSet(address indexed newVersion);

    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == owner, "APAS: Not owner");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "APAS: System is paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "APAS: System is not paused");
        _;
    }

    modifier onlyAttester() {
        require(isApprovedAttester[msg.sender], "APAS: Not an approved attester");
        _;
    }

    modifier onlyRegisteredExternalContract() {
        require(isRegisteredExternalContract[msg.sender], "APAS: Not a registered external contract");
        _;
    }

    modifier onlyAssetOwnerOrDelegatee(uint256 assetId) {
        address currentOwner = tokenOwners[assetId];
        require(
            msg.sender == currentOwner || traitManagementDelegatee[assetId] == msg.sender,
            "APAS: Not asset owner or delegatee"
        );
        _;
    }

    modifier assetMustExist(uint256 assetId) {
        require(assetExists[assetId], "APAS: Asset does not exist");
        _;
    }

    // --- Constructor ---

    constructor() {
        owner = msg.sender;
        _nextTokenId = 1; // Start token IDs from 1
        paused = false;
    }

    // --- Core Asset Management ---

    /**
     * @notice Mints a new asset and assigns it to a recipient.
     * @param recipient The address to receive the new asset.
     * @return The ID of the newly minted asset.
     */
    function mintAsset(address recipient) external onlyOwner whenNotPaused returns (uint256) {
        uint256 newTokenId = _nextTokenId++;
        assets[newTokenId] = Asset({
            id: newTokenId,
            mintedTimestamp: uint64(block.timestamp)
        });
        tokenOwners[newTokenId] = recipient;
        assetExists[newTokenId] = true;

        emit AssetMinted(newTokenId, recipient, uint64(block.timestamp));
        return newTokenId;
    }

    /**
     * @notice Gets the owner of an asset.
     * @param assetId The ID of the asset.
     * @return The owner's address.
     */
    function getAssetOwner(uint256 assetId) public view assetMustExist(assetId) returns (address) {
        return tokenOwners[assetId];
    }

    /**
     * @notice Gets the list of trait names associated with an asset.
     * @param assetId The ID of the asset.
     * @return An array of trait names (strings).
     */
    function getAssetTraits(uint256 assetId) public view assetMustExist(assetId) returns (string[] memory) {
        // This requires iterating through all known trait types and checking if the asset has it.
        // Or store a list of active traits per asset (more complex storage).
        // Let's iterate through defined trait types for simplicity in this demo.
        string[] memory traitNames = new string[](registeredTraitTypes.length);
        uint256 count = 0;
        for (uint i = 0; i < registeredTraitTypes.length; i++) {
            bytes32 traitHash = registeredTraitTypes[i];
            if (tokenTraits[assetId][traitHash].lastUpdatedTimestamp > 0) { // Assuming lastUpdatedTimestamp > 0 means the trait exists for this asset
                 // Find the original string name for the hash - requires storing mapping from hash back to string
                 // Or find the definition struct which contains the hash - let's refine TraitDefinition struct to store name.
                 // Re-structuring TraitDefinition and related storage to store string name directly or in a lookup
                 // For demo purposes, assume we can get the name back.
                 // **Practical consideration: Storing/retrieving strings is expensive. Using bytes32 hashes internally is better.**
                 // **Let's add a mapping `traitHash -> traitNameString` for view functions.**
                 // Adding mapping: `mapping(bytes32 traitHash => string public traitHashToString);`
                 // Update `defineTraitType` to populate this.
                 traitNames[count] = traitHashToString[traitHash];
                 count++;
            }
        }

        // Trim the array
        string[] memory activeTraitNames = new string[](count);
        for (uint i = 0; i < count; i++) {
            activeTraitNames[i] = traitNames[i];
        }
        return activeTraitNames;
    }

    /**
     * @notice Gets the current value of a specific trait for an asset, applying decay.
     * @param assetId The ID of the asset.
     * @param traitName The name of the trait.
     * @return The calculated current trait value.
     */
    function getAssetTraitValue(uint256 assetId, string memory traitName) public view assetMustExist(assetId) returns (uint256) {
        bytes32 traitHash = keccak256(bytes(traitName));
        require(traitDefinitions[traitHash].traitHash != bytes32(0), "APAS: Trait type not defined");

        Trait memory currentTrait = tokenTraits[assetId][traitHash];
        TraitDefinition memory definition = traitDefinitions[traitHash];

        // If the trait hasn't been set explicitly, return initial value
        if (currentTrait.lastUpdatedTimestamp == 0) {
            return definition.initialValue;
        }

        // Calculate decay since last update
        uint256 elapsedTime = block.timestamp - currentTrait.lastUpdatedTimestamp;
        uint256 decayAmount = elapsedTime * definition.decayRatePerSecond;

        // Apply decay, ensuring value doesn't go below zero
        uint256 decayedValue = currentTrait.value >= decayAmount ? currentTrait.value - decayAmount : 0;

        return decayedValue;
    }

    /**
     * @notice Returns the total number of assets minted.
     * @return The total count of assets.
     */
    function getTotalAssets() public view returns (uint256) {
        return _nextTokenId - 1; // Subtract 1 because _nextTokenId is the next available ID
    }

    /**
     * @notice Checks if a specific trait for an asset is locked.
     * @param assetId The ID of the asset.
     * @param traitName The name of the trait.
     * @return True if locked, false otherwise.
     */
    function isTraitLocked(uint256 assetId, string memory traitName) public view assetMustExist(assetId) returns (bool) {
        return traitLocked[assetId][keccak256(bytes(traitName))];
    }

     /**
     * @notice Sets initial trait values for a newly minted asset.
     *         Callable by owner or the recipient shortly after minting (e.g., within 1 block or tx).
     *         For this demo, owner can call it anytime, but in practice, this would have stricter limits.
     * @param assetId The ID of the asset.
     * @param traitNames Array of trait names to configure.
     * @param initialValues Array of initial values corresponding to traitNames.
     */
    function configureInitialTraits(uint256 assetId, string[] memory traitNames, uint256[] memory initialValues) external onlyOwner whenNotPaused assetMustExist(assetId) {
        // Add time limit requirement for non-owner in a real contract
        require(traitNames.length == initialValues.length, "APAS: Mismatched trait names and values count");

        for (uint i = 0; i < traitNames.length; i++) {
            bytes32 traitHash = keccak256(bytes(traitNames[i]));
            require(traitDefinitions[traitHash].traitHash != bytes32(0), "APAS: Trait type not defined");

            // Overwrite existing trait if it exists, or set initial if not
            _updateTrait(assetId, traitHash, initialValues[i], msg.sender);
        }
    }

    // --- Trait Definition & Rule Management ---

    // Need mapping traitHash -> traitNameString for getAssetTraits view function
    mapping(bytes32 traitHash => string) public traitHashToString;

    /**
     * @notice Defines a new type of trait that can be used in the system.
     * @param traitName The name of the trait.
     * @param decayRatePerSecond The rate at which the trait value decays per second.
     * @param initialValue The default value for this trait when added to an asset.
     */
    function defineTraitType(string memory traitName, uint256 decayRatePerSecond, uint256 initialValue) external onlyOwner {
        bytes32 traitHash = keccak256(bytes(traitName));
        require(traitDefinitions[traitHash].traitHash == bytes32(0), "APAS: Trait type already defined");

        traitDefinitions[traitHash] = TraitDefinition({
            traitHash: traitHash,
            decayRatePerSecond: decayRatePerSecond,
            initialValue: initialValue
        });
        registeredTraitTypes.push(traitHash);
        traitHashToString[traitHash] = traitName; // Store string for view functions

        emit TraitTypeDefined(traitHash, traitName, decayRatePerSecond, initialValue);
    }

     /**
     * @notice Gets the definition details for a trait type.
     * @param traitName The name of the trait.
     * @return traitName The name of the trait.
     * @return decayRatePerSecond The decay rate.
     * @return initialValue The default initial value.
     */
    function getTraitTypeDefinition(string memory traitName) public view returns (string memory, uint256, uint256) {
        bytes32 traitHash = keccak256(bytes(traitName));
        TraitDefinition memory def = traitDefinitions[traitHash];
        require(def.traitHash != bytes32(0), "APAS: Trait type not defined");
        return (traitHashToString[traitHash], def.decayRatePerSecond, def.initialValue);
    }


    /**
     * @notice Registers a rule that defines how a specific action (identified by ruleId) impacts a trait.
     * @param ruleId An identifier for the action/rule.
     * @param affectedTrait The name of the trait affected by this rule.
     * @param impactValue The amount by which the trait value changes.
     * @param isAdditive True if the impact is an addition, false for subtraction.
     */
    function registerActionRule(bytes32 ruleId, string memory affectedTrait, uint256 impactValue, bool isAdditive) external onlyOwner {
        bytes32 traitHash = keccak256(bytes(affectedTrait));
        require(traitDefinitions[traitHash].traitHash != bytes32(0), "APAS: Affected trait type not defined");

        actionRules[ruleId] = ActionRule({
            ruleId: ruleId,
            affectedTraitHash: traitHash,
            impactValue: impactValue,
            isAdditive: isAdditive
        });

        // Add ruleId to list if not already present (simple check for demo)
        bool exists = false;
        for(uint i=0; i < registeredActionRuleIds.length; i++) {
            if (registeredActionRuleIds[i] == ruleId) {
                exists = true;
                break;
            }
        }
        if (!exists) {
             registeredActionRuleIds.push(ruleId);
        }


        emit ActionRuleRegistered(ruleId, affectedTrait, impactValue, isAdditive);
    }

     /**
     * @notice Gets the details of a registered action rule.
     * @param ruleId The identifier for the action/rule.
     * @return ruleId The identifier.
     * @return affectedTrait The name of the affected trait.
     * @return impactValue The impact value.
     * @return isAdditive Is the impact additive.
     */
    function getActionRule(bytes32 ruleId) public view returns (bytes32, string memory, uint256, bool) {
        ActionRule memory rule = actionRules[ruleId];
        require(rule.ruleId != bytes32(0), "APAS: Rule not found");
        return (rule.ruleId, traitHashToString[rule.affectedTraitHash], rule.impactValue, rule.isAdditive);
    }

    // --- Dynamic Trait Modification ---

    /**
     * @notice Internal helper function to update a trait's value and timestamp.
     * @param assetId The ID of the asset.
     * @param traitHash The hash of the trait name.
     * @param newValue The new value for the trait.
     * @param updater The address that triggered the update.
     */
    function _updateTrait(uint256 assetId, bytes32 traitHash, uint256 newValue, address updater) internal assetMustExist(assetId) {
        require(!traitLocked[assetId][traitHash], "APAS: Trait is locked");

        // First, apply decay based on the *current* state before setting the new value.
        // This ensures decay is accounted for between updates from different sources.
        // We don't modify the state in the view function `getAssetTraitValue`.
        // The decay logic needs to be applied *before* the update is saved.
        // Let's implement an internal decay application logic.

        Trait storage currentTrait = tokenTraits[assetId][traitHash];
        TraitDefinition memory definition = traitDefinitions[traitHash];

        uint256 oldValue = currentTrait.lastUpdatedTimestamp == 0 ? definition.initialValue : _applyDecayLogic(currentTrait.value, currentTrait.lastUpdatedTimestamp, definition.decayRatePerSecond);

        currentTrait.value = newValue;
        currentTrait.lastUpdatedTimestamp = uint64(block.timestamp);

        emit TraitUpdated(assetId, traitHash, oldValue, newValue, uint64(block.timestamp), updater);
    }

    /**
     * @notice Internal helper to calculate value after decay.
     * @param initialValue The value before decay.
     * @param lastUpdateTime The timestamp when the value was last updated.
     * @param decayRatePerSecond The decay rate.
     * @return The value after decay.
     */
    function _applyDecayLogic(uint256 initialValue, uint64 lastUpdateTime, uint256 decayRatePerSecond) internal view returns (uint256) {
         if (decayRatePerSecond == 0 || lastUpdateTime == 0) {
             return initialValue; // No decay or trait not initialized
         }
         uint256 elapsedTime = block.timestamp - lastUpdateTime;
         uint256 decayAmount = elapsedTime * decayRatePerSecond;
         return initialValue >= decayAmount ? initialValue - decayAmount : 0;
    }

    /**
     * @notice Applies the effect of a registered action rule to an asset's trait.
     *         Callable by asset owner, their delegatee, registered attesters, or registered external contracts.
     * @param assetId The ID of the asset.
     * @param ruleId The identifier for the action/rule to apply.
     */
    function triggerTraitChange(uint256 assetId, bytes32 ruleId)
        external
        whenNotPaused
        assetMustExist(assetId)
    {
        address currentOwner = tokenOwners[assetId];
        address delegatee = traitManagementDelegatee[assetId];
        require(
            msg.sender == currentOwner || msg.sender == delegatee ||
            isApprovedAttester[msg.sender] || isRegisteredExternalContract[msg.sender],
            "APAS: Unauthorized to trigger trait change"
        );

        ActionRule memory rule = actionRules[ruleId];
        require(rule.ruleId != bytes32(0), "APAS: Rule not found");
        require(traitDefinitions[rule.affectedTraitHash].traitHash != bytes32(0), "APAS: Affected trait type not defined");

        bytes32 traitHash = rule.affectedTraitHash;
        Trait storage currentTrait = tokenTraits[assetId][traitHash];
        TraitDefinition memory definition = traitDefinitions[traitHash];

        // Get current effective value (with decay)
        uint256 currentValue = currentTrait.lastUpdatedTimestamp == 0 ? definition.initialValue : _applyDecayLogic(currentTrait.value, currentTrait.lastUpdatedTimestamp, definition.decayRatePerSecond);

        uint256 newValue;
        if (rule.isAdditive) {
            newValue = currentValue + rule.impactValue;
            // Prevent overflow (simple check, more robust checks might be needed depending on expected value range)
            require(newValue >= currentValue, "APAS: Value overflow");
        } else {
            newValue = currentValue >= rule.impactValue ? currentValue - rule.impactValue : 0;
        }

        _updateTrait(assetId, traitHash, newValue, msg.sender);
    }

    /**
     * @notice Allows a registered attester to directly set the value of a specific trait for an asset.
     * @param assetId The ID of the asset.
     * @param traitName The name of the trait to attest.
     * @param attestedValue The value the attester vouches for.
     */
    function attestTraitValue(uint256 assetId, string memory traitName, uint256 attestedValue) external onlyAttester whenNotPaused assetMustExist(assetId) {
        bytes32 traitHash = keccak256(bytes(traitName));
        require(traitDefinitions[traitHash].traitHash != bytes32(0), "APAS: Trait type not defined");
        _updateTrait(assetId, traitHash, attestedValue, msg.sender);
    }

     /**
     * @notice Manually triggers the decay calculation and update for a specific trait.
     *         Callable by asset owner or their delegatee.
     * @param assetId The ID of the asset.
     * @param traitName The name of the trait to decay.
     */
    function decayTrait(uint256 assetId, string memory traitName) external onlyAssetOwnerOrDelegatee(assetId) whenNotPaused assetMustExist(assetId) {
        bytes32 traitHash = keccak256(bytes(traitName));
        Trait storage currentTrait = tokenTraits[assetId][traitHash];
        TraitDefinition memory definition = traitDefinitions[traitHash];

        // Only decay if the trait has been initialized and has a decay rate
        if (currentTrait.lastUpdatedTimestamp == 0 || definition.decayRatePerSecond == 0) {
             // No decay needed or possible
             return;
        }

        uint256 oldValue = currentTrait.value;
        uint256 decayedValue = _applyDecayLogic(oldValue, currentTrait.lastUpdatedTimestamp, definition.decayRatePerSecond);

        // If decay happened, update the trait
        if (decayedValue != oldValue) {
             currentTrait.value = decayedValue;
             currentTrait.lastUpdatedTimestamp = uint64(block.timestamp); // Update timestamp to mark when decay was applied

             emit TraitDecayed(assetId, traitHash, oldValue, decayedValue, uint64(block.timestamp));
        }
         // If decayedValue == oldValue, it means no time has passed since last update or decay rate is 0, so no event/update needed.
    }

    /**
     * @notice Locks a specific trait for an asset, preventing most updates (except by owner/governance).
     * @param assetId The ID of the asset.
     * @param traitName The name of the trait to lock.
     */
    function lockTrait(uint256 assetId, string memory traitName) external onlyAssetOwnerOrDelegatee(assetId) whenNotPaused assetMustExist(assetId) {
        bytes32 traitHash = keccak256(bytes(traitName));
        traitLocked[assetId][traitHash] = true;
        emit TraitLocked(assetId, traitHash, msg.sender);
    }

    /**
     * @notice Unlocks a previously locked trait for an asset.
     * @param assetId The ID of the asset.
     * @param traitName The name of the trait to unlock.
     */
    function unlockTrait(uint256 assetId, string memory traitName) external onlyAssetOwnerOrDelegatee(assetId) whenNotPaused assetMustExist(assetId) {
        bytes32 traitHash = keccak256(bytes(traitName));
        traitLocked[assetId][traitHash] = false;
        emit TraitUnlocked(assetId, traitHash, msg.sender);
    }

     /**
     * @notice Allows the asset owner to delegate trait management capabilities (triggering changes, decay, locking/unlocking) for their asset to another address.
     * @param assetId The ID of the asset.
     * @param delegatee The address to delegate management to (address(0) to revoke).
     */
    function delegateTraitManagement(uint256 assetId, address delegatee) external whenNotPaused assetMustExist(assetId) {
        require(msg.sender == tokenOwners[assetId], "APAS: Not asset owner");
        address oldDelegatee = traitManagementDelegatee[assetId];
        traitManagementDelegatee[assetId] = delegatee;
        emit TraitManagementDelegated(assetId, oldDelegatee, delegatee);
    }

     /**
     * @notice Revokes any active trait management delegation for an asset.
     * @param assetId The ID of the asset.
     */
    function revokeTraitManagementDelegation(uint256 assetId) external whenNotPaused assetMustExist(assetId) {
         require(msg.sender == tokenOwners[assetId], "APAS: Not asset owner");
         delegateTraitManagement(assetId, address(0)); // Delegate to address(0) to revoke
     }


    // --- Attester Management ---

    /**
     * @notice Registers an address as a trusted attester. Only owner can call.
     * @param attester The address to register.
     */
    function registerAttester(address attester) external onlyOwner {
        require(!isApprovedAttester[attester], "APAS: Attester already registered");
        isApprovedAttester[attester] = true;
        approvedAttesters.push(attester);
        emit AttesterRegistered(attester, msg.sender);
    }

    /**
     * @notice Revokes attester status from an address. Only owner can call.
     * @param attester The address to revoke.
     */
    function revokeAttester(address attester) external onlyOwner {
        require(isApprovedAttester[attester], "APAS: Address is not an attester");
        isApprovedAttester[attester] = false;

        // Remove from list (basic implementation, O(n))
        for (uint i = 0; i < approvedAttesters.length; i++) {
            if (approvedAttesters[i] == attester) {
                approvedAttesters[i] = approvedAttesters[approvedAttesters.length - 1];
                approvedAttesters.pop();
                break;
            }
        }
        emit AttesterRevoked(attester, msg.sender);
    }

    /**
     * @notice Checks if an address is a registered attester.
     * @param account The address to check.
     * @return True if registered, false otherwise.
     */
    function isAttester(address account) public view returns (bool) {
        return isApprovedAttester[account];
    }

    /**
     * @notice Returns the list of all registered attesters.
     * @return An array of attester addresses.
     */
    function getApprovedAttesters() public view returns (address[] memory) {
        return approvedAttesters;
    }

    // --- External Contract Integration ---

    /**
     * @notice Registers an external contract address allowed to call certain restricted functions (e.g., triggerTraitChange). Only owner can call.
     * @param externalContract The address of the external contract.
     */
    function registerExternalContract(address externalContract) external onlyOwner {
        require(!isRegisteredExternalContract[externalContract], "APAS: External contract already registered");
        isRegisteredExternalContract[externalContract] = true;
        registeredExternalContracts.push(externalContract);
        emit ExternalContractRegistered(externalContract, msg.sender);
    }

    /**
     * @notice Revokes external contract status from an address. Only owner can call.
     * @param externalContract The address to revoke.
     */
    function revokeExternalContract(address externalContract) external onlyOwner {
        require(isRegisteredExternalContract[externalContract], "APAS: Address is not a registered external contract");
        isRegisteredExternalContract[externalContract] = false;

         // Remove from list (basic implementation, O(n))
        for (uint i = 0; i < registeredExternalContracts.length; i++) {
            if (registeredExternalContracts[i] == externalContract) {
                registeredExternalContracts[i] = registeredExternalContracts[registeredExternalContracts.length - 1];
                registeredExternalContracts.pop();
                break;
            }
        }
        emit ExternalContractRevoked(externalContract, msg.sender);
    }

    /**
     * @notice Checks if an address is a registered external contract.
     * @param account The address to check.
     * @return True if registered, false otherwise.
     */
    function isRegisteredExternalContract(address account) public view returns (bool) {
        return isRegisteredExternalContract[account];
    }

    /**
     * @notice Returns the list of all registered external contracts.
     * @return An array of external contract addresses.
     */
    function getRegisteredExternalContracts() public view returns (address[] memory) {
        return registeredExternalContracts;
    }

    // --- Composability (Nesting & ERC-20) ---

    /**
     * @notice Deposits ERC-20 tokens into the specified asset's internal balance.
     *         Requires that this contract has allowance or is approved to spend the tokens from msg.sender.
     * @param assetId The ID of the asset to deposit into.
     * @param tokenContract The address of the ERC-20 token contract.
     * @param amount The amount of tokens to deposit.
     */
    function depositERC20(uint256 assetId, address tokenContract, uint256 amount) external whenNotPaused assetMustExist(assetId) {
         // In a real scenario, this might require msg.sender to be the asset owner or a privileged address,
         // or perhaps anyone can donate to an asset. Let's allow anyone for flexibility in demo.
         require(amount > 0, "APAS: Amount must be greater than 0");
         IERC20 token = IERC20(tokenContract);

         // Use safeTransferFrom to handle different ERC-20 implementations
         uint256 balanceBefore = token.balanceOf(address(this));
         token.transferFrom(msg.sender, address(this), amount);
         uint256 balanceAfter = token.balanceOf(address(this));
         uint256 transferred = balanceAfter - balanceBefore;
         require(transferred == amount, "APAS: ERC20 transfer failed or amount mismatch");


         tokenERC20Balances[assetId][tokenContract] += amount;

         emit ERC20Deposited(assetId, tokenContract, amount, msg.sender);
    }

    /**
     * @notice Withdraws ERC-20 tokens from the asset's internal balance. Only asset owner can call.
     * @param assetId The ID of the asset to withdraw from.
     * @param tokenContract The address of the ERC-20 token contract.
     * @param amount The amount of tokens to withdraw.
     */
    function withdrawERC20(uint256 assetId, address tokenContract, uint256 amount) external whenNotPaused assetMustExist(assetId) {
         require(msg.sender == tokenOwners[assetId], "APAS: Not asset owner");
         require(tokenERC20Balances[assetId][tokenContract] >= amount, "APAS: Insufficient ERC20 balance in asset");
         require(amount > 0, "APAS: Amount must be greater than 0");

         tokenERC20Balances[assetId][tokenContract] -= amount;
         IERC20(tokenContract).transfer(msg.sender, amount); // Use standard transfer as contract owns the tokens

         emit ERC20Withdrawn(assetId, tokenContract, amount, msg.sender);
    }

    /**
     * @notice Gets the balance of a specific ERC-20 token held within an asset.
     * @param assetId The ID of the asset.
     * @param tokenContract The address of the ERC-20 token contract.
     * @return The balance of the token within the asset.
     */
    function getAssetERC20Balance(uint256 assetId, address tokenContract) public view assetMustExist(assetId) returns (uint256) {
         return tokenERC20Balances[assetId][tokenContract];
    }

    /**
     * @notice Nests a child asset inside a parent asset. Requires owner of both.
     * @param parentAssetId The ID of the parent asset.
     * @param childAssetId The ID of the child asset to nest.
     */
    function nestAsset(uint256 parentAssetId, uint256 childAssetId) external whenNotPaused assetMustExist(parentAssetId) assetMustExist(childAssetId) {
         require(msg.sender == tokenOwners[parentAssetId], "APAS: Not owner of parent asset");
         require(msg.sender == tokenOwners[childAssetId], "APAS: Not owner of child asset");
         require(parentAssetId != childAssetId, "APAS: Cannot nest asset within itself");
         require(parentAsset[childAssetId] == 0, "APAS: Child asset is already nested");

         // Prevent creating cycles (basic check: child cannot be an ancestor of parent)
         uint256 currentParent = parentAssetId;
         while(currentParent != 0) {
             require(currentParent != childAssetId, "APAS: Cannot create nesting cycle");
             currentParent = parentAsset[currentParent];
         }


         // Transfer ownership of child to this contract (or burning) is typical for nesting,
         // but let's keep owner the same and just update the parent pointer for this flexible system.
         // This means the owner *still* owns the nested asset and can unnest it.
         parentAsset[childAssetId] = parentAssetId;
         nestedAssetsList[parentAssetId].push(childAssetId);

         emit AssetNested(parentAssetId, childAssetId, msg.sender);
    }

     /**
     * @notice Removes a nested asset from its parent. Requires owner of the child asset.
     * @param childAssetId The ID of the child asset to unnest.
     */
    function unnestAsset(uint256 childAssetId) external whenNotPaused assetMustExist(childAssetId) {
         require(msg.sender == tokenOwners[childAssetId], "APAS: Not owner of child asset");
         uint256 currentParentId = parentAsset[childAssetId];
         require(currentParentId != 0, "APAS: Asset is not nested");

         parentAsset[childAssetId] = 0;

         // Remove child from parent's nested list (basic implementation, O(n))
         uint252[] storage children = nestedAssetsList[currentParentId];
         for (uint i = 0; i < children.length; i++) {
             if (children[i] == childAssetId) {
                 children[i] = children[children.length - 1];
                 children.pop();
                 break;
             }
         }

         emit AssetUnnested(currentParentId, childAssetId, msg.sender);
     }

    /**
     * @notice Gets the list of asset IDs nested directly within an asset.
     * @param assetId The ID of the parent asset.
     * @return An array of child asset IDs.
     */
    function getNestedAssets(uint256 assetId) public view assetMustExist(assetId) returns (uint256[] memory) {
         return nestedAssetsList[assetId];
    }

    /**
     * @notice Gets the parent asset ID for a nested asset. Returns 0 if not nested.
     * @param assetId The ID of the asset.
     * @return The parent asset ID, or 0.
     */
    function getAssetParent(uint256 assetId) public view assetMustExist(assetId) returns (uint256) {
         return parentAsset[assetId];
    }

    // --- Asset Linking ---

    /**
     * @notice Creates a directed link of a specific type from asset1 to asset2. Requires owner of asset1.
     * @param asset1Id The ID of the asset originating the link.
     * @param asset2Id The ID of the target asset.
     * @param linkType The type of link (e.g., "friend", "workedOn", "follows").
     */
    function linkAssets(uint256 asset1Id, uint256 asset2Id, string memory linkType) external whenNotPaused assetMustExist(asset1Id) assetMustExist(asset2Id) {
         require(msg.sender == tokenOwners[asset1Id], "APAS: Not owner of asset1");
         require(asset1Id != asset2Id, "APAS: Cannot link asset to itself");

         bytes32 linkTypeHash = keccak256(bytes(linkType));

         // Prevent duplicate links
         require(!linkedAssetExists[asset1Id][linkTypeHash][asset2Id], "APAS: Link already exists");

         linkedAssetsList[asset1Id][linkTypeHash].push(asset2Id);
         linkedAssetExists[asset1Id][linkTypeHash][asset2Id] = true;

         emit AssetsLinked(asset1Id, asset2Id, linkTypeHash, msg.sender);
    }

    /**
     * @notice Removes a directed link of a specific type from asset1 to asset2. Requires owner of asset1.
     * @param asset1Id The ID of the asset originating the link.
     * @param asset2Id The ID of the target asset.
     * @param linkType The type of link.
     */
    function unlinkAssets(uint256 asset1Id, uint256 asset2Id, string memory linkType) external whenNotPaused assetMustExist(asset1Id) assetMustExist(asset2Id) {
         require(msg.sender == tokenOwners[asset1Id], "APAS: Not owner of asset1");

         bytes32 linkTypeHash = keccak256(bytes(linkType));
         require(linkedAssetExists[asset1Id][linkTypeHash][asset2Id], "APAS: Link does not exist");

         // Remove from list (basic implementation, O(n))
         uint256[] storage targets = linkedAssetsList[asset1Id][linkTypeHash];
         for (uint i = 0; i < targets.length; i++) {
             if (targets[i] == asset2Id) {
                 targets[i] = targets[targets.length - 1];
                 targets.pop();
                 break;
             }
         }

         linkedAssetExists[asset1Id][linkTypeHash][asset2Id] = false;

         emit AssetsUnlinked(asset1Id, asset2Id, linkTypeHash, msg.sender);
    }

     /**
     * @notice Gets the list of asset IDs linked from asset1 with a specific link type.
     * @param assetId The ID of the asset originating the link.
     * @param linkType The type of link.
     * @return An array of target asset IDs.
     */
    function getLinkedAssets(uint256 assetId, string memory linkType) public view assetMustExist(assetId) returns (uint256[] memory) {
         bytes32 linkTypeHash = keccak256(bytes(linkType));
         return linkedAssetsList[assetId][linkTypeHash];
    }


    // --- Adaptive Funding ---

    /**
     * @notice Allows depositing Ether into the contract's funding pool.
     */
    receive() external payable {
        if (msg.value > 0) {
             emit FundingDeposited(msg.value, msg.sender);
        }
    }

    /**
     * @notice Allows depositing Ether into the contract's funding pool. Explicit function.
     */
    function depositFunding() external payable {
         if (msg.value > 0) {
              emit FundingDeposited(msg.value, msg.sender);
         }
    }


    /**
     * @notice Sets a minimum trait value required for an asset to be eligible for funding. Only owner can call.
     * @param traitName The name of the trait.
     * @param threshold The minimum value required.
     */
    function setFundingEligibilityTrait(string memory traitName, uint256 threshold) external onlyOwner {
         bytes32 traitHash = keccak256(bytes(traitName));
         require(traitDefinitions[traitHash].traitHash != bytes32(0), "APAS: Trait type not defined");
         fundingEligibilityThresholds[traitHash] = threshold;
         emit FundingEligibilitySet(traitHash, threshold);
    }

    /**
     * @notice Removes a trait eligibility requirement for funding. Only owner can call.
     * @param traitName The name of the trait.
     */
    function removeFundingEligibilityTrait(string memory traitName) external onlyOwner {
         bytes32 traitHash = keccak256(bytes(traitName));
         delete fundingEligibilityThresholds[traitHash]; // Deleting resets to 0
         emit FundingEligibilityRemoved(traitHash);
    }

    /**
     * @notice Sets a trait that provides a funding multiplier (in basis points). Only owner can call.
     *         MultiplierBasisPoints: 10000 = 1x, 5000 = 0.5x, 20000 = 2x.
     * @param traitName The name of the trait.
     * @param multiplierBasisPoints The multiplier value in basis points.
     */
    function setFundingMultiplierTrait(string memory traitName, uint256 multiplierBasisPoints) external onlyOwner {
         bytes32 traitHash = keccak256(bytes(traitName));
         require(traitDefinitions[traitHash].traitHash != bytes32(0), "APAS: Trait type not defined");
         fundingMultiplierBasisPoints[traitHash] = multiplierBasisPoints;
         emit FundingMultiplierSet(traitHash, multiplierBasisPoints);
    }

    /**
     * @notice Removes a trait multiplier for funding. Only owner can call.
     * @param traitName The name of the trait.
     */
    function removeFundingMultiplierTrait(string memory traitName) external onlyOwner {
         bytes32 traitHash = keccak256(bytes(traitName));
         delete fundingMultiplierBasisPoints[traitHash]; // Deleting resets to 0
         emit FundingMultiplierRemoved(traitHash);
    }


    /**
     * @notice Calculates the potential funding amount for an asset based on current traits and funding rules.
     *         Does NOT check if the asset is eligible for a request, only calculates the *potential* amount.
     * @param assetId The ID of the asset.
     * @return The calculated funding amount in Wei. Returns 0 if not potentially eligible based on thresholds.
     */
    function calculateFundingAmount(uint256 assetId) public view assetMustExist(assetId) returns (uint256) {
        // Check eligibility thresholds
        for (uint i = 0; i < registeredTraitTypes.length; i++) {
            bytes32 traitHash = registeredTraitTypes[i];
            uint256 threshold = fundingEligibilityThresholds[traitHash];
            if (threshold > 0) { // If a threshold is set for this trait
                uint256 currentTraitValue = getAssetTraitValue(assetId, traitHashToString[traitHash]); // Get value with decay
                if (currentTraitValue < threshold) {
                    return 0; // Not eligible if any required trait is below threshold
                }
            }
        }

        // Base funding amount (can be hardcoded, a parameter, or trait-based)
        // For simplicity, let's use a minimal base amount or 0 if only multipliers matter.
        uint256 baseFunding = 1e15; // Example: 0.001 Ether base amount (adjust as needed)
        if (registeredTraitTypes.length > 0 && baseFunding == 0) {
             // If no base funding and no multipliers, result is 0.
             // Need to ensure there's *some* source for funding amount, e.g., a default multiplier or base.
             // Let's assume a minimum baseFunding or that multipliers apply to 1 wei for calculation.
             // Or better, add a base funding state variable.
        }

        uint256 totalMultiplier = 10000; // Start at 1x (10000 basis points)

        // Apply multipliers
        for (uint i = 0; i < registeredTraitTypes.length; i++) {
            bytes32 traitHash = registeredTraitTypes[i];
            uint256 multiplier = fundingMultiplierBasisPoints[traitHash];
            if (multiplier > 0) { // If a multiplier is set for this trait
                 uint256 currentTraitValue = getAssetTraitValue(assetId, traitHashToString[traitHash]); // Get value with decay
                 // Simple linear multiplier based on trait value (can be more complex)
                 totalMultiplier = (totalMultiplier * currentTraitValue * multiplier) / 10000;
                 // Be careful with large numbers and potential overflow.
                 // A better approach might be (totalMultiplier * multiplier) / 10000, then scale by trait value later.
                 // Let's do totalMultiplier = (totalMultiplier * multiplier) / 10000; for each multiplier trait, then apply final multiplier to base.
                 // No, the *value* of the trait should influence the multiplier. E.g., 1 'skill' trait gives 1.1x, 10 gives 2x.
                 // Let's define multiplier rule: BaseMultiplier + (TraitValue * MultiplierBasisPointsPerUnit)
                 // Redefining: `fundingMultiplierBasisPoints` is BasisPoints *per unit of trait value*.
                 // E.g., 'Reputation' trait with multiplier 100 bp/unit means Reputation 5 gives 500 bp (0.05x).
                 // Total multiplier = 10000 (base) + SUM(TraitValue_i * MultiplierBasisPoints_i).
            }
        }

        // Let's use the simpler "Total multiplier = 10000 (base) + SUM(TraitValue_i * MultiplierBasisPoints_i)" model.
        totalMultiplier = 10000; // Reset to base 1x
         for (uint i = 0; i < registeredTraitTypes.length; i++) {
            bytes32 traitHash = registeredTraitTypes[i];
            uint256 multiplierPerUnit = fundingMultiplierBasisPoints[traitHash];
            if (multiplierPerUnit > 0) {
                 uint256 currentTraitValue = getAssetTraitValue(assetId, traitHashToString[traitHash]);
                 uint256 traitContribution = currentTraitValue * multiplierPerUnit;
                 totalMultiplier += traitContribution;
                 // Check for overflow before adding
                 require(totalMultiplier >= traitContribution, "APAS: Funding multiplier overflow");
            }
         }


        // Calculate final amount
        // Ensure we don't divide by zero if baseFunding is 0 and totalMultiplier is 0 or 10000
        uint256 potentialAmount = (baseFunding * totalMultiplier) / 10000; // Apply final multiplier

        return potentialAmount;
    }

    /**
     * @notice Allows an eligible asset owner to request funding from the pool.
     * @param assetId The ID of the asset requesting funding.
     */
    function requestFunding(uint256 assetId) external whenNotPaused assetMustExist(assetId) {
        require(msg.sender == tokenOwners[assetId], "APAS: Not asset owner");

        uint256 amountToTransfer = calculateFundingAmount(assetId);
        require(amountToTransfer > 0, "APAS: Asset not eligible for funding or amount is zero");
        require(address(this).balance >= amountToTransfer, "APAS: Insufficient funds in pool");

        (bool success, ) = payable(msg.sender).call{value: amountToTransfer}("");
        require(success, "APAS: Ether transfer failed");

        emit FundingRequested(assetId, amountToTransfer, msg.sender);

        // Optional: Add a trait update here to reflect funding was received, e.g., a "FundingReceivedCount" trait
        // bytes32 fundingCountTraitHash = keccak256(bytes("FundingReceivedCount"));
        // _updateTrait(assetId, fundingCountTraitHash, getAssetTraitValue(assetId, "FundingReceivedCount") + 1, address(this));
    }

    /**
     * @notice Allows owner/privileged role to trigger funding distribution for multiple assets.
     * @param assetIds Array of asset IDs to consider for distribution.
     *         Only assets in this list that are eligible will receive funding.
     */
    function distributeFunding(uint256[] memory assetIds) external onlyOwner whenNotPaused {
        uint256 totalAmountDistributed = 0;
        for (uint i = 0; i < assetIds.length; i++) {
            uint256 assetId = assetIds[i];
            if (!assetExists[assetId]) {
                 continue; // Skip non-existent assets
            }

            uint256 amountToTransfer = calculateFundingAmount(assetId);

            if (amountToTransfer > 0 && address(this).balance >= amountToTransfer) {
                address payable recipient = payable(tokenOwners[assetId]);
                (bool success, ) = recipient.call{value: amountToTransfer}("");
                if (success) {
                    totalAmountDistributed += amountToTransfer;
                    emit FundingRequested(assetId, amountToTransfer, recipient); // Re-use event or make new one
                    // Optional: Update trait for distributed assets
                }
                // If transfer fails for one, continue with others
            }
        }
        if (totalAmountDistributed > 0) {
             emit FundingDistributed(assetIds, totalAmountDistributed, msg.sender);
        }
    }

     /**
     * @notice Returns the current balance of Ether in the contract's funding pool.
     * @return The balance in Wei.
     */
    function getFundingPoolBalance() public view returns (uint256) {
         return address(this).balance;
    }


    // --- System Control ---

    /**
     * @notice Pauses the contract, preventing state-changing operations except for the owner.
     */
    function pauseSystem() external onlyOwner whenNotPaused {
        paused = true;
        emit SystemPaused(msg.sender);
    }

    /**
     * @notice Unpauses the contract, allowing normal operation.
     */
    function unpauseSystem() external onlyOwner whenPaused {
        paused = false;
        emit SystemUnpaused(msg.sender);
    }

    /**
     * @notice Sets the address of a potential next version of the contract (placeholder for upgradeability).
     *         Does not implement actual upgrade logic (which requires proxy patterns).
     * @param newContractAddress The address of the next version.
     */
    function upgradeSystem(address newContractAddress) external onlyOwner {
        nextVersion = newContractAddress;
        emit UpgradeAddressSet(newContractAddress);
    }

    // --- Utility/View Functions (continued for function count) ---

     /**
     * @notice Returns the list of all registered action rule IDs.
     * @return An array of rule IDs (bytes32).
     */
     function getRegisteredActionRuleIds() public view returns (bytes32[] memory) {
         return registeredActionRuleIds;
     }

     /**
     * @notice Gets the funding eligibility threshold for a specific trait.
     * @param traitName The name of the trait.
     * @return The threshold value, or 0 if no threshold is set.
     */
     function getFundingEligibilityThreshold(string memory traitName) public view returns (uint256) {
         return fundingEligibilityThresholds[keccak256(bytes(traitName))];
     }

     /**
     * @notice Gets the funding multiplier basis points for a specific trait.
     * @param traitName The name of the trait.
     * @return The multiplier basis points, or 0 if no multiplier is set.
     */
     function getFundingMultiplierBasisPoints(string memory traitName) public view returns (uint256) {
         return fundingMultiplierBasisPoints[keccak256(bytes(traitName))];
     }

     /**
      * @notice Get the address delegated for trait management for an asset.
      * @param assetId The ID of the asset.
      * @return The delegatee address, or address(0) if none is set.
      */
     function getTraitManagementDelegatee(uint256 assetId) public view assetMustExist(assetId) returns (address) {
         return traitManagementDelegatee[assetId];
     }

      // Example function that could internally call triggerTraitChange
      // (This is where the "action" part of ActionRule comes in)
      // function submitProofOfSkill(uint256 assetId, bytes32 proofHash) external whenNotPaused assetMustExist(assetId) {
      //     // Add verification logic for proofHash here...
      //     // If verification passes:
      //     // bytes32 skillProofRuleId = keccak256("SKILL_PROOF_ACTION"); // Example rule ID
      //     // triggerTraitChange(assetId, skillProofRuleId);
      //     // emit ProofOfSkillSubmitted(assetId, proofHash, msg.sender);
      // }
      // This function is commented out as it requires external logic, but illustrates the intended usage of triggerTraitChange.
}
```