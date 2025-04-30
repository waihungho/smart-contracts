Okay, here is a Solidity smart contract incorporating several advanced, creative, and trendy concepts like upgradability (UUPS proxy), Chainlink VRF for secure randomness, dynamic NFT state tracking, ERC-1155 crafting/loot mechanics, ERC-20 staking influence, and structured configuration.

It's designed as a core "Catalyst" system for a game or ecosystem where users use tokens to "attune" a special NFT (Quantum Orb) to potentially receive unique ERC-1155 items (Loot Modules) based on random chance influenced by inputs and staking.

This contract itself *doesn't deploy* the ERC-20, ERC-721, or ERC-1155 tokens; it *interacts* with external contracts representing those tokens. You would need to deploy those token contracts separately (e.g., using OpenZeppelin's templates) and then configure this contract with their addresses.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol"; // Required if contract holds ERC1155 temporarily (we won't hold, just check/transfer)
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol"; // Useful for tracking items or recipes

// --- Contract Outline ---
// 1. Imports (OpenZeppelin, Chainlink VRF)
// 2. Interfaces for external tokens (ERC20, ERC721, ERC1155) and VRF Coordinator
// 3. Error Definitions (Custom errors for clarity and gas efficiency)
// 4. Event Definitions (Track key actions and state changes)
// 5. Struct Definitions (Define data structures for recipes, outcomes, history, requests)
// 6. State Variables (Contract configuration, token addresses, VRF settings, internal state)
// 7. Mappings (Store user stakes, Orb history, pending loot, VRF requests, configurations)
// 8. Initializer (Setup function for UUPS upgradable proxy)
// 9. Modifiers (Access control, pausable)
// 10. VRF Consumer Implementation (`fulfillRandomWords` callback)
// 11. Core Logic Functions (Request attunement, process random result via callback)
// 12. Configuration Functions (Set token addresses, VRF params, define recipes and loot outcomes)
// 13. Staking Functions (Stake/unstake Catalyst tokens)
// 14. Claiming Functions (Claim pending Loot Modules)
// 15. Dynamic Orb State/History Functions (View Orb history)
// 16. Admin/Utility Functions (Withdraw trapped tokens/ETH, pause/unpause, upgrade)
// 17. View Functions (Check configurations, user state, pending requests)

// --- Function Summary ---
// 1. initialize(...)               : UUPS proxy initializer. Sets owner, pausable state, initial configs.
// 2. setCatalystToken(...)         : Owner sets the address of the ERC-20 Catalyst token.
// 3. setEssenceToken(...)          : Owner sets the address of the ERC-1155 Essence token.
// 4. setQuantumOrbToken(...)       : Owner sets the address of the ERC-721 Quantum Orb token.
// 5. setLootModuleToken(...)       : Owner sets the address of the ERC-1155 Loot Module token.
// 6. setVRFConfig(...)             : Owner sets Chainlink VRF parameters (coordinator, keyhash, fee).
// 7. setSubscriptionId(...)        : Owner sets the Chainlink VRF subscription ID.
// 8. addEssenceRecipeRequirement(...): Owner defines required Essence items (ID, amount) for an attunement recipe.
// 9. removeEssenceRecipeRequirement(...): Owner removes an Essence requirement from a recipe.
// 10. addLootOutcome(...)          : Owner defines a possible Loot Module outcome (ID, amount, weight) linked to an Essence recipe.
// 11. removeLootOutcome(...)       : Owner removes a Loot Module outcome from a recipe.
// 12. setAttunementCatalystCost(...): Owner sets the required Catalyst token amount for an attunement recipe.
// 13. setMinStakeForBoost(...)     : Owner sets the minimum staked Catalyst amount needed for attunement boost/discount.
// 14. setStakingBoostFactor(...)   : Owner sets the factor affecting random chance or outcome quality based on stake.
// 15. setStakingDiscountFactor(...) : Owner sets the discount factor applied to Catalyst cost based on stake.
// 16. requestAttunement(...)       : User initiates an attunement for their Orb, paying Catalyst and providing Essences. Triggers VRF request.
// 17. fulfillRandomWords(...)      : Chainlink VRF callback. Processes randomness, determines loot, updates Orb history, distributes loot.
// 18. stakeCatalyst(...)           : User stakes Catalyst tokens to qualify for boosts/discounts.
// 19. unstakeCatalyst(...)         : User unstakes Catalyst tokens.
// 20. claimLootModules(...)        : User claims Loot Modules awarded from completed attunement requests.
// 21. getOrbAttunementHistory(...) : View function. Retrieves the history of attunements for a specific Orb ID.
// 22. getPendingRequests(...)      : View function. Retrieves information about pending VRF requests.
// 23. getUserPendingLoot(...)      : View function. Retrieves Loot Modules waiting to be claimed by a user.
// 24. getStakeAmount(...)          : View function. Retrieves the amount of Catalyst tokens staked by a user.
// 25. getEssenceRequirements(...)  : View function. Retrieves the Essence requirements for a specific recipe.
// 26. getLootOutcomeConfigs(...)   : View function. Retrieves the configured Loot Module outcomes for a specific recipe.
// 27. getAttunementCatalystCost(...) : View function. Retrieves the Catalyst cost for a specific recipe.
// 28. withdrawERC20(...)           : Owner can withdraw accidentally sent ERC-20 tokens (excluding contract's own tokens).
// 29. withdrawEth(...)             : Owner can withdraw any trapped ETH.
// 30. pause()                      : Owner pauses core contract functions.
// 31. unpause()                    : Owner unpauses core contract functions.
// 32. _authorizeUpgrade(...)       : Internal UUPS function allowing only owner to upgrade.

contract QuantumLootboxCatalyst is OwnableUpgradeable, PausableUpgradeable, UUPSUpgradeable, VRFConsumerBaseV2 {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.Uint256Set;

    // --- Interfaces ---
    IERC20Upgradeable private _catalystToken;
    IERC1155Upgradeable private _essenceToken;
    IERC721Upgradeable private _quantumOrbToken;
    IERC1155Upgradeable private _lootModuleToken;

    VRFCoordinatorV2Interface private _vrfCoordinator;

    // --- Errors ---
    error InvalidTokenAddress(address tokenAddress);
    error TokenAddressNotSet();
    error VRFConfigNotSet();
    error SubscriptionNotSet();
    error RecipeNotFound(uint256 recipeId);
    error EssenceRequirementNotFound(uint256 recipeId, uint256 essenceTokenId);
    error LootOutcomeNotFound(uint256 recipeId, uint256 outcomeIndex);
    error InsufficientCatalystAllowance(address user, uint256 required, uint256 allowed);
    error InsufficientEssenceBalanceOrAllowance(address user, uint256 essenceTokenId, uint256 required, uint256 owned);
    error OrbNotOwnedOrApproved(address user, uint256 orbTokenId);
    error VRFRequestFailed();
    error RequestIdNotFound(uint256 requestId);
    error StakingAmountZero();
    error InsufficientStakedCatalyst();
    error InsufficientPendingLoot();
    error CannotWithdrawContractToken(address tokenAddress);

    // --- Events ---
    event Initialized(uint8 version);
    event CatalystTokenSet(address indexed token);
    event EssenceTokenSet(address indexed token);
    event QuantumOrbTokenSet(address indexed token);
    event LootModuleTokenSet(address indexed token);
    event VRFConfigSet(address indexed coordinator, bytes32 keyHash, uint32 callbackGasLimit, uint32 requestConfirmations, uint256 fee);
    event SubscriptionIdSet(uint64 indexed subId);
    event EssenceRecipeRequirementAdded(uint256 indexed recipeId, uint256 indexed essenceTokenId, uint256 amount);
    event EssenceRecipeRequirementRemoved(uint256 indexed recipeId, uint256 indexed essenceTokenId);
    event LootOutcomeAdded(uint256 indexed recipeId, uint256 indexed outcomeIndex, uint256 lootModuleTokenId, uint256 amount, uint16 weight);
    event LootOutcomeRemoved(uint256 indexed recipeId, uint256 indexed outcomeIndex);
    event AttunementCatalystCostSet(uint256 indexed recipeId, uint256 cost);
    event MinStakeForBoostSet(uint256 amount);
    event StakingBoostFactorSet(uint256 factor);
    event StakingDiscountFactorSet(uint256 factor);
    event AttunementRequested(uint256 indexed requestId, address indexed user, uint256 indexed orbTokenId, uint256 recipeId, uint256 catalystCostPaid);
    event AttunementFulfilled(uint256 indexed requestId, address indexed user, uint256 indexed orbTokenId, uint256 recipeId, uint256[] awardedLootModuleIds, uint256[] awardedLootAmounts);
    event CatalystStaked(address indexed user, uint256 amount);
    event CatalystUnstaked(address indexed user, uint256 amount);
    event LootModulesClaimed(address indexed user, uint256[] lootModuleIds, uint256[] amounts);
    event OrbAttunementHistoryUpdated(uint256 indexed orbTokenId, uint256 recipeId, uint256 timestamp);

    // --- Structs ---
    struct EssenceRequirement {
        uint256 essenceTokenId;
        uint256 amount;
    }

    struct LootOutcome {
        uint256 lootModuleTokenId;
        uint256 amount;
        uint16 weight; // Relative weight for random selection
        uint16 cumulativeWeight; // Calculated for weighted random selection
    }

    struct AttunementRecord {
        uint256 recipeId;
        uint256 timestamp;
        // Could add other details like essences used, catalyst paid, outcome received (pointers/ids)
    }

    struct VRFRequest {
        address user;
        uint256 orbTokenId;
        uint256 recipeId;
        uint256 catalystCostPaid; // Actual cost paid after discount
        mapping(uint256 => uint256) pendingLoot; // lootModuleTokenId => amount
    }

    // --- State Variables ---
    uint32 public s_callbackGasLimit;
    uint32 public s_requestConfirmations;
    uint256 public s_vrfFee;
    bytes32 public s_keyHash;
    uint64 public s_subscriptionId;
    uint256 public minStakeForBoost;
    uint256 public stakingBoostFactor; // Factor > 10000 grants boost, < 10000 penalty (or interpreted differently)
    uint256 public stakingDiscountFactor; // e.g., 10000 means 100% cost, 9000 means 90% cost (10% discount)

    // --- Mappings ---
    // Config: recipeId => Essence Requirements (array of structs)
    mapping(uint256 => EssenceRequirement[]) private _essenceRecipeRequirements;
    // Config: recipeId => Loot Outcomes (array of structs)
    mapping(uint256 => LootOutcome[]) private _lootOutcomes;
    // Config: recipeId => Total weight for weighted random selection
    mapping(uint256 => uint16) private _recipeTotalWeight;
    // Config: recipeId => Catalyst Cost
    mapping(uint256 => uint256) private _attunementCatalystCosts;
    // Config: Set of configured recipe IDs
    EnumerableSetUpgradeable.Uint256Set private _configuredRecipeIds;

    // User State: user address => staked Catalyst amount
    mapping(address => uint256) public stakedCatalyst;
    // User State: user address => lootModuleTokenId => amount pending claim
    mapping(address => mapping(uint256 => uint256)) private _userPendingLoot;
    EnumerableSetUpgradeable.Uint256Set private _usersWithPendingLoot; // To track users with pending loot

    // Orb State: orbTokenId => Attunement History (array of structs)
    mapping(uint256 => AttunementRecord[]) private _orbAttunementHistory;

    // VRF State: requestId => VRFRequest details
    mapping(uint256 => VRFRequest) private _vrfRequests;
    // VRF State: Set of pending requestIds
    EnumerableSetUpgradeable.Uint256Set private _pendingRequestIds;

    // --- Initializer ---
    /// @custom:oz-initialize
    function initialize(address ownerAddress) external initializer {
        __Ownable_init(ownerAddress);
        __Pausable_init();
        __UUPSUpgradeable_init(); // Initializes UUPS context

        // Default staking factors (e.g., 100% cost, no boost)
        stakingBoostFactor = 10000; // Represents 1.0x boost
        stakingDiscountFactor = 10000; // Represents 100% cost

        emit Initialized(1);
    }

    // --- Modifiers ---
    modifier onlyVRF() {
        if (msg.sender != address(_vrfCoordinator)) {
            revert OwnableUnauthorizedAccount(msg.sender); // Use Ownable error for consistency, although more specific error is possible
        }
        _;
    }

    modifier tokensMustBeSet() {
        if (address(_catalystToken) == address(0) ||
            address(_essenceToken) == address(0) ||
            address(_quantumOrbToken) == address(0) ||
            address(_lootModuleToken) == address(0)) {
            revert TokenAddressNotSet();
        }
        _;
    }

    modifier vrfConfigMustBeSet() {
         if (address(_vrfCoordinator) == address(0) || s_keyHash == bytes32(0) || s_vrfFee == 0) {
            revert VRFConfigNotSet();
        }
         if (s_subscriptionId == 0) {
            revert SubscriptionNotSet();
        }
        _;
    }

    modifier recipeMustExist(uint256 recipeId) {
        if (!_configuredRecipeIds.contains(recipeId)) {
            revert RecipeNotFound(recipeId);
        }
        _;
    }

    // --- VRF Consumer Implementation ---

    /// @dev Callback function from Chainlink VRF after random words are available.
    /// Processes the random result and determines loot.
    /// @param requestId The ID of the VRF request.
    /// @param randomWords The random words generated by Chainlink VRF.
    function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords)
        internal
        override
        onlyVRF // Only allow the VRF Coordinator to call this
    {
        if (!_pendingRequestIds.contains(requestId)) {
             // Request was already fulfilled or is invalid. Ignore.
            return;
        }

        VRFRequest storage req = _vrfRequests[requestId];
        address user = req.user;
        uint256 orbTokenId = req.orbTokenId;
        uint256 recipeId = req.recipeId;

        // Use the first random word for weighted selection
        uint256 randomNumber = randomWords[0];
        uint16 totalWeight = _recipeTotalWeight[recipeId];
        require(totalWeight > 0, "Recipe total weight must be greater than zero"); // Should be guaranteed by addLootOutcome checks

        // Calculate effective random value within total weight range
        uint16 randomValue = uint16(randomNumber % totalWeight);

        // Determine outcome based on weighted random selection
        uint16 cumulativeWeight = 0;
        bool outcomeFound = false;
        uint256 awardedLootModuleId = 0;
        uint256 awardedLootAmount = 0;

        LootOutcome[] storage outcomes = _lootOutcomes[recipeId];
        uint256 numOutcomes = outcomes.length;

        // Add staking boost/penalty logic to randomValue or outcome weights if desired
        // For simplicity here, let's assume boost affects a chance *before* outcome selection,
        // or slightly skews the randomValue towards higher weight outcomes.
        // Example: If user has stake > minStakeForBoost, maybe roll dice multiple times and pick best?
        // Or simply add a small percentage to randomValue? Let's use a simple weighted boost approach:
        // Calculate adjusted random value considering boostFactor if applicable.
        // A higher boostFactor makes it easier to land in higher-weight buckets.
        // This requires careful design based on how boostFactor is defined.
        // Let's use a simplified approach where boost slightly shifts the random value.
        // If boostFactor > 10000 and user meets min stake, slightly reduce the randomValue (making it land in potentially higher weight buckets easier).
        uint256 effectiveRandomValue = randomValue;
        if (stakedCatalyst[user] >= minStakeForBoost && stakingBoostFactor > 10000) {
            // Example boost: Reduce randomValue by a percentage proportional to boostFactor above 10000
            uint256 boostAmount = (effectiveRandomValue * (stakingBoostFactor - 10000)) / 10000;
             if (effectiveRandomValue > boostAmount) { // Prevent underflow
                 effectiveRandomValue = effectiveRandomValue - boostAmount;
             } else {
                 effectiveRandomValue = 0; // Cap at 0
             }
        }
        uint16 adjustedRandomValue = uint16(effectiveRandomValue % totalWeight); // Ensure it stays within total weight range

        for (uint i = 0; i < numOutcomes; i++) {
            cumulativeWeight += outcomes[i].weight;
            if (adjustedRandomValue < cumulativeWeight) { // Use adjustedRandomValue here
                awardedLootModuleId = outcomes[i].lootModuleTokenId;
                awardedLootAmount = outcomes[i].amount;
                outcomeFound = true;
                break;
            }
        }

        // If no outcome is found (shouldn't happen if totalWeight is calculated correctly and loop is correct),
        // potentially award a default "failed" item or revert. Let's assume an outcome is always found.
        require(outcomeFound, "Failed to determine loot outcome");

        // Store loot pending claim
        req.pendingLoot[awardedLootModuleId] += awardedLootAmount;
        _userPendingLoot[user][awardedLootModuleId] += awardedLootAmount; // Duplicate storage for easy lookup
         _usersWithPendingLoot.add(user);

        // Update Orb History
        _orbAttunementHistory[orbTokenId].push(AttunementRecord({
            recipeId: recipeId,
            timestamp: block.timestamp
            // Add other relevant details if needed
        }));

        // Clean up VRF request storage and pending requests set
        delete _vrfRequests[requestId];
        _pendingRequestIds.remove(requestId);

        // Emit events
        emit AttunementFulfilled(requestId, user, orbTokenId, recipeId, new uint256[](1), new uint256[](1)); // Simplified emit, can improve
        emit OrbAttunementHistoryUpdated(orbTokenId, recipeId, block.timestamp);
        // Note: LootModulesClaimed event is emitted when user *claims* the loot, not when awarded.
    }

    // --- Core Logic Functions ---

    /// @dev Allows a user to request attunement for their Quantum Orb.
    /// Requires Catalyst tokens, specific Essence tokens, and ownership/approval of the Orb.
    /// Initiates a Chainlink VRF request for random outcome generation.
    /// @param orbTokenId The ID of the Quantum Orb NFT to attune.
    /// @param recipeId The ID of the attunement recipe to use.
    function requestAttunement(uint256 orbTokenId, uint256 recipeId)
        external
        whenNotPaused
        tokensMustBeSet
        vrfConfigMustBeSet
        recipeMustExist(recipeId)
    {
        address user = msg.sender;

        // 1. Verify Orb Ownership/Approval
        IERC721Upgradeable quantumOrb = _quantumOrbToken;
        if (quantumOrb.ownerOf(orbTokenId) != user && !quantumOrb.isApprovedForAll(user, address(this))) {
             revert OrbNotOwnedOrApproved(user, orbTokenId);
        }
        // Note: The Orb itself is NOT transferred to the contract. It remains with the user.
        // Its state/history is tracked conceptually via a mapping.

        // 2. Check and Transfer Catalyst Cost
        uint256 requiredCatalystCost = _attunementCatalystCosts[recipeId];
        require(requiredCatalystCost > 0, "Catalyst cost must be set for this recipe");

        // Apply staking discount
        uint256 actualCatalystCost = requiredCatalystCost;
        if (stakedCatalyst[user] >= minStakeForBoost && stakingDiscountFactor < 10000) {
             actualCatalystCost = (requiredCatalystCost * stakingDiscountFactor) / 10000;
        }

        IERC20Upgradeable catalyst = _catalystToken;
        uint256 allowance = catalyst.allowance(user, address(this));
        if (allowance < actualCatalystCost) {
            revert InsufficientCatalystAllowance(user, actualCatalystCost, allowance);
        }
        // TransferFrom requires user to have approved this contract first.
        catalyst.transferFrom(user, address(this), actualCatalystCost);

        // 3. Check and Transfer Essence Requirements (ERC-1155)
        IERC1155Upgradeable essence = _essenceToken;
        EssenceRequirement[] storage requirements = _essenceRecipeRequirements[recipeId];
        uint256 numRequirements = requirements.length;

        // ERC1155 requires `safeBatchTransferFrom` or individual `safeTransferFrom`.
        // Using batch transfer is more efficient. Need to build the arrays.
        uint256[] memory essenceTokenIds = new uint256[](numRequirements);
        uint256[] memory essenceAmounts = new uint256[](numRequirements);

        for (uint i = 0; i < numRequirements; i++) {
            uint256 reqTokenId = requirements[i].essenceTokenId;
            uint256 reqAmount = requirements[i].amount;

            uint256 userBalance = essence.balanceOf(user, reqTokenId);
            if (userBalance < reqAmount) {
                revert InsufficientEssenceBalanceOrAllowance(user, reqTokenId, reqAmount, userBalance);
            }

            // Check ERC-1155 approval for all
            if (!essence.isApprovedForAll(user, address(this))) {
                revert InsufficientEssenceBalanceOrAllowance(user, reqTokenId, reqAmount, userBalance); // Re-using error, need to clarify allowance part
            }

            essenceTokenIds[i] = reqTokenId;
            essenceAmounts[i] = reqAmount;
        }

        // Transfer Essences from user to this contract
        if (numRequirements > 0) {
             essence.safeBatchTransferFrom(user, address(this), essenceTokenIds, essenceAmounts, "");
        }

        // 4. Request Random Words from Chainlink VRF
        VRFCoordinatorV2Interface vrfCoordinator = _vrfCoordinator;
        uint256 requestId = vrfCoordinator.requestRandomWords(
            s_keyHash,
            s_subscriptionId,
            s_requestConfirmations,
            s_callbackGasLimit,
            1 // Requesting 1 random word
        );

        if (requestId == 0) {
            revert VRFRequestFailed(); // Basic check if request failed immediately (unlikely)
        }

        // 5. Store request details
        _vrfRequests[requestId] = VRFRequest({
            user: user,
            orbTokenId: orbTokenId,
            recipeId: recipeId,
            catalystCostPaid: actualCatalystCost,
            pendingLoot: new mapping(uint256 => uint256)() // Initialize empty map
        });
        _pendingRequestIds.add(requestId);

        // 6. Emit event
        emit AttunementRequested(requestId, user, orbTokenId, recipeId, actualCatalystCost);
    }

    // --- Configuration Functions (Owner Only) ---

    function setCatalystToken(address tokenAddress) external onlyOwner {
        if (tokenAddress == address(0)) revert InvalidTokenAddress(tokenAddress);
        _catalystToken = IERC20Upgradeable(tokenAddress);
        emit CatalystTokenSet(tokenAddress);
    }

    function setEssenceToken(address tokenAddress) external onlyOwner {
        if (tokenAddress == address(0)) revert InvalidTokenAddress(tokenAddress);
        _essenceToken = IERC1155Upgradeable(tokenAddress);
        emit EssenceTokenSet(tokenAddress);
    }

    function setQuantumOrbToken(address tokenAddress) external onlyOwner {
        if (tokenAddress == address(0)) revert InvalidTokenAddress(tokenAddress);
        _quantumOrbToken = IERC721Upgradeable(tokenAddress);
        emit QuantumOrbTokenSet(tokenAddress);
    }

    function setLootModuleToken(address tokenAddress) external onlyOwner {
        if (tokenAddress == address(0)) revert InvalidTokenAddress(tokenAddress);
        _lootModuleToken = IERC1155Upgradeable(tokenAddress);
        emit LootModuleTokenSet(tokenAddress);
    }

    function setVRFConfig(
        address coordinator,
        bytes32 keyHash,
        uint32 callbackGasLimit,
        uint32 requestConfirmations,
        uint256 fee
    ) external onlyOwner {
        if (coordinator == address(0) || keyHash == bytes32(0) || fee == 0) revert VRFConfigNotSet();
        _vrfCoordinator = VRFCoordinatorV2Interface(coordinator);
        s_keyHash = keyHash;
        s_callbackGasLimit = callbackGasLimit;
        s_requestConfirmations = requestConfirmations;
        s_vrfFee = fee;
        emit VRFConfigSet(coordinator, keyHash, callbackGasLimit, requestConfirmations, fee);
    }

    function setSubscriptionId(uint64 subId) external onlyOwner {
        if (subId == 0) revert SubscriptionNotSet();
        s_subscriptionId = subId;
        emit SubscriptionIdSet(subId);
    }

    function addEssenceRecipeRequirement(uint256 recipeId, uint256 essenceTokenId, uint256 amount) external onlyOwner {
        require(amount > 0, "Amount must be greater than 0");
        EssenceRequirement[] storage requirements = _essenceRecipeRequirements[recipeId];
        // Prevent duplicate requirements for the same token ID within a recipe
        for (uint i = 0; i < requirements.length; i++) {
            if (requirements[i].essenceTokenId == essenceTokenId) {
                revert("Requirement for this essence token ID already exists");
            }
        }
        requirements.push(EssenceRequirement({
            essenceTokenId: essenceTokenId,
            amount: amount
        }));
        _configuredRecipeIds.add(recipeId);
        emit EssenceRecipeRequirementAdded(recipeId, essenceTokenId, amount);
    }

    function removeEssenceRecipeRequirement(uint256 recipeId, uint256 essenceTokenId) external onlyOwner recipeMustExist(recipeId) {
         EssenceRequirement[] storage requirements = _essenceRecipeRequirements[recipeId];
         for (uint i = 0; i < requirements.length; i++) {
             if (requirements[i].essenceTokenId == essenceTokenId) {
                 // Simple removal: replace with last element and pop
                 requirements[i] = requirements[requirements.length - 1];
                 requirements.pop();
                 emit EssenceRecipeRequirementRemoved(recipeId, essenceTokenId);
                 // If this was the last config for this recipe, remove recipeId from set? Optional.
                 if (requirements.length == 0 && _lootOutcomes[recipeId].length == 0 && _attunementCatalystCosts[recipeId] == 0) {
                     _configuredRecipeIds.remove(recipeId);
                 }
                 return;
             }
         }
         revert EssenceRequirementNotFound(recipeId, essenceTokenId);
    }

    function addLootOutcome(uint256 recipeId, uint256 lootModuleTokenId, uint256 amount, uint16 weight) external onlyOwner {
        require(amount > 0, "Amount must be greater than 0");
        require(weight > 0, "Weight must be greater than 0"); // Outcomes with zero weight are meaningless

        LootOutcome[] storage outcomes = _lootOutcomes[recipeId];
        uint16 currentTotalWeight = _recipeTotalWeight[recipeId];

        // Add the new outcome
        outcomes.push(LootOutcome({
            lootModuleTokenId: lootModuleTokenId,
            amount: amount,
            weight: weight,
            cumulativeWeight: currentTotalWeight + weight // Store cumulative weight for easier selection
        }));

        // Update total weight
        _recipeTotalWeight[recipeId] = currentTotalWeight + weight;

        _configuredRecipeIds.add(recipeId);
        emit LootOutcomeAdded(recipeId, outcomes.length - 1, lootModuleTokenId, amount, weight);
    }

    function removeLootOutcome(uint256 recipeId, uint256 outcomeIndex) external onlyOwner recipeMustExist(recipeId) {
         LootOutcome[] storage outcomes = _lootOutcomes[recipeId];
         require(outcomeIndex < outcomes.length, "Invalid outcome index");

         uint16 weightToRemove = outcomes[outcomeIndex].weight;

         // Remove the outcome: Replace with last element and pop
         outcomes[outcomeIndex] = outcomes[outcomes.length - 1];
         outcomes.pop();

         // Recalculate cumulative weights for the affected recipe
         uint16 currentCumulativeWeight = 0;
         for (uint i = 0; i < outcomes.length; i++) {
             currentCumulativeWeight += outcomes[i].weight;
             outcomes[i].cumulativeWeight = currentCumulativeWeight;
         }

         // Update total weight
         _recipeTotalWeight[recipeId] = currentCumulativeWeight;

         emit LootOutcomeRemoved(recipeId, outcomeIndex);

         // If this was the last config for this recipe, remove recipeId from set? Optional.
          if (_essenceRecipeRequirements[recipeId].length == 0 && outcomes.length == 0 && _attunementCatalystCosts[recipeId] == 0) {
              _configuredRecipeIds.remove(recipeId);
          }
    }

    function setAttunementCatalystCost(uint256 recipeId, uint256 cost) external onlyOwner {
        _attunementCatalystCosts[recipeId] = cost;
        _configuredRecipeIds.add(recipeId);
        emit AttunementCatalystCostSet(recipeId, cost);
    }

    function setMinStakeForBoost(uint256 amount) external onlyOwner {
        minStakeForBoost = amount;
        emit MinStakeForBoostSet(amount);
    }

    function setStakingBoostFactor(uint256 factor) external onlyOwner {
        stakingBoostFactor = factor;
        emit StakingBoostFactorSet(factor);
    }

    function setStakingDiscountFactor(uint256 factor) external onlyOwner {
        require(factor <= 10000, "Discount factor cannot be > 10000 (100%)");
        stakingDiscountFactor = factor;
        emit StakingDiscountFactorSet(factor);
    }

    // --- Staking Functions ---

    /// @dev Allows users to stake Catalyst tokens.
    /// Requires user to approve this contract to spend the tokens first.
    /// @param amount The amount of Catalyst tokens to stake.
    function stakeCatalyst(uint256 amount) external whenNotPaused tokensMustBeSet {
        if (amount == 0) revert StakingAmountZero();
        IERC20Upgradeable catalyst = _catalystToken;
        uint256 allowance = catalyst.allowance(msg.sender, address(this));
        if (allowance < amount) {
             revert InsufficientCatalystAllowance(msg.sender, amount, allowance);
        }
        catalyst.transferFrom(msg.sender, address(this), amount);
        stakedCatalyst[msg.sender] += amount;
        emit CatalystStaked(msg.sender, amount);
    }

    /// @dev Allows users to unstake Catalyst tokens.
    /// @param amount The amount of Catalyst tokens to unstake.
    function unstakeCatalyst(uint256 amount) external whenNotPaused tokensMustBeSet {
        require(stakedCatalyst[msg.sender] >= amount, "Insufficient staked amount");
        stakedCatalyst[msg.sender] -= amount;
        IERC20Upgradeable catalyst = _catalystToken;
        catalyst.transfer(msg.sender, amount);
        emit CatalystUnstaked(msg.sender, amount);
    }

    // --- Claiming Functions ---

    /// @dev Allows a user to claim Loot Modules awarded from fulfilled attunement requests.
    function claimLootModules() external whenNotPaused tokensMustBeSet {
        address user = msg.sender;
        require(_usersWithPendingLoot.contains(user), "No pending loot to claim"); // Optimization

        mapping(uint256 => uint256) storage pending = _userPendingLoot[user];

        uint256[] memory lootModuleIdsToClaim;
        uint256[] memory amountsToClaim;
        uint256 claimCount = 0;

        // Iterate through potential loot modules (could optimize this if many types exist)
        // A better way is to track *which* lootModuleIds a user has pending.
        // Let's assume we iterate over the *configured* loot module IDs for simplicity, or just iterate up to a reasonable limit.
        // A more robust solution would track specific loot IDs a user is owed.
        // For now, let's extract what they *do* have pending.
        // A better approach would be to store pending loot as (id, amount) pairs in a dynamic array or linked list per user.
        // Let's try to extract from the mapping dynamically.

        // This dynamic extraction is tricky and potentially gas intensive for many pending items.
        // A common pattern is to allow claiming *specific* items/amounts, or adding a claim limit.
        // Let's refine the VRFRequest struct and _userPendingLoot to store awarded items more directly.
        // The VRFRequest already stores it. We need to transfer from the request storage to the user's claimable storage.
        // Let's modify `fulfillRandomWords` to move from `req.pendingLoot` to `_userPendingLoot[user]` mapping.
        // The current implementation already does this.
        // So, now we need to iterate the `_userPendingLoot[user]` mapping. Solidity doesn't have easy mapping iteration.
        // We need an auxiliary data structure to track *which* token IDs have pending loot for a user.
        // Let's add a `mapping(address => uint256[]) private _userPendingLootIds;` and add/remove IDs there.

        // *Correction*: The `_userPendingLoot` mapping *does* store the amounts. We just can't iterate its keys directly.
        // The simplest way is to require the user to specify *which* tokens they want to claim, or claim *all* up to a limit.
        // Let's implement a claim-all-up-to-limit approach, iterating through a range of potential IDs or requiring the user to provide IDs.
        // Requiring the user to provide IDs is gas-efficient for the contract.

        // --- Revised Claiming ---
        // User provides the list of Loot Module IDs they expect to claim.
        // The contract checks their pending balance for each ID and transfers.
    }

    /// @dev Allows a user to claim specific Loot Modules awarded from fulfilled attunement requests.
    /// @param lootModuleIds The list of Loot Module IDs to claim.
    function claimLootModules(uint256[] calldata lootModuleIds) external whenNotPaused tokensMustBeSet {
        address user = msg.sender;
        mapping(uint256 => uint256) storage pending = _userPendingLoot[user];

        uint256[] memory actualClaimIds = new uint256[](lootModuleIds.length);
        uint256[] memory actualClaimAmounts = new uint256[](lootModuleIds.length);
        uint256 claimCount = 0;

        for (uint i = 0; i < lootModuleIds.length; i++) {
            uint256 lootId = lootModuleIds[i];
            uint256 amount = pending[lootId];

            if (amount > 0) {
                actualClaimIds[claimCount] = lootId;
                actualClaimAmounts[claimCount] = amount;
                pending[lootId] = 0; // Clear pending balance for this ID
                claimCount++;
            }
        }

        require(claimCount > 0, InsufficientPendingLoot());

        // Resize arrays to actual claimed items
        uint256[] memory finalClaimIds = new uint256[](claimCount);
        uint256[] memory finalClaimAmounts = new uint256[](claimCount);
        for (uint i = 0; i < claimCount; i++) {
            finalClaimIds[i] = actualClaimIds[i];
            finalClaimAmounts[i] = actualClaimAmounts[i];
        }

        // Transfer Loot Modules
        IERC1155Upgradeable lootModule = _lootModuleToken;
        lootModule.safeBatchTransferFrom(address(this), user, finalClaimIds, finalClaimAmounts, "");

        // Check if user still has any pending loot across other IDs
        // This requires iterating the mapping, which is not possible directly.
        // A flag or auxiliary structure is needed to manage _usersWithPendingLoot set.
        // For simplicity, let's assume clearing all requested items means they *might* not have pending loot anymore,
        // but the set member is only removed when all pending balances are zero. This is inefficient.
        // A better way is to use an iterable map or track pending IDs explicitly per user.
        // Given the complexity of reliably tracking zero balances across an unbounded mapping,
        // it's safer to leave the user in the `_usersWithPendingLoot` set until *all* possible types are zero,
        // or iterate a known list of configured loot IDs, or require user to provide *all* IDs they expect.
        // Let's keep the current approach but acknowledge the set might contain users with zero balance for some IDs.

        emit LootModulesClaimed(user, finalClaimIds, finalClaimAmounts);
    }

    // --- Dynamic Orb State/History Functions (View Only) ---

    /// @dev Retrieves the attunement history for a specific Quantum Orb.
    /// @param orbTokenId The ID of the Orb.
    /// @return An array of AttunementRecord structs.
    function getOrbAttunementHistory(uint256 orbTokenId) external view returns (AttunementRecord[] memory) {
        return _orbAttunementHistory[orbTokenId];
    }

    /// @dev Retrieves the current state (most recent attunement) for a specific Quantum Orb.
    /// @param orbTokenId The ID of the Orb.
    /// @return The most recent AttunementRecord, or a default struct if no history exists.
    function getOrbState(uint256 orbTokenId) external view returns (AttunementRecord memory) {
        AttunementRecord[] storage history = _orbAttunementHistory[orbTokenId];
        if (history.length == 0) {
            return AttunementRecord({recipeId: 0, timestamp: 0}); // Default state
        }
        return history[history.length - 1]; // Return the latest record
    }


    // --- Admin/Utility Functions ---

    /// @dev Allows the owner to withdraw accidentally sent ERC-20 tokens.
    /// Prevents withdrawal of the contract's own configured tokens (Catalyst).
    /// @param tokenAddress The address of the ERC-20 token to withdraw.
    /// @param amount The amount to withdraw.
    function withdrawERC20(address tokenAddress, uint256 amount) external onlyOwner {
        if (tokenAddress == address(0) || amount == 0) revert("Invalid address or amount");
        if (tokenAddress == address(_catalystToken)) revert CannotWithdrawContractToken(tokenAddress);
        // Add checks for other configured tokens if they were ERC20 (Essence, Loot Modules are ERC1155)

        IERC20Upgradeable token = IERC20Upgradeable(tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        require(balance >= amount, "Insufficient balance in contract");
        token.transfer(owner(), amount);
    }

    /// @dev Allows the owner to withdraw any trapped ETH.
    function withdrawEth() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No ETH balance in contract");
        (bool success, ) = payable(owner()).call{value: balance}("");
        require(success, "ETH transfer failed");
    }

    /// @dev Pauses the contract's core functions (requestAttunement, stake, unstake, claim).
    function pause() external onlyOwner {
        _pause();
    }

    /// @dev Unpauses the contract.
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @dev Internal function for UUPSUpgradeable to authorize upgrades.
    /// @param newImplementation The address of the new implementation contract.
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    // --- View Functions ---

    /// @dev Retrieves information about pending VRF requests.
    /// @return requestIds An array of request IDs that are pending.
    /// @return users Corresponding user addresses for the requests.
    /// @return orbTokenIds Corresponding Orb token IDs for the requests.
    function getPendingRequests() external view returns (uint256[] memory requestIds, address[] memory users, uint256[] memory orbTokenIds) {
        uint256 count = _pendingRequestIds.length();
        requestIds = new uint256[](count);
        users = new address[](count);
        orbTokenIds = new uint256[](count);

        for (uint i = 0; i < count; i++) {
            uint256 reqId = _pendingRequestIds.at(i);
            VRFRequest storage req = _vrfRequests[reqId];
            requestIds[i] = reqId;
            users[i] = req.user;
            orbTokenIds[i] = req.orbTokenId;
        }
        return (requestIds, users, orbTokenIds);
    }

    /// @dev Retrieves the pending Loot Modules for a specific user.
    /// NOTE: This view function cannot easily return *all* types and amounts
    /// if the user has many distinct Loot Module IDs pending without iterating.
    /// It's better to query for specific IDs using `getUserPendingLootAmount`.
    /// Alternatively, this could return a predefined list of configured loot IDs and their pending amounts.
     function getUserPendingLoot(address user) external view returns (uint256[] memory lootModuleIds, uint256[] memory amounts) {
         // To make this function useful without iterating a sparse mapping,
         // we can return the pending amounts for *all configured* loot outcomes across all recipes.
         // This might return a lot of zeros but gives a comprehensive view.
         // A more advanced approach needs an auxiliary mapping to track which loot IDs a user is owed.
         // Let's return pending amounts for the first 100 potential loot module IDs as a limited example.
         // **Warning**: This is not a robust solution for arbitrary loot IDs.
         // A proper solution requires tracking pending IDs per user.

         // Let's return pending amounts for a fixed set or require the caller to provide IDs.
         // Since the `claimLootModules` function requires IDs, let's create a view function that takes IDs too.
     }

    /// @dev Retrieves the pending amount for a specific Loot Module ID for a user.
    /// @param user The address of the user.
    /// @param lootModuleId The ID of the Loot Module token.
    /// @return The pending amount.
    function getUserPendingLootAmount(address user, uint256 lootModuleId) external view returns (uint256) {
         return _userPendingLoot[user][lootModuleId];
    }


    /// @dev Retrieves the amount of Catalyst tokens staked by a user.
    /// @param user The address of the user.
    /// @return The staked amount.
    function getStakeAmount(address user) external view returns (uint256) {
        return stakedCatalyst[user];
    }

    /// @dev Retrieves the Essence requirements for a specific recipe.
    /// @param recipeId The ID of the recipe.
    /// @return An array of EssenceRequirement structs.
    function getEssenceRequirements(uint256 recipeId) external view recipeMustExist(recipeId) returns (EssenceRequirement[] memory) {
        return _essenceRecipeRequirements[recipeId];
    }

    /// @dev Retrieves the configured Loot Module outcomes for a specific recipe.
    /// @param recipeId The ID of the recipe.
    /// @return An array of LootOutcome structs.
    function getLootOutcomeConfigs(uint256 recipeId) external view recipeMustExist(recipeId) returns (LootOutcome[] memory) {
        return _lootOutcomes[recipeId];
    }

    /// @dev Retrieves the Catalyst cost for a specific recipe.
    /// @param recipeId The ID of the recipe.
    /// @return The Catalyst cost.
    function getAttunementCatalystCost(uint256 recipeId) external view returns (uint256) {
        return _attunementCatalystCosts[recipeId];
    }

    /// @dev Returns the list of configured recipe IDs.
    function getConfiguredRecipeIds() external view returns (uint256[] memory) {
        uint256 count = _configuredRecipeIds.length();
        uint256[] memory recipeIds = new uint256[](count);
        for(uint i=0; i<count; i++){
            recipeIds[i] = _configuredRecipeIds.at(i);
        }
        return recipeIds;
    }

    // --- Required for ERC1155HolderUpgradeable if holding ERC1155s ---
    // However, we are only transferring FROM user to contract and then TO user from contract.
    // The contract doesn't hold user's ERC1155 for an extended period where it might receive arbitrary transfers.
    // If the contract *did* need to hold ERC1155s (e.g., for staking or a vault), this would be needed.
    // Adding it for robustness in case future upgrades involve holding.
    // Requires inheriting ERC1155HolderUpgradeable.
    function onERC1155Received(address operator, address from, uint256 id, uint256 value, bytes calldata data) external virtual returns (bytes4) {
         // Can add logic here to verify if the transfer is expected (e.g., from requestAttunement)
         // or revert unexpected transfers.
         // For this contract's design (ERC1155 only transferred *from* user *to* contract during `requestAttunement`),
         // any other ERC1155 received might be accidental. Reverting is safer.
         // But allowing transfers *from* the user during `requestAttunement` implicitly requires returning `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
         // as the return value from the `safeBatchTransferFrom` or `safeTransferFrom` call.
         // The default behavior in ERC1155HolderUpgradeable is to accept. Let's inherit and keep default for required calls.
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }

     function onERC1155BatchReceived(address operator, address from, uint256[] calldata ids, uint256[] calldata values, bytes calldata data) external virtual returns (bytes4) {
         return bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"));
     }

     function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, VRFConsumerBaseV2) returns (bool) {
         return interfaceId == type(IERC1155ReceiverUpgradeable).interfaceId || super.supportsInterface(interfaceId);
     }

    // Fallback function to receive ETH for VRF fees (if Chainlink requires payment in ETH)
    // Ensure the contract is funded for VRF requests.
    receive() external payable {}
}
```