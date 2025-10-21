This smart contract, "Aether Canvas," introduces a novel platform for AI-generated NFT art with an advanced, programmable licensing system. Users can submit text prompts, an off-chain AI (via a trusted oracle) generates the artwork, which can then be minted as an NFT. What makes Aether Canvas unique is its layered licensing: creators can define custom license *templates* and attach specific *instances* of these licenses to their NFTs, dictating usage rights (commercial, derivative works, resale royalties) independently of NFT ownership. This allows for intricate rights management and new monetization models beyond simple NFT sales.

---

## Aether Canvas: Generative AI NFT Art & Programmable Licensing Platform

### Outline:

*   **I. State Variables & Data Structures:** Defines the core data models for prompts, AI models, license templates, license instances, and marketplace listings.
*   **II. Events:** Declares events for tracking key actions and state changes within the contract.
*   **III. Modifiers:** Custom modifiers for access control and contract state checks.
*   **IV. Constructor:** Initializes the contract, setting the owner, trusted oracle, and default platform parameters.
*   **V. Platform Management (Owner Functions):** Functions accessible only by the contract owner for configuration and administration.
*   **VI. Prompt Submission & AI Generation:** Handles the user's journey from submitting a prompt to getting their artwork generated.
*   **VII. NFT Minting & Core ERC721 Functions:** Manages the creation and standard operations of the ERC-721 NFTs. Includes ERC2981 for creator royalties on NFT resales.
*   **VIII. Advanced Licensing System:** The core innovation – defining, attaching, purchasing, and verifying complex usage licenses for NFTs.
*   **IX. Marketplace Functionality:** Enables listing and purchasing of NFTs and their associated license instances.
*   **X. Earnings & Withdrawals:** Manages the distribution and withdrawal of funds earned by creators, owners, and the platform.
*   **XI. Public View Functions (Getters):** Provides read-only access to contract state for transparency and external dApps.

### Function Summary:

**Platform Management (Owner Functions):**
1.  `constructor`: Initializes the contract with the owner, trusted oracle address, and default fees.
2.  `updateOracleAddress`: Allows the owner to change the address of the trusted AI generation oracle.
3.  `updatePromptSubmissionFee`: Sets the fee required from users to submit a prompt for AI generation.
4.  `updatePlatformRoyaltyRate`: Configures the platform's percentage cut from NFT sales and license purchases.
5.  `togglePauseContract`: Pauses or unpauses core contract functionalities in emergencies.
6.  `withdrawPlatformFees`: Enables the contract owner to withdraw accumulated platform fees.
7.  `setApprovedAIModel`: Registers or updates metadata (e.g., pricing, capabilities) for different approved AI generation models.

**Prompt Submission & AI Generation:**
8.  `submitPromptForGeneration`: Users submit a text prompt, pay a fee, stake tokens, and specify a desired AI model to generate art.
9.  `processGeneratedArtworkHash`: **(Oracle-only function)** Called by the trusted oracle to confirm successful AI generation and provide the cryptographic hash of the artwork.
10. `claimPromptStake`: Allows the prompt submitter to retrieve their staked tokens after the artwork has been successfully generated.
11. `cancelPromptRequest`: Enables a user to cancel an unprocessed prompt request and receive a refund of their fee and stake.

**NFT Minting & Core ERC721 Functions:**
12. `mintGeneratedArtworkNFT`: The user who submitted the prompt can mint the AI-generated artwork as an ERC-721 NFT, establishing them as the initial creator.
13. `transferFrom`: Standard ERC-721 function to transfer ownership of an NFT.
14. `approve`: Standard ERC-721 function to grant approval for another address to transfer a specific NFT.
15. `getApproved`: Standard ERC-721 function to query the approved address for an NFT.
16. `setApprovalForAll`: Standard ERC-721 function to grant or revoke operator status for all NFTs owned by an address.
17. `ownerOf`: Standard ERC-721 function to get the owner of a specific NFT.
18. `balanceOf`: Standard ERC-721 function to get the number of NFTs owned by an address.
19. `royaltyInfo`: (ERC-2981) Returns the royalty receiver and percentage for an NFT, specifically for *resales of the NFT itself*.
20. `setNFTCreatorRoyaltyInfo`: The original creator of an NFT can set their royalty percentage for future NFT resales (ERC-2981 compliant).

**Advanced Licensing System:**
21. `defineLicenseTemplate`: An NFT creator defines a reusable, named license template (e.g., "Personal Use," "Commercial Basic") with default terms like commercial usage, derivative works, and resale royalty rates.
22. `attachLicenseToNFT`: The NFT creator or current owner attaches an instance of a defined license template to a specific NFT, optionally customizing its price, duration, and other terms for that specific instance.
23. `revokeLicenseInstance`: Allows the NFT owner to revoke an unpurchased license instance they previously attached to an NFT.
24. `purchaseLicenseInstance`: A user purchases a specific license instance for an NFT, granting them the defined usage rights.
25. `verifyLicenseUse`: A public view function to check if a specific address holds a valid, active license for a given NFT for a particular intended `usageType` (e.g., commercial, derivative).

**Marketplace Functionality:**
26. `listNFTForFixedPriceSale`: An NFT owner lists their NFT for direct sale at a fixed price.
27. `buyNFT`: A user purchases a listed NFT, triggering the distribution of funds to the seller, original creator (royalties via ERC-2981), and the platform.

**Earnings & Withdrawals:**
28. `withdrawEarnings`: Allows any user (creators, NFT sellers, license sellers) to withdraw their accumulated earnings from sales and royalties.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC2981/ERC2981.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol"; // For potential oracle signature verification, though here we trust 'oracleAddress'
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // Although Solidity 0.8+ has built-in checks, good practice for clarity in complex math

/// @title Aether Canvas: Generative AI NFT Art & Programmable Licensing Platform
/// @author YourName (GPT-4)
/// @notice This contract enables users to submit prompts for AI-generated artwork, mint these artworks as NFTs, and define/sell advanced usage licenses for these NFTs.
/// @dev It integrates a trusted oracle for AI generation, ERC-721 for NFTs, and ERC-2981 for creator royalties on NFT resales.
///      The unique feature is its multi-layered licensing system allowing fine-grained control over digital asset usage.

// Function Summary:
//
// Platform Management (Owner Functions):
// - constructor: Initializes the contract, sets owner, oracle address, and default fees.
// - updateOracleAddress: Updates the address of the trusted oracle.
// - updatePromptSubmissionFee: Adjusts the fee required to submit a prompt for AI generation.
// - updatePlatformRoyaltyRate: Sets the platform's percentage cut on sales and license purchases.
// - togglePauseContract: Pauses or unpauses critical contract functionalities.
// - withdrawPlatformFees: Allows the contract owner to withdraw accumulated platform fees.
// - setApprovedAIModel: Registers or updates metadata for an approved AI generation model.
//
// Prompt Submission & AI Generation:
// - submitPromptForGeneration: Users submit a text prompt, pay a fee, stake tokens, and specify an AI model.
// - processGeneratedArtworkHash: (Oracle-only function) Called by the trusted oracle to confirm AI generation and provide the artwork's content hash.
// - claimPromptStake: Allows a user to claim back their prompt stake after successful generation.
// - cancelPromptRequest: Allows a user to cancel an unprocessed prompt request and receive a refund.
//
// NFT Minting & Core ERC721 Functions:
// - mintGeneratedArtworkNFT: Mints the AI-generated artwork as an ERC-721 NFT for the prompt submitter.
// - transferFrom: Transfers ownership of an NFT (ERC-721 standard).
// - approve: Approves an address to manage a specific NFT (ERC-721 standard).
// - getApproved: Returns the approved address for a specific NFT (ERC-721 standard).
// - setApprovalForAll: Approves or revokes an operator for all NFTs (ERC-721 standard).
// - ownerOf: Returns the owner of a specific NFT (ERC-721 standard).
// - balanceOf: Returns the number of NFTs owned by an address (ERC-721 standard).
// - royaltyInfo: (ERC-2981) Returns the royalty receiver and percentage for an NFT.
// - setNFTCreatorRoyaltyInfo: The original creator of an NFT sets their royalty percentage for future NFT resales (ERC-2981).
//
// Advanced Licensing System:
// - defineLicenseTemplate: The original creator defines a reusable license template with default terms.
// - attachLicenseToNFT: NFT creator/owner attaches an instance of a license template to their NFT, setting specific terms.
// - revokeLicenseInstance: Allows the NFT owner to revoke an unpurchased license instance.
// - purchaseLicenseInstance: A user purchases a specific license instance for an NFT.
// - verifyLicenseUse: Checks if an address holds a valid license for a given NFT for a specific usage type.
//
// Marketplace Functionality:
// - listNFTForFixedPriceSale: An NFT owner lists their NFT for sale at a fixed price.
// - buyNFT: A user purchases a listed NFT, triggering royalty and platform fee distribution.
//
// Earnings & Withdrawals:
// - withdrawEarnings: Allows creators, NFT owners, and license sellers to withdraw their accumulated earnings.
//
// Public View Functions (Getters - implicit from ERC721, plus custom ones):
// - getPromptRequest: Retrieves details of a prompt submission.
// - getLicenseTemplate: Retrieves details of a defined license template.
// - getLicenseInstance: Retrieves details of an attached license instance.
// - getNFTCreatorRoyaltyInfo: Returns the creator royalty information for an NFT.
// - getApprovedAIModel: Retrieves details of an approved AI model.


contract AetherCanvas is ERC721, ERC2981, Ownable, Pausable {
    using SafeMath for uint256; // Explicitly use SafeMath (even if not strictly needed in 0.8+, for clarity)

    // I. State Variables & Data Structures

    // --- Configuration ---
    address private _oracleAddress;
    uint256 public promptSubmissionFee; // Fee to submit a prompt
    uint16 public platformRoyaltyRateBps; // Platform's cut in Basis Points (e.g., 500 = 5%)
    uint256 public nextPromptRequestId;
    uint256 public nextLicenseTemplateId;
    uint256 public nextLicenseInstanceId;

    // --- Data Storage ---
    mapping(address => uint256) public earnings; // Accumulated earnings for users

    // AI Models
    struct AIModel {
        string name;
        uint256 costPerGeneration; // Example: 0 if oracle handles pricing separately
        bool isActive;
    }
    mapping(bytes32 => AIModel) public approvedAIModels; // bytes32 for AI model ID (e.g., hash of model name)

    // Prompt Requests
    enum PromptStatus {
        Pending,
        Generated,
        Minted,
        Cancelled
    }
    struct PromptRequest {
        address submitter;
        string promptText;
        bytes32 aiModelId; // Identifier for the AI model used
        uint256 submissionFee;
        uint256 stakeAmount; // Optional stake for priority/quality
        PromptStatus status;
        bytes32 contentHash; // Hash of the generated artwork, set by oracle
        uint48 timestamp;
        uint256 tokenId; // Set when artwork is minted
    }
    mapping(uint256 => PromptRequest) public promptRequests; // promptId => PromptRequest

    // NFT Artwork
    mapping(uint256 => address) public nftCreator; // tokenId => original minter/creator

    // Licensing System
    enum UsageType {
        Personal,
        Commercial,
        Derivative,
        Resale
    }

    struct LicenseTemplate {
        string name;
        string description;
        bool canBeResold; // If the license itself can be resold
        bool canBeUsedCommercially;
        bool allowsDerivativeWorks;
        uint16 royaltyRateForLicenseResaleBps; // Royalty for reselling THIS license instance
        uint256 suggestedInitialPrice; // Non-binding suggestion for attaching
        address creator; // Address who defined this template
        bool isActive;
    }
    mapping(uint256 => LicenseTemplate) public licenseTemplates; // licenseTemplateId => LicenseTemplate

    struct LicenseInstance {
        uint256 licenseTemplateId;
        uint256 nftId;
        address ownerAddress; // Current owner of this license instance (can be different from NFT owner)
        uint256 price; // Actual price set when attached
        uint48 duration; // Duration in seconds (0 for perpetual)
        address purchaserAddress; // 0x0 if not purchased
        uint48 purchaseTimestamp; // 0 if not purchased
        bool isActive; // Can be revoked or expires
        uint16 customRoyaltyRateForLicenseResaleBps; // Override template default
        uint256 creatorRoyaltyShare; // For tracking earnings if license is resold
    }
    mapping(uint256 => LicenseInstance) public licenseInstances; // licenseInstanceId => LicenseInstance
    mapping(uint256 => uint256[]) public nftToLicenseInstances; // nftId => array of licenseInstanceIds

    // Marketplace
    struct NFTListing {
        uint256 nftId;
        address seller;
        uint256 price;
        bool isActive;
    }
    mapping(uint256 => NFTListing) public nftListings; // nftId => NFTListing

    // II. Events
    event OracleAddressUpdated(address indexed newOracleAddress);
    event PromptSubmissionFeeUpdated(uint256 newFee);
    event PlatformRoyaltyRateUpdated(uint16 newRateBps);
    event ApprovedAIModelSet(bytes32 indexed aiModelId, string name, uint256 costPerGeneration, bool isActive);

    event PromptSubmitted(uint256 indexed promptId, address indexed submitter, string promptText, bytes32 aiModelId, uint256 fee, uint256 stake);
    event ArtworkGenerated(uint256 indexed promptId, bytes32 indexed contentHash);
    event PromptCancelled(uint256 indexed promptId, address indexed submitter);
    event PromptStakeClaimed(uint256 indexed promptId, address indexed submitter, uint256 stakeAmount);

    event NFTMinted(uint256 indexed tokenId, address indexed creator, uint256 indexed promptId, bytes32 contentHash);
    event NFTCreatorRoyaltySet(uint256 indexed tokenId, address indexed creator, uint96 royaltyFraction);

    event LicenseTemplateDefined(uint256 indexed templateId, address indexed creator, string name);
    event LicenseInstanceAttached(uint256 indexed instanceId, uint256 indexed nftId, address indexed owner, uint256 price, uint48 duration);
    event LicenseInstanceRevoked(uint256 indexed instanceId, uint256 indexed nftId, address indexed revoker);
    event LicenseInstancePurchased(uint256 indexed instanceId, uint256 indexed nftId, address indexed purchaser, uint256 price);

    event NFTListedForSale(uint256 indexed nftId, address indexed seller, uint256 price);
    event NFTPurchased(uint256 indexed nftId, address indexed buyer, address indexed seller, uint256 price);

    event EarningsWithdrawn(address indexed beneficiary, uint256 amount);

    // III. Modifiers
    modifier onlyOracle() {
        require(msg.sender == _oracleAddress, "AetherCanvas: Only trusted oracle can call this function");
        _;
    }

    // IV. Constructor
    constructor(address initialOracleAddress, string memory name, string memory symbol)
        ERC721(name, symbol)
        Ownable(msg.sender)
        Pausable()
    {
        require(initialOracleAddress != address(0), "AetherCanvas: Invalid oracle address");
        _oracleAddress = initialOracleAddress;
        promptSubmissionFee = 0.001 ether; // Default fee
        platformRoyaltyRateBps = 250; // Default 2.5%
        nextPromptRequestId = 1;
        nextLicenseTemplateId = 1;
        nextLicenseInstanceId = 1;

        emit OracleAddressUpdated(initialOracleAddress);
        emit PromptSubmissionFeeUpdated(promptSubmissionFee);
        emit PlatformRoyaltyRateUpdated(platformRoyaltyRateBps);
    }

    // V. Platform Management (Owner Functions)

    /// @notice Updates the address of the trusted oracle.
    /// @param newOracleAddress The new address for the oracle.
    function updateOracleAddress(address newOracleAddress) external onlyOwner {
        require(newOracleAddress != address(0), "AetherCanvas: New oracle address cannot be zero");
        _oracleAddress = newOracleAddress;
        emit OracleAddressUpdated(newOracleAddress);
    }

    /// @notice Adjusts the fee required to submit a prompt for AI generation.
    /// @param newFee The new prompt submission fee in wei.
    function updatePromptSubmissionFee(uint256 newFee) external onlyOwner {
        promptSubmissionFee = newFee;
        emit PromptSubmissionFeeUpdated(newFee);
    }

    /// @notice Sets the platform's percentage cut on sales and license purchases.
    /// @param newRateBps The new platform royalty rate in basis points (e.g., 250 for 2.5%). Max 10000.
    function updatePlatformRoyaltyRate(uint16 newRateBps) external onlyOwner {
        require(newRateBps <= 10000, "AetherCanvas: Rate cannot exceed 100%");
        platformRoyaltyRateBps = newRateBps;
        emit PlatformRoyaltyRateUpdated(newRateBps);
    }

    /// @notice Pauses or unpauses critical contract functionalities.
    function togglePauseContract() external onlyOwner {
        if (paused()) {
            _unpause();
        } else {
            _pause();
        }
    }

    /// @notice Allows the contract owner to withdraw accumulated platform fees.
    function withdrawPlatformFees() external onlyOwner {
        uint256 amount = earnings[address(this)];
        require(amount > 0, "AetherCanvas: No platform fees to withdraw");
        earnings[address(this)] = 0;
        payable(owner()).transfer(amount);
        emit EarningsWithdrawn(owner(), amount);
    }

    /// @notice Registers or updates metadata for an approved AI generation model.
    /// @param aiModelId A unique identifier for the AI model (e.g., a hash or short string).
    /// @param name The human-readable name of the AI model.
    /// @param costPerGeneration The internal cost associated with using this model (can be 0 if oracle handles pricing externally).
    /// @param isActive Whether the model is currently active and available for use.
    function setApprovedAIModel(
        bytes32 aiModelId,
        string calldata name,
        uint256 costPerGeneration,
        bool isActive
    ) external onlyOwner {
        require(aiModelId != bytes32(0), "AetherCanvas: AI Model ID cannot be zero");
        approvedAIModels[aiModelId] = AIModel(name, costPerGeneration, isActive);
        emit ApprovedAIModelSet(aiModelId, name, costPerGeneration, isActive);
    }

    // VI. Prompt Submission & AI Generation

    /// @notice Users submit a text prompt, pay a fee, stake tokens, and specify an AI model to generate art.
    /// @param prompt The text prompt for AI generation.
    /// @param aiModelId The identifier of the desired AI model to use.
    /// @param stake The amount of tokens to stake with the prompt (can be 0).
    function submitPromptForGeneration(
        string calldata prompt,
        bytes32 aiModelId,
        uint256 stake
    ) external payable whenNotPaused {
        require(msg.value == promptSubmissionFee + stake, "AetherCanvas: Incorrect ETH sent for submission and stake");
        require(bytes(prompt).length > 0, "AetherCanvas: Prompt cannot be empty");
        require(approvedAIModels[aiModelId].isActive, "AetherCanvas: Specified AI model is not approved or active");

        uint256 currentPromptId = nextPromptRequestId++;
        promptRequests[currentPromptId] = PromptRequest({
            submitter: msg.sender,
            promptText: prompt,
            aiModelId: aiModelId,
            submissionFee: promptSubmissionFee,
            stakeAmount: stake,
            status: PromptStatus.Pending,
            contentHash: bytes32(0),
            timestamp: uint48(block.timestamp),
            tokenId: 0
        });

        // Funds go to contract for now, will be distributed/returned later
        earnings[address(this)] = earnings[address(this)].add(promptSubmissionFee); // Platform fee
        earnings[msg.sender] = earnings[msg.sender].add(stake); // User's stake is held

        emit PromptSubmitted(currentPromptId, msg.sender, prompt, aiModelId, promptSubmissionFee, stake);
    }

    /// @notice **(Oracle-only function)** Called by the trusted oracle to confirm AI generation and provide the artwork's content hash.
    /// @param promptId The ID of the prompt request.
    /// @param contentHash The cryptographic hash of the AI-generated artwork (e.g., IPFS hash).
    /// @param tokenURI The URI pointing to the artwork's metadata (e.g., IPFS link to JSON).
    function processGeneratedArtworkHash(
        uint256 promptId,
        bytes32 contentHash,
        string calldata tokenURI
    ) external onlyOracle whenNotPaused {
        PromptRequest storage req = promptRequests[promptId];
        require(req.submitter != address(0), "AetherCanvas: Prompt request not found");
        require(req.status == PromptStatus.Pending, "AetherCanvas: Prompt not in pending status");
        require(contentHash != bytes32(0), "AetherCanvas: Content hash cannot be zero");
        require(bytes(tokenURI).length > 0, "AetherCanvas: Token URI cannot be empty");

        req.status = PromptStatus.Generated;
        req.contentHash = contentHash;
        _setTokenURI(promptId, tokenURI); // Using promptId as a temporary tokenId placeholder for URI before minting

        emit ArtworkGenerated(promptId, contentHash);
    }

    /// @notice Allows a user to claim back their prompt stake after successful generation.
    /// @param promptId The ID of the prompt request.
    function claimPromptStake(uint256 promptId) external whenNotPaused {
        PromptRequest storage req = promptRequests[promptId];
        require(req.submitter == msg.sender, "AetherCanvas: Not the submitter of this prompt");
        require(req.status == PromptStatus.Generated || req.status == PromptStatus.Minted, "AetherCanvas: Artwork not generated or already claimed/minted");
        require(req.stakeAmount > 0, "AetherCanvas: No stake to claim");

        uint256 amountToClaim = req.stakeAmount;
        req.stakeAmount = 0; // Prevent double claim

        earnings[msg.sender] = earnings[msg.sender].add(amountToClaim); // Move stake from temp holding to earnings
        emit PromptStakeClaimed(promptId, msg.sender, amountToClaim);
    }

    /// @notice Enables a user to cancel an unprocessed prompt request and receive a refund.
    /// @param promptId The ID of the prompt request.
    function cancelPromptRequest(uint256 promptId) external whenNotPaused {
        PromptRequest storage req = promptRequests[promptId];
        require(req.submitter == msg.sender, "AetherCanvas: Not the submitter of this prompt");
        require(req.status == PromptStatus.Pending, "AetherCanvas: Only pending prompts can be cancelled");

        req.status = PromptStatus.Cancelled;

        // Refund submission fee and stake
        earnings[address(this)] = earnings[address(this)].sub(req.submissionFee); // Refund platform fee
        earnings[msg.sender] = earnings[msg.sender].add(req.submissionFee).add(req.stakeAmount); // Refund submitter
        req.submissionFee = 0;
        req.stakeAmount = 0;

        emit PromptCancelled(promptId, msg.sender);
    }

    // VII. NFT Minting & Core ERC721 Functions

    /// @notice Mints the AI-generated artwork as an ERC-721 NFT for the prompt submitter.
    /// @param promptId The ID of the prompt request to mint.
    function mintGeneratedArtworkNFT(uint256 promptId) external whenNotPaused {
        PromptRequest storage req = promptRequests[promptId];
        require(req.submitter == msg.sender, "AetherCanvas: Only prompt submitter can mint this NFT");
        require(req.status == PromptStatus.Generated, "AetherCanvas: Artwork must be generated to be minted");

        uint256 tokenId = req.tokenId > 0 ? req.tokenId : promptId; // Re-use promptId as tokenId if not set
        require(nftCreator[tokenId] == address(0), "AetherCanvas: NFT already minted for this prompt");

        _mint(msg.sender, tokenId);
        nftCreator[tokenId] = msg.sender; // Record the original creator
        req.status = PromptStatus.Minted;
        req.tokenId = tokenId; // Link prompt request to minted tokenId

        // TokenURI was set during artwork generation, if not, it should be set here.
        // As per ERC721, tokenURI is linked to tokenId. We set it with promptId as a placeholder.
        // It's fine to leave it, as promptId is usually equal to tokenId here.

        emit NFTMinted(tokenId, msg.sender, promptId, req.contentHash);
    }

    /// @notice (ERC-2981) Sets the original creator's royalty percentage for future NFT resales.
    /// @param tokenId The ID of the NFT.
    /// @param royaltyRateBps The royalty percentage in basis points (e.g., 500 for 5%). Max 10000.
    function setNFTCreatorRoyaltyInfo(uint256 tokenId, uint16 royaltyRateBps) external whenNotPaused {
        require(nftCreator[tokenId] == msg.sender, "AetherCanvas: Only the original creator can set royalty info");
        require(_exists(tokenId), "AetherCanvas: NFT does not exist");
        require(royaltyRateBps <= 10000, "AetherCanvas: Royalty rate cannot exceed 100%");

        _setTokenRoyalty(tokenId, nftCreator[tokenId], royaltyRateBps);
        emit NFTCreatorRoyaltySet(tokenId, nftCreator[tokenId], royaltyRateBps);
    }

    // Standard ERC721 overrides (required for OpenZeppelin)
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721, ERC2981) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // VIII. Advanced Licensing System

    /// @notice An NFT creator defines a reusable, named license template with default terms.
    /// @param name The name of the license template (e.g., "Personal Use," "Commercial Basic").
    /// @param description A detailed description of the license terms.
    /// @param canBeResold If an instance of this license can be resold by its purchaser.
    /// @param canBeUsedCommercially If the NFT under this license can be used for commercial purposes.
    /// @param allowsDerivativeWorks If the NFT under this license permits the creation of derivative works.
    /// @param royaltyRateForLicenseResaleBps The royalty for reselling THIS license instance (not the NFT).
    /// @param suggestedInitialPrice A non-binding suggested price for this license template.
    function defineLicenseTemplate(
        string calldata name,
        string calldata description,
        bool canBeResold,
        bool canBeUsedCommercially,
        bool allowsDerivativeWorks,
        uint16 royaltyRateForLicenseResaleBps,
        uint256 suggestedInitialPrice
    ) external whenNotPaused returns (uint256) {
        require(bytes(name).length > 0, "AetherCanvas: License template name cannot be empty");
        require(royaltyRateForLicenseResaleBps <= 10000, "AetherCanvas: License resale royalty rate cannot exceed 100%");

        uint256 templateId = nextLicenseTemplateId++;
        licenseTemplates[templateId] = LicenseTemplate({
            name: name,
            description: description,
            canBeResold: canBeResold,
            canBeUsedCommercially: canBeUsedCommercially,
            allowsDerivativeWorks: allowsDerivativeWorks,
            royaltyRateForLicenseResaleBps: royaltyRateForLicenseResaleBps,
            suggestedInitialPrice: suggestedInitialPrice,
            creator: msg.sender,
            isActive: true
        });

        emit LicenseTemplateDefined(templateId, msg.sender, name);
        return templateId;
    }

    /// @notice NFT creator or current owner attaches an instance of a license template to their NFT, setting specific terms.
    /// @param nftId The ID of the NFT to attach the license to.
    /// @param licenseTemplateId The ID of the predefined license template.
    /// @param price The actual price for this specific license instance.
    /// @param duration The duration of the license in seconds (0 for perpetual).
    /// @param customRoyaltyRateForLicenseResaleBps Optional custom royalty rate for reselling THIS license. 0 to use template default.
    function attachLicenseToNFT(
        uint256 nftId,
        uint256 licenseTemplateId,
        uint256 price,
        uint48 duration,
        uint16 customRoyaltyRateForLicenseResaleBps
    ) external whenNotPaused returns (uint256) {
        require(_exists(nftId), "AetherCanvas: NFT does not exist");
        require(ownerOf(nftId) == msg.sender, "AetherCanvas: Only NFT owner can attach licenses");
        LicenseTemplate storage template = licenseTemplates[licenseTemplateId];
        require(template.isActive, "AetherCanvas: License template is not active");
        require(customRoyaltyRateForLicenseResaleBps <= 10000, "AetherCanvas: Custom license resale royalty rate cannot exceed 100%");

        uint256 instanceId = nextLicenseInstanceId++;
        licenseInstances[instanceId] = LicenseInstance({
            licenseTemplateId: licenseTemplateId,
            nftId: nftId,
            ownerAddress: msg.sender,
            price: price,
            duration: duration,
            purchaserAddress: address(0),
            purchaseTimestamp: 0,
            isActive: true,
            customRoyaltyRateForLicenseResaleBps: customRoyaltyRateForLicenseResaleBps,
            creatorRoyaltyShare: 0
        });
        nftToLicenseInstances[nftId].push(instanceId);

        emit LicenseInstanceAttached(instanceId, nftId, msg.sender, price, duration);
        return instanceId;
    }

    /// @notice Allows the NFT owner to revoke an unpurchased license instance they previously attached to an NFT.
    /// @param licenseInstanceId The ID of the license instance to revoke.
    function revokeLicenseInstance(uint256 licenseInstanceId) external whenNotPaused {
        LicenseInstance storage instance = licenseInstances[licenseInstanceId];
        require(instance.ownerAddress == msg.sender, "AetherCanvas: Only the license instance owner can revoke");
        require(instance.purchaserAddress == address(0), "AetherCanvas: Cannot revoke a purchased license");
        require(instance.isActive, "AetherCanvas: License instance is not active");

        instance.isActive = false; // Mark as inactive
        // We don't remove from nftToLicenseInstances to maintain historical data if needed, just mark as inactive.
        emit LicenseInstanceRevoked(licenseInstanceId, instance.nftId, msg.sender);
    }

    /// @notice A user purchases a specific license instance for an NFT.
    /// @param licenseInstanceId The ID of the license instance to purchase.
    function purchaseLicenseInstance(uint256 licenseInstanceId) external payable whenNotPaused {
        LicenseInstance storage instance = licenseInstances[licenseInstanceId];
        require(instance.isActive, "AetherCanvas: License instance is not active or available");
        require(instance.purchaserAddress == address(0), "AetherCanvas: License already purchased");
        require(msg.value == instance.price, "AetherCanvas: Incorrect price sent");
        require(instance.ownerAddress != msg.sender, "AetherCanvas: Cannot purchase your own license instance");

        // Calculate platform fee
        uint256 platformFee = instance.price.mul(platformRoyaltyRateBps).div(10000);
        uint256 netToSeller = instance.price.sub(platformFee);

        earnings[instance.ownerAddress] = earnings[instance.ownerAddress].add(netToSeller);
        earnings[address(this)] = earnings[address(this)].add(platformFee);

        instance.purchaserAddress = msg.sender;
        instance.purchaseTimestamp = uint48(block.timestamp);

        emit LicenseInstancePurchased(licenseInstanceId, instance.nftId, msg.sender, instance.price);
    }

    /// @notice Checks if an address holds a valid, active license for a given NFT for a particular intended usage type.
    /// @param user The address to check for license validity.
    /// @param nftId The ID of the NFT.
    /// @param usageType The specific usage right to verify (e.g., Commercial, Derivative).
    /// @return True if the user has a valid license for the specified usage type, false otherwise.
    function verifyLicenseUse(
        address user,
        uint256 nftId,
        UsageType usageType
    ) public view returns (bool) {
        require(user != address(0), "AetherCanvas: Invalid user address");
        require(_exists(nftId), "AetherCanvas: NFT does not exist");

        // If the user is the original creator, they inherently have all rights.
        if (nftCreator[nftId] == user) {
            return true;
        }

        // Iterate through all attached license instances for this NFT
        for (uint256 i = 0; i < nftToLicenseInstances[nftId].length; i++) {
            uint256 instanceId = nftToLicenseInstances[nftId][i];
            LicenseInstance storage instance = licenseInstances[instanceId];

            // Only consider active and purchased licenses
            if (instance.isActive && instance.purchaserAddress == user) {
                // Check duration if not perpetual
                if (instance.duration > 0 && block.timestamp > instance.purchaseTimestamp + instance.duration) {
                    continue; // License expired
                }

                LicenseTemplate storage template = licenseTemplates[instance.licenseTemplateId];

                // Check specific usage type
                if (usageType == UsageType.Commercial && template.canBeUsedCommercially) return true;
                if (usageType == UsageType.Derivative && template.allowsDerivativeWorks) return true;
                if (usageType == UsageType.Resale && template.canBeResold) return true;
                if (usageType == UsageType.Personal) return true; // Personal use is generally covered by any valid license
            }
        }
        return false;
    }

    // IX. Marketplace Functionality

    /// @notice An NFT owner lists their NFT for direct sale at a fixed price.
    /// @param nftId The ID of the NFT to list.
    /// @param price The fixed price for the NFT.
    function listNFTForFixedPriceSale(uint256 nftId, uint256 price) external whenNotPaused {
        require(_exists(nftId), "AetherCanvas: NFT does not exist");
        require(ownerOf(nftId) == msg.sender, "AetherCanvas: Only NFT owner can list for sale");
        require(price > 0, "AetherCanvas: Price must be greater than zero");
        require(nftListings[nftId].seller == address(0), "AetherCanvas: NFT already listed");

        // Approve this contract to manage the NFT for sale
        _approve(address(this), nftId);

        nftListings[nftId] = NFTListing({
            nftId: nftId,
            seller: msg.sender,
            price: price,
            isActive: true
        });

        emit NFTListedForSale(nftId, msg.sender, price);
    }

    /// @notice A user purchases a listed NFT, triggering royalty and platform fee distribution.
    /// @param nftId The ID of the NFT to purchase.
    function buyNFT(uint256 nftId) external payable whenNotPaused {
        NFTListing storage listing = nftListings[nftId];
        require(listing.isActive, "AetherCanvas: NFT is not listed for sale or already sold");
        require(listing.seller != address(0), "AetherCanvas: NFT is not listed for sale");
        require(msg.value == listing.price, "AetherCanvas: Incorrect ETH sent");
        require(listing.seller != msg.sender, "AetherCanvas: Cannot buy your own NFT listing");

        listing.isActive = false; // Mark as sold

        // Handle ERC-2981 royalties for the original creator
        (address royaltyReceiver, uint256 royaltyAmount) = royaltyInfo(nftId, listing.price);

        // Calculate platform fee
        uint256 platformFee = listing.price.mul(platformRoyaltyRateBps).div(10000);
        
        // Ensure royalty and platform fee don't exceed purchase price
        uint256 totalFees = royaltyAmount.add(platformFee);
        if (totalFees > listing.price) {
            // Adjust fees proportionally or cap to price to prevent negative seller earnings
            platformFee = platformFee.mul(listing.price).div(totalFees);
            royaltyAmount = royaltyAmount.mul(listing.price).div(totalFees);
        }

        uint256 netToSeller = listing.price.sub(royaltyAmount).sub(platformFee);

        // Distribute funds
        if (royaltyAmount > 0) {
            earnings[royaltyReceiver] = earnings[royaltyReceiver].add(royaltyAmount);
        }
        earnings[listing.seller] = earnings[listing.seller].add(netToSeller);
        earnings[address(this)] = earnings[address(this)].add(platformFee);

        // Transfer NFT ownership
        _transfer(listing.seller, msg.sender, nftId);

        emit NFTPurchased(nftId, msg.sender, listing.seller, listing.price);
    }

    // X. Earnings & Withdrawals

    /// @notice Allows any user (creators, NFT sellers, license sellers) to withdraw their accumulated earnings.
    function withdrawEarnings() external whenNotPaused {
        uint256 amount = earnings[msg.sender];
        require(amount > 0, "AetherCanvas: No earnings to withdraw");

        earnings[msg.sender] = 0; // Reset earnings before transfer
        payable(msg.sender).transfer(amount);
        emit EarningsWithdrawn(msg.sender, amount);
    }

    // XI. Public View Functions (Getters)

    /// @notice Retrieves details of a prompt submission.
    /// @param promptId The ID of the prompt request.
    /// @return A tuple containing all PromptRequest details.
    function getPromptRequest(uint256 promptId)
        public
        view
        returns (
            address submitter,
            string memory promptText,
            bytes32 aiModelId,
            uint256 submissionFee,
            uint256 stakeAmount,
            PromptStatus status,
            bytes32 contentHash,
            uint48 timestamp,
            uint256 tokenId
        )
    {
        PromptRequest storage req = promptRequests[promptId];
        return (
            req.submitter,
            req.promptText,
            req.aiModelId,
            req.submissionFee,
            req.stakeAmount,
            req.status,
            req.contentHash,
            req.timestamp,
            req.tokenId
        );
    }

    /// @notice Retrieves details of a defined license template.
    /// @param templateId The ID of the license template.
    /// @return A tuple containing all LicenseTemplate details.
    function getLicenseTemplate(uint256 templateId)
        public
        view
        returns (
            string memory name,
            string memory description,
            bool canBeResold,
            bool canBeUsedCommercially,
            bool allowsDerivativeWorks,
            uint16 royaltyRateForLicenseResaleBps,
            uint256 suggestedInitialPrice,
            address creator,
            bool isActive
        )
    {
        LicenseTemplate storage template = licenseTemplates[templateId];
        return (
            template.name,
            template.description,
            template.canBeResold,
            template.canBeUsedCommercially,
            template.allowsDerivativeWorks,
            template.royaltyRateForLicenseResaleBps,
            template.suggestedInitialPrice,
            template.creator,
            template.isActive
        );
    }

    /// @notice Retrieves details of an attached license instance.
    /// @param instanceId The ID of the license instance.
    /// @return A tuple containing all LicenseInstance details.
    function getLicenseInstance(uint256 instanceId)
        public
        view
        returns (
            uint256 licenseTemplateId,
            uint256 nftId,
            address ownerAddress,
            uint256 price,
            uint48 duration,
            address purchaserAddress,
            uint48 purchaseTimestamp,
            bool isActive,
            uint16 customRoyaltyRateForLicenseResaleBps,
            uint256 creatorRoyaltyShare
        )
    {
        LicenseInstance storage instance = licenseInstances[instanceId];
        return (
            instance.licenseTemplateId,
            instance.nftId,
            instance.ownerAddress,
            instance.price,
            instance.duration,
            instance.purchaserAddress,
            instance.purchaseTimestamp,
            instance.isActive,
            instance.customRoyaltyRateForLicenseResaleBps,
            instance.creatorRoyaltyShare
        );
    }

    /// @notice Returns the array of license instance IDs attached to a given NFT.
    /// @param nftId The ID of the NFT.
    /// @return An array of `licenseInstanceId`s.
    function getNFTLicenseInstances(uint256 nftId) public view returns (uint256[] memory) {
        return nftToLicenseInstances[nftId];
    }

    /// @notice Retrieves details of an approved AI model.
    /// @param aiModelId The ID of the AI model.
    /// @return A tuple containing the AI model's name, cost per generation, and active status.
    function getApprovedAIModel(bytes32 aiModelId)
        public
        view
        returns (
            string memory name,
            uint256 costPerGeneration,
            bool isActive
        )
    {
        AIModel storage model = approvedAIModels[aiModelId];
        return (model.name, model.costPerGeneration, model.isActive);
    }
}
```