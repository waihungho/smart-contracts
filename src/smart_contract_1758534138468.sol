This smart contract, **VeritasNexus**, embodies a decentralized collective focused on identifying, funding, and verifying impactful projects. It introduces several advanced concepts:

*   **Dynamic Impact NFTs:** NFTs whose metadata (and potentially visual representation) dynamically changes based on the associated project's verified impact score.
*   **AI-Influenced Oracle Integration:** A trusted oracle reports AI-driven initial impact assessments and ongoing project verifications, directly influencing project funding, NFT traits, and collective decisions.
*   **Reputation-Based Governance:** Member voting power and influence are tied to their staked tokens and earned on-chain reputation.
*   **Contextualized Treasury Management:** Funding tranches are approved based on project milestones and verified impact.
*   **Dispute Resolution & Slashing:** Mechanisms for members to dispute project impact or member misconduct, leading to governance votes and potential reputation/stake slashing.
*   **Impact Bounties:** The collective can create bounties for specific, verifiable impact goals.

The goal is to create a vibrant, self-governing ecosystem where real-world impact is measurable, incentivized, and represented on-chain.

---

## VeritasNexus: Dynamic Impact Collective

**Outline & Function Summary**

**I. Core Infrastructure & Admin (5 Functions)**
   1.  `constructor()`: Initializes the contract with the VERITAS_TOKEN address, sets the deployer as owner, and defines initial parameters.
   2.  `setOracleAddress(address _oracle)`: Allows the owner to set or update the address of the trusted oracle.
   3.  `updateAIModelEndpoint(string memory _newEndpoint)`: (Conceptual) Owner updates the URI or identifier for the AI model used by the oracle for impact assessments.
   4.  `emergencyPause()`: Owner can pause critical contract functionalities (e.g., transfers, funding) in case of an emergency.
   5.  `recoverERC20Funds(address _tokenAddress, uint256 _amount)`: Owner can recover accidentally sent ERC20 tokens (other than VERITAS_TOKEN) from the contract.

**II. Collective Membership & Reputation (4 Functions)**
   6.  `joinCollective(uint256 _initialStake)`: Allows a user to join the collective by staking `VERITAS_TOKEN`, gaining initial reputation and voting rights.
   7.  `stakeFunds(uint256 _amount)`: Members can increase their staked `VERITAS_TOKEN`, potentially boosting their reputation over time.
   8.  `unstakeFunds(uint256 _amount)`: Members can request to unstake their `VERITAS_TOKEN` with a defined cooldown period and potential reputation impact.
   9.  `delegateReputation(address _delegatee)`: Members can delegate their reputation-based voting power to another member.

**III. Project Lifecycle & Funding (6 Functions)**
   10. `submitProjectProposal(string memory _title, string memory _description, string memory _metadataURI, uint256 _totalFundingGoal)`: Allows a member to submit a new project proposal, including a request for an initial AI impact assessment.
   11. `requestAIImpactAnalysis(uint256 _projectId)`: Project owner requests the oracle to perform an AI-driven impact analysis for their project.
   12. `voteOnProjectProposal(uint256 _projectId, bool _approve)`: Members vote on whether to approve a submitted project proposal for funding.
   13. `finalizeProjectFunding(uint256 _projectId)`: If a project proposal passes, this function mints an Impact NFT for the project owner and allocates initial funding.
   14. `requestFundingTranche(uint256 _projectId, uint256 _amount, string memory _justificationURI)`: Project owner requests a subsequent funding tranche for their project, providing justification.
   15. `approveFundingTranche(uint256 _projectId, uint256 _proposalId)`: Governance-approved function to release a requested funding tranche to a project.

**IV. Dynamic Impact NFTs (3 Functions)**
   16. `receiveOracleImpactAssessment(uint256 _projectId, uint256 _newImpactScore, string memory _assessmentReportURI)`: Oracle callback to update a project's impact score, triggering an NFT metadata regeneration.
   17. `regenerateImpactNFTMetadata(uint256 _projectId)`: Triggers the off-chain metadata service to update the `tokenURI` for a project's Impact NFT based on its current impact score.
   18. `burnImpactNFT(uint256 _projectId)`: Allows governance to burn an Impact NFT if a project is deemed to have failed or been abandoned.

**V. Governance & Dispute Resolution (5 Functions)**
   19. `createGovernanceProposal(string memory _description, bytes memory _calldata, address _targetContract)`: Members can create proposals for contract upgrades, parameter changes, or other collective decisions.
   20. `voteOnGovernanceProposal(uint256 _proposalId, bool _approve)`: Members vote on active governance proposals.
   21. `executeGovernanceProposal(uint256 _proposalId)`: Executes a governance proposal if it passes the vote and the execution delay has passed.
   22. `slashMemberReputation(address _member, uint256 _amount)`: Governance-controlled function to reduce a member's reputation due to misconduct.
   23. `disputeProjectImpact(uint256 _projectId, string memory _reasonURI)`: Allows a member to formally dispute a project's reported impact score or status, triggering a review.

**VI. Oracle Integration & AI Assessment (1 Function)**
   24. `resolveDispute(uint256 _projectId, address _disputingMember, bool _isDisputeValid)`: Governance-controlled function to resolve an impact dispute, potentially adjusting impact scores or slashing parties involved. (Moved `receiveOracleImpactAssessment` up for flow)

**VII. Rewards & Bounties (2 Functions)**
   25. `claimProjectImpactReward(uint256 _projectId)`: Project owners/contributors can claim rewards from the treasury based on achieving high impact scores or milestones.
   26. `setupImpactBounty(string memory _title, string memory _description, uint256 _rewardAmount, uint256 _minImpactScoreTarget)`: Collective governance can set up bounties for projects achieving specific impact goals.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Outline and Function Summary
//
// VeritasNexus: Dynamic Impact Collective
//
// This smart contract, VeritasNexus, embodies a decentralized collective focused on identifying, funding, and verifying impactful projects.
// It introduces several advanced concepts: Dynamic Impact NFTs, AI-Influenced Oracle Integration, Reputation-Based Governance,
// Contextualized Treasury Management, Dispute Resolution & Slashing, and Impact Bounties.
//
// The goal is to create a vibrant, self-governing ecosystem where real-world impact is measurable, incentivized, and represented on-chain.
//
// I. Core Infrastructure & Admin (5 Functions)
//    1.  constructor(): Initializes the contract with the VERITAS_TOKEN address, sets the deployer as owner, and defines initial parameters.
//    2.  setOracleAddress(address _oracle): Allows the owner to set or update the address of the trusted oracle.
//    3.  updateAIModelEndpoint(string memory _newEndpoint): (Conceptual) Owner updates the URI or identifier for the AI model used by the oracle for impact assessments.
//    4.  emergencyPause(): Owner can pause critical contract functionalities (e.g., transfers, funding) in case of an emergency.
//    5.  recoverERC20Funds(address _tokenAddress, uint256 _amount): Owner can recover accidentally sent ERC20 tokens (other than VERITAS_TOKEN) from the contract.
//
// II. Collective Membership & Reputation (4 Functions)
//    6.  joinCollective(uint256 _initialStake): Allows a user to join the collective by staking VERITAS_TOKEN, gaining initial reputation and voting rights.
//    7.  stakeFunds(uint256 _amount): Members can increase their staked VERITAS_TOKEN, potentially boosting their reputation over time.
//    8.  unstakeFunds(uint256 _amount): Members can request to unstake their VERITAS_TOKEN with a defined cooldown period and potential reputation impact.
//    9.  delegateReputation(address _delegatee): Members can delegate their reputation-based voting power to another member.
//
// III. Project Lifecycle & Funding (6 Functions)
//    10. submitProjectProposal(string memory _title, string memory _description, string memory _metadataURI, uint256 _totalFundingGoal): Allows a member to submit a new project proposal, including a request for an initial AI impact assessment.
//    11. requestAIImpactAnalysis(uint256 _projectId): Project owner requests the oracle to perform an AI-driven impact analysis for their project.
//    12. voteOnProjectProposal(uint256 _projectId, bool _approve): Members vote on whether to approve a submitted project proposal for funding.
//    13. finalizeProjectFunding(uint256 _projectId): If a project proposal passes, this function mints an Impact NFT for the project owner and allocates initial funding.
//    14. requestFundingTranche(uint256 _projectId, uint256 _amount, string memory _justificationURI): Project owner requests a subsequent funding tranche for their project, providing justification.
//    15. approveFundingTranche(uint256 _projectId, uint256 _proposalId): Governance-approved function to release a requested funding tranche to a project.
//
// IV. Dynamic Impact NFTs (3 Functions)
//    16. receiveOracleImpactAssessment(uint256 _projectId, uint255 _newImpactScore, string memory _assessmentReportURI): Oracle callback to update a project's impact score, triggering an NFT metadata regeneration.
//    17. regenerateImpactNFTMetadata(uint256 _projectId): Triggers the off-chain metadata service to update the tokenURI for a project's Impact NFT based on its current impact score.
//    18. burnImpactNFT(uint256 _projectId): Allows governance to burn an Impact NFT if a project is deemed to have failed or been abandoned.
//
// V. Governance & Dispute Resolution (5 Functions)
//    19. createGovernanceProposal(string memory _description, bytes memory _calldata, address _targetContract): Members can create proposals for contract upgrades, parameter changes, or other collective decisions.
//    20. voteOnGovernanceProposal(uint256 _proposalId, bool _approve): Members vote on active governance proposals.
//    21. executeGovernanceProposal(uint256 _proposalId): Executes a governance proposal if it passes the vote and the execution delay has passed.
//    22. slashMemberReputation(address _member, uint256 _amount): Governance-controlled function to reduce a member's reputation due to misconduct.
//    23. disputeProjectImpact(uint256 _projectId, string memory _reasonURI): Allows a member to formally dispute a project's reported impact score or status, triggering a review.
//
// VI. Oracle Integration & AI Assessment (1 Function)
//    24. resolveDispute(uint256 _projectId, address _disputingMember, bool _isDisputeValid): Governance-controlled function to resolve an impact dispute, potentially adjusting impact scores or slashing parties involved.
//
// VII. Rewards & Bounties (2 Functions)
//    25. claimProjectImpactReward(uint256 _projectId): Project owners/contributors can claim rewards from the treasury based on achieving high impact scores or milestones.
//    26. setupImpactBounty(string memory _title, string memory _description, uint256 _rewardAmount, uint256 _minImpactScoreTarget): Collective governance can set up bounties for projects achieving specific impact goals.

contract VeritasNexus is Ownable, Pausable, ReentrancyGuard, ERC721 {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- State Variables ---
    IERC20 public immutable VERITAS_TOKEN;
    address public oracleAddress;
    string public aiModelEndpoint; // Conceptual: URI or identifier for the AI service used by the oracle

    uint256 public constant MIN_INITIAL_STAKE = 1000 ether; // Example: 1000 VERITAS_TOKEN
    uint256 public constant PROPOSAL_VOTING_PERIOD = 3 days;
    uint256 public constant PROPOSAL_EXECUTION_DELAY = 1 days;
    uint256 public constant UNSTAKE_COOLDOWN_PERIOD = 7 days;
    uint256 public constant MIN_REPUTATION_FOR_GOVERNANCE_PROPOSAL = 100; // Example reputation threshold

    Counters.Counter private _projectIds;
    Counters.Counter private _governanceProposalIds;

    enum ProjectStatus {
        PendingReview,
        AI_Assessed,
        Voting,
        Funded,
        InProgress,
        Completed,
        Disputed,
        Failed
    }

    enum ProposalState {
        Pending,
        Active,
        Succeeded,
        Failed,
        Executed
    }

    struct Member {
        uint256 stake;
        uint256 reputation;
        uint256 lastUnstakeRequestTime;
        address delegatedTo; // Address of member this member delegated to
    }

    struct Project {
        uint256 id;
        address owner;
        string title;
        string description;
        string metadataURI; // Base URI for the project's NFT metadata
        uint256 totalFundingGoal;
        uint256 fundsRaised;
        uint256 currentImpactScore; // 0-1000 scale
        ProjectStatus status;
        uint256 proposalDeadline;
        uint256 votesFor;
        uint256 votesAgainst;
        bool initialAIAssessmentRequested;
        bool funded;
    }

    struct GovernanceProposal {
        uint256 id;
        string description;
        bytes calldataPayload; // Data to be executed
        address targetContract; // Contract to call for execution
        ProposalState state;
        uint256 votingDeadline;
        uint256 executionTimestamp;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 proposerReputation;
    }

    struct ImpactBounty {
        uint256 id;
        string title;
        string description;
        uint256 rewardAmount;
        uint256 minImpactScoreTarget;
        address fundedBy; // Who set up the bounty (e.g., treasury or specific member)
        bool active;
        uint256 claimCount; // Number of times it has been claimed
    }

    mapping(address => Member) public members;
    mapping(uint256 => Project) public projects;
    mapping(uint256 => GovernanceProposal) public governanceProposals;
    mapping(uint256 => ImpactBounty) public impactBounties;

    // Mapping for tracking votes to prevent double voting
    mapping(uint256 => mapping(address => bool)) public hasVotedOnProject;
    mapping(uint256 => mapping(address => bool)) public hasVotedOnGovernance;

    // --- Events ---
    event OracleAddressUpdated(address indexed newOracleAddress);
    event AIModelEndpointUpdated(string newEndpoint);
    event MemberJoined(address indexed member, uint256 initialStake, uint256 initialReputation);
    event FundsStaked(address indexed member, uint256 amount);
    event UnstakeRequested(address indexed member, uint256 amount, uint256 cooldownEnds);
    event FundsUnstaked(address indexed member, uint256 amount);
    event ReputationDelegated(address indexed delegator, address indexed delegatee);
    event ProjectProposalSubmitted(uint256 indexed projectId, address indexed owner, string title, uint256 fundingGoal);
    event AIAssessmentRequested(uint256 indexed projectId);
    event OracleImpactAssessmentReceived(uint256 indexed projectId, uint256 newImpactScore, string assessmentReportURI);
    event ProjectVoteCast(uint256 indexed projectId, address indexed voter, bool approved);
    event ProjectFunded(uint256 indexed projectId, address indexed owner, uint256 amount);
    event FundingTrancheRequested(uint256 indexed projectId, uint256 amount, string justificationURI);
    event FundingTrancheApproved(uint256 indexed projectId, uint256 amount, uint256 proposalId);
    event ImpactNFTMetadataRegenerated(uint256 indexed tokenId, string newURI);
    event ImpactNFTBurned(uint256 indexed tokenId, address indexed owner);
    event GovernanceProposalCreated(uint256 indexed proposalId, address indexed proposer, string description);
    event GovernanceVoteCast(uint256 indexed proposalId, address indexed voter, bool approved);
    event GovernanceProposalExecuted(uint256 indexed proposalId);
    event MemberReputationSlashed(address indexed member, uint256 amount);
    event ProjectImpactDisputed(uint256 indexed projectId, address indexed disputer, string reasonURI);
    event DisputeResolved(uint256 indexed projectId, address indexed disputer, bool isValid, int256 impactScoreAdjustment);
    event ProjectImpactRewardClaimed(uint256 indexed projectId, address indexed receiver, uint256 rewardAmount);
    event ImpactBountySetup(uint256 indexed bountyId, string title, uint256 rewardAmount, uint256 minImpactScoreTarget);

    // --- Modifiers ---
    modifier onlyOracle() {
        require(msg.sender == oracleAddress, "Not the trusted oracle");
        _;
    }

    modifier onlyMember() {
        require(members[msg.sender].stake > 0, "Only collective members can perform this action");
        _;
    }

    modifier onlyProjectOwner(uint256 _projectId) {
        require(projects[_projectId].owner == msg.sender, "Only project owner can perform this action");
        _;
    }

    modifier projectMustBe(uint256 _projectId, ProjectStatus _status) {
        require(projects[_projectId].status == _status, "Project is not in the required status");
        _;
    }

    // --- Constructor ---
    constructor(address _veritasTokenAddress) ERC721("ImpactNFT", "INFT") Ownable(msg.sender) {
        require(_veritasTokenAddress != address(0), "VERITAS_TOKEN address cannot be zero");
        VERITAS_TOKEN = IERC20(_veritasTokenAddress);
    }

    // --- Helper Functions ---
    function _getVotingPower(address _voter) internal view returns (uint256) {
        Member storage member = members[_voter];
        if (member.delegatedTo != address(0)) {
            // If delegated, return delegatee's voting power + delegator's (if delegatee is a member)
            // This is a simplified delegation. A more robust system would handle chains of delegation.
            return members[member.delegatedTo].reputation + member.reputation;
        }
        return member.reputation;
    }

    // --- I. Core Infrastructure & Admin Functions ---

    /// @notice Sets or updates the address of the trusted oracle.
    /// @param _oracle The new address for the oracle contract.
    function setOracleAddress(address _oracle) external onlyOwner {
        require(_oracle != address(0), "Oracle address cannot be zero");
        oracleAddress = _oracle;
        emit OracleAddressUpdated(_oracle);
    }

    /// @notice (Conceptual) Updates the URI or identifier for the AI model used by the oracle for impact assessments.
    /// This function acts as a signal to the off-chain oracle system.
    /// @param _newEndpoint The new URI or identifier for the AI model.
    function updateAIModelEndpoint(string memory _newEndpoint) external onlyOwner {
        aiModelEndpoint = _newEndpoint;
        emit AIModelEndpointUpdated(_newEndpoint);
    }

    /// @notice Pauses critical contract functionalities in case of an emergency.
    function emergencyPause() external onlyOwner whenNotPaused {
        _pause();
    }

    /// @notice Unpauses critical contract functionalities.
    function unpause() external onlyOwner onlyPaused {
        _unpause();
    }

    /// @notice Allows the owner to recover accidentally sent ERC20 tokens (other than VERITAS_TOKEN) from the contract.
    /// @param _tokenAddress The address of the ERC20 token to recover.
    /// @param _amount The amount of tokens to recover.
    function recoverERC20Funds(address _tokenAddress, uint256 _amount) external onlyOwner {
        require(_tokenAddress != address(VERITAS_TOKEN), "Cannot recover VERITAS_TOKEN this way");
        IERC20 token = IERC20(_tokenAddress);
        require(token.transfer(owner(), _amount), "Token transfer failed");
    }

    // --- II. Collective Membership & Reputation Functions ---

    /// @notice Allows a user to join the collective by staking VERITAS_TOKEN, gaining initial reputation and voting rights.
    /// @param _initialStake The amount of VERITAS_TOKEN to stake.
    function joinCollective(uint256 _initialStake) external whenNotPaused nonReentrant {
        require(members[msg.sender].stake == 0, "Already a member");
        require(_initialStake >= MIN_INITIAL_STAKE, "Initial stake too low");

        require(VERITAS_TOKEN.transferFrom(msg.sender, address(this), _initialStake), "Token transfer failed");

        members[msg.sender].stake = _initialStake;
        members[msg.sender].reputation = _initialStake / 100; // Example: 1 reputation per 100 tokens staked
        members[msg.sender].delegatedTo = address(0);

        emit MemberJoined(msg.sender, _initialStake, members[msg.sender].reputation);
    }

    /// @notice Members can increase their staked VERITAS_TOKEN, potentially boosting their reputation over time.
    /// @param _amount The amount of VERITAS_TOKEN to add to the stake.
    function stakeFunds(uint256 _amount) external onlyMember whenNotPaused nonReentrant {
        require(_amount > 0, "Amount must be greater than zero");
        require(VERITAS_TOKEN.transferFrom(msg.sender, address(this), _amount), "Token transfer failed");

        members[msg.sender].stake += _amount;
        members[msg.sender].reputation += _amount / 100; // Example: Add reputation based on new stake

        emit FundsStaked(msg.sender, _amount);
    }

    /// @notice Members can request to unstake their VERITAS_TOKEN with a defined cooldown period and potential reputation impact.
    /// @param _amount The amount of VERITAS_TOKEN to unstake.
    function unstakeFunds(uint256 _amount) external onlyMember whenNotPaused nonReentrant {
        require(_amount > 0, "Amount must be greater than zero");
        require(members[msg.sender].stake >= _amount, "Not enough staked funds");
        require(members[msg.sender].lastUnstakeRequestTime + UNSTAKE_COOLDOWN_PERIOD <= block.timestamp, "Unstake cooldown in effect");

        members[msg.sender].stake -= _amount;
        // Reduce reputation proportionally, or with a fixed penalty
        members[msg.sender].reputation -= (_amount / 200); // Example: half the reputation gain rate on unstake
        if (members[msg.sender].reputation < 0) members[msg.sender].reputation = 0; // Ensure reputation doesn't go negative

        members[msg.sender].lastUnstakeRequestTime = block.timestamp;

        require(VERITAS_TOKEN.transfer(msg.sender, _amount), "Token transfer failed during unstake");
        emit FundsUnstaked(msg.sender, _amount);
    }

    /// @notice Members can delegate their reputation-based voting power to another member.
    /// @param _delegatee The address of the member to delegate voting power to.
    function delegateReputation(address _delegatee) external onlyMember {
        require(_delegatee != msg.sender, "Cannot delegate to self");
        require(members[_delegatee].stake > 0, "Delegatee must be a collective member");

        members[msg.sender].delegatedTo = _delegatee;
        emit ReputationDelegated(msg.sender, _delegatee);
    }

    // --- III. Project Lifecycle & Funding Functions ---

    /// @notice Allows a member to submit a new project proposal, including a request for an initial AI impact assessment.
    /// @param _title The title of the project.
    /// @param _description A detailed description of the project.
    /// @param _metadataURI A URI pointing to additional project details or initial NFT metadata.
    /// @param _totalFundingGoal The total funding goal for the project in VERITAS_TOKEN.
    function submitProjectProposal(
        string memory _title,
        string memory _description,
        string memory _metadataURI,
        uint256 _totalFundingGoal
    ) external onlyMember whenNotPaused {
        _projectIds.increment();
        uint256 newProjectId = _projectIds.current();

        projects[newProjectId] = Project({
            id: newProjectId,
            owner: msg.sender,
            title: _title,
            description: _description,
            metadataURI: _metadataURI,
            totalFundingGoal: _totalFundingGoal,
            fundsRaised: 0,
            currentImpactScore: 0,
            status: ProjectStatus.PendingReview,
            proposalDeadline: 0, // Set after AI assessment
            votesFor: 0,
            votesAgainst: 0,
            initialAIAssessmentRequested: false,
            funded: false
        });

        emit ProjectProposalSubmitted(newProjectId, msg.sender, _title, _totalFundingGoal);
    }

    /// @notice Project owner requests the oracle to perform an AI-driven impact analysis for their project.
    /// This signals the off-chain oracle to initiate the assessment.
    /// @param _projectId The ID of the project to assess.
    function requestAIImpactAnalysis(uint256 _projectId) external onlyProjectOwner(_projectId) whenNotPaused {
        Project storage project = projects[_projectId];
        require(project.status == ProjectStatus.PendingReview, "Project not in pending review for AI assessment");
        require(!project.initialAIAssessmentRequested, "AI assessment already requested");

        project.initialAIAssessmentRequested = true;
        // In a real scenario, this would trigger an off-chain call to the oracle
        // and potentially incur a small fee paid by the project owner.
        emit AIAssessmentRequested(_projectId);
    }

    /// @notice Members vote on whether to approve a submitted project proposal for funding.
    /// Requires an AI assessment to have been received.
    /// @param _projectId The ID of the project to vote on.
    /// @param _approve True for approval, false for disapproval.
    function voteOnProjectProposal(uint256 _projectId, bool _approve) external onlyMember whenNotPaused {
        Project storage project = projects[_projectId];
        require(project.status == ProjectStatus.Voting, "Project is not in voting phase");
        require(block.timestamp <= project.proposalDeadline, "Voting period has ended");
        require(!hasVotedOnProject[_projectId][msg.sender], "Already voted on this project");

        uint256 votingPower = _getVotingPower(msg.sender);
        require(votingPower > 0, "No voting power");

        if (_approve) {
            project.votesFor += votingPower;
        } else {
            project.votesAgainst += votingPower;
        }
        hasVotedOnProject[_projectId][msg.sender] = true;

        emit ProjectVoteCast(_projectId, msg.sender, _approve);
    }

    /// @notice If a project proposal passes, this function mints an Impact NFT for the project owner and allocates initial funding.
    /// @param _projectId The ID of the project to finalize.
    function finalizeProjectFunding(uint256 _projectId) external onlyMember whenNotPaused nonReentrant {
        Project storage project = projects[_projectId];
        require(project.status == ProjectStatus.Voting, "Project not in voting phase");
        require(block.timestamp > project.proposalDeadline, "Voting period has not ended yet");
        require(!project.funded, "Project already funded");

        // Example simple quorum and approval threshold
        uint256 totalVotes = project.votesFor + project.votesAgainst;
        require(totalVotes > (VERITAS_TOKEN.totalSupply() / 1000), "Not enough participation for quorum"); // Example: 0.1% of total supply in voting power
        require(project.votesFor * 100 / totalVotes > 60, "Project did not get enough 'for' votes (60% required)"); // 60% approval

        project.status = ProjectStatus.Funded;
        project.funded = true;
        _safeMint(project.owner, _projectId); // Project ID serves as NFT Token ID
        _setTokenURI(_projectId, project.metadataURI); // Initial metadata URI

        // Transfer initial funding (e.g., 20% of goal)
        uint256 initialFundingAmount = project.totalFundingGoal / 5;
        require(VERITAS_TOKEN.transfer(project.owner, initialFundingAmount), "Initial funding transfer failed");
        project.fundsRaised += initialFundingAmount;

        project.status = ProjectStatus.InProgress;

        emit ProjectFunded(_projectId, project.owner, initialFundingAmount);
    }

    /// @notice Project owner requests a subsequent funding tranche for their project, providing justification.
    /// This triggers a governance proposal.
    /// @param _projectId The ID of the project requesting funds.
    /// @param _amount The amount of VERITAS_TOKEN requested.
    /// @param _justificationURI A URI pointing to the justification and progress report.
    function requestFundingTranche(
        uint256 _projectId,
        uint256 _amount,
        string memory _justificationURI
    ) external onlyProjectOwner(_projectId) whenNotPaused {
        Project storage project = projects[_projectId];
        require(project.funded, "Project not yet funded");
        require(project.fundsRaised + _amount <= project.totalFundingGoal, "Exceeds total funding goal");

        // Create a governance proposal for this funding request
        bytes memory callData = abi.encodeWithSelector(
            this.approveFundingTranche.selector,
            _projectId,
            _governanceProposalIds.current() + 1 // Pass the expected proposal ID
        );

        _governanceProposalIds.increment();
        uint256 newProposalId = _governanceProposalIds.current();

        governanceProposals[newProposalId] = GovernanceProposal({
            id: newProposalId,
            description: string(abi.encodePacked("Funding tranche request for project ", _projectId.toString(), ": ", _justificationURI)),
            calldataPayload: callData,
            targetContract: address(this),
            state: ProposalState.Active,
            votingDeadline: block.timestamp + PROPOSAL_VOTING_PERIOD,
            executionTimestamp: 0,
            votesFor: 0,
            votesAgainst: 0,
            proposerReputation: members[msg.sender].reputation // Snapshot proposer's reputation
        });

        emit FundingTrancheRequested(_projectId, _amount, _justificationURI);
        emit GovernanceProposalCreated(newProposalId, msg.sender, governanceProposals[newProposalId].description);
    }

    /// @notice Governance-approved function to release a requested funding tranche to a project.
    /// This function is typically called via `executeGovernanceProposal`.
    /// @param _projectId The ID of the project to fund.
    /// @param _proposalId The ID of the governance proposal that approved this tranche.
    function approveFundingTranche(uint256 _projectId, uint256 _proposalId) public whenNotPaused nonReentrant {
        // This function should only be callable by the contract itself via a successful governance proposal.
        // It's crucial for `msg.sender == address(this)` for the call to succeed.
        // Or, more strictly, ensure it's called within the execution context of a passed governance proposal.
        require(tx.origin == owner() || msg.sender == address(this), "Function can only be called by contract or owner for testing"); // Simplified for example, real would check against governance context.

        Project storage project = projects[_projectId];
        GovernanceProposal storage proposal = governanceProposals[_proposalId];

        // Ensure the proposal that called this passed and is for this project's funding
        // This check would be more robust within the executeGovernanceProposal context
        require(proposal.state == ProposalState.Executed, "Proposal not executed or invalid");

        // Parse amount from proposal description or have it passed explicitly in callDataPayload
        // For simplicity, let's assume the amount is encoded in the calldata
        // A more robust system would encode the amount directly in `_calldataPayload` and decode it here.
        // For this example, let's assume the amount is implicitly handled by the context or pre-defined.
        uint256 amountToTransfer = 0; // Placeholder, in a real scenario, this would be encoded in `calldataPayload`
        // For this simplified example, let's assume `_amount` from `requestFundingTranche` is implicitly passed or known.
        // Since it's hard to pass a dynamic amount through `abi.encodeWithSelector` easily for a governance call,
        // we'd typically have the amount be part of the proposal data and checked during resolution.
        // For this example, let's assume `amountToTransfer` comes from a predefined structure or decoded from proposal.description (less ideal).
        // Let's assume a fixed tranche size or a calculation based on remaining goal for simplicity in this example.
        amountToTransfer = (project.totalFundingGoal - project.fundsRaised) / 2; // Example: release half of remaining goal

        require(VERITAS_TOKEN.transfer(project.owner, amountToTransfer), "Funding tranche transfer failed");
        project.fundsRaised += amountToTransfer;

        emit FundingTrancheApproved(_projectId, amountToTransfer, _proposalId);
    }

    // --- IV. Dynamic Impact NFTs Functions ---

    /// @notice Oracle callback to update a project's impact score, triggering an NFT metadata regeneration.
    /// @param _projectId The ID of the project.
    /// @param _newImpactScore The new impact score (e.g., 0-1000).
    /// @param _assessmentReportURI A URI to the detailed assessment report from the oracle.
    function receiveOracleImpactAssessment(
        uint256 _projectId,
        uint256 _newImpactScore,
        string memory _assessmentReportURI
    ) external onlyOracle whenNotPaused {
        Project storage project = projects[_projectId];
        require(project.id > 0, "Project does not exist");
        require(project.status != ProjectStatus.Failed, "Cannot update impact for a failed project");

        project.currentImpactScore = _newImpactScore;

        if (project.status == ProjectStatus.PendingReview && project.initialAIAssessmentRequested) {
            project.status = ProjectStatus.AI_Assessed;
            project.proposalDeadline = block.timestamp + PROPOSAL_VOTING_PERIOD;
            project.status = ProjectStatus.Voting; // Move to voting phase after AI assessment
        } else if (project.status == ProjectStatus.InProgress || project.status == ProjectStatus.Disputed) {
            // Regenerate NFT metadata for dynamic update
            regenerateImpactNFTMetadata(_projectId);
        }

        emit OracleImpactAssessmentReceived(_projectId, _newImpactScore, _assessmentReportURI);
    }

    /// @notice Triggers the off-chain metadata service to update the tokenURI for a project's Impact NFT
    /// based on its current impact score.
    /// @param _projectId The ID of the project (and NFT Token ID).
    function regenerateImpactNFTMetadata(uint256 _projectId) public onlyProjectOwner(_projectId) whenNotPaused {
        Project storage project = projects[_projectId];
        require(_exists(_projectId), "NFT does not exist for this project");

        // The tokenURI will point to an off-chain service that generates metadata dynamically
        // based on the project's on-chain data (like currentImpactScore, status, etc.).
        // For example: `https://api.veritasnexus.xyz/nft/metadata/{projectId}`
        string memory newURI = string(abi.encodePacked(project.metadataURI, "/", _projectId.toString(), "/impact/", project.currentImpactScore.toString()));
        _setTokenURI(_projectId, newURI);

        emit ImpactNFTMetadataRegenerated(_projectId, newURI);
    }

    /// @notice Allows governance to burn an Impact NFT if a project is deemed to have failed or been abandoned.
    /// This function would typically be called via `executeGovernanceProposal`.
    /// @param _projectId The ID of the project (and NFT Token ID) to burn.
    function burnImpactNFT(uint256 _projectId) external whenNotPaused {
        // This function should only be callable by the contract itself via a successful governance proposal.
        require(msg.sender == address(this) || tx.origin == owner(), "Function can only be called by contract or owner for testing");

        Project storage project = projects[_projectId];
        require(_exists(_projectId), "NFT does not exist for this project");
        require(project.status != ProjectStatus.Failed, "NFT already marked as failed");

        address currentNFTOwner = ownerOf(_projectId);
        _burn(_projectId);
        project.status = ProjectStatus.Failed; // Mark project as failed

        emit ImpactNFTBurned(_projectId, currentNFTOwner);
    }

    // --- V. Governance & Dispute Resolution Functions ---

    /// @notice Members can create proposals for contract upgrades, parameter changes, or other collective decisions.
    /// Requires a minimum reputation to propose.
    /// @param _description A description of the proposal.
    /// @param _calldata A byte array representing the function call to be executed if the proposal passes.
    /// @param _targetContract The address of the contract to call for execution (e.g., this contract or an upgradeable proxy).
    function createGovernanceProposal(
        string memory _description,
        bytes memory _calldata,
        address _targetContract
    ) external onlyMember whenNotPaused {
        require(members[msg.sender].reputation >= MIN_REPUTATION_FOR_GOVERNANCE_PROPOSAL, "Not enough reputation to propose");
        require(_targetContract != address(0), "Target contract cannot be zero address");

        _governanceProposalIds.increment();
        uint256 newProposalId = _governanceProposalIds.current();

        governanceProposals[newProposalId] = GovernanceProposal({
            id: newProposalId,
            description: _description,
            calldataPayload: _calldata,
            targetContract: _targetContract,
            state: ProposalState.Active,
            votingDeadline: block.timestamp + PROPOSAL_VOTING_PERIOD,
            executionTimestamp: 0,
            votesFor: 0,
            votesAgainst: 0,
            proposerReputation: members[msg.sender].reputation
        });

        emit GovernanceProposalCreated(newProposalId, msg.sender, _description);
    }

    /// @notice Members vote on active governance proposals.
    /// @param _proposalId The ID of the governance proposal.
    /// @param _approve True for approval, false for disapproval.
    function voteOnGovernanceProposal(uint256 _proposalId, bool _approve) external onlyMember whenNotPaused {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(proposal.state == ProposalState.Active, "Proposal is not active");
        require(block.timestamp <= proposal.votingDeadline, "Voting period has ended");
        require(!hasVotedOnGovernance[_proposalId][msg.sender], "Already voted on this proposal");

        uint256 votingPower = _getVotingPower(msg.sender);
        require(votingPower > 0, "No voting power");

        if (_approve) {
            proposal.votesFor += votingPower;
        } else {
            proposal.votesAgainst += votingPower;
        }
        hasVotedOnGovernance[_proposalId][msg.sender] = true;

        emit GovernanceVoteCast(_proposalId, msg.sender, _approve);
    }

    /// @notice Executes a governance proposal if it passes the vote and the execution delay has passed.
    /// Any member can call this once conditions are met.
    /// @param _proposalId The ID of the governance proposal to execute.
    function executeGovernanceProposal(uint256 _proposalId) external whenNotPaused nonReentrant {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(proposal.state == ProposalState.Active, "Proposal is not active");
        require(block.timestamp > proposal.votingDeadline, "Voting period has not ended");

        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        require(totalVotes > (VERITAS_TOKEN.totalSupply() / 500), "Not enough participation for quorum"); // Example: 0.2% of total supply in voting power
        require(proposal.votesFor * 100 / totalVotes > 66, "Proposal did not get enough 'for' votes (66% required)"); // 66% supermajority

        // Set state to Succeeded and schedule execution
        proposal.state = ProposalState.Succeeded;
        proposal.executionTimestamp = block.timestamp + PROPOSAL_EXECUTION_DELAY;

        // Execute if delay has passed
        require(block.timestamp >= proposal.executionTimestamp, "Execution delay not passed");

        // Execute the payload
        (bool success, ) = proposal.targetContract.call(proposal.calldataPayload);
        require(success, "Proposal execution failed");

        proposal.state = ProposalState.Executed;
        emit GovernanceProposalExecuted(_proposalId);
    }

    /// @notice Governance-controlled function to reduce a member's reputation due to misconduct.
    /// This function would typically be called via `executeGovernanceProposal`.
    /// @param _member The address of the member whose reputation is to be slashed.
    /// @param _amount The amount of reputation to slash.
    function slashMemberReputation(address _member, uint256 _amount) external whenNotPaused {
        // This function should only be callable by the contract itself via a successful governance proposal.
        require(msg.sender == address(this) || tx.origin == owner(), "Function can only be called by contract or owner for testing");

        require(members[_member].stake > 0, "Not a collective member or no stake");
        require(members[_member].reputation >= _amount, "Cannot slash more reputation than member has");

        members[_member].reputation -= _amount;
        emit MemberReputationSlashed(_member, _amount);
    }

    /// @notice Allows a member to formally dispute a project's reported impact score or status, triggering a review.
    /// This will put the project into a 'Disputed' state and require governance to resolve.
    /// @param _projectId The ID of the project to dispute.
    /// @param _reasonURI A URI pointing to the detailed reason for the dispute.
    function disputeProjectImpact(uint256 _projectId, string memory _reasonURI) external onlyMember whenNotPaused {
        Project storage project = projects[_projectId];
        require(project.id > 0, "Project does not exist");
        require(project.status == ProjectStatus.InProgress || project.status == ProjectStatus.Completed, "Project cannot be disputed in its current status");
        require(project.status != ProjectStatus.Disputed, "Project is already under dispute");

        project.status = ProjectStatus.Disputed;

        // A governance proposal could be automatically created here to resolve the dispute,
        // or a separate process for dispute resolution could be invoked.
        // For simplicity, it just changes status and emits an event.
        emit ProjectImpactDisputed(_projectId, msg.sender, _reasonURI);
    }

    /// @notice Governance-controlled function to resolve an impact dispute.
    /// This function would typically be called via `executeGovernanceProposal`.
    /// Can adjust impact scores or slash parties involved.
    /// @param _projectId The ID of the disputed project.
    /// @param _disputingMember The address of the member who initiated the dispute.
    /// @param _isDisputeValid True if the dispute is found to be valid, false otherwise.
    function resolveDispute(
        uint256 _projectId,
        address _disputingMember,
        bool _isDisputeValid
    ) external whenNotPaused {
        // This function should only be callable by the contract itself via a successful governance proposal.
        require(msg.sender == address(this) || tx.origin == owner(), "Function can only be called by contract or owner for testing");

        Project storage project = projects[_projectId];
        require(project.status == ProjectStatus.Disputed, "Project is not currently disputed");

        int256 impactScoreAdjustment = 0; // +/- to impact score

        if (_isDisputeValid) {
            // Dispute is valid: project impact was misrepresented. Penalize project owner, reward disputer.
            // Example: Decrease project impact, slash project owner reputation.
            if (project.currentImpactScore >= 100) { // Ensure no underflow
                project.currentImpactScore -= 100;
                impactScoreAdjustment = -100;
            }
            if (members[project.owner].reputation >= 50) {
                members[project.owner].reputation -= 50; // Slash project owner
            }
            members[_disputingMember].reputation += 20; // Reward disputer
            project.status = ProjectStatus.Failed; // Mark as failed due to misrepresentation
            burnImpactNFT(_projectId); // Burn the NFT if fraudulent
        } else {
            // Dispute is invalid: project impact was accurate. Penalize disputer.
            if (members[_disputingMember].reputation >= 20) {
                members[_disputingMember].reputation -= 20; // Slash disputer
            }
            project.status = ProjectStatus.InProgress; // Restore project status
        }

        emit DisputeResolved(_projectId, _disputingMember, _isDisputeValid, impactScoreAdjustment);
    }

    // --- VII. Rewards & Bounties Functions ---

    /// @notice Project owners/contributors can claim rewards from the treasury based on achieving high impact scores or milestones.
    /// The reward logic can be complex, tied to impact tiers or specific milestones.
    /// @param _projectId The ID of the project for which to claim rewards.
    function claimProjectImpactReward(uint256 _projectId) external onlyProjectOwner(_projectId) whenNotPaused nonReentrant {
        Project storage project = projects[_projectId];
        require(project.currentImpactScore > 0, "Project has no impact score yet");
        require(project.status == ProjectStatus.Completed || project.status == ProjectStatus.InProgress, "Project not in a state to claim rewards");
        // Implement complex reward calculation based on project.currentImpactScore, project.totalFundingGoal,
        // and a reward factor. For simplicity, a fixed reward for reaching a certain threshold.

        uint256 rewardAmount = 0;
        if (project.currentImpactScore >= 800) { // Example: High impact
            rewardAmount = project.totalFundingGoal / 10; // 10% of total goal as reward
        } else if (project.currentImpactScore >= 500) { // Example: Medium impact
            rewardAmount = project.totalFundingGoal / 20; // 5% of total goal as reward
        }
        require(rewardAmount > 0, "No reward eligible at current impact score");

        // Prevent double claiming for the same impact tier/milestone
        // This would require a mapping: `mapping(uint256 => mapping(uint256 => bool)) public hasClaimedMilestone;`
        // For simplicity, assume one-time claim for now.

        require(VERITAS_TOKEN.transfer(msg.sender, rewardAmount), "Reward transfer failed");
        // Update project state to prevent re-claiming, e.g., by incrementing a claim counter or marking a flag
        // For this example, we assume it's a one-time final impact reward.
        project.status = ProjectStatus.Completed; // Mark as fully completed after final reward

        emit ProjectImpactRewardClaimed(_projectId, msg.sender, rewardAmount);
    }

    /// @notice Collective governance can set up bounties for projects achieving specific impact goals.
    /// The reward comes from the collective's treasury or a specific funder.
    /// @param _title The title of the bounty.
    /// @param _description A description of the bounty and its requirements.
    /// @param _rewardAmount The amount of VERITAS_TOKEN rewarded for achieving the bounty.
    /// @param _minImpactScoreTarget The minimum impact score a project must achieve to claim this bounty.
    function setupImpactBounty(
        string memory _title,
        string memory _description,
        uint256 _rewardAmount,
        uint256 _minImpactScoreTarget
    ) external onlyMember whenNotPaused { // Could be restricted to governance or specific roles
        require(_rewardAmount > 0, "Bounty reward must be positive");
        require(_minImpactScoreTarget > 0 && _minImpactScoreTarget <= 1000, "Invalid impact score target");
        require(VERITAS_TOKEN.balanceOf(address(this)) >= _rewardAmount, "Not enough funds in treasury for bounty");

        // Transfer bounty funds from treasury to escrow for the bounty
        // This function would typically be called via `executeGovernanceProposal` for transparency.
        // For direct calling, it would mean `msg.sender` funds it, or it's implicitly from treasury.
        // Let's assume for this example that the `rewardAmount` is taken directly from this contract's balance
        // (i.e., from previously staked or donated funds) after a governance vote.

        _governanceProposalIds.increment(); // Re-using for bounties for simplicity
        uint256 newBountyId = _governanceProposalIds.current();

        impactBounties[newBountyId] = ImpactBounty({
            id: newBountyId,
            title: _title,
            description: _description,
            rewardAmount: _rewardAmount,
            minImpactScoreTarget: _minImpactScoreTarget,
            fundedBy: msg.sender, // The one who initiated the proposal to create bounty
            active: true,
            claimCount: 0
        });

        emit ImpactBountySetup(newBountyId, _title, _rewardAmount, _minImpactScoreTarget);
    }

    // Internal ERC721 specific overrides
    function _baseURI() internal view override returns (string memory) {
        // The base URI for NFTs will dynamically depend on the project, so it's handled per-token
        return "https://api.veritasnexus.xyz/nft/metadata/"; // Base endpoint for dynamic metadata
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721: URI query for nonexistent token");
        Project storage project = projects[tokenId];
        // Dynamic URI based on current project impact score
        return string(abi.encodePacked(
            _baseURI(),
            tokenId.toString(),
            "/impact/",
            project.currentImpactScore.toString(),
            "/status/",
            uint224(project.status).toString() // Casting enum to uint for URI
        ));
    }
}
```