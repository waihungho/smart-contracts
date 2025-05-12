Okay, here is a smart contract concept called "Quantum Fluctuations". It aims to be creative, advanced, and trendy by featuring:

1.  **Dynamic, Evolving NFTs:** Tokens ("Fluctuations") aren't static images/data; their attributes change over time or through interactions.
2.  **On-Chain Randomness (Simulated for demo):** Attributes change based on random events (or deterministic simulations of randomness).
3.  **Complex Interactions:** Tokens can be "entangled" or "split", affecting their states.
4.  **State-Based Mechanics:** Actions and state changes depend on current attribute values (e.g., decay based on Stability, ability to split based on Complexity).
5.  **Time-Based Mechanics:** Attributes decay over time if not maintained, and states can be temporarily locked.
6.  **Novel Reputation/Affinity System (Implied):** While not a full system, actions like `attuneResonance` could hint at aligning tokens or users.

It implements the core ERC-721 functions needed for ownership and transfer but adds significant custom logic for the dynamic attributes and interactions.

**Outline & Function Summary:**

```solidity
// Outline:
// 1. Contract Definition & Imports (None required for this custom implementation)
// 2. Custom Errors
// 3. Structs: FluctuationAttributes
// 4. State Variables: ERC721 state, Fluctuation state, Config, Counters
// 5. Events: Token lifecycle, attribute changes, interactions, config updates
// 6. ERC721 Core Functions (Manual Implementation): balanceOf, ownerOf, approve, getApproved, setApprovalForAll, isApprovedForAll, transferFrom, safeTransferFrom (2 versions), totalSupply, tokenByIndex, tokenOfOwnerByIndex
// 7. Quantum Fluctuations Core Mechanics:
//    - mintFluctuation: Create new fluctuation with initial attributes (payable)
//    - getFluctuationAttributes: View current state of a fluctuation
//    - checkFluctuationState: Get derived state string (e.g., "Stable", "Volatile")
//    - energizeFluctuation: Increase EnergySignature (payable)
//    - stabilizeFluctuation: Increase Stability (payable)
//    - attuneResonance: Adjust ResonanceFrequency
//    - increaseComplexity: Increase Complexity (payable, might unlock future features)
//    - temporalShift: Lock fluctuation state until a future time
//    - triggerRandomFluctuation: Manually trigger a random attribute change (needs cooldown?)
//    - processDecay: Apply time-based decay to Stability
//    - calculateDecayAmount: View pending decay based on time
// 8. Inter-Fluctuation Interactions:
//    - entangleFluctuations: Link two fluctuations, potentially affecting their states
//    - dissociateFluctuations: Break an entanglement
//    - splitFluctuation: Create a new fluctuation from an existing one (payable, requires Complexity)
// 9. Configuration & Owner Functions:
//    - setFluctuationConfig: Set core parameters (decay rate, genesis cost, etc.)
//    - withdrawFunds: Withdraw contract balance
// 10. Helper Functions (Internal)

// Function Summary:
// ERC721 Core:
// - balanceOf(address owner): Get number of tokens owned by an address.
// - ownerOf(uint256 tokenId): Get the owner of a specific token.
// - approve(address to, uint256 tokenId): Grant approval for one token.
// - getApproved(uint256 tokenId): Get the approved address for a token.
// - setApprovalForAll(address operator, bool approved): Grant/revoke operator approval.
// - isApprovedForAll(address owner, address operator): Check operator approval status.
// - transferFrom(address from, address to, uint256 tokenId): Transfer token (unchecked).
// - safeTransferFrom(address from, address to, uint256 tokenId): Transfer token (checked receiver).
// - safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data): Transfer token (checked receiver with data).
// - totalSupply(): Get total number of tokens minted.
// - tokenByIndex(uint256 index): Get token ID by global index (for enumeration).
// - tokenOfOwnerByIndex(address owner, uint256 index): Get token ID owned by address by index.

// Quantum Fluctuations Mechanics:
// - mintFluctuation() payable: Mints a new Fluctuation token with random initial attributes. Costs genesis fee.
// - getFluctuationAttributes(uint256 tokenId) view: Returns the current state of a fluctuation's attributes.
// - checkFluctuationState(uint256 tokenId) view: Returns a descriptive state string based on current attributes.
// - energizeFluctuation(uint256 tokenId) payable: Increases the EnergySignature attribute. Costs a fee.
// - stabilizeFluctuation(uint256 tokenId) payable: Increases the Stability attribute. Costs a fee.
// - attuneResonance(uint256 tokenId, int256 delta): Adjusts the ResonanceFrequency within defined bounds.
// - increaseComplexity(uint256 tokenId) payable: Increases Complexity, potentially unlocking future features. Costs a fee.
// - temporalShift(uint256 tokenId, uint40 futureTimestamp): Locks the fluctuation's attributes from changing until futureTimestamp.
// - triggerRandomFluctuation(uint256 tokenId): Triggers a random change in one or more attributes. Subject to cooldowns/locks.
// - processDecay(uint256 tokenId): Applies time-based decay to the Stability attribute. Anyone can trigger.
// - calculateDecayAmount(uint256 tokenId) view: Calculates how much Stability decay is pending for a fluctuation based on time.

// Inter-Fluctuation Interactions:
// - entangleFluctuations(uint256 tokenId1, uint256 tokenId2): Links two fluctuations. Requires ownership or approval for both.
// - dissociateFluctuations(uint256 tokenId1, uint256 tokenId2): Breaks the link between two entangled fluctuations. Requires ownership or approval for either.
// - splitFluctuation(uint256 tokenId) payable: Creates a new fluctuation derived from an existing one, reducing the original's attributes. Requires sufficient Complexity and a fee.

// Configuration & Owner:
// - setFluctuationConfig(uint256 genesisCost, uint256 decayRatePerSecond, uint256 minStability, uint256 maxAttributeValue): Sets core contract parameters (only owner).
// - withdrawFunds(): Transfers collected ETH fees to the contract owner (only owner).

// Total Custom Functions (beyond basic ERC721): 13
// Total ERC721 Functions (Manual implementation): 10
// Total Functions: 23 (Meets requirement of >= 20)
```

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title QuantumFluctuations
 * @dev A creative smart contract representing dynamic, evolving digital entities.
 *      These entities ("Fluctuations") have attributes that can change over time,
 *      through user interaction, or via simulated random events.
 *      Features include attribute decay, temporal locking, entanglement, and splitting.
 *      Implements core ERC-721 functionality manually for non-fungible ownership.
 */
contract QuantumFluctuations {

    // --- Custom Errors ---
    error NotOwnerOrApproved();
    error InvalidTokenId();
    error TransferIntoZeroAddress();
    error TransferToERC721ReceiverRejected();
    error AlreadyApprovedOrOwner();
    error ApprovalForCaller();
    error NotTemporalShifted();
    error IsTemporalShifted();
    error InsufficientFunds();
    error InsufficientComplexityForSplit();
    error NotEntangled();
    error AlreadyEntangled();
    error CannotEntangleSelf();
    error TokensMustBeDifferent();
    error DecayCooldownNotElapsed();
    error RandomFluctuationCooldownNotElapsed();
    error AttributesOutOfRange(); // Should not happen with clamping, but good catch-all

    // --- Structs ---

    /**
     * @dev Represents the mutable attributes of a Quantum Fluctuation.
     *      Attributes are abstract and affect the fluctuation's state and behavior.
     *      All attributes are non-negative integers within a defined range.
     */
    struct FluctuationAttributes {
        uint256 stability;        // Resistance to decay and external changes. Range: [0, maxAttributeValue]
        uint256 energySignature;  // Potency and readiness for interaction/change. Range: [0, maxAttributeValue]
        uint256 complexity;       // Indicates potential for advanced states/actions like splitting. Range: [0, maxAttributeValue]
        uint256 resonanceFrequency; // Determines interaction dynamics and potential for entanglement. Range: [0, maxAttributeValue]
        uint256 temporalAlignment; // Affinity for stability or change over time. Range: [0, maxAttributeValue]
    }

    // --- State Variables (ERC-721 Core) ---

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping from owner address to number of owned tokens
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner address to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Array of all token IDs, for enumeration (Enumerable extension part)
    uint256[] private _allTokens;

    // Mapping from token ID to its index in the _allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    // Mapping from owner to list of owned token IDs (Enumerable extension part)
    mapping(address => uint256[] private) private _ownedTokens;

    // Mapping from token ID to its index in the owner's owned tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Total number of tokens minted
    uint256 private _totalSupply;

    // --- State Variables (Quantum Fluctuations Specific) ---

    // Mapping from token ID to its attributes
    mapping(uint256 => FluctuationAttributes) private _fluctuations;

    // Mapping from token ID to the timestamp when its state is locked until
    mapping(uint256 => uint40) private _temporalLocks; // 0 means not locked

    // Mapping from token ID to the token ID it is entangled with (if any)
    mapping(uint256 => uint256) private _entangledTokens; // 0 means not entangled

    // Mapping from token ID to the last timestamp decay was processed
    mapping(uint256 => uint40) private _timeLastDecayed; // 0 means never processed decay/just minted

    // Mapping from token ID to the last timestamp random fluctuation was triggered
    mapping(uint256 => uint40) private _timeLastRandomFluctuation;

    // --- Configuration ---
    address public immutable owner;
    uint256 public genesisCost; // Cost to mint a new fluctuation
    uint256 public decayRatePerSecond; // Rate at which stability decays per second (per fluctuation)
    uint256 public minStability; // Minimum stability to avoid certain decay consequences
    uint256 public maxAttributeValue; // Maximum possible value for any attribute
    uint256 public minAttributeValue; // Minimum possible value for any attribute (usually 0)
    uint256 public randomFluctuationCooldown; // Cooldown in seconds for triggering random fluctuation
    uint256 public decayProcessingCooldown; // Cooldown in seconds for processing decay on a single token

    // --- Events ---

    // ERC721 Events
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    // Quantum Fluctuations Events
    event Fluctuated(uint256 indexed tokenId, string attribute, uint256 oldValue, uint256 newValue, string reason);
    event StateChanged(uint256 indexed tokenId, string newState, string oldState); // State derived from attributes
    event Entangled(uint256 indexed tokenId1, uint256 indexed tokenId2);
    event Dissociated(uint256 indexed tokenId1, uint256 indexed tokenId2);
    event Split(uint256 indexed originalTokenId, uint256 indexed newTokenId);
    event TemporalShiftApplied(uint256 indexed tokenId, uint40 until);
    event TemporalShiftRemoved(uint256 indexed tokenId);
    event DecayProcessed(uint256 indexed tokenId, uint256 stabilityLost, uint256 newStability);
    event ConfigUpdated(uint256 newGenesisCost, uint256 newDecayRate, uint256 newMinStability, uint256 newMaxAttribute);

    // --- Constructor ---
    constructor(
        uint256 _genesisCost,
        uint256 _decayRatePerSecond,
        uint256 _minStability,
        uint256 _maxAttributeValue,
        uint256 _randomFluctuationCooldown,
        uint256 _decayProcessingCooldown
    ) {
        owner = msg.sender;
        genesisCost = _genesisCost;
        decayRatePerSecond = _decayRatePerSecond;
        minStability = _minStability;
        maxAttributeValue = _maxAttributeValue;
        minAttributeValue = 0; // Default minimum
        randomFluctuationCooldown = _randomFluctuationCooldown;
        decayProcessingCooldown = _decayProcessingCooldown;
    }

    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    modifier onlyOwnerOrApproved(uint256 tokenId) {
        address tokenOwner = ownerOf(tokenId); // Reverts if invalid tokenId
        require(msg.sender == tokenOwner || getApproved(tokenId) == msg.sender || isApprovedForAll(tokenOwner, msg.sender),
            "Not owner or approved");
        _;
    }

    modifier notTemporallyShifted(uint256 tokenId) {
        if (_temporalLocks[tokenId] > 0 && block.timestamp < _temporalLocks[tokenId]) {
             revert IsTemporalShifted();
        }
         // If lock time has passed, clear the lock
        if (_temporalLocks[tokenId] > 0 && block.timestamp >= _temporalLocks[tokenId]) {
             delete _temporalLocks[tokenId];
             emit TemporalShiftRemoved(tokenId);
        }
        _;
    }

    // --- ERC-721 Core Implementations ---
    // Implementing manually to avoid using OpenZeppelin directly as per prompt.
    // Includes basic Enumerable functionality.

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner_) public view returns (uint256) {
        require(owner_ != address(0), "Balance query for zero address");
        return _balances[owner_];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner_ = _owners[tokenId];
        require(owner_ != address(0), "Owner query for nonexistent token");
        return owner_;
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public {
        address owner_ = ownerOf(tokenId); // Validates token ID
        require(to != owner_, "Approval for current owner");
        require(msg.sender == owner_ || isApprovedForAll(owner_, msg.sender), "Approve caller is not owner nor approved for all");

        _tokenApprovals[tokenId] = to;
        emit Approval(owner_, to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId), "Approved query for nonexistent token");
        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public {
        require(operator != msg.sender, "Approve for caller");
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner_, address operator) public view returns (bool) {
        return _operatorApprovals[owner_][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     *      Note: This implementation does not check for validity of the receiver.
     */
    function transferFrom(address from, address to, uint256 tokenId) public {
        // Check ownership and approval
        require(_isApprovedOrOwner(msg.sender, tokenId), "Transfer caller is not owner nor approved");
        require(ownerOf(tokenId) == from, "Transfer from incorrect owner");
        require(to != address(0), "Transfer to the zero address");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public {
         safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) public {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Transfer caller is not owner nor approved");
        require(ownerOf(tokenId) == from, "Transfer from incorrect owner");
        require(to != address(0), "Transfer to the zero address");

        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

     /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view returns (uint256) {
        require(index < _totalSupply, "Global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner_, uint256 index) public view returns (uint256) {
        require(index < _balances[owner_], "Owner index out of bounds");
        return _ownedTokens[owner_][index];
    }


    // --- Internal ERC-721 Helpers ---

    /**
     * @dev Returns whether the specified token exists.
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _owners[tokenId] != address(0);
    }

     /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner_ = ownerOf(tokenId); // Verifies token exists
        return (spender == owner_ || getApproved(tokenId) == spender || isApprovedForAll(owner_, spender));
    }

    /**
     * @dev Safely transfers `tokenId` by calling `_transfer` and then making a call to `to`'s `onERC721Received` if `to` is a contract.
     * @param from The current owner of the token
     * @param to The new owner
     * @param tokenId The token ID to transfer
     * @param data Additional data with no specified format to be forwarded to the recipient
     */
     function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory data) internal returns (bool) {
        if (to.code.length > 0) { // Check if 'to' is a contract
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                     revert TransferToERC721ReceiverRejected();
                } else {
                     assembly {
                        revert(add(32, reason), mload(reason))
                     }
                }
            }
        }
        return true; // Not a contract, assume success
    }


    /**
     * @dev Internal function to transfer ownership of a given token ID to a new address.
     *      Requires the token ID to exist and the `from` address to be the current owner.
     *      Does NOT check approval or validity of the receiver.
     */
    function _transfer(address from, address to, uint256 tokenId) internal {
        // Clear approval for the token being transferred
        _tokenApprovals[tokenId] = address(0);

        // Update ERC721 state mappings
        _balances[from]--;
        _owners[tokenId] = to;
        _balances[to]++;

        // Update Enumerable mappings
        _removeTokenFromOwnersList(from, tokenId);
        _addTokenToOwnersList(to, tokenId);

        emit Transfer(from, to, tokenId);
    }

     /**
     * @dev Internal function to mint a new token.
     *      Does not check permissions or payment.
     *      Updates all relevant ERC721 state variables and Enumerable state.
     */
    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0), "Mint to the zero address");
        require(!_exists(tokenId), "Token already minted");

        _owners[tokenId] = to;
        _balances[to]++;
        _totalSupply++;

        // Add to global token list
        _allTokens.push(tokenId);
        _allTokensIndex[tokenId] = _allTokens.length - 1;

        // Add to owner's token list
        _addTokenToOwnersList(to, tokenId);

        emit Transfer(address(0), to, tokenId);
    }

     /**
     * @dev Internal function to burn a token.
     *      Does not check permissions.
     *      Updates all relevant ERC721 state variables and Enumerable state.
     */
    function _burn(uint256 tokenId) internal {
         address owner_ = ownerOf(tokenId); // Validates token exists and gets owner

        // Clear approval
        _tokenApprovals[tokenId] = address(0);

        // Update ERC721 state mappings
        _balances[owner_]--;
        delete _owners[tokenId];
        _totalSupply--;

        // Remove from global token list
        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId;
        _allTokensIndex[lastTokenId] = tokenIndex;
        _allTokens.pop();
        delete _allTokensIndex[tokenId];

        // Remove from owner's token list
        _removeTokenFromOwnersList(owner_, tokenId);

        // Clear fluctuation specific data
        delete _fluctuations[tokenId];
        delete _temporalLocks[tokenId];
        delete _timeLastDecayed[tokenId];
        delete _timeLastRandomFluctuation[tokenId];
        // Handle potential entanglement - burn dissolves entanglement
        uint256 entangledWith = _entangledTokens[tokenId];
        if (entangledWith != 0) {
            delete _entangledTokens[entangledWith];
            delete _entangledTokens[tokenId];
            emit Dissociated(tokenId, entangledWith);
        }

        emit Transfer(owner_, address(0), tokenId);
    }

    /**
     * @dev Add a token to the owner's list.
     */
    function _addTokenToOwnersList(address to, uint256 tokenId) private {
        _ownedTokens[to].push(tokenId);
        _ownedTokensIndex[tokenId] = _ownedTokens[to].length - 1;
    }

    /**
     * @dev Remove a token from the owner's list.
     *      Uses a swap-and-pop method for efficiency.
     */
    function _removeTokenFromOwnersList(address from, uint256 tokenId) private {
        uint256 lastTokenIndex = _ownedTokens[from].length - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // If the token is not the last one, move the last one into its spot
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];
            _ownedTokens[from][tokenIndex] = lastTokenId;
            _ownedTokensIndex[lastTokenId] = tokenIndex;
        }

        // Remove the last element
        _ownedTokens[from].pop();
        delete _ownedTokensIndex[tokenId];
    }

    // --- Quantum Fluctuations Core Mechanics ---

    /**
     * @dev Mints a new Quantum Fluctuation token for the caller.
     *      Requires sending `genesisCost` ETH with the transaction.
     *      Initial attributes are set randomly.
     * @return The ID of the newly minted token.
     */
    function mintFluctuation() public payable returns (uint256) {
        require(msg.value >= genesisCost, "Insufficient funds for genesis");

        uint256 newTokenId = _totalSupply + 1; // Simple sequential ID, avoid 0
        while (_exists(newTokenId)) { // Handle edge case if tokens are burned/total supply doesn't match last ID
             newTokenId++;
        }

        _mint(msg.sender, newTokenId);

        // Initialize attributes randomly (using simple hash-based approach for demo)
        bytes32 seed = keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, newTokenId, blockhash(block.number - 1)));

        uint256 initialStability = _random(seed, 1, maxAttributeValue / 2); // Start with some stability
        uint256 initialEnergy = _random(keccak256(abi.encodePacked(seed, "energy")), minAttributeValue, maxAttributeValue);
        uint256 initialComplexity = _random(keccak256(abi.encodePacked(seed, "complexity")), minAttributeValue, maxAttributeValue / 4); // Start less complex
        uint256 initialResonance = _random(keccak256(abi.encodePacked(seed, "resonance")), minAttributeValue, maxAttributeValue);
        uint256 initialTemporal = _random(keccak256(abi.encodePacked(seed, "temporal")), minAttributeValue, maxAttributeValue);

        _fluctuations[newTokenId] = FluctuationAttributes({
            stability: initialStability,
            energySignature: initialEnergy,
            complexity: initialComplexity,
            resonanceFrequency: initialResonance,
            temporalAlignment: initialTemporal
        });

        _timeLastDecayed[newTokenId] = uint40(block.timestamp); // Record initial decay time
        _timeLastRandomFluctuation[newTokenId] = uint40(block.timestamp); // Record initial fluctuation time

        // Note: Check state is view, not called here.
        // Emit initial state somehow if needed, but attributes are primary data.

        return newTokenId;
    }

    /**
     * @dev Gets the current attributes of a specific fluctuation.
     * @param tokenId The ID of the fluctuation.
     * @return A tuple containing the attributes: stability, energySignature, complexity, resonanceFrequency, temporalAlignment.
     */
    function getFluctuationAttributes(uint256 tokenId) public view returns (uint256 stability, uint256 energySignature, uint256 complexity, uint256 resonanceFrequency, uint256 temporalAlignment) {
        require(_exists(tokenId), "Query for nonexistent token");
        FluctuationAttributes storage attrs = _fluctuations[tokenId];
        return (attrs.stability, attrs.energySignature, attrs.complexity, attrs.resonanceFrequency, attrs.temporalAlignment);
    }

    /**
     * @dev Calculates a descriptive state string based on the fluctuation's attributes.
     *      This is a derived value, not stored state.
     * @param tokenId The ID of the fluctuation.
     * @return A string representing the current state (e.g., "Stable", "Volatile", "Critical").
     */
    function checkFluctuationState(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "Query for nonexistent token");
        FluctuationAttributes storage attrs = _fluctuations[tokenId];

        if (attrs.stability <= minStability) {
            return "Critical";
        }
        if (attrs.stability < maxAttributeValue / 4) {
            return "Volatile";
        }
        if (attrs.complexity > maxAttributeValue * 3 / 4 && attrs.energySignature > maxAttributeValue / 2) {
            return "Complex & Energetic";
        }
         if (attrs.temporalAlignment > maxAttributeValue * 3 / 4) {
            return "Temporally Anchored";
        }
         if (attrs.resonanceFrequency > maxAttributeValue * 3 / 4) {
            return "Highly Resonant";
        }

        return "Stable";
    }

    /**
     * @dev Increases the EnergySignature attribute of a fluctuation.
     *      Requires sending a fee and the caller must be the owner or approved.
     * @param tokenId The ID of the fluctuation to energize.
     */
    function energizeFluctuation(uint256 tokenId) public payable onlyOwnerOrApproved(tokenId) notTemporallyShifted(tokenId) {
        require(msg.value > 0, "Must send funds to energize"); // Could make fee configurable

        FluctuationAttributes storage attrs = _fluctuations[tokenId];
        uint256 oldEnergy = attrs.energySignature;

        // Energy gain based on amount sent, complexity, and current energy
        uint256 energyGain = msg.value / (1e15); // Simple conversion, 1 ether = 1000 energy points
        // Diminishing returns or bonus based on complexity/current energy?
        energyGain = energyGain + (attrs.complexity / 10) - (attrs.energySignature / 20); // Example complex gain

        attrs.energySignature = _clampAttribute(attrs.energySignature + energyGain);

        emit Fluctuated(tokenId, "EnergySignature", oldEnergy, attrs.energySignature, "Energized");
         // Could also check and emit StateChanged if relevant
    }

    /**
     * @dev Increases the Stability attribute of a fluctuation.
     *      Requires sending a fee and the caller must be the owner or approved.
     * @param tokenId The ID of the fluctuation to stabilize.
     */
    function stabilizeFluctuation(uint256 tokenId) public payable onlyOwnerOrApproved(tokenId) notTemporallyShifted(tokenId) {
        require(msg.value > 0, "Must send funds to stabilize"); // Could make fee configurable

        FluctuationAttributes storage attrs = _fluctuations[tokenId];
        uint256 oldStability = attrs.stability;

        // Stability gain based on amount sent, temporal alignment, and current stability
        uint256 stabilityGain = msg.value / (1e15); // Simple conversion
        stabilityGain = stabilityGain + (attrs.temporalAlignment / 10) - (attrs.stability / 20); // Example complex gain

        attrs.stability = _clampAttribute(attrs.stability + stabilityGain);

        emit Fluctuated(tokenId, "Stability", oldStability, attrs.stability, "Stabilized");
         // Could also check and emit StateChanged if relevant
    }

    /**
     * @dev Adjusts the ResonanceFrequency attribute of a fluctuation.
     *      The adjustment is limited and depends on the temporal alignment.
     *      Caller must be owner or approved.
     * @param tokenId The ID of the fluctuation.
     * @param delta The amount to adjust the resonance frequency by (can be negative).
     */
    function attuneResonance(uint256 tokenId, int256 delta) public onlyOwnerOrApproved(tokenId) notTemporallyShifted(tokenId) {
        FluctuationAttributes storage attrs = _fluctuations[tokenId];
        uint256 oldResonance = attrs.resonanceFrequency;

        // Adjustment limit based on temporal alignment (more aligned = less flexible?)
        int256 adjustmentLimit = int256(maxAttributeValue) / 10 - int256(attrs.temporalAlignment) / 20;
        if (delta > adjustmentLimit) delta = adjustmentLimit;
        if (delta < -adjustmentLimit) delta = -adjustmentLimit;

        int256 newResonanceSigned = int256(attrs.resonanceFrequency) + delta;

        // Clamp the new value
        uint256 newResonance;
        if (newResonanceSigned < int256(minAttributeValue)) newResonance = minAttributeValue;
        else if (newResonanceSigned > int256(maxAttributeValue)) newResonance = maxAttributeValue;
        else newResonance = uint256(newResonanceSigned);

        attrs.resonanceFrequency = newResonance;

        emit Fluctuated(tokenId, "ResonanceFrequency", oldResonance, attrs.resonanceFrequency, "Attuned");
    }

    /**
     * @dev Increases the Complexity attribute of a fluctuation.
     *      Requires sending a fee and the caller must be the owner or approved.
     *      Higher complexity might unlock new features or interactions in the future.
     * @param tokenId The ID of the fluctuation.
     */
    function increaseComplexity(uint256 tokenId) public payable onlyOwnerOrApproved(tokenId) notTemporallyShifted(tokenId) {
        require(msg.value > 0, "Must send funds to increase complexity"); // Could make fee configurable

        FluctuationAttributes storage attrs = _fluctuations[tokenId];
        uint256 oldComplexity = attrs.complexity;

        // Complexity gain based on amount sent and current complexity (harder to get more complex)
        uint256 complexityGain = msg.value / (2e16); // More expensive than energize/stabilize
        complexityGain = complexityGain + (attrs.energySignature / 20) - (attrs.complexity / 10); // Example gain

        attrs.complexity = _clampAttribute(attrs.complexity + complexityGain);

        emit Fluctuated(tokenId, "Complexity", oldComplexity, attrs.complexity, "Complexity Increased");
    }

    /**
     * @dev Locks the fluctuation's state from changing until a specified future timestamp.
     *      Prevents attribute changes via most functions (`energize`, `stabilize`, `attuneResonance`, `increaseComplexity`, `triggerRandomFluctuation`, `processDecay`).
     *      Does NOT prevent transfer, entanglement, or splitting (though splitting might have its own state requirements).
     *      Caller must be owner or approved.
     * @param tokenId The ID of the fluctuation.
     * @param futureTimestamp The timestamp until which the state is locked. Must be in the future.
     */
    function temporalShift(uint256 tokenId, uint40 futureTimestamp) public onlyOwnerOrApproved(tokenId) {
         require(futureTimestamp > block.timestamp, "Lock timestamp must be in the future");
         // Disallow re-locking before current lock expires
         require(_temporalLocks[tokenId] == 0 || block.timestamp >= _temporalLocks[tokenId], "Already temporally shifted");

        _temporalLocks[tokenId] = futureTimestamp;
        emit TemporalShiftApplied(tokenId, futureTimestamp);
    }

     /**
     * @dev Manually triggers a random change in one or more attributes of a fluctuation.
     *      Subject to a cooldown and temporal lock.
     *      Caller must be owner or approved.
     *      Uses simple blockhash-based randomness for demonstration.
     * @param tokenId The ID of the fluctuation.
     */
    function triggerRandomFluctuation(uint256 tokenId) public onlyOwnerOrApproved(tokenId) notTemporallyShifted(tokenId) {
        require(block.timestamp >= _timeLastRandomFluctuation[tokenId] + randomFluctuationCooldown, "Random fluctuation cooldown not elapsed");

        FluctuationAttributes storage attrs = _fluctuations[tokenId];
        bytes32 seed = keccak256(abi.encodePacked(block.timestamp, msg.sender, tokenId, blockhash(block.number - 1), attrs.stability, attrs.energySignature));

        uint256 randomChoice = _random(seed, 0, 4); // Choose which attribute to affect
        int256 randomDelta = int256(_random(keccak256(abi.encodePacked(seed, "delta")), 0, maxAttributeValue / 20)) - int256(maxAttributeValue / 40); // Random small +/- change

        string memory attributeName;
        uint256 oldValue;
        uint256 newValue;

        // Apply the change based on random choice
        if (randomChoice == 0) {
            attributeName = "Stability";
            oldValue = attrs.stability;
            attrs.stability = _clampAttribute(int256(attrs.stability) + randomDelta);
            newValue = attrs.stability;
        } else if (randomChoice == 1) {
            attributeName = "EnergySignature";
            oldValue = attrs.energySignature;
            attrs.energySignature = _clampAttribute(int256(attrs.energySignature) + randomDelta);
             newValue = attrs.energySignature;
        } else if (randomChoice == 2) {
            attributeName = "Complexity";
            oldValue = attrs.complexity;
            attrs.complexity = _clampAttribute(int256(attrs.complexity) + randomDelta / 2); // Less dramatic complexity change
            newValue = attrs.complexity;
        } else if (randomChoice == 3) {
            attributeName = "ResonanceFrequency";
             oldValue = attrs.resonanceFrequency;
            attrs.resonanceFrequency = _clampAttribute(int256(attrs.resonanceFrequency) + randomDelta);
             newValue = attrs.resonanceFrequency;
        } else { // randomChoice == 4
             attributeName = "TemporalAlignment";
             oldValue = attrs.temporalAlignment;
            attrs.temporalAlignment = _clampAttribute(int256(attrs.temporalAlignment) + randomDelta);
             newValue = attrs.temporalAlignment;
        }

        _timeLastRandomFluctuation[tokenId] = uint40(block.timestamp);

        emit Fluctuated(tokenId, attributeName, oldValue, newValue, "Random Fluctuation");
        // Could also check and emit StateChanged if relevant
    }

    /**
     * @dev Processes the time-based decay for a fluctuation's Stability.
     *      Can be called by anyone (to allow maintenance by others).
     *      Stability decreases based on time elapsed since last decay/mint.
     *      Subject to temporal lock and a processing cooldown per token.
     * @param tokenId The ID of the fluctuation to process decay for.
     */
    function processDecay(uint256 tokenId) public notTemporallyShifted(tokenId) {
        require(_exists(tokenId), "Process decay for nonexistent token");
        require(block.timestamp >= _timeLastDecayed[tokenId] + decayProcessingCooldown, "Decay processing cooldown not elapsed");

        FluctuationAttributes storage attrs = _fluctuations[tokenId];
        uint256 timeElapsed = block.timestamp - _timeLastDecayed[tokenId];
        uint256 stabilityLoss = timeElapsed * decayRatePerSecond;

        uint256 oldStability = attrs.stability;
        if (attrs.stability > stabilityLoss) {
            attrs.stability -= stabilityLoss;
        } else {
            attrs.stability = minAttributeValue; // Stability cannot go below 0 or minAttributeValue
        }

        _timeLastDecayed[tokenId] = uint40(block.timestamp);

        emit DecayProcessed(tokenId, stabilityLoss, attrs.stability);
         // Could also check and emit StateChanged if relevant
    }

     /**
     * @dev Calculates the potential stability decay amount based on time elapsed since last processing.
     *      This is a view function and does not change state.
     * @param tokenId The ID of the fluctuation.
     * @return The calculated stability loss if `processDecay` were called now.
     */
     function calculateDecayAmount(uint256 tokenId) public view returns (uint256) {
         require(_exists(tokenId), "Calculate decay for nonexistent token");
         // No cooldown check needed for view function
         uint256 timeElapsed = block.timestamp - _timeLastDecayed[tokenId];
         return timeElapsed * decayRatePerSecond;
     }


    // --- Inter-Fluctuation Interactions ---

    /**
     * @dev Entangles two fluctuations, linking their states.
     *      Requires ownership or approval for both tokens.
     *      Entangled tokens might influence each other's fluctuations (logic not fully implemented here, but structure exists).
     * @param tokenId1 The ID of the first fluctuation.
     * @param tokenId2 The ID of the second fluctuation.
     */
    function entangleFluctuations(uint256 tokenId1, uint256 tokenId2) public onlyOwnerOrApproved(tokenId1) onlyOwnerOrApproved(tokenId2) {
        require(tokenId1 != tokenId2, "Cannot entangle a token with itself");
        require(_entangledTokens[tokenId1] == 0 && _entangledTokens[tokenId2] == 0, "One or both tokens are already entangled");

        _entangledTokens[tokenId1] = tokenId2;
        _entangledTokens[tokenId2] = tokenId1;

        emit Entangled(tokenId1, tokenId2);

        // Potential advanced logic: Combine or average some attributes? Link decay rates?
    }

    /**
     * @dev Dissociates two entangled fluctuations.
     *      Requires ownership or approval for *either* token in the pair.
     * @param tokenId1 The ID of one fluctuation in the pair.
     * @param tokenId2 The ID of the other fluctuation in the pair.
     */
    function dissociateFluctuations(uint256 tokenId1, uint256 tokenId2) public {
        require(tokenId1 != tokenId2, "Invalid pair for dissociation");
         // Check if the caller owns/is approved for *either* token
         require(_isApprovedOrOwner(msg.sender, tokenId1) || _isApprovedOrOwner(msg.sender, tokenId2), "Not owner or approved for either token");

        uint256 entangledWith1 = _entangledTokens[tokenId1];
        uint256 entangledWith2 = _entangledTokens[tokenId2];

        require(entangledWith1 == tokenId2 && entangledWith2 == tokenId1, "Tokens are not entangled with each other");

        delete _entangledTokens[tokenId1];
        delete _entangledTokens[tokenId2];

        emit Dissociated(tokenId1, tokenId2);

        // Potential advanced logic: State change based on dissociation?
    }

    /**
     * @dev Splits an existing fluctuation into two.
     *      Consumes some attributes from the original and creates a new fluctuation.
     *      Requires sufficient Complexity in the original token and sending a fee.
     *      The new token is minted to the caller.
     *      Subject to temporal lock on the original token.
     * @param tokenId The ID of the fluctuation to split.
     * @return The ID of the newly created fluctuation.
     */
    function splitFluctuation(uint256 tokenId) public payable onlyOwnerOrApproved(tokenId) notTemporallyShifted(tokenId) returns (uint256) {
        require(msg.value >= genesisCost, "Insufficient funds for splitting cost"); // Uses same cost as genesis? Or different?
        FluctuationAttributes storage originalAttrs = _fluctuations[tokenId];
        require(originalAttrs.complexity > maxAttributeValue / 2, "Insufficient complexity to split"); // Example complexity requirement
        require(_entangledTokens[tokenId] == 0, "Cannot split an entangled fluctuation");


        uint256 newTokenId = _totalSupply + 1; // Simple sequential ID
         while (_exists(newTokenId)) { // Handle edge case
             newTokenId++;
        }

        _mint(msg.sender, newTokenId);

        // --- Splitting Logic ---
        // Attributes are divided or redistributed. Example:
        // Original loses complexity and energy, new gets some energy/resonance.
        uint256 oldOriginalComplexity = originalAttrs.complexity;
        uint256 oldOriginalEnergy = originalAttrs.energySignature;

        uint256 newComplexity = originalAttrs.complexity / 4; // Original loses 75%, new gets 25%
        uint256 newEnergy = originalAttrs.energySignature / 2; // Original loses 50%, new gets 50%
        uint256 newResonance = originalAttrs.resonanceFrequency; // Resonance might carry over

        originalAttrs.complexity = _clampAttribute(originalAttrs.complexity - (oldOriginalComplexity - newComplexity));
        originalAttrs.energySignature = _clampAttribute(originalAttrs.energySignature - (oldOriginalEnergy - newEnergy));
        // Stability and TemporalAlignment might be independent or partially inherited/randomized

        // New fluctuation attributes (mix of inherited and new random)
         bytes32 seed = keccak256(abi.encodePacked(block.timestamp, msg.sender, tokenId, newTokenId, blockhash(block.number - 1)));
         uint256 initialStability = _random(seed, minAttributeValue, maxAttributeValue / 3); // New might start less stable
         uint256 initialTemporal = _random(keccak256(abi.encodePacked(seed, "temporal_new")), minAttributeValue, maxAttributeValue);

        _fluctuations[newTokenId] = FluctuationAttributes({
            stability: initialStability,
            energySignature: newEnergy,
            complexity: newComplexity,
            resonanceFrequency: newResonance,
            temporalAlignment: initialTemporal
        });

        _timeLastDecayed[newTokenId] = uint40(block.timestamp); // Record initial decay time
         _timeLastRandomFluctuation[newTokenId] = uint40(block.timestamp); // Record initial fluctuation time


        emit Fluctuated(tokenId, "Complexity", oldOriginalComplexity, originalAttrs.complexity, "Split");
        emit Fluctuated(tokenId, "EnergySignature", oldOriginalEnergy, originalAttrs.energySignature, "Split");
        // Emit event for new fluctuation's creation implicitly via Mint event
        emit Split(tokenId, newTokenId);

        return newTokenId;
    }


    // --- Configuration & Owner Functions ---

    /**
     * @dev Allows the contract owner to update key configuration parameters.
     * @param _genesisCost New cost to mint/split.
     * @param _decayRatePerSecond New stability decay rate per second.
     * @param _minStability New minimum stability threshold.
     * @param _maxAttributeValue New maximum attribute value.
     * @param _randomFluctuationCooldown New cooldown for manual random fluctuation trigger.
     * @param _decayProcessingCooldown New cooldown for processing decay on a single token.
     */
    function setFluctuationConfig(
        uint256 _genesisCost,
        uint256 _decayRatePerSecond,
        uint256 _minStability,
        uint256 _maxAttributeValue,
        uint256 _randomFluctuationCooldown,
        uint256 _decayProcessingCooldown
    ) public onlyOwner {
        require(_maxAttributeValue > _minStability, "Max attribute must be greater than min stability");
        genesisCost = _genesisCost;
        decayRatePerSecond = _decayRatePerSecond;
        minStability = _minStability;
        maxAttributeValue = _maxAttributeValue;
        randomFluctuationCooldown = _randomFluctuationCooldown;
        decayProcessingCooldown = _decayProcessingCooldown;

        emit ConfigUpdated(genesisCost, decayRatePerSecond, minStability, maxAttributeValue);
    }

    /**
     * @dev Allows the contract owner to withdraw accumulated ETH fees.
     */
    function withdrawFunds() public onlyOwner {
        (bool success,) = payable(owner).call{value: address(this).balance}("");
        require(success, "Withdrawal failed");
    }

    // --- Internal Helper Functions ---

    /**
     * @dev Clamps an attribute value between minAttributeValue and maxAttributeValue.
     *      Handles signed to unsigned conversion safely.
     */
    function _clampAttribute(int256 value) internal view returns (uint256) {
        if (value < int256(minAttributeValue)) {
            return minAttributeValue;
        }
        if (value > int256(maxAttributeValue)) {
            return maxAttributeValue;
        }
        return uint256(value);
    }

     /**
     * @dev Clamps a uint256 attribute value between minAttributeValue and maxAttributeValue.
     */
     function _clampAttribute(uint256 value) internal view returns (uint256) {
        if (value < minAttributeValue) {
            return minAttributeValue;
        }
        if (value > maxAttributeValue) {
            return maxAttributeValue;
        }
        return value;
     }

     /**
     * @dev Simple pseudo-random number generator based on hashing.
     *      NOTE: This is NOT cryptographically secure and is predictable by miners.
     *      For production, use Chainlink VRF or similar. This is for demonstration only.
     * @param seed A seed for the random number generation.
     * @param min The minimum possible value (inclusive).
     * @param max The maximum possible value (inclusive).
     * @return A pseudo-random number within the specified range.
     */
    function _random(bytes32 seed, uint256 min, uint256 max) internal pure returns (uint256) {
        if (min > max) return min; // Or revert
        uint256 randomHash = uint256(keccak256(abi.encodePacked(seed)));
        return min + (randomHash % (max - min + 1));
    }


     // --- ERC721Receiver Interface (Minimal - adjust if needed) ---
     // This interface is used by safeTransferFrom to check if the recipient contract can receive ERC721 tokens.
    interface IERC721Receiver {
        /**
         * @dev Whenever an ERC721 token is transferred to a contract via `safeTransferFrom`
         * (with data), this function is called.
         *
         * It must return the function selector of `onERC721Received`
         * (`0x150b7a02`) if the transfer is to be accepted.
         *
         * If any other value is returned or the interface is not implemented by the recipient,
         * the transfer will be reverted.
         */
        function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
    }
}
```