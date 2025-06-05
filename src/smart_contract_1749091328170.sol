```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ProtonRegistry: Decentralized Skill, Achievement, and Attestation System
 * @author Your Name or Alias
 * @notice This contract implements a system for users to earn skills, unlock achievements,
 *         and attest to claims about other users. It includes concepts like:
 *         - Skill leveling (potentially gated by earned points).
 *         - Achievement claiming based on skill prerequisites.
 *         - User attestations for arbitrary claims, with verification based on distinct attestor count.
 *         - Progression points earned from achievements used for leveling.
 *         - Role-based access for system management (Owner & Managers).
 *         - Pause functionality.
 *
 * @dev This contract is designed to be a complex, interconnected system. It does not rely
 *      on existing ERC standards directly but implements similar concepts from scratch
 *      or in a unique combination. It is not intended for production use without
 *      further audits and gas optimization, particularly concerning state changes
 *      related to attestations and achievement requirements.
 *      The 'distinct attestor count' logic is a simplified implementation requiring careful
 *      consideration for gas costs and potential denial-of-service vectors in a real system.
 *      Initialization pattern is used to allow for potential future upgradeability
 *      via a proxy contract (though the proxy itself is not included here).
 */

// --- Outline & Function Summary ---
/*
1.  **Initialization & Ownership**
    - `initialize(address initialOwner)`: Sets the initial owner and state. Prevents re-initialization.
    - `transferOwnership(address newOwner)`: Transfers contract ownership (only owner).
    - `owner() view`: Gets the current owner.
    - `isOwner() view`: Checks if caller is the owner.

2.  **Manager Roles**
    - `setManager(address manager)`: Grants manager role (only owner).
    - `removeManager(address manager)`: Revokes manager role (only owner).
    - `isManager(address addr) view`: Checks if an address is a manager.

3.  **Pause Functionality**
    - `pauseSystem()`: Pauses user interactions (only owner or manager).
    - `unpauseSystem()`: Unpauses user interactions (only owner or manager).
    - `isPaused() view`: Checks system pause status.

4.  **Skill Registry Management (Owner or Manager)**
    - `addSkillType(string name, string description, uint256 baseLevelUpCost)`: Defines a new skill.
    - `updateSkillType(uint256 skillId, string name, string description, uint256 baseLevelUpCost)`: Modifies an existing skill.
    - `deactivateSkillType(uint256 skillId)`: Marks a skill as inactive.
    - `getSkillDetails(uint256 skillId) view`: Retrieves skill information.
    - `getSkillCount() view`: Gets total number of skills defined.
    - `getSkillLevelCost(uint256 skillId) view`: Gets the cost to level up a skill.

5.  **Achievement Registry Management (Owner or Manager)**
    - `addAchievementType(string name, string description, uint256 requiredSkillId, uint256 requiredSkillLevel, uint256 rewardPoints)`: Defines a new achievement with skill prerequisites and points.
    - `updateAchievementType(uint256 achievementId, string name, string description, uint256 requiredSkillId, uint256 requiredSkillLevel, uint256 rewardPoints)`: Modifies an achievement.
    - `deactivateAchievementType(uint256 achievementId)`: Marks an achievement as inactive.
    - `getAchievementDetails(uint256 achievementId) view`: Retrieves achievement information.
    - `getAchievementCount() view`: Gets total number of achievements defined.

6.  **Attestation Claim Registry Management (Owner or Manager)**
    - `addAttestationClaimType(string name, string description, uint256 validityDays, uint256 minDistinctAttestorsForVerification)`: Defines a type of claim users can attest to, with validity and verification threshold.
    - `updateAttestationClaimType(uint256 claimId, string name, string description, uint256 validityDays, uint256 minDistinctAttestorsForVerification)`: Modifies a claim type.
    - `removeAttestationClaimType(uint256 claimId)`: Removes a claim type.
    - `getAttestationClaimDetails(uint256 claimId) view`: Retrieves claim information.
    - `getAttestationClaimCount() view`: Gets total number of claim types defined.

7.  **User Progression (Users)**
    - `levelUpSkill(uint256 skillId)`: Allows a user to increase their level in a skill, consuming progression points.
    - `claimAchievement(uint256 achievementId)`: Allows a user to claim an achievement if skill prerequisites are met.

8.  **User Attestation (Users)**
    - `attestToUser(address user, uint256 claimId, bytes data)`: Allows a user to make an attestation about another user for a specific claim type.
    - `revokeAttestation(address user, uint256 claimId)`: Allows an attester to revoke their previous attestation.

9.  **User Data & Queries (View Functions)**
    - `getUserSkillLevel(address user, uint256 skillId) view`: Gets a user's current level in a skill.
    - `hasUserUnlockedAchievement(address user, uint256 achievementId) view`: Checks if a user has claimed an achievement.
    - `getUserTotalProgressionPoints(address user) view`: Calculates a user's total progression points from achievements.
    - `canClaimAchievement(address user, uint256 achievementId) view`: Checks if a user meets the skill prerequisites for an achievement.
    - `getAttestation(address attester, address attestedUser, uint256 claimId) view`: Retrieves details of a specific attestation.
    - `getDistinctAttestorCount(address attestedUser, uint256 claimId) view`: Gets the number of unique users who have a valid, active attestation for a claim about a user.
    - `isAttestationClaimVerified(address attestedUser, uint256 claimId) view`: Checks if a claim for a user meets the minimum distinct attestor threshold.
*/

contract ProtonRegistry {

    // --- Custom Errors ---
    error AlreadyInitialized();
    error NotOwner();
    error NotOwnerOrManager();
    error Paused();
    error NotPaused();
    error InvalidSkillId();
    error SkillIsInactive();
    error InvalidAchievementId();
    error AchievementIsInactive();
    error AchievementAlreadyClaimed();
    error AchievementPrerequisitesNotMet();
    error InvalidClaimId();
    error ClaimIsInactive();
    error InsufficientProgressionPoints();
    error CannotAttestToSelf();
    error NoActiveAttestationToRevoke();
    error ManagerRoleAlreadyAssigned(address manager);
    error ManagerRoleNotAssigned(address manager);


    // --- State Variables ---

    // Ownership
    address private _owner;
    bool private _initialized;

    // Role Management
    mapping(address => bool) private _managers;

    // System State
    bool private _paused;

    // Skill Registry
    struct Skill {
        string name;
        string description;
        uint256 baseLevelUpCost; // Cost in Progression Points to level up 1 time
        bool active;
    }
    mapping(uint256 => Skill) private _skills;
    uint256 private _skillCounter; // Starts at 1

    // Achievement Registry
    struct Achievement {
        string name;
        string description;
        uint256 requiredSkillId;
        uint256 requiredSkillLevel;
        uint256 rewardPoints;
        bool active;
    }
    mapping(uint256 => Achievement) private _achievements;
    uint256 private _achievementCounter; // Starts at 1

    // Attestation Claim Registry
    struct AttestationClaim {
        string name;
        string description;
        uint256 validityTimestamp; // Seconds from epoch, when added. Used to calculate validity end.
        uint256 validityDays; // How long the attestation is valid from creation time
        uint256 minDistinctAttestorsForVerification; // Threshold for 'verified' status
        bool active;
    }
    mapping(uint256 => AttestationClaim) private _attestationClaims;
    uint256 private _attestationClaimCounter; // Starts at 1

    // User Data
    // User Skill Levels: user address -> skillId -> level
    mapping(address => mapping(uint256 => uint256)) private _userSkillLevels;
    // User Achievements: user address -> achievementId -> unlocked?
    mapping(address => mapping(uint256 => bool)) private _userAchievements;
    // User Attestations: attester address -> attested user address -> claimId -> attestation data
    struct UserAttestation {
        uint256 timestamp; // When the attestation was made
        bytes data;        // Arbitrary data associated with the claim
    }
     mapping(address => mapping(address => mapping(uint256 => UserAttestation))) private _userAttestations;
    // To count distinct attestors efficiently: attested user -> claimId -> attester address -> has valid attestation?
     mapping(address => mapping(uint256 => mapping(address => bool))) private _hasValidAttestation;
    // attested user -> claimId -> distinct valid attestor count
     mapping(address => mapping(uint256 => uint256)) private _distinctAttestorCounts;


    // --- Events ---
    event Initialized(uint64 version);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event ManagerRoleSet(address indexed manager);
    event ManagerRoleRemoved(address indexed manager);
    event Paused(address account);
    event Unpaused(address account);

    event SkillTypeAdded(uint256 indexed skillId, string name);
    event SkillTypeUpdated(uint256 indexed skillId, string name);
    event SkillTypeDeactivated(uint256 indexed skillId);

    event AchievementTypeAdded(uint256 indexed achievementId, string name);
    event AchievementTypeUpdated(uint256 indexed achievementId, string name);
    event AchievementTypeDeactivated(uint256 indexed achievementId);

    event AttestationClaimTypeAdded(uint256 indexed claimId, string name);
    event AttestationClaimTypeUpdated(uint256 indexed claimId, string name);
    event AttestationClaimTypeRemoved(uint256 indexed claimId); // Removed entirely, not just deactivated

    event SkillLevelledUp(address indexed user, uint256 indexed skillId, uint256 newLevel, uint256 pointsSpent);
    event AchievementClaimed(address indexed user, uint256 indexed achievementId, uint256 rewardPoints);
    event UserAttested(address indexed attester, address indexed attestedUser, uint256 indexed claimId, bytes data);
    event AttestationRevoked(address indexed attester, address indexed attestedUser, uint256 indexed claimId);


    // --- Modifiers ---
    modifier onlyOwner() {
        if (msg.sender != _owner) {
            revert NotOwner();
        }
        _;
    }

    modifier onlyOwnerOrManager() {
        if (msg.sender != _owner && !_managers[msg.sender]) {
            revert NotOwnerOrManager();
        }
        _;
    }

    modifier whenNotPaused() {
        if (_paused) {
            revert Paused();
        }
        _;
    }

     modifier whenPaused() {
        if (!_paused) {
            revert NotPaused();
        }
        _;
    }

    // --- Initialization & Ownership ---

    /**
     * @notice Initializes the contract, setting the initial owner.
     * @param initialOwner The address to set as the contract owner.
     */
    function initialize(address initialOwner) external {
        if (_initialized) revert AlreadyInitialized();
        _owner = initialOwner;
        _initialized = true;
        _skillCounter = 0; // Counters start from 1, but map keys start from 1
        _achievementCounter = 0;
        _attestationClaimCounter = 0;
        emit OwnershipTransferred(address(0), initialOwner);
        emit Initialized(1); // Simple versioning
    }

    /**
     * @notice Transfers ownership of the contract to a new account.
     * @param newOwner The address of the new owner.
     */
    function transferOwnership(address newOwner) external onlyOwner {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @notice Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @notice Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }


    // --- Manager Roles ---

    /**
     * @notice Grants manager role to an address. Managers can perform certain admin actions.
     * @param manager The address to grant the manager role to.
     */
    function setManager(address manager) external onlyOwner {
        if (_managers[manager]) revert ManagerRoleAlreadyAssigned(manager);
        _managers[manager] = true;
        emit ManagerRoleSet(manager);
    }

    /**
     * @notice Revokes manager role from an address.
     * @param manager The address to revoke the manager role from.
     */
    function removeManager(address manager) external onlyOwner {
        if (!_managers[manager]) revert ManagerRoleNotAssigned(manager);
        _managers[manager] = false;
        emit ManagerRoleRemoved(manager);
    }

    /**
     * @notice Checks if an address has the manager role.
     */
    function isManager(address addr) public view returns (bool) {
        return _managers[addr];
    }

    // --- Pause Functionality ---

    /**
     * @notice Pauses the contract, preventing user interactions (skill leveling, achievement claiming, attesting).
     */
    function pauseSystem() external onlyOwnerOrManager whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @notice Unpauses the contract, allowing user interactions again.
     */
    function unpauseSystem() external onlyOwnerOrManager whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }

    /**
     * @notice Returns true if the contract is paused.
     */
    function isPaused() public view returns (bool) {
        return _paused;
    }

    // --- Skill Registry Management ---

    /**
     * @notice Adds a new skill type to the registry.
     * @param name The name of the skill.
     * @param description The description of the skill.
     * @param baseLevelUpCost The base number of progression points required to level up this skill once.
     * @return The ID of the newly added skill.
     */
    function addSkillType(string calldata name, string calldata description, uint256 baseLevelUpCost)
        external onlyOwnerOrManager returns (uint256)
    {
        _skillCounter++;
        _skills[_skillCounter] = Skill(name, description, baseLevelUpCost, true);
        emit SkillTypeAdded(_skillCounter, name);
        return _skillCounter;
    }

    /**
     * @notice Updates an existing skill type.
     * @param skillId The ID of the skill to update.
     * @param name The new name of the skill.
     * @param description The new description of the skill.
     * @param baseLevelUpCost The new base level up cost.
     */
    function updateSkillType(uint256 skillId, string calldata name, string calldata description, uint256 baseLevelUpCost)
        external onlyOwnerOrManager
    {
        if (skillId == 0 || skillId > _skillCounter || !_skills[skillId].active) revert InvalidSkillId();
        _skills[skillId].name = name;
        _skills[skillId].description = description;
        _skills[skillId].baseLevelUpCost = baseLevelUpCost;
        emit SkillTypeUpdated(skillId, name);
    }

    /**
     * @notice Deactivates a skill type, preventing further leveling or use in new achievement prerequisites.
     * @param skillId The ID of the skill to deactivate.
     */
    function deactivateSkillType(uint256 skillId) external onlyOwnerOrManager {
        if (skillId == 0 || skillId > _skillCounter || !_skills[skillId].active) revert InvalidSkillId();
        _skills[skillId].active = false;
        emit SkillTypeDeactivated(skillId);
    }

    /**
     * @notice Retrieves details of a specific skill type.
     * @param skillId The ID of the skill.
     * @return tuple containing skill details.
     */
    function getSkillDetails(uint256 skillId)
        public view returns (string memory name, string memory description, uint256 baseLevelUpCost, bool active)
    {
        if (skillId == 0 || skillId > _skillCounter) revert InvalidSkillId(); // Allow viewing inactive
        Skill storage skill = _skills[skillId];
        return (skill.name, skill.description, skill.baseLevelUpCost, skill.active);
    }

    /**
     * @notice Returns the total number of skill types registered.
     */
    function getSkillCount() public view returns (uint256) {
        return _skillCounter;
    }

    /**
     * @notice Gets the progression point cost to level up a specific skill *once*.
     * @dev Note: This is the *base* cost. Future versions could make cost scale with current level.
     * @param skillId The ID of the skill.
     * @return The progression point cost.
     */
    function getSkillLevelCost(uint256 skillId) public view returns (uint256) {
         if (skillId == 0 || skillId > _skillCounter || !_skills[skillId].active) revert InvalidSkillId();
         return _skills[skillId].baseLevelUpCost;
    }


    // --- Achievement Registry Management ---

    /**
     * @notice Adds a new achievement type to the registry.
     * @param name The name of the achievement.
     * @param description The description.
     * @param requiredSkillId The ID of the skill required (0 for no skill requirement).
     * @param requiredSkillLevel The minimum level required in the prerequisite skill.
     * @param rewardPoints The number of progression points awarded upon claiming.
     * @return The ID of the newly added achievement.
     */
    function addAchievementType(
        string calldata name,
        string calldata description,
        uint256 requiredSkillId,
        uint256 requiredSkillLevel,
        uint256 rewardPoints
    ) external onlyOwnerOrManager returns (uint256) {
        if (requiredSkillId != 0 && (requiredSkillId > _skillCounter || !_skills[requiredSkillId].active)) revert InvalidSkillId();
        _achievementCounter++;
        _achievements[_achievementCounter] = Achievement(
            name,
            description,
            requiredSkillId,
            requiredSkillLevel,
            rewardPoints,
            true
        );
        emit AchievementTypeAdded(_achievementCounter, name);
        return _achievementCounter;
    }

     /**
     * @notice Updates an existing achievement type.
     * @param achievementId The ID of the achievement to update.
     * @param name The new name.
     * @param description The new description.
     * @param requiredSkillId The new required skill ID.
     * @param requiredSkillLevel The new required skill level.
     * @param rewardPoints The new reward points.
     */
    function updateAchievementType(
        uint256 achievementId,
        string calldata name,
        string calldata description,
        uint256 requiredSkillId,
        uint256 requiredSkillLevel,
        uint256 rewardPoints
    ) external onlyOwnerOrManager {
        if (achievementId == 0 || achievementId > _achievementCounter || !_achievements[achievementId].active) revert InvalidAchievementId();
        if (requiredSkillId != 0 && (requiredSkillId > _skillCounter || !_skills[requiredSkillId].active)) revert InvalidSkillId();

        Achievement storage achievement = _achievements[achievementId];
        achievement.name = name;
        achievement.description = description;
        achievement.requiredSkillId = requiredSkillId;
        achievement.requiredSkillLevel = requiredSkillLevel;
        achievement.rewardPoints = rewardPoints;
        emit AchievementTypeUpdated(achievementId, name);
    }

    /**
     * @notice Deactivates an achievement type, preventing further claims.
     * @param achievementId The ID of the achievement to deactivate.
     */
    function deactivateAchievementType(uint256 achievementId) external onlyOwnerOrManager {
        if (achievementId == 0 || achievementId > _achievementCounter || !_achievements[achievementId].active) revert InvalidAchievementId();
        _achievements[achievementId].active = false;
        emit AchievementTypeDeactivated(achievementId);
    }

    /**
     * @notice Retrieves details of a specific achievement type.
     * @param achievementId The ID of the achievement.
     * @return tuple containing achievement details.
     */
    function getAchievementDetails(uint256 achievementId)
        public view returns (string memory name, string memory description, uint256 requiredSkillId, uint256 requiredSkillLevel, uint256 rewardPoints, bool active)
    {
        if (achievementId == 0 || achievementId > _achievementCounter) revert InvalidAchievementId(); // Allow viewing inactive
        Achievement storage achievement = _achievements[achievementId];
        return (
            achievement.name,
            achievement.description,
            achievement.requiredSkillId,
            achievement.requiredSkillLevel,
            achievement.rewardPoints,
            achievement.active
        );
    }

    /**
     * @notice Returns the total number of achievement types registered.
     */
    function getAchievementCount() public view returns (uint256) {
        return _achievementCounter;
    }

    // --- Attestation Claim Registry Management ---

    /**
     * @notice Adds a new attestation claim type to the registry.
     * @param name The name of the claim (e.g., "Trustworthiness").
     * @param description The description of the claim.
     * @param validityDays The number of days an attestation is valid from its creation time.
     * @param minDistinctAttestorsForVerification The minimum number of distinct, valid attestations needed for this claim to be considered "verified" for a user.
     * @return The ID of the newly added claim type.
     */
    function addAttestationClaimType(string calldata name, string calldata description, uint256 validityDays, uint256 minDistinctAttestorsForVerification)
        external onlyOwnerOrManager returns (uint256)
    {
        _attestationClaimCounter++;
        _attestationClaims[_attestationClaimCounter] = AttestationClaim(
            name,
            description,
            block.timestamp, // Store creation timestamp to calculate validity end relative to definition time
            validityDays,
            minDistinctAttestorsForVerification,
            true
        );
        emit AttestationClaimTypeAdded(_attestationClaimCounter, name);
        return _attestationClaimCounter;
    }

    /**
     * @notice Updates an existing attestation claim type.
     * @param claimId The ID of the claim to update.
     * @param name The new name.
     * @param description The new description.
     * @param validityDays The new validity in days.
     * @param minDistinctAttestorsForVerification The new verification threshold.
     */
    function updateAttestationClaimType(uint256 claimId, string calldata name, string calldata description, uint256 validityDays, uint256 minDistinctAttestorsForVerification)
        external onlyOwnerOrManager
    {
        if (claimId == 0 || claimId > _attestationClaimCounter || !_attestationClaims[claimId].active) revert InvalidClaimId();
        AttestationClaim storage claim = _attestationClaims[claimId];
        claim.name = name;
        claim.description = description;
        // Note: validityTimestamp remains the creation time of the CLAIM TYPE, not individual attestations.
        // Attestation validity is calculated based on claim.validityDays + individual attestation timestamp.
        claim.validityDays = validityDays;
        claim.minDistinctAttestorsForVerification = minDistinctAttestorsForVerification;
        emit AttestationClaimTypeUpdated(claimId, name);
    }

    /**
     * @notice Removes an attestation claim type entirely. This should be used cautiously as it affects existing attestations.
     * @param claimId The ID of the claim type to remove.
     */
     function removeAttestationClaimType(uint256 claimId) external onlyOwnerOrManager {
        // Note: Does NOT clean up existing attestations using this claim ID to save gas.
        // Query functions need to check if the claimId exists via getAttestationClaimDetails.
        if (claimId == 0 || claimId > _attestationClaimCounter) revert InvalidClaimId();
        // We don't explicitly delete from the mapping, just mark inactive/non-existent logic
        // For simplicity here, we'll just mark inactive as 'removed'. A true 'remove' might
        // require more complex state cleanup or different mapping structure.
        _attestationClaims[claimId].active = false; // Mark as removed effectively
        // If we wanted true removal and state cleanup, it would be gas prohibitive.
        // For this example, marking inactive is sufficient to prevent new use.
        emit AttestationClaimTypeRemoved(claimId);
    }


    /**
     * @notice Retrieves details of a specific attestation claim type.
     * @param claimId The ID of the claim type.
     * @return tuple containing claim details.
     */
    function getAttestationClaimDetails(uint256 claimId)
        public view returns (string memory name, string memory description, uint256 validityDays, uint256 minDistinctAttestorsForVerification, bool active)
    {
        if (claimId == 0 || claimId > _attestationClaimCounter) revert InvalidClaimId(); // Allow viewing inactive
         AttestationClaim storage claim = _attestationClaims[claimId];
        return (
            claim.name,
            claim.description,
            claim.validityDays,
            claim.minDistinctAttestorsForVerification,
            claim.active
        );
    }

    /**
     * @notice Returns the total number of attestation claim types registered.
     */
    function getAttestationClaimCount() public view returns (uint256) {
        return _attestationClaimCounter;
    }


    // --- User Progression ---

    /**
     * @notice Allows a user to level up a specific skill, consuming progression points.
     * @param skillId The ID of the skill to level up.
     */
    function levelUpSkill(uint256 skillId) external whenNotPaused {
        if (skillId == 0 || skillId > _skillCounter || !_skills[skillId].active) revert InvalidSkillId();

        uint256 currentLevel = _userSkillLevels[msg.sender][skillId];
        uint256 cost = _skills[skillId].baseLevelUpCost; // Simple cost model

        uint256 totalProgressionPoints = getUserTotalProgressionPoints(msg.sender);
        if (totalProgressionPoints < cost) {
            revert InsufficientProgressionPoints();
        }

        // Simple burn mechanism: deduct points. Note: This doesn't require tracking spent points,
        // as total points are calculated from achievements. Deducting from a 'total' isn't
        // how this model works. Instead, we need a mechanism to track *used* points.
        // Let's add a mapping for used points.
         mapping(address => uint256) private _userUsedProgressionPoints;

        uint256 availablePoints = totalProgressionPoints - _userUsedProgressionPoints[msg.sender];
        if (availablePoints < cost) {
             revert InsufficientProgressionPoints();
        }

        _userSkillLevels[msg.sender][skillId] = currentLevel + 1;
        _userUsedProgressionPoints[msg.sender] += cost;

        emit SkillLevelledUp(msg.sender, skillId, currentLevel + 1, cost);
    }

    /**
     * @notice Allows a user to claim an achievement if they meet the skill prerequisites.
     * @param achievementId The ID of the achievement to claim.
     */
    function claimAchievement(uint256 achievementId) external whenNotPaused {
        if (achievementId == 0 || achievementId > _achievementCounter || !_achievements[achievementId].active) revert InvalidAchievementId();
        if (_userAchievements[msg.sender][achievementId]) revert AchievementAlreadyClaimed();

        Achievement storage achievement = _achievements[achievementId];

        if (achievement.requiredSkillId != 0) {
            if (_userSkillLevels[msg.sender][achievement.requiredSkillId] < achievement.requiredSkillLevel) {
                revert AchievementPrerequisitesNotMet();
            }
        }

        _userAchievements[msg.sender][achievementId] = true;
        // Progression points are NOT added here directly. They are calculated on the fly by
        // summing rewardPoints of UNLOCKED achievements in getUserTotalProgressionPoints.
        // This is simpler than managing an explicit point balance.

        emit AchievementClaimed(msg.sender, achievementId, achievement.rewardPoints);
    }

    // --- User Attestation ---

    /**
     * @notice Allows a user to attest to a claim about another user. Overwrites previous attestation by the same attester for the same claim.
     * @param user The address of the user being attested to.
     * @param claimId The ID of the attestation claim type.
     * @param data Arbitrary bytes data associated with the claim (e.g., a rating, a specific detail).
     */
    function attestToUser(address user, uint256 claimId, bytes calldata data) external whenNotPaused {
        if (user == msg.sender) revert CannotAttestToSelf();
        if (claimId == 0 || claimId > _attestationClaimCounter || !_attestationClaims[claimId].active) revert InvalidClaimId();

        // Check if this attester already had a valid attestation for this user/claim
        bool hadValidAttestation = _hasValidAttestation[user][claimId][msg.sender];

        // Store or update the attestation
        _userAttestations[msg.sender][user][claimId] = UserAttestation(block.timestamp, data);

        // Update distinct attestor count if this is a *new* distinct valid attestation
        // Validity check is done during query time, but for the *count*, we assume a new
        // attestation by a distinct user makes them a 'valid' distinct attestor *at this moment*.
        // Revocation or time decay will invalidate them later.
        if (!hadValidAttestation) {
             _hasValidAttestation[user][claimId][msg.sender] = true;
            _distinctAttestorCounts[user][claimId]++;
        }
        // Note: if they already had an attestation but it expired, this doesn't decrement then increment.
        // The distinct count logic here is simplified and counts unique *addresses that have ever attested*
        // and not yet revoked, rather than unique *currently valid* attestations.
        // A more robust system would recalculate based on validity or use a Merkle tree/state accumulation.
        // For this example, it counts distinct users who made the *most recent* attestation within validity.

        emit UserAttested(msg.sender, user, claimId, data);
    }

    /**
     * @notice Allows an attester to revoke their attestation about another user for a specific claim.
     * @param user The address of the user the attestation was about.
     * @param claimId The ID of the attestation claim type.
     */
    function revokeAttestation(address user, uint256 claimId) external whenNotPaused {
        if (user == msg.sender) revert CannotAttestToSelf(); // Cannot revoke self-attestation if it were possible
        if (claimId == 0 || claimId > _attestationClaimCounter) revert InvalidClaimId(); // Allow revoking for inactive claim IDs

        // Check if there was an attestation by this sender for this user/claim
        UserAttestation storage attestation = _userAttestations[msg.sender][user][claimId];
        if (attestation.timestamp == 0) {
             revert NoActiveAttestationToRevoke(); // No attestation exists
        }

        // Clear the attestation data
        delete _userAttestations[msg.sender][user][claimId];

        // Decrement distinct attestor count if they had a valid attestation at time of attestation/last check
        // This simple model decrements if they *ever* had one recorded in _hasValidAttestation.
        if (_hasValidAttestation[user][claimId][msg.sender]) {
            _hasValidAttestation[user][claimId][msg.sender] = false;
            // Prevent underflow, although with correct logic this shouldn't happen if starting > 0
            if (_distinctAttestorCounts[user][claimId] > 0) {
                _distinctAttestorCounts[user][claimId]--;
            }
        }

        emit AttestationRevoked(msg.sender, user, claimId);
    }


    // --- User Data & Queries ---

    /**
     * @notice Gets a user's current level in a specific skill. Returns 0 if skill not found or user has no level.
     * @param user The address of the user.
     * @param skillId The ID of the skill.
     * @return The user's skill level.
     */
    function getUserSkillLevel(address user, uint256 skillId) public view returns (uint256) {
        // No revert for invalid skillId here, just returns 0
        if (skillId == 0 || skillId > _skillCounter) return 0;
        return _userSkillLevels[user][skillId];
    }

    /**
     * @notice Checks if a user has unlocked a specific achievement.
     * @param user The address of the user.
     * @param achievementId The ID of the achievement.
     * @return True if the user has unlocked the achievement, false otherwise.
     */
    function hasUserUnlockedAchievement(address user, uint256 achievementId) public view returns (bool) {
         // No revert for invalid achievementId, just returns false
        if (achievementId == 0 || achievementId > _achievementCounter) return false;
        return _userAchievements[user][achievementId];
    }

    /**
     * @notice Calculates a user's total progression points earned from all claimed achievements.
     * @param user The address of the user.
     * @return The total progression points.
     */
    function getUserTotalProgressionPoints(address user) public view returns (uint256) {
        uint256 totalPoints = 0;
        // Iterate through all defined achievements (inefficient for many achievements)
        // A better design would track total points separately or use a more complex state.
        // This is a simplified example for demonstration.
        for (uint256 i = 1; i <= _achievementCounter; i++) {
            if (_achievements[i].active && _userAchievements[user][i]) {
                totalPoints += _achievements[i].rewardPoints;
            }
        }
        // Subtract points spent on leveling skills
        return totalPoints - _userUsedProgressionPoints[user];
    }

    /**
     * @notice Checks if a user meets the prerequisites to claim a specific achievement.
     * @param user The address of the user.
     * @param achievementId The ID of the achievement.
     * @return True if prerequisites are met, false otherwise.
     */
    function canClaimAchievement(address user, uint256 achievementId) public view returns (bool) {
        if (achievementId == 0 || achievementId > _achievementCounter || !_achievements[achievementId].active) return false;

        Achievement storage achievement = _achievements[achievementId];

        // Already claimed? Can't claim again.
        if (_userAchievements[user][achievementId]) return false;

        // Check skill prerequisite
        if (achievement.requiredSkillId != 0) {
            if (achievement.requiredSkillId > _skillCounter || !_skills[achievement.requiredSkillId].active) return false; // Required skill must exist and be active

            if (_userSkillLevels[user][achievement.requiredSkillId] < achievement.requiredSkillLevel) {
                return false; // Skill level insufficient
            }
        }

        return true; // All checks passed
    }

    /**
     * @notice Retrieves details of a specific attestation made by one user about another for a claim.
     * @param attester The address who made the attestation.
     * @param attestedUser The address the attestation is about.
     * @param claimId The ID of the claim type.
     * @return timestamp The timestamp the attestation was made (0 if none exists).
     * @return data The arbitrary bytes data associated with the attestation.
     */
    function getAttestation(address attester, address attestedUser, uint256 claimId)
        public view returns (uint256 timestamp, bytes memory data)
    {
        if (claimId == 0 || claimId > _attestationClaimCounter) return (0, bytes("")); // Invalid claim ID

        UserAttestation storage attestation = _userAttestations[attester][attestedUser][claimId];

        // Check validity based on claim type duration and attestation timestamp
        AttestationClaim storage claim = _attestationClaims[claimId];
        uint256 validityDuration = claim.validityDays * 1 days;

        // An attestation with timestamp 0 means it doesn't exist or was revoked.
        // Also check if it has expired.
        bool isValid = attestation.timestamp > 0 && (validityDuration == 0 || attestation.timestamp + validityDuration >= block.timestamp);

        if (!isValid) {
             return (0, bytes("")); // Return empty/zero if no valid attestation found
        }

        return (attestation.timestamp, attestation.data);
    }

     /**
     * @notice Gets the raw timestamp of an attestation, regardless of validity. Useful for checking existence.
     * @param attester The address who made the attestation.
     * @param attestedUser The address the attestation is about.
     * @param claimId The ID of the claim type.
     * @return The timestamp the attestation was made (0 if none exists).
     */
    function getAttestationTimestamp(address attester, address attestedUser, uint256 claimId)
        public view returns (uint256)
    {
        // Doesn't check claim validity, just raw storage
         if (claimId == 0 || claimId > _attestationClaimCounter) return 0;
        return _userAttestations[attester][attestedUser][claimId].timestamp;
    }

     /**
     * @notice Gets the raw data of an attestation, regardless of validity. Useful for checking existence.
     * @param attester The address who made the attestation.
     * @param attestedUser The address the attestation is about.
     * @param claimId The ID of the claim type.
     * @return The arbitrary bytes data associated with the attestation (empty bytes if none exists).
     */
    function getAttestationData(address attester, address attestedUser, uint256 claimId)
        public view returns (bytes memory)
    {
        // Doesn't check claim validity, just raw storage
         if (claimId == 0 || claimId > _attestationClaimCounter) return bytes("");
        return _userAttestations[attester][attestedUser][claimId].data;
    }

    /**
     * @notice Gets the count of distinct users who have a *currently valid* attestation for a claim about a user.
     * @dev This implementation relies on `_distinctAttestorCounts` which is updated on attest/revoke.
     *      It does NOT re-evaluate validity *on query*. A more robust system would do this or use state accumulation.
     * @param attestedUser The address the attestation is about.
     * @param claimId The ID of the claim type.
     * @return The count of distinct valid attestors.
     */
    function getDistinctAttestorCount(address attestedUser, uint256 claimId) public view returns (uint256) {
        if (claimId == 0 || claimId > _attestationClaimCounter || !_attestationClaims[claimId].active) return 0;
        // Note: This returns the count based on the simplified _distinctAttestorCounts state variable,
        // which might not precisely reflect *currently valid* attestations if validity is dynamic
        // and not checked on attestation/revocation events themselves in the current simplified model.
        // A more complex system would need to re-evaluate validity for each potential attestor.
        return _distinctAttestorCounts[attestedUser][claimId];
    }


     /**
     * @notice Checks if a claim for a user is considered "verified" based on the distinct attestor count threshold.
     * @param attestedUser The address the claim is about.
     * @param claimId The ID of the claim type.
     * @return True if the claim is verified, false otherwise.
     */
    function isAttestationClaimVerified(address attestedUser, uint256 claimId) public view returns (bool) {
        if (claimId == 0 || claimId > _attestationClaimCounter || !_attestationClaims[claimId].active) return false;

        AttestationClaim storage claim = _attestationClaims[claimId];
        uint256 distinctCount = getDistinctAttestorCount(attestedUser, claimId); // Uses the potentially simplified count

        return distinctCount >= claim.minDistinctAttestorsForVerification;
    }
}
```