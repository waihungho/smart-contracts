This smart contract, "Quantum Nexus," is designed to be a decentralized innovation and capital orchestration platform. It integrates a unique reputation-based system for funding and managing projects, a utility-bearing dynamic NFT system for acknowledging contributions, and a governance model that allows for adaptive resource allocation and project lifecycle management.

It avoids direct duplication of common open-source projects by combining elements in a novel way:
*   **Reputation-gated funding and participation:** Not just token-weighted, but activity and contribution-weighted.
*   **Dynamic, utility-bearing NFTs:** NFTs are minted based on project milestones and success, granting potential future privileges within the ecosystem.
*   **Milestone-driven project funding:** Funds are released incrementally upon proven progress, mitigating risks.
*   **Oracle-assisted Project Scoring:** Allowing for potential integration with external "AI-driven" or data-driven insights for project evaluation (though the AI logic itself is off-chain).
*   **Liquid Democracy Governance:** Users can delegate their reputation/voting power.

---

## Quantum Nexus: Decentralized Innovation & Capital Orchestrator

### Outline

1.  **Contract Overview:** Purpose and core mechanics.
2.  **State Variables:** Global storage for contract data.
3.  **Structs:** Custom data types for Projects, Milestones, and Governance Proposals.
4.  **Enums:** Status indicators for projects and proposals.
5.  **Events:** Emitted logs for significant contract actions.
6.  **Modifiers:** Reusable access control and state checks.
7.  **Constructor:** Initializes the contract.
8.  **Capital Management Functions:** Depositing and withdrawing funds.
9.  **Reputation System Functions:** Managing and querying user reputation (primarily internal updates).
10. **Project Lifecycle Management Functions:** Proposing, funding, managing, and completing innovation projects.
11. **Governance & Voting Functions:** Creating proposals, voting, delegating reputation, executing decisions.
12. **Innovation NFT Functions:** Minting and managing contribution NFTs (mostly internal).
13. **Oracle & Admin Functions:** Setting external data sources and critical parameters.
14. **View Functions:** Reading contract state.

### Function Summary (25 Functions)

1.  **`constructor()`**: Initializes the contract with the owner, sets initial governance parameters, and deploys the internal Innovation NFT contract.
2.  **`setOracleAddress(address _oracle)`**: Sets the address of the external oracle for AI-driven insights/project scoring. (Admin only)
3.  **`setGovernanceParameters(uint256 _proposalThreshold, uint256 _quorumPercentage, uint256 _votingPeriodBlocks)`**: Sets the minimum reputation for proposals, quorum percentage, and voting period. (Admin only)
4.  **`depositCapital()`**: Allows users to deposit Ether into the Quantum Nexus capital pool.
5.  **`withdrawCapital(uint256 _amount)`**: Allows users to withdraw their deposited Ether, respecting locks or allocations.
6.  **`proposeInnovationProject(string memory _ipfsHash, uint256 _fundingGoal, uint256 _reputationScoreNeeded)`**: Initiates a new innovation project proposal with details linked via IPFS, a funding goal, and a minimum reputation score required for contributors.
7.  **`reviewProjectProposal(uint256 _projectId, ProjectStatus _newStatus)`**: Admin or DAO-approved function to change a project's status (e.g., from PENDING to APPROVED or REJECTED) after initial review.
8.  **`fundProject(uint256 _projectId, uint256 _amount)`**: Allows approved users to contribute funds to an `APPROVED` project. Increases contributor's reputation.
9.  **`addMilestone(uint256 _projectId, string memory _description, uint256 _payoutPercentage)`**: Allows the project proposer to add new milestones for their project.
10. **`submitMilestoneProof(uint256 _projectId, uint256 _milestoneIndex, string memory _proofIpfsHash)`**: Proposer submits proof of milestone completion.
11. **`approveMilestone(uint256 _projectId, uint256 _milestoneIndex)`**: Governance/DAO function to approve a submitted milestone, triggering a partial fund release. Updates reputation of approvers and project owner.
12. **`releaseProjectFunds(uint256 _projectId, uint256 _milestoneIndex)`**: Internal function called by `approveMilestone` to transfer funds.
13. **`completeProject(uint256 _projectId)`**: Marks a project as completed if all milestones are approved. Triggers final rewards and NFT minting.
14. **`claimProjectRewards(uint256 _projectId)`**: Allows successful project proposers to claim remaining funds after project completion.
15. **`liquidateProject(uint256 _projectId)`**: Allows DAO/governance to liquidate an underperforming or failed project, potentially returning remaining funds to contributors. Decreases proposer's reputation.
16. **`createGovernanceProposal(string memory _description, bytes memory _calldata)`**: Allows users with sufficient reputation to propose changes to the contract or execution of specific functions.
17. **`voteOnProposal(uint256 _proposalId, bool _support)`**: Casts a vote (support or against) on a governance proposal, weighted by the user's reputation.
18. **`delegateReputation(address _delegatee)`**: Allows users to delegate their reputation and voting power to another address.
19. **`undelegateReputation()`**: Revokes any active reputation delegation.
20. **`executeProposal(uint256 _proposalId)`**: Executes a governance proposal if it has met quorum and passed.
21. **`getUserReputation(address _user)`**: Returns the current reputation score of a given user.
22. **`getProjectDetails(uint256 _projectId)`**: Retrieves all relevant details for a specific project.
23. **`getMilestoneDetails(uint256 _projectId, uint256 _milestoneIndex)`**: Retrieves details for a specific milestone of a project.
24. **`getProposalDetails(uint256 _proposalId)`**: Retrieves all relevant details for a specific governance proposal.
25. **`getCurrentCapitalPool()`**: Returns the total amount of Ether held in the Nexus capital pool.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Quantum Nexus: Decentralized Innovation & Capital Orchestrator
// This contract facilitates a decentralized ecosystem for funding and managing innovation projects.
// It features a reputation-based system, milestone-driven funding, and utility-bearing NFTs for contributors.

// --- Outline ---
// 1. Contract Overview: Purpose and core mechanics.
// 2. State Variables: Global storage for contract data.
// 3. Structs: Custom data types for Projects, Milestones, and Governance Proposals.
// 4. Enums: Status indicators for projects and proposals.
// 5. Events: Emitted logs for significant contract actions.
// 6. Modifiers: Reusable access control and state checks.
// 7. Constructor: Initializes the contract.
// 8. Capital Management Functions: Depositing and withdrawing funds.
// 9. Reputation System Functions: Managing and querying user reputation (primarily internal updates).
// 10. Project Lifecycle Management Functions: Proposing, funding, managing, and completing innovation projects.
// 11. Governance & Voting Functions: Creating proposals, voting, delegating reputation, executing decisions.
// 12. Innovation NFT Functions: Minting and managing contribution NFTs (mostly internal).
// 13. Oracle & Admin Functions: Setting external data sources and critical parameters.
// 14. View Functions: Reading contract state.

// --- Function Summary (25 Functions) ---
// 1. constructor()
// 2. setOracleAddress(address _oracle)
// 3. setGovernanceParameters(uint256 _proposalThreshold, uint256 _quorumPercentage, uint256 _votingPeriodBlocks)
// 4. depositCapital()
// 5. withdrawCapital(uint256 _amount)
// 6. proposeInnovationProject(string memory _ipfsHash, uint256 _fundingGoal, uint256 _reputationScoreNeeded)
// 7. reviewProjectProposal(uint256 _projectId, ProjectStatus _newStatus)
// 8. fundProject(uint256 _projectId, uint256 _amount)
// 9. addMilestone(uint256 _projectId, string memory _description, uint256 _payoutPercentage)
// 10. submitMilestoneProof(uint256 _projectId, uint256 _milestoneIndex, string memory _proofIpfsHash)
// 11. approveMilestone(uint256 _projectId, uint256 _milestoneIndex)
// 12. releaseProjectFunds(uint256 _projectId, uint256 _milestoneIndex)
// 13. completeProject(uint256 _projectId)
// 14. claimProjectRewards(uint256 _projectId)
// 15. liquidateProject(uint256 _projectId)
// 16. createGovernanceProposal(string memory _description, bytes memory _calldata)
// 17. voteOnProposal(uint256 _proposalId, bool _support)
// 18. delegateReputation(address _delegatee)
// 19. undelegateReputation()
// 20. executeProposal(uint256 _proposalId)
// 21. getUserReputation(address _user)
// 22. getProjectDetails(uint256 _projectId)
// 23. getMilestoneDetails(uint256 _projectId, uint256 _milestoneIndex)
// 24. getProposalDetails(uint256 _proposalId)
// 25. getCurrentCapitalPool()

// --- Internal ERC721 for Innovation NFTs ---
contract InnovationNFT is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {}

    // Only the QuantumNexus contract or owner can mint
    function mint(address to, string memory uri) public onlyOwner returns (uint256) {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
        return tokenId;
    }

    // Function to update token URI if it's a dynamic NFT
    function updateTokenURI(uint256 tokenId, string memory newUri) public onlyOwner {
        require(_exists(tokenId), "InnovationNFT: Token does not exist");
        _setTokenURI(tokenId, newUri);
    }
}

contract QuantumNexus is Ownable, ReentrancyGuard {

    // --- Enums ---
    enum ProjectStatus {
        PENDING,    // Awaiting initial review
        APPROVED,   // Approved for funding
        FUNDING,    // Currently raising capital
        ACTIVE,     // Actively executing with funds released
        COMPLETED,  // All milestones done, final rewards claimed
        FAILED,     // Did not meet goals or liquidated
        REJECTED    // Rejected during initial review
    }

    enum ProposalStatus {
        PENDING,    // Awaiting votes
        SUCCEEDED,  // Met quorum and passed
        DEFEATED,   // Did not meet quorum or failed
        EXECUTED    // Successfully executed
    }

    // --- Structs ---

    struct Milestone {
        string description;
        uint256 payoutPercentage; // Percentage of total funding goal
        bool completed;
        string completionProofIpfsHash; // IPFS hash for proof of completion
        uint256 approvalBlock; // Block when milestone was approved
    }

    struct Project {
        uint256 id;
        address proposer;
        string ipfsHash; // IPFS hash for detailed project description
        ProjectStatus status;
        uint256 fundingGoal;
        uint256 currentFunding;
        uint256 fundsReleased;
        uint256 reputationScoreNeeded; // Minimum reputation for the proposer to submit
        uint256 proposalBlock; // Block when project was proposed
        uint256 totalPayoutPercentageApproved; // Sum of approved milestone percentages
        Milestone[] milestones;
        mapping(address => uint256) contributors; // address => amount contributed
        uint256 innovationNftId; // ID of the NFT minted upon project completion
    }

    struct GovernanceProposal {
        uint256 id;
        address proposer;
        string description; // IPFS hash or short text
        bytes calldata; // The call data for the function to be executed
        ProposalStatus status;
        uint256 proposalBlock;
        uint256 votingPeriodBlocks;
        uint256 totalVotesFor; // Sum of reputation scores for "For" votes
        uint256 totalVotesAgainst; // Sum of reputation scores for "Against" votes
        mapping(address => bool) hasVoted; // User => Voted status
        mapping(address => bool) voteSupport; // User => true for support, false for against
    }

    // --- State Variables ---
    using Counters for Counters.Counter;
    Counters.Counter private _nextProjectId;
    Counters.Counter private _nextProposalId;

    mapping(uint256 => Project) public projects;
    mapping(uint256 => GovernanceProposal) public governanceProposals;

    mapping(address => uint256) public userReputation; // Address => Reputation Score
    mapping(address => address) public reputationDelegates; // Delegator => Delegatee

    uint256 public totalCapitalPool; // Total ETH held in the contract

    address public oracleAddress; // Address of an external oracle for AI/data insights
    uint256 public proposalThresholdReputation; // Min reputation to create a governance proposal
    uint256 public quorumPercentage; // Percentage of total reputation needed for a proposal to pass
    uint256 public votingPeriodBlocks; // Number of blocks a proposal is open for voting

    InnovationNFT public innovationNFT; // ERC721 contract for innovation badges

    // --- Events ---
    event CapitalDeposited(address indexed user, uint256 amount);
    event CapitalWithdrawn(address indexed user, uint256 amount);
    event ProjectProposed(uint256 indexed projectId, address indexed proposer, uint256 fundingGoal, string ipfsHash);
    event ProjectStatusUpdated(uint256 indexed projectId, ProjectStatus oldStatus, ProjectStatus newStatus);
    event ProjectFunded(uint256 indexed projectId, address indexed funder, uint256 amount);
    event MilestoneAdded(uint256 indexed projectId, uint256 indexed milestoneIndex, string description, uint256 payoutPercentage);
    event MilestoneSubmitted(uint256 indexed projectId, uint256 indexed milestoneIndex, string proofIpfsHash);
    event MilestoneApproved(uint256 indexed projectId, uint256 indexed milestoneIndex, uint256 fundsReleased);
    event ProjectCompleted(uint256 indexed projectId, address indexed proposer, uint256 finalReward);
    event ProjectLiquidated(uint256 indexed projectId, address indexed liquidator);
    event ProjectRewardsClaimed(uint256 indexed projectId, address indexed proposer, uint256 amount);

    event GovernanceProposalCreated(uint256 indexed proposalId, address indexed proposer, string description);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 reputationWeight);
    event ReputationDelegated(address indexed delegator, address indexed delegatee);
    event ReputationUndelegated(address indexed delegator);
    event ProposalExecuted(uint256 indexed proposalId, bool success);
    event InnovationNFTMinted(uint256 indexed projectId, address indexed recipient, uint256 indexed tokenId);

    // --- Modifiers ---
    modifier onlyProjectProposer(uint256 _projectId) {
        require(projects[_projectId].proposer == msg.sender, "Only project proposer can call this function");
        _;
    }

    modifier projectExists(uint256 _projectId) {
        require(_projectId < _nextProjectId.current(), "Project does not exist");
        _;
    }

    modifier proposalExists(uint256 _proposalId) {
        require(_proposalId < _nextProposalId.current(), "Proposal does not exist");
        _;
    }

    // --- Constructor ---
    constructor(
        string memory _nftName,
        string memory _nftSymbol,
        uint256 _initialProposalThreshold,
        uint256 _initialQuorumPercentage,
        uint256 _initialVotingPeriodBlocks
    ) Ownable(msg.sender) {
        innovationNFT = new InnovationNFT(_nftName, _nftSymbol);
        // Transfer ownership of NFT contract to QuantumNexus contract
        innovationNFT.transferOwnership(address(this));

        proposalThresholdReputation = _initialProposalThreshold;
        quorumPercentage = _initialQuorumPercentage;
        votingPeriodBlocks = _initialVotingPeriodBlocks;
    }

    // --- Capital Management Functions ---

    /**
     * @notice Allows users to deposit Ether into the Quantum Nexus capital pool.
     * @dev Increases the totalCapitalPool.
     */
    function depositCapital() public payable nonReentrant {
        require(msg.value > 0, "Deposit amount must be greater than 0");
        totalCapitalPool += msg.value;
        // Optionally, could reward reputation for capital contribution
        _updateUserReputation(msg.sender, 1); // Small reputation bump
        emit CapitalDeposited(msg.sender, msg.value);
    }

    /**
     * @notice Allows users to withdraw their deposited Ether, respecting locks or allocations.
     * @param _amount The amount of Ether to withdraw.
     * @dev Current implementation is basic. In a real system, track individual deposits and allocations.
     *      For simplicity, this assumes users can withdraw from the total pool if available.
     */
    function withdrawCapital(uint256 _amount) public nonReentrant {
        require(_amount > 0, "Withdraw amount must be greater than 0");
        require(totalCapitalPool >= _amount, "Insufficient capital in pool");

        // In a more complex system, _amount should be checked against msg.sender's unallocated balance.
        // For this example, we assume a simple shared pool with an honor system or pre-calculated balances.
        totalCapitalPool -= _amount;
        payable(msg.sender).transfer(_amount);
        emit CapitalWithdrawn(msg.sender, _amount);
    }

    // --- Reputation System Functions (internal updates + public query) ---

    /**
     * @notice Internal function to update a user's reputation score.
     * @dev Called by other functions upon successful actions (e.g., funding a project, approving a milestone).
     * @param _user The address of the user whose reputation is updated.
     * @param _points The amount of reputation points to add.
     */
    function _updateUserReputation(address _user, uint256 _points) internal {
        userReputation[_user] += _points;
        // In a real system, could also have reputation decay or deduction mechanisms
    }

    /**
     * @notice Internal function to deduct reputation from a user.
     * @dev Called when a user's actions lead to negative outcomes (e.g., project liquidation).
     * @param _user The address of the user whose reputation is updated.
     * @param _points The amount of reputation points to deduct.
     */
    function _deductUserReputation(address _user, uint256 _points) internal {
        if (userReputation[_user] >= _points) {
            userReputation[_user] -= _points;
        } else {
            userReputation[_user] = 0; // Prevent underflow
        }
    }

    /**
     * @notice Returns the current reputation score of a given user.
     * @param _user The address of the user.
     * @return The reputation score.
     */
    function getUserReputation(address _user) public view returns (uint256) {
        return userReputation[_user];
    }

    // --- Project Lifecycle Management Functions ---

    /**
     * @notice Initiates a new innovation project proposal.
     * @param _ipfsHash IPFS hash linking to the detailed project description, team, roadmap, etc.
     * @param _fundingGoal The total Ether required for the project.
     * @param _reputationScoreNeeded Minimum reputation score for a contributor to join.
     */
    function proposeInnovationProject(
        string memory _ipfsHash,
        uint256 _fundingGoal,
        uint256 _reputationScoreNeeded
    ) public {
        require(bytes(_ipfsHash).length > 0, "IPFS hash cannot be empty");
        require(_fundingGoal > 0, "Funding goal must be greater than 0");
        require(userReputation[msg.sender] >= proposalThresholdReputation, "Insufficient reputation to propose a project");

        uint256 newProjectId = _nextProjectId.current();
        projects[newProjectId] = Project({
            id: newProjectId,
            proposer: msg.sender,
            ipfsHash: _ipfsHash,
            status: ProjectStatus.PENDING,
            fundingGoal: _fundingGoal,
            currentFunding: 0,
            fundsReleased: 0,
            reputationScoreNeeded: _reputationScoreNeeded,
            proposalBlock: block.number,
            totalPayoutPercentageApproved: 0,
            milestones: new Milestone[](0),
            innovationNftId: 0 // Will be set upon completion
        });
        _nextProjectId.increment();

        _updateUserReputation(msg.sender, 5); // Reward for proposing a project

        emit ProjectProposed(newProjectId, msg.sender, _fundingGoal, _ipfsHash);
    }

    /**
     * @notice Admin or DAO-approved function to change a project's status.
     * @dev This step is crucial for initial vetting of projects before they can receive funding.
     * @param _projectId The ID of the project.
     * @param _newStatus The new status (e.g., APPROVED, REJECTED).
     */
    function reviewProjectProposal(uint256 _projectId, ProjectStatus _newStatus)
        public
        onlyOwner // Can be replaced by a DAO voting mechanism
        projectExists(_projectId)
    {
        Project storage project = projects[_projectId];
        require(project.status == ProjectStatus.PENDING, "Project not in PENDING status");
        require(_newStatus == ProjectStatus.APPROVED || _newStatus == ProjectStatus.REJECTED, "Invalid status for review");

        ProjectStatus oldStatus = project.status;
        project.status = _newStatus;

        if (_newStatus == ProjectStatus.APPROVED) {
            project.status = ProjectStatus.FUNDING; // Ready for funding
            _updateUserReputation(project.proposer, 10); // Reward for project approval
        } else if (_newStatus == ProjectStatus.REJECTED) {
            _deductUserReputation(project.proposer, 3); // Small deduction for rejection
        }

        emit ProjectStatusUpdated(_projectId, oldStatus, project.status);
    }

    /**
     * @notice Allows approved users to contribute funds to an APPROVED project.
     * @param _projectId The ID of the project to fund.
     * @param _amount The amount of Ether to contribute.
     */
    function fundProject(uint256 _projectId, uint256 _amount) public payable nonReentrant projectExists(_projectId) {
        Project storage project = projects[_projectId];
        require(project.status == ProjectStatus.FUNDING, "Project is not open for funding");
        require(msg.value == _amount, "Sent Ether does not match specified amount");
        require(project.currentFunding + _amount <= project.fundingGoal, "Contribution exceeds funding goal");
        require(userReputation[msg.sender] >= project.reputationScoreNeeded, "Insufficient reputation to contribute");

        project.currentFunding += _amount;
        project.contributors[msg.sender] += _amount; // Track individual contributions
        totalCapitalPool += _amount; // Add to central pool

        _updateUserReputation(msg.sender, 2); // Reward for funding a project

        if (project.currentFunding == project.fundingGoal) {
            project.status = ProjectStatus.ACTIVE; // Project fully funded, ready for execution
            _updateUserReputation(project.proposer, 20); // Significant reward for securing funding
            emit ProjectStatusUpdated(_projectId, ProjectStatus.FUNDING, ProjectStatus.ACTIVE);
        }

        emit ProjectFunded(_projectId, msg.sender, _amount);
    }

    /**
     * @notice Allows the project proposer to add new milestones for their project.
     * @param _projectId The ID of the project.
     * @param _description A description of the milestone.
     * @param _payoutPercentage The percentage of total funding goal to be released upon this milestone's approval.
     */
    function addMilestone(uint256 _projectId, string memory _description, uint256 _payoutPercentage)
        public
        onlyProjectProposer(_projectId)
        projectExists(_projectId)
    {
        Project storage project = projects[_projectId];
        require(project.status == ProjectStatus.FUNDING || project.status == ProjectStatus.ACTIVE, "Project is not in a modifiable state");
        require(_payoutPercentage > 0 && _payoutPercentage <= 100, "Payout percentage must be between 1 and 100");
        require(project.totalPayoutPercentageApproved + _payoutPercentage <= 100, "Total payout percentages exceed 100%");

        project.milestones.push(Milestone({
            description: _description,
            payoutPercentage: _payoutPercentage,
            completed: false,
            completionProofIpfsHash: "",
            approvalBlock: 0
        }));

        emit MilestoneAdded(_projectId, project.milestones.length - 1, _description, _payoutPercentage);
    }

    /**
     * @notice Proposer submits proof of milestone completion.
     * @param _projectId The ID of the project.
     * @param _milestoneIndex The index of the milestone.
     * @param _proofIpfsHash IPFS hash for proof of completion (e.g., link to repo, report, demo).
     */
    function submitMilestoneProof(uint256 _projectId, uint256 _milestoneIndex, string memory _proofIpfsHash)
        public
        onlyProjectProposer(_projectId)
        projectExists(_projectId)
    {
        Project storage project = projects[_projectId];
        require(_milestoneIndex < project.milestones.length, "Milestone index out of bounds");
        require(!project.milestones[_milestoneIndex].completed, "Milestone already completed");
        require(bytes(_proofIpfsHash).length > 0, "Proof IPFS hash cannot be empty");

        project.milestones[_milestoneIndex].completionProofIpfsHash = _proofIpfsHash;

        emit MilestoneSubmitted(_projectId, _milestoneIndex, _proofIpfsHash);
    }

    /**
     * @notice Governance/DAO function to approve a submitted milestone, triggering a partial fund release.
     * @dev This function would ideally be called by a successful governance proposal.
     * @param _projectId The ID of the project.
     * @param _milestoneIndex The index of the milestone.
     */
    function approveMilestone(uint256 _projectId, uint256 _milestoneIndex)
        public
        onlyOwner // Placeholder for DAO governance. In a real system, this would be `executeProposal`
        projectExists(_projectId)
    {
        Project storage project = projects[_projectId];
        require(_milestoneIndex < project.milestones.length, "Milestone index out of bounds");
        require(!project.milestones[_milestoneIndex].completed, "Milestone already completed");
        require(bytes(project.milestones[_milestoneIndex].completionProofIpfsHash).length > 0, "Proof not submitted for milestone");
        require(project.status == ProjectStatus.ACTIVE, "Project is not active");

        project.milestones[_milestoneIndex].completed = true;
        project.milestones[_milestoneIndex].approvalBlock = block.number;
        project.totalPayoutPercentageApproved += project.milestones[_milestoneIndex].payoutPercentage;

        // Release funds for this milestone
        _releaseProjectFunds(_projectId, _milestoneIndex);

        _updateUserReputation(msg.sender, 3); // Reward for approving a milestone
        _updateUserReputation(project.proposer, 15); // Significant reward for milestone completion

        emit MilestoneApproved(_projectId, _milestoneIndex, project.fundsReleased);
    }

    /**
     * @notice Internal function to transfer funds to the project proposer based on milestone approval.
     * @dev Called by `approveMilestone`.
     * @param _projectId The ID of the project.
     * @param _milestoneIndex The index of the milestone.
     */
    function _releaseProjectFunds(uint256 _projectId, uint256 _milestoneIndex) internal nonReentrant {
        Project storage project = projects[_projectId];
        Milestone storage milestone = project.milestones[_milestoneIndex];

        uint256 amountToRelease = (project.fundingGoal * milestone.payoutPercentage) / 100;
        require(totalCapitalPool >= amountToRelease, "Insufficient funds in pool to release milestone payout");
        require(project.fundsReleased + amountToRelease <= project.fundingGoal, "Cannot release more than total funding goal");

        totalCapitalPool -= amountToRelease;
        project.fundsReleased += amountToRelease;

        payable(project.proposer).transfer(amountToRelease);
    }

    /**
     * @notice Marks a project as completed if all milestones are approved.
     * @param _projectId The ID of the project to complete.
     */
    function completeProject(uint256 _projectId) public nonReentrant projectExists(_projectId) {
        Project storage project = projects[_projectId];
        require(project.proposer == msg.sender, "Only project proposer can mark project complete");
        require(project.status == ProjectStatus.ACTIVE, "Project is not active");
        require(project.totalPayoutPercentageApproved >= 100, "All milestones must be 100% approved to complete project");
        
        // Ensure all milestones are marked complete
        for (uint i = 0; i < project.milestones.length; i++) {
            require(project.milestones[i].completed, "All milestones must be marked complete");
        }

        project.status = ProjectStatus.COMPLETED;

        // Calculate any remaining balance from funding goal not yet released (due to rounding or leftover)
        uint256 finalReward = project.fundingGoal - project.fundsReleased;
        if (finalReward > 0) {
            require(totalCapitalPool >= finalReward, "Insufficient capital for final reward");
            totalCapitalPool -= finalReward;
            payable(project.proposer).transfer(finalReward);
            project.fundsReleased += finalReward; // Account for final payout
        }

        // Mint a unique Innovation NFT for the project proposer
        string memory tokenURI = string(abi.encodePacked("ipfs://", project.ipfsHash, "/quantum_nexus_innovation_nft_", Strings.toString(_projectId)));
        uint256 tokenId = innovationNFT.mint(project.proposer, tokenURI);
        project.innovationNftId = tokenId;

        _updateUserReputation(project.proposer, 50); // Major reward for completing a project

        emit ProjectCompleted(_projectId, project.proposer, finalReward);
        emit InnovationNFTMinted(_projectId, project.proposer, tokenId);
        emit ProjectStatusUpdated(_projectId, ProjectStatus.ACTIVE, ProjectStatus.COMPLETED);
    }

    /**
     * @notice Allows successful project proposers to claim remaining funds after project completion.
     * @dev This function is redundant if `completeProject` handles final payout. Left as an example for explicit claiming.
     * @param _projectId The ID of the project.
     */
    function claimProjectRewards(uint256 _projectId) public nonReentrant onlyProjectProposer(_projectId) projectExists(_projectId) {
        Project storage project = projects[_projectId];
        require(project.status == ProjectStatus.COMPLETED, "Project is not completed");
        require(project.fundsReleased < project.fundingGoal, "No remaining funds to claim");

        uint256 remainingFunds = project.fundingGoal - project.fundsReleased;
        require(totalCapitalPool >= remainingFunds, "Insufficient capital for final reward");

        totalCapitalPool -= remainingFunds;
        project.fundsReleased += remainingFunds;
        payable(msg.sender).transfer(remainingFunds);

        emit ProjectRewardsClaimed(_projectId, msg.sender, remainingFunds);
    }

    /**
     * @notice Allows DAO/governance to liquidate an underperforming or failed project.
     * @dev Remaining funds are returned proportionally to contributors (simplified here).
     * @param _projectId The ID of the project to liquidate.
     */
    function liquidateProject(uint256 _projectId)
        public
        onlyOwner // Placeholder for DAO governance
        nonReentrant
        projectExists(_projectId)
    {
        Project storage project = projects[_projectId];
        require(project.status == ProjectStatus.ACTIVE || project.status == ProjectStatus.FUNDING, "Project not in active or funding state");

        ProjectStatus oldStatus = project.status;
        project.status = ProjectStatus.FAILED; // Mark as failed

        // Return remaining funds to contributors (simplified: this would require iterating contributors map)
        uint256 fundsRemaining = project.currentFunding - project.fundsReleased;
        if (fundsRemaining > 0) {
            totalCapitalPool -= fundsRemaining; // Remove from pool
            // In a real system, distribute proportionally to project.contributors
            // For simplicity, these funds are now effectively "lost" from the project context but still in Nexus for other uses
        }

        _deductUserReputation(project.proposer, 25); // Significant deduction for failed project

        emit ProjectLiquidated(_projectId, msg.sender);
        emit ProjectStatusUpdated(_projectId, oldStatus, ProjectStatus.FAILED);
    }

    // --- Governance & Voting Functions ---

    /**
     * @notice Allows users with sufficient reputation to create a governance proposal.
     * @param _description A description of the proposal (e.g., IPFS hash to full details).
     * @param _calldata The encoded function call to be executed if the proposal passes.
     */
    function createGovernanceProposal(string memory _description, bytes memory _calldata) public {
        require(userReputation[msg.sender] >= proposalThresholdReputation, "Insufficient reputation to propose");
        require(bytes(_description).length > 0, "Proposal description cannot be empty");
        require(_calldata.length > 0, "Calldata cannot be empty for executable proposal");

        uint256 newProposalId = _nextProposalId.current();
        governanceProposals[newProposalId] = GovernanceProposal({
            id: newProposalId,
            proposer: msg.sender,
            description: _description,
            calldata: _calldata,
            status: ProposalStatus.PENDING,
            proposalBlock: block.number,
            votingPeriodBlocks: votingPeriodBlocks,
            totalVotesFor: 0,
            totalVotesAgainst: 0
        });
        _nextProposalId.increment();

        _updateUserReputation(msg.sender, 5); // Reward for creating a proposal

        emit GovernanceProposalCreated(newProposalId, msg.sender, _description);
    }

    /**
     * @notice Allows users to vote on a governance proposal, weighted by their reputation.
     * @param _proposalId The ID of the proposal.
     * @param _support True for 'for' vote, false for 'against' vote.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) public proposalExists(_proposalId) {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(proposal.status == ProposalStatus.PENDING, "Proposal is not open for voting");
        require(block.number < proposal.proposalBlock + proposal.votingPeriodBlocks, "Voting period has ended");
        
        address voter = msg.sender;
        if (reputationDelegates[msg.sender] != address(0)) {
            voter = reputationDelegates[msg.sender]; // If delegated, the delegatee votes
        }
        
        require(!proposal.hasVoted[voter], "Already voted on this proposal");
        require(userReputation[voter] > 0, "User has no reputation to vote");

        uint256 voteWeight = userReputation[voter];

        if (_support) {
            proposal.totalVotesFor += voteWeight;
        } else {
            proposal.totalVotesAgainst += voteWeight;
        }
        proposal.hasVoted[voter] = true;
        proposal.voteSupport[voter] = _support;

        _updateUserReputation(voter, 1); // Small reward for active participation

        emit VoteCast(_proposalId, voter, _support, voteWeight);
    }

    /**
     * @notice Allows users to delegate their reputation and voting power to another address.
     * @param _delegatee The address to delegate reputation to.
     */
    function delegateReputation(address _delegatee) public {
        require(_delegatee != address(0), "Cannot delegate to zero address");
        require(_delegatee != msg.sender, "Cannot delegate to self");
        require(userReputation[msg.sender] > 0, "No reputation to delegate"); // Only delegate if you have reputation

        reputationDelegates[msg.sender] = _delegatee;
        emit ReputationDelegated(msg.sender, _delegatee);
    }

    /**
     * @notice Revokes any active reputation delegation.
     */
    function undelegateReputation() public {
        require(reputationDelegates[msg.sender] != address(0), "No active delegation to undelegate");
        reputationDelegates[msg.sender] = address(0);
        emit ReputationUndelegated(msg.sender);
    }

    /**
     * @notice Executes a governance proposal if it has met quorum and passed.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) public nonReentrant proposalExists(_proposalId) {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(proposal.status == ProposalStatus.PENDING, "Proposal is not in pending state");
        require(block.number >= proposal.proposalBlock + proposal.votingPeriodBlocks, "Voting period has not ended yet");

        uint256 totalPossibleReputation = totalCapitalPool > 0 ? totalCapitalPool : 1; // Simplified: Use total capital as proxy for total stake/reputation for quorum
        // A more robust system would track total active reputation.
        uint256 requiredQuorum = (totalPossibleReputation * quorumPercentage) / 100;

        bool passed = false;
        if (proposal.totalVotesFor >= requiredQuorum && proposal.totalVotesFor > proposal.totalVotesAgainst) {
            passed = true;
            proposal.status = ProposalStatus.SUCCEEDED;
        } else {
            proposal.status = ProposalStatus.DEFEATED;
        }

        if (passed) {
            (bool success, ) = address(this).call(proposal.calldata);
            require(success, "Proposal execution failed");
            proposal.status = ProposalStatus.EXECUTED;
            _updateUserReputation(proposal.proposer, 20); // Reward for successful execution
        } else {
            _deductUserReputation(proposal.proposer, 10); // Deduct for defeated proposal
        }

        emit ProposalExecuted(_proposalId, passed);
    }

    // --- Oracle & Admin Functions ---

    /**
     * @notice Sets the address of the external oracle for AI-driven insights/project scoring.
     * @dev Only callable by the contract owner.
     * @param _oracle The address of the oracle contract.
     */
    function setOracleAddress(address _oracle) public onlyOwner {
        require(_oracle != address(0), "Oracle address cannot be zero");
        oracleAddress = _oracle;
    }

    /**
     * @notice Sets the governance parameters for the contract.
     * @dev Only callable by the contract owner or via governance proposal.
     * @param _proposalThreshold The minimum reputation required to propose.
     * @param _quorumPercentage The percentage of total reputation needed for a quorum.
     * @param _votingPeriodBlocks The number of blocks for a voting period.
     */
    function setGovernanceParameters(uint256 _proposalThreshold, uint256 _quorumPercentage, uint256 _votingPeriodBlocks) public onlyOwner {
        require(_quorumPercentage > 0 && _quorumPercentage <= 100, "Quorum percentage must be between 1 and 100");
        require(_votingPeriodBlocks > 0, "Voting period must be greater than 0");
        proposalThresholdReputation = _proposalThreshold;
        quorumPercentage = _quorumPercentage;
        votingPeriodBlocks = _votingPeriodBlocks;
    }

    // --- View Functions ---

    /**
     * @notice Retrieves all relevant details for a specific project.
     * @param _projectId The ID of the project.
     * @return A tuple containing project details.
     */
    function getProjectDetails(uint256 _projectId)
        public
        view
        projectExists(_projectId)
        returns (
            uint256 id,
            address proposer,
            string memory ipfsHash,
            ProjectStatus status,
            uint256 fundingGoal,
            uint256 currentFunding,
            uint256 fundsReleased,
            uint256 reputationScoreNeeded,
            uint256 proposalBlock,
            uint256 totalPayoutPercentageApproved,
            uint256 milestoneCount,
            uint256 innovationNftId
        )
    {
        Project storage project = projects[_projectId];
        return (
            project.id,
            project.proposer,
            project.ipfsHash,
            project.status,
            project.fundingGoal,
            project.currentFunding,
            project.fundsReleased,
            project.reputationScoreNeeded,
            project.proposalBlock,
            project.totalPayoutPercentageApproved,
            project.milestones.length,
            project.innovationNftId
        );
    }

    /**
     * @notice Retrieves details for a specific milestone of a project.
     * @param _projectId The ID of the project.
     * @param _milestoneIndex The index of the milestone.
     * @return A tuple containing milestone details.
     */
    function getMilestoneDetails(uint256 _projectId, uint256 _milestoneIndex)
        public
        view
        projectExists(_projectId)
        returns (string memory description, uint256 payoutPercentage, bool completed, string memory completionProofIpfsHash, uint256 approvalBlock)
    {
        Project storage project = projects[_projectId];
        require(_milestoneIndex < project.milestones.length, "Milestone index out of bounds");
        Milestone storage milestone = project.milestones[_milestoneIndex];
        return (milestone.description, milestone.payoutPercentage, milestone.completed, milestone.completionProofIpfsHash, milestone.approvalBlock);
    }

    /**
     * @notice Retrieves all relevant details for a specific governance proposal.
     * @param _proposalId The ID of the proposal.
     * @return A tuple containing proposal details.
     */
    function getProposalDetails(uint256 _proposalId)
        public
        view
        proposalExists(_proposalId)
        returns (
            uint256 id,
            address proposer,
            string memory description,
            ProposalStatus status,
            uint256 proposalBlock,
            uint256 votingPeriodBlocks,
            uint256 totalVotesFor,
            uint256 totalVotesAgainst
        )
    {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        return (
            proposal.id,
            proposal.proposer,
            proposal.description,
            proposal.status,
            proposal.proposalBlock,
            proposal.votingPeriodBlocks,
            proposal.totalVotesFor,
            proposal.totalVotesAgainst
        );
    }

    /**
     * @notice Returns the total amount of Ether held in the Nexus capital pool.
     * @return The total capital in the pool.
     */
    function getCurrentCapitalPool() public view returns (uint256) {
        return totalCapitalPool;
    }
}
```