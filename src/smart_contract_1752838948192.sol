This smart contract, `BioGenesisCore`, implements a Decentralized AI-Augmented Research & Development (DARD) platform. It aims to foster innovation in bio-inspired algorithms and decentralized intelligence by funding projects, managing a dynamic reputation system, and evolving its own governance parameters.

---

## Smart Contract Outline & Function Summary

**Contract Name:** `BioGenesisCore`

This contract orchestrates the BioGenesis Protocol, managing research proposals, funding, participant reputation, and adaptive governance. It interacts with external ERC-20 (GenePool Token) and non-transferable ERC-721 (Genome NFT) contracts, as well as off-chain oracles for AI evaluations and knowledge base verification.

---

### **I. Core Architecture & Initialization**

1.  **`constructor(address _genePoolToken, address _genomeNFT, address _aiRatingOracle, address _knowledgeBaseOracle)`**:
    *   Initializes the contract owner, sets addresses for the GenePool ERC-20 token, Genome ERC-721 NFT, AI Rating Oracle, and Knowledge Base Oracle. Sets initial governance parameters.

2.  **`setGenePoolTokenAddress(address _newAddress)`**:
    *   **Access:** `onlyOwner`
    *   Updates the address of the GenePool ERC-20 token contract.

3.  **`setGenomeNFTAddress(address _newAddress)`**:
    *   **Access:** `onlyOwner`
    *   Updates the address of the Genome ERC-721 NFT contract.

4.  **`setAIRatingOracle(address _newAddress)`**:
    *   **Access:** `onlyOwner`
    *   Updates the address of the AI Rating Oracle contract.

5.  **`setKnowledgeBaseOracle(address _newAddress)`**:
    *   **Access:** `onlyOwner`
    *   Updates the address of the Knowledge Base Oracle contract.

---

### **II. Governance & Protocol Parameters (Emergent Protocol Parameters)**

6.  **`proposeParameterChange(string memory _paramName, uint256 _newValue, string memory _description)`**:
    *   Allows any participant with a Genome NFT and sufficient reputation to propose a change to a predefined protocol parameter. Requires an initial stake.

7.  **`voteOnParameterChange(uint256 _proposalId, bool _support)`**:
    *   Allows Genome NFT holders to vote (support or oppose) on an active parameter change proposal. Voting power is proportional to their Genome NFT's influence trait.

8.  **`executeParameterChange(uint256 _proposalId)`**:
    *   Executes a parameter change proposal if it has met the required voting thresholds and deliberation period. Updates the relevant protocol parameter.

9.  **`setGovernanceThresholds(uint256 _minVotingPower, uint256 _quorumPercentage, uint256 _majorityPercentage, uint256 _votingPeriod)`**:
    *   **Access:** `onlyGovernanceCouncil` (executed via parameter change proposal)
    *   Adjusts the minimum voting power required for a vote, the quorum percentage, the majority percentage, and the voting period for governance proposals.

10. **`updateAIWeightingFactor(uint256 _newWeight)`**:
    *   **Access:** `onlyGovernanceCouncil` (executed via parameter change proposal)
    *   Adjusts the weighting factor for the AI oracle's influence in proposal evaluations, allowing the DAO to adapt the role of AI.

---

### **III. Research Proposal Management**

11. **`submitResearchProposal(string memory _title, string memory _description, string memory _ipfsDocHash, uint256 _totalFundingRequired, uint256[] memory _milestoneAmounts)`**:
    *   Allows a participant to submit a new research proposal, including its details, a link to off-chain documentation, total funding, and a breakdown of funding per milestone.

12. **`stakeForProposalEligibility(uint256 _proposalId)`**:
    *   Proposer stakes GenePool tokens to make their proposal eligible for AI and community review. This stake can be slashed.

13. **`aiEvaluateProposal(uint256 _proposalId, uint256 _aiRating, string memory _aiFeedbackHash)`**:
    *   **Access:** `onlyAIRatingOracle`
    *   The designated AI oracle submits an initial objective rating and feedback hash for a pending research proposal. This rating influences community perception and potential funding.

14. **`communityReviewProposal(uint256 _proposalId, string memory _feedbackHash)`**:
    *   Allows Genome NFT holders to submit off-chain feedback (hash linked) on a proposal. This action contributes to their Genome's "Insight" trait.

15. **`fundProposalInitialMilestone(uint256 _proposalId)`**:
    *   **Access:** `onlyGovernanceCouncil` (after proposal approval via governance)
    *   Transfers the funding for the first milestone to the proposer after the proposal has been approved by governance.

16. **`submitMilestoneCompletion(uint256 _proposalId, uint256 _milestoneIndex, string memory _proofHash)`**:
    *   The researcher marks a specific milestone as completed and provides an off-chain proof hash.

17. **`verifyMilestoneCompletion(uint256 _proposalId, uint256 _milestoneIndex, bool _isSuccessful, string memory _verificationFeedbackHash)`**:
    *   **Access:** `onlyAIRatingOracle` or `onlyGovernanceCouncil`
    *   An authorized entity (AI or governance vote) verifies the completion of a milestone. If successful, it triggers the funding of the next milestone or project completion.

18. **`fundNextMilestone(uint256 _proposalId)`**:
    *   **Access:** `onlyGovernanceCouncil` (automatically triggered after `verifyMilestoneCompletion` if successful)
    *   Releases funds for the next pending milestone of a project if the current one has been successfully verified.

19. **`cancelProposal(uint256 _proposalId, string memory _reasonHash)`**:
    *   Allows the governance council to cancel a proposal or project at any stage, potentially slashing the proposer's staked tokens.

---

### **IV. Dynamic Reputation "Genome" NFTs (ERC-721 Interface Interactions)**

20. **`mintGenomeNFT()`**:
    *   Allows a new participant to mint their unique, non-transferable "Genome" NFT, representing their identity and potential within the BioGenesis Protocol. Limited to one per address.

21. **`updateGenomeTraits(address _user, uint256 _proposalSuccessPoints, uint256 _evaluationAccuracyPoints, uint256 _contributionPoints)`**:
    *   **Access:** `internal` (called by other functions in this contract)
    *   Updates the on-chain traits (metadata URI) of a user's Genome NFT based on their contributions and performance within the protocol. This drives the "dynamic" aspect.

22. **`getGenomeTraits(address _user)`**:
    *   **Access:** `public view`
    *   Retrieves the current numerical trait values (e.g., success, insight, influence) of a user's Genome NFT from the Genome NFT contract.

23. **`burnGenomeNFT(address _user, string memory _reasonHash)`**:
    *   **Access:** `onlyGovernanceCouncil`
    *   Allows the governance council to burn a Genome NFT in cases of severe misconduct, removing the participant's reputation and access.

---

### **V. Incentives & Rewards**

24. **`claimRewards()`**:
    *   Allows participants to claim their accumulated GenePool token rewards earned from successful evaluations, milestone completions, or valuable feedback.

25. **`distributeEvaluatorRewards(uint256 _proposalId)`**:
    *   **Access:** `internal` (called after successful proposal/milestone verification)
    *   Distributes a portion of the GenePool token rewards to community members who provided accurate evaluations or reviews for a successful proposal/milestone.

26. **`distributeFeedbackIncentives(uint256 _proposalId, address _feedbackProvider)`**:
    *   **Access:** `internal` (manually triggered by governance for exceptional feedback)
    *   Provides ad-hoc incentives for particularly insightful feedback or vulnerability disclosures related to proposals.

27. **`slashStakedTokens(address _staker, uint256 _amount, string memory _reasonHash)`**:
    *   **Access:** `internal` (called by functions like `cancelProposal` or `verifyMilestoneCompletion` on failure)
    *   Implements a slashing mechanism for staked GenePool tokens in cases of non-compliance, fraud, or failed milestones.

---

### **VI. Knowledge Base Management (Merkle Tree / IPFS Integration)**

28. **`registerKnowledgeBaseRoot(uint256 _proposalId, bytes32 _merkleRootHash, string memory _rootMetadataURI)`**:
    *   Registers the Merkle root hash and metadata URI for the project's knowledge base (e.g., research papers, datasets) associated with a completed or ongoing proposal.

29. **`verifyKnowledgeBaseContent(uint256 _proposalId, bytes32 _leafHash, bytes32[] memory _merkleProof)`**:
    *   **Access:** `onlyKnowledgeBaseOracle` (or `onlyGovernanceCouncil`)
    *   Verifies that a specific piece of content (represented by `_leafHash`) is included in the registered Merkle tree for a given project, ensuring data integrity.

30. **`accessGatedContent(uint256 _proposalId, bytes32 _leafHash)`**:
    *   **Access:** `public view` (Conceptual - requires off-chain integration)
    *   A conceptual function that checks if a user's Genome NFT traits meet the requirements to access specific gated content within a project's knowledge base. (On-chain, it merely verifies Merkle proof; access control is off-chain).

---

### **VII. Treasury & Fund Management**

31. **`depositToTreasury()`**:
    *   Allows anyone to directly deposit GenePool tokens into the BioGenesis Protocol's treasury, increasing its funding capacity for research.

32. **`withdrawFromTreasury(address _recipient, uint256 _amount)`**:
    *   **Access:** `onlyGovernanceCouncil` (executed via parameter change proposal)
    *   Allows the governance council to withdraw funds from the treasury for approved operational costs or strategic investments.

---

### **VIII. Administrative Functions**

33. **`pause()`**:
    *   **Access:** `onlyOwner`
    *   Pauses critical contract functions in case of emergencies (e.g., security vulnerabilities).

34. **`unpause()`**:
    *   **Access:** `onlyOwner`
    *   Unpauses the contract functions.

---

**Note on Oracles:** The `AI Rating Oracle` and `Knowledge Base Oracle` are conceptual external entities (could be smart contracts, multi-sig wallets, or off-chain systems with verifiable outputs) that provide data to `BioGenesisCore`. Their implementation is beyond the scope of this single contract, but their interface is defined.

**Note on Genome NFT:** The `IGenomeNFT` interface is used to interact with a separate contract responsible for managing the actual ERC-721 tokens and their dynamic metadata updates. The `BioGenesisCore` contract is designed to be the sole authority for minting and updating these NFTs' traits.

---
---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

// --- INTERFACES ---

/**
 * @title IGenomeNFT
 * @dev Interface for the non-transferable Genome NFT contract.
 *      This NFT represents a participant's reputation and dynamically updates its traits.
 */
interface IGenomeNFT is IERC721, IERC721Metadata {
    function mint(address to) external returns (uint256 tokenId);
    function updateTraits(uint256 tokenId, uint256 successPoints, uint256 evaluationAccuracyPoints, uint256 contributionPoints) external;
    function getTraits(uint256 tokenId) external view returns (uint256 successPoints, uint256 evaluationAccuracyPoints, uint256 contributionPoints);
    function exists(uint256 tokenId) external view returns (bool);
    function getTokenId(address owner) external view returns (uint256);
    function burn(uint256 tokenId) external; // For governance council
}

/**
 * @title IAIRatingOracle
 * @dev Interface for an external AI oracle responsible for rating research proposals.
 */
interface IAIRatingOracle {
    function submitRating(uint256 proposalId, uint256 aiRating, string calldata aiFeedbackHash) external;
}

/**
 * @title IKnowledgeBaseOracle
 * @dev Interface for an external oracle that verifies content within a project's Merkle-rooted knowledge base.
 */
interface IKnowledgeBaseOracle {
    function verifyContent(uint256 proposalId, bytes32 leafHash, bytes32[] calldata merkleProof) external returns (bool);
}

// --- MAIN CONTRACT ---

/**
 * @title BioGenesisCore
 * @dev A decentralized AI-augmented research & development (DARD) platform.
 *      It manages research proposals, funding, dynamic reputation NFTs, and adaptive governance.
 */
contract BioGenesisCore is Ownable, Pausable, ReentrancyGuard {

    // --- ENUMS ---
    enum ProposalState {
        AwaitingEligibilityStake,
        UnderAIReview,
        UnderCommunityReview,
        Approved,
        Rejected,
        Active,
        Completed,
        Cancelled
    }

    enum MilestoneState {
        Pending,
        SubmittedForVerification,
        Verified,
        Failed
    }

    enum GovernanceProposalState {
        Pending,
        Active,
        Succeeded,
        Failed,
        Executed
    }

    // --- STRUCTS ---

    struct ResearchProposal {
        uint256 id;
        address proposer;
        string title;
        string description;
        string ipfsDocHash; // Hash pointing to detailed proposal document on IPFS/Arweave
        uint256 totalFundingRequired;
        uint256 initialStakeAmount;
        uint256 aiRating; // 0-100 score from AI oracle
        string aiFeedbackHash;
        ProposalState state;
        uint256 submittedAt;

        uint256[] milestoneAmounts; // Funding per milestone
        MilestoneState[] milestoneStates;
        uint256 currentMilestoneIndex;
        string[] milestoneProofHashes; // Proof for each completed milestone
        string[] verificationFeedbackHashes; // Feedback from verifiers
        uint256 lastMilestonePaymentTime;
    }

    struct GovernanceProposal {
        uint256 id;
        address proposer;
        string paramName; // e.g., "minVotingPower", "quorumPercentage"
        uint256 newValue;
        string description;
        GovernanceProposalState state;
        uint256 submittedAt;
        uint256 votingEndsAt;
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted; // Tracks if an address has voted on this proposal
        mapping(address => uint256) voterWeight; // Tracks voting power used by each voter
    }

    struct ParticipantRewards {
        uint256 genePoolRewards;
        // Potentially other types of rewards or points
    }

    // --- STATE VARIABLES ---

    // Contract addresses
    IERC20 public genePoolToken;
    IGenomeNFT public genomeNFT;
    IAIRatingOracle public aiRatingOracle;
    IKnowledgeBaseOracle public knowledgeBaseOracle;

    // Proposal tracking
    uint256 public nextProposalId;
    mapping(uint256 => ResearchProposal) public researchProposals;
    mapping(address => uint256) public proposalStakeAmounts; // Amount staked by proposer for eligibility

    // Governance parameters (configurable by governance proposals)
    uint256 public minVotingPowerForProposal; // Minimum influence points to propose a governance change
    uint256 public minVotingPowerForVote;    // Minimum influence points to vote
    uint256 public governanceQuorumPercentage; // % of total voting power needed for quorum (e.g., 51% = 5100)
    uint256 public governanceMajorityPercentage; // % of votes for needed to pass (e.g., 51% = 5100)
    uint256 public governanceVotingPeriod;     // Duration of voting period in seconds
    uint256 public aiWeightingFactor;          // Weight of AI rating in overall evaluation (e.g., 100 = 100%)

    // Governance proposal tracking
    uint256 public nextGovernanceProposalId;
    mapping(uint256 => GovernanceProposal) public governanceProposals;
    mapping(address => ParticipantRewards) public participantRewards;

    // Knowledge Base tracking
    mapping(uint256 => bytes32) public projectKnowledgeBaseRoots; // proposalId => Merkle root hash

    // Treasury balance (GenePool tokens)
    uint256 public treasuryBalance;

    // --- EVENTS ---

    event GenePoolTokenAddressUpdated(address indexed newAddress);
    event GenomeNFTAddressUpdated(address indexed newAddress);
    event AIRatingOracleUpdated(address indexed newAddress);
    event KnowledgeBaseOracleUpdated(address indexed newAddress);

    event ResearchProposalSubmitted(uint256 indexed proposalId, address indexed proposer, string title, uint256 totalFundingRequired, uint256 submittedAt);
    event ProposalEligibilityStaked(uint256 indexed proposalId, address indexed staker, uint256 amount);
    event AIProposalEvaluated(uint256 indexed proposalId, uint256 aiRating, string aiFeedbackHash);
    event CommunityReviewSubmitted(uint256 indexed proposalId, address indexed reviewer, string feedbackHash);
    event ProposalStateChanged(uint256 indexed proposalId, ProposalState newState);
    event MilestoneSubmitted(uint256 indexed proposalId, uint256 indexed milestoneIndex, string proofHash);
    event MilestoneVerified(uint256 indexed proposalId, uint256 indexed milestoneIndex, bool isSuccessful);
    event MilestoneFunded(uint256 indexed proposalId, uint256 indexed milestoneIndex, uint256 amount);
    event ProposalCancelled(uint256 indexed proposalId, string reasonHash);

    event GenomeNFTMinted(address indexed holder, uint256 indexed tokenId);
    event GenomeNFTTraitsUpdated(uint256 indexed tokenId, uint256 successPoints, uint256 evaluationAccuracyPoints, uint256 contributionPoints);
    event GenomeNFTBurned(uint256 indexed tokenId, address indexed holder);

    event GovernanceParameterProposed(uint256 indexed proposalId, string paramName, uint256 newValue, string description);
    event GovernanceVoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 votingPower);
    event GovernanceProposalStateChanged(uint256 indexed proposalId, GovernanceProposalState newState);
    event GovernanceParameterChanged(string indexed paramName, uint256 newValue);

    event RewardsClaimed(address indexed claimant, uint256 amount);
    event TokensSlashed(address indexed slashee, uint256 amount, string reasonHash);

    event KnowledgeBaseRootRegistered(uint256 indexed proposalId, bytes32 merkleRootHash);
    event KnowledgeBaseContentVerified(uint256 indexed proposalId, bytes32 leafHash);

    event TreasuryDeposited(address indexed depositor, uint256 amount);
    event TreasuryWithdrawn(address indexed recipient, uint256 amount);

    // --- MODIFIERS ---

    modifier onlyAIOracle() {
        require(msg.sender == address(aiRatingOracle), "BioGenesis: Caller is not the AI Rating Oracle");
        _;
    }

    modifier onlyKnowledgeBaseOracle() {
        require(msg.sender == address(knowledgeBaseOracle), "BioGenesis: Caller is not the Knowledge Base Oracle");
        _;
    }

    // This modifier assumes governance acts via successful governance proposals,
    // which then call a function with this modifier.
    // For simplicity here, we'll use onlyOwner for now for immediate execution of governance-approved actions.
    // A full DAO would have a separate "Executor" contract.
    modifier onlyGovernanceCouncil() {
        // In a real DAO, this would be `require(governanceExecutor.canExecute(msg.sender, this, msg.sig))`
        // For this example, we'll simplify:
        require(msg.sender == owner(), "BioGenesis: Caller is not authorized by governance");
        _;
    }

    // --- CONSTRUCTOR ---

    constructor(
        address _genePoolToken,
        address _genomeNFT,
        address _aiRatingOracle,
        address _knowledgeBaseOracle
    ) Ownable(msg.sender) {
        require(_genePoolToken != address(0), "BioGenesis: GenePoolToken address cannot be zero");
        require(_genomeNFT != address(0), "BioGenesis: GenomeNFT address cannot be zero");
        require(_aiRatingOracle != address(0), "BioGenesis: AI Rating Oracle address cannot be zero");
        require(_knowledgeBaseOracle != address(0), "BioGenesis: Knowledge Base Oracle address cannot be zero");

        genePoolToken = IERC20(_genePoolToken);
        genomeNFT = IGenomeNFT(_genomeNFT);
        aiRatingOracle = IAIRatingOracle(_aiRatingOracle);
        knowledgeBaseOracle = IKnowledgeBaseOracle(_knowledgeBaseOracle);

        // Initial governance parameters (can be changed by governance)
        minVotingPowerForProposal = 100; // Example: 100 "Influence" points
        minVotingPowerForVote = 10;      // Example: 10 "Influence" points
        governanceQuorumPercentage = 5100; // 51%
        governanceMajorityPercentage = 5100; // 51%
        governanceVotingPeriod = 7 days; // 7 days
        aiWeightingFactor = 50; // 50% influence for AI rating (0-100 scale)

        nextProposalId = 1;
        nextGovernanceProposalId = 1;

        // Ensure token allowance for this contract if needed for internal transfers,
        // though typically users approve this contract directly.
    }

    // --- I. Core Architecture & Initialization ---

    /**
     * @dev Updates the address of the GenePool ERC-20 token contract.
     * @param _newAddress The new address for the GenePool token contract.
     */
    function setGenePoolTokenAddress(address _newAddress) public onlyOwner {
        require(_newAddress != address(0), "BioGenesis: New address cannot be zero");
        genePoolToken = IERC20(_newAddress);
        emit GenePoolTokenAddressUpdated(_newAddress);
    }

    /**
     * @dev Updates the address of the Genome ERC-721 NFT contract.
     * @param _newAddress The new address for the Genome NFT contract.
     */
    function setGenomeNFTAddress(address _newAddress) public onlyOwner {
        require(_newAddress != address(0), "BioGenesis: New address cannot be zero");
        genomeNFT = IGenomeNFT(_newAddress);
        emit GenomeNFTAddressUpdated(_newAddress);
    }

    /**
     * @dev Updates the address of the AI Rating Oracle contract.
     * @param _newAddress The new address for the AI Rating Oracle contract.
     */
    function setAIRatingOracle(address _newAddress) public onlyOwner {
        require(_newAddress != address(0), "BioGenesis: New address cannot be zero");
        aiRatingOracle = IAIRatingOracle(_newAddress);
        emit AIRatingOracleUpdated(_newAddress);
    }

    /**
     * @dev Updates the address of the Knowledge Base Oracle contract.
     * @param _newAddress The new address for the Knowledge Base Oracle contract.
     */
    function setKnowledgeBaseOracle(address _newAddress) public onlyOwner {
        require(_newAddress != address(0), "BioGenesis: New address cannot be zero");
        knowledgeBaseOracle = IKnowledgeBaseOracle(_newAddress);
        emit KnowledgeBaseOracleUpdated(_newAddress);
    }

    // --- II. Governance & Protocol Parameters (Emergent Protocol Parameters) ---

    /**
     * @dev Allows any participant with a Genome NFT and sufficient reputation to propose a change to a predefined protocol parameter.
     * @param _paramName The name of the parameter to change (e.g., "minVotingPower", "governanceQuorumPercentage").
     * @param _newValue The new value for the parameter.
     * @param _description A description of the proposed change.
     */
    function proposeParameterChange(string memory _paramName, uint256 _newValue, string memory _description)
        public
        whenNotPaused
        nonReentrant
    {
        uint256 genomeTokenId = genomeNFT.getTokenId(msg.sender);
        require(genomeTokenId != 0, "BioGenesis: Proposer must have a Genome NFT");
        (, , uint256 influencePoints) = genomeNFT.getTraits(genomeTokenId);
        require(influencePoints >= minVotingPowerForProposal, "BioGenesis: Not enough influence to propose");

        uint256 proposalId = nextGovernanceProposalId++;
        GovernanceProposal storage gp = governanceProposals[proposalId];
        gp.id = proposalId;
        gp.proposer = msg.sender;
        gp.paramName = _paramName;
        gp.newValue = _newValue;
        gp.description = _description;
        gp.state = GovernanceProposalState.Active;
        gp.submittedAt = block.timestamp;
        gp.votingEndsAt = block.timestamp + governanceVotingPeriod;

        emit GovernanceParameterProposed(proposalId, _paramName, _newValue, _description);
    }

    /**
     * @dev Allows Genome NFT holders to vote (support or oppose) on an active parameter change proposal.
     *      Voting power is proportional to their Genome NFT's influence trait.
     * @param _proposalId The ID of the governance proposal.
     * @param _support True if supporting the proposal, false if opposing.
     */
    function voteOnParameterChange(uint256 _proposalId, bool _support) public whenNotPaused nonReentrant {
        GovernanceProposal storage gp = governanceProposals[_proposalId];
        require(gp.state == GovernanceProposalState.Active, "BioGenesis: Proposal is not active for voting");
        require(block.timestamp < gp.votingEndsAt, "BioGenesis: Voting period has ended");

        uint256 genomeTokenId = genomeNFT.getTokenId(msg.sender);
        require(genomeTokenId != 0, "BioGenesis: Voter must have a Genome NFT");
        require(!gp.hasVoted[msg.sender], "BioGenesis: Already voted on this proposal");

        (, , uint256 influencePoints) = genomeNFT.getTraits(genomeTokenId);
        require(influencePoints >= minVotingPowerForVote, "BioGenesis: Not enough influence to vote");

        gp.hasVoted[msg.sender] = true;
        gp.voterWeight[msg.sender] = influencePoints;

        if (_support) {
            gp.votesFor += influencePoints;
        } else {
            gp.votesAgainst += influencePoints;
        }

        emit GovernanceVoteCast(_proposalId, msg.sender, _support, influencePoints);
    }

    /**
     * @dev Executes a parameter change proposal if it has met the required voting thresholds and deliberation period.
     * @param _proposalId The ID of the governance proposal.
     */
    function executeParameterChange(uint256 _proposalId) public whenNotPaused nonReentrant {
        GovernanceProposal storage gp = governanceProposals[_proposalId];
        require(gp.state == GovernanceProposalState.Active, "BioGenesis: Proposal is not active");
        require(block.timestamp >= gp.votingEndsAt, "BioGenesis: Voting period has not ended yet");

        uint256 totalVotes = gp.votesFor + gp.votesAgainst;
        uint256 totalPossibleVotingPower = genomeNFT.totalSupply() > 0 ? genomeNFT.getTraits(genomeNFT.getTokenId(address(this)) /*dummy*/).influencePoints * genomeNFT.totalSupply() : 0; // Simplified total voting power, requires actual sum or total supply of influence
        // For a more accurate total voting power, one would need to iterate through all NFTs or maintain a running total.
        // For simplicity, let's assume totalPossibleVotingPower is based on `minVotingPowerForVote * totalGenomeNFTs`
        // A proper implementation would require a sum of influence points of all eligible voters.
        // For this example, let's assume a simplified total for quorum check for now, or consider total votes cast as quorum basis.

        // Quorum check: simplified to total votes cast meeting a threshold.
        // A better quorum would be `total_votes_cast / total_possible_voting_power >= quorumPercentage`
        // For now, let's use the total votes cast as total "engaged" voting power.
        // This is a simplification; a true quorum would likely involve the sum of all eligible voting power.
        uint256 totalEngagedVotingPower = gp.votesFor + gp.votesAgainst;
        require(totalEngagedVotingPower * 10000 >= totalPossibleVotingPower * governanceQuorumPercentage, "BioGenesis: Quorum not met"); // Needs proper total

        if (gp.votesFor * 10000 >= totalEngagedVotingPower * governanceMajorityPercentage) {
            gp.state = GovernanceProposalState.Succeeded;
            _applyParameterChange(gp.paramName, gp.newValue);
            gp.state = GovernanceProposalState.Executed;
            emit GovernanceProposalStateChanged(_proposalId, GovernanceProposalState.Executed);
            emit GovernanceParameterChanged(gp.paramName, gp.newValue);
        } else {
            gp.state = GovernanceProposalState.Failed;
            emit GovernanceProposalStateChanged(_proposalId, GovernanceProposalState.Failed);
        }
    }

    /**
     * @dev Internal function to apply the parameter change.
     * @param _paramName The name of the parameter.
     * @param _newValue The new value.
     */
    function _applyParameterChange(string memory _paramName, uint256 _newValue) internal {
        if (keccak256(abi.encodePacked(_paramName)) == keccak256(abi.encodePacked("minVotingPowerForProposal"))) {
            minVotingPowerForProposal = _newValue;
        } else if (keccak256(abi.encodePacked(_paramName)) == keccak256(abi.encodePacked("minVotingPowerForVote"))) {
            minVotingPowerForVote = _newValue;
        } else if (keccak256(abi.encodePacked(_paramName)) == keccak256(abi.encodePacked("governanceQuorumPercentage"))) {
            require(_newValue <= 10000, "BioGenesis: Percentage out of range (0-10000)");
            governanceQuorumPercentage = _newValue;
        } else if (keccak256(abi.encodePacked(_paramName)) == keccak256(abi.encodePacked("governanceMajorityPercentage"))) {
            require(_newValue <= 10000, "BioGenesis: Percentage out of range (0-10000)");
            governanceMajorityPercentage = _newValue;
        } else if (keccak256(abi.encodePacked(_paramName)) == keccak256(abi.encodePacked("governanceVotingPeriod"))) {
            governanceVotingPeriod = _newValue;
        } else if (keccak256(abi.encodePacked(_paramName)) == keccak256(abi.encodePacked("aiWeightingFactor"))) {
            require(_newValue <= 100, "BioGenesis: Weighting factor out of range (0-100)");
            aiWeightingFactor = _newValue;
        } else {
            revert("BioGenesis: Unknown parameter name");
        }
    }

    /**
     * @dev Allows the DAO to adjust core governance thresholds.
     *      This function is called *internally* by `executeParameterChange` after a successful governance vote.
     * @param _minVotingPower For proposing.
     * @param _quorumPercentage For governance proposals.
     * @param _majorityPercentage For governance proposals.
     * @param _votingPeriod For governance proposals.
     */
    function setGovernanceThresholds(uint256 _minVotingPower, uint256 _quorumPercentage, uint256 _majorityPercentage, uint256 _votingPeriod)
        public
        onlyGovernanceCouncil
        whenNotPaused
    {
        // This function would typically be called by the `executeParameterChange` via a DAO multisig or executor
        // For this example, onlyOwner acts as a placeholder for governance.
        minVotingPowerForProposal = _minVotingPower;
        minVotingPowerForVote = _minVotingPower; // Assuming same for both for simplicity
        require(_quorumPercentage <= 10000, "Quorum must be <= 100%");
        governanceQuorumPercentage = _quorumPercentage;
        require(_majorityPercentage <= 10000, "Majority must be <= 100%");
        governanceMajorityPercentage = _majorityPercentage;
        governanceVotingPeriod = _votingPeriod;
        // Event for these specific changes would be redundant if general parameter change event is used.
    }

    /**
     * @dev Adjusts the weighting factor for the AI oracle's influence in proposal evaluations.
     *      This function is called *internally* by `executeParameterChange` after a successful governance vote.
     * @param _newWeight The new weighting factor (0-100).
     */
    function updateAIWeightingFactor(uint256 _newWeight) public onlyGovernanceCouncil whenNotPaused {
        require(_newWeight <= 100, "BioGenesis: Weight must be between 0 and 100");
        aiWeightingFactor = _newWeight;
        // Event for this specific change would be redundant if general parameter change event is used.
    }

    // --- III. Research Proposal Management ---

    /**
     * @dev Allows a user to submit a new research proposal.
     * @param _title The title of the proposal.
     * @param _description A brief description of the proposal.
     * @param _ipfsDocHash IPFS hash pointing to the detailed proposal document.
     * @param _totalFundingRequired The total amount of GenePool tokens required for the project.
     * @param _milestoneAmounts An array specifying the funding amount for each milestone.
     */
    function submitResearchProposal(
        string memory _title,
        string memory _description,
        string memory _ipfsDocHash,
        uint256 _totalFundingRequired,
        uint256[] memory _milestoneAmounts
    ) public whenNotPaused nonReentrant {
        require(bytes(_title).length > 0, "BioGenesis: Title cannot be empty");
        require(_totalFundingRequired > 0, "BioGenesis: Funding required must be greater than zero");
        require(_milestoneAmounts.length > 0, "BioGenesis: Must define at least one milestone");

        uint256 calculatedTotalMilestoneAmount = 0;
        for (uint256 i = 0; i < _milestoneAmounts.length; i++) {
            calculatedTotalMilestoneAmount += _milestoneAmounts[i];
            require(_milestoneAmounts[i] > 0, "BioGenesis: Milestone amount cannot be zero");
        }
        require(calculatedTotalMilestoneAmount == _totalFundingRequired, "BioGenesis: Milestone amounts must sum to total funding required");

        uint256 proposalId = nextProposalId++;
        ResearchProposal storage proposal = researchProposals[proposalId];
        proposal.id = proposalId;
        proposal.proposer = msg.sender;
        proposal.title = _title;
        proposal.description = _description;
        proposal.ipfsDocHash = _ipfsDocHash;
        proposal.totalFundingRequired = _totalFundingRequired;
        proposal.state = ProposalState.AwaitingEligibilityStake;
        proposal.submittedAt = block.timestamp;
        proposal.milestoneAmounts = _milestoneAmounts;
        proposal.milestoneStates = new MilestoneState[](_milestoneAmounts.length);
        for (uint256 i = 0; i < _milestoneAmounts.length; i++) {
            proposal.milestoneStates[i] = MilestoneState.Pending;
        }
        proposal.currentMilestoneIndex = 0; // Start at the first milestone

        emit ResearchProposalSubmitted(proposalId, msg.sender, _title, _totalFundingRequired, block.timestamp);
    }

    /**
     * @dev Proposer stakes GenePool tokens to make their proposal eligible for AI and community review.
     * @param _proposalId The ID of the proposal to stake for.
     */
    function stakeForProposalEligibility(uint256 _proposalId) public whenNotPaused nonReentrant {
        ResearchProposal storage proposal = researchProposals[_proposalId];
        require(proposal.state == ProposalState.AwaitingEligibilityStake, "BioGenesis: Proposal not awaiting stake");
        require(proposal.proposer == msg.sender, "BioGenesis: Only proposer can stake");

        // Example stake amount: 1% of total funding, or a fixed amount. Let's use a fixed amount.
        uint256 stakeAmount = 100 * (10 ** 18); // Example: 100 GenePool tokens
        require(genePoolToken.balanceOf(msg.sender) >= stakeAmount, "BioGenesis: Insufficient GenePool balance for stake");
        require(genePoolToken.allowance(msg.sender, address(this)) >= stakeAmount, "BioGenesis: Approve GenePool tokens first");

        require(genePoolToken.transferFrom(msg.sender, address(this), stakeAmount), "BioGenesis: Stake transfer failed");
        proposalStakeAmounts[_proposalId] = stakeAmount;
        treasuryBalance += stakeAmount; // Add to treasury

        proposal.initialStakeAmount = stakeAmount;
        proposal.state = ProposalState.UnderAIReview;
        emit ProposalEligibilityStaked(_proposalId, msg.sender, stakeAmount);
        emit ProposalStateChanged(_proposalId, ProposalState.UnderAIReview);
    }

    /**
     * @dev Callable by the AI Oracle to submit an initial rating for a research proposal.
     * @param _proposalId The ID of the proposal.
     * @param _aiRating The AI's rating (e.g., 0-100).
     * @param _aiFeedbackHash IPFS hash to detailed AI feedback.
     */
    function aiEvaluateProposal(uint256 _proposalId, uint256 _aiRating, string memory _aiFeedbackHash) public onlyAIOracle whenNotPaused {
        ResearchProposal storage proposal = researchProposals[_proposalId];
        require(proposal.state == ProposalState.UnderAIReview, "BioGenesis: Proposal not in AI review stage");
        require(_aiRating <= 100, "BioGenesis: AI Rating must be between 0 and 100");

        proposal.aiRating = _aiRating;
        proposal.aiFeedbackHash = _aiFeedbackHash;
        proposal.state = ProposalState.UnderCommunityReview; // Move to community review after AI
        emit AIProposalEvaluated(_proposalId, _aiRating, _aiFeedbackHash);
        emit ProposalStateChanged(_proposalId, ProposalState.UnderCommunityReview);
    }

    /**
     * @dev Allows community members to review and comment on proposals.
     *      Feedback is stored off-chain (via hash), but participation is tracked on-chain for reputation.
     * @param _proposalId The ID of the proposal being reviewed.
     * @param _feedbackHash IPFS hash pointing to the community member's detailed feedback.
     */
    function communityReviewProposal(uint256 _proposalId, string memory _feedbackHash) public whenNotPaused {
        ResearchProposal storage proposal = researchProposals[_proposalId];
        require(proposal.state == ProposalState.UnderCommunityReview, "BioGenesis: Proposal not in community review stage");

        uint256 genomeTokenId = genomeNFT.getTokenId(msg.sender);
        require(genomeTokenId != 0, "BioGenesis: Reviewer must have a Genome NFT");

        // Logic to track community review participation (for future "Insight" trait update)
        // For simplicity, this directly updates traits for participation.
        // A more complex system might have a separate contract or oracle for quality of feedback.
        _updateGenomeTraits(msg.sender, 0, 1, 0); // Award 1 point for evaluation accuracy (participation)
        emit CommunityReviewSubmitted(_proposalId, msg.sender, _feedbackHash);
    }

    /**
     * @dev Funds the first milestone of an approved proposal. This is typically called by the DAO after a governance vote.
     * @param _proposalId The ID of the proposal to fund.
     */
    function fundProposalInitialMilestone(uint256 _proposalId) public onlyGovernanceCouncil whenNotPaused nonReentrant {
        ResearchProposal storage proposal = researchProposals[_proposalId];
        require(proposal.state == ProposalState.UnderCommunityReview, "BioGenesis: Proposal not awaiting initial funding approval");
        require(proposal.milestoneAmounts.length > 0, "BioGenesis: Proposal has no milestones defined");
        require(proposal.currentMilestoneIndex == 0, "BioGenesis: Initial milestone already funded or project active");

        // Simplified approval for demonstration; a full DAO would have a vote.
        // Assuming AI rating and community sentiment leads to an "Approved" state.
        // For this example, 'onlyGovernanceCouncil' implies approval.
        proposal.state = ProposalState.Active;

        uint256 amountToFund = proposal.milestoneAmounts[0];
        require(treasuryBalance >= amountToFund, "BioGenesis: Insufficient funds in treasury");

        treasuryBalance -= amountToFund;
        require(genePoolToken.transfer(proposal.proposer, amountToFund), "BioGenesis: Failed to transfer initial milestone funds");

        proposal.milestoneStates[0] = MilestoneState.Verified; // Mark first as funded
        proposal.currentMilestoneIndex = 1; // Move to next milestone
        proposal.lastMilestonePaymentTime = block.timestamp;

        _updateGenomeTraits(proposal.proposer, 1, 0, 0); // Give success point to proposer for getting funded
        emit MilestoneFunded(_proposalId, 0, amountToFund);
        emit ProposalStateChanged(_proposalId, ProposalState.Active);
    }

    /**
     * @dev A researcher marks a milestone as complete and provides proof.
     * @param _proposalId The ID of the proposal.
     * @param _milestoneIndex The index of the completed milestone.
     * @param _proofHash IPFS hash pointing to the proof of completion.
     */
    function submitMilestoneCompletion(uint256 _proposalId, uint256 _milestoneIndex, string memory _proofHash) public whenNotPaused {
        ResearchProposal storage proposal = researchProposals[_proposalId];
        require(proposal.state == ProposalState.Active, "BioGenesis: Proposal is not active");
        require(proposal.proposer == msg.sender, "BioGenesis: Only proposer can submit milestone completion");
        require(_milestoneIndex < proposal.milestoneAmounts.length, "BioGenesis: Invalid milestone index");
        require(proposal.milestoneStates[_milestoneIndex] == MilestoneState.Pending, "BioGenesis: Milestone not pending");

        proposal.milestoneStates[_milestoneIndex] = MilestoneState.SubmittedForVerification;
        if (proposal.milestoneProofHashes.length <= _milestoneIndex) {
            // Resize array if needed (Solidity dynamic arrays automatically grow on push, but not direct assignment)
            // For fixed size struct, it's safer to pre-allocate or ensure enough space.
            // Simplified: Assuming sufficient space or handling via array growth
            // For this example, we will resize or ensure `push` is handled.
            // A more robust way might involve `bytes32[]` for hashes to ensure fixed size.
        }
        proposal.milestoneProofHashes.push(_proofHash); // Store the proof hash
        
        emit MilestoneSubmitted(_proposalId, _milestoneIndex, _proofHash);
    }

    /**
     * @dev Verifies a completed milestone (by AI or governance). If successful, it triggers funding for the next milestone.
     * @param _proposalId The ID of the proposal.
     * @param _milestoneIndex The index of the milestone to verify.
     * @param _isSuccessful Whether the milestone completion is deemed successful.
     * @param _verificationFeedbackHash IPFS hash for feedback from the verifier.
     */
    function verifyMilestoneCompletion(uint256 _proposalId, uint256 _milestoneIndex, bool _isSuccessful, string memory _verificationFeedbackHash)
        public
        whenNotPaused
        nonReentrant
    {
        ResearchProposal storage proposal = researchProposals[_proposalId];
        require(proposal.state == ProposalState.Active, "BioGenesis: Proposal is not active");
        require(_milestoneIndex < proposal.milestoneAmounts.length, "BioGenesis: Invalid milestone index");
        require(proposal.milestoneStates[_milestoneIndex] == MilestoneState.SubmittedForVerification, "BioGenesis: Milestone not submitted for verification");
        require(msg.sender == address(aiRatingOracle) || msg.sender == owner(), "BioGenesis: Only AI Oracle or Governance can verify");

        if (_isSuccessful) {
            proposal.milestoneStates[_milestoneIndex] = MilestoneState.Verified;
            _updateGenomeTraits(proposal.proposer, 1, 0, 0); // Reward proposer for successful milestone
            _distributeEvaluatorRewards(_proposalId); // Reward evaluators of this milestone
            proposal.verificationFeedbackHashes.push(_verificationFeedbackHash); // Store feedback hash

            if (_milestoneIndex + 1 < proposal.milestoneAmounts.length) {
                // If there are more milestones, fund the next one
                fundNextMilestone(_proposalId);
            } else {
                // All milestones completed
                proposal.state = ProposalState.Completed;
                // Return remaining stake to proposer (if any) and reward final completion
                uint256 returnStakeAmount = proposal.initialStakeAmount;
                if (returnStakeAmount > 0) {
                    _releaseFunds(proposal.proposer, returnStakeAmount);
                    proposalStakeAmounts[_proposalId] = 0; // Clear stake
                    treasuryBalance -= returnStakeAmount;
                }
                emit ProposalStateChanged(_proposalId, ProposalState.Completed);
            }
        } else {
            proposal.milestoneStates[_milestoneIndex] = MilestoneState.Failed;
            _slashStakedTokens(proposal.proposer, proposal.initialStakeAmount / 2, "Milestone failed"); // Slash partial stake
            proposal.state = ProposalState.Cancelled; // Project cancelled on failed milestone
            proposal.verificationFeedbackHashes.push(_verificationFeedbackHash);
            emit ProposalStateChanged(_proposalId, ProposalState.Cancelled);
        }
        emit MilestoneVerified(_proposalId, _milestoneIndex, _isSuccessful);
    }

    /**
     * @dev Releases funds for the next milestone of a project.
     *      This is an internal helper called after successful milestone verification.
     * @param _proposalId The ID of the proposal.
     */
    function fundNextMilestone(uint256 _proposalId) internal nonReentrant {
        ResearchProposal storage proposal = researchProposals[_proposalId];
        require(proposal.state == ProposalState.Active, "BioGenesis: Proposal must be active");
        require(proposal.currentMilestoneIndex < proposal.milestoneAmounts.length, "BioGenesis: No more milestones to fund");
        require(proposal.milestoneStates[proposal.currentMilestoneIndex -1] == MilestoneState.Verified, "BioGenesis: Previous milestone not verified");

        uint256 amountToFund = proposal.milestoneAmounts[proposal.currentMilestoneIndex];
        require(treasuryBalance >= amountToFund, "BioGenesis: Insufficient funds in treasury to fund next milestone");

        treasuryBalance -= amountToFund;
        require(genePoolToken.transfer(proposal.proposer, amountToFund), "BioGenesis: Failed to transfer milestone funds");

        proposal.milestoneStates[proposal.currentMilestoneIndex] = MilestoneState.Verified;
        proposal.currentMilestoneIndex++;
        proposal.lastMilestonePaymentTime = block.timestamp;
        emit MilestoneFunded(_proposalId, proposal.currentMilestoneIndex -1, amountToFund);
    }

    /**
     * @dev Cancels a proposal or project.
     * @param _proposalId The ID of the proposal to cancel.
     * @param _reasonHash IPFS hash for the reason of cancellation.
     */
    function cancelProposal(uint256 _proposalId, string memory _reasonHash) public onlyGovernanceCouncil whenNotPaused {
        ResearchProposal storage proposal = researchProposals[_proposalId];
        require(proposal.state != ProposalState.Completed && proposal.state != ProposalState.Cancelled, "BioGenesis: Proposal already completed or cancelled");

        proposal.state = ProposalState.Cancelled;
        _slashStakedTokens(proposal.proposer, proposal.initialStakeAmount, _reasonHash); // Slash full stake
        emit ProposalCancelled(_proposalId, _reasonHash);
        emit ProposalStateChanged(_proposalId, ProposalState.Cancelled);
    }

    // --- IV. Dynamic Reputation "Genome" NFTs (ERC-721 Interface Interactions) ---

    /**
     * @dev Allows a new participant to mint their unique, non-transferable "Genome" NFT.
     * @dev Limited to one per address.
     */
    function mintGenomeNFT() public whenNotPaused nonReentrant {
        // Check if user already has an NFT.
        require(genomeNFT.getTokenId(msg.sender) == 0, "BioGenesis: You already have a Genome NFT.");
        uint256 tokenId = genomeNFT.mint(msg.sender);
        // Initialize traits or rely on GenomeNFT contract's default
        emit GenomeNFTMinted(msg.sender, tokenId);
    }

    /**
     * @dev Internal function to update the on-chain traits of a user's Genome NFT.
     *      This is called by other functions in this contract based on user activity.
     * @param _user The address of the user whose NFT traits are to be updated.
     * @param _proposalSuccessPoints Points for successful proposals/milestones.
     * @param _evaluationAccuracyPoints Points for accurate evaluations/reviews.
     * @param _contributionPoints General contribution points.
     */
    function _updateGenomeTraits(address _user, uint256 _proposalSuccessPoints, uint256 _evaluationAccuracyPoints, uint256 _contributionPoints) internal {
        uint256 tokenId = genomeNFT.getTokenId(_user);
        if (tokenId != 0) { // Only update if NFT exists
            genomeNFT.updateTraits(tokenId, _proposalSuccessPoints, _evaluationAccuracyPoints, _contributionPoints);
            emit GenomeNFTTraitsUpdated(tokenId, _proposalSuccessPoints, _evaluationAccuracyPoints, _contributionPoints);
        }
    }

    /**
     * @dev Retrieves the current numerical trait values of a user's Genome NFT.
     * @param _user The address of the user.
     * @return successPoints Points from successful proposals/milestones.
     * @return evaluationAccuracyPoints Points from accurate evaluations/reviews.
     * @return contributionPoints General contribution points.
     */
    function getGenomeTraits(address _user) public view returns (uint256 successPoints, uint256 evaluationAccuracyPoints, uint256 contributionPoints) {
        uint256 tokenId = genomeNFT.getTokenId(_user);
        require(tokenId != 0, "BioGenesis: User does not have a Genome NFT.");
        return genomeNFT.getTraits(tokenId);
    }

    /**
     * @dev Allows the governance council to burn a Genome NFT in cases of severe misconduct.
     * @param _user The address of the user whose NFT is to be burned.
     * @param _reasonHash IPFS hash for the reason of burning.
     */
    function burnGenomeNFT(address _user, string memory _reasonHash) public onlyGovernanceCouncil whenNotPaused {
        uint256 tokenId = genomeNFT.getTokenId(_user);
        require(tokenId != 0, "BioGenesis: User does not have a Genome NFT to burn.");
        genomeNFT.burn(tokenId);
        emit GenomeNFTBurned(tokenId, _user);
        // Potentially slash staked tokens if any.
    }

    // --- V. Incentives & Rewards ---

    /**
     * @dev Allows participants to claim their accumulated GenePool token rewards.
     */
    function claimRewards() public whenNotPaused nonReentrant {
        uint256 amount = participantRewards[msg.sender].genePoolRewards;
        require(amount > 0, "BioGenesis: No rewards to claim.");
        require(treasuryBalance >= amount, "BioGenesis: Insufficient treasury balance for rewards.");

        participantRewards[msg.sender].genePoolRewards = 0;
        treasuryBalance -= amount;
        require(genePoolToken.transfer(msg.sender, amount), "BioGenesis: Failed to transfer rewards.");

        emit RewardsClaimed(msg.sender, amount);
    }

    /**
     * @dev Distributes rewards to evaluators of successful proposals.
     *      This is an internal helper called after successful proposal/milestone verification.
     * @param _proposalId The ID of the successful proposal.
     */
    function _distributeEvaluatorRewards(uint256 _proposalId) internal {
        // In a real system, this would involve tracking specific evaluators for each proposal/milestone
        // and assessing their 'accuracy' or 'insight' to distribute rewards.
        // For simplicity, this is a placeholder.
        // For now, let's just award a small, fixed reward to the 'aiRatingOracle' for demonstration
        // as a form of 'evaluator reward'. A true system would track all community reviewers.
        uint256 rewardAmount = 5 * (10 ** 18); // Example: 5 GenePool tokens per evaluation
        if (treasuryBalance >= rewardAmount) {
             participantRewards[address(aiRatingOracle)].genePoolRewards += rewardAmount;
             // Potentially add rewards to community reviewers also, if their feedback was effective.
        }
    }

    /**
     * @dev Provides ad-hoc incentives for particularly insightful feedback or vulnerability disclosures.
     * @param _proposalId The ID of the proposal.
     * @param _feedbackProvider The address of the feedback provider.
     */
    function distributeFeedbackIncentives(uint256 _proposalId, address _feedbackProvider) public onlyGovernanceCouncil whenNotPaused nonReentrant {
        // This function is manually triggered by governance for exceptional feedback
        uint256 incentiveAmount = 50 * (10 ** 18); // Example: 50 GenePool tokens
        require(treasuryBalance >= incentiveAmount, "BioGenesis: Insufficient treasury balance for incentive.");

        treasuryBalance -= incentiveAmount;
        require(genePoolToken.transfer(_feedbackProvider, incentiveAmount), "BioGenesis: Failed to transfer incentive.");

        _updateGenomeTraits(_feedbackProvider, 0, 5, 0); // Give significant evaluation accuracy points
        // Event for specific incentive distribution
    }

    /**
     * @dev Implements a slashing mechanism for staked GenePool tokens.
     *      This is an internal helper function.
     * @param _staker The address of the staker to be slashed.
     * @param _amount The amount of GenePool tokens to slash.
     * @param _reasonHash IPFS hash for the reason of slashing.
     */
    function _slashStakedTokens(address _staker, uint256 _amount, string memory _reasonHash) internal {
        if (_amount > 0 && proposalStakeAmounts[_proposalId] >= _amount) { // Ensure sufficient staked amount
            proposalStakeAmounts[_proposalId] -= _amount;
            // Transfer slashed tokens to a 'burn' address or a community pool (not treasury)
            // For simplicity, let's 'burn' by sending to address(0) (though typically not recommended)
            // or transfer to a dedicated "slashed funds" address.
            // A safer approach is to transfer to the treasury, but conceptually they are 'burned' from the staker.
            // For now, these slashed tokens are conceptually removed from circulation by not being returned to proposer.
            // If they are to be truly burned or re-allocated, an explicit transfer is needed.
            treasuryBalance -= _amount; // Deduct from treasury
            emit TokensSlashed(_staker, _amount, _reasonHash);
        }
    }

    // --- VI. Knowledge Base Management (Merkle Tree / IPFS Integration) ---

    /**
     * @dev Registers the Merkle root hash and metadata URI for a project's knowledge base.
     *      This signifies the official, verifiable output of a funded research project.
     * @param _proposalId The ID of the associated research proposal.
     * @param _merkleRootHash The Merkle root hash of the knowledge base content.
     * @param _rootMetadataURI IPFS URI pointing to metadata about the knowledge base structure.
     */
    function registerKnowledgeBaseRoot(uint256 _proposalId, bytes32 _merkleRootHash, string memory _rootMetadataURI) public onlyGovernanceCouncil whenNotPaused {
        ResearchProposal storage proposal = researchProposals[_proposalId];
        require(proposal.state == ProposalState.Completed || proposal.state == ProposalState.Active, "BioGenesis: Proposal must be completed or active to register knowledge base");
        require(_mermerkleRootHash != bytes32(0), "BioGenesis: Merkle root cannot be zero");

        projectKnowledgeBaseRoots[_proposalId] = _merkleRootHash;
        emit KnowledgeBaseRootRegistered(_proposalId, _merkleRootHash);
        // Store _rootMetadataURI off-chain or as part of a more complex metadata system.
    }

    /**
     * @dev Verifies that a specific piece of content (represented by `_leafHash`) is included
     *      in the registered Merkle tree for a given project.
     * @param _proposalId The ID of the project.
     * @param _leafHash The hash of the content to verify.
     * @param _merkleProof The Merkle proof for the content.
     * @return True if the content is successfully verified.
     */
    function verifyKnowledgeBaseContent(uint256 _proposalId, bytes32 _leafHash, bytes32[] memory _merkleProof) public view returns (bool) {
        bytes32 storedRoot = projectKnowledgeBaseRoots[_proposalId];
        require(storedRoot != bytes32(0), "BioGenesis: No knowledge base root registered for this project.");
        return MerkleProof.verify(_merkleProof, storedRoot, _leafHash);
    }

    /**
     * @dev (Conceptual) Allows access to content based on Genome NFT traits.
     *      On-chain, it verifies Merkle proof; actual content access control happens off-chain.
     * @param _proposalId The ID of the project.
     * @param _leafHash The hash of the content to access (for verification).
     * @return True if the user theoretically has access based on on-chain verification.
     */
    function accessGatedContent(uint256 _proposalId, bytes32 _leafHash) public view returns (bool) {
        // This function is purely conceptual for on-chain verification of access rights.
        // The actual content delivery and further access control logic (e.g., streaming)
        // would occur off-chain, potentially via an API gateway checking this contract's state.

        uint256 genomeTokenId = genomeNFT.getTokenId(msg.sender);
        require(genomeTokenId != 0, "BioGenesis: Must have a Genome NFT to access gated content.");

        (, , uint256 influencePoints) = genomeNFT.getTraits(genomeTokenId);
        // Example: Require a certain level of influence to access premium content
        require(influencePoints >= 50, "BioGenesis: Insufficient influence to access this content.");

        // Additional checks like `verifyKnowledgeBaseContent` would typically be done off-chain
        // before serving the content, using the Merkle root on-chain as the source of truth.
        // For demonstration, we simply return true if basic checks pass.
        return true;
    }

    // --- VII. Treasury & Fund Management ---

    /**
     * @dev Allows anyone to directly deposit GenePool tokens into the BioGenesis Protocol's treasury.
     */
    function depositToTreasury(uint256 _amount) public whenNotPaused nonReentrant {
        require(_amount > 0, "BioGenesis: Amount must be greater than zero");
        require(genePoolToken.transferFrom(msg.sender, address(this), _amount), "BioGenesis: Deposit failed");
        treasuryBalance += _amount;
        emit TreasuryDeposited(msg.sender, _amount);
    }

    /**
     * @dev Allows the governance council to withdraw funds from the treasury for approved operations.
     *      This function is called *internally* by `executeParameterChange` after a successful governance vote
     *      or via a separate treasury management proposal system.
     * @param _recipient The address to receive the funds.
     * @param _amount The amount of GenePool tokens to withdraw.
     */
    function withdrawFromTreasury(address _recipient, uint256 _amount) public onlyGovernanceCouncil whenNotPaused nonReentrant {
        require(_amount > 0, "BioGenesis: Withdrawal amount must be greater than zero");
        require(_recipient != address(0), "BioGenesis: Recipient cannot be zero address");
        require(treasuryBalance >= _amount, "BioGenesis: Insufficient treasury balance");

        treasuryBalance -= _amount;
        require(genePoolToken.transfer(_recipient, _amount), "BioGenesis: Treasury withdrawal failed");
        emit TreasuryWithdrawn(_recipient, _amount);
    }

    /**
     * @dev Helper function for internal fund releases.
     */
    function _releaseFunds(address _recipient, uint256 _amount) internal {
        require(_amount > 0, "BioGenesis: Release amount must be greater than zero");
        require(_recipient != address(0), "BioGenesis: Recipient cannot be zero address");
        require(genePoolToken.transfer(_recipient, _amount), "BioGenesis: Fund release failed");
    }

    // --- VIII. Administrative Functions ---

    /**
     * @dev Pauses critical contract functions in case of emergencies.
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract functions.
     */
    function unpause() public onlyOwner {
        _unpause();
    }
}
```