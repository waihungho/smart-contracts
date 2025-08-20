This smart contract, `AutonomousImpactNexus`, is designed as a decentralized protocol for funding "Impact Projects" and managing a dynamic, verifiable "Impact Reputation" system. It aims to connect real-world impact (verified via an oracle) with on-chain funding and reputation, incentivizing positive contributions to collective goals.

It focuses on advanced concepts like:
*   **Outcome-Based Funding:** Funds are released only upon oracle-verified completion of milestones.
*   **Dynamic Reputation System (`ImpactScore`):** Reputation is earned through verifiable positive actions (funding successful projects, proposing impactful initiatives, successful challenge resolution) and can be time-decayed or boosted by staking.
*   **Decentralized Oracle Integration (Simulated):** A mechanism for off-chain data (proofs of impact) to be brought on-chain to trigger fund releases and reputation updates.
*   **On-chain Challenge Mechanism:** Allows users to dispute project claims or oracle reports, ensuring accountability.
*   **Multi-ERC20 Support:** Flexibility in funding mechanisms.

---

## AutonomousImpactNexus (AIN)

**Core Concept:** A decentralized protocol facilitating outcome-based funding for "Impact Projects" and managing a dynamic, verifiable "Impact Reputation" system. It connects real-world impact (verified via an oracle) with on-chain funding and reputation, incentivizing positive contributions to collective goals.

**Key Features:**

1.  **Outcome-Based Funding:** Funds are released to projects only upon the successful, oracle-verified completion of predefined milestones.
2.  **Dynamic Reputation System:** User reputation (`ImpactScore`) is earned through various positive actions (funding successful projects, proposing impactful initiatives, successful challenge resolution) and can decay over time or be boosted by staking. Reputation dictates voting power and protocol access.
3.  **Project Lifecycle Management:** Comprehensive workflow from project proposal and community voting to milestone submission, oracle verification, and fund disbursement.
4.  **Decentralized Oracle Integration (Simulated):** Incorporates a mechanism for off-chain data (proofs of impact) to be brought on-chain via a trusted oracle, triggering fund releases and reputation updates.
5.  **Challenge Mechanism:** Allows users to dispute project claims or oracle reports, ensuring accountability and data integrity.
6.  **Flexible Funding:** Supports multiple ERC20 tokens for funding.

---

### Function Summary:

**I. Core Protocol Management:**
1.  `constructor(address _initialOracle, address _initialChallengeAuthority, uint256 _reputationDecayRate, uint256 _challengeBond)`: Initializes the contract with base parameters and trusted addresses.
2.  `updateProtocolParameter(bytes32 _paramName, uint256 _newValue)`: Allows owner to adjust core protocol parameters (e.g., reputation decay rate, challenge bond).
3.  `pauseProtocol()`: Emergency function to pause critical contract operations.
4.  `unpauseProtocol()`: Resumes protocol operations.
5.  `setTrustedOracleAddress(address _newOracle)`: Sets or updates the address of the trusted oracle (for simplified demonstration).
6.  `setChallengeResolutionAuthority(address _newAuthority)`: Sets or updates the address authorized to resolve challenges.
7.  `emergencyWithdrawFunds(address _tokenAddress, uint256 _amount)`: Owner can withdraw accidentally sent ERC20 tokens.

**II. Funding & Resource Management:**
8.  `depositFundsForImpact(address _tokenAddress, uint256 _amount)`: Users deposit ERC20 tokens into a general pool to be later allocated to projects.
9.  `withdrawFundsFromPool(address _tokenAddress, uint256 _amount)`: Allows users to withdraw their unallocated deposited funds.
10. `allocateFundsToProject(uint256 _projectId, address _tokenAddress, uint256 _amount)`: Users commit their deposited funds to support a specific impact project proposal.
11. `getProjectPooledFunds(uint256 _projectId, address _tokenAddress)`: Retrieves the total funds allocated to a specific project for a given token.
12. `releaseMilestoneFunds(uint256 _projectId, uint256 _milestoneIndex)`: Triggers the transfer of funds to a project owner for a successfully verified milestone.

**III. Impact Project Lifecycle:**
13. `proposeImpactProject(string memory _projectName, string memory _descriptionURI, uint256 _totalFundingGoal, uint256[] memory _milestoneAmounts, bytes32[] memory _milestoneHashes, uint256 _votingDuration)`: Allows users to propose a new impact project, defining its goals, milestones (with off-chain proof hashes), and required funding.
14. `voteOnProjectProposal(uint256 _projectId, bool _approve)`: Stakeholders vote on project proposals, with vote weight influenced by their ImpactScore.
15. `submitMilestoneProofRequest(uint256 _projectId, uint256 _milestoneIndex, bytes memory _proofDigest)`: Project owners submit a request for oracle verification of a completed milestone, providing a cryptographic digest of their off-chain proof.
16. `challengeMilestoneVerification(uint256 _projectId, uint256 _milestoneIndex, string memory _reason)`: Enables any user to dispute a milestone's verification status or a past verified one, requiring a bond.
17. `resolveChallenge(uint256 _challengeId, bool _isChallengerCorrect)`: An authorized entity (e.g., challenge resolution authority) resolves a challenge, determining its outcome.
18. `cancelProjectProposal(uint256 _projectId)`: Project proposer can cancel their unapproved project before voting ends.
19. `getProjectStatus(uint256 _projectId)`: Retrieves the current status and details of a project.
20. `getMilestoneStatus(uint256 _projectId, uint256 _milestoneIndex)`: Retrieves the status and details of a specific project milestone.

**IV. Reputation & Participation:**
21. `getReputationScore(address _user)`: Returns a user's current calculated ImpactScore, accounting for decay and multipliers.
22. `_updateReputationOnAction(address _user, uint256 _actionType, int256 _delta)`: (Internal) Updates a user's ImpactScore based on various protocol actions (e.g., successful vote, project completion).
23. `stakeForReputationMultiplier(uint256 _amount)`: Users stake a specific token (e.g., a dedicated governance token or ETH) to temporarily boost their ImpactScore calculation.
24. `unstakeForReputationMultiplier()`: Users unstake their tokens, removing the reputation boost.

**V. Oracle Integration & Advanced Concepts:**
25. `receiveOracleReport(uint256 _projectId, uint256 _milestoneIndex, bool _isVerified, bytes32 _reportHash)`: (Callable by trusted oracle) Notifies the contract of a milestone verification outcome, triggering fund release and reputation updates.
26. `submitAttestation(uint256 _attestationId, bytes32 _dataHash)`: Allows users to submit verifiable attestations about external activities, contributing to a broader reputation graph or future impact assessments (conceptual, for future expansion of the reputation system).
27. `getChallengeDetails(uint256 _challengeId)`: Retrieves details of an ongoing or resolved challenge.

---
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/**
 * @title AutonomousImpactNexus (AIN)
 * @dev A decentralized protocol for outcome-based funding of "Impact Projects"
 *      and managing a dynamic, verifiable "Impact Reputation" system.
 *      It connects real-world impact (verified via an oracle) with on-chain
 *      funding and reputation, incentivizing positive contributions.
 */
contract AutonomousImpactNexus is Ownable, Pausable {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    // --- State Variables ---

    uint256 private nextProjectId;
    uint256 private nextChallengeId;

    address public trustedOracle; // Address of the trusted oracle (simplified for this example)
    address public challengeResolutionAuthority; // Address authorized to resolve challenges

    // Protocol Parameters (adjustable by owner)
    uint256 public constant REPUTATION_DECAY_PERIOD = 30 days; // How often reputation decays
    uint256 public reputationDecayRatePercentage; // % of reputation lost per decay period (e.g., 5 for 5%)
    uint256 public challengeBondAmount; // Amount of a token required to open a challenge

    // Mapping for user balances in the general funding pool
    mapping(address => mapping(address => uint256)) public userDeposits; // user => tokenAddress => amount

    // --- Project Management ---
    enum ProjectStatus { Proposed, Active, Completed, Failed, Cancelled }
    enum MilestoneStatus { Pending, ProofSubmitted, Verified, Challenged }

    struct Milestone {
        uint256 amount;             // Funding requested for this milestone
        bytes32 proofHash;          // Cryptographic hash of the off-chain proof
        MilestoneStatus status;     // Current status of the milestone
        uint256 verificationTimestamp; // Timestamp when oracle verified, or 0
        uint256 challengeId;        // ID of the active challenge if status is Challenged
    }

    struct Project {
        uint256 id;                 // Unique Project ID
        address owner;              // Project proposer
        string name;                // Project name
        string descriptionURI;      // URI to off-chain description/details
        uint256 totalFundingGoal;   // Total funding goal for the project
        uint256 currentFunding;     // Current funds allocated/locked for this project
        address[] fundingTokens;    // List of tokens accepted for this project
        mapping(address => uint256) allocatedFundsPerToken; // tokenAddress => amount allocated
        Milestone[] milestones;     // Array of milestones
        ProjectStatus status;       // Current project status
        uint256 proposalVoteEndTime; // Timestamp when project proposal voting ends
        EnumerableSet.AddressSet voters; // Set of addresses that have voted on this proposal
        uint256 totalReputationVotesFor; // Sum of reputation scores for 'approve' votes
        uint256 totalReputationVotesAgainst; // Sum of reputation scores for 'reject' votes
    }

    mapping(uint256 => Project) public projects;
    mapping(uint256 => address[]) public projectFunders; // project ID => array of funders

    // --- Reputation System ---
    enum ReputationActionType { ProjectProposed, ProjectVoted, MilestoneVerified, ChallengeResolvedSuccess, ChallengeResolvedFail, FundingContribution }

    struct ImpactScore {
        uint256 score;             // Current raw reputation score
        uint256 lastUpdated;       // Last timestamp score was updated or decayed
        uint256 stakedAmount;      // Amount of token staked for multiplier
        uint256 stakeStartTime;    // Timestamp when stake began
    }

    mapping(address => ImpactScore) public impactReputation;
    address public reputationStakeToken; // Token used for staking to boost reputation (e.g., a governance token)

    // --- Challenge System ---
    enum ChallengeStatus { Open, ResolvedSuccess, ResolvedFail }

    struct Challenge {
        uint256 id;                 // Unique Challenge ID
        address challenger;         // Address that initiated the challenge
        uint256 projectId;          // Project ID being challenged
        uint256 milestoneIndex;     // Milestone index being challenged (if applicable, 0 for project level)
        string reason;              // Reason for the challenge
        uint256 bondAmount;         // Amount staked by challenger
        address bondToken;          // Token used for the bond
        ChallengeStatus status;     // Current status of the challenge
        uint256 initiatedAt;        // Timestamp when challenge was initiated
        bool isChallengerCorrect;   // Result of the challenge (true if challenger was correct)
    }

    mapping(uint256 => Challenge) public challenges;

    // --- Events ---
    event ParameterUpdated(bytes32 indexed paramName, uint256 newValue);
    event FundsDeposited(address indexed user, address indexed token, uint256 amount);
    event FundsWithdrawn(address indexed user, address indexed token, uint256 amount);
    event FundsAllocated(address indexed user, uint256 indexed projectId, address indexed token, uint256 amount);
    event ProjectProposed(uint256 indexed projectId, address indexed owner, string name, uint256 totalGoal);
    event ProjectVoteCast(uint256 indexed projectId, address indexed voter, bool approve, uint256 reputationWeight);
    event ProjectStatusChanged(uint256 indexed projectId, ProjectStatus newStatus);
    event MilestoneProofRequestSubmitted(uint256 indexed projectId, uint256 indexed milestoneIndex, address indexed submitter, bytes proofDigest);
    event MilestoneVerified(uint256 indexed projectId, uint256 indexed milestoneIndex, bool isVerified);
    event MilestoneFundsReleased(uint256 indexed projectId, uint256 indexed milestoneIndex, uint256 amount);
    event ChallengeInitiated(uint256 indexed challengeId, address indexed challenger, uint256 indexed projectId, uint256 milestoneIndex, string reason);
    event ChallengeResolved(uint256 indexed challengeId, bool isChallengerCorrect, address indexed resolver);
    event ReputationUpdated(address indexed user, uint256 newScore, uint256 oldScore, ReputationActionType actionType);
    event ReputationStaked(address indexed user, uint256 amount);
    event ReputationUnstaked(address indexed user, uint256 amount);

    // --- Modifiers ---
    modifier onlyOracle() {
        require(msg.sender == trustedOracle, "AIN: Only trusted oracle can call");
        _;
    }

    modifier onlyChallengeAuthority() {
        require(msg.sender == challengeResolutionAuthority, "AIN: Only challenge authority can call");
        _;
    }

    // --- Constructor ---
    /**
     * @dev Constructor for AutonomousImpactNexus.
     * @param _initialOracle The initial address of the trusted oracle.
     * @param _initialChallengeAuthority The initial address authorized to resolve challenges.
     * @param _reputationDecayRatePercentage The percentage of reputation lost per decay period (e.g., 5 for 5%).
     * @param _challengeBond The amount of token required to open a challenge.
     * @param _reputationStakeToken The ERC20 token address used for staking to boost reputation.
     */
    constructor(
        address _initialOracle,
        address _initialChallengeAuthority,
        uint256 _reputationDecayRatePercentage,
        uint256 _challengeBond,
        address _reputationStakeToken
    ) Ownable(msg.sender) Pausable() {
        require(_initialOracle != address(0), "AIN: Oracle cannot be zero address");
        require(_initialChallengeAuthority != address(0), "AIN: Challenge authority cannot be zero address");
        require(_reputationStakeToken != address(0), "AIN: Reputation stake token cannot be zero address");
        require(_reputationDecayRatePercentage <= 100, "AIN: Decay rate cannot exceed 100%");

        trustedOracle = _initialOracle;
        challengeResolutionAuthority = _initialChallengeAuthority;
        reputationDecayRatePercentage = _reputationDecayRatePercentage;
        challengeBondAmount = _challengeBond;
        reputationStakeToken = _reputationStakeToken;
        nextProjectId = 1;
        nextChallengeId = 1;
    }

    // --- I. Core Protocol Management ---

    /**
     * @dev Allows owner to adjust core protocol parameters.
     * @param _paramName The name of the parameter (e.g., "reputationDecayRate", "challengeBond").
     * @param _newValue The new value for the parameter.
     */
    function updateProtocolParameter(bytes32 _paramName, uint256 _newValue) public onlyOwner {
        require(_newValue > 0, "AIN: New value must be positive");
        if (_paramName == "reputationDecayRatePercentage") {
            require(_newValue <= 100, "AIN: Decay rate cannot exceed 100%");
            reputationDecayRatePercentage = _newValue;
        } else if (_paramName == "challengeBondAmount") {
            challengeBondAmount = _newValue;
        } else {
            revert("AIN: Unknown parameter");
        }
        emit ParameterUpdated(_paramName, _newValue);
    }

    /**
     * @dev Emergency function to pause critical contract operations.
     */
    function pauseProtocol() public onlyOwner {
        _pause();
    }

    /**
     * @dev Resumes protocol operations.
     */
    function unpauseProtocol() public onlyOwner {
        _unpause();
    }

    /**
     * @dev Sets or updates the address of the trusted oracle.
     *      In a real-world scenario, this would likely be a decentralized oracle network.
     * @param _newOracle The new oracle address.
     */
    function setTrustedOracleAddress(address _newOracle) public onlyOwner {
        require(_newOracle != address(0), "AIN: New oracle cannot be zero address");
        trustedOracle = _newOracle;
        emit ParameterUpdated("trustedOracle", uint256(uint160(_newOracle)));
    }

    /**
     * @dev Sets or updates the address authorized to resolve challenges.
     *      Could be a DAO or a trusted multi-sig.
     * @param _newAuthority The new challenge resolution authority address.
     */
    function setChallengeResolutionAuthority(address _newAuthority) public onlyOwner {
        require(_newAuthority != address(0), "AIN: New authority cannot be zero address");
        challengeResolutionAuthority = _newAuthority;
        emit ParameterUpdated("challengeResolutionAuthority", uint256(uint160(_newAuthority)));
    }

    /**
     * @dev Owner can withdraw accidentally sent ERC20 tokens.
     * @param _tokenAddress The address of the ERC20 token.
     * @param _amount The amount to withdraw.
     */
    function emergencyWithdrawFunds(address _tokenAddress, uint256 _amount) public onlyOwner {
        require(IERC20(_tokenAddress).balanceOf(address(this)) >= _amount, "AIN: Insufficient contract balance");
        IERC20(_tokenAddress).transfer(owner(), _amount);
    }

    // --- II. Funding & Resource Management ---

    /**
     * @dev Users deposit ERC20 tokens into a general pool to be later allocated to projects.
     * @param _tokenAddress The address of the ERC20 token to deposit.
     * @param _amount The amount of tokens to deposit.
     */
    function depositFundsForImpact(address _tokenAddress, uint256 _amount) public whenNotPaused {
        require(_amount > 0, "AIN: Deposit amount must be positive");
        IERC20(_tokenAddress).transferFrom(msg.sender, address(this), _amount);
        userDeposits[msg.sender][_tokenAddress] = userDeposits[msg.sender][_tokenAddress].add(_amount);
        emit FundsDeposited(msg.sender, _tokenAddress, _amount);
    }

    /**
     * @dev Allows users to withdraw their unallocated deposited funds from the general pool.
     * @param _tokenAddress The address of the ERC20 token to withdraw.
     * @param _amount The amount of tokens to withdraw.
     */
    function withdrawFundsFromPool(address _tokenAddress, uint256 _amount) public whenNotPaused {
        require(_amount > 0, "AIN: Withdrawal amount must be positive");
        require(userDeposits[msg.sender][_tokenAddress] >= _amount, "AIN: Insufficient user deposit balance");
        userDeposits[msg.sender][_tokenAddress] = userDeposits[msg.sender][_tokenAddress].sub(_amount);
        IERC20(_tokenAddress).transfer(msg.sender, _amount);
        emit FundsWithdrawn(msg.sender, _tokenAddress, _amount);
    }

    /**
     * @dev Users commit their deposited funds to support a specific impact project proposal.
     *      Funds are locked and contribute to the project's 'currentFunding' upon approval.
     * @param _projectId The ID of the project to allocate funds to.
     * @param _tokenAddress The address of the ERC20 token to allocate.
     * @param _amount The amount of tokens to allocate.
     */
    function allocateFundsToProject(uint256 _projectId, address _tokenAddress, uint256 _amount) public whenNotPaused {
        Project storage project = projects[_projectId];
        require(project.status == ProjectStatus.Proposed, "AIN: Project is not in 'Proposed' status");
        require(userDeposits[msg.sender][_tokenAddress] >= _amount, "AIN: Insufficient unallocated deposits");
        require(_amount > 0, "AIN: Allocation amount must be positive");

        // Check if the token is accepted by the project (simplified check, could be more robust)
        bool tokenAccepted = false;
        for (uint i = 0; i < project.fundingTokens.length; i++) {
            if (project.fundingTokens[i] == _tokenAddress) {
                tokenAccepted = true;
                break;
            }
        }
        require(tokenAccepted || project.fundingTokens.length == 0, "AIN: Project does not accept this token");

        userDeposits[msg.sender][_tokenAddress] = userDeposits[msg.sender][_tokenAddress].sub(_amount);
        project.allocatedFundsPerToken[_tokenAddress] = project.allocatedFundsPerToken[_tokenAddress].add(_amount);
        project.currentFunding = project.currentFunding.add(_amount); // This assumes a single base currency for goal or sum in USD
        
        // Add funder to list if not already present
        bool funderExists = false;
        for(uint i=0; i<projectFunders[_projectId].length; i++){
            if(projectFunders[_projectId][i] == msg.sender){
                funderExists = true;
                break;
            }
        }
        if(!funderExists){
            projectFunders[_projectId].push(msg.sender);
        }

        emit FundsAllocated(msg.sender, _projectId, _tokenAddress, _amount);
    }

    /**
     * @dev Triggers the transfer of funds to a project owner for a successfully verified milestone.
     *      Callable by anyone, but requires the milestone to be 'Verified'.
     * @param _projectId The ID of the project.
     * @param _milestoneIndex The index of the milestone (0-indexed).
     */
    function releaseMilestoneFunds(uint256 _projectId, uint256 _milestoneIndex) public whenNotPaused {
        Project storage project = projects[_projectId];
        require(project.status == ProjectStatus.Active, "AIN: Project is not active");
        require(_milestoneIndex < project.milestones.length, "AIN: Invalid milestone index");

        Milestone storage milestone = project.milestones[_milestoneIndex];
        require(milestone.status == MilestoneStatus.Verified, "AIN: Milestone not verified");
        require(milestone.amount > 0, "AIN: Milestone amount must be positive"); // Already released or zero amount

        // Logic to transfer funds. This assumes 'currentFunding' for a project is multi-currency.
        // For simplicity, we assume the milestone 'amount' refers to a primary currency, or this function
        // needs to be called for each token type. For now, let's assume one primary token or
        // that 'currentFunding' represents a USD equivalent which requires more complex oracle integration.
        // For a more robust solution, 'milestone.amount' would need to be token-specific.
        // Let's modify project.allocatedFundsPerToken to represent *how much of that token is available for payout*.

        // Simplification: Assume 'currentFunding' directly reflects the available funds from funders,
        // and project.allocatedFundsPerToken stores the actual token amounts.
        // We'll release funds proportionally or from a pre-defined primary token.
        // For this example, let's assume the milestoneAmount is for ETH if no specific token is set,
        // or the first token in project.fundingTokens.
        address payoutToken = project.fundingTokens.length > 0 ? project.fundingTokens[0] : address(0); // If project accepts multiple, first one is default payout
        require(payoutToken != address(0), "AIN: No payout token defined for project");
        
        // Ensure enough allocated funds of the payout token
        require(project.allocatedFundsPerToken[payoutToken] >= milestone.amount, "AIN: Insufficient allocated funds for payout token");

        project.allocatedFundsPerToken[payoutToken] = project.allocatedFundsPerToken[payoutToken].sub(milestone.amount);
        project.currentFunding = project.currentFunding.sub(milestone.amount); // Reduce overall tracking
        milestone.amount = 0; // Mark as released

        IERC20(payoutToken).transfer(project.owner, milestone.amount);
        
        // Update reputation for the project owner
        _updateReputationOnAction(project.owner, ReputationActionType.MilestoneVerified, 100); // Example score boost

        emit MilestoneFundsReleased(_projectId, _milestoneIndex, milestone.amount);

        // If all milestones are completed, mark project as completed
        bool allMilestonesCompleted = true;
        for (uint i = 0; i < project.milestones.length; i++) {
            if (project.milestones[i].status != MilestoneStatus.Verified || project.milestones[i].amount > 0) {
                allMilestonesCompleted = false;
                break;
            }
        }
        if (allMilestonesCompleted) {
            project.status = ProjectStatus.Completed;
            emit ProjectStatusChanged(_projectId, ProjectStatus.Completed);
            
            // Reward funders of successful project
            for(uint i=0; i<projectFunders[_projectId].length; i++){
                _updateReputationOnAction(projectFunders[_projectId][i], ReputationActionType.FundingContribution, 50); // Example reward
            }
        }
    }


    // --- III. Impact Project Lifecycle ---

    /**
     * @dev Allows users to propose a new impact project, defining its goals, milestones, and required funding.
     * @param _projectName The name of the project.
     * @param _descriptionURI URI pointing to off-chain project details (e.g., IPFS hash).
     * @param _totalFundingGoal The total funding goal for the project (in a base currency, or sum of milestone amounts).
     * @param _milestoneAmounts An array of funding amounts for each milestone.
     * @param _milestoneHashes An array of cryptographic hashes of off-chain proofs for each milestone.
     * @param _votingDuration The duration in seconds for which the project proposal will be open for voting.
     */
    function proposeImpactProject(
        string memory _projectName,
        string memory _descriptionURI,
        uint256 _totalFundingGoal,
        uint256[] memory _milestoneAmounts,
        bytes32[] memory _milestoneHashes,
        uint256 _votingDuration
    ) public whenNotPaused {
        require(bytes(_projectName).length > 0, "AIN: Project name cannot be empty");
        require(bytes(_descriptionURI).length > 0, "AIN: Description URI cannot be empty");
        require(_totalFundingGoal > 0, "AIN: Total funding goal must be positive");
        require(_milestoneAmounts.length == _milestoneHashes.length, "AIN: Milestone amounts and hashes must match");
        require(_milestoneAmounts.length > 0, "AIN: At least one milestone is required");
        require(_votingDuration > 0, "AIN: Voting duration must be positive");

        uint256 currentId = nextProjectId++;
        Project storage newProject = projects[currentId];
        newProject.id = currentId;
        newProject.owner = msg.sender;
        newProject.name = _projectName;
        newProject.descriptionURI = _descriptionURI;
        newProject.totalFundingGoal = _totalFundingGoal;
        newProject.status = ProjectStatus.Proposed;
        newProject.proposalVoteEndTime = block.timestamp.add(_votingDuration);
        
        // Initialize milestones
        for (uint i = 0; i < _milestoneAmounts.length; i++) {
            newProject.milestones.push(Milestone({
                amount: _milestoneAmounts[i],
                proofHash: _milestoneHashes[i],
                status: MilestoneStatus.Pending,
                verificationTimestamp: 0,
                challengeId: 0
            }));
        }

        // Project owner gets a reputation boost for proposing
        _updateReputationOnAction(msg.sender, ReputationActionType.ProjectProposed, 20); // Example score

        emit ProjectProposed(currentId, msg.sender, _projectName, _totalFundingGoal);
    }

    /**
     * @dev Stakeholders vote on project proposals, with vote weight influenced by their ImpactScore.
     * @param _projectId The ID of the project to vote on.
     * @param _approve True to vote for approval, false for rejection.
     */
    function voteOnProjectProposal(uint256 _projectId, bool _approve) public whenNotPaused {
        Project storage project = projects[_projectId];
        require(project.status == ProjectStatus.Proposed, "AIN: Project is not in 'Proposed' status");
        require(block.timestamp <= project.proposalVoteEndTime, "AIN: Project voting has ended");
        require(!project.voters.contains(msg.sender), "AIN: User has already voted on this project");

        uint256 voterReputationWeight = getReputationScore(msg.sender); // Get weighted reputation score
        require(voterReputationWeight > 0, "AIN: Voter must have a positive reputation score to vote");

        if (_approve) {
            project.totalReputationVotesFor = project.totalReputationVotesFor.add(voterReputationWeight);
        } else {
            project.totalReputationVotesAgainst = project.totalReputationVotesAgainst.add(voterReputationWeight);
        }
        project.voters.add(msg.sender);

        // Update reputation for voting
        _updateReputationOnAction(msg.sender, ReputationActionType.ProjectVoted, 5); // Example score

        emit ProjectVoteCast(_projectId, msg.sender, _approve, voterReputationWeight);

        // Check if voting period ended and finalize proposal
        if (block.timestamp >= project.proposalVoteEndTime) {
            _finalizeProjectProposal(_projectId);
        }
    }

    /**
     * @dev Internal function to finalize a project proposal after its voting period ends.
     */
    function _finalizeProjectProposal(uint256 _projectId) internal {
        Project storage project = projects[_projectId];
        require(project.status == ProjectStatus.Proposed, "AIN: Project is not in 'Proposed' status");
        
        // This function can be called externally if the block.timestamp check is removed,
        // or a specific trigger function is added, or an off-chain keeper calls it.
        // For simplicity, we make it internal and implicitly triggered by the last vote if time is up.
        // In a production system, an external keeper would likely call this after vote end.
        if (block.timestamp < project.proposalVoteEndTime && (project.totalReputationVotesFor + project.totalReputationVotesAgainst) == 0) {
            // If voting duration not ended, and no votes, don't finalize yet.
            // This case handles external calls before time is up but after last vote.
            return;
        }

        if (project.totalReputationVotesFor > project.totalReputationVotesAgainst && project.currentFunding >= project.totalFundingGoal) {
            project.status = ProjectStatus.Active;
            emit ProjectStatusChanged(_projectId, ProjectStatus.Active);
        } else {
            project.status = ProjectStatus.Failed;
            emit ProjectStatusChanged(_projectId, ProjectStatus.Failed);
            // Refund allocated funds
            _refundProjectAllocatedFunds(_projectId);
        }
    }

    /**
     * @dev Internal function to refund funds for failed/cancelled projects.
     */
    function _refundProjectAllocatedFunds(uint256 _projectId) internal {
        Project storage project = projects[_projectId];
        require(project.status == ProjectStatus.Failed || project.status == ProjectStatus.Cancelled, "AIN: Project not in refund state");

        // Iterate through all funders and refund their allocated amounts
        for(uint i=0; i<projectFunders[_projectId].length; i++){
            address funder = projectFunders[_projectId][i];
            for(uint j=0; j<project.fundingTokens.length; j++){
                address token = project.fundingTokens[j];
                uint256 allocated = project.allocatedFundsPerToken[token];
                if(allocated > 0){
                    userDeposits[funder][token] = userDeposits[funder][token].add(allocated);
                    project.allocatedFundsPerToken[token] = 0; // Clear project's allocated amount for this token
                    emit FundsWithdrawn(funder, token, allocated); // Emit as withdrawal back to general pool
                }
            }
        }
        project.currentFunding = 0; // Reset overall tracking
    }


    /**
     * @dev Project owners submit a request for oracle verification of a completed milestone.
     * @param _projectId The ID of the project.
     * @param _milestoneIndex The index of the milestone (0-indexed).
     * @param _proofDigest A cryptographic digest of the off-chain proof data for the milestone.
     */
    function submitMilestoneProofRequest(uint256 _projectId, uint256 _milestoneIndex, bytes memory _proofDigest) public whenNotPaused {
        Project storage project = projects[_projectId];
        require(project.owner == msg.sender, "AIN: Only project owner can submit proof requests");
        require(project.status == ProjectStatus.Active, "AIN: Project is not active");
        require(_milestoneIndex < project.milestones.length, "AIN: Invalid milestone index");

        Milestone storage milestone = project.milestones[_milestoneIndex];
        require(milestone.status == MilestoneStatus.Pending, "AIN: Milestone is not in 'Pending' status");
        require(milestone.proofHash == bytes32(_proofDigest), "AIN: Provided proof digest does not match expected hash");

        milestone.status = MilestoneStatus.ProofSubmitted;
        emit MilestoneProofRequestSubmitted(_projectId, _milestoneIndex, msg.sender, _proofDigest);
    }

    /**
     * @dev Enables any user to dispute a milestone's verification status or a past verified one, requiring a bond.
     * @param _projectId The ID of the project.
     * @param _milestoneIndex The index of the milestone (0-indexed).
     * @param _reason A string explaining the reason for the challenge.
     */
    function challengeMilestoneVerification(uint256 _projectId, uint256 _milestoneIndex, string memory _reason) public payable whenNotPaused {
        Project storage project = projects[_projectId];
        require(project.status == ProjectStatus.Active, "AIN: Project is not active");
        require(_milestoneIndex < project.milestones.length, "AIN: Invalid milestone index");

        Milestone storage milestone = project.milestones[_milestoneIndex];
        // Can challenge if ProofSubmitted (pre-verification) or Verified (post-verification)
        require(milestone.status == MilestoneStatus.ProofSubmitted || milestone.status == MilestoneStatus.Verified, "AIN: Milestone not in a state to be challenged");
        require(milestone.challengeId == 0, "AIN: Milestone already has an active challenge");
        
        require(msg.value >= challengeBondAmount, "AIN: Insufficient challenge bond provided"); // Using native currency for bond
        
        uint256 currentChallengeId = nextChallengeId++;
        challenges[currentChallengeId] = Challenge({
            id: currentChallengeId,
            challenger: msg.sender,
            projectId: _projectId,
            milestoneIndex: _milestoneIndex,
            reason: _reason,
            bondAmount: msg.value, // Store actual ETH sent
            bondToken: address(0), // 0 for ETH
            status: ChallengeStatus.Open,
            initiatedAt: block.timestamp,
            isChallengerCorrect: false // Default
        });

        milestone.status = MilestoneStatus.Challenged;
        milestone.challengeId = currentChallengeId;

        emit ChallengeInitiated(currentChallengeId, msg.sender, _projectId, _milestoneIndex, _reason);
    }

    /**
     * @dev An authorized entity (e.g., challenge resolution authority) resolves a challenge, determining its outcome.
     *      Impacts challenger's bond and reputation.
     * @param _challengeId The ID of the challenge to resolve.
     * @param _isChallengerCorrect True if the challenger's claim is valid, false otherwise.
     */
    function resolveChallenge(uint256 _challengeId, bool _isChallengerCorrect) public onlyChallengeAuthority whenNotPaused {
        Challenge storage challenge = challenges[_challengeId];
        require(challenge.status == ChallengeStatus.Open, "AIN: Challenge is not open");
        
        challenge.status = _isChallengerCorrect ? ChallengeStatus.ResolvedSuccess : ChallengeStatus.ResolvedFail;
        challenge.isChallengerCorrect = _isChallengerCorrect;

        Milestone storage milestone = projects[challenge.projectId].milestones[challenge.milestoneIndex];
        milestone.challengeId = 0; // Clear challenge ID on milestone

        if (_isChallengerCorrect) {
            // Challenger was correct: Milestone state might revert, challenger gets bond back and reputation boost
            if (milestone.status == MilestoneStatus.Verified) {
                milestone.status = MilestoneStatus.ProofSubmitted; // Revert to prior state
            } else if (milestone.status == MilestoneStatus.ProofSubmitted || milestone.status == MilestoneStatus.Challenged) {
                milestone.status = MilestoneStatus.Pending; // If it was still in verification stage
            }
            
            payable(challenge.challenger).transfer(challenge.bondAmount); // Return bond
            _updateReputationOnAction(challenge.challenger, ReputationActionType.ChallengeResolvedSuccess, 75); // Example boost
            
            // Penalize project owner if their milestone claim was successfully challenged
            _updateReputationOnAction(projects[challenge.projectId].owner, ReputationActionType.ChallengeResolvedFail, -50); // Example penalty
        } else {
            // Challenger was incorrect: Challenger loses bond, and reputation penalty
            // Bond is retained by the contract (could be sent to a treasury or burned)
            // For simplicity, it stays in the contract.
            _updateReputationOnAction(challenge.challenger, ReputationActionType.ChallengeResolvedFail, -25); // Example penalty

            // Restore milestone status (if it was challenged from 'ProofSubmitted' or 'Verified')
            if (milestone.status == MilestoneStatus.Challenged) {
                // If it was challenged from ProofSubmitted, put it back to ProofSubmitted for oracle to re-verify
                // If it was challenged from Verified, put it back to Verified
                // This logic needs to know the original status. Simplification: Assume it goes back to ProofSubmitted
                milestone.status = MilestoneStatus.ProofSubmitted; 
            }
        }

        emit ChallengeResolved(_challengeId, _isChallengerCorrect, msg.sender);
    }

    /**
     * @dev Project proposer can cancel their unapproved project before voting ends.
     *      Refunds any allocated funds.
     * @param _projectId The ID of the project to cancel.
     */
    function cancelProjectProposal(uint256 _projectId) public whenNotPaused {
        Project storage project = projects[_projectId];
        require(project.owner == msg.sender, "AIN: Only project owner can cancel");
        require(project.status == ProjectStatus.Proposed, "AIN: Project is not in 'Proposed' status");
        require(block.timestamp <= project.proposalVoteEndTime, "AIN: Project voting has ended, cannot cancel");

        project.status = ProjectStatus.Cancelled;
        emit ProjectStatusChanged(_projectId, ProjectStatus.Cancelled);
        _refundProjectAllocatedFunds(_projectId);
    }

    /**
     * @dev Retrieves the current status and details of a project.
     * @param _projectId The ID of the project.
     * @return project_details Tuple containing project information.
     */
    function getProjectStatus(uint256 _projectId)
        public view
        returns (
            uint256 id,
            address owner,
            string memory name,
            string memory descriptionURI,
            uint256 totalFundingGoal,
            uint256 currentFunding,
            ProjectStatus status,
            uint256 proposalVoteEndTime,
            uint256 totalReputationVotesFor,
            uint256 totalReputationVotesAgainst,
            uint256 milestoneCount
        )
    {
        Project storage project = projects[_projectId];
        require(project.id != 0, "AIN: Project does not exist");
        return (
            project.id,
            project.owner,
            project.name,
            project.descriptionURI,
            project.totalFundingGoal,
            project.currentFunding,
            project.status,
            project.proposalVoteEndTime,
            project.totalReputationVotesFor,
            project.totalReputationVotesAgainst,
            project.milestones.length
        );
    }

    /**
     * @dev Retrieves the status and details of a specific project milestone.
     * @param _projectId The ID of the project.
     * @param _milestoneIndex The index of the milestone (0-indexed).
     * @return milestone_details Tuple containing milestone information.
     */
    function getMilestoneStatus(uint256 _projectId, uint256 _milestoneIndex)
        public view
        returns (uint256 amount, bytes32 proofHash, MilestoneStatus status, uint256 verificationTimestamp, uint256 challengeId)
    {
        Project storage project = projects[_projectId];
        require(project.id != 0, "AIN: Project does not exist");
        require(_milestoneIndex < project.milestones.length, "AIN: Invalid milestone index");

        Milestone storage milestone = project.milestones[_milestoneIndex];
        return (milestone.amount, milestone.proofHash, milestone.status, milestone.verificationTimestamp, milestone.challengeId);
    }

    // --- IV. Reputation & Participation ---

    /**
     * @dev Returns a user's current calculated ImpactScore, accounting for decay and multipliers.
     * @param _user The address of the user.
     * @return The calculated ImpactScore.
     */
    function getReputationScore(address _user) public view returns (uint256) {
        ImpactScore storage rep = impactReputation[_user];
        if (rep.score == 0) return 0;

        uint256 currentScore = rep.score;
        uint256 timeSinceLastUpdate = block.timestamp.sub(rep.lastUpdated);

        // Apply decay
        if (timeSinceLastUpdate >= REPUTATION_DECAY_PERIOD && reputationDecayRatePercentage > 0) {
            uint256 decayPeriods = timeSinceLastUpdate.div(REPUTATION_DECAY_PERIOD);
            uint256 decayedAmount = currentScore.mul(reputationDecayRatePercentage).div(100).mul(decayPeriods);
            currentScore = currentScore.sub(decayedAmount > currentScore ? currentScore : decayedAmount); // Prevent negative score
        }

        // Apply stake multiplier (example: 1.05x multiplier per 100 staked tokens)
        if (rep.stakedAmount > 0) {
            uint256 multiplierBase = 1e18; // 1.0 for fixed point math
            uint256 multiplier = multiplierBase.add(rep.stakedAmount.mul(5).div(100)); // 5% boost per staked token (adjust as needed)
            currentScore = currentScore.mul(multiplier).div(multiplierBase);
        }
        
        return currentScore;
    }

    /**
     * @dev (Internal) Updates a user's ImpactScore based on various protocol actions.
     * @param _user The address of the user whose reputation is being updated.
     * @param _actionType The type of action performed.
     * @param _delta The amount by which to change the reputation score (can be positive or negative).
     */
    function _updateReputationOnAction(address _user, uint256 _actionType, int256 _delta) internal {
        ImpactScore storage rep = impactReputation[_user];
        uint256 oldScore = rep.score;
        uint256 newScore;

        // Apply decay before update, then update lastUpdated
        uint256 currentCalculatedScore = getReputationScore(_user); // Get score with decay applied
        rep.score = currentCalculatedScore; // Set internal score to decayed value before adding delta
        rep.lastUpdated = block.timestamp;

        if (_delta > 0) {
            newScore = rep.score.add(uint256(_delta));
        } else {
            uint256 absDelta = uint256(-_delta);
            newScore = rep.score.sub(absDelta > rep.score ? rep.score : absDelta); // Prevent negative score
        }
        rep.score = newScore;
        emit ReputationUpdated(_user, newScore, oldScore, ReputationActionType(_actionType));
    }

    /**
     * @dev Users stake a specific token (e.g., a dedicated governance token or ETH) to temporarily boost their ImpactScore calculation.
     * @param _amount The amount of reputation stake token to stake.
     */
    function stakeForReputationMultiplier(uint256 _amount) public whenNotPaused {
        require(_amount > 0, "AIN: Stake amount must be positive");
        IERC20(reputationStakeToken).transferFrom(msg.sender, address(this), _amount);
        
        ImpactScore storage rep = impactReputation[msg.sender];
        rep.stakedAmount = rep.stakedAmount.add(_amount);
        rep.stakeStartTime = block.timestamp; // Reset start time to apply multiplier from this point
        
        // Refresh reputation score to apply new multiplier immediately
        _updateReputationOnAction(msg.sender, uint256(ReputationActionType.FundingContribution), 0); // Type doesn't matter, just to trigger update
        emit ReputationStaked(msg.sender, _amount);
    }

    /**
     * @dev Users unstake their tokens, removing the reputation boost.
     */
    function unstakeForReputationMultiplier() public whenNotPaused {
        ImpactScore storage rep = impactReputation[msg.sender];
        require(rep.stakedAmount > 0, "AIN: No staked amount to unstake");

        uint256 amountToUnstake = rep.stakedAmount;
        rep.stakedAmount = 0; // Clear staked amount
        rep.stakeStartTime = 0; // Clear start time

        // Refresh reputation score to remove multiplier immediately
        _updateReputationOnAction(msg.sender, uint256(ReputationActionType.FundingContribution), 0); // Type doesn't matter, just to trigger update
        IERC20(reputationStakeToken).transfer(msg.sender, amountToUnstake);
        emit ReputationUnstaked(msg.sender, amountToUnstake);
    }

    // This function is for internal calculation (e.g., for voting power), not directly settable by users.
    // getReputationScore already provides the weighted value.
    // Keeping this placeholder for clarity if a separate voting token were involved.
    function queryReputationWeightedVote(address _user, uint256 _amount) public view returns (uint256) {
        // This function would calculate actual voting power if there was a separate voting token
        // combined with reputation. For now, it just returns reputation score for simplicity.
        // If _amount represents a fixed token (e.g., 1 token = 1 vote), then it's _amount * getReputationScore(_user)
        return getReputationScore(_user);
    }


    // --- V. Oracle Integration & Advanced Concepts ---

    /**
     * @dev Callable only by the trusted oracle to notify the contract of a milestone verification outcome.
     *      Triggers fund release and reputation updates.
     * @param _projectId The ID of the project.
     * @param _milestoneIndex The index of the milestone (0-indexed).
     * @param _isVerified True if the milestone is verified, false otherwise.
     * @param _reportHash A hash of the oracle's report data.
     */
    function receiveOracleReport(uint256 _projectId, uint256 _milestoneIndex, bool _isVerified, bytes32 _reportHash) public onlyOracle whenNotPaused {
        Project storage project = projects[_projectId];
        require(project.id != 0, "AIN: Project does not exist");
        require(_milestoneIndex < project.milestones.length, "AIN: Invalid milestone index");

        Milestone storage milestone = project.milestones[_milestoneIndex];
        require(milestone.status == MilestoneStatus.ProofSubmitted, "AIN: Milestone not awaiting oracle verification");
        require(milestone.challengeId == 0, "AIN: Milestone has an active challenge, cannot be reported");
        
        milestone.status = _isVerified ? MilestoneStatus.Verified : MilestoneStatus.Pending; // If not verified, goes back to pending/needs new proof
        milestone.verificationTimestamp = block.timestamp;
        
        emit MilestoneVerified(_projectId, _milestoneIndex, _isVerified);

        if (_isVerified) {
            // Funds will be released via releaseMilestoneFunds, which can be called by anyone.
            // This decouples verification from fund transfer, allowing separate calls.
        } else {
            // Optionally, penalize project owner for failed verification
            _updateReputationOnAction(project.owner, ReputationActionType.MilestoneVerified, -20); // Example penalty
        }
    }

    /**
     * @dev Allows users to submit verifiable attestations about external activities.
     *      This is a conceptual function for future expansion, laying groundwork for
     *      a broader reputation graph or impact assessments via verifiable credentials.
     * @param _attestationId A unique ID for the attestation.
     * @param _dataHash A hash of the off-chain attestation data.
     */
    function submitAttestation(uint256 _attestationId, bytes32 _dataHash) public whenNotPaused {
        // This function is a placeholder for future complex reputation/impact systems.
        // It could involve NFTs, SBTs, or integrate with ZK-proofs for privacy-preserving attestations.
        // For now, it just records the submission.
        // Further logic would involve verifying the attestation (e.g., via a decentralized oracle
        // or a specific attestor registry) and updating reputation based on its content.
        emit ParameterUpdated(bytes32("AttestationSubmitted"), _attestationId); // Reusing event for example
    }

    /**
     * @dev Retrieves details of an ongoing or resolved challenge.
     * @param _challengeId The ID of the challenge.
     * @return challenge_details Tuple containing challenge information.
     */
    function getChallengeDetails(uint256 _challengeId)
        public view
        returns (
            uint256 id,
            address challenger,
            uint256 projectId,
            uint256 milestoneIndex,
            string memory reason,
            uint256 bondAmount,
            address bondToken,
            ChallengeStatus status,
            uint256 initiatedAt,
            bool isChallengerCorrect
        )
    {
        Challenge storage challenge = challenges[_challengeId];
        require(challenge.id != 0, "AIN: Challenge does not exist");
        return (
            challenge.id,
            challenge.challenger,
            challenge.projectId,
            challenge.milestoneIndex,
            challenge.reason,
            challenge.bondAmount,
            challenge.bondToken,
            challenge.status,
            challenge.initiatedAt,
            challenge.isChallengerCorrect
        );
    }
}

```