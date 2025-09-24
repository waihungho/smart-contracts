This smart contract, **CognitoNet**, is designed to be a **Decentralized Autonomous Skill & Contribution Network**. It combines several advanced and trendy Web3 concepts to create a platform where users can establish verifiable professional identities, attest to their skills, build dynamic on-chain reputation through task completion, and participate in a decentralized work economy.

The core idea is to move beyond simple static identities and tokens, creating a living, evolving profile based on verifiable contributions and peer assessment. It incorporates **Soulbound Tokens (SBTs)** for non-transferable profiles, skills, and roles, an **epoch-based dynamic reputation system**, and a **task management framework** with commitment deposits and a decentralized dispute resolution interface. While direct AI integration is off-chain, the structure is designed to be compatible with future ZKML (Zero-Knowledge Machine Learning) verifiable outputs for skill assessment or reputation scoring.

---

### CognitoNet - Decentralized Autonomous Skill & Contribution Network

**I. Outline:**

1.  **Soulbound Token (SBT) Implementation:** A custom, minimal non-transferable ERC721-like contract (`SoulboundERC721`) is used for:
    *   **Profile SBTs:** Unique identifier for each user's professional profile.
    *   **Skill SBTs:** Verifiable and time-bound attestations of specific skills.
    *   **Role SBTs:** Delegation of organizational or project-specific roles.
2.  **Reputation System:**
    *   Dynamic reputation score (starts at 100).
    *   Adjusted by task completion, failure, and peer feedback.
    *   Epoch-based snapshots for historical reputation tracking and skill validity.
    *   Thresholds for attesting skills and accepting tasks.
3.  **Task Management & Execution:**
    *   Task creation with reward and required skills.
    *   Worker acceptance, requiring commitment deposits and matching active skills/reputation.
    *   Proof submission and verification of task completion.
    *   Escrow for rewards and commitment deposits, using a specified ERC20 token.
4.  **Dispute Resolution Interface:**
    *   Mechanism for workers/creators to raise disputes.
    *   An owner-configurable `disputeResolver` (e.g., a DAO, a multisig, or another contract) to arbitrate outcomes.
    *   Reputation adjustments based on dispute outcomes.
5.  **Epoch Management:**
    *   Time-based epochs (e.g., weekly) that trigger reputation snapshots and manage skill/role expiry.
6.  **Configuration & Administration:**
    *   Owner-controlled parameters for reputation thresholds, epoch duration, and token addresses.

**II. Function Summary (22 Functions):**

**A. Identity & Profile Management (SBT-0 Profile)**
1.  `registerProfile(string _metadataURI)`: Creates a new user profile and mints a unique profile SBT.
2.  `updateProfileMetadata(string _newMetadataURI)`: Updates the metadata URI for an existing user profile SBT.

**B. Skill & Role Attestation (SBT-1 Skills, SBT-2 Roles)**
3.  `attestSkill(address _user, string _skillHash, uint256 _durationEpochs, uint256 _attesterReputationThreshold)`: Attests a skill to a user, minting a Skill SBT, requiring minimum attester reputation.
4.  `revokeSkill(address _user, string _skillHash)`: Revokes an attested skill from a user.
5.  `hasSkill(address _user, string _skillHash)`: Checks if a user possesses an active (non-expired) skill.
6.  `delegateRole(address _delegatee, string _roleHash, uint256 _durationEpochs)`: Delegates a role to a user, minting a Role SBT.
7.  `revokeRole(address _delegatee, string _roleHash)`: Revokes a delegated role from a user.

**C. Reputation System**
8.  `getCurrentReputation(address _user)`: Retrieves the current reputation score for a user.
9.  `submitReputationFeedback(address _targetUser, uint256 _taskId, int8 _rating)`: Submits peer feedback for a completed task, influencing reputation.
10. `triggerEpochAdvance()`: Advances the current epoch, triggering internal state updates.
11. `getEpochReputation(address _user, uint256 _epoch)`: Retrieves the historical reputation of a user at a specific epoch.

**D. Task Management & Execution**
12. `createTask(string _taskMetadataURI, uint256 _rewardAmount, uint256 _commitmentDeposit, uint256 _deadlineEpoch, string[] _requiredSkillHashes)`: Creates a new task with specified reward, commitment, deadline, and required skills.
13. `acceptTask(uint256 _taskId)`: Allows a user to accept a task, requiring active skills, sufficient reputation, and a commitment deposit.
14. `submitTaskCompletion(uint256 _taskId, string _proofURI)`: Allows the worker to submit proof of completion for an accepted task.
15. `verifyTaskCompletion(uint256 _taskId, bool _isComplete, string _reasonURI)`: Verifies task completion, distributing rewards/slashing deposits, and updating reputation.
16. `cancelTask(uint256 _taskId)`: Allows the creator or owner to cancel a pending/accepted task, refunding funds.

**E. Dispute Resolution Interface**
17. `raiseDispute(uint256 _taskId, string _disputeMetadataURI)`: Initiates a dispute over a task.
18. `resolveDispute(uint256 _taskId, bool _workerWon, string _resolutionURI)`: Resolves a dispute, callable only by the designated dispute resolver.

**F. Configuration & Administration**
19. `setCommitmentToken(address _tokenAddress)`: Sets the ERC20 token used for commitment deposits and rewards.
20. `setReputationThresholds(uint256 _attesterThreshold, uint256 _taskAcceptanceThreshold)`: Sets minimum reputation for attesting skills and accepting tasks.
21. `setEpochDuration(uint256 _newEpochDurationSeconds)`: Sets the duration of an epoch in seconds.
22. `withdrawFunds(address _tokenAddress, address _to, uint256 _amount)`: Allows the owner to withdraw unallocated funds from the contract.
23. `updateDisputeResolver(address _newResolver)`: Updates the address of the dispute resolver.
24. `getCurrentEpoch()`: Retrieves the current epoch number (note: view function, accuracy depends on last state-changing call).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; // For Strings.toString

// Minimal ERC721-like interface for Soulbound Tokens (SBTs)
// These tokens are non-transferable by design.
interface ISoulboundToken {
    event Minted(address indexed to, uint256 tokenId, string uri);
    event Burned(address indexed from, uint256 tokenId);
    event UriUpdated(uint256 tokenId, string newUri);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function balanceOf(address owner) external view returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address);
    function tokenURI(uint256 tokenId) external view returns (string memory);
    function getTokenIdByOwner(address owner) external view returns (uint256); // For unique SBTs per user
    // No transfer functions are exposed or allowed.
}

// Minimal implementation of a non-transferable ERC721-like token
// Designed for internal use by CognitoNet to manage profiles, skills, and roles.
contract SoulboundERC721 is ISoulboundToken {
    using Counters for Counters.Counter;

    string public override name;
    string public override symbol;

    Counters.Counter private _tokenIdCounter;
    mapping(uint256 => address) private _tokenOwners; // Token ID to owner
    mapping(address => uint256) private _ownerTokens; // Owner to Token ID (for single token per owner)
    mapping(uint256 => string) private _tokenUris; // Token ID to URI

    // Flag to ensure only one SBT of this type can be minted per owner address
    bool public enforceSingleTokenPerOwner;

    constructor(string memory _name, string memory _symbol, bool _enforceSingleTokenPerOwner) {
        name = _name;
        symbol = _symbol;
        enforceSingleTokenPerOwner = _enforceSingleTokenPerOwner;
    }

    /**
     * @notice Returns the number of tokens in `owner`'s account.
     * @param owner The address to query the balance of.
     * @return The number of tokens owned by `owner`.
     */
    function balanceOf(address owner) public view override returns (uint256) {
        return _ownerTokens[owner] != 0 ? 1 : 0;
    }

    /**
     * @notice Returns the owner of the `tokenId` token.
     * @param tokenId The identifier for a token.
     * @return The address of the token owner.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        require(_tokenOwners[tokenId] != address(0), "SBT: Invalid token ID");
        return _tokenOwners[tokenId];
    }

    /**
     * @notice Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     * @param tokenId The identifier for a token.
     * @return The URI string.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return _tokenUris[tokenId];
    }

    /**
     * @notice Returns the token ID owned by `owner`. Useful for single-token-per-owner SBTs.
     * @param owner The address to query the token ID of.
     * @return The token ID owned by `owner`. Returns 0 if no token is owned.
     */
    function getTokenIdByOwner(address owner) public view override returns (uint256) {
        return _ownerTokens[owner];
    }

    /**
     * @dev Mints a new SBT to `to`. Internal function, called by `CognitoNet`.
     * @param to The address to mint the token to.
     * @param uri The metadata URI for the token.
     * @return The ID of the newly minted token.
     */
    function _mint(address to, string memory uri) internal returns (uint256) {
        require(to != address(0), "SBT: mint to the zero address");
        if (enforceSingleTokenPerOwner) {
            require(_ownerTokens[to] == 0, "SBT: Already owns a token of this type");
        }

        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        _tokenOwners[newTokenId] = to;
        _ownerTokens[to] = newTokenId;
        _tokenUris[newTokenId] = uri;

        emit Minted(to, newTokenId, uri);
        return newTokenId;
    }

    /**
     * @dev Burns an SBT from `from`. Internal function, called by `CognitoNet`.
     * @param from The address whose token is being burned.
     * @param tokenId The ID of the token to burn.
     */
    function _burn(address from, uint256 tokenId) internal {
        require(_tokenOwners[tokenId] == from, "SBT: not token owner");

        delete _tokenOwners[tokenId];
        delete _ownerTokens[from];
        delete _tokenUris[tokenId];

        emit Burned(from, tokenId);
    }

    /**
     * @dev Updates the metadata URI for an SBT. Internal function, called by `CognitoNet`.
     * @param tokenId The ID of the token to update.
     * @param newUri The new metadata URI.
     */
    function _setTokenURI(uint256 tokenId, string memory newUri) internal {
        require(_tokenOwners[tokenId] != address(0), "SBT: Invalid token ID");
        _tokenUris[tokenId] = newUri;
        emit UriUpdated(tokenId, newUri);
    }
}

contract CognitoNet is Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // --- Data Structures ---

    enum TaskStatus {
        Pending,            // Task created, awaiting acceptance by a worker
        Accepted,           // Task accepted by a worker
        SubmittedForReview, // Worker submitted proof of completion
        Completed,          // Task verified and completed successfully
        Disputed,           // Task completion is under dispute
        Cancelled,          // Task cancelled (by creator or governance)
        Failed              // Task failed (e.g., deadline missed, worker slashed)
    }

    struct Task {
        uint256 id;
        address creator;
        address worker; // The address who accepted the task
        string metadataURI; // IPFS hash or URL for task details
        uint256 rewardAmount; // Amount to be paid to the worker
        uint256 commitmentDeposit; // Deposit required from the worker
        address commitmentToken; // ERC20 token for deposit and reward
        uint256 deadlineEpoch; // Epoch by which task must be submitted
        uint256 submissionEpoch; // Epoch when worker submitted proof
        string[] requiredSkillHashes; // Hashes of skills required
        TaskStatus status;
        string proofURI; // IPFS hash or URL for proof of completion
        string disputeURI; // IPFS hash or URL for dispute details
        uint256 createdAt; // Timestamp of creation
    }

    struct Skill {
        string skillHash; // Unique identifier for the skill (e.g., keccak256 hash of "SolidityDev")
        uint256 tokenId; // Corresponding SBT token ID
        uint256 attestationEpoch; // Epoch when the skill was attested
        uint256 durationEpochs; // How many epochs the skill is valid for (0 for indefinite)
        address attester; // Who attested this skill
    }

    struct Role {
        string roleHash; // Unique identifier for the role (e.g., keccak256 hash of "ProjectLead")
        uint256 tokenId; // Corresponding SBT token ID
        uint256 attestationEpoch; // Epoch when the role was assigned
        uint256 durationEpochs; // How many epochs the role assignment is valid for (0 for indefinite)
        address assigner; // Who assigned this role
    }

    // --- State Variables ---

    // SBT Contracts
    SoulboundERC721 public profileSBT;
    SoulboundERC721 public skillSBT;
    SoulboundERC721 public roleSBT;

    // Reputation System
    mapping(address => uint256) public currentReputation; // Current reputation score for an address
    mapping(address => mapping(uint256 => uint256)) public epochReputations; // Historical reputation: user => epoch => score
    uint256 public reputationAttesterThreshold = 1000; // Min reputation required to attest a skill
    uint256 public reputationTaskAcceptanceThreshold = 500; // Min reputation required to accept a task

    // Reputation adjustment constants
    int256 public constant REPUTATION_INITIAL_BONUS = 100;
    int256 public constant REPUTATION_FEEDBACK_INCREMENT = 50; // Base reputation change for positive feedback
    int256 public constant REPUTATION_FEEDBACK_DECREMENT = -75; // Base reputation change for negative feedback
    int256 public constant REPUTATION_DISPUTE_WIN_BONUS = 200; // Bonus for winning a dispute
    int256 public constant REPUTATION_DISPUTE_LOSE_PENALTY = -250; // Penalty for losing a dispute
    int256 public constant REPUTATION_TASK_COMPLETION_BONUS = 100; // Bonus for successful task completion
    int256 public constant REPUTATION_TASK_FAILURE_PENALTY = -150; // Penalty for task failure/missed deadline
    int256 public constant REPUTATION_TASK_CANCEL_PENALTY_WORKER = -50; // Penalty for worker if task cancelled by creator

    // Epoch Management
    uint256 public currentEpoch;
    uint256 public epochDurationSeconds = 7 days; // Default 1 week per epoch
    uint256 public lastEpochUpdateTimestamp;

    // Task Management
    Counters.Counter private _taskIdCounter;
    mapping(uint256 => Task) public tasks;
    address public commitmentTokenAddress; // ERC20 token used for task commitments and rewards

    // Skill & Role Management
    mapping(address => mapping(string => Skill)) private userSkills; // user => skillHash => Skill
    mapping(address => mapping(string => Role)) private userRoles; // user => roleHash => Role

    // Dispute Resolution
    address public disputeResolver; // Address of a contract or multisig that handles disputes

    // --- Events ---

    event ProfileRegistered(address indexed user, uint256 profileTokenId, string metadataURI);
    event ProfileUpdated(address indexed user, uint256 profileTokenId, string newMetadataURI);
    event SkillAttested(address indexed user, string skillHash, uint256 skillTokenId, address indexed attester, uint256 durationEpochs);
    event SkillRevoked(address indexed user, string skillHash, uint256 skillTokenId, address indexed revoker);
    event RoleDelegated(address indexed delegatee, string roleHash, uint256 roleTokenId, address indexed assigner, uint256 durationEpochs);
    event RoleRevoked(address indexed delegatee, string roleHash, uint256 roleTokenId, address indexed revoker);

    event TaskCreated(uint256 indexed taskId, address indexed creator, string metadataURI, uint256 rewardAmount, uint256 commitmentDeposit, address commitmentToken, uint256 deadlineEpoch);
    event TaskAccepted(uint256 indexed taskId, address indexed worker);
    event TaskSubmitted(uint256 indexed taskId, address indexed worker, string proofURI);
    event TaskVerified(uint256 indexed taskId, address indexed verifier, bool isComplete, TaskStatus newStatus);
    event TaskCancelled(uint256 indexed taskId, address indexed canceller);
    event TaskFailed(uint256 indexed taskId, address indexed worker); // Missed deadline or similar failure

    event DisputeRaised(uint256 indexed taskId, address indexed disputer, string disputeMetadataURI);
    event DisputeResolved(uint256 indexed taskId, address indexed resolver, bool workerWon, string resolutionURI);

    event ReputationUpdated(address indexed user, uint256 oldReputation, uint256 newReputation, string reason);
    event EpochAdvanced(uint256 indexed oldEpoch, uint256 indexed newEpoch, uint256 timestamp);

    // --- Constructor ---

    constructor(address _disputeResolver, address _commitmentTokenAddress) Ownable(msg.sender) {
        profileSBT = new SoulboundERC721("CognitoNet Profile", "CNPROF", true);
        skillSBT = new SoulboundERC721("CognitoNet Skill", "CNSKILL", false); // Multiple skills per user
        roleSBT = new SoulboundERC721("CognitoNet Role", "CNROLE", false); // Multiple roles per user

        require(_disputeResolver != address(0), "CognitoNet: Dispute resolver cannot be zero address.");
        disputeResolver = _disputeResolver;
        
        require(Address.isContract(_commitmentTokenAddress), "CognitoNet: Token address must be a contract.");
        commitmentTokenAddress = _commitmentTokenAddress;

        // Initialize first epoch
        lastEpochUpdateTimestamp = block.timestamp;
        currentEpoch = 1;
    }

    // --- Modifiers ---

    modifier onlyRegisteredProfile() {
        require(profileSBT.balanceOf(msg.sender) > 0, "CognitoNet: User must have a registered profile");
        _;
    }

    modifier onlyDisputeResolver() {
        require(msg.sender == disputeResolver, "CognitoNet: Only dispute resolver can call this function");
        _;
    }

    // --- Internal Helpers ---

    /**
     * @dev Updates the current epoch based on `epochDurationSeconds` and `lastEpochUpdateTimestamp`.
     *      Also records current reputation for the just-ended epoch.
     */
    function _updateCurrentEpoch() internal {
        uint256 timeSinceLastUpdate = block.timestamp.sub(lastEpochUpdateTimestamp);
        if (timeSinceLastUpdate >= epochDurationSeconds) {
            uint256 epochsPassed = timeSinceLastUpdate.div(epochDurationSeconds);
            uint256 oldEpoch = currentEpoch;
            currentEpoch = currentEpoch.add(epochsPassed);
            lastEpochUpdateTimestamp = lastEpochUpdateTimestamp.add(epochsPassed.mul(epochDurationSeconds));

            // In a more complex system, this would iterate all users or use a snapshot.
            // For simplicity, epochReputations mapping is updated when reputation changes or epoch advances
            // for active users.
            emit EpochAdvanced(oldEpoch, currentEpoch, block.timestamp);
        }
    }

    /**
     * @dev Internal function to safely update a user's reputation score.
     * @param _user The address of the user whose reputation to update.
     * @param _delta The amount to change the reputation by (can be negative).
     * @param _reason A string describing the reason for the reputation change.
     */
    function _updateReputation(address _user, int256 _delta, string memory _reason) internal {
        _requireProfile(_user); // Ensure reputation only for registered profiles
        uint256 oldRep = currentReputation[_user];
        uint256 newRep;

        if (_delta > 0) {
            newRep = oldRep.add(uint256(_delta));
        } else if (_delta < 0) {
            uint256 absDelta = uint256(_delta * -1);
            newRep = oldRep >= absDelta ? oldRep.sub(absDelta) : 0; // Prevent reputation from going below 0
        } else {
            newRep = oldRep; // No change
        }
        
        currentReputation[_user] = newRep;
        epochReputations[_user][currentEpoch] = newRep; // Snapshot for current epoch

        emit ReputationUpdated(_user, oldRep, newRep, _reason);
    }

    /**
     * @dev Internal helper to check if a user has a registered profile.
     * @param _user The address to check.
     */
    function _requireProfile(address _user) internal view {
        require(profileSBT.balanceOf(_user) > 0, "CognitoNet: User does not have a registered profile.");
    }

    /**
     * @dev Internal helper to check if a user possesses an active skill.
     * @param _user The address of the user.
     * @param _skillHash The unique identifier for the skill.
     * @return True if the user has the active skill, false otherwise.
     */
    function _hasActiveSkill(address _user, string memory _skillHash) internal view returns (bool) {
        Skill storage skill = userSkills[_user][_skillHash];
        // Check if skill exists and is not expired (if durationEpochs > 0)
        return skill.tokenId != 0 && (skill.durationEpochs == 0 || currentEpoch <= skill.attestationEpoch.add(skill.durationEpochs));
    }

    /**
     * @dev Internal helper to check if a user possesses an active role.
     * @param _user The address of the user.
     * @param _roleHash The unique identifier for the role.
     * @return True if the user has the active role, false otherwise.
     */
    function _hasActiveRole(address _user, string memory _roleHash) internal view returns (bool) {
        Role storage role = userRoles[_user][_roleHash];
        // Check if role exists and is not expired (if durationEpochs > 0)
        return role.tokenId != 0 && (role.durationEpochs == 0 || currentEpoch <= role.attestationEpoch.add(role.durationEpochs));
    }

    // --- Public / External Functions ---

    // A. Identity & Profile Management (SBT-0 Profile)

    /**
     * @notice Registers a new user profile and mints a unique profile Soulbound Token (SBT).
     *         A user can only register one profile. Also grants initial reputation.
     * @param _metadataURI URI pointing to off-chain metadata (e.g., IPFS) for the profile.
     */
    function registerProfile(string calldata _metadataURI) external {
        require(profileSBT.balanceOf(msg.sender) == 0, "CognitoNet: Profile already registered.");
        uint256 tokenId = profileSBT._mint(msg.sender, _metadataURI);
        _updateReputation(msg.sender, REPUTATION_INITIAL_BONUS, "Initial profile registration bonus");
        emit ProfileRegistered(msg.sender, tokenId, _metadataURI);
    }

    /**
     * @notice Updates the metadata URI for an existing user profile SBT.
     * @param _newMetadataURI New URI pointing to updated off-chain metadata.
     */
    function updateProfileMetadata(string calldata _newMetadataURI) external onlyRegisteredProfile {
        uint256 tokenId = profileSBT.getTokenIdByOwner(msg.sender);
        profileSBT._setTokenURI(tokenId, _newMetadataURI);
        emit ProfileUpdated(msg.sender, tokenId, _newMetadataURI);
    }

    // B. Skill & Role Attestation (SBT-1 Skills, SBT-2 Roles)

    /**
     * @notice Attests a specific skill to a user by minting a Skill SBT.
     *         Requires the attester to have a minimum reputation.
     * @param _user The address of the user receiving the skill.
     * @param _skillHash A unique identifier (e.g., hash) for the skill.
     * @param _durationEpochs The number of epochs this skill attestation is valid for. 0 for indefinite.
     * @param _attesterReputationThreshold Minimum reputation the attester needs to perform this attestation.
     */
    function attestSkill(
        address _user,
        string calldata _skillHash,
        uint256 _durationEpochs,
        uint256 _attesterReputationThreshold
    ) external onlyRegisteredProfile {
        _requireProfile(_user);
        require(msg.sender != _user, "CognitoNet: Cannot attest your own skill.");
        require(currentReputation[msg.sender] >= _attesterReputationThreshold, "CognitoNet: Attester reputation too low.");
        require(userSkills[_user][_skillHash].tokenId == 0, "CognitoNet: Skill already attested for this user.");

        // Construct a unique metadata URI for the skill SBT
        string memory skillMetadataURI = string(abi.encodePacked("ipfs://", _skillHash, ".json"));
        uint256 skillTokenId = skillSBT._mint(_user, skillMetadataURI);

        userSkills[_user][_skillHash] = Skill({
            skillHash: _skillHash,
            tokenId: skillTokenId,
            attestationEpoch: currentEpoch,
            durationEpochs: _durationEpochs,
            attester: msg.sender
        });

        emit SkillAttested(_user, _skillHash, skillTokenId, msg.sender, _durationEpochs);
    }

    /**
     * @notice Revokes an attested skill from a user. Only the original attester, the user, or the owner can revoke.
     * @param _user The address of the user whose skill is being revoked.
     * @param _skillHash The unique identifier for the skill to revoke.
     */
    function revokeSkill(address _user, string calldata _skillHash) external onlyRegisteredProfile {
        Skill storage skill = userSkills[_user][_skillHash];
        require(skill.tokenId != 0, "CognitoNet: Skill not found for user.");
        require(msg.sender == skill.attester || msg.sender == _user || msg.sender == owner(), "CognitoNet: Not authorized to revoke skill.");

        skillSBT._burn(_user, skill.tokenId);
        delete userSkills[_user][_skillHash]; // Remove the skill entry

        emit SkillRevoked(_user, _skillHash, skill.tokenId, msg.sender);
    }

    /**
     * @notice Checks if a user possesses an active (non-expired) skill.
     * @param _user The address of the user.
     * @param _skillHash The unique identifier for the skill.
     * @return True if the user has the active skill, false otherwise.
     */
    function hasSkill(address _user, string calldata _skillHash) external view returns (bool) {
        _updateCurrentEpoch(); // Ensure epoch is up-to-date for validity check
        return _hasActiveSkill(_user, _skillHash);
    }

    /**
     * @notice Delegates a specific role to a user by minting a Role SBT.
     *         Can be used by project DAOs, sub-DAOs, or the contract owner.
     * @param _delegatee The address receiving the role.
     * @param _roleHash A unique identifier (e.g., hash) for the role.
     * @param _durationEpochs The number of epochs this role assignment is valid for. 0 for indefinite.
     */
    function delegateRole(
        address _delegatee,
        string calldata _roleHash,
        uint256 _durationEpochs
    ) external onlyRegisteredProfile {
        _requireProfile(_delegatee);
        // Authorization check: Only owner or specific roles/reputation can delegate certain roles
        // For simplicity, any registered profile can delegate, but can be restricted.
        // require(msg.sender == authorizedDelegator || _hasActiveRole(msg.sender, "RoleManager"), "CognitoNet: Not authorized to delegate role.");
        require(userRoles[_delegatee][_roleHash].tokenId == 0, "CognitoNet: Role already delegated to this user.");

        string memory roleMetadataURI = string(abi.encodePacked("ipfs://", _roleHash, ".json"));
        uint256 roleTokenId = roleSBT._mint(_delegatee, roleMetadataURI);

        userRoles[_delegatee][_roleHash] = Role({
            roleHash: _roleHash,
            tokenId: roleTokenId,
            attestationEpoch: currentEpoch,
            durationEpochs: _durationEpochs,
            assigner: msg.sender
        });

        emit RoleDelegated(_delegatee, _roleHash, roleTokenId, msg.sender, _durationEpochs);
    }

    /**
     * @notice Revokes a delegated role from a user. Only the original assigner, the user, or the owner can revoke.
     * @param _delegatee The address whose role is being revoked.
     * @param _roleHash The unique identifier for the role to revoke.
     */
    function revokeRole(address _delegatee, string calldata _roleHash) external onlyRegisteredProfile {
        Role storage role = userRoles[_delegatee][_roleHash];
        require(role.tokenId != 0, "CognitoNet: Role not found for user.");
        require(msg.sender == role.assigner || msg.sender == _delegatee || msg.sender == owner(), "CognitoNet: Not authorized to revoke role.");

        roleSBT._burn(_delegatee, role.tokenId);
        delete userRoles[_delegatee][_roleHash]; // Remove the role entry

        emit RoleRevoked(_delegatee, _roleHash, role.tokenId, msg.sender);
    }

    // C. Reputation System

    /**
     * @notice Retrieves the current reputation score for a user.
     * @param _user The address of the user.
     * @return The current reputation score.
     */
    function getCurrentReputation(address _user) external view returns (uint256) {
        return currentReputation[_user];
    }

    /**
     * @notice Submits reputation feedback for a completed task.
     *         This can be called by the task creator (for worker) or worker (for creator, in some systems).
     *         The rating influences reputation scores.
     * @param _targetUser The user whose reputation is being rated (e.g., the worker for a task).
     * @param _taskId The ID of the task the feedback relates to.
     * @param _rating A rating value (e.g., 1 for positive, -1 for negative, 0 for neutral).
     */
    function submitReputationFeedback(
        address _targetUser,
        uint256 _taskId,
        int8 _rating
    ) external onlyRegisteredProfile {
        Task storage task = tasks[_taskId];
        require(task.status == TaskStatus.Completed, "CognitoNet: Feedback can only be submitted for completed tasks.");
        require(msg.sender == task.creator || msg.sender == task.worker, "CognitoNet: Only task participants can submit feedback.");
        require(_targetUser == task.creator || _targetUser == task.worker, "CognitoNet: Target user not a participant in this task.");
        require(_targetUser != msg.sender, "CognitoNet: Cannot give feedback to yourself.");

        int256 delta = 0;
        if (_rating > 0) {
            delta = REPUTATION_FEEDBACK_INCREMENT; // Positive feedback
        } else if (_rating < 0) {
            delta = REPUTATION_FEEDBACK_DECREMENT; // Negative feedback
        }

        if (delta != 0) {
            _updateReputation(_targetUser, delta, string(abi.encodePacked("Feedback for Task #", Strings.toString(_taskId))));
        }
    }

    /**
     * @notice Advances the current epoch, storing a snapshot of current reputations.
     *         This function can be triggered by anyone after `epochDurationSeconds` has passed.
     *         This is important for time-based skill validity and historical reputation.
     */
    function triggerEpochAdvance() external {
        _updateCurrentEpoch(); // This function contains the logic to advance and emit events
    }

    /**
     * @notice Retrieves the reputation of a user at a specific historical epoch.
     * @param _user The address of the user.
     * @param _epoch The epoch number.
     * @return The reputation score at that epoch.
     */
    function getEpochReputation(address _user, uint256 _epoch) external view returns (uint256) {
        return epochReputations[_user][_epoch];
    }


    // D. Task Management & Execution

    /**
     * @notice Creates a new task.
     *         Requires the creator to have a registered profile.
     *         The reward amount and commitment deposit are in the specified ERC20 token.
     * @param _taskMetadataURI URI for task details.
     * @param _rewardAmount Amount to be paid to the worker upon successful completion.
     * @param _commitmentDeposit Deposit required from the worker to accept the task.
     * @param _deadlineEpoch The epoch by which the task must be completed.
     * @param _requiredSkillHashes Array of skill hashes required for the worker.
     */
    function createTask(
        string calldata _taskMetadataURI,
        uint256 _rewardAmount,
        uint256 _commitmentDeposit,
        uint256 _deadlineEpoch,
        string[] calldata _requiredSkillHashes
    ) external onlyRegisteredProfile {
        _updateCurrentEpoch();
        require(_rewardAmount > 0, "CognitoNet: Reward must be greater than zero.");
        require(_commitmentDeposit >= _rewardAmount.div(10), "CognitoNet: Commitment deposit must be at least 10% of reward (example rule)."); 
        require(_deadlineEpoch > currentEpoch, "CognitoNet: Deadline must be in a future epoch.");
        require(IERC20(commitmentTokenAddress).balanceOf(msg.sender) >= _rewardAmount, "CognitoNet: Creator lacks sufficient reward tokens.");
        require(IERC20(commitmentTokenAddress).allowance(msg.sender, address(this)) >= _rewardAmount, "CognitoNet: Creator must approve reward tokens.");

        _taskIdCounter.increment();
        uint256 taskId = _taskIdCounter.current();

        // Transfer reward tokens from creator to contract
        IERC20(commitmentTokenAddress).transferFrom(msg.sender, address(this), _rewardAmount);

        tasks[taskId] = Task({
            id: taskId,
            creator: msg.sender,
            worker: address(0), // No worker yet
            metadataURI: _taskMetadataURI,
            rewardAmount: _rewardAmount,
            commitmentDeposit: _commitmentDeposit,
            commitmentToken: commitmentTokenAddress,
            deadlineEpoch: _deadlineEpoch,
            submissionEpoch: 0,
            requiredSkillHashes: _requiredSkillHashes,
            status: TaskStatus.Pending,
            proofURI: "",
            disputeURI: "",
            createdAt: block.timestamp
        });

        emit TaskCreated(taskId, msg.sender, _taskMetadataURI, _rewardAmount, _commitmentDeposit, commitmentTokenAddress, _deadlineEpoch);
    }

    /**
     * @notice Allows a registered user to accept a pending task.
     *         Requires the worker to have all required skills and sufficient reputation.
     *         Worker must also approve the `commitmentDeposit` before calling this.
     * @param _taskId The ID of the task to accept.
     */
    function acceptTask(uint256 _taskId) external onlyRegisteredProfile {
        _updateCurrentEpoch();
        Task storage task = tasks[_taskId];
        require(task.status == TaskStatus.Pending, "CognitoNet: Task is not pending.");
        require(task.creator != msg.sender, "CognitoNet: Creator cannot accept their own task.");
        require(currentReputation[msg.sender] >= reputationTaskAcceptanceThreshold, "CognitoNet: Worker reputation too low to accept task.");
        require(IERC20(task.commitmentToken).balanceOf(msg.sender) >= task.commitmentDeposit, "CognitoNet: Worker lacks sufficient commitment tokens.");
        require(IERC20(task.commitmentToken).allowance(msg.sender, address(this)) >= task.commitmentDeposit, "CognitoNet: Worker must approve commitment deposit.");

        // Check for required skills
        for (uint252 i = 0; i < task.requiredSkillHashes.length; i++) {
            require(_hasActiveSkill(msg.sender, task.requiredSkillHashes[i]), string(abi.encodePacked("CognitoNet: Missing required skill: ", task.requiredSkillHashes[i])));
        }

        // Transfer commitment deposit from worker to contract
        IERC20(task.commitmentToken).transferFrom(msg.sender, address(this), task.commitmentDeposit);

        task.worker = msg.sender;
        task.status = TaskStatus.Accepted;

        emit TaskAccepted(_taskId, msg.sender);
    }

    /**
     * @notice Allows the worker to submit proof of completion for an accepted task.
     * @param _taskId The ID of the task.
     * @param _proofURI URI pointing to the proof of completion.
     */
    function submitTaskCompletion(uint256 _taskId, string calldata _proofURI) external onlyRegisteredProfile {
        _updateCurrentEpoch();
        Task storage task = tasks[_taskId];
        require(task.status == TaskStatus.Accepted, "CognitoNet: Task not in accepted state.");
        require(task.worker == msg.sender, "CognitoNet: Only the assigned worker can submit completion.");
        require(currentEpoch <= task.deadlineEpoch, "CognitoNet: Task deadline has passed.");

        task.proofURI = _proofURI;
        task.submissionEpoch = currentEpoch;
        task.status = TaskStatus.SubmittedForReview;

        emit TaskSubmitted(_taskId, msg.sender, _proofURI);
    }

    /**
     * @notice Verifies the completion of a submitted task. Can be called by task creator or governance.
     *         Distributes rewards, releases/slashes deposits, and updates reputation based on verification.
     * @param _taskId The ID of the task to verify.
     * @param _isComplete True if the task is successfully completed, false if failed.
     * @param _reasonURI URI for additional details/reason for verification outcome.
     */
    function verifyTaskCompletion(
        uint256 _taskId,
        bool _isComplete,
        string calldata _reasonURI
    ) external onlyRegisteredProfile {
        _updateCurrentEpoch();
        Task storage task = tasks[_taskId];
        require(task.status == TaskStatus.SubmittedForReview, "CognitoNet: Task not awaiting review.");
        require(msg.sender == task.creator || msg.sender == owner(), "CognitoNet: Only task creator or owner can verify.");
        require(task.worker != address(0), "CognitoNet: Task must have an assigned worker.");

        if (_isComplete) {
            task.status = TaskStatus.Completed;
            // Transfer reward to worker
            IERC20(task.commitmentToken).transfer(task.worker, task.rewardAmount);
            // Refund worker's commitment deposit
            IERC20(task.commitmentToken).transfer(task.worker, task.commitmentDeposit);
            _updateReputation(task.worker, REPUTATION_TASK_COMPLETION_BONUS, string(abi.encodePacked("Task #", Strings.toString(_taskId), " completed")));
        } else {
            task.status = TaskStatus.Failed;
            // Worker's commitment deposit is slashed (stays in contract).
            // Could be configured to go to creator or a DAO fund.
            _updateReputation(task.worker, REPUTATION_TASK_FAILURE_PENALTY, string(abi.encodePacked("Task #", Strings.toString(_taskId), " failed")));
        }
        task.disputeURI = _reasonURI; // Use disputeURI for resolution reason

        emit TaskVerified(_taskId, msg.sender, _isComplete, task.status);
    }

    /**
     * @notice Allows a task creator to cancel a pending task, or the owner to cancel any task.
     *         Refunds the creator's reward amount. If task was accepted, worker's deposit is refunded.
     * @param _taskId The ID of the task to cancel.
     */
    function cancelTask(uint256 _taskId) external onlyRegisteredProfile {
        Task storage task = tasks[_taskId];
        require(task.status == TaskStatus.Pending || task.status == TaskStatus.Accepted, "CognitoNet: Task cannot be cancelled in its current state.");
        require(msg.sender == task.creator || msg.sender == owner(), "CognitoNet: Not authorized to cancel task.");

        if (task.status == TaskStatus.Accepted) {
            // Refund worker's commitment deposit if task was accepted
            IERC20(task.commitmentToken).transfer(task.worker, task.commitmentDeposit);
            _updateReputation(task.worker, REPUTATION_TASK_CANCEL_PENALTY_WORKER, string(abi.encodePacked("Task #", Strings.toString(_taskId), " cancelled by creator"))); // Small penalty for worker if cancelled unexpectedly
        }

        // Refund creator's reward tokens
        IERC20(task.commitmentToken).transfer(task.creator, task.rewardAmount);
        task.status = TaskStatus.Cancelled;

        emit TaskCancelled(_taskId, msg.sender);
    }

    // E. Dispute Resolution Interface

    /**
     * @notice Raises a dispute over a task. Can be called by creator or worker if they disagree with verification or completion.
     * @param _taskId The ID of the disputed task.
     * @param _disputeMetadataURI URI for dispute details (e.g., evidence, reasoning).
     */
    function raiseDispute(uint256 _taskId, string calldata _disputeMetadataURI) external onlyRegisteredProfile {
        Task storage task = tasks[_taskId];
        require(task.status == TaskStatus.SubmittedForReview || task.status == TaskStatus.Accepted, "CognitoNet: Task not in a state eligible for dispute.");
        require(msg.sender == task.creator || msg.sender == task.worker, "CognitoNet: Only task creator or worker can raise a dispute.");
        require(task.worker != address(0), "CognitoNet: Disputed task must have a worker.");

        task.status = TaskStatus.Disputed;
        task.disputeURI = _disputeMetadataURI;

        emit DisputeRaised(_taskId, msg.sender, _disputeMetadataURI);
    }

    /**
     * @notice Resolves a dispute. Callable only by the designated dispute resolver.
     *         Distributes funds and adjusts reputation based on the resolution.
     * @param _taskId The ID of the disputed task.
     * @param _workerWon True if the worker wins the dispute, false if the creator wins.
     * @param _resolutionURI URI for the resolution details.
     */
    function resolveDispute(
        uint256 _taskId,
        bool _workerWon,
        string calldata _resolutionURI
    ) external onlyDisputeResolver {
        Task storage task = tasks[_taskId];
        require(task.status == TaskStatus.Disputed, "CognitoNet: Task is not currently disputed.");

        if (_workerWon) {
            // Worker wins: worker gets reward + deposit back, creator gets nothing
            IERC20(task.commitmentToken).transfer(task.worker, task.rewardAmount);
            IERC20(task.commitmentToken).transfer(task.worker, task.commitmentDeposit);
            _updateReputation(task.worker, REPUTATION_DISPUTE_WIN_BONUS, string(abi.encodePacked("Dispute #", Strings.toString(_taskId), " won")));
            _updateReputation(task.creator, REPUTATION_DISPUTE_LOSE_PENALTY, string(abi.encodePacked("Dispute #", Strings.toString(_taskId), " lost")));
            task.status = TaskStatus.Completed;
        } else {
            // Creator wins: creator's reward stays in contract, worker's deposit is slashed
            // For now, slashed deposit stays in contract. Can be configured to go to creator.
            _updateReputation(task.creator, REPUTATION_DISPUTE_WIN_BONUS, string(abi.encodePacked("Dispute #", Strings.toString(_taskId), " won")));
            _updateReputation(task.worker, REPUTATION_DISPUTE_LOSE_PENALTY, string(abi.encodePacked("Dispute #", Strings.toString(_taskId), " lost")));
            task.status = TaskStatus.Failed;
        }
        task.disputeURI = _resolutionURI; // Update disputeURI with resolution details

        emit DisputeResolved(_taskId, msg.sender, _workerWon, _resolutionURI);
    }

    // F. Configuration & Administration

    /**
     * @notice Sets the address of the ERC20 token to be used for commitment deposits and rewards.
     *         Only callable by the contract owner.
     * @param _tokenAddress The address of the ERC20 token.
     */
    function setCommitmentToken(address _tokenAddress) external onlyOwner {
        require(Address.isContract(_tokenAddress), "CognitoNet: Token address must be a contract.");
        commitmentTokenAddress = _tokenAddress;
    }

    /**
     * @notice Sets the minimum reputation thresholds for attesting skills and accepting tasks.
     *         Only callable by the contract owner.
     * @param _attesterThreshold Minimum reputation required to attest a skill.
     * @param _taskAcceptanceThreshold Minimum reputation required to accept a task.
     */
    function setReputationThresholds(uint256 _attesterThreshold, uint256 _taskAcceptanceThreshold) external onlyOwner {
        reputationAttesterThreshold = _attesterThreshold;
        reputationTaskAcceptanceThreshold = _taskAcceptanceThreshold;
    }

    /**
     * @notice Sets the duration of an epoch in seconds.
     *         Only callable by the contract owner.
     * @param _newEpochDurationSeconds The new duration for an epoch in seconds.
     */
    function setEpochDuration(uint256 _newEpochDurationSeconds) external onlyOwner {
        require(_newEpochDurationSeconds > 0, "CognitoNet: Epoch duration must be positive.");
        epochDurationSeconds = _newEpochDurationSeconds;
    }

    /**
     * @notice Allows the owner to withdraw unallocated funds from the contract.
     *         This can include slashed deposits or accidentally sent tokens.
     * @param _tokenAddress The address of the ERC20 token to withdraw.
     * @param _to The address to send the funds to.
     * @param _amount The amount to withdraw.
     */
    function withdrawFunds(address _tokenAddress, address _to, uint256 _amount) external onlyOwner {
        require(_to != address(0), "CognitoNet: Cannot withdraw to the zero address.");
        require(_amount > 0, "CognitoNet: Amount must be greater than zero.");
        IERC20 token = IERC20(_tokenAddress);
        require(token.balanceOf(address(this)) >= _amount, "CognitoNet: Insufficient balance in contract.");
        token.transfer(_to, _amount);
    }

    /**
     * @notice Updates the address of the dispute resolver.
     *         Only callable by the contract owner.
     * @param _newResolver The new address for the dispute resolver.
     */
    function updateDisputeResolver(address _newResolver) external onlyOwner {
        require(_newResolver != address(0), "CognitoNet: Dispute resolver cannot be zero address.");
        disputeResolver = _newResolver;
    }

    /**
     * @notice Retrieves the current epoch number. Note: This view function returns the last
     *         known epoch. For the absolute most up-to-date epoch, `triggerEpochAdvance()`
     *         should be called beforehand by a transaction.
     * @return The current epoch number.
     */
    function getCurrentEpoch() external view returns (uint256) {
        // As a view function, it cannot modify state (call _updateCurrentEpoch).
        // It returns the currentEpoch as it stands in the storage.
        return currentEpoch;
    }
}
```