Okay, let's create a Solidity smart contract that embodies some advanced, creative, and trendy concepts beyond typical open-source patterns.

The concept will be a "Dynamic Cybernetic Ecosystem" where users own unique "Entities" (NFTs) that possess mutable on-chain attributes. These entities can interact, evolve, consume resources (represented by another token), and synthesize new entities based on their attributes and state. It combines elements of dynamic NFTs, resource management, simple on-chain simulation, and potential future integration points (like oracles for environmental factors or AI).

**Core Concepts:**

1.  **Dynamic NFTs (Entities):** ERC-721 tokens with on-chain attributes that can change over time and through interactions.
2.  **Resource Consumption:** Entities require a specific ERC-20 token (`CyberEnergy`) to perform complex actions.
3.  **On-Chain State & Evolution:** Entities have internal states (`EntityStatus`) and attributes that can evolve (`performAdaptationCycle`) or degrade over time.
4.  **Synthesis (On-Chain Procreation/Crafting):** Combine two entities and resources to potentially create a new entity with combined/mutated attributes.
5.  **Passive Mechanics:** Entities can accumulate internal points (`mutationPoints`) while active.
6.  **Access Control & Pausability:** Basic administrative controls.

**Outline:**

1.  **Contract Definition:** Inherits ERC721, AccessControl, Pausable, ReentrancyGuard.
2.  **Interfaces:** Define interface for the `CyberEnergy` ERC-20 token.
3.  **State Variables:** Store ERC721 data, entity attributes, status, costs, parameters, global state.
4.  **Structs & Enums:** Define the structure for `EntityAttributes` and the `EntityStatus` enum.
5.  **Events:** Announce key state changes (Mint, StatusChange, AttributeUpdate, Synthesis, Adaptation, YieldClaimed, ParameterUpdate).
6.  **Modifiers:** Use inherited `whenNotPaused`, `nonReentrant`, `onlyRole`.
7.  **Constructor:** Initialize ERC721, AccessControl roles, set initial parameters.
8.  **ERC721 Standard Overrides:** `tokenURI`, `supportsInterface`.
9.  **Access Control & Pausability:** Standard functions.
10. **Core Entity Management:**
    *   `mintGenesisEntity`: Initial creation of entities by admin.
    *   `getEntityAttributes`: Read an entity's dynamic attributes.
    *   `getEntityStatus`: Read an entity's current status.
    *   `activateEntity`: Change entity status to Active, requires CyberEnergy cost, starts passive yield accrual.
    *   `deactivateEntity`: Change entity status to Dormant, stops passive yield accrual.
    *   `claimPassiveYield`: Harvest accumulated `mutationPoints` from an active entity.
    *   `performAdaptationCycle`: Use accumulated `mutationPoints` to attempt to improve `adaptationScore` or other attributes. Involves chance/logic.
11. **Synthesis Mechanism:**
    *   `attemptSynthesis`: Burn two parent entities (owned by caller), consume CyberEnergy, combine attributes with a chance of success/mutation, mint a new child entity.
12. **Resource & Interaction:**
    *   `synthesizeResource`: An active entity consumes CyberEnergy to produce something else (e.g., gain more `mutationPoints` instantly, or a different resource).
13. **Environment & Admin:**
    *   `getGlobalEcosystemState`: Read a conceptual global state variable.
    *   `evolveGlobalEcosystemState`: Admin function to simulate environmental change affecting entities (could be triggered by oracle/time).
    *   `setSynthesisParameters`: Admin sets costs, success rates, trait combination logic parameters.
    *   `setEntityBaseAttributes`: Admin sets initial attributes for genesis mints.
    *   `setEnergyToken`: Admin sets the address of the `CyberEnergy` token.
    *   `withdrawETH`: Admin withdraws accidental ETH sent to the contract.
    *   `withdrawERC20Funds`: Admin withdraws specific ERC20 tokens (e.g., accumulated CyberEnergy or other tokens if applicable).
14. **ERC721Receiver Hook:** `onERC721Received`: To handle receiving parent tokens for synthesis if needed.

**Function Summary (20+ Functions):**

*   `constructor()`: Initializes the contract, ERC721 name/symbol, admin role, and basic parameters.
*   `supportsInterface(bytes4 interfaceId) public view override returns (bool)`: Standard ERC165 function support check.
*   `tokenURI(uint256 tokenId) public view override returns (string memory)`: Generates the metadata URI dynamically based on the entity's on-chain attributes.
*   `mintGenesisEntity(address to, bytes32 initialDNAHash, uint256 initialComplexity) public onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused`: Mints a new entity with initial attributes (admin function).
*   `getEntityAttributes(uint256 tokenId) public view returns (EntityAttributes memory)`: Retrieves the full attribute struct for an entity.
*   `getEntityStatus(uint256 tokenId) public view returns (EntityStatus)`: Retrieves the current operational status of an entity.
*   `activateEntity(uint256 tokenId) public whenNotPaused nonReentrant`: Transitions an entity to 'Active' status, consuming `CyberEnergy` and resetting interaction timer. Requires caller to approve token transfer.
*   `deactivateEntity(uint256 tokenId) public whenNotPaused`: Transitions an entity to 'Dormant' status.
*   `claimPassiveYield(uint256 tokenId) public whenNotPaused nonReentrant`: Calculates and grants `mutationPoints` based on the time the entity was 'Active' since last claim/activation. Resets timer.
*   `performAdaptationCycle(uint256 tokenId) public whenNotPaused nonReentrant`: Consumes `mutationPoints` to attempt an adaptation. Modifies attributes based on internal logic and success chance.
*   `synthesizeResource(uint256 tokenId) public whenNotPaused nonReentrant`: Active entity consumes `CyberEnergy` to produce a benefit, e.g., instant `mutationPoints` or other effect. Requires caller to approve token transfer.
*   `attemptSynthesis(uint256 parent1Id, uint256 parent2Id) public whenNotPaused nonReentrant`: Burns two specified parent entities owned by the caller, consumes `CyberEnergy`, and attempts to mint a new child entity with combined/mutated attributes. Involves success chance.
*   `getGlobalEcosystemState() public view returns (uint256)`: Reads a global environmental state variable.
*   `evolveGlobalEcosystemState(uint256 newState) public onlyRole(DEFAULT_ADMIN_ROLE)`: Admin function to update the global environmental state (e.g., simulate external conditions changing).
*   `setSynthesisParameters(uint256 energyCost, uint256 successChancePermille, uint256 minComplexityParents, uint256 maxComplexityChild) public onlyRole(DEFAULT_ADMIN_ROLE)`: Admin sets parameters for the synthesis process.
*   `setGenesisParameters(uint256 energyCost, uint256 initialEnergy, uint256 initialComplexity, uint256 initialAdaptation) public onlyRole(DEFAULT_ADMIN_ROLE)`: Admin sets parameters for genesis minting.
*   `setEnergyToken(address tokenAddress) public onlyRole(DEFAULT_ADMIN_ROLE)`: Admin sets the address of the CyberEnergy ERC20 token.
*   `setBaseURI(string memory baseURI_) public onlyRole(DEFAULT_ADMIN_ROLE)`: Admin sets the base URI for token metadata.
*   `withdrawETH() public onlyRole(DEFAULT_ADMIN_ROLE)`: Admin function to withdraw any accidental ETH sent to the contract.
*   `withdrawERC20Funds(address tokenAddress, uint256 amount) public onlyRole(DEFAULT_ADMIN_ROLE)`: Admin function to withdraw specific ERC20 tokens held by the contract.
*   `onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) public override returns (bytes4)`: ERC721 standard hook. Required if synthesis involves transferring parents to the contract.
*   `pause() public onlyRole(DEFAULT_ADMIN_ROLE)`: Pauses contract interactions.
*   `unpause() public onlyRole(DEFAULT_ADMIN_ROLE)`: Unpauses contract interactions.
*   `grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role))`: Grants a role. (From AccessControl)
*   `revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role))`: Revokes a role. (From AccessControl)
*   `renounceRole(bytes32 role, address callerConfirmation) public virtual override`: Allows an account to renounce its own role. (From AccessControl)
*   `getRoleAdmin(bytes32 role) public view virtual override returns (bytes32)`: Gets the admin role for a given role. (From AccessControl)
*   `hasRole(bytes32 role, address account) public view virtual override returns (bool)`: Checks if an account has a role. (From AccessControl)

*(Note: The ERC721 standard methods like `transferFrom`, `ownerOf`, `balanceOf`, `approve`, `getApproved`, `setApprovalForAll`, `isApprovedForAll` are implicitly included via inheritance from OpenZeppelin's ERC721 base contract, bringing the total function count well above 20).*

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// --- Outline ---
// 1. Contract Definition: Inherits ERC721, AccessControl, Pausable, ReentrancyGuard, IERC721Receiver.
// 2. Interfaces: ICyberEnergy (for ERC20 token).
// 3. State Variables: ERC721 data, entity attributes, status, costs, parameters, global state.
// 4. Structs & Enums: EntityAttributes struct, EntityStatus enum.
// 5. Events: Notifications for key actions and state changes.
// 6. Modifiers: Use inherited Pausable, ReentrancyGuard, AccessControl modifiers.
// 7. Constructor: Setup initial contract state, roles, and parameters.
// 8. ERC721 Overrides: Implement custom logic for tokenURI and standard interface support.
// 9. Access Control & Pausability: Inherited and used for administrative functions.
// 10. Core Entity Logic: Functions to manage entity state, actions, and passive yield.
// 11. Synthesis Logic: Function to combine entities and resources into a new entity.
// 12. Resource Interaction: Functions involving the CyberEnergy token.
// 13. Environment & Admin: Functions to read/modify global state and contract parameters.
// 14. Helper Functions: Internal functions for complex logic components.
// 15. ERC721 Receiver Hook: Handles receiving tokens if synthesis requires transfer.

// --- Function Summary ---
// constructor() - Initializes the contract.
// supportsInterface(bytes4 interfaceId) - Standard ERC165 support check.
// tokenURI(uint256 tokenId) - Generates dynamic metadata URI based on entity state.
// mintGenesisEntity(address to, bytes32 initialDNAHash, uint256 initialComplexity) - Admin mints initial entities.
// getEntityAttributes(uint256 tokenId) - Retrieves entity attributes.
// getEntityStatus(uint256 tokenId) - Retrieves entity status.
// activateEntity(uint256 tokenId) - Changes entity status to Active, costs CyberEnergy, starts passive yield.
// deactivateEntity(uint256 tokenId) - Changes entity status to Dormant.
// claimPassiveYield(uint256 tokenId) - Claims accumulated mutation points based on active time.
// performAdaptationCycle(uint256 tokenId) - Consumes mutation points to attempt attribute adaptation.
// synthesizeResource(uint256 tokenId) - Active entity consumes CyberEnergy to gain benefit (e.g., mutation points).
// attemptSynthesis(uint256 parent1Id, uint256 parent2Id) - Burns two parent entities, consumes CyberEnergy, attempts to mint child.
// getGlobalEcosystemState() - Reads the global state.
// evolveGlobalEcosystemState(uint256 newState) - Admin updates global state.
// setSynthesisParameters(...) - Admin sets synthesis costs/chances.
// setGenesisParameters(...) - Admin sets genesis costs/initial attributes.
// setEnergyToken(address tokenAddress) - Admin sets the CyberEnergy token address.
// setBaseURI(string memory baseURI_) - Admin sets base URI for metadata.
// withdrawETH() - Admin withdraws accidental ETH.
// withdrawERC20Funds(address tokenAddress, uint256 amount) - Admin withdraws specific ERC20s.
// onERC721Received(...) - ERC721 receiver hook.
// pause() - Admin pauses interactions.
// unpause() - Admin unpauses interactions.
// grantRole(...) - AccessControl: grants a role.
// revokeRole(...) - AccessControl: revokes a role.
// renounceRole(...) - AccessControl: account renounces its own role.
// getRoleAdmin(...) - AccessControl: gets admin role for a role.
// hasRole(...) - AccessControl: checks if account has role.
// (Plus standard ERC721 functions inherited from OpenZeppelin: transferFrom, safeTransferFrom, ownerOf, balanceOf, approve, getApproved, setApprovalForAll, isApprovedForAll)

contract DynamicCyberneticEcosystem is ERC721, AccessControl, Pausable, ReentrancyGuard, IERC721Receiver {

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00; // Admin role from AccessControl

    // --- Interfaces ---
    interface ICyberEnergy is IERC20 {
        // Add any specific CyberEnergy functions if needed beyond standard ERC20
    }

    // --- State Variables ---

    // ERC721 Metadata
    string private _baseTokenURI;

    // Entity Data Structures
    enum EntityStatus { Dormant, Active, Repairing }

    struct EntityAttributes {
        uint66 energy; // Resource level, potentially consumed/replenished
        uint66 complexity; // Base value affecting yield, cost, synthesis outcomes
        uint66 adaptationScore; // Represents evolution/resilience
        bytes32 dnaHash; // Fixed traits determined at genesis/synthesis
        uint66 mutationPoints; // Points accumulated for adaptation cycles
        uint65 lastInteractionTime; // Timestamp of last activation, claim, or action
        uint65 creationTime; // Timestamp of minting
    }

    mapping(uint256 => EntityAttributes) private _entityAttributes;
    mapping(uint256 => EntityStatus) private _entityStatus;
    mapping(uint256 => uint64) private _entityLastActiveTime; // Timestamp tracking for passive yield

    // Global State
    uint256 public globalEcosystemState; // A parameter representing environmental conditions

    // Parameters & Costs
    address public cyberEnergyToken; // Address of the ERC20 CyberEnergy token

    struct GenesisParameters {
        uint256 energyCost;
        uint256 initialEnergy;
        uint256 initialComplexity;
        uint256 initialAdaptation;
        uint256 initialMutationPoints;
    }
    GenesisParameters public genesisParameters;

    struct SynthesisParameters {
        uint256 energyCost;
        uint256 successChancePermille; // Chance of success out of 1000 (e.g., 750 for 75%)
        uint256 minComplexityParents; // Minimum complexity sum for parents
        uint256 maxComplexityChild; // Maximum complexity for the child
        uint256 mutationChancePermille; // Chance of mutation if synthesis is successful
    }
    SynthesisParameters public synthesisParameters;

    // Counters
    uint256 private _nextTokenId;

    // --- Events ---
    event EntityMinted(uint256 indexed tokenId, address indexed owner, bytes32 dnaHash);
    event EntityStatusChanged(uint256 indexed tokenId, EntityStatus newStatus, EntityStatus oldStatus);
    event EntityAttributeUpdated(uint256 indexed tokenId, string attributeName, uint256 oldValue, uint256 newValue);
    event PassiveYieldClaimed(uint256 indexed tokenId, uint256 claimedMutationPoints);
    event AdaptationPerformed(uint256 indexed tokenId, bool success, uint256 pointsConsumed);
    event SynthesisAttempt(uint256 indexed parent1Id, uint256 indexed parent2Id, bool success, uint256 indexed childId);
    event ResourceSynthesized(uint256 indexed tokenId, uint256 energyConsumed, uint256 pointsGained);
    event ParametersUpdated(string paramType, bytes data);
    event GlobalStateEvolved(uint256 oldState, uint256 newState);

    // --- Modifiers ---
    // Uses inherited: whenNotPaused, nonReentrant, onlyRole(ROLE)

    // --- Constructor ---
    constructor(string memory name, string memory symbol, address admin)
        ERC721(name, symbol)
        Pausable()
        AccessControl()
    {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _nextTokenId = 0; // Start with token ID 0

        // Set initial dummy parameters (should be set properly by admin)
        genesisParameters = GenesisParameters(1 ether, 100, 50, 10, 0); // Example costs/initial values
        synthesisParameters = SynthesisParameters(2 ether, 750, 100, 150, 200); // Example costs/chances
    }

    // --- ERC721 Standard Overrides ---

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, AccessControl) returns (bool) {
        return interfaceId == type(IERC721Receiver).interfaceId || super.supportsInterface(interfaceId);
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI_) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _baseTokenURI = baseURI_;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) {
            revert ERC721NonexistentToken(tokenId);
        }

        // Fetch dynamic attributes
        EntityAttributes memory attrs = _entityAttributes[tokenId];
        EntityStatus status = _entityStatus[tokenId];

        // Build URI or fetch from external service based on attributes
        // For this example, we'll construct a simple placeholder URI
        // A real implementation would fetch structured metadata (e.g., JSON)
        // from IPFS or a trusted server, possibly embedding attributes directly.

        string memory base = _baseURI();
        if (bytes(base).length == 0) {
             return string(abi.encodePacked(
                 "data:application/json;base64,",
                 Base64.encode(bytes(abi.encodePacked(
                     '{"name":"Cybernetic Entity #', Strings.toString(tokenId),
                     '","description":"Dynamic entity in the cybernetic ecosystem.",',
                     '"attributes": [',
                         '{"trait_type": "Status", "value": "', _statusToString(status), '"},',
                         '{"trait_type": "Energy", "value": ', Strings.toString(attrs.energy), '},',
                         '{"trait_type": "Complexity", "value": ', Strings.toString(attrs.complexity), '},',
                         '{"trait_type": "Adaptation Score", "value": ', Strings.toString(attrs.adaptationScore), '},',
                         '{"trait_type": "Mutation Points", "value": ', Strings.toString(attrs.mutationPoints), '}',
                         // Add more attributes as needed
                     ']}'
                 )))
             ));
        }

        // Simple approach: baseURI/tokenId -> expects JSON at this URL
        return string(abi.encodePacked(base, Strings.toString(tokenId)));
    }

    // Helper to convert status enum to string for metadata
    function _statusToString(EntityStatus status) internal pure returns (string memory) {
        if (status == EntityStatus.Dormant) return "Dormant";
        if (status == EntityStatus.Active) return "Active";
        if (status == EntityStatus.Repairing) return "Repairing";
        return "Unknown";
    }

    // --- Core Entity Logic ---

    /// @notice Mints a new genesis entity. Only callable by admin.
    /// @param to The address to mint the entity to.
    /// @param initialDNAHash A unique hash representing the entity's inherent traits.
    /// @param initialComplexity Initial complexity score.
    function mintGenesisEntity(address to, bytes32 initialDNAHash, uint256 initialComplexity)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
        whenNotPaused
    {
        require(_nextTokenId < type(uint256).max, "Max entities reached");

        uint256 tokenId = _nextTokenId++;
        _mint(to, tokenId);

        EntityAttributes storage newAttrs = _entityAttributes[tokenId];
        newAttrs.energy = uint66(genesisParameters.initialEnergy);
        newAttrs.complexity = uint66(initialComplexity); // Use provided complexity or genesis default
        newAttrs.adaptationScore = uint66(genesisParameters.initialAdaptation);
        newAttrs.dnaHash = initialDNAHash;
        newAttrs.mutationPoints = uint66(genesisParameters.initialMutationPoints);
        newAttrs.lastInteractionTime = uint65(block.timestamp);
        newAttrs.creationTime = uint65(block.timestamp);

        _entityStatus[tokenId] = EntityStatus.Dormant;
        _entityLastActiveTime[tokenId] = uint64(block.timestamp);

        emit EntityMinted(tokenId, to, initialDNAHash);
    }

    /// @notice Gets the dynamic attributes of an entity.
    /// @param tokenId The ID of the entity.
    /// @return EntityAttributes struct containing all mutable attributes.
    function getEntityAttributes(uint256 tokenId) public view returns (EntityAttributes memory) {
        require(_exists(tokenId), "Entity does not exist");
        return _entityAttributes[tokenId];
    }

    /// @notice Gets the current status (Dormant, Active, Repairing) of an entity.
    /// @param tokenId The ID of the entity.
    /// @return The EntityStatus enum value.
    function getEntityStatus(uint256 tokenId) public view returns (EntityStatus) {
        require(_exists(tokenId), "Entity does not exist");
        return _entityStatus[tokenId];
    }

    /// @notice Activates a Dormant entity, consuming CyberEnergy.
    /// @param tokenId The ID of the entity to activate.
    function activateEntity(uint256 tokenId) public whenNotPaused nonReentrant {
        require(_exists(tokenId), "Entity does not exist");
        require(ownerOf(tokenId) == msg.sender, "Not entity owner");
        require(_entityStatus[tokenId] == EntityStatus.Dormant, "Entity must be Dormant");
        require(cyberEnergyToken != address(0), "Energy token not set");

        ICyberEnergy energyToken = ICyberEnergy(cyberEnergyToken);
        require(energyToken.transferFrom(msg.sender, address(this), synthesisParameters.energyCost), "Energy transfer failed"); // Using synthesis cost for example, define activation cost

        _setEntityStatus(tokenId, EntityStatus.Active);
        _entityAttributes[tokenId].lastInteractionTime = uint65(block.timestamp);
        _entityLastActiveTime[tokenId] = uint64(block.timestamp); // Start tracking active time
    }

    /// @notice Deactivates an Active entity, returning it to Dormant status.
    /// @param tokenId The ID of the entity to deactivate.
    function deactivateEntity(uint256 tokenId) public whenNotPaused {
        require(_exists(tokenId), "Entity does not exist");
        require(ownerOf(tokenId) == msg.sender, "Not entity owner");
        require(_entityStatus[tokenId] == EntityStatus.Active, "Entity must be Active");

        // Claim any accumulated yield before deactivating
        _claimPassiveYieldInternal(tokenId);

        _setEntityStatus(tokenId, EntityStatus.Dormant);
        // _entityLastActiveTime is reset upon next activation
    }

    /// @notice Claims mutation points accrued while the entity was Active.
    /// @param tokenId The ID of the entity to claim yield for.
    function claimPassiveYield(uint256 tokenId) public whenNotPaused nonReentrant {
        require(_exists(tokenId), "Entity does not exist");
        require(ownerOf(tokenId) == msg.sender, "Not entity owner");
        require(_entityStatus[tokenId] == EntityStatus.Active, "Entity must be Active");

        _claimPassiveYieldInternal(tokenId);
    }

    /// @dev Internal function to calculate and add passive yield.
    function _claimPassiveYieldInternal(uint256 tokenId) internal {
        uint64 lastActiveTime = _entityLastActiveTime[tokenId];
        uint64 timeElapsed = uint64(block.timestamp) - lastActiveTime;
        uint66 complexity = _entityAttributes[tokenId].complexity;

        // Simple yield calculation: time * complexity / some factor
        // Adjust factor for desired yield rate
        uint256 claimedPoints = (uint256(timeElapsed) * uint256(complexity)) / 3600; // Example: complexity points per hour

        if (claimedPoints > 0) {
            _entityAttributes[tokenId].mutationPoints += uint66(claimedPoints);
            _entityLastActiveTime[tokenId] = uint64(block.timestamp); // Reset timer
            emit PassiveYieldClaimed(tokenId, claimedPoints);
            emit EntityAttributeUpdated(tokenId, "mutationPoints", uint256(_entityAttributes[tokenId].mutationPoints) - claimedPoints, uint256(_entityAttributes[tokenId].mutationPoints));
        }
    }

    /// @notice Attempts to adapt the entity using accumulated mutation points.
    /// @param tokenId The ID of the entity.
    function performAdaptationCycle(uint256 tokenId) public whenNotPaused nonReentrant {
        require(_exists(tokenId), "Entity does not exist");
        require(ownerOf(tokenId) == msg.sender, "Not entity owner");

        EntityAttributes storage attrs = _entityAttributes[tokenId];
        require(attrs.mutationPoints > 0, "Not enough mutation points");

        uint256 pointsToConsume = attrs.mutationPoints; // Consume all available points
        attrs.mutationPoints = 0; // Reset points

        // Simple adaptation logic: chance of increasing adaptation score based on points
        // A more advanced version could use Chainlink VRF for true randomness
        // or deterministic logic based on ecosystem state/other attributes.
        uint256 successThreshold = pointsToConsume * 10; // Example: 10% base chance per point, scaled
        // Using blockhash is NOT secure for true randomness in production, but demonstrates concept
        uint256 randomFactor = uint256(keccak256(abi.encodePacked(block.timestamp, tx.origin, block.number, tokenId))) % 10000; // 0-9999

        bool success = randomFactor < successThreshold; // Simple chance check

        uint256 oldAdaptation = attrs.adaptationScore;
        if (success) {
            // Increase adaptation score, maybe also complexity or energy cap
            uint256 adaptationIncrease = pointsToConsume / 100; // Example increase
            attrs.adaptationScore = uint66(uint256(attrs.adaptationScore) + adaptationIncrease);
            emit EntityAttributeUpdated(tokenId, "adaptationScore", oldAdaptation, attrs.adaptationScore);
        }
        // Could add logic for failed adaptation (e.g., gain stress, temporary debuff)

        emit AdaptationPerformed(tokenId, success, pointsToConsume);
        emit EntityAttributeUpdated(tokenId, "mutationPoints", pointsToConsume, 0); // Mutation points reset
    }

    /// @notice Active entity consumes CyberEnergy for an instant benefit.
    /// @param tokenId The ID of the entity.
    function synthesizeResource(uint256 tokenId) public whenNotPaused nonReentrant {
        require(_exists(tokenId), "Entity does not exist");
        require(ownerOf(tokenId) == msg.sender, "Not entity owner");
        require(_entityStatus[tokenId] == EntityStatus.Active, "Entity must be Active");
        require(cyberEnergyToken != address(0), "Energy token not set");

        ICyberEnergy energyToken = ICyberEnergy(cyberEnergyToken);
        uint256 energyCost = synthesisParameters.energyCost / 2; // Example: Resource synthesis costs less than parent synthesis
        require(energyToken.transferFrom(msg.sender, address(this), energyCost), "Energy transfer failed");

        EntityAttributes storage attrs = _entityAttributes[tokenId];
        // Benefit example: gain instant mutation points
        uint256 pointsGained = energyCost / 1000; // Example: gain 1 point per 1000 energy
        attrs.mutationPoints += uint66(pointsGained);

        _entityAttributes[tokenId].lastInteractionTime = uint65(block.timestamp); // Reset interaction timer

        emit ResourceSynthesized(tokenId, energyCost, pointsGained);
        emit EntityAttributeUpdated(tokenId, "mutationPoints", uint256(attrs.mutationPoints) - pointsGained, uint256(attrs.mutationPoints));
    }

    // --- Synthesis Mechanism ---

    /// @notice Attempts to synthesize a new entity from two parent entities.
    /// @param parent1Id The ID of the first parent entity.
    /// @param parent2Id The ID of the second parent entity.
    function attemptSynthesis(uint256 parent1Id, uint256 parent2Id) public whenNotPaused nonReentrant {
        require(parent1Id != parent2Id, "Parents must be different entities");
        require(_exists(parent1Id), "Parent 1 does not exist");
        require(_exists(parent2Id), "Parent 2 does not exist");
        require(ownerOf(parent1Id) == msg.sender, "Not owner of parent 1");
        require(ownerOf(parent2Id) == msg.sender, "Not owner of parent 2");
        require(_entityStatus[parent1Id] == EntityStatus.Active, "Parent 1 must be Active");
        require(_entityStatus[parent2Id] == EntityStatus.Active, "Parent 2 must be Active");
        require(cyberEnergyToken != address(0), "Energy token not set");

        ICyberEnergy energyToken = ICyberEnergy(cyberEnergyToken);
        require(energyToken.transferFrom(msg.sender, address(this), synthesisParameters.energyCost), "Energy transfer failed");

        EntityAttributes memory parent1Attrs = _entityAttributes[parent1Id];
        EntityAttributes memory parent2Attrs = _entityAttributes[parent2Id];

        require(uint256(parent1Attrs.complexity) + uint256(parent2Attrs.complexity) >= synthesisParameters.minComplexityParents, "Parents too simple for synthesis");

        // Use blockhash as a simple pseudo-random source (NOT secure for production)
        uint256 randomFactor = uint256(keccak256(abi.encodePacked(block.timestamp, tx.origin, block.number, parent1Id, parent2Id))) % 1000; // 0-999

        bool synthesisSuccess = randomFactor < synthesisParameters.successChancePermille;
        uint256 childId = 0; // Will be 0 if synthesis fails

        if (synthesisSuccess) {
             require(_nextTokenId < type(uint256).max, "Max entities reached");
             childId = _nextTokenId++;

             // --- Child Attribute Calculation ---
             // Combine/mutate attributes based on parents
             bytes32 childDNA = _combineDNA(parent1Attrs.dnaHash, parent2Attrs.dnaHash);

             uint256 baseComplexity = (uint256(parent1Attrs.complexity) + uint256(parent2Attrs.complexity)) / 2;
             uint256 childComplexity = baseComplexity + (randomFactor % (synthesisParameters.maxComplexityChild - baseComplexity)); // Random complexity within range
             childComplexity = uint256(childComplexity) > synthesisParameters.maxComplexityChild ? synthesisParameters.maxComplexityChild : childComplexity; // Cap complexity

             uint256 childAdaptation = (uint256(parent1Attrs.adaptationScore) + uint256(parent2Attrs.adaptationScore)) / 2;
             // Add mutation chance for attributes
             if (randomFactor % 1000 < synthesisParameters.mutationChancePermille) {
                  // Simple mutation effect: boost/reduce a random attribute
                  uint256 mutationEffect = (randomFactor % 20) - 10; // +/- 10 effect
                  childComplexity = uint256(childComplexity) + mutationEffect;
                  childAdaptation = uint256(childAdaptation) + mutationEffect;
             }

             childComplexity = uint256(childComplexity) > 0 ? childComplexity : 1; // Min complexity 1
             childAdaptation = uint256(childAdaptation) > 0 ? childAdaptation : 1; // Min adaptation 1


             _mint(msg.sender, childId); // Mint child to the caller

             EntityAttributes storage childAttrs = _entityAttributes[childId];
             childAttrs.energy = uint66(genesisParameters.initialEnergy / 2); // Child starts with less energy
             childAttrs.complexity = uint66(childComplexity);
             childAttrs.adaptationScore = uint66(childAdaptation);
             childAttrs.dnaHash = childDNA;
             childAttrs.mutationPoints = 0;
             childAttrs.lastInteractionTime = uint65(block.timestamp);
             childAttrs.creationTime = uint65(block.timestamp);
             _entityStatus[childId] = EntityStatus.Dormant;
             _entityLastActiveTime[childId] = uint64(block.timestamp);

             emit EntityMinted(childId, msg.sender, childDNA);
        }

        // Burn parent entities regardless of synthesis success
        _burn(parent1Id);
        _burn(parent2Id);

        emit SynthesisAttempt(parent1Id, parent2Id, synthesisSuccess, childId);
    }

    /// @dev Internal helper to combine DNA hashes. Simple XOR for example.
    function _combineDNA(bytes32 dna1, bytes32 dna2) internal pure returns (bytes32) {
        return dna1 ^ dna2; // XOR combination
    }

    // --- Environment & Admin ---

    /// @notice Reads the current global ecosystem state.
    /// @return The current global state value.
    function getGlobalEcosystemState() public view returns (uint256) {
        return globalEcosystemState;
    }

    /// @notice Admin function to update the global ecosystem state.
    /// @param newState The new value for the global state.
    function evolveGlobalEcosystemState(uint256 newState) public onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 oldState = globalEcosystemState;
        globalEcosystemState = newState;
        emit GlobalStateEvolved(oldState, newState);
    }

    /// @notice Admin sets parameters for synthesis.
    function setSynthesisParameters(
        uint256 energyCost,
        uint256 successChancePermille,
        uint256 minComplexityParents,
        uint256 maxComplexityChild,
        uint256 mutationChancePermille
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        synthesisParameters = SynthesisParameters(
            energyCost,
            successChancePermille,
            minComplexityParents,
            maxComplexityChild,
            mutationChancePermille
        );
         emit ParametersUpdated("Synthesis", abi.encode(synthesisParameters));
    }

    /// @notice Admin sets parameters for genesis minting.
    function setGenesisParameters(
        uint256 energyCost,
        uint256 initialEnergy,
        uint256 initialComplexity,
        uint256 initialAdaptation,
        uint256 initialMutationPoints
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        genesisParameters = GenesisParameters(
            energyCost,
            initialEnergy,
            initialComplexity,
            initialAdaptation,
            initialMutationPoints
        );
         emit ParametersUpdated("Genesis", abi.encode(genesisParameters));
    }

    /// @notice Admin sets the address of the CyberEnergy ERC20 token.
    /// @param tokenAddress The address of the CyberEnergy token contract.
    function setEnergyToken(address tokenAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(tokenAddress != address(0), "Invalid address");
        cyberEnergyToken = tokenAddress;
         emit ParametersUpdated("EnergyToken", abi.encode(tokenAddress));
    }

    /// @notice Admin withdraws any accidental ETH sent to the contract.
    function withdrawETH() public onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "ETH withdrawal failed");
    }

    /// @notice Admin withdraws a specific ERC20 token held by the contract.
    /// @param tokenAddress The address of the ERC20 token.
    /// @param amount The amount to withdraw.
    function withdrawERC20Funds(address tokenAddress, uint256 amount) public onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant {
        require(tokenAddress != address(0), "Invalid token address");
        ICyberEnergy token = ICyberEnergy(tokenAddress); // Using ICyberEnergy interface, assumes it's any ERC20
        require(token.transfer(msg.sender, amount), "ERC20 withdrawal failed");
    }

    // --- Internal Helpers ---

    /// @dev Sets the status of an entity and emits an event.
    function _setEntityStatus(uint256 tokenId, EntityStatus newStatus) internal {
        EntityStatus oldStatus = _entityStatus[tokenId];
        if (oldStatus != newStatus) {
            _entityStatus[tokenId] = newStatus;
            emit EntityStatusChanged(tokenId, newStatus, oldStatus);
        }
    }

     /// @dev Updates a specific entity attribute and emits an event.
     function _updateEntityAttribute(uint256 tokenId, string memory attributeName, uint256 oldValue, uint256 newValue) internal {
         // Note: Direct assignment to struct members like _entityAttributes[tokenId].energy
         // is sufficient for state changes. This helper is for consistent event emission
         // and could include validation if needed. This implementation is simplified.
         emit EntityAttributeUpdated(tokenId, attributeName, oldValue, newValue);
     }


    // --- ERC721 Receiver Hook ---

    /// @notice Called when an ERC721 token is transferred to this contract via safeTransferFrom.
    /// Handles receiving parents for synthesis if that mechanism is used (not strictly necessary with current approach).
    /// @param operator The address which called `safeTransferFrom`.
    /// @param from The address which was the owner of the token before the transfer.
    /// @param tokenId The ID of the token that was transferred.
    /// @param data Additional data with no specified format.
    /// @return bytes4 `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) public override returns (bytes4) {
        // Optional: Add logic here if tokens received need specific handling.
        // For the current `attemptSynthesis` design (burning parents owned by sender),
        // this hook is not strictly needed, as parents are burned directly from the sender's wallet.
        // If synthesis involved sending parents *to* the contract first, this would be crucial.
        // Acknowledge receipt by returning the magic value.
        return this.onERC721Received.selector;
    }
}

// Helper contract for Base64 encoding (from OpenZeppelin) - needed for data URI tokenURI
library Base64 {
    string internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // pad with trailing zeros if needed to fulfill chunk size, then append padding characters
        uint256 lastChunkSize = data.length % 3;
        uint256 size = data.length + (lastChunkSize == 0 ? 0 : (3 - lastChunkSize));

        bytes memory output = new bytes(size * 4 / 3);
        // index in output array
        uint256 outputPtr = 0;

        // encode ABI parameter values to Tezos compatible Base64 format
        for (uint256 i = 0; i < data.length; i += 3) {
            output[outputPtr++] = bytes1(TABLE[uint8(data[i] >> 2)]);
            output[outputPtr++] = bytes1(TABLE[uint8(((data[i] & 0x03) << 4) | (data[i + 1] >> 4))]);
            if (i + 1 < data.length) {
                output[outputPtr++] = bytes1(TABLE[uint8(((data[i + 1] & 0x0f) << 2) | (data[i + 2] >> 6))]);
                if (i + 2 < data.length) {
                    output[outputPtr++] = bytes1(TABLE[uint8(data[i + 2] & 0x3f)]);
                } else {
                    output[outputPtr++] = "=";
                }
            } else {
                output[outputPtr++] = "=";
                output[outputPtr++] = "=";
            }
        }

        return string(output);
    }
}

```
**Explanation of Concepts & Why They are Advanced/Creative:**

1.  **Dynamic On-Chain Attributes:** Instead of static metadata, the `EntityAttributes` struct lives directly on the blockchain and can be modified. This allows for NFTs that *change* based on user interaction (`activateEntity`, `performAdaptationCycle`, `synthesizeResource`) or potentially time/external factors (`evolveGlobalEcosystemState`). The `tokenURI` function dynamically reads these attributes to generate metadata, making the NFT's appearance or description tied to its on-chain state. This goes beyond typical ERC721 where the `tokenURI` is usually static or points to static data.
2.  **On-Chain Simulation/Ecosystem:** The contract isn't just a collection of tokens; it defines a mini-ecosystem with resources (`CyberEnergy`), actions that consume/generate resources, and internal state (`EntityStatus`, `globalEcosystemState`) that influences behavior. This moves towards on-chain game logic or complex simulations.
3.  **Synthesis with Burning & Mutation:** The `attemptSynthesis` function is a core advanced concept. It requires the burning of existing NFTs (parents) to create a new one (child). The child's attributes are derived from parents via a defined logic (`_combineDNA`, averaging attributes) and include elements of chance/mutation, making the outcome semi-unpredictable and emergent. This is a creative "breeding" or "crafting" mechanism implemented on-chain.
4.  **Passive Yield & Active Status:** The `activateEntity` and `claimPassiveYield` functions introduce a yield-farming or staking-like mechanic where entities, when in a specific 'Active' state (which costs resources to enter), accrue internal points (`mutationPoints`) over time. This encourages engaging with the contract and managing entity states.
5.  **Adaptation Cycle:** The `performAdaptationCycle` uses accumulated internal points to attempt a permanent change in the entity's core stats (`adaptationScore`, potentially others). This adds a layer of progression and strategy, where users must manage their entities' state and points to improve them over time. The success chance based on points and a pseudo-random factor (note: using blockhash is for concept, production needs VRF) adds complexity and variance.
6.  **Inter-Entity Interaction (Indirect):** While not direct peer-to-peer combat, the synthesis function is an interaction between two entities *through* the owner, leading to a new outcome. Future extensions could involve entities directly interacting or competing based on attributes.
7.  **Access Control & Pausability:** Using OpenZeppelin's AccessControl and Pausable gives structured, secure ways to manage administrative functions and pause the contract in emergencies, which is crucial for complex systems.
8.  **Resource Token Integration:** Requiring an external ERC-20 token (`CyberEnergy`) for core actions (`activateEntity`, `attemptSynthesis`, `synthesizeResource`) creates interdependencies within a potential dApp ecosystem and adds a crucial economic layer.

This contract structure provides a framework for a sophisticated on-chain game or simulation where NFTs are not static collectibles but active participants with evolving traits and lifecycle mechanics (minting, activation, deactivation, resource use, adaptation, procreation/synthesis, burning). It avoids simply duplicating standard ERC721 or basic DeFi/DAO patterns by combining several advanced concepts into a novel system.

**Note on Security:**
*   The pseudo-randomness used (blockhash) is insecure and predictable. A production contract requiring true randomness would need to integrate with a service like Chainlink VRF.
*   This contract is complex and would require thorough testing and professional auditing before deployment to production.
*   Careful consideration is needed for parameter tuning (costs, yield rates, success chances) to ensure economic sustainability and balanced gameplay.
*   The `tokenURI` implementation using data URI with Base64 can be gas-intensive for complex metadata. An alternative is to store dynamic attributes on-chain but have the `tokenURI` point to an external API that reads the on-chain state and serves the metadata.