Okay, here is a Solidity smart contract concept I've designed. It combines elements of resource management, timed actions, on-chain randomness, and role-based access control within a theme of a decentralized "Alchemist Guild". It's designed to be complex and avoid duplicating standard library patterns wholesale, focusing on interconnected mechanics.

It's important to note:
1.  **Complexity:** This contract is complex and gas-intensive due to storing significant state on-chain and performing multiple operations in functions like `completeAlchemyJob`.
2.  **On-Chain Randomness:** The random number generation method used (`block.timestamp ^ block.difficulty ^ block.number ^ uint256(keccak256(abi.encodePacked(msg.sender, nonce++)))`) is *not* secure against malicious miners/validators for high-value applications. A solution like Chainlink VRF would be required in a production environment.
3.  **Gas Limits:** Functions involving complex loops or large state updates might exceed block gas limits on certain networks with lower gas limits.
4.  **Scalability:** Storing all jobs, blueprints, tools, etc., in mappings directly within one contract can become expensive to iterate or manage at scale.
5.  **Security:** This is an example for educational/demonstration purposes. A production contract would require rigorous audits.

Let's define the concept: **The Alchemist Guild**
Members can join the guild (represented by a soulbound-like status within the contract). They can collect magical essence (a token), find or buy spell blueprints (NFTs with data), acquire arcane tools (NFTs with durability), and perform alchemy jobs (timed processes using resources/tools/blueprints) which have random outcomes producing new items (NFTs) or resources. The guild has roles and basic treasury management.

---

**Smart Contract Outline: AlchemistGuild**

1.  **Contract Overview:** A decentralized protocol managing guild membership, resource generation, timed alchemy crafting jobs with random outcomes, blueprint and tool management, and basic roles/treasury.
2.  **Assets Managed (Internal State):**
    *   Guild Member Status
    *   Magical Essence Token (ERC20-like balance tracking)
    *   Spell Blueprint NFTs (ERC721-like ownership + data)
    *   Arcane Tool NFTs (ERC721-like ownership + durability)
    *   Crafted Item NFTs (ERC721-like ownership)
    *   Guild Treasury (holds Essence tokens from fees)
3.  **Key Concepts:**
    *   **Role-Based Access:** `GuildMaster`, `Artificer` (creates blueprints/tools), `Treasurer`.
    *   **Passive Resource Generation:** Members accumulate Essence over time.
    *   **Timed Jobs:** Alchemy requires a specific duration.
    *   **On-Chain Randomness:** Determines alchemy success, critical success/failure, item properties.
    *   **NFT Utility:** Blueprints define jobs, Tools are required and have durability, Membership grants access.
    *   **Treasury Management:** Fees from alchemy go to the guild treasury.
4.  **Function Summary (27 Functions):**

    *   **Admin & Setup (6 functions):**
        1.  `constructor`: Initializes contract, sets deployer as Guild Master.
        2.  `setGuildMaster`: Transfers Guild Master role.
        3.  `grantRole`: Assigns a specific role to a member.
        4.  `revokeRole`: Removes a specific role.
        5.  `setAlchemyFee`: Sets the fee for starting an alchemy job (in Essence).
        6.  `withdrawTreasury`: Guild Master or Treasurer can withdraw Essence from the treasury.
    *   **Membership (4 functions):**
        7.  `joinGuild`: Allows a user to become a guild member (potentially with a cost or condition).
        8.  `leaveGuild`: Allows a member to leave (burns membership status).
        9.  `isGuildMember`: Checks if an address is a member.
        10. `getMemberInfo`: Retrieves last resource claim time and roles for a member.
    *   **Magical Essence (Token - 5 functions):**
        11. `claimMagicalEssence`: Allows members to claim accumulated Essence based on time.
        12. `getPendingEssence`: Calculates Essence accumulated since last claim.
        13. `transferMagicalEssence`: Transfers Essence between members.
        14. `balanceOfEssence`: Gets Essence balance of an address.
        15. `_mintEssence`: Internal admin function to add Essence (e.g., initial supply, event rewards).
    *   **Blueprints (NFTs - 4 functions):**
        16. `createBlueprint`: Artificer role creates a new spell blueprint NFT. Defines recipe (resource/tool requirements), base time, possible outputs.
        17. `getBlueprintDetails`: Gets the full details of a blueprint NFT.
        18. `balanceOfBlueprints`: Gets number of blueprints owned by an address.
        19. `blueprintOwnerOf`: Gets owner of a specific blueprint token ID.
    *   **Tools (NFTs - 4 functions):**
        20. `createTool`: Artificer role creates a new arcane tool NFT with initial durability.
        21. `getToolDetails`: Gets the full details (owner, durability) of a tool NFT.
        22. `repairTool`: Allows owner to repair a tool using Essence.
        23. `toolOwnerOf`: Gets owner of a specific tool token ID.
    *   **Alchemy Jobs (Mechanics - 4 functions):**
        24. `startAlchemyJob`: Initiates a timed alchemy process using a blueprint, a tool, and consuming resources/Essence.
        25. `completeAlchemyJob`: Finalizes a completed alchemy job. Uses randomness to determine success, output items, tool durability loss.
        26. `cancelAlchemyJob`: Allows cancellation before completion (partial refund?).
        27. `getAlchemyJobDetails`: Gets the current state of an active or completed job.
    *   **Utility (1 function):**
        28. `getRandomResult`: Internal helper for generating random outcomes (acknowledging its insecurity).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// --- Smart Contract Outline: AlchemistGuild ---
// 1. Contract Overview: A decentralized protocol managing guild membership, resource generation,
//    timed alchemy crafting jobs with random outcomes, blueprint and tool management,
//    and basic roles/treasury.
// 2. Assets Managed (Internal State):
//    - Guild Member Status
//    - Magical Essence Token (ERC20-like balance tracking)
//    - Spell Blueprint NFTs (ERC721-like ownership + data)
//    - Arcane Tool NFTs (ERC721-like ownership + durability)
//    - Crafted Item NFTs (ERC721-like ownership)
//    - Guild Treasury (holds Essence tokens from fees)
// 3. Key Concepts:
//    - Role-Based Access: GuildMaster, Artificer, Treasurer.
//    - Passive Resource Generation: Members accumulate Essence over time.
//    - Timed Jobs: Alchemy requires a specific duration.
//    - On-Chain Randomness: Determines alchemy success, critical success/failure, item properties.
//    - NFT Utility: Blueprints define jobs, Tools are required and have durability, Membership grants access.
//    - Treasury Management: Fees from alchemy go to the guild treasury.
// 4. Function Summary (28 Functions):
//    - Admin & Setup (6): constructor, setGuildMaster, grantRole, revokeRole, setAlchemyFee, withdrawTreasury
//    - Membership (4): joinGuild, leaveGuild, isGuildMember, getMemberInfo
//    - Magical Essence (Token - 5): claimMagicalEssence, getPendingEssence, transferMagicalEssence, balanceOfEssence, _mintEssence (internal admin)
//    - Blueprints (NFTs - 4): createBlueprint, getBlueprintDetails, balanceOfBlueprints, blueprintOwnerOf
//    - Tools (NFTs - 4): createTool, getToolDetails, repairTool, toolOwnerOf
//    - Alchemy Jobs (Mechanics - 4): startAlchemyJob, completeAlchemyJob, cancelAlchemyJob, getAlchemyJobDetails
//    - Utility (1): getRandomResult (internal helper)

contract AlchemistGuild {

    // --- Events ---
    event GuildMemberJoined(address indexed member);
    event GuildMemberLeft(address indexed member);
    event RoleGranted(address indexed member, string role);
    event RoleRevoked(address indexed member, string role);
    event EssenceClaimed(address indexed member, uint256 amount);
    event EssenceTransferred(address indexed from, address indexed to, uint256 amount);
    event AlchemyFeeSet(uint256 newFee);
    event BlueprintCreated(uint256 indexed blueprintId, string name, address indexed creator);
    event ToolCreated(uint256 indexed toolId, string name, address indexed creator);
    event ToolRepaired(uint256 indexed toolId, uint256 durabilityRestored);
    event AlchemyJobStarted(uint256 indexed jobId, address indexed owner, uint256 blueprintId, uint256 toolId, uint256 startTime, uint256 duration);
    event AlchemyJobCompleted(uint256 indexed jobId, address indexed owner, bool success, uint256 craftedItemId); // CraftedItemId is 0 if no item produced
    event AlchemyJobCancelled(uint256 indexed jobId, address indexed owner);
    event TreasuryWithdrawn(address indexed receiver, uint256 amount);

    // --- Errors ---
    error NotGuildMember();
    error AlreadyGuildMember();
    error InsufficientEssence();
    error InsufficientResources();
    error InvalidBlueprint();
    error InvalidTool();
    error ToolNotOwned(uint256 toolId, address owner);
    error BlueprintNotOwned(uint256 blueprintId, address owner);
    error ToolDurabilityTooLow(uint256 toolId, uint256 required);
    error AlchemyJobInProgress(address owner);
    error NoActiveAlchemyJob(address owner);
    error AlchemyJobNotComplete(uint256 jobId);
    error AlchemyJobAlreadyCompleted(uint256 jobId);
    error InvalidJobId();
    error NotGuildMaster();
    error NotArtificer();
    error NotTreasurer();
    error NoPermission(string role);
    error InsufficientTreasuryBalance(uint256 required);

    // --- Data Structures ---

    struct MemberInfo {
        bool isMember;
        uint48 lastEssenceClaimTime; // Block timestamp of last claim
        mapping(string => bool) roles; // e.g., "GuildMaster", "Artificer", "Treasurer"
    }

    struct Blueprint {
        bool exists;
        string name;
        mapping(uint256 => uint256) requiredResources; // ResourceId => Amount (ResourceId 0 is Essence)
        uint256 requiredToolType; // Tool Type ID required (e.g., 1: Mortar, 2: Alembic)
        uint32 baseDuration; // Base time in seconds
        mapping(uint256 => uint256) possibleOutputs; // OutputItem NFT Type ID => Weight (for randomness)
        uint16 successChance; // Chance out of 10000 (e.g., 9500 for 95%)
        uint16 criticalSuccessChance; // Chance out of 10000
        uint16 criticalFailureChance; // Chance out of 10000
    }

    struct Tool {
        bool exists;
        address owner; // NFT-like ownership
        uint256 toolType; // e.g., 1, 2, etc.
        uint16 durability; // Current durability points
        uint16 maxDurability; // Max durability
        uint16 durabilityLossPerUse; // How much durability is lost per alchemy job
        uint256 repairCostEssence; // Cost to restore 1 durability point
    }

    enum AlchemyJobStatus {
        None,
        InProgress,
        Completed,
        Cancelled
    }

    struct AlchemyJob {
        bool exists;
        address owner;
        uint256 blueprintId;
        uint256 toolId;
        uint48 startTime; // Block timestamp
        uint32 duration; // In seconds
        AlchemyJobStatus status;
        bool success; // Result of the job (if completed)
        uint256 craftedItemId; // ID of the produced item (if any)
    }

    // --- State Variables ---

    address public guildMaster;
    uint256 public alchemyFee = 100; // Fee in Magical Essence per job
    uint256 public essenceGenerationRate = 1; // Essence per second per member (simplified)

    // Balances and Ownership (simplified internal tracking vs full ERC standards)
    mapping(address => uint255) private essenceBalances; // Using uint255 to avoid overflow with uint256 max
    uint256 public totalEssenceSupply;
    mapping(address => uint256) public blueprintTokenCount;
    mapping(uint256 => address) public blueprintOwners; // BlueprintId => Owner
    mapping(address => uint224) public toolTokenCount; // Using uint224, assuming less tools than blueprints
    mapping(uint256 => address) public toolOwners; // ToolId => Owner
    mapping(address => uint256) public craftedItemTokenCount;
    mapping(uint256 => address) public craftedItemOwners; // CraftedItemId => Owner

    // Guild State
    mapping(address => MemberInfo) public members;
    uint256 public totalMembers;

    // Asset Data
    uint256 private nextBlueprintId = 1;
    mapping(uint256 => Blueprint) public blueprints;
    uint256 private nextToolId = 1;
    mapping(uint256 => Tool) public tools;
    uint256 private nextCraftedItemId = 1;
    // Assume Crafted Items are just IDs for now, data is within blueprint output definition
    // mapping(uint256 => CraftedItem) public craftedItems; // Can add struct later if needed

    // Alchemy Jobs
    uint256 private nextAlchemyJobId = 1;
    mapping(uint256 => AlchemyJob) public alchemyJobs;
    mapping(address => uint256) public activeAlchemyJobId; // Track the single active job per member

    // Randomness nonce (simple, insecure)
    uint256 private nonce = 0;

    // --- Modifiers ---
    modifier onlyGuildMaster() {
        if (msg.sender != guildMaster) revert NotGuildMaster();
        _;
    }

    modifier onlyRole(string memory role_) {
        if (!members[msg.sender].roles[role_]) revert NoPermission(role_);
        _;
    }

    modifier onlyMember() {
        if (!members[msg.sender].isMember) revert NotGuildMember();
        _;
    }

    // --- Constructor ---
    constructor() {
        guildMaster = msg.sender;
        members[msg.sender].isMember = true;
        members[msg.sender].roles["GuildMaster"] = true;
        members[msg.sender].lastEssenceClaimTime = uint48(block.timestamp);
        totalMembers = 1;
        emit GuildMemberJoined(msg.sender);
        emit RoleGranted(msg.sender, "GuildMaster");

        // Example initial setup (optional, can be done via Artificer role later)
        // _mintEssence(msg.sender, 10000); // Give initial essence
    }

    // --- Admin & Setup Functions ---

    // 1. setGuildMaster: Transfers the Guild Master role.
    function setGuildMaster(address _newGuildMaster) external onlyGuildMaster {
        members[guildMaster].roles["GuildMaster"] = false;
        guildMaster = _newGuildMaster;
        members[_newGuildMaster].isMember = true; // New master must be a member
        members[_newGuildMaster].roles["GuildMaster"] = true;
        members[_newGuildMaster].lastEssenceClaimTime = uint48(block.timestamp); // Reset claim time for new master
        emit RoleGranted(_newGuildMaster, "GuildMaster");
        // Note: This doesn't revoke membership if the old master isn't member by other means
    }

    // 2. grantRole: Grants a specific role to a guild member.
    function grantRole(address _member, string calldata _role) external onlyGuildMaster {
        if (!members[_member].isMember) revert NotGuildMember();
        members[_member].roles[_role] = true;
        emit RoleGranted(_member, _role);
    }

    // 3. revokeRole: Revokes a specific role from a guild member.
    function revokeRole(address _member, string calldata _role) external onlyGuildMaster {
        // Cannot revoke GuildMaster role this way, use setGuildMaster
        require(bytes(_role).length > 0 && keccak256(abi.encodePacked(_role)) != keccak256(abi.encodePacked("GuildMaster")), "Cannot revoke GuildMaster role");
        members[_member].roles[_role] = false;
        emit RoleRevoked(_member, _role);
    }

    // 4. setAlchemyFee: Sets the Magical Essence fee required to start an alchemy job.
    function setAlchemyFee(uint256 _newFee) external onlyGuildMaster {
        alchemyFee = _newFee;
        emit AlchemyFeeSet(_newFee);
    }

     // 5. withdrawTreasury: Allows authorized roles to withdraw accumulated fees from the contract.
    function withdrawTreasury(address _receiver, uint256 _amount) external {
        if (!(msg.sender == guildMaster || members[msg.sender].roles["Treasurer"])) revert NoPermission("GuildMaster or Treasurer");
        if (_amount > essenceBalances[address(this)]) revert InsufficientTreasuryBalance(_amount);

        essenceBalances[address(this)] -= _amount;
        essenceBalances[_receiver] += _amount;
        emit TreasuryWithdrawn(_receiver, _amount);
    }

    // 6. _mintEssence: Internal function to mint new essence (e.g., for initial supply, rewards).
    function _mintEssence(address _to, uint256 _amount) internal onlyGuildMaster {
        essenceBalances[_to] += uint255(_amount);
        totalEssenceSupply += _amount;
        // No event for internal minting directly, maybe wrap in another function with an event if needed externally
    }

    // --- Membership Functions ---

    // 7. joinGuild: Allows a user to become a guild member.
    function joinGuild() external {
        if (members[msg.sender].isMember) revert AlreadyGuildMember();
        members[msg.sender].isMember = true;
        members[msg.sender].lastEssenceClaimTime = uint48(block.timestamp); // Start essence generation timer
        totalMembers++;
        emit GuildMemberJoined(msg.sender);
    }

    // 8. leaveGuild: Allows a guild member to leave.
    function leaveGuild() external onlyMember {
        // Check for active jobs? For simplicity, let's allow leaving but the job might get stuck or cancelled
        // if (activeAlchemyJobId[msg.sender] != 0) { /* Decide policy: require cancellation, auto-cancel, etc. */ }

        delete members[msg.sender]; // This removes member status and roles
        totalMembers--;
        emit GuildMemberLeft(msg.sender);
    }

    // 9. isGuildMember: Checks if an address is a member.
    function isGuildMember(address _addr) external view returns (bool) {
        return members[_addr].isMember;
    }

    // 10. getMemberInfo: Retrieves details about a guild member.
    function getMemberInfo(address _member) external view returns (bool isMember, uint48 lastEssenceClaimTime, bool isGuildMaster_, bool isArtificer_, bool isTreasurer_) {
        MemberInfo storage member = members[_member];
        return (
            member.isMember,
            member.lastEssenceClaimTime,
            member.roles["GuildMaster"],
            member.roles["Artificer"],
            member.roles["Treasurer"]
        );
    }


    // --- Magical Essence Functions ---

    // 11. claimMagicalEssence: Allows members to claim accumulated passive essence.
    function claimMagicalEssence() external onlyMember {
        uint256 pending = getPendingEssence(msg.sender);
        if (pending == 0) return; // Nothing to claim

        members[msg.sender].lastEssenceClaimTime = uint48(block.timestamp);
        essenceBalances[msg.sender] += uint255(pending);
        emit EssenceClaimed(msg.sender, pending);
    }

    // 12. getPendingEssence: Calculates how much essence a member has accumulated.
    function getPendingEssence(address _member) public view returns (uint256) {
        MemberInfo storage member = members[_member];
        if (!member.isMember) return 0;

        uint256 timeElapsed = block.timestamp - member.lastEssenceClaimTime;
        return timeElapsed * essenceGenerationRate;
    }

    // 13. transferMagicalEssence: Transfers essence between addresses.
    function transferMagicalEssence(address _to, uint256 _amount) external {
        if (essenceBalances[msg.sender] < _amount) revert InsufficientEssence();
        essenceBalances[msg.sender] -= uint255(_amount);
        essenceBalances[_to] += uint255(_amount);
        emit EssenceTransferred(msg.sender, _to, _amount);
    }

    // 14. balanceOfEssence: Gets the Magical Essence balance of an address.
    function balanceOfEssence(address _addr) external view returns (uint256) {
        return essenceBalances[_addr];
    }

    // --- Blueprints Functions (NFT-like) ---

    // 15. createBlueprint: Allows the Artificer role to create new blueprints.
    function createBlueprint(
        string calldata _name,
        uint256 _requiredToolType,
        uint32 _baseDuration,
        uint16 _successChance,
        uint16 _criticalSuccessChance,
        uint16 _criticalFailureChance,
        uint256[] calldata _resourceIds,
        uint256[] calldata _resourceAmounts,
        uint256[] calldata _outputItemTypes,
        uint256[] calldata _outputItemWeights
    ) external onlyRole("Artificer") returns (uint256 blueprintId) {
        require(_resourceIds.length == _resourceAmounts.length, "Resource arrays mismatch");
        require(_outputItemTypes.length == _outputItemWeights.length, "Output arrays mismatch");
        // Add more validation for chances (sum <= 10000), duration > 0, etc.

        blueprintId = nextBlueprintId++;
        Blueprint storage newBlueprint = blueprints[blueprintId];
        newBlueprint.exists = true;
        newBlueprint.name = _name;
        newBlueprint.requiredToolType = _requiredToolType;
        newBlueprint.baseDuration = _baseDuration;
        newBlueprint.successChance = _successChance;
        newBlueprint.criticalSuccessChance = _criticalSuccessChance;
        newBlueprint.criticalFailureChance = _criticalFailureChance;

        for (uint i = 0; i < _resourceIds.length; i++) {
            newBlueprint.requiredResources[_resourceIds[i]] = _resourceAmounts[i];
        }
        for (uint i = 0; i < _outputItemTypes.length; i++) {
            newBlueprint.possibleOutputs[_outputItemTypes[i]] = _outputItemWeights[i];
        }

        // Blueprints are owned by the creator initially (or transferred later)
        blueprintOwners[blueprintId] = msg.sender;
        blueprintTokenCount[msg.sender]++;

        emit BlueprintCreated(blueprintId, _name, msg.sender);
    }

    // 16. getBlueprintDetails: Retrieves the full details of a blueprint.
    function getBlueprintDetails(uint256 _blueprintId) external view returns (
        string memory name,
        uint256 requiredToolType,
        uint32 baseDuration,
        uint16 successChance,
        uint16 criticalSuccessChance,
        uint16 criticalFailureChance
        // Note: Mappings (requiredResources, possibleOutputs) cannot be returned directly from view functions in this way.
        // You would need separate functions or event logs to get these details.
        // For this example, we return fixed size data.
    ) {
        Blueprint storage b = blueprints[_blueprintId];
        if (!b.exists) revert InvalidBlueprint();
        return (b.name, b.requiredToolType, b.baseDuration, b.successChance, b.criticalSuccessChance, b.criticalFailureChance);
    }

     // 17. balanceOfBlueprints: Gets the number of blueprint NFTs owned by an address.
    function balanceOfBlueprints(address _owner) external view returns (uint256) {
        return blueprintTokenCount[_owner];
    }

    // 18. blueprintOwnerOf: Gets the owner of a specific blueprint token ID.
    function blueprintOwnerOf(uint256 _blueprintId) external view returns (address) {
         if (!blueprints[_blueprintId].exists) revert InvalidBlueprint();
         return blueprintOwners[_blueprintId];
    }


    // --- Tools Functions (NFT-like with Durability) ---

    // 19. createTool: Allows the Artificer role to create new tools.
    function createTool(
        uint256 _toolType,
        string calldata _name, // Tool name is not stored per instance, just type
        uint16 _maxDurability,
        uint16 _durabilityLossPerUse,
        uint256 _repairCostEssence
    ) external onlyRole("Artificer") returns (uint256 toolId) {
        toolId = nextToolId++;
        Tool storage newTool = tools[toolId];
        newTool.exists = true;
        newTool.owner = msg.sender;
        newTool.toolType = _toolType;
        newTool.durability = _maxDurability; // Starts with max durability
        newTool.maxDurability = _maxDurability;
        newTool.durabilityLossPerUse = _durabilityLossPerUse;
        newTool.repairCostEssence = _repairCostEssence;

        toolOwners[toolId] = msg.sender; // Redundant owner tracking for clarity, owner in struct is primary
        toolTokenCount[msg.sender]++;

        emit ToolCreated(toolId, _name, msg.sender);
    }

    // 20. getToolDetails: Retrieves details about a tool.
    function getToolDetails(uint256 _toolId) external view returns (
        address owner,
        uint256 toolType,
        uint16 durability,
        uint16 maxDurability,
        uint16 durabilityLossPerUse,
        uint256 repairCostEssence
    ) {
        Tool storage t = tools[_toolId];
        if (!t.exists) revert InvalidTool();
        return (t.owner, t.toolType, t.durability, t.maxDurability, t.durabilityLossPerUse, t.repairCostEssence);
    }

    // 21. repairTool: Allows a tool owner to repair it using Essence.
    function repairTool(uint256 _toolId, uint16 _amountToRepair) external onlyMember {
        Tool storage tool = tools[_toolId];
        if (!tool.exists) revert InvalidTool();
        if (tool.owner != msg.sender) revert ToolNotOwned(_toolId, msg.sender);

        uint16 repairNeeded = tool.maxDurability - tool.durability;
        if (_amountToRepair > repairNeeded) {
            _amountToRepair = repairNeeded; // Don't repair more than needed
        }
        if (_amountToRepair == 0) return; // Nothing to repair

        uint256 cost = uint256(_amountToRepair) * tool.repairCostEssence;
        if (essenceBalances[msg.sender] < cost) revert InsufficientEssence();

        essenceBalances[msg.sender] -= uint255(cost);
        tool.durability += _amountToRepair;
        emit ToolRepaired(_toolId, _amountToRepair);
    }

     // 22. toolOwnerOf: Gets the owner of a specific tool token ID.
    function toolOwnerOf(uint256 _toolId) external view returns (address) {
         if (!tools[_toolId].exists) revert InvalidTool();
         return tools[_toolId].owner;
    }


    // --- Alchemy Job Functions ---

    // 23. startAlchemyJob: Initiates a timed alchemy process.
    function startAlchemyJob(uint256 _blueprintId, uint256 _toolId) external onlyMember {
        if (activeAlchemyJobId[msg.sender] != 0) revert AlchemyJobInProgress(msg.sender);

        Blueprint storage blueprint = blueprints[_blueprintId];
        if (!blueprint.exists) revert InvalidBlueprint();

        Tool storage tool = tools[_toolId];
        if (!tool.exists) revert InvalidTool();
        if (tool.owner != msg.sender) revert ToolNotOwned(_toolId, msg.sender);
        if (tool.toolType != blueprint.requiredToolType) revert InvalidTool(); // Tool type must match blueprint
        if (tool.durability < tool.durabilityLossPerUse) revert ToolDurabilityTooLow(_toolId, tool.durabilityLossPerUse); // Tool needs minimum durability

        // Check and consume resources
        for (uint256 resourceId = 0; resourceId < 256; resourceId++) { // Iterate over possible resource IDs (0=Essence, others assumed)
            uint256 requiredAmount = blueprint.requiredResources[resourceId];
            if (requiredAmount > 0) {
                if (resourceId == 0) { // Resource 0 is Magical Essence
                    if (essenceBalances[msg.sender] < requiredAmount) revert InsufficientEssence();
                    essenceBalances[msg.sender] -= uint255(requiredAmount);
                } else {
                    // Assume other resources are tracked elsewhere (e.g., in member struct or separate mappings)
                    // For this example, we'll just check Essence and the Alchemy Fee
                    // require(member.resourceBalances[resourceId] >= requiredAmount, InsufficientResources());
                    // member.resourceBalances[resourceId] -= requiredAmount;
                     revert InsufficientResources(); // Placeholder: Implement real resource tracking if needed
                }
            }
        }

        // Consume Alchemy Fee (in Essence)
        if (essenceBalances[msg.sender] < alchemyFee) revert InsufficientEssence();
        essenceBalances[msg.sender] -= uint255(alchemyFee);
        essenceBalances[address(this)] += uint255(alchemyFee); // Send fee to contract treasury

        // Create the job
        uint256 jobId = nextAlchemyJobId++;
        AlchemyJob storage newJob = alchemyJobs[jobId];
        newJob.exists = true;
        newJob.owner = msg.sender;
        newJob.blueprintId = _blueprintId;
        newJob.toolId = _toolId;
        newJob.startTime = uint48(block.timestamp);
        newJob.duration = blueprint.baseDuration;
        newJob.status = AlchemyJobStatus.InProgress;

        activeAlchemyJobId[msg.sender] = jobId;

        emit AlchemyJobStarted(jobId, msg.sender, _blueprintId, _toolId, newJob.startTime, newJob.duration);
    }

    // 24. completeAlchemyJob: Finalizes an alchemy job after its duration.
    function completeAlchemyJob() external onlyMember {
        uint256 jobId = activeAlchemyJobId[msg.sender];
        if (jobId == 0) revert NoActiveAlchemyJob(msg.sender);

        AlchemyJob storage job = alchemyJobs[jobId];
        if (!job.exists || job.owner != msg.sender) revert InvalidJobId(); // Should not happen if activeJobId is correct
        if (job.status == AlchemyJobStatus.Completed) revert AlchemyJobAlreadyCompleted(jobId);
        if (job.status != AlchemyJobStatus.InProgress) revert InvalidJobId(); // Should be InProgress

        if (block.timestamp < job.startTime + job.duration) revert AlchemyJobNotComplete(jobId);

        // Get outcome using randomness (insecure example)
        uint256 randomSeed = getRandomResult(10000); // Get a random number between 0 and 9999
        Blueprint storage blueprint = blueprints[job.blueprintId];
        Tool storage tool = tools[job.toolId];

        bool success = false;
        uint256 craftedItemId = 0; // 0 means no item or failure

        // Determine outcome based on chances and random number
        uint256 cumulativeChance = blueprint.successChance;
        if (randomSeed < cumulativeChance) {
            // Basic Success or Critical Success
            cumulativeChance += blueprint.criticalSuccessChance;
            if (randomSeed < cumulativeChance) {
                 // Critical Success (higher chance of better output, maybe extra item, less tool wear)
                success = true; // Still counts as success for logic below
                // Implement critical success bonus outcomes here based on blueprint.possibleOutputs
                // For this example, let's just ensure an item is crafted and maybe roll twice
                uint256 itemType1 = _selectRandomOutput(blueprint.possibleOutputs, getRandomResult(10000));
                // Optional: uint256 itemType2 = _selectRandomOutput(blueprint.possibleOutputs, getRandomResult(10000));
                 if (itemType1 > 0) {
                     craftedItemId = _mintCraftedItem(itemType1, msg.sender);
                 }
                 // Maybe reduce tool durability loss?
                 tool.durability -= (tool.durabilityLossPerUse / 2); // Half loss on crit success
            } else {
                // Basic Success
                success = true;
                uint256 itemType = _selectRandomOutput(blueprint.possibleOutputs, getRandomResult(10000));
                 if (itemType > 0) {
                     craftedItemId = _mintCraftedItem(itemType, msg.sender);
                 }
                 tool.durability -= tool.durabilityLossPerUse; // Standard loss on basic success
            }
        } else {
            // Failure or Critical Failure
            cumulativeChance += blueprint.criticalFailureChance;
            if (randomSeed >= 10000 - blueprint.criticalFailureChance) { // Check from the top end for critical failure
                 // Critical Failure (tool break? consume extra resources? negative item?)
                 success = false;
                 tool.durability = 0; // Tool breaks completely
                 // Implement critical failure penalties here
            } else {
                 // Basic Failure
                 success = false;
                 tool.durability -= tool.durabilityLossPerUse; // Standard loss on failure
            }
        }

        // Ensure durability doesn't go below zero
        if (tool.durability < 0) tool.durability = 0;

        // Update job status and results
        job.status = AlchemyJobStatus.Completed;
        job.success = success;
        job.craftedItemId = craftedItemId; // Will be 0 if no item was crafted

        // Clear active job for the user
        activeAlchemyJobId[msg.sender] = 0;

        emit AlchemyJobCompleted(jobId, msg.sender, success, craftedItemId);
    }

     // 25. cancelAlchemyJob: Allows the owner to cancel an in-progress job.
    function cancelAlchemyJob() external onlyMember {
         uint256 jobId = activeAlchemyJobId[msg.sender];
        if (jobId == 0) revert NoActiveAlchemyJob(msg.sender);

        AlchemyJob storage job = alchemyJobs[jobId];
         if (!job.exists || job.owner != msg.sender) revert InvalidJobId();
         if (job.status != AlchemyJobStatus.InProgress) revert InvalidJobId(); // Can only cancel InProgress jobs

         // Refund policy: maybe partial refund of fee or resources?
         // For simplicity in this example, no refunds on cancellation.
         // To implement refund: calculate elapsed time, refund percentage of fee/resources.

         job.status = AlchemyJobStatus.Cancelled;
         activeAlchemyJobId[msg.sender] = 0; // Clear active job

         emit AlchemyJobCancelled(jobId, msg.sender);
    }

    // 26. getAlchemyJobDetails: Retrieves the current state of a job.
    function getAlchemyJobDetails(uint256 _jobId) external view returns (
        address owner,
        uint256 blueprintId,
        uint256 toolId,
        uint48 startTime,
        uint32 duration,
        AlchemyJobStatus status,
        bool success,
        uint256 craftedItemId
    ) {
        AlchemyJob storage job = alchemyJobs[_jobId];
        if (!job.exists) revert InvalidJobId();
        return (job.owner, job.blueprintId, job.toolId, job.startTime, job.duration, job.status, job.success, job.craftedItemId);
    }


    // --- Utility Functions ---

    // 27. checkRole: Public function to check if a member has a specific role.
    function checkRole(address _member, string calldata _role) external view returns (bool) {
        return members[_member].roles[_role];
    }

    // 28. getRandomResult: Insecure on-chain pseudo-random number generator (Helper).
    // WARNING: Do NOT use this for high-value or security-sensitive randomness.
    // Use Chainlink VRF or similar decentralized oracle for secure randomness.
    function getRandomResult(uint256 _max) internal returns (uint256) {
         uint256 randomSeed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, block.number, msg.sender, nonce++)));
         return randomSeed % _max;
    }

    // --- Internal Helper Functions (for internal mechanics) ---

    // Internal function to select a random output item type based on weights.
    function _selectRandomOutput(mapping(uint256 => uint256) storage _possibleOutputs, uint256 _randomNumber) internal view returns (uint256 itemType) {
        uint256 totalWeight = 0;
        // Iterate through all possible output item types defined in the blueprint
        // Note: Iterating mappings like this can be inefficient or require prior knowledge of keys.
        // A better approach might store keys in an array alongside the mapping.
        // For simplicity here, we'll demonstrate the logic assuming we know the keys or iterate a fixed small range.
        // In a real system, iterate over stored keys/item types.
        // Let's assume output item types are contiguous from 1 up to some limit for this example.
        // A more robust design would store output types in an array in the Blueprint struct.

        // Example implementation assuming _possibleOutputs maps 1 => weight, 2 => weight, etc.
        // Find total weight
        uint256[] memory outputTypes; // Placeholder: Need to populate this in a real blueprint struct
        // For demonstration, let's manually sum a few potential types (replace with dynamic logic)
        // Assuming keys 1, 2, 3 might exist as output types.
        uint256 demoTotalWeight = _possibleOutputs[1] + _possibleOutputs[2] + _possibleOutputs[3]; // Example sum

        uint256 rand = _randomNumber % demoTotalWeight;
        uint256 cumulativeWeight = 0;

        // Iterate through possible outputs and select based on random number
        // Again, this iteration needs a way to get the keys dynamically or from a stored array.
        // Manual check for demo keys:
        if (_possibleOutputs[1] > 0) {
             cumulativeWeight += _possibleOutputs[1];
             if (rand < cumulativeWeight) return 1;
        }
         if (_possibleOutputs[2] > 0) {
             cumulativeWeight += _possibleOutputs[2];
             if (rand < cumulativeWeight) return 2;
        }
         if (_possibleOutputs[3] > 0) {
             cumulativeWeight += _possibleOutputs[3];
             if (rand < cumulativeWeight) return 3;
        }
        // ... add more checks for other possible output keys

        // If no item is selected (weights might not sum to total or mapping iteration is issue)
        return 0; // Represents no item crafted
    }

    // Internal function to mint a new Crafted Item NFT.
    function _mintCraftedItem(uint256 _itemType, address _to) internal returns (uint256 craftedItemId) {
        craftedItemId = nextCraftedItemId++;
        craftedItemOwners[craftedItemId] = _to;
        craftedItemTokenCount[_to]++;
        // No explicit struct for CraftedItem data here, assuming itemType implies properties or data is external.
        // Add event for Crafted Item Minted if needed.
    }

    // Internal function to transfer blueprint ownership (basic NFT transfer logic).
    // Could be made external if blueprint trading is desired.
    function _transferBlueprint(address _from, address _to, uint256 _blueprintId) internal {
         require(blueprintOwners[_blueprintId] == _from, "Blueprint: Not owned by from");
         blueprintTokenCount[_from]--;
         blueprintOwners[_blueprintId] = _to;
         blueprintTokenCount[_to]++;
         // Add Transfer event similar to ERC721 if needed
    }

     // Internal function to transfer tool ownership (basic NFT transfer logic).
    // Could be made external if tool trading is desired.
    function _transferTool(address _from, address _to, uint256 _toolId) internal {
         require(toolOwners[_toolId] == _from, "Tool: Not owned by from");
         // Update owner in the struct as well
         tools[_toolId].owner = _to;
         toolTokenCount[_from]--;
         toolOwners[_toolId] = _to;
         toolTokenCount[_to]++;
         // Add Transfer event similar to ERC721 if needed
    }

    // You would need similar internal transfer functions for Crafted Items if they are transferable.
    // For this example, Crafted Items are just minted to the job completer.

}
```