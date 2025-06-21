Okay, let's design an interesting, advanced, and creative smart contract. We'll create a system for managing "Agent" NFTs with dynamic traits that evolve based on user activity and verified off-chain events via oracles. A key aspect is how user *behavior* within the system or *outcomes* verified externally can permanently alter the properties of their NFTs. We'll incorporate role-based access control for trusted data feeds and governance features.

This concept combines dynamic NFTs, behavioral tracking (simulated via role-based events), oracle integration, and access control in a way that isn't a direct copy of common open-source patterns.

**Concept Name:** AgentForge

**Core Idea:** A factory for creating and managing unique "Agent" NFTs (ERC721). These Agents possess a set of dynamic traits (e.g., Strength, Intelligence, Agility). These traits can evolve based on specific "Behavior Events" recorded within the system (triggered by trusted roles) or "Oracle Outcomes" verified by external data feeds (triggered by a different trusted role). Governance functions (via roles) control which traits exist, how they can evolve, and system parameters.

**Key Features:**

1.  **Dynamic Agent NFTs:** ERC721 tokens with mutable state (traits).
2.  **Parameterized Traits:** Define different types of traits with min/max values, names, etc.
3.  **Behavioral Evolution:** Traits change based on predefined rules triggered by "Behavior Events" (e.g., participating in a game, completing a task - simulated here by a function call from a trusted role).
4.  **Oracle-Driven Evolution:** Traits change based on predefined rules triggered by "Oracle Outcomes" (e.g., verifying a real-world event, getting external data - simulated here by a function call from a trusted role representing an oracle feed).
5.  **Trait Evolution Rules:** Define *how* traits change based on specific behavior types or oracle outcomes.
6.  **Role-Based Access Control:** Specific roles (`EVENT_PROCESSOR_ROLE`, `ORACLE_ROLE`, `ADMIN_ROLE`) are required to trigger trait-modifying functions.
7.  **Governance (via Roles):** Admin roles can define traits, update evolution rules, set base URI, manage other roles, and withdraw funds.
8.  **Pausable:** Ability to pause core functionality in emergencies.
9.  **ERC721 Compliance:** Standard NFT functionality.

---

### AgentForge Contract Outline & Function Summary

**Outline:**

1.  Pragma and SPDX License
2.  Import Libraries (ERC721, AccessControl, Pausable, ReentrancyGuard)
3.  Error Definitions
4.  Events
5.  Structs (TraitDefinition, TraitEvolutionRule)
6.  Constants (Roles)
7.  State Variables (NFT counter, mappings for traits, trait definitions, evolution rules, base URI, etc.)
8.  Constructor (Initialize roles, inherited contracts)
9.  Modifiers (using Pausable)
10. ERC721 Standard Functions (Overridden or inherited)
11. Agent Minting Function
12. Trait Management Functions (Define, remove, get definition, get all types)
13. Trait Evolution Rule Functions (Update, get)
14. Dynamic Trait Interaction Functions (Triggered by roles)
    *   `processBehaviorEvent`
    *   `processOracleOutcome`
15. Read Functions (Get agent traits, get rules, get base URI, etc.)
16. Access Control Functions (Inherited from AccessControl)
17. Pausable Functions (Inherited from Pausable)
18. Withdrawal Function (Admin/Owner)
19. Internal Helper Functions (Apply trait updates, generate token URI)

**Function Summary (Total: 26 Functions + inherited AccessControl/Pausable utils):**

1.  `constructor()`: Deploys the contract, initializes roles (assigns `DEFAULT_ADMIN_ROLE` and others to deployer).
2.  `mintAgent(address to)`: Mints a new Agent NFT to the specified address. Requires Ether payment (simulated). Increments agent counter.
3.  `balanceOf(address owner) public view override returns (uint256)`: ERC721: Returns the number of NFTs owned by an address.
4.  `ownerOf(uint256 tokenId) public view override returns (address)`: ERC721: Returns the owner of a specific NFT.
5.  `transferFrom(address from, address to, uint256 tokenId) public virtual override whenNotPaused`: ERC721: Transfers NFT ownership. Pausable.
6.  `safeTransferFrom(address from, address to, uint256 tokenId) public virtual override whenNotPaused`: ERC721: Safely transfers NFT ownership. Pausable.
7.  `safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual override whenNotPaused`: ERC721: Safely transfers NFT ownership with data. Pausable.
8.  `approve(address to, uint256 tokenId) public virtual override whenNotPaused`: ERC721: Approves address to manage NFT. Pausable.
9.  `getApproved(uint256 tokenId) public view override returns (address)`: ERC721: Gets approved address for NFT.
10. `setApprovalForAll(address operator, bool approved) public virtual override`: ERC721: Sets approval for all NFTs.
11. `isApprovedForAll(address owner, address operator) public view override returns (bool)`: ERC721: Checks if operator is approved for all NFTs.
12. `tokenURI(uint256 tokenId) public view override returns (string memory)`: ERC721: Returns the metadata URI for an NFT. Dynamic based on `_baseTokenURI`.
13. `getTokenTraits(uint256 tokenId) public view returns (mapping(bytes32 => int256) memory)`: Custom: Returns the current trait values for a specific Agent.
14. `getSupportedTraitTypes() public view returns (bytes32[] memory)`: Custom: Returns a list of all defined trait type hashes.
15. `getTraitDefinition(bytes32 traitType) public view returns (TraitDefinition memory)`: Custom: Returns the definition details for a specific trait type.
16. `defineTrait(bytes32 traitType, string calldata name, int256 min, int256 max) external onlyRole(DEFAULT_ADMIN_ROLE)`: Governance: Defines a new trait type and its parameters.
17. `removeTraitDefinition(bytes32 traitType) external onlyRole(DEFAULT_ADMIN_ROLE)`: Governance: Removes a trait definition (careful with existing agents).
18. `updateTraitEvolutionRule(bytes32 eventOrOutcomeType, bytes32 targetTraitType, int256 valueChange) external onlyRole(DEFAULT_ADMIN_ROLE)`: Governance: Sets or updates a rule: if `eventOrOutcomeType` occurs, change `targetTraitType` by `valueChange`.
19. `getTraitEvolutionRule(bytes32 eventOrOutcomeType) public view returns (bytes32 targetTraitType, int256 valueChange)`: Custom: Returns the evolution rule associated with a specific event/outcome type.
20. `processBehaviorEvent(uint256 agentId, bytes32 eventType, bytes calldata eventData) external onlyRole(EVENT_PROCESSOR_ROLE) whenNotPaused`: Behavioral: Triggered by Event Processors to apply trait changes based on a specific behavior type. `eventData` can carry auxiliary info.
21. `processOracleOutcome(uint256 agentId, bytes32 outcomeType, bytes calldata outcomeData) external onlyRole(ORACLE_ROLE) whenNotPaused`: Oracle: Triggered by Oracle feeds to apply trait changes based on a verified external outcome. `outcomeData` carries oracle result.
22. `setBaseTokenURI(string calldata baseURI) external onlyRole(DEFAULT_ADMIN_ROLE)`: Governance: Sets the base URI for NFT metadata (e.g., IPFS gateway).
23. `pause() external onlyRole(DEFAULT_ADMIN_ROLE)`: Pausable: Pauses the contract.
24. `unpause() external onlyRole(DEFAULT_ADMIN_ROLE)`: Pausable: Unpauses the contract.
25. `withdrawEther() external onlyOwner`: Admin: Allows the contract owner to withdraw collected Ether (from minting). Uses ReentrancyGuard.
26. `_applyTraitUpdate(uint256 agentId, bytes32 traitType, int256 valueChange) internal`: Internal helper to update a specific trait value for an agent, respecting min/max bounds.

*Inherited Functions:* AccessControl adds `grantRole`, `revokeRole`, `renounceRole`, `hasRole`, `getRoleAdmin`, `getRoleMember`, `getRoleMemberCount`, `getRoleMembers`. Pausable adds `paused()`. (These contribute to the *total* available functionality but are standard library functions).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// --- Outline & Function Summary ---
// See above summary for detailed descriptions.
//
// Outline:
// 1. Pragma and SPDX License
// 2. Import Libraries (ERC721, AccessControl, Pausable, ReentrancyGuard)
// 3. Error Definitions
// 4. Events
// 5. Structs (TraitDefinition, TraitEvolutionRule)
// 6. Constants (Roles)
// 7. State Variables
// 8. Constructor
// 9. Modifiers
// 10. ERC721 Standard Functions (Overrides)
// 11. Agent Minting Function
// 12. Trait Management Functions
// 13. Trait Evolution Rule Functions
// 14. Dynamic Trait Interaction Functions (Role-gated)
// 15. Read Functions
// 16. Access Control Functions (Inherited)
// 17. Pausable Functions (Inherited)
// 18. Withdrawal Function
// 19. Internal Helper Functions

// Function Summary (26 Custom Functions + Inherited):
// 1. constructor()
// 2. mintAgent(address to)
// 3. balanceOf(address owner) - ERC721
// 4. ownerOf(uint256 tokenId) - ERC721
// 5. transferFrom(address from, address to, uint256 tokenId) - ERC721, Pausable
// 6. safeTransferFrom(address from, address to, uint256 tokenId) - ERC721, Pausable
// 7. safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) - ERC721, Pausable
// 8. approve(address to, uint256 tokenId) - ERC721, Pausable
// 9. getApproved(uint256 tokenId) - ERC721
// 10. setApprovalForAll(address operator, bool approved) - ERC721
// 11. isApprovedForAll(address owner, address operator) - ERC721
// 12. tokenURI(uint256 tokenId) - ERC721, Dynamic
// 13. getTokenTraits(uint256 tokenId) - Custom Read
// 14. getSupportedTraitTypes() - Custom Read
// 15. getTraitDefinition(bytes32 traitType) - Custom Read
// 16. defineTrait(bytes32 traitType, string calldata name, int256 min, int256 max) - Governance (Admin)
// 17. removeTraitDefinition(bytes32 traitType) - Governance (Admin)
// 18. updateTraitEvolutionRule(bytes32 eventOrOutcomeType, bytes32 targetTraitType, int256 valueChange) - Governance (Admin)
// 19. getTraitEvolutionRule(bytes32 eventOrOutcomeType) - Custom Read
// 20. processBehaviorEvent(uint256 agentId, bytes32 eventType, bytes calldata eventData) - Behavioral Trigger (Event Processor Role)
// 21. processOracleOutcome(uint256 agentId, bytes32 outcomeType, bytes calldata outcomeData) - Oracle Trigger (Oracle Role)
// 22. setBaseTokenURI(string calldata baseURI) - Governance (Admin)
// 23. pause() - Pausable (Admin)
// 24. unpause() - Pausable (Admin)
// 25. withdrawEther() - Admin/Owner, ReentrancyGuard
// 26. _applyTraitUpdate(uint256 agentId, bytes32 traitType, int256 valueChange) - Internal Helper

contract AgentForge is ERC721, AccessControl, Pausable, ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _agentIds;

    // --- Errors ---
    error AgentForge__TraitAlreadyDefined(bytes32 traitType);
    error AgentForge__TraitNotDefined(bytes32 traitType);
    error AgentForge__AgentDoesNotExist(uint256 tokenId);
    error AgentForge__MintPriceNotMet(uint256 requiredPrice, uint256 sentAmount);
    error AgentForge__NoEtherToWithdraw();

    // --- Events ---
    event AgentMinted(uint256 indexed tokenId, address indexed owner, uint256 mintPrice);
    event TraitDefined(bytes32 indexed traitType, string name, int256 min, int256 max);
    event TraitDefinitionRemoved(bytes32 indexed traitType);
    event TraitEvolutionRuleUpdated(bytes32 indexed eventOrOutcomeType, bytes32 indexed targetTraitType, int256 valueChange);
    event AgentTraitUpdated(uint256 indexed agentId, bytes32 indexed traitType, int256 oldValue, int256 newValue);
    event BehaviorEventProcessed(uint256 indexed agentId, bytes32 indexed eventType);
    event OracleOutcomeProcessed(uint256 indexed agentId, bytes32 indexed outcomeType);
    event BaseTokenURIUpdated(string baseURI);

    // --- Roles ---
    // Default admin role (can grant/revoke other roles)
    bytes32 public constant DEFAULT_ADMIN_ROLE = keccak256("DEFAULT_ADMIN_ROLE");
    // Role allowed to trigger behavioral events (e.g., game engine backend)
    bytes32 public constant EVENT_PROCESSOR_ROLE = keccak256("EVENT_PROCESSOR_ROLE");
    // Role allowed to process verified oracle outcomes (e.g., Chainlink Keepers/VRF callback)
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");

    // --- Structs ---
    struct TraitDefinition {
        string name;
        int256 min;
        int256 max;
        bool exists; // Use exists flag instead of checking mapping existence
    }

    struct TraitEvolutionRule {
        bytes32 targetTraitType; // The trait this rule affects
        int256 valueChange;       // How much the trait value changes
        bool ruleExists;          // Use exists flag
    }

    // --- State Variables ---
    // Mapping from token ID to a mapping of traitTypeHash => traitValue
    mapping(uint256 tokenId => mapping(bytes32 traitType => int256 value)) private _agentTraits;
    // Mapping from traitTypeHash => TraitDefinition
    mapping(bytes32 traitType => TraitDefinition) private _traitDefinitions;
    // Array of supported trait type hashes
    bytes32[] private _supportedTraitTypes;

    // Mapping from eventOrOutcomeTypeHash => TraitEvolutionRule
    mapping(bytes32 eventOrOutcomeType => TraitEvolutionRule) private _traitEvolutionRules;

    string private _baseTokenURI;

    // Minting configuration (example)
    uint256 public mintPrice = 0.01 ether; // Example price

    // --- Constructor ---
    constructor() ERC721("AgentForge", "AGENT") {
        // Grant the deployer the default admin role
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        // Optionally grant initial EVENT_PROCESSOR_ROLE and ORACLE_ROLE to deployer
        // These should ideally be specific addresses in a production system
        _grantRole(EVENT_PROCESSOR_ROLE, msg.sender);
        _grantRole(ORACLE_ROLE, msg.sender);
    }

    // --- ERC721 Overrides (Includes Pausable) ---
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, AccessControl) returns (bool) {
        return interfaceId == type(ERC721).interfaceId || interfaceId == type(AccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) {
            revert ERC721NonexistentToken(tokenId);
        }
        return bytes(_baseTokenURI).length > 0 ? string(abi.encodePacked(_baseTokenURI, Strings.toString(tokenId))) : "";
    }

    // Pausable overrides for transfer functions
    function transferFrom(address from, address to, uint256 tokenId) public virtual override whenNotPaused {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override whenNotPaused {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual override whenNotPaused {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function approve(address to, uint256 tokenId) public virtual override whenNotPaused {
        super.approve(to, tokenId);
    }

    // --- Agent Minting Function ---
    function mintAgent(address to) public payable whenNotPaused returns (uint256) {
        if (msg.value < mintPrice) {
            revert AgentForge__MintPriceNotMet(mintPrice, msg.value);
        }

        _agentIds.increment();
        uint256 newTokenId = _agentIds.current();

        _safeMint(to, newTokenId);

        // Initialize traits for the new agent with default values (e.g., min value)
        for (uint i = 0; i < _supportedTraitTypes.length; i++) {
            bytes32 traitType = _supportedTraitTypes[i];
            TraitDefinition storage traitDef = _traitDefinitions[traitType];
            if (traitDef.exists) {
                 _agentTraits[newTokenId][traitType] = traitDef.min; // Initialize with min value
                 // No event for initialization to avoid log spam, assume min is known
            }
        }

        emit AgentMinted(newTokenId, to, msg.value);

        // Any excess Ether is kept in the contract, withdrawable by admin

        return newTokenId;
    }

    // --- Trait Management Functions (Governance) ---

    /// @notice Defines a new trait type that Agents can have.
    /// @param traitType A unique identifier (hash) for the trait.
    /// @param name The human-readable name of the trait (e.g., "Strength").
    /// @param min The minimum possible value for this trait.
    /// @param max The maximum possible value for this trait.
    function defineTrait(bytes32 traitType, string calldata name, int256 min, int256 max) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_traitDefinitions[traitType].exists) {
            revert AgentForge__TraitAlreadyDefined(traitType);
        }
        // Basic validation
        require(min <= max, "Min must be less than or equal to max");
        require(bytes(name).length > 0, "Trait name cannot be empty");

        _traitDefinitions[traitType] = TraitDefinition({
            name: name,
            min: min,
            max: max,
            exists: true
        });
        _supportedTraitTypes.push(traitType);

        emit TraitDefined(traitType, name, min, max);
    }

    /// @notice Removes a trait definition. Does NOT affect existing trait values on Agents.
    /// @param traitType The unique identifier (hash) of the trait to remove.
    function removeTraitDefinition(bytes32 traitType) external onlyRole(DEFAULT_ADMIN_ROLE) {
         if (!_traitDefinitions[traitType].exists) {
            revert AgentForge__TraitNotDefined(traitType);
        }

        // Mark as non-existent
        delete _traitDefinitions[traitType];

        // Removing from _supportedTraitTypes array is gas intensive O(n),
        // but necessary to keep the getSupportedTraitTypes list accurate.
        // For a large number of traits, a different structure might be needed.
        for (uint i = 0; i < _supportedTraitTypes.length; i++) {
            if (_supportedTraitTypes[i] == traitType) {
                _supportedTraitTypes[i] = _supportedTraitTypes[_supportedTraitTypes.length - 1];
                _supportedTraitTypes.pop();
                break;
            }
        }

        emit TraitDefinitionRemoved(traitType);
    }


    // --- Trait Evolution Rule Functions (Governance) ---

    /// @notice Sets or updates a rule for how a specific event or oracle outcome affects a trait.
    /// @param eventOrOutcomeType A unique identifier (hash) for the behavior event or oracle outcome type.
    /// @param targetTraitType The hash of the trait type that will be affected.
    /// @param valueChange The amount (positive or negative) to change the target trait's value.
    function updateTraitEvolutionRule(bytes32 eventOrOutcomeType, bytes32 targetTraitType, int256 valueChange) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (!_traitDefinitions[targetTraitType].exists) {
            revert AgentForge__TraitNotDefined(targetTraitType);
        }

        _traitEvolutionRules[eventOrOutcomeType] = TraitEvolutionRule({
            targetTraitType: targetTraitType,
            valueChange: valueChange,
            ruleExists: true
        });

        emit TraitEvolutionRuleUpdated(eventOrOutcomeType, targetTraitType, valueChange);
    }

    // --- Dynamic Trait Interaction Functions (Role-gated) ---

    /// @notice Processes a recorded behavior event, potentially triggering a trait update based on rules.
    /// This function should only be callable by addresses with the EVENT_PROCESSOR_ROLE.
    /// @param agentId The ID of the Agent NFT affected.
    /// @param eventType A unique identifier (hash) for the type of behavior event.
    /// @param eventData Optional additional data related to the event (ignored by default rule logic but available).
    function processBehaviorEvent(uint256 agentId, bytes32 eventType, bytes calldata eventData) external onlyRole(EVENT_PROCESSOR_ROLE) whenNotPaused {
         if (!_exists(agentId)) {
            revert AgentForge__AgentDoesNotExist(agentId);
        }

        TraitEvolutionRule storage rule = _traitEvolutionRules[eventType];
        if (rule.ruleExists) {
            // Rule found, apply the trait update
             _applyTraitUpdate(agentId, rule.targetTraitType, rule.valueChange);
        }

        emit BehaviorEventProcessed(agentId, eventType);
        // eventData is not indexed/stored by default here, but could be if needed.
    }

    /// @notice Processes a verified oracle outcome, potentially triggering a trait update based on rules.
    /// This function should only be callable by addresses with the ORACLE_ROLE.
    /// Assumes outcomeData contains the data from the oracle needed to potentially influence the trait change amount.
    /// Current rule logic only uses the predefined `valueChange`, but this can be extended.
    /// @param agentId The ID of the Agent NFT affected.
    /// @param outcomeType A unique identifier (hash) for the type of oracle outcome.
    /// @param outcomeData The raw data returned by the oracle.
    function processOracleOutcome(uint256 agentId, bytes32 outcomeType, bytes calldata outcomeData) external onlyRole(ORACLE_ROLE) whenNotPaused {
         if (!_exists(agentId)) {
            revert AgentForge__AgentDoesNotExist(agentId);
        }

        TraitEvolutionRule storage rule = _traitEvolutionRules[outcomeType];
        if (rule.ruleExists) {
            // Example: Rule found, apply the predefined trait update.
            // More advanced logic could parse outcomeData here to determine the change amount dynamically.
            _applyTraitUpdate(agentId, rule.targetTraitType, rule.valueChange);
        }

        emit OracleOutcomeProcessed(agentId, outcomeType);
        // outcomeData is not indexed/stored by default here.
    }

    // --- Read Functions ---

    /// @notice Gets the current trait values for a specific Agent.
    /// @param tokenId The ID of the Agent NFT.
    /// @return A mapping from traitTypeHash to traitValue.
    function getTokenTraits(uint256 tokenId) public view returns (mapping(bytes32 => int256) memory) {
        if (!_exists(tokenId)) {
            revert AgentForge__AgentDoesNotExist(tokenId);
        }
        // Note: Returning a mapping copy is gas intensive for many traits.
        // A better approach for many traits might be individual getter functions per trait,
        // or breaking traits into categories. Keeping it simple for the example.
        mapping(bytes32 => int256) memory currentTraits = new mapping(bytes32 => int256)();
         for (uint i = 0; i < _supportedTraitTypes.length; i++) {
            bytes32 traitType = _supportedTraitTypes[i];
             if (_traitDefinitions[traitType].exists) { // Ensure trait is still defined
                currentTraits[traitType] = _agentTraits[tokenId][traitType];
            }
        }
        return currentTraits;
    }

    /// @notice Gets the definition details for a specific trait type.
    /// @param traitType The hash of the trait type.
    /// @return The TraitDefinition struct.
    function getTraitDefinition(bytes32 traitType) public view returns (TraitDefinition memory) {
        if (!_traitDefinitions[traitType].exists) {
            revert AgentForge__TraitNotDefined(traitType);
        }
        return _traitDefinitions[traitType];
    }

     /// @notice Gets the trait evolution rule associated with a specific event or outcome type.
     /// @param eventOrOutcomeType The hash of the event or outcome type.
     /// @return targetTraitType The hash of the trait affected.
     /// @return valueChange The change amount.
     function getTraitEvolutionRule(bytes32 eventOrOutcomeType) public view returns (bytes32 targetTraitType, int256 valueChange) {
         TraitEvolutionRule storage rule = _traitEvolutionRules[eventOrOutcomeType];
         // Return empty/default values if rule doesn't exist
         return (rule.targetTraitType, rule.valueChange);
     }


    // --- Access Control Functions ---
    // Inherited from AccessControl:
    // - grantRole(bytes32 role, address account)
    // - revokeRole(bytes32 role, address account)
    // - renounceRole(bytes32 role, address account)
    // - hasRole(bytes32 role, address account)
    // - getRoleAdmin(bytes32 role)
    // - getRoleMember(bytes32 role, uint256 index)
    // - getRoleMemberCount(bytes32 role)
    // - getRoleMembers(bytes32 role) // Requires Enumerable variant - use getRoleMember/Count instead for basic AccessControl

    // --- Pausable Functions ---
    // Inherited from Pausable:
    // - pause()
    // - unpause()
    // - paused()

    // --- Withdrawal Function ---

    /// @notice Allows the contract owner to withdraw any accumulated Ether (e.g., from minting fees).
    function withdrawEther() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        if (balance == 0) {
            revert AgentForge__NoEtherToWithdraw();
        }
        (bool success, ) = payable(msg.sender).call{value: balance}("");
        require(success, "Ether withdrawal failed");
    }

    // --- Internal Helper Functions ---

    /// @notice Internal function to apply a change to an agent's trait value, respecting min/max bounds.
    /// @param agentId The ID of the Agent NFT.
    /// @param traitType The hash of the trait type to update.
    /// @param valueChange The amount to change the trait value by.
    function _applyTraitUpdate(uint256 agentId, bytes32 traitType, int256 valueChange) internal {
        TraitDefinition storage traitDef = _traitDefinitions[traitType];
        if (!traitDef.exists) {
            // Should not happen if rule validation was correct, but double check
            return;
        }

        int256 oldValue = _agentTraits[agentId][traitType];
        int256 newValue = oldValue + valueChange;

        // Clamp value to min/max bounds
        if (newValue < traitDef.min) {
            newValue = traitDef.min;
        }
        if (newValue > traitDef.max) {
            newValue = traitDef.max;
        }

        if (newValue != oldValue) {
            _agentTraits[agentId][traitType] = newValue;
            emit AgentTraitUpdated(agentId, traitType, oldValue, newValue);
        }
    }

    /// @notice Sets the base part of the token URI.
    /// @param baseURI The base string for token URIs (e.g., "ipfs://Qm.../").
    function setBaseTokenURI(string calldata baseURI) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _baseTokenURI = baseURI;
        emit BaseTokenURIUpdated(baseURI);
    }

    // Override AccessControl's _authorizeUpgrade (if using UUPS upgradeability)
    // function _authorizeUpgrade(address newImplementation) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}
}
```

**Explanation of Advanced/Creative/Trendy Concepts:**

1.  **Dynamic NFTs (Mutable Traits):** Unlike typical static NFTs where metadata is immutable, AgentForge allows the core properties (traits) of the NFT to change *after* minting based on defined logic. This enables NFTs that tell a story, represent evolving status, or change appearance/utility over time or based on interaction.
2.  **Behavioral/Oracle-Driven Evolution:** This is the core creative mechanic. Instead of random changes or simple time-based updates, traits evolve based on:
    *   **Behavior Events:** Designed to be triggered by an external system (like a game server, DApp backend, or trusted observer) via the `EVENT_PROCESSOR_ROLE`. This links *user activity* outside the contract's basic functions (but recorded by a trusted source) to the NFT's state. `eventData` allows passing context.
    *   **Oracle Outcomes:** Triggered by a trusted oracle feed via the `ORACLE_ROLE`. This allows real-world events (weather, sports scores, verifiable achievements off-chain) or computation results (Chainlink VRF for randomness, Chainlink Keepers for complex logic) to directly impact the NFT's traits. `outcomeData` carries the oracle result.
3.  **Parameterized Trait System:** Traits aren't hardcoded. New trait types (`Strength`, `Intelligence`, `Agility`, etc.) can be defined dynamically by the `DEFAULT_ADMIN_ROLE` with specific min/max bounds. This makes the system extensible.
4.  **Rule-Based Evolution Logic:** The `updateTraitEvolutionRule` function allows the `DEFAULT_ADMIN_ROLE` to define *how* a specific behavior event (`eventType`) or oracle outcome (`outcomeType`) impacts a *specific* trait (`targetTraitType`) by a *specific* amount (`valueChange`). This separates the *trigger* (event/oracle) from the *effect* (trait change), allowing flexible configuration without code changes. The current implementation is simple (`+valueChange`), but `_applyTraitUpdate` could be extended to handle more complex rule logic based on `eventData` or `outcomeData` if needed (e.g., apply a percentage change, set to a specific value).
5.  **Granular Role-Based Access Control:** Using OpenZeppelin's `AccessControl` and defining specific roles (`EVENT_PROCESSOR_ROLE`, `ORACLE_ROLE`) for the sensitive trait-modification functions ensures that only designated, trusted entities can trigger these updates. The `DEFAULT_ADMIN_ROLE` manages these other roles. This is crucial because trait updates represent significant state changes driven by external information.
6.  **Separation of Concerns:** The contract separates trait definition, rule definition, and the triggering of evolution, making the system more modular and configurable via governance.
7.  **Pausable & ReentrancyGuard:** Standard but necessary advanced security patterns for managing contract state and handling Ether withdrawals safely.

This contract goes beyond a simple ERC721 by adding a robust layer for dynamic state changes tied to external events and behavior, managed through configurable rules and fine-grained access control. It represents a pattern useful for decentralized games, reputation systems, verifiable credential-linked assets, or interactive digital collectibles.