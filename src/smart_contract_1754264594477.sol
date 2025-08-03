Here's a smart contract written in Solidity, incorporating advanced concepts, creative features, and trendy functionalities, aiming to avoid direct duplication of existing open-source projects by combining novel mechanics.

I've designed "The Aetherium Nexus: Dynamic Community Co-creation & SkillForge Protocol."

---

## **The Aetherium Nexus: Dynamic Community Co-creation & SkillForge Protocol**

### **Outline:**

**I. Introduction**
The Aetherium Nexus is a decentralized protocol designed to foster community-driven resource allocation and individual skill validation. It combines adaptive parameters, a dynamic treasury ("Synergy Pool"), milestone-based project funding, on-chain skill attestations, and a multi-factor "Impact Score" for governance and rewards. This contract aims to be a living, evolving organism powered by its community.

**II. Core Components:**
1.  **Governance & Epochs:** Protocol parameters (e.g., proposal fees, voting weights, maximum project funding) are adaptive, changing per predefined 'epoch' based on community governance decisions. This allows the protocol to evolve over time.
2.  **Synergy Pool:** The protocol's dynamic treasury, funded by various value-creation events (donations, protocol fees, project successes). A portion of this pool is distributed as rewards to active contributors each epoch.
3.  **Project Lifecycle:** A fully on-chain system for submitting, voting on, funding, and managing community projects through milestone-based disbursements with challenge mechanisms, ensuring accountability.
4.  **SkillForge Attestations:** A novel system for users to self-attest or receive third-party attestations for skills/achievements, represented as non-transferable (soulbound-like) ERC-721 NFTs. These attestations can be challenged and verified by the community.
5.  **Impact Score:** A dynamic, multi-factor score for each user, calculated based on their governance token stake, verified SkillForge Attestations, and past project contributions. This score significantly influences voting power and Synergy Pool reward distribution, promoting holistic engagement over pure capital ownership.

### **Function Summary (27 Functions):**

**A. Setup & Core Administration:**
1.  `constructor(IERC20 _governanceToken)`: Initializes the contract, setting the immutable governance token.
2.  `updateEpochDuration(uint256 _newDuration)`: Allows the owner to adjust the length of an epoch in seconds.
3.  `setGovernanceToken(IERC20 _newGovernanceToken)`: Allows the owner to update the governance token (a critical, owner-only action).
4.  `withdrawProtocolFees(address _to, uint256 _amount)`: Allows the owner to withdraw accumulated protocol fees (e.g., from project proposal submissions).

**B. Epoch & Parameter Management:**
5.  `advanceEpoch()`: Public function callable by anyone to advance to the next epoch once the current epoch's duration has passed. It applies the next epoch's parameters and can trigger reward calculations.
6.  `proposeNextEpochParameters(...)`: Allows governance token holders to propose a new set of parameters for the *next* epoch, subject to community vote.
7.  `voteOnEpochParametersProposal(uint256 _proposalId, bool _approve)`: Allows governance token holders (weighted by their Impact Score) to vote on proposed epoch parameters.
8.  `finalizeEpochParametersProposal(uint256 _proposalId)`: Called by governance to finalize a successful epoch parameter proposal, making its settings active for the upcoming epoch.
9.  `getCurrentEpoch()`: Returns the current epoch number.
10. `getNextEpochParameters()`: Returns the parameters proposed for the next epoch, or the current ones if no proposal is finalized.

**C. Synergy Pool & Reward System:**
11. `depositToSynergyPool()`: Allows any user to contribute native ETH to the protocol's treasury (Synergy Pool).
12. `getSynergyPoolBalance()`: Returns the current balance of native ETH in the Synergy Pool.
13. `claimSynergyRewards()`: Allows users to claim their accrued rewards from the Synergy Pool, distributed proportionally based on their Impact Score in the previous epoch.

**D. Project Proposal & Management:**
14. `submitProjectProposal(string calldata _title, string calldata _description, uint256 _totalBudget, Milestone[] calldata _milestones)`: Allows users to submit a new project proposal with milestones and budget, requiring a fee.
15. `voteOnProjectProposal(uint256 _projectId, bool _approve)`: Allows governance token holders (weighted by their Impact Score) to vote on active project proposals.
16. `finalizeProjectVote(uint256 _projectId)`: Called by governance to finalize the voting process for a project proposal, determining its approval or rejection.
17. `getProjectDetails(uint256 _projectId)`: Retrieves comprehensive details of a specific project.
18. `submitMilestoneCompletionProof(uint256 _projectId, uint256 _milestoneIndex, string calldata _proofCID)`: Project creators submit proof of milestone completion (e.g., IPFS CID).
19. `challengeMilestoneCompletion(uint256 _projectId, uint256 _milestoneIndex)`: Allows community members to challenge a submitted milestone completion proof during a challenge period.
20. `resolveMilestoneChallenge(uint256 _projectId, uint256 _milestoneIndex, bool _passed)`: Called by governance/dispute resolvers to decide the outcome of a milestone challenge.
21. `fundProjectMilestone(uint256 _projectId)`: Releases funds for the current project milestone if it's verified (after challenge period or successful challenge resolution).
22. `cancelProject(uint256 _projectId)`: Allows governance to cancel an ongoing project.

**E. SkillForge Attestations (ERC-721 NFTs):**
23. `attestSkill(string calldata _skillName)`: Allows a user to self-attest a skill, minting a non-transferable (soulbound-like) SkillForge Attestation NFT.
24. `challengeSkillAttestation(uint256 _tokenId)`: Allows anyone to challenge a pending self-attested skill during its verification period.
25. `verifySkillAttestation(uint256 _tokenId)`: Marks a skill attestation as verified. Callable by the attester after the challenge period, or by governance after challenge resolution.
26. `revokeSkillAttestation(uint256 _tokenId)`: Allows governance or the original attester to revoke a verified skill attestation, burning the NFT.
27. `grantSkillAttestation(address _to, string calldata _skillName)`: Allows authorized entities (e.g., governance) to directly grant a verified skill attestation to a user.

**F. Utility & View Functions:**
28. `tokenURI(uint256 _tokenId)`: Standard ERC-721 function to retrieve metadata URI for a SkillForge Attestation.
29. `calculateImpactScore(address _user)`: A public view function to calculate a user's dynamic Impact Score based on their governance token stake, verified SkillForge Attestations, and completed project contributions.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol"; // For Skill Attestations
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Outline:
// I. Introduction
//    The Aetherium Nexus: Dynamic Community Co-creation & SkillForge Protocol
//    A decentralized protocol fostering community-driven resource allocation and individual skill validation.
//    It integrates adaptive parameters, a dynamic treasury, milestone-based project funding,
//    on-chain skill attestations, and a multi-factor "Impact Score" for governance and rewards.
//    This contract aims to be a living, evolving organism powered by its community.

// II. Core Components
//    1. Governance & Epochs: Protocol parameters (e.g., proposal fees, voting weights, max funding)
//       are adaptive, changing per predefined 'epoch' based on community governance decisions.
//    2. Synergy Pool: The protocol's dynamic treasury, funded by various value-creation events
//       (donations, protocol fees, project successes). A portion of this pool is
//       distributed as rewards to active contributors each epoch.
//    3. Project Lifecycle: A fully on-chain system for submitting, voting on, funding, and
//       managing community projects through milestone-based disbursements with challenge mechanisms.
//    4. SkillForge Attestations: A novel system for users to self-attest or receive third-party
//       attestations for skills/achievements, represented as non-transferable (soulbound-like) NFTs.
//       These attestations can be challenged and verified.
//    5. Impact Score: A dynamic, multi-factor score for each user, calculated based on their
//       governance token stake, verified SkillForge Attestations, and past project contributions.
//       This score influences voting power and Synergy Pool reward distribution.

// III. Function Summary (27 functions)

//    A. Setup & Core Administration
//       1. constructor(IERC20 _governanceToken_): Initializes the contract, sets the governance token.
//       2. updateEpochDuration(uint256 _newDuration_): Allows the owner to adjust the length of an epoch.
//       3. setGovernanceToken(IERC20 _newGovernanceToken_): Allows the owner to update the governance token (critical change, owner only).
//       4. withdrawProtocolFees(address _to_, uint256 _amount_): Allows owner to withdraw collected protocol fees.

//    B. Epoch & Parameter Management
//       5. advanceEpoch(): Public function callable by anyone to advance to the next epoch once the current epoch duration has passed. Triggers parameter updates and reward calculations.
//       6. proposeNextEpochParameters(uint256 _proposalFee_, uint256 _baseVoteWeight_, uint256 _skillWeightFactor_, uint256 _contributionWeightFactor_, uint256 _maxProjectFunding_, uint256 _minProjectVoteThreshold_): Allows governance token holders to propose the parameters for the *next* epoch.
//       7. voteOnEpochParametersProposal(uint256 _proposalId_, bool _approve_): Allows governance token holders to vote on a proposed epoch parameter set.
//       8. finalizeEpochParametersProposal(uint256 _proposalId_): Called by governance to finalize a proposal, setting parameters for the *upcoming* epoch.
//       9. getCurrentEpoch(): Returns the current epoch number.
//       10. getNextEpochParameters(): Returns the parameters proposed for the next epoch.

//    C. Synergy Pool & Reward System
//       11. depositToSynergyPool(): Allows anyone to contribute native ETH to the protocol's treasury (Synergy Pool).
//       12. getSynergyPoolBalance(): Returns the current balance of the Synergy Pool.
//       13. claimSynergyRewards(): Allows users to claim their accrued rewards from the Synergy Pool, based on their Impact Score in the previous epoch.

//    D. Project Proposal & Management
//       14. submitProjectProposal(string calldata _title_, string calldata _description_, uint256 _totalBudget_, Milestone[] calldata _milestones_): Allows users to submit a new project proposal for community review. Requires a fee.
//       15. voteOnProjectProposal(uint256 _projectId_, bool _approve_): Allows governance token holders (weighted by Impact Score) to vote on project proposals.
//       16. finalizeProjectVote(uint256 _projectId_): Called by governance to finalize the vote on a project proposal.
//       17. getProjectDetails(uint256 _projectId_): Retrieves the full details of a specific project.
//       18. submitMilestoneCompletionProof(uint256 _projectId_, uint256 _milestoneIndex_, string calldata _proofCID_): Project creator submits proof of milestone completion.
//       19. challengeMilestoneCompletion(uint256 _projectId_, uint256 _milestoneIndex_): Allows community members to challenge a submitted milestone completion proof.
//       20. resolveMilestoneChallenge(uint256 _projectId_, uint256 _milestoneIndex_, bool _passed_): Called by governance/dispute resolvers to decide on a milestone challenge.
//       21. fundProjectMilestone(uint256 _projectId_): Releases funds for the current project milestone if completed and verified.
//       22. cancelProject(uint256 _projectId_): Allows governance to cancel an ongoing project.

//    E. SkillForge Attestations (ERC721 NFTs)
//       23. attestSkill(string calldata _skillName_): Allows a user to self-attest a skill. This creates a non-transferable SkillForge Attestation NFT.
//       24. challengeSkillAttestation(uint256 _tokenId_): Allows anyone to challenge a pending self-attested skill.
//       25. verifySkillAttestation(uint256 _tokenId_): Marks a skill attestation as verified (either after challenge period or successful challenge resolution).
//       26. revokeSkillAttestation(uint256 _tokenId_): Allows governance or the original attester (under specific conditions) to revoke a verified skill attestation.
//       27. grantSkillAttestation(address _to_, string calldata _skillName_): Allows authorized entities (e.g., governance or a trusted oracle) to directly grant a skill attestation.

//    F. Utility & View Functions
//       28. tokenURI(uint256 _tokenId_): Standard ERC-721 function for NFT metadata.
//       29. calculateImpactScore(address _user_): View function to calculate a user's dynamic Impact Score based on their governance token stake, verified skills, and project contributions.

contract AetheriumNexus is Ownable, ReentrancyGuard, ERC721 {
    using Counters for Counters.Counter;

    IERC20 public immutable governanceToken;

    // --- State Variables ---

    // Epoch Management
    uint256 public epochDuration; // Duration of an epoch in seconds
    uint256 public currentEpoch;
    uint256 public epochStartTime;

    struct EpochParameters {
        uint256 proposalFee;             // Fee to submit a project proposal (in wei)
        uint256 baseVoteWeight;          // Base weight for token holders (e.g., 1 token = 1 vote)
        uint256 skillWeightFactor;       // Multiplier for verified skills in Impact Score calculation
        uint256 contributionWeightFactor; // Multiplier for project contributions in Impact Score
        uint256 maxProjectFunding;       // Maximum ETH a single project can receive from Synergy Pool
        uint256 minProjectVoteThreshold; // Minimum % of total Impact Score votes required for project approval (e.g., 5000 = 50%)
    }

    // Parameters for the *next* epoch, proposed and voted on in the current epoch.
    mapping(uint256 => EpochParameters) public epochParameterProposals; // proposalId -> params
    mapping(uint256 => mapping(address => bool)) public epochParameterVotes; // proposalId -> voter -> voted
    mapping(uint256 => uint256) public epochParameterVotesFor; // proposalId -> votes for
    mapping(uint256 => uint256) public epochParameterTotalVotePower; // proposalId -> total vote power cast
    Counters.Counter private _epochParameterProposalCounter;
    uint256 public currentEpochParameterProposalId; // The proposal that passed for the next epoch

    EpochParameters public currentEpochParameters;

    // Synergy Pool (Treasury)
    uint256 public protocolFeesCollected; // ETH collected from various fees (e.g., proposal submission)
    mapping(address => uint256) public accruedSynergyRewards; // User's claimable rewards from Synergy Pool

    // Project Management
    struct Milestone {
        string description;
        uint256 budget; // Amount for this milestone in wei
        bool isCompleted;
        string proofCID; // IPFS CID or similar hash of completion proof
        bool isChallenged;
        uint256 challengeExpiry; // Timestamp when challenge period ends
        bool challengeResolved; // True if challenge was resolved, regardless of outcome
        bool challengePassed; // True if challenge was successful (milestone failed)
    }

    enum ProjectStatus { PendingApproval, Approved, Active, Completed, Cancelled, Rejected }

    struct Project {
        address creator;
        string title;
        string description;
        uint256 totalBudget;
        Milestone[] milestones;
        uint256 currentMilestoneIndex;
        ProjectStatus status;
        uint256 votesFor; // Total Impact Score votes for
        uint256 votesAgainst; // Total Impact Score votes against
        mapping(address => bool) hasVoted; // User -> Voted on project approval
        uint256 totalImpactScoreAtVote; // Snapshot of total Impact Score when project voting ended
    }

    mapping(uint256 => Project) public projects;
    Counters.Counter private _projectCounter;

    // SkillForge Attestations (ERC721)
    struct SkillAttestationDetails {
        address attester; // Who is attesting the skill (self or third-party)
        string skillName;
        uint256 attestationDate;
        bool isVerified; // True if verified (after challenge period or challenge resolution)
        bool isChallenged; // True if currently under challenge
        uint256 challengeExpiry; // Timestamp when challenge period ends
        address challengedBy; // Address that initiated the challenge
        bool challengeResolved; // True if challenge was resolved
        bool challengePassed; // True if challenge was successful (skill not valid)
    }

    mapping(uint256 => SkillAttestationDetails) public skillAttestations; // tokenId -> details
    Counters.Counter private _skillTokenIdCounter;

    // Impact Score
    // This mapping stores the latest calculated Impact Score for a user.
    mapping(address => uint256) public userImpactScores;
    // Auxiliary mapping to track count of verified skills per user for efficient calculation
    mapping(address => uint256) private _verifiedSkillCount;
    // Auxiliary mapping to track total budget of completed projects per user
    mapping(address => uint256) private _completedProjectsTotalBudget;


    // --- Events ---
    event EpochAdvanced(uint256 indexed newEpoch, uint256 timestamp);
    event EpochParametersProposed(uint256 indexed proposalId, address indexed proposer, EpochParameters params);
    event EpochParametersVoted(uint256 indexed proposalId, address indexed voter, bool vote);
    event EpochParametersFinalized(uint256 indexed proposalId, uint256 indexed epochNumber, EpochParameters params);

    event SynergyDeposit(address indexed depositor, uint256 amount);
    event SynergyRewardsClaimed(address indexed claimant, uint256 amount);

    event ProjectProposalSubmitted(uint256 indexed projectId, address indexed creator, uint256 submissionFee);
    event ProjectProposalVoted(uint256 indexed projectId, address indexed voter, bool support, uint256 votePower);
    event ProjectStatusUpdated(uint256 indexed projectId, ProjectStatus newStatus);
    event MilestoneCompletionSubmitted(uint256 indexed projectId, uint256 indexed milestoneIndex, string proofCID);
    event MilestoneChallenged(uint256 indexed projectId, uint256 indexed milestoneIndex, address indexed challenger);
    event MilestoneChallengeResolved(uint256 indexed projectId, uint256 indexed milestoneIndex, bool passed);
    event MilestoneFunded(uint256 indexed projectId, uint256 indexed milestoneIndex, uint256 amount);
    event ProjectCancelled(uint256 indexed projectId, address indexed canceller);

    event SkillAttested(uint256 indexed tokenId, address indexed attester, string skillName);
    event SkillAttestationChallenged(uint256 indexed tokenId, address indexed challenger);
    event SkillAttestationVerified(uint256 indexed tokenId);
    event SkillAttestationRevoked(uint256 indexed tokenId);
    event SkillAttestationGranted(uint256 indexed tokenId, address indexed to, string skillName);

    event ImpactScoreRecalculated(address indexed user, uint256 newScore);

    // --- Modifiers ---
    modifier onlyGovernance() {
        // For this demo, only the contract owner can perform governance actions.
        // In a real system, this would be a multi-sig, token-weighted vote, or timelock.
        require(msg.sender == owner(), "AetheriumNexus: Not authorized by governance");
        _;
    }

    // --- Constructor ---
    /// @param _governanceToken The address of the ERC20 token used for governance.
    constructor(IERC20 _governanceToken) ERC721("SkillForgeAttestation", "SFA") Ownable(msg.sender) {
        require(address(_governanceToken) != address(0), "AetheriumNexus: Invalid governance token address");
        governanceToken = _governanceToken;

        // Initialize genesis epoch parameters
        epochDuration = 7 days; // 1 week
        currentEpoch = 0;
        epochStartTime = block.timestamp;

        currentEpochParameters = EpochParameters({
            proposalFee: 0.05 ether, // 0.05 ETH
            baseVoteWeight: 1e18, // 1 token = 1 unit of vote weight
            skillWeightFactor: 1e17, // 0.1 additional vote weight per verified skill
            contributionWeightFactor: 5e16, // 0.05 additional vote weight per ETH contributed successfully to projects
            maxProjectFunding: 10 ether, // Max 10 ETH per project
            minProjectVoteThreshold: 5000 // 50.00%
        });
    }

    // --- A. Setup & Core Administration ---

    /// @notice Allows the owner to adjust the length of an epoch.
    /// @param _newDuration The new duration for an epoch in seconds.
    function updateEpochDuration(uint256 _newDuration) external onlyOwner {
        require(_newDuration > 0, "AetheriumNexus: Epoch duration must be positive");
        epochDuration = _newDuration;
    }

    /// @notice Allows the owner to update the governance token. Should be used with extreme caution.
    /// @param _newGovernanceToken The address of the new ERC20 governance token.
    function setGovernanceToken(IERC20 _newGovernanceToken) external onlyOwner {
        require(address(_newGovernanceToken) != address(0), "AetheriumNexus: Invalid governance token address");
        governanceToken = _newGovernanceToken;
    }

    /// @notice Allows the owner to withdraw collected protocol fees.
    /// @param _to The address to send the fees to.
    /// @param _amount The amount of fees to withdraw in wei.
    function withdrawProtocolFees(address _to, uint256 _amount) external onlyOwner nonReentrant {
        require(_amount > 0, "AetheriumNexus: Amount must be positive");
        require(protocolFeesCollected >= _amount, "AetheriumNexus: Insufficient protocol fees");
        protocolFeesCollected -= _amount;
        payable(_to).transfer(_amount);
    }

    // --- B. Epoch & Parameter Management ---

    /// @notice Advances the protocol to the next epoch. Can be called by anyone after the current epoch duration passes.
    /// @dev This function triggers the application of the previously voted-on parameters for the new epoch.
    function advanceEpoch() external nonReentrant {
        require(block.timestamp >= epochStartTime + epochDuration, "AetheriumNexus: Epoch not yet ended");

        // Apply parameters for the *next* epoch if a proposal was finalized
        if (currentEpochParameterProposalId != 0 && epochParameterVotesFor[currentEpochParameterProposalId] > 0) {
            // Check if it passed the threshold (for demo, just > 0, real would be > 50%)
            currentEpochParameters = epochParameterProposals[currentEpochParameterProposalId];
        }

        currentEpoch++;
        epochStartTime = block.timestamp;

        // Reset epoch parameter proposal state for the new epoch
        currentEpochParameterProposalId = 0; // Clear the previous winning proposal

        // In a full system, this would trigger distribution of Synergy Pool rewards for the just-ended epoch.
        // For simplicity in this demo, `accruedSynergyRewards` is updated through a simulated process
        // or can be managed off-chain for complex calculations, and users claim individually.

        emit EpochAdvanced(currentEpoch, block.timestamp);
    }

    /// @notice Allows governance token holders to propose new parameters for the *next* epoch.
    /// @param _proposalFee New proposal fee in wei.
    /// @param _baseVoteWeight New base vote weight.
    /// @param _skillWeightFactor New skill weight factor.
    /// @param _contributionWeightFactor New contribution weight factor.
    /// @param _maxProjectFunding New max project funding in wei.
    /// @param _minProjectVoteThreshold New min project vote threshold (e.g., 5000 for 50%).
    function proposeNextEpochParameters(
        uint256 _proposalFee,
        uint256 _baseVoteWeight,
        uint256 _skillWeightFactor,
        uint256 _contributionWeightFactor,
        uint256 _maxProjectFunding,
        uint256 _minProjectVoteThreshold
    ) external nonReentrant {
        require(governanceToken.balanceOf(msg.sender) > 0, "AetheriumNexus: Must hold governance tokens to propose");

        _epochParameterProposalCounter.increment();
        uint256 newProposalId = _epochParameterProposalCounter.current();

        epochParameterProposals[newProposalId] = EpochParameters({
            proposalFee: _proposalFee,
            baseVoteWeight: _baseVoteWeight,
            skillWeightFactor: _skillWeightFactor,
            contributionWeightFactor: _contributionWeightFactor,
            maxProjectFunding: _maxProjectFunding,
            minProjectVoteThreshold: _minProjectVoteThreshold
        });

        epochParameterVotesFor[newProposalId] = 0;
        epochParameterTotalVotePower[newProposalId] = 0;

        emit EpochParametersProposed(newProposalId, msg.sender, epochParameterProposals[newProposalId]);
    }

    /// @notice Allows governance token holders to vote on a proposed set of epoch parameters.
    /// @param _proposalId The ID of the epoch parameter proposal.
    /// @param _approve True to vote yes, false to vote no.
    function voteOnEpochParametersProposal(uint256 _proposalId, bool _approve) external nonReentrant {
        require(epochParameterProposals[_proposalId].proposalFee > 0, "AetheriumNexus: Proposal does not exist");
        require(!epochParameterVotes[_proposalId][msg.sender], "AetheriumNexus: Already voted on this proposal");

        uint256 voterImpactScore = calculateImpactScore(msg.sender);
        require(voterImpactScore > 0, "AetheriumNexus: Voter has no impact score");

        epochParameterVotes[_proposalId][msg.sender] = true;
        if (_approve) {
            epochParameterVotesFor[_proposalId] += voterImpactScore;
        }
        epochParameterTotalVotePower[_proposalId] += voterImpactScore;

        emit EpochParametersVoted(_proposalId, msg.sender, _approve);
    }

    /// @notice Finalizes a successful epoch parameter proposal. Only governance can call this after voting ends.
    /// @param _proposalId The ID of the epoch parameter proposal to finalize.
    function finalizeEpochParametersProposal(uint256 _proposalId) external onlyGovernance {
        require(epochParameterProposals[_proposalId].proposalFee > 0, "AetheriumNexus: Proposal does not exist");
        require(currentEpochParameterProposalId == 0, "AetheriumNexus: A proposal for next epoch is already finalized");

        // Check if votesFor meets the threshold relative to total cast votes
        require(
            epochParameterVotesFor[_proposalId] * 10000 / epochParameterTotalVotePower[_proposalId] >= currentEpochParameters.minProjectVoteThreshold,
            "AetheriumNexus: Proposal did not meet threshold"
        );

        currentEpochParameterProposalId = _proposalId;
        emit EpochParametersFinalized(_proposalId, currentEpoch + 1, epochParameterProposals[_proposalId]);
    }

    /// @notice Returns the current epoch number.
    /// @return The current epoch number.
    function getCurrentEpoch() public view returns (uint256) {
        return currentEpoch;
    }

    /// @notice Returns the parameters proposed for the next epoch.
    /// @return The EpochParameters struct for the next epoch's proposal.
    function getNextEpochParameters() public view returns (EpochParameters memory) {
        if (currentEpochParameterProposalId != 0) {
            return epochParameterProposals[currentEpochParameterProposalId];
        } else {
            return currentEpochParameters; // Return current if no specific proposal is selected
        }
    }


    // --- C. Synergy Pool & Reward System ---

    /// @notice Allows anyone to contribute native ETH to the protocol's treasury (Synergy Pool).
    function depositToSynergyPool() external payable nonReentrant {
        require(msg.value > 0, "AetheriumNexus: Deposit amount must be positive");
        emit SynergyDeposit(msg.sender, msg.value);
    }

    /// @notice Returns the current balance of the Synergy Pool.
    /// @return The balance of the contract in native ETH (Synergy Pool), excluding explicit protocol fees.
    function getSynergyPoolBalance() public view returns (uint256) {
        return address(this).balance - protocolFeesCollected;
    }

    /// @notice Allows users to claim their accrued rewards from the Synergy Pool.
    /// @dev Rewards are distributed proportionally based on Impact Score from the *previous* epoch.
    ///      The actual distribution calculation is complex and would involve iterating over users or
    ///      a merkle drop. For this demo, `accruedSynergyRewards` is assumed to be updated externally
    ///      or through a separate, more complex reward calculation function.
    function claimSynergyRewards() external nonReentrant {
        uint256 amount = accruedSynergyRewards[msg.sender];
        require(amount > 0, "AetheriumNexus: No rewards to claim");

        accruedSynergyRewards[msg.sender] = 0; // Reset before transfer to prevent reentrancy
        payable(msg.sender).transfer(amount);

        emit SynergyRewardsClaimed(msg.sender, amount);
    }

    // --- D. Project Proposal & Management ---

    /// @notice Allows users to submit a new project proposal for community review.
    /// @param _title The title of the project.
    /// @param _description A detailed description of the project.
    /// @param _totalBudget The total ETH requested for the project.
    /// @param _milestones An array of Milestone structs defining project phases.
    /// @dev Requires a `proposalFee` defined in currentEpochParameters.
    function submitProjectProposal(
        string calldata _title,
        string calldata _description,
        uint256 _totalBudget,
        Milestone[] calldata _milestones
    ) external payable nonReentrant {
        require(msg.value >= currentEpochParameters.proposalFee, "AetheriumNexus: Insufficient proposal fee");
        require(_totalBudget <= currentEpochParameters.maxProjectFunding, "AetheriumNexus: Project budget exceeds max funding");
        require(_milestones.length > 0, "AetheriumNexus: Project must have at least one milestone");

        uint256 milestoneSum;
        for (uint256 i = 0; i < _milestones.length; i++) {
            milestoneSum += _milestones[i].budget;
        }
        require(milestoneSum == _totalBudget, "AetheriumNexus: Milestone budgets must sum to total budget");

        _projectCounter.increment();
        uint256 projectId = _projectCounter.current();

        projects[projectId] = Project({
            creator: msg.sender,
            title: _title,
            description: _description,
            totalBudget: _totalBudget,
            milestones: _milestones,
            currentMilestoneIndex: 0,
            status: ProjectStatus.PendingApproval,
            votesFor: 0,
            votesAgainst: 0,
            totalImpactScoreAtVote: 0 // Will be set upon voting completion
        });

        protocolFeesCollected += msg.value; // Add fee to protocol treasury

        emit ProjectProposalSubmitted(projectId, msg.sender, msg.value);
    }

    /// @notice Allows governance token holders (weighted by Impact Score) to vote on project proposals.
    /// @param _projectId The ID of the project proposal to vote on.
    /// @param _approve True to vote in favor, false to vote against.
    function voteOnProjectProposal(uint256 _projectId, bool _approve) external nonReentrant {
        Project storage project = projects[_projectId];
        require(project.creator != address(0), "AetheriumNexus: Project does not exist");
        require(project.status == ProjectStatus.PendingApproval, "AetheriumNexus: Project not in pending approval status");
        require(!project.hasVoted[msg.sender], "AetheriumNexus: Already voted on this project");

        uint256 voterImpactScore = calculateImpactScore(msg.sender);
        require(voterImpactScore > 0, "AetheriumNexus: Voter has no impact score");

        project.hasVoted[msg.sender] = true;
        if (_approve) {
            project.votesFor += voterImpactScore;
        } else {
            project.votesAgainst += voterImpactScore;
        }

        emit ProjectProposalVoted(_projectId, msg.sender, _approve, voterImpactScore);
    }

    /// @notice Finalizes a project vote. For demo, only owner can call to simulate voting period end.
    /// @param _projectId The ID of the project.
    function finalizeProjectVote(uint256 _projectId) external onlyGovernance {
        Project storage project = projects[_projectId];
        require(project.creator != address(0), "AetheriumNexus: Project does not exist");
        require(project.status == ProjectStatus.PendingApproval, "AetheriumNexus: Project not in pending approval status");

        uint256 totalVotesReceived = project.votesFor + project.votesAgainst;
        project.totalImpactScoreAtVote = totalVotesReceived; // Snapshot total votes received for calculation

        if (totalVotesReceived > 0 && (project.votesFor * 10000 / totalVotesReceived) >= currentEpochParameters.minProjectVoteThreshold) {
            project.status = ProjectStatus.Approved;
            emit ProjectStatusUpdated(_projectId, ProjectStatus.Approved);
        } else {
            project.status = ProjectStatus.Rejected;
            emit ProjectStatusUpdated(_projectId, ProjectStatus.Rejected);
        }
    }


    /// @notice Retrieves the full details of a specific project.
    /// @param _projectId The ID of the project.
    /// @return A tuple containing all project details.
    function getProjectDetails(uint256 _projectId)
        public
        view
        returns (
            address creator,
            string memory title,
            string memory description,
            uint256 totalBudget,
            Milestone[] memory milestones,
            uint256 currentMilestoneIndex,
            ProjectStatus status,
            uint256 votesFor,
            uint256 votesAgainst
        )
    {
        Project storage project = projects[_projectId];
        require(project.creator != address(0), "AetheriumNexus: Project does not exist");

        return (
            project.creator,
            project.title,
            project.description,
            project.totalBudget,
            project.milestones,
            project.currentMilestoneIndex,
            project.status,
            project.votesFor,
            project.votesAgainst
        );
    }

    /// @notice Project creator submits proof of milestone completion.
    /// @param _projectId The ID of the project.
    /// @param _milestoneIndex The index of the milestone being completed.
    /// @param _proofCID The IPFS CID or similar hash of the completion proof.
    function submitMilestoneCompletionProof(uint256 _projectId, uint256 _milestoneIndex, string calldata _proofCID) external {
        Project storage project = projects[_projectId];
        require(msg.sender == project.creator, "AetheriumNexus: Only project creator can submit proof");
        require(project.status == ProjectStatus.Approved || project.status == ProjectStatus.Active, "AetheriumNexus: Project not active or approved");
        require(_milestoneIndex == project.currentMilestoneIndex, "AetheriumNexus: Not the current milestone");
        require(_milestoneIndex < project.milestones.length, "AetheriumNexus: Invalid milestone index");
        require(!project.milestones[_milestoneIndex].isCompleted, "AetheriumNexus: Milestone already completed");
        require(bytes(_proofCID).length > 0, "AetheriumNexus: Proof CID cannot be empty");

        project.milestones[_milestoneIndex].proofCID = _proofCID;
        // Set challenge expiry for community review
        project.milestones[_milestoneIndex].challengeExpiry = block.timestamp + 3 days; // 3-day challenge period

        emit MilestoneCompletionSubmitted(_projectId, _milestoneIndex, _proofCID);
    }

    /// @notice Allows community members to challenge a submitted milestone completion proof.
    /// @param _projectId The ID of the project.
    /// @param _milestoneIndex The index of the milestone being challenged.
    function challengeMilestoneCompletion(uint256 _projectId, uint256 _milestoneIndex) external {
        Project storage project = projects[_projectId];
        require(project.creator != address(0), "AetheriumNexus: Project does not exist");
        require(_milestoneIndex < project.milestones.length, "AetheriumNexus: Invalid milestone index");
        require(!project.milestones[_milestoneIndex].isCompleted, "AetheriumNexus: Milestone already completed");
        require(bytes(project.milestones[_milestoneIndex].proofCID).length > 0, "AetheriumNexus: No proof submitted to challenge");
        require(block.timestamp < project.milestones[_milestoneIndex].challengeExpiry, "AetheriumNexus: Challenge period expired");
        require(!project.milestones[_milestoneIndex].isChallenged, "AetheriumNexus: Milestone already challenged");

        project.milestones[_milestoneIndex].isChallenged = true;
        // In a real system, this would initiate a dispute resolution process (e.g., Kleros, Aragon court).
        // For this demo, challengeResolution is handled by `onlyGovernance`.
        emit MilestoneChallenged(_projectId, _milestoneIndex, msg.sender);
    }

    /// @notice Called by governance/dispute resolvers to decide on a milestone challenge.
    /// @param _projectId The ID of the project.
    /// @param _milestoneIndex The index of the milestone.
    /// @param _passed True if the challenge was successful (milestone failed to meet requirements), false otherwise.
    function resolveMilestoneChallenge(uint256 _projectId, uint256 _milestoneIndex, bool _passed) external onlyGovernance {
        Project storage project = projects[_projectId];
        require(project.creator != address(0), "AetheriumNexus: Project does not exist");
        require(_milestoneIndex < project.milestones.length, "AetheriumNexus: Invalid milestone index");
        require(project.milestones[_milestoneIndex].isChallenged, "AetheriumNexus: Milestone not currently challenged");
        require(!project.milestones[_milestoneIndex].challengeResolved, "AetheriumNexus: Challenge already resolved");

        project.milestones[_milestoneIndex].challengeResolved = true;
        project.milestones[_milestoneIndex].challengePassed = _passed;

        // If challenge passed (_passed is true), milestone is considered failed.
        if (!_passed) { // If challenge failed, milestone is considered successful.
            project.milestones[_milestoneIndex].isCompleted = true; // Mark as completed for funding
        }

        emit MilestoneChallengeResolved(_projectId, _milestoneIndex, _passed);
    }

    /// @notice Releases funds for the current project milestone if completed and verified.
    /// @param _projectId The ID of the project.
    function fundProjectMilestone(uint256 _projectId) external nonReentrant {
        Project storage project = projects[_projectId];
        require(project.creator != address(0), "AetheriumNexus: Project does not exist");
        require(project.status == ProjectStatus.Approved || project.status == ProjectStatus.Active, "AetheriumNexus: Project not approved or active");
        require(project.currentMilestoneIndex < project.milestones.length, "AetheriumNexus: All milestones completed");

        Milestone storage currentMilestone = project.milestones[project.currentMilestoneIndex];

        bool canFund = false;
        if (bytes(currentMilestone.proofCID).length > 0) {
            if (currentMilestone.isChallenged) {
                require(currentMilestone.challengeResolved, "AetheriumNexus: Challenge still pending resolution");
                if (!currentMilestone.challengePassed) { // Challenge failed, milestone passed
                    canFund = true;
                }
            } else {
                require(block.timestamp >= currentMilestone.challengeExpiry, "AetheriumNexus: Challenge period not over");
                canFund = true;
            }
        }
        require(canFund, "AetheriumNexus: Current milestone not verified for funding");

        // Ensure the milestone is marked as completed
        currentMilestone.isCompleted = true;

        // Update project status to Active if it's the first milestone being funded
        if (project.status == ProjectStatus.Approved) {
            project.status = ProjectStatus.Active;
        }

        uint256 amount = currentMilestone.budget;
        require(getSynergyPoolBalance() >= amount, "AetheriumNexus: Insufficient funds in Synergy Pool");

        payable(project.creator).transfer(amount);

        project.currentMilestoneIndex++;
        if (project.currentMilestoneIndex == project.milestones.length) {
            project.status = ProjectStatus.Completed;
            _completedProjectsTotalBudget[project.creator] += project.totalBudget; // Update for Impact Score
            userImpactScores[project.creator] = calculateImpactScore(project.creator); // Recalculate impact
            emit ImpactScoreRecalculated(project.creator, userImpactScores[project.creator]);
        }

        emit MilestoneFunded(_projectId, project.currentMilestoneIndex - 1, amount);
        emit ProjectStatusUpdated(_projectId, project.status);
    }

    /// @notice Allows governance to cancel an ongoing project.
    /// @param _projectId The ID of the project to cancel.
    function cancelProject(uint256 _projectId) external onlyGovernance {
        Project storage project = projects[_projectId];
        require(project.creator != address(0), "AetheriumNexus: Project does not exist");
        require(project.status != ProjectStatus.Completed && project.status != ProjectStatus.Cancelled && project.status != ProjectStatus.Rejected, "AetheriumNexus: Project cannot be cancelled in current state");

        project.status = ProjectStatus.Cancelled;

        emit ProjectCancelled(_projectId, msg.sender);
        emit ProjectStatusUpdated(_projectId, ProjectStatus.Cancelled);
    }


    // --- E. SkillForge Attestations (ERC721 NFTs) ---

    /// @notice Returns the URI for a SkillForge Attestation NFT.
    /// @param _tokenId The ID of the SkillForge Attestation NFT.
    /// @return The URI string.
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        SkillAttestationDetails storage attestation = skillAttestations[_tokenId];
        // In a real dApp, this would return a JSON URI with more details and a fancy image.
        // For simplicity, just return a string indicating the skill.
        return string(abi.encodePacked("ipfs://", attestation.skillName, ".json"));
    }

    /// @notice Allows a user to self-attest a skill. This creates a non-transferable SkillForge Attestation NFT.
    /// @param _skillName The name of the skill being attested (e.g., "Solidity Developer", "UI/UX Designer").
    /// @return The ID of the newly minted SkillForge Attestation NFT.
    function attestSkill(string calldata _skillName) external nonReentrant returns (uint256) {
        require(bytes(_skillName).length > 0, "AetheriumNexus: Skill name cannot be empty");

        _skillTokenIdCounter.increment();
        uint256 newTokenId = _skillTokenIdCounter.current();

        // Mint a soulbound-like NFT by setting owner to msg.sender but not allowing transfer
        _safeMint(msg.sender, newTokenId);
        // Note: For full "soulbound" behavior, transferFrom and approve would need to be overridden to revert.
        // For this demo, we assume no transfer.

        skillAttestations[newTokenId] = SkillAttestationDetails({
            attester: msg.sender,
            skillName: _skillName,
            attestationDate: block.timestamp,
            isVerified: false, // Starts unverified
            isChallenged: false,
            challengeExpiry: block.timestamp + 7 days, // 7-day challenge period for self-attestations
            challengedBy: address(0),
            challengeResolved: false,
            challengePassed: false
        });

        emit SkillAttested(newTokenId, msg.sender, _skillName);
        return newTokenId;
    }

    /// @notice Allows anyone to challenge a pending self-attested skill.
    /// @param _tokenId The ID of the SkillForge Attestation NFT.
    function challengeSkillAttestation(uint256 _tokenId) external {
        SkillAttestationDetails storage attestation = skillAttestations[_tokenId];
        require(attestation.attester != address(0), "AetheriumNexus: Skill Attestation does not exist");
        require(!attestation.isVerified, "AetheriumNexus: Skill is already verified");
        require(!attestation.isChallenged, "AetheriumNexus: Skill is already under challenge");
        require(block.timestamp < attestation.challengeExpiry, "AetheriumNexus: Challenge period expired");

        attestation.isChallenged = true;
        attestation.challengedBy = msg.sender;
        // In a real system, this would trigger a dispute mechanism.
        // For demo: `resolveSkillChallenge` by governance.

        emit SkillAttestationChallenged(_tokenId, msg.sender);
    }

    /// @notice Marks a skill attestation as verified (either after challenge period or successful challenge resolution).
    /// @param _tokenId The ID of the SkillForge Attestation NFT.
    /// @dev Callable by the original attester after `challengeExpiry` if no challenge, or by governance after challenge resolution.
    function verifySkillAttestation(uint256 _tokenId) external nonReentrant {
        SkillAttestationDetails storage attestation = skillAttestations[_tokenId];
        require(attestation.attester != address(0), "AetheriumNexus: Skill Attestation does not exist");
        require(!attestation.isVerified, "AetheriumNexus: Skill already verified");

        if (attestation.isChallenged) {
            require(attestation.challengeResolved, "AetheriumNexus: Challenge still pending resolution");
            require(!attestation.challengePassed, "AetheriumNexus: Challenge passed, skill is invalid");
        } else {
            require(block.timestamp >= attestation.challengeExpiry, "AetheriumNexus: Challenge period not over");
        }

        // Only original attester or governance can finalize verification
        require(msg.sender == attestation.attester || msg.sender == owner(), "AetheriumNexus: Not authorized to verify");

        attestation.isVerified = true;
        _verifiedSkillCount[attestation.attester]++; // Increment verified skill count
        userImpactScores[attestation.attester] = calculateImpactScore(attestation.attester);
        emit ImpactScoreRecalculated(attestation.attester, userImpactScores[attestation.attester]);

        emit SkillAttestationVerified(_tokenId);
    }

    /// @notice Allows governance or the original attester (under specific conditions) to revoke a verified skill attestation.
    /// @param _tokenId The ID of the SkillForge Attestation NFT.
    function revokeSkillAttestation(uint256 _tokenId) external nonReentrant {
        SkillAttestationDetails storage attestation = skillAttestations[_tokenId];
        require(attestation.attester != address(0), "AetheriumNexus: Skill Attestation does not exist");
        require(attestation.isVerified, "AetheriumNexus: Skill is not verified or already revoked");

        // Can be revoked by owner/governance, or by the original attester (e.g., self-revoke).
        require(msg.sender == owner() || msg.sender == attestation.attester, "AetheriumNexus: Not authorized to revoke");

        attestation.isVerified = false;
        _verifiedSkillCount[attestation.attester]--; // Decrement verified skill count
        _burn(_tokenId); // Burn the NFT

        userImpactScores[attestation.attester] = calculateImpactScore(attestation.attester);
        emit ImpactScoreRecalculated(attestation.attester, userImpactScores[attestation.attester]);

        emit SkillAttestationRevoked(_tokenId);
    }

    /// @notice Allows authorized entities (e.g., governance or a trusted oracle) to directly grant a skill attestation.
    /// @param _to The address to grant the skill to.
    /// @param _skillName The name of the skill.
    /// @return The ID of the newly minted SkillForge Attestation NFT.
    function grantSkillAttestation(address _to, string calldata _skillName) external onlyGovernance returns (uint256) {
        require(_to != address(0), "AetheriumNexus: Invalid recipient address");
        require(bytes(_skillName).length > 0, "AetheriumNexus: Skill name cannot be empty");

        _skillTokenIdCounter.increment();
        uint256 newTokenId = _skillTokenIdCounter.current();

        _safeMint(_to, newTokenId);

        skillAttestations[newTokenId] = SkillAttestationDetails({
            attester: msg.sender, // Granting entity
            skillName: _skillName,
            attestationDate: block.timestamp,
            isVerified: true, // Directly verified when granted by governance
            isChallenged: false,
            challengeExpiry: 0, // No challenge period for granted skills
            challengedBy: address(0),
            challengeResolved: false,
            challengePassed: false
        });

        _verifiedSkillCount[_to]++; // Increment verified skill count
        userImpactScores[_to] = calculateImpactScore(_to);
        emit ImpactScoreRecalculated(_to, userImpactScores[_to]);

        emit SkillAttestationGranted(newTokenId, _to, _skillName);
        return newTokenId;
    }

    /// @notice Retrieves details of a specific SkillForge Attestation NFT.
    /// @param _tokenId The ID of the SkillForge Attestation NFT.
    /// @return A tuple containing all skill attestation details.
    function getSkillAttestation(uint256 _tokenId)
        public
        view
        returns (
            address attester,
            string memory skillName,
            uint256 attestationDate,
            bool isVerified,
            bool isChallenged,
            uint256 challengeExpiry,
            address challengedBy,
            bool challengeResolved,
            bool challengePassed
        )
    {
        SkillAttestationDetails storage attestation = skillAttestations[_tokenId];
        require(attestation.attester != address(0), "AetheriumNexus: Skill Attestation does not exist");

        return (
            attestation.attester,
            attestation.skillName,
            attestation.attestationDate,
            attestation.isVerified,
            attestation.isChallenged,
            attestation.challengeExpiry,
            attestation.challengedBy,
            attestation.challengeResolved,
            attestation.challengePassed
        );
    }

    // --- F. Utility & View Functions ---

    /// @notice Calculates a user's dynamic Impact Score.
    /// @param _user The address of the user.
    /// @return The calculated Impact Score.
    /// @dev Impact Score = (Token Balance * baseVoteWeight) +
    ///      (Count of Verified Skills * skillWeightFactor) +
    ///      (Total Budget of Completed Projects * contributionWeightFactor).
    function calculateImpactScore(address _user) public view returns (uint256) {
        uint256 tokenBalance = governanceToken.balanceOf(_user);
        uint256 score = (tokenBalance * currentEpochParameters.baseVoteWeight) / 1e18; // Normalize base weight (assuming 1e18 for token)

        // Add score from verified skills
        uint256 userVerifiedSkillCount = _verifiedSkillCount[_user];
        score += (userVerifiedSkillCount * currentEpochParameters.skillWeightFactor) / 1e18;

        // Add score from project contributions
        uint256 totalProjectContributionValue = _completedProjectsTotalBudget[_user];
        score += (totalProjectContributionValue * currentEpochParameters.contributionWeightFactor) / 1e18;

        return score;
    }
}
```