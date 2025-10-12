I've designed a smart contract called `VerifiableSkillNetwork` that integrates several advanced and trendy concepts: **Soulbound Tokens (SBTs)** for identity and reputation, **on-chain attestations** for skills (with conceptual support for **ZK-proofs**), a structured **project collaboration lifecycle**, dynamic **reputation mechanics**, and an "AI Oracle" for advanced off-chain computations.

This contract aims to be an interesting and unique blend, focusing on a decentralized talent network where individuals build verifiable on-chain profiles and collaborate on projects.

---

## Verifiable Skill Network (VSN) Smart Contract

**Solidity Version:** `^0.8.20`
**Dependencies:** `@openzeppelin/contracts`

### Contract Structure (Outline)

This contract establishes a decentralized, reputation-based network for skill attestation, project collaboration, and incentivization. It leverages Soulbound Tokens (SBTs) as non-transferable digital identities that accrue reputation and verified skills based on on-chain activities and attestations. The network facilitates the creation and funding of projects, matching skilled contributors, and rewarding successful milestone completion.

**Key Concepts:**

*   **Soulbound Profiles (SBTs):** Non-transferable NFTs representing a user's on-chain identity, reputation, and verified skills.
*   **Skill Attestations:** A mechanism for trusted entities (Attestors/AI Oracle) to verify a user's proficiency. Includes conceptual support for ZK-proofs as a `bytes` payload.
*   **Project Lifecycle:** From proposal and community funding/voting to contributor selection, milestone tracking, and reward distribution.
*   **Dynamic Reputation:** Reputation scores tied to SBTs, evolving with contributions, attestations, and challenge outcomes.
*   **AI Oracle Integration (Conceptual):** A designated address to provide AI-driven insights, recommendations, or complex evaluations off-chain, influencing on-chain decisions.

---

### Function Summary

#### I. Core Setup & Administration (6 Functions)

1.  `constructor(address _sbtContractAddress, address _initialAIOracle, uint256 _initialEpochDuration, uint256 _initialAttestationChallengeStake)`:
    *   Initializes the contract with core parameters like the SBT contract address, the initial AI Oracle address, epoch duration, and attestation challenge stake. Sets the deployer as the owner and an admin.
2.  `setEpochDuration(uint256 _newDuration)`:
    *   Allows the owner to update the duration of an epoch (e.g., for reputation decay/boost calculations).
3.  `registerSkillCategory(string calldata _categoryName)`:
    *   Registers a new skill category (e.g., "Solidity Development", "Zero-Knowledge Proofs") that can be attested to by trusted entities. Only callable by admin/owner.
4.  `updateAIOracleAddress(address _newAIOracle)`:
    *   Sets or updates the address of the designated AI Oracle, a trusted entity for off-chain AI-driven evaluations. Only callable by owner.
5.  `pause()`:
    *   Pauses the contract in emergencies, preventing most operations. Only callable by owner. (Inherited from OpenZeppelin's `Pausable`).
6.  `unpause()`:
    *   Unpauses the contract, allowing operations to resume. Only callable by owner. (Inherited from OpenZeppelin's `Pausable`).

#### II. Profile & Skill Management (Soulbound Profile NFT) (5 Functions)

7.  `mintProfileSBT(string calldata _metadataURI)`:
    *   Creates a unique, non-transferable Soulbound Token (SBT) profile for the caller. Each address can only mint one SBT. The SBT stores reputation and links to verified skills.
8.  `attestSkill(uint256 _profileSBTId, uint256 _skillCategoryId, uint256 _level, bytes calldata _zkProof)`:
    *   Allows designated `Attestors` (admins, owner, or the AI Oracle) to verify a participant's skill level in a specific category. Includes `_zkProof` as a conceptual placeholder for off-chain zero-knowledge proof verification.
9.  `revokeSkillAttestation(uint256 _profileSBTId, uint256 _skillCategoryId)`:
    *   Revokes a previously issued skill attestation. Callable by the original attestor, admin, or AI Oracle.
10. `updateProfileMetadataURI(uint256 _profileSBTId, string calldata _newURI)`:
    *   Allows an SBT holder to update their profile's off-chain metadata URI (e.g., to link to an updated portfolio).
11. `challengeAttestation(uint256 _profileSBTId, uint256 _skillCategoryId)`:
    *   Enables any participant to challenge a potentially fraudulent skill attestation. Requires a stake (ETH) to initiate the challenge, which would trigger an off-chain dispute resolution process.

#### III. Project & Collaboration Lifecycle (10 Functions)

12. `createProjectProposal(string calldata _title, string calldata _description, uint256[] calldata _requiredSkillCategoryIds, uint256[] calldata _requiredSkillLevels, uint256 _budget, Milestone[] calldata _milestones)`:
    *   Initiates a new project proposal, detailing its requirements, budget, and milestones.
13. `stakeForProposalApproval(uint256 _projectId)`:
    *   Participants stake tokens (ETH) to signal support for a project proposal, contributing to its approval weight and potentially funding.
14. `voteOnProjectProposal(uint256 _projectId, bool _approve)`:
    *   Allows participants who have staked on a project to cast a vote (approve/reject). Vote weight is currently tied to the staked amount.
15. `approveProject(uint256 _projectId)`:
    *   The network governance (or admin) formally approves a project, moving it from `Pending` to `Active` status, based on voting/staking outcomes or administrative decision.
16. `applyToProject(uint256 _projectId)`:
    *   A profiled participant applies to join an approved project. The contract checks if the applicant's attested skills meet the project's requirements.
17. `selectProjectContributors(uint256 _projectId, uint256[] calldata _contributorSBTIds)`:
    *   The project creator selects official contributors from the pool of applicants. Only callable by the project creator.
18. `submitMilestoneProof(uint256 _projectId, uint256 _milestoneId, bytes32 _proofHash)`:
    *   A selected contributor submits proof of work for a project milestone. The `_proofHash` serves as an on-chain record of off-chain evidence.
19. `verifyMilestoneCompletion(uint256 _projectId, uint256 _milestoneId)`:
    *   The project creator verifies a submitted milestone. Upon verification, this triggers internal reputation updates for associated contributors and enables reward claiming.
20. `disputeMilestone(uint256 _projectId, uint256 _milestoneId, string calldata _reason)`:
    *   Allows participants to dispute the verification or completion of a milestone, changing its status to `Disputed` and potentially triggering arbitration.

#### IV. Reputation & Incentives (4 Functions)

21. `updateReputationScore(uint256 _profileSBTId, uint256 _changeAmount, bool _increase)`:
    *   An internal function used to dynamically adjust a participant's reputation score on their SBT, based on events like milestone completion, attestation challenges, etc.
22. `claimProjectReward(uint256 _projectId, uint256 _milestoneId, uint256 _profileSBTId)`:
    *   Allows a selected contributor (who submitted proof or is designated for a milestone) to claim their share of project funds for a verified milestone. Rewards are distributed from the contract's balance.
23. `requestAIEvaluation(uint256 _projectId, uint256[] calldata _profileSBTIds, bytes calldata _evaluationParams)`:
    *   Allows a project creator to request an AI Oracle evaluation for tasks like optimal contributor matching or project assessment. This function emits an event for the off-chain AI Oracle to pick up and process.
24. `getProfileDetails(address _owner)`:
    *   A view function to retrieve all relevant details for a participant's SBT: ID, reputation, metadata URI, and a list of all attested skills and their levels.
25. `getProjectDetails(uint256 _projectId)`:
    *   A view function to retrieve comprehensive details about a specific project, including its status, creator, budget, and milestones.

---

### Smart Contract Code

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol"; // Using ERC721 for base errors and some internal logic
import "@openzeppelin/contracts/utils/Counters.sol";

// --- Custom Errors for Clarity & Gas Efficiency ---
error NotProfileOwner(uint256 _tokenId, address _caller);
error ProfileAlreadyExists(address _owner);
error ProfileDoesNotExist(address _owner);
error InvalidSkillLevel();
error SkillCategoryDoesNotExist(uint256 _categoryId);
error AttestationNotFound(uint256 _profileId, uint256 _skillId);
error NotAuthorizedAttestor();
error ProjectNotFound(uint256 _projectId);
error ProjectAlreadyApproved(uint256 _projectId);
error ProjectNotApproved(uint256 _projectId);
error InvalidProjectStatus(uint256 _projectId, ProjectStatus _expectedStatus);
error CallerNotProjectCreator();
error AlreadyAppliedToProject(uint256 _projectId, uint256 _profileSBTId);
error NotEnoughSkill(uint256 _profileSBTId, uint256 _skillId, uint256 _requiredLevel);
error NotProjectContributor(uint256 _projectId, uint256 _profileSBTId);
error MilestoneProofAlreadySubmitted(uint256 _projectId, uint256 _milestoneId);
error MilestoneAlreadyVerified(uint256 _projectId, uint256 _milestoneId);
error MilestoneProofNotSubmitted(uint256 _projectId, uint256 _milestoneId);
error MilestoneRewardAlreadyClaimed(uint256 _projectId, uint256 _milestoneId, uint256 _profileSBTId);
error InsufficientStakeAmount();
error OnlyAIOrcle();
error CallerNotAdmin();
error AttestationChallengeStakeNotSet();
error CannotTransferSBT(); // For the non-transferable nature of SBTs
error NoFundsToClaim();
error InvalidMilestoneStatus(uint256 _milestoneId, MilestoneStatus _expectedStatus);


// --- Interface for the minimal ERC721 functionality required for SBTs ---
// This interface defines the custom functions for our Soulbound NFT.
interface IVSCNSoulboundNFT is IERC721 {
    function mint(address _to, string memory _tokenURI) external returns (uint256);
    function setTokenURI(uint256 _tokenId, string memory _tokenURI) external;
    function updateReputation(uint256 _tokenId, uint256 _newReputation) external;
    function getTokenReputation(uint256 _tokenId) external view returns (uint256);
}

// --- Soulbound NFT Contract ---
// This contract handles the creation and management of non-transferable Soulbound Tokens (SBTs).
// It's a minimal ERC721 implementation customized for SBTs.
contract VSCNSoulboundNFT is ERC721, IVSCNSoulboundNFT {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    mapping(uint256 => uint256) private _reputations; // Reputation score for each SBT

    // Events
    event SBTMinted(address indexed to, uint256 indexed tokenId, string tokenURI);
    event SBTMetadataUpdated(uint256 indexed tokenId, string newTokenURI);
    event SBTReputationUpdated(uint256 indexed tokenId, uint256 newReputation);

    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {}

    // --- Override ERC721 Transfer Functions to make SBTs Non-Transferable ---
    function approve(address, uint256) public pure override {
        revert CannotTransferSBT();
    }
    function getApproved(uint256) public pure override returns (address) {
        revert CannotTransferSBT();
    }
    function setApprovalForAll(address, bool) public pure override {
        revert CannotTransferSBT();
    }
    function isApprovedForAll(address, address) public pure override returns (bool) {
        revert CannotTransferSBT();
    }
    function transferFrom(address, address, uint256) public pure override {
        revert CannotTransferSBT();
    }
    function safeTransferFrom(address, address, uint256) public pure override {
        revert CannotTransferSBT();
    }
    function safeTransferFrom(address, address, uint256, bytes calldata) public pure override {
        revert CannotTransferSBT();
    }

    // --- Custom SBT-specific Functions ---

    /**
     * @notice Mints a new Soulbound Token (SBT) for a given address.
     * @param _to The address to mint the SBT for.
     * @param _tokenURI The URI pointing to the off-chain metadata for the profile.
     * @dev Only the owner of this SBT contract can call this.
     * @return The ID of the newly minted SBT.
     */
    function mint(address _to, string memory _tokenURI) external onlyOwner returns (uint256) {
        if (_to == address(0)) revert ERC721InvalidRecipient(address(0));
        if (balanceOf(_to) > 0) revert ProfileAlreadyExists(_to); // Only one SBT per address

        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        _mint(_to, newTokenId); // ERC721 internal mint
        _setTokenURI(newTokenId, _tokenURI); // ERC721 internal set URI
        _reputations[newTokenId] = 0; // Initialize reputation

        emit SBTMinted(_to, newTokenId, _tokenURI);
        return newTokenId;
    }

    /**
     * @notice Allows the owner of an SBT to update its metadata URI.
     * @param _tokenId The ID of the SBT to update.
     * @param _tokenURI The new URI for the metadata.
     * @dev Only the owner of the SBT can call this.
     */
    function setTokenURI(uint256 _tokenId, string memory _tokenURI) external override {
        if (msg.sender != ownerOf(_tokenId)) revert NotProfileOwner(_tokenId, msg.sender);
        _setTokenURI(_tokenId, _tokenURI);
        emit SBTMetadataUpdated(_tokenId, _tokenURI);
    }

    /**
     * @notice Updates the reputation score of an SBT.
     * @param _tokenId The ID of the SBT.
     * @param _newReputation The new reputation score.
     * @dev This function is intended to be called by the `VerifiableSkillNetwork` contract (or its owner).
     */
    function updateReputation(uint256 _tokenId, uint256 _newReputation) external override onlyOwner {
        if (!_exists(_tokenId)) revert ERC721NonexistentToken(_tokenId);
        _reputations[_tokenId] = _newReputation;
        emit SBTReputationUpdated(_tokenId, _newReputation);
    }

    /**
     * @notice Retrieves the current reputation score of an SBT.
     * @param _tokenId The ID of the SBT.
     * @return The reputation score.
     */
    function getTokenReputation(uint256 _tokenId) external view override returns (uint256) {
        if (!_exists(_tokenId)) revert ERC721NonexistentToken(_tokenId);
        return _reputations[_tokenId];
    }
}


// --- Main Contract: VerifiableSkillNetwork ---
// This contract orchestrates the core logic for skill attestations, project management, and reputation.
contract VerifiableSkillNetwork is Ownable, Pausable {
    using Counters for Counters.Counter;

    // --- Modifiers ---
    modifier onlyAdmin() {
        if (!_admins[msg.sender] && msg.sender != owner()) revert CallerNotAdmin();
        _;
    }

    modifier onlyAIOracle() {
        if (msg.sender != _aiOracle) revert OnlyAIOrcle();
        _;
    }

    // --- State Variables ---

    // Core Setup
    IVSCNSoulboundNFT public sbtContract; // Address of the deployed SBT contract
    address public _aiOracle;             // Address of the designated AI Oracle
    uint256 public _epochDuration;        // Duration of an epoch in seconds (for future reputation decay/boost)
    mapping(address => bool) private _admins; // Addresses granted admin privileges

    // Skill Categories
    Counters.Counter private _nextSkillCategoryId; // Counter for new skill categories
    mapping(uint256 => string) public _skillCategories; // skillId -> name
    mapping(string => uint256) public _skillCategoryIds; // name -> skillId (for reverse lookup)

    // Attestation System
    uint256 public _attestationChallengeStake; // Tokens required to challenge an attestation
    // profileSBTId => skillCategoryId => attestedLevel
    mapping(uint256 => mapping(uint256 => uint256)) public _skillAttestations;
    // attesterAddress => reputationScore (separate tracking for attestors, not global SBT reputation)
    mapping(address => uint256) public _attestorReputations;

    // Project Management
    enum ProjectStatus { Pending, Approved, Rejected, Active, Completed, Disputed }
    enum MilestoneStatus { Pending, Submitted, Verified, Disputed, Paid }

    struct Milestone {
        string description;
        uint256 deadline; // Unix timestamp
        uint256 rewardPercentage; // Percentage of total project budget allocated to this milestone
        MilestoneStatus status;
        address lastContributor; // Who submitted proof for this milestone
    }

    struct Project {
        uint256 id;
        address creator;
        string title;
        string description;
        uint256 budget; // Total budget for the project (ETH in this contract)
        uint256 fundedAmount; // Amount currently funded (staked for approval, or direct funds)
        uint256 approvalThreshold; // Minimum stake/votes for approval
        Milestone[] milestones;
        uint256[] requiredSkillCategoryIds; // Skill IDs needed
        uint256[] requiredSkillLevels;      // Minimum levels for required skills
        ProjectStatus status;
        uint256 creationTime;
        uint256 approvedTime;
        mapping(uint256 => bool) contributors; // profileSBTId => isContributor (Selected contributors)
        mapping(uint256 => bytes32) milestoneProofs; // milestoneId => proofHash
        mapping(uint256 => mapping(uint256 => bool)) milestoneRewardClaimed; // milestoneId => profileSBTId => claimed
    }

    Counters.Counter private _nextProjectId; // Counter for new project IDs
    mapping(uint256 => Project) public _projects;
    mapping(uint256 => mapping(address => uint256)) public _projectStakes; // projectId => staker => amount (ETH)
    mapping(uint256 => mapping(address => uint256)) public _projectVotes; // projectId => voter => voteWeight
    mapping(uint256 => uint256) public _totalProjectVoteWeight; // projectId => totalWeightedVotes
    // projectId => profileSBTId => bool (applied status)
    mapping(uint256 => mapping(uint256 => bool)) public _projectApplicants;


    // --- Events ---
    event EpochDurationUpdated(uint256 newDuration);
    event SkillCategoryRegistered(uint256 indexed categoryId, string categoryName);
    event AIOracleAddressUpdated(address indexed oldAddress, address indexed newAddress);
    event SkillAttested(uint256 indexed profileSBTId, uint256 indexed skillCategoryId, uint256 level, address indexed attestor);
    event SkillAttestationRevoked(uint256 indexed profileSBTId, uint256 indexed skillCategoryId, address indexed attestor);
    event AttestationChallenged(uint256 indexed profileSBTId, uint256 indexed skillCategoryId, address indexed challenger, uint256 stake);
    event ProjectProposalCreated(uint256 indexed projectId, address indexed creator, string title, uint256 budget);
    event ProjectStakeReceived(uint256 indexed projectId, address indexed staker, uint256 amount);
    event ProjectVoteCast(uint256 indexed projectId, address indexed voter, bool approved, uint256 voteWeight);
    event ProjectApproved(uint256 indexed projectId, address indexed approver);
    event ProjectRejected(uint256 indexed projectId, address indexed rejector);
    event AppliedToProject(uint256 indexed projectId, uint256 indexed profileSBTId);
    event ContributorsSelected(uint256 indexed projectId, uint256[] contributorSBTIds);
    event MilestoneProofSubmitted(uint256 indexed projectId, uint256 indexed milestoneId, bytes32 proofHash, uint256 profileSBTId);
    event MilestoneVerified(uint256 indexed projectId, uint256 indexed milestoneId, uint256 rewardAmount);
    event MilestoneDisputed(uint256 indexed projectId, uint256 indexed milestoneId, address indexed disputer, string reason);
    event ProjectRewardClaimed(uint256 indexed projectId, uint256 indexed milestoneId, uint256 indexed profileSBTId, uint256 amount);
    event AIEvaluationRequested(uint256 indexed projectId, uint256[] profileSBTIds, bytes evaluationParams);


    // --- Constructor ---
    constructor(
        address _sbtContractAddress,
        address _initialAIOracle,
        uint256 _initialEpochDuration,
        uint256 _initialAttestationChallengeStake
    )
        Ownable(msg.sender)
    {
        // Ensure the SBT contract is a valid address
        require(_sbtContractAddress != address(0), "Invalid SBT contract address");
        sbtContract = IVSCNSoulboundNFT(_sbtContractAddress);

        _aiOracle = _initialAIOracle;
        _epochDuration = _initialEpochDuration;
        _attestationChallengeStake = _initialAttestationChallengeStake;
        _admins[msg.sender] = true; // Deployer is automatically an admin
    }

    // --- I. Core Setup & Administration ---

    /**
     * @notice Allows the owner to update the duration of an epoch.
     * @param _newDuration The new duration in seconds.
     */
    function setEpochDuration(uint256 _newDuration) public onlyOwner {
        require(_newDuration > 0, "Epoch duration must be positive");
        _epochDuration = _newDuration;
        emit EpochDurationUpdated(_newDuration);
    }

    /**
     * @notice Registers a new skill category that can be attested to.
     * @param _categoryName The name of the new skill category.
     * @dev Only callable by owner or admin.
     */
    function registerSkillCategory(string calldata _categoryName) public onlyAdmin whenNotPaused {
        require(bytes(_categoryName).length > 0, "Category name cannot be empty");
        require(_skillCategoryIds[_categoryName] == 0, "Skill category already exists");

        _nextSkillCategoryId.increment();
        uint256 newId = _nextSkillCategoryId.current();
        _skillCategories[newId] = _categoryName;
        _skillCategoryIds[_categoryName] = newId;
        emit SkillCategoryRegistered(newId, _categoryName);
    }

    /**
     * @notice Sets or updates the address of the designated AI Oracle.
     * @param _newAIOracle The new address for the AI Oracle.
     * @dev Only callable by owner.
     */
    function updateAIOracleAddress(address _newAIOracle) public onlyOwner {
        require(_newAIOracle != address(0), "AI Oracle address cannot be zero");
        address oldAIOracle = _aiOracle;
        _aiOracle = _newAIOracle;
        emit AIOracleAddressUpdated(oldAIOracle, _newAIOracle);
    }

    /**
     * @notice Pauses the contract in emergencies.
     * @dev Only callable by owner. Inherited from Pausable.
     */
    function pause() public override onlyOwner {
        _pause();
    }

    /**
     * @notice Unpauses the contract.
     * @dev Only callable by owner. Inherited from Pausable.
     */
    function unpause() public override onlyOwner {
        _unpause();
    }

    // --- II. Profile & Skill Management (Soulbound Profile NFT) ---

    /**
     * @notice Creates a unique, non-transferable Soulbound Token (SBT) profile for the caller.
     * @param _metadataURI The URI pointing to the off-chain metadata for the profile.
     * @return The ID of the newly minted SBT.
     */
    function mintProfileSBT(string calldata _metadataURI) public whenNotPaused returns (uint256) {
        // The sbtContract handles the check for existing profiles for msg.sender.
        // Also, the sbtContract's mint is onlyOwner, so the VSN contract must be the owner of the SBT contract.
        return sbtContract.mint(msg.sender, _metadataURI);
    }

    /**
     * @notice Allows designated `Attestors` or the AI Oracle to verify a participant's skill.
     * @param _profileSBTId The tokenId of the profile to attest.
     * @param _skillCategoryId The ID of the skill category.
     * @param _level The attested skill level (e.g., 1-100).
     * @param _zkProof A conceptual placeholder for an off-chain ZK proof that verifies the skill.
     * @dev Only callable by a trusted `Attestor` (admin, AI Oracle, or owner of VSN).
     *      The actual ZK proof verification logic would be off-chain.
     */
    function attestSkill(
        uint256 _profileSBTId,
        uint256 _skillCategoryId,
        uint256 _level,
        bytes calldata _zkProof // Conceptual ZK proof
    ) public whenNotPaused {
        // Ensure caller is an authorized attestor
        if (!_admins[msg.sender] && msg.sender != _aiOracle && msg.sender != owner()) {
            revert NotAuthorizedAttestor();
        }
        // Validate skill level
        if (_level == 0) revert InvalidSkillLevel();
        // Check if skill category exists
        if (bytes(_skillCategories[_skillCategoryId]).length == 0) revert SkillCategoryDoesNotExist(_skillCategoryId);
        // Check if SBT exists (ownerOf will revert if it doesn't)
        sbtContract.ownerOf(_profileSBTId);

        _skillAttestations[_profileSBTId][_skillCategoryId] = _level;
        // Future: Attestors could earn reputation or _attestorReputations could be tracked here.
        emit SkillAttested(_profileSBTId, _skillCategoryId, _level, msg.sender);
    }

    /**
     * @notice Revokes a previously issued skill attestation.
     * @param _profileSBTId The tokenId of the profile.
     * @param _skillCategoryId The ID of the skill category.
     * @dev Only callable by the original attestor, admin, or AI Oracle.
     */
    function revokeSkillAttestation(uint256 _profileSBTId, uint256 _skillCategoryId) public whenNotPaused {
        if (!_admins[msg.sender] && msg.sender != _aiOracle && msg.sender != owner()) {
            revert NotAuthorizedAttestor();
        }
        if (bytes(_skillCategories[_skillCategoryId]).length == 0) revert SkillCategoryDoesNotExist(_skillCategoryId);
        sbtContract.ownerOf(_profileSBTId); // Check if SBT exists

        if (_skillAttestations[_profileSBTId][_skillCategoryId] == 0) revert AttestationNotFound(_profileSBTId, _skillCategoryId);

        _skillAttestations[_profileSBTId][_skillCategoryId] = 0; // Set level to 0 to revoke
        emit SkillAttestationRevoked(_profileSBTId, _skillCategoryId, msg.sender);
    }

    /**
     * @notice Allows an SBT holder to update their profile's off-chain metadata URI.
     * @param _profileSBTId The tokenId of the profile.
     * @param _newURI The new URI for the metadata.
     * @dev The actual SBT contract handles the ownership check.
     */
    function updateProfileMetadataURI(uint256 _profileSBTId, string calldata _newURI) public whenNotPaused {
        sbtContract.setTokenURI(_profileSBTId, _newURI); // This internally checks owner.
    }

    /**
     * @notice Allows any participant to challenge a skill attestation, requiring a stake.
     * @param _profileSBTId The tokenId of the profile whose attestation is being challenged.
     * @param _skillCategoryId The ID of the skill category of the challenged attestation.
     * @dev Requires a stake. A dispute resolution mechanism would resolve this off-chain,
     *      with an admin/oracle eventually calling a resolution function (not implemented here).
     */
    function challengeAttestation(uint256 _profileSBTId, uint256 _skillCategoryId) public payable whenNotPaused {
        if (_attestationChallengeStake == 0) revert AttestationChallengeStakeNotSet();
        if (msg.value < _attestationChallengeStake) revert InsufficientStakeAmount();
        if (_skillAttestations[_profileSBTId][_skillCategoryId] == 0) revert AttestationNotFound(_profileSBTId, _skillCategoryId);

        // Funds are held in the contract. A separate function (e.g., `resolveAttestationChallenge`)
        // would need to be called by an admin/oracle to distribute the stake and update reputation.
        emit AttestationChallenged(_profileSBTId, _skillCategoryId, msg.sender, msg.value);
    }

    // --- III. Project & Collaboration Lifecycle ---

    /**
     * @notice Initiates a new project proposal.
     * @param _title The title of the project.
     * @param _description A detailed description of the project.
     * @param _requiredSkillCategoryIds Array of skill category IDs required for the project.
     * @param _requiredSkillLevels Array of minimum skill levels corresponding to `_requiredSkillCategoryIds`.
     * @param _budget Total budget for the project.
     * @param _milestones Array of milestones for the project.
     */
    function createProjectProposal(
        string calldata _title,
        string calldata _description,
        uint256[] calldata _requiredSkillCategoryIds,
        uint256[] calldata _requiredSkillLevels,
        uint256 _budget,
        Milestone[] calldata _milestones
    ) public whenNotPaused {
        require(bytes(_title).length > 0, "Project title cannot be empty");
        require(_requiredSkillCategoryIds.length == _requiredSkillLevels.length, "Skill arrays mismatch");
        require(_milestones.length > 0, "Project must have at least one milestone");
        require(_budget > 0, "Project budget must be greater than zero");

        for (uint256 i = 0; i < _requiredSkillCategoryIds.length; i++) {
            if (bytes(_skillCategories[_requiredSkillCategoryIds[i]]).length == 0) {
                revert SkillCategoryDoesNotExist(_requiredSkillCategoryIds[i]);
            }
        }

        _nextProjectId.increment();
        uint256 projectId = _nextProjectId.current();

        Project storage newProject = _projects[projectId];
        newProject.id = projectId;
        newProject.creator = msg.sender;
        newProject.title = _title;
        newProject.description = _description;
        newProject.budget = _budget;
        newProject.milestones = _milestones;
        newProject.requiredSkillCategoryIds = _requiredSkillCategoryIds;
        newProject.requiredSkillLevels = _requiredSkillLevels;
        newProject.status = ProjectStatus.Pending;
        newProject.creationTime = block.timestamp;
        newProject.approvalThreshold = _budget / 10; // Example: 10% of budget as approval threshold

        emit ProjectProposalCreated(projectId, msg.sender, _title, _budget);
    }

    /**
     * @notice Participants stake tokens (ETH) to signal support for a project proposal.
     * @param _projectId The ID of the project proposal to stake for.
     * @dev Staked tokens contribute to the `fundedAmount` and signal community interest.
     *      Funds are held in the contract and will be used to pay contributors if approved.
     */
    function stakeForProposalApproval(uint256 _projectId) public payable whenNotPaused {
        Project storage project = _projects[_projectId];
        if (project.creator == address(0)) revert ProjectNotFound(_projectId);
        if (project.status != ProjectStatus.Pending) revert InvalidProjectStatus(_projectId, ProjectStatus.Pending);
        if (msg.value == 0) revert InsufficientStakeAmount();

        _projectStakes[_projectId][msg.sender] += msg.value;
        project.fundedAmount += msg.value; // Tracks total ETH staked for approval

        emit ProjectStakeReceived(_projectId, msg.sender, msg.value);
    }

    /**
     * @notice Allows governance participants to cast a vote on a proposal.
     * @param _projectId The ID of the project proposal to vote on.
     * @param _approve True to approve, false to reject.
     * @dev Vote weight is based on the amount of ETH staked by the voter.
     */
    function voteOnProjectProposal(uint256 _projectId, bool _approve) public whenNotPaused {
        Project storage project = _projects[_projectId];
        if (project.creator == address(0)) revert ProjectNotFound(_projectId);
        if (project.status != ProjectStatus.Pending) revert InvalidProjectStatus(_projectId, ProjectStatus.Pending);
        require(_projectStakes[_projectId][msg.sender] > 0, "Must stake tokens to vote");

        uint256 voteWeight = _projectStakes[_projectId][msg.sender];
        if (_projectVotes[_projectId][msg.sender] == 0) { // Only allow one vote (initial staking counts as vote)
            _projectVotes[_projectId][msg.sender] = voteWeight; // Record vote weight for this voter
            if (_approve) {
                _totalProjectVoteWeight[_projectId] += voteWeight;
            } else {
                // If a voter casts a "reject" vote, their staked amount effectively counts against the threshold.
                // A more complex system might differentiate approval vs rejection funds.
                // For simplicity, a rejection subtracts from the total approval weight.
                _totalProjectVoteWeight[_projectId] = _totalProjectVoteWeight[_projectId] > voteWeight ? _totalProjectVoteWeight[_projectId] - voteWeight : 0;
            }
        } else {
             revert("Already voted on this proposal");
        }
        emit ProjectVoteCast(_projectId, msg.sender, _approve, voteWeight);
    }

    /**
     * @notice The network governance (or admin) formally approves a project based on voting/staking outcomes.
     * @param _projectId The ID of the project to approve.
     * @dev Only callable by an admin. Admin can approve if `_totalProjectVoteWeight` meets `approvalThreshold`.
     */
    function approveProject(uint256 _projectId) public onlyAdmin whenNotPaused {
        Project storage project = _projects[_projectId];
        if (project.creator == address(0)) revert ProjectNotFound(_projectId);
        if (project.status != ProjectStatus.Pending) revert InvalidProjectStatus(_projectId, ProjectStatus.Pending);
        require(project.fundedAmount >= project.approvalThreshold, "Not enough funds staked for approval");
        // Could also add: `require(_totalProjectVoteWeight[_projectId] >= project.approvalThreshold, "Not enough approval votes");`

        project.status = ProjectStatus.Active;
        project.approvedTime = block.timestamp;
        emit ProjectApproved(_projectId, msg.sender);
    }

    /**
     * @notice A profiled participant applies to join an approved project.
     * @param _projectId The ID of the project to apply to.
     * @dev Applicant's skills must meet the project's requirements.
     */
    function applyToProject(uint256 _projectId) public whenNotPaused {
        Project storage project = _projects[_projectId];
        if (project.creator == address(0)) revert ProjectNotFound(_projectId);
        if (project.status != ProjectStatus.Active) revert InvalidProjectStatus(_projectId, ProjectStatus.Active);

        uint256 applicantSBTId = sbtContract.balanceOf(msg.sender) == 0 ? 0 : sbtContract.tokenOfOwnerByIndex(msg.sender, 0); // Assuming 1 SBT per owner
        if (applicantSBTId == 0) revert ProfileDoesNotExist(msg.sender);
        if (_projectApplicants[_projectId][applicantSBTId]) revert AlreadyAppliedToProject(_projectId, applicantSBTId);

        // Check if applicant meets required skills
        for (uint256 i = 0; i < project.requiredSkillCategoryIds.length; i++) {
            uint256 skillId = project.requiredSkillCategoryIds[i];
            uint256 requiredLevel = project.requiredSkillLevels[i];
            if (_skillAttestations[applicantSBTId][skillId] < requiredLevel) {
                revert NotEnoughSkill(applicantSBTId, skillId, requiredLevel);
            }
        }

        _projectApplicants[_projectId][applicantSBTId] = true;
        emit AppliedToProject(_projectId, applicantSBTId);
    }

    /**
     * @notice Project creator selects contributors from applicants based on skills and reputation.
     * @param _projectId The ID of the project.
     * @param _contributorSBTIds Array of SBT IDs of selected contributors.
     * @dev Only callable by the project creator.
     */
    function selectProjectContributors(uint256 _projectId, uint256[] calldata _contributorSBTIds) public whenNotPaused {
        Project storage project = _projects[_projectId];
        if (project.creator == address(0)) revert ProjectNotFound(_projectId);
        if (project.creator != msg.sender) revert CallerNotProjectCreator();
        if (project.status != ProjectStatus.Active) revert InvalidProjectStatus(_projectId, ProjectStatus.Active);

        for (uint256 i = 0; i < _contributorSBTIds.length; i++) {
            uint256 sbtId = _contributorSBTIds[i];
            address sbtOwner = sbtContract.ownerOf(sbtId); // This checks if SBT exists
            require(_projectApplicants[_projectId][sbtId], "SBT not an applicant");
            project.contributors[sbtId] = true;
            // Optionally, we could remove them from `_projectApplicants` to avoid re-selection or track selection status.
        }
        emit ContributorsSelected(_projectId, _contributorSBTIds);
    }

    /**
     * @notice A selected contributor submits proof of work for a project milestone.
     * @param _projectId The ID of the project.
     * @param _milestoneId The index of the milestone (0-indexed).
     * @param _proofHash A hash of the off-chain proof of work.
     * @dev Only callable by a selected contributor.
     */
    function submitMilestoneProof(uint256 _projectId, uint256 _milestoneId, bytes32 _proofHash) public whenNotPaused {
        Project storage project = _projects[_projectId];
        if (project.creator == address(0)) revert ProjectNotFound(_projectId);
        if (project.status != ProjectStatus.Active) revert InvalidProjectStatus(_projectId, ProjectStatus.Active);
        require(_milestoneId < project.milestones.length, "Invalid milestone ID");

        uint256 contributorSBTId = sbtContract.balanceOf(msg.sender) == 0 ? 0 : sbtContract.tokenOfOwnerByIndex(msg.sender, 0);
        if (contributorSBTId == 0 || !project.contributors[contributorSBTId]) {
            revert NotProjectContributor(_projectId, contributorSBTId);
        }

        Milestone storage milestone = project.milestones[_milestoneId];
        if (milestone.status != MilestoneStatus.Pending) revert MilestoneProofAlreadySubmitted(_projectId, _milestoneId);

        milestone.status = MilestoneStatus.Submitted;
        milestone.lastContributor = msg.sender; // Record who submitted the proof
        project.milestoneProofs[_milestoneId] = _proofHash; // Store hash for off-chain verification
        emit MilestoneProofSubmitted(_projectId, _milestoneId, _proofHash, contributorSBTId);
    }

    /**
     * @notice The project creator or designated verifier verifies a milestone, triggering reputation updates and enabling rewards.
     * @param _projectId The ID of the project.
     * @param _milestoneId The index of the milestone.
     * @dev Only callable by the project creator. Triggers reputation updates for the contributor.
     */
    function verifyMilestoneCompletion(uint256 _projectId, uint256 _milestoneId) public whenNotPaused {
        Project storage project = _projects[_projectId];
        if (project.creator == address(0)) revert ProjectNotFound(_projectId);
        if (project.creator != msg.sender) revert CallerNotProjectCreator();
        if (project.status != ProjectStatus.Active) revert InvalidProjectStatus(_projectId, ProjectStatus.Active);
        require(_milestoneId < project.milestones.length, "Invalid milestone ID");

        Milestone storage milestone = project.milestones[_milestoneId];
        if (milestone.status == MilestoneStatus.Verified) revert MilestoneAlreadyVerified(_projectId, _milestoneId);
        if (milestone.status != MilestoneStatus.Submitted) revert MilestoneProofNotSubmitted(_projectId, _milestoneId);

        milestone.status = MilestoneStatus.Verified;

        // Update reputation for the contributor who submitted the proof for this milestone
        address contributorAddress = milestone.lastContributor;
        if (contributorAddress != address(0)) {
            uint256 contributorSBTId = sbtContract.tokenOfOwnerByIndex(contributorAddress, 0); // Assuming 1 SBT per owner
            _updateReputationScore(contributorSBTId, 10, true); // Example increase of 10 reputation points
        }
        
        uint256 milestoneReward = (project.budget * milestone.rewardPercentage) / 100;
        emit MilestoneVerified(_projectId, _milestoneId, milestoneReward);
    }

    /**
     * @notice Allows participants to dispute a milestone's verification or completion.
     * @param _projectId The ID of the project.
     * @param _milestoneId The index of the milestone.
     * @param _reason The reason for the dispute.
     * @dev This would trigger an off-chain arbitration process, resolved by an admin/oracle.
     */
    function disputeMilestone(uint256 _projectId, uint256 _milestoneId, string calldata _reason) public whenNotPaused {
        Project storage project = _projects[_projectId];
        if (project.creator == address(0)) revert ProjectNotFound(_projectId);
        require(_milestoneId < project.milestones.length, "Invalid milestone ID");

        Milestone storage milestone = project.milestones[_milestoneId];
        require(milestone.status == MilestoneStatus.Submitted || milestone.status == MilestoneStatus.Verified, "Milestone not in disputable status");

        milestone.status = MilestoneStatus.Disputed;
        // Funds might be locked, or an arbitration fee required here.
        emit MilestoneDisputed(_projectId, _milestoneId, msg.sender, _reason);
    }

    // --- IV. Reputation & Incentives ---

    /**
     * @notice Internal function to dynamically adjust a participant's reputation.
     * @param _profileSBTId The tokenId of the profile.
     * @param _changeAmount The amount to change the reputation by.
     * @param _increase True to increase, false to decrease.
     * @dev Only callable internally by trusted roles (admin/AI Oracle).
     */
    function _updateReputationScore(uint256 _profileSBTId, uint256 _changeAmount, bool _increase) internal {
        // ownerOf will revert if _profileSBTId does not exist
        sbtContract.ownerOf(_profileSBTId);

        uint256 currentReputation = sbtContract.getTokenReputation(_profileSBTId);
        uint256 newReputation;
        if (_increase) {
            newReputation = currentReputation + _changeAmount;
        } else {
            newReputation = currentReputation > _changeAmount ? currentReputation - _changeAmount : 0;
        }
        sbtContract.updateReputation(_profileSBTId, newReputation);
    }

    /**
     * @notice Allows contributors to claim their share of project funds upon verified milestone completion.
     * @param _projectId The ID of the project.
     * @param _milestoneId The index of the milestone.
     * @param _profileSBTId The SBT ID of the contributor claiming the reward.
     * @dev Assumes the project budget (ETH) is held by the VSN contract.
     *      Reward is claimed by the contributor who submitted the proof for this milestone.
     */
    function claimProjectReward(uint256 _projectId, uint256 _milestoneId, uint256 _profileSBTId) public whenNotPaused {
        Project storage project = _projects[_projectId];
        if (project.creator == address(0)) revert ProjectNotFound(_projectId);
        if (sbtContract.ownerOf(_profileSBTId) != msg.sender) revert NotProfileOwner(_profileSBTId, msg.sender);
        require(_milestoneId < project.milestones.length, "Invalid milestone ID");

        Milestone storage milestone = project.milestones[_milestoneId];
        if (milestone.status != MilestoneStatus.Verified) revert InvalidMilestoneStatus(_milestoneId, MilestoneStatus.Verified);

        // Ensure the claimant is the recognized contributor for this milestone
        uint256 claimantSBTId = sbtContract.tokenOfOwnerByIndex(msg.sender, 0);
        require(claimantSBTId == _profileSBTId && project.contributors[claimantSBTId] && milestone.lastContributor == msg.sender, "Caller not the designated contributor for this milestone");

        if (project.milestoneRewardClaimed[_milestoneId][_profileSBTId]) revert MilestoneRewardAlreadyClaimed(_projectId, _milestoneId, _profileSBTId);

        uint256 individualReward = (project.budget * milestone.rewardPercentage) / 100;
        require(individualReward > 0, "No funds allocated for this milestone reward");
        
        // Ensure the contract holds enough funds
        require(address(this).balance >= individualReward, "Contract has insufficient balance for this reward");

        (bool success, ) = payable(msg.sender).call{value: individualReward}("");
        require(success, "Reward transfer failed");

        project.milestoneRewardClaimed[_milestoneId][_profileSBTId] = true;
        // Optionally, update the milestone status to Paid.
        milestone.status = MilestoneStatus.Paid;

        emit ProjectRewardClaimed(_projectId, _milestoneId, _profileSBTId, individualReward);
    }

    /**
     * @notice Allows a project creator to request an AI Oracle evaluation for complex matching or project assessment.
     * @param _projectId The ID of the project.
     * @param _profileSBTIds An array of SBT IDs to be evaluated (e.g., potential contributors).
     * @param _evaluationParams Arbitrary bytes for AI Oracle specific parameters.
     * @dev This function merely logs the request; the actual AI computation is off-chain.
     *      The AI Oracle would then process this request off-chain and potentially call `attestSkill`
     *      or a similar function with its recommendations.
     */
    function requestAIEvaluation(
        uint256 _projectId,
        uint256[] calldata _profileSBTIds,
        bytes calldata _evaluationParams
    ) public whenNotPaused {
        Project storage project = _projects[_projectId];
        if (project.creator == address(0)) revert ProjectNotFound(_projectId);
        if (project.creator != msg.sender) revert CallerNotProjectCreator();

        // This would typically involve sending a fee to the oracle, or relying on a subscription model.
        // For simplicity, we just log the request.
        emit AIEvaluationRequested(_projectId, _profileSBTIds, _evaluationParams);
    }

    // --- View Functions (Queries) ---

    /**
     * @notice A view function to retrieve all relevant details for a participant's SBT.
     * @param _owner The address of the SBT owner.
     * @return profileSBTId The tokenId of the profile.
     * @return reputation The current reputation score.
     * @return metadataURI The URI for the off-chain metadata.
     * @return skillAttestations List of attested skills (categoryId, level).
     */
    function getProfileDetails(address _owner) public view returns (
        uint256 profileSBTId,
        uint256 reputation,
        string memory metadataURI,
        uint256[] memory skillCategoryIds,
        uint256[] memory skillLevels
    ) {
        if (sbtContract.balanceOf(_owner) == 0) revert ProfileDoesNotExist(_owner);
        profileSBTId = sbtContract.tokenOfOwnerByIndex(_owner, 0); // Assuming one SBT per owner

        reputation = sbtContract.getTokenReputation(profileSBTId);
        metadataURI = sbtContract.tokenURI(profileSBTId);

        // Collect attested skills - this requires iterating through all registered skill categories
        uint256 currentMaxSkillId = _nextSkillCategoryId.current();
        uint256[] memory tempSkillCategoryIds = new uint256[](currentMaxSkillId);
        uint256[] memory tempSkillLevels = new uint256[](currentMaxSkillId);
        uint256 count = 0;

        for (uint256 i = 1; i <= currentMaxSkillId; i++) {
            if (_skillAttestations[profileSBTId][i] > 0) {
                tempSkillCategoryIds[count] = i;
                tempSkillLevels[count] = _skillAttestations[profileSBTId][i];
                count++;
            }
        }

        skillCategoryIds = new uint256[](count);
        skillLevels = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            skillCategoryIds[i] = tempSkillCategoryIds[i];
            skillLevels[i] = tempSkillLevels[i];
        }
    }

    /**
     * @notice A view function to retrieve project specifics.
     * @param _projectId The ID of the project.
     * @return projectStruct The full project struct details.
     */
    function getProjectDetails(uint256 _projectId) public view returns (
        Project memory projectStruct
    ) {
        Project storage project = _projects[_projectId];
        if (project.creator == address(0)) revert ProjectNotFound(_projectId);

        // Copy struct to memory for return
        projectStruct = project;
    }

    // --- Helper / Internal Functions ---

    /**
     * @notice Fallback function to allow receiving ETH for project funding.
     */
    receive() external payable {}
}
```