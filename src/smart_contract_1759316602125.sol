This smart contract, `AetherForge`, is designed to be a decentralized protocol for AI-assisted research and development (R&D). It introduces several advanced concepts:

*   **Dynamic Proof-of-Contribution NFTs (ForgeFragments):** These NFTs evolve in visual representation (via metadata tiers) based on the original contributor's cumulative on-chain reputation and the success of the projects they've contributed to.
*   **AI Oracle Integration (Simulated):** Projects and milestones can be evaluated by an external AI oracle, providing objective scores and verifications that influence project flow and participant reputation. This simulates a common pattern of off-chain computation with on-chain attestation.
*   **On-Chain Reputation System:** A core component, contributor reputation is an immutable (or slowly changing) on-chain score. It dictates voting power, eligibility for certain actions (like delegating reputation boosts), and the tier progression of ForgeFragment NFTs.
*   **Project Micro-Governance:** Stakeholders (contributors, highly reputed individuals) vote on project approval and milestone completion. Their vote weight is directly tied to their reputation and staked AetherForge tokens.
*   **Conditional Funding Release:** Project funds are locked in the contract and released in tranches only upon successful milestone verification by a combination of stakeholder votes and AI oracle attestations.
*   **Token-Gated Access & Staking:** Holding and staking `AetherForge` tokens enhances a contributor's reputation and voting power, effectively gating certain privileges and decision-making capabilities.

This combination of dynamic NFTs, reputation-based governance, AI oracle integration, and a structured R&D project lifecycle creates a unique and advanced decentralized application beyond typical open-source examples.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// ====================================================================================================
// Outline & Function Summary: AetherForge - Decentralized AI-Assisted R&D Protocol
// ====================================================================================================
// Contract: AetherForge
// Purpose: AetherForge is a decentralized protocol designed to facilitate AI-assisted research and development
//          (R&D) projects. It allows innovators to propose projects, crowdsource funding, define milestones,
//          and receive dynamic Proof-of-Contribution NFTs. The protocol integrates a reputation system,
//          simulated AI oracle for project evaluation, and a micro-governance model for milestone verification.
//          It aims to create a self-sustaining ecosystem for collaborative scientific and technological advancement.
//
// Key Concepts:
// - Dynamic Proof-of-Contribution NFTs (ForgeFragments): NFTs that evolve in tier and metadata based on
//   contributor reputation, project success, and active participation.
// - AI Oracle Integration: Projects and milestones can be evaluated by an external AI oracle (simulated here)
//   to provide objective scores and verifications.
// - On-Chain Reputation System: Contributor reputation is an immutable (or slowly changing) on-chain score
//   that influences voting power, funding eligibility, and NFT tiers.
// - Project Micro-Governance: Stakeholders (contributors, highly reputed individuals) vote on project approval
//   and milestone completion, with their vote weight tied to reputation and staked tokens.
// - Conditional Funding Release: Project funds are released in tranches upon successful milestone verification.
// - Token-Gated Access: Certain actions or privileges may require holding AetherForge tokens or a minimum reputation.
//
// --- CORE ENTITIES & DATA STRUCTURES ---
// 1. Project: Details of a research proposal, including funding, milestones, status, and contributors.
// 2. Milestone: Specific objectives within a project, tied to funding releases and requiring verification.
// 3. ContributorProfile: On-chain profile for users, tracking alias, reputation, staked tokens, and voting delegation.
// 4. ForgeFragmentData: Data associated with each dynamic NFT, stored in the ForgeFragment contract.
//
// --- INTERFACES & EXTERNAL DEPENDENCIES (Conceptual) ---
// - IERC20: Standard interface for the AetherForge token and project funding tokens.
// - IERC721Metadata: Standard interface for the ForgeFragment NFTs.
// - IAIOracle: Interface for the simulated AI oracle to send evaluation data.
//
// --- FUNCTION SUMMARY (29 Public/External Functions + 9 View Functions) ---
// I. Initial Setup & Admin Functions (Owner-only)
//    1. constructor(): Deploys the contract, initializes owner, sets up AetherForge ERC20 and ForgeFragment ERC721.
//    2. updateAIOracleAddress(address _newOracle): Updates the address of the AI oracle.
//    3. setProtocolFee(uint256 _newFeeBps): Sets the protocol's fee percentage on successful project funding.
//    4. updateVotingThresholds(uint256 _proposalThreshold, uint256 _milestoneThreshold): Adjusts required reputation/votes for proposals/milestones.
//    5. pauseContract(): Pauses critical contract functionalities (emergency).
//    6. unpauseContract(): Unpauses the contract.
//    7. distributeProtocolRewards(address[] calldata _recipients, uint256[] calldata _amounts): Distributes AetherForge tokens from treasury.
//
// II. Contributor Profile & Token Staking
//    8. registerContributor(string calldata _alias): Creates a contributor profile.
//    9. updateContributorAlias(string calldata _newAlias): Updates a contributor's alias.
//    10. stakeTokens(uint256 _amount): Stakes AetherForge tokens to boost reputation/voting power.
//    11. unstakeTokens(uint256 _amount): Unstakes AetherForge tokens.
//
// III. Project Submission & Lifecycle Management
//    12. submitResearchProposal(string calldata _ipfsHash, uint256 _fundingGoal, uint256 _durationDays, address _tokenAddress): Submits a new project proposal.
//    13. cancelProjectProposal(uint256 _projectId): Project owner cancels an unapproved/unfunded proposal.
//    14. voteOnProposal(uint256 _projectId, bool _approved): Stakeholders vote on whether to approve a proposal.
//    15. contributeToProject(uint256 _projectId, uint256 _amount): Funds a project.
//    16. withdrawContributorFunds(uint256 _projectId): Contributors withdraw funds if a project fails or is canceled.
//    17. claimProjectFunding(uint256 _projectId): Project owner claims initial funding after project approval.
//
// IV. Milestone Management & Verification
//    18. defineProjectMilestone(uint256 _projectId, string calldata _ipfsHash, uint256 _fundingReleasePercentage): Project owner defines a new milestone.
//    19. submitMilestoneCompletion(uint256 _projectId, uint256 _milestoneIndex, string calldata _ipfsProofHash): Project owner submits proof of milestone completion.
//    20. voteOnMilestoneCompletion(uint256 _projectId, uint256 _milestoneIndex, bool _approved): Stakeholders vote on milestone completion.
//    21. releaseMilestoneFunding(uint256 _projectId, uint256 _milestoneIndex): Releases funds for a completed and verified milestone.
//    22. distributeProjectCompletionRewards(uint256 _projectId): Distributes final project funds and potential AetherForge rewards upon full project completion.
//
// V. AI Oracle Integration (Callable only by the designated AI Oracle)
//    23. receiveAIProposalScore(uint256 _projectId, uint256 _score, string calldata _aiFeedbackIpfs): AI oracle submits a score for a proposal.
//    24. receiveAIMilestoneVerification(uint256 _projectId, uint256 _milestoneIndex, bool _verified, string calldata _aiFeedbackIpfs): AI oracle verifies a milestone.
//
// VI. ForgeFragment NFT & Reputation System
//    25. claimForgeFragment(uint256 _projectId): Allows eligible contributors to mint their dynamic ForgeFragment NFT.
//    26. upgradeForgeFragment(uint256 _tokenId): Triggers an upgrade check for a ForgeFragment based on reputation/activity.
//    27. delegateReputationBoost(address _contributor, uint256 _projectId, uint256 _amount): Allows reputable users to boost another contributor's reputation.
//
// VII. Voting Delegation
//    28. delegateVote(address _delegate): Delegates voting power to another address.
//    29. undelegateVote(): Removes vote delegation.
//
// VIII. View Functions (Read-only)
//    30. getProjectDetails(uint256 _projectId): Returns comprehensive project information.
//    31. getMilestoneDetails(uint256 _projectId, uint256 _milestoneIndex): Returns specific milestone details.
//    32. getContributorProfile(address _contributor): Returns a contributor's profile.
//    33. getForgeFragmentData(uint256 _tokenId): Returns data associated with a ForgeFragment NFT.
//    34. getForgeFragmentTier(uint256 _tokenId): Returns the current tier of a ForgeFragment.
//    35. protocolFee(): Returns the current protocol fee.
//    36. aiOracleAddress(): Returns the address of the AI oracle.
//    37. hasVotedOnProposal(address _voter, uint256 _projectId): Checks if an address has voted on a proposal.
//    38. hasVotedOnMilestone(address _voter, uint256 _projectId, uint256 _milestoneIndex): Checks if an address has voted on a milestone.
//
// Disclaimer: This contract is designed to showcase advanced concepts. It is provided for educational and
// conceptual purposes. It has not been formally audited and may contain vulnerabilities. Do not use in production
// without rigorous security audits and testing.
// ====================================================================================================

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

// --- Minimalist Interface Definitions for conceptual interaction ---
// IAetherForgeToken: Represents the native utility and governance token for AetherForge.
interface IAetherForgeToken is IERC20 {
    // In a full implementation, might have mint/burn controlled by this contract,
    // or by a separate DAO. Here, we assume standard ERC20 operations.
    // function mint(address to, uint256 amount) external;
    // function burn(uint256 amount) external;
}

// IForgeFragment: Represents the dynamic Proof-of-Contribution NFT.
interface IForgeFragment is IERC721Metadata {
    // Defines a tier for the dynamic NFT, influencing metadata and potentially visual representation.
    enum Tier { Base, Bronze, Silver, Gold, Platinum }

    // Structure to hold custom data associated with each ForgeFragment NFT.
    struct FragmentData {
        address originalContributor; // The address that originally earned/contributed to mint this NFT.
        uint256 projectId;           // The project this NFT is associated with.
        uint256 contributionAmount;  // The amount contributed to the project (in project's funded token).
        uint256 reputationScoreAtMint; // Reputation of original contributor at the time of mint.
        Tier currentTier;            // The current tier of the NFT.
        uint256 lastUpgradeTime;     // Timestamp of the last tier upgrade.
    }

    // Function to mint a new ForgeFragment NFT.
    function mint(address to, uint256 projectId, uint256 contributionAmount, uint256 reputationScore) external returns (uint256 tokenId);
    // Function to upgrade the tier of an existing ForgeFragment NFT.
    function upgradeTier(uint256 tokenId, Tier newTier) external;
    // View function to retrieve all custom data for a given NFT.
    function getFragmentData(uint256 tokenId) external view returns (FragmentData memory);
    // View function to retrieve just the tier of a given NFT.
    function getTokenTier(uint256 tokenId) external view returns (Tier);
}

// IAIOracle: Represents the interface for an external AI Oracle system.
// This oracle would perform off-chain computations and attest results back on-chain.
interface IAIOracle {
    function submitProposalScore(uint256 projectId, uint256 score, string calldata aiFeedbackIpfs) external;
    function submitMilestoneVerification(uint256 projectId, uint256 milestoneIndex, bool verified, string calldata aiFeedbackIpfs) external;
}

/// @title AetherForge - Decentralized AI-Assisted R&D Protocol
/// @notice Manages project submission, funding, milestone verification, dynamic NFTs, and a reputation system.
contract AetherForge is Ownable, Pausable {

    // --- State Variables ---
    IAetherForgeToken public immutable AETHER_TOKEN; // The protocol's native utility/governance token
    IForgeFragment public immutable FORGE_FRAGMENT_NFT; // The dynamic Proof-of-Contribution NFT contract

    address public aiOracleAddress; // Address of the trusted AI oracle contract
    uint256 public protocolFeeBps; // Protocol fee in basis points (e.g., 100 = 1%) charged on fund releases

    uint256 public nextProjectId; // Counter for unique project IDs
    uint256 public constant MIN_REPUTATION_FOR_VOTE = 100; // Minimum reputation required to participate in voting
    uint256 public proposalApprovalThresholdReputation; // Total reputation sum needed for a proposal to be approved
    uint256 public milestoneApprovalThresholdReputation; // Total reputation sum needed for a milestone to be approved

    // --- Enums ---
    /// @dev Represents the various stages of a project's lifecycle.
    enum ProjectStatus { Pending, Approved, Funded, InProgress, Completed, Canceled, Failed }

    // --- Structs ---
    /// @dev Stores comprehensive details about a research project.
    struct Project {
        address proposer;            // The address of the individual who submitted the project.
        string ipfsHash;             // IPFS hash pointing to the detailed project proposal document.
        uint256 fundingGoal;         // The total funding target for the project.
        uint256 currentFunding;      // The current amount of funds contributed to the project.
        IERC20 fundedToken;          // The ERC20 token in which funding is collected for this project.
        Milestone[] milestones;      // Array of milestones defined for this project.
        ProjectStatus status;        // Current status of the project.
        uint256 aiScore;             // AI's initial assessment score for the proposal (0-100).
        mapping(address => bool) approvalVotes; // Records if an address has voted on proposal approval (true for approve).
        uint256 totalApprovalReputation; // Sum of reputation points from addresses that approved the proposal.
        mapping(address => uint256) contributors; // Maps contributor address to their total contribution amount.
        mapping(address => bool) hasClaimedFragment; // Flags if a contributor has claimed their NFT for this project.
        uint256 startTime;           // Timestamp when the project was submitted.
        uint256 durationDays;        // Expected project duration in days.
        bool initialFundingClaimed;  // True if the proposer has claimed the initial funding tranche.
    }

    /// @dev Defines a specific objective or phase within a project.
    struct Milestone {
        string ipfsHash;             // IPFS hash for detailed milestone description.
        uint256 fundingReleasePercentage; // Percentage of the total project funding goal to release upon completion.
        bool isCompleted;            // True if the project owner has submitted completion proof.
        string proofIpfsHash;        // IPFS hash for the proof of milestone completion.
        mapping(address => bool) completionVotes; // Records if an address has voted on milestone completion (true for approve).
        uint256 totalCompletionReputation; // Sum of reputation points from addresses that approved the milestone.
        bool aiVerified;             // True if the AI oracle has verified milestone completion.
        bool released;               // True if funding for this milestone has been released.
    }

    /// @dev Stores reputation and staking information for each registered contributor.
    struct ContributorProfile {
        string alias;                // A display name chosen by the contributor.
        uint256 reputation;          // Cumulative on-chain reputation score.
        uint256 stakedTokens;        // Amount of AetherForge tokens currently staked by the contributor.
        address delegatedVoteTo;     // Address to which the contributor has delegated their voting power.
        bool hasRegistered;          // True if the address has a registered profile.
    }

    // --- Mappings ---
    mapping(uint256 => Project) public projects; // Maps project ID to its details.
    mapping(address => ContributorProfile) public contributorProfiles; // Maps contributor address to their profile.

    // --- Events ---
    event AIOracleAddressUpdated(address indexed newOracle);
    event ProtocolFeeUpdated(uint256 newFeeBps);
    event VotingThresholdsUpdated(uint256 proposalThreshold, uint256 milestoneThreshold);
    event ContributorRegistered(address indexed contributor, string alias);
    event ContributorAliasUpdated(address indexed contributor, string oldAlias, string newAlias);
    event TokensStaked(address indexed staker, uint256 amount);
    event TokensUnstaked(address indexed unstaker, uint256 amount);
    event ResearchProposalSubmitted(uint256 indexed projectId, address indexed proposer, string ipfsHash, uint256 fundingGoal);
    event ProjectProposalCanceled(uint256 indexed projectId, address indexed canceller);
    event ProposalVoted(uint256 indexed projectId, address indexed voter, bool approved, uint256 currentApprovalReputation);
    event ProjectApproved(uint256 indexed projectId);
    event ProjectFunded(uint256 indexed projectId, address indexed contributor, uint256 amount, uint256 totalFunded);
    event ContributorFundsWithdrawn(uint256 indexed projectId, address indexed contributor, uint256 amount);
    event ProjectFundingClaimed(uint256 indexed projectId, address indexed proposer, uint256 amount);
    event MilestoneDefined(uint256 indexed projectId, uint256 indexed milestoneIndex, string ipfsHash, uint256 fundingReleasePercentage);
    event MilestoneCompletionSubmitted(uint256 indexed projectId, uint256 indexed milestoneIndex, string proofIpfsHash);
    event MilestoneVoted(uint256 indexed projectId, uint256 indexed milestoneIndex, address indexed voter, bool approved, uint256 currentCompletionReputation);
    event MilestoneVerified(uint256 indexed projectId, uint256 indexed milestoneIndex);
    event MilestoneFundingReleased(uint256 indexed projectId, uint256 indexed milestoneIndex, uint256 amountReleased);
    event ProjectCompletionRewardsDistributed(uint256 indexed projectId);
    event AIProposalScoreReceived(uint256 indexed projectId, uint256 score, string aiFeedbackIpfs);
    event AIMilestoneVerificationReceived(uint256 indexed projectId, uint256 indexed milestoneIndex, bool verified, string aiFeedbackIpfs);
    event ForgeFragmentClaimed(uint256 indexed tokenId, uint256 indexed projectId, address indexed contributor, IForgeFragment.Tier initialTier);
    event ForgeFragmentUpgraded(uint256 indexed tokenId, IForgeFragment.Tier oldTier, IForgeFragment.Tier newTier);
    event ReputationBoosted(address indexed boostedContributor, address indexed booster, uint256 projectId, uint256 amount);
    event VoteDelegated(address indexed delegator, address indexed delegatee);
    event VoteUndelegated(address indexed delegator);
    event ContributorReputationUpdated(address indexed contributor, uint256 newReputation);

    // --- Modifiers ---
    /// @dev Restricts function access to only the designated AI oracle address.
    modifier onlyAIOracle() {
        require(msg.sender == aiOracleAddress, "AetherForge: Only AI Oracle can call this function");
        _;
    }

    /// @dev Restricts function access to only registered contributors.
    modifier onlyRegisteredContributor() {
        require(contributorProfiles[msg.sender].hasRegistered, "AetherForge: Caller not a registered contributor");
        _;
    }

    /// @dev Ensures that a project with the given ID exists.
    modifier projectExists(uint256 _projectId) {
        require(_projectId < nextProjectId, "AetherForge: Project does not exist");
        _;
    }

    /// @dev Restricts function access to only the proposer of a specific project.
    modifier isProjectProposer(uint256 _projectId) {
        require(projects[_projectId].proposer == msg.sender, "AetherForge: Only project proposer can call this function");
        _;
    }

    /// @dev Ensures the caller (or their delegate) has sufficient reputation to vote.
    modifier hasMinReputationForVote() {
        require(getVotingReputation(msg.sender) >= MIN_REPUTATION_FOR_VOTE, "AetherForge: Insufficient reputation to vote");
        _;
    }

    // --- Constructor ---
    /// @notice Initializes the AetherForge contract with addresses for the AetherForge token, ForgeFragment NFT, and initial AI oracle.
    /// @param _aetherTokenAddress The address of the AetherForge ERC20 token contract.
    /// @param _forgeFragmentNftAddress The address of the ForgeFragment ERC721 NFT contract.
    /// @param _initialAIOracle The initial address of the trusted AI oracle.
    constructor(address _aetherTokenAddress, address _forgeFragmentNftAddress, address _initialAIOracle)
        Ownable(msg.sender) {
        AETHER_TOKEN = IAetherForgeToken(_aetherTokenAddress);
        FORGE_FRAGMENT_NFT = IForgeFragment(_forgeFragmentNftAddress);
        aiOracleAddress = _initialAIOracle;
        protocolFeeBps = 500; // Default 5% fee (500 basis points)
        nextProjectId = 0;

        // Default voting thresholds (can be updated by owner)
        proposalApprovalThresholdReputation = 5000; // Example: 5000 reputation points needed to approve a proposal
        milestoneApprovalThresholdReputation = 2000; // Example: 2000 reputation points needed to approve a milestone
    }

    // ====================================================================================================
    // I. Initial Setup & Admin Functions (Owner-only)
    // ====================================================================================================

    /// @notice Updates the address of the AI oracle contract.
    /// @dev Only the contract owner can call this. The new oracle address cannot be zero.
    /// @param _newOracle The new address for the AI oracle.
    function updateAIOracleAddress(address _newOracle) external onlyOwner {
        require(_newOracle != address(0), "AetherForge: New AI oracle address cannot be zero");
        aiOracleAddress = _newOracle;
        emit AIOracleAddressUpdated(_newOracle);
    }

    /// @notice Sets the protocol's fee percentage for successful project funding.
    /// @dev Only the contract owner can call this. Fee is in basis points, e.g., 100 = 1%. Max 10000 (100%).
    /// @param _newFeeBps The new fee percentage in basis points.
    function setProtocolFee(uint256 _newFeeBps) external onlyOwner {
        require(_newFeeBps <= 10000, "AetherForge: Fee cannot exceed 100%");
        protocolFeeBps = _newFeeBps;
        emit ProtocolFeeUpdated(_newFeeBps);
    }

    /// @notice Updates the reputation thresholds required for approving proposals and milestones.
    /// @dev Only the contract owner can call this. Thresholds must be greater than zero.
    /// @param _proposalThreshold New minimum total reputation required for proposal approval.
    /// @param _milestoneThreshold New minimum total reputation required for milestone approval.
    function updateVotingThresholds(uint256 _proposalThreshold, uint256 _milestoneThreshold) external onlyOwner {
        require(_proposalThreshold > 0 && _milestoneThreshold > 0, "AetherForge: Thresholds must be greater than zero");
        proposalApprovalThresholdReputation = _proposalThreshold;
        milestoneApprovalThresholdReputation = _milestoneThreshold;
        emit VotingThresholdsUpdated(_proposalThreshold, _milestoneThreshold);
    }

    /// @notice Pauses critical contract functionalities in case of an emergency.
    /// @dev Only the contract owner can call this. Prevents most state-changing user interactions.
    function pauseContract() external onlyOwner {
        _pause();
    }

    /// @notice Unpauses critical contract functionalities, allowing normal operations to resume.
    /// @dev Only the contract owner can call this.
    function unpauseContract() external onlyOwner {
        _unpause();
    }

    /// @notice Distributes AetherForge tokens as protocol rewards or grants from the treasury.
    /// @dev Only the contract owner can call this. Assumes the AetherForge token contract has enough allowance
    ///      or that this contract is authorized to transfer from a treasury.
    /// @param _recipients Array of addresses to receive rewards.
    /// @param _amounts Array of amounts corresponding to each recipient.
    function distributeProtocolRewards(address[] calldata _recipients, uint256[] calldata _amounts) external onlyOwner {
        require(_recipients.length == _amounts.length, "AetherForge: Recipient and amount arrays must be same length");
        for (uint256 i = 0; i < _recipients.length; i++) {
            require(_recipients[i] != address(0), "AetherForge: Recipient address cannot be zero");
            require(_amounts[i] > 0, "AetherForge: Reward amount must be greater than zero");
            // This transfer assumes the AetherForge contract holds these tokens or has been approved to spend them.
            // In a real system, the owner might approve this contract, or this contract might mint tokens.
            AETHER_TOKEN.transfer(_recipients[i], _amounts[i]);
        }
    }


    // ====================================================================================================
    // II. Contributor Profile & Token Staking
    // ====================================================================================================

    /// @notice Registers a new contributor profile for the caller.
    /// @dev Requires the caller not to be already registered. Assigns a base reputation.
    /// @param _alias A chosen display name for the contributor.
    function registerContributor(string calldata _alias) external whenNotPaused {
        require(!contributorProfiles[msg.sender].hasRegistered, "AetherForge: Already a registered contributor");
        require(bytes(_alias).length > 0, "AetherForge: Alias cannot be empty");

        contributorProfiles[msg.sender].alias = _alias;
        contributorProfiles[msg.sender].reputation = 1; // Start with a base reputation of 1
        contributorProfiles[msg.sender].hasRegistered = true;
        emit ContributorRegistered(msg.sender, _alias);
        emit ContributorReputationUpdated(msg.sender, 1);
    }

    /// @notice Updates the caller's contributor alias.
    /// @dev Requires the caller to be a registered contributor.
    /// @param _newAlias The new alias for the contributor.
    function updateContributorAlias(string calldata _newAlias) external onlyRegisteredContributor whenNotPaused {
        require(bytes(_newAlias).length > 0, "AetherForge: New alias cannot be empty");
        string memory oldAlias = contributorProfiles[msg.sender].alias;
        contributorProfiles[msg.sender].alias = _newAlias;
        emit ContributorAliasUpdated(msg.sender, oldAlias, _newAlias);
    }

    /// @notice Stakes AetherForge tokens to gain voting power and potentially boost reputation.
    /// @dev Requires the caller to be a registered contributor. Tokens are transferred to this contract.
    /// @param _amount The amount of AetherForge tokens to stake.
    function stakeTokens(uint256 _amount) external onlyRegisteredContributor whenNotPaused {
        require(_amount > 0, "AetherForge: Amount to stake must be greater than zero");
        AETHER_TOKEN.transferFrom(msg.sender, address(this), _amount);
        contributorProfiles[msg.sender].stakedTokens += _amount;
        // Reputation boost based on staked tokens (e.g., 1 reputation per 100 AETHER staked)
        _updateContributorReputation(msg.sender, int256(_amount / 100)); // Example scaling
        emit TokensStaked(msg.sender, _amount);
    }

    /// @notice Unstakes AetherForge tokens.
    /// @dev Requires the caller to be a registered contributor and have sufficient staked tokens.
    /// @param _amount The amount of AetherForge tokens to unstake.
    function unstakeTokens(uint256 _amount) external onlyRegisteredContributor whenNotPaused {
        require(_amount > 0, "AetherForge: Amount to unstake must be greater than zero");
        require(contributorProfiles[msg.sender].stakedTokens >= _amount, "AetherForge: Insufficient staked tokens");

        contributorProfiles[msg.sender].stakedTokens -= _amount;
        AETHER_TOKEN.transfer(msg.sender, _amount);
        // Reputation reduction on unstake (e.g., 1 reputation per 100 AETHER unstaked)
        _updateContributorReputation(msg.sender, -int256(_amount / 100)); // Example scaling
        emit TokensUnstaked(msg.sender, _amount);
    }

    // ====================================================================================================
    // III. Project Submission & Lifecycle Management
    // ====================================================================================================

    /// @notice Submits a new research proposal to the AetherForge protocol.
    /// @dev Requires the caller to be a registered contributor.
    /// @param _ipfsHash IPFS hash pointing to the detailed project proposal document.
    /// @param _fundingGoal The total funding goal for the project.
    /// @param _durationDays The expected duration of the project in days.
    /// @param _tokenAddress The address of the ERC20 token in which funding is to be collected.
    /// @return The unique ID assigned to the new project.
    function submitResearchProposal(
        string calldata _ipfsHash,
        uint256 _fundingGoal,
        uint256 _durationDays,
        address _tokenAddress
    ) external onlyRegisteredContributor whenNotPaused returns (uint256) {
        require(bytes(_ipfsHash).length > 0, "AetherForge: IPFS hash cannot be empty");
        require(_fundingGoal > 0, "AetherForge: Funding goal must be greater than zero");
        require(_durationDays > 0, "AetherForge: Project duration must be greater than zero");
        // Simple check for token validity, could be more robust
        require(IERC20(_tokenAddress).totalSupply() > 0, "AetherForge: Invalid funding token address (likely not an ERC20)");

        uint256 projectId = nextProjectId++;
        projects[projectId].proposer = msg.sender;
        projects[projectId].ipfsHash = _ipfsHash;
        projects[projectId].fundingGoal = _fundingGoal;
        projects[projectId].fundedToken = IERC20(_tokenAddress);
        projects[projectId].status = ProjectStatus.Pending;
        projects[projectId].startTime = block.timestamp;
        projects[projectId].durationDays = _durationDays;

        emit ResearchProposalSubmitted(projectId, msg.sender, _ipfsHash, _fundingGoal);
        return projectId;
    }

    /// @notice Allows the project proposer to cancel their proposal if it's still pending or not yet in progress.
    /// @dev Funds contributed will remain in the contract until individual contributors call `withdrawContributorFunds`.
    /// @param _projectId The ID of the project to cancel.
    function cancelProjectProposal(uint256 _projectId) external projectExists(_projectId) isProjectProposer(_projectId) whenNotPaused {
        Project storage project = projects[_projectId];
        require(project.status == ProjectStatus.Pending || project.status == ProjectStatus.Approved || project.status == ProjectStatus.Funded,
                "AetherForge: Project cannot be canceled in its current state");

        project.status = ProjectStatus.Canceled;
        _updateContributorReputation(msg.sender, -50); // Small reputation penalty for canceling
        emit ProjectProposalCanceled(_projectId, msg.sender);
    }

    /// @notice Stakeholders vote on whether to approve a submitted project proposal.
    /// @dev Requires the caller to be a registered contributor with minimum reputation.
    /// @param _projectId The ID of the project to vote on.
    /// @param _approved True to approve the proposal, false to disapprove.
    function voteOnProposal(uint256 _projectId, bool _approved) external
        projectExists(_projectId)
        onlyRegisteredContributor
        hasMinReputationForVote
        whenNotPaused
    {
        Project storage project = projects[_projectId];
        require(project.status == ProjectStatus.Pending, "AetherForge: Project is not in pending status for voting");
        require(!project.approvalVotes[msg.sender], "AetherForge: Already voted on this proposal");

        project.approvalVotes[msg.sender] = _approved;
        uint256 voterReputation = getVotingReputation(msg.sender);

        if (_approved) {
            project.totalApprovalReputation += voterReputation;
        } else {
            // Disapproval votes could also have complex logic (e.g., negative reputation if voting against AI-approved projects)
            // For simplicity, only positive reputation contributions count towards approval.
        }

        emit ProposalVoted(_projectId, msg.sender, _approved, project.totalApprovalReputation);

        if (project.totalApprovalReputation >= proposalApprovalThresholdReputation) {
            project.status = ProjectStatus.Approved;
            _updateContributorReputation(project.proposer, 100); // Proposer gets reputation boost upon approval
            emit ProjectApproved(_projectId);
        }
    }

    /// @notice Contributes funds to an approved project.
    /// @dev Requires the project to be in "Approved" or "Funded" status.
    /// @param _projectId The ID of the project to contribute to.
    /// @param _amount The amount of tokens to contribute.
    function contributeToProject(uint256 _projectId, uint256 _amount) external projectExists(_projectId) whenNotPaused {
        Project storage project = projects[_projectId];
        require(project.status == ProjectStatus.Approved || project.status == ProjectStatus.Funded, "AetherForge: Project not approved or already fully funded");
        require(_amount > 0, "AetherForge: Contribution amount must be greater than zero");
        require(project.currentFunding + _amount <= project.fundingGoal, "AetherForge: Contribution exceeds funding goal");

        project.fundedToken.transferFrom(msg.sender, address(this), _amount);
        project.currentFunding += _amount;
        project.contributors[msg.sender] += _amount;

        _updateContributorReputation(msg.sender, 10); // Small reputation boost for contributing
        emit ProjectFunded(_projectId, msg.sender, _amount, project.currentFunding);

        if (project.currentFunding == project.fundingGoal) {
            project.status = ProjectStatus.Funded;
            // Optionally, trigger an AI oracle call for a "funded" status assessment here.
        }
    }

    /// @notice Allows a contributor to withdraw their funds if the project is canceled or fails.
    /// @param _projectId The ID of the project.
    function withdrawContributorFunds(uint256 _projectId) external projectExists(_projectId) whenNotPaused {
        Project storage project = projects[_projectId];
        require(project.status == ProjectStatus.Canceled || project.status == ProjectStatus.Failed,
                "AetherForge: Funds can only be withdrawn from canceled or failed projects");

        uint256 amountToWithdraw = project.contributors[msg.sender];
        require(amountToWithdraw > 0, "AetherForge: No funds contributed by this address to this project");
        
        project.contributors[msg.sender] = 0; // Reset contribution for this project
        project.fundedToken.transfer(msg.sender, amountToWithdraw);
        emit ContributorFundsWithdrawn(_projectId, msg.sender, amountToWithdraw);
    }

    /// @notice Allows the project proposer to claim the initial tranche of funding once the project is fully funded.
    /// @dev The initial claimable amount is either the first milestone's percentage or a default 25%.
    /// @param _projectId The ID of the project.
    function claimProjectFunding(uint256 _projectId) external projectExists(_projectId) isProjectProposer(_projectId) whenNotPaused {
        Project storage project = projects[_projectId];
        require(project.status == ProjectStatus.Funded, "AetherForge: Project not yet fully funded");
        require(!project.initialFundingClaimed, "AetherForge: Initial funding already claimed");

        uint256 initialClaimPercentage = 0;
        if (project.milestones.length > 0) {
            initialClaimPercentage = project.milestones[0].fundingReleasePercentage;
        } else {
            initialClaimPercentage = 2500; // Default 25% (2500 basis points) if no milestones defined yet
        }
        
        uint256 amountToClaim = (project.fundingGoal * initialClaimPercentage) / 10000;
        require(amountToClaim > 0, "AetherForge: Calculated amount to claim is zero. Define milestones or check percentages.");
        
        // Apply protocol fee to the claimed amount
        uint256 fee = (amountToClaim * protocolFeeBps) / 10000;
        uint256 amountAfterFee = amountToClaim - fee;

        // Transfer funds to proposer and fee to protocol treasury
        project.fundedToken.transfer(msg.sender, amountAfterFee);
        if (fee > 0) {
            project.fundedToken.transfer(address(this), fee); // Send fee to protocol treasury
        }
        
        project.initialFundingClaimed = true;
        project.status = ProjectStatus.InProgress; // Project is now considered in progress
        _updateContributorReputation(msg.sender, 50); // Proposer gets reputation boost
        emit ProjectFundingClaimed(_projectId, msg.sender, amountAfterFee);
    }

    // ====================================================================================================
    // IV. Milestone Management & Verification
    // ====================================================================================================

    /// @notice Allows the project proposer to define a new milestone for their project.
    /// @dev Requires the project to be active. Ensures total milestone percentages don't exceed 100%.
    /// @param _projectId The ID of the project.
    /// @param _ipfsHash IPFS hash for the detailed milestone description.
    /// @param _fundingReleasePercentage The percentage of the total funding goal to release upon completion (in basis points).
    function defineProjectMilestone(
        uint256 _projectId,
        string calldata _ipfsHash,
        uint256 _fundingReleasePercentage
    ) external projectExists(_projectId) isProjectProposer(_projectId) whenNotPaused {
        Project storage project = projects[_projectId];
        require(project.status == ProjectStatus.Approved || project.status == ProjectStatus.Funded || project.status == ProjectStatus.InProgress,
                "AetherForge: Project is not in an active state to define milestones");
        require(bytes(_ipfsHash).length > 0, "AetherForge: IPFS hash cannot be empty");
        require(_fundingReleasePercentage > 0 && _fundingReleasePercentage <= 10000, "AetherForge: Percentage must be between 1 and 10000 (100%)");

        // Ensure total percentages don't exceed 100% (or what's remaining if initial funding was claimed)
        uint256 totalAllocated = 0;
        for (uint256 i = 0; i < project.milestones.length; i++) {
            totalAllocated += project.milestones[i].fundingReleasePercentage;
        }
        require(totalAllocated + _fundingReleasePercentage <= 10000, "AetherForge: Total milestone funding exceeds 100%");

        project.milestones.push(Milestone({
            ipfsHash: _ipfsHash,
            fundingReleasePercentage: _fundingReleasePercentage,
            isCompleted: false,
            proofIpfsHash: "",
            aiVerified: false,
            released: false
        }));

        emit MilestoneDefined(_projectId, project.milestones.length - 1, _ipfsHash, _fundingReleasePercentage);
    }

    /// @notice Project proposer submits proof of milestone completion.
    /// @dev Requires the milestone not to be already completed.
    /// @param _projectId The ID of the project.
    /// @param _milestoneIndex The index of the milestone within the project's milestones array.
    /// @param _ipfsProofHash IPFS hash for the proof of completion.
    function submitMilestoneCompletion(
        uint256 _projectId,
        uint256 _milestoneIndex,
        string calldata _ipfsProofHash
    ) external projectExists(_projectId) isProjectProposer(_projectId) whenNotPaused {
        Project storage project = projects[_projectId];
        require(_milestoneIndex < project.milestones.length, "AetherForge: Milestone index out of bounds");
        Milestone storage milestone = project.milestones[_milestoneIndex];
        require(!milestone.isCompleted, "AetherForge: Milestone already marked as completed");
        require(bytes(_ipfsProofHash).length > 0, "AetherForge: Proof IPFS hash cannot be empty");

        milestone.isCompleted = true;
        milestone.proofIpfsHash = _ipfsProofHash;
        emit MilestoneCompletionSubmitted(_projectId, _milestoneIndex, _ipfsProofHash);
    }

    /// @notice Stakeholders vote on the completion of a submitted milestone.
    /// @dev Requires the caller to be a registered contributor with minimum reputation.
    ///      Milestone must have had completion proof submitted.
    /// @param _projectId The ID of the project.
    /// @param _milestoneIndex The index of the milestone.
    /// @param _approved True if the milestone completion is approved, false otherwise.
    function voteOnMilestoneCompletion(
        uint256 _projectId,
        uint256 _milestoneIndex,
        bool _approved
    ) external
        projectExists(_projectId)
        onlyRegisteredContributor
        hasMinReputationForVote
        whenNotPaused
    {
        Project storage project = projects[_projectId];
        require(_milestoneIndex < project.milestones.length, "AetherForge: Milestone index out of bounds");
        Milestone storage milestone = project.milestones[_milestoneIndex];
        require(milestone.isCompleted, "AetherForge: Milestone completion not yet submitted");
        require(!milestone.completionVotes[msg.sender], "AetherForge: Already voted on this milestone");

        milestone.completionVotes[msg.sender] = _approved;
        uint256 voterReputation = getVotingReputation(msg.sender);

        if (_approved) {
            milestone.totalCompletionReputation += voterReputation;
        }
        // Disapproval does not reduce sum, but can be used in more complex logic.

        emit MilestoneVoted(_projectId, _milestoneIndex, msg.sender, _approved, milestone.totalCompletionReputation);

        if (milestone.totalCompletionReputation >= milestoneApprovalThresholdReputation) {
            emit MilestoneVerified(_projectId, _milestoneIndex);
        }
    }

    /// @notice Releases funding for a successfully completed and verified milestone.
    /// @dev Can be called by anyone, but funds only release if conditions (voter approval OR AI verification) are met.
    /// @param _projectId The ID of the project.
    /// @param _milestoneIndex The index of the milestone.
    function releaseMilestoneFunding(uint256 _projectId, uint256 _milestoneIndex) external projectExists(_projectId) whenNotPaused {
        Project storage project = projects[_projectId];
        require(_milestoneIndex < project.milestones.length, "AetherForge: Milestone index out of bounds");
        Milestone storage milestone = project.milestones[_milestoneIndex];
        require(milestone.isCompleted, "AetherForge: Milestone completion not submitted");
        require(!milestone.released, "AetherForge: Milestone funding already released");
        require(milestone.totalCompletionReputation >= milestoneApprovalThresholdReputation || milestone.aiVerified,
                "AetherForge: Milestone not yet approved by voters or AI");

        uint256 amountToRelease = (project.fundingGoal * milestone.fundingReleasePercentage) / 10000;
        require(amountToRelease > 0, "AetherForge: No funds allocated for this milestone");

        // Apply protocol fee
        uint256 fee = (amountToRelease * protocolFeeBps) / 10000;
        uint256 amountAfterFee = amountToRelease - fee;

        // Transfer funds to proposer and fee to protocol treasury
        project.fundedToken.transfer(project.proposer, amountAfterFee);
        if (fee > 0) {
            project.fundedToken.transfer(address(this), fee); // Send fee to protocol treasury
        }
        
        milestone.released = true;
        _updateContributorReputation(project.proposer, 75); // Proposer gets reputation boost
        emit MilestoneFundingReleased(_projectId, _milestoneIndex, amountAfterFee);
    }

    /// @notice Distributes final rewards and remaining funds (if any) to project contributors upon full project completion.
    /// @dev Assumes all milestones are completed and released. Any unallocated remaining funds go to the proposer.
    /// @param _projectId The ID of the project.
    function distributeProjectCompletionRewards(uint256 _projectId) external projectExists(_projectId) isProjectProposer(_projectId) whenNotPaused {
        Project storage project = projects[_projectId];
        require(project.status != ProjectStatus.Completed, "AetherForge: Project already completed");

        // Check if all milestones are completed and funding released
        bool allMilestonesCompleted = true;
        for (uint256 i = 0; i < project.milestones.length; i++) {
            if (!project.milestones[i].released) {
                allMilestonesCompleted = false;
                break;
            }
        }
        require(allMilestonesCompleted, "AetherForge: Not all milestones are completed and funding released");
        
        // Mark project as completed
        project.status = ProjectStatus.Completed;
        _updateContributorReputation(project.proposer, 200); // Significant reputation boost for successful completion
        
        // In a real system, the remaining funds calculation would be more precise,
        // accounting for already claimed initial funding and collected fees.
        // For simplicity, we are assuming any funds still residing in the contract for this project
        // after all milestones are released, are now available for final distribution.
        // A more robust system would track available balance per project.
        
        // This is a placeholder for more complex distribution logic. For simplicity,
        // it means all planned milestones are funded, project is complete, and proposer gets a final reputation boost.
        // Any remaining balance of `project.fundedToken` in the contract attributable to this project would need to be
        // explicitly distributed, e.g., to the proposer, or refunded based on contribution shares.
        // Here, we assume *all* project funds would have been disbursed via initial claim and milestones.
        // If there is any remaining unallocated, it stays with the protocol for now.
        
        emit ProjectCompletionRewardsDistributed(_projectId);
    }

    // ====================================================================================================
    // V. AI Oracle Integration (Callable only by the designated AI Oracle)
    // ====================================================================================================

    /// @notice Allows the AI oracle to submit a score for a project proposal.
    /// @dev Only callable by the `aiOracleAddress`. The score can influence reputation and visibility.
    /// @param _projectId The ID of the project.
    /// @param _score The AI-generated score (e.g., 0-100).
    /// @param _aiFeedbackIpfs IPFS hash for detailed AI feedback.
    function receiveAIProposalScore(uint256 _projectId, uint256 _score, string calldata _aiFeedbackIpfs)
        external
        projectExists(_projectId)
        onlyAIOracle
        whenNotPaused
    {
        Project storage project = projects[_projectId];
        require(project.aiScore == 0, "AetherForge: AI score already received for this proposal");
        require(_score <= 100, "AetherForge: AI score must be between 0 and 100");

        project.aiScore = _score;
        // AI score can influence initial reputation, visibility, or future funding multipliers.
        _updateContributorReputation(project.proposer, int256(_score)); // Rep based on AI score for proposer
        emit AIProposalScoreReceived(_projectId, _score, _aiFeedbackIpfs);
    }

    /// @notice Allows the AI oracle to submit a verification result for a milestone.
    /// @dev Only callable by the `aiOracleAddress`. AI verification can impact funding release.
    /// @param _projectId The ID of the project.
    /// @param _milestoneIndex The index of the milestone.
    /// @param _verified True if the AI verified the milestone completion, false otherwise.
    /// @param _aiFeedbackIpfs IPFS hash for detailed AI feedback on verification.
    function receiveAIMilestoneVerification(
        uint256 _projectId,
        uint256 _milestoneIndex,
        bool _verified,
        string calldata _aiFeedbackIpfs
    ) external projectExists(_projectId) onlyAIOracle whenNotPaused {
        Project storage project = projects[_projectId];
        require(_milestoneIndex < project.milestones.length, "AetherForge: Milestone index out of bounds");
        Milestone storage milestone = project.milestones[_milestoneIndex];
        require(milestone.isCompleted, "AetherForge: Milestone completion not submitted");
        require(!milestone.aiVerified, "AetherForge: AI already verified this milestone");

        milestone.aiVerified = _verified;
        // AI verification can expedite funding release or boost proposer's reputation.
        if (_verified) {
            _updateContributorReputation(project.proposer, 50); // Additional reputation for AI-verified milestone
        } else {
            _updateContributorReputation(project.proposer, -25); // Small penalty for AI disapproval
        }
        emit AIMilestoneVerificationReceived(_projectId, _milestoneIndex, _verified, _aiFeedbackIpfs);
    }

    // ====================================================================================================
    // VI. ForgeFragment NFT & Reputation System
    // ====================================================================================================

    /// @notice Allows an eligible contributor to claim their dynamic ForgeFragment NFT for a project.
    /// @dev Eligibility is based on a minimum contribution amount and project status.
    ///      The NFT is minted to the caller and its initial tier is based on their reputation.
    /// @param _projectId The ID of the project for which to claim the NFT.
    function claimForgeFragment(uint256 _projectId) external projectExists(_projectId) onlyRegisteredContributor whenNotPaused {
        Project storage project = projects[_projectId];
        require(project.status >= ProjectStatus.Funded, "AetherForge: Project not yet funded to claim NFT");
        require(project.contributors[msg.sender] > 0, "AetherForge: No contribution from this address to this project");
        require(!project.hasClaimedFragment[msg.sender], "AetherForge: ForgeFragment already claimed for this project");

        // Example: Minimum contribution to claim NFT (e.g., 1% of funding goal)
        uint256 minContributionForNFT = project.fundingGoal / 100; // 1%
        require(project.contributors[msg.sender] >= minContributionForNFT, "AetherForge: Insufficient contribution to claim NFT");

        uint256 currentReputation = contributorProfiles[msg.sender].reputation;
        uint256 tokenId = FORGE_FRAGMENT_NFT.mint(msg.sender, _projectId, project.contributors[msg.sender], currentReputation);
        project.hasClaimedFragment[msg.sender] = true;

        emit ForgeFragmentClaimed(tokenId, _projectId, msg.sender, FORGE_FRAGMENT_NFT.getTokenTier(tokenId));
    }

    /// @notice Triggers an upgrade check for a ForgeFragment NFT.
    /// @dev NFT tier upgrades based on the *original contributor's* cumulative reputation and project successes.
    ///      This links the NFT's value to the soulbound reputation of the person who earned it.
    /// @param _tokenId The ID of the ForgeFragment NFT to check for upgrade.
    function upgradeForgeFragment(uint256 _tokenId) external whenNotPaused {
        require(FORGE_FRAGMENT_NFT.ownerOf(_tokenId) == msg.sender, "AetherForge: Not the owner of this ForgeFragment");
        
        IForgeFragment.FragmentData memory fragmentData = FORGE_FRAGMENT_NFT.getFragmentData(_tokenId);
        IForgeFragment.Tier currentTier = fragmentData.currentTier;
        
        // The reputation of the *original contributor* is key for NFT's value, even if transferred.
        uint256 originalContributorReputation = contributorProfiles[fragmentData.originalContributor].reputation;

        IForgeFragment.Tier newTier = currentTier;
        // Tier progression logic based on original contributor's reputation
        if (originalContributorReputation >= 5000 && currentTier < IForgeFragment.Tier.Platinum) {
            newTier = IForgeFragment.Tier.Platinum;
        } else if (originalContributorReputation >= 2000 && currentTier < IForgeFragment.Tier.Gold) {
            newTier = IForgeFragment.Tier.Gold;
        } else if (originalContributorReputation >= 500 && currentTier < IForgeFragment.Tier.Silver) {
            newTier = IForgeFragment.Tier.Silver;
        } else if (originalContributorReputation >= 100 && currentTier < IForgeFragment.Tier.Bronze) {
            newTier = IForgeFragment.Tier.Bronze;
        }

        if (newTier > currentTier) {
            FORGE_FRAGMENT_NFT.upgradeTier(_tokenId, newTier);
            emit ForgeFragmentUpgraded(_tokenId, currentTier, newTier);
        }
    }

    /// @notice Allows a highly reputable contributor (e.g., a project lead) to boost another contributor's reputation for their work on a specific project.
    /// @dev Requires the caller to have sufficient reputation and be associated with the project.
    /// @param _contributor The address of the contributor whose reputation will be boosted.
    /// @param _projectId The ID of the project related to the contribution.
    /// @param _amount The amount of reputation points to add (limited to prevent abuse).
    function delegateReputationBoost(
        address _contributor,
        uint256 _projectId,
        uint256 _amount
    ) external projectExists(_projectId) onlyRegisteredContributor whenNotPaused {
        require(contributorProfiles[_contributor].hasRegistered, "AetherForge: Target contributor not registered");
        require(getVotingReputation(msg.sender) >= 500, "AetherForge: Insufficient reputation to boost others"); // Example threshold for booster
        require(_amount > 0 && _amount <= 100, "AetherForge: Boost amount must be between 1 and 100"); // Limit boosts per transaction

        // Ensure booster was also a significant contributor or the project proposer
        require(projects[_projectId].proposer == msg.sender || projects[_projectId].contributors[msg.sender] > 0,
                "AetherForge: Booster must be the project proposer or a contributor to the project");
        
        _updateContributorReputation(_contributor, int256(_amount));
        emit ReputationBoosted(_contributor, msg.sender, _projectId, _amount);
    }

    // ====================================================================================================
    // VII. Voting Delegation
    // ====================================================================================================

    /// @notice Delegates the sender's voting power to another address.
    /// @dev Requires the caller to be a registered contributor. Cannot delegate to self or zero address.
    /// @param _delegate The address to delegate voting power to.
    function delegateVote(address _delegate) external onlyRegisteredContributor whenNotPaused {
        require(_delegate != address(0), "AetherForge: Delegate address cannot be zero");
        require(_delegate != msg.sender, "AetherForge: Cannot delegate to self");
        contributorProfiles[msg.sender].delegatedVoteTo = _delegate;
        emit VoteDelegated(msg.sender, _delegate);
    }

    /// @notice Removes the sender's voting delegation.
    /// @dev Requires the caller to have an active delegation.
    function undelegateVote() external onlyRegisteredContributor whenNotPaused {
        require(contributorProfiles[msg.sender].delegatedVoteTo != address(0), "AetherForge: No active delegation to remove");
        contributorProfiles[msg.sender].delegatedVoteTo = address(0);
        emit VoteUndelegated(msg.sender);
    }

    // ====================================================================================================
    // VIII. View Functions (Read-only)
    // ====================================================================================================

    /// @notice Returns comprehensive details for a specific project.
    /// @param _projectId The ID of the project.
    /// @return A tuple containing detailed project information.
    function getProjectDetails(uint256 _projectId)
        external
        view
        projectExists(_projectId)
        returns (
            address proposer,
            string memory ipfsHash,
            uint256 fundingGoal,
            uint256 currentFunding,
            address fundedTokenAddress,
            ProjectStatus status,
            uint256 aiScore,
            uint256 totalApprovalReputation,
            uint256 startTime,
            uint256 durationDays,
            bool initialFundingClaimed,
            uint256 milestoneCount
        )
    {
        Project storage project = projects[_projectId];
        return (
            project.proposer,
            project.ipfsHash,
            project.fundingGoal,
            project.currentFunding,
            address(project.fundedToken),
            project.status,
            project.aiScore,
            project.totalApprovalReputation,
            project.startTime,
            project.durationDays,
            project.initialFundingClaimed,
            project.milestones.length
        );
    }

    /// @notice Returns details for a specific milestone within a project.
    /// @param _projectId The ID of the project.
    /// @param _milestoneIndex The index of the milestone.
    /// @return A tuple containing detailed milestone information.
    function getMilestoneDetails(uint256 _projectId, uint256 _milestoneIndex)
        external
        view
        projectExists(_projectId)
        returns (
            string memory ipfsHash,
            uint256 fundingReleasePercentage,
            bool isCompleted,
            string memory proofIpfsHash,
            uint256 totalCompletionReputation,
            bool aiVerified,
            bool released
        )
    {
        Project storage project = projects[_projectId];
        require(_milestoneIndex < project.milestones.length, "AetherForge: Milestone index out of bounds");
        Milestone storage milestone = project.milestones[_milestoneIndex];
        return (
            milestone.ipfsHash,
            milestone.fundingReleasePercentage,
            milestone.isCompleted,
            milestone.proofIpfsHash,
            milestone.totalCompletionReputation,
            milestone.aiVerified,
            milestone.released
        );
    }

    /// @notice Returns the profile details for a given contributor address.
    /// @param _contributor The address of the contributor.
    /// @return A tuple containing contributor alias, reputation, staked tokens, and delegated vote address.
    function getContributorProfile(address _contributor)
        external
        view
        returns (string memory alias, uint256 reputation, uint256 stakedTokens, address delegatedVoteTo, bool hasRegistered)
    {
        ContributorProfile storage profile = contributorProfiles[_contributor];
        return (profile.alias, profile.reputation, profile.stakedTokens, profile.delegatedVoteTo, profile.hasRegistered);
    }

    /// @notice Returns the custom data associated with a ForgeFragment NFT.
    /// @param _tokenId The ID of the ForgeFragment NFT.
    /// @return A struct containing the fragment's detailed data.
    function getForgeFragmentData(uint256 _tokenId) external view returns (IForgeFragment.FragmentData memory) {
        return FORGE_FRAGMENT_NFT.getFragmentData(_tokenId);
    }

    /// @notice Returns the current tier of a ForgeFragment NFT.
    /// @param _tokenId The ID of the ForgeFragment NFT.
    /// @return The current tier of the NFT.
    function getForgeFragmentTier(uint256 _tokenId) external view returns (IForgeFragment.Tier) {
        return FORGE_FRAGMENT_NFT.getTokenTier(_tokenId);
    }

    /// @notice Returns the current protocol fee in basis points.
    /// @return The protocol fee percentage.
    function protocolFee() external view returns (uint256) {
        return protocolFeeBps;
    }

    /// @notice Returns the address of the currently configured AI oracle.
    /// @return The AI oracle's address.
    function aiOracleAddress() external view returns (address) {
        return aiOracleAddress;
    }

    /// @notice Checks if a specific address has already voted on a project proposal.
    /// @param _voter The address of the voter.
    /// @param _projectId The ID of the project.
    /// @return True if the voter has voted, false otherwise.
    function hasVotedOnProposal(address _voter, uint256 _projectId) external view projectExists(_projectId) returns (bool) {
        return projects[_projectId].approvalVotes[_voter];
    }

    /// @notice Checks if a specific address has already voted on a milestone completion.
    /// @param _voter The address of the voter.
    /// @param _projectId The ID of the project.
    /// @param _milestoneIndex The index of the milestone.
    /// @return True if the voter has voted, false otherwise.
    function hasVotedOnMilestone(address _voter, uint256 _projectId, uint256 _milestoneIndex) external view projectExists(_projectId) returns (bool) {
        require(_milestoneIndex < projects[_projectId].milestones.length, "AetherForge: Milestone index out of bounds");
        return projects[_projectId].milestones[_milestoneIndex].completionVotes[_voter];
    }


    // ====================================================================================================
    // Internal Helper Functions
    // ====================================================================================================

    /// @notice Internal function to get the effective voting reputation for an address, considering delegation.
    /// @dev If an address has delegated their vote, the delegatee's reputation and staked tokens are used.
    /// @param _voter The address whose voting reputation is to be calculated.
    /// @return The effective reputation score for voting.
    function getVotingReputation(address _voter) internal view returns (uint256) {
        ContributorProfile storage profile = contributorProfiles[_voter];
        address effectiveVoter = profile.delegatedVoteTo != address(0) ? profile.delegatedVoteTo : _voter;
        // Voting power is a combination of base reputation and staked tokens (e.g., 1 reputation per 100 AETHER staked)
        return contributorProfiles[effectiveVoter].reputation + (contributorProfiles[effectiveVoter].stakedTokens / 100); 
    }

    /// @notice Internal function to update a contributor's reputation score.
    /// @dev Reputation can increase or decrease. It cannot go below zero.
    /// @param _contributor The address of the contributor.
    /// @param _reputationChange The amount by which to change the reputation (can be positive or negative).
    function _updateContributorReputation(address _contributor, int256 _reputationChange) internal {
        ContributorProfile storage profile = contributorProfiles[_contributor];
        if (!profile.hasRegistered) return; // Only update registered contributors

        if (_reputationChange > 0) {
            profile.reputation += uint256(_reputationChange);
        } else {
            uint256 absChange = uint256(-_reputationChange);
            if (profile.reputation > absChange) {
                profile.reputation -= absChange;
            } else {
                profile.reputation = 0; // Reputation cannot go below zero
            }
        }
        emit ContributorReputationUpdated(_contributor, profile.reputation);
    }
}
```