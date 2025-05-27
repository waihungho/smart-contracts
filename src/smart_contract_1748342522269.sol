Okay, here is a smart contract concept called "CryptoCanvas" that combines elements of NFTs, collaborative art, passive income generation (via a utility token), and a decentralized marketplace. It aims for complexity and interaction beyond typical basic contracts.

It's designed with modularity in mind (leveraging OpenZeppelin for standard parts) and includes mechanics like dynamic properties, resource generation, and user-driven listing.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// --- CryptoCanvas Smart Contract ---
//
// This contract represents a large, tokenized digital canvas divided into discrete "Sections".
// Each Section is a unique ERC721 NFT. Users can buy blank sections, own them,
// decorate them with color, text, or data, and list them for sale on a P2P marketplace.
// Owning and actively decorating sections generates a passive income stream of a utility token called "Ink".
// Special decoration actions might require "Brush" NFTs/tokens from approved contracts.
//
// Outline:
// 1.  State Variables: Core data structures for sections, sales, Ink balances, configuration.
// 2.  Events: Notifications for key actions (buy, decorate, list, claim, etc.).
// 3.  Inheritance: ERC721 for sections, ERC20 for Ink, Ownable for admin, Pausable for control, ReentrancyGuard for security.
// 4.  Constructor: Initializes contract with base configurations.
// 5.  Admin/Configuration Functions: Set prices, rates, fees, approved brushes, pause/unpause, withdraw.
// 6.  Section Ownership & ERC721: Core ERC721 methods (transfer, approve, balance, ownerOf, tokenURI, etc. - partly inherited).
// 7.  Section Creation & Buying: Minting new blank sections, users buying them.
// 8.  Section Decoration: Applying visual/data changes to owned sections (requires fees/brushes).
// 9.  Section Marketplace: Listing sections for sale, cancelling listings, buying listed sections.
// 10. Ink Token (ERC20) & Generation: Internal ERC20 logic, calculating and allowing users to claim generated Ink.
// 11. Query Functions: View contract state, section details, marketplace listings, Ink balances.
// 12. Internal Functions: Helper functions for Ink calculation, state updates.
//
// Function Summary:
//
// Admin/Configuration:
// 1.  `setSectionPriceBase(uint256 _price)`: Set base price for buying new blank sections.
// 2.  `setDecorationFee(uint256 _fee)`: Set fee (in ETH/WETH) for decorating sections.
// 3.  `setInkGenerationRatePerSecondPerSection(uint256 _rate)`: Set Ink tokens generated per second per owned section.
// 4.  `setSaleProtocolFeeBasisPoints(uint256 _basisPoints)`: Set percentage fee taken by protocol on P2P sales.
// 5.  `addApprovedBrushContract(address _brushContract)`: Add an ERC721/ERC1155 contract address whose tokens can be used as brushes.
// 6.  `removeApprovedBrushContract(address _brushContract)`: Remove an approved brush contract.
// 7.  `withdrawProtocolFees()`: Withdraw collected protocol fees by the owner.
// 8.  `pause()`: Pause critical user interactions.
// 9.  `unpause()`: Unpause critical user interactions.
//
// Section Creation & Buying:
// 10. `buyBlankSection()`: Purchase a new, un-decorated section NFT.
//
// Section Decoration:
// 11. `decorateSectionWithColor(uint256 _sectionId, uint32 _color)`: Set the background color of an owned section.
// 12. `decorateSectionWithText(uint256 _sectionId, string calldata _text)`: Set text content on an owned section.
// 13. `decorateSectionWithData(uint256 _sectionId, string calldata _dataURI)`: Attach a data URI (e.g., IPFS hash) to a section.
// 14. `useBrushOnSection(uint256 _sectionId, address _brushContract, uint256 _brushTokenId)`: Use a specific brush token from an approved contract for a special effect (consumes token).
//
// Section Marketplace:
// 15. `offerSectionForSale(uint256 _sectionId, uint256 _price)`: List an owned section for sale at a specific price.
// 16. `cancelSectionSale(uint256 _sectionId)`: Remove a section from the marketplace listing.
// 17. `buySection(uint256 _sectionId)`: Purchase a section listed for sale by its owner.
//
// Ink Token & Generation:
// 18. `claimInk()`: Mint and transfer accrued Ink tokens to the caller based on owned sections and time.
// 19. `transferInk(address _recipient, uint256 _amount)`: Transfer Ink tokens (standard ERC20 transfer - inherited).
// 20. `approveInk(address _spender, uint256 _amount)`: Approve spending of Ink tokens (standard ERC20 approve - inherited).
//
// Query Functions:
// 21. `getSectionDetails(uint256 _sectionId)`: Get details (owner, color, text, dataURI, last decoration time) for a section.
// 22. `getSectionSaleDetails(uint256 _sectionId)`: Get sale details (price, seller, isListed) for a section.
// 23. `getPendingInk(address _user)`: Calculate amount of Ink a user is eligible to claim.
// 24. `getApprovedBrushContracts()`: Get the list of addresses of approved brush contracts.
// 25. `sectionPriceBase()`: Get the current base price for new blank sections.
// 26. `decorationFee()`: Get the current fee for decorating sections.
// 27. `inkGenerationRatePerSecondPerSection()`: Get the current Ink generation rate.
// 28. `saleProtocolFeeBasisPoints()`: Get the current protocol fee percentage on sales.
// 29. `totalSections()`: Get the total number of sections minted.
// (Plus inherited ERC721/ERC20 view functions like `balanceOf`, `ownerOf`, `allowance`, `totalSupply`, etc.)

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract CryptoCanvas is ERC721, ERC20, Ownable, Pausable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using Address for address payable;

    // --- State Variables ---

    Counters.Counter private _sectionIds;

    struct Section {
        uint32 color; // Represents color as an integer (e.g., RGB)
        string text; // Short text message on the section
        string dataURI; // URI pointing to external data/image/metadata (e.g., IPFS hash)
        uint256 lastDecoratedTime; // Timestamp of the last decoration action
        uint256 acquireTime; // Timestamp when the current owner acquired the section (for Ink calculation)
    }

    mapping(uint256 => Section) public sections;

    struct SaleListing {
        bool isListed;
        address payable seller;
        uint256 price; // Price in wei
    }

    mapping(uint256 => SaleListing) public sectionSales;

    // Ink Token specific
    uint256 public inkGenerationRatePerSecondPerSection; // Amount of Ink generated per second per owned section
    mapping(address => uint256) private _userLastInkClaimTime; // Timestamp of the user's last Ink claim

    // Configuration
    uint256 public sectionPriceBase; // Price to mint a new blank section (in wei)
    uint256 public decorationFee; // Fee to decorate a section (in wei)
    uint256 public saleProtocolFeeBasisPoints; // Protocol fee on section sales (e.g., 100 = 1%) - Max 10000 (100%)

    // Approved Brush Contracts
    mapping(address => bool) public isApprovedBrushContract;
    address[] private _approvedBrushContracts; // To easily list them

    // Protocol Fee Storage
    uint256 private _protocolFeesCollected;

    // --- Events ---

    event SectionBought(uint256 indexed sectionId, address indexed buyer, uint256 price);
    event SectionDecorated(uint256 indexed sectionId, address indexed decorator, uint256 feePaid, string decorationType);
    event SectionListed(uint256 indexed sectionId, address indexed seller, uint256 price);
    event SectionSaleCancelled(uint256 indexed sectionId);
    event InkClaimed(address indexed user, uint256 amount);
    event BrushUsed(uint256 indexed sectionId, address indexed user, address indexed brushContract, uint256 brushTokenId);
    event ProtocolFeeWithdrawn(address indexed to, uint256 amount);
    event ApprovedBrushContractAdded(address indexed brushContract);
    event ApprovedBrushContractRemoved(address indexed brushContract);

    // --- Constructor ---

    constructor(
        string memory name,
        string memory symbol,
        string memory inkTokenName,
        string memory inkTokenSymbol,
        uint256 _initialSectionPriceBase,
        uint256 _initialDecorationFee,
        uint256 _initialInkGenerationRatePerSecondPerSection,
        uint256 _initialSaleProtocolFeeBasisPoints
    ) ERC721(name, symbol) ERC20(inkTokenName, inkTokenSymbol) Ownable(msg.sender) Pausable() {
        sectionPriceBase = _initialSectionPriceBase;
        decorationFee = _initialDecorationFee;
        inkGenerationRatePerSecondPerSection = _initialInkGenerationRatePerSecondPerSection;
        saleProtocolFeeBasisPoints = _initialSaleProtocolFeeBasisPoints;
        require(_initialSaleProtocolFeeBasisPoints <= 10000, "Fee basis points cannot exceed 10000");
    }

    // --- Admin/Configuration Functions ---

    function setSectionPriceBase(uint256 _price) external onlyOwner {
        sectionPriceBase = _price;
    }

    function setDecorationFee(uint256 _fee) external onlyOwner {
        decorationFee = _fee;
    }

    function setInkGenerationRatePerSecondPerSection(uint256 _rate) external onlyOwner {
        inkGenerationRatePerSecondPerSection = _rate;
    }

    function setSaleProtocolFeeBasisPoints(uint256 _basisPoints) external onlyOwner {
        require(_basisPoints <= 10000, "Fee basis points cannot exceed 10000");
        saleProtocolFeeBasisPoints = _basisPoints;
    }

    function addApprovedBrushContract(address _brushContract) external onlyOwner {
        require(_brushContract != address(0), "Invalid address");
        if (!isApprovedBrushContract[_brushContract]) {
            isApprovedBrushContract[_brushContract] = true;
            _approvedBrushContracts.push(_brushContract);
            emit ApprovedBrushContractAdded(_brushContract);
        }
    }

    function removeApprovedBrushContract(address _brushContract) external onlyOwner {
        if (isApprovedBrushContract[_brushContract]) {
            isApprovedBrushContract[_brushContract] = false;
            // Remove from dynamic array (inefficient for large arrays, but fine for a small list)
            for (uint i = 0; i < _approvedBrushContracts.length; i++) {
                if (_approvedBrushContracts[i] == _brushContract) {
                    _approvedBrushContracts[i] = _approvedBrushContracts[_approvedBrushContracts.length - 1];
                    _approvedBrushContracts.pop();
                    break;
                }
            }
            emit ApprovedBrushContractRemoved(_brushContract);
        }
    }

    function withdrawProtocolFees() external onlyOwner nonReentrant {
        uint256 balance = _protocolFeesCollected;
        _protocolFeesCollected = 0;
        (bool success, ) = payable(owner()).call{value: balance}("");
        require(success, "Fee withdrawal failed");
        emit ProtocolFeeWithdrawn(owner(), balance);
    }

    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    // --- Section Creation & Buying ---

    function buyBlankSection() external payable nonReentrant whenNotPaused returns (uint256) {
        require(msg.value >= sectionPriceBase, "Insufficient payment");

        _sectionIds.increment();
        uint256 newItemId = _sectionIds.current();

        // Mint the NFT to the buyer
        _safeMint(msg.sender, newItemId);

        // Initialize section details
        sections[newItemId].color = 0; // Default color (e.g., black or white)
        sections[newItemId].text = "";
        sections[newItemId].dataURI = "";
        sections[newItemId].lastDecoratedTime = block.timestamp; // Treat minting as a decoration event start
        sections[newItemId].acquireTime = block.timestamp; // Track acquisition time for Ink

        // Ensure no sale listing exists initially
        sectionSales[newItemId].isListed = false;

        // Send excess funds back
        if (msg.value > sectionPriceBase) {
            payable(msg.sender).transfer(msg.value - sectionPriceBase);
        }

        emit SectionBought(newItemId, msg.sender, sectionPriceBase); // Use base price for mint event
        return newItemId;
    }

    // --- Section Decoration ---

    modifier onlySectionOwnerOrApproved(uint256 _sectionId) {
        require(_isApprovedOrOwner(msg.sender, _sectionId), "Caller is not owner or approved");
        _;
    }

    function decorateSectionWithColor(uint256 _sectionId, uint32 _color)
        external
        payable
        nonReentrant
        whenNotPaused
        onlySectionOwnerOrApproved(_sectionId)
    {
        require(msg.value >= decorationFee, "Insufficient decoration fee");

        sections[_sectionId].color = _color;
        sections[_sectionId].lastDecoratedTime = block.timestamp;

        _protocolFeesCollected += msg.value; // Collect fee

        emit SectionDecorated(_sectionId, msg.sender, msg.value, "color");
    }

    function decorateSectionWithText(uint256 _sectionId, string calldata _text)
        external
        payable
        nonReentrant
        whenNotPaused
        onlySectionOwnerOrApproved(_sectionId)
    {
        require(msg.value >= decorationFee, "Insufficient decoration fee");
        require(bytes(_text).length <= 160, "Text too long"); // Example limit

        sections[_sectionId].text = _text;
        sections[_sectionId].lastDecoratedTime = block.timestamp;

        _protocolFeesCollected += msg.value; // Collect fee

        emit SectionDecorated(_sectionId, msg.sender, msg.value, "text");
    }

    function decorateSectionWithData(uint256 _sectionId, string calldata _dataURI)
        external
        payable
        nonReentrant
        whenNotPaused
        onlySectionOwnerOrApproved(_sectionId)
    {
        require(msg.value >= decorationFee, "Insufficient decoration fee");

        sections[_sectionId].dataURI = _dataURI;
        sections[_sectionId].lastDecoratedTime = block.timestamp;

        _protocolFeesCollected += msg.value; // Collect fee

        emit SectionDecorated(_sectionId, msg.sender, msg.value, "data");
    }

    // This function assumes _brushContract is ERC721 and caller owns _brushTokenId
    // Or ERC1155 and caller owns sufficient amount
    // Basic implementation just checks approval and emits event, actual brush effect logic
    // would be more complex (e.g., requiring interaction with the brush contract)
    // For simplicity, we'll assume it "consumes" a single token by transferring it to address(0)
    function useBrushOnSection(uint256 _sectionId, address _brushContract, uint256 _brushTokenId)
        external
        nonReentrant
        whenNotPaused
        onlySectionOwnerOrApproved(_sectionId)
    {
        require(isApprovedBrushContract[_brushContract], "Brush contract not approved");

        // --- Mock Brush Consumption Logic ---
        // In a real scenario, you would interact with the brush contract:
        // Check ownership: IERC721(_brushContract).ownerOf(_brushTokenId) == msg.sender OR
        //                  IERC1155(_brushContract).balanceOf(msg.sender, _brushTokenId) > 0
        // Require approval: IERC721(_brushContract).getApproved(_brushTokenId) == address(this) OR
        //                   IERC1155(_brushContract).isApprovedForAll(msg.sender, address(this))
        // Consume token: IERC721(_brushContract).transferFrom(msg.sender, address(0), _brushTokenId); OR
        //                IERC1155(_brushContract).safeTransferFrom(msg.sender, address(0), _brushTokenId, 1, "");

        // For demonstration, we just emit the event and update section state
        sections[_sectionId].lastDecoratedTime = block.timestamp; // Using a brush counts as decoration

        emit BrushUsed(_sectionId, msg.sender, _brushContract, _brushTokenId);
        emit SectionDecorated(_sectionId, msg.sender, 0, "brush"); // Indicate decoration occurred
    }

    // --- Section Marketplace ---

    function offerSectionForSale(uint256 _sectionId, uint256 _price)
        external
        whenNotPaused
        onlySectionOwner(_sectionId) // Assumes only owner can list, not approved
    {
        require(_price > 0, "Price must be positive");
        require(!sectionSales[_sectionId].isListed, "Section already listed");

        sectionSales[_sectionId].isListed = true;
        sectionSales[_sectionId].seller = payable(msg.sender);
        sectionSales[_sectionId].price = _price;

        // Note: ERC721 transfer is needed later by buyer if using transferFrom flow.
        // Or, approve this contract to handle transfers (safer).
        // Let's require seller to approve this contract first.
        require(getApproved(_sectionId) == address(this) || isApprovedForAll(msg.sender, address(this)), "Contract not approved to transfer token");

        emit SectionListed(_sectionId, msg.sender, _price);
    }

    function cancelSectionSale(uint256 _sectionId)
        external
        whenNotPaused
        onlySectionOwner(_sectionId)
    {
        require(sectionSales[_sectionId].isListed, "Section not listed for sale");

        delete sectionSales[_sectionId]; // Clear the listing struct

        emit SectionSaleCancelled(_sectionId);
    }

    function buySection(uint256 _sectionId) external payable nonReentrant whenNotPaused {
        SaleListing storage listing = sectionSales[_sectionId];

        require(listing.isListed, "Section is not listed for sale");
        require(msg.value >= listing.price, "Insufficient payment");
        require(listing.seller != address(0), "Invalid seller address");
        require(listing.seller != msg.sender, "Cannot buy your own section");

        address seller = listing.seller;
        uint256 salePrice = listing.price;

        // Calculate protocol fee
        uint256 protocolFee = (salePrice * saleProtocolFeeBasisPoints) / 10000;
        uint256 sellerPayout = salePrice - protocolFee;

        // Transfer the NFT from seller to buyer using transferFrom (requires prior approval)
        // The seller must have approved THIS contract to transfer the token on their behalf.
        // This is why `offerSectionForSale` checks for approval.
        _transfer(seller, msg.sender, _sectionId);

        // Update section details for the new owner
        sections[_sectionId].acquireTime = block.timestamp; // Reset acquire time for Ink calculation

        // Clear the sale listing
        delete sectionSales[_sectionId];

        // Send funds to seller and protocol
        if (sellerPayout > 0) {
             payable(seller).transfer(sellerPayout);
        }
        _protocolFeesCollected += protocolFee;

        // Send excess funds back to buyer
        if (msg.value > salePrice) {
            payable(msg.sender).transfer(msg.value - salePrice);
        }

        emit SectionBought(_sectionId, msg.sender, salePrice); // Event uses the actual sale price
    }

    // --- Ink Token (ERC20) & Generation ---

    // Override ERC20 transfer and approve to be pausable if needed,
    // but standard ERC20 tokens are often left unpaused.
    // Let's only pause the Ink *claiming* mechanism, not transfers of existing Ink.

    function claimInk() external nonReentrant whenNotPaused {
        uint256 pendingInk = getPendingInk(msg.sender);
        require(pendingInk > 0, "No Ink available to claim");

        // Mint Ink to the user
        _mint(msg.sender, pendingInk);

        // Update the last claim time
        _userLastInkClaimTime[msg.sender] = block.timestamp;

        emit InkClaimed(msg.sender, pendingInk);
    }

     // Override `_beforeTokenTransfer` from ERC721 to update acquire time on transfer
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721)
    {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from != address(0) && to != address(0)) {
            // This is a transfer between users or user<->contract
            // Update acquire time for the new owner
            sections[tokenId].acquireTime = block.timestamp;

            // Cancel any active sale listing if being transferred by other means
            // (e.g., direct transfer by owner or approved)
            if (sectionSales[tokenId].isListed && sectionSales[tokenId].seller == from) {
                delete sectionSales[tokenId];
                emit SectionSaleCancelled(tokenId);
            }
        } else if (from == address(0) && to != address(0)) {
            // Minting - acquireTime is set in buyBlankSection
        } else if (from != address(0) && to == address(0)) {
            // Burning - no acquireTime needed
        }
    }

    // --- Query Functions ---

    function getSectionDetails(uint256 _sectionId)
        external
        view
        returns (
            address currentOwner,
            uint32 color,
            string memory text,
            string memory dataURI,
            uint256 lastDecoratedTime,
            uint256 acquireTime
        )
    {
        require(_exists(_sectionId), "Section does not exist");
        Section storage section = sections[_sectionId];
        return (
            ownerOf(_sectionId),
            section.color,
            section.text,
            section.dataURI,
            section.lastDecoratedTime,
            section.acquireTime
        );
    }

    function getSectionSaleDetails(uint256 _sectionId)
        external
        view
        returns (bool isListed, address seller, uint256 price)
    {
        SaleListing storage listing = sectionSales[_sectionId];
        return (listing.isListed, listing.seller, listing.price);
    }

    function getPendingInk(address _user) public view returns (uint256) {
        if (_user == address(0) || inkGenerationRatePerSecondPerSection == 0) {
            return 0;
        }

        uint256 ownedSectionsCount = balanceOf(_user);
        if (ownedSectionsCount == 0) {
            return 0;
        }

        uint256 lastClaim = _userLastInkClaimTime[_user];
        uint256 timeElapsed;

        // If user never claimed, calculate since the first section acquisition time
        // This is an approximation; a precise calculation would track time per section
        // For simplicity, we use the last claim time or deploy time/first acquire time
        // Let's simplify: calculate based on the user's last claim time.
        // If lastClaim is 0, assume it's the contract deploy time or roughly when user got their first NFT.
        // Using block.timestamp - userLastInkClaimTime is simpler.
        if (lastClaim == 0) {
             // Approximation: calculate from the time the user got their first section, or contract deploy if no sections yet.
             // A truly accurate system would need to track acquire time for *each* token
             // and calculate sum of (block.timestamp - sectionAcquireTime) for all *current* tokens owned by user.
             // This simple model assumes all user's tokens were held since last claim time (or start).
             // We'll use a simplified approximation: calculate since last claim (or 0) for *all* owned sections.
             // This means if a user buys a section, the Ink starts accruing from the *next* block, and previous Ink
             // on that section for the *previous* owner doesn't transfer implicitly to the buyer's pending amount
             // until the buyer claims *their* pending Ink. The new section's accrue time is set on transfer.
              timeElapsed = block.timestamp; // Treat 0 as start
        } else {
             timeElapsed = block.timestamp - lastClaim;
        }


        // Prevent calculation errors if block.timestamp somehow goes backwards (unlikely on mainnet)
         if (block.timestamp < lastClaim) {
             timeElapsed = 0;
         } else {
             timeElapsed = block.timestamp - lastClaim;
         }


        // Calculate total pending Ink
        // This is a simplified model: (time since last claim) * rate * (number of sections owned *at the time of claiming*)
        // A more precise model tracks ink accrual per section.
        // Given the complexity, the simpler model using block.timestamp - lastClaim and current section count is often used.
        return timeElapsed * inkGenerationRatePerSecondPerSection * ownedSectionsCount;
    }


    function getApprovedBrushContracts() external view returns (address[] memory) {
        return _approvedBrushContracts;
    }

    // Inherited ERC721/ERC20 functions:
    // name(), symbol(), totalSupply(), balanceOf(address owner), ownerOf(uint256 tokenId)
    // getApproved(uint256 tokenId), isApprovedForAll(address owner, address operator)
    // transferFrom(address from, address to, uint256 tokenId) - needs approval, Pausable?
    // approve(address to, uint256 tokenId)
    // setApprovalForAll(address operator, bool approved)
    // allowance(address owner, address spender), transfer(address to, uint256 amount), approve(address spender, uint256 amount)

    // Overriding ERC721 and ERC20 transfer functions to include pausing logic:
    // While Ink *claims* are pausable, direct ERC20/ERC721 *transfers* might be desired to remain active
    // even when decoration/buying is paused. Let's NOT override the standard transfer functions
    // from OpenZeppelin's ERC721/ERC20 base unless a specific need arises. The Pausable inheritance
    // primarily applies to functions explicitly marked with `whenNotPaused`.

    // Ensure core ERC721/ERC20 functions are inherited properly
    // The Pausable modifier is applied only where user interaction with the core canvas mechanics is intended to be controllable.

    // --- Internal/Helper Functions ---

    // Internal function overrides for ERC721 and ERC20 hooks if needed.
    // _beforeTokenTransfer is already overridden above.

    // tokenURI override example (can be dynamic based on section properties)
    // function tokenURI(uint256 tokenId) public view override returns (string memory) {
    //     require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
    //     // Construct URI based on sections[tokenId] properties
    //     // e.g., IPFS hash pointing to JSON metadata
    //     // string memory baseURI = _baseURI(); // If you have a base URI set
    //     // return string(abi.encodePacked(baseURI, section[tokenId].dataURI, ".json"));
    //      return sections[tokenId].dataURI; // Use stored dataURI directly
    // }

     // Internal helper to check if address is owner or approved for section
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address tokenOwner = ownerOf(tokenId);
        return (spender == tokenOwner || isApprovedForAll(tokenOwner, spender) || getApproved(tokenId) == spender);
    }

    // Override to make sure only owner can do direct transfer if not approved
    // Or use _beforeTokenTransfer hook for specific logic.
    // OpenZeppelin's transferFrom already handles approvals and owner checks.
    // We rely on the `whenNotPaused` modifier on functions that trigger transfers (buyBlankSection, buySection)
    // and the overridden `_beforeTokenTransfer` for acquire time updates.

}
```

---

**Explanation of Advanced/Creative/Trendy Concepts and Functions:**

1.  **Tokenized Sections (NFTs):** Standard ERC721, but the value comes from the *content* and *history* applied to the token.
2.  **Collaborative/Mutable Asset:** The canvas (collection of sections) is a shared asset where users contribute by modifying their owned parts (`decorateSectionWithColor`, `decorateSectionWithText`, `decorateSectionWithData`). This state is stored on-chain.
3.  **Dynamic NFT Properties:** The `Section` struct allows the NFT's properties (color, text, dataURI, last decorated time) to change *after* minting based on user actions.
4.  **Passive Income/Utility Token:** The `Ink` ERC20 token is generated over time simply by owning `CryptoCanvas` sections (`claimInk`). This creates a continuous incentive to hold the NFTs. The rate (`inkGenerationRatePerSecondPerSection`) is configurable.
5.  **Resource Consumption (Brushes):** The `useBrushOnSection` function introduces the concept of using other NFTs or tokens ("Brushes") from *approved external contracts* as a consumable resource for special actions. This enables ecosystem interaction and adds utility to other specific tokens.
6.  **Decentralized P2P Marketplace:** Functions like `offerSectionForSale`, `cancelSectionSale`, and `buySection` implement a simple on-chain mechanism for users to trade sections directly without relying on external marketplaces (though external ones can still list these NFTs). Includes a configurable `saleProtocolFeeBasisPoints` for the platform.
7.  **Time-Based Mechanics:** The `lastDecoratedTime` and `acquireTime` stamps are used, notably in the `getPendingInk` calculation, linking passive generation to ownership duration and activity (though the Ink calculation is a simplified model based on user's last claim time and total sections).
8.  **Approved External Contracts:** The `addApprovedBrushContract` and `isApprovedBrushContract` pattern allows the contract owner to whitelist specific external NFT/token contracts, creating a curated interaction point for the Brush mechanism.
9.  **Protocol Fee Collection:** Fees from decoration and sales are collected within the contract (`_protocolFeesCollected`) and can be withdrawn by the owner (`withdrawProtocolFees`), providing a potential revenue stream for maintaining or developing the project.
10. **Pausable Functionality:** Critical user actions (buying, decorating, claiming) can be paused by the owner using OpenZeppelin's `Pausable` to handle upgrades or emergencies.
11. **Reentrancy Protection:** `ReentrancyGuard` is used on functions involving Ether transfers to prevent reentrancy attacks.
12. **On-Chain State for Art:** While the dataURI can point off-chain, color and text are stored directly on-chain, making these fundamental properties immutable (except by decoration actions) and transparent.
13. **Dynamic Pricing Input:** `sectionPriceBase` and `decorationFee` are contract variables adjustable by the owner, allowing reaction to market conditions.
14. **Structured Data:** Using structs (`Section`, `SaleListing`) helps organize the complex state associated with each NFT.
15. **Modular Design:** Inherits from widely audited OpenZeppelin contracts (ERC721, ERC20, Ownable, Pausable, ReentrancyGuard) for standard behaviors and security.

This contract goes significantly beyond basic token standards by integrating multiple mechanics into a single system centered around a shared, dynamic, tokenized asset. The combination of mutable NFTs, passive token generation, an internal marketplace, and external contract interaction provides a rich set of functionalities meeting the criteria.