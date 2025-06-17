Okay, here is a Solidity smart contract for a "Soulbound Skill Tree".

**Concept:**
This contract implements a non-transferable token system representing skills, knowledge, or achievements tied to a specific wallet address (Soulbound Tokens concept). Skills are organized in a tree structure, where unlocking higher-level skills requires having specific prerequisites. Users can earn skills through direct issuance (e.g., by a governing body, completing a task recorded off-chain) or by spending accumulated "Experience Points" (XP) on skills they qualify for based on prerequisites. The system includes governance features for defining skills and distributing XP, and provides various query functions to explore the skill tree and user achievements. It implements ERC-721-like view functions for metadata compatibility, but strictly disallows transfers.

**Advanced Concepts Used:**
1.  **Soulbound Tokens (SBTs):** Non-transferable tokens representing identity/reputation.
2.  **Hierarchical Data (Skill Tree):** Skills with defined prerequisites creating dependencies. Cycle detection for prerequisite definition.
3.  **Dual Issuance Mechanism:** Skills can be issued directly by authority OR unlocked by users spending accumulated XP.
4.  **Experience Points (XP):** An internal token/score system managed within the contract.
5.  **Basic Governance/Authorization:** Distinguishing between owner/deployer and a designated governance address for key actions.
6.  **ERC-721 Compatibility (View Functions):** Implementing `tokenURI`, `ownerOf` (as `getTokenHolder`) for view purposes despite non-transferability. Token IDs represent unique instances of skills held by specific users.
7.  **Atomic Operations:** `attemptUnlockSkillWithXP` combines prerequisite checks, XP deduction, skill issuance, and state updates in one transaction.
8.  **Batch Operations:** Functions for issuing skills or distributing XP to multiple recipients or issuing multiple skills.
9.  **Revocation Mechanism:** Allowing authorized parties to revoke skills (with a reason), acknowledging potential real-world needs for correction in reputation systems (though controversial for true soulbound).

**Outline:**

1.  **State Variables:** Storage for skill definitions, user skills, user XP, token ID mappings, counters, governance addresses.
2.  **Structs:** `Skill` structure.
3.  **Events:** Notifications for state changes (Skill definition, issuance, XP, etc.).
4.  **Modifiers:** Access control (`onlyOwner`, `onlyGovernanceOrOwner`, `onlyXPAuthority`, `whenSkillExists`).
5.  **Internal Helpers:**
    *   `_checkPrerequisites`: Verifies if user has necessary skills.
    *   `_isPrerequisiteOfAnyExistingSkill`: Checks if a skill is required by another defined skill.
    *   `_checkPrerequisiteCycles`: Prevents circular dependencies in skill definitions.
    *   `_issueSkillInternal`: Core logic for assigning a skill and managing token IDs.
    *   `_revokeSkillInternal`: Core logic for removing a skill and managing token IDs.
6.  **Owner/Governance Functions:**
    *   Contract administration (`constructor`, `transferOwnership`, `setGovernanceAddress`, `setBaseMetadataURI`, `pauseXPDistribution`, `unpauseXPDistribution`).
    *   Skill definition management (`addSkillDefinition`, `updateSkillDefinition`, `removeSkillDefinition`).
    *   Direct Issuance (`issueSkillTo`, `batchIssueSkillsTo`, `issueSkillBatch`).
    *   XP Management (`distributeXP`, `batchDistributeXP`).
    *   Revocation (`revokeSkillFrom`).
7.  **User Functions:**
    *   XP-based Unlock (`attemptUnlockSkillWithXP`).
    *   XP Burning (`burnXP`).
8.  **View Functions:**
    *   Skill data (`getSkillDefinition`, `getSkillPrerequisites`, `getAllSkillDefinitions`, `getSkillCount`).
    *   User data (`hasSkill`, `getUserSkills`, `getUserXP`, `canUnlockSkill`).
    *   Statistics (`getSkillHolderCount`).
    *   ERC-721-like Views (`getTokenURI`, `getSkillTokenId`, `getUserSkillTokenIds`, `getSkillDefinitionByTokenId`, `getTokenHolder`).

**Function Summary (Total: 30+ functions):**

*   `constructor()`: Deploys the contract, sets initial owner.
*   `transferOwnership(address newOwner)`: Transfers contract ownership. (Ownable standard)
*   `setGovernanceAddress(address _governance)`: Sets the address authorized for governance actions.
*   `pauseXPDistribution()`: Pauses XP distribution (by owner/governance).
*   `unpauseXPDistribution()`: Unpauses XP distribution (by owner/governance).
*   `addSkillDefinition(uint256 skillId, string memory name, string memory description, uint256[] memory prerequisites, uint256 xpCost)`: Adds a new skill type.
*   `updateSkillDefinition(uint256 skillId, string memory name, string memory description, uint256[] memory prerequisites, uint256 xpCost)`: Updates an existing skill type.
*   `removeSkillDefinition(uint256 skillId)`: Removes a skill type (only if no one holds it and it's not a prerequisite).
*   `setBaseMetadataURI(string memory baseURI)`: Sets the base URI for skill metadata.
*   `issueSkillTo(address recipient, uint256 skillId)`: Issues a specific skill to a user (requires prerequisites). (Auth only)
*   `batchIssueSkillsTo(address recipient, uint256[] memory skillIds)`: Issues multiple skills to one user. (Auth only)
*   `issueSkillBatch(address[] memory recipients, uint256 skillId)`: Issues one skill to multiple users. (Auth only)
*   `revokeSkillFrom(address holder, uint256 skillId, string memory reason)`: Revokes a skill from a user. (Auth only)
*   `distributeXP(address recipient, uint256 amount)`: Awards XP to a user. (Auth only)
*   `batchDistributeXP(address[] memory recipients, uint256[] memory amounts)`: Awards XP to multiple users. (Auth only)
*   `attemptUnlockSkillWithXP(uint256 skillId)`: User attempts to unlock a skill using their XP. (User callable)
*   `burnXP(uint256 amount)`: Allows a user to burn their own XP. (User callable)
*   `getSkillDefinition(uint256 skillId)`: Get details of a skill definition. (View)
*   `getSkillPrerequisites(uint256 skillId)`: Get prerequisite skill IDs for a skill. (View)
*   `hasSkill(address user, uint256 skillId)`: Checks if a user has a specific skill. (View)
*   `getUserSkills(address user)`: Gets all skill IDs held by a user. (View)
*   `getUserXP(address user)`: Gets the XP balance of a user. (View)
*   `canUnlockSkill(address user, uint256 skillId)`: Checks if a user meets prerequisites and has enough XP for a skill. (View)
*   `getAllSkillDefinitions()`: Gets a list of all defined skill IDs. (View)
*   `getSkillCount()`: Gets the total number of defined skills. (View)
*   `getSkillHolderCount(uint256 skillId)`: Gets the number of users who hold a specific skill. (View)
*   `getTokenURI(uint256 tokenId)`: Gets metadata URI for a specific issued skill instance (ERC721-like). (View)
*   `getSkillTokenId(address user, uint256 skillId)`: Gets the specific `tokenId` for a user's instance of a skill. (View)
*   `getUserSkillTokenIds(address user)`: Gets all `tokenId`s held by a user. (View)
*   `getSkillDefinitionByTokenId(uint256 tokenId)`: Gets the skill definition details for a given `tokenId`. (View)
*   `getTokenHolder(uint256 tokenId)`: Gets the address holding a specific `tokenId` (ERC721-like `ownerOf`). (View)

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/// @title SoulboundSkillTree
/// @author YourNameHere (Inspired by Vitalik's SBT concept and gaming skill trees)
/// @custom:version 1.0.0
/// @notice Implements a soulbound token system for tracking user skills and achievements in a hierarchical tree structure.
/// Skills can be issued directly by authority or unlocked by users spending accumulated XP.
/// ERC-721-like view functions are included for compatibility, but tokens are strictly non-transferable.
///
/// Outline:
/// 1. State Variables & Structs
/// 2. Events
/// 3. Modifiers
/// 4. Internal Helper Functions
///    - Prerequisite checks and cycle detection
///    - Internal issue/revoke logic
/// 5. Owner/Governance Functions
///    - Admin (Ownership, Governance Address, Pause)
///    - Skill Definition Management (Add, Update, Remove)
///    - Direct Issuance (Single, Batch)
///    - XP Management (Distribute, Batch)
///    - Revocation
/// 6. User Functions
///    - XP-based Unlock
///    - XP Burning
/// 7. View Functions
///    - Skill Data
///    - User Data
///    - Statistics
///    - ERC-721-like Views (Metadata, Ownership lookup)
///
/// Function Summary (Approx 30+ functions):
/// - constructor()
/// - transferOwnership(address newOwner)
/// - setGovernanceAddress(address _governance)
/// - pauseXPDistribution()
/// - unpauseXPDistribution()
/// - addSkillDefinition(...)
/// - updateSkillDefinition(...)
/// - removeSkillDefinition(...)
/// - setBaseMetadataURI(string memory baseURI)
/// - issueSkillTo(address recipient, uint256 skillId)
/// - batchIssueSkillsTo(address recipient, uint256[] memory skillIds)
/// - issueSkillBatch(address[] memory recipients, uint256 skillId)
/// - revokeSkillFrom(address holder, uint256 skillId, string memory reason)
/// - distributeXP(address recipient, uint256 amount)
/// - batchDistributeXP(address[] memory recipients, uint256[] memory amounts)
/// - attemptUnlockSkillWithXP(uint256 skillId)
/// - burnXP(uint256 amount)
/// - getSkillDefinition(uint256 skillId)
/// - getSkillPrerequisites(uint256 skillId)
/// - hasSkill(address user, uint256 skillId)
/// - getUserSkills(address user)
/// - getUserXP(address user)
/// - canUnlockSkill(address user, uint256 skillId)
/// - getAllSkillDefinitions()
/// - getSkillCount()
/// - getSkillHolderCount(uint256 skillId)
/// - getTokenURI(uint256 tokenId)
/// - getSkillTokenId(address user, uint256 skillId)
/// - getUserSkillTokenIds(address user)
/// - getSkillDefinitionByTokenId(uint256 tokenId)
/// - getTokenHolder(uint256 tokenId)

contract SoulboundSkillTree is Ownable {
    using Strings for uint256;

    // --- State Variables ---

    /// @dev Represents a type of skill that can be earned.
    struct Skill {
        string name;
        string description;
        uint256[] prerequisites; // List of skillIds required before this skill can be earned
        uint256 xpCost; // XP required to unlock this skill if not directly issued
        bool isDefined; // Flag to check if skillId corresponds to a defined skill
    }

    // Mapping from skill ID to its definition
    mapping(uint256 => Skill) private s_skillDefinitions;

    // Mapping from user address to their acquired skill IDs
    mapping(address => mapping(uint256 => bool)) private s_userSkills;
    mapping(address => uint256[]) private s_userSkillList; // To easily list skills for a user

    // Mapping from user address to their experience points (XP) balance
    mapping(address => uint256) private s_userXP;

    // A list of all defined skill IDs
    uint256[] private s_definedSkillIds;
    // Mapping to quickly check if a skillId exists in s_definedSkillIds
    mapping(uint256 => bool) private s_isSkillDefined;

    // ERC-721-like tokenId tracking for individual skill instances held by users
    uint256 private s_nextTokenId;
    mapping(uint256 => address) private s_tokenIdToHolder; // tokenId -> holder address
    mapping(uint256 => uint256) private s_tokenIdToSkillId; // tokenId -> skillId
    mapping(address => mapping(uint256 => uint256)) private s_holderSkillToTokenId; // (holder, skillId) -> tokenId

    string private s_baseMetadataURI;
    address private s_governance;
    bool private s_xpDistributionPaused = false;

    // --- Events ---

    /// @dev Emitted when a new skill definition is added.
    event SkillDefinitionAdded(uint256 indexed skillId, string name, uint256 xpCost);

    /// @dev Emitted when a skill definition is updated.
    event SkillDefinitionUpdated(uint256 indexed skillId, string name, uint256 xpCost);

    /// @dev Emitted when a skill definition is removed.
    event SkillDefinitionRemoved(uint256 indexed skillId);

    /// @dev Emitted when a skill is issued to a user.
    event SkillIssued(uint256 indexed tokenId, address indexed holder, uint256 indexed skillId, address issuer);

    /// @dev Emitted when a skill is revoked from a user.
    event SkillRevoked(uint256 indexed tokenId, address indexed holder, uint256 indexed skillId, address revoker, string reason);

    /// @dev Emitted when a user unlocks a skill using XP.
    event SkillUnlocked(uint256 indexed tokenId, address indexed holder, uint256 indexed skillId, uint256 xpSpent);

    /// @dev Emitted when XP is distributed to a user.
    event XPSent(address indexed recipient, uint256 amount, address distributor);

    /// @dev Emitted when a user burns XP.
    event XPBurned(address indexed burner, uint256 amount);

    /// @dev Emitted when governance address is set.
    event GovernanceAddressSet(address indexed oldGovernance, address indexed newGovernance);

    /// @dev Emitted when XP distribution is paused.
    event XPDistributionPaused(address indexed pauser);

    /// @dev Emitted when XP distribution is unpaused.
    event XPDistributionUnpaused(address indexed unpauser);

    // --- Modifiers ---

    /// @dev Checks if the caller is the contract owner or the designated governance address.
    modifier onlyGovernanceOrOwner() {
        require(msg.sender == owner() || msg.sender == s_governance, "Only owner or governance");
        _;
    }

    /// @dev Checks if the provided skill ID corresponds to a defined skill.
    modifier whenSkillExists(uint256 skillId) {
        require(s_isSkillDefined[skillId], "Skill does not exist");
        _;
    }

    /// @dev Checks if XP distribution is currently unpaused.
    modifier whenXPDistributionIsNotPaused() {
        require(!s_xpDistributionPaused, "XP distribution is paused");
        _;
    }

    // --- Constructor ---

    constructor() Ownable(msg.sender) {
        // Initial owner is the deployer
    }

    // --- Internal Helper Functions ---

    /// @dev Checks if a user has all required prerequisites for a given skill.
    function _checkPrerequisites(address user, uint256 skillId) internal view returns (bool) {
        Skill memory skill = s_skillDefinitions[skillId];
        for (uint i = 0; i < skill.prerequisites.length; i++) {
            if (!s_userSkills[user][skill.prerequisites[i]]) {
                return false;
            }
        }
        return true;
    }

    /// @dev Checks if a skill ID is listed as a prerequisite for any currently defined skill.
    function _isPrerequisiteOfAnyExistingSkill(uint256 skillId) internal view returns (bool) {
        for (uint i = 0; i < s_definedSkillIds.length; i++) {
            uint256 definedSkillId = s_definedSkillIds[i];
            if (definedSkillId != skillId && s_isSkillDefined[definedSkillId]) {
                Skill memory definedSkill = s_skillDefinitions[definedSkillId];
                for (uint j = 0; j < definedSkill.prerequisites.length; j++) {
                    if (definedSkill.prerequisites[j] == skillId) {
                        return true;
                    }
                }
            }
        }
        return false;
    }

    /// @dev Prevents adding or updating a skill definition if it creates a circular dependency in prerequisites.
    /// @param skillId The ID of the skill being checked.
    /// @param prerequisites The list of prerequisite skill IDs.
    function _checkPrerequisiteCycles(uint256 skillId, uint256[] memory prerequisites) internal view {
        // Basic check: skill cannot be its own prerequisite
        for (uint i = 0; i < prerequisites.length; i++) {
            require(prerequisites[i] != skillId, "Skill cannot be its own prerequisite");
        }

        // More complex cycle detection (simplified): Check if any prerequisite directly or indirectly requires this skill.
        // This implementation performs a limited depth check. A full cycle detection might require a more complex graph traversal.
        // For this example, we'll check up to 2 levels deep.
        for (uint i = 0; i < prerequisites.length; i++) {
            uint256 prereqId = prerequisites[i];
            require(s_isSkillDefined[prereqId], "Prerequisite skill does not exist");

            // Check prereq's prereqs (1 level deep)
            Skill memory prereqSkill = s_skillDefinitions[prereqId];
            for (uint j = 0; j < prereqSkill.prerequisites.length; j++) {
                 require(prereqSkill.prerequisites[j] != skillId, "Prerequisite creates a cycle (1 level deep)");

                 // Check prereq's prereq's prereqs (2 levels deep)
                 uint256 prereq2Id = prereqSkill.prerequisites[j];
                 if (s_isSkillDefined[prereq2Id]) { // Check if prereq2Id is a defined skill
                      Skill memory prereq2Skill = s_skillDefinitions[prereq2Id];
                       for (uint k = 0; k < prereq2Skill.prerequisites.length; k++) {
                            require(prereq2Skill.prerequisites[k] != skillId, "Prerequisite creates a cycle (2 levels deep)");
                       }
                 }
            }
        }
        // Note: A truly robust cycle detection requires graph traversal (DFS/BFS), which is complex and gas-intensive on-chain.
        // This 2-level check provides basic protection against simple cycles.
    }


    /// @dev Internal function to issue a skill and manage associated token ID.
    function _issueSkillInternal(address recipient, uint256 skillId, address issuer) internal {
        require(recipient != address(0), "Issue to zero address");
        require(s_isSkillDefined[skillId], "Skill definition does not exist");
        require(!s_userSkills[recipient][skillId], "User already has this skill");
        require(_checkPrerequisites(recipient, skillId), "User does not meet prerequisites");

        // Assign skill
        s_userSkills[recipient][skillId] = true;
        s_userSkillList[recipient].push(skillId);

        // Mint a new token ID for this specific instance
        uint256 tokenId = s_nextTokenId++;
        s_tokenIdToHolder[tokenId] = recipient;
        s_tokenIdToSkillId[tokenId] = skillId;
        s_holderSkillToTokenId[recipient][skillId] = tokenId; // Store the unique tokenId for this user+skill pair

        emit SkillIssued(tokenId, recipient, skillId, issuer);
    }

    /// @dev Internal function to revoke a skill and manage associated token ID.
    /// @param holder The address holding the skill.
    /// @param skillId The ID of the skill to revoke.
    /// @param reason The reason for revocation.
    function _revokeSkillInternal(address holder, uint256 skillId, string memory reason) internal {
        require(s_isSkillDefined[skillId], "Skill definition does not exist");
        require(s_userSkills[holder][skillId], "User does not have this skill");

        // Check if any *other* skill held by this user depends on the one being revoked.
        // If so, revoking this skill would invalidate their dependent skills.
        // This policy decides whether to allow revocation anyway, or require dependent skills to be revoked first.
        // For this implementation, we'll allow revocation but acknowledge dependencies might be broken (they won't be able to unlock *new* skills that depend on the revoked one).
        // A stricter policy might require revoking dependents first or disallow if dependents exist.

        // Get the tokenId for this specific user+skill instance
        uint256 tokenId = s_holderSkillToTokenId[holder][skillId];
        require(tokenId != 0, "Token ID not found for this user/skill"); // Should not happen if s_userSkills[holder][skillId] is true

        // Remove skill
        s_userSkills[holder][skillId] = false;

        // Remove from the user's list (inefficient for large lists, consider linked list or different structure if many skills per user)
        uint265 indexToRemove = type(uint256).max;
        for(uint256 i = 0; i < s_userSkillList[holder].length; i++){
            if(s_userSkillList[holder][i] == skillId){
                indexToRemove = i;
                break;
            }
        }
        if (indexToRemove != type(uint256).max) {
             // Swap last element with element to remove and pop
            uint256 lastIndex = s_userSkillList[holder].length - 1;
            s_userSkillList[holder][indexToRemove] = s_userSkillList[holder][lastIndex];
            s_userSkillList[holder].pop();
        }


        // Clean up tokenId mappings
        delete s_tokenIdToHolder[tokenId];
        delete s_tokenIdToSkillId[tokenId];
        delete s_holderSkillToTokenId[holder][skillId];

        emit SkillRevoked(tokenId, holder, skillId, msg.sender, reason);
    }


    // --- Owner/Governance Functions ---

    /// @dev Transfers ownership of the contract.
    /// Can only be called by the current owner.
    function transferOwnership(address newOwner) public override onlyOwner {
        super.transferOwnership(newOwner);
    }

    /// @dev Sets the designated governance address. This address can perform certain privileged actions.
    /// Can only be called by the contract owner.
    /// @param _governance The address to set as the governance address.
    function setGovernanceAddress(address _governance) public onlyOwner {
        address oldGovernance = s_governance;
        s_governance = _governance;
        emit GovernanceAddressSet(oldGovernance, _governance);
    }

    /// @dev Pauses XP distribution by authorized parties.
    /// Can only be called by the owner or governance address.
    function pauseXPDistribution() public onlyGovernanceOrOwner {
        s_xpDistributionPaused = true;
        emit XPDistributionPaused(msg.sender);
    }

    /// @dev Unpauses XP distribution by authorized parties.
    /// Can only be called by the owner or governance address.
    function unpauseXPDistribution() public onlyGovernanceOrOwner {
        s_xpDistributionPaused = false;
        emit XPDistributionUnpaused(msg.sender);
    }


    /// @dev Adds a new skill definition to the tree.
    /// Skill IDs must be unique and non-zero. Prerequisite IDs must exist and not create cycles.
    /// Can only be called by the owner or governance address.
    /// @param skillId The unique ID for the new skill.
    /// @param name The name of the skill.
    /// @param description A description of the skill.
    /// @param prerequisites An array of skill IDs that must be held before this skill can be earned.
    /// @param xpCost The amount of XP required to unlock this skill via `attemptUnlockSkillWithXP`.
    function addSkillDefinition(
        uint256 skillId,
        string memory name,
        string memory description,
        uint256[] memory prerequisites,
        uint256 xpCost
    ) public onlyGovernanceOrOwner {
        require(skillId != 0, "Skill ID cannot be zero");
        require(!s_isSkillDefined[skillId], "Skill ID already exists");

        _checkPrerequisiteCycles(skillId, prerequisites); // Prevent cycles

        s_skillDefinitions[skillId] = Skill({
            name: name,
            description: description,
            prerequisites: prerequisites,
            xpCost: xpCost,
            isDefined: true
        });
        s_definedSkillIds.push(skillId);
        s_isSkillDefined[skillId] = true;

        emit SkillDefinitionAdded(skillId, name, xpCost);
    }

    /// @dev Updates an existing skill definition.
    /// Can update name, description, prerequisites, and XP cost.
    /// Requires the skill ID to exist. Updated prerequisites must not create cycles.
    /// Consider implications if users already hold this skill or skills that depend on it.
    /// Can only be called by the owner or governance address.
    /// @param skillId The ID of the skill to update.
    /// @param name The new name of the skill.
    /// @param description The new description of the skill.
    /// @param prerequisites The new array of prerequisite skill IDs.
    /// @param xpCost The new XP cost.
    function updateSkillDefinition(
        uint256 skillId,
        string memory name,
        string memory description,
        uint256[] memory prerequisites,
        uint256 xpCost
    ) public onlyGovernanceOrOwner whenSkillExists(skillId) {
        // Ensure the skill is not a prerequisite for itself or creating new cycles
        _checkPrerequisiteCycles(skillId, prerequisites);

        // Note: This update doesn't affect skills already held by users.
        // Users who already hold the skill keep it, even if they no longer meet new prerequisites.
        // Users attempting to unlock it *after* the update will use the new definition.

        Skill storage skill = s_skillDefinitions[skillId];
        skill.name = name;
        skill.description = description;
        skill.prerequisites = prerequisites; // Overwrites existing prereqs
        skill.xpCost = xpCost;

        emit SkillDefinitionUpdated(skillId, name, xpCost);
    }

    /// @dev Removes a skill definition.
    /// Can only be removed if no user currently holds this skill and it's not a prerequisite for any other defined skill.
    /// Can only be called by the owner or governance address.
    /// @param skillId The ID of the skill to remove.
    function removeSkillDefinition(uint256 skillId) public onlyGovernanceOrOwner whenSkillExists(skillId) {
        // Check if any user holds this skill
        require(getSkillHolderCount(skillId) == 0, "Cannot remove skill definition while users hold it");
        // Check if it's a prerequisite for any other existing skill
        require(!_isPrerequisiteOfAnyExistingSkill(skillId), "Cannot remove skill as it is a prerequisite for another skill");

        delete s_skillDefinitions[skillId];
        s_isSkillDefined[skillId] = false;

        // Remove from s_definedSkillIds list (inefficient for large lists, consider using a mapping or linked list)
        uint256 indexToRemove = type(uint256).max;
        for(uint256 i = 0; i < s_definedSkillIds.length; i++){
            if(s_definedSkillIds[i] == skillId){
                indexToRemove = i;
                break;
            }
        }
        if (indexToRemove != type(uint256).max) {
            // Swap last element with element to remove and pop
            uint256 lastIndex = s_definedSkillIds.length - 1;
            s_definedSkillIds[indexToRemove] = s_definedSkillIds[lastIndex];
            s_definedSkillIds.pop();
        }

        emit SkillDefinitionRemoved(skillId);
    }

    /// @dev Sets the base URI for the metadata of issued skill tokens.
    /// The token URI for a specific skill instance will be baseURI + tokenId.toString().
    /// Can only be called by the owner or governance address.
    /// @param baseURI The new base metadata URI.
    function setBaseMetadataURI(string memory baseURI) public onlyGovernanceOrOwner {
        s_baseMetadataURI = baseURI;
    }


    /// @dev Issues a specific skill to a user.
    /// This function bypasses the XP cost but still requires prerequisites to be met.
    /// Can only be called by the owner or governance address.
    /// @param recipient The address to issue the skill to.
    /// @param skillId The ID of the skill to issue.
    function issueSkillTo(address recipient, uint256 skillId) public onlyGovernanceOrOwner whenSkillExists(skillId) {
        _issueSkillInternal(recipient, skillId, msg.sender);
    }

    /// @dev Issues multiple skills to a single user in a batch.
    /// Each skill requires prerequisites to be met.
    /// Can only be called by the owner or governance address.
    /// @param recipient The address to issue skills to.
    /// @param skillIds An array of skill IDs to issue.
    function batchIssueSkillsTo(address recipient, uint256[] memory skillIds) public onlyGovernanceOrOwner {
        for (uint i = 0; i < skillIds.length; i++) {
             require(s_isSkillDefined[skillIds[i]], "Skill ID in batch does not exist");
            // Only issue if user doesn't already have it and meets prereqs.
            // If a skill in the batch is a prerequisite for a later skill in the same batch,
            // the prerequisite check will pass if the user already had it or acquires it earlier in this loop.
            if (!s_userSkills[recipient][skillIds[i]] && _checkPrerequisites(recipient, skillIds[i])) {
                 _issueSkillInternal(recipient, skillIds[i], msg.sender);
            }
        }
    }

    /// @dev Issues a single skill to multiple users in a batch.
    /// Each user requires prerequisites to be met for the skill.
    /// Can only be called by the owner or governance address.
    /// @param recipients An array of addresses to issue the skill to.
    /// @param skillId The ID of the skill to issue.
    function issueSkillBatch(address[] memory recipients, uint256 skillId) public onlyGovernanceOrOwner whenSkillExists(skillId) {
         // Pre-check prerequisites for all recipients if needed, or check per recipient in the loop.
         // Checking per recipient is simpler and handles cases where some recipients meet prereqs and others don't.
        for (uint i = 0; i < recipients.length; i++) {
            address recipient = recipients[i];
            // Only issue if user doesn't already have it and meets prereqs.
            if (recipient != address(0) && !s_userSkills[recipient][skillId] && _checkPrerequisites(recipient, skillId)) {
                _issueSkillInternal(recipient, skillId, msg.sender);
            }
        }
    }


    /// @dev Revokes a specific skill from a user.
    /// This is a powerful function typically used for correcting errors or addressing policy violations.
    /// Consider the implications for skills that had the revoked skill as a prerequisite.
    /// Can only be called by the owner or governance address.
    /// @param holder The address to revoke the skill from.
    /// @param skillId The ID of the skill to revoke.
    /// @param reason A description of why the skill is being revoked.
    function revokeSkillFrom(address holder, uint256 skillId, string memory reason) public onlyGovernanceOrOwner {
        _revokeSkillInternal(holder, skillId, reason);
    }


    /// @dev Distributes XP to a user.
    /// Can only be called by the owner or governance address.
    /// @param recipient The address to receive XP.
    /// @param amount The amount of XP to distribute.
    function distributeXP(address recipient, uint256 amount) public onlyGovernanceOrOwner whenXPDistributionIsNotPaused {
        require(recipient != address(0), "Distribute to zero address");
        s_userXP[recipient] += amount;
        emit XPSent(recipient, amount, msg.sender);
    }

    /// @dev Distributes XP to multiple users in a batch.
    /// Can only be called by the owner or governance address.
    /// @param recipients An array of addresses to receive XP.
    /// @param amounts An array of corresponding XP amounts. Must have the same length as recipients.
    function batchDistributeXP(address[] memory recipients, uint256[] memory amounts) public onlyGovernanceOrOwner whenXPDistributionIsNotPaused {
        require(recipients.length == amounts.length, "Recipient and amount arrays must match in length");
        for (uint i = 0; i < recipients.length; i++) {
            address recipient = recipients[i];
            uint256 amount = amounts[i];
             if (recipient != address(0) && amount > 0) {
                s_userXP[recipient] += amount;
                emit XPSent(recipient, amount, msg.sender);
            }
        }
    }

    // --- User Functions ---

    /// @dev Allows a user to attempt to unlock a skill using their accumulated XP.
    /// Requires the user to meet all prerequisites and have sufficient XP.
    /// The required XP is deducted upon successful unlock.
    /// @param skillId The ID of the skill the user wants to unlock.
    function attemptUnlockSkillWithXP(uint256 skillId) public whenSkillExists(skillId) {
        address user = msg.sender;
        Skill memory skill = s_skillDefinitions[skillId];

        require(!s_userSkills[user][skillId], "User already has this skill");
        require(_checkPrerequisites(user, skillId), "User does not meet prerequisites");
        require(s_userXP[user] >= skill.xpCost, "Insufficient XP");

        // Deduct XP and issue the skill
        s_userXP[user] -= skill.xpCost;
        _issueSkillInternal(user, skillId, address(0)); // Issuer is address(0) to signify XP unlock

        emit SkillUnlocked(s_holderSkillToTokenId[user][skillId], user, skillId, skill.xpCost);
    }

    /// @dev Allows a user to burn their own XP.
    /// This XP is permanently removed from their balance. Useful if XP could have other uses (e.g., gas reduction).
    /// @param amount The amount of XP to burn.
    function burnXP(uint256 amount) public {
        require(s_userXP[msg.sender] >= amount, "Insufficient XP to burn");
        s_userXP[msg.sender] -= amount;
        emit XPBurned(msg.sender, amount);
    }


    // --- View Functions ---

    /// @dev Gets the details of a specific skill definition.
    /// @param skillId The ID of the skill.
    /// @return name The skill name.
    /// @return description The skill description.
    /// @return prerequisites The array of prerequisite skill IDs.
    /// @return xpCost The XP cost to unlock.
    function getSkillDefinition(uint256 skillId)
        public
        view
        whenSkillExists(skillId)
        returns (string memory name, string memory description, uint256[] memory prerequisites, uint256 xpCost)
    {
        Skill memory skill = s_skillDefinitions[skillId];
        return (skill.name, skill.description, skill.prerequisites, skill.xpCost);
    }

    /// @dev Gets the list of prerequisite skill IDs for a given skill.
    /// @param skillId The ID of the skill.
    /// @return prerequisites The array of prerequisite skill IDs.
    function getSkillPrerequisites(uint256 skillId) public view whenSkillExists(skillId) returns (uint256[] memory) {
        return s_skillDefinitions[skillId].prerequisites;
    }

     /// @dev Gets a list of all defined skill IDs.
     /// @return An array of all skill IDs currently defined.
    function getAllSkillDefinitions() public view returns (uint256[] memory) {
        return s_definedSkillIds;
    }

    /// @dev Gets the total number of skill definitions.
    /// @return The count of defined skills.
    function getSkillCount() public view returns (uint256) {
        return s_definedSkillIds.length;
    }


    /// @dev Checks if a specific user has a specific skill.
    /// @param user The address of the user.
    /// @param skillId The ID of the skill to check.
    /// @return True if the user has the skill, false otherwise.
    function hasSkill(address user, uint256 skillId) public view returns (bool) {
        return s_userSkills[user][skillId];
    }

    /// @dev Gets the list of all skill IDs held by a specific user.
    /// @param user The address of the user.
    /// @return An array of skill IDs the user holds.
    function getUserSkills(address user) public view returns (uint256[] memory) {
        return s_userSkillList[user]; // Returns the list of skill IDs
    }

    /// @dev Gets the current XP balance of a user.
    /// @param user The address of the user.
    /// @return The user's XP balance.
    function getUserXP(address user) public view returns (uint256) {
        return s_userXP[user];
    }

    /// @dev Checks if a user is eligible to unlock a skill based on prerequisites and XP.
    /// @param user The address of the user.
    /// @param skillId The ID of the skill to check.
    /// @return True if the user meets prerequisites and has enough XP, false otherwise.
    function canUnlockSkill(address user, uint256 skillId) public view whenSkillExists(skillId) returns (bool) {
        Skill memory skill = s_skillDefinitions[skillId];
        if (s_userSkills[user][skillId]) {
            return false; // Already has the skill
        }
        if (s_userXP[user] < skill.xpCost) {
            return false; // Not enough XP
        }
        if (!_checkPrerequisites(user, skillId)) {
            return false; // Doesn't meet prerequisites
        }
        return true; // Eligible to unlock
    }

    /// @dev Gets the number of users who currently hold a specific skill.
    /// Note: This iterates through all users, which can be gas-intensive and should be used judiciously off-chain.
    /// For this implementation, we would need to track holder counts separately, which adds complexity.
    /// A simpler, but potentially less efficient on-chain way is to iterate.
    /// A more efficient way would be to maintain a separate counter or list per skill.
    /// Let's implement the counter approach for efficiency. We need to update this counter on issue and revoke.
    mapping(uint256 => uint256) private s_skillHolderCount;

    /// @dev Gets the number of unique users who currently hold a specific skill.
    /// This relies on an internal counter updated during issue/revoke operations.
    /// @param skillId The ID of the skill.
    /// @return The number of users holding the skill.
    function getSkillHolderCount(uint256 skillId) public view whenSkillExists(skillId) returns (uint256) {
        return s_skillHolderCount[skillId];
    }


    // --- ERC-721-like View Functions (for compatibility) ---
    // Note: These tokens are NOT transferable. approve/transferFrom/safeTransferFrom are not implemented/allowed.

    /// @dev Gets the metadata URI for a specific issued skill instance.
    /// Implements ERC-721 Metadata URI standard.
    /// @param tokenId The unique ID of the skill instance.
    /// @return The URI pointing to the metadata for this token.
    function getTokenURI(uint256 tokenId) public view returns (string memory) {
        require(s_tokenIdToHolder[tokenId] != address(0), "Token ID does not exist");
        // Returns baseURI + tokenId.toString()
        return string(abi.encodePacked(s_baseMetadataURI, tokenId.toString()));
    }

    /// @dev Gets the specific token ID associated with a user's instance of a skill.
    /// @param user The address of the user.
    /// @param skillId The ID of the skill.
    /// @return The unique token ID for this user's skill instance, or 0 if the user does not have the skill.
    function getSkillTokenId(address user, uint256 skillId) public view returns (uint256) {
        return s_holderSkillToTokenId[user][skillId]; // Returns 0 if not found
    }

    /// @dev Gets a list of all token IDs held by a specific user.
    /// @param user The address of the user.
    /// @return An array of token IDs held by the user.
    function getUserSkillTokenIds(address user) public view returns (uint256[] memory) {
        uint256[] memory skillIds = getUserSkills(user); // Get the list of skill IDs
        uint256[] memory tokenIds = new uint256[](skillIds.length);
        for(uint i = 0; i < skillIds.length; i++){
            tokenIds[i] = s_holderSkillToTokenId[user][skillIds[i]];
        }
        return tokenIds;
    }

    /// @dev Gets the skill definition associated with a specific issued token ID.
    /// @param tokenId The unique ID of the skill instance.
    /// @return skillId The ID of the skill.
    /// @return name The skill name.
    /// @return description The skill description.
    /// @return prerequisites The array of prerequisite skill IDs.
    /// @return xpCost The XP cost to unlock.
    function getSkillDefinitionByTokenId(uint256 tokenId)
        public
        view
        returns (uint256 skillId, string memory name, string memory description, uint256[] memory prerequisites, uint256 xpCost)
    {
         require(s_tokenIdToHolder[tokenId] != address(0), "Token ID does not exist");
         skillId = s_tokenIdToSkillId[tokenId];
         return getSkillDefinition(skillId); // Reuse existing view function
    }

    /// @dev Gets the holder of a specific issued skill instance (ERC-721 ownerOf equivalent).
    /// @param tokenId The unique ID of the skill instance.
    /// @return The address holding the token.
    function getTokenHolder(uint256 tokenId) public view returns (address) {
         require(s_tokenIdToHolder[tokenId] != address(0), "Token ID does not exist");
         return s_tokenIdToHolder[tokenId];
    }

    // --- ERC-721 Forbidden Functions ---
    // Explicitly omitting or making these functions require authorization/revert
    // to enforce the Soulbound nature.
    // Transfer, safeTransferFrom, approve, setApprovalForAll, getApproved, isApprovedForAll are not implemented.
    // The core _issueSkillInternal and _revokeSkillInternal handle the token ID management.
    // The only way a token ID changes holder is by direct issuance or revocation from the authorized parties.
    // Users cannot transfer their skill tokens.

    // Example of making a transfer function revert:
    // function transferFrom(address from, address to, uint256 tokenId) public virtual {
    //     revert("Skill tokens are soulbound and cannot be transferred");
    // }
    // (Or simply don't include these functions)

}
```