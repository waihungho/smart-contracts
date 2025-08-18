Okay, this is an exciting challenge! Creating a truly unique, advanced, and creative smart contract that doesn't duplicate existing open-source projects, while incorporating trendy concepts and having at least 20 functions, requires a novel approach.

I'll propose a concept called **"Aetheris Protocol"**. It's a decentralized scientific research and funding platform, enhanced by AI-assisted peer review, dynamic knowledge NFTs, and a sophisticated reputation system, governed by stakers.

---

### **Aetheris Protocol: Decentralized AI-Augmented Research & Knowledge Network**

**Outline:**

The Aetheris Protocol aims to revolutionize scientific research funding, peer review, and knowledge dissemination by integrating blockchain transparency, AI assistance, and decentralized governance. Researchers can propose projects, receive funding, and publish results, while the community (including AI Oracles) contributes to review and verification, earning reputation and rewards. Successful research is immortalized as Dynamic Knowledge NFTs that evolve with their real-world impact.

**Core Concepts:**

1.  **Decentralized Grant Funding:** A transparent, community-governed process for allocating funds to research proposals.
2.  **AI-Augmented Peer Review:** Integration with "AI Oracles" (simulated via trusted addresses) that provide initial analysis and verification of research proposals and results, complementing human review.
3.  **Dynamic Knowledge NFTs (K-NFTs):** ERC-721 tokens representing successful research outputs. These NFTs are dynamic, meaning their metadata can evolve based on the research's ongoing impact (e.g., citations, real-world application, external validation).
4.  **Reputation System:** Researchers, reviewers, and AI Oracles earn reputation scores based on the quality and impact of their contributions, influencing their future privileges and rewards.
5.  **Role-Based Staking:** Participants stake tokens to qualify for roles like Reviewer or AI Oracle, ensuring skin-in-the-game and accountability.
6.  **Dispute Resolution:** A mechanism for addressing disagreements over reviews, research validity, or misconduct, resolved by a governing body.
7.  **Adaptive Governance:** On-chain voting for protocol parameter changes, upgrades, and high-level decisions.

---

**Function Summary (29 Functions):**

**I. Core Protocol Management & Funding:**
1.  `constructor()`: Initializes the contract with basic roles and ERC-721 details.
2.  `depositFunds()`: Allows anyone to contribute funds to the research grant pool.
3.  `withdrawProtocolFees(address _to, uint256 _amount)`: Allows the protocol admin to withdraw accrued fees.
4.  `proposeProtocolParameterChange(bytes32 _parameterKey, uint256 _newValue)`: Initiates a governance proposal to change a protocol setting.
5.  `voteOnProtocolChange(uint256 _proposalId, bool _approve)`: Allows governors to vote on proposed protocol changes.
6.  `executeProtocolChange(uint256 _proposalId)`: Executes a passed governance proposal.

**II. Researcher & Research Lifecycle:**
7.  `registerResearcher(string _name, string _profileIpfsHash)`: Allows an address to register as a researcher.
8.  `updateResearcherProfile(string _newProfileIpfsHash)`: Allows a researcher to update their profile.
9.  `submitResearchProposal(string _title, string _ipfsHash, uint256 _requestedAmount)`: Researchers submit new proposals for funding.
10. `requestAIPreReview(uint256 _proposalId)`: Requests an AI Oracle to perform an initial review of a proposal.
11. `submitAIPreReviewResult(uint256 _proposalId, string _aiReviewHash, uint256 _aiScore)`: AI Oracles submit their pre-review results (called externally by the AI Oracle).
12. `assignManualReviewer(uint256 _proposalId, address _reviewer)`: Governors/curators assign human reviewers.
13. `submitManualReview(uint256 _proposalId, string _reviewHash, uint256 _score)`: Human reviewers submit their assessments.
14. `voteOnProposalFunding(uint256 _proposalId, bool _approve)`: Governors vote on whether to fund a proposal.
15. `finalizeProposalFunding(uint256 _proposalId)`: Finalizes the funding decision based on votes and distributes funds if approved.
16. `submitResearchProgressUpdate(uint256 _proposalId, string _updateIpfsHash)`: Researchers provide updates during the research phase.
17. `submitFinalResearchResults(uint256 _proposalId, string _resultsIpfsHash)`: Researchers submit their final research outcomes.
18. `requestAIVerification(uint256 _proposalId)`: Requests an AI Oracle to verify the final results.
19. `submitAIVerificationResult(uint256 _proposalId, bool _verified, string _proofIpfsHash)`: AI Oracles submit final verification results.
20. `mintKnowledgeArtifactNFT(uint256 _proposalId)`: Mints a Dynamic K-NFT for successfully verified research.
21. `updateKnowledgeArtifactMetadata(uint256 _tokenId, string _newMetadataIpfsHash)`: Allows the protocol to update K-NFT metadata based on external impact (e.g., citations, new data).

**III. Reputation & Role-Based Staking:**
22. `stakeForReviewerRole(uint256 _amount)`: Allows an address to stake tokens to become eligible as a reviewer.
23. `unstakeFromReviewerRole()`: Allows a reviewer to unstake their tokens.
24. `claimReviewerReward(uint256 _reviewId)`: Allows reviewers to claim rewards for impactful reviews.
25. `registerAIOracle(address _oracleAddress, string _description)`: Allows an AI service provider to register as an AI Oracle.
26. `deregisterAIOracle(address _oracleAddress)`: Allows an AI Oracle to de-register.
27. `setAIOracleFee(address _oracleAddress, uint256 _fee)`: Allows protocol governors to set a fee for AI Oracle services.

**IV. Dispute Resolution:**
28. `initiateDispute(uint256 _involvedEntityId, DisputeType _type, string _reasonIpfsHash)`: Allows a user to initiate a dispute (e.g., fraudulent research, biased review).
29. `resolveDispute(uint256 _disputeId, DisputeResolution _resolution)`: Allows governors to resolve a dispute, potentially affecting reputation or funds.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Mock Token for staking and payments (replace with a real ERC-20 in production)
interface IMockERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract AetherisProtocol is Ownable, ERC721, ReentrancyGuard {
    using Counters for Counters.Counter;

    // --- State Variables & Enums ---

    // Constants
    uint256 public constant MIN_REVIEWER_STAKE = 100 ether; // Example stake amount
    uint256 public constant DEFAULT_GOVERNANCE_QUORUM = 60; // 60% of votes needed to pass (out of 100)

    // ERC-20 for staking and grants
    IMockERC20 public immutable protocolToken;

    // Counters for unique IDs
    Counters.Counter private _proposalIds;
    Counters.Counter private _reviewIds;
    Counters.Counter private _knowledgeArtifactIds;
    Counters.Counter private _protocolGovernanceProposalIds;
    Counters.Counter private _disputeIds;

    // --- Enums ---
    enum ProposalStatus {
        Submitted,
        AIPreReviewed,
        ManualReviewed,
        Voting,
        Approved,
        Rejected,
        Funded,
        ResultsSubmitted,
        AIVerified,
        Completed,
        Disputed
    }

    enum DisputeType {
        Misconduct,
        BiasedReview,
        FraudulentResults,
        Other
    }

    enum DisputeResolution {
        None,
        Upheld,
        Overturned
    }

    enum GovernanceProposalStatus {
        Pending,
        Voting,
        Approved,
        Rejected,
        Executed
    }

    // --- Structs ---

    struct Researcher {
        string name;
        string profileIpfsHash;
        uint256 reputation; // Accumulated score
        bool isRegistered;
    }

    struct ResearchProposal {
        address researcher;
        string title;
        string ipfsHash; // Hash of the proposal document
        uint256 requestedAmount;
        uint256 fundedAmount;
        ProposalStatus status;
        address[] assignedManualReviewers;
        mapping(address => bool) hasVoted; // For governance voting
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 submissionTimestamp;
        uint256 votingEndsTimestamp;
        string finalResultsIpfsHash; // Hash of final results
        uint256 knowledgeArtifactTokenId; // Link to the K-NFT
    }

    struct AIPreReview {
        uint256 proposalId;
        address aiOracle;
        string reviewHash; // IPFS hash of AI's detailed review
        uint256 aiScore; // AI's assessment score (e.g., 0-100)
        uint256 timestamp;
    }

    struct ManualReview {
        uint256 proposalId;
        address reviewer;
        string reviewHash; // IPFS hash of human's detailed review
        uint256 score; // Human's assessment score (e.g., 0-100)
        uint256 timestamp;
        bool rewarded;
    }

    struct KnowledgeArtifact {
        uint256 proposalId;
        address researcher;
        string metadataIpfsHash; // Dynamic metadata (e.g., citation count, impact score)
        uint256 mintTimestamp;
    }

    struct ReviewerStake {
        uint256 amount;
        uint256 stakeTimestamp;
    }

    struct AIOracle {
        string description;
        uint256 fee; // Fee in protocol tokens for services
        bool isRegistered;
    }

    struct ProtocolGovernanceProposal {
        bytes32 parameterKey;
        uint256 newValue;
        uint256 submissionTimestamp;
        uint256 votingEndsTimestamp;
        GovernanceProposalStatus status;
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted; // For governance voting
    }

    struct Dispute {
        uint256 involvedEntityId; // e.g., proposalId, reviewId
        DisputeType disputeType;
        string reasonIpfsHash;
        address initiator;
        DisputeResolution resolution;
        uint256 resolutionTimestamp;
        mapping(address => bool) hasVoted; // For resolution voting by governors
        uint256 votesForResolution;
        uint256 votesAgainstResolution;
    }

    // --- Mappings ---
    mapping(address => Researcher) public researchers;
    mapping(uint256 => ResearchProposal) public proposals;
    mapping(uint256 => AIPreReview) public aiPreReviews;
    mapping(uint256 => ManualReview) public manualReviews;
    mapping(uint256 => KnowledgeArtifact) public knowledgeArtifacts; // tokenId -> KnowledgeArtifact
    mapping(address => ReviewerStake) public reviewerStakes;
    mapping(address => bool) public isReviewer; // Quick lookup for eligible reviewers
    mapping(address => AIOracle) public aiOracles;
    mapping(address => bool) public isAIOracle; // Quick lookup for registered AI Oracles
    mapping(address => bool) public isGovernor; // Addresses with governance voting power
    mapping(uint256 => ProtocolGovernanceProposal) public protocolGovernanceProposals;
    mapping(uint256 => Dispute) public disputes;

    // --- Events ---
    event FundsDeposited(address indexed depositor, uint256 amount);
    event ProtocolFeesWithdrawn(address indexed to, uint256 amount);
    event ResearcherRegistered(address indexed researcherAddress, string name);
    event ResearcherProfileUpdated(address indexed researcherAddress, string newProfileIpfsHash);
    event ResearchProposalSubmitted(uint256 indexed proposalId, address indexed researcher, string title, uint256 requestedAmount);
    event AIPreReviewRequested(uint256 indexed proposalId, address indexed aiOracle);
    event AIPreReviewResultSubmitted(uint256 indexed proposalId, address indexed aiOracle, uint256 aiScore);
    event ManualReviewAssigned(uint256 indexed proposalId, address indexed reviewer);
    event ManualReviewSubmitted(uint256 indexed reviewId, uint256 indexed proposalId, address indexed reviewer, uint256 score);
    event ProposalFundingVoteCast(uint256 indexed proposalId, address indexed voter, bool approved);
    event ProposalFundingFinalized(uint256 indexed proposalId, ProposalStatus newStatus, uint256 fundedAmount);
    event GrantDistributed(uint256 indexed proposalId, address indexed researcher, uint256 amount);
    event ResearchProgressUpdated(uint256 indexed proposalId, string updateIpfsHash);
    event FinalResearchResultsSubmitted(uint256 indexed proposalId, string resultsIpfsHash);
    event AIVerificationRequested(uint256 indexed proposalId, address indexed aiOracle);
    event AIVerificationResultSubmitted(uint256 indexed proposalId, address indexed aiOracle, bool verified);
    event KnowledgeArtifactMinted(uint256 indexed tokenId, uint256 indexed proposalId, address indexed researcher, string metadataIpfsHash);
    event KnowledgeArtifactMetadataUpdated(uint256 indexed tokenId, string newMetadataIpfsHash);
    event ReviewerStaked(address indexed reviewer, uint256 amount);
    event ReviewerUnstaked(address indexed reviewer, uint256 amount);
    event ReviewerRewardClaimed(uint256 indexed reviewId, address indexed reviewer, uint256 amount);
    event AIOracleRegistered(address indexed oracleAddress, string description);
    event AIOracleDeregistered(address indexed oracleAddress);
    event AIOracleFeeSet(address indexed oracleAddress, uint256 fee);
    event ProtocolParameterChangeProposed(uint256 indexed proposalId, bytes32 parameterKey, uint256 newValue);
    event ProtocolParameterChangeVoteCast(uint256 indexed proposalId, address indexed voter, bool approved);
    event ProtocolParameterChangeExecuted(uint256 indexed proposalId, bytes32 parameterKey, uint256 newValue);
    event DisputeInitiated(uint256 indexed disputeId, uint256 involvedEntityId, DisputeType disputeType, address indexed initiator);
    event DisputeResolved(uint256 indexed disputeId, DisputeResolution resolution);

    // --- Modifiers ---
    modifier onlyResearcher() {
        require(researchers[msg.sender].isRegistered, "AP: Not a registered researcher");
        _;
    }

    modifier onlyReviewer() {
        require(isReviewer[msg.sender], "AP: Not an eligible reviewer");
        _;
    }

    modifier onlyAIOracle() {
        require(isAIOracle[msg.sender], "AP: Not a registered AI Oracle");
        _;
    }

    modifier onlyGovernor() {
        require(isGovernor[msg.sender], "AP: Not a governor");
        _;
    }

    // --- Constructor ---
    constructor(address _protocolTokenAddress, address[] memory _initialGovernors) Ownable(msg.sender) ERC721("Aetheris Knowledge Artifact", "K-NFT") {
        protocolToken = IMockERC20(_protocolTokenAddress);

        for (uint256 i = 0; i < _initialGovernors.length; i++) {
            isGovernor[_initialGovernors[i]] = true;
        }
    }

    // --- I. Core Protocol Management & Funding ---

    /**
     * @notice Allows anyone to deposit funds into the protocol's grant pool.
     * @dev Funds are held in this contract to be disbursed for research grants.
     */
    function depositFunds(uint256 _amount) external nonReentrant {
        require(_amount > 0, "AP: Deposit amount must be positive");
        require(protocolToken.transferFrom(msg.sender, address(this), _amount), "AP: Token transfer failed");
        emit FundsDeposited(msg.sender, _amount);
    }

    /**
     * @notice Allows the protocol owner to withdraw accumulated fees.
     * @param _to The address to send the fees to.
     * @param _amount The amount of fees to withdraw.
     */
    function withdrawProtocolFees(address _to, uint256 _amount) external onlyOwner nonReentrant {
        require(_amount > 0, "AP: Withdraw amount must be positive");
        require(protocolToken.balanceOf(address(this)) >= _amount, "AP: Insufficient funds in protocol balance");
        require(protocolToken.transfer(_to, _amount), "AP: Fee withdrawal failed");
        emit ProtocolFeesWithdrawn(_to, _amount);
    }

    /**
     * @notice Allows a governor to propose a change to a protocol parameter.
     * @param _parameterKey A bytes32 identifier for the parameter (e.g., keccak256("MIN_REVIEWER_STAKE")).
     * @param _newValue The new value for the parameter.
     */
    function proposeProtocolParameterChange(bytes32 _parameterKey, uint256 _newValue) external onlyGovernor returns (uint256) {
        _protocolGovernanceProposalIds.increment();
        uint256 proposalId = _protocolGovernanceProposalIds.current();

        protocolGovernanceProposals[proposalId] = ProtocolGovernanceProposal({
            parameterKey: _parameterKey,
            newValue: _newValue,
            submissionTimestamp: block.timestamp,
            votingEndsTimestamp: block.timestamp + 3 days, // Example: 3 days voting period
            status: GovernanceProposalStatus.Voting,
            votesFor: 0,
            votesAgainst: 0
        });

        emit ProtocolParameterChangeProposed(proposalId, _parameterKey, _newValue);
        return proposalId;
    }

    /**
     * @notice Allows a governor to vote on an active protocol parameter change proposal.
     * @param _proposalId The ID of the governance proposal.
     * @param _approve True to vote for, false to vote against.
     */
    function voteOnProtocolChange(uint256 _proposalId, bool _approve) external onlyGovernor {
        ProtocolGovernanceProposal storage proposal = protocolGovernanceProposals[_proposalId];
        require(proposal.submissionTimestamp != 0, "AP: Proposal does not exist");
        require(proposal.status == GovernanceProposalStatus.Voting, "AP: Proposal not in voting phase");
        require(block.timestamp <= proposal.votingEndsTimestamp, "AP: Voting period has ended");
        require(!proposal.hasVoted[msg.sender], "AP: Already voted on this proposal");

        if (_approve) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }
        proposal.hasVoted[msg.sender] = true;

        emit ProtocolParameterChangeVoteCast(_proposalId, msg.sender, _approve);
    }

    /**
     * @notice Executes a passed protocol parameter change proposal. Only callable after voting period ends.
     * @param _proposalId The ID of the governance proposal.
     */
    function executeProtocolChange(uint256 _proposalId) external onlyGovernor {
        ProtocolGovernanceProposal storage proposal = protocolGovernanceProposals[_proposalId];
        require(proposal.submissionTimestamp != 0, "AP: Proposal does not exist");
        require(proposal.status == GovernanceProposalStatus.Voting, "AP: Proposal not in voting phase");
        require(block.timestamp > proposal.votingEndsTimestamp, "AP: Voting period not ended yet");
        require(proposal.votesFor + proposal.votesAgainst > 0, "AP: No votes cast"); // Ensure at least some participation

        // Simple majority based on votes cast, above a certain quorum
        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        uint256 requiredVotesFor = (totalVotes * DEFAULT_GOVERNANCE_QUORUM) / 100;

        if (proposal.votesFor >= requiredVotesFor && proposal.votesFor > proposal.votesAgainst) {
            bytes32 key = proposal.parameterKey;
            uint256 newValue = proposal.newValue;

            if (key == keccak256("MIN_REVIEWER_STAKE")) {
                // MIN_REVIEWER_STAKE = newValue; // Placeholder, as MIN_REVIEWER_STAKE is 'constant' in this simplified example
                // In a real system, `constant` would be replaced with a state variable `minReviewerStake`
            } else if (key == keccak256("DEFAULT_GOVERNANCE_QUORUM")) {
                // DEFAULT_GOVERNANCE_QUORUM = newValue;
            }
            // Add more parameter update logic here

            proposal.status = GovernanceProposalStatus.Executed;
            emit ProtocolParameterChangeExecuted(_proposalId, key, newValue);
        } else {
            proposal.status = GovernanceProposalStatus.Rejected;
            // No specific event for rejection, implied by status
        }
    }

    // --- II. Researcher & Research Lifecycle ---

    /**
     * @notice Allows an address to register themselves as a researcher.
     * @param _name The researcher's name.
     * @param _profileIpfsHash IPFS hash pointing to the researcher's detailed profile.
     */
    function registerResearcher(string memory _name, string memory _profileIpfsHash) external {
        require(!researchers[msg.sender].isRegistered, "AP: Already a registered researcher");
        researchers[msg.sender] = Researcher({
            name: _name,
            profileIpfsHash: _profileIpfsHash,
            reputation: 100, // Starting reputation
            isRegistered: true
        });
        emit ResearcherRegistered(msg.sender, _name);
    }

    /**
     * @notice Allows a registered researcher to update their profile information.
     * @param _newProfileIpfsHash IPFS hash pointing to the updated profile.
     */
    function updateResearcherProfile(string memory _newProfileIpfsHash) external onlyResearcher {
        researchers[msg.sender].profileIpfsHash = _newProfileIpfsHash;
        emit ResearcherProfileUpdated(msg.sender, _newProfileIpfsHash);
    }

    /**
     * @notice Allows a researcher to submit a new research proposal.
     * @param _title The title of the research proposal.
     * @param _ipfsHash IPFS hash pointing to the full proposal document.
     * @param _requestedAmount The amount of protocol tokens requested for the grant.
     */
    function submitResearchProposal(string memory _title, string memory _ipfsHash, uint256 _requestedAmount) external onlyResearcher returns (uint256) {
        _proposalIds.increment();
        uint256 proposalId = _proposalIds.current();

        proposals[proposalId] = ResearchProposal({
            researcher: msg.sender,
            title: _title,
            ipfsHash: _ipfsHash,
            requestedAmount: _requestedAmount,
            fundedAmount: 0,
            status: ProposalStatus.Submitted,
            assignedManualReviewers: new address[](0),
            votesFor: 0,
            votesAgainst: 0,
            submissionTimestamp: block.timestamp,
            votingEndsTimestamp: 0, // Set later when voting starts
            finalResultsIpfsHash: "",
            knowledgeArtifactTokenId: 0
        });

        emit ResearchProposalSubmitted(proposalId, msg.sender, _title, _requestedAmount);
        return proposalId;
    }

    /**
     * @notice Requests an AI Oracle to perform an initial pre-review of a proposal.
     * @dev This simulates an off-chain interaction where a registered AI Oracle picks up the request.
     * @param _proposalId The ID of the proposal to be pre-reviewed.
     */
    function requestAIPreReview(uint256 _proposalId) external {
        ResearchProposal storage proposal = proposals[_proposalId];
        require(proposal.submissionTimestamp != 0, "AP: Proposal does not exist");
        require(proposal.status == ProposalStatus.Submitted, "AP: Proposal not in submitted state");
        require(isAIOracle[msg.sender], "AP: Only registered AI Oracles can request this"); // Only AI Oracles can pull tasks

        // In a real system, this would trigger an off-chain event or a push to a specific AI Oracle
        // For this example, we'll just allow a registered AI Oracle to acknowledge the request
        emit AIPreReviewRequested(_proposalId, msg.sender);
    }

    /**
     * @notice Allows a registered AI Oracle to submit the results of a pre-review.
     * @param _proposalId The ID of the proposal.
     * @param _aiReviewHash IPFS hash of the detailed AI review report.
     * @param _aiScore The AI's score for the proposal (e.g., 0-100).
     */
    function submitAIPreReviewResult(uint256 _proposalId, string memory _aiReviewHash, uint256 _aiScore) external onlyAIOracle {
        ResearchProposal storage proposal = proposals[_proposalId];
        require(proposal.submissionTimestamp != 0, "AP: Proposal does not exist");
        require(proposal.status == ProposalStatus.Submitted, "AP: Proposal not in submitted state"); // Still 'Submitted' until human review begins

        _aiPreReviews.increment();
        aiPreReviews[_aiPreReviews.current()] = AIPreReview({
            proposalId: _proposalId,
            aiOracle: msg.sender,
            reviewHash: _aiReviewHash,
            aiScore: _aiScore,
            timestamp: block.timestamp
        });

        proposal.status = ProposalStatus.AIPreReviewed;
        _updateResearcherReputation(msg.sender, 5); // Reward AI Oracle for contribution
        emit AIPreReviewResultSubmitted(_proposalId, msg.sender, _aiScore);
    }

    /**
     * @notice Allows a governor to assign a human reviewer to a proposal.
     * @param _proposalId The ID of the proposal.
     * @param _reviewer The address of the human reviewer.
     */
    function assignManualReviewer(uint256 _proposalId, address _reviewer) external onlyGovernor {
        ResearchProposal storage proposal = proposals[_proposalId];
        require(proposal.submissionTimestamp != 0, "AP: Proposal does not exist");
        require(proposal.status == ProposalStatus.AIPreReviewed, "AP: Proposal not in AI pre-reviewed state");
        require(isReviewer[_reviewer], "AP: Assigned address is not an eligible reviewer");
        
        bool alreadyAssigned = false;
        for(uint i=0; i<proposal.assignedManualReviewers.length; i++){
            if(proposal.assignedManualReviewers[i] == _reviewer){
                alreadyAssigned = true;
                break;
            }
        }
        require(!alreadyAssigned, "AP: Reviewer already assigned to this proposal");

        proposal.assignedManualReviewers.push(_reviewer);
        emit ManualReviewAssigned(_proposalId, _reviewer);
    }

    /**
     * @notice Allows an assigned human reviewer to submit their review.
     * @param _proposalId The ID of the proposal.
     * @param _reviewHash IPFS hash of the detailed human review report.
     * @param _score The human's score for the proposal (e.g., 0-100).
     */
    function submitManualReview(uint256 _proposalId, string memory _reviewHash, uint256 _score) external onlyReviewer {
        ResearchProposal storage proposal = proposals[_proposalId];
        require(proposal.submissionTimestamp != 0, "AP: Proposal does not exist");
        require(proposal.status == ProposalStatus.AIPreReviewed, "AP: Proposal not in correct state for manual review");

        bool isAssigned = false;
        for (uint i = 0; i < proposal.assignedManualReviewers.length; i++) {
            if (proposal.assignedManualReviewers[i] == msg.sender) {
                isAssigned = true;
                break;
            }
        }
        require(isAssigned, "AP: You are not assigned to review this proposal");

        // Check if reviewer already submitted for this proposal
        _reviewIds.increment();
        manualReviews[_reviewIds.current()] = ManualReview({
            proposalId: _proposalId,
            reviewer: msg.sender,
            reviewHash: _reviewHash,
            score: _score,
            timestamp: block.timestamp,
            rewarded: false
        });

        // This would ideally be more complex, e.g., requiring N reviews before moving to voting
        if (proposal.assignedManualReviewers.length > 0) { // For this example, 1 review is enough to move to voting
            proposal.status = ProposalStatus.Voting;
            proposal.votingEndsTimestamp = block.timestamp + 7 days; // Example: 7 days voting for funding
        }

        _updateResearcherReputation(msg.sender, 10); // Reward reviewer for good review
        emit ManualReviewSubmitted(_reviewIds.current(), _proposalId, msg.sender, _score);
    }

    /**
     * @notice Allows a governor to vote on whether to fund a research proposal.
     * @param _proposalId The ID of the proposal.
     * @param _approve True to vote for funding, false to vote against.
     */
    function voteOnProposalFunding(uint256 _proposalId, bool _approve) external onlyGovernor {
        ResearchProposal storage proposal = proposals[_proposalId];
        require(proposal.submissionTimestamp != 0, "AP: Proposal does not exist");
        require(proposal.status == ProposalStatus.Voting, "AP: Proposal not in voting phase");
        require(block.timestamp <= proposal.votingEndsTimestamp, "AP: Voting period has ended");
        require(!proposal.hasVoted[msg.sender], "AP: Already voted on this proposal");

        if (_approve) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }
        proposal.hasVoted[msg.sender] = true;

        emit ProposalFundingVoteCast(_proposalId, msg.sender, _approve);
    }

    /**
     * @notice Finalizes the funding decision for a proposal based on votes.
     * @param _proposalId The ID of the proposal.
     */
    function finalizeProposalFunding(uint256 _proposalId) external nonReentrant {
        ResearchProposal storage proposal = proposals[_proposalId];
        require(proposal.submissionTimestamp != 0, "AP: Proposal does not exist");
        require(proposal.status == ProposalStatus.Voting, "AP: Proposal not in voting phase");
        require(block.timestamp > proposal.votingEndsTimestamp, "AP: Voting period not ended yet");
        
        // Simple majority based on votes cast, above a certain quorum
        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        require(totalVotes > 0, "AP: No votes cast for this proposal");

        uint256 requiredVotesFor = (totalVotes * DEFAULT_GOVERNANCE_QUORUM) / 100;

        if (proposal.votesFor >= requiredVotesFor && proposal.votesFor > proposal.votesAgainst) {
            // Check if enough funds are available in the protocol contract
            if (protocolToken.balanceOf(address(this)) >= proposal.requestedAmount) {
                proposal.status = ProposalStatus.Approved;
                proposal.fundedAmount = proposal.requestedAmount;
            } else {
                proposal.status = ProposalStatus.Rejected; // Rejected due to insufficient funds
            }
        } else {
            proposal.status = ProposalStatus.Rejected;
        }
        emit ProposalFundingFinalized(_proposalId, proposal.status, proposal.fundedAmount);
    }

    /**
     * @notice Distributes the grant funds to the researcher if the proposal was approved.
     * @param _proposalId The ID of the proposal.
     */
    function distributeGrant(uint256 _proposalId) external nonReentrant {
        ResearchProposal storage proposal = proposals[_proposalId];
        require(proposal.researcher == msg.sender, "AP: Only the researcher can claim the grant");
        require(proposal.status == ProposalStatus.Approved, "AP: Proposal not approved for funding");
        require(proposal.fundedAmount > 0, "AP: No funds to distribute");

        uint256 amountToTransfer = proposal.fundedAmount;
        proposal.fundedAmount = 0; // Prevent re-claiming

        require(protocolToken.transfer(proposal.researcher, amountToTransfer), "AP: Grant transfer failed");
        proposal.status = ProposalStatus.Funded;
        _updateResearcherReputation(proposal.researcher, 50); // Significant reputation boost
        emit GrantDistributed(_proposalId, proposal.researcher, amountToTransfer);
    }

    /**
     * @notice Allows a researcher to submit progress updates for their funded research.
     * @param _proposalId The ID of the proposal.
     * @param _updateIpfsHash IPFS hash of the progress update document.
     */
    function submitResearchProgressUpdate(uint256 _proposalId, string memory _updateIpfsHash) external onlyResearcher {
        ResearchProposal storage proposal = proposals[_proposalId];
        require(proposal.researcher == msg.sender, "AP: Not the researcher for this proposal");
        require(proposal.status == ProposalStatus.Funded || proposal.status == ProposalStatus.ResultsSubmitted, "AP: Proposal not in active research phase");
        require(bytes(_updateIpfsHash).length > 0, "AP: IPFS hash cannot be empty");
        // No state change here, just a log of progress
        emit ResearchProgressUpdated(_proposalId, _updateIpfsHash);
    }

    /**
     * @notice Allows a researcher to submit their final research results.
     * @param _proposalId The ID of the proposal.
     * @param _resultsIpfsHash IPFS hash of the final research paper/results.
     */
    function submitFinalResearchResults(uint256 _proposalId, string memory _resultsIpfsHash) external onlyResearcher {
        ResearchProposal storage proposal = proposals[_proposalId];
        require(proposal.researcher == msg.sender, "AP: Not the researcher for this proposal");
        require(proposal.status == ProposalStatus.Funded, "AP: Proposal not in funded state");
        require(bytes(_resultsIpfsHash).length > 0, "AP: Results IPFS hash cannot be empty");

        proposal.finalResultsIpfsHash = _resultsIpfsHash;
        proposal.status = ProposalStatus.ResultsSubmitted;
        emit FinalResearchResultsSubmitted(_proposalId, _resultsIpfsHash);
    }

    /**
     * @notice Requests an AI Oracle to verify the final research results.
     * @dev Similar to `requestAIPreReview`, this simulates an off-chain interaction.
     * @param _proposalId The ID of the proposal.
     */
    function requestAIVerification(uint256 _proposalId) external {
        ResearchProposal storage proposal = proposals[_proposalId];
        require(proposal.submissionTimestamp != 0, "AP: Proposal does not exist");
        require(proposal.status == ProposalStatus.ResultsSubmitted, "AP: Proposal results not submitted");
        require(isAIOracle[msg.sender], "AP: Only registered AI Oracles can request this");

        emit AIVerificationRequested(_proposalId, msg.sender);
    }

    /**
     * @notice Allows a registered AI Oracle to submit the results of final research verification.
     * @param _proposalId The ID of the proposal.
     * @param _verified True if the results were verified, false otherwise.
     * @param _proofIpfsHash IPFS hash of the AI's verification proof/report.
     */
    function submitAIVerificationResult(uint256 _proposalId, bool _verified, string memory _proofIpfsHash) external onlyAIOracle {
        ResearchProposal storage proposal = proposals[_proposalId];
        require(proposal.submissionTimestamp != 0, "AP: Proposal does not exist");
        require(proposal.status == ProposalStatus.ResultsSubmitted, "AP: Proposal not in results submitted state");
        
        if (_verified) {
            proposal.status = ProposalStatus.AIVerified;
            _updateResearcherReputation(proposal.researcher, 100); // Big boost for verified research
            _updateResearcherReputation(msg.sender, 20); // Reward AI Oracle for verification
        } else {
            proposal.status = ProposalStatus.Disputed; // If AI finds issues, it goes to dispute
            // Potentially auto-initiate dispute here, or just change status for human review
        }
        emit AIVerificationResultSubmitted(_proposalId, msg.sender, _verified);
    }

    /**
     * @notice Mints a Dynamic Knowledge Artifact NFT for successfully verified research.
     * @param _proposalId The ID of the proposal.
     */
    function mintKnowledgeArtifactNFT(uint256 _proposalId) external nonReentrant {
        ResearchProposal storage proposal = proposals[_proposalId];
        require(proposal.researcher == msg.sender, "AP: Only the researcher can mint their K-NFT");
        require(proposal.status == ProposalStatus.AIVerified, "AP: Research not yet AI verified");
        require(proposal.knowledgeArtifactTokenId == 0, "AP: K-NFT already minted for this research");

        _knowledgeArtifactIds.increment();
        uint256 newTokenId = _knowledgeArtifactIds.current();

        // Base metadata can include title, researcher, initial IPFS hash of results
        string memory initialMetadataHash = proposal.finalResultsIpfsHash; // Or a dedicated metadata JSON
        
        _safeMint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, initialMetadataHash); // Set initial URI as the results hash for now

        knowledgeArtifacts[newTokenId] = KnowledgeArtifact({
            proposalId: _proposalId,
            researcher: msg.sender,
            metadataIpfsHash: initialMetadataHash,
            mintTimestamp: block.timestamp
        });
        
        proposal.knowledgeArtifactTokenId = newTokenId;
        proposal.status = ProposalStatus.Completed; // Research cycle completed
        emit KnowledgeArtifactMinted(newTokenId, _proposalId, msg.sender, initialMetadataHash);
    }

    /**
     * @notice Allows the protocol (via governance/admin) to update the metadata of a K-NFT.
     * @dev This enables the 'dynamic' aspect, updating based on real-world impact (e.g., citations).
     * @param _tokenId The ID of the Knowledge Artifact NFT.
     * @param _newMetadataIpfsHash The IPFS hash of the new, updated metadata.
     */
    function updateKnowledgeArtifactMetadata(uint256 _tokenId, string memory _newMetadataIpfsHash) external onlyGovernor {
        require(_exists(_tokenId), "AP: K-NFT does not exist");
        KnowledgeArtifact storage ka = knowledgeArtifacts[_tokenId];
        require(bytes(_newMetadataIpfsHash).length > 0, "AP: New metadata IPFS hash cannot be empty");

        ka.metadataIpfsHash = _newMetadataIpfsHash;
        _setTokenURI(_tokenId, _newMetadataIpfsHash); // Update ERC-721 token URI
        emit KnowledgeArtifactMetadataUpdated(_tokenId, _newMetadataIpfsHash);
    }

    // --- III. Reputation & Role-Based Staking ---

    /**
     * @notice Internal function to update a researcher's reputation score.
     * @param _addr The address of the researcher/contributor.
     * @param _delta The amount to change reputation by (can be negative).
     */
    function _updateResearcherReputation(address _addr, int256 _delta) internal {
        if (researchers[_addr].isRegistered) {
            int256 currentRep = int256(researchers[_addr].reputation);
            currentRep += _delta;
            if (currentRep < 0) currentRep = 0; // Reputation cannot go below 0
            researchers[_addr].reputation = uint256(currentRep);
            // Consider emitting an event for reputation changes
        }
    }

    /**
     * @notice Allows a user to stake tokens to become an eligible reviewer.
     * @param _amount The amount of tokens to stake.
     */
    function stakeForReviewerRole(uint256 _amount) external nonReentrant {
        require(_amount >= MIN_REVIEWER_STAKE, "AP: Stake amount too low");
        require(reviewerStakes[msg.sender].amount == 0, "AP: Already staked as a reviewer");

        require(protocolToken.transferFrom(msg.sender, address(this), _amount), "AP: Token transfer failed");

        reviewerStakes[msg.sender] = ReviewerStake({
            amount: _amount,
            stakeTimestamp: block.timestamp
        });
        isReviewer[msg.sender] = true;
        emit ReviewerStaked(msg.sender, _amount);
    }

    /**
     * @notice Allows a reviewer to unstake their tokens and relinquish the role.
     */
    function unstakeFromReviewerRole() external nonReentrant {
        ReviewerStake storage stake = reviewerStakes[msg.sender];
        require(stake.amount > 0, "AP: No active stake found");

        uint256 amountToReturn = stake.amount;
        delete reviewerStakes[msg.sender];
        isReviewer[msg.sender] = false;

        require(protocolToken.transfer(msg.sender, amountToReturn), "AP: Unstake transfer failed");
        emit ReviewerUnstaked(msg.sender, amountToReturn);
    }

    /**
     * @notice Allows a reviewer to claim rewards for completed, impactful reviews.
     * @param _reviewId The ID of the review to claim rewards for.
     */
    function claimReviewerReward(uint256 _reviewId) external nonReentrant {
        ManualReview storage review = manualReviews[_reviewId];
        require(review.reviewer == msg.sender, "AP: Not the reviewer for this review");
        require(!review.rewarded, "AP: Review already rewarded");
        
        // Example reward logic: 10 tokens per review
        uint256 rewardAmount = 10 ether; 
        require(protocolToken.balanceOf(address(this)) >= rewardAmount, "AP: Insufficient protocol funds for reward");

        review.rewarded = true;
        require(protocolToken.transfer(msg.sender, rewardAmount), "AP: Reward transfer failed");
        emit ReviewerRewardClaimed(_reviewId, msg.sender, rewardAmount);
    }

    /**
     * @notice Allows an AI service provider to register as an AI Oracle.
     * @param _oracleAddress The address of the AI Oracle's contract/wallet.
     * @param _description A description of the AI Oracle's capabilities.
     */
    function registerAIOracle(address _oracleAddress, string memory _description) external onlyOwner {
        require(!isAIOracle[_oracleAddress], "AP: AI Oracle already registered");
        aiOracles[_oracleAddress] = AIOracle({
            description: _description,
            fee: 0, // Default fee, can be set later by governors
            isRegistered: true
        });
        isAIOracle[_oracleAddress] = true;
        emit AIOracleRegistered(_oracleAddress, _description);
    }

    /**
     * @notice Allows an AI Oracle to de-register themselves or the owner to remove them.
     * @param _oracleAddress The address of the AI Oracle to deregister.
     */
    function deregisterAIOracle(address _oracleAddress) external onlyOwner {
        require(isAIOracle[_oracleAddress], "AP: AI Oracle not registered");
        delete aiOracles[_oracleAddress];
        isAIOracle[_oracleAddress] = false;
        emit AIOracleDeregistered(_oracleAddress);
    }

    /**
     * @notice Allows governors to set the service fee for a registered AI Oracle.
     * @param _oracleAddress The address of the AI Oracle.
     * @param _fee The new fee amount in protocol tokens.
     */
    function setAIOracleFee(address _oracleAddress, uint256 _fee) external onlyGovernor {
        require(isAIOracle[_oracleAddress], "AP: AI Oracle not registered");
        aiOracles[_oracleAddress].fee = _fee;
        emit AIOracleFeeSet(_oracleAddress, _fee);
    }

    // --- IV. Dispute Resolution ---

    /**
     * @notice Allows a user to initiate a dispute regarding a specific entity (e.g., proposal, review).
     * @param _involvedEntityId The ID of the entity involved in the dispute (e.g., proposalId, reviewId).
     * @param _type The type of dispute (e.g., Misconduct, BiasedReview).
     * @param _reasonIpfsHash IPFS hash pointing to the detailed reason and evidence for the dispute.
     */
    function initiateDispute(uint256 _involvedEntityId, DisputeType _type, string memory _reasonIpfsHash) external {
        _disputeIds.increment();
        uint256 disputeId = _disputeIds.current();

        disputes[disputeId] = Dispute({
            involvedEntityId: _involvedEntityId,
            disputeType: _type,
            reasonIpfsHash: _reasonIpfsHash,
            initiator: msg.sender,
            resolution: DisputeResolution.None,
            resolutionTimestamp: 0,
            votesForResolution: 0,
            votesAgainstResolution: 0
        });

        // Potentially change status of involved entity to Disputed
        // For example, if it's a proposal:
        // if (proposals[_involvedEntityId].submissionTimestamp != 0) {
        //     proposals[_involvedEntityId].status = ProposalStatus.Disputed;
        // }

        emit DisputeInitiated(disputeId, _involvedEntityId, _type, msg.sender);
    }

    /**
     * @notice Allows governors to resolve an active dispute. This could involve voting.
     * @param _disputeId The ID of the dispute to resolve.
     * @param _resolution The resolution (Upheld or Overturned).
     * @dev In a real system, this might be a multi-step voting process. Here, it's simplified.
     */
    function resolveDispute(uint256 _disputeId, DisputeResolution _resolution) external onlyGovernor {
        Dispute storage dispute = disputes[_disputeId];
        require(dispute.involvedEntityId != 0, "AP: Dispute does not exist");
        require(dispute.resolution == DisputeResolution.None, "AP: Dispute already resolved");
        require(_resolution != DisputeResolution.None, "AP: Invalid resolution");

        // Simplified resolution: direct action by a governor
        dispute.resolution = _resolution;
        dispute.resolutionTimestamp = block.timestamp;

        // Apply consequences based on resolution
        if (_resolution == DisputeResolution.Upheld) {
            // Example consequences:
            // if (dispute.disputeType == DisputeType.FraudulentResults) {
            //     ResearchProposal storage proposal = proposals[dispute.involvedEntityId];
            //     _updateResearcherReputation(proposal.researcher, -200); // Massive reputation loss
            //     // Potentially freeze/slash funds, burn K-NFT
            // } else if (dispute.disputeType == DisputeType.BiasedReview) {
            //     ManualReview storage review = manualReviews[dispute.involvedEntityId];
            //     _updateResearcherReputation(review.reviewer, -50); // Reputation loss for reviewer
            // }
        } else if (_resolution == DisputeResolution.Overturned) {
            // If overturned, restore reputation, etc.
        }

        emit DisputeResolved(_disputeId, _resolution);
    }

    // --- Read-only Functions (Getters) ---
    function getResearcher(address _addr) public view returns (string memory name, string memory profileIpfsHash, uint256 reputation, bool isRegistered) {
        Researcher storage r = researchers[_addr];
        return (r.name, r.profileIpfsHash, r.reputation, r.isRegistered);
    }

    function getProposal(uint256 _proposalId) public view returns (address researcher, string memory title, string memory ipfsHash, uint256 requestedAmount, uint256 fundedAmount, ProposalStatus status, uint256 votesFor, uint256 votesAgainst, uint256 submissionTimestamp, uint256 votingEndsTimestamp, string memory finalResultsIpfsHash, uint256 knowledgeArtifactTokenId) {
        ResearchProposal storage p = proposals[_proposalId];
        return (p.researcher, p.title, p.ipfsHash, p.requestedAmount, p.fundedAmount, p.status, p.votesFor, p.votesAgainst, p.submissionTimestamp, p.votingEndsTimestamp, p.finalResultsIpfsHash, p.knowledgeArtifactTokenId);
    }

    function getKnowledgeArtifact(uint256 _tokenId) public view returns (uint256 proposalId, address researcher, string memory metadataIpfsHash, uint256 mintTimestamp) {
        KnowledgeArtifact storage ka = knowledgeArtifacts[_tokenId];
        return (ka.proposalId, ka.researcher, ka.metadataIpfsHash, ka.mintTimestamp);
    }

    function getReviewerStake(address _addr) public view returns (uint256 amount, uint256 stakeTimestamp) {
        ReviewerStake storage stake = reviewerStakes[_addr];
        return (stake.amount, stake.stakeTimestamp);
    }

    function getAIOracle(address _addr) public view returns (string memory description, uint256 fee, bool registered) {
        AIOracle storage oracle = aiOracles[_addr];
        return (oracle.description, oracle.fee, oracle.isRegistered);
    }

    // ERC721 metadata override (optional but good practice)
    function _baseURI() internal view override returns (string memory) {
        return "ipfs://"; // Base URI for K-NFT metadata
    }
}
```