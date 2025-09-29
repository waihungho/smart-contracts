This smart contract, named **AetherForge**, is designed as a decentralized platform for the creation, curation, and ownership of AI-assisted generative digital assets (NFTs). It incorporates several advanced, creative, and trendy concepts:

1.  **AI Oracle Integration:** Manages requests for off-chain AI generation and on-chain fulfillment of results, bridging the gap between AI models and blockchain.
2.  **Decentralized Creator/Curator Reputation:** Introduces a non-transferable reputation score (akin to a Soulbound Token concept) for creators and curators, influencing their participation and voting power.
3.  **Community-Driven Curation:** Implements a DAO-like voting system for community members to approve or reject AI-generated assets before they can be minted, ensuring quality and alignment with guild standards.
4.  **Dynamic Royalty Distribution:** Allows for flexible and on-chain management of royalty splits between the creator, the guild's community pool, and potential liquidity pools from secondary sales.
5.  **Adaptive Licensing & Usage Rights:** Enables granular, on-chain granting and revocation of specific usage rights (e.g., commercial use, derivative work) for NFTs, making ownership rights more programmable and flexible.
6.  **AI Compute Resource Management:** Provides a mechanism for funding off-chain AI computation costs using a dedicated ERC20 token.
7.  **On-chain Governance for Parameters:** A simplified DAO structure allows community members (based on reputation and token holdings) to propose and vote on key platform parameters.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // For AI compute funding and voting tokens

/**
 * @title AetherForge
 * @dev A decentralized platform for AI-assisted generative asset creation, curation, and ownership.
 *      It empowers creators to mint unique digital assets derived from AI models,
 *      managed through a community-driven guild system with dynamic royalties and adaptive licensing.
 *
 * Outline and Function Summary:
 *
 * I. Core Asset Management (ERC721 NFT)
 *    - Extends ERC721 for standard NFT operations and custom AI asset lifecycle.
 *    - `requestAIAssetGeneration`: Initiates an off-chain AI computation request by a registered creator.
 *    - `fulfillAIAssetGeneration`: Oracle callback to record AI results (e.g., IPFS CID) and metadata URI.
 *    - `mintAIAsset`: Mints an AI-generated content as an NFT after successful generation and community approval.
 *    - `updateAssetMetadata`: Allows controlled updates to specific asset metadata by its owner (e.g., for evolving NFTs).
 *    - `burnAsset`: Allows the NFT owner to burn their asset, removing it from existence.
 *
 * II. Creator & Reputation System
 *    - `registerCreatorProfile`: Allows a user to establish a non-transferable creator identity on the platform.
 *    - `updateCreatorProfile`: Updates a creator's on-chain profile name.
 *    - `getCreatorReputation`: Retrieves a creator's current reputation score.
 *    - `_incrementCreatorReputation` (internal): Increases reputation based on positive actions (e.g., successful mints, good curations).
 *    - `_decrementCreatorReputation` (internal): Decreases reputation based on negative actions (e.g., rejected curations, asset burns).
 *
 * III. Curation & Validation (DAO-like)
 *    - `submitAssetForCuration`: Proposes a generated asset for community review and approval before minting.
 *    - `voteOnCurationProposal`: Allows eligible community members to vote on active curation proposals using trusted tokens.
 *    - `finalizeCurationProposal`: Processes votes and updates the asset's status based on the outcome (approved/rejected).
 *    - `getPendingCurationProposals` (View): Returns a (placeholder) list of active curation proposals.
 *
 * IV. Dynamic Royalties & Revenue Distribution
 *    - `setRoyaltyDistributionSchema`: Defines the percentage split of royalties (creator, guild, liquidity pool) by the owner.
 *    - `collectRoyaltyPayment`: Receives and distributes royalty funds (ETH) for a specific NFT according to the schema.
 *    - `distributePooledRoyalties`: Allows the owner to distribute accumulated guild funds for operations or community incentives.
 *
 * V. Adaptive Licensing & Usage Rights
 *    - `grantAssetUsageRight`: Grants specific, granular usage rights (e.g., commercial use) for an NFT to another address.
 *    - `revokeAssetUsageRight`: Revokes previously granted usage rights by the original grantor.
 *    - `checkAssetUsageRight`: Verifies if an address holds a specific usage right for an asset.
 *
 * VI. Oracle Management & AI Compute Funding
 *    - `setAIOracleAddress`: Sets the trusted address for the AI Oracle, responsible for fulfilling generation requests.
 *    - `depositFundingForAICompute`: Allows users or the guild to deposit AI Funding Tokens to cover computational costs.
 *    - `withdrawFundingForAICompute`: Allows the AI Oracle to withdraw funds from the collective pool to pay for compute.
 *    - `getOracleRequestStatus`: Retrieves the current processing status of an AI generation request.
 *
 * VII. Governance & Parameters (Simplified DAO)
 *    - `proposeGuildParameterChange`: Initiates a proposal to modify a core guild parameter (e.g., voting thresholds).
 *    - `voteOnGuildParameterChange`: Allows eligible members to vote on active parameter change proposals.
 *    - `executeGuildParameterChange`: Executes a parameter change proposal if it passes the required voting threshold.
 *    - `getGuildParameter` (View): Retrieves the current value of a specific guild parameter.
 *
 * VIII. Utility & View Functions
 *    - `getAssetDetails` (View): Retrieves all structured details of a minted AetherForge asset.
 */
contract AetherForge is ERC721, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;

    // --- State Variables ---
    Counters.Counter private _tokenIdCounter;

    address public aiOracleAddress;
    IERC20 public trustedVoterToken; // ERC20 token used for voting power
    IERC20 public aiFundingToken;    // ERC20 token used to pay for AI compute

    // Governance parameters (can be changed via proposals)
    uint256 public curationVoteThresholdPercent = 60; // % approval needed for asset curation
    uint256 public guildVoteThresholdPercent = 65;    // % approval needed for guild parameter changes
    uint256 public guildVoteDurationBlocks = 10000;   // Voting period in blocks (approx. ~1.3 days at 13s/block)
    uint256 public minReputationForVoting = 100;     // Minimum reputation to be eligible to vote

    // --- Data Structures ---

    enum AssetStatus {
        Requested,              // AI generation requested
        Generated,              // AI result received from oracle
        SubmittedForCuration,   // Waiting for community review
        ApprovedForMint,        // Community approved, ready to mint
        Rejected,               // Community rejected
        Minted                  // Asset has been minted as an NFT
    }

    struct Asset {
        uint256 assetId;          // Token ID once minted
        address creator;
        string promptHash;        // Cryptographic hash of the AI prompt/parameters
        string resultCID;         // IPFS CID or similar identifier for the AI-generated content
        AssetStatus status;
        uint256 creationTimestamp;
        string metadataURI;       // URI to full NFT metadata (e.g., JSON on IPFS)
    }

    // Mapping from AI request hash to Asset details (before minting)
    mapping(bytes32 => Asset) public pendingAssets;
    mapping(uint256 => Asset) private _assets; // Token ID to Asset details after minting

    struct CreatorProfile {
        string name;
        uint256 reputationScore; // Non-transferable, increases with positive actions
        bool exists;
    }
    mapping(address => CreatorProfile) public creatorProfiles;

    enum ProposalType {
        Curation,
        GuildParameter
    }

    enum GuildParameterName {
        CurationThreshold,
        GuildThreshold,
        VoteDuration,
        MinReputationForVoting
    }

    struct CurationProposal {
        bytes32 requestId; // References the pendingAsset's requestId
        address proposer;
        uint256 startTime;
        uint256 totalVotesFor;
        uint256 totalVotesAgainst;
        mapping(address => bool) hasVoted; // Voter address => true if voted
        bool finalized;
        uint256 totalVoterTokenSupplyAtProposal; // Snapshot of total supply of trustedVoterToken
    }
    mapping(bytes32 => CurationProposal) public curationProposals;

    struct GuildParameterProposal {
        GuildParameterName paramName;
        uint256 newValue;
        address proposer;
        uint256 startTime;
        uint256 totalVotesFor;
        uint256 totalVotesAgainst;
        mapping(address => bool) hasVoted;
        bool finalized;
        uint256 totalVoterTokenSupplyAtProposal; // Snapshot
    }
    mapping(bytes32 => GuildParameterProposal) public guildParameterProposals;

    // For Adaptive Licensing - predefined usage right hashes
    bytes32 public constant USAGE_RIGHT_COMMERCIAL_USE = keccak256(abi.encodePacked("COMMERCIAL_USE"));
    bytes32 public constant USAGE_RIGHT_DERIVATIVE_WORK_ALLOWED = keccak256(abi.encodePacked("DERIVATIVE_WORK_ALLOWED"));
    bytes32 public constant USAGE_RIGHT_DISPLAY_ONLY = keccak256(abi.encodePacked("DISPLAY_ONLY"));
    bytes32 public constant USAGE_RIGHT_PUBLIC_DOMAIN = keccak256(abi.encodePacked("PUBLIC_DOMAIN"));

    // tokenId => grantorAddress => rightHash => isGranted
    mapping(uint256 => mapping(address => mapping(bytes32 => bool))) public assetUsageRights;

    // Royalty Distribution
    struct RoyaltySchema {
        uint96 creatorShareBps;      // Creator's share in basis points (e.g., 500 = 5%)
        uint96 guildShareBps;        // Guild's share for operations
        uint96 liquidityPoolShareBps; // Share for a community liquidity pool or general fund
    }
    RoyaltySchema public royaltySchema;
    uint256 public totalCollectedRoyalties; // Total royalties ever collected
    uint256 public guildPooledFunds;        // Funds held by the guild for various uses

    // AI Compute Funding: Tracks general funds available for the AI oracle to withdraw
    // Individual deposits are tracked for potential refund/accountability, but withdrawals are from collective pool.
    mapping(address => uint256) public individualAIComputeDeposits; 

    // --- Events ---
    event AIAssetGenerationRequested(bytes32 indexed requestId, address indexed creator, string promptHash);
    event AIAssetGenerationFulfilled(bytes32 indexed requestId, string resultCID, string metadataURI);
    event AssetMinted(uint256 indexed tokenId, bytes32 indexed requestId, address indexed creator, string resultCID);
    event AssetMetadataUpdated(uint256 indexed tokenId, string newMetadataURI);
    event CreatorRegistered(address indexed creator, string name);
    event CreatorReputationUpdated(address indexed creator, uint256 newReputation);
    event CurationProposalSubmitted(bytes32 indexed requestId, address indexed proposer);
    event CurationVoteCast(bytes32 indexed requestId, address indexed voter, bool support);
    event CurationProposalFinalized(bytes32 indexed requestId, bool approved);
    event RoyaltySchemaUpdated(uint96 creatorShareBps, uint96 guildShareBps, uint96 liquidityPoolShareBps);
    event RoyaltyCollected(uint256 indexed tokenId, uint256 amount, address indexed payer);
    event PooledRoyaltiesDistributed(uint256 amount, address indexed recipient);
    event UsageRightGranted(uint256 indexed tokenId, address indexed grantor, address indexed grantee, bytes32 rightHash);
    event UsageRightRevoked(uint256 indexed tokenId, address indexed grantor, address indexed grantee, bytes32 rightHash);
    event AIComputeFundingDeposited(address indexed depositor, uint256 amount);
    event AIComputeFundingWithdrawn(address indexed recipient, uint256 amount);
    event GuildParameterPropose(bytes32 indexed proposalId, GuildParameterName paramName, uint256 newValue);
    event GuildParameterVoteCast(bytes32 indexed proposalId, address indexed voter, bool support);
    event GuildParameterExecuted(bytes32 indexed proposalId, GuildParameterName paramName, uint256 newValue);


    // --- Constructor ---
    constructor(address _aiOracleAddress, address _trustedVoterToken, address _aiFundingToken)
        ERC721("AetherForge AI Asset", "AFAIA")
        Ownable(msg.sender)
    {
        require(_aiOracleAddress != address(0), "Invalid AI Oracle address");
        require(_trustedVoterToken != address(0), "Invalid Voter Token address");
        require(_aiFundingToken != address(0), "Invalid AI Funding Token address");

        aiOracleAddress = _aiOracleAddress;
        trustedVoterToken = IERC20(_trustedVoterToken);
        aiFundingToken = IERC20(_aiFundingToken);

        // Set default royalty schema: e.g., 5% creator, 3% guild, 2% LP. Total royalty assumed 10%.
        royaltySchema = RoyaltySchema({
            creatorShareBps: 500, // 5%
            guildShareBps: 300,   // 3%
            liquidityPoolShareBps: 200 // 2%
        });
        require(royaltySchema.creatorShareBps + royaltySchema.guildShareBps + royaltySchema.liquidityPoolShareBps <= 10000, "Invalid initial royalty schema sum");
    }

    // --- Modifiers ---
    modifier onlyAIOracle() {
        require(msg.sender == aiOracleAddress, "Only AI Oracle can call this function");
        _;
    }

    modifier onlyRegisteredCreator(address _creator) {
        require(creatorProfiles[_creator].exists, "Creator profile does not exist");
        _;
    }

    modifier canVote(address _voter) {
        require(creatorProfiles[_voter].exists, "Voter must be a registered creator");
        require(creatorProfiles[_voter].reputationScore >= minReputationForVoting, "Insufficient reputation to vote");
        require(trustedVoterToken.balanceOf(_voter) > 0, "Voter must hold voter tokens");
        _;
    }

    // --- I. Core Asset Management (ERC721 NFT) ---

    /**
     * @dev Creator requests an AI asset generation. This triggers an off-chain process.
     * @param _promptHash A cryptographic hash of the AI prompt and parameters.
     * @return requestId A unique identifier for this AI generation request.
     */
    function requestAIAssetGeneration(string calldata _promptHash)
        external
        onlyRegisteredCreator(msg.sender)
        returns (bytes32 requestId)
    {
        requestId = keccak256(abi.encodePacked(msg.sender, _promptHash, block.timestamp));
        require(pendingAssets[requestId].creator == address(0), "Request with this ID already exists.");

        pendingAssets[requestId] = Asset({
            assetId: 0, // Assigned upon minting
            creator: msg.sender,
            promptHash: _promptHash,
            resultCID: "",
            status: AssetStatus.Requested,
            creationTimestamp: block.timestamp,
            metadataURI: ""
        });

        _incrementCreatorReputation(msg.sender, 1); // Small reputation boost for engaging
        emit AIAssetGenerationRequested(requestId, msg.sender, _promptHash);
        return requestId;
    }

    /**
     * @dev AI Oracle fulfills an AI asset generation request.
     *      Records the result (e.g., IPFS CID) and metadata URI.
     * @param _requestId The ID of the original generation request.
     * @param _resultCID The content identifier (e.g., IPFS CID) of the generated asset.
     * @param _metadataURI URI for the full NFT metadata (e.g., JSON on IPFS).
     */
    function fulfillAIAssetGeneration(bytes32 _requestId, string calldata _resultCID, string calldata _metadataURI)
        external
        onlyAIOracle
    {
        Asset storage asset = pendingAssets[_requestId];
        require(asset.creator != address(0), "Request does not exist.");
        require(asset.status == AssetStatus.Requested, "Asset not in 'Requested' state.");
        require(bytes(_resultCID).length > 0, "Result CID cannot be empty.");
        require(bytes(_metadataURI).length > 0, "Metadata URI cannot be empty.");

        asset.resultCID = _resultCID;
        asset.metadataURI = _metadataURI;
        asset.status = AssetStatus.Generated;

        _incrementCreatorReputation(asset.creator, 5); // Larger boost for successful generation
        emit AIAssetGenerationFulfilled(_requestId, _resultCID, _metadataURI);
    }

    /**
     * @dev Mints an AI-generated asset as an NFT.
     *      Requires the asset to be in 'ApprovedForMint' status.
     * @param _requestId The ID of the approved generation request.
     */
    function mintAIAsset(bytes32 _requestId) external nonReentrant {
        Asset storage asset = pendingAssets[_requestId];
        require(asset.creator != address(0), "Request does not exist.");
        require(asset.creator == msg.sender, "Only the creator can mint their asset.");
        require(asset.status == AssetStatus.ApprovedForMint, "Asset must be approved for minting.");

        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();

        _safeMint(msg.sender, newItemId);
        _setTokenURI(newItemId, asset.metadataURI);

        asset.assetId = newItemId;
        asset.status = AssetStatus.Minted;
        _assets[newItemId] = asset; // Store in minted assets mapping

        // `pendingAssets` still holds the historical data with status `Minted`.
        _incrementCreatorReputation(msg.sender, 10); // Significant boost for a minted asset
        emit AssetMinted(newItemId, _requestId, msg.sender, asset.resultCID);
    }

    /**
     * @dev Allows the owner of an NFT to update its metadata URI.
     *      Can be used for evolving NFTs or correcting metadata errors.
     * @param _tokenId The ID of the NFT to update.
     * @param _newMetadataURI The new URI for the NFT's metadata.
     */
    function updateAssetMetadata(uint256 _tokenId, string calldata _newMetadataURI) external {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "Only owner or approved can update metadata.");
        require(bytes(_newMetadataURI).length > 0, "New metadata URI cannot be empty.");

        Asset storage asset = _assets[_tokenId];
        require(asset.creator != address(0), "Asset does not exist.");

        asset.metadataURI = _newMetadataURI;
        _setTokenURI(_tokenId, _newMetadataURI);

        emit AssetMetadataUpdated(_tokenId, _newMetadataURI);
    }

    /**
     * @dev Allows the owner of an NFT to burn their asset.
     *      This removes the NFT from existence and from the _assets mapping.
     * @param _tokenId The ID of the NFT to burn.
     */
    function burnAsset(uint256 _tokenId) external {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "Only owner or approved can burn asset.");

        Asset storage asset = _assets[_tokenId];
        require(asset.creator != address(0), "Asset does not exist.");

        _burn(_tokenId);
        delete _assets[_tokenId]; // Remove from our custom asset mapping

        // Find and update the pending asset status to burned if possible for record keeping,
        // though `_assets` is the source of truth post-mint.
        // This part is complex because `pendingAssets` is keyed by `requestId`, not `tokenId`.
        // A real system would link these or manage history differently.
        // For simplicity, we just delete the minted record.

        _decrementCreatorReputation(asset.creator, 5); // Small reputation penalty for burning
    }


    // --- II. Creator & Reputation System ---

    /**
     * @dev Allows a user to register as a creator on the platform.
     *      Each address can only register once.
     * @param _name The desired public name for the creator.
     */
    function registerCreatorProfile(string calldata _name) external {
        require(!creatorProfiles[msg.sender].exists, "Creator already registered.");
        require(bytes(_name).length > 0, "Creator name cannot be empty.");

        creatorProfiles[msg.sender] = CreatorProfile({
            name: _name,
            reputationScore: 0,
            exists: true
        });

        emit CreatorRegistered(msg.sender, _name);
    }

    /**
     * @dev Allows a registered creator to update their profile name.
     * @param _newName The new desired public name.
     */
    function updateCreatorProfile(string calldata _newName) external onlyRegisteredCreator(msg.sender) {
        require(bytes(_newName).length > 0, "New creator name cannot be empty.");
        creatorProfiles[msg.sender].name = _newName;
    }

    /**
     * @dev Returns the reputation score of a given creator.
     * @param _creator The address of the creator.
     * @return The current reputation score.
     */
    function getCreatorReputation(address _creator) external view returns (uint256) {
        return creatorProfiles[_creator].reputationScore;
    }

    /**
     * @dev Internal function to increment a creator's reputation score.
     *      Used after positive actions within the platform.
     */
    function _incrementCreatorReputation(address _creator, uint256 _amount) internal {
        if (creatorProfiles[_creator].exists) {
            creatorProfiles[_creator].reputationScore += _amount;
            emit CreatorReputationUpdated(_creator, creatorProfiles[_creator].reputationScore);
        }
    }

    /**
     * @dev Internal function to decrement a creator's reputation score.
     *      Used after negative actions (e.g., rejected curation, burning assets).
     */
    function _decrementCreatorReputation(address _creator, uint256 _amount) internal {
        if (creatorProfiles[_creator].exists) {
            creatorProfiles[_creator].reputationScore = (creatorProfiles[_creator].reputationScore > _amount) ?
                                                        (creatorProfiles[_creator].reputationScore - _amount) : 0;
            emit CreatorReputationUpdated(_creator, creatorProfiles[_creator].reputationScore);
        }
    }


    // --- III. Curation & Validation (DAO-like) ---

    /**
     * @dev Submits a generated asset for community curation before it can be minted.
     *      Only assets in 'Generated' status can be submitted.
     * @param _requestId The ID of the AI generation request to be curated.
     */
    function submitAssetForCuration(bytes32 _requestId) external onlyRegisteredCreator(msg.sender) {
        Asset storage asset = pendingAssets[_requestId];
        require(asset.creator == msg.sender, "Only the creator can submit their asset for curation.");
        require(asset.status == AssetStatus.Generated, "Asset must be in 'Generated' status.");
        require(curationProposals[_requestId].proposer == address(0), "Curation proposal already exists for this request.");

        asset.status = AssetStatus.SubmittedForCuration;

        curationProposals[_requestId] = CurationProposal({
            requestId: _requestId,
            proposer: msg.sender,
            startTime: block.timestamp,
            totalVotesFor: 0,
            totalVotesAgainst: 0,
            finalized: false,
            totalVoterTokenSupplyAtProposal: trustedVoterToken.totalSupply() // Snapshot total supply for voting power calculation
        });

        emit CurationProposalSubmitted(_requestId, msg.sender);
    }

    /**
     * @dev Allows eligible community members to vote on a curation proposal.
     *      Voting power is based on the trustedVoterToken balance.
     * @param _requestId The ID of the curation proposal.
     * @param _support True for 'for' vote, false for 'against' vote.
     */
    function voteOnCurationProposal(bytes32 _requestId, bool _support) external canVote(msg.sender) {
        CurationProposal storage proposal = curationProposals[_requestId];
        require(proposal.proposer != address(0), "Curation proposal does not exist.");
        require(!proposal.finalized, "Curation proposal has already been finalized.");
        require(block.timestamp <= proposal.startTime + guildVoteDurationBlocks * 13, "Voting period has ended."); // Approx 13s per block
        require(!proposal.hasVoted[msg.sender], "Already voted on this proposal.");

        uint256 voterTokens = trustedVoterToken.balanceOf(msg.sender);
        require(voterTokens > 0, "Voter must hold trusted voter tokens.");

        proposal.hasVoted[msg.sender] = true;
        if (_support) {
            proposal.totalVotesFor += voterTokens;
        } else {
            proposal.totalVotesAgainst += voterTokens;
            // Small penalty for voting against (to discourage malicious downvoting), or could be removed
            // _decrementCreatorReputation(proposal.proposer, 1);
        }

        emit CurationVoteCast(_requestId, msg.sender, _support);
    }

    /**
     * @dev Finalizes a curation proposal after the voting period ends.
     *      If approved, the asset status changes to 'ApprovedForMint'.
     * @param _requestId The ID of the curation proposal.
     */
    function finalizeCurationProposal(bytes32 _requestId) external {
        CurationProposal storage proposal = curationProposals[_requestId];
        require(proposal.proposer != address(0), "Curation proposal does not exist.");
        require(!proposal.finalized, "Curation proposal has already been finalized.");
        require(block.timestamp > proposal.startTime + guildVoteDurationBlocks * 13, "Voting period is still active.");

        proposal.finalized = true;

        Asset storage asset = pendingAssets[_requestId];
        uint256 totalVotes = proposal.totalVotesFor + proposal.totalVotesAgainst;

        if (totalVotes == 0) { // No votes, automatically reject (or keep pending, depending on policy).
             asset.status = AssetStatus.Rejected;
             emit CurationProposalFinalized(_requestId, false);
             _decrementCreatorReputation(asset.creator, 5); // Penalty for asset failing to gather votes/approval
             return;
        }

        if ((proposal.totalVotesFor * 100) / totalVotes >= curationVoteThresholdPercent) {
            asset.status = AssetStatus.ApprovedForMint;
            _incrementCreatorReputation(asset.creator, 10); // Boost for approved asset
            emit CurationProposalFinalized(_requestId, true);
        } else {
            asset.status = AssetStatus.Rejected;
            _decrementCreatorReputation(asset.creator, 5); // Penalty for rejected asset
            emit CurationProposalFinalized(_requestId, false);
        }
    }

    /**
     * @dev Returns a list of all active curation proposal request IDs.
     *      NOTE: This is a placeholder. In a real application, storing an array of active
     *      proposal IDs or using subgraphs/off-chain indexing would be more efficient.
     */
    function getPendingCurationProposals() external pure returns (bytes32[] memory) {
        return new bytes32[](0); // Illustrative; actual implementation requires storing proposal IDs in a dynamic array.
    }


    // --- IV. Dynamic Royalties & Revenue Distribution ---

    /**
     * @dev Allows the owner to set the royalty distribution schema.
     *      Basis points (Bps) sum must be less than or equal to 10000 (100%).
     * @param _creatorShareBps Share for the creator in basis points.
     * @param _guildShareBps Share for the guild's operational funds.
     * @param _liquidityPoolShareBps Share for a community liquidity pool or general fund.
     */
    function setRoyaltyDistributionSchema(uint96 _creatorShareBps, uint96 _guildShareBps, uint96 _liquidityPoolShareBps)
        external
        onlyOwner
    {
        require(_creatorShareBps + _guildShareBps + _liquidityPoolShareBps <= 10000, "Total shares exceed 100%");
        royaltySchema = RoyaltySchema({
            creatorShareBps: _creatorShareBps,
            guildShareBps: _guildShareBps,
            liquidityPoolShareBps: _liquidityPoolShareBps
        });
        emit RoyaltySchemaUpdated(_creatorShareBps, _guildShareBps, _liquidityPoolShareBps);
    }

    /**
     * @dev Receives and distributes royalty payments for a specific NFT.
     *      This function would typically be called by a marketplace or a wrapper contract.
     *      Assumes native currency (ETH) for simplicity.
     * @param _tokenId The ID of the NFT for which royalties are being paid.
     */
    function collectRoyaltyPayment(uint256 _tokenId) external payable nonReentrant {
        require(_assets[_tokenId].creator != address(0), "NFT does not exist or is not an AetherForge asset.");
        require(msg.value > 0, "Royalty amount must be greater than zero.");

        address creator = _assets[_tokenId].creator;
        uint256 totalRoyaltyAmount = msg.value;
        totalCollectedRoyalties += totalRoyaltyAmount;

        // Distribute to creator
        uint256 creatorPayment = (totalRoyaltyAmount * royaltySchema.creatorShareBps) / 10000;
        if (creatorPayment > 0) {
            payable(creator).transfer(creatorPayment);
        }

        // Distribute to guild pool
        uint255 guildPayment = (totalRoyaltyAmount * royaltySchema.guildShareBps) / 10000;
        if (guildPayment > 0) {
            guildPooledFunds += guildPayment; // Hold in contract for later distribution/use
        }

        // Distribute to liquidity pool (placeholder, would require specific LP integration)
        uint255 lpPayment = (totalRoyaltyAmount * royaltySchema.liquidityPoolShareBps) / 10000;
        if (lpPayment > 0) {
            // In a real scenario, this would interact with an external LP contract.
            // For this example, we'll just add it to guildPooledFunds as a general community fund.
            guildPooledFunds += lpPayment;
        }

        emit RoyaltyCollected(_tokenId, totalRoyaltyAmount, msg.sender);
    }

    /**
     * @dev Allows the owner to distribute a portion of the guild's pooled royalties.
     *      This could be for grants, operational costs, or community incentives.
     * @param _amount The amount to distribute.
     * @param _recipient The address to receive the funds.
     */
    function distributePooledRoyalties(uint256 _amount, address payable _recipient) external onlyOwner nonReentrant {
        require(_amount > 0, "Amount must be greater than zero.");
        require(guildPooledFunds >= _amount, "Insufficient pooled funds.");

        guildPooledFunds -= _amount;
        _recipient.transfer(_amount);

        emit PooledRoyaltiesDistributed(_amount, _recipient);
    }


    // --- V. Adaptive Licensing & Usage Rights ---

    /**
     * @dev Grants a specific usage right for an NFT to a target address.
     *      Only the NFT owner (or an approved operator) can grant rights.
     *      Rights are tied to the grantor, meaning if the NFT changes owner, new owner needs to re-grant.
     * @param _tokenId The ID of the NFT.
     * @param _grantee The address to which the right is granted.
     * @param _rightHash A hash representing the specific usage right (e.g., USAGE_RIGHT_COMMERCIAL_USE).
     */
    function grantAssetUsageRight(uint256 _tokenId, address _grantee, bytes32 _rightHash) external {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "Only owner or approved can grant usage rights.");
        require(_grantee != address(0), "Cannot grant rights to zero address.");
        require(_grantee != ownerOf(_tokenId), "Cannot grant rights to the owner themselves.");
        require(!assetUsageRights[_tokenId][ownerOf(_tokenId)][_rightHash], "Right already granted by current owner to this grantee."); // Check if *current owner* already granted this right

        assetUsageRights[_tokenId][ownerOf(_tokenId)][_rightHash] = true; // Store that the current owner granted this
        emit UsageRightGranted(_tokenId, ownerOf(_tokenId), _grantee, _rightHash);
    }

    /**
     * @dev Revokes a previously granted usage right for an NFT.
     *      Only the current NFT owner (or an approved operator) can revoke rights they granted.
     * @param _tokenId The ID of the NFT.
     * @param _grantee The address from which the right is to be revoked.
     * @param _rightHash The hash representing the specific usage right.
     */
    function revokeAssetUsageRight(uint256 _tokenId, address _grantee, bytes32 _rightHash) external {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "Only owner or approved can revoke usage rights.");
        require(_grantee != address(0), "Cannot revoke rights from zero address.");
        require(assetUsageRights[_tokenId][ownerOf(_tokenId)][_rightHash], "Right not granted by current owner to this grantee.");

        assetUsageRights[_tokenId][ownerOf(_tokenId)][_rightHash] = false;
        emit UsageRightRevoked(_tokenId, ownerOf(_tokenId), _grantee, _rightHash);
    }

    /**
     * @dev Checks if a specific address has a particular usage right for an NFT, granted by the current owner.
     * @param _tokenId The ID of the NFT.
     * @param _queryAddress The address to check for the right.
     * @param _rightHash The hash representing the specific usage right.
     * @return True if the right is held, false otherwise.
     */
    function checkAssetUsageRight(uint256 _tokenId, address _queryAddress, bytes32 _rightHash) external view returns (bool) {
        address currentOwner = ownerOf(_tokenId);
        // A _queryAddress has a right if the current owner granted it to them.
        return assetUsageRights[_tokenId][currentOwner][_rightHash];
    }


    // --- VI. Oracle Management & AI Compute Funding ---

    /**
     * @dev Sets the trusted AI Oracle address. Only callable by the contract owner.
     * @param _newAIOracleAddress The new address for the AI Oracle.
     */
    function setAIOracleAddress(address _newAIOracleAddress) external onlyOwner {
        require(_newAIOracleAddress != address(0), "Invalid AI Oracle address.");
        aiOracleAddress = _newAIOracleAddress;
    }

    /**
     * @dev Allows users or the guild to deposit AI Funding Tokens to cover AI computational costs.
     * @param _amount The amount of AI Funding Tokens to deposit.
     */
    function depositFundingForAICompute(uint256 _amount) external {
        require(_amount > 0, "Deposit amount must be greater than zero.");
        require(aiFundingToken.transferFrom(msg.sender, address(this), _amount), "Token transfer failed.");
        individualAIComputeDeposits[msg.sender] += _amount; // Track individual contributions (for potential refunds/audits)
        emit AIComputeFundingDeposited(msg.sender, _amount);
    }

    /**
     * @dev Allows the AI Oracle to withdraw deposited AI Funding Tokens to pay for compute.
     *      The Oracle withdraws from the collective pool, not individual deposits directly.
     * @param _amount The amount of AI Funding Tokens to withdraw.
     */
    function withdrawFundingForAICompute(uint256 _amount) external onlyAIOracle {
        require(_amount > 0, "Withdrawal amount must be greater than zero.");
        uint256 contractBalance = aiFundingToken.balanceOf(address(this));
        require(contractBalance >= _amount, "Insufficient funds in contract for withdrawal.");

        require(aiFundingToken.transfer(msg.sender, _amount), "Token withdrawal failed.");
        // This withdrawal model assumes a shared pool, without complex individual account tracking for withdrawals.
        emit AIComputeFundingWithdrawn(msg.sender, _amount);
    }

    /**
     * @dev Retrieves the current status of an AI generation request.
     * @param _requestId The ID of the AI generation request.
     * @return The current AssetStatus of the request.
     */
    function getOracleRequestStatus(bytes32 _requestId) external view returns (AssetStatus) {
        return pendingAssets[_requestId].status;
    }


    // --- VII. Governance & Parameters (Simplified DAO) ---

    /**
     * @dev Proposes a change to a core guild parameter.
     *      Only registered creators with sufficient reputation can propose.
     * @param _paramName The name of the parameter to change.
     * @param _newValue The new value for the parameter.
     * @return proposalId A unique identifier for the proposal.
     */
    function proposeGuildParameterChange(GuildParameterName _paramName, uint256 _newValue)
        external
        onlyRegisteredCreator(msg.sender)
        returns (bytes32 proposalId)
    {
        require(creatorProfiles[msg.sender].reputationScore >= minReputationForVoting, "Insufficient reputation to propose.");

        // Additional checks for valid new values for specific parameters
        if (_paramName == GuildParameterName.CurationThreshold || _paramName == GuildParameterName.GuildThreshold) {
            require(_newValue <= 100, "Threshold cannot exceed 100%");
        } else if (_paramName == GuildParameterName.VoteDuration) {
            require(_newValue > 0, "Vote duration must be positive");
        }

        proposalId = keccak256(abi.encodePacked(block.timestamp, msg.sender, uint256(_paramName), _newValue));
        require(guildParameterProposals[proposalId].startTime == 0, "Proposal with this ID already exists."); // startTime=0 indicates uninitialized

        guildParameterProposals[proposalId] = GuildParameterProposal({
            paramName: _paramName,
            newValue: _newValue,
            proposer: msg.sender,
            startTime: block.timestamp,
            totalVotesFor: 0,
            totalVotesAgainst: 0,
            finalized: false,
            totalVoterTokenSupplyAtProposal: trustedVoterToken.totalSupply()
        });

        emit GuildParameterPropose(proposalId, _paramName, _newValue);
        return proposalId;
    }

    /**
     * @dev Allows eligible members to vote on a guild parameter change proposal.
     * @param _proposalId The ID of the guild parameter proposal.
     * @param _support True for 'for' vote, false for 'against' vote.
     */
    function voteOnGuildParameterChange(bytes32 _proposalId, bool _support) external canVote(msg.sender) {
        GuildParameterProposal storage proposal = guildParameterProposals[_proposalId];
        require(proposal.startTime != 0, "Guild parameter proposal does not exist.");
        require(!proposal.finalized, "Guild parameter proposal has already been finalized.");
        require(block.timestamp <= proposal.startTime + guildVoteDurationBlocks * 13, "Voting period has ended.");
        require(!proposal.hasVoted[msg.sender], "Already voted on this proposal.");

        uint256 voterTokens = trustedVoterToken.balanceOf(msg.sender);
        require(voterTokens > 0, "Voter must hold trusted voter tokens.");

        proposal.hasVoted[msg.sender] = true;
        if (_support) {
            proposal.totalVotesFor += voterTokens;
        } else {
            proposal.totalVotesAgainst += voterTokens;
        }

        emit GuildParameterVoteCast(_proposalId, msg.sender, _support);
    }

    /**
     * @dev Executes a guild parameter change proposal if it has passed the voting threshold.
     *      Currently, only the owner can trigger execution, but the decision itself is decentralized.
     * @param _proposalId The ID of the guild parameter proposal.
     */
    function executeGuildParameterChange(bytes32 _proposalId) external onlyOwner {
        GuildParameterProposal storage proposal = guildParameterProposals[_proposalId];
        require(proposal.startTime != 0, "Guild parameter proposal does not exist.");
        require(!proposal.finalized, "Guild parameter proposal has already been finalized.");
        require(block.timestamp > proposal.startTime + guildVoteDurationBlocks * 13, "Voting period is still active.");

        proposal.finalized = true;

        uint256 totalVotes = proposal.totalVotesFor + proposal.totalVotesAgainst;
        if (totalVotes == 0 || (proposal.totalVotesFor * 100) / totalVotes < guildVoteThresholdPercent) {
            emit GuildParameterExecuted(_proposalId, proposal.paramName, 0); // 0 indicates rejection/no change
            return;
        }

        // Execute the parameter change
        if (proposal.paramName == GuildParameterName.CurationThreshold) {
            require(proposal.newValue <= 100, "Threshold cannot exceed 100%");
            curationVoteThresholdPercent = proposal.newValue;
        } else if (proposal.paramName == GuildParameterName.GuildThreshold) {
            require(proposal.newValue <= 100, "Threshold cannot exceed 100%");
            guildVoteThresholdPercent = proposal.newValue;
        } else if (proposal.paramName == GuildParameterName.VoteDuration) {
            require(proposal.newValue > 0, "Duration must be positive");
            guildVoteDurationBlocks = proposal.newValue;
        } else if (proposal.paramName == GuildParameterName.MinReputationForVoting) {
            minReputationForVoting = proposal.newValue;
        }

        emit GuildParameterExecuted(_proposalId, proposal.paramName, proposal.newValue);
    }

    /**
     * @dev Retrieves the current value of a guild parameter.
     * @param _paramName The name of the guild parameter.
     * @return The current value of the parameter.
     */
    function getGuildParameter(GuildParameterName _paramName) external view returns (uint256) {
        if (_paramName == GuildParameterName.CurationThreshold) {
            return curationVoteThresholdPercent;
        } else if (_paramName == GuildParameterName.GuildThreshold) {
            return guildVoteThresholdPercent;
        } else if (_paramName == GuildParameterName.VoteDuration) {
            return guildVoteDurationBlocks;
        } else if (_paramName == GuildParameterName.MinReputationForVoting) {
            return minReputationForVoting;
        }
        revert("Invalid parameter name");
    }


    // --- VIII. Utility & View Functions ---

    /**
     * @dev Retrieves all structured details of a minted AetherForge asset.
     * @param _tokenId The ID of the minted NFT.
     * @return A struct containing all asset details.
     */
    function getAssetDetails(uint256 _tokenId) external view returns (Asset memory) {
        require(_assets[_tokenId].creator != address(0), "Asset does not exist.");
        return _assets[_tokenId];
    }
}

```