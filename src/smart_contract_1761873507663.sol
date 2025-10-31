This smart contract, **SkillForgeDAO**, is a sophisticated Decentralized Autonomous Organization (DAO) designed for project incubation, skill-based contribution, and reputation-driven governance. It leverages **Dynamic Skill NFTs (sNFTs)** to represent verifiable skills, allowing a more nuanced approach to member participation and project execution than traditional token-only DAOs.

The core idea is to create an ecosystem where:
1.  **Skills are on-chain assets (sNFTs):** Members can mint, upgrade, and even lend NFTs representing specific skills (e.g., "Solidity Dev L3", "UI/UX Designer L2"). These sNFTs require attestation (verification).
2.  **Projects are incubated and funded by the DAO:** Projects are proposed, require specific sNFTs from contributors, and receive funding based on milestone completion and performance.
3.  **Governance is hybrid and dynamic:** Voting power combines traditional token-based governance (assumed for general DAO operations, though not explicit in this contract) with sNFT-based influence, potentially weighted by skill level or reputation.
4.  **Reputation matters:** Contributors earn/lose reputation based on project performance, influencing their future opportunities and sNFT progression.

This integrated system aims to foster a meritocratic, skill-centric decentralized workforce.

---

**Outline and Function Summary:**

This contract, `SkillForgeDAO`, acts as the central hub for the SkillForge ecosystem, interacting with an external `SkillForgeNFT` contract and an `AttestationOracle`.

**I. Core DAO Management & Initialization**
1.  **`constructor(address _skillNFTContract, address _attestationOracle, address _initialGovernanceModule, address _treasury)`**: Initializes the DAO with essential external contract addresses (sNFT, Oracle), the initial governance module, and the treasury address. Sets initial parameters like epoch duration and default fees.
2.  **`setGovernanceModule(address _governanceModule)`**: Allows the DAO's governance to update the address responsible for core governance actions (e.g., to upgrade governance logic).
3.  **`pauseDAO(bool _paused)`**: An emergency pause/unpause mechanism for critical DAO operations, controlled by the governance module.
4.  **`setEpochDuration(uint256 _duration)`**: Sets the duration for governance epochs (e.g., voting periods) in seconds.

**II. SkillForge NFT (sNFT) Management**
5.  **`proposeSkill(string memory _skillName, string memory _description, bytes32 _attestationCriteriaHash)`**: Allows any member to propose a new verifiable skill to be added to the sNFT system. This proposal requires subsequent governance approval to become an active skill.
6.  **`mintSkillNFT(address _to, uint256 _skillId, uint256 _level, bytes memory _attestationProof)`**: Mints a new sNFT for a user. Requires a valid attestation proof verified by the `AttestationOracle` and payment of a dynamic fee.
7.  **`upgradeSkillNFT(uint256 _tokenId, uint256 _newLevel, bytes memory _reAttestationProof)`**: Allows an sNFT holder to upgrade their skill to a higher level. This process also requires re-attestation and a dynamic fee.
8.  **`stakeSkillNFTForProject(uint256 _tokenId, uint256 _projectId)`**: Enables an sNFT holder to formally commit their skill to a specific approved or in-progress project, signaling active contribution.
9.  **`unstakeSkillNFTFromProject(uint256 _tokenId, uint256 _projectId)`**: Allows an sNFT holder to remove their staked sNFT from a project.
10. **`delegateSkillNFTVotingPower(uint256 _tokenId, address _delegatee)`**: Delegates the unique voting power associated with a specific sNFT to another address, fostering proxy voting based on specialized skills.
11. **`lendSkillNFT(uint256 _tokenId, uint256 _duration, uint256 _feePerEpoch, address _lenderPool)`**: Facilitates the temporary lending of an sNFT. This could enable skill-sharing for projects or allow earning passive income from one's verified skills.
12. **`revokeSkillNFT(uint256 _tokenId, string memory _reason)`**: Grants the governance module the ability to revoke an sNFT, typically due to misconduct, invalidation, or skill decay (though decay logic is external).

**III. Project Incubation & Management**
13. **`proposeProject(string memory _projectName, string memory _description, address _projectLead, uint256 _initialFundingRequest, uint256[] memory _requiredSkillIds, uint256[] memory _requiredSkillLevels)`**: Members can propose new projects, outlining their scope, designated project lead, initial funding request, and the specific sNFT skills and levels required from contributors. This undergoes governance review.
14. **`approveProjectFundingMilestone(uint256 _projectId, uint256 _milestoneIndex, uint256 _amount)`**: The governance module approves and releases funds for a specific project milestone after its successful completion or upon initial project approval.
15. **`submitProjectMilestoneCompletion(uint256 _projectId, uint256 _milestoneIndex, bytes32 _completionHash)`**: The designated project lead submits cryptographic proof of a milestone's completion, triggering potential funding release and contributor review processes.
16. **`assignContributorToProjectRole(uint256 _projectId, address _contributor, uint256 _skillId, uint256 _roleId)`**: The project lead assigns a verified contributor (who possesses the required sNFTs) to a specific role within the project.

**IV. Governance & Voting**
17. **`createProposal(bytes32 _proposalHash, ProposalType _proposalType, bytes memory _targetCallData)`**: Initiates a new governance proposal (e.g., adding a new skill, funding a project, updating DAO parameters, or executing custom logic).
18. **`voteOnProposal(uint256 _proposalId, bool _support, uint256[] memory _sNFTTokenIdsToUse)`**: Allows eligible members to vote on active proposals. Voting power is derived from a combination of their owned and/or delegated sNFTs (and potentially external governance tokens, not explicitly handled in this contract).
19. **`executeProposal(uint256 _proposalId)`**: Executes a passed governance proposal, enacting the proposed changes or actions within the DAO.

**V. Reputation & Rewards**
20. **`submitContributorPerformanceReview(uint256 _projectId, address _contributor, int256 _reputationDelta, string memory _feedbackHash)`**: The project lead (or a designated peer review committee) submits a performance review for a contributor, which directly updates their on-chain reputation score.
21. **`claimProjectRewards(uint256 _projectId, uint256 _contributorSkillNFTId)`**: Allows contributors to claim their earned project rewards (e.g., ETH, tokens) based on their assigned role, staked sNFT, and performance, assuming rewards have been allocated by the project lead or governance.

**VI. Treasury Management & Utilities**
22. **`updateAttestationOracle(address _newOracle)`**: Enables the governance module to update the address of the trusted `AttestationOracle` for skill verification, allowing for future upgrades or changes.
23. **`emergencyWithdrawFunds(address _tokenAddress, uint256 _amount, address _to)`**: A governance-controlled function for critical fund withdrawals (ETH or ERC20) in extreme circumstances, designed for security and crisis management.
24. **`setDynamicFee(ActionType _actionType, uint256 _newFeeBasisPoints)`**: Allows the governance module to dynamically adjust fees (in basis points) for various actions within the DAO (e.g., sNFT minting, project proposals), adapting to economic conditions or DAO strategy.
25. **`initiateTreasuryInvestment(address _strategyContract, bytes memory _callData)`**: A powerful function enabling the DAO's governance to invest treasury funds into approved DeFi strategies or interact with external contracts, facilitating active treasury management.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// --- Custom Errors ---
error Unauthorized();
error ZeroAddressNotAllowed();
error SkillNotFound();
error SkillNotApproved();
error InvalidSkillLevel();
error InsufficientFunding();
error ProjectNotFound();
error MilestoneNotFound();
error ProjectAlreadyApproved();
error ProjectNotApproved();
error InvalidProposalState();
error ProposalNotFound();
error VotingClosed();
error NotEnoughVotingPower();
error SkillNFTNotFound();
error SkillNFTNotOwned();
error SkillNFTAlreadyStaked();
error SkillNFTNotStaked();
error SkillNFTStakedOnWrongProject();
error NotProjectLead();
error InvalidAttestationProof();
error ContributorNotAssigned();
error SkillRequiredForRoleMismatch();
error LendingDurationTooShort();
error LendingFeeTooLow();
error InvalidActionType();
error EmergencyWithdrawalFailed();
error NothingToClaim();


// --- Interfaces for SkillNFTs and Attestation Oracle ---

interface ISkillNFT is IERC721Enumerable {
    struct SkillAttributes {
        uint256 skillId;
        uint256 level;
        uint256 lastAttestedAt; // Timestamp of the last attestation/upgrade
        uint256 projectIdStaked; // 0 if not staked, otherwise project ID
        address delegatedTo; // Address to which voting power is delegated
        address borrower; // Address if lent out, else address(0)
        uint256 lendingEndTime; // Timestamp when lending ends
        uint256 feePerEpoch; // Fee per epoch if lent
    }

    event SkillNFTMinted(address indexed to, uint256 indexed tokenId, uint256 skillId, uint256 level);
    event SkillNFTUpgraded(uint256 indexed tokenId, uint256 oldLevel, uint256 newLevel);
    event SkillNFTStaked(uint256 indexed tokenId, uint256 indexed projectId);
    event SkillNFTUnstaked(uint256 indexed tokenId, uint256 indexed projectId);
    event SkillNFTDelegated(uint256 indexed tokenId, address indexed delegator, address indexed delegatee);
    event SkillNFTRevoked(uint256 indexed tokenId, string reason);
    event SkillNFTLent(uint256 indexed tokenId, address indexed lender, address indexed borrower, uint256 duration, uint256 feePerEpoch);
    event SkillNFTUnlent(uint256 indexed tokenId);

    function mint(address _to, uint256 _skillId, uint256 _level) external returns (uint256);
    function upgrade(uint256 _tokenId, uint256 _newLevel) external;
    function revoke(uint256 _tokenId, string memory _reason) external;
    function getSkillAttributes(uint256 _tokenId) external view returns (SkillAttributes memory);
    function updateStakedProject(uint256 _tokenId, uint256 _projectId) external;
    function updateDelegatedTo(uint256 _tokenId, address _delegatee) external;
    function updateLendingState(uint256 _tokenId, address _borrower, uint256 _lendingEndTime, uint256 _feePerEpoch) external;
    function ownerOf(uint256 tokenId) external view returns (address);
}

// Interface for a potential external Attestation Oracle (can be a simple trusted address in this example)
interface IAttestationOracle {
    function verifyAttestation(uint256 _skillId, uint256 _level, bytes memory _proof) external view returns (bool);
    function verifyReAttestation(uint256 _tokenId, uint256 _newLevel, bytes memory _proof) external view returns (bool);
}

contract SkillForgeDAO is Context, ReentrancyGuard {

    // --- Outline and Function Summary ---
    // This contract, SkillForgeDAO, is designed as a dynamic, reputation-driven DAO for project incubation
    // and verifiable skill-based contribution using Dynamic Skill NFTs (sNFTs). It integrates skill
    // acquisition, project funding, contributor management, and hybrid governance into a cohesive system.

    // I. Core DAO Management & Initialization
    // 1. constructor(): Initializes the DAO with essential parameters like the sNFT contract,
    //    an attestation oracle, and an initial governance address.
    // 2. setGovernanceModule(address _governanceModule): Allows the DAO's governance to update
    //    the address responsible for core governance actions (e.g., in case of an upgrade).
    // 3. pauseDAO(bool _paused): Emergency pause/unpause for critical DAO operations, controlled by governance.
    // 4. setEpochDuration(uint256 _duration): Sets the duration for governance epochs (e.g., voting periods).

    // II. SkillForge NFT (sNFT) Management
    // 5. proposeSkill(string memory _skillName, string memory _description, bytes32 _attestationCriteriaHash):
    //    Allows members to propose new skills for the sNFT system, requiring governance approval to be activated.
    // 6. mintSkillNFT(address _to, uint256 _skillId, uint256 _level, bytes memory _attestationProof):
    //    Mints a new sNFT for a user after successful verification by the Attestation Oracle.
    // 7. upgradeSkillNFT(uint256 _tokenId, uint256 _newLevel, bytes memory _reAttestationProof):
    //    Upgrades an existing sNFT to a higher level, requiring re-attestation.
    // 8. stakeSkillNFTForProject(uint256 _tokenId, uint256 _projectId):
    //    Stakes an sNFT to commit to a specific project, signaling active contribution.
    // 9. unstakeSkillNFTFromProject(uint256 _tokenId, uint256 _projectId):
    //    Unstakes an sNFT from a project.
    // 10. delegateSkillNFTVotingPower(uint256 _tokenId, address _delegatee):
    //     Delegates the voting power of a specific sNFT to another address.
    // 11. lendSkillNFT(uint256 _tokenId, uint256 _duration, uint256 _feePerEpoch, address _lenderPool):
    //     Allows owners to temporarily lend their sNFTs to others, potentially earning fees.
    // 12. revokeSkillNFT(uint256 _tokenId, string memory _reason):
    //     Governance can revoke an sNFT due to misconduct or invalidation.

    // III. Project Incubation & Management
    // 13. proposeProject(string memory _projectName, string memory _description, address _projectLead,
    //     uint256 _initialFundingRequest, uint256[] memory _requiredSkillIds, uint256[] memory _requiredSkillLevels):
    //     Members can propose new projects, specifying required skills and initial funding needs,
    //     which then undergo governance approval.
    // 14. approveProjectFundingMilestone(uint256 _projectId, uint256 _milestoneIndex, uint256 _amount):
    //     Governance approves and releases funds for a specific project milestone.
    // 15. submitProjectMilestoneCompletion(uint256 _projectId, uint256 _milestoneIndex, bytes32 _completionHash):
    //     Project leads submit proof of milestone completion, initiating a review process.
    // 16. assignContributorToProjectRole(uint256 _projectId, address _contributor, uint256 _skillId, uint256 _roleId):
    //     Assigns a verified contributor (with relevant sNFT) to a specific role within a project.

    // IV. Governance & Voting
    // 17. createProposal(bytes32 _proposalHash, uint256 _proposalType, bytes memory _targetCallData):
    //     Initiates a new governance proposal (e.g., parameter changes, new skills, project funding).
    // 18. voteOnProposal(uint256 _proposalId, bool _support, uint256[] memory _sNFTTokenIdsToUse):
    //     Allows members to vote on proposals using their sNFTs' voting power (and assumed external token power).
    // 19. executeProposal(uint256 _proposalId): Executes a passed governance proposal.

    // V. Reputation & Rewards
    // 20. submitContributorPerformanceReview(uint256 _projectId, address _contributor,
    //     int256 _reputationDelta, string memory _feedbackHash):
    //     Project leads or peer committees submit performance reviews, affecting a contributor's reputation score.
    // 21. claimProjectRewards(uint256 _projectId, uint256 _contributorSkillNFTId):
    //     Contributors can claim their project rewards (e.g., tokens, ETH) based on their assigned role,
    //     performance, and sNFT contribution.

    // VI. Treasury Management & Utilities
    // 22. updateAttestationOracle(address _newOracle):
    //     Governance updates the address of the trusted Attestation Oracle.
    // 23. emergencyWithdrawFunds(address _tokenAddress, uint256 _amount, address _to):
    //     A governance-controlled emergency function for critical fund withdrawals.
    // 24. setDynamicFee(ActionType _actionType, uint256 _newFeeBasisPoints):
    //     Governance sets dynamic fees for various actions within the DAO (e.g., sNFT minting, project proposals).
    // 25. initiateTreasuryInvestment(address _strategyContract, bytes memory _callData):
    //     Governance can initiate investments of DAO treasury funds into approved DeFi strategies or external contracts.

    // --- State Variables ---

    address public immutable SKILL_NFT_CONTRACT;
    address public attestationOracle;
    address public governanceModule; // The address authorized to perform governance actions
    address public treasury; // Where all fees and project funds are held

    bool public daoPaused;
    uint256 public epochDuration; // Duration of a governance epoch in seconds

    uint256 public nextSkillId; // Auto-incrementing ID for proposed skills
    uint256 public nextProjectId; // Auto-incrementing ID for projects
    uint256 public nextProposalId; // Auto-incrementing ID for proposals

    // Proposed Skills (pending governance approval)
    struct ProposedSkill {
        string name;
        string description;
        bytes32 attestationCriteriaHash;
        bool approved;
    }
    mapping(uint256 => ProposedSkill) public proposedSkills;
    mapping(uint256 => bool) public approvedSkillIds; // Approved skills mapped by their ID (nextSkillId)

    // Projects
    enum ProjectStatus { Proposed, Approved, InProgress, Completed, Cancelled }
    struct Project {
        string name;
        string description;
        address projectLead;
        uint256 totalFundingAllocated; // Total funding requested and approved for the project
        uint256 currentFundingReleased; // Funds actually sent out for milestones
        ProjectStatus status;
        uint256[] requiredSkillIds;
        uint256[] requiredSkillLevels;
        mapping(uint256 => uint256) milestoneFundingAmount; // milestoneIndex => amount (approved for that milestone)
        mapping(uint256 => bool) milestoneCompleted; // milestoneIndex => completed status
        mapping(address => mapping(uint256 => uint256)) contributorRoles; // contributor => skillId => roleId (generic role identifier)
        mapping(address => uint256) unclaimedRewards; // contributor => reward amount
    }
    mapping(uint256 => Project) public projects;

    // Proposals
    enum ProposalType { AddSkill, ApproveProject, UpdateParam, CustomCall }
    enum ProposalState { Pending, Active, Succeeded, Defeated, Executed }
    struct Proposal {
        bytes32 proposalHash; // Unique hash for content (e.g., IPFS CID)
        ProposalType proposalType;
        bytes targetCallData; // Calldata for execution if CustomCall or UpdateParam
        uint256 startBlock;
        uint256 endBlock;
        uint256 votesFor;
        uint256 votesAgainst;
        ProposalState state;
        mapping(address => bool) hasVoted; // User has voted
        mapping(uint256 => bool) sNFTUsedInVote; // sNFT tokenId has voted
    }
    mapping(uint256 => Proposal) public proposals;

    // Reputation System
    mapping(address => int256) public reputationScores;

    // Dynamic Fees
    enum ActionType { MintSkillNFT, UpgradeSkillNFT, ProposeProject, ProposeSkill }
    mapping(ActionType => uint256) public actionFeesBasisPoints; // Fees in basis points (100 = 1%)

    // Events
    event DAOPaused(bool indexed _paused);
    event GovernanceModuleUpdated(address indexed _oldModule, address indexed _newModule);
    event SkillProposed(uint256 indexed skillId, string name, address indexed proposer);
    event SkillApproved(uint256 indexed skillId, string name);
    event ProjectProposed(uint256 indexed projectId, string name, address indexed projectLead, uint256 fundingRequested);
    event ProjectApproved(uint256 indexed projectId, uint256 totalFunding);
    event MilestoneApproved(uint256 indexed projectId, uint256 indexed milestoneIndex, uint256 amount);
    event MilestoneCompleted(uint256 indexed projectId, uint256 indexed milestoneIndex, bytes32 completionHash);
    event ContributorAssigned(uint256 indexed projectId, address indexed contributor, uint256 skillId, uint256 roleId);
    event ProposalCreated(uint256 indexed proposalId, bytes32 indexed proposalHash, ProposalType proposalType, address indexed proposer);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 sNFTsVotedPower);
    event ProposalExecuted(uint256 indexed proposalId);
    event ReputationUpdated(address indexed contributor, int256 newScore, int256 delta);
    event RewardsClaimed(address indexed contributor, uint256 projectId, uint256 amount);
    event AttestationOracleUpdated(address indexed _oldOracle, address indexed _newOracle);
    event EmergencyFundsWithdrawn(address indexed token, uint256 amount, address indexed to);
    event DynamicFeeUpdated(ActionType indexed actionType, uint256 newFeeBasisPoints);
    event TreasuryInvestmentInitiated(address indexed strategyContract, bytes callData);


    // --- Constructor ---
    constructor(address _skillNFTContract, address _attestationOracle, address _initialGovernanceModule, address _treasury) {
        if (_skillNFTContract == address(0) || _attestationOracle == address(0) || _initialGovernanceModule == address(0) || _treasury == address(0)) {
            revert ZeroAddressNotAllowed();
        }
        SKILL_NFT_CONTRACT = _skillNFTContract;
        attestationOracle = _attestationOracle;
        governanceModule = _initialGovernanceModule;
        treasury = _treasury;

        daoPaused = false;
        epochDuration = 7 days; // Default 7-day voting period

        nextSkillId = 1;
        nextProjectId = 1;
        nextProposalId = 1;

        // Set initial fees (e.g., 100 basis points = 1%)
        actionFeesBasisPoints[ActionType.MintSkillNFT] = 100; // 1%
        actionFeesBasisPoints[ActionType.UpgradeSkillNFT] = 50; // 0.5%
        actionFeesBasisPoints[ActionType.ProposeProject] = 0;
        actionFeesBasisPoints[ActionType.ProposeSkill] = 0;
    }

    // --- Modifiers ---
    modifier onlyGovernance() {
        if (_msgSender() != governanceModule) {
            revert Unauthorized();
        }
        _;
    }

    modifier whenNotPaused() {
        if (daoPaused) {
            revert DAOPaused(true);
        }
        _;
    }

    // --- I. Core DAO Management & Initialization ---

    // 2. setGovernanceModule(address _governanceModule)
    function setGovernanceModule(address _governanceModule) external onlyGovernance {
        if (_governanceModule == address(0)) {
            revert ZeroAddressNotAllowed();
        }
        emit GovernanceModuleUpdated(governanceModule, _governanceModule);
        governanceModule = _governanceModule;
    }

    // 3. pauseDAO(bool _paused)
    function pauseDAO(bool _paused) external onlyGovernance {
        daoPaused = _paused;
        emit DAOPaused(_paused);
    }

    // 4. setEpochDuration(uint256 _duration)
    function setEpochDuration(uint256 _duration) external onlyGovernance {
        if (_duration == 0) {
            revert ("Epoch duration cannot be zero");
        }
        epochDuration = _duration;
    }

    // --- II. SkillForge NFT (sNFT) Management ---

    // Internal helper to handle fees
    function _handleFee(ActionType _actionType) internal {
        uint256 feeBps = actionFeesBasisPoints[_actionType];
        if (feeBps > 0) {
            uint256 feeAmount = (msg.value * feeBps) / 10000; // Assuming fee is paid in ETH
            if (feeAmount > 0) {
                // Transfer fee to treasury
                (bool success, ) = payable(treasury).call{value: feeAmount}("");
                if (!success) {
                    revert ("Fee transfer failed");
                }
            }
        }
    }

    // 5. proposeSkill(string memory _skillName, string memory _description, bytes32 _attestationCriteriaHash)
    function proposeSkill(string memory _skillName, string memory _description, bytes32 _attestationCriteriaHash)
        external
        payable
        whenNotPaused
    {
        _handleFee(ActionType.ProposeSkill);

        uint256 skillId = nextSkillId++;
        proposedSkills[skillId] = ProposedSkill({
            name: _skillName,
            description: _description,
            attestationCriteriaHash: _attestationCriteriaHash,
            approved: false
        });
        emit SkillProposed(skillId, _skillName, _msgSender());
    }

    // Helper function for governance to approve a skill proposal (likely via a createProposal -> executeProposal flow)
    function _approveSkill(uint256 _skillId) internal onlyGovernance {
        if (bytes(proposedSkills[_skillId].name).length == 0) {
            revert SkillNotFound();
        }
        if (proposedSkills[_skillId].approved) {
            revert ("Skill already approved");
        }
        proposedSkills[_skillId].approved = true;
        approvedSkillIds[_skillId] = true;
        emit SkillApproved(_skillId, proposedSkills[_skillId].name);
    }

    // 6. mintSkillNFT(address _to, uint256 _skillId, uint256 _level, bytes memory _attestationProof)
    function mintSkillNFT(address _to, uint256 _skillId, uint256 _level, bytes memory _attestationProof)
        external
        payable
        whenNotPaused
        nonReentrant
    {
        _handleFee(ActionType.MintSkillNFT);

        if (_to == address(0)) {
            revert ZeroAddressNotAllowed();
        }
        if (!approvedSkillIds[_skillId]) {
            revert SkillNotApproved();
        }
        if (_level == 0) {
            revert InvalidSkillLevel();
        }
        if (!IAttestationOracle(attestationOracle).verifyAttestation(_skillId, _level, _attestationProof)) {
            revert InvalidAttestationProof();
        }

        ISkillNFT(SKILL_NFT_CONTRACT).mint(_to, _skillId, _level);
    }

    // 7. upgradeSkillNFT(uint256 _tokenId, uint256 _newLevel, bytes memory _reAttestationProof)
    function upgradeSkillNFT(uint256 _tokenId, uint256 _newLevel, bytes memory _reAttestationProof)
        external
        payable
        whenNotPaused
        nonReentrant
    {
        _handleFee(ActionType.UpgradeSkillNFT);

        ISkillNFT.SkillAttributes memory currentAttrs = ISkillNFT(SKILL_NFT_CONTRACT).getSkillAttributes(_tokenId);
        if (currentAttrs.skillId == 0) {
            revert SkillNFTNotFound();
        }
        if (ISkillNFT(SKILL_NFT_CONTRACT).ownerOf(_tokenId) != _msgSender()) {
            revert SkillNFTNotOwned();
        }
        if (_newLevel <= currentAttrs.level) {
            revert InvalidSkillLevel();
        }
        if (!IAttestationOracle(attestationOracle).verifyReAttestation(_tokenId, _newLevel, _reAttestationProof)) {
            revert InvalidAttestationProof();
        }

        ISkillNFT(SKILL_NFT_CONTRACT).upgrade(_tokenId, _newLevel);
    }

    // 8. stakeSkillNFTForProject(uint256 _tokenId, uint256 _projectId)
    function stakeSkillNFTForProject(uint256 _tokenId, uint256 _projectId) external whenNotPaused {
        if (ISkillNFT(SKILL_NFT_CONTRACT).ownerOf(_tokenId) != _msgSender()) {
            revert SkillNFTNotOwned();
        }
        ISkillNFT.SkillAttributes memory attrs = ISkillNFT(SKILL_NFT_CONTRACT).getSkillAttributes(_tokenId);
        if (attrs.projectIdStaked != 0) {
            revert SkillNFTAlreadyStaked();
        }
        if (projects[_projectId].status != ProjectStatus.Approved && projects[_projectId].status != ProjectStatus.InProgress) {
            revert ProjectNotApproved();
        }

        ISkillNFT(SKILL_NFT_CONTRACT).updateStakedProject(_tokenId, _projectId);
    }

    // 9. unstakeSkillNFTFromProject(uint256 _tokenId, uint256 _projectId)
    function unstakeSkillNFTFromProject(uint256 _tokenId, uint256 _projectId) external whenNotPaused {
        if (ISkillNFT(SKILL_NFT_CONTRACT).ownerOf(_tokenId) != _msgSender()) {
            revert SkillNFTNotOwned();
        }
        ISkillNFT.SkillAttributes memory attrs = ISkillNFT(SKILL_NFT_CONTRACT).getSkillAttributes(_tokenId);
        if (attrs.projectIdStaked == 0) {
            revert SkillNFTNotStaked();
        }
        if (attrs.projectIdStaked != _projectId) {
            revert SkillNFTStakedOnWrongProject();
        }

        ISkillNFT(SKILL_NFT_CONTRACT).updateStakedProject(_tokenId, 0); // Unstake by setting to 0
    }

    // 10. delegateSkillNFTVotingPower(uint256 _tokenId, address _delegatee)
    function delegateSkillNFTVotingPower(uint256 _tokenId, address _delegatee) external whenNotPaused {
        if (ISkillNFT(SKILL_NFT_CONTRACT).ownerOf(_tokenId) != _msgSender()) {
            revert SkillNFTNotOwned();
        }
        if (_delegatee == address(0)) {
            revert ZeroAddressNotAllowed();
        }
        ISkillNFT(SKILL_NFT_CONTRACT).updateDelegatedTo(_tokenId, _delegatee);
    }

    // 11. lendSkillNFT(uint256 _tokenId, uint256 _duration, uint256 _feePerEpoch, address _lenderPool)
    function lendSkillNFT(uint256 _tokenId, uint256 _duration, uint256 _feePerEpoch, address _borrower) external whenNotPaused {
        if (ISkillNFT(SKILL_NFT_CONTRACT).ownerOf(_tokenId) != _msgSender()) {
            revert SkillNFTNotOwned();
        }
        if (_duration == 0) {
            revert LendingDurationTooShort();
        }
        if (_feePerEpoch == 0) {
            revert LendingFeeTooLow();
        }
        if (_borrower == address(0)) {
            revert ZeroAddressNotAllowed();
        }
        ISkillNFT.SkillAttributes memory attrs = ISkillNFT(SKILL_NFT_CONTRACT).getSkillAttributes(_tokenId);
        if (attrs.borrower != address(0)) {
            revert ("SkillNFT already lent out");
        }

        // The sNFT's owner does not change, but its internal state reflects lending
        // A full lending protocol would involve an escrow or direct transfer for the duration.
        // For this demo, we model the internal state of the sNFT as 'lent'.
        uint256 lendingEndTime = block.timestamp + _duration;
        ISkillNFT(SKILL_NFT_CONTRACT).updateLendingState(_tokenId, _borrower, lendingEndTime, _feePerEpoch);
    }

    // 12. revokeSkillNFT(uint256 _tokenId, string memory _reason)
    function revokeSkillNFT(uint256 _tokenId, string memory _reason) external onlyGovernance whenNotPaused {
        ISkillNFT.SkillAttributes memory currentAttrs = ISkillNFT(SKILL_NFT_CONTRACT).getSkillAttributes(_tokenId);
        if (currentAttrs.skillId == 0) {
            revert SkillNFTNotFound();
        }
        ISkillNFT(SKILL_NFT_CONTRACT).revoke(_tokenId, _reason);
    }

    // --- III. Project Incubation & Management ---

    // 13. proposeProject(string memory _projectName, string memory _description, address _projectLead,
    //     uint256 _initialFundingRequest, uint256[] memory _requiredSkillIds, uint256[] memory _requiredSkillLevels)
    function proposeProject(
        string memory _projectName,
        string memory _description,
        address _projectLead,
        uint256 _initialFundingRequest,
        uint256[] memory _requiredSkillIds,
        uint256[] memory _requiredSkillLevels
    ) external payable whenNotPaused {
        _handleFee(ActionType.ProposeProject);

        if (_projectLead == address(0)) {
            revert ZeroAddressNotAllowed();
        }
        if (_requiredSkillIds.length != _requiredSkillLevels.length) {
            revert ("Skill requirements length mismatch");
        }
        if (_initialFundingRequest == 0) {
            revert ("Initial funding request must be greater than zero");
        }

        uint256 projectId = nextProjectId++;
        Project storage newProject = projects[projectId];
        newProject.name = _projectName;
        newProject.description = _description;
        newProject.projectLead = _projectLead;
        newProject.totalFundingAllocated = _initialFundingRequest;
        newProject.status = ProjectStatus.Proposed;
        newProject.requiredSkillIds = _requiredSkillIds;
        newProject.requiredSkillLevels = _requiredSkillLevels;

        emit ProjectProposed(projectId, _projectName, _projectLead, _initialFundingRequest);
    }

    // Helper function for governance to approve a project proposal (likely via a createProposal -> executeProposal flow)
    function _approveProject(uint256 _projectId) internal onlyGovernance {
        if (projects[_projectId].status != ProjectStatus.Proposed) {
            revert ProjectAlreadyApproved();
        }
        projects[_projectId].status = ProjectStatus.Approved;
        emit ProjectApproved(_projectId, projects[_projectId].totalFundingAllocated);
    }

    // 14. approveProjectFundingMilestone(uint256 _projectId, uint256 _milestoneIndex, uint256 _amount)
    function approveProjectFundingMilestone(uint256 _projectId, uint256 _milestoneIndex, uint256 _amount)
        external
        onlyGovernance
        whenNotPaused
        nonReentrant
    {
        Project storage project = projects[_projectId];
        if (project.status != ProjectStatus.Approved && project.status != ProjectStatus.InProgress) {
            revert ProjectNotApproved();
        }
        if (_amount == 0) {
            revert ("Funding amount must be greater than zero");
        }
        if (address(this).balance < _amount) { // Check if DAO has enough funds
            revert InsufficientFunding();
        }
        if (project.currentFundingReleased + _amount > project.totalFundingAllocated) {
            revert ("Funding exceeds total allocated for project");
        }

        project.milestoneFundingAmount[_milestoneIndex] = _amount;
        project.currentFundingReleased += _amount;

        (bool success, ) = payable(project.projectLead).call{value: _amount}("");
        if (!success) {
            revert ("Milestone funding transfer failed");
        }

        emit MilestoneApproved(_projectId, _milestoneIndex, _amount);
    }

    // 15. submitProjectMilestoneCompletion(uint256 _projectId, uint256 _milestoneIndex, bytes32 _completionHash)
    function submitProjectMilestoneCompletion(uint256 _projectId, uint256 _milestoneIndex, bytes32 _completionHash) external whenNotPaused {
        Project storage project = projects[_projectId];
        if (_msgSender() != project.projectLead) {
            revert NotProjectLead();
        }
        if (project.status != ProjectStatus.InProgress && project.status != ProjectStatus.Approved) {
            revert ProjectNotApproved();
        }
        if (project.milestoneCompleted[_milestoneIndex]) {
            revert ("Milestone already completed");
        }

        project.milestoneCompleted[_milestoneIndex] = true;
        // In a real DAO, this would trigger a governance vote or a review committee approval for final completion.
        // For simplicity, we directly mark as completed.
        // Further logic could change project status to 'InProgress' after 1st milestone, 'Completed' after final.

        emit MilestoneCompleted(_projectId, _milestoneIndex, _completionHash);
    }

    // 16. assignContributorToProjectRole(uint256 _projectId, address _contributor, uint256 _skillId, uint256 _roleId)
    function assignContributorToProjectRole(uint256 _projectId, address _contributor, uint256 _skillId, uint256 _roleId) external whenNotPaused {
        Project storage project = projects[_projectId];
        if (_msgSender() != project.projectLead) {
            revert NotProjectLead();
        }
        if (project.status != ProjectStatus.InProgress && project.status != ProjectStatus.Approved) {
            revert ProjectNotApproved();
        }
        if (_contributor == address(0)) {
            revert ZeroAddressNotAllowed();
        }

        // Verify the contributor has the required sNFT for this role
        bool hasRequiredSkill = false;
        uint256 ownerSNFTCount = ISkillNFT(SKILL_NFT_CONTRACT).balanceOf(_contributor);

        for (uint256 i = 0; i < ownerSNFTCount; i++) {
            uint256 tokenId = ISkillNFT(SKILL_NFT_CONTRACT).tokenOfOwnerByIndex(_contributor, i);
            ISkillNFT.SkillAttributes memory attrs = ISkillNFT(SKILL_NFT_CONTRACT).getSkillAttributes(tokenId);
            
            // Check if this sNFT matches ANY of the project's requirements for _skillId and level
            for (uint256 j = 0; j < project.requiredSkillIds.length; j++) {
                if (attrs.skillId == project.requiredSkillIds[j] && attrs.level >= project.requiredSkillLevels[j]) {
                    hasRequiredSkill = true;
                    break;
                }
            }
            if (hasRequiredSkill) break; // Found a matching skill, no need to check other sNFTs
        }

        if (!hasRequiredSkill) {
            revert SkillRequiredForRoleMismatch();
        }

        project.contributorRoles[_contributor][_skillId] = _roleId;
        emit ContributorAssigned(_projectId, _contributor, _skillId, _roleId);
    }

    // --- IV. Governance & Voting ---

    // 17. createProposal(bytes32 _proposalHash, uint256 _proposalType, bytes memory _targetCallData)
    function createProposal(bytes32 _proposalHash, ProposalType _proposalType, bytes memory _targetCallData) external whenNotPaused {
        // For simplicity, only governanceModule can create proposals
        if (_msgSender() != governanceModule) {
            revert Unauthorized();
        }
        if (_proposalHash == bytes32(0)) {
            revert ("Proposal hash cannot be zero");
        }

        uint256 proposalId = nextProposalId++;
        proposals[proposalId] = Proposal({
            proposalHash: _proposalHash,
            proposalType: _proposalType,
            targetCallData: _targetCallData,
            startBlock: block.number,
            endBlock: block.number + (epochDuration / 12), // Assuming ~12 seconds per block
            votesFor: 0,
            votesAgainst: 0,
            state: ProposalState.Active
        });
        emit ProposalCreated(proposalId, _proposalHash, _proposalType, _msgSender());
    }

    // Helper to get total voting power for an address based on sNFTs
    function _getVotingPower(address _voter, uint256[] memory _sNFTTokenIdsToUse) internal view returns (uint256) {
        uint256 totalPower = 0;
        // In a full DAO, this would combine sNFT power with ERC20 governance token power.
        // Here, we focus solely on sNFTs.
        for (uint256 i = 0; i < _sNFTTokenIdsToUse.length; i++) {
            uint256 tokenId = _sNFTTokenIdsToUse[i];
            ISkillNFT.SkillAttributes memory attrs = ISkillNFT(SKILL_NFT_CONTRACT).getSkillAttributes(tokenId);

            // Check if the sNFT is owned by the voter or delegated to them, and not lent out
            address owner = ISkillNFT(SKILL_NFT_CONTRACT).ownerOf(tokenId);
            address delegatedTo = attrs.delegatedTo;
            if (attrs.borrower == address(0) && (owner == _voter || delegatedTo == _voter)) {
                // Example: Each sNFT gives voting power based on its level, 100 power per level
                totalPower += (attrs.level * 100);
            }
        }
        return totalPower;
    }

    // 18. voteOnProposal(uint256 _proposalId, bool _support, uint256[] memory _sNFTTokenIdsToUse)
    function voteOnProposal(uint256 _proposalId, bool _support, uint256[] memory _sNFTTokenIdsToUse) external whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.proposalHash == bytes32(0)) {
            revert ProposalNotFound();
        }
        if (proposal.state != ProposalState.Active) {
            revert InvalidProposalState();
        }
        if (block.number > proposal.endBlock) {
            // Automatically mark proposal as defeated/succeeded if voting period ended
            proposal.state = (proposal.votesFor > proposal.votesAgainst) ? ProposalState.Succeeded : ProposalState.Defeated;
            revert VotingClosed();
        }
        if (proposal.hasVoted[_msgSender()]) {
            revert ("Already voted on this proposal");
        }

        uint256 voterPower = _getVotingPower(_msgSender(), _sNFTTokenIdsToUse);
        if (voterPower == 0) {
            revert NotEnoughVotingPower();
        }

        // Ensure sNFTs used in voting are not already used for this specific proposal
        for (uint256 i = 0; i < _sNFTTokenIdsToUse.length; i++) {
            if (proposal.sNFTUsedInVote[_sNFTTokenIdsToUse[i]]) {
                revert ("One or more sNFTs already used in this vote");
            }
            proposal.sNFTUsedInVote[_sNFTTokenIdsToUse[i]] = true;
        }

        if (_support) {
            proposal.votesFor += voterPower;
        } else {
            proposal.votesAgainst += voterPower;
        }
        proposal.hasVoted[_msgSender()] = true;

        emit VoteCast(_proposalId, _msgSender(), _support, voterPower);
    }

    // 19. executeProposal(uint256 _proposalId)
    function executeProposal(uint256 _proposalId) external onlyGovernance whenNotPaused nonReentrant {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.proposalHash == bytes32(0)) {
            revert ProposalNotFound();
        }
        if (block.number <= proposal.endBlock) {
            revert ("Voting period not ended");
        }

        // Finalize state if not already done
        if (proposal.state == ProposalState.Active) {
            proposal.state = (proposal.votesFor > proposal.votesAgainst) ? ProposalState.Succeeded : ProposalState.Defeated;
        }

        if (proposal.state == ProposalState.Defeated) {
            revert ("Proposal defeated");
        }
        if (proposal.state == ProposalState.Executed) {
            revert ("Proposal already executed");
        }

        proposal.state = ProposalState.Executed;

        // Execute action based on proposal type
        if (proposal.proposalType == ProposalType.AddSkill) {
            // TargetCallData for AddSkill should be abi.encode(_skillId)
            (uint256 skillId) = abi.decode(proposal.targetCallData, (uint256));
            _approveSkill(skillId);
        } else if (proposal.proposalType == ProposalType.ApproveProject) {
            // TargetCallData for ApproveProject should be abi.encode(_projectId)
            (uint256 projectId) = abi.decode(proposal.targetCallData, (uint256));
            _approveProject(projectId);
        } else if (proposal.proposalType == ProposalType.UpdateParam) {
            // TargetCallData for UpdateParam should be a direct call to a setter function on this contract
            (bool success,) = address(this).call(proposal.targetCallData);
            if (!success) {
                revert ("UpdateParam execution failed");
            }
        } else if (proposal.proposalType == ProposalType.CustomCall) {
            // CustomCall allows interaction with arbitrary contracts via governance.
            // TargetCallData should be `abi.encodeWithSignature("functionName(types...)", args...)`
            // and the `to` address must be implicitly handled in the `_targetCallData`
            // For delegatecall, the first bytes of _targetCallData should be the target address.
            // For simplicity, let's assume _targetCallData is for an external call.
            // If it's a delegatecall to change DAO logic, it would look like:
            // (bool success,) = address(this).delegatecall(proposal.targetCallData);
            // But a safer `CustomCall` usually involves calling an external `target` contract.
            // For this example, let's assume it calls an arbitrary contract defined within the callData.
            // A more robust system would include target address in the proposal struct.
            // For now, let's simulate a generic external call to a pre-approved strategy contract.
            // Revert to a simple `call` to avoid complex decoding without `target` address.
            // The `initiateTreasuryInvestment` is a safer way to do external calls.
            revert ("CustomCall type not directly supported for execution; use initiateTreasuryInvestment");
        } else {
            revert ("Unknown proposal type");
        }

        emit ProposalExecuted(_proposalId);
    }

    // --- V. Reputation & Rewards ---

    // 20. submitContributorPerformanceReview(uint256 _projectId, address _contributor, int256 _reputationDelta, string memory _feedbackHash)
    function submitContributorPerformanceReview(uint256 _projectId, address _contributor, int256 _reputationDelta, string memory _feedbackHash) external whenNotPaused {
        Project storage project = projects[_projectId];
        if (_msgSender() != project.projectLead) {
            revert NotProjectLead();
        }
        if (_contributor == address(0)) {
            revert ZeroAddressNotAllowed();
        }

        // Ensure contributor was assigned to the project. This is a basic check.
        // A more thorough check would ensure the specific sNFT used for assignment is still staked.
        bool contributorFoundInProject = false;
        uint256 ownerSNFTCount = ISkillNFT(SKILL_NFT_CONTRACT).balanceOf(_contributor);
        for (uint256 i = 0; i < ownerSNFTCount; i++) {
            uint256 tokenId = ISkillNFT(SKILL_NFT_CONTRACT).tokenOfOwnerByIndex(_contributor, i);
            ISkillNFT.SkillAttributes memory attrs = ISkillNFT(SKILL_NFT_CONTRACT).getSkillAttributes(tokenId);
            if (attrs.projectIdStaked == _projectId) {
                contributorFoundInProject = true;
                break;
            }
        }
        if (!contributorFoundInProject) {
            revert ContributorNotAssigned();
        }

        reputationScores[_contributor] += _reputationDelta;
        emit ReputationUpdated(_contributor, reputationScores[_contributor], _reputationDelta);
    }

    // Helper for project lead to allocate rewards (example: after milestone completion)
    // This is made internal for demonstration. In a real system, it might be an external function callable by projectLead
    // or through another governance-approved mechanism to distribute a portion of milestone funds.
    function _allocateProjectRewards(uint256 _projectId, address _contributor, uint256 _amount) internal onlyGovernance {
        if (projects[_projectId].projectLead == address(0)) { // Basic project existence check
            revert ProjectNotFound();
        }
        if (_contributor == address(0)) {
            revert ZeroAddressNotAllowed();
        }
        projects[_projectId].unclaimedRewards[_contributor] += _amount;
    }

    // 21. claimProjectRewards(uint256 _projectId, uint256 _contributorSkillNFTId)
    function claimProjectRewards(uint256 _projectId, uint256 _contributorSkillNFTId) external whenNotPaused nonReentrant {
        Project storage project = projects[_projectId];
        if (project.projectLead == address(0)) {
            revert ProjectNotFound();
        }
        if (ISkillNFT(SKILL_NFT_CONTRACT).ownerOf(_contributorSkillNFTId) != _msgSender()) {
            revert SkillNFTNotOwned();
        }
        // Basic check if the sNFT was involved in this project (more robust check would be if it was *assigned*)
        ISkillNFT.SkillAttributes memory attrs = ISkillNFT(SKILL_NFT_CONTRACT).getSkillAttributes(_contributorSkillNFTId);
        if (attrs.projectIdStaked != _projectId) {
            revert SkillNFTStakedOnWrongProject();
        }

        uint256 amountToClaim = project.unclaimedRewards[_msgSender()];
        if (amountToClaim == 0) {
            revert NothingToClaim();
        }
        project.unclaimedRewards[_msgSender()] = 0;

        (bool success, ) = payable(_msgSender()).call{value: amountToClaim}("");
        if (!success) {
            revert ("Reward transfer failed");
        }
        emit RewardsClaimed(_msgSender(), _projectId, amountToClaim);
    }

    // --- VI. Treasury Management & Utilities ---

    // 22. updateAttestationOracle(address _newOracle)
    function updateAttestationOracle(address _newOracle) external onlyGovernance {
        if (_newOracle == address(0)) {
            revert ZeroAddressNotAllowed();
        }
        emit AttestationOracleUpdated(attestationOracle, _newOracle);
        attestationOracle = _newOracle;
    }

    // 23. emergencyWithdrawFunds(address _tokenAddress, uint256 _amount, address _to)
    function emergencyWithdrawFunds(address _tokenAddress, uint256 _amount, address _to) external onlyGovernance nonReentrant {
        if (_to == address(0)) {
            revert ZeroAddressNotAllowed();
        }
        if (_amount == 0) {
            revert ("Amount must be greater than zero");
        }

        if (_tokenAddress == address(0)) { // ETH withdrawal
            if (address(this).balance < _amount) {
                revert InsufficientFunding();
            }
            (bool success, ) = payable(_to).call{value: _amount}("");
            if (!success) {
                revert EmergencyWithdrawalFailed();
            }
        } else { // ERC20 token withdrawal
            IERC20 token = IERC20(_tokenAddress);
            if (token.balanceOf(address(this)) < _amount) {
                revert InsufficientFunding();
            }
            if (!token.transfer(_to, _amount)) {
                revert EmergencyWithdrawalFailed();
            }
        }
        emit EmergencyFundsWithdrawn(_tokenAddress, _amount, _to);
    }

    // 24. setDynamicFee(ActionType _actionType, uint256 _newFeeBasisPoints)
    function setDynamicFee(ActionType _actionType, uint256 _newFeeBasisPoints) external onlyGovernance {
        if (_newFeeBasisPoints > 10000) { // Max 100% fee
            revert ("Fee cannot exceed 100%");
        }
        actionFeesBasisPoints[_actionType] = _newFeeBasisPoints;
        emit DynamicFeeUpdated(_actionType, _newFeeBasisPoints);
    }

    // 25. initiateTreasuryInvestment(address _strategyContract, bytes memory _callData)
    function initiateTreasuryInvestment(address _strategyContract, bytes memory _callData) external onlyGovernance nonReentrant {
        if (_strategyContract == address(0)) {
            revert ZeroAddressNotAllowed();
        }
        // This allows governance to call any function on any contract from the DAO treasury.
        // It's a powerful and flexible feature for dynamic treasury management.
        (bool success, ) = _strategyContract.call(_callData);
        if (!success) {
            revert ("Treasury investment call failed");
        }
        emit TreasuryInvestmentInitiated(_strategyContract, _callData);
    }

    // Fallback function to receive ETH
    receive() external payable {}
    fallback() external payable {}
}


// --- Helper Contracts for Demonstration (Would be separate deployments in production) ---

// Dummy SkillForgeNFT contract
// This ERC721 implementation is simplified for brevity and demonstration.
// In a production environment, use a robust ERC721 implementation like OpenZeppelin's.
contract SkillForgeNFT is IERC721Enumerable, ISkillNFT {
    string public name = "SkillForge NFT";
    string public symbol = "SFNFT";
    uint256 private _nextTokenId;
    address public immutable CONTROLLER; // The address of SkillForgeDAO

    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    mapping(uint256 => SkillAttributes) private _skillAttributes;

    // For ERC721Enumerable
    mapping(address => uint256[]) private _ownedTokens;
    mapping(uint256 => uint256) private _ownedTokensIndex;

    constructor(address _controller) {
        if (_controller == address(0)) revert ZeroAddressNotAllowed();
        CONTROLLER = _controller;
        _nextTokenId = 1;
    }

    modifier onlyController() {
        if (_msgSender() != CONTROLLER) {
            revert Unauthorized();
        }
        _;
    }

    // --- ERC721 Standard Functions (Simplified) ---
    function balanceOf(address owner) public view override returns (uint256) {
        if (owner == address(0)) revert ZeroAddressNotAllowed();
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view override returns (address) {
        address owner = _owners[tokenId];
        if (owner == address(0)) revert SkillNFTNotFound();
        return owner;
    }

    function approve(address to, uint256 tokenId) public override {
        address owner = ownerOf(tokenId);
        if (owner != _msgSender() && !_isApprovedForAll(owner, _msgSender())) {
            revert Unauthorized();
        }
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    function getApproved(uint256 tokenId) public view override returns (address) {
        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public override {
        if (operator == _msgSender()) revert ("Cannot approve self");
        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(address from, address to, uint256 tokenId) public override {
        if (!_isApprovedOrOwner(_msgSender(), tokenId)) {
            revert Unauthorized();
        }
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override {
        if (!_isApprovedOrOwner(_msgSender(), tokenId)) {
            revert Unauthorized();
        }
        _transfer(from, to, tokenId);
        // In a full ERC721, this would check `onERC721Received`
    }

    function _transfer(address from, address to, uint256 tokenId) internal {
        if (ownerOf(tokenId) != from) revert SkillNFTNotOwned();
        if (to == address(0)) revert ZeroAddressNotAllowed();

        _approve(address(0), tokenId); // Clear approval for the transferred token
        
        _removeTokenFromOwnerEnumeration(from, tokenId); // For Enumerable
        _addTokenToOwnerEnumeration(to, tokenId);       // For Enumerable

        _balances[from]--;
        _balances[to]++;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    // --- ERC721Enumerable Functions (Simplified) ---
    function tokenOfOwnerByIndex(address owner, uint256 index) public view override returns (uint256) {
        if (index >= _ownedTokens[owner].length) revert ("Index out of bounds");
        return _ownedTokens[owner][index];
    }

    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) internal {
        _ownedTokens[to].push(tokenId);
        _ownedTokensIndex[tokenId] = _ownedTokens[to].length - 1;
    }

    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) internal {
        uint256 lastTokenIndex = _ownedTokens[from].length - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];
            _ownedTokens[from][tokenIndex] = lastTokenId;
            _ownedTokensIndex[lastTokenId] = tokenIndex;
        }
        _ownedTokens[from].pop();
        delete _ownedTokensIndex[tokenId];
    }
    
    // --- ISkillNFT Custom Functions ---

    function mint(address _to, uint256 _skillId, uint256 _level) external onlyController returns (uint256) {
        if (_to == address(0)) {
            revert ZeroAddressNotAllowed();
        }
        if (_skillId == 0 || _level == 0) {
            revert InvalidSkillLevel();
        }

        uint256 newId = _nextTokenId++;
        _owners[newId] = _to;
        _balances[_to]++;
        _skillAttributes[newId] = SkillAttributes({
            skillId: _skillId,
            level: _level,
            lastAttestedAt: block.timestamp,
            projectIdStaked: 0,
            delegatedTo: address(0),
            borrower: address(0),
            lendingEndTime: 0,
            feePerEpoch: 0
        });
        _addTokenToOwnerEnumeration(_to, newId);

        emit Transfer(address(0), _to, newId); // ERC721 mint event
        emit SkillNFTMinted(_to, newId, _skillId, _level);
        return newId;
    }

    function upgrade(uint256 _tokenId, uint256 _newLevel) external onlyController {
        if (_skillAttributes[_tokenId].skillId == 0) {
            revert SkillNFTNotFound();
        }
        if (_newLevel <= _skillAttributes[_tokenId].level) {
            revert InvalidSkillLevel();
        }

        uint256 oldLevel = _skillAttributes[_tokenId].level;
        _skillAttributes[_tokenId].level = _newLevel;
        _skillAttributes[_tokenId].lastAttestedAt = block.timestamp;
        emit SkillNFTUpgraded(_tokenId, oldLevel, _newLevel);
    }

    function revoke(uint256 _tokenId, string memory _reason) external onlyController {
        if (_skillAttributes[_tokenId].skillId == 0) {
            revert SkillNFTNotFound();
        }

        address owner = _owners[_tokenId];
        _removeTokenFromOwnerEnumeration(owner, _tokenId);

        delete _owners[_tokenId];
        _balances[owner]--;
        delete _skillAttributes[_tokenId];
        delete _tokenApprovals[_tokenId];

        emit Transfer(owner, address(0), _tokenId); // ERC721 burn event
        emit SkillNFTRevoked(_tokenId, _reason);
    }

    function getSkillAttributes(uint256 _tokenId) public view override returns (SkillAttributes memory) {
        return _skillAttributes[_tokenId];
    }

    function updateStakedProject(uint256 _tokenId, uint256 _projectId) external onlyController {
        if (_skillAttributes[_tokenId].skillId == 0) {
            revert SkillNFTNotFound();
        }
        _skillAttributes[_tokenId].projectIdStaked = _projectId;
        if (_projectId != 0) {
            emit SkillNFTStaked(_tokenId, _projectId);
        } else {
            emit SkillNFTUnstaked(_tokenId, _skillAttributes[_tokenId].projectIdStaked);
        }
    }

    function updateDelegatedTo(uint256 _tokenId, address _delegatee) external onlyController {
        if (_skillAttributes[_tokenId].skillId == 0) {
            revert SkillNFTNotFound();
        }
        _skillAttributes[_tokenId].delegatedTo = _delegatee;
        emit SkillNFTDelegated(_tokenId, _owners[_tokenId], _delegatee);
    }

    function updateLendingState(uint256 _tokenId, address _borrower, uint256 _lendingEndTime, uint256 _feePerEpoch) external onlyController {
        if (_skillAttributes[_tokenId].skillId == 0) {
            revert SkillNFTNotFound();
        }
        _skillAttributes[_tokenId].borrower = _borrower;
        _skillAttributes[_tokenId].lendingEndTime = _lendingEndTime;
        _skillAttributes[_tokenId].feePerEpoch = _feePerEpoch;

        if (_borrower != address(0)) {
            emit SkillNFTLent(_tokenId, _owners[_tokenId], _borrower, _lendingEndTime - block.timestamp, _feePerEpoch);
        } else {
            emit SkillNFTUnlent(_tokenId);
        }
    }
}

// Dummy AttestationOracle contract
contract AttestationOracle is IAttestationOracle {
    // For demonstration purposes, all attestations are 'true'.
    // In a real application, this would involve complex logic,
    // e.g., verified credentials, ZK proofs, or a trusted committee.
    function verifyAttestation(uint256 _skillId, uint256 _level, bytes memory _proof) external pure returns (bool) {
        // Placeholder for complex verification logic
        return true;
    }

    function verifyReAttestation(uint256 _tokenId, uint256 _newLevel, bytes memory _proof) external pure returns (bool) {
        // Placeholder for complex re-verification logic
        return true;
    }
}
```