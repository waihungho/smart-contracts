Okay, here is a Solidity smart contract incorporating several advanced concepts like:

1.  **Composable/Fusion NFTs:** Combining existing NFTs to create a new one.
2.  **On-Chain Randomness:** Using Chainlink VRF for unpredictable outcomes in fusion.
3.  **Dynamic Metadata:** Hinting at how `tokenURI` could change based on NFT state (though the external metadata source is a placeholder).
4.  **Recipe-Based Crafting:** Defining specific combinations required for fusion.
5.  **Role-Based Access (Implicit):** Using `Ownable` for admin tasks (minting, setting fees, defining recipes, VRF config).
6.  **Pausable:** Emergency stop mechanism.
7.  **Gas Optimization considerations:** Using structs, mappings efficiently.
8.  **ERC-721 Standard:** Building on a well-known standard but adding significant custom logic.
9.  **Custom Errors:** For clearer error handling (in Solidity 0.8+).
10. **State Management:** Tracking fusion requests and NFT properties.

It *uses* standard interfaces (ERC721, VRF) but the *fusion/crafting logic* and state management built around it are the creative core, not a direct duplicate of standard open-source contracts.

We will aim for over 20 functions covering the standard ERC721 interface, administrative controls, user interaction for fusion, view functions, and VRF integration.

---

**Outline and Function Summary:**

This smart contract implements a Non-Fungible Token (NFT) collection where users can fuse existing NFTs ('Base' type) based on predefined recipes and a random outcome to create new NFTs ('Fused' type).

**Contract:** `CryptoArtFusion`

**Inherits:** ERC721, Ownable, Pausable, VRFConsumerBaseV2

**Key Concepts:**
*   **NFT Types:** Base (initial mints), Fused (created via fusion).
*   **Fusion Recipes:** Define required input NFT types/attributes and potential output details/success chance.
*   **Fusion Process:** User initiates by providing input NFTs and paying a fee. Randomness is requested via Chainlink VRF. The VRF callback determines success/failure and mints a new NFT or burns inputs.
*   **Dynamic Metadata:** The `tokenURI` can differ based on the NFT's type (Base vs. Fused) and potentially its specific attributes derived from fusion.

**State Variables:**
*   `_tokenIds`: Counter for total minted NFTs.
*   `_nftData`: Maps tokenId to `NFTData` struct (type, parents, attributes, fusionRequestId).
*   `_fusionRecipes`: Maps recipe hash/ID to `FusionRecipe` struct.
*   `_fusionRequests`: Maps VRF `requestId` to `FusionRequest` struct.
*   `_requestIdsByInitiator`: Tracks pending requests per user.
*   `_fusionFee`: Fee required to initiate fusion.
*   `_baseTokenURIPrefix`: Base URI for Base NFTs.
*   `_fusedTokenURIPrefix`: Base URI for Fused NFTs.
*   `_dynamicMetadataSource`: (Placeholder/Example) Address of a potential external metadata contract.
*   `_vrfCoordinator`: Address of Chainlink VRF Coordinator.
*   `_keyHash`: Key hash for Chainlink VRF requests.
*   `_callbackGasLimit`: Gas limit for Chainlink VRF callback.
*   `_s_randomWords`: Stores the random words received from VRF.

**Structs:**
*   `NFTData`: Stores data specific to each NFT (type, parents, attributes, fusionRequestId).
*   `InputRequirement`: Defines required properties for an input NFT in a recipe.
*   `FusionRecipe`: Defines a recipe (inputs, output chance, output attributes, fee).
*   `FusionRequest`: Tracks a pending/completed fusion request (initiator, inputs, outputId, status, VRF requestId).

**Enums:**
*   `NFTType`: Base, Fused.
*   `FusionStatus`: Pending, Fulfilled, Failed, Claimed.

**Events:**
*   `BaseNFTMinted`: When a Base NFT is minted.
*   `FusionRecipeDefined`: When a fusion recipe is added/updated.
*   `FusionInitiated`: When a user starts a fusion process.
*   `FusionFulfilled`: When VRF callback processes a successful fusion.
*   `FusionFailed`: When VRF callback processes a failed fusion.
*   `FusedNFTClaimed`: When a user claims their resulting Fused NFT.

**Functions (Categorized):**

**I. Core ERC-721 Standard Functions (Overridden/Implemented):**
1.  `constructor()`: Initializes the contract (name, symbol, VRF config, fee, URIs).
2.  `balanceOf(address owner)`: Returns the number of NFTs owned by an address.
3.  `ownerOf(uint256 tokenId)`: Returns the owner of a specific NFT.
4.  `transferFrom(address from, address to, uint256 tokenId)`: Transfers ownership of an NFT.
5.  `safeTransferFrom(address from, address to, uint256 tokenId)`: Safe transfer variant.
6.  `safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)`: Safe transfer variant with data.
7.  `approve(address to, uint256 tokenId)`: Approves an address to transfer a specific NFT.
8.  `setApprovalForAll(address operator, bool approved)`: Approves or revokes an operator for all owner's NFTs.
9.  `getApproved(uint256 tokenId)`: Returns the approved address for a specific NFT.
10. `isApprovedForAll(address owner, address operator)`: Checks if an operator is approved for an owner.
11. `tokenURI(uint256 tokenId)`: Returns the metadata URI for an NFT (dynamic based on type/data).
12. `supportsInterface(bytes4 interfaceId)`: Standard ERC165 function to indicate supported interfaces (ERC721, ERC721Metadata, ERC2981 potentially, VRF).

**II. Owner/Administrative Functions:**
13. `mintBaseNFT(address to, string memory initialAttributes)`: Mints a new 'Base' type NFT to a recipient.
14. `defineFusionRecipe(bytes32 recipeId, InputRequirement[] memory inputs, uint16 successChanceBP, uint256[] memory outputAttributeValues)`: Defines or updates a fusion recipe.
15. `setFusionFee(uint256 fee)`: Sets the fee required to initiate fusion.
16. `setBaseTokenURIPrefix(string memory prefix)`: Sets the base URI for Base NFTs.
17. `setFusedTokenURIPrefix(string memory prefix)`: Sets the base URI for Fused NFTs.
18. `setDynamicMetadataSource(address source)`: Sets an address for potential dynamic metadata lookup.
19. `setVRFConfig(address coordinator, bytes32 keyHash, uint32 callbackGasLimit)`: Sets Chainlink VRF parameters.
20. `withdrawFees()`: Allows the owner to withdraw collected fusion fees.
21. `pause()`: Pauses contract functionality (fusion, minting, transfers).
22. `unpause()`: Unpauses the contract.
23. `transferOwnership(address newOwner)`: Transfers contract ownership.

**III. User Interaction Functions:**
24. `initiateFusion(uint256[] memory inputTokenIds, bytes32 recipeId)`: Initiates the fusion process for a set of owned and approved NFTs using a specific recipe. Pays the fusion fee. Requests VRF randomness.
25. `claimFusedNFT(uint256 fusionRequestId)`: Allows the initiator of a successful fusion to claim the newly minted Fused NFT.

**IV. View/Query Functions:**
26. `getNFTDetails(uint256 tokenId)`: Returns comprehensive details about an NFT (owner, type, parents, attributes, associated fusion request).
27. `getNFTType(uint256 tokenId)`: Returns the type of an NFT (Base or Fused).
28. `viewFusionRecipe(bytes32 recipeId)`: Returns the details of a specific fusion recipe.
29. `viewPossibleFusions(address user, uint256[] memory userOwnedTokenIds)`: (Conceptual/Helper) Suggests potential fusion recipes based on a user's owned NFTs (Note: This could be gas-intensive on-chain and better handled off-chain).
30. `getFusionRequestStatus(uint256 fusionRequestId)`: Returns the current status of a fusion request.
31. `getUserNFTs(address user)`: Returns an array of all token IDs owned by a user (Warning: Can be gas-intensive for many tokens).
32. `getFusionFee()`: Returns the current fee to initiate fusion.

**V. Chainlink VRF Callback:**
33. `rawFulfillRandomness(uint256 requestId, uint256[] memory randomWords)`: Called by the Chainlink VRF Coordinator to deliver randomness. Triggers the fusion fulfillment or failure logic.

**Internal Functions:**
*   `_performFusion`: Handles the logic for a successful fusion (minting Fused NFT, setting data).
*   `_failFusion`: Handles the logic for a failed fusion (inputs already burned).
*   `_validateFusionRecipe`: Checks if a set of inputs matches a recipe (abstracted logic, could check types, attributes, etc.).
*   `_burn`: Internal ERC721 helper to burn a token.
*   `_mint`: Internal ERC721 helper to mint a token.
*   `_beforeTokenTransfer`: ERC721 hook.
*   `_afterTokenTransfer`: ERC721 hook.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol"; // Added for getUserNFTs (less efficient but fulfills function request)
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol"; // Added for withdrawFees
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

// --- Outline and Function Summary ---
//
// This smart contract implements a Non-Fungible Token (NFT) collection where users can fuse existing NFTs ('Base' type)
// based on predefined recipes and a random outcome to create new NFTs ('Fused' type).
//
// Contract: CryptoArtFusion
// Inherits: ERC721, Ownable, Pausable, VRFConsumerBaseV2, ReentrancyGuard (for withdrawFees)
//
// Key Concepts:
// - NFT Types: Base (initial mints), Fused (created via fusion).
// - Fusion Recipes: Define required input NFT types/attributes and potential output details/success chance.
// - Fusion Process: User initiates by providing input NFTs and paying a fee. Randomness is requested via Chainlink VRF.
//   The VRF callback determines success/failure and mints a new NFT or indicates failure (inputs are burned on initiation).
// - Dynamic Metadata: The `tokenURI` can differ based on the NFT's type (Base vs. Fused) and potentially its specific attributes derived from fusion.
// - On-Chain Randomness: Using Chainlink VRF for unpredictable fusion outcomes.
//
// State Variables:
// - _tokenIds: Counter for total minted NFTs.
// - _nftData: Maps tokenId to NFTData struct (type, parents, attributes, fusionRequestId).
// - _fusionRecipes: Maps recipe hash/ID to FusionRecipe struct.
// - _fusionRequests: Maps VRF requestId to FusionRequest struct.
// - _requestIdsByInitiator: Tracks pending requests per user.
// - _fusionFee: Fee required to initiate fusion (in wei).
// - _baseTokenURIPrefix: Base URI for Base NFTs.
// - _fusedTokenURIPrefix: Base URI for Fused NFTs.
// - _dynamicMetadataSource: (Placeholder/Example) Address of a potential external metadata contract.
// - _vrfCoordinator: Address of Chainlink VRF Coordinator.
// - _keyHash: Key hash for Chainlink VRF requests.
// - _callbackGasLimit: Gas limit for Chainlink VRF callback.
// - _s_randomWords: Stores the random words received from VRF.
//
// Structs:
// - NFTData: Stores data specific to each NFT (type, parents, attributes, fusionRequestId).
// - InputRequirement: Defines required properties for an input NFT in a recipe.
// - FusionRecipe: Defines a recipe (inputs, output chance, output attributes, fee is checked on initiation, but recipe stores outcome data).
// - FusionRequest: Tracks a pending/completed fusion request (initiator, inputs, outputId, status, VRF requestId).
//
// Enums:
// - NFTType: Base, Fused.
// - FusionStatus: Pending, Fulfilled, Failed, Claimed.
//
// Events:
// - BaseNFTMinted: When a Base NFT is minted.
// - FusionRecipeDefined: When a fusion recipe is added/updated.
// - FusionInitiated: When a user starts a fusion process.
// - FusionFulfilled: When VRF callback processes a successful fusion.
// - FusionFailed: When VRF callback processes a failed fusion.
// - FusedNFTClaimed: When a user claims their resulting Fused NFT.
//
// Functions:
// I. Core ERC-721 Standard Functions (Overridden/Implemented):
// 1. constructor(string name, string symbol, address initialOwner, address vrfCoordinator, bytes32 keyHash, uint32 callbackGasLimit)
// 2. balanceOf(address owner)
// 3. ownerOf(uint256 tokenId)
// 4. transferFrom(address from, address to, uint256 tokenId)
// 5. safeTransferFrom(address from, address to, uint256 tokenId)
// 6. safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
// 7. approve(address to, uint256 tokenId)
// 8. setApprovalForAll(address operator, bool approved)
// 9. getApproved(uint256 tokenId)
// 10. isApprovedForAll(address owner, address operator)
// 11. tokenURI(uint256 tokenId)
// 12. supportsInterface(bytes4 interfaceId)
//
// II. Owner/Administrative Functions:
// 13. mintBaseNFT(address to, uint256[] memory attributes)
// 14. defineFusionRecipe(bytes32 recipeId, InputRequirement[] memory inputs, uint16 successChanceBP, uint256[] memory outputAttributeValues)
// 15. setFusionFee(uint256 fee)
// 16. setBaseTokenURIPrefix(string memory prefix)
// 17. setFusedTokenURIPrefix(string memory prefix)
// 18. setDynamicMetadataSource(address source)
// 19. setVRFConfig(address coordinator, bytes32 keyHash, uint32 callbackGasLimit)
// 20. withdrawFees()
// 21. pause()
// 22. unpause()
// 23. transferOwnership(address newOwner)
//
// III. User Interaction Functions:
// 24. initiateFusion(uint256[] memory inputTokenIds, bytes32 recipeId)
// 25. claimFusedNFT(uint256 fusionRequestId)
//
// IV. View/Query Functions:
// 26. getNFTDetails(uint256 tokenId)
// 27. getNFTType(uint256 tokenId)
// 28. viewFusionRecipe(bytes32 recipeId)
// 29. viewPossibleFusions(uint256[] memory userOwnedTokenIds) // Simplified version, takes tokenIds as input
// 30. getFusionRequestStatus(uint256 fusionRequestId)
// 31. getUserNFTs(address user)
// 32. getFusionFee()
//
// V. Chainlink VRF Callback:
// 33. rawFulfillRandomness(uint256 requestId, uint256[] memory randomWords)
//
// Internal Functions:
// - _performFusion: Handles successful fusion.
// - _failFusion: Handles failed fusion (inputs already burned).
// - _validateFusionRecipe: Checks inputs against a recipe.
// - _burn: ERC721 helper.
// - _mint: ERC721 helper.
// - _beforeTokenTransfer, _afterTokenTransfer: ERC721 hooks.

// --- Custom Errors ---
error InvalidFusionRecipe();
error NotFusionInitiator();
error FusionRequestNotFound();
error FusionRequestNotFulfilled();
error FusionRequestStatusInvalid(FusionStatus currentStatus);
error InsufficientFee(uint256 requiredFee, uint256 sentFee);
error InvalidInputNFTs(uint256 tokenId, string reason);
error CannotFuseFusedNFTs();
error RecipeInputMismatch();
error RecipeDoesNotExist();
error VRFConfigNotSet();
error RandomnessNotReceived();
error NoFeesToWithdraw();

// --- Interfaces ---
interface IDynamicMetadata {
    function tokenURI(uint256 tokenId, NFTData memory data) external view returns (string memory);
}

contract CryptoArtFusion is ERC721Enumerable, Ownable, Pausable, VRFConsumerBaseV2, ReentrancyGuard { // Added Enumerable & ReentrancyGuard

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    enum NFTType { Base, Fused }
    enum FusionStatus { Pending, Fulfilled, Failed, Claimed } // Claimed added to prevent double claiming

    struct InputRequirement {
        NFTType requiredType;
        // Add more complex requirements here, e.g., attribute ranges, specific trait hashes
        // Example: bytes32 requiredAttributeHash;
    }

    struct FusionRecipe {
        InputRequirement[] inputs;
        uint16 successChanceBP; // Success chance in Basis Points (0-10000)
        uint256[] outputAttributeValues; // Attributes for the resulting Fused NFT
        bool isActive; // Allow disabling recipes
    }

    struct NFTData {
        NFTType type_;
        uint256[] parents; // TokenIds of NFTs fused to create this one (only for Fused)
        uint256[] attributes; // Example attributes (can be anything, e.g., [strength, speed, color])
        uint256 fusionRequestId; // Request ID that created this NFT (only for Fused)
    }

    struct FusionRequest {
        address initiator;
        uint256[] inputTokenIds; // The actual tokens used
        uint256 outputTokenId; // The token created if successful
        FusionStatus status;
        uint256 vrfRequestId;
        bytes32 recipeId; // Keep track of the recipe used
    }

    // State variables
    mapping(uint256 => NFTData) private _nftData;
    mapping(bytes32 => FusionRecipe) private _fusionRecipes;
    mapping(uint256 => FusionRequest) private _fusionRequests; // Map VRF requestId to FusionRequest
    mapping(address => uint256[]) private _requestIdsByInitiator; // Track request IDs per user

    uint256 private _fusionFee; // Fee in wei to initiate a fusion
    string private _baseTokenURIPrefix;
    string private _fusedTokenURIPrefix;
    address private _dynamicMetadataSource; // Address of a contract that handles dynamic metadata

    bytes32 private _keyHash;
    uint32 private _callbackGasLimit;

    // VRF variables - these are managed by VRFConsumerBaseV2, but we might store the latest random words
    // uint256[] public s_randomWords; // Inherited and updated by VRFConsumerBaseV2

    // Events
    event BaseNFTMinted(address indexed to, uint256 indexed tokenId, uint256[] attributes);
    event FusionRecipeDefined(bytes32 indexed recipeId, InputRequirement[] inputs, uint16 successChanceBP, uint256[] outputAttributeValues, bool isActive);
    event FusionInitiated(address indexed initiator, uint256 indexed requestId, uint256[] inputTokenIds, bytes32 indexed recipeId);
    event FusionFulfilled(uint256 indexed requestId, uint256 indexed outputTokenId, uint256[] attributes);
    event FusionFailed(uint256 indexed requestId, uint256[] inputTokenIds); // Inputs are already burned
    event FusedNFTClaimed(uint256 indexed requestId, address indexed owner, uint256 indexed tokenId);

    /// @dev Constructor initializes the contract.
    /// @param name_ ERC721 collection name.
    /// @param symbol_ ERC721 collection symbol.
    /// @param initialOwner Owner address.
    /// @param vrfCoordinator Address of the Chainlink VRF Coordinator.
    /// @param keyHash Key hash for VRF requests.
    /// @param callbackGasLimit Gas limit for the VRF callback function.
    constructor(
        string memory name_,
        string memory symbol_,
        address initialOwner,
        address vrfCoordinator,
        bytes32 keyHash,
        uint32 callbackGasLimit
    )
        ERC721(name_, symbol_)
        Ownable(initialOwner)
        Pausable()
        VRFConsumerBaseV2(vrfCoordinator)
    {
        _vrfCoordinator = vrfCoordinator;
        _keyHash = keyHash;
        _callbackGasLimit = callbackGasLimit;
        _fusionFee = 0; // Set fee later via setFusionFee
        _baseTokenURIPrefix = ""; // Set later
        _fusedTokenURIPrefix = ""; // Set later
    }

    // --- I. Core ERC-721 Standard Functions ---

    // balanceOf, ownerOf, getApproved, isApprovedForAll, setApprovalForAll are inherited from ERC721
    // transferFrom, safeTransferFrom are inherited and use _beforeTokenTransfer/_afterTokenTransfer hooks

    /// @dev See {IERC721Metadata-tokenURI}. Returns dynamic URI based on NFT data.
    /// @param tokenId The token ID to query.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) {
            revert ERC721NonexistentToken(tokenId);
        }

        NFTData storage data = _nftData[tokenId];
        string memory baseURI;

        if (data.type_ == NFTType.Base) {
            baseURI = _baseTokenURIPrefix;
        } else if (data.type_ == NFTType.Fused) {
            baseURI = _fusedTokenURIPrefix;
        } else {
            // Should not happen with current logic, but good practice
            baseURI = "";
        }

        if (bytes(baseURI).length == 0) {
             return ""; // No base URI set
        }

        // Optionally integrate a dynamic metadata source contract
        if (_dynamicMetadataSource != address(0)) {
             try IDynamicMetadata(_dynamicMetadataSource).tokenURI(tokenId, data) returns (string memory dynamicURI) {
                 if (bytes(dynamicURI).length > 0) {
                     return dynamicURI;
                 }
             } catch {} // Fallback to default if call fails or returns empty
        }

        // Default URI structure: baseURI + tokenId.json
        return string(abi.encodePacked(baseURI, Strings.toString(tokenId), ".json"));
    }

    /// @dev See {ERC165-supportsInterface}. Overridden to support ERC721Enumerable.
    /// @param interfaceId The interface identifier, as defined in ERC-165.
    function supportsInterface(bytes4 interfaceId) public view override(ERC721Enumerable, VRFConsumerBaseV2) returns (bool) {
        // Also supports ERC721Enumerable and VRFConsumerBaseV2 interfaces
        return super.supportsInterface(interfaceId);
    }

    // --- II. Owner/Administrative Functions ---

    /// @dev Mints a new Base type NFT. Only owner can call.
    /// @param to The recipient address.
    /// @param attributes Initial attributes for the NFT.
    function mintBaseNFT(address to, uint256[] memory attributes) external onlyOwner whenNotPaused {
        uint256 newTokenId = _tokenIds.current();
        _tokenIds.increment();
        _mint(to, newTokenId);
        _nftData[newTokenId] = NFTData({
            type_: NFTType.Base,
            parents: new uint256[](0),
            attributes: attributes,
            fusionRequestId: 0 // Not created by fusion
        });
        emit BaseNFTMinted(to, newTokenId, attributes);
    }

    /// @dev Defines or updates a fusion recipe. Only owner can call.
    /// @param recipeId A unique identifier for the recipe.
    /// @param inputs Array of InputRequirement structs defining needed input types/attributes.
    /// @param successChanceBP Success chance in basis points (e.g., 5000 for 50%). Max 10000.
    /// @param outputAttributeValues Attributes for the resulting Fused NFT on success.
    function defineFusionRecipe(
        bytes32 recipeId,
        InputRequirement[] memory inputs,
        uint16 successChanceBP,
        uint256[] memory outputAttributeValues // Could be based on inputs or fixed
    ) external onlyOwner {
        require(successChanceBP <= 10000, "Success chance cannot exceed 10000 BP");
        _fusionRecipes[recipeId] = FusionRecipe({
            inputs: inputs,
            successChanceBP: successChanceBP,
            outputAttributeValues: outputAttributeValues,
            isActive: true
        });
        emit FusionRecipeDefined(recipeId, inputs, successChanceBP, outputAttributeValues, true);
    }

    /// @dev Sets the fee required to initiate a fusion. Only owner can call.
    /// @param fee The new fusion fee in wei.
    function setFusionFee(uint256 fee) external onlyOwner {
        _fusionFee = fee;
    }

    /// @dev Sets the base URI prefix for Base NFTs. Only owner can call.
    /// @param prefix The new base URI prefix.
    function setBaseTokenURIPrefix(string memory prefix) external onlyOwner {
        _baseTokenURIPrefix = prefix;
    }

    /// @dev Sets the base URI prefix for Fused NFTs. Only owner can call.
    /// @param prefix The new base URI prefix.
    function setFusedTokenURIPrefix(string memory prefix) external onlyOwner {
        _fusedTokenURIPrefix = prefix;
    }

    /// @dev Sets the address of a dynamic metadata source contract. Only owner can call.
    /// @param source The address of the dynamic metadata contract.
    function setDynamicMetadataSource(address source) external onlyOwner {
        _dynamicMetadataSource = source;
    }

    /// @dev Sets the Chainlink VRF configuration. Only owner can call.
    /// @param coordinator Address of the Chainlink VRF Coordinator.
    /// @param keyHash Key hash for VRF requests.
    /// @param callbackGasLimit Gas limit for the VRF callback function.
    function setVRFConfig(address coordinator, bytes32 keyHash, uint32 callbackGasLimit) external onlyOwner {
        _vrfCoordinator = coordinator;
        _keyHash = keyHash;
        _callbackGasLimit = callbackGasLimit;
    }

    /// @dev Withdraws collected fusion fees. Only owner can call. Uses ReentrancyGuard.
    function withdrawFees() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        if (balance == 0) {
            revert NoFeesToWithdraw();
        }
        (bool success, ) = owner().call{value: balance}("");
        require(success, "Withdrawal failed");
    }

    /// @dev Pauses transfers and fusion initiation. Only owner can call.
    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    /// @dev Unpauses the contract. Only owner can call.
    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    // transferOwnership is inherited from Ownable

    // --- III. User Interaction Functions ---

    /// @dev Initiates a fusion process using specified input NFTs and recipe.
    /// The sender must own and have approved the contract for all input NFTs.
    /// Requires payment of the fusion fee. Burns input NFTs and requests VRF randomness.
    /// @param inputTokenIds Array of token IDs to be used as input for fusion.
    /// @param recipeId The ID of the fusion recipe to attempt.
    /// @return requestId The VRF request ID associated with this fusion attempt.
    function initiateFusion(uint256[] memory inputTokenIds, bytes32 recipeId)
        external
        payable
        whenNotPaused
        returns (uint256 requestId)
    {
        if (_vrfCoordinator == address(0) || _keyHash == bytes32(0) || _callbackGasLimit == 0) {
             revert VRFConfigNotSet();
        }

        if (msg.value < _fusionFee) {
            revert InsufficientFee({requiredFee: _fusionFee, sentFee: msg.value});
        }

        if (inputTokenIds.length == 0) {
            revert InvalidInputNFTs(0, "No input tokens provided");
        }

        FusionRecipe storage recipe = _fusionRecipes[recipeId];
        if (!recipe.isActive) {
             revert RecipeDoesNotExist();
        }

        if (inputTokenIds.length != recipe.inputs.length) {
            revert RecipeInputMismatch();
        }

        // Basic validation and burning of input NFTs
        address initiator = msg.sender;
        for (uint i = 0; i < inputTokenIds.length; i++) {
            uint256 tokenId = inputTokenIds[i];

            if (!_exists(tokenId)) {
                revert InvalidInputNFTs(tokenId, "Does not exist");
            }
            if (ownerOf(tokenId) != initiator) {
                revert InvalidInputNFTs(tokenId, "Not owned by initiator");
            }
            if (getApproved(tokenId) != address(this) && !isApprovedForAll(initiator, address(this))) {
                revert InvalidInputNFTs(tokenId, "Contract not approved");
            }

            // Check NFT type requirement (basic version)
            NFTData storage inputData = _nftData[tokenId];
            if (inputData.type_ != recipe.inputs[i].requiredType) {
                 // Add more complex attribute checks here if InputRequirement had more fields
                 revert RecipeInputMismatch();
            }
            // Prevent fusing Fused NFTs if the recipe requires Base (example rule)
            if (inputData.type_ == NFTType.Fused) { // Example restriction
                 revert CannotFuseFusedNFTs();
            }

            // Burn the input token immediately
            _burn(tokenId);
            // Note: NFTData is not deleted but the token no longer exists according to ERC721
            // We store inputTokenIds in the request for history/failure event, even if burned.
        }

        // Request randomness
        VRFCoordinatorV2Interface COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
        requestId = COORDINATOR.requestRandomWords(
            _keyHash,
            0, // request_confirmations
            _callbackGasLimit,
            1 // numWords
        );

        // Store fusion request details
        _fusionRequests[requestId] = FusionRequest({
            initiator: initiator,
            inputTokenIds: inputTokenIds, // Store burned token IDs for history
            outputTokenId: 0, // Will be set on fulfillment
            status: FusionStatus.Pending,
            vrfRequestId: requestId,
            recipeId: recipeId
        });

        _requestIdsByInitiator[initiator].push(requestId);

        emit FusionInitiated(initiator, requestId, inputTokenIds, recipeId);

        return requestId;
    }

    /// @dev Allows the initiator of a *fulfilled* fusion request to claim the resulting Fused NFT.
    /// @param fusionRequestId The VRF request ID of the completed fusion.
    function claimFusedNFT(uint256 fusionRequestId) external whenNotPaused {
        FusionRequest storage request = _fusionRequests[fusionRequestId];

        if (request.initiator == address(0)) {
            revert FusionRequestNotFound();
        }
        if (request.initiator != msg.sender) {
            revert NotFusionInitiator();
        }
        if (request.status != FusionStatus.Fulfilled) {
             revert FusionRequestNotFulfilled();
        }

        uint256 outputTokenId = request.outputTokenId;

        if (!_exists(outputTokenId)) {
             revert FusionRequestNotFulfilled(); // Should not happen if status is Fulfilled
        }

        // Transfer the NFT from the contract (owner is this contract after minting) to the initiator
        _safeTransfer(address(this), msg.sender, outputTokenId);

        request.status = FusionStatus.Claimed; // Mark as claimed

        emit FusedNFTClaimed(fusionRequestId, msg.sender, outputTokenId);
    }

    // --- IV. View/Query Functions ---

    /// @dev Returns detailed information about a specific NFT.
    /// @param tokenId The token ID to query.
    /// @return owner_ The owner's address.
    /// @return type_ The NFT type (Base or Fused).
    /// @return parents The token IDs of parent NFTs (empty for Base).
    /// @return attributes The NFT's attributes.
    /// @return fusionRequestId The request ID that created this NFT (0 for Base or if not set).
    function getNFTDetails(uint256 tokenId)
        public
        view
        returns (address owner_, NFTType type_, uint256[] memory parents, uint256[] memory attributes, uint256 fusionRequestId)
    {
        owner_ = ownerOf(tokenId); // This will revert if token doesn't exist
        NFTData storage data = _nftData[tokenId];
        type_ = data.type_;
        parents = data.parents;
        attributes = data.attributes;
        fusionRequestId = data.fusionRequestId;
    }

    /// @dev Returns the type of a specific NFT.
    /// @param tokenId The token ID to query.
    /// @return The NFTType (Base or Fused).
    function getNFTType(uint256 tokenId) public view returns (NFTType) {
         if (!_exists(tokenId)) {
             revert ERC721NonexistentToken(tokenId);
         }
         return _nftData[tokenId].type_;
    }

    /// @dev Returns the details of a specific fusion recipe.
    /// @param recipeId The ID of the recipe.
    /// @return inputs Array of InputRequirement structs.
    /// @return successChanceBP Success chance in basis points.
    /// @return outputAttributeValues Attributes for resulting Fused NFT.
    /// @return isActive Whether the recipe is currently active.
    function viewFusionRecipe(bytes32 recipeId)
        public
        view
        returns (InputRequirement[] memory inputs, uint16 successChanceBP, uint256[] memory outputAttributeValues, bool isActive)
    {
        FusionRecipe storage recipe = _fusionRecipes[recipeId];
        if (!recipe.isActive) {
             revert RecipeDoesNotExist();
        }
        return (recipe.inputs, recipe.successChanceBP, recipe.outputAttributeValues, recipe.isActive);
    }

     /// @dev Returns potential fusion recipes a user could perform with the provided token IDs.
     /// This is a basic check based on owned token types matching recipe requirements.
     /// NOTE: This function can be gas-intensive depending on the number of owned tokens and recipes.
     /// A more robust implementation or off-chain calculation is recommended for large collections/recipes.
     /// @param userOwnedTokenIds Array of token IDs owned by the user.
     /// @return An array of recipe IDs that the user potentially has inputs for.
    function viewPossibleFusions(uint256[] memory userOwnedTokenIds) public view returns (bytes32[] memory) {
        // This is a simplified view function. A real-world scenario would need
        // to check if *specific combinations* of owned tokens match recipes,
        // which is complex and gas-heavy on-chain. This version just checks
        // if the user *has* tokens matching the required types for *any* recipe.

        bytes32[] memory possibleRecipes = new bytes32[](0);
        // Iterating through all recipes might be too gas heavy.
        // For demonstration, let's assume we have a known list of recipeIds to check against.
        // In practice, you'd need a way to get active recipe IDs (e.g., a mapping or array of IDs).
        // For this example, let's just return an empty array as finding *matching sets* is complex.
        // A practical approach would be off-chain indexing of recipes and user inventories.
        // Returning empty for simplicity and gas awareness in this example.
        // If you had a fixed, small number of recipes you could iterate `_fusionRecipes` keys,
        // but Solidity mappings don't easily expose keys.
        // To actually implement this fully on-chain would require iterating all recipes
        // and all combinations of user tokens, which is prohibitive.

        // Placeholder for a more complex check if needed:
        // for (bytes32 recipeId : allRecipeIds) { // Need a way to get all recipe IDs
        //     FusionRecipe storage recipe = _fusionRecipes[recipeId];
        //     if (!recipe.isActive) continue;
        //     bool potentialMatch = true;
        //     // Complex logic to check if userOwnedTokenIds *contain* a valid set for recipe.inputs
        //     // ...
        //     if (potentialMatch) {
        //         // Add recipeId to possibleRecipes
        //     }
        // }

        return possibleRecipes; // Returning empty as a placeholder due to complexity/gas
    }

    /// @dev Returns the current status of a fusion request.
    /// @param fusionRequestId The VRF request ID.
    /// @return The FusionStatus of the request.
    function getFusionRequestStatus(uint256 fusionRequestId) public view returns (FusionStatus) {
        FusionRequest storage request = _fusionRequests[fusionRequestId];
         if (request.initiator == address(0)) {
            revert FusionRequestNotFound();
        }
        return request.status;
    }

    /// @dev Returns an array of all token IDs owned by a user.
    /// Inherited from ERC721Enumerable.
    /// WARNING: This function can be very gas-intensive for users with many NFTs.
    /// It iterates through all existing token IDs. Use off-chain indexing if possible.
    /// @param user The address to query.
    /// @return An array of token IDs owned by the user.
    function getUserNFTs(address user) public view returns (uint256[] memory) {
        // ERC721Enumerable provides tokenOfOwnerByIndex
        uint256 ownerTokenCount = balanceOf(user);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i = 0; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(user, i);
        }
        return tokenIds;
    }

    /// @dev Returns the current fee to initiate a fusion.
    /// @return The fusion fee in wei.
    function getFusionFee() public view returns (uint256) {
        return _fusionFee;
    }


    // --- V. Chainlink VRF Callback ---

    /// @dev Callback function invoked by the Chainlink VRF Coordinator.
    /// Processes the random words and determines the fusion outcome.
    /// DO NOT CALL THIS FUNCTION DIRECTLY. It can only be called by the VRF Coordinator.
    /// @param requestId The VRF request ID.
    /// @param randomWords Array of random words generated by VRF.
    function rawFulfillRandomness(uint256 requestId, uint256[] memory randomWords)
        internal
        override
    {
        // Ensure the request exists and is pending
        FusionRequest storage request = _fusionRequests[requestId];
         if (request.initiator == address(0)) {
            revert FusionRequestNotFound(); // Should not happen if Coordinator calls correctly
        }
        if (request.status != FusionStatus.Pending) {
             revert FusionRequestStatusInvalid(request.status); // Should not happen
        }
        if (randomWords.length == 0) {
            revert RandomnessNotReceived(); // Should not happen with 1 requested word
        }

        _s_randomWords = randomWords; // Store random words if needed elsewhere

        // Get the recipe used for this request
        FusionRecipe storage recipe = _fusionRecipes[request.recipeId];
        // Basic sanity check (recipe should exist if request exists)
        if (!recipe.isActive) {
            _failFusion(requestId); // Treat as failure if recipe disappeared/deactivated
            return;
        }

        // Determine success based on random word and recipe success chance
        // Random word is uint256. Modulo 10000 gives a result in [0, 9999].
        uint256 randomResult = randomWords[0] % 10000;

        if (randomResult < recipe.successChanceBP) {
            // Fusion Success
            _performFusion(requestId, recipe.outputAttributeValues, request.inputTokenIds);
        } else {
            // Fusion Failure
            _failFusion(requestId);
        }
    }

    // --- Internal Helper Functions ---

    /// @dev Performs the actions for a successful fusion.
    /// Mints a new Fused NFT and updates the fusion request state.
    /// @param requestId The VRF request ID.
    /// @param outputAttributeValues Attributes for the new Fused NFT.
    /// @param parents The token IDs of the input NFTs (already burned).
    function _performFusion(uint256 requestId, uint256[] memory outputAttributeValues, uint256[] memory parents) internal {
        FusionRequest storage request = _fusionRequests[requestId];

        uint256 newTokenId = _tokenIds.current();
        _tokenIds.increment();

        // Mint the new Fused NFT to the *contract* initially
        _mint(address(this), newTokenId);

        // Store NFT data
        _nftData[newTokenId] = NFTData({
            type_: NFTType.Fused,
            parents: parents, // Store parents for history/metadata
            attributes: outputAttributeValues,
            fusionRequestId: requestId
        });

        // Update request state
        request.outputTokenId = newTokenId;
        request.status = FusionStatus.Fulfilled;

        emit FusionFulfilled(requestId, newTokenId, outputAttributeValues);
    }

    /// @dev Handles the actions for a failed fusion.
    /// Input NFTs were already burned in initiateFusion. This function primarily updates state and emits event.
    /// @param requestId The VRF request ID.
    function _failFusion(uint256 requestId) internal {
        FusionRequest storage request = _fusionRequests[requestId];

        // Input NFTs are already burned in initiateFusion.
        // We just update the request status.

        request.status = FusionStatus.Failed;

        emit FusionFailed(requestId, request.inputTokenIds);
    }

    /// @dev Validates if a given set of token IDs matches the input requirements of a recipe.
    /// This is a placeholder logic. Real-world implementation would check attributes, types, etc.
    /// Assumes `inputTokenIds` and `recipe.inputs` are the same length (checked in initiateFusion).
    /// @param inputTokenIds The actual token IDs used as input.
    /// @param recipe The FusionRecipe to check against.
    /// @return bool True if the inputs match the recipe requirements.
    function _validateFusionRecipe(uint256[] memory inputTokenIds, FusionRecipe storage recipe) internal view returns (bool) {
        // This implementation only checks that *a* recipe exists with this structure.
        // A more advanced check would ensure the *specific* NFTs passed as input
        // match the *specific* requirements (e.g., type, attributes) outlined in `recipe.inputs`.
        // For this example, we simply check if the recipe exists and is active,
        // and that the input array length matches the recipe's input length (done in initiateFusion).
        // More complex validation logic would go here, potentially iterating through inputs
        // and comparing _nftData[tokenId] against recipe.inputs[i].

        return recipe.isActive; // Simplified validation
    }

    // _mint, _burn, _beforeTokenTransfer, _afterTokenTransfer are standard ERC721 internal functions,
    // used by OpenZeppelin's ERC721 implementation and hooks for custom logic.
    // _beforeTokenTransfer is used here to prevent transfers when paused.

    /// @dev See {ERC721-_beforeTokenTransfer}.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721Enumerable) // Use ERC721Enumerable's hook
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize); // Call parent hook first

        // Prevent transfers when paused, except for the zero address (minting/burning)
        if (from != address(0) && to != address(0)) {
            require(!paused(), "Pausable: paused");
        }

        // Custom logic: Prevent transferring NFTs that are currently part of a pending fusion request
        // Find the request associated with this token if it's an input
        // This requires iterating through pending requests or mapping tokenIds to requests, which is complex.
        // A simpler approach used here is that inputs are burned *before* the request is finalized,
        // so they cannot be transferred while pending.
        // For Fused NFTs (outputTokenId), they are owned by the contract until claimed,
        // so they also cannot be transferred by the user while pending claim.

    }

    // No specific custom logic needed in _afterTokenTransfer for this example.
}
```

---

**Explanation of Advanced Concepts & Design Choices:**

1.  **NFT Fusion Mechanics:**
    *   The core logic resides in `initiateFusion`, `rawFulfillRandomness`, `_performFusion`, and `_failFusion`.
    *   Input NFTs are immediately burned in `initiateFusion`. This simplifies state management (no need to lock NFTs) but makes failure punitive (inputs are lost). An alternative would be transferring inputs to the contract and burning/returning *after* randomness.
    *   Fusion recipes (`defineFusionRecipe`) introduce a crafting system. Recipes can be based on abstract `InputRequirement`s (like `NFTType`) or could be extended to check specific attributes of the input NFTs, creating complex combinatorial possibilities.
    *   The resulting Fused NFT stores its `parents` (the burned input token IDs) in its `NFTData`. This creates a lineage or history chain, adding depth.

2.  **Chainlink VRF Integration:**
    *   Inherits `VRFConsumerBaseV2` and implements `rawFulfillRandomness`.
    *   `initiateFusion` requests randomness after inputs are handled.
    *   The VRF callback (`rawFulfillRandomness`) is the *only* way the fusion outcome is determined, ensuring it's unpredictable on-chain.
    *   The outcome (success/failure) is calculated directly from the `randomWords` and the recipe's `successChanceBP`.
    *   Successful fusions mint the new NFT to the *contract address* initially (`_mint(address(this), newTokenId)`). The user must call `claimFusedNFT` to receive it. This separates the random outcome step from the transfer step.

3.  **Dynamic Metadata (`tokenURI`):**
    *   The `tokenURI` function is overridden to return different base URIs based on the NFT `type_` (Base or Fused).
    *   It includes a placeholder (`_dynamicMetadataSource`) for an external contract that could provide even more dynamic metadata based on the `NFTData` struct (e.g., attributes, fusion history). This offloads complex JSON generation or image rendering logic off-chain while allowing the smart contract to signal *where* that dynamic data can be found.

4.  **State Management (`FusionRequest`, `_fusionRequests`):**
    *   The `FusionRequest` struct tracks the entire lifecycle of a fusion attempt (Pending -> Fulfilled/Failed -> Claimed).
    *   Mapping `requestId` to `FusionRequest` allows the VRF callback to easily access the context of the request it's fulfilling.
    *   Mapping `initiator` to `_requestIdsByInitiator` (though only pushing in this example) hints at how a user could query *their* pending requests, although iterating this array on-chain could be costly.

5.  **Gas Considerations:**
    *   `getUserNFTs` (via ERC721Enumerable) and potentially a fully implemented `viewPossibleFusions` can be gas-intensive. The code includes warnings or simplified implementations for these, acknowledging that off-chain indexing or helper contracts might be needed in production.
    *   Burning NFTs *before* VRF fulfillment in `initiateFusion` avoids the need to complex locking/unlocking logic based on the outcome, potentially saving gas on callback paths.

6.  **Access Control & Safety:**
    *   `Ownable` for admin functions.
    *   `Pausable` for emergency halting of transfers and fusion initiation.
    *   `ReentrancyGuard` on `withdrawFees` as it involves transferring ETH out.
    *   Custom errors provide specific reasons for transaction failures.
    *   Input validation in `initiateFusion` checks ownership, approvals, and basic recipe match.

This contract demonstrates a more complex NFT interaction pattern than simple minting and transferring, integrating external services (VRF) and internal crafting mechanics. It provides a foundation for game assets, evolving collectibles, or other interactive NFT experiences.