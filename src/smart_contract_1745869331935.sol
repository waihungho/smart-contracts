Okay, let's design a smart contract based on a concept of managing decentralized "Planetary Outposts". This involves resource management, time-based production, dynamic state tied to an NFT, and administrative control over global parameters, all within a single contract for illustrative purposes (in a real dApp, resources might be separate ERC-20s, and NFTs a standard ERC-721, but implementing key parts internally fulfills the "not duplicate open source" and "creative" aspect by tightly integrating the logic).

**Concept: Planetary Outposts**

Users can deploy Outposts (represented by NFTs). These outposts require resources (Energy, Materials, Data) to produce new resources. Outposts have different types, levels, and efficiency which affect production. They operate on production cycles tied to time. Outposts can be upgraded, potentially damaged, and their state influences their abilities. Global parameters (like production rates, event multipliers) can be adjusted by an admin (or potentially a DAO in a more complex version). Outpost metadata can change based on its state (level, damage, etc.), making them dynamic NFTs.

---

**Outline:**

1.  **State Variables:** Define types, mappings, and counters for Outposts, Resources, Users, and Global Settings.
2.  **Enums:** Define states for Outposts and types of Resources.
3.  **Structs:** Define the structure for an Outpost and a Global Event.
4.  **Events:** Define events for key actions (Outpost deployed, Production claimed, Upgrade, Resource transfer, etc.).
5.  **Modifiers:** Define access control modifiers (e.g., `onlyAdmin`, `outpostExists`, `onlyOutpostOwner`).
6.  **Internal/Helper Functions:** Functions used internally (e.g., calculating production, updating state).
7.  **Public/External Functions:** The main interface for users and admin.
    *   Deployment & Ownership (Deploy, Transfer, Dismantle, Query ownership)
    *   Resource Management (Feed, Claim, Transfer, Query balances)
    *   Production & State (Start Production, Upgrade, Repair, Query State/Details)
    *   Dynamic Metadata (Update URI, Query URI)
    *   Admin Controls (Set rates, Trigger Events, Set base URI)
    *   Query Functions (Calculate costs/production, Global event status)

---

**Function Summary:**

1.  `constructor()`: Initializes the contract with the deploying address as admin.
2.  `deployOutpost(uint256 outpostType)`: Mints a new Outpost NFT for the caller. Requires initial resources.
3.  `feedResources(uint256 outpostId, ResourceType resourceType, uint256 amount)`: Transfers resources from user's balance into an Outpost's reserve.
4.  `startProduction(uint256 outpostId)`: Initiates a production cycle for an outpost. Requires specific resources in the outpost's reserve and outpost to be `Idle`.
5.  `claimProduction(uint256 outpostId)`: Finalizes a production cycle, calculates output based on time elapsed and outpost stats, adds resources to user's balance, and updates outpost state/time. May incur damage chance.
6.  `upgradeOutpost(uint256 outpostId)`: Increases an outpost's level and efficiency. Requires resources from user's balance and outpost to be `Idle`.
7.  `repairOutpost(uint256 outpostId)`: Repairs a damaged outpost, changing its state from `Damaged` to `Idle`. Requires resources from user's balance.
8.  `dismantleOutpost(uint256 outpostId)`: Burns an Outpost NFT. May return a fraction of invested resources.
9.  `transferOutpost(address recipient, uint256 outpostId)`: Transfers ownership of an Outpost NFT.
10. `sendResource(address recipient, ResourceType resourceType, uint256 amount)`: Allows a user to transfer resources from their contract balance to another user's contract balance.
11. `getUserResourceBalance(address user, ResourceType resourceType)`: Returns the resource balance of a specific user.
12. `getOutpostDetails(uint256 outpostId)`: Returns the detailed state of an outpost (type, level, state, reserves, etc.).
13. `getUserOutposts(address user)`: Returns a list of Outpost IDs owned by a user.
14. `calculatePotentialProduction(uint256 outpostId)`: Calculates the *potential* production yield for one cycle *if* production were claimed now. (View function)
15. `calculateUpgradeCost(uint256 outpostId)`: Calculates the resource cost for the next upgrade of an outpost. (View function)
16. `updateMetadataURI(uint256 outpostId, string calldata newURI)`: Allows the outpost owner to set a specific metadata URI for their NFT (overrides base URI if set).
17. `tokenURI(uint256 outpostId)`: Standard ERC721 function to get the metadata URI for an outpost. Combines base URI and potential specific URI.
18. `adminSetGlobalProductionRate(uint256 outpostType, ResourceType resourceType, uint256 rate)`: Admin sets the base production rate for a specific outpost type and resource.
19. `adminSetUpgradeCost(uint256 outpostType, uint256 currentLevel, ResourceType resourceType, uint256 amount)`: Admin sets the resource cost for upgrading an outpost type at a specific level.
20. `adminTriggerGlobalEvent(string calldata eventName, int256 productionEffectMultiplier)`: Admin activates a global event that affects production rates.
21. `getGlobalEventStatus()`: Returns the details of the currently active global event. (View function)
22. `adminSetBaseMetadataURI(string calldata uri)`: Admin sets a base URI for all outpost metadata (can be used as a fallback or standard).
23. `adminSetDamageChance(uint256 chance)`: Admin sets the percentage chance (out of 10000) for an outpost to become damaged upon production claim.
24. `getDamageChance()`: Returns the current damage chance setting. (View function)

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Note: This contract is a simplified simulation.
// In a production system, resource tokens might be separate ERC-20s,
// outpost NFTs might fully implement ERC721 with a standard library,
// and admin functions might be governed by a DAO.
// This implementation keeps logic tightly integrated for demonstration
// purposes, focusing on the unique mechanics described.

interface IERC721Metadata {
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

contract PlanetaryOutposts is IERC721Metadata {

    // --- ENUMS ---
    enum OutpostState {
        Idle,
        Producing,
        Damaged
    }

    enum ResourceType {
        Energy,
        Materials,
        Data
    }

    // --- STRUCTS ---
    struct Outpost {
        address owner;
        uint256 outpostType; // e.g., 0: Basic, 1: Advanced Mining, 2: Research Hub
        uint256 level;
        uint256 efficiency; // Multiplier for production/consumption (e.g., 1000 for 100%)
        uint256 lastProductionTime; // Timestamp of last production start or claim
        mapping(ResourceType => uint256) resourceReserve; // Resources stored in the outpost
        OutpostState state;
        string metadataURI; // Specific URI for this outpost instance (overrides base)
    }

    struct GlobalEvent {
        string name;
        int256 productionEffectMultiplier; // Percentage effect (e.g., 100 for +10%, -50 for -5%) - scaled by 100
        uint256 startTime; // 0 if no active event
        uint256 duration; // Event duration in seconds
    }

    // --- STATE VARIABLES ---

    // Admin address - can be replaced by a DAO later
    address public admin;

    // Outpost storage
    mapping(uint256 => Outpost) public outposts;
    uint256 private nextOutpostId;

    // Basic NFT ownership tracking (simplified ERC721)
    mapping(uint256 => address) private outpostOwners;
    mapping(address => uint256[]) private userOutpostIds; // To get list of user's tokens

    // User resource balances within the contract
    mapping(address => mapping(ResourceType => uint256)) private userResourceBalances;

    // Global parameters (Admin settable)
    mapping(uint256 => mapping(ResourceType => uint256)) private globalProductionRates; // outpostType => resourceType => rate per second per efficiency unit
    mapping(uint256 => mapping(uint256 => mapping(ResourceType => uint256))) private globalUpgradeCosts; // outpostType => level => resourceType => amount
    mapping(uint256 => mapping(ResourceType => uint256)) private outpostTypeInitialCost; // outpostType => resourceType => amount
    mapping(uint256 => mapping(ResourceType => uint256)) private outpostTypeProductionInput; // outpostType => resourceType => amount per production cycle start
    uint256 public productionCycleDuration = 1 days; // Base duration for a production cycle
    uint256 public baseEfficiency = 1000; // Base efficiency (100%)
    uint256 public upgradeEfficiencyIncrease = 100; // Efficiency increase per level (10%)
    uint256 public dismantleResourceReturnPercent = 25; // Percentage of initial cost returned on dismantle (scaled by 100)
    uint256 private damageChanceBps = 100; // Chance of damage on claim (100 = 1%) BPS = Basis Points (1/100 of a percent)

    // Dynamic metadata base URI
    string public baseMetadataURI;

    // Global Event
    GlobalEvent public currentGlobalEvent;

    // --- EVENTS ---
    event OutpostDeployed(address indexed owner, uint256 indexed outpostId, uint256 outpostType);
    event ResourcesFed(uint256 indexed outpostId, ResourceType indexed resourceType, uint256 amount);
    event ProductionStarted(uint256 indexed outpostId, uint256 startTime);
    event ProductionClaimed(uint256 indexed outpostId, uint256 claimTime);
    event ResourcesProduced(uint256 indexed outpostId, ResourceType indexed resourceType, uint256 amount);
    event OutpostUpgraded(uint256 indexed outpostId, uint256 newLevel, uint256 newEfficiency);
    event OutpostRepaired(uint256 indexed outpostId);
    event OutpostDismantled(address indexed owner, uint256 indexed outpostId);
    event OutpostTransferred(address indexed from, address indexed to, uint256 indexed outpostId);
    event ResourceTransferred(address indexed from, address indexed to, ResourceType indexed resourceType, uint256 amount);
    event GlobalEventTriggered(string name, int256 productionEffectMultiplier, uint256 startTime, uint256 duration);
    event MetadataURIUpdated(uint256 indexed outpostId, string newURI);
    event DamageChanceUpdated(uint256 newChanceBps);

    // --- MODIFIERS ---
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }

    modifier outpostExists(uint256 _outpostId) {
        require(_outpostId > 0 && _outpostId < nextOutpostId, "Outpost does not exist");
        _;
    }

    modifier onlyOutpostOwner(uint256 _outpostId) {
        require(outpostOwners[_outpostId] == msg.sender, "Caller is not the outpost owner");
        _;
    }

    modifier outpostIdle(uint256 _outpostId) {
        require(outposts[_outpostId].state == OutpostState.Idle, "Outpost must be Idle");
        _;
    }

    modifier outpostProducing(uint256 _outpostId) {
        require(outposts[_outpostId].state == OutpostState.Producing, "Outpost must be Producing");
        _;
    }

    modifier outpostDamaged(uint256 _outpostId) {
        require(outposts[_outpostId].state == OutpostState.Damaged, "Outpost must be Damaged");
        _;
    }

    // --- CONSTRUCTOR ---
    constructor() {
        admin = msg.sender;
        nextOutpostId = 1; // Start outpost IDs from 1

        // Set some initial parameters (example values)
        // Basic Outpost (Type 0): Produces Materials, needs Energy input
        outpostTypeInitialCost[0][ResourceType.Energy] = 1000;
        outpostTypeInitialCost[0][ResourceType.Materials] = 500;
        outpostTypeProductionInput[0][ResourceType.Energy] = 200; // Energy consumed per cycle start

        // Production rates (rate per second per 1000 efficiency)
        globalProductionRates[0][ResourceType.Materials] = 10; // 10 Materials per second per 1000 efficiency

        // Upgrade costs for Type 0, Level 1 -> 2
        globalUpgradeCosts[0][1][ResourceType.Materials] = 1000;
        globalUpgradeCosts[0][1][ResourceType.Data] = 100;

        // Add more types/levels as needed
    }

    // --- EXTERNAL / PUBLIC FUNCTIONS ---

    /// @notice Deploys a new Planetary Outpost for the caller.
    /// @param _outpostType The type of outpost to deploy.
    function deployOutpost(uint256 _outpostType) external {
        require(outpostTypeInitialCost[_outpostType][ResourceType.Energy] > 0 || outpostTypeInitialCost[_outpostType][ResourceType.Materials] > 0 || outpostTypeInitialCost[_outpostType][ResourceType.Data] > 0, "Invalid outpost type or costs not set");

        uint256 currentId = nextOutpostId;
        nextOutpostId++;

        // Pay initial cost
        for (uint i = 0; i < type(ResourceType).max; i++) {
            ResourceType resType = ResourceType(i);
            uint256 cost = outpostTypeInitialCost[_outpostType][resType];
            if (cost > 0) {
                require(userResourceBalances[msg.sender][resType] >= cost, "Insufficient resources to deploy");
                userResourceBalances[msg.sender][resType] -= cost;
            }
        }

        // Create the outpost
        Outpost storage newOutpost = outposts[currentId];
        newOutpost.owner = msg.sender;
        newOutpost.outpostType = _outpostType;
        newOutpost.level = 1; // Start at level 1
        newOutpost.efficiency = baseEfficiency;
        newOutpost.lastProductionTime = block.timestamp; // Initialize time
        newOutpost.state = OutpostState.Idle;
        // Metadata URI defaults to empty, tokenURI will use baseURI

        outpostOwners[currentId] = msg.sender;
        userOutpostIds[msg.sender].push(currentId);

        emit OutpostDeployed(msg.sender, currentId, _outpostType);
    }

    /// @notice Feeds resources from the caller's balance into an outpost's reserve.
    /// @param _outpostId The ID of the outpost.
    /// @param _resourceType The type of resource to feed.
    /// @param _amount The amount of resource to feed.
    function feedResources(uint256 _outpostId, ResourceType _resourceType, uint256 _amount) external outpostExists(_outpostId) onlyOutpostOwner(_outpostId) {
        require(_amount > 0, "Amount must be greater than zero");
        require(userResourceBalances[msg.sender][_resourceType] >= _amount, "Insufficient resources in user balance");

        userResourceBalances[msg.sender][_resourceType] -= _amount;
        outposts[_outpostId].resourceReserve[_resourceType] += _amount;

        emit ResourcesFed(_outpostId, _resourceType, _amount);
    }

    /// @notice Initiates a production cycle for an outpost.
    /// @dev Requires the outpost to be Idle and have sufficient resources in its reserve.
    /// @param _outpostId The ID of the outpost.
    function startProduction(uint256 _outpostId) external outpostExists(_outpostId) onlyOutpostOwner(_outpostId) outpostIdle(_outpostId) {
        Outpost storage outpost = outposts[_outpostId];

        // Check and consume required input resources from reserve
        for (uint i = 0; i < type(ResourceType).max; i++) {
            ResourceType resType = ResourceType(i);
            uint256 requiredInput = outpostTypeProductionInput[outpost.outpostType][resType];
            if (requiredInput > 0) {
                require(outpost.resourceReserve[resType] >= requiredInput, "Insufficient resources in outpost reserve to start production");
                outpost.resourceReserve[resType] -= requiredInput;
            }
        }

        outpost.state = OutpostState.Producing;
        outpost.lastProductionTime = block.timestamp; // Record start time
        emit ProductionStarted(_outpostId, block.timestamp);
    }

    /// @notice Claims production yield from a producing outpost.
    /// @dev Calculates production based on time since last production/claim, efficiency, and global effects.
    /// @param _outpostId The ID of the outpost.
    function claimProduction(uint256 _outpostId) external outpostExists(_outpostId) onlyOutpostOwner(_outpostId) outpostProducing(_outpostId) {
        Outpost storage outpost = outposts[_outpostId];
        uint256 timeElapsed = block.timestamp - outpost.lastProductionTime;
        require(timeElapsed >= productionCycleDuration, "Production cycle not yet complete");

        // Calculate production based on time elapsed, efficiency, type, and global event
        for (uint i = 0; i < type(ResourceType).max; i++) {
            ResourceType resType = ResourceType(i);
            uint256 baseRate = globalProductionRates[outpost.outpostType][resType];

            if (baseRate > 0) {
                // Production = (baseRate * timeElapsed * efficiency / 1000)
                uint256 potentialProduction = (baseRate * timeElapsed * outpost.efficiency) / 1000;

                // Apply global event effect if active
                uint256 actualProduction = potentialProduction;
                if (currentGlobalEvent.startTime > 0 && block.timestamp < currentGlobalEvent.startTime + currentGlobalEvent.duration) {
                     // Apply effect: production = production * (1000 + effectMultiplier*10) / 1000
                    actualProduction = (actualProduction * (1000 + currentGlobalEvent.productionEffectMultiplier * 10)) / 1000;
                }

                if (actualProduction > 0) {
                    userResourceBalances[msg.sender][resType] += actualProduction;
                    emit ResourcesProduced(_outpostId, resType, actualProduction);
                }
            }
        }

        // Update outpost state and time
        outpost.state = OutpostState.Idle;
        outpost.lastProductionTime = block.timestamp; // Record claim time

        // Check for random damage
        if (damageChanceBps > 0) {
             // Use a block property for a simple form of randomness (be aware of miner manipulation)
            uint256 randomValue = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, _outpostId))) % 10000;
            if (randomValue < damageChanceBps) {
                outpost.state = OutpostState.Damaged;
                // Optionally, clear reserves or reduce efficiency upon damage
                // Example: clear reserves
                 for (uint i = 0; i < type(ResourceType).max; i++) {
                    ResourceType resType = ResourceType(i);
                     outpost.resourceReserve[resType] = 0;
                 }
            }
        }


        emit ProductionClaimed(_outpostId, block.timestamp);
    }

    /// @notice Upgrades an outpost to the next level.
    /// @dev Requires outpost to be Idle and caller to have sufficient resources.
    /// @param _outpostId The ID of the outpost.
    function upgradeOutpost(uint256 _outpostId) external outpostExists(_outpostId) onlyOutpostOwner(_outpostId) outpostIdle(_outpostId) {
        Outpost storage outpost = outposts[_outpostId];
        uint256 nextLevel = outpost.level + 1;
        bool costsExist = false;

        // Check and pay upgrade cost
        for (uint i = 0; i < type(ResourceType).max; i++) {
            ResourceType resType = ResourceType(i);
            uint256 cost = globalUpgradeCosts[outpost.outpostType][outpost.level][resType];
            if (cost > 0) {
                costsExist = true;
                require(userResourceBalances[msg.sender][resType] >= cost, "Insufficient resources to upgrade");
            }
        }

        require(costsExist, "Upgrade costs not set for next level");

        // Deduct costs
         for (uint i = 0; i < type(ResourceType).max; i++) {
            ResourceType resType = ResourceType(i);
            uint256 cost = globalUpgradeCosts[outpost.outpostType][outpost.level][resType];
             if (cost > 0) {
                 userResourceBalances[msg.sender][resType] -= cost;
             }
         }


        // Apply upgrade effects
        outpost.level = nextLevel;
        outpost.efficiency += upgradeEfficiencyIncrease; // Increase efficiency

        emit OutpostUpgraded(_outpostId, nextLevel, outpost.efficiency);
    }

    /// @notice Repairs a damaged outpost.
    /// @dev Requires outpost to be Damaged and caller to have sufficient resources (simplified cost).
    /// @param _outpostId The ID of the outpost.
    function repairOutpost(uint256 _outpostId) external outpostExists(_outpostId) onlyOutpostOwner(_outpostId) outpostDamaged(_outpostId) {
         Outpost storage outpost = outposts[_outpostId];

         // Simplified repair cost (e.g., a fraction of initial cost or fixed amount)
         // Using a simple fixed cost for now
         ResourceType repairResourceType = ResourceType.Materials; // Example: repairs need Materials
         uint256 repairCost = outpost.level * 100; // Example: cost scales with level

         require(userResourceBalances[msg.sender][repairResourceType] >= repairCost, "Insufficient resources to repair");
         userResourceBalances[msg.sender][repairResourceType] -= repairCost;

         outpost.state = OutpostState.Idle;
         outpost.lastProductionTime = block.timestamp; // Reset timer after repair

         emit OutpostRepaired(_outpostId);
    }


    /// @notice Dismantles an outpost, burning the NFT and returning a fraction of initial cost.
    /// @param _outpostId The ID of the outpost.
    function dismantleOutpost(uint256 _outpostId) external outpostExists(_outpostId) onlyOutpostOwner(_outpostId) {
        Outpost storage outpost = outposts[_outpostId];
        address owner = msg.sender;
        uint256 outpostType = outpost.outpostType;

        // Transfer any remaining resources in outpost reserve back to owner
        for (uint i = 0; i < type(ResourceType).max; i++) {
            ResourceType resType = ResourceType(i);
            uint256 reserveAmount = outpost.resourceReserve[resType];
            if (reserveAmount > 0) {
                userResourceBalances[owner][resType] += reserveAmount;
                // No specific event for this transfer back to self, covered by Dismantled event context
            }
        }

        // Return a fraction of the initial cost
        for (uint i = 0; i < type(ResourceType).max; i++) {
            ResourceType resType = ResourceType(i);
            uint256 initialCost = outpostTypeInitialCost[outpostType][resType];
            if (initialCost > 0) {
                uint256 refundAmount = (initialCost * dismantleResourceReturnPercent) / 100;
                 if (refundAmount > 0) {
                    userResourceBalances[owner][resType] += refundAmount;
                 }
            }
        }

        // "Burn" the outpost by clearing its state and ownership
        delete outposts[_outpostId];
        delete outpostOwners[_outpostId];

        // Remove from user's list (simplified, assumes appending adds to end)
        uint256[] storage userTokens = userOutpostIds[owner];
        for (uint i = 0; i < userTokens.length; i++) {
            if (userTokens[i] == _outpostId) {
                userTokens[i] = userTokens[userTokens.length - 1]; // Replace with last element
                userTokens.pop(); // Remove last element
                break; // Found and removed
            }
        }

        emit OutpostDismantled(owner, _outpostId);
    }

    /// @notice Transfers ownership of an Outpost NFT.
    /// @param _recipient The address to transfer the outpost to.
    /// @param _outpostId The ID of the outpost.
    function transferOutpost(address _recipient, uint256 _outpostId) external outpostExists(_outpostId) onlyOutpostOwner(_outpostId) {
        require(_recipient != address(0), "Cannot transfer to the zero address");
        address owner = msg.sender;

        outpostOwners[_outpostId] = _recipient;

        // Update userOutpostIds mapping (simplified removal and addition)
        uint256[] storage ownerTokens = userOutpostIds[owner];
         for (uint i = 0; i < ownerTokens.length; i++) {
            if (ownerTokens[i] == _outpostId) {
                ownerTokens[i] = ownerTokens[ownerTokens.length - 1];
                ownerTokens.pop();
                break;
            }
        }
        userOutpostIds[_recipient].push(_outpostId);

        emit OutpostTransferred(owner, _recipient, _outpostId);
    }

    /// @notice Transfers resources from the caller's balance to another user's balance within the contract.
    /// @param _recipient The address to send resources to.
    /// @param _resourceType The type of resource to transfer.
    /// @param _amount The amount of resource to transfer.
    function sendResource(address _recipient, ResourceType _resourceType, uint256 _amount) external {
        require(_recipient != address(0), "Cannot transfer to the zero address");
        require(_amount > 0, "Amount must be greater than zero");
        require(userResourceBalances[msg.sender][_resourceType] >= _amount, "Insufficient resources in user balance");

        userResourceBalances[msg.sender][_resourceType] -= _amount;
        userResourceBalances[_recipient][_resourceType] += _amount;

        emit ResourceTransferred(msg.sender, _recipient, _resourceType, _amount);
    }

    // --- QUERY FUNCTIONS (VIEW / PURE) ---

    /// @notice Returns the resource balance for a user.
    /// @param _user The user's address.
    /// @param _resourceType The type of resource.
    /// @return The amount of the specified resource the user holds.
    function getUserResourceBalance(address _user, ResourceType _resourceType) external view returns (uint256) {
        return userResourceBalances[_user][_resourceType];
    }

     /// @notice Returns the detailed information about an outpost.
     /// @param _outpostId The ID of the outpost.
     /// @return owner Address of the owner.
     /// @return outpostType Type of the outpost.
     /// @return level Current level.
     /// @return efficiency Current efficiency.
     /// @return lastProductionTime Timestamp of last production start/claim.
     /// @return state Current state (Idle, Producing, Damaged).
     /// @return resourceReserves Mapping of resources in the outpost's reserve. (Note: Cannot return full mapping directly, need helper or query per type)
    function getOutpostDetails(uint256 _outpostId)
        external
        view
        outpostExists(_outpostId)
        returns (
            address owner,
            uint256 outpostType,
            uint256 level,
            uint256 efficiency,
            uint256 lastProductionTime,
            OutpostState state
        )
    {
        Outpost storage outpost = outposts[_outpostId];
        return (
            outpost.owner,
            outpost.outpostType,
            outpost.level,
            outpost.efficiency,
            outpost.lastProductionTime,
            outpost.state
        );
    }

     /// @notice Returns the resource reserve amount for a specific resource in an outpost.
     /// @param _outpostId The ID of the outpost.
     /// @param _resourceType The type of resource.
     /// @return The amount of the specified resource in the outpost's reserve.
     function getOutpostResourceReserve(uint256 _outpostId, ResourceType _resourceType)
        external
        view
        outpostExists(_outpostId)
        returns (uint256)
    {
        return outposts[_outpostId].resourceReserve[_resourceType];
    }

    /// @notice Returns the list of Outpost IDs owned by a user.
    /// @param _user The user's address.
    /// @return An array of Outpost IDs.
    function getUserOutposts(address _user) external view returns (uint256[] memory) {
        return userOutpostIds[_user];
    }

    /// @notice Calculates the potential production yield if production was claimed now.
    /// @dev This is an estimate and doesn't account for current global events.
    /// @param _outpostId The ID of the outpost.
    /// @return A mapping of ResourceType to potential amount. (Note: Returning map impossible, return as array/struct or query per type)
    /// @return resourceTypes_ Array of resource types produced.
    /// @return amounts_ Array of corresponding production amounts.
    function calculatePotentialProduction(uint256 _outpostId)
        external
        view
        outpostExists(_outpostId)
        returns (ResourceType[] memory resourceTypes_, uint256[] memory amounts_)
    {
        Outpost storage outpost = outposts[_outpostId];
        uint256 timeElapsed = block.timestamp - outpost.lastProductionTime;
        if (outpost.state != OutpostState.Producing || timeElapsed < productionCycleDuration) {
             // Return zero if not producing or cycle not complete
             return (new ResourceType[](0), new uint256[](0));
        }

        ResourceType[] memory producedTypes = new ResourceType[](type(ResourceType).max);
        uint256[] memory productionAmounts = new uint256[](type(ResourceType).max);
        uint256 count = 0;

        for (uint i = 0; i < type(ResourceType).max; i++) {
            ResourceType resType = ResourceType(i);
            uint256 baseRate = globalProductionRates[outpost.outpostType][resType];
            if (baseRate > 0) {
                 uint256 potential = (baseRate * productionCycleDuration * outpost.efficiency) / 1000; // Calculate for one full cycle
                 if (potential > 0) {
                    producedTypes[count] = resType;
                    productionAmounts[count] = potential;
                    count++;
                 }
            }
        }

        // Trim arrays
        ResourceType[] memory finalTypes = new ResourceType[](count);
        uint256[] memory finalAmounts = new uint256[](count);
        for(uint i = 0; i < count; i++){
            finalTypes[i] = producedTypes[i];
            finalAmounts[i] = productionAmounts[i];
        }

        return (finalTypes, finalAmounts);
    }


    /// @notice Calculates the resource cost for the next upgrade level of an outpost.
    /// @param _outpostId The ID of the outpost.
    /// @return resourceTypes_ Array of resource types needed.
    /// @return amounts_ Array of corresponding costs.
    function calculateUpgradeCost(uint256 _outpostId)
        external
        view
        outpostExists(_outpostId)
        returns (ResourceType[] memory resourceTypes_, uint256[] memory amounts_)
    {
        Outpost storage outpost = outposts[_outpostId];
        uint256 nextLevel = outpost.level + 1;

        ResourceType[] memory requiredTypes = new ResourceType[](type(ResourceType).max);
        uint256[] memory requiredAmounts = new uint256[](type(ResourceType).max);
        uint256 count = 0;

        for (uint i = 0; i < type(ResourceType).max; i++) {
            ResourceType resType = ResourceType(i);
            uint256 cost = globalUpgradeCosts[outpost.outpostType][outpost.level][resType];
             if (cost > 0) {
                requiredTypes[count] = resType;
                requiredAmounts[count] = cost;
                count++;
             }
        }

        // Trim arrays
        ResourceType[] memory finalTypes = new ResourceType[](count);
        uint256[] memory finalAmounts = new uint256[](count);
        for(uint i = 0; i < count; i++){
            finalTypes[i] = requiredTypes[i];
            finalAmounts[i] = requiredAmounts[i];
        }

        return (finalTypes, finalAmounts);
    }


    /// @notice Returns the global event status.
    /// @return name Event name.
    /// @return productionEffectMultiplier Effect on production (scaled by 100).
    /// @return startTime Timestamp event started (0 if inactive).
    /// @return duration Event duration in seconds.
    /// @return isActive True if the event is currently active.
    function getGlobalEventStatus()
        external
        view
        returns (string memory name, int256 productionEffectMultiplier, uint256 startTime, uint256 duration, bool isActive)
    {
        bool active = currentGlobalEvent.startTime > 0 && block.timestamp < currentGlobalEvent.startTime + currentGlobalEvent.duration;
        return (
            currentGlobalEvent.name,
            currentGlobalEvent.productionEffectMultiplier,
            currentGlobalEvent.startTime,
            currentGlobalEvent.duration,
            active
        );
    }

     /// @notice Returns the current damage chance percentage (scaled by 10000).
     function getDamageChance() external view returns (uint256) {
         return damageChanceBps;
     }


    // --- DYNAMIC METADATA (ERC721 compatible) ---

     /// @notice Allows outpost owner to set a specific metadata URI for their outpost.
     /// @dev This URI will override the base URI set by the admin.
     /// @param _outpostId The ID of the outpost.
     /// @param _newURI The new metadata URI.
     function updateMetadataURI(uint256 _outpostId, string calldata _newURI)
        external
        outpostExists(_outpostId)
        onlyOutpostOwner(_outpostId)
    {
        outposts[_outpostId].metadataURI = _newURI;
        emit MetadataURIUpdated(_outpostId, _newURI);
    }

    /// @notice Standard ERC721 function to get the metadata URI for a token.
    /// @dev Returns the specific URI if set, otherwise falls back to the base URI.
    /// @param _outpostId The ID of the outpost.
    /// @return The metadata URI for the outpost.
    function tokenURI(uint256 _outpostId) external view override outpostExists(_outpostId) returns (string memory) {
        string memory specificURI = outposts[_outpostId].metadataURI;
        if (bytes(specificURI).length > 0) {
            return specificURI;
        }
        // Fallback to base URI, potentially appending token ID
        if (bytes(baseMetadataURI).length > 0) {
             // Simple concatenation example, complex schemas might need off-chain or more complex on-chain logic
             return string(abi.encodePacked(baseMetadataURI, "/", Strings.toString(_outpostId)));
        }
        return ""; // No URI set
    }

    // --- ADMIN FUNCTIONS ---

    /// @notice Admin sets the global base production rate for an outpost type and resource.
    /// @param _outpostType The type of outpost.
    /// @param _resourceType The type of resource produced.
    /// @param _rate The base production rate (amount per second per 1000 efficiency).
    function adminSetGlobalProductionRate(uint256 _outpostType, ResourceType _resourceType, uint256 _rate) external onlyAdmin {
        globalProductionRates[_outpostType][_resourceType] = _rate;
    }

    /// @notice Admin sets the resource cost for upgrading an outpost type from a specific level.
    /// @param _outpostType The type of outpost.
    /// @param _currentLevel The current level of the outpost.
    /// @param _resourceType The type of resource required for the upgrade.
    /// @param _amount The amount of the resource required.
    function adminSetUpgradeCost(uint256 _outpostType, uint256 _currentLevel, ResourceType _resourceType, uint256 _amount) external onlyAdmin {
        globalUpgradeCosts[_outpostType][_currentLevel][_resourceType] = _amount;
    }

    /// @notice Admin sets the initial resource cost for deploying a specific outpost type.
    /// @param _outpostType The type of outpost.
    /// @param _resourceType The type of resource required.
    /// @param _amount The amount required.
     function adminSetOutpostInitialCost(uint256 _outpostType, ResourceType _resourceType, uint256 _amount) external onlyAdmin {
         outpostTypeInitialCost[_outpostType][_resourceType] = _amount;
     }

     /// @notice Admin sets the resource input required to start a production cycle for an outpost type.
     /// @param _outpostType The type of outpost.
     /// @param _resourceType The type of resource required.
     /// @param _amount The amount required per cycle start.
     function adminSetOutpostProductionInput(uint256 _outpostType, ResourceType _resourceType, uint256 _amount) external onlyAdmin {
         outpostTypeProductionInput[_outpostType][_resourceType] = _amount;
     }


    /// @notice Admin triggers or updates a global event affecting production.
    /// @param _eventName The name of the event.
    /// @param _productionEffectMultiplier Percentage effect on production (e.g., 10 for +10%, -50 for -5%). Scaled by 100.
    /// @param _duration The duration of the event in seconds. Set 0 for no active event.
    function adminTriggerGlobalEvent(string calldata _eventName, int256 _productionEffectMultiplier, uint256 _duration) external onlyAdmin {
        currentGlobalEvent = GlobalEvent({
            name: _eventName,
            productionEffectMultiplier: _productionEffectMultiplier,
            startTime: _duration > 0 ? block.timestamp : 0, // Set start time only if duration > 0
            duration: _duration
        });

        emit GlobalEventTriggered(_eventName, _productionEffectMultiplier, currentGlobalEvent.startTime, _duration);
    }

    /// @notice Admin sets the base metadata URI for all outposts.
    /// @param _uri The base URI.
    function adminSetBaseMetadataURI(string calldata _uri) external onlyAdmin {
        baseMetadataURI = _uri;
    }

    /// @notice Admin sets the percentage chance for an outpost to become damaged on production claim.
    /// @param _chanceBps Chance in Basis Points (10000 = 100%).
    function adminSetDamageChance(uint256 _chanceBps) external onlyAdmin {
        require(_chanceBps <= 10000, "Chance cannot exceed 10000 bps (100%)");
        damageChanceBps = _chanceBps;
        emit DamageChanceUpdated(_chanceBps);
    }

    // --- INTERNAL / HELPER FUNCTIONS ---

    // ERC721 standard requires supportsInterface, adding a minimal implementation
    // for compatibility check, although full ERC721 is not implemented.
    function supportsInterface(bytes4 interfaceId) public view returns (bool) {
        // ERC721 Metadata interface ID is 0x5b5e139f
        return interfaceId == type(IERC721Metadata).interfaceId;
        // Add other interfaces if fully implementing ERC721, Ownable, etc.
    }

    // Basic toString helper needed for tokenURI concatenation
    library Strings {
        function toString(uint256 value) internal pure returns (string memory) {
            if (value == 0) {
                return "0";
            }
            uint256 temp = value;
            uint256 digits;
            while (temp != 0) {
                digits++;
                temp /= 10;
            }
            bytes memory buffer = new bytes(digits);
            while (value != 0) {
                digits -= 1;
                buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
                value /= 10;
            }
            return string(buffer);
        }
    }
}
```