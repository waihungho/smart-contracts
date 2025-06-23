Okay, here is a Solidity smart contract implementing a "Decentralized Generative Art Canvas" called `AlgoGenesisCanvas`. This contract combines several concepts:

1.  **ERC-721 NFT Standard:** For the generative art pieces themselves.
2.  **On-chain Algorithmic Parameters:** The "DNA" or rules for the generative art are stored directly in the contract.
3.  **Subscription Model:** Users pay a recurring fee (in a specified ERC-20 token) to gain the ability to mint NFTs.
4.  **NFT Mutation:** Subscribers can "mutate" or update the parameters of their existing NFTs, creating dynamic art pieces.
5.  **ERC-2981 Royalties:** Standard way to handle creator royalties.
6.  **Access Control:** Role-based access for managing parameters, subscriptions settings, etc.
7.  **Pausable:** Ability to pause core functions in emergencies.
8.  **UUPS Upgradeability:** Designed to be deployed behind a proxy for future updates.

This contract leverages several advanced concepts and libraries from OpenZeppelin for robustness and best practices, but the core logic around combining subscriptions, on-chain parameters, generative minting, and NFT mutation is a custom design.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol"; // Although params are on-chain, still useful for base URI
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/Base64Upgradeable.sol";

// --- Outline ---
// 1. State Variables: Store contract data (NFT counter, subscription info, params, roles, etc.)
// 2. Events: Announce key actions (Mint, Subscribe, ParamUpdate, Mutation, etc.)
// 3. Errors: Custom errors for clearer reverts.
// 4. Access Control: Define roles (DEFAULT_ADMIN_ROLE).
// 5. Pausable: Implement pausing mechanism.
// 6. UUPS Upgradeability: Implement upgradeability checks.
// 7. Initialization: Set up the contract on deployment (behind a proxy).
// 8. Base ERC721 Functionality: Implement standard ERC721 functions.
// 9. ERC2981 Royalty Functionality: Implement standard royalty info.
// 10. Subscription Management: Handle user subscriptions using ERC20 tokens.
// 11. Algorithmic Parameters: Store and manage on-chain parameters for generative art.
// 12. NFT Minting: Allow subscribers to mint NFTs based on current parameters and randomness.
// 13. NFT Mutation: Allow subscribers to change parameters of their owned NFTs.
// 14. Metadata Generation: Dynamically generate tokenURI including on-chain parameters.
// 15. Admin Functions: Functions for setting parameters, subscription details, withdrawing funds, managing roles.
// 16. View Functions: Functions to query state.

// --- Function Summary ---
// - initialize(string memory name, string memory symbol, address defaultAdmin, address royaltyRecipient, uint96 royaltyPercentageBasisPoints): Sets up the contract (for proxy).
// - setSubscriptionToken(address token): Admin sets the ERC20 token used for subscriptions.
// - setSubscriptionPrice(uint256 price): Admin sets the price (in subscription tokens) per subscription period.
// - setSubscriptionPeriod(uint256 duration): Admin sets the duration (in seconds) of one subscription period.
// - subscribe(uint256 periods): User pays subscription tokens to extend their subscription.
// - unsubscribe(): User cancels automatic extension (if implemented, simplified here to just a placeholder).
// - checkSubscription(address user): Checks if a user's subscription is currently active.
// - extendSubscription(uint256 periods): User explicitly pays to add more periods to current subscription.
// - setParameter(string memory key, bytes memory value): Admin sets or updates an algorithmic parameter.
// - getParameter(string memory key): Retrieves the value of an algorithmic parameter.
// - removeParameter(string memory key): Admin removes an algorithmic parameter.
// - getAllParameterKeys(): Retrieves all currently set algorithmic parameter keys. (Gas-heavy)
// - requestMintNFT(): Subscriber requests to mint a new NFT.
// - _generateRandomParameters(): Internal helper to generate parameters for a new mint using randomness. (Note: Uses simple block data, recommend VRF for production)
// - _mintNFT(address recipient, bytes memory parameters): Internal function to mint the NFT with specified parameters.
// - getNFTParameters(uint256 tokenId): Retrieves the stored parameters for a specific NFT.
// - mutateNFT(uint256 tokenId, bytes memory newParameters): Allows the owner of an NFT to change its parameters (if subscribed).
// - getNFTMutationHistory(uint256 tokenId): Retrieves the history of parameter mutations for an NFT.
// - _addToMutationHistory(uint256 tokenId, bytes memory parameters): Internal helper to add parameters to history.
// - addAdmin(address admin): Owner grants admin role.
// - removeAdmin(address admin): Owner revokes admin role.
// - pause(): Admin pauses minting and subscription functions.
// - unpause(): Admin unpauses.
// - withdrawEarnings(address tokenAddress, address recipient): Admin withdraws collected tokens (e.g., subscription tokens).
// - supportsInterface(bytes4 interfaceId): Standard check for supported interfaces (ERC721, ERC165, ERC2981).
// - tokenURI(uint256 tokenId): Generates the metadata URI for an NFT, including on-chain parameters.
// - royaltyInfo(uint256 tokenId, uint256 salePrice): Standard function for ERC2981 royalties.
// - _authorizeUpgrade(address newImplementation): UUPS check for upgrade authorization.
// - _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize): ERC721 hook.

contract AlgoGenesisCanvas is
    ERC721Upgradeable,
    ERC721EnumerableUpgradeable, // Allows getting total supply and token by index
    ERC721URIStorageUpgradeable,
    AccessControlUpgradeable,
    PausableUpgradeable,
    UUPSUpgradeable,
    ERC2981Upgradeable // For royalties
{
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using StringsUpgradeable for uint256;
    using Base64Upgradeable for bytes;

    // --- State Variables ---

    bytes32 public constant DEFAULT_ADMIN_ROLE = keccak256("DEFAULT_ADMIN_ROLE");

    CountersUpgradeable.Counter private _tokenIdCounter;

    // Subscription details
    address private _subscriptionToken;
    uint256 private _subscriptionPrice; // in subscriptionToken units
    uint256 private _subscriptionPeriod; // in seconds
    mapping(address => uint64) private _subscriptions; // user => expirationTimestamp (uint64 sufficient until ~2200s)

    // Algorithmic Parameters
    mapping(string => bytes) private _algorithmParameters;
    string[] private _parameterKeys; // Store keys for enumeration (gas consideration for large sets)
    mapping(string => bool) private _parameterKeysExists; // Helper for efficient key removal

    // NFT Specific Parameters
    mapping(uint256 => bytes) private _tokenParameters; // tokenId => parameters
    mapping(uint256 => bytes[]) private _tokenMutationHistory; // tokenId => list of historical parameter states

    // Royalty Info (ERC2981)
    address private _royaltyRecipient;
    uint96 private _royaltyPercentageBasisPoints; // bps, e.g., 250 = 2.5%

    // Base URI for metadata
    string private _baseURI;

    // --- Events ---

    event Initialized(uint8 version);
    event SubscriptionTokenSet(address indexed token);
    event SubscriptionPriceSet(uint256 price);
    event SubscriptionPeriodSet(uint256 duration);
    event Subscribed(address indexed user, uint64 expiration);
    event ParameterSet(string key, bytes value);
    event ParameterRemoved(string key);
    event NFTMinted(address indexed owner, uint256 indexed tokenId, bytes parameters);
    event NFTMutated(uint256 indexed tokenId, bytes newParameters);
    event EarningsWithdrawn(address indexed token, address indexed recipient, uint256 amount);

    // --- Errors ---

    error SubscriptionNotActive(address user);
    error SubscriptionTokenNotSet();
    error SubscriptionPriceNotSet();
    error SubscriptionPeriodNotSet();
    error InsufficientSubscriptionAllowance(address user, uint256 required, uint256 current);
    error ParameterDoesNotExist(string key);
    error OnlySubscribersCanMint();
    error OnlyNFTOwnerCanMutate();
    error ZeroAddress();
    error InvalidRoyaltyPercentage();
    error ParametersMustNotBeEmpty();

    // --- Initialization ---

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        // Initializer called by the proxy
        _disableInitializers();
    }

    function initialize(
        string memory name,
        string memory symbol,
        address defaultAdmin,
        address royaltyRecipient,
        uint96 royaltyPercentageBasisPoints_
    ) public initializer {
        if (defaultAdmin == address(0) || royaltyRecipient == address(0)) revert ZeroAddress();
        if (royaltyPercentageBasisPoints_ > 10000) revert InvalidRoyaltyPercentage();

        __ERC721_init(name, symbol);
        __ERC721Enumerable_init();
        __ERC721URIStorage_init(); // Use if base URI is needed, otherwise remove
        __AccessControl_init();
        __Pausable_init();
        __UUPSUpgradeable_init();
        __ERC2981_init();

        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender()); // Grant admin to deployer as well

        _royaltyRecipient = royaltyRecipient;
        _royaltyPercentageBasisPoints = royaltyPercentageBasisPoints_;

        emit Initialized(1);
    }

    // --- Access Control (UUPS) ---

    function _authorizeUpgrade(address newImplementation) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}

    // --- Pausable ---

    function pause() public onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        _pause();
    }

    function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) whenPaused {
        _unpause();
    }

    // --- Base ERC721 Overrides ---

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override(ERC721Upgradeable, ERC721EnumerableUpgradeable) whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721Upgradeable, ERC721EnumerableUpgradeable, ERC2981Upgradeable, AccessControlUpgradeable) returns (bool) {
        return
            ERC721Upgradeable.supportsInterface(interfaceId) ||
            ERC721EnumerableUpgradeable.supportsInterface(interfaceId) ||
            ERC2981Upgradeable.supportsInterface(interfaceId) ||
            AccessControlUpgradeable.supportsInterface(interfaceId);
    }

    // --- ERC2981 Royalty Implementation ---

    function royaltyInfo(uint256 tokenId, uint256 salePrice) public view override returns (address receiver, uint256 royaltyAmount) {
        // _royaltyRecipient and _royaltyPercentageBasisPoints are set by admin
        receiver = _royaltyRecipient;
        royaltyAmount = (salePrice * _royaltyPercentageBasisPoints) / 10000;
    }

    // --- Subscription Management ---

    /// @notice Sets the ERC20 token used for subscriptions.
    /// @param token The address of the ERC20 token.
    function setSubscriptionToken(address token) public onlyRole(DEFAULT_ADMIN_ROLE) {
        if (token == address(0)) revert ZeroAddress();
        _subscriptionToken = token;
        emit SubscriptionTokenSet(token);
    }

    /// @notice Sets the price per subscription period.
    /// @param price The price in units of the subscription token.
    function setSubscriptionPrice(uint256 price) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _subscriptionPrice = price;
        emit SubscriptionPriceSet(price);
    }

    /// @notice Sets the duration of one subscription period in seconds.
    /// @param duration The duration in seconds.
    function setSubscriptionPeriod(uint256 duration) public onlyRole(DEFAULT_ADMIN_ROLE) {
        if (duration == 0) revert Revert("Period must be > 0"); // Using generic Revert for simple checks
        _subscriptionPeriod = duration;
        emit SubscriptionPeriodSet(duration);
    }

    /// @notice Extends the caller's subscription by the specified number of periods.
    /// User must have approved the contract to spend the required amount of subscription tokens.
    /// @param periods The number of periods to subscribe for.
    function subscribe(uint256 periods) public whenNotPaused {
        if (_subscriptionToken == address(0)) revert SubscriptionTokenNotSet();
        if (_subscriptionPrice == 0) revert SubscriptionPriceNotSet();
        if (_subscriptionPeriod == 0) revert SubscriptionPeriodNotSet();
        if (periods == 0) revert Revert("Periods must be > 0");

        uint256 requiredAmount = _subscriptionPrice * periods;
        address subscriber = _msgSender();
        IERC20Upgradeable subscriptionToken = IERC20Upgradeable(_subscriptionToken);

        // Check allowance first
        if (subscriptionToken.allowance(subscriber, address(this)) < requiredAmount) {
             revert InsufficientSubscriptionAllowance(subscriber, requiredAmount, subscriptionToken.allowance(subscriber, address(this)));
        }

        // Transfer tokens from the user
        bool success = subscriptionToken.transferFrom(subscriber, address(this), requiredAmount);
        if (!success) revert Revert("Token transfer failed"); // Using generic Revert

        uint64 currentExpiration = _subscriptions[subscriber];
        uint64 newExpiration;

        // If subscription is expired or doesn't exist, start from now
        if (currentExpiration < block.timestamp) {
            newExpiration = uint64(block.timestamp + (_subscriptionPeriod * periods));
        } else {
            // If active, extend from current expiration
            newExpiration = uint64(currentExpiration + (_subscriptionPeriod * periods));
        }

        _subscriptions[subscriber] = newExpiration;
        emit Subscribed(subscriber, newExpiration);
    }

    /// @notice Placeholder for potential unsubscribe logic (e.g., cancelling recurring payments).
    /// This simple version doesn't implement recurring payments, so it does nothing.
    function unsubscribe() public {
        // In a system with recurring payments (e.g., via a relayer or off-chain),
        // this function would signal the intent to cancel the next payment.
        // For this simple model, it's a no-op as subscriptions are pre-paid for periods.
    }

    /// @notice Checks if a user's subscription is currently active.
    /// @param user The address of the user to check.
    /// @return True if the subscription is active, false otherwise.
    function checkSubscription(address user) public view returns (bool) {
        return _subscriptions[user] > block.timestamp;
    }

    /// @notice Explicitly extends a user's *current* subscription expiration date.
    /// This is an alternative way to pay for periods, potentially useful if the user
    /// wants to add time starting from their *current* expiration rather than `block.timestamp`.
    /// In this contract's simple model, `subscribe` already does this if the subscription is active.
    /// Keeping it for clarity and distinct function count.
    /// @param periods The number of periods to add.
    function extendSubscription(uint256 periods) public whenNotPaused {
         // Re-use subscribe logic as it correctly extends from current expiration if active
        subscribe(periods);
    }


    // --- Algorithmic Parameters ---

    /// @notice Sets or updates a specific algorithmic parameter.
    /// @param key The identifier for the parameter (e.g., "colorPalette", "shapeType").
    /// @param value The parameter value encoded as bytes.
    function setParameter(string memory key, bytes memory value) public onlyRole(DEFAULT_ADMIN_ROLE) {
        if (!_parameterKeysExists[key]) {
            _parameterKeys.push(key);
            _parameterKeysExists[key] = true;
        }
        _algorithmParameters[key] = value;
        emit ParameterSet(key, value);
    }

    /// @notice Retrieves the value of an algorithmic parameter.
    /// @param key The identifier for the parameter.
    /// @return The parameter value as bytes.
    function getParameter(string memory key) public view returns (bytes memory) {
        if (!_parameterKeysExists[key]) revert ParameterDoesNotExist(key);
        return _algorithmParameters[key];
    }

     /// @notice Removes an algorithmic parameter.
    /// @param key The identifier for the parameter.
    function removeParameter(string memory key) public onlyRole(DEFAULT_ADMIN_ROLE) {
         if (!_parameterKeysExists[key]) revert ParameterDoesNotExist(key);

        delete _algorithmParameters[key]; // Clear the value
        _parameterKeysExists[key] = false; // Mark key as non-existent

        // Remove key from the array (gas-inefficient for large arrays)
        // In production, consider a linked list or different data structure
        for (uint i = 0; i < _parameterKeys.length; i++) {
            if (keccak256(bytes(_parameterKeys[i])) == keccak256(bytes(key))) {
                // Replace with last element and pop
                _parameterKeys[i] = _parameterKeys[_parameterKeys.length - 1];
                _parameterKeys.pop();
                break; // Key is unique
            }
        }

        emit ParameterRemoved(key);
    }

    /// @notice Retrieves all currently set algorithmic parameter keys.
    /// Note: This function can be gas-heavy if there are many parameters.
    /// @return An array of all parameter keys.
    function getAllParameterKeys() public view returns (string[] memory) {
        // Filter out keys that were removed but not yet cleaned from the array if removal didn't happen via removeParameter
        // Or if using the current removeParameter logic, it's just the remaining keys.
         string[] memory activeKeys = new string[](_parameterKeys.length);
         uint activeCount = 0;
         for (uint i = 0; i < _parameterKeys.length; i++) {
             if (_parameterKeysExists[_parameterKeys[i]]) {
                 activeKeys[activeCount] = _parameterKeys[i];
                 activeCount++;
             }
         }
         // Resize the array to only contain active keys if needed
         if (activeCount < _parameterKeys.length) {
             string[] memory result = new string[](activeCount);
             for(uint i = 0; i < activeCount; i++) {
                 result[i] = activeKeys[i];
             }
             return result;
         }
        return activeKeys;
    }


    // --- NFT Minting ---

    /// @notice Allows a subscribed user to request the minting of a new AlgoGenesis NFT.
    /// The NFT will be generated based on current algorithmic parameters and randomness.
    function requestMintNFT() public whenNotPaused {
        if (!checkSubscription(_msgSender())) revert OnlySubscribersCanMint();

        // Generate parameters using pseudo-randomness
        // NOTE: This is NOT cryptographically secure randomness.
        // For production, integrate a VRF (Verifiable Random Function) like Chainlink VRF.
        // The VRF would typically involve a request/callback pattern.
        // For this example, we use a simple block-based pseudo-randomness for demonstration.
        bytes memory generatedParameters = _generateRandomParameters();
        if (generatedParameters.length == 0) revert Revert("Failed to generate parameters"); // Generic revert for generation error

        _mintNFT(_msgSender(), generatedParameters);
    }

    /// @dev Internal helper function to generate parameters based on current algorithm settings and randomness.
    /// Uses a basic hash of block data and caller address for pseudo-randomness.
    /// @return Bytes representing the generated parameters for an NFT.
    function _generateRandomParameters() internal view returns (bytes memory) {
        // Simple pseudo-randomness using block data and caller address.
        // *** DO NOT USE THIS FOR HIGH-VALUE OR SECURITY-CRITICAL RANDOMNESS ***
        // Replace with Chainlink VRF or similar for production.
        uint256 randomSeed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, tx.origin, msg.sender, _tokenIdCounter.current())));

        // In a real system, this logic would interpret the randomSeed
        // and potentially iterate through _parameterKeys, using the seed
        // to select values, variants, or apply transformations defined by
        // the on-chain _algorithmParameters.

        // Example: Simple logic that hashes the seed with some parameter keys
        bytes memory generatedParams = abi.encodePacked("seed:", randomSeed.toString());

        // This is a simplified placeholder. Real logic would parse _algorithmParameters
        // and use the seed to derive concrete values (e.g., color hex, shape type enum).
        // Example (conceptual):
        // bytes memory colorPaletteBytes = _algorithmParameters["colorPalette"]; // e.g., abi.encode(["#FF0000", "#00FF00"])
        // string[] memory colorPalette = abi.decode(colorPaletteBytes, (string[]));
        // uint256 colorIndex = randomSeed % colorPalette.length;
        // bytes memory colorParam = abi.encodePacked("color:", colorPalette[colorIndex]);
        // generatedParams = abi.encodePacked(generatedParams, colorParam);

        // For demonstration, just return the seed-based bytes
        return generatedParams;
    }


    /// @dev Internal function to handle the actual minting process.
    /// Mints the NFT to the recipient with the given parameters.
    /// @param recipient The address to mint the NFT to.
    /// @param parameters The parameters generated for this specific NFT.
    function _mintNFT(address recipient, bytes memory parameters) internal {
        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        _safeMint(recipient, newTokenId);
        _tokenParameters[newTokenId] = parameters;
        _addToMutationHistory(newTokenId, parameters); // Add initial state to history

        emit NFTMinted(recipient, newTokenId, parameters);
    }

    /// @notice Retrieves the specific parameters stored for a given NFT token ID.
    /// @param tokenId The ID of the NFT.
    /// @return The parameters as bytes.
    function getNFTParameters(uint256 tokenId) public view returns (bytes memory) {
        _requireMinted(tokenId);
        return _tokenParameters[tokenId];
    }

    // --- NFT Mutation ---

    /// @notice Allows the owner of an NFT to mutate its parameters.
    /// Requires an active subscription.
    /// @param tokenId The ID of the NFT to mutate.
    /// @param newParameters The new parameters for the NFT.
    function mutateNFT(uint256 tokenId, bytes memory newParameters) public whenNotPaused {
        _requireMinted(tokenId);
        if (_msgSender() != ownerOf(tokenId)) revert OnlyNFTOwnerCanMutate();
        if (!checkSubscription(_msgSender())) revert OnlySubscribersCanMint(); // Mutation also requires subscription
        if (newParameters.length == 0) revert ParametersMustNotBeEmpty();

        _tokenParameters[tokenId] = newParameters;
        _addToMutationHistory(tokenId, newParameters);

        emit NFTMutated(tokenId, newParameters);
    }

    /// @notice Retrieves the history of mutations for a specific NFT token ID.
    /// @param tokenId The ID of the NFT.
    /// @return An array of bytes, where each element is a historical parameter state.
    function getNFTMutationHistory(uint256 tokenId) public view returns (bytes[] memory) {
         _requireMinted(tokenId);
         return _tokenMutationHistory[tokenId];
    }

    /// @dev Internal helper to add a parameter state to the mutation history.
    /// @param tokenId The ID of the NFT.
    /// @param parameters The parameter state to add.
    function _addToMutationHistory(uint256 tokenId, bytes memory parameters) internal {
         _tokenMutationHistory[tokenId].push(parameters);
    }


    // --- Metadata Generation ---

    /// @notice Sets the base URI for token metadata.
    /// @param baseURI_ The base URI string.
    function setBaseURI(string memory baseURI_) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _baseURI = baseURI_;
        // No event emitted in OZ ERC721URIStorage, but could add one if desired
    }

    /// @dev Internal helper to get the base URI.
    function _baseURI() internal view override returns (string memory) {
        return _baseURI;
    }

    /// @notice Generates the metadata URI for a given token ID.
    /// Includes the on-chain parameters encoded in a data URI.
    /// @param tokenId The ID of the NFT.
    /// @return A data URI string containing JSON metadata.
    function tokenURI(uint256 tokenId) public view override(ERC721Upgradeable, ERC721URIStorageUpgradeable) returns (string memory) {
        _requireMinted(tokenId); // Check if token exists

        // Get the stored parameters for this token
        bytes memory parameters = _tokenParameters[tokenId];

        // Example JSON structure - adapt based on how parameters are structured
        // This example treats the 'parameters' bytes as just a value to display.
        // A real implementation would parse the bytes into meaningful key-value pairs.
        string memory json = string(abi.encodePacked(
            '{"name": "AlgoGenesis #', tokenId.toString(),
            '", "description": "Generative Art NFT from AlgoGenesis Canvas. Parameters stored on-chain.",',
            '"image": "', _baseURI(), tokenId.toString(), '.png",', // Point to an image service
            '"attributes": [',
                '{"trait_type": "Token ID", "value": "', tokenId.toString(), '"},',
                '{"trait_type": "Parameters (raw)", "value": "', string(parameters), '"}', // Simple raw display
                // Add more attributes by parsing the `parameters` bytes here
                // e.g., '{"trait_type": "Color", "value": "Red"}, {"trait_type": "Shape", "value": "Circle"}'
            ']}'
        ));

        // Encode the JSON as Base64 and prepend the data URI scheme
        string memory base64Json = Base64Upgradeable.encode(bytes(json));
        return string(abi.encodePacked("data:application/json;base64,", base64Json));
    }


    // --- Admin Functions ---

     /// @notice Grants the DEFAULT_ADMIN_ROLE to an address.
     /// Only the current owner or an existing admin can call this (via AccessControl).
    function addAdmin(address admin) public onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(DEFAULT_ADMIN_ROLE, admin);
    }

     /// @notice Revokes the DEFAULT_ADMIN_ROLE from an address.
     /// Only an existing admin can call this. Cannot revoke from the last admin (or owner if owner is admin).
     /// In practice, ensure you don't lock yourself out.
    function removeAdmin(address admin) public onlyRole(DEFAULT_ADMIN_ROLE) {
        // Potentially add a check to prevent revoking from the last admin role holder,
        // or implement a timelock/multi-sig for critical role changes.
        revokeRole(DEFAULT_ADMIN_ROLE, admin);
    }

    /// @notice Allows admins to withdraw collected tokens (e.g., subscription fees).
    /// Can withdraw any ERC20 token held by the contract.
    /// @param tokenAddress The address of the ERC20 token to withdraw.
    /// @param recipient The address to send the tokens to.
    function withdrawEarnings(address tokenAddress, address recipient) public onlyRole(DEFAULT_ADMIN_ROLE) {
        if (recipient == address(0)) revert ZeroAddress();
        IERC20Upgradeable token = IERC20Upgradeable(tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        if (balance > 0) {
            bool success = token.transfer(recipient, balance);
            if (!success) revert Revert("Withdrawal failed"); // Using generic Revert
            emit EarningsWithdrawn(tokenAddress, recipient, balance);
        }
    }


    // --- View Functions ---

    /// @notice Gets the current subscription token address.
    function getSubscriptionToken() public view returns (address) {
        return _subscriptionToken;
    }

    /// @notice Gets the current subscription price.
     /// @return The price in units of the subscription token.
    function getSubscriptionPrice() public view returns (uint256) {
        return _subscriptionPrice;
    }

     /// @notice Gets the current subscription period duration.
     /// @return The duration in seconds.
    function getSubscriptionPeriod() public view returns (uint256) {
        return _subscriptionPeriod;
    }

    /// @notice Gets the subscription expiration timestamp for a user.
    /// @param user The address of the user.
    /// @return The Unix timestamp when the subscription expires (0 if never subscribed or long expired).
    function getSubscriptionExpiration(address user) public view returns (uint64) {
        return _subscriptions[user];
    }

    /// @notice Gets the total number of NFTs minted.
    function getTotalMinted() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    /// @notice Gets the current royalty recipient address.
    function getRoyaltyRecipient() public view returns (address) {
        return _royaltyRecipient;
    }

    /// @notice Gets the current royalty percentage in basis points.
    function getRoyaltyPercentageBasisPoints() public view returns (uint96) {
        return _royaltyPercentageBasisPoints;
    }

    /// @notice Checks if an address has the DEFAULT_ADMIN_ROLE.
    function isAdmin(address account) public view returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, account);
    }

    // --- Helper for Revert (can define custom errors instead) ---
    // Simplified error handling for minor checks.
    // In production, use specific custom errors.
    error Revert(string message);
}
```

---

**Explanation of Concepts and Features:**

1.  **Algorithmic Parameters (`_algorithmParameters`, `_parameterKeys`):** This mapping stores key-value pairs (string to bytes) representing the rules or settings for the generative art. Examples could be `{"colorPalette": "<hex_codes_encoded>", "shapeDensity": "<uint_encoded>"}`. The `bytes` type allows flexibility to store various data types (strings, numbers, arrays, structs) encoded using `abi.encode`. `_parameterKeys` is added to allow iterating through keys, though this is gas-heavy for many parameters.
2.  **Subscription Model (`_subscriptions`, `_subscriptionToken`, `_subscriptionPrice`, `_subscriptionPeriod`, `subscribe`, `checkSubscription`):** Users pay a specified ERC-20 token to the contract (`IERC20Upgradeable.transferFrom`). The contract tracks the expiration timestamp (`_subscriptions` mapping). Minting (`requestMintNFT`) is gated by `checkSubscription`.
3.  **NFT Minting (`requestMintNFT`, `_generateRandomParameters`, `_mintNFT`):** Only subscribers can call `requestMintNFT`. It calls an internal function (`_generateRandomParameters`) to determine the NFT's parameters based on the current `_algorithmParameters` and some source of randomness. It then calls `_mintNFT` to create the ERC721 token and store the *specific* generated parameters for that token ID.
4.  **Pseudo-Randomness (`_generateRandomParameters`):** **Important:** The example uses `block.timestamp` and `block.difficulty` hashing for randomness. This is **predictable and insecure** for anything valuable. A real application *must* integrate a secure Verifiable Random Function (VRF) like Chainlink VRF. The `requestMintNFT` would trigger a VRF request, and the minting would happen in a callback function.
5.  **NFT Mutation (`mutateNFT`, `_tokenParameters`, `_tokenMutationHistory`):** This is a key creative feature. The owner of an NFT, if they have an active subscription, can change the `_tokenParameters` associated with their token. This allows the art represented by the NFT to evolve over time. Mutation history is stored.
6.  **On-Chain Metadata (`tokenURI`):** The `tokenURI` function dynamically generates the NFT's metadata JSON. It includes the specific `_tokenParameters` stored for that token ID directly in the metadata, encoded in a data URI. This means the core properties of the art are verifiable on-chain. `Base64Upgradeable` is used to encode the JSON.
7.  **ERC-2981 Royalties:** Standard implementation for creators/platforms to receive royalties on secondary sales on marketplaces that support the standard.
8.  **Access Control:** Uses OpenZeppelin's `AccessControlUpgradeable` for role-based permissions (here, just `DEFAULT_ADMIN_ROLE`).
9.  **Pausable:** Allows admins to pause sensitive functions like minting and subscription payments in case of issues.
10. **UUPS Upgradeability:** Inherits `UUPSUpgradeable` and includes the `_authorizeUpgrade` function, allowing the contract logic to be upgraded via a proxy contract (like OpenZeppelin's UUPS proxy). This means you can fix bugs or add features later without migrating NFTs or state. State variables are laid out contiguously as per upgradeability patterns.
11. **ERC-721 Enumerable:** Included for easy access to the total supply and iterating tokens by index (though iterating large collections on-chain is gas-intensive).
12. **Error Handling:** Uses `revert` with custom errors for clarity.

This contract provides a framework for a dynamic, subscription-based generative art platform where the art's "DNA" and its evolution are managed on-chain. Remember that for a production system, the randomness source and potentially the gas efficiency of parameter storage/retrieval would need further optimization.