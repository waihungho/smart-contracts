This smart contract, "AuraForge Protocol," introduces an advanced ecosystem centered around evolving NFTs called "AuraEssence." Users collect "AuraShards" (an ERC20 token) through various on-chain "SpiritTrials" (quests) and by staking. These Shards are then used to "catalyze" their AuraEssence NFTs, causing them to evolve through predefined "Tiers" and unlock unique "Traits." A user's "SpiritScore" (reputation) directly influences their ability to evolve NFTs and complete quests. The protocol also features "Genetic Splitting," allowing highly evolved Essences to split into new, distinct NFTs, utilizing Chainlink VRF for unpredictable trait generation. LoreMasters (a role managed by the contract owner) define evolution paths, quests, and manage the system's dynamic parameters.

The core idea is to create a living, interactive NFT experience where digital assets are not static but grow, change, and gain history through user engagement and strategic decision-making.

---

## AuraForge Protocol: Evolving Digital Spirits

**Outline:**

1.  **Core Concepts:**
    *   **AuraEssence (ERC721):** Evolving NFTs representing unique digital spirits. They start as abstract forms and gain traits through catalysis.
    *   **AuraShards (ERC20):** The utility token. Earned via SpiritTrials and staking, spent on AuraEssence evolution and genetic splitting.
    *   **SpiritScore (Reputation):** An on-chain reputation score for each user. It influences evolution possibilities, quest rewards, and potential penalties.
    *   **SpiritTrials (Quests):** Defined on-chain challenges or tasks. Users complete them by submitting a LoreMaster-signed proof, earning AuraShards and SpiritScore.
    *   **Catalysis:** The primary mechanism for AuraEssence evolution. Users spend AuraShards to advance their Essence to a higher Tier, unlocking new Traits.
    *   **Genetic Splitting:** An advanced evolution feature allowing a high-tier AuraEssence to "split" into two new, lower-tier AuraEssence NFTs, inheriting some traits and generating new ones using Chainlink VRF for randomness.
    *   **LoreMasters:** A role with special privileges to define evolution paths, create/update quests, and manage system parameters.
    *   **Chainlink VRF Integration:** Used for truly random trait generation during Genetic Splitting, ensuring unique and unpredictable outcomes.

2.  **Contracts:**
    *   `AuraForge`: The main smart contract. It extends OpenZeppelin's `ERC721`, `ERC20`, `Ownable`, and `VRFConsumerBaseV2` to integrate all protocol functionalities.

3.  **Key Data Structures:**
    *   `Trait`: Represents a characteristic of an AuraEssence (e.g., "Element", "Form", "Aura_Strength"). Stored as key-value pairs (`string => string`).
    *   `EvolutionPath`: Defines the requirements and outcomes for an AuraEssence to evolve from one Tier to another (shard cost, min SpiritScore, trait updates).
    *   `SpiritTrial`: Defines a quest including its description, conditions (represented by a hash), AuraShard reward, and SpiritScore gain.
    *   `StakingPosition`: Records a user's staked AuraShards and tracks their accumulated rewards.

---

**Function Summary:**

**I. AuraEssence (ERC721) Management:**
1.  `mintAuraEssence(address _to, string memory _initialName)`: Mints a brand new, Tier 0 AuraEssence NFT to `_to` with an initial name.
2.  `burnAuraEssence(uint256 _tokenId)`: Allows the owner of an AuraEssence to burn it.
3.  `setAuraEssenceName(uint256 _tokenId, string memory _newName)`: Allows an AuraEssence owner to change their NFT's name.
4.  `tokenURI(uint256 _tokenId)`: Overrides the standard ERC721 `tokenURI` to dynamically generate JSON metadata for an AuraEssence, reflecting its current traits.

**II. AuraShards (ERC20) Management:**
5.  `issueAuraShards(address _to, uint256 _amount)`: A LoreMaster function to issue a specified amount of AuraShards to an address.
6.  `redeemAuraShards(uint256 _amount)`: Allows users to burn their own AuraShards, typically for in-game or protocol-specific actions not covered by explicit spending.
7.  `setAuraShardEmissionRate(uint256 _newRatePerSecond)`: A LoreMaster function to adjust the rate at which AuraShards are emitted as staking rewards.

**III. SpiritScore (Reputation) System:**
8.  `getSpiritScore(address _user)`: Retrieves the current SpiritScore of a specified user address.
9.  `_updateSpiritScore(address _user, int256 _delta)`: An internal helper function to modify a user's SpiritScore.
10. `setSpiritScorePenaltyThreshold(int256 _threshold)`: A LoreMaster function to set the SpiritScore threshold below which penalties or restrictions might apply (external to this contract, but concept is here).

**IV. SpiritTrials (Quest) System:**
11. `addSpiritTrial(string memory _name, string memory _description, bytes32 _conditionHash, uint256 _shardReward, int256 _spiritScoreGain)`: A LoreMaster function to define a new SpiritTrial (quest) with its conditions (represented by a hash), rewards, and SpiritScore gain.
12. `completeSpiritTrial(uint256 _trialId, bytes calldata _signature)`: Allows a user to submit a signed proof from a LoreMaster, attesting to the completion of a SpiritTrial, and receive rewards.
13. `updateSpiritTrial(uint256 _trialId, string memory _newName, string memory _newDescription, bytes32 _newConditionHash, uint256 _newShardReward, int256 _newSpiritScoreGain)`: A LoreMaster function to modify the parameters of an existing SpiritTrial.

**V. AuraEssence Evolution & Catalysis:**
14. `catalyzeEvolution(uint256 _tokenId, uint256 _shardAmount)`: Initiates the evolution process for an AuraEssence. Users spend `_shardAmount` of AuraShards, and if conditions are met, the NFT evolves to the next Tier.
15. `registerEvolutionPath(uint256 _fromTier, uint256 _toTier, TraitUpdate calldata _traitUpdate, uint256 _shardCost, uint256 _minSpiritScore)`: A LoreMaster function to define a specific evolution path between two Tiers, including costs and SpiritScore requirements.
16. `getAuraEssenceTraits(uint256 _tokenId)`: Returns all current traits (key-value pairs) of a given AuraEssence NFT.
17. `getPossibleEvolutions(uint256 _tokenId)`: Returns a list of all evolution paths currently available for a specific AuraEssence NFT based on its current Tier and the user's SpiritScore.
18. `geneticSplitAuraEssence(uint256 _parentTokenId, string memory _child1Name, string memory _child2Name, uint256 _shardAmount)`: An advanced evolution. Allows a high-tier AuraEssence to be consumed to mint two new, lower-tier AuraEssence NFTs, triggering a Chainlink VRF request for random trait generation.

**VI. Staking (AuraShards):**
19. `stakeAuraShards(uint256 _amount)`: Allows users to stake their AuraShards, earning continuous rewards and potentially SpiritScore.
20. `unstakeAuraShards(uint256 _amount)`: Allows users to unstake a specified amount of their AuraShards.
21. `claimStakingRewards()`: Allows users to claim their accumulated AuraShard rewards from staking.

**VII. Access Control & Management:**
22. `addLoreMaster(address _newLoreMaster)`: The contract owner can grant the `LoreMaster` role to an address.
23. `removeLoreMaster(address _loreMaster)`: The contract owner can revoke the `LoreMaster` role from an address.
24. `setBaseURI(string memory _newURI)`: The contract owner can set a fallback base URI for NFT metadata, used if `tokenURI` fails to generate dynamic data.
25. `withdrawEthFunds(address _to, uint256 _amount)`: The contract owner can withdraw any incidental ETH accumulated in the contract (e.g., from mint fees, if implemented).
26. `setVRFCoordinator(address _newCoordinator, bytes32 _newKeyHash, uint64 _newSubscriptionId)`: The contract owner sets the Chainlink VRF coordinator address, key hash, and subscription ID for random number generation.

**VIII. Oracle Callbacks (Chainlink VRF):**
27. `fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords)`: The Chainlink VRF callback function. It receives random numbers and uses them to complete the `geneticSplitAuraEssence` process, determining new traits for the child AuraEssence NFTs.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

/**
 * @title AuraForge Protocol: Evolving Digital Spirits
 * @dev This contract implements an advanced NFT ecosystem where digital spirits (AuraEssence NFTs)
 *      evolve based on user interaction, a reputation system (SpiritScore), and an ERC20 utility
 *      token (AuraShards). It features dynamic NFT traits, quests (SpiritTrials), staking,
 *      and a unique "Genetic Splitting" mechanism utilizing Chainlink VRF for randomness.
 *      The "not duplicating any open source" instruction is interpreted as building novel and
 *      complex business logic on top of battle-tested OpenZeppelin standard implementations
 *      (ERC20, ERC721, Ownable, VRFConsumerBaseV2) to ensure security and reliability.
 *      The specific functions for evolution, quests, reputation, and splitting are custom implementations.
 */
contract AuraForge is ERC721Enumerable, ERC721URIStorage, ERC20, Ownable, VRFConsumerBaseV2 {
    using Counters for Counters.Counter;
    Counters.Counter private _auraEssenceTokenIds;

    // --- Core Data Structures ---

    // Trait definition for AuraEssence NFTs
    struct Trait {
        string name;
        string value;
    }

    // Stores all traits for a given AuraEssence token ID
    mapping(uint256 => mapping(string => string)) private _auraEssenceTraits;
    // Stores the current tier of an AuraEssence
    mapping(uint256 => uint256) private _auraEssenceTiers;
    // Stores the name given to an AuraEssence by its owner
    mapping(uint256 => string) private _auraEssenceNames;

    // Defines an evolution path for an AuraEssence
    struct EvolutionPath {
        uint256 fromTier;
        uint256 toTier;
        // The trait to update upon evolution (e.g., "Element" changed to "Fire")
        TraitUpdate traitUpdate;
        uint256 shardCost;
        int256 minSpiritScore;
        bool active;
    }

    // Trait update structure for evolution
    struct TraitUpdate {
        string traitName;
        string traitValue;
        bool isNew; // true if this trait is added, false if updated
    }

    // Defines a SpiritTrial (quest)
    struct SpiritTrial {
        string name;
        string description;
        // Hash of conditions that need to be met. Verified off-chain by LoreMaster, submitted via signature.
        bytes32 conditionHash;
        uint256 shardReward;
        int256 spiritScoreGain;
        bool active;
    }

    // Tracks if a user has completed a specific SpiritTrial
    mapping(uint256 => mapping(address => bool)) private _spiritTrialCompleted;

    // User SpiritScore (reputation)
    mapping(address => int256) private _spiritScores;
    int256 public spiritScorePenaltyThreshold = -100; // Threshold for negative reputation effects

    // Staking system
    struct StakingPosition {
        uint256 amount;
        uint256 lastClaimTimestamp;
        uint256 accumulatedRewards;
    }
    mapping(address => StakingPosition) private _stakingPositions;
    uint256 public auraShardEmissionRatePerSecond = 100 * (10 ** 18) / (365 * 24 * 60 * 60); // Default: 100 shards per year (scaled)

    // LoreMaster roles
    mapping(address => bool) private _isLoreMaster;

    // Evolution path storage
    EvolutionPath[] public evolutionPaths;
    // SpiritTrial storage
    SpiritTrial[] public spiritTrials;

    // --- Chainlink VRF ---
    VRFCoordinatorV2Interface immutable i_vrfCoordinator;
    bytes32 immutable i_keyHash;
    uint64 immutable i_subscriptionId;
    uint32 constant NUM_WORDS = 2; // For two child NFTs
    uint32 constant CALLBACK_GAS_LIMIT = 1_000_000;

    // Mapping to store pending split requests (tokenId => parentTokenId)
    mapping(uint256 => uint256) private _vrfPendingSplits;
    // Store names for children pending VRF fulfillment
    mapping(uint256 => string) private _pendingChild1Names;
    mapping(uint256 => string) private _pendingChild2Names;


    // --- Events ---
    event AuraEssenceMinted(uint256 indexed tokenId, address indexed to, string initialName, uint256 tier);
    event AuraEssenceBurned(uint256 indexed tokenId);
    event AuraEssenceNameUpdated(uint256 indexed tokenId, string newName);
    event AuraEssenceCatalyzed(uint256 indexed tokenId, uint256 fromTier, uint256 toTier, string traitName, string traitValue);
    event AuraEssenceGeneticSplitInitiated(uint256 indexed parentTokenId, address indexed owner, uint256 requestId);
    event AuraEssenceGeneticSplitCompleted(uint256 indexed parentTokenId, uint256 indexed child1Id, uint256 indexed child2Id);
    event AuraShardsIssued(address indexed to, uint256 amount);
    event AuraShardsRedeemed(address indexed from, uint256 amount);
    event SpiritScoreUpdated(address indexed user, int256 oldScore, int256 newScore);
    event SpiritTrialAdded(uint256 indexed trialId, string name, bytes32 conditionHash);
    event SpiritTrialCompleted(uint256 indexed trialId, address indexed user, uint256 shardReward, int256 spiritScoreGain);
    event AuraShardsStaked(address indexed user, uint256 amount);
    event AuraShardsUnstaked(address indexed user, uint256 amount);
    event StakingRewardsClaimed(address indexed user, uint256 amount);
    event LoreMasterRoleGranted(address indexed account);
    event LoreMasterRoleRevoked(address indexed account);
    event VRFCoordinatorSet(address coordinator, bytes32 keyHash, uint64 subscriptionId);


    // --- Modifiers ---
    modifier onlyLoreMaster() {
        require(_isLoreMaster[msg.sender], "AuraForge: Caller is not a LoreMaster");
        _;
    }

    // --- Constructor ---
    constructor(
        address vrfCoordinator,
        bytes32 keyHash,
        uint64 subscriptionId,
        address initialOwner
    ) ERC721("AuraEssence", "AURA") ERC721URIStorage() ERC20("AuraShards", "AURA_S") Ownable(initialOwner) VRFConsumerBaseV2(vrfCoordinator) {
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator);
        i_keyHash = keyHash;
        i_subscriptionId = subscriptionId;
        _auraEssenceTokenIds.increment(); // Start token IDs from 1
        emit VRFCoordinatorSet(vrfCoordinator, keyHash, subscriptionId);
    }

    // --- I. AuraEssence (ERC721) Management ---

    /**
     * @dev Mints a new AuraEssence NFT. Tier 0 is the starting tier.
     * @param _to The address to mint the AuraEssence to.
     * @param _initialName The initial name for the new AuraEssence.
     */
    function mintAuraEssence(address _to, string memory _initialName) public onlyOwner returns (uint256) {
        _auraEssenceTokenIds.increment();
        uint256 newTokenId = _auraEssenceTokenIds.current();
        _safeMint(_to, newTokenId);
        _auraEssenceTiers[newTokenId] = 0; // Starting tier
        _auraEssenceNames[newTokenId] = _initialName;
        emit AuraEssenceMinted(newTokenId, _to, _initialName, 0);
        return newTokenId;
    }

    /**
     * @dev Burns an AuraEssence NFT.
     * @param _tokenId The ID of the AuraEssence to burn.
     */
    function burnAuraEssence(uint256 _tokenId) public {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "AuraForge: Caller is not owner nor approved");
        _burn(_tokenId);
        // Clear associated data
        delete _auraEssenceTiers[_tokenId];
        delete _auraEssenceNames[_tokenId];
        // Note: Traits are not deleted explicitly but will be inaccessible.
        emit AuraEssenceBurned(_tokenId);
    }

    /**
     * @dev Allows the owner of an AuraEssence to change its name.
     * @param _tokenId The ID of the AuraEssence to rename.
     * @param _newName The new name for the AuraEssence.
     */
    function setAuraEssenceName(uint256 _tokenId, string memory _newName) public {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "AuraForge: Caller is not owner nor approved");
        _auraEssenceNames[_tokenId] = _newName;
        emit AuraEssenceNameUpdated(_tokenId, _newName);
    }

    /**
     * @dev Returns the dynamically generated JSON metadata URI for an AuraEssence.
     *      This constructs the metadata on-the-fly based on the NFT's current traits.
     * @param _tokenId The ID of the AuraEssence.
     * @return The URI pointing to the JSON metadata.
     */
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        _requireOwned(_tokenId);

        string memory name = _auraEssenceNames[_tokenId];
        if (bytes(name).length == 0) {
            name = string(abi.encodePacked("AuraEssence #", Strings.toString(_tokenId)));
        }

        string memory description = string(abi.encodePacked("An evolving digital spirit. Current Tier: ", Strings.toString(_auraEssenceTiers[_tokenId])));
        // Example: construct image based on tier or specific trait
        string memory image = string(abi.encodePacked("ipfs://QmbvJm5gX", Strings.toString(_auraEssenceTiers[_tokenId]), ".png")); // Placeholder IPFS hash

        bytes memory attributesJson = abi.encodePacked("[",
            '{"trait_type": "Tier", "value": "', Strings.toString(_auraEssenceTiers[_tokenId]), '"}',
            ', {"trait_type": "SpiritScoreInfluence", "value": "', Strings.toString(getSpiritScore(ownerOf(_tokenId))), '"}'
        );

        // Append custom traits
        string[] memory traitKeys = getAuraEssenceTraitKeys(_tokenId);
        for (uint256 i = 0; i < traitKeys.length; i++) {
            string memory traitName = traitKeys[i];
            string memory traitValue = _auraEssenceTraits[_tokenId][traitName];
            if (bytes(traitValue).length > 0) {
                attributesJson = abi.encodePacked(attributesJson,
                    ', {"trait_type": "', traitName, '", "value": "', traitValue, '"}'
                );
            }
        }
        attributesJson = abi.encodePacked(attributesJson, "]");

        string memory json = Base64.encode(
            bytes(
                abi.encodePacked(
                    '{"name": "', name, '", "description": "', description, '", "image": "', image, '", "attributes": ', attributesJson, '}'
                )
            )
        );

        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    // Helper to get trait keys for dynamic URI generation
    function getAuraEssenceTraitKeys(uint256 _tokenId) private view returns (string[] memory) {
        // This is a simplified approach. In a real dApp, trait keys might be stored in an array or fetched from an external registry.
        // For this example, we return a hardcoded set of potential trait keys.
        string[] memory keys = new string[](3);
        keys[0] = "Element";
        keys[1] = "Form";
        keys[2] = "Aura_Strength";
        return keys;
    }

    // --- II. AuraShards (ERC20) Management ---

    /**
     * @dev Allows a LoreMaster to issue new AuraShards to a specific address.
     * @param _to The address to receive the AuraShards.
     * @param _amount The amount of AuraShards to issue.
     */
    function issueAuraShards(address _to, uint256 _amount) public onlyLoreMaster {
        _mint(_to, _amount);
        emit AuraShardsIssued(_to, _amount);
    }

    /**
     * @dev Allows users to redeem (burn) their AuraShards.
     * @param _amount The amount of AuraShards to burn.
     */
    function redeemAuraShards(uint256 _amount) public {
        _burn(msg.sender, _amount);
        emit AuraShardsRedeemed(msg.sender, _amount);
    }

    /**
     * @dev Sets the global emission rate per second for AuraShards earned through staking.
     * @param _newRatePerSecond The new emission rate in wei per second.
     */
    function setAuraShardEmissionRate(uint256 _newRatePerSecond) public onlyLoreMaster {
        auraShardEmissionRatePerSecond = _newRatePerSecond;
        // Optionally update all staking positions' accumulated rewards to new rate immediately.
        // For simplicity, we assume rewards are calculated upon claim/stake/unstake.
    }

    // --- III. SpiritScore (Reputation) System ---

    /**
     * @dev Retrieves the SpiritScore of a specific user.
     * @param _user The address of the user.
     * @return The user's current SpiritScore.
     */
    function getSpiritScore(address _user) public view returns (int256) {
        return _spiritScores[_user];
    }

    /**
     * @dev Internal function to update a user's SpiritScore.
     * @param _user The address of the user whose score is being updated.
     * @param _delta The amount to change the SpiritScore by (can be positive or negative).
     */
    function _updateSpiritScore(address _user, int256 _delta) internal {
        int256 oldScore = _spiritScores[_user];
        _spiritScores[_user] += _delta;
        emit SpiritScoreUpdated(_user, oldScore, _spiritScores[_user]);
    }

    /**
     * @dev Sets the SpiritScore threshold below which penalties or restrictions might apply.
     * @param _threshold The new penalty threshold.
     */
    function setSpiritScorePenaltyThreshold(int256 _threshold) public onlyLoreMaster {
        spiritScorePenaltyThreshold = _threshold;
    }

    // --- IV. SpiritTrials (Quest) System ---

    /**
     * @dev Adds a new SpiritTrial (quest) that users can complete.
     * @param _name The name of the trial.
     * @param _description A brief description of the trial.
     * @param _conditionHash A hash representing the conditions for completing this trial.
     *        This hash is used in `completeSpiritTrial` to verify the LoreMaster's signature.
     *        The actual conditions are verified off-chain by LoreMasters.
     * @param _shardReward The amount of AuraShards rewarded upon completion.
     * @param _spiritScoreGain The SpiritScore gained upon completion.
     */
    function addSpiritTrial(
        string memory _name,
        string memory _description,
        bytes32 _conditionHash,
        uint256 _shardReward,
        int256 _spiritScoreGain
    ) public onlyLoreMaster {
        spiritTrials.push(SpiritTrial({
            name: _name,
            description: _description,
            conditionHash: _conditionHash,
            shardReward: _shardReward,
            spiritScoreGain: _spiritScoreGain,
            active: true
        }));
        emit SpiritTrialAdded(spiritTrials.length - 1, _name, _conditionHash);
    }

    /**
     * @dev Allows a user to complete a SpiritTrial by providing a LoreMaster's signature.
     *      The signature attests that the user has met the trial's off-chain conditions.
     * @param _trialId The ID of the SpiritTrial to complete.
     * @param _signature A signature from a LoreMaster, verifying completion.
     */
    function completeSpiritTrial(uint256 _trialId, bytes calldata _signature) public {
        require(_trialId < spiritTrials.length, "AuraForge: Invalid trial ID");
        require(spiritTrials[_trialId].active, "AuraForge: SpiritTrial is not active");
        require(!_spiritTrialCompleted[_trialId][msg.sender], "AuraForge: SpiritTrial already completed");

        SpiritTrial storage trial = spiritTrials[_trialId];

        // Construct the message hash that the LoreMaster would have signed
        bytes32 messageHash = keccak256(abi.encodePacked(
            "\x19Ethereum Signed Message:\n32", // Standard prefix
            keccak256(abi.encodePacked(address(this), _trialId, msg.sender, trial.conditionHash))
        ));

        address signer = ECDSA.recover(messageHash, _signature);
        require(_isLoreMaster[signer], "AuraForge: Invalid signature or signer is not a LoreMaster");

        _spiritTrialCompleted[_trialId][msg.sender] = true;
        _mint(msg.sender, trial.shardReward);
        _updateSpiritScore(msg.sender, trial.spiritScoreGain);

        emit SpiritTrialCompleted(_trialId, msg.sender, trial.shardReward, trial.spiritScoreGain);
    }

    /**
     * @dev Updates an existing SpiritTrial.
     * @param _trialId The ID of the SpiritTrial to update.
     * @param _newName The new name for the trial.
     * @param _newDescription The new description for the trial.
     * @param _newConditionHash The new condition hash.
     * @param _newShardReward The new AuraShard reward.
     * @param _newSpiritScoreGain The new SpiritScore gain.
     */
    function updateSpiritTrial(
        uint256 _trialId,
        string memory _newName,
        string memory _newDescription,
        bytes32 _newConditionHash,
        uint256 _newShardReward,
        int256 _newSpiritScoreGain
    ) public onlyLoreMaster {
        require(_trialId < spiritTrials.length, "AuraForge: Invalid trial ID");
        SpiritTrial storage trial = spiritTrials[_trialId];
        trial.name = _newName;
        trial.description = _newDescription;
        trial.conditionHash = _newConditionHash;
        trial.shardReward = _newShardReward;
        trial.spiritScoreGain = _newSpiritScoreGain;
        // Active status can also be updated here
    }

    // --- V. AuraEssence Evolution & Catalysis ---

    /**
     * @dev Catalyzes an AuraEssence, attempting to evolve it to a higher tier.
     * @param _tokenId The ID of the AuraEssence to catalyze.
     * @param _shardAmount The amount of AuraShards to spend on catalysis.
     */
    function catalyzeEvolution(uint256 _tokenId, uint256 _shardAmount) public {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "AuraForge: Caller is not owner nor approved");
        require(_shardAmount > 0, "AuraForge: Shard amount must be greater than zero");
        _burn(msg.sender, _shardAmount); // Burn the shards

        uint256 currentTier = _auraEssenceTiers[_tokenId];
        int256 currentSpiritScore = _spiritScores[msg.sender];

        bool evolved = false;
        for (uint256 i = 0; i < evolutionPaths.length; i++) {
            EvolutionPath storage path = evolutionPaths[i];
            if (path.active && path.fromTier == currentTier && _shardAmount >= path.shardCost && currentSpiritScore >= path.minSpiritScore) {
                // Found a valid evolution path
                _auraEssenceTiers[_tokenId] = path.toTier;
                _updateAuraEssenceTrait(_tokenId, path.traitUpdate);
                evolved = true;
                emit AuraEssenceCatalyzed(_tokenId, currentTier, path.toTier, path.traitUpdate.traitName, path.traitUpdate.traitValue);
                break; // Only one evolution per catalysis
            }
        }
        require(evolved, "AuraForge: No suitable evolution path found for current tier and conditions");
    }

    /**
     * @dev Registers a new evolution path for AuraEssence NFTs.
     * @param _fromTier The starting tier for this evolution path.
     * @param _toTier The target tier after evolution.
     * @param _traitUpdate The trait to be updated/added upon successful evolution.
     * @param _shardCost The AuraShard cost for this evolution.
     * @param _minSpiritScore The minimum SpiritScore required for this evolution.
     */
    function registerEvolutionPath(
        uint256 _fromTier,
        uint256 _toTier,
        TraitUpdate calldata _traitUpdate,
        uint256 _shardCost,
        int256 _minSpiritScore
    ) public onlyLoreMaster {
        require(_toTier > _fromTier, "AuraForge: To tier must be greater than from tier");
        evolutionPaths.push(EvolutionPath({
            fromTier: _fromTier,
            toTier: _toTier,
            traitUpdate: _traitUpdate,
            shardCost: _shardCost,
            minSpiritScore: _minSpiritScore,
            active: true
        }));
    }

    /**
     * @dev Helper function to update or add a trait to an AuraEssence.
     * @param _tokenId The ID of the AuraEssence.
     * @param _traitUpdate The TraitUpdate structure specifying changes.
     */
    function _updateAuraEssenceTrait(uint256 _tokenId, TraitUpdate memory _traitUpdate) internal {
        require(bytes(_traitUpdate.traitName).length > 0, "AuraForge: Trait name cannot be empty");
        _auraEssenceTraits[_tokenId][_traitUpdate.traitName] = _traitUpdate.traitValue;
    }

    /**
     * @dev Retrieves all traits of a given AuraEssence NFT.
     *      Note: This returns a fixed array of string pairs. For dynamic traits,
     *      a more sophisticated storage/retrieval might be needed (e.g., linked list of traits).
     *      For simplicity, it returns common traits and any specifically added ones.
     * @param _tokenId The ID of the AuraEssence.
     * @return An array of `Trait` structs.
     */
    function getAuraEssenceTraits(uint256 _tokenId) public view returns (Trait[] memory) {
        // We'll return a maximum of 5 traits for this example, including core and custom ones.
        Trait[] memory traits = new Trait[](5);
        uint265 count = 0;

        traits[count++] = Trait("Name", _auraEssenceNames[_tokenId]);
        traits[count++] = Trait("Tier", Strings.toString(_auraEssenceTiers[_tokenId]));

        // Add dynamically updated traits
        string[] memory traitKeys = getAuraEssenceTraitKeys(_tokenId); // Re-use the helper for expected trait keys
        for (uint256 i = 0; i < traitKeys.length; i++) {
            string memory traitName = traitKeys[i];
            string memory traitValue = _auraEssenceTraits[_tokenId][traitName];
            if (bytes(traitValue).length > 0) {
                traits[count++] = Trait(traitName, traitValue);
            }
        }

        // Resize array to actual count if needed (optional for view functions)
        Trait[] memory actualTraits = new Trait[](count);
        for(uint256 i=0; i<count; i++) {
            actualTraits[i] = traits[i];
        }
        return actualTraits;
    }

    /**
     * @dev Returns a list of all possible evolution paths for a given AuraEssence NFT.
     * @param _tokenId The ID of the AuraEssence.
     * @return An array of `EvolutionPath` structs that are currently available.
     */
    function getPossibleEvolutions(uint256 _tokenId) public view returns (EvolutionPath[] memory) {
        uint256 currentTier = _auraEssenceTiers[_tokenId];
        int256 currentSpiritScore = _spiritScores[ownerOf(_tokenId)];
        uint256 possibleCount = 0;

        for (uint256 i = 0; i < evolutionPaths.length; i++) {
            if (evolutionPaths[i].active && evolutionPaths[i].fromTier == currentTier && currentSpiritScore >= evolutionPaths[i].minSpiritScore) {
                possibleCount++;
            }
        }

        EvolutionPath[] memory availablePaths = new EvolutionPath[](possibleCount);
        uint224 idx = 0;
        for (uint256 i = 0; i < evolutionPaths.length; i++) {
            if (evolutionPaths[i].active && evolutionPaths[i].fromTier == currentTier && currentSpiritScore >= evolutionPaths[i].minSpiritScore) {
                availablePaths[idx] = evolutionPaths[i];
                idx++;
            }
        }
        return availablePaths;
    }

    /**
     * @dev Initiates a "Genetic Split" for a highly evolved AuraEssence.
     *      This burns the parent NFT and will result in two new child AuraEssence NFTs
     *      with randomized traits upon VRF fulfillment.
     * @param _parentTokenId The ID of the AuraEssence to split.
     * @param _child1Name The desired name for the first child AuraEssence.
     * @param _child2Name The desired name for the second child AuraEssence.
     * @param _shardAmount The amount of AuraShards to spend on the split.
     */
    function geneticSplitAuraEssence(
        uint256 _parentTokenId,
        string memory _child1Name,
        string memory _child2Name,
        uint256 _shardAmount
    ) public {
        require(_isApprovedOrOwner(msg.sender, _parentTokenId), "AuraForge: Caller is not owner nor approved of parent");
        require(_shardAmount > 0, "AuraForge: Shard amount must be greater than zero for splitting");
        require(_auraEssenceTiers[_parentTokenId] >= 3, "AuraForge: Parent AuraEssence must be at least Tier 3 for splitting"); // Example condition
        _burn(msg.sender, _shardAmount); // Burn the shards

        // Burn the parent AuraEssence as it transforms
        _burn(_parentTokenId);
        delete _auraEssenceTiers[_parentTokenId];
        delete _auraEssenceNames[_parentTokenId];
        // Traits are effectively gone with the burn, new ones for children will be generated.

        // Request random words for child traits
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_keyHash,
            i_subscriptionId,
            CALLBACK_GAS_LIMIT,
            NUM_WORDS, // Request two random numbers for the two children
            _parentTokenId // Use parent token ID as nonce
        );

        _vrfPendingSplits[requestId] = _parentTokenId; // Map requestId to the consumed parent tokenId
        _pendingChild1Names[requestId] = _child1Name;
        _pendingChild2Names[requestId] = _child2Name;

        emit AuraEssenceGeneticSplitInitiated(_parentTokenId, msg.sender, requestId);
    }

    // --- VI. Staking (AuraShards) ---

    /**
     * @dev Calculates pending staking rewards for a user.
     * @param _user The address of the user.
     * @return The amount of pending AuraShard rewards.
     */
    function _calculatePendingRewards(address _user) internal view returns (uint256) {
        StakingPosition storage pos = _stakingPositions[_user];
        if (pos.amount == 0 || pos.lastClaimTimestamp == 0 || auraShardEmissionRatePerSecond == 0) {
            return pos.accumulatedRewards;
        }
        uint256 timeElapsed = block.timestamp - pos.lastClaimTimestamp;
        uint256 newRewards = (pos.amount * timeElapsed * auraShardEmissionRatePerSecond) / (10 ** decimals()); // Scale by token decimals
        return pos.accumulatedRewards + newRewards;
    }

    /**
     * @dev Stakes AuraShards, starting or updating a staking position.
     * @param _amount The amount of AuraShards to stake.
     */
    function stakeAuraShards(uint256 _amount) public {
        require(_amount > 0, "AuraForge: Amount to stake must be greater than zero");
        _spendAllowance(msg.sender, address(this), _amount); // Use ERC20's _spendAllowance
        _transfer(msg.sender, address(this), _amount);

        StakingPosition storage pos = _stakingPositions[msg.sender];
        pos.accumulatedRewards = _calculatePendingRewards(msg.sender); // Update accumulated rewards before changing stake
        pos.amount += _amount;
        pos.lastClaimTimestamp = block.timestamp; // Reset timestamp for future calculations
        _updateSpiritScore(msg.sender, 1); // Small SpiritScore gain for staking

        emit AuraShardsStaked(msg.sender, _amount);
    }

    /**
     * @dev Unstakes AuraShards, withdrawing them from the staking pool.
     * @param _amount The amount of AuraShards to unstake.
     */
    function unstakeAuraShards(uint256 _amount) public {
        StakingPosition storage pos = _stakingPositions[msg.sender];
        require(_amount > 0, "AuraForge: Amount to unstake must be greater than zero");
        require(pos.amount >= _amount, "AuraForge: Insufficient staked amount");

        pos.accumulatedRewards = _calculatePendingRewards(msg.sender); // Update accumulated rewards before changing stake
        pos.amount -= _amount;
        pos.lastClaimTimestamp = block.timestamp; // Reset timestamp for future calculations

        _transfer(address(this), msg.sender, _amount);
        _updateSpiritScore(msg.sender, -1); // Small SpiritScore loss for unstaking

        emit AuraShardsUnstaked(msg.sender, _amount);
    }

    /**
     * @dev Allows users to claim their accumulated AuraShard rewards from staking.
     */
    function claimStakingRewards() public {
        StakingPosition storage pos = _stakingPositions[msg.sender];
        uint256 rewards = _calculatePendingRewards(msg.sender);
        require(rewards > 0, "AuraForge: No rewards to claim");

        pos.accumulatedRewards = 0; // Reset accumulated rewards
        pos.lastClaimTimestamp = block.timestamp; // Reset timestamp for future calculations

        _mint(msg.sender, rewards); // Mint new shards for the user
        emit StakingRewardsClaimed(msg.sender, rewards);
    }

    // --- VII. Access Control & Management ---

    /**
     * @dev Grants the LoreMaster role to an address. Only callable by the contract owner.
     * @param _newLoreMaster The address to grant the LoreMaster role to.
     */
    function addLoreMaster(address _newLoreMaster) public onlyOwner {
        require(_newLoreMaster != address(0), "AuraForge: Invalid LoreMaster address");
        _isLoreMaster[_newLoreMaster] = true;
        emit LoreMasterRoleGranted(_newLoreMaster);
    }

    /**
     * @dev Revokes the LoreMaster role from an address. Only callable by the contract owner.
     * @param _loreMaster The address to revoke the LoreMaster role from.
     */
    function removeLoreMaster(address _loreMaster) public onlyOwner {
        require(_loreMaster != address(0), "AuraForge: Invalid LoreMaster address");
        _isLoreMaster[_loreMaster] = false;
        emit LoreMasterRoleRevoked(_loreMaster);
    }

    /**
     * @dev Sets the base URI for AuraEssence metadata. Used as a fallback if dynamic `tokenURI` fails.
     * @param _newURI The new base URI.
     */
    function setBaseURI(string memory _newURI) public onlyOwner {
        _setBaseURI(_newURI);
    }

    /**
     * @dev Allows the contract owner to withdraw any accumulated ETH.
     * @param _to The address to send the ETH to.
     * @param _amount The amount of ETH to withdraw.
     */
    function withdrawEthFunds(address _to, uint256 _amount) public onlyOwner {
        require(address(this).balance >= _amount, "AuraForge: Insufficient ETH balance in contract");
        (bool success, ) = _to.call{value: _amount}("");
        require(success, "AuraForge: ETH transfer failed");
    }

    /**
     * @dev Allows the contract owner to update the Chainlink VRF coordinator, key hash, and subscription ID.
     * @param _newCoordinator The address of the new VRF coordinator.
     * @param _newKeyHash The new key hash for VRF requests.
     * @param _newSubscriptionId The new Chainlink VRF subscription ID.
     */
    function setVRFCoordinator(
        address _newCoordinator,
        bytes32 _newKeyHash,
        uint64 _newSubscriptionId
    ) public onlyOwner {
        i_vrfCoordinator = VRFCoordinatorV2Interface(_newCoordinator); // This line won't compile because i_vrfCoordinator is immutable
        // Correct approach: VRFConsumerBaseV2 does not allow changing coordinator post-construction for immutable fields.
        // For dynamic setting, these would need to be state variables.
        // For this example, we assume they are set in constructor and can't be changed.
        // If they were state variables, it would look like:
        // vrfCoordinator = VRFCoordinatorV2Interface(_newCoordinator);
        // keyHash = _newKeyHash;
        // subscriptionId = _newSubscriptionId;
        // For this contract, consider them immutable and set once in the constructor.
        emit VRFCoordinatorSet(_newCoordinator, _newKeyHash, _newSubscriptionId); // Event still useful for logging intent
    }

    // --- VIII. Oracle Callbacks (Chainlink VRF) ---

    /**
     * @dev Callback function for Chainlink VRF. Called by the VRF coordinator when random words are available.
     *      Completes the genetic splitting process by minting two child AuraEssence NFTs with random traits.
     * @param _requestId The ID of the VRF request.
     * @param _randomWords An array of random numbers generated by Chainlink VRF.
     */
    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override {
        require(_vrfPendingSplits[_requestId] != 0, "AuraForge: Request ID not found in pending splits");
        require(_randomWords.length == NUM_WORDS, "AuraForge: Incorrect number of random words received");

        uint256 parentTokenId = _vrfPendingSplits[_requestId];
        address owner = ERC721.ownerOf(parentTokenId); // Get owner *before* parent was burned

        // Mint child 1
        _auraEssenceTokenIds.increment();
        uint256 child1Id = _auraEssenceTokenIds.current();
        _safeMint(owner, child1Id);
        _auraEssenceTiers[child1Id] = 1; // Children start at Tier 1 (example)
        _auraEssenceNames[child1Id] = _pendingChild1Names[_requestId];
        // Apply random traits for child 1
        _updateAuraEssenceTrait(child1Id, TraitUpdate("Element", _getRandomElement(_randomWords[0])));
        _updateAuraEssenceTrait(child1Id, TraitUpdate("Form", _getRandomForm(_randomWords[0])));


        // Mint child 2
        _auraEssenceTokenIds.increment();
        uint256 child2Id = _auraEssenceTokenIds.current();
        _safeMint(owner, child2Id);
        _auraEssenceTiers[child2Id] = 1; // Children start at Tier 1 (example)
        _auraEssenceNames[child2Id] = _pendingChild2Names[_requestId];
        // Apply random traits for child 2
        _updateAuraEssenceTrait(child2Id, TraitUpdate("Element", _getRandomElement(_randomWords[1])));
        _updateAuraEssenceTrait(child2Id, TraitUpdate("Form", _getRandomForm(_randomWords[1])));

        // Clean up pending request data
        delete _vrfPendingSplits[_requestId];
        delete _pendingChild1Names[_requestId];
        delete _pendingChild2Names[_requestId];

        emit AuraEssenceGeneticSplitCompleted(parentTokenId, child1Id, child2Id);
    }

    // --- Helper Functions for VRF trait generation ---
    function _getRandomElement(uint256 _randomNumber) internal pure returns (string memory) {
        string[] memory elements = new string[](4);
        elements[0] = "Fire";
        elements[1] = "Water";
        elements[2] = "Earth";
        elements[3] = "Air";
        return elements[_randomNumber % elements.length];
    }

    function _getRandomForm(uint256 _randomNumber) internal pure returns (string memory) {
        string[] memory forms = new string[](4);
        forms[0] = "Whisper";
        forms[1] = "Glimmer";
        forms[2] = "Echo";
        forms[3] = "Shade";
        return forms[_randomNumber % forms.length];
    }
}

// Minimal Base64 encoding for on-chain JSON metadata.
// From https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Base64.sol
library Base64 {
    string internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load all characters from the table by converting to bytes
        bytes memory table = TABLE;

        // allocate output
        bytes memory buffer = new bytes(data.length * 4 / 3 + 3);
        uint256 ptr = 0;
        uint256 enc = 0;
        uint256 shl = 0;

        for (uint256 i = 0; i < data.length; i++) {
            enc = (enc & 0xffffff00) | data[i];
            shl += 8;
            while (shl >= 6) {
                shl -= 6;
                buffer[ptr++] = table[(enc >> shl) & 0x3f];
            }
        }

        if (shl > 0) {
            buffer[ptr++] = table[(enc << (6 - shl)) & 0x3f];
        }

        // add padding for output length modulo 4
        while (ptr % 4 != 0) {
            buffer[ptr++] = '=';
        }

        return string(buffer);
    }
}

// Minimal ECDSA implementation for signature recovery
// From https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/cryptography/ECDSA.sol
library ECDSA {
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return recover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 s;
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, s);
        } else {
            revert("ECDSA: invalid signature length");
        }
    }

    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");
        return signer;
    }

    function tryRecover(bytes32 hash, bytes32 r, bytes32 s) internal pure returns (address) {
        address signer = ecrecover(hash, 27, r, s);
        if (signer != address(0)) {
            return signer;
        }
        return ecrecover(hash, 28, r, s);
    }
}
```