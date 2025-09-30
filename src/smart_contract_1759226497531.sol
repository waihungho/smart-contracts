This smart contract, **Aetheria Nexus**, envisions a decentralized AI-driven innovation hub. It allows a community (DAO) to propose, fund, and manage R&D projects. A key differentiator is its integration with external AI models (via an oracle) for decision support, combined with dynamic intellectual property (IP) management where successful projects' IP is tokenized as NFTs, which can then be fractionalized and licensed, generating revenue for the DAO and contributors. A reputation system (non-transferable points) enhances governance beyond mere token holdings.

---

### **Aetheria Nexus: Decentralized AI-Driven Innovation Hub**

**Outline:**

1.  **Interfaces:** Standard ERC-20, ERC-721 interfaces for token interactions.
2.  **Enums:** Define states for projects, proposals, and AI outcomes.
3.  **Structs:** Data structures for `Proposal`, `Project`, `IPNFTDetails`, `LicenseAgreement`.
4.  **State Variables:** Store core contract data like proposal counters, project details, treasury balance, oracle addresses, and reputation scores.
5.  **Events:** Emit logs for critical actions for transparency and off-chain monitoring.
6.  **Modifiers:** Access control for different roles (admin, project lead, DAO member) and contract state (paused).
7.  **Core DAO Governance & Project Lifecycle Functions:** Managing proposals, voting, project funding, and milestones.
8.  **Intellectual Property (IP) Management & Monetization Functions:** Minting IP NFTs, fractionalizing them, and managing licensing agreements.
9.  **AI Oracle Integration & Validation Functions:** Interacting with an external AI oracle for insights and validating its outcomes.
10. **Tokenomics, Staking & Reputation Functions:** Handling the native governance token (AETH) for staking, rewards, and a non-transferable reputation system.
11. **Treasury & Administrative Functions:** Managing DAO funds and critical contract settings.

---

**Function Summary:**

**I. Core DAO Governance & Project Lifecycle (8 Functions)**

1.  `submitProjectProposal(string memory _title, string memory _description, uint256 _fundingAmount, bool _requiresAIAnalysis)`: Allows any member to propose an R&D project to the DAO, specifying funding needs and if AI assistance is desired.
2.  `voteOnProposal(uint256 _proposalId, bool _support)`: DAO members cast their vote (for or against) on an active project proposal.
3.  `executeProposal(uint256 _proposalId)`: Finalizes a passed project proposal, transferring requested funds from the treasury to the project's dedicated escrow.
4.  `submitMilestoneReport(uint256 _projectId, uint256 _milestoneIndex, string memory _reportHash)`: Project Lead reports the completion of a project milestone, providing a hash to off-chain details.
5.  `voteOnMilestoneCompletion(uint256 _projectId, uint256 _milestoneIndex, bool _approved)`: DAO members vote to approve or reject a submitted milestone report.
6.  `claimMilestonePayment(uint256 _projectId, uint256 _milestoneIndex)`: If a milestone is approved by the DAO, the Project Lead can claim the corresponding payment.
7.  `finalizeProject(uint256 _projectId)`: Marks a project as complete after all milestones are met, triggering the creation of an IP NFT.
8.  `updateProposalParameters(uint256 _newMinQuorum, uint256 _newVotingPeriod)`: DAO members can propose and vote to update core governance parameters like quorum and voting duration.

**II. Intellectual Property (IP) Management & Monetization (6 Functions)**

9.  `mintProjectIPNFT(uint256 _projectId, string memory _tokenURI)`: Mints a unique ERC-721 NFT representing the intellectual property of a successfully finalized project. The Project Lead is the initial owner.
10. `fractionalizeIPNFT(uint256 _ipNFTId, uint256 _totalShares)`: Converts an IP NFT into ERC-20 shares, allowing for fractional ownership and easier trading of IP rights.
11. `proposeIPLicenseTerms(uint256 _ipNFTId, string memory _termsURI, uint256 _royaltyPercentage, uint256 _durationInDays)`: The IP NFT owner (or DAO, if multi-owner) proposes terms for licensing the IP.
12. `voteOnIPLicenseApproval(uint256 _licenseId, bool _approve)`: If fractionalized, fractional owners or DAO members vote to approve a proposed IP license agreement.
13. `executeIPLicenseAgreement(uint256 _licenseId, address _licensee)`: Finalizes an approved license agreement, making the IP available to the licensee and starting royalty collection.
14. `collectIPRoyalties(uint256 _licenseId)`: Allows IP NFT owners/shareholders to collect accrued royalties from active license agreements.

**III. AI Oracle Integration & Validation (3 Functions)**

15. `requestAIOurputForDecision(uint256 _projectId, string memory _inputHash, string memory _question)`: Project Lead requests an AI oracle to analyze specific data (`_inputHash`) and provide insights on a `_question` for project decisions.
16. `submitAIOurcome(uint256 _projectId, string memory _outcomeHash, uint256 _analysisRequestIndex)`: The trusted AI oracle submits its analytical outcome (e.g., a recommendation) to the contract.
17. `voteToValidateAIOurcome(uint256 _projectId, uint256 _analysisRequestIndex, bool _isValid)`: DAO members vote to validate or reject the AI oracle's submitted outcome, providing a human oversight layer.

**IV. Tokenomics, Staking & Reputation (5 Functions)**

18. `stakeAETH(uint256 _amount)`: Allows users to stake their native AETH tokens, gaining voting power and becoming eligible for rewards.
19. `unstakeAETH(uint256 _amount)`: Users can unstake their AETH tokens after a lock-up period.
20. `claimStakingRewards()`: Allows staked AETH holders to claim their accumulated rewards.
21. `grantReputationPoints(address _recipient, uint256 _points)`: DAO-approved function to award non-transferable reputation points for valuable contributions (e.g., successful project completion, active voting).
22. `delegateVotingPower(address _delegatee)`: Allows AETH stakers to delegate their voting power to another address, fostering expert representation.

**V. Treasury & Administrative Functions (4 Functions)**

23. `depositToTreasury()`: Allows anyone to deposit funds (e.g., ETH, stablecoins) into the DAO's treasury.
24. `withdrawFromTreasury(address _recipient, uint256 _amount)`: Allows the DAO (via a passed proposal) to withdraw funds from the treasury for approved expenses.
25. `setAIOracleAddress(address _newOracleAddress)`: Admin function to update the address of the trusted AI oracle.
26. `togglePausability()`: Allows the admin to pause/unpause critical contract functions in emergencies.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// --- Interfaces for standard tokens ---
interface IAETH is IERC20 {}
interface IIPNFT is IERC721, IERC721Metadata {}
interface IFractionalIP is IERC20 {} // For fractionalized IP shares

// --- Aetheria Nexus Contract ---
contract AetheriaNexus is Ownable, ReentrancyGuard, Pausable {
    using SafeMath for uint256;

    // --- Enums ---
    enum ProposalState { Pending, Active, Succeeded, Failed, Executed }
    enum ProjectState { Proposed, Active, MilestoneReported, Completed, Failed }
    enum AIOurcomeState { Requested, Submitted, Validated, Rejected }
    enum LicenseState { Proposed, Approved, Active, Expired, Terminated }

    // --- Structs ---

    struct Proposal {
        uint256 id;
        address proposer;
        string title;
        string description;
        uint256 fundingAmount; // Amount requested from treasury
        bool requiresAIAnalysis; // Does this project integrate AI for decision support?
        uint256 startBlock;
        uint256 endBlock;
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted;
        ProposalState state;
        uint256 projectId; // If proposal succeeds, this links to the project
    }

    struct Project {
        uint256 id;
        address lead; // Address of the project leader
        string title;
        string description;
        uint256 totalFunding; // Total funding allocated to the project
        uint256 fundsWithdrawn;
        uint256 ipNFTId; // Link to the IP NFT once minted
        ProjectState state;
        mapping(uint256 => Milestone) milestones;
        uint256 milestoneCount;
        mapping(uint256 => AIOurcomeRequest) aiOutcomeRequests;
        uint256 aiRequestCount;
    }

    struct Milestone {
        uint256 id;
        string descriptionHash; // Hash of off-chain milestone description
        uint256 fundingAllocation; // Funds released upon completion
        bool reported; // If project lead has reported completion
        bool approvedByDAO; // If DAO has approved completion
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted;
    }

    struct IPNFTDetails {
        uint256 ipNFTId;
        address currentOwner; // Can be a single address or the DAO contract if fractionalized
        bool isFractionalized;
        address fractionalizedTokenAddress; // Address of the ERC-20 contract for shares
        mapping(uint256 => LicenseAgreement) licenses; // Active license agreements for this IP
        uint256 licenseCount;
    }

    struct LicenseAgreement {
        uint256 id;
        uint256 ipNFTId;
        string termsURI; // URI to off-chain legal terms
        address licensee;
        uint256 royaltyPercentageBps; // Royalty percentage in basis points (e.g., 500 for 5%)
        uint256 durationInDays;
        uint256 startDate;
        uint256 collectedRoyalties; // Amount of royalties collected for this license
        LicenseState state;
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted;
    }

    struct AIOurcomeRequest {
        uint256 id;
        string inputHash; // Hash of the data sent to AI for analysis
        string question; // The question asked to the AI
        string outcomeHash; // Hash of the AI's response
        address oracleWhoSubmitted;
        AIOurcomeState state;
        uint256 votesFor; // Votes for validation
        uint256 votesAgainst; // Votes against validation
        mapping(address => bool) hasVoted;
    }

    // --- State Variables ---

    IAETH public aethToken; // Native governance token
    IPNFT public ipNFTContract; // Contract for IP NFTs
    address public treasuryAddress; // Address holding DAO funds
    address public aiOracleAddress; // Trusted AI oracle address

    uint256 public nextProposalId;
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => uint256) public proposalVotes; // Staked AETH for each voter

    uint256 public nextProjectId;
    mapping(uint256 => Project) public projects;
    mapping(uint256 => address) public projectLeads; // projectId => lead address

    uint256 public nextIpNFTId; // Counter for IP NFTs
    mapping(uint256 => IPNFTDetails) public ipNFTs;

    mapping(address => uint256) public stakedAETH; // User => staked amount
    mapping(address => uint256) public reputationPoints; // User => non-transferable reputation
    mapping(address => address) public votingDelegates; // User => delegatee for voting power

    uint256 public minQuorumNumerator = 50; // 50% for quorum (numerator)
    uint256 public minQuorumDenominator = 100; // (denominator)
    uint256 public votingPeriodBlocks = 10000; // Approx 2-3 days on Ethereum (example)
    uint256 public proposalDepositAmount = 100 ether; // AETH required to submit a proposal

    // --- Events ---
    event ProposalSubmitted(uint256 indexed proposalId, address indexed proposer, string title, uint256 fundingAmount);
    event ProposalVoted(uint256 indexed proposalId, address indexed voter, bool support, uint256 votes);
    event ProposalExecuted(uint256 indexed proposalId, uint256 indexed projectId, address indexed projectLead, uint256 fundingAmount);
    event MilestoneReported(uint256 indexed projectId, uint256 indexed milestoneId, address indexed reporter);
    event MilestoneVoted(uint256 indexed projectId, uint256 indexed milestoneId, address indexed voter, bool approved);
    event MilestonePaymentClaimed(uint256 indexed projectId, uint256 indexed milestoneId, address indexed recipient, uint256 amount);
    event ProjectFinalized(uint256 indexed projectId);
    event ProposalParametersUpdated(uint256 newMinQuorum, uint256 newVotingPeriod);

    event IPNFTMinted(uint256 indexed ipNFTId, uint256 indexed projectId, address indexed owner);
    event IPNFTFractionalized(uint256 indexed ipNFTId, address indexed fractionalERC20);
    event IPLicenseProposed(uint256 indexed licenseId, uint256 indexed ipNFTId, address indexed proposer, uint256 royaltyPercentage);
    event IPLicenseVoted(uint256 indexed licenseId, address indexed voter, bool approved);
    event IPLicenseExecuted(uint256 indexed licenseId, uint256 indexed ipNFTId, address indexed licensee);
    event IPRoyaltiesCollected(uint256 indexed licenseId, address indexed collector, uint256 amount);

    event AIRequestSubmitted(uint256 indexed projectId, uint256 indexed requestId, string question);
    event AIOutcomeSubmitted(uint256 indexed projectId, uint256 indexed requestId, address indexed oracle);
    event AIOutcomeValidated(uint256 indexed projectId, uint256 indexed requestId, bool isValid);

    event AETHStaked(address indexed staker, uint256 amount);
    event AETHUnstaked(address indexed staker, uint256 amount);
    event StakingRewardsClaimed(address indexed staker, uint256 amount);
    event ReputationGranted(address indexed recipient, uint256 points);
    event VotingPowerDelegated(address indexed delegator, address indexed delegatee);

    event FundsDeposited(address indexed depositor, uint256 amount);
    event FundsWithdrawn(address indexed recipient, uint256 amount);
    event AIOracleAddressUpdated(address indexed oldAddress, address indexed newAddress);

    // --- Modifiers ---
    modifier onlyMember() {
        require(stakedAETH[msg.sender] > 0 || votingDelegates[msg.sender] != address(0), "AetheriaNexus: Must be a staking member or delegate to interact");
        _;
    }

    modifier onlyProjectLead(uint256 _projectId) {
        require(projects[_projectId].lead == msg.sender, "AetheriaNexus: Only project lead can call this function");
        _;
    }

    modifier onlyAIOracle() {
        require(msg.sender == aiOracleAddress, "AetheriaNexus: Only trusted AI oracle can call this function");
        _;
    }

    // --- Constructor ---
    constructor(address _aethTokenAddress, address _ipNFTContractAddress, address _treasuryAddress, address _aiOracleAddress) Ownable(msg.sender) Pausable() {
        aethToken = IAETH(_aethTokenAddress);
        ipNFTContract = IIPNFT(_ipNFTContractAddress);
        treasuryAddress = _treasuryAddress;
        aiOracleAddress = _aiOracleAddress;
        nextProposalId = 1;
        nextProjectId = 1;
        nextIpNFTId = 1;
    }

    // --- I. Core DAO Governance & Project Lifecycle (8 Functions) ---

    /// @notice Allows any member to propose an R&D project to the DAO.
    /// @param _title Project title.
    /// @param _description Project detailed description.
    /// @param _fundingAmount Amount of AETH requested from the treasury.
    /// @param _requiresAIAnalysis True if the project intends to leverage AI for insights.
    function submitProjectProposal(
        string memory _title,
        string memory _description,
        uint256 _fundingAmount,
        bool _requiresAIAnalysis
    ) external nonReentrant returns (uint256) {
        require(_fundingAmount > 0, "AetheriaNexus: Funding amount must be greater than zero");
        require(aethToken.transferFrom(msg.sender, address(this), proposalDepositAmount), "AetheriaNexus: Failed to transfer proposal deposit");

        Proposal storage newProposal = proposals[nextProposalId];
        newProposal.id = nextProposalId;
        newProposal.proposer = msg.sender;
        newProposal.title = _title;
        newProposal.description = _description;
        newProposal.fundingAmount = _fundingAmount;
        newProposal.requiresAIAnalysis = _requiresAIAnalysis;
        newProposal.startBlock = block.number;
        newProposal.endBlock = block.number.add(votingPeriodBlocks);
        newProposal.state = ProposalState.Pending;

        emit ProposalSubmitted(nextProposalId, msg.sender, _title, _fundingAmount);
        nextProposalId++;
        return newProposal.id;
    }

    /// @notice DAO members cast their vote (for or against) on an active project proposal.
    /// @param _proposalId The ID of the proposal to vote on.
    /// @param _support True for 'for' vote, false for 'against' vote.
    function voteOnProposal(uint256 _proposalId, bool _support) external onlyMember whenNotPaused nonReentrant {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.state == ProposalState.Pending || proposal.state == ProposalState.Active, "AetheriaNexus: Proposal not in active voting state");
        require(block.number <= proposal.endBlock, "AetheriaNexus: Voting period has ended");
        require(!proposal.hasVoted[msg.sender], "AetheriaNexus: Already voted on this proposal");

        uint256 voterWeight = _getVotingPower(msg.sender);
        require(voterWeight > 0, "AetheriaNexus: Voter has no active voting power");

        if (_support) {
            proposal.votesFor = proposal.votesFor.add(voterWeight);
        } else {
            proposal.votesAgainst = proposal.votesAgainst.add(voterWeight);
        }
        proposal.hasVoted[msg.sender] = true;

        // Transition to active if enough votes come in quickly, or after startBlock
        if (proposal.state == ProposalState.Pending && proposal.votesFor.add(proposal.votesAgainst) > 0) { // Or a minimum threshold to become active
            proposal.state = ProposalState.Active;
        }

        emit ProposalVoted(_proposalId, msg.sender, _support, voterWeight);
    }

    /// @notice Finalizes a passed project proposal, transferring requested funds from the treasury.
    /// @param _proposalId The ID of the proposal to execute.
    function executeProposal(uint256 _proposalId) external nonReentrant whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(block.number > proposal.endBlock, "AetheriaNexus: Voting period has not ended yet");
        require(proposal.state == ProposalState.Active, "AetheriaNexus: Proposal not in active state for execution");

        uint256 totalVotes = proposal.votesFor.add(proposal.votesAgainst);
        uint256 requiredQuorum = aethToken.balanceOf(address(this)).mul(minQuorumNumerator).div(minQuorumDenominator);
        require(totalVotes >= requiredQuorum, "AetheriaNexus: Quorum not met");

        if (proposal.votesFor > proposal.votesAgainst) {
            // Proposal Succeeded
            proposal.state = ProposalState.Succeeded;

            // Create new project
            Project storage newProject = projects[nextProjectId];
            newProject.id = nextProjectId;
            newProject.lead = proposal.proposer;
            newProject.title = proposal.title;
            newProject.description = proposal.description;
            newProject.totalFunding = proposal.fundingAmount;
            newProject.state = ProjectState.Active;
            projectLeads[nextProjectId] = proposal.proposer;

            // Transfer funds from treasury to the project leader (or project's dedicated escrow)
            // For simplicity, we transfer directly to the project lead's future claims,
            // but a more robust system might use a separate escrow contract for each project.
            // Here, funds are implicitly 'allocated' and then 'claimed' per milestone.

            // AETH taken for deposit is returned
            require(aethToken.transfer(proposal.proposer, proposalDepositAmount), "AetheriaNexus: Failed to return proposal deposit");

            proposal.projectId = nextProjectId;
            proposal.state = ProposalState.Executed;

            emit ProposalExecuted(_proposalId, nextProjectId, proposal.proposer, proposal.fundingAmount);
            nextProjectId++;
        } else {
            // Proposal Failed
            proposal.state = ProposalState.Failed;
            // Return deposit
            require(aethToken.transfer(proposal.proposer, proposalDepositAmount), "AetheriaNexus: Failed to return proposal deposit");
        }
    }

    /// @notice Project Lead reports the completion of a project milestone.
    /// @param _projectId The ID of the project.
    /// @param _milestoneIndex The index of the milestone being reported (0-indexed).
    /// @param _reportHash Hash linking to off-chain detailed report.
    function submitMilestoneReport(uint256 _projectId, uint256 _milestoneIndex, string memory _reportHash) external onlyProjectLead(_projectId) whenNotPaused {
        Project storage project = projects[_projectId];
        require(project.state == ProjectState.Active, "AetheriaNexus: Project is not active");
        require(_milestoneIndex < project.milestoneCount, "AetheriaNexus: Invalid milestone index");
        require(!project.milestones[_milestoneIndex].reported, "AetheriaNexus: Milestone already reported");

        Milestone storage milestone = project.milestones[_milestoneIndex];
        milestone.descriptionHash = _reportHash;
        milestone.reported = true;
        project.state = ProjectState.MilestoneReported; // Temporarily change state for DAO review

        emit MilestoneReported(_projectId, _milestoneIndex, msg.sender);
    }

    /// @notice DAO members vote to approve or reject a submitted milestone report.
    /// @param _projectId The ID of the project.
    /// @param _milestoneIndex The index of the milestone being voted on.
    /// @param _approved True to approve, false to reject.
    function voteOnMilestoneCompletion(uint256 _projectId, uint256 _milestoneIndex, bool _approved) external onlyMember whenNotPaused nonReentrant {
        Project storage project = projects[_projectId];
        require(project.state == ProjectState.MilestoneReported || project.state == ProjectState.Active, "AetheriaNexus: Project not in milestone review state");
        require(_milestoneIndex < project.milestoneCount, "AetheriaNexus: Invalid milestone index");
        Milestone storage milestone = project.milestones[_milestoneIndex];
        require(milestone.reported, "AetheriaNexus: Milestone not yet reported by lead");
        require(!milestone.hasVoted[msg.sender], "AetheriaNexus: Already voted on this milestone");

        uint256 voterWeight = _getVotingPower(msg.sender);
        require(voterWeight > 0, "AetheriaNexus: Voter has no active voting power");

        if (_approved) {
            milestone.votesFor = milestone.votesFor.add(voterWeight);
        } else {
            milestone.votesAgainst = milestone.votesAgainst.add(voterWeight);
        }
        milestone.hasVoted[msg.sender] = true;

        emit MilestoneVoted(_projectId, _milestoneIndex, msg.sender, _approved);
    }

    /// @notice If a milestone is approved by the DAO, the Project Lead can claim the corresponding payment.
    /// @param _projectId The ID of the project.
    /// @param _milestoneIndex The index of the milestone to claim.
    function claimMilestonePayment(uint256 _projectId, uint256 _milestoneIndex) external onlyProjectLead(_projectId) nonReentrant whenNotPaused {
        Project storage project = projects[_projectId];
        require(_milestoneIndex < project.milestoneCount, "AetheriaNexus: Invalid milestone index");
        Milestone storage milestone = project.milestones[_milestoneIndex];
        require(milestone.reported, "AetheriaNexus: Milestone not yet reported");
        require(!milestone.approvedByDAO, "AetheriaNexus: Milestone payment already claimed or approved"); // approvedByDAO acts as a flag for claiming

        // Check quorum and approval thresholds (simplified here)
        uint256 totalVotes = milestone.votesFor.add(milestone.votesAgainst);
        uint256 requiredQuorum = aethToken.balanceOf(address(this)).mul(minQuorumNumerator).div(minQuorumDenominator); // Needs to be dynamic based on current staked AETH
        require(totalVotes >= requiredQuorum, "AetheriaNexus: Quorum not met for milestone approval");
        require(milestone.votesFor > milestone.votesAgainst, "AetheriaNexus: Milestone not approved by DAO majority");

        milestone.approvedByDAO = true;
        project.fundsWithdrawn = project.fundsWithdrawn.add(milestone.fundingAllocation);
        project.state = ProjectState.Active; // Return to active state for next actions

        // Transfer AETH from treasury to project lead
        require(aethToken.transfer(project.lead, milestone.fundingAllocation), "AetheriaNexus: Failed to transfer milestone payment");

        emit MilestonePaymentClaimed(_projectId, _milestoneIndex, project.lead, milestone.fundingAllocation);
    }

    /// @notice Marks a project as complete after all milestones are met, triggering the creation of an IP NFT.
    /// @param _projectId The ID of the project to finalize.
    function finalizeProject(uint256 _projectId) external onlyProjectLead(_projectId) nonReentrant whenNotPaused {
        Project storage project = projects[_projectId];
        require(project.state == ProjectState.Active, "AetheriaNexus: Project not in active state");
        require(project.milestoneCount > 0, "AetheriaNexus: Project must have at least one milestone");

        // Ensure all milestones are reported and approved
        for (uint256 i = 0; i < project.milestoneCount; i++) {
            require(project.milestones[i].approvedByDAO, "AetheriaNexus: Not all milestones are approved yet");
        }
        require(project.fundsWithdrawn == project.totalFunding, "AetheriaNexus: Not all allocated funds have been withdrawn (or excess funds exist)");

        project.state = ProjectState.Completed;
        // Optionally, trigger IP NFT minting here or in a separate step

        emit ProjectFinalized(_projectId);
    }

    /// @notice DAO members can propose and vote to update core governance parameters.
    /// @param _newMinQuorum New minimum quorum percentage (e.g., 50 for 50%).
    /// @param _newVotingPeriod New voting period in blocks.
    function updateProposalParameters(uint256 _newMinQuorum, uint256 _newVotingPeriod) external onlyMember whenNotPaused {
        // This function itself would ideally be a proposal to be voted on.
        // For simplicity, directly callable by a 'member' but in a real DAO
        // it would be a critical governance function requiring high approval.
        require(_newMinQuorum > 0 && _newMinQuorum <= 100, "AetheriaNexus: Quorum must be between 1 and 100");
        require(_newVotingPeriod > 0, "AetheriaNexus: Voting period must be greater than 0");

        minQuorumNumerator = _newMinQuorum;
        minQuorumDenominator = 100;
        votingPeriodBlocks = _newVotingPeriod;

        emit ProposalParametersUpdated(_newMinQuorum, _newVotingPeriod);
    }

    // --- II. Intellectual Property (IP) Management & Monetization (6 Functions) ---

    /// @notice Mints a unique ERC-721 NFT representing the intellectual property of a successfully finalized project.
    /// @param _projectId The ID of the completed project.
    /// @param _tokenURI URI linking to the IP NFT's metadata.
    function mintProjectIPNFT(uint256 _projectId, string memory _tokenURI) external onlyProjectLead(_projectId) nonReentrant whenNotPaused returns (uint256) {
        Project storage project = projects[_projectId];
        require(project.state == ProjectState.Completed, "AetheriaNexus: Project must be completed to mint IP NFT");
        require(project.ipNFTId == 0, "AetheriaNexus: IP NFT already minted for this project");

        // This assumes IPNFT contract has a `mint` function callable by this contract
        // In a real scenario, this would involve a separate ERC-721 contract.
        // For this example, we mock the IPNFT contract interaction.
        uint256 newIpNFTId = nextIpNFTId++;
        // ipNFTContract.mint(project.lead, newIpNFTId); // Placeholder for actual ERC721 minting
        // ipNFTContract.setTokenURI(newIpNFTId, _tokenURI); // Placeholder for setting URI

        IPNFTDetails storage newIP = ipNFTs[newIpNFTId];
        newIP.ipNFTId = newIpNFTId;
        newIP.currentOwner = project.lead;
        newIP.isFractionalized = false;

        project.ipNFTId = newIpNFTId; // Link project to its IP NFT

        emit IPNFTMinted(newIpNFTId, _projectId, project.lead);
        return newIpNFTId;
    }

    /// @notice Converts an IP NFT into ERC-20 shares, allowing for fractional ownership.
    /// @param _ipNFTId The ID of the IP NFT to fractionalize.
    /// @param _totalShares The total number of ERC-20 shares to mint.
    function fractionalizeIPNFT(uint256 _ipNFTId, uint256 _totalShares) external nonReentrant whenNotPaused {
        IPNFTDetails storage ip = ipNFTs[_ipNFTId];
        require(ip.ipNFTId != 0, "AetheriaNexus: IP NFT does not exist");
        require(ip.currentOwner == msg.sender, "AetheriaNexus: Only IP NFT owner can fractionalize");
        require(!ip.isFractionalized, "AetheriaNexus: IP NFT is already fractionalized");
        require(_totalShares > 0, "AetheriaNexus: Total shares must be greater than zero");

        // In a real scenario, this would deploy a new ERC-20 contract for these shares,
        // and transfer ownership of the original ERC-721 to that ERC-20 contract (or to this DAO contract).
        // For simplicity, we'll just mock the creation of a fractional token address.
        address newFractionalTokenAddress = address(uint160(keccak256(abi.encodePacked("FractionalIP_", _ipNFTId, block.timestamp))));
        // IFractionalIP(newFractionalTokenAddress).mint(msg.sender, _totalShares); // Mock minting

        ip.isFractionalized = true;
        ip.fractionalizedTokenAddress = newFractionalTokenAddress;
        ip.currentOwner = address(this); // DAO contract now implicitly manages the IP NFT through its fractional shares.

        // ipNFTContract.transferFrom(msg.sender, address(this), _ipNFTId); // Transfer the original NFT to the DAO contract

        emit IPNFTFractionalized(_ipNFTId, newFractionalTokenAddress);
    }

    /// @notice The IP NFT owner (or DAO, if multi-owner) proposes terms for licensing the IP.
    /// @param _ipNFTId The ID of the IP NFT to license.
    /// @param _termsURI URI to off-chain legal terms of the license.
    /// @param _royaltyPercentageBps Royalty percentage in basis points (e.g., 500 for 5%).
    /// @param _durationInDays Duration of the license in days.
    function proposeIPLicenseTerms(
        uint256 _ipNFTId,
        string memory _termsURI,
        uint256 _royaltyPercentageBps,
        uint256 _durationInDays
    ) external nonReentrant whenNotPaused returns (uint256) {
        IPNFTDetails storage ip = ipNFTs[_ipNFTId];
        require(ip.ipNFTId != 0, "AetheriaNexus: IP NFT does not exist");
        require(ip.currentOwner == msg.sender || ip.currentOwner == address(this), "AetheriaNexus: Only IP NFT owner or DAO can propose licenses");
        require(_royaltyPercentageBps <= 10000, "AetheriaNexus: Royalty percentage cannot exceed 100%");
        require(_durationInDays > 0, "AetheriaNexus: License duration must be positive");

        uint256 newLicenseId = ip.licenseCount++;
        LicenseAgreement storage newLicense = ip.licenses[newLicenseId];
        newLicense.id = newLicenseId;
        newLicense.ipNFTId = _ipNFTId;
        newLicense.termsURI = _termsURI;
        newLicense.royaltyPercentageBps = _royaltyPercentageBps;
        newLicense.durationInDays = _durationInDays;
        newLicense.state = LicenseState.Proposed;

        // If fractionalized, this proposal would need a vote.
        // If single owner, they can directly approve/execute.
        // For now, let's assume it always needs a vote if fractionalized or if DAO owned.

        emit IPLicenseProposed(newLicenseId, _ipNFTId, msg.sender, _royaltyPercentageBps);
        return newLicenseId;
    }

    /// @notice If fractionalized, fractional owners or DAO members vote to approve a proposed IP license agreement.
    /// @param _licenseId The ID of the license agreement to vote on.
    /// @param _approve True to approve, false to reject.
    function voteOnIPLicenseApproval(uint256 _licenseId, bool _approve) external onlyMember whenNotPaused nonReentrant {
        // Find the correct IPNFT and license
        uint256 ipNFTIdFound = 0;
        bool found = false;
        for (uint256 i = 0; i < nextIpNFTId; i++) {
            if (ipNFTs[i].licenses[_licenseId].id == _licenseId && ipNFTs[i].licenses[_licenseId].ipNFTId != 0) {
                ipNFTIdFound = ipNFTs[i].ipNFTId;
                found = true;
                break;
            }
        }
        require(found, "AetheriaNexus: License agreement not found");

        IPNFTDetails storage ip = ipNFTs[ipNFTIdFound];
        LicenseAgreement storage license = ip.licenses[_licenseId];
        require(license.state == LicenseState.Proposed, "AetheriaNexus: License is not in a proposed state");
        require(!license.hasVoted[msg.sender], "AetheriaNexus: Already voted on this license");

        uint256 voterWeight = _getVotingPower(msg.sender);
        require(voterWeight > 0, "AetheriaNexus: Voter has no active voting power");

        if (_approve) {
            license.votesFor = license.votesFor.add(voterWeight);
        } else {
            license.votesAgainst = license.votesAgainst.add(voterWeight);
        }
        license.hasVoted[msg.sender] = true;

        emit IPLicenseVoted(_licenseId, msg.sender, _approve);
    }

    /// @notice Finalizes an approved license agreement, making the IP available to the licensee and starting royalty collection.
    /// @param _licenseId The ID of the license agreement to execute.
    /// @param _licensee The address of the entity/person acquiring the license.
    function executeIPLicenseAgreement(uint256 _licenseId, address _licensee) external nonReentrant whenNotPaused {
        // Find the correct IPNFT and license
        uint256 ipNFTIdFound = 0;
        bool found = false;
        for (uint256 i = 0; i < nextIpNFTId; i++) {
            if (ipNFTs[i].licenses[_licenseId].id == _licenseId && ipNFTs[i].licenses[_licenseId].ipNFTId != 0) {
                ipNFTIdFound = ipNFTs[i].ipNFTId;
                found = true;
                break;
            }
        }
        require(found, "AetheriaNexus: License agreement not found");

        IPNFTDetails storage ip = ipNFTs[ipNFTIdFound];
        LicenseAgreement storage license = ip.licenses[_licenseId];
        require(license.state == LicenseState.Proposed, "AetheriaNexus: License is not in a proposed state");

        // Check voting outcome (simplified: majority and quorum assumed)
        uint256 totalVotes = license.votesFor.add(license.votesAgainst);
        uint256 requiredQuorum = aethToken.balanceOf(address(this)).mul(minQuorumNumerator).div(minQuorumDenominator);
        require(totalVotes >= requiredQuorum, "AetheriaNexus: Quorum not met for license approval");
        require(license.votesFor > license.votesAgainst, "AetheriaNexus: License not approved by DAO majority");

        license.state = LicenseState.Active;
        license.licensee = _licensee;
        license.startDate = block.timestamp;

        emit IPLicenseExecuted(_licenseId, ip.ipNFTId, _licensee);
    }

    /// @notice Allows IP NFT owners/shareholders to collect accrued royalties from active license agreements.
    /// @param _licenseId The ID of the license agreement to collect royalties from.
    function collectIPRoyalties(uint256 _licenseId) external nonReentrant whenNotPaused {
        // Find the correct IPNFT and license
        uint256 ipNFTIdFound = 0;
        bool found = false;
        for (uint256 i = 0; i < nextIpNFTId; i++) {
            if (ipNFTs[i].licenses[_licenseId].id == _licenseId && ipNFTs[i].licenses[_licenseId].ipNFTId != 0) {
                ipNFTIdFound = ipNFTs[i].ipNFTId;
                found = true;
                break;
            }
        }
        require(found, "AetheriaNexus: License agreement not found");

        IPNFTDetails storage ip = ipNFTs[ipNFTIdFound];
        LicenseAgreement storage license = ip.licenses[_licenseId];
        require(license.state == LicenseState.Active, "AetheriaNexus: License is not active");
        require(block.timestamp <= license.startDate.add(license.durationInDays.mul(1 days)), "AetheriaNexus: License has expired");

        // Simplified royalty collection: Assume licensee sends funds to this contract for royalties.
        // In a real system, there would be a pull mechanism or direct payments from licensee.
        // For this example, let's say the collectedRoyalties are somehow accumulated here.
        uint256 availableRoyalties = license.collectedRoyalties; // This would be populated by external payments
        require(availableRoyalties > 0, "AetheriaNexus: No royalties to collect");

        license.collectedRoyalties = 0; // Reset
        
        address recipient = ip.isFractionalized ? address(ip.fractionalizedTokenAddress) : ip.currentOwner;
        // In a real system, fractionalized royalties would be distributed to ERC-20 holders via the fractional ERC-20 contract.
        // For a single owner, directly transfer.
        // For simplicity here, we send to the main owner or the fractional token contract for distribution.
        require(aethToken.transfer(recipient, availableRoyalties), "AetheriaNexus: Failed to transfer royalties");

        emit IPRoyaltiesCollected(_licenseId, recipient, availableRoyalties);
    }

    /// @notice Allows the owner of the core IP NFT to transfer its ownership.
    /// @param _ipNFTId The ID of the IP NFT to transfer.
    /// @param _newOwner The address of the new owner.
    function transferIPNFTOwnership(uint256 _ipNFTId, address _newOwner) external whenNotPaused {
        IPNFTDetails storage ip = ipNFTs[_ipNFTId];
        require(ip.ipNFTId != 0, "AetheriaNexus: IP NFT does not exist");
        require(ip.currentOwner == msg.sender, "AetheriaNexus: Only current IP NFT owner can transfer");
        require(!ip.isFractionalized, "AetheriaNexus: Cannot transfer a fractionalized IP NFT directly");

        // ipNFTContract.transferFrom(msg.sender, _newOwner, _ipNFTId); // Actual ERC-721 transfer
        ip.currentOwner = _newOwner; // Update internal record
    }

    // --- III. AI Oracle Integration & Validation (3 Functions) ---

    /// @notice Project Lead requests an AI oracle to analyze specific data and provide insights for project decisions.
    /// @param _projectId The ID of the project requesting AI analysis.
    /// @param _inputHash Hash of the off-chain input data for AI.
    /// @param _question The question posed to the AI.
    function requestAIOurputForDecision(uint256 _projectId, string memory _inputHash, string memory _question) external onlyProjectLead(_projectId) whenNotPaused {
        Project storage project = projects[_projectId];
        require(project.state == ProjectState.Active, "AetheriaNexus: Project is not active");
        require(aiOracleAddress != address(0), "AetheriaNexus: AI Oracle address not set");
        require(project.aiRequestCount < 10, "AetheriaNexus: Max AI requests reached for this project (limit for example)");

        uint256 newRequestId = project.aiRequestCount++;
        AIOurcomeRequest storage newRequest = project.aiOutcomeRequests[newRequestId];
        newRequest.id = newRequestId;
        newRequest.inputHash = _inputHash;
        newRequest.question = _question;
        newRequest.state = AIOurcomeState.Requested;

        emit AIRequestSubmitted(_projectId, newRequestId, _question);
        // An event here could trigger the off-chain oracle service.
    }

    /// @notice The trusted AI oracle submits its analytical outcome to the contract.
    /// @param _projectId The ID of the project.
    /// @param _outcomeHash Hash of the AI's response/recommendation.
    /// @param _analysisRequestIndex The index of the original AI analysis request.
    function submitAIOurcome(uint256 _projectId, string memory _outcomeHash, uint256 _analysisRequestIndex) external onlyAIOracle whenNotPaused {
        Project storage project = projects[_projectId];
        require(project.aiOutcomeRequests[_analysisRequestIndex].state == AIOurcomeState.Requested, "AetheriaNexus: AI outcome not in requested state");

        AIOurcomeRequest storage request = project.aiOutcomeRequests[_analysisRequestIndex];
        request.outcomeHash = _outcomeHash;
        request.oracleWhoSubmitted = msg.sender;
        request.state = AIOurcomeState.Submitted;

        emit AIOutcomeSubmitted(_projectId, _analysisRequestIndex, msg.sender);
    }

    /// @notice DAO members vote to validate or reject the AI oracle's submitted outcome.
    /// @param _projectId The ID of the project.
    /// @param _analysisRequestIndex The index of the AI analysis request.
    /// @param _isValid True to validate, false to reject.
    function voteToValidateAIOurcome(uint256 _projectId, uint256 _analysisRequestIndex, bool _isValid) external onlyMember whenNotPaused nonReentrant {
        Project storage project = projects[_projectId];
        AIOurcomeRequest storage request = project.aiOutcomeRequests[_analysisRequestIndex];
        require(request.state == AIOurcomeState.Submitted, "AetheriaNexus: AI outcome not submitted for validation");
        require(!request.hasVoted[msg.sender], "AetheriaNexus: Already voted on this AI outcome");

        uint256 voterWeight = _getVotingPower(msg.sender);
        require(voterWeight > 0, "AetheriaNexus: Voter has no active voting power");

        if (_isValid) {
            request.votesFor = request.votesFor.add(voterWeight);
        } else {
            request.votesAgainst = request.votesAgainst.add(voterWeight);
        }
        request.hasVoted[msg.sender] = true;

        // Simplified: automatically validate/reject if enough votes accrue quickly, or require a separate execution step.
        // For example, if (request.votesFor + request.votesAgainst >= minQuorum) then finalize state.
        // For now, assume a separate execution or off-chain monitoring will finalize.

        emit AIOutcomeValidated(_projectId, _analysisRequestIndex, _isValid);
    }

    // --- IV. Tokenomics, Staking & Reputation (5 Functions) ---

    /// @notice Allows users to stake their native AETH tokens, gaining voting power and becoming eligible for rewards.
    /// @param _amount The amount of AETH to stake.
    function stakeAETH(uint256 _amount) external nonReentrant whenNotPaused {
        require(_amount > 0, "AetheriaNexus: Stake amount must be greater than zero");
        require(aethToken.transferFrom(msg.sender, address(this), _amount), "AetheriaNexus: Failed to transfer AETH for staking");
        stakedAETH[msg.sender] = stakedAETH[msg.sender].add(_amount);

        // Logic for reward calculation would be here (e.g., based on time staked, proportion of total stake)
        // For simplicity, rewards are assumed to be distributed separately or accrue based on some metric.

        emit AETHStaked(msg.sender, _amount);
    }

    /// @notice Users can unstake their AETH tokens after a lock-up period (not enforced in this example).
    /// @param _amount The amount of AETH to unstake.
    function unstakeAETH(uint256 _amount) external nonReentrant whenNotPaused {
        require(_amount > 0, "AetheriaNexus: Unstake amount must be greater than zero");
        require(stakedAETH[msg.sender] >= _amount, "AetheriaNexus: Insufficient staked AETH");

        stakedAETH[msg.sender] = stakedAETH[msg.sender].sub(_amount);
        require(aethToken.transfer(msg.sender, _amount), "AetheriaNexus: Failed to transfer AETH back to staker");

        // Clear delegate if no more voting power
        if (stakedAETH[msg.sender] == 0 && votingDelegates[msg.sender] != address(0)) {
            votingDelegates[msg.sender] = address(0);
        }

        emit AETHUnstaked(msg.sender, _amount);
    }

    /// @notice Allows staked AETH holders to claim their accumulated rewards.
    function claimStakingRewards() external nonReentrant whenNotPaused {
        // This is a placeholder. Actual reward calculation and distribution logic would be complex.
        // For example: `rewards[msg.sender] = calculateRewards(msg.sender);`
        uint256 rewardsToClaim = 0; // Placeholder value
        if (rewardsToClaim > 0) {
            // require(aethToken.transfer(msg.sender, rewardsToClaim), "AetheriaNexus: Failed to transfer staking rewards");
            emit StakingRewardsClaimed(msg.sender, rewardsToClaim);
        } else {
            revert("AetheriaNexus: No rewards to claim");
        }
    }

    /// @notice DAO-approved function to award non-transferable reputation points for valuable contributions.
    /// @param _recipient The address to grant reputation points to.
    /// @param _points The number of reputation points to grant.
    function grantReputationPoints(address _recipient, uint256 _points) external onlyMember whenNotPaused {
        // This function would typically be triggered by a passed DAO proposal,
        // or by specific contract actions (e.g., project completion).
        // For simplicity, let's allow any member to propose, but real implementation needs robust checks.
        require(_points > 0, "AetheriaNexus: Points must be greater than zero");
        reputationPoints[_recipient] = reputationPoints[_recipient].add(_points);

        emit ReputationGranted(_recipient, _points);
    }

    /// @notice Allows AETH stakers to delegate their voting power to another address.
    /// @param _delegatee The address to delegate voting power to.
    function delegateVotingPower(address _delegatee) external whenNotPaused {
        require(stakedAETH[msg.sender] > 0, "AetheriaNexus: Only stakers can delegate voting power");
        require(_delegatee != address(0), "AetheriaNexus: Delegatee cannot be zero address");
        require(_delegatee != msg.sender, "AetheriaNexus: Cannot delegate to self");

        votingDelegates[msg.sender] = _delegatee;
        emit VotingPowerDelegated(msg.sender, _delegatee);
    }

    // Internal helper function to get voting power, considering delegation.
    function _getVotingPower(address _voter) internal view returns (uint256) {
        address actualVoter = _voter;
        // Check if the voter has delegated their power
        if (votingDelegates[_voter] != address(0)) {
            actualVoter = votingDelegates[_voter];
        }
        return stakedAETH[actualVoter];
    }

    // --- V. Treasury & Administrative Functions (4 Functions) ---

    /// @notice Allows anyone to deposit funds (e.g., ETH, stablecoins) into the DAO's treasury.
    function depositToTreasury() external payable whenNotPaused {
        // This function handles ETH deposits. For AETH, transferFrom is used.
        require(msg.value > 0, "AetheriaNexus: Deposit amount must be greater than zero");
        // Funds are held directly by the contract. A separate treasury contract might be better.
        // For this example, contract's balance is the treasury.
        emit FundsDeposited(msg.sender, msg.value);
    }

    /// @notice Allows the DAO (via a passed proposal) to withdraw funds from the treasury for approved expenses.
    /// @param _recipient The address to send funds to.
    /// @param _amount The amount of ETH to withdraw.
    function withdrawFromTreasury(address _recipient, uint256 _amount) external nonReentrant whenNotPaused {
        // This would typically be executed by a passed DAO proposal.
        // For simplicity, only DAO owner (deployer) can call this for ETH.
        // For AETH, it's handled by executeProposal.
        require(msg.sender == owner(), "AetheriaNexus: Only contract owner can withdraw ETH from treasury for now (should be DAO controlled)");
        require(address(this).balance >= _amount, "AetheriaNexus: Insufficient funds in treasury");
        
        (bool success, ) = _recipient.call{value: _amount}("");
        require(success, "AetheriaNexus: Failed to withdraw ETH from treasury");

        emit FundsWithdrawn(_recipient, _amount);
    }

    /// @notice Admin function to update the address of the trusted AI oracle.
    /// @param _newOracleAddress The new address for the AI oracle.
    function setAIOracleAddress(address _newOracleAddress) external onlyOwner whenNotPaused {
        require(_newOracleAddress != address(0), "AetheriaNexus: New AI oracle address cannot be zero");
        emit AIOracleAddressUpdated(aiOracleAddress, _newOracleAddress);
        aiOracleAddress = _newOracleAddress;
    }

    /// @notice Allows the admin to pause/unpause critical contract functions in emergencies.
    function togglePausability() external onlyOwner {
        if (paused()) {
            _unpause();
        } else {
            _pause();
        }
    }
}

// --- Mock ERC-721 for IPNFT ---
// In a real scenario, this would be a separate, deployed ERC-721 contract.
// We include a simplified version here for compilation, but in production,
// AetheriaNexus would interact with an already deployed, feature-rich ERC-721.
contract IPNFT is IERC721, IERC721Metadata {
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    mapping(uint256 => string) private _tokenURIs; // Simplified metadata

    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view override returns (string memory) { return _name; }
    function symbol() public view override returns (string memory) { return _symbol; }
    function totalSupply() public pure returns (uint256) { return 0; } // Simplified
    function balanceOf(address owner) public view override returns (uint256) { return _balances[owner]; }
    function ownerOf(uint256 tokenId) public view override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }
    function approve(address to, uint256 tokenId) public override {
        address owner_ = ownerOf(tokenId);
        require(to != owner_, "ERC721: approval to current owner");
        require(msg.sender == owner_ || isApprovedForAll(owner_, msg.sender), "ERC721: approve caller is not owner nor approved for all");
        _tokenApprovals[tokenId] = to;
        emit Approval(owner_, to, tokenId);
    }
    function getApproved(uint256 tokenId) public view override returns (address) { return _tokenApprovals[tokenId]; }
    function setApprovalForAll(address operator, bool approved) public override {
        require(operator != msg.sender, "ERC721: approve to caller");
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }
    function isApprovedForAll(address owner_, address operator) public view override returns (bool) { return _operatorApprovals[owner_][operator]; }
    function transferFrom(address from, address to, uint256 tokenId) public override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
    }
    function safeTransferFrom(address from, address to, uint256 tokenId) public override {
        safeTransferFrom(from, to, tokenId, "");
    }
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return _tokenURIs[tokenId];
    }

    // Internal minting function for AetheriaNexus to call
    function mint(address to, uint256 tokenId) internal {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");
        _balances[to]++;
        _owners[tokenId] = to;
        emit Transfer(address(0), to, tokenId);
    }

    function setTokenURI(uint256 tokenId, string memory uri_) internal {
        require(_exists(tokenId), "ERC721Metadata: URI set for nonexistent token");
        _tokenURIs[tokenId] = uri_;
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _transfer(address from, address to, uint256 tokenId) internal {
        require(ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _balances[from]--;
        _balances[to]++;
        _owners[tokenId] = to;
        _tokenApprovals[tokenId] = address(0); // Clear approvals
        emit Transfer(from, to, tokenId);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner_ = ownerOf(tokenId);
        return (spender == owner_ || getApproved(tokenId) == spender || isApprovedForAll(owner_, spender));
    }

    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory data) private pure returns (bool) {
        // Mock implementation, in a real case it would call `onERC721Received`
        // if `to` is a contract and check its return value.
        return true;
    }
}
```