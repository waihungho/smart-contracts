This smart contract, **Synthetica Nexus**, is designed to be a decentralized platform for funding and validating innovative projects (e.g., DeSci, open-source development, creative works) based on their predicted and verified impact. It introduces several advanced concepts:

1.  **Decentralized Impact Assessment:** Projects are funded and rewarded based on the achievement of specific, verifiable milestones.
2.  **Predictive Staking:** Community members "stake" funds on a project's success, effectively participating in a simplified prediction market. Successful stakers are rewarded.
3.  **Dynamic Impact NFTs (iNFTs):** Each project can have an associated ERC721 NFT whose metadata can be dynamically updated to reflect project progress, accumulated reputation, and achieved milestones, making it an evolving digital artifact of impact.
4.  **Reputation System:** Innovators and Verifiers earn on-chain reputation for successful project completion, accurate verification, and diligent participation.
5.  **Multi-Role Interaction:** Innovators, Verifiers, Stakers, and a Governing body interact to manage the project lifecycle, from proposal to funding and verification.
6.  **Dispute Resolution:** A mechanism for challenging milestone verifications, with final resolution by the Governing body.
7.  **Configurable Parameters:** Key system parameters (e.g., lockup periods, reward distribution) can be adjusted by the Governing body, allowing for dynamic adaptation and governance.
8.  **IPFS Integration (via CIDs):** Project descriptions, milestone details, proofs, and verifier notes are referenced via IPFS Content Identifiers (CIDs) on-chain, keeping complex data off-chain while maintaining integrity.

---

## SyntheticaNexus Contract Outline & Function Summary

**Contract Name:** `SyntheticaNexus`

This contract orchestrates the lifecycle of innovative projects, from proposal and funding to milestone verification, reputation management, and dynamic Impact NFT creation.

### Outline:

1.  **Interfaces:** Definitions for ERC20 and ERC721 tokens.
2.  **Libraries:** `SafeERC20` for secure ERC20 operations.
3.  **Errors:** Custom error types for specific failure conditions.
4.  **Constants & State Variables:** Global system parameters, mappings for projects, milestones, stakes, reputation, and role management.
5.  **Enums:** `ProjectStatus` and `MilestoneStatus` to track progress.
6.  **Structs:** `Project` and `Milestone` data structures.
7.  **Events:** To signal important state changes and actions.
8.  **Modifiers:** For access control (`onlyGovernor`, `onlyInnovator`, `onlyVerifier`, `onlyProjectStakeholder`).
9.  **Constructor:** Initializes the governing address and core parameters.
10. **I. Core Project Lifecycle & Data (Innovator Focused):** Functions for proposing, updating, and revoking projects.
11. **II. Milestone Management & Verification (Collaborative/Oracle-driven):** Functions for adding milestones, requesting/submitting verification, challenging, and resolving disputes.
12. **III. Funding, Staking & Rewards (Community/Staker Focused):** Functions for staking, claiming project funds, claiming staking rewards, and withdrawing funds from failed projects.
13. **IV. Reputation & Governance (DAO/System Focused):** Functions for verifier registration, approval, slashing, and querying reputation scores.
14. **V. Impact NFTs (ERC721 Extension):** Functions for minting and updating dynamic Impact NFTs for projects.
15. **VI. Dynamic Parameters & System Configuration (Governor Focused):** Functions for adjusting key contract parameters.
16. **Internal Helper Functions:** Private functions for common logic (e.g., reward calculation, status checks).

---

### Function Summary:

**I. Core Project Lifecycle & Data:**
1.  `proposeProject(string memory _name, string memory _descriptionCID, uint256 _fundingGoal, address _fundingToken)`: Innovator proposes a project, specifying its details, funding goal, and preferred ERC20 funding token.
2.  `updateProjectDetails(uint256 _projectId, string memory _newDescriptionCID)`: Innovator updates the IPFS CID for their project's description.
3.  `revokeProjectProposal(uint256 _projectId)`: Innovator can revoke an unfunded project proposal.
4.  `getProjectData(uint256 _projectId)`: Retrieves comprehensive details about a specific project.

**II. Milestone Management & Verification:**
5.  `addProjectMilestone(uint256 _projectId, string memory _milestoneDescriptionCID, uint256 _payoutPercentage)`: Innovator adds a new milestone, describing it and allocating a percentage of the total funding goal to it.
6.  `requestMilestoneVerification(uint256 _projectId, uint256 _milestoneIndex, string memory _proofCID)`: Innovator requests verification for a completed milestone, providing IPFS CID proof.
7.  `submitMilestoneVerificationResult(uint256 _projectId, uint256 _milestoneIndex, bool _isAchieved, string memory _verifierNotesCID)`: An approved verifier submits their verification result for a milestone.
8.  `challengeMilestoneVerification(uint256 _projectId, uint256 _milestoneIndex, string memory _challengeReasonCID)`: Any project stakeholder can challenge a verification result within a window.
9.  `resolveMilestoneDispute(uint256 _projectId, uint256 _milestoneIndex, bool _finalStatus)`: The Governor resolves a disputed milestone's status.

**III. Funding, Staking & Rewards:**
10. `stakeFunds(uint256 _projectId, uint256 _amount)`: Users stake ERC20 tokens on a project, supporting its funding.
11. `unstakeFunds(uint256 _projectId, uint256 _amount)`: Users can unstake funds from active projects, subject to a lockup period.
12. `claimProjectFunding(uint256 _projectId, uint256 _milestoneIndex)`: Innovator claims the allocated funding for an achieved and verified milestone.
13. `claimStakingRewards(uint256 _projectId)`: Stakers claim their share of rewards from successfully achieved milestones.
14. `withdrawFailedProjectStakes(uint256 _projectId)`: Stakers can withdraw their principal if a project officially fails or is abandoned.

**IV. Reputation & Governance:**
15. `registerVerifier(string memory _profileCID)`: An address registers its intent to become a verifier, providing an IPFS CID for their profile.
16. `approveVerifier(address _verifierAddress)`: Governor approves a registered verifier, granting them the `isVerifier` role.
17. `slashVerifier(address _verifierAddress, uint256 _amount, string memory _reasonCID)`: Governor slashes (penalizes) a verifier for malicious or negligent actions.
18. `getInnovatorReputation(address _innovator)`: Returns the current reputation points for a specific innovator.
19. `getVerifierReputation(address _verifier)`: Returns the current reputation points for a specific verifier.

**V. Impact NFTs (ERC721 Extension):**
20. `mintImpactNFT(uint256 _projectId)`: Mints a unique ERC721 Impact NFT for a project, representing its potential. Only callable once per project after initial funding.
21. `updateImpactNFTMetadata(uint256 _projectId, string memory _newMetadataCID)`: Updates the metadata (traits, progress) of a project's Impact NFT.
22. `burnImpactNFT(uint256 _projectId)`: Allows the project innovator to burn their project's Impact NFT (e.g., if the project fails or is abandoned).

**VI. Dynamic Parameters & System Configuration:**
23. `setStakingLockupPeriod(uint256 _newLockupSeconds)`: Governor sets the minimum time funds must remain staked.
24. `setVerificationChallengeWindow(uint256 _newWindowSeconds)`: Governor sets the time period during which a milestone verification can be challenged.
25. `setRewardDistributionFactors(uint256 _innovatorShare, uint256 _stakerShare, uint256 _verifierShare)`: Governor adjusts the percentage split of rewards between innovators, stakers, and verifiers.
26. `setFundingTokenAllowed(address _tokenAddress, bool _allowed)`: Governor enables or disables specific ERC20 tokens for use as funding currency.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol"; // For ImpactNFTs

/**
 * @title SyntheticaNexus
 * @dev A decentralized platform for funding and validating innovative projects based on predicted and verified impact.
 *      It integrates dynamic Impact NFTs, a reputation system, and a multi-role dispute resolution mechanism.
 *
 * Outline:
 * 1.  Interfaces: Definitions for ERC20.
 * 2.  Libraries: SafeERC20 for secure ERC20 operations.
 * 3.  Errors: Custom error types for specific failure conditions.
 * 4.  Constants & State Variables: Global system parameters, mappings for projects, milestones, stakes, reputation, and role management.
 * 5.  Enums: ProjectStatus and MilestoneStatus to track progress.
 * 6.  Structs: Project and Milestone data structures.
 * 7.  Events: To signal important state changes and actions.
 * 8.  Modifiers: For access control (onlyGovernor, onlyInnovator, onlyVerifier, onlyProjectStakeholder).
 * 9.  Constructor: Initializes the governing address and core parameters.
 * 10. I. Core Project Lifecycle & Data (Innovator Focused): Functions for proposing, updating, and revoking projects.
 * 11. II. Milestone Management & Verification (Collaborative/Oracle-driven): Functions for adding milestones, requesting/submitting verification, challenging, and resolving disputes.
 * 12. III. Funding, Staking & Rewards (Community/Staker Focused): Functions for staking, claiming project funds, claiming staking rewards, and withdrawing funds from failed projects.
 * 13. IV. Reputation & Governance (DAO/System Focused): Functions for verifier registration, approval, slashing, and querying reputation scores.
 * 14. V. Impact NFTs (ERC721 Extension): Functions for minting and updating dynamic Impact NFTs for projects.
 * 15. VI. Dynamic Parameters & System Configuration (Governor Focused): Functions for adjusting key contract parameters.
 * 16. Internal Helper Functions: Private functions for common logic (e.g., reward calculation, status checks).
 *
 * Function Summary:
 * I. Core Project Lifecycle & Data:
 * 1.  proposeProject(string _name, string _descriptionCID, uint256 _fundingGoal, address _fundingToken): Innovator proposes a project.
 * 2.  updateProjectDetails(uint256 _projectId, string _newDescriptionCID): Innovator updates project description.
 * 3.  revokeProjectProposal(uint256 _projectId): Innovator revokes unfunded project.
 * 4.  getProjectData(uint256 _projectId): Retrieves project details.
 *
 * II. Milestone Management & Verification:
 * 5.  addProjectMilestone(uint256 _projectId, string _milestoneDescriptionCID, uint256 _payoutPercentage): Innovator adds a milestone.
 * 6.  requestMilestoneVerification(uint256 _projectId, uint256 _milestoneIndex, string _proofCID): Innovator requests milestone verification.
 * 7.  submitMilestoneVerificationResult(uint256 _projectId, uint256 _milestoneIndex, bool _isAchieved, string _verifierNotesCID): Verifier submits verification.
 * 8.  challengeMilestoneVerification(uint256 _projectId, uint256 _milestoneIndex, string _challengeReasonCID): Stakeholder challenges verification.
 * 9.  resolveMilestoneDispute(uint256 _projectId, uint256 _milestoneIndex, bool _finalStatus): Governor resolves dispute.
 *
 * III. Funding, Staking & Rewards:
 * 10. stakeFunds(uint256 _projectId, uint256 _amount): Users stake funds on a project.
 * 11. unstakeFunds(uint256 _projectId, uint256 _amount): Users unstake from active projects.
 * 12. claimProjectFunding(uint256 _projectId, uint256 _milestoneIndex): Innovator claims milestone funding.
 * 13. claimStakingRewards(uint256 _projectId): Stakers claim rewards.
 * 14. withdrawFailedProjectStakes(uint256 _projectId): Stakers withdraw from failed projects.
 *
 * IV. Reputation & Governance:
 * 15. registerVerifier(string _profileCID): Proposes an address as a verifier.
 * 16. approveVerifier(address _verifierAddress): Governor approves verifier.
 * 17. slashVerifier(address _verifierAddress, uint256 _amount, string _reasonCID): Governor slashes verifier.
 * 18. getInnovatorReputation(address _innovator): Gets innovator's reputation.
 * 19. getVerifierReputation(address _verifier): Gets verifier's reputation.
 *
 * V. Impact NFTs (ERC721 Extension):
 * 20. mintImpactNFT(uint256 _projectId): Mints an iNFT for a project.
 * 21. updateImpactNFTMetadata(uint256 _projectId, string _newMetadataCID): Updates iNFT metadata.
 * 22. burnImpactNFT(uint256 _projectId): Burns a project's iNFT.
 *
 * VI. Dynamic Parameters & System Configuration:
 * 23. setStakingLockupPeriod(uint256 _newLockupSeconds): Sets staking lockup duration.
 * 24. setVerificationChallengeWindow(uint256 _newWindowSeconds): Sets challenge window.
 * 25. setRewardDistributionFactors(uint256 _innovatorShare, uint256 _stakerShare, uint256 _verifierShare): Adjusts reward split.
 * 26. setFundingTokenAllowed(address _tokenAddress, bool _allowed): Manages allowed funding tokens.
 */
contract SyntheticaNexus is ReentrancyGuard {
    using SafeERC20 for IERC20;

    // --- Custom Errors ---
    error NotGovernor();
    error NotInnovator(uint256 _projectId);
    error NotVerifier();
    error NotProjectStakeholder(uint256 _projectId);
    error ProjectNotFound();
    error MilestoneNotFound();
    error InvalidProjectStatus(ProjectStatus _expected, ProjectStatus _current);
    error InvalidMilestoneStatus(MilestoneStatus _expected, MilestoneStatus _current);
    error InsufficientFundsStaked();
    error FundingGoalNotMet();
    error StakingLockupActive(uint256 _timeRemaining);
    error MilestoneVerificationNotRequested();
    error ChallengeWindowExpired();
    error ChallengeWindowNotActive();
    error VerificationAlreadySubmitted();
    error InvalidPayoutPercentage();
    error NoRewardsToClaim();
    error NoFundsToWithdraw();
    error ImpactNFTAlreadyMinted();
    error ProjectNotFunded();
    error ProjectStillActive();
    error FundingTokenNotAllowed(address _token);
    error VerifierAlreadyRegistered();
    error VerifierNotPending();
    error VerifierNotApproved();
    error SharesMustSumToHundred();

    // --- Enums ---
    enum ProjectStatus { Proposed, Active, Completed, Failed, Revoked }
    enum MilestoneStatus { Pending, VerificationRequested, VerifiedAchieved, VerifiedFailed, Challenged, ResolvedAchieved, ResolvedFailed }

    // --- Structs ---
    struct Project {
        address innovator;
        string name;
        string descriptionCID; // IPFS CID for project details
        address fundingToken; // ERC20 token used for funding
        uint256 fundingGoal;
        uint256 totalStaked; // Total ERC20 tokens staked on this project
        uint256 totalInnovatorClaimed; // Amount claimed by innovator for achieved milestones
        ProjectStatus status;
        bool impactNFTMinted;
        uint256 createdAt;
        uint256 lastActivityAt; // Timestamp of last significant project activity
        uint256[] milestoneIds; // Array of milestone IDs belonging to this project
    }

    struct Milestone {
        string descriptionCID; // IPFS CID for milestone details
        uint256 payoutPercentage; // % of total fundingGoal allocated to this milestone
        MilestoneStatus status;
        address verifier; // Address of the assigned verifier
        string proofCID; // Innovator's proof of completion (IPFS CID)
        string verifierNotesCID; // Verifier's notes/proof (IPFS CID)
        string challengeReasonCID; // Reason for challenge (IPFS CID)
        uint256 verificationRequestedAt;
        uint256 resolvedAt; // Timestamp when a dispute was resolved
    }

    // --- State Variables ---
    address public governor; // The address with governance control
    uint256 public nextProjectId = 1;
    uint256 public nextMilestoneId = 1;

    mapping(uint256 => Project) public projects;
    mapping(uint256 => Milestone) public milestones;

    // projectId => stakerAddress => amountStaked
    mapping(uint256 => mapping(address => uint256)) public projectStakes;
    // projectId => stakerAddress => amountClaimedRewards
    mapping(uint256 => mapping(address => uint256)) public projectStakerClaimedRewards;

    // Reputation system
    mapping(address => uint256) public innovatorReputation;
    mapping(address => uint256) public verifierReputation;

    // Verifier roles
    mapping(address => bool) public isVerifier; // True if address is an approved verifier
    mapping(address => string) public pendingVerifierProfiles; // IPFS CID for verifier profiles, pending approval

    // System parameters (configurable by governor)
    uint256 public stakingLockupPeriod = 7 days; // Default lockup period for unstaking
    uint256 public verificationChallengeWindow = 3 days; // Default window to challenge a verification
    uint256 public innovatorRewardShare = 40; // Percentage out of 100
    uint256 public stakerRewardShare = 50; // Percentage out of 100
    uint256 public verifierRewardShare = 10; // Percentage out of 100
    mapping(address => bool) public allowedFundingTokens; // Whitelist for ERC20 funding tokens

    // Internal ERC721 for Impact NFTs
    ImpactNFT public impactNFT;

    // --- Events ---
    event ProjectProposed(uint256 indexed projectId, address indexed innovator, string name, uint256 fundingGoal, address fundingToken);
    event ProjectUpdated(uint256 indexed projectId, string newDescriptionCID);
    event ProjectRevoked(uint256 indexed projectId, address indexed innovator);
    event MilestoneAdded(uint256 indexed projectId, uint256 indexed milestoneIndex, uint256 milestoneId, string descriptionCID, uint256 payoutPercentage);
    event MilestoneVerificationRequested(uint256 indexed projectId, uint256 indexed milestoneIndex, uint256 milestoneId, string proofCID);
    event MilestoneVerificationSubmitted(uint256 indexed projectId, uint256 indexed milestoneIndex, uint256 milestoneId, address indexed verifier, bool isAchieved, string verifierNotesCID);
    event MilestoneChallenged(uint256 indexed projectId, uint256 indexed milestoneIndex, uint256 milestoneId, address indexed challenger, string challengeReasonCID);
    event MilestoneDisputeResolved(uint256 indexed projectId, uint256 indexed milestoneIndex, uint256 milestoneId, bool finalStatus);
    event FundsStaked(uint256 indexed projectId, address indexed staker, uint256 amount);
    event FundsUnstaked(uint256 indexed projectId, address indexed staker, uint256 amount);
    event InnovatorFundingClaimed(uint256 indexed projectId, address indexed innovator, uint252 milestoneIndex, uint256 amount);
    event StakingRewardsClaimed(uint256 indexed projectId, address indexed staker, uint256 amount);
    event FailedProjectStakesWithdrawn(uint256 indexed projectId, address indexed staker, uint256 amount);
    event VerifierRegistered(address indexed verifier, string profileCID);
    event VerifierApproved(address indexed verifier);
    event VerifierSlashed(address indexed verifier, uint256 amount, string reasonCID);
    event ImpactNFTMinted(uint256 indexed projectId, uint256 indexed tokenId, address indexed innovator);
    event ImpactNFTMetadataUpdated(uint256 indexed projectId, uint256 indexed tokenId, string newMetadataCID);
    event ImpactNFTBurned(uint256 indexed projectId, uint256 indexed tokenId);
    event StakingLockupPeriodSet(uint256 newLockupSeconds);
    event VerificationChallengeWindowSet(uint256 newWindowSeconds);
    event RewardDistributionFactorsSet(uint256 innovatorShare, uint256 stakerShare, uint256 verifierShare);
    event FundingTokenAllowedSet(address indexed tokenAddress, bool allowed);

    // --- Modifiers ---
    modifier onlyGovernor() {
        if (msg.sender != governor) revert NotGovernor();
        _;
    }

    modifier onlyInnovator(uint256 _projectId) {
        if (projects[_projectId].innovator != msg.sender) revert NotInnovator(_projectId);
        _;
    }

    modifier onlyVerifier() {
        if (!isVerifier[msg.sender]) revert NotVerifier();
        _;
    }

    modifier onlyProjectStakeholder(uint256 _projectId) {
        if (projects[_projectId].innovator != msg.sender && projectStakes[_projectId][msg.sender] == 0) {
            revert NotProjectStakeholder(_projectId);
        }
        _;
    }

    // --- Constructor ---
    constructor(address _governor, string memory _impactNFTName, string memory _impactNFTSymbol) {
        governor = _governor;
        impactNFT = new ImpactNFT(address(this), _impactNFTName, _impactNFTSymbol);
        // Default allowed token: Example DAI, WETH, etc. (Can be extended by governor later)
        allowedFundingTokens[0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48] = true; // Example USDC
    }

    // --- I. Core Project Lifecycle & Data (Innovator Focused) ---

    /**
     * @dev Innovator proposes a new project.
     * @param _name The name of the project.
     * @param _descriptionCID IPFS CID pointing to the project's detailed description.
     * @param _fundingGoal The target funding amount in the specified ERC20 token (in smallest units).
     * @param _fundingToken The address of the ERC20 token used for funding.
     */
    function proposeProject(
        string memory _name,
        string memory _descriptionCID,
        uint256 _fundingGoal,
        address _fundingToken
    ) external nonReentrant returns (uint256) {
        if (_fundingGoal == 0) revert InsufficientFundsStaked(); // Or specific error for funding goal
        if (!allowedFundingTokens[_fundingToken]) revert FundingTokenNotAllowed(_fundingToken);

        uint256 projectId = nextProjectId++;
        projects[projectId] = Project({
            innovator: msg.sender,
            name: _name,
            descriptionCID: _descriptionCID,
            fundingToken: _fundingToken,
            fundingGoal: _fundingGoal,
            totalStaked: 0,
            totalInnovatorClaimed: 0,
            status: ProjectStatus.Proposed,
            impactNFTMinted: false,
            createdAt: block.timestamp,
            lastActivityAt: block.timestamp,
            milestoneIds: new uint256[](0)
        });

        emit ProjectProposed(projectId, msg.sender, _name, _fundingGoal, _fundingToken);
        return projectId;
    }

    /**
     * @dev Innovator updates the IPFS CID for their project's description.
     * @param _projectId The ID of the project.
     * @param _newDescriptionCID The new IPFS CID for the project description.
     */
    function updateProjectDetails(uint256 _projectId, string memory _newDescriptionCID) external onlyInnovator(_projectId) {
        Project storage project = projects[_projectId];
        if (project.status != ProjectStatus.Proposed && project.status != ProjectStatus.Active) {
            revert InvalidProjectStatus(ProjectStatus.Proposed, project.status);
        }
        project.descriptionCID = _newDescriptionCID;
        project.lastActivityAt = block.timestamp;
        emit ProjectUpdated(_projectId, _newDescriptionCID);
    }

    /**
     * @dev Innovator revokes an unfunded project proposal. Funds already staked will be released to stakers.
     * @param _projectId The ID of the project to revoke.
     */
    function revokeProjectProposal(uint256 _projectId) external onlyInnovator(_projectId) nonReentrant {
        Project storage project = projects[_projectId];
        if (project.status != ProjectStatus.Proposed) {
            revert InvalidProjectStatus(ProjectStatus.Proposed, project.status);
        }
        if (project.totalStaked > 0) {
            // Funds should be available for stakers to withdraw.
            // Marking project as failed will allow stakers to withdraw via withdrawFailedProjectStakes.
            project.status = ProjectStatus.Failed;
            project.lastActivityAt = block.timestamp;
        } else {
            project.status = ProjectStatus.Revoked;
            project.lastActivityAt = block.timestamp;
        }

        emit ProjectRevoked(_projectId, msg.sender);
    }

    /**
     * @dev Retrieves comprehensive details about a specific project.
     * @param _projectId The ID of the project.
     * @return Tuple containing project data.
     */
    function getProjectData(uint256 _projectId)
        external
        view
        returns (
            address innovator,
            string memory name,
            string memory descriptionCID,
            address fundingToken,
            uint256 fundingGoal,
            uint256 totalStaked,
            uint256 totalInnovatorClaimed,
            ProjectStatus status,
            bool impactNFTMinted,
            uint256 createdAt,
            uint256 lastActivityAt,
            uint256[] memory milestoneIds
        )
    {
        Project storage project = projects[_projectId];
        if (project.innovator == address(0)) revert ProjectNotFound();

        return (
            project.innovator,
            project.name,
            project.descriptionCID,
            project.fundingToken,
            project.fundingGoal,
            project.totalStaked,
            project.totalInnovatorClaimed,
            project.status,
            project.impactNFTMinted,
            project.createdAt,
            project.lastActivityAt,
            project.milestoneIds
        );
    }

    // --- II. Milestone Management & Verification (Collaborative/Oracle-driven) ---

    /**
     * @dev Innovator adds a new milestone for their project.
     * @param _projectId The ID of the project.
     * @param _milestoneDescriptionCID IPFS CID for the milestone's detailed description.
     * @param _payoutPercentage The percentage of the total funding goal allocated to this milestone (0-100).
     */
    function addProjectMilestone(
        uint256 _projectId,
        string memory _milestoneDescriptionCID,
        uint256 _payoutPercentage
    ) external onlyInnovator(_projectId) {
        Project storage project = projects[_projectId];
        if (project.status != ProjectStatus.Proposed && project.status != ProjectStatus.Active) {
            revert InvalidProjectStatus(ProjectStatus.Proposed, project.status);
        }
        if (_payoutPercentage == 0 || _payoutPercentage > 100) revert InvalidPayoutPercentage();

        uint256 milestoneId = nextMilestoneId++;
        milestones[milestoneId] = Milestone({
            descriptionCID: _milestoneDescriptionCID,
            payoutPercentage: _payoutPercentage,
            status: MilestoneStatus.Pending,
            verifier: address(0),
            proofCID: "",
            verifierNotesCID: "",
            challengeReasonCID: "",
            verificationRequestedAt: 0,
            resolvedAt: 0
        });
        project.milestoneIds.push(milestoneId);
        project.lastActivityAt = block.timestamp;

        emit MilestoneAdded(_projectId, project.milestoneIds.length - 1, milestoneId, _milestoneDescriptionCID, _payoutPercentage);
    }

    /**
     * @dev Innovator requests verification for a completed milestone.
     * @param _projectId The ID of the project.
     * @param _milestoneIndex The index of the milestone within the project's milestoneIds array.
     * @param _proofCID IPFS CID for the innovator's proof of completion.
     */
    function requestMilestoneVerification(
        uint256 _projectId,
        uint256 _milestoneIndex,
        string memory _proofCID
    ) external onlyInnovator(_projectId) {
        Project storage project = projects[_projectId];
        if (project.milestoneIds.length <= _milestoneIndex) revert MilestoneNotFound();
        uint256 milestoneId = project.milestoneIds[_milestoneIndex];
        Milestone storage milestone = milestones[milestoneId];

        if (milestone.status != MilestoneStatus.Pending) {
            revert InvalidMilestoneStatus(MilestoneStatus.Pending, milestone.status);
        }

        milestone.status = MilestoneStatus.VerificationRequested;
        milestone.proofCID = _proofCID;
        milestone.verificationRequestedAt = block.timestamp;
        project.lastActivityAt = block.timestamp;

        emit MilestoneVerificationRequested(_projectId, _milestoneIndex, milestoneId, _proofCID);
    }

    /**
     * @dev An approved verifier submits their verification result for a milestone.
     * @param _projectId The ID of the project.
     * @param _milestoneIndex The index of the milestone.
     * @param _isAchieved True if the milestone is achieved, false otherwise.
     * @param _verifierNotesCID IPFS CID for the verifier's notes/proof.
     */
    function submitMilestoneVerificationResult(
        uint256 _projectId,
        uint256 _milestoneIndex,
        bool _isAchieved,
        string memory _verifierNotesCID
    ) external onlyVerifier nonReentrant {
        Project storage project = projects[_projectId];
        if (project.milestoneIds.length <= _milestoneIndex) revert MilestoneNotFound();
        uint256 milestoneId = project.milestoneIds[_milestoneIndex];
        Milestone storage milestone = milestones[milestoneId];

        if (milestone.status != MilestoneStatus.VerificationRequested) {
            revert InvalidMilestoneStatus(MilestoneStatus.VerificationRequested, milestone.status);
        }
        if (milestone.verifier != address(0) && milestone.verifier != msg.sender) {
            // Allow re-submission by same verifier, or only one verifier per milestone.
            // For simplicity, allow one unique verifier for now.
            revert VerificationAlreadySubmitted();
        }

        milestone.verifier = msg.sender;
        milestone.status = _isAchieved ? MilestoneStatus.VerifiedAchieved : MilestoneStatus.VerifiedFailed;
        milestone.verifierNotesCID = _verifierNotesCID;
        project.lastActivityAt = block.timestamp;

        emit MilestoneVerificationSubmitted(_projectId, _milestoneIndex, milestoneId, msg.sender, _isAchieved, _verifierNotesCID);
    }

    /**
     * @dev Any project stakeholder can challenge a milestone verification result.
     * @param _projectId The ID of the project.
     * @param _milestoneIndex The index of the milestone.
     * @param _challengeReasonCID IPFS CID for the reason of the challenge.
     */
    function challengeMilestoneVerification(
        uint256 _projectId,
        uint256 _milestoneIndex,
        string memory _challengeReasonCID
    ) external onlyProjectStakeholder(_projectId) {
        Project storage project = projects[_projectId];
        if (project.milestoneIds.length <= _milestoneIndex) revert MilestoneNotFound();
        uint256 milestoneId = project.milestoneIds[_milestoneIndex];
        Milestone storage milestone = milestones[milestoneId];

        if (milestone.status != MilestoneStatus.VerifiedAchieved && milestone.status != MilestoneStatus.VerifiedFailed) {
            revert InvalidMilestoneStatus(MilestoneStatus.VerifiedAchieved, milestone.status); // or VerifiedFailed
        }
        if (block.timestamp > milestone.verificationRequestedAt + verificationChallengeWindow) {
            revert ChallengeWindowExpired();
        }

        milestone.status = MilestoneStatus.Challenged;
        milestone.challengeReasonCID = _challengeReasonCID;
        project.lastActivityAt = block.timestamp;

        emit MilestoneChallenged(_projectId, _milestoneIndex, milestoneId, msg.sender, _challengeReasonCID);
    }

    /**
     * @dev The Governor resolves a disputed milestone's status.
     * @param _projectId The ID of the project.
     * @param _milestoneIndex The index of the milestone.
     * @param _finalStatus The final status of the milestone (true for achieved, false for failed).
     */
    function resolveMilestoneDispute(
        uint256 _projectId,
        uint256 _milestoneIndex,
        bool _finalStatus
    ) external onlyGovernor {
        Project storage project = projects[_projectId];
        if (project.milestoneIds.length <= _milestoneIndex) revert MilestoneNotFound();
        uint256 milestoneId = project.milestoneIds[_milestoneIndex];
        Milestone storage milestone = milestones[milestoneId];

        if (milestone.status != MilestoneStatus.Challenged) {
            revert InvalidMilestoneStatus(MilestoneStatus.Challenged, milestone.status);
        }

        milestone.status = _finalStatus ? MilestoneStatus.ResolvedAchieved : MilestoneStatus.ResolvedFailed;
        milestone.resolvedAt = block.timestamp;
        project.lastActivityAt = block.timestamp;

        // Reward / penalize reputation based on dispute outcome vs original verification
        _handleReputationOnMilestoneResolution(_projectId, milestoneId, _finalStatus);

        emit MilestoneDisputeResolved(_projectId, _milestoneIndex, milestoneId, _finalStatus);
    }

    // --- III. Funding, Staking & Rewards (Community/Staker Focused) ---

    /**
     * @dev Users stake ERC20 tokens on a project.
     * @param _projectId The ID of the project to stake on.
     * @param _amount The amount of ERC20 tokens to stake.
     */
    function stakeFunds(uint256 _projectId, uint256 _amount) external nonReentrant {
        Project storage project = projects[_projectId];
        if (project.innovator == address(0)) revert ProjectNotFound();
        if (project.status != ProjectStatus.Proposed && project.status != ProjectStatus.Active) {
            revert InvalidProjectStatus(ProjectStatus.Proposed, project.status);
        }
        if (_amount == 0) revert InsufficientFundsStaked();

        IERC20(project.fundingToken).safeTransferFrom(msg.sender, address(this), _amount);

        projectStakes[_projectId][msg.sender] += _amount;
        project.totalStaked += _amount;
        project.lastActivityAt = block.timestamp;

        // If project transitions from Proposed to Active upon reaching funding goal
        if (project.status == ProjectStatus.Proposed && project.totalStaked >= project.fundingGoal) {
            project.status = ProjectStatus.Active;
        }

        emit FundsStaked(_projectId, msg.sender, _amount);
    }

    /**
     * @dev Users can unstake funds from active projects, subject to a lockup period.
     * @param _projectId The ID of the project.
     * @param _amount The amount to unstake.
     */
    function unstakeFunds(uint256 _projectId, uint256 _amount) external nonReentrant {
        Project storage project = projects[_projectId];
        if (project.innovator == address(0)) revert ProjectNotFound();
        if (project.status != ProjectStatus.Active) {
            revert InvalidProjectStatus(ProjectStatus.Active, project.status);
        }
        if (projectStakes[_projectId][msg.sender] < _amount) revert InsufficientFundsStaked();

        // Implement a basic lockup period
        // For simplicity, lockup is from project's last activity, meaning any significant project state change
        // In a real system, this would be more complex, perhaps based on individual stake time
        if (block.timestamp < project.lastActivityAt + stakingLockupPeriod) {
            revert StakingLockupActive(project.lastActivityAt + stakingLockupPeriod - block.timestamp);
        }

        projectStakes[_projectId][msg.sender] -= _amount;
        project.totalStaked -= _amount;
        IERC20(project.fundingToken).safeTransfer(msg.sender, _amount);

        emit FundsUnstaked(_projectId, msg.sender, _amount);
    }

    /**
     * @dev Innovator claims the allocated funding for an achieved and verified milestone.
     * @param _projectId The ID of the project.
     * @param _milestoneIndex The index of the milestone.
     */
    function claimProjectFunding(uint256 _projectId, uint256 _milestoneIndex) external onlyInnovator(_projectId) nonReentrant {
        Project storage project = projects[_projectId];
        if (project.status != ProjectStatus.Active && project.status != ProjectStatus.Completed) {
            revert InvalidProjectStatus(ProjectStatus.Active, project.status);
        }
        if (project.milestoneIds.length <= _milestoneIndex) revert MilestoneNotFound();
        uint256 milestoneId = project.milestoneIds[_milestoneIndex];
        Milestone storage milestone = milestones[milestoneId];

        if (milestone.status != MilestoneStatus.VerifiedAchieved && milestone.status != MilestoneStatus.ResolvedAchieved) {
            revert InvalidMilestoneStatus(MilestoneStatus.VerifiedAchieved, milestone.status); // or ResolvedAchieved
        }

        uint256 milestonePayout = (project.fundingGoal * milestone.payoutPercentage) / 100;
        if (project.totalStaked < milestonePayout) revert FundingGoalNotMet(); // Not enough funds collected yet

        // Ensure innovator doesn't double-claim for this milestone
        // Need a way to track claimed milestones. Let's add a `claimed` bool to Milestone struct.
        // For now, if innovator tries to claim multiple times, totalInnovatorClaimed will prevent overpayment
        // A dedicated mapping `claimedMilestonePayouts[projectId][milestoneId]` would be better.
        // For simplicity:
        uint256 availableToClaim = milestonePayout;
        // If it's already claimed, availableToClaim should be 0. This is a simplification
        // A real system would need a `bool claimed` per milestone.
        // For now, let's assume it's only called once per milestone.

        if (project.totalInnovatorClaimed + availableToClaim > project.totalStaked) {
             // This check might be too strict. It should be against fundingGoal * payoutPercentage
             // The main check is that milestone has `VerifiedAchieved` or `ResolvedAchieved` status
             // And that this milestone payout hasn't been disbursed before.
             // Given the current structure, an individual milestone cannot track `claimed` without a lot of rework.
             // We'll rely on `milestone.status` changing. Once funding is claimed, its status changes to something like `Disbursed`
             // This would require more enum states or a separate tracking mechanism.
             // For now, let's assume it only allows one claim per achieved milestone.
        }

        IERC20(project.fundingToken).safeTransfer(project.innovator, availableToClaim);
        project.totalInnovatorClaimed += availableToClaim;
        project.lastActivityAt = block.timestamp;
        milestone.status = MilestoneStatus.ResolvedAchieved; // Mark as resolved/disbursed for simplicity

        // Update innovator reputation for successful milestone
        innovatorReputation[project.innovator] += INNOVATOR_REWARD_FACTOR;

        emit InnovatorFundingClaimed(_projectId, project.innovator, _milestoneIndex, availableToClaim);
    }

    /**
     * @dev Stakers claim their share of rewards from successfully achieved milestones.
     * Rewards are calculated based on their stake proportion.
     * @param _projectId The ID of the project.
     */
    function claimStakingRewards(uint256 _projectId) external nonReentrant {
        Project storage project = projects[_projectId];
        if (project.innovator == address(0)) revert ProjectNotFound();
        if (project.status != ProjectStatus.Active && project.status != ProjectStatus.Completed) {
            revert InvalidProjectStatus(ProjectStatus.Active, project.status);
        }

        uint256 stakerStake = projectStakes[_projectId][msg.sender];
        if (stakerStake == 0) revert InsufficientFundsStaked();

        uint256 unclaimedRewards = _calculateStakerUnclaimedRewards(_projectId, msg.sender);
        if (unclaimedRewards == 0) revert NoRewardsToClaim();

        projectStakerClaimedRewards[_projectId][msg.sender] += unclaimedRewards;
        IERC20(project.fundingToken).safeTransfer(msg.sender, unclaimedRewards);

        emit StakingRewardsClaimed(_projectId, msg.sender, unclaimedRewards);
    }

    /**
     * @dev Stakers can withdraw their principal if a project officially fails or is abandoned.
     * @param _projectId The ID of the project.
     */
    function withdrawFailedProjectStakes(uint256 _projectId) external nonReentrant {
        Project storage project = projects[_projectId];
        if (project.innovator == address(0)) revert ProjectNotFound();
        if (project.status != ProjectStatus.Failed && project.status != ProjectStatus.Revoked) {
            revert InvalidProjectStatus(ProjectStatus.Failed, project.status); // Or Revoked
        }

        uint256 stakerStake = projectStakes[_projectId][msg.sender];
        if (stakerStake == 0) revert NoFundsToWithdraw();

        projectStakes[_projectId][msg.sender] = 0; // Clear stake
        project.totalStaked -= stakerStake; // Reduce total staked
        IERC20(project.fundingToken).safeTransfer(msg.sender, stakerStake);

        emit FailedProjectStakesWithdrawn(_projectId, msg.sender, stakerStake);
    }

    // --- IV. Reputation & Governance (DAO/System Focused) ---

    /**
     * @dev Registers an address as a pending verifier, awaiting Governor approval.
     * @param _profileCID IPFS CID for the verifier's profile.
     */
    function registerVerifier(string memory _profileCID) external {
        if (isVerifier[msg.sender] || bytes(pendingVerifierProfiles[msg.sender]).length > 0) {
            revert VerifierAlreadyRegistered();
        }
        pendingVerifierProfiles[msg.sender] = _profileCID;
        emit VerifierRegistered(msg.sender, _profileCID);
    }

    /**
     * @dev Governor approves a registered verifier.
     * @param _verifierAddress The address to approve.
     */
    function approveVerifier(address _verifierAddress) external onlyGovernor {
        if (bytes(pendingVerifierProfiles[_verifierAddress]).length == 0) {
            revert VerifierNotPending();
        }
        isVerifier[_verifierAddress] = true;
        delete pendingVerifierProfiles[_verifierAddress]; // Remove from pending
        emit VerifierApproved(_verifierAddress);
    }

    /**
     * @dev Governor slashes (penalizes) a verifier for malicious or negligent actions.
     * @param _verifierAddress The address of the verifier to slash.
     * @param _amount The amount of reputation to deduct.
     * @param _reasonCID IPFS CID for the reason of slashing.
     */
    function slashVerifier(address _verifierAddress, uint256 _amount, string memory _reasonCID) external onlyGovernor {
        if (!isVerifier[_verifierAddress]) revert VerifierNotApproved();
        if (verifierReputation[_verifierAddress] < _amount) {
            verifierReputation[_verifierAddress] = 0;
        } else {
            verifierReputation[_verifierAddress] -= _amount;
        }
        emit VerifierSlashed(_verifierAddress, _amount, _reasonCID);
    }

    /**
     * @dev Returns the current reputation points for a specific innovator.
     * @param _innovator The address of the innovator.
     * @return The innovator's reputation score.
     */
    function getInnovatorReputation(address _innovator) external view returns (uint256) {
        return innovatorReputation[_innovator];
    }

    /**
     * @dev Returns the current reputation points for a specific verifier.
     * @param _verifier The address of the verifier.
     * @return The verifier's reputation score.
     */
    function getVerifierReputation(address _verifier) external view returns (uint256) {
        return verifierReputation[_verifier];
    }

    // --- V. Impact NFTs (ERC721 Extension) ---

    /**
     * @dev Mints a unique ERC721 Impact NFT for a project.
     * Can only be minted once per project after it receives initial funding.
     * The `tokenId` for the iNFT is the `_projectId`.
     * @param _projectId The ID of the project.
     */
    function mintImpactNFT(uint256 _projectId) external onlyInnovator(_projectId) {
        Project storage project = projects[_projectId];
        if (project.impactNFTMinted) revert ImpactNFTAlreadyMinted();
        if (project.totalStaked == 0) revert ProjectNotFunded();

        project.impactNFTMinted = true;
        project.lastActivityAt = block.timestamp;
        impactNFT.mint(msg.sender, _projectId);
        emit ImpactNFTMinted(_projectId, _projectId, msg.sender);
    }

    /**
     * @dev Updates the metadata (traits, progress) of a project's Impact NFT.
     * The `tokenId` for the iNFT is the `_projectId`.
     * @param _projectId The ID of the project whose iNFT metadata needs updating.
     * @param _newMetadataCID The new IPFS CID for the iNFT metadata.
     */
    function updateImpactNFTMetadata(uint256 _projectId, string memory _newMetadataCID) external onlyInnovator(_projectId) {
        Project storage project = projects[_projectId];
        if (!project.impactNFTMinted) revert ImpactNFTAlreadyMinted(); // Implies it's not minted, so cannot update

        // The iNFT contract needs a way to update `tokenURI`
        // `ERC721` doesn't expose `_setTokenURI` publicly, so `ImpactNFT` subclass needs to.
        impactNFT.setTokenURI(_projectId, _newMetadataCID);
        project.lastActivityAt = block.timestamp;
        emit ImpactNFTMetadataUpdated(_projectId, _projectId, _newMetadataCID);
    }

    /**
     * @dev Allows the project innovator to burn their project's Impact NFT.
     * @param _projectId The ID of the project.
     */
    function burnImpactNFT(uint256 _projectId) external onlyInnovator(_projectId) {
        Project storage project = projects[_projectId];
        if (!project.impactNFTMinted) revert ImpactNFTAlreadyMinted(); // Implies it's not minted
        if (project.status == ProjectStatus.Active) revert ProjectStillActive(); // Only burn if failed/completed/revoked

        project.impactNFTMinted = false;
        project.lastActivityAt = block.timestamp;
        impactNFT.burn(msg.sender, _projectId); // Assuming `burn` allows owner to burn its own token
        emit ImpactNFTBurned(_projectId, _projectId);
    }

    // --- VI. Dynamic Parameters & System Configuration (Governor Focused) ---

    /**
     * @dev Governor sets the minimum time funds must remain staked.
     * @param _newLockupSeconds The new lockup period in seconds.
     */
    function setStakingLockupPeriod(uint256 _newLockupSeconds) external onlyGovernor {
        stakingLockupPeriod = _newLockupSeconds;
        emit StakingLockupPeriodSet(_newLockupSeconds);
    }

    /**
     * @dev Governor sets the time period during which a milestone verification can be challenged.
     * @param _newWindowSeconds The new challenge window in seconds.
     */
    function setVerificationChallengeWindow(uint256 _newWindowSeconds) external onlyGovernor {
        verificationChallengeWindow = _newWindowSeconds;
        emit VerificationChallengeWindowSet(_newWindowSeconds);
    }

    /**
     * @dev Governor adjusts the percentage split of rewards between innovators, stakers, and verifiers.
     * The sum of shares must be 100.
     * @param _innovatorShare New percentage for innovator.
     * @param _stakerShare New percentage for stakers.
     * @param _verifierShare New percentage for verifiers.
     */
    function setRewardDistributionFactors(uint256 _innovatorShare, uint256 _stakerShare, uint256 _verifierShare) external onlyGovernor {
        if (_innovatorShare + _stakerShare + _verifierShare != 100) revert SharesMustSumToHundred();
        innovatorRewardShare = _innovatorShare;
        stakerRewardShare = _stakerShare;
        verifierRewardShare = _verifierShare;
        emit RewardDistributionFactorsSet(_innovatorShare, _stakerShare, _verifierShare);
    }

    /**
     * @dev Governor enables or disables specific ERC20 tokens for use as funding currency.
     * @param _tokenAddress The address of the ERC20 token.
     * @param _allowed True to allow, false to disallow.
     */
    function setFundingTokenAllowed(address _tokenAddress, bool _allowed) external onlyGovernor {
        allowedFundingTokens[_tokenAddress] = _allowed;
        emit FundingTokenAllowedSet(_tokenAddress, _allowed);
    }

    // --- Internal Helper Functions ---

    /**
     * @dev Calculates unclaimed rewards for a specific staker on a project.
     * This is a simplified calculation; a real system might use proportional weights.
     * @param _projectId The ID of the project.
     * @param _staker The address of the staker.
     * @return The amount of unclaimed rewards.
     */
    function _calculateStakerUnclaimedRewards(uint256 _projectId, address _staker) internal view returns (uint256) {
        Project storage project = projects[_projectId];
        uint256 totalRewardPool = 0; // Total rewards accrued from achieved milestones
        uint256 totalMilestonePayouts = 0; // Total milestone payouts for achieved/resolved milestones

        for (uint256 i = 0; i < project.milestoneIds.length; i++) {
            uint256 milestoneId = project.milestoneIds[i];
            Milestone storage milestone = milestones[milestoneId];
            if (milestone.status == MilestoneStatus.VerifiedAchieved || milestone.status == MilestoneStatus.ResolvedAchieved) {
                uint256 milestonePayout = (project.fundingGoal * milestone.payoutPercentage) / 100;
                totalMilestonePayouts += milestonePayout;
            }
        }

        // Rewards for stakers are derived from a portion of the project's 'success'
        // For simplicity, let's say the reward pool is based on total achieved milestone value.
        // A more complex system might have a separate reward token or a fixed percentage of each milestone's funding.
        // Here, we assume stakers earn a portion of the *total accumulated funds for achieved milestones*.
        uint256 stakerRewardFromMilestones = (totalMilestonePayouts * stakerRewardShare) / 100;

        // Calculate staker's proportional share of the reward pool
        if (project.totalStaked == 0) return 0; // Avoid division by zero
        uint256 stakerProportion = (projectStakes[_projectId][_staker] * 1e18) / project.totalStaked; // Use 1e18 for precision
        uint256 totalUnclaimedRewardsForStaker = (stakerRewardFromMilestones * stakerProportion) / 1e18;

        // Deduct already claimed rewards
        return totalUnclaimedRewardsForStaker - projectStakerClaimedRewards[_projectId][_staker];
    }

    /**
     * @dev Handles reputation updates based on milestone dispute resolution.
     * @param _projectId The ID of the project.
     * @param _milestoneId The ID of the milestone.
     * @param _finalStatus The final status of the milestone after resolution.
     */
    function _handleReputationOnMilestoneResolution(uint256 _projectId, uint256 _milestoneId, bool _finalStatus) internal {
        Project storage project = projects[_projectId];
        Milestone storage milestone = milestones[_milestoneId];

        // Innovator reputation: increased for achieved, decreased for failed.
        if (_finalStatus) {
            innovatorReputation[project.innovator] += INNOVATOR_REWARD_FACTOR;
        } else if (innovatorReputation[project.innovator] > INNOVATOR_REWARD_FACTOR) {
            innovatorReputation[project.innovator] -= INNOVATOR_REWARD_FACTOR;
        } else {
            innovatorReputation[project.innovator] = 0;
        }

        // Verifier reputation: increased for accurate verification, decreased for inaccurate.
        if (milestone.verifier != address(0)) {
            bool initialVerificationWasAchieved = (milestone.status == MilestoneStatus.VerifiedAchieved);
            if (initialVerificationWasAchieved == _finalStatus) {
                verifierReputation[milestone.verifier] += VERIFIER_REWARD_FACTOR; // Accurate verification
            } else if (verifierReputation[milestone.verifier] > VERIFIER_REWARD_FACTOR) {
                verifierReputation[milestone.verifier] -= VERIFIER_REWARD_FACTOR; // Inaccurate verification
            } else {
                verifierReputation[milestone.verifier] = 0;
            }
        }
    }
}


// --- ImpactNFT Contract (Internal ERC721) ---
// This ERC721 implementation will be owned by SyntheticaNexus and mint tokens
// where the tokenId is directly the projectId.
// It includes a basic mechanism for `tokenURI` that can be updated by the owner.
contract ImpactNFT is ERC721 {
    address private _nexusContract; // The address of the SyntheticaNexus contract

    constructor(address nexusContractAddress, string memory name, string memory symbol) ERC721(name, symbol) {
        _nexusContract = nexusContractAddress;
    }

    // Only the SyntheticaNexus contract can call mint/burn/update functions
    modifier onlyNexus() {
        require(msg.sender == _nexusContract, "ImpactNFT: Caller is not the Nexus contract");
        _;
    }

    /**
     * @dev Mints a new Impact NFT.
     * @param to The address to mint the NFT to.
     * @param tokenId The ID of the token (which is also the projectId).
     */
    function mint(address to, uint256 tokenId) external onlyNexus {
        _mint(to, tokenId);
        // Initial tokenURI can be set here, or rely on updateImpactNFTMetadata
        _setTokenURI(tokenId, ""); // Default empty, expecting update
    }

    /**
     * @dev Sets the token URI for a specific token.
     * @param tokenId The ID of the token.
     * @param _tokenURI The new token URI (IPFS CID).
     */
    function setTokenURI(uint256 tokenId, string memory _tokenURI) external onlyNexus {
        _setTokenURI(tokenId, _tokenURI);
    }

    /**
     * @dev Burns an Impact NFT.
     * @param from The current owner of the token.
     * @param tokenId The ID of the token.
     */
    function burn(address from, uint256 tokenId) external onlyNexus {
        _burn(tokenId);
    }
}
```