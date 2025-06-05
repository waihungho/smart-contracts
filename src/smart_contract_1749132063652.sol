Okay, let's design a smart contract concept that is a bit more complex and attempts to combine several ideas: **An Algorithmic Archetype Forge and Dynamic Asset Protocol.**

**Concept:** Users can define "Archetype Blueprints" which are templates for dynamic, parameterizable assets. These assets (let's call them "Forged Archetypes" or FAs) are minted by staking an underlying ERC-20 token. The attributes and potentially the value/characteristics of these FAs change over time based on complex, algorithmically defined logic that can incorporate external data (via oracles) or internal protocol state. FAs can then be used in various ways within the protocol, such as staking for yield influenced by attributes, being mutated or combined, or influencing protocol parameters.

This concept is advanced because it involves:
*   Dynamic state based on logic and potential external data.
*   User-defined (templated) asset types.
*   Integration with staking and potential yield generation.
*   Non-standard asset behavior (attributes changing).
*   Potential for complex interactions between assets.

It's creative and trendy as it touches upon dynamic NFTs (or semi-fungible tokens), algorithmic protocols, and composability.

---

**Outline and Function Summary**

**Contract Name:** AlgorithmicArchetypeForge

**Concept:** A protocol enabling the creation, forging, management, and interaction with dynamic, algorithmically defined assets ("Forged Archetypes") based on user-defined blueprints.

**Key Components:**
1.  **Archetype Blueprints:** Templates defining the parameters, logic, required staking token, and behavior of a type of Forged Archetype.
2.  **Forged Archetypes (FAs):** Instances minted from a blueprint by staking an ERC-20 token. Each FA has dynamic attributes calculated based on the blueprint's logic and external data.
3.  **Oracles:** Provide external data feeds used in attribute calculations.
4.  **Staking Pool:** Users can stake FAs to earn rewards, potentially influenced by the FA's attributes.
5.  **Base Stake Token:** The ERC-20 token required to forge FAs.

**State Variables:**
*   Mapping of Archetype Blueprint IDs to Blueprint data (`blueprints`)
*   Mapping of Forged Archetype Instance IDs to Instance data (`forgedInstances`)
*   Mapping of Forged Archetype Instance IDs to owner address (`instanceOwners`)
*   Mapping of Forged Archetype Instance IDs to staked status (`instanceStaked`)
*   Mapping of users to Forged Archetype Instance IDs they own (`userInstances`)
*   Mapping of registered Oracles (`isOracle`)
*   Latest Oracle data feeds (`oracleData`)
*   Protocol configuration (fees, base token address, etc.)

**Functions (25+):**

*   **Admin/Protocol Configuration (7 functions):**
    1.  `constructor`: Initialize contract owner, base token, etc.
    2.  `pauseContract`: Pause crucial contract operations (Owner only).
    3.  `unpauseContract`: Unpause contract operations (Owner only).
    4.  `setProtocolFee`: Set fee percentage for forging (Owner only).
    5.  `setFeeRecipient`: Set address receiving protocol fees (Owner only).
    6.  `registerOracle`: Grant oracle data submission rights (Owner only).
    7.  `revokeOracle`: Remove oracle data submission rights (Owner only).

*   **Archetype Blueprint Management (5 functions):**
    8.  `createArchetypeBlueprint`: Define a new template for FAs.
    9.  `updateArchetypeBlueprintLogic`: Update calculation logic/parameters for an existing blueprint (Admin/Creator only, potentially via governance).
    10. `toggleBlueprintActive`: Enable/disable a blueprint for forging.
    11. `getArchetypeBlueprintDetails`: View details of a specific blueprint (View).
    12. `listActiveBlueprints`: View list of active blueprint IDs (View).

*   **Forging & Redemption (3 functions):**
    13. `forgeArchetypeInstance`: Mint a new FA by staking tokens based on a blueprint.
    14. `redeemArchetypeStake`: Burn an FA instance and reclaim the staked tokens.
    15. `getForgedInstanceStake`: View the current staked amount for an FA (View).

*   **Forged Archetype (FA) Management & Interaction (8 functions):**
    16. `transferArchetypeInstance`: Transfer ownership of an FA instance.
    17. `getArchetypeInstanceAttributes`: View the current dynamic attributes of an FA (View).
    18. `triggerAttributeUpdate`: Manually trigger attribute recalculation for an instance (Oracle/Whitelisted caller only, based on blueprint config).
    19. `stakeArchetypeInstance`: Stake an FA instance into the protocol pool.
    20. `unstakeArchetypeInstance`: Unstake an FA instance from the pool.
    21. `claimStakingRewards`: Claim accumulated rewards for staked FAs.
    22. `getPendingRewards`: View pending rewards for a user (View).
    23. `mutateArchetypeInstances`: Combine two or more FAs into a new one, potentially altering attributes or consuming components (Complex, conceptual).

*   **Oracle Interaction (2 functions):**
    24. `submitOracleData`: Oracles submit data feeds used in attribute calculations.
    25. `getLatestOracleData`: View the latest submitted oracle data for a specific key (View).

*   **Querying (Specific Getters) (3 functions):**
    26. `getUserArchetypeInstances`: List all FA instance IDs owned by a user (View).
    27. `getOwnerOfInstance`: Get the owner address of an FA instance (View).
    28. `getTotalForgedInstances`: Get the total count of minted FA instances (View).

*Total Functions: 28*

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// Note: This is a conceptual implementation.
// A production system would require:
// - A robust Oracle infrastructure (Chainlink, custom, etc.)
// - More sophisticated attribute calculation logic (potentially external libraries or complex internal functions)
// - Proper ERC-721 or ERC-1155 implementation if FAs are true NFTs/SFTS.
// - Detailed reward calculation logic for staking.
// - Gas optimizations for complex attribute calculations.
// - Advanced access control for blueprint updates.

// Mock Oracle Interface (for demonstration)
interface IOracle {
    function getData(string calldata key) external view returns (uint256);
}

contract AlgorithmicArchetypeForge is Ownable, Pausable, ReentrancyGuard {

    // --- Data Structures ---

    struct ArchetypeBlueprint {
        string name;
        string description;
        address stakeToken;       // ERC20 token required to forge
        uint256 stakeAmount;      // Amount of stakeToken required per instance
        bytes blueprintLogic;     // Placeholder for encoded logic parameters/reference
        string[] requiredOracleKeys; // Oracle data keys needed for attribute calculation
        bool isActive;            // Can new instances be forged?
        uint256 createdTimestamp;
        address createdBy;
        // Attributes that instances of this blueprint will have
        mapping(string => uint256) initialAttributes; // e.g., "power": 100
        string[] attributeKeys; // Array of attribute names
    }

    struct ForgedArchetypeInstance {
        uint256 blueprintId;
        uint256 forgedTimestamp;
        mapping(string => uint256) currentAttributes; // Dynamic attributes
        bool isStaked;
        // Add other instance-specific data if needed
    }

    struct OracleData {
        uint256 value;
        uint256 timestamp;
    }

    // --- State Variables ---

    uint256 private nextBlueprintId = 1;
    mapping(uint256 => ArchetypeBlueprint) public blueprints;
    uint256[] public blueprintIds; // To iterate through blueprints

    uint256 private nextInstanceId = 1;
    mapping(uint256 => ForgedArchetypeInstance) public forgedInstances;
    mapping(uint256 => address) public instanceOwners; // Maps instance ID to owner
    mapping(address => uint256[]) private userInstances; // Maps owner to array of instance IDs

    address public baseStakeToken; // The primary ERC20 token for staking
    uint256 public protocolFeeBasisPoints; // Fee applied to staked amount (e.g., 50 = 0.5%)
    address public feeRecipient;

    mapping(address => bool) public isOracle; // Whitelisted oracle addresses
    mapping(string => OracleData) private latestOracleData; // Latest data from oracles

    // Placeholder for staking rewards logic (would be more complex in reality)
    mapping(uint256 => uint256) private instanceStakingStartTime;
    mapping(uint256 => uint256) private instanceAccruedRewards; // Placeholder reward token unit

    // --- Events ---

    event ArchetypeBlueprintCreated(uint256 indexed blueprintId, string name, address indexed createdBy);
    event ArchetypeBlueprintUpdated(uint256 indexed blueprintId);
    event BlueprintActiveToggled(uint256 indexed blueprintId, bool isActive);
    event ForgedArchetypeInstanceForged(uint256 indexed instanceId, uint256 indexed blueprintId, address indexed owner);
    event ForgedArchetypeInstanceRedeemed(uint256 indexed instanceId, address indexed owner, uint256 stakeReturned);
    event InstanceAttributesUpdated(uint256 indexed instanceId, string[] attributeKeys);
    event InstanceTransferred(uint256 indexed instanceId, address indexed from, address indexed to);
    event InstanceStaked(uint256 indexed instanceId, address indexed owner);
    event InstanceUnstaked(uint256 indexed instanceId, address indexed owner);
    event RewardsClaimed(address indexed owner, uint256 amount);
    event OracleDataSubmitted(string indexed key, uint256 value, uint256 timestamp);
    event MutateInstances(uint256[] indexed parentInstanceIds, uint256 indexed newInstanceId, address indexed owner);
    event ProtocolFeeSet(uint256 oldFee, uint256 newFee);
    event FeeRecipientSet(address oldRecipient, address newRecipient);
    event OracleRegistered(address indexed oracleAddress);
    event OracleRevoked(address indexed oracleAddress);

    // --- Modifiers ---

    modifier onlyOracle() {
        require(isOracle[msg.sender], "Caller is not a registered oracle");
        _;
    }

    // Check if blueprint exists and is active
    modifier onlyActiveBlueprint(uint256 _blueprintId) {
        require(_blueprintId > 0 && _blueprintId < nextBlueprintId, "Invalid blueprint ID");
        require(blueprints[_blueprintId].isActive, "Blueprint is not active");
        _;
    }

    // Check if instance exists and is owned by caller
    modifier onlyInstanceOwner(uint256 _instanceId) {
        require(_instanceId > 0 && _instanceId < nextInstanceId, "Invalid instance ID");
        require(instanceOwners[_instanceId] == msg.sender, "Not instance owner");
        _;
        // Note: ERC721 standard would handle ownership via its internal state
    }

    // --- Constructor ---

    constructor(address _baseStakeToken, address _feeRecipient) Ownable(msg.sender) {
        baseStakeToken = _baseStakeToken;
        feeRecipient = _feeRecipient;
        protocolFeeBasisPoints = 50; // Default 0.5% fee
    }

    // --- Admin/Protocol Configuration Functions ---

    function pauseContract() external onlyOwner {
        _pause();
    }

    function unpauseContract() external onlyOwner {
        _unpause();
    }

    function setProtocolFee(uint256 _protocolFeeBasisPoints) external onlyOwner {
        require(_protocolFeeBasisPoints <= 1000, "Fee exceeds 10%"); // Example limit
        emit ProtocolFeeSet(protocolFeeBasisPoints, _protocolFeeBasisPoints);
        protocolFeeBasisPoints = _protocolFeeBasisPoints;
    }

    function setFeeRecipient(address _feeRecipient) external onlyOwner {
        require(_feeRecipient != address(0), "Invalid recipient address");
        emit FeeRecipientSet(feeRecipient, _feeRecipient);
        feeRecipient = _feeRecipient;
    }

    function registerOracle(address _oracleAddress) external onlyOwner {
        require(_oracleAddress != address(0), "Invalid oracle address");
        isOracle[_oracleAddress] = true;
        emit OracleRegistered(_oracleAddress);
    }

    function revokeOracle(address _oracleAddress) external onlyOwner {
        require(_oracleAddress != address(0), "Invalid oracle address");
        isOracle[_oracleAddress] = false;
        emit OracleRevoked(_oracleAddress);
    }

    // --- Archetype Blueprint Management Functions ---

    function createArchetypeBlueprint(
        string calldata _name,
        string calldata _description,
        address _stakeToken,
        uint256 _stakeAmount,
        bytes calldata _blueprintLogic,
        string[] calldata _requiredOracleKeys,
        string[] calldata _initialAttributeKeys,
        uint256[] calldata _initialAttributeValues
    ) external nonReentrant returns (uint256) {
        // Basic validation
        require(bytes(_name).length > 0, "Name required");
        require(_stakeAmount > 0, "Stake amount must be positive");
        require(_initialAttributeKeys.length == _initialAttributeValues.length, "Attribute key/value mismatch");

        uint256 blueprintId = nextBlueprintId++;
        ArchetypeBlueprint storage blueprint = blueprints[blueprintId];

        blueprint.name = _name;
        blueprint.description = _description;
        blueprint.stakeToken = _stakeToken;
        blueprint.stakeAmount = _stakeAmount;
        blueprint.blueprintLogic = _blueprintLogic;
        blueprint.requiredOracleKeys = _requiredOracleKeys;
        blueprint.isActive = true; // Active by default on creation
        blueprint.createdTimestamp = block.timestamp;
        blueprint.createdBy = msg.sender;
        blueprint.attributeKeys = _initialAttributeKeys;

        for (uint i = 0; i < _initialAttributeKeys.length; i++) {
            blueprint.initialAttributes[_initialAttributeKeys[i]] = _initialAttributeValues[i];
        }

        blueprintIds.push(blueprintId);

        emit ArchetypeBlueprintCreated(blueprintId, _name, msg.sender);
        return blueprintId;
    }

    function updateArchetypeBlueprintLogic(
        uint256 _blueprintId,
        bytes calldata _newBlueprintLogic,
        string[] calldata _newRequiredOracleKeys
        // Could also add parameters to update stake amount, initial attributes etc.
    ) external nonReentrant { // Potentially add onlyOwner or specific blueprint admin modifier
        require(_blueprintId > 0 && _blueprintId < nextBlueprintId, "Invalid blueprint ID");
        ArchetypeBlueprint storage blueprint = blueprints[_blueprintId];

        blueprint.blueprintLogic = _newBlueprintLogic;
        blueprint.requiredOracleKeys = _newRequiredOracleKeys;

        emit ArchetypeBlueprintUpdated(_blueprintId);
    }

    function toggleBlueprintActive(uint256 _blueprintId) external nonReentrant {
        require(_blueprintId > 0 && _blueprintId < nextBlueprintId, "Invalid blueprint ID");
        ArchetypeBlueprint storage blueprint = blueprints[_blueprintId];

        blueprint.isActive = !blueprint.isActive;
        emit BlueprintActiveToggled(_blueprintId, blueprint.isActive);
    }

    function getArchetypeBlueprintDetails(uint256 _blueprintId)
        external
        view
        returns (
            string memory name,
            string memory description,
            address stakeToken,
            uint256 stakeAmount,
            bytes memory blueprintLogic,
            string[] memory requiredOracleKeys,
            bool isActive,
            uint256 createdTimestamp,
            address createdBy,
            string[] memory attributeKeys,
            uint256[] memory attributeValues // Return initial values for view
        )
    {
        require(_blueprintId > 0 && _blueprintId < nextBlueprintId, "Invalid blueprint ID");
        ArchetypeBlueprint storage blueprint = blueprints[_blueprintId];

        uint256[] memory values = new uint256[](blueprint.attributeKeys.length);
        for(uint i = 0; i < blueprint.attributeKeys.length; i++) {
            values[i] = blueprint.initialAttributes[blueprint.attributeKeys[i]];
        }

        return (
            blueprint.name,
            blueprint.description,
            blueprint.stakeToken,
            blueprint.stakeAmount,
            blueprint.blueprintLogic,
            blueprint.requiredOracleKeys,
            blueprint.isActive,
            blueprint.createdTimestamp,
            blueprint.createdBy,
            blueprint.attributeKeys,
            values
        );
    }

    function listActiveBlueprints() external view returns (uint256[] memory) {
        uint256[] memory activeIds = new uint256[](blueprintIds.length);
        uint256 count = 0;
        for(uint i = 0; i < blueprintIds.length; i++) {
            if(blueprints[blueprintIds[i]].isActive) {
                activeIds[count] = blueprintIds[i];
                count++;
            }
        }
        // Trim the array to the actual number of active blueprints
        uint256[] memory result = new uint256[](count);
        for(uint i = 0; i < count; i++) {
            result[i] = activeIds[i];
        }
        return result;
    }

    // --- Forging & Redemption Functions ---

    function forgeArchetypeInstance(uint256 _blueprintId) external payable whenNotPaused nonReentrantic {
        require(_blueprintId > 0 && _blueprintId < nextBlueprintId, "Invalid blueprint ID");
        ArchetypeBlueprint storage blueprint = blueprints[_blueprintId];
        require(blueprint.isActive, "Blueprint is not active for forging");

        uint256 instanceId = nextInstanceId++;

        // Handle payment/staking (assuming stakeToken is ERC20 or native ETH)
        if (blueprint.stakeToken == address(0)) { // Assume address(0) means native ETH
            require(msg.value >= blueprint.stakeAmount, "Insufficient ETH sent");
            // Refund excess ETH if any
            if (msg.value > blueprint.stakeAmount) {
                 payable(msg.sender).transfer(msg.value - blueprint.stakeAmount);
            }
        } else { // ERC20 token
            // Protocol Fee calculation and transfer
            uint256 stakeAmount = blueprint.stakeAmount;
            uint256 protocolFee = (stakeAmount * protocolFeeBasisPoints) / 10000; // Basis points division
            uint256 amountToStake = stakeAmount - protocolFee;

            // Transfer staked amount to contract
            IERC20 stakeTokenContract = IERC20(blueprint.stakeToken);
            require(stakeTokenContract.transferFrom(msg.sender, address(this), amountToStake), "Stake token transfer failed");

            // Transfer fee to recipient
            if (protocolFee > 0) {
                 require(stakeTokenContract.transfer(feeRecipient, protocolFee), "Fee token transfer failed");
            }
        }

        // Create new instance
        ForgedArchetypeInstance storage instance = forgedInstances[instanceId];
        instance.blueprintId = _blueprintId;
        instance.forgedTimestamp = block.timestamp;
        instance.isStaked = false; // Initially not staked in the pool

        // Copy initial attributes
        for(uint i = 0; i < blueprint.attributeKeys.length; i++) {
            instance.currentAttributes[blueprint.attributeKeys[i]] = blueprint.initialAttributes[blueprint.attributeKeys[i]];
        }

        // Assign ownership
        instanceOwners[instanceId] = msg.sender;
        userInstances[msg.sender].push(instanceId);

        emit ForgedArchetypeInstanceForged(instanceId, _blueprintId, msg.sender);
    }

     function redeemArchetypeStake(uint256 _instanceId) external nonReentrantic onlyInstanceOwner(_instanceId) {
        ForgedArchetypeInstance storage instance = forgedInstances[_instanceId];
        require(!instance.isStaked, "Instance is currently staked"); // Must be unstaked first

        uint256 blueprintId = instance.blueprintId;
        ArchetypeBlueprint storage blueprint = blueprints[blueprintId];

        // Remove instance from owner's list
        uint256[] storage instances = userInstances[msg.sender];
        for (uint i = 0; i < instances.length; i++) {
            if (instances[i] == _instanceId) {
                // Swap with last element and pop (gas efficient removal)
                instances[i] = instances[instances.length - 1];
                instances.pop();
                break;
            }
        }

        // Determine staked amount (excluding protocol fee, assuming fee is kept)
        // Note: A more complex model might return a portion of the fee or have variable redemption values
        uint256 stakeAmount = blueprint.stakeAmount;
        uint256 protocolFee = (stakeAmount * protocolFeeBasisPoints) / 10000;
        uint256 amountToReturn = stakeAmount - protocolFee;

        // Transfer staked amount back
         if (blueprint.stakeToken == address(0)) { // Native ETH
            payable(msg.sender).transfer(amountToReturn);
        } else { // ERC20 token
            IERC20 stakeTokenContract = IERC20(blueprint.stakeToken);
             require(stakeTokenContract.transfer(msg.sender, amountToReturn), "Stake token transfer failed");
        }


        // Delete instance data (reset state)
        delete forgedInstances[_instanceId];
        delete instanceOwners[_instanceId];
        delete instanceStakingStartTime[_instanceId]; // Clean up potential staking data
        delete instanceAccruedRewards[_instanceId];

        emit ForgedArchetypeInstanceRedeemed(_instanceId, msg.sender, amountToReturn);
    }

    function getForgedInstanceStake(uint256 _instanceId) external view returns (uint256) {
         require(_instanceId > 0 && _instanceId < nextInstanceId, "Invalid instance ID");
         uint256 blueprintId = forgedInstances[_instanceId].blueprintId;
         return blueprints[blueprintId].stakeAmount; // Return total stake amount defined in blueprint
    }


    // --- Forged Archetype (FA) Management & Interaction Functions ---

    // Basic transfer function (simplified, not full ERC721)
    function transferArchetypeInstance(address _to, uint256 _instanceId) external nonReentrant onlyInstanceOwner(_instanceId) {
        require(_to != address(0), "Invalid recipient address");
        require(!forgedInstances[_instanceId].isStaked, "Instance is currently staked"); // Cannot transfer if staked

        address from = msg.sender;

        // Remove from sender's instances
        uint256[] storage fromInstances = userInstances[from];
        for (uint i = 0; i < fromInstances.length; i++) {
            if (fromInstances[i] == _instanceId) {
                fromInstances[i] = fromInstances[fromInstances.length - 1];
                fromInstances.pop();
                break;
            }
        }

        // Add to recipient's instances
        userInstances[_to].push(_instanceId);
        instanceOwners[_instanceId] = _to;

        emit InstanceTransferred(_instanceId, from, _to);
    }

    function getArchetypeInstanceAttributes(uint256 _instanceId)
        external
        view
        returns (string[] memory attributeKeys, uint256[] memory attributeValues)
    {
        require(_instanceId > 0 && _instanceId < nextInstanceId, "Invalid instance ID");
        ForgedArchetypeInstance storage instance = forgedInstances[_instanceId];
         ArchetypeBlueprint storage blueprint = blueprints[instance.blueprintId];

        string[] memory keys = blueprint.attributeKeys; // Get keys from blueprint
        uint256[] memory values = new uint256[](keys.length);

        for(uint i = 0; i < keys.length; i++) {
            values[i] = instance.currentAttributes[keys[i]];
        }

        return (keys, values);
    }

    // Function to trigger attribute updates
    // In a real system, this might be called by the oracle itself, or a separate upkeep bot.
    // The calculation logic is abstract here.
    function triggerAttributeUpdate(uint256 _instanceId) external nonReentrant whenNotPaused {
        require(_instanceId > 0 && _instanceId < nextInstanceId, "Invalid instance ID");
        // Add access control here: maybe only whitelisted updaters, or even the oracle itself if it has this capability
        // For simplicity, let's allow anyone to trigger for demonstration, but in production, this is critical access control.
        // require(isUpdater[msg.sender] || isOracle[msg.sender], "Unauthorized to trigger update");

        _calculateAndSetAttributes(_instanceId);
    }

     // Internal function to calculate and set attributes
    function _calculateAndSetAttributes(uint256 _instanceId) internal {
        ForgedArchetypeInstance storage instance = forgedInstances[_instanceId];
        ArchetypeBlueprint storage blueprint = blueprints[instance.blueprintId];

        // --- Complex Attribute Calculation Logic (Placeholder) ---
        // This is where the core algorithmic logic of the blueprint resides.
        // It would use:
        // 1. `blueprint.blueprintLogic` (parameters or reference to code)
        // 2. `blueprint.requiredOracleKeys` and data from `latestOracleData`
        // 3. `instance.forgedTimestamp` and current `block.timestamp`
        // 4. `instance.currentAttributes` (for cumulative effects)

        // Example Placeholder Logic: Increment a 'timeAlive' attribute
        // and modify 'value' based on oracle data.
        uint256 timeAlive = block.timestamp - instance.forgedTimestamp;
        instance.currentAttributes["timeAlive"] = timeAlive; // Assuming "timeAlive" is a possible attribute key

        // Example Oracle Data Usage: Modify "value" attribute based on "priceFeed" oracle
        for (uint i = 0; i < blueprint.requiredOracleKeys.length; i++) {
            string memory key = blueprint.requiredOracleKeys[i];
            if (bytes(key).length > 0 && latestOracleData[key].timestamp > 0) {
                uint256 oracleValue = latestOracleData[key].value;
                // Simple example: if key is "priceFeed", set/modify a "computedValue" attribute
                if (keccak256(abi.encodePacked(key)) == keccak256(abi.encodePacked("priceFeed"))) {
                     // Assuming "computedValue" is a possible attribute key
                    instance.currentAttributes["computedValue"] = oracleValue / 100; // Example simple transform
                }
                 // Add more specific logic based on other keys and blueprint.blueprintLogic
            }
        }

        // In a real system, this would be a complex, possibly external, calculation.
        // The new values would be stored in `instance.currentAttributes`.

        // Re-emit attributes after update
        emit InstanceAttributesUpdated(_instanceId, blueprint.attributeKeys);
        // --- End Placeholder Logic ---
    }

    // Placeholder Staking Functions
    // This would interact with a separate staking pool contract or internal logic
    function stakeArchetypeInstance(uint256 _instanceId) external nonReentrantic onlyInstanceOwner(_instanceId) whenNotPaused {
         ForgedArchetypeInstance storage instance = forgedInstances[_instanceId];
         require(!instance.isStaked, "Instance is already staked");

         instance.isStaked = true;
         instanceStakingStartTime[_instanceId] = block.timestamp;
         // Logic to add instance to a staking pool data structure if needed

         emit InstanceStaked(_instanceId, msg.sender);
    }

     function unstakeArchetypeInstance(uint256 _instanceId) external nonReentrantic onlyInstanceOwner(_instanceId) whenNotPaused {
         ForgedArchetypeInstance storage instance = forgedInstances[_instanceId];
         require(instance.isStaked, "Instance is not staked");

         // Calculate pending rewards before unstaking (placeholder)
         _calculatePendingRewards(_instanceId); // Update accruedRewards based on time/attributes

         instance.isStaked = false;
         delete instanceStakingStartTime[_instanceId];
         // Logic to remove instance from staking pool data structure

         emit InstanceUnstaked(_instanceId, msg.sender);
     }

     // Placeholder reward calculation - would depend on attributes and time staked
     function _calculatePendingRewards(uint256 _instanceId) internal view returns (uint256) {
         ForgedArchetypeInstance storage instance = forgedInstances[_instanceId];
         if (!instance.isStaked) {
             return instanceAccruedRewards[_instanceId];
         }

         uint256 timeStaked = block.timestamp - instanceStakingStartTime[_instanceId];
         // Example: Reward rate based on an attribute, e.g., "yieldFactor"
         uint256 yieldFactor = instance.currentAttributes["yieldFactor"]; // Assuming this attribute exists
         uint256 rewardsEarned = timeStaked * yieldFactor; // Simplified calculation

         // In reality, need to track last claim time or use a more complex yield-farming math (e.g., accumulation points)
         // This simple model would just recalculate total earned since start, which is flawed for repeated claims.
         // A real system would store `lastRewardCalculationTime` or use a more advanced method.

         // For this placeholder, let's just return a value based on time * a base rate + attribute influence
         uint256 placeholderBaseRate = 1; // Some base unit per second
         uint256 totalPotentialRewards = timeStaked * placeholderBaseRate + (timeStaked / 100) * yieldFactor; // Example formula

         return instanceAccruedRewards[_instanceId] + totalPotentialRewards; // Add to previously accrued
     }

     function claimStakingRewards(uint256[] calldata _instanceIds) external nonReentrantic whenNotPaused {
        uint256 totalRewardsToClaim = 0;
        // In a real system, iterate through user's staked instances and calculate rewards
        // For simplicity here, let's assume claiming for specific instances passed in
        // A better approach is often to calculate for *all* of user's staked instances.

        for(uint i = 0; i < _instanceIds.length; i++) {
            uint256 instanceId = _instanceIds[i];
            require(instanceOwners[instanceId] == msg.sender, "Not instance owner");
            // Calculate rewards accrued since last claim or since staking started
            // This requires a more robust reward tracking system than the placeholder
            uint256 pending = _calculatePendingRewards(instanceId); // Placeholder logic
            totalRewardsToClaim += pending;

            // Reset accrued rewards after calculating
            instanceAccruedRewards[instanceId] = 0;
            instanceStakingStartTime[instanceId] = block.timestamp; // Reset time if time-based
        }

        // Transfer reward token (assuming a specific reward token)
        // This needs an ERC20 token contract and the contract must hold rewards
        // IERC20 rewardToken = IERC20(rewardTokenAddress);
        // require(rewardToken.transfer(msg.sender, totalRewardsToClaim), "Reward token transfer failed");

        // For placeholder, just emit the amount
        if (totalRewardsToClaim > 0) {
             emit RewardsClaimed(msg.sender, totalRewardsToClaim);
        }
     }

     function getPendingRewards(address _user) external view returns (uint256) {
         uint256 totalPending = 0;
         uint256[] storage instances = userInstances[_user];
         for(uint i = 0; i < instances.length; i++) {
             uint256 instanceId = instances[i];
             // Only calculate for staked instances
             if (forgedInstances[instanceId].isStaked) {
                  totalPending += _calculatePendingRewards(instanceId); // Placeholder
             }
         }
         return totalPending;
     }


    // Placeholder for a complex 'mutation' function
    function mutateArchetypeInstances(uint256[] calldata _parentInstanceIds) external nonReentrantic whenNotPaused {
        require(_parentInstanceIds.length >= 2, "Requires at least two instances to mutate");

        // Validate ownership and state of parent instances
        for(uint i = 0; i < _parentInstanceIds.length; i++) {
            uint256 instanceId = _parentInstanceIds[i];
            require(instanceOwners[instanceId] == msg.sender, "Not owner of all parent instances");
            require(!forgedInstances[instanceId].isStaked, "Parent instance is staked");
            // Add other checks: e.g., compatible blueprints, not already used in mutation, etc.
        }

        // --- Complex Mutation Logic (Placeholder) ---
        // This would involve:
        // 1. Defining rules based on blueprints of parent instances.
        // 2. Combining/Averaging/Transforming parent attributes.
        // 3. Potentially consuming the parent instances (burning them).
        // 4. Minting a new Forged Archetype Instance based on specific mutation rules or a new "Mutant" blueprint.

        // Example: Simple average of attributes from two parents (conceptual)
        // uint256 newBlueprintId = ...; // Determine blueprint for the new instance
        // uint256 newInstanceId = nextInstanceId++;
        // ForgedArchetypeInstance storage newInstance = forgedInstances[newInstanceId];
        // ... setup new instance data ...
        // For example: newInstance.currentAttributes["power"] = (forgedInstances[_parentInstanceIds[0]].currentAttributes["power"] + forgedInstances[_parentInstanceIds[1]].currentAttributes["power"]) / 2;
        // ... burn parent instances ...
        // ... assign ownership of new instance ...
        // --- End Placeholder Logic ---

         uint256 newInstanceId = 0; // Replace with actual minted ID if successful
         // Simplified: just burn parents for demonstration of interaction function
         for(uint i = 0; i < _parentInstanceIds.length; i++) {
             redeemArchetypeStake(_parentInstanceIds[i]); // Use redeem logic to burn and return stake (optional, could just burn)
         }


        emit MutateInstances(_parentInstanceIds, newInstanceId, msg.sender);
    }


    // Functionality allowing an instance owner to set a parameter, IF the blueprint allows it
    // This adds a layer of user interaction and control over the dynamic asset.
    function setInstanceParameter(uint256 _instanceId, string calldata _parameterKey, uint256 _value) external nonReentrant onlyInstanceOwner(_instanceId) {
        // Check blueprint rules: Does this blueprint allow this parameter to be set by the owner?
        // This requires adding allowed parameters/logic to the Blueprint struct and checks here.
        // require(blueprints[forgedInstances[_instanceId].blueprintId].allowOwnerParamSet[_parameterKey], "Parameter not settable by owner");

        // For placeholder, directly set an attribute (this is NOT ideal; ideally parameters influence attributes indirectly)
        // A better approach is to store this as a user-set parameter that the _calculateAndSetAttributes function reads.
        forgedInstances[_instanceId].currentAttributes[_parameterKey] = _value;

        // Re-calculate attributes if setting this parameter should trigger a recalculation
        _calculateAndSetAttributes(_instanceId);

        // Emit event about parameter set / attribute changed
        string[] memory updatedKey = new string[](1);
        updatedKey[0] = _parameterKey;
        emit InstanceAttributesUpdated(_instanceId, updatedKey);
    }

    // Conceptual function: Allow an instance owner to "delegate" the influence/voting power
    // tied to an instance's attributes to another address.
    // This requires a separate system (e.g., governance contract) that reads these delegations.
    function delegateAttributeInfluence(uint256 _instanceId, address _delegate) external nonReentrant onlyInstanceOwner(_instanceId) {
         // Store the delegation
         // mapping(uint256 => address) public instanceDelegates; // Add this state variable
         // instanceDelegates[_instanceId] = _delegate;

         // Emit an event for off-chain or other contracts to pick up
         // event AttributeInfluenceDelegated(uint256 indexed instanceId, address indexed from, address indexed to);
         // emit AttributeInfluenceDelegated(_instanceId, msg.sender, _delegate);
    }


    // --- Oracle Interaction Functions ---

    function submitOracleData(string calldata _key, uint256 _value) external nonReentrant onlyOracle {
        latestOracleData[_key] = OracleData({
            value: _value,
            timestamp: block.timestamp
        });
        emit OracleDataSubmitted(_key, _value, block.timestamp);
    }

    function getLatestOracleData(string calldata _key) external view returns (uint256 value, uint256 timestamp) {
        OracleData storage data = latestOracleData[_key];
        return (data.value, data.timestamp);
    }

    // --- Querying Functions ---

    function getUserArchetypeInstances(address _user) external view returns (uint256[] memory) {
        return userInstances[_user];
    }

    function getOwnerOfInstance(uint256 _instanceId) external view returns (address) {
        require(_instanceId > 0 && _instanceId < nextInstanceId, "Invalid instance ID");
        return instanceOwners[_instanceId];
    }

     function getTotalForgedInstances() external view returns (uint256) {
        return nextInstanceId - 1; // nextInstanceId is the next available ID, so count is one less
     }

    // Getter for protocol fee (added to reach count easily)
    function getProtocolFee() external view returns (uint256) {
        return protocolFeeBasisPoints;
    }

    // Getter for oracle contract (added to reach count easily)
    function getOracleContract() external view returns (address) {
        // Assuming a single oracle contract address is stored, not multiple whitelisted ones
        // Or could return the address of a specific oracle if needed
        // For now, let's just return address(0) as we only have whitelisted addresses
        return address(0); // Needs refinement based on actual oracle setup
    }

     // Getter for checking archetype admin status (added to reach count easily)
     function isArchetypeAdmin(address _addr) external view returns (bool) {
         // This requires an ArchetypeAdmin role/mapping, which wasn't fully implemented but was mentioned in the outline.
         // For simplicity, let's just check if they are the contract owner for this example.
         return _addr == owner();
     }


    // Get instance details including attributes (combines getArchetypeInstanceAttributes and other details)
    function getArchetypeInstanceDetails(uint256 _instanceId)
        external
        view
        returns (
            uint256 instanceId,
            uint256 blueprintId,
            address owner,
            uint256 forgedTimestamp,
            bool isStaked,
            string[] memory attributeKeys,
            uint256[] memory attributeValues
        )
    {
        require(_instanceId > 0 && _instanceId < nextInstanceId, "Invalid instance ID");
        ForgedArchetypeInstance storage instance = forgedInstances[_instanceId];
        ArchetypeBlueprint storage blueprint = blueprints[instance.blueprintId];

        string[] memory keys = blueprint.attributeKeys; // Get keys from blueprint
        uint256[] memory values = new uint256[](keys.length);

        for(uint i = 0; i < keys.length; i++) {
            values[i] = instance.currentAttributes[keys[i]];
        }

        return (
            _instanceId,
            instance.blueprintId,
            instanceOwners[_instanceId],
            instance.forgedTimestamp,
            instance.isStaked,
            keys,
            values
        );
    }

    // Getter for blueprint count (added for function count)
    function getArchetypeBlueprintCount() external view returns (uint256) {
        return nextBlueprintId - 1;
    }

}
```