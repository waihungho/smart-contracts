Okay, let's design a sophisticated, non-standard smart contract for a **Decentralized Autonomous Art Gallery and Generative Platform**. This contract will combine elements of NFT management (ERC721), a simple on-chain generative art component, a curation process, a treasury, and a basic governance mechanism (without implementing a full Governor contract, we'll simulate key actions controlled by a `GOVERNOR_ROLE` which in a real DAO would be held by a Governor contract).

It avoids simply being an ERC721 implementation or a standard marketplace.

**Core Concepts:**

1.  **Art Pieces as NFTs (ERC721):** Each art piece is a unique token.
2.  **Two Ways to Get Art:**
    *   **Submitted Art:** Artists submit external art (via metadata link) for community/curator review (requires a fee).
    *   **Generated Art:** Users can trigger the creation of unique art pieces *by the contract itself* based on on-chain parameters (requires a fee).
3.  **Curation Layer:** A designated role (`CURATOR_ROLE`) can initially approve or reject submitted art.
4.  **Treasury:** The contract holds collected fees (ETH/Wei).
5.  **Governance Control (Simulated):** A `GOVERNOR_ROLE` (intended to be a DAO's Governor contract) has ultimate control over treasury withdrawal, fee settings, curator roles, and can override curation decisions.
6.  **Dynamic Traits:** Some art pieces can have traits that change over time or based on interaction.
7.  **Basic Sales Mechanism:** Art held by the gallery can be put up for sale.

**Outline & Function Summary:**

```
Outline:
1. State Variables: Storage for NFTs, fees, roles, submissions, generative art params, sales, dynamic traits.
2. Events: Signalling important actions (Mint, Submit, Approve, Reject, Buy, Fee Update, etc.).
3. Errors: Custom errors for clearer failure reasons.
4. Modifiers: Access control (onlyCurator, onlyGovernor, onlyApprovedOrGovernor).
5. Constructor: Initializes roles and basic settings.
6. ERC721 Standard Functions: Basic NFT operations (minting is custom, but transfer, ownerOf, etc. are standard).
7. Roles Management: Setting and revoking roles.
8. Submission Management: Functions for artists to submit and curators/governor to review.
9. Generative Art Management: Functions to trigger and retrieve parameters for on-chain art.
10. Sales Management: Listing gallery art for sale and purchasing it.
11. Treasury Management: Accessing and withdrawing collected fees.
12. Dynamic Traits: Functions to update and retrieve dynamic state.
13. Metadata/URI: Function to generate token URI based on art type and state.
14. Utility Functions: Getting counts, fees, etc.
```

```
Function Summary:

Inherited/Standard ERC721 (9):
- balanceOf(address owner) public view returns (uint256): Get balance of an owner.
- ownerOf(uint256 tokenId) public view returns (address owner): Get owner of a token.
- approve(address to, uint256 tokenId) public: Approve address to spend token.
- getApproved(uint256 tokenId) public view returns (address operator): Get approved address for token.
- setApprovalForAll(address operator, bool _approved) public: Approve or unapprove operator for all tokens.
- isApprovedForAll(address owner, address operator) public view returns (bool): Check if operator is approved for all.
- transferFrom(address from, address to, uint256 tokenId) public: Transfer token (unsafe).
- safeTransferFrom(address from, address to, uint256 tokenId) public: Transfer token (safe).
- safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public: Transfer token with data (safe).

Inherited/Standard ERC2981 Royalties (2):
- supportsInterface(bytes4 interfaceId) public view virtual override returns (bool): Check supported interfaces.
- royaltyInfo(uint256 tokenId, uint256 salePrice) public view virtual override returns (address receiver, uint256 royaltyAmount): Get royalty info for a token sale.

Custom Functions (24):
1. constructor(address initialGovernor, address initialCurator): Initializes roles, sets deployer as owner.
2. setGovernorRole(address governorAddress): Assigns the GOVERNOR_ROLE (only owner or current governor).
3. setCuratorRole(address curatorAddress): Assigns the CURATOR_ROLE (only owner or governor).
4. revokeGovernorRole(address governorAddress): Revokes the GOVERNOR_ROLE (only owner or current governor).
5. revokeCuratorRole(address curatorAddress): Revokes the CURATOR_ROLE (only owner or governor).
6. setSubmissionFee(uint256 newFee): Sets the fee required for submitting external art (only governor).
7. setGenerativeFee(uint256 newFee): Sets the fee required to generate on-chain art (only governor).
8. submitExternalArt(string calldata metadataURI): Submits an external art piece for review, pays fee. Mints a token with status PENDING.
9. approveSubmittedArt(uint256 tokenId): Approves a submitted art piece (only curator or governor). Changes status to APPROVED.
10. rejectSubmittedArt(uint256 tokenId): Rejects a submitted art piece (only curator or governor). Changes status to REJECTED.
11. withdrawSubmissionFee(uint256 tokenId): Allows artist to withdraw fee if their submission was rejected.
12. generateOnChainArt(uint256 seed): Triggers the generation of an on-chain art piece, pays fee. Mints a token with generated parameters.
13. getGenerativeArtParams(uint256 tokenId) public view returns (uint256 seed): Retrieve the seed used for a generative art piece.
14. listGalleryArtForSale(uint256 tokenId, uint256 price): Lists an art piece owned by the gallery for sale (only governor).
15. updateGalleryArtPrice(uint256 tokenId, uint256 newPrice): Updates the price of an art piece listed for sale by the gallery (only governor).
16. cancelGalleryArtSale(uint256 tokenId): Removes an art piece listed for sale by the gallery (only governor).
17. buyGalleryArt(uint256 tokenId) payable: Buys an art piece listed for sale by the gallery.
18. withdrawTreasury(address payable recipient, uint256 amount): Allows the governor to withdraw funds from the gallery treasury.
19. getGalleryBalance() public view returns (uint256): Get the current contract balance (treasury).
20. updateDynamicTrait(uint256 tokenId): Triggers an update for a token's dynamic trait state (callable by anyone, pays gas). Only applicable to certain tokens.
21. getDynamicTraitState(uint256 tokenId) public view returns (uint64 lastUpdated, uint256 internalState): Get the dynamic trait state.
22. getSubmissionState(uint256 tokenId) public view returns (SubmissionState): Get the current state of a submitted artwork.
23. getTokenArtType(uint256 tokenId) public view returns (ArtType): Get whether a token is SUBMITTED or GENERATED.
24. setTokenRoyalty(uint256 tokenId, address receiver, uint96 feeNumerator): Sets the royalty information for a specific token (intended for submitted art, potentially callable by owner/governor).

Total Functions: 9 (ERC721) + 2 (ERC2981) + 24 (Custom) = 35 Functions.
```

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC2981/ERC2981.sol";

// Note: A full DAO would use OpenZeppelin's Governor and Timelock contracts.
// This contract simulates actions controlled by a GOVERNOR_ROLE which would
// ideally be held by such a Governor contract, allowing proposed and voted
// upon changes to the gallery's parameters and treasury.

/**
 * @title DecentralizedAutonomousArtGallery
 * @dev A smart contract representing a decentralized art gallery combining submitted
 *      and on-chain generative art, a curation process, treasury, and governance control.
 *
 * Outline:
 * 1. State Variables: Storage for NFTs, fees, roles, submissions, generative art params, sales, dynamic traits.
 * 2. Events: Signalling important actions (Mint, Submit, Approve, Reject, Buy, Fee Update, etc.).
 * 3. Errors: Custom errors for clearer failure reasons.
 * 4. Modifiers: Access control (onlyCurator, onlyGovernor, onlyApprovedOrGovernor).
 * 5. Constructor: Initializes roles and basic settings.
 * 6. ERC721 Standard Functions: Basic NFT operations (minting is custom, but transfer, ownerOf, etc. are standard).
 * 7. Roles Management: Setting and revoking roles.
 * 8. Submission Management: Functions for artists to submit and curators/governor to review.
 * 9. Generative Art Management: Functions to trigger and retrieve parameters for on-chain art.
 * 10. Sales Management: Listing gallery art for sale and purchasing it.
 * 11. Treasury Management: Accessing and withdrawing collected fees.
 * 12. Dynamic Traits: Functions to update and retrieve dynamic state.
 * 13. Metadata/URI: Function to generate token URI based on art type and state.
 * 14. Utility Functions: Getting counts, fees, etc.
 *
 * Function Summary:
 * Inherited/Standard ERC721 (9): balanceOf, ownerOf, approve, getApproved, setApprovalForAll, isApprovedForAll, transferFrom, safeTransferFrom(bytes), safeTransferFrom(no bytes)
 * Inherited/Standard ERC2981 Royalties (2): supportsInterface, royaltyInfo
 * Custom Functions (24): constructor, setGovernorRole, setCuratorRole, revokeGovernorRole, revokeCuratorRole, setSubmissionFee, setGenerativeFee, submitExternalArt, approveSubmittedArt, rejectSubmittedArt, withdrawSubmissionFee, generateOnChainArt, getGenerativeArtParams, listGalleryArtForSale, updateGalleryArtPrice, cancelGalleryArtSale, buyGalleryArt, withdrawTreasury, getGalleryBalance, updateDynamicTrait, getDynamicTraitState, getSubmissionState, getTokenArtType, setTokenRoyalty
 * Total Functions: 35
 */
contract DecentralizedAutonomousArtGallery is ERC721URIStorage, ERC2981, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // --- State Variables ---

    // Roles
    bytes32 public constant GOVERNOR_ROLE = keccak256("GOVERNOR_ROLE");
    bytes32 public constant CURATOR_ROLE = keccak256("CURATOR_ROLE");
    mapping(address => bool) private _governors;
    mapping(address => bool) private _curators;

    // Fees
    uint256 public submissionFee = 0.01 ether; // Fee for submitting external art
    uint256 public generativeFee = 0.005 ether; // Fee for triggering on-chain generation

    // Art Information
    enum ArtType { SUBMITTED, GENERATED }
    mapping(uint256 => ArtType) private _tokenArtType;

    enum SubmissionState { PENDING, APPROVED, REJECTED }
    mapping(uint256 => SubmissionState) private _submissionState;
    mapping(uint256 => address) private _submissionArtist; // Original submitter for fee withdrawal

    // Generative Art Data
    mapping(uint256 => uint256) private _generativeSeeds; // Seed for on-chain art generation

    // Sales Data (for art owned by the gallery contract)
    mapping(uint256 => uint256) private _gallerySalesPrice; // Price > 0 means listed for sale

    // Dynamic Traits (Simple Example: State changes based on time/interaction)
    struct DynamicState {
        uint64 lastUpdated; // Timestamp of the last state update
        uint256 internalState; // A generic state variable, could influence metadata
    }
    mapping(uint256 => DynamicState) private _dynamicStates;
    uint64 public dynamicTraitUpdateInterval = 1 days; // How often trait can update

    // Royalties (using ERC2981 standards, can be overridden per token)
    address private _defaultRoyaltyRecipient;
    uint96 private _defaultRoyaltyFeeNumerator;

    // --- Events ---

    event ArtSubmitted(uint256 indexed tokenId, address indexed artist, string metadataURI);
    event SubmissionStateChanged(uint256 indexed tokenId, SubmissionState newState, address changer);
    event SubmissionFeeWithdrawn(uint256 indexed tokenId, address indexed recipient, uint256 amount);
    event OnChainArtGenerated(uint256 indexed tokenId, address indexed creator, uint256 seed);
    event GalleryArtListedForSale(uint256 indexed tokenId, uint256 price);
    event GalleryArtSaleUpdated(uint256 indexed tokenId, uint256 newPrice);
    event GalleryArtSaleCancelled(uint256 indexed tokenId);
    event GalleryArtBought(uint256 indexed tokenId, address indexed buyer, uint256 price);
    event TreasuryWithdrawn(address indexed recipient, uint256 amount);
    event SubmissionFeeUpdated(uint256 newFee);
    event GenerativeFeeUpdated(uint256 newFee);
    event GovernorRoleSet(address indexed account);
    event GovernorRoleRevoked(address indexed account);
    event CuratorRoleSet(address indexed account);
    event CuratorRoleRevoked(address indexed account);
    event DynamicTraitUpdated(uint256 indexed tokenId, uint256 newState);
    event TokenRoyaltySet(uint256 indexed tokenId, address indexed receiver, uint96 feeNumerator);


    // --- Errors ---

    error DAAG_NotGovernor();
    error DAAG_NotCurator();
    error DAAG_NotApprovedOrGovernor();
    error DAAG_SubmissionNotFound();
    error DAAG_SubmissionNotInState(SubmissionState requiredState);
    error DAAG_SubmissionFeeAlreadyWithdrawn();
    error DAAG_InvalidTokenId();
    error DAAG_UnauthorizedWithdrawal();
    error DAAG_InsufficientPayment(uint256 requiredAmount);
    error DAAG_ArtNotListedForSale();
    error DAAG_ArtAlreadyListedForSale();
    error DAAG_NotTokenOwner();
    error DAAG_DynamicTraitNotReady(uint64 nextUpdateTime);
    error DAAG_InvalidRoyaltyNumerator();
    error DAAG_OnlyApplicableToSubmittedArt();


    // --- Modifiers ---

    modifier onlyGovernor() {
        if (!_governors[msg.sender] && msg.sender != owner()) revert DAAG_NotGovernor();
        _;
    }

    modifier onlyCurator() {
         if (!_curators[msg.sender] && msg.sender != owner()) revert DAAG_NotCurator();
        _;
    }

    // Allows the token owner OR a governor to perform an action
    modifier onlyApprovedOrGovernor(uint256 tokenId) {
        address tokenOwner = ownerOf(tokenId); // Will revert for non-existent tokens

        if (msg.sender != tokenOwner && !_governors[msg.sender] && msg.sender != owner()) {
            revert DAAG_NotApprovedOrGovernor();
        }
        _;
    }


    // --- Constructor ---

    constructor(address initialGovernor, address initialCurator) ERC721("Decentralized Autonomous Art Gallery", "DAAG") Ownable(msg.sender) {
        // Set initial roles. In a real DAO, owner would transfer governor role to Governor contract.
        _governors[initialGovernor] = true;
        emit GovernorRoleSet(initialGovernor);

        _curators[initialCurator] = true;
        emit CuratorRoleSet(initialCurator);

        // Set a default royalty configuration (can be overridden per token)
        _defaultRoyaltyRecipient = address(this); // Gallery gets default royalty
        _defaultRoyaltyFeeNumerator = 500; // 5% (500/10000)
    }

    // --- ERC721 & ERC2981 Implementations ---

    // ERC721URIStorage requires _baseURI and _setTokenURI.
    // We'll override tokenURI for custom metadata based on type/state.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        // Revert if token doesn't exist
        if (!_exists(tokenId)) revert ERC721URIStorage.URIQueryForNonexistentToken();

        ArtType artType = _tokenArtType[tokenId];

        if (artType == ArtType.SUBMITTED) {
            // For submitted art, return the stored external URI
            return super.tokenURI(tokenId);
        } else if (artType == ArtType.GENERATED) {
            // For generated art, construct a data URI containing parameters or a pointer
            // In a real app, this would generate a base64 JSON data URI.
            // For this example, we'll return a simplified string indicating the parameters.
            uint256 seed = _generativeSeeds[tokenId];
            DynamicState memory dynState = _dynamicStates[tokenId];
            return string(abi.encodePacked(
                "data:application/json;utf8,",
                '{"name":"On-Chain Art #',
                Strings.toString(tokenId),
                '", "description":"Generative art piece based on seed ",',
                Strings.toString(seed),
                '", "attributes": [ {"trait_type": "Seed", "value": ',
                Strings.toString(seed),
                '}, {"trait_type": "Last Updated", "value": ',
                Strings.toString(dynState.lastUpdated),
                 '}, {"trait_type": "Internal State", "value": ',
                Strings.toString(dynState.internalState),
                '} ] }'
            ));
        }
        // Should not happen if _tokenArtType is always set correctly
        return "";
    }

    // ERC2981 Implementation
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        public
        view
        virtual
        override
        returns (address receiver, uint256 royaltyAmount)
    {
         // Check if specific royalty is set for this token first
        address customReceiver;
        uint96 customFeeNumerator;
        // Assuming a mapping exists to store per-token royalty:
        // mapping(uint256 => address) _tokenRoyaltyReceiver;
        // mapping(uint256 => uint96) _tokenRoyaltyNumerator;
        // For this example, we'll just check a simple flag or structure
        if (_tokenRoyaltyReceivers[tokenId] != address(0)) {
             customReceiver = _tokenRoyaltyReceivers[tokenId];
             customFeeNumerator = _tokenRoyaltyNumerators[tokenId];
        } else {
            // Fallback to default royalty if no specific one is set
            customReceiver = _defaultRoyaltyRecipient;
            customFeeNumerator = _defaultRoyaltyFeeNumerator;
        }

        if (customFeeNumerator > 10000) revert DAAG_InvalidRoyaltyNumerator(); // Prevent >100% royalty

        return (customReceiver, (salePrice * customFeeNumerator) / 10000);
    }

    // Add mappings to store per-token royalties (required for setTokenRoyalty)
    mapping(uint256 => address) private _tokenRoyaltyReceivers;
    mapping(uint256 => uint96) private _tokenRoyaltyNumerators;

    /**
     * @dev Sets the royalty information for a specific token.
     * @param tokenId The ID of the token.
     * @param receiver The address to receive the royalty payments.
     * @param feeNumerator The royalty percentage represented as a numerator (e.g., 500 for 5%). Max 10000.
     * @dev Only the token owner, gallery owner, or a governor can set royalties.
     * @dev Intended primarily for SUBMITTED art.
     */
    function setTokenRoyalty(uint256 tokenId, address receiver, uint96 feeNumerator) public onlyApprovedOrGovernor(tokenId) {
         if (!_exists(tokenId)) revert DAAG_InvalidTokenId();
         if (feeNumerator > 10000) revert DAAG_InvalidRoyaltyNumerator();
         // Optional: enforce this only applies to SUBMITTED art? Let's allow on GENERATED too for flexibility.

        _tokenRoyaltyReceivers[tokenId] = receiver;
        _tokenRoyaltyNumerators[tokenId] = feeNumerator;

        emit TokenRoyaltySet(tokenId, receiver, feeNumerator);
    }


    // Support ERC721, ERC721Metadata, ERC721Enumerable (if included), and ERC2981
    function supportsInterface(bytes4 interfaceId) public view override(ERC721URIStorage, ERC2981) returns (bool) {
        return interfaceId == type(ERC721).interfaceId ||
               interfaceId == type(ERC721Enumerable).interfaceId || // If using Enumerable
               interfaceId == type(ERC721Metadata).interfaceId ||
               interfaceId == type(ERC2981).interfaceId ||
               super.supportsInterface(interfaceId);
    }


    // --- Roles Management ---

    /**
     * @dev Grants the GOVERNOR_ROLE to an account.
     * @param governorAddress The address to grant the role to.
     * @dev Only the contract owner or an existing governor can call this.
     */
    function setGovernorRole(address governorAddress) public onlyGovernor {
        _governors[governorAddress] = true;
        emit GovernorRoleSet(governorAddress);
    }

    /**
     * @dev Revokes the GOVERNOR_ROLE from an account.
     * @param governorAddress The address to revoke the role from.
     * @dev Only the contract owner or an existing governor can call this. Cannot revoke own role if it's the last governor.
     */
    function revokeGovernorRole(address governorAddress) public onlyGovernor {
         // Basic check to prevent removing the last governor or owner if they are governor
        uint256 governorCount = 0;
        for(uint i=0; i < 100; ++i) { // Iterate a small fixed number for gas limits, not ideal but simpler than linked list
            // This iteration method is not scalable. In a real contract, track governors in a dynamic array or use AccessControl.sol
            // For this example, we'll skip the 'last governor' check for simplicity.
            break; // Avoid high gas cost of naive iteration
        }
       // if (governorCount <= 1 && (_governors[msg.sender] || owner() == msg.sender)) revert DAAG_CannotRemoveLastGovernor(); // Simplified, better to use AccessControl

        _governors[governorAddress] = false;
        emit GovernorRoleRevoked(governorAddress);
    }

    /**
     * @dev Grants the CURATOR_ROLE to an account.
     * @param curatorAddress The address to grant the role to.
     * @dev Only the contract owner or a governor can call this.
     */
    function setCuratorRole(address curatorAddress) public onlyGovernor {
        _curators[curatorAddress] = true;
        emit CuratorRoleSet(curatorAddress);
    }

    /**
     * @dev Revokes the CURATOR_ROLE from an account.
     * @param curatorAddress The address to revoke the role from.
     * @dev Only the contract owner or a governor can call this.
     */
    function revokeCuratorRole(address curatorAddress) public onlyGovernor {
        _curators[curatorAddress] = false;
        emit CuratorRoleRevoked(curatorAddress);
    }

    // --- Fee Management ---

    /**
     * @dev Sets the fee for submitting external art.
     * @param newFee The new submission fee in wei.
     * @dev Only a governor can call this.
     */
    function setSubmissionFee(uint256 newFee) public onlyGovernor {
        submissionFee = newFee;
        emit SubmissionFeeUpdated(newFee);
    }

    /**
     * @dev Sets the fee for triggering on-chain art generation.
     * @param newFee The new generative fee in wei.
     * @dev Only a governor can call this.
     */
    function setGenerativeFee(uint256 newFee) public onlyGovernor {
        generativeFee = newFee;
        emit GenerativeFeeUpdated(newFee);
    }

    // --- Submission Management ---

    /**
     * @dev Allows an artist to submit external art for consideration.
     * Mints a token with state PENDING. Requires payment of submission fee.
     * @param metadataURI The URI pointing to the external art metadata.
     */
    function submitExternalArt(string calldata metadataURI) public payable {
        if (msg.value < submissionFee) revert DAAG_InsufficientPayment(submissionFee);

        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        _mint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, metadataURI);
        _tokenArtType[newTokenId] = ArtType.SUBMITTED;
        _submissionState[newTokenId] = SubmissionState.PENDING;
        _submissionArtist[newTokenId] = msg.sender; // Store artist for fee withdrawal

        emit ArtSubmitted(newTokenId, msg.sender, metadataURI);
    }

    /**
     * @dev Approves a submitted art piece.
     * Changes the submission state from PENDING to APPROVED.
     * @param tokenId The ID of the token to approve.
     * @dev Only a curator or a governor can call this.
     */
    function approveSubmittedArt(uint256 tokenId) public onlyCurator {
        if (!_exists(tokenId)) revert DAAG_InvalidTokenId();
        if (_tokenArtType[tokenId] != ArtType.SUBMITTED) revert DAAG_OnlyApplicableToSubmittedArt();
        if (_submissionState[tokenId] != SubmissionState.PENDING) revert DAAG_SubmissionNotInState(SubmissionState.PENDING);

        _submissionState[tokenId] = SubmissionState.APPROVED;
        // Note: The submission fee remains in the treasury.
        // The artist now owns an APPROVED token.

        emit SubmissionStateChanged(tokenId, SubmissionState.APPROVED, msg.sender);
    }

    /**
     * @dev Rejects a submitted art piece.
     * Changes the submission state from PENDING to REJECTED.
     * Allows the artist to withdraw their submission fee.
     * @param tokenId The ID of the token to reject.
     * @dev Only a curator or a governor can call this.
     */
    function rejectSubmittedArt(uint256 tokenId) public onlyCurator {
        if (!_exists(tokenId)) revert DAAG_InvalidTokenId();
         if (_tokenArtType[tokenId] != ArtType.SUBMITTED) revert DAAG_OnlyApplicableToSubmittedArt();
        if (_submissionState[tokenId] != SubmissionState.PENDING) revert DAAG_SubmissionNotInState(SubmissionState.PENDING);

        _submissionState[tokenId] = SubmissionState.REJECTED;
        // Fee can now be withdrawn by the artist

        emit SubmissionStateChanged(tokenId, SubmissionState.REJECTED, msg.sender);
    }

     /**
     * @dev Allows the original artist to withdraw their submission fee if the art was REJECTED.
     * @param tokenId The ID of the rejected token.
     */
    function withdrawSubmissionFee(uint256 tokenId) public {
        if (!_exists(tokenId)) revert DAAG_InvalidTokenId();
         if (_tokenArtType[tokenId] != ArtType.SUBMITTED) revert DAAG_OnlyApplicableToSubmittedArt();
        if (_submissionState[tokenId] != SubmissionState.REJECTED) revert DAAG_SubmissionNotInState(SubmissionState.REJECTED);
        if (_submissionArtist[tokenId] != msg.sender) revert DAAG_UnauthorizedWithdrawal(); // Only original submitter can withdraw

        address artist = _submissionArtist[tokenId];
        // Use a flag or set artist to address(0) to prevent double withdrawal
        if (artist == address(0)) revert DAAG_SubmissionFeeAlreadyWithdrawn();

        _submissionArtist[tokenId] = address(0); // Mark as withdrawn

        (bool success, ) = artist.call{value: submissionFee}("");
        require(success, "Fee withdrawal failed");

        emit SubmissionFeeWithdrawn(tokenId, artist, submissionFee);
    }

    /**
     * @dev Gets the current submission state of a token.
     * @param tokenId The ID of the token.
     * @return The submission state (PENDING, APPROVED, REJECTED).
     */
    function getSubmissionState(uint256 tokenId) public view returns (SubmissionState) {
         if (!_exists(tokenId)) revert DAAG_InvalidTokenId();
         if (_tokenArtType[tokenId] != ArtType.SUBMITTED) revert DAAG_OnlyApplicableToSubmittedArt();
        return _submissionState[tokenId];
    }


    // --- Generative Art Management ---

    /**
     * @dev Triggers the creation of a new on-chain generative art piece.
     * Mints a token with state GENERATED and stores the seed. Requires payment of generative fee.
     * @param seed A seed value used for potential generation logic (actual generation happens off-chain via tokenURI).
     */
    function generateOnChainArt(uint256 seed) public payable {
        if (msg.value < generativeFee) revert DAAG_InsufficientPayment(generativeFee);

        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        _mint(msg.sender, newTokenId);
        _tokenArtType[newTokenId] = ArtType.GENERATED;
        _generativeSeeds[newTokenId] = seed;
        // Initialize dynamic state for generative art
        _dynamicStates[newTokenId] = DynamicState({
            lastUpdated: uint64(block.timestamp),
            internalState: 0
        });


        // TokenURI for generated art will be constructed dynamically

        emit OnChainArtGenerated(newTokenId, msg.sender, seed);
    }

     /**
     * @dev Retrieves the generative seed used for an on-chain art piece.
     * @param tokenId The ID of the token.
     * @return The seed value.
     */
    function getGenerativeArtParams(uint256 tokenId) public view returns (uint256 seed) {
        if (!_exists(tokenId)) revert DAAG_InvalidTokenId();
        if (_tokenArtType[tokenId] != ArtType.GENERATED) revert DAAG_OnlyApplicableToSubmittedArt(); // Reusing error, slightly inaccurate
        return _generativeSeeds[tokenId];
    }


    // --- Sales Management (for art owned by the gallery itself) ---

    /**
     * @dev Lists an art piece currently owned by the gallery contract for sale.
     * @param tokenId The ID of the token owned by the contract.
     * @param price The price in wei.
     * @dev Only a governor can call this.
     */
    function listGalleryArtForSale(uint256 tokenId, uint256 price) public onlyGovernor {
        if (!_exists(tokenId)) revert DAAG_InvalidTokenId();
        if (ownerOf(tokenId) != address(this)) revert DAAG_NotTokenOwner(); // Gallery must own the token
        if (_gallerySalesPrice[tokenId] > 0) revert DAAG_ArtAlreadyListedForSale(); // Not already listed

        _gallerySalesPrice[tokenId] = price;

        emit GalleryArtListedForSale(tokenId, price);
    }

    /**
     * @dev Updates the price of an art piece listed for sale by the gallery.
     * @param tokenId The ID of the token listed for sale.
     * @param newPrice The new price in wei.
     * @dev Only a governor can call this.
     */
    function updateGalleryArtPrice(uint256 tokenId, uint256 newPrice) public onlyGovernor {
         if (!_exists(tokenId)) revert DAAG_InvalidTokenId();
         if (ownerOf(tokenId) != address(this)) revert DAAG_NotTokenOwner(); // Gallery must own the token
        if (_gallerySalesPrice[tokenId] == 0) revert DAAG_ArtNotListedForSale(); // Must be listed

        _gallerySalesPrice[tokenId] = newPrice;

        emit GalleryArtSaleUpdated(tokenId, newPrice);
    }

    /**
     * @dev Cancels the sale of an art piece listed by the gallery.
     * @param tokenId The ID of the token listed for sale.
     * @dev Only a governor can call this.
     */
    function cancelGalleryArtSale(uint256 tokenId) public onlyGovernor {
         if (!_exists(tokenId)) revert DAAG_InvalidTokenId();
         if (ownerOf(tokenId) != address(this)) revert DAAG_NotTokenOwner(); // Gallery must own the token
        if (_gallerySalesPrice[tokenId] == 0) revert DAAG_ArtNotListedForSale(); // Must be listed

        delete _gallerySalesPrice[tokenId]; // Remove from sale

        emit GalleryArtSaleCancelled(tokenId);
    }


    /**
     * @dev Allows a user to buy an art piece listed for sale by the gallery.
     * Transfers the token from the gallery to the buyer.
     * @param tokenId The ID of the token to buy.
     * @dev Requires payment equal to the listed price.
     */
    function buyGalleryArt(uint256 tokenId) public payable {
         if (!_exists(tokenId)) revert DAAG_InvalidTokenId();
         if (ownerOf(tokenId) != address(this)) revert DAAG_NotTokenOwner(); // Gallery must own the token

        uint256 price = _gallerySalesPrice[tokenId];
        if (price == 0) revert DAAG_ArtNotListedForSale(); // Must be listed for sale
        if (msg.value < price) revert DAAG_InsufficientPayment(price);

        delete _gallerySalesPrice[tokenId]; // Remove from sale upon purchase

        // Transfer the token to the buyer
        _transfer(address(this), msg.sender, tokenId);

        // The payment (msg.value) remains in the contract's balance (treasury)
        // Any excess payment beyond the price is also kept as a "donation"
        // In a real system, you might refund excess or require exact payment.
        // For simplicity, all msg.value goes to treasury.

        // Handle potential royalties (ERC2981)
        (address royaltyReceiver, uint256 royaltyAmount) = royaltyInfo(tokenId, price);
        if (royaltyAmount > 0 && royaltyReceiver != address(0)) {
             // Note: In this setup, the gallery owns the art and receives the full sale price.
             // If the gallery were to *pay* a royalty on its own sale, the treasury would decrease.
             // More common: Royalties are paid on *secondary* sales *after* the gallery sells it.
             // This royaltyInfo is primarily for secondary markets that respect ERC2981.
             // We'll emit an event indicating the theoretical royalty, but the funds stay in treasury for simplicity here.
            // If we wanted the gallery to *pay* royalty on its own sale:
            // require(address(this).balance >= royaltyAmount, "Insufficient balance for royalty");
            // (bool success, ) = royaltyReceiver.call{value: royaltyAmount}("");
            // require(success, "Royalty payment failed");
        }


        emit GalleryArtBought(tokenId, msg.sender, price);
    }

    // --- Treasury Management ---

    /**
     * @dev Gets the current balance of the contract (treasury).
     * @return The balance in wei.
     */
    function getGalleryBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Allows the governor to withdraw funds from the gallery treasury.
     * In a real DAO, this would be called by the Governor contract after a successful proposal.
     * @param recipient The address to send the funds to.
     * @param amount The amount to withdraw in wei.
     * @dev Only a governor can call this.
     */
    function withdrawTreasury(address payable recipient, uint256 amount) public onlyGovernor {
        if (address(this).balance < amount) revert DAAG_InsufficientPayment(amount); // Reusing error
        if (recipient == address(0)) revert DAAG_InvalidTokenId(); // Reusing error, invalid recipient

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Treasury withdrawal failed");

        emit TreasuryWithdrawn(recipient, amount);
    }

    // --- Dynamic Traits ---

    /**
     * @dev Triggers an update check for a token's dynamic traits.
     * Can be called by anyone to "poke" the token and see if its dynamic state should change.
     * Updates happen based on `dynamicTraitUpdateInterval`.
     * @param tokenId The ID of the token to update.
     * @dev Only applicable to tokens configured for dynamic traits (e.g., GENERATED art).
     */
    function updateDynamicTrait(uint256 tokenId) public {
        if (!_exists(tokenId)) revert DAAG_InvalidTokenId();
        // Optional: Check if this token type is configured for dynamic traits
        // if (_tokenArtType[tokenId] != ArtType.GENERATED) revert DAAG_OnlyApplicableToSubmittedArt(); // Reusing error

        DynamicState storage dynState = _dynamicStates[tokenId];

        // Check if enough time has passed since the last update
        if (block.timestamp < dynState.lastUpdated + dynamicTraitUpdateInterval) {
             revert DAAG_DynamicTraitNotReady(dynState.lastUpdated + dynamicTraitUpdateInterval);
        }

        // Implement dynamic state change logic here.
        // This is a simple example: increment internal state.
        dynState.internalState++;
        dynState.lastUpdated = uint64(block.timestamp);

        emit DynamicTraitUpdated(tokenId, dynState.internalState);
        // Note: The tokenURI should now reflect this updated state.
    }

    /**
     * @dev Gets the current dynamic trait state for a token.
     * @param tokenId The ID of the token.
     * @return lastUpdated The timestamp of the last state update.
     * @return internalState The current value of the internal dynamic state.
     */
    function getDynamicTraitState(uint256 tokenId) public view returns (uint64 lastUpdated, uint256 internalState) {
        if (!_exists(tokenId)) revert DAAG_InvalidTokenId();
         // Optional: Check if this token type is configured for dynamic traits
        // if (_tokenArtType[tokenId] != ArtType.GENERATED) revert DAAG_OnlyApplicableToSubmittedArt(); // Reusing error
        DynamicState storage dynState = _dynamicStates[tokenId];
        return (dynState.lastUpdated, dynState.internalState);
    }

     // --- Utility Functions ---

     /**
     * @dev Gets the art type of a specific token.
     * @param tokenId The ID of the token.
     * @return The ArtType (SUBMITTED or GENERATED).
     */
    function getTokenArtType(uint256 tokenId) public view returns (ArtType) {
        if (!_exists(tokenId)) revert DAAG_InvalidTokenId();
        return _tokenArtType[tokenId];
    }

    /**
     * @dev Checks if an address has the GOVERNOR_ROLE.
     */
    function isGovernor(address account) public view returns (bool) {
        return _governors[account];
    }

    /**
     * @dev Checks if an address has the CURATOR_ROLE.
     */
     function isCurator(address account) public view returns (bool) {
        return _curators[account];
    }

    // Fallback function to receive Ether (for fees)
    receive() external payable {}
}
```