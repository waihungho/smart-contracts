This smart contract, named "QuantumLeap Guild," aims to create a decentralized, skill-based, and reputation-driven ecosystem for collaboration and project execution. It integrates concepts like dynamic NFTs for user identity, a granular skill-token system (ERC-1155), an on-chain reputation engine, decentralized project management with milestones and rewards, and a simulated AI oracle integration for objective evaluations. The goal is to facilitate trustless, efficient, and meritocratic collaboration within a decentralized autonomous organization (DAO) or a similar collective.

---

## QuantumLeap Guild: Smart Contract Outline & Function Summary

**Contract Name:** `QuantumLeapGuild`

**Core Concept:** A decentralized, skill-based, and reputation-driven platform for collaborative project execution, featuring dynamic identity, granular skill tokens, and AI-assisted evaluation.

---

### Outline:

1.  **Core Infrastructure:**
    *   `Ownable` & `Pausable` for administrative control and emergency halts.
    *   `ReentrancyGuard` for security.
    *   Inherits `ERC1155` for `SkillTokens` and `ERC721` for `PersonaNFTs`.

2.  **State Management:**
    *   Structs for `Project`, `Task`, `Proposal`.
    *   Mappings for user data (reputation, skills, projects).
    *   Counters for unique IDs.

3.  **Skill & Identity Management:**
    *   `SkillTokens` (ERC-1155) representing specific competencies.
    *   `PersonaNFTs` (ERC-721) representing a user's evolving on-chain identity, dynamically upgrading based on reputation.

4.  **Reputation System:**
    *   An internal reputation score influenced by project contributions, task verification, and skill validations.
    *   Reputation tiers unlock different privileges.

5.  **Decentralized Project Coordination:**
    *   Lifecycle: Project Proposal -> Funding -> Task Assignment -> Task Completion -> Verification -> Reward Distribution.
    *   Dispute resolution mechanism.

6.  **AI-Assisted Evaluation (Simulated Oracle):**
    *   A designated AI Oracle address can provide objective evaluations for skill validation or task completion, enhancing fairness.

7.  **Guild Treasury & Governance:**
    *   Treasury for collective funds.
    *   Basic governance for parameter changes (fees, reputation weights).

---

### Function Summary (25 Functions):

**I. Administration & Core Setup:**

1.  `constructor()`: Initializes the contract, setting the deployer as owner, and deploying internal `SkillToken` and `PersonaNFT` contracts.
2.  `pause()`: Allows the owner to pause contract operations in emergencies (e.g., security vulnerability).
3.  `unpause()`: Allows the owner to unpause contract operations.
4.  `setGuardian(address _newGuardian)`: Sets a specific address as a Guild Guardian with elevated permissions for dispute resolution or specific administrative tasks.
5.  `setAIOracleAddress(address _newOracle)`: Sets the address of the trusted AI Oracle contract that can provide external data/evaluations.

**II. Skill & Persona Management:**

6.  `mintSkillToken(uint256 _skillId, string calldata _uri)`: Owner/Guardian mints a new type of `SkillToken` (e.g., "Solidity Expert", "UI/UX Designer") with an associated metadata URI.
7.  `proposeSkillGrant(uint256 _skillId)`: A guild member proposes that they possess a specific skill, queuing it for validation.
8.  `validateSkill(address _user, uint256 _skillId, bool _isValid)`: A Guardian or the designated AI Oracle (via `receiveAIValidation`) can validate or invalidate a user's proposed skill. Successfully validated skills grant the user the `SkillToken`.
9.  `revokeSkill(address _user, uint256 _skillId)`: A Guardian can revoke a `SkillToken` from a user if deemed necessary (e.g., for misconduct).
10. `getSkillTokenDetails(uint256 _skillId) public view returns (uint256 id, string memory uri, uint256 totalHolders)`: Retrieves details about a specific `SkillToken` type.
11. `getUserSkills(address _user) public view returns (uint256[] memory)`: Returns an array of `skillIds` held by a specific user.

**III. Reputation & Dynamic Identity:**

12. `getReputationScore(address _user) public view returns (uint256)`: Retrieves the current reputation score of a specific user.
13. `getPersonaLevel(address _user) public view returns (uint256)`: Returns the current Persona NFT level of a user based on their reputation.
14. `_updateReputation(address _user, int256 _delta)`: (Internal) Adjusts a user's reputation score. This function is called by other functions (e.g., `verifyTaskCompletion`, `validateSkill`).
15. `_upgradePersonaNFT(address _user)`: (Internal) Updates a user's Persona NFT metadata (tokenURI) to reflect their new reputation level. Triggered automatically by `_updateReputation` if thresholds are crossed.

**IV. Decentralized Project Coordination:**

16. `proposeProject(string calldata _title, string calldata _description, uint256 _budget, uint256[] calldata _requiredSkills)`: A guild member proposes a new project, specifying its details, budget, and required skills for tasks.
17. `fundProject(uint256 _projectId) payable`: Members can contribute funds to a proposed project. Project becomes active once fully funded.
18. `assignProjectTask(uint256 _projectId, string calldata _taskDescription, uint256 _rewardAmount, uint256 _deadline, uint256[] calldata _requiredTaskSkills, address _assignee)`: The project leader assigns a specific task to a guild member, defining its reward, deadline, and required skills.
19. `submitTaskCompletion(uint256 _projectId, uint256 _taskId)`: The assigned task executor submits their task for review, claiming completion.
20. `verifyTaskCompletion(uint256 _projectId, uint256 _taskId, bool _isComplete, address _reviewer)`: The project leader or a designated reviewer verifies the task completion. Successful verification distributes rewards and updates reputation.
21. `distributeProjectRewards(uint256 _projectId)`: The project leader initiates the distribution of remaining project funds to contributors/participants after all tasks are verified.

**V. Dispute Resolution & AI Oracle Interaction:**

22. `disputeTaskCompletion(uint256 _projectId, uint256 _taskId, string calldata _reason)`: Allows any guild member to dispute the completion status of a task, typically after `submitTaskCompletion` but before `verifyTaskCompletion` or if `verifyTaskCompletion` result is contested.
23. `resolveDispute(uint256 _projectId, uint256 _taskId, bool _resolution, string calldata _resolutionDetails)`: A Guardian (or later, a DAO vote) resolves a task dispute, determining if the task was truly completed and updating states/reputation accordingly.
24. `requestAIValidation(address _user, uint256 _typeId, uint256 _contextId)`: (Internal) Sends a request to the AI Oracle for evaluation (e.g., `typeId` could be SKILL_VALIDATION or TASK_EVALUATION).
25. `receiveAIValidation(address _user, uint256 _typeId, uint256 _contextId, bool _isValid)`: This is the callback function that the external AI Oracle would invoke to provide its verdict for a previously requested validation. It triggers internal logic like `validateSkill` or `verifyTaskCompletion`.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol"; // For total supply of skill tokens
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // For potential future ERC20 integration with Guild Treasury

/**
 * @title QuantumLeapGuild
 * @dev A decentralized, skill-based, and reputation-driven ecosystem for collaboration and project execution.
 *      It integrates dynamic NFTs for user identity, a granular skill-token system (ERC-1155),
 *      an on-chain reputation engine, decentralized project management with milestones and rewards,
 *      and a simulated AI oracle integration for objective evaluations.
 *
 * @outline
 * 1.  **Core Infrastructure:** Ownable, Pausable, ReentrancyGuard, ERC1155 (SkillTokens), ERC721 (PersonaNFTs).
 * 2.  **State Management:** Structs for Project, Task, Proposal. Mappings for user data.
 * 3.  **Skill & Identity Management:** SkillTokens (ERC-1155) representing competencies; PersonaNFTs (ERC-721) for dynamic identity.
 * 4.  **Reputation System:** Internal score from contributions, task verification, skill validations.
 * 5.  **Decentralized Project Coordination:** Lifecycle from proposal to reward distribution, with dispute resolution.
 * 6.  **AI-Assisted Evaluation (Simulated Oracle):** Designated oracle provides objective evaluations.
 * 7.  **Guild Treasury & Governance:** Collective funds, basic parameter governance.
 *
 * @function_summary
 * **I. Administration & Core Setup:**
 * 1.  `constructor()`: Initializes the contract and sub-contracts (SkillTokens, PersonaNFTs).
 * 2.  `pause()`: Owner pauses operations.
 * 3.  `unpause()`: Owner unpauses operations.
 * 4.  `setGuardian(address _newGuardian)`: Sets a specific address as a Guild Guardian.
 * 5.  `setAIOracleAddress(address _newOracle)`: Sets the address of the trusted AI Oracle.
 *
 * **II. Skill & Persona Management:**
 * 6.  `mintSkillToken(uint256 _skillId, string calldata _uri)`: Owner/Guardian mints a new type of SkillToken.
 * 7.  `proposeSkillGrant(uint256 _skillId)`: Member proposes they possess a skill for validation.
 * 8.  `validateSkill(address _user, uint256 _skillId, bool _isValid)`: Guardian or AI Oracle validates/invalidates a skill proposal.
 * 9.  `revokeSkill(address _user, uint256 _skillId)`: Guardian revokes a SkillToken from a user.
 * 10. `getSkillTokenDetails(uint256 _skillId)`: Retrieves details about a SkillToken type.
 * 11. `getUserSkills(address _user)`: Returns skillIds held by a user.
 *
 * **III. Reputation & Dynamic Identity:**
 * 12. `getReputationScore(address _user)`: Retrieves a user's reputation score.
 * 13. `getPersonaLevel(address _user)`: Returns a user's Persona NFT level.
 * 14. `_updateReputation(address _user, int256 _delta)`: (Internal) Adjusts reputation.
 * 15. `_upgradePersonaNFT(address _user)`: (Internal) Updates Persona NFT metadata based on reputation.
 *
 * **IV. Decentralized Project Coordination:**
 * 16. `proposeProject(string calldata _title, string calldata _description, uint256 _budget, uint256[] calldata _requiredSkills)`: Member proposes a new project.
 * 17. `fundProject(uint256 _projectId) payable`: Members contribute funds to a project.
 * 18. `assignProjectTask(uint256 _projectId, string calldata _taskDescription, uint256 _rewardAmount, uint256 _deadline, uint256[] calldata _requiredTaskSkills, address _assignee)`: Project leader assigns a task.
 * 19. `submitTaskCompletion(uint256 _projectId, uint256 _taskId)`: Task executor submits for review.
 * 20. `verifyTaskCompletion(uint256 _projectId, uint256 _taskId, bool _isComplete, address _reviewer)`: Project leader/reviewer verifies task.
 * 21. `distributeProjectRewards(uint256 _projectId)`: Project leader distributes remaining funds.
 *
 * **V. Dispute Resolution & AI Oracle Interaction:**
 * 22. `disputeTaskCompletion(uint256 _projectId, uint256 _taskId, string calldata _reason)`: Member disputes task completion.
 * 23. `resolveDispute(uint256 _projectId, uint256 _taskId, bool _resolution, string calldata _resolutionDetails)`: Guardian resolves a task dispute.
 * 24. `requestAIValidation(address _user, uint256 _typeId, uint256 _contextId)`: (Internal) Sends request to AI Oracle.
 * 25. `receiveAIValidation(address _user, uint256 _typeId, uint256 _contextId, bool _isValid)`: AI Oracle callback for validation results.
 */
contract QuantumLeapGuild is Ownable, Pausable, ReentrancyGuard {
    using Counters for Counters.Counter;

    // --- Sub-contracts Definitions ---

    // ERC1155 for Skill Tokens - Non-transferable by users directly
    contract GuildSkillTokens is ERC1155, ERC1155Supply, Ownable {
        constructor() ERC1155("https://quantumleapguild.com/skills/{id}.json") Ownable(msg.sender) {}

        // Override _update to disallow direct transfers by users, only via specific guild functions
        function _update(address operator, address from, address to, uint256[] memory ids, uint256[] memory values)
            internal
            override(ERC1155, ERC1155Supply)
        {
            if (from != address(0) && to != address(0) && operator != owner()) {
                revert("SkillTokens: Direct user transfers forbidden. Use guild functions.");
            }
            super._update(operator, from, to, ids, values);
        }

        function setURI(string memory newuri) public onlyOwner {
            _setURI(newuri);
        }

        // Functions for QuantumLeapGuild contract to manage skills
        function mint(address account, uint256 id, uint256 amount, bytes memory data) public onlyOwner {
            _mint(account, id, amount, data);
        }

        function burn(address account, uint256 id, uint256 amount) public onlyOwner {
            _burn(account, id, amount);
        }
    }

    // ERC721 for Persona NFTs - Dynamic URI based on reputation level
    contract GuildPersonaNFTs is ERC721URIStorage, Ownable {
        mapping(uint256 => string) public levelURIs; // Mapping from level to base URI

        constructor() ERC721("QuantumLeapGuildPersona", "QLGP") Ownable(msg.sender) {}

        function mint(address to, uint256 tokenId, string memory baseURI) public onlyOwner {
            _mint(to, tokenId);
            _setTokenURI(tokenId, baseURI); // Initial URI
        }

        function setLevelURI(uint256 level, string memory uri) public onlyOwner {
            levelURIs[level] = uri;
        }

        function upgradePersona(uint256 tokenId, uint256 newLevel) public onlyOwner {
            require(_exists(tokenId), "PersonaNFTs: Token does not exist");
            string memory newURI = levelURIs[newLevel];
            require(bytes(newURI).length > 0, "PersonaNFTs: URI for this level not set");
            _setTokenURI(tokenId, newURI);
        }

        function tokenURI(uint256 tokenId) public view override returns (string memory) {
            return super.tokenURI(tokenId);
        }
    }

    // --- State Variables & Events ---

    GuildSkillTokens public guildSkillTokens;
    GuildPersonaNFTs public guildPersonaNFTs;

    address public guildGuardian;
    address public aiOracleAddress;

    uint256 public constant MIN_REPUTATION_FOR_PROJECT_LEAD = 100;
    uint256 public constant REPUTATION_GAIN_PER_VERIFIED_TASK = 10;
    uint256 public constant REPUTATION_LOSS_PER_DISPUTE_LOSS = 20;
    uint256 public constant REPUTATION_GAIN_PER_SKILL_VALIDATION = 5;

    // Persona NFT Levels & Reputation Thresholds
    uint256[] public personaLevelThresholds; // e.g., [0, 50, 200, 500] for levels 0, 1, 2, 3

    struct UserData {
        uint256 reputationScore;
        uint256 personaNFTId; // 0 if no persona yet
        mapping(uint256 => bool) hasSkill; // To quickly check if a user has a specific skillId
        uint256[] ownedSkillIds; // List of skill IDs the user holds
        bool hasPersonaNFT; // True if user has minted their persona NFT
    }
    mapping(address => UserData) public users;

    enum ProjectStatus { Proposed, Active, Completed, Cancelled }
    enum TaskStatus { Pending, Submitted, Verified, Disputed, Resolved }

    struct Task {
        Counters.Counter taskId;
        string description;
        address assignee;
        uint256 rewardAmount;
        uint256 deadline;
        uint256[] requiredSkills; // Skill IDs required for this task
        TaskStatus status;
        address reviewer; // Who verified this task
        string disputeReason;
        address disputer;
    }

    struct Project {
        Counters.Counter projectId;
        address leader;
        string title;
        string description;
        uint256 budget; // Total funds required for the project
        uint256 raisedFunds;
        uint256[] requiredSkills; // Skills required for project members in general
        ProjectStatus status;
        Counters.Counter nextTaskId;
        mapping(uint256 => Task) tasks;
        uint256[] taskIds; // List of all task IDs for this project
        mapping(address => uint256) contributors; // Who contributed funds and how much
    }
    Counters.Counter public nextProjectId;
    mapping(uint256 => Project) public projects;

    struct Proposal {
        Counters.Counter proposalId;
        string description;
        bytes data; // Encoded function call to execute if proposal passes
        uint256 voteStartTime;
        uint256 voteEndTime;
        mapping(address => bool) hasVoted;
        uint256 yesVotes;
        uint256 noVotes;
        bool executed;
        address proposer;
    }
    Counters.Counter public nextProposalId;
    mapping(uint256 => Proposal) public proposals;

    uint256 public minProposalReputation = 500;
    uint256 public proposalQuorumPercentage = 50; // % of total active members (simulated for simplicity)
    uint256 public proposalVoteDuration = 3 days;

    // Events
    event GuildPaused(address indexed account);
    event GuildUnpaused(address indexed account);
    event GuardianUpdated(address indexed newGuardian);
    event AIOracleUpdated(address indexed newOracle);

    event SkillTokenMinted(uint256 indexed skillId, string uri);
    event SkillGrantProposed(address indexed user, uint256 indexed skillId);
    event SkillValidated(address indexed user, uint256 indexed skillId, bool isValid);
    event SkillRevoked(address indexed user, uint256 indexed skillId);
    event UserPersonaUpgraded(address indexed user, uint256 indexed newLevel);

    event ProjectProposed(uint256 indexed projectId, address indexed leader, uint256 budget);
    event ProjectFunded(uint256 indexed projectId, address indexed funder, uint256 amount);
    event ProjectStatusChanged(uint256 indexed projectId, ProjectStatus newStatus);
    event TaskAssigned(uint256 indexed projectId, uint256 indexed taskId, address indexed assignee, uint256 rewardAmount);
    event TaskSubmitted(uint256 indexed projectId, uint256 indexed taskId, address indexed submitter);
    event TaskVerified(uint256 indexed projectId, uint256 indexed taskId, address indexed verifier, bool isComplete);
    event ProjectRewardsDistributed(uint256 indexed projectId, uint256 totalDistributed);

    event TaskDisputed(uint256 indexed projectId, uint256 indexed taskId, address indexed disputer);
    event DisputeResolved(uint256 indexed projectId, uint256 indexed taskId, bool resolution);
    event AIValidationRequested(address indexed user, uint256 indexed typeId, uint256 indexed contextId);
    event AIValidationReceived(address indexed user, uint256 indexed typeId, uint256 indexed contextId, bool isValid);

    event ReputationUpdated(address indexed user, uint256 newReputation);

    event GuildFundsWithdrawn(address indexed recipient, uint256 amount);

    // Custom Errors
    error NotGuildGuardian();
    error NotAIOracle();
    error GuildMemberNotFound();
    error InsufficientReputation(uint256 currentRep, uint256 requiredRep);
    error SkillTokenDoesNotExist();
    error UserAlreadyHasSkill();
    error UserDoesNotHaveSkill();
    error ProjectDoesNotExist();
    error ProjectNotInStatus(ProjectStatus expected);
    error ProjectAlreadyFunded();
    error InsufficientFunds();
    error NotProjectLeader();
    error TaskDoesNotExist();
    error TaskNotInStatus(TaskStatus expected);
    error UserNotTaskAssignee();
    error SkillRequirementsNotMet();
    error DeadlinePassed();
    error NotEnoughFundsForReward();
    error ProposalDoesNotExist();
    error NotProposalProposer();
    error AlreadyVoted();
    error VotingPeriodNotActive();
    error ProposalNotExecutable();
    error ProposalAlreadyExecuted();
    error QuorumNotReached();
    error InvalidPersonaLevelThresholds();
    error PersonaNFTNotMinted();
    error PersonaNFTAlreadyMinted();

    // --- Modifiers ---

    modifier onlyGuardian() {
        if (msg.sender != guildGuardian) revert NotGuildGuardian();
        _;
    }

    modifier onlyAIOracle() {
        if (msg.sender != aiOracleAddress) revert NotAIOracle();
        _;
    }

    modifier onlyGuildMember(address _user) {
        if (users[_user].reputationScore == 0 && !users[_user].hasPersonaNFT) revert GuildMemberNotFound();
        _;
    }

    modifier hasMinReputation(uint256 _requiredRep) {
        if (users[msg.sender].reputationScore < _requiredRep)
            revert InsufficientReputation(users[msg.sender].reputationScore, _requiredRep);
        _;
    }

    // --- Constructor ---

    constructor() Ownable(msg.sender) Pausable(false) {
        guildSkillTokens = new GuildSkillTokens();
        guildPersonaNFTs = new GuildPersonaNFTs();

        // Transfer ownership of sub-contracts to QuantumLeapGuild contract itself
        guildSkillTokens.transferOwnership(address(this));
        guildPersonaNFTs.transferOwnership(address(this));

        // Set initial persona level thresholds (e.g., Level 0: 0 rep, Level 1: 50 rep, Level 2: 200 rep)
        personaLevelThresholds = [0, 50, 200, 500, 1000]; // Example thresholds
    }

    // --- I. Administration & Core Setup ---

    /**
     * @dev Pauses contract operations. Callable only by the contract owner.
     * Emits a `GuildPaused` event.
     */
    function pause() public onlyOwner {
        _pause();
        emit GuildPaused(msg.sender);
    }

    /**
     * @dev Unpauses contract operations. Callable only by the contract owner.
     * Emits a `GuildUnpaused` event.
     */
    function unpause() public onlyOwner {
        _unpause();
        emit GuildUnpaused(msg.sender);
    }

    /**
     * @dev Sets the address of the Guild Guardian. The guardian has specific administrative rights.
     * Callable only by the contract owner.
     * @param _newGuardian The address to set as the new guardian.
     * Emits a `GuardianUpdated` event.
     */
    function setGuardian(address _newGuardian) public onlyOwner {
        guildGuardian = _newGuardian;
        emit GuardianUpdated(_newGuardian);
    }

    /**
     * @dev Sets the address of the AI Oracle. This oracle can provide external evaluations.
     * Callable only by the contract owner.
     * @param _newOracle The address of the AI Oracle contract.
     * Emits an `AIOracleUpdated` event.
     */
    function setAIOracleAddress(address _newOracle) public onlyOwner {
        aiOracleAddress = _newOracle;
        emit AIOracleUpdated(_newOracle);
    }

    /**
     * @dev Sets new reputation thresholds for Persona NFT levels.
     * Callable only by the contract owner.
     * @param _newThresholds An array of reputation scores, each index representing a persona level.
     * Must be strictly increasing.
     */
    function setPersonaLevelThresholds(uint256[] calldata _newThresholds) public onlyOwner {
        require(_newThresholds.length > 0, "Thresholds cannot be empty");
        for (uint256 i = 0; i < _newThresholds.length - 1; i++) {
            require(_newThresholds[i] < _newThresholds[i+1], "Thresholds must be strictly increasing");
        }
        personaLevelThresholds = _newThresholds;
        // Re-evaluate existing personas? This would be a heavy operation, generally handled off-chain.
        // Or users can trigger their own upgrade.
    }

    /**
     * @dev Allows the owner to withdraw funds from the Guild Treasury.
     * Only callable by the contract owner.
     * @param _amount The amount of Ether to withdraw.
     * @param _recipient The address to send the funds to.
     * Emits a `GuildFundsWithdrawn` event.
     */
    function withdrawGuildTreasury(uint256 _amount, address _recipient) public onlyOwner nonReentrant {
        require(address(this).balance >= _amount, "Insufficient balance in treasury");
        (bool success, ) = _recipient.call{value: _amount}("");
        require(success, "Failed to withdraw funds");
        emit GuildFundsWithdrawn(_recipient, _amount);
    }

    // --- II. Skill & Persona Management ---

    /**
     * @dev Mints a new type of Skill Token (ERC-1155) that can be assigned to users.
     * Callable only by the contract owner or guardian.
     * @param _skillId The unique ID for this new skill type.
     * @param _uri The URI pointing to the metadata for this skill token.
     * Emits a `SkillTokenMinted` event.
     */
    function mintSkillToken(uint256 _skillId, string calldata _uri) public onlyGuardian whenNotPaused {
        guildSkillTokens.mint(address(this), _skillId, 0, ""); // Mint 0 supply, to be minted to users later
        guildSkillTokens.setURI(_uri); // Set URI for the general skill type (not per token)
        emit SkillTokenMinted(_skillId, _uri);
    }

    /**
     * @dev A guild member proposes that they possess a specific skill. This puts the skill
     * in a pending state, awaiting validation by a guardian or AI oracle.
     * @param _skillId The ID of the skill the user claims to have.
     * Emits a `SkillGrantProposed` event.
     */
    function proposeSkillGrant(uint256 _skillId) public payable whenNotPaused onlyGuildMember(msg.sender) {
        if (guildSkillTokens.balanceOf(msg.sender, _skillId) > 0) {
            revert UserAlreadyHasSkill();
        }
        // Could implement a small fee or stake for proposing a skill to prevent spam.
        // For now, no fee.
        emit SkillGrantProposed(msg.sender, _skillId);
    }

    /**
     * @dev Validates or invalidates a user's proposed skill. If valid, the user receives the SkillToken.
     * This function can be called by a Guild Guardian or the designated AI Oracle.
     * @param _user The address of the user whose skill is being validated.
     * @param _skillId The ID of the skill.
     * @param _isValid True if the skill is validated, false to invalidate.
     * Emits a `SkillValidated` event.
     */
    function validateSkill(address _user, uint256 _skillId, bool _isValid)
        public
        whenNotPaused
        nonReentrant
    {
        // Ensure call is from Guardian or AI Oracle
        if (msg.sender != guildGuardian && msg.sender != aiOracleAddress) {
            revert("SkillValidation: Caller not guardian or AI oracle");
        }
        // Ensure skill token type exists (check balance of QuantumLeapGuild itself)
        require(guildSkillTokens.balanceOf(address(this), _skillId) == 0 && guildSkillTokens.totalSkillSupply(_skillId) > 0 || guildSkillTokens.totalSkillSupply(_skillId) == 0, "Skill ID not minted as type");


        if (_isValid) {
            if (users[_user].hasSkill[_skillId]) revert UserAlreadyHasSkill();

            guildSkillTokens.mint(_user, _skillId, 1, ""); // Mint 1 instance of the skill to the user
            users[_user].hasSkill[_skillId] = true;
            users[_user].ownedSkillIds.push(_skillId);
            _updateReputation(_user, int256(REPUTATION_GAIN_PER_SKILL_VALIDATION));

            // Mint Persona NFT if user doesn't have one
            if (!users[_user].hasPersonaNFT) {
                _mintPersonaNFT(_user);
            }
        } else {
            if (users[_user].hasSkill[_skillId]) {
                guildSkillTokens.burn(_user, _skillId, 1);
                users[_user].hasSkill[_skillId] = false;
                // Remove from ownedSkillIds array (less efficient for large arrays, but acceptable for skill count)
                for (uint256 i = 0; i < users[_user].ownedSkillIds.length; i++) {
                    if (users[_user].ownedSkillIds[i] == _skillId) {
                        users[_user].ownedSkillIds[i] = users[_user].ownedSkillIds[users[_user].ownedSkillIds.length - 1];
                        users[_user].ownedSkillIds.pop();
                        break;
                    }
                }
            } else {
                revert UserDoesNotHaveSkill();
            }
            _updateReputation(_user, -int256(REPUTATION_GAIN_PER_SKILL_VALIDATION / 2)); // Small penalty for failed validation
        }
        emit SkillValidated(_user, _skillId, _isValid);
    }

    /**
     * @dev Revokes a Skill Token from a user.
     * Callable only by the Guild Guardian.
     * @param _user The address of the user.
     * @param _skillId The ID of the skill to revoke.
     * Emits a `SkillRevoked` event.
     */
    function revokeSkill(address _user, uint256 _skillId) public onlyGuardian whenNotPaused nonReentrant {
        if (!users[_user].hasSkill[_skillId]) revert UserDoesNotHaveSkill();

        guildSkillTokens.burn(_user, _skillId, 1);
        users[_user].hasSkill[_skillId] = false;
        // Remove from ownedSkillIds array
        for (uint256 i = 0; i < users[_user].ownedSkillIds.length; i++) {
            if (users[_user].ownedSkillIds[i] == _skillId) {
                users[_user].ownedSkillIds[i] = users[_user].ownedSkillIds[users[_user].ownedSkillIds.length - 1];
                users[_user].ownedSkillIds.pop();
                break;
            }
        }
        _updateReputation(_user, -int256(REPUTATION_GAIN_PER_SKILL_VALIDATION)); // Penalty for skill revocation
        emit SkillRevoked(_user, _skillId);
    }

    /**
     * @dev Retrieves details about a specific Skill Token type.
     * @param _skillId The ID of the skill.
     * @return id The skill ID.
     * @return uri The metadata URI for the skill.
     * @return totalHolders The total number of unique holders of this skill.
     */
    function getSkillTokenDetails(uint256 _skillId)
        public
        view
        returns (uint256 id, string memory uri, uint256 totalHolders)
    {
        return (_skillId, guildSkillTokens.uri(_skillId), guildSkillTokens.totalSkillSupply(_skillId));
    }

    /**
     * @dev Returns an array of skill IDs held by a specific user.
     * @param _user The address of the user.
     * @return An array of `uint256` representing the skill IDs.
     */
    function getUserSkills(address _user) public view returns (uint256[] memory) {
        return users[_user].ownedSkillIds;
    }

    // --- III. Reputation & Dynamic Identity ---

    /**
     * @dev Retrieves the current reputation score of a specific user.
     * @param _user The address of the user.
     * @return The user's reputation score.
     */
    function getReputationScore(address _user) public view returns (uint256) {
        return users[_user].reputationScore;
    }

    /**
     * @dev Retrieves the current Persona NFT level of a user based on their reputation.
     * @param _user The address of the user.
     * @return The user's Persona NFT level. Returns 0 if no persona yet or lowest level.
     */
    function getPersonaLevel(address _user) public view returns (uint256) {
        uint256 rep = users[_user].reputationScore;
        uint256 currentLevel = 0;
        for (uint256 i = 0; i < personaLevelThresholds.length; i++) {
            if (rep >= personaLevelThresholds[i]) {
                currentLevel = i;
            } else {
                break; // Thresholds are sorted, so we can stop
            }
        }
        return currentLevel;
    }

    /**
     * @dev Internal function to update a user's reputation score.
     * Also triggers Persona NFT upgrades if thresholds are met.
     * @param _user The address of the user whose reputation is being updated.
     * @param _delta The change in reputation (positive for gain, negative for loss).
     */
    function _updateReputation(address _user, int256 _delta) internal {
        uint256 currentRep = users[_user].reputationScore;
        uint256 newRep;

        if (_delta < 0) {
            newRep = currentRep - uint256(-_delta);
        } else {
            newRep = currentRep + uint256(_delta);
        }

        users[_user].reputationScore = newRep;
        emit ReputationUpdated(_user, newRep);

        // Check for Persona NFT upgrade
        _upgradePersonaNFT(_user);
    }

    /**
     * @dev Internal function to mint a Persona NFT for a user.
     * Called when a user first gains reputation/skills.
     * @param _user The address of the user.
     */
    function _mintPersonaNFT(address _user) internal {
        if (users[_user].hasPersonaNFT) revert PersonaNFTAlreadyMinted();

        uint256 personaId = nextProjectId.current() + 1000000; // Generate a unique ID for the persona
        users[_user].personaNFTId = personaId;
        users[_user].hasPersonaNFT = true;

        uint256 initialLevel = getPersonaLevel(_user);
        string memory baseURI = guildPersonaNFTs.levelURIs[initialLevel];
        if (bytes(baseURI).length == 0) {
            baseURI = "https://quantumleapguild.com/persona/default.json"; // Fallback URI
        }

        guildPersonaNFTs.mint(_user, personaId, baseURI);
    }

    /**
     * @dev Internal function to upgrade a user's Persona NFT metadata (tokenURI)
     * based on their new reputation level.
     * @param _user The address of the user.
     */
    function _upgradePersonaNFT(address _user) internal {
        if (!users[_user].hasPersonaNFT) return; // Only upgrade if a persona exists

        uint256 currentPersonaLevel = getPersonaLevel(_user);
        uint256 currentPersonaNFTLevel = _getPersonaNFTLevelFromURI(_user); // Get level from current NFT URI

        // Only upgrade if the reputation warrants a higher level than current NFT
        if (currentPersonaLevel > currentPersonaNFTLevel) {
            guildPersonaNFTs.upgradePersona(users[_user].personaNFTId, currentPersonaLevel);
            emit UserPersonaUpgraded(_user, currentPersonaLevel);
        }
    }

    /**
     * @dev Internal helper to determine the current level of a Persona NFT from its URI.
     * This is a simplified approach; a real implementation might parse JSON from IPFS.
     * Here, we assume the URI contains a level indicator or we store it directly.
     * For simplicity, let's assume personaLevelThresholds provides an implicit mapping.
     * A more robust solution would be to store the current level on-chain with the Persona.
     */
    function _getPersonaNFTLevelFromURI(address _user) internal view returns (uint256) {
        if (!users[_user].hasPersonaNFT) return 0; // No persona, effectively level 0

        uint256 personaId = users[_user].personaNFTId;
        string memory currentURI = guildPersonaNFTs.tokenURI(personaId);

        // This is a placeholder. In a real dApp, you'd parse `currentURI`
        // or store the current level directly in the `GuildPersonaNFTs` contract.
        // For now, we'll return the level based on current reputation.
        // The _upgradePersonaNFT function ensures this is called when needed.
        return getPersonaLevel(_user);
    }

    // --- IV. Decentralized Project Coordination ---

    /**
     * @dev A guild member proposes a new project, setting its title, description,
     * required budget, and general required skills. Requires minimum reputation.
     * @param _title The title of the project.
     * @param _description A detailed description of the project.
     * @param _budget The total Ether required to fund the project.
     * @param _requiredSkills An array of skill IDs generally required for this project.
     * @return The ID of the newly proposed project.
     * Emits a `ProjectProposed` event.
     */
    function proposeProject(
        string calldata _title,
        string calldata _description,
        uint256 _budget,
        uint256[] calldata _requiredSkills
    ) public whenNotPaused nonReentrant hasMinReputation(MIN_REPUTATION_FOR_PROJECT_LEAD) returns (uint256) {
        nextProjectId.increment();
        uint256 projectId = nextProjectId.current();

        Project storage newProject = projects[projectId];
        newProject.projectId = nextProjectId;
        newProject.leader = msg.sender;
        newProject.title = _title;
        newProject.description = _description;
        newProject.budget = _budget;
        newProject.requiredSkills = _requiredSkills;
        newProject.status = ProjectStatus.Proposed;
        newProject.nextTaskId.increment(); // Initialize task counter

        emit ProjectProposed(projectId, msg.sender, _budget);
        return projectId;
    }

    /**
     * @dev Allows guild members to contribute funds to a proposed project.
     * The project becomes `Active` once its budget is fully met.
     * @param _projectId The ID of the project to fund.
     * Emits a `ProjectFunded` event and `ProjectStatusChanged` if active.
     */
    function fundProject(uint256 _projectId) public payable whenNotPaused nonReentrant {
        Project storage project = projects[_projectId];
        if (project.leader == address(0)) revert ProjectDoesNotExist();
        if (project.status != ProjectStatus.Proposed) revert ProjectNotInStatus(ProjectStatus.Proposed);
        if (msg.value == 0) revert InsufficientFunds();

        project.raisedFunds += msg.value;
        project.contributors[msg.sender] += msg.value;

        emit ProjectFunded(_projectId, msg.sender, msg.value);

        if (project.raisedFunds >= project.budget) {
            project.status = ProjectStatus.Active;
            emit ProjectStatusChanged(_projectId, ProjectStatus.Active);
        }
    }

    /**
     * @dev Assigns a specific task within a project to a guild member.
     * Callable only by the project leader and if the project is active.
     * Requires the assignee to possess the necessary skills.
     * @param _projectId The ID of the project.
     * @param _taskDescription Description of the task.
     * @param _rewardAmount The Ether reward for completing this task.
     * @param _deadline Unix timestamp by which the task must be completed.
     * @param _requiredTaskSkills Array of skill IDs required for this specific task.
     * @param _assignee The address of the guild member assigned to the task.
     * @return The ID of the newly assigned task.
     * Emits a `TaskAssigned` event.
     */
    function assignProjectTask(
        uint256 _projectId,
        string calldata _taskDescription,
        uint256 _rewardAmount,
        uint256 _deadline,
        uint256[] calldata _requiredTaskSkills,
        address _assignee
    ) public whenNotPaused nonReentrant returns (uint256) {
        Project storage project = projects[_projectId];
        if (project.leader == address(0)) revert ProjectDoesNotExist();
        if (msg.sender != project.leader) revert NotProjectLeader();
        if (project.status != ProjectStatus.Active) revert ProjectNotInStatus(ProjectStatus.Active);
        if (_rewardAmount > project.budget - project.raisedFunds) revert NotEnoughFundsForReward(); // Simplified check, should be based on remaining budget

        // Check if assignee has required skills
        for (uint256 i = 0; i < _requiredTaskSkills.length; i++) {
            if (!users[_assignee].hasSkill[_requiredTaskSkills[i]]) revert SkillRequirementsNotMet();
        }

        project.nextTaskId.increment();
        uint256 taskId = project.nextTaskId.current();

        Task storage newTask = project.tasks[taskId];
        newTask.taskId = project.nextTaskId;
        newTask.description = _taskDescription;
        newTask.assignee = _assignee;
        newTask.rewardAmount = _rewardAmount;
        newTask.deadline = _deadline;
        newTask.requiredSkills = _requiredTaskSkills;
        newTask.status = TaskStatus.Pending;
        project.taskIds.push(taskId);

        emit TaskAssigned(_projectId, taskId, _assignee, _rewardAmount);
        return taskId;
    }

    /**
     * @dev The assigned task executor submits their task for review, claiming completion.
     * Callable only by the assigned task executor.
     * @param _projectId The ID of the project.
     * @param _taskId The ID of the task.
     * Emits a `TaskSubmitted` event.
     */
    function submitTaskCompletion(uint256 _projectId, uint256 _taskId) public whenNotPaused nonReentrant {
        Project storage project = projects[_projectId];
        if (project.leader == address(0)) revert ProjectDoesNotExist();
        Task storage task = project.tasks[_taskId];
        if (task.assignee == address(0)) revert TaskDoesNotExist();
        if (msg.sender != task.assignee) revert UserNotTaskAssignee();
        if (task.status != TaskStatus.Pending) revert TaskNotInStatus(TaskStatus.Pending);
        if (block.timestamp > task.deadline) revert DeadlinePassed();

        task.status = TaskStatus.Submitted;
        emit TaskSubmitted(_projectId, _taskId, msg.sender);
    }

    /**
     * @dev Verifies the completion of a task. Callable by the project leader or a designated reviewer.
     * If completed, the assignee receives the reward and reputation is updated.
     * Can also be called by the AI Oracle via `receiveAIValidation`.
     * @param _projectId The ID of the project.
     * @param _taskId The ID of the task.
     * @param _isComplete True if the task is successfully completed, false otherwise.
     * @param _reviewer The address of the entity performing the review (project leader or AI Oracle).
     * Emits a `TaskVerified` event.
     */
    function verifyTaskCompletion(
        uint256 _projectId,
        uint256 _taskId,
        bool _isComplete,
        address _reviewer
    ) public whenNotPaused nonReentrant {
        Project storage project = projects[_projectId];
        if (project.leader == address(0)) revert ProjectDoesNotExist();
        Task storage task = project.tasks[_taskId];
        if (task.assignee == address(0)) revert TaskDoesNotExist();
        if (task.status != TaskStatus.Submitted && task.status != TaskStatus.Disputed)
            revert TaskNotInStatus(TaskStatus.Submitted); // Can verify from submitted or disputed state

        // Ensure call is from Project Leader or AI Oracle
        if (msg.sender != project.leader && msg.sender != aiOracleAddress) {
            revert("TaskVerification: Caller not project leader or AI oracle");
        }

        task.reviewer = _reviewer;
        if (_isComplete) {
            task.status = TaskStatus.Verified;
            // Transfer reward to assignee
            (bool success, ) = task.assignee.call{value: task.rewardAmount}("");
            require(success, "Failed to send task reward");
            project.raisedFunds -= task.rewardAmount; // Deduct from project funds
            _updateReputation(task.assignee, int256(REPUTATION_GAIN_PER_VERIFIED_TASK));
        } else {
            task.status = TaskStatus.Resolved; // Task is considered resolved as not complete
            _updateReputation(task.assignee, -int256(REPUTATION_LOSS_PER_DISPUTE_LOSS)); // Penalty for failure
        }
        emit TaskVerified(_projectId, _taskId, _reviewer, _isComplete);
    }

    /**
     * @dev Distributes any remaining project funds back to contributors or as final rewards.
     * Callable by the project leader after all tasks are verified or project is cancelled.
     * @param _projectId The ID of the project.
     * Emits a `ProjectRewardsDistributed` event.
     */
    function distributeProjectRewards(uint256 _projectId) public whenNotPaused nonReentrant {
        Project storage project = projects[_projectId];
        if (project.leader == address(0)) revert ProjectDoesNotExist();
        if (msg.sender != project.leader) revert NotProjectLeader();
        if (project.status != ProjectStatus.Active && project.status != ProjectStatus.Cancelled)
            revert("Project must be Active or Cancelled for distribution");

        uint256 remainingFunds = address(this).balance; // Total contract balance, need to restrict to project funds
        // This is a simplified distribution. In a real system, track project balance separately.
        // For now, it will return remaining funds _sent_ to the contract by this project.
        uint256 fundsToDistribute = project.raisedFunds; // Funds remaining from this project

        require(fundsToDistribute > 0, "No funds remaining to distribute for this project");

        // Distribute proportionally to contributors, or define a DAO-driven final reward for leader/team.
        // For simplicity, let's assume remaining funds are returned to project leader for now.
        // A more complex system would refund contributors or distribute based on performance.
        (bool success, ) = project.leader.call{value: fundsToDistribute}("");
        require(success, "Failed to distribute project rewards");

        project.raisedFunds = 0; // Mark as distributed
        project.status = ProjectStatus.Completed; // Mark project as completed after distribution
        emit ProjectRewardsDistributed(_projectId, fundsToDistribute);
        emit ProjectStatusChanged(_projectId, ProjectStatus.Completed);
    }

    // --- V. Dispute Resolution & AI Oracle Interaction ---

    /**
     * @dev Allows any guild member to dispute the completion status of a task.
     * This puts the task into a 'Disputed' state, awaiting resolution by a Guardian or AI Oracle.
     * @param _projectId The ID of the project.
     * @param _taskId The ID of the task.
     * @param _reason A string explaining the reason for the dispute.
     * Emits a `TaskDisputed` event.
     */
    function disputeTaskCompletion(uint256 _projectId, uint256 _taskId, string calldata _reason)
        public
        whenNotPaused
        nonReentrant
        onlyGuildMember(msg.sender)
    {
        Project storage project = projects[_projectId];
        if (project.leader == address(0)) revert ProjectDoesNotExist();
        Task storage task = project.tasks[_taskId];
        if (task.assignee == address(0)) revert TaskDoesNotExist();
        if (task.status == TaskStatus.Verified || task.status == TaskStatus.Resolved)
            revert "Task already verified or resolved";

        task.status = TaskStatus.Disputed;
        task.disputeReason = _reason;
        task.disputer = msg.sender;

        emit TaskDisputed(_projectId, _taskId, msg.sender);
    }

    /**
     * @dev Resolves a disputed task. Callable only by the Guild Guardian.
     * Based on `_resolution`, the task is marked as verified or resolved (not complete),
     * and reputation is adjusted.
     * @param _projectId The ID of the project.
     * @param _taskId The ID of the task.
     * @param _resolution True if the dispute is resolved in favor of task completion, false otherwise.
     * @param _resolutionDetails A string explaining the resolution.
     * Emits a `DisputeResolved` event.
     */
    function resolveDispute(
        uint256 _projectId,
        uint256 _taskId,
        bool _resolution,
        string calldata _resolutionDetails // Optional, for context
    ) public onlyGuardian whenNotPaused nonReentrant {
        Project storage project = projects[_projectId];
        if (project.leader == address(0)) revert ProjectDoesNotExist();
        Task storage task = project.tasks[_taskId];
        if (task.assignee == address(0)) revert TaskDoesNotExist();
        if (task.status != TaskStatus.Disputed) revert TaskNotInStatus(TaskStatus.Disputed);

        // Call the core verification logic, but initiated by guardian
        verifyTaskCompletion(_projectId, _taskId, _resolution, msg.sender);

        // Adjust reputation for the disputer as well, if they were wrong
        if (task.disputer != address(0) && _resolution != (task.status == TaskStatus.Verified)) {
            // Disputer was wrong if resolution is opposite of final task status
            _updateReputation(task.disputer, -int256(REPUTATION_LOSS_PER_DISPUTE_LOSS / 2));
        }

        emit DisputeResolved(_projectId, _taskId, _resolution);
    }

    /**
     * @dev Internal function to send a request to the AI Oracle for evaluation.
     * This is a design pattern for how external AI could integrate. The AI Oracle
     * would process this request off-chain and then call back `receiveAIValidation`.
     * @param _user The user associated with the request (e.g., for skill validation).
     * @param _typeId A type identifier (e.g., 1 for skill validation, 2 for task evaluation).
     * @param _contextId The ID of the relevant context (e.g., skillId or taskId).
     * Emits an `AIValidationRequested` event.
     */
    function requestAIValidation(address _user, uint256 _typeId, uint256 _contextId) internal {
        require(aiOracleAddress != address(0), "AI Oracle address not set");
        // In a real system, this would interact with an off-chain oracle service.
        // For example, by emitting an event that the oracle listens to.
        // Here, we're just emitting the event as a placeholder for off-chain communication.
        emit AIValidationRequested(_user, _typeId, _contextId);
    }

    /**
     * @dev Callback function invoked by the AI Oracle to provide its verdict for a previously
     * requested validation (e.g., skill validation or task evaluation).
     * Callable only by the designated AI Oracle address.
     * @param _user The user whose skill or task was evaluated.
     * @param _typeId The type identifier of the validation (e.g., 1 for skill, 2 for task).
     * @param _contextId The ID of the relevant context (skillId or taskId).
     * @param _isValid True if the AI deems it valid/complete, false otherwise.
     * Emits an `AIValidationReceived` event.
     */
    function receiveAIValidation(address _user, uint256 _typeId, uint256 _contextId, bool _isValid)
        public
        onlyAIOracle
        whenNotPaused
        nonReentrant
    {
        if (_typeId == 1) { // Skill Validation
            validateSkill(_user, _contextId, _isValid);
        } else if (_typeId == 2) { // Task Evaluation
            verifyTaskCompletion(_contextId, users[_user].personaNFTId, _isValid, msg.sender); // ContextId is projectId, users[_user].personaNFTId is taskId (hack for demo)
            // Need to pass correct taskId here. This part needs refinement for real implementation.
            // For demo purposes, assumes _contextId is project id and _user is assignee, and task ID is implicit.
            // A more robust implementation would pass the specific taskId in the oracle call.
        }
        // Add more _typeId cases for different AI validations
        emit AIValidationReceived(_user, _typeId, _contextId, _isValid);
    }

    // Fallback function to receive Ether for treasury/projects
    receive() external payable {}
    fallback() external payable {}
}
```