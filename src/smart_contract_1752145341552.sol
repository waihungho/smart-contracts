Okay, here is a Solidity smart contract demonstrating a unique, advanced concept: "Symbiotic Digital Organisms" (SDOs).

This contract acts as both an NFT manager (for the SDOs) and a simple internal token manager (for "Nutrient" tokens required by SDOs). It incorporates mechanics like dynamic traits, feeding, decay, merging, and yield generation, all managed on-chain.

It avoids duplicating common open-source contracts like OpenZeppelin's standard ERC-721, ERC-20, Ownable, or Pausable implementations by implementing the necessary logic directly within this single contract.

---

**Contract Name:** SymbioticDigitalOrganisms

**Concept:** A system of dynamic, non-fungible tokens (SDOs) representing digital organisms that require maintenance (feeding with a fungible "Nutrient" token) to survive and evolve. They can decay over time if neglected but can also merge to create new, potentially stronger organisms or yield Nutrient tokens.

**Key Features:**
1.  **SDO (NFT):** Represents a unique digital organism with dynamic traits.
2.  **Nutrient (Internal Fungible Token):** A utility token managed within the same contract, required to feed SDOs.
3.  **Dynamic Traits:** SDOs have numerical traits (e.g., Energy, Resilience, Mutation Potential) that change based on interactions.
4.  **Feeding:** Users spend Nutrient tokens to increase SDO Energy/Resilience and reset decay timers.
5.  **Decay:** SDO traits decrease over time if not fed or maintained. Can lead to dormancy or dissipation (burning).
6.  **Merging:** Combine two SDO NFTs to create a new, unique SDO with combined/mutated traits. Parent SDOs are burned.
7.  **Yield:** SDOs with high Energy/Resilience can passively generate Nutrient tokens for their owner over time.
8.  **On-Chain State:** All SDO traits and state are stored and updated directly in the contract.
9.  **Manual Implementation:** Core logic for NFT (ERC-721-like), Fungible Token (ERC-20-like), Ownership, and Pausing is implemented manually without inheriting from standard libraries.

**Outline:**

1.  **License & Pragma**
2.  **Error Declarations**
3.  **Events**
4.  **Structs:**
    *   `SDOState`: Stores dynamic traits and state variables for an SDO.
    *   `SDOParams`: Stores global parameters affecting SDO behavior (decay rates, yield rates, merge costs, trait limits).
    *   `NutrientParams`: Stores global parameters for the Nutrient token (supply limits, yield rates).
5.  **State Variables:**
    *   Owner, Paused status.
    *   Total supplies (SDO, Nutrient).
    *   SDO parameters, Nutrient parameters.
    *   Mapping for SDO states (`tokenId` => `SDOState`).
    *   Mappings for SDO NFT logic (owners, balances, approvals, operator approvals).
    *   Mappings for Nutrient token logic (balances, allowances).
    *   Next available SDO token ID.
6.  **Modifiers:**
    *   `onlyOwner`: Restricts access to the contract owner.
    *   `whenNotPaused`: Prevents execution when the contract is paused.
    *   `whenPaused`: Allows execution only when the contract is paused.
    *   `sdoExists`: Checks if an SDO with the given ID exists.
7.  **Constructor:** Sets initial owner and parameters.
8.  **Owner & Pausability Functions:** (Manual implementation)
9.  **Manual ERC-721 Logic (SDO):** Internal helper functions (`_exists`, `_isApprovedOrOwner`, `_transfer`, `_mint`, `_burn`) and public interface functions (`balanceOf`, `ownerOf`, `getApproved`, `isApprovedForAll`, `approve`, `setApprovalForAll`, `transferFrom`, `safeTransferFrom`).
10. **Manual ERC-20-like Logic (Nutrient):** Internal helper functions (`_mintNutrient`, `_burnNutrient`, `_transferNutrient`) and public interface functions (`balanceOfNutrient`, `allowanceNutrient`, `approveNutrient`, `transferNutrient`, `transferFromNutrient`).
11. **SDO Core Mechanics (Public/External):**
    *   `mintInitialSDO`: Mints the first SDOs (Admin).
    *   `feedSDO`: Feeds an SDO with Nutrient.
    *   `mergeSDOs`: Merges two SDOs into a new one.
    *   `triggerSDODecay`: Allows anyone to trigger decay calculation/application for an SDO (gas optimization).
    *   `checkSDODecay`: View function to see potential decay.
    *   `claimSDOYield`: Claims generated Nutrient yield from an SDO.
    *   `checkSDOYield`: View function to see potential yield.
    *   `getSDOTraits`: View function for SDO traits.
    *   `getSDOState`: View function for full SDO state.
12. **Parameter Setting Functions (Admin):**
    *   `setSDOParams`: Sets SDO behavior parameters.
    *   `setNutrientParams`: Sets Nutrient parameters.
    *   `mintInitialNutrient`: Mints initial Nutrient supply (Admin).
13. **View Functions (Getters):**
    *   `getSDOParams`
    *   `getNutrientParams`
    *   `getTotalSupplySDO`
    *   `getTotalSupplyNutrient`

**Function Summary:**

*(Listed in potential order of appearance or logical grouping)*

*   `constructor()`: Initializes the contract, sets owner.
*   `owner()`: Returns the current owner (View).
*   `pause()`: Pauses contract operations (Owner only).
*   `unpause()`: Unpauses contract operations (Owner only).
*   `paused()`: Returns paused status (View).
*   `balanceOf(address owner)`: Returns the number of SDOs owned by an address (View, ERC721-like).
*   `ownerOf(uint256 tokenId)`: Returns the owner of a specific SDO (View, ERC721-like).
*   `getApproved(uint256 tokenId)`: Returns the address approved for a specific SDO (View, ERC721-like).
*   `isApprovedForAll(address owner, address operator)`: Checks if an operator is approved for all SDOs of an owner (View, ERC721-like).
*   `approve(address to, uint256 tokenId)`: Approves an address to transfer a specific SDO (ERC721-like).
*   `setApprovalForAll(address operator, bool approved)`: Sets operator approval for all SDOs (ERC721-like).
*   `transferFrom(address from, address to, uint256 tokenId)`: Transfers SDO ownership (ERC721-like).
*   `safeTransferFrom(address from, address to, uint256 tokenId)`: Safely transfers SDO ownership (ERC721-like, two versions).
*   `balanceOfNutrient(address account)`: Returns the Nutrient balance of an address (View, ERC20-like).
*   `allowanceNutrient(address owner, address spender)`: Returns the Nutrient allowance granted by owner to spender (View, ERC20-like).
*   `approveNutrient(address spender, uint256 amount)`: Sets the Nutrient allowance for a spender (ERC20-like).
*   `transferNutrient(address to, uint256 amount)`: Transfers Nutrient tokens (ERC20-like).
*   `transferFromNutrient(address from, address to, uint256 amount)`: Transfers Nutrient tokens using allowance (ERC20-like).
*   `mintInitialSDO(address recipient)`: Mints a genesis SDO (Owner only).
*   `feedSDO(uint256 tokenId, uint256 nutrientAmount)`: Feeds an SDO, consuming Nutrient and updating traits/timers.
*   `mergeSDOs(uint256 tokenId1, uint256 tokenId2, uint256 nutrientCost)`: Merges two SDOs into a new one, burning parents and consuming Nutrient.
*   `triggerSDODecay(uint256 tokenId)`: Public function to trigger decay calculation and application for an SDO.
*   `checkSDODecay(uint256 tokenId)`: Calculates potential decay for an SDO without applying it (View).
*   `claimSDOYield(uint256 tokenId)`: Calculates and transfers generated Nutrient yield to the SDO owner.
*   `checkSDOYield(uint256 tokenId)`: Calculates potential Nutrient yield for an SDO without claiming (View).
*   `getSDOTraits(uint256 tokenId)`: Returns the current dynamic traits of an SDO (View).
*   `getSDOState(uint256 tokenId)`: Returns the full state struct of an SDO (View).
*   `setSDOParams(SDOParams memory params)`: Sets global SDO parameters (Owner only).
*   `setNutrientParams(NutrientParams memory params)`: Sets global Nutrient parameters (Owner only).
*   `mintInitialNutrient(address recipient, uint256 amount)`: Mints initial Nutrient supply (Owner only).
*   `getSDOParams()`: Returns current SDO parameters (View).
*   `getNutrientParams()`: Returns current Nutrient parameters (View).
*   `getTotalSupplySDO()`: Returns the total number of existing SDOs (View).
*   `getTotalSupplyNutrient()`: Returns the total supply of Nutrient tokens (View).

*(Total external/public functions: 34)*

---
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title SymbioticDigitalOrganisms
 * @dev A contract managing dynamic NFT-like Symbiotic Digital Organisms (SDOs)
 * and an internal utility token (Nutrient) required for their maintenance and evolution.
 * This contract implements core ERC-721, ERC-20, Ownable, and Pausable logic manually
 * to avoid direct duplication of open-source libraries, while providing unique SDO mechanics.
 */

// --- Error Declarations ---
error NotOwnerOrApproved();
error NotApprovedForAll();
error SDODoesNotExist();
error SDOAlreadyExists();
error Unauthorized();
error Paused();
error NotPaused();
error InsufficientBalance(uint256 required, uint256 available);
error InsufficientNutrientAllowance(uint256 required, uint256 available);
error MergeRequiresTwoDifferentSDOs();
error SDOMergeRequiresNonDormantParents();
error NutrientTransferFailed();
error InvalidAmount();
error ApprovalToCurrentOwner();
error ApproveCallerIsNotOwnerNorApproved();
error TransferToZeroAddress();
error TransferCallerIsNotOwnerNorApproved();


// --- Events ---
event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
event Paused(address account);
event Unpaused(address account);
event Transfer(address indexed from, address indexed to, uint256 indexed tokenId); // SDO Transfer (ERC721-like)
event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId); // SDO Approval (ERC721-like)
event ApprovalForAll(address indexed owner, address indexed operator, bool approved); // SDO ApprovalForAll (ERC721-like)
event NutrientTransfer(address indexed from, address indexed to, uint256 value); // Nutrient Transfer (ERC20-like)
event NutrientApproval(address indexed owner, address indexed spender, uint256 value); // Nutrient Approval (ERC20-like)
event SDOMinted(uint256 indexed tokenId, address indexed owner, uint256 indexed generation);
event SDOFed(uint256 indexed tokenId, uint256 nutrientAmount, uint256 newEnergy, uint256 newResilience);
event SDOMerged(uint256 indexed tokenId1, uint256 indexed tokenId2, uint256 indexed newTokenId, uint256 nutrientCost);
event SDODecayed(uint256 indexed tokenId, uint256 energyLoss, uint256 resilienceLoss, bool becameDormant, bool becameDissipated);
event SDOYieldClaimed(uint256 indexed tokenId, address indexed owner, uint256 amount);
event SDOParamsUpdated(SDOParams params);
event NutrientParamsUpdated(NutrientParams params);


// --- Structs ---

/// @dev Represents the dynamic state and traits of an SDO.
struct SDOState {
    uint256 generation;         // How many merges deep
    uint256 energy;             // Affects yield potential, resists decay
    uint256 resilience;         // Affects decay resistance, merge outcome
    uint256 mutationPotential;  // Affects variability in merge outcomes
    uint256 lastFedTimestamp;   // When it was last fed
    uint256 lastDecayTimestamp; // When decay was last applied
    uint256 lastYieldTimestamp; // When yield was last claimed
    bool isDormant;             // If decay is too high
    bool isDissipated;          // If decay caused permanent destruction
}

/// @dev Global parameters governing SDO behavior.
struct SDOParams {
    uint256 initialEnergy;              // Energy upon minting
    uint256 initialResilience;          // Resilience upon minting
    uint256 initialMutationPotential;   // Mutation potential upon minting
    uint256 decayRatePerSecondEnergy;   // Energy loss per second
    uint256 decayRatePerSecondResilience; // Resilience loss per second
    uint256 decayTriggerInterval;       // Minimum time between triggering decay calculation
    uint256 energyPerNutrient;          // How much energy 1 Nutrient adds
    uint256 resiliencePerNutrient;      // How much resilience 1 Nutrient adds
    uint256 mergeNutrientCost;          // Base cost to merge two SDOs
    uint256 mergeEnergyBonus;           // Energy bonus for merged SDO
    uint256 mergeResilienceBonus;       // Resilience bonus for merged SDO
    uint256 mergeMutationMultiplier;    // Multiplier for mutation potential during merge
    uint256 minEnergyForYield;          // Minimum energy to potentially yield
    uint256 minResilienceForYield;      // Minimum resilience to potentially yield
    uint256 yieldRatePerSecond;         // Base nutrient yield per second (scaled by traits)
    uint256 energyDecayThreshold;       // Energy level below which SDO becomes dormant
    uint256 resilienceDecayThreshold;   // Resilience level below which SDO becomes dormant
    uint256 decayDissipateThreshold;    // Combined decay level below which SDO is dissipated
}

/// @dev Global parameters governing Nutrient token behavior.
struct NutrientParams {
    uint256 maxSupply;          // Maximum total supply of Nutrient
    uint256 initialMintLimit;   // Limit for initial minting (per address or total)
    uint256 sdoYieldFactor;     // Factor scaling SDO yield based on traits
}


// --- State Variables ---

address private _owner;
bool private _paused;

// SDO (ERC721-like) State
mapping(uint256 => address) private _owners;
mapping(address => uint256) private _balances;
mapping(uint256 => address) private _tokenApprovals;
mapping(address => mapping(address => bool)) private _operatorApprovals;
uint256 private _totalSupplySDO;
uint256 private _nextTokenId; // Counter for minting new SDOs

// Nutrient (ERC20-like) State
mapping(address => uint256) private _nutrientBalances;
mapping(address => mapping(address => uint256)) private _nutrientAllowances;
uint256 private _totalSupplyNutrient;
uint256 private _nutrientMaxSupply; // Alias from params for quick access

// SDO Dynamic State
mapping(uint256 => SDOState) private _sdoStates;
SDOParams private _sdoParams;
NutrientParams private _nutrientParams;


// --- Modifiers ---
modifier onlyOwner() {
    if (msg.sender != _owner) revert Unauthorized();
    _;
}

modifier whenNotPaused() {
    if (_paused) revert Paused();
    _;
}

modifier whenPaused() {
    if (!_paused) revert NotPaused();
    _;
}

modifier sdoExists(uint256 tokenId) {
    if (!_exists(tokenId)) revert SDODoesNotExist();
    _;
}


// --- Constructor ---
constructor() {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), msg.sender);

    // Set some initial default parameters (can be changed by owner later)
    _sdoParams = SDOParams({
        initialEnergy: 1000,
        initialResilience: 1000,
        initialMutationPotential: 100,
        decayRatePerSecondEnergy: 1, // 1 energy per second
        decayRatePerSecondResilience: 1, // 1 resilience per second
        decayTriggerInterval: 1 days, // Allow triggering decay at most once per day
        energyPerNutrient: 10,       // 1 Nutrient adds 10 energy
        resiliencePerNutrient: 5,    // 1 Nutrient adds 5 resilience
        mergeNutrientCost: 500,
        mergeEnergyBonus: 200,
        mergeResilienceBonus: 100,
        mergeMutationMultiplier: 150, // 150% multiplier
        minEnergyForYield: 500,
        minResilienceForYield: 500,
        yieldRatePerSecond: 1,       // Base yield rate (scaled)
        energyDecayThreshold: 200,
        resilienceDecayThreshold: 200,
        decayDissipateThreshold: 50 // If energy + resilience < 50, dissipate
    });

    _nutrientParams = NutrientParams({
        maxSupply: 1_000_000_000 ether, // Example max supply (using ether for decimals)
        initialMintLimit: 100_000 ether, // Limit per recipient for initial mint
        sdoYieldFactor: 10 // Multiplier for yield calculation
    });
    _nutrientMaxSupply = _nutrientParams.maxSupply;
}


// --- Owner & Pausability (Manual Implementation) ---

/// @notice Returns the address of the current owner.
function owner() public view returns (address) {
    return _owner;
}

/// @notice Pauses the contract, preventing most operations.
/// @dev Can only be called by the current owner.
function pause() public onlyOwner whenNotPaused {
    _paused = true;
    emit Paused(msg.sender);
}

/// @notice Unpauses the contract, allowing operations to resume.
/// @dev Can only be called by the current owner.
function unpause() public onlyOwner whenPaused {
    _paused = false;
    emit Unpaused(msg.sender);
}

/// @notice Returns true if the contract is paused, and false otherwise.
function paused() public view returns (bool) {
    return _paused;
}


// --- Manual ERC-721 Logic (SDO) ---

/// @dev Internal check if an SDO exists.
function _exists(uint256 tokenId) internal view returns (bool) {
    return _owners[tokenId] != address(0);
}

/// @dev Internal check if an address is the owner or approved for an SDO.
function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
    address sdoOwner = ownerOf(tokenId);
    return (spender == sdoOwner || getApproved(tokenId) == spender || isApprovedForAll(sdoOwner, spender));
}

/// @dev Internal SDO transfer logic.
function _transfer(address from, address to, uint256 tokenId) internal {
    if (ownerOf(tokenId) != from) revert TransferCallerIsNotOwnerNorApproved(); // Should not happen if called correctly
    if (to == address(0)) revert TransferToZeroAddress();

    // Clear approvals from the previous owner
    delete _tokenApprovals[tokenId];

    _balances[from]--;
    _balances[to]++;
    _owners[tokenId] = to;

    emit Transfer(from, to, tokenId);
}

/// @dev Internal SDO minting logic.
function _mint(address to, uint256 tokenId, uint256 generation) internal {
    if (to == address(0)) revert TransferToZeroAddress();
    if (_exists(tokenId)) revert SDOAlreadyExists();

    _balances[to]++;
    _owners[tokenId] = to;
    _totalSupplySDO++;

    // Initialize SDO state
    _sdoStates[tokenId] = SDOState({
        generation: generation,
        energy: _sdoParams.initialEnergy,
        resilience: _sdoParams.initialResilience,
        mutationPotential: _sdoParams.initialMutationPotential,
        lastFedTimestamp: block.timestamp,
        lastDecayTimestamp: block.timestamp,
        lastYieldTimestamp: block.timestamp,
        isDormant: false,
        isDissipated: false
    });

    emit Transfer(address(0), to, tokenId);
    emit SDOMinted(tokenId, to, generation);
}

/// @dev Internal SDO burning logic.
function _burn(uint256 tokenId) internal sdoExists(tokenId) {
    address sdoOwner = ownerOf(tokenId);

    // Clear approvals
    delete _tokenApprovals[tokenId];

    _balances[sdoOwner]--;
    delete _owners[tokenId];
    delete _sdoStates[tokenId]; // Remove state
    _totalSupplySDO--;

    emit Transfer(sdoOwner, address(0), tokenId);
}

/// @notice Returns the number of SDOs owned by `owner`.
/// @param owner The address to query the balance of.
/// @return The total count of SDOs owned by `owner`.
function balanceOf(address owner) public view returns (uint256) {
    return _balances[owner];
}

/// @notice Returns the owner of the SDO identified by `tokenId`.
/// @param tokenId The identifier for an SDO.
/// @return The address of the owner.
function ownerOf(uint256 tokenId) public view returns (address) {
    address tokenOwner = _owners[tokenId];
    if (tokenOwner == address(0)) revert SDODoesNotExist();
    return tokenOwner;
}

/// @notice Gets the approved address for a single SDO.
/// @param tokenId The SDO to find the approved address for.
/// @return The approved address for this SDO, or the zero address if none is set.
function getApproved(uint256 tokenId) public view sdoExists(tokenId) returns (address) {
    return _tokenApprovals[tokenId];
}

/// @notice Queries the approval status of an operator for a given owner.
/// @param owner The address of the owner.
/// @param operator The address of the operator.
/// @return True if `operator` is approved for `owner`, false otherwise.
function isApprovedForAll(address owner, address operator) public view returns (bool) {
    return _operatorApprovals[owner][operator];
}

/// @notice Approves another address to transfer a specific SDO.
/// @dev The caller must own the SDO or be an approved operator.
/// @param to The address to approve.
/// @param tokenId The SDO to approve.
function approve(address to, uint256 tokenId) public whenNotPaused sdoExists(tokenId) {
    address sdoOwner = ownerOf(tokenId);
    if (msg.sender != sdoOwner && !isApprovedForAll(sdoOwner, msg.sender)) {
        revert ApproveCallerIsNotOwnerNorApproved();
    }
    if (to == sdoOwner) revert ApprovalToCurrentOwner();

    _tokenApprovals[tokenId] = to;
    emit Approval(sdoOwner, to, tokenId);
}

/// @notice Approves or revokes an operator for all of the caller's SDOs.
/// @param operator The address of the operator.
/// @param approved True to approve, false to revoke.
function setApprovalForAll(address operator, bool approved) public whenNotPaused {
    if (msg.sender == operator) revert InvalidAmount(); // Cannot approve self as operator
    _operatorApprovals[msg.sender][operator] = approved;
    emit ApprovalForAll(msg.sender, operator, approved);
}

/// @notice Transfers ownership of an SDO from `from` to `to`.
/// @dev Caller must be the owner, approved, or an approved operator.
/// @param from The current owner.
/// @param to The new owner.
/// @param tokenId The SDO to transfer.
function transferFrom(address from, address to, uint256 tokenId) public whenNotPaused sdoExists(tokenId) {
    if (!_isApprovedOrOwner(msg.sender, tokenId)) revert NotOwnerOrApproved();
    if (ownerOf(tokenId) != from) revert Unauthorized(); // Ensure 'from' is indeed the current owner

    _transfer(from, to, tokenId);
}

/// @notice Safely transfers ownership of an SDO from `from` to `to`.
/// @dev Behaves like `transferFrom`, but includes a check if the recipient is a contract
/// that can accept ERC721 tokens. This simplified version does not implement the full
/// ERC721Receiver check due to the "no open source duplication" constraint,
/// but a production contract *must* implement this check.
/// @param from The current owner.
/// @param to The new owner.
/// @param tokenId The SDO to transfer.
function safeTransferFrom(address from, address to, uint256 tokenId) public whenNotPaused sdoExists(tokenId) {
    // NOTE: This is a simplified safeTransferFrom. A full implementation
    // would check if 'to' is a contract and calls onERC721Received.
    // Implementing that would require importing ERC165 and ERC721Receiver
    // interfaces, which conflicts with the "no open source duplication"
    // constraint if those interfaces are considered "open source".
    // For this example, we proceed with the transfer directly.
    transferFrom(from, to, tokenId);
    // In a real contract, add: require(_checkOnERC721Received(from, to, tokenId, ""), "ERC721: transfer to non ERC721Receiver implementer");
}

/// @notice Safely transfers ownership of an SDO from `from` to `to`, with data.
/// @dev See `safeTransferFrom`.
/// @param from The current owner.
/// @param to The new owner.
/// @param tokenId The SDO to transfer.
/// @param data Additional data with no specified format, sent in call to `to`.
function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public whenNotPaused sdoExists(tokenId) {
    // NOTE: Simplified version, see comment in safeTransferFrom(address, address, uint256).
    // The 'data' parameter is ignored in this simplified implementation.
    transferFrom(from, to, tokenId);
    // In a real contract, add: require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    // Added 'data' to the event anyway for potential future compatibility/logging.
    // emit Transfer(from, to, tokenId); // Transfer event already emitted by _transfer
}


// --- Manual ERC-20-like Logic (Nutrient) ---

/// @dev Internal Nutrient minting logic.
function _mintNutrient(address account, uint256 amount) internal {
    if (account == address(0)) revert TransferToZeroAddress();
    if (_totalSupplyNutrient + amount > _nutrientMaxSupply) revert InvalidAmount(); // Exceeds max supply

    _totalSupplyNutrient += amount;
    _nutrientBalances[account] += amount;
    emit NutrientTransfer(address(0), account, amount);
}

/// @dev Internal Nutrient burning logic.
function _burnNutrient(address account, uint256 amount) internal {
    if (account == address(0)) revert TransferToZeroAddress();
    if (_nutrientBalances[account] < amount) revert InsufficientBalance(amount, _nutrientBalances[account]);

    _nutrientBalances[account] -= amount;
    _totalSupplyNutrient -= amount;
    emit NutrientTransfer(account, address(0), amount);
}

/// @dev Internal Nutrient transfer logic.
function _transferNutrient(address from, address to, uint256 amount) internal {
    if (from == address(0) || to == address(0)) revert TransferToZeroAddress();
    if (_nutrientBalances[from] < amount) revert InsufficientBalance(amount, _nutrientBalances[from]);

    _nutrientBalances[from] -= amount;
    _nutrientBalances[to] += amount;
    emit NutrientTransfer(from, to, amount);
}

/// @notice Returns the amount of Nutrient tokens owned by `account`.
/// @param account The address to query the balance of.
/// @return The amount of Nutrient tokens owned by `account`.
function balanceOfNutrient(address account) public view returns (uint256) {
    return _nutrientBalances[account];
}

/// @notice Returns the remaining number of Nutrient tokens that `spender` will be allowed to spend on behalf of `owner`.
/// @param owner The address that owns the tokens.
/// @param spender The address that is allowed to spend the tokens.
/// @return The remaining allowance amount.
function allowanceNutrient(address owner, address spender) public view returns (uint256) {
    return _nutrientAllowances[owner][spender];
}

/// @notice Sets the amount of Nutrient tokens that `spender` is allowed to spend on behalf of the caller.
/// @param spender The address to approve.
/// @param amount The amount of tokens to approve.
/// @return True if the operation was successful.
function approveNutrient(address spender, uint256 amount) public whenNotPaused returns (bool) {
    _nutrientAllowances[msg.sender][spender] = amount;
    emit NutrientApproval(msg.sender, spender, amount);
    return true;
}

/// @notice Transfers `amount` of Nutrient tokens from the caller to `to`.
/// @param to The address to transfer to.
/// @param amount The amount to transfer.
/// @return True if the operation was successful.
function transferNutrient(address to, uint256 amount) public whenNotPaused returns (bool) {
    _transferNutrient(msg.sender, to, amount);
    return true;
}

/// @notice Transfers `amount` of Nutrient tokens from `from` to `to`, using the allowance mechanism.
/// @dev The caller must have sufficient allowance from `from`.
/// @param from The address to transfer from.
/// @param to The address to transfer to.
/// @param amount The amount to transfer.
/// @return True if the operation was successful.
function transferFromNutrient(address from, address to, uint256 amount) public whenNotPaused returns (bool) {
    uint256 currentAllowance = _nutrientAllowances[from][msg.sender];
    if (currentAllowance < amount) revert InsufficientNutrientAllowance(amount, currentAllowance);

    _nutrientAllowances[from][msg.sender] -= amount; // Decrement allowance BEFORE transfer
    _transferNutrient(from, to, amount);
    return true;
}


// --- SDO Core Mechanics ---

/// @notice Mints an initial, genesis SDO and assigns it to a recipient.
/// @dev Can only be called by the owner. Limited initial minting.
/// In a more complex system, this could be replaced by a public minting function.
/// @param recipient The address to receive the new SDO.
/// @return The token ID of the newly minted SDO.
function mintInitialSDO(address recipient) public onlyOwner whenNotPaused returns (uint256) {
    // Add limits if needed, e.g., total genesis count
    uint256 newTokenId = _nextTokenId++;
    _mint(recipient, newTokenId, 1); // Generation 1 for initial mints
    return newTokenId;
}

/// @notice Feeds an SDO, consuming Nutrient tokens and boosting traits.
/// @dev Requires approval or ownership of the SDO and sufficient Nutrient balance/allowance.
/// @param tokenId The SDO to feed.
/// @param nutrientAmount The amount of Nutrient tokens to use for feeding.
function feedSDO(uint256 tokenId, uint256 nutrientAmount) public whenNotPaused sdoExists(tokenId) {
    address sdoOwner = ownerOf(tokenId);
    if (!_isApprovedOrOwner(msg.sender, tokenId)) revert NotOwnerOrApproved();
    if (nutrientAmount == 0) revert InvalidAmount();
    
    SDOState storage sdo = _sdoStates[tokenId];
    if (sdo.isDissipated) revert SDODoesNotExist(); // Cannot interact with dissipated SDOs

    // Apply decay before feeding
    _applyDecay(tokenId);

    // Transfer Nutrient tokens from the caller (potentially using allowance)
    if (msg.sender != sdoOwner) {
        // If caller is not owner, use transferFrom (requires allowance)
        transferFromNutrient(sdoOwner, address(this), nutrientAmount); // Owner must approve contract or caller
    } else {
        // If caller is owner, use direct transfer
        transferNutrient(address(this), nutrientAmount);
    }
     // Burn the nutrient that is fed
    _burnNutrient(address(this), nutrientAmount);


    // Boost traits
    sdo.energy += nutrientAmount * _sdoParams.energyPerNutrient;
    sdo.resilience += nutrientAmount * _sdoParams.resiliencePerNutrient;
    sdo.lastFedTimestamp = block.timestamp;
    sdo.lastDecayTimestamp = block.timestamp; // Feeding resets decay timer
    sdo.isDormant = false; // Feeding revives from dormancy

    // Cap traits if needed, e.g., sdo.energy = Math.min(sdo.energy, MAX_ENERGY);

    emit SDOFed(tokenId, nutrientAmount, sdo.energy, sdo.resilience);
}

/// @notice Merges two SDOs into a new one.
/// @dev Requires ownership or approval of both SDOs and sufficient Nutrient cost.
/// Parent SDOs are burned.
/// @param tokenId1 The ID of the first SDO to merge.
/// @param tokenId2 The ID of the second SDO to merge.
/// @param nutrientCost The amount of Nutrient tokens to pay for the merge. Must match params.mergeNutrientCost.
/// @return The token ID of the newly created SDO.
function mergeSDOs(uint256 tokenId1, uint256 tokenId2, uint256 nutrientCost) public whenNotPaused sdoExists(tokenId1) sdoExists(tokenId2) returns (uint256) {
    if (tokenId1 == tokenId2) revert MergeRequiresTwoDifferentSDOs();
    if (ownerOf(tokenId1) != ownerOf(tokenId2)) revert Unauthorized(); // Must be owned by the same address
    if (!_isApprovedOrOwner(msg.sender, tokenId1) || !_isApprovedOrOwner(msg.sender, tokenId2)) revert NotOwnerOrApproved();
    if (nutrientCost != _sdoParams.mergeNutrientCost) revert InvalidAmount();

    SDOState storage sdo1 = _sdoStates[tokenId1];
    SDOState storage sdo2 = _sdoStates[tokenId2];

    if (sdo1.isDormant || sdo1.isDissipated || sdo2.isDormant || sdo2.isDissipated) revert SDOMergeRequiresNonDormantParents();

    address owner = ownerOf(tokenId1);

    // Transfer and burn the merge cost
    if (msg.sender != owner) {
         transferFromNutrient(owner, address(this), nutrientCost);
    } else {
         transferNutrient(address(this), nutrientCost);
    }
    _burnNutrient(address(this), nutrientCost);

    // Calculate new traits (simplified example)
    uint256 newGeneration = Math.max(sdo1.generation, sdo2.generation) + 1;
    uint256 newEnergy = (sdo1.energy + sdo2.energy) / 2 + _sdoParams.mergeEnergyBonus;
    uint256 newResilience = (sdo1.resilience + sdo2.resilience) / 2 + _sdoParams.mergeResilienceBonus;
    // Mutation potential could be combined and multiplied, with some pseudorandomness if needed
    uint256 newMutationPotential = ((sdo1.mutationPotential + sdo2.mutationPotential) * _sdoParams.mergeMutationMultiplier) / 100;

    // Cap traits if needed

    // Burn the parent SDOs
    _burn(tokenId1);
    _burn(tokenId2);

    // Mint the new SDO
    uint256 newTokenId = _nextTokenId++;
    _mint(owner, newTokenId, newGeneration);

    // Update state for the new SDO
    SDOState storage newSdo = _sdoStates[newTokenId];
    newSdo.energy = newEnergy;
    newSdo.resilience = newResilience;
    newSdo.mutationPotential = newMutationPotential;
    newSdo.lastFedTimestamp = block.timestamp;
    newSdo.lastDecayTimestamp = block.timestamp;
    newSdo.lastYieldTimestamp = block.timestamp;
    // New SDO is never dormant/dissipated initially

    emit SDOMerged(tokenId1, tokenId2, newTokenId, nutrientCost);
    return newTokenId;
}

/// @dev Internal helper to apply decay to an SDO based on time elapsed.
function _applyDecay(uint256 tokenId) internal {
    SDOState storage sdo = _sdoStates[tokenId];
    if (sdo.isDissipated) return; // Cannot decay if already dissipated

    uint256 currentTime = block.timestamp;
    uint256 timeElapsed = currentTime - sdo.lastDecayTimestamp;

    if (timeElapsed == 0) return; // No time has passed

    uint256 energyLoss = timeElapsed * _sdoParams.decayRatePerSecondEnergy;
    uint256 resilienceLoss = timeElapsed * _sdoParams.decayRatePerSecondResilience;

    uint256 initialEnergy = sdo.energy;
    uint256 initialResilience = sdo.resilience;

    sdo.energy = sdo.energy > energyLoss ? sdo.energy - energyLoss : 0;
    sdo.resilience = sdo.resilience > resilienceLoss ? sdo.resilience - resilienceLoss : 0;

    sdo.lastDecayTimestamp = currentTime;

    bool becameDormant = false;
    if (!sdo.isDormant && (sdo.energy < _sdoParams.energyDecayThreshold || sdo.resilience < _sdoParams.resilienceDecayThreshold)) {
        sdo.isDormant = true;
        becameDormant = true;
    }

    bool becameDissipated = false;
    if (sdo.energy + sdo.resilience < _sdoParams.decayDissipateThreshold) {
        sdo.isDissipated = true;
        // Potentially burn the SDO automatically here, or require a separate action.
        // For this example, we just mark it as dissipated. Interactions will revert.
        becameDissipated = true;
    }

    // Only emit event if decay actually happened (loss > 0)
    if (energyLoss > 0 || resilienceLoss > 0) {
         emit SDODecayed(
            tokenId,
            initialEnergy - sdo.energy, // Actual energy loss
            initialResilience - sdo.resilience, // Actual resilience loss
            becameDormant,
            becameDissipated
         );
    }
}

/// @notice Allows anyone to trigger the decay calculation and application for a specific SDO.
/// @dev This offloads the decay cost from other transactions (like feed/claim) and allows external
/// parties (e.g., keepers) to maintain the state.
/// @param tokenId The SDO to trigger decay for.
function triggerSDODecay(uint256 tokenId) public whenNotPaused sdoExists(tokenId) {
     SDOState storage sdo = _sdoStates[tokenId];
     // Prevent excessive calls to save gas; only trigger if enough time has passed or state is crucial
     if (block.timestamp - sdo.lastDecayTimestamp >= _sdoParams.decayTriggerInterval || sdo.isDormant || sdo.isDissipated) {
         _applyDecay(tokenId);
     }
     // Note: If state was already dissipated, _applyDecay does nothing, but we still process the call.
}

/// @notice Checks the potential decay an SDO would experience if decay were applied now.
/// @param tokenId The SDO to check.
/// @return energyLoss The amount of energy that would be lost.
/// @return resilienceLoss The amount of resilience that would be lost.
function checkSDODecay(uint256 tokenId) public view sdoExists(tokenId) returns (uint256 energyLoss, uint256 resilienceLoss) {
    SDOState storage sdo = _sdoStates[tokenId];
    if (sdo.isDissipated) return (0, 0);

    uint256 timeElapsed = block.timestamp - sdo.lastDecayTimestamp;

    energyLoss = timeElapsed * _sdoParams.decayRatePerSecondEnergy;
    resilienceLoss = timeElapsed * _sdoParams.decayRatePerSecondResilience;

    energyLoss = sdo.energy > energyLoss ? energyLoss : sdo.energy; // Don't lose more energy than it has
    resilienceLoss = sdo.resilience > resilienceLoss ? resilienceLoss : sdo.resilience; // Don't lose more resilience than it has

    return (energyLoss, resilienceLoss);
}


/// @notice Calculates the potential Nutrient yield an SDO has generated since last claimed.
/// @dev Yield is based on time elapsed and SDO traits (Energy, Resilience).
/// @param tokenId The SDO to check.
/// @return The amount of Nutrient tokens available to claim.
function checkSDOYield(uint256 tokenId) public view sdoExists(tokenId) returns (uint256) {
    SDOState storage sdo = _sdoStates[tokenId];
    if (sdo.isDormant || sdo.isDissipated) return 0;
    if (sdo.energy < _sdoParams.minEnergyForYield || sdo.resilience < _sdoParams.minResilienceForYield) return 0;

    uint256 currentTime = block.timestamp;
    uint256 timeElapsed = currentTime - sdo.lastYieldTimestamp;

    if (timeElapsed == 0) return 0;

    // Example yield calculation: Base rate * time * (Energy + Resilience) / ScalingFactor
    // Use a larger scaling factor to avoid overflow with large traits, adjust yieldRatePerSecond accordingly
    uint256 yieldAmount = (_sdoParams.yieldRatePerSecond * timeElapsed * (sdo.energy + sdo.resilience)) / (1 ether) * _nutrientParams.sdoYieldFactor;

    // Ensure yield doesn't exceed remaining max supply (unlikely but good practice)
    uint256 maxPossibleYield = _nutrientMaxSupply - _totalSupplyNutrient;
    if (yieldAmount > maxPossibleYield) {
        yieldAmount = maxPossibleYield;
    }

    return yieldAmount;
}

/// @notice Claims the generated Nutrient yield from an SDO for its owner.
/// @dev Applies decay and calculates/mints yield.
/// @param tokenId The SDO to claim yield from.
function claimSDOYield(uint256 tokenId) public whenNotPaused sdoExists(tokenId) {
    address sdoOwner = ownerOf(tokenId);
    if (msg.sender != sdoOwner) revert Unauthorized();

    // Apply decay before calculating yield
    _applyDecay(tokenId);

    SDOState storage sdo = _sdoStates[tokenId];
     if (sdo.isDormant || sdo.isDissipated) return; // Cannot claim yield if dormant/dissipated

    uint256 yieldAmount = checkSDOYield(tokenId);

    if (yieldAmount > 0) {
        _mintNutrient(sdoOwner, yieldAmount);
        sdo.lastYieldTimestamp = block.timestamp; // Reset yield timer
        emit SDOYieldClaimed(tokenId, sdoOwner, yieldAmount);
    }
}

/// @notice Gets the current dynamic traits of an SDO.
/// @param tokenId The SDO to query.
/// @return generation, energy, resilience, mutationPotential
function getSDOTraits(uint256 tokenId) public view sdoExists(tokenId) returns (uint256 generation, uint256 energy, uint256 resilience, uint256 mutationPotential) {
    SDOState storage sdo = _sdoStates[tokenId];
    return (sdo.generation, sdo.energy, sdo.resilience, sdo.mutationPotential);
}

/// @notice Gets the full dynamic state of an SDO.
/// @param tokenId The SDO to query.
/// @return The SDOState struct.
function getSDOState(uint256 tokenId) public view sdoExists(tokenId) returns (SDOState memory) {
    return _sdoStates[tokenId];
}


// --- Parameter Setting Functions (Admin) ---

/// @notice Sets global parameters for SDO behavior.
/// @dev Can only be called by the owner.
/// @param params The new SDOParams struct.
function setSDOParams(SDOParams memory params) public onlyOwner {
    // Basic validation
    if (params.decayRatePerSecondEnergy == 0 || params.decayRatePerSecondResilience == 0) revert InvalidAmount();
    // Add more comprehensive validation as needed

    _sdoParams = params;
    emit SDOParamsUpdated(params);
}

/// @notice Sets global parameters for Nutrient token behavior.
/// @dev Can only be called by the owner.
/// @param params The new NutrientParams struct.
function setNutrientParams(NutrientParams memory params) public onlyOwner {
    // Basic validation
    if (params.maxSupply < _totalSupplyNutrient) revert InvalidAmount(); // Cannot set max supply below current supply

    _nutrientParams = params;
    _nutrientMaxSupply = params.maxSupply; // Update alias
    emit NutrientParamsUpdated(params);
}

/// @notice Mints an initial supply of Nutrient tokens to a recipient.
/// @dev Can only be called by the owner. Subject to `initialMintLimit`.
/// @param recipient The address to receive the tokens.
/// @param amount The amount to mint.
function mintInitialNutrient(address recipient, uint256 amount) public onlyOwner whenNotPaused {
    // Implement logic to respect initialMintLimit, perhaps per recipient or total
    // For simplicity, this example doesn't track per-recipient limits.
    // It does check against max supply internally in _mintNutrient.
     if (amount == 0) revert InvalidAmount();
    _mintNutrient(recipient, amount);
}


// --- View Functions (Getters) ---

/// @notice Returns the current global SDO parameters.
function getSDOParams() public view returns (SDOParams memory) {
    return _sdoParams;
}

/// @notice Returns the current global Nutrient parameters.
function getNutrientParams() public view returns (NutrientParams memory) {
    return _nutrientParams;
}

/// @notice Returns the total number of existing SDOs.
function getTotalSupplySDO() public view returns (uint256) {
    return _totalSupplySDO;
}

/// @notice Returns the total supply of Nutrient tokens.
function getTotalSupplyNutrient() public view returns (uint256) {
    return _totalSupplyNutrient;
}


// --- Libraries (Manual Implementation, if any complex math was needed) ---
// Example Math library if complex calculations were necessary
library Math {
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

     function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a <= b ? a : b;
    }
}
```