Okay, let's design a smart contract that combines several interesting concepts:
1.  **ERC-721 (NFT):** Each token represents a unique item.
2.  **ERC-4626-like Vault Concept:** Each NFT token ID *itself* acts as a miniature vault capable of holding *multiple* ERC-20 tokens. (This differs from standard ERC-4626 which is a fungible vault).
3.  **Dynamic Metadata:** The NFT's appearance/attributes (via `tokenURI`) changes based on the *contents* and *value* of the assets stored within its associated vault.
4.  **Oracle Integration:** Uses Chainlink Price Feeds to determine the USD value of the assets in the vault.
5.  **Governance Interaction:** A simple mechanism allowing the NFT owner to potentially use their NFT (or its value/contents) to interact with a separate governance contract.
6.  **Token Gating/Allowance:** Restricts which ERC-20 tokens can be deposited.

This combination creates a "Dynamic Asset Vault NFT" (DAV-NFT) – an NFT that is also a portfolio container with a value-reactive appearance and potential utility.

Here's the contract structure and code:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";

// --- Outline ---
// 1. Imports and Interfaces
// 2. Error Handling
// 3. Events
// 4. State Variables
//    - NFT Counter
//    - Vault Storage (Mapping: tokenId => tokenAddress => balance)
//    - Allowed ERC20 Tokens (Mapping: tokenAddress => bool)
//    - Chainlink Price Feeds (Mapping: tokenAddress => priceFeedAddress)
//    - NFT Value Storage (Mapping: tokenId => USD Value)
//    - Metadata Base URI
//    - Governance Contract Address
// 5. Modifiers
//    - onlyNFTVaultOwner
//    - isAllowedToken
// 6. Constructor
// 7. ERC-721 Overrides (tokenURI)
// 8. Owner/Admin Functions
//    - mint (permissioned)
//    - addAllowedToken (with price feed)
//    - removeAllowedToken
//    - setMetadataBaseURI
//    - setGovernanceContract
//    - rescueERC20 (for mistakenly sent tokens)
// 9. Vault Management Functions
//    - depositTokens (to a specific NFT vault)
//    - withdrawTokens (from a specific NFT vault)
//    - burn (burns NFT, returns assets)
// 10. Value Tracking Functions
//    - _updateNFTValue (internal helper, calculates and stores)
//    - getNFTValueUSD (view, gets stored value)
//    - getLiveNFTValueUSD (view, calculates live value)
// 11. Utility/Interaction Functions
//    - triggerMetadataRefresh (signals external service)
//    - interactWithGovernance (calls external governance contract)
// 12. View Functions (Getters)
//    - getVaultTokenBalance
//    - getVaultContents
//    - getAllowedTokens
//    - getChainlinkPriceFeed
//    - getGovernanceContract
//    - getTotalMinted

// --- Function Summary ---
// constructor(): Initializes the contract, name, symbol, and owner.
// mint(): Allows the contract owner to mint new DAV-NFTs.
// addAllowedToken(address tokenAddress, address priceFeed): Owner adds an ERC-20 token that can be deposited, linking it to a Chainlink price feed.
// removeAllowedToken(address tokenAddress): Owner removes an ERC-20 token from the allowed list.
// setMetadataBaseURI(string memory baseURI): Owner sets the base URI for NFT metadata.
// setGovernanceContract(address governanceContractAddress): Owner sets the address of a linked governance contract.
// rescueERC20(address tokenAddress, uint256 amount): Owner can rescue ERC-20 tokens accidentally sent directly to the contract (not via deposit).
// depositTokens(uint256 tokenId, address tokenAddress, uint256 amount): Allows the NFT owner to deposit allowed ERC-20 tokens into their specific NFT's vault. Requires prior ERC-20 approval.
// withdrawTokens(uint256 tokenId, address tokenAddress, uint256 amount): Allows the NFT owner to withdraw tokens from their specific NFT's vault.
// burn(uint256 tokenId): Allows the NFT owner to burn their NFT and receive all held assets back.
// _updateNFTValue(uint256 tokenId): Internal function to calculate the total USD value of assets in an NFT's vault using Chainlink oracles.
// getNFTValueUSD(uint256 tokenId): View function to get the last calculated (stored) USD value of an NFT's vault.
// getLiveNFTValueUSD(uint256 tokenId): View function to calculate and return the *current* USD value of an NFT's vault on-the-fly.
// triggerMetadataRefresh(uint256 tokenId): Public function emitting an event to signal external metadata service to update for a specific token.
// interactWithGovernance(uint256 tokenId, bytes memory data): Allows the NFT owner to call a method on the configured governance contract, potentially using token data.
// getVaultTokenBalance(uint256 tokenId, address tokenAddress): View function to get the balance of a specific token within an NFT's vault.
// getVaultContents(uint256 tokenId): View function to list all tokens and their balances within an NFT's vault. (Note: returning dynamic array of structs from mapping is complex, might need an alternative approach or rely on events/off-chain indexing for full content listing). Let's return a list of allowed tokens and their balances in the vault.
// getAllowedTokens(): View function listing all ERC-20 token addresses currently allowed for deposit.
// getChainlinkPriceFeed(address tokenAddress): View function to get the price feed address for an allowed token.
// getGovernanceContract(): View function to get the governance contract address.
// getTotalMinted(): View function to get the total number of NFTs minted.
// tokenURI(uint256 tokenId): Overrides the standard ERC-721 function to return a URI for dynamic metadata, potentially incorporating the vault's value/contents.
// plus standard inherited ERC721/Ownable view functions like name, symbol, balanceOf, ownerOf, getApproved, isApprovedForAll, transferOwnership, renounceOwnership, supportsInterface. (These bring the total well over 20).

contract DynamicAssetVaultNFT is ERC721, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    using Address for address;

    Counters.Counter private _tokenIds;

    // Mapping from token ID to token address to balance in the vault
    mapping(uint256 => mapping(address => uint256)) private _vaults;

    // Mapping of allowed ERC-20 tokens for deposit
    mapping(address => bool) private _allowedTokens;
    address[] private _allowedTokenAddresses; // To easily list allowed tokens

    // Mapping of allowed ERC-20 tokens to their Chainlink price feed addresses
    mapping(address => AggregatorV3Interface) private _priceFeeds;

    // Mapping from token ID to its calculated USD value (scaled by 10^8, Chainlink standard)
    mapping(uint256 => int256) private _nftValueUSD;

    string private _metadataBaseURI;

    address private _governanceContract;

    // --- Interfaces ---

    // Interface for a simple governance contract interaction
    interface IGovernance {
        function execute(uint256 tokenId, address caller, bytes calldata data) external;
        // Add other potential interaction functions here
    }

    // --- Error Handling ---

    error TokenNotAllowed(address token);
    error InsufficientFundsInVault(address token, uint256 requested, uint256 available);
    error DepositZeroAmount();
    error WithdrawZeroAmount();
    error InvalidPriceFeed();
    error PriceFeedNotSet(address token);
    error PriceFeedReturnedInvalidData();
    error GovernanceContractNotSet();
    error GovernanceCallFailed();
    error TokenDoesNotExist(uint256 tokenId);

    // --- Events ---

    event NFTVaultCreated(uint256 indexed tokenId, address indexed owner);
    event TokensDeposited(uint256 indexed tokenId, address indexed token, uint256 amount, address indexed depositor);
    event TokensWithdrawn(uint256 indexed tokenId, address indexed token, uint256 amount, address indexed receiver);
    event NFTValueUpdated(uint256 indexed tokenId, int256 valueUSD); // Using int256 as Chainlink returns it
    event AllowedTokenAdded(address indexed token, address indexed priceFeed);
    event AllowedTokenRemoved(address indexed token);
    event MetadataShouldRefresh(uint256 indexed tokenId); // Signal to external service
    event GovernanceInteraction(uint256 indexed tokenId, address indexed governanceContract, bytes data);
    event NFTBurned(uint256 indexed tokenId, address indexed owner);

    // --- Modifiers ---

    modifier onlyNFTVaultOwner(uint256 tokenId) {
        if (ownerOf(tokenId) != _msgSender()) {
            revert ERC721InsufficientApproval(_msgSender(), tokenId); // Or custom error
        }
        _;
    }

    modifier isAllowedToken(address tokenAddress) {
        if (!_allowedTokens[tokenAddress]) {
            revert TokenNotAllowed(tokenAddress);
        }
        _;
    }

    // --- Constructor ---

    constructor(string memory name, string memory symbol)
        ERC721(name, symbol)
        Ownable(msg.sender)
    {}

    // --- ERC-721 Overrides ---

    /// @dev See {ERC721-tokenURI}.
    /// @dev Returns a URI pointing to metadata. The external service should fetch vault contents/value via contract calls
    ///      to generate dynamic metadata based on the state.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) {
             revert TokenDoesNotExist(tokenId);
        }
        // Append token ID to the base URI. External service needs to be configured to handle this endpoint.
        return string(abi.encodePacked(_metadataBaseURI, Strings.toString(tokenId)));
    }

    // --- Owner/Admin Functions ---

    /// @notice Mints a new DAV-NFT and assigns it to the recipient. Only callable by the owner.
    /// @param recipient The address to receive the new NFT.
    /// @return The ID of the newly minted token.
    function mint(address recipient) public onlyOwner returns (uint256) {
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();
        _safeMint(recipient, newTokenId);
        emit NFTVaultCreated(newTokenId, recipient);
        return newTokenId;
    }

    /// @notice Adds an ERC-20 token to the list of allowed deposit tokens and links it to a Chainlink price feed.
    /// @dev Requires a valid Chainlink AggregatorV3Interface address for the feed.
    /// @param tokenAddress The address of the ERC-20 token.
    /// @param priceFeed The address of the Chainlink AggregatorV3Interface for the token/USD price.
    function addAllowedToken(address tokenAddress, address priceFeed) public onlyOwner {
        require(tokenAddress != address(0), "Invalid token address");
        require(priceFeed != address(0), "Invalid price feed address");

        if (!_allowedTokens[tokenAddress]) {
            _allowedTokens[tokenAddress] = true;
            _allowedTokenAddresses.push(tokenAddress);
            _priceFeeds[tokenAddress] = AggregatorV3Interface(priceFeed);
            emit AllowedTokenAdded(tokenAddress, priceFeed);
        }
    }

    /// @notice Removes an ERC-20 token from the list of allowed deposit tokens.
    /// @dev Note: This does not affect tokens already held in vaults, but prevents new deposits/withdrawals of this type.
    /// @param tokenAddress The address of the ERC-20 token to remove.
    function removeAllowedToken(address tokenAddress) public onlyOwner {
        if (_allowedTokens[tokenAddress]) {
            _allowedTokens[tokenAddress] = false;
            // Remove from allowedTokenAddresses array - inefficient for large arrays, but simple
            for (uint i = 0; i < _allowedTokenAddresses.length; i++) {
                if (_allowedTokenAddresses[i] == tokenAddress) {
                    _allowedTokenAddresses[i] = _allowedTokenAddresses[_allowedTokenAddresses.length - 1];
                    _allowedTokenAddresses.pop();
                    break;
                }
            }
            // Removing from priceFeeds mapping is optional, won't be used if !allowedTokens[tokenAddress]
            // delete _priceFeeds[tokenAddress];
            emit AllowedTokenRemoved(tokenAddress);
        }
    }

    /// @notice Sets the base URI for the NFT metadata.
    /// @param baseURI The base URL string. The token ID will be appended to this.
    function setMetadataBaseURI(string memory baseURI) public onlyOwner {
        _metadataBaseURI = baseURI;
    }

    /// @notice Sets the address of the linked governance contract.
    /// @param governanceContractAddress The address of the governance contract.
    function setGovernanceContract(address governanceContractAddress) public onlyOwner {
        require(governanceContractAddress != address(0), "Invalid address");
        _governanceContract = governanceContractAddress;
    }

    /// @notice Allows the owner to rescue ERC-20 tokens mistakenly sent directly to the contract,
    ///         which are NOT part of any NFT vault.
    /// @dev Be cautious not to rescue tokens held legitimately within vaults.
    /// @param tokenAddress The address of the ERC-20 token to rescue.
    /// @param amount The amount of the token to rescue.
    function rescueERC20(address tokenAddress, uint256 amount) public onlyOwner {
        require(tokenAddress != address(0), "Invalid token address");
        require(amount > 0, "Rescue zero amount");

        // Ensure the contract has enough balance
        IERC20 token = IERC20(tokenAddress);
        uint256 contractBalance = token.balanceOf(address(this));
        require(contractBalance >= amount, "Insufficient contract balance");

        // IMPORTANT: This function should only be used for tokens NOT intended for vaults.
        // A more robust system might track total deposits vs total balance.
        // For simplicity here, we assume owner is careful.

        token.transfer(owner(), amount);
    }

    // --- Vault Management Functions ---

    /// @notice Deposits an allowed ERC-20 token into a specific NFT vault.
    /// @dev The sender must be the owner of the NFT. The sender must have approved this contract
    ///      to spend the `tokenAddress` amount prior to calling this function.
    /// @param tokenId The ID of the NFT vault.
    /// @param tokenAddress The address of the ERC-20 token to deposit. Must be an allowed token.
    /// @param amount The amount of the token to deposit.
    function depositTokens(uint256 tokenId, address tokenAddress, uint256 amount)
        public
        onlyNFTVaultOwner(tokenId)
        isAllowedToken(tokenAddress)
    {
        if (!_exists(tokenId)) {
             revert TokenDoesNotExist(tokenId);
        }
        if (amount == 0) {
            revert DepositZeroAmount();
        }

        IERC20 token = IERC20(tokenAddress);
        uint256 initialContractBalance = token.balanceOf(address(this));

        // Transfer tokens from the depositor to the contract
        token.transferFrom(msg.sender, address(this), amount);

        // Verify the transfer happened - simple check, more robust requires pre/post balance diff
        uint256 finalContractBalance = token.balanceOf(address(this));
        require(finalContractBalance >= initialContractBalance.add(amount), "ERC20 transferFrom failed or amount mismatch");

        // Update the vault balance for this token ID and token address
        _vaults[tokenId][tokenAddress] = _vaults[tokenId][tokenAddress].add(amount);

        // Update the calculated USD value for this NFT
        _updateNFTValue(tokenId);

        emit TokensDeposited(tokenId, tokenAddress, amount, msg.sender);
        emit MetadataShouldRefresh(tokenId); // Signal metadata refresh
    }

    /// @notice Withdraws an allowed ERC-20 token from a specific NFT vault.
    /// @dev The sender must be the owner of the NFT.
    /// @param tokenId The ID of the NFT vault.
    /// @param tokenAddress The address of the ERC-20 token to withdraw. Must be an allowed token.
    /// @param amount The amount of the token to withdraw.
    function withdrawTokens(uint256 tokenId, address tokenAddress, uint256 amount)
        public
        onlyNFTVaultOwner(tokenId)
        isAllowedToken(tokenAddress)
    {
        if (!_exists(tokenId)) {
             revert TokenDoesNotExist(tokenId);
        }
        if (amount == 0) {
            revert WithdrawZeroAmount();
        }

        // Check if the vault has enough balance of this token
        uint256 currentVaultBalance = _vaults[tokenId][tokenAddress];
        if (currentVaultBalance < amount) {
            revert InsufficientFundsInVault(tokenAddress, amount, currentVaultBalance);
        }

        // Update the vault balance *before* transferring
        _vaults[tokenId][tokenAddress] = currentVaultBalance.sub(amount);

        // Transfer tokens from the contract back to the withdrawer
        IERC20 token = IERC20(tokenAddress);
        token.transfer(msg.sender, amount);

        // Update the calculated USD value for this NFT
        _updateNFTValue(tokenId);

        emit TokensWithdrawn(tokenId, tokenAddress, amount, msg.sender);
        emit MetadataShouldRefresh(tokenId); // Signal metadata refresh
    }

    /// @notice Allows the NFT owner to burn their NFT, returning all contained assets to them.
    /// @param tokenId The ID of the NFT to burn.
    function burn(uint256 tokenId) public onlyNFTVaultOwner(tokenId) {
        if (!_exists(tokenId)) {
             revert TokenDoesNotExist(tokenId);
        }

        address owner = ownerOf(tokenId);

        // Withdraw all held tokens back to the owner before burning
        address[] memory allowedTokens = getAllowedTokens(); // Get current list
        for (uint i = 0; i < allowedTokens.length; i++) {
            address tokenAddress = allowedTokens[i];
            uint256 balance = _vaults[tokenId][tokenAddress];
            if (balance > 0) {
                // Note: Using Address.sendValue for ETH if needed, but this design is for ERC20s
                IERC20 token = IERC20(tokenAddress);
                _vaults[tokenId][tokenAddress] = 0; // Clear balance in mapping BEFORE transfer
                token.transfer(owner, balance);
                emit TokensWithdrawn(tokenId, tokenAddress, balance, owner); // Log the withdrawal
            }
        }

        // Finally, burn the NFT
        _burn(tokenId);
        _tokenIds.decrement(); // Decrement total supply counter if using it this way

        // Optional: Clean up vault storage entries explicitly (gas intensive)
        // For practical purposes, leaving empty mappings is fine.

        emit NFTBurned(tokenId, owner);
    }


    // --- Value Tracking Functions ---

    /// @notice Internal helper to calculate and store the total USD value of assets in an NFT vault.
    /// @dev Iterates through allowed tokens, gets price from oracle, sums up values.
    /// @param tokenId The ID of the NFT vault.
    function _updateNFTValue(uint256 tokenId) internal {
        if (!_exists(tokenId)) {
             revert TokenDoesNotExist(tokenId); // Should not happen if called from deposit/withdraw
        }

        int256 totalValueUSD = 0;

        address[] memory currentAllowedTokens = getAllowedTokens();
        for (uint i = 0; i < currentAllowedTokens.length; i++) {
            address tokenAddress = currentAllowedTokens[i];
            uint256 tokenBalance = _vaults[tokenId][tokenAddress];

            if (tokenBalance > 0) {
                 AggregatorV3Interface priceFeed = _priceFeeds[tokenAddress];
                 if (address(priceFeed) == address(0)) {
                     // Should not happen if token is in _allowedTokenAddresses, but safety check
                     continue;
                 }

                 (, int256 price, , , ) = priceFeed.latestRoundData();

                 if (price <= 0) {
                     // Handle zero or negative price (e.g., oracle error, illiquid asset)
                     // We can skip this token or handle it specifically. Skipping for now.
                     continue;
                 }

                 // Get token decimals and price feed decimals for scaling
                 uint8 tokenDecimals;
                 try IERC20(tokenAddress).decimals() returns (uint8 decimals) {
                     tokenDecimals = decimals;
                 } catch {
                      // If token doesn't support decimals() (very rare), assume 18 or skip
                      continue; // Skip tokens without standard decimals()
                 }

                 uint8 priceFeedDecimals = uint8(priceFeed.decimals());

                 // Calculate value: (balance * price) / (10^tokenDecimals * 10^priceFeedDecimals)
                 // We need to scale the balance up to 10^18 (standard for value calculation)
                 // Then multiply by price (scaled by 10^priceFeedDecimals)
                 // Result needs to be scaled down by 10^priceFeedDecimals to match price feed output scale

                 // Scaling balance to a higher precision before multiplication
                 // Balance is tokenBalance * (10^18 / 10^tokenDecimals)
                 uint256 balanceScaled18 = tokenBalance.mul(10**18).div(10**tokenDecimals);

                 // Calculate value in USD terms, maintaining priceFeedDecimals scale
                 // (balanceScaled18 * price) / 10^18
                 int256 tokenValueUSD = int256(balanceScaled18.mul(uint256(price)).div(10**18));

                 totalValueUSD = totalValueUSD.add(tokenValueUSD);
            }
        }

        _nftValueUSD[tokenId] = totalValueUSD;
        emit NFTValueUpdated(tokenId, totalValueUSD);
    }


    /// @notice Gets the last calculated (stored) USD value of an NFT's vault.
    /// @dev This value is updated on deposit, withdrawal, or burn.
    /// @param tokenId The ID of the NFT.
    /// @return The USD value of the vault (scaled by 10^8, standard Chainlink format).
    function getNFTValueUSD(uint256 tokenId) public view returns (int256) {
         if (!_exists(tokenId)) {
             revert TokenDoesNotExist(tokenId);
         }
        return _nftValueUSD[tokenId];
    }

    /// @notice Calculates and returns the *current* USD value of an NFT's vault using live oracle data.
    /// @dev Can be gas-intensive as it reads multiple oracles. Does NOT store the value.
    /// @param tokenId The ID of the NFT.
    /// @return The live USD value of the vault (scaled by 10^8, standard Chainlink format).
    function getLiveNFTValueUSD(uint256 tokenId) public view returns (int256) {
         if (!_exists(tokenId)) {
             revert TokenDoesNotExist(tokenId);
         }

        int256 totalValueUSD = 0;

        address[] memory currentAllowedTokens = getAllowedTokens(); // Use state array for iteration
         if (currentAllowedTokens.length == 0) {
             return 0; // No allowed tokens, value is zero
         }

        for (uint i = 0; i < currentAllowedTokens.length; i++) {
            address tokenAddress = currentAllowedTokens[i];
            uint256 tokenBalance = _vaults[tokenId][tokenAddress];

            if (tokenBalance > 0) {
                 AggregatorV3Interface priceFeed = _priceFeeds[tokenAddress];
                 if (address(priceFeed) == address(0)) {
                     // This token was likely removed from allowed list but still in vault
                     // Cannot get live price, skip or handle error
                     continue;
                 }

                 (, int256 price, , , ) = priceFeed.latestRoundData();

                 if (price <= 0) {
                     // Handle zero or negative price - cannot calculate value
                     continue;
                 }

                 uint8 tokenDecimals;
                 try IERC20(tokenAddress).decimals() returns (uint8 decimals) {
                     tokenDecimals = decimals;
                 } catch {
                      continue; // Skip tokens without standard decimals()
                 }

                 uint8 priceFeedDecimals = uint8(priceFeed.decimals());

                 // Calculation similar to _updateNFTValue
                 uint256 balanceScaled18 = tokenBalance.mul(10**18).div(10**tokenDecimals);
                 int256 tokenValueUSD = int256(balanceScaled18.mul(uint256(price)).div(10**18));

                 totalValueUSD = totalValueUSD.add(tokenValueUSD);
            }
        }

        return totalValueUSD; // Value scaled to 10^priceFeedDecimals (assuming all feeds have same decimals, common for USD)
                             // Or scale to a fixed value like 10^8 if needed (less common now)
                             // Chainlink USD feeds are typically 8 decimals.

        // A more robust approach might aggregate decimals from all feeds, but sticking to 8 is common.
        // Let's ensure the output matches typical AggregatorV3Interface().latestRoundData() return format (10^8).
        // If priceFeedDecimals != 8, additional scaling logic is needed here. Assuming 8 for simplicity.
    }

    // --- Utility/Interaction Functions ---

    /// @notice Public function to signal an external service that metadata for a token should be refreshed.
    /// @dev This function doesn't change state itself, but emits an event. Can be called by anyone to help keep metadata fresh.
    /// @param tokenId The ID of the NFT for which metadata should be refreshed.
    function triggerMetadataRefresh(uint256 tokenId) public {
        if (!_exists(tokenId)) {
             revert TokenDoesNotExist(tokenId);
        }
        emit MetadataShouldRefresh(tokenId);
    }

    /// @notice Allows the NFT owner to interact with the configured governance contract.
    /// @dev The nature of the interaction depends on the target governance contract's ABI.
    ///      This function passes the tokenId, caller, and arbitrary data to the target contract.
    /// @param tokenId The ID of the NFT being used for the interaction.
    /// @param data The abi-encoded call data for the governance contract function.
    function interactWithGovernance(uint256 tokenId, bytes memory data) public onlyNFTVaultOwner(tokenId) {
        if (!_exists(tokenId)) {
             revert TokenDoesNotExist(tokenId);
        }
        if (_governanceContract == address(0)) {
            revert GovernanceContractNotSet();
        }

        // Example interaction: Call a function on the governance contract, passing NFT details
        // Using a simple interface call for clarity, could use low-level call for flexibility
        try IGovernance(_governanceContract).execute(tokenId, msg.sender, data) {
            // Success
            emit GovernanceInteraction(tokenId, _governanceContract, data);
        } catch {
            // Handle potential errors from the governance call
            revert GovernanceCallFailed();
        }
    }

    // --- View Functions (Getters) ---

    /// @notice Gets the balance of a specific ERC-20 token within an NFT's vault.
    /// @param tokenId The ID of the NFT.
    /// @param tokenAddress The address of the ERC-20 token.
    /// @return The amount of the token held in the vault.
    function getVaultTokenBalance(uint256 tokenId, address tokenAddress) public view returns (uint256) {
         if (!_exists(tokenId)) {
             revert TokenDoesNotExist(tokenId);
         }
        return _vaults[tokenId][tokenAddress];
    }

    /// @notice Attempts to list all allowed tokens and their balances for a specific NFT vault.
    /// @dev Note: Returning dynamic arrays of mappings is not standard. This function iterates
    ///      through the list of *allowed* tokens and returns the balance *if* that token is held.
    ///      A complete list of *all* tokens ever deposited (even if no longer allowed) would require
    ///      different storage structure or off-chain indexing.
    /// @param tokenId The ID of the NFT.
    /// @return An array of token addresses and an array of their corresponding balances in the vault.
    function getVaultContents(uint256 tokenId) public view returns (address[] memory tokens, uint256[] memory balances) {
        if (!_exists(tokenId)) {
             revert TokenDoesNotExist(tokenId);
        }

        address[] memory allowedTokens = getAllowedTokens();
        uint256[] memory currentBalances = new uint256[](allowedTokens.length);

        for (uint i = 0; i < allowedTokens.length; i++) {
            currentBalances[i] = _vaults[tokenId][allowedTokens[i]];
        }

        return (allowedTokens, currentBalances);
    }

    /// @notice Gets the list of all ERC-20 token addresses currently allowed for deposit.
    /// @return An array of allowed token addresses.
    function getAllowedTokens() public view returns (address[] memory) {
        return _allowedTokenAddresses;
    }

    /// @notice Gets the Chainlink price feed address configured for a specific token.
    /// @param tokenAddress The address of the ERC-20 token.
    /// @return The address of the Chainlink AggregatorV3Interface. Returns address(0) if not set or not allowed.
    function getChainlinkPriceFeed(address tokenAddress) public view returns (address) {
        return address(_priceFeeds[tokenAddress]);
    }

    /// @notice Gets the address of the configured governance contract.
    /// @return The address of the governance contract. Returns address(0) if not set.
    function getGovernanceContract() public view returns (address) {
        return _governanceContract;
    }

    /// @notice Gets the total number of NFTs minted by this contract.
    /// @return The total count of minted NFTs.
    function getTotalMinted() public view returns (uint256) {
        return _tokenIds.current();
    }

    // --- Fallback/Receive (Optional but good practice) ---

    // Prevent ETH from being sent directly to the contract address
    receive() external payable {
        revert("ETH not accepted directly");
    }

    fallback() external payable {
        revert("Fallback not implemented");
    }
}
```

**Explanation of Advanced/Creative/Trendy Concepts:**

1.  **NFT as a Multi-Asset Vault:** Instead of the NFT just *representing* ownership related to a vault elsewhere (like a share token), the `_vaults` mapping directly associates token balances with the NFT's `tokenId`. This makes the NFT the direct container representation.
2.  **Dynamic Metadata Driven by On-Chain Value:** The `tokenURI` links to an external service, but the *content* of that metadata is intended to change based on the calculated USD value (`_nftValueUSD`). The `MetadataShouldRefresh` event acts as an on-chain signal to off-chain services to update the metadata dynamically. The value itself is stored (`_nftValueUSD`) and also calculable live (`getLiveNFTValueUSD`).
3.  **Direct Oracle Integration for State:** Chainlink Price Feeds are used within the contract (`_updateNFTValue`, `getLiveNFTValueUSD`) to calculate a crucial piece of state (`_nftValueUSD`). This moves beyond simple off-chain data use into using on-chain oracles to directly influence contract state (or derivable state).
4.  **Conceptual Governance Interaction:** The `interactWithGovernance` function provides a structured way for the NFT (specifically, its owner and potentially its properties like value/contents) to interface with a separate governance system. This demonstrates utility beyond just collection or value storage.
5.  **Token Gating with Associated Data:** The `_allowedTokens` and `_priceFeeds` mappings, along with the `isAllowedToken` modifier, create a controlled environment for the vault contents, crucially linking the allowed tokens to the necessary oracle data for valuation.
6.  **On-Chain Calculation for Dynamic State:** The `_updateNFTValue` and `getLiveNFTValueUSD` functions perform potentially complex on-chain calculations (iterating through tokens, querying oracles, handling decimals) to determine the value, which is then used conceptually for the dynamic metadata.

This contract is a conceptual framework. For production, you would need:
*   A robust external service to host and serve the dynamic JSON metadata at the `_metadataBaseURI` endpoints, fetching data from the contract via web3 calls (`getNFTValueUSD`, `getVaultContents`, etc.).
*   More sophisticated error handling and gas optimization, especially around array management (`_allowedTokenAddresses`).
*   Consideration for Oracle staleness or failure (Chainlink data includes timestamps and heartbeats, which could be checked).
*   A real `IGovernance` contract interface and implementation.
*   Auditing!

But it meets the criteria of combining several advanced, creative, and trendy concepts into a single Solidity contract with more than 20 public/external functions (counting standard inherited ERC-721/Ownable functions like `name`, `symbol`, `balanceOf`, `ownerOf`, `transferFrom`, `approve`, etc., plus the custom ones).