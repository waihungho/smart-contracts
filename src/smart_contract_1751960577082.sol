Okay, let's design a smart contract incorporating several advanced, creative, and potentially trendy concepts beyond a basic token or marketplace.

We will build a **Dynamic NFT Marketplace with Trait Evolution and Gamified Mechanics**.

Here's the core idea: NFTs minted by this contract are not static. They have dynamic traits that can change based on owner actions within the contract (staking, mutation/crafting) or potentially external data (simulated via an oracle pattern). The contract also acts as a marketplace for these dynamic NFTs and introduces a secondary token for mutation.

**Concepts Included:**

1.  **Dynamic NFTs:** Traits stored on-chain that can change.
2.  **NFT Staking:** Lock NFTs to accrue rewards or evolve traits over time.
3.  **NFT Mutation/Crafting:** Combine an NFT with other tokens (an ERC20 in this case) to permanently alter its traits.
4.  **On-Chain Trait Logic:** Calculations and state updates for traits happen within the contract.
5.  **Oracle Pattern (Simulated):** A mechanism to allow external data (like game results or environmental factors) to influence traits.
6.  **Marketplace:** Basic buy/sell functionality for these specific dynamic NFTs.
7.  **ERC20 Integration:** Using a separate ERC20 for payment or crafting.
8.  **Fee Mechanism:** Marketplace fees.
9.  **Pausable:** Ability to pause contract operations.
10. **Ownable:** Access control.

---

**Outline and Function Summary:**

**Contract Name:** `DynamicNFTMarketplace`

**Core Functionality:** Manages the minting, trading, staking, and mutation of dynamic NFTs with on-chain evolving traits.

**State Variables:**
*   ERC721 mappings (`_owners`, `_balances`, etc. - implemented custom, not inheriting standard libraries directly for uniqueness)
*   NFT Dynamic Trait data (`DynamicNFTData` struct)
*   NFT Staking data (`StakingData` struct)
*   Marketplace listings (`Listing` struct)
*   Approved payment tokens (mapping address => bool)
*   Mutation token address and cost
*   Marketplace fee percentage
*   Collected fees (ETH and ERC20)
*   Oracle address for trait updates
*   Pausable state
*   Ownership

**Events:**
*   `NFTMinted`
*   `TraitsUpdated`
*   `NFTStaked`
*   `NFTUnstaked`
*   `NFTMutated`
*   `ItemListed`
*   `ItemSold`
*   `ItemDelisted`
*   `PaymentTokenApproved`
*   `PaymentTokenRemoved`
*   `MarketplaceFeeUpdated`
*   `FeesWithdrawn`
*   `Paused`
*   `Unpaused`
*   `OwnershipTransferred`

**Modifiers:**
*   `onlyOwner`
*   `whenNotPaused`
*   `whenPaused`
*   `validTokenId`

**Functions (at least 20 public/external):**

1.  `constructor(string memory name, string memory symbol)`: Initializes the contract with name and symbol, sets owner.
2.  `mintDynamicNFT(address recipient, string memory tokenURI, uint256 initialPower, uint256 initialAffinity)`: Mints a new dynamic NFT with initial traits.
3.  `updateNFTMetadata(uint256 tokenId, string memory newTokenURI)`: Allows owner to update an NFT's metadata URI. (ERC721 standard, but needed)
4.  `getNFTDynamicTraits(uint256 tokenId)`: View function to retrieve the current dynamic traits of an NFT.
5.  `stakeNFT(uint256 tokenId)`: Allows an NFT owner to stake their token, starting trait evolution/accrual.
6.  `unstakeNFT(uint256 tokenId)`: Allows an owner to unstake their token, applying trait evolution based on stake duration and potentially claiming rewards (simplified: trait evolution is the primary reward here).
7.  `mutateNFT(uint256 tokenId)`: Allows an owner to mutate an NFT using the configured mutation token, permanently altering traits. Requires spending the mutation token.
8.  `simulateOracleTraitUpdate(uint256 tokenId, uint256 newAffinity)`: Callable *only by the designated oracle address* to update a specific trait based on external input. (Simulates oracle integration)
9.  `setOracleAddress(address _oracleAddress)`: Owner sets the address allowed to call `simulateOracleTraitUpdate`.
10. `listItemForSale(uint256 tokenId, uint256 price, address paymentToken)`: Owner lists their NFT for sale on the marketplace using ETH (address(0)) or an approved ERC20.
11. `buyItem(uint256 tokenId)`: Allows a buyer to purchase a listed NFT, handling ETH or ERC20 transfer and fees.
12. `delistItem(uint256 tokenId)`: Allows the seller to remove their NFT listing.
13. `getListing(uint256 tokenId)`: View function to get details of a marketplace listing.
14. `setMarketplaceFee(uint16 feePercentage)`: Owner sets the marketplace fee percentage (e.g., 100 = 1%).
15. `withdrawETHFees()`: Owner withdraws collected ETH fees.
16. `withdrawERC20Fees(address tokenAddress)`: Owner withdraws collected ERC20 fees for a specific token.
17. `setApprovedPaymentToken(address token, bool isApproved)`: Owner approves or disapproves an ERC20 token for use in marketplace listings.
18. `setMutationToken(address token, uint256 cost)`: Owner sets the ERC20 token and the amount required for mutation.
19. `getMutationTokenInfo()`: View function to get the mutation token address and cost.
20. `pause()`: Owner pauses marketplace/staking/mutation operations.
21. `unpause()`: Owner unpauses operations.
22. `renounceOwnership()`: Owner renounces ownership (standard, but included).
23. `transferOwnership(address newOwner)`: Owner transfers ownership (standard, but included).
24. `balanceOf(address owner)`: ERC721 standard - returns number of NFTs owned by an address.
25. `ownerOf(uint256 tokenId)`: ERC721 standard - returns owner of a specific token.
26. `transferFrom(address from, address to, uint256 tokenId)`: ERC721 standard - transfers ownership. Includes checks for staking/listing.
27. `safeTransferFrom(address from, address to, uint256 tokenId)`: ERC721 standard - safe transfer. Includes checks.
28. `safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)`: ERC721 standard - safe transfer with data. Includes checks.
29. `approve(address to, uint256 tokenId)`: ERC721 standard - approves one address to transfer a token.
30. `getApproved(uint256 tokenId)`: ERC721 standard - gets the approved address for a token.
31. `setApprovalForAll(address operator, bool approved)`: ERC721 standard - approves or revokes approval for an operator to manage all of sender's tokens.
32. `isApprovedForAll(address owner, address operator)`: ERC721 standard - checks if an operator is approved for an owner.

*(Self-correction: The ERC721 standard functions (24-32) contribute to the count, making it easy to reach >20. The truly *dynamic/marketplace* specific ones are 1-23. This meets the spirit and the letter of the request).*

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Basic IERC20 interface for interacting with payment/mutation tokens
interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
}

/**
 * @title DynamicNFTMarketplace
 * @dev A marketplace for NFTs with dynamic on-chain traits that can evolve
 *      through staking, mutation (crafting with an ERC20), and simulated oracle updates.
 *      Includes basic ERC721 implementation, marketplace, and fee mechanics.
 */
contract DynamicNFTMarketplace {
    // --- Outline and Function Summary ---
    // Core Functionality: Manages the minting, trading, staking, and mutation of dynamic NFTs with on-chain evolving traits.
    // State Variables: Custom ERC721 data, Dynamic Trait data, Staking data, Marketplace listings, approved tokens, fees, oracle, pause, ownership.
    // Events: NFTMinted, TraitsUpdated, NFTStaked, NFTUnstaked, NFTMutated, ItemListed, ItemSold, ItemDelisted, PaymentTokenApproved, PaymentTokenRemoved, MarketplaceFeeUpdated, FeesWithdrawn, Paused, Unpaused, OwnershipTransferred.
    // Modifiers: onlyOwner, whenNotPaused, whenPaused, validTokenId.
    // Public/External Functions (>= 20):
    //   - constructor: Initializes contract.
    //   - mintDynamicNFT: Mints a new NFT with initial traits.
    //   - updateNFTMetadata: Updates NFT metadata URI (owner only).
    //   - getNFTDynamicTraits: Reads dynamic traits.
    //   - stakeNFT: Locks NFT for trait evolution.
    //   - unstakeNFT: Unlocks NFT, applies trait evolution.
    //   - mutateNFT: Alters traits using mutation token.
    //   - simulateOracleTraitUpdate: Updates trait (oracle only).
    //   - setOracleAddress: Sets oracle address (owner only).
    //   - listItemForSale: Lists NFT for sale (ETH or ERC20).
    //   - buyItem: Buys listed NFT.
    //   - delistItem: Removes NFT listing.
    //   - getListing: Reads listing details.
    //   - setMarketplaceFee: Sets marketplace fee (owner only).
    //   - withdrawETHFees: Withdraws ETH fees (owner only).
    //   - withdrawERC20Fees: Withdraws ERC20 fees (owner only).
    //   - setApprovedPaymentToken: Approves/disapproves ERC20 for payment (owner only).
    //   - setMutationToken: Sets mutation token and cost (owner only).
    //   - getMutationTokenInfo: Reads mutation token info.
    //   - pause: Pauses operations (owner only).
    //   - unpause: Unpauses operations (owner only).
    //   - renounceOwnership: Renounces ownership (standard).
    //   - transferOwnership: Transfers ownership (standard).
    //   - balanceOf: ERC721 standard - token count.
    //   - ownerOf: ERC721 standard - token owner.
    //   - transferFrom: ERC721 standard - transfers ownership.
    //   - safeTransferFrom (x2 overloads): ERC721 standard - safe transfers.
    //   - approve: ERC721 standard - approves one address.
    //   - getApproved: ERC721 standard - gets approved address.
    //   - setApprovalForAll: ERC721 standard - approves operator.
    //   - isApprovedForAll: ERC721 standard - checks operator approval.
    // --- End Outline and Summary ---

    // --- State Variables ---

    // Custom ERC721 Implementation (simplified, not inheriting standard libraries)
    mapping(uint255 => address) private _owners;
    mapping(address => uint255) private _balances;
    mapping(uint255 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    string public name;
    string public symbol;
    uint256 private _nextTokenId;

    // Dynamic NFT Data
    struct DynamicNFTData {
        string tokenURI;
        uint256 level; // Evolves with staking time
        uint256 power; // Evolves with mutation
        uint256 affinity; // Can be affected by oracle (simulated)
        uint256 lastUpdateTime; // Timestamp for trait calculations
    }
    mapping(uint256 => DynamicNFTData) private _dynamicNFTs;

    // Staking Data
    struct StakingData {
        bool isStaked;
        uint256 stakeStartTime;
    }
    mapping(uint256 => StakingData) private _stakingData;

    // Marketplace Data
    struct Listing {
        bool isListed;
        address seller;
        uint256 price; // Price in ETH (if paymentToken is address(0)) or ERC20 amount
        address paymentToken; // address(0) for ETH
    }
    mapping(uint256 => Listing) private _listings;

    address[] public listedTokenIds; // Simple array to track listed IDs (for read convenience, basic)

    // Payment Tokens
    mapping(address => bool) public approvedPaymentTokens;

    // Mutation Token
    address public mutationToken;
    uint256 public mutationTokenCost;

    // Marketplace Fees
    uint16 public marketplaceFeePercentage; // Stored as basis points, e.g., 100 for 1%
    uint256 public collectedETHFees;
    mapping(address => uint256) public collectedERC20Fees;

    // Oracle Address (for simulated external updates)
    address public oracleAddress;

    // Pausable State
    bool public paused;

    // Ownership
    address private _owner;

    // --- Events ---

    event NFTMinted(address indexed recipient, uint256 indexed tokenId, string tokenURI);
    event TraitsUpdated(uint256 indexed tokenId, uint256 level, uint256 power, uint256 affinity);
    event NFTStaked(uint256 indexed tokenId, address indexed owner);
    event NFTUnstaked(uint256 indexed tokenId, address indexed owner, uint256 durationStaked);
    event NFTMutated(uint256 indexed tokenId, address indexed owner, uint256 newPower);
    event ItemListed(uint256 indexed tokenId, address indexed seller, uint256 price, address paymentToken);
    event ItemSold(uint256 indexed tokenId, address indexed buyer, address indexed seller, uint256 price, address paymentToken);
    event ItemDelisted(uint256 indexed tokenId, address indexed seller);
    event PaymentTokenApproved(address indexed token, bool isApproved);
    event MarketplaceFeeUpdated(uint16 feePercentage);
    event FeesWithdrawn(address indexed recipient, uint256 amount, address indexed token);
    event Paused(address account);
    event Unpaused(address account);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == _owner, "Only owner can call this function");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "Contract is not paused");
        _;
    }

    modifier validTokenId(uint256 tokenId) {
        require(_exists(tokenId), "Invalid token ID");
        _;
    }

    // --- Constructor ---

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
        _owner = msg.sender; // Set initial owner
        paused = false; // Not paused initially
        marketplaceFeePercentage = 0; // No fees initially
        _nextTokenId = 1; // Start token IDs from 1
        oracleAddress = address(0); // No oracle initially
    }

    // --- ERC721 Core Implementation (Custom, simplified) ---

    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "Balance query for null address");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "Owner query for nonexistent token");
        return owner;
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Transfer caller not owner nor approved");
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable {
        require(_isApprovedOrOwner(msg.sender, tokenId), "SafeTransfer caller not owner nor approved");
        _safeTransfer(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public payable {
        require(_isApprovedOrOwner(msg.sender, tokenId), "SafeTransfer caller not owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    function approve(address to, uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender), "Approve caller not owner nor approved for all");
        _approve(to, tokenId);
    }

    function getApproved(uint255 tokenId) public view returns (address) {
        require(_exists(tokenId), "Approved query for nonexistent token");
        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public {
        require(operator != msg.sender, "Approve for all to yourself");
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved); // Need ERC721 events
    }

    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    // Internal ERC721 Helpers
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function _transfer(address from, address to, uint256 tokenId) internal {
        require(ownerOf(tokenId) == from, "Transfer from incorrect owner");
        require(to != address(0), "Transfer to the zero address");

        // Check if staked or listed - disallow transfer if true
        require(!_stakingData[tokenId].isStaked, "Cannot transfer staked token");
        require(!_listings[tokenId].isListed, "Cannot transfer listed token");

        _beforeTokenTransfer(from, to, tokenId);

        _balances[from]--;
        _owners[tokenId] = to;
        _balances[to]++;

        _approve(address(0), tokenId); // Clear approval for the old owner

        _afterTokenTransfer(from, to, tokenId);
    }

    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721Receiver: transfer refused");
    }

     function _approve(address to, uint256 tokenId) internal {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId); // Need ERC721 events
    }

    // Hooks that can be overridden (empty default implementation)
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual {}
    function _afterTokenTransfer(address from, address to, uint256 tokenId) internal virtual {}

    // ERC721Receiver check helper
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory data) private returns (bool) {
        if (to.code.length == 0) { // Not a contract
            return true;
        }
        // Call onERC721Received function on the recipient contract
        try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (bytes4 retval) {
            return retval == IERC721Receiver.onERC721Received.selector;
        } catch (bytes memory reason) {
             if (reason.length == 0) {
                revert("ERC721Receiver: transfer to non ERC721Receiver implementer");
            } else {
                /// @solidity exclusive
                revert(string(reason));
            }
        }
    }

    // ERC721 standard interfaces (Need to include the events and the receiver interface)
    // This would typically be handled by inheriting from standard libraries, but we are implementing manually.
    // Define missing events:
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool indexed approved);

    // Define IERC165 (supportsInterface) and IERC721Receiver for compliance
    function supportsInterface(bytes4 interfaceId) public view returns (bool) {
        // ERC721 Interface ID: 0x80ac58cd
        // ERC165 Interface ID: 0x01ffc9a7
        return interfaceId == 0x80ac58cd || interfaceId == 0x01ffc9a7;
    }

    // Define the ERC721Receiver interface expected by safeTransferFrom
    interface IERC721Receiver {
        function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
    }

    // --- Dynamic NFT & Gamified Functions ---

    /**
     * @dev Mints a new dynamic NFT and assigns initial traits.
     * @param recipient The address to mint the NFT to.
     * @param tokenURI The URI pointing to the NFT's metadata.
     * @param initialPower Initial 'power' trait value.
     * @param initialAffinity Initial 'affinity' trait value.
     */
    function mintDynamicNFT(address recipient, string memory tokenURI, uint256 initialPower, uint256 initialAffinity)
        external
        onlyOwner // Only contract owner can mint
        whenNotPaused
    {
        require(recipient != address(0), "Mint to zero address");
        uint256 newTokenId = _nextTokenId;
        _nextTokenId++;

        _owners[newTokenId] = recipient;
        _balances[recipient]++;

        _dynamicNFTs[newTokenId] = DynamicNFTData({
            tokenURI: tokenURI,
            level: 1, // Start at level 1
            power: initialPower,
            affinity: initialAffinity,
            lastUpdateTime: block.timestamp // Record mint time for staking calc
        });

        _stakingData[newTokenId] = StakingData({
            isStaked: false,
            stakeStartTime: 0
        });

        emit Transfer(address(0), recipient, newTokenId); // ERC721 Transfer event
        emit NFTMinted(recipient, newTokenId, tokenURI);
        emit TraitsUpdated(newTokenId, 1, initialPower, initialAffinity);
    }

    /**
     * @dev Allows owner to update the metadata URI for an NFT.
     * @param tokenId The ID of the token to update.
     * @param newTokenURI The new metadata URI.
     */
    function updateNFTMetadata(uint256 tokenId, string memory newTokenURI)
        external
        onlyOwner // Only contract owner can update URI
        validTokenId(tokenId)
    {
        _dynamicNFTs[tokenId].tokenURI = newTokenURI;
        // Note: ERC721 metadata updates don't typically have a standard event,
        // but we could emit a generic update event if needed.
    }

    /**
     * @dev Gets the current dynamic traits of an NFT.
     * @param tokenId The ID of the token.
     * @return The DynamicNFTData struct.
     */
    function getNFTDynamicTraits(uint256 tokenId)
        public
        view
        validTokenId(tokenId)
        returns (DynamicNFTData memory)
    {
        return _dynamicNFTs[tokenId];
    }

    /**
     * @dev Allows an NFT owner to stake their token. Cannot be listed or already staked.
     * Traits will evolve based on staking duration.
     * @param tokenId The ID of the token to stake.
     */
    function stakeNFT(uint256 tokenId)
        external
        whenNotPaused
        validTokenId(tokenId)
    {
        require(ownerOf(tokenId) == msg.sender, "Only owner can stake");
        require(!_stakingData[tokenId].isStaked, "Token is already staked");
        require(!_listings[tokenId].isListed, "Cannot stake a listed token");

        _stakingData[tokenId].isStaked = true;
        _stakingData[tokenId].stakeStartTime = block.timestamp;
        _dynamicNFTs[tokenId].lastUpdateTime = block.timestamp; // Reset time for trait calc

        emit NFTStaked(tokenId, msg.sender);
    }

    /**
     * @dev Allows an owner to unstake their token. Applies trait evolution based on stake duration.
     * @param tokenId The ID of the token to unstake.
     */
    function unstakeNFT(uint256 tokenId)
        external
        whenNotPaused
        validTokenId(tokenId)
    {
        require(ownerOf(tokenId) == msg.sender, "Only owner can unstake");
        require(_stakingData[tokenId].isStaked, "Token is not staked");

        uint256 durationStaked = block.timestamp - _stakingData[tokenId].stakeStartTime;

        // Apply trait evolution based on duration
        _applyStakingEvolution(tokenId, durationStaked);

        _stakingData[tokenId].isStaked = false;
        _stakingData[tokenId].stakeStartTime = 0; // Reset staking data

        emit NFTUnstaked(tokenId, msg.sender, durationStaked);
        emit TraitsUpdated(tokenId, _dynamicNFTs[tokenId].level, _dynamicNFTs[tokenId].power, _dynamicNFTs[tokenId].affinity);
    }

    /**
     * @dev Applies staking-based trait evolution. Called internally upon unstaking.
     * Simplified: increases level based on time. Could add more complex logic.
     * @param tokenId The ID of the token.
     * @param durationStaked The duration the token was staked in seconds.
     */
    function _applyStakingEvolution(uint256 tokenId, uint256 durationStaked) internal {
        uint256 secondsPerLevel = 86400; // 1 day per level for example
        uint256 levelsGained = durationStaked / secondsPerLevel;

        _dynamicNFTs[tokenId].level += levelsGained;
        _dynamicNFTs[tokenId].lastUpdateTime = block.timestamp; // Update time
    }

    /**
     * @dev Allows an owner to mutate an NFT using the configured mutation token.
     * Permanently alters traits (e.g., increases power).
     * Requires the owner to have approved the contract to spend the mutation token.
     * @param tokenId The ID of the token to mutate.
     */
    function mutateNFT(uint256 tokenId)
        external
        whenNotPaused
        validTokenId(tokenId)
    {
        require(ownerOf(tokenId) == msg.sender, "Only owner can mutate");
        require(mutationToken != address(0), "Mutation token not set");
        require(mutationTokenCost > 0, "Mutation cost not set");

        IERC20 mutationTokenContract = IERC20(mutationToken);
        require(mutationTokenContract.transferFrom(msg.sender, address(this), mutationTokenCost), "Mutation token transfer failed");

        // Apply mutation effect (example: increase power)
        _dynamicNFTs[tokenId].power += 5; // Example: increase power by 5
        _dynamicNFTs[tokenId].lastUpdateTime = block.timestamp; // Update time

        emit NFTMutated(tokenId, msg.sender, _dynamicNFTs[tokenId].power);
        emit TraitsUpdated(tokenId, _dynamicNFTs[tokenId].level, _dynamicNFTs[tokenId].power, _dynamicNFTs[tokenId].affinity);
    }

    /**
     * @dev Allows the designated oracle address to update a specific trait (e.g., affinity).
     * Simulates external data influencing the NFT.
     * @param tokenId The ID of the token to update.
     * @param newAffinity The new affinity value from the oracle.
     */
    function simulateOracleTraitUpdate(uint256 tokenId, uint256 newAffinity)
        external
        validTokenId(tokenId)
    {
        require(msg.sender == oracleAddress, "Only designated oracle can update traits");

        _dynamicNFTs[tokenId].affinity = newAffinity;
        _dynamicNFTs[tokenId].lastUpdateTime = block.timestamp; // Update time

        emit TraitsUpdated(tokenId, _dynamicNFTs[tokenId].level, _dynamicNFTs[tokenId].power, _dynamicNFTs[tokenId].affinity);
    }

    /**
     * @dev Owner sets the address allowed to call `simulateOracleTraitUpdate`.
     * @param _oracleAddress The address of the oracle contract or account.
     */
    function setOracleAddress(address _oracleAddress) external onlyOwner {
        oracleAddress = _oracleAddress;
        // Optional: Emit event for oracle address update
    }

    // --- Marketplace Functions ---

    /**
     * @dev Allows an owner to list their NFT for sale. Cannot list if staked or already listed.
     * Price can be in native ETH (paymentToken = address(0)) or an approved ERC20.
     * @param tokenId The ID of the token to list.
     * @param price The sale price.
     * @param paymentToken The address of the token to accept (address(0) for ETH).
     */
    function listItemForSale(uint256 tokenId, uint256 price, address paymentToken)
        external
        whenNotPaused
        validTokenId(tokenId)
    {
        require(ownerOf(tokenId) == msg.sender, "Only owner can list");
        require(!_stakingData[tokenId].isStaked, "Cannot list a staked token");
        require(!_listings[tokenId].isListed, "Token is already listed");
        require(price > 0, "Price must be greater than 0");

        if (paymentToken != address(0)) {
            require(approvedPaymentTokens[paymentToken], "Payment token not approved");
        }

        _listings[tokenId] = Listing({
            isListed: true,
            seller: msg.sender,
            price: price,
            paymentToken: paymentToken
        });

        // Add to the listedTokenIds array (basic implementation, can be optimized)
        listedTokenIds.push(tokenId);

        // Clear any prior approvals when listing
        _approve(address(0), tokenId);

        emit ItemListed(tokenId, msg.sender, price, paymentToken);
    }

    /**
     * @dev Allows a buyer to purchase a listed NFT.
     * Handles ETH or ERC20 payment and fee distribution.
     * @param tokenId The ID of the token to buy.
     */
    function buyItem(uint256 tokenId) external payable whenNotPaused validTokenId(tokenId) {
        Listing storage listing = _listings[tokenId];
        require(listing.isListed, "Token not listed for sale");
        require(listing.seller != address(0), "Listing seller invalid"); // Should be set if listed
        require(listing.seller != msg.sender, "Cannot buy your own item");

        address buyer = msg.sender;
        address seller = listing.seller;
        uint256 price = listing.price;
        address paymentToken = listing.paymentToken;
        uint16 feeBasisPoints = marketplaceFeePercentage; // 100 = 1%
        uint256 feeAmount = (price * feeBasisPoints) / 10000;
        uint256 amountToSeller = price - feeAmount;

        // Handle payment
        if (paymentToken == address(0)) { // ETH payment
            require(msg.value == price, "Incorrect ETH amount sent");
            require(seller.send(amountToSeller), "ETH transfer to seller failed"); // Use send for simplicity, handle false
            if (feeAmount > 0) {
                collectedETHFees += feeAmount; // Collect fee in the contract
            }
        } else { // ERC20 payment
            require(msg.value == 0, "Cannot send ETH with ERC20 payment");
            IERC20 paymentTokenContract = IERC20(paymentToken);
            require(paymentTokenContract.transferFrom(buyer, seller, amountToSeller), "ERC20 transfer to seller failed");
             if (feeAmount > 0) {
                // Transfer fee to contract or accumulate if direct transfer fails
                 require(paymentTokenContract.transferFrom(buyer, address(this), feeAmount), "ERC20 fee transfer failed");
                 collectedERC20Fees[paymentToken] += feeAmount; // Accumulate collected fees
            }
        }

        // Transfer NFT to buyer
        _transfer(seller, buyer, tokenId); // This also clears approval

        // Clear listing data
        delete _listings[tokenId];
        // Remove from listedTokenIds array (simple O(n) removal)
        for (uint i = 0; i < listedTokenIds.length; i++) {
            if (listedTokenIds[i] == tokenId) {
                listedTokenIds[i] = listedTokenIds[listedTokenIds.length - 1];
                listedTokenIds.pop();
                break;
            }
        }

        emit ItemSold(tokenId, buyer, seller, price, paymentToken);
    }

    /**
     * @dev Allows the seller of a listed item to delist it.
     * @param tokenId The ID of the token to delist.
     */
    function delistItem(uint256 tokenId)
        external
        whenNotPaused
        validTokenId(tokenId)
    {
        Listing storage listing = _listings[tokenId];
        require(listing.isListed, "Token is not listed");
        require(listing.seller == msg.sender, "Only the seller can delist");

        address seller = listing.seller;

        // Clear listing data
        delete _listings[tokenId];
         // Remove from listedTokenIds array (simple O(n) removal)
        for (uint i = 0; i < listedTokenIds.length; i++) {
            if (listedTokenIds[i] == tokenId) {
                listedTokenIds[i] = listedTokenIds[listedTokenIds.length - 1];
                listedTokenIds.pop();
                break;
            }
        }

        emit ItemDelisted(tokenId, seller);
    }

    /**
     * @dev Gets the listing details for a given token ID.
     * @param tokenId The ID of the token.
     * @return The Listing struct.
     */
    function getListing(uint256 tokenId) public view returns (Listing memory) {
         // Does not require validTokenId modifier here as it should return empty struct for non-existent or unlisted tokens
        return _listings[tokenId];
    }

    // --- Fee Management ---

    /**
     * @dev Owner sets the marketplace fee percentage.
     * @param feePercentage The fee percentage in basis points (e.g., 100 = 1%). Max 10000 (100%).
     */
    function setMarketplaceFee(uint16 feePercentage) external onlyOwner {
        require(feePercentage <= 10000, "Fee percentage cannot exceed 100%");
        marketplaceFeePercentage = feePercentage;
        emit MarketplaceFeeUpdated(feePercentage);
    }

    /**
     * @dev Owner withdraws accumulated ETH fees.
     */
    function withdrawETHFees() external onlyOwner {
        uint256 amount = collectedETHFees;
        require(amount > 0, "No ETH fees to withdraw");
        collectedETHFees = 0;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "ETH withdrawal failed");
        emit FeesWithdrawn(msg.sender, amount, address(0));
    }

    /**
     * @dev Owner withdraws accumulated ERC20 fees for a specific token.
     * @param tokenAddress The address of the ERC20 token.
     */
    function withdrawERC20Fees(address tokenAddress) external onlyOwner {
        require(tokenAddress != address(0), "Invalid token address");
        uint256 amount = collectedERC20Fees[tokenAddress];
        require(amount > 0, "No fees to withdraw for this token");
        collectedERC20Fees[tokenAddress] = 0;
        IERC20 tokenContract = IERC20(tokenAddress);
        require(tokenContract.transfer(msg.sender, amount), "ERC20 withdrawal failed");
        emit FeesWithdrawn(msg.sender, amount, tokenAddress);
    }

    // --- Token Configuration ---

    /**
     * @dev Owner approves or disapproves an ERC20 token for use in marketplace listings.
     * ETH is always allowed (represented by address(0)).
     * @param token The address of the ERC20 token.
     * @param isApproved Whether the token is approved or not.
     */
    function setApprovedPaymentToken(address token, bool isApproved) external onlyOwner {
        require(token != address(0), "Cannot approve zero address as payment token");
        approvedPaymentTokens[token] = isApproved;
        emit PaymentTokenApproved(token, isApproved);
    }

     /**
     * @dev Owner sets the ERC20 token and the amount required for the `mutateNFT` function.
     * Setting token to address(0) disables mutation.
     * @param token The address of the ERC20 token.
     * @param cost The amount of the token required for mutation.
     */
    function setMutationToken(address token, uint256 cost) external onlyOwner {
        mutationToken = token;
        mutationTokenCost = cost;
        // Optional: Emit event for mutation token update
    }

    /**
     * @dev Gets the configured mutation token and cost.
     * @return The address of the mutation token and the required cost.
     */
    function getMutationTokenInfo() public view returns (address, uint256) {
        return (mutationToken, mutationTokenCost);
    }

    // --- Pause Functionality ---

    /**
     * @dev Pauses the contract. Prevents most state-changing operations.
     * Only callable by the owner.
     */
    function pause() external onlyOwner whenNotPaused {
        paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Unpauses the contract. Allows state-changing operations again.
     * Only callable by the owner.
     */
    function unpause() external onlyOwner whenPaused {
        paused = false;
        emit Unpaused(msg.sender);
    }

    // --- Ownership Management (Simplified Ownable) ---

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can be used to renounce security and pass
     * control to zero address.
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() external onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    // --- View Functions & Helpers ---

    // Public mapping accessor for convenience
    function getDynamicNFTData(uint256 tokenId) public view returns (string memory tokenURI, uint256 level, uint256 power, uint256 affinity, uint256 lastUpdateTime) {
         require(_exists(tokenId), "Invalid token ID");
         DynamicNFTData storage data = _dynamicNFTs[tokenId];
         return (data.tokenURI, data.level, data.power, data.affinity, data.lastUpdateTime);
    }

    function getStakingData(uint256 tokenId) public view returns (bool isStaked, uint256 stakeStartTime) {
        require(_exists(tokenId), "Invalid token ID");
        StakingData storage data = _stakingData[tokenId];
        return (data.isStaked, data.stakeStartTime);
    }

     // Override tokenURI function to provide the current URI
    function tokenURI(uint256 tokenId) public view returns (string memory) {
         require(_exists(tokenId), "Nonexistent token");
        return _dynamicNFTs[tokenId].tokenURI;
    }
}
```

**Explanation of Advanced/Creative/Trendy Aspects:**

1.  **Dynamic Traits (On-Chain):** Instead of just a static `tokenURI` pointing to off-chain metadata, key traits (`level`, `power`, `affinity`) are stored directly in contract storage (`_dynamicNFTs` mapping). This allows the contract logic itself to modify these properties.
2.  **NFT Staking for Evolution:** The `stakeNFT` and `unstakeNFT` functions implement a simple staking mechanism. The duration an NFT is staked directly influences its `level` trait upon unstaking (`_applyStakingEvolution`). This adds an idle-game or yield-farming like mechanic directly tied to the NFT's properties.
3.  **NFT Mutation (Crafting):** The `mutateNFT` function introduces a "crafting" or "mutation" concept. To increase a trait like `power`, the user must spend a specific ERC20 token (`mutationToken`). This creates utility for a secondary token and introduces a burning or spending mechanism within the NFT ecosystem.
4.  **Simulated Oracle Integration:** `simulateOracleTraitUpdate` and `setOracleAddress` provide a *pattern* for how external, real-world (or game-world) data could influence NFT traits (`affinity`). While this example uses a trusted `oracleAddress`, in a real-world advanced scenario, this would involve integrating with decentralized oracle networks (like Chainlink).
5.  **Custom ERC721 Implementation:** While drawing heavily from the ERC721 standard, the core mappings (`_owners`, `_balances`, etc.) are implemented directly, and the `_transfer` function is modified to include checks for the contract's internal state (staked, listed). This deviates from simply inheriting OpenZeppelin's standard library, fulfilling the "don't duplicate open source" spirit by integrating core logic *within* the standard behavior.
6.  **Integrated Marketplace:** The contract isn't just an NFT; it's also a marketplace *for its own NFTs*. This creates a self-contained ecosystem where trading, staking, and mutation all happen within a single contract context.
7.  **Flexible Payment & Fees:** The marketplace supports both native ETH and approved ERC20 tokens for purchases, and includes a fee mechanism for the owner, with separate withdrawal functions.

This contract combines elements from gaming, DeFi (staking-like accrual), token utility (mutation token), and dynamic state management, offering a richer interaction model than a standard static NFT. It includes well over the requested 20 functions, covering minting, managing, dynamic mechanics, marketplace operations, configuration, and standard ERC721 compliance.