```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Modular Reputation & Resource Synthesis Platform
 * @dev This contract implements a system where user contribution earns non-transferable Reputation Points (RP).
 *      RP can be converted into transferable Resource Credits (RC). RC can be staked into different pools.
 *      Staked RC from specific pools can be used to synthesize unique, dynamic NFTs called Dynamic Modules (DM).
 *      DMs have mutable traits that can be upgraded, mutated, or combined using RC or staked resources.
 *      This creates a complex ecosystem tying non-transferable reputation to liquid resources and dynamic assets.
 *
 * @author YourName (or Pseudonym)
 * @date 2023-10-27
 */

/*
 * OUTLINE:
 * 1. State Variables & Constants
 * 2. Structs for Data Representation (Resource Types, Module Types, Module Traits)
 * 3. Events for Transparency
 * 4. Modifiers for Access Control and State Checks
 * 5. Internal Token & NFT Logic (Self-implemented to avoid duplicating standard contracts)
 *    - RP: Balances, earning
 *    - RC: Balances, total supply, transfers, approvals
 *    - DM: Owners, approvals, base transfer logic, trait storage
 * 6. Core System Mechanics (RP -> RC, RC Staking, RC/Staked -> DM Synthesis)
 * 7. Dynamic Module Interaction (Upgrading, Mutating, Combining, Equipping)
 * 8. Admin/Parameter Setting Functions
 * 9. Public Read-Only Functions (Queries)
 */

/*
 * FUNCTION SUMMARY:
 *
 * --- Admin & Setup ---
 * - constructor(): Initializes contract admin.
 * - setResourceTypeParameters(): Admin sets parameters for different resource pools.
 * - setModuleTypeParameters(): Admin sets synthesis costs and initial traits for different module types.
 * - setReputationConversionRate(): Admin sets the rate to convert RP to RC.
 * - setSynthesisFeeRate(): Admin sets the percentage fee for module synthesis.
 * - withdrawProtocolFees(): Admin withdraws accumulated fees.
 *
 * --- Core Mechanics (User Write) ---
 * - earnReputation(): (Simulated) Function to accrue Reputation Points (RP). In a real system, this would be triggered by verifiable contributions (e.g., via oracles, proofs).
 * - convertReputationToResourceCredits(): Convert earned RP into transferable Resource Credits (RC).
 * - stakeResourceCredits(): Stake RC into a specific resource pool required for module synthesis/upgrades.
 * - unstakeResourceCredits(): Withdraw staked RC from a resource pool.
 * - synthesizeDynamicModule(): Use staked RC from a specific pool to mint a new Dynamic Module (DM) NFT. Includes fee collection.
 *
 * --- Resource Credit (RC) ERC-20 Like Functions ---
 * - transferResourceCredits(): Transfer RC to another address.
 * - approveResourceCredits(): Approve an address to spend RC on your behalf.
 * - transferFromResourceCredits(): Transfer RC from an approved address.
 *
 * --- Dynamic Module (DM) ERC-721 Like Functions ---
 * - transferDynamicModule(): Transfer a DM NFT to another address.
 * - approveDynamicModule(): Approve an address to transfer a specific DM NFT.
 * - setApprovalForAllDynamicModules(): Approve an operator to manage all your DM NFTs.
 *
 * --- Dynamic Module Interaction (User Write) ---
 * - upgradeDynamicModule(): Use staked RC/resources to improve specific traits of a DM.
 * - mutateDynamicModuleTrait(): Use staked RC/resources to randomly (or condition-based) change a specific trait value.
 * - combineDynamicModules(): Burn one DM and use staked RC/resources to transfer/boost traits onto another DM.
 * - equipDynamicModule(): Mark a DM as 'equipped' (example state change, could unlock in-system perks).
 * - unequipDynamicModule(): Mark a DM as 'unequipped'.
 * - delegateModuleAction(): Grant specific permission to an address to perform *certain* actions (e.g., upgrade, mutate) on a specific DM without full transfer approval.
 *
 * --- Public Read-Only Functions (Queries) ---
 * - getVersion(): Get contract version.
 * - getAdminAddress(): Get the contract admin address.
 * - getReputationBalance(): Get a user's RP balance.
 * - getResourceCreditBalance(): Get a user's RC balance.
 * - getTotalResourceCreditsSupply(): Get the total minted RC supply.
 * - getDynamicModuleOwner(): Get the owner of a specific DM token ID.
 * - getApprovedDynamicModule(): Get the approved address for a specific DM token ID.
 * - isApprovedForAllDynamicModules(): Check if an operator is approved for all of a user's DMs.
 * - getDynamicModuleTraits(): Get the current traits of a specific DM token ID.
 * - getDynamicModuleType(): Get the module type ID of a specific DM token ID.
 * - getResourceTypeParameters(): Get parameters for a specific resource type.
 * - getModuleTypeParameters(): Get parameters for a specific module type.
 * - getSynthesisPoolBalance(): Get the total amount of RC staked in a specific resource pool.
 * - getUserStakedResources(): Get the amount of RC a user has staked in a specific resource pool.
 * - getReputationConversionRate(): Get the current RP to RC conversion rate.
 * - getSynthesisFeeRate(): Get the current synthesis fee rate.
 * - getProtocolFees(): Get the current accumulated protocol fees.
 */

contract ModularSynthesisPlatform {

    // --- 1. State Variables & Constants ---
    address public admin;
    uint256 public constant CONTRACT_VERSION = 1;

    // Reputation Points (RP): Non-transferable, balance per user
    mapping(address => uint256) private reputationBalances;

    // Resource Credits (RC): Transferable, balance per user (ERC-20 like)
    mapping(address => uint256) private resourceCreditBalances;
    mapping(address => mapping(address => uint256)) private resourceCreditAllowances;
    uint256 private totalSupplyRC;

    // Dynamic Modules (DM): NFTs (ERC-721 like)
    mapping(uint256 => address) private dynamicModuleOwners;
    mapping(uint256 => uint256) private dynamicModuleTypes; // Maps tokenId to Module Type ID
    mapping(uint256 => DynamicModuleTraits) private dynamicModuleTraits; // Maps tokenId to traits
    mapping(uint256 => address) private dynamicModuleTokenApprovals; // ERC721 token approval
    mapping(address => mapping(address => bool)) private dynamicModuleOperatorApprovals; // ERC721 operator approval
    mapping(uint256 => address) private dynamicModuleActionDelegates; // Custom action delegate per module
    uint256 private nextModuleTokenId; // Counter for unique DM token IDs

    // Resource Pools: RC staked for synthesis/upgrades
    mapping(uint256 => uint256) private synthesisPools; // Maps Resource Type ID to total RC staked
    mapping(uint256 => mapping(address => uint256)) private userStakedResources; // Maps Resource Type ID to user to staked amount

    // Parameters and Rates
    uint256 private reputationConversionRate; // How much RC per RP
    uint256 private synthesisFeeRate; // Percentage fee for synthesis (e.g., 100 = 1%)
    uint256 private protocolFees; // Accumulated fees

    // --- 2. Structs for Data Representation ---

    struct ResourceTypeParameters {
        uint256 baseSynthesisCost; // RC cost from this pool for synthesis
        uint256 upgradeCostMultiplier; // Multiplier for upgrade costs using this resource
        bool exists; // Sentinel to check if resource type is configured
    }
    mapping(uint256 => ResourceTypeParameters) private resourceTypeParameters; // Maps Resource Type ID to parameters

    struct ModuleTypeParameters {
        uint256 requiredResourceTypeId; // Which resource pool is primarily used for synthesis
        uint256 requiredResourceAmount; // How much staked resource is required
        uint256 baseSynthesisFee; // Base fee paid in RC (in addition to resource cost)
        uint256 initialTraitValue; // Initial value for a primary trait
        bool exists; // Sentinel
    }
    mapping(uint256 => ModuleTypeParameters) private moduleTypeParameters; // Maps Module Type ID to parameters

    struct DynamicModuleTraits {
        uint256 primaryTrait; // Example: Power, Level, etc.
        uint256 secondaryTrait; // Example: Speed, Efficiency, etc.
        uint256 rarityScore; // Example: Derived from traits, affects interactions
        bool isEquipped; // Example state: Can't transfer or combine if equipped
        // Add more traits as needed
    }

    // --- 3. Events for Transparency ---
    event ReputationEarned(address indexed user, uint256 amount, uint256 newBalance);
    event ReputationConvertedToResourceCredits(address indexed user, uint256 rpAmount, uint256 rcAmount);
    event ResourceCreditsStaked(address indexed user, uint256 indexed resourceTypeId, uint256 amount, uint256 newPoolTotal);
    event ResourceCreditsUnstaked(address indexed user, uint256 indexed resourceTypeId, uint256 amount, uint256 newPoolTotal);
    event ModuleSynthesized(address indexed owner, uint256 indexed moduleId, uint256 indexed moduleTypeId, uint256 resourceCost, uint256 feePaid);
    event ModuleUpgraded(uint256 indexed moduleId, uint8 indexed traitIndex, uint256 oldValue, uint256 newValue); // traitIndex 0=primary, 1=secondary etc.
    event ModuleTraitMutated(uint256 indexed moduleId, uint8 indexed traitIndex, uint256 oldValue, uint256 newValue, uint256 mutationResourceTypeId);
    event ModulesCombined(address indexed newModuleOwner, uint256 indexed retainedModuleId, uint256 indexed sacrificedModuleId);
    event ModuleEquipped(uint256 indexed moduleId, address indexed owner);
    event ModuleUnequipped(uint256 indexed moduleId, address indexed owner);
    event ModuleDelegateSet(uint256 indexed moduleId, address indexed delegatee);
    event ProtocolFeesWithdrawn(address indexed recipient, uint256 amount);

    // ERC-20 like events for RC
    event TransferRC(address indexed from, address indexed to, uint256 value);
    event ApprovalRC(address indexed owner, address indexed spender, uint256 value);

    // ERC-721 like events for DM
    event TransferDM(address indexed from, address indexed to, uint256 indexed tokenId);
    event ApprovalDM(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAllDM(address indexed owner, address indexed operator, bool approved);

    // Admin events
    event ResourceTypeParametersSet(uint256 indexed resourceTypeId, ResourceTypeParameters params);
    event ModuleTypeParametersSet(uint256 indexed moduleTypeId, ModuleTypeParameters params);
    event ReputationConversionRateSet(uint256 rate);
    event SynthesisFeeRateSet(uint256 rate);


    // --- 4. Modifiers ---
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }

    modifier whenNotEquipped(uint256 tokenId) {
        require(!dynamicModuleTraits[tokenId].isEquipped, "Module is equipped");
        _;
    }

    // --- Constructor ---
    constructor() {
        admin = msg.sender;
        reputationConversionRate = 100; // Default: 1 RP = 100 RC
        synthesisFeeRate = 50; // Default: 5% fee
    }

    // --- 5. Internal Token & NFT Logic (Self-implemented) ---

    // --- Internal RP Logic ---
    // No internal transfer/burn for RP, it's earned and converted.

    // --- Internal RC Logic (ERC-20 like) ---
    function _mintResourceCredits(address account, uint256 amount) internal {
        require(account != address(0), "Mint to the zero address");
        totalSupplyRC += amount;
        resourceCreditBalances[account] += amount;
        emit TransferRC(address(0), account, amount);
    }

    function _burnResourceCredits(address account, uint256 amount) internal {
        require(account != address(0), "Burn from the zero address");
        uint256 accountBalance = resourceCreditBalances[account];
        require(accountBalance >= amount, "Burn amount exceeds balance");
        unchecked {
            resourceCreditBalances[account] = accountBalance - amount;
        }
        totalSupplyRC -= amount;
        emit TransferRC(account, address(0), amount);
    }

    function _transferResourceCredits(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "Transfer from the zero address");
        require(recipient != address(0), "Transfer to the zero address");
        uint256 senderBalance = resourceCreditBalances[sender];
        require(senderBalance >= amount, "Transfer amount exceeds balance");
        unchecked {
            resourceCreditBalances[sender] = senderBalance - amount;
        }
        resourceCreditBalances[recipient] += amount;
        emit TransferRC(sender, recipient, amount);
    }

    // --- Internal DM Logic (ERC-721 like) ---
    function _existsDynamicModule(uint256 tokenId) internal view returns (bool) {
        return dynamicModuleOwners[tokenId] != address(0);
    }

    function _isApprovedOrOwnerDM(address spender, uint256 tokenId) internal view returns (bool) {
        address owner = dynamicModuleOwners[tokenId];
        return (spender == owner || getApprovedDynamicModule(tokenId) == spender || isApprovedForAllDynamicModules(owner, spender));
    }

    function _mintDynamicModule(address to, uint256 moduleTypeId) internal returns (uint256) {
        require(to != address(0), "Mint to the zero address");
        uint256 newTokenId = nextModuleTokenId++;
        dynamicModuleOwners[newTokenId] = to;
        dynamicModuleTypes[newTokenId] = moduleTypeId;
        dynamicModuleTraits[newTokenId] = DynamicModuleTraits({
            primaryTrait: moduleTypeParameters[moduleTypeId].initialTraitValue,
            secondaryTrait: 0, // Example initial value
            rarityScore: 0, // Example initial value
            isEquipped: false
        });
        emit TransferDM(address(0), to, newTokenId);
        return newTokenId;
    }

    function _burnDynamicModule(uint256 tokenId) internal {
        address owner = dynamicModuleOwners[tokenId];
        require(owner != address(0), "Token doesn't exist");
        require(!dynamicModuleTraits[tokenId].isEquipped, "Cannot burn equipped module");

        // Clear approvals
        approveDynamicModule(address(0), tokenId);
        dynamicModuleActionDelegates[tokenId] = address(0);

        delete dynamicModuleOwners[tokenId];
        delete dynamicModuleTypes[tokenId];
        delete dynamicModuleTraits[tokenId];

        emit TransferDM(owner, address(0), tokenId);
    }

    function _transferDynamicModuleInternal(address from, address to, uint256 tokenId) internal {
        require(dynamicModuleOwners[tokenId] == from, "Not owner");
        require(to != address(0), "Transfer to the zero address");
        require(!dynamicModuleTraits[tokenId].isEquipped, "Cannot transfer equipped module");

        // Clear approvals for the token
        approveDynamicModule(address(0), tokenId);
        dynamicModuleActionDelegates[tokenId] = address(0);

        dynamicModuleOwners[tokenId] = to;
        emit TransferDM(from, to, tokenId);
    }


    // --- 6. Core System Mechanics ---

    /**
     * @dev Allows users to earn Reputation Points (Simulated).
     *      In a real application, this would be triggered by verifiable external events
     *      or complex internal contract logic proving contribution.
     * @param user The address earning reputation.
     * @param amount The amount of RP earned.
     */
    function earnReputation(address user, uint256 amount) external onlyAdmin {
        require(user != address(0), "Cannot earn for zero address");
        require(amount > 0, "Amount must be greater than 0");
        reputationBalances[user] += amount;
        emit ReputationEarned(user, amount, reputationBalances[user]);
    }

    /**
     * @dev Allows a user to convert their Reputation Points (RP) into Resource Credits (RC).
     *      RP are burned in the process.
     * @param rpAmount The amount of RP to convert.
     */
    function convertReputationToResourceCredits(uint256 rpAmount) external {
        require(rpAmount > 0, "RP amount must be greater than 0");
        uint256 currentReputation = reputationBalances[msg.sender];
        require(currentReputation >= rpAmount, "Insufficient Reputation Points");

        unchecked {
            reputationBalances[msg.sender] = currentReputation - rpAmount;
        }

        uint256 rcAmount = rpAmount * reputationConversionRate;
        _mintResourceCredits(msg.sender, rcAmount);

        emit ReputationConvertedToResourceCredits(msg.sender, rpAmount, rcAmount);
    }

    /**
     * @dev Allows a user to stake Resource Credits (RC) into a specific resource pool.
     *      Staked RC are required for synthesizing and upgrading modules.
     * @param rcAmount The amount of RC to stake.
     * @param resourceTypeId The ID of the resource pool to stake into.
     */
    function stakeResourceCredits(uint256 rcAmount, uint256 resourceTypeId) external {
        require(rcAmount > 0, "RC amount must be greater than 0");
        require(resourceTypeParameters[resourceTypeId].exists, "Invalid resource type ID");
        _transferResourceCredits(msg.sender, address(this), rcAmount); // Transfer RC to contract
        synthesisPools[resourceTypeId] += rcAmount;
        userStakedResources[resourceTypeId][msg.sender] += rcAmount;
        emit ResourceCreditsStaked(msg.sender, resourceTypeId, rcAmount, synthesisPools[resourceTypeId]);
    }

    /**
     * @dev Allows a user to unstake Resource Credits (RC) from a specific resource pool.
     * @param rcAmount The amount of RC to unstake.
     * @param resourceTypeId The ID of the resource pool to unstake from.
     */
    function unstakeResourceCredits(uint256 rcAmount, uint256 resourceTypeId) external {
        require(rcAmount > 0, "RC amount must be greater than 0");
        require(resourceTypeParameters[resourceTypeId].exists, "Invalid resource type ID");
        uint256 staked = userStakedResources[resourceTypeId][msg.sender];
        require(staked >= rcAmount, "Insufficient staked resources");

        unchecked {
            userStakedResources[resourceTypeId][msg.sender] = staked - rcAmount;
        }
        synthesisPools[resourceTypeId] -= rcAmount;
        _mintResourceCredits(msg.sender, rcAmount); // Transfer RC back from contract balance

        emit ResourceCreditsUnstaked(msg.sender, resourceTypeId, rcAmount, synthesisPools[resourceTypeId]);
    }

    /**
     * @dev Allows a user to synthesize a new Dynamic Module (DM) NFT using staked RC from a specific pool.
     *      Costs are deducted from the user's staked amount in the specified pool, plus a fee in RC.
     * @param moduleTypeId The ID of the module type to synthesize.
     * @param resourceTypeId The ID of the resource pool to use for synthesis cost.
     */
    function synthesizeDynamicModule(uint256 moduleTypeId, uint256 resourceTypeId) external returns (uint256 tokenId) {
        ModuleTypeParameters storage moduleParams = moduleTypeParameters[moduleTypeId];
        ResourceTypeParameters storage resourceParams = resourceTypeParameters[resourceTypeId];

        require(moduleParams.exists, "Invalid module type ID");
        require(resourceParams.exists, "Invalid resource type ID");
        require(moduleParams.requiredResourceTypeId == resourceTypeId, "Incorrect resource pool for this module type");

        uint256 requiredResource = moduleParams.requiredResourceAmount;
        uint256 userStaked = userStakedResources[resourceTypeId][msg.sender];
        require(userStaked >= requiredResource, "Insufficient staked resources for synthesis");

        uint256 baseFee = moduleParams.baseSynthesisFee;
        uint256 percentageFee = (requiredResource * synthesisFeeRate) / 10000; // feeRate is in basis points (1/100th of a percent)
        uint256 totalFee = baseFee + percentageFee;

        // Deduct resource cost from staked amount
        unchecked {
            userStakedResources[resourceTypeId][msg.sender] = userStaked - requiredResource;
        }
        synthesisPools[resourceTypeId] -= requiredResource; // This RC stays in the pool or can be managed by admin

        // Deduct RC fee from user's liquid balance
        _burnResourceCredits(msg.sender, totalFee); // Burn fee or send to admin/treasury? Let's accumulate in contract for admin withdrawal
        protocolFees += totalFee;

        // Mint the new module
        tokenId = _mintDynamicModule(msg.sender, moduleTypeId);

        emit ModuleSynthesized(msg.sender, tokenId, moduleTypeId, requiredResource, totalFee);
        return tokenId;
    }

    // --- 7. Dynamic Module Interaction ---

    /**
     * @dev Allows a user to upgrade specific traits of their Dynamic Module using staked resources.
     * @param tokenId The ID of the module to upgrade.
     * @param resourceTypeId The ID of the resource pool to use for upgrade cost.
     * @param traitIndex Which trait to upgrade (0 for primary, 1 for secondary, etc.).
     * @param upgradeAmount The amount of the trait to increase.
     */
    function upgradeDynamicModule(uint256 tokenId, uint256 resourceTypeId, uint8 traitIndex, uint256 upgradeAmount) external whenNotEquipped(tokenId) {
        require(_existsDynamicModule(tokenId), "Module does not exist");
        require(dynamicModuleOwners[tokenId] == msg.sender, "Not owner of module");
        require(resourceTypeParameters[resourceTypeId].exists, "Invalid resource type ID");
        require(upgradeAmount > 0, "Upgrade amount must be greater than 0");
        // Basic check for valid trait index
        require(traitIndex <= 2, "Invalid trait index (0-primary, 1-secondary, 2-rarity)");

        // Calculate cost based on resource type and upgrade amount/current trait value
        uint256 cost = upgradeAmount * resourceTypeParameters[resourceTypeId].upgradeCostMultiplier; // Simple linear cost example
        // More complex cost could consider current trait value, rarity, module type etc.

        uint256 userStaked = userStakedResources[resourceTypeId][msg.sender];
        require(userStaked >= cost, "Insufficient staked resources for upgrade");

        // Deduct cost from staked amount
        unchecked {
            userStakedResources[resourceTypeId][msg.sender] = userStaked - cost;
        }
        synthesisPools[resourceTypeId] -= cost;

        // Apply upgrade to trait
        uint256 oldValue;
        uint256 newValue;
        DynamicModuleTraits storage traits = dynamicModuleTraits[tokenId];
        if (traitIndex == 0) {
            oldValue = traits.primaryTrait;
            traits.primaryTrait += upgradeAmount;
            newValue = traits.primaryTrait;
        } else if (traitIndex == 1) {
            oldValue = traits.secondaryTrait;
            traits.secondaryTrait += upgradeAmount;
            newValue = traits.secondaryTrait;
        } else if (traitIndex == 2) {
             oldValue = traits.rarityScore; // Maybe upgrading rarity is different?
             traits.rarityScore += upgradeAmount;
             newValue = traits.rarityScore;
        }
        // Note: Rarity Score might typically be *derived* from other traits,
        // but here we allow direct upgrade as an example of dynamic state.

        // Update traits mapping explicitly after modifications to the struct
        // dynamicModuleTraits[tokenId] = traits; // Not needed if using storage reference

        emit ModuleUpgraded(tokenId, traitIndex, oldValue, newValue);
    }

    /**
     * @dev Allows a user to mutate a specific trait of their Dynamic Module using staked resources.
     *      Mutation could introduce randomness or change based on the resource used.
     * @param tokenId The ID of the module to mutate.
     * @param traitIndex Which trait to mutate.
     * @param mutationResourceTypeId The ID of the resource pool used for mutation.
     */
    function mutateDynamicModuleTrait(uint256 tokenId, uint8 traitIndex, uint256 mutationResourceTypeId) external whenNotEquipped(tokenId) {
        require(_existsDynamicModule(tokenId), "Module does not exist");
        require(dynamicModuleOwners[tokenId] == msg.sender, "Not owner of module");
        require(resourceTypeParameters[mutationResourceTypeId].exists, "Invalid mutation resource type ID");
        require(traitIndex <= 2, "Invalid trait index");

        // Example cost: fixed amount based on mutation resource type
        uint256 cost = resourceTypeParameters[mutationResourceTypeId].upgradeCostMultiplier; // Re-purpose upgrade cost multiplier as mutation cost base
        require(cost > 0, "Mutation cost must be configured for this resource type");

        uint256 userStaked = userStakedResources[mutationResourceTypeId][msg.sender];
        require(userStaked >= cost, "Insufficient staked resources for mutation");

        // Deduct cost from staked amount
        unchecked {
            userStakedResources[mutationResourceTypeId][msg.sender] = userStaked - cost;
        }
        synthesisPools[mutationResourceTypeId] -= cost;

        // Apply mutation logic
        // Example mutation: Randomly adjust trait value up or down
        // In a real system, this would likely use a VRF (Verifiable Random Function) for true randomness.
        // For this example, we'll use block data (NOT SECURE for high-value randomness)
        uint256 randomFactor = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, tokenId, block.number, traitIndex))) % 10 + 1; // Value between 1 and 10

        uint256 oldValue;
        uint256 newValue;
        DynamicModuleTraits storage traits = dynamicModuleTraits[tokenId];

        // Determine if trait increases or decreases based on resource type or other logic
        // Example: Even resourceTypeIds increase, Odd decrease
        bool increase = (mutationResourceTypeId % 2 == 0);

        if (traitIndex == 0) {
            oldValue = traits.primaryTrait;
            if (increase) {
                traits.primaryTrait += randomFactor;
            } else {
                 // Prevent underflow if decreasing
                traits.primaryTrait = traits.primaryTrait > randomFactor ? traits.primaryTrait - randomFactor : 0;
            }
            newValue = traits.primaryTrait;
        } else if (traitIndex == 1) {
             oldValue = traits.secondaryTrait;
             if (increase) {
                traits.secondaryTrait += randomFactor;
            } else {
                 traits.secondaryTrait = traits.secondaryTrait > randomFactor ? traits.secondaryTrait - randomFactor : 0;
            }
            newValue = traits.secondaryTrait;
        } else if (traitIndex == 2) {
             oldValue = traits.rarityScore;
             if (increase) {
                traits.rarityScore += randomFactor;
            } else {
                 traits.rarityScore = traits.rarityScore > randomFactor ? traits.rarityScore - randomFactor : 0;
            }
            newValue = traits.rarityScore;
        }
        // Add checks for trait bounds if necessary (e.g., max trait value)

        emit ModuleTraitMutated(tokenId, traitIndex, oldValue, newValue, mutationResourceTypeId);
    }

    /**
     * @dev Allows a user to combine two modules, sacrificing one to potentially boost the traits of the other.
     *      Requires staked resources as a cost.
     * @param retainedModuleId The ID of the module whose traits will be boosted.
     * @param sacrificedModuleId The ID of the module that will be burned.
     */
    function combineDynamicModules(uint256 retainedModuleId, uint256 sacrificedModuleId) external whenNotEquipped(retainedModuleId) whenNotEquipped(sacrificedModuleId) {
        require(_existsDynamicModule(retainedModuleId), "Retained module does not exist");
        require(_existsDynamicModule(sacrificedModuleId), "Sacrificed module does not exist");
        require(retainedModuleId != sacrificedModuleId, "Cannot combine a module with itself");
        require(dynamicModuleOwners[retainedModuleId] == msg.sender, "Not owner of retained module");
        require(dynamicModuleOwners[sacrificedModuleId] == msg.sender, "Not owner of sacrificed module");

        // Example Cost: Requires staking a specific resource type based on the *sacrificed* module type
        uint256 sacrificedModuleType = dynamicModuleTypes[sacrificedModuleId];
        ModuleTypeParameters storage sacrificedModuleParams = moduleTypeParameters[sacrificedModuleType];
        require(sacrificedModuleParams.exists, "Invalid type for sacrificed module");

        uint256 requiredResourceTypeId = sacrificedModuleParams.requiredResourceTypeId; // Use resource type associated with sacrificed module
        uint256 cost = sacrificedModuleParams.requiredResourceAmount / 2; // Example: half the synthesis cost as combining cost
        require(cost > 0, "Combining cost derived from sacrificed module type must be greater than 0");

        uint256 userStaked = userStakedResources[requiredResourceTypeId][msg.sender];
        require(userStaked >= cost, "Insufficient staked resources for combining");

        // Deduct cost from staked amount
        unchecked {
            userStakedResources[requiredResourceTypeId][msg.sender] = userStaked - cost;
        }
        synthesisPools[requiredResourceTypeId] -= cost;

        // Boost traits of the retained module based on the sacrificed module's traits
        DynamicModuleTraits storage retainedTraits = dynamicModuleTraits[retainedModuleId];
        DynamicModuleTraits storage sacrificedTraits = dynamicModuleTraits[sacrificedModuleId];

        // Example boosting logic: Add a percentage of sacrificed traits
        retainedTraits.primaryTrait += (sacrificedTraits.primaryTrait * 20) / 100; // Add 20%
        retainedTraits.secondaryTrait += (sacrificedTraits.secondaryTrait * 15) / 100; // Add 15%
        retainedTraits.rarityScore += (sacrificedTraits.rarityScore * 50) / 100; // Add 50%

        // Burn the sacrificed module
        _burnDynamicModule(sacrificedModuleId);

        emit ModulesCombined(msg.sender, retainedModuleId, sacrificedModuleId);
    }

    /**
     * @dev Marks a Dynamic Module as 'equipped'.
     *      Equipped modules might unlock perks in external applications or prevent transfer/burning.
     * @param tokenId The ID of the module to equip.
     */
    function equipDynamicModule(uint256 tokenId) external {
        require(_existsDynamicModule(tokenId), "Module does not exist");
        require(dynamicModuleOwners[tokenId] == msg.sender, "Not owner of module");
        require(!dynamicModuleTraits[tokenId].isEquipped, "Module is already equipped");

        dynamicModuleTraits[tokenId].isEquipped = true;
        emit ModuleEquipped(tokenId, msg.sender);
    }

    /**
     * @dev Marks a Dynamic Module as 'unequipped'.
     * @param tokenId The ID of the module to unequip.
     */
    function unequipDynamicModule(uint256 tokenId) external {
        require(_existsDynamicModule(tokenId), "Module does not exist");
        require(dynamicModuleOwners[tokenId] == msg.sender, "Not owner of module");
        require(dynamicModuleTraits[tokenId].isEquipped, "Module is not equipped");

        dynamicModuleTraits[tokenId].isEquipped = false;
        emit ModuleUnequipped(tokenId, msg.sender);
    }

    /**
     * @dev Allows the owner of a module to delegate specific interaction rights
     *      (like upgrade, mutate) to another address without full transfer approval.
     * @param tokenId The ID of the module to delegate rights for.
     * @param delegatee The address to grant delegation rights to. Set to address(0) to remove.
     */
    function delegateModuleAction(uint256 tokenId, address delegatee) external {
        require(_existsDynamicModule(tokenId), "Module does not exist");
        require(dynamicModuleOwners[tokenId] == msg.sender, "Not owner of module");
        require(delegatee != msg.sender, "Cannot delegate to self");

        dynamicModuleActionDelegates[tokenId] = delegatee;
        emit ModuleDelegateSet(tokenId, delegatee);
    }

    /**
     * @dev Internal helper to check if an address is allowed to perform certain actions
     *      on a module (owner, approved, operator, or specific action delegate).
     *      This would be used inside functions like `upgradeDynamicModule`, `mutateDynamicModuleTrait`.
     *      Leaving these functions external for simplicity, but in a complex system,
     *      they might be protected by this helper check instead of just `msg.sender == owner`.
     */
    // function _canPerformModuleAction(address caller, uint256 tokenId) internal view returns (bool) {
    //     address owner = dynamicModuleOwners[tokenId];
    //     if (caller == owner) return true;
    //     if (_isApprovedOrOwnerDM(caller, tokenId)) return true; // Standard ERC721 approvals might imply action rights too
    //     if (dynamicModuleActionDelegates[tokenId] == caller) return true; // Specific action delegate
    //     return false;
    // }


    // --- 8. Admin/Parameter Setting Functions ---

    /**
     * @dev Admin sets parameters for a specific resource pool ID.
     * @param resourceTypeId The ID of the resource type.
     * @param baseSynthesisCost The base RC cost from this pool for synthesis.
     * @param upgradeCostMultiplier Multiplier for upgrade costs using this resource.
     */
    function setResourceTypeParameters(uint256 resourceTypeId, uint256 baseSynthesisCost, uint256 upgradeCostMultiplier) external onlyAdmin {
         resourceTypeParameters[resourceTypeId] = ResourceTypeParameters({
            baseSynthesisCost: baseSynthesisCost,
            upgradeCostMultiplier: upgradeCostMultiplier,
            exists: true
        });
        emit ResourceTypeParametersSet(resourceTypeId, resourceTypeParameters[resourceTypeId]);
    }

    /**
     * @dev Admin sets synthesis parameters for a specific module type ID.
     * @param moduleTypeId The ID of the module type.
     * @param requiredResourceTypeId The resource pool ID required for synthesis.
     * @param requiredResourceAmount The amount of the required resource needed from the staked pool.
     * @param baseSynthesisFee Base fee in RC paid by the user (in addition to resource cost).
     * @param initialTraitValue Initial value for the primary trait of this module type.
     */
    function setModuleTypeParameters(uint256 moduleTypeId, uint256 requiredResourceTypeId, uint256 requiredResourceAmount, uint256 baseSynthesisFee, uint256 initialTraitValue) external onlyAdmin {
        require(resourceTypeParameters[requiredResourceTypeId].exists, "Required resource type must exist");
        moduleTypeParameters[moduleTypeId] = ModuleTypeParameters({
            requiredResourceTypeId: requiredResourceTypeId,
            requiredResourceAmount: requiredResourceAmount,
            baseSynthesisFee: baseSynthesisFee,
            initialTraitValue: initialTraitValue,
            exists: true
        });
         emit ModuleTypeParametersSet(moduleTypeId, moduleTypeParameters[moduleTypeId]);
    }

    /**
     * @dev Admin sets the conversion rate from Reputation Points (RP) to Resource Credits (RC).
     *      Rate is how many RC are received per 1 RP.
     * @param rate The new conversion rate.
     */
    function setReputationConversionRate(uint256 rate) external onlyAdmin {
        reputationConversionRate = rate;
        emit ReputationConversionRateSet(rate);
    }

     /**
     * @dev Admin sets the percentage fee applied during module synthesis.
     *      Fee is taken from the resource cost amount and accumulated as protocol fees.
     * @param rate The new fee rate in basis points (e.g., 100 = 1%). Max 10000 (100%).
     */
    function setSynthesisFeeRate(uint256 rate) external onlyAdmin {
        require(rate <= 10000, "Fee rate cannot exceed 100%");
        synthesisFeeRate = rate;
        emit SynthesisFeeRateSet(rate);
    }

    /**
     * @dev Admin withdraws accumulated protocol fees.
     * @param recipient The address to send the fees to.
     */
    function withdrawProtocolFees(address recipient) external onlyAdmin {
        require(recipient != address(0), "Cannot withdraw to the zero address");
        uint256 fees = protocolFees;
        require(fees > 0, "No fees to withdraw");
        protocolFees = 0;
        // Transfer RC from the contract's balance
        _transferResourceCredits(address(this), recipient, fees); // Use internal transfer assuming fees are in RC
        emit ProtocolFeesWithdrawn(recipient, fees);
    }


    // --- Resource Credit (RC) ERC-20 Like Functions ---

    /**
     * @dev Transfer RC to another address.
     * @param recipient The address to transfer to.
     * @param amount The amount of RC to transfer.
     */
    function transferResourceCredits(address recipient, uint256 amount) external returns (bool) {
        _transferResourceCredits(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @dev Approve an address to spend RC on your behalf.
     * @param spender The address to approve.
     * @param amount The maximum amount they can spend.
     */
    function approveResourceCredits(address spender, uint256 amount) external returns (bool) {
        resourceCreditAllowances[msg.sender][spender] = amount;
        emit ApprovalRC(msg.sender, spender, amount);
        return true;
    }

    /**
     * @dev Transfer RC from an approved address.
     * @param sender The address whose RC is being transferred.
     * @param recipient The address to transfer to.
     * @param amount The amount of RC to transfer.
     */
    function transferFromResourceCredits(address sender, address recipient, uint256 amount) external returns (bool) {
        uint256 currentAllowance = resourceCreditAllowances[sender][msg.sender];
        require(currentAllowance >= amount, "Transfer amount exceeds allowance");
        unchecked {
            resourceCreditAllowances[sender][msg.sender] = currentAllowance - amount;
        }
        _transferResourceCredits(sender, recipient, amount);
        emit ApprovalRC(sender, msg.sender, resourceCreditAllowances[sender][msg.sender]); // ERC20 standard practice
        return true;
    }


     // --- Dynamic Module (DM) ERC-721 Like Functions ---

     /**
     * @dev Get the owner of a specific Dynamic Module token.
     * @param tokenId The ID of the token.
     */
    function getDynamicModuleOwner(uint256 tokenId) public view returns (address) {
        address owner = dynamicModuleOwners[tokenId];
        require(owner != address(0), "Token does not exist");
        return owner;
    }

     /**
     * @dev Transfer a Dynamic Module token. Standard ERC721 transfer logic.
     * @param from The current owner's address.
     * @param to The recipient's address.
     * @param tokenId The ID of the token to transfer.
     */
    function transferDynamicModule(address from, address to, uint256 tokenId) public {
        require(_isApprovedOrOwnerDM(msg.sender, tokenId), "Caller is not owner nor approved");
        require(dynamicModuleOwners[tokenId] == from, "From address is not the owner");
        _transferDynamicModuleInternal(from, to, tokenId);
    }

     /**
     * @dev Approve an address to take ownership of a specific Dynamic Module token.
     * @param approved The address to approve.
     * @param tokenId The ID of the token to approve.
     */
    function approveDynamicModule(address approved, uint256 tokenId) public {
        address owner = dynamicModuleOwners[tokenId];
        require(owner != address(0), "Token does not exist");
        require(msg.sender == owner || isApprovedForAllDynamicModules(owner, msg.sender), "Caller is not owner nor approved operator");

        dynamicModuleTokenApprovals[tokenId] = approved;
        emit ApprovalDM(owner, approved, tokenId);
    }

     /**
     * @dev Get the approved address for a specific Dynamic Module token.
     * @param tokenId The ID of the token.
     */
    function getApprovedDynamicModule(uint256 tokenId) public view returns (address) {
         require(_existsDynamicModule(tokenId), "Token does not exist");
         return dynamicModuleTokenApprovals[tokenId];
    }

     /**
     * @dev Set or unset the approval for an operator to manage all of your Dynamic Module tokens.
     * @param operator The address of the operator.
     * @param approved True to approve, false to revoke approval.
     */
    function setApprovalForAllDynamicModules(address operator, bool approved) public {
        require(operator != msg.sender, "Cannot approve self as operator");
        dynamicModuleOperatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAllDM(msg.sender, operator, approved);
    }

     /**
     * @dev Check if an address is an approved operator for another address's Dynamic Module tokens.
     * @param owner The address of the token owner.
     * @param operator The address of the potential operator.
     */
    function isApprovedForAllDynamicModules(address owner, address operator) public view returns (bool) {
        return dynamicModuleOperatorApprovals[owner][operator];
    }


    // --- 9. Public Read-Only Functions (Queries) ---

    /**
     * @dev Returns the current version of the contract.
     */
    function getVersion() external pure returns (uint256) {
        return CONTRACT_VERSION;
    }

     /**
     * @dev Returns the address of the contract admin.
     */
    function getAdminAddress() external view returns (address) {
        return admin;
    }

    /**
     * @dev Gets the Reputation Points (RP) balance for a user.
     * @param user The address of the user.
     */
    function getReputationBalance(address user) external view returns (uint256) {
        return reputationBalances[user];
    }

    /**
     * @dev Gets the Resource Credits (RC) balance for a user. (ERC-20 like balanceOf)
     * @param user The address of the user.
     */
    function getResourceCreditBalance(address user) external view returns (uint256) {
        return resourceCreditBalances[user];
    }

    /**
     * @dev Gets the total supply of Resource Credits (RC). (ERC-20 like totalSupply)
     */
    function getTotalResourceCreditsSupply() external view returns (uint256) {
        return totalSupplyRC;
    }

    /**
     * @dev Gets the current traits of a specific Dynamic Module.
     * @param tokenId The ID of the module.
     */
    function getDynamicModuleTraits(uint256 tokenId) external view returns (DynamicModuleTraits memory) {
        require(_existsDynamicModule(tokenId), "Module does not exist");
        return dynamicModuleTraits[tokenId];
    }

    /**
     * @dev Gets the module type ID for a specific Dynamic Module token.
     * @param tokenId The ID of the module.
     */
    function getDynamicModuleType(uint256 tokenId) external view returns (uint256) {
         require(_existsDynamicModule(tokenId), "Module does not exist");
         return dynamicModuleTypes[tokenId];
    }

    /**
     * @dev Gets the parameters configured for a specific resource type ID.
     * @param resourceTypeId The ID of the resource type.
     */
    function getResourceTypeParameters(uint256 resourceTypeId) external view returns (ResourceTypeParameters memory) {
        require(resourceTypeParameters[resourceTypeId].exists, "Resource type ID not configured");
        return resourceTypeParameters[resourceTypeId];
    }

     /**
     * @dev Gets the parameters configured for a specific module type ID.
     * @param moduleTypeId The ID of the module type.
     */
    function getModuleTypeParameters(uint256 moduleTypeId) external view returns (ModuleTypeParameters memory) {
         require(moduleTypeParameters[moduleTypeId].exists, "Module type ID not configured");
         return moduleTypeParameters[moduleTypeId];
    }

    /**
     * @dev Gets the total amount of RC staked in a specific resource pool.
     * @param resourceTypeId The ID of the resource pool.
     */
    function getSynthesisPoolBalance(uint256 resourceTypeId) external view returns (uint256) {
        return synthesisPools[resourceTypeId];
    }

    /**
     * @dev Gets the amount of RC a specific user has staked in a specific resource pool.
     * @param user The address of the user.
     * @param resourceTypeId The ID of the resource pool.
     */
    function getUserStakedResources(address user, uint256 resourceTypeId) external view returns (uint256) {
        return userStakedResources[resourceTypeId][user];
    }

    /**
     * @dev Gets the current conversion rate from RP to RC.
     */
    function getReputationConversionRate() external view returns (uint256) {
        return reputationConversionRate;
    }

     /**
     * @dev Gets the current synthesis fee rate in basis points.
     */
    function getSynthesisFeeRate() external view returns (uint256) {
        return synthesisFeeRate;
    }

    /**
     * @dev Gets the total accumulated protocol fees.
     */
    function getProtocolFees() external view returns (uint256) {
        return protocolFees;
    }

     /**
     * @dev Gets the current delegate for a specific Dynamic Module action.
     * @param tokenId The ID of the module.
     */
    function getDynamicModuleActionDelegate(uint256 tokenId) external view returns (address) {
        require(_existsDynamicModule(tokenId), "Module does not exist");
        return dynamicModuleActionDelegates[tokenId];
    }
}
```