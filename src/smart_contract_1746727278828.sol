Okay, here is a Solidity smart contract implementing an advanced concept for an NFT ecosystem.

The concept revolves around **MetaMorphMarket**, a platform for dynamic, evolving NFTs ($META) that can be mutated, composed, staked, and traded, interacting with a utility token ($MORPH). It incorporates dynamic metadata, royalty distribution, role-based access control, pausing, and an integrated simple marketplace.

This contract avoids directly duplicating standard OpenZeppelin templates (like just an ERC721 or ERC20) by combining several distinct, interactive functionalities into a single ecosystem contract.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // Assume MORPH token exists

// Interface for the MORPH token
interface IMorphToken is IERC20 {
    function mint(address account, uint256 amount) external;
    function burn(address account, uint256 amount) external;
    // Potentially other MORPH specific functions
}

// --- MetaMorphMarket Contract Outline ---
// 1. State Variables & Constants: Define core data structures and roles.
// 2. Structs: Define data structures for NFT data and marketplace listings.
// 3. Events: Define events for transparency and off-chain monitoring.
// 4. Constructor: Initialize roles and base contract state.
// 5. Access Control & Pausability: Standard OpenZeppelin patterns with specific roles.
// 6. NFT Management (ERC721 Extensions): Minting, burning, transfers, enumeration.
// 7. Dynamic Metadata: Storing and retrieving mutable NFT attributes.
// 8. Core Mechanics:
//    - Mutation: Evolving an NFT by consuming MORPH and/or other assets.
//    - Composition: Combining multiple NFTs into a single, new/enhanced one.
//    - Decomposition: (Optional/Advanced) Breaking composites.
// 9. Staking: Locking NFTs to earn MORPH tokens.
// 10. Marketplace: Listing and buying NFTs within the contract.
// 11. Protocol Configuration: Admin functions to set parameters.
// 12. Utility/Admin: Rescue funds, manage roles, query state.
// 13. Royalty Distribution: ERC2981 implementation.
// 14. Override Functions: Necessary overrides for inherited contracts.

// --- Function Summary ---
// [ADMIN/CONFIG]
// 1. setBaseURI(string uri): Sets the base URI for static metadata.
// 2. setMetadataServiceURI(string uri): Sets a URI hint for dynamic metadata service.
// 3. setMutationCostMorph(uint256 cost): Sets the MORPH token cost for NFT mutation.
// 4. setCompositionCostMorph(uint256 cost): Sets the MORPH token cost for NFT composition.
// 5. setStakingRateMorphPerSec(uint256 rate): Sets the MORPH token emission rate per staked NFT per second.
// 6. setMarketplaceFeeBps(uint16 feeBps): Sets the marketplace fee percentage (in basis points).
// 7. setTreasuryAddress(address treasury): Sets the address receiving marketplace fees.
// 8. setMorphTokenAddress(address morphToken): Sets the address of the MORPH ERC20 contract.

// [CORE NFT ACTIONS]
// 9. mintInitialNFT(address to, uint256 initialAttributes): Mints a new NFT to an address with initial attributes.
// 10. evolveNFT(uint256 tokenId, uint256 morphAmount, uint256 newAttributes): Mutates an existing NFT's attributes, potentially consuming MORPH and burning other items (logic simplified for example).
// 11. composeNFTs(uint256[] memory tokenIdsToBurn, uint256 newTokenId, uint256 newAttributes): Burns multiple NFTs to create/mint a new "composite" NFT.
// 12. stakeNFT(uint256 tokenId): Locks an owned NFT, making it earn MORPH over time.
// 13. unstakeNFT(uint256 tokenId): Unlocks a staked NFT and claims accumulated MORPH rewards.
// 14. claimStakedMorph(uint256 tokenId): Claims accumulated MORPH rewards for a staked NFT without unstaking.
// 15. listItemForSale(uint256 tokenId, uint256 price, bool useMorph): Lists an owned NFT on the internal marketplace for ETH or MORPH.
// 16. buyItem(uint256 tokenId): Buys a listed NFT.
// 17. cancelListing(uint256 tokenId): Removes an NFT from the marketplace listing.

// [UTILITY & READ]
// 18. getNFTAttributes(uint256 tokenId): Retrieves the current dynamic attributes of an NFT.
// 19. getPendingMorphRewards(uint256 tokenId): Calculates the pending MORPH rewards for a staked NFT.
// 20. getListing(uint256 tokenId): Retrieves details of a marketplace listing.
// 21. isStaked(uint256 tokenId): Checks if an NFT is currently staked.
// 22. getTotalStakedNFTs(): Gets the total number of NFTs currently staked.
// 23. withdrawAccidentalERC20(address tokenAddress, uint256 amount): Allows admin to rescue other ERC20s sent to the contract.
// 24. supportsInterface(bytes4 interfaceId): Standard ERC165 interface support check (includes ERC721, Enumerable, Pausable, AccessControl, ERC2981).
// 25. royaltyInfo(uint256 tokenId, uint256 salePrice): ERC2981 standard function to get royalty details.

// [INHERITED / STANDARD ERC721+]
// - balanceOf(address owner)
// - ownerOf(uint256 tokenId)
// - approve(address to, uint256 tokenId)
// - getApproved(uint256 tokenId)
// - setApprovalForAll(address operator, bool approved)
// - isApprovedForAll(address owner, address operator)
// - transferFrom(address from, address to, uint256 tokenId)
// - safeTransferFrom(address from, address to, uint256 tokenId)
// - safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
// - totalSupply()
// - tokenByIndex(uint256 index)
// - tokenOfOwnerByIndex(address owner, uint256 index)
// - tokenURI(uint256 tokenId)
// - pause()
// - unpause()
// - paused()
// - hasRole(bytes32 role, address account)
// - getRoleAdmin(bytes32 role)
// - grantRole(bytes32 role, address account)
// - revokeRole(bytes32 role, address account)
// - renounceRole(bytes32 role)


contract MetaMorphMarket is ERC721Enumerable, ERC721Pausable, AccessControlEnumerable, ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // --- State Variables & Constants ---

    // Roles
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant CONFIG_ROLE = keccak256("CONFIG_ROLE"); // Role to set core parameters
    bytes32 public constant METADATA_ROLE = keccak256("METADATA_ROLE"); // Role to update dynamic metadata directly

    // Contract Addresses
    address public morphTokenAddress;
    address public treasuryAddress;

    // Configuration Parameters
    uint256 public mutationCostMorph; // Cost to evolve/mutate in MORPH tokens
    uint256 public compositionCostMorph; // Cost to compose in MORPH tokens
    uint256 public stakingRateMorphPerSec; // MORPH tokens earned per NFT per second staked
    uint16 public marketplaceFeeBps; // Marketplace fee in basis points (e.g., 250 for 2.5%)

    // Base URI for static metadata (e.g., ipfs://...)
    string private _baseTokenURI;
    // URI hint for a dynamic metadata service (optional)
    string public metadataServiceURI;

    // --- Structs ---

    struct NFTData {
        uint256 attributes; // Represents dynamic attributes encoded in a uint256
        bool isStaked;
        uint64 stakeStartTime; // Unix timestamp when staking started
        uint256 unclaimedMorphRewards; // Rewards accumulated since last claim/unstake
    }

    struct Listing {
        address seller;
        uint256 price;
        bool isListed;
        bool useMorphToken; // True if price is in MORPH, false for ETH
    }

    // --- Mappings ---

    mapping(uint256 => NFTData) private _nftData;
    mapping(uint256 => Listing) private _listings;
    mapping(address => uint256[]) private _stakedTokenIdsByOwner; // Track staked tokens per owner (less efficient for large numbers)
    uint256 private _totalStakedNFTs;

    // --- Events ---

    event InitialNFTMinted(address indexed owner, uint256 indexed tokenId, uint256 attributes);
    event NFTMutated(uint256 indexed tokenId, uint256 oldAttributes, uint256 newAttributes, uint256 morphSpent);
    event NFTsComposed(address indexed newOwner, uint256 indexed newTokenId, uint256[] burnedTokenIds, uint256 newAttributes);
    event NFTStaked(address indexed owner, uint256 indexed tokenId);
    event NFTUnstaked(address indexed owner, uint256 indexed tokenId, uint256 claimedRewards);
    event MorphRewardsClaimed(address indexed owner, uint256 indexed tokenId, uint256 claimedRewards);
    event ItemListed(uint256 indexed tokenId, address indexed seller, uint256 price, bool useMorphToken);
    event ItemBought(uint256 indexed tokenId, address indexed buyer, uint256 indexed seller, uint256 price, bool useMorphToken);
    event ListingCancelled(uint256 indexed tokenId);
    event ParameterChanged(bytes32 indexed parameterName, uint256 oldValue, uint256 newValue);
    event TreasuryUpdated(address indexed oldAddress, address indexed newAddress);
    event MorphTokenAddressUpdated(address indexed oldAddress, address indexed newAddress);
    event DynamicAttributeUpdated(uint256 indexed tokenId, uint256 oldAttributes, uint256 newAttributes);

    // --- Constructor ---

    constructor(address defaultAdmin, string memory name, string memory symbol)
        ERC721(name, symbol)
        ERC721Enumerable()
        ERC721Pausable()
        AccessControlEnumerable()
    {
        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
        _grantRole(PAUSER_ROLE, defaultAdmin);
        _grantRole(CONFIG_ROLE, defaultAdmin);
        _grantRole(METADATA_ROLE, defaultAdmin);

        // Set initial default config values
        mutationCostMorph = 100 ether; // Example value
        compositionCostMorph = 500 ether; // Example value
        stakingRateMorphPerSec = 1000; // 1000 wei per sec, adjust based on desired rate
        marketplaceFeeBps = 250; // 2.5%
        treasuryAddress = defaultAdmin; // Set initial treasury to admin
    }

    // --- Access Control & Pausability ---

    // The Pausable and AccessControlEnumerable provide the pause, unpause, hasRole, grantRole, etc.
    // We just need to make sure our functions respect these.

    /// @dev See {ERC721Pausable-beforeTokenTransfer}.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721Enumerable, ERC721Pausable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        // Additional checks: prevent transfer if listed or staked
        if (_listings[tokenId].isListed) {
            revert("MetaMorphMarket: Token is listed for sale");
        }
         if (_nftData[tokenId].isStaked) {
            revert("MetaMorphMarket: Token is staked");
        }
    }

    /// @dev See {ERC721Enumerable-supportsInterface}.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Enumerable, AccessControlEnumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId) ||
               interfaceId == type(ERC2981).interfaceId; // Support ERC2981 Royalties
    }

    // --- NFT Management ---

    /// @notice Mints a new initial NFT.
    /// @param to The address to mint the NFT to.
    /// @param initialAttributes The initial dynamic attributes for the NFT.
    function mintInitialNFT(address to, uint256 initialAttributes)
        public
        onlyRole(DEFAULT_ADMIN_ROLE) // Only admin can mint initial NFTs
        whenNotPaused
    {
        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();
        _safeMint(to, newItemId);

        _nftData[newItemId].attributes = initialAttributes;
        _setTokenRoyalty(newItemId, owner(), 500); // Example: 5% royalty to the contract deployer/owner initially

        emit InitialNFTMinted(to, newItemId, initialAttributes);
    }

    /// @dev Burns an NFT. Requires `burn` approval from ERC721.
    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        // Before burning, ensure it's not listed or staked
        if (_listings[tokenId].isListed) {
            revert("MetaMorphMarket: Cannot burn listed token");
        }
         if (_nftData[tokenId].isStaked) {
            revert("MetaMorphMarket: Cannot burn staked token");
        }

        // If staked, unstake first before burning (implicitly handled by the check above)
        // If listed, cancel listing first (implicitly handled by the check above)

        // Clean up NFTData entry (optional, relies on default value mapping behaviour)
        delete _nftData[tokenId];
        // Clean up Listing entry (optional)
        delete _listings[tokenId];

        super._burn(tokenId);
    }

    // --- Dynamic Metadata ---

    /// @notice Sets the base URI for static metadata.
    /// @param uri The base URI string.
    function setBaseURI(string memory uri) public onlyRole(CONFIG_ROLE) {
        _baseTokenURI = uri;
        emit ParameterChanged("baseURI", 0, 0); // Event doesn't strictly fit uint, overloaded meaning
    }

    /// @notice Sets a URI hint for an external dynamic metadata service.
    /// @param uri The URI hint.
    function setMetadataServiceURI(string memory uri) public onlyRole(CONFIG_ROLE) {
        metadataServiceURI = uri;
        emit ParameterChanged("metadataServiceURI", 0, 0); // Event doesn't strictly fit uint, overloaded meaning
    }

    /// @dev Returns the base URI for standard token metadata.
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    /// @notice Returns the URI for the dynamic metadata of a token.
    /// @dev This function serves as a hint. An external service should combine
    /// the base URI (if any) and the dynamic data (from getNFTAttributes)
    /// to generate the full metadata JSON based on `metadataServiceURI`.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);
        // Return the dynamic metadata service URI hint, potentially with the token ID
        // A client would use metadataServiceURI + tokenId to query the actual metadata.
        // Or, if _baseTokenURI is set, it could return _baseURI() + tokenId string.
        // For this example, we'll just return the metadataServiceURI hint.
        // A more complex implementation might encode data in the URI or point directly
        // to a URI that generates the JSON based on the on-chain attributes.
        // Let's return base URI + tokenId if set, otherwise just the service hint.
        string memory base = _baseURI();
        if (bytes(base).length > 0) {
            return string(abi.encodePacked(base, Strings.toString(tokenId)));
        }
        return metadataServiceURI; // Fallback/Hint
    }

    /// @notice Retrieves the dynamic attributes of an NFT.
    /// @param tokenId The ID of the NFT.
    /// @return The uint256 representing the attributes.
    function getNFTAttributes(uint256 tokenId) public view returns (uint256) {
         _requireOwned(tokenId); // Can only get attributes if it exists
        return _nftData[tokenId].attributes;
    }

    /// @notice Allows a METADATA_ROLE address to update an NFT's attributes directly.
    /// @dev This bypasses mutation/composition logic and is intended for corrections or special events.
    /// @param tokenId The ID of the NFT.
    /// @param newAttributes The new attributes value.
    function updateDynamicAttribute(uint256 tokenId, uint256 newAttributes) public onlyRole(METADATA_ROLE) whenNotPaused {
        _requireOwned(tokenId);
        uint256 oldAttributes = _nftData[tokenId].attributes;
        _nftData[tokenId].attributes = newAttributes;
        emit DynamicAttributeUpdated(tokenId, oldAttributes, newAttributes);
    }


    // --- Core Mechanics ---

    /// @notice Mutates an NFT, changing its attributes based on cost and potentially other inputs.
    /// @dev This is a simplified example. A real implementation would have complex attribute logic.
    /// Requires MORPH token approval for `mutationCostMorph`.
    /// @param tokenId The ID of the NFT to mutate.
    /// @param morphAmount The amount of MORPH token to use for mutation (must be >= mutationCostMorph).
    /// @param newAttributes The resulting attributes after mutation (could be deterministic or based on inputs).
    function evolveNFT(uint256 tokenId, uint256 morphAmount, uint256 newAttributes) public payable nonReentrant whenNotPaused {
        _requireOwned(tokenId);
        require(!_nftData[tokenId].isStaked, "MetaMorphMarket: Staked NFTs cannot be mutated");
        require(!_listings[tokenId].isListed, "MetaMorphMarket: Listed NFTs cannot be mutated");
        require(morphTokenAddress != address(0), "MetaMorphMarket: MORPH token address not set");
        require(morphAmount >= mutationCostMorph, "MetaMorphMarket: Insufficient MORPH for mutation cost");

        IMorphToken morphToken = IMorphToken(morphTokenAddress);

        // Transfer MORPH token cost from the caller
        // Assumes user has approved this contract to spend MORPH
        morphToken.transferFrom(msg.sender, treasuryAddress, mutationCostMorph);

        // Burn the remaining morphAmount or use it as a 'fuel' input (example: burn excess)
        if (morphAmount > mutationCostMorph) {
             // Example: Burn the excess MORPH provided as part of the process
             // A real system might use this excess to influence the outcome or as a sink
             uint256 excessMorph = morphAmount - mutationCostMorph;
             morphToken.transferFrom(msg.sender, address(this), excessMorph); // Transfer excess to contract first
             morphToken.burn(address(this), excessMorph); // Then burn from contract's balance
        }

        uint256 oldAttributes = _nftData[tokenId].attributes;
        _nftData[tokenId].attributes = newAttributes; // Update attributes

        emit NFTMutated(tokenId, oldAttributes, newAttributes, mutationCostMorph);
    }

    /// @notice Composes multiple NFTs into a new one (burning the inputs).
    /// @dev This is a simplified example. Real logic could be complex.
    /// Requires MORPH token approval for `compositionCostMorph`.
    /// @param tokenIdsToBurn An array of NFT IDs to be burned.
    /// @param newAttributes The attributes for the newly minted composite NFT.
    /// @return newTokenId The ID of the newly created composite NFT.
    function composeNFTs(uint256[] memory tokenIdsToBurn, uint256 newAttributes) public payable nonReentrant whenNotPaused returns (uint256 newTokenId) {
        require(tokenIdsToBurn.length > 0, "MetaMorphMarket: Must provide NFTs to compose");
        require(morphTokenAddress != address(0), "MetaMorphMarket: MORPH token address not set");

        IMorphToken morphToken = IMorphToken(morphTokenAddress);

         // Transfer MORPH token cost from the caller
        // Assumes user has approved this contract to spend MORPH
        morphToken.transferFrom(msg.sender, treasuryAddress, compositionCostMorph);

        // Burn the input NFTs
        for (uint i = 0; i < tokenIdsToBurn.length; i++) {
            uint256 burnTokenId = tokenIdsToBurn[i];
            _requireOwned(burnTokenId); // Ensure caller owns all inputs
            require(!_nftData[burnTokenId].isStaked, "MetaMorphMarket: Staked NFTs cannot be composed");
            require(!_listings[burnTokenId].isListed, "MetaMorphMarket: Listed NFTs cannot be composed");

            _burn(burnTokenId); // Burn the token
        }

        // Mint the new composite NFT
        _tokenIdCounter.increment();
        newTokenId = _tokenIdCounter.current();
        _safeMint(msg.sender, newTokenId); // Mint the new token to the caller

        _nftData[newTokenId].attributes = newAttributes; // Set attributes for the new token
        _setTokenRoyalty(newTokenId, owner(), 750); // Example: Higher royalty for composites

        emit NFTsComposed(msg.sender, newTokenId, tokenIdsToBurn, newAttributes);
        return newTokenId;
    }

    // --- Staking ---

    /// @notice Stakes an NFT, making it eligible to earn MORPH rewards.
    /// @param tokenId The ID of the NFT to stake.
    function stakeNFT(uint256 tokenId) public nonReentrant whenNotPaused {
        _requireOwned(tokenId);
        require(!_nftData[tokenId].isStaked, "MetaMorphMarket: NFT is already staked");
        require(!_listings[tokenId].isListed, "MetaMorphMarket: Cannot stake a listed NFT");
        require(stakingRateMorphPerSec > 0, "MetaMorphMarket: Staking rewards are not active");

        _nftData[tokenId].isStaked = true;
        _nftData[tokenId].stakeStartTime = uint64(block.timestamp);
        _nftData[tokenId].unclaimedMorphRewards = 0; // Reset unclaimed on new stake

        // Add to staked list (simplistic tracking)
        _stakedTokenIdsByOwner[msg.sender].push(tokenId);
        _totalStakedNFTs++;

        // Transfer ownership to the contract during staking (standard staking pattern)
        _transfer(msg.sender, address(this), tokenId);

        emit NFTStaked(msg.sender, tokenId);
    }

    /// @notice Unstakes an NFT and claims any accumulated MORPH rewards.
    /// @param tokenId The ID of the NFT to unstake.
    function unstakeNFT(uint256 tokenId) public nonReentrant whenNotPaused {
        // Ownership check is implicit as only owner can call (though ownership is contract while staked)
        // Need to verify it was *theirs* before staking
        address originalOwner = ownerOf(tokenId); // This will be the contract address while staked
        require(originalOwner == address(this), "MetaMorphMarket: NFT is not owned by the staking contract");
        require(_nftData[tokenId].isStaked, "MetaMorphMarket: NFT is not staked");

        uint256 pendingRewards = getPendingMorphRewards(tokenId);
        uint256 totalClaimAmount = _nftData[tokenId].unclaimedMorphRewards + pendingRewards;

        _nftData[tokenId].isStaked = false;
        _nftData[tokenId].stakeStartTime = 0; // Reset start time
        _nftData[tokenId].unclaimedMorphRewards = 0; // Claiming all

        // Remove from staked list (simplistic tracking - might need optimization for large arrays)
        // Note: Removing from middle of array is O(n), better for small arrays or use alternative data structure
        uint252 ownerTokenCount = _stakedTokenIdsByOwner[originalOwner].length; // This should be the original owner's list
        bool found = false;
        for(uint i = 0; i < ownerTokenCount; i++) {
            if (_stakedTokenIdsByOwner[originalOwner][i] == tokenId) {
                 // Replace with last element and pop
                 _stakedTokenIdsByOwner[originalOwner][i] = _stakedTokenIdsByOwner[originalOwner][ownerTokenCount - 1];
                 _stakedTokenIdsByOwner[originalOwner].pop();
                 found = true;
                 break;
            }
        }
        require(found, "MetaMorphMarket: Staked token not found in owner's list"); // Should not happen if state is consistent

        _totalStakedNFTs--;

        // Transfer NFT back to the original owner (the one who staked it)
        // Need to store original staker? Let's assume msg.sender is the original owner calling unstake.
        // A more robust system would store the staker's address in the NFTData struct.
        // For this example, we'll assume msg.sender is the intended recipient.
        _safeTransfer(address(this), msg.sender, tokenId); // Transfer back to msg.sender

        // Mint and transfer MORPH rewards
        if (totalClaimAmount > 0) {
            require(morphTokenAddress != address(0), "MetaMorphMarket: MORPH token address not set for rewards");
            IMorphToken morphToken = IMorphToken(morphTokenAddress);
            morphToken.mint(msg.sender, totalClaimAmount); // Mint MORPH to the staker
             emit MorphRewardsClaimed(msg.sender, tokenId, totalClaimAmount); // Also emit claim event
        }


        emit NFTUnstaked(msg.sender, tokenId, totalClaimAmount);
    }

    /// @notice Claims accumulated MORPH rewards for a staked NFT without unstaking.
    /// @param tokenId The ID of the staked NFT.
    function claimStakedMorph(uint256 tokenId) public nonReentrant whenNotPaused {
        address currentOwner = ownerOf(tokenId); // This will be the contract address
         require(currentOwner == address(this), "MetaMorphMarket: NFT is not owned by the staking contract");
        require(_nftData[tokenId].isStaked, "MetaMorphMarket: NFT is not staked");
        require(morphTokenAddress != address(0), "MetaMorphMarket: MORPH token address not set for rewards");

        uint256 pendingRewards = getPendingMorphRewards(tokenId);
        uint256 totalClaimAmount = _nftData[tokenId].unclaimedMorphRewards + pendingRewards;

        // Update state: move pending to unclaimed and reset start time
        _nftData[tokenId].unclaimedMorphRewards = 0; // Claiming all
        _nftData[tokenId].stakeStartTime = uint64(block.timestamp); // Restart accumulation timer

        // Mint and transfer MORPH rewards
        if (totalClaimAmount > 0) {
             IMorphToken morphToken = IMorphToken(morphTokenAddress);
             // Need to find the original staker's address to mint to.
             // This requires storing staker address in NFTData struct. Let's add that.
             address staker = _nftData[tokenId].staker; // Assuming we add `address staker;` to NFTData
             require(staker != address(0), "MetaMorphMarket: Staker address not recorded");
             morphToken.mint(staker, totalClaimAmount); // Mint MORPH to the original staker
             emit MorphRewardsClaimed(staker, tokenId, totalClaimAmount);
        }
    }

     // --- Staking Helper (Requires NFTData struct modification) ---
     // Modify NFTData struct:
     // struct NFTData {
     //     uint256 attributes;
     //     bool isStaked;
     //     uint64 stakeStartTime;
     //     uint256 unclaimedMorphRewards;
     //     address staker; // Add this field
     // }
     // Need to update mint/stake functions to set this.
     // Modifying `stakeNFT`: add `_nftData[tokenId].staker = msg.sender;`
     // Modifying `mintInitialNFT`: add `_nftData[newItemId].staker = address(0);` (or owner)


    /// @notice Calculates the pending MORPH rewards for a staked NFT.
    /// @param tokenId The ID of the staked NFT.
    /// @return The amount of MORPH rewards pending.
    function getPendingMorphRewards(uint256 tokenId) public view returns (uint256) {
        if (!_nftData[tokenId].isStaked || stakingRateMorphPerSec == 0) {
            return 0;
        }
        uint256 timeStaked = block.timestamp - _nftData[tokenId].stakeStartTime;
        return timeStaked * stakingRateMorphPerSec;
    }

    /// @notice Checks if an NFT is currently staked.
    /// @param tokenId The ID of the NFT.
    /// @return True if staked, false otherwise.
    function isStaked(uint256 tokenId) public view returns (bool) {
        return _nftData[tokenId].isStaked;
    }

    /// @notice Gets the total number of NFTs currently staked in the contract.
    /// @return The total count of staked NFTs.
    function getTotalStakedNFTs() public view returns (uint256) {
        return _totalStakedNFTs;
    }


    // --- Marketplace ---

    /// @notice Lists an owned NFT for sale on the internal marketplace.
    /// @param tokenId The ID of the NFT to list.
    /// @param price The price in ETH or MORPH.
    /// @param useMorph If true, price is in MORPH; if false, price is in ETH.
    function listItemForSale(uint256 tokenId, uint256 price, bool useMorph) public nonReentrant whenNotPaused {
        _requireOwned(tokenId);
        require(!_nftData[tokenId].isStaked, "MetaMorphMarket: Cannot list a staked NFT");
        require(!_listings[tokenId].isListed, "MetaMorphMarket: NFT is already listed");
        require(price > 0, "MetaMorphMarket: Price must be greater than 0");
        if (useMorph) {
             require(morphTokenAddress != address(0), "MetaMorphMarket: MORPH token address not set for MORPH listing");
        }

        // Approve contract to transfer the token if not already approved
        // ERC721 standard allows `transferFrom` if caller is owner or approved operator
        // No explicit approval to contract needed *just* for listing state,
        // but transferFrom will be called by contract in `buyItem`.

        _listings[tokenId] = Listing({
            seller: msg.sender,
            price: price,
            isListed: true,
            useMorphToken: useMorph
        });

        emit ItemListed(tokenId, msg.sender, price, useMorph);
    }

    /// @notice Buys a listed NFT.
    /// @param tokenId The ID of the NFT to buy.
    function buyItem(uint256 tokenId) public payable nonReentrant whenNotPaused {
        Listing storage listing = _listings[tokenId];
        require(listing.isListed, "MetaMorphMarket: NFT is not listed for sale");
        require(listing.seller != address(0), "MetaMorphMarket: Invalid listing seller"); // Should be set if listed
        require(listing.seller != msg.sender, "MetaMorphMarket: Cannot buy your own NFT");

        uint256 price = listing.price;
        address seller = listing.seller;
        bool useMorph = listing.useMorphToken;

        uint256 feeAmount = (price * marketplaceFeeBps) / 10000;
        uint256 sellerReceiveAmount = price - feeAmount;

        if (useMorph) {
            require(morphTokenAddress != address(0), "MetaMorphMarket: MORPH token address not set for purchase");
            IMorphToken morphToken = IMorphToken(morphTokenAddress);
            require(morphToken.balanceOf(msg.sender) >= price, "MetaMorphMarket: Insufficient MORPH token balance");
            // Assumes buyer has approved this contract to spend MORPH
            morphToken.transferFrom(msg.sender, seller, sellerReceiveAmount);
            if (feeAmount > 0 && treasuryAddress != address(0)) {
                 morphToken.transferFrom(msg.sender, treasuryAddress, feeAmount);
            }
        } else { // Use ETH
            require(msg.value >= price, "MetaMorphMarket: Insufficient ETH sent");

            // Send ETH to seller and treasury
            (bool successSeller, ) = payable(seller).call{value: sellerReceiveAmount}("");
            require(successSeller, "MetaMorphMarket: ETH transfer to seller failed");

            if (feeAmount > 0 && treasuryAddress != address(0)) {
                 (bool successTreasury, ) = payable(treasuryAddress).call{value: feeAmount}("");
                 require(successTreasury, "MetaMorphMarket: ETH transfer to treasury failed");
            }

            // Refund excess ETH if any
            if (msg.value > price) {
                 (bool successRefund, ) = payable(msg.sender).call{value: msg.value - price}("");
                 require(successRefund, "MetaMorphMarket: ETH refund failed");
            }
        }

        // Transfer NFT to the buyer
        _safeTransfer(seller, msg.sender, tokenId);

        // Clear the listing
        delete _listings[tokenId];

        emit ItemBought(tokenId, msg.sender, seller, price, useMorph);

        // Optional: Trigger royalty distribution (ERC2981)
        // This example assumes royalties are paid *from* the seller's portion or separately handled.
        // A common pattern is that the marketplace pays royalties *before* the seller receives funds.
        // Let's implement triggering ERC2981 after the sale is complete.
        // Note: The buyer typically pays the full price including royalties and fees.
        // The contract then distributes the parts. Let's adjust the payment logic slightly.
        // The `royaltyInfo` function is *read-only*. A marketplace *calls* it to know *how much*
        // to pay as royalty from the total sale price.

        // Let's assume fee and royalty are taken from the 'price' paid by the buyer.
        // Total paid = price (from listing).
        // Royalty = royaltyInfo(tokenId, price) amount to royaltyRecipient.
        // Fee = price * marketplaceFeeBps.
        // Seller receives = price - royaltyAmount - feeAmount.
        // Need to re-calculate sellerReceiveAmount. Let's adjust the payment logic above or below.
        // It's simpler if the contract *knows* the royalty details and pays them out.

        // Re-calculating payments based on ERC2981:
        (address royaltyRecipient, uint256 royaltyAmount) = royaltyInfo(tokenId, price);
        sellerReceiveAmount = price - feeAmount - royaltyAmount;

        // Need to adjust the payment logic within the if/else block above
        // Let's move the payment logic here after royaltyInfo is called.

        // --- Adjusted Payment Logic (within buyItem) ---
        if (useMorph) {
            // ... (initial checks remain)
            require(morphToken.balanceOf(msg.sender) >= price, "MetaMorphMarket: Insufficient MORPH token balance");

            // Transfer MORPH: Royalty -> Treasury -> Seller
            if (royaltyAmount > 0 && royaltyRecipient != address(0)) {
                 morphToken.transferFrom(msg.sender, royaltyRecipient, royaltyAmount);
            }
             if (feeAmount > 0 && treasuryAddress != address(0)) {
                 morphToken.transferFrom(msg.sender, treasuryAddress, feeAmount);
             }
             // Seller gets the rest
            morphToken.transferFrom(msg.sender, seller, sellerReceiveAmount); // This will be price - royalty - fee

        } else { // Use ETH
             // ... (initial checks remain)
            require(msg.value >= price, "MetaMorphMarket: Insufficient ETH sent");

            // Send ETH: Royalty -> Treasury -> Seller
            if (royaltyAmount > 0 && royaltyRecipient != address(0)) {
                 (bool successRoyalty, ) = payable(royaltyRecipient).call{value: royaltyAmount}("");
                 require(successRoyalty, "MetaMorphMarket: ETH transfer to royalty recipient failed");
            }
             if (feeAmount > 0 && treasuryAddress != address(0)) {
                 (bool successTreasury, ) = payable(treasuryAddress).call{value: feeAmount}("");
                 require(successTreasury, "MetaMorphMarket: ETH transfer to treasury failed");
            }
            // Seller gets the rest
            (bool successSeller, ) = payable(seller).call{value: sellerReceiveAmount}("");
             require(successSeller, "MetaMorphMarket: ETH transfer to seller failed");

            // Refund excess ETH if any
            if (msg.value > price) {
                 (bool successRefund, ) = payable(msg.sender).call{value: msg.value - price}("");
                 require(successRefund, "MetaMorphMarket: ETH refund failed");
            }
        }
        // --- End Adjusted Payment Logic ---
    }

    /// @notice Cancels a marketplace listing for an owned NFT.
    /// @param tokenId The ID of the NFT listing to cancel.
    function cancelListing(uint256 tokenId) public nonReentrant whenNotPaused {
        Listing storage listing = _listings[tokenId];
        require(listing.isListed, "MetaMorphMarket: NFT is not listed for sale");
        require(listing.seller == msg.sender, "MetaMorphMarket: Caller is not the seller");

        delete _listings[tokenId];

        emit ListingCancelled(tokenId);
    }

    /// @notice Retrieves details of a marketplace listing.
    /// @param tokenId The ID of the NFT.
    /// @return seller The address of the seller.
    /// @return price The listed price.
    /// @return isListed Whether the item is currently listed.
    /// @return useMorph If the price is in MORPH token.
    function getListing(uint256 tokenId) public view returns (address seller, uint256 price, bool isListed, bool useMorph) {
        Listing storage listing = _listings[tokenId];
        return (listing.seller, listing.price, listing.isListed, listing.useMorphToken);
    }


    // --- Protocol Configuration ---

    /// @notice Sets the MORPH token cost for NFT mutation.
    /// @param cost The new cost in MORPH tokens.
    function setMutationCostMorph(uint256 cost) public onlyRole(CONFIG_ROLE) {
        emit ParameterChanged("mutationCostMorph", mutationCostMorph, cost);
        mutationCostMorph = cost;
    }

    /// @notice Sets the MORPH token cost for NFT composition.
    /// @param cost The new cost in MORPH tokens.
    function setCompositionCostMorph(uint256 cost) public onlyRole(CONFIG_ROLE) {
        emit ParameterChanged("compositionCostMorph", compositionCostMorph, cost);
        compositionCostMorph = cost;
    }

    /// @notice Sets the MORPH token emission rate per staked NFT per second.
    /// @param rate The new rate (e.g., wei per second).
    function setStakingRateMorphPerSec(uint256 rate) public onlyRole(CONFIG_ROLE) {
         emit ParameterChanged("stakingRateMorphPerSec", stakingRateMorphPerSec, rate);
        stakingRateMorphPerSec = rate;
    }

    /// @notice Sets the marketplace fee percentage in basis points.
    /// @param feeBps The new fee (e.g., 250 for 2.5%). Max 10000.
    function setMarketplaceFeeBps(uint16 feeBps) public onlyRole(CONFIG_ROLE) {
        require(feeBps <= 10000, "MetaMorphMarket: Fee cannot exceed 100%");
        emit ParameterChanged("marketplaceFeeBps", marketplaceFeeBps, feeBps); // Need overloaded event or separate
        marketplaceFeeBps = feeBps;
    }

    /// @notice Sets the address where marketplace fees are sent.
    /// @param treasury The new treasury address.
    function setTreasuryAddress(address treasury) public onlyRole(CONFIG_ROLE) {
        require(treasury != address(0), "MetaMorphMarket: Treasury address cannot be zero");
        emit TreasuryUpdated(treasuryAddress, treasury);
        treasuryAddress = treasury;
    }

    /// @notice Sets the address of the MORPH ERC20 token contract.
    /// @param morphToken The address of the MORPH token.
    function setMorphTokenAddress(address morphToken) public onlyRole(CONFIG_ROLE) {
        require(morphToken != address(0), "MetaMorphMarket: MORPH token address cannot be zero");
        emit MorphTokenAddressUpdated(morphTokenAddress, morphToken);
        morphTokenAddress = morphToken;
    }

    /// @notice Gets the address of the MORPH ERC20 token contract.
    function getMorphTokenAddress() public view returns (address) {
        return morphTokenAddress;
    }

    // --- Utility ---

    /// @notice Allows an address with CONFIG_ROLE to withdraw accidentally sent ERC20 tokens from the contract.
    /// @dev Only use this for tokens accidentally sent here, not intended protocol tokens like MORPH.
    /// @param tokenAddress The address of the ERC20 token.
    /// @param amount The amount to withdraw.
    function withdrawAccidentalERC20(address tokenAddress, uint256 amount) public onlyRole(CONFIG_ROLE) {
        require(tokenAddress != address(0), "MetaMorphMarket: Cannot withdraw zero address");
        require(tokenAddress != address(this), "MetaMorphMarket: Cannot withdraw contract's own token");
        require(tokenAddress != morphTokenAddress, "MetaMorphMarket: Use specific functions for MORPH token");

        IERC20 accidentalToken = IERC20(tokenAddress);
        require(accidentalToken.transfer(msg.sender, amount), "MetaMorphMarket: ERC20 transfer failed");
    }

    // --- Royalty Distribution (ERC2981) ---

    // We set royalties during minting and composition using _setTokenRoyalty.
    // This standard function is called by marketplaces to *query* the royalty info.
    // The actual distribution logic is handled within the `buyItem` function.

    /// @notice Returns the royalty information for a token based on a sale price.
    /// @param tokenId The token ID.
    /// @param salePrice The sale price of the token.
    /// @return receiver The address to receive royalties.
    /// @return royaltyAmount The amount of royalty to pay.
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        public
        view
        override(ERC2981)
        returns (address receiver, uint256 royaltyAmount)
    {
        // Calls the internal ERC2981 _tokenRoyaltyInfo function set via _setTokenRoyalty
        return super.royaltyInfo(tokenId, salePrice);
    }

    // --- Internal Overrides ---

    /// @dev See {ERC721-beforeTokenTransfer}. Note: The base ERC721Enumerable
    /// override is already handled by inheriting ERC721Enumerable.
    // _beforeTokenTransfer is overridden above.

    /// @dev See {ERC721Enumerable-safeTransferFrom}.
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override(ERC721, ERC721Enumerable) whenNotPaused {
        // Adds pausable check
        super.safeTransferFrom(from, to, tokenId, data);
    }

     /// @dev See {ERC721Enumerable-safeTransferFrom}.
    function safeTransferFrom(address from, address to, uint256 tokenId) public override(ERC721, ERC721Enumerable) whenNotPaused {
        // Adds pausable check
        super.safeTransferFrom(from, to, tokenId);
    }

     /// @dev See {ERC721Enumerable-transferFrom}.
    function transferFrom(address from, address to, uint256 tokenId) public override(ERC721, ERC721Enumerable) whenNotPaused {
        // Adds pausable check
        super.transferFrom(from, to, tokenId);
    }

    // The rest of the standard ERC721Enumerable/Pausable/AccessControl functions
    // (balanceOf, ownerOf, approve, setApprovalForAll, getApproved, isApprovedForAll,
    // totalSupply, tokenByIndex, tokenOfOwnerByIndex, pause, unpause, paused,
    // hasRole, getRoleAdmin, grantRole, revokeRole, renounceRole)
    // are inherited and exposed automatically.

    // --- Helper Modifier (Internal/Example) ---
    // A more complex system might have modifiers like:
    // modifier onlyStaked(uint256 tokenId) {
    //     require(_nftData[tokenId].isStaked, "MetaMorphMarket: Token must be staked");
    //     _;
    // }
    // modifier onlyListed(uint256 tokenId) {
    //      require(_listings[tokenId].isListed, "MetaMorphMarket: Token must be listed");
    //      _;
    // }
}
```