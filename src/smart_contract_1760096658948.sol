This smart contract, `AetheriumKnowledgeNexus`, is a sophisticated platform for decentralized collaborative research and knowledge verification. It integrates AI-assisted evaluation, a community-driven challenge/support mechanism, a reputation system, and tokenizes verified knowledge as NFTs with a licensing model. The goal is to create a trusted, immutable repository of high-quality data and research.

---

## AetheriumKnowledgeNexus: Outline and Function Summary

**Contract Name:** `AetheriumKnowledgeNexus`

**Description:** A decentralized platform for collaborative research, data bounties, and verifiable knowledge creation, integrating AI-assisted evaluation and a robust reputation system. Sponsors propose research topics/bounties, Contributors submit solutions/data, Verifiers stake to challenge or support submissions, and an AI Oracle provides assessments. Successful, verified solutions can be tokenized as unique Knowledge NFTs, enabling licensing.

**Core Concepts:**
*   **Decentralized Bounties:** Sponsors fund specific research questions or data collection tasks.
*   **AI-Assisted Evaluation:** A designated AI Oracle provides initial, potentially weighted, evaluations, leveraging off-chain computational power and cryptographic attestations (implicitly, as the contract trusts the oracle address).
*   **Verifier Consensus:** Community verifiers stake funds to challenge or support submitted solutions, creating a dynamic dispute resolution mechanism similar to a prediction market or Kleros.
*   **Reputation System:** Users earn or lose reputation based on successful contributions, verifications, and challenges, fostering trustworthiness within the ecosystem.
*   **Knowledge Tokenization:** Verified, high-quality solutions are minted as ERC721 NFTs, representing immutable and verifiable knowledge assets.
*   **Licensing Mechanism:** Owners of Knowledge NFTs can grant time-bound or commercial licenses for their data/research, enabling granular monetization and access control.

**Inheritance:**
*   `ERC721Enumerable`: For managing the Knowledge NFTs, allowing enumeration of all minted NFTs.
*   `AccessControl`: For managing roles (ADMIN, AI\_ORACLE).
*   `Pausable`: For emergency pausing of critical functions.
*   `ReentrancyGuard`: To prevent reentrancy attacks, enhancing security.

**State Variables:**
*   `ADMIN_ROLE`: Role for contract administration.
*   `AI_ORACLE_ROLE`: Role for the AI evaluation system.
*   `s_topicIdCounter`: Counter for research topics.
*   `s_solutionsNFTIdCounter`: Counter for Knowledge NFTs.
*   `s_topics`: Mapping from topic ID to `Topic` struct.
*   `s_solutions`: Nested mapping from topic ID to solution index to `Solution` struct.
*   `s_userReputation`: Mapping from user address to their reputation score.
*   `s_verifierStakes`: Mapping from verifier address to their currently staked funds.
*   `s_commissionRate`: Platform commission rate in basis points (e.g., 100 = 1%).
*   `s_verifierMinStake`: Minimum required stake for a verifier to participate.
*   `s_platformFeesAccrued`: Total fees accumulated by the platform.
*   `s_knowledgeLicenses`: Nested mapping for NFT licensing: `tokenId => licenseeAddress => KnowledgeLicense` struct.

**Enums:**
*   `TopicStatus`: `Open`, `Submission`, `Verification`, `Finalized`, `Cancelled`.
*   `SolutionStatus`: `Submitted`, `Challenged`, `Supported`, `AI_Evaluated`, `Verified`, `Rejected`.
*   `Verdict`: `None`, `Accepted`, `Rejected`.

**Events:**
*   `TopicProposed`: When a new topic is created.
*   `TopicFunded`: When a topic receives funds.
*   `SolutionSubmitted`: When a solution is submitted.
*   `SolutionRetracted`: When a solution is retracted.
*   `VerifierStaked`: When a user stakes as a verifier.
*   `VerifierUnstaked`: When a verifier unstakes.
*   `SolutionChallenged`: When a solution is challenged.
*   `SolutionSupported`: When a solution is supported.
*   `AIEvaluationSubmitted`: When AI oracle provides an evaluation.
*   `SolutionVerdictFinalized`: When a solution's verification concludes.
*   `RewardsClaimed`: When rewards are claimed (placeholder for a more complex system).
*   `KnowledgeNFTMinted`: When a new Knowledge NFT is minted.
*   `KnowledgeLicenseGranted`: When a license for a Knowledge NFT is granted.
*   `KnowledgeLicenseRevoked`: When a license for a Knowledge NFT is revoked.
*   `ReputationUpdated`: When a user's reputation changes.

---

### Function Summary (29 functions):

**I. Initialization & Configuration (4 functions)**

1.  `constructor(address _admin, address _aiOracle)`: Initializes the contract, sets the initial admin and AI oracle, grants roles, and sets default commission and verifier stake.
2.  `setAIAssistantOracle(address _oracle)`: Sets/updates the address of the trusted AI oracle. *Accessible only by `ADMIN_ROLE`*.
3.  `setVerifierMinStake(uint256 _amount)`: Sets the minimum stake required for verifiers. *Accessible only by `ADMIN_ROLE`*.
4.  `setCommissionRate(uint256 _rate)`: Sets the platform commission rate in basis points (e.g., 100 = 1%). *Accessible only by `ADMIN_ROLE`*.

**II. Research Topic Management (5 functions)**

5.  `proposeResearchTopic(string memory _title, string memory _description, uint256 _submissionDeadline, uint256 _verificationDeadline, bool _isPrivate)`: Allows a sponsor to propose a new research topic or data bounty.
6.  `fundResearchTopic(uint256 _topicId) payable`: Allows sponsors to fund an existing research topic by sending ETH.
7.  `updateTopicDetails(uint256 _topicId, string memory _newDescription)`: Allows the sponsor to update topic details (e.g., description) before deadlines. *Accessible only by the topic sponsor*.
8.  `cancelResearchTopic(uint256 _topicId)`: Allows the sponsor to cancel a topic before the submission deadline, returning any funds. *Accessible only by the topic sponsor*.
9.  `withdrawUnspentTopicFunds(uint256 _topicId)`: Allows the sponsor to withdraw any unspent bounty funds after a topic is cancelled or finalized. *Accessible only by the topic sponsor*.

**III. Solution Contribution (2 functions)**

10. `submitSolution(uint256 _topicId, string memory _ipfsHash)`: Allows a contributor to submit a solution/data to a topic, referencing off-chain content via an IPFS hash.
11. `retractSolution(uint256 _topicId, uint256 _solutionIndex)`: Allows a contributor to retract their solution before the verification deadline, provided it's not under active dispute. *Accessible only by the solution contributor*.

**IV. Verification & Evaluation (6 functions)**

12. `stakeAsVerifier() payable`: Allows a user to become an active verifier by staking the `s_verifierMinStake` amount.
13. `unstakeVerifierFunds()`: Allows a verifier to unstake their funds if not currently involved in challenges (simplified for this contract).
14. `challengeSolution(uint256 _topicId, uint256 _solutionIndex) payable`: Allows a staked verifier to challenge a submitted solution, staking funds against its validity. *Accessible only by verifiers*.
15. `supportSolution(uint256 _topicId, uint256 _solutionIndex) payable`: Allows a staked verifier to support a submitted solution, staking funds in favor of its validity. *Accessible only by verifiers*.
16. `aiOracleSubmitEvaluation(uint256 _topicId, uint256 _solutionIndex, uint8 _score, string memory _feedbackHash)`: Allows the designated AI oracle to submit an evaluation score (0-100) and feedback for a solution. *Accessible only by `AI_ORACLE_ROLE`*.
17. `finalizeSolutionVerdict(uint256 _topicId, uint256 _solutionIndex)`: Finalizes the verdict for a solution after its verification deadline, based on AI score and verifier stakes, distributing rewards/slashes (simplified reward distribution in current implementation, needs external claim).

**V. Rewards & Funds Management (2 functions)**

18. `claimRewards(uint256 _topicId, uint256 _solutionIndex)`: Placeholder function for contributors and verifiers to claim their earned rewards. *Note: The reward distribution logic needs further refinement in `finalizeSolutionVerdict` to make this function fully operational.*
19. `withdrawPlatformFees()`: Allows the contract `ADMIN_ROLE` to withdraw accumulated platform fees.

**VI. Knowledge NFT & Licensing (3 functions)**

20. `mintVerifiedKnowledgeNFT(uint256 _topicId, uint256 _solutionIndex)`: Mints an ERC721 NFT for a successfully verified and highly-rated solution, owned by the contributor. *Accessible only by the solution contributor*.
21. `grantKnowledgeLicense(uint256 _tokenId, address _licensee, uint256 _expiry, bool _commercialUse)`: Grants a license for a specific Knowledge NFT to another address, defining expiry and commercial use terms. *Accessible only by the NFT owner or approved address*.
22. `revokeKnowledgeLicense(uint256 _tokenId, address _licensee)`: Revokes an existing license for a Knowledge NFT. *Accessible only by the NFT owner or approved address*.

**VII. View Functions (5 functions)**

23. `queryUserReputation(address _user)`: Returns the current reputation score of a user.
24. `getTopicDetails(uint256 _topicId)`: Returns detailed information about a research topic.
25. `getSolutionDetails(uint256 _topicId, uint256 _solutionIndex)`: Returns detailed information about a submitted solution.
26. `getVerifierStake(address _verifier)`: Returns the current staked amount of a verifier.
27. `getLicenseDetails(uint256 _tokenId, address _licensee)`: Returns details of a specific license for a Knowledge NFT.

**VIII. Emergency & Safety (2 functions)**

28. `pause()`: Pauses the contract, preventing most state-changing operations. *Accessible only by `ADMIN_ROLE`*.
29. `unpause()`: Unpauses the contract. *Accessible only by `ADMIN_ROLE`*.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // For explicit checked arithmetic in certain scenarios

// --- OUTLINE AND FUNCTION SUMMARY ---
// Contract Name: AetheriumKnowledgeNexus
// Description: A decentralized platform for collaborative research, data bounties, and verifiable knowledge creation,
//              integrating AI-assisted evaluation and a robust reputation system.
//              Sponsors propose research topics/bounties, Contributors submit solutions/data,
//              Verifiers stake to challenge or support submissions, and an AI Oracle provides assessments.
//              Successful, verified solutions can be tokenized as unique Knowledge NFTs, enabling licensing.
//
// Core Concepts:
// - Decentralized Bounties: Sponsors fund specific research questions or data collection tasks.
// - AI-Assisted Evaluation: A designated AI Oracle provides initial, potentially weighted, evaluations.
// - Verifier Consensus: Community verifiers stake funds to challenge or support submitted solutions,
//                       creating a dispute resolution mechanism.
// - Reputation System: Users earn or lose reputation based on successful contributions, verifications, and challenges.
// - Knowledge Tokenization: Verified solutions are minted as ERC721 NFTs, representing immutable knowledge.
// - Licensing Mechanism: Owners of Knowledge NFTs can grant time-bound or commercial licenses for their data/research.
//
// Inheritance:
// - ERC721Enumerable: For Knowledge NFTs.
// - AccessControl: For managing roles (ADMIN, AI_ORACLE).
// - Pausable: For emergency pausing of critical functions.
// - ReentrancyGuard: To prevent reentrancy attacks.
//
// State Variables:
// - `ADMIN_ROLE`: Role for contract administration.
// - `AI_ORACLE_ROLE`: Role for the AI evaluation system.
// - `s_topicIdCounter`: Counter for research topics.
// - `s_solutionsNFTIdCounter`: Counter for Knowledge NFTs.
// - `s_topics`: Mapping from topic ID to `Topic` struct.
// - `s_solutions`: Nested mapping from topic ID to solution index to `Solution` struct.
// - `s_userReputation`: Mapping from user address to their reputation score.
// - `s_verifierStakes`: Mapping from verifier address to their currently staked funds.
// - `s_commissionRate`: Platform commission rate in basis points (e.g., 100 = 1%).
// - `s_verifierMinStake`: Minimum required stake for a verifier to participate.
// - `s_platformFeesAccrued`: Total fees accumulated by the platform.
// - `s_knowledgeLicenses`: Nested mapping for NFT licensing: `tokenId => licenseeAddress => KnowledgeLicense` struct.
//
// Enums:
// - `TopicStatus`: Defines the lifecycle stages of a research topic.
// - `SolutionStatus`: Defines the lifecycle stages of a submitted solution.
// - `Verdict`: Represents the final outcome of a solution's verification.
//
// Events:
// - `TopicProposed`: When a new topic is created.
// - `TopicFunded`: When a topic receives funds.
// - `SolutionSubmitted`: When a solution is submitted.
// - `SolutionRetracted`: When a solution is retracted.
// - `VerifierStaked`: When a user stakes as a verifier.
// - `VerifierUnstaked`: When a verifier unstakes.
// - `SolutionChallenged`: When a solution is challenged.
// - `SolutionSupported`: When a solution is supported.
// - `AIEvaluationSubmitted`: When AI oracle provides an evaluation.
// - `SolutionVerdictFinalized`: When a solution's verification concludes.
// - `RewardsClaimed`: When rewards are claimed.
// - `KnowledgeNFTMinted`: When a new Knowledge NFT is minted.
// - `KnowledgeLicenseGranted`: When a license for a Knowledge NFT is granted.
// - `KnowledgeLicenseRevoked`: When a license for a Knowledge NFT is revoked.
// - `ReputationUpdated`: When a user's reputation changes.
//
// Function Summary (29 functions):
//
// I. Initialization & Configuration (4 functions)
// 1. `constructor()`: Initializes the contract with an admin, sets basic parameters, and grants roles.
// 2. `setAIAssistantOracle(address _oracle)`: Sets/updates the address of the trusted AI oracle (ADMIN_ROLE).
// 3. `setVerifierMinStake(uint256 _amount)`: Sets the minimum stake required for verifiers (ADMIN_ROLE).
// 4. `setCommissionRate(uint256 _rate)`: Sets the platform commission rate in basis points (ADMIN_ROLE).
//
// II. Research Topic Management (5 functions)
// 5. `proposeResearchTopic(string memory _title, string memory _description, uint256 _submissionDeadline, uint256 _verificationDeadline, bool _isPrivate)`: Allows a sponsor to propose a new research topic or data bounty.
// 6. `fundResearchTopic(uint256 _topicId) payable`: Allows sponsors to fund an existing research topic.
// 7. `updateTopicDetails(uint256 _topicId, string memory _newDescription)`: Allows the sponsor to update topic details.
// 8. `cancelResearchTopic(uint256 _topicId)`: Allows the sponsor to cancel a topic before the submission deadline, returning funds.
// 9. `withdrawUnspentTopicFunds(uint256 _topicId)`: Allows the sponsor to withdraw any funds exceeding the bounty or if topic cancelled.
//
// III. Solution Contribution (2 functions)
// 10. `submitSolution(uint256 _topicId, string memory _ipfsHash)`: Allows a contributor to submit a solution/data to a topic.
// 11. `retractSolution(uint256 _topicId, uint256 _solutionIndex)`: Allows a contributor to retract their solution before verification.
//
// IV. Verification & Evaluation (6 functions)
// 12. `stakeAsVerifier() payable`: Allows a user to become an active verifier by staking tokens.
// 13. `unstakeVerifierFunds()`: Allows a verifier to unstake their funds if not currently involved in challenges.
// 14. `challengeSolution(uint256 _topicId, uint256 _solutionIndex) payable`: Allows a verifier to challenge a submitted solution, staking funds.
// 15. `supportSolution(uint256 _topicId, uint256 _solutionIndex) payable`: Allows a verifier to support a submitted solution, staking funds.
// 16. `aiOracleSubmitEvaluation(uint256 _topicId, uint256 _solutionIndex, uint8 _score, string memory _feedbackHash)`: Allows the designated AI oracle to submit an evaluation score (0-100) and feedback.
// 17. `finalizeSolutionVerdict(uint256 _topicId, uint256 _solutionIndex)`: Finalizes the verdict for a solution after its verification deadline, distributing rewards/slashes.
//
// V. Rewards & Funds Management (2 functions)
// 18. `claimRewards(uint256 _topicId, uint256 _solutionIndex)`: Allows contributors and verifiers to claim their earned rewards after a solution is finalized.
// 19. `withdrawPlatformFees()`: Allows the contract ADMIN_ROLE to withdraw accumulated platform fees.
//
// VI. Knowledge NFT & Licensing (3 functions)
// 20. `mintVerifiedKnowledgeNFT(uint256 _topicId, uint256 _solutionIndex)`: Mints an ERC721 NFT for a successfully verified and highly-rated solution.
// 21. `grantKnowledgeLicense(uint256 _tokenId, address _licensee, uint256 _expiry, bool _commercialUse)`: Grants a license for a specific Knowledge NFT to another address.
// 22. `revokeKnowledgeLicense(uint256 _tokenId, address _licensee)`: Revokes an existing license for a Knowledge NFT.
//
// VII. View Functions (5 functions)
// 23. `queryUserReputation(address _user)`: Returns the current reputation score of a user.
// 24. `getTopicDetails(uint256 _topicId)`: Returns detailed information about a research topic.
// 25. `getSolutionDetails(uint256 _topicId, uint256 _solutionIndex)`: Returns detailed information about a submitted solution.
// 26. `getVerifierStake(address _verifier)`: Returns the current staked amount of a verifier.
// 27. `getLicenseDetails(uint256 _tokenId, address _licensee)`: Returns details of a specific license for a Knowledge NFT.
//
// VIII. Emergency & Safety (2 functions)
// 28. `pause()`: Pauses the contract, preventing most state-changing operations (ADMIN_ROLE).
// 29. `unpause()`: Unpauses the contract (ADMIN_ROLE).

contract AetheriumKnowledgeNexus is ERC721Enumerable, AccessControl, Pausable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using SafeMath for uint256; // Explicitly use SafeMath for arithmetic operations where overflow/underflow is critical

    // --- Roles ---
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant AI_ORACLE_ROLE = keccak256("AI_ORACLE_ROLE");

    // --- Counters ---
    Counters.Counter private s_topicIdCounter;
    Counters.Counter private s_solutionsNFTIdCounter;

    // --- Configuration Parameters ---
    uint256 public s_commissionRate; // In basis points (e.g., 100 = 1%)
    uint256 public s_verifierMinStake; // Minimum required stake for verifiers

    // --- Platform Balances ---
    uint256 public s_platformFeesAccrued;

    // --- Enums ---
    enum TopicStatus {
        Open,           // Topic proposed, accepting funds
        Submission,     // Accepting solutions
        Verification,   // Solutions submitted, awaiting verification (also past submission deadline)
        Finalized,      // Verification complete, rewards distributed
        Cancelled       // Topic cancelled, funds returned
    }

    enum SolutionStatus {
        Submitted,      // Awaiting AI/community verification
        Challenged,     // Under dispute by verifiers
        Supported,      // Supported by verifiers
        AI_Evaluated,   // AI evaluation received
        Verified,       // Final verdict: Accepted
        Rejected        // Final verdict: Rejected
    }

    enum Verdict {
        None,
        Accepted,
        Rejected
    }

    // --- Structs ---
    struct Topic {
        uint256 id;
        address sponsor;
        string title;
        string description;
        uint256 submissionDeadline;
        uint256 verificationDeadline;
        TopicStatus status;
        uint256 totalBounty; // Total ETH allocated by sponsor
        uint256 solutionCount;
        bool isPrivate; // If true, implies future features to restrict visibility/submission
        bool hasMintedNFT; // To prevent multiple NFT mints for the same topic (if multiple solutions are accepted)
    }

    struct Solution {
        uint256 id;
        address contributor;
        string ipfsHash; // Hash pointing to off-chain data/solution
        uint256 submissionTime;
        SolutionStatus status;
        uint8 aiScore; // 0-100, from AI oracle
        string aiFeedbackHash; // IPFS hash for AI feedback
        uint256 totalChallengeStake; // Total ETH staked by challengers
        uint256 totalSupportStake;   // Total ETH staked by supporters
        Verdict finalVerdict;
        bool rewardsClaimed; // True if the contributor's bounty has been claimed
        bool nftMinted; // Has an NFT been minted for this specific solution?
    }

    struct KnowledgeLicense {
        address licensee;
        uint256 expiry; // Timestamp, 0 for perpetual license
        bool commercialUse;
        bool active; // Explicitly mark if the license is active
    }

    // --- Mappings ---
    mapping(uint256 => Topic) public s_topics;
    mapping(uint256 => mapping(uint256 => Solution)) public s_solutions; // topicId => solutionIndex => Solution
    mapping(address => uint256) public s_userReputation; // Address => Reputation Score (initial 1000)
    mapping(address => uint256) public s_verifierStakes; // Verifier => Staked Amount (total funds user has staked for verification)

    // Knowledge NFT licensing: tokenId => licensee address => KnowledgeLicense
    mapping(uint256 => mapping(address => KnowledgeLicense)) public s_knowledgeLicenses;

    // --- Events ---
    event TopicProposed(uint256 indexed topicId, address indexed sponsor, string title, uint256 submissionDeadline);
    event TopicFunded(uint256 indexed topicId, address indexed funder, uint256 amount, uint256 newTotalBounty);
    event SolutionSubmitted(uint256 indexed topicId, uint256 indexed solutionIndex, address indexed contributor, string ipfsHash);
    event SolutionRetracted(uint256 indexed topicId, uint256 indexed solutionIndex, address indexed contributor);
    event VerifierStaked(address indexed verifier, uint256 amount);
    event VerifierUnstaked(address indexed verifier, uint256 amount);
    event SolutionChallenged(uint256 indexed topicId, uint256 indexed solutionIndex, address indexed challenger, uint256 stake);
    event SolutionSupported(uint256 indexed topicId, uint256 indexed solutionIndex, address indexed supporter, uint256 stake);
    event AIEvaluationSubmitted(uint256 indexed topicId, uint256 indexed solutionIndex, uint8 score, string feedbackHash);
    event SolutionVerdictFinalized(uint256 indexed topicId, uint256 indexed solutionIndex, Verdict verdict, uint256 bountyRewardsDistributed);
    event RewardsClaimed(uint256 indexed topicId, uint256 indexed solutionIndex, address indexed claimant, uint256 amount);
    event KnowledgeNFTMinted(uint256 indexed tokenId, uint256 indexed topicId, uint256 indexed solutionIndex, address indexed minter);
    event KnowledgeLicenseGranted(uint256 indexed tokenId, address indexed licensee, uint256 expiry, bool commercialUse);
    event KnowledgeLicenseRevoked(uint256 indexed tokenId, address indexed licensee);
    event ReputationUpdated(address indexed user, uint256 oldReputation, uint256 newReputation);

    // --- Constructor ---
    /// @notice Initializes the contract with an admin and an initial AI oracle address.
    /// @param _admin The address for the contract administrator.
    /// @param _aiOracle The address of the initial AI evaluation oracle.
    constructor(address _admin, address _aiOracle)
        ERC721("Aetherium Knowledge NFT", "AKN") // Initialize ERC721 contract
    {
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(ADMIN_ROLE, _admin);
        _grantRole(AI_ORACLE_ROLE, _aiOracle);

        s_commissionRate = 500; // 5% commission (500 basis points) by default
        s_verifierMinStake = 1 ether; // 1 ETH minimum stake for verifiers by default
    }

    // --- Modifiers ---
    /// @dev Restricts access to the sponsor of a given topic.
    modifier onlyTopicSponsor(uint256 _topicId) {
        require(s_topics[_topicId].sponsor == msg.sender, "Caller is not the topic sponsor");
        _;
    }

    /// @dev Restricts access to an active verifier with sufficient stake.
    modifier onlyVerifier() {
        require(s_verifierStakes[msg.sender] >= s_verifierMinStake, "Caller is not an active verifier or has insufficient stake");
        _;
    }

    // --- I. Initialization & Configuration ---

    /// @notice Sets the address of the trusted AI oracle. Only callable by `ADMIN_ROLE`.
    /// @param _oracle The new address for the AI oracle.
    function setAIAssistantOracle(address _oracle) external onlyRole(ADMIN_ROLE) {
        require(_oracle != address(0), "AI Oracle address cannot be zero");
        // Remove old AI_ORACLE_ROLE from previous oracle if any, and grant to new one
        // Note: OpenZeppelin's AccessControl doesn't directly support replacing a single-role member.
        // A more robust system for multiple AI oracles or single replacement would track the address.
        // For simplicity, this assumes a single AI oracle identity.
        _grantRole(AI_ORACLE_ROLE, _oracle); // This will grant to the new, the old will keep it but won't be called.
    }

    /// @notice Sets the minimum required stake for verifiers. Only callable by `ADMIN_ROLE`.
    /// @param _amount The new minimum stake amount in wei.
    function setVerifierMinStake(uint256 _amount) external onlyRole(ADMIN_ROLE) {
        require(_amount > 0, "Stake amount must be greater than zero");
        s_verifierMinStake = _amount;
    }

    /// @notice Sets the platform commission rate. Only callable by `ADMIN_ROLE`.
    /// @param _rate The new commission rate in basis points (e.g., 100 = 1%). Max 10000 (100%).
    function setCommissionRate(uint256 _rate) external onlyRole(ADMIN_ROLE) {
        require(_rate <= 10000, "Commission rate cannot exceed 100%");
        s_commissionRate = _rate;
    }

    // --- II. Research Topic Management ---

    /// @notice Allows a sponsor to propose a new research topic or data bounty.
    /// @param _title The title of the research topic.
    /// @param _description A detailed description of the topic.
    /// @param _submissionDeadline The timestamp by which solutions must be submitted.
    /// @param _verificationDeadline The timestamp by which solutions must be verified.
    /// @param _isPrivate If true, future access control features might limit visibility/submission.
    /// @return topicId The ID of the newly created topic.
    function proposeResearchTopic(
        string memory _title,
        string memory _description,
        uint256 _submissionDeadline,
        uint256 _verificationDeadline,
        bool _isPrivate
    ) external whenNotPaused nonReentrant returns (uint256) {
        require(bytes(_title).length > 0, "Title cannot be empty");
        require(_submissionDeadline > block.timestamp, "Submission deadline must be in the future");
        require(_verificationDeadline > _submissionDeadline, "Verification deadline must be after submission deadline");

        s_topicIdCounter.increment();
        uint256 newTopicId = s_topicIdCounter.current();

        s_topics[newTopicId] = Topic({
            id: newTopicId,
            sponsor: msg.sender,
            title: _title,
            description: _description,
            submissionDeadline: _submissionDeadline,
            verificationDeadline: _verificationDeadline,
            status: TopicStatus.Open,
            totalBounty: 0,
            solutionCount: 0,
            isPrivate: _isPrivate,
            hasMintedNFT: false
        });

        _updateReputation(msg.sender, 10); // +10 for proposing a topic
        emit TopicProposed(newTopicId, msg.sender, _title, _submissionDeadline);
        return newTopicId;
    }

    /// @notice Allows sponsors to fund an existing research topic. Funds are held in the contract.
    /// @param _topicId The ID of the topic to fund.
    function fundResearchTopic(uint256 _topicId) external payable whenNotPaused nonReentrant {
        Topic storage topic = s_topics[_topicId];
        require(topic.id == _topicId, "Topic does not exist");
        require(msg.value > 0, "Funding amount must be greater than zero");
        require(topic.status == TopicStatus.Open || topic.status == TopicStatus.Submission, "Topic not in funding or submission stage");

        topic.totalBounty = topic.totalBounty.add(msg.value);

        // Automatically move to submission stage if funded and currently Open
        if (topic.status == TopicStatus.Open) {
            topic.status = TopicStatus.Submission;
        }

        _updateReputation(msg.sender, 5); // +5 for funding
        emit TopicFunded(_topicId, msg.sender, msg.value, topic.totalBounty);
    }

    /// @notice Allows the sponsor to update topic details (e.g., description) before the submission deadline.
    /// @param _topicId The ID of the topic.
    /// @param _newDescription The new description for the topic.
    function updateTopicDetails(uint256 _topicId, string memory _newDescription)
        external
        onlyTopicSponsor(_topicId)
        whenNotPaused
    {
        Topic storage topic = s_topics[_topicId];
        require(block.timestamp < topic.submissionDeadline, "Cannot update after submission deadline");
        topic.description = _newDescription;
    }

    /// @notice Allows the sponsor to cancel a topic before the submission deadline. Funds are returned.
    /// @param _topicId The ID of the topic to cancel.
    function cancelResearchTopic(uint256 _topicId)
        external
        onlyTopicSponsor(_topicId)
        whenNotPaused
        nonReentrant
    {
        Topic storage topic = s_topics[_topicId];
        require(topic.status != TopicStatus.Finalized && topic.status != TopicStatus.Cancelled, "Topic already finalized or cancelled");
        require(block.timestamp < topic.submissionDeadline, "Cannot cancel after submission deadline");
        require(topic.solutionCount == 0, "Cannot cancel a topic with submitted solutions. Must wait for verification to complete or retract them.");

        uint256 amountToReturn = topic.totalBounty;
        topic.totalBounty = 0; // Clear bounty
        topic.status = TopicStatus.Cancelled;

        (bool sent, ) = topic.sponsor.call{value: amountToReturn}("");
        require(sent, "Failed to send funds back to sponsor");

        _updateReputation(msg.sender, -10); // -10 for cancelling
    }

    /// @notice Allows the sponsor to withdraw any unspent funds from a topic (e.g., overfunded, or after cancellation).
    /// @param _topicId The ID of the topic.
    function withdrawUnspentTopicFunds(uint256 _topicId)
        external
        onlyTopicSponsor(_topicId)
        whenNotPaused
        nonReentrant
    {
        Topic storage topic = s_topics[_topicId];
        require(topic.id == _topicId, "Topic does not exist");
        require(topic.status == TopicStatus.Cancelled || topic.status == TopicStatus.Finalized, "Topic must be cancelled or finalized to withdraw unspent funds");
        require(topic.totalBounty > 0, "No unspent funds to withdraw");

        uint256 amountToReturn = topic.totalBounty;
        topic.totalBounty = 0; // Clear remaining bounty

        (bool sent, ) = topic.sponsor.call{value: amountToReturn}("");
        require(sent, "Failed to send funds back to sponsor");
    }


    // --- III. Solution Contribution ---

    /// @notice Allows a contributor to submit a solution/data to a topic.
    /// @param _topicId The ID of the topic.
    /// @param _ipfsHash The IPFS hash pointing to the solution's data or research paper.
    /// @return solutionIndex The index of the submitted solution within the topic.
    function submitSolution(uint256 _topicId, string memory _ipfsHash)
        external
        whenNotPaused
        nonReentrant
        returns (uint256)
    {
        Topic storage topic = s_topics[_topicId];
        require(topic.id == _topicId, "Topic does not exist");
        require(topic.status == TopicStatus.Submission || topic.status == TopicStatus.Verification, "Topic not in submission phase");
        require(block.timestamp <= topic.submissionDeadline, "Submission deadline passed");
        require(bytes(_ipfsHash).length > 0, "IPFS hash cannot be empty");

        uint256 solutionIndex = topic.solutionCount;
        s_solutions[_topicId][solutionIndex] = Solution({
            id: solutionIndex,
            contributor: msg.sender,
            ipfsHash: _ipfsHash,
            submissionTime: block.timestamp,
            status: SolutionStatus.Submitted,
            aiScore: 0,
            aiFeedbackHash: "",
            totalChallengeStake: 0,
            totalSupportStake: 0,
            finalVerdict: Verdict.None,
            rewardsClaimed: false,
            nftMinted: false
        });
        topic.solutionCount++;

        // If the submission deadline has passed, move the topic to verification status
        if (block.timestamp > topic.submissionDeadline) {
             topic.status = TopicStatus.Verification;
        }

        _updateReputation(msg.sender, 5); // +5 for submitting a solution
        emit SolutionSubmitted(_topicId, solutionIndex, msg.sender, _ipfsHash);
        return solutionIndex;
    }

    /// @notice Allows a contributor to retract their solution before the verification deadline.
    /// @param _topicId The ID of the topic.
    /// @param _solutionIndex The index of the solution to retract.
    function retractSolution(uint256 _topicId, uint256 _solutionIndex)
        external
        whenNotPaused
        nonReentrant
    {
        Topic storage topic = s_topics[_topicId];
        Solution storage solution = s_solutions[_topicId][_solutionIndex];

        require(topic.id == _topicId, "Topic does not exist");
        require(solution.contributor == msg.sender, "Caller is not the solution contributor");
        require(solution.finalVerdict == Verdict.None, "Solution already finalized"); // Cannot retract once verdict is set
        require(block.timestamp < topic.verificationDeadline, "Verification deadline passed, cannot retract");

        // Solutions cannot be retracted if there are active challenges/supports to simplify logic.
        require(solution.totalChallengeStake == 0 && solution.totalSupportStake == 0, "Solution under active challenge/support, cannot retract");

        // Mark as rejected and update reputation
        solution.status = SolutionStatus.Rejected;
        solution.finalVerdict = Verdict.Rejected;
        _updateReputation(msg.sender, -10); // -10 for retracting
        emit SolutionRetracted(_topicId, _solutionIndex, msg.sender);
    }

    // --- IV. Verification & Evaluation ---

    /// @notice Allows a user to become an active verifier by staking tokens.
    /// @dev The staked amount is locked until unstaked.
    function stakeAsVerifier() external payable whenNotPaused nonReentrant {
        require(msg.value >= s_verifierMinStake, "Must stake at least the verifier minimum stake");
        s_verifierStakes[msg.sender] = s_verifierStakes[msg.sender].add(msg.value);
        emit VerifierStaked(msg.sender, msg.value);
    }

    /// @notice Allows a verifier to unstake their funds if they are not currently involved in any active challenges/supports.
    /// @dev This simplified version assumes if no active challenges are recorded (which aren't individually tracked per verifier here),
    ///      they can unstake. A real-world system would require more robust tracking of individual verifier stakes per solution.
    function unstakeVerifierFunds() external whenNotPaused nonReentrant {
        require(s_verifierStakes[msg.sender] > 0, "No funds staked to unstake");
        // Simplified: check if user is involved in *any* pending solution disputes.
        // For a full implementation, you'd need a more complex way to track
        // if msg.sender has challenges/supports that are not yet finalized across all topics/solutions.
        // For this example, we assume `finalizeSolutionVerdict` handles all stakes,
        // so if there are no 'live' challenges for msg.sender, they can unstake.
        uint256 amount = s_verifierStakes[msg.sender];
        s_verifierStakes[msg.sender] = 0;

        (bool sent, ) = msg.sender.call{value: amount}("");
        require(sent, "Failed to send funds to verifier");
        emit VerifierUnstaked(msg.sender, amount);
    }

    /// @notice Allows a verifier to challenge a submitted solution, staking funds against it.
    /// @param _topicId The ID of the topic.
    /// @param _solutionIndex The index of the solution to challenge.
    function challengeSolution(uint256 _topicId, uint256 _solutionIndex) external payable onlyVerifier whenNotPaused nonReentrant {
        Topic storage topic = s_topics[_topicId];
        Solution storage solution = s_solutions[_topicId][_solutionIndex];

        require(topic.id == _topicId, "Topic does not exist");
        require(solution.contributor != address(0), "Solution does not exist");
        require(block.timestamp < topic.verificationDeadline, "Verification deadline passed, cannot challenge");
        require(solution.finalVerdict == Verdict.None, "Solution already finalized");
        require(msg.value > 0, "Challenge stake must be greater than zero");
        require(msg.sender != solution.contributor, "Contributor cannot challenge their own solution");

        solution.totalChallengeStake = solution.totalChallengeStake.add(msg.value);
        solution.status = SolutionStatus.Challenged; // Update status to reflect active challenge

        // A more complex system would track individual verifier stakes for each solution
        // to facilitate proportional rewards/slashes. Here, we track total.
        _updateReputation(msg.sender, 2); // +2 for active participation
        emit SolutionChallenged(_topicId, _solutionIndex, msg.sender, msg.value);
    }

    /// @notice Allows a verifier to support a submitted solution, staking funds in favor of it.
    /// @param _topicId The ID of the topic.
    /// @param _solutionIndex The index of the solution to support.
    function supportSolution(uint256 _topicId, uint256 _solutionIndex) external payable onlyVerifier whenNotPaused nonReentrant {
        Topic storage topic = s_topics[_topicId];
        Solution storage solution = s_solutions[_topicId][_solutionIndex];

        require(topic.id == _topicId, "Topic does not exist");
        require(solution.contributor != address(0), "Solution does not exist");
        require(block.timestamp < topic.verificationDeadline, "Verification deadline passed, cannot support");
        require(solution.finalVerdict == Verdict.None, "Solution already finalized");
        require(msg.value > 0, "Support stake must be greater than zero");
        require(msg.sender != solution.contributor, "Contributor cannot support their own solution");

        solution.totalSupportStake = solution.totalSupportStake.add(msg.value);
        solution.status = SolutionStatus.Supported; // Update status to reflect active support

        // A more complex system would track individual verifier stakes for each solution.
        _updateReputation(msg.sender, 2); // +2 for active participation
        emit SolutionSupported(_topicId, _solutionIndex, msg.sender, msg.value);
    }

    /// @notice Allows the designated AI oracle to submit an evaluation score and feedback.
    /// @param _topicId The ID of the topic.
    /// @param _solutionIndex The index of the solution.
    /// @param _score An evaluation score from 0-100.
    /// @param _feedbackHash IPFS hash pointing to detailed AI feedback.
    function aiOracleSubmitEvaluation(
        uint256 _topicId,
        uint256 _solutionIndex,
        uint8 _score,
        string memory _feedbackHash
    ) external onlyRole(AI_ORACLE_ROLE) whenNotPaused {
        Topic storage topic = s_topics[_topicId];
        Solution storage solution = s_solutions[_topicId][_solutionIndex];

        require(topic.id == _topicId, "Topic does not exist");
        require(solution.contributor != address(0), "Solution does not exist");
        require(block.timestamp < topic.verificationDeadline, "Verification deadline passed, cannot submit AI evaluation");
        require(solution.finalVerdict == Verdict.None, "Solution already finalized");
        require(_score <= 100, "AI score must be between 0 and 100");

        solution.aiScore = _score;
        solution.aiFeedbackHash = _feedbackHash;
        solution.status = SolutionStatus.AI_Evaluated;
        emit AIEvaluationSubmitted(_topicId, _solutionIndex, _score, _feedbackHash);
    }

    /// @notice Finalizes the verdict for a solution after its verification deadline, distributing rewards/slashes.
    /// @dev This function calculates the final verdict based on AI score and verifier stakes.
    ///      Rewards are calculated for the contributor and verifiers, and funds are moved.
    ///      The logic for verifier rewards/slashes is simplified and could be expanded to track individual stakes.
    /// @param _topicId The ID of the topic.
    /// @param _solutionIndex The index of the solution.
    function finalizeSolutionVerdict(uint256 _topicId, uint256 _solutionIndex) external whenNotPaused nonReentrant {
        Topic storage topic = s_topics[_topicId];
        Solution storage solution = s_solutions[_topicId][_solutionIndex];

        require(topic.id == _topicId, "Topic does not exist");
        require(solution.contributor != address(0), "Solution does not exist");
        require(block.timestamp >= topic.verificationDeadline, "Verification deadline not yet passed");
        require(solution.finalVerdict == Verdict.None, "Solution verdict already finalized");
        require(topic.status != TopicStatus.Cancelled, "Topic is cancelled");

        // Determine final verdict based on AI score and verifier stakes
        uint256 effectiveScore = solution.aiScore; // Start with AI score as baseline

        // Community consensus acts as a modifier
        if (solution.totalSupportStake > solution.totalChallengeStake) {
            // More support than challenge, boost score
            effectiveScore = effectiveScore.add(10); // Example boost
        } else if (solution.totalChallengeStake > solution.totalSupportStake) {
            // More challenge than support, reduce score
            effectiveScore = effectiveScore.sub(10); // Example reduction
        }
        // Ensure effective score stays within 0-100 bounds
        if (effectiveScore > 100) effectiveScore = 100;
        if (effectiveScore < 0) effectiveScore = 0;

        Verdict finalVerdict;
        uint256 bountyRewardsDistributed = 0;

        if (effectiveScore >= 60) { // Threshold for acceptance
            finalVerdict = Verdict.Accepted;
            solution.status = SolutionStatus.Verified;
            _updateReputation(solution.contributor, 50); // +50 for successful contribution

            // Distribute bounty funds to contributor
            uint256 commissionAmount = topic.totalBounty.mul(s_commissionRate).div(10000);
            s_platformFeesAccrued = s_platformFeesAccrued.add(commissionAmount);
            bountyRewardsDistributed = topic.totalBounty.sub(commissionAmount);

            (bool sent, ) = solution.contributor.call{value: bountyRewardsDistributed}("");
            require(sent, "Failed to send bounty rewards to contributor");

            // Reward supporting verifiers by returning their stake + a share of challenged stake
            // For simplicity, stakes are distributed proportionally, but not individually tracked.
            if (solution.totalSupportStake > 0) {
                 // For current simple design, we don't track who supported/challenged each solution.
                 // A more complex mapping would be required: `mapping(uint256 => mapping(uint256 => mapping(address => uint256))) s_individualVerifierStakes;`
                 // This would be too gas-intensive for this example.
                 // So for now, we just update reputation for verifiers, and the stakes stay in the contract.
                 // Verifiers will need to unstake their initial stake using `unstakeVerifierFunds()`.
            }
            _updateReputation(msg.sender, 10); // +10 for finalizing (if successful)

        } else { // Rejected
            finalVerdict = Verdict.Rejected;
            solution.status = SolutionStatus.Rejected;
            _updateReputation(solution.contributor, -25); // -25 for rejected contribution

            // Reward challenging verifiers, potentially slash supporting verifiers
            // Same simplification as above: no individual stake tracking for this solution.
            _updateReputation(msg.sender, 5); // +5 for finalizing (if rejected)
        }
        solution.finalVerdict = finalVerdict;
        topic.totalBounty = 0; // Bounty is either distributed or remains for sponsor to withdraw (if rejected)
        topic.status = TopicStatus.Finalized; // Topic is now finalized

        emit SolutionVerdictFinalized(_topicId, _solutionIndex, finalVerdict, bountyRewardsDistributed);
    }

    // --- V. Rewards & Funds Management ---

    /// @notice Allows contributors and verifiers to claim their earned rewards after a solution is finalized.
    /// @dev This function's implementation is a placeholder. A robust reward system would require `finalizeSolutionVerdict`
    ///      to credit specific users with claimable amounts in a dedicated mapping (e.g., `mapping(address => uint256) claimableFunds;`).
    ///      Currently, `finalizeSolutionVerdict` directly sends the bounty to the contributor.
    ///      Verifier reward/slash distribution logic is not fully implemented for individual stakes here.
    /// @param _topicId The ID of the topic.
    /// @param _solutionIndex The index of the solution.
    function claimRewards(uint256 _topicId, uint256 _solutionIndex) external whenNotPaused nonReentrant {
        Topic storage topic = s_topics[_topicId];
        Solution storage solution = s_solutions[_topicId][_solutionIndex];

        require(topic.id == _topicId, "Topic does not exist");
        require(solution.contributor != address(0), "Solution does not exist");
        require(solution.finalVerdict != Verdict.None, "Solution verdict not finalized yet");
        
        // This function is currently a placeholder as `finalizeSolutionVerdict` attempts direct transfer.
        // A proper system would use a `claimable` mapping.
        // For example:
        // uint256 amountToClaim = s_claimableRewards[msg.sender];
        // require(amountToClaim > 0, "No rewards to claim");
        // s_claimableRewards[msg.sender] = 0;
        // (bool sent, ) = msg.sender.call{value: amountToClaim}("");
        // require(sent, "Failed to send rewards");
        // emit RewardsClaimed(_topicId, _solutionIndex, msg.sender, amountToClaim);

        revert("Reward claiming is managed directly in finalizeSolutionVerdict for contributors. Verifier rewards need a dedicated tracking system.");
    }

    /// @notice Allows the contract `ADMIN_ROLE` to withdraw accumulated platform fees.
    function withdrawPlatformFees() external onlyRole(ADMIN_ROLE) whenNotPaused nonReentrant {
        require(s_platformFeesAccrued > 0, "No fees accrued to withdraw");
        uint256 amount = s_platformFeesAccrued;
        s_platformFeesAccrued = 0;

        (bool sent, ) = msg.sender.call{value: amount}("");
        require(sent, "Failed to withdraw fees");
    }

    // --- VI. Knowledge NFT & Licensing ---

    /// @notice Mints an ERC721 NFT for a successfully verified and highly-rated solution.
    /// @dev Only the contributor of an accepted solution can mint an NFT, and only one NFT per topic.
    /// @param _topicId The ID of the topic.
    /// @param _solutionIndex The index of the solution.
    /// @return tokenId The ID of the newly minted NFT.
    function mintVerifiedKnowledgeNFT(uint256 _topicId, uint256 _solutionIndex)
        external
        whenNotPaused
        nonReentrant
        returns (uint256)
    {
        Topic storage topic = s_topics[_topicId];
        Solution storage solution = s_solutions[_topicId][_solutionIndex];

        require(topic.id == _topicId, "Topic does not exist");
        require(solution.contributor == msg.sender, "Caller is not the solution contributor");
        require(solution.finalVerdict == Verdict.Accepted, "Solution must be verified and accepted to mint NFT");
        require(!topic.hasMintedNFT, "An NFT has already been minted for this topic's accepted solution"); // Prevents multiple NFTs for same topic
        require(!solution.nftMinted, "This solution already has an NFT minted for it");

        s_solutionsNFTIdCounter.increment();
        uint256 newTokenId = s_solutionsNFTIdCounter.current();

        _safeMint(msg.sender, newTokenId); // Mints the NFT to the contributor
        _setTokenURI(newTokenId, solution.ipfsHash); // NFT URI points to the solution's IPFS hash

        solution.nftMinted = true;
        topic.hasMintedNFT = true; // Mark topic as having minted an NFT

        _updateReputation(msg.sender, 100); // +100 for minting a valuable knowledge NFT
        emit KnowledgeNFTMinted(newTokenId, _topicId, _solutionIndex, msg.sender);
        return newTokenId;
    }

    /// @notice Grants a license for a specific Knowledge NFT to another address.
    /// @dev Allows the NFT owner to set terms for using the associated knowledge.
    /// @param _tokenId The ID of the Knowledge NFT.
    /// @param _licensee The address to grant the license to.
    /// @param _expiry The timestamp when the license expires (0 for perpetual).
    /// @param _commercialUse True if the license allows commercial use, false otherwise.
    function grantKnowledgeLicense(uint256 _tokenId, address _licensee, uint256 _expiry, bool _commercialUse)
        external
        whenNotPaused
        nonReentrant
    {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "Caller must be NFT owner or approved");
        require(_licensee != address(0), "Licensee cannot be zero address");
        require(_licensee != ownerOf(_tokenId), "Cannot license to self");
        require(_expiry == 0 || _expiry > block.timestamp, "Expiry must be in the future or 0 for perpetual");

        s_knowledgeLicenses[_tokenId][_licensee] = KnowledgeLicense({
            licensee: _licensee,
            expiry: _expiry,
            commercialUse: _commercialUse,
            active: true
        });

        emit KnowledgeLicenseGranted(_tokenId, _licensee, _expiry, _commercialUse);
    }

    /// @notice Revokes an existing license for a Knowledge NFT.
    /// @dev Only the NFT owner can revoke a license.
    /// @param _tokenId The ID of the Knowledge NFT.
    /// @param _licensee The address whose license is to be revoked.
    function revokeKnowledgeLicense(uint256 _tokenId, address _licensee)
        external
        whenNotPaused
        nonReentrant
    {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "Caller must be NFT owner or approved");
        require(s_knowledgeLicenses[_tokenId][_licensee].active, "No active license for this address to revoke");

        delete s_knowledgeLicenses[_tokenId][_licensee]; // Remove the license entry
        emit KnowledgeLicenseRevoked(_tokenId, _licensee);
    }

    // --- VII. View Functions ---

    /// @notice Returns the current reputation score of a user.
    /// @param _user The address of the user.
    /// @return The reputation score.
    function queryUserReputation(address _user) external view returns (uint256) {
        return s_userReputation[_user];
    }

    /// @notice Returns detailed information about a research topic.
    /// @param _topicId The ID of the topic.
    /// @return The Topic struct.
    function getTopicDetails(uint256 _topicId) external view returns (Topic memory) {
        return s_topics[_topicId];
    }

    /// @notice Returns detailed information about a submitted solution.
    /// @param _topicId The ID of the topic.
    /// @param _solutionIndex The index of the solution.
    /// @return The Solution struct.
    function getSolutionDetails(uint256 _topicId, uint256 _solutionIndex) external view returns (Solution memory) {
        return s_solutions[_topicId][_solutionIndex];
    }

    /// @notice Returns the current staked amount of a verifier.
    /// @param _verifier The address of the verifier.
    /// @return The staked amount in wei.
    function getVerifierStake(address _verifier) external view returns (uint256) {
        return s_verifierStakes[_verifier];
    }

    /// @notice Returns details of a specific license for a Knowledge NFT.
    /// @param _tokenId The ID of the Knowledge NFT.
    /// @param _licensee The address of the licensee.
    /// @return The KnowledgeLicense struct.
    function getLicenseDetails(uint256 _tokenId, address _licensee) external view returns (KnowledgeLicense memory) {
        return s_knowledgeLicenses[_tokenId][_licensee];
    }

    // --- VIII. Emergency & Safety ---

    /// @notice Pauses the contract, preventing most state-changing operations. Only callable by `ADMIN_ROLE`.
    function pause() external onlyRole(ADMIN_ROLE) {
        _pause();
    }

    /// @notice Unpauses the contract. Only callable by `ADMIN_ROLE`.
    function unpause() external onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    // --- Internal/Private Functions ---

    /// @dev Internal function to update a user's reputation score.
    /// @param _user The address of the user.
    /// @param _points The points to add or subtract (can be negative).
    function _updateReputation(address _user, int256 _points) internal {
        uint256 oldReputation = s_userReputation[_user];
        if (oldReputation == 0) { // Initialize reputation if not set, preventing default 0 to be treated as high score
            oldReputation = 1000; // Start with a base reputation score
        }

        uint256 newReputation;
        if (_points >= 0) {
            newReputation = oldReputation.add(uint256(_points));
        } else {
            // Ensure reputation doesn't go below a reasonable minimum (e.g., 100)
            uint256 absPoints = uint256(_points * -1);
            newReputation = (oldReputation > absPoints.add(100)) ? oldReputation.sub(absPoints) : 100; // Minimum 100 rep
        }

        s_userReputation[_user] = newReputation;
        emit ReputationUpdated(_user, oldReputation, newReputation);
    }

    // --- ERC721 Overrides ---
    /// @dev Returns the base URI for all NFTs in this contract. Can be overridden for dynamic URIs.
    function _baseURI() internal view override returns (string memory) {
        return "ipfs://AetheriumKnowledgeNexus/"; // Base URI for NFT metadata
    }
}
```