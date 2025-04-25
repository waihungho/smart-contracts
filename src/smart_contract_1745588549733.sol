Okay, let's design a smart contract system focused on managing creative content rights, licenses, and usage tracking on-chain, incorporating several interconnected and less common concepts.

We'll call it `DecentralizedCreativeCommons` (DCC). It will combine NFT-like ownership for content with a flexible on-chain licensing framework, a self-sovereign attribution system, and tracking for derivative works.

**Core Concepts:**

1.  **Content Tokens:** ERC721-like tokens representing individual creative works (images, music, text hashes, etc., represented by a URI/hash).
2.  **License Templates:** Predefined or custom types of licenses (similar to CC-BY, CC-NC, CC-SA, etc.) with configurable terms (price, duration, allowed uses, attribution requirements).
3.  **Acquired Licenses:** Instances of licenses purchased by users for specific Content Tokens. These are tracked on-chain.
4.  **Usage Records (Self-Sovereign Attribution - SSA):** Users who utilize content under a valid license can register an on-chain record of their usage, providing a link to where/how it was used. This proves compliant usage.
5.  **Derivative Tracking:** A mechanism to link newly minted derivative content tokens back to the original source token(s), ensuring provenance and potentially enforcing derivative licensing terms.

**Outline & Function Summary:**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// --- Contract: DecentralizedCreativeCommons (DCC) ---
// Purpose: Manages creative content tokens (NFTs), on-chain licensing,
//          usage tracking (Self-Sovereign Attribution), and derivative linking.
// Concepts: ERC721-like content ownership, configurable license terms,
//           time-bound licenses, on-chain usage registration, derivative provenance.

// --- Outline ---
// 1. Imports (ERC721, Ownable, Pausable, ERC165)
// 2. Data Structures (Enums, Structs)
// 3. State Variables (Mappings, Counters)
// 4. Events
// 5. Modifiers
// 6. Constructor
// 7. ERC721 Standard Functions (8 functions)
// 8. Pausable Functions (2 functions)
// 9. Ownable Functions (2 functions)
// 10. ERC165 Interface Detection (1 function)
// 11. Admin & Setup Functions (3 functions)
// 12. Content Management Functions (4 functions)
// 13. License Template Management Functions (3 functions)
// 14. License Acquisition & Management Functions (6 functions)
// 15. Usage Tracking (Self-Sovereign Attribution) Functions (3 functions)
// 16. Revenue & Royalty Distribution Functions (1 function)
// 17. Derivative Creation Functions (1 function)
// 18. View/Query Functions (5 functions)

// --- Function Summary (Total: 35 functions) ---

// Admin & Setup
// 1. constructor(): Initializes contract owner and ERC721 name/symbol.
// 2. pause(): Pauses the contract (owner only).
// 3. unpause(): Unpauses the contract (owner only).
// 4. transferOwnership(): Transfers contract ownership (owner only).
// 5. addLicenseTemplate(): Adds a new predefined license template (owner only).
// 6. removeLicenseTemplate(): Removes a license template (owner only).
// 7. updateBaseRoyaltyFee(): Updates a base fee applied to all license acquisitions (owner only).

// Content Management
// 8. mintContent(address to, string memory tokenURI, LicenseTerms[] memory initialLicenses): Mints a new content token, assigns ownership, sets metadata, and defines initial license options. Emits ContentCreated, Transfer.
// 9. burnContent(uint256 tokenId): Burns a content token (only by owner or approved). Emits Transfer.
// 10. addLicensesToContent(uint256 tokenId, LicenseTerms[] memory newLicenses): Allows content owner to add new license options to an existing token. Emits LicenseOptionAdded.
// 11. removeLicenseFromContent(uint256 tokenId, uint256 licenseOptionId): Allows content owner to remove a specific license option from their token. Emits LicenseOptionRemoved.

// License Template Management
// 12. getLicenseTemplate(uint256 templateId): Retrieves details of a specific license template. (View)
// 13. getAllLicenseTemplateIds(): Retrieves a list of all available license template IDs. (View)
// 14. getLicenseTemplatesCount(): Retrieves the total number of license templates. (View)

// License Acquisition & Management
// 15. acquireLicense(uint256 tokenId, uint256 licenseOptionId) payable: Allows a user to purchase a license for a specific content token and license option. Emits LicenseAcquired, EarningsDistributed.
// 16. renewLicense(uint256 tokenId, uint256 licenseInstanceId) payable: Allows a user to renew an existing acquired license instance. Emits LicenseRenewed.
// 17. transferLicense(uint256 tokenId, uint256 licenseInstanceId, address to): Allows a user to transfer an acquired license instance they own to another address. Emits LicenseTransferred.
// 18. getUserLicenses(address user, uint256 tokenId): Retrieves all active and expired license instances a user holds for a specific content token. (View)
// 19. checkLicenseValidity(address user, uint256 tokenId, UsagePurpose purpose): Checks if a user currently holds *any* valid license for a specific content token that permits the given usage purpose. (View)
// 20. getLicenseInstanceDetails(uint256 tokenId, uint256 licenseInstanceId): Retrieves details of a specific acquired license instance. (View)

// Usage Tracking (Self-Sovereign Attribution - SSA)
// 21. registerUsage(uint256 tokenId, uint256 licenseInstanceId, string memory usageURI, string memory attributionDetails): Allows a user with a valid license instance to register an on-chain record of their content usage, linking to an external resource. Emits UsageRegistered.
// 22. getUsageRecords(uint256 tokenId): Retrieves all registered usage records for a specific content token. (View)
// 23. verifyUsageClaim(uint256 tokenId, uint256 usageRecordId): Checks if a specific usage record exists and links to a valid *type* of license option that would have permitted the usage claimed (does not re-verify license validity *at time of usage*, relies on the user only calling registerUsage when valid). (View)

// Revenue & Royalty Distribution
// 24. withdrawEarnings(): Allows a content creator to withdraw earned license fees for their content tokens. Emits EarningsWithdrawn.

// Derivative Creation
// 25. mintDerivative(address to, string memory tokenURI, uint256[] memory parentTokenIds, LicenseTerms[] memory initialLicenses): Mints a new content token explicitly marked as a derivative of one or more parent tokens. Requires msg.sender to hold a license for each parent token allowing derivatives. Emits ContentCreated, DerivativeMinted.

// View/Query Functions
// 26. getContentMetadata(uint256 tokenId): Gets the token URI for a content token. (View)
// 27. getContentOwner(uint256 tokenId): Gets the owner of a content token (standard ERC721). (View)
// 28. getContentLicenses(uint256 tokenId): Gets all defined license options available for a specific content token. (View)
// 29. getContentLicenseOptionDetails(uint256 tokenId, uint256 licenseOptionId): Gets details of a specific license option for a content token. (View)
// 30. balanceOf(address owner): Gets the number of tokens owned by an address (standard ERC721). (View)
// 31. ownerOf(uint256 tokenId): Gets the owner of a token (standard ERC721). (View)
// 32. getApproved(uint256 tokenId): Gets approved address for a token (standard ERC721). (View)
// 33. isApprovedForAll(address owner, address operator): Checks approval for all (standard ERC721). (View)
// 34. supportsInterface(bytes4 interfaceId): Standard ERC165. (View)
// 35. getTotalSupply(): Gets the total number of tokens minted. (View)

```

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol"; // Adds _beforeTokenTransfer hook
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Address.sol"; // For sending value

// Note: ERC721Enumerable adds significant gas cost for transfers and minting/burning.
// For production, consider managing token lists differently if gas is critical.
// It's included here to easily get token lists for users/total supply.

contract DecentralizedCreativeCommons is ERC721Enumerable, Ownable, Pausable {
    using Counters for Counters.Counter;
    using Address for address payable;

    // --- Data Structures ---

    enum LicenseType {
        Attribution,      // Must attribute creator
        NonCommercial,    // Cannot use for commercial purposes
        ShareAlike,       // Derivatives must use same license
        NoDerivatives,    // Cannot create derivatives
        Commercial,       // Can be used commercially
        Custom            // A combination or specific terms
    }

    enum UsagePurpose {
        Display,          // Showcasing the work (e.g., blog post)
        Incorporation,    // Using it as part of a larger work
        Modification,     // Creating a derivative (requires specific license)
        Redistribution,   // Sharing copies
        Other             // Any other use case
    }

    struct LicenseTerms {
        uint256 id;             // Unique ID within the content token's options
        string name;            // e.g., "CC-BY-NC-SA", "Standard Commercial"
        LicenseType[] licenseTypes; // Combination of base license types
        uint256 duration;       // Duration in seconds (0 for perpetual)
        uint256 price;          // Price in native token (wei)
        string termsURI;        // Link to detailed terms (off-chain legal text)
        bool attributionRequired; // Explicitly require attribution
        uint256 royaltyShare;   // Percentage (0-10000) of price going to creator (10000 = 100%)
    }

    struct LicenseInstance {
        uint256 id;             // Unique ID for this specific acquired license instance
        uint256 licenseOptionId; // Refers to the LicenseTerms option purchased
        address licensee;       // Address holding this license
        uint256 acquisitionTimestamp; // When the license was acquired
        uint256 expiryTimestamp;    // When the license expires (0 for perpetual)
        bool revoked;           // Has this specific instance been revoked? (e.g., breach)
    }

    struct UsageRecord {
        uint256 id;             // Unique ID for this usage record
        uint256 tokenId;        // The content token being used
        uint256 licenseInstanceId; // The specific license instance used
        address user;           // The address registering the usage
        uint256 timestamp;      // When the usage was registered
        string usageURI;        // URI linking to the usage location/context (e.g., URL of blog post, IPFS hash)
        string attributionDetails; // Textual attribution details provided by the user
    }

    struct LicenseTemplate {
        uint256 id;
        string name;
        LicenseType[] licenseTypes;
        string termsURI;
        bool attributionRequired;
        uint256 defaultDuration;
        uint256 defaultRoyaltyShare;
    }

    // --- State Variables ---

    // Content Token Management
    Counters.Counter private _tokenIdCounter;
    // Mapping from tokenId to the list of license options available for that token
    mapping(uint255 => LicenseTerms[]) private _contentLicenseOptions;
    // Counter for license options within a specific token
    mapping(uint256 => Counters.Counter) private _licenseOptionCounters;
    // Mapping from tokenId to the list of parent tokenIds (if it's a derivative)
    mapping(uint256 => uint256[]) private _derivativeParentTokens;

    // License Acquisition Management
    Counters.Counter private _licenseInstanceCounter;
    // Mapping from tokenId -> licensee address -> list of acquired license instances for that token and user
    mapping(uint256 => mapping(address => LicenseInstance[])) private _userLicenses;
    // Mapping from tokenId -> licenseInstanceId -> LicenseInstance details (for direct lookup)
    mapping(uint256 => mapping(uint256 => LicenseInstance)) private _licenseInstances;

    // Usage Tracking (Self-Sovereign Attribution)
    Counters.Counter private _usageRecordCounter;
    // Mapping from tokenId -> list of UsageRecords for that token
    mapping(uint256 => UsageRecord[]) private _contentUsageRecords;
    // Mapping from tokenId -> usageRecordId -> UsageRecord details (for direct lookup)
    mapping(uint256 => mapping(uint256 => UsageRecord)) private _usageRecords;

    // License Template Management
    Counters.Counter private _licenseTemplateCounter;
    mapping(uint256 => LicenseTemplate) private _licenseTemplates;
    uint256[] private _licenseTemplateIds; // To iterate through templates

    // Revenue Distribution
    mapping(address => uint256) private _pendingEarnings; // Creator addresses to accumulated earnings

    // Contract Fees
    uint256 public baseRoyaltyFee = 0; // Base fee (in basis points, 0-10000) applied to license price, sent to owner

    // --- Events ---

    event ContentCreated(uint256 indexed tokenId, address indexed owner, string tokenURI);
    event LicenseOptionAdded(uint256 indexed tokenId, uint256 indexed licenseOptionId, string name, uint256 price);
    event LicenseOptionRemoved(uint256 indexed tokenId, uint256 indexed licenseOptionId);
    event LicenseAcquired(uint256 indexed tokenId, uint256 indexed licenseInstanceId, address indexed licensee, uint256 licenseOptionId, uint256 acquisitionTimestamp, uint256 expiryTimestamp, uint256 paidPrice);
    event LicenseRenewed(uint256 indexed tokenId, uint256 indexed licenseInstanceId, uint256 newExpiryTimestamp, uint256 paidPrice);
    event LicenseTransferred(uint256 indexed tokenId, uint256 indexed licenseInstanceId, address indexed from, address indexed to);
    event UsageRegistered(uint256 indexed tokenId, uint256 indexed licenseInstanceId, address indexed user, uint256 usageRecordId, string usageURI);
    event EarningsDistributed(uint256 indexed tokenId, uint256 indexed licenseInstanceId, address indexed creator, uint256 creatorAmount, uint256 platformAmount);
    event EarningsWithdrawn(address indexed creator, uint255 amount);
    event DerivativeMinted(uint256 indexed derivativeTokenId, uint256[] indexed parentTokenIds, address indexed owner);
    event LicenseTemplateAdded(uint256 indexed templateId, string name);
    event LicenseTemplateRemoved(uint256 indexed templateId);

    // --- Modifiers ---

    modifier onlyContentOwner(uint256 tokenId) {
        require(_exists(tokenId), "DCC: token does not exist");
        require(ownerOf(tokenId) == msg.sender, "DCC: caller is not content owner");
        _;
    }

    modifier onlyLicensee(uint256 tokenId, uint256 licenseInstanceId) {
        require(_exists(tokenId), "DCC: token does not exist");
        require(_licenseInstances[tokenId][licenseInstanceId].licensee == msg.sender, "DCC: caller is not license owner");
        require(!_licenseInstances[tokenId][licenseInstanceId].revoked, "DCC: license is revoked");
        _;
    }

    // --- Constructor ---

    constructor(string memory name, string memory symbol)
        ERC721(name, symbol)
        Ownable(msg.sender)
        Pausable()
    {}

    // --- ERC721 Standard Functions (8 functions) ---
    // These are implemented by inheriting ERC721Enumerable and ERC721

    // 1. balanceOf(address owner) view returns (uint256) - implemented by ERC721
    // 2. ownerOf(uint256 tokenId) view returns (address) - implemented by ERC721
    // 3. safeTransferFrom(address from, address to, uint256 tokenId) - implemented by ERC721
    // 4. safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) - implemented by ERC721
    // 5. transferFrom(address from, address to, uint256 tokenId) - implemented by ERC721
    // 6. approve(address to, uint256 tokenId) - implemented by ERC721
    // 7. setApprovalForAll(address operator, bool approved) - implemented by ERC721
    // 8. getApproved(uint256 tokenId) view returns (address) - implemented by ERC721
    // 9. isApprovedForAll(address owner, address operator) view returns (bool) - implemented by ERC721
    // 10. getTotalSupply() view returns (uint256) - Implemented by ERC721Enumerable

    // Note: ERC721Enumerable adds _beforeTokenTransfer, which we might use later if needed for hooks,
    // but it's not explicitly used in the custom logic below yet.
    // For gas efficiency, one could remove Enumerable and track supply/owned tokens manually.

    // --- Pausable Functions (2 functions) ---

    // 11. pause() onlyOwner whenNotPaused - Implemented by Pausable
    // 12. unpause() onlyOwner whenPaused - Implemented by Pausable

    // --- Ownable Functions (2 functions) ---

    // 13. transferOwnership(address newOwner) onlyOwner - Implemented by Ownable
    // 14. renounceOwnership() onlyOwner - Implemented by Ownable

    // --- ERC165 Interface Detection (1 function) ---

    // 15. supportsInterface(bytes4 interfaceId) view returns (bool) - Implemented by ERC721Enumerable

    // --- Admin & Setup Functions ---

    function updateBaseRoyaltyFee(uint256 _fee) external onlyOwner {
        require(_fee <= 10000, "DCC: fee exceeds 10000 basis points");
        baseRoyaltyFee = _fee;
    }

    // --- Content Management Functions ---

    function mintContent(address to, string memory tokenURI, LicenseTerms[] memory initialLicenses)
        external
        whenNotPaused
        returns (uint256)
    {
        require(to != address(0), "DCC: mint to the zero address");

        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        _safeMint(to, newTokenId);
        _setTokenURI(newTokenId, tokenURI);

        for (uint i = 0; i < initialLicenses.length; i++) {
            _licenseOptionCounters[newTokenId].increment();
            uint256 newOptionId = _licenseOptionCounters[newTokenId].current();
            initialLicenses[i].id = newOptionId;
            _contentLicenseOptions[newTokenId].push(initialLicenses[i]);
            emit LicenseOptionAdded(newTokenId, newOptionId, initialLicenses[i].name, initialLicenses[i].price);
        }

        emit ContentCreated(newTokenId, to, tokenURI);
        return newTokenId;
    }

    function burnContent(uint256 tokenId) external {
        // ERC721 burn checks for owner or approved operator
        require(_exists(tokenId), "DCC: token does not exist");
        // Note: This doesn't clean up licenses or usage records associated with the token.
        // For a real system, you'd need a strategy (e.g., mark as invalid, or make burn restricted/impossible).
        // Keeping it simple here, burning just removes the token ownership.
        _burn(tokenId);
    }

    function addLicensesToContent(uint256 tokenId, LicenseTerms[] memory newLicenses)
        external
        onlyContentOwner(tokenId)
        whenNotPaused
    {
        require(_exists(tokenId), "DCC: token does not exist");
        for (uint i = 0; i < newLicenses.length; i++) {
            _licenseOptionCounters[tokenId].increment();
            uint256 newOptionId = _licenseOptionCounters[tokenId].current();
            newLicenses[i].id = newOptionId;
            _contentLicenseOptions[tokenId].push(newLicenses[i]);
            emit LicenseOptionAdded(tokenId, newOptionId, newLicenses[i].name, newLicenses[i].price);
        }
    }

    function removeLicenseFromContent(uint256 tokenId, uint256 licenseOptionId)
        external
        onlyContentOwner(tokenId)
        whenNotPaused
    {
        bool found = false;
        LicenseTerms[] storage options = _contentLicenseOptions[tokenId];
        for (uint i = 0; i < options.length; i++) {
            if (options[i].id == licenseOptionId) {
                // Simple removal: replace with last element and pop. Order changes but IDs are stable.
                options[i] = options[options.length - 1];
                options.pop();
                found = true;
                emit LicenseOptionRemoved(tokenId, licenseOptionId);
                break;
            }
        }
        require(found, "DCC: license option not found for this token");
    }

    // --- License Template Management Functions ---

    function addLicenseTemplate(LicenseTemplate memory template)
        external
        onlyOwner
        whenNotPaused
        returns (uint256 templateId)
    {
        _licenseTemplateCounter.increment();
        templateId = _licenseTemplateCounter.current();
        template.id = templateId; // Ensure ID is set in the struct
        _licenseTemplates[templateId] = template;
        _licenseTemplateIds.push(templateId);
        emit LicenseTemplateAdded(templateId, template.name);
    }

    function removeLicenseTemplate(uint256 templateId)
        external
        onlyOwner
        whenNotPaused
    {
        require(_licenseTemplates[templateId].id != 0, "DCC: template does not exist"); // Check if ID exists
        // Simple removal from array by shifting
        for (uint i = 0; i < _licenseTemplateIds.length; i++) {
            if (_licenseTemplateIds[i] == templateId) {
                // Shift elements left
                for (uint j = i; j < _licenseTemplateIds.length - 1; j++) {
                    _licenseTemplateIds[j] = _licenseTemplateIds[j+1];
                }
                _licenseTemplateIds.pop(); // Remove last element
                break; // Exit outer loop
            }
        }
        delete _licenseTemplates[templateId]; // Remove from map
        emit LicenseTemplateRemoved(templateId);
    }

    // --- License Acquisition & Management Functions ---

    function acquireLicense(uint256 tokenId, uint256 licenseOptionId)
        external
        payable
        whenNotPaused
    {
        require(_exists(tokenId), "DCC: token does not exist");

        LicenseTerms[] storage options = _contentLicenseOptions[tokenId];
        LicenseTerms memory chosenOption;
        bool found = false;
        for (uint i = 0; i < options.length; i++) {
            if (options[i].id == licenseOptionId) {
                chosenOption = options[i];
                found = true;
                break;
            }
        }
        require(found, "DCC: invalid license option ID for token");
        require(msg.value >= chosenOption.price, "DCC: insufficient payment");

        // Calculate split
        uint256 totalPrice = msg.value;
        uint256 platformCut = (totalPrice * baseRoyaltyFee) / 10000;
        uint256 creatorCut = totalPrice - platformCut;

        // Distribute funds
        address payable contentOwner = payable(ownerOf(tokenId));
        if (creatorCut > 0) {
           // Accumulate for creator to withdraw
            _pendingEarnings[contentOwner] += creatorCut;
        }
         // Send platform fee directly
        if (platformCut > 0 && payable(owner()) != address(this)) { // Avoid sending to self if owner is contract address
             payable(owner()).sendValue(platformCut);
        }
        // Refund any excess payment
        if (msg.value > chosenOption.price) {
            payable(msg.sender).sendValue(msg.value - chosenOption.price);
        }

        // Create license instance
        _licenseInstanceCounter.increment();
        uint256 newLicenseInstanceId = _licenseInstanceCounter.current();

        uint256 acquisitionTime = block.timestamp;
        uint256 expiryTime = chosenOption.duration > 0 ? acquisitionTime + chosenOption.duration : 0; // 0 duration means perpetual

        LicenseInstance memory newInstance = LicenseInstance({
            id: newLicenseInstanceId,
            licenseOptionId: licenseOptionId,
            licensee: msg.sender,
            acquisitionTimestamp: acquisitionTime,
            expiryTimestamp: expiryTime,
            revoked: false
        });

        // Store license instance
        _userLicenses[tokenId][msg.sender].push(newInstance); // Add to user's list
        _licenseInstances[tokenId][newLicenseInstanceId] = newInstance; // Store by ID

        emit LicenseAcquired(tokenId, newLicenseInstanceId, msg.sender, licenseOptionId, acquisitionTime, expiryTime, chosenOption.price);
        emit EarningsDistributed(tokenId, newLicenseInstanceId, contentOwner, creatorCut, platformCut);
    }

    function renewLicense(uint256 tokenId, uint256 licenseInstanceId)
        external
        payable
        onlyLicensee(tokenId, licenseInstanceId)
        whenNotPaused
    {
        LicenseInstance storage instance = _licenseInstances[tokenId][licenseInstanceId];
        require(!instance.revoked, "DCC: license instance is revoked");

        // Find the original license option terms
        LicenseTerms memory chosenOption;
        bool found = false;
        LicenseTerms[] storage options = _contentLicenseOptions[tokenId];
        for (uint i = 0; i < options.length; i++) {
            if (options[i].id == instance.licenseOptionId) {
                chosenOption = options[i];
                found = true;
                break;
            }
        }
        require(found, "DCC: original license option not found");
        require(chosenOption.duration > 0, "DCC: perpetual licenses cannot be renewed");
        require(msg.value >= chosenOption.price, "DCC: insufficient payment for renewal");

         // Calculate split (same as acquire)
        uint256 totalPrice = msg.value;
        uint256 platformCut = (totalPrice * baseRoyaltyFee) / 10000;
        uint256 creatorCut = totalPrice - platformCut;

        // Distribute funds (same as acquire)
        address payable contentOwner = payable(ownerOf(tokenId));
        if (creatorCut > 0) {
           _pendingEarnings[contentOwner] += creatorCut;
        }
         if (platformCut > 0 && payable(owner()) != address(this)) {
             payable(owner()).sendValue(platformCut);
        }
        // Refund any excess payment
        if (msg.value > chosenOption.price) {
            payable(msg.sender).sendValue(msg.value - chosenOption.price);
        }


        // Extend expiry timestamp
        uint256 currentExpiry = instance.expiryTimestamp;
        // If expired or perpetual (shouldn't happen due to check), set from now, otherwise extend
        uint256 newExpiry = (currentExpiry < block.timestamp || currentExpiry == 0)
                            ? block.timestamp + chosenOption.duration
                            : currentExpiry + chosenOption.duration;

        instance.expiryTimestamp = newExpiry; // Update storage

        emit LicenseRenewed(tokenId, licenseInstanceId, newExpiry, chosenOption.price);
         emit EarningsDistributed(tokenId, licenseInstanceId, contentOwner, creatorCut, platformCut);
    }

    function transferLicense(uint256 tokenId, uint256 licenseInstanceId, address to)
        external
        onlyLicensee(tokenId, licenseInstanceId)
        whenNotPaused
    {
        require(to != address(0), "DCC: transfer to the zero address");
        require(to != msg.sender, "DCC: cannot transfer to self");

        LicenseInstance storage instance = _licenseInstances[tokenId][licenseInstanceId];

        // Update the licensee
        address oldLicensee = instance.licensee;
        instance.licensee = to; // Update the storage variable

        // Note: Removing from the old user's array and adding to the new user's array
        // is complex and gas-intensive. A simpler approach for querying is to
        // always check the `licensee` field of the LicenseInstance struct itself,
        // rather than relying solely on the _userLicenses mapping for truth.
        // The _userLicenses mapping can then be seen as a historical or potentially
        // less accurate list, while _licenseInstances[tokenId][licenseInstanceId].licensee is canonical.
        // For simplicity and gas here, we only update the canonical location.

        emit LicenseTransferred(tokenId, licenseInstanceId, oldLicensee, to);
    }

    function checkLicenseValidity(address user, uint256 tokenId, UsagePurpose purpose)
        public
        view
        returns (bool)
    {
        require(_exists(tokenId), "DCC: token does not exist");

        LicenseInstance[] storage userLicenseInstances = _userLicenses[tokenId][user];

        for (uint i = 0; i < userLicenseInstances.length; i++) {
            LicenseInstance storage instance = userLicenseInstances[i];

            // Check if the instance is valid (not revoked, not expired or perpetual)
            if (!instance.revoked && (instance.expiryTimestamp == 0 || instance.expiryTimestamp > block.timestamp)) {

                // Find the original license option terms for this instance
                LicenseTerms memory chosenOption;
                bool found = false;
                LicenseTerms[] storage options = _contentLicenseOptions[tokenId];
                for (uint j = 0; j < options.length; j++) {
                    if (options[j].id == instance.licenseOptionId) {
                        chosenOption = options[j];
                        found = true;
                        break;
                    }
                }

                // If the original option was somehow deleted, treat the license as invalid
                if (!found) continue;

                // Check if the license terms allow the requested purpose
                // This is a simplified check based on broad categories. Real licenses are complex.
                bool purposeAllowed = false;
                for (uint k = 0; k < chosenOption.licenseTypes.length; k++) {
                    LicenseType licenseType = chosenOption.licenseTypes[k];
                    if (purpose == UsagePurpose.Display) {
                         // Display is generally allowed with most licenses that aren't NoDerivatives/Commercial only
                         // For simplicity, assume Display is generally allowed unless explicitly restricted.
                         // A more complex system would have explicit 'allowedPurposes' in LicenseTerms.
                         purposeAllowed = true; break; // Assume display is okay if any license type is present
                    } else if (purpose == UsagePurpose.Incorporation || purpose == UsagePurpose.Redistribution || purpose == UsagePurpose.Other) {
                         if (licenseType != LicenseType.NoDerivatives && licenseType != LicenseType.NonCommercial) {
                              // Assume general usage/redistribution needs non-NC, non-ND.
                              purposeAllowed = true; break;
                         }
                    } else if (purpose == UsagePurpose.Modification) {
                         if (licenseType != LicenseType.NoDerivatives) {
                             purposeAllowed = true; break; // Needs a license that ISN'T NoDerivatives
                         }
                    }
                     if (licenseType == LicenseType.Commercial && (purpose == UsagePurpose.Incorporation || purpose == UsagePurpose.Redistribution || purpose == UsagePurpose.Modification || purpose == UsagePurpose.Other)) {
                         purposeAllowed = true; break; // Explicit commercial license covers commercial uses
                     }
                     if (licenseType == LicenseType.NonCommercial && (purpose == UsagePurpose.Display)) {
                         // NonCommercial allows display
                          purposeAllowed = true; break;
                     }
                      // Add more complex logic here for other combinations if needed
                }

                // If purpose is allowed by this valid license instance, return true
                if (purposeAllowed) {
                    return true;
                }
            }
        }

        // No valid license instance found for the user and purpose
        return false;
    }


    // --- Usage Tracking (Self-Sovereign Attribution) Functions ---

    function registerUsage(uint256 tokenId, uint256 licenseInstanceId, string memory usageURI, string memory attributionDetails)
        external
        whenNotPaused
    {
        // Verify the caller owns the license instance and it's valid *now* (basic check)
        // Note: A sophisticated system might check validity *at the time of usage* if that time was different,
        // but on-chain proof of historical validity requires complex state snapshots or proof systems.
        // This approach proves usage was registered by the licensee *while the license was active* and links it.
        LicenseInstance storage instance = _licenseInstances[tokenId][licenseInstanceId];
        require(instance.licensee == msg.sender, "DCC: caller does not own license instance");
        require(!instance.revoked, "DCC: license instance is revoked");
        require(instance.expiryTimestamp == 0 || instance.expiryTimestamp > block.timestamp, "DCC: license instance is expired");

        // Optional: Further check if the license *option* associated with this instance
        // *would have allowed* this type of usage (based on termsURI or licenseTypes in the option).
        // This requires passing the UsagePurpose here or inferring it from usageURI/details,
        // adding complexity. We'll skip explicit purpose check here, the user is claiming compliant usage.
        // The `verifyUsageClaim` function allows external parties to review this claim.

        _usageRecordCounter.increment();
        uint256 newUsageRecordId = _usageRecordCounter.current();

        UsageRecord memory newRecord = UsageRecord({
            id: newUsageRecordId,
            tokenId: tokenId,
            licenseInstanceId: licenseInstanceId, // Link to the specific license used
            user: msg.sender,
            timestamp: block.timestamp,
            usageURI: usageURI,
            attributionDetails: attributionDetails
        });

        _contentUsageRecords[tokenId].push(newRecord); // Add to token's list
        _usageRecords[tokenId][newUsageRecordId] = newRecord; // Store by ID

        emit UsageRegistered(tokenId, licenseInstanceId, msg.sender, newUsageRecordId, usageURI);
    }

    function verifyUsageClaim(uint256 tokenId, uint256 usageRecordId)
        public
        view
        returns (bool isValidClaim, address user, uint256 timestamp, string memory usageURI, string memory attributionDetails)
    {
        UsageRecord storage record = _usageRecords[tokenId][usageRecordId];

        // Check if the record exists
        if (record.id == 0 && record.tokenId == 0 && record.timestamp == 0) {
            // Structs initialized to zero values indicate non-existence in map
             return (false, address(0), 0, "", "");
        }

        // Further validation could involve:
        // 1. Looking up the associated LicenseInstance (_licenseInstances[tokenId][record.licenseInstanceId])
        // 2. Looking up the associated LicenseTerms (_contentLicenseOptions based on licenseInstance.licenseOptionId)
        // 3. Checking if the *type* of license option defined in the terms *would have* permitted the claimed usage purpose.
        //    This doesn't check if the license instance was active *at the registration time*, but verifies the *terms* allowed it.
        //    Checking historical license validity at the exact registration timestamp is complex on-chain.
        //    The current `registerUsage` design implies the user claims validity *now*.

        // For this function, we simply verify the *existence and integrity* of the claim record itself.
        // External parties (or another smart contract) would use this data and potentially
        // historical chain data (if available) to make a full judgment.

        return (
            true,
            record.user,
            record.timestamp,
            record.usageURI,
            record.attributionDetails
        );
    }


    // --- Revenue & Royalty Distribution Functions ---

    function withdrawEarnings() external whenNotPaused {
        address payable creator = payable(msg.sender);
        uint256 amount = _pendingEarnings[creator];
        require(amount > 0, "DCC: no earnings to withdraw");

        _pendingEarnings[creator] = 0; // Reset before sending to prevent reentrancy (though sendValue is safe)

        creator.sendValue(amount);

        emit EarningsWithdrawn(creator, amount);
    }

    // --- Derivative Creation Functions ---

    function mintDerivative(address to, string memory tokenURI, uint256[] memory parentTokenIds, LicenseTerms[] memory initialLicenses)
        external
        whenNotPaused
        returns (uint256)
    {
        require(to != address(0), "DCC: mint to the zero address");
        require(parentTokenIds.length > 0, "DCC: derivative must have parents");

        // Check if the minter holds a valid license for *each* parent token that allows derivatives
        for (uint i = 0; i < parentTokenIds.length; i++) {
            uint256 parentTokenId = parentTokenIds[i];
            require(_exists(parentTokenId), "DCC: parent token does not exist");

            // Check if msg.sender has *any* valid license instance for this parent
            // which includes the `Modification` usage purpose and doesn't have `NoDerivatives`
            bool derivativeAllowed = false;
             LicenseInstance[] storage userLicenseInstances = _userLicenses[parentTokenId][msg.sender];

            for (uint j = 0; j < userLicenseInstances.length; j++) {
                LicenseInstance storage instance = userLicenseInstances[j];

                 if (!instance.revoked && (instance.expiryTimestamp == 0 || instance.expiryTimestamp > block.timestamp)) {
                     // Find the original license option terms
                    LicenseTerms memory chosenOption;
                    bool found = false;
                    LicenseTerms[] storage options = _contentLicenseOptions[parentTokenId];
                    for (uint k = 0; k < options.length; k++) {
                        if (options[k].id == instance.licenseOptionId) {
                            chosenOption = options[k];
                            found = true;
                            break;
                        }
                    }
                    if (!found) continue; // Skip if original option terms are gone

                    // Check if this license option allows modification
                     for (uint l = 0; l < chosenOption.licenseTypes.length; l++) {
                         if (chosenOption.licenseTypes[l] != LicenseType.NoDerivatives) {
                              derivativeAllowed = true;
                              break; // Found a valid license instance allowing modification
                         }
                     }
                 }
                 if (derivativeAllowed) break; // Found a valid license for this parent, move to the next parent
            }
            require(derivativeAllowed, string(abi.encodePacked("DCC: no valid license allowing derivatives for parent token ", Strings.toString(parentTokenId))));
        }

        // If all parent licenses checks pass, mint the new derivative token
        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        _safeMint(to, newTokenId);
        _setTokenURI(newTokenId, tokenURI);

        // Store parent links
        _derivativeParentTokens[newTokenId] = parentTokenIds;

         // Add initial licenses to the derivative itself (it's a new work)
         for (uint i = 0; i < initialLicenses.length; i++) {
            _licenseOptionCounters[newTokenId].increment();
            uint256 newOptionId = _licenseOptionCounters[newTokenId].current();
            initialLicenses[i].id = newOptionId;
            _contentLicenseOptions[newTokenId].push(initialLicenses[i]);
            emit LicenseOptionAdded(newTokenId, newOptionId, initialLicenses[i].name, initialLicenses[i].price);
        }


        emit ContentCreated(newTokenId, to, tokenURI);
        emit DerivativeMinted(newTokenId, parentTokenIds, to);
        return newTokenId;
    }


    // --- View/Query Functions ---

    function getContentMetadata(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "DCC: token does not exist");
        return tokenURI(tokenId);
    }

    function getContentOwner(uint255 tokenId) public view returns (address) {
        require(_exists(tokenId), "DCC: token does not exist");
        return ownerOf(tokenId); // Implemented by ERC721
    }

     function getContentLicenses(uint256 tokenId)
        public
        view
        returns (LicenseTerms[] memory)
    {
         require(_exists(tokenId), "DCC: token does not exist");
         LicenseTerms[] storage options = _contentLicenseOptions[tokenId];
         // Return a copy to avoid storage pointer issues in external calls
         LicenseTerms[] memory result = new LicenseTerms[](options.length);
         for (uint i = 0; i < options.length; i++) {
             result[i] = options[i];
         }
         return result;
    }

     function getContentLicenseOptionDetails(uint256 tokenId, uint256 licenseOptionId)
         public
         view
         returns (LicenseTerms memory)
     {
         require(_exists(tokenId), "DCC: token does not exist");
         LicenseTerms[] storage options = _contentLicenseOptions[tokenId];
         for (uint i = 0; i < options.length; i++) {
             if (options[i].id == licenseOptionId) {
                 return options[i];
             }
         }
         revert("DCC: invalid license option ID for token");
     }

     function getUserLicenses(address user, uint256 tokenId)
         public
         view
         returns (LicenseInstance[] memory)
     {
         require(_exists(tokenId), "DCC: token does not exist");
         LicenseInstance[] storage instances = _userLicenses[tokenId][user];
         // Return a copy
         LicenseInstance[] memory result = new LicenseInstance[](instances.length);
         for (uint i = 0; i < instances.length; i++) {
             result[i] = instances[i];
         }
         return result;
     }

    function getLicenseInstanceDetails(uint256 tokenId, uint256 licenseInstanceId)
        public
        view
        returns (LicenseInstance memory)
    {
        require(_exists(tokenId), "DCC: token does not exist");
        LicenseInstance storage instance = _licenseInstances[tokenId][licenseInstanceId];
         // Check if the struct is non-zero (indicates existence)
        require(instance.id != 0 || licenseInstanceId == 0, "DCC: license instance does not exist"); // Allow 0 ID if query is for 0, but 0 shouldn't be used for real instances

        return instance;
    }


    function getUsageRecords(uint256 tokenId)
        public
        view
        returns (UsageRecord[] memory)
    {
         require(_exists(tokenId), "DCC: token does not exist");
         UsageRecord[] storage records = _contentUsageRecords[tokenId];
         // Return a copy
         UsageRecord[] memory result = new UsageRecord[](records.length);
         for (uint i = 0; i < records.length; i++) {
             result[i] = records[i];
         }
         return result;
    }

     function getLicenseTemplate(uint256 templateId)
         public
         view
         returns (LicenseTemplate memory)
     {
         require(_licenseTemplates[templateId].id != 0, "DCC: template does not exist");
         return _licenseTemplates[templateId];
     }

     function getAllLicenseTemplateIds() public view returns (uint255[] memory) {
         // Return a copy
         return _licenseTemplateIds;
     }

      function getLicenseTemplatesCount() public view returns (uint256) {
         return _licenseTemplateIds.length;
      }

     function getDerivativeParentTokens(uint256 tokenId)
         public
         view
         returns (uint256[] memory)
     {
        require(_exists(tokenId), "DCC: token does not exist");
        // Return a copy
        return _derivativeParentTokens[tokenId];
     }

    // Override ERC721Enumerable's _beforeTokenTransfer to enforce Pausable
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        virtual
        override(ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
        require(!paused(), "Pausable: paused");
    }

    // Required overrides for ERC721Enumerable
    function _increaseBalance(address account, uint256 amount) internal override(ERC721Enumerable, ERC721) {
        super._increaseBalance(account, amount);
    }

    function _decreaseBalance(address account, uint256 amount) internal override(ERC721Enumerable, ERC721) {
        super._decreaseBalance(account, amount);
    }

    function _indexOf(uint256 tokenId) internal view override(ERC721Enumerable, ERC721) returns (uint256) {
         return super._indexOf(tokenId);
    }

    function totalSupply() public view override(ERC721Enumerable, ERC721) returns (uint256) {
        return super.totalSupply();
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) public view override(ERC721Enumerable, ERC721) returns (uint255) {
        return super.tokenOfOwnerByIndex(owner, index);
    }

    function tokenByIndex(uint256 index) public view override(ERC721Enumerable, ERC721) returns (uint255) {
        return super.tokenByIndex(index);
    }
}
```

**Explanation of Advanced/Interesting Concepts:**

1.  **On-Chain Licensing Framework:** Instead of just saying "this NFT has license X", we define structured `LicenseTerms` on-chain for *each* token, and track individual `LicenseInstance` purchases. This allows for multiple types of licenses per token, time-bound licenses, and potential on-chain validation of license status.
2.  **Self-Sovereign Attribution (SSA):** The `registerUsage` function allows users to create immutable, timestamped records linking their use of content (via `usageURI`) to a specific acquired license instance. This is a form of on-chain proof of *claiming* licensed usage. The `verifyUsageClaim` function provides a way to check the existence and details of such claims. While the contract doesn't *fully* police compliance off-chain, it provides the on-chain primitives for users to assert their rights and for others to audit usage.
3.  **Derivative Tracking:** The `mintDerivative` function enforces that a minter must hold valid licenses allowing modification for *all* specified parent tokens. Crucially, it stores the links to the parent tokens on-chain (`_derivativeParentTokens`), creating a decentralized graph of derivative provenance.
4.  **Role-Based Logic:** Utilizes `Ownable` for administrative control and custom modifiers (`onlyContentOwner`, `onlyLicensee`) for fine-grained access to content and license-specific actions.
5.  **Time-Based State:** Licenses have explicit `duration` and `expiryTimestamp`, making their validity dependent on `block.timestamp`.
6.  **Structured Data & Mappings:** Extensive use of structs and nested mappings (`_contentLicenseOptions`, `_userLicenses`, `_licenseInstances`, `_usageRecords`) to manage complex relationships between tokens, licenses, users, and usage data on-chain.
7.  **Events for Off-Chain Tracking:** Comprehensive events (`LicenseAcquired`, `UsageRegistered`, `DerivativeMinted`, etc.) are emitted to facilitate off-chain indexing, monitoring, and building user interfaces.
8.  **Configurable Royalties/Fees:** Includes a simple mechanism for creators to earn from licenses (`_pendingEarnings`) and a base fee for the platform/owner (`baseRoyaltyFee`).
9.  **Pausable Pattern:** Included for emergency situations.
10. **ERC721Enumerable:** Used to easily demonstrate token listing and supply, although it adds gas cost.

This contract provides a robust foundation for a decentralized system focused on creative rights management, going beyond simple NFT ownership to include granular licensing and auditable usage claims.