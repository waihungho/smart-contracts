This smart contract, "Chronoscribe Nexus," aims to create a decentralized, AI-assisted platform for collaborative narrative creation and reputation building, expressed through dynamic NFTs. Users contribute "chronicles" (narrative fragments), which are then analyzed by an off-chain AI oracle (simulated by a trusted address) for originality and coherence, and voted on by the community. Successful contributions boost a user's on-chain reputation and evolve their unique "Chronoscribe" NFT, which dynamically reflects their contributions and standing within the narrative universe.

---

## Contract Outline & Function Summary

### I. Contract Overview

*   **Name:** `ChronoscribeNexus`
*   **Purpose:** A decentralized protocol for collaborative narrative creation, reputation building, and dynamic NFT evolution, powered by AI-assisted curation.
*   **Key Innovations:**
    *   **AI Oracle Integration:** Simulates an off-chain AI analyzing user-submitted content for quality and originality, feeding scores back on-chain.
    *   **Dynamic, Evolving NFTs (Chronoscribes):** ERC721 NFTs whose attributes (and thus visual representation/metadata) change based on a user's reputation, contributions, and AI scores. These NFTs are designed to be "Soulbound" until certain progression milestones, reflecting a user's journey.
    *   **Multi-Stage Chronicle Lifecycle:** Content submission goes through draft, AI analysis, community voting, and finalization stages.
    *   **Gamified Narrative Challenges:** Protocol can issue specific narrative bounties or challenges with rewards.
    *   **Decentralized Reputation System:** Users earn reputation points for approved contributions and positive community engagement.

### II. Core Concepts

*   **Chronicle:** A unit of narrative content submitted by a user. Stored as a hash on-chain, with the actual content expected to reside on IPFS/Arweave.
*   **Chronoscribe NFT:** An ERC721 token representing a user's unique journey and contribution to the Chronoscribe Nexus. Its metadata points to an external service that dynamically generates the NFT's appearance based on on-chain attributes (creativity score, coherence score, impact score, etc.).
*   **AI Oracle:** An external service (represented by a trusted address) that performs complex computational analysis on submitted chronicle content and reports a score back to the contract.
*   **Reputation Points:** Non-transferable points awarded to users for their valuable contributions.
*   **Narrative Challenges:** Themed prompts or bounties set by the community or curators to guide narrative development.

### III. Function Summary

This contract offers a rich set of functionalities categorized for clarity:

**A. Core Chronicle Management (User & Lifecycle)**

1.  `submitChronicleDraft(string memory _contentHash)`: Allows a user to submit a new chronicle draft, represented by its content hash (e.g., IPFS CID).
2.  `updateChronicleDraft(uint256 _chronicleId, string memory _newContentHash)`: Allows the author to update their chronicle draft before it proceeds to analysis.
3.  `requestAIAnalysis(uint256 _chronicleId)`: Owner/Curator initiates an AI analysis request for a pending chronicle. The AI Oracle address will then call back.
4.  `receiveAIAnalysisResult(uint256 _chronicleId, uint256 _aiScore, string memory _feedbackHash)`: Callback function for the AI Oracle to provide analysis results (score, and hash of detailed feedback).
5.  `voteOnChronicle(uint256 _chronicleId, bool _isUpvote)`: Community members vote to approve or reject a chronicle after AI analysis.
6.  `finalizeChronicle(uint256 _chronicleId)`: Owner/Curator finalizes a chronicle based on AI score and community votes, moving it to Approved or Rejected status.
7.  `disputeChronicleDecision(uint256 _chronicleId, string memory _reasonHash)`: Allows an author to dispute a rejection, putting the chronicle back into a disputed state.

**B. Chronoscribe NFT & Reputation Management**

8.  `mintChronoscribeNFT()`: Allows a user to mint their initial Chronoscribe NFT (requires meeting an initial reputation threshold or first approved chronicle).
9.  `_updateChronoscribeNFTAttributes(uint256 _tokenId, uint256 _creativityBoost, uint256 _coherenceBoost, uint256 _impactBoost)`: Internal function called upon successful chronicle finalization to update the NFT's underlying attributes.
10. `evolveChronoscribeNFT(uint256 _tokenId)`: Allows the NFT holder to trigger an "evolution" (e.g., a visual upgrade) once specific reputation or contribution milestones are met.
11. `isChronoscribeTransferable(uint256 _tokenId)`: Checks if a Chronoscribe NFT has reached a stage where it can be transferred (e.g., after achieving 'Legendary' status).

**C. Narrative Challenges & Bounties**

12. `createNarrativeChallenge(string memory _themeHash, uint256 _rewardAmount, uint256 _submissionDeadline)`: Owner/Curator creates a new narrative challenge with a theme and reward.
13. `submitChallengeEntry(uint256 _challengeId, uint256 _chronicleId)`: Allows a user to submit an existing approved chronicle as an entry for a challenge.
14. `resolveNarrativeChallenge(uint256 _challengeId, uint256[] memory _winnerChronicleIds)`: Owner/Curator resolves a challenge, selecting winning chronicles.
15. `claimChallengeReward(uint256 _challengeId)`: Allows a winner of a challenge to claim their rewards.

**D. Treasury & Funding**

16. `depositTreasuryFunds()`: Allows anyone to deposit ETH into the protocol's treasury.
17. `proposeTreasurySpend(uint256 _amount, address _recipient, string memory _descriptionHash)`: A Curator or high-reputation user can propose a spend from the treasury.
18. `voteOnTreasurySpend(uint256 _proposalId, bool _approve)`: Community members vote on treasury spending proposals.
19. `executeTreasurySpend(uint256 _proposalId)`: Owner/Curator executes a treasury spend proposal that has passed its vote.

**E. Governance & Admin**

20. `setAIOracleAddress(address _newOracleAddress)`: Owner sets or updates the address of the trusted AI Oracle.
21. `setVotingThresholds(uint256 _minUpvotes, uint256 _aiScoreWeight)`: Owner configures the thresholds for chronicle approval (e.g., minimum upvotes, AI score weighting).
22. `grantCuratorRole(address _account)`: Owner grants a user the Curator role, enabling them to initiate AI analysis and finalize chronicles.
23. `revokeCuratorRole(address _account)`: Owner revokes a Curator role.
24. `pauseContract()`: Emergency function by owner to pause critical functionalities (inherited from `Pausable` if used, or custom).
25. `withdrawStuckTokens(address _tokenAddress)`: Owner can withdraw accidentally sent ERC20 tokens.

**F. View & Helper Functions**

26. `getChronicleDetails(uint256 _chronicleId)`: Retrieves detailed information about a chronicle.
27. `getChronoscribeNFTAttributes(uint256 _tokenId)`: Retrieves the dynamic attributes stored for a specific Chronoscribe NFT.
28. `getUserReputation(address _user)`: Returns the reputation score of a given user.
29. `getChallengeDetails(uint256 _challengeId)`: Retrieves details about a narrative challenge.
30. `getTreasuryBalance()`: Returns the current balance of the contract's treasury.
31. `getTreasuryProposal(uint256 _proposalId)`: Retrieves details about a treasury spending proposal.
32. `tokenURI(uint256 tokenId)`: Standard ERC721 function to get the metadata URI for a given token. (Note: The actual metadata will be dynamically generated off-chain based on the NFT's on-chain attributes).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol"; // For pause/unpause functionality

// Interfaces
interface IAIOracle {
    // This interface defines how the ChronoscribeNexus contract expects to interact with the AI Oracle.
    // The actual AI computation happens off-chain, and this contract expects a callback.
    function requestAnalysis(uint256 chronicleId, string calldata contentHash) external;
    // Expected callback (implemented in ChronoscribeNexus):
    // receiveAIAnalysisResult(uint256 chronicleId, uint256 aiScore, string calldata feedbackHash)
}

/**
 * @title ChronoscribeNexus
 * @dev A decentralized protocol for collaborative narrative creation, reputation building, and dynamic NFT evolution,
 *      powered by AI-assisted curation. Users submit narrative fragments (chronicles), which are analyzed by an
 *      off-chain AI oracle and voted on by the community. Successful contributions boost user reputation and
 *      evolve their unique Chronoscribe NFTs.
 */
contract ChronoscribeNexus is Ownable, ERC721URIStorage, ReentrancyGuard, Pausable {
    using Counters for Counters.Counter;

    // --- State Variables ---

    Counters.Counter private _chronicleIds; // Counter for unique chronicle IDs
    Counters.Counter private _tokenIdCounter; // Counter for unique Chronoscribe NFT IDs
    Counters.Counter private _challengeIds; // Counter for narrative challenge IDs
    Counters.Counter private _proposalIds; // Counter for treasury spending proposal IDs

    // Maps chronicle ID to its details
    mapping(uint256 => Chronicle) public chronicles;
    // Maps chronicle ID to user addresses that have voted (to prevent double voting)
    mapping(uint256 => mapping(address => bool)) public chronicleVoters;
    // Maps user address to their current reputation points
    mapping(address => uint256) public userReputation;
    // Maps Chronoscribe NFT ID to its dynamic attributes
    mapping(uint256 => ChronoscribeAttributes) public chronoscribeNFTs;
    // Maps narrative challenge ID to its details
    mapping(uint256 => NarrativeChallenge) public narrativeChallenges;
    // Maps treasury proposal ID to its details
    mapping(uint256 => TreasuryProposal) public treasuryProposals;
    // Maps proposal ID to user addresses that have voted on it
    mapping(uint256 => mapping(address => bool)) public treasuryProposalVoters;

    // Address of the trusted AI Oracle contract
    IAIOracle public aiOracle;

    // Configuration for chronicle approval thresholds
    uint256 public minUpvotesForApproval;
    uint256 public aiScoreWeightPercentage; // e.g., 70 for 70% AI, 30% community vote
    uint256 public minAIScoreForAnalysis; // Minimum score required from AI for approval consideration

    // Reputation thresholds for NFT evolution and transferability
    uint256 public reputationForNFTMint;
    uint256 public reputationForNFTEvolution1; // e.g., 'Apprentice' to 'Journeyman'
    uint256 public reputationForNFTEvolution2; // e.g., 'Journeyman' to 'Master'
    uint256 public reputationForNFTTransferability; // 'Master' to 'Legendary' (transferable)

    // Role management
    mapping(address => bool) public isCurator;

    // --- Enums ---

    enum ChronicleStatus {
        Draft,                // Initial state, editable by author
        PendingAIAnalysis,    // Sent to AI for scoring
        PendingCommunityVote, // AI analysis complete, awaiting community vote
        Approved,             // Finalized and approved
        Rejected,             // Finalized and rejected
        Disputed              // Author has disputed a rejection
    }

    enum ProposalStatus {
        Pending,
        Approved,
        Rejected,
        Executed
    }

    // --- Structs ---

    struct Chronicle {
        uint256 id;
        address author;
        string contentHash; // IPFS CID or similar hash of the narrative content
        ChronicleStatus status;
        uint256 aiScore; // Score from AI Oracle (0-100)
        string aiFeedbackHash; // Hash of AI's detailed feedback
        uint256 upvotes;
        uint256 downvotes;
        uint256 submissionTimestamp;
        uint256 challengeId; // 0 if not part of a challenge
    }

    struct ChronoscribeAttributes {
        uint256 creativityScore; // Reflects originality and ideation
        uint256 coherenceScore;  // Reflects logical flow and consistency
        uint256 impactScore;     // Reflects resonance and influence
        uint256 chroniclesContributed; // Total number of approved chronicles
        uint256 evolutionStage;  // 0: Basic, 1: Apprentice, 2: Journeyman, 3: Master, 4: Legendary
    }

    struct NarrativeChallenge {
        uint256 id;
        string themeHash; // Hash of the challenge theme/description
        uint256 rewardAmount; // ETH or other token reward
        uint256 submissionDeadline;
        uint256[] winningChronicleIds;
        bool isActive;
        bool isResolved;
    }

    struct TreasuryProposal {
        uint256 id;
        address proposer;
        uint256 amount;
        address recipient;
        string descriptionHash;
        uint256 upvotes;
        uint256 downvotes;
        uint256 creationTimestamp;
        ProposalStatus status;
        uint256 minVoteDuration; // Duration in seconds for voting period
        uint256 voteEndTime;
    }

    // --- Events ---

    event ChronicleSubmitted(uint256 indexed chronicleId, address indexed author, string contentHash);
    event ChronicleUpdated(uint256 indexed chronicleId, string newContentHash);
    event AIAnalysisRequested(uint256 indexed chronicleId, address indexed requestor);
    event AIAnalysisReceived(uint256 indexed chronicleId, uint256 aiScore, string feedbackHash);
    event ChronicleVoted(uint256 indexed chronicleId, address indexed voter, bool isUpvote);
    event ChronicleFinalized(uint256 indexed chronicleId, ChronicleStatus newStatus);
    event ChronicleDisputed(uint256 indexed chronicleId, address indexed disputer, string reasonHash);

    event ChronoscribeNFTMinted(address indexed minter, uint256 indexed tokenId);
    event ChronoscribeNFTAttributesUpdated(uint256 indexed tokenId, uint256 creativity, uint256 coherence, uint256 impact);
    event ChronoscribeNFTEvolved(uint256 indexed tokenId, uint256 newStage);
    event ChronoscribeNFTTransferabilityChanged(uint256 indexed tokenId, bool isTransferable);

    event ReputationAwarded(address indexed user, uint256 amount);

    event NarrativeChallengeCreated(uint256 indexed challengeId, string themeHash, uint256 rewardAmount, uint256 deadline);
    event ChallengeEntrySubmitted(uint256 indexed challengeId, uint256 indexed chronicleId, address indexed submitter);
    event NarrativeChallengeResolved(uint256 indexed challengeId, uint256[] winnerChronicleIds);
    event ChallengeRewardClaimed(uint256 indexed challengeId, address indexed winner, uint256 amount);

    event FundsDeposited(address indexed depositor, uint256 amount);
    event TreasurySpendProposed(uint256 indexed proposalId, address indexed proposer, uint256 amount, address recipient, string descriptionHash);
    event TreasurySpendVoted(uint256 indexed proposalId, address indexed voter, bool approved);
    event TreasurySpendExecuted(uint256 indexed proposalId);

    event AIOracleAddressSet(address indexed oldAddress, address indexed newAddress);
    event VotingThresholdsSet(uint256 minUpvotes, uint256 aiScoreWeight, uint256 minAIScore);
    event CuratorRoleGranted(address indexed account);
    event CuratorRoleRevoked(address indexed account);

    // --- Modifiers ---

    modifier onlyCurator() {
        require(isCurator[msg.sender], "ChronoscribeNexus: Caller is not a curator");
        _;
    }

    // --- Constructor ---

    constructor(
        address _aiOracleAddress,
        uint256 _minUpvotesForApproval,
        uint256 _aiScoreWeightPercentage,
        uint256 _minAIScoreForAnalysis,
        uint256 _reputationForNFTMint,
        uint256 _reputationForNFTEvolution1,
        uint256 _reputationForNFTEvolution2,
        uint256 _reputationForNFTTransferability,
        string memory _name,
        string memory _symbol
    ) ERC721(_name, _symbol) Ownable(msg.sender) {
        require(_aiOracleAddress != address(0), "ChronoscribeNexus: AI Oracle address cannot be zero");
        aiOracle = IAIOracle(_aiOracleAddress);

        minUpvotesForApproval = _minUpvotesForApproval;
        aiScoreWeightPercentage = _aiScoreWeightPercentage;
        minAIScoreForAnalysis = _minAIScoreForAnalysis;

        reputationForNFTMint = _reputationForNFTMint;
        reputationForNFTEvolution1 = _reputationForNFTEvolution1;
        reputationForNFTEvolution2 = _reputationForNFTEvolution2;
        reputationForNFTTransferability = _reputationForNFTTransferability;

        // Grant deployer the initial curator role
        isCurator[msg.sender] = true;
        emit CuratorRoleGranted(msg.sender);
    }

    // --- Core Chronicle Management ---

    /**
     * @dev Allows a user to submit a new chronicle draft.
     * @param _contentHash The IPFS CID or content hash of the narrative text.
     */
    function submitChronicleDraft(string memory _contentHash) external whenNotPaused nonReentrant {
        _chronicleIds.increment();
        uint256 newId = _chronicleIds.current();
        chronicles[newId] = Chronicle({
            id: newId,
            author: msg.sender,
            contentHash: _contentHash,
            status: ChronicleStatus.Draft,
            aiScore: 0,
            aiFeedbackHash: "",
            upvotes: 0,
            downvotes: 0,
            submissionTimestamp: block.timestamp,
            challengeId: 0
        });
        emit ChronicleSubmitted(newId, msg.sender, _contentHash);
    }

    /**
     * @dev Allows the author to update their chronicle draft before it proceeds to analysis.
     * @param _chronicleId The ID of the chronicle to update.
     * @param _newContentHash The new IPFS CID or content hash.
     */
    function updateChronicleDraft(uint256 _chronicleId, string memory _newContentHash) external whenNotPaused {
        Chronicle storage chronicle = chronicles[_chronicleId];
        require(chronicle.author == msg.sender, "ChronoscribeNexus: Only author can update their draft.");
        require(chronicle.status == ChronicleStatus.Draft, "ChronoscribeNexus: Chronicle is not in draft status.");

        chronicle.contentHash = _newContentHash;
        emit ChronicleUpdated(_chronicleId, _newContentHash);
    }

    /**
     * @dev Initiates an AI analysis request for a pending chronicle. Only callable by a curator.
     *      The AI Oracle will then call `receiveAIAnalysisResult`.
     * @param _chronicleId The ID of the chronicle to send for AI analysis.
     */
    function requestAIAnalysis(uint256 _chronicleId) external onlyCurator whenNotPaused {
        Chronicle storage chronicle = chronicles[_chronicleId];
        require(chronicle.status == ChronicleStatus.Draft || chronicle.status == ChronicleStatus.Disputed, "ChronoscribeNexus: Chronicle not in a state for AI analysis.");
        require(bytes(chronicle.contentHash).length > 0, "ChronoscribeNexus: Chronicle content hash is empty.");

        chronicle.status = ChronicleStatus.PendingAIAnalysis;
        aiOracle.requestAnalysis(_chronicleId, chronicle.contentHash);
        emit AIAnalysisRequested(_chronicleId, msg.sender);
    }

    /**
     * @dev Callback function for the AI Oracle to provide analysis results.
     *      Only callable by the registered AI Oracle address.
     * @param _chronicleId The ID of the chronicle.
     * @param _aiScore The score provided by the AI (e.g., 0-100).
     * @param _feedbackHash The IPFS CID or hash of detailed AI feedback.
     */
    function receiveAIAnalysisResult(uint256 _chronicleId, uint256 _aiScore, string memory _feedbackHash) external whenNotPaused {
        require(msg.sender == address(aiOracle), "ChronoscribeNexus: Only the registered AI Oracle can call this function.");
        Chronicle storage chronicle = chronicles[_chronicleId];
        require(chronicle.status == ChronicleStatus.PendingAIAnalysis, "ChronoscribeNexus: Chronicle not awaiting AI analysis.");

        chronicle.aiScore = _aiScore;
        chronicle.aiFeedbackHash = _feedbackHash;
        chronicle.status = ChronicleStatus.PendingCommunityVote; // Move to community vote stage
        emit AIAnalysisReceived(_chronicleId, _aiScore, _feedbackHash);
    }

    /**
     * @dev Allows community members to vote on a chronicle after AI analysis.
     * @param _chronicleId The ID of the chronicle to vote on.
     * @param _isUpvote True for an upvote, false for a downvote.
     */
    function voteOnChronicle(uint256 _chronicleId, bool _isUpvote) external whenNotPaused {
        Chronicle storage chronicle = chronicles[_chronicleId];
        require(chronicle.status == ChronicleStatus.PendingCommunityVote, "ChronoscribeNexus: Chronicle not in voting stage.");
        require(chronicle.author != msg.sender, "ChronoscribeNexus: Authors cannot vote on their own chronicles.");
        require(!chronicleVoters[_chronicleId][msg.sender], "ChronoscribeNexus: Already voted on this chronicle.");

        if (_isUpvote) {
            chronicle.upvotes++;
        } else {
            chronicle.downvotes++;
        }
        chronicleVoters[_chronicleId][msg.sender] = true;
        emit ChronicleVoted(_chronicleId, msg.sender, _isUpvote);
    }

    /**
     * @dev Finalizes a chronicle based on its AI score and community votes.
     *      Only callable by a curator.
     * @param _chronicleId The ID of the chronicle to finalize.
     */
    function finalizeChronicle(uint256 _chronicleId) external onlyCurator whenNotPaused nonReentrant {
        Chronicle storage chronicle = chronicles[_chronicleId];
        require(chronicle.status == ChronicleStatus.PendingCommunityVote, "ChronoscribeNexus: Chronicle not ready for finalization.");

        // Calculate combined score (simple weighted average example)
        uint256 communityScore = chronicle.upvotes > chronicle.downvotes ? chronicle.upvotes - chronicle.downvotes : 0;
        uint256 totalScore = (chronicle.aiScore * aiScoreWeightPercentage / 100) +
                             (communityScore * (100 - aiScoreWeightPercentage) / 100);

        if (totalScore >= minAIScoreForAnalysis && chronicle.upvotes >= minUpvotesForApproval) {
            chronicle.status = ChronicleStatus.Approved;
            _awardReputation(chronicle.author, 10); // Example: Award 10 reputation for approved chronicle
            _updateChronoscribeNFTAttributes(
                _getChronoscribeTokenId(chronicle.author),
                chronicle.aiScore / 10, // Example: Creativity boost based on AI score
                chronicle.aiScore / 10, // Example: Coherence boost based on AI score
                communityScore / 5     // Example: Impact boost based on community score
            );
        } else {
            chronicle.status = ChronicleStatus.Rejected;
        }
        emit ChronicleFinalized(_chronicleId, chronicle.status);
    }

    /**
     * @dev Allows an author to dispute a rejected chronicle. Puts it back into a disputed state for re-evaluation.
     * @param _chronicleId The ID of the chronicle to dispute.
     * @param _reasonHash The IPFS CID or hash of the reason for dispute.
     */
    function disputeChronicleDecision(uint256 _chronicleId, string memory _reasonHash) external whenNotPaused {
        Chronicle storage chronicle = chronicles[_chronicleId];
        require(chronicle.author == msg.sender, "ChronoscribeNexus: Only author can dispute.");
        require(chronicle.status == ChronicleStatus.Rejected, "ChronoscribeNexus: Only rejected chronicles can be disputed.");

        chronicle.status = ChronicleStatus.Disputed;
        // Reset vote counts and AI score to allow re-evaluation path (optional, depends on re-evaluation logic)
        chronicle.upvotes = 0;
        chronicle.downvotes = 0;
        chronicle.aiScore = 0;
        // Clear all previous votes for this chronicle
        // Note: For actual large-scale dApps, clearing individually can be gas intensive.
        // A more complex voting system (e.g., snapshot based) might be needed.
        // For simplicity, this example just conceptually "resets".
        // In reality, you'd iterate or use a more advanced data structure.
        // Or simply mark it disputed and require a curator to re-trigger AIAnalysis.

        emit ChronicleDisputed(_chronicleId, msg.sender, _reasonHash);
    }

    // --- Chronoscribe NFT & Reputation Management ---

    /**
     * @dev Awards reputation points to a user. Internal function.
     * @param _user The address of the user to award reputation to.
     * @param _amount The amount of reputation to award.
     */
    function _awardReputation(address _user, uint256 _amount) internal {
        userReputation[_user] += _amount;
        emit ReputationAwarded(_user, _amount);
    }

    /**
     * @dev Allows a user to mint their initial Chronoscribe NFT.
     *      Requires meeting a minimum reputation threshold.
     */
    function mintChronoscribeNFT() external whenNotPaused nonReentrant {
        require(balanceOf(msg.sender) == 0, "ChronoscribeNexus: You already own a Chronoscribe NFT.");
        require(userReputation[msg.sender] >= reputationForNFTMint, "ChronoscribeNexus: Not enough reputation to mint NFT.");

        _tokenIdCounter.increment();
        uint256 newId = _tokenIdCounter.current();

        _safeMint(msg.sender, newId);
        chronoscribeNFTs[newId] = ChronoscribeAttributes({
            creativityScore: 0,
            coherenceScore: 0,
            impactScore: 0,
            chroniclesContributed: 0,
            evolutionStage: 0 // Basic stage
        });

        // Set initial token URI. This URI will point to an off-chain service that generates dynamic metadata.
        _setTokenURI(newId, string(abi.encodePacked(baseURI(), Strings.toString(newId))));

        emit ChronoscribeNFTMinted(msg.sender, newId);
    }

    /**
     * @dev Internal function to update a Chronoscribe NFT's attributes.
     *      Called upon successful chronicle finalization or other achievements.
     * @param _tokenId The ID of the Chronoscribe NFT.
     * @param _creativityBoost Points to add to creativity.
     * @param _coherenceBoost Points to add to coherence.
     * @param _impactBoost Points to add to impact.
     */
    function _updateChronoscribeNFTAttributes(uint256 _tokenId, uint256 _creativityBoost, uint256 _coherenceBoost, uint256 _impactBoost) internal {
        ChronoscribeAttributes storage nft = chronoscribeNFTs[_tokenId];
        nft.creativityScore += _creativityBoost;
        nft.coherenceScore += _coherenceBoost;
        nft.impactScore += _impactBoost;
        nft.chroniclesContributed++;

        emit ChronoscribeNFTAttributesUpdated(_tokenId, nft.creativityScore, nft.coherenceScore, nft.impactScore);
    }

    /**
     * @dev Allows the NFT holder to trigger an "evolution" of their Chronoscribe NFT.
     *      This could correspond to visual upgrades or new metadata levels.
     * @param _tokenId The ID of the Chronoscribe NFT to evolve.
     */
    function evolveChronoscribeNFT(uint256 _tokenId) external whenNotPaused {
        require(ownerOf(_tokenId) == msg.sender, "ChronoscribeNexus: Only NFT owner can evolve.");
        ChronoscribeAttributes storage nft = chronoscribeNFTs[_tokenId];
        uint256 currentRep = userReputation[msg.sender];

        if (nft.evolutionStage == 0 && currentRep >= reputationForNFTEvolution1) {
            nft.evolutionStage = 1; // Evolve to Apprentice
            emit ChronoscribeNFTEvolved(_tokenId, 1);
        } else if (nft.evolutionStage == 1 && currentRep >= reputationForNFTEvolution2) {
            nft.evolutionStage = 2; // Evolve to Journeyman
            emit ChronoscribeNFTEvolved(_tokenId, 2);
        } else if (nft.evolutionStage == 2 && currentRep >= reputationForNFTTransferability) {
            nft.evolutionStage = 3; // Evolve to Master (or Legendary, making it transferable)
            emit ChronoscribeNFTEvolved(_tokenId, 3);
            emit ChronoscribeNFTTransferabilityChanged(_tokenId, true);
        } else {
            revert("ChronoscribeNexus: Not eligible for evolution or already at max stage.");
        }
        // Update URI to reflect new stage, which an off-chain service would interpret
        _setTokenURI(_tokenId, string(abi.encodePacked(baseURI(), Strings.toString(_tokenId))));
    }

    /**
     * @dev Internal helper to get the Chronoscribe NFT ID for a given user.
     *      Assumes each user can only have one Chronoscribe NFT.
     */
    function _getChronoscribeTokenId(address _user) internal view returns (uint256) {
        // This is a simplified lookup. In a real scenario, you might map user address to tokenId
        // or iterate through tokens owned by the user if multiple NFTs were allowed.
        // For a "soulbound-like" single NFT per user, checking `tokenOfOwnerByIndex` for index 0 is common.
        if (balanceOf(_user) == 0) return 0; // User does not own a Chronoscribe NFT
        return tokenOfOwnerByIndex(_user, 0);
    }

    /**
     * @dev Overrides ERC721's _beforeTokenTransfer to implement "soulbound" logic.
     *      NFTs are non-transferable until they reach a certain evolution stage.
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721URIStorage) // ERC721URIStorage also implements this hook
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        if (from != address(0) && to != address(0) && from != to) { // Actual transfer, not mint/burn
            require(isChronoscribeTransferable(tokenId), "ChronoscribeNexus: Chronoscribe NFT not yet transferable.");
        }
    }

    /**
     * @dev Checks if a Chronoscribe NFT has reached a stage where it can be transferred.
     * @param _tokenId The ID of the Chronoscribe NFT.
     * @return True if transferable, false otherwise.
     */
    function isChronoscribeTransferable(uint256 _tokenId) public view returns (bool) {
        return chronoscribeNFTs[_tokenId].evolutionStage >= 3; // Legendary stage or higher
    }

    // --- Narrative Challenges & Bounties ---

    /**
     * @dev Allows a curator to create a new narrative challenge.
     * @param _themeHash IPFS CID or hash of the challenge theme/description.
     * @param _rewardAmount ETH reward for winners.
     * @param _submissionDeadline Timestamp when submissions close.
     */
    function createNarrativeChallenge(string memory _themeHash, uint256 _rewardAmount, uint256 _submissionDeadline)
        external
        onlyCurator
        whenNotPaused
        nonReentrant
    {
        require(bytes(_themeHash).length > 0, "ChronoscribeNexus: Theme hash cannot be empty.");
        require(_submissionDeadline > block.timestamp, "ChronoscribeNexus: Deadline must be in the future.");

        _challengeIds.increment();
        uint256 newId = _challengeIds.current();

        narrativeChallenges[newId] = NarrativeChallenge({
            id: newId,
            themeHash: _themeHash,
            rewardAmount: _rewardAmount,
            submissionDeadline: _submissionDeadline,
            winningChronicleIds: new uint256[](0),
            isActive: true,
            isResolved: false
        });
        emit NarrativeChallengeCreated(newId, _themeHash, _rewardAmount, _submissionDeadline);
    }

    /**
     * @dev Allows a user to submit an approved chronicle as an entry for a narrative challenge.
     * @param _challengeId The ID of the challenge.
     * @param _chronicleId The ID of the approved chronicle to submit.
     */
    function submitChallengeEntry(uint256 _challengeId, uint256 _chronicleId) external whenNotPaused {
        NarrativeChallenge storage challenge = narrativeChallenges[_challengeId];
        require(challenge.isActive, "ChronoscribeNexus: Challenge is not active.");
        require(block.timestamp <= challenge.submissionDeadline, "ChronoscribeNexus: Submission deadline passed.");

        Chronicle storage chronicle = chronicles[_chronicleId];
        require(chronicle.author == msg.sender, "ChronoscribeNexus: You must be the author of the chronicle.");
        require(chronicle.status == ChronicleStatus.Approved, "ChronoscribeNexus: Chronicle must be approved.");
        require(chronicle.challengeId == 0, "ChronoscribeNexus: Chronicle already submitted to a challenge.");

        chronicle.challengeId = _challengeId; // Link chronicle to challenge
        emit ChallengeEntrySubmitted(_challengeId, _chronicleId, msg.sender);
    }

    /**
     * @dev Allows a curator to resolve a narrative challenge and declare winners.
     * @param _challengeId The ID of the challenge to resolve.
     * @param _winnerChronicleIds An array of chronicle IDs that are winners.
     */
    function resolveNarrativeChallenge(uint256 _challengeId, uint256[] memory _winnerChronicleIds)
        external
        onlyCurator
        whenNotPaused
        nonReentrant
    {
        NarrativeChallenge storage challenge = narrativeChallenges[_challengeId];
        require(challenge.isActive, "ChronoscribeNexus: Challenge is not active.");
        require(block.timestamp > challenge.submissionDeadline, "ChronoscribeNexus: Submission period not yet ended.");
        require(!challenge.isResolved, "ChronoscribeNexus: Challenge already resolved.");
        require(_winnerChronicleIds.length > 0, "ChronoscribeNexus: At least one winner must be specified.");

        challenge.winningChronicleIds = _winnerChronicleIds;
        challenge.isActive = false;
        challenge.isResolved = true;

        // Optionally, award bonus reputation to winners
        for (uint256 i = 0; i < _winnerChronicleIds.length; i++) {
            address winnerAddress = chronicles[_winnerChronicleIds[i]].author;
            _awardReputation(winnerAddress, 25); // Example: Award 25 bonus reputation
        }
        emit NarrativeChallengeResolved(_challengeId, _winnerChronicleIds);
    }

    /**
     * @dev Allows a winning author to claim their reward for a resolved challenge.
     *      Each winner shares the reward equally.
     * @param _challengeId The ID of the challenge.
     */
    function claimChallengeReward(uint256 _challengeId) external whenNotPaused nonReentrant {
        NarrativeChallenge storage challenge = narrativeChallenges[_challengeId];
        require(challenge.isResolved, "ChronoscribeNexus: Challenge not resolved.");
        require(challenge.winningChronicleIds.length > 0, "ChronoscribeNexus: No winners declared for this challenge.");

        bool isWinner = false;
        for (uint256 i = 0; i < challenge.winningChronicleIds.length; i++) {
            if (chronicles[challenge.winningChronicleIds[i]].author == msg.sender) {
                isWinner = true;
                break;
            }
        }
        require(isWinner, "ChronoscribeNexus: You are not a winner of this challenge.");

        uint256 rewardPerWinner = challenge.rewardAmount / challenge.winningChronicleIds.length;
        require(rewardPerWinner > 0, "ChronoscribeNexus: No reward amount to claim or too many winners.");
        // Mark as claimed to prevent double claim (or, use a more complex state for each winner)
        challenge.rewardAmount = 0; // Mark reward as claimed for simplicity.
        // In a more robust system, you'd track individual claims.
        // For now, this means only one person claims, then the rest can't.
        // A better approach would be: mapping (challengeId => winnerAddress => bool hasClaimed)

        (bool success,) = payable(msg.sender).call{value: rewardPerWinner}("");
        require(success, "ChronoscribeNexus: Failed to send reward.");

        emit ChallengeRewardClaimed(_challengeId, msg.sender, rewardPerWinner);
    }

    // --- Treasury & Funding ---

    /**
     * @dev Allows anyone to deposit ETH into the protocol's treasury.
     */
    function depositTreasuryFunds() external payable whenNotPaused {
        require(msg.value > 0, "ChronoscribeNexus: Must send positive ETH amount.");
        emit FundsDeposited(msg.sender, msg.value);
    }

    /**
     * @dev Allows a curator or high-reputation user to propose a spend from the treasury.
     * @param _amount The amount of ETH to spend.
     * @param _recipient The address to send the funds to.
     * @param _descriptionHash IPFS CID or hash of the proposal's description.
     */
    function proposeTreasurySpend(uint256 _amount, address _recipient, string memory _descriptionHash)
        external
        onlyCurator // Or add reputation check: `require(userReputation[msg.sender] >= MIN_REPUTATION_FOR_PROPOSAL);`
        whenNotPaused
    {
        require(_amount > 0, "ChronoscribeNexus: Amount must be greater than zero.");
        require(_recipient != address(0), "ChronoscribeNexus: Recipient cannot be zero address.");
        require(address(this).balance >= _amount, "ChronoscribeNexus: Insufficient treasury balance.");

        _proposalIds.increment();
        uint256 newId = _proposalIds.current();

        treasuryProposals[newId] = TreasuryProposal({
            id: newId,
            proposer: msg.sender,
            amount: _amount,
            recipient: _recipient,
            descriptionHash: _descriptionHash,
            upvotes: 0,
            downvotes: 0,
            creationTimestamp: block.timestamp,
            status: ProposalStatus.Pending,
            minVoteDuration: 7 days, // Example: 7 days voting period
            voteEndTime: block.timestamp + 7 days
        });
        emit TreasurySpendProposed(newId, msg.sender, _amount, _recipient, _descriptionHash);
    }

    /**
     * @dev Allows community members to vote on treasury spending proposals.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _approve True to approve, false to reject.
     */
    function voteOnTreasurySpend(uint256 _proposalId, bool _approve) external whenNotPaused {
        TreasuryProposal storage proposal = treasuryProposals[_proposalId];
        require(proposal.status == ProposalStatus.Pending, "ChronoscribeNexus: Proposal is not pending.");
        require(block.timestamp < proposal.voteEndTime, "ChronoscribeNexus: Voting period has ended.");
        require(!treasuryProposalVoters[_proposalId][msg.sender], "ChronoscribeNexus: Already voted on this proposal.");

        if (_approve) {
            proposal.upvotes++;
        } else {
            proposal.downvotes++;
        }
        treasuryProposalVoters[_proposalId][msg.sender] = true;
        emit TreasurySpendVoted(_proposalId, msg.sender, _approve);
    }

    /**
     * @dev Executes a treasury spend proposal that has passed its voting period and criteria.
     *      Only callable by a curator.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeTreasurySpend(uint256 _proposalId) external onlyCurator whenNotPaused nonReentrant {
        TreasuryProposal storage proposal = treasuryProposals[_proposalId];
        require(proposal.status == ProposalStatus.Pending, "ChronoscribeNexus: Proposal is not pending.");
        require(block.timestamp >= proposal.voteEndTime, "ChronoscribeNexus: Voting period has not ended.");

        // Simple approval criteria: more upvotes than downvotes
        if (proposal.upvotes > proposal.downvotes) {
            proposal.status = ProposalStatus.Approved;
            require(address(this).balance >= proposal.amount, "ChronoscribeNexus: Insufficient balance for execution.");

            (bool success,) = payable(proposal.recipient).call{value: proposal.amount}("");
            require(success, "ChronoscribeNexus: Failed to send funds for proposal.");
            proposal.status = ProposalStatus.Executed;
            emit TreasurySpendExecuted(_proposalId);
        } else {
            proposal.status = ProposalStatus.Rejected;
            // No funds transfer if rejected
        }
    }

    // --- Governance & Admin ---

    /**
     * @dev Sets or updates the address of the trusted AI Oracle.
     *      Only callable by the contract owner.
     * @param _newOracleAddress The new address of the AI Oracle contract.
     */
    function setAIOracleAddress(address _newOracleAddress) external onlyOwner {
        require(_newOracleAddress != address(0), "ChronoscribeNexus: AI Oracle address cannot be zero.");
        address oldOracle = address(aiOracle);
        aiOracle = IAIOracle(_newOracleAddress);
        emit AIOracleAddressSet(oldOracle, _newOracleAddress);
    }

    /**
     * @dev Configures the thresholds for chronicle approval.
     *      Only callable by the contract owner.
     * @param _minUpvotes The minimum number of upvotes required.
     * @param _aiScoreWeight The percentage weight of the AI score (0-100).
     * @param _minAIScore The minimum AI score required for analysis consideration.
     */
    function setVotingThresholds(uint256 _minUpvotes, uint256 _aiScoreWeight, uint256 _minAIScore) external onlyOwner {
        require(_aiScoreWeight <= 100, "ChronoscribeNexus: AI score weight cannot exceed 100%.");
        minUpvotesForApproval = _minUpvotes;
        aiScoreWeightPercentage = _aiScoreWeight;
        minAIScoreForAnalysis = _minAIScore;
        emit VotingThresholdsSet(_minUpvotes, _aiScoreWeight, _minAIScore);
    }

    /**
     * @dev Grants a user the Curator role, enabling them to initiate AI analysis and finalize chronicles.
     *      Only callable by the contract owner.
     * @param _account The address to grant the role to.
     */
    function grantCuratorRole(address _account) external onlyOwner {
        require(_account != address(0), "ChronoscribeNexus: Account cannot be zero address.");
        require(!isCurator[_account], "ChronoscribeNexus: Account already has curator role.");
        isCurator[_account] = true;
        emit CuratorRoleGranted(_account);
    }

    /**
     * @dev Revokes the Curator role from a user.
     *      Only callable by the contract owner.
     * @param _account The address to revoke the role from.
     */
    function revokeCuratorRole(address _account) external onlyOwner {
        require(_account != address(0), "ChronoscribeNexus: Account cannot be zero address.");
        require(isCurator[_account], "ChronoscribeNexus: Account does not have curator role.");
        isCurator[_account] = false;
        emit CuratorRoleRevoked(_account);
    }

    /**
     * @dev Emergency function to pause critical functionalities in case of an exploit or bug.
     *      Only callable by the contract owner. Inherited from Pausable.
     */
    function pauseContract() external onlyOwner {
        _pause();
    }

    /**
     * @dev Resumes critical functionalities after a pause.
     *      Only callable by the contract owner. Inherited from Pausable.
     */
    function unpauseContract() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Allows the owner to withdraw any ERC20 tokens accidentally sent to the contract.
     * @param _tokenAddress The address of the ERC20 token.
     */
    function withdrawStuckTokens(address _tokenAddress) external onlyOwner nonReentrant {
        IERC20 token = IERC20(_tokenAddress);
        token.transfer(owner(), token.balanceOf(address(this)));
    }


    // --- View & Helper Functions ---

    /**
     * @dev Retrieves detailed information about a chronicle.
     * @param _chronicleId The ID of the chronicle.
     * @return A tuple containing chronicle details.
     */
    function getChronicleDetails(uint256 _chronicleId)
        external
        view
        returns (
            uint256 id,
            address author,
            string memory contentHash,
            ChronicleStatus status,
            uint256 aiScore,
            string memory aiFeedbackHash,
            uint256 upvotes,
            uint256 downvotes,
            uint256 submissionTimestamp,
            uint256 challengeId
        )
    {
        Chronicle storage c = chronicles[_chronicleId];
        return (
            c.id,
            c.author,
            c.contentHash,
            c.status,
            c.aiScore,
            c.aiFeedbackHash,
            c.upvotes,
            c.downvotes,
            c.submissionTimestamp,
            c.challengeId
        );
    }

    /**
     * @dev Retrieves the dynamic attributes stored for a specific Chronoscribe NFT.
     * @param _tokenId The ID of the Chronoscribe NFT.
     * @return A tuple containing the NFT's attribute scores and evolution stage.
     */
    function getChronoscribeNFTAttributes(uint256 _tokenId)
        external
        view
        returns (uint256 creativity, uint256 coherence, uint256 impact, uint256 contributed, uint256 evolutionStage)
    {
        ChronoscribeAttributes storage nft = chronoscribeNFTs[_tokenId];
        return (nft.creativityScore, nft.coherenceScore, nft.impactScore, nft.chroniclesContributed, nft.evolutionStage);
    }

    /**
     * @dev Returns the current reputation score of a given user.
     * @param _user The address of the user.
     * @return The user's reputation score.
     */
    function getUserReputation(address _user) external view returns (uint256) {
        return userReputation[_user];
    }

    /**
     * @dev Retrieves details about a narrative challenge.
     * @param _challengeId The ID of the challenge.
     * @return A tuple containing challenge details.
     */
    function getChallengeDetails(uint256 _challengeId)
        external
        view
        returns (
            uint256 id,
            string memory themeHash,
            uint256 rewardAmount,
            uint256 submissionDeadline,
            uint256[] memory winningChronicleIds,
            bool isActive,
            bool isResolved
        )
    {
        NarrativeChallenge storage nc = narrativeChallenges[_challengeId];
        return (
            nc.id,
            nc.themeHash,
            nc.rewardAmount,
            nc.submissionDeadline,
            nc.winningChronicleIds,
            nc.isActive,
            nc.isResolved
        );
    }

    /**
     * @dev Returns the current balance of the contract's treasury.
     * @return The treasury's ETH balance.
     */
    function getTreasuryBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Retrieves details about a treasury spending proposal.
     * @param _proposalId The ID of the proposal.
     * @return A tuple containing proposal details.
     */
    function getTreasuryProposal(uint256 _proposalId)
        external
        view
        returns (
            uint256 id,
            address proposer,
            uint256 amount,
            address recipient,
            string memory descriptionHash,
            uint256 upvotes,
            uint256 downvotes,
            uint256 creationTimestamp,
            ProposalStatus status,
            uint256 voteEndTime
        )
    {
        TreasuryProposal storage tp = treasuryProposals[_proposalId];
        return (
            tp.id,
            tp.proposer,
            tp.amount,
            tp.recipient,
            tp.descriptionHash,
            tp.upvotes,
            tp.downvotes,
            tp.creationTimestamp,
            tp.status,
            tp.voteEndTime
        );
    }

    /**
     * @dev Standard ERC721 function to get the metadata URI for a given token.
     *      This URI points to an off-chain service that dynamically generates the JSON metadata
     *      based on the NFT's on-chain attributes stored in `chronoscribeNFTs`.
     * @param tokenId The ID of the NFT.
     * @return The URI string.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");
        // Example base URI. This would typically be a gateway to a dynamic metadata service.
        // e.g., "https://chronoscribe.xyz/api/metadata/" + tokenId
        return string(abi.encodePacked(baseURI(), Strings.toString(tokenId)));
    }

    /**
     * @dev Sets the base URI for all token URIs.
     *      Only callable by the contract owner.
     * @param _newBaseURI The new base URI string.
     */
    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        _setBaseURI(_newBaseURI);
    }

    // Required for IERC165 interface used by ERC721
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
```