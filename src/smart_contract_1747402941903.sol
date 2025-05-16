Okay, let's design a creative, advanced-concept smart contract. We will create a "Synthesized Reality Engine" where users interact with dynamic, evolving digital entities called "Fragments" using a resource token called "Essence" and potentially other inputs ("Catalysts"). The Fragments' traits evolve over time based on nourishment, environmental conditions, and interactions. It's not a standard token, DEX, or lending protocol, but incorporates elements of dynamic NFTs, resource management, and simulation.

**Concept:**

*   **Essence (ERC-20-like):** The primary resource token required for most actions (discovery, nourishment).
*   **Catalyst (ERC-20-like):** A secondary resource token that boosts nourishment or influences evolution.
*   **Fragments (ERC-721-like):** Dynamic NFTs. Each Fragment has a set of numerical `Traits` that change over time based on internal logic (nourishment, decay) and external factors (`EnvironmentalConditions`).
*   **Environmental Conditions:** Global parameters within the contract that affect the evolution/decay rates of all Fragments. These can be changed via a simple governance mechanism.
*   **Nourishment:** Users spend Essence and/or Catalysts on a Fragment to increase its internal `nourishmentLevel` and reset its interaction timer, counteracting decay and boosting evolution.
*   **Discovery:** Users spend Essence and/or Catalysts to "discover" (mint) a new Fragment. Initial traits might be influenced by current conditions or a pseudo-random factor.
*   **Harvest:** Users can "harvest" a Fragment, consuming its `nourishmentLevel` and potentially altering traits, yielding a reward (e.g., some Essence) based on its current state and traits.
*   **Evolution Logic:** An internal system that calculates how traits change based on elapsed time, nourishment, environmental conditions, and potentially specific trait interactions. This calculation happens lazily (on interaction or query) or can be triggered.

**Outline:**

1.  **State Variables:** Define storage for tokens (balances, approvals), Fragment data (owner, approvals, state), environmental conditions, costs, rates, trait definitions.
2.  **Events:** Define events for key actions (token transfers, approvals, fragment creation, nourishment, harvest, environmental shifts, parameter changes).
3.  **Structs:** Define structs for Fragment data (traits, nourishment level, last interaction time, etc.). Define Trait definitions.
4.  **Modifiers:** Simple access control (e.g., `onlyOwner` for admin functions).
5.  **ERC-20 Logic (Essence & Catalyst):** Basic `balanceOf`, `transfer`, `approve`, `allowance`, `transferFrom`. Minting and burning functions (controlled access).
6.  **ERC-721 Logic (Fragments):** Basic `ownerOf`, `transferFrom`, `approve`, `setApprovalForAll`, `getApproved`, `isApprovedForAll`. Minting logic triggered by `discoverFragment`.
7.  **Fragment State & Evolution:**
    *   Internal functions to calculate trait changes based on logic (`_calculateFragmentEvolution`).
    *   Public/External view function to simulate evolution.
    *   Internal/Public functions to update state on interaction (`_updateFragmentState`).
8.  **Core User Interactions:**
    *   `discoverFragment()`: Mint a new Fragment.
    *   `nourishFragment()`: Spend resources to boost a Fragment.
    *   `harvestFragment()`: Extract value/change state from a Fragment.
9.  **Environmental & Parameter Control:**
    *   Functions to get current environmental conditions and costs.
    *   Admin/Governance functions to set costs, rates, conditions, and trait names.
10. **Helper/Utility Functions:** Getters for various state variables, trait names, etc.

**Function Summary:**

*   **Owner/Admin:**
    *   `constructor()`: Initializes the contract, sets initial parameters and owner.
    *   `transferOwnership(address newOwner)`: Transfers contract ownership.
    *   `renounceOwnership()`: Renounces contract ownership.
    *   `mintEssence(address account, uint256 amount)`: Admin mints Essence.
    *   `mintCatalyst(address account, uint256 amount)`: Admin mints Catalyst.
    *   `triggerEnvironmentalShift(uint256 newConditionValue)`: Admin changes a global environmental condition.
    *   `setNourishmentCosts(uint256 essenceCost, uint256 catalystCost)`: Admin sets the cost for nourishment.
    *   `setDiscoveryCost(uint256 essenceCost, uint256 catalystCost)`: Admin sets the cost for discovery.
    *   `setBaseRates(uint256 baseEvolutionRate, uint256 baseDecayRate)`: Admin sets base rates for trait changes.
    *   `setFragmentTraitNames(string[] traitNames)`: Admin sets the names for traits.
    *   `setFragmentTraitBoosts(uint256 traitIndex, uint256 boost)`: Admin sets specific boost factors for traits.
*   **Essence (ERC-20):**
    *   `getEssenceName()`: Returns Essence name.
    *   `getEssenceSymbol()`: Returns Essence symbol.
    *   `getEssenceTotalSupply()`: Returns total Essence supply.
    *   `balanceOfEssence(address account)`: Returns account's Essence balance.
    *   `transferEssence(address recipient, uint256 amount)`: Transfers Essence.
    *   `approveEssence(address spender, uint256 amount)`: Approves spender for Essence.
    *   `allowanceEssence(address owner, address spender)`: Returns spender's Essence allowance.
    *   `transferFromEssence(address sender, address recipient, uint256 amount)`: Transfers Essence using allowance.
    *   `burnEssence(uint256 amount)`: User burns their own Essence.
*   **Catalyst (ERC-20):**
    *   `getCatalystName()`: Returns Catalyst name.
    *   `getCatalystSymbol()`: Returns Catalyst symbol.
    *   `getCatalystTotalSupply()`: Returns total Catalyst supply.
    *   `balanceOfCatalyst(address account)`: Returns account's Catalyst balance.
    *   `transferCatalyst(address recipient, uint256 amount)`: Transfers Catalyst.
    *   `approveCatalyst(address spender, uint256 amount)`: Approves spender for Catalyst.
    *   `allowanceCatalyst(address owner, address spender)`: Returns spender's Catalyst allowance.
    *   `transferFromCatalyst(address sender, address recipient, uint256 amount)`: Transfers Catalyst using allowance.
    *   `burnCatalyst(uint256 amount)`: User burns their own Catalyst.
*   **Fragments (ERC-721):**
    *   `getFragmentName()`: Returns Fragment name.
    *   `getFragmentSymbol()`: Returns Fragment symbol.
    *   `getFragmentTotalSupply()`: Returns total Fragment supply.
    *   `ownerOfFragment(uint256 tokenId)`: Returns owner of Fragment.
    *   `transferFromFragment(address from, address to, uint256 tokenId)`: Transfers Fragment ownership.
    *   `approveFragment(address to, uint256 tokenId)`: Approves address for Fragment.
    *   `getApprovedFragment(uint256 tokenId)`: Returns approved address for Fragment.
    *   `setApprovalForAllFragments(address operator, bool approved)`: Sets approval for all Fragments for an operator.
    *   `isApprovedForAllFragments(address owner, address operator)`: Checks if operator is approved for all Fragments.
    *   `getFragmentTraits(uint256 tokenId)`: Returns the current trait values for a Fragment.
    *   `getFragmentState(uint256 tokenId)`: Returns a struct with nourishment level and last interaction time.
    *   `getFragmentTraitNames()`: Returns the names of all traits.
*   **Core Reality Engine:**
    *   `getEnvironmentalConditions()`: Returns current environmental conditions.
    *   `getNourishmentCosts()`: Returns the current costs for nourishment.
    *   `getDiscoveryCost()`: Returns the current cost for discovery.
    *   `discoverFragment()`: User initiates discovery, paying cost and potentially minting a new Fragment.
    *   `nourishFragment(uint256 tokenId, uint256 essenceAmount, uint256 catalystAmount)`: User nourishes a Fragment, paying resources and updating state.
    *   `harvestFragment(uint256 tokenId)`: User harvests a Fragment, triggering state change and potential reward.
    *   `simulateFragmentEvolution(uint256 tokenId, uint256 timeElapsed)`: View function to see how traits *would* evolve over a given time.

This totals well over 20 functions and covers the described unique mechanics.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Outline:
// 1. State Variables: Token balances, approvals, Fragment data, system parameters.
// 2. Events: Standard token events, Fragment events, Reality Engine events.
// 3. Structs: FragmentState.
// 4. Modifiers: onlyOwner.
// 5. Basic Access Control: Ownership pattern.
// 6. ERC-20 Logic (Essence & Catalyst): Simplified implementations for tracking balances and allowances.
// 7. ERC-721 Logic (Fragments): Simplified implementations for tracking ownership and approvals.
// 8. Fragment State & Evolution: Internal logic for trait changes, view function for simulation.
// 9. Core User Interactions: discover, nourish, harvest.
// 10. Environmental & Parameter Control: Getters and setters for system parameters.

// Function Summary:
// Owner/Admin Functions:
// constructor()
// transferOwnership(address newOwner)
// renounceOwnership()
// mintEssence(address account, uint256 amount)
// mintCatalyst(address account, uint256 amount)
// triggerEnvironmentalShift(uint256 newConditionValue)
// setNourishmentCosts(uint256 essenceCost, uint256 catalystCost)
// setDiscoveryCost(uint256 essenceCost, uint256 catalystCost)
// setBaseRates(uint256 baseEvolutionRate, uint256 baseDecayRate)
// setFragmentTraitNames(string[] traitNames)
// setFragmentTraitBoosts(uint256 traitIndex, uint256 boost)

// Essence Token (ERC-20 basic implementation):
// getEssenceName()
// getEssenceSymbol()
// getEssenceTotalSupply()
// balanceOfEssence(address account)
// transferEssence(address recipient, uint256 amount)
// approveEssence(address spender, uint256 amount)
// allowanceEssence(address owner, address spender)
// transferFromEssence(address sender, address recipient, uint256 amount)
// burnEssence(uint256 amount)

// Catalyst Token (ERC-20 basic implementation):
// getCatalystName()
// getCatalystSymbol()
// getCatalystTotalSupply()
// balanceOfCatalyst(address account)
// transferCatalyst(address recipient, uint256 amount)
// approveCatalyst(address spender, uint256 amount)
// allowanceCatalyst(address owner, address spender)
// transferFromCatalyst(address sender, address recipient, uint256 amount)
// burnCatalyst(uint256 amount)

// Fragments (ERC-721 basic implementation & custom state):
// getFragmentName()
// getFragmentSymbol()
// getFragmentTotalSupply()
// ownerOfFragment(uint256 tokenId)
// transferFromFragment(address from, address to, uint256 tokenId)
// approveFragment(address to, uint256 tokenId)
// getApprovedFragment(uint256 tokenId)
// setApprovalForAllFragments(address operator, bool approved)
// isApprovedForAllFragments(address owner, address operator)
// getFragmentTraits(uint256 tokenId)
// getFragmentState(uint256 tokenId)
// getFragmentTraitNames()

// Core Reality Engine Functions:
// getEnvironmentalConditions()
// getNourishmentCosts()
// getDiscoveryCost()
// discoverFragment()
// nourishFragment(uint256 tokenId, uint256 essenceAmount, uint256 catalystAmount)
// harvestFragment(uint256 tokenId)
// simulateFragmentEvolution(uint256 tokenId, uint256 timeElapsed)


contract SynthesizedRealityEngine {

    // --- State Variables ---

    // Ownership
    address private _owner;

    // Essence (ERC-20)
    string private _essenceName = "Essence";
    string private _essenceSymbol = "ESS";
    uint256 private _essenceTotalSupply;
    mapping(address => uint256) private _essenceBalances;
    mapping(address => mapping(address => uint256)) private _essenceAllowances;

    // Catalyst (ERC-20)
    string private _catalystName = "Catalyst";
    string private _catalystSymbol = "CAT";
    uint256 private _catalystTotalSupply;
    mapping(address => uint256) private _catalystBalances;
    mapping(address => mapping(address => uint256)) private _catalystAllowances;

    // Fragments (ERC-721 & Custom State)
    string private _fragmentName = "Fragment";
    string private _fragmentSymbol = "FRG";
    uint256 private _fragmentCounter; // Used for token IDs
    mapping(uint256 => address) private _fragmentOwners;
    mapping(uint256 => address) private _fragmentTokenApprovals;
    mapping(address => mapping(address => bool)) private _fragmentOperatorApprovals;

    struct FragmentState {
        uint16[] traits; // e.g., [Vitality, Resonance, Complexity, Adaptability] (values 0-1000)
        uint256 nourishmentLevel; // How much nourishment it has received (affects growth rate)
        uint48 lastInteractionTime; // Timestamp of last nourish or harvest
        uint48 lastEvolutionUpdateTime; // Timestamp traits were last explicitly calculated/updated
    }
    mapping(uint256 => FragmentState) private _fragmentStates;

    // Fragment Trait Definitions
    string[] private _fragmentTraitNames; // ["Vitality", "Resonance", ...]
    mapping(uint256 => uint256) private _fragmentTraitBoosts; // Boost factor for evolution per trait index

    // Reality Engine Parameters
    uint256 private _environmentalCondition; // A single dynamic condition parameter (can be expanded)
    uint256 private _nourishmentEssenceCost;
    uint256 private _nourishmentCatalystCost;
    uint256 private _discoveryEssenceCost;
    uint256 private _discoveryCatalystCost;
    uint256 private _baseTraitEvolutionRate; // Rate per unit time/nourishment
    uint256 private _baseTraitDecayRate;     // Rate per unit time

    // Constants
    uint256 public constant MAX_TRAIT_VALUE = 1000;
    uint256 public constant MIN_TRAIT_VALUE = 0;
    uint256 public constant FRAGMENT_DECAY_INTERVAL = 1 days; // How often decay is calculated
    uint256 public constant FRAGMENT_EVOLUTION_INTERVAL = 1 hours; // How often growth is calculated based on state

    // --- Events ---

    event TransferEssence(address indexed from, address indexed to, uint256 value);
    event ApprovalEssence(address indexed owner, address indexed spender, uint256 value);

    event TransferCatalyst(address indexed from, address indexed to, uint256 value);
    event ApprovalCatalyst(address indexed owner, address indexed spender, uint256 value);

    event TransferFragment(address indexed from, address indexed to, uint256 tokenId);
    event ApprovalFragment(address indexed owner, address indexed approved, uint256 tokenId);
    event ApprovalForAllFragments(address indexed owner, address indexed operator, bool approved);

    event FragmentDiscovered(uint256 indexed tokenId, address indexed owner, uint16[] initialTraits);
    event FragmentNourished(uint256 indexed tokenId, address indexed nourisher, uint256 essenceUsed, uint256 catalystUsed, uint256 newNourishmentLevel);
    event FragmentHarvested(uint256 indexed tokenId, address indexed harvester, uint256 essenceYielded, uint16[] finalTraits);
    event FragmentTraitsEvolved(uint256 indexed tokenId, uint16[] newTraits);

    event EnvironmentalShift(uint256 indexed oldCondition, uint256 indexed newCondition);
    event ParametersUpdated(string paramName, uint256[] newValues);


    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == _owner, "Only owner can call this function");
        _;
    }

    modifier onlyFragmentOwnerOrApproved(uint256 tokenId) {
        require(_exists(tokenId), "Fragment does not exist");
        address owner = _fragmentOwners[tokenId];
        require(msg.sender == owner || _fragmentTokenApprovals[tokenId] == msg.sender || _fragmentOperatorApprovals[owner][msg.sender], "Not owner or approved");
        _;
    }

    // --- Constructor ---

    constructor() {
        _owner = msg.sender;

        // Set initial parameters
        _environmentalCondition = 50; // Example initial value
        _nourishmentEssenceCost = 10e18; // 10 Essence
        _nourishmentCatalystCost = 1e18; // 1 Catalyst
        _discoveryEssenceCost = 50e18; // 50 Essence
        _discoveryCatalystCost = 5e18; // 5 Catalyst
        _baseTraitEvolutionRate = 1; // Points per interval per nourishment unit
        _baseTraitDecayRate = 5;     // Points per interval

        // Set initial trait names (can be updated later)
        _fragmentTraitNames = ["Vitality", "Resonance", "Complexity", "Adaptability"];

        // Set some default boosts (can be updated later)
        _fragmentTraitBoosts[0] = 10; // Vitality might get more boost
        _fragmentTraitBoosts[1] = 5;
        _fragmentTraitBoosts[2] = 8;
        _fragmentTraitBoosts[3] = 12;

        // Mint initial tokens for the owner (example)
        _mintEssence(msg.sender, 1000e18);
        _mintCatalyst(msg.sender, 100e18);
    }

    // --- Ownership Functions ---

    function owner() public view returns (address) {
        return _owner;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner is zero address");
        _owner = newOwner;
    }

    function renounceOwnership() public onlyOwner {
        _owner = address(0); // Zero address signifies no owner
    }

    // --- Essence Token (ERC-20 basic implementation) ---

    function getEssenceName() public view returns (string memory) {
        return _essenceName;
    }

    function getEssenceSymbol() public view returns (string memory) {
        return _essenceSymbol;
    }

    function getEssenceTotalSupply() public view returns (uint256) {
        return _essenceTotalSupply;
    }

    function balanceOfEssence(address account) public view returns (uint256) {
        return _essenceBalances[account];
    }

    function transferEssence(address recipient, uint256 amount) public returns (bool) {
        _transferEssence(msg.sender, recipient, amount);
        return true;
    }

    function approveEssence(address spender, uint256 amount) public returns (bool) {
        _approveEssence(msg.sender, spender, amount);
        return true;
    }

    function allowanceEssence(address owner_, address spender) public view returns (uint256) {
        return _essenceAllowances[owner_][spender];
    }

    function transferFromEssence(address sender, address recipient, uint256 amount) public returns (bool) {
        uint256 currentAllowance = _essenceAllowances[sender][msg.sender];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approveEssence(sender, msg.sender, currentAllowance - amount);
        _transferEssence(sender, recipient, amount);
        return true;
    }

    function _transferEssence(address from, address to, uint256 amount) internal {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(_essenceBalances[from] >= amount, "ERC20: transfer amount exceeds balance");

        _essenceBalances[from] -= amount;
        _essenceBalances[to] += amount;
        emit TransferEssence(from, to, amount);
    }

    function _mintEssence(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");
        _essenceTotalSupply += amount;
        _essenceBalances[account] += amount;
        emit TransferEssence(address(0), account, amount);
    }

     // Admin function to mint Essence
    function mintEssence(address account, uint256 amount) public onlyOwner {
        _mintEssence(account, amount);
    }

    // User function to burn their own Essence
    function burnEssence(uint256 amount) public {
        _burnEssence(msg.sender, amount);
    }

    function _burnEssence(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");
        require(_essenceBalances[account] >= amount, "ERC20: burn amount exceeds balance");

        _essenceBalances[account] -= amount;
        _essenceTotalSupply -= amount;
        emit TransferEssence(account, address(0), amount);
    }

    function _approveEssence(address owner_, address spender, uint256 amount) internal {
        require(owner_ != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _essenceAllowances[owner_][spender] = amount;
        emit ApprovalEssence(owner_, spender, amount);
    }


    // --- Catalyst Token (ERC-20 basic implementation) ---
    // (Similar functions as Essence, implemented for completeness and count)

     function getCatalystName() public view returns (string memory) {
        return _catalystName;
    }

    function getCatalystSymbol() public view returns (string memory) {
        return _catalystSymbol;
    }

    function getCatalystTotalSupply() public view returns (uint256) {
        return _catalystTotalSupply;
    }

    function balanceOfCatalyst(address account) public view returns (uint256) {
        return _catalystBalances[account];
    }

    function transferCatalyst(address recipient, uint256 amount) public returns (bool) {
        _transferCatalyst(msg.sender, recipient, amount);
        return true;
    }

    function approveCatalyst(address spender, uint256 amount) public returns (bool) {
        _approveCatalyst(msg.sender, spender, amount);
        return true;
    }

    function allowanceCatalyst(address owner_, address spender) public view returns (uint256) {
        return _catalystAllowances[owner_][spender];
    }

    function transferFromCatalyst(address sender, address recipient, uint256 amount) public returns (bool) {
        uint256 currentAllowance = _catalystAllowances[sender][msg.sender];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approveCatalyst(sender, msg.sender, currentAllowance - amount);
        _transferCatalyst(sender, recipient, amount);
        return true;
    }

    function _transferCatalyst(address from, address to, uint256 amount) internal {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(_catalystBalances[from] >= amount, "ERC20: transfer amount exceeds balance");

        _catalystBalances[from] -= amount;
        _catalystBalances[to] += amount;
        emit TransferCatalyst(from, to, amount);
    }

    function _mintCatalyst(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");
        _catalystTotalSupply += amount;
        _catalystBalances[account] += amount;
        emit TransferCatalyst(address(0), account, amount);
    }

    // Admin function to mint Catalyst
    function mintCatalyst(address account, uint256 amount) public onlyOwner {
        _mintCatalyst(account, amount);
    }

    // User function to burn their own Catalyst
    function burnCatalyst(uint256 amount) public {
        _burnCatalyst(msg.sender, amount);
    }

    function _burnCatalyst(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");
        require(_catalystBalances[account] >= amount, "ERC20: burn amount exceeds balance");

        _catalystBalances[account] -= amount;
        _catalystTotalSupply -= amount;
        emit TransferCatalyst(account, address(0), amount);
    }

    function _approveCatalyst(address owner_, address spender, uint256 amount) internal {
        require(owner_ != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _catalystAllowances[owner_][spender] = amount;
        emit ApprovalCatalyst(owner_, spender, amount);
    }


    // --- Fragments (ERC-721 basic implementation & custom state) ---

    function getFragmentName() public view returns (string memory) {
        return _fragmentName;
    }

    function getFragmentSymbol() public view returns (string memory) {
        return _fragmentSymbol;
    }

    function getFragmentTotalSupply() public view returns (uint256) {
        return _fragmentCounter;
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return _fragmentOwners[tokenId] != address(0);
    }

    function ownerOfFragment(uint256 tokenId) public view returns (address) {
        address owner_ = _fragmentOwners[tokenId];
        require(owner_ != address(0), "ERC721: owner query for nonexistent token");
        return owner_;
    }

    function transferFromFragment(address from, address to, uint256 tokenId) public onlyFragmentOwnerOrApproved(tokenId) {
        require(_fragmentOwners[tokenId] == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _approveFragment(address(0), tokenId); // Clear approval for the old owner
        _fragmentOwners[tokenId] = to;

        emit TransferFragment(from, to, tokenId);
    }

    function safeTransferFromFragment(address from, address to, uint256 tokenId) public {
        // Simplified: Just call transferFrom.
        // In a real ERC721, this would check if 'to' is a contract and can receive ERC721.
        transferFromFragment(from, to, tokenId);
    }

    function approveFragment(address to, uint256 tokenId) public onlyFragmentOwnerOrApproved(tokenId) {
         // require(ownerOfFragment(tokenId) == msg.sender, "ERC721: approval to current owner"); // Not needed per standard
        _approveFragment(to, tokenId);
    }

    function _approveFragment(address to, uint256 tokenId) internal {
        _fragmentTokenApprovals[tokenId] = to;
        emit ApprovalFragment(ownerOfFragment(tokenId), to, tokenId);
    }

    function getApprovedFragment(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");
        return _fragmentTokenApprovals[tokenId];
    }

    function setApprovalForAllFragments(address operator, bool approved) public {
        require(operator != msg.sender, "ERC721: approve to caller");
        _fragmentOperatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAllFragments(msg.sender, operator, approved);
    }

    function isApprovedForAllFragments(address owner_, address operator) public view returns (bool) {
        return _fragmentOperatorApprovals[owner_][operator];
    }

     function _mintFragment(address to, uint16[] memory initialTraits) internal {
        require(to != address(0), "ERC721: mint to the zero address");
        uint256 newItemId = ++_fragmentCounter;
        _fragmentOwners[newItemId] = to;

        FragmentState storage newState = _fragmentStates[newItemId];
        newState.traits = initialTraits;
        newState.nourishmentLevel = 0;
        newState.lastInteractionTime = uint48(block.timestamp); // Use uint48 to save space
        newState.lastEvolutionUpdateTime = uint48(block.timestamp);

        emit TransferFragment(address(0), to, newItemId);
        emit FragmentDiscovered(newItemId, to, initialTraits);
    }

    function getFragmentTraits(uint256 tokenId) public view returns (uint16[] memory) {
        require(_exists(tokenId), "Fragment does not exist");
        // Note: This view function does *not* trigger evolution.
        // To see evolved traits, call simulateFragmentEvolution or interact with the fragment.
        return _fragmentStates[tokenId].traits;
    }

     struct FragmentStateReturn {
        uint256 nourishmentLevel;
        uint48 lastInteractionTime;
        uint48 lastEvolutionUpdateTime;
    }

    function getFragmentState(uint256 tokenId) public view returns (FragmentStateReturn memory) {
        require(_exists(tokenId), "Fragment does not exist");
        FragmentState storage state = _fragmentStates[tokenId];
        return FragmentStateReturn(state.nourishmentLevel, state.lastInteractionTime, state.lastEvolutionUpdateTime);
    }

    function getFragmentTraitNames() public view returns (string[] memory) {
        return _fragmentTraitNames;
    }


    // --- Core Reality Engine Functions ---

    function getEnvironmentalConditions() public view returns (uint256) {
        return _environmentalCondition;
    }

    function getNourishmentCosts() public view returns (uint256 essenceCost, uint256 catalystCost) {
        return (_nourishmentEssenceCost, _nourishmentCatalystCost);
    }

    function getDiscoveryCost() public view returns (uint256 essenceCost, uint256 catalystCost) {
        return (_discoveryEssenceCost, _discoveryCatalystCost);
    }

    /**
     * @dev User initiates a discovery attempt. Consumes resources and might mint a new Fragment.
     * Simplified pseudo-randomness based on block data. In a real system, use a VRF oracle.
     */
    function discoverFragment() public {
        require(balanceOfEssence(msg.sender) >= _discoveryEssenceCost, "Not enough Essence for discovery");
        require(balanceOfCatalyst(msg.sender) >= _discoveryCatalystCost, "Not enough Catalyst for discovery");

        _burnEssence(msg.sender, _discoveryEssenceCost);
        _burnCatalyst(msg.sender, _discoveryCatalystCost);

        // Simplified pseudo-random trait generation (NOT SECURE/TRULY RANDOM ON-CHAIN)
        // In production, use Chainlink VRF or similar.
        uint256 randomSeed = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, _fragmentCounter, block.difficulty)));
        uint16[] memory initialTraits = new uint16[](_fragmentTraitNames.length);

        for (uint i = 0; i < initialTraits.length; i++) {
            // Example initial trait calculation: influenced by random seed and environmental condition
            uint256 traitValue = (randomSeed % (MAX_TRAIT_VALUE / 2)) + (_environmentalCondition * (MAX_TRAIT_VALUE / 200));
            initialTraits[i] = uint16(traitValue > MAX_TRAIT_VALUE ? MAX_TRAIT_VALUE : traitValue);
            randomSeed = uint256(keccak256(abi.encodePacked(randomSeed, i))); // Update seed
        }

        _mintFragment(msg.sender, initialTraits);
    }

    /**
     * @dev User provides nourishment to a Fragment.
     * @param tokenId The ID of the Fragment to nourish.
     * @param essenceAmount The amount of Essence to spend.
     * @param catalystAmount The amount of Catalyst to spend.
     */
    function nourishFragment(uint256 tokenId, uint256 essenceAmount, uint256 catalystAmount) public onlyFragmentOwnerOrApproved(tokenId) {
        require(essenceAmount >= _nourishmentEssenceCost, "Not enough Essence for nourishment");
        require(catalystAmount >= _nourishmentCatalystCost, "Not enough Catalyst for nourishment");

        // Check sender's balances (handles both owner and approved/operator)
        address owner = ownerOfFragment(tokenId);
        if (msg.sender != owner) {
             // For approved/operator, check allowances if transferFrom is used
             require(allowanceEssence(owner, msg.sender) >= essenceAmount, "Essence allowance insufficient");
             require(allowanceCatalyst(owner, msg.sender) >= catalystAmount, "Catalyst allowance insufficient");
             _transferFromEssence(owner, address(this), essenceAmount); // Contract holds resources temporarily
             _transferFromCatalyst(owner, address(this), catalystAmount);
        } else {
            require(balanceOfEssence(msg.sender) >= essenceAmount, "Essence balance insufficient");
            require(balanceOfCatalyst(msg.sender) >= catalystAmount, "Catalyst balance insufficient");
             _transferEssence(msg.sender, address(this), essenceAmount); // Contract holds resources temporarily
             _transferCatalyst(msg.sender, address(this), catalystAmount);
        }

        // Simulate evolution *before* nourishment to account for time elapsed since last interaction
        _updateFragmentState(tokenId);

        FragmentState storage state = _fragmentStates[tokenId];
        // Simple nourishment logic: adds to level, capped.
        state.nourishmentLevel += (essenceAmount / _nourishmentEssenceCost) + (catalystAmount / _nourishmentCatalystCost) * 2; // Catalysts more effective
        // Cap nourishment level if desired
        // state.nourishmentLevel = state.nourishmentLevel > MAX_NOURISHMENT ? MAX_NOURISHMENT : state.nourishmentLevel;

        state.lastInteractionTime = uint48(block.timestamp); // Reset interaction timer

        // Resources are sunk into the contract, or could be directed elsewhere.
        // For simplicity, they are burned or held by the contract address.

        emit FragmentNourished(tokenId, msg.sender, essenceAmount, catalystAmount, state.nourishmentLevel);

        // Re-calculate state immediately after nourishment to reflect changes
        _updateFragmentState(tokenId);
    }


    /**
     * @dev User harvests a Fragment. Consumes nourishment and might yield Essence.
     * @param tokenId The ID of the Fragment to harvest.
     */
    function harvestFragment(uint256 tokenId) public onlyFragmentOwnerOrApproved(tokenId) {
        _updateFragmentState(tokenId); // Ensure traits are up-to-date based on time

        FragmentState storage state = _fragmentStates[tokenId];
        require(state.nourishmentLevel > 0, "Fragment needs nourishment before harvesting");

        uint256 essenceYield = 0;
        // Example harvest logic: Yield based on NourishmentLevel and specific traits
        // Let's say Vitality (trait 0) contributes directly, and Resonance (trait 1) has a multiplier
        if (_fragmentTraitNames.length > 0) {
            uint256 vitality = state.traits[0]; // Assuming Vitality is trait 0
            uint256 resonance = _fragmentTraitNames.length > 1 ? state.traits[1] : 0; // Assuming Resonance is trait 1

            essenceYield = (state.nourishmentLevel * (vitality + 100)) / 1000 // Base yield from nourishment + vitality
                           + (state.nourishmentLevel * resonance) / 500; // Additional yield from resonance multiplier

            // Ensure yield is not excessive and doesn't exceed contract's Essence balance (if not burning)
            // Simplified: Assuming contract can mint/burn or has infinite supply for example.
            // In real case, might yield from a pool or mint only up to a cap.
        } else {
             essenceYield = state.nourishmentLevel; // Basic yield if no traits defined
        }


        state.nourishmentLevel = 0; // Reset nourishment after harvest
        state.lastInteractionTime = uint48(block.timestamp); // Reset interaction timer

        // Potentially modify traits after harvest (e.g., reduce Vitality slightly)
        if (_fragmentTraitNames.length > 0) {
            state.traits[0] = uint16(state.traits[0] * 9 / 10); // Example decay on harvest
            // Ensure traits stay within bounds
             for(uint i=0; i < state.traits.length; i++) {
                state.traits[i] = uint16(state.traits[i] > MAX_TRAIT_VALUE ? MAX_TRAIT_VALUE : (state.traits[i] < MIN_TRAIT_VALUE ? MIN_TRAIT_VALUE : state.traits[i]));
            }
        }

        // Mint or transfer harvested Essence to the user
        // Assuming contract has privilege to mint for simplicity, or transfers from its balance.
        _mintEssence(msg.sender, essenceYield);


        emit FragmentHarvested(tokenId, msg.sender, essenceYield, state.traits);

         // Re-calculate state immediately after harvest to reflect changes
        _updateFragmentState(tokenId);
    }


    // --- Fragment State & Evolution Logic ---

    /**
     * @dev Internal function to update fragment state (traits) based on elapsed time.
     * Applies decay and growth since lastEvolutionUpdateTime.
     * @param tokenId The ID of the Fragment to update.
     */
    function _updateFragmentState(uint256 tokenId) internal {
         // This check is important to prevent re-calculating unnecessarily or for non-existent tokens
        if (!_exists(tokenId)) return;

        FragmentState storage state = _fragmentStates[tokenId];
        uint48 currentTime = uint48(block.timestamp);
        uint256 timeElapsed = currentTime - state.lastEvolutionUpdateTime;

        // Only update if significant time has passed
        if (timeElapsed < FRAGMENT_EVOLUTION_INTERVAL && timeElapsed < FRAGMENT_DECAY_INTERVAL) {
             return; // No need to update yet
        }

        uint256 decayPeriods = timeElapsed / FRAGMENT_DECAY_INTERVAL;
        uint256 evolutionPeriods = timeElapsed / FRAGMENT_EVOLUTION_INTERVAL;

        // Calculate total trait change (decay vs growth)
        int256[] memory traitChanges = new int256[](_fragmentTraitNames.length);

        for (uint i = 0; i < state.traits.length; i++) {
             // Apply Decay: Traits naturally decrease over time
            uint256 decayAmount = decayPeriods * _baseTraitDecayRate;

             // Apply Growth: Traits increase based on nourishment and environmental conditions
             // Higher nourishmentLevel -> more growth from evolution periods
             // Higher environmentalCondition -> more growth overall
            uint256 evolutionAmount = (evolutionPeriods * _baseTraitEvolutionRate * (state.nourishmentLevel + 1) * (_environmentalCondition + 1)) / 1000; // Scaling factors

            // Apply trait-specific boosts
            evolutionAmount = (evolutionAmount * (_fragmentTraitBoosts[i] + 100)) / 100;

            // Net change for this trait
            traitChanges[i] = int256(evolutionAmount) - int256(decayAmount);

             // Reduce nourishment level over time (consumed by evolution)
            // Simple reduction: nourishmentLevel decreases proportional to time elapsed and its current value
            state.nourishmentLevel = (state.nourishmentLevel * uint256(FRAGMENT_EVOLUTION_INTERVAL)) / (uint256(FRAGMENT_EVOLUTION_INTERVAL) + evolutionPeriods); // Example decay logic
        }


        // Apply changes and clamp values
        bool traitsChanged = false;
        for (uint i = 0; i < state.traits.length; i++) {
            int256 currentTrait = int256(state.traits[i]);
            int256 nextTrait = currentTrait + traitChanges[i];

            uint16 clampedTrait = uint16(nextTrait > int256(MAX_TRAIT_VALUE) ? MAX_TRAIT_VALUE : (nextTrait < int256(MIN_TRAIT_VALUE) ? MIN_TRAIT_VALUE : uint256(nextTrait)));

            if (state.traits[i] != clampedTrait) {
                state.traits[i] = clampedTrait;
                traitsChanged = true;
            }
        }

        state.lastEvolutionUpdateTime = currentTime; // Update the last calculation time

        if (traitsChanged) {
             emit FragmentTraitsEvolved(tokenId, state.traits);
        }
    }

     /**
     * @dev Public view function to simulate the evolution of a fragment's traits over a given time period.
     * Does NOT change contract state.
     * @param tokenId The ID of the Fragment to simulate.
     * @param timeElapsed The number of seconds to simulate evolution for.
     * @return The simulated trait values after the elapsed time.
     */
    function simulateFragmentEvolution(uint256 tokenId, uint256 timeElapsed) public view returns (uint16[] memory) {
        require(_exists(tokenId), "Fragment does not exist");

        FragmentState storage state = _fragmentStates[tokenId];
        uint16[] memory simulatedTraits = new uint16[](state.traits.length);
        for(uint i = 0; i < state.traits.length; i++) {
            simulatedTraits[i] = state.traits[i]; // Start with current traits
        }

        uint256 simulatedNourishment = state.nourishmentLevel;

        uint256 decayPeriods = timeElapsed / FRAGMENT_DECAY_INTERVAL;
        uint256 evolutionPeriods = timeElapsed / FRAGMENT_EVOLUTION_INTERVAL; // Simplified: assume constant periods within simulation

         // Calculate total trait change (decay vs growth)
        int256[] memory traitChanges = new int256[](state.traits.length);

        for (uint i = 0; i < state.traits.length; i++) {
             // Apply Decay
            uint256 decayAmount = decayPeriods * _baseTraitDecayRate;

             // Apply Growth (based on nourishment and environmental conditions *at the start* of the simulation)
            uint256 evolutionAmount = (evolutionPeriods * _baseTraitEvolutionRate * (simulatedNourishment + 1) * (_environmentalCondition + 1)) / 1000;

             // Apply trait-specific boosts
            evolutionAmount = (evolutionAmount * (_fragmentTraitBoosts[i] + 100)) / 100;

            // Net change
            traitChanges[i] = int256(evolutionAmount) - int256(decayAmount);

             // Simulate nourishment decay over this period (simplified linear decay for view function)
             // In a real simulation you might iterate or use more complex math
            simulatedNourishment = (simulatedNourishment * uint256(FRAGMENT_EVOLUTION_INTERVAL * evolutionPeriods)) / (uint256(FRAGMENT_EVOLUTION_INTERVAL * evolutionPeriods) + timeElapsed);
        }

        // Apply changes and clamp values for simulation
        for (uint i = 0; i < simulatedTraits.length; i++) {
            int256 currentTrait = int256(simulatedTraits[i]);
            int256 nextTrait = currentTrait + traitChanges[i];

            simulatedTraits[i] = uint16(nextTrait > int256(MAX_TRAIT_VALUE) ? MAX_TRAIT_VALUE : (nextTrait < int256(MIN_TRAIT_VALUE) ? MIN_TRAIT_VALUE : uint256(nextTrait)));
        }

        return simulatedTraits;
    }


    // --- Environmental & Parameter Control Functions ---

    function triggerEnvironmentalShift(uint256 newConditionValue) public onlyOwner {
         require(newConditionValue <= 100, "Condition value must be <= 100"); // Example constraint
        uint256 oldCondition = _environmentalCondition;
        _environmentalCondition = newConditionValue;
        emit EnvironmentalShift(oldCondition, newConditionValue);
        emit ParametersUpdated("EnvironmentalCondition", new uint256[](1) ); // Simplified event, no value needed
    }

    function setNourishmentCosts(uint256 essenceCost, uint256 catalystCost) public onlyOwner {
        _nourishmentEssenceCost = essenceCost;
        _nourishmentCatalystCost = catalystCost;
        emit ParametersUpdated("NourishmentCosts", new uint256[](2));
    }

    function setDiscoveryCost(uint256 essenceCost, uint256 catalystCost) public onlyOwner {
        _discoveryEssenceCost = essenceCost;
        _discoveryCatalystCost = catalystCost;
        emit ParametersUpdated("DiscoveryCost", new uint256[](2));
    }

    function setBaseRates(uint256 baseEvolutionRate, uint256 baseDecayRate) public onlyOwner {
        _baseTraitEvolutionRate = baseEvolutionRate;
        _baseTraitDecayRate = baseDecayRate;
         emit ParametersUpdated("BaseRates", new uint256[](2));
    }

    function setFragmentTraitNames(string[] memory traitNames) public onlyOwner {
        // Add validation if number of traits must be constant
        // require(traitNames.length == _fragmentTraitNames.length, "Trait count must match");
        _fragmentTraitNames = traitNames;
         emit ParametersUpdated("FragmentTraitNames", new uint256[](0)); // No numerical value relevant
    }

    function setFragmentTraitBoosts(uint256 traitIndex, uint256 boost) public onlyOwner {
        require(traitIndex < _fragmentTraitNames.length, "Invalid trait index");
        _fragmentTraitBoosts[traitIndex] = boost;
         emit ParametersUpdated("FragmentTraitBoosts", new uint256[](2)); // traitIndex, boostValue
    }

    // Fallback/Receive to accept Ether (optional, depending on design - not used here)
    // receive() external payable {}
    // fallback() external payable {}
}
```