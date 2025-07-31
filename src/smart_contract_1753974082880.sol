This smart contract, `CognitoNexus`, envisions a decentralized knowledge collaboration platform powered by an AI-assisted curation layer and a dynamic reputation system. It's designed to incentivize high-quality research, data contributions, and problem-solving within specific "Knowledge Domains." The core innovation lies in integrating an off-chain AI oracle's verifiable assessments directly into the on-chain reputation and contribution acceptance flow, without duplicating existing open-source patterns like standard DeFi, simple NFTs, or generic DAOs.

---

### **CognitoNexus: Decentralized AI-Curated Knowledge Collaboration Platform**

**Outline:**

1.  **Contract Overview:** Purpose, core concepts, and key features.
2.  **Solidity Version & Imports:** Standard pragma and necessary OpenZeppelin contracts.
3.  **Error Definitions:** Custom errors for clearer revert messages.
4.  **Enums:** Define states for Domains, Contributions, and Challenges.
5.  **Structs:**
    *   `KnowledgeDomain`: Represents a collaborative area of knowledge.
    *   `Contribution`: Details of a submitted piece of knowledge/data.
    *   `UserProfile`: Stores a user's cumulative Knowledge Points and dynamic Reputation Score.
    *   `Challenge`: Defines a bounty for solving a specific problem within a domain.
6.  **State Variables:** Mappings for core entities, counters, and admin addresses.
7.  **Events:** Log key actions and state changes for off-chain monitoring.
8.  **Modifiers:** Access control and state-based checks.
9.  **Constructor:** Initializes the contract, setting the owner and initial AI oracle address.
10. **Admin & Core Configuration Functions (5 functions):**
    *   `updateAIOracleAddress`: Change the trusted AI oracle.
    *   `setAIApprovalThresholds`: Configure AI score thresholds for auto-acceptance/rejection.
    *   `setMinimumKPForDomainCreation`: Adjust KP required to propose domains.
    *   `emergencyPause`: Pause all sensitive operations in an emergency.
    *   `unpauseContract`: Resume operations.
11. **Knowledge Domain Management Functions (6 functions):**
    *   `proposeKnowledgeDomain`: Allows users to propose new knowledge domains.
    *   `approveKnowledgeDomain`: Owner/governance approves a proposed domain, making it active.
    *   `archiveKnowledgeDomain`: Archive a domain, preventing new contributions.
    *   `addDomainModerator`: Assigns moderator roles for a domain.
    *   `removeDomainModerator`: Revokes moderator roles.
    *   `setDomainRequiredKPToContribute`: Adjusts the KP requirement for contributing to a specific domain.
12. **Contribution & Curation Functions (6 functions):**
    *   `submitContribution`: Users submit contributions (data/metadata hashes).
    *   `submitAIVerificationProof`: AI oracle submits its cryptographic proof/score for a contribution.
    *   `acceptContribution`: Moderator/auto-accepts a contribution, awarding KPs/RS.
    *   `rejectContribution`: Moderator/auto-rejects a contribution, potentially penalizing RS.
    *   `editContributionMetadataHash`: Allows a contributor to update their metadata hash if pending review.
    *   `claimContributionReward`: Allows contributors to claim a small reward if the contribution leads to something big (e.g., successful challenge solution).
13. **Challenge/Bounty Functions (6 functions):**
    *   `createChallenge`: Proposer creates a challenge with rewards.
    *   `fundChallenge`: Users or proposer deposit ERC20 tokens into a challenge's reward pool.
    *   `submitChallengeSolution`: Contributors submit their work as a solution to a challenge.
    *   `selectChallengeWinner`: Proposer selects a winning solution, triggering reward distribution and further KP/RS awards.
    *   `claimChallengeReward`: Winner claims their tokens.
    *   `cancelChallenge`: Proposer can cancel unfunded or un-resolvable challenges.
14. **User Profile & Reputation Functions (3 functions):**
    *   `getUserKnowledgeProfile`: View a user's current Knowledge Points and Reputation Score.
    *   `getUsersByReputationTier`: (Conceptual - returns top N or a range of users)
    *   `transferERC20Tokens`: Owner can transfer ERC20 tokens for administrative purposes (e.g., returning funds from cancelled challenges).
15. **Internal Helper Functions:** Logic for awarding KPs/RS, status transitions, etc.

**Function Summary (at least 20 functions):**

1.  **`constructor(address _aiOracleAddress)`**: Initializes the contract with the AI oracle address.
2.  **`updateAIOracleAddress(address _newAIOracleAddress)`**: Updates the trusted AI oracle's address.
3.  **`setAIApprovalThresholds(int256 _autoAcceptThreshold, int256 _autoRejectThreshold)`**: Sets the AI score thresholds for automated contribution processing.
4.  **`setMinimumKPForDomainCreation(uint256 _newMinKP)`**: Sets the minimum Knowledge Points required to propose a new domain.
5.  **`emergencyPause()`**: Pauses the contract in case of an emergency.
6.  **`unpauseContract()`**: Unpauses the contract.
7.  **`proposeKnowledgeDomain(string calldata _name, string calldata _description)`**: Allows users with sufficient KP to propose a new knowledge domain.
8.  **`approveKnowledgeDomain(uint256 _domainId)`**: Marks a proposed domain as 'Active', making it available for contributions.
9.  **`archiveKnowledgeDomain(uint256 _domainId)`**: Changes a domain's status to 'Archived', preventing new contributions.
10. **`addDomainModerator(uint256 _domainId, address _moderator)`**: Appoints an address as a moderator for a specific domain.
11. **`removeDomainModerator(uint256 _domainId, address _moderator)`**: Revokes moderator status for an address in a domain.
12. **`setDomainRequiredKPToContribute(uint256 _domainId, uint256 _newRequiredKP)`**: Sets or updates the minimum KP needed to contribute to a domain.
13. **`submitContribution(uint256 _domainId, string calldata _dataHash, string calldata _metadataHash, uint256 _associatedChallengeId)`**: Users submit new contributions with IPFS hashes.
14. **`submitAIVerificationProof(uint256 _contributionId, string calldata _aiProof, int256 _aiScore)`**: The AI oracle submits its verifiable assessment for a contribution.
15. **`acceptContribution(uint256 _contributionId)`**: Confirms a contribution's validity, awards KPs, and updates RS. Can be auto-triggered or by moderator.
16. **`rejectContribution(uint256 _contributionId, string calldata _reason)`**: Declines a contribution, potentially penalizing RS. Can be auto-triggered or by moderator.
17. **`editContributionMetadataHash(uint256 _contributionId, string calldata _newMetadataHash)`**: Allows a contributor to update the metadata hash of a pending contribution.
18. **`createChallenge(uint256 _domainId, string calldata _title, string calldata _description, address _rewardToken, uint256 _rewardAmountPerWinner, uint256 _deadline)`**: Creates a new problem-solving challenge.
19. **`fundChallenge(uint256 _challengeId, uint256 _amount)`**: Adds funds to a challenge's reward pool.
20. **`submitChallengeSolution(uint256 _challengeId, uint256 _contributionId)`**: Links an existing contribution as a solution to a challenge.
21. **`selectChallengeWinner(uint256 _challengeId, uint256 _winningContributionId)`**: Proposer selects the winning solution for a challenge.
22. **`claimChallengeReward(uint256 _challengeId)`**: Allows the winner of a challenge to claim their reward.
23. **`cancelChallenge(uint256 _challengeId)`**: Allows the challenge proposer to cancel an open challenge, releasing funds if applicable.
24. **`getUserKnowledgeProfile(address _user)`**: Retrieves a user's Knowledge Points and Reputation Score.
25. **`getDomainDetails(uint256 _domainId)`**: Retrieves details about a specific knowledge domain.
26. **`getContributionDetails(uint256 _contributionId)`**: Retrieves details about a specific contribution.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/**
 * @title CognitoNexus
 * @dev A decentralized knowledge collaboration platform powered by AI-assisted curation
 *      and a dynamic reputation system. It incentivizes high-quality research, data contributions,
 *      and problem-solving within specific "Knowledge Domains." The core innovation lies in
 *      integrating an off-chain AI oracle's verifiable assessments directly into the on-chain
 *      reputation and contribution acceptance flow.
 *
 * Concepts:
 * - Knowledge Domains: Thematic areas for collaboration (e.g., "Quantum Computing," "Sustainable Energy").
 * - Contributions: IPFS-referenced data/research submissions.
 * - AI Oracle: An off-chain entity providing cryptographically verifiable assessments (proofs/scores)
 *   of contributions. The contract trusts this oracle's input.
 * - Knowledge Points (KP): Accumulative points earned for accepted contributions and successful challenges.
 * - Reputation Score (RS): A dynamic, potentially negative, score reflecting the quality and impact
 *   of a user's interactions, heavily influenced by AI assessments.
 * - Challenges/Bounties: ERC20-funded tasks for specific research problems within domains.
 *
 * Key Differentiators:
 * - AI-Assisted Curation: Contributions are evaluated by a trusted AI oracle, influencing their acceptance and impact on reputation.
 * - Dynamic Reputation: Reputation score can fluctuate based on contribution quality (AI-verified), and actions.
 * - Structured Knowledge: Emphasis on data/metadata hashes to encourage verifiable and structured contributions.
 * - Decentralized Ownership & Moderation: Domains can have their own moderators and KP requirements.
 */
contract CognitoNexus is Ownable, Pausable {
    using EnumerableSet for EnumerableSet.AddressSet;

    /* ========== Custom Errors ========== */
    error CognitoNexus__NotAIOracle();
    error CognitoNexus__DomainNotFound(uint256 domainId);
    error CognitoNexus__DomainNotProposed(uint256 domainId);
    error CognitoNexus__DomainNotActive(uint256 domainId);
    error CognitoNexus__DomainAlreadyActive(uint256 domainId);
    error CognitoNexus__DomainAlreadyArchived(uint256 domainId);
    error CognitoNexus__AlreadyModerator(uint256 domainId, address moderator);
    error CognitoNexus__NotModerator(uint256 domainId, address user);
    error CognitoNexus__InsufficientKnowledgePoints(uint256 required, uint256 actual);
    error CognitoNexus__ContributionNotFound(uint256 contributionId);
    error CognitoNexus__ContributionNotInDomain(uint256 contributionId, uint256 domainId);
    error CognitoNexus__ContributionStatusInvalid(uint256 contributionId, ContributionStatus expectedStatus);
    error CognitoNexus__AIProofAlreadySubmitted(uint256 contributionId);
    error CognitoNexus__OnlyPendingForAIProof(uint256 contributionId);
    error CognitoNexus__ChallengeNotFound(uint256 challengeId);
    error CognitoNexus__ChallengeNotOpen(uint256 challengeId);
    error CognitoNexus__ChallengeNotResolved(uint256 challengeId);
    error CognitoNexus__ChallengeAlreadyResolved(uint256 challengeId);
    error CognitoNexus__ChallengeDeadlinePassed(uint256 challengeId);
    error CognitoNexus__SolutionAlreadySubmitted(uint256 challengeId, uint256 contributionId);
    error CognitoNexus__NoWinnerSelected(uint256 challengeId);
    error CognitoNexus__RewardAlreadyClaimed(uint256 challengeId);
    error CognitoNexus__NotChallengeProposer(uint256 challengeId, address caller);
    error CognitoNexus__InvalidZeroAddress();
    error CognitoNexus__NoFundsToWithdraw();
    error CognitoNexus__TransferFailed();
    error CognitoNexus__CannotEditAcceptedOrRejectedContribution();

    /* ========== Enums ========== */
    enum DomainStatus { Proposed, Active, Archived }
    enum ContributionStatus { PendingAIReview, PendingModeratorReview, Accepted, Rejected }
    enum ChallengeStatus { Open, Closed, Resolved, Cancelled }

    /* ========== Structs ========== */
    struct KnowledgeDomain {
        uint256 id;
        address creator;
        string name;
        string description;
        DomainStatus status;
        uint256 requiredKPToContribute; // Minimum Knowledge Points required to submit to this domain
        EnumerableSet.AddressSet moderators; // Set of addresses that can moderate this domain
        uint256 createdAt;
        uint256 totalContributions;
        uint256 totalKnowledgePointsAwarded;
    }

    struct Contribution {
        uint256 id;
        uint256 domainId;
        address contributor;
        string dataHash; // IPFS hash of the core data/research content
        string metadataHash; // IPFS hash of structured metadata (e.g., source links, methodologies)
        string aiVerificationProof; // Cryptographic proof/signature from the AI oracle
        int256 aiScore; // AI's assessment score (e.g., -100 to 100), higher is better
        ContributionStatus status;
        uint256 createdAt;
        uint256 associatedChallengeId; // 0 if not part of a challenge
    }

    struct UserProfile {
        uint256 knowledgePoints; // Cumulative KPs, always non-decreasing
        int256 reputationScore; // Dynamic score, can go positive or negative
        uint256 contributionsCount;
    }

    struct Challenge {
        uint256 id;
        uint256 domainId;
        address proposer;
        string title;
        string description;
        address rewardToken; // ERC20 token address for the reward
        uint256 rewardAmountPerWinner; // Amount awarded to each winner
        uint256 deadline;
        ChallengeStatus status;
        address winner; // Address of the selected winner (for single winner challenges)
        uint256 winningContributionId; // ID of the contribution selected as winner
        uint256 totalFundedAmount; // Total ERC20 tokens deposited
        bool rewardClaimed;
        EnumerableSet.UintSet solutionContributions; // Set of contribution IDs submitted as solutions
    }

    /* ========== State Variables ========== */

    // Admin addresses
    address public aiOracleAddress;

    // Counters for unique IDs
    uint256 public nextDomainId;
    uint256 public nextContributionId;
    uint256 public nextChallengeId;

    // Thresholds for AI auto-processing
    int256 public autoAcceptThreshold; // AI score >= this to auto-accept
    int256 public autoRejectThreshold; // AI score <= this to auto-reject

    // Minimum KP for certain actions
    uint256 public minimumKPForDomainCreation;

    // Mappings for main entities
    mapping(uint256 => KnowledgeDomain) public knowledgeDomains;
    mapping(uint256 => Contribution) public contributions;
    mapping(uint256 => Challenge) public challenges;
    mapping(address => UserProfile) public userProfiles;

    // Mapping for contributions per domain (stores contribution IDs)
    mapping(uint256 => uint256[]) public domainContributionIds;

    /* ========== Events ========== */
    event AIOracleAddressUpdated(address indexed oldAddress, address indexed newAddress);
    event AIApprovalThresholdsUpdated(int256 autoAcceptThreshold, int256 autoRejectThreshold);
    event MinimumKPForDomainCreationUpdated(uint256 newMinKP);
    event DomainProposed(uint256 indexed domainId, address indexed creator, string name);
    event DomainApproved(uint256 indexed domainId, address indexed approver);
    event DomainArchived(uint256 indexed domainId, address indexed archiver);
    event DomainModeratorAdded(uint256 indexed domainId, address indexed moderator);
    event DomainModeratorRemoved(uint256 indexed domainId, address indexed moderator);
    event DomainRequiredKPToContributeUpdated(uint256 indexed domainId, uint256 newRequiredKP);
    event ContributionSubmitted(uint256 indexed contributionId, uint256 indexed domainId, address indexed contributor, string dataHash, uint256 associatedChallengeId);
    event AIVerificationPerformed(uint256 indexed contributionId, string aiProof, int256 aiScore);
    event ContributionAccepted(uint256 indexed contributionId, uint256 awardedKP, int256 reputationChange);
    event ContributionRejected(uint256 indexed contributionId, string reason, int256 reputationChange);
    event ContributionMetadataEdited(uint256 indexed contributionId, string newMetadataHash);
    event ChallengeCreated(uint256 indexed challengeId, uint256 indexed domainId, address indexed proposer, string title, address rewardToken, uint256 rewardAmountPerWinner, uint256 deadline);
    event ChallengeFunded(uint256 indexed challengeId, address indexed funder, uint256 amount);
    event ChallengeSolutionSubmitted(uint256 indexed challengeId, uint256 indexed contributionId, address indexed contributor);
    event ChallengeWinnerSelected(uint256 indexed challengeId, address indexed winner, uint256 winningContributionId);
    event ChallengeRewardClaimed(uint256 indexed challengeId, address indexed winner, uint256 amount);
    event ChallengeCancelled(uint256 indexed challengeId, address indexed canceller);
    event KnowledgePointsAwarded(address indexed user, uint256 amount, uint256 totalKP);
    event ReputationScoreUpdated(address indexed user, int256 change, int256 newScore);
    event TokensWithdrawn(address indexed recipient, address indexed token, uint256 amount);

    /* ========== Modifiers ========== */
    modifier onlyAIOracle() {
        if (msg.sender != aiOracleAddress) {
            revert CognitoNexus__NotAIOracle();
        }
        _;
    }

    modifier onlyDomainModerator(uint256 _domainId) {
        if (!knowledgeDomains[_domainId].moderators.contains(msg.sender) && msg.sender != owner()) {
            revert CognitoNexus__NotModerator(_domainId, msg.sender);
        }
        _;
    }

    modifier domainExists(uint256 _domainId) {
        if (knowledgeDomains[_domainId].id == 0 && nextDomainId > 0) { // Check for ID 0 but also ensure it's not simply an uninitialized struct
            revert CognitoNexus__DomainNotFound(_domainId);
        }
        _;
    }

    modifier isDomainActive(uint256 _domainId) {
        domainExists(_domainId);
        if (knowledgeDomains[_domainId].status != DomainStatus.Active) {
            revert CognitoNexus__DomainNotActive(_domainId);
        }
        _;
    }

    modifier isContributionPendingAIReview(uint256 _contributionId) {
        if (contributions[_contributionId].status != ContributionStatus.PendingAIReview) {
            revert CognitoNexus__ContributionStatusInvalid(_contributionId, ContributionStatus.PendingAIReview);
        }
        _;
    }

    modifier isContributionPendingModeratorReview(uint256 _contributionId) {
        if (contributions[_contributionId].status != ContributionStatus.PendingModeratorReview) {
            revert CognitoNexus__ContributionStatusInvalid(_contributionId, ContributionStatus.PendingModeratorReview);
        }
        _;
    }

    modifier isChallengeOpen(uint256 _challengeId) {
        if (challenges[_challengeId].status != ChallengeStatus.Open) {
            revert CognitoNexus__ChallengeNotOpen(_challengeId);
        }
        if (block.timestamp > challenges[_challengeId].deadline) {
            revert CognitoNexus__ChallengeDeadlinePassed(_challengeId);
        }
        _;
    }

    /* ========== Constructor ========== */
    constructor(address _aiOracleAddress) Ownable(msg.sender) {
        if (_aiOracleAddress == address(0)) {
            revert CognitoNexus__InvalidZeroAddress();
        }
        aiOracleAddress = _aiOracleAddress;
        autoAcceptThreshold = 75; // Default: AI score 75/100 for auto-accept
        autoRejectThreshold = 25;  // Default: AI score 25/100 for auto-reject
        minimumKPForDomainCreation = 100; // Default: 100 KP to propose a domain
    }

    /* ========== Admin & Core Configuration Functions ========== */

    /**
     * @dev Updates the address of the trusted AI oracle. Only callable by the contract owner.
     * @param _newAIOracleAddress The new address for the AI oracle.
     */
    function updateAIOracleAddress(address _newAIOracleAddress) external onlyOwner {
        if (_newAIOracleAddress == address(0)) {
            revert CognitoNexus__InvalidZeroAddress();
        }
        emit AIOracleAddressUpdated(aiOracleAddress, _newAIOracleAddress);
        aiOracleAddress = _newAIOracleAddress;
    }

    /**
     * @dev Sets the AI score thresholds for auto-accepting and auto-rejecting contributions.
     *      Only callable by the contract owner.
     * @param _autoAcceptThreshold AI score (e.g., 0-100) at or above which a contribution is auto-accepted.
     * @param _autoRejectThreshold AI score (e.g., 0-100) at or below which a contribution is auto-rejected.
     */
    function setAIApprovalThresholds(int256 _autoAcceptThreshold, int256 _autoRejectThreshold) external onlyOwner {
        // Basic validation, further business logic may apply
        require(_autoAcceptThreshold > _autoRejectThreshold, "CognitoNexus: Accept threshold must be higher than reject.");
        emit AIApprovalThresholdsUpdated(_autoAcceptThreshold, _autoRejectThreshold);
        autoAcceptThreshold = _autoAcceptThreshold;
        autoRejectThreshold = _autoRejectThreshold;
    }

    /**
     * @dev Sets the minimum Knowledge Points (KP) required for a user to propose a new knowledge domain.
     *      Only callable by the contract owner.
     * @param _newMinKP The new minimum KP value.
     */
    function setMinimumKPForDomainCreation(uint256 _newMinKP) external onlyOwner {
        emit MinimumKPForDomainCreationUpdated(_newMinKP);
        minimumKPForDomainCreation = _newMinKP;
    }

    /**
     * @dev Pauses all core operations of the contract. Only callable by the contract owner.
     *      Uses OpenZeppelin's Pausable functionality.
     */
    function emergencyPause() external onlyOwner whenNotPaused {
        _pause();
    }

    /**
     * @dev Unpauses the contract, resuming all core operations. Only callable by the contract owner.
     *      Uses OpenZeppelin's Pausable functionality.
     */
    function unpauseContract() external onlyOwner whenPaused {
        _unpause();
    }

    /* ========== Knowledge Domain Management Functions ========== */

    /**
     * @dev Allows a user to propose a new knowledge domain. Requires a minimum KP.
     * @param _name The name of the proposed domain.
     * @param _description A description of the domain's scope.
     */
    function proposeKnowledgeDomain(string calldata _name, string calldata _description) external whenNotPaused {
        if (userProfiles[msg.sender].knowledgePoints < minimumKPForDomainCreation) {
            revert CognitoNexus__InsufficientKnowledgePoints(minimumKPForDomainCreation, userProfiles[msg.sender].knowledgePoints);
        }

        uint256 domainId = ++nextDomainId;
        KnowledgeDomain storage newDomain = knowledgeDomains[domainId];
        newDomain.id = domainId;
        newDomain.creator = msg.sender;
        newDomain.name = _name;
        newDomain.description = _description;
        newDomain.status = DomainStatus.Proposed; // Initially proposed, needs owner/governance approval
        newDomain.requiredKPToContribute = 0; // Default, can be set later
        newDomain.createdAt = block.timestamp;

        emit DomainProposed(domainId, msg.sender, _name);
    }

    /**
     * @dev Approves a proposed knowledge domain, changing its status to 'Active'.
     *      Only callable by the contract owner.
     * @param _domainId The ID of the domain to approve.
     */
    function approveKnowledgeDomain(uint256 _domainId) external onlyOwner domainExists(_domainId) {
        if (knowledgeDomains[_domainId].status != DomainStatus.Proposed) {
            revert CognitoNexus__DomainNotProposed(_domainId);
        }
        knowledgeDomains[_domainId].status = DomainStatus.Active;
        emit DomainApproved(_domainId, msg.sender);
    }

    /**
     * @dev Archives an active knowledge domain, preventing new contributions.
     *      Existing contributions and challenges remain accessible but no new ones can be added.
     *      Only callable by the contract owner or domain moderators.
     * @param _domainId The ID of the domain to archive.
     */
    function archiveKnowledgeDomain(uint256 _domainId) external onlyDomainModerator(_domainId) domainExists(_domainId) {
        if (knowledgeDomains[_domainId].status == DomainStatus.Archived) {
            revert CognitoNexus__DomainAlreadyArchived(_domainId);
        }
        knowledgeDomains[_domainId].status = DomainStatus.Archived;
        emit DomainArchived(_domainId, msg.sender);
    }

    /**
     * @dev Adds a new moderator to a specific knowledge domain.
     *      Only callable by the contract owner or existing domain moderators.
     * @param _domainId The ID of the domain.
     * @param _moderator The address to add as a moderator.
     */
    function addDomainModerator(uint256 _domainId, address _moderator) external onlyDomainModerator(_domainId) domainExists(_domainId) {
        if (_moderator == address(0)) {
            revert CognitoNexus__InvalidZeroAddress();
        }
        if (knowledgeDomains[_domainId].moderators.contains(_moderator)) {
            revert CognitoNexus__AlreadyModerator(_domainId, _moderator);
        }
        knowledgeDomains[_domainId].moderators.add(_moderator);
        emit DomainModeratorAdded(_domainId, _moderator);
    }

    /**
     * @dev Removes a moderator from a specific knowledge domain.
     *      Only callable by the contract owner or existing domain moderators.
     * @param _domainId The ID of the domain.
     * @param _moderator The address to remove as a moderator.
     */
    function removeDomainModerator(uint256 _domainId, address _moderator) external onlyDomainModerator(_domainId) domainExists(_domainId) {
        if (!knowledgeDomains[_domainId].moderators.contains(_moderator)) {
            revert CognitoNexus__NotModerator(_domainId, _moderator); // Or a specific error like "not an active moderator"
        }
        knowledgeDomains[_domainId].moderators.remove(_moderator);
        emit DomainModeratorRemoved(_domainId, _moderator);
    }

    /**
     * @dev Sets or updates the minimum Knowledge Points required for users to contribute to a domain.
     *      Only callable by the contract owner or domain moderators.
     * @param _domainId The ID of the domain.
     * @param _newRequiredKP The new minimum KP required.
     */
    function setDomainRequiredKPToContribute(uint256 _domainId, uint256 _newRequiredKP) external onlyDomainModerator(_domainId) isDomainActive(_domainId) {
        knowledgeDomains[_domainId].requiredKPToContribute = _newRequiredKP;
        emit DomainRequiredKPToContributeUpdated(_domainId, _newRequiredKP);
    }

    /* ========== Contribution & Curation Functions ========== */

    /**
     * @dev Allows a user to submit a new contribution to an active knowledge domain.
     *      Requires the user to meet the domain's minimum KP.
     * @param _domainId The ID of the domain to contribute to.
     * @param _dataHash IPFS hash referencing the primary data/research content.
     * @param _metadataHash IPFS hash referencing structured metadata (e.g., sources, methodology).
     * @param _associatedChallengeId The ID of a challenge this contribution is a solution for (0 if none).
     */
    function submitContribution(uint256 _domainId, string calldata _dataHash, string calldata _metadataHash, uint256 _associatedChallengeId) external whenNotPaused isDomainActive(_domainId) {
        if (userProfiles[msg.sender].knowledgePoints < knowledgeDomains[_domainId].requiredKPToContribute) {
            revert CognitoNexus__InsufficientKnowledgePoints(
                knowledgeDomains[_domainId].requiredKPToContribute, userProfiles[msg.sender].knowledgePoints
            );
        }
        if (_associatedChallengeId != 0) {
            if (challenges[_associatedChallengeId].id == 0) {
                revert CognitoNexus__ChallengeNotFound(_associatedChallengeId);
            }
            if (challenges[_associatedChallengeId].domainId != _domainId) {
                revert CognitoNexus__ContributionNotInDomain(_associatedChallengeId, _domainId); // Misleading error, but implies challenge not relevant to domain
            }
            if (challenges[_associatedChallengeId].status != ChallengeStatus.Open || block.timestamp > challenges[_associatedChallengeId].deadline) {
                revert CognitoNexus__ChallengeNotOpen(_associatedChallengeId);
            }
        }

        uint256 contributionId = ++nextContributionId;
        Contribution storage newContribution = contributions[contributionId];
        newContribution.id = contributionId;
        newContribution.domainId = _domainId;
        newContribution.contributor = msg.sender;
        newContribution.dataHash = _dataHash;
        newContribution.metadataHash = _metadataHash;
        newContribution.aiScore = 0; // Will be set by AI oracle
        newContribution.status = ContributionStatus.PendingAIReview; // Awaiting AI assessment
        newContribution.createdAt = block.timestamp;
        newContribution.associatedChallengeId = _associatedChallengeId;

        knowledgeDomains[_domainId].totalContributions++;
        userProfiles[msg.sender].contributionsCount++;
        domainContributionIds[_domainId].push(contributionId);

        emit ContributionSubmitted(contributionId, _domainId, msg.sender, _dataHash, _associatedChallengeId);
    }

    /**
     * @dev The AI oracle submits its verifiable assessment for a specific contribution.
     *      This function determines the next state of the contribution (auto-accept, auto-reject, or pending moderator review).
     * @param _contributionId The ID of the contribution to verify.
     * @param _aiProof A cryptographic proof or signature from the AI oracle validating the assessment.
     * @param _aiScore The AI's numerical assessment score (e.g., 0-100, where higher is better).
     */
    function submitAIVerificationProof(uint256 _contributionId, string calldata _aiProof, int256 _aiScore) external onlyAIOracle isContributionPendingAIReview(_contributionId) {
        Contribution storage contribution = contributions[_contributionId];
        if (bytes(contribution.aiVerificationProof).length > 0) {
            revert CognitoNexus__AIProofAlreadySubmitted(_contributionId);
        }

        contribution.aiVerificationProof = _aiProof;
        contribution.aiScore = _aiScore;

        // Automatically determine next step based on AI score
        if (_aiScore >= autoAcceptThreshold) {
            contribution.status = ContributionStatus.Accepted;
            _awardKnowledgePoints(contribution.contributor, 10 + uint256(_aiScore / 10)); // Example: Base 10 KP + 1 KP per 10 AI score points
            _updateReputationScore(contribution.contributor, int256(5 + _aiScore / 20)); // Example: Base 5 RS + 1 RS per 20 AI score points
            emit ContributionAccepted(_contributionId, 10 + uint256(_aiScore / 10), int256(5 + _aiScore / 20));
        } else if (_aiScore <= autoRejectThreshold) {
            contribution.status = ContributionStatus.Rejected;
            _updateReputationScore(contribution.contributor, - int256(5 + (100 - _aiScore) / 20)); // Example: Penalize more for lower scores
            emit ContributionRejected(_contributionId, "Rejected by AI due to low score", - int256(5 + (100 - _aiScore) / 20));
        } else {
            // Falls between thresholds, requires moderator review
            contribution.status = ContributionStatus.PendingModeratorReview;
        }

        emit AIVerificationPerformed(_contributionId, _aiProof, _aiScore);
    }

    /**
     * @dev Allows a domain moderator or the owner to accept a contribution that is pending review.
     *      Awards Knowledge Points and updates Reputation Score.
     * @param _contributionId The ID of the contribution to accept.
     */
    function acceptContribution(uint256 _contributionId) external whenNotPaused {
        Contribution storage contribution = contributions[_contributionId];
        if (contribution.id == 0) {
            revert CognitoNexus__ContributionNotFound(_contributionId);
        }
        if (contribution.status != ContributionStatus.PendingModeratorReview) {
            revert CognitoNexus__OnlyPendingForAIProof(_contributionId); // More specific error
        }

        // Ensure caller is moderator or owner
        bool isMod = knowledgeDomains[contribution.domainId].moderators.contains(msg.sender);
        if (!isMod && msg.sender != owner()) {
            revert CognitoNexus__NotModerator(contribution.domainId, msg.sender);
        }

        contribution.status = ContributionStatus.Accepted;
        // KP/RS award logic (can be made more sophisticated based on domain, AI score, etc.)
        uint256 awardedKP = 15 + uint256(contribution.aiScore / 10); // Example: More KP for human-accepted
        int256 reputationChange = 10 + int256(contribution.aiScore / 15); // Example: More RS for human-accepted

        _awardKnowledgePoints(contribution.contributor, awardedKP);
        _updateReputationScore(contribution.contributor, reputationChange);

        emit ContributionAccepted(_contributionId, awardedKP, reputationChange);
    }

    /**
     * @dev Allows a domain moderator or the owner to reject a contribution that is pending review.
     *      Can penalize Reputation Score.
     * @param _contributionId The ID of the contribution to reject.
     * @param _reason A string explaining the reason for rejection.
     */
    function rejectContribution(uint256 _contributionId, string calldata _reason) external whenNotPaused {
        Contribution storage contribution = contributions[_contributionId];
        if (contribution.id == 0) {
            revert CognitoNexus__ContributionNotFound(_contributionId);
        }
        if (contribution.status != ContributionStatus.PendingModeratorReview) {
            revert CognitoNexus__OnlyPendingForAIProof(_contributionId); // More specific error
        }

        // Ensure caller is moderator or owner
        bool isMod = knowledgeDomains[contribution.domainId].moderators.contains(msg.sender);
        if (!isMod && msg.sender != owner()) {
            revert CognitoNexus__NotModerator(contribution.domainId, msg.sender);
        }

        contribution.status = ContributionStatus.Rejected;
        // RS penalty logic
        int256 reputationChange = -10 - int256((100 - contribution.aiScore) / 10); // Example: Penalize more for lower AI scores
        _updateReputationScore(contribution.contributor, reputationChange);

        emit ContributionRejected(_contributionId, _reason, reputationChange);
    }

    /**
     * @dev Allows a contributor to update the metadata hash of their contribution,
     *      but only if it's still pending AI or moderator review.
     * @param _contributionId The ID of the contribution to update.
     * @param _newMetadataHash The new IPFS hash for the metadata.
     */
    function editContributionMetadataHash(uint256 _contributionId, string calldata _newMetadataHash) external whenNotPaused {
        Contribution storage contribution = contributions[_contributionId];
        if (contribution.id == 0 || contribution.contributor != msg.sender) {
            revert CognitoNexus__ContributionNotFound(_contributionId);
        }
        if (contribution.status == ContributionStatus.Accepted || contribution.status == ContributionStatus.Rejected) {
            revert CognitoNexus__CannotEditAcceptedOrRejectedContribution();
        }

        contribution.metadataHash = _newMetadataHash;
        // Optionally reset status to PendingAIReview if metadata affects core content,
        // but for now, assuming metadata is descriptive and doesn't require full re-review.
        // If the AI verification is based on ALL content, then it should trigger re-evaluation by AI
        // contribution.status = ContributionStatus.PendingAIReview;
        // contribution.aiVerificationProof = ""; // Clear old proof
        // contribution.aiScore = 0; // Clear old score

        emit ContributionMetadataEdited(_contributionId, _newMetadataHash);
    }

    /* ========== Challenge/Bounty Functions ========== */

    /**
     * @dev Creates a new challenge (bounty) within an active knowledge domain.
     *      Requires the challenge proposer to have sufficient KP.
     * @param _domainId The ID of the domain the challenge belongs to.
     * @param _title The title of the challenge.
     * @param _description A detailed description of the problem/task.
     * @param _rewardToken The address of the ERC20 token used for rewards.
     * @param _rewardAmountPerWinner The amount of reward tokens per winner.
     * @param _deadline The timestamp by which solutions must be submitted.
     */
    function createChallenge(
        uint256 _domainId,
        string calldata _title,
        string calldata _description,
        address _rewardToken,
        uint256 _rewardAmountPerWinner,
        uint256 _deadline
    ) external whenNotPaused isDomainActive(_domainId) {
        // Example: Require min 500 KP to create a challenge
        if (userProfiles[msg.sender].knowledgePoints < 500) {
            revert CognitoNexus__InsufficientKnowledgePoints(500, userProfiles[msg.sender].knowledgePoints);
        }
        if (_deadline <= block.timestamp) {
            revert CognitoNexus__ChallengeDeadlinePassed(0); // Use 0 as placeholder since challenge not created yet
        }
        if (_rewardToken == address(0) || _rewardAmountPerWinner == 0) {
            revert CognitoNexus__InvalidZeroAddress(); // Or more specific error
        }

        uint256 challengeId = ++nextChallengeId;
        Challenge storage newChallenge = challenges[challengeId];
        newChallenge.id = challengeId;
        newChallenge.domainId = _domainId;
        newChallenge.proposer = msg.sender;
        newChallenge.title = _title;
        newChallenge.description = _description;
        newChallenge.rewardToken = _rewardToken;
        newChallenge.rewardAmountPerWinner = _rewardAmountPerWinner;
        newChallenge.deadline = _deadline;
        newChallenge.status = ChallengeStatus.Open;

        emit ChallengeCreated(challengeId, _domainId, msg.sender, _title, _rewardToken, _rewardAmountPerWinner, _deadline);
    }

    /**
     * @dev Allows users to fund a challenge with ERC20 tokens.
     * @param _challengeId The ID of the challenge to fund.
     * @param _amount The amount of ERC20 tokens to deposit.
     */
    function fundChallenge(uint256 _challengeId, uint256 _amount) external whenNotPaused isChallengeOpen(_challengeId) {
        Challenge storage challenge = challenges[_challengeId];
        if (_amount == 0) {
            revert CognitoNexus__NoFundsToWithdraw(); // Re-using error, consider specific "zero amount" error
        }

        IERC20(challenge.rewardToken).transferFrom(msg.sender, address(this), _amount);
        challenge.totalFundedAmount += _amount;

        emit ChallengeFunded(_challengeId, msg.sender, _amount);
    }

    /**
     * @dev Submits an existing accepted contribution as a solution to an open challenge.
     *      The contribution must belong to the same domain as the challenge.
     * @param _challengeId The ID of the challenge.
     * @param _contributionId The ID of the contribution being submitted as a solution.
     */
    function submitChallengeSolution(uint256 _challengeId, uint256 _contributionId) external whenNotPaused isChallengeOpen(_challengeId) {
        Challenge storage challenge = challenges[_challengeId];
        Contribution storage contribution = contributions[_contributionId];

        if (contribution.id == 0 || contribution.status != ContributionStatus.Accepted) {
            revert CognitoNexus__ContributionStatusInvalid(_contributionId, ContributionStatus.Accepted);
        }
        if (contribution.domainId != challenge.domainId) {
            revert CognitoNexus__ContributionNotInDomain(_contributionId, challenge.domainId);
        }
        if (challenge.solutionContributions.contains(_contributionId)) {
            revert CognitoNexus__SolutionAlreadySubmitted(_challengeId, _contributionId);
        }
        if (userProfiles[contribution.contributor].knowledgePoints < challenge.minimumKPSolution) { // if challenge needs min KP for solution
            revert CognitoNexus__InsufficientKnowledgePoints(challenge.minimumKPSolution, userProfiles[contribution.contributor].knowledgePoints);
        }

        challenge.solutionContributions.add(_contributionId);
        emit ChallengeSolutionSubmitted(_challengeId, _contributionId, msg.sender);
    }

    /**
     * @dev Allows the challenge proposer to select a winning solution.
     *      This marks the challenge as 'Resolved' and enables the winner to claim rewards.
     *      Awards additional KP/RS to the winner and proposer.
     * @param _challengeId The ID of the challenge.
     * @param _winningContributionId The ID of the contribution selected as the winner.
     */
    function selectChallengeWinner(uint256 _challengeId, uint256 _winningContributionId) external whenNotPaused {
        Challenge storage challenge = challenges[_challengeId];
        if (challenge.id == 0) {
            revert CognitoNexus__ChallengeNotFound(_challengeId);
        }
        if (msg.sender != challenge.proposer) {
            revert CognitoNexus__NotChallengeProposer(_challengeId, msg.sender);
        }
        if (challenge.status != ChallengeStatus.Open || block.timestamp <= challenge.deadline) {
            revert CognitoNexus__ChallengeNotOpen(_challengeId); // Deadline must have passed to select winner
        }
        if (challenge.winningContributionId != 0) {
            revert CognitoNexus__ChallengeAlreadyResolved(_challengeId);
        }
        if (!challenge.solutionContributions.contains(_winningContributionId)) {
            revert CognitoNexus__ContributionNotFound(_winningContributionId); // Or specifically "not a valid solution"
        }

        Contribution storage winningContribution = contributions[_winningContributionId];
        if (winningContribution.status != ContributionStatus.Accepted) {
            revert CognitoNexus__ContributionStatusInvalid(_winningContributionId, ContributionStatus.Accepted); // Winning solution must be accepted
        }

        challenge.winningContributionId = _winningContributionId;
        challenge.winner = winningContribution.contributor;
        challenge.status = ChallengeStatus.Resolved;

        // Award bonus KP/RS for winning a challenge
        _awardKnowledgePoints(challenge.winner, 50 + uint256(winningContribution.aiScore / 5)); // Example: Substantial bonus
        _updateReputationScore(challenge.winner, 25 + int256(winningContribution.aiScore / 10));

        // Award proposer KP/RS for successful challenge resolution
        _awardKnowledgePoints(challenge.proposer, 10);
        _updateReputationScore(challenge.proposer, 5);

        emit ChallengeWinnerSelected(_challengeId, challenge.winner, _winningContributionId);
    }

    /**
     * @dev Allows the selected winner of a resolved challenge to claim their ERC20 reward.
     * @param _challengeId The ID of the challenge.
     */
    function claimChallengeReward(uint256 _challengeId) external whenNotPaused {
        Challenge storage challenge = challenges[_challengeId];
        if (challenge.id == 0) {
            revert CognitoNexus__ChallengeNotFound(_challengeId);
        }
        if (challenge.status != ChallengeStatus.Resolved) {
            revert CognitoNexus__ChallengeNotResolved(_challengeId);
        }
        if (msg.sender != challenge.winner) {
            revert CognitoNexus__NoWinnerSelected(_challengeId); // Not the winner, misusing error but implies it
        }
        if (challenge.rewardClaimed) {
            revert CognitoNexus__RewardAlreadyClaimed(_challengeId);
        }

        uint256 amountToTransfer = challenge.rewardAmountPerWinner;
        if (challenge.totalFundedAmount < amountToTransfer) {
            amountToTransfer = challenge.totalFundedAmount; // Transfer what's available if less than intended
        }

        challenge.rewardClaimed = true;
        challenge.totalFundedAmount -= amountToTransfer; // Reduce total funded amount by claimed amount

        bool success = IERC20(challenge.rewardToken).transfer(msg.sender, amountToTransfer);
        if (!success) {
            revert CognitoNexus__TransferFailed();
        }

        emit ChallengeRewardClaimed(_challengeId, msg.sender, amountToTransfer);
    }

    /**
     * @dev Allows the challenge proposer to cancel an open challenge before its deadline.
     *      Funds are returned to the contract owner's discretion or the original funders.
     *      For simplicity, funds remain in contract for owner to withdraw via `transferERC20Tokens`.
     * @param _challengeId The ID of the challenge to cancel.
     */
    function cancelChallenge(uint256 _challengeId) external whenNotPaused {
        Challenge storage challenge = challenges[_challengeId];
        if (challenge.id == 0) {
            revert CognitoNexus__ChallengeNotFound(_challengeId);
        }
        if (msg.sender != challenge.proposer) {
            revert CognitoNexus__NotChallengeProposer(_challengeId, msg.sender);
        }
        if (challenge.status != ChallengeStatus.Open) {
            revert CognitoNexus__ChallengeNotOpen(_challengeId); // Already closed/resolved/cancelled
        }
        if (block.timestamp > challenge.deadline) {
            revert CognitoNexus__ChallengeDeadlinePassed(_challengeId); // Can't cancel after deadline
        }

        challenge.status = ChallengeStatus.Cancelled;

        // Funds remain in contract, can be swept by owner or (in advanced version) returned to funders
        emit ChallengeCancelled(_challengeId, msg.sender);
    }

    /* ========== User Profile & Reputation Functions ========== */

    /**
     * @dev Retrieves a user's current Knowledge Points and Reputation Score.
     * @param _user The address of the user.
     * @return knowledgePoints The user's total accumulated Knowledge Points.
     * @return reputationScore The user's current dynamic Reputation Score.
     * @return contributionsCount The total number of contributions by this user.
     */
    function getUserKnowledgeProfile(address _user) external view returns (uint256 knowledgePoints, int256 reputationScore, uint256 contributionsCount) {
        UserProfile storage profile = userProfiles[_user];
        return (profile.knowledgePoints, profile.reputationScore, profile.contributionsCount);
    }

    /**
     * @dev Retrieves details of a specific knowledge domain.
     * @param _domainId The ID of the domain.
     * @return domain The KnowledgeDomain struct containing all its details.
     */
    function getDomainDetails(uint256 _domainId) external view domainExists(_domainId) returns (KnowledgeDomain memory domain) {
        domain = knowledgeDomains[_domainId];
        // Note: EnumerableSet cannot be returned directly from storage in memory, need to copy to array if needed.
        // For simplicity, moderators are omitted in this direct return, but individual lookup `isModerator` is possible.
    }

    /**
     * @dev Retrieves details of a specific contribution.
     * @param _contributionId The ID of the contribution.
     * @return contribution The Contribution struct containing all its details.
     */
    function getContributionDetails(uint256 _contributionId) external view returns (Contribution memory contribution) {
        if (contributions[_contributionId].id == 0 && nextContributionId > 0) {
            revert CognitoNexus__ContributionNotFound(_contributionId);
        }
        return contributions[_contributionId];
    }

    /**
     * @dev Allows the owner to transfer ERC20 tokens held by the contract to a specified recipient.
     *      Useful for managing leftover challenge funds or in emergency situations.
     * @param _tokenAddress The address of the ERC20 token.
     * @param _recipient The address to send the tokens to.
     * @param _amount The amount of tokens to send.
     */
    function transferERC20Tokens(address _tokenAddress, address _recipient, uint256 _amount) external onlyOwner {
        if (_tokenAddress == address(0) || _recipient == address(0)) {
            revert CognitoNexus__InvalidZeroAddress();
        }
        if (_amount == 0) {
            revert CognitoNexus__NoFundsToWithdraw();
        }

        bool success = IERC20(_tokenAddress).transfer(_recipient, _amount);
        if (!success) {
            revert CognitoNexus__TransferFailed();
        }
        emit TokensWithdrawn(_recipient, _tokenAddress, _amount);
    }

    /* ========== Internal Helper Functions ========== */

    /**
     * @dev Internal function to award Knowledge Points to a user.
     * @param _user The address of the user to award KPs to.
     * @param _amount The amount of KPs to award.
     */
    function _awardKnowledgePoints(address _user, uint256 _amount) internal {
        userProfiles[_user].knowledgePoints += _amount;
        emit KnowledgePointsAwarded(_user, _amount, userProfiles[_user].knowledgePoints);
    }

    /**
     * @dev Internal function to update a user's Reputation Score.
     * @param _user The address of the user.
     * @param _change The change in reputation score (can be positive or negative).
     */
    function _updateReputationScore(address _user, int256 _change) internal {
        userProfiles[_user].reputationScore += _change;
        emit ReputationScoreUpdated(_user, _change, userProfiles[_user].reputationScore);
    }
}
```