Okay, let's design a smart contract around a "Decentralized Skill Tree" concept. This contract will allow users to track their "learning" or "mastery" of skills on-chain, with prerequisites and a validation mechanism. It goes beyond simple token transfers or NFTs by introducing complex state transitions, dependencies, and a multi-party interaction model (user, contract, validator).

Here's the outline and function summary, followed by the Solidity code.

---

## DecentralizedSkillTree Smart Contract

This contract implements a system for managing skill trees, user progress, and skill validation on the blockchain. Users can attempt to learn skills, which may require prerequisites and/or validation by designated validators.

**Concept:**
*   **Skill Trees:** Categories or branches of skills.
*   **Skills:** Individual units of knowledge or capability within a tree. Each skill can have prerequisites (other skills that must be learned first).
*   **Users:** Addresses interacting with the contract to learn skills.
*   **Skill Status:** Each user's status for each skill (Locked, Available, Attempting, Learned, Validated).
*   **Validation:** A process where designated addresses ("Validators") can verify a user's claim to have learned a skill, moving their status to "Validated".
*   **Learning Requirements:** Skills can have different requirements to be considered "Learned" (e.g., automatic upon attempting, requiring submission of off-chain proof, requiring validator approval).
*   **Validation Requirements:** Skills can have different requirements to be considered "Validated" (e.g., automatic upon learning, requiring any validator, requiring specific validators).

**Data Structures:**

1.  `SkillTree`: Represents a category or branch of skills.
    *   `name`: Name of the skill tree.
    *   `skillIds`: Array of skill IDs belonging to this tree.
2.  `Skill`: Represents an individual skill.
    *   `name`: Name of the skill.
    *   `description`: Description of the skill.
    *   `prerequisiteSkillIds`: Array of skill IDs required before attempting this skill.
    *   `treeId`: ID of the skill tree this skill belongs to.
    *   `requirementType`: How the skill moves from `Attempting` to `Learned`.
    *   `validationRequirement`: How the skill moves from `Learned` to `Validated`.
    *   `challengeDataHash`: Optional hash linking to off-chain challenge data.
    *   `isActive`: Flag to enable/disable the skill.
3.  `UserSkillStatus`: Represents a user's progress for a specific skill.
    *   `status`: Current status (Locked, Available, Attempting, Learned, Validated).
    *   `attemptTimestamp`: Timestamp when `attemptLearnSkill` was called.
    *   `learnedTimestamp`: Timestamp when status became `Learned`.
    *   `validatedTimestamp`: Timestamp when status became `Validated`.
    *   `submittedChallengeProofHash`: Hash submitted by the user for challenge-based skills.
    *   `validatorAddress`: Address of the validator if validation was required.

**State Machine for a User's Skill Status:**

`Locked` (Default)
-> `Available` (Prerequisites met, if any)
-> `Attempting` (`attemptLearnSkill` called)
-> `Learned` (Requirement met: e.g., `submitChallengeProof` called if `RequirementType` is `Challenge`, or automatically if `RequirementType` is `Auto`)
-> `Validated` (Validation met: e.g., `validateSkill` called if `ValidationRequirement` is `AnyValidator`, or automatically if `ValidationRequirement` is `AutoLearned`)

*(Note: A skill requiring validation will transition `Attempting` -> `Learned` -> `Validated`. A skill not requiring validation will transition `Attempting` -> `Validated` directly if `RequirementType` is `Auto`, or `Attempting` -> `Learned` (via challenge proof) -> `Validated` automatically if `ValidationRequirement` is `AutoLearned`.)*

**Enums:**

*   `SkillStatus`: `Locked`, `Available`, `Attempting`, `Learned`, `Validated`
*   `RequirementType`: `Auto` (Learned immediately on attempt), `Challenge` (Requires `submitChallengeProof`), `ValidatorApprovedLearning` (Requires validator approval to be Learned - *Note: This is an alternative path, simplified by combining learning/validation states below*)
*   `ValidationRequirement`: `None` (Validated immediately on learning), `AnyValidator` (Requires any registered validator), `SpecificValidators` (Requires approval from a specific set - *Note: Simplified to AnyValidator for this version*), `AutoLearned` (Validated automatically once Learned - used for Challenge type skills that don't need manual validation *after* learning proof is submitted).

*(Refined State Flow for Simplicity & Clarity)*
`Locked` (Default)
-> `Available` (Prerequisites met)
-> `Attempting` (`attemptLearnSkill` called)
-> `Processing` (Intermediate state after attempting, waiting for challenge proof or validator action)
-> `Validated` (Skill requirements fully met and verified - end state)
-> `Rejected` (Attempt was rejected by validator - allows retrying)

*(Refined Requirement/Validation Combinations)*
1.  **Auto Learn & Auto Validate:** `RequirementType.Auto`, `ValidationRequirement.None`. Transitions: `Attempting` -> `Validated`.
2.  **Challenge & Auto Validate:** `RequirementType.Challenge`, `ValidationRequirement.AutoLearned`. Transitions: `Attempting` -> `Processing` (on challenge proof) -> `Validated`.
3.  **Validator Learn & Validate:** `RequirementType.ValidatorApprovedLearning`, `ValidationRequirement.AnyValidator`. Transitions: `Attempting` -> `Processing` (on validator approval) -> `Validated`. (Simplified validator interaction: validation is the final step, moving directly to `Validated`).

*(Final Simpler State Flow)*
`Locked` (Default)
-> `Available` (Prerequisites met)
-> `Attempting` (`attemptLearnSkill` called)
-> `Validated` (Requirements fully met: auto, challenge proof + auto-validate, or validator approval)
-> `Rejected` (Attempt was rejected by validator - allows retrying)

**Functions (Approx. 25+ Public/External):**

1.  `constructor()`: Initializes the owner.
2.  `addSkillTree(string memory _name)`: Owner adds a new skill tree. Returns treeId.
3.  `updateSkillTreeName(uint256 _treeId, string memory _newName)`: Owner updates a tree's name.
4.  `addSkill(uint256 _treeId, string memory _name, string memory _description, uint256[] memory _prerequisiteSkillIds, RequirementType _requirementType, ValidationRequirement _validationRequirement, bytes32 _challengeDataHash, bool _isActive)`: Owner adds a new skill to a tree. Returns skillId.
5.  `updateSkillDetails(uint256 _skillId, string memory _name, string memory _description, bytes32 _challengeDataHash, bool _isActive)`: Owner updates basic skill details.
6.  `updateSkillPrerequisites(uint256 _skillId, uint256[] memory _newPrerequisites)`: Owner updates a skill's prerequisites.
7.  `updateSkillRequirementTypes(uint256 _skillId, RequirementType _requirementType, ValidationRequirement _validationRequirement)`: Owner updates how a skill is learned/validated.
8.  `addValidator(address _validator)`: Owner adds a validator address.
9.  `removeValidator(address _validator)`: Owner removes a validator address.
10. `isValidator(address _address)`: View if an address is a validator.
11. `attemptLearnSkill(uint256 _skillId)`: User initiates learning a skill. Checks prerequisites and updates status to `Attempting`.
12. `submitChallengeProof(uint256 _skillId, bytes32 _proofHash)`: User submits proof for a Challenge-based skill. Checks status and requirement type. Updates status based on `ValidationRequirement`.
13. `validateSkillAttempt(address _user, uint256 _skillId)`: Validator approves a user's skill attempt (for ValidatorApprovedLearning skills). Checks status and requirement type. Updates status to `Validated`.
14. `rejectSkillAttempt(address _user, uint256 _skillId, string memory _reason)`: Validator rejects a user's skill attempt. Updates status to `Rejected`.
15. `reattemptRejectedSkill(uint256 _skillId)`: User attempts a rejected skill again. Resets status to `Attempting`.
16. `getSkillTreeCount()`: View total number of skill trees.
17. `getSkillTreeDetails(uint256 _treeId)`: View details of a skill tree.
18. `getSkillCount()`: View total number of skills.
19. `getSkillDetails(uint256 _skillId)`: View details of a skill.
20. `getSkillsInTree(uint256 _treeId)`: View list of skill IDs in a tree.
21. `getUserSkillStatus(address _user, uint256 _skillId)`: View a user's status for a specific skill.
22. `checkPrerequisitesMet(address _user, uint256 _skillId)`: View if a user has met prerequisites for a skill.
23. `getAvailableSkillsForUser(address _user)`: View list of skill IDs the user can attempt (prereqs met, not Validated/Attempting).
24. `getUserSkillsByStatus(address _user, SkillStatus _status)`: View list of skill IDs a user has with a specific status.
25. `getValidators()`: View the list of current validators.
26. `pauseContract()`: Owner can pause the contract (e.g., for upgrades or emergencies).
27. `unpauseContract()`: Owner can unpause the contract.
28. `transferOwnership(address _newOwner)`: Owner can transfer ownership.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

// --- Outline & Function Summary ---
// See detailed outline and summary above the contract code block.
// Key elements: Skill Trees, Skills with prerequisites and dynamic requirements,
// User progress tracking with a state machine, Validator system,
// > 25 public/external functions for admin, user, and validator interactions.
// Advanced/Creative aspects: On-chain skill tree structure with dependencies,
// configurable learning/validation flows, explicit user 'attempt' state,
// validator role for decentralized verification, state-dependent function access.
// --- End Outline & Summary ---

contract DecentralizedSkillTree is Ownable, Pausable {

    // --- Enums ---

    enum SkillStatus {
        Locked,        // Prerequisites not met, or not yet attempted
        Available,     // Prerequisites met, ready to be attempted
        Attempting,    // attemptLearnSkill called, waiting for next step (challenge proof or validation)
        Validated,     // Skill successfully learned and verified (final state)
        Rejected       // Attempt was rejected by a validator
    }

    enum RequirementType {
        Auto,                     // Skill transitions directly from Attempting to Validated on attemptLearnSkill
        Challenge,                // Skill requires submitChallengeProof after attemptLearnSkill to move to Processing
        ValidatorApprovedLearning // Skill requires validateSkillAttempt after attemptLearnSkill to move to Validated
    }

    enum ValidationRequirement {
        None,         // Validation happens automatically based on RequirementType (Auto or Challenge+AutoLearned)
        AnyValidator, // Requires any registered validator to call validateSkillAttempt
        AutoLearned   // Validated automatically once RequirementType (Challenge) is fulfilled (moves from Processing to Validated)
        // SpecificValidators - omitted for simplicity in this version
    }

    // --- Data Structures ---

    struct SkillTree {
        string name;
        uint256[] skillIds; // Store IDs for easy retrieval per tree
    }

    struct Skill {
        string name;
        string description;
        uint256[] prerequisiteSkillIds;
        uint256 treeId;
        RequirementType requirementType;
        ValidationRequirement validationRequirement;
        bytes32 challengeDataHash; // Optional hash linking to off-chain challenge data
        bool isActive; // Allows disabling skills without removing them
    }

    struct UserSkillStatus {
        SkillStatus status;
        uint48 attemptTimestamp; // Using uint48 for gas efficiency (timestamps are typically < 2^48)
        uint48 validatedTimestamp;
        bytes32 submittedChallengeProofHash; // Proof submitted by user for Challenge type
        address validatorAddress; // Address of the validator who validated the skill
    }

    // --- State Variables ---

    uint256 private nextSkillTreeId = 1;
    mapping(uint256 => SkillTree) public skillTrees;

    uint256 private nextSkillId = 1;
    mapping(uint256 => Skill) public skills;

    // userAddress => skillId => status
    mapping(address => mapping(uint256 => UserSkillStatus)) public userSkillStatuses;

    // validatorAddress => isValidator
    mapping(address => bool) private validators;
    address[] private validatorList; // To easily retrieve all validators

    // --- Events ---

    event SkillTreeAdded(uint256 indexed treeId, string name, address indexed owner);
    event SkillTreeUpdated(uint256 indexed treeId, string newName);
    event SkillAdded(uint256 indexed skillId, uint256 indexed treeId, string name, address indexed owner);
    event SkillUpdated(uint256 indexed skillId, string name, bool isActive);
    event SkillPrerequisitesUpdated(uint256 indexed skillId, uint256[] newPrerequisites);
    event SkillRequirementTypesUpdated(uint256 indexed skillId, RequirementType requirementType, ValidationRequirement validationRequirement);

    event ValidatorAdded(address indexed validator, address indexed owner);
    event ValidatorRemoved(address indexed validator, address indexed owner);

    event SkillAttempted(address indexed user, uint256 indexed skillId, uint48 timestamp);
    event ChallengeProofSubmitted(address indexed user, uint256 indexed skillId, bytes32 proofHash);
    event SkillValidated(address indexed user, uint256 indexed skillId, address indexed validator, uint48 timestamp);
    event SkillRejected(address indexed user, uint256 indexed skillId, address indexed validator, string reason);
    event SkillReattempted(address indexed user, uint256 indexed skillId);

    // --- Modifier ---

    modifier onlyValidator() {
        require(validators[msg.sender], "DST: Caller is not a validator");
        _;
    }

    // --- Constructor ---

    constructor() Ownable(msg.sender) {}

    // --- Admin Functions (Owner Only) ---

    function addSkillTree(string memory _name) external onlyOwner returns (uint256) {
        uint256 treeId = nextSkillTreeId++;
        skillTrees[treeId] = SkillTree({
            name: _name,
            skillIds: new uint256[](0)
        });
        emit SkillTreeAdded(treeId, _name, msg.sender);
        return treeId;
    }

    function updateSkillTreeName(uint256 _treeId, string memory _newName) external onlyOwner {
        require(skillTrees[_treeId].skillIds.length > 0 || _treeId < nextSkillTreeId, "DST: Invalid tree ID"); // Basic check if tree exists
        skillTrees[_treeId].name = _newName;
        emit SkillTreeUpdated(_treeId, _newName);
    }

    function addSkill(
        uint256 _treeId,
        string memory _name,
        string memory _description,
        uint256[] memory _prerequisiteSkillIds,
        RequirementType _requirementType,
        ValidationRequirement _validationRequirement,
        bytes32 _challengeDataHash,
        bool _isActive
    ) external onlyOwner returns (uint256) {
        require(skillTrees[_treeId].skillIds.length > 0 || _treeId < nextSkillTreeId, "DST: Invalid tree ID");

        // Validate prerequisite IDs exist
        for (uint i = 0; i < _prerequisiteSkillIds.length; i++) {
            require(skills[_prerequisiteSkillIds[i]].treeId != 0 || _prerequisiteSkillIds[i] < nextSkillId, "DST: Invalid prerequisite skill ID");
        }

        // Validate RequirementType & ValidationRequirement compatibility
        // If Auto, ValidationRequirement must be None
        require(!(_requirementType == RequirementType.Auto && _validationRequirement != ValidationRequirement.None), "DST: Auto requirement needs None validation");
        // If Challenge, ValidationRequirement must be AutoLearned or AnyValidator (None wouldn't make sense)
        require(!(_requirementType == RequirementType.Challenge && _validationRequirement == ValidationRequirement.None), "DST: Challenge requirement needs validation");
        // If ValidatorApprovedLearning, ValidationRequirement must be AnyValidator (AutoLearned wouldn't make sense)
        require(!(_requirementType == RequirementType.ValidatorApprovedLearning && _validationRequirement == ValidationRequirement.AutoLearned), "DST: Validator requirement needs AnyValidator validation");


        uint256 skillId = nextSkillId++;
        skills[skillId] = Skill({
            name: _name,
            description: _description,
            prerequisiteSkillIds: _prerequisiteSkillIds,
            treeId: _treeId,
            requirementType: _requirementType,
            validationRequirement: _validationRequirement,
            challengeDataHash: _challengeDataHash,
            isActive: _isActive
        });

        skillTrees[_treeId].skillIds.push(skillId);

        emit SkillAdded(skillId, _treeId, _name, msg.sender);
        return skillId;
    }

     function updateSkillDetails(
        uint256 _skillId,
        string memory _name,
        string memory _description,
        bytes32 _challengeDataHash,
        bool _isActive
    ) external onlyOwner {
        require(skills[_skillId].treeId != 0 || _skillId < nextSkillId, "DST: Invalid skill ID");
        skills[_skillId].name = _name;
        skills[_skillId].description = _description;
        skills[_skillId].challengeDataHash = _challengeDataHash;
        skills[_skillId].isActive = _isActive;
        emit SkillUpdated(_skillId, _name, _isActive);
    }

    function updateSkillPrerequisites(uint256 _skillId, uint256[] memory _newPrerequisites) external onlyOwner {
         require(skills[_skillId].treeId != 0 || _skillId < nextSkillId, "DST: Invalid skill ID");

         // Validate prerequisite IDs exist
        for (uint i = 0; i < _newPrerequisites.length; i++) {
            require(skills[_newPrerequisiteIds[i]].treeId != 0 || _newPrerequisites[i] < nextSkillId, "DST: Invalid prerequisite skill ID");
        }

        skills[_skillId].prerequisiteSkillIds = _newPrerequisites;
        emit SkillPrerequisitesUpdated(_skillId, _newPrerequisites);
    }

    function updateSkillRequirementTypes(uint256 _skillId, RequirementType _requirementType, ValidationRequirement _validationRequirement) external onlyOwner {
        require(skills[_skillId].treeId != 0 || _skillId < nextSkillId, "DST: Invalid skill ID");

        // Validate compatibility again
         require(!(_requirementType == RequirementType.Auto && _validationRequirement != ValidationRequirement.None), "DST: Auto requirement needs None validation");
        require(!(_requirementType == RequirementType.Challenge && _validationRequirement == ValidationRequirement.None), "DST: Challenge requirement needs validation");
        require(!(_requirementType == RequirementType.ValidatorApprovedLearning && _validationRequirement == ValidationRequirement.AutoLearned), "DST: Validator requirement needs AnyValidator validation");


        skills[_skillId].requirementType = _requirementType;
        skills[_skillId].validationRequirement = _validationRequirement;
        emit SkillRequirementTypesUpdated(_skillId, _requirementType, _validationRequirement);
    }

    function addValidator(address _validator) external onlyOwner {
        require(_validator != address(0), "DST: Zero address not allowed");
        if (!validators[_validator]) {
            validators[_validator] = true;
            validatorList.push(_validator);
            emit ValidatorAdded(_validator, msg.sender);
        }
    }

    function removeValidator(address _validator) external onlyOwner {
        if (validators[_validator]) {
            validators[_validator] = false;
            // Remove from validatorList - potentially gas-intensive O(N)
            for (uint i = 0; i < validatorList.length; i++) {
                if (validatorList[i] == _validator) {
                    validatorList[i] = validatorList[validatorList.length - 1];
                    validatorList.pop();
                    break;
                }
            }
            emit ValidatorRemoved(_validator, msg.sender);
        }
    }

    // --- User Functions ---

    function attemptLearnSkill(uint256 _skillId) external whenNotPaused {
        require(skills[_skillId].isActive, "DST: Skill is not active");

        UserSkillStatus storage userStatus = userSkillStatuses[msg.sender][_skillId];

        // Check current status allows attempting
        require(
            userStatus.status == SkillStatus.Locked ||
            userStatus.status == SkillStatus.Available ||
            userStatus.status == SkillStatus.Rejected,
            "DST: Skill is not available or rejected for attempting"
        );

        // Check prerequisites if status is Locked or Available
        if (userStatus.status == SkillStatus.Locked || userStatus.status == SkillStatus.Available) {
             require(checkPrerequisitesMet(msg.sender, _skillId), "DST: Prerequisites not met");
        }

        Skill storage skill = skills[_skillId];

        userStatus.attemptTimestamp = uint48(block.timestamp);
        userStatus.submittedChallengeProofHash = bytes32(0); // Reset proof hash on re-attempt
        userStatus.validatorAddress = address(0); // Reset validator address on re-attempt

        // Handle Auto requirement immediately
        if (skill.requirementType == RequirementType.Auto) {
             userStatus.status = SkillStatus.Validated; // Auto learn implies auto validate (ValidationRequirement.None enforced in add/update)
             userStatus.validatedTimestamp = uint48(block.timestamp);
             emit SkillValidated(msg.sender, _skillId, address(0), uint48(block.timestamp)); // Validator address 0 for auto-validation
        } else {
             userStatus.status = SkillStatus.Attempting;
             emit SkillAttempted(msg.sender, _skillId, uint48(block.timestamp));
        }
    }

    function submitChallengeProof(uint256 _skillId, bytes32 _proofHash) external whenNotPaused {
        require(skills[_skillId].isActive, "DST: Skill is not active");

        UserSkillStatus storage userStatus = userSkillStatuses[msg.sender][_skillId];
        Skill storage skill = skills[_skillId];

        require(userStatus.status == SkillStatus.Attempting, "DST: Skill is not in Attempting state");
        require(skill.requirementType == RequirementType.Challenge, "DST: Skill does not require challenge proof");

        userStatus.submittedChallengeProofHash = _proofHash;

        // Handle auto-validation after challenge proof if applicable
        if (skill.validationRequirement == ValidationRequirement.AutoLearned) {
            userStatus.status = SkillStatus.Validated;
            userStatus.validatedTimestamp = uint48(block.timestamp);
            emit SkillValidated(msg.sender, _skillId, address(0), uint48(block.timestamp)); // Validator address 0 for auto-validation
        } else {
            // Stays in Attempting, waiting for validator
            // Could introduce a 'Processing' state here if needed, but Attempting works for now
        }

        emit ChallengeProofSubmitted(msg.sender, _skillId, _proofHash);
    }

     function reattemptRejectedSkill(uint256 _skillId) external whenNotPaused {
        UserSkillStatus storage userStatus = userSkillStatuses[msg.sender][_skillId];
        require(userStatus.status == SkillStatus.Rejected, "DST: Skill is not in Rejected state");

        // Reset status to Attempting, allowing the user to try again
        userStatus.status = SkillStatus.Attempting;
        // Keep attemptTimestamp or update? Let's update to track the new attempt time.
        userStatus.attemptTimestamp = uint48(block.timestamp);
        userStatus.submittedChallengeProofHash = bytes32(0); // Clear previous proof
        userStatus.validatorAddress = address(0); // Clear previous validator

        emit SkillReattempted(msg.sender, _skillId);
    }


    // --- Validator Functions ---

    function validateSkillAttempt(address _user, uint256 _skillId) external onlyValidator whenNotPaused {
        require(skills[_skillId].isActive, "DST: Skill is not active");

        UserSkillStatus storage userStatus = userSkillStatuses[_user][_skillId];
        Skill storage skill = skills[_skillId];

         // Skill must be in Attempting state
        require(userStatus.status == SkillStatus.Attempting, "DST: User skill is not in Attempting state");

        // Check if validation is required for this skill
        require(skill.validationRequirement == ValidationRequirement.AnyValidator, "DST: Skill does not require this type of validation");

        // Finalize validation
        userStatus.status = SkillStatus.Validated;
        userStatus.validatedTimestamp = uint48(block.timestamp);
        userStatus.validatorAddress = msg.sender;

        emit SkillValidated(_user, _skillId, msg.sender, uint48(block.timestamp));
    }

     function rejectSkillAttempt(address _user, uint256 _skillId, string memory _reason) external onlyValidator whenNotPaused {
        require(skills[_skillId].isActive, "DST: Skill is not active");

        UserSkillStatus storage userStatus = userSkillStatuses[_user][_skillId];

        // Skill must be in Attempting state
        require(userStatus.status == SkillStatus.Attempting, "DST: User skill is not in Attempting state");

        // Move to Rejected state
        userStatus.status = SkillStatus.Rejected;
        userStatus.validatorAddress = msg.sender; // Record which validator rejected it

        emit SkillRejected(_user, _skillId, msg.sender, _reason);
    }


    // --- View Functions (Public/External) ---

    function isValidator(address _address) external view returns (bool) {
        return validators[_address];
    }

    function getSkillTreeCount() external view returns (uint256) {
        return nextSkillTreeId - 1;
    }

    function getSkillTreeDetails(uint256 _treeId) external view returns (string memory name, uint256[] memory skillIds) {
        require(skillTrees[_treeId].skillIds.length > 0 || _treeId < nextSkillTreeId, "DST: Invalid tree ID"); // Check if tree exists
        SkillTree storage tree = skillTrees[_treeId];
        return (tree.name, tree.skillIds);
    }

    function getSkillCount() external view returns (uint256) {
        return nextSkillId - 1;
    }

    function getSkillDetails(uint256 _skillId) external view returns (
        string memory name,
        string memory description,
        uint256[] memory prerequisiteSkillIds,
        uint256 treeId,
        RequirementType requirementType,
        ValidationRequirement validationRequirement,
        bytes32 challengeDataHash,
        bool isActive
    ) {
         require(skills[_skillId].treeId != 0 || _skillId < nextSkillId, "DST: Invalid skill ID"); // Check if skill exists
         Skill storage skill = skills[_skillId];
         return (
             skill.name,
             skill.description,
             skill.prerequisiteSkillIds,
             skill.treeId,
             skill.requirementType,
             skill.validationRequirement,
             skill.challengeDataHash,
             skill.isActive
         );
    }

     function getSkillsInTree(uint256 _treeId) external view returns (uint256[] memory) {
         require(skillTrees[_treeId].skillIds.length > 0 || _treeId < nextSkillTreeId, "DST: Invalid tree ID");
         return skillTrees[_treeId].skillIds;
     }

    function getUserSkillStatus(address _user, uint256 _skillId) external view returns (
        SkillStatus status,
        uint48 attemptTimestamp,
        uint48 validatedTimestamp,
        bytes32 submittedChallengeProofHash,
        address validatorAddress
    ) {
        // No require here, returns default values if skill/user status doesn't exist (status will be Locked=0)
        UserSkillStatus storage userStatus = userSkillStatuses[_user][_skillId];
        return (
            userStatus.status,
            userStatus.attemptTimestamp,
            userStatus.validatedTimestamp,
            userStatus.submittedChallengeProofHash,
            userStatus.validatorAddress
        );
    }

    function checkPrerequisitesMet(address _user, uint256 _skillId) public view returns (bool) {
        Skill storage skill = skills[_skillId];
        // If skill doesn't exist or no prerequisites, return true (though addSkill validates existence)
        if (skill.prerequisiteSkillIds.length == 0) {
            return true;
        }

        // Check if user has *Validated* all prerequisites
        for (uint i = 0; i < skill.prerequisiteSkillIds.length; i++) {
            uint256 prereqId = skill.prerequisiteSkillIds[i];
            if (userSkillStatuses[_user][prereqId].status != SkillStatus.Validated) {
                return false;
            }
        }
        return true;
    }

    // Returns skills a user *could* attempt (prereqs met and not already Validated or Attempting)
    function getAvailableSkillsForUser(address _user) external view returns (uint256[] memory) {
        uint256[] memory allSkillIds = new uint256[](nextSkillId - 1);
        for (uint i = 1; i < nextSkillId; i++) {
            allSkillIds[i-1] = i;
        }

        uint256[] memory availableSkillIds = new uint256[](nextSkillId - 1); // Max possible size
        uint256 availableCount = 0;

        for (uint i = 0; i < allSkillIds.length; i++) {
            uint256 skillId = allSkillIds[i];
             Skill storage skill = skills[skillId];

            // Skip inactive skills or skills that don't exist (shouldn't happen with nextSkillId logic, but safe)
            if (skill.treeId == 0 && skillId >= nextSkillId) continue;
             if (!skill.isActive) continue;

            SkillStatus userStatus = userSkillStatuses[_user][skillId].status;

            // A skill is available if:
            // 1. It's not already Validated.
            // 2. It's not currently being Attempted.
            // 3. Its prerequisites are met OR it has no prerequisites.
            // 4. Its status is Locked, Available, or Rejected (meaning it hasn't been Validated or is not currently Attempting).

            if (userStatus != SkillStatus.Validated && userStatus != SkillStatus.Attempting) {
                 // Check prerequisites only if the skill isn't already marked as Available (implies prereqs met)
                 // Or if it's Locked or Rejected (need to re-check or check for the first time)
                 if (userStatus == SkillStatus.Available || userStatus == SkillStatus.Rejected || checkPrerequisitesMet(_user, skillId)) {
                     availableSkillIds[availableCount] = skillId;
                     availableCount++;
                 }
            }
        }

        // Copy to a correctly sized array
        uint256[] memory result = new uint256[](availableCount);
        for (uint i = 0; i < availableCount; i++) {
            result[i] = availableSkillIds[i];
        }
        return result;
    }


    // Note: This could be gas-intensive for users with many skills.
    // A better approach for frontends is to query status for specific skills or trees.
     function getUserSkillsByStatus(address _user, SkillStatus _status) external view returns (uint256[] memory) {
         uint256[] memory matchingSkillIds = new uint256[](nextSkillId - 1); // Max possible size
         uint256 count = 0;

         // Iterate through all possible skill IDs
         for (uint i = 1; i < nextSkillId; i++) {
             if (userSkillStatuses[_user][i].status == _status) {
                 matchingSkillIds[count] = i;
                 count++;
             }
         }

         // Copy to a correctly sized array
         uint256[] memory result = new uint256[](count);
         for (uint i = 0; i < count; i++) {
             result[i] = matchingSkillIds[i];
         }
         return result;
     }


    function getValidators() external view returns (address[] memory) {
        return validatorList;
    }

    // --- Pausable Functions ---

    function pauseContract() external onlyOwner {
        _pause();
    }

    function unpauseContract() external onlyOwner {
        _unpause();
    }
}
```