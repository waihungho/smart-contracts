I'm excited to present "ChronoForge: Algorithmic Emergence & Adaptive Reputation Protocol." This smart contract pushes the boundaries of dynamic digital assets by introducing a system where NFTs (ChronoAssets) evolve based on time, user actions, and a unique reputation score. It's designed to be complex, engaging, and to offer a novel experience beyond static NFTs or simple staking.

---

## ChronoForge: Algorithmic Emergence & Adaptive Reputation Protocol

This contract enables users to forge dynamic ChronoAssets (ERC721 NFTs) by combining existing Catalyst NFTs and Essence Tokens. ChronoAsset properties are not fixed at mint but emerge and evolve over time based on staking, user reputation, and participation in Quests. Users earn ChronoReputation, a non-transferable score that influences forging costs, quest access, and the rate of asset evolution. Assets and their attributes can also decay if neglected, introducing a dynamic lifecycle.

### Core Concepts & Innovations:

1.  **Algorithmic Forging**: Users combine existing ERC721 NFTs (Catalyst NFTs) and ERC20 tokens (Essence Tokens) according to predefined **Recipes** to create new, unique ChronoAssets (ERC721 tokens).
2.  **Temporal & Conditional Evolution**: ChronoAssets possess "Temporal Attributes" that change based on staking duration, participation in "Quests," or external oracle data. They can also have "Conditional Attributes" that unlock/decay based on specific on-chain events or user reputation.
3.  **Adaptive Reputation System**: Users earn "ChronoReputation" (a non-transferable, soulbound-like score) by successfully forging assets, completing quests, prolonged staking, and through a delegated voting mechanism. This reputation influences forging costs, quest access, and the rate of asset evolution.
4.  **Decay Mechanics**: ChronoAssets or their attributes can decay if not maintained (e.g., unstaked for too long, not participating in quests), introducing a dynamic lifecycle and encouraging active participation.

### Outline and Function Summary:

#### I. Core ChronoAsset Management (ERC721 based)
*   **`ChronoAssetData`**: A struct defining the dynamic properties and state of each ChronoAsset.
*   **`_nextChronoAssetId`**: Counter for unique ChronoAsset IDs.
*   **`_mintChronoAsset` (internal)**: Internal function to create a new ChronoAsset with initial properties.
*   **`_beforeTokenTransfer` (override)**: Overrides to prevent transfer of staked or quest-active assets.
*   **`getChronoAssetDetails` (view)**: Retrieves all detailed data for a specific ChronoAsset.
*   **`getChronoAssetMetadataURI` (view)**: Provides a URI for dynamic metadata, relying on an off-chain service.

#### II. Forging Mechanics
*   **`ForgingRecipe`**: A struct defining the requirements (NFTs, tokens, reputation) and outcomes for creating ChronoAssets.
*   **`ForgingRequest`**: A struct to track ongoing forging processes for a user.
*   **`recipes`**: Mapping of recipe ID to recipe details.
*   **`forgingRequests`**: Mapping of user address and recipe ID to track individual forging attempts.
*   **`_nextRecipeId`**: Counter for new recipe IDs.
*   **`protocolFee`**: The fee in native currency for initiating a forge.
*   **`totalProtocolFeesCollected`**: Accumulator for collected fees.
*   **`defineForgingRecipe` (admin)**: Allows the contract owner to create new forging recipes.
*   **`initiateChronoForge`**: User function to start a forging process by providing components and paying the protocol fee.
*   **`claimForgedChronoAsset`**: User function to claim their newly forged ChronoAsset after the required duration.
*   **`setProtocolFee` (admin)**: Allows the owner to adjust the forging protocol fee.
*   **`withdrawProtocolFees` (admin)**: Allows the owner to withdraw accumulated protocol fees.

#### III. Temporal Staking & Evolution
*   **`StakingRecord`**: A struct to track details of a staked ChronoAsset.
*   **`chronoAssetStaking`**: Mapping of ChronoAsset ID to its staking record.
*   **`stakeChronoAsset`**: User function to lock a ChronoAsset for a specified duration to enable temporal evolution.
*   **`unstakeChronoAsset`**: User function to retrieve a staked ChronoAsset, potentially incurring a penalty for early withdrawal.
*   **`_updateChronoAssetTemporalAttributes` (internal)**: Internal function to update an asset's properties based on staking time, reputation, and decay.
*   **`getStakingDetails` (view)**: Retrieves the staking record for a ChronoAsset.

#### IV. Adaptive Reputation System
*   **`chronoReputations`**: Mapping of user address to their ChronoReputation score.
*   **`reputationDelegations`**: Mapping from delegator to delegatee to track delegated reputation.
*   **`_updateReputation` (internal)**: Internal function to adjust a user's ChronoReputation score.
*   **`getReputation` (view)**: Retrieves the ChronoReputation score for a user.
*   **`delegateReputation`**: User function to delegate a portion of their reputation to another address.
*   **`undelegateReputation`**: User function to undelegate previously delegated reputation.

#### V. Quest & Challenge System
*   **`ChronoQuest`**: A struct defining quest details, including rewards, requirements, and oracle.
*   **`QuestParticipation`**: A struct to track a ChronoAsset's active participation in a quest.
*   **`quests`**: Mapping of quest ID to quest details.
*   **`questParticipations`**: Mapping of ChronoAsset ID to its current quest participation details.
*   **`_nextQuestId`**: Counter for new quest IDs.
*   **`_oracleAddress`**: The authorized address (multisig, keeper) to verify quest conditions.
*   **`createChronoQuest` (admin)**: Allows the owner to define new quests with specific requirements and rewards.
*   **`enrollInQuest`**: User function to assign one of their ChronoAssets to an active quest.
*   **`fulfillQuestCondition` (oracle-only)**: Callable by the designated oracle to mark a quest condition as met for an asset.
*   **`completeChronoQuest`**: User function to claim quest rewards for their ChronoAsset after conditions are fulfilled.
*   **`getQuestDetails` (view)**: Retrieves details of a specific quest.
*   **`getQuestParticipationDetails` (view)**: Retrieves the participation details for a ChronoAsset.

#### VI. Protocol Control & Utility
*   **`pause` (admin)**: Pauses core contract functionalities in emergencies.
*   **`unpause` (admin)**: Unpauses core contract functionalities.
*   **`rescueERC20` (admin)**: Allows the owner to recover accidentally sent ERC20 tokens (with checks to prevent withdrawing active protocol assets).
*   **`setOracleAddress` (admin)**: Sets the global oracle address.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; // For tokenURI

/**
 * @title ChronoForge: Algorithmic Emergence & Adaptive Reputation Protocol
 * @dev This contract allows users to forge dynamic ChronoAssets (ERC721 NFTs) by combining Catalyst NFTs and Essence Tokens.
 *      ChronoAsset properties evolve over time based on staking, user reputation, and participation in Quests.
 *      Users earn ChronoReputation, which influences forging costs, quest access, and asset evolution.
 *      Assets and their attributes can decay if not actively maintained.
 */
contract ChronoForge is ERC721, ERC721Burnable, Ownable, Pausable {
    using Counters for Counters.Counter;

    // --- Outline and Function Summary ---

    // I. Core ChronoAsset Management (ERC721 based)
    //    - chronos: A mapping of ChronoAsset ID to its ChronoAssetData struct, defining dynamic properties and state.
    //    - _nextChronoAssetId: Counter for unique ChronoAsset IDs.
    //    - _mintChronoAsset (internal): Internal function to create and mint a new ChronoAsset.
    //    - _beforeTokenTransfer (override): Prevents transfer of staked or quest-active assets.
    //    - getChronoAssetDetails (view): Retrieves detailed data for a specific ChronoAsset.
    //    - getChronoAssetMetadataURI (view): Returns the dynamic metadata URI for an asset.

    // II. Forging Mechanics
    //    - ForgingRecipe: Struct defining requirements and outcomes for ChronoAsset creation.
    //    - ForgingRequest: Struct to track ongoing user forging processes.
    //    - recipes: Mapping recipe ID to recipe details.
    //    - forgingRequests: Mapping user address and recipe ID to track individual forging requests.
    //    - _nextRecipeId: Counter for new recipe IDs.
    //    - protocolFee: Fee in native currency for forging.
    //    - totalProtocolFeesCollected: Accumulator for collected fees.
    //    - defineForgingRecipe (admin): Creates new forging recipes.
    //    - initiateChronoForge: User function to start a forging process, submitting components and fee.
    //    - claimForgedChronoAsset: User function to claim a newly forged ChronoAsset after its lock period.
    //    - setProtocolFee (admin): Adjusts the protocol forging fee.
    //    - withdrawProtocolFees (admin): Withdraws accumulated protocol fees to the owner.

    // III. Temporal Staking & Evolution
    //    - StakingRecord: Struct to track details of a staked ChronoAsset.
    //    - chronoAssetStaking: Mapping ChronoAsset ID to its staking record.
    //    - stakeChronoAsset: User function to lock a ChronoAsset for a duration to enable temporal evolution.
    //    - unstakeChronoAsset: User function to retrieve a staked ChronoAsset, with potential early unstake penalties.
    //    - _updateChronoAssetTemporalAttributes (internal): Adjusts asset properties based on time, staking, and decay.
    //    - getStakingDetails (view): Retrieves staking information for an asset.

    // IV. Adaptive Reputation System
    //    - chronoReputations: Mapping user address to their ChronoReputation score.
    //    - reputationDelegations: Mapping from delegator to delegatee to track delegated reputation.
    //    - _updateReputation (internal): Adjusts a user's reputation score.
    //    - getReputation (view): Retrieves a user's ChronoReputation score.
    //    - delegateReputation: User function to delegate a portion of their reputation to another address.
    //    - undelegateReputation: User function to undelegate previously delegated reputation.

    // V. Quest & Challenge System
    //    - ChronoQuest: Struct defining quest details, rewards, and oracle.
    //    - QuestParticipation: Struct for user's participation details in a quest.
    //    - quests: Mapping quest ID to quest details.
    //    - questParticipations: Mapping ChronoAsset ID to its current quest participation.
    //    - _nextQuestId: Counter for new quest IDs.
    //    - _oracleAddress: The address authorized to fulfill quest conditions.
    //    - createChronoQuest (admin): Defines new quests.
    //    - enrollInQuest: User function to assign a ChronoAsset to an active quest.
    //    - fulfillQuestCondition (oracle-only): Marks a quest condition as met for an asset.
    //    - completeChronoQuest: User function to claim quest rewards and benefits after fulfillment.
    //    - getQuestDetails (view): Retrieves details of a specific quest.
    //    - getQuestParticipationDetails (view): Retrieves participation details for an asset.

    // VI. Protocol Control & Utility
    //    - pause (admin): Pauses core protocol functions.
    //    - unpause (admin): Unpauses core protocol functions.
    //    - rescueERC20 (admin): Recovers accidentally sent ERC20 tokens.
    //    - setOracleAddress (admin): Sets the global oracle address.

    // --- Events ---
    event ChronoAssetForged(uint256 indexed chronoAssetId, address indexed owner, uint256 recipeId, uint256 forgingTimestamp);
    event ChronoAssetClaimed(uint256 indexed chronoAssetId, address indexed owner);
    event ChronoAssetStaked(uint256 indexed chronoAssetId, address indexed staker, uint256 duration);
    event ChronoAssetUnstaked(uint256 indexed chronoAssetId, address indexed staker, uint256 penaltyReputationApplied);
    event ReputationUpdated(address indexed user, uint256 newReputation, int256 delta);
    event ReputationDelegated(address indexed delegator, address indexed delegatee, uint256 amount);
    event ReputationUndelegated(address indexed delegator, address indexed delegatee, uint256 amount);
    event QuestCreated(uint256 indexed questId, string description, uint256 requiredReputation);
    event QuestEnrolled(uint256 indexed chronoAssetId, uint256 indexed questId, address indexed participant);
    event QuestConditionFulfilled(uint256 indexed chronoAssetId, uint256 indexed questId);
    event ChronoQuestCompleted(uint256 indexed chronoAssetId, uint256 indexed questId, address indexed participant);
    event ProtocolFeeUpdated(uint256 newFee);
    event FeesWithdrawn(address indexed recipient, uint256 amount);
    event OracleAddressUpdated(address indexed newOracleAddress);


    // --- State Variables & Structs ---

    // I. Core ChronoAsset Management
    struct ChronoAssetData {
        uint256 forgingTimestamp;
        uint256 lastEvolutionUpdate; // Timestamp of the last time temporal/conditional attributes were updated
        bytes32[] dynamicProperties; // Dynamically evolving properties (e.g., strength, rarity score, encoded as bytes32)
        uint256 reputationMultiplier; // Influences how much reputation affects its evolution (e.g., 100 = 1x)
        bool isStaked;
        uint256 currentQuestId; // 0 if not in a quest
        uint256 decayRate; // Rate at which attributes decay if neglected (e.g., points per day)
    }
    mapping(uint256 => ChronoAssetData) public chronos;
    Counters.Counter private _nextChronoAssetId;

    // II. Forging Mechanics
    struct ForgingRecipe {
        uint256 id;
        uint256 requiredReputation;
        IERC721[] catalystNFTs; // Addresses of required ERC721 contracts
        uint256[] catalystNFTAmounts; // Corresponding amounts (usually 1 for ERC721)
        IERC20[] essenceTokens; // Addresses of required ERC20 contracts
        uint256[] essenceTokenAmounts; // Corresponding amounts
        uint256 forgingDuration; // Time in seconds until the asset can be claimed
        bytes32[] initialProperties; // Initial dynamic properties set upon forging
        uint256 initialReputationMultiplier;
        uint256 initialDecayRate;
        bool active;
    }
    mapping(uint256 => ForgingRecipe) public recipes;
    Counters.Counter private _nextRecipeId;

    struct ForgingRequest {
        address user;
        uint256 recipeId;
        uint256 forgingStartTime;
        uint256 chronoAssetId; // 0 until claimed
        bool claimed;
    }
    // Mapping: user => recipeId => request details. This ensures one pending request per user per recipe.
    mapping(address => mapping(uint256 => ForgingRequest)) public forgingRequests;

    uint256 public protocolFee = 0.01 ether; // Default 0.01 ETH fee for forging (can be adjusted)
    uint256 public totalProtocolFeesCollected;

    // III. Temporal Staking & Evolution
    struct StakingRecord {
        address staker;
        uint256 stakeStartTime;
        uint256 stakeEndTime;
        bool active;
    }
    mapping(uint256 => StakingRecord) public chronoAssetStaking; // ChronoAsset ID => Staking Record

    // IV. Adaptive Reputation System
    mapping(address => uint256) public chronoReputations;
    // Mapping: delegator => delegatee => amount delegated
    mapping(address => mapping(address => uint256)) public reputationDelegations;

    // V. Quest & Challenge System
    struct ChronoQuest {
        uint256 id;
        string description;
        uint256 requiredReputation; // Minimum reputation for owner to enroll an asset
        bytes32[] rewardProperties; // Properties gained/enhanced upon completion
        uint256 completionDeadline; // 0 for no deadline
        address questOracle; // Address authorized to fulfill quest conditions
        bool active;
    }
    mapping(uint256 => ChronoQuest) public quests;
    Counters.Counter private _nextQuestId;

    struct QuestParticipation {
        uint256 questId;
        bool conditionFulfilled;
        uint256 enrollmentTime;
    }
    // Mapping: ChronoAsset ID => QuestParticipation details for the current quest
    mapping(uint256 => QuestParticipation) public questParticipations;

    address public _globalOracleAddress; // Global oracle address for general protocol updates/verifications

    // VI. Protocol Control & Utility
    string private _baseTokenURI; // Base URI for dynamic metadata service

    // --- Constructor ---
    constructor(address initialGlobalOracleAddress) ERC721("ChronoForge Asset", "CFA") Ownable(msg.sender) {
        require(initialGlobalOracleAddress != address(0), "Invalid global oracle address");
        _globalOracleAddress = initialGlobalOracleAddress;
    }

    // --- Modifiers ---
    modifier onlyGlobalOracle() {
        require(msg.sender == _globalOracleAddress, "Only global oracle can call this function");
        _;
    }
    
    modifier onlyQuestOracle(uint256 questId) {
        require(quests[questId].questOracle == msg.sender, "Caller is not the authorized oracle for this quest");
        _;
    }

    // --- I. Core ChronoAsset Management ---

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @dev Sets the base URI for ChronoAsset metadata. This typically points to an API endpoint
     *      that dynamically generates JSON metadata based on the on-chain state of the ChronoAsset.
     * @param newBaseURI The new base URI for metadata.
     */
    function setMetadataBaseURI(string memory newBaseURI) external onlyOwner {
        _baseTokenURI = newBaseURI;
    }

    /**
     * @dev Overrides ERC721's _beforeTokenTransfer to enforce protocol rules.
     *      Prevents transfer of ChronoAssets that are currently staked or actively participating in a quest.
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        // Allow transfer to/from contract for staking/forging
        if (to == address(this) || from == address(this)) {
            return;
        }

        // Prevent transfer if ChronoAsset is staked or actively participating in a quest
        if (chronos[tokenId].isStaked) {
            revert("ChronoAsset is staked and cannot be transferred");
        }
        if (chronos[tokenId].currentQuestId != 0) {
            revert("ChronoAsset is in a quest and cannot be transferred");
        }
    }

    /**
     * @dev Internal function to mint a new ChronoAsset.
     * @param to The recipient of the new ChronoAsset.
     * @param recipeId The ID of the forging recipe used to create this asset.
     * @param initialProps Initial dynamic properties of the asset.
     * @param initialRepMultiplier Initial reputation multiplier for the asset.
     * @param initialDecay Initial decay rate for the asset.
     * @return The ID of the newly minted ChronoAsset.
     */
    function _mintChronoAsset(
        address to,
        uint256 recipeId,
        bytes32[] memory initialProps,
        uint256 initialRepMultiplier,
        uint256 initialDecay
    ) internal returns (uint256) {
        _nextChronoAssetId.increment();
        uint256 newChronoAssetId = _nextChronoAssetId.current();

        _safeMint(to, newChronoAssetId);

        chronos[newChronoAssetId] = ChronoAssetData({
            forgingTimestamp: block.timestamp,
            lastEvolutionUpdate: block.timestamp,
            dynamicProperties: initialProps,
            reputationMultiplier: initialRepMultiplier,
            isStaked: false,
            currentQuestId: 0,
            decayRate: initialDecay
        });

        emit ChronoAssetForged(newChronoAssetId, to, recipeId, block.timestamp);
        return newChronoAssetId;
    }

    /**
     * @dev Retrieves the detailed data for a specific ChronoAsset.
     * @param chronoAssetId The ID of the ChronoAsset.
     * @return ChronoAssetData struct containing all relevant details.
     */
    function getChronoAssetDetails(uint256 chronoAssetId) public view returns (ChronoAssetData memory) {
        require(_exists(chronoAssetId), "ChronoAsset does not exist");
        return chronos[chronoAssetId];
    }

    /**
     * @dev Retrieves the dynamic metadata URI for a specific ChronoAsset.
     *      This function relies on an off-chain service (specified by `_baseTokenURI`)
     *      to generate the JSON metadata based on the current on-chain state of the ChronoAsset.
     * @param chronoAssetId The ID of the ChronoAsset.
     * @return A URI pointing to the JSON metadata.
     */
    function getChronoAssetMetadataURI(uint256 chronoAssetId) public view returns (string memory) {
        require(_exists(chronoAssetId), "ChronoAsset does not exist");
        return string(abi.encodePacked(_baseTokenURI, Strings.toString(chronoAssetId)));
    }


    // --- II. Forging Mechanics ---

    /**
     * @dev Allows the contract owner to define a new forging recipe.
     *      Each recipe specifies required reputation, Catalyst NFTs, Essence Tokens,
     *      forging duration, and the initial properties of the resulting ChronoAsset.
     * @param requiredReputation Minimum reputation required to use this recipe.
     * @param catalystNFTs Addresses of ERC721 contracts required.
     * @param essenceTokens Addresses of ERC20 contracts required.
     * @param essenceTokenAmounts Amounts of ERC20 tokens required.
     * @param forgingDuration Time in seconds the asset is locked during forging.
     * @param initialProperties Initial dynamic properties for the forged asset (bytes32 array).
     * @param initialReputationMultiplier Initial reputation multiplier for the asset.
     * @param initialDecayRate Initial decay rate for the asset.
     * @return The ID of the newly defined recipe.
     */
    function defineForgingRecipe(
        uint256 requiredReputation,
        IERC721[] memory catalystNFTs,
        IERC20[] memory essenceTokens,
        uint256[] memory essenceTokenAmounts,
        uint256 forgingDuration,
        bytes32[] memory initialProperties,
        uint256 initialReputationMultiplier,
        uint256 initialDecayRate
    ) external onlyOwner returns (uint256 recipeId) {
        require(catalystNFTs.length == essenceTokens.length, "Catalyst and Essence arrays must be same length for simplicity"); // Simplified: assumes 1:1 mapping
        require(essenceTokens.length == essenceTokenAmounts.length, "Essence token and amount arrays mismatch");
        require(forgingDuration > 0, "Forging duration must be positive");
        require(initialReputationMultiplier > 0, "Reputation multiplier must be positive");

        _nextRecipeId.increment();
        recipeId = _nextRecipeId.current();

        recipes[recipeId] = ForgingRecipe({
            id: recipeId,
            requiredReputation: requiredReputation,
            catalystNFTs: catalystNFTs,
            catalystNFTAmounts: new uint256[](catalystNFTs.length), // Always 1 for ERC721 here, but array for flexibility
            essenceTokens: essenceTokens,
            essenceTokenAmounts: essenceTokenAmounts,
            forgingDuration: forgingDuration,
            initialProperties: initialProperties,
            initialReputationMultiplier: initialReputationMultiplier,
            initialDecayRate: initialDecayRate,
            active: true
        });

        // Initialize catalystNFTAmounts to 1 for each ERC721
        for (uint256 i = 0; i < catalystNFTs.length; i++) {
            recipes[recipeId].catalystNFTAmounts[i] = 1;
        }
        return recipeId;
    }

    /**
     * @dev Allows a user to initiate the forging process for a ChronoAsset.
     *      Requires the user to send the protocol fee, transfer specified Catalyst NFTs,
     *      and Essence Tokens to the contract.
     * @param recipeId The ID of the forging recipe to use.
     * @param catalystNFTIds The specific IDs of the catalyst NFTs being used.
     */
    function initiateChronoForge(uint256 recipeId, uint256[] memory catalystNFTIds) external payable whenNotPaused {
        ForgingRecipe storage recipe = recipes[recipeId];
        require(recipe.active, "Recipe is not active");
        require(chronoReputations[msg.sender] >= recipe.requiredReputation, "Insufficient ChronoReputation");
        require(msg.value >= protocolFee, "Insufficient protocol fee");
        require(forgingRequests[msg.sender][recipeId].user == address(0) || forgingRequests[msg.sender][recipeId].claimed, "Previous forging request for this recipe not claimed");
        require(catalystNFTIds.length == recipe.catalystNFTs.length, "Mismatched number of catalyst NFTs provided");

        // Transfer Catalyst NFTs
        for (uint256 i = 0; i < recipe.catalystNFTs.length; i++) {
            IERC721 catalystNFT = recipe.catalystNFTs[i];
            uint256 nftId = catalystNFTIds[i];
            require(catalystNFT.ownerOf(nftId) == msg.sender, "User does not own required Catalyst NFT");
            catalystNFT.transferFrom(msg.sender, address(this), nftId);
        }

        // Transfer Essence Tokens
        for (uint256 i = 0; i < recipe.essenceTokens.length; i++) {
            IERC20 essenceToken = recipe.essenceTokens[i];
            uint256 amount = recipe.essenceTokenAmounts[i];
            // Approve contract to spend tokens before calling transferFrom
            require(essenceToken.transferFrom(msg.sender, address(this), amount), "Essence token transfer failed. Did you approve this contract?");
        }

        totalProtocolFeesCollected += msg.value;

        // Record forging request
        forgingRequests[msg.sender][recipeId] = ForgingRequest({
            user: msg.sender,
            recipeId: recipeId,
            forgingStartTime: block.timestamp,
            chronoAssetId: 0, // Set to 0 initially, updated on claim
            claimed: false
        });

        _updateReputation(msg.sender, 10, true); // +10 reputation for initiating forge
    }

    /**
     * @dev Allows a user to claim their newly forged ChronoAsset after the forging duration has passed.
     * @param recipeId The ID of the recipe used for forging.
     */
    function claimForgedChronoAsset(uint256 recipeId) external whenNotPaused {
        ForgingRequest storage request = forgingRequests[msg.sender][recipeId];
        require(request.user == msg.sender, "No active forging request for this recipe by sender");
        require(!request.claimed, "ChronoAsset already claimed for this request");
        require(block.timestamp >= request.forgingStartTime + recipes[recipeId].forgingDuration, "Forging duration not yet passed");

        // Mint the new ChronoAsset
        uint256 newChronoAssetId = _mintChronoAsset(
            msg.sender,
            recipeId,
            recipes[recipeId].initialProperties,
            recipes[recipeId].initialReputationMultiplier,
            recipes[recipeId].initialDecayRate
        );

        request.chronoAssetId = newChronoAssetId;
        request.claimed = true;

        _updateReputation(msg.sender, 50, true); // +50 reputation for successful claim

        emit ChronoAssetClaimed(newChronoAssetId, msg.sender);
    }

    /**
     * @dev Allows the owner to set the protocol fee for forging.
     * @param newFee The new fee amount in wei (or equivalent native currency units).
     */
    function setProtocolFee(uint256 newFee) external onlyOwner {
        protocolFee = newFee;
        emit ProtocolFeeUpdated(newFee);
    }

    /**
     * @dev Allows the owner to withdraw accumulated protocol fees.
     */
    function withdrawProtocolFees() external onlyOwner {
        uint256 amount = totalProtocolFeesCollected;
        require(amount > 0, "No fees to withdraw");
        totalProtocolFeesCollected = 0;
        (bool success, ) = payable(owner()).call{value: amount}("");
        require(success, "Fee withdrawal failed");
        emit FeesWithdrawn(owner(), amount);
    }

    // --- III. Temporal Staking & Evolution ---

    /**
     * @dev Stakes a ChronoAsset for a specified duration.
     *      The asset is transferred to the contract and cannot be transferred while staked.
     *      Reputation is gained proportional to staking duration.
     * @param chronoAssetId The ID of the ChronoAsset to stake.
     * @param duration The duration in seconds to stake the asset.
     */
    function stakeChronoAsset(uint256 chronoAssetId, uint256 duration) external whenNotPaused {
        require(_isApprovedOrOwner(msg.sender, chronoAssetId), "Not approved or owner");
        require(!chronos[chronoAssetId].isStaked, "ChronoAsset is already staked");
        require(chronos[chronoAssetId].currentQuestId == 0, "ChronoAsset is in a quest");
        require(duration > 0, "Staking duration must be positive");

        _transfer(msg.sender, address(this), chronoAssetId); // Transfer to contract
        chronos[chronoAssetId].isStaked = true;

        chronoAssetStaking[chronoAssetId] = StakingRecord({
            staker: msg.sender,
            stakeStartTime: block.timestamp,
            stakeEndTime: block.timestamp + duration,
            active: true
        });

        // Small reputation boost per week of staking
        _updateReputation(msg.sender, duration / (1 days * 7), true);

        emit ChronoAssetStaked(chronoAssetId, msg.sender, duration);
    }

    /**
     * @dev Unstakes a ChronoAsset.
     *      If unstaked before `stakeEndTime`, a reputation penalty is applied.
     *      The asset is transferred back to the owner.
     * @param chronoAssetId The ID of the ChronoAsset to unstake.
     */
    function unstakeChronoAsset(uint256 chronoAssetId) external whenNotPaused {
        StakingRecord storage record = chronoAssetStaking[chronoAssetId];
        require(record.active && record.staker == msg.sender, "ChronoAsset not staked by sender or not active");
        require(chronos[chronoAssetId].isStaked, "ChronoAsset not marked as staked");

        uint256 penaltyReputationApplied = 0;
        if (block.timestamp < record.stakeEndTime) {
            // Example penalty: 1 reputation point per month (30 days) of remaining staking time
            uint256 remainingTime = record.stakeEndTime - block.timestamp;
            penaltyReputationApplied = remainingTime / (1 days * 30);
            _updateReputation(msg.sender, penaltyReputationApplied, false); // Reduce reputation for early unstake
        } else {
            // Bonus reputation for full staking duration completion
            _updateReputation(msg.sender, (record.stakeEndTime - record.stakeStartTime) / (1 days * 7), true); // Bonus: 1 rep per week staked
        }

        chronos[chronoAssetId].isStaked = false;
        record.active = false;
        delete chronoAssetStaking[chronoAssetId]; // Clean up record

        _transfer(address(this), msg.sender, chronoAssetId); // Transfer back to owner

        emit ChronoAssetUnstaked(chronoAssetId, msg.sender, penaltyReputationApplied);

        // Trigger an evolution update upon unstaking to reflect changes from staking period.
        _updateChronoAssetTemporalAttributes(chronoAssetId);
    }

    /**
     * @dev Internal function to update a ChronoAsset's temporal attributes.
     *      This function encapsulates the core logic of asset evolution. It should be called
     *      whenever a state change might trigger evolution (e.g., staking, unstaking, quest completion).
     *      The actual evolution logic (how `dynamicProperties` change) would be more complex in a live system,
     *      potentially involving external AI oracles or detailed on-chain game-theory mechanics.
     *      For this example, it's a simplified placeholder.
     * @param chronoAssetId The ID of the ChronoAsset to update.
     */
    function _updateChronoAssetTemporalAttributes(uint256 chronoAssetId) internal {
        ChronoAssetData storage asset = chronos[chronoAssetId];
        uint256 timeElapsed = block.timestamp - asset.lastEvolutionUpdate;

        // Skip if no time has passed or asset has no dynamic properties to evolve
        if (timeElapsed == 0 || asset.dynamicProperties.length == 0) {
            asset.lastEvolutionUpdate = block.timestamp;
            return;
        }

        // --- Simplified Evolution Logic Placeholder ---
        // This logic modifies the first dynamic property as a generic 'power' attribute.
        // In a real system, there would be multiple properties and more complex rules.
        uint256 currentPower = uint256(asset.dynamicProperties[0]);

        if (asset.isStaked) {
            // Gain 'power' while staked, scaled by reputation multiplier
            uint256 gain = (timeElapsed / 1 days) * (asset.reputationMultiplier / 100); // e.g., 1 point per day per 100 rep multiplier
            currentPower += gain;
        } else {
            // Decay 'power' if not staked for more than 7 days
            uint256 timeSinceUnstaked = block.timestamp - asset.lastEvolutionUpdate;
            if (timeSinceUnstaked > 7 days) {
                uint256 decay = (timeSinceUnstaked / 1 days) * asset.decayRate; // Decay by rate per day
                currentPower = currentPower > decay ? currentPower - decay : 0;
            }
        }
        asset.dynamicProperties[0] = bytes32(currentPower);
        // --- End Simplified Evolution Logic ---

        asset.lastEvolutionUpdate = block.timestamp;
    }

    /**
     * @dev Retrieves staking details for a ChronoAsset.
     * @param chronoAssetId The ID of the ChronoAsset.
     * @return StakingRecord struct containing staking information.
     */
    function getStakingDetails(uint256 chronoAssetId) public view returns (StakingRecord memory) {
        require(_exists(chronoAssetId), "ChronoAsset does not exist");
        return chronoAssetStaking[chronoAssetId];
    }

    // --- IV. Adaptive Reputation System ---

    /**
     * @dev Internal function to update a user's ChronoReputation.
     *      This is called by various protocol actions (forging, staking, quests).
     * @param user The address whose reputation to update.
     * @param delta The amount to change the reputation by.
     * @param increase If true, add delta; if false, subtract delta (with floor at 0).
     */
    function _updateReputation(address user, uint256 delta, bool increase) internal {
        uint256 currentReputation = chronoReputations[user];
        uint256 newReputation;
        int256 signedDelta;

        if (increase) {
            newReputation = currentReputation + delta;
            signedDelta = int256(delta);
        } else {
            newReputation = currentReputation > delta ? currentReputation - delta : 0;
            signedDelta = -int256(delta);
        }
        chronoReputations[user] = newReputation;
        emit ReputationUpdated(user, newReputation, signedDelta);
    }

    /**
     * @dev Allows a user to delegate a portion of their ChronoReputation to another address.
     *      Delegated reputation contributes to the delegatee's effective reputation and can be used
     *      for actions requiring a minimum reputation (e.g., forging, quest enrollment).
     * @param delegatee The address to delegate reputation to.
     * @param amount The amount of reputation to delegate.
     */
    function delegateReputation(address delegatee, uint256 amount) external whenNotPaused {
        require(delegatee != address(0) && delegatee != msg.sender, "Invalid delegatee address");
        require(chronoReputations[msg.sender] >= amount, "Insufficient reputation to delegate");
        
        // Update reputation scores
        chronoReputations[msg.sender] -= amount; // Reduce delegator's effective reputation
        chronoReputations[delegatee] += amount;   // Increase delegatee's effective reputation
        
        // Track the specific delegation for undelegation purposes
        reputationDelegations[msg.sender][delegatee] += amount;

        emit ReputationDelegated(msg.sender, delegatee, amount);
        emit ReputationUpdated(msg.sender, chronoReputations[msg.sender], -int256(amount));
        emit ReputationUpdated(delegatee, chronoReputations[delegatee], int256(amount));
    }

    /**
     * @dev Allows a user to undelegate previously delegated ChronoReputation.
     *      The reputation is returned to the delegator's effective reputation.
     * @param delegatee The address from which to undelegate reputation (the one who received it).
     * @param amount The amount of reputation to undelegate.
     */
    function undelegateReputation(address delegatee, uint256 amount) external whenNotPaused {
        require(reputationDelegations[msg.sender][delegatee] >= amount, "Not enough reputation delegated to undelegate");

        // Update reputation scores
        chronoReputations[msg.sender] += amount; // Increase delegator's effective reputation
        chronoReputations[delegatee] -= amount;   // Reduce delegatee's effective reputation
        
        // Update the tracked delegation
        reputationDelegations[msg.sender][delegatee] -= amount;

        emit ReputationUndelegated(msg.sender, delegatee, amount);
        emit ReputationUpdated(msg.sender, chronoReputations[msg.sender], int256(amount));
        emit ReputationUpdated(delegatee, chronoReputations[delegatee], -int256(amount));
    }

    /**
     * @dev Retrieves the ChronoReputation score for a specific user.
     * @param user The address of the user.
     * @return The user's ChronoReputation score.
     */
    function getReputation(address user) public view returns (uint256) {
        return chronoReputations[user];
    }

    // --- V. Quest & Challenge System ---

    /**
     * @dev Allows the owner to create a new ChronoQuest.
     *      Quests define requirements, rewards, a deadline, and a specific oracle
     *      responsible for fulfilling quest conditions.
     * @param description A brief description of the quest.
     * @param requiredReputation Minimum reputation required for an asset owner to enroll.
     * @param rewardProperties Properties that are enhanced or added upon quest completion.
     * @param completionDeadline Deadline for the quest (0 for no deadline).
     * @param questOracle The address authorized to fulfill conditions for this specific quest.
     * @return The ID of the newly created quest.
     */
    function createChronoQuest(
        string memory description,
        uint256 requiredReputation,
        bytes32[] memory rewardProperties,
        uint256 completionDeadline,
        address questOracle
    ) external onlyOwner returns (uint256 questId) {
        require(questOracle != address(0), "Invalid quest oracle address");

        _nextQuestId.increment();
        questId = _nextQuestId.current();

        quests[questId] = ChronoQuest({
            id: questId,
            description: description,
            requiredReputation: requiredReputation,
            rewardProperties: rewardProperties,
            completionDeadline: completionDeadline,
            questOracle: questOracle,
            active: true
        });

        emit QuestCreated(questId, description, requiredReputation);
        return questId;
    }

    /**
     * @dev Allows an owner to enroll one of their ChronoAssets into an active quest.
     *      The asset cannot be staked or in another quest. Reputation requirements apply.
     * @param chronoAssetId The ID of the ChronoAsset to enroll.
     * @param questId The ID of the quest to enroll in.
     */
    function enrollInQuest(uint256 chronoAssetId, uint256 questId) external whenNotPaused {
        require(_isApprovedOrOwner(msg.sender, chronoAssetId), "Not approved or owner of ChronoAsset");
        ChronoQuest storage quest = quests[questId];
        require(quest.active, "Quest is not active");
        require(chronoReputations[msg.sender] >= quest.requiredReputation, "Insufficient ChronoReputation to enroll in quest");
        require(!chronos[chronoAssetId].isStaked, "ChronoAsset is staked and cannot enroll");
        require(chronos[chronoAssetId].currentQuestId == 0, "ChronoAsset is already in another quest");
        if (quest.completionDeadline != 0) {
            require(block.timestamp < quest.completionDeadline, "Quest deadline has passed");
        }

        chronos[chronoAssetId].currentQuestId = questId;
        questParticipations[chronoAssetId] = QuestParticipation({
            questId: questId,
            conditionFulfilled: false,
            enrollmentTime: block.timestamp
        });

        _updateReputation(msg.sender, 20, true); // Small reputation boost for engaging in a quest
        emit QuestEnrolled(chronoAssetId, questId, msg.sender);
    }

    /**
     * @dev Marks a quest condition as fulfilled for a specific ChronoAsset.
     *      This function is callable only by the designated `questOracle` for that quest.
     *      The actual verification of the quest condition (e.g., off-chain data, computation)
     *      is assumed to be performed by the oracle before calling this function.
     * @param chronoAssetId The ID of the ChronoAsset.
     * @param questId The ID of the quest.
     */
    function fulfillQuestCondition(uint256 chronoAssetId, uint256 questId) external onlyQuestOracle(questId) {
        QuestParticipation storage participation = questParticipations[chronoAssetId];
        ChronoQuest storage quest = quests[questId];

        require(participation.questId == questId, "ChronoAsset not enrolled in this quest");
        require(!participation.conditionFulfilled, "Quest condition already fulfilled");
        if (quest.completionDeadline != 0) {
            require(block.timestamp < quest.completionDeadline, "Quest deadline has passed");
        }

        participation.conditionFulfilled = true;
        emit QuestConditionFulfilled(chronoAssetId, questId);
    }

    /**
     * @dev Allows the owner of a ChronoAsset to complete a quest after its conditions are fulfilled.
     *      This applies the quest's `rewardProperties` to the ChronoAsset and clears its quest status.
     * @param chronoAssetId The ID of the ChronoAsset.
     * @param questId The ID of the quest.
     */
    function completeChronoQuest(uint256 chronoAssetId, uint256 questId) external whenNotPaused {
        require(_isApprovedOrOwner(msg.sender, chronoAssetId), "Not approved or owner of ChronoAsset");
        QuestParticipation storage participation = questParticipations[chronoAssetId];
        ChronoQuest storage quest = quests[questId];

        require(participation.questId == questId, "ChronoAsset not enrolled in this quest");
        require(participation.conditionFulfilled, "Quest condition not yet fulfilled");
        require(chronos[chronoAssetId].currentQuestId == questId, "ChronoAsset not actively in this quest");

        // Apply reward properties to the ChronoAsset
        for (uint256 i = 0; i < quest.rewardProperties.length; i++) {
            // This example simply appends properties. More complex logic would merge, enhance, or replace existing properties.
            chronos[chronoAssetId].dynamicProperties.push(quest.rewardProperties[i]);
        }

        chronos[chronoAssetId].currentQuestId = 0; // Clear quest status
        delete questParticipations[chronoAssetId]; // Remove participation record

        _updateReputation(msg.sender, 100, true); // Significant reputation boost for completing a quest
        emit ChronoQuestCompleted(chronoAssetId, questId, msg.sender);

        _updateChronoAssetTemporalAttributes(chronoAssetId); // Trigger evolution update after quest completion
    }

    /**
     * @dev Retrieves the details of a ChronoQuest.
     * @param questId The ID of the quest.
     * @return ChronoQuest struct containing all quest details.
     */
    function getQuestDetails(uint256 questId) public view returns (ChronoQuest memory) {
        require(quests[questId].active, "Quest does not exist or is inactive");
        return quests[questId];
    }

    /**
     * @dev Retrieves the participation details for a ChronoAsset in its current quest.
     * @param chronoAssetId The ID of the ChronoAsset.
     * @return QuestParticipation struct.
     */
    function getQuestParticipationDetails(uint256 chronoAssetId) public view returns (QuestParticipation memory) {
        require(_exists(chronoAssetId), "ChronoAsset does not exist");
        return questParticipations[chronoAssetId];
    }

    // --- VI. Protocol Control & Utility ---

    /**
     * @dev Pauses core contract functionalities. Callable by owner.
     *      Prevents new forging, staking, quest enrollment, etc., in emergencies.
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses core contract functionalities. Callable by owner.
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @dev Allows the owner to rescue accidentally sent ERC20 tokens to the contract.
     *      Includes basic checks to prevent withdrawing tokens that are currently
     *      held as 'essence tokens' for active forging recipes.
     *      A more robust system would track token holdings by purpose.
     * @param tokenAddress The address of the ERC20 token to rescue.
     * @param amount The amount of tokens to rescue.
     */
    function rescueERC20(IERC20 tokenAddress, uint256 amount) external onlyOwner {
        require(tokenAddress != address(0), "Invalid token address");
        require(tokenAddress.balanceOf(address(this)) >= amount, "Insufficient contract balance to rescue");

        // Simple check to prevent rescuing 'essence' tokens which are actively used in recipes.
        // This is a weak check; a proper system would track *which* tokens are held for *which* purpose.
        // For example, iterate through `recipes` to see if `tokenAddress` is listed as `essenceToken`.
        // This simple check just prevents immediate withdrawal if it's a known essence token.
        for (uint256 i = 1; i <= _nextRecipeId.current(); i++) { // Iterate through existing recipes
            if (recipes[i].active) { // Only check active recipes
                for (uint256 j = 0; j < recipes[i].essenceTokens.length; j++) {
                    require(address(tokenAddress) != address(recipes[i].essenceTokens[j]), "Cannot rescue token active in a recipe");
                }
            }
        }

        require(tokenAddress.transfer(owner(), amount), "ERC20 rescue failed");
    }

    /**
     * @dev Allows the owner to set the global oracle address.
     *      This oracle can be a single address, a multisig, or a Chainlink Keeper.
     *      It has privileges for `onlyGlobalOracle` functions. Individual quests can
     *      still define their own specific `questOracle`.
     * @param newOracleAddress The new address for the global oracle.
     */
    function setOracleAddress(address newOracleAddress) external onlyOwner {
        require(newOracleAddress != address(0), "Invalid oracle address");
        _globalOracleAddress = newOracleAddress;
        emit OracleAddressUpdated(newOracleAddress);
    }
}
```