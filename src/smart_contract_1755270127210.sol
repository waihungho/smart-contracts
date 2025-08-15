Okay, this is an ambitious request! Creating a truly novel smart contract concept that is also "advanced, creative, trendy" and has 20+ non-duplicative functions, all while avoiding existing open-source projects, is a significant challenge. Most advanced concepts (DAOs, NFTs, oracles) have open-source implementations.

My approach will be to combine several advanced concepts in a *novel way* to form a unique protocol, rather than inventing entirely new primitives. I will use standard, battle-tested OpenZeppelin libraries for basic ERC20/ERC721/AccessControl functionalities (as re-implementing these poorly would be counterproductive and insecure). The "non-duplication" directive will apply to the *core business logic and architecture* of the system.

Let's imagine a protocol called **"CogniVerse Protocol - AI-Enhanced Dynamic Asset & Curatorial DAO"**.

**Core Idea:**
A decentralized protocol where users can register digital assets as NFTs (`ContentNFTs`). These NFTs are not static; their properties and metadata can *dynamically evolve* based on AI oracle insights and community curation. The protocol includes a native token (`COGN`) for governance, staking, and participation in a reputation-driven curation system.

---

## CogniVerse Protocol: AI-Enhanced Dynamic Asset & Curatorial DAO

**Disclaimer:** This contract utilizes standard, audited OpenZeppelin libraries for foundational ERC20, ERC721, and access control functionalities. The "non-duplication of open source" directive is interpreted as designing a unique *combination* of advanced concepts and novel *business logic*, rather than re-implementing basic token standards.

---

### Outline

**I. Core Protocol & Token Management**
   A. `COGNToken` (ERC20): The native utility and governance token.
   B. `ContentNFT` (ERC721): Non-fungible tokens representing dynamic digital assets with mutable metadata.
   C. Access Control & Global Parameters: Owner/DAO-controlled settings for the protocol.

**II. AI Oracle & Dynamic Asset Lifecycle**
   A. NFT Registration: Users mint `ContentNFTs` with initial content references.
   B. AI Enhancement Requests: NFT owners can request AI analysis/modification for their NFTs.
   C. AI Oracle Integration: A trusted oracle submits AI-generated outcomes.
   D. Owner Approval: NFT owners review and approve AI-proposed changes to their assets.
   E. Global AI Insights: Oracle provides broader market/thematic insights for community context.

**III. Community Curation & Reputation System**
   A. Curator Staking: Users stake `COGN` to become eligible for content curation.
   B. Content Rating: Curators provide ratings for `ContentNFTs`, aiming for alignment with AI insights.
   C. Challenge & Dispute Resolution: Mechanism for users to challenge curator ratings, resolved by DAO/moderators.
   D. Reputation & Rewards: Curators gain/lose reputation based on challenge outcomes and accrue rewards.

**IV. Decentralized Governance (DAO)**
   A. Proposal Creation: `COGN` holders can propose changes to protocol parameters, oracle addresses, etc.
   B. Voting Mechanism: `COGN` holders vote on proposals with delegated voting power.
   C. Proposal Execution: Successful proposals are executed on-chain.

**V. Economic Model & Incentives**
   A. Dynamic Fee Configuration: Fees for actions like AI enhancements are dynamically set by the DAO.
   B. Reward Pool: Accrued fees and potential protocol inflation are used to reward active participants.

---

### Function Summary (24 Functions)

**I. Core Protocol & Token Management**
1.  **`constructor()`**: Initializes the `COGN` token, `ContentNFT` contract, and sets initial protocol parameters and ownership.
2.  **`setAIAccessOracle(address _newOracle)`**: (DAO/Admin) Sets the trusted address authorized to submit AI insights and outcomes.
3.  **`updateDynamicFee(string memory _feeType, uint256 _newFee)`**: (DAO) Adjusts specific dynamic fees within the protocol (e.g., AI enhancement fee, curation challenge fee).
4.  **`setModerator(address _moderator, bool _isModerator)`**: (DAO) Grants or revokes a moderator role, assisting in dispute resolution.
5.  **`recoverExcessFunds(address _tokenAddress)`**: (DAO) Allows the protocol to recover accidentally sent ERC20 tokens not meant for its operation.

**II. AI Oracle & Dynamic Asset Lifecycle**
6.  **`registerContentNFT(string memory _initialContentURI, string memory _metadataHash)`**: Mints a new `ContentNFT` for the caller, linking it to initial immutable content and mutable metadata.
7.  **`requestAIEnhancement(uint256 _tokenId, string memory _enhancementRequestHint)`**: Allows a `ContentNFT` owner to request an AI-driven enhancement for their NFT, paying a dynamic fee.
8.  **`submitAIEnhancementOutcome(uint256 _tokenId, string memory _newContentURI, string memory _newMetadataHash, uint256 _insightScore)`**: (Oracle-only) The AI oracle submits its proposed new state (content URI, metadata hash) for an NFT and an associated AI "insight score."
9.  **`approveAIEnhancement(uint256 _tokenId)`**: The `ContentNFT` owner approves the AI's proposed enhancement, permanently updating their NFT's on-chain metadata.
10. **`declineAIEnhancement(uint256 _tokenId)`**: The `ContentNFT` owner declines the AI's proposed enhancement, discarding the outcome but forfeiting the fee.
11. **`submitGlobalAIInsight(string memory _insightURI, uint256 _sentimentScore)`**: (Oracle-only) Submits broader, general AI insights (e.g., market trends, thematic analyses) relevant to the entire protocol.
12. **`burnContentNFT(uint256 _tokenId)`**: Allows the owner of a `ContentNFT` to permanently destroy (burn) their NFT.

**III. Community Curation & Reputation System**
13. **`stakeCOGNForCuration(uint256 _amount)`**: Users stake `COGN` tokens to become active curators and gain eligibility for reputation and rewards.
14. **`submitContentRating(uint256 _tokenId, int256 _rating, string memory _justificationURI)`**: Active curators rate `ContentNFTs` based on their perceived quality or alignment with global AI insights.
15. **`challengeContentRating(uint256 _tokenId, address _curator, string memory _challengeReasonURI)`**: A user can challenge a specific curator's rating, paying a dynamic fee to initiate a dispute.
16. **`resolveContentChallenge(uint256 _tokenId, address _curator, bool _challengeSuccessful)`**: (DAO/Moderator) Resolves a content rating challenge, adjusting the curator's reputation based on the outcome.
17. **`claimCurationRewards()`**: Allows curators to claim their accumulated `COGN` rewards based on their reputation and successful curation history.
18. **`withdrawStakedCOGN(uint256 _amount)`**: Allows curators to unstake their `COGN` after a defined cooldown period.
19. **`getCuratorReputation(address _curator)`**: Retrieves the current reputation score of a specific curator.
20. **`getContentInsights(uint256 _tokenId)`**: Returns the latest AI insight score and a simplified representation of the aggregated community rating for a specific `ContentNFT`.

**IV. Decentralized Governance (DAO)**
21. **`proposeProtocolChange(string memory _description, bytes memory _calldata, address _targetAddress)`**: `COGN` holders meeting a threshold can create new governance proposals for various protocol modifications.
22. **`voteOnProposal(uint256 _proposalId, bool _support)`**: `COGN` holders cast their votes (for or against) on active proposals, using their delegated voting power.
23. **`delegateVotingPower(address _delegatee)`**: Allows a `COGN` holder to delegate their voting power to another address for future proposals.
24. **`executeProposal(uint256 _proposalId)`**: Executes a proposal that has successfully passed the voting period, met quorum, and received majority 'for' votes.

---
---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title CogniVerse Protocol
 * @dev An AI-Enhanced Dynamic Asset & Curatorial DAO
 *
 * This contract orchestrates a decentralized protocol for managing dynamic digital assets (ContentNFTs)
 * and their curation. It integrates AI oracle inputs, a community-driven reputation system, and a robust
 * governance DAO.
 *
 * Key Concepts:
 * - Dynamic ContentNFTs: NFTs whose metadata and properties can evolve based on AI insights and owner approval.
 * - AI Oracle Integration: A trusted oracle (simulated here) provides AI-driven insights for enhancements and global trends.
 * - Community Curation: Users stake COGN tokens to gain curation rights, rating content and building reputation.
 * - Reputation System: Curators gain or lose reputation based on the alignment of their ratings with AI insights and community consensus.
 * - Decentralized Governance: A DAO governs protocol parameters, AI oracle addresses, and dispute resolution.
 * - Dynamic Fees & Incentives: Fees for AI enhancements and rewards for good curation are dynamically managed.
 */

// --- OUTLINE ---
// I. Core Protocol & Token Management
//    A. COGN Token (ERC20)
//    B. ContentNFT (ERC721 with Dynamic Metadata)
//    C. Access Control & Global Parameters
// II. AI Oracle & Dynamic Asset Lifecycle
//    A. NFT Registration & AI Enhancement Requests
//    B. AI Oracle Integration
//    C. Owner Approval of Enhancements
// III. Community Curation & Reputation System
//    A. Curator Staking & Rights
//    B. Content Rating & AI Alignment
//    C. Challenge & Dispute Resolution
//    D. Reputation & Reward Distribution
// IV. Decentralized Governance (DAO)
//    A. Proposal Creation & Management
//    B. Voting Mechanism (Delegated Voting)
//    C. Proposal Execution
// V. Economic Model & Incentives
//    A. Dynamic Fee Configuration
//    B. Reward Pool Management

// --- FUNCTION SUMMARY ---

// I. Core Protocol & Token Management
// 1.  constructor(): Initializes COGN token, ContentNFT, and sets initial protocol parameters.
// 2.  setAIAccessOracle(address _newOracle): (DAO/Admin) Sets the trusted AI oracle address.
// 3.  updateDynamicFee(string memory _feeType, uint256 _newFee): (DAO) Updates various dynamic fees (e.g., for AI enhancements).
// 4.  setModerator(address _moderator, bool _isModerator): (DAO) Grants or revokes moderator roles for dispute resolution.
// 5.  recoverExcessFunds(address _tokenAddress): (DAO) Allows recovery of accidentally sent tokens.

// II. AI Oracle & Dynamic Asset Lifecycle
// 6.  registerContentNFT(string memory _initialContentURI, string memory _metadataHash): Mints a new ContentNFT with initial content/metadata.
// 7.  requestAIEnhancement(uint256 _tokenId, string memory _enhancementRequestHint): Initiates an AI enhancement request for an NFT, requires dynamic fee.
// 8.  submitAIEnhancementOutcome(uint256 _tokenId, string memory _newContentURI, string memory _newMetadataHash, uint256 _insightScore): (Oracle-only) Records the AI's proposed enhancement outcome and an insight score.
// 9.  approveAIEnhancement(uint256 _tokenId): NFT owner approves and applies the AI's proposed enhancement.
// 10. declineAIEnhancement(uint256 _tokenId): NFT owner declines the AI's proposed enhancement.
// 11. submitGlobalAIInsight(string memory _insightURI, uint256 _sentimentScore): (Oracle-only) Provides broader, general AI insights to the protocol.
// 12. burnContentNFT(uint256 _tokenId): Allows ContentNFT owner to burn their NFT.

// III. Community Curation & Reputation System
// 13. stakeCOGNForCuration(uint256 _amount): Users stake COGN to become active curators and gain reputation.
// 14. submitContentRating(uint256 _tokenId, int256 _rating, string memory _justificationURI): Curators rate ContentNFTs based on quality/alignment, affecting their reputation.
// 15. challengeContentRating(uint256 _tokenId, address _curator, string memory _challengeReasonURI): Allows users to challenge a curator's rating.
// 16. resolveContentChallenge(uint256 _tokenId, address _curator, bool _challengeSuccessful): (DAO/Moderator) Resolves a content rating challenge, adjusting reputation.
// 17. claimCurationRewards(): Allows curators to claim accrued COGN rewards based on successful curation.
// 18. withdrawStakedCOGN(uint256 _amount): Allows curators to unstake their COGN after a cooldown period.
// 19. getCuratorReputation(address _curator): Retrieves the current reputation score of an address.
// 20. getContentInsights(uint256 _tokenId): Aggregates and returns AI and community insights for a specific ContentNFT.

// IV. Decentralized Governance (DAO)
// 21. proposeProtocolChange(string memory _description, bytes memory _calldata, address _targetAddress): Creates a new governance proposal for various protocol changes.
// 22. voteOnProposal(uint256 _proposalId, bool _support): COGN holders vote on active proposals.
// 23. delegateVotingPower(address _delegatee): Allows users to delegate their voting power to another address.
// 24. executeProposal(uint256 _proposalId): Executes a successful proposal once voting concludes and quorum is met.


// --- COGNToken Contract ---
contract COGNToken is ERC20 {
    constructor() ERC20("CogniVerse Token", "COGN") {
        // Initial supply for the protocol, governance, and early contributors.
        // In a real project, this would be managed by a more complex distribution
        // mechanism (e.g., vesting contracts, public sale).
        _mint(msg.sender, 1_000_000_000 * 10**decimals()); // Example: 1 Billion tokens
    }
}

// --- ContentNFT Contract ---
contract ContentNFT is ERC721 {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // Struct to hold dynamic metadata for each NFT
    struct NFTMetadata {
        string contentURI;      // IPFS/Arweave URI for the main content (can be updated)
        string metadataHash;    // Hash/URI reference of the mutable metadata JSON (can be updated)
        uint256 aiInsightScore; // Score from the AI for the current state (0-100)
    }

    mapping(uint256 => NFTMetadata) public nftMetadata;

    constructor() ERC721("CogniVerse Content NFT", "CNFT") {}

    /// @dev Mints a new ContentNFT and assigns initial metadata. Only callable by the main protocol contract.
    /// @param to The recipient address of the new NFT.
    /// @param _initialContentURI The initial URI for the content.
    /// @param _metadataHash The initial hash/URI for mutable metadata.
    /// @return The ID of the newly minted NFT.
    function mint(address to, string memory _initialContentURI, string memory _metadataHash) internal returns (uint256) {
        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();
        _safeMint(to, newItemId);
        nftMetadata[newItemId] = NFTMetadata({
            contentURI: _initialContentURI,
            metadataHash: _metadataHash,
            aiInsightScore: 0 // Initial score, will be updated by AI enhancements
        });
        emit ContentNFTRegistered(newItemId, to, _initialContentURI, _metadataHash);
        return newItemId;
    }

    /// @dev Updates the metadata of an existing ContentNFT. Only callable by the main protocol contract.
    /// @param tokenId The ID of the NFT to update.
    /// @param newContentURI The new content URI.
    /// @param newMetadataHash The new metadata hash.
    /// @param newInsightScore The new AI insight score.
    function _updateNFTMetadata(uint256 tokenId, string memory newContentURI, string memory newMetadataHash, uint256 newInsightScore) internal {
        require(_exists(tokenId), "ContentNFT: token does not exist");
        nftMetadata[tokenId].contentURI = newContentURI;
        nftMetadata[tokenId].metadataHash = newMetadataHash;
        nftMetadata[tokenId].aiInsightScore = newInsightScore;
        emit MetadataUpdated(tokenId);
    }

    /// @dev Overrides base tokenURI to reflect dynamic metadata.
    /// In a real system, this would point to a service that dynamically composes metadata JSON.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        // For simplicity, returning the base content URI. A more complete system would fetch
        // `nftMetadata[tokenId].metadataHash` and combine it with contentURI.
        return nftMetadata[tokenId].contentURI;
    }

    // Events
    event ContentNFTRegistered(uint256 indexed tokenId, address indexed owner, string initialContentURI, string metadataHash);
    event MetadataUpdated(uint256 indexed tokenId);
}


// --- CogniVerseProtocol Contract ---
contract CogniVerseProtocol is Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;

    // --- State Variables ---

    // Tokens
    COGNToken public cognToken;
    ContentNFT public contentNFT;

    // AI Oracle Management
    address public aiAccessOracle; // The trusted address that can submit AI insights

    // Dynamic Fees
    mapping(string => uint256) public dynamicFees; // e.g., "ai_enhancement_fee", "curation_challenge_fee"

    // ContentNFT Data
    // Stores pending AI enhancement requests for NFTs
    struct AIEnhancementRequest {
        address requester;
        string requestHint;
        bool fulfilled; // True if oracle has submitted an outcome
        string proposedContentURI;
        string proposedMetadataHash;
        uint256 proposedInsightScore;
        uint256 requestTimestamp;
    }
    mapping(uint256 => AIEnhancementRequest) public aiEnhancementRequests; // tokenId => request

    // Community Curation & Reputation
    struct Curator {
        uint256 stakedAmount;
        int256 reputation; // Can be positive or negative
        uint256 lastUnstakeTimestamp;
        bool isActive; // Flag to indicate if currently eligible for curation
    }
    mapping(address => Curator) public curators;
    uint256 public constant UNSTAKE_COOLDOWN_PERIOD = 7 days; // Example cooldown for unstaking

    // Stores individual content ratings by curators
    struct ContentRating {
        address curator;
        int256 rating; // e.g., -100 to 100
        string justificationURI;
        bool challenged; // True if this rating has been challenged
        uint256 timestamp;
    }
    mapping(uint256 => mapping(address => ContentRating)) public contentRatings; // tokenId => curator => rating
    mapping(uint256 => mapping(address => bool)) public hasRated; // tokenId => curator => hasRated (to prevent double rating)

    // Stores details of a challenge against a curator's rating
    struct Challenge {
        address challenger;
        string reasonURI;
        bool resolved; // True if the challenge has been processed
        bool successful; // True if the challenge was deemed valid (curator's rating was bad)
        uint256 timestamp;
    }
    mapping(uint256 => mapping(address => Challenge)) public contentChallenges; // tokenId => curator => challenge

    // DAO Governance
    struct Proposal {
        uint256 id; // Unique proposal ID
        string description;
        address targetAddress; // Contract address to call
        bytes calldataPayload; // Calldata for the function call
        uint256 voteStartTime;
        uint256 voteEndTime;
        uint256 forVotes;
        uint256 againstVotes;
        bool executed;
        mapping(address => bool) hasVoted; // Voter address => true if voted
    }
    Counters.Counter public nextProposalId; // Counter for new proposals
    mapping(uint256 => Proposal) public proposals; // Stores proposal data by ID
    mapping(address => address) public delegates; // Global delegation: delegator => delegatee

    uint256 public constant VOTING_PERIOD = 5 days; // Example voting period
    uint256 public constant PROPOSAL_THRESHOLD = 1_000 * 10**18; // Example: 1000 COGN required to propose
    uint256 public constant QUORUM_PERCENTAGE = 4; // 4% of total COGN supply needed for quorum

    // Moderation (can be appointed by DAO for dispute resolution)
    mapping(address => bool) public isModerator;

    // --- Events ---
    event NewAIAccessOracle(address indexed newOracle);
    event DynamicFeeUpdated(string feeType, uint256 newFee);
    event ModeratorStatusUpdated(address indexed moderator, bool isModerator);

    event AIEnhancementRequested(uint256 indexed tokenId, address indexed requester, string requestHint, uint256 feePaid);
    event AIEnhancementOutcomeSubmitted(uint256 indexed tokenId, string newContentURI, string newMetadataHash, uint256 insightScore);
    event AIEnhancementApproved(uint256 indexed tokenId, string finalContentURI, string finalMetadataHash, uint256 finalInsightScore);
    event AIEnhancementDeclined(uint256 indexed tokenId);
    event GlobalAIInsightSubmitted(string insightURI, uint256 sentimentScore);

    event COGNStakedForCuration(address indexed curator, uint256 amount);
    event COGNUnstakedFromCuration(address indexed curator, uint256 amount);
    event ContentRated(uint256 indexed tokenId, address indexed curator, int256 rating, string justificationURI);
    event CurationRatingChallenged(uint256 indexed tokenId, address indexed curator, address indexed challenger, string reasonURI);
    event CurationChallengeResolved(uint256 indexed tokenId, address indexed curator, address indexed resolver, bool challengeSuccessful);
    event CuratorReputationUpdated(address indexed curator, int256 newReputation);
    event CurationRewardsClaimed(address indexed curator, uint256 amount);

    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description, address target, bytes calldataPayload);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 votes);
    event VoteDelegated(address indexed delegator, address indexed delegatee);
    event ProposalExecuted(uint256 indexed proposalId);


    // --- Constructor ---
    constructor() Ownable(msg.sender) {
        // Deploy COGN token
        cognToken = new COGNToken();
        // Deploy ContentNFT
        contentNFT = new ContentNFT();

        // Transfer initial COGN supply from deployer to this contract for rewards/fees.
        // In a production setup, this would be part of a more elaborate tokenomics
        // (e.g., streaming funds, treasury management by DAO).
        require(cognToken.transferFrom(msg.sender, address(this), cognToken.balanceOf(msg.sender)), "Initial COGN transfer failed");

        // Set initial dynamic fees (can be updated by DAO)
        dynamicFees["ai_enhancement_fee"] = 10 * 10**18; // Example: 10 COGN
        dynamicFees["curation_challenge_fee"] = 5 * 10**18; // Example: 5 COGN

        // Set initial AI oracle (can be updated by DAO via proposal)
        aiAccessOracle = msg.sender; // For initial setup, owner is the oracle
        emit NewAIAccessOracle(aiAccessOracle);
    }

    // --- Modifiers ---
    /// @dev Restricts calls to the contract owner or if the DAO is considered active (has made at least one proposal).
    /// In a fully decentralized setup, ownership would likely be relinquished to the DAO's multisig.
    modifier onlyOwnerOrDAO() {
        require(msg.sender == owner() || nextProposalId.current() > 0, "CogniVerse: Only owner or DAO can call this function");
        _;
    }

    /// @dev Restricts calls to the designated AI oracle address.
    modifier onlyAIAccessOracle() {
        require(msg.sender == aiAccessOracle, "CogniVerse: Only AI oracle can call this function");
        _;
    }

    /// @dev Restricts calls to a designated moderator or the contract owner/DAO.
    modifier onlyModeratorOrDAO() {
        require(msg.sender == owner() || isModerator[msg.sender] || nextProposalId.current() > 0, "CogniVerse: Only owner, moderator, or DAO can call this function");
        _;
    }

    // --- I. Core Protocol & Token Management ---

    /// @dev Sets the address of the trusted AI oracle. Callable only by the DAO or owner initially.
    /// @param _newOracle The new address for the AI oracle.
    function setAIAccessOracle(address _newOracle) public onlyOwnerOrDAO {
        require(_newOracle != address(0), "CogniVerse: Zero address not allowed for oracle");
        aiAccessOracle = _newOracle;
        emit NewAIAccessOracle(_newOracle);
    }

    /// @dev Updates a specific dynamic fee parameter. Callable only by the DAO.
    /// @param _feeType The type of fee to update (e.g., "ai_enhancement_fee").
    /// @param _newFee The new fee amount (in COGN, scaled by decimals).
    function updateDynamicFee(string memory _feeType, uint256 _newFee) public onlyOwnerOrDAO {
        dynamicFees[_feeType] = _newFee;
        emit DynamicFeeUpdated(_feeType, _newFee);
    }

    /// @dev Grants or revokes moderator role. Moderators can assist in resolving challenges. Callable only by the DAO.
    /// @param _moderator The address to set/unset as moderator.
    /// @param _isModerator True to grant, false to revoke.
    function setModerator(address _moderator, bool _isModerator) public onlyOwnerOrDAO {
        require(_moderator != address(0), "CogniVerse: Zero address not allowed for moderator");
        isModerator[_moderator] = _isModerator;
        emit ModeratorStatusUpdated(_moderator, _isModerator);
    }

    /// @dev Allows the DAO to recover accidentally sent ERC20 tokens.
    /// @param _tokenAddress The address of the ERC20 token to recover.
    function recoverExcessFunds(address _tokenAddress) public onlyOwnerOrDAO {
        require(_tokenAddress != address(cognToken), "CogniVerse: Cannot recover COGN token itself via this function");
        ERC20 token = ERC20(_tokenAddress);
        token.transfer(owner(), token.balanceOf(address(this)));
    }


    // --- II. AI Oracle & Dynamic Asset Lifecycle ---

    /// @dev Mints a new ContentNFT, associating it with initial content and metadata.
    /// @param _initialContentURI The URI (e.g., IPFS) pointing to the initial immutable content.
    /// @param _metadataHash A hash or URI reference to the mutable metadata file (e.g., on IPFS).
    /// @return The ID of the newly minted ContentNFT.
    function registerContentNFT(string memory _initialContentURI, string memory _metadataHash) public nonReentrant returns (uint256) {
        uint256 newId = contentNFT.mint(msg.sender, _initialContentURI, _metadataHash);
        // Event `ContentNFTRegistered` is emitted by `ContentNFT.mint`
        return newId;
    }

    /// @dev Initiates an AI enhancement request for a ContentNFT. Requires payment of a dynamic fee.
    /// @param _tokenId The ID of the ContentNFT to enhance.
    /// @param _enhancementRequestHint A hint for the AI (e.g., "make it more vibrant", "generate a backstory").
    function requestAIEnhancement(uint256 _tokenId, string memory _enhancementRequestHint) public nonReentrant {
        require(contentNFT.ownerOf(_tokenId) == msg.sender, "CogniVerse: Caller is not NFT owner");
        require(aiEnhancementRequests[_tokenId].requester == address(0), "CogniVerse: An enhancement request is already pending for this NFT.");

        uint256 fee = dynamicFees["ai_enhancement_fee"];
        require(cognToken.transferFrom(msg.sender, address(this), fee), "CogniVerse: COGN transfer failed for enhancement fee");

        aiEnhancementRequests[_tokenId] = AIEnhancementRequest({
            requester: msg.sender,
            requestHint: _enhancementRequestHint,
            fulfilled: false,
            proposedContentURI: "",
            proposedMetadataHash: "",
            proposedInsightScore: 0,
            requestTimestamp: block.timestamp
        });

        emit AIEnhancementRequested(_tokenId, msg.sender, _enhancementRequestHint, fee);
    }

    /// @dev (Oracle-only) Submits the AI's proposed new state for an NFT.
    /// This function is called by the trusted AI oracle after processing an enhancement request.
    /// @param _tokenId The ID of the ContentNFT.
    /// @param _newContentURI The AI's proposed new content URI.
    /// @param _newMetadataHash The AI's proposed new metadata hash.
    /// @param _insightScore An AI-generated insight score for the proposed change (0-100).
    function submitAIEnhancementOutcome(
        uint256 _tokenId,
        string memory _newContentURI,
        string memory _newMetadataHash,
        uint256 _insightScore
    ) public onlyAIAccessOracle {
        require(aiEnhancementRequests[_tokenId].requester != address(0), "CogniVerse: No pending AI enhancement request for this NFT");
        require(!aiEnhancementRequests[_tokenId].fulfilled, "CogniVerse: Enhancement request already fulfilled");

        AIEnhancementRequest storage req = aiEnhancementRequests[_tokenId];
        req.fulfilled = true;
        req.proposedContentURI = _newContentURI;
        req.proposedMetadataHash = _newMetadataHash;
        req.proposedInsightScore = _insightScore;

        emit AIEnhancementOutcomeSubmitted(_tokenId, _newContentURI, _newMetadataHash, _insightScore);
    }

    /// @dev NFT owner approves the AI's proposed enhancement, making it official and updating the NFT.
    /// @param _tokenId The ID of the ContentNFT.
    function approveAIEnhancement(uint256 _tokenId) public nonReentrant {
        require(contentNFT.ownerOf(_tokenId) == msg.sender, "CogniVerse: Caller is not NFT owner");
        AIEnhancementRequest storage req = aiEnhancementRequests[_tokenId];
        require(req.requester != address(0) && req.fulfilled, "CogniVerse: No fulfilled AI enhancement request for this NFT");

        contentNFT._updateNFTMetadata(_tokenId, req.proposedContentURI, req.proposedMetadataHash, req.proposedInsightScore);

        delete aiEnhancementRequests[_tokenId]; // Clear the request

        emit AIEnhancementApproved(_tokenId, contentNFT.nftMetadata[_tokenId].contentURI, contentNFT.nftMetadata[_tokenId].metadataHash, contentNFT.nftMetadata[_tokenId].aiInsightScore);
    }

    /// @dev NFT owner declines the AI's proposed enhancement. The fee is consumed.
    /// @param _tokenId The ID of the ContentNFT.
    function declineAIEnhancement(uint256 _tokenId) public {
        require(contentNFT.ownerOf(_tokenId) == msg.sender, "CogniVerse: Caller is not NFT owner");
        AIEnhancementRequest storage req = aiEnhancementRequests[_tokenId];
        require(req.requester != address(0) && req.fulfilled, "CogniVerse: No fulfilled AI enhancement request for this NFT");

        delete aiEnhancementRequests[_tokenId]; // Clear the request

        emit AIEnhancementDeclined(_tokenId);
    }

    /// @dev (Oracle-only) Submits a broader, general AI insight (e.g., market trend, thematic analysis).
    /// These insights can be used by curators for better content rating alignment.
    /// @param _insightURI The URI pointing to the detailed global AI insight.
    /// @param _sentimentScore An overall sentiment score (e.g., -100 to 100) for the insight.
    function submitGlobalAIInsight(string memory _insightURI, uint256 _sentimentScore) public onlyAIAccessOracle {
        // For simplicity, we just emit an event here. A more complex system might store a history of global insights.
        emit GlobalAIInsightSubmitted(_insightURI, _sentimentScore);
    }

    /// @dev Allows the ContentNFT owner to burn their NFT.
    /// @param _tokenId The ID of the ContentNFT to burn.
    function burnContentNFT(uint256 _tokenId) public {
        require(contentNFT.ownerOf(_tokenId) == msg.sender, "CogniVerse: Only NFT owner can burn");
        // Clear any pending enhancement requests if they exist
        delete aiEnhancementRequests[_tokenId];
        // Remove metadata reference from ContentNFT contract
        delete contentNFT.nftMetadata[_tokenId];
        contentNFT.burn(_tokenId);
    }


    // --- III. Community Curation & Reputation System ---

    /// @dev Users stake COGN to become active curators and gain reputation.
    /// @param _amount The amount of COGN to stake.
    function stakeCOGNForCuration(uint256 _amount) public nonReentrant {
        require(_amount > 0, "CogniVerse: Stake amount must be greater than zero");
        require(cognToken.transferFrom(msg.sender, address(this), _amount), "CogniVerse: COGN transfer failed for staking");

        Curator storage curator = curators[msg.sender];
        curator.stakedAmount += _amount;
        curator.isActive = true; // Mark as active curator
        // New curators start with 0 reputation.

        emit COGNStakedForCuration(msg.sender, _amount);
    }

    /// @dev Curators rate ContentNFTs based on quality/alignment. Affects their reputation based on challenges.
    /// @param _tokenId The ID of the ContentNFT to rate.
    /// @param _rating The rating value (e.g., -100 to 100).
    /// @param _justificationURI A URI to an explanation for the rating.
    function submitContentRating(uint256 _tokenId, int256 _rating, string memory _justificationURI) public nonReentrant {
        require(curators[msg.sender].stakedAmount > 0, "CogniVerse: Must stake COGN to be a curator");
        require(curators[msg.sender].isActive, "CogniVerse: Curator is not active");
        require(!hasRated[_tokenId][msg.sender], "CogniVerse: You have already rated this content");
        require(_rating >= -100 && _rating <= 100, "CogniVerse: Rating must be between -100 and 100");
        require(contentNFT.ownerOf(_tokenId) != address(0), "CogniVerse: NFT does not exist.");

        contentRatings[_tokenId][msg.sender] = ContentRating({
            curator: msg.sender,
            rating: _rating,
            justificationURI: _justificationURI,
            challenged: false,
            timestamp: block.timestamp
        });
        hasRated[_tokenId][msg.sender] = true; // Mark as rated for this NFT

        emit ContentRated(_tokenId, msg.sender, _rating, _justificationURI);
    }

    /// @dev Allows users to challenge a curator's rating. Requires a fee.
    /// @param _tokenId The ID of the ContentNFT.
    /// @param _curator The address of the curator whose rating is being challenged.
    /// @param _challengeReasonURI A URI to the reason for the challenge.
    function challengeContentRating(uint256 _tokenId, address _curator, string memory _challengeReasonURI) public nonReentrant {
        require(contentRatings[_tokenId][_curator].curator != address(0), "CogniVerse: No rating found from this curator for this NFT");
        require(!contentRatings[_tokenId][_curator].challenged, "CogniVerse: This rating has already been challenged");
        require(msg.sender != _curator, "CogniVerse: Cannot challenge your own rating");

        uint256 fee = dynamicFees["curation_challenge_fee"];
        require(cognToken.transferFrom(msg.sender, address(this), fee), "CogniVerse: COGN transfer failed for challenge fee");

        contentRatings[_tokenId][_curator].challenged = true;
        contentChallenges[_tokenId][_curator] = Challenge({
            challenger: msg.sender,
            reasonURI: _challengeReasonURI,
            resolved: false,
            successful: false, // Default to false until resolved
            timestamp: block.timestamp
        });

        emit CurationRatingChallenged(_tokenId, _curator, msg.sender, _challengeReasonURI);
    }

    /// @dev (DAO/Moderator) Resolves a content rating challenge, adjusting curator reputation.
    /// @param _tokenId The ID of the ContentNFT.
    /// @param _curator The address of the curator whose rating was challenged.
    /// @param _challengeSuccessful True if the challenge is upheld (curator's rating was deemed bad), false if rejected.
    function resolveContentChallenge(uint256 _tokenId, address _curator, bool _challengeSuccessful) public nonReentrant onlyModeratorOrDAO {
        require(contentRatings[_tokenId][_curator].challenged, "CogniVerse: This rating was not challenged");
        require(!contentChallenges[_tokenId][_curator].resolved, "CogniVerse: Challenge already resolved");

        Challenge storage challenge = contentChallenges[_tokenId][_curator];
        challenge.resolved = true;
        challenge.successful = _challengeSuccessful;

        // Reputation adjustment logic (example values)
        int256 reputationChange = _challengeSuccessful ? -10 : 5; // Loses 10 rep if challenge successful, gains 5 if defends
        curators[_curator].reputation += reputationChange;
        emit CuratorReputationUpdated(_curator, curators[_curator].reputation);

        // Refund/distribute challenge fee
        uint256 fee = dynamicFees["curation_challenge_fee"];
        if (_challengeSuccessful) {
            // Challenger wins: Fee refunded to challenger. Curator might be penalized further (e.g., stake slash).
            cognToken.transfer(challenge.challenger, fee);
            // Optional: Further penalize _curator, e.g., by reducing their staked amount or increasing reputation penalty.
        } else {
            // Curator wins: Challenge fee remains in protocol (or distributed as reward).
            // For simplicity, it stays in the contract as protocol revenue.
        }
        emit CurationChallengeResolved(_tokenId, _curator, msg.sender, _challengeSuccessful);
    }

    /// @dev Allows curators to claim accrued COGN rewards based on successful curation.
    /// NOTE: This function's reward calculation is a placeholder. A robust reward model
    /// would require complex on-chain calculation based on reputation, successful ratings,
    /// and a dynamic reward pool, or rely on off-chain calculation with on-chain verification.
    function claimCurationRewards() public nonReentrant {
        require(curators[msg.sender].stakedAmount > 0, "CogniVerse: You are not an active curator");
        uint256 rewards = 0; // Placeholder for reward calculation
        // Example: rewards = (curators[msg.sender].reputation / 100) * (total_pool_share);
        // A more robust system would track eligible rewards per curator based on their activity and reputation.

        if (rewards > 0) {
            // require(cognToken.transfer(msg.sender, rewards), "CogniVerse: Reward transfer failed");
            // For now, this is a conceptual function. Uncomment and implement reward distribution in a real scenario.
            emit CurationRewardsClaimed(msg.sender, rewards);
        } else {
            revert("CogniVerse: No rewards to claim");
        }
    }

    /// @dev Allows curators to unstake their COGN after a cooldown period.
    /// @param _amount The amount of COGN to unstake.
    function withdrawStakedCOGN(uint256 _amount) public nonReentrant {
        Curator storage curator = curators[msg.sender];
        require(curator.stakedAmount >= _amount, "CogniVerse: Insufficient staked amount");
        require(block.timestamp >= curator.lastUnstakeTimestamp + UNSTAKE_COOLDOWN_PERIOD, "CogniVerse: Unstake cooldown period not over");

        curator.stakedAmount -= _amount;
        curator.lastUnstakeTimestamp = block.timestamp;

        if (curator.stakedAmount == 0) {
            curator.isActive = false; // Deactivate if no stake remains
        }

        require(cognToken.transfer(msg.sender, _amount), "CogniVerse: COGN transfer failed for unstaking");
        emit COGNUnstakedFromCuration(msg.sender, _amount);
    }

    /// @dev Retrieves the current reputation score of an address.
    /// @param _curator The address of the curator.
    /// @return The reputation score.
    function getCuratorReputation(address _curator) public view returns (int256) {
        return curators[_curator].reputation;
    }

    /// @dev Aggregates and returns AI and community insights for a specific ContentNFT.
    /// NOTE: Calculating `averageCommunityRating` by iterating over a `mapping` of unknown size
    /// is not feasible or gas-efficient in Solidity. This function returns 0 for community
    /// rating as a placeholder. In a real application, this average would be maintained
    /// incrementally, or aggregated off-chain.
    /// @param _tokenId The ID of the ContentNFT.
    /// @return The NFT's current AI insight score and the average community rating.
    function getContentInsights(uint256 _tokenId) public view returns (uint256 aiInsightScore, int256 averageCommunityRating) {
        require(contentNFT.ownerOf(_tokenId) != address(0), "CogniVerse: NFT does not exist");
        aiInsightScore = contentNFT.nftMetadata[_tokenId].aiInsightScore;

        // Placeholder for averageCommunityRating due to on-chain iteration limitations:
        // A real system would either maintain this incrementally or aggregate off-chain.
        averageCommunityRating = 0;

        return (aiInsightScore, averageCommunityRating);
    }


    // --- IV. Decentralized Governance (DAO) ---

    /// @dev Creates a new governance proposal for various protocol changes.
    /// Requires a minimum COGN stake (PROPOSAL_THRESHOLD).
    /// @param _description A description of the proposal.
    /// @param _calldata The calldata for the target function to be executed.
    /// @param _targetAddress The address of the contract to call if the proposal passes.
    /// @return The ID of the new proposal.
    function proposeProtocolChange(string memory _description, bytes memory _calldata, address _targetAddress) public nonReentrant returns (uint256) {
        require(cognToken.balanceOf(msg.sender) >= PROPOSAL_THRESHOLD, "CogniVerse: Insufficient COGN to propose");

        nextProposalId.increment();
        uint256 proposalId = nextProposalId.current();

        proposals[proposalId] = Proposal({
            id: proposalId,
            description: _description,
            targetAddress: _targetAddress,
            calldataPayload: _calldata,
            voteStartTime: block.timestamp,
            voteEndTime: block.timestamp + VOTING_PERIOD,
            forVotes: 0,
            againstVotes: 0,
            executed: false,
            hasVoted: new mapping(address => bool)
        });

        emit ProposalCreated(proposalId, msg.sender, _description, _targetAddress, _calldata);
        return proposalId;
    }

    /// @dev Allows COGN holders to vote on active proposals. Uses global delegated voting power.
    /// @param _proposalId The ID of the proposal to vote on.
    /// @param _support True for 'for' vote, false for 'against' vote.
    function voteOnProposal(uint256 _proposalId, bool _support) public nonReentrant {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "CogniVerse: Proposal does not exist"); // Check if proposal initialized
        require(block.timestamp >= proposal.voteStartTime && block.timestamp <= proposal.voteEndTime, "CogniVerse: Voting is not active");
        require(!proposal.hasVoted[msg.sender], "CogniVerse: You have already voted on this proposal");

        address currentVoter = msg.sender;
        // Resolve effective voter by following delegation chain
        while (delegates[currentVoter] != address(0) && delegates[currentVoter] != currentVoter) {
            currentVoter = delegates[currentVoter];
        }

        uint256 voteWeight = cognToken.balanceOf(currentVoter); // Voting power based on current balance
        require(voteWeight > 0, "CogniVerse: No voting power");

        if (_support) {
            proposal.forVotes += voteWeight;
        } else {
            proposal.againstVotes += voteWeight;
        }
        proposal.hasVoted[msg.sender] = true; // Mark original caller as having voted

        emit VoteCast(_proposalId, msg.sender, _support, voteWeight);
    }

    /// @dev Allows users to delegate their voting power to another address for all future proposals.
    /// @param _delegatee The address to delegate voting power to.
    function delegateVotingPower(address _delegatee) public {
        require(msg.sender != _delegatee, "CogniVerse: Cannot delegate to self");
        delegates[msg.sender] = _delegatee;
        emit VoteDelegated(msg.sender, _delegatee);
    }

    /// @dev Executes a successful proposal once voting concludes and quorum is met.
    /// Only callable after voteEndTime and if criteria are met.
    /// @param _proposalId The ID of the proposal to execute.
    function executeProposal(uint256 _proposalId) public nonReentrant {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "CogniVerse: Proposal does not exist");
        require(block.timestamp > proposal.voteEndTime, "CogniVerse: Voting period not ended");
        require(!proposal.executed, "CogniVerse: Proposal already executed");

        uint256 totalVotes = proposal.forVotes + proposal.againstVotes;
        uint256 totalCOGNSupply = cognToken.totalSupply(); // Use current total supply for quorum
        uint256 quorumThreshold = (totalCOGNSupply * QUORUM_PERCENTAGE) / 100;

        require(totalVotes >= quorumThreshold, "CogniVerse: Quorum not met");
        require(proposal.forVotes > proposal.againstVotes, "CogniVerse: Proposal did not pass");

        (bool success, ) = proposal.targetAddress.call(proposal.calldataPayload);
        require(success, "CogniVerse: Proposal execution failed");

        proposal.executed = true;
        emit ProposalExecuted(_proposalId);
    }

    // Fallback function to prevent accidental Ether sends
    receive() external payable {
        revert("CogniVerse: Ether not accepted directly. Use specific functions or wrap ETH to COGN.");
    }
}
```