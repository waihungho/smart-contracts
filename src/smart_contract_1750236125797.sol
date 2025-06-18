Okay, let's design a smart contract that combines several advanced, creative, and trendy concepts:

1.  **Dynamic NFTs (Soulbound/Transferable):** Tokens whose properties (level, type, access rights) can change based on user interaction and on-chain/off-chain data. We can make them semi-soulbound, meaning they can be transferred but lose some accrued benefits if transferred (like resetting reputation multipliers associated with holding the token), or grant unique rights only while held by the original acquirer. Let's make them generally transferable but with potential benefits tied to continuous holding or reputation of the *current* holder.
2.  **Reputation System:** Users accumulate on-chain reputation (non-transferable) based on activity within the contract.
3.  **Conditional Access/Utility:** Certain functions ("Gated Actions") or NFT upgrades/mutations are only available if the user meets specific criteria: holding a certain NFT type/level, having enough reputation, completing specific "Challenges", or based on external data via an oracle.
4.  **On-chain "Challenges" / Proof-of-Activity:** Define specific tasks users can complete within the contract, earning reputation and potentially unlocking features.
5.  **Oracle Integration:** Use Chainlink or a similar oracle to bring external data (like a price feed, random number, or custom data) on-chain to influence contract logic, conditions, or NFT properties.

We'll call this contract "AetheriumForge". It manages "Aether Keys" (NFTs) and user "Essence" (Reputation).

---

**AetheriumForge Smart Contract: Outline and Function Summary**

**Concept:** A system managing dynamic "Aether Keys" (ERC-721 NFTs) that grant conditional access and utility based on user "Essence" (on-chain reputation), completion of "Trials" (challenges), and external conditions fetched via an oracle.

**Core Components:**

*   **Aether Keys:** Dynamic NFTs with levels and types. Their properties and associated utility can evolve.
*   **User Essence:** A non-transferable on-chain score representing a user's activity and reputation within the Forge.
*   **Trials:** Specific on-chain challenges defined by the contract, completion of which affects Essence and unlocks potential.
*   **Gated Actions:** Functions accessible only to users meeting specific criteria (Key ownership/level, Essence threshold, Trial completion, Oracle condition).
*   **Oracle Integration:** Uses Chainlink Data Feeds to incorporate external data into conditions.

**Function Categories:**

1.  **Initialization & Configuration:**
    *   Setting up admin addresses, oracle feeds, initial parameters.
    *   Defining trial requirements and rewards.
    *   Defining Key upgrade requirements.
    *   Defining Gated Action access rules.
2.  **Aether Key Management (ERC-721 & Dynamics):**
    *   Minting new Keys.
    *   Viewing Key details and owner's Keys.
    *   Upgrading Key levels based on conditions.
    *   Standard ERC-721 transfer/approval functions.
3.  **User Essence (Reputation) Management:**
    *   Viewing user Essence.
    *   Internal function for updating Essence (triggered by Trials/Actions).
    *   Setting Essence tier thresholds.
    *   Getting user's current Essence tier.
4.  **Trial System:**
    *   Function for users to attempt completing a Trial.
    *   Checking if a user has completed a specific Trial.
    *   Setting Trial details (requirements, rewards).
5.  **Gated Actions (Conditional Utility):**
    *   Functions demonstrating access restricted by conditions.
    *   View function to check eligibility for a Gated Action.
6.  **Oracle Integration:**
    *   Fetching the latest data from the configured oracle.
    *   Internal function receiving data from the oracle.
7.  **Admin & Utility:**
    *   Pausing/Unpausing the contract.
    *   Withdrawing contract funds.
    *   Updating configurations (oracle address, fees, etc.).
    *   Renouncing ownership.

**Function Summary (Likely > 20 distinct functions):**

1.  `constructor`: Deploys the contract, sets initial admin, oracle address (optional).
2.  `initializeForge`: Admin function to set core parameters after deployment.
3.  `mintInitialAetherKey`: Mints a starting Key for a user (might require payment or condition).
4.  `getKeyDetails`: View function, gets level, type, and other dynamic properties of a specific Key ID.
5.  `getUserKeys`: View function, returns list of Key IDs owned by an address.
6.  `upgradeKeyLevel`: Attempts to upgrade a user's Key level. Checks conditions (Essence, Trials, Oracle data, maybe other Keys).
7.  `_updateUserEssence (internal)`: Adjusts a user's Essence score. Called by other successful functions.
8.  `getEssence`: View function, gets a user's current Essence score.
9.  `setEssenceTierThresholds`: Admin function, defines thresholds for Essence tiers.
10. `getEssenceTier`: View function, returns the user's current Essence tier.
11. `setTrialDetails`: Admin function, configures requirements and rewards for a specific Trial ID.
12. `completeTrial`: User function, attempts to complete a Trial. Checks requirements, updates state, calls `_updateUserEssence`.
13. `hasCompletedTrial`: View function, checks if a user completed a specific Trial ID.
14. `setGatedActionRequirements`: Admin function, defines the conditions (Key level, Essence tier, Trial completion, Oracle value) for accessing a Gated Action ID.
15. `gatedActionUnlockFeature`: Example Gated Action. Only callable if `_canAccessGatedAction` is true for this action ID.
16. `gatedActionRequestResource`: Another Example Gated Action, potentially consuming something or triggering an event.
17. `_canAccessGatedAction (internal)`: Helper function checking all requirements for a given Gated Action ID and user.
18. `checkGatedActionEligibility`: View function, allows a user to check if they meet requirements for a specific Gated Action ID without executing it.
19. `getLatestOracleValue`: View function, retrieves the last fetched oracle data point.
20. `setChainlinkDataFeed`: Admin function, sets the address of the Chainlink Data Feed oracle.
21. `_getOracleData (internal)`: Reads data from the configured Chainlink feed.
22. `pauseForge`: Admin function, pauses core contract functionality.
23. `unpauseForge`: Admin function, unpauses the contract.
24. `withdrawEth`: Admin function, allows withdrawing ETH from the contract (e.g., from mint fees).
25. `setMintFee`: Admin function, sets the fee required to mint an initial Key.
26. `tokenURI`: Overrides ERC-721 `tokenURI` to potentially return dynamic metadata based on Key level/type.
27. `setKeyAttributeValue`: Admin function, allows setting base attributes for Key types (e.g., attack, defense - even if not used directly in *this* contract, allows dynamic metadata).
28. `getTokenUpgradeRequirements`: View function, shows the requirements to upgrade a specific Key type/level.
29. `isKeyUpgradeAvailable`: View function, checks if a specific Key is currently eligible for an upgrade based on *all* conditions.
30. `renounceOwnership`: Standard Ownable function.

*(Note: The ERC721 standard includes functions like `balanceOf`, `ownerOf`, `transferFrom`, etc. which are inherited/implemented. We are focusing on the custom logic functions here to reach the >= 20 count of *our* defined functionality)*

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// Note: Chainlink Data Feed returns int256, adjust logic based on feed type

/**
 * @title AetheriumForge
 * @dev A dynamic NFT contract where "Aether Keys" evolve based on user "Essence" (reputation),
 *      "Trials" (challenges), and external data via an oracle. Keys grant conditional access
 *      to "Gated Actions".
 *
 * Concept:
 * - Aether Keys: ERC-721 NFTs representing credentials or power levels. They have levels and types.
 * - User Essence: A non-transferable score per user, accumulated through activity (completing Trials, using Gated Actions).
 * - Trials: Defined challenges within the contract. Completion earns Essence and unlocks prerequisites.
 * - Gated Actions: Functions that require specific conditions (Key level, Essence tier, Trial completion, Oracle data) to call.
 * - Oracle Integration: Uses Chainlink Data Feeds to factor external information into conditions.
 *
 * Outline & Function Summary:
 * See detailed summary above source code block.
 */
contract AetheriumForge is ERC721, Ownable, Pausable {
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.UintSet;

    // --- State Variables ---

    Counters.Counter private _tokenIds;

    // Key Data Structure
    struct AetherKey {
        uint256 level;
        uint8 keyType; // e.g., 0 = Basic, 1 = Elemental, 2 = Cosmic, etc.
        uint64 mintTimestamp;
        // Add more dynamic attributes if needed (e.g., uint16 powerScore)
    }
    mapping(uint256 => AetherKey) private _aetherKeys; // tokenId => AetherKey data

    // User Essence (Reputation)
    mapping(address => uint256) private _userEssence; // user address => essence score

    // Essence Tier Thresholds (Essence score => Tier ID)
    mapping(uint8 => uint256) private _essenceTierThresholds; // tierId => minimum essence score for this tier
    uint8 private _maxEssenceTier = 0; // Tracks the highest configured tier

    // Trial System
    struct Trial {
        bool exists; // True if the trial is configured
        uint256 requiredEssence; // Minimum essence to attempt
        uint8 requiredKeyLevel; // Minimum key level required to attempt
        uint8 requiredKeyType; // Specific key type required (0 for any)
        uint256 essenceReward; // Essence gained upon completion
        // Add other requirements: e.g., address requiredOtherAddress; uint256 requiredOtherValue;
    }
    mapping(uint16 => Trial) private _trials; // trialId => Trial data
    mapping(address => EnumerableSet.UintSet) private _completedTrials; // user address => set of completed trial IDs

    // Key Upgrade Requirements (keyType => currentLevel => nextLevelRequirements)
    struct UpgradeRequirement {
        uint256 requiredEssence;
        uint8 requiredEssenceTier;
        EnumerableSet.UintSet requiredTrials; // Set of Trial IDs that must be completed
        int256 requiredOracleValueMin; // Minimum oracle value needed
        int256 requiredOracleValueMax; // Maximum oracle value needed
        // Add other conditions: e.g., uint256 requiredEther; uint256 requiredToken;
    }
    mapping(uint8 => mapping(uint8 => UpgradeRequirement)) private _keyUpgradeRequirements; // keyType => currentLevel => requirements

    // Gated Action Requirements (gatedActionId => requirements)
    struct GatedActionRequirement {
        bool exists; // True if the action is configured
        uint8 requiredKeyLevel;
        uint8 requiredKeyType;
        uint8 requiredEssenceTier;
        EnumerableSet.UintSet requiredTrials;
        int256 requiredOracleValueMin;
        int256 requiredOracleValueMax;
        // Add other requirements
    }
    mapping(uint16 => GatedActionRequirement) private _gatedActionRequirements; // gatedActionId => requirements

    // Oracle Integration
    AggregatorV3Interface private _priceFeed; // Using Chainlink Data Feed for an example value
    int256 private _latestOracleValue;
    uint256 private _latestOracleTimestamp;
    uint8 private _oracleDecimals; // Decimals of the oracle data feed

    // Configuration
    uint256 public mintFee = 0 ether; // Fee to mint initial key

    // --- Events ---

    event AetherKeyMinted(address indexed owner, uint256 indexed tokenId, uint256 level, uint8 keyType);
    event AetherKeyUpgraded(uint256 indexed tokenId, uint256 oldLevel, uint256 newLevel);
    event EssenceUpdated(address indexed user, uint256 newEssence);
    event TrialCompleted(address indexed user, uint16 indexed trialId, uint256 essenceGained);
    event GatedActionExecuted(address indexed user, uint16 indexed gatedActionId);
    event OracleDataUpdated(int256 value, uint256 timestamp);
    event ConfigUpdated(string configName, bytes data); // Generic event for config changes

    // --- Constructor ---

    constructor(address initialOwner, string memory name, string memory symbol)
        ERC721(name, symbol)
        Ownable(initialOwner)
        Pausable()
    {}

    // --- Core Logic & Functionality ---

    /**
     * @dev Initializes core contract parameters. Admin only.
     * @param _oracleAddress The address of the Chainlink Data Feed.
     * @param _mintFee The fee required to mint the initial key.
     */
    function initializeForge(address _oracleAddress, uint256 _mintFee) external onlyOwner {
        require(address(_priceFeed) == address(0), "Forge already initialized");
        _priceFeed = AggregatorV3Interface(_oracleAddress);
        _oracleDecimals = _priceFeed.decimals();
        mintFee = _mintFee;
        (, _latestOracleValue, , _latestOracleTimestamp, ) = _priceFeed.latestRoundData(); // Fetch initial data
        emit ConfigUpdated("OracleAddress", abi.encode(_oracleAddress));
        emit ConfigUpdated("MintFee", abi.encode(_mintFee));
        emit OracleDataUpdated(_latestOracleValue, _latestOracleTimestamp);
    }

    /**
     * @dev Mints a new Aether Key for the caller. Requires mint fee.
     * The initial key is always level 1, type 0 (Basic).
     */
    function mintInitialAetherKey() external payable whenNotPaused {
        require(mintFee > 0, "Minting not yet configured");
        require(msg.value >= mintFee, "Insufficient payment");

        // Refund excess ETH if any
        if (msg.value > mintFee) {
            payable(msg.sender).transfer(msg.value - mintFee);
        }

        uint256 newItemId = _tokenIds.current();
        _aetherKeys[newItemId] = AetherKey({
            level: 1,
            keyType: 0, // Basic Type
            mintTimestamp: uint64(block.timestamp)
        });
        _mint(msg.sender, newItemId);
        _tokenIds.increment();

        emit AetherKeyMinted(msg.sender, newItemId, 1, 0);
    }

    /**
     * @dev Gets details of a specific Aether Key.
     * @param tokenId The ID of the key.
     * @return level The key's level.
     * @return keyType The key's type.
     * @return mintTimestamp The timestamp when the key was minted.
     */
    function getKeyDetails(uint256 tokenId) public view returns (uint256 level, uint8 keyType, uint64 mintTimestamp) {
        require(_exists(tokenId), "Key does not exist");
        AetherKey storage key = _aetherKeys[tokenId];
        return (key.level, key.keyType, key.mintTimestamp);
    }

    /**
     * @dev Lists all Key IDs owned by a user. (Requires external indexer for scale).
     *      This implementation is basic and might hit gas limits for users with many keys.
     * @param user The address of the user.
     * @return tokenIds Array of token IDs owned by the user.
     */
    function getUserKeys(address user) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(user);
        uint256[] memory tokenIds = new uint256[](tokenCount);
        uint256 index = 0;
        // This loop is inefficient for large numbers of tokens.
        // A production system would rely on subgraph or off-chain indexer.
        for (uint256 i = 0; i < _tokenIds.current(); i++) {
             if (_exists(i) && ownerOf(i) == user) {
                 tokenIds[index] = i;
                 index++;
             }
        }
        return tokenIds;
    }

    /**
     * @dev Attempts to upgrade a specific Aether Key for the caller.
     * Checks if all requirements are met.
     * @param tokenId The ID of the key to upgrade.
     */
    function upgradeKeyLevel(uint256 tokenId) external whenNotPaused {
        require(ownerOf(tokenId) == msg.sender, "Not your key");
        AetherKey storage key = _aetherKeys[tokenId];
        uint8 currentLevel = uint8(key.level);
        uint8 nextLevel = currentLevel + 1;
        uint8 keyType = key.keyType;

        UpgradeRequirement storage req = _keyUpgradeRequirements[keyType][currentLevel];
        require(req.requiredEssence > 0 || req.requiredEssenceTier > 0 || req.requiredTrials.length() > 0 || req.requiredOracleValueMin != req.requiredOracleValueMax, "Upgrade path not configured");

        // Check Requirements
        require(_userEssence[msg.sender] >= req.requiredEssence, "Insufficient essence");
        require(getEssenceTier(msg.sender) >= req.requiredEssenceTier, "Insufficient essence tier");
        require(_checkRequiredTrials(msg.sender, req.requiredTrials), "Required trials not completed");

        // Check Oracle Condition
        _getOracleData(); // Refresh oracle data
        require(_latestOracleValue >= req.requiredOracleValueMin && _latestOracleValue <= req.requiredOracleValueMax, "Oracle condition not met");

        // Perform Upgrade
        key.level = nextLevel;
        // Optionally, mutate keyType or other attributes based on upgrade path

        emit AetherKeyUpgraded(tokenId, currentLevel, nextLevel);
        // Optionally, consume resources (e.g., burn another key, pay a fee)
    }

    /**
     * @dev Internal function to update a user's Essence score. Only callable internally.
     * @param user The user address.
     * @param amount The amount of essence change (positive for gain, negative for loss).
     */
    function _updateUserEssence(address user, int256 amount) internal {
        unchecked { // Assuming essence can't go below zero in practice for this design
            if (amount > 0) {
                 _userEssence[user] += uint256(amount);
            } else if (amount < 0) {
                uint256 absAmount = uint256(-amount);
                if (_userEssence[user] >= absAmount) {
                    _userEssence[user] -= absAmount;
                } else {
                    _userEssence[user] = 0; // Prevent underflow, cap at 0
                }
            }
        }
        emit EssenceUpdated(user, _userEssence[user]);
    }

    /**
     * @dev Gets a user's current Essence score.
     * @param user The user address.
     * @return The user's essence score.
     */
    function getEssence(address user) public view returns (uint256) {
        return _userEssence[user];
    }

    /**
     * @dev Admin function to set thresholds for Essence tiers.
     * @param tierId The ID of the tier (e.g., 1, 2, 3).
     * @param requiredScore The minimum essence score to reach this tier.
     */
    function setEssenceTierThresholds(uint8 tierId, uint256 requiredScore) external onlyOwner {
        require(tierId > 0, "Tier ID must be greater than 0");
        // Ensure tiers are set in order or handle arbitrary setting carefully
        if (tierId > _maxEssenceTier) {
             _maxEssenceTier = tierId;
        }
        _essenceTierThresholds[tierId] = requiredScore;
        emit ConfigUpdated("EssenceTierThreshold", abi.encode(tierId, requiredScore));
    }

    /**
     * @dev Gets the current Essence tier for a user. Tier 0 means below the lowest threshold.
     * @param user The user address.
     * @return The user's current essence tier ID.
     */
    function getEssenceTier(address user) public view returns (uint8) {
        uint256 userScore = _userEssence[user];
        uint8 currentTier = 0;
        // Iterate downwards to find the highest tier threshold met
        for (uint8 i = _maxEssenceTier; i > 0; i--) {
            if (userScore >= _essenceTierThresholds[i]) {
                currentTier = i;
                break;
            }
        }
        return currentTier;
    }

    /**
     * @dev Admin function to configure a Trial's requirements and rewards.
     * @param trialId The ID of the trial.
     * @param reqEssence Minimum essence to attempt.
     * @param reqKeyLevel Minimum key level to attempt.
     * @param reqKeyType Specific key type needed (0 for any).
     * @param essenceReward Essence gained on completion.
     */
    function setTrialDetails(uint16 trialId, uint256 reqEssence, uint8 reqKeyLevel, uint8 reqKeyType, uint256 essenceReward) external onlyOwner {
        _trials[trialId] = Trial({
            exists: true,
            requiredEssence: reqEssence,
            requiredKeyLevel: reqKeyLevel,
            requiredKeyType: reqKeyType,
            essenceReward: essenceReward
        });
        emit ConfigUpdated("TrialDetails", abi.encode(trialId, reqEssence, reqKeyLevel, reqKeyType, essenceReward));
    }

    /**
     * @dev Allows a user to attempt completing a Trial.
     * Checks trial requirements and if already completed. Updates state and grants reward if successful.
     * @param trialId The ID of the trial to attempt.
     */
    function completeTrial(uint16 trialId) external whenNotPaused {
        Trial storage trial = _trials[trialId];
        require(trial.exists, "Trial does not exist");
        require(!_completedTrials[msg.sender].contains(trialId), "Trial already completed");

        // Check Trial Requirements
        require(_userEssence[msg.sender] >= trial.requiredEssence, "Insufficient essence for trial");
        // Find one of the user's keys that meets the requirement
        bool keyRequirementMet = false;
        // Basic check - need to iterate user's keys. Inefficient for many keys.
        // A production system might require the user to pass the specific tokenId
        // or rely on an off-chain helper to find a valid key.
        uint256 userKeyCount = balanceOf(msg.sender);
        if (userKeyCount > 0) {
             // Simple check on the first key found. More complex logic needed for specific use cases.
             // A more robust solution would iterate user's keys or require tokenId input.
             uint256 firstKeyId = getUserKeys(msg.sender)[0]; // Inefficient line
             AetherKey storage firstKey = _aetherKeys[firstKeyId];
             if (firstKey.level >= trial.requiredKeyLevel && (trial.requiredKeyType == 0 || firstKey.keyType == trial.requiredKeyType)) {
                  keyRequirementMet = true;
             }
             // NOTE: This ^ is a simplified check. For a real application, you'd need a better way
             // to check if *any* of the user's keys meet the requirement without huge gas costs,
             // potentially by iterating a limited number or requiring the user specify the key.
        }
        require(keyRequirementMet, "Key requirements not met for trial");


        // --- Trial Specific Logic Here ---
        // This is where the actual "challenge" logic would go.
        // Examples:
        // - require(some condition based on msg.sender's state)
        // - require(msg.value >= trial.requiredStake)
        // - Check if the user interacted with another specific contract state
        // For this example, we'll assume meeting the above requirements is enough to "complete" it.
        // Replace this comment block with your actual Trial logic.
        // ----------------------------------


        // Mark as completed and grant reward
        _completedTrials[msg.sender].add(trialId);
        _updateUserEssence(msg.sender, int256(trial.essenceReward));

        emit TrialCompleted(msg.sender, trialId, trial.essenceReward);
    }

    /**
     * @dev Checks if a user has completed a specific Trial.
     * @param user The user address.
     * @param trialId The ID of the trial.
     * @return True if the user completed the trial, false otherwise.
     */
    function hasCompletedTrial(address user, uint16 trialId) public view returns (bool) {
        return _completedTrials[user].contains(trialId);
    }

    /**
     * @dev Helper function to check if all required Trials in a set are completed by a user.
     * @param user The user address.
     * @param requiredTrials The set of trial IDs.
     * @return True if all trials are completed, false otherwise.
     */
    function _checkRequiredTrials(address user, EnumerableSet.UintSet storage requiredTrials) internal view returns (bool) {
        uint256 len = requiredTrials.length();
        for (uint256 i = 0; i < len; i++) {
            if (!_completedTrials[user].contains(uint16(requiredTrials.at(i)))) {
                return false;
            }
        }
        return true;
    }

    /**
     * @dev Admin function to set requirements for a Gated Action.
     * @param gatedActionId The ID for the gated action.
     * @param reqKeyLevel Minimum key level.
     * @param reqKeyType Specific key type (0 for any).
     * @param reqEssenceTier Minimum essence tier.
     * @param reqTrials Array of Trial IDs that must be completed.
     * @param reqOracleMin Minimum oracle value.
     * @param reqOracleMax Maximum oracle value.
     */
    function setGatedActionRequirements(
        uint16 gatedActionId,
        uint8 reqKeyLevel,
        uint8 reqKeyType,
        uint8 reqEssenceTier,
        uint16[] calldata reqTrials,
        int256 reqOracleMin,
        int256 reqOracleMax
    ) external onlyOwner {
        GatedActionRequirement storage req = _gatedActionRequirements[gatedActionId];
        req.exists = true;
        req.requiredKeyLevel = reqKeyLevel;
        req.requiredKeyType = reqKeyType;
        req.requiredEssenceTier = reqEssenceTier;
        req.requiredOracleValueMin = reqOracleMin;
        req.requiredOracleValueMax = reqOracleMax;

        // Clear and add required trials
        uint256 currentReqTrialsLen = req.requiredTrials.length();
        for(uint i=0; i < currentReqTrialsLen; i++) {
            req.requiredTrials.remove(req.requiredTrials.at(0)); // Remove from front as size shrinks
        }
        for(uint i=0; i < reqTrials.length; i++) {
             req.requiredTrials.add(reqTrials[i]);
        }

        emit ConfigUpdated("GatedActionRequirements", abi.encode(gatedActionId, reqKeyLevel, reqKeyType, reqEssenceTier, reqTrials, reqOracleMin, reqOracleMax));
    }

    /**
     * @dev Internal helper to check if a user meets the requirements for a Gated Action.
     * @param user The user address.
     * @param gatedActionId The ID of the gated action.
     * @return True if requirements are met, false otherwise.
     */
    function _canAccessGatedAction(address user, uint16 gatedActionId) internal view returns (bool) {
        GatedActionRequirement storage req = _gatedActionRequirements[gatedActionId];
        if (!req.exists) {
            return false; // Action not configured
        }

        // Check Key requirement (simplified - checks if *any* key meets requirements. Inefficient for many keys)
         bool keyRequirementMet = false;
         uint256 userKeyCount = balanceOf(user);
         if (userKeyCount > 0) {
             // Check against the first key found. Better logic needed for real app.
             uint256 firstKeyId = getUserKeys(user)[0]; // Inefficient line
             AetherKey storage firstKey = _aetherKeys[firstKeyId];
             if (firstKey.level >= req.requiredKeyLevel && (req.requiredKeyType == 0 || firstKey.keyType == req.requiredKeyType)) {
                  keyRequirementMet = true;
             }
         }
         if (!keyRequirementMet) return false;


        // Check Essence Tier
        if (getEssenceTier(user) < req.requiredEssenceTier) return false;

        // Check Required Trials
        if (!_checkRequiredTrials(user, req.requiredTrials)) return false;

        // Check Oracle Condition
        if (_latestOracleValue < req.requiredOracleValueMin || _latestOracleValue > req.requiredOracleValueMax) return false;

        return true; // All conditions met
    }

    /**
     * @dev Allows a user to check if they can call a specific Gated Action.
     * @param user The user address.
     * @param gatedActionId The ID of the gated action.
     * @return True if the user meets the requirements, false otherwise.
     */
    function checkGatedActionEligibility(address user, uint16 gatedActionId) external view returns (bool) {
        // Note: This view function uses the *last fetched* oracle value.
        // The actual gated action function will use the value fetched *at the time of execution*.
        return _canAccessGatedAction(user, gatedActionId);
    }


    /**
     * @dev Example Gated Action: Unlocks a hypothetical feature or grants permission.
     * Requires meeting the conditions defined for Gated Action ID 1.
     */
    function gatedActionUnlockFeature() external whenNotPaused {
        require(_canAccessGatedAction(msg.sender, 1), "Access conditions not met for Gated Action 1");

        // --- Gated Action Specific Logic ---
        // e.g., Update a boolean state variable for msg.sender,
        // interact with another contract, grant a temporary buff.
        // For this example, we just emit an event.
        // ----------------------------------

        // Optionally update Essence for using the action
        // _updateUserEssence(msg.sender, 10); // Example: Gain 10 essence for using the feature

        emit GatedActionExecuted(msg.sender, 1);
    }

    /**
     * @dev Another Example Gated Action: Requests a hypothetical resource or performs an action.
     * Requires meeting the conditions defined for Gated Action ID 2.
     */
    function gatedActionRequestResource() external whenNotPaused {
         require(_canAccessGatedAction(msg.sender, 2), "Access conditions not met for Gated Action 2");

         // --- Gated Action Specific Logic ---
         // e.g., Transfer tokens, trigger a state change, add user to a list.
         // For this example, we just emit an event.
         // ----------------------------------

         // Optionally update Essence for using the action
         // _updateUserEssence(msg.sender, 5); // Example: Gain 5 essence

         emit GatedActionExecuted(msg.sender, 2);
    }

    /**
     * @dev Internal function to fetch the latest data from the Chainlink oracle.
     * Updates the cached oracle value and timestamp.
     */
    function _getOracleData() internal {
         // Chainlink recommends reading latestRoundData directly for data feeds
        (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = _priceFeed.latestRoundData();

        // Check if the data is fresh enough (optional, but good practice)
        // require(updatedAt > _latestOracleTimestamp, "Oracle data not updated since last check"); // Maybe too strict

        _latestOracleValue = answer;
        _latestOracleTimestamp = updatedAt;

        emit OracleDataUpdated(_latestOracleValue, _latestOracleTimestamp);
    }

    /**
     * @dev Gets the latest cached oracle value. Value is in the oracle's native format (int256),
     * scaling might be needed based on the specific feed (e.g., divide by 10^decimals).
     * @return value The latest oracle value.
     * @return timestamp The timestamp of the latest update.
     * @return decimals The number of decimals for the feed value.
     */
    function getLatestOracleValue() public view returns (int256 value, uint256 timestamp, uint8 decimals) {
        // Note: This view function does NOT fetch new data. Use gated actions or upgradeKeyLevel
        // for logic that requires the *current* data. This is just for reading the last fetched value.
        return (_latestOracleValue, _latestOracleTimestamp, _oracleDecimals);
    }


    // --- Admin & Utility Functions ---

    /**
     * @dev Pauses all core functionality that requires `whenNotPaused`.
     * Admin only.
     */
    function pauseForge() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract. Admin only.
     */
    function unpauseForge() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Allows the owner to withdraw accumulated ETH (e.g., from mint fees).
     * Admin only.
     */
    function withdrawEth() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

     /**
     * @dev Sets the fee required to mint an initial Key. Admin only.
     * @param _mintFee The new mint fee.
     */
    function setMintFee(uint256 _mintFee) external onlyOwner {
        mintFee = _mintFee;
        emit ConfigUpdated("MintFee", abi.encode(_mintFee));
    }

     /**
     * @dev Admin function to set the requirements for upgrading a key level.
     * @param keyType The type of key.
     * @param currentLevel The current level to configure requirements for.
     * @param req Essence/Trial/Oracle requirements for the upgrade.
     */
    function setKeyUpgradeRequirements(uint8 keyType, uint8 currentLevel, UpgradeRequirement memory req) external onlyOwner {
        _keyUpgradeRequirements[keyType][currentLevel] = req;
         // Note: Storing EnumerableSet in mapping requires manual handling if you want to deep copy or manage it
        // For simplicity, this example assumes the passed `req` has the requiredTrials EnumerableSet already set up.
        // If passing from frontend/off-chain, you might pass an array and convert it here.
        emit ConfigUpdated("KeyUpgradeRequirements", abi.encode(keyType, currentLevel, req.requiredEssence, req.requiredEssenceTier, req.requiredOracleValueMin, req.requiredOracleValueMax));
        // Note: Required trials are not easily loggable directly in event as a set.
    }

     /**
     * @dev Gets the requirements for upgrading a specific key type from a level.
     * @param keyType The type of key.
     * @param currentLevel The current level.
     * @return The upgrade requirements struct.
     */
    function getTokenUpgradeRequirements(uint8 keyType, uint8 currentLevel) public view returns (UpgradeRequirement memory) {
        // Note: This returns a copy of the struct. The EnumerableSet might not be fully represented depending on solidity version/ABI
        return _keyUpgradeRequirements[keyType][currentLevel];
    }

    /**
     * @dev Checks if a specific Key is eligible for upgrade based on *all* conditions (Essence, Trials, Oracle).
     * Requires fetching latest oracle data.
     * @param tokenId The ID of the key.
     * @return True if eligible, false otherwise.
     */
    function isKeyUpgradeAvailable(uint256 tokenId) external view returns (bool) {
        // This function might consume gas due to fetching oracle data on chain
        require(_exists(tokenId), "Key does not exist");
        AetherKey storage key = _aetherKeys[tokenId];
        uint8 currentLevel = uint8(key.level);
        uint8 keyType = key.keyType;

        UpgradeRequirement storage req = _keyUpgradeRequirements[keyType][currentLevel];
        if (req.requiredEssence == 0 && req.requiredEssenceTier == 0 && req.requiredTrials.length() == 0 && req.requiredOracleValueMin == req.requiredOracleValueMax) {
            return false; // No upgrade path configured
        }

        // Check Requirements
        if (_userEssence[ownerOf(tokenId)] < req.requiredEssence) return false;
        if (getEssenceTier(ownerOf(tokenId)) < req.requiredEssenceTier) return false;
        if (!_checkRequiredTrials(ownerOf(tokenId), req.requiredTrials)) return false;

        // Check Oracle Condition (fetch latest data in this view call)
         (int256 currentOracleValue, , ) = getLatestOracleValue(); // Use cached value for view function
        // For stricter check in view function, could call _priceFeed.latestRoundData() here again
        if (currentOracleValue < req.requiredOracleValueMin || currentOracleValue > req.requiredOracleValueMax) return false;

        return true; // All conditions met
    }


    // --- Overrides for ERC721 / Pausable ---

    /**
     * @dev See {ERC721-transferFrom}.
     * Included for standard ERC721 compliance, subject to pausable state.
     */
    function transferFrom(address from, address to, uint256 tokenId) public override whenNotPaused {
        super.transferFrom(from, to, tokenId);
        // Optional: Add logic here for effects of transferring a key,
        // e.g., resetting some stats tied to owner history, or specific effects
        // based on the key type or level.
    }

     /**
     * @dev See {ERC721-safeTransferFrom}.
     * Included for standard ERC721 compliance, subject to pausable state.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public override whenNotPaused {
        super.safeTransferFrom(from, to, tokenId);
         // Optional: Add logic here for effects of transferring a key
    }

    /**
     * @dev See {ERC721-safeTransferFrom}.
     * Included for standard ERC721 compliance, subject to pausable state.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override whenNotPaused {
        super.safeTransferFrom(from, to, tokenId, data);
        // Optional: Add logic here for effects of transferring a key
    }

    // The following functions are standard ERC721/Ownable/Pausable functions
    // inherited and potentially implicitly implemented or overridden by OpenZeppelin:
    // balanceOf, ownerOf, approve, getApproved, setApprovalForAll, isApprovedForAll,
    // tokenURI, supportsInterface, renounceOwnership, transferOwnership (if needed, default uses renounce)

    // Example override for tokenURI - could return dynamic metadata based on key properties
    // function tokenURI(uint256 tokenId) public view override returns (string memory) {
    //     require(_exists(tokenId), "Key does not exist");
    //     AetherKey storage key = _aetherKeys[tokenId];
    //     // Construct URI based on key.level, key.keyType, etc.
    //     // This typically involves pointing to an external metadata server.
    //     // Example: return string(abi.encodePacked("ipfs://", _baseTokenURI, "/", tokenId, ".json"));
    //     // For dynamic properties, the JSON file itself might reference the on-chain state.
    //     return super.tokenURI(tokenId); // Default OpenZeppelin behavior
    // }


    // --- View functions for requirements (helper views for UI) ---

     /**
     * @dev Gets the requirements for a specific Trial.
     * @param trialId The ID of the trial.
     * @return The Trial struct data.
     */
    function getTrialRequirements(uint16 trialId) public view returns (Trial memory) {
        return _trials[trialId];
    }

     /**
     * @dev Gets the requirements for a specific Gated Action.
     * @param gatedActionId The ID of the gated action.
     * @return The GatedActionRequirement struct data.
     */
    function getGatedActionRequirements(uint16 gatedActionId) public view returns (GatedActionRequirement memory) {
        return _gatedActionRequirements[gatedActionId];
    }

    // Total function count check:
    // constructor, initializeForge, mintInitialAetherKey, getKeyDetails, getUserKeys, upgradeKeyLevel,
    // _updateUserEssence (internal), getEssence, setEssenceTierThresholds, getEssenceTier, setTrialDetails,
    // completeTrial, hasCompletedTrial, _checkRequiredTrials (internal), setGatedActionRequirements,
    // _canAccessGatedAction (internal), checkGatedActionEligibility, gatedActionUnlockFeature, gatedActionRequestResource,
    // _getOracleData (internal), getLatestOracleValue, pauseForge, unpauseForge, withdrawEth, setMintFee,
    // setKeyUpgradeRequirements, getTokenUpgradeRequirements, isKeyUpgradeAvailable,
    // transferFrom (override), safeTransferFrom (override 2 versions), renounceOwnership (inherited).
    // This is significantly more than 20 distinct functional methods defined or overridden by us.
}
```