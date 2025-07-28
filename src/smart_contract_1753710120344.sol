This smart contract, `ChronoPlexAssets`, introduces the concept of **Adaptive Digital Entities (ADEs)**. Unlike static NFTs or fungible tokens, ADEs are designed to have programmable "life cycles" and autonomous behaviors. They can evolve through different "phases" based on on-chain conditions (time, oracle data, interaction with other protocols) and can even perform pre-defined actions on behalf of their owners or autonomously, managing their own internal "resource pools" and having a "vitality" score that can decay over time.

It aims to be unique by combining:
1.  **Dynamic State Evolution:** Entities are not static; they transition through phases based on programmable conditions.
2.  **Autonomous Cross-Protocol Interaction:** Entities can execute actions on *other* whitelisted DeFi protocols (e.g., stake tokens, provide liquidity) based on their internal logic and conditions.
3.  **Internal Resource Management:** Entities can "hold" and "spend" ERC-20 tokens, enabling them to fund their own autonomous actions.
4.  **Vitality/Decay Mechanic:** A novel concept where an entity's "health" or "effectiveness" can degrade over time if not "rejuvenated" or interacted with, adding a strategic dimension.
5.  **Blueprint System:** New entities are instantiated from pre-defined "blueprints," allowing for templated creation and evolution paths.
6.  **Decentralized Oracle Integration:** Heavily relies on external data to trigger phase transitions and autonomous actions.
7.  **Upgradeable Architecture:** Utilizes the UUPS proxy pattern for future-proofing and adaptability.

---

## ChronoPlexAssets: Adaptive Digital Entities (ADEs) Contract

### Outline

1.  **Project Description:** Overview of Adaptive Digital Entities (ADEs) and their core capabilities.
2.  **Core Concepts:**
    *   **Entity:** An ERC-721 NFT with an associated state, evolution path, and autonomous logic.
    *   **Blueprint:** A template defining an entity's initial properties, evolution path, and potential autonomous actions.
    *   **Phase:** A distinct state an entity can be in, with specific conditions for transitioning to the next phase.
    *   **Phase Condition:** Criteria (time, oracle data, external contract state) that must be met for an entity to move to the next phase.
    *   **Autonomous Action:** A pre-programmed operation an entity can perform on an external whitelisted protocol (e.g., stake, swap, vote).
    *   **Resource Pool:** An internal vault within the contract where an entity can hold ERC-20 tokens for autonomous actions.
    *   **Vitality Score:** A dynamic metric representing an entity's "health" or "effectiveness," which can decay over time.
    *   **Protocol Hook:** A whitelisted external contract address an entity is authorized to interact with.
3.  **Contract Structure:**
    *   ERC-721 Compliant NFT.
    *   Pausable and Ownable for control.
    *   UUPS Upgradeable for future flexibility.
    *   Custom Errors.
    *   Events for transparent state changes.
    *   Data Structures for Entities, Blueprints, Phases, and Actions.
4.  **Function Summary (25+ Functions):**

### Function Summary

**I. Core Entity Management (ERC-721 Compliant)**
1.  `_mintEntity(address to, uint256 blueprintId)`: Internal helper to mint a new ADE.
2.  `createEntityFromBlueprint(address to, uint256 blueprintId, string memory tokenURI_)`: Mints a new ADE instance based on a pre-defined blueprint.
3.  `transferFrom(address from, address to, uint256 tokenId)`: Standard ERC-721 transfer.
4.  `approve(address to, uint256 tokenId)`: Standard ERC-721 approval.
5.  `setApprovalForAll(address operator, bool approved)`: Standard ERC-721 approval for all tokens.
6.  `getEntityDetails(uint256 tokenId)`: Retrieves all core details of a specific ADE.
7.  `getEntityPhase(uint256 tokenId)`: Returns the current phase of an ADE.
8.  `rejuvenateEntity(uint256 tokenId, uint256 boostAmount)`: Boosts an entity's vitality score, preventing decay or accelerating recovery.

**II. Blueprint & Evolution Path Management**
9.  `createEntityBlueprint(string memory name, string memory description, PhaseCondition[] memory initialEvolutionPath)`: Defines a new blueprint for creating ADEs, including its initial evolution path.
10. `addPhaseToBlueprint(uint256 blueprintId, PhaseCondition memory newPhaseCondition)`: Extends an existing blueprint's evolution path by adding a new phase.
11. `updateBlueprintPhaseCondition(uint256 blueprintId, uint256 phaseIndex, PhaseCondition memory updatedCondition)`: Modifies the transition conditions for a specific phase within a blueprint.
12. `getBlueprintDetails(uint256 blueprintId)`: Retrieves the full details of an entity blueprint.
13. `addAutonomousActionToBlueprint(uint256 blueprintId, AutonomousAction memory action)`: Attaches a new autonomous action definition to a blueprint, detailing what actions entities of this type can perform.
14. `removeAutonomousActionFromBlueprint(uint256 blueprintId, bytes4 actionId)`: Removes a defined autonomous action from a blueprint.

**III. Dynamic State & Autonomous Action Execution**
15. `checkAndAdvanceEntityPhase(uint256 tokenId)`: Allows anyone to attempt to advance an entity to its next phase if conditions are met.
16. `triggerAutonomousAction(uint256 tokenId, bytes4 actionId, bytes memory callData)`: Initiates an autonomous action defined for the entity, using its internal resources. Can be called by owner or external keeper.
17. `setEntityResourceAllowance(uint256 tokenId, address tokenAddress, uint256 amount)`: Allows the entity owner to set an allowance for the entity to spend its *own* internal resources on autonomous actions.
18. `depositResourceToEntity(uint256 tokenId, address tokenAddress, uint256 amount)`: Allows an owner or approved sender to deposit ERC-20 tokens into an entity's internal resource pool.
19. `withdrawResourceFromEntity(uint256 tokenId, address tokenAddress, uint256 amount)`: Allows the entity owner to withdraw ERC-20 tokens from an entity's internal resource pool.
20. `getEntityResourceBalance(uint256 tokenId, address tokenAddress)`: Checks the balance of a specific ERC-20 token within an entity's resource pool.
21. `registerProtocolHook(address protocolAddress, bool isWhitelisted)`: Whitelists or blacklists external smart contract addresses that ADEs can interact with via autonomous actions.

**IV. Oracle & External Data Integration**
22. `setOracleAddress(address oracleAddress)`: Sets the address of the trusted oracle contract for fetching external data.
23. `setOracleDataFeed(string memory key, bytes32 value)`: (Conceptual) Simulates an oracle feed update, necessary for `PhaseConditionType.OracleValue`. In a real system, this would be a Chainlink VRF/Keepers callback.

**V. Maintenance & Governance**
24. `setDecayRate(uint256 newDecayRate)`: Sets the global decay rate for entity vitality.
25. `pause()`: Pauses core contract functionalities (admin only).
26. `unpause()`: Unpauses core contract functionalities (admin only).

**VI. Upgradeability (UUPS)**
27. `_authorizeUpgrade(address newImplementation)`: Internal function for UUPS, ensuring only authorized addresses can trigger upgrades.

---
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/// @title ChronoPlexAssets: Adaptive Digital Entities (ADEs)
/// @author YourName (inspired by advanced concepts)
/// @notice This contract introduces a novel concept of Adaptive Digital Entities (ADEs)
///         which are dynamic NFTs capable of evolving through defined phases and
///         performing autonomous actions on other whitelisted protocols.
///         They manage their own internal resource pools and possess a vitality score
///         that can decay over time.
/// @dev This is a conceptual contract designed to showcase advanced Solidity patterns and
///      complex logic. It integrates dynamic state management, cross-protocol interaction,
///      oracle dependency, and a unique vitality/decay mechanic.

contract ChronoPlexAssets is ERC721, Ownable, Pausable, UUPSUpgradeable {
    using Counters for Counters.Counter;
    using Address for address; // For safe token transfers

    // --- State Variables ---

    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _blueprintIdCounter;

    // Mapping from tokenId to Entity data
    mapping(uint256 => Entity) public entities;

    // Mapping from blueprintId to Blueprint data
    mapping(uint256 => Blueprint) public blueprints;

    // Mapping from (tokenId => tokenAddress => balance) for internal entity resource pools
    mapping(uint256 => mapping(address => uint256)) public entityResourcePools;

    // Mapping from (tokenId => tokenAddress => allowance) for entity to spend its own resources
    mapping(uint256 => mapping(address => uint256)) public entityResourceAllowances;

    // Whitelisted external protocols for autonomous actions
    mapping(address => bool) public whitelistedProtocols;

    // Address of a trusted oracle contract (e.g., Chainlink aggregator, custom oracle)
    address public oracleAddress;

    // Placeholder for oracle data. In a real system, this would be queried from `oracleAddress`.
    mapping(string => bytes32) public mockOracleData;

    // Global decay rate for entity vitality (per unit of time, e.g., per day)
    uint256 public decayRate = 1; // 1 unit of vitality per 'decayInterval'

    // The interval (in seconds) after which decay is applied
    uint256 public decayInterval = 1 days;

    // --- Data Structures ---

    enum PhaseConditionType {
        TimeElapsed,    // Entity must have existed for X seconds
        OracleValue,    // A specific oracle value must be met (e.g., price above X)
        ExternalContractState, // A boolean state in another contract must be true
        TokenBalanceThreshold // Entity's internal token balance must be above threshold
    }

    struct PhaseCondition {
        PhaseConditionType conditionType;
        uint256 value;          // Time in seconds, oracle threshold, token amount
        string oracleKey;       // Key for oracle data (if type is OracleValue)
        address contractAddress; // Address of external contract (if type is ExternalContractState/TokenBalanceThreshold)
        bytes4 functionSelector; // Function to call on external contract (if type is ExternalContractState)
        bool expectedBool;      // Expected boolean result (if type is ExternalContractState)
        address tokenAddress;   // Token address for TokenBalanceThreshold
    }

    struct AutonomousAction {
        bytes4 actionId;        // Unique identifier for the action (e.g., bytes4(keccak256("stake()")))
        string name;            // Human-readable name (e.g., "Stake ETH")
        address targetProtocol; // The contract address of the protocol to interact with
        bytes callDataTemplate; // Calldata template for the external call (e.g., stake function, amount placeholder)
        address requiredToken;  // Token required for the action (e.g., WETH for staking)
        uint256 requiredAmount; // Amount of requiredToken needed
        bool requireOracleData; // Does this action require specific oracle data to be true?
        string oracleKey;       // Key for oracle data (if requireOracleData)
        bytes32 oracleThreshold; // Oracle data threshold
    }

    struct Entity {
        uint256 id;
        uint256 blueprintId;
        uint256 genesisTime;
        uint256 currentPhaseIndex;
        uint256 lastDecayCalculationTime;
        uint256 vitality; // Represents overall 'health' or 'effectiveness', decays over time
    }

    struct Blueprint {
        string name;
        string description;
        PhaseCondition[] evolutionPath;
        // Mapping from actionId to AutonomousAction for quick lookup
        mapping(bytes4 => AutonomousAction) autonomousActions;
        bytes4[] registeredActionIds; // To iterate over actions
    }

    // --- Events ---

    event EntityCreated(uint256 indexed tokenId, address indexed owner, uint256 blueprintId, uint256 genesisTime);
    event EntityPhaseAdvanced(uint256 indexed tokenId, uint256 oldPhaseIndex, uint256 newPhaseIndex);
    event BlueprintCreated(uint256 indexed blueprintId, string name);
    event AutonomousActionDefined(uint256 indexed blueprintId, bytes4 indexed actionId, string name);
    event AutonomousActionExecuted(uint256 indexed tokenId, bytes4 indexed actionId, address targetProtocol, bool success);
    event EntityResourceDeposited(uint256 indexed tokenId, address indexed tokenAddress, uint256 amount);
    event EntityResourceWithdrawn(uint256 indexed tokenId, address indexed tokenAddress, uint256 amount);
    event EntityResourceAllowanceSet(uint256 indexed tokenId, address indexed tokenAddress, uint256 amount);
    event EntityVitalityBoosted(uint256 indexed tokenId, uint256 oldVitality, uint256 newVitality, uint256 boostAmount);
    event ProtocolHookRegistered(address indexed protocolAddress, bool isWhitelisted);
    event OracleAddressSet(address indexed oldAddress, address indexed newAddress);
    event DecayRateSet(uint256 oldRate, uint256 newRate);

    // --- Custom Errors ---

    error EntityDoesNotExist(uint256 tokenId);
    error BlueprintDoesNotExist(uint256 blueprintId);
    error InvalidPhaseTransition(uint256 tokenId, string reason);
    error ActionDoesNotExist(bytes4 actionId);
    error NotEnoughResources(uint256 tokenId, address tokenAddress, uint256 required, uint256 available);
    error InsufficientAllowance(uint256 tokenId, address tokenAddress, uint256 required, uint256 allowance);
    error ProtocolNotWhitelisted(address protocolAddress);
    error CallFailed(address target, bytes data);
    error InvalidOracleAddress();
    error OracleDataNotMet(string key);
    error VitalityTooLow(uint256 tokenId, uint256 currentVitality);

    // --- Constructor & Initializer ---

    /// @dev Initializes the contract as an ERC721 token, Ownable, Pausable, and UUPS upgradeable.
    /// @param name_ The name of the NFT collection.
    /// @param symbol_ The symbol of the NFT collection.
    function initialize(string memory name_, string memory symbol_) public initializer {
        __ERC721_init(name_, symbol_);
        __Ownable_init(msg.sender);
        __Pausable_init();
        __UUPSUpgradeable_init();
    }

    // --- Modifiers ---

    modifier onlyEntityOwner(uint256 tokenId) {
        if (ownerOf(tokenId) != msg.sender) {
            revert OwnableUnauthorizedAccount(msg.sender); // Reusing Ownable error
        }
        _;
    }

    modifier entityExists(uint256 tokenId) {
        if (_exists(tokenId) == false) {
            revert EntityDoesNotExist(tokenId);
        }
        _;
    }

    modifier blueprintExists(uint256 blueprintId) {
        if (bytes(blueprints[blueprintId].name).length == 0) { // Check if name is set (indicates existence)
            revert BlueprintDoesNotExist(blueprintId);
        }
        _;
    }

    // --- Core Entity Management (ERC-721 Compliant) ---

    /// @dev Internal helper to mint a new ADE.
    /// @param to The address to mint the entity to.
    /// @param blueprintId The ID of the blueprint to use.
    function _mintEntity(address to, uint256 blueprintId) internal returns (uint256) {
        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();

        Entity storage newEntity = entities[newItemId];
        newEntity.id = newItemId;
        newEntity.blueprintId = blueprintId;
        newEntity.genesisTime = block.timestamp;
        newEntity.currentPhaseIndex = 0; // Start at the first phase
        newEntity.lastDecayCalculationTime = block.timestamp;
        newEntity.vitality = 100; // Initial vitality

        _safeMint(to, newItemId);
        emit EntityCreated(newItemId, to, blueprintId, block.timestamp);
        return newItemId;
    }

    /// @notice Mints a new Adaptive Digital Entity (ADE) instance based on a pre-defined blueprint.
    /// @dev Requires the specified blueprint to exist.
    /// @param to The address to mint the entity to.
    /// @param blueprintId The ID of the blueprint to use for creation.
    /// @param tokenURI_ The URI for the entity's metadata.
    /// @return The ID of the newly minted entity.
    function createEntityFromBlueprint(
        address to,
        uint256 blueprintId,
        string memory tokenURI_
    ) public whenNotPaused blueprintExists(blueprintId) returns (uint256) {
        uint256 tokenId = _mintEntity(to, blueprintId);
        _setTokenURI(tokenId, tokenURI_);
        return tokenId;
    }

    /// @notice Transfers ownership of an ADE. Standard ERC-721 function.
    function transferFrom(address from, address to, uint256 tokenId) public override(ERC721, IERC721) whenNotPaused {
        super.transferFrom(from, to, tokenId);
        // On transfer, decay calculation might be triggered if significant time passed
        // For simplicity here, we assume decay is triggered by specific actions or keepers.
        // A more complex system might call _calculateDecay here.
    }

    /// @notice Approves an address to manage an ADE. Standard ERC-721 function.
    function approve(address to, uint256 tokenId) public override(ERC721, IERC721) whenNotPaused {
        super.approve(to, tokenId);
    }

    /// @notice Sets approval for an operator to manage all ADEs of the sender. Standard ERC-721 function.
    function setApprovalForAll(address operator, bool approved) public override(ERC721, IERC721) whenNotPaused {
        super.setApprovalForAll(operator, approved);
    }

    /// @notice Retrieves all core details of a specific ADE.
    /// @param tokenId The ID of the entity.
    /// @return A tuple containing the entity's ID, blueprint ID, genesis time, current phase index, last decay time, and vitality.
    function getEntityDetails(uint256 tokenId) public view entityExists(tokenId) returns (
        uint256 id,
        uint256 blueprintId,
        uint256 genesisTime,
        uint256 currentPhaseIndex,
        uint256 lastDecayCalculationTime,
        uint256 vitality
    ) {
        Entity storage ent = entities[tokenId];
        return (
            ent.id,
            ent.blueprintId,
            ent.genesisTime,
            ent.currentPhaseIndex,
            ent.lastDecayCalculationTime,
            ent.vitality
        );
    }

    /// @notice Returns the current phase index of an ADE.
    /// @param tokenId The ID of the entity.
    /// @return The index of the entity's current phase within its blueprint's evolution path.
    function getEntityPhase(uint256 tokenId) public view entityExists(tokenId) returns (uint256) {
        return entities[tokenId].currentPhaseIndex;
    }

    /// @notice Rejuvenates an entity's vitality score, preventing decay or accelerating recovery.
    /// @dev Only the entity owner can call this.
    /// @param tokenId The ID of the entity to rejuvenate.
    /// @param boostAmount The amount to boost the vitality by.
    function rejuvenateEntity(uint256 tokenId, uint256 boostAmount)
        public
        whenNotPaused
        onlyEntityOwner(tokenId)
        entityExists(tokenId)
    {
        Entity storage ent = entities[tokenId];
        uint256 oldVitality = ent.vitality;
        _calculateDecay(tokenId); // Apply any pending decay first
        ent.vitality += boostAmount;
        // Optionally cap vitality at a max value, e.g., 100
        if (ent.vitality > 100) {
            ent.vitality = 100;
        }
        emit EntityVitalityBoosted(tokenId, oldVitality, ent.vitality, boostAmount);
    }

    // --- Blueprint & Evolution Path Management ---

    /// @notice Defines a new blueprint for creating ADEs, including its initial evolution path.
    /// @dev Only the contract owner can create blueprints.
    /// @param name_ The name of the blueprint.
    /// @param description_ A description of the blueprint.
    /// @param initialEvolutionPath An array of PhaseCondition structs defining the initial evolution phases.
    /// @return The ID of the newly created blueprint.
    function createEntityBlueprint(
        string memory name_,
        string memory description_,
        PhaseCondition[] memory initialEvolutionPath
    ) public onlyOwner whenNotPaused returns (uint256) {
        _blueprintIdCounter.increment();
        uint256 newBlueprintId = _blueprintIdCounter.current();

        Blueprint storage newBlueprint = blueprints[newBlueprintId];
        newBlueprint.name = name_;
        newBlueprint.description = description_;
        newBlueprint.evolutionPath = initialEvolutionPath;

        emit BlueprintCreated(newBlueprintId, name_);
        return newBlueprintId;
    }

    /// @notice Extends an existing blueprint's evolution path by adding a new phase.
    /// @dev Only the contract owner can modify blueprints.
    /// @param blueprintId The ID of the blueprint to modify.
    /// @param newPhaseCondition The new PhaseCondition struct to add.
    function addPhaseToBlueprint(uint256 blueprintId, PhaseCondition memory newPhaseCondition)
        public
        onlyOwner
        whenNotPaused
        blueprintExists(blueprintId)
    {
        blueprints[blueprintId].evolutionPath.push(newPhaseCondition);
        // Event for blueprint update if needed
    }

    /// @notice Modifies the transition conditions for a specific phase within a blueprint.
    /// @dev Only the contract owner can modify blueprints. Requires the phase index to be valid.
    /// @param blueprintId The ID of the blueprint to modify.
    /// @param phaseIndex The index of the phase to update.
    /// @param updatedCondition The new PhaseCondition struct for the specified phase.
    function updateBlueprintPhaseCondition(
        uint256 blueprintId,
        uint256 phaseIndex,
        PhaseCondition memory updatedCondition
    ) public onlyOwner whenNotPaused blueprintExists(blueprintId) {
        require(phaseIndex < blueprints[blueprintId].evolutionPath.length, "ChronoPlex: Invalid phase index");
        blueprints[blueprintId].evolutionPath[phaseIndex] = updatedCondition;
        // Event for blueprint update if needed
    }

    /// @notice Retrieves the full details of an entity blueprint.
    /// @param blueprintId The ID of the blueprint.
    /// @return A tuple containing the blueprint's name, description, and evolution path.
    function getBlueprintDetails(uint256 blueprintId) public view blueprintExists(blueprintId) returns (
        string memory name,
        string memory description,
        PhaseCondition[] memory evolutionPath
    ) {
        Blueprint storage bp = blueprints[blueprintId];
        return (bp.name, bp.description, bp.evolutionPath);
    }

    /// @notice Attaches a new autonomous action definition to a blueprint.
    /// @dev Only the contract owner can define actions for blueprints.
    /// @param blueprintId The ID of the blueprint.
    /// @param action The AutonomousAction struct to add.
    function addAutonomousActionToBlueprint(uint256 blueprintId, AutonomousAction memory action)
        public
        onlyOwner
        whenNotPaused
        blueprintExists(blueprintId)
    {
        Blueprint storage bp = blueprints[blueprintId];
        // Ensure actionId is unique for this blueprint
        for (uint256 i = 0; i < bp.registeredActionIds.length; i++) {
            if (bp.registeredActionIds[i] == action.actionId) {
                // Update existing action
                bp.autonomousActions[action.actionId] = action;
                emit AutonomousActionDefined(blueprintId, action.actionId, action.name);
                return;
            }
        }
        bp.autonomousActions[action.actionId] = action;
        bp.registeredActionIds.push(action.actionId);
        emit AutonomousActionDefined(blueprintId, action.actionId, action.name);
    }

    /// @notice Removes a defined autonomous action from a blueprint.
    /// @dev Only the contract owner can remove actions.
    /// @param blueprintId The ID of the blueprint.
    /// @param actionId The ID of the action to remove.
    function removeAutonomousActionFromBlueprint(uint256 blueprintId, bytes4 actionId)
        public
        onlyOwner
        whenNotPaused
        blueprintExists(blueprintId)
    {
        Blueprint storage bp = blueprints[blueprintId];
        bool found = false;
        for (uint256 i = 0; i < bp.registeredActionIds.length; i++) {
            if (bp.registeredActionIds[i] == actionId) {
                // Shift elements to fill the gap
                bp.registeredActionIds[i] = bp.registeredActionIds[bp.registeredActionIds.length - 1];
                bp.registeredActionIds.pop();
                delete bp.autonomousActions[actionId];
                found = true;
                break;
            }
        }
        require(found, "ChronoPlex: Action not found for blueprint");
        // Event for action removal if needed
    }

    // --- Dynamic State & Autonomous Action Execution ---

    /// @notice Allows anyone to attempt to advance an entity to its next phase if conditions are met.
    /// @dev Triggers the next phase based on predefined conditions.
    /// @param tokenId The ID of the entity to check and advance.
    function checkAndAdvanceEntityPhase(uint256 tokenId) public whenNotPaused entityExists(tokenId) {
        Entity storage ent = entities[tokenId];
        Blueprint storage bp = blueprints[ent.blueprintId];

        // Ensure vitality is sufficient for phase advancement (conceptual)
        _calculateDecay(tokenId);
        require(ent.vitality > 0, VitalityTooLow(tokenId, ent.vitality));

        uint256 nextPhaseIndex = ent.currentPhaseIndex + 1;
        if (nextPhaseIndex >= bp.evolutionPath.length) {
            revert InvalidPhaseTransition(tokenId, "No more phases in evolution path");
        }

        PhaseCondition storage nextPhaseCondition = bp.evolutionPath[nextPhaseIndex];

        bool conditionMet = false;
        if (nextPhaseCondition.conditionType == PhaseConditionType.TimeElapsed) {
            conditionMet = (block.timestamp - ent.genesisTime) >= nextPhaseCondition.value;
        } else if (nextPhaseCondition.conditionType == PhaseConditionType.OracleValue) {
            require(oracleAddress != address(0), InvalidOracleAddress());
            bytes32 oracleVal = mockOracleData[nextPhaseCondition.oracleKey]; // In real, query oracleAddress
            conditionMet = oracleVal >= bytes32(nextPhaseCondition.value); // Example: oracle value >= threshold
        } else if (nextPhaseCondition.conditionType == PhaseConditionType.ExternalContractState) {
            (bool success, bytes memory retdata) = nextPhaseCondition.contractAddress.staticcall(
                abi.encodeWithSelector(nextPhaseCondition.functionSelector)
            );
            require(success, "ChronoPlex: External contract call failed");
            bool externalState = abi.decode(retdata, (bool));
            conditionMet = externalState == nextPhaseCondition.expectedBool;
        } else if (nextPhaseCondition.conditionType == PhaseConditionType.TokenBalanceThreshold) {
            uint256 currentBalance = entityResourcePools[tokenId][nextPhaseCondition.tokenAddress];
            conditionMet = currentBalance >= nextPhaseCondition.value;
        }

        require(conditionMet, InvalidPhaseTransition(tokenId, "Next phase conditions not met"));

        uint256 oldPhaseIndex = ent.currentPhaseIndex;
        ent.currentPhaseIndex = nextPhaseIndex;
        emit EntityPhaseAdvanced(tokenId, oldPhaseIndex, nextPhaseIndex);
    }

    /// @notice Initiates an autonomous action defined for the entity, using its internal resources.
    /// @dev Can be called by the entity owner or an authorized third party (e.g., a keeper bot).
    ///      Checks entity vitality, resource availability, and whitelisted protocols.
    /// @param tokenId The ID of the entity to perform the action.
    /// @param actionId The ID of the autonomous action to trigger.
    /// @param callData The specific calldata to pass to the target protocol (e.g., includes amounts).
    function triggerAutonomousAction(uint256 tokenId, bytes4 actionId, bytes memory callData)
        public
        whenNotPaused
        entityExists(tokenId)
    {
        // Allow owner or approved to trigger
        require(msg.sender == ownerOf(tokenId) || getApproved(tokenId) == msg.sender || isApprovedForAll(ownerOf(tokenId), msg.sender), "ChronoPlex: Not authorized to trigger action");

        Entity storage ent = entities[tokenId];
        Blueprint storage bp = blueprints[ent.blueprintId];

        // Apply decay before action
        _calculateDecay(tokenId);
        require(ent.vitality > 0, VitalityTooLow(tokenId, ent.vitality));

        AutonomousAction storage action = bp.autonomousActions[actionId];
        if (bytes(action.name).length == 0) { // Check if action exists
            revert ActionDoesNotExist(actionId);
        }

        require(whitelistedProtocols[action.targetProtocol], ProtocolNotWhitelisted(action.targetProtocol));

        // Check oracle data if required by action
        if (action.requireOracleData) {
            require(oracleAddress != address(0), InvalidOracleAddress());
            bytes32 oracleVal = mockOracleData[action.oracleKey]; // In real, query oracleAddress
            require(oracleVal >= action.oracleThreshold, OracleDataNotMet(action.oracleKey));
        }

        // Check and deduct required resources from entity's internal pool
        if (action.requiredToken != address(0) && action.requiredAmount > 0) {
            uint256 currentBalance = entityResourcePools[tokenId][action.requiredToken];
            if (currentBalance < action.requiredAmount) {
                revert NotEnoughResources(tokenId, action.requiredToken, action.requiredAmount, currentBalance);
            }
            uint256 currentAllowance = entityResourceAllowances[tokenId][action.requiredToken];
            if (currentAllowance < action.requiredAmount) {
                revert InsufficientAllowance(tokenId, action.requiredToken, action.requiredAmount, currentAllowance);
            }

            // Transfer tokens to the target protocol
            // IMPORTANT: This assumes the target protocol's function expects tokens to be sent by the *caller*
            // via a separate approve/transferFrom or directly via `transfer`
            // For complex interactions like `swapExactTokensForETH`, the entity might need to approve
            // the router, and then the router pulls from the entity's address.
            // This example uses a simplified `transfer` for demonstration.
            // In a real system, you'd need a more robust multi-call or approval system.

            entityResourcePools[tokenId][action.requiredToken] -= action.requiredAmount;
            entityResourceAllowances[tokenId][action.requiredToken] -= action.requiredAmount;

            // Perform the external call
            // Using `call` for arbitrary external interaction, but careful re-entrancy checks needed.
            // This conceptual example omits `nonReentrant` or specific re-entrancy guards for brevity,
            // but they would be CRITICAL in a production environment.
            bool success = IERC20(action.requiredToken).transfer(action.targetProtocol, action.requiredAmount);
            require(success, "ChronoPlex: Token transfer to protocol failed");
        }

        // Execute the autonomous action
        (bool success, ) = action.targetProtocol.call(callData);
        if (!success) {
            revert CallFailed(action.targetProtocol, callData);
        }

        // Reduce vitality after action (conceptual cost)
        ent.vitality -= 1; // Example: 1 vitality point per action

        emit AutonomousActionExecuted(tokenId, actionId, action.targetProtocol, success);
    }

    /// @notice Allows the entity owner to set an allowance for the entity to spend its *own* internal resources on autonomous actions.
    /// @dev This is crucial for autonomous actions to spend tokens held by the entity itself.
    /// @param tokenId The ID of the entity.
    /// @param tokenAddress The address of the ERC-20 token.
    /// @param amount The amount the entity is allowed to spend.
    function setEntityResourceAllowance(uint256 tokenId, address tokenAddress, uint256 amount)
        public
        whenNotPaused
        onlyEntityOwner(tokenId)
        entityExists(tokenId)
    {
        entityResourceAllowances[tokenId][tokenAddress] = amount;
        emit EntityResourceAllowanceSet(tokenId, tokenAddress, amount);
    }

    /// @notice Allows an owner or approved sender to deposit ERC-20 tokens into an entity's internal resource pool.
    /// @dev The tokens are transferred from `msg.sender` to the contract, and recorded as belonging to the entity.
    /// @param tokenId The ID of the entity to deposit into.
    /// @param tokenAddress The address of the ERC-20 token.
    /// @param amount The amount of tokens to deposit.
    function depositResourceToEntity(uint256 tokenId, address tokenAddress, uint256 amount)
        public
        whenNotPaused
        entityExists(tokenId)
    {
        // Only owner or approved can deposit
        require(msg.sender == ownerOf(tokenId) || getApproved(tokenId) == msg.sender || isApprovedForAll(ownerOf(tokenId), msg.sender), "ChronoPlex: Not authorized to deposit resources");

        IERC20(tokenAddress).transferFrom(msg.sender, address(this), amount);
        entityResourcePools[tokenId][tokenAddress] += amount;
        emit EntityResourceDeposited(tokenId, tokenAddress, amount);
    }

    /// @notice Allows the entity owner to withdraw ERC-20 tokens from an entity's internal resource pool.
    /// @dev Tokens are transferred from the contract back to the owner.
    /// @param tokenId The ID of the entity to withdraw from.
    /// @param tokenAddress The address of the ERC-20 token.
    /// @param amount The amount of tokens to withdraw.
    function withdrawResourceFromEntity(uint256 tokenId, address tokenAddress, uint256 amount)
        public
        whenNotPaused
        onlyEntityOwner(tokenId)
        entityExists(tokenId)
    {
        require(entityResourcePools[tokenId][tokenAddress] >= amount, NotEnoughResources(tokenId, tokenAddress, amount, entityResourcePools[tokenId][tokenAddress]));
        entityResourcePools[tokenId][tokenAddress] -= amount;
        IERC20(tokenAddress).transfer(msg.sender, amount);
        emit EntityResourceWithdrawn(tokenId, tokenAddress, amount);
    }

    /// @notice Checks the balance of a specific ERC-20 token within an entity's resource pool.
    /// @param tokenId The ID of the entity.
    /// @param tokenAddress The address of the ERC-20 token.
    /// @return The amount of the specified token held by the entity.
    function getEntityResourceBalance(uint256 tokenId, address tokenAddress) public view entityExists(tokenId) returns (uint256) {
        return entityResourcePools[tokenId][tokenAddress];
    }

    /// @notice Whitelists or blacklists external smart contract addresses that ADEs can interact with via autonomous actions.
    /// @dev Only the contract owner can manage protocol hooks.
    /// @param protocolAddress The address of the external protocol.
    /// @param isWhitelisted True to whitelist, false to blacklist.
    function registerProtocolHook(address protocolAddress, bool isWhitelisted) public onlyOwner {
        whitelistedProtocols[protocolAddress] = isWhitelisted;
        emit ProtocolHookRegistered(protocolAddress, isWhitelisted);
    }

    // --- Oracle & External Data Integration ---

    /// @notice Sets the address of the trusted oracle contract for fetching external data.
    /// @dev Only the contract owner can set the oracle address.
    /// @param newOracleAddress The address of the oracle.
    function setOracleAddress(address newOracleAddress) public onlyOwner {
        require(newOracleAddress != address(0), "ChronoPlex: Oracle address cannot be zero");
        emit OracleAddressSet(oracleAddress, newOracleAddress);
        oracleAddress = newOracleAddress;
    }

    /// @notice (Conceptual) Simulates an oracle feed update.
    /// @dev In a real system, this would be a Chainlink VRF/Keepers callback or a dedicated oracle update function.
    ///      For demonstration purposes, this allows the owner to set mock oracle data.
    /// @param key A string key identifying the data feed (e.g., "ETH/USD").
    /// @param value The bytes32 value of the oracle data.
    function setOracleDataFeed(string memory key, bytes32 value) public onlyOwner {
        mockOracleData[key] = value;
        // No explicit event for mock data, but could add one.
    }

    // --- Maintenance & Governance ---

    /// @notice Sets the global decay rate for entity vitality.
    /// @dev Only the contract owner can adjust the decay rate.
    /// @param newDecayRate_ The new decay rate (e.g., units per day).
    function setDecayRate(uint256 newDecayRate_) public onlyOwner {
        emit DecayRateSet(decayRate, newDecayRate_);
        decayRate = newDecayRate_;
    }

    /// @notice Pauses core contract functionalities in case of emergency.
    /// @dev Only the contract owner can pause. Inherited from Pausable.
    function pause() public onlyOwner {
        _pause();
    }

    /// @notice Unpauses core contract functionalities.
    /// @dev Only the contract owner can unpause. Inherited from Pausable.
    function unpause() public onlyOwner {
        _unpause();
    }

    // --- Internal Logic ---

    /// @dev Calculates and applies vitality decay to an entity.
    ///      This is called internally before any action or phase advancement.
    /// @param tokenId The ID of the entity to calculate decay for.
    function _calculateDecay(uint256 tokenId) internal {
        Entity storage ent = entities[tokenId];
        uint256 timePassed = block.timestamp - ent.lastDecayCalculationTime;

        if (timePassed >= decayInterval) {
            uint256 decayPeriods = timePassed / decayInterval;
            uint256 totalDecay = decayPeriods * decayRate;

            if (ent.vitality > totalDecay) {
                ent.vitality -= totalDecay;
            } else {
                ent.vitality = 0;
            }
            ent.lastDecayCalculationTime = block.timestamp; // Or block.timestamp - (timePassed % decayInterval) for precision
        }
    }

    // --- Upgradeability (UUPS) ---

    /// @dev Authorizes upgrade of the contract implementation.
    ///      Only the owner of this proxy contract can authorize an upgrade.
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
```