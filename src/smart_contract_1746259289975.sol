Okay, let's design a smart contract that incorporates several advanced and creative concepts beyond standard token functionalities.

We'll create a "ChronicleForge" contract. This contract manages dynamic, semi-soulbound NFTs (Chronicles) for users. These Chronicles track a user's on-chain reputation and possess attributes that change based on completed "Achievements". Achievements are defined by the contract owner and can have various conditions (some verifiable on-chain, some requiring external proof/trigger). The NFTs are non-transferable by default but could potentially gain transferability under specific achievement conditions (though we'll keep them strictly soulbound for simplicity here to lean into the reputation aspect).

This combines:
1.  **Dynamic NFTs:** Attributes change post-mint.
2.  **Soulbound Mechanics:** NFTs tied to an address's identity/reputation.
3.  **On-Chain Reputation System:** A score linked to activities/achievements.
4.  **Extensible Achievement System:** Owner can define new goals/rewards.
5.  **Attribute System:** NFTs have numerical attributes influenced by achievements.
6.  **Conditional Logic:** Achievements have conditions that must be met.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
// We'll simulate interfaces or external contracts needed for certain achievement types
// import "./interfaces/ISpecificProtocol.sol"; // Example

/**
 * @title ChronicleForge
 * @dev A smart contract for managing dynamic, soulbound-like NFTs (Chronicles)
 *      tied to user reputation and on-chain achievements.
 */
contract ChronicleForge is Ownable {

    /*
     * OUTLINE:
     * 1. State Variables:
     *    - Mappings for Chronicles, Reputation, Achievement Status.
     *    - Structs for Chronicle and Achievement data.
     *    - Arrays/Mappings for Achievement definitions.
     *    - Configuration parameters (mint fee, base reputation, etc.).
     *    - Counters (total minted, achievement count).
     * 2. Enums:
     *    - Achievement Condition Types.
     *    - Chronicle Attribute Types (indices).
     * 3. Events:
     *    - Chronicle Minted, Achievement Defined, Achievement Completed,
     *    - Reputation Updated, Attribute Updated, Parameters Updated.
     * 4. Modifiers:
     *    - hasChronicle (ensures caller has a Chronicle).
     * 5. Core Logic Functions:
     *    - Minting Chronicles.
     *    - Defining and managing Achievements (Owner only).
     *    - Checking and processing Achievements for users.
     *    - Updating Reputation and Chronicle Attributes.
     * 6. Query Functions (View/Pure):
     *    - Getting Chronicle data, Reputation, Achievement details, etc.
     * 7. Admin Functions (Owner only):
     *    - Setting parameters, withdrawing fees, revoking achievements, etc.
     * 8. Internal Helper Functions.
     */

    /*
     * FUNCTION SUMMARY:
     *
     * --- Core Chronicle/Reputation ---
     * 1. constructor() - Initializes contract with owner.
     * 2. mintChronicle() external payable - Allows a user to mint their unique Chronicle NFT (if they don't have one). Requires a fee.
     * 3. getChronicle(address user) public view returns (Chronicle memory) - Retrieves a user's Chronicle data.
     * 4. getReputation(address user) public view returns (uint256) - Retrieves a user's current reputation score.
     * 5. getTotalChroniclesMinted() public view returns (uint256) - Returns the total number of Chronicles minted.
     * 6. isChronicleMinted(address user) public view returns (bool) - Checks if a user has already minted a Chronicle.
     * 7. getChronicleAttribute(address user, uint256 attributeIndex) public view returns (int256) - Gets a specific dynamic attribute value for a user's Chronicle.
     * 8. getChronicleAttributeCount() public pure returns (uint256) - Returns the number of defined Chronicle attributes.
     * 9. resetChronicle(address user) external onlyOwner - Resets a user's Chronicle attributes and reputation (use with caution).
     *
     * --- Achievement System ---
     * 10. defineAchievement(AchievementDefinition calldata definition) external onlyOwner - Defines a new type of achievement with conditions and rewards.
     * 11. checkAndProcessAchievement(uint256 achievementId) external - Allows a user or trusted system to check and process a specific achievement for the caller.
     * 12. getUserCompletedAchievements(address user) public view returns (uint256[] memory) - Lists the IDs of achievements completed by a user.
     * 13. getUserAchievementStatus(address user, uint256 achievementId) public view returns (bool) - Checks if a user has completed a specific achievement.
     * 14. getAchievementDetails(uint256 achievementId) public view returns (AchievementDefinition memory) - Retrieves the details of a defined achievement.
     * 15. listAchievements() public view returns (uint256[] memory) - Lists all defined achievement IDs.
     * 16. getAchievementCount() public view returns (uint256) - Returns the total number of defined achievements.
     * 17. isAchievementDefined(uint256 achievementId) public view returns (bool) - Checks if an achievement ID corresponds to a defined achievement.
     * 18. setAchievementStatus(address user, uint256 achievementId, bool completed) external onlyOwner - Manually sets the completion status of an achievement for a user.
     * 19. revokeAchievement(address user, uint256 achievementId) external onlyOwner - Revokes a previously completed achievement for a user, reverting rewards.
     *
     * --- Admin & Configuration ---
     * 20. setMintFee(uint256 fee) external onlyOwner - Sets the fee required to mint a Chronicle.
     * 21. getMintFee() public view returns (uint256) - Gets the current Chronicle mint fee.
     * 22. setBaseReputationGain(uint256 amount) external onlyOwner - Sets the base amount of reputation gained from achievements (modified by achievement reward).
     * 23. getBaseReputationGain() public view returns (uint256) - Gets the base reputation gain amount.
     * 24. setMaxReputation(uint256 amount) external onlyOwner - Sets the maximum possible reputation a user can achieve.
     * 25. getMaxReputation() public view returns (uint256) - Gets the maximum reputation.
     * 26. setChronicleBaseAttributes(int256[10] calldata attributes) external onlyOwner - Sets the initial base attributes for new Chronicles.
     * 27. getChronicleBaseAttributes() public view returns (int256[10] memory) - Gets the current base attributes for Chronicles.
     * 28. withdrawFunds() external onlyOwner - Allows the owner to withdraw collected mint fees.
     * 29. setAchievementCondition(uint256 achievementId, ConditionType conditionType, bytes calldata conditionValue) external onlyOwner - Allows updating the condition of an existing achievement.
     * 30. setTrustedSigner(address signer) external onlyOwner - Sets an address trusted to provide signed data for certain achievement types (e.g., off-chain proof). (Optional advanced feature placeholder)
     *
     * Note: Some functions combine storage reads and computations.
     * The current implementation requires users to call `checkAndProcessAchievement` to claim rewards
     * once they believe they've met the criteria. For `OnChainBalanceGreaterThan` or `OnChainFunctionCallCount`
     * conditions, the contract will verify the state at the time of the call. For `ManualTrigger`,
     * the function simply allows processing if the admin/trusted source indicates completion
     * (e.g., via `setAchievementStatus` or signed data not implemented here).
     * Revoking achievements requires careful logic to revert attributes/reputation - this is complex and
     * simplified here by just marking as incomplete. Full state rollback would be more complex.
     * Attributes are `int256` to allow for negative modifiers, but they are capped at 0.
     */

    // --- Enums ---

    enum ConditionType {
        ManualTrigger,              // Can be triggered manually by owner or trusted source via setAchievementStatus
        OnChainReputationReached,   // User's reputation must be >= conditionValue (uint256)
        OnChainBalanceGreaterThan,  // User's balance of a specific ERC20 token must be >= conditionValue (address token, uint256 requiredAmount)
        OnChainFunctionCallCount    // User must have called a specific function on a specific contract >= conditionValue (address contractAddress, bytes4 functionSig, uint256 requiredCalls) - SIMULATED, complex to verify on-chain history
        // Add more complex types like interacting with specific protocols, having other NFTs, etc.
    }

    // Define attribute indices for clarity
    enum AttributeType {
        Strength,      // Index 0
        Dexterity,     // Index 1
        Intelligence,  // Index 2
        Wisdom,        // Index 3
        Charisma,      // Index 4
        Constitution,  // Index 5
        Luck,          // Index 6
        Focus,         // Index 7
        Courage,       // Index 8
        Creativity     // Index 9
    }

    uint256 constant ATTRIBUTE_COUNT = 10;

    // --- Structs ---

    struct Chronicle {
        address owner;
        uint256 mintedTimestamp;
        int256[ATTRIBUTE_COUNT] baseAttributes; // Initial attributes
        int256[ATTRIBUTE_COUNT] dynamicAttributes; // Base + modifiers from achievements
        // Add more NFT metadata fields if needed
    }

    struct AchievementDefinition {
        uint256 id;
        string description;
        ConditionType conditionType;
        bytes conditionValue; // Packed data depending on conditionType
        int256[ATTRIBUTE_COUNT] attributeModifiers; // Signed integers to add/subtract from attributes
        uint256 reputationReward; // Reputation points awarded
        bool isRepeatable; // Can this achievement be completed multiple times? (Usually false for badges)
        bool requiresExternalVerification; // True if conditionType requires off-chain proof / admin trigger
    }

    // --- State Variables ---

    mapping(address => Chronicle) public chronicles;
    mapping(address => bool) public hasChronicle; // Quick check if user has minted
    mapping(address => uint256) public reputation;
    mapping(address => mapping(uint256 => bool)) public userAchievements; // user => achievementId => completed

    AchievementDefinition[] public achievements; // Store defined achievements in an array
    mapping(uint256 => uint256) private achievementIdToIndex; // Map ID to array index
    uint256 private nextAchievementId = 1; // Start IDs from 1

    uint256 public mintFee;
    uint256 public baseReputationGain = 10; // Default gain per achievement
    uint256 public maxReputation = 1000;

    uint256 public totalChroniclesMinted;

    int256[ATTRIBUTE_COUNT] public chronicleBaseAttributes; // Default base attributes

    // Example: For OnChainFunctionCallCount (SIMULATED - actual impl is complex)
    mapping(address => mapping(address => mapping(bytes4 => uint256))) private functionCallCounts;

    // --- Events ---

    event ChronicleMinted(address indexed owner, uint256 indexed chronicleId, uint256 timestamp);
    event AchievementDefined(uint256 indexed achievementId, string description, ConditionType conditionType);
    event AchievementCompleted(address indexed user, uint256 indexed achievementId, uint256 newReputation);
    event ReputationUpdated(address indexed user, uint256 oldReputation, uint256 newReputation);
    event AttributesUpdated(address indexed user, uint256 indexed achievementId, int256[ATTRIBUTE_COUNT] appliedModifiers);
    event ParametersUpdated(string paramName, uint256 oldValue, uint256 newValue);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner); // From Ownable
    event FundsWithdrawn(address indexed owner, uint256 amount);

    // --- Modifiers ---

    modifier hasChronicle() {
        require(hasChronicle[msg.sender], "ChronicleForge: Caller must have a Chronicle");
        _;
    }

    // --- Constructor ---

    constructor() Ownable(msg.sender) {
        // Set some default base attributes
        chronicleBaseAttributes = [10, 10, 10, 10, 10, 10, 10, 10, 10, 10];
        mintFee = 0.01 ether; // Example default fee
    }

    // --- Core Chronicle/Reputation Functions ---

    /**
     * @dev Allows a user to mint their unique Chronicle NFT. Soulbound to the minter's address.
     * @param initialAttributes Optional initial attributes (can be zeros if using defaults).
     * @param name Placeholder for potential future name or token URI data.
     */
    function mintChronicle(int256[ATTRIBUTE_COUNT] calldata initialAttributes, string calldata name) external payable {
        require(!hasChronicle[msg.sender], "ChronicleForge: Already minted a Chronicle");
        require(msg.value >= mintFee, "ChronicleForge: Insufficient mint fee");

        totalChroniclesMinted++; // Use this as a simple unique ID for the Chronicle, though not a full ERC721 token ID.
                                 // If implementing ERC721, this would be the tokenId.

        Chronicle storage newChronicle = chronicles[msg.sender];
        newChronicle.owner = msg.sender;
        newChronicle.mintedTimestamp = block.timestamp;

        // Set initial attributes (can be provided or use base attributes)
        for (uint i = 0; i < ATTRIBUTE_COUNT; i++) {
            newChronicle.baseAttributes[i] = initialAttributes[i] > 0 ? initialAttributes[i] : chronicleBaseAttributes[i];
            newChronicle.dynamicAttributes[i] = newChronicle.baseAttributes[i]; // Start dynamic = base
        }

        hasChronicle[msg.sender] = true;
        reputation[msg.sender] = 0; // Start with 0 reputation

        emit ChronicleMinted(msg.sender, totalChroniclesMinted, block.timestamp); // Emitting total count as ID
    }

     /**
     * @dev Retrieves a user's Chronicle data.
     * @param user The address of the user.
     * @return Chronicle struct data.
     */
    function getChronicle(address user) public view returns (Chronicle memory) {
         require(hasChronicle[user], "ChronicleForge: User does not have a Chronicle");
         return chronicles[user];
    }

    /**
     * @dev Retrieves a user's current reputation score.
     * @param user The address of the user.
     * @return The user's reputation score.
     */
    function getReputation(address user) public view returns (uint256) {
         require(hasChronicle[user], "ChronicleForge: User does not have a Chronicle");
         return reputation[user];
    }

    /**
     * @dev Returns the total number of Chronicles minted.
     */
    function getTotalChroniclesMinted() public view returns (uint256) {
        return totalChroniclesMinted;
    }

    /**
     * @dev Checks if a user has already minted a Chronicle.
     * @param user The address to check.
     * @return True if the user has a Chronicle, false otherwise.
     */
    function isChronicleMinted(address user) public view returns (bool) {
        return hasChronicle[user];
    }

    /**
     * @dev Gets a specific dynamic attribute value for a user's Chronicle.
     * @param user The address of the user.
     * @param attributeIndex The index of the attribute (0-9 based on AttributeType enum).
     * @return The dynamic attribute value.
     */
    function getChronicleAttribute(address user, uint256 attributeIndex) public view returns (int256) {
        require(hasChronicle[user], "ChronicleForge: User does not have a Chronicle");
        require(attributeIndex < ATTRIBUTE_COUNT, "ChronicleForge: Invalid attribute index");
        return chronicles[user].dynamicAttributes[attributeIndex];
    }

    /**
     * @dev Returns the number of defined Chronicle attributes.
     */
    function getChronicleAttributeCount() public pure returns (uint256) {
        return ATTRIBUTE_COUNT;
    }

    /**
     * @dev Resets a user's Chronicle attributes to base and reputation to 0.
     * @param user The address of the user to reset.
     */
    function resetChronicle(address user) external onlyOwner {
        require(hasChronicle[user], "ChronicleForge: User does not have a Chronicle");

        Chronicle storage userChronicle = chronicles[user];
        // Reset dynamic attributes to base
         for (uint i = 0; i < ATTRIBUTE_COUNT; i++) {
            userChronicle.dynamicAttributes[i] = userChronicle.baseAttributes[i];
        }

        // Reset completed achievements status
        uint256[] memory completedAchievementIds = getUserCompletedAchievements(user);
        for(uint i = 0; i < completedAchievementIds.length; i++) {
             userAchievements[user][completedAchievementIds[i]] = false;
        }

        uint256 oldReputation = reputation[user];
        reputation[user] = 0;

        emit AttributesUpdated(user, 0, [0,0,0,0,0,0,0,0,0,0]); // Indicate attributes reset (0 means reset)
        emit ReputationUpdated(user, oldReputation, 0);
        // Note: This is a simplified reset. A full rollback would need to track attribute/reputation changes per achievement.
    }


    // --- Achievement System ---

    /**
     * @dev Defines a new achievement type. Only callable by the owner.
     * @param definition The struct containing achievement details.
     */
    function defineAchievement(AchievementDefinition calldata definition) external onlyOwner {
        require(definition.id == 0 || !isAchievementDefined(definition.id), "ChronicleForge: Achievement ID already exists");
        require(definition.attributeModifiers.length == ATTRIBUTE_COUNT, "ChronicleForge: Invalid attribute modifier count");
        // Add more validation based on conditionType if needed

        uint256 achievementIdToUse = definition.id == 0 ? nextAchievementId++ : definition.id;
        require(achievementIdToUse > 0, "ChronicleForge: Achievement ID must be positive"); // Ensure nextId doesn't wrap or start at 0

        // Prevent overwriting existing non-zero IDs unless explicitly intended (maybe add a separate update function?)
        // For simplicity, if ID is provided, it must be new. If ID is 0, assign nextId.
        if (definition.id == 0) {
            achievementIdToUse = nextAchievementId++;
        } else {
             require(!isAchievementDefined(definition.id), "ChronicleForge: Achievement ID already exists");
             achievementIdToUse = definition.id;
        }


        AchievementDefinition memory newAchievement = definition;
        newAchievement.id = achievementIdToUse;

        achievements.push(newAchievement);
        achievementIdToIndex[newAchievement.id] = achievements.length - 1;

        emit AchievementDefined(newAchievement.id, newAchievement.description, newAchievement.conditionType);
    }

    /**
     * @dev Allows a user or trusted system to check and process a specific achievement.
     *      Requires the caller to have a Chronicle.
     *      The contract verifies the condition based on the AchievementDefinition.
     * @param achievementId The ID of the achievement to check.
     */
    function checkAndProcessAchievement(uint256 achievementId) external hasChronicle {
        address user = msg.sender;
        require(isAchievementDefined(achievementId), "ChronicleForge: Achievement not defined");
        require(!userAchievements[user][achievementId], "ChronicleForge: Achievement already completed by user");

        AchievementDefinition storage achievementDef = achievements[achievementIdToIndex[achievementId]];

        bool conditionMet = false;
        // --- Condition Verification Logic ---
        // This is where you implement the specific checks based on conditionType
        if (achievementDef.conditionType == ConditionType.ManualTrigger) {
            // This type assumes an external process (like owner calling setAchievementStatus)
            // already marked the condition as met. This function just processes the completion.
            // Add a require here if you need a proof parameter: require(proofData.length > 0, "ManualTrigger requires proof");
            // For simplicity, this type just requires the admin to have set the status first.
            // Alternatively, this could require a signed message from a trusted address (setTrustedSigner).
             revert("ChronicleForge: ManualTrigger achievements must be set by admin"); // Force admin/trusted trigger
             // OR allow anyone to call *if* setAchievementStatus was used: conditionMet = userAchievements[user][achievementId]; // Check status already set by admin
             // Let's stick to admin setting status for ManualTrigger for clarity.
        } else if (achievementDef.conditionType == ConditionType.OnChainReputationReached) {
            uint256 requiredReputation = abi.decode(achievementDef.conditionValue, (uint256));
            conditionMet = reputation[user] >= requiredReputation;
        } else if (achievementDef.conditionType == ConditionType.OnChainBalanceGreaterThan) {
             (address tokenAddress, uint256 requiredAmount) = abi.decode(achievementDef.conditionValue, (address, uint256));
             // Requires the token contract to implement ERC20 balance check
             // Example (uncomment if you have ERC20 interface):
             // IERC20 token = IERC20(tokenAddress);
             // conditionMet = token.balanceOf(user) >= requiredAmount;
             revert("ChronicleForge: OnChainBalanceGreaterThan not fully implemented (requires IERC20)"); // Placeholder
        } else if (achievementDef.conditionType == ConditionType.OnChainFunctionCallCount) {
             // SIMULATED: Actual on-chain history tracking is complex and expensive.
             // This would typically require external indexing or a dedicated tracking contract.
             // We'll just add a placeholder increment in a hypothetical function elsewhere.
             // require(proofData.length > 0, "OnChainFunctionCallCount requires proof"); // Or some identifier
             (address contractAddress, bytes4 functionSig, uint256 requiredCalls) = abi.decode(achievementDef.conditionValue, (address, bytes4, uint256));
             // How to get call count? Impossible purely within a standard contract.
             // This would need an event listener off-chain or a specific counting mechanism in the target contract.
              revert("ChronicleForge: OnChainFunctionCallCount simulation - not verifiable on-chain"); // Placeholder
        } else {
            revert("ChronicleForge: Unknown condition type");
        }

        require(conditionMet, "ChronicleForge: Achievement condition not met");

        // --- Process Reward ---
        userAchievements[user][achievementId] = true; // Mark as completed

        // Update Reputation
        uint256 oldReputation = reputation[user];
        uint256 reputationIncrease = baseReputationGain + achievementDef.reputationReward;
        reputation[user] = Math.min(reputation[user] + reputationIncrease, maxReputation);
        if (reputation[user] != oldReputation) {
             emit ReputationUpdated(user, oldReputation, reputation[user]);
        }


        // Update Attributes
        Chronicle storage userChronicle = chronicles[user];
        int256[ATTRIBUTE_COUNT] memory appliedModifiers; // To emit

        for (uint i = 0; i < ATTRIBUTE_COUNT; i++) {
            int256 modifier = achievementDef.attributeModifiers[i];
            userChronicle.dynamicAttributes[i] = userChronicle.dynamicAttributes[i] + modifier;
            // Ensure attributes don't go below zero
            if (userChronicle.dynamicAttributes[i] < 0) {
                userChronicle.dynamicAttributes[i] = 0;
            }
            appliedModifiers[i] = modifier;
        }

        emit AttributesUpdated(user, achievementId, appliedModifiers);
        emit AchievementCompleted(user, achievementId, reputation[user]);
    }

    /**
     * @dev Lists the IDs of achievements completed by a user.
     * @param user The address of the user.
     * @return An array of achievement IDs.
     */
    function getUserCompletedAchievements(address user) public view returns (uint256[] memory) {
        require(hasChronicle[user], "ChronicleForge: User does not have a Chronicle");
        uint256[] memory completed;
        uint256 count = 0;
        // Count completed achievements first
        for(uint i = 0; i < achievements.length; i++) {
            if(userAchievements[user][achievements[i].id]) {
                count++;
            }
        }
        // Populate the array
        completed = new uint256[](count);
        uint256 j = 0;
        for(uint i = 0; i < achievements.length; i++) {
            if(userAchievements[user][achievements[i].id]) {
                completed[j] = achievements[i].id;
                j++;
            }
        }
        return completed;
    }

    /**
     * @dev Checks if a user has completed a specific achievement.
     * @param user The address of the user.
     * @param achievementId The ID of the achievement.
     * @return True if completed, false otherwise.
     */
    function getUserAchievementStatus(address user, uint256 achievementId) public view returns (bool) {
         require(hasChronicle[user], "ChronicleForge: User does not have a Chronicle");
         require(isAchievementDefined(achievementId), "ChronicleForge: Achievement not defined");
         return userAchievements[user][achievementId];
    }

     /**
     * @dev Retrieves the details of a defined achievement.
     * @param achievementId The ID of the achievement.
     * @return AchievementDefinition struct data.
     */
    function getAchievementDetails(uint256 achievementId) public view returns (AchievementDefinition memory) {
        require(isAchievementDefined(achievementId), "ChronicleForge: Achievement not defined");
        return achievements[achievementIdToIndex[achievementId]];
    }

     /**
     * @dev Lists all defined achievement IDs.
     * @return An array of all achievement IDs.
     */
    function listAchievements() public view returns (uint256[] memory) {
        uint256[] memory ids = new uint256[](achievements.length);
        for(uint i = 0; i < achievements.length; i++) {
            ids[i] = achievements[i].id;
        }
        return ids;
    }

    /**
     * @dev Returns the total number of defined achievements.
     */
    function getAchievementCount() public view returns (uint256) {
        return achievements.length;
    }

    /**
     * @dev Checks if an achievement ID corresponds to a defined achievement.
     * @param achievementId The ID to check.
     * @return True if defined, false otherwise.
     */
    function isAchievementDefined(uint256 achievementId) public view returns (bool) {
        // Check if the ID maps to a valid index within the achievements array bounds
        uint256 index = achievementIdToIndex[achievementId];
        return index < achievements.length && achievements[index].id == achievementId;
    }

    /**
     * @dev Manually sets the completion status of an achievement for a user.
     *      Can be used by the owner for ManualTrigger achievements or overrides.
     *      Does NOT trigger attribute/reputation changes directly. Use checkAndProcessAchievement
     *      after setting status to true (by the user or trusted system).
     * @param user The address of the user.
     * @param achievementId The ID of the achievement.
     * @param completed The desired completion status (true/false).
     */
    function setAchievementStatus(address user, uint256 achievementId, bool completed) external onlyOwner {
         require(hasChronicle[user], "ChronicleForge: User does not have a Chronicle");
         require(isAchievementDefined(achievementId), "ChronicleForge: Achievement not defined");
         userAchievements[user][achievementId] = completed;
         // Note: This function only updates the status flag.
         // For rewards, `checkAndProcessAchievement` must still be called *if* completed is set to true.
         // If setting to false, this marks it incomplete but doesn't revert rewards automatically.
    }

    /**
     * @dev Revokes a previously completed achievement for a user.
     *      Marks it as incomplete but does NOT automatically revert attribute/reputation changes.
     *      Full state rollback is complex and requires specific logic based on how rewards accumulate.
     * @param user The address of the user.
     * @param achievementId The ID of the achievement to revoke.
     */
    function revokeAchievement(address user, uint256 achievementId) external onlyOwner {
         require(hasChronicle[user], "ChronicleForge: User does not have a Chronicle");
         require(isAchievementDefined(achievementId), "ChronicleForge: Achievement not defined");
         require(userAchievements[user][achievementId], "ChronicleForge: Achievement not completed by user");

         userAchievements[user][achievementId] = false;
         // Simple revocation: just set status to false.
         // More complex revocation would attempt to subtract rewards, which is tricky
         // if attributes/reputation are non-linearly affected or capped.
         // For this example, we assume effects are cumulative and hard to fully undo.
         // A sophisticated system might require re-calculating state from scratch or using snapshotting.
         emit ParametersUpdated("AchievementRevoked", achievementId, 0); // Using generic event for lack of specific one
    }


    // --- Admin & Configuration Functions ---

    /**
     * @dev Sets the fee required to mint a Chronicle. Only owner can call.
     * @param fee The new mint fee in wei.
     */
    function setMintFee(uint256 fee) external onlyOwner {
        uint256 oldFee = mintFee;
        mintFee = fee;
        emit ParametersUpdated("MintFee", oldFee, mintFee);
    }

    /**
     * @dev Gets the current Chronicle mint fee.
     */
    function getMintFee() public view returns (uint256) {
        return mintFee;
    }

    /**
     * @dev Sets the base amount of reputation gained from achievements. Only owner can call.
     * @param amount The new base reputation gain.
     */
    function setBaseReputationGain(uint256 amount) external onlyOwner {
        uint256 oldAmount = baseReputationGain;
        baseReputationGain = amount;
        emit ParametersUpdated("BaseReputationGain", oldAmount, baseReputationGain);
    }

     /**
     * @dev Gets the base reputation gain amount.
     */
    function getBaseReputationGain() public view returns (uint256) {
        return baseReputationGain;
    }

    /**
     * @dev Sets the maximum possible reputation a user can achieve. Only owner can call.
     * @param amount The new maximum reputation.
     */
    function setMaxReputation(uint256 amount) external onlyOwner {
        uint256 oldAmount = maxReputation;
        maxReputation = amount;
        emit ParametersUpdated("MaxReputation", oldAmount, maxReputation);
        // Note: This doesn't retroactively change reputation for users already above the new max.
        // Could add logic to cap existing users if needed.
    }

    /**
     * @dev Gets the maximum reputation.
     */
    function getMaxReputation() public view returns (uint256) {
        return maxReputation;
    }

    /**
     * @dev Sets the initial base attributes for new Chronicles. Only owner can call.
     * @param attributes An array of 10 int256 values for the base attributes.
     */
    function setChronicleBaseAttributes(int256[ATTRIBUTE_COUNT] calldata attributes) external onlyOwner {
        chronicleBaseAttributes = attributes;
         // No specific event for this, could add one or use generic.
         emit ParametersUpdated("ChronicleBaseAttributes", 0, 0); // Simplified event
    }

    /**
     * @dev Gets the current base attributes for Chronicles.
     */
    function getChronicleBaseAttributes() public view returns (int256[ATTRIBUTE_COUNT] memory) {
        return chronicleBaseAttributes;
    }

    /**
     * @dev Allows the owner to withdraw collected mint fees and other Ether sent to the contract.
     */
    function withdrawFunds() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "ChronicleForge: No funds to withdraw");
        (bool success, ) = payable(owner()).call{value: balance}("");
        require(success, "ChronicleForge: Failed to withdraw funds");
        emit FundsWithdrawn(owner(), balance);
    }

    /**
     * @dev Allows updating the condition details of an existing achievement.
     *      Only owner can call.
     * @param achievementId The ID of the achievement to update.
     * @param conditionType The new condition type.
     * @param conditionValue The new packed condition value.
     */
    function setAchievementCondition(uint256 achievementId, ConditionType conditionType, bytes calldata conditionValue) external onlyOwner {
        require(isAchievementDefined(achievementId), "ChronicleForge: Achievement not defined");
        AchievementDefinition storage achievementDef = achievements[achievementIdToIndex[achievementId]];
        achievementDef.conditionType = conditionType;
        achievementDef.conditionValue = conditionValue;
        emit AchievementDefined(achievementId, achievementDef.description, conditionType); // Re-emit with updated type
    }

     /**
     * @dev Placeholder for setting a trusted address used for signing off-chain data
     *      required for certain achievement condition types (e.g., ManualTrigger with proof).
     * @param signer The address to trust.
     */
    address public trustedSigner;
    function setTrustedSigner(address signer) external onlyOwner {
        trustedSigner = signer;
         emit ParametersUpdated("TrustedSigner", uint256(uint160(address(0))), uint256(uint160(signer))); // Simplified event
    }


    // --- Internal Helper Functions ---

     /**
     * @dev Helper function for safe signed integer addition with a minimum floor (0).
     * @param a The initial value.
     * @param b The value to add (can be negative).
     * @return The result, capped at a minimum of 0.
     */
    function _safeAddIntCapped(int256 a, int256 b) internal pure returns (int256) {
        int256 result = a + b;
        // Check for overflow/underflow and cap at 0
         unchecked {
            // Check for overflow (a > 0, b > 0, result < a)
            if (a > 0 && b > 0 && result < a) return type(int256).max; // Cap at max if overflow
            // Check for underflow (a < 0, b < 0, result > a)
            if (a < 0 && b < 0 && result > a) return type(int256).min; // Cap at min if underflow
         }
         // Ensure result is not less than 0 after addition
         return result > 0 ? result : 0;
    }

     // Example of a simulated function call counter increment - this would need to be called
     // by relevant functions *within this contract* or via external calls if tracking external calls.
     // This is NOT a general solution for tracking *any* function call on *any* contract.
     function _incrementFunctionCallCount(address user, address contractAddress, bytes4 functionSig) internal {
         functionCallCounts[user][contractAddress][functionSig]++;
     }

    // Add fallback or receive if you want to accept plain Ether transfers (not just mint fee)
    // receive() external payable {
    //     // Handle unexpected Ether if necessary
    // }
}

// Basic Math library for min/max (can be replaced by OpenZeppelin's SafeMath if preferred for more operations)
library Math {
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
     function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }
}

// Example placeholder interface (uncomment and define if needed for actual OnChainBalanceGreaterThan)
/*
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    // Add other ERC20 functions if needed for other conditions
}
*/
```

---

**Explanation of Concepts and Features:**

1.  **Dynamic NFTs (Chronicles):** Unlike standard ERC-721s where metadata is often static or points to an off-chain URI, the core state of a Chronicle (its `dynamicAttributes` and associated `reputation`) changes *on-chain* based on user activity tracked by the contract.
2.  **Soulbound-like:** The `mintChronicle` function ensures only one Chronicle per address and there's no `transfer` function. This ties the Chronicle to the user's identity on that chain, making it a form of Soulbound Token (SBT).
3.  **On-Chain Reputation:** A simple `uint256` reputation score is tracked per user. This score increases based on completing achievements, up to a configurable maximum. It's a direct on-chain metric of a user's engagement/accomplishments within this specific system.
4.  **Extensible Achievement System:** The `defineAchievement` function (callable by the owner) allows new types of achievements to be added dynamically. Each achievement has a description, a reward (attribute modifiers and reputation), and a `ConditionType`.
5.  **Conditional Achievement Processing:** The `checkAndProcessAchievement` function is the core mechanic. It attempts to verify if a user has met the criteria for a specific achievement based on its `ConditionType`.
    *   `ManualTrigger`: Relies on external input (like the owner using `setAchievementStatus`) to mark the condition as met. Useful for off-chain activities or complex conditions hard to verify directly in Solidity.
    *   `OnChainReputationReached`: Verifiable directly by checking the user's current reputation score.
    *   `OnChainBalanceGreaterThan`: (Placeholder) Would require interaction with an ERC20 contract to check a user's token balance.
    *   `OnChainFunctionCallCount`: (Simulated) Represents a condition based on a user having called a specific function on a specific contract a certain number of times. *True* on-chain history lookup is extremely difficult and expensive; this implementation is a simulation, highlighting the limitations and potential need for external indexers or specific contract designs to track such things.
6.  **Attribute Modification:** Achievements provide signed integer modifiers (`int256[] attributeModifiers`) that are applied to the user's `dynamicAttributes`. This allows achievements to increase *or decrease* attributes, adding depth (e.g., a "Trial of Failure" achievement might decrease a stat but give reputation). Attributes are capped at 0 to avoid negative values in practice.
7.  **Modular Configuration:** Key parameters like `mintFee`, `baseReputationGain`, `maxReputation`, and `chronicleBaseAttributes` are configurable by the owner via dedicated functions.
8.  **Admin Controls:** Functions like `setAchievementStatus`, `revokeAchievement`, `resetChronicle`, `withdrawFunds`, and parameter setters provide necessary administrative capabilities, especially crucial for managing the flexible achievement system and manual triggers.
9.  **Gas Considerations:** The `checkAndProcessAchievement` function's gas cost depends on the complexity of the condition check. Iterating through completed achievements for view functions is avoided by storing `dynamicAttributes` directly. Listing all achievements (`listAchievements`, `getUserCompletedAchievements`) involves loops, which have gas costs proportional to the number of defined or completed achievements. This design chooses to update the `dynamicAttributes` *when* an achievement is processed, making view functions cheap, rather than calculating attributes from scratch every time.
10. **Non-Duplication Effort:** While elements like Ownable or basic struct/mapping usage are common, the specific combination of dynamic, soulbound NFTs tied to an extensible, conditional on-chain achievement and reputation system, with attributes modified by achievements using signed integers, is not a standard, widely duplicated open-source contract pattern like ERC-20, ERC-721, or a typical AMM/staking pool. The `ConditionType` enum and the design around needing external verification or specific on-chain checks for achievements add layers of complexity often specific to custom dApps.

This contract provides a solid foundation for a dApp where user identity and progression are key, like a decentralized gaming profile, a community reputation system, or a protocol participation tracker.