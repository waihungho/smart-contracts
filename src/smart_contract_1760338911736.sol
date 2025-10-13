Here's a Solidity smart contract named `GenesisForge` that implements a decentralized innovation lab with advanced concepts like AI oracle integration, dynamic IP NFTs, and nuanced project lifecycle management. It includes more than 20 functions, each serving a unique purpose within the ecosystem.

---

## Contract: `GenesisForge`

**Overview:**
`GenesisForge` is a cutting-edge smart contract platform designed to foster decentralized research, development, and intellectual property (IP) creation. It enables innovators to propose projects, secure funding, collaborate, and dynamically manage the ownership, licensing, and monetization of their resulting IP. The platform heavily integrates with AI oracles for objective project scoring, milestone verification, and IP valuation, aiming to introduce a layer of sophisticated, data-driven decision-making into decentralized innovation.

**Core Concepts:**
*   **Project Lifecycle**: Projects move through states: Proposed, Funded, Active, Completed, Cancelled, Disputed.
*   **Milestone-Based Funding**: Projects are funded incrementally based on verifiable milestones.
*   **Dynamic IP NFTs**: ERC-721 tokens representing project IP, with mutable metadata and fractional ownership/royalty distribution features managed by the contract.
*   **AI Oracle Integration**: Asynchronous callback mechanism for external AI services to provide scores, verifications, and valuations.
*   **Role-Based Access**: Utilizes OpenZeppelin's `AccessControl` for managing `ADMIN`, `VALIDATOR`, `ARBITRATOR`, and `ORACLE_RESPONDER` roles.
*   **Staking & Rewards**: Users stake `GenesisToken` (ERC20) for project funding, and various participants can claim rewards.
*   **Dispute Resolution**: A mechanism for formal disputes, handled by arbitrators or potentially AI-assisted resolution.

---

### Function Summary:

**I. Core Project Lifecycle Management**
1.  `proposeProject(string calldata _title, string calldata _description, uint256 _fundingGoal, uint256 _milestoneCount, bytes32[] calldata _milestoneHashes)`: Allows any user to propose a new R&D project with details and hashed milestones.
2.  `stakeForProjectFunding(uint256 _projectId, uint256 _amount)`: Enables users to stake `GenesisToken` to fund a specific project.
3.  `unstakeFromProjectFunding(uint256 _projectId, uint256 _amount)`: Allows stakers to withdraw funds if the project hasn't started or is cancelled.
4.  `initiateProject(uint256 _projectId)`: Marks a project as "Active" once its funding goal is met, allowing the proposer to start work.
5.  `submitMilestoneProof(uint256 _projectId, uint256 _milestoneIndex, bytes32 _proofHash)`: Project proposer submits a hash representing proof of milestone completion.
6.  `verifyMilestone(uint256 _projectId, uint256 _milestoneIndex)`: A designated `VALIDATOR_ROLE` member can verify a submitted milestone proof.
7.  `requestMilestoneVerificationFromAI(uint256 _projectId, uint256 _milestoneIndex, bytes calldata _dataForAI)`: Requests the AI Oracle to verify a milestone, expecting a callback.
8.  `processOracleResponse_MilestoneVerification(uint256 _projectId, uint256 _milestoneIndex, bool _isVerified, string calldata _reasoning)`: Callback function for the AI Oracle to report milestone verification status.
9.  `withdrawProjectFunds(uint256 _projectId, uint256 _milestoneIndex)`: Proposers can withdraw funds allocated to a *verified* milestone.
10. `completeProject(uint256 _projectId)`: Marks a project as "Completed" after all milestones are verified.

**II. Dynamic IP & NFT Management (ERC-721-like functionality)**
11. `mintDynamicIPNFT(uint256 _projectId, string calldata _tokenURI)`: Mints a unique Dynamic IP NFT for a completed project, representing its intellectual property.
12. `updateIPNFTMetadata(uint256 _tokenId, string calldata _newTokenURI)`: Allows the IP NFT owner (or `GenesisForge` if it holds ownership) to update its metadata.
13. `assignIPFractionalOwnership(uint256 _tokenId, address[] calldata _recipients, uint256[] calldata _shares)`: Distributes fractional ownership shares of an IP NFT to multiple addresses, managed internally.
14. `transferIPNFTRoyaltyShare(uint256 _tokenId, address _from, address _to, uint256 _sharePercentage)`: Transfers a percentage of future royalty distributions associated with an IP NFT.
15. `licenseIPNFTUsage(uint256 _tokenId, address _licensee, uint256 _duration, uint256 _fee)`: Grants a time-bound license for commercial or research usage of the underlying IP, requiring a fee.
16. `revokeIPNFTLicense(uint256 _tokenId, address _licensee)`: Allows the IP NFT owner to revoke an active license.
17. `collectIPNFTRoyalties(uint256 _tokenId)`: Allows fractional owners to collect accumulated royalties from IP usage.

**III. AI Oracle Integration & External Data**
18. `setAIOracleAddress(address _newOracleAddress)`: Sets the address of the trusted AI Oracle contract. (Admin only)
19. `requestProjectScoreFromAI(uint256 _projectId, bytes calldata _promptData)`: Requests the AI Oracle to provide an objective score for a project proposal.
20. `processOracleResponse_ProjectScore(uint256 _projectId, uint256 _score, string calldata _reasoning)`: Callback function for the AI Oracle to report a project score.
21. `requestIPValuationFromAI(uint256 _tokenId, bytes calldata _data)`: Requests the AI Oracle to assess and provide a valuation for a specific IP NFT.
22. `processOracleResponse_IPValuation(uint256 _tokenId, uint256 _valuation, string calldata _metrics)`: Callback function for the AI Oracle to report an IP valuation.

**IV. Governance & Roles**
23. `delegateVotingPower(address _delegatee)`: Allows users to delegate their staked tokens' voting power to another address for governance proposals.
24. `proposeGovernanceChange(string calldata _description, address _targetContract, bytes calldata _callData)`: Allows eligible stakers to propose changes to contract parameters or logic.
25. `voteOnProposal(uint256 _proposalId, bool _support)`: Stakers or their delegates can vote on active governance proposals.
26. `assignRole(address _user, bytes32 _role)`: Assigns a specific role (e.g., `VALIDATOR_ROLE`, `ARBITRATOR_ROLE`) to a user. (`DEFAULT_ADMIN_ROLE` or Governance)

**V. Dispute Resolution**
27. `initiateDispute(uint256 _projectIdOrTokenId, bytes32 _disputeType, string calldata _description, uint256 _collateralAmount)`: Initiates a formal dispute against a project, milestone, or IP NFT, requiring collateral.
28. `submitArbitrationEvidence(uint256 _disputeId, bytes32 _evidenceHash)`: Parties involved in a dispute can submit evidence.
29. `resolveDisputeByArbitrator(uint256 _disputeId, address _winner, uint256 _penaltyPercentage)`: An assigned `ARBITRATOR_ROLE` member resolves the dispute, distributing collateral and imposing penalties.

**VI. Treasury & Rewards**
30. `claimRewards()`: Allows various participants (stakers, successful proposers, arbitrators) to claim their earned rewards.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// --- Minimal ERC20 for demonstration (GenesisToken) ---
// In a real scenario, this would be a separate, deployed ERC20 contract.
contract GenesisToken is IERC20 {
    using SafeMath for uint256;
    string public name = "Genesis Token";
    string public symbol = "GEN";
    uint8 public immutable decimals = 18;
    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    constructor(uint256 initialSupply) {
        _totalSupply = initialSupply * (10**uint256(decimals));
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function totalSupply() public view override returns (uint256) { return _totalSupply; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }
    function allowance(address owner, address spender) public view override returns (uint256) { return _allowances[owner][spender]; }
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}


// --- AI Oracle Interface for asynchronous callbacks ---
// In a real scenario, this would be a separate, more complex contract
// or an external service interacting with a simple on-chain interface.
interface IAIOracle {
    function requestProjectScore(uint256 projectId, bytes calldata promptData, address callbackContract) external;
    function requestMilestoneVerification(uint256 projectId, uint256 milestoneIndex, bytes calldata dataForAI, address callbackContract) external;
    function requestIPValuation(uint256 tokenId, bytes calldata data, address callbackContract) external;
}


// --- Main GenesisForge Contract ---
contract GenesisForge is ERC721, AccessControl {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // --- Roles ---
    bytes32 public constant VALIDATOR_ROLE = keccak256("VALIDATOR_ROLE");
    bytes32 public constant ARBITRATOR_ROLE = keccak256("ARBITRATOR_ROLE");
    bytes32 public constant ORACLE_RESPONDER_ROLE = keccak256("ORACLE_RESPONDER_ROLE"); // For trusted AI oracle contract

    // --- State Variables ---
    IERC20 public genesisToken;
    IAIOracle public aiOracle;

    Counters.Counter private _projectIds;
    Counters.Counter private _ipTokenIds;
    Counters.Counter private _governanceProposalIds;
    Counters.Counter private _disputeIds;

    enum ProjectState { Proposed, Funded, Active, Completed, Cancelled, Disputed }

    struct Milestone {
        bytes32 hash;           // Hash of milestone description/requirements
        bool isVerified;        // True if milestone proof has been verified
        uint256 fundsAllocated; // Amount allocated to this milestone
        bytes32 proofHash;      // Hash of the submitted proof
    }

    struct Project {
        address proposer;
        string title;
        string description;
        uint256 fundingGoal;
        uint256 fundedAmount;
        ProjectState state;
        Milestone[] milestones;
        uint256 ipTokenId; // 0 if no IP NFT minted yet
        uint256 projectScore; // From AI oracle, 0 if not scored
        address[] stakers; // To track who staked
        mapping(address => uint256) stakes; // Amount staked by each staker
        mapping(uint256 => bool) milestoneVerificationPending; // Track pending oracle requests
    }
    mapping(uint256 => Project) public projects;

    struct DynamicIPNFT {
        string tokenURI;
        uint256 projectId;
        uint256 valuation; // From AI oracle, 0 if not valued
        mapping(address => uint256) fractionalOwnershipShares; // Basis points (e.g., 100 = 1%)
        mapping(address => uint256) accruedRoyalties;
        mapping(address => uint256) activeLicenses; // Licensee => expirationTimestamp
    }
    mapping(uint256 => DynamicIPNFT) public ipNFTs; // IP token ID => IP data

    enum ProposalState { Pending, Active, Succeeded, Defeated, Executed }

    struct GovernanceProposal {
        address proposer;
        string description;
        address targetContract;
        bytes callData;
        uint256 voteStartTime;
        uint256 voteEndTime;
        uint256 yayVotes;
        uint256 nayVotes;
        ProposalState state;
        mapping(address => bool) hasVoted;
    }
    mapping(uint256 => GovernanceProposal) public governanceProposals;

    struct Dispute {
        address initiator;
        bytes32 disputeType; // e.g., keccak256("MILSTONE_FAILED"), keccak256("IP_INFRINGEMENT")
        string description;
        uint256 collateralAmount;
        address primarySubject; // Project proposer or IP NFT owner
        uint256 projectIdOrTokenId; // The ID of the project/IP NFT in dispute
        address winner;
        uint256 penaltyPercentage; // Penalty from loser to winner, basis points
        mapping(address => bool) evidenceSubmitted; // Placeholder for evidence tracking
        bool resolved;
    }
    mapping(uint256 => Dispute) public disputes;

    mapping(address => uint256) public delegatedVotingPower;
    mapping(address => uint256) public pendingRewards; // For various participants

    // --- Events ---
    event ProjectProposed(uint256 indexed projectId, address indexed proposer, string title, uint256 fundingGoal);
    event TokensStakedForProject(uint256 indexed projectId, address indexed staker, uint256 amount);
    event TokensUnstakedFromProject(uint256 indexed projectId, address indexed staker, uint256 amount);
    event ProjectInitiated(uint256 indexed projectId);
    event MilestoneProofSubmitted(uint256 indexed projectId, uint256 indexed milestoneIndex, bytes32 proofHash);
    event MilestoneVerified(uint256 indexed projectId, uint256 indexed milestoneIndex, bool isVerified);
    event ProjectFundsWithdrawn(uint256 indexed projectId, uint256 indexed milestoneIndex, uint256 amount);
    event ProjectCompleted(uint256 indexed projectId);

    event IPNFTMinted(uint256 indexed tokenId, uint256 indexed projectId, address indexed owner, string tokenURI);
    event IPNFTMetadataUpdated(uint256 indexed tokenId, string newTokenURI);
    event FractionalOwnershipAssigned(uint256 indexed tokenId, address indexed recipient, uint256 shares);
    event RoyaltyShareTransferred(uint256 indexed tokenId, address indexed from, address indexed to, uint256 sharePercentage);
    event IPLicenseGranted(uint256 indexed tokenId, address indexed licensee, uint256 duration, uint256 fee);
    event IPLicenseRevoked(uint256 indexed tokenId, address indexed licensee);
    event RoyaltiesCollected(uint256 indexed tokenId, address indexed collector, uint256 amount);

    event AIOracleAddressSet(address indexed newOracleAddress);
    event ProjectScoreRequested(uint256 indexed projectId, bytes promptData);
    event ProjectScoreReceived(uint256 indexed projectId, uint256 score, string reasoning);
    event IPValuationRequested(uint256 indexed tokenId, bytes data);
    event IPValuationReceived(uint256 indexed tokenId, uint256 valuation, string metrics);

    event VotingPowerDelegated(address indexed delegator, address indexed delegatee);
    event GovernanceProposalCreated(uint256 indexed proposalId, address indexed proposer, string description);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalStateChanged(uint256 indexed proposalId, ProposalState newState);

    event DisputeInitiated(uint256 indexed disputeId, address indexed initiator, uint256 projectIdOrTokenId, bytes32 disputeType);
    event ArbitrationEvidenceSubmitted(uint256 indexed disputeId, address indexed submitter, bytes32 evidenceHash);
    event DisputeResolved(uint256 indexed disputeId, address indexed winner, uint256 penaltyToLoser);

    event RewardsClaimed(address indexed claimant, uint256 amount);

    // --- Constructor ---
    constructor(address _genesisTokenAddress, address _aiOracleAddress)
        ERC721("Dynamic IP NFT", "DIPN")
        AccessControl("GenesisForge", "GF")
    {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        genesisToken = IERC20(_genesisTokenAddress);
        aiOracle = IAIOracle(_aiOracleAddress);
    }

    // --- Modifiers ---
    modifier onlyRole(bytes32 role) {
        require(hasRole(role, msg.sender), "GenesisForge: Not authorized for this role");
        _;
    }

    modifier onlyProposer(uint256 _projectId) {
        require(projects[_projectId].proposer == msg.sender, "GenesisForge: Only project proposer can call this function");
        _;
    }

    modifier projectExists(uint256 _projectId) {
        require(_projectId > 0 && _projectId <= _projectIds.current(), "GenesisForge: Project does not exist");
        _;
    }

    modifier ipNFTExists(uint256 _tokenId) {
        require(_tokenId > 0 && _tokenId <= _ipTokenIds.current(), "GenesisForge: IP NFT does not exist");
        _;
    }

    // --- I. Core Project Lifecycle Management ---

    /**
     * @notice Propose a new research or development project.
     * @param _title Project title.
     * @param _description Detailed project description.
     * @param _fundingGoal Target funding amount in Genesis Tokens.
     * @param _milestoneCount Number of milestones for the project.
     * @param _milestoneHashes Array of keccak256 hashes of milestone descriptions/requirements.
     */
    function proposeProject(
        string calldata _title,
        string calldata _description,
        uint256 _fundingGoal,
        uint256 _milestoneCount,
        bytes32[] calldata _milestoneHashes
    ) external {
        require(_fundingGoal > 0, "GenesisForge: Funding goal must be greater than zero");
        require(_milestoneCount > 0, "GenesisForge: Project must have at least one milestone");
        require(_milestoneCount == _milestoneHashes.length, "GenesisForge: Milestone count and hashes mismatch");

        _projectIds.increment();
        uint256 newProjectId = _projectIds.current();

        Milestone[] memory newMilestones = new Milestone[](_milestoneCount);
        for (uint256 i = 0; i < _milestoneCount; i++) {
            newMilestones[i].hash = _milestoneHashes[i];
            newMilestones[i].fundsAllocated = _fundingGoal.div(_milestoneCount); // Simple equal distribution
        }

        projects[newProjectId] = Project({
            proposer: msg.sender,
            title: _title,
            description: _description,
            fundingGoal: _fundingGoal,
            fundedAmount: 0,
            state: ProjectState.Proposed,
            milestones: newMilestones,
            ipTokenId: 0,
            projectScore: 0
        });

        emit ProjectProposed(newProjectId, msg.sender, _title, _fundingGoal);
    }

    /**
     * @notice Stake Genesis Tokens to fund a specific project.
     * @param _projectId The ID of the project to fund.
     * @param _amount The amount of Genesis Tokens to stake.
     */
    function stakeForProjectFunding(uint256 _projectId, uint256 _amount) external projectExists(_projectId) {
        Project storage project = projects[_projectId];
        require(project.state == ProjectState.Proposed || project.state == ProjectState.Funded, "GenesisForge: Project not in funding phase");
        require(_amount > 0, "GenesisForge: Amount must be greater than zero");

        genesisToken.transferFrom(msg.sender, address(this), _amount);

        project.fundedAmount = project.fundedAmount.add(_amount);
        project.stakes[msg.sender] = project.stakes[msg.sender].add(_amount);

        // Add staker to list if not already present
        bool found = false;
        for(uint256 i = 0; i < project.stakers.length; i++) {
            if (project.stakers[i] == msg.sender) {
                found = true;
                break;
            }
        }
        if (!found) {
            project.stakers.push(msg.sender);
        }

        if (project.fundedAmount >= project.fundingGoal && project.state == ProjectState.Proposed) {
            project.state = ProjectState.Funded;
        }

        emit TokensStakedForProject(_projectId, msg.sender, _amount);
    }

    /**
     * @notice Unstake Genesis Tokens from a project. Can only be done if the project hasn't started or is cancelled.
     * @param _projectId The ID of the project to unstake from.
     * @param _amount The amount of Genesis Tokens to unstake.
     */
    function unstakeFromProjectFunding(uint256 _projectId, uint256 _amount) external projectExists(_projectId) {
        Project storage project = projects[_projectId];
        require(project.state == ProjectState.Proposed || project.state == ProjectState.Funded || project.state == ProjectState.Cancelled, "GenesisForge: Project is active or completed, cannot unstake");
        require(project.stakes[msg.sender] >= _amount, "GenesisForge: Insufficient staked amount");
        require(_amount > 0, "GenesisForge: Amount must be greater than zero");

        project.stakes[msg.sender] = project.stakes[msg.sender].sub(_amount);
        project.fundedAmount = project.fundedAmount.sub(_amount);
        genesisToken.transfer(msg.sender, _amount);

        emit TokensUnstakedFromProject(_projectId, msg.sender, _amount);
    }

    /**
     * @notice Initiate a project once its funding goal is met.
     * @param _projectId The ID of the project to initiate.
     */
    function initiateProject(uint256 _projectId) external onlyProposer(_projectId) projectExists(_projectId) {
        Project storage project = projects[_projectId];
        require(project.state == ProjectState.Funded, "GenesisForge: Project must be in 'Funded' state");
        require(project.fundedAmount >= project.fundingGoal, "GenesisForge: Project not fully funded yet");

        project.state = ProjectState.Active;
        emit ProjectInitiated(_projectId);
    }

    /**
     * @notice Project proposer submits a hash representing proof of milestone completion.
     * @param _projectId The ID of the project.
     * @param _milestoneIndex The index of the milestone (0-based).
     * @param _proofHash A hash representing the evidence for milestone completion.
     */
    function submitMilestoneProof(uint256 _projectId, uint256 _milestoneIndex, bytes32 _proofHash) external onlyProposer(_projectId) projectExists(_projectId) {
        Project storage project = projects[_projectId];
        require(project.state == ProjectState.Active, "GenesisForge: Project is not active");
        require(_milestoneIndex < project.milestones.length, "GenesisForge: Invalid milestone index");
        require(!project.milestones[_milestoneIndex].isVerified, "GenesisForge: Milestone already verified");
        require(_proofHash != bytes32(0), "GenesisForge: Proof hash cannot be zero");

        project.milestones[_milestoneIndex].proofHash = _proofHash;
        emit MilestoneProofSubmitted(_projectId, _milestoneIndex, _proofHash);
    }

    /**
     * @notice A designated validator verifies a milestone based on the submitted proof.
     * @param _projectId The ID of the project.
     * @param _milestoneIndex The index of the milestone.
     */
    function verifyMilestone(uint256 _projectId, uint256 _milestoneIndex) external onlyRole(VALIDATOR_ROLE) projectExists(_projectId) {
        Project storage project = projects[_projectId];
        require(project.state == ProjectState.Active, "GenesisForge: Project is not active");
        require(_milestoneIndex < project.milestones.length, "GenesisForge: Invalid milestone index");
        require(!project.milestones[_milestoneIndex].isVerified, "GenesisForge: Milestone already verified");
        require(project.milestones[_milestoneIndex].proofHash != bytes32(0), "GenesisForge: No proof submitted for this milestone");

        project.milestones[_milestoneIndex].isVerified = true;
        emit MilestoneVerified(_projectId, _milestoneIndex, true);
    }

    /**
     * @notice Requests the AI Oracle to verify a milestone proof.
     * @param _projectId The ID of the project.
     * @param _milestoneIndex The index of the milestone.
     * @param _dataForAI Additional data for the AI Oracle to consider.
     */
    function requestMilestoneVerificationFromAI(uint256 _projectId, uint256 _milestoneIndex, bytes calldata _dataForAI) external onlyProposer(_projectId) projectExists(_projectId) {
        Project storage project = projects[_projectId];
        require(project.state == ProjectState.Active, "GenesisForge: Project is not active");
        require(_milestoneIndex < project.milestones.length, "GenesisForge: Invalid milestone index");
        require(!project.milestones[_milestoneIndex].isVerified, "GenesisForge: Milestone already verified");
        require(project.milestones[_milestoneIndex].proofHash != bytes32(0), "GenesisForge: No proof submitted for this milestone");
        require(address(aiOracle) != address(0), "GenesisForge: AI Oracle address not set");
        
        project.milestoneVerificationPending[_milestoneIndex] = true;
        aiOracle.requestMilestoneVerification(_projectId, _milestoneIndex, _dataForAI, address(this));
    }

    /**
     * @notice Callback function for the AI Oracle to report milestone verification status.
     * @dev Only callable by the trusted AI Oracle contract.
     * @param _projectId The ID of the project.
     * @param _milestoneIndex The index of the milestone.
     * @param _isVerified Whether the AI Oracle verified the milestone.
     * @param _reasoning AI's reasoning for the verification.
     */
    function processOracleResponse_MilestoneVerification(uint256 _projectId, uint256 _milestoneIndex, bool _isVerified, string calldata _reasoning) external onlyRole(ORACLE_RESPONDER_ROLE) projectExists(_projectId) {
        Project storage project = projects[_projectId];
        require(project.milestoneVerificationPending[_milestoneIndex], "GenesisForge: No pending AI verification for this milestone");
        
        delete project.milestoneVerificationPending[_milestoneIndex];

        if (_isVerified) {
            project.milestones[_milestoneIndex].isVerified = true;
        }
        // Even if not verified, the request is processed. Proposer might need to resubmit or dispute.
        emit MilestoneVerified(_projectId, _milestoneIndex, _isVerified);
    }


    /**
     * @notice Proposer can withdraw funds allocated to a *verified* milestone.
     * @param _projectId The ID of the project.
     * @param _milestoneIndex The index of the milestone.
     */
    function withdrawProjectFunds(uint256 _projectId, uint256 _milestoneIndex) external onlyProposer(_projectId) projectExists(_projectId) {
        Project storage project = projects[_projectId];
        require(project.state == ProjectState.Active, "GenesisForge: Project is not active");
        require(_milestoneIndex < project.milestones.length, "GenesisForge: Invalid milestone index");
        require(project.milestones[_milestoneIndex].isVerified, "GenesisForge: Milestone not yet verified");
        require(project.milestones[_milestoneIndex].fundsAllocated > 0, "GenesisForge: No funds to withdraw for this milestone");

        uint256 amount = project.milestones[_milestoneIndex].fundsAllocated;
        project.milestones[_milestoneIndex].fundsAllocated = 0; // Clear allocated funds to prevent re-withdrawal
        genesisToken.transfer(msg.sender, amount);

        emit ProjectFundsWithdrawn(_projectId, _milestoneIndex, amount);
    }

    /**
     * @notice Marks a project as "Completed" after all milestones are verified.
     * @param _projectId The ID of the project to complete.
     */
    function completeProject(uint256 _projectId) external onlyProposer(_projectId) projectExists(_projectId) {
        Project storage project = projects[_projectId];
        require(project.state == ProjectState.Active, "GenesisForge: Project is not active");

        for (uint256 i = 0; i < project.milestones.length; i++) {
            require(project.milestones[i].isVerified, "GenesisForge: Not all milestones are verified");
        }

        project.state = ProjectState.Completed;
        emit ProjectCompleted(_projectId);
    }

    // --- II. Dynamic IP & NFT Management ---

    /**
     * @notice Mints a unique Dynamic IP NFT for a completed project.
     * The GenesisForge contract will be the initial owner of the NFT. Fractional ownership is managed internally.
     * @param _projectId The ID of the completed project.
     * @param _tokenURI Initial URI for the IP NFT metadata.
     */
    function mintDynamicIPNFT(uint256 _projectId, string calldata _tokenURI) external onlyProposer(_projectId) projectExists(_projectId) {
        Project storage project = projects[_projectId];
        require(project.state == ProjectState.Completed, "GenesisForge: Project must be completed to mint IP NFT");
        require(project.ipTokenId == 0, "GenesisForge: IP NFT already minted for this project");

        _ipTokenIds.increment();
        uint256 newIpTokenId = _ipTokenIds.current();

        // GenesisForge holds the actual ERC721 token
        _safeMint(address(this), newIpTokenId); 
        _setTokenURI(newIpTokenId, _tokenURI);

        project.ipTokenId = newIpTokenId;
        ipNFTs[newIpTokenId] = DynamicIPNFT({
            tokenURI: _tokenURI,
            projectId: _projectId,
            valuation: 0
        });

        // Proposer gets a default 100% initial share, can redistribute later
        ipNFTs[newIpTokenId].fractionalOwnershipShares[msg.sender] = 10000; // 100% in basis points

        emit IPNFTMinted(newIpTokenId, _projectId, address(this), _tokenURI);
    }

    /**
     * @notice Allows the IP NFT owner (or contract if it holds ownership) to update its metadata.
     * Only the initial IP holder (proposer) or an admin can update this, or a governance decision.
     * @param _tokenId The ID of the IP NFT.
     * @param _newTokenURI The new URI for the IP NFT metadata.
     */
    function updateIPNFTMetadata(uint256 _tokenId, string calldata _newTokenURI) external ipNFTExists(_tokenId) {
        DynamicIPNFT storage ipNFT = ipNFTs[_tokenId];
        require(ipNFT.fractionalOwnershipShares[msg.sender] == 10000 || hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "GenesisForge: Only primary IP owner or admin can update metadata");
        
        ipNFT.tokenURI = _newTokenURI;
        _setTokenURI(_tokenId, _newTokenURI); // Update ERC721 standard URI

        emit IPNFTMetadataUpdated(_tokenId, _newTokenURI);
    }

    /**
     * @notice Distributes fractional ownership shares of an IP NFT.
     * The sum of _shares must not exceed 10000 (100%).
     * @param _tokenId The ID of the IP NFT.
     * @param _recipients Array of addresses to receive shares.
     * @param _shares Array of share percentages (in basis points, e.g., 100 for 1%).
     */
    function assignIPFractionalOwnership(uint256 _tokenId, address[] calldata _recipients, uint256[] calldata _shares) external ipNFTExists(_tokenId) {
        DynamicIPNFT storage ipNFT = ipNFTs[_tokenId];
        require(ipNFT.fractionalOwnershipShares[msg.sender] == 10000 || hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "GenesisForge: Only primary IP owner or admin can assign fractional ownership");
        require(_recipients.length == _shares.length, "GenesisForge: Recipients and shares array length mismatch");

        uint256 totalShares = 0;
        for (uint256 i = 0; i < _shares.length; i++) {
            totalShares = totalShares.add(_shares[i]);
            require(_recipients[i] != address(0), "GenesisForge: Recipient cannot be zero address");
        }
        require(totalShares <= 10000, "GenesisForge: Total shares exceed 100%");

        // Clear existing fractional ownership to reassign from scratch or manage logic carefully
        // For simplicity, this function overwrites shares. A more complex system might add/subtract.
        // In a real system, you'd iterate through existing shares and re-distribute.
        // For this example, we assume this is called once or by admin to re-distribute completely.
        delete ipNFT.fractionalOwnershipShares; // Clear existing
        for (uint256 i = 0; i < _recipients.length; i++) {
            ipNFT.fractionalOwnershipShares[_recipients[i]] = ipNFT.fractionalOwnershipShares[_recipients[i]].add(_shares[i]);
            emit FractionalOwnershipAssigned(_tokenId, _recipients[i], _shares[i]);
        }
    }
    
    /**
     * @notice Transfers a percentage of future royalty distributions associated with an IP NFT.
     * Requires the sender to have sufficient share to transfer.
     * @param _tokenId The ID of the IP NFT.
     * @param _from The address currently holding the royalty share.
     * @param _to The address to transfer the royalty share to.
     * @param _sharePercentage The percentage of royalty share to transfer (in basis points).
     */
    function transferIPNFTRoyaltyShare(uint256 _tokenId, address _from, address _to, uint256 _sharePercentage) external ipNFTExists(_tokenId) {
        DynamicIPNFT storage ipNFT = ipNFTs[_tokenId];
        require(ipNFT.fractionalOwnershipShares[_from] >= _sharePercentage, "GenesisForge: Insufficient royalty share to transfer");
        require(_to != address(0), "GenesisForge: Cannot transfer to zero address");
        require(msg.sender == _from, "GenesisForge: Sender must be the owner of the shares");

        ipNFT.fractionalOwnershipShares[_from] = ipNFT.fractionalOwnershipShares[_from].sub(_sharePercentage);
        ipNFT.fractionalOwnershipShares[_to] = ipNFT.fractionalOwnershipShares[_to].add(_sharePercentage);

        emit RoyaltyShareTransferred(_tokenId, _from, _to, _sharePercentage);
    }

    /**
     * @notice Grants a time-bound license for commercial or research usage of the underlying IP.
     * Requires a fee in Genesis Tokens.
     * @param _tokenId The ID of the IP NFT.
     * @param _licensee The address receiving the license.
     * @param _duration Duration of the license in seconds.
     * @param _fee Fee for the license in Genesis Tokens.
     */
    function licenseIPNFTUsage(uint256 _tokenId, address _licensee, uint256 _duration, uint256 _fee) external ipNFTExists(_tokenId) {
        DynamicIPNFT storage ipNFT = ipNFTs[_tokenId];
        require(ipNFT.fractionalOwnershipShares[msg.sender] > 0 || hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "GenesisForge: Only IP owners or admin can grant licenses");
        require(_licensee != address(0), "GenesisForge: Licensee cannot be zero address");
        require(_duration > 0, "GenesisForge: License duration must be positive");
        require(_fee > 0, "GenesisForge: License fee must be positive");

        genesisToken.transferFrom(msg.sender, address(this), _fee); // Fee goes to contract, then distributed to owners
        ipNFT.accruedRoyalties[_tokenId] = ipNFT.accruedRoyalties[_tokenId].add(_fee); // Accumulate for distribution

        ipNFT.activeLicenses[_licensee] = block.timestamp.add(_duration);

        emit IPLicenseGranted(_tokenId, _licensee, _duration, _fee);
    }

    /**
     * @notice Allows the IP NFT owner to revoke an active license before its expiration.
     * @param _tokenId The ID of the IP NFT.
     * @param _licensee The address whose license is to be revoked.
     */
    function revokeIPNFTLicense(uint256 _tokenId, address _licensee) external ipNFTExists(_tokenId) {
        DynamicIPNFT storage ipNFT = ipNFTs[_tokenId];
        require(ipNFT.fractionalOwnershipShares[msg.sender] > 0 || hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "GenesisForge: Only IP owners or admin can revoke licenses");
        require(ipNFT.activeLicenses[_licensee] > block.timestamp, "GenesisForge: License is not active or does not exist");

        delete ipNFT.activeLicenses[_licensee];
        // Potentially refund a portion of the fee, depending on policy
        // For simplicity, no refund in this example.

        emit IPLicenseRevoked(_tokenId, _licensee);
    }

    /**
     * @notice Allows fractional owners to collect accumulated royalties from IP usage.
     * The total accrued royalties are distributed proportionally.
     * @param _tokenId The ID of the IP NFT.
     */
    function collectIPNFTRoyalties(uint256 _tokenId) external ipNFTExists(_tokenId) {
        DynamicIPNFT storage ipNFT = ipNFTs[_tokenId];
        require(ipNFT.fractionalOwnershipShares[msg.sender] > 0, "GenesisForge: You do not own shares of this IP NFT");

        uint256 totalAccrued = ipNFT.accruedRoyalties[_tokenId];
        require(totalAccrued > 0, "GenesisForge: No royalties accrued for this IP NFT");

        // Calculate and transfer royalties
        uint256 share = ipNFT.fractionalOwnershipShares[msg.sender];
        uint256 amountToClaim = totalAccrued.mul(share).div(10000); // Calculate based on share

        require(amountToClaim > 0, "GenesisForge: No royalties to claim for your share");

        ipNFT.accruedRoyalties[_tokenId] = ipNFT.accruedRoyalties[_tokenId].sub(amountToClaim); // Reduce total accrued
        pendingRewards[msg.sender] = pendingRewards[msg.sender].add(amountToClaim); // Add to pending rewards

        emit RoyaltiesCollected(_tokenId, msg.sender, amountToClaim);
    }


    // --- III. AI Oracle Integration & External Data ---

    /**
     * @notice Sets the address of the trusted AI Oracle contract.
     * @dev Only callable by an admin.
     * @param _newOracleAddress The address of the AI Oracle contract.
     */
    function setAIOracleAddress(address _newOracleAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_newOracleAddress != address(0), "GenesisForge: AI Oracle address cannot be zero");
        aiOracle = IAIOracle(_newOracleAddress);
        // Grant ORACLE_RESPONDER_ROLE to the AI Oracle contract so it can call back
        _grantRole(ORACLE_RESPONDER_ROLE, _newOracleAddress);
        emit AIOracleAddressSet(_newOracleAddress);
    }

    /**
     * @notice Requests the AI Oracle to provide an objective score for a project proposal.
     * @param _projectId The ID of the project to score.
     * @param _promptData Additional data for the AI Oracle to consider for scoring.
     */
    function requestProjectScoreFromAI(uint256 _projectId, bytes calldata _promptData) external projectExists(_projectId) {
        Project storage project = projects[_projectId];
        require(project.state == ProjectState.Proposed, "GenesisForge: Project must be in 'Proposed' state to request scoring");
        require(address(aiOracle) != address(0), "GenesisForge: AI Oracle address not set");

        aiOracle.requestProjectScore(_projectId, _promptData, address(this));
        emit ProjectScoreRequested(_projectId, _promptData);
    }

    /**
     * @notice Callback function for the AI Oracle to report a project score.
     * @dev Only callable by the trusted AI Oracle contract.
     * @param _projectId The ID of the project.
     * @param _score The score provided by the AI (e.g., 0-100).
     * @param _reasoning AI's reasoning for the score.
     */
    function processOracleResponse_ProjectScore(uint256 _projectId, uint256 _score, string calldata _reasoning) external onlyRole(ORACLE_RESPONDER_ROLE) projectExists(_projectId) {
        Project storage project = projects[_projectId];
        project.projectScore = _score;
        // Optionally, use reasoning for further on-chain logic or off-chain display
        emit ProjectScoreReceived(_projectId, _score, _reasoning);
    }

    /**
     * @notice Requests the AI Oracle to assess and provide a valuation for a specific IP NFT.
     * @param _tokenId The ID of the IP NFT to value.
     * @param _data Additional data for the AI Oracle to consider for valuation.
     */
    function requestIPValuationFromAI(uint252 _tokenId, bytes calldata _data) external ipNFTExists(_tokenId) {
        DynamicIPNFT storage ipNFT = ipNFTs[_tokenId];
        require(ipNFT.projectId > 0, "GenesisForge: IP NFT not linked to a project"); // Ensures project exists and is completed
        require(address(aiOracle) != address(0), "GenesisForge: AI Oracle address not set");

        aiOracle.requestIPValuation(_tokenId, _data, address(this));
        emit IPValuationRequested(_tokenId, _data);
    }

    /**
     * @notice Callback function for the AI Oracle to report an IP valuation.
     * @dev Only callable by the trusted AI Oracle contract.
     * @param _tokenId The ID of the IP NFT.
     * @param _valuation The valuation provided by the AI.
     * @param _metrics AI's metrics or reasoning for the valuation.
     */
    function processOracleResponse_IPValuation(uint256 _tokenId, uint256 _valuation, string calldata _metrics) external onlyRole(ORACLE_RESPONDER_ROLE) ipNFTExists(_tokenId) {
        DynamicIPNFT storage ipNFT = ipNFTs[_tokenId];
        ipNFT.valuation = _valuation;
        // Optionally, use metrics for further on-chain logic or off-chain display
        emit IPValuationReceived(_tokenId, _valuation, _metrics);
    }

    // --- IV. Governance & Roles ---

    /**
     * @notice Allows users to delegate their staked tokens' voting power to another address for governance proposals.
     * @param _delegatee The address to delegate voting power to.
     */
    function delegateVotingPower(address _delegatee) external {
        require(_delegatee != address(0), "GenesisForge: Delegatee cannot be the zero address");
        delegatedVotingPower[msg.sender] = projects[0].stakes[msg.sender]; // Use a dummy project for total staked
        delegatedVotingPower[_delegatee] = delegatedVotingPower[_delegatee].add(projects[0].stakes[msg.sender]); // Sum up for delegatee
        // In a real system, would iterate through all projects or have a global stake.
        // For simplicity, assuming total staked in project 0 (which is not a real project) is the voting power.
        // A more robust implementation would sum up all stakes of the sender across all active/funded projects.
        // Or link directly to genesisToken balance or a dedicated staking module.
        // For this demo, let's just make it simple: `msg.sender`'s GEN balance is their voting power.
        // This is a simplification and would need a proper snapshot or token-based voting logic.
        uint256 votingPower = genesisToken.balanceOf(msg.sender);
        delegatedVotingPower[_delegatee] = delegatedVotingPower[_delegatee].add(votingPower);
        delegatedVotingPower[msg.sender] = 0; // Clear sender's direct power
        
        emit VotingPowerDelegated(msg.sender, _delegatee);
    }
    
    /**
     * @notice Proposes a change to contract parameters or logic.
     * This would typically be for an upgradeable proxy pattern.
     * @param _description A description of the proposed change.
     * @param _targetContract The address of the contract to call (e.g., an upgrade proxy or `GenesisForge` itself).
     * @param _callData The encoded function call data for the target contract.
     */
    function proposeGovernanceChange(string calldata _description, address _targetContract, bytes calldata _callData) external {
        // A more advanced system would check if proposer has enough voting power (e.g., min stake)
        require(genesisToken.balanceOf(msg.sender) > 0, "GenesisForge: Proposer must hold Genesis Tokens"); // Simplified eligibility

        _governanceProposalIds.increment();
        uint256 newProposalId = _governanceProposalIds.current();

        governanceProposals[newProposalId] = GovernanceProposal({
            proposer: msg.sender,
            description: _description,
            targetContract: _targetContract,
            callData: _callData,
            voteStartTime: block.timestamp,
            voteEndTime: block.timestamp.add(7 days), // 7-day voting period
            yayVotes: 0,
            nayVotes: 0,
            state: ProposalState.Active
        });

        emit GovernanceProposalCreated(newProposalId, msg.sender, _description);
    }

    /**
     * @notice Casts a vote on an active governance proposal.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for 'Yay', false for 'Nay'.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) external {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(proposal.state == ProposalState.Active, "GenesisForge: Proposal is not active");
        require(block.timestamp >= proposal.voteStartTime && block.timestamp <= proposal.voteEndTime, "GenesisForge: Voting period is not active");
        
        address voter = msg.sender;
        if (delegatedVotingPower[msg.sender] > 0) {
            // Find who msg.sender delegated their power to
            for (uint256 i = 0; i < projects[0].stakers.length; i++) { // Again, a simplification
                if (delegatedVotingPower[projects[0].stakers[i]] == genesisToken.balanceOf(msg.sender)) {
                    voter = projects[0].stakers[i];
                    break;
                }
            }
        }
        require(!proposal.hasVoted[voter], "GenesisForge: Voter already cast a vote");

        uint256 votingPower = genesisToken.balanceOf(voter); // Simplified: direct token balance is voting power
        require(votingPower > 0, "GenesisForge: Voter has no voting power");

        if (_support) {
            proposal.yayVotes = proposal.yayVotes.add(votingPower);
        } else {
            proposal.nayVotes = proposal.nayVotes.add(votingPower);
        }
        proposal.hasVoted[voter] = true;

        emit VoteCast(_proposalId, voter, _support);
    }
    
    /**
     * @notice Executes a successful governance proposal.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) external onlyRole(DEFAULT_ADMIN_ROLE) { // Typically callable by anyone after state transition
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(proposal.state == ProposalState.Active, "GenesisForge: Proposal is not active");
        require(block.timestamp > proposal.voteEndTime, "GenesisForge: Voting period not ended");

        if (proposal.yayVotes > proposal.nayVotes && proposal.yayVotes > (proposal.yayVotes.add(proposal.nayVotes)).div(2)) { // Simple majority threshold
            proposal.state = ProposalState.Succeeded;
            emit ProposalStateChanged(_proposalId, ProposalState.Succeeded);

            // Execute the proposal's callData
            (bool success, ) = proposal.targetContract.call(proposal.callData);
            require(success, "GenesisForge: Proposal execution failed");

            proposal.state = ProposalState.Executed;
            emit ProposalStateChanged(_proposalId, ProposalState.Executed);
        } else {
            proposal.state = ProposalState.Defeated;
            emit ProposalStateChanged(_proposalId, ProposalState.Defeated);
        }
    }

    /**
     * @notice Assigns a specific role to a user.
     * @dev Only callable by an admin or via governance.
     * @param _user The address to assign the role to.
     * @param _role The role to assign (e.g., `VALIDATOR_ROLE`).
     */
    function assignRole(address _user, bytes32 _role) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(_role, _user);
    }

    // --- V. Dispute Resolution ---

    /**
     * @notice Initiates a formal dispute against a project, milestone, or IP NFT.
     * Requires collateral in Genesis Tokens.
     * @param _projectIdOrTokenId The ID of the project or IP NFT in dispute.
     * @param _disputeType A hash identifying the type of dispute (e.g., keccak256("MILSTONE_FAILED")).
     * @param _description A detailed description of the dispute.
     * @param _collateralAmount The amount of Genesis Tokens staked as collateral for the dispute.
     */
    function initiateDispute(
        uint256 _projectIdOrTokenId,
        bytes32 _disputeType,
        string calldata _description,
        uint256 _collateralAmount
    ) external {
        require(_collateralAmount > 0, "GenesisForge: Collateral must be positive");
        genesisToken.transferFrom(msg.sender, address(this), _collateralAmount);

        _disputeIds.increment();
        uint256 newDisputeId = _disputeIds.current();

        address subjectAddress = address(0);
        if (_disputeType == keccak256("MILSTONE_FAILED") || _disputeType == keccak256("PROJECT_FRAUD")) {
            require(projects[_projectIdOrTokenId].proposer != address(0), "GenesisForge: Project not found for dispute");
            subjectAddress = projects[_projectIdOrTokenId].proposer;
            projects[_projectIdOrTokenId].state = ProjectState.Disputed; // Pause project activity
        } else if (_disputeType == keccak256("IP_INFRINGEMENT")) {
            require(ipNFTs[_projectIdOrTokenId].projectId > 0, "GenesisForge: IP NFT not found for dispute");
            subjectAddress = ownerOf(_projectIdOrTokenId); // ERC721 owner
        } else {
            revert("GenesisForge: Invalid dispute type");
        }

        disputes[newDisputeId] = Dispute({
            initiator: msg.sender,
            disputeType: _disputeType,
            description: _description,
            collateralAmount: _collateralAmount,
            primarySubject: subjectAddress,
            projectIdOrTokenId: _projectIdOrTokenId,
            winner: address(0),
            penaltyPercentage: 0,
            resolved: false
        });

        emit DisputeInitiated(newDisputeId, msg.sender, _projectIdOrTokenId, _disputeType);
    }

    /**
     * @notice Parties involved in a dispute can submit evidence.
     * @param _disputeId The ID of the dispute.
     * @param _evidenceHash A hash representing the evidence (e.g., IPFS hash).
     */
    function submitArbitrationEvidence(uint256 _disputeId, bytes32 _evidenceHash) external {
        Dispute storage dispute = disputes[_disputeId];
        require(!dispute.resolved, "GenesisForge: Dispute already resolved");
        require(msg.sender == dispute.initiator || msg.sender == dispute.primarySubject, "GenesisForge: Not a party to this dispute");

        dispute.evidenceSubmitted[msg.sender] = true; // Placeholder for evidence tracking
        emit ArbitrationEvidenceSubmitted(_disputeId, msg.sender, _evidenceHash);
    }

    /**
     * @notice An assigned arbitrator resolves the dispute, distributing collateral and imposing penalties.
     * @param _disputeId The ID of the dispute.
     * @param _winner The address determined to be the winner of the dispute.
     * @param _penaltyPercentage Percentage of the loser's collateral transferred to the winner (in basis points, max 10000).
     */
    function resolveDisputeByArbitrator(uint256 _disputeId, address _winner, uint256 _penaltyPercentage) external onlyRole(ARBITRATOR_ROLE) {
        Dispute storage dispute = disputes[_disputeId];
        require(!dispute.resolved, "GenesisForge: Dispute already resolved");
        require(_winner != address(0), "GenesisForge: Winner cannot be zero address");
        require(_penaltyPercentage <= 10000, "GenesisForge: Penalty percentage exceeds 100%");

        address loser;
        if (_winner == dispute.initiator) {
            loser = dispute.primarySubject;
        } else if (_winner == dispute.primarySubject) {
            loser = dispute.initiator;
        } else {
            revert("GenesisForge: Winner must be one of the dispute parties");
        }

        uint256 totalCollateral = dispute.collateralAmount.mul(2); // Assuming both parties stake equal collateral
        uint256 penaltyAmount = dispute.collateralAmount.mul(_penaltyPercentage).div(10000);
        uint256 winnerShare = dispute.collateralAmount.add(penaltyAmount);
        uint256 loserShare = dispute.collateralAmount.sub(penaltyAmount);

        // Distribute shares
        pendingRewards[_winner] = pendingRewards[_winner].add(winnerShare);
        pendingRewards[loser] = pendingRewards[loser].add(loserShare);

        dispute.winner = _winner;
        dispute.penaltyPercentage = _penaltyPercentage;
        dispute.resolved = true;

        // If it was a project dispute, clear the dispute flag or change project state
        if (dispute.disputeType == keccak256("MILSTONE_FAILED") || dispute.disputeType == keccak256("PROJECT_FRAUD")) {
            projects[dispute.projectIdOrTokenId].state = (_winner == dispute.primarySubject) ? ProjectState.Active : ProjectState.Cancelled;
        }

        emit DisputeResolved(_disputeId, _winner, penaltyAmount);
    }

    // --- VI. Treasury & Rewards ---

    /**
     * @notice Allows participants (stakers, successful proposers, arbitrators) to claim their earned rewards.
     */
    function claimRewards() external {
        uint256 amount = pendingRewards[msg.sender];
        require(amount > 0, "GenesisForge: No rewards to claim");

        pendingRewards[msg.sender] = 0;
        genesisToken.transfer(msg.sender, amount);

        emit RewardsClaimed(msg.sender, amount);
    }

    // --- ERC721 Overrides for DynamicIPNFT ---
    // These ensure the contract acts as the owner of the NFTs it mints,
    // and that metadata can be controlled by GenesisForge's logic.
    function _baseURI() internal view virtual override returns (string memory) {
        return "ipfs://"; // Placeholder base URI, actual URI set per token
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721: URI query for nonexistent token");
        return ipNFTs[tokenId].tokenURI;
    }
}
```