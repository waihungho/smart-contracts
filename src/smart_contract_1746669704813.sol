Okay, here is a Solidity smart contract concept for a "Quantum Lootbox" system. It aims for complexity, dynamism, and features beyond a standard lootbox, incorporating concepts like dynamic probabilities, staking influence, item fusion, and reliance on a provable randomness oracle.

It assumes the existence of separate ERC721 contracts for the Lootboxes themselves and the potential Items within them. The `QuantumLootbox` contract orchestrates the minting, burning, and transferring of these NFTs based on game mechanics and randomness.

**Disclaimer:** This is a complex contract concept. It is provided for educational and creative purposes. Implementing such a contract for production requires rigorous testing, security audits, and careful consideration of gas costs, economic models, and potential exploits. Chainlink VRF integration requires setting up a Chainlink node or using their service, paying LINK tokens, and funding the contract with LINK and native currency.

---

## QuantumLootbox Smart Contract

**Concept:** A dynamic lootbox system where the probability of receiving different items changes based on global factors (set by admin or potentially oracle) and user staking activity. Users can buy lootbox NFTs, open them using provable randomness (Chainlink VRF) to receive item NFTs, or fuse item NFTs to potentially create higher-tier items.

**Key Features:**

*   **Dynamic Probabilities:** Item drop rates within lootboxes are not fixed but influenced by a global modifier and user-specific staking boosts.
*   **Provable Randomness:** Uses Chainlink VRF v2 to ensure fair and tamper-proof outcomes for lootbox openings and item fusion.
*   **Item & Lootbox NFTs:** Manages separate ERC721 contracts for the lootboxes users own and the items they receive.
*   **Item Tiers & Pools:** Defines different tiers of items (Common, Rare, Epic, etc.) and manages pools of pre-minted or mintable items associated with those tiers.
*   **Lootbox Types:** Defines different types of lootboxes (Bronze, Silver, Gold) with varying costs and potential item tier distributions.
*   **Staking Boost:** Users can stake a designated ERC20 token to temporarily increase their probability of receiving rarer items.
*   **Item Fusion:** Users can burn multiple lower-tier items to attempt to fuse them into a higher-tier item (probabilistic outcome via VRF).
*   **Admin Controls:** Owner can define tiers, lootbox types, adjust base probabilities, set global modifiers, manage item pools, and withdraw funds/stuck items.
*   **Pausable:** Emergency pause functionality.

**Interfaces:**

*   `IERC721`: For interacting with Lootbox and Item NFT contracts.
*   `IERC20`: For the staking token.
*   `VRFConsumerBaseV2`: For Chainlink VRF integration.

**Dependencies:**

*   OpenZeppelin Contracts (Ownable, ERC721, SafeTransferLib) - Assumed for structure, but custom code is written.
*   Chainlink VRF v2 (VRFConsumerBaseV2, LINK token, VRF Coordinator).

**Outline:**

1.  **State Variables:** Define structs for ItemTiers, LootboxTypes, VRF request tracking. Define mappings for configuration, item pools, staking data. Define global modifiers, VRF parameters, contract addresses (NFTs, Staking Token, VRF Coordinator, LINK).
2.  **Events:** Define events for key actions (LootboxBought, LootboxOpened, ItemAwarded, ItemsFused, Staked, ProbabilityModifierUpdated, etc.).
3.  **Modifiers:** `onlyOwner`, `whenNotPaused`, `onlyVRF`.
4.  **Constructor:** Set up owner, VRF parameters, contract addresses.
5.  **Admin Functions (`onlyOwner`):**
    *   `defineItemTier`: Configure properties of an item tier.
    *   `defineLootboxType`: Configure properties of a lootbox type.
    *   `addItemToTierPool`: Add a specific item NFT (pre-minted and owned by contract) to a tier's pool.
    *   `removeItemFromTierPool`: Remove an item from a tier's pool (transfers back to owner?).
    *   `setTierProbabilityForLootboxType`: Adjust the base probability weight of an item tier within a specific lootbox type.
    *   `setGlobalProbabilityModifier`: Update the global factor affecting all probabilities.
    *   `setMinStakingBoost`, `setMaxStakingBoost`, `setStakingRequirement`, `setStakingDuration`: Configure staking parameters.
    *   `setFusionParameters`: Define which item tiers can be fused and the potential outcome tiers/probabilities.
    *   `withdrawFunds`: Withdraw native currency from lootbox sales.
    *   `withdrawERC721Item`: Withdraw a specific NFT owned by the contract (for stuck items etc.).
    *   `pauseContract`, `unpauseContract`.
    *   `setLootboxNFTContract`, `setItemNFTContract`, `setStakingTokenContract`.
6.  **User Functions:**
    *   `buyLootbox`: Pay native currency to mint/receive a lootbox NFT of a specific type.
    *   `openLootboxRequest`: Request VRF randomness to open a specified lootbox NFT (burns lootbox, triggers VRF).
    *   `stakeForProbabilityBoost`: Stake ERC20 tokens to gain a temporary probability boost.
    *   `withdrawStakedTokens`: Withdraw previously staked tokens after the staking period ends.
    *   `fuseItemsRequest`: Request VRF randomness to fuse specified item NFTs (burns source items, triggers VRF).
7.  **VRF Callback Function (`rawFulfillRandomWords`):**
    *   Triggered by Chainlink VRF.
    *   Determine the type of request (open lootbox or fuse items).
    *   Retrieve stored request details.
    *   Perform random number processing based on request type.
    *   **For Open Lootbox:**
        *   Calculate dynamic probabilities based on global modifier and user staking boost.
        *   Select item tier using random word and probability wheel.
        *   Select a specific item from the chosen tier's pool using another random word.
        *   Transfer awarded item NFT to user.
        *   Burn the lootbox NFT.
    *   **For Fuse Items:**
        *   Calculate probabilistic outcome based on fusion parameters and random word.
        *   If successful, select/mint/transfer the resulting item NFT.
        *   If failed, potentially handle failure (e.g., no item awarded, small consolation?).
    *   Clean up VRF request state.
8.  **Internal/Helper Functions:**
    *   `_calculateDynamicProbabilities`: Computes weighted probabilities considering base weights, global modifier, and user boost.
    *   `_selectItemFromTier`: Selects an item ID from a tier's pool based on random number.
    *   `_requestRandomWords`: Handles calling the VRF Coordinator.
    *   `_transferItem`: Safely transfers an item NFT.
    *   `_burnLootbox`: Burns a lootbox NFT.
    *   `_mintLootbox`: Mints a lootbox NFT.
9.  **View Functions:**
    *   `getLootboxTypeDetails`: Get configuration for a specific lootbox type.
    *   `getItemTierDetails`: Get configuration for a specific item tier.
    *   `getItemPoolItems`: Get the list of item IDs available in a specific tier's pool.
    *   `getGlobalProbabilityModifier`: Get the current global modifier value.
    *   `getStakingDetails`: Get staking configuration parameters.
    *   `getUserStakingInfo`: Get a user's current staking amount and boost details.
    *   `getFusionParameters`: Get configuration for item fusion.
    *   `getLootboxDynamicProbabilities`: *Simulate* the dynamic probabilities for a specific lootbox type for a specific user *without* opening it.
    *   `getVRFRequestStatus`: Check the status of a VRF request.
    *   `supportsInterface` (ERC165 for VRFConsumerBaseV2).
    *   `onERC721Received` (Needed if the contract receives items into its pool).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol"; // To receive items for pooling
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@chainlink/contracts/src/v0.8/vrf/V2/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";
import "@openzeppelin/contracts/token/ERC721/utils/SafeERC721.sol";


/**
 * @title QuantumLootbox
 * @dev A dynamic, probabilistic lootbox and item fusion system powered by Chainlink VRF.
 *      Manages separate ERC721 contracts for Lootboxes and Items.
 *      Probabilities are influenced by global factors and user staking.
 */
contract QuantumLootbox is Ownable, ReentrancyGuard, VRFConsumerBaseV2, ERC721Holder {
    using SafeERC721 for IERC721;
    using Counters for Counters.Counter;

    // --- State Variables ---

    IERC721 public lootboxNFT; // Address of the Lootbox ERC721 contract
    IERC721 public itemNFT;    // Address of the Item ERC721 contract
    IERC20 public stakingToken; // Address of the ERC20 token used for staking boost

    // Chainlink VRF V2 parameters
    address public vrfCoordinator;
    uint64 public s_subscriptionId;
    bytes32 public s_keyHash;
    uint32 public s_callbackGasLimit;
    uint16 public s_requestConfirmations;
    uint32 public s_numWords;

    // State to track VRF requests: requestId => Request details
    struct RequestDetails {
        address user;
        uint256 lootboxId; // Relevant for open lootbox requests
        uint256[] itemIdsToFuse; // Relevant for fuse item requests
        uint8 requestType; // 0: Open Lootbox, 1: Fuse Items
        bool fulfilled;
    }
    mapping(uint256 => RequestDetails) public s_requests;
    Counters.Counter private s_requestIdCounter;

    // --- Item Tier Configuration ---
    struct ItemTier {
        string name; // e.g., "Common", "Rare", "Epic"
        uint256 baseProbabilityWeight; // Relative weight for selection (out of total weights for a lootbox type)
        uint256 minPotentialValue; // Optional: for display/prediction
        uint256 maxPotentialValue; // Optional: for display/prediction
        uint256 fusionInputTierId; // If this tier can be an input for fusion, this is the resulting tier ID
        uint256 fusionInputQuantity; // Quantity of this tier required for fusion
    }
    mapping(uint256 => ItemTier) public itemTiers; // tierId => ItemTier
    Counters.Counter private nextItemTierId;

    // Pool of actual item NFT token IDs available for distribution for each tier
    // Contract must own these NFTs before they can be added to the pool.
    mapping(uint256 => uint256[]) public itemTierPool; // tierId => list of item NFT token IDs

    // --- Lootbox Type Configuration ---
    struct LootboxType {
        string name; // e.g., "Bronze Crate", "Silver Chest"
        uint256 cost; // Cost in native currency (e.g., Wei)
        uint256 baseWeight; // Relative weight for random lootbox drops/mints (if applicable)
        // Probability weights for item tiers *within* this lootbox type (overrides tier's baseWeight if set)
        mapping(uint256 => uint256) itemTierWeights; // tierId => weight
        uint256 totalTierWeights; // Sum of itemTierWeights for this lootbox type
    }
    mapping(uint256 => LootboxType) public lootboxTypes; // lootboxTypeId => LootboxType
    Counters.Counter private nextLootboxTypeId;

    // --- Dynamic Probability Factors ---
    uint256 public globalProbabilityModifier = 100; // Base 100 = 100%, 110 = 110%, 90 = 90% etc. Affects all probabilities.
    uint256 public minProbabilityModifier = 50; // Minimum global modifier
    uint256 public maxProbabilityModifier = 200; // Maximum global modifier

    // --- Staking Configuration & State ---
    uint256 public stakingRequirement; // Amount of stakingToken required for boost
    uint256 public minStakingBoost = 105; // Minimum boost percentage (e.g., 105 = +5% effective probability)
    uint256 public maxStakingBoost = 150; // Maximum boost percentage (e.g., 150 = +50% effective probability)
    uint256 public stakingDuration = 30 days; // Duration of the staking boost in seconds

    struct UserStakingInfo {
        uint256 amountStaked;
        uint256 boostEndTime;
    }
    mapping(address => UserStakingInfo) public userStaking;

    // --- Item Fusion Configuration ---
    struct FusionOutcome {
        uint256 resultTierId; // The tier ID of the potential output item
        uint256 probabilityWeight; // Relative weight for this specific outcome (out of total outcome weights for this fusion)
    }
    // Fusion requires N items of tier A to attempt creating 1 item of tier B or C etc.
    // Key: inputTierId => PossibleOutcome[]
    mapping(uint256 => FusionOutcome[]) public fusionPossibleOutcomes; // Mapping input tier ID to possible outcomes

    // --- Pausability ---
    bool public paused = false;

    // --- Events ---
    event LootboxBought(address indexed buyer, uint256 lootboxTypeId, uint256 lootboxId, uint256 cost);
    event LootboxOpenRequested(address indexed user, uint256 lootboxId, uint256 requestId);
    event ItemAwarded(address indexed user, uint256 lootboxId, uint256 itemId, uint256 itemTierId); // item NFT token ID awarded
    event ItemsFusionRequested(address indexed user, uint256[] itemIdsBurned, uint256 requestId);
    event ItemsFused(address indexed user, uint256[] itemIdsBurned, uint256 resultItemId, uint256 resultTierId); // result item NFT token ID
    event FusionFailed(address indexed user, uint256[] itemIdsBurned);
    event Staked(address indexed user, uint256 amount, uint256 boostEndTime);
    event Unstaked(address indexed user, uint256 amount);
    event GlobalProbabilityModifierUpdated(uint255 oldModifier, uint255 newModifier);
    event ItemTierDefined(uint256 indexed tierId, string name, uint256 baseWeight);
    event LootboxTypeDefined(uint256 indexed typeId, string name, uint255 cost);
    event ItemAddedToPool(uint256 indexed tierId, uint256 indexed itemId);
    event ItemRemovedFromPool(uint256 indexed tierId, uint256 indexed itemId);
    event Paused(address account);
    event Unpaused(address account);
    event Withdraw(address indexed receiver, uint256 amount);
    event WithdrawERC721(address indexed receiver, address indexed tokenContract, uint256 indexed tokenId);


    // --- Constructor ---
    constructor(
        address _lootboxNFTAddress,
        address _itemNFTAddress,
        address _stakingTokenAddress,
        address _vrfCoordinator,
        bytes32 _keyHash,
        uint64 _subscriptionId,
        uint32 _callbackGasLimit,
        uint16 _requestConfirmations,
        uint32 _numWords
    ) VRFConsumerBaseV2(_vrfCoordinator) Ownable(msg.sender) {
        require(_lootboxNFTAddress != address(0), "Invalid lootbox NFT address");
        require(_itemNFTAddress != address(0), "Invalid item NFT address");
        require(_stakingTokenAddress != address(0), "Invalid staking token address");
        require(_vrfCoordinator != address(0), "Invalid VRF coordinator address");
        require(_keyHash != bytes32(0), "Invalid key hash");
        require(_subscriptionId > 0, "Invalid subscription ID");
        require(_callbackGasLimit > 0, "Callback gas limit must be > 0");
        require(_numWords > 0, "Number of words must be > 0");

        lootboxNFT = IERC721(_lootboxNFTAddress);
        itemNFT = IERC721(_itemNFTAddress);
        stakingToken = IERC20(_stakingTokenAddress);

        vrfCoordinator = _vrfCoordinator;
        s_keyHash = _keyHash;
        s_subscriptionId = _subscriptionId;
        s_callbackGasLimit = _callbackGasLimit;
        s_requestConfirmations = _requestConfirmations;
        s_numWords = _numWords;

        // Set initial default staking config (can be updated by owner)
        stakingRequirement = 100e18; // Example: 100 staking tokens
    }

    // --- Modifiers ---

    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    modifier onlyVRF() {
        require(msg.sender == vrfCoordinator, "Only VRF Coordinator can call this");
        _;
    }

    // --- Admin Functions (onlyOwner) ---

    /**
     * @dev Defines a new item tier.
     * @param _name Name of the tier (e.g., "Common").
     * @param _baseProbabilityWeight Base weight for probability calculation.
     * @param _minPotentialValue Optional display value.
     * @param _maxPotentialValue Optional display value.
     */
    function defineItemTier(
        string calldata _name,
        uint256 _baseProbabilityWeight,
        uint256 _minPotentialValue,
        uint256 _maxPotentialValue
    ) external onlyOwner {
        uint256 newTierId = nextItemTierId.current();
        itemTiers[newTierId] = ItemTier({
            name: _name,
            baseProbabilityWeight: _baseProbabilityWeight,
            minPotentialValue: _minPotentialValue,
            maxPotentialValue: _maxPotentialValue,
            fusionInputTierId: 0, // Default: not an input tier
            fusionInputQuantity: 0 // Default: not an input tier
        });
        nextItemTierId.increment();
        emit ItemTierDefined(newTierId, _name, _baseProbabilityWeight);
    }

    /**
     * @dev Defines a new lootbox type.
     * @param _name Name of the lootbox type (e.g., "Bronze Crate").
     * @param _cost Cost to buy in native currency (Wei).
     * @param _baseWeight Base weight for random lootbox drops/mints (if used elsewhere).
     * @param _tierWeights Array of [tierId, weight] pairs for probabilities within this box.
     */
    function defineLootboxType(
        string calldata _name,
        uint256 _cost,
        uint256 _baseWeight,
        uint256[] calldata _tierWeights // [tierId1, weight1, tierId2, weight2, ...]
    ) external onlyOwner {
        require(_tierWeights.length % 2 == 0, "Invalid tierWeights format");
        uint256 newTypeId = nextLootboxTypeId.current();
        LootboxType storage newLootboxType = lootboxTypes[newTypeId];
        newLootboxType.name = _name;
        newLootboxType.cost = _cost;
        newLootboxType.baseWeight = _baseWeight;
        newLootboxType.totalTierWeights = 0;

        for (uint i = 0; i < _tierWeights.length; i += 2) {
            uint256 tierId = _tierWeights[i];
            uint256 weight = _tierWeights[i + 1];
            require(itemTiers[tierId].baseProbabilityWeight > 0 || tierId == 0, "Invalid tierId in weights"); // tierId 0 could be "empty"
            newLootboxType.itemTierWeights[tierId] = weight;
            newLootboxType.totalTierWeights += weight;
        }
        require(newLootboxType.totalTierWeights > 0, "Lootbox must have at least one tier weight");

        nextLootboxTypeId.increment();
        emit LootboxTypeDefined(newTypeId, _name, _cost);
    }

    /**
     * @dev Sets/updates the probability weight for a specific item tier within a lootbox type.
     *      Total weight for the lootbox type is updated automatically.
     * @param _lootboxTypeId The ID of the lootbox type.
     * @param _tierId The ID of the item tier.
     * @param _weight The new weight for this tier in this lootbox type.
     */
    function setTierProbabilityForLootboxType(
        uint256 _lootboxTypeId,
        uint256 _tierId,
        uint256 _weight
    ) external onlyOwner {
        LootboxType storage lbType = lootboxTypes[_lootboxTypeId];
        require(lbType.totalTierWeights > 0, "Lootbox type not defined"); // Using totalTierWeights as existence check
        require(itemTiers[_tierId].baseProbabilityWeight > 0 || _tierId == 0, "Invalid tierId"); // tierId 0 could be "empty"

        uint256 oldWeight = lbType.itemTierWeights[_tierId];
        lbType.itemTierWeights[_tierId] = _weight;
        lbType.totalTierWeights = lbType.totalTierWeights - oldWeight + _weight;
        require(lbType.totalTierWeights > 0, "Lootbox must have at least one tier weight"); // Ensure total remains > 0
    }


    /**
     * @dev Adds a specific item NFT (must be owned by this contract) to a tier's pool.
     *      Contract must receive the NFT *before* this function is called or during with a hook.
     * @param _tierId The ID of the item tier.
     * @param _itemId The token ID of the item NFT to add.
     */
    function addItemToTierPool(uint256 _tierId, uint256 _itemId) external onlyOwner {
        require(itemTiers[_tierId].baseProbabilityWeight > 0, "Invalid tierId");
        require(itemNFT.ownerOf(_itemId) == address(this), "Contract must own the item");

        // Prevent adding the same item twice
        bool found = false;
        for(uint i=0; i<itemTierPool[_tierId].length; i++) {
            if (itemTierPool[_tierId][i] == _itemId) {
                found = true;
                break;
            }
        }
        require(!found, "Item already in pool");

        itemTierPool[_tierId].push(_itemId);
        emit ItemAddedToPool(_tierId, _itemId);
    }

    /**
     * @dev Removes a specific item NFT from a tier's pool and transfers it to the owner.
     * @param _tierId The ID of the item tier.
     * @param _itemId The token ID of the item NFT to remove.
     */
    function removeItemFromTierPool(uint256 _tierId, uint256 _itemId) external onlyOwner nonReentrant {
        require(itemTiers[_tierId].baseProbabilityWeight > 0, "Invalid tierId");

        bool found = false;
        uint256 index = 0;
        for(uint i=0; i<itemTierPool[_tierId].length; i++) {
            if (itemTierPool[_tierId][i] == _itemId) {
                found = true;
                index = i;
                break;
            }
        }
        require(found, "Item not found in tier pool");

        // Remove item from the array by swapping with last and popping
        itemTierPool[_tierId][index] = itemTierPool[_tierId][itemTierPool[_tierId].length - 1];
        itemTierPool[_tierId].pop();

        // Transfer the item back to the owner
        itemNFT.safeTransferFrom(address(this), owner(), _itemId);
        emit ItemRemovedFromPool(_tierId, _itemId);
    }

    /**
     * @dev Sets the global probability modifier.
     * @param _modifier New modifier value (100 = 100%).
     */
    function setGlobalProbabilityModifier(uint256 _modifier) external onlyOwner {
        require(_modifier >= minProbabilityModifier && _modifier <= maxProbabilityModifier, "Modifier out of bounds");
        emit GlobalProbabilityModifierUpdated(globalProbabilityModifier, _modifier);
        globalProbabilityModifier = _modifier;
    }

    /**
     * @dev Sets the min/max bounds for the global probability modifier.
     */
    function setMinMaxProbabilities(uint256 _min, uint256 _max) external onlyOwner {
        require(_min <= 100 && _max >= 100 && _min < _max, "Invalid min/max bounds");
        minProbabilityModifier = _min;
        maxProbabilityModifier = _max;
    }

    /**
     * @dev Configures staking parameters.
     */
    function setStakingParameters(uint256 _requirement, uint256 _minBoost, uint256 _maxBoost, uint256 _duration) external onlyOwner {
        require(_requirement > 0, "Staking requirement must be > 0");
        require(_minBoost >= 100 && _maxBoost >= _minBoost, "Invalid boost values");
        require(_duration > 0, "Duration must be > 0");
        stakingRequirement = _requirement;
        minStakingBoost = _minBoost;
        maxStakingBoost = _maxBoost;
        stakingDuration = _duration;
    }

    /**
     * @dev Configures possible outcomes for item fusion from a given input tier.
     * @param _inputTierId The tier ID required for fusion input. Must be defined with fusion properties first.
     * @param _outcomeTierIds Array of potential resulting tier IDs.
     * @param _outcomeWeights Array of weights for each outcome tier. Must match _outcomeTierIds length.
     */
    function setFusionParameters(uint256 _inputTierId, uint256[] calldata _outcomeTierIds, uint256[] calldata _outcomeWeights) external onlyOwner {
        require(itemTiers[_inputTierId].fusionInputQuantity > 0, "Input tier not configured for fusion");
        require(_outcomeTierIds.length > 0 && _outcomeTierIds.length == _outcomeWeights.length, "Invalid outcomes");

        delete fusionPossibleOutcomes[_inputTierId]; // Clear previous outcomes
        for (uint i = 0; i < _outcomeTierIds.length; i++) {
            uint256 resultTierId = _outcomeTierIds[i];
            uint256 weight = _outcomeWeights[i];
             require(itemTiers[resultTierId].baseProbabilityWeight > 0 || resultTierId == 0, "Invalid result tierId in outcomes"); // resultTierId 0 could mean "fusion failed, no item"
            fusionPossibleOutcomes[_inputTierId].push(FusionOutcome({
                resultTierId: resultTierId,
                probabilityWeight: weight
            }));
        }
    }

    /**
     * @dev Configures an item tier to be a potential input for fusion.
     * @param _tierId The ID of the item tier.
     * @param _fusionResultTierId The tier ID that *could* result from fusing this tier.
     * @param _quantityRequired The number of items of this tier required for fusion.
     */
    function configureTierAsFusionInput(uint256 _tierId, uint256 _fusionResultTierId, uint256 _quantityRequired) external onlyOwner {
        require(itemTiers[_tierId].baseProbabilityWeight > 0, "Invalid tierId");
        require(itemTiers[_fusionResultTierId].baseProbabilityWeight > 0, "Invalid result tierId");
         require(_quantityRequired > 0, "Quantity required must be > 0");

        ItemTier storage tier = itemTiers[_tierId];
        tier.fusionInputTierId = _fusionResultTierId; // Note: This is a bit simplified. Maybe better just to store quantity and let setFusionParameters define results. Let's stick to simplified for now. The `setFusionParameters` approach is more flexible. So this function only sets quantity required.
         tier.fusionInputQuantity = _quantityRequired;
    }


    /**
     * @dev Withdraws native currency from the contract.
     * @param _to Address to send the funds to.
     */
    function withdrawFunds(address payable _to) external onlyOwner nonReentrant {
        require(_to != address(0), "Invalid address");
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        (bool success, ) = _to.call{value: balance}("");
        require(success, "Withdraw failed");
        emit Withdraw(_to, balance);
    }

    /**
     * @dev Withdraws a specific ERC721 token owned by the contract.
     *      Useful for stuck tokens or removing items from pools manually.
     * @param _tokenContract Address of the ERC721 contract.
     * @param _tokenId Token ID to withdraw.
     * @param _to Address to send the token to.
     */
    function withdrawERC721Item(address _tokenContract, uint256 _tokenId, address _to) external onlyOwner nonReentrant {
        require(_tokenContract != address(0), "Invalid token address");
        require(_to != address(0), "Invalid recipient address");
        IERC721 token = IERC721(_tokenContract);
        require(token.ownerOf(_tokenId) == address(this), "Contract does not own the token");
        token.safeTransferFrom(address(this), _to, _tokenId);
        emit WithdrawERC721(_to, _tokenContract, _tokenId);
    }

    /**
     * @dev Pauses the contract. Only owner can call.
     */
    function pauseContract() external onlyOwner whenNotPaused {
        paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Unpauses the contract. Only owner can call.
     */
    function unpauseContract() external onlyOwner {
        require(paused, "Contract is not paused");
        paused = false;
        emit Unpaused(msg.sender);
    }


    // --- User Functions ---

    /**
     * @dev Buys a lootbox NFT of a specified type.
     *      Mints a new lootbox NFT and transfers it to the buyer.
     * @param _lootboxTypeId The ID of the lootbox type to buy.
     */
    function buyLootbox(uint256 _lootboxTypeId) external payable whenNotPaused nonReentrant {
        LootboxType storage lbType = lootboxTypes[_lootboxTypeId];
        require(lbType.totalTierWeights > 0, "Lootbox type not defined"); // Using totalTierWeights as existence check
        require(msg.value >= lbType.cost, "Insufficient funds");

        // Calculate refund if overpaid
        if (msg.value > lbType.cost) {
            uint256 refund = msg.value - lbType.cost;
            (bool success, ) = payable(msg.sender).call{value: refund}("");
            require(success, "Refund failed");
        }

        // Mint a new lootbox NFT and transfer it to the buyer
        // Assumes lootboxNFT contract has a function like mint(address to) or mint(address to, uint256 typeId)
        // For this example, let's assume it has a general mint function and we associate type data off-chain or in a separate mapping.
        // A better way would be to pass typeId to mint if the Lootbox NFT contract supports it.
        // For simplicity here, we'll assume a basic mint and track type here.
        // uint256 newLootboxId = lootboxNFT.totalSupply() + 1; // Example logic, depends on NFT contract
        // lootboxNFT.mint(msg.sender, newLootboxId); // Example mint call (needs to exist on lootboxNFT contract)
        // A more standard ERC721 doesn't have public mint. Owner usually mints or specific minter role.
        // Let's assume the `lootboxNFT` contract has an `ownerMint` function callable by this contract's address.
        uint256 newLootboxId = _mintLootbox(msg.sender, _lootboxTypeId);


        emit LootboxBought(msg.sender, _lootboxTypeId, newLootboxId, lbType.cost);
    }

    /**
     * @dev Requests VRF randomness to open a specific lootbox NFT.
     *      Burns the lootbox NFT and initiates the VRF process.
     *      The item is awarded in the `rawFulfillRandomWords` callback.
     * @param _lootboxId The token ID of the lootbox NFT to open.
     */
    function openLootboxRequest(uint256 _lootboxId) external whenNotPaused nonReentrant {
        require(lootboxNFT.ownerOf(_lootboxId) == msg.sender, "Not your lootbox");

        // Get lootbox type information (assuming it's stored/retrievable, e.g., via metadata or a mapping here)
        // For this example, let's assume a mapping: lootboxId -> lootboxTypeId
        uint256 lootboxTypeId = _getLootboxTypeId(_lootboxId); // Needs implementation or metadata lookup
        LootboxType storage lbType = lootboxTypes[lootboxTypeId];
        require(lbType.totalTierWeights > 0, "Lootbox type not defined for this ID");

        // Burn the lootbox NFT
        _burnLootbox(_lootboxId);

        // Request randomness from VRF Coordinator
        uint256 requestId = _requestRandomWords(0, msg.sender, _lootboxId, new uint256[](0));

        emit LootboxOpenRequested(msg.sender, _lootboxId, requestId);
    }

    /**
     * @dev Stakes ERC20 tokens to gain a probability boost.
     * @param _amount The amount of staking tokens to stake.
     */
    function stakeForProbabilityBoost(uint256 _amount) external whenNotPaused nonReentrant {
        require(_amount > 0, "Amount must be > 0");
        require(_amount >= stakingRequirement, "Amount below minimum staking requirement");
        require(stakingToken.transferFrom(msg.sender, address(this), _amount), "Token transfer failed");

        UserStakingInfo storage stakingInfo = userStaking[msg.sender];
        uint256 currentStaked = stakingInfo.amountStaked;
        uint256 currentEndTime = stakingInfo.boostEndTime;

        // If user already staking, add to amount and extend/set end time
        if (currentStaked > 0 && block.timestamp < currentEndTime) {
             stakingInfo.amountStaked = currentStaked + _amount;
             stakingInfo.boostEndTime = currentEndTime + stakingDuration; // Add duration to existing end time
        } else {
            // New stake or existing stake period ended
            stakingInfo.amountStaked = _amount;
            stakingInfo.boostEndTime = block.timestamp + stakingDuration;
        }


        emit Staked(msg.sender, _amount, stakingInfo.boostEndTime);
    }

    /**
     * @dev Withdraws staked tokens.
     *      Can only be withdrawn after the staking boost period has ended.
     */
    function withdrawStakedTokens() external whenNotPaused nonReentrant {
        UserStakingInfo storage stakingInfo = userStaking[msg.sender];
        uint256 amount = stakingInfo.amountStaked;
        require(amount > 0, "No tokens staked");
        require(block.timestamp >= stakingInfo.boostEndTime, "Staking boost period is not over");

        stakingInfo.amountStaked = 0; // Reset state BEFORE transfer
        stakingInfo.boostEndTime = 0;

        require(stakingToken.transfer(msg.sender, amount), "Token withdrawal failed");
        emit Unstaked(msg.sender, amount);
    }

    /**
     * @dev Requests VRF randomness to attempt fusing multiple items into potentially a higher tier one.
     *      Burns the input items and initiates the VRF process for the outcome.
     * @param _itemIdsToFuse Array of token IDs of the item NFTs to fuse. Must all be the same tier.
     */
    function fuseItemsRequest(uint256[] calldata _itemIdsToFuse) external whenNotPaused nonReentrant {
        require(_itemIdsToFuse.length > 0, "No items provided for fusion");

        uint256 firstItemId = _itemIdsToFuse[0];
        uint256 inputTierId = _getItemTierId(firstItemId); // Needs implementation or metadata lookup
        require(inputTierId > 0, "Invalid input item tier");

        ItemTier storage inputTier = itemTiers[inputTierId];
        require(inputTier.fusionInputQuantity > 0, "This item tier cannot be used for fusion input");
        require(_itemIdsToFuse.length == inputTier.fusionInputQuantity, "Incorrect number of items for this fusion");

        // Check ownership and burn items
        for (uint i = 0; i < _itemIdsToFuse.length; i++) {
            uint256 itemId = _itemIdsToFuse[i];
             // Ensure all items are of the correct input tier
            require(_getItemTierId(itemId) == inputTierId, "All items must be of the same fusion input tier");
            require(itemNFT.ownerOf(itemId) == msg.sender, "Not your item to fuse");
            // Burn the item
            itemNFT.burn(itemId); // Assumes itemNFT contract supports burn
        }

        // Request randomness for fusion outcome
        uint256 requestId = _requestRandomWords(1, msg.sender, 0, _itemIdsToFuse);

        emit ItemsFusionRequested(msg.sender, _itemIdsToFuse, requestId);
    }


    // --- VRF Callback Function ---

    /**
     * @dev Callback function for Chainlink VRF V2. Receives random words.
     *      Called by the VRF Coordinator contract after a request is fulfilled.
     * @param requestId The ID of the VRF request.
     * @param randomWords Array of random uint256 words.
     */
    function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override onlyVRF {
        require(randomWords.length > 0, "No random words received");

        RequestDetails storage request = s_requests[requestId];
        require(!request.fulfilled, "Request already fulfilled");
        require(request.user != address(0), "Unknown request ID"); // Check if request exists

        request.fulfilled = true; // Mark as fulfilled

        uint256 randomness = randomWords[0]; // Use the first random word

        if (request.requestType == 0) { // Open Lootbox Request
            uint256 lootboxId = request.lootboxId;
            address user = request.user;

            uint256 lootboxTypeId = _getLootboxTypeId(lootboxId); // Retrieve lootbox type
            LootboxType storage lbType = lootboxTypes[lootboxTypeId];

            // Calculate dynamic probabilities
            (uint256[] memory tierIds, uint256[] memory cumulativeWeights) = _calculateDynamicProbabilities(user, lootboxTypeId);
            uint256 totalWeight = cumulativeWeights[cumulativeWeights.length - 1];

            // Select item tier based on randomness
            uint256 selectedTierId = 0; // Default: no item awarded (e.g., if total weight is 0)
            uint256 randomNumberInWeightRange = randomness % totalWeight;

            for (uint i = 0; i < cumulativeWeights.length; i++) {
                if (randomNumberInWeightRange < cumulativeWeights[i]) {
                    selectedTierId = tierIds[i];
                    break;
                }
            }

            // Select a specific item from the tier's pool
            uint256 awardedItemId = 0;
            if (selectedTierId > 0) { // If a valid tier was selected
                 // Use another random word or derive from the first one for item selection within tier
                 uint256 itemSelectionRandomness = randomWords.length > 1 ? randomWords[1] : randomness / totalWeight; // Use second word if available, or derive

                uint256[] storage tierPool = itemTierPool[selectedTierId];
                if (tierPool.length > 0) {
                    uint256 poolIndex = itemSelectionRandomness % tierPool.length;
                    awardedItemId = tierPool[poolIndex];

                    // Transfer the awarded item NFT to the user
                    itemNFT.safeTransferFrom(address(this), user, awardedItemId);

                    // Remove the item from the pool (it's now owned by the user)
                    // This is a simplified pool management. A real system might mint new items or have replenish mechanisms.
                    // Remove by swapping with last and popping.
                    if (tierPool.length > 1) {
                         tierPool[poolIndex] = tierPool[tierPool.length - 1];
                    }
                    tierPool.pop();

                    emit ItemAwarded(user, lootboxId, awardedItemId, selectedTierId);
                } else {
                    // Tier selected but pool is empty - this indicates a configuration issue or pool depletion
                    // Consider emitting a warning event or awarding a fallback item/value
                     emit ItemAwarded(user, lootboxId, 0, selectedTierId); // Award item ID 0 to signify pool empty
                }
            } else {
                // No tier selected (e.g., random number fell outside any weighted range due to rounding or config)
                 emit ItemAwarded(user, lootboxId, 0, 0); // Award item ID 0 and tier 0
            }


        } else if (request.requestType == 1) { // Fuse Items Request
            address user = request.user;
            uint256[] memory itemIdsBurned = request.itemIdsToFuse;
            uint256 inputTierId = _getItemTierId(itemIdsBurned[0]); // All burned items are same tier

            FusionOutcome[] storage outcomes = fusionPossibleOutcomes[inputTierId];
            uint256 totalOutcomeWeight = 0;
            for(uint i=0; i < outcomes.length; i++) {
                totalOutcomeWeight += outcomes[i].probabilityWeight;
            }

             uint256 resultTierId = 0; // Default: Fusion Failed
             if(totalOutcomeWeight > 0) {
                uint256 randomNumberInWeightRange = randomness % totalOutcomeWeight;
                 uint256 cumulativeOutcomeWeight = 0;
                 for(uint i=0; i < outcomes.length; i++) {
                     cumulativeOutcomeWeight += outcomes[i].probabilityWeight;
                     if (randomNumberInWeightRange < cumulativeOutcomeWeight) {
                        resultTierId = outcomes[i].resultTierId;
                        break;
                     }
                 }
             }

             uint256 resultItemId = 0;
             if (resultTierId > 0) { // If fusion was successful and resulted in a tier
                 // Select a specific item from the result tier's pool (or mint a new one)
                 // This logic is similar to item awarding from lootbox
                  uint256 itemSelectionRandomness = randomWords.length > 1 ? randomWords[1] : randomness / totalOutcomeWeight;

                uint256[] storage tierPool = itemTierPool[resultTierId];
                 if (tierPool.length > 0) {
                    uint256 poolIndex = itemSelectionRandomness % tierPool.length;
                    resultItemId = tierPool[poolIndex];

                    // Transfer the result item NFT to the user
                    itemNFT.safeTransferFrom(address(this), user, resultItemId);

                    // Remove the item from the pool
                    if (tierPool.length > 1) {
                         tierPool[poolIndex] = tierPool[tierPool.length - 1];
                    }
                    tierPool.pop();

                    emit ItemsFused(user, itemIdsBurned, resultItemId, resultTierId);
                 } else {
                    // Result tier selected but pool empty - fusion failed implicitly due to lack of items
                    emit FusionFailed(user, itemIdsBurned); // Or a specific "FusionSucceededButPoolEmpty" event
                 }
             } else {
                 // Fusion failed (either total weight 0 or random number selected the 0 tier)
                 emit FusionFailed(user, itemIdsBurned);
             }

        }

        // Clean up request details after fulfillment (optional but good practice)
        // delete s_requests[requestId]; // Or mark as fulfilled and leave historical data
    }

    // --- Internal/Helper Functions ---

    /**
     * @dev Mints a new lootbox NFT and tracks its type.
     *      Assumes the lootboxNFT contract allows this contract to mint.
     * @param _to The recipient of the new lootbox NFT.
     * @param _lootboxTypeId The type of the lootbox being minted.
     * @return The token ID of the newly minted lootbox NFT.
     */
    function _mintLootbox(address _to, uint256 _lootboxTypeId) internal returns (uint256) {
        // This requires the lootboxNFT contract to have a public mint function or
        // this contract to have a minter role on the lootboxNFT contract.
        // Example assuming a simple mint:
        // uint256 newTokenId = lootboxNFT.totalSupply() + 1; // Simple, depends on NFT contract logic
        // lootboxNFT.mint(_to, newTokenId); // Assumes this method exists and is callable

        // More realistically, the lootboxNFT contract would have an `ownerMint` or `mintFor` function.
        // Let's assume a function `mintFor(address to, uint256 typeId)` exists on `lootboxNFT`.
        // The `typeId` might be stored within the NFT metadata or in a mapping here.
        // For this example, we'll track the typeId here. We still need a way to get the new ID.
        // A common pattern is for the minter contract (QuantumLootbox) to call `lootboxNFT.mint(to)`
        // and then the lootboxNFT contract emits a Transfer event which this contract could theoretically listen to (off-chain)
        // to get the new ID, or the mint function returns the ID. Let's assume it returns the ID.
        // Assumes a function `mintFor(address to)` that returns the new tokenId.
        uint256 newTokenId = lootboxNFT.mintFor(_to); // Assumes this function exists and returns tokenId
        _setLootboxTypeId(newTokenId, _lootboxTypeId); // Store the type locally if needed
        return newTokenId;
    }

     /**
     * @dev Burns a lootbox NFT.
     *      Assumes the lootboxNFT contract allows burning or has a burn function for the owner.
     * @param _lootboxId The token ID of the lootbox NFT to burn.
     */
    function _burnLootbox(uint256 _lootboxId) internal {
        // Assumes lootboxNFT contract has a burn function callable by this contract.
        // Could be `lootboxNFT.burn(_lootboxId)` or `lootboxNFT.ownerBurn(address(this), _lootboxId)`.
        lootboxNFT.burn(_lootboxId); // Assumes this function exists
        _removeLootboxTypeId(_lootboxId); // Clean up local type tracking
    }


    /**
     * @dev Stores the type ID for a given lootbox token ID.
     *      Needed if the lootbox NFT contract doesn't store type itself.
     */
    mapping(uint256 => uint256) private _lootboxIdToTypeId;
    function _setLootboxTypeId(uint256 _lootboxId, uint256 _typeId) internal {
        _lootboxIdToTypeId[_lootboxId] = _typeId;
    }
    function _getLootboxTypeId(uint256 _lootboxId) internal view returns (uint256) {
        return _lootboxIdToTypeId[_lootboxId];
    }
    function _removeLootboxTypeId(uint256 _lootboxId) internal {
        delete _lootboxIdToTypeId[_lootboxId];
    }

     /**
     * @dev Retrieves the tier ID for a given item token ID.
     *      Needed if the item NFT contract doesn't store tier itself.
     *      This is crucial for item fusion.
     *      Needs a mechanism to track which tier an item belongs to.
     *      Possibilities:
     *      1. Store in a mapping here (requires linking item ID to tier upon mint/addition to pool)
     *      2. Store in the Item NFT metadata/properties
     *      3. Have separate Item NFT contracts per tier (more complex setup)
     *      Let's assume a mapping for simplicity here.
     */
    mapping(uint256 => uint256) private _itemIdToTierId;
     function _setItemTierId(uint256 _itemId, uint256 _tierId) internal {
         _itemIdToTierId[_itemId] = _tierId;
     }
     function _getItemTierId(uint256 _itemId) internal view returns (uint256) {
         return _itemIdToTierId[_itemId];
     }


    /**
     * @dev Requests random words from the VRF Coordinator.
     * @param _requestType 0 for Open Lootbox, 1 for Fuse Items.
     * @param _user The user making the request.
     * @param _lootboxId The lootbox ID (if type 0).
     * @param _itemIdsToFuse The item IDs (if type 1).
     * @return requestId The Chainlink VRF request ID.
     */
    function _requestRandomWords(
        uint8 _requestType,
        address _user,
        uint256 _lootboxId,
        uint256[] memory _itemIdsToFuse
    ) internal returns (uint256 requestId) {
        // Need LINK token to pay for VRF request
        // Transfer LINK to VRF Coordinator if necessary (usually handled by Chainlink automation/keepers funding the subscription)
        // For testing, you might need to send LINK to this contract and call coordinator.transferAndCall or similar.
        // Using VRFConsumerBaseV2's requestRandomWords handles the LINK payment from the subscription.
        requestId = requestRandomWords(s_keyHash, s_subscriptionId, s_requestConfirmations, s_callbackGasLimit, s_numWords);

        // Store request details to process in the callback
        s_requests[requestId] = RequestDetails({
            user: _user,
            lootboxId: _lootboxId,
            itemIdsToFuse: _itemIdsToFuse,
            requestType: _requestType,
            fulfilled: false
        });
        s_requestIdCounter.increment();
    }

    /**
     * @dev Calculates dynamic probability weights for item tiers in a lootbox for a specific user.
     *      Considers base weights, global modifier, and user staking boost.
     *      Returns arrays of tier IDs and their cumulative weights for probabilistic selection.
     * @param _user The user requesting the probabilities.
     * @param _lootboxTypeId The ID of the lootbox type.
     * @return tierIds Array of tier IDs.
     * @return cumulativeWeights Array of cumulative weights corresponding to tierIds.
     */
    function _calculateDynamicProbabilities(address _user, uint256 _lootboxTypeId)
        internal view returns (uint256[] memory tierIds, uint256[] memory cumulativeWeights)
    {
        LootboxType storage lbType = lootboxTypes[_lootboxTypeId];
        require(lbType.totalTierWeights > 0, "Lootbox type weights not set");

        uint256 totalWeight = 0;
        uint256 itemCount = 0;

        // First pass to count valid tiers and sum weights
        for (uint256 i = 0; i < nextItemTierId.current(); i++) { // Iterate through all defined tiers
            uint256 baseWeight = lbType.itemTierWeights[i];
            // Check if the tier has a defined weight for this lootbox type AND if there are items available in the pool for this tier
            if (baseWeight > 0 && itemTierPool[i].length > 0) {
                 // Apply global modifier
                uint256 modifiedWeight = (baseWeight * globalProbabilityModifier) / 100;

                // Apply staking boost (only if user is actively staking and tier is "rare" or higher conceptually)
                // A more complex system would have boost apply differently per tier.
                // For simplicity: if user stakes, apply boost to non-common tiers (tierId > 0 assuming 0 is common or empty)
                uint256 stakingBoost = _getUserStakingBoost(_user);
                 if (stakingBoost > 100 && i > 0) { // Assuming tier 0 is common/empty, apply boost to others
                     modifiedWeight = (modifiedWeight * stakingBoost) / 100;
                 }

                totalWeight += modifiedWeight;
                itemCount++;
            } else if (i == 0 && baseWeight > 0) {
                // Handle tier 0 (e.g., "empty" or "common") separately if needed, without requiring pool items
                 // Or simply include it if its weight is > 0, without pool check if it's a "no item" outcome.
                 // Let's assume tier 0 means "no item" or a default common item that doesn't need pooling.
                 // If tier 0 is a default common item that needs a pool, the above `itemTierPool[i].length > 0` check is necessary.
                 // Let's assume for this example tier 0 is 'no item' or implicitly 'common' and has a base weight but no pool.
                 // In that case, its weight isn't affected by pool size or staking boost.
                 uint256 weight = lbType.itemTierWeights[i]; // Use base weight for tier 0
                 totalWeight += weight;
                 itemCount++;
            }
        }

        require(totalWeight > 0, "No possible items to drop from this lootbox");

        tierIds = new uint256[](itemCount);
        cumulativeWeights = new uint256[](itemCount);

        // Second pass to populate arrays with dynamic weights
        uint256 currentCumulativeWeight = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < nextItemTierId.current(); i++) { // Iterate through all defined tiers
            uint256 baseWeight = lbType.itemTierWeights[i];
             if (baseWeight > 0 && (i == 0 || itemTierPool[i].length > 0)) { // Include tier 0 or tiers with items in pool
                 uint256 modifiedWeight;
                 if (i == 0) {
                     modifiedWeight = baseWeight; // Tier 0 weight not boosted/modified by global/staking
                 } else {
                     // Apply global modifier
                    modifiedWeight = (baseWeight * globalProbabilityModifier) / 100;
                    // Apply staking boost
                    uint256 stakingBoost = _getUserStakingBoost(_user);
                    if (stakingBoost > 100) {
                        modifiedWeight = (modifiedWeight * stakingBoost) / 100;
                    }
                 }

                currentCumulativeWeight += modifiedWeight;
                tierIds[currentIndex] = i;
                cumulativeWeights[currentIndex] = currentCumulativeWeight;
                currentIndex++;
            }
        }

        return (tierIds, cumulativeWeights);
    }

    /**
     * @dev Calculates the user's current staking boost percentage.
     * @param _user The user's address.
     * @return The boost percentage (100 = no boost, >100 = boost).
     */
    function _getUserStakingBoost(address _user) internal view returns (uint256) {
        UserStakingInfo storage stakingInfo = userStaking[_user];
        if (stakingInfo.amountStaked >= stakingRequirement && block.timestamp < stakingInfo.boostEndTime) {
             // Calculate boost percentage based on amount staked relative to requirement and max boost
             // Simple linear scale: (amount - requirement) / (max_stake_for_max_boost - requirement) * (max_boost - min_boost) + min_boost
             // For simplicity here, let's just apply a fixed boost if requirement is met, or scale linearly up to max.
             uint256 effectiveStakedAmount = stakingInfo.amountStaked;
             // Cap effective stake at some level if needed to prevent infinite boost scaling
             // For simplicity, let's say max boost is reached at 2x requirement
             uint256 maxStakeForMaxBoost = stakingRequirement * 2;
             if (effectiveStakedAmount > maxStakeForMaxBoost) {
                 effectiveStakedAmount = maxStakeForMaxBoost;
             }

             // Linear interpolation between min and max boost
             // Y = Y0 + (X - X0) * (Y1 - Y0) / (X1 - X0)
             // Y = boost, X = effectiveStakedAmount, Y0 = minStakingBoost, X0 = stakingRequirement, Y1 = maxStakingBoost, X1 = maxStakeForMaxBoost
             uint256 boostRange = maxStakingBoost - minStakingBoost;
             uint256 stakeRange = maxStakeForMaxBoost - stakingRequirement;

             if (stakeRange == 0) return minStakingBoost; // Avoid division by zero if requirement is 0 or max is same as min

             uint256 addedBoost = ((effectiveStakedAmount - stakingRequirement) * boostRange) / stakeRange;
             return minStakingBoost + addedBoost;

        } else {
            return 100; // No boost
        }
    }


    // --- View Functions ---

    /**
     * @dev Gets details for a specific item tier.
     * @param _tierId The ID of the item tier.
     * @return name, baseProbabilityWeight, minPotentialValue, maxPotentialValue, fusionInputTierId, fusionInputQuantity.
     */
    function getItemTierDetails(uint256 _tierId)
        external view returns (string memory name, uint256 baseProbabilityWeight, uint256 minPotentialValue, uint256 maxPotentialValue, uint256 fusionInputTierId, uint256 fusionInputQuantity)
    {
        ItemTier storage tier = itemTiers[_tierId];
        require(tier.baseProbabilityWeight > 0 || _tierId == 0, "Item tier not defined");
        return (tier.name, tier.baseProbabilityWeight, tier.minPotentialValue, tier.maxPotentialValue, tier.fusionInputTierId, tier.fusionInputQuantity);
    }

     /**
     * @dev Gets details for a specific lootbox type.
     * @param _typeId The ID of the lootbox type.
     * @return name, cost, baseWeight, totalTierWeights.
     */
    function getLootboxTypeDetails(uint256 _typeId)
        external view returns (string memory name, uint256 cost, uint256 baseWeight, uint256 totalTierWeights)
    {
        LootboxType storage lbType = lootboxTypes[_typeId];
        require(lbType.totalTierWeights > 0, "Lootbox type not defined");
        return (lbType.name, lbType.cost, lbType.baseWeight, lbType.totalTierWeights);
    }

     /**
     * @dev Gets the base probability weights for item tiers within a specific lootbox type.
     * @param _typeId The ID of the lootbox type.
     * @return tierIds Array of tier IDs with weights defined for this lootbox type.
     * @return weights Array of corresponding base weights.
     */
    function getLootboxTypeTierWeights(uint256 _typeId)
        external view returns (uint256[] memory tierIds, uint256[] memory weights)
    {
        LootboxType storage lbType = lootboxTypes[_typeId];
        require(lbType.totalTierWeights > 0, "Lootbox type not defined");

        uint256 count = 0;
         for(uint256 i=0; i < nextItemTierId.current(); i++) {
             if (lbType.itemTierWeights[i] > 0) {
                 count++;
             }
         }

         tierIds = new uint256[](count);
         weights = new uint256[](count);
         uint256 index = 0;
         for(uint256 i=0; i < nextItemTierId.current(); i++) {
             if (lbType.itemTierWeights[i] > 0) {
                 tierIds[index] = i;
                 weights[index] = lbType.itemTierWeights[i];
                 index++;
             }
         }
         return (tierIds, weights);
    }


    /**
     * @dev Gets the list of item token IDs currently in a tier's pool.
     * @param _tierId The ID of the item tier.
     * @return Array of item NFT token IDs.
     */
    function getItemPoolItems(uint256 _tierId) external view returns (uint256[] memory) {
        require(itemTiers[_tierId].baseProbabilityWeight > 0 || _tierId == 0, "Item tier not defined");
        return itemTierPool[_tierId];
    }

    /**
     * @dev Gets the current global probability modifier.
     */
    function getGlobalProbabilityModifier() external view returns (uint256) {
        return globalProbabilityModifier;
    }

    /**
     * @dev Gets staking configuration parameters.
     */
    function getStakingDetails() external view returns (uint256 requirement, uint256 minBoost, uint256 maxBoost, uint256 duration) {
        return (stakingRequirement, minStakingBoost, maxStakingBoost, stakingDuration);
    }

    /**
     * @dev Gets a user's current staking information.
     * @param _user The user's address.
     * @return amountStaked, boostEndTime.
     */
    function getUserStakingInfo(address _user) external view returns (uint256 amountStaked, uint256 boostEndTime) {
        UserStakingInfo storage stakingInfo = userStaking[_user];
        return (stakingInfo.amountStaked, stakingInfo.boostEndTime);
    }

     /**
     * @dev Gets a user's *effective* staking boost percentage.
     * @param _user The user's address.
     * @return The effective boost percentage (100 = no boost, >100 = boost).
     */
    function getUserEffectiveStakingBoost(address _user) external view returns (uint256) {
        return _getUserStakingBoost(_user);
    }


    /**
     * @dev Gets possible outcomes for item fusion from a given input tier.
     * @param _inputTierId The ID of the input tier.
     * @return resultTierIds Array of potential resulting tier IDs.
     * @return probabilityWeights Array of weights for each outcome.
     */
    function getFusionParameters(uint256 _inputTierId)
        external view returns (uint256[] memory resultTierIds, uint256[] memory probabilityWeights)
    {
        require(itemTiers[_inputTierId].fusionInputQuantity > 0, "Input tier not configured for fusion");

        FusionOutcome[] storage outcomes = fusionPossibleOutcomes[_inputTierId];
        resultTierIds = new uint256[](outcomes.length);
        probabilityWeights = new uint256[](outcomes.length);

        for (uint i = 0; i < outcomes.length; i++) {
            resultTierIds[i] = outcomes[i].resultTierId;
            probabilityWeights[i] = outcomes[i].probabilityWeight;
        }
        return (resultTierIds, probabilityWeights);
    }

     /**
     * @dev Simulates and returns the *current* dynamic probabilities for item tiers
     *      within a specific lootbox type for a given user.
     *      This is a view function and does not consume gas for state changes or VRF.
     * @param _user The user address (to calculate staking boost).
     * @param _lootboxTypeId The ID of the lootbox type.
     * @return tierIds Array of tier IDs with non-zero dynamic probability.
     * @return dynamicWeights Array of corresponding dynamic weights.
     */
    function getLootboxDynamicProbabilities(address _user, uint256 _lootboxTypeId)
        external view returns (uint256[] memory tierIds, uint256[] memory dynamicWeights)
    {
        LootboxType storage lbType = lootboxTypes[_lootboxTypeId];
        require(lbType.totalTierWeights > 0, "Lootbox type not defined");

        uint256 itemCount = 0;
        // First pass to count valid tiers
        for (uint256 i = 0; i < nextItemTierId.current(); i++) {
             if (lbType.itemTierWeights[i] > 0 && (i == 0 || itemTierPool[i].length > 0)) {
                itemCount++;
            }
        }

        tierIds = new uint256[](itemCount);
        dynamicWeights = new uint256[](itemCount);

        uint256 currentIndex = 0;
        uint256 stakingBoost = _getUserStakingBoost(_user); // Calculate boost once

        for (uint256 i = 0; i < nextItemTierId.current(); i++) {
             uint256 baseWeight = lbType.itemTierWeights[i];
             if (baseWeight > 0 && (i == 0 || itemTierPool[i].length > 0)) {
                 uint256 modifiedWeight;
                 if (i == 0) {
                     modifiedWeight = baseWeight; // Tier 0 weight not boosted/modified
                 } else {
                    modifiedWeight = (baseWeight * globalProbabilityModifier) / 100;
                    if (stakingBoost > 100) {
                        modifiedWeight = (modifiedWeight * stakingBoost) / 100;
                    }
                 }
                 tierIds[currentIndex] = i;
                 dynamicWeights[currentIndex] = modifiedWeight;
                 currentIndex++;
             }
        }

        return (tierIds, dynamicWeights);
    }

    /**
     * @dev Gets the status of a VRF request.
     * @param _requestId The VRF request ID.
     * @return user, lootboxId, itemIdsToFuse, requestType, fulfilled.
     */
    function getVRFRequestStatus(uint256 _requestId)
        external view returns (address user, uint256 lootboxId, uint256[] memory itemIdsToFuse, uint8 requestType, bool fulfilled)
    {
        RequestDetails storage request = s_requests[_requestId];
        return (request.user, request.lootboxId, request.itemIdsToFuse, request.requestType, request.fulfilled);
    }

    /**
     * @dev Returns the total number of item tiers defined.
     */
    function totalItemTiers() external view returns (uint256) {
        return nextItemTierId.current();
    }

    /**
     * @dev Returns the total number of lootbox types defined.
     */
    function totalLootboxTypes() external view returns (uint256) {
        return nextLootboxTypeId.current();
    }

    // --- ERC165 Support ---
    // Needed for VRFConsumerBaseV2
    function supportsInterface(bytes4 interfaceId) public view override(VRFConsumerBaseV2, ERC721Holder) returns (bool) {
        return interfaceId == type(VRFConsumerBaseV2).interfaceId || super.supportsInterface(interfaceId);
    }

    // ERC721Holder hook to receive items into the pool
    // This is needed if the owner transfers items to the contract using safeTransferFrom
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
        public override returns (bytes4)
    {
         // You might add checks here, e.g., only allow transfers from the owner or specific addresses
         // or based on the `data` payload to automatically categorize the item into a pool upon deposit.
         // For this basic implementation, any ERC721 received will be accepted, but won't be
         // part of an item pool until `addItemToTierPool` is explicitly called by the owner.
         // A more advanced version could try to read metadata or use the `data` field
         // to automatically place the item in a pool if possible.
         // Example check: require(from == owner(), "Only owner can deposit items");
        return this.onERC721Received.selector;
    }

    // Fallback function to accept native currency
    receive() external payable {}
}
```