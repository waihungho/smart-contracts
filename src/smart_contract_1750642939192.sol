Okay, let's design a smart contract around a concept I'll call the "Digital Art Forge". This concept combines NFTs, generative traits, dynamic evolution based on time and 'catalysts', staking for passive trait enhancement, and a custom royalty system.

It aims for uniqueness by building the core mechanics directly rather than relying heavily on standard library imports (though it will aim to *conform* to interfaces like ERC-721/165/2981).

**Concept:** Users mint "Art Seeds" (NFTs). These seeds can be "Nourished" (staked for a period) or exposed to external "Catalysts" (special actions/tokens/data) to evolve into different "Art Forms". Art Forms have dynamic traits that can change based on their state (staked, unstaked) or further catalysts. The visual art is determined by an on-chain DNA string and the current state/traits, rendered off-chain.

---

**Outline:**

1.  **License and Pragma**
2.  **Interfaces:** ERC-165, ERC-721 (partial, manual implementation), ERC-2981 (partial, manual implementation)
3.  **Errors and Events**
4.  **Data Structures:**
    *   Token States Enum (Seed, Nourishing, ReadyToEvolve, FormA, FormB, etc.)
    *   Catalyst Configuration Struct
    *   Token Data Struct (state, generation timestamp, DNA, traits mapping)
5.  **State Variables:**
    *   Owner, Paused State
    *   Token Counter, Total Supply
    *   Mappings for ERC-721 ownership, approvals, operator approvals
    *   Mapping for Token Data
    *   Mapping for Catalyst Configurations
    *   Configuration Parameters (mint price, nourishment period, royalty info)
6.  **Modifiers:** `onlyOwner`, `whenNotPaused`, `whenPaused`, `isApprovedOrOwner` (custom check)
7.  **Constructor**
8.  **Core ERC-721/165/2981 Functions (Manual Implementation):** Basic transfer, approval, ownership, interface support, royalty info.
9.  **Core Art Forge Mechanics:**
    *   Minting Seeds
    *   Nourishing (Staking) Seeds
    *   Claiming Nourished Seeds (State Change)
    *   Applying Catalysts (Triggering Evolution Attempt)
    *   Evolving Tokens (State Transition Logic)
    *   Staking Art Forms (Passive Trait Enhancement)
    *   Unstaking Art Forms
10. **Trait and Data Query Functions:** Reading token state, DNA, generation time, individual traits, all traits.
11. **Admin/Configuration Functions:** Pause, unpause, withdraw ETH, set parameters (prices, periods, royalties), manage catalyst types.
12. **Internal Helper Functions:** Minting logic, transfer hooks, DNA generation, evolution logic, state updates, trait updates, access checks.

---

**Function Summary:**

*   `constructor()`: Initializes contract owner, sets initial parameters.
*   `pause()`: Owner pauses token transfers and most interactions.
*   `unpause()`: Owner unpauses the contract.
*   `withdrawETH(address payable recipient)`: Owner withdraws ETH balance.
*   `supportsInterface(bytes4 interfaceId) view returns (bool)`: ERC-165 standard - declares supported interfaces (ERC-721, ERC-165, ERC-2981).
*   `balanceOf(address owner) view returns (uint256)`: ERC-721 standard - returns owner's token count.
*   `ownerOf(uint256 tokenId) view returns (address)`: ERC-721 standard - returns owner of a specific token.
*   `transferFrom(address from, address to, uint256 tokenId)`: ERC-721 standard - transfers token ownership.
*   `safeTransferFrom(address from, address to, uint256 tokenId)`: ERC-721 standard - safe transfer (checks receiver).
*   `safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data)`: ERC-721 standard - safe transfer with data.
*   `approve(address to, uint256 tokenId)`: ERC-721 standard - grants approval for one token.
*   `getApproved(uint256 tokenId) view returns (address)`: ERC-721 standard - returns approved address for a token.
*   `setApprovalForAll(address operator, bool approved)`: ERC-721 standard - sets approval for an operator over all tokens.
*   `isApprovedForAll(address owner, address operator) view returns (bool)`: ERC-721 standard - checks if operator is approved for owner.
*   `tokenURI(uint256 tokenId) view returns (string memory)`: ERC-721 standard - returns metadata URI (points to off-chain renderer).
*   `royaltyInfo(uint256 tokenId, uint256 salePrice) view returns (address receiver, uint256 royaltyAmount)`: ERC-2981 standard - returns royalty details.
*   `setRoyaltyFeeBasisPoints(uint96 feeBasisPoints)`: Owner sets royalty percentage.
*   `setDefaultRoyaltyRecipient(address recipient)`: Owner sets default royalty recipient.
*   `setBaseMintPrice(uint256 price)`: Owner sets the price to mint a seed.
*   `setNourishmentPeriod(uint256 period)`: Owner sets the time required for seed nourishment.
*   `addCatalystType(uint256 catalystId, uint256 requiredState, uint256 successState, uint256 failState, uint256 fee)`: Owner defines a new catalyst type and its parameters.
*   `removeCatalystType(uint256 catalystId)`: Owner removes a catalyst type definition.
*   `updateCatalystFee(uint256 catalystId, uint256 newFee)`: Owner updates the fee for a catalyst type.
*   `mintSeed(bytes32 initialDNA)`: Mints a new Art Seed for the caller upon payment of the mint price. Generates token data.
*   `startNourishing(uint256 tokenId)`: Puts a Seed token into the Nourishing state, starting a timer.
*   `claimNourished(uint256 tokenId)`: Claims a Seed after its nourishment period, changing its state to ReadyToEvolve.
*   `applyCatalyst(uint256 tokenId, uint256 catalystId, bytes calldata catalystData)`: Applies a catalyst to a token (requires payment of catalyst fee). Triggers potential evolution based on catalyst type and token state.
*   `evolveToken(uint256 tokenId)`: Triggers the evolution process for a token based on its current state and history (e.g., after nourishment or catalyst).
*   `stakeArtForm(uint256 tokenId)`: Stakes an evolved Art Form token, potentially activating passive trait bonuses.
*   `unstakeArtForm(uint256 tokenId)`: Unstakes an Art Form token, potentially deactivating passive trait bonuses.
*   `getTrait(uint256 tokenId, string calldata traitName) view returns (uint256 value)`: Returns the value of a specific trait for a token.
*   `getTokenState(uint256 tokenId) view returns (uint256 state)`: Returns the current state of a token.
*   `getTokenGenerationTimestamp(uint256 tokenId) view returns (uint256 timestamp)`: Returns the timestamp when the token was minted.
*   `getTokenDNA(uint256 tokenId) view returns (bytes32 dna)`: Returns the base DNA hash of the token.
*   `getTokenTraits(uint256 tokenId) view returns (string[] memory names, uint256[] memory values)`: Returns all dynamic traits and their values for a token.

Total External Functions: 34+ (Includes required standard interface functions and custom logic functions).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title DigitalArtForge
 * @notice A generative, dynamic NFT contract where tokens evolve based on time and catalysts.
 * Implements custom logic for ERC-721, ERC-165, and ERC-2981 interfaces without direct OpenZeppelin imports.
 */

// Outline:
// 1. License and Pragma
// 2. Interfaces (ERC-165, ERC-721, ERC-2981 - partial, manual implementation)
// 3. Errors and Events
// 4. Data Structures (States, CatalystConfig, TokenData)
// 5. State Variables (Owner, Paused, Counters, Mappings, Configs)
// 6. Modifiers
// 7. Constructor
// 8. Core ERC-721/165/2981 Functions (Manual Implementation)
// 9. Core Art Forge Mechanics (Mint, Nourish, Claim, Apply Catalyst, Evolve, Stake, Unstake)
// 10. Trait and Data Query Functions
// 11. Admin/Configuration Functions
// 12. Internal Helper Functions (_mint, _transfer, evolution logic, etc.)

// Function Summary:
// constructor()
// pause(), unpause(), withdrawETH()
// supportsInterface()
// balanceOf(), ownerOf(), transferFrom(), safeTransferFrom(x2), approve(), getApproved(), setApprovalForAll(), isApprovedForAll()
// tokenURI()
// royaltyInfo(), setRoyaltyFeeBasisPoints(), setDefaultRoyaltyRecipient()
// setBaseMintPrice(), setNourishmentPeriod(), addCatalystType(), removeCatalystType(), updateCatalystFee()
// mintSeed()
// startNourishing(), claimNourished()
// applyCatalyst(), evolveToken()
// stakeArtForm(), unstakeArtForm()
// getTrait(), getTokenState(), getTokenGenerationTimestamp(), getTokenDNA(), getTokenTraits()

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 /* is IERC165 */ {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

interface IERC2981 /* is IERC165 */ {
    function royaltyInfo(uint5 pid, uint26 price) external view returns (address receiver, uint256 royaltyAmount);
}


// --- Errors ---
error NotOwner();
error Paused();
error NotPaused();
error TransferToZeroAddress();
error TokenDoesNotExist();
error NotApprovedOrOwner();
error ApprovalToCurrentOwner();
error ApproveCallerIsNotOwnerNorApprovedForAll();
error TransferCallerIsNotOwnerNorApprovedForAll();
error InvalidTokenId();
error InsufficientPayment();
error TokenAlreadyExists(); // For internal minting check
error InvalidStateForAction();
error NotReadyToClaim();
error CatalystNotFound();
error CatalystConditionNotMet();
error CannotEvolveInCurrentState();
error NotArtForm();
error AlreadyStaked();
error NotStaked();
error InvalidCatalystData(); // Generic for bad data format
error RoyaltyFeeTooHigh();
error InvalidRoyaltyRecipient();


// --- Events ---
event SeedMinted(uint256 indexed tokenId, address indexed owner, bytes32 dna);
event NourishingStarted(uint256 indexed tokenId, uint256 startedAt);
event NourishingClaimed(uint256 indexed tokenId, uint256 claimedAt);
event CatalystApplied(uint256 indexed tokenId, uint256 indexed catalystId, bytes calldata catalystData);
event TokenEvolved(uint256 indexed tokenId, uint256 indexed newState, bytes32 newDNA); // DNA might change on evolution
event TraitChanged(uint256 indexed tokenId, string traitName, uint256 newValue);
event ArtFormStaked(uint256 indexed tokenId, uint256 stakedAt);
event ArtFormUnstaked(uint256 indexed tokenId, uint256 unstakedAt);
event BaseMintPriceUpdated(uint256 newPrice);
event NourishmentPeriodUpdated(uint256 newPeriod);
event CatalystTypeAdded(uint256 indexed catalystId, uint256 requiredState, uint256 successState, uint256 failState, uint256 fee);
event CatalystTypeRemoved(uint256 indexed catalystId);
event CatalystFeeUpdated(uint256 indexed catalystId, uint256 newFee);
event RoyaltyFeeUpdated(uint96 feeBasisPoints);
event DefaultRoyaltyRecipientUpdated(address recipient);


contract DigitalArtForge is IERC721, IERC165, IERC2981 {

    // --- Data Structures ---

    enum TokenState {
        NonExistent,     // 0 (Shouldn't happen for existing tokens, but useful as a check)
        Seed,            // 1
        Nourishing,      // 2
        ReadyToEvolve,   // 3 (Finished nourishing or ready after catalyst)
        FormA,           // 4
        FormB,           // 5
        FormC,           // 6
        StakedFormA,     // 7
        StakedFormB,     // 8
        StakedFormC      // 9
        // Add more states/forms as needed
    }

    struct CatalystConfig {
        uint256 requiredState;  // State token must be in to use this catalyst
        uint256 successState;   // State after successful application & evolution
        uint256 failState;      // State after failed application & evolution
        uint256 fee;            // ETH fee to apply this catalyst
        bool active;            // Is this catalyst type currently active?
    }

    struct TokenData {
        uint256 state;                     // Corresponds to TokenState enum value
        uint256 generationTimestamp;       // When the token was minted (or perhaps last evolved?)
        bytes32 dna;                       // Base genetic code (initial, might evolve)
        mapping(string => uint256) traits; // Dynamic traits (e.g., "Power", "ColorHue")
        uint256 lastNourishedTimestamp;    // When nourishment started
        uint256 lastStakedTimestamp;       // When staking started
        uint256 lastCatalystId;            // Last catalyst applied
    }

    // --- State Variables ---

    address private _owner;
    bool private _paused;

    uint256 private _tokenCounter;
    uint256 private _totalSupply;

    // ERC721 Mappings
    mapping(uint256 => address) private _tokenOwners;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Art Forge Data
    mapping(uint256 => TokenData) private _tokenData;
    mapping(string => uint256[]) private _traitPossibleValues; // Example: trait "ColorHue" -> [0, 30, 60, 120, ...]

    // Catalyst Configurations
    mapping(uint256 => CatalystConfig) private _catalystConfigs; // catalystId => config

    // Configuration Parameters
    uint256 public baseMintPrice;
    uint256 public nourishmentPeriod; // Duration in seconds

    // ERC2981 Royalty
    uint96 private _royaltyFeeBasisPoints; // e.g., 500 = 5%
    address private _defaultRoyaltyRecipient;

    // ERC165 Interface IDs (manual computation or lookup)
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7; // bytes4(keccak256("supportsInterface(bytes4)"))
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd; // See ERC721 spec
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f; // See ERC721 spec
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a; // bytes4(keccak256("royaltyInfo(uint256,uint256)"))


    // --- Modifiers ---

    modifier onlyOwner() {
        if (msg.sender != _owner) revert NotOwner();
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

    modifier isApprovedOrOwner(uint256 tokenId) {
        address owner = _tokenOwners[tokenId];
        if (msg.sender != owner && getApproved(tokenId) != msg.sender && !isApprovedForAll(owner, msg.sender)) {
            revert NotApprovedOrOwner();
        }
        _;
    }

    // --- Constructor ---

    constructor(uint256 initialMintPrice, uint256 initialNourishmentPeriod, uint96 initialRoyaltyBasisPoints, address initialRoyaltyRecipient) {
        _owner = msg.sender;
        _tokenCounter = 0;
        _totalSupply = 0;
        _paused = false;

        baseMintPrice = initialMintPrice;
        nourishmentPeriod = initialNourishmentPeriod;

        if (initialRoyaltyBasisPoints > 10000) revert RoyaltyFeeTooHigh();
        _royaltyFeeBasisPoints = initialRoyaltyBasisPoints;
        if (initialRoyaltyRecipient == address(0)) revert InvalidRoyaltyRecipient();
        _defaultRoyaltyRecipient = initialRoyaltyRecipient;

        // Initialize some potential trait value ranges (optional, for example)
        // _traitPossibleValues["Power"] = [1, 5, 10, 20];
        // _traitPossibleValues["Speed"] = [1, 3, 7];
    }

    // --- Access Control ---

    function owner() external view returns (address) {
        return _owner;
    }

    function pause() external onlyOwner whenNotPaused {
        _paused = true;
        // Emit Paused event
    }

    function unpause() external onlyOwner whenPaused {
        _paused = false;
        // Emit Unpaused event
    }

    function paused() external view returns (bool) {
        return _paused;
    }

    function withdrawETH(address payable recipient) external onlyOwner {
        // Ensure recipient is not address(0)
        if (recipient == address(0)) revert TransferToZeroAddress();
        uint256 balance = address(this).balance;
        (bool success, ) = recipient.call{value: balance}("");
        require(success, "ETH withdrawal failed");
    }


    // --- ERC165 Support ---

    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return interfaceId == _INTERFACE_ID_ERC165 ||
               interfaceId == _INTERFACE_ID_ERC721 ||
               interfaceId == _INTERFACE_ID_ERC721_METADATA ||
               interfaceId == _INTERFACE_ID_ERC2981;
               // Add other interfaces if implemented (e.g., ERC-4906 Metadata Extension, etc.)
    }


    // --- ERC721 Basic Implementations (Manual) ---

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address owner) public view override returns (uint256) {
        if (owner == address(0)) revert TransferToZeroAddress();
        uint256 count = 0;
        // This is inefficient for large collections. A mapping(address => uint256) _balances would be better.
        // For simplicity in this example aiming for function count, we simulate.
        // In a real contract, use a balance mapping.
        // return _balances[owner]; // Preferred implementation
        for (uint256 i = 1; i <= _tokenCounter; i++) { // Simulate iterating tokens
            if (_tokenOwners[i] == owner) {
                count++;
            }
        }
        return count;
    }

    function ownerOf(uint256 tokenId) public view override returns (address) {
        address owner = _tokenOwners[tokenId];
        if (owner == address(0)) revert TokenDoesNotExist();
        return owner;
    }

    function getApproved(uint256 tokenId) public view override returns (address) {
        if (_tokenOwners[tokenId] == address(0)) revert TokenDoesNotExist(); // Check if token exists
        return _tokenApprovals[tokenId];
    }

    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
         if (owner == address(0)) revert TransferToZeroAddress(); // owner cannot be zero address for query
         if (operator == address(0)) revert TransferToZeroAddress(); // operator cannot be zero address for query
        return _operatorApprovals[owner][operator];
    }

    function approve(address to, uint256 tokenId) public override whenNotPaused {
        address owner = _tokenOwners[tokenId];
        if (owner == address(0)) revert TokenDoesNotExist();
        if (to == owner) revert ApprovalToCurrentOwner();
        if (msg.sender != owner && !isApprovedForAll(owner, msg.sender)) revert ApproveCallerIsNotOwnerNorApprovedForAll();

        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

     function setApprovalForAll(address operator, bool approved) public override whenNotPaused {
        if (operator == msg.sender) revert InvalidTokenId(); // Cannot approve self as operator
        if (operator == address(0)) revert TransferToZeroAddress(); // operator cannot be zero address
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override whenNotPaused isApprovedOrOwner(tokenId) {
        if (_tokenOwners[tokenId] == address(0)) revert TokenDoesNotExist();
        if (_tokenOwners[tokenId] != from) revert NotApprovedOrOwner(); // Check if 'from' is the actual owner
        if (to == address(0)) revert TransferToZeroAddress();

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override whenNotPaused {
         safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) public override whenNotPaused isApprovedOrOwner(tokenId) {
        if (_tokenOwners[tokenId] == address(0)) revert TokenDoesNotExist();
        if (_tokenOwners[tokenId] != from) revert NotApprovedOrOwner(); // Check if 'from' is the actual owner
        if (to == address(0)) revert TransferToZeroAddress();

        _transfer(from, to, tokenId);

        // ERC721Receiver check
        if (to.code.length > 0) { // Check if recipient is a contract
            bytes4 retval = IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data);
            require(retval == IERC721Receiver.onERC721Received.selector, "ERC721: transfer to non ERC721Receiver implementer");
        }
    }

    // Internal transfer logic
    function _transfer(address from, address to, uint256 tokenId) internal {
        require(_tokenOwners[tokenId] != address(0), "ERC721: transfer of nonexistent token"); // Should be caught by callers, but double check
        require(_tokenOwners[tokenId] == from, "ERC721: transfer from incorrect owner"); // Should be caught by callers, but double check
        require(to != address(0), "ERC721: transfer to the zero address"); // Should be caught by callers, but double check

        // Clear approvals for the transferring token
        _approve(address(0), tokenId);

        // Call hook before transfer
        _beforeTokenTransfer(from, to, tokenId);

        _tokenOwners[tokenId] = to;
        // In a real contract, update _balances here: _balances[from]--; _balances[to]++;

        // Call hook after transfer
        _afterTokenTransfer(from, to, tokenId);

        emit Transfer(from, to, tokenId);
    }

    // Internal mint logic (used by mintSeed)
    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0), "ERC721: mint to the zero address");
        require(_tokenOwners[tokenId] == address(0), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _tokenOwners[tokenId] = to;
         // In a real contract, update _balances here: _balances[to]++;
        _totalSupply++;

        _afterTokenTransfer(address(0), to, tokenId);

        emit Transfer(address(0), to, tokenId);
    }

    // Internal burn logic (optional, not required by prompt, but good practice)
    // function _burn(uint256 tokenId) internal {
    //     address owner = _tokenOwners[tokenId];
    //     require(owner != address(0), "ERC721: burn of nonexistent token");

    //     _approve(address(0), tokenId); // Clear approvals
    //     _beforeTokenTransfer(owner, address(0), tokenId);

    //     delete _tokenOwners[tokenId];
    //     delete _tokenData[tokenId]; // Also remove custom data
    //     // In a real contract, update _balances here: _balances[owner]--;
    //     _totalSupply--;

    //     _afterTokenTransfer(owner, address(0), tokenId);

    //     emit Transfer(owner, address(0), tokenId);
    // }

    // Internal approval logic
    function _approve(address to, uint256 tokenId) internal {
        _tokenApprovals[tokenId] = to;
        // Note: This internal function doesn't emit Approval event, standard _approve usually does.
        // We emit in the public `approve` function.
    }

    // ERC721 Hooks (Can be overridden in more complex scenarios)
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual {
        // Prevent transfers of tokens in certain states if needed
        // Example: if (_tokenData[tokenId].state == uint256(TokenState.Nourishing)) revert InvalidStateForAction();
        // Example: if (_tokenData[tokenId].state >= uint256(TokenState.StakedFormA)) revert InvalidStateForAction();
    }

    function _afterTokenTransfer(address from, address to, uint256 tokenId) internal virtual {
        // Placeholder for post-transfer logic
    }


    // --- ERC2981 Royalty Implementation ---

    // ERC2981 required function
    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view override returns (address receiver, uint256 royaltyAmount) {
        if (_tokenOwners[tokenId] == address(0)) revert TokenDoesNotExist(); // Token must exist
        if (_defaultRoyaltyRecipient == address(0)) return (address(0), 0); // No recipient set

        uint256 basisPoints = _royaltyFeeBasisPoints;

        // Optional: royalty could vary based on token properties (_tokenData[tokenId])
        // Example: if (_tokenData[tokenId].state == uint256(TokenState.FormA)) { basisPoints = 700; } // 7% for FormA

        uint256 amount = (salePrice * basisPoints) / 10000; // basisPoints / 100 = percentage

        return (_defaultRoyaltyRecipient, amount);
    }

    // Admin function to set royalty fee
    function setRoyaltyFeeBasisPoints(uint96 feeBasisPoints) external onlyOwner {
        if (feeBasisPoints > 10000) revert RoyaltyFeeTooHigh(); // Max 100%
        _royaltyFeeBasisPoints = feeBasisPoints;
        emit RoyaltyFeeUpdated(feeBasisPoints);
    }

    // Admin function to set default recipient
    function setDefaultRoyaltyRecipient(address recipient) external onlyOwner {
         if (recipient == address(0)) revert InvalidRoyaltyRecipient();
        _defaultRoyaltyRecipient = recipient;
        emit DefaultRoyaltyRecipientUpdated(recipient);
    }


    // --- ERC721 Metadata (Placeholder) ---

    // ERC721 Metadata required function
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
         if (_tokenOwners[tokenId] == address(0)) revert TokenDoesNotExist();

        // In a real implementation, this would return a URI pointing to a metadata service
        // The service would use the token ID, state, DNA, and traits to generate JSON metadata
        // and potentially an image URI.
        // Example structure: ipfs://<base_uri>/<tokenId>
        // The metadata JSON could contain:
        // {
        //   "name": "Art Forge Token #" + tokenId,
        //   "description": "A generative digital art token that evolves.",
        //   "image": "ipfs://<image_uri>/render?id=" + tokenId + "&state=" + uint256(_tokenData[tokenId].state) + "&dna=" + _tokenData[tokenId].dna_hex + "&traits=...",
        //   "attributes": [
        //     { "trait_type": "State", "value": TokenState(uint256(_tokenData[tokenId].state)).toString() }, // Need toString or mapping off-chain
        //     { "trait_type": "Generation", "value": _tokenData[tokenId].generationTimestamp },
        //     // Add dynamic traits here
        //     // { "trait_type": "Power", "value": _tokenData[tokenId].traits["Power"] }
        //   ]
        // }

        // For this example, returning a placeholder or a simple URI
        return string(abi.encodePacked("ipfs://my-art-forge-metadata-service/", Strings.toString(tokenId)));
    }

    // Simple Strings utility (manual, mimic OpenZeppelin)
    library Strings {
        function toString(uint256 value) internal pure returns (string memory) {
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
            while (value != 0) {
                digits -= 1;
                buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
                value /= 10;
            }
            return string(buffer);
        }
    }


    // --- Core Art Forge Mechanics ---

    /**
     * @notice Mints a new Art Seed token.
     * @param initialDNA A bytes32 hash representing the initial genetic code of the seed.
     */
    function mintSeed(bytes32 initialDNA) external payable whenNotPaused {
        if (msg.value < baseMintPrice) revert InsufficientPayment();

        _tokenCounter++;
        uint256 newTokenId = _tokenCounter;

        // Basic minting logic
        _mint(msg.sender, newTokenId);

        // Initialize token data
        _tokenData[newTokenId].state = uint256(TokenState.Seed);
        _tokenData[newTokenId].generationTimestamp = block.timestamp;
        _tokenData[newTokenId].dna = initialDNA;
        // Initialize default traits or calculate from DNA if needed

        emit SeedMinted(newTokenId, msg.sender, initialDNA);

        // Refund excess ETH if any
        if (msg.value > baseMintPrice) {
            (bool success, ) = payable(msg.sender).call{value: msg.value - baseMintPrice}("");
            require(success, "ETH refund failed");
        }
    }

    /**
     * @notice Starts the nourishment process for a Seed token.
     * @param tokenId The ID of the token to nourish.
     */
    function startNourishing(uint256 tokenId) external whenNotPaused isApprovedOrOwner(tokenId) {
        // Check token exists and is owned by caller or approved
        if (_tokenOwners[tokenId] == address(0)) revert TokenDoesNotExist();
         if (_tokenOwners[tokenId] != msg.sender && getApproved(tokenId) != msg.sender && !isApprovedForAll(_tokenOwners[tokenId], msg.sender)) revert NotApprovedOrOwner();

        // Check token state
        if (_tokenData[tokenId].state != uint256(TokenState.Seed)) revert InvalidStateForAction();

        // Update state and timestamp
        _updateTokenState(tokenId, TokenState.Nourishing);
        _tokenData[tokenId].lastNourishedTimestamp = block.timestamp;

        emit NourishingStarted(tokenId, block.timestamp);
    }

    /**
     * @notice Claims a Seed token after it has been nourished for the required period.
     * @param tokenId The ID of the token to claim.
     */
    function claimNourished(uint256 tokenId) external whenNotPaused isApprovedOrOwner(tokenId) {
         // Check token exists and is owned by caller or approved
        if (_tokenOwners[tokenId] == address(0)) revert TokenDoesNotExist();
         if (_tokenOwners[tokenId] != msg.sender && getApproved(tokenId) != msg.sender && !isApprovedForAll(_tokenOwners[tokenId], msg.sender)) revert NotApprovedOrOwner();

        // Check token state
        if (_tokenData[tokenId].state != uint256(TokenState.Nourishing)) revert InvalidStateForAction();

        // Check if nourishment period has passed
        if (block.timestamp < _tokenData[tokenId].lastNourishedTimestamp + nourishmentPeriod) revert NotReadyToClaim();

        // Update state
        _updateTokenState(tokenId, TokenState.ReadyToEvolve); // Now ready for evolution

        emit NourishingClaimed(tokenId, block.timestamp);
    }

    /**
     * @notice Applies a catalyst to a token, potentially triggering evolution.
     * Requires payment of the catalyst fee.
     * @param tokenId The ID of the token.
     * @param catalystId The ID of the catalyst type to apply.
     * @param catalystData Optional data specific to the catalyst (e.g., parameters).
     */
    function applyCatalyst(uint256 tokenId, uint256 catalystId, bytes calldata catalystData) external payable whenNotPaused isApprovedOrOwner(tokenId) {
        // Check token exists and is owned by caller or approved
        if (_tokenOwners[tokenId] == address(0)) revert TokenDoesNotExist();
         if (_tokenOwners[tokenId] != msg.sender && getApproved(tokenId) != msg.sender && !isApprovedForAll(_tokenOwners[tokenId], msg.sender)) revert NotApprovedOrOwner();

        // Check catalyst exists and is active
        CatalystConfig storage config = _catalystConfigs[catalystId];
        if (!config.active) revert CatalystNotFound();

        // Check required state for the catalyst
        if (_tokenData[tokenId].state != config.requiredState) revert CatalystConditionNotMet();

        // Check payment
        if (msg.value < config.fee) revert InsufficientPayment();

        // Process catalyst-specific data if needed (example: check data format)
        // require(catalystData.length <= 32, "Invalid catalyst data length"); // Example check

        // Update token data
        _tokenData[tokenId].lastCatalystId = catalystId;
        // Could potentially update a 'catalyst count' or similar trait here

        emit CatalystApplied(tokenId, catalystId, catalystData);

        // Automatically trigger evolution attempt after catalyst
        _performEvolution(tokenId, catalystId, catalystData);

        // Refund excess ETH if any
        if (msg.value > config.fee) {
             (bool success, ) = payable(msg.sender).call{value: msg.value - config.fee}("");
            require(success, "ETH refund failed");
        }
    }

     /**
     * @notice Attempts to evolve a token based on its current state and potentially a recent catalyst.
     * Can be called by anyone for tokens in a 'ReadyToEvolve' state or after a catalyst is applied.
     * Evolution logic is internal.
     * @param tokenId The ID of the token to evolve.
     */
    function evolveToken(uint256 tokenId) external whenNotPaused {
        // Check token exists
         if (_tokenOwners[tokenId] == address(0)) revert TokenDoesNotExist();

        // Check if token is in a state where it can be manually evolved (e.g., ReadyToEvolve)
        if (_tokenData[tokenId].state != uint256(TokenState.ReadyToEvolve)) {
            // Allow evolving after specific catalysts too, if designed that way
            // Example: if (_tokenData[tokenId].state != uint256(TokenState.ReadyToEvolve) && _tokenData[tokenId].lastCatalystId == 0) {
                 revert CannotEvolveInCurrentState();
            // }
        }

        // Perform the internal evolution logic
        // If called after a catalyst, the catalyst logic already happened, this call
        // might just re-trigger the state transition based on the *result* determined by applyCatalyst.
        // Or, if ReadyToEvolve from nourishment, this logic determines the outcome.
        // Let's make _performEvolution handle both cases.
        _performEvolution(tokenId, 0, ""); // Pass catalystId 0 and empty data if not from catalyst
    }

    /**
     * @notice Stakes an evolved Art Form token.
     * Staking might provide passive trait enhancements or unlock abilities.
     * @param tokenId The ID of the token to stake.
     */
    function stakeArtForm(uint256 tokenId) external whenNotPaused isApprovedOrOwner(tokenId) {
         // Check token exists and is owned by caller or approved
        if (_tokenOwners[tokenId] == address(0)) revert TokenDoesNotExist();
         if (_tokenOwners[tokenId] != msg.sender && getApproved(tokenId) != msg.sender && !isApprovedForAll(_tokenOwners[tokenId], msg.sender)) revert NotApprovedOrOwner();

        uint256 currentState = _tokenData[tokenId].state;

        // Check token state is an unstaked Art Form
        if (currentState < uint256(TokenState.FormA) || currentState > uint256(TokenState.FormC)) {
            revert NotArtForm();
        }

        // Check it's not already staked
         if (currentState >= uint256(TokenState.StakedFormA)) revert AlreadyStaked();

        // Update state to staked form
        if (currentState == uint256(TokenState.FormA)) _updateTokenState(tokenId, TokenState.StakedFormA);
        else if (currentState == uint256(TokenState.FormB)) _updateTokenState(tokenId, TokenState.StakedFormB);
        else if (currentState == uint256(TokenState.FormC)) _updateTokenState(tokenId, TokenState.StakedFormC);
        // Add more forms as needed

        _tokenData[tokenId].lastStakedTimestamp = block.timestamp;

        // Apply staking effects to traits
        _applyStakingEffects(tokenId, true);

        emit ArtFormStaked(tokenId, block.timestamp);
    }

    /**
     * @notice Unstakes an Art Form token.
     * Removes passive trait enhancements.
     * @param tokenId The ID of the token to unstake.
     */
    function unstakeArtForm(uint256 tokenId) external whenNotPaused isApprovedOrOwner(tokenId) {
         // Check token exists and is owned by caller or approved
        if (_tokenOwners[tokenId] == address(0)) revert TokenDoesNotExist();
         if (_tokenOwners[tokenId] != msg.sender && getApproved(tokenId) != msg.sender && !isApprovedForAll(_tokenOwners[tokenId], msg.sender)) revert NotApprovedOrOwner();

        uint256 currentState = _tokenData[tokenId].state;

         // Check token state is a staked Art Form
        if (currentState < uint256(TokenState.StakedFormA) || currentState > uint256(TokenState.StakedFormC)) {
            revert NotStaked();
        }

        // Update state back to unstaked form
        if (currentState == uint256(TokenState.StakedFormA)) _updateTokenState(tokenId, TokenState.FormA);
        else if (currentState == uint256(TokenState.StakedFormB)) _updateTokenState(tokenId, TokenState.FormB);
        else if (currentState == uint256(TokenState.StakedFormC)) _updateTokenState(tokenId, TokenState.FormC);
         // Add more forms as needed

        _tokenData[tokenId].lastStakedTimestamp = 0; // Reset stake timestamp

        // Remove staking effects from traits
        _applyStakingEffects(tokenId, false);

        emit ArtFormUnstaked(tokenId, block.timestamp);
    }


    // --- Trait and Data Query Functions ---

    /**
     * @notice Gets the value of a specific trait for a token.
     * @param tokenId The ID of the token.
     * @param traitName The name of the trait.
     * @return The value of the trait (0 if not found).
     */
    function getTrait(uint256 tokenId, string calldata traitName) external view returns (uint256 value) {
        if (_tokenOwners[tokenId] == address(0)) revert TokenDoesNotExist();
        return _tokenData[tokenId].traits[traitName];
    }

    /**
     * @notice Gets the current state of a token.
     * @param tokenId The ID of the token.
     * @return The state as a uint256 (mapping to TokenState enum).
     */
    function getTokenState(uint256 tokenId) external view returns (uint256 state) {
         if (_tokenOwners[tokenId] == address(0)) revert TokenDoesNotExist();
        return _tokenData[tokenId].state;
    }

    /**
     * @notice Gets the generation timestamp of a token.
     * @param tokenId The ID of the token.
     * @return The timestamp.
     */
    function getTokenGenerationTimestamp(uint256 tokenId) external view returns (uint256 timestamp) {
         if (_tokenOwners[tokenId] == address(0)) revert TokenDoesNotExist();
        return _tokenData[tokenId].generationTimestamp;
    }

     /**
     * @notice Gets the base DNA of a token.
     * @param tokenId The ID of the token.
     * @return The DNA hash.
     */
    function getTokenDNA(uint256 tokenId) external view returns (bytes32 dna) {
         if (_tokenOwners[tokenId] == address(0)) revert TokenDoesNotExist();
        return _tokenData[tokenId].dna;
    }

     /**
     * @notice Gets all currently set dynamic traits for a token.
     * Note: Iterating over mappings in Solidity is not direct. This function
     * assumes a predefined list of *possible* trait names or requires storing
     * active trait names separately. This implementation is simplified.
     * A more robust version would store trait names in an array or use a helper contract.
     * @param tokenId The ID of the token.
     * @return Arrays of trait names and values.
     */
    function getTokenTraits(uint256 tokenId) external view returns (string[] memory names, uint256[] memory values) {
         if (_tokenOwners[tokenId] == address(0)) revert TokenDoesNotExist();

        // This requires knowing trait names beforehand or storing them.
        // Example: Return values for a few known traits.
        // If the list of possible traits is dynamic or large, this approach is not suitable.
        // A better approach would be to store trait names in an array alongside the mapping.

        // For demonstration, let's assume a fixed small set of possible traits
        string[] memory possibleTraitNames = new string[](2); // Example: "Power", "Speed"
        possibleTraitNames[0] = "Power";
        possibleTraitNames[1] = "Speed"; // Assuming these are set somewhere during mint/evolution

        uint26 traitsCount = 0;
        for (uint256 i = 0; i < possibleTraitNames.length; i++) {
             // Check if the trait has a non-zero value or was explicitly set
            if (_tokenData[tokenId].traits[possibleTraitNames[i]] > 0) { // Simplified check
                traitsCount++;
            }
        }

        names = new string[](traitsCount);
        values = new uint256[](traitsCount);
        uint256 currentIndex = 0;

         for (uint256 i = 0; i < possibleTraitNames.length; i++) {
             uint256 traitValue = _tokenData[tokenId].traits[possibleTraitNames[i]];
            if (traitValue > 0) { // Simplified check
                names[currentIndex] = possibleTraitNames[i];
                values[currentIndex] = traitValue;
                currentIndex++;
            }
        }

        return (names, values);
    }

    // --- Admin/Configuration Functions ---

    /**
     * @notice Owner sets the base price for minting new seeds.
     * @param price The new mint price in Wei.
     */
    function setBaseMintPrice(uint256 price) external onlyOwner {
        baseMintPrice = price;
        emit BaseMintPriceUpdated(price);
    }

    /**
     * @notice Owner sets the required duration for seed nourishment.
     * @param period The new nourishment period in seconds.
     */
    function setNourishmentPeriod(uint256 period) external onlyOwner {
        nourishmentPeriod = period;
        emit NourishmentPeriodUpdated(period);
    }

     /**
     * @notice Owner defines a new catalyst type or updates an existing one.
     * @param catalystId Unique ID for the catalyst.
     * @param requiredState State the token must be in.
     * @param successState State after successful evolution.
     * @param failState State after failed evolution.
     * @param fee ETH fee to apply.
     */
    function addCatalystType(uint256 catalystId, uint256 requiredState, uint256 successState, uint256 failState, uint256 fee) external onlyOwner {
        // Basic validation on states (should map to enum)
        require(requiredState > uint256(TokenState.NonExistent), "Invalid required state");
        require(successState > uint256(TokenState.NonExistent), "Invalid success state");
        require(failState > uint256(TokenState.NonExistent), "Invalid fail state");

        _catalystConfigs[catalystId] = CatalystConfig(requiredState, successState, failState, fee, true);
        emit CatalystTypeAdded(catalystId, requiredState, successState, failState, fee);
    }

    /**
     * @notice Owner deactivates a catalyst type. Config remains, but cannot be applied.
     * @param catalystId The ID of the catalyst to deactivate.
     */
    function removeCatalystType(uint256 catalystId) external onlyOwner {
        if (!_catalystConfigs[catalystId].active) revert CatalystNotFound(); // Already inactive or doesn't exist

        _catalystConfigs[catalystId].active = false; // Mark as inactive
        emit CatalystTypeRemoved(catalystId);
    }

     /**
     * @notice Owner updates the fee for an existing catalyst type.
     * @param catalystId The ID of the catalyst.
     * @param newFee The new ETH fee.
     */
    function updateCatalystFee(uint256 catalystId, uint256 newFee) external onlyOwner {
        if (!_catalystConfigs[catalystId].active) revert CatalystNotFound(); // Must be an active catalyst

        _catalystConfigs[catalystId].fee = newFee;
        emit CatalystFeeUpdated(catalystId, newFee);
    }


    // --- Internal Helper Functions ---

    /**
     * @notice Internal function to update a token's state.
     * Emits a TraitChanged event for the state trait.
     * @param tokenId The ID of the token.
     * @param newState The new state enum value.
     */
    function _updateTokenState(uint256 tokenId, TokenState newState) internal {
        _tokenData[tokenId].state = uint256(newState);
        // Represent state as a trait for metadata/querying convenience
        _tokenData[tokenId].traits["State"] = uint256(newState);
        emit TraitChanged(tokenId, "State", uint256(newState));
    }

    /**
     * @notice Internal function to update a specific trait.
     * Emits a TraitChanged event.
     * @param tokenId The ID of the token.
     * @param traitName The name of the trait.
     * @param newValue The new value for the trait.
     */
    function _updateTrait(uint256 tokenId, string memory traitName, uint256 newValue) internal {
         _tokenData[tokenId].traits[traitName] = newValue;
        emit TraitChanged(tokenId, traitName, newValue);
    }

    /**
     * @notice Internal function implementing the evolution logic.
     * Determines the outcome of evolution based on current state, catalyst, DNA, and pseudo-randomness.
     * @param tokenId The ID of the token.
     * @param catalystId The catalyst used (0 if none).
     * @param catalystData Data from the catalyst (if any).
     */
    function _performEvolution(uint256 tokenId, uint256 catalystId, bytes calldata catalystData) internal {
        // --- Pseudo-randomness Source ---
        // Using block.timestamp, block.difficulty (or gaslimit on PoS), and token ID as seeds.
        // NOTE: This is WEAK pseudo-randomness and vulnerable to front-running!
        // For truly unpredictable results, use an oracle like Chainlink VRF.
        uint256 entropy = uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.prevrandao, // Use prevrandao on PoS, difficulty on PoW
            tx.gasprice,
            tokenId,
            _tokenData[tokenId].dna,
            catalystId,
            catalystData // Include catalyst data if it influences randomness
        )));

        uint26 currentState = _tokenData[tokenId].state;
        uint26 nextState = currentState; // Default: no change
        bytes32 newDNA = _tokenData[tokenId].dna; // Default: DNA doesn't change

        // --- Evolution Logic ---
        if (currentState == uint256(TokenState.ReadyToEvolve) && catalystId == 0) {
            // Evolution after nourishment, no catalyst
            // 50/50 chance to become FormA or FormB
            if (entropy % 2 == 0) {
                nextState = uint256(TokenState.FormA);
                // Maybe update DNA slightly based on entropy? newDNA = bytes32(uint256(newDNA) ^ (entropy % (2**32)));
                _updateTrait(tokenId, "EvolutionType", 1); // Indicate Nourishment Evolution
            } else {
                nextState = uint256(TokenState.FormB);
                 _updateTrait(tokenId, "EvolutionType", 2); // Indicate Nourishment Evolution
            }
             _updateTrait(tokenId, "NourishmentEvolutions", _tokenData[tokenId].traits["NourishmentEvolutions"] + 1);

        } else if (catalystId != 0) {
            // Evolution triggered by a catalyst
            CatalystConfig storage config = _catalystConfigs[catalystId];
            if (config.active && currentState == config.requiredState) {
                // Determine success/failure based on entropy and potentially token traits or catalyst data
                // Example: Higher 'Power' trait increases success chance
                uint256 successRoll = entropy % 100; // Roll 0-99
                uint256 successThreshold = 50; // Base 50% success

                // Add bonus based on a trait value (example)
                // successThreshold += (_tokenData[tokenId].traits["Luck"] / 10); // Assuming 'Luck' trait

                if (successRoll < successThreshold) {
                    nextState = config.successState;
                    _updateTrait(tokenId, "CatalystSuccesses", _tokenData[tokenId].traits["CatalystSuccesses"] + 1);
                     _updateTrait(tokenId, "LastCatalystOutcome", 1); // Success
                     // Potentially modify DNA based on successful catalyst
                      newDNA = bytes32(uint256(newDNA) ^ (entropy % (2**64))); // Example DNA change
                } else {
                    nextState = config.failState;
                    _updateTrait(tokenId, "CatalystFailures", _tokenData[tokenId].traits["CatalystFailures"] + 1);
                    _updateTrait(tokenId, "LastCatalystOutcome", 0); // Failure
                }
                 _updateTrait(tokenId, "LastCatalystId", catalystId);
            } else {
                 // Catalyst application failed state check, should have reverted earlier,
                 // but good to handle defensively here too.
                revert CatalystConditionNotMet();
            }
        } else {
            // Token is not in a state ready for *this type* of evolution (e.g., trying to evolve a Seed directly)
            revert CannotEvolveInCurrentState();
        }

        // --- Apply Evolution Effects (Traits, DNA) ---
        // This is where the specific effects of transitioning to the nextState occur
        _applyEvolutionEffects(tokenId, uint256(currentState), nextState, newDNA);

        // --- Update State ---
        if (nextState != currentState) {
             _updateTokenState(tokenId, TokenState(nextState));
             _tokenData[tokenId].dna = newDNA; // Update DNA if it changed
             emit TokenEvolved(tokenId, nextState, newDNA);
        }
    }

     /**
     * @notice Internal function to apply changes based on evolution outcome.
     * Updates traits, potentially DNA, etc., based on the state transition.
     * @param tokenId The ID of the token.
     * @param fromState The state before evolution.
     * @param toState The state after evolution.
     * @param newDNA The DNA after evolution (might be same as before).
     */
    function _applyEvolutionEffects(uint256 tokenId, uint256 fromState, uint256 toState, bytes32 newDNA) internal {
        // Logic here modifies traits based on the state transition
        // Example:
        if (fromState < uint26(TokenState.FormA) && toState >= uint26(TokenState.FormA)) {
            // Transitioned from Seed/Ready state to an Art Form
            // Initialize base traits for the new form
            if (toState == uint26(TokenState.FormA)) {
                 _updateTrait(tokenId, "FormType", 1); // Form A
                 _updateTrait(tokenId, "Power", 50);
                 _updateTrait(tokenId, "Speed", 10);
                 _updateTrait(tokenId, "RarityScore", 100); // Base rarity
            } else if (toState == uint26(TokenState.FormB)) {
                 _updateTrait(tokenId, "FormType", 2); // Form B
                 _updateTrait(tokenId, "Power", 10);
                 _updateTrait(tokenId, "Speed", 50);
                 _updateTrait(tokenId, "RarityScore", 120); // Slightly rarer base
            }
            // etc. for FormC, etc.
        }

        // Example: Trait changes based on specific catalyst outcomes
        // if (toState == uint256(TokenState.FormC) && fromState != uint256(TokenState.FormC)) {
        //     // Just evolved into FormC - maybe a rare outcome
        //     _updateTrait(tokenId, "SpecialAbilityUnlocked", 1);
        //     _updateTrait(tokenId, "RarityScore", _tokenData[tokenId].traits["RarityScore"] + 50);
        // }

        // Example: Traits influenced by DNA or history (not just state)
        // uint256 dnaInfluence = uint256(newDNA) % 10;
        // _updateTrait(tokenId, "ColorHue", dnaInfluence * 36); // Map DNA to hue angle 0-360
    }

     /**
     * @notice Internal function to apply or remove trait effects from staking.
     * @param tokenId The ID of the token.
     * @param apply True to apply staking effects, false to remove.
     */
    function _applyStakingEffects(uint256 tokenId, bool apply) internal {
        uint26 currentState = _tokenData[tokenId].state;
        uint256 power = _tokenData[tokenId].traits["Power"];
        uint256 speed = _tokenData[tokenId].traits["Speed"];
        uint256 rarity = _tokenData[tokenId].traits["RarityScore"];

        // Determine the base state traits before staking/unstaking
        uint26 baseState = currentState;
        if (currentState == uint26(TokenState.StakedFormA)) baseState = uint26(TokenState.FormA);
        else if (currentState == uint26(TokenState.StakedFormB)) baseState = uint26(TokenState.FormB);
        else if (currentState == uint26(TokenState.StakedFormC)) baseState = uint26(TokenState.FormC);
        // Add more forms as needed

        // Note: To accurately reverse effects, you might need to store the *base* traits
        // separately or recalculate them from DNA/Form type when unstaking.
        // For simplicity here, we apply a fixed bonus/penalty. A real system would
        // track temporary modifiers.

        if (apply) {
            // Apply staking bonuses
            if (baseState == uint26(TokenState.FormA)) {
                 _updateTrait(tokenId, "Power", power + 10); // Example bonus
                 _updateTrait(tokenId, "RarityScore", rarity + 5); // Slight boost while staked?
            } else if (baseState == uint26(TokenState.FormB)) {
                 _updateTrait(tokenId, "Speed", speed + 10); // Example bonus
            }
             _updateTrait(tokenId, "IsStaked", 1);
        } else {
             // Remove staking bonuses (reverse the logic above)
             if (baseState == uint26(TokenState.FormA)) {
                 _updateTrait(tokenId, "Power", power > 10 ? power - 10 : 0); // Subtract bonus
                 _updateTrait(tokenId, "RarityScore", rarity > 5 ? rarity - 5 : rarity); // Subtract boost
            } else if (baseState == uint26(TokenState.FormB)) {
                 _updateTrait(tokenId, "Speed", speed > 10 ? speed - 10 : 0); // Subtract bonus
            }
             _updateTrait(tokenId, "IsStaked", 0);
        }
    }

    // Helper function to check if caller is owner or approved
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner = _tokenOwners[tokenId];
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    // Helper function to get token state name (off-chain metadata helper)
    // Needs an external mapping or library if needed on-chain
    // function _getStateName(uint256 stateValue) internal pure returns (string memory) {
    //     if (stateValue == uint256(TokenState.Seed)) return "Seed";
    //     if (stateValue == uint256(TokenState.Nourishing)) return "Nourishing";
    //     if (stateValue == uint256(TokenState.ReadyToEvolve)) return "ReadyToEvolve";
    //     if (stateValue == uint256(TokenState.FormA)) return "FormA";
    //     // ... etc.
    //     return "Unknown";
    // }

}
```