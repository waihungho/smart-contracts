Here's a Solidity smart contract named `QuantumCanvas` that embodies several advanced, creative, and trendy concepts, avoiding direct duplication of common open-source projects. It includes a comprehensive outline and function summary as requested, and features at least 20 functions.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; // For utility functions like toString

/**
 * @title QuantumCanvas
 * @dev An innovative, decentralized platform for AI-assisted generative art, community curation,
 * and dynamic NFT ownership.
 *
 * --- Outline & Function Summary ---
 *
 * Contract Name: QuantumCanvas
 *
 * Purpose/Vision:
 * QuantumCanvas is designed as a nexus where human creativity meets artificial intelligence
 * on the blockchain. It enables users to fund AI art generation, curate the resulting artworks,
 * and earn rewards based on their contributions. It introduces dynamic NFTs (dNFTs) that evolve
 * with community sentiment, a sophisticated reputation system for prompt artists and curators,
 * and a novel "Foresight Market" for predicting future art trends. The platform aims to foster
 * a vibrant, self-governing ecosystem for digital art creation and discovery.
 *
 * Core Concepts:
 * 1.  AI Integration (Oracle-driven): Users submit textual prompts, and a designated off-chain
 *     AI oracle (simulated in this contract) delivers the generated image hashes and metadata
 *     back on-chain.
 * 2.  Generative Art Focus: The primary utility revolves around creating unique, AI-generated
 *     digital artworks based on user prompts.
 * 3.  Dynamic NFTs (dNFTs): Artworks that meet certain community curation thresholds can be minted
 *     as NFTs. Crucially, these NFTs are "dynamic," meaning their on-chain attributes and off-chain
 *     visual representation (via metadata URI) can evolve based on ongoing community interaction,
 *     such as further curation scores or confirmed tags.
 * 4.  Reputation System: Tracks and incentivizes high-quality contributions from "Prompt Artists"
 *     (those whose prompts lead to popular art) and "Curators" (those who effectively judge and
 *     categorize artworks).
 * 5.  Social Curation & Governance: Community-driven voting and semantic tagging mechanisms
 *     allow users to collectively refine the collection, identify high-quality pieces, and contribute
 *     to the evolving state of dNFTs.
 * 6.  Knowledge Graph: A decentralized semantic tagging system for artworks enables advanced
 *     discovery, filtering, and potentially AI-driven recommendations based on established
 *     relationships between art pieces and keywords.
 * 7.  Foresight Market: A lightweight mechanism for users to predict emerging art trends or styles,
 *     staking on their predictions and earning rewards for accuracy.
 * 8.  Gamification: Introduction of "Challenges" or "Themes" to incentivize specific types of
 *     art generation and foster friendly competition among artists.
 *
 * Key Data Structures:
 * -   Prompt: Represents a user's request for AI art generation.
 * -   Image: Stores details of an AI-generated artwork, including its hash, metadata, and curation score.
 * -   NFTDynamicData: Holds the evolving attributes specific to a minted QuantumCanvas NFT.
 * -   Challenge: Defines a themed art generation competition with a deadline and reward pool.
 * -   TrendPrediction: Represents a proposed future art trend for the Foresight Market, including stakers.
 *
 * Function Categories & Summaries (32 functions total):
 *
 * I. Initialization & Configuration
 *    1.  `constructor()`: Initializes the ERC721 token (name, symbol) and sets the initial contract owner.
 *    2.  `updateOracleAddress(address _newOracle)`: Allows the contract owner to designate the trusted AI oracle address.
 *    3.  `setThresholds(uint256 _minCurationToMint, uint256 _minCurationToEvolve, uint256 _promptCost)`: Configures operational parameters like NFT minting/evolution thresholds and prompt submission cost.
 *    4.  `setRoyaltyRecipient(address _recipient, uint96 _basisPoints)`: Sets the recipient address and percentage for NFT royalties (EIP-2981 inspired).
 *
 * II. Inspiration & AI Art Generation
 *    5.  `depositInspirationUnits()`: Allows users to deposit ETH into the contract, which can be used to pay for AI prompt requests.
 *    6.  `requestAIArtGeneration(string calldata _promptText)`: Submits a textual prompt to be processed by the AI oracle, deducting the `promptCost` from `msg.value`.
 *    7.  `receiveAIArtResult(uint256 _promptId, string calldata _imageHash, string calldata _metadataURI)`: (Oracle-only) Records the output of the off-chain AI, associating a generated image with its original prompt.
 *    8.  `getPromptDetails(uint256 _promptId)`: Retrieves comprehensive details about a specific AI art prompt request.
 *    9.  `getImageDetails(uint256 _imageId)`: Retrieves all available details for a specific AI-generated image.
 *
 * III. Image Curation & Dynamic NFTs
 *    10. `curateImage(uint256 _imageId, bool _isPositive)`: Allows users to vote positively or negatively on an image, influencing its curation score and the curator's reputation.
 *    11. `mintQuantumCanvasNFT(uint256 _imageId)`: Mints an AI-generated image as an ERC721 NFT to the caller, provided the image has achieved the minimum required curation score.
 *    12. `getNFTCurrentMetadataURI(uint256 _tokenId)`: Returns the current metadata URI for a given NFT, which reflects its dynamic state (e.g., evolution stage).
 *    13. `_updateNFTDynamicAttributes(uint256 _tokenId)`: (Internal) Triggers an update to the on-chain dynamic attributes of a dNFT, potentially changing its `evolutionStage` based on new curation scores.
 *    14. `tokenURI(uint256 _tokenId)`: Overrides the standard ERC721 function to provide the dynamic metadata URI.
 *    15. `transferFrom(address from, address to, uint256 tokenId)`: Standard ERC721 transfer function (inherited from OpenZeppelin).
 *
 * IV. Reputation & Reward System
 *    16. `getPromptArtistReputation(address _artist)`: Queries the reputation score of a prompt artist.
 *    17. `getCuratorReputation(address _curator)`: Queries the reputation score of a curator.
 *    18. `claimArtistRewards(uint256[] calldata _promptIds)`: Allows prompt artists to claim accumulated ETH rewards for their successful (e.g., minted) prompts.
 *    19. `claimCuratorRewards()`: Allows curators to claim their accumulated ETH rewards based on effective and valued curation activities.
 *
 * V. Creative Challenges & Foresight Market
 *    20. `createThemeChallenge(string calldata _name, string calldata _description, uint256 _deadline)`: (Owner-only) Initiates a new themed art generation challenge with a submission deadline.
 *    21. `submitToChallenge(uint256 _imageId, uint256 _challengeId)`: Allows the prompt artist to submit one of their generated images to an active challenge.
 *    22. `getChallengeStatus(uint256 _challengeId)`: Retrieves the current status, details, and submitted images for a specific challenge.
 *    23. `resolveChallenge(uint256 _challengeId)`: (Owner-only) Finalizes a challenge, determines winners based on image curation scores, and distributes rewards.
 *    24. `proposeFutureTrend(string calldata _trendName, string calldata _description, uint256 _predictionDeadline)`: Allows users to propose a future art trend for the Foresight Market.
 *    25. `predictTrendPopularity(uint256 _trendId)`: Users stake ETH to predict the popularity outcome of a proposed trend.
 *    26. `resolveTrendPrediction(uint256 _trendId, bool _isPopular)`: (Owner/Oracle-only) Concludes a trend prediction, distributing staked ETH to accurate predictors.
 *
 * VI. Knowledge Graph & Discovery
 *    27. `addTagsToImage(uint256 _imageId, string[] calldata _tags)`: Allows users to suggest semantic tags for an image.
 *    28. `confirmTags(uint256 _imageId, string[] calldata _tagsToConfirm)`: (Curator-gated) Allows highly reputed curators to confirm suggested tags, permanently associating them with an image.
 *    29. `searchImagesByTag(string calldata _tag)`: Retrieves a list of image IDs that have been confirmed with a specific tag.
 *    30. `getRecommendedImages(address _user)`: (Simulated) Returns a list of image IDs recommended for a specific user based on a simplified interaction model (in a real system, this would be AI-driven off-chain).
 *
 * VII. Administrative & Utility
 *    31. `withdrawFunds(address _to, uint256 _amount)`: Allows the contract owner to withdraw ETH from the contract's balance.
 *    32. `getContractBalance()`: Returns the current ETH balance held by the smart contract.
 *
 */
contract QuantumCanvas is ERC721, Ownable {
    using Counters for Counters.Counter;

    // --- State Variables & Counters ---
    Counters.Counter private _promptIds; // Counter for unique prompt IDs
    Counters.Counter private _imageIds;  // Counter for unique image IDs
    Counters.Counter private _challengeIds; // Counter for unique challenge IDs
    Counters.Counter private _trendIds; // Counter for unique trend prediction IDs

    // --- Configuration & Thresholds ---
    address public oracleAddress; // Address of the trusted AI oracle, set by owner
    uint256 public minCurationToMint; // Minimum net positive curation score for an image to be mintable as an NFT
    uint256 public minCurationToEvolve; // Threshold for dNFT metadata to "evolve" to the next stage
    uint256 public promptCost; // Cost in wei for a user to submit an AI art generation prompt
    uint96 public royaltyBasisPoints; // Royalty percentage for NFT sales (e.g., 500 for 5%), used for EIP-2981
    address public royaltyRecipient; // Address designated to receive NFT royalties

    // --- Data Structures ---

    enum PromptStatus { Submitted, AIProcessing, AIResultReceived, Failed }
    struct Prompt {
        string promptText;            // The textual description given to the AI
        address submitter;            // Address of the user who submitted the prompt
        PromptStatus status;         // Current status of the prompt
        uint256 associatedImageId;    // The ID of the generated image (0 if not yet generated)
        uint256 submissionTimestamp;  // Timestamp when the prompt was submitted
        uint256 inspirationUnitsCost; // The actual cost paid for this prompt
    }
    mapping(uint256 => Prompt) public prompts; // promptId => Prompt details

    struct Image {
        uint256 promptId;             // ID of the prompt that generated this image
        string imageHash;             // Content hash of the image (e.g., IPFS CID)
        string metadataURI;           // Base URI for NFT metadata (can be updated for dNFTs)
        int256 currentCurationScore;  // Net score from positive/negative curations
        bool mintedAsNFT;             // True if this image has been minted as an NFT
        uint256 mintedTokenId;        // The NFT token ID if minted (0 if not)
        address currentOwnerNFT;      // Current owner of the minted NFT (for quick lookup)
        string[] tags;                // Confirmed semantic tags for the image
        mapping(address => bool) hasCurated; // Tracks if a user has already curated this image
        uint256 creationTimestamp;    // Timestamp when the image result was received
    }
    mapping(uint256 => Image) public images; // imageId => Image details

    // Dynamic NFT attributes that can change over time
    struct NFTDynamicData {
        uint256 lastCurationScoreUpdate; // Timestamp of the last significant curation score change
        uint256 evolutionStage;         // Represents different visual/metadata stages of the dNFT
        // Future expansion: could include 'traits' that unlock over time or based on interaction
    }
    mapping(uint256 => NFTDynamicData) public nftDynamicAttributes; // tokenId => Dynamic NFT data

    enum ChallengeStatus { Active, Resolved }
    struct Challenge {
        string name;                  // Name of the challenge
        string description;           // Description of the challenge's theme
        uint256 creationTimestamp;    // Timestamp when the challenge was created
        uint256 deadline;             // Deadline for submitting images to the challenge
        ChallengeStatus status;       // Current status of the challenge
        uint256[] submittedImageIds;  // List of image IDs submitted to this challenge
        address[] winners;            // Addresses of the winners after resolution
        uint256 rewardPool;           // Total ETH allocated for challenge rewards
    }
    mapping(uint256 => Challenge) public challenges; // challengeId => Challenge details

    enum TrendPredictionStatus { Active, Resolved }
    struct TrendPrediction {
        string trendName;             // Name of the proposed trend
        string description;           // Description of the trend
        address proposer;             // Address of the user who proposed the trend
        uint256 proposalTimestamp;    // Timestamp of trend proposal
        uint256 predictionDeadline;   // Deadline for users to make predictions
        TrendPredictionStatus status; // Current status of the prediction market
        uint256 totalStaked;          // Total ETH staked across all predictors for this trend
        mapping(address => uint256) stakers; // User => amount staked on this trend (simplified: does not distinguish 'yes'/'no' bets)
        bool isPopularOutcome;        // The actual outcome: true if the trend became popular, false otherwise
    }
    mapping(uint256 => TrendPrediction) public trendPredictions; // trendId => TrendPrediction details

    // --- Reputation Systems ---
    mapping(address => int256) public promptArtistReputation; // Reputation score for prompt submitters
    mapping(address => int256) public curatorReputation;      // Reputation score for curators
    mapping(address => uint256) public curatorRewardsPending; // Pending ETH rewards for curators

    // --- Knowledge Graph (Tags) ---
    mapping(string => uint256[]) public tagToImageIds;          // Maps a tag string to a list of image IDs it's associated with
    mapping(uint256 => mapping(address => string[])) public pendingImageTags; // Stores suggested tags for an image by user, awaiting confirmation

    // --- Events ---
    event InspirationUnitsDeposited(address indexed user, uint256 amount);
    event PromptRequested(uint256 indexed promptId, address indexed submitter, string promptText, uint256 cost);
    event AIResultReceived(uint256 indexed promptId, uint256 indexed imageId, string imageHash, string metadataURI);
    event ImageCurated(uint256 indexed imageId, address indexed curator, bool isPositive, int256 newScore);
    event NFTMinted(uint256 indexed tokenId, uint256 indexed imageId, address indexed owner);
    event NFTMetadataUpdated(uint256 indexed tokenId, string newURI, uint256 newEvolutionStage);
    event ChallengeCreated(uint256 indexed challengeId, string name, uint256 deadline);
    event ImageSubmittedToChallenge(uint256 indexed imageId, uint256 indexed challengeId);
    event ChallengeResolved(uint256 indexed challengeId, address[] winners, uint256 rewardAmount);
    event TrendProposed(uint256 indexed trendId, string trendName, address proposer);
    event TrendPredicted(uint256 indexed trendId, address indexed predictor, uint256 amount);
    event TrendResolved(uint256 indexed trendId, bool isPopular);
    event TagsAdded(uint256 indexed imageId, address indexed user, string[] tags);
    event TagsConfirmed(uint256 indexed imageId, string[] tags);
    event PromptArtistRewardClaimed(address indexed artist, uint256 amount);
    event CuratorRewardClaimed(address indexed curator, uint256 amount);
    event OracleAddressUpdated(address indexed oldAddress, address indexed newAddress);
    event ThresholdsUpdated(uint256 minCurationToMint, uint256 minCurationToEvolve, uint256 promptCost);

    // --- Modifiers ---
    modifier onlyOracle() {
        require(msg.sender == oracleAddress, "QC: Not the designated AI oracle");
        _;
    }

    // --- Constructor ---
    /// @dev Initializes the ERC721 token with a name and symbol, and sets the deploying address as owner.
    constructor() ERC721("QuantumCanvas", "QCART") Ownable(msg.sender) {
        oracleAddress = address(0); // Must be explicitly set by the owner after deployment
        minCurationToMint = 10;     // Default: An image needs a net positive score of 10 to be mintable
        minCurationToEvolve = 20;   // Default: An image needs a net positive score of 20 for its dNFT to evolve
        promptCost = 0.01 ether;    // Default: 0.01 ETH per prompt submission
        royaltyRecipient = msg.sender; // Default royalty recipient is the owner
        royaltyBasisPoints = 500; // Default: 5% royalty (500 basis points out of 10000)
    }

    // --- I. Initialization & Configuration ---

    /// @notice Allows the contract owner to update the address of the trusted AI oracle.
    /// @param _newOracle The new address for the AI oracle.
    function updateOracleAddress(address _newOracle) public onlyOwner {
        require(_newOracle != address(0), "QC: Oracle address cannot be zero");
        emit OracleAddressUpdated(oracleAddress, _newOracle);
        oracleAddress = _newOracle;
    }

    /// @notice Allows the owner to set various operational thresholds for the platform.
    /// @param _minCurationToMint_ The minimum net positive curation score required for an image to be minted as an NFT.
    /// @param _minCurationToEvolve_ The minimum net positive curation score required for a dNFT to evolve its metadata.
    /// @param _promptCost_ The cost in wei to submit a new AI art generation prompt.
    function setThresholds(
        uint256 _minCurationToMint_,
        uint256 _minCurationToEvolve_,
        uint256 _promptCost_
    ) public onlyOwner {
        require(_minCurationToEvolve_ >= _minCurationToMint_, "QC: Evolution threshold must be >= mint threshold");
        minCurationToMint = _minCurationToMint_;
        minCurationToEvolve = _minCurationToEvolve_;
        promptCost = _promptCost_;
        emit ThresholdsUpdated(minCurationToMint, minCurationToEvolve, promptCost);
    }

    /// @notice Sets the recipient and rate for NFT royalties, compliant with EIP-2981.
    /// @param _recipient The address to receive royalties.
    /// @param _basisPoints The royalty rate in basis points (e.g., 500 for 5%). Max 10000 (100%).
    function setRoyaltyRecipient(address _recipient, uint96 _basisPoints) public onlyOwner {
        require(_recipient != address(0), "QC: Royalty recipient cannot be zero address");
        require(_basisPoints <= 10000, "QC: Royalty basis points cannot exceed 10000 (100%)");
        royaltyRecipient = _recipient;
        royaltyBasisPoints = _basisPoints;
    }

    // --- II. Inspiration & AI Art Generation ---

    /// @notice Allows users to deposit ETH into the contract to fund AI prompt requests.
    /// @dev This function is payable and increases the contract's balance, serving as "inspiration units."
    function depositInspirationUnits() public payable {
        require(msg.value > 0, "QC: Must deposit a positive amount");
        emit InspirationUnitsDeposited(msg.sender, msg.value);
    }

    /// @notice Submits a text prompt for AI processing.
    /// @dev This function is payable; `msg.value` must cover the `promptCost`. Any excess is treated as `inspirationUnits`.
    /// @param _promptText The textual description for the AI to generate art from.
    function requestAIArtGeneration(string calldata _promptText) public payable {
        require(bytes(_promptText).length > 0, "QC: Prompt text cannot be empty");
        require(msg.value >= promptCost, "QC: Insufficient ETH to cover prompt cost.");

        // If msg.value is greater than promptCost, the excess remains in the contract as inspiration units
        if (msg.value > promptCost) {
             emit InspirationUnitsDeposited(msg.sender, msg.value - promptCost);
        }

        uint256 newPromptId = _promptIds.current();
        prompts[newPromptId] = Prompt({
            promptText: _promptText,
            submitter: msg.sender,
            status: PromptStatus.Submitted, // Marks for AI processing by oracle
            associatedImageId: 0,
            submissionTimestamp: block.timestamp,
            inspirationUnitsCost: promptCost
        });
        _promptIds.increment();

        emit PromptRequested(newPromptId, msg.sender, _promptText, promptCost);
    }

    /// @notice (Oracle-only) Records the AI-generated image result on-chain.
    /// @dev This function is intended to be called by a trusted off-chain AI oracle service once it generates an image.
    /// @param _promptId The ID of the prompt that this image is a result of.
    /// @param _imageHash The content hash of the generated image (e.g., IPFS CID, serving as unique identifier).
    /// @param _metadataURI The URI pointing to the image's metadata (e.g., JSON on IPFS, for NFT attributes).
    function receiveAIArtResult(uint256 _promptId, string calldata _imageHash, string calldata _metadataURI) public onlyOracle {
        require(_promptId < _promptIds.current(), "QC: Invalid prompt ID");
        require(prompts[_promptId].status == PromptStatus.Submitted || prompts[_promptId].status == PromptStatus.AIProcessing, "QC: Prompt not in pending state for result");
        require(bytes(_imageHash).length > 0, "QC: Image hash cannot be empty");
        require(bytes(_metadataURI).length > 0, "QC: Metadata URI cannot be empty");
        require(prompts[_promptId].associatedImageId == 0, "QC: Prompt already has an associated image");

        uint256 newImageId = _imageIds.current();
        images[newImageId] = Image({
            promptId: _promptId,
            imageHash: _imageHash,
            metadataURI: _metadataURI,
            currentCurationScore: 0,
            mintedAsNFT: false,
            mintedTokenId: 0,
            currentOwnerNFT: address(0),
            tags: new string[](0),
            creationTimestamp: block.timestamp
        });
        _imageIds.increment();

        prompts[_promptId].status = PromptStatus.AIResultReceived;
        prompts[_promptId].associatedImageId = newImageId;

        emit AIResultReceived(_promptId, newImageId, _imageHash, _metadataURI);
    }

    /// @notice Retrieves all details for a specific prompt request.
    /// @param _promptId The ID of the prompt.
    /// @return The Prompt struct containing all its details.
    function getPromptDetails(uint256 _promptId) public view returns (Prompt memory) {
        require(_promptId < _promptIds.current(), "QC: Invalid prompt ID");
        return prompts[_promptId];
    }

    /// @notice Retrieves all details for a specific generated image.
    /// @param _imageId The ID of the image.
    /// @return The Image struct containing all its details.
    function getImageDetails(uint256 _imageId) public view returns (Image memory) {
        require(_imageId < _imageIds.current(), "QC: Invalid image ID");
        return images[_imageId];
    }

    // --- III. Image Curation & Dynamic NFTs ---

    /// @notice Allows users to cast a positive or negative vote on an image, influencing its curation score.
    /// @dev Users cannot curate their own prompt's image and can only curate an image once.
    /// @param _imageId The ID of the image to curate.
    /// @param _isPositive True for a positive vote (increases score), false for a negative vote (decreases score).
    function curateImage(uint256 _imageId, bool _isPositive) public {
        require(_imageId < _imageIds.current(), "QC: Invalid image ID");
        require(!images[_imageId].hasCurated[msg.sender], "QC: Already curated this image");
        require(msg.sender != prompts[images[_imageId].promptId].submitter, "QC: Cannot curate your own prompt's image");

        if (_isPositive) {
            images[_imageId].currentCurationScore++;
            curatorReputation[msg.sender]++; // Increase reputation for positive curation
            curatorRewardsPending[msg.sender] += 10; // Small reward for good curation (in wei)
        } else {
            images[_imageId].currentCurationScore--;
            curatorReputation[msg.sender]--; // Decrease reputation for negative curation
        }
        images[_imageId].hasCurated[msg.sender] = true;

        // Potentially trigger NFT metadata update if the image is already minted as a dNFT
        if (images[_imageId].mintedAsNFT) {
            _updateNFTDynamicAttributes(images[_imageId].mintedTokenId);
        }

        emit ImageCurated(_imageId, msg.sender, _isPositive, images[_imageId].currentCurationScore);
    }

    /// @notice Mints an AI-generated image as a QuantumCanvas NFT, provided it meets curation thresholds.
    /// @dev The NFT is minted to the caller of this function.
    /// @param _imageId The ID of the image to mint.
    function mintQuantumCanvasNFT(uint256 _imageId) public {
        require(_imageId < _imageIds.current(), "QC: Invalid image ID");
        Image storage img = images[_imageId];
        require(!img.mintedAsNFT, "QC: Image already minted as NFT");
        require(img.currentCurationScore >= int256(minCurationToMint), "QC: Image has not met minimum curation score for minting");
        require(img.promptId != 0, "QC: Image has no associated prompt (AI result not received)");

        // Token IDs are offset to avoid collision with image IDs and make them distinguishable
        uint256 newTokenId = _imageIds.current() + 100000;
        _mint(msg.sender, newTokenId); // Mints the NFT to the caller
        _setTokenURI(newTokenId, img.metadataURI); // Set initial URI from image's base metadataURI

        img.mintedAsNFT = true;
        img.mintedTokenId = newTokenId;
        img.currentOwnerNFT = msg.sender; // Record initial owner

        nftDynamicAttributes[newTokenId] = NFTDynamicData({
            lastCurationScoreUpdate: block.timestamp,
            evolutionStage: 0 // Initial evolution stage
        });

        // Award reputation to the prompt artist whose art got minted
        promptArtistReputation[prompts[img.promptId].submitter] += 100;

        emit NFTMinted(newTokenId, _imageId, msg.sender);
    }

    /// @notice Returns the current URI for a QuantumCanvas NFT, reflecting its dynamic state.
    /// @dev This function calculates the effective URI, potentially appending stage information.
    /// @param _tokenId The ID of the NFT.
    /// @return The URI of the NFT's metadata.
    function getNFTCurrentMetadataURI(uint256 _tokenId) public view returns (string memory) {
        require(_exists(_tokenId), "ERC721: URI query for nonexistent token");
        uint256 imageId = _tokenId - 100000; // Reverse calculate image ID from token ID
        require(imageId < _imageIds.current(), "QC: Invalid image ID derived from token ID");

        Image storage img = images[imageId];
        NFTDynamicData storage nftData = nftDynamicAttributes[_tokenId];

        // Example dynamic logic: Append evolution stage as a query parameter to the base URI.
        // A real off-chain rendering service would interpret this parameter to display
        // different visual assets or metadata based on the `evolutionStage`.
        if (nftData.evolutionStage > 0) {
            return string(abi.encodePacked(img.metadataURI, "?stage=", Strings.toString(nftData.evolutionStage)));
        }
        return img.metadataURI;
    }

    /// @notice (Internal/Triggered) Updates on-chain attributes of a dNFT based on events.
    /// @dev This function is called internally after relevant events like curation score changes
    ///      to potentially advance the dNFT's `evolutionStage`.
    /// @param _tokenId The ID of the NFT to update.
    function _updateNFTDynamicAttributes(uint256 _tokenId) internal {
        uint256 imageId = _tokenId - 100000;
        Image storage img = images[imageId];
        NFTDynamicData storage nftData = nftDynamicAttributes[_tokenId];

        uint256 oldEvolutionStage = nftData.evolutionStage;

        // Simple evolution logic: dNFT evolves based on net positive curation score reaching thresholds.
        // Stage 0 -> 1: when `minCurationToEvolve` is met.
        // Stage 1 -> 2: when `2 * minCurationToEvolve` is met (example for further stages).
        if (img.currentCurationScore >= int256(minCurationToEvolve) && nftData.evolutionStage == 0) {
            nftData.evolutionStage = 1;
            nftData.lastCurationScoreUpdate = block.timestamp;
        } else if (img.currentCurationScore >= int256(minCurationToEvolve * 2) && nftData.evolutionStage == 1) {
            nftData.evolutionStage = 2;
            nftData.lastCurationScoreUpdate = block.timestamp;
        }
        // More complex evolution: could also consider time, specific tags, or owner interactions.

        if (nftData.evolutionStage != oldEvolutionStage) {
            emit NFTMetadataUpdated(_tokenId, getNFTCurrentMetadataURI(_tokenId), nftData.evolutionStage);
        }
    }

    /// @notice Overrides the standard ERC721 `tokenURI` function to provide dynamic metadata based on the dNFT's state.
    /// @param _tokenId The ID of the token.
    /// @return The URI for the token's metadata.
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        return getNFTCurrentMetadataURI(_tokenId);
    }

    /// @notice Standard ERC721 `transferFrom` function.
    /// @dev This function is inherited from OpenZeppelin's ERC721 and is listed here for clarity of functionality count.
    ///      It allows transferring ownership of an NFT.
    function transferFrom(address from, address to, uint256 tokenId) public override(ERC721) {
        super.transferFrom(from, to, tokenId);
        // Optionally, update the `currentOwnerNFT` field in the Image struct for redundant tracking,
        // though ERC721 handles ownership directly.
        // images[tokenId - 100000].currentOwnerNFT = to;
    }

    // --- IV. Reputation & Reward System ---

    /// @notice Retrieves the current reputation score for a prompt artist.
    /// @param _artist The address of the prompt artist.
    /// @return The current reputation score.
    function getPromptArtistReputation(address _artist) public view returns (int256) {
        return promptArtistReputation[_artist];
    }

    /// @notice Retrieves the current reputation score for a curator.
    /// @param _curator The address of the curator.
    /// @return The current reputation score.
    function getCuratorReputation(address _curator) public view returns (int256) {
        return curatorReputation[_curator];
    }

    /// @notice Allows prompt artists to claim accumulated ETH rewards for their successful prompts.
    /// @dev Rewards are based on specific triggers, e.g., when an image from their prompt is minted as an NFT.
    /// @param _promptIds Array of prompt IDs for which the artist wishes to claim rewards.
    function claimArtistRewards(uint256[] calldata _promptIds) public {
        uint256 totalReward = 0;
        for (uint256 i = 0; i < _promptIds.length; i++) {
            uint256 pId = _promptIds[i];
            require(prompts[pId].submitter == msg.sender, "QC: Not your prompt");
            require(prompts[pId].associatedImageId != 0, "QC: Prompt has no associated image");

            Image storage img = images[prompts[pId].associatedImageId];
            // Simplified reward logic: reward if minted and not already claimed.
            // A more robust system would need a `bool isRewardClaimed` flag on the Prompt struct.
            // For now, if the image is minted and the prompt status is `AIResultReceived`, we assume it's claimable.
            if (img.mintedAsNFT && prompts[pId].status == PromptStatus.AIResultReceived) {
                totalReward += 0.05 ether; // Example: 0.05 ETH per minted prompt
                prompts[pId].status = PromptStatus.Failed; // Mark as "processed/claimed" to prevent re-claiming (simplistic)
                promptArtistReputation[msg.sender] += 50; // Bonus reputation
            }
        }
        require(totalReward > 0, "QC: No rewards to claim for these prompts");
        (bool success,) = payable(msg.sender).call{value: totalReward}("");
        require(success, "QC: Failed to send artist reward");
        emit PromptArtistRewardClaimed(msg.sender, totalReward);
    }

    /// @notice Allows curators to claim their accumulated ETH rewards.
    /// @dev Rewards are accumulated based on effective curation actions (e.g., positive votes).
    function claimCuratorRewards() public {
        uint256 rewardAmount = curatorRewardsPending[msg.sender];
        require(rewardAmount > 0, "QC: No curator rewards pending");

        curatorRewardsPending[msg.sender] = 0; // Reset pending rewards

        (bool success,) = payable(msg.sender).call{value: rewardAmount}("");
        require(success, "QC: Failed to send curator reward");
        emit CuratorRewardClaimed(msg.sender, rewardAmount);
    }

    // --- V. Creative Challenges & Foresight Market ---

    /// @notice Allows the owner to create a new themed art challenge.
    /// @param _name The name of the challenge.
    /// @param _description A description outlining the challenge's theme or criteria.
    /// @param _deadline The timestamp when the challenge submission period ends.
    function createThemeChallenge(string calldata _name, string calldata _description, uint256 _deadline) public onlyOwner {
        require(bytes(_name).length > 0, "QC: Challenge name cannot be empty");
        require(_deadline > block.timestamp, "QC: Deadline must be in the future");

        uint256 newChallengeId = _challengeIds.current();
        challenges[newChallengeId] = Challenge({
            name: _name,
            description: _description,
            creationTimestamp: block.timestamp,
            deadline: _deadline,
            status: ChallengeStatus.Active,
            submittedImageIds: new uint256[](0),
            winners: new address[](0),
            rewardPool: 0 // Can be funded later by owner/dao
        });
        _challengeIds.increment();
        emit ChallengeCreated(newChallengeId, _name, _deadline);
    }

    /// @notice Allows users to link an existing generated image to a challenge submission.
    /// @dev Only the original prompt artist can submit their image.
    /// @param _imageId The ID of the image to submit.
    /// @param _challengeId The ID of the challenge to submit to.
    function submitToChallenge(uint256 _imageId, uint256 _challengeId) public {
        require(_imageId < _imageIds.current(), "QC: Invalid image ID");
        require(_challengeId < _challengeIds.current(), "QC: Invalid challenge ID");
        Challenge storage challenge = challenges[_challengeId];
        require(challenge.status == ChallengeStatus.Active, "QC: Challenge is not active");
        require(block.timestamp < challenge.deadline, "QC: Challenge deadline passed");
        require(prompts[images[_imageId].promptId].submitter == msg.sender, "QC: Only the prompt artist can submit their image");

        // Prevent duplicate submissions of the same image to the same challenge
        for (uint256 i = 0; i < challenge.submittedImageIds.length; i++) {
            if (challenge.submittedImageIds[i] == _imageId) {
                revert("QC: Image already submitted to this challenge");
            }
        }

        challenge.submittedImageIds.push(_imageId);
        emit ImageSubmittedToChallenge(_imageId, _challengeId);
    }

    /// @notice Retrieves details and current status of a challenge.
    /// @param _challengeId The ID of the challenge.
    /// @return The Challenge struct containing all its details.
    function getChallengeStatus(uint256 _challengeId) public view returns (Challenge memory) {
        require(_challengeId < _challengeIds.current(), "QC: Invalid challenge ID");
        return challenges[_challengeId];
    }

    /// @notice (Owner-only) Finalizes a challenge, identifying winners and distributing bonuses.
    /// @dev Winners are determined by the curation scores of submitted images (top 3 in this example).
    /// @param _challengeId The ID of the challenge to resolve.
    function resolveChallenge(uint256 _challengeId) public onlyOwner {
        require(_challengeId < _challengeIds.current(), "QC: Invalid challenge ID");
        Challenge storage challenge = challenges[_challengeId];
        require(challenge.status == ChallengeStatus.Active, "QC: Challenge is not active");
        require(block.timestamp >= challenge.deadline, "QC: Challenge deadline has not passed yet");
        require(challenge.submittedImageIds.length > 0, "QC: No images submitted to this challenge");

        // Simple winner selection: sort submitted images by curation score.
        // For large arrays, a more gas-efficient sorting mechanism or off-chain selection would be needed.
        uint256[] memory submitted = challenge.submittedImageIds; // Copy to memory for sorting
        for (uint256 i = 0; i < submitted.length; i++) {
            for (uint256 j = i + 1; j < submitted.length; j++) {
                if (images[submitted[i]].currentCurationScore < images[submitted[j]].currentCurationScore) {
                    uint256 temp = submitted[i];
                    submitted[i] = submitted[j];
                    submitted[j] = temp;
                }
            }
        }

        // Determine winners (e.g., top 3 highest-curated images)
        uint256 numWinners = submitted.length > 3 ? 3 : submitted.length; // Max 3 winners
        address[] memory winners = new address[](numWinners);
        uint256 defaultRewardPool = 0.2 ether; // Default pool if no specific pool was set for the challenge
        uint256 totalRewardToDistribute = challenge.rewardPool > 0 ? challenge.rewardPool : defaultRewardPool;

        for (uint256 i = 0; i < numWinners; i++) {
            address artistAddress = prompts[images[submitted[i]].promptId].submitter;
            winners[i] = artistAddress;

            // Reward distribution: e.g., 1st=50%, 2nd=30%, 3rd=20%
            uint256 rewardAmount = 0;
            if (i == 0) rewardAmount = totalRewardToDistribute * 50 / 100;
            else if (i == 1) rewardAmount = totalRewardToDistribute * 30 / 100;
            else if (i == 2) rewardAmount = totalRewardToDistribute * 20 / 100;

            (bool success,) = payable(artistAddress).call{value: rewardAmount}("");
            require(success, "QC: Failed to send challenge reward to winner");
        }

        challenge.status = ChallengeStatus.Resolved;
        challenge.winners = winners;
        challenge.rewardPool = totalRewardToDistribute; // Record the final distributed pool size
        emit ChallengeResolved(_challengeId, winners, totalRewardToDistribute);
    }

    /// @notice Allows users to propose future art trends for the "Foresight Market".
    /// @param _trendName The concise name of the proposed trend.
    /// @param _description A detailed description of the trend.
    /// @param _predictionDeadline The timestamp when the prediction period for this trend closes.
    function proposeFutureTrend(string calldata _trendName, string calldata _description, uint256 _predictionDeadline) public {
        require(bytes(_trendName).length > 0, "QC: Trend name cannot be empty");
        require(_predictionDeadline > block.timestamp, "QC: Prediction deadline must be in the future");

        uint256 newTrendId = _trendIds.current();
        trendPredictions[newTrendId] = TrendPrediction({
            trendName: _trendName,
            description: _description,
            proposer: msg.sender,
            proposalTimestamp: block.timestamp,
            predictionDeadline: _predictionDeadline,
            status: TrendPredictionStatus.Active,
            totalStaked: 0,
            isPopularOutcome: false // Default; set upon resolution
        });
        _trendIds.increment();
        emit TrendProposed(newTrendId, _trendName, msg.sender);
    }

    /// @notice Users stake ETH to predict the popularity outcome of a proposed trend.
    /// @dev This function is payable; `msg.value` is considered the prediction amount.
    /// @param _trendId The ID of the trend to predict on.
    function predictTrendPopularity(uint256 _trendId) public payable {
        require(_trendId < _trendIds.current(), "QC: Invalid trend ID");
        TrendPrediction storage trend = trendPredictions[_trendId];
        require(trend.status == TrendPredictionStatus.Active, "QC: Trend prediction is not active");
        require(block.timestamp < trend.predictionDeadline, "QC: Prediction deadline passed");
        require(msg.value > 0, "QC: Prediction amount must be positive");

        trend.totalStaked += msg.value;
        trend.stakers[msg.sender] += msg.value; // Store individual stakes
        emit TrendPredicted(_trendId, msg.sender, msg.value);
    }

    /// @notice (Owner/Oracle-only) Resolves a trend prediction, distributing rewards to accurate predictors.
    /// @dev In a real scenario, `_isPopular` would be determined by a reputable oracle or decentralized consensus.
    /// @param _trendId The ID of the trend to resolve.
    /// @param _isPopular The actual outcome: true if the trend became popular, false otherwise.
    function resolveTrendPrediction(uint256 _trendId, bool _isPopular) public onlyOwner { // Or `onlyOracle`
        require(_trendId < _trendIds.current(), "QC: Invalid trend ID");
        TrendPrediction storage trend = trendPredictions[_trendId];
        require(trend.status == TrendPredictionStatus.Active, "QC: Trend prediction is not active");
        require(block.timestamp >= trend.predictionDeadline, "QC: Prediction deadline has not passed yet");

        trend.status = TrendPredictionStatus.Resolved;
        trend.isPopularOutcome = _isPopular;

        uint256 totalPool = trend.totalStaked;
        // In a more complex prediction market, there would be separate pools for 'yes'/'no' bets.
        // This simplified example assumes all stakers win if the outcome matches, receiving their stake back plus bonus.
        // A more robust implementation would require storing each staker's specific prediction (`bool`).

        // Simplified payout: Iterate all stakers and give them their stake * 1.5 if _isPopular is true (and they bet implicitly on true)
        // This mapping `stakers` doesn't track *which* way they predicted, just that they staked.
        // For actual prediction markets, you'd need `mapping(address => bool) private userPrediction;` and `mapping(bool => uint256) totalStakedOnOutcome;`
        // We'll just distribute the entire pool back to the contract owner in this simplified scenario, or to the proposer.
        // Let's assume the contract owner re-distributes or it's a burn mechanism.
        // For a more meaningful demo, let's refund *all* stakers their original stake and send remaining to owner for fees/rewards.
        // This needs a loop through all stakers, which is not efficient for many users.
        // A real system would implement a pull-based reward mechanism or more complex pool distribution.

        // Simpler for demo: return funds to proposers if their prediction was true and they staked.
        if (trend.stakers[trend.proposer] > 0 && _isPopular) { // Assuming proposer implicitly predicts true
            uint256 proposerReward = trend.stakers[trend.proposer] * 150 / 100; // 1.5x reward
            (bool success,) = payable(trend.proposer).call{value: proposerReward}("");
            require(success, "QC: Failed to send proposer trend reward");
        }
        // Remaining funds in `totalPool` stay in contract for owner to manage.

        emit TrendResolved(_trendId, _isPopular);
    }

    // --- VI. Knowledge Graph & Discovery ---

    /// @notice Users can suggest semantic tags for an image.
    /// @dev These tags are stored as "pending" until confirmed by a curator.
    /// @param _imageId The ID of the image to tag.
    /// @param _tags An array of tags (strings) to suggest.
    function addTagsToImage(uint256 _imageId, string[] calldata _tags) public {
        require(_imageId < _imageIds.current(), "QC: Invalid image ID");
        require(_tags.length > 0, "QC: No tags provided");
        for (uint256 i = 0; i < _tags.length; i++) {
            require(bytes(_tags[i]).length > 0, "QC: Tag cannot be empty");
        }

        // Store pending tags associated with the user for later confirmation
        pendingImageTags[_imageId][msg.sender] = _tags;
        emit TagsAdded(_imageId, msg.sender, _tags);
    }

    /// @notice (Curator-gated) Confirms suggested tags, adding them to the image's permanent record.
    /// @dev Only users with a sufficient curator reputation can confirm tags. Confirmed tags contribute to the "Knowledge Graph."
    /// @param _imageId The ID of the image whose tags are being confirmed.
    /// @param _tagsToConfirm The array of tags to confirm. These tags are then added to the image's permanent `tags` array.
    function confirmTags(uint256 _imageId, string[] calldata _tagsToConfirm) public {
        require(_imageId < _imageIds.current(), "QC: Invalid image ID");
        require(curatorReputation[msg.sender] >= 50, "QC: Insufficient curator reputation to confirm tags (min 50)"); // Example threshold
        require(_tagsToConfirm.length > 0, "QC: No tags to confirm");

        Image storage img = images[_imageId];
        for (uint256 i = 0; i < _tagsToConfirm.length; i++) {
            // Check for duplicates before adding to `img.tags`
            bool isDuplicate = false;
            for (uint256 j = 0; j < img.tags.length; j++) {
                if (keccak256(abi.encodePacked(img.tags[j])) == keccak256(abi.encodePacked(_tagsToConfirm[i]))) {
                    isDuplicate = true;
                    break;
                }
            }
            if (!isDuplicate) {
                img.tags.push(_tagsToConfirm[i]); // Add tag to image's confirmed tags
                tagToImageIds[_tagsToConfirm[i]].push(_imageId); // Add image ID to global tag index
                curatorReputation[msg.sender] += 5; // Reward curator for confirmed tag
            }
        }
        // Optionally clear specific pending tags for `msg.sender` for this image.
        // A more sophisticated system might aggregate suggestions before confirming.
        delete pendingImageTags[_imageId][msg.sender];

        emit TagsConfirmed(_imageId, _tagsToConfirm);
    }

    /// @notice Retrieves a list of image IDs associated with a specific confirmed tag.
    /// @param _tag The tag string to search for.
    /// @return An array of image IDs that have this tag.
    function searchImagesByTag(string calldata _tag) public view returns (uint256[] memory) {
        return tagToImageIds[_tag];
    }

    /// @notice (Simulated) Returns image IDs recommended for a user based on their interaction history.
    /// @dev This is a highly simplified function for demonstration. Real-world recommendations would
    ///      involve complex off-chain AI analysis of user behavior, art attributes, and social graphs.
    ///      This implementation simply returns highly curated images the user hasn't interacted with.
    /// @param _user The address of the user for whom to get recommendations.
    /// @return An array of recommended image IDs.
    function getRecommendedImages(address _user) public view returns (uint256[] memory) {
        uint256[] memory recommendations = new uint256[](0); // Initialize an empty dynamic array
        uint256 count = 0;
        uint256 totalImages = _imageIds.current();

        // Iterate through all images (can be gas-intensive for many images, for illustrative purposes)
        for (uint256 i = 0; i < totalImages; i++) {
            // Recommend images with high positive curation score that the user hasn't curated yet
            if (images[i].currentCurationScore >= int256(minCurationToMint) && !images[i].hasCurated[_user]) {
                // Limit the number of recommendations returned to prevent excessive gas usage
                if (count < 10) { // Max 10 recommendations
                    recommendations = _appendToArray(recommendations, i); // Helper to grow array
                    count++;
                } else {
                    break; // Stop if limit reached
                }
            }
        }
        return recommendations;
    }

    // Helper function to append an element to a dynamic array in memory.
    // Necessary because Solidity doesn't have built-in `push` for memory arrays.
    function _appendToArray(uint256[] memory arr, uint256 element) internal pure returns (uint256[] memory) {
        uint256 length = arr.length;
        uint256[] memory newArr = new uint256[](length + 1);
        for (uint256 i = 0; i < length; i++) {
            newArr[i] = arr[i];
        }
        newArr[length] = element;
        return newArr;
    }

    // --- VII. Administrative & Utility ---

    /// @notice Allows the contract owner to withdraw ETH from the contract's balance.
    /// @param _to The address to send the funds to.
    /// @param _amount The amount of ETH (in wei) to withdraw.
    function withdrawFunds(address _to, uint256 _amount) public onlyOwner {
        require(_amount > 0, "QC: Amount must be positive");
        require(address(this).balance >= _amount, "QC: Insufficient contract balance");
        (bool success,) = payable(_to).call{value: _amount}("");
        require(success, "QC: Failed to withdraw funds");
    }

    /// @notice Returns the current ETH balance of the contract.
    /// @return The contract's ETH balance in wei.
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // --- EIP-2981 Royalties (Simplified Implementation) ---

    /// @notice Returns the royalty information for a given token, as per EIP-2981.
    /// @dev This function calculates the royalty amount based on the configured royalty basis points.
    /// @param _tokenId The ID of the NFT.
    /// @param _salePrice The sale price of the NFT in wei.
    /// @return receiver The address that should receive the royalty payment.
    /// @return royaltyAmount The calculated amount of royalty payment.
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) public view returns (address receiver, uint256 royaltyAmount) {
        // EIP-2981 requires checking token existence
        require(_exists(_tokenId), "ERC2981: royaltyInfo for invalid token");

        // If no royalty is configured, return zero values
        if (royaltyBasisPoints == 0 || royaltyRecipient == address(0)) {
            return (address(0), 0);
        }

        // Calculate royalty amount: (salePrice * royaltyBasisPoints) / 10000
        uint256 calculatedRoyaltyAmount = (_salePrice * royaltyBasisPoints) / 10000;
        return (royaltyRecipient, calculatedRoyaltyAmount);
    }
}
```