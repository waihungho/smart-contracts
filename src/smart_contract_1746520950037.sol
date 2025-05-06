Okay, here is a Solidity smart contract demonstrating interesting, advanced, and creative concepts around time-based mechanics, dynamic assets, and interactions, fulfilling the requirement of having at least 20 functions and avoiding common open-source patterns directly.

**Concept: ChronoQuest Protocol**

Users own unique digital entities called "Quanta". These Quanta exist within a simulated "Chronosphere". Quanta have dynamic traits that can change over time, through user interactions, or by successfully completing "Quests". Users accrue "Temporal Energy" passively over time, which is required to perform actions like evolving Quanta, starting Quests, or interacting with other Quanta.

**Interesting/Advanced Concepts:**

1.  **Time-Based Evolution:** Quanta traits change automatically based on the time elapsed since their last update, triggered by user actions or explicit 'attunement'.
2.  **Temporal Energy Accrual:** Users gain a resource (Temporal Energy) over time, needed for actions, introducing a passive resource generation mechanic.
3.  **Dynamic NFTs/Assets:** Quanta (acting like NFTs) are not static; their properties (`traits`) change based on protocol mechanics.
4.  **On-Chain Quests:** Users can assign their Quanta to time-locked quests with specific requirements and guaranteed, yet trait-modifying, outcomes.
5.  **User Interaction Mechanics:** Users can spend energy to interact with *any* Quanta, potentially causing small trait shifts, encouraging engagement beyond just owning.
6.  **On-Chain Synthesis/Burning:** A process to combine aspects of two Quanta into one, consuming the other, acting as a supply sink and trait refinement mechanism.
7.  **Manual ERC721-like Handling:** Instead of inheriting ERC721 directly, key ownership/transfer functions are implemented manually to fit the custom Quanta struct and logic, demonstrating the underlying principles.

---

**Outline and Function Summary**

**Contract Name:** `ChronoQuestProtocol`

**Core Concepts:** Time-based Quanta evolution, Temporal Energy system, Quests, Dynamic Traits, Interaction, Synthesis.

**State Variables:**
*   `owner`: Protocol administrator.
*   `questMaster`: Role for creating new Quest types.
*   `nextQuantaId`: Counter for unique Quanta IDs.
*   `nextQuestId`: Counter for unique Quest IDs.
*   `MINT_FEE`: Cost to mint a new Quanta (in native token).
*   `TEMPORAL_ENERGY_RATE`: Energy gained per second per user.
*   `MIN_TRAITS`, `MAX_TRAITS`: Bounds for Quanta trait array size.
*   `userTemporalEnergy`: Mapping of user addresses to their energy balance.
*   `lastEnergyClaimTime`: Mapping of user addresses to the last timestamp they claimed energy.
*   `quantaById`: Mapping of Quanta ID to Quanta struct.
*   `questsById`: Mapping of Quest ID to Quest struct.
*   `operatorApprovals`: Mapping for ERC721 `setApprovalForAll`.
*   `userQuantaCount`: Mapping to track number of Quanta owned by each address.

**Structs:**
*   `Quanta`: Represents a single dynamic entity with traits, ownership, time data, and quest state.
*   `Quest`: Defines a type of quest with duration, costs, rewards, and trait modifications/requirements.

**Events:** Standard ERC721 events (`Transfer`, `Approval`, `ApprovalForAll`) plus custom events for protocol actions (`QuantaMinted`, `QuantaEvolved`, `EnergyClaimed`, `QuestCreated`, `QuestStarted`, `QuestCompleted`, `QuestCancelled`, `QuantaInteracted`, `QuantaSynthesized`, `QuantaDispersed`).

**Modifiers:**
*   `onlyOwner`: Restricts access to the contract owner.
*   `onlyQuestMaster`: Restricts access to the designated quest master.
*   `quantaExists(uint256 quantaId)`: Checks if a Quanta ID is valid and active.
*   `isQuantaOwnerOrApproved(uint256 quantaId)`: Checks if sender is owner or approved for a Quanta.
*   `questExists(uint256 questId)`: Checks if a Quest ID is valid.

**Functions (Total: 27)**

**ERC721-like Interface (Manual Implementation):**
1.  `balanceOf(address owner)`: Get the number of Quanta owned by an address.
2.  `ownerOf(uint256 quantaId)`: Get the owner of a specific Quanta.
3.  `approve(address to, uint256 quantaId)`: Approve another address to transfer a specific Quanta.
4.  `getApproved(uint256 quantaId)`: Get the approved address for a specific Quanta.
5.  `setApprovalForAll(address operator, bool approved)`: Approve or revoke approval for an operator for all sender's Quanta.
6.  `isApprovedForAll(address owner, address operator)`: Check if an operator is approved for all of an owner's Quanta.
7.  `transferFrom(address from, address to, uint256 quantaId)`: Transfer a Quanta (requires ownership or approval).

**Quanta Lifecycle & Core Mechanics:**
8.  `mintQuanta()`: Mints a new Quanta for the sender, requires MINT_FEE, assigns initial traits.
9.  `getQuanta(uint256 quantaId)`: Views all details of a specific Quanta (includes applying potential time evolution *before* returning).
10. `getQuantaTraits(uint256 quantaId)`: Views only the traits of a specific Quanta (includes applying potential time evolution).
11. `attuneQuantaToChronosphere(uint256 quantaId)`: Explicitly triggers the time-based evolution logic for a Quanta, consuming energy.
12. `disperseQuanta(uint256 quantaId)`: Marks a Quanta as inactive/burned, potentially refunding some energy.

**Temporal Energy System:**
13. `claimTemporalEnergy()`: Calculates and adds accrued temporal energy based on time elapsed.
14. `getUserTemporalEnergy(address user)`: Views a user's temporal energy balance.

**Quest System:**
15. `createQuest(string calldata name, uint64 duration, uint256 energyCost, int256[] calldata traitModifiers, uint256 rewardAmount, uint256[] calldata requiredTraits)`: Creates a new Quest type (only by questMaster).
16. `getQuestDetails(uint256 questId)`: Views details of a specific Quest type.
17. `startQuest(uint256 quantaId, uint256 questId)`: Assigns a Quanta to a quest if requirements are met (consumes energy).
18. `completeQuest(uint256 quantaId)`: Finalizes a quest if duration is passed, applies trait modifiers, and transfers rewards.
19. `cancelQuest(uint256 quantaId)`: Stops a quest before completion (potential penalty?).

**Interaction & Synthesis:**
20. `interactWithQuanta(uint256 quantaId)`: Allows spending energy to interact with any active Quanta, causing a minor trait modification.
21. `synthesizeQuanta(uint256 targetQuantaId, uint256 sourceQuantaId)`: Combines traits from a source Quanta into a target Quanta, dispersing the source Quanta (consumes energy/fees).

**Admin/Configuration:**
22. `setQuestMaster(address _questMaster)`: Sets the address with quest creation privileges.
23. `setTemporalEnergyRate(uint256 rate)`: Sets the temporal energy accrual rate.
24. `setMintFee(uint256 fee)`: Sets the fee required to mint a Quanta.
25. `setTraitBounds(uint256 min, uint256 max)`: Sets minimum and maximum allowed traits array size.
26. `withdrawProtocolFees()`: Allows the owner to withdraw accumulated mint fees.
27. `getProtocolState()`: Views various global protocol parameters.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title ChronoQuestProtocol
/// @author Your Name (or Pseudonym)
/// @notice A smart contract protocol for managing time-evolving Quanta entities,
/// utilizing Temporal Energy, and engaging in on-chain Quests.
/// It implements key ERC721-like features manually for custom logic integration.

// Outline and Function Summary:
//
// Concept: ChronoQuest Protocol where users own dynamic Quanta, manage Temporal Energy, and embark on Quests.
// Advanced Concepts: Time-Based Evolution, Temporal Energy Accrual, Dynamic Assets, On-Chain Quests, User Interaction, On-Chain Synthesis/Burning, Manual ERC721 Implementation.
//
// State Variables:
// - owner: Protocol administrator (address payable)
// - questMaster: Address allowed to create new Quest types (address)
// - nextQuantaId: Counter for unique Quanta IDs (uint256)
// - nextQuestId: Counter for unique Quest IDs (uint256)
// - MINT_FEE: Cost in native token to mint a Quanta (uint256)
// - TEMPORAL_ENERGY_RATE: Energy gained per second per user (uint256)
// - MIN_TRAITS, MAX_TRAITS: Bounds for Quanta trait array size (uint256)
// - userTemporalEnergy: User energy balance (mapping(address => uint256))
// - lastEnergyClaimTime: Last timestamp user claimed energy (mapping(address => uint64))
// - quantaById: Quanta data storage (mapping(uint256 => Quanta))
// - questsById: Quest data storage (mapping(uint256 => Quest))
// - operatorApprovals: ERC721 Approval for All (mapping(address => mapping(address => bool)))
// - userQuantaCount: Number of Quanta owned by address (mapping(address => uint256))
//
// Structs:
// - Quanta: Represents a dynamic entity (uint256 id, address owner, uint64 creationTime, uint64 lastActionTime, int256[] traits, uint256 currentQuestId, uint64 questEndTime, address approved, bool isActive)
// - Quest: Defines a quest type (uint256 id, string name, uint64 duration, uint256 energyCost, int256[] traitModifiers, uint256 rewardAmount, int256[] requiredTraits)
//
// Events: Transfer, Approval, ApprovalForAll, QuantaMinted, QuantaEvolved, EnergyClaimed, QuestCreated, QuestStarted, QuestCompleted, QuestCancelled, QuantaInteracted, QuantaSynthesized, QuantaDispersed.
//
// Modifiers: onlyOwner, onlyQuestMaster, quantaExists, isQuantaOwnerOrApproved, questExists.
//
// Functions (27 Total):
// - ERC721-like: balanceOf, ownerOf, approve, getApproved, setApprovalForAll, isApprovedForAll, transferFrom
// - Quanta Lifecycle: mintQuanta, getQuanta, getQuantaTraits, attuneQuantaToChronosphere, disperseQuanta
// - Temporal Energy: claimTemporalEnergy, getUserTemporalEnergy
// - Quest System: createQuest, getQuestDetails, startQuest, completeQuest, cancelQuest
// - Interaction & Synthesis: interactWithQuanta, synthesizeQuanta
// - Admin/Configuration: setQuestMaster, setTemporalEnergyRate, setMintFee, setTraitBounds, withdrawProtocolFees, getProtocolState

error QuantaDoesNotExist(uint256 quantaId);
error QuantaNotActive(uint256 quantaId);
error NotQuantaOwnerOrApproved(uint256 quantaId);
error NotApprovedForAll();
error TransferToZeroAddress();
error TransferFromIncorrectOwner();
error QuantaAlreadyApproved();
error ApprovalToCurrentOwner();
error InvalidTraitCount();
error InsufficientPayment(uint256 required, uint256 sent);
error InsufficientTemporalEnergy(uint256 required, uint256 available);
error QuestDoesNotExist(uint256 questId);
error QuantaBusyOnQuest(uint256 quantaId);
error QuantaNotOnQuest(uint256 quantaId);
error QuestNotComplete(uint256 quantaId);
error QuestRequirementsNotMet(uint256 quantaId, uint256 questId);
error CannotInteractWithInactiveQuanta();
error CannotSynthesizeInactiveQuanta();
error SourceAndTargetQuantaCannotBeSame();
error QuestModifierTraitCountMismatch(uint256 questId);
error RequiredTraitCountMismatch(uint256 questId);

contract ChronoQuestProtocol {
    address payable public owner;
    address public questMaster;

    uint256 public nextQuantaId;
    uint256 public nextQuestId;

    uint256 public MINT_FEE = 0.01 ether; // Example fee
    uint256 public TEMPORAL_ENERGY_RATE = 10; // Example: 10 energy per second

    uint256 public MIN_TRAITS = 3; // Example bounds
    uint256 public MAX_TRAITS = 8;

    mapping(address => uint256) public userTemporalEnergy;
    mapping(address => uint64) public lastEnergyClaimTime;

    struct Quanta {
        uint256 id;
        address owner;
        uint64 creationTime;
        uint64 lastActionTime; // Used for evolution calculation
        int256[] traits; // Dynamic array of trait values
        uint256 currentQuestId; // 0 if not on quest
        uint64 questEndTime; // 0 if not on quest
        address approved; // ERC721 single approval
        bool isActive; // False if dispersed/synthesized away
    }

    mapping(uint256 => Quanta) private quantaById;

    struct Quest {
        uint256 id;
        string name;
        uint64 duration; // In seconds
        uint256 energyCost;
        int256[] traitModifiers; // Changes to traits after completion (can be negative)
        uint256 rewardAmount; // Reward in native currency (ETH/MATIC)
        int256[] requiredTraits; // Minimum trait values to start (must match trait count)
    }

    mapping(uint256 => Quest) private questsById;

    mapping(address => mapping(address => bool)) private operatorApprovals;
    mapping(address => uint256) private userQuantaCount;

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    event QuantaMinted(uint256 indexed quantaId, address indexed owner, uint64 creationTime);
    event QuantaEvolved(uint256 indexed quantaId, int256[] newTraits);
    event EnergyClaimed(address indexed user, uint256 amount);
    event QuestCreated(uint256 indexed questId, string name, address indexed creator);
    event QuestStarted(uint256 indexed quantaId, uint256 indexed questId, uint64 startTime, uint64 endTime);
    event QuestCompleted(uint256 indexed quantaId, uint256 indexed questId, uint64 completionTime, uint256 rewardAmount, int256[] traitModifiersApplied);
    event QuestCancelled(uint256 indexed quantaId, uint256 indexed questId, uint64 cancelTime);
    event QuantaInteracted(uint256 indexed quantaId, address indexed interactor, int256[] traitChanges);
    event QuantaSynthesized(uint256 indexed targetQuantaId, uint256 indexed sourceQuantaId, address indexed owner);
    event QuantaDispersed(uint256 indexed quantaId, address indexed owner);

    modifier onlyOwner() {
        if (msg.sender != owner) revert OwnableUnauthorizedAccount(msg.sender);
        _;
    }

    modifier onlyQuestMaster() {
        if (msg.sender != questMaster) revert OwnableUnauthorizedAccount(msg.sender);
        _;
    }

    modifier quantaExists(uint256 quantaId) {
        if (!quantaById[quantaId].isActive) revert QuantaDoesNotExist(quantaId);
        _;
    }

    modifier isQuantaOwnerOrApproved(uint255 quantaId) {
        if (quantaById[quantaId].owner != msg.sender && quantaById[quantaId].approved != msg.sender && !operatorApprovals[quantaById[quantaId].owner][msg.sender]) {
             revert NotQuantaOwnerOrApproved(quantaId);
        }
        _;
    }

    modifier questExists(uint256 questId) {
        if (questId == 0 || questsById[questId].id == 0) revert QuestDoesNotExist(questId);
        _;
    }

    constructor(address _questMaster) payable {
        owner = payable(msg.sender);
        questMaster = _questMaster;
        nextQuantaId = 1; // Start IDs from 1
        nextQuestId = 1; // Start IDs from 1
        lastEnergyClaimTime[owner] = uint64(block.timestamp); // Initialize owner energy time
    }

    // --- ERC721-like Functions ---

    /// @notice Returns the number of Quanta owned by an account.
    /// @param _owner The address to query the balance of.
    /// @return The number of Quanta owned by the address.
    function balanceOf(address _owner) public view returns (uint256) {
        if (_owner == address(0)) revert TransferToZeroAddress();
        return userQuantaCount[_owner];
    }

    /// @notice Returns the owner of the Quanta with the given ID.
    /// @param quantaId The ID of the Quanta to query the owner of.
    /// @return The owner address.
    function ownerOf(uint256 quantaId) public view quantaExists(quantaId) returns (address) {
        return quantaById[quantaId].owner;
    }

    /// @notice Approves another address to transfer a specific Quanta.
    /// @param to The address to approve.
    /// @param quantaId The ID of the Quanta to approve.
    function approve(address to, uint256 quantaId) public quantaExists(quantaId) {
        address currentOwner = quantaById[quantaId].owner;
        if (msg.sender != currentOwner && !operatorApprovals[currentOwner][msg.sender]) {
            revert NotQuantaOwnerOrApproved(quantaId);
        }
        if (to == currentOwner) revert ApprovalToCurrentOwner();

        quantaById[quantaId].approved = to;
        emit Approval(currentOwner, to, quantaId);
    }

    /// @notice Get the approved address for a single Quanta.
    /// @param quantaId The ID of the Quanta to query.
    /// @return The approved address.
    function getApproved(uint256 quantaId) public view quantaExists(quantaId) returns (address) {
        return quantaById[quantaId].approved;
    }

    /// @notice Approve or revoke approval for an operator for all of sender's Quanta.
    /// @param operator The address to approve or revoke.
    /// @param approved Whether to approve or revoke.
    function setApprovalForAll(address operator, bool approved) public {
        if (operator == msg.sender) revert("Cannot approve self for all");
        operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /// @notice Check if an operator is approved for all of an owner's Quanta.
    /// @param _owner The owner address.
    /// @param operator The operator address.
    /// @return True if approved, false otherwise.
    function isApprovedForAll(address _owner, address operator) public view returns (bool) {
        return operatorApprovals[_owner][operator];
    }

    /// @notice Transfers ownership of a Quanta.
    /// @param from The current owner.
    /// @param to The new owner.
    /// @param quantaId The ID of the Quanta to transfer.
    function transferFrom(address from, address to, uint256 quantaId) public quantaExists(quantaId) {
        address currentOwner = quantaById[quantaId].owner;
        if (currentOwner != from) revert TransferFromIncorrectOwner();
        if (to == address(0)) revert TransferToZeroAddress();

        // Check approval: caller is owner, approved for single, or approved for all
        if (msg.sender != currentOwner && quantaById[quantaId].approved != msg.sender && !operatorApprovals[currentOwner][msg.sender]) {
            revert NotQuantaOwnerOrApproved(quantaId);
        }

        // Clear approval regardless of who initiated transfer
        if (quantaById[quantaId].approved != address(0)) {
             quantaById[quantaId].approved = address(0);
        }

        // Update ownership state
        userQuantaCount[from]--;
        quantaById[quantaId].owner = to;
        userQuantaCount[to]++;

        emit Transfer(from, to, quantaId);
    }

    // --- Quanta Lifecycle & Core Mechanics ---

    /// @notice Mints a new Quanta with initial traits.
    /// @dev Requires MINT_FEE to be sent with the transaction.
    /// @return The ID of the newly minted Quanta.
    function mintQuanta() public payable returns (uint256) {
        if (msg.value < MINT_FEE) revert InsufficientPayment(MINT_FEE, msg.value);

        uint256 quantaId = nextQuantaId;
        nextQuantaId++;
        uint64 currentTime = uint64(block.timestamp);

        // Generate initial traits - Basic example using time/block data
        uint256 traitCount = MIN_TRAITS + (block.timestamp % (MAX_TRAITS - MIN_TRAITS + 1));
        int256[] memory initialTraits = new int256[](traitCount);
        bytes32 randomness = keccak256(abi.encodePacked(block.timestamp, msg.sender, quantaId, block.difficulty)); // Basic randomness, not secure for high value
        for (uint i = 0; i < traitCount; i++) {
             initialTraits[i] = int256(uint256(keccak256(abi.encodePacked(randomness, i))) % 100) - 50; // Example range [-50, 49]
        }

        quantaById[quantaId] = Quanta({
            id: quantaId,
            owner: msg.sender,
            creationTime: currentTime,
            lastActionTime: currentTime,
            traits: initialTraits,
            currentQuestId: 0,
            questEndTime: 0,
            approved: address(0),
            isActive: true
        });

        userQuantaCount[msg.sender]++;

        emit QuantaMinted(quantaId, msg.sender, currentTime);

        // Transfer the mint fee to the owner
        (bool success, ) = owner.call{value: msg.value}("");
        require(success, "Fee transfer failed"); // Should not fail if owner is payable

        return quantaId;
    }

    /// @notice Gets the current state of a Quanta, applying any pending time-based evolution.
    /// @param quantaId The ID of the Quanta.
    /// @return The updated Quanta struct.
    function getQuanta(uint256 quantaId) public quantaExists(quantaId) returns (Quanta memory) {
        _applyTimeEvolution(quantaId);
        return quantaById[quantaId];
    }

    /// @notice Gets the current traits of a Quanta, applying any pending time-based evolution.
    /// @param quantaId The ID of the Quanta.
    /// @return The updated traits array.
    function getQuantaTraits(uint256 quantaId) public quantaExists(quantaId) returns (int256[] memory) {
        _applyTimeEvolution(quantaId);
        return quantaById[quantaId].traits;
    }

    /// @notice Explicitly triggers time-based evolution for a Quanta.
    /// @dev Requires Temporal Energy.
    /// @param quantaId The ID of the Quanta.
    function attuneQuantaToChronosphere(uint256 quantaId) public quantaExists(quantaId) isQuantaOwnerOrApproved(quantaId) {
        uint256 energyCost = 100; // Example cost
        if (userTemporalEnergy[msg.sender] < energyCost) revert InsufficientTemporalEnergy(energyCost, userTemporalEnergy[msg.sender]);

        _applyTimeEvolution(quantaId); // Evolution happens regardless of this call, but this costs energy to trigger it explicitly?
                                      // Let's make this function *only* cost energy and update time, the evolution is applied on *read* or quest completion.
                                      // Or better: make evolution happen on *any* state-changing interaction with the Quanta, and this is an explicit way to trigger state change and energy cost.
        uint64 currentTime = uint64(block.timestamp);
        quantaById[quantaId].lastActionTime = currentTime; // Update last action time
        userTemporalEnergy[msg.sender] -= energyCost;

        // Re-applying evolution here after updating lastActionTime would double-count time.
        // Stick to applying evolution only when needed (get/startQuest/completeQuest/interact/synthesize)

        // Let's re-think: Attunement is the *mechanism* that applies evolution and costs energy.
        // Evolution should *not* happen automatically on read, as that would be complex/expensive.
        // Evolution happens when `_applyTimeEvolution` is called, which this function does.
        _applyTimeEvolution(quantaId);

        // This function now costs energy and triggers the evolution calculation.
        // It's different from just viewing.
    }


    /// @notice Marks a Quanta as inactive (dispersed/burned).
    /// @dev Requires sender is owner or approved.
    /// @param quantaId The ID of the Quanta to disperse.
    function disperseQuanta(uint256 quantaId) public quantaExists(quantaId) isQuantaOwnerOrApproved(quantaId) {
        Quanta storage quanta = quantaById[quantaId];
        if (quanta.currentQuestId != 0) revert QuantaBusyOnQuest(quantaId);

        address currentOwner = quanta.owner;

        // Clear any pending approval
        if (quanta.approved != address(0)) {
             quanta.approved = address(0);
             emit Approval(currentOwner, address(0), quantaId);
        }
        // Note: operator approvals remain, but won't affect this inactive Quanta

        quanta.isActive = false; // Mark as inactive
        quanta.owner = address(0); // Set owner to zero address as convention for burned/inactive

        userQuantaCount[currentOwner]--;

        emit QuantaDispersed(quantaId, currentOwner);
        emit Transfer(currentOwner, address(0), quantaId); // ERC721 burn event convention
    }

    /// @dev Internal function to apply time-based evolution to Quanta traits.
    /// @param quantaId The ID of the Quanta.
    function _applyTimeEvolution(uint256 quantaId) internal {
        Quanta storage quanta = quantaById[quantaId];
        uint64 currentTime = uint64(block.timestamp);
        uint64 timeElapsed = currentTime - quanta.lastActionTime;

        if (timeElapsed == 0 || quanta.currentQuestId != 0) {
            // No time elapsed, or Quanta is busy on a quest (evolution paused)
            return;
        }

        // Simple example evolution: traits drift slightly over time
        // More complex logic could be based on specific trait values, external data, etc.
        bytes32 evolutionSeed = keccak256(abi.encodePacked(quantaId, currentTime, block.difficulty)); // Basic entropy
        uint256 traitCount = quanta.traits.length;

        for (uint i = 0; i < traitCount; i++) {
            // Example: Add or subtract a small random value based on time
            uint256 rand = uint256(keccak256(abi.encodePacked(evolutionSeed, i)));
            int256 evolutionChange = int256((rand % uint256(timeElapsed)) * 10 / (24 * 3600)); // Example: change scaled by days elapsed, max 10 per day
            if (rand % 2 == 0) evolutionChange = -evolutionChange; // Randomly make it negative

            quanta.traits[i] += evolutionChange;

            // Optional: Clamp trait values within a range [-100, 100]
            if (quanta.traits[i] > 100) quanta.traits[i] = 100;
            if (quanta.traits[i] < -100) quanta.traits[i] = -100;
        }

        quanta.lastActionTime = currentTime; // Update last action time after evolution
        emit QuantaEvolved(quantaId, quanta.traits);
    }


    // --- Temporal Energy System ---

    /// @notice Allows users to claim their accrued Temporal Energy.
    /// @dev Energy accrues passively since the last claim or relevant action.
    function claimTemporalEnergy() public {
        uint64 currentTime = uint64(block.timestamp);
        uint64 lastClaim = lastEnergyClaimTime[msg.sender];

        // Ensure lastClaim is initialized (first claim sets it)
        if (lastClaim == 0) {
            lastClaimTime[msg.sender] = currentTime;
            return; // No time elapsed yet
        }

        uint256 timeElapsed = currentTime - lastClaim;
        uint256 accrued = timeElapsed * TEMPORAL_ENERGY_RATE;

        if (accrued > 0) {
            userTemporalEnergy[msg.sender] += accrued;
            lastEnergyClaimTime[msg.sender] = currentTime;
            emit EnergyClaimed(msg.sender, accrued);
        }
    }

    /// @notice Views the Temporal Energy balance of a user.
    /// @param user The address to query.
    /// @return The user's current temporal energy amount.
    function getUserTemporalEnergy(address user) public view returns (uint256) {
        return userTemporalEnergy[user];
    }

    // --- Quest System ---

    /// @notice Creates a new type of Quest.
    /// @dev Only callable by the questMaster.
    /// @param name Name of the quest.
    /// @param duration Duration of the quest in seconds.
    /// @param energyCost Energy required to start the quest.
    /// @param traitModifiers Changes applied to Quanta traits upon completion. Must match trait count.
    /// @param rewardAmount Native token reward upon completion.
    /// @param requiredTraits Minimum trait values required to start. Must match trait count.
    /// @return The ID of the newly created Quest.
    function createQuest(
        string calldata name,
        uint64 duration,
        uint256 energyCost,
        int256[] calldata traitModifiers,
        uint256 rewardAmount,
        int256[] calldata requiredTraits
    ) public onlyQuestMaster returns (uint256) {
        if (traitModifiers.length < MIN_TRAITS || traitModifiers.length > MAX_TRAITS) {
            revert QuestModifierTraitCountMismatch(nextQuestId);
        }
        if (requiredTraits.length != traitModifiers.length) {
             revert RequiredTraitCountMismatch(nextQuestId);
        }

        uint256 questId = nextQuestId;
        nextQuestId++;

        questsById[questId] = Quest({
            id: questId,
            name: name,
            duration: duration,
            energyCost: energyCost,
            traitModifiers: traitModifiers,
            rewardAmount: rewardAmount,
            requiredTraits: requiredTraits
        });

        emit QuestCreated(questId, name, msg.sender);
        return questId;
    }

    /// @notice Gets the details of a specific Quest type.
    /// @param questId The ID of the Quest type.
    /// @return The Quest struct details.
    function getQuestDetails(uint256 questId) public view questExists(questId) returns (Quest memory) {
        return questsById[questId];
    }

    /// @notice Starts a Quest for a specific Quanta.
    /// @dev Requires Temporal Energy and Quanta must meet trait requirements.
    /// @param quantaId The ID of the Quanta.
    /// @param questId The ID of the Quest type.
    function startQuest(uint256 quantaId, uint256 questId) public quantaExists(quantaId) isQuantaOwnerOrApproved(quantaId) questExists(questId) {
        Quanta storage quanta = quantaById[quantaId];
        Quest storage quest = questsById[questId];

        if (quanta.currentQuestId != 0) revert QuantaBusyOnQuest(quantaId);
        if (userTemporalEnergy[msg.sender] < quest.energyCost) revert InsufficientTemporalEnergy(quest.energyCost, userTemporalEnergy[msg.sender]);
        if (quanta.traits.length != quest.requiredTraits.length) revert QuestRequirementsNotMet(quantaId, questId);

        // Check quest requirements
        for (uint i = 0; i < quanta.traits.length; i++) {
            if (quanta.traits[i] < quest.requiredTraits[i]) {
                revert QuestRequirementsNotMet(quantaId, questId);
            }
        }

        // Consume energy
        userTemporalEnergy[msg.sender] -= quest.energyCost;

        // Apply time evolution before starting the quest
        _applyTimeEvolution(quantaId);

        // Set quest state on Quanta
        uint64 currentTime = uint64(block.timestamp);
        quanta.currentQuestId = questId;
        quanta.questEndTime = currentTime + quest.duration;
        // lastActionTime is updated by _applyTimeEvolution just before setting quest state

        emit QuestStarted(quantaId, questId, currentTime, quanta.questEndTime);
    }

    /// @notice Completes a Quest for a Quanta if the duration has passed.
    /// @dev Transfers rewards and applies trait modifiers.
    /// @param quantaId The ID of the Quanta.
    function completeQuest(uint256 quantaId) public quantaExists(quantaId) isQuantaOwnerOrApproved(quantaId) {
        Quanta storage quanta = quantaById[quantaId];

        if (quanta.currentQuestId == 0) revert QuantaNotOnQuest(quantaId);
        if (block.timestamp < quanta.questEndTime) revert QuestNotComplete(quantaId);

        Quest storage quest = questsById[quanta.currentQuestId]; // Use the stored quest ID

        // Apply time evolution before applying quest modifiers
        _applyTimeEvolution(quantaId);

        // Apply trait modifiers from the quest
        uint256 traitCount = quanta.traits.length;
        if (traitCount != quest.traitModifiers.length) revert QuestModifierTraitCountMismatch(quest.id); // Should not happen if createQuest is correct

        int256[] memory appliedModifiers = new int256[](traitCount); // To emit
        for (uint i = 0; i < traitCount; i++) {
            int256 modifier = quest.traitModifiers[i];
            quanta.traits[i] += modifier;
            appliedModifiers[i] = modifier;

            // Optional: Clamp trait values
            if (quanta.traits[i] > 100) quanta.traits[i] = 100;
            if (quanta.traits[i] < -100) quanta.traits[i] = -100;
        }

        // Transfer reward
        if (quest.rewardAmount > 0) {
             (bool success, ) = payable(msg.sender).call{value: quest.rewardAmount}("");
             // Consider more robust error handling or re-queuing if transfer fails
             require(success, "Reward transfer failed");
        }

        // Reset quest state
        uint256 completedQuestId = quanta.currentQuestId;
        quanta.currentQuestId = 0;
        quanta.questEndTime = 0;
        // lastActionTime was updated by _applyTimeEvolution

        emit QuestCompleted(quantaId, completedQuestId, uint64(block.timestamp), quest.rewardAmount, appliedModifiers);
    }

    /// @notice Cancels a Quest for a Quanta before completion.
    /// @dev Potential energy or trait penalty could be added here.
    /// @param quantaId The ID of the Quanta.
    function cancelQuest(uint256 quantaId) public quantaExists(quantaId) isQuantaOwnerOrApproved(quantaId) {
        Quanta storage quanta = quantaById[quantaId];

        if (quanta.currentQuestId == 0) revert QuantaNotOnQuest(quantaId);
        if (block.timestamp >= quanta.questEndTime) revert QuestNotComplete(quantaId); // Cannot cancel if already completable

        uint256 cancelledQuestId = quanta.currentQuestId;

        // Optional: Apply penalty (e.g., trait decay, energy loss)
        // For simplicity, no penalty in this example.

        // Reset quest state
        quanta.currentQuestId = 0;
        quanta.questEndTime = 0;
        // lastActionTime remains whatever it was before starting the quest? Or update it now?
        // Let's update it now, as cancelling is an action.
        quanta.lastActionTime = uint64(block.timestamp);

        emit QuestCancelled(quantaId, cancelledQuestId, uint64(block.timestamp));
    }


    // --- Interaction & Synthesis ---

    /// @notice Allows a user to interact with any active Quanta.
    /// @dev Consumes energy and applies a minor, potentially random, trait change.
    /// @param quantaId The ID of the Quanta to interact with.
    function interactWithQuanta(uint256 quantaId) public quantaExists(quantaId) {
        Quanta storage quanta = quantaById[quantaId];

        uint256 energyCost = 50; // Example cost
        if (userTemporalEnergy[msg.sender] < energyCost) revert InsufficientTemporalEnergy(energyCost, userTemporalEnergy[msg.sender]);

        // Apply time evolution before interaction
        _applyTimeEvolution(quantaId);

        // Apply interaction effect - simple random change to one trait
        uint256 traitCount = quanta.traits.length;
        if (traitCount == 0) {
             quanta.lastActionTime = uint64(block.timestamp); // Still update time if no traits
             userTemporalEnergy[msg.sender] -= energyCost;
             emit QuantaInteracted(quantaId, msg.sender, new int256[](0)); // Emit empty changes if no traits
             return;
        }

        bytes32 interactionSeed = keccak256(abi.encodePacked(block.timestamp, msg.sender, quantaId, block.difficulty, userTemporalEnergy[msg.sender])); // Basic entropy
        uint256 targetTraitIndex = uint256(keccak256(interactionSeed)) % traitCount;
        int256 interactionChange = int256(uint256(keccak256(abi.encodePacked(interactionSeed, targetTraitIndex))) % 11) - 5; // Example change range [-5, 5]

        quanta.traits[targetTraitIndex] += interactionChange;

        // Optional: Clamp trait values
        if (quanta.traits[targetTraitIndex] > 100) quanta.traits[targetTraitIndex] = 100;
        if (quanta.traits[targetTraitIndex] < -100) quanta.traits[targetTraitIndex] = -100;

        // Update state
        quanta.lastActionTime = uint64(block.timestamp);
        userTemporalEnergy[msg.sender] -= energyCost;

        int256[] memory traitChanges = new int256[](traitCount); // Prepare array for event
        traitChanges[targetTraitIndex] = interactionChange;

        emit QuantaInteracted(quantaId, msg.sender, traitChanges);
    }

    /// @notice Synthesizes two Quanta into one, dispersing the source.
    /// @dev Combines traits. Requires sender is owner or approved for both.
    /// @param targetQuantaId The ID of the Quanta that will absorb traits.
    /// @param sourceQuantaId The ID of the Quanta that will be consumed.
    function synthesizeQuanta(uint256 targetQuantaId, uint256 sourceQuantaId) public quantaExists(targetQuantaId) quantaExists(sourceQuantaId) {
        if (targetQuantaId == sourceQuantaId) revert SourceAndTargetQuantaCannotBeSame();

        // Check ownership/approval for both
        isQuantaOwnerOrApproved(targetQuantaId); // Will revert if not authorized
        isQuantaOwnerOrApproved(sourceQuantaId); // Will revert if not authorized

        Quanta storage targetQuanta = quantaById[targetQuantaId];
        Quanta storage sourceQuanta = quantaById[sourceQuantaId];

        if (targetQuanta.currentQuestId != 0) revert QuantaBusyOnQuest(targetQuantaId);
        if (sourceQuanta.currentQuestId != 0) revert QuantaBusyOnQuest(sourceQuantaId);
        if (!sourceQuanta.isActive) revert CannotSynthesizeInactiveQuanta(); // Should be caught by quantaExists, but defensive

        uint256 energyCost = 500; // Example cost
        if (userTemporalEnergy[msg.sender] < energyCost) revert InsufficientTemporalEnergy(energyCost, userTemporalEnergy[msg.sender]);

        // Apply time evolution to both before synthesis
        _applyTimeEvolution(targetQuantaId);
        _applyTimeEvolution(sourceQuantaId);

        // Synthesis logic: Combine traits (Example: average common traits, add unique traits)
        uint256 targetTraitCount = targetQuanta.traits.length;
        uint256 sourceTraitCount = sourceQuanta.traits.length;
        uint256 commonTraitCount = targetTraitCount < sourceTraitCount ? targetTraitCount : sourceTraitCount;

        // Create new trait array based on the target's size
        int256[] memory newTraits = new int256[](targetTraitCount);

        // Copy and average common traits
        for (uint i = 0; i < commonTraitCount; i++) {
            // Simple average, could be weighted or more complex
            newTraits[i] = (targetQuanta.traits[i] + sourceQuanta.traits[i]) / 2;
        }

        // Copy remaining traits from target if target has more
        for (uint i = commonTraitCount; i < targetTraitCount; i++) {
            newTraits[i] = targetQuanta.traits[i];
        }

        // Assign new traits to target Quanta
        targetQuanta.traits = newTraits; // This copies the memory array back to storage

        // Disperse the source Quanta
        _disperseQuantaInternal(sourceQuantaId, sourceQuanta.owner); // Use internal helper to avoid re-checking permissions

        // Update state
        targetQuanta.lastActionTime = uint64(block.timestamp);
        userTemporalEnergy[msg.sender] -= energyCost;

        emit QuantaSynthesized(targetQuantaId, sourceQuantaId, msg.sender);
        // Disperse event is emitted by _disperseQuantaInternal
    }

     /// @dev Internal helper to disperse a Quanta without permission checks.
     /// @param quantaId The ID of the Quanta to disperse.
     /// @param currentOwner The current owner (for event).
    function _disperseQuantaInternal(uint256 quantaId, address currentOwner) internal {
        Quanta storage quanta = quantaById[quantaId];

        // Clear any pending approval
        if (quanta.approved != address(0)) {
             quanta.approved = address(0);
             emit Approval(currentOwner, address(0), quantaId);
        }

        quanta.isActive = false; // Mark as inactive
        quanta.owner = address(0); // Set owner to zero address

        userQuantaCount[currentOwner]--;

        emit QuantaDispersed(quantaId, currentOwner);
        emit Transfer(currentOwner, address(0), quantaId); // ERC721 burn event convention
    }


    // --- Admin/Configuration ---

    /// @notice Sets the address allowed to create new Quest types.
    /// @param _questMaster The new quest master address.
    function setQuestMaster(address _questMaster) public onlyOwner {
        questMaster = _questMaster;
    }

    /// @notice Sets the rate at which Temporal Energy accrues per second.
    /// @param rate The new energy rate per second.
    function setTemporalEnergyRate(uint256 rate) public onlyOwner {
        TEMPORAL_ENERGY_RATE = rate;
    }

    /// @notice Sets the fee required to mint a new Quanta.
    /// @param fee The new mint fee in native token (wei).
    function setMintFee(uint256 fee) public onlyOwner {
        MINT_FEE = fee;
    }

    /// @notice Sets the minimum and maximum allowed size for Quanta trait arrays.
    /// @param min The minimum trait count.
    /// @param max The maximum trait count.
    function setTraitBounds(uint256 min, uint256 max) public onlyOwner {
        if (min == 0 || max == 0 || min > max) revert InvalidTraitCount();
        MIN_TRAITS = min;
        MAX_TRAITS = max;
    }

    /// @notice Allows the protocol owner to withdraw accumulated mint fees.
    function withdrawProtocolFees() public onlyOwner {
        uint256 balance = address(this).balance;
        // Subtract any potential rewards awaiting distribution if this contract holds rewards long-term.
        // In this design, rewards are sent directly on completion, so contract balance should only be mint fees.
        if (balance > 0) {
            (bool success, ) = owner.call{value: balance}("");
            require(success, "Withdrawal failed");
        }
    }

    /// @notice Gets various global protocol parameters.
    /// @return Global parameters: (owner, questMaster, nextQuantaId, nextQuestId, MINT_FEE, TEMPORAL_ENERGY_RATE, MIN_TRAITS, MAX_TRAITS)
    function getProtocolState() public view returns (address, address, uint256, uint256, uint256, uint256, uint256, uint256) {
        return (
            owner,
            questMaster,
            nextQuantaId,
            nextQuestId,
            MINT_FEE,
            TEMPORAL_ENERGY_RATE,
            MIN_TRAITS,
            MAX_TRAITS
        );
    }

     // --- Fallback/Receive for Fee Collection ---
    receive() external payable {}
    fallback() external payable {}

    // --- Custom Error for Ownable-like behavior ---
    // Replacing standard Ownable to avoid inheritance and keep it self-contained
    error OwnableUnauthorizedAccount(address account);

}
```