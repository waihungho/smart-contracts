Okay, here is a Solidity smart contract implementing a concept called "Quantum Entanglement NFTs" (QENFTs). This concept involves NFTs minted in pairs whose "state" (a numerical value in this case) is linked through a dynamic, random process simulated by Chainlink VRF.

The contract integrates custom state management, Chainlink VRF for verifiable randomness, owner-controlled parameters, and a simple staking mechanism that affects the state dynamics. It implements the necessary functions to adhere to the ERC-721 standard while adding complex custom logic.

**Disclaimer:** This is a complex and experimental concept. The state determination logic is a simplified analogy of entanglement collapse. Deploying such a contract requires thorough testing, security audits, and consideration of gas costs for VRF callbacks and state updates. Chainlink VRF requires funding a subscription.

---

## Quantum Entanglement NFT Contract (QENFT)

**Outline:**

1.  **Pragma and Imports:** Specify Solidity version, import necessary interfaces (ERC721, ERC165, VRFConsumerBaseV2).
2.  **Interfaces:** Define the ERC-721 and ERC-165 interfaces if not directly importing full implementations (using standard OpenZeppelin interfaces is common practice and not considered "duplication" of logic).
3.  **Libraries:** Use SafeMath for arithmetic safety (although 0.8+ handles overflow by default, explicit checks can be good for clarity or specific scenarios).
4.  **Contract Definition:** Inherit from ERC721 and VRFConsumerBaseV2. Implement Ownable pattern manually or import (manual for less dependency).
5.  **State Variables:**
    *   Basic ERC721 state (owner, balance, approvals, total supply).
    *   Entanglement State: Mapping token ID to pair ID, mapping pair ID to member token IDs, mapping pair ID to entanglement status (Entangled, Collapsed, Separated).
    *   Token State: Mapping token ID to its current numerical state value.
    *   VRF Integration: Subscription ID, Key Hash, Request IDs, mapping request ID to token ID.
    *   Minting Parameters: Cost per pair, maximum number of pairs.
    *   Staking: Mapping token ID to staking status, mapping token ID to stake start time.
    *   Cooldown: Mapping token ID to last measurement time, measurement cooldown duration.
    *   Base URI for metadata.
    *   Counters for token IDs and pair IDs.
    *   Admin address (Owner).
6.  **Enums:** Define states for pairs (Entangled, Collapsed, Separated).
7.  **Events:** MintedPair, StateMeasured, PairCollapsed, PairSeparated, TokenStaked, TokenUnstaked, ParametersUpdated, EtherWithdrawn.
8.  **Modifiers:** OnlyPairMember, OnlyEntangled, OnlyCollapsed, OnlySeparated, OnlyStaked, NotStaked, OnlyOwner.
9.  **Constructor:** Initialize name, symbol, VRF parameters, owner, base URI.
10. **ERC-721 Overrides:** Implement standard ERC-721 functions (`balanceOf`, `ownerOf`, `transferFrom`, `approve`, `setApprovalForAll`, `getApproved`, `isApprovedForAll`, `tokenURI`, `supportsInterface`). Add checks related to staking status in transfer functions.
11. **Core Entanglement Functions:**
    *   `mintEntangledPair`: Mints a new pair of QENFTs, links them, sets initial state, marks as Entangled. Handles payment and limits.
    *   `requestStateMeasurement`: Initiates VRF request for a token ID if it's Entangled, not Staked, and not on cooldown.
    *   `fulfillRandomWords`: VRF callback function. Receives random word, determines state for requesting token, calculates partner's state based on entanglement rule, updates states, updates cooldown.
    *   `collapsePair`: Changes pair status from Entangled to Collapsed. May prevent future measurements.
    *   `separatePair`: Changes pair status from Entangled to Separated. Breaks the state linkage.
12. **State & Pairing Read Functions:**
    *   `getPairId`: Get the pair ID for a token.
    *   `getPairMembers`: Get the token IDs for a pair.
    *   `getEntanglementStatus`: Get the status of a pair.
    *   `getTokenState`: Get the current numerical state of a token.
13. **Staking Functions:**
    *   `stakeToken`: Stakes an *Entangled* token. Prevents measurement and potentially transfer. Records stake time.
    *   `unstakeToken`: Unstakes a token. Allows measurement/transfer again.
    *   `isTokenStaked`: Check staking status.
    *   `getStakeStartTime`: Get when a token was staked.
14. **Admin/Governance Functions:**
    *   `setMaxPairs`: Set the maximum number of pairs that can be minted.
    *   `setMintCost`: Set the cost in Ether to mint a pair.
    *   `withdrawEther`: Owner can withdraw accumulated Ether.
    *   `setVRFParameters`: Update VRF configuration (key hash, sub ID, gas limit).
    *   `updateBaseURI`: Change the base URI for metadata.
    *   `setMeasurementCooldown`: Set the minimum time between state measurements for a token.
    *   `pauseContract` / `unpauseContract` (Optional but good practice).
15. **Helper Internal Functions:**
    *   `_beforeTokenTransfer` / `_afterTokenTransfer` hooks (if overriding ERC721).
    *   Internal state update logic.

**Function Summary (>= 20 Functions):**

1.  `constructor(string memory name_, string memory symbol_, uint64 subscriptionId, bytes32 keyHash, uint32 requestConfirmations, uint32 callbackGasLimit, string memory baseURI_)` - Initializes contract, ERC721 details, VRF params, base URI.
2.  `supportsInterface(bytes4 interfaceId)` - ERC-165 standard function.
3.  `name()` - Returns the contract name.
4.  `symbol()` - Returns the contract symbol.
5.  `balanceOf(address owner)` - Returns the number of tokens owned by an address.
6.  `ownerOf(uint256 tokenId)` - Returns the owner of a specific token.
7.  `transferFrom(address from, address to, uint256 tokenId)` - Transfers token ownership (basic ERC721). Includes checks for staking.
8.  `safeTransferFrom(address from, address to, uint256 tokenId)` - Safe transfer (ERC721). Includes checks for staking.
9.  `safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)` - Safe transfer with data (ERC721). Includes checks for staking.
10. `approve(address to, uint256 tokenId)` - Approves an address to transfer a token. Includes checks for staking.
11. `setApprovalForAll(address operator, bool approved)` - Sets approval for an operator for all owner's tokens.
12. `getApproved(uint256 tokenId)` - Returns the approved address for a token.
13. `isApprovedForAll(address owner, address operator)` - Checks if an operator is approved for all tokens of an owner.
14. `tokenURI(uint256 tokenId)` - Returns the metadata URI for a token. Uses the base URI and token ID, external service should provide dynamic data based on state.
15. `mintEntangledPair()` - Mints two new entangled tokens to the caller. Requires payment and checks limits.
16. `requestStateMeasurement(uint256 tokenId)` - Requests a VRF random number to measure/update the state of a token and its entangled partner. Checks entanglement status, staking, and cooldown.
17. `fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)` - VRF callback. Updates the state of the token associated with the request ID and its entangled partner based on the random word.
18. `collapsePair(uint256 pairId)` - Changes the status of a pair to Collapsed. Can only be called by an owner of one of the pair members.
19. `separatePair(uint256 pairId)` - Changes the status of a pair to Separated. Can only be called by an owner of one of the pair members. Breaks the state linkage permanently.
20. `getPairId(uint256 tokenId)` - Returns the pair ID associated with a token.
21. `getPairMembers(uint256 pairId)` - Returns the two token IDs belonging to a pair.
22. `getEntanglementStatus(uint256 pairId)` - Returns the current status (Entangled, Collapsed, Separated) of a pair.
23. `getTokenState(uint256 tokenId)` - Returns the current numerical state value of a token.
24. `stakeToken(uint256 tokenId)` - Stakes an Entangled token owned by the caller.
25. `unstakeToken(uint256 tokenId)` - Unstakes a token owned by the caller.
26. `isTokenStaked(uint256 tokenId)` - Checks if a token is currently staked.
27. `getStakeStartTime(uint256 tokenId)` - Returns the timestamp when a token was staked (0 if not staked).
28. `setMaxPairs(uint256 _maxPairs)` - Owner function to set the maximum number of pairs mintable.
29. `setMintCost(uint256 _mintCost)` - Owner function to set the cost to mint a pair.
30. `withdrawEther(address payable to)` - Owner function to withdraw contract balance.
31. `setVRFParameters(uint64 _subscriptionId, bytes32 _keyHash, uint32 _requestConfirmations, uint32 _callbackGasLimit)` - Owner function to update VRF parameters.
32. `updateBaseURI(string memory _baseURI)` - Owner function to update the base URI for metadata.
33. `setMeasurementCooldown(uint256 _cooldown)` - Owner function to set the minimum time between state measurements for a token.
34. `getLastMeasurementTime(uint256 tokenId)` - Returns the timestamp of the last state measurement for a token.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Assuming OpenZeppelin interfaces are available via npm install @openzeppelin/contracts
// Or you can manually copy the interface definitions if strictly avoiding npm dependency.
// We will use interfaces here as it's standard practice and not considered duplicating *implementation*.
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/access/Ownable.sol"; // Using OpenZeppelin Ownable for simplicity
import "@chainlink/contracts/src/v0.8/VRFV2Base.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

/// @title QuantumEntanglementNFT (QENFT)
/// @notice A dynamic NFT contract where tokens are minted in entangled pairs,
///         and their states are linked and updated via Chainlink VRF-triggered
///         "measurements". Includes state transitions (Collapsed, Separated)
///         and a staking mechanism affecting state dynamics.
/// @dev This contract uses Chainlink VRF v2 and requires a funded subscription.
///      The state update logic is a simplified analogy of quantum entanglement.
contract QuantumEntanglementNFT is Context, ERC165, IERC721, VRFV2Base, Ownable {

    // --- Structs, Enums, Constants ---

    /// @notice Represents the entanglement status of a pair.
    enum PairStatus {
        NonExistent, // Default status for uninitialized pairIds
        Entangled,
        Collapsed, // States are fixed, no more measurements
        Separated  // Link broken, no more state linkage
    }

    // --- Events ---

    /// @dev Emitted when a new entangled pair is minted.
    /// @param pairId The ID of the newly created pair.
    /// @param tokenId1 The ID of the first token in the pair.
    /// @param tokenId2 The ID of the second token in the pair.
    /// @param owner The address that received the pair.
    event MintedPair(uint256 indexed pairId, uint256 indexed tokenId1, uint256 indexed tokenId2, address indexed owner);

    /// @dev Emitted when the state of a token (and potentially its partner) is measured/updated.
    /// @param tokenId The ID of the token whose measurement triggered the update.
    /// @param oldState The state of the token before the measurement.
    /// @param newState The state of the token after the measurement.
    /// @param pairPartnerTokenId The ID of the entangled partner token (0 if separated).
    /// @param pairPartnerOldState The state of the partner before the update.
    /// @param pairPartnerNewState The state of the partner after the update.
    event StateMeasured(uint256 indexed tokenId, uint256 oldState, uint256 newState, uint256 indexed pairPartnerTokenId, uint256 pairPartnerOldState, uint256 pairPartnerNewState);

    /// @dev Emitted when an entangled pair is collapsed.
    /// @param pairId The ID of the pair.
    event PairCollapsed(uint256 indexed pairId);

    /// @dev Emitted when an entangled pair is separated.
    /// @param pairId The ID of the pair.
    event PairSeparated(uint256 indexed pairId);

    /// @dev Emitted when a token is staked.
    /// @param tokenId The ID of the staked token.
    /// @param owner The owner of the token.
    event TokenStaked(uint256 indexed tokenId, address indexed owner);

    /// @dev Emitted when a token is unstaked.
    /// @param tokenId The ID of the unstaked token.
    /// @param owner The owner of the token.
    event TokenUnstaked(uint256 indexed tokenId, address indexed owner);

    /// @dev Emitted when contract parameters are updated by the owner.
    event ParametersUpdated();

    /// @dev Emitted when owner withdraws Ether from the contract.
    event EtherWithdrawn(address indexed to, uint256 amount);

    // --- State Variables ---

    string private _name;
    string private _symbol;

    // ERC721 Standard Mappings
    mapping(uint256 => address) private _tokenOwners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    uint256 private _totalSupply;

    // Entanglement State
    mapping(uint256 => uint256) private _tokenToPairId; // token ID => pair ID
    mapping(uint256 => uint256[2]) private _pairIdToTokens; // pair ID => [token ID 1, token ID 2]
    mapping(uint256 => PairStatus) private _pairStatus; // pair ID => status
    uint256 private _nextTokenId;
    uint256 private _nextPairId;

    // Token State (Numerical value)
    mapping(uint256 => uint256) private _tokenState;
    uint256 public constant MAX_TOKEN_STATE = 1000; // Define a max state value for analogy

    // VRF State
    VRFCoordinatorV2Interface immutable i_vrfCoordinator;
    uint64 private i_subscriptionId;
    bytes32 private i_keyHash;
    uint32 private i_requestConfirmations;
    uint32 private i_callbackGasLimit;
    mapping(uint256 => uint256) private _requestIdToTokenId; // request ID => token ID that triggered it

    // Minting Parameters
    uint256 public mintCost = 0.01 ether; // Cost per pair
    uint256 public maxPairs = 1000;     // Max pairs to mint

    // Staking State
    mapping(uint256 => bool) private _isStaked;
    mapping(uint256 => uint256) private _stakeStartTime; // Timestamp when staked

    // Measurement Cooldown
    mapping(uint256 => uint256) private _lastMeasurementTime; // Timestamp of last measurement request
    uint256 public measurementCooldown = 1 days; // Cooldown duration between measurements per token

    // Metadata
    string private _baseURI;

    // --- Modifiers ---

    modifier onlyPairMember(uint256 pairId, uint256 tokenId) {
        require(_pairIdToTokens[pairId][0] == tokenId || _pairIdToTokens[pairId][1] == tokenId, "Not a member of this pair");
        _;
    }

    modifier onlyEntangled(uint256 pairId) {
        require(_pairStatus[pairId] == PairStatus.Entangled, "Pair is not Entangled");
        _;
    }

    modifier onlyCollapsed(uint256 pairId) {
        require(_pairStatus[pairId] == PairStatus.Collapsed, "Pair is not Collapsed");
        _;
    }

    modifier onlySeparated(uint256 pairId) {
        require(_pairStatus[pairId] == PairStatus.Separated, "Pair is not Separated");
        _;
    }

    modifier notStaked(uint256 tokenId) {
        require(!_isStaked[tokenId], "Token is staked");
        _;
    }

    modifier onlyStaked(uint256 tokenId) {
        require(_isStaked[tokenId], "Token is not staked");
        _;
    }

    // --- Constructor ---

    /// @notice Constructs the QENFT contract.
    /// @param name_ Name of the NFT collection.
    /// @param symbol_ Symbol of the NFT collection.
    /// @param subscriptionId Chainlink VRF subscription ID.
    /// @param keyHash Chainlink VRF key hash.
    /// @param requestConfirmations Chainlink VRF request confirmations.
    /// @param callbackGasLimit Chainlink VRF callback gas limit.
    /// @param baseURI_ The base URI for token metadata.
    constructor(
        string memory name_,
        string memory symbol_,
        uint64 subscriptionId,
        bytes32 keyHash,
        uint32 requestConfirmations,
        uint32 callbackGasLimit,
        string memory baseURI_
    )
        VRFV2Base(0xC02aaA39B223FE8D0A0E5C4F27EAD9083C756Cc2) // Example VRF Coordinator address (update for specific network)
        Ownable(msg.sender)
    {
        _name = name_;
        _symbol = symbol_;
        i_subscriptionId = subscriptionId;
        i_keyHash = keyHash;
        i_requestConfirmations = requestConfirmations;
        i_callbackGasLimit = callbackGasLimit;
        _baseURI = baseURI_;
        _nextTokenId = 1; // Start token IDs from 1
        _nextPairId = 1;  // Start pair IDs from 1
    }

    // --- ERC-721 Standard Functions ---

    function supportsInterface(bytes4 interfaceId) public view override(ERC165, IERC721) returns (bool) {
        return interfaceId == type(IERC721).interfaceId || super.supportsInterface(interfaceId);
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function balanceOf(address owner) public view override returns (uint256) {
        require(owner != address(0), "Address zero is not a valid owner");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view override returns (address) {
        address owner = _tokenOwners[tokenId];
        require(owner != address(0), "Owner query for non-existent token");
        return owner;
    }

    function transferFrom(address from, address to, uint256 tokenId) public override notStaked(tokenId) {
        // Basic ERC721 transfer logic, including checks for approvals etc.
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override notStaked(tokenId) {
        // Basic ERC721 safe transfer logic
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override notStaked(tokenId) {
        // Basic ERC721 safe transfer logic with data
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    function approve(address to, uint256 tokenId) public override notStaked(tokenId) {
        address owner = ownerOf(tokenId);
        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()), "Approve caller is not owner nor approved for all");
        _approve(to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public override {
        require(operator != _msgSender(), "Approve to caller");
        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    function getApproved(uint256 tokenId) public view override returns (address) {
        require(_exists(tokenId), "Approval query for non-existent token");
        return _tokenApprovals[tokenId];
    }

    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /// @dev See {IERC721Metadata-tokenURI}.
    /// @dev This implementation assumes a metadata server that can lookup
    ///      metadata based on token ID and potentially query the contract
    ///      for the current state.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "URI query for non-existent token");
        // Simple base URI + token ID concatenation
        return string(abi.encodePacked(_baseURI, Strings.toString(tokenId)));
    }

    // --- Core Entanglement Functions ---

    /// @notice Mints a new pair of entangled QENFTs to the caller.
    /// @dev Requires payment of `mintCost` and adheres to `maxPairs`.
    function mintEntangledPair() public payable {
        uint256 pairId = _nextPairId;
        uint256 tokenId1 = _nextTokenId;
        uint256 tokenId2 = _nextTokenId + 1;

        require(pairId <= maxPairs, "Maximum number of pairs minted");
        require(msg.value >= mintCost, "Insufficient payment");

        // Mint first token
        _safeMint(msg.sender, tokenId1);
        _tokenToPairId[tokenId1] = pairId;
        _pairIdToTokens[pairId][0] = tokenId1;
        _tokenState[tokenId1] = 0; // Initial state

        // Mint second token
        _safeMint(msg.sender, tokenId2);
        _tokenToPairId[tokenId2] = pairId;
        _pairIdToTokens[pairId][1] = tokenId2;
        _tokenState[tokenId2] = MAX_TOKEN_STATE; // Initial entangled state (e.g., opposite)

        // Set pair status and increment counters
        _pairStatus[pairId] = PairStatus.Entangled;
        _nextTokenId += 2;
        _nextPairId++;

        emit MintedPair(pairId, tokenId1, tokenId2, msg.sender);

        // Refund any excess payment
        if (msg.value > mintCost) {
            payable(msg.sender).transfer(msg.value - mintCost);
        }
    }

    /// @notice Requests a state measurement for an entangled, unstaked token.
    /// @dev Triggers a Chainlink VRF request. Requires adherence to cooldown.
    /// @param tokenId The ID of the token to measure.
    /// @return requestId The ID of the VRF request.
    function requestStateMeasurement(uint256 tokenId) public notStaked(tokenId) returns (uint256 requestId) {
        uint256 pairId = _tokenToPairId[tokenId];
        require(pairId != 0, "Token is not part of a pair");
        require(_pairStatus[pairId] == PairStatus.Entangled, "Pair is not Entangled");
        require(_msgSender() == ownerOf(tokenId), "Only owner can request measurement");
        require(block.timestamp >= _lastMeasurementTime[tokenId] + measurementCooldown, "Measurement on cooldown");

        // Request randomness from Chainlink VRF
        requestId = i_vrfCoordinator.requestRandomWords(
            i_keyHash,
            i_subscriptionId,
            i_requestConfirmations,
            i_callbackGasLimit,
            1 // Request 1 random word
        );

        _requestIdToTokenId[requestId] = tokenId;
        _lastMeasurementTime[tokenId] = block.timestamp; // Set cooldown start time

        return requestId;
    }

    /// @notice Callback function for Chainlink VRF.
    /// @dev Called by the VRF coordinator after a random number is generated.
    ///      Updates the state of the requesting token and its entangled partner.
    /// @param requestId The ID of the VRF request.
    /// @param randomWords An array of random words.
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        uint256 tokenId = _requestIdToTokenId[requestId];
        require(tokenId != 0, "Request ID not found"); // Should not happen with correct VRF setup

        uint256 pairId = _tokenToPairId[tokenId];
        // Only update state if the pair is still entangled
        if (_pairStatus[pairId] != PairStatus.Entangled) {
            // If pair is not entangled, randomness is not applied to states
            delete _requestIdToTokenId[requestId]; // Clean up mapping
            return;
        }

        // Get the random word and map it to the state range (0 to MAX_TOKEN_STATE)
        uint256 randomness = randomWords[0];
        uint256 newState1 = randomness % (MAX_TOKEN_STATE + 1); // State for the requesting token

        // Determine the partner token ID
        uint256 tokenId1 = _pairIdToTokens[pairId][0];
        uint256 tokenId2 = _pairIdToTokens[pairId][1];
        uint256 pairPartnerTokenId = (tokenId == tokenId1) ? tokenId2 : tokenId1;

        // Determine the state for the partner token based on the entanglement rule
        // Example rule: stateB = MAX_TOKEN_STATE - stateA
        uint256 newState2 = MAX_TOKEN_STATE - newState1;

        // Update states and emit event
        uint256 oldState1 = _tokenState[tokenId];
        uint256 oldState2 = _tokenState[pairPartnerTokenId];

        _tokenState[tokenId] = newState1;
        _tokenState[pairPartnerTokenId] = newState2;

        emit StateMeasured(tokenId, oldState1, newState1, pairPartnerTokenId, oldState2, newState2);

        // Clean up mapping
        delete _requestIdToTokenId[requestId];
    }

    /// @notice Collapses an entangled pair.
    /// @dev Changes pair status to Collapsed. Can only be called by an owner of one of the pair members.
    ///      Collapsed pairs cannot have their state measured via `requestStateMeasurement`.
    /// @param pairId The ID of the pair to collapse.
    function collapsePair(uint256 pairId) public onlyEntangled(pairId) {
        uint256 tokenId1 = _pairIdToTokens[pairId][0];
        uint256 tokenId2 = _pairIdToTokens[pairId][1];
        require(_msgSender() == ownerOf(tokenId1) || _msgSender() == ownerOf(tokenId2), "Caller must own a token in the pair");

        _pairStatus[pairId] = PairStatus.Collapsed;
        emit PairCollapsed(pairId);
    }

    /// @notice Separates an entangled pair.
    /// @dev Changes pair status to Separated. Can only be called by an owner of one of the pair members.
    ///      Separated pairs lose their entanglement link. Their states remain as they were, and
    ///      future measurements on individual tokens (if the logic allowed, though this contract
    ///      only allows measurement of Entangled tokens) would not affect the former partner.
    ///      In *this* implementation, once separated, `requestStateMeasurement` is not possible.
    /// @param pairId The ID of the pair to separate.
    function separatePair(uint256 pairId) public onlyEntangled(pairId) {
        uint256 tokenId1 = _pairIdToTokens[pairId][0];
        uint256 tokenId2 = _pairIdToTokens[pairId][1];
        require(_msgSender() == ownerOf(tokenId1) || _msgSender() == ownerOf(tokenId2), "Caller must own a token in the pair");

        _pairStatus[pairId] = PairStatus.Separated;
        // Note: We don't zero out tokenToPairId or pairIdToTokens mappings
        // so that lookup functions still work for historical data.
        emit PairSeparated(pairId);
    }

    // --- State & Pairing Read Functions ---

    /// @notice Gets the pair ID for a given token ID.
    /// @param tokenId The ID of the token.
    /// @return The pair ID, or 0 if the token is not part of a pair (shouldn't happen for minted tokens).
    function getPairId(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "Token does not exist");
        return _tokenToPairId[tokenId];
    }

    /// @notice Gets the two token IDs that form a pair.
    /// @param pairId The ID of the pair.
    /// @return An array containing the two token IDs.
    function getPairMembers(uint256 pairId) public view returns (uint256[2] memory) {
        require(_pairStatus[pairId] != PairStatus.NonExistent, "Pair does not exist");
        return _pairIdToTokens[pairId];
    }

    /// @notice Gets the current entanglement status of a pair.
    /// @param pairId The ID of the pair.
    /// @return The PairStatus enum value.
    function getEntanglementStatus(uint256 pairId) public view returns (PairStatus) {
        return _pairStatus[pairId];
    }

    /// @notice Gets the current numerical state value of a token.
    /// @param tokenId The ID of the token.
    /// @return The token's state value.
    function getTokenState(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "Token does not exist");
        return _tokenState[tokenId];
    }

    // --- Staking Functions ---

    /// @notice Stakes an entangled token owned by the caller.
    /// @dev Staked tokens cannot be measured or transferred (via standard functions).
    /// @param tokenId The ID of the token to stake.
    function stakeToken(uint256 tokenId) public notStaked(tokenId) {
        require(_msgSender() == ownerOf(tokenId), "Only owner can stake token");
        uint256 pairId = _tokenToPairId[tokenId];
        require(pairId != 0, "Token is not part of a pair");
        require(_pairStatus[pairId] == PairStatus.Entangled, "Only Entangled tokens can be staked");

        _isStaked[tokenId] = true;
        _stakeStartTime[tokenId] = block.timestamp;
        emit TokenStaked(tokenId, _msgSender());
    }

    /// @notice Unstakes a token owned by the caller.
    /// @param tokenId The ID of the token to unstake.
    function unstakeToken(uint256 tokenId) public onlyStaked(tokenId) {
        require(_msgSender() == ownerOf(tokenId), "Only owner can unstake token");

        _isStaked[tokenId] = false;
        _stakeStartTime[tokenId] = 0; // Reset stake time
        emit TokenUnstaked(tokenId, _msgSender());
    }

    /// @notice Checks if a token is currently staked.
    /// @param tokenId The ID of the token.
    /// @return True if staked, false otherwise.
    function isTokenStaked(uint256 tokenId) public view returns (bool) {
        return _isStaked[tokenId];
    }

    /// @notice Gets the timestamp when a token was staked.
    /// @param tokenId The ID of the token.
    /// @return The timestamp, or 0 if not staked.
    function getStakeStartTime(uint256 tokenId) public view returns (uint256) {
        return _stakeStartTime[tokenId];
    }

    // --- Admin/Governance Functions (Only Owner) ---

    /// @notice Sets the maximum number of pairs that can be minted.
    /// @dev Only callable by the contract owner.
    /// @param _maxPairs The new maximum pair count.
    function setMaxPairs(uint256 _maxPairs) public onlyOwner {
        require(_maxPairs >= _nextPairId -1 , "New max pairs must be greater than or equal to already minted pairs"); // Ensure already minted pairs are still valid
        maxPairs = _maxPairs;
        emit ParametersUpdated();
    }

    /// @notice Sets the cost in Ether to mint a new entangled pair.
    /// @dev Only callable by the contract owner.
    /// @param _mintCost The new minting cost in wei.
    function setMintCost(uint256 _mintCost) public onlyOwner {
        mintCost = _mintCost;
        emit ParametersUpdated();
    }

    /// @notice Allows the owner to withdraw accumulated Ether from the contract.
    /// @dev Only callable by the contract owner.
    /// @param to The address to send the Ether to.
    function withdrawEther(address payable to) public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No Ether to withdraw");
        (bool success, ) = to.call{value: balance}("");
        require(success, "Ether withdrawal failed");
        emit EtherWithdrawn(to, balance);
    }

    /// @notice Updates Chainlink VRF parameters.
    /// @dev Only callable by the contract owner. Requires careful handling of subscription ID.
    /// @param _subscriptionId The new subscription ID.
    /// @param _keyHash The new key hash.
    /// @param _requestConfirmations The new request confirmations.
    /// @param _callbackGasLimit The new callback gas limit.
    function setVRFParameters(
        uint64 _subscriptionId,
        bytes32 _keyHash,
        uint32 _requestConfirmations,
        uint32 _callbackGasLimit
    ) public onlyOwner {
        i_subscriptionId = _subscriptionId;
        i_keyHash = _keyHash;
        i_requestConfirmations = _requestConfirmations;
        i_callbackGasLimit = _callbackGasLimit;
        emit ParametersUpdated();
    }

    /// @notice Updates the base URI for token metadata.
    /// @dev Only callable by the contract owner.
    /// @param _baseURI The new base URI.
    function updateBaseURI(string memory _baseURI) public onlyOwner {
        _baseURI = _baseURI;
        emit ParametersUpdated();
    }

    /// @notice Sets the minimum time between state measurements for a token.
    /// @dev Only callable by the contract owner.
    /// @param _cooldown The cooldown duration in seconds.
    function setMeasurementCooldown(uint256 _cooldown) public onlyOwner {
        measurementCooldown = _cooldown;
        emit ParametersUpdated();
    }

     /// @notice Gets the timestamp of the last state measurement request for a token.
    /// @param tokenId The ID of the token.
    /// @return The timestamp of the last measurement request, or 0 if never measured.
    function getLastMeasurementTime(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "Token does not exist");
        return _lastMeasurementTime[tokenId];
    }


    // --- Internal Helper Functions (ERC721 Overrides/Helpers) ---

    /// @dev Mints a token to an address without checking if the recipient is a smart contract.
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "Mint to the zero address");
        require(!_exists(tokenId), "Token already minted");

        _tokenOwners[tokenId] = to;
        _balances[to]++;
        _totalSupply++;

        emit Transfer(address(0), to, tokenId);
    }

    /// @dev Mints a token and checks if the recipient is a smart contract,
    ///      calling `onERC721Received` if it is.
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, ""),
            "ERC721Receiver not implemented or returned incorrectly"
        );
    }


    /// @dev Transfers token ownership, including checks for staking.
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ownerOf(tokenId) == from, "Transfer from incorrect owner");
        require(to != address(0), "Transfer to the zero address");
        require(!_isStaked[tokenId], "Cannot transfer staked token"); // Custom staking check

        // Clear approvals before transfer
        _approve(address(0), tokenId);

        _balances[from]--;
        _tokenOwners[tokenId] = to;
        _balances[to]++;

        emit Transfer(from, to, tokenId);
    }

    /// @dev Safely transfers token ownership, including checks for staking.
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal virtual {
         _transfer(from, to, tokenId); // Use the modified _transfer function
         require(
            _checkOnERC721Received(from, to, tokenId, data),
            "ERC721Receiver not implemented or returned incorrectly"
        );
    }

    /// @dev Approves an address to control a token.
    function _approve(address to, uint256 tokenId) internal virtual {
         _tokenApprovals[tokenId] = to;
         emit Approval(ownerOf(tokenId), to, tokenId);
    }


    /// @dev Checks if a token exists.
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _tokenOwners[tokenId] != address(0);
    }

    /// @dev Checks if the sender is the owner or approved for a token.
     function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "Operator query for non-existent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }


    /// @dev Internal function to check if a transfer to a smart contract is safe.
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory data) private returns (bool) {
        if (to.code.length == 0) {
            return true; // Not a smart contract
        }
        // Call onERC721Received on the recipient contract
        try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
            return retval == IERC721Receiver.onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert("Transfer to non ERC721Receiver implementer");
            } else {
                /// @solidity exclusive
                revert(string(reason));
            }
        }
    }

    // --- VRF Configuration & Read Functions ---

    /// @notice Returns the Chainlink VRF subscription ID used by the contract.
    function getSubscriptionId() public view onlyOwner returns (uint64) {
        return i_subscriptionId;
    }

    /// @notice Returns the Chainlink VRF key hash used by the contract.
    function getKeyHash() public view onlyOwner returns (bytes32) {
        return i_keyHash;
    }

    /// @notice Returns the number of block confirmations required for VRF requests.
    function getRequestConfirmations() public view onlyOwner returns (uint32) {
        return i_requestConfirmations;
    }

    /// @notice Returns the callback gas limit for VRF requests.
    function getCallbackGasLimit() public view onlyOwner returns (uint32) {
        return i_callbackGasLimit;
    }

    // --- Additional Read Functions ---

    /// @notice Returns the current total supply of tokens.
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /// @notice Returns the current number of pairs that have been minted.
    function mintedPairsCount() public view returns (uint256) {
        return _nextPairId - 1;
    }

    // --- Fallback and Receive ---

    receive() external payable {}
    fallback() external payable {}
}

// Dummy implementation of ERC721, ERC165, Context interfaces if not using OpenZeppelin imports
// This is illustrative only. Using standard imports is recommended.
/*
interface IERC721 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function setApprovalForAll(address operator, bool _approved) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

library Strings {
    function toString(uint256 value) internal pure returns (string memory) {
        // Code from OpenZeppelin's Strings.sol
         if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = bytes1(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
    }
}
*/
```