Here's a Solidity smart contract named "EtherealEchoes" that encapsulates several interesting, advanced, creative, and trendy concepts, aiming to avoid direct duplication of existing open-source projects by combining unique functionalities. It includes over 20 functions as requested.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol"; // For safe transfers

/**
 * @title EtherealEchoes: AI-Assisted Generative Art, Dynamic Royalties, Social-Fi & DAO Governance
 * @dev This contract orchestrates a decentralized platform for generative AI art NFTs.
 *      It integrates off-chain AI generation via an oracle, implements a novel dynamic royalty system
 *      based on configurable rules, fosters community curation and tipping, and is governed by a DAO.
 */

// Outline:
// I. NFT Core (ERC721 & AI Integration)
//    - Manages the lifecycle of generative AI art NFTs.
//    - Facilitates requests for off-chain AI art generation.
//    - Defines and manages ERC1155 "AI Parameter Packs" to unlock specific generative styles.
// II. Dynamic Royalty System
//    - Implements flexible royalty rates that adjust based on defined, on-chain rules (e.g., sales count, time).
//    - Ensures proper distribution of proceeds during primary and secondary sales.
// III. Social & Curation Layer
//    - Allows community members to curate (score) artworks.
//    - Enables direct tipping of original artists.
//    - Provides functionality for creators to register profiles and earn reputation.
// IV. DAO Governance
//    - Facilitates decentralized decision-making through a proposal and voting mechanism.
//    - Allows for community-driven changes to contract parameters, royalty rules, and treasury management.
// V. Treasury Management
//    - Collects platform fees and proceeds from sales.
//    - Enables DAO-controlled withdrawal of funds.
// VI. Access Control & Utilities
//    - Standard administrative functions (pausing, oracle management, upgrades).

// Function Summary:
// I. NFT Core (ERC721 & AI Integration)
// 1.  `configureAIGeneratorParams(string calldata _settingsJson, uint256 _costEth, address _erc20Token, uint256 _costERC20)`:
//     Sets the base parameters and costs (ETH/ERC20) for AI art generation requests. (DAO-governed)
// 2.  `requestGenerativeArt(string calldata _promptHash, uint256 _generationOptionId, uint256 _packIdUsed)`:
//     Initiates a request for AI art generation, paying the associated cost. Requires a prompt hash (for off-chain prompt retrieval) and an optional AI parameter pack ID.
// 3.  `fulfillArtGenerationAndMint(uint256 _requestId, string calldata _tokenURI, bytes32 _artworkHash, address _recipient)`:
//     Callable only by the designated oracle, this function finalizes an AI art request by minting the NFT and assigning it to the recipient.
// 4.  `getGenerationRequestStatus(uint256 _requestId)`:
//     Retrieves the current status and details of a specific AI art generation request.
// 5.  `setAIParameterPack(uint256 _packId, string calldata _metadataURI, uint256 _price, uint256 _maxSupply)`:
//     Defines an ERC1155 AI parameter pack, specifying its metadata, price, and maximum supply. (DAO-governed)
// 6.  `purchaseAIParameterPack(uint256 _packId)`:
//     Allows users to buy an AI parameter pack, receiving an ERC1155 token that unlocks specific generative styles or features.
// 7.  `getAIParameterPackDetails(uint256 _packId)`:
//     Retrieves the details of a specific AI parameter pack.
// 8.  `getTotalGeneratedArtworks()`:
//     Returns the total number of generative art NFTs minted on the platform.

// II. Dynamic Royalty System
// 9.  `setGlobalBaseRoyaltyRate(uint256 _newRatePermyriad)`:
//     Sets the baseline royalty percentage (permyriad, 10000 = 100%) for all NFT sales. (DAO-governed)
// 10. `defineDynamicRoyaltyRule(bytes32 _ruleId, uint256 _ruleType, uint256 _threshold, int256 _adjustmentPermyriad, uint256 _durationBlocks, bool _active)`:
//     Creates or updates a dynamic royalty rule that modifies the base royalty. Rule types can be based on sales count, time, or other metrics. (DAO-governed)
// 11. `getNFTCurrentDynamicRoyalty(uint256 _tokenId)`:
//     Calculates and returns the current effective royalty rate for a given NFT, considering its history and all active dynamic royalty rules.
// 12. `processNFTPrimarySale(uint256 _tokenId, uint256 _salePrice)`:
//     Handles the initial sale of a newly minted NFT. Collects platform fees and distributes proceeds to the artist.
// 13. `processNFTResale(uint256 _tokenId, uint256 _salePrice)`:
//     Facilitates secondary market sales of NFTs. Calculates and distributes dynamic royalties to the original artist and platform, and sends remaining funds to the seller.

// III. Social & Curation Layer
// 14. `curateArtwork(uint256 _tokenId, uint256 _score)`:
//     Allows users to assign a "curation score" to an artwork, influencing its visibility or reputation.
// 15. `tipArtist(uint256 _tokenId)`:
//     Enables users to send Ether tips directly to the original artist of an NFT.
// 16. `registerCreatorProfile(string calldata _profileURI)`:
//     Allows creators to associate a public profile URI (e.g., IPFS link to metadata) with their address.
// 17. `awardReputationPoints(address _user, uint256 _points)`:
//     DAO/Admin function to reward users for positive contributions (e.g., good curation, community participation) with reputation points.

// IV. DAO Governance
// 18. `proposeConfigurationChange(bytes32 _proposalId, uint256 _proposalType, bytes calldata _payload)`:
//     Initiates a DAO proposal to alter contract parameters, royalty rules, or other core settings.
// 19. `voteOnProposal(bytes32 _proposalId, bool _support)`:
//     Allows designated voters (e.g., reputation point holders, governance token holders) to cast their vote on an active proposal.
// 20. `executeProposal(bytes32 _proposalId)`:
//     Executes a successfully passed DAO proposal, applying the proposed changes to the contract.

// V. Treasury Management
// 21. `withdrawTreasuryFunds(address _recipient, uint256 _amount)`:
//     Allows DAO-approved withdrawal of accumulated platform fees and treasury funds to a specified recipient.

// VI. Access Control & Utilities
// 22. `setOracleAddress(address _newOracle)`:
//     Configures the trusted oracle address responsible for fulfilling AI generation requests. (DAO-governed)
// 23. `setFeeRecipient(address _newRecipient)`:
//     Sets the address where platform fees are directed. (DAO-governed)
// 24. `pauseContract()`:
//     Pauses critical contract functions (e.g., new requests, sales) in emergencies. (DAO-governed)
// 25. `unpauseContract()`:
//     Unpauses the contract after an emergency. (DAO-governed)
// 26. `_migrateToNewContract(address _newImplementation)`:
//     An internal future-proofing function for controlled contract upgrades (exposed via DAO proposal).

contract EtherealEchoes is ERC721Burnable, ERC1155, Ownable, Pausable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using SafeERC20 for IERC20;

    // --- Events ---
    event AIGeneratorParamsConfigured(string settingsJson, uint256 costEth, address erc20Token, uint256 costERC20);
    event ArtGenerationRequested(uint256 requestId, address indexed requester, string promptHash, uint256 generationOptionId, uint256 packIdUsed, uint256 costPaid);
    event ArtGenerationFulfilled(uint256 requestId, uint256 tokenId, address indexed recipient, string tokenURI);
    event AIParameterPackDefined(uint256 packId, string metadataURI, uint256 price, uint256 maxSupply);
    event AIParameterPackPurchased(address indexed buyer, uint256 packId, uint256 amount);
    event GlobalBaseRoyaltyRateSet(uint256 newRatePermyriad);
    event DynamicRoyaltyRuleDefined(bytes32 ruleId, uint256 ruleType, uint256 threshold, int256 adjustmentPermyriad, uint256 durationBlocks, bool active);
    event NFTPrimarySale(uint256 indexed tokenId, address indexed buyer, address indexed artist, uint256 salePrice, uint256 platformFee);
    event NFTResale(uint256 indexed tokenId, address indexed seller, address indexed buyer, uint256 salePrice, uint256 royaltyAmount, uint256 platformFee);
    event ArtworkCurated(uint256 indexed tokenId, address indexed curator, uint256 score);
    event ArtistTipped(uint256 indexed tokenId, address indexed tipper, address indexed artist, uint256 amount);
    event CreatorProfileRegistered(address indexed creator, string profileURI);
    event ReputationPointsAwarded(address indexed user, uint256 points);
    event ProposalCreated(bytes32 proposalId, uint256 proposalType, bytes payload, address indexed proposer);
    event VoteCast(bytes32 proposalId, address indexed voter, bool support);
    event ProposalExecuted(bytes32 proposalId);
    event TreasuryFundsWithdrawn(address indexed recipient, uint256 amount);
    event OracleAddressSet(address newOracle);
    event FeeRecipientSet(address newRecipient);
    event ContractMigrated(address newImplementation);

    // --- State Variables ---
    Counters.Counter private _tokenIdCounter; // For ERC721 NFTs
    Counters.Counter private _requestIdCounter; // For AI generation requests
    uint256 public constant PERMYRIAD_BASE = 10000; // Represents 100% (e.g., 500 = 5%)

    // AI Generation Configuration
    struct AIGenConfig {
        string settingsJson; // JSON string for off-chain AI parameters
        uint256 costEth;     // Cost in native Ether (wei)
        address erc20Token;  // Address of an optional ERC20 token for payment
        uint256 costERC20;   // Cost in the specified ERC20 token
    }
    AIGenConfig public aiGenConfig;
    address public oracleAddress; // Address of the trusted off-chain oracle that fulfills requests

    // AI Generation Requests
    enum RequestStatus { Pending, Fulfilled, Failed }
    struct GenerationRequest {
        address requester;
        string promptHash; // Hash of the user's prompt (actual prompt is off-chain)
        uint256 generationOptionId; // Specific AI model/option ID
        uint256 packIdUsed; // ID of the ERC1155 AI Parameter Pack used
        uint256 costPaid; // Total cost paid for the request (simplistic for example)
        RequestStatus status;
        uint256 tokenId; // Populated once fulfilled with the minted NFT ID
        address originalArtist; // The address that initiated the request and will be the original artist
    }
    mapping(uint256 => GenerationRequest) public generationRequests;

    // AI Parameter Packs (ERC1155)
    struct AIParameterPack {
        string metadataURI; // URI for the ERC1155 token's metadata
        uint256 price;      // Price in ETH to purchase one unit of this pack
        uint256 maxSupply;  // Maximum number of units that can be minted
        uint256 currentSupply; // Current number of units minted
        bool exists;
    }
    mapping(uint256 => AIParameterPack) public aiParameterPacks; // _packId -> AIParameterPack details

    // NFT Metadata & History
    mapping(uint256 => address) public originalArtists; // ERC721 tokenId -> original artist (who requested AI gen)
    mapping(uint256 => uint256) public nftSalesCount; // ERC721 tokenId -> number of times it has been sold
    mapping(uint256 => uint256) public nftLastSaleBlock; // ERC721 tokenId -> block number of last sale
    mapping(uint256 => uint256) public nftCurationScore; // ERC721 tokenId -> aggregated curation score from users

    // Dynamic Royalty System
    uint256 public globalBaseRoyaltyRatePermyriad; // e.g., 500 = 5% (applied as platform fee for simplicity)

    enum RuleType {
        SalesCount,          // Royalty adjusts based on number of sales
        TimeSinceMint,       // Royalty adjusts based on time since NFT was minted/last sold
        CurationScoreThreshold // Royalty adjusts based on the NFT's curation score
    }

    struct DynamicRoyaltyRule {
        RuleType ruleType;
        uint256 threshold; // Value at which the rule applies (e.g., 5 sales, 1000 blocks, score of 75)
        int256 adjustmentPermyriad; // Amount to add/subtract from the current royalty rate (+/- permyriad)
        uint256 durationBlocks; // How long the adjustment applies (0 for permanent)
        bool active;
    }
    mapping(bytes32 => DynamicRoyaltyRule) public dynamicRoyaltyRules;
    bytes32[] public activeRoyaltyRuleIds; // A list to iterate through active rules efficiently

    // Social & Curation
    mapping(address => string) public creatorProfiles; // Creator's address -> IPFS/HTTP URI for their profile metadata
    mapping(address => uint256) public reputationPoints; // User's address -> accumulated reputation points

    // DAO Governance
    uint256 public constant MIN_VOTES_FOR_PROPOSAL = 3; // Example: Minimum 'for' votes required to pass a proposal
    uint256 public constant VOTING_PERIOD_BLOCKS = 100; // Example: Voting period duration in blocks (~20-25 mins at 12s/block)

    enum ProposalType {
        ConfigureAIGenParams,
        SetGlobalBaseRoyaltyRate,
        DefineDynamicRoyaltyRule,
        SetAIParameterPack,
        SetOracleAddress,
        SetFeeRecipient,
        PauseContract,
        UnpauseContract,
        WithdrawTreasuryFunds,
        AwardReputationPoints,
        MigrateContract
    }

    struct Proposal {
        ProposalType proposalType;
        bytes payload; // ABI-encoded function call data for execution
        uint256 startBlock;
        uint256 endBlock;
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted; // Tracks who has voted
        bool executed;
        bool exists;
    }
    mapping(bytes32 => Proposal) public proposals;
    bytes32[] public activeProposals; // List of active proposals for easier management

    address public feeRecipient; // Address to receive platform fees

    // --- Constructor ---
    constructor(
        address _initialOracle,
        address _initialFeeRecipient,
        uint256 _initialBaseRoyaltyRatePermyriad
    ) ERC721("Ethereal Echoes NFT", "EEART") ERC1155("") Ownable(msg.sender) { // ERC1155 _uri is set later with AI packs
        require(_initialOracle != address(0), "Invalid oracle address");
        require(_initialFeeRecipient != address(0), "Invalid fee recipient address");

        oracleAddress = _initialOracle;
        feeRecipient = _initialFeeRecipient;
        globalBaseRoyaltyRatePermyriad = _initialBaseRoyaltyRatePermyriad; // e.g. 500 for 5%

        // Initialize with a default, empty AI Generator configuration
        aiGenConfig = AIGenConfig({
            settingsJson: "{}",
            costEth: 0,
            erc20Token: address(0),
            costERC20: 0
        });

        // The deployer of the contract becomes the initial owner.
        // In a real DAO, this ownership would typically be transferred to the DAO's governance contract.
    }

    // --- Modifiers ---
    modifier onlyOracle() {
        require(msg.sender == oracleAddress, "Caller is not the oracle");
        _;
    }

    // For simplicity, DAO-governed functions are restricted to the contract owner.
    // In a full DAO setup, `owner()` would be a DAO contract, which would then vote
    // to execute these actions.
    modifier onlyDAOManager() {
        require(owner() == msg.sender, "Caller is not the DAO manager");
        _;
    }

    // --- Fallback & Receive ---
    receive() external payable {} // Allows contract to receive Ether
    fallback() external payable {} // Catches calls to undefined functions, allows receiving Ether

    // --- I. NFT Core (ERC721 & AI Integration) ---

    /**
     * @dev Configures the parameters and costs for AI art generation requests.
     * @param _settingsJson A JSON string containing specific AI generation parameters (e.g., style, quality presets).
     * @param _costEth The cost in native Ether (wei) for a generation request.
     * @param _erc20Token The address of an ERC20 token that can be used for payment.
     * @param _costERC20 The cost in the specified ERC20 token (in its smallest unit) for a generation request.
     * Callable by DAO Manager.
     */
    function configureAIGeneratorParams(
        string calldata _settingsJson,
        uint256 _costEth,
        address _erc20Token,
        uint256 _costERC20
    ) external onlyDAOManager {
        aiGenConfig = AIGenConfig({
            settingsJson: _settingsJson,
            costEth: _costEth,
            erc20Token: _erc20Token,
            costERC20: _costERC20
        });
        emit AIGeneratorParamsConfigured(_settingsJson, _costEth, _erc20Token, _costERC20);
    }

    /**
     * @dev Initiates a request for off-chain AI art generation.
     * @param _promptHash A hash of the user's prompt (actual prompt is stored off-chain, e.g., IPFS).
     * @param _generationOptionId An ID representing a specific AI generation model/option.
     * @param _packIdUsed The ID of an ERC1155 AI Parameter Pack token used, if any, to unlock specific features.
     * Requires payment in ETH or ERC20 as configured.
     */
    function requestGenerativeArt(
        string calldata _promptHash,
        uint256 _generationOptionId,
        uint256 _packIdUsed
    ) external payable nonReentrant whenNotPaused {
        require(bytes(_promptHash).length > 0, "Prompt hash cannot be empty");
        require(aiGenConfig.costEth > 0 || aiGenConfig.costERC20 > 0, "AI generation cost not configured");

        // Handle ETH payment
        if (aiGenConfig.costEth > 0) {
            require(msg.value >= aiGenConfig.costEth, "Insufficient ETH for generation cost");
            if (msg.value > aiGenConfig.costEth) {
                payable(msg.sender).transfer(msg.value - aiGenConfig.costEth); // Refund excess ETH
            }
        } else {
            require(msg.value == 0, "ETH sent when not required");
        }

        // Handle ERC20 payment
        if (aiGenConfig.erc20Token != address(0) && aiGenConfig.costERC20 > 0) {
            IERC20(aiGenConfig.erc20Token).safeTransferFrom(msg.sender, address(this), aiGenConfig.costERC20);
        } else {
             require(aiGenConfig.erc20Token == address(0) || aiGenConfig.costERC20 == 0, "ERC20 payment required but not provided or configured");
        }
        
        // Check for AI Parameter Pack ownership if required
        if (_packIdUsed != 0) {
            require(balanceOf(msg.sender, _packIdUsed) > 0, "Requester does not own required AI Parameter Pack");
            // Future extension: Could burn/consume the pack here if it's single-use.
        }

        uint256 newRequestId = _requestIdCounter.current();
        _requestIdCounter.increment();

        generationRequests[newRequestId] = GenerationRequest({
            requester: msg.sender,
            promptHash: _promptHash,
            generationOptionId: _generationOptionId,
            packIdUsed: _packIdUsed,
            costPaid: aiGenConfig.costEth + aiGenConfig.costERC20, // Simplified cost sum
            status: RequestStatus.Pending,
            tokenId: 0,
            originalArtist: msg.sender
        });

        emit ArtGenerationRequested(newRequestId, msg.sender, _promptHash, _generationOptionId, _packIdUsed, aiGenConfig.costEth + aiGenConfig.costERC20);
    }

    /**
     * @dev Called by the designated oracle to fulfill an AI art generation request and mint the NFT.
     * This function is restricted to the `oracleAddress`.
     * @param _requestId The ID of the original generation request.
     * @param _tokenURI The URI of the generated NFT metadata (e.g., IPFS hash).
     * @param _artworkHash A hash of the generated artwork itself (for off-chain integrity checks).
     * @param _recipient The address to mint the NFT to.
     */
    function fulfillArtGenerationAndMint(
        uint256 _requestId,
        string calldata _tokenURI,
        bytes32 _artworkHash,
        address _recipient
    ) external onlyOracle nonReentrant {
        GenerationRequest storage req = generationRequests[_requestId];
        require(req.status == RequestStatus.Pending, "Request already fulfilled or failed");
        require(bytes(_tokenURI).length > 0, "Token URI cannot be empty");
        require(_recipient != address(0), "Invalid recipient address");

        uint256 newTokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        _safeMint(_recipient, newTokenId); // Mints the ERC721 NFT
        _setTokenURI(newTokenId, _tokenURI); // Sets the ERC721 metadata URI
        originalArtists[newTokenId] = req.originalArtist; // Stores the original artist

        req.status = RequestStatus.Fulfilled;
        req.tokenId = newTokenId;

        emit ArtGenerationFulfilled(_requestId, newTokenId, _recipient, _tokenURI);
    }

    /**
     * @dev Retrieves the current status and details of an AI art generation request.
     * @param _requestId The ID of the request.
     * @return GenerationRequest struct containing all details of the request.
     */
    function getGenerationRequestStatus(uint256 _requestId) public view returns (GenerationRequest memory) {
        return generationRequests[_requestId];
    }

    /**
     * @dev Defines a new AI Parameter Pack (an ERC1155 token).
     * These packs can unlock specific generative styles or features.
     * @param _packId The unique ID for this parameter pack.
     * @param _metadataURI The URI for the ERC1155 metadata for this pack.
     * @param _price The price in ETH to purchase one unit of this pack.
     * @param _maxSupply The maximum number of units of this pack that can be minted.
     * Callable by DAO Manager.
     */
    function setAIParameterPack(
        uint256 _packId,
        string calldata _metadataURI,
        uint256 _price,
        uint256 _maxSupply
    ) external onlyDAOManager {
        require(!aiParameterPacks[_packId].exists, "Pack ID already exists");
        require(bytes(_metadataURI).length > 0, "Metadata URI cannot be empty");
        require(_maxSupply > 0, "Max supply must be greater than 0");

        aiParameterPacks[_packId] = AIParameterPack({
            metadataURI: _metadataURI,
            price: _price,
            maxSupply: _maxSupply,
            currentSupply: 0,
            exists: true
        });
        emit AIParameterPackDefined(_packId, _metadataURI, _price, _maxSupply);
    }

    /**
     * @dev Allows a user to purchase an AI Parameter Pack.
     * Mints an ERC1155 token to the buyer and sends ETH to the fee recipient.
     * @param _packId The ID of the parameter pack to purchase.
     * Requires sending the exact ETH amount specified as the pack's price.
     */
    function purchaseAIParameterPack(uint256 _packId) external payable nonReentrant whenNotPaused {
        AIParameterPack storage pack = aiParameterPacks[_packId];
        require(pack.exists, "Pack does not exist");
        require(pack.currentSupply < pack.maxSupply, "Pack supply exhausted");
        require(msg.value == pack.price, "Incorrect ETH amount sent for pack");

        pack.currentSupply++;
        _mint(msg.sender, _packId, 1, ""); // Mints 1 ERC1155 token to the buyer

        if (msg.value > 0) {
            payable(feeRecipient).transfer(msg.value); // All proceeds from pack sales go to fee recipient
        }

        emit AIParameterPackPurchased(msg.sender, _packId, 1);
    }

    /**
     * @dev Retrieves details about a specific AI parameter pack.
     * @param _packId The ID of the pack.
     * @return AIParameterPack struct containing metadata URI, price, supply info, and existence flag.
     */
    function getAIParameterPackDetails(uint256 _packId) public view returns (AIParameterPack memory) {
        return aiParameterPacks[_packId];
    }

    /**
     * @dev Returns the total number of generative art NFTs minted on the platform.
     * @return Total count of ERC721 NFTs.
     */
    function getTotalGeneratedArtworks() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    // --- II. Dynamic Royalty System ---

    /**
     * @dev Sets the global base royalty rate for all NFT sales. This also serves as the platform fee percentage.
     * @param _newRatePermyriad The new base rate in permyriad (e.g., 500 for 5%). Max 10000 (100%).
     * Callable by DAO Manager.
     */
    function setGlobalBaseRoyaltyRate(uint256 _newRatePermyriad) external onlyDAOManager {
        require(_newRatePermyriad <= PERMYRIAD_BASE, "Royalty rate cannot exceed 100%");
        globalBaseRoyaltyRatePermyriad = _newRatePermyriad;
        emit GlobalBaseRoyaltyRateSet(_newRatePermyriad);
    }

    /**
     * @dev Defines or updates a dynamic royalty rule. These rules modify the base royalty based on conditions.
     * Rules can increase or decrease royalties based on sales count, time since mint/last sale, or curation score.
     * @param _ruleId A unique identifier for the rule.
     * @param _ruleType The type of rule (0=SalesCount, 1=TimeSinceMint, 2=CurationScoreThreshold).
     * @param _threshold The value threshold for the rule to apply (e.g., 5 sales, 1000 blocks, score of 75).
     * @param _adjustmentPermyriad The adjustment to the royalty rate (+/- permyriad).
     * @param _durationBlocks The number of blocks this adjustment is active (0 for permanent).
     * @param _active Whether this rule is currently active.
     * Callable by DAO Manager.
     */
    function defineDynamicRoyaltyRule(
        bytes32 _ruleId,
        uint256 _ruleType, // Corresponds to RuleType enum
        uint256 _threshold,
        int256 _adjustmentPermyriad,
        uint256 _durationBlocks,
        bool _active
    ) external onlyDAOManager {
        require(_ruleType < uint256(RuleType.CurationScoreThreshold) + 1, "Invalid rule type");
        
        bool wasActive = dynamicRoyaltyRules[_ruleId].exists && dynamicRoyaltyRules[_ruleId].active;

        if (!wasActive && _active) {
            activeRoyaltyRuleIds.push(_ruleId); // Add to active list only if new and active
        } else if (wasActive && !_active) {
            // If rule is being deactivated, remove it from activeRoyaltyRuleIds
            for (uint i = 0; i < activeRoyaltyRuleIds.length; i++) {
                if (activeRoyaltyRuleIds[i] == _ruleId) {
                    activeRoyaltyRuleIds[i] = activeRoyaltyRuleIds[activeRoyaltyRuleIds.length - 1];
                    activeRoyaltyRuleIds.pop();
                    break;
                }
            }
        }
        
        dynamicRoyaltyRules[_ruleId] = DynamicRoyaltyRule({
            ruleType: RuleType(_ruleType),
            threshold: _threshold,
            adjustmentPermyriad: _adjustmentPermyriad,
            durationBlocks: _durationBlocks,
            active: _active
        });

        emit DynamicRoyaltyRuleDefined(_ruleId, _ruleType, _threshold, _adjustmentPermyriad, _durationBlocks, _active);
    }

    /**
     * @dev Calculates the current effective royalty rate for a given NFT, considering all active dynamic rules.
     * @param _tokenId The ID of the NFT.
     * @return The effective royalty rate in permyriad.
     */
    function getNFTCurrentDynamicRoyalty(uint256 _tokenId) public view returns (uint256) {
        require(_exists(_tokenId), "ERC721: invalid token ID");

        uint256 currentRoyaltyRate = globalBaseRoyaltyRatePermyriad; // Start with the base rate

        // Apply dynamic rules
        for (uint i = 0; i < activeRoyaltyRuleIds.length; i++) {
            bytes32 ruleId = activeRoyaltyRuleIds[i];
            DynamicRoyaltyRule storage rule = dynamicRoyaltyRules[ruleId];

            if (!rule.active) continue; // Skip inactive rules

            bool applyRule = false;
            if (rule.ruleType == RuleType.SalesCount && nftSalesCount[_tokenId] >= rule.threshold) {
                applyRule = true;
            } else if (rule.ruleType == RuleType.TimeSinceMint) {
                // Approximate "mint block" or "last sale block" for time calculation
                uint256 referenceBlock = (nftLastSaleBlock[_tokenId] != 0) ? nftLastSaleBlock[_tokenId] : block.number;
                if (block.number >= referenceBlock + rule.threshold) {
                    if (rule.durationBlocks == 0 || block.number <= (referenceBlock + rule.threshold + rule.durationBlocks)) {
                        applyRule = true;
                    }
                }
            } else if (rule.ruleType == RuleType.CurationScoreThreshold && nftCurationScore[_tokenId] >= rule.threshold) {
                applyRule = true;
            }

            if (applyRule) {
                // Apply adjustment, ensuring no underflow/overflow and staying within bounds
                if (rule.adjustmentPermyriad < 0) {
                    currentRoyaltyRate = currentRoyaltyRate > uint256(-rule.adjustmentPermyriad)
                        ? currentRoyaltyRate - uint256(-rule.adjustmentPermyriad)
                        : 0; // Cap at 0%
                } else {
                    currentRoyaltyRate += uint256(rule.adjustmentPermyriad);
                }
            }
        }
        
        // Cap royalty at 100% (PERMYRIAD_BASE)
        if (currentRoyaltyRate > PERMYRIAD_BASE) {
            currentRoyaltyRate = PERMYRIAD_BASE;
        }

        return currentRoyaltyRate;
    }

    /**
     * @dev Handles the initial sale of a newly minted NFT.
     * Assumes NFT is already minted to the original artist's address before this call.
     * Buyer sends ETH directly to this function.
     * @param _tokenId The ID of the NFT being sold.
     * @param _salePrice The agreed-upon sale price in wei.
     * Callable by anyone willing to buy, but msg.sender becomes the new owner.
     */
    function processNFTPrimarySale(uint256 _tokenId, uint256 _salePrice) external payable nonReentrant whenNotPaused {
        require(_exists(_tokenId), "ERC721: invalid token ID");
        require(ownerOf(_tokenId) != address(0), "Token has no owner");
        require(msg.value >= _salePrice, "Insufficient ETH for sale price");
        require(ownerOf(_tokenId) == originalArtists[_tokenId], "NFT is not in original artist's wallet for primary sale");

        address artist = originalArtists[_tokenId];
        uint256 platformFee = (_salePrice * globalBaseRoyaltyRatePermyriad) / PERMYRIAD_BASE; // Platform fee
        uint256 artistProceeds = _salePrice - platformFee;

        // Transfer funds
        payable(feeRecipient).transfer(platformFee);
        payable(artist).transfer(artistProceeds);

        // Transfer NFT to buyer
        _safeTransfer(artist, msg.sender, _tokenId);

        // Update NFT sales history
        nftSalesCount[_tokenId]++;
        nftLastSaleBlock[_tokenId] = block.number;

        // Refund any excess ETH to buyer
        if (msg.value > _salePrice) {
            payable(msg.sender).transfer(msg.value - _salePrice);
        }

        emit NFTPrimarySale(_tokenId, msg.sender, artist, _salePrice, platformFee);
    }

    /**
     * @dev Facilitates secondary market sales of NFTs, applying dynamic royalties.
     * The seller must have approved this contract (or a marketplace) to transfer the NFT.
     * Buyer sends ETH directly to this function.
     * @param _tokenId The ID of the NFT being sold.
     * @param _salePrice The agreed-upon sale price in wei.
     * Callable by anyone (typically a marketplace or the buyer after approval).
     */
    function processNFTResale(uint256 _tokenId, uint256 _salePrice) external payable nonReentrant whenNotPaused {
        require(_exists(_tokenId), "ERC721: invalid token ID");
        require(ownerOf(_tokenId) != address(0), "Token has no owner");
        require(msg.value >= _salePrice, "Insufficient ETH for sale price");
        require(ownerOf(_tokenId) != msg.sender, "Seller cannot be buyer in this call"); // Buyer calls this

        address currentSeller = ownerOf(_tokenId);
        address originalCreator = originalArtists[_tokenId];

        uint256 platformFeeAmount = (_salePrice * globalBaseRoyaltyRatePermyriad) / PERMYRIAD_BASE; // Fixed platform fee
        uint256 artistRoyaltyAmount = (_salePrice * getNFTCurrentDynamicRoyalty(_tokenId)) / PERMYRIAD_BASE; // Dynamic artist royalty

        // Ensure total fees/royalties do not exceed sale price
        if (platformFeeAmount + artistRoyaltyAmount > _salePrice) {
            // Prioritize artist royalty, then reduce platform fee if necessary
            if (artistRoyaltyAmount > _salePrice) { // Should not happen if getNFTCurrentDynamicRoyalty caps at 100%
                artistRoyaltyAmount = _salePrice;
                platformFeeAmount = 0;
            } else {
                platformFeeAmount = _salePrice - artistRoyaltyAmount;
            }
        }
        
        uint256 sellerProceeds = _salePrice - artistRoyaltyAmount - platformFeeAmount;

        // Transfer funds
        if (platformFeeAmount > 0) payable(feeRecipient).transfer(platformFeeAmount);
        if (artistRoyaltyAmount > 0) payable(originalCreator).transfer(artistRoyaltyAmount);
        if (sellerProceeds > 0) payable(currentSeller).transfer(sellerProceeds);

        // Transfer NFT to buyer (msg.sender is the buyer)
        _safeTransfer(currentSeller, msg.sender, _tokenId); // Uses ERC721's _safeTransfer

        // Update NFT sales history
        nftSalesCount[_tokenId]++;
        nftLastSaleBlock[_tokenId] = block.number;

        // Refund any excess ETH to buyer
        if (msg.value > _salePrice) {
            payable(msg.sender).transfer(msg.value - _salePrice);
        }

        emit NFTResale(_tokenId, currentSeller, msg.sender, _salePrice, artistRoyaltyAmount, platformFeeAmount);
    }

    // --- III. Social & Curation Layer ---

    /**
     * @dev Allows users to assign a "curation score" to an artwork.
     * This is a simple cumulative sum. For more advanced systems, consider tracking individual
     * scores, averages, or weighting by reputation points.
     * @param _tokenId The ID of the artwork.
     * @param _score The score given (e.g., 0-100).
     */
    function curateArtwork(uint256 _tokenId, uint256 _score) external whenNotPaused {
        require(_exists(_tokenId), "ERC721: invalid token ID");
        require(_score <= 100, "Score must be between 0 and 100"); // Example max score

        nftCurationScore[_tokenId] += _score; // Accumulate scores
        emit ArtworkCurated(_tokenId, msg.sender, _score);
    }

    /**
     * @dev Enables direct tipping of the original artist of an NFT.
     * Requires sending ETH with the transaction.
     * @param _tokenId The ID of the NFT.
     */
    function tipArtist(uint256 _tokenId) external payable nonReentrant whenNotPaused {
        require(_exists(_tokenId), "ERC721: invalid token ID");
        require(msg.value > 0, "Tip amount must be greater than zero");
        
        address artist = originalArtists[_tokenId];
        require(artist != address(0), "Original artist not found");
        require(artist != msg.sender, "Cannot tip yourself");

        payable(artist).transfer(msg.value);
        emit ArtistTipped(_tokenId, msg.sender, artist, msg.value);
    }

    /**
     * @dev Allows creators to register a public profile URI with their address.
     * This URI could point to IPFS metadata containing their portfolio, social links, etc.
     * @param _profileURI The URI (e.g., IPFS hash) pointing to their profile metadata.
     */
    function registerCreatorProfile(string calldata _profileURI) external whenNotPaused {
        require(bytes(_profileURI).length > 0, "Profile URI cannot be empty");
        creatorProfiles[msg.sender] = _profileURI;
        emit CreatorProfileRegistered(msg.sender, _profileURI);
    }

    /**
     * @dev Awards reputation points to a user for positive contributions (e.g., good curation, community participation).
     * These points could influence voting power in a more advanced DAO.
     * @param _user The address of the user to award points to.
     * @param _points The number of points to award.
     * Callable by DAO Manager.
     */
    function awardReputationPoints(address _user, uint256 _points) external onlyDAOManager {
        require(_user != address(0), "Invalid user address");
        require(_points > 0, "Points must be positive");
        reputationPoints[_user] += _points;
        emit ReputationPointsAwarded(_user, _points);
    }

    // --- IV. DAO Governance ---

    /**
     * @dev Initiates a new DAO proposal for configuration changes.
     * Any user can propose, but only DAO Manager can vote for this simplified example.
     * @param _proposalId A unique identifier for the proposal.
     * @param _proposalType The type of change being proposed (see ProposalType enum).
     * @param _payload The ABI-encoded data for the function call to be executed if the proposal passes.
     */
    function proposeConfigurationChange(
        bytes32 _proposalId,
        uint256 _proposalType,
        bytes calldata _payload
    ) external whenNotPaused {
        require(!proposals[_proposalId].exists, "Proposal ID already exists");
        require(_proposalType < uint256(ProposalType.MigrateContract) + 1, "Invalid proposal type");
        
        proposals[_proposalId] = Proposal({
            proposalType: ProposalType(_proposalType),
            payload: _payload,
            startBlock: block.number,
            endBlock: block.number + VOTING_PERIOD_BLOCKS,
            votesFor: 0,
            votesAgainst: 0,
            hasVoted: new mapping(address => bool), // Initialize mapping
            executed: false,
            exists: true
        });
        activeProposals.push(_proposalId); // Add to active list for easier tracking/querying

        emit ProposalCreated(_proposalId, _proposalType, _payload, msg.sender);
    }

    /**
     * @dev Allows a user (specifically, the DAO Manager in this simplified example) to cast their vote on an active proposal.
     * In a full DAO, this would involve governance token balances or specific voter roles.
     * @param _proposalId The ID of the proposal.
     * @param _support True for 'for', false for 'against'.
     */
    function voteOnProposal(bytes32 _proposalId, bool _support) external onlyDAOManager {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.exists, "Proposal does not exist");
        require(!proposal.executed, "Proposal already executed");
        require(block.number <= proposal.endBlock, "Voting period has ended");
        require(!proposal.hasVoted[msg.sender], "Already voted on this proposal");

        proposal.hasVoted[msg.sender] = true;
        if (_support) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }
        emit VoteCast(_proposalId, msg.sender, _support);
    }

    /**
     * @dev Executes a successfully passed DAO proposal.
     * Callable by anyone after the voting period ends and the proposal criteria are met.
     * @param _proposalId The ID of the proposal.
     */
    function executeProposal(bytes32 _proposalId) external nonReentrant {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.exists, "Proposal does not exist");
        require(!proposal.executed, "Proposal already executed");
        require(block.number > proposal.endBlock, "Voting period has not ended");
        require(proposal.votesFor >= MIN_VOTES_FOR_PROPOSAL, "Not enough votes to pass");
        require(proposal.votesFor > proposal.votesAgainst, "Proposal did not pass (more against or tie)");

        proposal.executed = true; // Mark as executed *before* executing to prevent re-entrancy issues with internal calls

        // Decode payload and call the corresponding internal/external function
        bytes memory payload = proposal.payload;
        
        if (proposal.proposalType == ProposalType.ConfigureAIGenParams) {
             (string memory _settingsJson, uint256 _costEth, address _erc20Token, uint256 _costERC20) = abi.decode(payload, (string, uint256, address, uint256));
             configureAIGeneratorParams(_settingsJson, _costEth, _erc20Token, _costERC20);
        } else if (proposal.proposalType == ProposalType.SetGlobalBaseRoyaltyRate) {
             (uint256 _newRatePermyriad) = abi.decode(payload, (uint256));
             setGlobalBaseRoyaltyRate(_newRatePermyriad);
        } else if (proposal.proposalType == ProposalType.DefineDynamicRoyaltyRule) {
             (bytes32 _ruleId, uint256 _ruleType, uint256 _threshold, int256 _adjustmentPermyriad, uint256 _durationBlocks, bool _active) = abi.decode(payload, (bytes32, uint256, uint256, int256, uint256, bool));
             defineDynamicRoyaltyRule(_ruleId, _ruleType, _threshold, _adjustmentPermyriad, _durationBlocks, _active);
        } else if (proposal.proposalType == ProposalType.SetAIParameterPack) {
             (uint256 _packId, string memory _metadataURI, uint256 _price, uint256 _maxSupply) = abi.decode(payload, (uint256, string, uint256, uint256));
             setAIParameterPack(_packId, _metadataURI, _price, _maxSupply);
        } else if (proposal.proposalType == ProposalType.SetOracleAddress) {
             (address _newOracle) = abi.decode(payload, (address));
             setOracleAddress(_newOracle);
        } else if (proposal.proposalType == ProposalType.SetFeeRecipient) {
             (address _newRecipient) = abi.decode(payload, (address));
             setFeeRecipient(_newRecipient);
        } else if (proposal.proposalType == ProposalType.PauseContract) {
             _pause(); // Calls OpenZeppelin Pausable internal function
        } else if (proposal.proposalType == ProposalType.UnpauseContract) {
             _unpause(); // Calls OpenZeppelin Pausable internal function
        } else if (proposal.proposalType == ProposalType.WithdrawTreasuryFunds) {
             (address _recipient, uint256 _amount) = abi.decode(payload, (address, uint256));
             withdrawTreasuryFunds(_recipient, _amount);
        } else if (proposal.proposalType == ProposalType.AwardReputationPoints) {
             (address _user, uint252 _points) = abi.decode(payload, (address, uint256));
             awardReputationPoints(_user, _points);
        } else if (proposal.proposalType == ProposalType.MigrateContract) {
             (address _newImplementation) = abi.decode(payload, (address));
             _migrateToNewContract(_newImplementation);
        }
        
        emit ProposalExecuted(_proposalId);
    }

    // --- V. Treasury Management ---

    /**
     * @dev Allows withdrawal of accumulated platform fees and treasury funds (ETH) from the contract.
     * @param _recipient The address to send funds to.
     * @param _amount The amount of Ether (in wei) to withdraw.
     * Callable by DAO Manager (or via a DAO proposal execution).
     */
    function withdrawTreasuryFunds(address _recipient, uint256 _amount) public onlyDAOManager nonReentrant {
        require(_recipient != address(0), "Invalid recipient address");
        require(address(this).balance >= _amount, "Insufficient balance in treasury");
        payable(_recipient).transfer(_amount);
        emit TreasuryFundsWithdrawn(_recipient, _amount);
    }

    // --- VI. Access Control & Utilities ---

    /**
     * @dev Sets the address of the trusted off-chain oracle.
     * This oracle is responsible for calling `fulfillArtGenerationAndMint` after AI processing.
     * @param _newOracle The new oracle address.
     * Callable by DAO Manager (or via a DAO proposal execution).
     */
    function setOracleAddress(address _newOracle) public onlyDAOManager {
        require(_newOracle != address(0), "Invalid oracle address");
        oracleAddress = _newOracle;
        emit OracleAddressSet(_newOracle);
    }

    /**
     * @dev Sets the address to which platform fees are directed.
     * @param _newRecipient The new fee recipient address.
     * Callable by DAO Manager (or via a DAO proposal execution).
     */
    function setFeeRecipient(address _newRecipient) public onlyDAOManager {
        require(_newRecipient != address(0), "Invalid fee recipient address");
        feeRecipient = _newRecipient;
        emit FeeRecipientSet(_newRecipient);
    }

    /**
     * @dev Pauses critical contract functions (e.g., new requests, sales) in emergencies.
     * Uses OpenZeppelin's Pausable functionality.
     * Callable by DAO Manager (or via a DAO proposal execution).
     */
    function pauseContract() external onlyDAOManager {
        _pause();
    }

    /**
     * @dev Unpauses the contract, resuming operations.
     * Uses OpenZeppelin's Pausable functionality.
     * Callable by DAO Manager (or via a DAO proposal execution).
     */
    function unpauseContract() external onlyDAOManager {
        _unpause();
    }

    /**
     * @dev Internal function to handle contract migration to a new implementation.
     * This is a placeholder for an upgrade mechanism. In a real-world scenario with proxy contracts
     * (e.g., UUPS proxy), this would call a function on the proxy to update its implementation.
     * For a non-proxy contract, this function primarily signals the intent for an upgrade.
     * @param _newImplementation The address of the new contract implementation.
     */
    function _migrateToNewContract(address _newImplementation) internal {
        require(_newImplementation != address(0), "Invalid new implementation address");
        // For a proxy contract, this would be:
        // _setImplementation(_newImplementation); // If using UUPS
        emit ContractMigrated(_newImplementation);
    }

    // --- ERC721 & ERC1155 Overrides ---

    /**
     * @dev Returns the base URI for all token IDs.
     * Overrides both ERC721 and ERC1155 _baseURI.
     */
    function _baseURI() internal pure override(ERC721, ERC1155) returns (string memory) {
        return "ipfs://"; // Example base URI
    }

    /**
     * @dev Returns the URI for an individual token ID.
     * Overrides ERC1155's uri function to handle AI Parameter Pack metadata specifically.
     */
    function uri(uint256 tokenId) public view override returns (string memory) {
        // If the tokenId corresponds to a defined AI Parameter Pack, return its specific metadata URI
        if (aiParameterPacks[tokenId].exists) {
            return aiParameterPacks[tokenId].metadataURI;
        }
        // Otherwise, fall back to the default ERC1155 URI behavior or a general token URI
        // For generative art NFTs (ERC721), their URI is set individually via _setTokenURI.
        return super.uri(tokenId);
    }
}
```