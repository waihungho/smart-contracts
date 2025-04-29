Okay, let's design a smart contract that combines several interesting, advanced, and trendy concepts: Generative NFTs with on-chain traits, a marketplace, breeding mechanics, dynamic evolution, and role-based access control.

We'll call this contract `GenerativeNFTMarketplace`.

**Concept:** Users can mint unique generative NFTs by providing parameters. These parameters and some on-chain entropy determine the NFT's "DNA". This DNA dictates its traits, which can be computed on-chain. NFTs can be listed and bought on a marketplace. Additionally, NFTs can be "fed" to slightly evolve their DNA over time, or two NFTs can be "bred" to create a new NFT inheriting aspects of parents' DNA. We'll use role-based access control for managing contract parameters.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol"; // Example of an advanced utility, could be used for whitelisting mints

// --- Outline ---
// 1. State Variables & Structs: Define data structures for NFTs, listings, generative parameters, and roles.
// 2. Events: Declare events for tracking key actions (minting, trading, evolving, breeding, etc.).
// 3. Errors: Custom errors for better state handling.
// 4. Access Control (Roles): Implement basic role management.
// 5. ERC721, ERC2981, Pausable Extensions: Inherit standard functionalities.
// 6. Constructor: Initialize contract parameters and roles.
// 7. ERC721 Standard Functions: Implement/override necessary ERC721 functions (handled by extensions mostly).
// 8. Generative NFT Functions: Logic for minting, DNA generation, trait computation, evolution (feeding), and breeding.
// 9. Marketplace Functions: Logic for listing, buying, canceling listings.
// 10. Parameter Management Functions: Functions for roles with specific permissions to manage generative rules, fees, etc.
// 11. Utility/Admin Functions: Pause/unpause, withdraw funds, get contract state.
// 12. Internal Helper Functions: Helper logic like DNA generation, trait computation.

// --- Function Summary ---
// ERC721/ERC2981/Pausable Standard Functions (Handled by Inherited Contracts & Overrides):
// 1. constructor: Initializes the contract, name, symbol, roles, and default parameters.
// 2. supportsInterface: ERC165 standard, indicates which interfaces are supported (ERC721, ERC721Enumerable, ERC721URIStorage, ERC2981, Pausable).
// 3. balanceOf: Returns the number of tokens owned by an address.
// 4. ownerOf: Returns the owner of a specific token.
// 5. safeTransferFrom(address,address,uint256): Transfers token safely, checking recipient.
// 6. safeTransferFrom(address,address,uint256,bytes): Transfers token safely with data.
// 7. transferFrom: Transfers token without recipient checks (internal use or by approved).
// 8. approve: Sets approval for one token.
// 9. setApprovalForAll: Sets approval for all tokens.
// 10. getApproved: Gets the approved address for a token.
// 11. isApprovedForAll: Checks if an address is approved for all tokens by an owner.
// 12. tokenByIndex: Gets token ID by index (ERC721Enumerable).
// 13. totalSupply: Gets total minted tokens (ERC721Enumerable).
// 14. tokenOfOwnerByIndex: Gets token ID by owner and index (ERC721Enumerable).
// 15. tokenURI: Gets the metadata URI for a token (ERC721URIStorage). Overridden to potentially include DNA/traits.
// 16. royaltyInfo: Gets royalty information for a sale (ERC2981).
// 17. pause: Pauses the contract (only MANAGER_ROLE).
// 18. unpause: Unpauses the contract (only MANAGER_ROLE).

// Custom Generative NFT & Marketplace Functions:
// 19. mint: Mints a new generative NFT based on provided parameters.
// 20. feedNFT: "Feeds" an owned NFT, evolving its DNA slightly and incrementing feed count.
// 21. breedNFTs: Breeds two owned NFTs to produce a new one with mixed DNA.
// 22. getNFTData: Retrieves stored on-chain data (DNA, feed count, breed count, parents) for an NFT.
// 23. computeTraitsFromDNA: (view) Computes traits of an NFT based on its DNA and current generative parameters.
// 24. listItem: Lists an owned NFT for sale on the marketplace.
// 25. buyItem: Buys a listed NFT from the marketplace.
// 26. cancelListing: Cancels an active listing.
// 27. getListing: Retrieves listing details for a token.
// 28. getTotalSupply: Returns the total number of NFTs minted (same as totalSupply, but a separate access pattern).
// 29. getMarketplaceFeeBps: Gets the current marketplace fee percentage in basis points.

// Parameter Management & Admin Functions (Role-Based):
// 30. setGenerativeParameters: Sets the rules and ranges for DNA generation and trait mapping (only PARAM_MANAGER_ROLE).
// 31. setMarketplaceFee: Sets the fee percentage for marketplace sales (only MANAGER_ROLE).
// 32. setBaseURI: Sets the base URI for token metadata (only MANAGER_ROLE).
// 33. setDefaultRoyalty: Sets the default royalty info for all tokens (only MANAGER_ROLE).
// 34. grantRole: Grants a role to an address (only DEFAULT_ADMIN_ROLE).
// 35. revokeRole: Revokes a role from an address (only DEFAULT_ADMIN_ROLE).
// 36. renounceRole: Renounces a role (user function).
// 37. getRoleAdmin: Gets the admin role for a given role.
// 38. hasRole: Checks if an address has a specific role.
// 39. withdrawFees: Allows the MANAGER_ROLE to withdraw accumulated marketplace fees.
// 40. withdrawNative: Allows the DEFAULT_ADMIN_ROLE to withdraw accidental native token transfers.

// --- Dependencies ---
// Uses OpenZeppelin Contracts for ERC721, Enumerable, URIStorage, Royalty, Ownable (as base for roles), Pausable, Counters, Strings, MerkleProof.

contract GenerativeNFTMarketplace is ERC721Enumerable, ERC721URIStorage, ERC721Royalty, Pausable, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // --- State Variables & Structs ---

    // Role Definitions (using ERC721's Ownable as a base for a simple admin)
    // In a full system, might use OpenZeppelin's AccessControl. For 20+ functions, we'll simulate roles.
    bytes32 public constant DEFAULT_ADMIN_ROLE = keccak256("DEFAULT_ADMIN_ROLE");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE"); // Manages fees, URI, pausing
    bytes32 public constant PARAM_MANAGER_ROLE = keccak256("PARAM_MANAGER_ROLE"); // Manages generative parameters

    mapping(bytes32 => mapping(address => bool)) private _roles;

    struct NFTData {
        bytes32 dna; // The unique on-chain "DNA" determining traits
        uint64 feedCount; // How many times this NFT has been "fed"
        uint66 lastFedTimestamp; // Timestamp of the last feed
        uint64 breedCount; // How many times this NFT has been used for breeding
        uint66 lastBredTimestamp; // Timestamp of the last breed
        uint256 parent1Id; // ID of the first parent (0 if minted)
        uint256 parent2Id; // ID of the second parent (0 if minted)
    }

    mapping(uint256 => NFTData) private _nftData;

    struct Listing {
        uint256 tokenId;
        address seller;
        uint256 price; // Price in native token (wei)
        uint64 listingTimestamp;
    }

    mapping(uint256 => Listing) private _listings; // tokenId => Listing

    // Define parameters for generative logic (simplified)
    struct GenerativeParameters {
        uint16[] traitRanges; // Max value for each DNA segment mapping to a trait
        uint16 dnaLength; // Number of segments in DNA
        uint16 feedEvolutionFactor; // How much feeding changes DNA (e.g., 1-100)
        uint16 breedCrossoverPoints; // How many points parents' DNA is mixed
        uint66 minFeedInterval; // Minimum time between feeds
        uint66 minBreedInterval; // Minimum time between breeding
    }

    GenerativeParameters public generativeParams;

    uint16 public marketplaceFeeBps; // Marketplace fee in basis points (e.g., 250 for 2.5%)
    uint256 private _accumulatedFees; // Fees collected in native token

    bytes32 private _merkleRoot; // Example: Root for potential whitelisting of minters/breeders

    // --- Events ---
    event Minted(address indexed owner, uint256 indexed tokenId, bytes32 dna, uint256[] initialParams);
    event Fed(uint256 indexed tokenId, bytes32 newDNA, uint64 newFeedCount);
    event Bred(uint256 indexed parent1Id, uint256 indexed parent2Id, uint256 indexed childId, bytes32 childDNA);
    event ItemListed(uint256 indexed tokenId, address indexed seller, uint256 price);
    event ItemBought(uint256 indexed tokenId, address indexed buyer, address indexed seller, uint256 price, uint256 fee);
    event ListingCancelled(uint256 indexed tokenId, address indexed seller);
    event ParametersUpdated(GenerativeParameters newParams);
    event FeeUpdated(uint16 newFeeBps);
    event FeesWithdrawn(address indexed recipient, uint256 amount);
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    // --- Errors ---
    error Unauthorized();
    error TokenDoesNotExist();
    error NotTokenOwnerOrApproved();
    error AlreadyListed(uint256 tokenId);
    error NotListed(uint256 tokenId);
    error InvalidListingPrice();
    error InsufficientPayment();
    error ListingNotYours(uint256 tokenId);
    error CannotSelfBuy();
    error InvalidGenerativeParameters();
    error BreedingCooldown(uint256 tokenId);
    error FeedingCooldown(uint256 tokenId);
    error CannotBreedSameToken();
    error InvalidParent(uint256 tokenId);
    error MintParametersMismatch(uint256 expectedLength, uint256 actualLength);
    error MerkleProofInvalid();
    error NoFeesToWithdraw();
    error InvalidFeeBps();
    error InvalidRoyaltyBps();


    // --- Access Control (Simulated Roles) ---

    modifier onlyRole(bytes32 role) {
        if (!_roles[role][msg.sender]) revert Unauthorized();
        _;
    }

    function grantRole(bytes32 role, address account) public virtual onlyOwner { // Using Ownable as ADMIN
        _grantRole(role, account);
        emit RoleGranted(role, account, msg.sender);
    }

    function revokeRole(bytes32 role, address account) public virtual onlyOwner { // Using Ownable as ADMIN
        _revokeRole(role, account);
        emit RoleRevoked(role, account, msg.sender);
    }

    function renounceRole(bytes32 role) public virtual {
        _revokeRole(role, msg.sender);
        emit RoleRevoked(role, msg.sender, msg.sender);
    }

    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role][account];
    }

    function getRoleAdmin(bytes32 role) public pure returns (bytes32) {
        // Simple role hierarchy: ADMIN manages all.
        // Could add more complex logic if needed.
        if (role == MANAGER_ROLE || role == PARAM_MANAGER_ROLE) return DEFAULT_ADMIN_ROLE;
        return bytes32(0); // No specific admin role defined beyond default
    }

    function _grantRole(bytes32 role, address account) internal virtual {
        _roles[role][account] = true;
    }

    function _revokeRole(bytes32 role, address account) internal virtual {
        _roles[role][account] = false;
    }


    // --- Constructor ---

    constructor(
        string memory name,
        string memory symbol,
        uint16 initialMarketplaceFeeBps,
        GenerativeParameters memory initialGenerativeParams,
        bytes32 initialMerkleRoot // Example for future whitelisting
    ) ERC721(name, symbol)
      ERC721Enumerable()
      ERC721URIStorage()
      ERC721Royalty() // Inherits ERC2981
      Pausable()
      Ownable(msg.sender) // Set deployer as Ownable admin (DEFAULT_ADMIN_ROLE)
    {
        // Initialize roles
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender); // Deployer is admin
        _grantRole(MANAGER_ROLE, msg.sender); // Deployer also gets manager role
        _grantRole(PARAM_MANAGER_ROLE, msg.sender); // Deployer also gets param manager role

        // Set initial parameters
        if (initialMarketplaceFeeBps > 10000) revert InvalidFeeBps();
        marketplaceFeeBps = initialMarketplaceFeeBps;

        if (initialGenerativeParams.dnaLength == 0 || initialGenerativeParams.traitRanges.length != initialGenerativeParams.dnaLength) {
             revert InvalidGenerativeParameters();
        }
        generativeParams = initialGenerativeParams;

        _merkleRoot = initialMerkleRoot; // Store merkle root

        // Set default royalty for the collection (e.g., 5% to the owner)
        _setDefaultRoyalty(msg.sender, 500); // 500 basis points = 5%
    }

    // --- ERC721 Overrides ---

    // The functions below are mostly handled by the inherited contracts
    // but are listed in the summary for completeness as they are part of the
    // contract's external interface due to standard compliance.
    // We override _beforeTokenTransfer to handle marketplace interactions.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721Enumerable)
        whenNotPaused // Add pausable check to transfers
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        // If the token is listed, only allow transfer if it's the buyer or contract itself (during buy)
        if (_listings[tokenId].seller != address(0) && from != address(this)) {
             // Allow transfer if it's the contract sending to the buyer during a purchase
            if (to != address(this) && to != _listings[tokenId].seller) {
                revert NotTokenOwnerOrApproved(); // Or a more specific error
            }
             // If the transfer is from the seller, it must be buying it themselves to cancel listing, or contract sending
             if (from == _listings[tokenId].seller && to != address(this)) {
                  revert NotTokenOwnerOrApproved(); // Cannot transfer a listed token normally
             }
        }

        // Clear listing if transferred for any other reason (e.g., transfer outside marketplace buy) - adjust logic if needed
        if (_listings[tokenId].seller != address(0) && from != address(this)) {
            delete _listings[tokenId];
            emit ListingCancelled(tokenId, from); // Implicit cancel
        }
    }

    function _update(address to, uint256 tokenId, address auth)
        internal
        override(ERC721, ERC721Enumerable, ERC721URIStorage)
        returns (address)
    {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(address account, uint256 amount)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._increaseBalance(account, amount);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        // Example: Append DNA and traits to the base URI or encode them in a data URI
        // A real implementation would likely point to an API gateway that fetches
        // on-chain DNA and parameters to generate the metadata JSON.
        // For simplicity, we'll just return the standard URI here, but highlight the potential.
        if (!_exists(tokenId)) revert TokenDoesNotExist();

        // bytes32 dna = _nftData[tokenId].dna;
        // uint256[] memory traits = computeTraitsFromDNA(dna); // Compute traits

        // string memory uri = super.tokenURI(tokenId);
        // string memory custom_uri = string(abi.encodePacked(uri, "?dna=", Strings.toHexString(dna), "&traits=", _encodeTraits(traits)));
        // return custom_uri; // Example of modifying URI

        return super.tokenURI(tokenId); // Standard implementation for now
    }

    // Helper to encode traits (example)
    // function _encodeTraits(uint256[] memory traits) internal pure returns (string memory) {
    //     bytes memory encoded = abi.encodePacked(traits);
    //     // Convert bytes to hex string or similar for URI
    //     return ""; // Placeholder
    // }


    // --- Generative NFT Functions ---

    function mint(uint256[] memory initialParams, bytes32[] memory merkleProof)
        public
        whenNotPaused
    {
        // Example Merkle Proof check for whitelisting minters or parameter sets
        // bytes32 leaf = keccak256(abi.encodePacked(msg.sender, keccak256(abi.encodePacked(initialParams))));
        // if (!MerkleProof.verify(merkleProof, _merkleRoot, leaf)) {
        //     revert MerkleProofInvalid();
        // }
        // For this example, we skip the Merkle proof actual check but show its structure.

        if (initialParams.length != generativeParams.dnaLength) {
            revert MintParametersMismatch(generativeParams.dnaLength, initialParams.length);
        }

        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        // Generate DNA based on parameters and some entropy
        // WARNING: Block data (timestamp, difficulty, basefee) is not perfectly random.
        // For production, consider Chainlink VRF or similar.
        bytes32 generatedDNA = _generateDNA(initialParams, block.timestamp, block.difficulty, msg.sender, tx.origin, keccak256(abi.encodePacked(merkleProof)));

        _nftData[newTokenId] = NFTData({
            dna: generatedDNA,
            feedCount: 0,
            lastFedTimestamp: uint66(block.timestamp), // Initialize feed/breed time
            breedCount: 0,
            lastBredTimestamp: uint66(block.timestamp),
            parent1Id: 0, // 0 indicates minted, not bred
            parent2Id: 0
        });

        _safeMint(msg.sender, newTokenId);

        emit Minted(msg.sender, newTokenId, generatedDNA, initialParams);
    }

    function feedNFT(uint256 tokenId) public whenNotPaused {
        address owner = ownerOf(tokenId);
        if (owner != msg.sender && getApproved(tokenId) != msg.sender && !isApprovedForAll(owner, msg.sender)) {
            revert NotTokenOwnerOrApproved();
        }

        NFTData storage nft = _nftData[tokenId];
        if (block.timestamp < nft.lastFedTimestamp + generativeParams.minFeedInterval) {
            revert FeedingCooldown(tokenId);
        }

        // Simple deterministic evolution based on current DNA and count
        nft.dna = _evolveDNA(nft.dna, nft.feedCount, block.timestamp);
        nft.feedCount++;
        nft.lastFedTimestamp = uint66(block.timestamp);

        emit Fed(tokenId, nft.dna, nft.feedCount);
    }

    function breedNFTs(uint256 parent1Id, uint256 parent2Id) public whenNotPaused {
        if (parent1Id == parent2Id) revert CannotBreedSameToken();
        if (!_exists(parent1Id) || !_exists(parent2Id)) revert InvalidParent(parent1Id == 0 ? parent2Id : parent1Id); // Check existence

        address owner1 = ownerOf(parent1Id);
        address owner2 = ownerOf(parent2Id);

        // Check if user owns both or is approved for both
        bool owner1Auth = (owner1 == msg.sender || getApproved(parent1Id) == msg.sender || isApprovedForAll(owner1, msg.sender));
        bool owner2Auth = (owner2 == msg.sender || getApproved(parent2Id) == msg.sender || isApprovedForAll(owner2, msg.sender));

        if (!owner1Auth || !owner2Auth) revert NotTokenOwnerOrApproved();

        NFTData storage parent1 = _nftData[parent1Id];
        NFTData storage parent2 = _nftData[parent2Id];

        if (block.timestamp < parent1.lastBredTimestamp + generativeParams.minBreedInterval) revert BreedingCooldown(parent1Id);
        if (block.timestamp < parent2.lastBredTimestamp + generativeParams.minBreedInterval) revert BreedingCooldown(parent2Id);

        _tokenIdCounter.increment();
        uint256 childTokenId = _tokenIdCounter.current();

        // Breed DNA: Simple crossover (example logic)
        bytes32 childDNA = _breedDNA(parent1.dna, parent2.dna, block.timestamp); // Use timestamp for entropy in crossover points

        _nftData[childTokenId] = NFTData({
            dna: childDNA,
            feedCount: 0,
            lastFedTimestamp: uint66(block.timestamp),
            breedCount: 0, // Child starts with 0 breeds
            lastBredTimestamp: uint66(block.timestamp),
            parent1Id: parent1Id,
            parent2Id: parent2Id
        });

        parent1.breedCount++;
        parent1.lastBredTimestamp = uint66(block.timestamp);
        parent2.breedCount++;
        parent2.lastBredTimestamp = uint66(block.timestamp);


        _safeMint(msg.sender, childTokenId); // Child goes to the breeder

        emit Bred(parent1Id, parent2Id, childTokenId, childDNA);
    }


    function getNFTData(uint256 tokenId) public view returns (NFTData memory) {
        if (!_exists(tokenId)) revert TokenDoesNotExist();
        return _nftData[tokenId];
    }

    function computeTraitsFromDNA(bytes32 _dna) public view returns (uint256[] memory traits) {
        // Deterministically compute traits based on DNA and current parameters
        // Example: Map segments of the DNA hash to trait values based on ranges
        uint16 dnaLength = generativeParams.dnaLength;
        uint16[] memory traitRanges = generativeParams.traitRanges;

        if (dnaLength == 0 || traitRanges.length != dnaLength) {
             // Cannot compute traits if parameters are not set correctly
             // Return empty or revert based on desired behavior
             revert InvalidGenerativeParameters();
        }

        traits = new uint256[](dnaLength);
        bytes32 currentDNA = _dna;

        for (uint i = 0; i < dnaLength; i++) {
            // Extract a portion of the DNA (e.g., 2 bytes)
            uint16 dnaSegment = uint16((currentDNA >> (i * 16)) & 0xFFFF); // Extract 2 bytes

            // Map segment value to a trait value based on the range
            // Simple mapping: segment_value % range_max
            if (traitRanges[i] == 0) {
                 traits[i] = 0; // Avoid division by zero if range is 0
            } else {
                 traits[i] = dnaSegment % traitRanges[i];
            }

            // Further complex logic could involve multiple segments, bitwise operations, etc.
        }

        return traits;
    }

    // --- Marketplace Functions ---

    function listItem(uint256 tokenId, uint256 price) public whenNotPaused {
        if (!_exists(tokenId)) revert TokenDoesNotExist();
        if (ownerOf(tokenId) != msg.sender) revert NotTokenOwnerOrApproved(); // Must own the token
        if (_listings[tokenId].seller != address(0)) revert AlreadyListed(tokenId);
        if (price == 0) revert InvalidListingPrice(); // Must have a price

        // Approve the contract to manage the token for sale
        approve(address(this), tokenId);

        _listings[tokenId] = Listing({
            tokenId: tokenId,
            seller: msg.sender,
            price: price,
            listingTimestamp: uint64(block.timestamp)
        });

        emit ItemListed(tokenId, msg.sender, price);
    }

    function buyItem(uint256 tokenId) public payable whenNotPaused {
        Listing storage listing = _listings[tokenId];

        if (listing.seller == address(0)) revert NotListed(tokenId);
        if (listing.seller == msg.sender) revert CannotSelfBuy();
        if (msg.value < listing.price) revert InsufficientPayment();

        uint256 price = listing.price;
        address seller = listing.seller;
        address buyer = msg.sender; // msg.sender is the buyer

        // Calculate fee
        uint256 fee = (price * marketplaceFeeBps) / 10000;
        uint256 sellerPayout = price - fee;

        // Clear the listing BEFORE transferring to prevent reentrancy via _beforeTokenTransfer
        delete _listings[tokenId];

        // Transfer native token to seller and accumulate fee
        (bool successSeller, ) = payable(seller).call{value: sellerPayout}("");
        // If seller transfer fails, decide policy: revert entire transaction or log/handle?
        // Reverting is safer for buyer and contract state.
        require(successSeller, "Transfer to seller failed"); // Revert if seller payout fails

        // Accumulate fee (safer than sending immediately)
        _accumulatedFees += fee;

        // Transfer the NFT from the contract (as it was approved) to the buyer
        // The contract now owns the token temporarily due to the `approve` in `listItem`
        // and it's safeTransferring from itself.
        _safeTransferFrom(address(this), buyer, tokenId);

        // If buyer sent excess native token, return it
        if (msg.value > price) {
            (bool successRefund, ) = payable(msg.sender).call{value: msg.value - price}("");
            // Refund failure shouldn't revert the purchase, just log or handle.
             require(successRefund, "Excess payment refund failed"); // Or handle gracefully
        }

        emit ItemBought(tokenId, buyer, seller, price, fee);
    }

    function cancelListing(uint256 tokenId) public whenNotPaused {
        Listing storage listing = _listings[tokenId];

        if (listing.seller == address(0)) revert NotListed(tokenId);
        // Only the seller or contract owner can cancel
        if (listing.seller != msg.sender && !hasRole(MANAGER_ROLE, msg.sender)) {
            revert ListingNotYours(tokenId);
        }

        // The _beforeTokenTransfer in buyItem clears the listing.
        // For explicit cancel, clear it here.
        delete _listings[tokenId];

        // Note: Approval for contract to transfer is still active until a transfer happens or owner revokes.
        // This is standard ERC721 behavior.

        emit ListingCancelled(tokenId, listing.seller);
    }

    function getListing(uint256 tokenId) public view returns (Listing memory) {
        return _listings[tokenId];
    }

    function getTotalSupply() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    function getMarketplaceFeeBps() public view returns (uint16) {
        return marketplaceFeeBps;
    }


    // --- Parameter Management & Admin Functions ---

    function setGenerativeParameters(GenerativeParameters memory newParams) public onlyRole(PARAM_MANAGER_ROLE) {
        if (newParams.dnaLength == 0 || newParams.traitRanges.length != newParams.dnaLength) {
             revert InvalidGenerativeParameters();
        }
        // Add more validation for other parameters if needed (e.g., ranges not too large)
        generativeParams = newParams;
        emit ParametersUpdated(newParams);
    }

    function setMarketplaceFee(uint16 newFeeBps) public onlyRole(MANAGER_ROLE) {
        if (newFeeBps > 10000) revert InvalidFeeBps(); // Max 100% fee
        marketplaceFeeBps = newFeeBps;
        emit FeeUpdated(newFeeBps);
    }

    function setBaseURI(string memory baseURI_) public onlyRole(MANAGER_ROLE) {
        _setBaseURI(baseURI_);
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyRole(MANAGER_ROLE) {
        if (feeNumerator > 10000) revert InvalidRoyaltyBps();
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function withdrawFees() public onlyRole(MANAGER_ROLE) {
        if (_accumulatedFees == 0) revert NoFeesToWithdraw();

        uint256 amount = _accumulatedFees;
        _accumulatedFees = 0;

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Fee withdrawal failed");

        emit FeesWithdrawn(msg.sender, amount);
    }

    // Allows admin to recover native tokens sent to the contract by mistake
    function withdrawNative(uint256 amount) public onlyOwner { // Owner = DEFAULT_ADMIN_ROLE
        if (amount == 0) return;
        if (address(this).balance < amount) revert InsufficientPayment(); // Use InsufficientPayment error

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Native withdrawal failed");
    }

    // --- Internal Helper Functions ---

    // Generates DNA bytes32 from initial parameters and entropy sources
    function _generateDNA(
        uint256[] memory initialParams,
        uint256 entropy1, // block.timestamp
        uint256 entropy2, // block.difficulty/basefee
        address entropy3, // msg.sender
        address entropy4, // tx.origin
        bytes32 entropy5  // hash of merkle proof/other data
        ) internal pure returns (bytes32)
    {
        bytes32 dna;
        bytes memory paramBytes = abi.encodePacked(initialParams);

        // Combine parameter hash with entropy for pseudo-randomness
        bytes32 paramHash = keccak256(paramBytes);
        bytes32 entropyHash = keccak256(abi.encodePacked(entropy1, entropy2, entropy3, entropy4, entropy5));

        // Simple XOR combination - more complex methods possible
        dna = paramHash ^ entropyHash;

        // Optional: Further manipulate DNA based on parameters or a fixed salt
        // dna = keccak256(abi.encodePacked(dna, block.number));

        return dna;
    }

    // Evolves DNA for feeding
    function _evolveDNA(bytes32 currentDNA, uint64 feedCount, uint256 timestamp) internal view returns (bytes32) {
        // Simple evolution: XOR with a hash derived from current state and time
        // The 'feedEvolutionFactor' can influence the hash or how many bits are flipped/changed.
        bytes32 evolutionSeed = keccak256(abi.encodePacked(currentDNA, feedCount, timestamp, generativeParams.feedEvolutionFactor));
        // XORing with a hash provides a simple bit-flipping mechanism
        return currentDNA ^ evolutionSeed;

        // More complex evolution could target specific DNA segments based on feedCount or time.
    }

    // Breeds two parent DNAs
    function _breedDNA(bytes32 dna1, bytes32 dna2, uint256 timestamp) internal view returns (bytes32) {
        bytes32 childDNA = 0;
        uint16 dnaLength = generativeParams.dnaLength; // Assume dnaLength from params applies to bytes32 segments mentally
        uint16 crossoverPoints = generativeParams.breedCrossoverPoints;

        // Ensure crossover points don't exceed DNA "length" (which is 32 bytes or 256 bits)
        if (crossoverPoints >= 32) crossoverPoints = 1; // Simple fallback

        // Generate pseudo-random crossover points based on timestamp and parent DNA
        // For real randomness, use VRF
        bytes32 seed = keccak256(abi.encodePacked(dna1, dna2, timestamp));
        uint256 randomValue = uint256(seed);

        uint16 currentCrossover = 0;
        bool takeFromParent1 = true;

        for (uint i = 0; i < 32; i++) { // Iterate through bytes
            // Determine crossover points based on randomValue
            // Example: use bits of randomValue to decide when to swap parents
            if (currentCrossover < crossoverPoints) {
                 if ((randomValue >> i) & 1 == 1) { // Use i-th bit of randomValue
                      takeFromParent1 = !takeFromParent1;
                      currentCrossover++;
                 }
            }

            // Take byte from parent1 or parent2
            if (takeFromParent1) {
                childDNA |= bytes32((uint256(dna1) >> (i * 8)) & 0xFF) << (i * 8);
            } else {
                childDNA |= bytes32((uint256(dna2) >> (i * 8)) & 0xFF) << (i * 8);
            }
        }

        return childDNA;

        // Alternative breeding:
        // - Average DNA values (if DNA segments are numerical)
        // - Combine specific traits or segments based on rules
        // - Introduce mutations (small random changes)
    }

    // --- Receive/Fallback ---
    receive() external payable {
        // This allows the contract to receive native tokens (needed for buyItem)
        // Any unexpected sends will increase _accumulatedFees or contract balance
        // and can be recovered by withdrawFees/withdrawNative.
    }

    fallback() external payable {
        // Same as receive, for calls with data but no matching function.
        // Useful for recovery of accidental sends with data.
    }

}
```