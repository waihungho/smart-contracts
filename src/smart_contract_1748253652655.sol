Okay, here is a Solidity smart contract for an "Evolving Chronicle Shard". The concept is a non-transferable (Soulbound) digital asset that represents a user's journey, reputation, and achievements within a specific ecosystem governed by the contract. It evolves over time based on the user completing challenges, gaining experience, leveling up, and unlocking traits. An authorized "Oracle" role is used to verify off-chain (or complex on-chain) challenge completions.

This combines concepts like Soulbound Tokens (non-transferability), dynamic NFTs (state changes over time), gamification (XP, leveling, challenges, traits), and oracle patterns.

---

**Contract: EvolvingChronicleShard**

**Outline:**

1.  **State Variables:**
    *   Owner address
    *   Oracle address (authorized to submit challenge completions)
    *   Counters for shards, challenges, and traits
    *   Mappings for Shard data by owner address
    *   Mappings for Challenge data by ID
    *   Mappings for Challenge Type data by ID
    *   Mappings for XP thresholds per level
    *   Mappings to track completed challenges per shard
    *   Mapping to track traits per shard
    *   Global list of available trait IDs
    *   Parameters for the decay mechanism (optional vitality/XP decay)

2.  **Structs:**
    *   `ChronicleShard`: Represents the user's unique evolving asset. Contains XP, Level, last active timestamp, etc.
    *   `ChallengeType`: Defines a category of challenges (e.g., "Community", "Technical", "Creative").
    *   `Challenge`: Defines a specific task or achievement with XP reward, potential trait reward, status, etc.

3.  **Enums:**
    *   `ChallengeStatus`: Indicates if a challenge is active or inactive.

4.  **Events:**
    *   `ShardMinted`
    *   `ShardBurned`
    *   `XPReceived`
    *   `LevelUp`
    *   `TraitUnlocked`
    *   `ChallengeCreated`
    *   `ChallengeCompleted`
    *   `BlessingReceived`
    *   `XPDecayed`

5.  **Modifiers:**
    *   `onlyOwner`: Restricts access to the contract owner.
    *   `onlyOracle`: Restricts access to the designated oracle address.
    *   `hasShard`: Checks if the caller/specified address has a minted shard.
    *   `shardExists`: Checks if a shard exists for an address.

6.  **Functions:**
    *   **Admin/Configuration (onlyOwner):**
        *   `constructor`: Initializes the contract owner.
        *   `setOracleAddress`: Sets the address authorized to submit challenge completions.
        *   `addChallengeType`: Creates a new type/category of challenge.
        *   `removeChallengeType`: Deactivates a challenge type.
        *   `createChallenge`: Defines a new specific challenge instance.
        *   `deactivateChallenge`: Marks a challenge as inactive.
        *   `updateChallengeXP`: Modifies the XP reward for a challenge.
        *   `updateChallengeTrait`: Modifies the trait awarded by a challenge.
        *   `addTraitType`: Defines a new global trait ID.
        *   `setLevelXPThreshold`: Sets the XP required to reach a specific level.
        *   `grantTraitManually`: Admin grants a trait directly to a shard.
        *   `revokeTraitManually`: Admin removes a trait directly from a shard.
        *   `setDecayParameters`: Configure optional XP decay rate and interval.

    *   **Shard Management (User Interaction):**
        *   `mintChronicleShard`: Allows an address to mint their unique, non-transferable shard (if they don't have one).
        *   `burnChronicleShard`: Allows admin to burn a shard (e.g., for violations). Users cannot burn their own.
        *   `requestBlessing`: A user initiated function, primarily to update the `lastActive` timestamp, potentially mitigating decay or offering small passive benefit.

    *   **Oracle Interaction (onlyOracle):**
        *   `submitChallengeCompletion`: Verifies and processes a user's completion of a challenge, awarding XP and traits. Includes replay protection and decay calculation.

    *   **Query/View Functions (Public):**
        *   `getShardByOwner`: Retrieves all data for a specific shard owner.
        *   `doesOwnerHaveShard`: Checks if an address possesses a shard.
        *   `getCurrentLevel`: Calculates the current level based on XP.
        *   `hasTrait`: Checks if a shard has a specific trait.
        *   `getShardTraits`: Returns a list of trait IDs held by a shard.
        *   `getChallengeDetails`: Retrieves details for a specific challenge ID.
        *   `getChallengeTypeDetails`: Retrieves details for a specific challenge type ID.
        *   `getLevelXPThreshold`: Retrieves the XP needed for a given level.
        *   `getTotalShards`: Returns the total number of minted shards.
        *   `isChallengeCompletedByShard`: Checks if a specific shard has completed a specific challenge.
        *   `getAllTraitTypes`: Returns a list of all defined trait IDs.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title EvolvingChronicleShard
 * @dev A non-transferable (Soulbound) ERC-like asset representing a user's reputation and achievements.
 * Shards evolve based on completing challenges verified by an Oracle, gaining XP, leveling up,
 * and unlocking traits. Includes a simple decay mechanism for inactivity.
 */
contract EvolvingChronicleShard {

    // --- STATE VARIABLES ---

    address private owner; // Contract deployer/admin
    address private oracleAddress; // Address authorized to verify challenge completions

    uint256 private nextShardId = 1; // Starts from 1, though not strictly an ERC721 token ID (non-transferable)
    uint256 private nextChallengeTypeId = 1;
    uint256 private nextChallengeId = 1;
    uint256 private nextTraitId = 1;

    // Core data for each Chronicle Shard, mapped by owner address
    struct ChronicleShard {
        uint256 xp; // Experience Points
        uint256 level; // Current Level
        uint256 lastActive; // Timestamp of last significant activity (e.g., blessing, challenge completion)
        // Add other dynamic attributes here if needed
    }
    mapping(address => ChronicleShard) private shards;
    mapping(address => bool) private hasShard; // Quick lookup if an address has a shard

    // Defines a category of challenges
    struct ChallengeType {
        string name;
        string description;
        bool active; // Can new challenges of this type be created?
    }
    mapping(uint256 => ChallengeType) private challengeTypes;
    uint256[] private availableChallengeTypeIds;

    // Defines a specific challenge instance
    enum ChallengeStatus { Active, Inactive }
    struct Challenge {
        uint256 challengeTypeId; // Link to ChallengeType
        string name;
        string description;
        uint256 xpReward; // XP awarded upon completion
        uint256 traitRewardId; // Optional: Trait ID awarded (0 for none)
        ChallengeStatus status;
    }
    mapping(uint256 => Challenge) private challenges;
    uint256[] private availableChallengeIds;

    // XP required for each level (level => xp)
    mapping(uint256 => uint256) private levelXPThresholds;

    // Tracks which challenges a specific shard has completed (address => challengeId => completed)
    mapping(address => mapping(uint256 => bool)) private completedChallenges;

    // Tracks traits held by a specific shard (address => traitId => hasTrait)
    mapping(address => mapping(uint256 => bool)) private shardTraits;
    uint256[] private availableTraitIds; // Global list of all possible trait IDs

    // Decay parameters
    uint256 private decayRateXP; // XP lost per decay interval
    uint256 private decayInterval; // Time in seconds for one decay period (0 means no decay)

    // Replay protection for challenge completion
    mapping(bytes32 => bool) private processedProofs;

    // --- EVENTS ---

    event ShardMinted(address indexed owner, uint256 initialLevel, uint256 initialXP);
    event ShardBurned(address indexed owner);
    event XPReceived(address indexed owner, uint252 amount, uint252 newXP);
    event LevelUp(address indexed owner, uint256 oldLevel, uint256 newLevel, uint256 newXP);
    event TraitUnlocked(address indexed owner, uint256 traitId);
    event ChallengeCreated(uint256 indexed challengeId, uint256 indexed challengeTypeId, string name);
    event ChallengeCompleted(address indexed owner, uint256 indexed challengeId, uint256 xpGained, uint256 traitGainedId);
    event BlessingReceived(address indexed owner, uint256 timestamp);
    event XPDecayed(address indexed owner, uint252 amount, uint252 newXP);
    event TraitAdded(uint256 indexed traitId);


    // --- MODIFIERS ---

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function");
        _;
    }

    modifier onlyOracle() {
        require(msg.sender == oracleAddress, "Only the designated oracle can call this function");
        _;
    }

    modifier hasShard(address _addr) {
        require(hasShard[_addr], "Address does not have a Chronicle Shard");
        _;
    }

    modifier shardExists(address _addr) {
        require(hasShard[_addr], "Shard for this address does not exist");
        _;
    }

    // --- CONSTRUCTOR ---

    constructor() {
        owner = msg.sender;
        // Set initial Level 1 threshold
        levelXPThresholds[1] = 0; // Start at level 1 with 0 XP
        levelXPThresholds[2] = 100; // Example: Need 100 XP for level 2
        // Add more levels here or via setLevelXPThreshold later
    }

    // --- ADMIN / CONFIGURATION FUNCTIONS (onlyOwner) ---

    /**
     * @dev Sets the address authorized to submit challenge completions.
     * @param _oracleAddress The address of the oracle.
     */
    function setOracleAddress(address _oracleAddress) external onlyOwner {
        require(_oracleAddress != address(0), "Oracle address cannot be zero");
        oracleAddress = _oracleAddress;
    }

    /**
     * @dev Adds a new category for challenges.
     * @param _name The name of the challenge type.
     * @param _description A description of the challenge type.
     * @return The ID of the new challenge type.
     */
    function addChallengeType(string calldata _name, string calldata _description) external onlyOwner returns (uint256) {
        uint256 newId = nextChallengeTypeId++;
        challengeTypes[newId] = ChallengeType({
            name: _name,
            description: _description,
            active: true
        });
        availableChallengeTypeIds.push(newId);
        return newId;
    }

    /**
     * @dev Deactivates a challenge type. Challenges of this type can no longer be created.
     * Existing challenges of this type remain queryable but cannot be completed.
     * @param _challengeTypeId The ID of the challenge type to deactivate.
     */
    function removeChallengeType(uint256 _challengeTypeId) external onlyOwner {
        require(challengeTypes[_challengeTypeId].active, "Challenge type is already inactive or does not exist");
        challengeTypes[_challengeTypeId].active = false;
        // Note: We don't remove from availableChallengeTypeIds to maintain ID integrity and history
    }

    /**
     * @dev Creates a new specific challenge instance.
     * @param _challengeTypeId The type/category of the challenge.
     * @param _name The name of the specific challenge.
     * @param _description A description of the challenge.
     * @param _xpReward The XP awarded upon completion.
     * @param _traitRewardId Optional trait ID awarded (0 for none).
     * @return The ID of the new challenge.
     */
    function createChallenge(
        uint256 _challengeTypeId,
        string calldata _name,
        string calldata _description,
        uint256 _xpReward,
        uint256 _traitRewardId
    ) external onlyOwner returns (uint256) {
        require(challengeTypes[_challengeTypeId].active, "Challenge type is not active or does not exist");
        if (_traitRewardId != 0) {
             bool traitExists = false;
             for(uint i = 0; i < availableTraitIds.length; i++) {
                 if(availableTraitIds[i] == _traitRewardId) {
                     traitExists = true;
                     break;
                 }
             }
             require(traitExists, "Trait reward ID does not exist");
        }

        uint256 newId = nextChallengeId++;
        challenges[newId] = Challenge({
            challengeTypeId: _challengeTypeId,
            name: _name,
            description: _description,
            xpReward: _xpReward,
            traitRewardId: _traitRewardId,
            status: ChallengeStatus.Active
        });
        availableChallengeIds.push(newId);

        emit ChallengeCreated(newId, _challengeTypeId, _name);
        return newId;
    }

    /**
     * @dev Deactivates a specific challenge instance. Cannot be completed once inactive.
     * @param _challengeId The ID of the challenge to deactivate.
     */
    function deactivateChallenge(uint256 _challengeId) external onlyOwner {
        require(challenges[_challengeId].status == ChallengeStatus.Active, "Challenge is already inactive or does not exist");
        challenges[_challengeId].status = ChallengeStatus.Inactive;
    }

    /**
     * @dev Updates the XP reward for an existing challenge.
     * @param _challengeId The ID of the challenge.
     * @param _newXPReward The new XP reward amount.
     */
    function updateChallengeXP(uint256 _challengeId, uint256 _newXPReward) external onlyOwner {
        require(challenges[_challengeId].challengeTypeId != 0, "Challenge does not exist"); // Check existence implicitly
        challenges[_challengeId].xpReward = _newXPReward;
    }

    /**
     * @dev Updates the trait reward for an existing challenge. Set _newTraitRewardId to 0 for no trait.
     * @param _challengeId The ID of the challenge.
     * @param _newTraitRewardId The new trait ID to reward (0 for none).
     */
    function updateChallengeTrait(uint256 _challengeId, uint256 _newTraitRewardId) external onlyOwner {
        require(challenges[_challengeId].challengeTypeId != 0, "Challenge does not exist"); // Check existence implicitly
         if (_newTraitRewardId != 0) {
             bool traitExists = false;
             for(uint i = 0; i < availableTraitIds.length; i++) {
                 if(availableTraitIds[i] == _newTraitRewardId) {
                     traitExists = true;
                     break;
                 }
             }
             require(traitExists, "New trait reward ID does not exist");
        }
        challenges[_challengeId].traitRewardId = _newTraitRewardId;
    }

     /**
     * @dev Adds a new global trait type that can be awarded.
     * @return The ID of the new trait type.
     */
    function addTraitType() external onlyOwner returns (uint256) {
        uint256 newId = nextTraitId++;
        availableTraitIds.push(newId); // Just adding the ID to the global list
        emit TraitAdded(newId);
        return newId;
    }


    /**
     * @dev Sets the XP required to reach a specific level.
     * Level 1 threshold is usually 0 and set in constructor.
     * @param _level The level number.
     * @param _xpThreshold The XP required to reach this level.
     */
    function setLevelXPThreshold(uint256 _level, uint256 _xpThreshold) external onlyOwner {
        require(_level > 0, "Level must be greater than 0");
        levelXPThresholds[_level] = _xpThreshold;
    }

     /**
     * @dev Manually grants a trait to a user's shard.
     * @param _owner The address of the shard owner.
     * @param _traitId The ID of the trait to grant.
     */
    function grantTraitManually(address _owner, uint256 _traitId) external onlyOwner hasShard(_owner) {
         bool traitExists = false;
         for(uint i = 0; i < availableTraitIds.length; i++) {
             if(availableTraitIds[i] == _traitId) {
                 traitExists = true;
                 break;
             }
         }
         require(traitExists, "Trait ID does not exist");

        if (!shardTraits[_owner][_traitId]) {
            shardTraits[_owner][_traitId] = true;
            emit TraitUnlocked(_owner, _traitId);
        }
    }

    /**
     * @dev Manually revokes a trait from a user's shard.
     * @param _owner The address of the shard owner.
     * @param _traitId The ID of the trait to revoke.
     */
    function revokeTraitManually(address _owner, uint256 _traitId) external onlyOwner hasShard(_owner) {
        require(shardTraits[_owner][_traitId], "Shard does not have this trait");
        shardTraits[_owner][_traitId] = false; // Setting to false is sufficient
    }

    /**
     * @dev Configures the optional XP decay mechanism.
     * @param _decayRate The amount of XP to decay each interval.
     * @param _decayInterval The time in seconds between decay events. Set to 0 to disable decay.
     */
    function setDecayParameters(uint256 _decayRate, uint256 _decayInterval) external onlyOwner {
        decayRateXP = _decayRate;
        decayInterval = _decayInterval;
    }

    // --- SHARD MANAGEMENT FUNCTIONS (User Interaction) ---

    /**
     * @dev Allows an address to mint their unique Chronicle Shard.
     * Each address can only have one shard.
     */
    function mintChronicleShard() external {
        require(!hasShard[msg.sender], "Address already has a Chronicle Shard");

        shards[msg.sender] = ChronicleShard({
            xp: 0,
            level: 1,
            lastActive: block.timestamp
        });
        hasShard[msg.sender] = true;

        // Note: nextShardId is incremented but not used as a direct token ID as it's non-transferable
        // We could store it in the struct if needed for unique identifier beyond address
        nextShardId++;

        emit ShardMinted(msg.sender, 1, 0);
    }

    /**
     * @dev Allows the admin to burn a specific shard. This permanently removes it.
     * @param _owner The address of the shard owner to burn.
     */
    function burnChronicleShard(address _owner) external onlyOwner hasShard(_owner) {
        delete shards[_owner]; // Removes the shard data
        delete hasShard[_owner]; // Updates the quick lookup

        // Optionally clear trait data or other associated data here
        // For traits, since they are mapped by address and traitId, they implicitly disappear
        // However, if tracking *all* traits for a user in an array, that needs explicit clearing.
        // Let's assume simple mapping for traits for now.

        // Clear completed challenges data for the user
        // Cannot efficiently delete entire nested mapping entries in Solidity < 0.8.18
        // If needed, would require iterating or a different data structure.
        // For this example, we'll leave the completedChallenges mapping data but the shard check prevents interaction.

        emit ShardBurned(_owner);
    }

    /**
     * @dev Allows a user to "bless" their shard. Updates last active timestamp.
     * Can potentially mitigate XP decay.
     */
    function requestBlessing() external hasShard(msg.sender) {
        ChronicleShard storage shard = shards[msg.sender];
        _applyDecay(msg.sender, shard); // Apply decay before updating timestamp
        shard.lastActive = block.timestamp;
        emit BlessingReceived(msg.sender, block.timestamp);
    }

    // --- ORACLE INTERACTION FUNCTIONS (onlyOracle) ---

    /**
     * @dev Submits proof that a user completed a specific challenge.
     * This function is called by the authorized oracle address.
     * Includes replay protection using a unique proof hash.
     * @param _owner The address of the user who completed the challenge.
     * @param _challengeId The ID of the challenge completed.
     * @param _proofHash A unique hash representing the completion event (e.g., hash of user+challengeId+timestamp+nonce).
     */
    function submitChallengeCompletion(address _owner, uint256 _challengeId, bytes32 _proofHash) external onlyOracle shardExists(_owner) {
        require(!processedProofs[_proofHash], "Proof hash already processed");
        require(challenges[_challengeId].status == ChallengeStatus.Active, "Challenge is not active or does not exist");
        require(!completedChallenges[_owner][_challengeId], "Challenge already completed by this shard");

        ChronicleShard storage shard = shards[_owner];

        // 1. Apply potential decay first
        _applyDecay(_owner, shard);

        // 2. Process challenge rewards
        uint256 xpGained = challenges[_challengeId].xpReward;
        uint256 traitGainedId = challenges[_challengeId].traitRewardId;

        shard.xp += xpGained;
        completedChallenges[_owner][_challengeId] = true;
        processedProofs[_proofHash] = true;
        shard.lastActive = block.timestamp; // Update active time

        emit XPReceived(_owner, uint252(xpGained), uint252(shard.xp));
        emit ChallengeCompleted(_owner, _challengeId, xpGained, traitGainedId);

        // 3. Check for Level Up
        _checkLevelUp(_owner, shard);

        // 4. Award Trait if applicable
        if (traitGainedId != 0) {
            if (!shardTraits[_owner][traitGainedId]) {
                 bool traitExists = false;
                 for(uint i = 0; i < availableTraitIds.length; i++) {
                     if(availableTraitIds[i] == traitGainedId) {
                         traitExists = true;
                         break;
                     }
                 }
                 // This check should ideally happen in createChallenge, but good to double-check
                 if(traitExists) {
                    shardTraits[_owner][traitGainedId] = true;
                    emit TraitUnlocked(_owner, traitGainedId);
                 }
            }
        }
    }

    // --- INTERNAL HELPERS ---

    /**
     * @dev Internal function to check and apply XP decay.
     * @param _owner The shard owner's address.
     * @param _shard The shard storage pointer.
     */
    function _applyDecay(address _owner, ChronicleShard storage _shard) internal {
        if (decayInterval == 0 || decayRateXP == 0 || _shard.xp == 0) {
            return; // Decay is disabled or no XP to decay
        }

        uint256 timePassed = block.timestamp - _shard.lastActive;
        if (timePassed >= decayInterval) {
            uint256 intervalsPassed = timePassed / decayInterval;
            uint256 totalDecay = intervalsPassed * decayRateXP;

            if (totalDecay > _shard.xp) {
                totalDecay = _shard.xp; // Don't decay below zero
            }

            if (totalDecay > 0) {
                _shard.xp -= totalDecay;
                emit XPDecayed(_owner, uint252(totalDecay), uint252(_shard.xp));
                // Re-calculate level as decay might cause level down
                _checkLevelUp(_owner, _shard);
            }
            // Update lastActive only for the intervals that passed, or to now if activity happens
            // A simpler approach is just setting it to block.timestamp upon activity (blessing/completion)
            // We update lastActive upon activity in the calling functions (requestBlessing, submitChallengeCompletion)
        }
    }


    /**
     * @dev Internal function to check if a shard has leveled up (or down).
     * @param _owner The shard owner's address.
     * @param _shard The shard storage pointer.
     */
    function _checkLevelUp(address _owner, ChronicleShard storage _shard) internal {
        uint256 currentLevel = _shard.level;
        uint256 currentXP = _shard.xp;
        uint256 newLevel = currentLevel;

        // Check for level UP
        // Iterate through levels starting from current+1 to find the new level
        uint256 maxLevel = _shard.level + 10; // Arbitrary upper limit check to prevent infinite loop if thresholds are weird
        for (uint256 level = currentLevel + 1; level <= maxLevel; level++) {
            uint256 threshold = levelXPThresholds[level];
            if (threshold == 0 && level > 1) break; // No threshold defined for this level, stop
            if (currentXP >= threshold) {
                newLevel = level;
            } else {
                break; // XP is below this level's threshold, can't reach higher
            }
        }

        // Check for level DOWN (due to decay or manual XP adjustment if implemented)
         // Iterate downwards from current level to find the lowest level whose threshold is met
         for (uint256 level = currentLevel; level >= 1; level--) {
             uint256 threshold = levelXPThresholds[level];
              // Note: level 1 threshold is 0, always met if XP >= 0
             if (currentXP >= threshold) {
                 newLevel = level; // This is the highest level whose threshold is met
                 break;
             }
             // If level 1 threshold is not met (shouldn't happen with non-negative XP), stay at 1
             if (level == 1) {
                 newLevel = 1;
             }
         }


        if (newLevel != currentLevel) {
            _shard.level = newLevel;
            emit LevelUp(_owner, currentLevel, newLevel, currentXP);
        }
    }


    // --- QUERY / VIEW FUNCTIONS (Public) ---

    /**
     * @dev Retrieves the data for a specific Chronicle Shard owner.
     * @param _owner The address of the shard owner.
     * @return xp The current experience points.
     * @return level The current level.
     * @return lastActive The timestamp of the last significant activity.
     */
    function getShardByOwner(address _owner) external view shardExists(_owner) returns (uint256 xp, uint256 level, uint256 lastActive) {
        ChronicleShard storage shard = shards[_owner];
        return (shard.xp, shard.level, shard.lastActive);
    }

    /**
     * @dev Checks if an address currently possesses a Chronicle Shard.
     * @param _addr The address to check.
     * @return True if the address has a shard, false otherwise.
     */
    function doesOwnerHaveShard(address _addr) external view returns (bool) {
        return hasShard[_addr];
    }

    /**
     * @dev Calculates the current level of a shard based on its XP.
     * Useful if needing to recalculate level outside of state-changing functions.
     * @param _owner The address of the shard owner.
     * @return The calculated current level.
     */
    function getCurrentLevel(address _owner) external view shardExists(_owner) returns (uint256) {
        uint256 currentXP = shards[_owner].xp;
        uint256 calculatedLevel = 1;
        // Iterate upwards to find the highest level whose threshold is met
        uint256 maxCheckLevel = shards[_owner].level + 10; // Check a reasonable range above stored level
        for (uint256 level = 1; level <= maxCheckLevel; level++) {
             uint256 threshold = levelXPThresholds[level];
             if (threshold == 0 && level > 1) break; // No threshold defined
             if (currentXP >= threshold) {
                 calculatedLevel = level;
             } else {
                 // If current level threshold is not met, we need to check downwards
                 if (level > 1) break; // Stop if checking from level 1 and threshold is not met
             }
        }
         // Iterate downwards to find the highest level whose threshold is still met (in case of decay)
         for (uint256 level = calculatedLevel; level >= 1; level--) {
             uint256 threshold = levelXPThresholds[level];
             if (currentXP >= threshold) {
                 calculatedLevel = level;
                 break;
             }
              if (level == 1) {
                 calculatedLevel = 1;
             }
         }
        return calculatedLevel;
    }

    /**
     * @dev Checks if a specific shard possesses a given trait.
     * @param _owner The address of the shard owner.
     * @param _traitId The ID of the trait to check.
     * @return True if the shard has the trait, false otherwise.
     */
    function hasTrait(address _owner, uint256 _traitId) external view shardExists(_owner) returns (bool) {
        return shardTraits[_owner][_traitId];
    }

     /**
     * @dev Gets a list of all trait IDs held by a specific shard.
     * Note: This can be gas-intensive if a shard has many traits.
     * Consider alternative data structures if needed for production with many traits.
     * @param _owner The address of the shard owner.
     * @return An array of trait IDs.
     */
    function getShardTraits(address _owner) external view shardExists(_owner) returns (uint256[] memory) {
        uint256[] memory heldTraitIds = new uint256[](availableTraitIds.length);
        uint256 count = 0;
        for(uint i = 0; i < availableTraitIds.length; i++) {
            uint256 traitId = availableTraitIds[i];
            if (shardTraits[_owner][traitId]) {
                heldTraitIds[count] = traitId;
                count++;
            }
        }
        // Resize the array to only contain the traits found
        uint256[] memory result = new uint256[](count);
        for(uint i = 0; i < count; i++) {
            result[i] = heldTraitIds[i];
        }
        return result;
    }


    /**
     * @dev Retrieves the details of a specific challenge.
     * @param _challengeId The ID of the challenge.
     * @return challengeTypeId The type/category ID.
     * @return name The challenge name.
     * @return description The challenge description.
     * @return xpReward The XP reward.
     * @return traitRewardId The trait ID rewarded (0 for none).
     * @return status The status (Active/Inactive).
     */
    function getChallengeDetails(uint256 _challengeId) external view returns (uint256 challengeTypeId, string memory name, string memory description, uint256 xpReward, uint256 traitRewardId, ChallengeStatus status) {
        require(challenges[_challengeId].challengeTypeId != 0, "Challenge does not exist");
        Challenge storage challenge = challenges[_challengeId];
        return (
            challenge.challengeTypeId,
            challenge.name,
            challenge.description,
            challenge.xpReward,
            challenge.traitRewardId,
            challenge.status
        );
    }

    /**
     * @dev Retrieves the details of a specific challenge type.
     * @param _challengeTypeId The ID of the challenge type.
     * @return name The challenge type name.
     * @return description The challenge type description.
     * @return active The activity status.
     */
    function getChallengeTypeDetails(uint256 _challengeTypeId) external view returns (string memory name, string memory description, bool active) {
        require(challengeTypes[_challengeTypeId].name.length > 0 || _challengeTypeId == 0, "Challenge type does not exist"); // Check existence
        ChallengeType storage challengeType = challengeTypes[_challengeTypeId];
         // Handle case where typeId is 0, though internal IDs start at 1
        if (_challengeTypeId == 0) return ("", "", false); // Or some default/error state
        return (
            challengeType.name,
            challengeType.description,
            challengeType.active
        );
    }

     /**
     * @dev Returns a list of all available challenge type IDs.
     * @return An array of challenge type IDs.
     */
    function getChallengeTypes() external view returns (uint256[] memory) {
        return availableChallengeTypeIds;
    }

     /**
     * @dev Returns a list of all available challenge IDs.
     * @return An array of challenge IDs.
     */
    function getAllChallengeIds() external view returns (uint256[] memory) {
        return availableChallengeIds;
    }

    /**
     * @dev Retrieves the XP threshold required for a given level.
     * @param _level The level number.
     * @return The XP threshold for that level. Returns 0 if not defined.
     */
    function getLevelXPThreshold(uint256 _level) external view returns (uint256) {
        return levelXPThresholds[_level];
    }

    /**
     * @dev Gets the total number of Chronicle Shards minted.
     * Note: Does not decrease if shards are burned, reflects total ever minted.
     * If needing active count, would require tracking in a separate state variable.
     * @return The total number of shards minted.
     */
    function getTotalShards() external view returns (uint256) {
        return nextShardId - 1; // Subtract 1 because ID started at 1 and increments before use
    }

    /**
     * @dev Checks if a specific shard has completed a given challenge.
     * @param _owner The address of the shard owner.
     * @param _challengeId The ID of the challenge to check.
     * @return True if the challenge has been completed by the shard, false otherwise.
     */
    function isChallengeCompletedByShard(address _owner, uint256 _challengeId) external view shardExists(_owner) returns (bool) {
        return completedChallenges[_owner][_challengeId];
    }

    /**
     * @dev Returns a list of all defined trait IDs.
     * @return An array of trait IDs.
     */
    function getAllTraitTypes() external view returns (uint256[] memory) {
        return availableTraitIds;
    }

    /**
     * @dev Gets the current oracle address.
     * @return The oracle address.
     */
    function getOracleAddress() external view returns (address) {
        return oracleAddress;
    }

    /**
     * @dev Gets the contract owner address.
     * @return The owner address.
     */
    function getOwner() external view returns (address) {
        return owner;
    }

     /**
     * @dev Gets the current decay parameters.
     * @return decayRate The XP lost per decay interval.
     * @return decayInterval The time in seconds for one decay period.
     */
    function getDecayParameters() external view returns (uint256 decayRate, uint256 decayInterval) {
        return (decayRateXP, decayInterval);
    }
}
```