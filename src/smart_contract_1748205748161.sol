Okay, let's design a smart contract that embodies a dynamic, self-evolving digital ecosystem. We'll create "SyntheTech Organisms" (Synths) as NFTs (ERC-721) that consume and produce "Nutrient Essence" (NE) as an ERC-20 token. Synths will have states, can interact, evolve, mutate, and their activities can influence user reputation within the ecosystem. This involves combining token standards with complex state logic and probabilistic outcomes.

We will implement minimal versions of ERC-20 and ERC-721 within this contract to avoid *directly* importing and duplicating standard open-source libraries like OpenZeppelin, while still providing the expected interfaces. This approach (implementing inline) is generally NOT recommended for production systems due to security risks and lack of battle-testing compared to standard libraries, but it fits the request to avoid direct duplication for a creative exercise.

---

### Outline and Function Summary

**Contract Name:** SyntheTechEcosystem

**Concept:** A decentralized simulation/game where users control "SyntheTech Organisms" (Synths - ERC-721 NFTs) that live within an ecosystem, consuming and producing "Nutrient Essence" (NE - ERC-20 token). Synths have dynamic states, interact with each other, can evolve and mutate probabilistically, and contribute to or detract from controller reputation based on outcomes.

**Core Components:**
1.  **SyntheTech Organisms (Synths):** Non-fungible tokens (ERC-721) representing individual entities. Each Synth has unique attributes (ID, generation, type, state, resources held, reputation score, mutation history, timers).
2.  **Nutrient Essence (NE):** Fungible token (ERC-20) representing the vital resource of the ecosystem. Synths consume NE to grow, reproduce, mutate, and perform actions. Synths in productive states generate NE.
3.  **User Reputation:** A score tracked for each user/controller, influenced by the success/failure of their Synths' actions (reproduction, mutation, interactions). High reputation may grant advantages or influence probabilities.
4.  **Synth States:** An enum defining the lifecycle stages of a Synth (e.g., Dormant, Growing, Active, Producing, ReproductionReady, MutationReady, Interacting, Degenerating).
5.  **Game Parameters:** Admin-adjustable values that balance the ecosystem dynamics (e.g., resource costs, production rates, probability weights).

**Key Dynamics:**
*   **Creation:** Genesis Synths can be created initially (maybe by admin or during a specific phase). New Synths are primarily created through successful reproduction attempts.
*   **Resource Management:** Synths consume NE over time or for actions; Synths in certain states produce NE that can be claimed by the owner. Users must feed their Synths NE.
*   **State Transitions:** Synths transition between states based on time, resource levels, successful actions, or external calls (`progressSynthState`, `feedSynth`).
*   **Interactions:** Synths can attempt interactions with other Synths (e.g., Symbiosis, Competition), requiring resources and involving probabilistic outcomes influenced by reputation and Synth attributes.
*   **Evolution & Mutation:** Synths in specific states can attempt evolution (advance generation, gain traits) or mutation (change type, gain unique properties). These are probabilistic and influenced by resources and reputation.
*   **Degeneration:** Synths that are unfed or fail repeatedly may enter a degenerating state and eventually be lost (burned).

**Function Summary (Grouped):**

**I. Core Ecosystem & Admin (3 functions)**
1.  `constructor()`: Initializes the contract, sets admin, mints initial NE supply, potentially creates initial genesis parameters.
2.  `setGameParameter(string memory paramName, uint256 value)`: Admin function to adjust balancing parameters.
3.  `getGameParameter(string memory paramName)`: Query function to retrieve a parameter value.

**II. Nutrient Essence (NE - ERC-20 Minimal Implementation - 8 functions)**
4.  `name() external view returns (string memory)`: ERC-20 standard: Returns token name.
5.  `symbol() external view returns (string memory)`: ERC-20 standard: Returns token symbol.
6.  `decimals() external view returns (uint8)`: ERC-20 standard: Returns token decimals.
7.  `totalSupply() external view returns (uint256)`: ERC-20 standard: Returns total supply of NE.
8.  `balanceOf(address account) external view returns (uint256)`: ERC-20 standard: Returns account NE balance.
9.  `transfer(address recipient, uint256 amount) external returns (bool)`: ERC-20 standard: Transfers NE.
10. `approve(address spender, uint256 amount) external returns (bool)`: ERC-20 standard: Approves spender.
11. `transferFrom(address sender, address recipient, uint256 amount) external returns (bool)`: ERC-20 standard: Transfers NE using allowance.

**III. SyntheTech Organisms (Synths - ERC-721 Minimal Implementation - 8 functions)**
12. `balanceOf(address owner) public view returns (uint256)`: ERC-721 standard: Returns number of Synths owned by address.
13. `ownerOf(uint256 tokenId) public view returns (address)`: ERC-721 standard: Returns owner of a Synth.
14. `transferFrom(address from, address to, uint256 tokenId) public`: ERC-721 standard: Transfers ownership.
15. `safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public`: ERC-721 standard: Safe transfer variant.
16. `safeTransferFrom(address from, address to, uint256 tokenId) public`: ERC-721 standard: Safe transfer variant.
17. `approve(address to, uint256 tokenId) public`: ERC-721 standard: Approves address to manage Synth.
18. `setApprovalForAll(address operator, bool approved) public`: ERC-721 standard: Sets operator approval for all owner's Synths.
19. `getApproved(uint256 tokenId) public view returns (address)`: ERC-721 standard: Gets approved address for a Synth.
20. `isApprovedForAll(address owner, address operator) public view returns (bool)`: ERC-721 standard: Checks operator approval.

**IV. Synth Lifecycle & Management (11 functions)**
21. `createGenesisSynth(address owner)`: Admin function to mint initial Synths (Generation 0).
22. `getSynthDetails(uint256 synthId) external view returns (...)`: Query function to retrieve full details of a Synth.
23. `feedSynth(uint256 synthId, uint256 amount)`: User provides NE to a Synth, influencing its state and potentially growth.
24. `claimPendingNutrients(uint256 synthId)`: Owner claims NE produced by their Synth.
25. `attemptReproduction(uint256 parentSynthId)`: Initiates a reproduction attempt, consuming resources and potentially creating a new Synth.
26. `attemptMutation(uint256 synthId)`: Initiates a mutation attempt, consuming resources and potentially changing Synth attributes.
27. `burnSynth(uint256 synthId)`: Removes a Synth from existence (e.g., due to degeneration or user action).
28. `progressSynthState(uint256 synthId)`: Allows anyone to trigger a check and potential update of a Synth's state based on time and internal conditions (consuming gas).
29. `triggerNutrientProduction(uint256 synthId)`: Internal helper (or external if needed) to calculate and add pending NE production.
30. `checkSynthStateConditions(uint256 synthId)`: Internal helper to evaluate if state transitions or time-based effects should occur.
31. `updateReputation(address user, int256 reputationChange)`: Internal helper to modify user reputation based on Synth outcomes.

**V. Synth Interactions (3 functions)**
32. `initiateSymbioticBond(uint256 synth1Id, uint256 synth2Id)`: Attempts to create a symbiotic relationship between two Synths (potentially owned by different users), requiring mutual consent (approvals) and resources. Affects states and potentially production/reputation.
33. `dissolveSymbioticBond(uint256 synthId)`: Dissolves an existing symbiotic bond.
34. `initiateCompetitiveInteraction(uint256 attackerSynthId, uint256 targetSynthId)`: Attempts a competitive interaction, consuming resources, involving probabilistic outcomes (resource transfer, state change, reputation change) based on attributes. Requires target owner approval? (Let's make it open but with consequences).

**VI. Query & Reputation (2 functions)**
35. `getUserReputation(address user) external view returns (int256)`: Query user's reputation score.
36. `getSynthPendingNutrients(uint256 synthId) external view returns (uint256)`: Query NE pending claim for a Synth.

**(Total Functions: 36)**

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// --- Outline and Function Summary Above ---

/// @title SyntheTechEcosystem
/// @dev A smart contract implementing a dynamic digital ecosystem with ERC-721 Organisms (Synths)
/// @dev and ERC-20 Resources (Nutrient Essence), featuring state dynamics, interactions,
/// @dev evolution, mutation, and user reputation. Minimal ERC-20/ERC-721 implemented inline.
contract SyntheTechEcosystem {

    // --- Errors ---
    error NotAdmin();
    error InsufficientBalance(uint256 required, uint256 current);
    error InsufficientAllowance(uint256 required, uint256 current);
    error TokenDoesNotExist(uint256 tokenId);
    error TokenAlreadyExists(uint256 tokenId);
    error NotTokenOwner(address caller, uint256 tokenId);
    error TransferToZeroAddress();
    error ApproveToOwner();
    error CannotOperateOnZeroAddress();
    error InvalidParameter();
    error InvalidAmount();
    error SynthNotInValidState(uint256 synthId, SynthState currentState, string memory requiredState);
    error SynthsAlreadyBonded(uint256 synth1Id, uint256 synth2Id);
    error SynthsNotBonded(uint256 synthId);
    error InteractionRequiresTwoSynths();
    error CannotInteractWithSelf();
    error CannotBondWithSelf();
    error BondingRequiresApproval(uint256 synthId);
    error AdminGenesisOnly();
    error ReproductionNotReady(uint256 synthId);
    error MutationNotReady(uint256 synthId);
    error NothingToClaim(uint256 synthId);


    // --- Enums ---
    enum SynthState {
        Dormant,          // Inactive, consumes minimal, produces nothing
        Growing,          // Actively consuming resources to grow
        Active,           // Baseline state, consumes moderate, might produce
        Producing,        // Focused on resource production
        ReproductionReady, // Ready to attempt reproduction
        MutationReady,    // Ready to attempt mutation
        Interacting,      // Temporarily in an interaction process
        Degenerating      // Losing health/state due to lack of resources or failure
    }

    // --- Structs ---
    struct Synth {
        uint256 id;
        address owner; // ERC721 owner
        uint256 generation;
        uint256 synthType; // Simple type indicator (e.g., 0, 1, 2)
        SynthState state;
        uint256 resourcesHeld; // NE directly assigned to this synth
        int256 intrinsicReputation; // Reputation earned/lost by this specific synth's actions
        uint64 creationTime;
        uint64 lastUpdateTime;
        uint256 pendingNutrients; // NE produced but not yet claimed
        uint256 bondedSynthId; // ID of synth bonded symbiotically (0 if none)
        // Add more complex attributes here if needed (e.g., genes, traits, interaction history)
    }

    // --- State Variables ---
    address public admin;
    uint256 private _synthCounter;
    uint256 private _nutrientSupply; // Total supply of NE

    // ERC-20 Balances and Allowances
    mapping(address => uint256) private _nutrientBalances;
    mapping(address => mapping(address => uint256)) private _nutrientAllowances;

    // ERC-721 Token Ownership
    mapping(uint256 => address) private _synthOwners;
    mapping(address => uint256) private _synthBalances;
    mapping(uint256 => address) private _synthApprovals;
    mapping(address => mapping(address => bool)) private _synthOperatorApprovals;

    // Synth Data
    mapping(uint256 => Synth) private _synths;

    // User Reputation (Separate from Synth intrinsicReputation)
    mapping(address => int256) public userReputation; // Global reputation for a user

    // Game Parameters
    mapping(string => uint256) public gameParameters;

    // --- Events ---
    event NutrientTransfer(address indexed from, address indexed to, uint256 value);
    event NutrientApproval(address indexed owner, address indexed spender, uint256 value);
    event SynthTransfer(address indexed from, address indexed to, uint256 tokenId);
    event SynthApproval(address indexed owner, address indexed approved, uint256 tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event SynthCreated(uint256 indexed synthId, address indexed owner, uint256 generation, uint256 synthType);
    event SynthStateChanged(uint256 indexed synthId, SynthState oldState, SynthState newState);
    event SynthFed(uint256 indexed synthId, address indexed feeder, uint256 amount);
    event NutrientsClaimed(uint256 indexed synthId, address indexed owner, uint256 amount);
    event ReproductionAttempt(uint256 indexed parentSynthId, address indexed owner);
    event ReproductionSuccess(uint256 indexed parentSynthId, uint256 indexed childSynthId, address indexed owner);
    event MutationAttempt(uint256 indexed synthId, address indexed owner);
    event MutationSuccess(uint256 indexed synthId, uint256 newSynthType); // Simplified mutation event
    event SynthBurned(uint256 indexed synthId, address indexed owner);
    event SymbioticBondAttempt(uint256 indexed synth1Id, uint256 indexed synth2Id, address indexed caller);
    event SymbioticBondCreated(uint256 indexed synth1Id, uint256 indexed synth2Id);
    event SymbioticBondDissolved(uint256 indexed synth1Id, uint256 indexed synth2Id);
    event CompetitiveInteractionAttempt(uint256 indexed attackerSynthId, uint256 indexed targetSynthId, address indexed caller);
    event CompetitiveInteractionOutcome(uint256 indexed synth1Id, uint256 indexed synth2Id, bool successForSynth1, int256 reputationChange);
    event UserReputationChanged(address indexed user, int256 oldReputation, int256 newReputation);
    event GameParameterSet(string paramName, uint256 value);


    // --- Constructor ---
    constructor(uint256 initialNutrientSupply, uint256 initialGenesisSynths) {
        admin = msg.sender;
        _nutrientSupply = initialNutrientSupply;
        _nutrientBalances[msg.sender] = initialNutrientSupply; // Mint initial supply to admin

        // Set some default game parameters
        gameParameters["genesisCostNE"] = 100; // Cost to create a genesis synth (if enabled later)
        gameParameters["feedGrowthAmount"] = 50; // NE needed per feed to trigger growth chance
        gameParameters["growthCostNE"] = 20; // NE consumed during growth phase per update
        gameParameters["productionRateNE"] = 5; // NE produced per producing-state update
        gameParameters["reproductionCostNE"] = 100; // NE cost to attempt reproduction
        gameParameters["mutationCostNE"] = 80; // NE cost to attempt mutation
        gameParameters["symbiosisCostNE"] = 120; // NE cost per pair to attempt symbiosis
        gameParameters["competitionCostNE"] = 60; // NE cost for attacker to attempt competition
        gameParameters["degenerationThreshold"] = 10; // Resource threshold below which degeneration starts
        gameParameters["reproductionSuccessChance"] = 60; // Base chance (%)
        gameParameters["mutationSuccessChance"] = 40; // Base chance (%)
        gameParameters["symbiosisSuccessChance"] = 70; // Base chance (%)
        gameParameters["competitionSuccessChance"] = 50; // Base chance (%)
        gameParameters["reproductionMinReputation"] = 50; // Min user reputation required for reproduction
        gameParameters["mutationMinReputation"] = 30; // Min user reputation required for mutation
        gameParameters["interactionMinReputation"] = 20; // Min user reputation required for interactions
        gameParameters["reputationChangeSuccessLarge"] = 20; // Rep change on large success (e.g. repro/mutation)
        gameParameters["reputationChangeSuccessSmall"] = 5; // Rep change on small success (e.g. interaction)
        gameParameters["reputationChangeFailureLarge"] = -15; // Rep change on large failure
        gameParameters["reputationChangeFailureSmall"] = -5; // Rep change on small failure
        gameParameters["minTimeBetweenUpdates"] = 60; // Min time (seconds) between state updates via progressSynthState
        gameParameters["minTimeInState_Growing"] = 300; // Min time in state before transition check
        gameParameters["minTimeInState_Producing"] = 600;
        gameParameters["minTimeInState_ReproductionReady"] = 120;
        gameParameters["minTimeInState_MutationReady"] = 120;
        gameParameters["minTimeInState_Degenerating"] = 3600; // Synth burns after this time in degenerating

        // Mint initial genesis synths
        for (uint256 i = 0; i < initialGenesisSynths; i++) {
            _createSynth(msg.sender, 0, uint256(uint8(i % 3))); // Gen 0, initial types 0, 1, 2
        }
    }

    // --- Modifiers ---
    modifier onlyAdmin() {
        if (msg.sender != admin) revert NotAdmin();
        _;
    }

    // --- Utility Functions (Internal/Pure/View Helpers) ---
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _synthOwners[tokenId] != address(0);
    }

    function _safeMint(address to, uint256 tokenId) internal {
        if (_exists(tokenId)) revert TokenAlreadyExists(tokenId);
        if (to == address(0)) revert CannotOperateOnZeroAddress();

        _synthOwners[tokenId] = to;
        _synthBalances[to]++;
        emit SynthCreated(tokenId, to, _synths[tokenId].generation, _synths[tokenId].synthType); // Emit creation event here too
        emit SynthTransfer(address(0), to, tokenId); // ERC721 Transfer event for minting
    }

    function _burn(uint256 tokenId) internal {
        address owner = _synthOwners[tokenId];
        if (owner == address(0)) revert TokenDoesNotExist(tokenId);

        // Clear approvals
        delete _synthApprovals[tokenId];
        // Note: Operator approvals remain, apply to future tokens

        _synthBalances[owner]--;
        delete _synthOwners[tokenId];
        delete _synths[tokenId]; // Remove synth data

        emit SynthBurned(tokenId, owner);
        emit SynthTransfer(owner, address(0), tokenId); // ERC721 Transfer event for burning
    }

    function _transfer(address from, address to, uint256 tokenId) internal {
        if (ownerOf(tokenId) != from) revert NotTokenOwner(from, tokenId); // Should not happen if called internally correctly
        if (to == address(0)) revert TransferToZeroAddress();

        // Clear approvals
        delete _synthApprovals[tokenId];

        _synthBalances[from]--;
        _synthBalances[to]++;
        _synthOwners[tokenId] = to;

        _synths[tokenId].owner = to; // Update owner in the Synth struct too

        emit SynthTransfer(from, to, tokenId);
    }

    function _checkApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

     function _mintNutrients(address to, uint256 amount) internal {
        _nutrientSupply += amount;
        _nutrientBalances[to] += amount;
        emit NutrientTransfer(address(0), to, amount); // ERC20 Transfer event for minting
    }

    function _burnNutrients(address from, uint256 amount) internal {
        if (_nutrientBalances[from] < amount) revert InsufficientBalance(amount, _nutrientBalances[from]);
         _nutrientSupply -= amount;
        _nutrientBalances[from] -= amount;
        emit NutrientTransfer(from, address(0), amount); // ERC20 Transfer event for burning
    }

    function _transferNutrients(address from, address to, uint256 amount) internal {
        if (_nutrientBalances[from] < amount) revert InsufficientBalance(amount, _nutrientBalances[from]);
        if (to == address(0)) revert TransferToZeroAddress();

        _nutrientBalances[from] -= amount;
        _nutrientBalances[to] += amount;
        emit NutrientTransfer(from, to, amount);
    }

    function _createSynth(address owner, uint256 generation, uint256 synthType) internal returns (uint256 newSynthId) {
        _synthCounter++;
        newSynthId = _synthCounter;

        Synth storage newSynth = _synths[newSynthId];
        newSynth.id = newSynthId;
        newSynth.owner = owner;
        newSynth.generation = generation;
        newSynth.synthType = synthType; // Simple type for now
        newSynth.state = SynthState.Dormant; // Starts dormant
        newSynth.resourcesHeld = 0;
        newSynth.intrinsicReputation = 0;
        newSynth.creationTime = uint64(block.timestamp);
        newSynth.lastUpdateTime = uint64(block.timestamp);
        newSynth.pendingNutrients = 0;
        newSynth.bondedSynthId = 0;

        _safeMint(owner, newSynthId); // Handles ERC721 minting and events
        // SynthCreated event is emitted in _safeMint
        return newSynthId;
    }

    function _updateReputation(address user, int256 reputationChange) internal {
        int256 oldRep = userReputation[user];
        userReputation[user] += reputationChange;
        emit UserReputationChanged(user, oldRep, userReputation[user]);
    }

    function _getPseudoRandomUint(uint256 seed) internal view returns (uint256) {
        // WARNING: This is for demonstration only. On-chain randomness without oracles
        // is susceptible to miner/validator manipulation.
        return uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, seed)));
    }

     function _getGameParameter(string memory paramName) internal view returns (uint256) {
        uint256 value = gameParameters[paramName];
        // Basic check if parameter exists and is non-zero, prevents relying on un-set parameters
        // For production, would need more robust default handling or require all params set.
        if (value == 0 && keccak256(abi.encodePacked(paramName)) != keccak256(abi.encodePacked("genesisCostNE"))) { // Allow 0 for genesisCostNE if needed
             revert InvalidParameter(); // Or return a default/handle internally
        }
        return value;
    }


    // --- I. Core Ecosystem & Admin ---

    /// @dev Admin function to set ecosystem parameters.
    /// @param paramName The name of the parameter (e.g., "productionRateNE").
    /// @param value The new value for the parameter.
    function setGameParameter(string memory paramName, uint256 value) external onlyAdmin {
        gameParameters[paramName] = value;
        emit GameParameterSet(paramName, value);
    }

    /// @dev Query function to get the value of an ecosystem parameter.
    /// @param paramName The name of the parameter.
    /// @return The value of the parameter.
    function getGameParameter(string memory paramName) external view returns (uint256) {
        return _getGameParameter(paramName);
    }

    /// @dev Admin function to create the initial generation of Synths.
    /// @param owner The address to mint the genesis Synth to.
    /// @notice This function is typically called only during contract initialization or a specific event.
    function createGenesisSynth(address owner) external onlyAdmin {
        // Add checks to ensure this is only callable during specific phases if necessary
        // For this example, simply requires admin role.
        _createSynth(owner, 0, _getPseudoRandomUint(_synthCounter) % 3); // Random initial type
    }

    // --- II. Nutrient Essence (NE - ERC-20 Minimal Implementation) ---

    function name() external view returns (string memory) { return "Nutrient Essence"; }
    function symbol() external view returns (string memory) { return "NE"; }
    function decimals() external view returns (uint8) { return 18; } // Standard decimals

    function totalSupply() external view returns (uint256) {
        return _nutrientSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _nutrientBalances[account];
    }

    function transfer(address recipient, uint256 amount) external returns (bool) {
        _transferNutrients(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        _nutrientAllowances[msg.sender][spender] = amount;
        emit NutrientApproval(msg.sender, spender, amount);
        return true;
    }

    function allowance(address owner, address spender) external view returns (uint256) {
        return _nutrientAllowances[owner][spender];
    }

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
        uint256 currentAllowance = _nutrientAllowances[sender][msg.sender];
        if (currentAllowance < amount) revert InsufficientAllowance(amount, currentAllowance);

        _transferNutrients(sender, recipient, amount);

        unchecked {
            _nutrientAllowances[sender][msg.sender] = currentAllowance - amount;
        }
        emit NutrientApproval(sender, msg.sender, _nutrientAllowances[sender][msg.sender]); // Update allowance event

        return true;
    }


    // --- III. SyntheTech Organisms (Synths - ERC-721 Minimal Implementation) ---

    // balanceOf(address owner) - Implemented above for ERC-20, need overload for ERC-721
    function balanceOf(address owner) public view override(SyntheTechEcosystem) returns (uint256) {
         if (owner == address(0)) revert CannotOperateOnZeroAddress();
         return _synthBalances[owner];
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _synthOwners[tokenId];
        if (owner == address(0)) revert TokenDoesNotExist(tokenId);
        return owner;
    }

    // approve(address to, uint256 tokenId) - Implemented above for ERC-20, need overload
    function approve(address to, uint256 tokenId) public override(SyntheTechEcosystem) {
        address owner = ownerOf(tokenId); // Implicitly checks if token exists
        if (msg.sender != owner && !isApprovedForAll(owner, msg.sender)) revert NotTokenOwner(msg.sender, tokenId);
        if (to == owner) revert ApproveToOwner();

        _synthApprovals[tokenId] = to;
        emit SynthApproval(owner, to, tokenId);
    }


    function getApproved(uint256 tokenId) public view returns (address) {
        if (!_exists(tokenId)) revert TokenDoesNotExist(tokenId);
        return _synthApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public {
        if (operator == msg.sender) revert CannotOperateOnZeroAddress(); // Should be != msg.sender, not zero address
        _synthOperatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _synthOperatorApprovals[owner][operator];
    }

    // transferFrom(address from, address to, uint256 tokenId) - Implemented above for ERC-20, need overload
    function transferFrom(address from, address to, uint256 tokenId) public override(SyntheTechEcosystem) {
        if (!_checkApprovedOrOwner(msg.sender, tokenId)) revert NotTokenOwner(msg.sender, tokenId);
        _transfer(from, to, tokenId); // Internal transfer logic
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public {
        if (!_checkApprovedOrOwner(msg.sender, tokenId)) revert NotTokenOwner(msg.sender, tokenId);
         address owner = ownerOf(tokenId); // Checks existence
         if (owner != from) revert NotTokenOwner(from, tokenId); // Ensure 'from' is correct owner

        _transfer(from, to, tokenId); // Internal transfer logic

        // ERC721Receiver check is skipped for this minimal implementation
        // A full ERC721 implementation would call onERC721Received
        // if the recipient is a contract.
    }


    // --- IV. Synth Lifecycle & Management ---

    /// @dev Gets the detailed state of a specific Synth.
    /// @param synthId The ID of the Synth.
    /// @return Synth struct details.
    function getSynthDetails(uint256 synthId) external view returns (Synth memory) {
        if (!_exists(synthId)) revert TokenDoesNotExist(synthId);
        return _synths[synthId];
    }

    /// @dev Allows a user to feed a Synth with Nutrient Essence.
    /// @param synthId The ID of the Synth to feed.
    /// @param amount The amount of NE to feed.
    /// @notice NE is transferred from the caller to the contract, added to the synth's held resources.
    function feedSynth(uint256 synthId, uint256 amount) external {
        Synth storage synth = _synths[synthId];
        if (!_exists(synthId)) revert TokenDoesNotExist(synthId);
        // No owner check here - anyone can feed a public synth! (Creative choice)
        if (amount == 0) revert InvalidAmount();

        _transferNutrients(msg.sender, address(this), amount);
        synth.resourcesHeld += amount;

        emit SynthFed(synthId, msg.sender, amount);

        // Optionally trigger state check after feeding
        _checkSynthStateConditions(synthId);
    }

    /// @dev Allows a Synth owner to claim pending Nutrient Essence produced by their Synth.
    /// @param synthId The ID of the Synth.
    function claimPendingNutrients(uint256 synthId) external {
        Synth storage synth = _synths[synthId];
        if (!_exists(synthId)) revert TokenDoesNotExist(synthId);
        if (msg.sender != synth.owner) revert NotTokenOwner(msg.sender, synthId);

        // First, update state to potentially calculate more pending nutrients
        _checkSynthStateConditions(synthId); // This might increase pendingNutrients

        uint256 amountToClaim = synth.pendingNutrients;
        if (amountToClaim == 0) revert NothingToClaim(synthId);

        synth.pendingNutrients = 0;
        // Transfer from contract balance to owner
        _transferNutrients(address(this), msg.sender, amountToClaim);

        emit NutrientsClaimed(synthId, msg.sender, amountToClaim);
    }

    /// @dev Attempts for a Synth to reproduce, potentially creating a new Synth.
    /// @param parentSynthId The ID of the Synth attempting reproduction.
    /// @notice This consumes resources and has a probabilistic outcome.
    function attemptReproduction(uint256 parentSynthId) external {
        Synth storage parentSynth = _synths[parentSynthId];
        if (!_exists(parentSynthId)) revert TokenDoesNotExist(parentSynthId);
        if (msg.sender != parentSynth.owner) revert NotTokenOwner(msg.sender, parentSynthId);

        // Trigger state check to ensure state is up-to-date
        _checkSynthStateConditions(parentSynthId);

        uint256 reproductionCost = _getGameParameter("reproductionCostNE");
        uint256 successChance = _getGameParameter("reproductionSuccessChance");
        uint256 minReputation = _getGameParameter("reproductionMinReputation");
        int256 repChangeSuccess = int256(_getGameParameter("reputationChangeSuccessLarge"));
        int256 repChangeFailure = -1 * int256(_getGameParameter("reputationChangeFailureLarge"));

        if (parentSynth.resourcesHeld < reproductionCost) revert InsufficientBalance(reproductionCost, parentSynth.resourcesHeld);
        if (userReputation[msg.sender] < int256(minReputation)) revert ReproductionNotReady(parentSynthId); // Check user reputation

        // Check state is ReproductionReady or similar
        if (parentSynth.state != SynthState.ReproductionReady && parentSynth.state != SynthState.Active) { // Allow from Active too? Or only Ready? Let's enforce Ready.
             revert SynthNotInValidState(parentSynthId, parentSynth.state, "ReproductionReady");
        }


        parentSynth.resourcesHeld -= reproductionCost;
        emit ReproductionAttempt(parentSynthId, msg.sender);

        uint256 randomValue = _getPseudoRandomUint(parentSynthId);

        if (randomValue % 100 < successChance) {
            // Success
            uint256 childSynthId = _createSynth(
                msg.sender,
                parentSynth.generation + 1,
                (parentSynth.synthType + (randomValue % 3)) % 5 // Example: child type influenced by parent and randomness
            );
            parentSynth.intrinsicReputation += repChangeSuccess; // Parent synth gains rep
            _updateReputation(msg.sender, repChangeSuccess); // User gains rep
            emit ReproductionSuccess(parentSynthId, childSynthId, msg.sender);

            // Parent might go Dormant or Active after success
            _transitionState(parentSynthId, SynthState.Dormant); // Or Active, based on design
        } else {
            // Failure
            parentSynth.intrinsicReputation += repChangeFailure; // Parent synth loses rep
            _updateReputation(msg.sender, repChangeFailure); // User loses rep
            // Failure might lead to state change or resource loss beyond cost
            _transitionState(parentSynthId, SynthState.Dormant); // Or Degenerating?
        }

         parentSynth.lastUpdateTime = uint64(block.timestamp); // Reset timer after action
    }

    /// @dev Attempts for a Synth to mutate, potentially changing its type or attributes.
    /// @param synthId The ID of the Synth attempting mutation.
    /// @notice This consumes resources and has a probabilistic outcome.
    function attemptMutation(uint256 synthId) external {
        Synth storage synth = _synths[synthId];
        if (!_exists(synthId)) revert TokenDoesNotExist(synthId);
        if (msg.sender != synth.owner) revert NotTokenOwner(msg.sender, synthId);

        // Trigger state check
        _checkSynthStateConditions(synthId);

        uint256 mutationCost = _getGameParameter("mutationCostNE");
        uint256 successChance = _getGameParameter("mutationSuccessChance");
        uint256 minReputation = _getGameParameter("mutationMinReputation");
         int256 repChangeSuccess = int256(_getGameParameter("reputationChangeSuccessLarge"));
        int256 repChangeFailure = -1 * int256(_getGameParameter("reputationChangeFailureLarge"));


        if (synth.resourcesHeld < mutationCost) revert InsufficientBalance(mutationCost, synth.resourcesHeld);
        if (userReputation[msg.sender] < int256(minReputation)) revert MutationNotReady(synthId); // Check user reputation

        // Check state is MutationReady
         if (synth.state != SynthState.MutationReady && synth.state != SynthState.Active) { // Allow from Active too?
             revert SynthNotInValidState(synthId, synth.state, "MutationReady");
        }

        synth.resourcesHeld -= mutationCost;
        emit MutationAttempt(synthId, msg.sender);

        uint256 randomValue = _getPseudoRandomUint(synthId);

        if (randomValue % 100 < successChance) {
            // Success
            uint256 newSynthType = (synth.synthType + 1 + (randomValue % 2)) % 5; // Example: Mutate to a new type
            synth.synthType = newSynthType; // Update synth type
            synth.intrinsicReputation += repChangeSuccess;
            _updateReputation(msg.sender, repChangeSuccess);
            emit MutationSuccess(synthId, newSynthType);

            // Synth might go Dormant or Active after success
            _transitionState(synthId, SynthState.Dormant);
        } else {
            // Failure
            synth.intrinsicReputation += repChangeFailure;
            _updateReputation(msg.sender, repChangeFailure);
            // Failure might lead to state change or resource loss
             _transitionState(synthId, SynthState.Dormant); // Or Degenerating?
        }
         synth.lastUpdateTime = uint64(block.timestamp); // Reset timer after action
    }

     /// @dev Burns a Synth, removing it from the ecosystem.
     /// @param synthId The ID of the Synth to burn.
     /// @notice Can be used for degeneration/death or user action.
    function burnSynth(uint256 synthId) public { // Public for owner to burn, or internal for degeneration
        Synth storage synth = _synths[synthId];
        if (!_exists(synthId)) revert TokenDoesNotExist(synthId);
        if (msg.sender != synth.owner && synth.state != SynthState.Degenerating) revert NotTokenOwner(msg.sender, synthId); // Only owner can burn unless it's degenerating

        // Return some resources or penalize/reward reputation?
        // Example: Return a small fraction of resources
        uint256 refundAmount = synth.resourcesHeld / 10;
        if (refundAmount > 0) {
             // Check contract balance is sufficient (should be if synths hold resources here)
            _transferNutrients(address(this), synth.owner, refundAmount);
        }

        // Handle symbiotic bond if exists
        if (synth.bondedSynthId != 0) {
            _dissolveBond(synth.bondedSynthId); // Internal dissolve
        }

        _burn(synthId); // Handles ERC721 burn and events
        // SynthBurned event is emitted in _burn
    }

    /// @dev Allows anyone to trigger a state progression check for a Synth based on elapsed time.
    /// @param synthId The ID of the Synth to progress.
    /// @notice Calling this consumes gas, but allows the ecosystem to advance without keeper bots for basic time-based state changes.
    function progressSynthState(uint256 synthId) external {
        // This function exists so external actors can "poke" synths to update state based on time.
        // The actual state checks and transitions happen inside _checkSynthStateConditions.
        if (!_exists(synthId)) revert TokenDoesNotExist(synthId);
        _checkSynthStateConditions(synthId);
    }

    /// @dev Internal function to trigger nutrient production calculation.
    /// @param synthId The ID of the Synth.
    function _triggerNutrientProduction(uint256 synthId) internal {
         Synth storage synth = _synths[synthId];
        uint256 productionRate = _getGameParameter("productionRateNE");
        uint64 timeInState = uint64(block.timestamp) - synth.lastUpdateTime; // Use block.timestamp for elapsed time

        // Simple production: produces based on time in producing state
        if (synth.state == SynthState.Producing && productionRate > 0 && timeInState > 0) {
             uint256 produced = productionRate * timeInState; // Simplistic: Production per second
             synth.pendingNutrients += produced;
             synth.lastUpdateTime = uint64(block.timestamp); // Reset timer for production calculation
             // Note: This can lead to large pending amounts if not claimed/progressed often.
        }
        // Could add production decay or other logic here
    }

     /// @dev Internal function to check time-based state transitions and effects.
     /// @param synthId The ID of the Synth.
    function _checkSynthStateConditions(uint256 synthId) internal {
        Synth storage synth = _synths[synthId];
        uint64 elapsed = uint64(block.timestamp) - synth.lastUpdateTime;
        SynthState currentState = synth.state;

        // Trigger production calculation regardless of state transition
        _triggerNutrientProduction(synthId);

        // Check for degeneration due to low resources
        uint256 degenerationThreshold = _getGameParameter("degenerationThreshold");
        if (synth.resourcesHeld < degenerationThreshold && currentState != SynthState.Degenerating) {
             _transitionState(synthId, SynthState.Degenerating);
             return; // State changed, re-check in next call if needed
        }

        // Check degeneration timer if in Degenerating state
        if (currentState == SynthState.Degenerating) {
             uint256 degenerationTime = _getGameParameter("minTimeInState_Degenerating");
             if (elapsed >= degenerationTime) {
                 burnSynth(synthId); // Automatically burn if degenerated too long
                 return; // Synth is burned
             }
        }

        // Check for transitions based on time spent in current state
        uint265 minTimeInState;
        bool checkTransition = false;

        if (currentState == SynthState.Dormant) {
             // Dormant might transition to Active if fed? Or passively after a long time?
             // Let's make it transition to Active if fed (handled in feedSynth) or after enough resources build up?
             // For now, remains dormant until an action (feed) or condition met.
        } else if (currentState == SynthState.Growing) {
            minTimeInState = _getGameParameter("minTimeInState_Growing");
            checkTransition = true;
             // Growing consumes resources over time
             uint256 growthCost = _getGameParameter("growthCostNE");
             uint256 costThisPeriod = (elapsed / 60) * (growthCost / _getGameParameter("minTimeBetweenUpdates")); // Simple cost calculation based on elapsed time / update interval
             if (synth.resourcesHeld < costThisPeriod) {
                  synth.resourcesHeld = 0;
                  // Insufficient resources during growth -> Degenerating
                 _transitionState(synthId, SynthState.Degenerating);
                 return;
             } else {
                  synth.resourcesHeld -= costThisPeriod;
             }

        } else if (currentState == SynthState.Active) {
            // Active can transition to Producing, ReproductionReady, MutationReady based on resources/conditions
             // No specific timer to leave Active, transitions are triggered by conditions/resources
        } else if (currentState == SynthState.Producing) {
            minTimeInState = _getGameParameter("minTimeInState_Producing");
            checkTransition = true;
            // Production handled by _triggerNutrientProduction
        } else if (currentState == SynthState.ReproductionReady) {
            minTimeInState = _getGameParameter("minTimeInState_ReproductionReady");
            checkTransition = true;
             // Stays Ready until attempt or timer runs out (maybe back to Active/Dormant?)
        } else if (currentState == SynthState.MutationReady) {
            minTimeInState = _getGameParameter("minTimeInState_MutationReady");
            checkTransition = true;
            // Stays Ready until attempt or timer runs out
        } else if (currentState == SynthState.Interacting) {
            // Interaction state is temporary, managed by interaction functions
            // Maybe a timeout to revert?
        }

        // Apply state transition if time elapsed and other conditions (like resource levels being sufficient for the *next* state)
        if (checkTransition && elapsed >= minTimeInState) {
            // Example transitions:
            if (currentState == SynthState.Growing) {
                 // After growing, if resources high enough, become ProductionReady or ReproductionReady?
                 if (synth.resourcesHeld >= _getGameParameter("reproductionCostNE")) {
                     _transitionState(synthId, SynthState.ReproductionReady);
                 } else if (synth.resourcesHeld >= _getGameParameter("mutationCostNE")) {
                     _transitionState(synthId, SynthState.MutationReady);
                 } else {
                     _transitionState(synthId, SynthState.Active); // Default to Active
                 }
            } else if (currentState == SynthState.Producing) {
                 // After producing for a while, maybe transition back to Active or try something else
                 _transitionState(synthId, SynthState.Active);
            } else if (currentState == SynthState.ReproductionReady || currentState == SynthState.MutationReady) {
                // If ready state timer runs out without action, go back to Active
                _transitionState(synthId, SynthState.Active);
            }
             // Update lastUpdateTime *after* potential state change
             synth.lastUpdateTime = uint64(block.timestamp); // Reset timer for new state
        } else if (elapsed >= _getGameParameter("minTimeBetweenUpdates")) {
             // If enough time passed for an update tick but not state transition, just update timer
             synth.lastUpdateTime = uint64(block.timestamp);
        }
         // Note: This logic is simplified. A real game would have more complex conditions.
    }

    /// @dev Internal function to change a Synth's state and emit event.
    /// @param synthId The ID of the Synth.
    /// @param newState The state to transition to.
    function _transitionState(uint256 synthId, SynthState newState) internal {
        Synth storage synth = _synths[synthId];
        if (synth.state == newState) return; // No change

        SynthState oldState = synth.state;
        synth.state = newState;
        synth.lastUpdateTime = uint64(block.timestamp); // Reset timer on state change
        // Any state-specific effects on entering state?

        emit SynthStateChanged(synthId, oldState, newState);
    }


    // --- V. Synth Interactions ---

    /// @dev Attempts to initiate a symbiotic bond between two Synths.
    /// @param synth1Id The ID of the first Synth.
    /// @param synth2Id The ID of the second Synth.
    /// @notice Requires approval from the owner of synth2 if not the caller. Consumes resources. Probabilistic outcome.
    function initiateSymbioticBond(uint256 synth1Id, uint256 synth2Id) external {
        if (synth1Id == synth2Id) revert CannotBondWithSelf();
        if (!_exists(synth1Id)) revert TokenDoesNotExist(synth1Id);
        if (!_exists(synth2Id)) revert TokenDoesNotExist(synth2Id);

        Synth storage synth1 = _synths[synth1Id];
        Synth storage synth2 = _synths[synth2Id];

        if (synth1.bondedSynthId != 0 || synth2.bondedSynthId != 0) revert SynthsAlreadyBonded(synth1Id, synth2Id);

        // Require owner of synth1 to call, AND approval from owner of synth2 if different
        if (msg.sender != synth1.owner) revert NotTokenOwner(msg.sender, synth1Id);
        if (msg.sender != synth2.owner && !_checkApprovedOrOwner(msg.sender, synth2Id)) {
             revert BondingRequiresApproval(synth2Id);
        }

        // Trigger state check before interacting
        _checkSynthStateConditions(synth1Id);
        _checkSynthStateConditions(synth2Id);

        uint256 symbiosisCost = _getGameParameter("symbiosisCostNE");
         if (synth1.resourcesHeld + synth2.resourcesHeld < symbiosisCost) {
             // Cost is shared or needs total? Let's say combined resources must be enough
            revert InsufficientBalance(symbiosisCost, synth1.resourcesHeld + synth2.resourcesHeld);
        }

        // Consume resources (split cost?)
        uint256 costPerSynth = symbiosisCost / 2;
        synth1.resourcesHeld -= costPerSynth;
        synth2.resourcesHeld -= costPerSynth; // Assumes cost is even

        emit SymbioticBondAttempt(synth1Id, synth2Id, msg.sender);

        uint256 successChance = _getGameParameter("symbiosisSuccessChance");
        int256 repChangeSuccess = int256(_getGameParameter("reputationChangeSuccessSmall"));
        int256 repChangeFailure = -1 * int265(_getGameParameter("reputationChangeFailureSmall"));

        uint256 randomValue = _getPseudoRandomUint(synth1Id + synth2Id);

        // Temporarily put both in Interacting state?
        _transitionState(synth1Id, SynthState.Interacting);
        _transitionState(synth2Id, SynthState.Interacting);

        if (randomValue % 100 < successChance) {
            // Success: Create bond
            synth1.bondedSynthId = synth2Id;
            synth2.bondedSynthId = synth1Id;
            // Potential state changes upon successful bond (e.g., both go to Producing)
            _transitionState(synth1Id, SynthState.Producing); // Example: Bonded = better production
            _transitionState(synth2Id, SynthState.Producing);

            // Reputation changes
            _updateReputation(synth1.owner, repChangeSuccess);
            if (synth1.owner != synth2.owner) {
                 _updateReputation(synth2.owner, repChangeSuccess);
            }
             synth1.intrinsicReputation += repChangeSuccess;
             synth2.intrinsicReputation += repChangeSuccess;

            emit SymbioticBondCreated(synth1Id, synth2Id);
        } else {
            // Failure: No bond created
             // Maybe a penalty? State change back to Active/Dormant
            _transitionState(synth1Id, SynthState.Active); // Example: Back to active after failure
            _transitionState(synth2Id, SynthState.Active);

            // Reputation changes
            _updateReputation(synth1.owner, repChangeFailure);
            if (synth1.owner != synth2.owner) {
                 _updateReputation(synth2.owner, repChangeFailure);
            }
            synth1.intrinsicReputation += repChangeFailure;
            synth2.intrinsicReputation += repChangeFailure;
        }

        synth1.lastUpdateTime = uint64(block.timestamp);
        synth2.lastUpdateTime = uint64(block.timestamp);
    }

    /// @dev Dissolves an existing symbiotic bond for a Synth.
    /// @param synthId The ID of the Synth whose bond should be dissolved.
    /// @notice Called by the owner of the Synth.
    function dissolveSymbioticBond(uint256 synthId) external {
        Synth storage synth = _synths[synthId];
        if (!_exists(synthId)) revert TokenDoesNotExist(synthId);
        if (msg.sender != synth.owner) revert NotTokenOwner(msg.sender, synthId);
        if (synth.bondedSynthId == 0) revert SynthsNotBonded(synthId);

        _dissolveBond(synthId); // Use internal helper
    }

     /// @dev Internal helper to dissolve a bond from one side.
     /// @param synthId The ID of the Synth whose bond is being dissolved.
    function _dissolveBond(uint256 synthId) internal {
        Synth storage synth1 = _synths[synthId];
        uint256 synth2Id = synth1.bondedSynthId;
        // Check if synth2 still exists, might have been burned
        if (_exists(synth2Id)) {
             Synth storage synth2 = _synths[synth2Id];
             synth2.bondedSynthId = 0;
             // State change upon dissolving? E.g., back to Active
             _transitionState(synth2Id, SynthState.Active);
             synth2.lastUpdateTime = uint64(block.timestamp);
        }
        synth1.bondedSynthId = 0;
        // State change upon dissolving?
         _transitionState(synthId, SynthState.Active);
         synth1.lastUpdateTime = uint64(block.timestamp);

         emit SymbioticBondDissolved(synthId, synth2Id);
    }

    /// @dev Initiates a competitive interaction between two Synths.
    /// @param attackerSynthId The ID of the attacking Synth (owned by caller).
    /// @param targetSynthId The ID of the target Synth.
    /// @notice Consumes attacker resources, has probabilistic outcome affecting resources and reputation of both.
    function initiateCompetitiveInteraction(uint256 attackerSynthId, uint256 targetSynthId) external {
        if (attackerSynthId == targetSynthId) revert CannotInteractWithSelf();
        if (!_exists(attackerSynthId)) revert TokenDoesNotExist(attackerSynthId);
        if (!_exists(targetSynthId)) revert TokenDoesNotExist(targetSynthId);

        Synth storage attackerSynth = _synths[attackerSynthId];
        Synth storage targetSynth = _synths[targetSynthId];

        if (msg.sender != attackerSynth.owner) revert NotTokenOwner(msg.sender, attackerSynthId);

        // Trigger state check
        _checkSynthStateConditions(attackerSynthId);
        _checkSynthStateConditions(targetSynthId);


        uint256 competitionCost = _getGameParameter("competitionCostNE");
         if (attackerSynth.resourcesHeld < competitionCost) revert InsufficientBalance(competitionCost, attackerSynth.resourcesHeld);

        attackerSynth.resourcesHeld -= competitionCost;
        emit CompetitiveInteractionAttempt(attackerSynthId, targetSynthId, msg.sender);

        uint256 successChance = _getGameParameter("competitionSuccessChance");
        // Adjust chance based on Synth types, reputation difference, etc.
        // Example: attackerRep + attackerType vs targetRep + targetType
        int256 attackerEffectiveScore = userReputation[msg.sender] + attackerSynth.intrinsicReputation + int256(attackerSynth.synthType * 10); // Example factors
        int256 targetEffectiveScore = userReputation[targetSynth.owner] + targetSynth.intrinsicReputation + int256(targetSynth.synthType * 10); // Example factors

        // Chance modifier based on score difference
        int256 scoreDifference = attackerEffectiveScore - targetEffectiveScore;
        // Simple modifier: +1% chance per 10 score difference in attacker's favor, up to max/min chance
        uint256 modifiedChance = successChance;
        if (scoreDifference > 0) {
            modifiedChance += uint256(scoreDifference / 10);
        } else if (scoreDifference < 0) {
            modifiedChance = modifiedChance >= uint252(-scoreDifference / 10) ? modifiedChance - uint252(-scoreDifference / 10) : 0;
        }
        // Clamp chance between min/max (e.g., 10% to 90%)
        uint256 minChance = 10; // Example min chance
        uint256 maxChance = 90; // Example max chance
        if (modifiedChance < minChance) modifiedChance = minChance;
        if (modifiedChance > maxChance) modifiedChance = maxChance;


        int256 repChangeSuccessAttacker = int256(_getGameParameter("reputationChangeSuccessSmall"));
        int256 repChangeFailureAttacker = -1 * int256(_getGameParameter("reputationChangeFailureSmall"));
         // Target rep change is opposite of attacker's outcome
        int256 repChangeSuccessTarget = repChangeFailureAttacker; // Target loses rep on attacker success
        int256 repChangeFailureTarget = repChangeSuccessAttacker; // Target gains rep on attacker failure


        uint256 randomValue = _getPseudoRandomUint(attackerSynthId + targetSynthId + uint256(block.difficulty));

        bool successForAttacker = randomValue % 100 < modifiedChance;

        // Temporarily put both in Interacting state?
        _transitionState(attackerSynthId, SynthState.Interacting);
        _transitionState(targetSynthId, SynthState.Interacting);

        if (successForAttacker) {
            // Attacker wins: gains resources from target, state change for target
            uint256 resourceStealAmount = targetSynth.resourcesHeld / 5; // Example: steal 20%
            if (resourceStealAmount > 0) {
                targetSynth.resourcesHeld -= resourceStealAmount;
                attackerSynth.resourcesHeld += resourceStealAmount;
            }
            // State change for target (e.g., Degenerating or Dormant)
             _transitionState(targetSynthId, SynthState.Degenerating); // Example: Target suffers
             _transitionState(attackerSynthId, SynthState.Active); // Attacker returns to active

            // Reputation changes
            _updateReputation(attackerSynth.owner, repChangeSuccessAttacker);
            _updateReputation(targetSynth.owner, repChangeSuccessTarget);
            attackerSynth.intrinsicReputation += repChangeSuccessAttacker;
            targetSynth.intrinsicReputation += repChangeSuccessTarget;

            emit CompetitiveInteractionOutcome(attackerSynthId, targetSynthId, true, repChangeSuccessAttacker);

        } else {
            // Attacker loses: loses more resources, state change for attacker
            uint256 resourcePenaltyAmount = competitionCost / 2; // Example: Lose half cost again
            if (attackerSynth.resourcesHeld >= resourcePenaltyAmount) {
                 attackerSynth.resourcesHeld -= resourcePenaltyAmount;
            } else {
                 attackerSynth.resourcesHeld = 0;
            }
             // State change for attacker (e.g., Degenerating or Dormant)
             _transitionState(attackerSynthId, SynthState.Degenerating); // Example: Attacker suffers
             _transitionState(targetSynthId, SynthState.Active); // Target recovers/unaffected

            // Reputation changes
            _updateReputation(attackerSynth.owner, repChangeFailureAttacker);
            _updateReputation(targetSynth.owner, repChangeFailureTarget);
            attackerSynth.intrinsicReputation += repChangeFailureAttacker;
            targetSynth.intrinsicReputation += repChangeFailureTarget;

            emit CompetitiveInteractionOutcome(attackerSynthId, targetSynthId, false, repChangeFailureAttacker);
        }

         attackerSynth.lastUpdateTime = uint64(block.timestamp);
         targetSynth.lastUpdateTime = uint64(block.timestamp);
    }


    // --- VI. Query & Reputation ---

    /// @dev Gets the global reputation score for a user.
    /// @param user The address of the user.
    /// @return The user's reputation score.
    function getUserReputation(address user) external view returns (int256) {
        return userReputation[user];
    }

     /// @dev Gets the amount of pending Nutrient Essence for a specific Synth.
     /// @param synthId The ID of the Synth.
     /// @return The amount of pending NE.
    function getSynthPendingNutrients(uint256 synthId) external view returns (uint256) {
        if (!_exists(synthId)) revert TokenDoesNotExist(synthId);
        // Note: This doesn't trigger production calculation, just returns current pending.
        // A user would call progressSynthState or claimPendingNutrients to update it.
        return _synths[synthId].pendingNutrients;
    }

     /// @dev Gets the ID of the Synth currently bonded symbiotically, if any.
     /// @param synthId The ID of the Synth.
     /// @return The bonded Synth ID, or 0 if not bonded.
    function getSynthBondedSynth(uint256 synthId) external view returns (uint256) {
        if (!_exists(synthId)) revert TokenDoesNotExist(synthId);
        return _synths[synthId].bondedSynthId;
    }

     /// @dev Gets the total number of Synths that have been created.
     /// @return The total Synth supply.
    function getTotalSynthSupply() external view returns (uint256) {
        return _synthCounter;
    }

    /// @dev Admin function to grant initial nutrients to an address.
    /// @param recipient The address to grant nutrients to.
    /// @param amount The amount of NE to grant.
    function grantInitialNutrients(address recipient, uint256 amount) external onlyAdmin {
         _mintNutrients(recipient, amount);
    }

     /// @dev Query function to check a synth's current state without triggering updates.
     /// @param synthId The ID of the Synth.
     /// @return The current SynthState.
    function checkSynthState(uint256 synthId) external view returns (SynthState) {
         if (!_exists(synthId)) revert TokenDoesNotExist(synthId);
         return _synths[synthId].state;
    }
}
```