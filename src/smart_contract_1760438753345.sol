Here's a smart contract in Solidity called "NexusChronicle" that implements a decentralized skill and reputation graph with adaptive incentives, fulfilling your requirements for an interesting, advanced-concept, creative, and trendy design with over 20 functions.

This contract combines several advanced concepts:

1.  **Soulbound Tokens (SBTs):** Skill badges are non-transferable ERC-721-like tokens, representing verifiable skills and proficiency tied directly to a user's identity.
2.  **Dynamic Attestation & Validation:** A system where other users can attest to skills, and these attestations have decay mechanisms and can be challenged, adding a layer of dynamic trust.
3.  **Reputation-Weighted Governance:** A basic DAO-like structure where a user's voting power is directly tied to their accumulated reputation score, promoting meritocracy.
4.  **Adaptive Incentive Mechanisms:** Task rewards and skill values can be influenced by external factors through an oracle, allowing the protocol to respond to real-world demand or market conditions.
5.  **Skill Graph with Prerequisites:** Skills can be defined with prerequisites, ensuring a structured progression of verifiable knowledge.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; // For tokenURI conversion

// ====================================================================================================
// NEXUS CHRONICLE: ADAPTIVE SKILL & REPUTATION NEXUS
// ====================================================================================================
// This contract establishes a decentralized protocol for managing on-chain skill verification,
// reputation, and adaptive task coordination. It introduces "Soulbound Skill Badges" (SSBs)
// that represent specific skills and proficiency levels for users. These badges are non-transferable
// and are backed by an attestation system, allowing peers and automated processes to vouch for
// a user's capabilities.
//
// The protocol integrates a dynamic task/bounty system where creators can define tasks requiring
// specific skill sets. Rewards and task parameters can adapt based on system state, skill demand
// (potentially influenced by external oracles), and completion rates. A basic governance
// mechanism allows for protocol evolution driven by reputation-weighted voting.
//
// Key Concepts:
// -   **Soulbound Skill Badges (SSBs):** Non-transferable ERC-721-like tokens representing
//     a user's acquired skills and their proficiency levels.
// -   **Dynamic Attestation System:** Peers can attest to a user's skills, with attestations
//     having a defined validity period and the ability to be challenged.
// -   **Reputation Score:** A cumulative, on-chain metric derived from valid skill badges,
//     attestations, and task completions, used for weighted governance and task eligibility.
// -   **Skill Graph:** Basic mapping of skill prerequisites to ensure foundational knowledge.
// -   **Adaptive Task Marketplace:** Tasks are created with specific skill requirements,
//     and their rewards can dynamically adjust based on demand signals (e.g., from an oracle).
// -   **Lightweight Governance:** A proposal and voting system, weighted by reputation,
//     to enact protocol upgrades or significant state changes.
//
// ====================================================================================================
// FUNCTION SUMMARY
// ====================================================================================================
//
// I. ADMIN / INITIALIZATION FUNCTIONS:
//    1. `createSkillType`: Defines a new type of skill that can be recognized and attested to.
//    2. `defineSkillPrerequisite`: Sets a prerequisite skill and minimum proficiency required for a main skill.
//    3. `setOracleAddress`: Sets the address of the trusted oracle contract.
//
// II. SKILL BADGE & PROFILE FUNCTIONS:
//    4. `mintSkillBadge`: Mints a new non-transferable (soulbound) skill badge for a recipient.
//    5. `updateBadgeProficiency`: Internal function to update the proficiency level of an existing skill badge.
//    6. `revokeSkillBadge`: Revokes a skill badge, making it invalid and burning the underlying token.
//    7. `revalidateSkillBadge`: Extends the expiration timestamp for a skill badge's attestation.
//    8. `setUserProfile`: Allows a user to set their on-chain profile metadata URI.
//
// III. VIEW FUNCTIONS (GETTERS):
//    9. `getSkillBadgeDetails`: Retrieves detailed information about a specific skill badge.
//    10. `getUserSkillBadges`: Retrieves all valid skill badges held by a specific user.
//    11. `getAttestationsForBadge`: Retrieves all attestations for a given skill badge.
//    12. `getEligibleTaskApplicants`: Retrieves a list of addresses that have applied for a task and meet its skill requirements.
//    13. `getOpenTasks`: Retrieves a list of all currently open tasks.
//    14. `hasRequiredSkills`: Helper function to check if a user possesses the necessary skills and proficiencies.
//    15. `ownerOf`: Overrides ERC721's `ownerOf` to reflect the soulbound badge owner.
//    16. `tokenURI`: Returns the URI for a given Soulbound Skill Badge's metadata.
//
// IV. ATTESTATION & REPUTATION FUNCTIONS:
//    17. `attestSkillProficiency`: Allows a user to attest to another user's skill proficiency for a given badge.
//    18. `challengeAttestation`: Allows any user to challenge the validity of an attestation.
//    19. `resolveAttestationChallenge`: Resolves a challenged attestation, marking it as valid or invalid.
//    20. `calculateUserReputation`: Calculates and updates a user's reputation score.
//    21. `decayStaleAttestations`: Triggers the decay or invalidation of old/expired badge attestations.
//
// V. TASK & BOUNTY SYSTEM FUNCTIONS:
//    22. `createTask`: Creates a new task or bounty requiring specific skills.
//    23. `applyForTask`: Allows a user to apply for an open task.
//    24. `assignTask`: Assigns an open task to an eligible applicant.
//    25. `submitTaskDeliverable`: Allows the assigned user to submit their deliverable for a task.
//    26. `verifyTaskCompletion`: Verifies the completion of a task, distributes rewards, and updates assignee's proficiency.
//
// VI. ADAPTIVE MECHANISMS & ORACLE FUNCTIONS:
//    27. `adjustRewardDynamically`: Allows dynamic adjustment of task rewards, typically by the task creator or an oracle.
//    28. `updateSkillDemandFactor`: Updates the demand factor for a specific skill type, affecting its perceived value (called by oracle).
//
// VII. GOVERNANCE FUNCTIONS:
//    29. `proposeGovernanceAction`: Creates a new governance proposal for contract changes or significant actions.
//    30. `voteOnProposal`: Allows users with sufficient reputation to vote on an active governance proposal.
//    31. `executeProposal`: Executes a governance proposal if the voting period has ended and it has passed.
//
// ====================================================================================================

// Custom Errors for enhanced clarity and gas efficiency
error Unauthorized(string message);
error InvalidSkillType(string message);
error BadgeNotFound(uint256 badgeId);
error AttestationNotFound(uint256 attestationId);
error TaskNotFound(uint256 taskId);
error InsufficientProficiency(string message);
error TaskNotOpen(uint256 taskId);
error TaskAlreadyAssigned(uint256 taskId);
error TaskNotAssignedToCaller(uint256 taskId);
error DeliverableNotSubmitted(uint256 taskId);
error SelfAttestationNotAllowed();
error AttestationExpiredOrInvalid(string message);
error NotAnOracle();
error ProposalNotFound(uint256 proposalId);
error VotingClosed(string message);
error AlreadyVoted();
error NoActiveProposal(string message);


// Interface for a generic oracle contract
interface IOracle {
    function getUint256(string calldata key) external view returns (uint256);
    function getInt256(string calldata key) external view returns (int256);
}

contract NexusChronicle is ERC721, Ownable {
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;

    // --- State Variables ---

    // Global counters for unique IDs across different entities
    Counters.Counter private _skillTypeIds;
    Counters.Counter private _badgeIds;
    Counters.Counter private _attestationIds;
    Counters.Counter private _taskIds;
    Counters.Counter private _proposalIds;

    // --- Skill Type Management ---
    // Stores definitions for different skill categories
    struct SkillType {
        string name;
        string description;
        uint256 baseProficiencyCap; // Max proficiency level for this skill type (e.g., 100)
        mapping(uint256 => uint256) prerequisites; // Maps prereqSkillTypeId => minProficiency needed
        int256 demandFactor; // A value representing market demand, updated by oracle/governance
        bool exists; // Flag to check if a skillId is valid
    }
    mapping(uint256 => SkillType) public skillTypes; // skillTypeId => SkillType details

    // --- Soulbound Skill Badges (SSBs) ---
    // Represents a non-transferable skill credential held by a user
    struct SkillBadge {
        uint256 skillTypeId;
        uint256 currentProficiency;
        uint256 mintTimestamp;
        uint256 attestationExpires; // Timestamp when the badge's validity requires revalidation
        address owner; // The true owner of the soulbound badge
        bool revoked;
    }
    mapping(uint256 => SkillBadge) public skillBadges; // badgeId => SkillBadge details
    mapping(address => EnumerableSet.UintSet) private _userBadges; // userAddress => set of badgeIds owned by them
    mapping(address => string) private _userProfileMetadata; // userAddress => URI for off-chain profile metadata

    // --- Attestation System ---
    // Records peer-to-peer or automated attestations of skill proficiency
    struct Attestation {
        uint256 badgeId;
        address attestor;
        uint256 attestedProficiency;
        string context; // Brief description of the attestation's basis
        uint256 timestamp;
        bool isValid; // Can be invalidated by challenge resolution
        bool challenged; // True if the attestation is currently under dispute
    }
    mapping(uint256 => Attestation) public attestations; // attestationId => Attestation details
    mapping(uint256 => EnumerableSet.UintSet) private _badgeAttestations; // badgeId => set of attestationIds for that badge

    // --- User Reputation ---
    // A dynamic score reflecting a user's overall standing and trustworthiness
    mapping(address => uint256) public userReputation; // userAddress => reputationScore

    // --- Task & Bounty System ---
    // Manages decentralized tasks, their requirements, and lifecycle
    enum TaskStatus { Open, Assigned, DeliverableSubmitted, Verified, Rejected, Cancelled }
    struct Task {
        address creator;
        uint256 initialReward;
        uint256 currentReward; // Can be dynamically adjusted by creator/oracle
        uint256 deadline;
        string taskURI; // URI to detailed task description (e.g., IPFS)
        TaskStatus status;
        uint256[] requiredSkillIds; // Skill types required for this task
        uint256[] minProficiencies; // Minimum proficiency for each required skill
        address assignee; // The user assigned to the task
        string deliverableURI; // URI to the submitted work
        uint256 completionTimestamp;
    }
    mapping(uint256 => Task) public tasks; // taskId => Task details
    EnumerableSet.UintSet private _openTasks; // Set of taskIds that are currently open for applications
    mapping(uint256 => EnumerableSet.AddressSet) private _taskApplicants; // taskId => set of applicant addresses

    // --- Governance & Oracle ---
    // Enables protocol evolution and external data integration
    address public oracleAddress; // Address of the trusted oracle contract
    uint256 public constant MIN_REPUTATION_FOR_VOTE = 100; // Minimum reputation required to participate in governance

    struct GovernanceProposal {
        bytes callData; // The encoded function call to execute if proposal passes
        address targetContract; // The target contract for the call (e.g., address(this) for self-modification)
        string description; // Human-readable description of the proposal
        uint256 startBlock;
        uint256 endBlock; // Block number when voting concludes
        uint256 votesFor; // Total reputation-weighted votes in favor
        uint256 votesAgainst; // Total reputation-weighted votes against
        mapping(address => bool) hasVoted; // Tracks if a user has already voted on this proposal
        bool executed;
        bool active; // True if the proposal is currently active for voting
    }
    mapping(uint256 => GovernanceProposal) public proposals; // proposalId => GovernanceProposal details
    uint256 public activeProposalId; // Tracks the single currently active proposal for voting

    // --- Events ---
    // Define events for external monitoring and dapp UI updates
    event SkillTypeCreated(uint256 indexed skillTypeId, string name, string description);
    event SkillBadgeMinted(uint256 indexed badgeId, uint256 indexed skillTypeId, address indexed recipient, uint256 initialProficiency);
    event SkillBadgeProficiencyUpdated(uint256 indexed badgeId, uint256 oldProficiency, uint256 newProficiency);
    event SkillBadgeRevoked(uint256 indexed badgeId, address indexed owner);
    event SkillBadgeRevalidated(uint256 indexed badgeId, uint256 newExpiration);
    event AttestationRecorded(uint256 indexed attestationId, uint256 indexed badgeId, address indexed attestor, uint256 attestedProficiency);
    event AttestationChallenged(uint256 indexed attestationId, address indexed challenger, string reason);
    event AttestationChallengeResolved(uint256 indexed attestationId, bool isValid, address indexed arbiter);
    event ReputationCalculated(address indexed user, uint256 reputationScore);
    event SkillPrerequisiteDefined(uint256 indexed mainSkillId, uint256 indexed prereqSkillId, uint256 minProficiency);
    event TaskCreated(uint256 indexed taskId, address indexed creator, uint256 initialReward, uint256 deadline);
    event TaskApplied(uint256 indexed taskId, address indexed applicant);
    event TaskAssigned(uint256 indexed taskId, address indexed assignee);
    event TaskDeliverableSubmitted(uint256 indexed taskId, address indexed submitter, string deliverableURI);
    event TaskVerified(uint256 indexed taskId, address indexed assignee, uint256 actualReward);
    event TaskRewardAdjusted(uint256 indexed taskId, uint256 oldReward, uint256 newReward);
    event SkillDemandFactorUpdated(uint256 indexed skillTypeId, int256 changeAmount);
    event OracleAddressSet(address indexed oldOracle, address indexed newOracle);
    event GovernanceProposalCreated(uint256 indexed proposalId, string description, address indexed proposer);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId, bool success);

    /// @notice Constructor to initialize the NexusChronicle contract.
    /// @dev Sets the name and symbol for the ERC721 badges and assigns the initial owner and oracle address.
    /// @param _oracleAddress The address of the trusted oracle contract.
    constructor(address _oracleAddress) ERC721("NexusChronicleSkillBadge", "NCSB") Ownable(msg.sender) {
        oracleAddress = _oracleAddress;
    }

    // --- Core ERC721 Overrides to enforce Soulbound nature ---
    // These functions explicitly disable any transfer or approval mechanisms,
    // ensuring the badges remain non-transferable (soulbound).

    /// @notice Prevents direct transfer of Soulbound Skill Badges.
    /// @dev Always reverts, as skill badges are non-transferable.
    function transferFrom(address, address, uint256) public pure override {
        revert Unauthorized("Skill Badges are non-transferable (soulbound).");
    }

    /// @notice Prevents direct safe transfer of Soulbound Skill Badges.
    /// @dev Always reverts, as skill badges are non-transferable.
    function safeTransferFrom(address, address, uint256) public pure override {
        revert Unauthorized("Skill Badges are non-transferable (soulbound).");
    }

    /// @notice Prevents direct safe transfer of Soulbound Skill Badges with data.
    /// @dev Always reverts, as skill badges are non-transferable.
    function safeTransferFrom(address, address, uint256, bytes memory) public pure override {
        revert Unauthorized("Skill Badges are non-transferable (soulbound).");
    }

    /// @notice Prevents approving other addresses to transfer Soulbound Skill Badges.
    /// @dev Always reverts, as skill badges cannot be approved for transfer.
    function approve(address, uint256) public pure override {
        revert Unauthorized("Skill Badges cannot be approved for transfer.");
    }

    /// @notice Prevents setting an operator to manage all Soulbound Skill Badges.
    /// @dev Always reverts, as skill badges cannot be approved for transfer.
    function setApprovalForAll(address, bool) public pure override {
        revert Unauthorized("Skill Badges cannot be approved for transfer.");
    }

    /// @notice Returns the owner of the Soulbound Skill Badge.
    /// @dev Overrides ERC721's `ownerOf` to use our internal `SkillBadge` struct.
    /// @param badgeId The ID of the skill badge.
    /// @return The address of the badge owner.
    function ownerOf(uint256 badgeId) public view override returns (address) {
        SkillBadge storage badge = skillBadges[badgeId];
        if (badge.owner == address(0)) {
            revert BadgeNotFound(badgeId);
        }
        return badge.owner;
    }

    /// @notice Returns the URI for a given Soulbound Skill Badge.
    /// @dev This can link to IPFS or other storage for richer metadata.
    ///      It relies on the `getSkillBadgeDetails` function to ensure badge existence.
    /// @param badgeId The ID of the skill badge.
    /// @return A URI string pointing to the badge's metadata.
    function tokenURI(uint256 badgeId) public view override returns (string memory) {
        // Calling getSkillBadgeDetails implicitly checks for badge existence and reverts if not found.
        (,,,,,address owner,,) = getSkillBadgeDetails(badgeId);
        if (owner == address(0)) { // Additional check, though getSkillBadgeDetails should catch this.
            revert BadgeNotFound(badgeId);
        }
        return string(abi.encodePacked("https://nexus.chronicle/badge/", Strings.toString(badgeId)));
    }

    // --- Modifier for Oracle ---
    /// @dev Restricts a function's execution to only the designated oracle address.
    modifier onlyOracle() {
        if (msg.sender != oracleAddress) {
            revert NotAnOracle();
        }
        _;
    }

    // ====================================================================================================
    // I. ADMIN / INITIALIZATION FUNCTIONS
    // ====================================================================================================

    /// @notice Defines a new type of skill that can be recognized and attested to within the protocol.
    /// @dev Only the contract owner can create new skill types.
    /// @param _name The human-readable name of the skill (e.g., "Solidity Development").
    /// @param _description A brief description providing context for the skill.
    /// @param _baseProficiencyCap The maximum proficiency level attainable for this skill type.
    /// @return The unique ID of the newly created skill type.
    function createSkillType(string calldata _name, string calldata _description, uint256 _baseProficiencyCap)
        public onlyOwner returns (uint256)
    {
        _skillTypeIds.increment();
        uint256 newSkillTypeId = _skillTypeIds.current();
        skillTypes[newSkillTypeId] = SkillType({
            name: _name,
            description: _description,
            baseProficiencyCap: _baseProficiencyCap,
            demandFactor: 0,
            exists: true
        });
        emit SkillTypeCreated(newSkillTypeId, _name, _description);
        return newSkillTypeId;
    }

    /// @notice Sets a prerequisite skill and minimum proficiency required to be considered proficient in a main skill.
    /// @dev Only the contract owner can define skill prerequisites. Ensures structured skill progression.
    /// @param _mainSkillId The ID of the skill for which a prerequisite is being defined.
    /// @param _prereqSkillId The ID of the prerequisite skill.
    /// @param _minProficiency The minimum proficiency level required in the prerequisite skill.
    function defineSkillPrerequisite(uint256 _mainSkillId, uint256 _prereqSkillId, uint256 _minProficiency)
        public onlyOwner
    {
        if (!skillTypes[_mainSkillId].exists) {
            revert InvalidSkillType("Main skill type does not exist.");
        }
        if (!skillTypes[_prereqSkillId].exists) {
            revert InvalidSkillType("Prerequisite skill type does not exist.");
        }
        skillTypes[_mainSkillId].prerequisites[_prereqSkillId] = _minProficiency;
        emit SkillPrerequisiteDefined(_mainSkillId, _prereqSkillId, _minProficiency);
    }

    /// @notice Sets the address of the trusted oracle contract.
    /// @dev The oracle is responsible for providing external data, such as skill demand factors.
    ///      Only the contract owner can set the oracle address.
    /// @param _newOracle The new address of the oracle.
    function setOracleAddress(address _newOracle) public onlyOwner {
        address oldOracle = oracleAddress;
        oracleAddress = _newOracle;
        emit OracleAddressSet(oldOracle, _newOracle);
    }

    // ====================================================================================================
    // II. SKILL BADGE & PROFILE FUNCTIONS
    // ====================================================================================================

    /// @notice Mints a new non-transferable (soulbound) skill badge for a specified recipient.
    /// @dev Only the contract owner can mint new skill badges. The badge's proficiency can
    ///      later be updated through attestations or task completions. The initial attestation
    ///      must have a future expiration date.
    /// @param _recipient The address to which the skill badge will be minted.
    /// @param _skillTypeId The ID of the skill type this badge represents.
    /// @param _initialProficiency The starting proficiency level for the badge.
    /// @param _attestationExpires Timestamp when the initial attestation/badge validity expires,
    ///                            requiring revalidation.
    /// @return The unique ID of the newly minted skill badge.
    function mintSkillBadge(address _recipient, uint256 _skillTypeId, uint256 _initialProficiency, uint256 _attestationExpires)
        public onlyOwner returns (uint256)
    {
        if (!skillTypes[_skillTypeId].exists) {
            revert InvalidSkillType("Skill type does not exist.");
        }
        uint256 actualProficiency = _initialProficiency;
        if (actualProficiency > skillTypes[_skillTypeId].baseProficiencyCap) {
            actualProficiency = skillTypes[_skillTypeId].baseProficiencyCap; // Cap proficiency at max allowed for skill type
        }
        if (_attestationExpires <= block.timestamp) {
            revert AttestationExpiredOrInvalid("Attestation expiration must be in the future.");
        }

        _badgeIds.increment();
        uint256 newBadgeId = _badgeIds.current();

        skillBadges[newBadgeId] = SkillBadge({
            skillTypeId: _skillTypeId,
            currentProficiency: actualProficiency,
            mintTimestamp: block.timestamp,
            attestationExpires: _attestationExpires,
            owner: _recipient,
            revoked: false
        });

        _userBadges[_recipient].add(newBadgeId);
        _mint(_recipient, newBadgeId); // Call ERC721 internal mint to track token owner for ownerOf
        emit SkillBadgeMinted(newBadgeId, _skillTypeId, _recipient, actualProficiency);
        return newBadgeId;
    }

    /// @notice Updates the proficiency level of an existing skill badge.
    /// @dev This function is internal and called by other contract functions, such as
    ///      `verifyTaskCompletion` or `decayStaleAttestations`. It ensures proficiency
    ///      does not exceed the skill's defined cap.
    /// @param _badgeId The ID of the skill badge to update.
    /// @param _newProficiency The new proficiency level.
    function updateBadgeProficiency(uint256 _badgeId, uint256 _newProficiency)
        internal
    {
        SkillBadge storage badge = skillBadges[_badgeId];
        if (badge.owner == address(0) || badge.revoked) {
            revert BadgeNotFound(_badgeId);
        }
        uint256 cappedProficiency = _newProficiency;
        if (cappedProficiency > skillTypes[badge.skillTypeId].baseProficiencyCap) {
            cappedProficiency = skillTypes[badge.skillTypeId].baseProficiencyCap;
        }
        uint256 oldProficiency = badge.currentProficiency;
        badge.currentProficiency = cappedProficiency;
        emit SkillBadgeProficiencyUpdated(_badgeId, oldProficiency, cappedProficiency);
    }

    /// @notice Revokes a skill badge, making it invalid and burning the underlying ERC721 token.
    /// @dev Only the contract owner can revoke skill badges. Revoked badges are permanently removed
    ///      from a user's active set and ERC721 tracking.
    /// @param _badgeId The ID of the badge to revoke.
    function revokeSkillBadge(uint256 _badgeId) public onlyOwner {
        SkillBadge storage badge = skillBadges[_badgeId];
        if (badge.owner == address(0) || badge.revoked) {
            revert BadgeNotFound(_badgeId);
        }
        badge.revoked = true;
        _userBadges[badge.owner].remove(_badgeId);
        _burn(_badgeId); // Burn the ERC721 token to remove from owner's balance
        emit SkillBadgeRevoked(_badgeId, badge.owner);
    }

    /// @notice Extends the expiration timestamp for a skill badge's attestation.
    /// @dev Can be called by the badge owner or the contract owner. Requires a future expiration date.
    ///      This allows users to maintain the "freshness" of their skill attestations.
    /// @param _badgeId The ID of the badge to revalidate.
    /// @param _newExpiration The new timestamp for expiration. Must be in the future.
    function revalidateSkillBadge(uint256 _badgeId, uint256 _newExpiration) public {
        SkillBadge storage badge = skillBadges[_badgeId];
        if (badge.owner == address(0) || badge.revoked) {
            revert BadgeNotFound(_badgeId);
        }
        if (msg.sender != badge.owner && msg.sender != owner()) {
            revert Unauthorized("Only badge owner or contract owner can revalidate this badge.");
        }
        if (_newExpiration <= block.timestamp) {
            revert AttestationExpiredOrInvalid("New expiration must be in the future.");
        }
        badge.attestationExpires = _newExpiration;
        emit SkillBadgeRevalidated(_badgeId, _newExpiration);
    }

    /// @notice Allows a user to set their on-chain profile metadata URI.
    /// @dev This URI typically points to an IPFS hash or similar decentralized storage
    ///      containing richer profile information (e.g., a JSON file with bio, links, etc.).
    ///      This allows users to curate their public persona associated with their on-chain identity.
    /// @param _metadataURI The URI pointing to the user's off-chain profile metadata.
    function setUserProfile(string calldata _metadataURI) public {
        _userProfileMetadata[msg.sender] = _metadataURI;
    }

    // ====================================================================================================
    // III. VIEW FUNCTIONS (GETTERS)
    // ====================================================================================================

    /// @notice Retrieves detailed information about a specific skill badge.
    /// @dev Provides all stored attributes for a given badge ID.
    /// @param _badgeId The ID of the skill badge.
    /// @return skillTypeId The type of skill.
    /// @return currentProficiency The current proficiency level.
    /// @return mintTimestamp When the badge was minted.
    /// @return attestationExpires When attestation needs revalidation.
    /// @return owner The address of the badge owner.
    /// @return revoked Whether the badge has been revoked.
    function getSkillBadgeDetails(uint256 _badgeId)
        public view returns (uint256 skillTypeId, uint256 currentProficiency, uint256 mintTimestamp, uint256 attestationExpires, address owner, bool revoked)
    {
        SkillBadge storage badge = skillBadges[_badgeId];
        if (badge.owner == address(0)) {
            revert BadgeNotFound(_badgeId);
        }
        return (badge.skillTypeId, badge.currentProficiency, badge.mintTimestamp, badge.attestationExpires, badge.owner, badge.revoked);
    }

    /// @notice Retrieves all valid skill badges held by a specific user.
    /// @param _user The address of the user.
    /// @return An array of badge IDs held by the user.
    function getUserSkillBadges(address _user) public view returns (uint256[] memory) {
        return _userBadges[_user].values();
    }

    /// @notice Retrieves all attestations for a given skill badge.
    /// @param _badgeId The ID of the skill badge.
    /// @return An array of attestation IDs.
    function getAttestationsForBadge(uint256 _badgeId) public view returns (uint256[] memory) {
        if (skillBadges[_badgeId].owner == address(0)) {
            revert BadgeNotFound(_badgeId);
        }
        return _badgeAttestations[_badgeId].values();
    }

    /// @notice Retrieves a list of addresses that have applied for a task and meet its skill requirements.
    /// @param _taskId The ID of the task.
    /// @return An array of addresses of eligible applicants.
    function getEligibleTaskApplicants(uint256 _taskId) public view returns (address[] memory) {
        Task storage task = tasks[_taskId];
        if (task.creator == address(0)) {
            revert TaskNotFound(_taskId);
        }
        EnumerableSet.AddressSet storage applicants = _taskApplicants[_taskId];
        address[] memory eligibleApplicants = new address[](applicants.length());
        uint256 count = 0;
        for (uint256 i = 0; i < applicants.length(); i++) {
            address applicant = applicants.at(i);
            if (hasRequiredSkills(applicant, task.requiredSkillIds, task.minProficiencies)) {
                eligibleApplicants[count] = applicant;
                count++;
            }
        }
        // Resize dynamic array to actual count for gas efficiency and correct length
        address[] memory finalEligibleApplicants = new address[](count);
        for(uint256 i = 0; i < count; i++){
            finalEligibleApplicants[i] = eligibleApplicants[i];
        }
        return finalEligibleApplicants;
    }

    /// @notice Retrieves a list of all currently open tasks.
    /// @return An array of task IDs that are currently open.
    function getOpenTasks() public view returns (uint256[] memory) {
        return _openTasks.values();
    }

    /// @notice Helper function to check if a user possesses the necessary skills and proficiencies.
    /// @dev Checks for active, non-revoked badges with sufficient proficiency and recursively
    ///      validates any defined prerequisites for those skills.
    /// @param _user The address of the user to check.
    /// @param _requiredSkillIds An array of skill type IDs that are required.
    /// @param _minProficiencies An array of minimum proficiency levels corresponding to requiredSkillIds.
    /// @return True if the user meets all specified skill requirements, false otherwise.
    function hasRequiredSkills(address _user, uint256[] memory _requiredSkillIds, uint256[] memory _minProficiencies)
        public view returns (bool)
    {
        if (_requiredSkillIds.length != _minProficiencies.length) return false;

        uint256[] memory userBadges = getUserSkillBadges(_user);

        for (uint256 i = 0; i < _requiredSkillIds.length; i++) {
            uint256 requiredSkill = _requiredSkillIds[i];
            uint256 minProficiency = _minProficiencies[i];

            bool hasSkill = false;
            for (uint256 j = 0; j < userBadges.length; j++) {
                SkillBadge storage badge = skillBadges[userBadges[j]];
                if (badge.skillTypeId == requiredSkill && !badge.revoked && badge.attestationExpires > block.timestamp && badge.currentProficiency >= minProficiency) {
                    hasSkill = true;
                    break;
                }
            }
            if (!hasSkill) return false;

            // Check prerequisites for the required skill
            SkillType storage skillType = skillTypes[requiredSkill];
            // Iterate through all potential skill types to find prerequisites.
            // This loop could be optimized if prerequisites were stored differently (e.g., in an array).
            for (uint256 k = 1; k <= _skillTypeIds.current(); k++) {
                uint256 prereqMinProficiency = skillType.prerequisites[k];
                if (prereqMinProficiency > 0) { // If a prerequisite is defined for skill type `k`
                    bool hasPrereq = false;
                    for (uint256 j = 0; j < userBadges.length; j++) {
                        SkillBadge storage badge = skillBadges[userBadges[j]];
                        if (badge.skillTypeId == k && !badge.revoked && badge.attestationExpires > block.timestamp && badge.currentProficiency >= prereqMinProficiency) {
                            hasPrereq = true;
                            break;
                        }
                    }
                    if (!hasPrereq) return false;
                }
            }
        }
        return true;
    }

    // ====================================================================================================
    // IV. ATTESTATION & REPUTATION FUNCTIONS
    // ====================================================================================================

    /// @notice Allows a user to attest to another user's skill proficiency for a given badge.
    /// @dev Attestations contribute to the badge's perceived proficiency and the user's overall reputation.
    ///      Self-attestation is explicitly not allowed to maintain integrity. Proficiency is capped.
    /// @param _badgeId The ID of the skill badge being attested.
    /// @param _attestedProficiency The proficiency level being attested to.
    /// @param _context A string describing the context of the attestation (e.g., "collaborated on project X").
    /// @return The unique ID of the newly created attestation.
    function attestSkillProficiency(uint256 _badgeId, uint256 _attestedProficiency, string calldata _context)
        public returns (uint256)
    {
        SkillBadge storage badge = skillBadges[_badgeId];
        if (badge.owner == address(0) || badge.revoked) {
            revert BadgeNotFound(_badgeId);
        }
        if (msg.sender == badge.owner) {
            revert SelfAttestationNotAllowed();
        }
        uint256 cappedProficiency = _attestedProficiency;
        if (cappedProficiency > skillTypes[badge.skillTypeId].baseProficiencyCap) {
            cappedProficiency = skillTypes[badge.skillTypeId].baseProficiencyCap;
        }

        _attestationIds.increment();
        uint256 newAttestationId = _attestationIds.current();

        attestations[newAttestationId] = Attestation({
            badgeId: _badgeId,
            attestor: msg.sender,
            attestedProficiency: cappedProficiency,
            context: _context,
            timestamp: block.timestamp,
            isValid: true,
            challenged: false
        });
        _badgeAttestations[_badgeId].add(newAttestationId);

        emit AttestationRecorded(newAttestationId, _badgeId, msg.sender, cappedProficiency);
        return newAttestationId;
    }

    /// @notice Allows any user to challenge the validity of an attestation.
    /// @dev Challenging an attestation marks it for review. Resolution requires governance or an arbiter.
    ///      Once challenged, an attestation cannot be challenged again until resolved.
    /// @param _attestationId The ID of the attestation to challenge.
    /// @param _reason A brief explanation for challenging the attestation.
    function challengeAttestation(uint256 _attestationId, string calldata _reason) public {
        Attestation storage att = attestations[_attestationId];
        if (att.attestor == address(0)) {
            revert AttestationNotFound(_attestationId);
        }
        if (!att.isValid || att.challenged) {
            revert AttestationExpiredOrInvalid("Attestation is already invalid or challenged.");
        }
        att.challenged = true;
        emit AttestationChallenged(_attestationId, msg.sender, _reason);
    }

    /// @notice Resolves a challenged attestation, marking it as valid or invalid.
    /// @dev Only the contract owner (acting as an arbiter) can resolve challenges.
    ///      This is a crucial step for maintaining the integrity of the reputation system.
    /// @param _attestationId The ID of the attestation to resolve.
    /// @param _isValid True if the attestation is deemed valid, false otherwise.
    /// @param _arbiter The address of the entity that resolved the challenge (e.g., a DAO, a trusted third party).
    function resolveAttestationChallenge(uint256 _attestationId, bool _isValid, address _arbiter) public onlyOwner {
        Attestation storage att = attestations[_attestationId];
        if (att.attestor == address(0) || !att.challenged) {
            revert AttestationNotFound(_attestationId);
        }
        att.isValid = _isValid;
        att.challenged = false; // Challenge resolved
        emit AttestationChallengeResolved(_attestationId, _isValid, _arbiter);
    }

    /// @notice Calculates and updates a user's reputation score based on their valid skill badges and attestations.
    /// @dev This function can be called by anyone to trigger a recalculation for a user.
    ///      Reputation is a sum of current proficiency from valid badges and averaged attested proficiencies.
    ///      This provides a dynamic and comprehensive measure of a user's standing.
    /// @param _user The address of the user.
    function calculateUserReputation(address _user) public {
        uint256 totalReputation = 0;
        uint256[] memory userBadges = getUserSkillBadges(_user);

        for (uint256 i = 0; i < userBadges.length; i++) {
            uint256 badgeId = userBadges[i];
            SkillBadge storage badge = skillBadges[badgeId];

            // Only consider non-revoked and non-expired badges for reputation calculation
            if (!badge.revoked && badge.attestationExpires > block.timestamp) {
                totalReputation += badge.currentProficiency;

                uint256[] memory attestationsForBadge = getAttestationsForBadge(badgeId);
                uint256 validAttestationsCount = 0;
                uint256 totalAttestedProficiency = 0;

                for (uint256 j = 0; j < attestationsForBadge.length; j++) {
                    Attestation storage att = attestations[attestationsForBadge[j]];
                    if (att.isValid && !att.challenged) {
                        validAttestationsCount++;
                        totalAttestedProficiency += att.attestedProficiency;
                    }
                }
                if (validAttestationsCount > 0) {
                    totalReputation += (totalAttestedProficiency / validAttestationsCount);
                }
            }
        }
        userReputation[_user] = totalReputation;
        emit ReputationCalculated(_user, totalReputation);
    }

    /// @notice Public function to trigger the decay or invalidation of old/expired badge attestations.
    /// @dev This iterates through all existing badges and sets their proficiency to 0 if their
    ///      `attestationExpires` timestamp has passed. This simulates a need for revalidation
    ///      and ensures that reputation is based on current and actively maintained skills.
    ///      Can be called by anyone to help maintain the system's state.
    function decayStaleAttestations() public {
        uint256 currentId = _badgeIds.current();
        for (uint256 i = 1; i <= currentId; i++) {
            SkillBadge storage badge = skillBadges[i];
            // Check if badge exists, is not revoked, and its attestation has expired
            if (badge.owner != address(0) && !badge.revoked && badge.attestationExpires <= block.timestamp) {
                if (badge.currentProficiency > 0) {
                    updateBadgeProficiency(i, 0); // Reset proficiency to 0 on expiration
                }
            }
        }
    }

    // ====================================================================================================
    // V. TASK & BOUNTY SYSTEM FUNCTIONS
    // ====================================================================================================

    /// @notice Creates a new task or bounty within the protocol, requiring specific skills.
    /// @dev The task creator defines skill prerequisites, initial reward, and deadline.
    ///      This allows for a decentralized marketplace for skilled work.
    /// @param _requiredSkillIds An array of skill type IDs required for the task.
    /// @param _minProficiencies An array of minimum proficiency levels corresponding to requiredSkillIds.
    /// @param _initialReward The initial reward offered for completing the task (assumed to be native token for now).
    /// @param _deadline The timestamp by which the task must be completed.
    /// @param _taskURI A URI pointing to the detailed task description (e.g., IPFS hash).
    /// @return The unique ID of the newly created task.
    function createTask(uint256[] calldata _requiredSkillIds, uint256[] calldata _minProficiencies, uint256 _initialReward, uint256 _deadline, string calldata _taskURI)
        public returns (uint256)
    {
        if (_requiredSkillIds.length != _minProficiencies.length) {
            revert InvalidSkillType("Required skills and proficiencies arrays must match in length.");
        }
        for (uint256 i = 0; i < _requiredSkillIds.length; i++) {
            if (!skillTypes[_requiredSkillIds[i]].exists) {
                revert InvalidSkillType("One of the required skill types does not exist.");
            }
        }
        if (_deadline <= block.timestamp) {
            revert TaskNotOpen(0); // Using 0 as taskId for generic "task not open" condition (deadline passed)
        }

        _taskIds.increment();
        uint256 newTaskId = _taskIds.current();

        tasks[newTaskId] = Task({
            creator: msg.sender,
            initialReward: _initialReward,
            currentReward: _initialReward,
            deadline: _deadline,
            taskURI: _taskURI,
            status: TaskStatus.Open,
            requiredSkillIds: _requiredSkillIds,
            minProficiencies: _minProficiencies,
            assignee: address(0),
            deliverableURI: "",
            completionTimestamp: 0
        });
        _openTasks.add(newTaskId);
        emit TaskCreated(newTaskId, msg.sender, _initialReward, _deadline);
        return newTaskId;
    }

    /// @notice Allows a user to apply for an open task.
    /// @dev The applicant must meet the task's skill requirements at the time of application.
    /// @param _taskId The ID of the task to apply for.
    function applyForTask(uint256 _taskId) public {
        Task storage task = tasks[_taskId];
        if (task.creator == address(0)) { // Check if task exists
            revert TaskNotFound(_taskId);
        }
        if (task.status != TaskStatus.Open || task.deadline <= block.timestamp) {
            revert TaskNotOpen(_taskId);
        }
        if (!hasRequiredSkills(msg.sender, task.requiredSkillIds, task.minProficiencies)) {
            revert InsufficientProficiency("Applicant does not meet required skill proficiencies.");
        }
        _taskApplicants[_taskId].add(msg.sender);
        emit TaskApplied(_taskId, msg.sender);
    }

    /// @notice Assigns an open task to an eligible applicant.
    /// @dev Only the task creator can assign the task. The assignee must have previously applied
    ///      and still meet the skill requirements. Once assigned, the task is no longer open for applications.
    /// @param _taskId The ID of the task to assign.
    /// @param _assignee The address of the applicant to assign the task to.
    function assignTask(uint256 _taskId, address _assignee) public {
        Task storage task = tasks[_taskId];
        if (task.creator != msg.sender) {
            revert Unauthorized("Only task creator can assign the task.");
        }
        if (task.status != TaskStatus.Open) {
            revert TaskNotOpen(_taskId);
        }
        if (task.assignee != address(0)) {
            revert TaskAlreadyAssigned(_taskId);
        }
        if (!_taskApplicants[_taskId].contains(_assignee)) {
            revert Unauthorized("Assignee has not applied for this task.");
        }
        // Re-check skill requirements at assignment to ensure they still apply
        if (!hasRequiredSkills(_assignee, task.requiredSkillIds, task.minProficiencies)) {
            revert InsufficientProficiency("Assignee no longer meets skill requirements.");
        }

        task.assignee = _assignee;
        task.status = TaskStatus.Assigned;
        _openTasks.remove(_taskId); // No longer open for application
        emit TaskAssigned(_taskId, _assignee);
    }

    /// @notice Allows the assigned user to submit their deliverable for a task.
    /// @dev Only the assigned user can submit deliverables, and only if the task is in the 'Assigned' state
    ///      and the deadline has not passed.
    /// @param _taskId The ID of the task.
    /// @param _deliverableURI A URI pointing to the submitted work (e.g., IPFS link to code, document).
    function submitTaskDeliverable(uint256 _taskId, string calldata _deliverableURI) public {
        Task storage task = tasks[_taskId];
        if (task.assignee != msg.sender) {
            revert TaskNotAssignedToCaller(_taskId);
        }
        if (task.status != TaskStatus.Assigned) {
            revert DeliverableNotSubmitted(_taskId); // Using DeliverableNotSubmitted for inappropriate status
        }
        if (block.timestamp > task.deadline) {
            revert TaskNotFound("Task deadline has passed.");
        }
        task.deliverableURI = _deliverableURI;
        task.status = TaskStatus.DeliverableSubmitted;
        emit TaskDeliverableSubmitted(_taskId, msg.sender, _deliverableURI);
    }

    /// @notice Verifies the completion of a task, distributes rewards, and can update assignee's skill proficiency.
    /// @dev Only the task creator can verify completion. Rewards are conceptual and assume an external token or native coin
    ///      is handled outside this contract's scope or sent with the initial `createTask` call.
    ///      Successful completion can lead to proficiency increases for relevant skill badges.
    /// @param _taskId The ID of the task to verify.
    /// @param _isComplete True if the task is successfully completed, false otherwise.
    /// @param _actualReward The actual reward to be paid to the assignee.
    function verifyTaskCompletion(uint256 _taskId, bool _isComplete, uint256 _actualReward) public {
        Task storage task = tasks[_taskId];
        if (task.creator != msg.sender) {
            revert Unauthorized("Only task creator can verify task completion.");
        }
        if (task.status != TaskStatus.DeliverableSubmitted) {
            revert DeliverableNotSubmitted(_taskId);
        }
        if (task.assignee == address(0)) { // Should not happen if status is DeliverableSubmitted, but for safety
            revert TaskNotFound("Task has no assignee.");
        }

        task.completionTimestamp = block.timestamp;

        if (_isComplete) {
            task.status = TaskStatus.Verified;
            task.currentReward = _actualReward; // Update final reward

            // Example of reward transfer (would need actual token contract interaction)
            // If native token: payable(task.assignee).transfer(_actualReward);
            // If ERC20: IERC20(rewardTokenAddress).transfer(task.assignee, _actualReward);

            // Increase assignee's relevant skill proficiencies upon successful completion
            uint256[] memory assigneeBadges = getUserSkillBadges(task.assignee);
            for (uint256 i = 0; i < task.requiredSkillIds.length; i++) {
                uint256 skillTypeId = task.requiredSkillIds[i];
                for (uint256 j = 0; j < assigneeBadges.length; j++) {
                    uint256 badgeId = assigneeBadges[j];
                    SkillBadge storage badge = skillBadges[badgeId];
                    if (badge.skillTypeId == skillTypeId && !badge.revoked && badge.attestationExpires > block.timestamp) {
                        // Increase proficiency by a factor of the minimum required proficiency, up to cap
                        uint256 proficiencyIncrease = task.minProficiencies[i] / 4; // Example: 25% of min required as bonus
                        updateBadgeProficiency(badgeId, badge.currentProficiency + proficiencyIncrease);
                        break; // Move to the next required skill after finding and updating one relevant badge
                    }
                }
            }
            emit TaskVerified(_taskId, task.assignee, _actualReward);
        } else {
            task.status = TaskStatus.Rejected;
            emit TaskVerified(_taskId, task.assignee, 0); // Reward 0 on rejection
        }
        _taskApplicants[_taskId].clear(); // Clear all applicants as the task is no longer pending/open
    }

    // ====================================================================================================
    // VI. ADAPTIVE MECHANISMS & ORACLE FUNCTIONS
    // ====================================================================================================

    /// @notice Allows dynamic adjustment of task rewards, typically by the task creator or an oracle.
    /// @dev This function enables flexible incentive mechanisms, allowing tasks to adapt to changing
    ///      demands or market conditions (e.g., if a task is difficult to get assigned, reward can be increased).
    /// @param _taskId The ID of the task to adjust.
    /// @param _newReward The new reward amount.
    function adjustRewardDynamically(uint256 _taskId, uint256 _newReward) public {
        Task storage task = tasks[_taskId];
        if (task.creator == address(0)) {
            revert TaskNotFound(_taskId);
        }
        if (task.creator != msg.sender && msg.sender != owner()) { // Only creator or admin can adjust
            revert Unauthorized("Only task creator or contract owner can adjust task rewards.");
        }
        if (task.status != TaskStatus.Open && task.status != TaskStatus.Assigned) {
            revert TaskNotFound("Task is not in a state where reward can be adjusted.");
        }
        uint256 oldReward = task.currentReward;
        task.currentReward = _newReward;
        emit TaskRewardAdjusted(_taskId, oldReward, _newReward);
    }

    /// @notice Updates the demand factor for a specific skill type, affecting its perceived value.
    /// @dev This function is intended to be called by a trusted oracle, reflecting real-world demand or trends.
    ///      This demand factor can then influence reward calculations or task prioritization in dApps.
    /// @param _skillTypeId The ID of the skill type.
    /// @param _changeAmount The amount to change the demand factor by (can be positive or negative).
    function updateSkillDemandFactor(uint256 _skillTypeId, int256 _changeAmount) public onlyOracle {
        SkillType storage skill = skillTypes[_skillTypeId];
        if (!skill.exists) {
            revert InvalidSkillType("Skill type does not exist.");
        }
        skill.demandFactor += _changeAmount;
        emit SkillDemandFactorUpdated(_skillTypeId, _changeAmount);
    }

    // ====================================================================================================
    // VII. GOVERNANCE FUNCTIONS
    // ====================================================================================================

    /// @notice Creates a new governance proposal for contract changes or significant actions.
    /// @dev Only users with a minimum reputation can propose. To simplify, only one proposal
    ///      can be active for voting at any given time.
    /// @param _targetContract The address of the contract to call (can be `address(this)` for self-modification).
    /// @param _calldata The encoded function call data for the proposed action.
    /// @param _description A human-readable description of the proposal.
    /// @param _votingPeriodBlocks The number of blocks for which the voting will be open.
    /// @return The unique ID of the newly created proposal.
    function proposeGovernanceAction(address _targetContract, bytes memory _calldata, string calldata _description, uint256 _votingPeriodBlocks)
        public returns (uint256)
    {
        if (userReputation[msg.sender] < MIN_REPUTATION_FOR_VOTE) {
            revert Unauthorized("Insufficient reputation to propose governance action.");
        }
        if (activeProposalId != 0 && proposals[activeProposalId].active) {
            revert NoActiveProposal("An active proposal already exists. Only one can be active at a time.");
        }
        if (_votingPeriodBlocks == 0) {
            revert VotingClosed("Voting period must be greater than zero.");
        }

        _proposalIds.increment();
        uint256 newProposalId = _proposalIds.current();

        proposals[newProposalId] = GovernanceProposal({
            callData: _calldata,
            targetContract: _targetContract,
            description: _description,
            startBlock: block.number,
            endBlock: block.number + _votingPeriodBlocks,
            votesFor: 0,
            votesAgainst: 0,
            hasVoted: new mapping(address => bool), // Initialize the mapping
            executed: false,
            active: true
        });
        activeProposalId = newProposalId;
        emit GovernanceProposalCreated(newProposalId, _description, msg.sender);
        return newProposalId;
    }

    /// @notice Allows users with sufficient reputation to vote on an active governance proposal.
    /// @dev Votes are weighted by the voter's current reputation score, promoting informed decisions.
    ///      Each user can vote only once per proposal.
    /// @param _proposalId The ID of the proposal to vote on.
    /// @param _support True to vote in favor, false to vote against.
    function voteOnProposal(uint256 _proposalId, bool _support) public {
        GovernanceProposal storage proposal = proposals[_proposalId];

        if (_proposalId != activeProposalId || !proposal.active) {
            revert ProposalNotFound(_proposalId);
        }
        if (block.number > proposal.endBlock) {
            revert VotingClosed("Voting period has ended.");
        }
        if (userReputation[msg.sender] < MIN_REPUTATION_FOR_VOTE) {
            revert Unauthorized("Insufficient reputation to vote.");
        }
        if (proposal.hasVoted[msg.sender]) {
            revert AlreadyVoted();
        }

        if (_support) {
            proposal.votesFor += userReputation[msg.sender]; // Reputation-weighted voting
        } else {
            proposal.votesAgainst += userReputation[msg.sender];
        }
        proposal.hasVoted[msg.sender] = true;
        emit VoteCast(_proposalId, msg.sender, _support);
    }

    /// @notice Executes a governance proposal if the voting period has ended and it has passed.
    /// @dev Anyone can call this to trigger execution, but it will only succeed if conditions are met
    ///      (voting period ended, more 'for' votes than 'against'). This allows for decentralized execution.
    /// @param _proposalId The ID of the proposal to execute.
    function executeProposal(uint256 _proposalId) public {
        GovernanceProposal storage proposal = proposals[_proposalId];

        if (_proposalId != activeProposalId) { // Must be the currently active proposal
            revert NoActiveProposal("This is not the currently active proposal.");
        }
        if (block.number <= proposal.endBlock) {
            revert VotingClosed("Voting period has not ended yet.");
        }
        if (proposal.executed) {
            revert ProposalNotFound("Proposal already executed.");
        }

        bool success = false;
        // Simple majority based on reputation-weighted votes. Can be customized for quorum/supermajority.
        if (proposal.votesFor > proposal.votesAgainst) {
            (success,) = proposal.targetContract.call(proposal.callData);
            require(success, "Proposal execution failed.");
        }
        proposal.executed = true;
        proposal.active = false; // Deactivate the proposal
        activeProposalId = 0; // Clear the active proposal slot
        emit ProposalExecuted(_proposalId, success);
    }
}
```