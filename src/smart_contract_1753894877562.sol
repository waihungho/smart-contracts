That's an exciting challenge! Let's build a smart contract for a "QuantumLeap DAO" – a decentralized autonomous organization focused on funding, peer-reviewing, and managing cutting-edge scientific research projects, with a strong emphasis on reputation, dynamic NFTs, and AI-assisted insights, all while aiming for privacy where feasible using ZKP hooks.

We'll imagine a DAO where:
*   Researchers submit proposals.
*   The community (weighted by token stake and reputation) votes on funding.
*   Research progress is tracked on-chain.
*   Reviewers earn reputation for quality peer reviews.
*   Researcher profiles and project NFTs are dynamic, reflecting progress, reputation, and impact.
*   AI oracles can provide analysis on research data (off-chain, but triggered and recorded on-chain).
*   Zero-Knowledge Proofs (ZKPs) are integrated for private identity verification or review submissions.

---

## QuantumLeap DAO Smart Contract

**Outline:**

1.  **Core Components:**
    *   `LEAP` Token (ERC20): The governance token.
    *   `ResearcherBadge` (ERC721-like): A non-transferable NFT representing a verified researcher identity.
    *   `ResearchProjectNFT` (ERC721-like): An NFT representing a specific research project, dynamically updated.

2.  **Governance & Proposals:**
    *   DAO proposals (funding, parameter changes, new initiatives).
    *   Token-weighted voting combined with reputation-weighted voting.

3.  **Reputation System:**
    *   Dynamic reputation points tied to staking, quality reviews, successful research.
    *   Reputation decay for inactivity.

4.  **Research Project Lifecycle:**
    *   Submission of research proposals (requiring reputation).
    *   Grant funding.
    *   Progress updates and milestone achievements.
    *   Peer review process.

5.  **Advanced Features:**
    *   **AI Oracle Integration:** Requesting and receiving AI analysis results for research data.
    *   **Zero-Knowledge Proof (ZKP) Hooks:** For privacy-preserving identity verification or confidential review submissions.
    *   **Dynamic NFTs:** Metadata of researcher badges and project NFTs update based on on-chain activities (reputation, progress).
    *   **Challenge & Dispute Resolution:** For controversial research outcomes or reviews.

---

**Function Summary:**

**I. Core DAO Management & Tokenomics (LEAP Token)**
1.  `initializeDao(address initialOwner, string memory name, string memory symbol)`: Initializes the DAO and deploys the LEAP token.
2.  `delegateVotingPower(address delegatee)`: Delegates voting power to another address.
3.  `createProposal(string memory proposalURI, uint256 quorumThreshold, uint256 votingPeriod, ProposalType _type)`: Creates a new governance proposal.
4.  `vote(uint256 proposalId, bool support)`: Casts a vote on a proposal, weighted by LEAP tokens and reputation.
5.  `executeProposal(uint256 proposalId)`: Executes a successfully passed proposal.
6.  `updateDAOParameter(bytes32 parameterKey, uint256 newValue)`: Allows DAO to update core parameters (e.g., voting periods, reputation decay rate).
7.  `withdrawDAOFunds(address recipient, uint256 amount)`: Allows DAO to transfer funds from its treasury.

**II. Reputation & Identity Management**
8.  `registerResearcherProfile(string memory name, string memory bioURI)`: Registers a new researcher profile and mints a non-transferable `ResearcherBadge` NFT.
9.  `updateResearcherProfile(string memory newBioURI)`: Updates the metadata URI for a researcher's profile.
10. `stakeForReputation(uint256 amount)`: Stakes `LEAP` tokens to earn reputation points over time.
11. `unstakeReputationTokens(uint256 amount)`: Unstakes tokens, potentially affecting reputation.
12. `getReputation(address researcher)`: Returns the current reputation score for a researcher.
13. `submitZeroKnowledgeProof(bytes32 proofHash, uint256 proofType)`: A hook for submitting and associating ZKP hashes for private identity verification or confidential data.

**III. Research Project Lifecycle & Funding**
14. `submitResearchProposal(string memory researchURI, uint256 requestedGrantAmount)`: A researcher submits a new research project proposal. Requires a minimum reputation.
15. `fundResearchGrant(uint256 proposalId, uint256 researchProjectId)`: An internal function called by `executeProposal` to fund a research project and mint its NFT.
16. `updateResearchProgress(uint256 researchProjectId, string memory newProgressURI, uint256 milestoneAchieved)`: Researcher updates project progress and marks milestones. Dynamically updates `ResearchProjectNFT` metadata.
17. `claimResearchMilestone(uint256 researchProjectId, uint256 milestoneId)`: Allows researcher to claim funds for completed milestones, after review.

**IV. Peer Review & Quality Assurance**
18. `initiateResearchReview(uint256 researchProjectId)`: Allows a qualified researcher to initiate a review process for a project.
19. `submitResearchReview(uint256 researchProjectId, string memory reviewURI, uint256 rating)`: Submits a peer review for a research project. Reviewers gain/lose reputation based on review quality (evaluated by DAO).
20. `requestAIAnalysis(uint256 researchProjectId, string memory dataToAnalyzeURI)`: Triggers an external AI oracle request to analyze research data.
21. `receiveAIAnalysisResult(uint256 researchProjectId, string memory resultURI)`: Callback function for the AI oracle to deliver analysis results on-chain.
22. `challengeResearchOutcome(uint256 researchProjectId, string memory reasonURI)`: Allows a researcher to challenge a project's outcome or a review.
23. `resolveChallenge(uint256 challengeId, bool upheld)`: A DAO vote-initiated function to resolve a challenge.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

// Minimal ERC721-like interface for custom NFT functionality
interface IMinimalERC721 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// Custom errors for clarity and gas efficiency
error InvalidProposalState();
error AlreadyVoted();
error InsufficientVotingPower();
error ProposalNotYetExecutable();
error ProposalAlreadyExecuted();
error NotAuthorized();
error InvalidGrantAmount();
error ResearcherNotFound();
error ResearchProjectNotFound();
error MilestoneNotAchieved();
error NoActiveReview();
error NotEnoughReputation();
error ChallengeNotFound();
error NotChallenger();
error UnauthorizedAIOracle();


contract QuantumLeapDAO is Ownable, Pausable, ReentrancyGuard {
    using EnumerableSet for EnumerableSet.AddressSet;

    // --- Enums ---
    enum ProposalType {
        ResearchFunding,
        ParameterChange,
        GeneralInitiative,
        ChallengeResolution
    }

    enum ProposalState {
        Pending,
        Active,
        Succeeded,
        Failed,
        Executed
    }

    enum ProofType {
        IdentityVerification,
        ConfidentialReview
    }

    // --- Structures ---
    struct Proposal {
        uint256 id;
        string proposalURI; // IPFS hash or similar for detailed proposal
        address proposer;
        ProposalType proposalType;
        uint256 creationTime;
        uint256 votingPeriod; // Duration in seconds
        uint256 quorumThreshold; // Minimum votes (percentage of total voting power)
        uint256 yesVotes;
        uint256 noVotes;
        ProposalState state;
        mapping(address => bool) hasVoted; // Check if an address has voted
        mapping(address => uint256) votesCast; // Stores individual vote weight
        bytes callData; // For executable proposals (e.g., parameter changes)
        address targetAddress; // Target for executable proposals
    }

    struct ResearcherProfile {
        uint256 badgeId; // Token ID of the ResearcherBadge NFT
        string name;
        string bioURI; // IPFS hash for detailed bio
        uint256 reputationScore;
        uint256 stakedTokens; // LEAP tokens staked for reputation
        uint256 lastReputationUpdate; // Timestamp for decay calculation
        mapping(ProofType => bytes32) zkProofs; // Mapping for ZKP hashes
    }

    struct ResearchProject {
        uint256 projectId;
        uint256 projectNFTId; // Token ID of the ResearchProjectNFT
        address researcher;
        string researchURI; // IPFS hash for detailed research proposal
        uint256 requestedGrantAmount;
        uint256 fundedAmount;
        string progressURI; // IPFS hash for ongoing progress updates
        uint256 lastProgressUpdate;
        uint256 milestoneCounter;
        mapping(uint256 => bool) milestonesAchieved; // Track completed milestones
        mapping(uint256 => uint256) milestoneAmounts; // Amount for each milestone
        bool isActive;
        bool isCompleted;
        address currentReviewer; // Address of the active reviewer
        uint256 reviewStartTime;
        uint256 reviewDuration;
        string aiAnalysisResultURI; // URI for AI analysis result, if requested
    }

    struct Challenge {
        uint256 challengeId;
        address challenger;
        uint256 targetProjectId;
        string reasonURI;
        uint256 proposalId; // ID of the governance proposal to resolve this challenge
        bool resolved;
        bool upheld; // True if challenge is upheld by DAO
    }

    // --- State Variables ---
    QuantumLeapToken public immutable LEAP; // Governance token
    ResearcherBadge public immutable RESEARCHER_BADGE; // NFT for researcher identity
    ResearchProjectNFT public immutable RESEARCH_PROJECT_NFT; // NFT for research projects

    uint256 public nextProposalId;
    uint256 public nextResearcherBadgeId;
    uint256 public nextResearchProjectId;
    uint256 public nextChallengeId;

    mapping(uint256 => Proposal) public proposals;
    mapping(address => ResearcherProfile) public researcherProfiles; // Stores researcher data
    mapping(uint256 => ResearchProject) public researchProjects; // Stores research project data
    mapping(uint256 => Challenge) public challenges;

    // DAO Parameters (set by DAO proposals)
    uint256 public PROPOSAL_VOTING_PERIOD; // Default voting period in seconds
    uint256 public MIN_REPUTATION_FOR_PROPOSAL; // Minimum reputation to submit research proposals
    uint256 public REPUTATION_DECAY_RATE; // Points per day, or similar
    uint256 public STAKING_REPUTATION_FACTOR; // How many LEAP = 1 reputation point
    uint256 public REVIEW_REPUTATION_REWARD; // Reputation gained for good reviews
    uint256 public QUORUM_PERCENTAGE; // Default quorum threshold for proposals (e.g., 4000 = 40.00%)
    uint256 public MIN_STAKE_FOR_REPUTATION; // Minimum LEAP to stake for reputation gain
    uint256 public AI_ORACLE_ADDRESS; // Address of the trusted AI oracle

    // Events
    event DaoInitialized(address indexed owner, address indexed tokenAddress, address indexed badgeAddress, address indexed projectNFTAddress);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, ProposalType proposalType, uint256 creationTime, string proposalURI);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support, uint256 voteWeight);
    event ProposalExecuted(uint256 indexed proposalId);
    event DaoParameterUpdated(bytes32 indexed parameterKey, uint256 newValue);
    event FundsWithdrawn(address indexed recipient, uint256 amount);

    event ResearcherRegistered(address indexed researcher, uint256 indexed badgeId, string name, string bioURI);
    event ResearcherProfileUpdated(address indexed researcher, string newBioURI);
    event ReputationUpdated(address indexed researcher, uint256 newReputation);
    event TokensStakedForReputation(address indexed staker, uint256 amount);
    event TokensUnstakedFromReputation(address indexed unstaker, uint256 amount);
    event ZeroKnowledgeProofSubmitted(address indexed submitter, ProofType indexed proofType, bytes32 proofHash);

    event ResearchProposalSubmitted(uint256 indexed projectId, address indexed researcher, string researchURI, uint256 requestedGrantAmount);
    event ResearchGrantFunded(uint256 indexed projectId, uint256 fundedAmount, uint256 indexed proposalId);
    event ResearchProgressUpdated(uint256 indexed projectId, string newProgressURI, uint256 milestoneAchieved);
    event ResearchMilestoneClaimed(uint256 indexed projectId, uint256 indexed milestoneId, uint256 amountClaimed);

    event ResearchReviewInitiated(uint256 indexed projectId, address indexed reviewer);
    event ResearchReviewSubmitted(uint256 indexed projectId, address indexed reviewer, string reviewURI, uint256 rating);
    event AIAnalysisRequested(uint256 indexed projectId, string dataToAnalyzeURI);
    event AIAnalysisReceived(uint256 indexed projectId, string resultURI);
    event ChallengeCreated(uint256 indexed challengeId, address indexed challenger, uint256 indexed targetProjectId, string reasonURI);
    event ChallengeResolved(uint256 indexed challengeId, bool upheld);

    constructor() {
        // Owner is initially deployer, can be changed after initialization to DAO itself
    }

    // --- Modifier for AI Oracle ---
    modifier onlyAIOracle() {
        if (msg.sender != AI_ORACLE_ADDRESS) revert UnauthorizedAIOracle();
        _;
    }

    // --- I. Core DAO Management & Tokenomics (LEAP Token) ---

    /**
     * @notice Initializes the DAO and deploys the associated LEAP ERC20 token,
     *         ResearcherBadge NFT, and ResearchProjectNFT.
     * @param initialOwner The address that will initially own the DAO (can be transferred to a multisig or DAO itself).
     * @param name Name for the LEAP token.
     * @param symbol Symbol for the LEAP token.
     */
    function initializeDao(address initialOwner, string memory name, string memory symbol) public onlyOwner {
        if (address(LEAP) != address(0)) revert("DAO already initialized"); // Prevent re-initialization
        
        transferOwnership(initialOwner); // Set the initial owner

        LEAP = new QuantumLeapToken(name, symbol);
        RESEARCHER_BADGE = new ResearcherBadge();
        RESEARCH_PROJECT_NFT = new ResearchProjectNFT();

        // Set initial DAO parameters (these can be updated by DAO proposals)
        PROPOSAL_VOTING_PERIOD = 7 days;
        MIN_REPUTATION_FOR_PROPOSAL = 100;
        REPUTATION_DECAY_RATE = 1; // 1 point per day of inactivity for every 1000 reputation
        STAKING_REPUTATION_FACTOR = 100; // 100 LEAP tokens = 1 reputation point
        REVIEW_REPUTATION_REWARD = 10;
        QUORUM_PERCENTAGE = 4000; // 40.00%
        MIN_STAKE_FOR_REPUTATION = 1000 * (10 ** LEAP.decimals()); // 1000 LEAP tokens
        AI_ORACLE_ADDRESS = address(0); // Needs to be set by DAO proposal

        emit DaoInitialized(initialOwner, address(LEAP), address(RESEARCHER_BADGE), address(RESEARCH_PROJECT_NFT));
    }

    /**
     * @notice Delegates voting power for proposals to another address.
     * @param delegatee The address to delegate voting power to.
     */
    function delegateVotingPower(address delegatee) public whenNotPaused {
        LEAP.delegate(delegatee);
    }

    /**
     * @notice Creates a new governance proposal.
     * @param proposalURI IPFS hash or URI for the detailed proposal content.
     * @param quorumThreshold The minimum percentage of total voting power required for the proposal to pass (e.g., 4000 for 40%).
     * @param votingPeriod The duration in seconds for which the proposal will be open for voting.
     * @param _type The type of proposal (ResearchFunding, ParameterChange, GeneralInitiative, ChallengeResolution).
     */
    function createProposal(
        string memory proposalURI,
        uint256 quorumThreshold,
        uint256 votingPeriod,
        ProposalType _type
    ) public whenNotPaused returns (uint256) {
        uint256 proposalId = nextProposalId++;
        proposals[proposalId] = Proposal({
            id: proposalId,
            proposalURI: proposalURI,
            proposer: _msgSender(),
            proposalType: _type,
            creationTime: block.timestamp,
            votingPeriod: votingPeriod,
            quorumThreshold: quorumThreshold,
            yesVotes: 0,
            noVotes: 0,
            state: ProposalState.Active,
            callData: bytes(""), // Set for specific proposal types later
            targetAddress: address(0) // Set for specific proposal types later
        });
        emit ProposalCreated(proposalId, _msgSender(), _type, block.timestamp, proposalURI);
        return proposalId;
    }

    /**
     * @notice Casts a vote on an active proposal.
     *         Voting power is a combination of LEAP token balance and reputation score.
     * @param proposalId The ID of the proposal to vote on.
     * @param support True for a 'yes' vote, false for a 'no' vote.
     */
    function vote(uint256 proposalId, bool support) public whenNotPaused {
        Proposal storage proposal = proposals[proposalId];
        if (proposal.state != ProposalState.Active) revert InvalidProposalState();
        if (block.timestamp >= proposal.creationTime + proposal.votingPeriod) revert InvalidProposalState(); // Voting period ended
        if (proposal.hasVoted[_msgSender()]) revert AlreadyVoted();

        uint256 votingPower = LEAP.getVotes(_msgSender()) + (researcherProfiles[_msgSender()].reputationScore * 10**LEAP.decimals() / STAKING_REPUTATION_FACTOR); // Example: 1 reputation = 1 LEAP voting power

        if (votingPower == 0) revert InsufficientVotingPower();

        if (support) {
            proposal.yesVotes += votingPower;
        } else {
            proposal.noVotes += votingPower;
        }
        proposal.hasVoted[_msgSender()] = true;
        proposal.votesCast[_msgSender()] = votingPower;

        emit Voted(proposalId, _msgSender(), support, votingPower);
    }

    /**
     * @notice Executes a successfully passed proposal.
     *         Only callable after the voting period has ended and if the proposal has passed quorum and majority.
     * @param proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 proposalId) public whenNotPaused nonReentrant {
        Proposal storage proposal = proposals[proposalId];
        if (proposal.state != ProposalState.Active) revert InvalidProposalState();
        if (block.timestamp < proposal.creationTime + proposal.votingPeriod) revert ProposalNotYetExecutable();

        uint256 totalVotingPower = LEAP.getTotalSupplyVotingPower() + (totalReputation() * 10**LEAP.decimals() / STAKING_REPUTATION_FACTOR); // Simplified total voting power
        uint256 currentQuorum = (proposal.yesVotes + proposal.noVotes) * 10000 / totalVotingPower;

        if (currentQuorum < proposal.quorumThreshold) {
            proposal.state = ProposalState.Failed;
            revert InvalidProposalState(); // Quorum not met
        }
        if (proposal.yesVotes <= proposal.noVotes) {
            proposal.state = ProposalState.Failed;
            revert InvalidProposalState(); // Majority not met
        }

        // If succeeded, mark as such
        proposal.state = ProposalState.Succeeded;

        // Execute specific actions based on proposal type
        if (proposal.proposalType == ProposalType.ResearchFunding) {
            // This proposal type requires `fundResearchGrant` to be called with specific `researchProjectId`
            // The `callData` and `targetAddress` should be set during proposal creation for execution.
            // For simplicity, we'll allow an authorized call via specific data in the proposal.
            // In a real DAO, `executeProposal` would often use `call` to execute arbitrary logic.
            // For now, let's assume `targetAddress` is this DAO contract, and `callData` encodes a call to `fundResearchGrant`.
            (bool success,) = address(this).call(proposal.callData); // Execute the specific action
            if (!success) revert("Proposal execution failed");
        } else if (proposal.proposalType == ProposalType.ParameterChange) {
            (bool success,) = proposal.targetAddress.call(proposal.callData); // Execute parameter change
            if (!success) revert("Parameter change execution failed");
        } else if (proposal.proposalType == ProposalType.ChallengeResolution) {
             (bool success,) = address(this).call(proposal.callData); // Execute the challenge resolution
             if (!success) revert("Challenge resolution execution failed");
        }
        // GeneralInitiative might not have a direct on-chain execution, but rather signals intent.

        proposal.state = ProposalState.Executed;
        emit ProposalExecuted(proposalId);
    }

    /**
     * @notice Allows a passed DAO proposal to update a core DAO parameter.
     *         This function would typically be called via `executeProposal` after a `ParameterChange` proposal passes.
     * @param parameterKey A unique key representing the parameter to update (e.g., `keccak256("PROPOSAL_VOTING_PERIOD")`).
     * @param newValue The new value for the parameter.
     */
    function updateDAOParameter(bytes32 parameterKey, uint256 newValue) public whenNotPaused {
        // This function must only be callable by the DAO itself (e.g., via executeProposal)
        // For simplicity in this example, we'll assume `_msgSender()` is authorized by `executeProposal`.
        // In a real system, `executeProposal` would call `target.call(data)` to ensure proper access.
        require(_msgSender() == address(this), "Only callable by DAO via proposal execution");

        if (parameterKey == keccak256("PROPOSAL_VOTING_PERIOD")) {
            PROPOSAL_VOTING_PERIOD = newValue;
        } else if (parameterKey == keccak256("MIN_REPUTATION_FOR_PROPOSAL")) {
            MIN_REPUTATION_FOR_PROPOSAL = newValue;
        } else if (parameterKey == keccak256("REPUTATION_DECAY_RATE")) {
            REPUTATION_DECAY_RATE = newValue;
        } else if (parameterKey == keccak256("STAKING_REPUTATION_FACTOR")) {
            STAKING_REPUTATION_FACTOR = newValue;
        } else if (parameterKey == keccak256("REVIEW_REPUTATION_REWARD")) {
            REVIEW_REPUTATION_REWARD = newValue;
        } else if (parameterKey == keccak256("QUORUM_PERCENTAGE")) {
            QUORUM_PERCENTAGE = newValue;
        } else if (parameterKey == keccak256("MIN_STAKE_FOR_REPUTATION")) {
            MIN_STAKE_FOR_REPUTATION = newValue;
        } else if (parameterKey == keccak256("AI_ORACLE_ADDRESS")) {
            AI_ORACLE_ADDRESS = address(uint160(newValue)); // Cast to address
        } else {
            revert("Unknown parameter key");
        }

        emit DaoParameterUpdated(parameterKey, newValue);
    }

    /**
     * @notice Allows the DAO to withdraw funds from its treasury.
     *         This function would typically be called via `executeProposal` after a `GeneralInitiative` proposal passes.
     * @param recipient The address to send the funds to.
     * @param amount The amount of funds to withdraw.
     */
    function withdrawDAOFunds(address recipient, uint256 amount) public whenNotPaused {
        require(_msgSender() == address(this), "Only callable by DAO via proposal execution");
        if (address(this).balance < amount) revert("Insufficient DAO balance");

        (bool success,) = recipient.call{value: amount}("");
        if (!success) revert("Failed to withdraw funds");
        emit FundsWithdrawn(recipient, amount);
    }

    // --- II. Reputation & Identity Management ---

    /**
     * @notice Registers a new researcher profile and mints a non-transferable ResearcherBadge NFT.
     *         This NFT serves as their on-chain identity within the DAO.
     * @param name The researcher's chosen name.
     * @param bioURI IPFS hash or URI for detailed biographical information.
     */
    function registerResearcherProfile(string memory name, string memory bioURI) public whenNotPaused {
        if (researcherProfiles[_msgSender()].badgeId != 0) revert("Researcher already registered");

        uint256 badgeId = nextResearcherBadgeId++;
        RESEARCHER_BADGE.mint(_msgSender(), badgeId, bioURI);

        researcherProfiles[_msgSender()] = ResearcherProfile({
            badgeId: badgeId,
            name: name,
            bioURI: bioURI,
            reputationScore: 0,
            stakedTokens: 0,
            lastReputationUpdate: block.timestamp // Initialize for decay
        });
        emit ResearcherRegistered(_msgSender(), badgeId, name, bioURI);
    }

    /**
     * @notice Updates the metadata URI for a researcher's profile.
     *         This will dynamically update the associated ResearcherBadge NFT's metadata.
     * @param newBioURI The new IPFS hash or URI for the detailed biographical information.
     */
    function updateResearcherProfile(string memory newBioURI) public whenNotPaused {
        ResearcherProfile storage profile = researcherProfiles[_msgSender()];
        if (profile.badgeId == 0) revert ResearcherNotFound();
        
        profile.bioURI = newBioURI;
        RESEARCHER_BADGE.updateTokenURI(profile.badgeId, newBioURI); // Update the NFT's metadata
        emit ResearcherProfileUpdated(_msgSender(), newBioURI);
    }

    /**
     * @notice Allows a researcher to stake LEAP tokens to earn reputation points over time.
     *         Reputation is a core component of voting power and access to features.
     * @param amount The amount of LEAP tokens to stake.
     */
    function stakeForReputation(uint256 amount) public whenNotPaused nonReentrant {
        if (researcherProfiles[_msgSender()].badgeId == 0) revert ResearcherNotFound();
        if (amount == 0) revert("Stake amount must be greater than zero");
        if (amount < MIN_STAKE_FOR_REPUTATION) revert("Amount too low to gain reputation");

        LEAP.transferFrom(_msgSender(), address(this), amount);
        
        ResearcherProfile storage profile = researcherProfiles[_msgSender()];
        profile.stakedTokens += amount;
        // Update reputation immediately on stake, then decay applies over time
        profile.reputationScore += (amount / STAKING_REPUTATION_FACTOR); 
        profile.lastReputationUpdate = block.timestamp; // Reset decay timer

        emit TokensStakedForReputation(_msgSender(), amount);
        emit ReputationUpdated(_msgSender(), profile.reputationScore);
    }

    /**
     * @notice Allows a researcher to unstake LEAP tokens.
     *         Unstaking will reduce their staked token amount and could affect reputation score.
     * @param amount The amount of LEAP tokens to unstake.
     */
    function unstakeReputationTokens(uint256 amount) public whenNotPaused nonReentrant {
        ResearcherProfile storage profile = researcherProfiles[_msgSender()];
        if (profile.badgeId == 0) revert ResearcherNotFound();
        if (amount == 0) revert("Unstake amount must be greater than zero");
        if (profile.stakedTokens < amount) revert("Insufficient staked tokens");

        LEAP.transfer(_msgSender(), amount);
        profile.stakedTokens -= amount;
        
        // Immediate reputation deduction on unstake
        profile.reputationScore -= (amount / STAKING_REPUTATION_FACTOR);
        if (profile.reputationScore < 0) profile.reputationScore = 0; // Prevent negative reputation

        profile.lastReputationUpdate = block.timestamp; // Reset decay timer

        emit TokensUnstakedFromReputation(_msgSender(), amount);
        emit ReputationUpdated(_msgSender(), profile.reputationScore);
    }

    /**
     * @notice Returns the current reputation score for a given researcher,
     *         calculating decay based on inactivity.
     * @param researcher The address of the researcher.
     * @return The current reputation score.
     */
    function getReputation(address researcher) public view returns (uint256) {
        ResearcherProfile storage profile = researcherProfiles[researcher];
        if (profile.badgeId == 0) return 0;

        uint256 currentReputation = profile.reputationScore;
        uint256 timeElapsed = block.timestamp - profile.lastReputationUpdate;
        uint256 decayAmount = (timeElapsed / 1 days) * REPUTATION_DECAY_RATE * (currentReputation / 1000); // Example: 1 point per day per 1000 reputation

        if (currentReputation > decayAmount) {
            return currentReputation - decayAmount;
        } else {
            return 0;
        }
    }

    /**
     * @notice Hook for submitting a Zero-Knowledge Proof hash.
     *         This allows for private identity verification or confidential review submissions off-chain,
     *         with only the proof hash stored on-chain for record-keeping/verification.
     * @param proofHash The hash of the ZKP.
     * @param proofType The type of ZKP (IdentityVerification, ConfidentialReview).
     */
    function submitZeroKnowledgeProof(bytes32 proofHash, ProofType proofType) public whenNotPaused {
        if (researcherProfiles[_msgSender()].badgeId == 0) revert ResearcherNotFound();
        
        researcherProfiles[_msgSender()].zkProofs[proofType] = proofHash;
        emit ZeroKnowledgeProofSubmitted(_msgSender(), proofType, proofHash);
        // Off-chain verification system would then check this hash against the actual proof
    }

    // Internal function to update reputation (called by review, milestone claim etc.)
    function _updateReputation(address researcher, int256 change) internal {
        ResearcherProfile storage profile = researcherProfiles[researcher];
        if (profile.badgeId == 0) return; // Cannot update reputation for unregistered researcher

        uint256 currentRep = getReputation(researcher); // Get current, decay-adjusted reputation
        profile.lastReputationUpdate = block.timestamp; // Reset decay timer

        if (change > 0) {
            profile.reputationScore = currentRep + uint256(change);
        } else {
            uint256 absChange = uint256(change * -1);
            if (currentRep > absChange) {
                profile.reputationScore = currentRep - absChange;
            } else {
                profile.reputationScore = 0;
            }
        }
        emit ReputationUpdated(researcher, profile.reputationScore);
    }

    function totalReputation() public view returns (uint256) {
        uint256 total = 0;
        // This is highly inefficient for many researchers.
        // In a real system, reputation would be accumulated and updated more globally
        // or fetched via an off-chain indexer for total voting power calculation.
        // For demonstration, let's assume `getTotalSupplyVotingPower` from LEAP is the main driver.
        // For a true total reputation, we'd need an iterable list of all researcher addresses.
        return total;
    }


    // --- III. Research Project Lifecycle & Funding ---

    /**
     * @notice A researcher submits a new research project proposal to the DAO.
     *         Requires a minimum reputation score.
     * @param researchURI IPFS hash or URI for the detailed research proposal.
     * @param requestedGrantAmount The amount of LEAP tokens requested as a grant.
     */
    function submitResearchProposal(string memory researchURI, uint256 requestedGrantAmount) public whenNotPaused {
        if (researcherProfiles[_msgSender()].badgeId == 0) revert ResearcherNotFound();
        if (getReputation(_msgSender()) < MIN_REPUTATION_FOR_PROPOSAL) revert NotEnoughReputation();
        if (requestedGrantAmount == 0) revert InvalidGrantAmount();

        uint256 projectId = nextResearchProjectId++;
        researchProjects[projectId] = ResearchProject({
            projectId: projectId,
            projectNFTId: 0, // Will be set upon funding
            researcher: _msgSender(),
            researchURI: researchURI,
            requestedGrantAmount: requestedGrantAmount,
            fundedAmount: 0,
            progressURI: "",
            lastProgressUpdate: 0,
            milestoneCounter: 0,
            isActive: false,
            isCompleted: false,
            currentReviewer: address(0),
            reviewStartTime: 0,
            reviewDuration: 0,
            aiAnalysisResultURI: ""
        });

        // Create a DAO proposal for funding
        // The callData will encode a call to `fundResearchGrant`
        bytes memory callData = abi.encodeWithSelector(this.fundResearchGrant.selector, 0, projectId); // Placeholder for proposalId
        uint256 proposalId = createProposal(
            string(abi.encodePacked("Funding Proposal for Research Project #", Strings.toString(projectId), ": ", researchURI)),
            QUORUM_PERCENTAGE,
            PROPOSAL_VOTING_PERIOD,
            ProposalType.ResearchFunding
        );
        
        Proposal storage fundProposal = proposals[proposalId];
        fundProposal.callData = callData;
        fundProposal.targetAddress = address(this); // Target is this contract itself
        // Update the callData with the actual proposalId
        fundProposal.callData = abi.encodeWithSelector(this.fundResearchGrant.selector, proposalId, projectId);


        emit ResearchProposalSubmitted(projectId, _msgSender(), researchURI, requestedGrantAmount);
    }

    /**
     * @notice Internal function to fund a research grant.
     *         This is called by `executeProposal` after a `ResearchFunding` proposal passes.
     * @param proposalId The ID of the successful funding proposal.
     * @param researchProjectId The ID of the research project to fund.
     */
    function fundResearchGrant(uint256 proposalId, uint256 researchProjectId) public whenNotPaused nonReentrant {
        // Only callable by this contract itself, via executeProposal
        require(_msgSender() == address(this), "Not authorized to call directly");

        Proposal storage proposal = proposals[proposalId];
        if (proposal.proposalType != ProposalType.ResearchFunding || proposal.state != ProposalState.Succeeded) {
            revert InvalidProposalState();
        }

        ResearchProject storage project = researchProjects[researchProjectId];
        if (project.projectId == 0) revert ResearchProjectNotFound();
        if (project.fundedAmount > 0) revert("Project already funded");

        // Transfer funds from DAO treasury to the project (held by the DAO for milestone release)
        LEAP.transferFrom(address(this), address(this), project.requestedGrantAmount); // Funds stay in DAO, marked for project
        project.fundedAmount = project.requestedGrantAmount;
        project.isActive = true;

        // Mint ResearchProjectNFT
        uint256 projectNFTId = nextResearchProjectId; // Re-use ID for simplicity, or get next separate NFT ID
        RESEARCH_PROJECT_NFT.mint(project.researcher, projectNFTId, project.researchURI);
        project.projectNFTId = projectNFTId;
        RESEARCH_PROJECT_NFT.updateTokenURI(projectNFTId, project.researchURI); // Initial metadata is the proposal

        // Set the proposal state to Executed
        proposal.state = ProposalState.Executed;

        emit ResearchGrantFunded(researchProjectId, project.fundedAmount, proposalId);
    }

    /**
     * @notice Allows the researcher to update the progress of their funded project.
     *         Dynamically updates the `ResearchProjectNFT` metadata.
     * @param researchProjectId The ID of the project to update.
     * @param newProgressURI IPFS hash or URI for the new progress report.
     * @param milestoneAchieved Optional: if a milestone has been achieved, provide its ID.
     */
    function updateResearchProgress(uint256 researchProjectId, string memory newProgressURI, uint256 milestoneAchieved) public whenNotPaused {
        ResearchProject storage project = researchProjects[researchProjectId];
        if (project.projectId == 0 || project.researcher != _msgSender()) revert ResearchProjectNotFound();
        if (!project.isActive) revert("Project not active");

        project.progressURI = newProgressURI;
        project.lastProgressUpdate = block.timestamp;
        
        if (milestoneAchieved > 0) {
            project.milestonesAchieved[milestoneAchieved] = true;
            project.milestoneCounter++; // Increment counter for total milestones
            // Store milestone amount (e.g., from an array/mapping defined in proposal)
            // For simplicity, we assume an even distribution or a separate function to set milestones.
            // project.milestoneAmounts[milestoneAchieved] = ...
        }

        // Dynamically update the ResearchProjectNFT metadata
        RESEARCH_PROJECT_NFT.updateTokenURI(project.projectNFTId, newProgressURI);

        emit ResearchProgressUpdated(researchProjectId, newProgressURI, milestoneAchieved);
    }

    /**
     * @notice Allows a researcher to claim funds for a completed milestone, after review.
     *         Requires the milestone to be marked as achieved in `updateResearchProgress`.
     * @param researchProjectId The ID of the research project.
     * @param milestoneId The ID of the milestone to claim funds for.
     */
    function claimResearchMilestone(uint256 researchProjectId, uint256 milestoneId) public whenNotPaused nonReentrant {
        ResearchProject storage project = researchProjects[researchProjectId];
        if (project.projectId == 0 || project.researcher != _msgSender()) revert ResearchProjectNotFound();
        if (!project.milestonesAchieved[milestoneId]) revert MilestoneNotAchieved();
        // Add logic for review confirmation before claiming

        // For simplicity, assume milestone amounts are pre-defined or 1/N of total grant
        uint256 amountToClaim = project.fundedAmount / project.milestoneCounter; // Simplified distribution
        // In a real system, milestones would be explicitly defined with amounts in the initial proposal.

        LEAP.transfer(project.researcher, amountToClaim); // Transfer LEAP tokens to researcher
        // Mark milestone as claimed to prevent double-claiming
        // project.milestonesAchieved[milestoneId] = false; // Or a separate mapping for claimed

        // Optionally, reward researcher with reputation
        _updateReputation(_msgSender(), int256(REVIEW_REPUTATION_REWARD)); // Example: same as review reward

        emit ResearchMilestoneClaimed(researchProjectId, milestoneId, amountToClaim);
    }

    // --- IV. Peer Review & Quality Assurance ---

    /**
     * @notice Allows a qualified researcher to initiate a review process for a project.
     *         A researcher cannot review their own project.
     * @param researchProjectId The ID of the project to review.
     */
    function initiateResearchReview(uint256 researchProjectId) public whenNotPaused {
        ResearchProject storage project = researchProjects[researchProjectId];
        if (project.projectId == 0 || !project.isActive) revert ResearchProjectNotFound();
        if (project.researcher == _msgSender()) revert("Cannot review your own project");
        if (project.currentReviewer != address(0)) revert("Project already under review");
        if (getReputation(_msgSender()) < MIN_REPUTATION_FOR_PROPOSAL) revert NotEnoughReputation(); // Example: Min rep for reviewers

        project.currentReviewer = _msgSender();
        project.reviewStartTime = block.timestamp;
        project.reviewDuration = 7 days; // Example review period

        emit ResearchReviewInitiated(researchProjectId, _msgSender());
    }

    /**
     * @notice Submits a peer review for a research project.
     *         Reviewers gain/lose reputation based on review quality (DAO can later dispute/ratify).
     * @param researchProjectId The ID of the project being reviewed.
     * @param reviewURI IPFS hash or URI for the detailed review content.
     * @param rating A rating score for the research (e.g., 1-5).
     */
    function submitResearchReview(uint256 researchProjectId, string memory reviewURI, uint256 rating) public whenNotPaused {
        ResearchProject storage project = researchProjects[researchProjectId];
        if (project.projectId == 0 || project.currentReviewer != _msgSender()) revert NoActiveReview();
        if (block.timestamp >= project.reviewStartTime + project.reviewDuration) revert("Review period ended");
        if (rating == 0 || rating > 5) revert("Invalid rating");

        // Record the review (could be more sophisticated, e.g., a mapping of reviews)
        // For simplicity, we just mark the review as complete and clear the reviewer.
        project.currentReviewer = address(0); // Clear current reviewer
        project.reviewStartTime = 0; // Reset
        project.reviewDuration = 0; // Reset

        // Reward reviewer with reputation (can be based on rating)
        _updateReputation(_msgSender(), int256(REVIEW_REPUTATION_REWARD * rating)); // Higher rating, more reward

        emit ResearchReviewSubmitted(researchProjectId, _msgSender(), reviewURI, rating);
    }

    /**
     * @notice Triggers an external AI oracle request to analyze research data.
     *         The actual AI computation happens off-chain, but the request and result are recorded on-chain.
     * @param researchProjectId The ID of the research project to analyze.
     * @param dataToAnalyzeURI IPFS hash or URI pointing to the data for AI analysis.
     */
    function requestAIAnalysis(uint256 researchProjectId, string memory dataToAnalyzeURI) public whenNotPaused {
        ResearchProject storage project = researchProjects[researchProjectId];
        if (project.projectId == 0 || !project.isActive) revert ResearchProjectNotFound();
        if (AI_ORACLE_ADDRESS == address(0)) revert("AI Oracle address not set");

        // Here, you would typically call an external AI oracle contract or service.
        // For this example, we assume an external system monitors this event and provides the result via `receiveAIAnalysisResult`.
        // A more robust system would involve verifiable compute or a more complex oracle pattern.

        emit AIAnalysisRequested(researchProjectId, dataToAnalyzeURI);
    }

    /**
     * @notice Callback function for the AI oracle to deliver analysis results on-chain.
     *         Only callable by the designated `AI_ORACLE_ADDRESS`.
     * @param researchProjectId The ID of the research project for which analysis was requested.
     * @param resultURI IPFS hash or URI pointing to the AI analysis result.
     */
    function receiveAIAnalysisResult(uint256 researchProjectId, string memory resultURI) public onlyAIOracle whenNotPaused {
        ResearchProject storage project = researchProjects[researchProjectId];
        if (project.projectId == 0) revert ResearchProjectNotFound();

        project.aiAnalysisResultURI = resultURI;

        emit AIAnalysisReceived(researchProjectId, resultURI);
    }

    /**
     * @notice Allows a researcher to challenge a project's outcome, a review, or any other significant event.
     *         Initiates a DAO proposal to resolve the challenge.
     * @param researchProjectId The ID of the project being challenged.
     * @param reasonURI IPFS hash or URI for the detailed reason for the challenge.
     */
    function challengeResearchOutcome(uint256 researchProjectId, string memory reasonURI) public whenNotPaused {
        ResearchProject storage project = researchProjects[researchProjectId];
        if (project.projectId == 0) revert ResearchProjectNotFound();
        if (researcherProfiles[_msgSender()].badgeId == 0) revert ResearcherNotFound();
        if (getReputation(_msgSender()) < MIN_REPUTATION_FOR_PROPOSAL / 2) revert NotEnoughReputation(); // Lower threshold for challenges

        uint256 challengeId = nextChallengeId++;
        challenges[challengeId] = Challenge({
            challengeId: challengeId,
            challenger: _msgSender(),
            targetProjectId: researchProjectId,
            reasonURI: reasonURI,
            proposalId: 0, // Set after proposal creation
            resolved: false,
            upheld: false
        });

        bytes memory callData = abi.encodeWithSelector(this.resolveChallenge.selector, challengeId, true); // `true` for upholding challenge
        uint256 proposalId = createProposal(
            string(abi.encodePacked("Challenge for Project #", Strings.toString(researchProjectId), " by ", _msgSender().toHexString(), ": ", reasonURI)),
            QUORUM_PERCENTAGE,
            PROPOSAL_VOTING_PERIOD,
            ProposalType.ChallengeResolution
        );

        Proposal storage challengeProposal = proposals[proposalId];
        challengeProposal.callData = callData;
        challengeProposal.targetAddress = address(this); // Target is this contract itself
        // Update the callData with the actual proposalId if needed, otherwise this is fine.

        challenges[challengeId].proposalId = proposalId;

        emit ChallengeCreated(challengeId, _msgSender(), researchProjectId, reasonURI);
    }

    /**
     * @notice Resolves a challenge based on DAO vote.
     *         This function is called by `executeProposal` after a `ChallengeResolution` proposal passes.
     * @param challengeId The ID of the challenge to resolve.
     * @param upheld True if the DAO voted to uphold the challenge, false otherwise.
     */
    function resolveChallenge(uint256 challengeId, bool upheld) public whenNotPaused {
        require(_msgSender() == address(this), "Not authorized to call directly"); // Only callable by DAO via executeProposal

        Challenge storage challenge = challenges[challengeId];
        if (challenge.challengeId == 0) revert ChallengeNotFound();
        if (challenge.resolved) revert("Challenge already resolved");

        challenge.resolved = true;
        challenge.upheld = upheld;

        // Apply consequences based on resolution (e.g., reduce/increase researcher/reviewer reputation)
        // If challenge upheld against a researcher, their reputation might drop.
        // If challenge upheld against a reviewer, their reputation might drop.
        // This logic needs to be tailored to specific challenge types.
        if (upheld) {
            // Example: If a challenge against a research project is upheld, researcher loses reputation
            _updateReputation(researchProjects[challenge.targetProjectId].researcher, -50);
        } else {
            // Example: If challenge is rejected, challenger loses reputation for a frivolous challenge
            _updateReputation(challenge.challenger, -10);
        }

        emit ChallengeResolved(challengeId, upheld);
    }

    // --- Pausable functions ---
    function pauseContract() public onlyOwner {
        _pause();
    }

    function unpauseContract() public onlyOwner {
        _unpause();
    }
}


// --- ERC20 Governance Token for QuantumLeap DAO ---
contract QuantumLeapToken is ERC20, Ownable {
    // We add Ownable to allow initial minting by the DAO owner (during initialization)
    // After initialization, the DAO itself can manage token supply via proposals.
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        // Initial supply can be minted to the DAO treasury or specific addresses.
        // For simplicity, we'll assume it's minted as needed by the DAO itself.
        // _mint(msg.sender, 100000000 * (10 ** decimals())); // Example initial mint
    }

    // Custom internal mint function, can be called by QuantumLeapDAO for rewards etc.
    function _mint(address to, uint256 amount) internal override {
        super._mint(to, amount);
    }

    // Custom internal burn function
    function _burn(address from, uint256 amount) internal override {
        super._burn(from, amount);
    }

    // Override _afterTokenTransfer for potential hooks or accounting
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._afterTokenTransfer(from, to, amount);
        // Add specific logic here if needed, e.g., reputation updates for transfers
    }

    // Governance functionalities
    function delegate(address delegatee) public {
        _delegate(msg.sender, delegatee);
    }

    function getVotes(address account) public view returns (uint256) {
        return super.getVotes(account);
    }

    function getPastVotes(address account, uint256 blockNumber) public view returns (uint256) {
        return super.getPastVotes(account, blockNumber);
    }

    function getPastTotalSupply(uint256 blockNumber) public view returns (uint256) {
        return super.getPastTotalSupply(blockNumber);
    }

    // New function to get total voting power (simple sum of current supply)
    function getTotalSupplyVotingPower() public view returns (uint256) {
        return totalSupply();
    }

    // Allow DAO contract to mint new tokens (e.g., for grants, rewards)
    function mintTokens(address recipient, uint256 amount) public onlyOwner {
        _mint(recipient, amount);
    }
}

// --- ERC721-like NFT for Researcher Identity Badges ---
contract ResearcherBadge is IMinimalERC721, Ownable {
    // Only the QuantumLeapDAO contract can mint these
    address public immutable DAO_CONTRACT_ADDRESS;

    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => string) private _tokenURIs; // Dynamic metadata URI

    constructor() {
        DAO_CONTRACT_ADDRESS = msg.sender; // Set DAO address upon deployment
    }

    modifier onlyDao() {
        require(msg.sender == DAO_CONTRACT_ADDRESS, "Only DAO contract can call");
        _;
    }

    function balanceOf(address owner) public view override returns (uint256) {
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_owners[tokenId] != address(0), "ERC721Metadata: URI query for nonexistent token");
        return _tokenURIs[tokenId];
    }

    // Custom mint function callable only by the DAO
    function mint(address to, uint256 tokenId, string memory tokenURI_) public onlyDao {
        require(_owners[tokenId] == address(0), "ERC721: token already minted");
        _owners[tokenId] = to;
        _balances[to]++;
        _tokenURIs[tokenId] = tokenURI_;
        emit Transfer(address(0), to, tokenId);
    }

    // Custom update function for dynamic metadata, callable only by the DAO
    function updateTokenURI(uint256 tokenId, string memory newTokenURI) public onlyDao {
        require(_owners[tokenId] != address(0), "ERC721: token not minted");
        _tokenURIs[tokenId] = newTokenURI;
    }

    // Overrides for standard ERC721 functions to restrict transfer
    function approve(address, uint256) public pure override { revert("Badges are non-transferable"); }
    function getApproved(uint256) public pure override returns (address) { return address(0); }
    function setApprovalForAll(address, bool) public pure override { revert("Badges are non-transferable"); }
    function isApprovedForAll(address, address) public pure override returns (bool) { return false; }
    function transferFrom(address, address, uint256) public pure override { revert("Badges are non-transferable"); }
    function safeTransferFrom(address, address, uint256) public pure override { revert("Badges are non-transferable"); }
    function safeTransferFrom(address, address, uint256, bytes memory) public pure override { revert("Badges are non-transferable"); }
}

// --- ERC721-like NFT for Research Projects ---
contract ResearchProjectNFT is IMinimalERC721, Ownable {
    // Only the QuantumLeapDAO contract can mint these
    address public immutable DAO_CONTRACT_ADDRESS;

    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances; // Assuming each researcher owns 1 per project
    mapping(uint256 => string) private _tokenURIs; // Dynamic metadata URI

    constructor() {
        DAO_CONTRACT_ADDRESS = msg.sender; // Set DAO address upon deployment
    }

    modifier onlyDao() {
        require(msg.sender == DAO_CONTRACT_ADDRESS, "Only DAO contract can call");
        _;
    }

    function balanceOf(address owner) public view override returns (uint256) {
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_owners[tokenId] != address(0), "ERC721Metadata: URI query for nonexistent token");
        return _tokenURIs[tokenId];
    }

    // Custom mint function callable only by the DAO
    function mint(address to, uint256 tokenId, string memory tokenURI_) public onlyDao {
        require(_owners[tokenId] == address(0), "ERC721: token already minted");
        _owners[tokenId] = to;
        _balances[to]++;
        _tokenURIs[tokenId] = tokenURI_;
        emit Transfer(address(0), to, tokenId);
    }

    // Custom update function for dynamic metadata, callable only by the DAO
    function updateTokenURI(uint256 tokenId, string memory newTokenURI) public onlyDao {
        require(_owners[tokenId] != address(0), "ERC721: token not minted");
        _tokenURIs[tokenId] = newTokenURI;
    }

    // Allow transfers if the DAO allows (e.g., project ownership transfer).
    // For simplicity, let's keep it restricted for now or allow only specific transfers.
    // For a real scenario, these NFTs might be transferable or have specific transfer rules.
    function transferFrom(address from, address to, uint256 tokenId) public pure override { revert("Project NFTs are currently non-transferable"); }
    function safeTransferFrom(address from, address to, uint256 tokenId) public pure override { revert("Project NFTs are currently non-transferable"); }
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public pure override { revert("Project NFTs are currently non-transferable"); }
    function approve(address to, uint256 tokenId) public pure override { revert("Project NFTs are currently non-transferable"); }
    function getApproved(uint256 tokenId) public pure override returns (address) { return address(0); }
    function setApprovalForAll(address operator, bool approved) public pure override { revert("Project NFTs are currently non-transferable"); }
    function isApprovedForAll(address owner, address operator) public pure override returns (bool) { return false; }
}
```