Okay, here is a concept for a smart contract called `DecentralizedArtFoundry`.

This contract blends concepts of:
1.  **NFTs:** Managing multiple types of NFTs within one contract (Catalysts and Masterpieces).
2.  **Resource Management:** Introducing a fungible token (Essence) as fuel.
3.  **Staking:** Catalysts can be staked to yield Essence.
4.  **Forging/Crafting:** Combining NFTs (Catalysts) and a fungible token (Essence) to create a new, dynamic NFT (Masterpiece).
5.  **Dynamic Traits:** Masterpiece traits are generated based on input Catalysts, Essence used, and blockchain data at the time of forging.
6.  **Refinement/Enhancement:** Mechanisms to upgrade Catalysts or modify Masterpieces post-creation.
7.  **Binding/Soulbound-like Mechanics:** Used Catalysts can become "bound" to the resulting Masterpiece instead of being burned, adding provenance and affecting traits.

This aims to be more complex than a standard ERC721 minting contract or basic staking.

---

### DecentralizedArtFoundry Smart Contract Outline & Function Summary

**Contract Name:** `DecentralizedArtFoundry`

**Concept:** A platform where users collect Catalyst NFTs, stake them to earn Essence tokens, and use both Catalysts and Essence to forge unique Masterpiece NFTs with dynamic traits.

**Key Assets:**
1.  **Catalyst NFTs (ERC721):** Ingredients or tools for forging. Different types exist. Can be staked.
2.  **Essence (ERC20-like):** A fungible token representing energy or fuel. Earned by staking Catalysts. Required for forging and enhancement.
3.  **Masterpiece NFTs (ERC721):** The final artworks. Traits are dynamically generated during forging based on inputs. Can potentially be enhanced.

**Key Processes:**
*   **Catalyst Minting:** Initial distribution or minting mechanism for Catalysts.
*   **Staking:** Locking Catalysts to earn Essence over time.
*   **Claiming Essence:** Collecting earned Essence.
*   **Forging:** Combining specific Catalysts (bound to the Masterpiece) and Essence to create a new Masterpiece.
*   **Dynamic Trait Generation:** Masterpiece traits are determined algorithmically based on forging inputs and block data.
*   **Masterpiece Enhancement:** Spending more Essence to potentially alter a Masterpiece's traits after creation.
*   **Catalyst Refinement:** Burning multiple lower-tier Catalysts to mint a higher-tier one.
*   **Admin/Control:** Functions for setting parameters, withdrawing funds/assets, pausing.

**Function Summary (25+ public/external functions, including inherited/overridden essentials):**

*   **ERC721 Standard Functions (for managing both Catalysts and Masterpieces - differentiator is internal state/metadata):**
    1.  `balanceOf(address owner)`: Get balance of NFTs owned by address.
    2.  `ownerOf(uint256 tokenId)`: Get owner of an NFT.
    3.  `transferFrom(address from, address to, uint256 tokenId)`: Transfer NFT ownership.
    4.  `safeTransferFrom(...)`: Safe transfer NFT ownership (overloaded).
    5.  `approve(address to, uint256 tokenId)`: Approve an address to manage an NFT.
    6.  `setApprovalForAll(address operator, bool approved)`: Set operator approval for all NFTs.
    7.  `getApproved(uint256 tokenId)`: Get approved address for a specific NFT.
    8.  `isApprovedForAll(address owner, address operator)`: Check operator approval status.
    9.  `tokenURI(uint256 tokenId)`: Get metadata URI for an NFT (dynamically determines if Catalyst or Masterpiece).

*   **ERC20-like Standard Functions (for Essence):**
    10. `balanceOfEssence(address owner)`: Get Essence balance.
    11. `transferEssence(address recipient, uint256 amount)`: Transfer Essence.
    12. `approveEssence(address spender, uint256 amount)`: Approve spender for Essence.
    13. `allowanceEssence(address owner, address spender)`: Get spender allowance for Essence.
    14. `transferFromEssence(address sender, address recipient, uint256 amount)`: Transfer Essence using allowance.
    15. `totalSupplyEssence()`: Get total supply of Essence.

*   **Catalyst Management:**
    16. `mintCatalyst(address recipient, uint256 catalystType)`: Admin function to mint new Catalysts.
    17. `setCatalystBaseURI(string memory baseURI)`: Admin function to set base URI for Catalyst metadata.
    18. `getCatalystDetails(uint256 tokenId)`: Get details of a specific Catalyst (type, owner, staked status).
    19. `refineCatalysts(uint256[] calldata catalystTokenIds, uint256 targetCatalystType)`: Burn specified low-tier Catalysts to mint a higher-tier one.

*   **Essence Staking:**
    20. `stakeCatalyst(uint256 tokenId)`: Stake a Catalyst NFT to earn Essence.
    21. `unstakeCatalyst(uint256 tokenId)`: Unstake a Catalyst NFT.
    22. `claimEssence()`: Claim all pending Essence rewards for the caller.
    23. `getPendingEssence(address staker)`: View function to calculate pending Essence for a staker.
    24. `getCatalystStakeInfo(uint256 tokenId)`: View function to get staking details for a specific Catalyst.

*   **Masterpiece Forging & Enhancement:**
    25. `forgeMasterpiece(uint256[] calldata catalystTokenIds, uint256 essenceAmount)`: Forge a new Masterpiece using specified Catalysts and Essence. Catalysts get bound. Traits are generated.
    26. `enhanceMasterpiece(uint256 masterpieceTokenId, uint256 additionalEssenceAmount)`: Enhance an existing Masterpiece by spending more Essence, potentially altering traits.
    27. `getMasterpieceDetails(uint256 tokenId)`: Get details of a specific Masterpiece (bound catalysts, traits).
    28. `getForgingRequirements(uint256 masterpieceType)`: View function to see what's required for a specific type of Masterpiece forge (if types are defined).

*   **Admin & Configuration:**
    29. `setEssencePerBlock(uint256 amount)`: Admin function to set the Essence yield rate per block per staked Catalyst.
    30. `setForgingCost(uint256 requiredEssence, uint256[] calldata requiredCatalystTypes)`: Admin function to set requirements for forging (simplified: single cost/type requirement set globally for example). *Self-correction: Forcing specific *types* of catalysts is more interesting.* Let's make this specific to *combinations*.
    31. `setForgingRecipe(uint256 masterpieceType, uint256 requiredEssence, uint256[] calldata requiredCatalystTypes)`: Admin function to define a recipe for a specific Masterpiece type.
    32. `addAllowedCatalystType(uint256 catalystType)`: Admin function to register a valid Catalyst type.
    33. `addAllowedMasterpieceType(uint256 masterpieceType)`: Admin function to register a valid Masterpiece type.
    34. `withdrawERC20(address tokenAddress, uint256 amount)`: Admin function to withdraw other ERC20 tokens sent to the contract.
    35. `withdrawERC721(address tokenAddress, uint256 tokenId)`: Admin function to withdraw other ERC721 tokens sent to the contract.
    36. `pauseFoundry()`: Admin function to pause core operations (staking, forging, refining, claims).
    37. `unpauseFoundry()`: Admin function to unpause.
    38. `setMasterpieceBaseURI(string memory baseURI)`: Admin function to set base URI for Masterpiece metadata.
    39. `setRefinementRecipe(uint256[] calldata sourceCatalystTypes, uint256 targetCatalystType)`: Admin function to define a refinement recipe.

*(Okay, that's 39 unique functions planned - well over the 20 required, covering the core concepts and admin controls).*

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // Import for withdrawing other ERC20s

// Custom structs for data
struct CatalystDetails {
    uint256 tokenID; // Redundant but useful for clarity sometimes
    uint256 catalystType;
    bool isStaked;
    address currentOwner; // Stored for lookup ease, updated on transfers/stakes
}

struct MasterpieceDetails {
    uint256 tokenID; // Redundant
    uint256[] boundCatalystTokenIds; // IDs of Catalysts used and bound
    uint256 essenceUsed; // Total essence spent (initial + enhancement)
    // Store dynamic traits directly, or a hash pointing to off-chain data
    // For on-chain simplicity, let's just store a few key traits derived from inputs
    uint256[] dynamicTraits; // e.g., [ColorCode, TextureCode, ShapeCode, EffectIntensity]
    // In a real app, this would likely be more complex and generated off-chain based on data inputs,
    // with the contract storing a hash or seed. For this example, we'll simulate simple on-chain generation.
    uint256 creationBlock;
    uint256 creationTimestamp;
}

struct CatalystStakeInfo {
    uint48 lastRewardBlock; // Using uint48 to save gas/storage if block numbers fit
    uint256 accumulatedEssence;
}

struct ForgingRecipe {
    uint256 requiredEssence;
    uint256[] requiredCatalystTypes; // Specific types required for this recipe
    // Could add required amounts of each type: mapping(uint256 => uint256) requiredTypeAmounts;
    // For simplicity, assume unique types are required, count matters based on array length.
}

struct RefinementRecipe {
    uint256[] sourceCatalystTypes; // e.g., [1, 1, 1] for three Type 1 catalysts
    uint256 targetCatalystType;    // e.g., 2 for one Type 2 catalyst
    // Could add essence cost for refinement
}


contract DecentralizedArtFoundry is ERC721, Ownable, ReentrancyGuard, Pausable, IERC721Receiver {
    using Counters for Counters.Counter;

    // --- NFT Counters ---
    Counters.Counter private _tokenIdCounter; // Single counter for both types, differentiate via mappings

    // --- Configuration ---
    string private _catalystBaseURI;
    string private _masterpieceBaseURI;

    uint256 public essencePerBlockPerCatalyst = 100; // Amount of Essence per block per staked Catalyst (scaled by decimals later)
    uint256 public constant ESSENCE_DECIMALS = 18; // Essence token decimal places

    // --- Asset State ---
    // ERC721 state is handled by inheritance. We need to track WHICH tokenID is which type.
    mapping(uint256 => CatalystDetails) private _catalystDetails; // Token ID -> Catalyst Details
    mapping(uint256 => MasterpieceDetails) private _masterpieceDetails; // Token ID -> Masterpiece Details

    mapping(uint256 => bool) public allowedCatalystTypes; // Valid catalyst types (e.g., type 1, 2, 3)
    mapping(uint256 => bool) public allowedMasterpieceTypes; // Valid masterpiece types (e.g., type 1, 2, 3) - if recipes map to types

    mapping(uint256 => ForgingRecipe) public forgingRecipes; // MasterpieceType -> Recipe
    mapping(uint256 => RefinementRecipe) public refinementRecipes; // TargetCatalystType -> Refinement Recipe (assuming 1 recipe per target type)


    // ERC20-like state for Essence
    mapping(address => uint256) private _essenceBalances;
    mapping(address => mapping(address => uint256)) private _essenceAllowances;
    uint256 private _essenceTotalSupply;

    // --- Staking State ---
    mapping(uint256 => CatalystStakeInfo) private _catalystStakeInfo; // Staked Catalyst ID -> Stake Info
    mapping(address => uint256[] ) private _stakedCatalystsByOwner; // Owner -> List of their staked Catalyst IDs
    mapping(uint256 => address) private _stakedCatalystOwner; // Staked Catalyst ID -> Owner (quick lookup)


    // --- Events ---
    event CatalystMinted(address indexed recipient, uint256 indexed tokenId, uint256 catalystType);
    event CatalystStaked(address indexed owner, uint256 indexed tokenId);
    event CatalystUnstaked(address indexed owner, uint256 indexed tokenId);
    event EssenceClaimed(address indexed owner, uint256 amount);
    event MasterpieceForged(address indexed owner, uint256 indexed masterpieceTokenId, uint256[] boundCatalystTokenIds, uint256 essenceUsed);
    event MasterpieceEnhanced(uint256 indexed masterpieceTokenId, uint256 additionalEssenceUsed, uint256[] newTraits);
    event CatalystRefined(address indexed owner, uint256[] burnedCatalystTokenIds, uint256 indexed mintedCatalystTokenId, uint256 targetCatalystType);
    event ForgingRecipeUpdated(uint256 indexed masterpieceType, uint256 requiredEssence, uint256[] requiredCatalystTypes);
    event RefinementRecipeUpdated(uint256 indexed targetCatalystType, uint256[] sourceCatalystTypes);
    event EssenceRateUpdated(uint256 indexed newRatePerBlockPerCatalyst);


    // --- Constructor ---
    constructor(string memory name, string memory symbol)
        ERC721(name, symbol)
        Ownable(msg.sender)
        Pausable()
    {}

    // --- Pausable Overrides ---
    function pauseFoundry() external onlyOwner {
        _pause();
    }

    function unpauseFoundry() external onlyOwner {
        _unpause();
    }

    // --- ERC721 Overrides & Custom Logic ---

    // Override to get appropriate URI based on token type
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        if (_catalystDetails[tokenId].tokenID != 0) { // Check if it's a Catalyst by checking if details exist
            return string(abi.encodePacked(_catalystBaseURI, toString(tokenId)));
        } else if (_masterpieceDetails[tokenId].tokenID != 0) { // Check if it's a Masterpiece
             // For Masterpieces, maybe the URI points to dynamic data including traits
             // Simplified here, just using base URI + ID
            return string(abi.encodePacked(_masterpieceBaseURI, toString(tokenId)));
        } else {
            // Should not happen if _exists is true, but good fallback
            return "";
        }
    }

    // Need to handle transfers carefully to update internal state (like staked status)
    // This implementation *prevents* transferring staked tokens via standard ERC721 methods.
    // Users must unstake first.
    function transferFrom(address from, address to, uint256 tokenId) public virtual override nonReentrant whenNotPaused {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        require(_catalystDetails[tokenId].tokenID == 0 || !_catalystDetails[tokenId].isStaked, "Foundry: Cannot transfer staked Catalyst");
        _transfer(from, to, tokenId);
        // Update internal owner state if needed, though ERC721 handles ownership mapping
        if (_catalystDetails[tokenId].tokenID != 0) {
             _catalystDetails[tokenId].currentOwner = to;
        }
        // Masterpieces don't have 'staked' state, transfers are standard
    }

    // Same check for safeTransferFrom
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual override nonReentrant whenNotPaused {
         require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        require(_catalystDetails[tokenId].tokenID == 0 || !_catalystDetails[tokenId].isStaked, "Foundry: Cannot transfer staked Catalyst");
        _safeTransfer(from, to, tokenId, data);
        // Update internal owner state if needed
         if (_catalystDetails[tokenId].tokenID != 0) {
             _catalystDetails[tokenId].currentOwner = to;
        }
    }

     function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override nonReentrant whenNotPaused {
        safeTransferFrom(from, to, tokenId, "");
    }


    // We need to support receiving ERC721s (e.g., if Catalysts were minted elsewhere and transferred here)
    // Although in this contract, Catalysts are minted internally. This is more for completeness
    // or future extensions where catalysts might be bridged or minted externally.
    // Returning bytes4(keccak256("onERC721Received(address,address,uint256,bytes)")) signifies acceptance.
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external virtual override returns (bytes4) {
        // Optional: Add logic to handle received NFTs, e.g., only accept Catalysts from a specific contract
        // require(msg.sender == address(this), "Foundry: Only accept transfers from self"); // If only internal transfers happen
        return this.onERC721Received.selector;
    }


    // --- ERC20-like Functions (Essence) ---
    // We implement a basic ERC20 interface internally for Essence

    function totalSupplyEssence() external view returns (uint256) {
        return _essenceTotalSupply;
    }

    function balanceOfEssence(address owner) external view returns (uint256) {
        return _essenceBalances[owner];
    }

    function transferEssence(address recipient, uint256 amount) external nonReentrant whenNotPaused returns (bool) {
        _transferEssence(_msgSender(), recipient, amount);
        return true;
    }

    function allowanceEssence(address owner, address spender) external view returns (uint256) {
        return _essenceAllowances[owner][spender];
    }

    function approveEssence(address spender, uint256 amount) external nonReentrant whenNotPaused returns (bool) {
        _approveEssence(_msgSender(), spender, amount);
        return true;
    }

    function transferFromEssence(address sender, address recipient, uint256 amount) external nonReentrant whenNotPaused returns (bool) {
        uint256 currentAllowance = _essenceAllowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approveEssence(sender, _msgSender(), currentAllowance - amount);
        }
        _transferEssence(sender, recipient, amount);
        return true;
    }

    // Internal Essence transfer logic
    function _transferEssence(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(_essenceBalances[sender] >= amount, "ERC20: transfer amount exceeds balance");

        // Before transfer, calculate and add pending rewards for the sender if they have staked catalysts
        _updateEssenceRewards(sender);

        unchecked {
            _essenceBalances[sender] -= amount;
        }
        _essenceBalances[recipient] += amount;
        // No standard ERC20 events emitted here as it's not a standard ERC20 contract
        // Could emit custom events like `EssenceTransferred(sender, recipient, amount)` if needed.
    }

    // Internal Essence approval logic
    function _approveEssence(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

         // Before approval, calculate and add pending rewards for the owner if they have staked catalysts
        _updateEssenceRewards(owner);

        _essenceAllowances[owner][spender] = amount;
         // Could emit custom events like `EssenceApproved(owner, spender, amount)` if needed.
    }

    // Internal Essence minting logic (only by contract)
    function _mintEssence(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

         // Before minting, calculate and add pending rewards for the recipient if they have staked catalysts
        _updateEssenceRewards(account);

        _essenceTotalSupply += amount;
        _essenceBalances[account] += amount;
         // Could emit custom events like `EssenceMinted(account, amount)` if needed.
    }

     // Internal Essence burning logic (only by contract)
    function _burnEssence(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");
        require(_essenceBalances[account] >= amount, "ERC20: burn amount exceeds balance");

         // Before burning, calculate and add pending rewards for the burner if they have staked catalysts
        _updateEssenceRewards(account);

        unchecked {
            _essenceBalances[account] -= amount;
        }
        _essenceTotalSupply -= amount;
         // Could emit custom events like `EssenceBurned(account, amount)` if needed.
    }


    // --- Catalyst Management ---

    function mintCatalyst(address recipient, uint256 catalystType) external onlyOwner nonReentrant whenNotPaused {
        require(allowedCatalystTypes[catalystType], "Foundry: Invalid catalyst type");

        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();

        _catalystDetails[newItemId] = CatalystDetails({
            tokenID: newItemId,
            catalystType: catalystType,
            isStaked: false,
            currentOwner: recipient // Store initial owner
        });

        // Mint the NFT using ERC721 standard function
        _safeMint(recipient, newItemId);

        // Update internal owner state after minting transfer
         _catalystDetails[newItemId].currentOwner = recipient;


        emit CatalystMinted(recipient, newItemId, catalystType);
    }

    function setCatalystBaseURI(string memory baseURI) external onlyOwner {
        _catalystBaseURI = baseURI;
    }

    function getCatalystDetails(uint256 tokenId) external view returns (CatalystDetails memory) {
        require(_catalystDetails[tokenId].tokenID != 0, "Foundry: Not a valid Catalyst token");
        // Note: owner field in struct might be slightly out of sync if transfers happen without this contract's knowledge
        // Rely on ERC721 ownerOf() for definitive ownership check if needed elsewhere.
        // But for staked status, this internal state is the source of truth.
        CatalystDetails storage details = _catalystDetails[tokenId];
         return CatalystDetails({
            tokenID: details.tokenID,
            catalystType: details.catalystType,
            isStaked: details.isStaked,
            currentOwner: ownerOf(tokenId) // Get current owner directly from ERC721 state
        });
    }

    function refineCatalysts(uint256[] calldata sourceCatalystTokenIds, uint256 targetCatalystType) external nonReentrant whenNotPaused {
        RefinementRecipe memory recipe = refinementRecipes[targetCatalystType];
        require(recipe.targetCatalystType != 0, "Foundry: No refinement recipe for target type");
        require(sourceCatalystTokenIds.length == recipe.sourceCatalystTypes.length, "Foundry: Incorrect number of source catalysts");

        address caller = _msgSender();
        uint256[] memory sourceTypes = recipe.sourceCatalystTypes;
        uint256[] memory currentSourceTypes = new uint256[](sourceCatalystTokenIds.length);

        // Check ownership and collect types
        for (uint i = 0; i < sourceCatalystTokenIds.length; i++) {
            uint256 tokenId = sourceCatalystTokenIds[i];
            require(ownerOf(tokenId) == caller, "Foundry: Not owner of source catalyst");
            require(_catalystDetails[tokenId].tokenID != 0, "Foundry: Invalid source catalyst token");
            require(!_catalystDetails[tokenId].isStaked, "Foundry: Source catalyst is staked");
            currentSourceTypes[i] = _catalystDetails[tokenId].catalystType;
        }

        // Sort both arrays to compare recipes regardless of input order
        sort(currentSourceTypes);
        sort(sourceTypes);

        // Check if submitted catalyst types match the recipe requirements
        for (uint i = 0; i < sourceTypes.length; i++) {
            require(currentSourceTypes[i] == sourceTypes[i], "Foundry: Source catalyst types do not match recipe");
        }

        // Burn source catalysts
        uint256[] memory burnedIds = new uint256[](sourceCatalystTokenIds.length);
        for (uint i = 0; i < sourceCatalystTokenIds.length; i++) {
            uint256 tokenIdToBurn = sourceCatalystTokenIds[i];
            _burn(tokenIdToBurn);
            delete _catalystDetails[tokenIdToBurn]; // Remove catalyst state
            burnedIds[i] = tokenIdToBurn;
        }

        // Mint target catalyst
        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();

        _catalystDetails[newItemId] = CatalystDetails({
            tokenID: newItemId,
            catalystType: targetCatalystType,
            isStaked: false,
            currentOwner: caller
        });

        _safeMint(caller, newItemId);
        _catalystDetails[newItemId].currentOwner = caller;


        emit CatalystRefined(caller, burnedIds, newItemId, targetCatalystType);
    }

     // Helper function for sorting (simple bubble sort for demonstration)
     function sort(uint256[] memory arr) internal pure {
         for (uint i = 0; i < arr.length; i++) {
             for (uint j = i + 1; j < arr.length; j++) {
                 if (arr[i] > arr[j]) {
                     uint256 temp = arr[i];
                     arr[i] = arr[j];
                     arr[j] = temp;
                 }
             }
         }
     }

    // --- Essence Staking ---

    function stakeCatalyst(uint256 tokenId) external nonReentrant whenNotPaused {
        address owner = ownerOf(tokenId);
        require(owner == _msgSender(), "Foundry: Caller is not token owner");
        require(_catalystDetails[tokenId].tokenID != 0, "Foundry: Not a valid Catalyst token");
        require(!_catalystDetails[tokenId].isStaked, "Foundry: Catalyst is already staked");

        // Calculate and add pending rewards before staking
        _updateEssenceRewards(owner);

        // Transfer NFT ownership to the contract
        // Use internal _transfer to avoid triggering our own transferFrom checks unnecessarily
        // and because the owner has already been validated.
        _transfer(owner, address(this), tokenId);


        _catalystDetails[tokenId].isStaked = true;
        _catalystStakeInfo[tokenId].lastRewardBlock = uint48(block.number);
        _catalystStakeInfo[tokenId].accumulatedEssence = 0; // Reset accumulated on stake (rewards added to balance)

        _stakedCatalystOwner[tokenId] = owner; // Track who staked it
        _stakedCatalystsByOwner[owner].push(tokenId); // Add to owner's staked list

        emit CatalystStaked(owner, tokenId);
    }

    function unstakeCatalyst(uint256 tokenId) external nonReentrant whenNotPaused {
        require(_exists(tokenId), "ERC721: owner query for nonexistent token"); // Check if token exists
        require(_catalystDetails[tokenId].tokenID != 0, "Foundry: Not a valid Catalyst token"); // Check if it's a Catalyst
        require(_catalystDetails[tokenId].isStaked, "Foundry: Catalyst is not staked"); // Check if staked

        address staker = _stakedCatalystOwner[tokenId];
        require(staker == _msgSender(), "Foundry: Caller is not the staker"); // Check if caller is the original staker

        // Calculate and add pending rewards before unstaking
        _updateEssenceRewards(staker);

        _catalystDetails[tokenId].isStaked = false;
        delete _catalystStakeInfo[tokenId]; // Clear stake info

        // Remove from owner's staked list
        uint256[] storage stakedList = _stakedCatalystsByOwner[staker];
        for (uint i = 0; i < stakedList.length; i++) {
            if (stakedList[i] == tokenId) {
                stakedList[i] = stakedList[stakedList.length - 1];
                stakedList.pop();
                break;
            }
        }

        delete _stakedCatalystOwner[tokenId]; // Clear staked owner mapping

        // Transfer NFT back to the staker
         // Use internal _transfer
        _transfer(address(this), staker, tokenId);

        emit CatalystUnstaked(staker, tokenId);
    }

    function claimEssence() external nonReentrant whenNotPaused {
        address caller = _msgSender();
         // Calculate and add pending rewards first
        _updateEssenceRewards(caller);

        uint256 claimable = _essenceRewards[caller];
        require(claimable > 0, "Foundry: No Essence to claim");

        _essenceRewards[caller] = 0; // Reset pending rewards

        _mintEssence(caller, claimable); // Mint the essence directly to their balance

        emit EssenceClaimed(caller, claimable);
    }

    // View function to calculate pending rewards *without* updating state
    function getPendingEssence(address staker) external view returns (uint256) {
        uint256 pending = _essenceRewards[staker]; // Start with accumulated but not yet claimed
        uint256[] memory stakedList = _stakedCatalystsByOwner[staker];

        for (uint i = 0; i < stakedList.length; i++) {
            uint256 tokenId = stakedList[i];
            CatalystStakeInfo storage stakeInfo = _catalystStakeInfo[tokenId];
            uint256 blocksElapsed = block.number - stakeInfo.lastRewardBlock;
            pending += blocksElapsed * essencePerBlockPerCatalyst;
        }
        // Note: This view function's result might differ slightly from the amount claimed
        // by `claimEssence` if called after `claimEssence` but before the next block,
        // as `claimEssence` transfers `_essenceRewards[caller]` *before* calling `_mintEssence`.
        // The state-changing `_updateEssenceRewards` is the accurate calculation trigger.
         return pending;
    }

     // Internal helper to calculate and update rewards for an owner
     // Called before any state-changing operation involving an owner's balance or staked status
     mapping(address => uint256) private _essenceRewards; // Store calculated rewards not yet claimed

     function _updateEssenceRewards(address staker) internal {
         uint256[] storage stakedList = _stakedCatalystsByOwner[staker];
         uint256 currentBlock = block.number;

         for (uint i = 0; i < stakedList.length; i++) {
             uint256 tokenId = stakedList[i];
             CatalystStakeInfo storage stakeInfo = _catalystStakeInfo[tokenId];

             // Calculate rewards since last update block
             uint256 blocksElapsed = currentBlock - stakeInfo.lastRewardBlock;
             uint256 earned = blocksElapsed * essencePerBlockPerCatalyst;

             // Add to staker's total pending rewards
             _essenceRewards[staker] += earned;

             // Update last calculated block for this catalyst
             stakeInfo.lastRewardBlock = uint48(currentBlock);
             // Note: accumulatedEssence in struct is not strictly necessary if we sum into _essenceRewards
             // It could be used to show per-catalyst earnings before claim, but _essenceRewards simplifies claims.
         }
     }

     function getCatalystStakeInfo(uint256 tokenId) external view returns (uint48 lastRewardBlock, uint256 accumulatedEssence, address staker) {
         require(_catalystDetails[tokenId].tokenID != 0, "Foundry: Not a valid Catalyst token");
         require(_catalystDetails[tokenId].isStaked, "Foundry: Catalyst is not staked");

         CatalystStakeInfo storage stakeInfo = _catalystStakeInfo[tokenId];
         address owner = _stakedCatalystOwner[tokenId];
         // Note: accumulatedEssence in this return is not showing *total* earned,
         // but the value stored in the struct, which is effectively just the base for calculation.
         // `getPendingEssence` shows the claimable amount.
         return (stakeInfo.lastRewardBlock, stakeInfo.accumulatedEssence, owner);
     }

     function getTotalStakedCatalysts(address staker) external view returns (uint256) {
         return _stakedCatalystsByOwner[staker].length;
     }


    // --- Masterpiece Forging & Enhancement ---

    function forgeMasterpiece(uint256[] calldata catalystTokenIds, uint256 essenceAmount) external nonReentrant whenNotPaused {
        address caller = _msgSender();

        // Check Essence balance and allowance/direct transfer
        // Assume user has approved this contract or will send directly (using receive/fallback, not ideal)
        // Standard ERC20 usage is approve + transferFrom.
        _burnEssence(caller, essenceAmount); // Burn Essence from user's balance

        // Validate and take possession of Catalysts
        require(catalystTokenIds.length > 0, "Foundry: Must use at least one Catalyst");
        uint256[] memory catalystTypesUsed = new uint256[](catalystTokenIds.length);

        for (uint i = 0; i < catalystTokenIds.length; i++) {
            uint256 tokenId = catalystTokenIds[i];
            require(ownerOf(tokenId) == caller, "Foundry: Not owner of catalyst");
            require(_catalystDetails[tokenId].tokenID != 0, "Foundry: Invalid catalyst token");
            require(!_catalystDetails[tokenId].isStaked, "Foundry: Catalyst is staked");

            // Transfer catalyst to contract (binding them)
            // Using internal _transfer
            _transfer(caller, address(this), tokenId);

            // Store catalyst type for trait generation / recipe check
            catalystTypesUsed[i] = _catalystDetails[tokenId].catalystType;

            // Mark catalyst as bound - they can no longer be unstaked or transferred away from the contract
            _catalystDetails[tokenId].isStaked = true; // Reuse isStaked flag to mean 'isBound'
        }

        // Optional: Check if the combination of catalysts/essence matches a known recipe
        // This adds structure, or allow freeform forging
        // Let's implement a recipe check here:
        uint256 masterpieceType = _findForgingRecipe(essenceAmount, catalystTypesUsed);
        require(masterpieceType != 0, "Foundry: No forging recipe matches inputs");
        require(allowedMasterpieceTypes[masterpieceType], "Foundry: Resulting masterpiece type is not allowed");


        // Mint the new Masterpiece
        _tokenIdCounter.increment();
        uint256 newMasterpieceId = _tokenIdCounter.current();

        // Generate dynamic traits based on inputs and block data
        uint256[] memory dynamicTraits = _generateMasterpieceTraits(
            catalystTokenIds,
            catalystTypesUsed,
            essenceAmount,
            block.timestamp,
            block.basefee // block.difficulty and block.gaslimit were affected by The Merge
        );

        _masterpieceDetails[newMasterpieceId] = MasterpieceDetails({
            tokenID: newMasterpieceId,
            boundCatalystTokenIds: catalystTokenIds,
            essenceUsed: essenceAmount,
            dynamicTraits: dynamicTraits,
            creationBlock: block.number,
            creationTimestamp: block.timestamp
        });

        // Mint the Masterpiece NFT to the caller
        _safeMint(caller, newMasterpieceId);

        emit MasterpieceForged(caller, newMasterpieceId, catalystTokenIds, essenceAmount);
    }

    // Internal helper to find a matching forging recipe
    // Returns 0 if no recipe matches
    function _findForgingRecipe(uint256 essenceAmount, uint256[] memory catalystTypesUsed) internal view returns (uint256) {
        // Sort catalyst types used for recipe comparison
        uint256[] memory sortedUsedTypes = new uint256[](catalystTypesUsed.length);
        for(uint i=0; i<catalystTypesUsed.length; i++) {
            sortedUsedTypes[i] = catalystTypesUsed[i];
        }
        sort(sortedUsedTypes); // Use the helper sort function

        // Iterate through defined recipes to find a match
        // This requires a way to iterate through mapping keys, which isn't direct in Solidity.
        // A common pattern is to store recipe keys (masterpiece types) in an array.
        // Let's assume for simplicity that masterpieceType directly corresponds to an index or is known.
        // Or, let's check against all *allowed* masterpiece types that have recipes.
        // This requires an array of masterpiece types with recipes. We'll need an admin function for that.
        // For now, let's assume recipes are stored indexed by the target masterpiece type.

        // We need to iterate through all potential masterpiece types that have recipes
        // Let's assume max 100 masterpiece types for this example and iterate
        // In a real application, manage this list explicitly via admin functions
        uint256[] memory masterpieceTypesWithRecipes = new uint256[](100); // Placeholder
        uint256 recipeCount = 0;
         // A better way: store the types with recipes in a dynamic array managed by admin
         // For this example, let's just find *a* recipe that matches requirements
         // We need to store valid recipe keys.

        // Let's add a state variable: uint256[] public recipeMasterpieceTypes;
        // Admin function: addRecipeMasterpieceType(uint256 masterpieceType)

        // Simple matching: Find the first recipe that matches the exact catalyst types and essence amount.
        // This is restrictive. More complex matching (e.g., minimum essence, any combination of types) is possible.

        // Let's iterate through known recipe types (assuming an array `recipeMasterpieceTypes` exists and is populated)
        // We need to add that state and admin function.

        // For simplicity *in this version*, let's require an *exact* match on types and essence.
        // Iterate through all *possible* masterpiece types that have a recipe defined.
        // We need an array of keys for the `forgingRecipes` mapping.
        // Let's simulate checking a few known recipe types directly.

        // **Simplified Recipe Check Logic for Demo:**
        // We need to know which masterpiece types *could* be forged.
        // The `forgingRecipes` mapping stores the recipe *for* a given `masterpieceType`.
        // So we need to iterate through potential `masterpieceType` values (say 1 to 10).
        for (uint256 masterpieceType = 1; masterpieceType <= 10; masterpieceType++) { // Simulate checking types 1-10
            ForgingRecipe memory recipe = forgingRecipes[masterpieceType];
            // Check if a recipe exists for this type AND the type is allowed
            if (recipe.requiredEssence != 0 && allowedMasterpieceTypes[masterpieceType]) {
                // Check if essence requirement is met
                if (essenceAmount >= recipe.requiredEssence) {
                    // Check if catalyst types match EXACTLY (length and sorted types)
                    if (catalystTypesUsed.length == recipe.requiredCatalystTypes.length) {
                         uint256[] memory sortedRecipeTypes = new uint256[](recipe.requiredCatalystTypes.length);
                         for(uint i=0; i<recipe.requiredCatalystTypes.length; i++) {
                             sortedRecipeTypes[i] = recipe.requiredCatalystTypes[i];
                         }
                         sort(sortedRecipeTypes);

                         bool typesMatch = true;
                         for (uint i = 0; i < sortedUsedTypes.length; i++) {
                             if (sortedUsedTypes[i] != sortedRecipeTypes[i]) {
                                 typesMatch = false;
                                 break;
                             }
                         }
                         if (typesMatch) {
                             return masterpieceType; // Found a match! Return the type
                         }
                    }
                }
            }
        }

        return 0; // No recipe found matching the exact inputs
    }


    // Internal helper to generate dynamic traits
    function _generateMasterpieceTraits(
        uint256[] memory catalystTokenIds,
        uint256[] memory catalystTypes,
        uint256 essenceAmount,
        uint256 timestamp,
        uint256 basefee
    ) internal pure returns (uint256[] memory) {
        // This is a simplified example. Real trait generation could be complex.
        // Use inputs and unpredictable block data as seeds.
        // Example traits: [Color, Shape, Texture, SparkleIntensity]
        uint256[] memory traits = new uint256[](4);

        // Use a combination of inputs and block data to derive trait values
        // Hash inputs to create a seed
        bytes32 seed = keccak256(abi.encodePacked(
            catalystTokenIds,
            catalystTypes,
            essenceAmount,
            timestamp,
            basefee,
            block.prevrandao // Consider prevrandao after the merge for randomness source
            // Could also include msg.sender's address, nonce, etc.
        ));

        // Derive traits from the seed using modulo or bitwise operations
        traits[0] = uint256(seed) % 256; // Example: Color (0-255)
        traits[1] = (uint256(seed) >> 8) % 100; // Example: Shape (0-99)
        traits[2] = (uint256(seed) >> 16) % 50; // Example: Texture (0-49)
        traits[3] = (uint256(seed) >> 24) % 10; // Example: Sparkle Intensity (0-9)

        // Traits could also be influenced directly by inputs
        // Example: Higher essence -> more intense effect
        traits[3] = (traits[3] + (essenceAmount / (10**ESSENCE_DECIMALS))) % 10; // Add influence from essence amount

        // Example: Specific catalyst types influence certain traits
        for(uint i=0; i<catalystTypes.length; i++) {
            if(catalystTypes[i] == 1) { // If catalyst type 1 was used
                traits[0] = (traits[0] + 50) % 256; // Shift color
            } else if (catalystTypes[i] == 2) { // If catalyst type 2 was used
                traits[2] = (traits[2] + 10) % 50; // Change texture
            }
            // ... etc.
        }


        return traits;
    }

    function enhanceMasterpiece(uint256 masterpieceTokenId, uint256 additionalEssenceAmount) external nonReentrant whenNotPaused {
        require(_masterpieceDetails[masterpieceTokenId].tokenID != 0, "Foundry: Not a valid Masterpiece token");
        require(ownerOf(masterpieceTokenId) == _msgSender(), "Foundry: Caller is not Masterpiece owner");
        require(additionalEssenceAmount > 0, "Foundry: Must use non-zero essence for enhancement");

        // Burn additional Essence from user's balance
        _burnEssence(_msgSender(), additionalEssenceAmount);

        MasterpieceDetails storage details = _masterpieceDetails[masterpieceTokenId];
        details.essenceUsed += additionalEssenceAmount; // Track total essence spent on this piece

        // Re-generate traits or add new traits based on the *updated* state and block data
        // This could be a partial re-roll or adding layers/effects.
        // For simplicity, let's add influence from the *new* essence amount and current block data.
        // A more complex system might re-run the initial generation function with new inputs,
        // or apply a different trait generation logic for enhancement.

        // Simple enhancement logic: Add influence to existing traits based on new essence and block data
        uint256[] memory currentTraits = details.dynamicTraits; // Get current traits
        uint256[] memory newTraits = new uint256[](currentTraits.length);

        // Use a new seed for enhancement, incorporating original seed factors + new factors
         bytes32 enhancementSeed = keccak256(abi.encodePacked(
            details.boundCatalystTokenIds, // Original inputs still matter
            details.essenceUsed, // Total essence now matters
            block.timestamp,
            block.basefee,
            block.prevrandao,
            masterpieceTokenId // Token ID itself can be part of seed
        ));

        // Apply enhancement influence (example: shifting trait values)
        newTraits[0] = (currentTraits[0] + (uint256(enhancementSeed) % 50)) % 256;
        newTraits[1] = (currentTraits[1] + (uint256(enhancementSeed) >> 4 % 20)) % 100;
        // ... apply logic to other traits ...
        if (currentTraits.length > 2) { // Ensure index exists
             newTraits[2] = (currentTraits[2] + (uint256(enhancementSeed) >> 8 % 10)) % 50;
        }
         if (currentTraits.length > 3) { // Ensure index exists
             newTraits[3] = (currentTraits[3] + (uint256(enhancementSeed) >> 12 % 5)) % 10;
         }


        details.dynamicTraits = newTraits; // Update traits

        emit MasterpieceEnhanced(masterpieceTokenId, additionalEssenceAmount, newTraits);
    }

    function getMasterpieceDetails(uint256 tokenId) external view returns (MasterpieceDetails memory) {
        require(_masterpieceDetails[tokenId].tokenID != 0, "Foundry: Not a valid Masterpiece token");
        MasterpieceDetails storage details = _masterpieceDetails[tokenId];
        return MasterpieceDetails({
            tokenID: details.tokenID,
            boundCatalystTokenIds: details.boundCatalystTokenIds,
            essenceUsed: details.essenceUsed,
            dynamicTraits: details.dynamicTraits,
            creationBlock: details.creationBlock,
            creationTimestamp: details.creationTimestamp
        });
    }

    // View function to get forging requirements for a specific Masterpiece type
    function getForgingRequirements(uint256 masterpieceType) external view returns (ForgingRecipe memory) {
         require(allowedMasterpieceTypes[masterpieceType], "Foundry: Invalid masterpiece type");
         return forgingRecipes[masterpieceType];
    }


    // --- Admin & Configuration ---

    function setEssencePerBlock(uint256 amount) external onlyOwner {
        essencePerBlockPerCatalyst = amount;
        emit EssenceRateUpdated(amount);
    }

    function setForgingRecipe(uint256 masterpieceType, uint256 requiredEssence, uint256[] calldata requiredCatalystTypes) external onlyOwner {
        require(allowedMasterpieceTypes[masterpieceType], "Foundry: Invalid masterpiece type for recipe");
        // Basic validation for required catalysts
        for(uint i=0; i<requiredCatalystTypes.length; i++) {
            require(allowedCatalystTypes[requiredCatalystTypes[i]], "Foundry: Invalid required catalyst type in recipe");
        }
        forgingRecipes[masterpieceType] = ForgingRecipe({
            requiredEssence: requiredEssence,
            requiredCatalystTypes: requiredCatalystTypes
        });
        emit ForgingRecipeUpdated(masterpieceType, requiredEssence, requiredCatalystTypes);
    }

     function setRefinementRecipe(uint256[] calldata sourceCatalystTypes, uint256 targetCatalystType) external onlyOwner {
        require(allowedCatalystTypes[targetCatalystType], "Foundry: Invalid target catalyst type for refinement");
        require(sourceCatalystTypes.length > 0, "Foundry: Must provide source catalysts for refinement");
        // Basic validation for source catalysts
         for(uint i=0; i<sourceCatalystTypes.length; i++) {
            require(allowedCatalystTypes[sourceCatalystTypes[i]], "Foundry: Invalid source catalyst type in recipe");
        }
        // Store recipe indexed by target type
        refinementRecipes[targetCatalystType] = RefinementRecipe({
            sourceCatalystTypes: sourceCatalystTypes,
            targetCatalystType: targetCatalystType
        });
        emit RefinementRecipeUpdated(targetCatalystType, sourceCatalystTypes);
     }


    function addAllowedCatalystType(uint256 catalystType) external onlyOwner {
        allowedCatalystTypes[catalystType] = true;
    }

    function addAllowedMasterpieceType(uint256 masterpieceType) external onlyOwner {
        allowedMasterpieceTypes[masterpieceType] = true;
    }

    function setMasterpieceBaseURI(string memory baseURI) external onlyOwner {
        _masterpieceBaseURI = baseURI;
    }

    // Admin withdrawal functions for accidentally sent tokens
    function withdrawERC20(address tokenAddress, uint256 amount) external onlyOwner nonReentrant {
        require(tokenAddress != address(0), "Foundry: Invalid token address");
        require(tokenAddress != address(this), "Foundry: Cannot withdraw self (Essence)"); // Prevent withdrawing Essence this way
        IERC20 token = IERC20(tokenAddress);
        token.transfer(owner(), amount);
    }

    function withdrawERC721(address tokenAddress, uint256 tokenId) external onlyOwner nonReentrant {
        require(tokenAddress != address(0), "Foundry: Invalid token address");
        IERC721 token = IERC721(tokenAddress);
        require(token.ownerOf(tokenId) == address(this), "Foundry: Contract does not own token");
        token.transferFrom(address(this), owner(), tokenId);
    }


    // --- Internal Helpers ---

    // Helper to convert uint256 to string
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
            buffer[digits] = bytes1(uint8(48 + value % 10));
            value /= 10;
        }
        return string(buffer);
    }
}
```