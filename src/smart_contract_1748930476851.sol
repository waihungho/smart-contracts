Okay, here is a smart contract concept that attempts to be unique, advanced, and feature-rich.

**Concept: The "ChronicleForge"**

This contract creates a decentralized system where users earn "Influence" across different "Paths" (representing skills, affiliations, or contributions) by completing tasks and participating in governance. This accumulated Influence dynamically shapes a unique, non-transferable token called the "Chronicle Stone," representing the user's on-chain identity and standing within the ChronicleForge ecosystem.

*   **Unique/Advanced Aspects:**
    *   **Dynamic, Non-Transferable Token (SBT-like):** The "Chronicle Stone" is tied to the user's address and cannot be transferred. Its properties (attributes, tiers) change *on-chain* based on user activity and accumulated Influence. This acts as a form of persistent, programmable identity.
    *   **Multi-Path Influence System:** Influence is not monolithic but categorized across different, configurable "Paths."
    *   **Influence as Governance Power:** Voting power in proposals is derived from Influence within specific Paths required by the proposal.
    *   **Task-Based Influence Earning:** A mechanism (simulated oracle) for verifying completion of tasks (on-chain or off-chain) to distribute Influence.
    *   **Procedural Attribute Generation:** Stone attributes and tiers are derived algorithmically on-chain from the user's Influence scores across Paths.
    *   **On-Chain History:** The Stone maintains a basic history of key events.

*   **Why it's (likely) not duplicated:** While components like NFTs, governance, and roles exist, the specific combination of a *dynamic*, *non-transferable* token whose *on-chain attributes* and *governance power* are derived from *multi-path influence* earned through *verified tasks* is a novel architectural pattern.

---

**Outline & Function Summary**

**Contract Name:** `ChronicleForge`

**Concept:** A system for managing user reputation (Influence) across multiple Paths, tied to a dynamic, non-transferable "Chronicle Stone" token (SBT-like). Influence is earned via tasks and participation and used for governance.

**Core Components:**

1.  **Chronicle Stone:** A unique, non-transferable token (represented internally) assigned to each user, whose attributes change based on their Influence.
2.  **Paths:** Configurable categories representing areas of contribution or specialization (e.g., Builder, Lore Keeper, Strategist).
3.  **Influence:** A score for each user within each Path, accumulated through activity.
4.  **Tasks:** Verifiable actions (on-chain or off-chain) that reward Influence.
5.  **Proposals:** Governance items voted on using Influence from specific Paths.

**Function Categories:**

*   **Initialization & Configuration (Admin/Oracle):** Set up paths, oracles, attribute mappings, thresholds.
*   **User & Stone Management:** Claiming a stone, retrieving stone data, checking user status.
*   **Influence & Path Management:** Adding influence (internal/oracle), getting influence, getting user tiers within paths, configuring path tiers.
*   **Task Management:** Creating tasks (admin/oracle), assigning tasks, verifying task completion (oracle).
*   **Proposal & Governance:** Submitting proposals, voting on proposals (using path influence), checking voting eligibility, executing proposals.
*   **Stone Dynamics:** Triggering stone attribute updates based on influence, adding history events.
*   **Querying & Viewing (Read-Only):** Getting details about users, stones, paths, tasks, proposals.
*   **System Control (Admin):** Pausing, upgrading (simulated).

**Function Summary (20+ functions):**

1.  `constructor(address _admin, address _oracle)`: Initializes contract with admin and oracle addresses.
2.  `initializePaths(string[] memory _pathNames)`: Admin function to define the available Paths.
3.  `setOracleAddress(address _oracle)`: Admin function to update the oracle address.
4.  `setAdminAddress(address _admin)`: Admin function to update the admin address.
5.  `claimInitialStone()`: User function to mint their first and only Chronicle Stone.
6.  `getUserStoneId(address _user)`: View function to get the stone ID for a user.
7.  `getStoneOwner(uint256 _stoneId)`: View function to get the owner of a stone ID.
8.  `getStoneAttribute(uint256 _stoneId, string memory _attributeName)`: View function to get a specific attribute value for a stone.
9.  `getStonePathInfluence(uint256 _stoneId, Path _path)`: View function to get influence in a specific path for a stone.
10. `getTotalUserInfluence(address _user)`: View function to get sum of influence across all paths for a user.
11. `createTask(Path _rewardPath, uint256 _rewardAmount, bytes32 _verificationHash, string memory _description)`: Admin/Oracle function to create a new verifiable task.
12. `getTaskDetails(uint256 _taskId)`: View function to get details of a task.
13. `assignTask(uint256 _taskId, address _user)`: Admin/Oracle function to assign a task to a user. (Optional, could be open tasks)
14. `completeTask(uint256 _taskId, bytes memory _verificationProof)`: Oracle function to verify task completion and reward influence.
15. `getUserTaskStatus(uint256 _taskId, address _user)`: View function to check the status of a task for a user.
16. `submitProposal(string memory _description, bytes memory _executionData, Path[] memory _requiredPaths, uint256[] memory _requiredInfluence)`: User function to submit a new governance proposal requiring specific path influence to vote.
17. `getProposal(uint256 _proposalId)`: View function to get details of a proposal.
18. `voteOnProposal(uint256 _proposalId, Path _path)`: User function to vote on a proposal using influence from a specific path.
19. `checkUserVotingEligibility(address _user, uint256 _proposalId)`: View function to check if a user meets the influence requirements to vote on a proposal.
20. `getProposalVoteCount(uint256 _proposalId, Path _path)`: View function to get vote count for a path on a proposal.
21. `executeProposal(uint256 _proposalId)`: Function to execute an approved proposal.
22. `setPathInfluenceThresholds(Path _path, uint256[] memory _thresholds, string[] memory _tierNames)`: Admin function to define influence tiers and names for a path.
23. `getUserPathTier(address _user, Path _path)`: View function to get the tier name for a user in a specific path based on influence.
24. `triggerStoneAttributeUpdate(address _user)`: Internal/Callable helper to re-calculate and update stone attributes based on current influence and tier thresholds.
25. `getStoneHistory(uint256 _stoneId)`: View function to retrieve the event history for a stone.
26. `addStoneHistoryEvent(uint256 _stoneId, string memory _eventDescription)`: Internal function to add an event to a stone's history.
27. `setStoneAttributeMapping(string memory _attributeName, Path _sourcePath, uint256[] memory _tierValues)`: Admin function to map path influence tiers to specific attribute values (e.g., Builder Tier 1 maps to "Craftsmanship": 5).
28. `getStoneAttributeMapping(string memory _attributeName)`: View function to get the configuration for an attribute mapping.
29. `useInfluenceForBoost(Path _path, uint256 _amount)`: User function (placeholder for a game/utility mechanic) to spend influence from a path for a temporary effect (simulated burn).
30. `pauseSystem()`: Admin function to pause core interactions.
31. `unpauseSystem()`: Admin function to unpause the system.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Outline & Function Summary above

/**
 * @title ChronicleForge
 * @dev A system for managing user reputation (Influence) across multiple Paths,
 *      tied to a dynamic, non-transferable "Chronicle Stone" token (SBT-like).
 *      Influence is earned via tasks and participation and used for governance.
 */
contract ChronicleForge is Ownable, Pausable, ReentrancyGuard {
    using Strings for uint256;

    // --- Error Definitions ---
    error ChronicleForge__AlreadyClaimedStone();
    error ChronicleForge__StoneDoesNotExist(uint256 stoneId);
    error ChronicleForge__UserHasNoStone(address user);
    error ChronicleForge__InvalidPath();
    error ChronicleForge__TaskNotFound(uint256 taskId);
    error ChronicleForge__TaskNotAssignedToUser(uint256 taskId, address user);
    error ChronicleForge__TaskAlreadyCompleted(uint256 taskId);
    error ChronicleForge__ProposalNotFound(uint256 proposalId);
    error ChronicleForge__ProposalAlreadyVoted(uint256 proposalId, address voter);
    error ChronicleForge__NotEnoughInfluenceForVote(address voter, Path path, uint256 required);
    error ChronicleForge__ProposalNotExecutable(uint256 proposalId);
    error ChronicleForge__ProposalNotApproved(uint256 proposalId);
    error ChronicleForge__ProposalExecutionFailed(uint256 proposalId);
    error ChronicleForge__InfluenceCannotBeZero();
    error ChronicleForge__AttributeMappingMismatch();
    error ChronicleForge__NotEnoughInfluenceForBoost(Path path, uint256 required);
    error ChronicleForge__OnlyAssignedUserCanClaimCompletion(); // If using user-claimed tasks

    // --- Enums ---
    enum Path {
        None, // Default/invalid path
        Builder,
        LoreKeeper,
        Strategist,
        Diplomat,
        Explorer
        // Add more paths as needed
    }

    enum ProposalStatus {
        Pending,
        Approved,
        Rejected,
        Executed,
        Cancelled
    }

    enum TaskStatus {
        Open,
        Assigned,
        Completed,
        Cancelled
    }

    // --- Structs ---

    struct ChronicleStone {
        uint256 stoneId; // Unique ID (matches ERC721 conceptual ID)
        address owner; // The sole owner (non-transferable)
        mapping(Path => uint256) paths_influence; // Influence score per path
        mapping(string => uint256) attributes; // Dynamic attributes derived from influence
        string[] history; // On-chain log of significant events
    }

    struct Proposal {
        uint256 proposalId;
        address proposer;
        string description;
        bytes executionData; // Data for potential contract call
        ProposalStatus status;
        uint256 submissionTimestamp;
        uint256 endTimestamp; // Voting period end (simplified)
        mapping(Path => uint256) requiredInfluence; // Influence needed per path to vote
        mapping(address => bool) hasVoted; // User has voted at all
        mapping(Path => uint256) pathVoteCounts; // Total influence voted per path
        uint256 totalWeightedVotes; // Sum of (influence * path weight) - simplified sum of influence for now
    }

    struct Task {
        uint256 taskId;
        string description;
        Path rewardPath;
        uint256 rewardAmount;
        bytes32 verificationHash; // Hash representing proof/data required for completion
        TaskStatus status;
        address assignedTo; // Address the task is assigned to (0x0 for open)
        address creator; // Admin/Oracle who created the task
    }

    struct PathConfig {
        string name;
        uint256[] influenceThresholds; // Influence amounts for tier levels
        string[] tierNames; // Names for each tier (thresholds.length == tierNames.length)
    }

    // Defines how path influence tiers map to specific stone attributes
    struct AttributeMapping {
        Path sourcePath;
        uint256[] tierValues; // Values for attribute at each tier (tierNames.length == tierValues.length)
    }

    // --- State Variables ---

    // Stone Data
    uint256 private _stoneCounter;
    mapping(address => uint256) private userStoneId; // User address -> stone ID
    mapping(uint256 => ChronicleStone) private stoneDetails; // Stone ID -> stone data

    // Path Data
    Path[] public availablePaths; // List of available Paths (enums)
    mapping(Path => PathConfig) private pathConfigs;
    mapping(string => AttributeMapping) private stoneAttributeMappings; // Attribute name -> mapping config

    // Task Data
    uint256 private _taskCounter;
    mapping(uint256 => Task) private tasks;
    // Could add mapping(address => uint256[]) userTasks;

    // Proposal Data
    uint256 private _proposalCounter;
    mapping(uint256 => Proposal) private proposals;
    uint256 public constant MIN_PROPOSAL_DURATION = 1 days; // Example voting period

    // Roles
    address private oracleAddress; // Address designated to verify external events/tasks

    // --- Events ---

    event ChronicleStoneMinted(uint256 indexed stoneId, address indexed owner);
    event InfluenceAdded(uint256 indexed stoneId, Path indexed path, uint256 amount, string reason);
    event InfluenceBurned(uint256 indexed stoneId, Path indexed path, uint256 amount, string reason);
    event StoneAttributeUpdated(uint256 indexed stoneId, string indexed attributeName, uint256 newValue);
    event PathConfigured(Path indexed path, string name, uint256[] thresholds);
    event AttributeMappingConfigured(string indexed attributeName, Path indexed sourcePath);
    event TaskCreated(uint256 indexed taskId, address indexed creator, Path rewardPath, uint256 rewardAmount);
    event TaskAssigned(uint256 indexed taskId, address indexed assignedTo);
    event TaskCompleted(uint256 indexed taskId, address indexed completedBy, Path rewardPath, uint256 rewardedAmount);
    event ProposalSubmitted(uint256 indexed proposalId, address indexed proposer, string description);
    event ProposalVoted(uint256 indexed proposalId, address indexed voter, Path indexed path, uint256 influenceUsed);
    event ProposalStatusChanged(uint256 indexed proposalId, ProposalStatus newStatus);
    event ProposalExecuted(uint255 indexed proposalId);
    event StoneHistoryEvent(uint256 indexed stoneId, uint256 indexed timestamp, string eventDescription);
    event SystemPaused();
    event SystemUnpaused();

    // --- Modifiers ---

    modifier onlyOracle() {
        require(msg.sender == oracleAddress, "ChronicleForge: Only oracle can call this");
        _;
    }

    modifier hasStone(address _user) {
        require(userStoneId[_user] != 0, ChronicleForge__UserHasNoStone(_user));
        _;
    }

    // --- Constructor ---

    constructor(address _admin, address _oracle) Ownable(_admin) {
        require(_oracle != address(0), "ChronicleForge: Invalid oracle address");
        oracleAddress = _oracle;
        _stoneCounter = 0; // Stone IDs start from 1
        _taskCounter = 0;
        _proposalCounter = 0;

        // Initialize Path.None config
        pathConfigs[Path.None] = PathConfig({
            name: "None",
            influenceThresholds: new uint256[](0),
            tierNames: new string[](0)
        });
    }

    // --- Core Logic Functions ---

    /**
     * @dev Allows a user to claim their unique Chronicle Stone. Can only be done once.
     */
    function claimInitialStone() external whenNotPaused nonReentrant {
        require(userStoneId[msg.sender] == 0, ChronicleForge__AlreadyClaimedStone());

        uint256 newStoneId = ++_stoneCounter;
        userStoneId[msg.sender] = newStoneId;
        stoneDetails[newStoneId].stoneId = newStoneId;
        stoneDetails[newStoneId].owner = msg.sender;

        // Initialize influence for all paths to 0
        for (uint i = 0; i < availablePaths.length; i++) {
            stoneDetails[newStoneId].paths_influence[availablePaths[i]] = 0;
        }

        _addStoneHistoryEvent(newStoneId, "Chronicle Stone forged.");

        emit ChronicleStoneMinted(newStoneId, msg.sender);
    }

    /**
     * @dev Internal function to add influence to a user's stone.
     * @param _user The address of the user.
     * @param _path The path to add influence to.
     * @param _amount The amount of influence to add.
     * @param _reason A description of why influence was added.
     */
    function _addInfluence(address _user, Path _path, uint256 _amount, string memory _reason) internal hasStone(_user) {
        uint256 stoneId = userStoneId[_user];
        stoneDetails[stoneId].paths_influence[_path] += _amount;
        emit InfluenceAdded(stoneId, _path, _amount, _reason);
        _addStoneHistoryEvent(stoneId, string(abi.encodePacked("Influence +", _amount.toString(), " in ", pathConfigs[_path].name, " (", _reason, ")")));

        // Automatically trigger attribute update after influence change
        _triggerStoneAttributeUpdate(_user);
    }

    /**
     * @dev Internal function to burn influence from a user's stone.
     *      Can be used for mechanics where influence is a resource.
     * @param _user The address of the user.
     * @param _path The path to burn influence from.
     * @param _amount The amount of influence to burn.
     * @param _reason A description of why influence was burned.
     */
    function _burnInfluence(address _user, Path _path, uint256 _amount, string memory _reason) internal hasStone(_user) {
        uint256 stoneId = userStoneId[_user];
        require(stoneDetails[stoneId].paths_influence[_path] >= _amount, "ChronicleForge: Not enough influence to burn");
        stoneDetails[stoneId].paths_influence[_path] -= _amount;
        emit InfluenceBurned(stoneId, _path, _amount, _reason);
        _addStoneHistoryEvent(stoneId, string(abi.encodePacked("Influence -", _amount.toString(), " in ", pathConfigs[_path].name, " (", _reason, ")")));

        // Automatically trigger attribute update after influence change
        _triggerStoneAttributeUpdate(_user);
    }


    /**
     * @dev Allows oracle to complete a task and reward the assigned user with influence.
     * @param _taskId The ID of the task to complete.
     * @param _verificationProof Proof data that matches the task's verificationHash.
     */
    function completeTask(uint256 _taskId, bytes memory _verificationProof) external onlyOracle whenNotPaused nonReentrant {
        Task storage task = tasks[_taskId];
        require(task.taskId != 0, ChronicleForge__TaskNotFound(_taskId));
        require(task.status != TaskStatus.Completed, ChronicleForge__TaskAlreadyCompleted(_taskId));
        // Require specific assignment if applicable, or allow anyone to claim open task
        require(task.assignedTo == address(0) || task.assignedTo == msg.sender, "ChronicleForge: Task not assigned to this oracle");
        // Verification logic (simplified: just check if proof matches hash)
        require(keccak256(_verificationProof) == task.verificationHash, "ChronicleForge: Invalid verification proof");

        address userToReward = task.assignedTo == address(0) ? msg.sender : task.assignedTo; // Reward oracle for open tasks, or assigned user

        task.status = TaskStatus.Completed;
        _addInfluence(userToReward, task.rewardPath, task.rewardAmount, string(abi.encodePacked("Task Completion #", _taskId.toString())));

        emit TaskCompleted(_taskId, userToReward, task.rewardPath, task.rewardAmount);
    }

    /**
     * @dev Submits a new governance proposal.
     * @param _description A description of the proposal.
     * @param _executionData ABI encoded data for contract call if proposal passes (can be empty).
     * @param _requiredPaths The paths whose influence is required to vote.
     * @param _requiredInfluence The minimum influence required in each corresponding path.
     */
    function submitProposal(
        string memory _description,
        bytes memory _executionData,
        Path[] memory _requiredPaths,
        uint256[] memory _requiredInfluence
    ) external whenNotPaused nonReentrant hasStone(msg.sender) {
        require(_requiredPaths.length == _requiredInfluence.length, "ChronicleForge: Path and influence arrays must match");
        require(_requiredPaths.length > 0, "ChronicleForge: Must specify required paths for voting");
        require(_description.length > 0, "ChronicleForge: Description cannot be empty");

        uint256 newProposalId = ++_proposalCounter;
        Proposal storage newProposal = proposals[newProposalId];

        newProposal.proposalId = newProposalId;
        newProposal.proposer = msg.sender;
        newProposal.description = _description;
        newProposal.executionData = _executionData;
        newProposal.status = ProposalStatus.Pending;
        newProposal.submissionTimestamp = block.timestamp;
        newProposal.endTimestamp = block.timestamp + MIN_PROPOSAL_DURATION; // Simple fixed duration

        for (uint i = 0; i < _requiredPaths.length; i++) {
            require(_requiredPaths[i] != Path.None, ChronicleForge__InvalidPath());
            require(pathConfigs[_requiredPaths[i]].name.length > 0, "ChronicleForge: Required path not initialized");
            newProposal.requiredInfluence[_requiredPaths[i]] = _requiredInfluence[i];
        }

        emit ProposalSubmitted(newProposalId, msg.sender, _description);
    }

    /**
     * @dev Allows a user to vote on a proposal using their influence from a specific path.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _path The path whose influence the user wants to use for voting.
     */
    function voteOnProposal(uint256 _proposalId, Path _path) external whenNotPaused nonReentrant hasStone(msg.sender) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposalId != 0, ChronicleForge__ProposalNotFound(_proposalId));
        require(proposal.status == ProposalStatus.Pending, "ChronicleForge: Proposal not in pending state");
        require(block.timestamp <= proposal.endTimestamp, "ChronicleForge: Voting period has ended");
        require(!proposal.hasVoted[msg.sender], ChronicleForge__ProposalAlreadyVoted(_proposalId, msg.sender));
        require(_path != Path.None, ChronicleForge__InvalidPath());
        require(proposal.requiredInfluence[_path] > 0, "ChronicleForge: Voting not allowed using this path for this proposal"); // Must be a required path

        uint256 stoneId = userStoneId[msg.sender];
        uint256 userInfluence = stoneDetails[stoneId].paths_influence[_path];

        require(userInfluence >= proposal.requiredInfluence[_path], ChronicleForge__NotEnoughInfluenceForVote(msg.sender, _path, proposal.requiredInfluence[_path]));

        // Record vote
        proposal.hasVoted[msg.sender] = true;
        proposal.pathVoteCounts[_path] += userInfluence; // Add user's influence as weighted vote
        proposal.totalWeightedVotes += userInfluence; // Sum up total weighted votes (simplistic)

        emit ProposalVoted(_proposalId, msg.sender, _path, userInfluence);
    }

    /**
     * @dev Executes an approved proposal. Requires proposal.endTimestamp to be in the past
     *      and sufficient votes (simplified: just checks totalWeightedVotes > 0 for now).
     *      More complex voting logic (quorum, majority per path, etc.) would go here.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) external whenNotPaused nonReentrant {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposalId != 0, ChronicleForge__ProposalNotFound(_proposalId));
        require(proposal.status == ProposalStatus.Pending || proposal.status == ProposalStatus.Approved, ChronicleForge__ProposalNotExecutable(_proposalId));
        require(block.timestamp > proposal.endTimestamp, "ChronicleForge: Voting period not ended");

        // --- Simple Approval Logic: If total influence voted is > 0, it passes ---
        // In a real system, this would involve checking quorum, majority, etc.
        if (proposal.totalWeightedVotes > 0) {
             proposal.status = ProposalStatus.Approved; // Mark as approved first if logic is complex
        } else {
             proposal.status = ProposalStatus.Rejected;
             emit ProposalStatusChanged(_proposalId, ProposalStatus.Rejected);
             return; // Exit if rejected
        }
        // --- End Simple Approval Logic ---

        // Check if already marked Approved (in case approval is a separate step)
        require(proposal.status == ProposalStatus.Approved, ChronicleForge__ProposalNotApproved(_proposalId));

        proposal.status = ProposalStatus.Executed;

        // Execute the payload if exists
        if (proposal.executionData.length > 0) {
            (bool success,) = address(this).call(proposal.executionData);
            require(success, ChronicleForge__ProposalExecutionFailed(_proposalId));
        }

        emit ProposalStatusChanged(_proposalId, ProposalStatus.Executed);
        emit ProposalExecuted(_proposalId);
    }


    /**
     * @dev Allows a user to spend influence from a path. Placeholder for a game/utility mechanic.
     * @param _path The path to burn influence from.
     * @param _amount The amount of influence to spend.
     */
    function useInfluenceForBoost(Path _path, uint256 _amount) external whenNotPaused nonReentrant hasStone(msg.sender) {
         require(_amount > 0, ChronicleForge__InfluenceCannotBeZero());
         uint256 stoneId = userStoneId[msg.sender];
         require(stoneDetails[stoneId].paths_influence[_path] >= _amount, ChronicleForge__NotEnoughInfluenceForBoost(_path, _amount));

         _burnInfluence(msg.sender, _path, _amount, "Influence spent for boost");

         // TODO: Add actual boost logic here (e.g., temporary state change, unlock feature)
         // For now, it just burns the influence.
    }


    // --- Stone Dynamics ---

    /**
     * @dev Internal function to re-calculate and update stone attributes based on current influence and mappings.
     * @param _user The address of the user.
     */
    function _triggerStoneAttributeUpdate(address _user) internal hasStone(_user) {
        uint256 stoneId = userStoneId[_user];

        // Iterate over all configured attribute mappings
        string[] memory attributeNames = new string[](stoneAttributeMappings.length); // Need to track attribute names if not fixed
        uint attributeIndex = 0;
        // NOTE: Iterating mappings directly is not possible. A state variable listing attribute names is needed.
        // For simplicity, let's assume we have a list of attribute names somewhere or iterate known ones.
        // Let's use a fixed list for this example: "Craftsmanship", "Insight", "Strategy", etc. based on paths.

        string[] memory dynamicAttributeKeys = new string[](4); // Assuming 4 paths mapped to attributes
        dynamicAttributeKeys[0] = "Craftsmanship"; // Maps to Builder
        dynamicAttributeKeys[1] = "LoreSkill"; // Maps to LoreKeeper
        dynamicAttributeKeys[2] = "StrategicMind"; // Maps to Strategist
        dynamicAttributeKeys[3] = "DiplomaticAcumen"; // Maps to Diplomat
        // Add more based on Paths

        for (uint i = 0; i < dynamicAttributeKeys.length; i++) {
            string memory attrName = dynamicAttributeKeys[i];
            AttributeMapping storage mappingConfig = stoneAttributeMappings[attrName];

            if (mappingConfig.sourcePath != Path.None) { // Check if mapping is configured
                 uint256 currentInfluence = stoneDetails[stoneId].paths_influence[mappingConfig.sourcePath];
                 uint256 currentValue = 0; // Default value if no tiers

                 // Find the corresponding tier value based on influence thresholds
                 PathConfig storage pathConfig = pathConfigs[mappingConfig.sourcePath];
                 require(pathConfig.influenceThresholds.length == mappingConfig.tierValues.length, ChronicleForge__AttributeMappingMismatch());

                 for(uint j = 0; j < pathConfig.influenceThresholds.length; j++) {
                     if (currentInfluence >= pathConfig.influenceThresholds[j]) {
                         currentValue = mappingConfig.tierValues[j];
                     } else {
                         break; // Influence is below this threshold and subsequent ones
                     }
                 }

                 if (stoneDetails[stoneId].attributes[attrName] != currentValue) {
                    stoneDetails[stoneId].attributes[attrName] = currentValue;
                    emit StoneAttributeUpdated(stoneId, attrName, currentValue);
                 }
            }
        }
    }


    /**
     * @dev Internal function to add an event string to a stone's history log.
     * @param _stoneId The ID of the stone.
     * @param _eventDescription The description of the event.
     */
    function _addStoneHistoryEvent(uint256 _stoneId, string memory _eventDescription) internal {
         require(_stoneId != 0, ChronicleForge__StoneDoesNotExist(_stoneId));
         stoneDetails[_stoneId].history.push(string(abi.encodePacked(block.timestamp.toString(), ": ", _eventDescription)));
         emit StoneHistoryEvent(_stoneId, block.timestamp, _eventDescription);
    }

    // --- Configuration & Admin/Oracle Functions ---

    /**
     * @dev Admin function to initialize the available Paths in the system.
     *      Can only be called once per path name.
     * @param _pathNames Array of string names for the paths.
     */
    function initializePaths(string[] memory _pathNames) external onlyOwner {
        for (uint i = 0; i < _pathNames.length; i++) {
            string memory pathName = _pathNames[i];
            // Use keccak256 hash of name to get deterministic Path enum value
            Path newPath = Path(uint8(keccak256(abi.encodePacked(pathName))[0])); // Simple hash to enum mapping

            // Check if path already exists using the name mapping
            bool exists = false;
            for(uint j = 0; j < availablePaths.length; j++) {
                if (pathConfigs[availablePaths[j]].name == pathName) {
                    exists = true;
                    break;
                }
            }
            require(!exists, string(abi.encodePacked("ChronicleForge: Path '", pathName, "' already exists")));

            pathConfigs[newPath] = PathConfig({
                name: pathName,
                influenceThresholds: new uint256[](0), // Initialize with no tiers
                tierNames: new string[](0)
            });
            availablePaths.push(newPath);
             emit PathConfigured(newPath, pathName, new uint256[](0));
        }
    }

    /**
     * @dev Admin function to define influence thresholds and tier names for a specific path.
     *      The length of thresholds and tierNames must match.
     * @param _path The path enum to configure.
     * @param _thresholds Array of influence amounts marking the start of each tier. Must be sorted ascending.
     * @param _tierNames Array of names for each tier.
     */
    function setPathInfluenceThresholds(Path _path, uint256[] memory _thresholds, string[] memory _tierNames) external onlyOwner {
        require(pathConfigs[_path].name.length > 0, ChronicleForge__InvalidPath()); // Path must be initialized
        require(_thresholds.length == _tierNames.length, "ChronicleForge: Thresholds and tier names lengths must match");

        // Optional: Add check that thresholds are sorted ascending

        pathConfigs[_path].influenceThresholds = _thresholds;
        pathConfigs[_path].tierNames = _tierNames;

        emit PathConfigured(_path, pathConfigs[_path].name, _thresholds);

        // Trigger updates for all users? Expensive. Better to update on next influence change.
        // Or add a function to trigger for a specific user/subset.
    }

     /**
      * @dev Admin function to configure how a stone attribute's value is derived from path influence tiers.
      *      The length of tierValues must match the number of tiers defined for the sourcePath.
      * @param _attributeName The name of the stone attribute.
      * @param _sourcePath The path whose influence determines this attribute.
      * @param _tierValues The value the attribute takes at each corresponding tier of the sourcePath.
      */
     function setStoneAttributeMapping(string memory _attributeName, Path _sourcePath, uint256[] memory _tierValues) external onlyOwner {
         require(pathConfigs[_sourcePath].name.length > 0, ChronicleForge__InvalidPath()); // Source path must be initialized
         require(pathConfigs[_sourcePath].tierNames.length == _tierValues.length, "ChronicleForge: Tier values length must match source path tier count");

         stoneAttributeMappings[_attributeName] = AttributeMapping({
             sourcePath: _sourcePath,
             tierValues: _tierValues
         });

         emit AttributeMappingConfigured(_attributeName, _sourcePath);

         // Trigger attribute updates for affected stones? Same issue as setPathInfluenceThresholds.
     }


    /**
     * @dev Admin/Oracle function to create a new task.
     * @param _rewardPath The path whose influence will be rewarded.
     * @param _rewardAmount The amount of influence to reward.
     * @param _verificationHash A hash representing the requirement for completing the task (e.g., hash of proof data, hash of external event ID).
     * @param _description A description of the task.
     */
    function createTask(
        Path _rewardPath,
        uint256 _rewardAmount,
        bytes32 _verificationHash,
        string memory _description
    ) external onlyOracle whenNotPaused {
        require(pathConfigs[_rewardPath].name.length > 0, ChronicleForge__InvalidPath());
        require(_rewardAmount > 0, ChronicleForge__InfluenceCannotBeZero());
        require(_description.length > 0, "ChronicleForge: Description cannot be empty");

        uint256 newTaskId = ++_taskCounter;
        tasks[newTaskId] = Task({
            taskId: newTaskId,
            description: _description,
            rewardPath: _rewardPath,
            rewardAmount: _rewardAmount,
            verificationHash: _verificationHash,
            status: TaskStatus.Open, // Initially open, can be assigned later or open for any oracle
            assignedTo: address(0),
            creator: msg.sender
        });

        emit TaskCreated(newTaskId, msg.sender, _rewardPath, _rewardAmount);
    }

    /**
     * @dev Admin/Oracle function to assign an open task to a specific user.
     * @param _taskId The ID of the task to assign.
     * @param _user The address of the user to assign the task to.
     */
    function assignTask(uint256 _taskId, address _user) external onlyOracle whenNotPaused {
        Task storage task = tasks[_taskId];
        require(task.taskId != 0, ChronicleForge__TaskNotFound(_taskId));
        require(task.status == TaskStatus.Open, "ChronicleForge: Task is not open");
        require(_user != address(0), "ChronicleForge: Cannot assign to zero address");
        // Optional: require user has a stone

        task.status = TaskStatus.Assigned;
        task.assignedTo = _user;

        emit TaskAssigned(_taskId, _user);
    }

    /**
     * @dev Sets the address of the oracle.
     * @param _oracle The new oracle address.
     */
    function setOracleAddress(address _oracle) external onlyOwner {
        require(_oracle != address(0), "ChronicleForge: Invalid oracle address");
        oracleAddress = _oracle;
    }

    /**
     * @dev Sets the address of the admin (overrides Ownable transferOwnership).
     * @param _admin The new admin address.
     */
    function setAdminAddress(address _admin) external onlyOwner {
        require(_admin != address(0), "ChronicleForge: Invalid admin address");
        transferOwnership(_admin); // Use Ownable's transfer
    }


    // --- System Control ---

    /**
     * @dev Pauses the system, preventing most interactions.
     */
    function pauseSystem() external onlyOwner {
        _pause();
        emit SystemPaused();
    }

    /**
     * @dev Unpauses the system.
     */
    function unpauseSystem() external onlyOwner {
        _unpause();
        emit SystemUnpaused();
    }

    // --- Querying & Viewing Functions ---

    /**
     * @dev Gets the stone ID associated with a user address.
     * @param _user The address of the user.
     * @return The stone ID (0 if user has no stone).
     */
    function getUserStoneId(address _user) external view returns (uint256) {
        return userStoneId[_user];
    }

     /**
      * @dev Gets the owner of a specific stone ID.
      * @param _stoneId The ID of the stone.
      * @return The owner's address (0x0 if stone does not exist or is not owned).
      */
    function getStoneOwner(uint256 _stoneId) external view returns (address) {
         // Check if stoneDetails[_stoneId] exists by checking its ID field
         if (stoneDetails[_stoneId].stoneId == 0 && _stoneId != 0) {
             revert ChronicleForge__StoneDoesNotExist(_stoneId);
         }
         return stoneDetails[_stoneId].owner; // Returns address(0) if stoneId is 0
    }

    /**
     * @dev Gets a specific dynamic attribute value for a stone.
     * @param _stoneId The ID of the stone.
     * @param _attributeName The name of the attribute.
     * @return The attribute value (0 if attribute not set).
     */
    function getStoneAttribute(uint256 _stoneId, string memory _attributeName) external view returns (uint256) {
        require(_stoneId != 0, ChronicleForge__StoneDoesNotExist(_stoneId));
        // Note: stoneDetails[_stoneId].attributes[_attributeName] will return 0 if not set, which is acceptable.
        return stoneDetails[_stoneId].attributes[_attributeName];
    }

    /**
     * @dev Gets the influence amount a stone has in a specific path.
     * @param _stoneId The ID of the stone.
     * @param _path The path enum.
     * @return The influence amount.
     */
    function getStonePathInfluence(uint256 _stoneId, Path _path) external view returns (uint256) {
        require(_stoneId != 0, ChronicleForge__StoneDoesNotExist(_stoneId));
        return stoneDetails[_stoneId].paths_influence[_path];
    }

    /**
     * @dev Gets the total influence a user has across all paths.
     * @param _user The address of the user.
     * @return The total influence sum.
     */
    function getTotalUserInfluence(address _user) external view hasStone(_user) returns (uint256) {
        uint256 stoneId = userStoneId[_user];
        uint256 total = 0;
        for (uint i = 0; i < availablePaths.length; i++) {
            total += stoneDetails[stoneId].paths_influence[availablePaths[i]];
        }
        return total;
    }

    /**
     * @dev Gets details for a specific task.
     * @param _taskId The ID of the task.
     * @return task details struct.
     */
    function getTaskDetails(uint256 _taskId) external view returns (Task memory) {
        require(tasks[_taskId].taskId != 0, ChronicleForge__TaskNotFound(_taskId));
        return tasks[_taskId];
    }

    /**
     * @dev Gets the verification hash required for a task.
     * @param _taskId The ID of the task.
     * @return The verification hash.
     */
     function getTaskVerificationHash(uint256 _taskId) external view returns (bytes32) {
         require(tasks[_taskId].taskId != 0, ChronicleForge__TaskNotFound(_taskId));
         return tasks[_taskId].verificationHash;
     }

     /**
      * @dev Gets the reward details for a task.
      * @param _taskId The ID of the task.
      * @return rewardPath The path influence is rewarded to.
      * @return rewardAmount The amount of influence rewarded.
      */
     function getTaskReward(uint256 _taskId) external view returns (Path rewardPath, uint256 rewardAmount) {
          require(tasks[_taskId].taskId != 0, ChronicleForge__TaskNotFound(_taskId));
          return (tasks[_taskId].rewardPath, tasks[_taskId].rewardAmount);
     }


    /**
     * @dev Gets the status of a task for a specific user.
     *      Note: This is simplified. A real system might track user attempts/assignments separately.
     * @param _taskId The ID of the task.
     * @param _user The address of the user.
     * @return The status of the task.
     */
    function getUserTaskStatus(uint256 _taskId, address _user) external view returns (TaskStatus) {
        require(tasks[_taskId].taskId != 0, ChronicleForge__TaskNotFound(_taskId));
        Task storage task = tasks[_taskId];
        if (task.assignedTo != address(0) && task.assignedTo != _user) {
            return TaskStatus.Open; // Or a specific 'NotAssigned' status
        }
        return task.status; // Returns Open, Assigned (if assigned to user), or Completed
    }

    /**
     * @dev Gets details for a specific proposal.
     * @param _proposalId The ID of the proposal.
     * @return proposal details struct.
     */
    function getProposal(uint256 _proposalId) external view returns (Proposal memory) {
        require(proposals[_proposalId].proposalId != 0, ChronicleForge__ProposalNotFound(_proposalId));
        return proposals[_proposalId];
    }

    /**
     * @dev Checks if a user is eligible to vote on a proposal based on required path influence.
     * @param _user The address of the user.
     * @param _proposalId The ID of the proposal.
     * @return true if eligible, false otherwise.
     */
    function checkUserVotingEligibility(address _user, uint256 _proposalId) external view hasStone(_user) returns (bool) {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.proposalId == 0 || proposal.status != ProposalStatus.Pending || block.timestamp > proposal.endTimestamp) {
            return false; // Proposal invalid, closed, or user already voted (basic check)
        }
        if (proposal.hasVoted[_user]) return false; // User already voted

        uint256 stoneId = userStoneId[_user];

        // Check required influence for all required paths
        for (uint i = 0; i < availablePaths.length; i++) {
            Path currentPath = availablePaths[i];
            uint256 required = proposal.requiredInfluence[currentPath];
            if (required > 0) {
                 if (stoneDetails[stoneId].paths_influence[currentPath] < required) {
                    return false; // Not enough influence in this required path
                 }
            }
        }
        return true; // Meets all required influence thresholds
    }

     /**
      * @dev Gets the vote count (total influence contributed) for a specific path on a proposal.
      * @param _proposalId The ID of the proposal.
      * @param _path The path enum.
      * @return The total influence voted using that path for the proposal.
      */
     function getProposalVoteCount(uint256 _proposalId, Path _path) external view returns (uint256) {
         require(proposals[_proposalId].proposalId != 0, ChronicleForge__ProposalNotFound(_proposalId));
         return proposals[_proposalId].pathVoteCounts[_path];
     }

     /**
      * @dev Gets the name of a path.
      * @param _path The path enum.
      * @return The name of the path.
      */
     function getPathName(Path _path) external view returns (string memory) {
         return pathConfigs[_path].name;
     }

     /**
      * @dev Gets the names of all available paths.
      * @return An array of path names.
      */
     function getAllPathNames() external view returns (string[] memory) {
         string[] memory names = new string[](availablePaths.length);
         for (uint i = 0; i < availablePaths.length; i++) {
             names[i] = pathConfigs[availablePaths[i]].name;
         }
         return names;
     }

      /**
       * @dev Gets the required influence mapping for a proposal.
       * @param _proposalId The ID of the proposal.
       * @return requiredPaths Array of paths requiring influence.
       * @return requiredInfluence Array of corresponding influence amounts required.
       */
      function getProposalRequiredInfluence(uint256 _proposalId) external view returns (Path[] memory requiredPaths, uint256[] memory requiredInfluence) {
          require(proposals[_proposalId].proposalId != 0, ChronicleForge__ProposalNotFound(_proposalId));
          Proposal storage proposal = proposals[_proposalId];

          Path[] memory paths = new Path[](availablePaths.length); // Max possible required paths
          uint256[] memory influenceAmounts = new uint256[](availablePaths.length);
          uint count = 0;

          for(uint i = 0; i < availablePaths.length; i++) {
              Path currentPath = availablePaths[i];
              uint256 required = proposal.requiredInfluence[currentPath];
              if (required > 0) {
                  paths[count] = currentPath;
                  influenceAmounts[count] = required;
                  count++;
              }
          }

          // Resize arrays to actual required paths
          requiredPaths = new Path[](count);
          requiredInfluence = new uint256[](count);
          for(uint i = 0; i < count; i++) {
              requiredPaths[i] = paths[i];
              requiredInfluence[i] = influenceAmounts[i];
          }
          return (requiredPaths, requiredInfluence);
      }

      /**
       * @dev Gets the current tier name for a user within a specific path based on their influence.
       * @param _user The address of the user.
       * @param _path The path enum.
       * @return The name of the tier. Returns empty string if user has no stone, path not found, or no tiers defined.
       */
      function getUserPathTier(address _user, Path _path) external view returns (string memory) {
          if (userStoneId[_user] == 0) return ""; // User has no stone

          uint256 stoneId = userStoneId[_user];
          PathConfig storage pathConfig = pathConfigs[_path];
          if (pathConfig.name.length == 0 || pathConfig.influenceThresholds.length == 0) return ""; // Path not configured or no tiers

          uint256 currentInfluence = stoneDetails[stoneId].paths_influence[_path];
          string memory currentTierName = "Untiered"; // Default before first tier

          for (uint i = 0; i < pathConfig.influenceThresholds.length; i++) {
              if (currentInfluence >= pathConfig.influenceThresholds[i]) {
                  currentTierName = pathConfig.tierNames[i];
              } else {
                  break; // Influence is below this threshold
              }
          }
          return currentTierName;
      }

      /**
       * @dev Gets the full history log for a stone.
       * @param _stoneId The ID of the stone.
       * @return An array of history event strings.
       */
      function getStoneHistory(uint256 _stoneId) external view returns (string[] memory) {
          require(_stoneId != 0, ChronicleForge__StoneDoesNotExist(_stoneId));
          // Need to return a copy of the dynamic array
          string[] memory historyCopy = new string[](stoneDetails[_stoneId].history.length);
          for (uint i = 0; i < stoneDetails[_stoneId].history.length; i++) {
              historyCopy[i] = stoneDetails[_stoneId].history[i];
          }
          return historyCopy;
      }

      /**
       * @dev Gets the configuration mapping for a specific stone attribute.
       * @param _attributeName The name of the attribute.
       * @return sourcePath The path whose influence drives this attribute.
       * @return tierValues Array of attribute values for each corresponding tier of the sourcePath.
       */
      function getStoneAttributeMapping(string memory _attributeName) external view returns (Path sourcePath, uint256[] memory tierValues) {
          AttributeMapping storage mappingConfig = stoneAttributeMappings[_attributeName];
          // Return empty array if not configured
          return (mappingConfig.sourcePath, mappingConfig.tierValues);
      }


    // --- Internal Helpers ---
    // (No new public/external functions needed, but these are part of the 20+ concept)

    // _triggerStoneAttributeUpdate - already counted and implemented above.
    // _addInfluence - already counted and implemented above.
    // _burnInfluence - already counted and implemented above.
    // _addStoneHistoryEvent - already counted and implemented above.

}
```