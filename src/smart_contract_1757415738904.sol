Here is a Solidity smart contract named `AetherMindNexus`, designed with advanced, creative, and trendy concepts for a decentralized knowledge and reputation network. It integrates dynamic NFTs, a reputation-weighted governance system, and a unique decentralized peer-review mechanism.

The contract focuses on the following key areas:

*   **AetherReputation:** A non-transferable, dynamic score reflecting a user's standing and trustworthiness within the network.
*   **Knowledge Units (KUs):** On-chain records pointing to off-chain knowledge (e.g., research papers, datasets, articles stored on IPFS).
*   **Decentralized Review:** A system where reputation-holding members stake tokens to review KUs, with rewards/penalties based on the accuracy of their reviews.
*   **MindGem NFTs:** Dynamic, soulbound (non-transferable) NFTs that visually evolve based on a user's AetherReputation tier and achievements.
*   **Governance:** A reputation-weighted voting system allowing AetherReputation holders to propose and vote on key platform parameters.

---

## Contract: `AetherMindNexus`

**Purpose:** A decentralized platform for curating and validating knowledge, fostering an on-chain reputation system, and incentivizing high-quality contributions and peer reviews. Users submit "Knowledge Units" (KU) – pointers to off-chain data (e.g., IPFS CIDs). These KUs undergo a decentralized review process. Successful contributions and accurate reviews build "AetherReputation," which is tied to governance power and represented by dynamic "MindGem" NFTs.

**Core Concepts:**
1.  **AetherReputation:** A non-transferable, dynamic score reflecting a user's standing and trustworthiness within the network, earned through validated contributions and accurate reviews. It can decay over time or boost with consistent activity.
2.  **Knowledge Units (KUs):** On-chain records pointing to off-chain knowledge (e.g., research papers, datasets, articles stored on IPFS).
3.  **Decentralized Review:** A system where reputation-holding members stake tokens to review KUs. Consensus determines acceptance, and reviewers are rewarded or penalized based on the outcome.
4.  **MindGem NFTs:** Dynamic, soulbound (non-transferable) NFTs that visually evolve based on a user's AetherReputation tier and achievements, acting as a verifiable on-chain identity and badge of honor.
5.  **Governance:** A reputation-weighted voting system allowing AetherReputation holders to propose and vote on key platform parameters.

**Key Features:**
*   Submit and manage Knowledge Units.
*   Stake and submit reviews for Knowledge Units.
*   Reputation-based rewards and penalties.
*   Dynamic AetherReputation system with potential for decay/boost.
*   Integration with external ERC-20 token for staking/rewards.
*   Integration with external ERC-721 for dynamic, soulbound MindGem NFTs.
*   On-chain governance for system parameters.

---

**Function Summary:**

**I. Initialization & Administration (4 functions):**
1.  `constructor`: Deploys the contract, setting up initial roles and dependencies (AetherToken, MindGem NFT addresses).
2.  `updateAetherTokenAddress`: Admin function to set or update the address of the `$AETH` ERC-20 token.
3.  `updateMindGemNFTAddress`: Admin function to set or update the address of the MindGem ERC-721 NFT contract.
4.  `pause` / `unpause`: Admin functions to pause or unpause critical contract operations, useful for upgrades or emergency situations.

**II. AetherReputation Management (4 functions):**
5.  `getAetherReputation`: Retrieves the current AetherReputation score for a given address.
6.  `getReputationTier`: Determines the reputation tier (e.g., Novice, Scholar, Sage) for a given address based on their AetherReputation.
7.  `triggerReputationDecay`: Callable by a designated keeper/oracle (or any user in a public keeper model) to initiate a decay cycle for inactive reputations, preventing stale scores.
8.  `proposeReputationBoostAdjustment`: Allows a community member (with sufficient reputation) to propose a manual reputation boost for another user, which then goes through governance.

**III. Knowledge Unit (KU) Management (4 functions):**
9.  `submitKnowledgeUnit`: Allows a user to submit a new Knowledge Unit (KU) with an IPFS CID, title, description, and categories, initiating the review process.
10. `getKnowledgeUnitDetails`: Retrieves all comprehensive details of a specific Knowledge Unit.
11. `updateKnowledgeUnitMetadata`: Allows the KU owner to update metadata (CID, title, description) for a pending KU before it's finalized.
12. `retractKnowledgeUnit`: Allows the KU owner to withdraw a pending Knowledge Unit, refunding any reviewer stakes if applicable.

**IV. Decentralized Review System (5 functions):**
13. `stakeForReview`: Allows a user with sufficient reputation to stake `$AETH` tokens, indicating their intent to review a pending KU.
14. `submitReview`: Allows a staked reviewer to submit their verdict (approved/rejected) and provide an IPFS CID for detailed feedback on a KU.
15. `getReviewOutcome`: Retrieves the specific details of a particular reviewer's submission for a KU.
16. `finalizeKnowledgeUnitReview`: Triggered after sufficient reviews, it calculates consensus (majority vote), distributes rewards/penalties, and updates reputations for both contributor and reviewers.
17. `claimReviewStake`: Allows a reviewer to claim back their initial stake (or the remaining portion after potential slashes) once a KU has been finalized.

**V. MindGem NFT Integration (3 functions):**
18. `mintMindGem`: Internally called or callable by a user to mint their unique MindGem NFT upon meeting initial reputation requirements or making their first contribution.
19. `syncMindGemVisuals`: Triggers an update to the metadata URI of a user's MindGem NFT, reflecting their current AetherReputation and achievements dynamically.
20. `getMindGemTokenId`: Returns the MindGem NFT token ID owned by a specific address, or 0 if they don't have one.

**VI. Tokenomics & Rewards (3 functions):**
21. `claimContributionRewards`: Allows a contributor to claim `$AETH` rewards for their Knowledge Units that have been successfully accepted by the community.
22. `claimReviewerRewards`: Allows a reviewer to claim `$AETH` rewards for their accurately submitted reviews after a KU's finalization.
23. `withdrawContractFunds`: Admin function to safely withdraw any excess or accidentally sent tokens from the contract to the owner's address.

**VII. Decentralized Governance (4 functions):**
24. `proposeParameterChange`: Allows users with sufficient reputation to propose changes to configurable contract parameters (e.g., review stake amount, reward percentages, voting periods).
25. `voteOnParameterChange`: Allows users to cast their AetherReputation-weighted vote on an active governance proposal.
26. `getProposalDetails`: Retrieves the current status and comprehensive details of a specific governance proposal.
27. `executeParameterChange`: Executable by anyone after a voting period concludes, applying the proposed parameter change if the proposal succeeded based on reputation-weighted votes.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; // For converting uint256 to string for URI

// --- Interfaces for external contracts ---

/**
 * @title IMindGemNFT
 * @dev Interface for the MindGem ERC-721 NFT contract.
 *      Assumes the NFT contract has specific functions for this system to mint
 *      and update the tokenURI (for dynamic visuals).
 */
interface IMindGemNFT is IERC721 {
    function mint(address to, uint256 tokenId, string memory tokenURI) external;
    function updateTokenURI(uint256 tokenId, string memory newTokenURI) external;
    function getTokenIdForUser(address user) external view returns (uint256);
}

/**
 * @title IAetherToken
 * @dev Interface for the AetherToken (ERC-20) used for staking and rewards.
 */
interface IAetherToken is IERC20 {
    // Standard ERC-20 functions are already in IERC20
}

/**
 * @title AetherMindNexus
 * @dev A decentralized platform for curating and validating knowledge, fostering an on-chain reputation system,
 *      and incentivizing high-quality contributions and peer reviews. Users submit "Knowledge Units" (KU) –
 *      pointers to off-chain data (e.g., IPFS CIDs). These KUs undergo a decentralized review process.
 *      Successful contributions and accurate reviews build "AetherReputation," which is tied to governance power
 *      and represented by dynamic "MindGem" NFTs.
 *
 * Core Concepts:
 * 1.  AetherReputation: A non-transferable, dynamic score reflecting a user's standing and trustworthiness within the network,
 *     earned through validated contributions and accurate reviews. It can decay over time or boost with consistent activity.
 * 2.  Knowledge Units (KUs): On-chain records pointing to off-chain knowledge (e.g., research papers, datasets, articles stored on IPFS).
 * 3.  Decentralized Review: A system where reputation-holding members stake tokens to review KUs. Consensus determines acceptance,
 *     and reviewers are rewarded or penalized based on the outcome.
 * 4.  MindGem NFTs: Dynamic, soulbound (non-transferable) NFTs that visually evolve based on a user's AetherReputation tier
 *     and achievements, acting as a verifiable on-chain identity and badge of honor.
 * 5.  Governance: A reputation-weighted voting system allowing AetherReputation holders to propose and vote on key platform parameters.
 *
 * Key Features:
 * *   Submit and manage Knowledge Units.
 * *   Stake and submit reviews for Knowledge Units.
 * *   Reputation-based rewards and penalties.
 * *   Dynamic AetherReputation system with potential for decay/boost.
 * *   Integration with external ERC-20 token for staking/rewards.
 * *   Integration with external ERC-721 for dynamic, soulbound MindGem NFTs.
 * *   On-chain governance for system parameters.
 */
contract AetherMindNexus is Ownable, Pausable, ReentrancyGuard {

    // --- State Variables & Enums ---

    IAetherToken public aetherToken;
    IMindGemNFT public mindGemNFT;

    uint256 public nextKnowledgeUnitId;
    uint256 public nextMindGemTokenId; // Tracks next available token ID for MindGem NFT
    uint256 public nextProposalId;

    // Reputation related
    mapping(address => int256) public aetherReputation; // Can be negative for penalties
    mapping(address => uint256) public lastReputationActivity; // To track decay
    uint256 public constant MIN_REPUTATION_FOR_REVIEW = 500;
    uint256 public constant INITIAL_MINDGEM_MINT_REPUTATION = 100; // Rep needed to mint first MindGem

    // Adjustable Governance Parameters (default values)
    uint256 public PARAM_REVIEW_STAKE_AMOUNT = 100 * (10 ** 18); // 100 AETH
    uint256 public PARAM_KU_ACCEPT_REWARD = 500 * (10 ** 18); // 500 AETH
    uint256 public PARAM_REVIEWER_ACCURATE_REWARD = 50 * (10 ** 18); // 50 AETH
    uint256 public PARAM_REVIEWER_INACCURATE_SLASH = 75 * (10 ** 18); // 75 AETH
    uint256 public PARAM_REPUTATION_GAIN_KU_ACCEPT = 100;
    uint256 public PARAM_REPUTATION_GAIN_ACCURATE_REVIEW = 20;
    uint256 public PARAM_REPUTATION_LOSS_KU_REJECT = 50;
    uint256 public PARAM_REPUTATION_LOSS_INACCURATE_REVIEW = 30;
    uint256 public PARAM_REPUTATION_DECAY_RATE_PER_WEEK = 5; // 5% per week of inactivity
    uint256 public PARAM_MIN_REVIEWS_FOR_FINALIZATION = 3;
    uint256 public PARAM_PROPOSAL_MIN_REPUTATION = 1000; // Min rep to propose
    uint256 public PARAM_VOTING_PERIOD = 7 days;
    uint256 public PARAM_MAJORITY_THRESHOLD = 50; // 50% + 1 for simple majority
    uint256 public PARAM_REPUTATION_BOOST_PROPOSAL_GRACE_PERIOD = 3 days; // For dedicated boost proposals

    // Reputation Tiers (for MindGem visuals)
    enum ReputationTier { Novice, Explorer, Scholar, Sage, Luminary }

    struct KnowledgeUnit {
        address owner;
        string ipfsCID;
        string title;
        string description;
        string[] categories;
        uint256 submissionTime;
        bool isFinalized;
        bool isAccepted;
        uint256 acceptedTime;
        uint256 approvalCount;
        uint256 rejectionCount;
        mapping(address => Review) reviews; // Reviewer address => Review
        address[] currentReviewers; // List of addresses currently reviewing
        mapping(address => bool) hasClaimedRewards; // For contributors
        mapping(address => bool) hasClaimedReviewStake; // For reviewers
    }

    struct Review {
        bool hasStaked;
        bool approved; // true for approve, false for reject
        string feedbackCID;
        uint256 stakeAmount; // The amount staked by this reviewer
        bool isFinalized; // True after KU is finalized
        bool wasAccurate; // True if this review matched the final outcome
    }

    enum ProposalState { Pending, Active, Succeeded, Failed, Executed }

    struct GovernanceProposal {
        address proposer;
        bytes32 parameterKey; // The identifier for the parameter to change (hashed string)
        uint256 newValue; // The new value for the parameter
        string description;
        uint256 creationTime;
        uint256 votingEndTime;
        uint256 totalVotesFor; // Total AetherReputation voting for
        uint256 totalVotesAgainst; // Total AetherReputation voting against
        mapping(address => bool) hasVoted;
        ProposalState state;
        address targetAddress; // For specific proposals like reputation boost
    }

    mapping(uint256 => KnowledgeUnit) public knowledgeUnits;
    mapping(uint256 => GovernanceProposal) public proposals;

    // A mapping from a user's address to their MindGem token ID
    mapping(address => uint256) public userMindGemTokenId;

    // --- Events ---

    event AetherTokenAddressUpdated(address indexed newAddress);
    event MindGemNFTAddressUpdated(address indexed newAddress);
    event Paused(address account);
    event Unpaused(address account);

    event ReputationAdjusted(address indexed user, int256 amount, int256 newReputation, string reason);
    event ReputationDecayTriggered(uint256 timestamp); // Simplified global trigger for decay
    event ReputationBoostProposed(uint256 indexed proposalId, address indexed proposer, address indexed targetUser, uint256 amount);

    event KnowledgeUnitSubmitted(uint256 indexed kuId, address indexed owner, string ipfsCID, string title);
    event KnowledgeUnitMetadataUpdated(uint256 indexed kuId, string newIpfsCID, string newTitle);
    event KnowledgeUnitRetracted(uint256 indexed kuId);

    event ReviewStaked(uint256 indexed kuId, address indexed reviewer, uint256 stakeAmount);
    event ReviewSubmitted(uint256 indexed kuId, address indexed reviewer, bool approved, string feedbackCID);
    event KnowledgeUnitFinalized(uint256 indexed kuId, bool accepted, uint256 approvalCount, uint256 rejectionCount);
    event ReviewStakeClaimed(uint256 indexed kuId, address indexed reviewer, uint256 claimedAmount);

    event MindGemMinted(address indexed user, uint256 indexed tokenId);
    event MindGemVisualsSynced(address indexed user, uint256 indexed tokenId, string newURI);

    event ContributionRewardsClaimed(uint256 indexed kuId, address indexed contributor, uint256 amount);
    event ReviewerRewardsClaimed(uint256 indexed kuId, address indexed reviewer, uint256 amount);
    event ContractFundsWithdrawn(address indexed tokenAddress, address indexed to, uint256 amount);

    event ParameterChangeProposed(uint256 indexed proposalId, bytes32 indexed parameterKey, uint256 newValue, string description);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 voteWeight);
    event ProposalStateChanged(uint256 indexed proposalId, ProposalState newState);
    event ParameterChangeExecuted(uint256 indexed proposalId, bytes32 indexed parameterKey, uint256 newValue);

    // --- Constructor ---

    /**
     * @dev Constructor for AetherMindNexus.
     * @param _aetherTokenAddress The address of the AetherToken ERC-20 contract.
     * @param _mindGemNFTAddress The address of the MindGem NFT ERC-721 contract.
     */
    constructor(address _aetherTokenAddress, address _mindGemNFTAddress) Ownable(msg.sender) {
        require(_aetherTokenAddress != address(0), "Invalid AetherToken address");
        require(_mindGemNFTAddress != address(0), "Invalid MindGem NFT address");

        aetherToken = IAetherToken(_aetherTokenAddress);
        mindGemNFT = IMindGemNFT(_mindGemNFTAddress);
        
        nextKnowledgeUnitId = 1; // Start KUID from 1
        nextMindGemTokenId = 1; // Start MindGem token ID from 1
        nextProposalId = 1; // Start Proposal ID from 1
    }

    // --- Internal Helpers ---

    /**
     * @dev Internal function to adjust a user's AetherReputation.
     * Also updates last activity timestamp.
     * @param user The address of the user whose reputation is being adjusted.
     * @param amount The amount to add to or subtract from the reputation. Can be negative.
     * @param reason A string describing the reason for the reputation adjustment.
     */
    function _adjustReputation(address user, int256 amount, string memory reason) internal {
        aetherReputation[user] += amount;
        lastReputationActivity[user] = block.timestamp;
        emit ReputationAdjusted(user, amount, aetherReputation[user], reason);
    }

    /**
     * @dev Internal function to ensure the caller has a MindGem NFT and gets its ID.
     * @param user The address of the user.
     * @return The token ID of the user's MindGem NFT.
     */
    function _getUserMindGemTokenId(address user) internal view returns (uint256) {
        uint256 tokenId = userMindGemTokenId[user];
        require(tokenId != 0, "User does not own a MindGem NFT yet.");
        return tokenId;
    }

    /**
     * @dev Internal function to get the current AetherReputation of a user.
     * This function should ideally incorporate decay logic if `triggerReputationDecay` isn't
     * called frequently enough or on a per-user basis. For this example, decay is a separate call.
     * @param user The address of the user.
     * @return The current AetherReputation score.
     */
    function _getCurrentReputation(address user) internal view returns (int256) {
        // In a more complex system, reputation decay could be dynamically calculated here
        // based on `lastReputationActivity[user]` and `PARAM_REPUTATION_DECAY_RATE_PER_WEEK`.
        // This is omitted for gas efficiency on every read and relies on `triggerReputationDecay`
        // or other user interactions to update `lastReputationActivity`.
        return aetherReputation[user];
    }

    // --- I. Initialization & Administration (4 functions) ---

    /**
     * @dev Updates the address of the AetherToken ERC-20 contract. Only callable by the owner.
     * @param _newAddress The new address for the AetherToken contract.
     */
    function updateAetherTokenAddress(address _newAddress) public onlyOwner {
        require(_newAddress != address(0), "Invalid AetherToken address");
        aetherToken = IAetherToken(_newAddress);
        emit AetherTokenAddressUpdated(_newAddress);
    }

    /**
     * @dev Updates the address of the MindGem NFT ERC-721 contract. Only callable by the owner.
     * @param _newAddress The new address for the MindGem NFT contract.
     */
    function updateMindGemNFTAddress(address _newAddress) public onlyOwner {
        require(_newAddress != address(0), "Invalid MindGem NFT address");
        mindGemNFT = IMindGemNFT(_newAddress);
        emit MindGemNFTAddressUpdated(_newAddress);
    }

    /**
     * @dev Pauses the contract. Only callable by the owner.
     * Critical operations will be blocked while paused.
     */
    function pause() public onlyOwner {
        _pause();
        emit Paused(msg.sender);
    }

    /**
     * @dev Unpauses the contract. Only callable by the owner.
     * Resumes critical operations.
     */
    function unpause() public onlyOwner {
        _unpause();
        emit Unpaused(msg.sender);
    }

    // --- II. AetherReputation Management (4 functions) ---

    /**
     * @dev Retrieves the current AetherReputation score for a given address.
     * @param user The address of the user.
     * @return The current AetherReputation score.
     */
    function getAetherReputation(address user) public view returns (int256) {
        return _getCurrentReputation(user);
    }

    /**
     * @dev Determines the reputation tier for a given address based on their AetherReputation score.
     * @param user The address of the user.
     * @return The ReputationTier enum value.
     */
    function getReputationTier(address user) public view returns (ReputationTier) {
        int256 rep = _getCurrentReputation(user);
        if (rep < 100) return ReputationTier.Novice;
        if (rep < 500) return ReputationTier.Explorer;
        if (rep < 2000) return ReputationTier.Scholar;
        if (rep < 5000) return ReputationTier.Sage;
        return ReputationTier.Luminary;
    }

    /**
     * @dev Triggers reputation decay for inactive users.
     * This function can be called by anyone (e.g., a keeper bot) to keep reputation scores current.
     * In this simplified model, it serves as a placeholder. A robust implementation would either:
     * 1. Require users to update their own reputation, triggering decay if due.
     * 2. Implement a batched processing for a set of inactive users by a keeper.
     * Iterating all users on-chain is too gas-intensive. The actual decay calculation
     * for a specific user would typically occur upon their next interaction or a dedicated update call.
     */
    function triggerReputationDecay() public nonReentrant {
        // This function is a global trigger placeholder.
        // Actual decay logic (e.g., `_adjustReputation(user, -decayAmount, "Decay")`)
        // would need to be applied to individual users either by:
        // A) Each user calling a `updateMyReputation()` function which computes their decay.
        // B) An off-chain keeper service identifying inactive users and submitting batched decay transactions.
        emit ReputationDecayTriggered(block.timestamp);
    }

    /**
     * @dev Allows a community member with sufficient reputation to propose a manual reputation boost for a user.
     * This proposal is subject to reputation-weighted governance voting.
     * @param targetUser The address of the user to receive the reputation boost.
     * @param amount The amount of reputation to boost. Must be positive.
     * @param reason A description for why the boost is being proposed.
     */
    function proposeReputationBoostAdjustment(address targetUser, uint256 amount, string memory reason)
        public
        whenNotPaused
        nonReentrant
    {
        require(targetUser != address(0), "Invalid target user address");
        require(amount > 0, "Boost amount must be positive");
        require(_getCurrentReputation(msg.sender) >= int256(PARAM_PROPOSAL_MIN_REPUTATION), "Insufficient reputation to propose");

        uint256 proposalId = nextProposalId++;

        proposals[proposalId] = GovernanceProposal({
            proposer: msg.sender,
            parameterKey: keccak256(abi.encodePacked("ReputationBoost")), // Specific key for boost proposals
            newValue: amount, // The boost amount
            description: string(abi.encodePacked("Reputation boost for ", Strings.toHexString(uint160(targetUser), 20), ": ", reason)),
            creationTime: block.timestamp,
            votingEndTime: block.timestamp + PARAM_REPUTATION_BOOST_PROPOSAL_GRACE_PERIOD, // Shorter voting for boosts
            totalVotesFor: 0,
            totalVotesAgainst: 0,
            hasVoted: new mapping(address => bool),
            state: ProposalState.Active,
            targetAddress: targetUser // Store target address directly
        });

        emit ReputationBoostProposed(proposalId, msg.sender, targetUser, amount);
        emit ParameterChangeProposed(proposalId, keccak256(abi.encodePacked("ReputationBoost")), amount, proposals[proposalId].description);
    }

    // --- III. Knowledge Unit (KU) Management (4 functions) ---

    /**
     * @dev Allows a user to submit a new Knowledge Unit (KU).
     * Requirements: Contract must not be paused.
     * @param ipfsCID The IPFS Content Identifier for the knowledge data.
     * @param title The title of the Knowledge Unit.
     * @param description A brief description of the Knowledge Unit.
     * @param categories An array of categories for the Knowledge Unit (e.g., "AI", "Blockchain", "Biology").
     */
    function submitKnowledgeUnit(string memory ipfsCID, string memory title, string memory description, string[] memory categories)
        public
        whenNotPaused
        nonReentrant
    {
        require(bytes(ipfsCID).length > 0, "IPFS CID cannot be empty");
        require(bytes(title).length > 0, "Title cannot be empty");
        // Additional validation for IPFS CID format, categories, etc., could be added.

        uint256 kuId = nextKnowledgeUnitId++;
        knowledgeUnits[kuId].owner = msg.sender;
        knowledgeUnits[kuId].ipfsCID = ipfsCID;
        knowledgeUnits[kuId].title = title;
        knowledgeUnits[kuId].description = description;
        knowledgeUnits[kuId].categories = categories; 
        knowledgeUnits[kuId].submissionTime = block.timestamp;
        knowledgeUnits[kuId].isFinalized = false;
        knowledgeUnits[kuId].isAccepted = false; // Default
        knowledgeUnits[kuId].approvalCount = 0;
        knowledgeUnits[kuId].rejectionCount = 0;

        // Optionally, mint MindGem if it's the user's first contribution and they meet rep threshold
        if (userMindGemTokenId[msg.sender] == 0 && _getCurrentReputation(msg.sender) >= int256(INITIAL_MINDGEM_MINT_REPUTATION)) {
            mintMindGem(msg.sender);
        }

        emit KnowledgeUnitSubmitted(kuId, msg.sender, ipfsCID, title);
    }

    /**
     * @dev Retrieves all details of a specific Knowledge Unit.
     * @param kuId The ID of the Knowledge Unit.
     * @return owner The address of the KU owner.
     * @return ipfsCID The IPFS Content Identifier.
     * @return title The title of the KU.
     * @return description A brief description.
     * @return categories An array of categories.
     * @return submissionTime The timestamp of submission.
     * @return isFinalized True if the review process is complete.
     * @return isAccepted True if the KU was accepted.
     * @return approvalCount Number of approval reviews.
     * @return rejectionCount Number of rejection reviews.
     */
    function getKnowledgeUnitDetails(uint256 kuId)
        public
        view
        returns (
            address owner,
            string memory ipfsCID,
            string memory title,
            string memory description,
            string[] memory categories,
            uint256 submissionTime,
            bool isFinalized,
            bool isAccepted,
            uint256 approvalCount,
            uint256 rejectionCount
        )
    {
        KnowledgeUnit storage ku = knowledgeUnits[kuId];
        require(ku.owner != address(0), "Knowledge Unit does not exist");

        return (
            ku.owner,
            ku.ipfsCID,
            ku.title,
            ku.description,
            ku.categories,
            ku.submissionTime,
            ku.isFinalized,
            ku.isAccepted,
            ku.approvalCount,
            ku.rejectionCount
        );
    }

    /**
     * @dev Allows the owner of a Knowledge Unit to update its metadata (IPFS CID, title, description).
     * This is only allowed if the KU is not yet finalized.
     * @param kuId The ID of the Knowledge Unit.
     * @param newIpfsCID The new IPFS CID.
     * @param newTitle The new title.
     * @param newDescription The new description.
     */
    function updateKnowledgeUnitMetadata(uint256 kuId, string memory newIpfsCID, string memory newTitle, string memory newDescription)
        public
        whenNotPaused
        nonReentrant
    {
        KnowledgeUnit storage ku = knowledgeUnits[kuId];
        require(ku.owner == msg.sender, "Only KU owner can update metadata");
        require(!ku.isFinalized, "Cannot update finalized Knowledge Unit");
        require(bytes(newIpfsCID).length > 0, "New IPFS CID cannot be empty");
        require(bytes(newTitle).length > 0, "New title cannot be empty");

        ku.ipfsCID = newIpfsCID;
        ku.title = newTitle;
        ku.description = newDescription;

        emit KnowledgeUnitMetadataUpdated(kuId, newIpfsCID, newTitle);
    }

    /**
     * @dev Allows the owner of a Knowledge Unit to retract it if it has not yet been finalized.
     * @param kuId The ID of the Knowledge Unit to retract.
     */
    function retractKnowledgeUnit(uint256 kuId) public whenNotPaused nonReentrant {
        KnowledgeUnit storage ku = knowledgeUnits[kuId];
        require(ku.owner != address(0), "Knowledge Unit does not exist");
        require(ku.owner == msg.sender, "Only KU owner can retract");
        require(!ku.isFinalized, "Cannot retract finalized Knowledge Unit");

        // Refund any reviewer stakes for this KU that were submitted before retraction
        for (uint256 i = 0; i < ku.currentReviewers.length; i++) {
            address reviewer = ku.currentReviewers[i];
            if (ku.reviews[reviewer].hasStaked && !ku.reviews[reviewer].isFinalized) { // Only refund if stake hasn't been finalized/claimed
                uint256 stake = ku.reviews[reviewer].stakeAmount;
                if (stake > 0) {
                    aetherToken.transfer(reviewer, stake);
                    emit ReviewStakeClaimed(kuId, reviewer, stake);
                }
            }
        }

        delete knowledgeUnits[kuId]; // Remove the KU
        emit KnowledgeUnitRetracted(kuId);
    }

    // --- IV. Decentralized Review System (5 functions) ---

    /**
     * @dev Allows a user with sufficient AetherReputation to stake tokens to review a pending Knowledge Unit.
     * @param kuId The ID of the Knowledge Unit to review.
     */
    function stakeForReview(uint256 kuId) public whenNotPaused nonReentrant {
        KnowledgeUnit storage ku = knowledgeUnits[kuId];
        require(ku.owner != address(0), "Knowledge Unit does not exist");
        require(!ku.isFinalized, "Knowledge Unit is already finalized");
        require(ku.owner != msg.sender, "Cannot review your own Knowledge Unit");
        require(_getCurrentReputation(msg.sender) >= int256(MIN_REPUTATION_FOR_REVIEW), "Insufficient reputation to review");
        require(!ku.reviews[msg.sender].hasStaked, "Already staked for this review");

        // Transfer stake amount from reviewer to this contract
        require(aetherToken.transferFrom(msg.sender, address(this), PARAM_REVIEW_STAKE_AMOUNT), "AetherToken transfer failed");

        ku.reviews[msg.sender].hasStaked = true;
        ku.reviews[msg.sender].stakeAmount = PARAM_REVIEW_STAKE_AMOUNT;
        ku.currentReviewers.push(msg.sender); // Add reviewer to list for this KU

        emit ReviewStaked(kuId, msg.sender, PARAM_REVIEW_STAKE_AMOUNT);
    }

    /**
     * @dev Allows a staked reviewer to submit their verdict (approved/rejected) and feedback CID for a KU.
     * Requires the reviewer to have first staked for the review.
     * @param kuId The ID of the Knowledge Unit being reviewed.
     * @param approved True if the reviewer approves the KU, false if they reject it.
     * @param feedbackCID The IPFS CID for detailed review feedback.
     */
    function submitReview(uint256 kuId, bool approved, string memory feedbackCID) public whenNotPaused nonReentrant {
        KnowledgeUnit storage ku = knowledgeUnits[kuId];
        require(ku.owner != address(0), "Knowledge Unit does not exist");
        require(!ku.isFinalized, "Knowledge Unit is already finalized");
        require(ku.owner != msg.sender, "Cannot review your own Knowledge Unit");

        Review storage review = ku.reviews[msg.sender];
        require(review.hasStaked, "Must stake for review before submitting");
        require(bytes(review.feedbackCID).length == 0, "Review already submitted"); // Can only submit once

        review.approved = approved;
        review.feedbackCID = feedbackCID;

        if (approved) {
            ku.approvalCount++;
        } else {
            ku.rejectionCount++;
        }

        emit ReviewSubmitted(kuId, msg.sender, approved, feedbackCID);
    }

    /**
     * @dev Retrieves the details of a specific reviewer's submission for a Knowledge Unit.
     * @param kuId The ID of the Knowledge Unit.
     * @param reviewer The address of the reviewer.
     * @return hasStaked True if the reviewer has staked.
     * @return approved True if the reviewer approved, false if rejected.
     * @return feedbackCID The IPFS CID of the feedback.
     * @return stakeAmount The amount staked by the reviewer.
     * @return isFinalized True if the review for this KU is finalized.
     * @return wasAccurate True if this review matched the final outcome.
     */
    function getReviewOutcome(uint256 kuId, address reviewer)
        public
        view
        returns (
            bool hasStaked,
            bool approved,
            string memory feedbackCID,
            uint256 stakeAmount,
            bool isFinalized,
            bool wasAccurate
        )
    {
        KnowledgeUnit storage ku = knowledgeUnits[kuId];
        require(ku.owner != address(0), "Knowledge Unit does not exist");
        Review storage review = ku.reviews[reviewer];

        return (
            review.hasStaked,
            review.approved,
            review.feedbackCID,
            review.stakeAmount,
            review.isFinalized,
            review.wasAccurate
        );
    }

    /**
     * @dev Finalizes a Knowledge Unit's review process after enough reviews have been submitted.
     * Calculates consensus, distributes rewards/penalties, and updates reputations.
     * This function can be called by anyone (e.g., a keeper bot) once `PARAM_MIN_REVIEWS_FOR_FINALIZATION` is met.
     * @param kuId The ID of the Knowledge Unit to finalize.
     */
    function finalizeKnowledgeUnitReview(uint256 kuId) public whenNotPaused nonReentrant {
        KnowledgeUnit storage ku = knowledgeUnits[kuId];
        require(ku.owner != address(0), "Knowledge Unit does not exist");
        require(!ku.isFinalized, "Knowledge Unit is already finalized");
        require(ku.approvalCount + ku.rejectionCount >= PARAM_MIN_REVIEWS_FOR_FINALIZATION, "Not enough reviews to finalize");

        ku.isFinalized = true;
        ku.acceptedTime = block.timestamp;

        // Determine final outcome: simple majority vote
        bool finalAcceptance = ku.approvalCount > ku.rejectionCount;
        ku.isAccepted = finalAcceptance;

        // Adjust contributor's reputation
        if (finalAcceptance) {
            _adjustReputation(ku.owner, int256(PARAM_REPUTATION_GAIN_KU_ACCEPT), "Knowledge Unit accepted");
        } else {
            _adjustReputation(ku.owner, -int256(PARAM_REPUTATION_LOSS_KU_REJECT), "Knowledge Unit rejected");
        }

        // Adjust reviewers' reputation and stakes
        for (uint256 i = 0; i < ku.currentReviewers.length; i++) {
            address reviewer = ku.currentReviewers[i];
            Review storage review = ku.reviews[reviewer];
            if (!review.hasStaked || bytes(review.feedbackCID).length == 0) continue; // Skip if not fully reviewed

            review.isFinalized = true;
            if (review.approved == finalAcceptance) {
                // Reviewer was accurate
                review.wasAccurate = true;
                _adjustReputation(reviewer, int256(PARAM_REPUTATION_GAIN_ACCURATE_REVIEW), "Accurate review");
            } else {
                // Reviewer was inaccurate/malicious
                review.wasAccurate = false;
                _adjustReputation(reviewer, -int256(PARAM_REPUTATION_LOSS_INACCURATE_REVIEW), "Inaccurate review");
                // Slash stake. Slash amount remains in contract (e.g., for treasury/rewards pool).
                // Remaining stake is claimable.
                if (review.stakeAmount > PARAM_REVIEWER_INACCURATE_SLASH) {
                    review.stakeAmount -= PARAM_REVIEWER_INACCURATE_SLASH; 
                } else {
                    review.stakeAmount = 0; // Lost all stake
                }
            }
        }
        
        emit KnowledgeUnitFinalized(kuId, finalAcceptance, ku.approvalCount, ku.rejectionCount);

        // Sync MindGem visuals for contributor if they have one
        if (userMindGemTokenId[ku.owner] != 0) {
            syncMindGemVisuals(ku.owner);
        }
    }

    /**
     * @dev Allows a reviewer to claim back their stake if their review was deemed accurate
     *      or claim remaining stake if inaccurate (after the KU has been finalized).
     * @param kuId The ID of the Knowledge Unit.
     */
    function claimReviewStake(uint256 kuId) public whenNotPaused nonReentrant {
        KnowledgeUnit storage ku = knowledgeUnits[kuId];
        require(ku.owner != address(0), "Knowledge Unit does not exist");
        require(ku.isFinalized, "Knowledge Unit is not yet finalized");

        Review storage review = ku.reviews[msg.sender];
        require(review.hasStaked, "No stake found for this reviewer on this KU");
        require(review.isFinalized, "Review is not finalized yet");
        require(!ku.hasClaimedReviewStake[msg.sender], "Reviewer already claimed stake for this KU");

        uint256 amountToTransfer = review.stakeAmount; // This will be the remaining stake after any slash
        ku.hasClaimedReviewStake[msg.sender] = true;

        if (amountToTransfer > 0) {
            require(aetherToken.transfer(msg.sender, amountToTransfer), "Failed to transfer review stake");
            emit ReviewStakeClaimed(kuId, msg.sender, amountToTransfer);
        }
    }

    // --- V. MindGem NFT Integration (3 functions) ---

    /**
     * @dev Mints a unique MindGem NFT for the given user.
     * This function is callable by the user if they meet initial reputation requirements
     * and don't already own a MindGem. Or it can be called internally by the contract.
     * The token ID is managed by this contract and passed to the NFT contract.
     * @param user The address for whom to mint the MindGem.
     */
    function mintMindGem(address user) public whenNotPaused nonReentrant {
        require(user != address(0), "Invalid user address");
        require(userMindGemTokenId[user] == 0, "User already owns a MindGem NFT");
        require(_getCurrentReputation(user) >= int256(INITIAL_MINDGEM_MINT_REPUTATION), "Insufficient reputation to mint MindGem");

        uint256 tokenId = nextMindGemTokenId++;
        userMindGemTokenId[user] = tokenId;

        // Generate an initial token URI based on reputation and tier.
        // In a real system, this would point to a service (e.g., IPFS gateway + backend API)
        // that dynamically renders the NFT metadata and image based on on-chain state.
        string memory initialURI = string(abi.encodePacked(
            "https://mindgem.io/api/metadata/", Strings.toString(tokenId),
            "?owner=", Strings.toHexString(uint160(user), 20),
            "&rep=", Strings.toString(uint256(aetherReputation[user])),
            "&tier=", Strings.toString(uint256(getReputationTier(user)))
        ));
        
        mindGemNFT.mint(user, tokenId, initialURI);
        emit MindGemMinted(user, tokenId);
        emit MindGemVisualsSynced(user, tokenId, initialURI);
    }

    /**
     * @dev Triggers an update to the metadata URI of a user's MindGem NFT.
     * This reflects their current AetherReputation and achievements.
     * Callable by anyone, it pushes the current state to the NFT contract for dynamic visuals.
     * @param user The address of the MindGem owner.
     */
    function syncMindGemVisuals(address user) public whenNotPaused nonReentrant {
        uint256 tokenId = _getUserMindGemTokenId(user);
        
        // Construct the new metadata URI with updated reputation and tier.
        string memory newURI = string(abi.encodePacked(
            "https://mindgem.io/api/metadata/", Strings.toString(tokenId),
            "?owner=", Strings.toHexString(uint160(user), 20),
            "&rep=", Strings.toString(uint256(aetherReputation[user])),
            "&tier=", Strings.toString(uint256(getReputationTier(user)))
        ));
        
        mindGemNFT.updateTokenURI(tokenId, newURI);
        emit MindGemVisualsSynced(user, tokenId, newURI);
    }

    /**
     * @dev Returns the MindGem NFT tokenId owned by a specific address.
     * @param user The address of the user.
     * @return The token ID of the user's MindGem NFT, or 0 if none.
     */
    function getMindGemTokenId(address user) public view returns (uint256) {
        return userMindGemTokenId[user];
    }

    // --- VI. Tokenomics & Rewards (3 functions) ---

    /**
     * @dev Allows a contributor to claim $AETH rewards for their accepted Knowledge Units.
     * @param kuId The ID of the Knowledge Unit for which to claim rewards.
     */
    function claimContributionRewards(uint256 kuId) public whenNotPaused nonReentrant {
        KnowledgeUnit storage ku = knowledgeUnits[kuId];
        require(ku.owner != address(0), "Knowledge Unit does not exist");
        require(ku.owner == msg.sender, "Only KU owner can claim rewards");
        require(ku.isFinalized, "Knowledge Unit is not yet finalized");
        require(ku.isAccepted, "Knowledge Unit was not accepted, no rewards");
        require(!ku.hasClaimedRewards[msg.sender], "Contributor already claimed rewards for this KU");

        ku.hasClaimedRewards[msg.sender] = true;
        require(aetherToken.transfer(msg.sender, PARAM_KU_ACCEPT_REWARD), "Failed to transfer contribution rewards");

        emit ContributionRewardsClaimed(kuId, msg.sender, PARAM_KU_ACCEPT_REWARD);
    }

    /**
     * @dev Allows a reviewer to claim $AETH rewards for their accurately submitted reviews.
     * This is separate from stake claiming.
     * @param kuId The ID of the Knowledge Unit for which to claim reviewer rewards.
     */
    function claimReviewerRewards(uint256 kuId) public whenNotPaused nonReentrant {
        KnowledgeUnit storage ku = knowledgeUnits[kuId];
        require(ku.owner != address(0), "Knowledge Unit does not exist");
        require(ku.isFinalized, "Knowledge Unit is not yet finalized");

        Review storage review = ku.reviews[msg.sender];
        require(review.hasStaked, "No review found for this KU by caller");
        require(review.isFinalized, "Review is not finalized yet");
        require(review.wasAccurate, "Review was not accurate, no rewards");
        require(!ku.hasClaimedRewards[msg.sender], "Reviewer already claimed rewards for this KU"); // Reuse mapping for simplicity

        ku.hasClaimedRewards[msg.sender] = true;
        require(aetherToken.transfer(msg.sender, PARAM_REVIEWER_ACCURATE_REWARD), "Failed to transfer reviewer rewards");

        emit ReviewerRewardsClaimed(kuId, msg.sender, PARAM_REVIEWER_ACCURATE_REWARD);
    }

    /**
     * @dev Admin function to withdraw any excess or accidentally sent tokens from the contract.
     * Only callable by the owner.
     * @param tokenAddress The address of the ERC-20 token to withdraw.
     * @param amount The amount of tokens to withdraw.
     */
    function withdrawContractFunds(address tokenAddress, uint256 amount) public onlyOwner {
        require(tokenAddress != address(0), "Invalid token address");
        IERC20 token = IERC20(tokenAddress);
        require(token.balanceOf(address(this)) >= amount, "Insufficient contract balance");
        require(token.transfer(owner(), amount), "Token withdrawal failed");

        emit ContractFundsWithdrawn(tokenAddress, owner(), amount);
    }

    // --- VII. Decentralized Governance (4 functions) ---

    /**
     * @dev Allows users with sufficient reputation to propose changes to contract parameters.
     * @param parameterKey A string identifier for the parameter to change (e.g., "REVIEW_STAKE_AMOUNT").
     * @param newValue The new value for the parameter.
     * @param description A description of the proposal.
     */
    function proposeParameterChange(string memory parameterKey, uint256 newValue, string memory description)
        public
        whenNotPaused
        nonReentrant
    {
        require(_getCurrentReputation(msg.sender) >= int256(PARAM_PROPOSAL_MIN_REPUTATION), "Insufficient reputation to propose");
        require(bytes(parameterKey).length > 0, "Parameter key cannot be empty");
        // Further validation for parameterKey (e.g., exists in a whitelist of configurable parameters)
        // This relies on `_setParameter` to correctly interpret the key.

        uint256 proposalId = nextProposalId++;
        
        proposals[proposalId] = GovernanceProposal({
            proposer: msg.sender,
            parameterKey: keccak256(abi.encodePacked(parameterKey)),
            newValue: newValue,
            description: description,
            creationTime: block.timestamp,
            votingEndTime: block.timestamp + PARAM_VOTING_PERIOD,
            totalVotesFor: 0,
            totalVotesAgainst: 0,
            hasVoted: new mapping(address => bool),
            state: ProposalState.Active,
            targetAddress: address(0) // Not applicable for general parameter changes
        });

        emit ParameterChangeProposed(proposalId, proposals[proposalId].parameterKey, newValue, description);
    }

    /**
     * @dev Allows users to cast their AetherReputation-weighted vote on an active proposal.
     * @param proposalId The ID of the governance proposal.
     * @param support True to vote for the proposal, false to vote against.
     */
    function voteOnParameterChange(uint256 proposalId, bool support) public whenNotPaused nonReentrant {
        GovernanceProposal storage proposal = proposals[proposalId];
        require(proposal.proposer != address(0), "Proposal does not exist");
        require(proposal.state == ProposalState.Active, "Proposal is not active");
        require(block.timestamp <= proposal.votingEndTime, "Voting period has ended");
        require(!proposal.hasVoted[msg.sender], "Already voted on this proposal");

        int256 voterReputation = _getCurrentReputation(msg.sender);
        require(voterReputation > 0, "Voter must have positive AetherReputation");

        if (support) {
            proposal.totalVotesFor += uint256(voterReputation);
        } else {
            proposal.totalVotesAgainst += uint256(voterReputation);
        }
        proposal.hasVoted[msg.sender] = true;

        emit VoteCast(proposalId, msg.sender, support, uint256(voterReputation));
    }

    /**
     * @dev Retrieves the current status and details of a specific governance proposal.
     * @param proposalId The ID of the proposal.
     * @return proposer The address of the proposal's creator.
     * @return parameterKey The hash of the parameter key.
     * @return newValue The proposed new value.
     * @return description The proposal description.
     * @return creationTime The creation timestamp.
     * @return votingEndTime The voting end timestamp.
     * @return totalVotesFor Total reputation votes for.
     * @return totalVotesAgainst Total reputation votes against.
     * @return state The current state of the proposal.
     * @return targetAddress The target address for specific proposals (e.g., reputation boost).
     */
    function getProposalDetails(uint256 proposalId)
        public
        view
        returns (
            address proposer,
            bytes32 parameterKey,
            uint256 newValue,
            string memory description,
            uint256 creationTime,
            uint256 votingEndTime,
            uint256 totalVotesFor,
            uint256 totalVotesAgainst,
            ProposalState state,
            address targetAddress
        )
    {
        GovernanceProposal storage proposal = proposals[proposalId];
        require(proposal.proposer != address(0), "Proposal does not exist");
        return (
            proposal.proposer,
            proposal.parameterKey,
            proposal.newValue,
            proposal.description,
            proposal.creationTime,
            proposal.votingEndTime,
            proposal.totalVotesFor,
            proposal.totalVotesAgainst,
            proposal.state,
            proposal.targetAddress
        );
    }

    /**
     * @dev Executes a passed governance proposal, applying the proposed parameter change.
     * Callable by anyone after the voting period ends and if the proposal succeeded.
     * @param proposalId The ID of the proposal to execute.
     */
    function executeParameterChange(uint256 proposalId) public whenNotPaused nonReentrant {
        GovernanceProposal storage proposal = proposals[proposalId];
        require(proposal.proposer != address(0), "Proposal does not exist");
        require(proposal.state == ProposalState.Active, "Proposal is not active");
        require(block.timestamp > proposal.votingEndTime, "Voting period has not ended");

        // Check for vote outcome
        uint256 totalVotes = proposal.totalVotesFor + proposal.totalVotesAgainst;
        require(totalVotes > 0, "No votes cast on this proposal");

        if (proposal.totalVotesFor * 100 > totalVotes * PARAM_MAJORITY_THRESHOLD) {
            proposal.state = ProposalState.Succeeded;
            
            // Apply the parameter change or special action
            if (proposal.parameterKey == keccak256(abi.encodePacked("ReputationBoost"))) {
                // Special handling for ReputationBoost proposals
                require(proposal.targetAddress != address(0), "Reputation Boost proposal missing target address");
                _adjustReputation(proposal.targetAddress, int256(proposal.newValue), "Governance-approved reputation boost");
                emit ParameterChangeExecuted(proposalId, proposal.parameterKey, proposal.newValue);
            } else {
                _setParameter(proposal.parameterKey, proposal.newValue);
                emit ParameterChangeExecuted(proposalId, proposal.parameterKey, proposal.newValue);
            }

        } else {
            proposal.state = ProposalState.Failed;
        }
        emit ProposalStateChanged(proposalId, proposal.state);
    }

    /**
     * @dev Internal function to update a contract parameter based on a governance proposal.
     * This function uses `bytes32` keys for flexibility.
     * @param parameterKey The `bytes32` identifier for the parameter.
     * @param value The new value for the parameter.
     */
    function _setParameter(bytes32 parameterKey, uint256 value) internal {
        // This pattern allows for future expansion of configurable parameters
        if (parameterKey == keccak256(abi.encodePacked("PARAM_REVIEW_STAKE_AMOUNT"))) {
            PARAM_REVIEW_STAKE_AMOUNT = value;
        } else if (parameterKey == keccak256(abi.encodePacked("PARAM_KU_ACCEPT_REWARD"))) {
            PARAM_KU_ACCEPT_REWARD = value;
        } else if (parameterKey == keccak256(abi.encodePacked("PARAM_REVIEWER_ACCURATE_REWARD"))) {
            PARAM_REVIEWER_ACCURATE_REWARD = value;
        } else if (parameterKey == keccak256(abi.encodePacked("PARAM_REVIEWER_INACCURATE_SLASH"))) {
            PARAM_REVIEWER_INACCURATE_SLASH = value;
        } else if (parameterKey == keccak256(abi.encodePacked("PARAM_REPUTATION_GAIN_KU_ACCEPT"))) {
            PARAM_REPUTATION_GAIN_KU_ACCEPT = value;
        } else if (parameterKey == keccak256(abi.encodePacked("PARAM_REPUTATION_GAIN_ACCURATE_REVIEW"))) {
            PARAM_REPUTATION_GAIN_ACCURATE_REVIEW = value;
        } else if (parameterKey == keccak256(abi.encodePacked("PARAM_REPUTATION_LOSS_KU_REJECT"))) {
            PARAM_REPUTATION_LOSS_KU_REJECT = value;
        } else if (parameterKey == keccak256(abi.encodePacked("PARAM_REPUTATION_LOSS_INACCURATE_REVIEW"))) {
            PARAM_REPUTATION_LOSS_INACCURATE_REVIEW = value;
        } else if (parameterKey == keccak256(abi.encodePacked("PARAM_REPUTATION_DECAY_RATE_PER_WEEK"))) {
            PARAM_REPUTATION_DECAY_RATE_PER_WEEK = value;
        } else if (parameterKey == keccak256(abi.encodePacked("PARAM_MIN_REVIEWS_FOR_FINALIZATION"))) {
            PARAM_MIN_REVIEWS_FOR_FINALIZATION = value;
        } else if (parameterKey == keccak256(abi.encodePacked("PARAM_PROPOSAL_MIN_REPUTATION"))) {
            PARAM_PROPOSAL_MIN_REPUTATION = value;
        } else if (parameterKey == keccak256(abi.encodePacked("PARAM_VOTING_PERIOD"))) {
            PARAM_VOTING_PERIOD = value;
        } else if (parameterKey == keccak256(abi.encodePacked("PARAM_MAJORITY_THRESHOLD"))) {
            require(value <= 100, "Majority threshold cannot exceed 100%");
            PARAM_MAJORITY_THRESHOLD = value;
        } else if (parameterKey == keccak256(abi.encodePacked("PARAM_REPUTATION_BOOST_PROPOSAL_GRACE_PERIOD"))) {
            PARAM_REPUTATION_BOOST_PROPOSAL_GRACE_PERIOD = value;
        } else {
            revert("Unknown parameter key for general parameter change");
        }
    }
}
```