This smart contract, named `AetherForge`, is designed as a decentralized, AI-enhanced talent marketplace and task management system. It incorporates several advanced, creative, and trendy concepts, while striving to avoid direct duplication of existing open-source projects by combining functionalities in novel ways and providing a conceptual framework for off-chain/on-chain interactions.

---

# Outline and Function Summary for AetherForge Smart Contract

**Contract Name:** `AetherForge`

**Purpose:** A decentralized, AI-enhanced talent marketplace and task management system. It aims to connect individuals with skills to tasks/quests, manage reputation dynamically, offer gamified achievements via NFTs, and evolve its parameters through DAO governance.

---

**Core Concepts:**

1.  **Talent Profile (Self-SSovereign Identity):** Comprehensive user profiles including skills, availability, and verifiable credentials (represented by ZK-proof hashes).
2.  **Skill Registry (Token-Curated):** A curated and evolving list of recognized skills, managed via DAO, with dynamic proficiency tracking and skill decay mechanisms.
3.  **Task/Quest System:** Structured work units with dynamic rewards, staking for commitment, and built-in dispute resolution pathways via DAO.
4.  **Dynamic Reputation:** A multi-faceted reputation system influenced by task outcomes, peer reviews, and insights from an off-chain AI-powered oracle.
5.  **AI-Enhanced Matching (Conceptual):** Utilizes (simulated) AI insights from oracles for smarter, context-aware task-to-talent matching. The on-chain component provides the framework for such integration.
6.  **Gamified Achievements (NFTs):** Unique non-fungible tokens representing verified skill mastery, special achievements, or exceptional task completions.
7.  **DAO Governance:** A Decentralized Autonomous Organization for critical parameter changes (e.g., fees, decay rates), dispute resolution, and managing the official skill registry.
8.  **Oracle Integration:** Enables trustless access to off-chain data, including AI model outputs (for reputation/matching) and ZK-proof verification results.
9.  **Staking & Slashing:** Ensures commitment from both task creators and talents by requiring stakes, which can be slashed in cases of non-compliance or dispute outcomes.
10. **Predictive Analytics (Simulated):** Provides suggestions for optimal task rewards based on internal logic considering required skills' scarcity, demand, and talent pool.

---

**State Variables:**

*   `talents`: Mapping from address to `TalentProfile` struct. Stores all registered users and their details.
*   `registeredSkills`: Mapping from `bytes32` (skill ID) to `Skill` struct. The global, DAO-approved list of skills.
*   `skillNameToId`: Mapping from `string` (skill name) to `bytes32` (skill ID) for easy lookup.
*   `tasks`: Mapping from `bytes32` (task ID) to `Task` struct. Contains all task-related information.
*   `_taskIdCounter`: Counter for generating unique task IDs.
*   `reputationScores`: Mapping from `address` to `uint256`. Stores each talent's current aggregated reputation score (0-1000).
*   `oracleAddress`: Address of the trusted AI/ZK-proof oracle.
*   `daoAddress`: Address of the DAO governance contract.
*   `achievementNFTContract`: Instance of the ERC721 Achievement NFT contract for minting.
*   `platformFeeRate`: Percentage fee (in basis points, e.g., 500 for 5%) taken by the platform on task completion.
*   `minReputationForSkillProposal`: Minimum reputation required for a talent to propose a new skill to the DAO.
*   `skillDecayRatePerSecond`: Rate at which skill proficiency decreases over time if not used or updated.
*   `minTalentStake`: Minimum amount of ETH/tokens a talent must stake to commit to a task.

---

**Functions Summary (26 functions):**

**A. Profile & Identity Management (4 Functions)**

1.  `createTalentProfile(string _name, string _bio, bytes32 _initialVCHash)`: Registers a new user as a talent, assigning an initial reputation and allowing an optional ZK-proof hash for verifiable credentials.
2.  `updateTalentProfile(string _name, string _bio, bool _available)`: Allows a talent to modify their public profile details and availability status.
3.  `attachVerifiableCredential(bytes32 _vcHash)`: Attaches a cryptographic hash representing an off-chain verified credential (e.g., identity proof, professional certificate) to a talent's profile.
4.  `getTalentProfile(address _talent)`: Retrieves the complete profile information for a specified talent address.

**B. Skill & Competency Management (5 Functions)**

5.  `proposeNewSkill(string _name, string _description, string _category, uint256 _requiredReputation)`: Initiates a governance proposal through the DAO to introduce a new skill to the platform's official registry. Requires a minimum reputation.
6.  `addSkillToRegistry(bytes32 _skillId, string _name, string _description, string _category, uint256 _requiredReputation)`: An internal/DAO-callable function that officially adds a skill to the global registry after a successful DAO vote.
7.  `addSkillToProfile(bytes32 _skillId, uint256 _initialProficiency)`: Allows a talent to declare a registered skill they possess, along with a self-assessed initial proficiency level.
8.  `updateSkillProficiency(bytes32 _skillId, uint256 _newProficiency)`: Enables talents to update their self-assessed skill proficiency, or allows a trusted oracle to submit verified proficiency scores.
9.  `decaySkillProficiency(address _talent, bytes32 _skillId)`: An internal function designed to be called by an off-chain keeper or oracle, gradually decreasing a talent's skill proficiency over time if it remains unused.

**C. Task & Quest Management (7 Functions)**

10. `createTask(string _title, string _description, bytes32[] _requiredSkills, uint256 _deadline, uint256 _initialReward, uint256 _creatorStake)`: Allows a user to create a new task, depositing the initial reward amount and a creator's stake as a commitment.
11. `proposeSolution(bytes32 _taskId, uint256 _bidAmount)`: Enables a talent to submit a proposal or bid for an open task, indicating their proposed reward amount.
12. `assignTask(bytes32 _taskId, address _talent)`: The task creator selects and assigns the task to a chosen talent from the pool of proposers. The assigned talent must provide their stake.
13. `submitWork(bytes32 _taskId, bytes32 _workHash)`: The assigned talent submits a cryptographic hash (e.g., IPFS hash) representing their completed work for review.
14. `reviewWorkAndCompleteTask(bytes32 _taskId, uint256 _reviewScore, string _reviewFeedback)`: The task creator reviews the submitted work, assigns a score, provides feedback, and finalizes the task, triggering reward distribution and reputation updates.
15. `disputeTask(bytes32 _taskId)`: Allows either the task creator or the assigned talent to formally initiate a dispute regarding a task, which is then escalated to the DAO for arbitration.
16. `resolveDispute(bytes32 _taskId, bool _talentWins)`: An internal/DAO-callable function to finalize a disputed task, determining the outcome (who wins, stake distribution, and reputation adjustments).
17. `releaseCreatorStake(bytes32 _taskId)`: Allows the task creator to reclaim their initial stake after a task has been successfully completed without any disputes.

**D. Reputation & Rewards (3 Functions)**

18. `getReputation(address _talent)`: Retrieves the current aggregated reputation score of a specified talent.
19. `updateReputationFromOracle(address _talent, uint256 _newReputationScore)`: A privileged function, callable only by the trusted AI-oracle, to update a talent's reputation based on sophisticated off-chain analysis.
20. `claimRewards(bytes32 _taskId)`: Allows the assigned talent to claim their task reward and their staked amount after successful task completion.

**E. Advanced & System Functions (6 Functions)**

21. `getRecommendedTalents(bytes32 _taskId, uint256 _maxResults)`: A conceptual AI-enhanced matching function that suggests suitable talents for a given task based on skills, proficiency, reputation, availability, and simulated contextual relevance. *Note: For scalability, real-world implementations would leverage off-chain AI/indexing.*
22. `mintAchievementNFT(address _recipient, bytes32 _relatedSkill, string _tokenURI)`: Mints a unique ERC721 NFT to a talent's wallet, signifying a verified achievement or mastery in a specific skill. Callable by the owner or oracle for exceptional achievements.
23. `predictiveTaskReward(bytes32 _taskId)`: Calculates and suggests an optimal reward amount for a given task, based on internal logic considering required skills' scarcity, demand, and a general assessment of talent value.
24. `setOracleAddress(address _newOracle)`: Allows the contract owner to update the address of the trusted AI/ZK-proof oracle.
25. `proposeParameterChange(string _paramName, uint256 _newValue)`: Allows authorized members (owner, high-reputation talents) to initiate a DAO proposal to change core contract parameters (e.g., platform fees, decay rates).
26. `voteOnProposal(uint256 _proposalId, bool _support)`: Allows DAO members to cast their vote on an active governance proposal. (Simplified interaction with external DAO).
27. `executeProposal(uint256 _proposalId)`: Triggers the execution of a DAO proposal that has met the required consensus threshold. (Simplified interaction with external DAO).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// ====================================================================================================
// Outline and Function Summary for AetherForge Smart Contract
// ====================================================================================================

// Contract Name: AetherForge
// Purpose: A decentralized, AI-enhanced talent marketplace and task management system.
// It aims to connect individuals with skills to tasks/quests, manage reputation dynamically,
// offer gamified achievements via NFTs, and evolve its parameters through DAO governance.

// Core Concepts:
// 1.  Talent Profile (Self-Sovereign Identity): Comprehensive user profiles including skills, availability, and verifiable credentials.
// 2.  Skill Registry (Token-Curated): A curated and evolving list of recognized skills, with dynamic proficiency tracking.
// 3.  Task/Quest System: Structured work units with multi-stage milestones, dynamic rewards, and dispute resolution.
// 4.  Dynamic Reputation: A multi-faceted reputation system influenced by task outcomes, reviews, and AI-oracle analysis.
// 5.  AI-Enhanced Matching (Conceptual): Utilizes (simulated) AI insights from oracles for smarter task-to-talent matching.
// 6.  Gamified Achievements (NFTs): Unique non-fungible tokens representing verified skill mastery or task achievements.
// 7.  DAO Governance: Decentralized Autonomous Organization for critical parameter changes, dispute resolution, and skill registry management.
// 8.  Oracle Integration: Trustless access to off-chain data, including AI model outputs and ZK-proof verification results.
// 9.  Staking & Slashing: Ensures commitment from both task creators and talents, and provides a mechanism for dispute resolution.
// 10. Predictive Analytics (Simulated): Suggests optimal task rewards based on market dynamics and talent availability.

// State Variables:
// -   `talents`: Mapping from address to TalentProfile struct.
// -   `registeredSkills`: Mapping from bytes32 (skillId) to Skill struct.
// -   `skillNameToId`: Mapping from string to bytes32 for easy skill ID lookup.
// -   `tasks`: Mapping from bytes32 (taskId) to Task struct.
// -   `_taskIdCounter`: Counter for unique task IDs.
// -   `reputationScores`: Mapping from address to uint256 for talent reputation.
// -   `oracleAddress`: Address of the trusted AI/ZK-proof oracle.
// -   `daoAddress`: Address of the DAO governance contract.
// -   `achievementNFTContract`: Address of the ERC721 Achievement NFT contract.
// -   `platformFeeRate`: Percentage fee taken by the platform on task completion.
// -   `minReputationForSkillProposal`: Minimum reputation to propose a new skill.
// -   `skillDecayRatePerSecond`: Rate at which skill proficiency decays.
// -   `minTalentStake`: Minimum stake required from a talent for task commitment.

// Functions Summary (27 functions):

// A. Profile & Identity Management (4 Functions)
// 1.  `createTalentProfile(string _name, string _bio, bytes32 _initialVCHash)`: Registers a new user with an optional initial verifiable credential hash (e.g., ZK-proof output).
// 2.  `updateTalentProfile(string _name, string _bio, bool _available)`: Allows a talent to update their name, bio, and availability status.
// 3.  `attachVerifiableCredential(bytes32 _vcHash)`: Attaches a hash representing a ZK-proof verified credential to a talent's profile.
// 4.  `getTalentProfile(address _talent)`: Retrieves the comprehensive profile details for a given talent address.

// B. Skill & Competency Management (5 Functions)
// 5.  `proposeNewSkill(string _name, string _description, string _category, uint256 _requiredReputation)`: Initiates a DAO proposal to add a new skill to the registry. Requires proposer to meet a minimum reputation.
// 6.  `addSkillToRegistry(bytes32 _skillId, string _name, string _description, string _category, uint256 _requiredReputation)`: Internal/DAO-callable function to add a skill to the global registry after DAO approval.
// 7.  `addSkillToProfile(bytes32 _skillId, uint256 _initialProficiency)`: Allows a talent to add a registered skill to their profile with a self-assessed initial proficiency.
// 8.  `updateSkillProficiency(bytes32 _skillId, uint256 _newProficiency)`: Allows a talent to update their self-assessed proficiency, or an oracle to submit a verified proficiency score.
// 9.  `decaySkillProficiency(address _talent, bytes32 _skillId)`: An internal/keeper function that gradually reduces a talent's proficiency in a skill if it's not actively used or updated.

// C. Task & Quest Management (7 Functions)
// 10. `createTask(string _title, string _description, bytes32[] _requiredSkills, uint256 _deadline, uint256 _initialReward, uint256 _creatorStake)`: Allows a user to create a new task, depositing initial reward and a creator stake for commitment.
// 11. `proposeSolution(bytes32 _taskId, uint256 _bidAmount)`: Enables a talent to submit a proposal/bid for an open task.
// 12. `assignTask(bytes32 _taskId, address _talent)`: The task creator assigns the task to a chosen talent from the proposals, and the talent provides their stake.
// 13. `submitWork(bytes32 _taskId, bytes32 _workHash)`: The assigned talent submits a cryptographic hash of their completed work.
// 14. `reviewWorkAndCompleteTask(bytes32 _taskId, uint256 _reviewScore, string _reviewFeedback)`: The task creator reviews the submitted work, assigns a score, provides feedback, and completes the task, triggering reward distribution and reputation update.
// 15. `disputeTask(bytes32 _taskId)`: Allows either the task creator or assigned talent to initiate a dispute over a task, leading to DAO arbitration.
// 16. `resolveDispute(bytes32 _taskId, bool _talentWins)`: Internal function callable only by the DAO to resolve a dispute, distributing stakes and updating reputation based on the outcome.
// 17. `releaseCreatorStake(bytes32 _taskId)`: Allows the task creator to reclaim their initial stake after a task is successfully completed without disputes.

// D. Reputation & Rewards (3 Functions)
// 18. `getReputation(address _talent)`: Retrieves the current aggregated reputation score of a talent.
// 19. `updateReputationFromOracle(address _talent, uint256 _newReputationScore)`: An oracle-privileged function to update a talent's reputation based on sophisticated off-chain AI analysis.
// 20. `claimRewards(bytes32 _taskId)`: Allows the talent to claim their task reward and staked amount after successful task completion.

// E. Advanced & System Functions (7 Functions)
// 21. `getRecommendedTalents(bytes32 _taskId, uint256 _maxResults)`: An AI-enhanced matching function that suggests suitable talents for a given task based on skills, reputation, availability, and contextual relevance.
// 22. `mintAchievementNFT(address _recipient, bytes32 _relatedSkill, string _tokenURI)`: Mints a unique ERC721 NFT to a talent's wallet, signifying a verified achievement or mastery in a specific skill. Callable by creator/oracle after exceptional task completion.
// 23. `predictiveTaskReward(bytes32 _taskId)`: Calculates and suggests an optimal reward amount for a given task, based on internal logic considering required skills' scarcity, demand, and average talent reputation for similar tasks.
// 24. `setOracleAddress(address _newOracle)`: Allows the contract owner to update the address of the trusted AI/ZK-proof oracle.
// 25. `proposeParameterChange(string _paramName, uint256 _newValue)`: Allows an authorized member (e.g., owner, high-reputation talent) to propose a change to a core contract parameter (e.g., fees, decay rates) via DAO.
// 26. `voteOnProposal(uint256 _proposalId, bool _support)`: Allows DAO members to cast their vote on an active governance proposal. (Simplified for this example).
// 27. `executeProposal(uint256 _proposalId)`: Executes a DAO proposal that has met the required consensus threshold. (Simplified for this example).

// ====================================================================================================

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Interface for a hypothetical DAO contract
interface IAetherForgeDAO {
    struct Proposal {
        uint256 id;
        string description;
        address proposer;
        uint256 creationTime;
        uint256 votingDeadline;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        bool passed;
        bytes data; // Encoded call data for execution
        string paramName; // For parameter change proposals
        uint256 newValue; // For parameter change proposals
        bytes32 skillId; // For new skill proposals (use bytes32 for consistency)
    }

    function createProposal(
        string memory _description,
        bytes memory _data,
        string memory _paramName,
        uint256 _newValue,
        bytes32 _skillId // Changed to bytes32
    ) external returns (uint256);

    function vote(uint256 _proposalId, bool _support) external;

    function execute(uint256 _proposalId) external;

    function getProposal(uint256 _proposalId)
        external
        view
        returns (Proposal memory);

    function hasVoted(
        uint256 _proposalId,
        address _voter
    ) external view returns (bool);
}

// Interface for the Achievement NFT contract
interface IAetherForgeAchievementNFT is IERC721 {
    function mint(address to, string memory tokenURI) external returns (uint256);
}

contract AetherForge is Ownable {
    // --- Enums ---
    enum TaskStatus {
        Open, // Task is newly created, open for proposals
        Proposed, // At least one proposal has been submitted
        Assigned, // A talent has been assigned to the task
        Submitted, // Assigned talent has submitted work
        Completed, // Work has been reviewed and task is finalized
        Disputed, // A dispute has been initiated
        Cancelled // Task was cancelled by creator (e.g. before assignment)
    }

    // --- Structs ---

    struct TalentProfile {
        string name;
        string bio;
        bool available;
        uint256 totalCompletedTasks;
        mapping(bytes32 => TalentSkill) skills; // Mapping of skillId to TalentSkill details for this talent
        bytes32 verifiableCredentialHash; // Placeholder for ZK-proof hash (e.g., identity, education)
        bytes32[] activeTasks; // Array of taskId (bytes32) the talent is currently assigned to
    }

    struct TalentSkill {
        bytes32 skillId;
        uint255 proficiency; // 0-100, 100 being expert. Using 255 to save gas on uint256 max check.
        uint256 lastProficiencyUpdate; // Timestamp of last update/decay check
    }

    struct Skill {
        bytes32 id;
        string name;
        string description;
        string category;
        uint256 requiredReputation; // Min reputation to be considered for this skill's tasks
        uint256 currentDemand; // Placeholder: Higher demand for rare skills increases their value in matching. (Updated by oracle)
        bool isRegistered; // True if DAO approved and registered
    }

    struct Task {
        bytes32 id;
        address creator;
        address assignedTalent;
        string title;
        string description;
        bytes32[] requiredSkills;
        uint256 deadline;
        uint256 initialReward; // Amount deposited by creator
        uint256 creatorStake; // Stake deposited by creator for commitment
        uint256 talentStake; // Stake deposited by assigned talent for commitment
        TaskStatus status;
        uint255 reviewScore; // 0-100 given by creator
        string reviewFeedback;
        bytes32 submittedWorkHash; // Hash of the completed work (e.g., IPFS hash)
        uint256 createdAt;
        bool creatorStakeReleased;
        bool talentClaimedReward;
        mapping(address => uint256) proposals; // Talent address => bidAmount proposed
        address[] proposers; // Array to keep track of addresses that proposed, for iteration (though not iterable from mapping directly)
    }

    // --- State Variables ---

    mapping(address => TalentProfile) public talents;
    mapping(bytes32 => Skill) public registeredSkills; // Global skill registry
    mapping(string => bytes32) public skillNameToId; // For quick lookup of skill IDs by name
    mapping(bytes32 => Task) public tasks;

    uint256 private _taskIdCounter; // Used to generate unique IDs
    
    mapping(address => uint256) public reputationScores; // Talent address => reputation score (0-1000)

    address public oracleAddress; // Address of the trusted AI/ZK-proof oracle
    address public daoAddress; // Address of the DAO contract
    IAetherForgeAchievementNFT public achievementNFTContract; // Instance of the Achievement NFT contract

    uint256 public platformFeeRate = 500; // 5% (500 basis points, 10000 = 100%)
    uint256 public minReputationForSkillProposal = 200; // Min reputation to propose new skill to DAO
    uint256 public skillDecayRatePerSecond = 1; // 1 unit of proficiency decay per day (86400 seconds)
    uint255 public maxProficiency = 100; // Max proficiency for a skill
    uint255 public maxReputation = 1000; // Max reputation score
    uint256 public minTalentStake = 1e16; // 0.01 Ether in Wei, minimum stake for an assigned talent

    // --- Events ---
    event ProfileCreated(address indexed talent, string name);
    event ProfileUpdated(address indexed talent, string name, bool available);
    event CredentialAttached(address indexed talent, bytes32 vcHash);
    event SkillProposed(bytes32 indexed skillId, string name, address indexed proposer);
    event SkillAddedToProfile(address indexed talent, bytes32 indexed skillId, uint255 proficiency);
    event SkillProficiencyUpdated(address indexed talent, bytes32 indexed skillId, uint255 newProficiency);
    event TaskCreated(bytes32 indexed taskId, address indexed creator, uint256 reward);
    event SolutionProposed(bytes32 indexed taskId, address indexed talent, uint256 bidAmount);
    event TaskAssigned(bytes32 indexed taskId, address indexed talent);
    event WorkSubmitted(bytes32 indexed taskId, address indexed talent, bytes32 workHash);
    event TaskCompleted(
        bytes32 indexed taskId,
        address indexed talent,
        uint255 reviewScore,
        uint256 finalReward
    );
    event TaskDisputed(bytes32 indexed taskId, address indexed initiator);
    event ReputationUpdated(address indexed talent, uint256 newScore);
    event AchievementNFTMinted(address indexed recipient, bytes32 indexed skillId, uint256 tokenId);
    event OracleAddressUpdated(address indexed newOracle);
    event ParameterChangeProposed(string paramName, uint256 newValue);
    event DisputeResolved(bytes32 indexed taskId, bool talentWins);


    // --- Modifiers ---
    modifier onlyOracle() {
        require(msg.sender == oracleAddress, "Caller is not the oracle");
        _;
    }

    modifier onlyDAO() {
        require(msg.sender == daoAddress, "Caller is not the DAO");
        _;
    }

    modifier onlyCreator(bytes32 _taskId) {
        require(msg.sender == tasks[_taskId].creator, "Caller is not the task creator");
        _;
    }

    modifier onlyAssignedTalent(bytes32 _taskId) {
        require(msg.sender == tasks[_taskId].assignedTalent, "Caller is not the assigned talent");
        _;
    }

    modifier talentExists() {
        require(bytes(talents[msg.sender].name).length > 0, "Talent profile does not exist");
        _;
    }

    modifier taskExists(bytes32 _taskId) {
        require(tasks[_taskId].creator != address(0), "Task does not exist");
        _;
    }

    // --- Constructor ---
    constructor(address _daoAddress, address _achievementNFTAddress) {
        require(_daoAddress != address(0), "DAO address cannot be zero");
        require(_achievementNFTAddress != address(0), "Achievement NFT address cannot be zero");
        daoAddress = _daoAddress;
        achievementNFTContract = IAetherForgeAchievementNFT(_achievementNFTAddress);
    }

    // ==============================================================================================
    // A. Profile & Identity Management (4 Functions)
    // ==============================================================================================

    /**
     * @notice Registers a new user as a talent in the AetherForge marketplace.
     * @param _name The name of the talent.
     * @param _bio A short biography for the talent.
     * @param _initialVCHash An optional hash representing a ZK-proof verified credential (e.g., identity, education).
     */
    function createTalentProfile(
        string calldata _name,
        string calldata _bio,
        bytes32 _initialVCHash
    ) external {
        require(bytes(talents[msg.sender].name).length == 0, "Profile already exists");
        talents[msg.sender].name = _name;
        talents[msg.sender].bio = _bio;
        talents[msg.sender].available = true;
        talents[msg.sender].verifiableCredentialHash = _initialVCHash;
        reputationScores[msg.sender] = 500; // Initial reputation score
        emit ProfileCreated(msg.sender, _name);
    }

    /**
     * @notice Allows a talent to update their profile details.
     * @param _name The new name for the talent.
     * @param _bio The new biography for the talent.
     * @param _available The new availability status (true if available for tasks).
     */
    function updateTalentProfile(
        string calldata _name,
        string calldata _bio,
        bool _available
    ) external talentExists {
        talents[msg.sender].name = _name;
        talents[msg.sender].bio = _bio;
        talents[msg.sender].available = _available;
        emit ProfileUpdated(msg.sender, _name, _available);
    }

    /**
     * @notice Attaches a hash representing a ZK-proof verified credential to a talent's profile.
     *         The actual ZK-proof verification happens off-chain, and only the hash is stored.
     * @param _vcHash The cryptographic hash of the verified credential.
     */
    function attachVerifiableCredential(bytes32 _vcHash) external talentExists {
        talents[msg.sender].verifiableCredentialHash = _vcHash;
        emit CredentialAttached(msg.sender, _vcHash);
    }

    /**
     * @notice Retrieves the comprehensive profile details for a given talent address.
     * @param _talent The address of the talent.
     * @return A tuple containing talent's name, bio, availability, total completed tasks,
     *         and verifiable credential hash.
     */
    function getTalentProfile(
        address _talent
    )
        external
        view
        returns (
            string memory name,
            string memory bio,
            bool available,
            uint256 totalCompletedTasks,
            bytes32 vcHash
        )
    {
        TalentProfile storage profile = talents[_talent];
        require(bytes(profile.name).length > 0, "Talent profile does not exist");
        return (
            profile.name,
            profile.bio,
            profile.available,
            profile.totalCompletedTasks,
            profile.verifiableCredentialHash
        );
    }

    // ==============================================================================================
    // B. Skill & Competency Management (5 Functions)
    // ==============================================================================================

    /**
     * @notice Proposes a new skill to be added to the global skill registry.
     *         Requires DAO approval to become officially registered.
     * @param _name The name of the new skill.
     * @param _description A brief description of the skill.
     * @param _category The category the skill belongs to (e.g., "Web Development", "Graphic Design").
     * @param _requiredReputation The minimum reputation a talent needs to be assigned tasks requiring this skill.
     */
    function proposeNewSkill(
        string calldata _name,
        string calldata _description,
        string calldata _category,
        uint256 _requiredReputation
    ) external talentExists {
        require(
            reputationScores[msg.sender] >= minReputationForSkillProposal,
            "Insufficient reputation to propose a skill"
        );
        require(skillNameToId[_name] == bytes32(0), "Skill with this name already proposed or exists");

        bytes32 newSkillId = keccak256(abi.encodePacked(_name, _category, block.timestamp, msg.sender)); // Ensure uniqueness
        
        // Simulate adding to DAO for proposal
        // In a real scenario, this would call DAO.createProposal with appropriate call data
        IAetherForgeDAO(daoAddress).createProposal(
            string(abi.encodePacked("Propose new skill: ", _name)),
            abi.encodeWithSelector(this.addSkillToRegistry.selector, newSkillId, _name, _description, _category, _requiredReputation),
            "newSkill",
            0, // Not a parameter change
            newSkillId // Use bytes32 for skillId in proposal
        );

        emit SkillProposed(newSkillId, _name, msg.sender);
    }

    /**
     * @notice Internal/DAO-callable function to add a skill to the global registry after DAO approval.
     * @dev This function should only be callable by the DAO contract after a successful proposal vote.
     * @param _skillId The ID of the skill.
     * @param _name The name of the skill.
     * @param _description A description of the skill.
     * @param _category The category of the skill.
     * @param _requiredReputation Minimum reputation required for this skill.
     */
    function addSkillToRegistry(
        bytes32 _skillId,
        string calldata _name,
        string calldata _description,
        string calldata _category,
        uint256 _requiredReputation
    ) external onlyDAO {
        require(!registeredSkills[_skillId].isRegistered, "Skill already registered");
        require(skillNameToId[_name] == bytes32(0), "Skill name already exists in registry"); // Ensure name uniqueness
        
        registeredSkills[_skillId] = Skill(
            _skillId,
            _name,
            _description,
            _category,
            _requiredReputation,
            0, // Initial demand
            true
        );
        skillNameToId[_name] = _skillId;
    }

    /**
     * @notice Allows a talent to declare a skill they possess from the registered skills.
     * @param _skillId The ID of the skill to add.
     * @param _initialProficiency A self-assessed initial proficiency score (0-100).
     */
    function addSkillToProfile(bytes32 _skillId, uint255 _initialProficiency) external talentExists {
        require(registeredSkills[_skillId].isRegistered, "Skill not registered");
        require(
            talents[msg.sender].skills[_skillId].proficiency == 0,
            "Skill already added to profile"
        );
        require(_initialProficiency <= maxProficiency, "Proficiency must be between 0 and 100");

        talents[msg.sender].skills[_skillId] = TalentSkill(
            _skillId,
            _initialProficiency,
            block.timestamp
        );
        emit SkillAddedToProfile(msg.sender, _skillId, _initialProficiency);
    }

    /**
     * @notice Updates a talent's proficiency in a specific skill.
     *         Can be called by the talent themselves (self-assessment) or by the oracle (verified update).
     * @param _skillId The ID of the skill.
     * @param _newProficiency The new proficiency score (0-100).
     */
    function updateSkillProficiency(bytes32 _skillId, uint255 _newProficiency) external talentExists {
        require(registeredSkills[_skillId].isRegistered, "Skill not registered");
        require(
            talents[msg.sender].skills[_skillId].proficiency > 0,
            "Skill not added to profile yet"
        );
        require(_newProficiency <= maxProficiency, "Proficiency must be between 0 and 100");

        // Allow self-update up to current level + a small delta, or by oracle for significant changes
        if (msg.sender != oracleAddress) {
            require(
                _newProficiency <= talents[msg.sender].skills[_skillId].proficiency + 10 || // Max 10 point self-increase for self-assessment
                _newProficiency < talents[msg.sender].skills[_skillId].proficiency, // Allow decrease
                "Significant proficiency update requires oracle verification or is too high for self-assessment."
            );
        }

        talents[msg.sender].skills[_skillId].proficiency = _newProficiency;
        talents[msg.sender].skills[_skillId].lastProficiencyUpdate = block.timestamp;
        emit SkillProficiencyUpdated(msg.sender, _skillId, _newProficiency);
    }

    /**
     * @notice Retrieves the details of a specific skill from the global registry.
     * @param _skillId The ID of the skill.
     * @return A tuple containing skill name, description, category, required reputation, current demand, and registration status.
     */
    function getSkillDetails(
        bytes32 _skillId
    )
        external
        view
        returns (
            string memory name,
            string memory description,
            string memory category,
            uint256 requiredReputation,
            uint256 currentDemand,
            bool isRegistered
        )
    {
        Skill storage skill = registeredSkills[_skillId];
        require(skill.isRegistered, "Skill not registered");
        return (
            skill.name,
            skill.description,
            skill.category,
            skill.requiredReputation,
            skill.currentDemand,
            skill.isRegistered
        );
    }

    /**
     * @notice Internal/Keeper function to gradually decay a talent's proficiency in a skill over time.
     *         This incentivizes continuous learning and active participation.
     * @param _talent The address of the talent.
     * @param _skillId The ID of the skill to decay.
     * @dev This function could be called periodically by a decentralized keeper network or by the oracle.
     */
    function decaySkillProficiency(address _talent, bytes32 _skillId) internal {
        TalentSkill storage tSkill = talents[_talent].skills[_skillId];
        if (tSkill.proficiency > 0) {
            uint256 timeElapsed = block.timestamp - tSkill.lastProficiencyUpdate;
            uint255 decayAmount = uint255(timeElapsed / 86400) * uint255(skillDecayRatePerSecond); // Decay per day
            if (decayAmount > tSkill.proficiency) {
                decayAmount = tSkill.proficiency;
            }
            tSkill.proficiency = tSkill.proficiency - decayAmount;
            tSkill.lastProficiencyUpdate = block.timestamp;
            if (decayAmount > 0) {
                emit SkillProficiencyUpdated(_talent, _skillId, tSkill.proficiency);
            }
        }
    }

    // ==============================================================================================
    // C. Task & Quest Management (7 Functions)
    // ==============================================================================================

    /**
     * @notice Allows a user to create a new task on the marketplace.
     * @param _title The title of the task.
     * @param _description A detailed description of the task.
     * @param _requiredSkills An array of skill IDs required for the task.
     * @param _deadline The Unix timestamp by which the task needs to be completed.
     * @param _initialReward The amount of ETH/tokens offered as a base reward.
     * @param _creatorStake The stake amount required from the creator as commitment.
     */
    function createTask(
        string calldata _title,
        string calldata _description,
        bytes32[] calldata _requiredSkills,
        uint256 _deadline,
        uint256 _initialReward,
        uint256 _creatorStake
    ) external payable {
        require(_deadline > block.timestamp, "Deadline must be in the future");
        require(_initialReward > 0, "Initial reward must be greater than zero");
        require(_creatorStake > 0, "Creator stake must be greater than zero");
        require(
            msg.value == _initialReward + _creatorStake,
            "Incorrect ETH sent for reward and stake"
        );

        for (uint256 i = 0; i < _requiredSkills.length; i++) {
            require(
                registeredSkills[_requiredSkills[i]].isRegistered,
                "One or more required skills are not registered"
            );
        }

        bytes32 newTaskId = keccak256(abi.encodePacked(_title, msg.sender, block.timestamp, _taskIdCounter++));
        
        tasks[newTaskId] = Task({
            id: newTaskId,
            creator: msg.sender,
            assignedTalent: address(0), // No talent assigned initially
            title: _title,
            description: _description,
            requiredSkills: _requiredSkills,
            deadline: _deadline,
            initialReward: _initialReward,
            creatorStake: _creatorStake,
            talentStake: 0, // Talent stake to be provided upon assignment
            status: TaskStatus.Open,
            reviewScore: 0,
            reviewFeedback: "",
            submittedWorkHash: bytes32(0),
            createdAt: block.timestamp,
            creatorStakeReleased: false,
            talentClaimedReward: false,
            proposals: new mapping(address => uint256)(), // Initialize empty
            proposers: new address[](0) // Initialize empty
        });

        emit TaskCreated(newTaskId, msg.sender, _initialReward);
    }

    /**
     * @notice Enables a talent to submit a proposal/bid for an open task.
     *         Does not require stake at this stage, stake is required upon assignment.
     * @param _taskId The ID of the task to propose for.
     * @param _bidAmount The amount of reward the talent proposes (can be same as initial reward or different).
     */
    function proposeSolution(bytes32 _taskId, uint256 _bidAmount) external talentExists {
        Task storage task = tasks[_taskId];
        require(task.creator != address(0), "Task does not exist");
        require(task.status == TaskStatus.Open, "Task is not open for proposals");
        require(msg.sender != task.creator, "Creator cannot propose solution for own task");
        require(_bidAmount > 0, "Bid amount must be greater than zero");
        require(task.proposals[msg.sender] == 0, "Talent already proposed for this task"); // Allow only one proposal per talent

        // Ensure talent has required skills for the task and sufficient reputation
        for (uint256 i = 0; i < task.requiredSkills.length; i++) {
            bytes32 skillId = task.requiredSkills[i];
            require(
                talents[msg.sender].skills[skillId].proficiency > 0,
                string(abi.encodePacked("Talent does not possess required skill: ", registeredSkills[skillId].name))
            );
            require(
                reputationScores[msg.sender] >= registeredSkills[skillId].requiredReputation,
                "Insufficient reputation for this skill"
            );
            // Optionally decay skill proficiency when it's considered for matching
            decaySkillProficiency(msg.sender, skillId);
        }

        task.proposals[msg.sender] = _bidAmount;
        task.proposers.push(msg.sender);
        
        if (task.status == TaskStatus.Open) {
            task.status = TaskStatus.Proposed; // Change status once first proposal comes in
        }
        emit SolutionProposed(_taskId, msg.sender, _bidAmount);
    }

    /**
     * @notice The task creator assigns the task to a chosen talent from the proposals.
     *         The assigned talent must provide the minimum talent stake upon assignment.
     * @param _taskId The ID of the task.
     * @param _talent The address of the talent to assign the task to.
     */
    function assignTask(bytes32 _taskId, address _talent) external payable onlyCreator(_taskId) {
        Task storage task = tasks[_taskId];
        require(task.status == TaskStatus.Proposed, "Task is not in proposal state");
        require(task.proposals[_talent] > 0, "Talent has not proposed for this task");
        require(bytes(talents[_talent].name).length > 0, "Assigned talent profile does not exist");
        require(msg.value >= minTalentStake, "Assigned talent must provide minimum stake");
        require(task.assignedTalent == address(0), "Task already assigned");

        task.talentStake = msg.value; // Store the assigned talent's stake
        task.assignedTalent = _talent;
        task.status = TaskStatus.Assigned;

        // Add task to talent's active tasks
        talents[_talent].activeTasks.push(_taskId);

        emit TaskAssigned(_taskId, _talent);
    }

    /**
     * @notice The assigned talent submits the cryptographic hash of their completed work.
     * @param _taskId The ID of the task.
     * @param _workHash The hash of the completed work (e.g., IPFS hash).
     */
    function submitWork(bytes32 _taskId, bytes32 _workHash) external onlyAssignedTalent(_taskId) {
        Task storage task = tasks[_taskId];
        require(
            task.status == TaskStatus.Assigned, // Assuming direct transition from Assigned to Submitted
            "Task is not assigned"
        );
        require(block.timestamp <= task.deadline, "Task submission deadline passed");

        task.submittedWorkHash = _workHash;
        task.status = TaskStatus.Submitted;
        emit WorkSubmitted(_taskId, msg.sender, _workHash);
    }

    /**
     * @notice The task creator reviews the submitted work, assigns a score, provides feedback,
     *         and completes the task, triggering reward distribution and reputation update.
     * @param _taskId The ID of the task.
     * @param _reviewScore The score given by the creator (0-100).
     * @param _reviewFeedback Optional feedback string.
     */
    function reviewWorkAndCompleteTask(
        bytes32 _taskId,
        uint255 _reviewScore,
        string calldata _reviewFeedback
    ) external onlyCreator(_taskId) {
        Task storage task = tasks[_taskId];
        require(task.status == TaskStatus.Submitted, "Work has not been submitted or task is not in review state");
        require(_reviewScore <= 100, "Review score must be between 0 and 100");

        task.reviewScore = _reviewScore;
        task.reviewFeedback = _reviewFeedback;
        task.status = TaskStatus.Completed;

        uint256 finalReward = task.initialReward;
        uint256 platformFee = (finalReward * platformFeeRate) / 10000; // Calculate 5% fee
        
        // Transfer fee to platform (owner)
        payable(owner()).transfer(platformFee);
        
        // Update talent's completed tasks count
        talents[task.assignedTalent].totalCompletedTasks++;

        // Remove task from activeTasks
        for(uint256 i = 0; i < talents[task.assignedTalent].activeTasks.length; i++){
            if(talents[task.assignedTalent].activeTasks[i] == _taskId){
                talents[task.assignedTalent].activeTasks[i] = talents[task.assignedTalent].activeTasks[talents[task.assignedTalent].activeTasks.length - 1];
                talents[task.assignedTalent].activeTasks.pop();
                break;
            }
        }

        // Update reputation based on review score
        uint256 currentRep = reputationScores[task.assignedTalent];
        if (_reviewScore >= 80) {
            reputationScores[task.assignedTalent] = currentRep + 10 > maxReputation ? maxReputation : currentRep + 10; // Positive boost, capped at maxReputation
        } else if (_reviewScore < 50) {
            reputationScores[task.assignedTalent] = currentRep > 5 ? currentRep - 5 : 0; // Negative impact, floored at 0
        }
        emit ReputationUpdated(task.assignedTalent, reputationScores[task.assignedTalent]);

        emit TaskCompleted(_taskId, task.assignedTalent, _reviewScore, finalReward - platformFee);
    }

    /**
     * @notice Allows either the task creator or assigned talent to initiate a dispute over a task.
     *         This triggers a dispute resolution process, typically handled by the DAO or an arbitration module.
     * @param _taskId The ID of the task to dispute.
     */
    function disputeTask(bytes32 _taskId) external taskExists {
        Task storage task = tasks[_taskId];
        require(
            msg.sender == task.creator || msg.sender == task.assignedTalent,
            "Only creator or assigned talent can dispute"
        );
        require(
            task.status != TaskStatus.Completed && task.status != TaskStatus.Disputed && task.status != TaskStatus.Cancelled,
            "Task cannot be disputed in its current state"
        );

        task.status = TaskStatus.Disputed;
        // In a real system, this would trigger a DAO proposal or an external arbitration mechanism.
        // The DAO would vote and then call resolveDispute.
        IAetherForgeDAO(daoAddress).createProposal(
            string(abi.encodePacked("Dispute for task: ", task.title, " (ID:", Strings.toHexString(uint256(_taskId)), ")")),
            abi.encodeWithSelector(this.resolveDispute.selector, _taskId, false), // Placeholder for actual dispute resolution logic
            "dispute",
            0,
            bytes32(0) // Not a skill proposal
        );

        emit TaskDisputed(_taskId, msg.sender);
    }

    /**
     * @notice Internal function to resolve a dispute. Callable only by the DAO.
     * @param _taskId The ID of the task under dispute.
     * @param _talentWins True if talent wins, false if creator wins.
     */
    function resolveDispute(bytes32 _taskId, bool _talentWins) external onlyDAO taskExists {
        Task storage task = tasks[_taskId];
        require(task.status == TaskStatus.Disputed, "Task is not in disputed state");

        if (_talentWins) {
            // Talent wins: creator's stake partially goes to talent and platform, talent gets initial reward + talent stake.
            uint256 creatorPenaltyToPlatform = task.creatorStake / 2; // 50% of creator stake as penalty to platform
            uint256 compensationToTalentFromCreatorStake = task.creatorStake - creatorPenaltyToPlatform; // Remaining to talent as compensation

            payable(owner()).transfer(creatorPenaltyToPlatform); // Platform gets penalty
            // Talent will claim initial reward + compensation from creator stake + their own stake via claimRewards

            reputationScores[task.assignedTalent] += 20; // Talent rep boost
            if (reputationScores[task.assignedTalent] > maxReputation) reputationScores[task.assignedTalent] = maxReputation;
            reputationScores[task.creator] = reputationScores[task.creator] > 20 ? reputationScores[task.creator] - 20 : 0; // Creator rep drop
        } else {
            // Creator wins: talent's stake partially goes to creator and platform, talent gets nothing, creator gets their stake back.
            uint256 talentPenaltyToPlatform = task.talentStake / 2; // 50% of talent stake as penalty to platform
            uint256 compensationToCreatorFromTalentStake = task.talentStake - talentPenaltyToPlatform; // Remaining to creator

            payable(owner()).transfer(talentPenaltyToPlatform); // Platform gets penalty
            payable(task.creator).transfer(compensationToCreatorFromTalentStake); // Creator gets compensation

            reputationScores[task.creator] += 20; // Creator rep boost
            if (reputationScores[task.creator] > maxReputation) reputationScores[task.creator] = maxReputation;
            reputationScores[task.assignedTalent] = reputationScores[task.assignedTalent] > 20 ? reputationScores[task.assignedTalent] - 20 : 0; // Talent rep drop
        }
        task.status = TaskStatus.Completed; // Dispute is now resolved, marking task as completed
        emit ReputationUpdated(task.assignedTalent, reputationScores[task.assignedTalent]);
        emit ReputationUpdated(task.creator, reputationScores[task.creator]);
        emit DisputeResolved(_taskId, _talentWins);
    }

    /**
     * @notice Allows the task creator to reclaim their initial stake after a task is successfully completed
     *         without disputes.
     * @param _taskId The ID of the task.
     */
    function releaseCreatorStake(bytes32 _taskId) external onlyCreator(_taskId) {
        Task storage task = tasks[_taskId];
        require(task.status == TaskStatus.Completed, "Task is not completed");
        require(!task.creatorStakeReleased, "Creator stake already released");
        require(task.assignedTalent != address(0), "Task must have been assigned to release stake"); // Ensure it went through the process

        task.creatorStakeReleased = true;
        payable(task.creator).transfer(task.creatorStake);
    }

    // ==============================================================================================
    // D. Reputation & Rewards (3 Functions)
    // ==============================================================================================

    /**
     * @notice Retrieves a talent's current aggregated reputation score.
     * @param _talent The address of the talent.
     * @return The reputation score (0-1000).
     */
    function getReputation(address _talent) external view returns (uint256) {
        return reputationScores[_talent];
    }

    /**
     * @notice Callable only by a trusted AI-oracle to update a talent's reputation based on
     *         sophisticated off-chain analysis (e.g., sentiment analysis of reviews, project success rate).
     * @param _talent The address of the talent whose reputation is to be updated.
     * @param _newReputationScore The new reputation score provided by the oracle (0-1000).
     */
    function updateReputationFromOracle(address _talent, uint256 _newReputationScore) external onlyOracle {
        require(bytes(talents[_talent].name).length > 0, "Talent profile does not exist");
        require(_newReputationScore <= maxReputation, "Reputation score cannot exceed 1000");

        reputationScores[_talent] = _newReputationScore;
        emit ReputationUpdated(_talent, _newReputationScore);
    }

    /**
     * @notice Allows the assigned talent to claim their task reward and staked amount after successful task completion.
     * @param _taskId The ID of the completed task.
     */
    function claimRewards(bytes32 _taskId) external onlyAssignedTalent(_taskId) {
        Task storage task = tasks[_taskId];
        require(task.status == TaskStatus.Completed, "Task is not completed");
        require(!task.talentClaimedReward, "Rewards already claimed");

        uint256 finalReward = task.initialReward;
        uint256 platformFee = (finalReward * platformFeeRate) / 10000;
        uint256 talentReward = finalReward - platformFee;

        uint256 totalClaimAmount = talentReward + task.talentStake;
        task.talentClaimedReward = true;
        payable(msg.sender).transfer(totalClaimAmount);
    }

    // ==============================================================================================
    // E. Advanced & System Functions (7 Functions)
    // ==============================================================================================

    /**
     * @notice AI-enhanced matching function that suggests suitable talents for a given task.
     *         Considers skills, proficiency, reputation, availability, and (simulated) contextual relevance.
     * @param _taskId The ID of the task to find talents for.
     * @param _maxResults The maximum number of talent recommendations to return.
     * @return An array of recommended talent addresses.
     * @dev This function is a symbolic representation of an AI-enhanced matching engine.
     *      Due to blockchain limitations (no arbitrary iteration over mappings, high gas costs for complex logic),
     *      a real implementation would offload heavy computation to an off-chain AI service/Subgraph,
     *      which then submits a signed result via an oracle if needed for on-chain verification or interaction.
     *      For this demo, it provides a very basic, non-scalable placeholder logic.
     */
    function getRecommendedTalents(
        bytes32 _taskId,
        uint256 _maxResults
    ) public view returns (address[] memory) {
        Task storage task = tasks[_taskId];
        require(task.creator != address(0), "Task does not exist");

        // --- IMPORTANT NOTE ON SCALABILITY ---
        // Directly iterating over all 'talents' mapping is not feasible on-chain due to gas limits and
        // lack of direct iteration support for mappings in Solidity.
        // A real-world application would use an off-chain indexing solution (e.g., The Graph)
        // or a dedicated AI oracle service to pre-compute and provide these recommendations.
        // This function merely demonstrates the *concept* of such a feature.

        address[] memory recommendedList = new address[](0);
        // For demonstration purposes, if an assigned talent exists, we'll return them as a "recommendation".
        // Otherwise, it would conceptually involve iterating through registered skills and then talents possessing them.
        if (task.assignedTalent != address(0) && bytes(talents[task.assignedTalent].name).length > 0) {
            if (talents[task.assignedTalent].available) {
                // Simulate checking if the assigned talent meets the skills/reputation requirements
                bool allSkillsMet = true;
                for (uint256 i = 0; i < task.requiredSkills.length; i++) {
                    bytes32 requiredSkillId = task.requiredSkills[i];
                    if (talents[task.assignedTalent].skills[requiredSkillId].proficiency == 0 ||
                        reputationScores[task.assignedTalent] < registeredSkills[requiredSkillId].requiredReputation) {
                        allSkillsMet = false;
                        break;
                    }
                }
                if (allSkillsMet) {
                    recommendedList = new address[](1);
                    recommendedList[0] = task.assignedTalent;
                }
            }
        }
        
        // In a more complex conceptual setup, this would call an oracle:
        // (address[] memory recs, uint256[] memory scores) = IExternalAIOracle(oracleAddress).getRecommendations(_taskId, _maxResults);
        // Then return `recs`.

        return recommendedList;
    }

    /**
     * @notice Mints a unique ERC721 NFT to a talent's wallet, signifying a verified achievement or mastery in a specific skill.
     *         Typically callable by the contract owner, DAO, or trusted oracle after exceptional task completion or verification.
     * @param _recipient The address of the talent to receive the NFT.
     * @param _relatedSkill The ID of the skill related to this achievement.
     * @param _tokenURI The URI pointing to the NFT's metadata (image, description).
     */
    function mintAchievementNFT(
        address _recipient,
        bytes32 _relatedSkill,
        string calldata _tokenURI
    ) external {
        // Only owner, or potentially the DAO/Oracle should be able to mint achievements
        require(msg.sender == owner() || msg.sender == oracleAddress || msg.sender == daoAddress, "Unauthorized to mint Achievement NFT");
        require(bytes(talents[_recipient].name).length > 0, "Recipient talent profile does not exist");
        require(registeredSkills[_relatedSkill].isRegistered, "Related skill is not registered");

        uint256 tokenId = achievementNFTContract.mint(_recipient, _tokenURI);
        emit AchievementNFTMinted(_recipient, _relatedSkill, tokenId);
    }

    /**
     * @notice Calculates and suggests an optimal reward amount for a given task.
     *         Uses internal logic considering required skills' scarcity, demand, and average talent reputation for similar tasks.
     * @param _taskId The ID of the task for which to suggest a reward.
     * @return The suggested optimal reward in wei.
     * @dev This is a simplified on-chain pricing model. A real-world predictive model would involve
     *      more complex data (e.g., historical task completion rates, market volatility) typically fetched via an oracle.
     */
    function predictiveTaskReward(bytes32 _taskId) public view returns (uint256) {
        Task storage task = tasks[_taskId];
        require(task.creator != address(0), "Task does not exist");

        uint256 baseReward = task.initialReward; 
        if (baseReward == 0) baseReward = 0.1 ether; // Provide a default base if task creator didn't specify initially

        // Simulate dynamic pricing factors based on conceptual "demand"
        // `currentDemand` for a skill is a simplified representation. In a real system, this would be
        // updated by an oracle based on off-chain market analysis (e.g., number of open tasks vs. available talents for that skill).
        uint256 totalDemandFactor = 0; // Represents accumulated "scarcity" or "hotness" of skills
        for (uint256 i = 0; i < task.requiredSkills.length; i++) {
            bytes32 skillId = task.requiredSkills[i];
            Skill storage s = registeredSkills[skillId];
            if (s.isRegistered) {
                totalDemandFactor += s.currentDemand; // Accumulate demand value for required skills
            }
        }

        // Simple adjustment formula: base + (base * totalDemandFactor / max_demand_scale)
        // Assume max_demand_scale is 1000 for a 100% adjustment (doubling price)
        uint256 adjustment = (baseReward * totalDemandFactor) / 1000; 
        return baseReward + adjustment;
    }

    /**
     * @notice Allows the contract owner to update the address of the trusted AI/ZK-proof oracle.
     * @param _newOracle The new address for the oracle.
     */
    function setOracleAddress(address _newOracle) external onlyOwner {
        require(_newOracle != address(0), "Oracle address cannot be zero");
        oracleAddress = _newOracle;
        emit OracleAddressUpdated(_newOracle);
    }

    /**
     * @notice Allows an authorized member (e.g., owner, high-reputation talent) to propose a change to a
     *         core contract parameter (e.g., fees, skill decay rates) via the DAO.
     * @param _paramName The name of the parameter to change (e.g., "platformFeeRate", "minTalentStake").
     * @param _newValue The new value for the parameter.
     */
    function proposeParameterChange(string calldata _paramName, uint256 _newValue) external {
        // Only owner or talent with high enough reputation can propose
        require(
            msg.sender == owner() || reputationScores[msg.sender] >= minReputationForSkillProposal,
            "Unauthorized to propose parameter change"
        );

        // Encode the function call to be executed by the DAO
        bytes memory callData;
        if (keccak256(abi.encodePacked(_paramName)) == keccak256(abi.encodePacked("platformFeeRate"))) {
            callData = abi.encodeWithSelector(this.setPlatformFeeRate.selector, _newValue);
        } else if (keccak256(abi.encodePacked(_paramName)) == keccak256(abi.encodePacked("minReputationForSkillProposal"))) {
            callData = abi.encodeWithSelector(this.setMinReputationForSkillProposal.selector, _newValue);
        } else if (keccak256(abi.encodePacked(_paramName)) == keccak256(abi.encodePacked("skillDecayRatePerSecond"))) {
            callData = abi.encodeWithSelector(this.setSkillDecayRatePerSecond.selector, _newValue);
        } else if (keccak256(abi.encodePacked(_paramName)) == keccak256(abi.encodePacked("minTalentStake"))) {
            callData = abi.encodeWithSelector(this.setMinTalentStake.selector, _newValue);
        } else {
            revert("Unknown parameter name");
        }

        IAetherForgeDAO(daoAddress).createProposal(
            string(abi.encodePacked("Change parameter: ", _paramName, " to ", Strings.toString(_newValue))),
            callData,
            _paramName,
            _newValue,
            bytes32(0) // Not a skill proposal
        );

        emit ParameterChangeProposed(_paramName, _newValue);
    }

    /**
     * @notice Allows a DAO member to cast their vote on an active governance proposal.
     *         Simplified for this example, assumes external DAO handles vote weighting and eligibility.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for 'yes' vote, false for 'no' vote.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) external {
        // In a real DAO, there would be checks for membership, token balance, etc.
        // For this contract, we simply call the DAO's vote function.
        IAetherForgeDAO(daoAddress).vote(_proposalId, _support);
    }

    /**
     * @notice Executes a DAO proposal that has met the required consensus threshold.
     *         Simplified for this example, assumes external DAO determines pass/fail and calls this.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) external {
        // Only the DAO itself or a privileged address should be able to execute
        // For simplicity, directly call DAO's execute function
        IAetherForgeDAO(daoAddress).execute(_proposalId);
    }

    // --- Internal functions for DAO to call --- (these are public because the DAO will call them externally)
    // In a production setup, these might be internal and only callable via an `execute` function
    // in the DAO contract that performs delegatecall or call with the correct target.
    // For this example, they are public and use `onlyDAO` modifier.

    function setPlatformFeeRate(uint256 _newRate) public onlyDAO {
        require(_newRate <= 1000, "Fee rate cannot exceed 10% (1000 basis points)"); // Max 10%
        platformFeeRate = _newRate;
    }

    function setMinReputationForSkillProposal(uint256 _newRep) public onlyDAO {
        minReputationForSkillProposal = _newRep;
    }

    function setSkillDecayRatePerSecond(uint255 _newRate) public onlyDAO {
        skillDecayRatePerSecond = _newRate;
    }

    function setMinTalentStake(uint256 _newStake) public onlyDAO {
        minTalentStake = _newStake;
    }

    // Fallback function to prevent accidental ETH transfers without specific methods
    receive() external payable {
        revert("Direct ETH transfers not allowed. Use specific functions.");
    }
}
```