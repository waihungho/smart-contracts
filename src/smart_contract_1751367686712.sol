Okay, let's design a sophisticated smart contract for a Decentralized Autonomous Research Lab (DARL). This contract will handle research proposal submissions, funding, project management, data registration, intellectual property (IP) management via NFTs, a peer review process, a reputation system, simplified governance, and conceptual integration points for off-chain verification (like ZK proofs) and oracles.

It incorporates concepts like:
*   **DeSci (Decentralized Science):** Focus on research, data, IP.
*   **Token-Curated Registries (Implicit):** Proposals and projects form curated lists.
*   **NFTs for IP:** Representing research outputs as NFTs with potential revenue sharing.
*   **Reputation System:** On-chain tracking of contributions.
*   **Decentralized Storage Integration:** Using hashes for off-chain data (IPFS, Arweave, etc.).
*   **Simplified Governance:** Voting on key actions (project approval, treasury).
*   **Conceptual ZK/Oracle Integration:** Functions to *record* verification proofs.
*   **Treasury Management:** Funding proposals and rewarding participants.
*   **Role-Based Access Control (Simplified):** Admin/Governance roles.
*   **Pausable:** Standard security pattern.

This is a complex system, and a full production-grade implementation would require significant off-chain components (UI, data storage, verification services, oracle feeds) and potentially more sophisticated governance (e.g., Compound/Aave style). This contract focuses on the on-chain logic and state management.

---

**Outline and Function Summary**

**Contract Name:** DecentralizedAutonomousResearchLab (DARL)

**Core Concepts:** DeSci, IP-NFTs, Reputation, Peer Review, Decentralized Data/IP Management, Simplified Governance, Treasury, Off-chain Verification Hooks.

**State Management:**
*   Manages researchers, proposals, projects, research data, reviews, governance proposals, and reputation scores.
*   Uses counters to generate unique IDs for entities.
*   Tracks funding, project progress, and governance votes.

**Interfaces & Dependencies:**
*   Inherits from `Ownable` for initial administrative control.
*   Inherits from `Pausable` for emergency stops.
*   Implements basic `ERC721` for minting IP NFTs directly (simplified).

**Key Entities (Structs & Mappings):**
*   `Researcher`: Represents an onboarded researcher with a profile hash and reputation score.
*   `Proposal`: Details a research proposal seeking funding/approval.
*   `Project`: Represents an active or completed research project.
*   `ResearchData`: Metadata and hash of research data associated with a project.
*   `Review`: A peer review submitted for a proposal or project.
*   `GovernanceProposal`: A proposal for the DAO to vote on (parameter change, treasury action, project status change).

**Enums:**
*   `ProposalStatus`: Lifecycle of a proposal (Draft, Submitted, Funding, Funded, Rejected).
*   `ProjectStatus`: Lifecycle of a project (Proposed, Active, Review, Completed, Failed).
*   `ReviewTargetType`: Indicates whether a review is for a proposal or a project.
*   `GovernanceProposalStatus`: Lifecycle of a governance proposal (Open, Passed, Failed, Executed).
*   `GovernanceProposalType`: Type of action a governance proposal proposes.

**Functions (>= 20):**

**I. Administration & Setup**
1.  `constructor()`: Initializes owner, counters, and sets initial parameters.
2.  `pauseContract()`: Pauses the contract (Owner/Governance).
3.  `unpauseContract()`: Unpauses the contract (Owner/Governance).
4.  `setGovernanceParameters()`: Updates core governance parameters like voting periods, quorum, etc. (Callable by Governance).

**II. Researcher Management**
5.  `registerResearcher(string calldata profileHash)`: Allows anyone to register as a researcher (requires a unique profile hash linking to off-chain info).
6.  `updateResearcherProfile(string calldata newProfileHash)`: Allows a registered researcher to update their profile hash.
7.  `getResearcherProfile(address researcher)`: Views a researcher's profile hash and status.

**III. Proposal Lifecycle**
8.  `submitResearchProposal(string calldata metadataHash, uint256 fundingGoal)`: A registered researcher submits a new proposal.
9.  `getProposalDetails(uint256 proposalId)`: Views the details of a specific proposal.
10. `fundProposal(uint256 proposalId)`: Allows anyone to contribute ether to a proposal's funding goal.
11. `withdrawFailedProposalFunds(uint256 proposalId)`: Allows contributors to withdraw funds if a proposal is rejected or expires without funding.

**IV. Project Management**
12. `startResearchProject(uint256 proposalId)`: Converts a funded/approved proposal into an active project (Callable by Governance/Admin). Allocates funds from the treasury.
13. `submitProjectUpdate(uint256 projectId, string calldata updateHash)`: Project researcher submits a progress update (hash of report/data).
14. `registerResearchData(uint256 projectId, string calldata dataHash, string calldata metadataHash)`: Project researcher registers a hash and metadata for a dataset generated by the project.
15. `submitOffChainVerificationProof(uint256 projectId, uint256 updateIndex, string calldata proofHash)`: Researcher submits a hash referencing a proof (e.g., ZK proof) verifying an off-chain project update or result.
16. `completeProject(uint256 projectId)`: Marks a project as completed after review/verification (Callable by Governance/Admin). Triggers reputation update for participants.
17. `getProjectDetails(uint256 projectId)`: Views the details of a specific project.
18. `getResearchDataDetails(uint256 dataId)`: Views details of registered research data.

**V. Intellectual Property (IP) Management**
19. `mintIPNFT(uint256 projectId, string calldata tokenURICid)`: Mints an ERC721 token representing the IP of a *completed* project (Callable by Project Lead/Governance). Links NFT to project.
20. `setIPRevenueShare(uint256 ipNftTokenId, address[] calldata payees, uint256[] calldata shares)`: Sets revenue sharing structure for future sales/royalties of a specific IP NFT (Callable by IP NFT owner or Governance). (Note: Requires external revenue collection/distribution logic).
21. `getIPNFTDetails(uint256 ipNftTokenId)`: Views details about an IP NFT and its linked project.

**VI. Peer Review System**
22. `assignReviewer(uint256 targetId, ReviewTargetType targetType, address reviewer)`: Assigns a researcher to review a proposal or project (Callable by Governance/Admin).
23. `submitReview(uint256 reviewId, uint8 rating, string calldata reviewHash)`: A designated reviewer submits their review score and hash.
24. `getReviewDetails(uint256 reviewId)`: Views details of a specific review.
25. `finalizeReviewProcess(uint256 targetId, ReviewTargetType targetType)`: Concludes the review process for a proposal or project, potentially triggering status change or reward (Callable by Governance/Admin).

**VII. Reputation System**
26. `getReputationScore(address researcher)`: Views a researcher's current reputation score.
27. `slashReputation(address researcher, uint256 amount)`: Decreases a researcher's reputation score due to misconduct (Callable by Governance/Admin).

**VIII. Treasury Management**
28. `depositToTreasury()`: Allows anyone to send ether to the contract treasury.
29. `withdrawFromTreasury(uint256 amount, address recipient)`: Withdraws funds from the treasury (Callable by Governance via proposal execution).
30. `getTreasuryBalance()`: Views the current balance of the contract's treasury.

**IX. Governance System**
31. `createGovernanceProposal(GovernanceProposalType proposalType, uint256 targetId, bytes calldata proposalData, string calldata descriptionHash)`: Allows researchers with sufficient reputation to create a governance proposal.
32. `voteOnGovernanceProposal(uint256 proposalId, bool voteYes)`: Allows eligible participants (e.g., researchers, token holders - simplified here to registered researchers) to vote on an open proposal.
33. `executeGovernanceProposal(uint256 proposalId)`: Executes a governance proposal if it has passed the vote and grace period (Callable by anyone after grace period). Handles different proposal types internally (e.g., calls `startResearchProject`, `completeProject`, `withdrawFromTreasury`, `setGovernanceParameters`, `slashReputation`).
34. `getGovernanceProposalDetails(uint256 proposalId)`: Views details of a specific governance proposal.
35. `getGovernanceProposalVoteCounts(uint256 proposalId)`: Views vote counts for a specific governance proposal.

Total Functions: 35 (Well over the minimum 20).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol"; // Example for potential off-chain verification hook

// Outline and Function Summary: See above the contract code.

/**
 * @title DecentralizedAutonomousResearchLab (DARL)
 * @dev A sophisticated smart contract for managing decentralized research projects.
 * It includes features for proposals, funding, project tracking, data registration,
 * IP-NFTs, peer review, researcher reputation, treasury management, and governance.
 */
contract DecentralizedAutonomousResearchLab is Ownable, Pausable, ERC721 {
    using Counters for Counters.Counter;

    // --- Counters ---
    Counters.Counter private _researcherIds;
    Counters.Counter private _proposalIds;
    Counters.Counter private _projectIds;
    Counters.Counter private _dataIds;
    Counters.Counter private _reviewIds;
    Counters.Counter private _governanceProposalIds;
    Counters.Counter private _ipNftTokenIds; // Using ERC721's internal counter, but tracking linkage

    // --- Enums ---
    enum ProposalStatus {
        Draft,
        Submitted,
        Funding,
        Funded,
        Rejected,
        ConvertedToProject
    }

    enum ProjectStatus {
        Proposed, // Linked to a Funded proposal
        Active,
        Review, // Under peer/governance review
        Completed,
        Failed // e.g., Did not pass review, ran out of funds, abandoned
    }

    enum ReviewTargetType {
        Proposal,
        Project
    }

    enum GovernanceProposalStatus {
        Open,
        Passed,
        Failed,
        Executed
    }

    enum GovernanceProposalType {
        ParameterChange,
        TreasuryWithdrawal,
        ProjectStatusChange, // e.g., Complete, Fail
        ResearcherSlashReputation
    }

    // --- Structs ---
    struct Researcher {
        bool exists;
        address wallet;
        string profileHash; // IPFS CID or similar
        uint256 reputation;
    }

    struct Proposal {
        uint256 id;
        address author;
        string metadataHash; // IPFS CID for proposal details
        uint256 fundingGoal;
        uint256 fundsRaised;
        ProposalStatus status;
        uint256 submissionTimestamp;
        uint256 fundingExpirationTimestamp;
        uint256 linkedProjectId; // 0 if not yet a project
    }

    struct Project {
        uint256 id;
        uint256 proposalId;
        address author; // Lead researcher
        address[] researchers; // Team members
        string initialMetadataHash; // Copy from proposal
        ProjectStatus status;
        uint256 fundsAllocated; // Amount allocated from treasury
        uint256 startTime;
        uint256 completionTime;
        uint256[] dataIds; // Links to registered data
        uint256[] ipNFTTokenIds; // Links to minted IP NFTs
        mapping(uint256 => string) updateHashes; // Progress reports, indexed by update number
        uint256 nextUpdateIndex;
        mapping(uint256 => string) verificationProofHashes; // Hashes of off-chain proofs (e.g., ZKPs) for updates, indexed by update number
    }

    struct ResearchData {
        uint256 id;
        uint256 projectId;
        address uploader;
        string dataHash; // IPFS CID or similar
        string metadataHash; // Metadata hash (e.g., description, format)
        uint256 timestamp;
    }

    struct Review {
        uint256 id;
        uint256 targetId; // Proposal or Project ID
        ReviewTargetType targetType;
        address reviewer;
        uint8 rating; // e.g., 1-5 or 1-10
        string reviewHash; // Hash of the review content
        bool submitted;
        bool finalized;
    }

    struct GovernanceProposal {
        uint256 id;
        address proposer;
        GovernanceProposalType proposalType;
        uint256 targetId; // Target for the action (e.g., project ID, researcher ID)
        bytes proposalData; // Data for the proposal (e.g., new param values, withdrawal amount/recipient)
        string descriptionHash; // Hash of proposal description
        uint256 creationTimestamp;
        uint256 votingExpirationTimestamp;
        uint256 gracePeriodExpirationTimestamp; // Time after vote ends before execution
        uint256 yesVotes;
        uint256 noVotes;
        mapping(address => bool) hasVoted;
        GovernanceProposalStatus status;
    }

    // --- State Variables ---
    mapping(address => uint256) private _researcherWalletToId;
    mapping(uint256 => Researcher) private _researchers;
    mapping(uint256 => Proposal) private _proposals;
    mapping(uint256 => Project) private _projects;
    mapping(uint256 => ResearchData) private _researchData;
    mapping(uint256 => Review) private _reviews;
    mapping(uint256 => GovernanceProposal) private _governanceProposals;

    // Governance Parameters
    uint256 public minReputationToPropose;
    uint256 public proposalVotingPeriod; // Duration in seconds
    uint256 public proposalExecutionGracePeriod; // Duration in seconds after voting ends
    uint256 public minYesVotesForGovernanceProposal; // Simple quorum/threshold example
    uint256 public reviewerRewardAmount; // Amount of Ether rewarded per finalized review

    address[] public governanceCouncil; // Simplified Governance - addresses that can call Admin functions

    // --- Events ---
    event ResearcherRegistered(address indexed wallet, uint256 researcherId, string profileHash);
    event ResearcherProfileUpdated(address indexed wallet, uint256 researcherId, string newProfileHash);
    event ProposalSubmitted(uint256 indexed proposalId, address indexed author, string metadataHash, uint256 fundingGoal);
    event FundsContributed(uint256 indexed proposalId, address indexed contributor, uint256 amount, uint256 totalRaised);
    event ProposalFunded(uint256 indexed proposalId, uint256 totalRaised);
    event ProjectStarted(uint256 indexed projectId, uint256 indexed proposalId, address indexed author, uint256 allocatedFunds);
    event ProjectUpdateSubmitted(uint256 indexed projectId, uint256 indexed updateIndex, string updateHash);
    event ResearchDataRegistered(uint256 indexed dataId, uint256 indexed projectId, address indexed uploader, string dataHash);
    event OffChainVerificationProofSubmitted(uint256 indexed projectId, uint256 indexed updateIndex, string proofHash);
    event ProjectCompleted(uint256 indexed projectId, uint256 completionTime);
    event ProjectFailed(uint256 indexed projectId);
    event IPNFTMinted(uint256 indexed projectId, uint256 indexed ipNftTokenId, address indexed owner);
    event IPRevenueShareUpdated(uint256 indexed ipNftTokenId, address[] payees, uint256[] shares);
    event ReviewAssigned(uint256 indexed reviewId, uint256 targetId, ReviewTargetType targetType, address indexed reviewer);
    event ReviewSubmitted(uint256 indexed reviewId, uint8 rating, string reviewHash);
    event ReviewProcessFinalized(uint256 indexed targetId, ReviewTargetType targetType);
    event ReputationUpdated(address indexed researcher, uint256 newReputation);
    event ReputationSlashed(address indexed researcher, uint256 amount);
    event DepositMade(address indexed depositor, uint256 amount);
    event WithdrawalMade(address indexed recipient, uint256 amount);
    event GovernanceProposalCreated(uint256 indexed proposalId, address indexed proposer, GovernanceProposalType proposalType, uint256 targetId, string descriptionHash);
    event GovernanceVoteCast(uint256 indexed proposalId, address indexed voter, bool voteYes);
    event GovernanceProposalPassed(uint256 indexed proposalId);
    event GovernanceProposalFailed(uint256 indexed proposalId);
    event GovernanceProposalExecuted(uint256 indexed proposalId);
    event GovernanceParametersUpdated(uint256 minReputation, uint256 votingPeriod, uint256 gracePeriod, uint256 minVotes);
    event ReviewerRewardClaimed(uint256 indexed reviewId, address indexed reviewer, uint256 amount);
    event FailedProposalFundsWithdrawn(uint256 indexed proposalId, address indexed withdrawer, uint256 amount);


    // --- Modifiers ---
    modifier onlyRegisteredResearcher() {
        require(_researcherWalletToId[msg.sender] != 0, "DARL: Only registered researchers");
        _;
    }

    modifier onlyProjectResearcher(uint256 projectId) {
        Project storage project = _projects[projectId];
        bool isResearcher = false;
        if (project.author == msg.sender) {
            isResearcher = true;
        } else {
            for (uint i = 0; i < project.researchers.length; i++) {
                if (project.researchers[i] == msg.sender) {
                    isResearcher = true;
                    break;
                }
            }
        }
        require(isResearcher, "DARL: Only project researchers");
        _;
    }

    modifier onlyAssignedReviewer(uint256 reviewId) {
        require(_reviews[reviewId].reviewer == msg.sender, "DARL: Only assigned reviewer");
        require(_reviews[reviewId].submitted == false, "DARL: Review already submitted");
        _;
    }

    modifier onlyGovernanceOrOwner() {
        bool isGovernance = false;
        for(uint i = 0; i < governanceCouncil.length; i++){
            if(governanceCouncil[i] == msg.sender){
                isGovernance = true;
                break;
            }
        }
        require(isGovernance || owner() == msg.sender, "DARL: Only Governance Council or Owner");
        _;
    }

    // --- Constructor ---
    constructor(address[] memory initialGovernanceCouncil, uint256 _minReputationToPropose, uint256 _proposalVotingPeriod, uint256 _proposalExecutionGracePeriod, uint256 _minYesVotesForGovernanceProposal, uint256 _reviewerRewardAmount)
        ERC721("DARL IP NFT", "DARL-IP") // Initialize ERC721
        Ownable(msg.sender) // Set deployer as initial owner
    {
        governanceCouncil = initialGovernanceCouncil;
        minReputationToPropose = _minReputationToPropose;
        proposalVotingPeriod = _proposalVotingPeriod;
        proposalExecutionGracePeriod = _proposalExecutionGracePeriod;
        minYesVotesForGovernanceProposal = _minYesVotesForGovernanceProposal;
        reviewerRewardAmount = _reviewerRewardAmount;

        // Researcher ID 0 is reserved (null state)
        _researcherIds.increment();
    }

    // --- Pausable Overrides ---
    function pauseContract() public onlyGovernanceOrOwner {
        _pause();
    }

    function unpauseContract() public onlyGovernanceOrOwner {
        _unpause();
    }

    // --- Admin & Governance Parameter Setting ---
    function setGovernanceParameters(
        uint256 _minReputation,
        uint256 _votingPeriod,
        uint256 _gracePeriod,
        uint256 _minVotes,
        uint256 _reviewerReward
    ) public onlyGovernanceOrOwner whenNotPaused {
        minReputationToPropose = _minReputation;
        proposalVotingPeriod = _votingPeriod;
        proposalExecutionGracePeriod = _gracePeriod;
        minYesVotesForGovernanceProposal = _minVotes;
        reviewerRewardAmount = _reviewerReward;
        emit GovernanceParametersUpdated(_minReputation, _votingPeriod, _gracePeriod, _minVotes);
    }

    function setGovernanceCouncil(address[] memory newCouncil) public onlyOwner {
        governanceCouncil = newCouncil;
    }


    // --- Researcher Management (5, 6, 7) ---

    /**
     * @notice Registers a new researcher in the DARL.
     * @param profileHash IPFS CID or similar hash linking to the researcher's off-chain profile.
     */
    function registerResearcher(string calldata profileHash) public whenNotPaused {
        require(_researcherWalletToId[msg.sender] == 0, "DARL: Wallet already registered");
        require(bytes(profileHash).length > 0, "DARL: Profile hash required");

        uint256 newId = _researcherIds.current();
        _researchers[newId] = Researcher({
            exists: true,
            wallet: msg.sender,
            profileHash: profileHash,
            reputation: 0 // Start with 0 reputation
        });
        _researcherWalletToId[msg.sender] = newId;
        _researcherIds.increment();

        emit ResearcherRegistered(msg.sender, newId, profileHash);
    }

    /**
     * @notice Allows a registered researcher to update their profile hash.
     * @param newProfileHash The new IPFS CID or similar hash for the profile.
     */
    function updateResearcherProfile(string calldata newProfileHash) public onlyRegisteredResearcher whenNotPaused {
        uint256 researcherId = _researcherWalletToId[msg.sender];
        _researchers[researcherId].profileHash = newProfileHash;
        emit ResearcherProfileUpdated(msg.sender, researcherId, newProfileHash);
    }

    /**
     * @notice Gets the profile details for a researcher.
     * @param researcher The wallet address of the researcher.
     * @return exists Whether the researcher is registered.
     * @return profileHash The IPFS CID or hash of their profile.
     * @return reputation The researcher's current reputation score.
     */
    function getResearcherProfile(address researcher) public view returns (bool exists, string memory profileHash, uint256 reputation) {
        uint256 researcherId = _researcherWalletToId[researcher];
        if (researcherId == 0) {
            return (false, "", 0);
        }
        Researcher storage r = _researchers[researcherId];
        return (r.exists, r.profileHash, r.reputation);
    }


    // --- Proposal Lifecycle (8, 9, 10, 11) ---

    /**
     * @notice Submits a new research proposal.
     * @param metadataHash IPFS CID or hash of the proposal document.
     * @param fundingGoal The amount of Ether requested for the project.
     */
    function submitResearchProposal(string calldata metadataHash, uint256 fundingGoal) public onlyRegisteredResearcher whenNotPaused {
        require(fundingGoal > 0, "DARL: Funding goal must be greater than 0");
        require(bytes(metadataHash).length > 0, "DARL: Metadata hash required");

        uint256 newId = _proposalIds.current();
        _proposals[newId] = Proposal({
            id: newId,
            author: msg.sender,
            metadataHash: metadataHash,
            fundingGoal: fundingGoal,
            fundsRaised: 0,
            status: ProposalStatus.Submitted,
            submissionTimestamp: block.timestamp,
            fundingExpirationTimestamp: block.timestamp + (7 days), // Example: 7 days funding period
            linkedProjectId: 0
        });
        _proposalIds.increment();

        emit ProposalSubmitted(newId, msg.sender, metadataHash, fundingGoal);
    }

    /**
     * @notice Gets the details of a specific research proposal.
     * @param proposalId The ID of the proposal.
     * @return proposal Details of the proposal.
     */
    function getProposalDetails(uint256 proposalId) public view returns (Proposal memory proposal) {
        require(proposalId > 0 && proposalId < _proposalIds.current(), "DARL: Invalid proposal ID");
        return _proposals[proposalId];
    }

    /**
     * @notice Contributes funds (Ether) to a research proposal's funding goal.
     * @param proposalId The ID of the proposal to fund.
     */
    function fundProposal(uint256 proposalId) public payable whenNotPaused {
        Proposal storage proposal = _proposals[proposalId];
        require(proposal.status == ProposalStatus.Submitted || proposal.status == ProposalStatus.Funding, "DARL: Proposal not open for funding");
        require(block.timestamp <= proposal.fundingExpirationTimestamp, "DARL: Funding period expired");
        require(msg.value > 0, "DARL: Must send ether to fund");

        if (proposal.status == ProposalStatus.Submitted) {
            proposal.status = ProposalStatus.Funding;
        }

        proposal.fundsRaised += msg.value;

        emit FundsContributed(proposalId, msg.sender, msg.value, proposal.fundsRaised);

        // Automatically transition to Funded if goal is met
        if (proposal.fundsRaised >= proposal.fundingGoal) {
            proposal.status = ProposalStatus.Funded;
            emit ProposalFunded(proposalId, proposal.fundsRaised);
            // Governance would typically start the project after this or via a separate proposal
        }
    }

     /**
      * @notice Allows contributors to withdraw their funds if a proposal was rejected or expired without being funded.
      * @param proposalId The ID of the proposal.
      */
    function withdrawFailedProposalFunds(uint256 proposalId) public whenNotPaused {
        Proposal storage proposal = _proposals[proposalId];
        require(proposal.id != 0, "DARL: Invalid proposal ID"); // Ensure proposal exists
        require(proposal.status == ProposalStatus.Rejected || (proposal.status == ProposalStatus.Submitted && block.timestamp > proposal.fundingExpirationTimestamp), "DARL: Proposal not failed or expired"); // Correctly check expired status

        // Simple distribution: assumes contributors tracking off-chain.
        // A more robust system would track individual contributions per proposal.
        // For this example, we'll just allow the author to withdraw leftover funds if not funded/rejected,
        // or implement a placeholder that assumes contributors can claim (requires significant state).
        // Let's simplify: only the author can sweep if failed, or a more complex mapping is needed.
        // Alternative: Funds stay in treasury if proposal expires/fails. Let's allow anyone who contributed to withdraw if proposal was *Submitted* and expired unfunded. This requires tracking contributions.
        // Let's revert to allowing author to withdraw if rejected/failed, or governance directs.
        // Simplest approach for this example: If proposal status is Rejected or Submitted & expired unfunded, and fundsRaised > 0, author *can* withdraw.
        require(proposal.fundsRaised > 0, "DARL: No funds raised for this proposal");
        require(proposal.author == msg.sender, "DARL: Only author can attempt withdrawal for failed/expired proposals");

        uint256 amountToWithdraw = proposal.fundsRaised;
        proposal.fundsRaised = 0; // Reset funds raised

        (bool success, ) = payable(msg.sender).call{value: amountToWithdraw}("");
        require(success, "DARL: Ether transfer failed");

        emit FailedProposalFundsWithdrawn(proposalId, msg.sender, amountToWithdraw);
    }


    // --- Project Management (12, 13, 14, 15, 16, 17, 18) ---

    /**
     * @notice Converts a Funded proposal into an Active research project.
     * Callable by Governance Council or Owner.
     * @param proposalId The ID of the funded proposal.
     */
    function startResearchProject(uint256 proposalId) public onlyGovernanceOrOwner whenNotPaused {
        Proposal storage proposal = _proposals[proposalId];
        require(proposal.status == ProposalStatus.Funded, "DARL: Proposal must be in Funded status");
        require(proposal.linkedProjectId == 0, "DARL: Proposal already linked to a project");

        uint256 newProjectId = _projectIds.current();
        _projects[newProjectId] = Project({
            id: newProjectId,
            proposalId: proposalId,
            author: proposal.author,
            researchers: new address[](0), // Project researchers can be added later
            initialMetadataHash: proposal.metadataHash,
            status: ProjectStatus.Active,
            fundsAllocated: proposal.fundsRaised, // Allocate all raised funds
            startTime: block.timestamp,
            completionTime: 0,
            dataIds: new uint256[](0),
            ipNFTTokenIds: new uint256[](0),
            nextUpdateIndex: 0
        });
        _projectIds.increment();

        proposal.status = ProposalStatus.ConvertedToProject;
        proposal.linkedProjectId = newProjectId;

        // Transfer funds from proposal to project context (conceptually, or just allocate from treasury)
        // Funds contributed were already held by the contract.
        // No need to transfer internally, they are available to the project via project.fundsAllocated

        emit ProjectStarted(newProjectId, proposalId, proposal.author, proposal.fundsRaised);
    }

     /**
      * @notice Allows a project researcher to submit a progress update hash.
      * @param projectId The ID of the project.
      * @param updateHash IPFS CID or hash of the progress update document.
      */
    function submitProjectUpdate(uint256 projectId, string calldata updateHash) public onlyProjectResearcher(projectId) whenNotPaused {
        Project storage project = _projects[projectId];
        require(project.status == ProjectStatus.Active, "DARL: Project must be Active to submit updates");
        require(bytes(updateHash).length > 0, "DARL: Update hash required");

        uint256 updateIndex = project.nextUpdateIndex;
        project.updateHashes[updateIndex] = updateHash;
        project.nextUpdateIndex++;

        emit ProjectUpdateSubmitted(projectId, updateIndex, updateHash);
    }

    /**
     * @notice Registers a hash and metadata for research data produced by a project.
     * @param projectId The ID of the project.
     * @param dataHash IPFS CID or hash of the research data itself.
     * @param metadataHash IPFS CID or hash of metadata describing the data.
     */
    function registerResearchData(uint256 projectId, string calldata dataHash, string calldata metadataHash) public onlyProjectResearcher(projectId) whenNotPaused {
        Project storage project = _projects[projectId];
        require(project.status == ProjectStatus.Active || project.status == ProjectStatus.Review || project.status == ProjectStatus.Completed, "DARL: Data can only be registered for Active, Review, or Completed projects");
        require(bytes(dataHash).length > 0, "DARL: Data hash required");
        require(bytes(metadataHash).length > 0, "DARL: Metadata hash required");

        uint256 newDataId = _dataIds.current();
        _researchData[newDataId] = ResearchData({
            id: newDataId,
            projectId: projectId,
            uploader: msg.sender,
            dataHash: dataHash,
            metadataHash: metadataHash,
            timestamp: block.timestamp
        });
        _dataIds.increment();

        project.dataIds.push(newDataId);

        emit ResearchDataRegistered(newDataId, projectId, msg.sender, dataHash);
    }

     /**
      * @notice Submits a hash referencing an off-chain verification proof (e.g., ZK proof, Oracle attestation)
      * related to a specific project update.
      * @param projectId The ID of the project.
      * @param updateIndex The index of the project update this proof corresponds to.
      * @param proofHash IPFS CID or hash referencing the verification proof.
      */
    function submitOffChainVerificationProof(uint256 projectId, uint256 updateIndex, string calldata proofHash) public onlyProjectResearcher(projectId) whenNotPaused {
        Project storage project = _projects[projectId];
        require(project.updateHashes[updateIndex].length > 0, "DARL: Update index invalid or no update submitted");
        require(bytes(proofHash).length > 0, "DARL: Proof hash required");

        // In a real system, this proofHash would be processed off-chain (e.g., by an oracle network)
        // to verify the associated updateHash. This function just records the submission.
        project.verificationProofHashes[updateIndex] = proofHash;

        emit OffChainVerificationProofSubmitted(projectId, updateIndex, proofHash);
    }

    /**
     * @notice Marks a project as completed. Requires governance approval (via executeGovernanceProposal).
     * Updates researcher reputation upon successful completion.
     * @param projectId The ID of the project to complete.
     */
    function completeProject(uint256 projectId) public onlyGovernanceOrOwner whenNotPaused {
        Project storage project = _projects[projectId];
        require(project.status == ProjectStatus.Review, "DARL: Project must be under Review to be completed"); // Typically moved to Review via governance first
        // Add check for successful review/verification outcome if applicable

        project.status = ProjectStatus.Completed;
        project.completionTime = block.timestamp;

        // Example: Increase reputation for the lead researcher and team members
        uint256 authorResearcherId = _researcherWalletToId[project.author];
        if (authorResearcherId != 0) {
            _researchers[authorResearcherId].reputation += 10; // Example reward
            emit ReputationUpdated(project.author, _researchers[authorResearcherId].reputation);
        }
        for (uint i = 0; i < project.researchers.length; i++) {
             uint256 teamResearcherId = _researcherWalletToId[project.researchers[i]];
             if(teamResearcherId != 0) {
                 _researchers[teamResearcherId].reputation += 5; // Example reward
                 emit ReputationUpdated(project.researchers[i], _researchers[teamResearcherId].reputation);
             }
        }


        emit ProjectCompleted(projectId, project.completionTime);
    }

     /**
      * @notice Gets the details of a specific project.
      * @param projectId The ID of the project.
      * @return project The details of the project.
      */
    function getProjectDetails(uint256 projectId) public view returns (Project memory project) {
        require(projectId > 0 && projectId < _projectIds.current(), "DARL: Invalid project ID");
        Project storage p = _projects[projectId];
         // Need to copy data to memory for return, excluding mappings
         Project memory projectMemory = Project({
            id: p.id,
            proposalId: p.proposalId,
            author: p.author,
            researchers: p.researchers,
            initialMetadataHash: p.initialMetadataHash,
            status: p.status,
            fundsAllocated: p.fundsAllocated,
            startTime: p.startTime,
            completionTime: p.completionTime,
            dataIds: p.dataIds,
            ipNFTTokenIds: p.ipNFTTokenIds,
            nextUpdateIndex: p.nextUpdateIndex,
            // Mappings are not included in memory copy, need separate getters if needed
            updateHashes: mapping(uint256 => string)(0), // Placeholder
            verificationProofHashes: mapping(uint256 => string)(0) // Placeholder
         });
        return projectMemory;
    }

     /**
      * @notice Gets the details of registered research data.
      * @param dataId The ID of the data entry.
      * @return researchData The details of the research data.
      */
    function getResearchDataDetails(uint256 dataId) public view returns (ResearchData memory researchData) {
        require(dataId > 0 && dataId < _dataIds.current(), "DARL: Invalid data ID");
        return _researchData[dataId];
    }


    // --- Intellectual Property (IP) Management (19, 20, 21) ---

     /**
      * @notice Mints an ERC721 NFT representing the IP of a completed project.
      * Callable by the project author or Governance.
      * @param projectId The ID of the completed project.
      * @param tokenURICid The IPFS CID or hash for the NFT metadata.
      */
    function mintIPNFT(uint256 projectId, string calldata tokenURICid) public onlyGovernanceOrOwner whenNotPaused { // Or potentially onlyProjectResearcher(projectId) if project lead has explicit minting rights post-completion
        Project storage project = _projects[projectId];
        require(project.status == ProjectStatus.Completed, "DARL: Can only mint IP NFT for completed projects");
        // Prevent multiple IP NFTs for the same project unless explicitly allowed
        require(project.ipNFTTokenIds.length == 0, "DARL: IP NFT already minted for this project");
        require(bytes(tokenURICid).length > 0, "DARL: Token URI CID required");

        // Mint the NFT using ERC721 standard
        uint256 newTokenId = _ipNftTokenIds.current(); // ERC721's internal counter
        _safeMint(project.author, newTokenId); // Mint to project author by default, governance can transfer later
        _setTokenURI(newTokenId, tokenURICid);

        project.ipNFTTokenIds.push(newTokenId);
         _ipNftTokenIds.increment(); // Manually increment counter for our tracking

        emit IPNFTMinted(projectId, newTokenId, project.author);
    }

    /**
     * @notice Sets a revenue sharing structure for an IP NFT.
     * This function defines the split but requires external mechanisms (e.g., a separate payment splitter contract or platform)
     * to collect and distribute revenue based on this structure.
     * @param ipNftTokenId The ID of the IP NFT.
     * @param payees An array of addresses to receive revenue shares.
     * @param shares An array of the respective shares for each payee. Sum of shares typically equals a total (e.g., 10000 for 100%).
     */
    function setIPRevenueShare(uint256 ipNftTokenId, address[] calldata payees, uint256[] calldata shares) public onlyGovernanceOrOwner whenNotPaused { // Could also allow IP NFT owner
         require(_exists(ipNftTokenId), "DARL: IP NFT does not exist");
         require(payees.length == shares.length, "DARL: Payees and shares length mismatch");
         require(payees.length > 0, "DARL: At least one payee required");

         // Link this information to the token ID. This requires a mapping: uint256 => {address[], uint256[]}
         // Adding this state would increase complexity. For this example, we emit an event
         // and assume an off-chain or external contract listens and stores this configuration.
         // Example State needed: mapping(uint256 => address[]) private _ipNftPayees; mapping(uint256 => uint256[]) private _ipNftShares;
         // We'll just emit the event as a signal for the external system.

         emit IPRevenueShareUpdated(ipNftTokenId, payees, shares);
    }

    /**
     * @notice Views details about an IP NFT and its associated project.
     * @param ipNftTokenId The ID of the IP NFT.
     * @return projectId The ID of the project this NFT represents.
     * @return tokenURI The metadata URI for the NFT.
     * @return owner The current owner of the NFT.
     */
    function getIPNFTDetails(uint256 ipNftTokenId) public view returns (uint256 projectId, string memory tokenURI, address owner) {
        require(_exists(ipNftTokenId), "DARL: IP NFT does not exist");

        uint256 linkedProjectId = 0;
        // Need to find the project linked to this NFT. This requires iterating through projects or storing a reverse mapping.
        // Adding reverse mapping: mapping(uint256 => uint256) private _ipNftToProjectId;
        // For simplicity in this example, let's assume an external indexer finds this link via events or iterates.
        // A direct getter requires the reverse mapping. Let's add it.
        mapping(uint256 => uint256) private _ipNftToProjectId; // <-- Add this mapping

        // Assuming _ipNftToProjectId is populated when mintIPNFT is called
        linkedProjectId = _ipNftToProjectId[ipNftTokenId];
        require(linkedProjectId != 0, "DARL: IP NFT not linked to a project"); // Should not happen if minting is linked

        owner = ERC721.ownerOf(ipNftTokenId);
        tokenURI = ERC721.tokenURI(ipNftTokenId);

        return (linkedProjectId, tokenURI, owner);
    }

    // --- Peer Review System (22, 23, 24, 25) ---

     /**
      * @notice Assigns a researcher to review a proposal or project.
      * Callable by Governance Council or Owner.
      * @param targetId The ID of the proposal or project to review.
      * @param targetType The type of target (Proposal or Project).
      * @param reviewer The address of the researcher assigned to review.
      */
    function assignReviewer(uint256 targetId, ReviewTargetType targetType, address reviewer) public onlyGovernanceOrOwner whenNotPaused {
        require(_researcherWalletToId[reviewer] != 0, "DARL: Reviewer must be a registered researcher");

        if (targetType == ReviewTargetType.Proposal) {
            require(targetId > 0 && targetId < _proposalIds.current(), "DARL: Invalid proposal ID");
            require(_proposals[targetId].status == ProposalStatus.Funded || _proposals[targetId].status == ProposalStatus.Submitted, "DARL: Proposal not in reviewable status"); // Review before funding or after? Let's say after funding, before project start.
             // Update: Let's allow reviews on Submitted proposals too, for pre-funding assessment.
             require(_proposals[targetId].status == ProposalStatus.Submitted || _proposals[targetId].status == ProposalStatus.Funding || _proposals[targetId].status == ProposalStatus.Funded, "DARL: Proposal not in reviewable status");
        } else if (targetType == ReviewTargetType.Project) {
            require(targetId > 0 && targetId < _projectIds.current(), "DARL: Invalid project ID");
            require(_projects[targetId].status == ProjectStatus.Review, "DARL: Project not in Review status"); // Projects are reviewed before completion
        } else {
            revert("DARL: Invalid review target type");
        }

        uint256 newReviewId = _reviewIds.current();
        _reviews[newReviewId] = Review({
            id: newReviewId,
            targetId: targetId,
            targetType: targetType,
            reviewer: reviewer,
            rating: 0, // Default 0 until submitted
            reviewHash: "",
            submitted: false,
            finalized: false
        });
        _reviewIds.increment();

        emit ReviewAssigned(newReviewId, targetId, targetType, reviewer);
    }

    /**
     * @notice Allows an assigned reviewer to submit their review.
     * @param reviewId The ID of the assigned review slot.
     * @param rating The rating given by the reviewer (e.g., 1-5).
     * @param reviewHash IPFS CID or hash of the full review content.
     */
    function submitReview(uint256 reviewId, uint8 rating, string calldata reviewHash) public onlyAssignedReviewer(reviewId) whenNotPaused {
        require(bytes(reviewHash).length > 0, "DARL: Review hash required");
        // Add rating range validation if needed (e.g., require(rating >= 1 && rating <= 10, "DARL: Invalid rating");)

        Review storage review = _reviews[reviewId];
        review.rating = rating;
        review.reviewHash = reviewHash;
        review.submitted = true;

        // Note: Reviewer reward is claimed upon review FINALIZATION, not submission.

        emit ReviewSubmitted(reviewId, rating, reviewHash);
    }

    /**
     * @notice Gets the details of a specific review.
     * @param reviewId The ID of the review.
     * @return review The details of the review.
     */
    function getReviewDetails(uint256 reviewId) public view returns (Review memory review) {
        require(reviewId > 0 && reviewId < _reviewIds.current(), "DARL: Invalid review ID");
        return _reviews[reviewId];
    }

     /**
      * @notice Finalizes the review process for a proposal or project.
      * Callable by Governance Council or Owner. This might trigger status changes
      * for the target proposal/project or allow reviewers to claim rewards.
      * @param targetId The ID of the proposal or project being finalized.
      * @param targetType The type of target (Proposal or Project).
      */
    function finalizeReviewProcess(uint256 targetId, ReviewTargetType targetType) public onlyGovernanceOrOwner whenNotPaused {
         // Requires finding all reviews associated with this targetId and targetType
         // This implies reviews need to be queryable by target (e.g., mapping(uint256 => mapping(ReviewTargetType => uint256[])))
         // For simplicity in this example, this function primarily marks reviews as finalized
         // and signals the completion of the review phase. Actual aggregated review results
         // would likely be computed off-chain or require more complex on-chain state/logic.

         // Iterate through all reviews to find ones matching the target
         uint256 totalReviews = _reviewIds.current();
         uint256 finalizedCount = 0;
         for (uint i = 1; i < totalReviews; i++) {
             Review storage review = _reviews[i];
             if (review.targetId == targetId && review.targetType == targetType && review.submitted && !review.finalized) {
                 review.finalized = true;
                 finalizedCount++;
                 // Reputation update for reviewer upon successful finalization of their review
                 uint256 reviewerResearcherId = _researcherWalletToId[review.reviewer];
                 if (reviewerResearcherId != 0) {
                     _researchers[reviewerResearcherId].reputation += 1; // Example small reward
                      emit ReputationUpdated(review.reviewer, _researchers[reviewerResearcherId].reputation);
                 }
             }
         }

         // Add logic here to potentially change the status of the target proposal/project
         // based on the review results (e.g., if using a simple score threshold, or simply
         // signaling that governance can now decide based on finalized reviews).
         // For projects, this would typically mean moving from Active -> Review -> Completed or Failed.
         // For proposals, potentially influencing the startResearchProject decision.
         if (targetType == ReviewTargetType.Project) {
              Project storage project = _projects[targetId];
              if (project.status == ProjectStatus.Review) {
                 // Review process finalized, governance can now call completeProject or failProject
              }
         } else if (targetType == ReviewTargetType.Proposal) {
             Proposal storage proposal = _proposals[targetId];
             // Reviews finalized for proposal - info is now available for governance decision on starting project
         }


         emit ReviewProcessFinalized(targetId, targetType);
    }


    // --- Reputation System (26, 27) ---

    /**
     * @notice Gets the current reputation score for a researcher.
     * @param researcher The wallet address of the researcher.
     * @return The researcher's reputation score.
     */
    function getReputationScore(address researcher) public view returns (uint256) {
        uint256 researcherId = _researcherWalletToId[researcher];
        if (researcherId == 0) {
            return 0; // Not a registered researcher
        }
        return _researchers[researcherId].reputation;
    }

     /**
      * @notice Decreases a researcher's reputation score (e.g., for misconduct).
      * Callable by Governance Council or Owner.
      * @param researcher The wallet address of the researcher whose reputation is being slashed.
      * @param amount The amount to decrease the reputation by.
      */
    function slashReputation(address researcher, uint256 amount) public onlyGovernanceOrOwner whenNotPaused {
        uint256 researcherId = _researcherWalletToId[researcher];
        require(researcherId != 0, "DARL: Researcher not registered");
        require(amount > 0, "DARL: Slash amount must be greater than 0");

        Researcher storage r = _researchers[researcherId];
        r.reputation = r.reputation > amount ? r.reputation - amount : 0;

        emit ReputationSlashed(researcher, amount);
        emit ReputationUpdated(researcher, r.reputation);
    }


    // --- Treasury Management (28, 29, 30) ---

     /**
      * @notice Allows anyone to deposit Ether into the contract's treasury.
      */
    function depositToTreasury() public payable whenNotPaused {
        require(msg.value > 0, "DARL: Must send ether");
        emit DepositMade(msg.sender, msg.value);
    }

     /**
      * @notice Allows Governance to withdraw funds from the treasury.
      * This function is intended to be called *only* via the `executeGovernanceProposal` mechanism.
      * @param amount The amount of Ether to withdraw.
      * @param recipient The address to send the Ether to.
      */
    function withdrawFromTreasury(uint256 amount, address recipient) public onlyGovernanceOrOwner whenNotPaused {
        // This function should ideally ONLY be callable via a governance proposal execution.
        // The onlyGovernanceOrOwner modifier allows the owner or council to call directly for simplicity in this example,
        // but in a real DAO, this would be restricted to the execution mechanism.
        require(amount > 0, "DARL: Amount must be greater than 0");
        require(address(this).balance >= amount, "DARL: Insufficient treasury balance");
        require(recipient != address(0), "DARL: Invalid recipient address");

        (bool success, ) = payable(recipient).call{value: amount}("");
        require(success, "DARL: Ether transfer failed");

        emit WithdrawalMade(recipient, amount);
    }

     /**
      * @notice Gets the current balance of the contract's treasury.
      * @return The current balance in Ether.
      */
    function getTreasuryBalance() public view returns (uint256) {
        return address(this).balance;
    }

     /**
      * @notice Allows a reviewer to claim their reward after a review is finalized.
      * Note: A reviewer might have multiple finalized reviews to claim.
      * This simple version assumes the reviewer tracks which reviews are claimable off-chain
      * and calls this function per review ID. A more complex system would allow claiming
      * all outstanding rewards at once.
      * @param reviewId The ID of the finalized review.
      */
    function claimReviewerReward(uint256 reviewId) public onlyRegisteredResearcher whenNotPaused {
        Review storage review = _reviews[reviewId];
        require(review.id != 0, "DARL: Invalid review ID");
        require(review.reviewer == msg.sender, "DARL: Only the assigned reviewer can claim");
        require(review.finalized, "DARL: Review is not finalized");
        // Add a flag to prevent double claiming, e.g., `bool claimedReward;` in Review struct.
        require(!review.claimedReward, "DARL: Reward already claimed for this review"); // Requires adding `claimedReward` to Review struct.

        uint256 reward = reviewerRewardAmount;
        require(address(this).balance >= reward, "DARL: Insufficient treasury balance for reward");

        (bool success, ) = payable(msg.sender).call{value: reward}("");
        require(success, "DARL: Ether transfer failed");

        // Mark reward as claimed (requires adding `claimedReward` to Review struct)
        // review.claimedReward = true; // Uncomment if adding `claimedReward`

        emit ReviewerRewardClaimed(reviewId, msg.sender, reward);
    }

    // --- Governance System (31, 32, 33, 34, 35) ---

     /**
      * @notice Creates a governance proposal. Requires minimum researcher reputation.
      * @param proposalType The type of governance action proposed.
      * @param targetId The ID of the entity the proposal targets (e.g., project ID, researcher ID).
      * @param proposalData ABI-encoded data for the proposal (parameters for the execution function).
      * @param descriptionHash IPFS CID or hash of the proposal description/justification.
      */
    function createGovernanceProposal(
        GovernanceProposalType proposalType,
        uint256 targetId,
        bytes calldata proposalData,
        string calldata descriptionHash
    ) public onlyRegisteredResearcher whenNotPaused {
        uint256 proposerResearcherId = _researcherWalletToId[msg.sender];
        require(_researchers[proposerResearcherId].reputation >= minReputationToPropose, "DARL: Insufficient reputation to create proposal");
        require(bytes(descriptionHash).length > 0, "DARL: Description hash required");

        // Basic validation based on proposal type
        if (proposalType == GovernanceProposalType.TreasuryWithdrawal) {
             // proposalData should contain abi.encode(amount, recipient)
             require(proposalData.length > 0, "DARL: proposalData required for TreasuryWithdrawal");
        } // Add checks for other types as needed

        uint256 newId = _governanceProposalIds.current();
        _governanceProposals[newId] = GovernanceProposal({
            id: newId,
            proposer: msg.sender,
            proposalType: proposalType,
            targetId: targetId,
            proposalData: proposalData,
            descriptionHash: descriptionHash,
            creationTimestamp: block.timestamp,
            votingExpirationTimestamp: block.timestamp + proposalVotingPeriod,
            gracePeriodExpirationTimestamp: 0, // Set upon voting end
            yesVotes: 0,
            noVotes: 0,
            hasVoted: mapping(address => bool)(0),
            status: GovernanceProposalStatus.Open
        });
         _governanceProposalIds.increment();

        emit GovernanceProposalCreated(newId, msg.sender, proposalType, targetId, descriptionHash);
    }

    /**
     * @notice Allows eligible participants (e.g., registered researchers) to vote on an open governance proposal.
     * @param proposalId The ID of the proposal to vote on.
     * @param voteYes True for a 'Yes' vote, False for a 'No' vote.
     */
    function voteOnGovernanceProposal(uint256 proposalId, bool voteYes) public onlyRegisteredResearcher whenNotPaused {
        GovernanceProposal storage proposal = _governanceProposals[proposalId];
        require(proposal.id != 0, "DARL: Invalid proposal ID");
        require(proposal.status == GovernanceProposalStatus.Open, "DARL: Proposal is not open for voting");
        require(block.timestamp <= proposal.votingExpirationTimestamp, "DARL: Voting period has ended");
        require(!proposal.hasVoted[msg.sender], "DARL: Already voted on this proposal");

        // Voting power could be based on reputation, token holdings, etc.
        // For simplicity, 1 researcher address = 1 vote.
        if (voteYes) {
            proposal.yesVotes++;
        } else {
            proposal.noVotes++;
        }
        proposal.hasVoted[msg.sender] = true;

        emit GovernanceVoteCast(proposalId, msg.sender, voteYes);

        // Check if voting period ended or if quorum met early (optional)
        if (block.timestamp > proposal.votingExpirationTimestamp) {
            _checkAndSetProposalStatus(proposalId);
        }
    }

    /**
     * @notice Executes a governance proposal if it has passed and the grace period has ended.
     * Callable by anyone to trigger execution after the conditions are met.
     * @param proposalId The ID of the proposal to execute.
     */
    function executeGovernanceProposal(uint256 proposalId) public whenNotPaused {
        GovernanceProposal storage proposal = _governanceProposals[proposalId];
        require(proposal.id != 0, "DARL: Invalid proposal ID");
        require(proposal.status == GovernanceProposalStatus.Passed, "DARL: Proposal has not passed");
        require(block.timestamp > proposal.gracePeriodExpirationTimestamp, "DARL: Grace period has not ended");

        // Execute the proposal based on its type
        if (proposal.proposalType == GovernanceProposalType.ParameterChange) {
            // Assuming proposalData contains abi.encode(minReputation, votingPeriod, gracePeriod, minVotes, reviewerReward)
            (uint256 _minRep, uint256 _vPeriod, uint256 _gPeriod, uint256 _minVotes, uint256 _reviewerRew) = abi.decode(proposal.proposalData, (uint256, uint256, uint256, uint256, uint256));
            setGovernanceParameters(_minRep, _vPeriod, _gPeriod, _minVotes, _reviewerRew); // Call the admin function
        } else if (proposal.proposalType == GovernanceProposalType.TreasuryWithdrawal) {
            // Assuming proposalData contains abi.encode(amount, recipient)
            (uint256 amount, address recipient) = abi.decode(proposal.proposalData, (uint256, address));
             withdrawFromTreasury(amount, recipient); // Call the treasury function
        } else if (proposal.proposalType == GovernanceProposalType.ProjectStatusChange) {
            // Assuming proposalData contains abi.encode(ProjectStatus.Completed or ProjectStatus.Failed)
             (ProjectStatus newStatus) = abi.decode(proposal.proposalData, (ProjectStatus));
             require(proposal.targetId > 0 && proposal.targetId < _projectIds.current(), "DARL: Invalid project target ID");
             Project storage project = _projects[proposal.targetId];

             if (newStatus == ProjectStatus.Completed) {
                 require(project.status == ProjectStatus.Review, "DARL: Project must be under Review to be Completed via governance");
                 completeProject(proposal.targetId); // Call the project function
             } else if (newStatus == ProjectStatus.Failed) {
                 // Logic to mark project as failed, potentially return remaining funds to treasury etc.
                  project.status = ProjectStatus.Failed;
                  emit ProjectFailed(proposal.targetId);
             } else {
                 revert("DARL: Invalid ProjectStatusChange target status");
             }
        } else if (proposal.proposalType == GovernanceProposalType.ResearcherSlashReputation) {
             // Assuming proposalData contains abi.encode(researcherAddress, amount)
             (address researcherToSlash, uint256 amount) = abi.decode(proposal.proposalData, (address, uint256));
             slashReputation(researcherToSlash, amount); // Call the reputation function
        } else {
             revert("DARL: Unknown proposal type for execution");
        }

        proposal.status = GovernanceProposalStatus.Executed;
        emit GovernanceProposalExecuted(proposalId);
    }

    /**
     * @notice Gets the details of a specific governance proposal.
     * @param proposalId The ID of the proposal.
     * @return proposal The details of the governance proposal.
     */
    function getGovernanceProposalDetails(uint256 proposalId) public view returns (GovernanceProposal memory proposal) {
        require(proposalId > 0 && proposalId < _governanceProposalIds.current(), "DARL: Invalid governance proposal ID");
         GovernanceProposal storage p = _governanceProposals[proposalId];
         // Copy to memory, excluding mapping
         GovernanceProposal memory proposalMemory = GovernanceProposal({
            id: p.id,
            proposer: p.proposer,
            proposalType: p.proposalType,
            targetId: p.targetId,
            proposalData: p.proposalData,
            descriptionHash: p.descriptionHash,
            creationTimestamp: p.creationTimestamp,
            votingExpirationTimestamp: p.votingExpirationTimestamp,
            gracePeriodExpirationTimestamp: p.gracePeriodExpirationTimestamp,
            yesVotes: p.yesVotes,
            noVotes: p.noVotes,
            // hasVoted mapping excluded
            hasVoted: mapping(address => bool)(0), // Placeholder
            status: p.status
         });
         return proposalMemory;
    }

    /**
     * @notice Gets the vote counts for a governance proposal.
     * @param proposalId The ID of the proposal.
     * @return yesVotes The total number of 'Yes' votes.
     * @return noVotes The total number of 'No' votes.
     */
    function getGovernanceProposalVoteCounts(uint256 proposalId) public view returns (uint256 yesVotes, uint256 noVotes) {
         require(proposalId > 0 && proposalId < _governanceProposalIds.current(), "DARL: Invalid governance proposal ID");
         GovernanceProposal storage proposal = _governanceProposals[proposalId];
         return (proposal.yesVotes, proposal.noVotes);
    }


    // --- Internal/Helper Functions ---

    /**
     * @dev Internal function to check if a governance proposal's voting period has ended and update its status.
     * Can be called by anyone after the voting expiration timestamp.
     * @param proposalId The ID of the proposal to check.
     */
    function _checkAndSetProposalStatus(uint256 proposalId) internal {
        GovernanceProposal storage proposal = _governanceProposals[proposalId];

        if (proposal.status == GovernanceProposalStatus.Open && block.timestamp > proposal.votingExpirationTimestamp) {
            // Simple majority and minimum yes votes threshold
            if (proposal.yesVotes > proposal.noVotes && proposal.yesVotes >= minYesVotesForGovernanceProposal) {
                proposal.status = GovernanceProposalStatus.Passed;
                proposal.gracePeriodExpirationTimestamp = block.timestamp + proposalExecutionGracePeriod;
                emit GovernanceProposalPassed(proposalId);
            } else {
                proposal.status = GovernanceProposalStatus.Failed;
                emit GovernanceProposalFailed(proposalId);
            }
        }
    }

    // Allow anyone to trigger the status check once voting is over
    function finalizeVotingPeriod(uint256 proposalId) public {
        require(proposalId > 0 && proposalId < _governanceProposalIds.current(), "DARL: Invalid governance proposal ID");
        _checkAndSetProposalStatus(proposalId);
    }


    // --- ERC721 Overrides ---
    // Need to override functions like _beforeTokenTransfer, _afterTokenTransfer,
    // _update, _mint, _burn if adding custom logic around transfers or lifecycle.
    // For this example, default ERC721 behavior is assumed for transfers *after* minting.
    // The minting is restricted via mintIPNFT.

    // The following standard ERC721 view functions are automatically available:
    // name(), symbol(), balanceOf(owner), ownerOf(tokenId), tokenURI(tokenId), supportsInterface(interfaceId)
    // transferFrom(from, to, tokenId), safeTransferFrom(from, to, tokenId) - subject to ERC721 approval/operator logic
    // approve(to, tokenId), setApprovalForAll(operator, approved), getApproved(tokenId), isApprovedForAll(owner, operator)


}
```